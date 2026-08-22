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
	for key: Vector2i in _order(heights, family):
		var tile: Image = painting.image_of(key)
		if tile == null:
			continue
		canvas.blend_rect(tile, Rect2i(0, 0, side, side), _where(key, side, family))
	return canvas


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
	for key: Vector2i in _order(heights, family):
		var sheet: Image = null
		var slot: Vector2i = Vector2i(-1, -1)
		if key.y >= 0 and roles.has(key):
			sheet = wall_sheet
			slot = TilesetPNG.wall_slot(roles[key], 0)
		elif indices.has(key):
			sheet = surface_sheet
			slot = TilesetPNG.surface_slot(int(indices[key]), 0, family)
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
	for at: Vector2i in Families.index_map(family, heights).keys():
		by_key[Families.storage_key(family, at)] = Families.index_map(family, heights)[at]
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
