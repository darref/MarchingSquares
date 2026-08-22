# Catalogue des modes.
#
# Un mode reunit un guide et des regles d'exportation. L'interface en fera une liste
# deroulante ; le noyau se contente de la table et n'a pas d'avis sur son affichage.
#
# Un mode, c'est un PAYSAGE : le relief du guide et ce qu'il faut en tirer. Ni la
# technique du fond ni son style n'entrent ici -- ce sont des outils, pas des modes.
# Chacun livre DEUX familles de tuiles : le blob 47
# pour la surface des plateaux, et les 12 tuiles de robe pour les falaises. Un terrain Wang
# resout les coins d'un plan ; une falaise sort du plan, et son vocabulaire est autre.
# C'est le choix de ce qu'on fabrique, fait une fois avant de dessiner, pas un reglage a
# ajuster en cours de route (charte, regle 1).
#
# La disposition de la feuille exportee ne figure pas ici : elle est la MEME pour tous
# les modes, puisque tous livrent les memes 59 tuiles. Elle vit donc dans
# `exporters/tileset_png.gd`, une fois, plutot que recopiee dans chaque entree.
extends RefCounted

const MINIMAL: StringName = &"minimal"
const AMPLE: StringName = &"ample"

const MODES: Dictionary = {
	MINIMAL: {
		"label": "Minimal",
		"guide_path": "res://guides/minimal.txt",
		"surface_tiles": 47,
		"wall_tiles": 36,
		"min_occurrences": 1,
	},
	# Meme completude que `minimal`, mais volontairement plus de repetitions : chaque tuile
	# se voit dans plusieurs contextes, ce qui rend le geste plus sur. La promesse est
	# chiffree par `min_occurrences` et prouvee par la suite de tests.
	AMPLE: {
		"label": "Ample",
		"guide_path": "res://guides/ample.txt",
		"surface_tiles": 47,
		"wall_tiles": 36,
		# ⚠ TROIS, ET C'EST UNE BARRE TROIS FOIS PLUS HAUTE QUE CELLE DE `minimal`. Elle
		# porte sur les TROIS vocabulaires -- 47 index de surface, 15 croisements, 36 roles
		# de robe -- et elle est prouvee par la suite, pas promise.
		"min_occurrences": 3,
	},
}


## Identifiants des modes, dans l'ordre de la liste deroulante.
static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in MODES.keys():
		result.append(id)
	return result


static func has(id: StringName) -> bool:
	return MODES.has(id)


## Vrai si le guide du mode existe reellement.
## ⚠ UN MODE SANS GUIDE NE SE CHOISIT PAS (charte, regle 5). Il figure au catalogue parce
## qu'il est decide et nomme, mais il reste ferme tant qu'on ne peut rien prouver dessus.
static func is_available(id: StringName) -> bool:
	if not MODES.has(id) or bool(MODES[id].get("closed", false)):
		return false
	return FileAccess.file_exists(guide_path(id))


## Libelle affichable du mode.
static func label(id: StringName) -> String:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return ""
	return MODES[id]["label"]


## Chemin du guide du mode.
static func guide_path(id: StringName) -> String:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return ""
	return MODES[id]["guide_path"]


## Nombre minimal d'OCCURRENCES que chaque tuile doit avoir dans le guide du mode.
##
## ⚠ C'EST LA PROMESSE DU MODE, ET ELLE EST PROUVEE. `ample` ne dit pas « plus redondant »
## en esperant que ce soit vrai : il annonce 3, et la suite de tests le verifie.
##
## ⚠ CE NE SONT PAS DES VARIANTES. Une occurrence est un ENDROIT de plus ou la meme tuile
## se voit ; toutes portent le meme dessin. Ce qu'elles apportent, c'est que peindre une
## tuile en remplit des dizaines sous les yeux -- pas que la planche grossisse.
static func min_occurrences(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["min_occurrences"]


## Nombre de tuiles de surface -- le blob 47.
static func surface_tile_count(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["surface_tiles"]


## Nombre de tuiles de mur -- trois pans par quatre rangees.
static func wall_tile_count(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["wall_tiles"]


## Tout ce que le mode doit livrer, les deux familles reunies.
static func tile_count(id: StringName) -> int:
	return surface_tile_count(id) + wall_tile_count(id)
