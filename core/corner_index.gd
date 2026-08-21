# LE RESEAU DUAL — la grille a cheval, ou une tuile couvre quatre cases.
#
# Beaucoup de tilesets du marche sont « a cheval » : la tuile n'est pas posee SUR une case,
# elle est posee sur le CROISEMENT de quatre cases, et son dessin ne depend que de ces
# quatre-la. C'est le systeme de Satyron (`mode = 1`, Match Corners). Quatre cases, deux
# etats chacune : seize combinaisons, contre quarante-sept pour le blob.
#
# ⚠ LE CROISEMENT VIDE N'EST PAS UNE TUILE. Le code 0 -- les quatre cases a la plaine -- ne
# dessine rien, exactement comme la plaine n'est pas une tuile du blob (charte, regle 5 :
# ce qui n'est pas garanti est interdit, et ici il n'y a rien a garantir). Le reseau dual
# livre donc **quinze** tuiles a peindre, pas seize. Avec les douze robes : vingt-sept
# tuiles pour un tileset complet, contre cinquante-neuf.
#
# ⚠ LES DEUX SYSTEMES NE SE RECOUVRENT PAS. La canonicalisation du blob JETTE le contact
# diagonal isole -- « un coin diagonal isole ne change pas la silhouette de la tuile ». Le
# reseau dual, lui, a une tuile pour ca : deux quadrants opposes pleins, les deux autres
# vides. C'est le point exact ou les deux vocabulaires divergent, et c'est pour ca qu'un
# guide complet en blob 47 n'est PAS automatiquement complet en dual.
#
# Repere : un croisement (i, j) touche les cases (i-1, j-1), (i, j-1), (i-1, j) et (i, j).
# Une grille de W x H cases porte donc (W+1) x (H+1) croisements.
extends RefCounted

const MaskIO := preload("res://core/mask_io.gd")
const HeightMask := preload("res://core/height_mask.gd")

## Bits dans le sens horaire depuis le nord-ouest, comme le blob part du nord.
const NW: int = 1
const NE: int = 2
const SE: int = 4
const SW: int = 8

const BITS: Array[int] = [NW, NE, SE, SW]
const BIT_NAMES: Array[String] = ["NO", "NE", "SE", "SO"]

## Decalages (dx, dy) de la case portee par chaque bit, depuis le croisement.
const OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(0, 0),
	Vector2i(-1, 0),
]

const NO_INDEX: int = -1

## Les quinze tuiles. Le code 0 en est absent : il ne dessine rien.
const TILE_COUNT: int = 15


## Les quinze index, dans l'ordre croissant.
static func all_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()
	for code: int in range(1, 16):
		indices.append(code)
	return indices


## L'index du croisement [param i], [param j] dans un masque binaire.
static func index_at(mask: PackedStringArray, i: int, j: int) -> int:
	var code: int = 0
	for bit: int in range(BITS.size()):
		var at: Vector2i = OFFSETS[bit]
		if MaskIO.is_filled(mask, i + at.x, j + at.y):
			code |= BITS[bit]
	return code if code != 0 else NO_INDEX


## L'index VISIBLE d'un croisement dans un relief.
##
## ⚠ ON NE VOIT QUE LE SOMMET, comme partout ailleurs. Un croisement touche quatre cases qui
## peuvent etre a quatre etages differents ; la tuile qu'on voit est celle de l'etage le
## plus haut des quatre, puisque sa couche recouvre les autres. Compter aussi les etages du
## dessous gonflerait le rapport de tuiles que personne ne pourra jamais peindre : elles
## sont cachees, donc on ne peut ni les viser ni les juger.
static func visible_index_at(heights: PackedStringArray, i: int, j: int) -> int:
	var top: int = 0
	for bit: int in range(BITS.size()):
		var at: Vector2i = OFFSETS[bit]
		top = maxi(top, HeightMask.level_at(heights, i + at.x, j + at.y))
	if top == 0:
		return NO_INDEX
	return index_at(HeightMask.silhouette(heights, top), i, j)


## Croisement -> index visible, pour tout le relief.
static func index_map(heights: PackedStringArray) -> Dictionary:
	var indices: Dictionary = {}
	for j: int in range(HeightMask.height(heights) + 1):
		for i: int in range(HeightMask.width(heights) + 1):
			var index: int = visible_index_at(heights, i, j)
			if index != NO_INDEX:
				indices[Vector2i(i, j)] = index
	return indices


## Rapport de couverture du reseau dual.
##
## Cles rendues : present, missing, occurrences, positions, filled_count, is_complete.
static func analyse_relief(heights: PackedStringArray) -> Dictionary:
	var indices: Dictionary = index_map(heights)
	var occurrences: Dictionary = {}
	var positions: Dictionary = {}
	for point: Vector2i in indices.keys():
		var index: int = int(indices[point])
		occurrences[index] = int(occurrences.get(index, 0)) + 1
		if not positions.has(index):
			var fresh: Array[Vector2i] = []
			positions[index] = fresh
		var where: Array[Vector2i] = positions[index]
		where.append(point)

	var present: PackedInt32Array = PackedInt32Array()
	var missing: PackedInt32Array = PackedInt32Array()
	for index: int in all_indices():
		if occurrences.has(index):
			present.append(index)
		else:
			missing.append(index)

	return {
		"present": present,
		"missing": missing,
		"occurrences": occurrences,
		"positions": positions,
		"filled_count": indices.size(),
		"is_complete": missing.is_empty(),
	}


## Les croisements regroupes par index : les jumelles du reseau dual.
static func points_by_index(index_by_point: Dictionary) -> Dictionary:
	var groups: Dictionary = {}
	for point: Vector2i in index_by_point.keys():
		var index: int = int(index_by_point[point])
		if not groups.has(index):
			var fresh: Array[Vector2i] = []
			groups[index] = fresh
		var points: Array[Vector2i] = groups[index]
		points.append(point)
	return groups


## Un index ecrit par ses quadrants : « 9 = NO+SO ».
static func describe(index: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for bit: int in range(BITS.size()):
		if (index & BITS[bit]) != 0:
			parts.append(BIT_NAMES[bit])
	return "rien" if parts.is_empty() else "+".join(parts)
