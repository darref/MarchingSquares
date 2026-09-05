# LES EXEMPLES LIVRES — des tilesets peints a la main, montres comme fond de guide.
#
# ⚠ UN EXEMPLE N'EST PAS UN STYLE, C'EST UNE PREUVE. « Notre dessin » est la SPECIFICATION :
# calculee depuis le relief, elle ne peut pas mentir sur ce que le guide contient, et elle a donc
# toujours l'air juste. Un exemple, lui, est du VRAI trait remonte en paysage -- c'est la seule
# vue ou l'on voit ce que l'outil rend vraiment, et c'est la qu'on trouve les defauts. Le
# cisaillement du massif 21 a ete releve comme ca, et par aucun autre moyen.
#
# ⚠ ET IL EST LIVRE AVEC LE LOGICIEL, PAS LU CHEZ QUELQU'UN D'AUTRE. Le banc « Satyron » lit un
# pack achete la ou il se trouve : sa licence autorise l'usage et interdit la redistribution,
# donc il reste ferme sur une machine qui ne l'a pas (charte, regle 5). Ceux-ci sont a nous --
# notre propre trace, redistribuable -- donc ils s'ouvrent partout.
#
# ⚠ ET UN EXEMPLE QUI N'EXISTE PAS SE MONTRE QUAND MEME, GRISE. Une place vide dit « ceci
# viendra » ; une absence ne dit rien du tout, et l'acheteur ne cherche pas ce qu'il ne voit pas.
extends RefCounted

const WorkIO := preload("res://core/work_io.gd")

## Basse resolution : le premier tileset peint a la main, 16 px par tuile.
const LOW: StringName = &"low_res"
## Haute resolution : sa place est prise, il viendra.
const HIGH: StringName = &"high_res"

const CATALOGUE: Dictionary = {
	LOW: {
		"label": "Exemple Low Res",
		"path": "res://examples/low_res.solutiles",
		"note": "16 px par tuile",
	},
	HIGH: {
		"label": "Exemple High Res",
		"path": "res://examples/high_res.solutiles",
		"note": "a venir",
	},
}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in CATALOGUE.keys():
		out.append(id)
	return out


static func label(id: StringName) -> String:
	return String((CATALOGUE[id] as Dictionary)["label"]) if CATALOGUE.has(id) else ""


static func note(id: StringName) -> String:
	return String((CATALOGUE[id] as Dictionary)["note"]) if CATALOGUE.has(id) else ""


static func path(id: StringName) -> String:
	return String((CATALOGUE[id] as Dictionary)["path"]) if CATALOGUE.has(id) else ""


## ⚠ ON REGARDE LE FICHIER, PAS UNE LISTE ECRITE. Un catalogue qui affirmerait la presence d'un
## exemple absent ouvrirait un choix qui ne montre rien -- le pire des refus, celui qui se tait.
static func is_available(id: StringName) -> bool:
	return CATALOGUE.has(id) and FileAccess.file_exists(path(id))


## LE CARNET D'UN EXEMPLE, relu contre le relief courant.
##
## ⚠ IL SE RELIT CONTRE LE GUIDE DU JOUR, ET C'EST TOUT L'INTERET. Le carnet range par TUILE :
## un exemple peint sur un guide d'hier retombe sur ses pieds sur celui d'aujourd'hui, et ce qui
## ne retombe pas est DIT, jamais jete. C'est la meme mecanique que l'ouverture d'un travail.
static func painting(id: StringName, heights: PackedStringArray) -> RefCounted:
	if not is_available(id):
		return null
	var loaded: Dictionary = WorkIO.read(path(id), heights)
	if int(loaded["error"]) != OK:
		return null
	return loaded["painting"]
