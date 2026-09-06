extends SceneTree

var _frames: int = 0
var _manual: bool = false
var _target: String = "shot.png"
var _technic: int = -1
var _ink: int = -1
var _work: String = ""
var _assembled: bool = false

var _marks: bool = true
## ⚠ POUR REGARDER LES COUTURES. Grille en place, ses traits les couvrent : c'est exactement
## pourquoi elles ne se voyaient pas avant qu'on puisse la masquer.
var _no_grid: bool = false
var _hover: Vector2i = Vector2i(-1, -1)
var _hovered: bool = false
var _family: int = -1
var _strokes: bool = false
var _stroked: bool = false
var _editor: Node = null
var _zoom_at: Vector2 = Vector2.ZERO
## Le paysage a ouvrir, par son identifiant de mode. ⚠ IL SE POSE AVANT LE RESEAU : la
## liste des reseaux se grise d'apres le guide, donc changer de paysage apres coup
## deplacerait la selection sous nos pieds.
var _mode: StringName = &""
## L'atelier a capturer. ⚠ ON PASSE PAR LE BOUTON, PAS PAR LA VARIABLE : un outil de
## relecture qui prendrait un raccourci ne relirait pas ce que l'utilisateur voit.
var _room: StringName = &""
var _zoom_steps: int = 0
var _zoomed: bool = false


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
	# Arguments facultatifs, dans n'importe quel ordre : la technique (« utilisable »,
	# « example »), le style (« fil »), « remontage », et un travail a ouvrir.
	for index: int in range(1, arguments.size()):
		var argument: String = arguments[index]
		match argument:
			"example":
				_technic = 1
			"nu":
				_marks = false
			"sansgrille":
				_no_grid = true
			"cheval":
				_family = 1
			"fil":
				_ink = 1
			"contour":
				_ink = 2
			"remontage":
				_assembled = true
			"manuel":
				_manual = true
			"massifs":
				_mode = &"massifs"
			"trait":
				_strokes = true
			# ⚠ LES DEUX MOTS, parce que l interface est passee a l anglais et que le mot-cle,
			# lui, etait reste francais. Une relecture qui refuse le mot qu on a sous les yeux
			# n aide personne.
			"essai", "test":
				_room = &"test"
			_:
				if argument.begins_with("zoom="):
					# ⚠ POUR REGARDER LE TRAIT, PAS LE PAYSAGE. En vue d'ensemble un faux pixel
					# mesure moins d'un pixel d'ecran : un contour d'UN pixel y disparait, et
					# ce qui en survit se lit comme du bruit. La lecon est deja au dossier pour
					# le crayon ; elle vaut pour le fond.
					var z: PackedStringArray = argument.substr(5).split(",")
					if z.size() == 3:
						_zoom_at = Vector2(z[0].to_float(), z[1].to_float())
						_zoom_steps = z[2].to_int()
				elif argument.begins_with("survol="):
					var at: PackedStringArray = argument.substr(7).split(",")
					if at.size() == 2:
						_hover = Vector2i(at[0].to_int(), at[1].to_int())
				elif argument.ends_with(".solutiles"):
					_work = argument
				else:
					# ⚠ UN ARGUMENT INCONNU SE DIT. Il etait avale en silence : on demandait une
					# room, on recevait une capture de la room par defaut, « sans une seule
					# erreur » -- et on cherchait la panne dans le logiciel. Releve par la session
					# anglaise, qui a tape `test` quand le mot-cle etait `essai`.
					printerr("capture : argument inconnu « %s » -- ignore." % argument)


## ⚠ ON N'AGIT PAS SUR LA SCENE DEPUIS _initialize(). A ce moment l'arbre n'a pas encore
## demarre : les _ready() n'ont pas tourne, et les listes deroulantes sont vides.
func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		if _mode != &"":
			var modes: OptionButton = _editor.get_node("%ModeChoice")
			for index2: int in range(modes.item_count):
				if StringName(modes.get_item_metadata(index2)) == _mode:
					modes.select(index2)
					modes.item_selected.emit(index2)
					break
		if _family >= 0:
			var family: OptionButton = _editor.get_node("%FamilyChoice")
			family.select(_family)
			family.item_selected.emit(_family)
		if _technic >= 0:
			var technic: OptionButton = _editor.get_node("%StyleChoice")
			technic.select(_technic)
			technic.item_selected.emit(_technic)
		if not _marks:
			var marks: CheckBox = _editor.get_node("%MarksCheck")
			marks.button_pressed = true
			marks.toggled.emit(true)
		if _no_grid:
			var grid: CheckBox = _editor.get_node("%GridCheck")
			grid.button_pressed = true
			grid.toggled.emit(true)
		if _ink >= 0:
			var ink: OptionButton = _editor.get_node("%InkChoice")
			ink.select(_ink)
			ink.item_selected.emit(_ink)
		# ⚠ ON APPELLE LE MEME CHEMIN QUE LE BOUTON. Un outil de relecture qui prendrait un
		# raccourci ne relirait pas ce que l'utilisateur voit.
		if _work != "":
			_editor.call("_on_open_chosen", _work)
		if _room != &"":
			for child: Node in _editor.get_node("%RoomGrid").get_children():
				var button: Button = child as Button
				# ⚠ PAR L IDENTIFIANT, PAS PAR LE LIBELLE : celui-ci se traduit.
				if button != null and button.get_meta("room", &"") == _room:
					button.button_pressed = true
					button.pressed.emit()
			# ⚠ ON POSE DU RELIEF PAR DE VRAIS CLICS, pas en appelant le tampon. Une relecture
			# qui prendrait un raccourci ne relirait pas ce que l'utilisateur voit -- c'est la
			# regle deja suivie pour le mode d'emploi et pour le zoom.
			var room: Control = _editor.get_node("%TestRoom")
			for step: Vector2i in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(6, 0),
					Vector2i(3, 3), Vector2i(6, 3), Vector2i(4, 1)]:
				var click: InputEventMouseButton = InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = true
				click.position = room.size * 0.5 + Vector2(step) * 18.0
				room.gui_input.emit(click)
		if _assembled:
			var check: CheckBox = _editor.get_node("%AssembledCheck")
			check.button_pressed = true
			check.toggled.emit(true)
		if _manual:
			# ⚠ ON PASSE PAR LE MEME CHEMIN QUE LE CLIC. Un outil de relecture qui prendrait
			# un raccourci ne relirait pas ce que l'utilisateur voit.
			var ticker: Label = _editor.get_node("%Ticker")
			var click: InputEventMouseButton = InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			ticker.gui_input.emit(click)
	# ⚠ ON ATTEND QUE LE FOND SOIT DESSINE. Il se calcule par etapes ; capturer trop tot
	# ne montrerait que la barre de progression.
	if _frames < 20:
		return false
	var loading: Control = _editor.get_node("%LoadingPanel")
	if loading.visible and _frames < 900:
		return false
	# ⚠ LE ZOOM SE POSE APRES LE FOND, ET PAR LE MEME CHEMIN QUE LA MOLETTE. Une relecture qui
	# prendrait un raccourci ne relirait pas ce que l'utilisateur voit -- c'est la regle deja
	# ecrite ici pour le survol et pour le clic.
	if _zoom_steps > 0 and not _zoomed:
		_zoomed = true
		var zoom_work: Control = _editor.get_node("%WorkArea")
		var pivot: Vector2 = zoom_work._cell_origin(Vector2i(int(_zoom_at.x), int(_zoom_at.y)))
		for _turn: int in range(_zoom_steps):
			zoom_work._zoom_at(pivot, 1.12)
		zoom_work.queue_redraw()
		return false
	# ⚠ LE SURVOL SE POSE AU DERNIER MOMENT. Pose plus tot, la VRAIE souris -- garee quelque
	# part sur l'ecran -- emet son propre survol et l'ecrase. On a cru un panneau casse alors
	# qu'il suivait fidelement un curseur qu'on ne voyait pas.
	if _hover.x >= 0 and not _hovered:
		_hovered = true
		# Par le meme chemin que la souris : la zone de travail resout la case, dessine le
		# cercle et les liees, et emet hover_changed vers le releve. Poser seulement le
		# releve, comme avant, montrait un survol que la zone de travail ignorait.
		var hover_work: Control = _editor.get_node("%WorkArea")
		var centre: Vector2 = hover_work._cell_origin(_hover) \
				+ Vector2(hover_work._tile_px, hover_work._tile_px) * 0.5
		hover_work._set_hover(centre)
		hover_work.queue_redraw()
		return false
	# Quelques coups d'outil, pour voir les jumelles se remplir : un pot sur l'herbe pleine,
	# une brosse sur une robe. Par le meme chemin que la souris, et une image avant la
	# capture pour que les textures remontent.
	if _strokes and not _stroked:
		_stroked = true
		_paint_samples()
		return false
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(_target)
	if error != OK:
		printerr("capture impossible : %d" % error)
	else:
		print("capture %s (%dx%d)" % [_target, image.get_width(), image.get_height()])
	return true


func _paint_samples() -> void:
	var work: Control = _editor.get_node("%WorkArea")
	var grass: Vector2i = Vector2i(-1, -1)
	var wall: Vector2i = Vector2i(-1, -1)
	var surfaces: Dictionary = work.surface_index()
	for cell: Vector2i in work._paintable.keys():
		if grass.x < 0 and surfaces.has(cell) and int(surfaces[cell]) == 255:
			grass = cell
		elif wall.x < 0 and work.wall_roles().has(cell):
			wall = cell
	var half: Vector2 = Vector2(work._tile_px, work._tile_px) * 0.5
	if grass.x >= 0:
		work.tool = work.Tool.BUCKET
		work.pencil = Color(0.706, 0.741, 0.522)
		var at: Vector2 = work._cell_origin(grass) + half
		work._begin_or_end(true, 1, at)
		work._begin_or_end(false, 1, at)
	if wall.x >= 0:
		work.tool = work.Tool.BRUSH
		work.brush_size = 4
		work.pencil = Color(0.612, 0.514, 0.396)
		var from: Vector2 = work._cell_origin(wall) + Vector2(half.x * 0.3, half.y)
		var to: Vector2 = work._cell_origin(wall) + Vector2(half.x * 1.7, half.y)
		work._begin_or_end(true, 1, from)
		work._apply_stroke(from, to)
		work._begin_or_end(false, 1, to)
	work.tool = work.Tool.PENCIL
