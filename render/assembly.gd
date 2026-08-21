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

## Le fond sur lequel le paysage se pose. Le meme que la zone de travail, pour qu'un trou
## se lise pareil a l'ecran et dans un fichier.
const BACKDROP: Color = Color(0.106, 0.114, 0.125)


## Le paysage remonte avec ce qui est peint, case par case.
static func from_painting(heights: PackedStringArray, painting: Painting) -> Image:
	var side: int = painting.resolution
	var canvas: Image = _canvas(heights, side)
	for cell: Vector2i in _order(heights):
		var tile: Image = painting.image_of(cell)
		if tile == null:
			continue
		canvas.blend_rect(tile, Rect2i(0, 0, side, side), cell * side)
	return canvas


## Le paysage remonte depuis les deux planches exportees.
##
## ⚠ ON PREND LA VARIANTE 0. La feuille en porte peut-etre plusieurs ; en choisir une au
## hasard rendrait ce remontage non reproductible, donc inutilisable comme preuve.
static func from_sheets(heights: PackedStringArray, surface_sheet: Image, wall_sheet: Image,
		side: int) -> Image:
	var canvas: Image = _canvas(heights, side)
	var indices: Dictionary = Coverage.index_map(heights)
	var roles: Dictionary = Walls.visible_roles(heights)
	for cell: Vector2i in _order(heights):
		var sheet: Image = null
		var slot: Vector2i = Vector2i(-1, -1)
		if roles.has(cell):
			sheet = wall_sheet
			slot = TilesetPNG.wall_slot(roles[cell], 0)
		elif indices.has(cell):
			sheet = surface_sheet
			slot = TilesetPNG.surface_slot(int(indices[cell]), 0)
		if sheet == null or slot.x < 0:
			continue
		var from: Rect2i = Rect2i(slot * side, Vector2i(side, side))
		if from.position.x < 0 or from.position.y < 0 \
				or from.end.x > sheet.get_width() or from.end.y > sheet.get_height():
			continue
		canvas.blend_rect(sheet, from, cell * side)
	return canvas


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
static func borrow(target: PackedStringArray, guide: PackedStringArray) -> Dictionary:
	var source_of: Dictionary = {}
	var by_key: Dictionary = WorkIO.cells_by_key(guide)
	var indices: Dictionary = Coverage.index_map(target)
	var roles: Dictionary = Walls.visible_roles(target)
	for cell: Vector2i in _order(target):
		var key: String = ""
		if roles.has(cell):
			var role: Vector2i = roles[cell]
			key = "W%d,%d:0" % [role.x, role.y]
		elif indices.has(cell):
			key = "S%d:0" % int(indices[cell])
		if by_key.has(key):
			source_of[cell] = by_key[key]
	return source_of


## Le decor, peint avec les tuiles empruntees au guide. La version fichier de ce que le
## panneau dessine a l'ecran.
static func from_borrowed(target: PackedStringArray, guide: PackedStringArray,
		painting: Painting) -> Image:
	var side: int = painting.resolution
	var canvas: Image = _canvas(target, side)
	var source_of: Dictionary = borrow(target, guide)
	for cell: Vector2i in _order(target):
		if not source_of.has(cell):
			continue
		var tile: Image = painting.image_of(source_of[cell])
		if tile == null:
			continue
		canvas.blend_rect(tile, Rect2i(0, 0, side, side), cell * side)
	return canvas


## Les cases dans l'ordre ou elles se posent : les surfaces d'abord, les robes par-dessus.
##
## ⚠ LA ROBE PASSE DEVANT, comme partout ailleurs. Une case peut appartenir au sol d'un
## etage bas ET porter la face du plateau qui la surplombe ; vue de dessus, c'est la face
## qu'on voit. C'est la meme regle que la couverture -- on ne voit que le sommet.
static func _order(heights: PackedStringArray) -> Array[Vector2i]:
	var indices: Dictionary = Coverage.index_map(heights)
	var roles: Dictionary = Walls.visible_roles(heights)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in indices.keys():
		if not roles.has(cell):
			cells.append(cell)
	for cell: Vector2i in roles.keys():
		cells.append(cell)
	return cells


static func _canvas(heights: PackedStringArray, side: int) -> Image:
	var columns: int = maxi(HeightMask.width(heights), 1)
	var rows: int = maxi(HeightMask.height(heights), 1)
	var canvas: Image = Image.create_empty(columns * side, rows * side, false, Image.FORMAT_RGBA8)
	canvas.fill(BACKDROP)
	return canvas
