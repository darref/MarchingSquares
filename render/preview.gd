# Ecrit l'illustration du guide sur disque.
#
#   godot --headless --path . --script res://render/preview.gd [guide] [sortie]
#
# Par defaut : le guide du mode minimal, vers guides/minimal_preview.png.
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
	var image: Image = GuideImage.render(heights)
	var error: Error = image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		printerr("ecriture impossible : %d" % error)
		quit(1)
		return
	print("%s -> %s (%dx%d)" % [guide_path, output_path, image.get_width(), image.get_height()])
	quit(0)
