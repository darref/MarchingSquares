extends Control

## L'ÉDITEUR DE MARCHING SQUARES SUR LE MODÈLE PAR LES COINS — l'interface du début, gardée (Jordan, 4 novembre 2026 :
## « où est passée l'interface avec les deux volets, la barre du haut, la vue centrale […] le mode draw et le mode
## test ? », puis « oui » à « mettre le nouveau modèle dans l'ancienne interface ») : la scène est celle de
## `ui/editor.tscn`, les mêmes volets et sections ; dessous, le modèle par les coins (`core/coins/`, la zone
## `ui/coins/zone.gd`). Câblage, et rien d'autre : aucune règle du produit ne vit ici.
##   DRAW   le guide des coins ; la ligne « Paint » choisit la surface de base ou une matière ; la section Variants.
##   TEST   un relief à soi, peint avec les mêmes outils ; la section Sculpt (le bouton « Sculpt plateaus »).
## Ce qui n'a plus de sens est caché : le choix du réseau et le fond d'exemple de l'ancien modèle, l'export « packed ».

const Painting := preload("res://core/painting.gd")
const Travail := preload("res://core/coins/travail.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")
const Essai := preload("res://core/coins/essai.gd")
const Installer := preload("res://core/coins/installer.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const MANUEL := preload("res://ui/coins/manuel.gd")
const ToolSection := preload("res://ui/tool_section.gd")

const GUIDE := "res://guides/coins.txt"
const GUIDE_MATIERES := "res://guides/coins_matieres.txt"
## ⚠ 16, 32, 64 SEULEMENT : le guide entier se compose en une image, et à 128 faux pixels par case elle passerait
## seize millions de pixels (quatre tableaux de cette taille) — l'ancien éditeur offrait 256, celui-ci le refuserait.
const RESOLUTIONS: Array[int] = [16, 32, 64]
const WINDOW_SCREEN_SHARE: float = 0.95
const DRAW: StringName = &"draw"
const TEST: StringName = &"test"
const SALLES := {
	DRAW: {"label": "Draw", "sections": ["WorkSection", "EngineSection", "SupportSection", "PencilSection",
			"NeighboursSection", "ViewSection", "VariantsSection"]},
	TEST: {"label": "Test", "sections": ["WorkSection", "EngineSection", "SupportSection", "PencilSection",
			"SculptSection", "NeighboursSection", "ViewSection"]},
}
const SECTIONS: Array[String] = ["WorkSection", "BackgroundSection", "EngineSection", "PencilSection",
		"NeighboursSection", "ViewSection", "VariantsSection", "SculptSection", "SupportSection"]
## LES DONS — la même liste que MarchingBlocks (`app/dons.gd`, son FUNDING.yml, son README) : MarchingSquares est libre
## (CC0) et vit de dons (Jordan, 4 novembre 2026 : « préparer le GitHub Sponsors […] comme on l'a fait pour Marching
## Blocks »). Une plateforme ajoutée s'ajoute ici, dans `.github/FUNDING.yml` et dans le README.
const DONS: Array = [["Donate on Ko-fi", "https://ko-fi.com/darref"],
		["Sponsor on GitHub", "https://github.com/sponsors/darref"]]
const SCULPT := 8
const TOOL_KEYS: Dictionary = {KEY_P: 0, KEY_B: 1, KEY_A: 2, KEY_G: 3, KEY_L: 4, KEY_R: 5, KEY_I: 6, KEY_E: 7}
const SORTES := ["", "top", "cliff top", "cliff bottom"]

## Le bandeau du haut : il dit quelque chose de VRAI à chaque phrase (la règle de l'ancien), et un clic ouvre le mode
## d'emploi.
const PROMISES: Array[String] = [
	"One guide holds all 35 tiles and all 261 junctions. Paint it once.",
	"Proven, not promised: 6,523,200 pixels against an exact ray cast, no difference.",
	"The pencil only reaches the tile you see, and only inside its shape.",
	"Painting one tile paints it everywhere it appears.",
	"Pink points: where a band meets the tile edge. Carry the drawing on there.",
	"V makes a variant from the tile you hover. C switches it, X removes it.",
	"Test: sculpt your own world with S, paint it with any tool. The change is everywhere.",
	"Materials share the 15 top shapes: rounded, never in steps.",
	"Left click paints, right click erases. Ctrl+Z undoes a whole stroke.",
	"Tools: P B A G L R I E. The brackets change the size. Tab: Draw / Test.",
	"Click here: the user guide opens full size.",
	"Install the plugin: point at the folder that holds project.godot.",
]
const PROMISE_SECONDS: float = 6.0

var _peinture: Painting
var _meta := {"poids": {}, "affectation": {}}
var _guide := {}
var _guide_mat := PackedInt32Array()
var _work_path := ""
var _dirty := false
var _reset_after_save := false
var _room: StringName = DRAW
var _outil_salle := {DRAW: 0, TEST: SCULPT}
var _promise := 0
var _elapsed := PROMISE_SECONDS
var _busy_held := false
var _manual: Control
var _new_dialog: ConfirmationDialog
var _open_dialog: FileDialog
var _save_dialog: FileDialog
var _export_dialog: FileDialog
var _plugin_dialog: FileDialog
var _trial_dialog: FileDialog
var _sculpt_button: Button
var _brush_material: OptionButton
var _materials_label: Label
var _room_buttons := {}


func _ready() -> void:
	(%Version as Label).text = String(ProjectSettings.get_setting("application/config/version", "?"))
	_apply_window_size()
	_guide = lire_guide(GUIDE)
	if FileAccess.file_exists(GUIDE_MATIERES):
		_guide_mat = lire_guide(GUIDE_MATIERES).h
	_construire_sections()
	_reecrire_textes()
	_fill_rooms()
	_fill_paint_choice()
	_fill_resolutions()
	var zone := _zone()
	zone.painting_changed.connect(_refresh_counters)
	zone.painting_changed.connect(_on_painting_changed)
	zone.painting_changed.connect((%NeighboursPanel as Control).mark_dirty)
	zone.relief_changed.connect(_on_painting_changed)
	zone.hover_changed.connect(_on_hover_changed)
	zone.pencil_picked.connect(_on_pencil_picked)
	zone.refused.connect(_announce)
	(%NewButton as Button).pressed.connect(_on_new_pressed)
	(%OpenButton as Button).pressed.connect(func() -> void: _open_dialog.popup_centered_ratio(0.6))
	(%SaveButton as Button).pressed.connect(_on_save_pressed)
	(%ExportButton as Button).pressed.connect(func() -> void: _export_dialog.popup_centered_ratio(0.6))
	(%InstallPluginButton as Button).pressed.connect(func() -> void: _plugin_dialog.popup_centered_ratio(0.6))
	(%TrialButton as Button).pressed.connect(func() -> void: _trial_dialog.popup_centered_ratio(0.6))
	(%FitButton as Button).pressed.connect(func() -> void: _zone().fit())
	(%ModeChoice as OptionButton).item_selected.connect(_on_paint_selected)
	(%SizeChoice as OptionButton).item_selected.connect(_on_resolution_selected)
	(%PencilColor as ColorPickerButton).color_changed.connect(func(c: Color) -> void: _zone().pencil = c)
	for swatch: Node in %Swatches.get_children():
		var b := swatch as Button
		if b != null:
			b.pressed.connect(_on_swatch_pressed.bind(b))
	(%LockCheck as CheckBox).toggled.connect(func(on: bool) -> void: _zone().lock_to_tile = on)
	for child: Node in %ToolGrid.get_children():
		var tb := child as Button
		if tb != null and tb.has_meta("tool"):
			tb.toggled.connect(_on_tool_toggled.bind(tb))
	_sculpt_button.toggled.connect(_on_tool_toggled.bind(_sculpt_button))
	for child: Node in %BrushRow.get_children():
		var sb := child as Button
		if sb != null and sb.has_meta("size"):
			sb.toggled.connect(func(on: bool) -> void: if on: _zone().brush_size = int(sb.get_meta("size")))
	(%GridCheck as CheckBox).toggled.connect(_on_grid_toggled)
	(%AssembledCheck as CheckBox).toggled.connect(_on_assembled_toggled)
	(%WorkCheck as CheckBox).toggled.connect(_on_work_hidden)
	_manual = MANUEL.new()
	add_child(_manual)
	var ticker: Label = %Ticker
	ticker.mouse_filter = Control.MOUSE_FILTER_STOP
	ticker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ticker.tooltip_text = "User guide"
	ticker.gui_input.connect(_on_ticker_input)
	_build_dialogs()
	_apply_margins()
	zone.pencil = (%PencilColor as ColorPickerButton).color
	_nouveau_carnet()
	_apply_room()
	await get_tree().process_frame
	_apply_window_size()
	_apply_margins()
	zone.fit()


func _zone() -> Control:
	return %WorkArea as Control


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < PROMISE_SECONDS:
		return
	_elapsed = 0.0
	(%Ticker as Label).text = PROMISES[_promise]
	_promise = (_promise + 1) % PROMISES.size()


func _apply_window_size() -> void:
	var window := get_window()
	# Une prise de vue (`--write-movie`) fixe sa fenêtre elle-même : la redimensionner changerait la taille du film.
	if window == null or DisplayServer.get_name() == "headless" or window.has_meta("tournage"):
		return
	if window.mode != Window.MODE_WINDOWED:
		window.mode = Window.MODE_WINDOWED
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var target := Vector2i(int(usable.size.x * WINDOW_SCREEN_SHARE), int(usable.size.y * WINDOW_SCREEN_SHARE))
	window.size = target
	window.position = usable.position + (usable.size - target) / 2


# ── l'interface : ce qui change par rapport à l'ancien éditeur ───────────────────────────────────────────────────────

## Une section repliable de plus, faite comme celles de la scène (en-tête plat, contenu à marges).
func _section(nom: String, titre: String, avant: String, apres := false) -> VBoxContainer:
	var parent := (find_child(avant, true, false) as Node).get_parent()
	var sec := VBoxContainer.new()
	sec.name = nom
	sec.add_theme_constant_override("separation", 0)
	var header := Button.new()
	header.name = "Header"
	header.toggle_mode = true
	header.flat = true
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_color_override("font_color", Color(0.878, 0.878, 0.851))
	header.add_theme_color_override("font_pressed_color", Color(0.878, 0.878, 0.851))
	header.add_theme_color_override("font_hover_color", Color(0.706, 0.741, 0.522))
	sec.add_child(header)
	var content := MarginContainer.new()
	content.name = "Content"
	for cote: String in ["left", "right"]:
		content.add_theme_constant_override("margin_" + cote, 10)
	content.add_theme_constant_override("margin_top", 6)
	content.add_theme_constant_override("margin_bottom", 10)
	sec.add_child(content)
	var items := VBoxContainer.new()
	items.name = "Items"
	items.add_theme_constant_override("separation", 6)
	content.add_child(items)
	sec.set_script(ToolSection)
	sec.set("title", titre)
	sec.set("expanded", true)
	parent.add_child(sec)
	parent.move_child(sec, (find_child(avant, true, false) as Node).get_index() + (1 if apres else 0))
	return items


func _bouton(dans: Container, texte: String, aide: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.tooltip_text = aide
	b.pressed.connect(action)
	dans.add_child(b)
	return b


func _etiquette(dans: Container, texte: String) -> Label:
	var l := Label.new()
	l.text = texte
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.65, 0.67, 0.62))
	dans.add_child(l)
	return l


func _construire_sections() -> void:
	var v := _section("VariantsSection", "Variants", "ViewSection")
	_etiquette(v, "On the last tile you hovered in the guide. A variant starts as a copy, shown on that spot among its real neighbours; the game draws variants by a fixed hash of the position, weighted.")
	_bouton(v, "New variant here (V)", "Copy the hovered tile into a new variant, shown on this spot.",
			func() -> void: _variante(func() -> String: return _zone().nouvelle_variante(), true))
	_bouton(v, "Next variant here (C)", "Which variant this spot shows.",
			func() -> void: _variante(func() -> String: return _zone().changer_variante(), true))
	_bouton(v, "Remove this variant (X)", "The following ones are renumbered.",
			func() -> void: _variante(func() -> String: return _zone().oter_variante(), true))
	var poids := HBoxContainer.new()
	v.add_child(poids)
	_bouton(poids, "Weight −", "How often the game draws this variant (-).",
			func() -> void: _variante(func() -> String: return _zone().regler_poids(-1), false))
	_bouton(poids, "Weight +", "How often the game draws this variant (+).",
			func() -> void: _variante(func() -> String: return _zone().regler_poids(1), false))
	var d := _section("SupportSection", "Support", "EngineSection", true)
	_etiquette(d, "MarchingSquares is free and open (CC0), made by one developer. If it helps you build your worlds, a donation keeps it going.")
	for don: Array in DONS:
		var url: String = don[1]
		_bouton(d, don[0], url, func() -> void: OS.shell_open(url))
	var s := _section("SculptSection", "Sculpt", "PencilSection")
	_sculpt_button = Button.new()
	_sculpt_button.text = "Sculpt plateaus (S)"
	_sculpt_button.toggle_mode = true
	_sculpt_button.tooltip_text = "Click raises the corner you see, right click lowers it. Shift + click paints the brush material, Shift + right click removes it."
	_sculpt_button.button_group = (%ToolGrid.get_child(0) as Button).button_group
	_sculpt_button.set_meta("tool", SCULPT)
	s.add_child(_sculpt_button)
	var ligne := HBoxContainer.new()
	s.add_child(ligne)
	var l := Label.new()
	l.text = "Brush material"
	ligne.add_child(l)
	_brush_material = OptionButton.new()
	for m in range(1, Modele.MATIERES_MAXI):
		_brush_material.add_item("Material %d" % m)
	_brush_material.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_brush_material.item_selected.connect(func(i: int) -> void: _zone().matiere_pinceau = i + 1)
	ligne.add_child(_brush_material)
	_bouton(s, "Back to the starting world", "Two terraces and a niche on a plain, with a patch of material 1.",
			func() -> void:
				_zone().relief = _zone().relief_de_depart()
				_zone()._apres_relief()
				_zone().fit())
	_etiquette(s, "Any painting tool paints the tile you see here, and the change is everywhere. This world does not hold every junction: check them in Draw.")
	_materials_label = Label.new()
	_materials_label.add_theme_font_size_override("font_size", 11)
	(%RemainingLabel as Label).get_parent().add_child(_materials_label)
	_materials_label.get_parent().move_child(_materials_label, (%RemainingLabel as Label).get_index() + 1)


func _reecrire_textes() -> void:
	_texte("Slogan", "Paint one guide. Every junction covered.")
	_texte("Subtitle", "Heights on corners, 35 tiles, proven pixel by pixel.")
	_texte("ModeLabel", "Paint")
	_texte("NeighboursLabel", "The hovered tile, full size. Hatched: not yours to paint. Pink: its junction points.")
	_texte("ViewHint", "Wheel: zoom · middle button: move\nP B A G L R I E: tools · [ ]: size\nTab: Draw / Test · S: sculpt (Test)\nV C X: variants · + -: weight\nCtrl+Z / Ctrl+Y · Ctrl+S · Ctrl+O")
	(%FitButton as Button).text = "Fit the view"
	(%InstallPluginButton as Button).tooltip_text = "Copies the MarchingSquares plugin into a Godot project, with your tileset if it is complete, the trial otherwise. You still have to tick it in Project > Project Settings > Plugins."
	(%TrialButton as Button).tooltip_text = "Writes a complete tileset computed from the model, without painting a pixel: enough to try the plugin. It is a specification drawing, not art."
	(%PluginHint as Label).text = "The plugin places your world with the tiles painted here."
	(%ExportButton as Button).text = "Export tileset"
	(%PackedButton as Button).visible = false
	(%FamilyChoice as Control).get_parent().visible = false
	var sec := find_child("NeighboursSection", true, false)
	if sec != null:
		sec.set("title", "Tile")
		sec.set("expanded", true)


func _texte(nom: String, texte: String) -> void:
	var n := find_child(nom, true, false) as Label
	if n != null:
		n.text = texte


func _fill_rooms() -> void:
	var grid: GridContainer = %RoomGrid
	for old: Node in grid.get_children():
		old.queue_free()
	var group := ButtonGroup.new()
	for id: StringName in [DRAW, TEST]:
		var b := Button.new()
		b.text = SALLES[id].label
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.button_pressed = id == _room
		b.pressed.connect(choisir_salle.bind(id))
		grid.add_child(b)
		_room_buttons[id] = b
	(%Rooms as Control).visible = true


## Draw ↔ Test : le TRAVAIL ne bouge pas (le même carnet, la même annulation), seule change la vue — et chaque salle
## garde son dernier outil (Test commence par Sculpt).
func choisir_salle(id: StringName) -> void:
	if id == _room:
		return
	_room = id
	(_room_buttons[id] as Button).button_pressed = true
	_apply_room()


func _apply_room() -> void:
	for nom: String in SECTIONS:
		var s := find_child(nom, true, false) as Control
		if s != null:
			s.visible = (SALLES[_room].sections as Array).has(nom)
	_zone().set_mode_relief(_room == TEST)
	_choisir_outil(int(_outil_salle[_room]))
	_apply_margins()
	_announce("Test: your own world. S sculpts, the other tools paint." if _room == TEST
			else "Draw: the guide, every tile and every junction.")


func _choisir_outil(t: int) -> void:
	if t == SCULPT:
		_sculpt_button.button_pressed = true
	else:
		_press_meta(%ToolGrid, "tool", t)
	_zone().tool = t


func _on_tool_toggled(pressed: bool, button: Button) -> void:
	if not pressed:
		return
	var t := int(button.get_meta("tool"))
	_zone().tool = t
	_outil_salle[_room] = t


func _press_meta(row: Node, key: String, value: int) -> void:
	for child: Node in row.get_children():
		var b := child as Button
		if b != null and b.has_meta(key) and int(b.get_meta(key)) == value:
			b.button_pressed = true
			return


func _fill_paint_choice() -> void:
	var c: OptionButton = %ModeChoice
	c.clear()
	c.add_item("Base surface")
	for m in range(1, Modele.MATIERES_MAXI):
		c.add_item("Material %d" % m)
	c.tooltip_text = "What the guide shows to paint: the base surface (tops and cliffs), or a material's 15 top shapes laid on the plateaus."
	c.select(0)


func _fill_resolutions() -> void:
	var c: OptionButton = %SizeChoice
	c.clear()
	for r: int in RESOLUTIONS:
		c.add_item("%d x %d" % [r, r])
		c.set_item_metadata(c.item_count - 1, r)
	c.select(0)


func _current_resolution() -> int:
	var c: OptionButton = %SizeChoice
	return int(c.get_item_metadata(c.selected))


func _on_paint_selected(index: int) -> void:
	await _show_then("Laying the guide", "the material's field on the landscape" if index > 0 else "the base surface")
	_zone().set_matiere(index)
	_announce("Painting the base surface." if index == 0 else "Painting material %d: its 15 top shapes are in the guide." % index)


func _on_resolution_selected(_index: int) -> void:
	await _show_then("Changing the pixel size", "the guide and its tiles")
	_nouveau_carnet()
	_announce("Each tile is now %d x %d fake pixels." % [_current_resolution(), _current_resolution()])


func _on_swatch_pressed(b: Button) -> void:
	if not b.has_meta("color"):
		return
	var c: Color = b.get_meta("color")
	(%PencilColor as ColorPickerButton).color = c
	_zone().pencil = c


func _on_pencil_picked(c: Color) -> void:
	(%PencilColor as ColorPickerButton).color = c


func _on_grid_toggled(pressed: bool) -> void:
	_zone().set_grid(not pressed)
	_announce("Grid and junction points hidden." if pressed else "Grid and junction points back.")


func _on_assembled_toggled(pressed: bool) -> void:
	_zone().assembled = pressed
	_zone().recolorer()
	_announce("Guide hidden: your tiles alone." if pressed else "Guide back.")


func _on_work_hidden(pressed: bool) -> void:
	_zone().hide_work = pressed
	_zone().recolorer()
	_announce("Work hidden: the guide alone." if pressed else "Work back.")


func _on_hover_changed(info: Dictionary) -> void:
	(%NeighboursPanel as Control).montrer(info, _peinture)
	var label: Label = %HoverLabel
	if int(info.get("outil", 0)) == SCULPT:
		label.text = "click: raise · right click: lower · Shift: material %d" % _zone().matiere_pinceau
		return
	if bool(info.get("vide", true)):
		label.text = "nothing to paint here"
		return
	var quoi: String = SORTES[int(info.sorte)] if int(info.matiere) == 0 else "material %d" % int(info.matiere)
	var v := ""
	if int(info.variantes) > 1:
		v = " · variant %d of %d, weight %d" % [int(info.variante), int(info.variantes) - 1, (info.poids as PackedInt32Array)[int(info.variante)]]
	label.text = "tile %d (%s)%s · %d here, %d in the guide" % [int(info.archetype), quoi, v, int(info.ici), int(info.au_guide)]


func _variante(action: Callable, long: bool) -> void:
	if long:
		await _show_then("Variants", "recomposing the view")
	var dit: String = action.call()
	_refresh_counters()
	if dit != "":
		_announce(dit)
	else:
		_idle()


func _on_ticker_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_manual.open()
		(%Ticker as Label).accept_event()


# ── l'attente, montrée (les mêmes règles que l'ancien éditeur) ───────────────────────────────────────────────────────

func _busy(title: String, note: String) -> void:
	(%LoadingPanel as Control).visible = true
	(%LoadingTitle as Label).text = title
	var bar: ProgressBar = %LoadingBar
	bar.max_value = 1.0
	bar.value = 1.0
	(%LoadingCount as Label).text = note


func _idle() -> void:
	_busy_held = false
	(%LoadingPanel as Control).visible = false


## ⚠ Attendre que le panneau soit DESSINÉ (`frame_post_draw`), sinon il n'apparaît jamais (leçon de l'ancien éditeur).
func _show_then(title: String, note: String) -> void:
	_busy(title, note)
	_busy_held = true
	await get_tree().process_frame
	# Sans fenêtre (la sonde), aucune image n'est dessinée : l'attendre bloquerait pour toujours.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw


func _apply_margins() -> void:
	var zone := _zone()
	zone.reserved_left = (%Sidebar as Control).size.x
	zone.reserved_right = (%Toolbar as Control).size.x


func _announce(text: String) -> void:
	_idle()
	(%Ticker as Label).text = text
	_elapsed = 0.0


# ── le travail ───────────────────────────────────────────────────────────────────────────────────────────────────────

func _nouveau_carnet() -> void:
	_peinture = Painting.new(_current_resolution())
	var relief: Dictionary = _meta.get("relief", {})
	_meta = {"poids": {}, "affectation": {}}
	if relief.has("h"):
		_meta.relief = relief
	_zone().adopt(_peinture, _meta, _guide, _guide_mat)
	_zone().set_matiere((%ModeChoice as OptionButton).selected)
	_dirty = false
	_refresh_counters()
	(%NeighboursPanel as Control).montrer({}, _peinture)


func _build_dialogs() -> void:
	var filtre := PackedStringArray(["*.%s ; MarchingSquares work" % Travail.EXTENSION])
	_open_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_FILE, "Open a work file", filtre)
	_open_dialog.file_selected.connect(ouvrir)
	_save_dialog = _make_dialog(FileDialog.FILE_MODE_SAVE_FILE, "Save the work file", filtre)
	_save_dialog.file_selected.connect(enregistrer)
	_save_dialog.canceled.connect(func() -> void: _reset_after_save = false)
	_export_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR, "Export the tileset", PackedStringArray())
	_export_dialog.dir_selected.connect(exporter)
	_plugin_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR, "Choose a Godot project", PackedStringArray())
	_plugin_dialog.dir_selected.connect(installer)
	_trial_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR, "Where to write the trial", PackedStringArray())
	_trial_dialog.dir_selected.connect(essai)
	_new_dialog = ConfirmationDialog.new()
	_new_dialog.title = "New project"
	_new_dialog.ok_button_text = "Save, then start over"
	_new_dialog.get_cancel_button().text = "Cancel"
	_new_dialog.add_button("Start over without saving", false, "jeter")
	_new_dialog.confirmed.connect(func() -> void:
		_reset_after_save = true
		_on_save_pressed())
	_new_dialog.custom_action.connect(func(a: StringName) -> void:
		if a == &"jeter":
			_new_dialog.hide()
			_nouveau_projet())
	add_child(_new_dialog)


func _make_dialog(mode: FileDialog.FileMode, title: String, filters: PackedStringArray) -> FileDialog:
	var d := FileDialog.new()
	d.file_mode = mode
	d.access = FileDialog.ACCESS_FILESYSTEM
	d.title = title
	d.filters = filters
	d.use_native_dialog = true
	add_child(d)
	return d


func _on_painting_changed() -> void:
	_dirty = true


func _on_new_pressed() -> void:
	if not (_dirty and not _peinture.painted_cells().is_empty()):
		_nouveau_projet()
		return
	var where := "The last save is %s." % _work_path.get_file() if _work_path != "" else "This work has never been saved."
	_new_dialog.dialog_text = "%d painted tiles are not saved.\n%s" % [_peinture.painted_cells().size(), where]
	_new_dialog.popup_centered()


func _nouveau_projet() -> void:
	await _show_then("New project", "starting again from a blank guide")
	_work_path = ""
	(%WorkHint as Label).text = "Nothing saved yet."
	_meta = {"poids": {}, "affectation": {}}
	_nouveau_carnet()
	_announce("New project: the guide is blank, and the pixel size can be chosen again.")


func _on_save_pressed() -> void:
	if _work_path != "":
		enregistrer(_work_path)
		return
	_save_dialog.current_file = "my_tileset.%s" % Travail.EXTENSION
	_save_dialog.popup_centered_ratio(0.6)


func enregistrer(path: String) -> void:
	await _show_then("Saving the work file", path.get_file())
	if Travail.sauver(_peinture, _meta, path) != OK:
		_announce("Could not save.")
		return
	_work_path = path
	_dirty = false
	(%WorkHint as Label).text = path.get_file()
	_announce("Saved to %s" % path.get_file())
	if _reset_after_save:
		_reset_after_save = false
		_nouveau_projet()


func ouvrir(path: String) -> void:
	await _show_then("Opening the work file", path.get_file())
	var d := Travail.relire(path)
	if d.is_empty():
		_announce("This file is not a MarchingSquares work file (.%s). Files from the old massif model do not open here." % Travail.EXTENSION)
		return
	var p: Painting = d.peinture
	if not RESOLUTIONS.has(p.resolution):
		_announce("This work is painted at %d x %d: this editor offers %s." % [p.resolution, p.resolution, str(RESOLUTIONS)])
		return
	for i in (%SizeChoice as OptionButton).item_count:
		if int((%SizeChoice as OptionButton).get_item_metadata(i)) == p.resolution:
			(%SizeChoice as OptionButton).select(i)
	_peinture = p
	_meta = d.meta
	_zone().adopt(_peinture, _meta, _guide, _guide_mat)
	_work_path = path
	_dirty = false
	(%WorkHint as Label).text = path.get_file()
	_refresh_counters()
	_zone().fit()
	_announce("%d images placed back." % _peinture.painted_cells().size())


func exporter(folder: String) -> void:
	await _show_then("Exporting the tileset", "sheet and manifest")
	var sortie := Travail.exporter(_peinture, _meta, folder)
	_announce("Exported to %s: %s and its manifest." % [folder.get_file(), String(sortie[0]).get_file()])


func installer(folder: String) -> void:
	await _show_then("Installing the plugin", "and something to paint with")
	var r := Installer.installer(folder, _peinture, _meta)
	_announce(String(r.dit).replace("\n", " "))
	(%PluginHint as Label).text = r.dit


func essai(folder: String) -> void:
	await _show_then("Writing the trial", "a tileset computed from the model")
	var sortie := Essai.ecrire(folder, _current_resolution())
	_announce("Trial written to %s: %s and its manifest." % [folder.get_file(), String(sortie[0]).get_file()])
	(%PluginHint as Label).text = "The trial is written. Give its manifest to a MarchingSquaresWorld node."


# ── le clavier ───────────────────────────────────────────────────────────────────────────────────────────────────────

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.ctrl_pressed:
		if key.keycode == KEY_S:
			_on_save_pressed()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_O:
			_open_dialog.popup_centered_ratio(0.6)
			get_viewport().set_input_as_handled()
		return
	if key.alt_pressed or key.meta_pressed:
		return
	if TOOL_KEYS.has(key.keycode):
		_choisir_outil(int(TOOL_KEYS[key.keycode]))
	elif key.keycode == KEY_S and _room == TEST:
		_choisir_outil(SCULPT)
	elif key.keycode == KEY_TAB:
		choisir_salle(TEST if _room == DRAW else DRAW)
	elif key.keycode == KEY_V:
		_variante(func() -> String: return _zone().nouvelle_variante(), true)
	elif key.keycode == KEY_C:
		_variante(func() -> String: return _zone().changer_variante(), true)
	elif key.keycode == KEY_X:
		_variante(func() -> String: return _zone().oter_variante(), true)
	elif key.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
		_variante(func() -> String: return _zone().regler_poids(1), false)
	elif key.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		_variante(func() -> String: return _zone().regler_poids(-1), false)
	elif key.keycode == KEY_BRACKETLEFT or key.keycode == KEY_BRACKETRIGHT:
		var tailles: Array[int] = _zone().BRUSH_SIZES
		var at := clampi(tailles.find(_zone().brush_size) + (1 if key.keycode == KEY_BRACKETRIGHT else -1), 0, tailles.size() - 1)
		_press_meta(%BrushRow, "size", tailles[at])
	else:
		return
	get_viewport().set_input_as_handled()


# ── les jauges ───────────────────────────────────────────────────────────────────────────────────────────────────────

func _refresh_counters() -> void:
	if _peinture == null:
		return
	var c := Travail.compte(_peinture)
	(%SurfaceLabel as Label).text = "Tops         %d / %d" % [c.dessus, c.total_dessus]
	(%SurfaceBar as ProgressBar).max_value = float(c.total_dessus)
	(%SurfaceBar as ProgressBar).value = float(c.dessus)
	(%WallLabel as Label).text = "Cliffs       %d / %d" % [c.falaises, c.total_falaises]
	(%WallBar as ProgressBar).max_value = float(c.total_falaises)
	(%WallBar as ProgressBar).value = float(c.falaises)
	var reste: int = int(c.total_dessus) + int(c.total_falaises) - int(c.dessus) - int(c.falaises)
	(%RemainingLabel as Label).text = "ready to export" if reste == 0 else "%d tiles left to paint" % reste
	(%ExportButton as Button).disabled = reste > 0
	(%ExportButton as Button).tooltip_text = "One sheet and its manifest, for the plugin." if reste == 0 \
			else "Refused while a base tile is left unpainted: a sheet with holes would show them in the game. The trial lets you try the plugin meanwhile."
	var mats := PackedStringArray()
	for m in range(1, Modele.MATIERES_MAXI):
		var k := 0
		for a: Dictionary in Archetypes.liste():
			if a.sorte == Modele.DESSUS and _peinture.is_painted(Vector2i(a.numero, m * 10)):
				k += 1
		if k > 0:
			mats.append("material %d: %d / %d" % [m, k, c.total_dessus])
	_materials_label.text = ", ".join(mats)
	_materials_label.visible = not mats.is_empty()
	(%SizeChoice as OptionButton).disabled = not _peinture.painted_cells().is_empty()


## Un relief au format texte : « colonnes rangées », puis une valeur par coin, une rangée par ligne.
static func lire_guide(chemin: String) -> Dictionary:
	var lignes := FileAccess.get_file_as_string(chemin).strip_edges().split("\n")
	var tete := lignes[0].strip_edges().split(" ")
	var colonnes := int(tete[0])
	var rangees := int(tete[1])
	var h := PackedInt32Array()
	for j in range(1, rangees + 2):
		for v: String in lignes[j].strip_edges().split(" "):
			h.append(int(v))
	return {"h": h, "colonnes": colonnes, "rangees": rangees}
