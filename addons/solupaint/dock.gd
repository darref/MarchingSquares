# LE PANNEAU DU PINCEAU — choisir un etage, armer, peindre.
#
# ⚠ CE FICHIER NE SAIT RIEN DU MONDE. Il n'a ni relief, ni manifeste, ni noeud : il affiche
# des choix et les annonce. Le greffon fait le reste. Un panneau qui va chercher lui-meme
# la scene finit par en savoir plus que le greffon, et les deux se contredisent.
@tool
extends VBoxContainer

signal armed_changed(armed: bool)
signal tileset_chosen(path: String)

## L'etage qu'on pose. `VOID` retire la case du monde.
const VOID: int = -1
const LEVELS: int = 10

var _arm: CheckButton = null
var _tileset: OptionButton = null
var _status: Label = null
var _group: ButtonGroup = null
var _chosen: int = 1


func _ready() -> void:
	if get_child_count() == 0:
		_build()


func _build() -> void:
	add_theme_constant_override("separation", 6)

	var title: Label = Label.new()
	title.text = "SoluPaint"
	title.add_theme_font_size_override("font_size", 15)
	add_child(title)

	var hint: Label = Label.new()
	hint.text = "Left click places the chosen level.\nRight click removes the cell from the world."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.65)
	add_child(hint)

	add_child(HSeparator.new())

	# ⚠ ON NE DEMANDE PAS CE QU'ON PEUT TROUVER. Pointer un manifeste a la main est le
	# genre de geste qui fait abandonner un outil : il faut savoir ce qu'on cherche, ou il
	# est, et que ce soit lui. Le greffon fouille le projet et propose ; s'il n'en trouve
	# qu'un, il le prend sans rien demander.
	var sheet: Label = Label.new()
	sheet.text = "Tileset"
	add_child(sheet)
	_tileset = OptionButton.new()
	_tileset.clip_text = true
	_tileset.tooltip_text = "The SoluTiles tilesets found in this project."
	_tileset.item_selected.connect(_on_tileset_selected)
	add_child(_tileset)

	add_child(HSeparator.new())

	var caption: Label = Label.new()
	caption.text = "Level"
	add_child(caption)

	# ⚠ DIX BOUTONS PLUTOT QU'UN COMPTEUR. Choisir l'etage EST le geste principal : le mettre
	# derriere une fleche a cliquer deux fois pour aller de 1 a 3 fait payer a chaque coup ce
	# qui doit se prendre d'un regard.
	var row: HFlowContainer = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 2)
	row.add_theme_constant_override("v_separation", 2)
	add_child(row)
	_group = ButtonGroup.new()
	for level: int in range(LEVELS):
		row.add_child(_level_button(str(level), level))
	# ⚠ LE VIDE EST UN CHOIX, PAS UNE ABSENCE DE CHOIX. L'etage 0 est du SOL -- il porte une
	# tuile, et une falaise la ou il borde le vide. Retirer une case est un autre geste.
	var nothing: Button = _level_button("Void", VOID)
	nothing.tooltip_text = "Removes the cell from the world. This is not the plain:\n" \
			+ "level 0 is ground, void is the world's edge."
	row.add_child(nothing)

	add_child(HSeparator.new())

	# ⚠ UN BOUTON, PAS UN RACCOURCI, ET C'EST LA LECON DU PINCEAU DE SATYRON. Un pinceau qui
	# intercepte la souris sans qu'on l'ait demande fait perdre le glisser-deposer des noeuds,
	# et on met dix minutes a comprendre pourquoi l'editeur ne repond plus.
	_arm = CheckButton.new()
	_arm.text = "Arm the brush"
	_arm.tooltip_text = "While it is armed, the mouse paints the map instead of\n" \
			+ "moving nodes."
	_arm.toggled.connect(_on_armed)
	add_child(_arm)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 11)
	_status.modulate = Color(1, 1, 1, 0.65)
	add_child(_status)


func _level_button(text: String, level: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = _group
	button.custom_minimum_size = Vector2(30, 0)
	button.button_pressed = level == _chosen
	button.pressed.connect(func() -> void: _chosen = level)
	return button


func _on_armed(pressed: bool) -> void:
	armed_changed.emit(pressed)


func is_armed() -> bool:
	return _arm != null and _arm.button_pressed


func disarm() -> void:
	if _arm != null:
		_arm.set_pressed_no_signal(false)


func chosen_level() -> int:
	return _chosen


func say(message: String) -> void:
	if _status != null:
		_status.text = message


## Remplit la liste des tilesets trouves, et retient celui qui est en place.
##
## ⚠ SANS RIEN CHOISIR A LA PLACE DE L'ACHETEUR QUAND IL Y A UN DOUTE. Un seul tileset :
## on le prend. Plusieurs : on montre celui du monde, ou le premier, et il tranche.
func fill_tilesets(paths: PackedStringArray, current: String) -> void:
	if _tileset == null:
		return
	_tileset.clear()
	if paths.is_empty():
		_tileset.add_item("no tileset found")
		_tileset.disabled = true
		return
	_tileset.disabled = false
	var chosen: int = 0
	for index: int in range(paths.size()):
		_tileset.add_item(_short(paths[index]))
		_tileset.set_item_metadata(index, paths[index])
		if paths[index] == current:
			chosen = index
	_tileset.select(chosen)


func chosen_tileset() -> String:
	if _tileset == null or _tileset.disabled or _tileset.item_count == 0:
		return ""
	return String(_tileset.get_item_metadata(_tileset.selected))


func _on_tileset_selected(index: int) -> void:
	tileset_chosen.emit(String(_tileset.get_item_metadata(index)))


func _short(path: String) -> String:
	var name: String = path.get_file().trim_suffix("_tileset.txt")
	var folder: String = path.get_base_dir().get_file()
	return name if folder.is_empty() else "%s  (%s)" % [name, folder]
