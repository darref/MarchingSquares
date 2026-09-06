# LA CARTE DES CASES D'HERBE VISIBLE FINE — ou la grammaire se resserre.
#
# ⚠ ON MONTRE L'ENDROIT, PAS LE NOMBRE. « 147 cases d'herbe visible fine » n'oriente aucune
# decision : ce qu'il faut voir, c'est OU elles sont et a quoi elles ressemblent -- une bande
# d'herbe de deux cases entre deux falaises se juge a l'oeil, pas au compteur.
#
# La carte pose un cadre rouge sur chaque case fautive, par-dessus le dessin calcule. Elle sert a
# arbitrer une regle de modele, donc elle ne cache rien : le compte, les zones, et l'image.
#
#     godot --headless --path . --script res://tools/thin_map.gd -- <sortie.png> [guide]
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Gesture := preload("res://core/gesture.gd")
const Scene := preload("res://render/massif_scene.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")

const RES: int = MassifTiles.RES
const MARK: Color = Color(1.0, 0.25, 0.2)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var target: String = args[0] if args.size() > 0 else "thin.png"
	var path: String = args[1] if args.size() > 1 else "res://guides/massifs.txt"
	var world: PackedStringArray = HeightMask.read(path)
	if world.is_empty():
		printerr("carte : '%s' ne se lit pas." % path)
		quit(1)
		return

	var poses: Array[Dictionary] = Massifs.poses(world)
	var thin: Array[Vector2i] = Gesture.thin_cells_visible(world, poses)
	print("%s : %d case(s) d'herbe visible fine" % [path, thin.size()])

	# ⚠ ET ON DIT LES ZONES, PAS SEULEMENT LES CASES. Cent quarante-sept points epars et cent
	# quarante-sept points groupes en trois endroits ne demandent pas le meme arbitrage.
	var bands: Dictionary = {}
	for at: Vector2i in thin:
		var band: int = at.y / 20
		bands[band] = int(bands.get(band, 0)) + 1
	var rows: Array[int] = []
	for band2: Variant in bands.keys():
		rows.append(int(band2))
	rows.sort()
	for band3: int in rows:
		print("    rangees %3d-%3d : %d case(s)" % [band3 * 20, band3 * 20 + 19,
				int(bands[band3])])

	var image: Image = Scene.compose(world, 1)
	for at2: Vector2i in thin:
		_frame(image, at2)
	# ⚠ ET ON PEUT RECADRER, PARCE QU'UNE CARTE DE 2432x4448 NE SE REGARDE PAS. « Montrer
	# l'endroit » suppose qu'on puisse en approcher un : `x y w h` en CASES, comme l'apercu.
	if args.size() >= 6:
		var box: Rect2i = Rect2i(args[2].to_int() * RES, args[3].to_int() * RES,
				args[4].to_int() * RES, args[5].to_int() * RES)
		image = image.get_region(box)
		var zoom: int = args[6].to_int() if args.size() > 6 else 1
		if zoom > 1:
			image.resize(image.get_width() * zoom, image.get_height() * zoom,
					Image.INTERPOLATE_NEAREST)
	if image.save_png(target) != OK:
		printerr("carte : impossible d'ecrire %s" % target)
		quit(1)
		return
	print("carte ecrite : %s (%dx%d)" % [target, image.get_width(), image.get_height()])
	quit(0)


## Un cadre rouge autour d'une case, pose PAR-DESSUS le dessin : on marque, on ne remplace pas.
static func _frame(image: Image, cell: Vector2i) -> void:
	var left: int = cell.x * RES
	var top: int = cell.y * RES
	for step: int in range(RES):
		for edge: int in [0, RES - 1]:
			_dot(image, left + step, top + edge)
			_dot(image, left + edge, top + step)


static func _dot(image: Image, x: int, y: int) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, MARK)
