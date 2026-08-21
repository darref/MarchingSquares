# Catalogue des modes.
#
# Un mode reunit un guide et des regles d'exportation. L'interface en fera une liste
# deroulante ; le noyau se contente de la table et n'a pas d'avis sur son affichage.
#
# Un seul mode pour l'instant : "minimal". Il livre DEUX familles de tuiles : le blob 47
# pour la surface des plateaux, et les 12 tuiles de robe pour les falaises. Un terrain Wang
# resout les coins d'un plan ; une falaise sort du plan, et son vocabulaire est autre.
# C'est le choix de ce qu'on fabrique, fait une fois avant de dessiner, pas un reglage a
# ajuster en cours de route (charte, regle 1).
#
# Les regles d'exportation ne figurent pas encore ici : exporters/ est vide, et les
# inventer maintenant reviendrait a decider a la place de l'usage. Elles rejoindront
# l'entree du mode quand le premier exporteur existera.
extends RefCounted

const MINIMAL: StringName = &"minimal"
const AMPLE: StringName = &"ample"
const UNLIT: StringName = &"unlit"

const MODES: Dictionary = {
	MINIMAL: {
		"label": "Minimal",
		"guide_path": "res://guides/minimal.txt",
		"surface_tiles": 47,
		"wall_tiles": 12,
		"min_variants": 1,
	},
	# Meme completude que `minimal`, mais volontairement plus de repetitions : chaque tuile
	# se voit dans plusieurs contextes, ce qui rend le geste plus sur. La promesse est
	# chiffree par `min_variants` et prouvee par la suite de tests.
	AMPLE: {
		"label": "Ample",
		"guide_path": "res://guides/ample.txt",
		"surface_tiles": 47,
		"wall_tiles": 12,
		"min_variants": 3,
	},
	# ⚠ SANS LUMIERE, DONC LES SYMETRIES Y SONT LICITES. Meme guide et meme vocabulaire que
	# `minimal` -- ce n'est pas le paysage qui change, c'est ce qu'on fabrique : des tuiles
	# sans direction d'eclairage. Rien n'y contredit une rotation, alors l'outil remplit les
	# orbites, et il ne reste que 22 tuiles a peindre au lieu de 59.
	UNLIT: {
		"label": "Sans lumiere",
		"guide_path": "res://guides/minimal.txt",
		"surface_tiles": 47,
		"wall_tiles": 12,
		"min_variants": 1,
		"lit": false,
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
	return MODES.has(id) and FileAccess.file_exists(guide_path(id))


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


## Vrai si le tileset du mode a une direction d'eclairage.
##
## ⚠ C'EST CE QUI AUTORISE OU INTERDIT LES SYMETRIES. Un tileset eclaire ne se tourne pas :
## la lumiere tournerait avec lui. Sans lumiere, rien dans le dessin ne s'y oppose, et
## l'outil peut remplir les orbites -- decide UNE FOIS avec le mode, jamais en cours de
## dessin.
static func is_lit(id: StringName) -> bool:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return true
	return bool(MODES[id].get("lit", true))


## Nombre de tuiles que l'utilisateur devra reellement peindre. ⚠ A NE PAS CONFONDRE AVEC
## LA TAILLE DU VOCABULAIRE : le guide couvre toujours 47 index et 12 roles ; c'est la
## QUANTITE DE TRAVAIL qui tombe quand les symetries sont licites.
static func work_count(id: StringName) -> int:
	if not MODES.has(id):
		return 0
	if is_lit(id):
		return surface_tile_count(id) + wall_tile_count(id)
	var symmetry: GDScript = load("res://core/symmetry.gd")
	return symmetry.surface_work_count() + symmetry.wall_work_count()


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
