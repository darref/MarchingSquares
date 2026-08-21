# Ecrit l'illustration du guide sur disque.
#
#   godot --headless --path . --script res://render/preview.gd -- [guide] [sortie] [style]
#
# Par defaut : le guide du mode minimal, vers guides/minimal_preview.png, style
# representative. Le troisieme argument accepte « usable ».
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Modes := preload("res://core/modes.gd")


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var guide_path: String = arguments[0] if arguments.size() > 0 else Modes.guide_path(Modes.MINIMAL)
	var output_path: String = arguments[1] if arguments.size() > 1 else "res://guides/minimal_preview.png"
	if not FileAccess.file_exists(guide_path):
		printerr("guide introuvable : %s" % guide_path)
		quit(1)
		return
	var heights: PackedStringArray = HeightMask.read(guide_path)
	# Troisieme argument : « peint » ou « fil ». Quatrieme : « representatif » ou « utilisable ».
	var ink: GuideImage.Ink = GuideImage.Ink.PAINTED
	if arguments.size() > 2 and arguments[2] == "fil":
		ink = GuideImage.Ink.WIREFRAME
	# Quatrieme argument : « nu » pour retirer les marques de travail.
	var marks: bool = true
	if arguments.size() > 3 and arguments[3] == "nu":
		marks = false
	var purpose: GuideImage.Purpose = GuideImage.Purpose.REPRESENTATIVE
	# Cinquieme argument : le cote de tuile, pour inspecter le trait de pres.
	var tile_size: int = GuideImage.TILE
	if arguments.size() > 4:
		tile_size = maxi(8, arguments[4].to_int())
	var image: Image = GuideImage.render(heights, tile_size, ink, purpose, marks)
	var error: Error = image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		printerr("ecriture impossible : %d" % error)
		quit(1)
		return
	print("%s -> %s (%dx%d)" % [guide_path, output_path, image.get_width(), image.get_height()])
	quit(0)
