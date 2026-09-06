extends SceneTree

## LE GUIDE DU MODE PAYSAGE : les memes temoins, SOUDES.
##
##     godot --headless --path . --script res://tools/build_terrain.gd -- <sortie.txt> [ecart]
##
## ⚠ IL N'Y A RIEN A CHERCHER, ET C'EST TOUT L'INTERET. Le damier a deja resolu la question
## dure : chacune des tuiles du geste a son TEMOIN, un relief calcule qui la porte a une case
## connue -- 53 blocs chasses dans `core/massif_witnesses.gd`, les autres tires de l'enumeration
## des fenetres. Un paysage n'est donc pas un probleme de couverture a resoudre, c'est le meme
## jeu de pieces POSE AUTREMENT : collees sur de la plaine continue au lieu d'etre isolees
## chacune dans son liseré de vide.
##
## ⚠ ET LA SOUDURE SE MESURE, ELLE NE SE SUPPOSE PAS. Deux choses pouvaient la casser, et il
## fallait les chiffrer avant d'ecrire une ligne :
##
##   -- un temoin peut CESSER de porter sa tuile quand son voisinage change. C'est la faute deja
##      payee au dossier (« la decoupe ment : onze tuiles sur cinquante et une avaient disparu
##      au decoupage »). Mesure : les 53 blocs, poses sur de la plaine au lieu du vide, gardent
##      TOUS leur tuile a leur case. Le resultat n'est pas un coup de chance -- ces blocs ont ete
##      trouves DANS des mondes, donc entoures de terrain ; c'est le vide du damier qui etait le
##      contexte artificiel, pas la plaine.
##
##   -- le relief assemble peut devenir ILLEGAL. Mesure, en balayant l'ecart de dix a zero : a
##      trois il est legal et les 53 temoins sont intacts ; a DEUX il devient illegal, temoins
##      pourtant intacts. Ce n'est pas une marge de securite tiree au sort, c'est MIN TROIS --
##      bord, centre, bord -- lu directement a l'ecran du compteur. L'ecart vaut donc trois, et
##      descendre a deux n'est pas « un peu plus serre », c'est un relief que le pinceau refuse.
##
## ⚠ ET LE GUIDE SE COUCHE. Le damier fait 152 x 248, donc debout, et le dossier a mesure qu'un
## guide couche epouse le cadre de travail et gagne 30 % sur le cote de la case. Ce qui compte
## n'est pas le nombre de cases, c'est la taille de la case a l'ecran : le nombre de colonnes est
## donc CHOISI pour approcher le rapport vise, pas fixe a la main.
##
## ⚠ ET ON REVERIFIE DANS LE GUIDE ASSEMBLE, JAMAIS DANS SON COIN -- meme regle que le damier.
## Un temoin juste tout seul peut se faire manger par son voisin ; et la reparation du geste,
## qui passe apres la pose, DEPLACE des cases. Le controle final lit donc le fichier ecrit et
## verifie deux choses distinctes : que chaque temoin porte encore la tuile qu'il annonce, et
## que le vocabulaire entier est present. Les deux, parce qu'une tuile trouvee ailleurs par
## accident rendrait le compte vert pendant que le temoin ment.
const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")
const Witnesses := preload("res://core/massif_witnesses.gd")
const Brush := preload("res://core/brush_vocabulary.gd")
const Lab := preload("res://tools/relief_lab.gd")

## L'ECART LATERAL ENTRE DEUX TEMOINS. ⚠ MESURE, PAS CHOISI : c'est min trois.
const GAP: int = 3

## L'ECART VERTICAL, ET IL N'EST PAS LE MEME. ⚠ UNE FALAISE DESCEND SOUS SON BLOC : un etage
## vaut trois rangees, et le PIED reclame en plus trois rangees de surface porteuse visible sous
## lui (la marge de pied). A trois rangees d'ecart, la jupe d'un temoin tombait sur le chapiteau
## de celui d'en dessous -- onze fautes de marge de pied, et un relief que le pinceau refuse.
## Le nombre est mesure, pas deduit : voir le balayage au dossier.
const VGAP: int = 12

## Le lisere de vide du bord du monde. ⚠ LA PLAINE EST UN MASSIF, ET SA FALAISE TOMBE LA.
## Sans cette marge, le contour du bord se trouve coupe par le cadre de l'image.
const RIM: int = 4

## LE CADRE DE TRAVAIL, en proportion. ⚠ ET ON NE VISE PAS LE RAPPORT DU GUIDE, ON VISE LA
## TAILLE DE LA CASE A L'ECRAN. Ce sont deux choses differentes, et s'y tromper coute : 245 x 151
## affiche un rapport de 1,62, plus proche du cadre que 209 x 151 et son 1,38 -- et pourtant la
## case y est PLUS PETITE, parce que c'est `min(largeur/colonnes, hauteur/rangees)` qui decide,
## jamais le rapport. Le dossier le dit depuis longtemps : ce qui compte n'est pas le nombre de
## cases, c'est la taille de la case. On optimise donc la grandeur qu'on veut, pas une qui lui
## ressemble.
const FRAME: Vector2 = Vector2(16.0, 9.0)

## Combien de mondes du vivier on interroge pour les tuiles sans temoin.
## ⚠ ET IL SE REGLE, PARCE QU'UN BALAYAGE NE PEUT PAS PAYER LA BATTUE A CHAQUE ESSAI.
const POOL_DRAWS: int = 120


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "res://guides/terrain.txt"
	var gap: int = args[1].to_int() if args.size() > 1 else GAP
	var down: int = args[2].to_int() if args.size() > 2 else VGAP
	var draws: int = args[3].to_int() if args.size() > 3 else POOL_DRAWS

	var blocks: Dictionary = Witnesses.blocks()
	var whole: Array[int] = Brush.tiles()
	var pieces: Array[int] = []
	var orphans: Array[int] = []
	for tile: int in whole:
		if blocks.has(tile):
			pieces.append(tile)
		else:
			orphans.append(tile)
	print("le geste atteint %d tuiles ; %d ont un temoin, %d n'en ont pas"
			% [whole.size(), pieces.size(), orphans.size()])

	# ⚠ UN MONDE QUI PORTE UNE TUILE EST SON TEMOIN, et c'est comme ca que le damier couvre ces
	# tuiles-la : il ne pose pas QUE des ilots, il pose aussi des mondes entiers du vivier, et
	# `PIED 21 au ras` n'existe dans le guide livre que par l'un d'eux. Les chercher ici est donc
	# la meme reponse, pas une rustine -- et c'est LE VIVIER COMMUN qu'on interroge, jamais un
	# tirage a nous : deux battues qui ne cherchent pas au meme endroit ne peuvent pas s'accorder.
	var seats_of: Dictionary = {}
	for tile0: int in pieces:
		seats_of[tile0] = Witnesses.AT
	# ⚠ LE VIVIER SE TIRE UNE FOIS, PAS PAR ORPHELIN. Ecrit d'abord dans la boucle, il rejouait
	# quatre cents mondes a chaque tuile cherchee et le batisseur ne rendait plus la main. C'est
	# la carte couteuse recalculee a chaque tour, deja payee sept fois au dossier -- et elle ne
	# se voit d'aucun test, puisque la suite mesure la justesse et pas la duree.
	var pool: Array[PackedStringArray] = []
	if not orphans.is_empty():
		pool = Lab.ground(draws)
		print("  %d tuiles sans temoin : on interroge %d mondes du vivier"
				% [orphans.size(), pool.size()])
	for tile1: int in orphans.duplicate():
		var found: Array = _from_pool(pool, tile1)
		if found.is_empty():
			continue
		blocks[tile1] = found[0]
		seats_of[tile1] = found[1]
		pieces.append(tile1)
		orphans.erase(tile1)
		print("  %s : trouve dans un monde du vivier" % Massifs.describe(tile1))

	var columns: int = _best_columns(pieces, blocks, gap, down)
	var placed: Array[Vector2i] = _pack(pieces, blocks, gap, down, columns)
	var span: Vector2i = _span(pieces, blocks, placed)
	# ⚠ LE BORD DU MONDE EST UN VOISIN COMME UN AUTRE, ET IL A DROIT AU MEME ECART. Premiere
	# version : le paquetage collait le premier temoin de chaque rangee contre le lisere de vide.
	# Un seul en est mort -- `CHAPITEAU 241 libre` devenait `CHAPITEAU 81 au ras` -- et il a fallu
	# le bloc SEUL DANS LA CARTE ENTIERE pour le voir : ni le voisinage, ni la reparation, ni la
	# distance a la plaine n'y etaient pour rien, c'etait le vide a trois cases de sa falaise.
	# La marge vaut donc `RIM + gap`, pas `RIM`.
	# ⚠ ET LA MARGE DU BAS N'EST PAS CELLE DU HAUT. Une falaise descend SOUS son bloc : un etage
	# vaut trois rangees, et le PIED reclame trois rangees de surface porteuse visible sous lui.
	# Mesure, bloc par bloc et souds un a un : sans rab, DIX-NEUF des cinquante-trois temoins
	# rendent un relief illegal ; a douze rangees de plaine sous eux, AUCUN. La derniere rangee
	# du paysage n'en avait que `RIM + gap`, c'est-a-dire sept -- d'ou onze fautes de marge de
	# pied que ni l'ecart vertical ni la reparation ne faisaient bouger, puisqu'elles n'etaient
	# ni entre deux temoins ni reparables.
	var edge: int = RIM + gap
	var wide: int = span.x + 2 * edge
	var tall: int = span.y + edge + RIM + down
	# ⚠ ON PUBLIE LA GRANDEUR QU'ON A OPTIMISEE, pas une autre. La case est donnee pour un cadre
	# de 1300 x 950, la zone de travail d'un ecran ordinaire : c'est ce nombre que l'artiste voit.
	var side: float = minf(1300.0 / float(wide), 950.0 / float(tall))
	print("  %d colonnes, %d x %d cases -- %.1f px la case sur un cadre de 1300 x 950"
			% [columns, wide, tall, side])

	# LE SOL EST DE LA PLAINE PARTOUT, et c'est la seule difference avec le damier.
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(1)
		grid.append(line)

	var seats: Array[Vector2i] = []
	for at: int in range(pieces.size()):
		var origin: Vector2i = placed[at] + Vector2i(edge, edge)
		_weld(grid, blocks[pieces[at]] as PackedStringArray, origin)
		seats.append(origin + (seats_of[pieces[at]] as Vector2i))

	# LE BORD DU MONDE. ⚠ POSE EN DERNIER, PAR ECRASEMENT : `_weld` prend le maximum, comme le
	# damier, donc un vide pose avant serait remonte a la plaine par la premiere pose venue.
	for y1: int in range(tall):
		for x1: int in range(wide):
			if y1 < RIM or y1 >= tall - RIM or x1 < RIM or x1 >= wide - RIM:
				grid[y1][x1] = 0

	# ⚠ ON NE REPARE QUE SI C'EST NECESSAIRE, ET C'EST UNE DIFFERENCE AVEC LE DAMIER. Le damier
	# repare toujours : ses ilots, verifies seuls, se voisinent une fois assembles et creent des
	# cas qu'aucun d'eux ne portait. Ici la soudure est plus douce -- trois cases de plaine
	# separent deux temoins -- et le relief brut est deja legal. Or `mend` DEPLACE des cases :
	# applique a un relief qui n'en a pas besoin, il a coute un temoin, qui ne portait plus la
	# tuile qu'il annoncait. On repare donc quand il le faut, et seulement alors.
	var raw: PackedStringArray = Gesture.text(grid)
	var text: PackedStringArray = raw
	if not Gesture.legal(raw):
		var mended: PackedStringArray = Gesture.mend(grid)
		if mended.is_empty():
			# ⚠ UN ECHEC MUET EST LE PIRE DES ECHECS. Ce message manquait, et le batisseur
			# ecrivait un relief illegal sans un mot -- seul le controle final le rattrapait,
			# et il fallait le chercher ailleurs.
			print("  la reparation du geste a ECHOUE : le relief reste tel quel")
		else:
			text = mended
			print("  le relief brut demandait une reparation du geste")
	var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(text) + "\n")
	file.close()
	print("paysage ecrit : %s (%dx%d)" % [out, wide, tall])
	quit(0 if _audit(text, whole, pieces, seats, orphans) else 1)


## LE NOMBRE DE COLONNES QUI COUCHE LE MIEUX LE GUIDE.
## ⚠ ON MESURE CHAQUE ESSAI PLUTOT QUE DE CALCULER UNE FORMULE : les temoins n'ont pas tous la
## meme taille, donc la largeur d'une rangee ne se deduit pas du nombre de pieces.
func _best_columns(pieces: Array[int], blocks: Dictionary, gap: int, down: int) -> int:
	var best: int = 1
	var widest: float = 0.0
	for columns: int in range(1, pieces.size() + 1):
		var placed: Array[Vector2i] = _pack(pieces, blocks, gap, down, columns)
		var span: Vector2i = _span(pieces, blocks, placed)
		if span.y <= 0:
			continue
		# ⚠ UNE DERNIERE RANGEE PRESQUE VIDE COUTE SA HAUTEUR POUR RIEN, et c'est exactement ce
		# que ce mode vient gagner : treize colonnes pour cinquante-trois temoins laissaient UN
		# temoin seul sur la derniere rangee, soit un cinquieme de la hauteur en herbe. Le
		# rapport seul ne le voit pas -- il mesure la boite, pas ce qu'il y a dedans.
		var rest: int = pieces.size() % columns
		if rest != 0 and rest * 2 < columns:
			continue
		var side: float = minf(FRAME.x / float(span.x + 2 * RIM),
				FRAME.y / float(span.y + 2 * RIM))
		if side > widest:
			widest = side
			best = columns
	return best


## LA POSE EN RANGEES. Chaque rangee prend la hauteur de son plus grand temoin -- un pas fixe
## gaspillerait la place des petits, et la case a l'ecran se paie en cases perdues.
func _pack(pieces: Array[int], blocks: Dictionary, gap: int, down: int,
		columns: int) -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	var x: int = 0
	var y: int = 0
	var line_tall: int = 0
	for at: int in range(pieces.size()):
		if at > 0 and at % columns == 0:
			x = 0
			y += line_tall + down
			line_tall = 0
		var block: PackedStringArray = blocks[pieces[at]]
		placed.append(Vector2i(x, y))
		x += block[0].length() + gap
		line_tall = maxi(line_tall, block.size())
	return placed


func _span(pieces: Array[int], blocks: Dictionary, placed: Array[Vector2i]) -> Vector2i:
	var wide: int = 0
	var tall: int = 0
	for at: int in range(pieces.size()):
		var block: PackedStringArray = blocks[pieces[at]]
		wide = maxi(wide, placed[at].x + block[0].length())
		tall = maxi(tall, placed[at].y + block.size())
	return Vector2i(wide, tall)


## POSE UN TEMOIN, SOUDE. ⚠ SON VIDE DEVIENT DE LA PLAINE, et c'est exactement ce qui distingue
## ce guide du damier. Le damier garde le vide du bloc parce que sept temoins sont des CORPS
## d'une chute qui n'atterrit pas : leur falaise tombe au bord du monde. Ici la mesure dit qu'ils
## gardent leur tuile quand meme -- la chute retrouve un sol, mais elle en avait deja un dans le
## monde ou le bloc a ete trouve. On le REVERIFIE au controle final plutot que de le croire.
func _weld(grid: Array[PackedByteArray], block: PackedStringArray, origin: Vector2i) -> void:
	for y: int in range(block.size()):
		var row: String = block[y]
		for x: int in range(row.length()):
			var c: String = row[x]
			var level: int = 0 if (c == "~" or c == "." or c == "0") else c.to_int()
			var px: int = origin.x + x
			var py: int = origin.y + y
			if py < 0 or py >= grid.size():
				continue
			var line: PackedByteArray = grid[py]
			if px < 0 or px >= line.size():
				continue
			line[px] = maxi(int(line[px]), level + 1)
			grid[py] = line


## LE CONTROLE FINAL, sur le fichier ecrit. Trois questions distinctes, et il faut les trois.
func _audit(text: PackedStringArray, whole: Array[int], pieces: Array[int],
		seats: Array[Vector2i], orphans: Array[int]) -> bool:
	var good: bool = true
	if not Gesture.legal(text):
		print("  ECHEC : le paysage assemble n'est pas un relief que le pinceau produit")
		# ⚠ ON NOMME LES FAUTES. « Illegal » envoie chercher partout ; « onze fautes de marge de
		# pied » designe l'ecart vertical en un mot.
		for line: String in Gesture.faults(text):
			print("    %s" % line)
		good = false
	else:
		print("  le paysage est legal -- le pinceau peut le construire")

	var posed: Dictionary = Massifs.paintable(text)
	var moved: Array[int] = []
	var shifted: int = 0
	for at: int in range(pieces.size()):
		if int(posed.get(seats[at], -1)) == pieces[at]:
			continue
		# ⚠ ON RETROUVE LE SIEGE, ON NE LE CROIT PAS SUR PAROLE. `mend` deplace des cases : un
		# temoin peut porter sa tuile UNE CASE A COTE. Le siege n'est pas une preuve, c'est un
		# repere -- il sert a POINTER la tuile, et il servira a l'artiste pour aller la peindre.
		# Le corriger est honnete tant qu'on relit ce que la case porte vraiment ; l'abandonner
		# perdrait le repere, le croire serait mentir. On ne cherche qu'AUTOUR : une tuile
		# trouvee a l'autre bout du guide n'est pas ce temoin-ci.
		var fixed: Vector2i = _nearby(posed, seats[at], pieces[at])
		if fixed.x >= 0:
			seats[at] = fixed
			shifted += 1
			continue
		moved.append(pieces[at])
	if shifted > 0:
		print("  %d temoins ont glisse d'une case ou deux a la reparation, sieges corriges"
				% shifted)
	if moved.is_empty():
		print("  les %d temoins portent tous la tuile qu'ils annoncent" % pieces.size())
	else:
		print("  ECHEC : %d temoins ne portent plus leur tuile" % moved.size())
		# ⚠ UN ECHEC QUI NE DIT QUE « ECHEC » FAIT SUPPOSER, ET SUPPOSER COUTE DES ESSAIS. On dit
		# ce que la case porte A LA PLACE, et ou la tuile est passee si elle est ailleurs.
		for at1: int in range(pieces.size()):
			if not moved.has(pieces[at1]):
				continue
			var here: int = int(posed.get(seats[at1], -1))
			var where: String = "rien" if here < 0 else Massifs.describe(here)
			var far: String = "absente du paysage"
			var best: int = 1 << 30
			for cell: Vector2i in posed.keys():
				if int(posed[cell]) != pieces[at1]:
					continue
				var d: int = absi(cell.x - seats[at1].x) + absi(cell.y - seats[at1].y)
				if d < best:
					best = d
					far = "portee %d cases plus loin, en %s" % [d, cell]
			print("    %s" % Massifs.describe(pieces[at1]))
			print("      son siege %s porte : %s" % [seats[at1], where])
			print("      la tuile est %s" % far)
		good = false

	var carried: Dictionary = {}
	for tile1: Variant in posed.values():
		carried[int(tile1)] = true
	var missing: Array[int] = []
	for tile2: int in whole:
		if not carried.has(tile2):
			missing.append(tile2)
	print("  le paysage porte %d tuiles sur %d" % [whole.size() - missing.size(), whole.size()])
	if not missing.is_empty():
		# ⚠ ON LE DIT, ON NE LE TAIT PAS. Un guide incomplet n'est pas une erreur de programme,
		# c'est un etat : ce qui serait une faute, c'est de l'ecrire sans le dire. Le mode ne
		# s'ouvrira que quand ce compte sera nul (charte, regle 5).
		print("  IL MANQUE %d tuiles :" % missing.size())
		for tile3: int in missing:
			var why: String = " (aucun temoin)" if orphans.has(tile3) else " (perdue a la soudure)"
			print("    %s%s" % [Massifs.describe(tile3), why])
		good = false
	return good


## LE MONDE DU VIVIER QUI PORTE UNE TUILE **UNE FOIS SOUDE**.
##
## ⚠ ET C'EST LA DIFFERENCE QUI A COUTE UN ESSAI. Premiere version : on prenait le premier monde
## qui portait la tuile, et on le soudait. Les deux tuiles cherchees sont AU RAS -- et « au ras »
## n'est pas une propriete de la case, c'est une propriete du MASSIF vis-a-vis de celui qui le
## porte : une partie dedans, une partie dehors. Combler le vide d'un monde en plaine change
## precisement ce qui le porte, donc son massif cesse d'etre au ras, donc la case cesse de
## porter sa tuile. Les deux temoins etaient perdus, et le paysage devenait illegal par-dessus.
##
## On ne choisit donc pas un temoin PUIS on le soude : on choisit un temoin QUI SUPPORTE la
## soudure. C'est la meme lecon que « on ne coupe jamais sans reverifier, et dans le CONTEXTE ou
## le temoin sera pose » -- ici le contexte est la plaine continue, pas le vide.
##
## ⚠ ON REND LE MONDE ENTIER, JAMAIS UNE DECOUPE. La decoupe tranche des massifs, donc elle
## change les jonctions qu'elle pretend capturer -- faute deja payee, qui en rejetait le tiers.
func _from_pool(pool: Array[PackedStringArray], tile: int) -> Array:
	for world: PackedStringArray in pool:
		var posed: Dictionary = Massifs.paintable(world)
		for cell: Vector2i in posed.keys():
			if int(posed[cell]) != tile:
				continue
			if _survives_weld(world, cell, tile):
				return [world, cell]
	return []


## LE TEMOIN, SOUDE DANS SON PROPRE CADRE DE PLAINE, PORTE-T-IL ENCORE SA TUILE ?
## ⚠ ON LE JUGE DANS LE CONTEXTE OU IL SERVIRA, pas dans celui ou on l'a trouve.
func _survives_weld(world: PackedStringArray, cell: Vector2i, tile: int) -> bool:
	var pad: int = GAP + RIM
	var wide: int = world[0].length() + 2 * pad
	var tall: int = world.size() + 2 * pad
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(1)
		grid.append(line)
	_weld(grid, world, Vector2i(pad, pad))
	for y1: int in range(tall):
		for x1: int in range(wide):
			if y1 < RIM or y1 >= tall - RIM or x1 < RIM or x1 >= wide - RIM:
				grid[y1][x1] = 0
	var text: PackedStringArray = Gesture.text(grid)
	if not Gesture.legal(text):
		return false
	return int(Massifs.paintable(text).get(cell + Vector2i(pad, pad), -1)) == tile


## LA MEME TUILE, A DEUX CASES PRES. Au-dela ce n'est plus le meme temoin.
func _nearby(posed: Dictionary, seat: Vector2i, tile: int) -> Vector2i:
	for radius: int in range(1, 3):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var at: Vector2i = seat + Vector2i(dx, dy)
				if int(posed.get(at, -1)) == tile:
					return at
	return Vector2i(-1, -1)
