# LES DEUX FAMILLES DE SURFACE — et le seul endroit où elles sont interchangeables.
#
# Un tileset de surface peut se poser de deux façons, et ce sont deux vocabulaires, pas deux
# réglages :
#
#   PAR CASE   -- le blob 47. La tuile occupe une case, et son dessin depend des 8 voisins
#                 de cette case.
#   A CHEVAL   -- le reseau dual. La tuile occupe le CROISEMENT de quatre cases, et son
#                 dessin ne depend que de ces quatre-la. Quinze tuiles, pas seize : le
#                 croisement entierement vide ne dessine rien.
#
# ⚠ LES ROBES NE CHANGENT PAS. Une falaise sort du plan ; elle se pose case pour case, quel
# que soit le reseau du sol. Les 36 roles valent pour les deux familles.
#
# ⚠ ET LA FAMILLE N'EST PAS LE PAYSAGE. Le meme guide sert les deux : ce sont deux axes
# independants, comme la taille des faux pixels. On choisit une fois, avant de dessiner --
# c'est ce qu'on fabrique, pas un reglage a ajuster en route (charte, regle 1).
#
# ⚠ CE FICHIER EXISTE POUR QU'IL N'Y AIT QU'UN SEUL ENDROIT OU LES DEUX SE RESSEMBLENT.
# Sans lui, chaque compteur, chaque exportateur et chaque test se dedoublerait -- et deux
# copies d'une meme regle finissent toujours par se contredire.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Coverage := preload("res://core/coverage.gd")
const HeightMask := preload("res://core/height_mask.gd")

const BY_CELL: StringName = &"cell"
const BY_CORNER: StringName = &"corner"

const FAMILIES: Dictionary = {
	BY_CELL: {
		"label": "Par case",
		"note": "47 tuiles de surface",
	},
	BY_CORNER: {
		"label": "A cheval",
		"note": "15 tuiles de surface",
	},
}


static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in FAMILIES.keys():
		result.append(id)
	return result


static func has(family: StringName) -> bool:
	return FAMILIES.has(family)


static func label(family: StringName) -> String:
	return String(FAMILIES[family]["label"]) if FAMILIES.has(family) else ""


static func note(family: StringName) -> String:
	return String(FAMILIES[family]["note"]) if FAMILIES.has(family) else ""


## Les index de surface que la famille livre.
static func surface_indices(family: StringName) -> PackedInt32Array:
	if family == BY_CORNER:
		return CornerIndex.all_indices()
	return BlobIndex.CANONICAL_INDICES


static func surface_tile_count(family: StringName) -> int:
	return surface_indices(family).size()


## Ce qu'on peint -> l'index qu'il porte.
##
## ⚠ LA CLE N'EST PAS DANS LE MEME ESPACE SELON LA FAMILLE. Par case, c'est une case du
## relief ; a cheval, c'est un CROISEMENT, et il y en a (W+1) x (H+1). Les deux sont des
## `Vector2i` mais ne designent pas la meme chose -- raison pour laquelle la peinture des
## deux familles ne partage jamais le meme carnet.
static func index_map(family: StringName, heights: PackedStringArray) -> Dictionary:
	if family == BY_CORNER:
		return CornerIndex.index_map(heights)
	return Coverage.index_map(heights)


## Le rapport de couverture de la famille sur ce relief.
static func analyse(family: StringName, heights: PackedStringArray) -> Dictionary:
	if family == BY_CORNER:
		return CornerIndex.analyse_relief(heights)
	return Coverage.analyse_relief(heights)


## Les jumelles : ce qui porte le meme index porte la meme tuile.
static func groups(family: StringName, index_by_key: Dictionary) -> Dictionary:
	if family == BY_CORNER:
		return CornerIndex.points_by_index(index_by_key)
	return Coverage.cells_by_index(index_by_key)


## Un index ecrit par ses bits, dans le vocabulaire de sa famille.
static func describe(family: StringName, index: int) -> String:
	if family == BY_CORNER:
		return CornerIndex.describe(index)
	return BlobIndex.describe(index)


## ⚠ UNE FAMILLE NE SE CHOISIT QUE SI LE GUIDE LA COUVRE (charte, regle 5). Un guide complet
## en blob 47 n'est PAS automatiquement complet a cheval : la canonicalisation du blob jette
## le contact diagonal isole, dont le reseau dual a besoin.
static func is_covered(family: StringName, heights: PackedStringArray) -> bool:
	return bool(analyse(family, heights)["is_complete"])


## La lettre qui nomme la famille dans les cles de sauvegarde et d'export.
## `S` pour la surface par case, `C` pour le croisement.
static func key_letter(family: StringName) -> String:
	return "C" if family == BY_CORNER else "S"
