# Rapport de couverture d'un masque de guide : quels index blob le masque produit,
# lesquels manquent encore, et combien de fois chacun apparait.
# Charte, regle 4 : l'exactitude se prouve. Ce fichier est la preuve.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const MaskIO := preload("res://core/mask_io.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")

## Index retourne pour une case vide : une case vide ne produit aucune tuile.
const NO_INDEX: int = -1


static func raw_neighbourhood(mask: PackedStringArray, x: int, y: int) -> int:
	var raw: int = 0
	for bit_index: int in range(BlobIndex.BITS.size()):
		var offset: Vector2i = BlobIndex.OFFSETS[bit_index]
		if MaskIO.is_filled(mask, x + offset.x, y + offset.y):
			raw |= BlobIndex.BITS[bit_index]
	return raw


## Index canonique de la case (x, y), ou NO_INDEX si la case est vide.
static func index_at(mask: PackedStringArray, x: int, y: int) -> int:
	if not MaskIO.is_filled(mask, x, y):
		return NO_INDEX
	return BlobIndex.canonicalize(raw_neighbourhood(mask, x, y))


## Rapport de couverture d'un masque.
## Cles retournees :
##   filled_count : int                      nombre de cases pleines
##   present      : PackedInt32Array         index couverts, tries
##   missing      : PackedInt32Array         index encore absents, tries
##   occurrences  : Dictionary[int, int]     index -> nombre de cases
##   positions    : Dictionary[int, Array]   index -> Array[Vector2i] des cases
##   is_complete  : bool                     vrai si les 27 index EPAIS sont couverts
## Les occurrences multiples ne sont pas des doublons : ce sont les jumelles d'une tuile.
static func analyse(mask: PackedStringArray) -> Dictionary:
	var occurrences: Dictionary = {}
	var positions: Dictionary = {}
	var filled_count: int = 0
	for y: int in range(MaskIO.height(mask)):
		for x: int in range(MaskIO.width(mask)):
			var index: int = index_at(mask, x, y)
			if index == NO_INDEX:
				continue
			filled_count += 1
			occurrences[index] = int(occurrences.get(index, 0)) + 1
			if not positions.has(index):
				var new_cells: Array[Vector2i] = []
				positions[index] = new_cells
			var cells: Array[Vector2i] = positions[index]
			cells.append(Vector2i(x, y))
	var present: PackedInt32Array = PackedInt32Array()
	var missing: PackedInt32Array = PackedInt32Array()
	for index: int in Thickness.SURFACE_INDICES:
		if occurrences.has(index):
			present.append(index)
		else:
			missing.append(index)
	return {
		"filled_count": filled_count,
		"present": present,
		"missing": missing,
		"occurrences": occurrences,
		"positions": positions,
		"is_complete": missing.is_empty(),
	}


## Index de la SURFACE VISIBLE d'une case d'un guide en relief, ou NO_INDEX si la case
## est a la plaine.
##
## ⚠ UNE CASE SOUS UN PLATEAU PLUS HAUT EST MASQUEE, DONC NON PEIGNABLE. Vu de dessus, on
## ne voit que le sommet : la tuile qu'une case porte est celle de son PROPRE etage, lue
## dans la silhouette de cet etage. Compter l'union de tous les etages gonflerait la
## couverture avec des tuiles que personne ne pourra jamais peindre.
## ⚠ LA PLAINE EN FAIT PARTIE. L'etage 0 est un plateau comme les autres : il a sa
## silhouette -- tout ce qui n'est pas le vide -- ses 47 index, et ses falaises au bord du
## monde. Seul le VIDE ne porte rien.
static func visible_index_at(heights: PackedStringArray, x: int, y: int) -> int:
	var level: int = HeightMask.level_at(heights, x, y)
	if level < 0:
		return NO_INDEX
	return index_at_level(heights, x, y, level)


## Index d'une case dans la silhouette d'un etage donne, sans se demander si cet etage est
## celui qu'on voit. C'est ce dont le rendu a besoin : il dessine etage par etage, du bas
## vers le haut, et chaque couche recouvre la precedente.
static func index_at_level(heights: PackedStringArray, x: int, y: int, level: int) -> int:
	if HeightMask.level_at(heights, x, y) < level:
		return NO_INDEX
	var raw: int = 0
	for bit_index: int in range(BlobIndex.BITS.size()):
		var offset: Vector2i = BlobIndex.OFFSETS[bit_index]
		if HeightMask.level_at(heights, x + offset.x, y + offset.y) >= level:
			raw |= BlobIndex.BITS[bit_index]
	return BlobIndex.canonicalize(raw)


## Rapport de couverture de surface d'un guide en relief.
## Memes cles que analyse(), les positions portant l'etage : Array[Vector3i].
static func analyse_relief(heights: PackedStringArray) -> Dictionary:
	var occurrences: Dictionary = {}
	var positions: Dictionary = {}
	var surface_count: int = 0
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			var index: int = visible_index_at(heights, x, y)
			if index == NO_INDEX:
				continue
			surface_count += 1
			occurrences[index] = int(occurrences.get(index, 0)) + 1
			if not positions.has(index):
				var new_cells: Array[Vector3i] = []
				positions[index] = new_cells
			var cells: Array[Vector3i] = positions[index]
			cells.append(Vector3i(x, y, HeightMask.level_at(heights, x, y)))
	var present: PackedInt32Array = PackedInt32Array()
	var missing: PackedInt32Array = PackedInt32Array()
	for index: int in Thickness.SURFACE_INDICES:
		if occurrences.has(index):
			present.append(index)
		else:
			missing.append(index)
	return {
		"filled_count": surface_count,
		"present": present,
		"missing": missing,
		"occurrences": occurrences,
		"positions": positions,
		"is_complete": missing.is_empty(),
	}


## La carte des index de surface visible, case par case.
##
## ⚠ ELLE SE CALCULE UNE FOIS. Relire tout le relief a chaque coup de crayon coutait 4,4 ms
## par image sur le guide minimal -- un tiers du budget d'affichage pour recompter ce qui
## n'a pas bouge. L'editeur la garde et repasse par delivery.resolve_indexed().
static func index_map(heights: PackedStringArray) -> Dictionary:
	var indices: Dictionary = {}
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			var index: int = visible_index_at(heights, x, y)
			if index != NO_INDEX:
				indices[Vector2i(x, y)] = index
	return indices


## Les cases regroupees par index de surface.
##
## Deux cases du meme groupe portent LA MEME TUILE : ce sont les jumelles l'une de
## l'autre. C'est ce qui permet de proposer de les peindre ensemble.
static func cells_by_index(index_by_cell: Dictionary) -> Dictionary:
	var groups: Dictionary = {}
	for cell: Vector2i in index_by_cell.keys():
		var index: int = int(index_by_cell[cell])
		if not groups.has(index):
			var fresh: Array[Vector2i] = []
			groups[index] = fresh
		var cells: Array[Vector2i] = groups[index]
		cells.append(cell)
	return groups

