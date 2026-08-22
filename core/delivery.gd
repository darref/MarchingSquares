# LA LIVRAISON : quelles cases du guide deviennent des tuiles.
#
# Regle fixee : quand plusieurs cases du guide portent le meme index, ce sont des
# OCCURRENCES de la meme tuile -- des jumelles. La tuile est livree des qu'une seule
# d'entre elles porte un pixel. Une case laissee vierge n'est simplement pas utilisee :
# rien n'est fabrique a sa place (charte, regle 3). Peindre est donc l'acte de selection,
# il n'y a rien a configurer (charte, regle 1).
#
# ⚠ UNE JUMELLE N'EST PAS UNE VARIANTE. Ce fichier s'appelait `variants.gd`, et le mot
# faisait deux metiers : les occurrences du guide, et les dessins distincts qu'on empilait
# jadis dans la planche. Le second a disparu ; ce qui reste, c'est la livraison.
#
# Le noyau ne connait pas les pixels. La couche de dessin repond a une seule question
# par case -- "porte-t-elle au moins un pixel peint ?" -- et transmet la liste des cases
# concernees. C'est toute l'interface.
extends RefCounted

const MaskIO := preload("res://core/mask_io.gd")
const Coverage := preload("res://core/coverage.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const HeightMask := preload("res://core/height_mask.gd")


## Resout la livraison d'un guide en fonction des cases peintes.
##
## Cles retournees :
##   retained      : Dictionary[int, Array[Vector2i]]  index -> cases peintes retenues
##   unused        : Array[Vector2i]                   cases du guide non peintes
##   outside       : Array[Vector2i]                   cases peintes hors du guide
##   delivered     : PackedInt32Array                  index ayant au moins une case peinte
##   missing       : PackedInt32Array                  index sans aucune case peinte
##   is_exportable : bool                              vrai si les 47 index sont livres
##
## Un guide complet ne suffit pas a exporter : c'est le dessin qui livre les index.
## Les cases sont parcourues en ordre de lecture, donc le resultat ne depend pas de
## l'ordre dans lequel les cases peintes sont fournies.
static func resolve(mask: PackedStringArray, painted_cells: Array[Vector2i]) -> Dictionary:
	var painted: Dictionary = {}
	for cell: Vector2i in painted_cells:
		painted[cell] = true

	var retained: Dictionary = {}
	var unused: Array[Vector2i] = []
	var in_guide: Dictionary = {}
	for y: int in range(MaskIO.height(mask)):
		for x: int in range(MaskIO.width(mask)):
			var index: int = Coverage.index_at(mask, x, y)
			if index == Coverage.NO_INDEX:
				continue
			var cell: Vector2i = Vector2i(x, y)
			in_guide[cell] = true
			if not painted.has(cell):
				unused.append(cell)
				continue
			if not retained.has(index):
				var new_cells: Array[Vector2i] = []
				retained[index] = new_cells
			var cells: Array[Vector2i] = retained[index]
			cells.append(cell)

	# Peindre hors du guide n'est pas cense arriver : le pinceau refuse ces cases
	# (charte, regle 5). On le signale plutot que de jeter le travail en silence.
	var outside: Array[Vector2i] = []
	for cell: Vector2i in painted.keys():
		if not in_guide.has(cell):
			outside.append(cell)
	outside.sort_custom(_reading_order)

	var delivered: PackedInt32Array = PackedInt32Array()
	var missing: PackedInt32Array = PackedInt32Array()
	for index: int in BlobIndex.CANONICAL_INDICES:
		if retained.has(index):
			delivered.append(index)
		else:
			missing.append(index)

	return {
		"retained": retained,
		"unused": unused,
		"outside": outside,
		"delivered": delivered,
		"missing": missing,
		"is_exportable": missing.is_empty(),
	}


static func _reading_order(left: Vector2i, right: Vector2i) -> bool:
	if left.y != right.y:
		return left.y < right.y
	return left.x < right.x


## Meme regle, sur un guide en relief : une case peinte est retenue pour l'index de sa
## surface VISIBLE. Le reste est identique -- une case vierge ne sert pas.
static func resolve_relief(heights: PackedStringArray, painted_cells: Array[Vector2i]) -> Dictionary:
	return resolve_indexed(Coverage.index_map(heights), painted_cells)


## Meme chose a partir d'une carte case -> index deja calculee.
##
## ⚠ C'EST PAR ICI QUE PASSE L'EDITEUR. Relire le relief entier a chaque coup de crayon
## coutait 4,4 ms par image ; en partant de la carte, le compte ne parcourt plus que les
## cases peintes.
## ⚠ LA LISTE ATTENDUE SE PASSE, ELLE NE SE DEVINE PAS. Elle etait codee en dur sur les 47
## du blob : en famille « a cheval » le compte aurait annonce quarante-sept manquants alors
## qu'il n'y en a que quinze a peindre. Le vocabulaire attendu appartient a l'appelant.
static func resolve_indexed(index_by_cell: Dictionary, painted_cells: Array[Vector2i],
		wanted: PackedInt32Array = BlobIndex.CANONICAL_INDICES) -> Dictionary:
	var painted: Dictionary = {}
	for cell: Vector2i in painted_cells:
		painted[cell] = true
	var retained: Dictionary = {}
	var unused: Array[Vector2i] = []
	var in_guide: Dictionary = index_by_cell
	# ⚠ ON NE TRIE PAS ICI. La carte est deja en ordre de lecture -- coverage.index_map()
	# la remplit ligne par ligne -- et un tri par Callable a chaque image coutait plus cher
	# que tout le reste du compte.
	for cell: Vector2i in index_by_cell.keys():
		var index: int = int(index_by_cell[cell])
		if not painted.has(cell):
			unused.append(cell)
			continue
		if not retained.has(index):
			var new_cells: Array[Vector2i] = []
			retained[index] = new_cells
		var cells: Array[Vector2i] = retained[index]
		cells.append(cell)
	var outside: Array[Vector2i] = []
	for cell: Vector2i in painted.keys():
		if not in_guide.has(cell):
			outside.append(cell)
	outside.sort_custom(_reading_order)
	var delivered: PackedInt32Array = PackedInt32Array()
	var missing: PackedInt32Array = PackedInt32Array()
	for index: int in wanted:
		if retained.has(index):
			delivered.append(index)
		else:
			missing.append(index)
	return {
		"retained": retained,
		"unused": unused,
		"outside": outside,
		"delivered": delivered,
		"missing": missing,
		"is_exportable": missing.is_empty(),
	}
