# L'ESSAI — le guide lui-meme, livre comme tileset.
#
# Le logiciel prouve que les tuiles sont completes ; le plugin s'en sert. Entre les deux il
# manquait de quoi ESSAYER : tant qu'aucun pixel n'est peint, l'export refuse -- a juste
# titre -- et le game dev n'a rien a poser. Il devait donc croire sur parole.
#
# Or nous avons deja un dessin complet de chaque tuile : l'illustration du guide. Elle est
# CALCULEE depuis le relief, elle ne lit aucune image, et elle couvre par construction tout
# ce que le guide couvre. On la verse donc dans un carnet de peinture comme si elle avait
# ete peinte a la main, et on la fait sortir par LE CHEMIN NORMAL.
#
# ⚠ ET C'EST TOUT L'INTERET : PAS DE CHEMIN DE TRAVERSE. `TilesetPNG.write` ne sait pas
# qu'il exporte un essai. Le manifeste est le vrai, les planches sont les vraies, le refus
# d'une feuille incomplete s'applique. Si l'essai sort, c'est que la chaine entiere marche
# -- et s'il ne sort pas, c'est qu'elle est cassee pour tout le monde.
#
# ⚠ ELLE EST ENTIEREMENT A NOUS. Aucun pixel emprunte, aucune licence a lire : c'est notre
# propre trace, celui-la meme qu'on efface en peignant par-dessus. Le banc `example`, lui,
# lit le tileset de Satyron et ne peut RIEN livrer.
#
# ⚠ CE N'EST PAS DE L'ART, ET IL NE FAUT PAS FAIRE SEMBLANT. C'est un dessin de
# specification : des aplats, des arrondis, une striure. Il sert a poser un monde qui se
# tient et a juger l'outil, pas a habiller un jeu. L'artiste peint par-dessus, et c'est
# precisement le geste que le logiciel existe pour guider.
#
#     godot --headless --path . --script res://exporters/trial_tileset.gd -- dossier [taille]
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const Modes := preload("res://core/modes.gd")
const Families := preload("res://core/families.gd")
const GuideImage := preload("res://render/guide_image.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")

## L'etage dont on prend la teinte pour TOUTES les surfaces.
##
## ⚠ UN TILESET N'A QU'UN JEU DE 47, ET C'EST LE POINT. L'illustration teinte chaque etage
## differemment pour qu'on lise l'altitude d'un coup d'oeil ; une feuille exportee, elle,
## sert a tous les etages a la fois. On en fige donc un seul -- et le monde pose par le
## plugin montrera ses plateaux dans la meme herbe, exactement comme un vrai tileset.
const TRIAL_LEVEL: int = 1

## La taille de tuile de l'essai. Assez grande pour que les arrondis se voient, assez
## petite pour que la feuille reste legere.
const TRIAL_RESOLUTION: int = 32

const TRIAL_BASENAME: String = "absolutiles_essai"


## Le carnet de peinture rempli de notre propre dessin, tuile par tuile.
##
## ⚠ UNE OCCURRENCE PAR TUILE SUFFIT, et c'est deja asserte ailleurs : l'export ne retient
## que la premiere peinte. Remplir les mille jumelles ne changerait pas d'un pixel ce qui
## sort, et couterait mille images.
static func paint(heights: PackedStringArray, resolution: int = TRIAL_RESOLUTION,
		family: StringName = Families.BY_CELL) -> Painting:
	var painting: Painting = Painting.new(resolution)
	var drawn: Dictionary = {}
	for cell: Vector2i in WorkIO.slots(heights, family).keys():
		var key: String = String(WorkIO.slots(heights, family)[cell])
		var slot: Dictionary = WorkIO.describe(key)
		var tile: String = key.substr(0, key.rfind(":"))
		if drawn.has(tile):
			continue
		var image: Image = _draw(slot, resolution)
		if image == null:
			continue
		drawn[tile] = true
		painting.set_image(cell, image)
	return painting


## Le dessin d'une tuile, pris a l'illustration.
##
## ⚠ SANS LES MARQUES. Le trait grossi, les marqueurs de coin rentrant et les tirets de
## rangee existent pour rendre la SPECIFICATION lisible en peignant ; dans une feuille
## livree ce ne sont plus des reperes, ce sont des taches.
static func _draw(slot: Dictionary, resolution: int) -> Image:
	if slot["family"] == "S":
		return GuideImage.make_top(int(slot["index"]), TRIAL_LEVEL, resolution,
				GuideImage.Ink.PAINTED, false)
	if slot["family"] == "W":
		return GuideImage.make_wall(slot["role"], resolution, GuideImage.Ink.PAINTED, false)
	# ⚠ LA FAMILLE A CHEVAL N'A PAS ENCORE DE DESSIN. L'illustration calcule les 47 index du
	# blob, pas les 15 croisements : elle dessine le relief, et le relief se lit par case.
	# On ne fabrique pas un dessin qu'on n'a pas -- l'essai reste donc par case (regle 5).
	return null


## Ecrit l'essai complet : les deux planches, la preuve et le manifeste.
static func write(folder: String, mode_id: StringName = Modes.MINIMAL,
		resolution: int = TRIAL_RESOLUTION) -> Dictionary:
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(mode_id))
	var painting: Painting = paint(heights, resolution, Families.BY_CELL)
	return TilesetPNG.write(folder, TRIAL_BASENAME, painting, heights, mode_id,
			Families.BY_CELL)


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var folder: String = arguments[0] if arguments.size() > 0 else "user://essai"
	var resolution: int = arguments[1].to_int() if arguments.size() > 1 else TRIAL_RESOLUTION
	if not Painting.RESOLUTIONS.has(resolution):
		resolution = TRIAL_RESOLUTION
	var report: Dictionary = write(folder, Modes.MINIMAL, resolution)
	if int(report["error"]) != OK:
		push_error("essai : l export a refuse (erreur %d)." % int(report["error"]))
		quit(1)
		return
	print("L'essai est ecrit, en %d pixels par tuile :" % resolution)
	for path: String in report["written"]:
		print("  %s" % ProjectSettings.globalize_path(path))
	quit(0)
