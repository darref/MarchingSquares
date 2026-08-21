extends SceneTree

var _frames: int = 0
var _target: String = "shot.png"
var _technic: int = -1
var _ink: int = -1
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
	# Arguments facultatifs : la technique (« utilisable ») et le style (« fil »).
	if arguments.size() > 1 and arguments[1] == "utilisable":
		_technic = 1
	if arguments.size() > 2 and arguments[2] == "fil":
		_ink = 1


## ⚠ ON N'AGIT PAS SUR LA SCENE DEPUIS _initialize(). A ce moment l'arbre n'a pas encore
## demarre : les _ready() n'ont pas tourne, et les listes deroulantes sont vides.
func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		if _technic >= 0:
			var technic: OptionButton = _editor.get_node("%StyleChoice")
			technic.select(_technic)
			technic.item_selected.emit(_technic)
		if _ink >= 0:
			var ink: OptionButton = _editor.get_node("%InkChoice")
			ink.select(_ink)
			ink.item_selected.emit(_ink)
	# ⚠ ON ATTEND QUE LE FOND SOIT DESSINE. Il se calcule par etapes ; capturer trop tot
	# ne montrerait que la barre de progression.
	if _frames < 20:
		return false
	var loading: Control = _editor.get_node("%LoadingPanel")
	if loading.visible and _frames < 900:
		return false
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(_target)
	if error != OK:
		printerr("capture impossible : %d" % error)
	else:
		print("capture %s (%dx%d)" % [_target, image.get_width(), image.get_height()])
	return true
