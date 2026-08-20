# UNE SECTION D'OUTILS — un en-tete qui se replie, et ce qu'il contient.
#
# La barre de gauche en empilera autant qu'on voudra ; c'est le ScrollContainer qui absorbe
# le debordement. Ajouter un outil, c'est ajouter un enfant sous `Content/Items` dans
# l'editeur de scenes : rien a ecrire ici.
@tool
extends VBoxContainer

const OPEN_MARK: String = "▾  "
const SHUT_MARK: String = "▸  "

@export var title: String = "Section":
	set(value):
		title = value
		_apply()

@export var expanded: bool = true:
	set(value):
		expanded = value
		_apply()


func _ready() -> void:
	var header: Button = get_node_or_null("Header") as Button
	if header != null and not header.toggled.is_connected(_on_header_toggled):
		header.toggled.connect(_on_header_toggled)
	_apply()


func _on_header_toggled(pressed: bool) -> void:
	expanded = pressed


func _apply() -> void:
	var header: Button = get_node_or_null("Header") as Button
	if header != null:
		header.text = (OPEN_MARK if expanded else SHUT_MARK) + title
		header.button_pressed = expanded
	var content: Control = get_node_or_null("Content") as Control
	if content != null:
		content.visible = expanded
