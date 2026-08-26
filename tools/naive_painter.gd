extends SceneTree

## LE PEINTRE NAIF : ce que ca donne si un artiste peint les 47 tuiles a la va-vite.
##
## ⚠ CE N'EST PAS L'ILLUSTRATION. Celle-la est CALCULEE depuis le relief : elle se referme par
## construction, et ne prouve donc que la SUFFISANCE du vocabulaire. Ici on fait l'inverse :
## on peint chaque tuile **avec la seule information que la tuile possede** -- sa silhouette
## pour une surface, son pan et sa rangee pour une robe -- au trait droit, sans arrondi, sans
## marque, sans rien deviner du voisinage. Puis on assemble et on regarde.
##
## C'est le seul test qui reponde a « est-ce que ca se referme quand c'est PEINT ». S'il reste
## un trou, c'est que la tuile aurait eu besoin de savoir quelque chose qu'elle ne sait pas --
## et c'est exactement ce que la decomposition en couches pretend avoir supprime.
##
## ⚠ ET ON PEINT PAR LE CHEMIN NORMAL, avec la propagation des raccords. Les bords se
## recopient comme sous le crayon de l'acheteur : si la propagation ecrivait de travers, on le
## verrait ici.

const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")
const Assembly := preload("res://render/assembly.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Modes := preload("res://core/modes.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Seams := preload("res://core/seams.gd")
const WorkIO := preload("res://core/work_io.gd")

const RES: int = 16
## ⚠ LE TRAIT NE TOUCHE JAMAIS LE BORD DE SA CASE. Il le TRAVERSE a une profondeur
## canonique -- la meme pour tout le monde -- et flotte librement entre les deux traversees.
## C'est ca, « libre lateralement dans sa tuile » : la position est libre partout SAUF aux
## deux points ou deux tuiles doivent se retrouver. Sans ce point commun, deux traits voisins
## arrivent au bord a des hauteurs differentes et le contour se rompt ; avec lui, ils se
## rejoignent par construction, sans qu'aucune des deux n'ait rien a savoir de l'autre.
## ⚠ ET CETTE PROFONDEUR VAUT ZERO, C'EST-A-DIRE QUE LE TRAIT PASSE PAR LES COINS DE LA CASE.
## Mesure faite : a trois pixels du bord, le contour tombe a 200 morceaux dont 190 tirets ; au
## contact, 34 morceaux et zero tiret. La raison est geometrique et sans appel -- quand un
## coude traverse deux tuiles, le bout de trait qui remonte le long de la frontiere n'appartient
## a AUCUNE des deux : chacune voit de la matiere chez l'autre et ne trace rien.
##
## La liberte reste entiere entre ces points : le trait fait ce qu'il veut a l'interieur, il
## doit seulement passer par les coins. C'est le prix minimal de la fermeture, et il ne se
## negocie pas.
const CROSS: int = 0          ## la profondeur de traversee, en pixels
const REACH: int = 3          ## et de combien la ligne s'en ecarte au milieu


const GRASS: Color = Color("#6f8a4a")
const GRASS_LIP: Color = Color("#8aa661")
const ROCK: Color = Color("#7d6b53")
const ROCK_DARK: Color = Color("#7d6b53")   ## la meme roche : le seul fonce doit etre le trait
const ROCK_FOOT: Color = Color("#7d6b53")
const OUTLINE: Color = Color("#1d2414")   ## le trait de bord, celui que l'artiste trace


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "res://peint.png"
	var tile: int = int(args[1]) if args.size() > 1 else 20
	var relief: PackedStringArray = ProofScene.relief(Families.BY_CELL)
	var painting: Painting = Painting.new(RES)

	# ⚠ LES JUMELLES SE GROUPENT PAR CLE, PAS PAR CARTE DE SURFACE. `paintable_map` ne rend
	# que les surfaces -- les robes se rangent ailleurs. Premier essai : je n'ai partage que
	# les surfaces, donc chaque role n'a ete peint que sur UNE case et les falaises sont
	# sorties vides. `WorkIO.slots` donne la cle de CHAQUE case, S et W confondues ; on
	# regroupe dessus.
	var flocks: Dictionary = {}
	var slots: Dictionary = WorkIO.slots(relief, Families.BY_CELL)
	for cell: Vector2i in slots.keys():
		var key: String = str(slots[cell]).split(":")[0]
		if not flocks.has(key):
			flocks[key] = ([] as Array[Vector2i])
		(flocks[key] as Array[Vector2i]).append(cell)
	for key: Variant in flocks.keys():
		painting.share(flocks[key] as Array[Vector2i])

	var surface: Dictionary = Families.surface_map(Families.BY_CELL, relief)
	var roles: Dictionary = Walls.visible_roles(relief)
	var done: Dictionary = {}
	var painted: int = 0
	for at: Vector2i in surface.keys():
		var tile_id: int = int(surface[at])
		if done.has("S%d" % tile_id):
			continue
		done["S%d" % tile_id] = true
		_paint_surface(painting, at, tile_id)
		painted += 1
	for at: Vector2i in roles.keys():
		var role: Vector2i = roles[at]
		if done.has("W%d,%d" % [role.x, role.y]):
			continue
		done["W%d,%d" % [role.x, role.y]] = true
		_paint_wall(painting, at, role)
		painted += 1
	print("tuiles peintes : %d  (au trait droit, sans arrondi ni marque)" % painted)
	# ⚠ ON COMPTE CE QU'ON A VRAIMENT POSE. Deux fois de suite j'ai dit « le trait est la »
	# en regardant une image ; il ne l'etait pas. Un comptage tranche en une ligne.
	for at: Vector2i in roles.keys():
		var role: Vector2i = roles[at]
		if not (role.x == Walls.pan_of(Walls.SIDE_STOP, Walls.SIDE_CONTINUE)
				or role.x == Walls.pan_of(Walls.SIDE_CONTINUE, Walls.SIDE_CONTINUE)):
			continue
		var probe: Image = painting.image_of(at)
		var outline: int = 0
		var matter: int = 0
		for y: int in range(RES):
			for x: int in range(RES):
				var c: Color = probe.get_pixel(x, y)
				if c.a < 0.5:
					continue
				matter += 1
				if c.is_equal_approx(OUTLINE):
					outline += 1
		print("   %-34s matiere %3d, trait %3d" % [Walls.role_name(role), matter, outline])
		if outline > 0 or matter > 0:
			break

	var image: Image = Assembly.from_painting(relief, painting, Families.BY_CELL)
	_count_loose_ends(image)
	_count_holes(image, relief)
	_check_silhouettes(image, relief)
	# ⚠ UN GROS PLAN, SINON ON NE JUGE RIEN. A dix pixels par case on voit une silhouette, pas
	# une jonction. Les quatre arguments suivants decoupent en CASES, puis on agrandit au plus
	# proche -- jamais un lissage, qui inventerait des coutures que le dessin n'a pas.
	if args.size() >= 6:
		var cx: int = int(args[2])
		var cy: int = int(args[3])
		var cw: int = int(args[4])
		var ch: int = int(args[5])
		var crop: Image = Image.create(cw * RES, ch * RES, false, image.get_format())
		crop.blit_rect(image, Rect2i(cx * RES, cy * RES, cw * RES, ch * RES), Vector2i.ZERO)
		crop.resize(cw * tile, ch * tile, Image.INTERPOLATE_NEAREST)
		image = crop
	image.save_png(out)
	print("ecrit : %s  (%d x %d px)" % [out, image.get_width(), image.get_height()])
	quit()


## LE VAGABONDAGE : le trait serpente A L'INTERIEUR, et touche le bord de la case A SES DEUX
## BOUTS.
##
## ⚠ C'EST CE PINCEMENT, ET LUI SEUL, QUI FAIT QUE LE CONTOUR SE REFERME. Le dernier pixel
## d'une tuile touche le premier de sa voisine : les deux traits se rejoignent par
## construction, sans qu'aucune des deux n'ait rien a savoir de l'autre. Entre ces deux bouts,
## la ligne fait ce qu'elle veut.
##
## ⚠ ET UNE SEULE BOSSE PAR CASE. Deux ou trois oscillations a l'interieur d'une case ne se
## lisent pas comme une cote mais comme une SCIE -- le pincement revient tous les seize
## pixels, et si le trait bouge plus vite que ca, l'oeil ne voit plus que des dents.
func _wander(seed_a: int, seed_b: int, t: float) -> int:
	var seed: int = absi((seed_a + 1) * 73856093 ^ (seed_b + 1) * 19349663)
	var skew: float = 0.75 + 0.55 * float(seed % 101) / 100.0
	var height: float = float(1 + seed % REACH)
	return CROSS + int(round(height * sin(PI * pow(t, skew))))


## UNE SURFACE : la case pleine, creusee d'une bosse a chaque cardinal VIDE.
##
## ⚠ RIEN AU SUD. Une case dont le sud est vide est une levre : sa falaise commence juste
## dessous, et c'est le CHAPITEAU qui porte la crete -- lui seul peut la faire serpenter, en
## dessinant de l'herbe au-dessus d'elle.
func _paint_surface(painting: Painting, at: Vector2i, tile_id: int) -> void:
	var index: int = BlobIndex.silhouette(tile_id)
	var mask: Array[PackedByteArray] = _solid_mask()
	if (index & BlobIndex.N) == 0:
		_carve(mask, index, 0, true, false)
	if (index & BlobIndex.E) == 0:
		_carve(mask, index, 1, false, true)
	if (index & BlobIndex.W) == 0:
		_carve(mask, index, 2, false, false)
	_lay(painting, at, mask, GRASS, [(index & BlobIndex.N) == 0,
			(index & BlobIndex.E) == 0, false, (index & BlobIndex.W) == 0])


## UNE ROBE : la roche, creusee aux flancs qui S'ARRETENT -- et le CHAPITEAU porte la crete.
func _paint_wall(painting: Painting, at: Vector2i, role: Vector2i) -> void:
	var mask: Array[PackedByteArray] = _solid_mask()
	var tag: int = 1000 + role.x * 8 + role.y
	if role.y == 0:
		_carve(mask, tag, 0, true, false)      # la crete, en haut du chapiteau
	# ⚠ UN FLANC QUI S'ARRETE NE SE CREUSE PAS : IL SE TRAIT. La roche va jusqu'au bord de sa
	# case et l'artiste marque sa fin d'un trait -- `opens` dit a `_lay` qu'au-dela il n'y a
	# rien, donc la colonne du bord est cernee. C'est la regle des couches appliquee a la
	# lettre : une tuile REMPLIT sa case, et ce qui est a cote appartient au voisin.
	#
	# Les deux autres reglages ont ete essayes et mesures, et chacun echange un defaut contre
	# l'autre parce qu'aucun ne touche la cause -- LES DEUX COTES CREUSAIENT LA MEME FRONTIERE :
	#   * creuser en pincant au bord (profondeur 0) : le creux se referme tous les seize pixels
	#     et se decoupe en une CHAINE DE LENTILLES, deux petits arcs mirrores par rangee ;
	#   * creuser en pincant a profondeur commune : le creux devient une bande continue -- plus
	#     d'ovales -- mais ses deux bords ne se rejoignent plus nulle part : 138 morceaux dont
	#     114 segments ouverts, la ou il y en avait 34 fermes.
	# Ne pas creuser du tout supprime le creux, donc la question.
	if role.y == Walls.ROW_FOOT:
		_carve(mask, tag, 3, true, true)
	# ⚠ ET LA CLOTURE RESTE AU RAS DU BORD, APRES TROIS ESSAIS MESURES. La rentrer d'un pixel
	# la separe du contour du plateau voisin -- donc plus de demi-lentilles -- mais elle cesse
	# de retrouver la crete et le pied : 39 morceaux dont 5 tirets. La retirer tout a fait est
	# pire encore : elle porte la connexite du contour de toute la falaise, et sans elle la
	# crete et le pied s'arretent dans le vide -- 90 morceaux dont 55 tirets.
	#
	# ⚠ ET RETIRER LA CLOTURE NE PERDRAIT POURTANT AUCUNE LIMITE : un flanc qui s'arrete ne
	# borde JAMAIS de la roche -- c'est un theoreme, `SIDE_STOP` veut dire « aucune face sur la
	# case d'a cote » -- et le recensement le confirme, 0 sur 5 216 flancs (35,5 % de terre,
	# 64,5 % de vide). La couleur change donc toute seule partout ou le trait disparaitrait.
	# C'est la CONNEXITE qui l'exige, pas la lisibilite.
	_lay(painting, at, mask, ROCK, [role.y == 0,
			Walls.pan_east(role.x) != Walls.SIDE_MUTE, role.y == Walls.ROW_FOOT,
			Walls.pan_west(role.x) != Walls.SIDE_MUTE])


## La roche s'arrete UN PIXEL avant le bord, tout droit, sans onduler.
##
## ⚠ DROIT, ET C'EST LA CONDITION. Une rangee de robe retrouve la rangee suivante DE SA PROPRE
## CHUTE : si le flanc ondulait, il faudrait qu'il revienne a une profondeur commune a chaque
## frontiere de rangees, et cette profondeur commune est justement ce qui recolle les deux
## traits. Droit a un pixel, il n'y a plus de frontiere a negocier : la paroi descend d'un
## trait, et le contour du plateau voisin ne vient jamais le toucher.
func _carve_flat(mask: Array[PackedByteArray], far: bool, depth: int) -> void:
	for y: int in range(RES):
		for d: int in range(depth):
			var row: PackedByteArray = mask[y]
			row[RES - 1 - d if far else d] = 0
			mask[y] = row


func _solid_mask() -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	for y: int in range(RES):
		var row: PackedByteArray = PackedByteArray()
		row.resize(RES)
		for x: int in range(RES):
			row[x] = 1
		out.append(row)
	return out


## Creuse une bosse le long d'un cote. [param axis] 0 nord, 1 est, 2 ouest, 3 sud.
func _carve(mask: Array[PackedByteArray], tag: int, axis: int, horizontal: bool,
		far: bool) -> void:
	for i: int in range(RES):
		var t: float = float(i) / float(RES - 1)
		var depth: int = _wander(tag, axis, t)
		for d: int in range(depth):
			if horizontal:
				var y: int = RES - 1 - d if far else d
				var row: PackedByteArray = mask[y]
				row[i] = 0
				mask[y] = row
			else:
				var x: int = RES - 1 - d if far else d
				var row2: PackedByteArray = mask[i]
				row2[x] = 0
				mask[i] = row2


## Pose la matiere, puis cerne son bord. Le trait fait UN pixel, partout.
func _lay(painting: Painting, at: Vector2i, mask: Array[PackedByteArray], body: Color,
		opens: Array) -> void:
	for y: int in range(RES):
		for x: int in range(RES):
			if mask[y][x] == 0:
				continue
			var border: bool = false
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if not _solid(mask, x + step.x, y + step.y, opens):
					border = true
			_stroke(painting, at, x, y, OUTLINE if border else body)




## LE CRITERE, TEL QUE L'UTILISATEUR L'A POSE : « toutes les silhouettes faites d'un trait, en
## plusieurs segments parfaitement relies, et de la meme epaisseur partout ».
##
## Il se mesure, et en deux nombres :
##   1. AUTANT DE TRAITS QUE DE MASSIFS. Un massif est une tache de matiere ; son contour doit
##      etre un seul morceau. Plus de morceaux que de massifs = un contour brise quelque part.
##   2. AUCUN PAVE 2x2 ENTIEREMENT DE TRAIT. Un trait d'un pixel ne peut pas en remplir un ;
##      des qu'il y en a un, deux traits se sont colles ou un trait a double.
##
## ⚠ ET LE SECOND EST CELUI QUI ATTRAPE LES DEMI-LENTILLES. Le premier les laisse passer : deux
## traits qui se touchent forment un seul morceau, donc le compte de morceaux est content
## pendant que l'oeil voit un renflement. C'est exactement la faute deja payee ici -- « pas
## d'extremite » disait zero pendant que l'oeil voyait des segments.
func _check_silhouettes(image: Image, heights: PackedStringArray) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var massifs: int = _components(image, width, height, false)
	var roles: Dictionary = Walls.visible_roles(heights)
	var by_kind: Dictionary = {}
	var thick: int = 0
	var where: Array[String] = []
	for y: int in range(height - 1):
		for x: int in range(width - 1):
			var full: bool = true
			for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				if not image.get_pixel(x + d.x, y + d.y).is_equal_approx(OUTLINE):
					full = false
					break
			if full:
				thick += 1
				var cell: Vector2i = Vector2i(x / RES, y / RES)
				var level: int = HeightMask.level_at(heights, cell.x, cell.y)
				var kind: String = "robe" if roles.has(cell) else (
						"plaine" if level == 0 else "etage %d" % level)
				by_kind[kind] = int(by_kind.get(kind, 0)) + 1
				if where.size() < 4:
					where.append("%d,%d" % [cell.x, cell.y])
	print("massifs : %d   paves 2x2 de trait : %d   %s" % [massifs, thick, str(where)])
	for kind: Variant in by_kind.keys():
		print("   %-10s %d" % [str(kind), int(by_kind[kind])])


func _components(image: Image, width: int, height: int, outline: bool) -> int:
	var seen: Dictionary = {}
	var count: int = 0
	for y: int in range(height):
		for x: int in range(width):
			if _is_kind(image, x, y, outline) == false:
				continue
			var root: int = y * width + x
			if seen.has(root):
				continue
			count += 1
			var stack: Array[int] = [root]
			seen[root] = true
			while not stack.is_empty():
				var here: int = stack.pop_back()
				var hx: int = here % width
				var hy: int = here / width
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
						Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1),
						Vector2i(-1, -1)]:
					var nx: int = hx + d.x
					var ny: int = hy + d.y
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					var key: int = ny * width + nx
					if seen.has(key):
						continue
					if _is_kind(image, nx, ny, outline) == false:
						continue
					seen[key] = true
					stack.append(key)
	return count


func _is_kind(image: Image, x: int, y: int, outline: bool) -> bool:
	var c: Color = image.get_pixel(x, y)
	if outline:
		return c.is_equal_approx(OUTLINE)
	return c.a >= 0.5

## LE FOND SE VOIT-IL LA OU LE MONDE A DE LA MATIERE ? On regarde TOUS les pixels.
##
## ⚠ `tools/coverage_proof.gd` ne sonde que le CENTRE de chaque case, et c'est volontaire : les
## coins arrondis de l'illustration laissent voir l'etage d'en dessous, ce qui est voulu. Mais
## un peintre libre ne creuse pas qu'aux coins -- il creuse le long de tout un bord, et si tous
## les etages d'une case creusent au meme endroit (c'est la MEME tuile), personne ne comble.
## Le centre reste plein pendant que le bord est perce : la sonde du centre ne peut pas le voir.
func _count_holes(image: Image, heights: PackedStringArray) -> void:
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var holes: int = 0
	var pixels: int = 0
	var worst: Array[String] = []
	for cy: int in range(height):
		for cx: int in range(width):
			if HeightMask.level_at(heights, cx, cy) < 0:
				continue
			var pierced: int = 0
			for y: int in range(RES):
				for x: int in range(RES):
					var px: int = cx * RES + x
					var py: int = cy * RES + y
					if px >= image.get_width() or py >= image.get_height():
						continue
					pixels += 1
					if image.get_pixel(px, py).a < 0.5:
						pierced += 1
			if pierced > 0:
				holes += 1
				if worst.size() < 6:
					worst.append("%d,%d (%d px)" % [cx, cy, pierced])
	print("fond visible : %d cases percees sur %d pixels de terre   %s"
			% [holes, pixels, str(worst)])

## LE TRAIT EST-IL D'UN SEUL TENANT ? On compte ses MORCEAUX SEPARES.
##
## ⚠ « PAS D'EXTREMITE » NE SUFFIT PAS, ET C'ETAIT MA QUATRIEME ERREUR DE JUGEMENT. Un trait
## de deux pixels d'epaisseur n'a jamais d'extremite : le moindre tiret flottant est deja une
## petite boucle fermee, chaque pixel y ayant deux voisins. Le compte disait zero pendant que
## l'oeil voyait des segments. Ce qu'il faut compter, c'est le nombre de MORCEAUX -- un contour
## par massif, et rien qui flotte a cote.
func _count_loose_ends(image: Image) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var seen: Dictionary = {}
	var sizes: Array[int] = []
	var strokes: int = 0
	var floaters: Array[String] = []
	for y: int in range(height):
		for x: int in range(width):
			if not image.get_pixel(x, y).is_equal_approx(OUTLINE):
				continue
			strokes += 1
			var root: int = y * width + x
			if seen.has(root):
				continue
			var size: int = 0
			var stack: Array[int] = [root]
			seen[root] = true
			while not stack.is_empty():
				var here: int = stack.pop_back()
				size += 1
				var hx: int = here % width
				var hy: int = here / width
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var qx: int = hx + dx
						var qy: int = hy + dy
						if qx < 0 or qy < 0 or qx >= width or qy >= height:
							continue
						var key: int = qy * width + qx
						if seen.has(key):
							continue
						if not image.get_pixel(qx, qy).is_equal_approx(OUTLINE):
							continue
						seen[key] = true
						stack.append(key)
			sizes.append(size)
			if size < 400:
				floaters.append("%d,%d (%d px)" % [x, y, size])
	sizes.sort()
	print("trait : %d pixels, %d morceaux separes" % [strokes, sizes.size()])
	print("   le plus petit : %d px   le plus grand : %d px"
			% [sizes[0] if sizes.size() > 0 else 0,
			sizes[sizes.size() - 1] if sizes.size() > 0 else 0])
	print("   morceaux de moins de 400 px (des tirets qui flottent) : %d" % floaters.size())
	for line: String in floaters.slice(0, mini(10, floaters.size())):
		print("      %s" % line)


## Une case du masque porte-t-elle de la matiere ?
##
## ⚠ HORS DE LA TUILE, LA REPONSE DEPEND DU COTE -- et c'est ce qui manquait. Du cote d'un
## cardinal PLEIN, la matiere continue chez la voisine : repondre « oui » evite de tracer un
## trait sur chaque frontiere, qui quadrillerait le massif. Mais du cote d'un cardinal VIDE,
## il n'y a rien au-dela : repondre « oui » y faisait manquer le pixel du PINCEMENT -- celui
## ou le trait touche le bord -- et le contour se cassait a CHAQUE frontiere de tuile.
## Mesure : 1 652 morceaux au lieu d'un par massif.
static func _solid(mask: Array[PackedByteArray], x: int, y: int, opens: Array) -> bool:
	if y < 0:
		return not bool(opens[0])
	if x >= RES:
		return not bool(opens[1])
	if y >= RES:
		return not bool(opens[2])
	if x < 0:
		return not bool(opens[3])
	return mask[y][x] != 0


## Peindre. Un pixel, sans plus.
##
## ⚠ LES ECHOS DE RACCORD NE SE POSENT PAS ICI. Ils sont le geste de l'EDITEUR, qui recopie
## un pixel de bord dans toute sa classe. On peint ici chaque tuile entiere d'un bloc : tous
## ses bords sont ecrits de toute facon, et un echo n'ajouterait rien. Ce que la suite verifie
## deja de son cote, c'est qu'un echo n'ecrit jamais dans le dehors du destinataire.
func _stroke(painting: Painting, at: Vector2i, x: int, y: int, tint: Color) -> void:
	painting.paint(at, x, y, tint)
