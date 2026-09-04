extends SceneTree

## LA MEME TUILE, DANS SES TROIS SITUATIONS — cote a cote, pour qu'on JUGE au lieu de deduire.

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifScene := preload("res://render/massif_scene.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")
const BlobIndex := preload("res://core/blob_index.gd")

const CARDS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
const WAYS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const RES: int = MassifTiles.RES
const MARGIN: int = 3


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var wanted: int = arguments[0].to_int()
	var target: String = arguments[1]

	var world: PackedStringArray = HeightMask.read("res://guides/massifs.txt")
	var top: Dictionary = {}
	for pose: Dictionary in Massifs.poses(world):
		var at: Vector2i = pose["cell"]
		if top.has(at) and int((top[at] as Dictionary)["level"]) > int(pose["level"]):
			continue
		top[at] = pose

	# Un exemplaire de chaque situation de la tuile demandee.
	var found: Dictionary = {}
	for cell: Vector2i in top.keys():
		var one: Dictionary = top[cell]
		if Massifs.key_of(one) != wanted:
			continue
		var sil: int = int(one["sil"])
		var word: String = ""
		for k: int in range(4):
			if (sil & CARDS[k]) != 0:
				word += "-"
				continue
			var near: Vector2i = cell + WAYS[k]
			if not top.has(near):
				word += "0"
			elif int((top[near] as Dictionary)["band"]) == Massifs.SURFACE:
				word += "1"
			else:
				word += "2"
		if not found.has(word):
			found[word] = cell
	if found.is_empty():
		printerr("aucune occurrence de %s" % Massifs.describe(wanted))
		quit(1)
		return

	var image: Image = MassifScene.compose(world, 1, MassifTiles.PEINT)
	var side: int = (1 + 2 * MARGIN) * RES
	var words: Array = found.keys()
	words.sort()
	var sheet: Image = Image.create_empty(side * words.size() + 8 * (words.size() - 1),
			side, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.19, 0.20, 0.21, 1.0))
	for k2: int in range(words.size()):
		var cell2: Vector2i = found[words[k2]]
		var from: Vector2i = (cell2 - Vector2i(MARGIN, MARGIN)) * RES
		var box: Rect2i = Rect2i(from, Vector2i(side, side))
		sheet.blend_rect(image, box, Vector2i(k2 * (side + 8), 0))
		print("  %s  -> case %s" % [_say(String(words[k2])), cell2])
	sheet.save_png(target)
	print("%s : %d situations, ecrit %s" % [Massifs.describe(wanted), words.size(), target])
	quit()


func _say(word: String) -> String:
	var sides: Array[String] = ["N", "E", "S", "O"]
	var names: Array[String] = ["vide", "herbe", "roche"]
	var out: PackedStringArray = PackedStringArray()
	for k: int in range(4):
		var mark: String = word.substr(k, 1)
		if mark != "-":
			out.append("%s=%s" % [sides[k], names[mark.to_int()]])
	return " ".join(out)
