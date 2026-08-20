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

const MODES: Dictionary = {
	MINIMAL: {
		"label": "Minimal",
		"guide_path": "res://guides/minimal.txt",
		"surface_tiles": 47,
		"wall_tiles": 12,
	},
	# ⚠ DECIDE, NOMME, PAS ENCORE DESSINE. Meme completude que `minimal`, mais volontairement
	# plus de repetitions : peindre une tuile en remplit plusieurs, ce qui rend le geste plus
	# intuitif. Il reste ferme tant que son guide n'existe pas (charte, regle 5).
	AMPLE: {
		"label": "Ample",
		"guide_path": "res://guides/ample.txt",
		"surface_tiles": 47,
		"wall_tiles": 12,
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
