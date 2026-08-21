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
		"min_variants": 1,
	},
	# Meme completude que `minimal`, mais volontairement plus de repetitions : chaque tuile
	# se voit dans plusieurs contextes, ce qui rend le geste plus sur. La promesse est
	# chiffree par `min_variants` et prouvee par la suite de tests.
	AMPLE: {
		"label": "Ample",
		"guide_path": "res://guides/ample.txt",
		# ⚠ FERME. Son guide ne couvre que 25 des 36 roles de mur depuis que le vocabulaire
		# distingue les faces en retrait, et il promet TROIS occurrences de chacun -- une
		# barre bien plus haute que `minimal`. Ce qui n'est pas garanti ne se choisit pas
		# (regle 5) : il reste au catalogue, grise, jusqu'a ce que son guide soit refait.
		"closed": true,
		"surface_tiles": 47,
		"wall_tiles": 36,
		"min_variants": 3,
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


## Nombre minimal d'occurrences que chaque tuile doit avoir dans le guide du mode.
## ⚠ C'EST LA PROMESSE DU MODE, ET ELLE EST PROUVEE. `ample` ne dit pas « plus redondant »
## en esperant que ce soit vrai : il annonce 3, et la suite de tests le verifie.
static func min_variants(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["min_variants"]


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
