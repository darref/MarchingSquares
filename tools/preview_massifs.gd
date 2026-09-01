extends SceneTree

## LE GUIDE PEINT SOUS LE NOUVEAU MODELE -- le seul rendu qui dise si on va au bon endroit.
##
##     godot --headless --path . --script res://tools/preview_massifs.gd -- <sortie.png> [zoom] [x y w h]
##
## Variables : `GUIDE=` le relief a peindre, `F=` la liberte (0 1 2), `GRILLE=1` la grille.
##
## ⚠ ET IL NE CALCULE RIEN LUI-MEME. Il appelle `render/massif_scene.gd`, celui que le banc
## mesure : une image qu'on regarde et une image qu'on mesure doivent sortir du meme code, sinon
## l'oeil approuve ce que la mesure n'a pas vu.

const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Scene := preload("res://render/massif_scene.gd")

const RES: int = Scene.RES
const VOID: Color = Color(0.09, 0.09, 0.10)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	var zoom: int = args[1].to_int() if args.size() > 1 else 1
	var guide: String = OS.get_environment("GUIDE")
	if guide.is_empty():
		guide = Modes.guide_path(Modes.EPAIS)
	var freedom: int = 1
	if not OS.get_environment("F").is_empty():
		freedom = OS.get_environment("F").to_int()
	var world: PackedStringArray = HeightMask.read(guide)
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	# ⚠ LE FOND N'EST PEINT QUE POUR L'OEIL. Le composeur laisse le vide transparent -- c'est ce
	# qui rend la mesure possible -- mais un PNG a fond transparent se regarde mal.
	var image: Image = Image.create_empty(wide * RES, tall * RES, false, Image.FORMAT_RGBA8)
	image.fill(VOID)
	image.blend_rect(Scene.compose(world, freedom),
			Rect2i(0, 0, wide * RES, tall * RES), Vector2i.ZERO)

	if OS.get_environment("GRILLE") != "":
		var grid: Color = Color(1.0, 0.35, 0.35, 0.55)
		for gy: int in range(tall + 1):
			for gx: int in range(wide * RES):
				image.set_pixel(gx, mini(gy * RES, tall * RES - 1), grid)
		for gx2: int in range(wide + 1):
			for gy2: int in range(tall * RES):
				image.set_pixel(mini(gx2 * RES, wide * RES - 1), gy2, grid)
	if args.size() >= 6:
		var crop: Image = Image.create_empty(args[4].to_int() * RES, args[5].to_int() * RES,
				false, image.get_format())
		crop.blit_rect(image, Rect2i(args[2].to_int() * RES, args[3].to_int() * RES,
				args[4].to_int() * RES, args[5].to_int() * RES), Vector2i.ZERO)
		image = crop
	if zoom > 1:
		image.resize(image.get_width() * zoom, image.get_height() * zoom,
				Image.INTERPOLATE_NEAREST)
	image.save_png(out)
	print("guide %dx%d a F%d, ecrit : %s (%dx%d)"
			% [wide, tall, freedom, out, image.get_width(), image.get_height()])
	quit(0)
