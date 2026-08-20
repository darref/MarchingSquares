extends SceneTree

var _frames: int = 0
var _target: String = "shot.png"
var _style: int = -1
var _editor: Node = null


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() > 0:
		_target = arguments[0]
	var scene: PackedScene = load("res://ui/editor.tscn")
	if scene == null:
		printerr("scene illisible")
		quit(1)
		return
	_editor = scene.instantiate()
	root.add_child(_editor)
	# Second argument facultatif : « usable » pour capturer l autre style de fond.
	if arguments.size() > 1 and arguments[1] == "usable":
		_style = 1


## ⚠ ON N'AGIT PAS SUR LA SCENE DEPUIS _initialize(). A ce moment l'arbre n'a pas encore
## demarre : les _ready() n'ont pas tourne, et les listes deroulantes sont vides.
func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3 and _style >= 0:
		var choice: OptionButton = _editor.get_node("%StyleChoice")
		choice.select(_style)
		choice.item_selected.emit(_style)
	if _frames < 20:
		return false
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(_target)
	if error != OK:
		printerr("capture impossible : %d" % error)
	else:
		print("capture %s (%dx%d)" % [_target, image.get_width(), image.get_height()])
	return true
