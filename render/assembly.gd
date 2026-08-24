# LE REMONTAGE — le paysage rebati avec les tuiles peintes.
#
# C'est le seul controle que le programme ne peut pas faire a notre place. Il sait prouver
# que les 59 tuiles existent ; il ne sait pas juger qu'elles SE RACCORDENT. Un bord est
# peint d'un cote, son voisin de l'autre, a deux moments differents, et rien ne garantit
# qu'ils se rejoignent -- sauf de le voir. C'est la regle 6 poussee jusqu'au bout, et c'est
# ce qui supprime la boucle essai-export-correction que la regle 2 interdit.
#
# ⚠ DEUX CHEMINS, ET C'EST TOUT L'INTERET. Le meme paysage se remonte de deux facons :
#   - `from_painting()` : la case va directement chercher ce qui est peint dessus ;
#   - `from_sheets()`   : la case demande son index, l'index donne sa place sur la planche,
#                         et l'on relit le pixel la-bas.
# Le second traverse l'exportateur en entier -- disposition, tassement des variantes,
# manifeste. Les deux doivent rendre la MEME image, au pixel pres, et c'est asserte. Si
# l'exportateur range une tuile a la mauvaise case, les deux divergent et le test le dit.
# Un remontage qui ne saurait faire qu'un seul chemin ne prouverait rien : il se contenterait
# de redire ce qu'il vient de lire.
#
# ⚠ UNE CASE NON PEINTE RESTE UN TROU. On ne la remplit pas d'un aplat aimable : un trou est
# la verite, et c'est exactement ce qu'on veut voir.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")
const Families := preload("res://core/families.gd")

## Le fond sur lequel le paysage se pose. Le meme que la zone de travail, pour qu'un trou
## se lise pareil a l'ecran et dans un fichier.
const BACKDROP: Color = Color(0.106, 0.114, 0.125)


## Le paysage remonte avec ce qui est peint, case par case.
static func from_painting(heights: PackedStringArray, painting: Painting,
		family: StringName = Families.BY_CELL) -> Image:
	var side: int = painting.resolution
	var canvas: Image = _canvas(heights, side, family)
	var roles: Dictionary = Walls.visible_roles(heights)
	var by_role: Dictionary = Walls.cells_by_role(roles)
	_blend_buried(canvas, heights, roles, WorkIO.cells_by_key(heights, family),
			painting, side, family)
	var underfoot: Dictionary = _underfoot(heights)
	for cell: Vector2i in underfoot.keys():
		var role: Vector2i = underfoot[cell]
		if not by_role.has(role):
			continue
		for source: Vector2i in by_role[role]:
			var rock: Image = painting.image_of(source)
			if rock != null:
				canvas.blend_rect(rock, Rect2i(0, 0, side, side), _where(cell, side, family))
				break
	for key: Vector2i in _order(heights, family):
		var tile: Image = painting.image_of(key)
		if tile == null:
			continue
		canvas.blend_rect(tile, Rect2i(0, 0, side, side), _where(key, side, family))
	return canvas


## Les etages ENTERRES de chaque case : son index dans chaque silhouette sous son sommet --
## et le sommet inclus quand une robe la couvre, puisqu'elle passe devant. C'est la matiere
## premiere de l'empilement : une tuile par etage et par case, comme le jeu et
## l'illustration. Rend case -> Array[int] d'indexes, du bas vers le haut.
static func _buried_indices(heights: PackedStringArray, roles: Dictionary) -> Dictionary:
	var columns: int = HeightMask.width(heights)
	var rows: int = HeightMask.height(heights)
	var top_level: int = 0
	for y: int in range(rows):
		for x: int in range(columns):
			top_level = maxi(top_level, HeightMask.level_at(heights, x, y))
	var storey_indices: Array[Dictionary] = []
	for storey: int in range(top_level + 1):
		var silhouette: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				line += "#" if HeightMask.level_at(heights, x, y) >= storey else "."
			silhouette.append(line)
		storey_indices.append(Coverage.index_map(silhouette))
	var buried: Dictionary = {}
	for y: int in range(rows):
		for x: int in range(columns):
			var cell: Vector2i = Vector2i(x, y)
			var level: int = HeightMask.level_at(heights, x, y)
			if level < 0:
				continue
			var covered: int = level - 1 + (1 if roles.has(cell) else 0)
			if covered < 0:
				continue
			var stack: Array[int] = []
			for storey: int in range(covered + 1):
				stack.append(int(storey_indices[storey].get(cell, -1)))
			buried[cell] = stack
	return buried


## LE SOCLE ENTERRE, SOUS TOUT LE RESTE. Une seule tuile visible par case suffisait au
## dessin de specification -- l'epaule, le sous-pied et la pose derriere bouchent ses
## coins -- mais elle mentait sur une peinture libre : un pixel laisse transparent -- coin
## decoupe, bord balade -- montrait le fond la ou le jeu montrera le sol couvert. On pose
## donc d'abord les etages enterres, du bas vers le haut.
## ⚠ Famille par case seulement : a cheval, une tuile se lit du sommet de quatre cases,
## il n'y a rien a empiler.
static func _blend_buried(canvas: Image, heights: PackedStringArray, roles: Dictionary,
		by_key: Dictionary, painting: Painting, side: int, family: StringName) -> void:
	if family != Families.BY_CELL:
		return
	var buried: Dictionary = _buried_indices(heights, roles)
	for cell: Vector2i in buried.keys():
		for below: int in (buried[cell] as Array):
			var ground_key: String = "S%d:0" % int(below)
			if not by_key.has(ground_key):
				continue
			var ground: Image = painting.image_of(by_key[ground_key])
			if ground != null:
				canvas.blend_rect(ground, Rect2i(0, 0, side, side),
						_where(cell, side, family))


## L'APERCU EMPILE : pour chaque case du decor, la PILE des cases du guide a dessiner, du
## bas vers le haut -- etages enterres, pied repose, puis la tuile visible. Le panneau ne
## fait que suivre la liste ; la regle d'empilement vit ici, avec ses soeurs.
static func borrow_layers(target: PackedStringArray, guide: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var layers: Dictionary = {}
	var by_key: Dictionary = WorkIO.cells_by_key(guide, family)
	var source_of: Dictionary = borrow(target, guide, family)
	if family == Families.BY_CELL:
		var roles: Dictionary = Walls.visible_roles(target)
		var buried: Dictionary = _buried_indices(target, roles)
		for cell: Vector2i in buried.keys():
			var stack: Array = []
			for below: int in (buried[cell] as Array):
				var ground_key: String = "S%d:0" % int(below)
				if by_key.has(ground_key):
					stack.append(by_key[ground_key])
			if not stack.is_empty():
				layers[cell] = stack
		var underfoot: Dictionary = _underfoot(target)
		for cell: Vector2i in underfoot.keys():
			var role: Vector2i = underfoot[cell]
			var foot_key: String = "W%d,%d:0" % [role.x, role.y]
			if by_key.has(foot_key):
				var stack: Array = layers.get(cell, [])
				stack.append(by_key[foot_key])
				layers[cell] = stack
	for at: Vector2i in source_of.keys():
		var stack: Array = layers.get(at, [])
		stack.append(source_of[at])
		layers[at] = stack
	return layers

## Les cases d'atterrissage et le PIED a y reposer, une case plus bas.
##
## ⚠ CE N'EST PAS UNE TUILE DE PLUS, C'EST UNE POSE DE PLUS. La case d'atterrissage a ses
## coins nord decoupes -- son voisin du nord est la face de la falaise -- et par ces coins
## on voyait le sol au lieu de la roche qui continue derriere. On repose donc le pied
## dessous : la surface le recouvre entierement sauf par ses coins, et c'est exactement la
## qu'il manquait.
static func _underfoot(heights: PackedStringArray) -> Dictionary:
	return Walls.visible_underfoot(heights)



## OU SE POSE, SUR LA TOILE, CE QUE PORTE CETTE CLE.
##
## ⚠ EN FAMILLE A CHEVAL, TOUT SE DECALE D'UNE DEMI-TUILE. Un croisement est a cheval sur
## quatre cases : sa tuile occupe (i-0.5, j-0.5) a (i+0.5, j+0.5). Plutot que de poser des
## coordonnees negatives au bord, on agrandit la toile d'une tuile et on decale les CASES
## d'une demi -- le croisement retombe alors sur des entiers.
static func _where(key: Vector2i, side: int, family: StringName) -> Vector2i:
	if family != Families.BY_CORNER:
		return key * side
	if key.y < 0:
		return Families.from_storage(Families.BY_CORNER, key) * side
	return key * side + Vector2i(side / 2, side / 2)


## Le paysage remonte depuis les deux planches exportees.
##
## ⚠ ON PREND LA VARIANTE 0. La feuille en porte peut-etre plusieurs ; en choisir une au
## hasard rendrait ce remontage non reproductible, donc inutilisable comme preuve.
static func from_sheets(heights: PackedStringArray, surface_sheet: Image, wall_sheet: Image,
		side: int, family: StringName = Families.BY_CELL) -> Image:
	var canvas: Image = _canvas(heights, side, family)
	var indices: Dictionary = _surfaces(heights, family)
	var roles: Dictionary = Walls.visible_roles(heights)
	var underfoot: Dictionary = _underfoot(heights)
	for cell: Vector2i in underfoot.keys():
		var slot: Vector2i = TilesetPNG.wall_slot(underfoot[cell])
		var from: Rect2i = Rect2i(slot * side, Vector2i(side, side))
		if from.end.x <= wall_sheet.get_width() and from.end.y <= wall_sheet.get_height():
			canvas.blend_rect(wall_sheet, from, _where(cell, side, family))
	for key: Vector2i in _order(heights, family):
		var sheet: Image = null
		var slot: Vector2i = Vector2i(-1, -1)
		if key.y >= 0 and roles.has(key):
			sheet = wall_sheet
			slot = TilesetPNG.wall_slot(roles[key])
		elif indices.has(key):
			sheet = surface_sheet
			slot = TilesetPNG.surface_slot(int(indices[key]), family)
		if sheet == null or slot.x < 0:
			continue
		var from: Rect2i = Rect2i(slot * side, Vector2i(side, side))
		if from.position.x < 0 or from.position.y < 0 \
				or from.end.x > sheet.get_width() or from.end.y > sheet.get_height():
			continue
		canvas.blend_rect(sheet, from, _where(key, side, family))
	return canvas


## Les surfaces de la famille, en cles de carnet.
static func _surfaces(heights: PackedStringArray, family: StringName) -> Dictionary:
	var by_key: Dictionary = {}
	var indices: Dictionary = Families.index_map(family, heights)
	for at: Vector2i in indices.keys():
		by_key[Families.storage_key(family, at)] = indices[at]
	return by_key


## L'APERCU EN JEU : ou aller chercher, dans le guide, la tuile que reclame chaque case
## d'un AUTRE relief.
##
## Le guide est un banc d'epreuve -- lacs d'une case, pinacles isoles, encoches partout. Il
## ne ressemblera jamais a une carte de jeu, donc il ne dira jamais si le tileset REND bien.
## Un petit relief ordinaire le dit. Il n'a besoin d'aucune tuile de plus : il pioche dans
## celles du guide, par index et par role.
##
## ⚠ ON PIOCHE TOUJOURS LA VARIANTE 0. Le decor doit etre le meme d'une seconde a l'autre ;
## tirer une variante au hasard le ferait scintiller a chaque coup de crayon.
##
## Rend : Dictionary[Vector2i, Vector2i], case du decor -> case du guide.
static func borrow(target: PackedStringArray, guide: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var source_of: Dictionary = {}
	var by_key: Dictionary = WorkIO.cells_by_key(guide, family)
	var indices: Dictionary = _surfaces(target, family)
	var roles: Dictionary = Walls.visible_roles(target)
	var letter: String = Families.key_letter(family)
	for at: Vector2i in _order(target, family):
		var key: String = ""
		if at.y >= 0 and roles.has(at):
			var role: Vector2i = roles[at]
			key = "W%d,%d:0" % [role.x, role.y]
		elif indices.has(at):
			key = "%s%d:0" % [letter, int(indices[at])]
		if by_key.has(key):
			source_of[at] = by_key[key]
	return source_of


## Le decor, peint avec les tuiles empruntees au guide. La version fichier de ce que le
## panneau dessine a l'ecran.
static func from_borrowed(target: PackedStringArray, guide: PackedStringArray,
		painting: Painting, family: StringName = Families.BY_CELL) -> Image:
	var side: int = painting.resolution
	var canvas: Image = _canvas(target, side, family)
	var source_of: Dictionary = borrow(target, guide, family)
	var by_key: Dictionary = WorkIO.cells_by_key(guide, family)
	_blend_buried(canvas, target, Walls.visible_roles(target), by_key, painting, side, family)
	var underfoot: Dictionary = _underfoot(target)
	for cell: Vector2i in underfoot.keys():
		var role: Vector2i = underfoot[cell]
		var key: String = "W%d,%d:0" % [role.x, role.y]
		if not by_key.has(key):
			continue
		var rock: Image = painting.image_of(by_key[key])
		if rock != null:
			canvas.blend_rect(rock, Rect2i(0, 0, side, side), _where(cell, side, family))
	for at: Vector2i in _order(target, family):
		if not source_of.has(at):
			continue
		var tile: Image = painting.image_of(source_of[at])
		if tile == null:
			continue
		canvas.blend_rect(tile, Rect2i(0, 0, side, side), _where(at, side, family))
	return canvas


## Les cases dans l'ordre ou elles se posent : les surfaces d'abord, les robes par-dessus.
##
## ⚠ LA ROBE PASSE DEVANT, comme partout ailleurs. Une case peut appartenir au sol d'un
## etage bas ET porter la face du plateau qui la surplombe ; vue de dessus, c'est la face
## qu'on voit. C'est la meme regle que la couverture -- on ne voit que le sommet.
static func _order(heights: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Array[Vector2i]:
	var indices: Dictionary = _surfaces(heights, family)
	var roles: Dictionary = Walls.visible_roles(heights)
	var cells: Array[Vector2i] = []
	for at: Vector2i in indices.keys():
		if at.y < 0 or not roles.has(at):
			cells.append(at)
	for cell: Vector2i in roles.keys():
		cells.append(cell)
	return cells


static func _canvas(heights: PackedStringArray, side: int,
		family: StringName = Families.BY_CELL) -> Image:
	var grow: int = 1 if family == Families.BY_CORNER else 0
	var columns: int = maxi(HeightMask.width(heights), 1) + grow
	var rows: int = maxi(HeightMask.height(heights), 1) + grow
	var canvas: Image = Image.create_empty(columns * side, rows * side, false, Image.FORMAT_RGBA8)
	canvas.fill(BACKDROP)
	return canvas
