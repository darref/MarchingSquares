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
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Massifs := preload("res://core/massifs.gd")
const Brush := preload("res://core/brush_vocabulary.gd")

const BY_CELL: StringName = &"cell"
const BY_CORNER: StringName = &"corner"
## LE MODELE DES MASSIFS : une seule famille, un seul vocabulaire.
##
## ⚠ ICI LA FALAISE N'EST PLUS UN SECOND VOCABULAIRE. Un massif se dessine ENTIER -- sa
## surface et sa jupe -- et une tuile est le couple (silhouette, bande). Il n'y a donc ni
## carte de surface a nettoyer de ses robes, ni roles a compter a part : une case porte une
## pose, et c'est tout. Les deux jauges de l'editeur se lisent alors sur les BANDES d'un
## meme vocabulaire, pas sur deux familles qui s'ignorent.
const BY_MASSIF: StringName = &"massif"

const FAMILIES: Dictionary = {
	# ⚠ « PAR CASE » ET « A CHEVAL » SONT RETIREES DU PRODUIT (decision utilisateur). Elles
	# etaient les deux reseaux de l'ancien modele, ou une tuile de surface ignorait sa jupe ;
	# le modele des massifs n'a qu'un vocabulaire, et offrir un choix qui n'en est plus un
	# ferait chercher a l'acheteur une decision qu'il n'a pas a prendre (charte, regle 1).
	# Leurs constantes survivent le temps que l'ancien noyau soit demonte -- elles ne sont
	# plus proposees nulle part.
	BY_MASSIF: {
		"label": "Massifs",
		"note": "un massif entier, surface et jupe",
	},
}


## LE VOCABULAIRE DU MODELE DES MASSIFS : celui que le GESTE atteint, pas la forme close.
## ⚠ LA FORME CLOSE RESTE LA BORNE HAUTE (core/massif_form.gd) ; elle garde l'invariant, elle
## n'est plus la cible. Le peintre peint de la surface ; le reste suit.
static func massif_tiles() -> Array[int]:
	return Brush.tiles()


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
##
## ⚠ LE MODE EPAIS EST LE PRODUIT : par case, la famille livre les 27 index qui survivent
## a l'interdit des reliefs d'une tuile d'epaisseur (core/thickness.gd), pas les 47 de la
## mathematique. Les 47 restent le theoreme (BlobIndex) ; les 27 sont le vocabulaire.
static func surface_indices(family: StringName) -> PackedInt32Array:
	if family == BY_MASSIF:
		var out: PackedInt32Array = PackedInt32Array()
		for tile: int in massif_tiles():
			if Massifs.band_of(tile) == Massifs.SURFACE:
				out.append(tile)
		return out
	if family == BY_CORNER:
		return CornerIndex.all_indices()
	return Thickness.SURFACE_INDICES


static func surface_tile_count(family: StringName) -> int:
	return surface_indices(family).size()


## Les roles de robe que le mode livre -- les 23 epais, pour les deux familles.
## ⚠ C'EST ICI QUE LA BARRE VIT, une seule fois : Walls garde sa mathematique des 36 et
## recoit la liste voulue en parametre (un preload Walls -> Thickness ferait un cycle).
static func wall_roles(family: StringName = BY_CELL) -> Array[Vector2i]:
	return [] as Array[Vector2i] if family == BY_MASSIF else Thickness.wall_roles()


## LES TUILES DE JUPE du modele des massifs : tout ce qui n'est pas une surface.
## ⚠ ET ELLES SONT DANS LE MEME VOCABULAIRE que les surfaces, donc dans le meme carnet et
## sur la meme planche. C'est ce qui distingue ce modele de l'ancien, ou une falaise avait
## sa feuille a part parce qu'elle « sortait du plan ».
static func massif_skirts() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for tile: int in massif_tiles():
		if Massifs.band_of(tile) != Massifs.SURFACE:
			out.append(tile)
	return out


## Ce qu'on peint -> l'index qu'il porte.
##
## ⚠ LA CLE N'EST PAS DANS LE MEME ESPACE SELON LA FAMILLE. Par case, c'est une case du
## relief ; a cheval, c'est un CROISEMENT, et il y en a (W+1) x (H+1). Les deux sont des
## `Vector2i` mais ne designent pas la meme chose -- raison pour laquelle la peinture des
## deux familles ne partage jamais le meme carnet.
static func index_map(family: StringName, heights: PackedStringArray) -> Dictionary:
	if family == BY_MASSIF:
		return Massifs.visible(heights)
	if family == BY_CORNER:
		return CornerIndex.index_map(heights)
	return Coverage.index_map(heights)


## Le rapport de couverture de la famille sur ce relief.
static func analyse(family: StringName, heights: PackedStringArray) -> Dictionary:
	if family == BY_MASSIF:
		return _massif_report(heights)
	if family == BY_CORNER:
		return CornerIndex.analyse_relief(heights)
	return Coverage.analyse_relief(heights)


## CE QU'UNE CASE PORTE EN SURFACE, une fois les robes passees devant.
##
## ⚠ UNE CASE SOUS UNE FACE DE FALAISE PORTE LA ROBE, PAS LE SOL D'EN BAS. Sur la carte, une
## case de robe est une case du sol d'en dessous, et `index_map` lui donne donc un index de
## surface -- celui d'un sol que la face recouvre entierement, et que personne ne verra ni
## ne peindra jamais a cet endroit. La laisser dans les groupes de surface faisait ecrire
## la peinture de l'index 255 dans 130 cases de robe du guide minimal : apres UNE surface
## peinte, les 36 roles de robe se disaient livres, et l'export aurait pris de l'herbe pour
## de la roche. C'est la regle que `WorkIO.slots` appliquait deja en silence -- la cle `W`
## ecrasait la cle `S` -- et qui vit desormais ici, une seule fois.
##
## ⚠ MESURE AVANT D'ECRIRE : ca ne coute aucune tuile. Sur les deux guides livres,
## l'occurrence la plus rare reste a 1 (`minimal`) et 3 (`ample`).
##
## A cheval, les cles sont dans un autre espace et ne rencontrent aucune robe : la carte
## est rendue telle quelle.
static func surface_map(family: StringName, heights: PackedStringArray) -> Dictionary:
	var indices: Dictionary = index_map(family, heights)
	# ⚠ RIEN A NETTOYER : une case porte UNE pose, jupe comprise. L'ancien modele devait
	# retirer de la carte de surface les cases qu'une robe recouvre -- sur la carte, une case
	# de robe est une case du sol d'en dessous -- et c'est cet ecart entre « ce que la case
	# est » et « ce qu'elle montre » qui a fait declarer les 36 roles livres apres UNE
	# surface peinte. Ici la question ne se pose pas.
	if family == BY_MASSIF:
		return indices
	if family == BY_CORNER:
		return indices
	var covered: Dictionary = Walls.visible_roles(heights)
	for cell: Vector2i in covered.keys():
		indices.erase(cell)
	return indices


## CE QUI PREND LE CRAYON : les cles de `surface_map` dont l'etage visible est au moins 1.
##
## ⚠ L'ETAGE 0 EST DU DECOR. La plaine reste dans les groupes de jumelles -- peindre une
## tuile la remplit sous les yeux -- mais elle ne se peint pas. C'est la meme table que
## lit l'editeur pour tracer sa grille et refuser le crayon, et que lit la suite pour
## verifier qu'un mode trouve tout son vocabulaire hors de la plaine : un seul endroit.
static func paintable_map(family: StringName, heights: PackedStringArray) -> Dictionary:
	if family == BY_MASSIF:
		return Massifs.paintable(heights)
	var kept: Dictionary = {}
	var carried: Dictionary = surface_map(family, heights)
	for at: Vector2i in carried.keys():
		if visible_level(family, heights, at) >= 1:
			kept[at] = carried[at]
	return kept


## L'etage que montre ce qu'on peint ici : celui de la case, ou le plus haut des quatre
## cases d'un croisement. ⚠ ON NE VOIT QUE LE SOMMET, ici comme partout.
static func visible_level(family: StringName, heights: PackedStringArray, at: Vector2i) -> int:
	if family != BY_CORNER:
		return HeightMask.level_at(heights, at.x, at.y)
	var top: int = HeightMask.VOID
	for offset: Vector2i in CornerIndex.OFFSETS:
		top = maxi(top, HeightMask.level_at(heights, at.x + offset.x, at.y + offset.y))
	return top


## Les jumelles : ce qui porte le meme index porte la meme tuile.
static func groups(family: StringName, index_by_key: Dictionary) -> Dictionary:
	if family == BY_MASSIF:
		return Massifs.cells_by_key(index_by_key)
	if family == BY_CORNER:
		return CornerIndex.points_by_index(index_by_key)
	return Coverage.cells_by_index(index_by_key)


## Un index ecrit par ses bits, dans le vocabulaire de sa famille.
static func describe(family: StringName, index: int) -> String:
	if family == BY_MASSIF:
		return Massifs.describe(index)
	if family == BY_CORNER:
		return CornerIndex.describe(index)
	# ⚠ UNE TUILE PAR CASE EST UN COUPLE : la silhouette, et ce qu'il y a au-dela de ses
	# bords vides. Le nom doit dire les deux, sinon deux tuiles differentes portent le meme.
	var edge: String = BlobIndex.brink_name(index)
	return BlobIndex.describe(BlobIndex.silhouette(index)) + ("" if edge == "" else "  [%s]" % edge)


## ⚠ UNE FAMILLE NE SE CHOISIT QUE SI LE GUIDE LA COUVRE (charte, regle 5). Un guide complet
## en blob 47 n'est PAS automatiquement complet a cheval : la canonicalisation du blob jette
## le contact diagonal isole, dont le reseau dual a besoin.
static func is_covered(family: StringName, heights: PackedStringArray) -> bool:
	return bool(analyse(family, heights)["is_complete"])


## OU SE RANGE, DANS LE CARNET DE PEINTURE, CE QU'ON PEINT A CET ENDROIT.
##
## ⚠ LES DEUX FAMILLES PARTAGENT UN SEUL CARNET ET NE S'Y RENCONTRENT JAMAIS. Un
## croisement (i, j) se range a la cle (i, -1 - j) : les cases occupent les y positifs ou
## nuls, les croisements les y strictement negatifs. Sur le guide livre, 520 coordonnees
## sont communes aux deux familles -- sans cette separation, la tuile du croisement (3,4) et
## la robe de la case (3,4) se marcheraient dessus.
##
## ⚠ ET UN SEUL CARNET, PAS DEUX, PARCE QUE TOUT LE RESTE EN DEPEND : un seul historique
## d'annulation -- `Ctrl+Z` n'a pas a deviner de quel carnet il parle --, une seule taille de
## faux pixel, un seul fichier. Deux carnets rendraient l'un ou l'autre faux.
static func storage_key(family: StringName, at: Vector2i) -> Vector2i:
	return Vector2i(at.x, -1 - at.y) if family == BY_CORNER else at


## Le chemin inverse : de la cle du carnet vers ce qu'on peint.
static func from_storage(family: StringName, key: Vector2i) -> Vector2i:
	return Vector2i(key.x, -1 - key.y) if family == BY_CORNER else key


## La lettre qui nomme la famille dans les cles de sauvegarde et d'export.
## `S` pour la surface par case, `C` pour le croisement.
static func key_letter(family: StringName) -> String:
	if family == BY_MASSIF:
		return "M"
	return "C" if family == BY_CORNER else "S"


## LE RAPPORT DU MODELE DES MASSIFS, dans la forme que l'interface lit deja.
static func _massif_report(heights: PackedStringArray) -> Dictionary:
	var wanted: Array[int] = massif_tiles()
	var got: Dictionary = Massifs.analyse(heights, wanted)
	var groups_by: Dictionary = got["groups"]
	var present: Array[int] = []
	var occurrences: Dictionary = {}
	var positions: Dictionary = {}
	var filled: int = 0
	for tile: int in wanted:
		if not groups_by.has(tile):
			continue
		var cells: Array[Vector2i] = groups_by[tile]
		present.append(tile)
		occurrences[tile] = cells.size()
		positions[tile] = cells
		filled += cells.size()
	return {
		"filled_count": filled,
		"present": present,
		"missing": got["missing"],
		"occurrences": occurrences,
		"positions": positions,
		"is_complete": bool(got["is_complete"]),
	}
