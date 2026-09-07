# L'ESSAI DU MODELE DES MASSIFS — notre propre trace, livre comme tileset.
#
# Le logiciel prouve que les tuiles sont completes ; le plugin s'en sert. Entre les deux il
# manque de quoi ESSAYER : tant qu'aucun pixel n'est peint, l'export refuse -- a juste titre --
# et le game dev n'a rien a poser. Il devrait croire sur parole.
#
# Or nous avons deja un dessin complet de chaque tuile : celui du fond de guide. Il est CALCULE
# depuis la silhouette et la bande, il ne lit aucune image, et il couvre par construction tout
# le vocabulaire. On le verse donc dans un carnet de peinture comme s'il avait ete peint a la
# main, et on le fait sortir par LE CHEMIN NORMAL.
#
# ⚠ ET C'EST TOUT L'INTERET : PAS DE CHEMIN DE TRAVERSE. `MassifTileset.write` ne sait pas
# qu'il exporte un essai. Le manifeste est le vrai, la planche est la vraie, le refus d'une
# feuille incomplete s'applique. Si l'essai sort, c'est que la chaine entiere marche -- et s'il
# ne sort pas, c'est qu'elle est cassee pour tout le monde.
#
# ⚠ IL EST ENTIEREMENT A NOUS. Aucun pixel emprunte, aucune licence a lire : c'est notre propre
# trace, celui-la meme qu'on efface en peignant par-dessus.
#
# ⚠ CE N'EST PAS DE L'ART, ET IL NE FAUT PAS FAIRE SEMBLANT. C'est un dessin de SPECIFICATION :
# des aplats, des arrondis, un contour. Il sert a poser un monde qui se tient et a juger
# l'outil, pas a habiller un jeu.
#
#     godot --headless --path . --script res://exporters/massif_trial.gd -- dossier
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const Modes := preload("res://core/modes.gd")
const Families := preload("res://core/families.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")

## ⚠ LA TAILLE EST CELLE DU DESSIN, PAS UN REGLAGE. `MassifTiles.shape` rend une image de
## `RES` pixels de cote ; demander une autre taille reviendrait a redimensionner un dessin de
## specification, donc a livrer autre chose que ce que le fond montre.
const TRIAL_RESOLUTION: int = MassifTiles.RES

## L'etage dont on prend la teinte. ⚠ UN TILESET N'A QU'UN JEU DE TUILES : le fond du guide
## n'en teinte deja plus qu'un, mais on le fige ici aussi, pour que rien ne depende du relief.
const TRIAL_LEVEL: int = 1

const TRIAL_BASENAME: String = "solutiles_essai"


## LE CARNET DE PEINTURE, rempli de notre propre dessin, tuile par tuile.
##
## ⚠ UNE OCCURRENCE PAR TUILE SUFFIT, et c'est deja asserte ailleurs : l'export ne retient que
## la premiere peinte. Remplir les jumelles ne changerait pas d'un pixel ce qui sort.
static func paint(heights: PackedStringArray,
		resolution: int = TRIAL_RESOLUTION) -> Painting:
	var painting: Painting = Painting.new(resolution)
	var drawn: Dictionary = {}
	var slots: Dictionary = WorkIO.slots(heights, Families.BY_MASSIF)
	for cell: Vector2i in slots.keys():
		var key: String = String(slots[cell])
		var slot: Dictionary = WorkIO.describe(key)
		if String(slot["family"]) != "M":
			continue
		var tile: int = int(slot["index"])
		if drawn.has(tile):
			continue
		drawn[tile] = true
		painting.set_image(cell, draw(tile, resolution))
	return painting


## Le dessin d'une tuile, pris au fond du guide.
##
## ⚠ EN APLATS, PAS EN CONTOUR. Le contour prouve sert a JUGER le trace en peignant ; livre
## comme tileset il donnerait un monde en fil de fer. C'est le dessin peint qui part.
static func draw(tile: int, resolution: int = TRIAL_RESOLUTION) -> Image:
	var image: Image = MassifTiles.shape(Massifs.sil_of(tile),
			Massifs.band_of(tile), Massifs.flush_of(tile), 1,
			Color(0, 0, 0, 0), TRIAL_LEVEL, MassifTiles.PEINT, Massifs.cut_of(tile))
	if resolution != image.get_width():
		image.resize(resolution, resolution, Image.INTERPOLATE_NEAREST)
	return image


## Ecrit l'essai complet : la planche et le manifeste.
static func write(folder: String, mode_id: StringName = Modes.MASSIFS,
		resolution: int = TRIAL_RESOLUTION) -> Dictionary:
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(mode_id))
	var painting: Painting = paint(heights, resolution)
	return MassifTileset.write(painting, heights, mode_id, folder, TRIAL_BASENAME)


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var folder: String = arguments[0] if arguments.size() > 0 else "user://essai_massifs"
	var report: Dictionary = write(folder)
	if String(report["error"]) != "":
		push_error("essai : l export a refuse (%s)." % String(report["error"]))
		quit(1)
		return
	print("Trial written, at %d pixels per tile:" % TRIAL_RESOLUTION)
	for path: String in report["written"]:
		print("  %s" % ProjectSettings.globalize_path(path))
	quit(0)
