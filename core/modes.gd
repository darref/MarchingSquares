# Catalogue des modes.
#
# Un mode reunit un guide et des regles d'exportation. L'interface en fera une liste
# deroulante ; le noyau se contente de la table et n'a pas d'avis sur son affichage.
#
# UN SEUL MODE : EPAIS. Decision utilisateur du 24/08/2026, prise apres une session de
# peinture reelle sur l'ancien mode 47 : les tuiles a matiere minoritaire -- pointes,
# isthmes, ilots, trous d'une case -- concentraient tous les problemes d'expression.
# Le mode epais interdit tout relief d'une tuile d'epaisseur (core/thickness.gd) ; son
# vocabulaire est CALCULE de cette interdiction : 27 index de surface (theoreme des 256
# fenetres), 25 roles de robe (redan compris), 15 croisements. Les anciens modes minimal et ample ne
# sont pas fermes : ils sont RETIRES -- leurs guides restent au depot comme temoins.
#
# La disposition de la feuille exportee ne figure pas ici : elle se deduit du vocabulaire
# (exporters/tileset_png.gd), une fois, plutot que recopiee dans chaque entree.
extends RefCounted

const Thickness := preload("res://core/thickness.gd")
const Massifs := preload("res://core/massifs.gd")
const Brush := preload("res://core/brush_vocabulary.gd")

const EPAIS: StringName = &"epais"
## LE MODELE DES MASSIFS. ⚠ SON GUIDE EST BATI PAR LE GESTE, ENTIEREMENT : chacun de ses
## mondes sort d'une suite de tampons, donc la marche EST la preuve qu'il est atteignable.
## Il ne montre a l'artiste que ce que le pinceau saura faire.
const MASSIFS: StringName = &"massifs"

## L'ancien nom du mode par defaut, garde comme alias le temps que tout le monde parle
## epais. Il pointe le MEME mode : il n'y en a qu'un.
const MINIMAL: StringName = EPAIS

static var MODES: Dictionary = {}


static func _static_init() -> void:
	# Les comptes sont CALCULES du vocabulaire epais, jamais ecrits en dur -- meme raison
	# que CANONICAL_INDICES : une liste ecrite a la main est un endroit ou mentir.
	MODES = {
		EPAIS: {
			"label": "Epais",
			"guide_path": "res://guides/epais.txt",
			"surface_tiles": Thickness.SURFACE_INDICES.size(),
			"wall_tiles": Thickness.wall_roles().size(),
			"min_occurrences": 1,
			# ⚠ FERME : c'est le paysage de l'ancien modele, et son vocabulaire n'existe
			# plus. Il reste dans la table parce que les outils et la suite s'en servent
			# encore comme TEMOIN -- le demontage de l'ancien noyau viendra apres le portage
			# du remontage, de l'apercu et de la planche de preuve.
			"closed": true,
		},
		MASSIFS: {
			"label": "Massifs",
			"guide_path": "res://guides/massifs.txt",
			"surface_tiles": _massif_count(Massifs.SURFACE, true),
			"wall_tiles": _massif_count(Massifs.SURFACE, false),
			"min_occurrences": 1,
		},
	}


## Les tuiles du modele des massifs, par bande -- les surfaces d'un cote, les jupes de
## l'autre. ⚠ ELLES SONT DANS UN SEUL VOCABULAIRE ET SUR UNE SEULE PLANCHE : la coupure
## n'existe que pour les deux jauges de l'editeur, qui disent ou en est le travail.
static func _massif_count(band: int, equal: bool) -> int:
	var many: int = 0
	for tile: int in Brush.tiles():
		if (Massifs.band_of(tile) == band) == equal:
			many += 1
	return many


## Identifiants des modes, dans l'ordre de la liste deroulante.
static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in MODES.keys():
		result.append(id)
	return result


## Vrai si le mode appartient a un modele retire : il ne figure plus dans la liste.
static func is_closed(id: StringName) -> bool:
	return MODES.has(id) and bool(MODES[id].get("closed", false))


static func has(id: StringName) -> bool:
	return MODES.has(id)


## Vrai si le guide du mode existe reellement.
## ⚠ UN MODE SANS GUIDE NE SE CHOISIT PAS (charte, regle 5).
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
static func min_occurrences(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["min_occurrences"]


## Nombre de tuiles de surface du mode -- les 27 index epais, calcules.
static func surface_tile_count(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["surface_tiles"]


## Nombre de tuiles de mur du mode -- les 25 roles epais, calcules.
static func wall_tile_count(id: StringName) -> int:
	if not MODES.has(id):
		push_error("modes: mode inconnu '%s'." % id)
		return 0
	return MODES[id]["wall_tiles"]


## Tout ce que le mode doit livrer, les deux familles reunies.
static func tile_count(id: StringName) -> int:
	return surface_tile_count(id) + wall_tile_count(id)
