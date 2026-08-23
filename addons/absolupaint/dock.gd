# LE PANNEAU DU PINCEAU — choisir un etage, armer, peindre.
#
# ⚠ CE FICHIER NE SAIT RIEN DU MONDE. Il n'a ni relief, ni manifeste, ni noeud : il affiche
# des choix et les annonce. Le greffon fait le reste. Un panneau qui va chercher lui-meme
# la scene finit par en savoir plus que le greffon, et les deux se contredisent.
@tool
extends VBoxContainer

signal armed_changed(armed: bool)

## L'etage qu'on pose. `VOID` retire la case du monde.
const VOID: int = -1
const LEVELS: int = 10

var _arm: CheckButton = null
var _status: Label = null
var _group: ButtonGroup = null
var _chosen: int = 1


func _ready() -> void:
	if get_child_count() == 0:
		_build()


func _build() -> void:
	add_theme_constant_override("separation", 6)

	var title: Label = Label.new()
	title.text = "AbsoluPaint"
	title.add_theme_font_size_override("font_size", 15)
	add_child(title)

	var hint: Label = Label.new()
	hint.text = "Clic gauche pose l'etage choisi.\nClic droit retire la case du monde."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.65)
	add_child(hint)

	add_child(HSeparator.new())

	var caption: Label = Label.new()
	caption.text = "Etage"
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
	var nothing: Button = _level_button("Vide", VOID)
	nothing.tooltip_text = "Retire la case du monde. Ce n'est pas la plaine :\n" \
			+ "l'etage 0 est du sol, le vide est le bord du monde."
	row.add_child(nothing)

	add_child(HSeparator.new())

	# ⚠ UN BOUTON, PAS UN RACCOURCI, ET C'EST LA LECON DU PINCEAU DE SATYRON. Un pinceau qui
	# intercepte la souris sans qu'on l'ait demande fait perdre le glisser-deposer des noeuds,
	# et on met dix minutes a comprendre pourquoi l'editeur ne repond plus.
	_arm = CheckButton.new()
	_arm.text = "Armer le pinceau"
	_arm.tooltip_text = "Tant qu'il est arme, la souris peint la carte au lieu de\n" \
			+ "deplacer les noeuds."
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
