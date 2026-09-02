extends SceneTree

## LE GUIDE DU NOUVEAU MODELE : UN ILOT PAR TUILE, CALCULE.
##
##     godot --headless --path . --script res://tools/build_massifs.gd -- <sortie.txt>
##
## ⚠ IL N'EST PLUS DESSINE A LA MAIN, ET C'EST LA REPONSE A « COMMENT SAIT-ON QU'ON COUVRE
## TOUT ? ». Dix formes dessinees a la main exercaient 37 tuiles sur 88 -- et rien ne le disait.
## Un guide ecrit a la main est une donnee a maintenir, donc un endroit ou mentir : c'est
## exactement l'argument qui fait calculer les 47 index, la planche de preuve et les ilots de
## bord. Ici la FORME CLOSE donne la liste, l'enumeration donne pour chaque tuile une FENETRE qui
## la produit, et l'ilot n'est que cette fenetre ETIREE.
##
## ⚠ ET ON REVERIFIE DANS LE GUIDE ASSEMBLE, JAMAIS DANS SON COIN. Un temoin juste tout seul peut
## se faire manger par sa marge ou son socle : la decoupe ment, c'est deja au dossier. Le controle
## final lit `Massifs.analyse` sur le fichier ecrit, et il verifie en plus que CHAQUE ilot porte
## bien la tuile qu'il annonce -- sans quoi une tuile trouvee ailleurs par accident rendrait le
## compte vert pendant que l'ilot ment.

const HeightMask := preload("res://core/height_mask.gd")
const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifForm := preload("res://core/massif_form.gd")
const Witnesses := preload("res://core/massif_witnesses.gd")
const Lab := preload("res://tools/relief_lab.gd")
const Brush := preload("res://core/brush_vocabulary.gd")

## L'ilot : la fenetre 3x6 etiree de deux cases de chaque cote.
const PAD: int = 2
const ISLE_W: int = MassifForm.COLS + 2 * PAD
const ISLE_H: int = MassifForm.ROWS + 2 * PAD

## Le pave qui porte un ilot, marges comprises.
##
## ⚠ ET C'EST LE SOCLE QUI DICTE SA LARGEUR, PAS L'ILOT. Premier essai a treize : l'ilot fait
## sept, mais son socle en fait onze, et il ne restait que DEUX colonnes de plaine entre deux
## paves -- une course de deux, donc fine, donc 1 368 cases refusees par l'epaisseur. On mesure
## la marge sur ce qu'on pose vraiment, jamais sur ce qu'on croit poser.
const BLOCK_W: int = 19
const BLOCK_H: int = 30
const COLUMNS: int = 8
## La marge de vide autour du guide : la falaise du bord du monde y tombe.
const RIM: int = 4
## Le socle d'un ilot AU RAS : il deborde d'autant, et de quoi porter le pied.
## ⚠ ET LES MARGES DE L'ILOT SUIVENT LA REGLE DU GESTE, PAS L'INVERSE. Elles etaient calibrees
## pour une marge de pied d'UNE rangee ; depuis que min trois vaut aussi sur ce qui se voit, il
## faut TROIS rangees de sol visible sous chaque pied et trois cases de socle visible autour.
const BASE_SIDE: int = 3
const BASE_SOUTH: int = 6
## Le monde de couverture : un relief ENTIER, avec son lisere de vide.
const CUT_W: int = 24
const CUT_H: int = 30


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "res://guides/massifs.txt"
	var draws: int = args[1].to_int() if args.size() > 1 else 400
	# ⚠ ON VISE LE VOCABULAIRE DU PINCEAU, PAS LA FORME CLOSE. Une tuile que le geste ne produit
	# jamais est une tuile que l'artiste peindrait pour rien : le modele doit prevoir ce qu'il
	# faut au GESTE, ni plus ni moins. La forme close reste la borne haute -- elle garde I8.
	var whole: Array[int] = Brush.tiles()
	var wits: Dictionary = MassifForm.sources(false)
	var wits_ras: Dictionary = MassifForm.sources(true)
	var blocks: Dictionary = Witnesses.blocks()
	var wanted: Array[int] = []
	var out_of_reach: Array[int] = []
	for tile: int in whole:
		if _choose(tile, wits_ras if Massifs.flush_of(tile) else wits) >= 0 or blocks.has(tile):
			wanted.append(tile)
		else:
			out_of_reach.append(tile)

	# PHASE UN : COUVRIR LE RECENSEMENT DES JONCTIONS, PAS LA LISTE DES TUILES.
	#
	# ⚠ UN ILOT PAR TUILE EST UNE PROJECTION. Il garantit que chaque DESSIN est peignable et perd
	# tout ce qui se passe ENTRE deux cases -- or c'est la que le modele decide : meme massif ?
	# meme rangee de levre ? quel ecart d'etage ? quelle longueur de chute ? Mesure avant ce
	# changement : le monde posait 140 especes de jonction, le guide en montrait 87. Les 53
	# manquantes etaient exactement les defauts trouves a l'oeil, un par un, seance apres seance.
	#
	# ⚠ ET LE GUIDE EST UNE MOSAIQUE DE MONDES ENTIERS, PAS DE DECOUPES. Une decoupe tranche des
	# massifs, donc elle change les jonctions qu'elle pretend capturer : il fallait la reparer,
	# la relire encadree, et elle en rejetait le tiers. Un monde entier, lui, est legal par
	# construction et porte son propre lisere de vide -- deux mondes voisins sont donc separes
	# par huit cases de vide, sans qu'on ait rien a menager.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x475549
	var pool: Array[PackedStringArray] = []
	var brings: Array[Dictionary] = []
	var targets: Dictionary = {}
	while pool.size() < draws:
		var one: PackedStringArray = Lab.draw(rng, CUT_W, CUT_H)
		if one.is_empty():
			continue
		var got: Dictionary = Lab.species(one)
		pool.append(one)
		brings.append(got)
		for key: String in got.keys():
			targets[key] = int(targets.get(key, 0)) + 1
	print("le monde pose %d especes de jonction (%d mondes)" % [targets.size(), pool.size()])

	# LE CHOIX GLOUTON : a chaque tour, le monde qui apporte le plus d'especes neuves.
	var covered: Dictionary = {}
	var pieces: Array[PackedStringArray] = []
	while covered.size() < targets.size():
		var best: int = -1
		var most: int = 0
		for at3: int in range(pool.size()):
			var gain: int = 0
			for key2: String in (brings[at3] as Dictionary).keys():
				if not covered.has(key2):
					gain += 1
			if gain > most:
				most = gain
				best = at3
		if best < 0:
			break
		pieces.append(pool[best])
		for key3: String in (brings[best] as Dictionary).keys():
			covered[key3] = true
		brings[best] = {}
	print("  %d mondes couvrent %d especes sur %d"
			% [pieces.size(), covered.size(), targets.size()])

	# PHASE DEUX : ce qui manque encore en TUILES, par ilot calcule.
	var carried: Dictionary = {}
	for piece: PackedStringArray in pieces:
		for tile2: Variant in Massifs.paintable(piece).values():
			carried[int(tile2)] = true
	var todo: Array[int] = []
	for tile3: int in wanted:
		if not carried.has(tile3):
			todo.append(tile3)
	print("les mondes portent %d tuiles ; %d ilots a ajouter" % [carried.size(), todo.size()])

	# LA MOSAIQUE : les mondes d'abord, les ilots ensuite, sur une meme grille de paves.
	var per_row: int = 6
	var cells: int = pieces.size() + (todo.size() + per_row - 1) / per_row * per_row
	var rows: int = (pieces.size() + per_row - 1) / per_row
	var isle_rows: int = (todo.size() + COLUMNS - 1) / COLUMNS
	var wide: int = maxi(per_row * CUT_W, COLUMNS * BLOCK_W) + 2 * RIM
	var tall: int = 2 * RIM + rows * CUT_H + isle_rows * BLOCK_H
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	# La plaine ne court que sous les ILOTS : les mondes portent la leur, avec leur vide.
	for y2: int in range(RIM + rows * CUT_H, tall - RIM):
		for x2: int in range(RIM, wide - RIM):
			_put(grid, x2, y2, 0)

	var centres: Array[Vector2i] = []
	var kinds: Array[int] = []
	for at: int in range(pieces.size()):
		_place(grid, pieces[at], RIM + (at % per_row) * CUT_W, RIM + (at / per_row) * CUT_H)
	for at2: int in range(todo.size()):
		var bx: int = RIM + (at2 % COLUMNS) * BLOCK_W
		var by: int = RIM + rows * CUT_H + (at2 / COLUMNS) * BLOCK_H
		var bits: int = _choose(todo[at2], wits_ras if Massifs.flush_of(todo[at2]) else wits)
		if bits >= 0:
			_stamp(grid, todo[at2], bits & 0xffffff, bx, by, bits >> 24)
			centres.append(Vector2i(bx + 3 + PAD + MassifForm.CX,
					by + 3 + PAD + MassifForm.CY))
		else:
			_place(grid, blocks[todo[at2]] as PackedStringArray, bx + 2, by + 2)
			centres.append(Vector2i(bx + 2, by + 2) + Witnesses.AT)
		kinds.append(todo[at2])

	# ⚠ ET LE GUIDE PASSE PAR LA REPARATION DU GESTE AVANT D'ETRE ECRIT. Chaque ilot est verifie
	# SEUL ; assembles, ils se voisinent, et le voisinage cree des cas qu'aucun d'eux ne portait
	# -- huit cases d'herbe fine sur le dernier guide, alors que chaque ilot etait legal. Un guide
	# est un relief comme un autre : il doit etre de ceux que le pinceau produit, donc il subit la
	# meme correction.
	var mended: PackedStringArray = Gesture.mend(grid)
	var text: PackedStringArray = mended if not mended.is_empty() else Gesture.text(grid)
	var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(text) + "\n")
	file.close()
	print("guide ecrit : %s (%dx%d), %d mondes + %d ilots"
			% [out, wide, tall, pieces.size(), todo.size()])
	_audit(text, wanted, centres, kinds, targets, out_of_reach)
	quit(0)


## Le bloc, encadre de plaine puis de vide -- le contexte du guide.
func _alone_block(block: PackedStringArray) -> PackedStringArray:
	var wide: int = block[0].length() + 2 * RIM
	var tall: int = block.size() + 2 * RIM
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(tall):
		var line: String = ""
		for x: int in range(wide):
			if x < 2 or y < 2 or x >= wide - 2 or y >= tall - 2:
				line += "~"
			elif x < RIM or y < RIM or x >= wide - RIM or y >= tall - RIM:
				line += "0"
			else:
				line += block[y - RIM].substr(x - RIM, 1)
		out.append(line)
	return out


func _put(grid: Array[PackedByteArray], x: int, y: int, level: int) -> void:
	if y < 0 or y >= grid.size():
		return
	var line: PackedByteArray = grid[y]
	if x < 0 or x >= line.size():
		return
	line[x] = maxi(int(line[x]), level + 1)
	grid[y] = line


## POSE UN BLOC DE TEMOIN, tel quel : ses etages sont ceux qu'on a mesures, pas un maximum.
## ⚠ ET LE VIDE DU BLOC EST DU VIDE, PAS DE LA PLAINE. Sept temoins sont des CORPS de chute qui
## N'ATTERRIT PAS : leur falaise tombe dans le vide, c'est-a-dire au bord du monde. En comblant
## leur vide de plaine, la chute retrouvait un sol, se raccourcissait, et la case ne portait plus
## rien du tout. Un bloc se pose tel qu'il a ete mesure -- niveaux ET vide -- ou il ne prouve
## rien.
func _place(grid: Array[PackedByteArray], block: PackedStringArray, ox: int, oy: int) -> void:
	for y: int in range(block.size()):
		for x: int in range(block[y].length()):
			if oy + y < 0 or oy + y >= grid.size():
				continue
			if ox + x < 0 or ox + x >= grid[0].size():
				continue
			var here: String = block[y].substr(x, 1)
			grid[oy + y][ox + x] = 0 if here == "~" else here.to_int() + 1


## POSE L'ILOT D'UNE TUILE, et rend la fenetre retenue.
##
## ⚠ UNE TUILE AU RAS EST UN MASSIF D'ETAGE 2, ET C'EST TOUT CE QUE « AU RAS » VEUT DIRE : elle
## en recouvre un autre. On lui donne donc un socle d'etage 1 -- qui doit porter son PIED avec une
## rangee de rab, sans quoi la marge de pied saute.
func _stamp(grid: Array[PackedByteArray], tile: int, bits: int, bx: int, by: int,
		variant: int = 0) -> void:
	var flush: bool = Massifs.flush_of(tile)
	var level: int = 2 if flush else 1
	var isle: Array[PackedByteArray] = MassifForm.stretched(bits, PAD)
	var ox: int = bx + 3
	var oy: int = by + 3
	if flush:
		# ⚠ UN VRAI CHEVAUCHEMENT DEBORDE, IL NE S'ARRETE PAS PILE SUR LE PORTEUR. Premiere
		# version : le socle s'arretait net au bord ouest de l'ilot -- c'est bien un
		# chevauchement, mais le SEUL qu'on montrait, et le plus pauvre : la falaise de l'ilot
		# retombait sur le socle en trois rangees. Or un massif porte qui deborde est plus haut
		# que ce qui le borde, donc la ou il sort du porteur SA FACE DESCEND JUSQU'A LA PLAINE --
		# six rangees. Le guide ne montrait pas ce cas, donc il ne le rendait pas peignable.
		#
		# Variante 0 : le socle couvre le NORD de l'ilot, dont le sud surplombe la plaine.
		# Variante 1 : le socle affleure a l'ouest -- l'ancien cas, garde parce qu'il en est un.
		var stop: int = (ISLE_H / 2) if variant == 0 else (ISLE_H + Massifs.FALL + BASE_SOUTH)
		var start: int = -BASE_SIDE if variant == 0 else 0
		for y: int in range(-BASE_SIDE, stop):
			for x: int in range(start, ISLE_W + BASE_SIDE):
				_put(grid, ox + x, oy + y, 1)
	for x2: int in range(ISLE_W):
		for y2: int in range(ISLE_H):
			if int(isle[x2][y2]) == 1:
				_put(grid, ox + x2, oy + y2, level)


## LA FENETRE QUI TIENT, et c'est la seule facon honnete de la trouver.
##
## ⚠ UNE FENETRE N'EST PAS UN ILOT. L'enumeration raisonne sur trois colonnes et six rangees, et
## elle a le droit de supposer que deux composantes distinctes de la fenetre sont reliees DEHORS.
## L'ilot, lui, est un monde fini : ce qui n'est pas relie dedans ne l'est nulle part. Prendre la
## premiere fenetre venue donnait 53 ilots sur 88 qui portaient une AUTRE tuile que la leur --
## et le compte global, lui, restait content. On essaie donc toutes les fenetres du couple, on
## BATIT l'ilot, et on lit ce que la case porte vraiment.
func _choose(tile: int, wits: Dictionary) -> int:
	if not wits.has(tile):
		return -1
	# ⚠ ET LA VARIANTE QUI DEBORDE PASSE EN PREMIER. Les deux sont des chevauchements ; celle
	# qui surplombe la plaine est la plus riche -- c'est elle qui exerce la chute de six.
	for variant: int in [0, 1]:
		for bits: int in (wits[tile] as Array[int]):
			var mini: PackedStringArray = _alone(tile, bits, variant)
			var paint: Dictionary = Massifs.paintable(mini)
			var centre: Vector2i = Vector2i(RIM + BASE_SIDE + PAD + MassifForm.CX,
					RIM + BASE_SIDE + PAD + MassifForm.CY)
			if int(paint.get(centre, -1)) != tile:
				continue
			if not Lab.legal(mini):
				continue
			return (variant << 24) | bits
	return -1


## L'ilot seul dans son cadre, pour le juger avant de le poser.
func _alone(tile: int, bits: int, variant: int) -> PackedStringArray:
	var wide: int = 2 * RIM + 2 * BASE_SIDE + ISLE_W
	var tall: int = 2 * RIM + 2 * BASE_SIDE + ISLE_H + 2 * Massifs.FALL + BASE_SOUTH
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	for y2: int in range(RIM, tall - RIM):
		for x2: int in range(RIM, wide - RIM):
			_put(grid, x2, y2, 0)
	_stamp(grid, tile, bits, RIM - 3 + BASE_SIDE, RIM - 3 + BASE_SIDE, variant)
	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said: String = ""
		for v: int in line2:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	return text


## CE QUE LE GUIDE PORTE VRAIMENT, lu sur le fichier ecrit.
func _audit(world: PackedStringArray, wanted: Array[int], centres: Array[Vector2i],
		chosen: Array[int], targets: Dictionary, out_of_reach: Array[int]) -> void:
	var got: Dictionary = Massifs.analyse(world, wanted)
	var wrongs: Array[String] = Gesture.faults(world)
	print("  %d/%d tuiles peignables" % [int(got["found"]), int(got["wanted"])])
	print("  le guide est %s" % ("LEGAL" if wrongs.is_empty() else "ILLEGAL : "
			+ ", ".join(wrongs)))
	var paint: Dictionary = Massifs.paintable(world)
	var wrong: int = 0
	var said: Array[String] = []
	# ⚠ ON NE CONTROLE QUE LES ILOTS : les mondes de couverture ne promettent aucune tuile a une
	# case donnee, ils promettent des JONCTIONS. Iterer sur `wanted` lisait `centres` au-dela de
	# sa taille -- et un audit qui plante ne mesure rien.
	for at: int in range(chosen.size()):
		var here: int = int(paint.get(centres[at], -1))
		if here == chosen[at]:
			continue
		wrong += 1
		if said.size() < 10:
			said.append("%s : la case porte %s" % [Massifs.describe(chosen[at]),
					"rien" if here < 0 else Massifs.describe(here)])
	print("  %d ilot(s) qui ne portent pas leur tuile" % wrong)
	for one: String in said:
		print("      %s" % one)
	# ⚠ I9 : LA COUVERTURE DES JONCTIONS, lue sur le guide ECRIT. C'est elle qui doit faire
	# converger : tant qu'elle se jugeait a l'oeil, chaque regard trouvait un manque de plus.
	var shown: Dictionary = Lab.species(world)
	var absent: int = 0
	var lacks: Array[String] = []
	for kind: String in targets.keys():
		if shown.has(kind):
			continue
		absent += 1
		if lacks.size() < 10:
			lacks.append(kind)
	print("  JONCTIONS : %d especes sur %d que le monde pose"
			% [targets.size() - absent, targets.size()])
	for one: String in lacks:
		print("      manque : %s" % one)
	var missing: Array[String] = []
	for tile: int in (got["missing"] as Array[int]):
		missing.append(Massifs.describe(tile))
	if not missing.is_empty():
		print("  tuiles manquantes : %s" % " | ".join(missing))
	print("  (%d tuiles hors de portee, refusees au pinceau)" % out_of_reach.size())
