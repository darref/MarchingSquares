# L'ASSEMBLAGE DU CONTOUR PROUVE : d'un relief a une image.
#
# ⚠ TROISIEME ET DERNIER MORCEAU SORTI DU BANC. `core/brink.gd` dit ce qu'une tuile doit savoir,
# `render/contour_tiles.gd` dit comment elle se dessine ; ici on POSE -- les classes de raccord,
# les tuiles de surface, les robes, les poses arriere, et l'empilement etage par etage.
#
# ⚠ ET C'EST CE QUI MANQUAIT POUR QUE LE LOGICIEL VOIE CE QUE LE BANC PROUVE. Tant que
# l'assemblage vivait dans `proof/`, le produit pouvait dessiner une tuile sans jamais pouvoir
# en poser un paysage.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Walls := preload("res://core/walls.gd")
const Brink := preload("res://core/brink.gd")
const Tiles := preload("res://render/contour_tiles.gd")

const RES := Tiles.RES
const GRASS := Tiles.GRASS
const OUTLINE := Tiles.OUTLINE
const ROCK := Tiles.ROCK
const STEPS := Brink.STEPS
const CARDINALS := Brink.CARDINALS
## Les quatre cotes, pour dire un raccord en clair.
const SIDE_NAMES: Array[String] = ["nord", "est", "sud", "ouest"]

## Le pinceau se nomme `Contour` dans le corps deplace : c'est `contour_tiles`.
const Contour := Tiles

## F0 : LE TRAIT AU RAS DU BORD DE LA CASE. Aucune liberte.
##
## ⚠ C'EST LE TEMOIN, ET C'EST SA SEULE RAISON D'ETRE. A F0 le dessin ne peut rien inventer :
## la tuile remplit sa case et pose son trait sur la colonne ou la rangee du bord, la ou son
## cardinal est vide. Si un invariant rougit ici, le defaut est dans le MODELE -- pas dans la
## main. C'est le seul instrument qui separe les deux, et il nous a manque toute la semaine.
static func paint(vocabulary: Dictionary, freedom: int, level: int,
		seed_of: Dictionary) -> Dictionary:
	var tiles: Dictionary = {}
	for key: Variant in vocabulary.keys():
		var index: int = int(key) & 0xff
		var brink: int = int(key) >> 8
		var open: Array[bool] = Brink.surface_open(int(key), level)
		var seams: Array[int] = []
		for side: int in range(4):
			seams.append(int(seed_of.get(node("S", int(key), side), 0)))
		tiles[int(key)] = Contour.shape(open, freedom, GRASS, index, brink, false, false, seams)
	return tiles


## LES ROBES : meme fabrique, autres bords ouverts.
##
## ⚠ ET C'EST TOUT CE QUE L2 AJOUTE AU DESSIN. Une tuile de robe a exactement les memes
## frontieres qu'une surface, seulement designees autrement : la CRETE en haut du chapiteau,
## le PIED en bas de la derniere rangee, et les flancs qui S'ARRETENT. Partout ailleurs la
## roche continue chez la voisine, comme la matiere d'une surface continue chez la sienne.
##
## ⚠ ET PAS D'ERGOT DE COIN RENTRANT. Il demande de savoir si la DIAGONALE est vide alors que
## les deux cardinaux sont pleins ; un role de robe -- deux flancs, une rangee -- ne porte pas
## cette information. On note ce que le banc en dira plutot que de l'inventer.
## LA CLE D'UNE TUILE DE ROBE A DEUX FORMES, selon le cote ou le bit de J2 est pose :
## (pan, rangee) quand c'est la surface qui se tait, (pan, rangee, cession) quand c'est la
## face. Une pose arriere est cachee sous une surface -- elle ne cede son trait a personne,
## d'ou zero.
static func wall_key(role: Vector2i) -> Variant:
	return Vector3i(role.x, role.y, 0) if Brink.j2_on_face else role


## LE PAN DONT LES DEUX FLANCS CONTINUENT -- calcule, jamais ecrit en dur : c'est le seul
## role sans aucun cote ouvert, donc le seul carre de roche sans trait.
static func solid_pan() -> int:
	for pan: int in range(Walls.PAN_COUNT):
		if Walls.pan_west(pan) == Walls.SIDE_CONTINUE \
				and Walls.pan_east(pan) == Walls.SIDE_CONTINUE:
			return pan
	return 0


## La meme tuile, sa matiere sans son trait.
static func muted(tile: Image) -> Image:
	var out: Image = tile.duplicate() as Image
	for y: int in range(RES):
		for x: int in range(RES):
			if out.get_pixel(x, y).is_equal_approx(OUTLINE):
				out.set_pixel(x, y, ROCK)
	return out


## LA POSE ARRIERE QUI NE GARDE QU'UNE PART DE SON TRAIT.
##
## ⚠ ET ON N'Y TOUCHE PAS A LA MATIERE, C'EST TOUTE LA LECON DE L'ESSAI PRECEDENT. J'avais
## d'abord ferme la crete et le pied du role -- ce qui change les cotes OUVERTS, donc la forme,
## donc la matiere : la roche s'etendait jusqu'au bord et le trait des flancs pendait en haut
## comme en bas. 90 extremites sur la planche, et I6 rouge. La matiere d'une pose arriere est ce
## que le modele NOMME (I6) ; seul son TRAIT est negociable.
##
## On part donc de la vraie tuile et on eteint des pixels de contour, jamais des pixels de
## matiere. Un pixel de contour appartient a la CRETE ou au PIED si le vide qu'il borde est
## au-dessus ou au-dessous ; a un FLANC si ce vide est a gauche ou a droite.
static func muted_but(tile: Image, keep_vertical: bool) -> Image:
	var out: Image = tile.duplicate() as Image
	for y: int in range(RES):
		for x: int in range(RES):
			if not tile.get_pixel(x, y).is_equal_approx(OUTLINE):
				continue
			var vertical: bool = false
			var lateral: bool = false
			for side: int in range(4):
				var probe: Vector2i = Vector2i(x, y) + STEPS[side]
				var outside: bool = probe.x < 0 or probe.y < 0 or probe.x >= RES 						or probe.y >= RES or tile.get_pixel(probe.x, probe.y).a < 0.5
				if not outside:
					continue
				if side == 0 or side == 2:
					vertical = true
				else:
					lateral = true
			if vertical if keep_vertical else lateral:
				continue
			out.set_pixel(x, y, ROCK)
	return out


static func wall_tiles(roles: Dictionary, freedom: int, seed_of: Dictionary) -> Dictionary:
	var tiles: Dictionary = {}
	for key: Variant in roles.keys():
		var open: Array[bool] = Contour.wall_open(key)
		var seams: Array[int] = []
		for side: int in range(4):
			seams.append(int(seed_of.get(node("W", key, side), 0)))
		tiles[key] = Contour.shape(open, freedom, ROCK, -1, 0, false, true, seams)
	return tiles


## L'EMPILEMENT : une tuile par etage et par case, du bas vers le haut.
##
## C'est la regle du depot, pas une invention du banc : « on dessine du bas vers le haut,
## chaque couche recouvrant la precedente ».
##
## ⚠ ET « LE SOMMET TRACE, LES ENTERRES SE POSENT PLEINS » A ETE ESSAYE PUIS REFUTE. C'etait
## la reponse que le plan pronait pour L1, et elle se defend : une case appartient ENTIEREMENT
## a chaque silhouette qui la contient, donc le monde n'y a pas de bord et l'entaille n'est
## qu'une decoration du bord visible. Poser la tuile pleine sous le sommet efface bien les
## paves -- 6 a L1/F2, zero apres.
##
## Mais elle en ouvre 26 ailleurs : le bord d'un etage qui passe SOUS un plateau voisin cesse
## d'etre trace, et le contour de la terrasse s'arrete net au pied du plateau au lieu d'y
## rejoindre le sien. Ce que l'etage enterre dessine n'est donc pas une decoration : c'est ce
## qui RACCORDE deux terrasses de niveaux differents. Mesure : 26 extremites contre 6 paves.
##
## On garde donc l'empilement complet, et le defaut restant -- six pixels a une jonction en T
## entre les bords de deux etages -- attend son propre diagnostic.
## LA POSE ARRIERE, RECADREE SOUS LA MATIERE DE LA CASE QUI LA COUVRE, au nord seulement.
## Colonne par colonne : tout ce qui est au-dessus du premier pixel opaque du couvercle est
## efface de la roche reposee.
## CE QUI COUVRE UNE CASE, A CHEVAL : les quatre quarts des quatre tuiles de croisement qui
## se partagent la case. La tuile du croisement (i, j) est posee en `(i, j) * RES - RES / 2`,
## donc son quart sud-est couvre le quart nord-ouest de la case (i, j).
static func astride_cover(map: Dictionary, tiles: Dictionary, cell: Vector2i) -> Image:
	var out: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	var half: int = RES / 2
	for qy: int in range(2):
		for qx: int in range(2):
			var at: Vector2i = cell + Vector2i(qx, qy)
			if not map.has(at):
				continue
			var tile: Image = tiles[int(map[at])] as Image
			for y: int in range(half):
				for x: int in range(half):
					out.set_pixel(qx * half + x, qy * half + y,
							tile.get_pixel(x + (1 - qx) * half, y + (1 - qy) * half))
	return out


static func clip_north(rock: Image, cover: Image) -> Image:
	var out: Image = rock.duplicate() as Image
	for x: int in range(RES):
		for y: int in range(RES):
			if cover.get_pixel(x, y).a >= 0.5:
				break
			out.set_pixel(x, y, Color(0, 0, 0, 0))
	return out


static func assemble(world: PackedStringArray, storeys: Array[Dictionary],
		tiles: Dictionary, roles: Dictionary, role_tiles: Dictionary,
		under_by_level: Array[Dictionary], backing_tiles: Dictionary,
		astride: bool = false) -> Image:
	var canvas: Image = Image.create_empty(HeightMask.width(world) * RES,
			HeightMask.height(world) * RES, false, Image.FORMAT_RGBA8)
	for storey: int in range(storeys.size()):
		# ⚠ LA POSE ARRIERE PASSE JUSTE AVANT LA SURFACE DE SON ETAGE D'ATTERRISSAGE. Sous
		# celle-ci, donc invisible partout ou la surface est opaque -- et visible par ses
		# coins decoupes, ce qui est exactement l'endroit ou elle manquait.
		var backing: Dictionary = under_by_level[storey]
		for cell: Vector2i in backing.keys():
			var rock: Image = backing_tiles[backing[cell]] as Image
			# ⚠ ET LA POSE ARRIERE NE DEBORDE PAS AU NORD DE LA CASE QUI LA COUVRE. Un
			# chapiteau repose sous sa levre remplit la case ENTIERE ; or la face d'une levre
			# est AU SUD -- c'est le theoreme. Derriere l'encoche NORD de la levre il n'y a
			# donc pas de roche, il y a ce que le monde a la : le vide, ou la terrasse d'en
			# dessous. Sans ce recadrage, la roche y sort avec un bord que personne ne trace,
			# et le trait de la terrasse voisine vient mourir dessus.
			#
			# ⚠ C'EST UNE POSE, PAS UNE TUILE. Zero dessin de plus : on ne fait que ne pas
			# poser ce que le modele ne met pas la.
			# ⚠ ET A CHEVAL, CE QUI COUVRE UNE CASE EST FAIT DE QUATRE TUILES, PAS D'UNE.
			# `storeys` y est indexe par CROISEMENT ; demander `cover[cell]` avec une
			# coordonnee de CASE tombe sur une cle qui existe -- les deux familles partagent
			# le type `Vector2i` -- et rogne la roche contre une tuile decalee d'une
			# demi-case, dont la transparence n'a rien a voir avec celle qui couvre vraiment
			# cette case. C'est la faute des deux carnets qui se melangent, ici dans le banc.
			var cover: Dictionary = storeys[storey]
			if astride:
				rock = clip_north(rock, astride_cover(cover, tiles, cell))
			elif cover.has(cell):
				rock = clip_north(rock, tiles[int(cover[cell])] as Image)
			canvas.blend_rect(rock, Rect2i(0, 0, RES, RES), cell * RES)
		var map: Dictionary = storeys[storey]
		# ⚠ LE DECALAGE EST D'UN DEMI-PAS, ET C'EST TOUT CE QUE LA FAMILLE A CHEVAL CHANGE A LA
		# POSE. La tuile d'un croisement est centree sur le coin de quatre cases.
		var shift: Vector2i = Vector2i(RES / 2, RES / 2) if astride else Vector2i.ZERO
		for cell: Vector2i in map.keys():
			var tile: Image = tiles[int(map[cell])]
			canvas.blend_rect(tile, Rect2i(0, 0, RES, RES), cell * RES - shift)
	for cell: Vector2i in roles.keys():
		var rock: Image = role_tiles[roles[cell]] as Image
		canvas.blend_rect(rock, Rect2i(0, 0, RES, RES), cell * RES)
	return canvas


## LE NOM D'UN BORD : une famille, une tuile, un cote. C'est l'unite dont on cherche les
## classes -- ce qui doit etre le MEME dessin d'une tuile a l'autre.
static func node(kind: String, key: Variant, side: int) -> String:
	if kind == "S":
		return "S%d/%d" % [int(key), side]
	var role: Vector2i = Vector2i(key) if not Brink.j2_on_face else Vector2i((key as Vector3i).x,
			(key as Vector3i).y)
	return "W%d.%d/%d" % [role.x, role.y, side]


static func root(parent: Dictionary, node: String) -> String:
	var at: String = node
	while String(parent[at]) != at:
		at = String(parent[at])
	var walk: String = node
	while String(parent[walk]) != at:
		var next: String = String(parent[walk])
		parent[walk] = at
		walk = next
	return at


static func join(parent: Dictionary, a: String, b: String) -> void:
	if not parent.has(a):
		parent[a] = a
	if not parent.has(b):
		parent[b] = b
	var ra: String = root(parent, a)
	var rb: String = root(parent, b)
	if ra != rb:
		parent[ra] = rb


## LE RECENSEMENT DES RACCORDS -- DEPUIS LE MONDE, JAMAIS DEPUIS UNE FORMULE.
##
## ⚠ C'EST LA LECON LA PLUS CHERE DU DEPOT, ET ELLE EST ECRITE AU DOSSIER : `Seams` deduisait
## ses classes de `row_for` au lieu de les lire du monde, et ignorait 60 jonctions sur 109 --
## l'illustration cassait aux 60, pendant que la suite etait verte.
##
## DEUX RELATIONS, ET ELLES SE MESURENT TOUTES LES DEUX :
##
##   SUPERPOSITION -- dans une meme case, plusieurs tuiles empilees tracent le meme bord. Si
##   elles ne le tracent pas pareil, le trait se dedouble. C'est le defaut deja mesure a
##   L1/F2 : « deux silhouettes d'etages differents peuvent s'arreter au MEME endroit -- la
##   pile, jusqu'a trois sur la planche -- et chacune y trace son bord », 6 paves.
##
##   CONTINUATION -- deux cases cote a cote tracent le meme bord, qui se prolonge de l'une a
##   l'autre. Leurs deux traits doivent se rejoindre a la frontiere commune.
##
## ⚠ ET LA CONTINUATION N'IMPOSE QUE LES DEUX BOUTS, PAS TOUT LE BORD. Deux segments
## colineaires dans deux cases differentes n'ont a se rejoindre qu'AU POINT ou ils se
## touchent. C'est la traversee, et c'est ce qui laisse le milieu libre.
static func seam_classes(storeys: Array[Dictionary], roles: Dictionary, level: int,
		join_continuation: bool) -> Dictionary:
	var parent: Dictionary = {}
	var cells: Dictionary = {}
	for storey: int in range(storeys.size()):
		for cell: Vector2i in (storeys[storey] as Dictionary).keys():
			cells[cell] = true
	for cell: Vector2i in roles.keys():
		cells[cell] = true

	# La pile de chaque case, dans l'ordre du dessin, et les cotes que chacune trace.
	var stacks: Dictionary = {}
	for cell: Vector2i in cells.keys():
		var stack: Array = []
		for storey: int in range(storeys.size()):
			var map: Dictionary = storeys[storey]
			if map.has(cell):
				stack.append(["S", map[cell], Brink.surface_open(int(map[cell]), level)])
		if roles.has(cell):
			stack.append(["W", roles[cell], Contour.wall_open(roles[cell])])
		stacks[cell] = stack
		for entry: Array in stack:
			var open: Array[bool] = entry[2]
			for side: int in range(4):
				if not open[side]:
					continue
				var node: String = node(String(entry[0]), entry[1], side)
				if not parent.has(node):
					parent[node] = node

	# ⚠ ON COMPTE LES RELATIONS OBSERVEES, PAS LES FUSIONS EFFECTUEES. Premiere version : on
	# n'incrementait que quand l'union changeait quelque chose -- donc le compte dependait de
	# l'ORDRE des cases, et la superposition annoncait ZERO lien sur un monde a quatre etages
	# qui en est plein. Un compteur qui ne mesure pas ce qu'il pretend mesurer.
	var superposed: int = 0
	var continued: int = 0
	var crossed: int = 0
	var witness: Array[String] = []
	for cell: Vector2i in cells.keys():
		var stack: Array = stacks[cell]
		# SUPERPOSITION : tout ce qui trace le meme cote dans la meme case.
		for side: int in range(4):
			var first: String = ""
			for entry: Array in stack:
				if not (entry[2] as Array[bool])[side]:
					continue
				var node: String = node(String(entry[0]), entry[1], side)
				if first.is_empty():
					first = node
				else:
					superposed += 1
					join(parent, first, node)
		# CONTINUATION : la meme frontiere qui se prolonge chez la voisine. On ne regarde que
		# l'est et le sud -- l'autre sens est le meme raccord, vu de l'autre cote.
		for step: int in range(2 if join_continuation else 0):
			var toward: Vector2i = Vector2i.RIGHT if step == 0 else Vector2i.DOWN
			var near: Vector2i = cell + toward
			if not stacks.has(near):
				continue
			var sides: Array[int] = []
			sides.assign([0, 2] if step == 0 else [1, 3])
			for side: int in sides:
				for here: Array in stack:
					if not (here[2] as Array[bool])[side]:
						continue
					for there: Array in (stacks[near] as Array):
						if not (there[2] as Array[bool])[side]:
							continue
						continued += 1
						# ⚠ ET ON GARDE LES LIENS QUI TRAVERSENT LES FAMILLES. Ce sont eux
						# qui decident si une surface et une robe doivent se ressembler ; le
						# reste de la cloture les emporte sans qu'on sache d'ou ils viennent.
						if String(here[0]) != String(there[0]):
							crossed += 1
							if witness.size() < 6:
								witness.append("%s en %d,%d contre %s en %d,%d, bord %s"
										% [String(here[0]), cell.x, cell.y,
										String(there[0]), near.x, near.y, SIDE_NAMES[side]])
						join(parent, node(String(here[0]), here[1], side),
								node(String(there[0]), there[1], side))

	var classes: Dictionary = {}
	for node: String in parent.keys():
		var root: String = root(parent, node)
		if not classes.has(root):
			classes[root] = PackedStringArray()
		var members: PackedStringArray = classes[root]
		members.append(node)
		classes[root] = members
	# LA GRAINE D'UNE CLASSE : un entier stable, pour que le trait en depende. C'est ce qui
	# transforme le recensement en experience -- si le dessin varie par classe et que les six
	# invariants restent verts, alors la liberte mesuree est REELLE.
	var seed_of: Dictionary = {}
	var rank: int = 0
	var roots: Array[String] = []
	roots.assign(classes.keys())
	roots.sort()
	for root: String in roots:
		for node: String in (classes[root] as PackedStringArray):
			seed_of[node] = rank
		rank += 1
	return {"parent": parent, "bords": parent.size(), "classes": classes.size(),
			"membres": classes, "superposition": superposed, "continuation": continued,
			"croises": crossed, "temoins": witness, "graine": seed_of}

## LE CHEMIN COMPLET : un relief, une image -- et rien d'autre a savoir.
##
##     var faite: Dictionary = Contour.compose(relief, 3, 1)
##     faite["image"].save_png(...)
##
## ⚠ ELLE NE SERT QUE LA FAMILLE PAR CASE. La famille a cheval pose ses surfaces sur le
## CROISEMENT de quatre cases : c'est un autre monde de tuiles, et le banc le mesure encore
## seul. Ce qui est ici est ce que le logiciel livre.
##
## ⚠ ET LE BANC DOIT RENDRE LA MEME IMAGE, AU BIT PRES. Deux orchestrations d'une meme
## chaine finissent toujours par diverger -- `tools/soft_invariants.gd --contre <png du banc>`
## les confronte, et c'est la seule chose qui rende la copie sure.
static func compose(world: PackedStringArray, level: int, freedom: int) -> Dictionary:
	Tiles.level = level
	# ⚠ LES CLES VIENNENT DU MODELE, ELLES NE SE REFONT PAS ICI. Silhouettes par etage, carte
	# visible, vocabulaire, robes fermees : c'est `core/brink.gd` qui les tient, une fois.
	var made: Dictionary = Brink.keys(world, level)
	var storeys: Array[Dictionary] = made["storeys"]
	var indices: Dictionary = made["indices"]
	var vocabulary: Dictionary = made["vocabulaire"]
	var roles: Dictionary = made["roles"]
	var seen: Dictionary = made["seen"]
	# LES POSES ARRIERE, rangees par etage d'atterrissage : elles passent JUSTE AVANT la surface
	# de leur etage, donc sous elle, et visibles par ses coins decoupes.
	var under_by_level: Array[Dictionary] = []
	for storey: int in range(storeys.size()):
		under_by_level.append({})
	if level >= 3:
		for cell: Vector2i in (seen["underfoot"] as Dictionary).keys():
			var landing: int = HeightMask.level_at(world, cell.x, cell.y)
			if landing < 0:
				continue
			(under_by_level[landing] as Dictionary)[cell] = wall_key(
					(seen["underfoot"] as Dictionary)[cell])
	var seams: Dictionary = seam_classes(storeys, roles, level, false)
	var tiles: Dictionary = paint(vocabulary, freedom, level, seams["graine"])
	var kinds: Dictionary = {}
	for cell: Vector2i in roles.keys():
		kinds[wall_key(roles[cell])] = true
	var role_tiles: Dictionary = wall_tiles(kinds, freedom, seams["graine"])
	var posed_roles: Dictionary = {}
	for cell: Vector2i in roles.keys():
		posed_roles[cell] = wall_key(roles[cell])
	# LA POSE ARRIERE EST MUETTE : sa matiere SANS son contour. C'est I6 qui l'a tranche --
	# la roche pleine inventait jusqu'a 1 506 pixels que le modele n'a pas.
	var backing_tiles: Dictionary = {}
	for key: Variant in role_tiles.keys():
		backing_tiles[key] = muted(role_tiles[key] as Image)
	var image: Image = assemble(world, storeys, tiles, posed_roles, role_tiles,
			under_by_level, backing_tiles, false)
	return {"image": image, "storeys": storeys, "indices": indices, "roles": posed_roles,
			"tiles": tiles, "vocabulaire": vocabulary}
