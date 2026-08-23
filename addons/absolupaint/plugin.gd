# ABSOLUPAINT — l'enregistrement du noeud, et le bouton qui le trouve pour vous.
#
# ⚠ UN EditorPlugin QUI FAIT DU TRAVAIL EST UN PIEGE. Tout ce qui compte -- la regle de
# pose, la lecture du manifeste, la fabrique du TileSet -- vit dans des fichiers qui ne
# connaissent ni l'editeur ni un noeud, donc qui se testent en headless. Ce fichier ne fait
# que declarer le type et poser un bouton ; s'il grossit, c'est que quelque chose est au
# mauvais endroit.
#
# ⚠ ET LE BOUTON N'EST PAS UNE COQUETTERIE. Une extension qu'on coche et qui ne montre RIEN
# oblige a savoir d'avance qu'il faut ajouter un noeud, et lequel. C'est une des premieres
# causes d'abandon d'un outil : on ne le trouve pas, donc on croit qu'il ne marche pas.
# Le bouton se voit dans la barre du haut des la premiere seconde, et il fait le seul geste
# que l'acheteur ne peut pas deviner -- poser le monde dans la scene ouverte.
@tool
extends EditorPlugin

const NODE_NAME: String = "AbsoluPaintWorld"
const WORLD_SCRIPT: String = "res://addons/absolupaint/world.gd"
const ICON: String = "res://addons/absolupaint/icon.svg"

var _button: Button = null


func _enter_tree() -> void:
	var icon: Texture2D = load(ICON) as Texture2D
	add_custom_type(NODE_NAME, "Node2D", load(WORLD_SCRIPT), icon)

	_button = Button.new()
	_button.text = "AbsoluPaint"
	_button.icon = icon
	_button.flat = true
	_button.tooltip_text = "Pose un monde AbsoluPaint dans la scene ouverte, et le\n" \
			+ "selectionne. S'il y en a deja un, il vous y emmene."
	_button.pressed.connect(_on_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _button)


func _exit_tree() -> void:
	if _button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null
	remove_custom_type(NODE_NAME)


## Emmene l'acheteur au monde, et le cree s'il n'existe pas encore.
##
## ⚠ ON NE CREE JAMAIS UN SECOND MONDE EN SILENCE. Deux `AbsoluPaintWorld` dans la meme
## scene poseraient deux fois les memes tuiles, l'un sur l'autre : on chercherait longtemps
## pourquoi le monde parait juste mais se comporte mal. S'il y en a deja un, on y va.
func _on_pressed() -> void:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		push_warning("AbsoluPaint : ouvrez d'abord une scene.")
		return
	var world: Node = _find_world(root)
	if world == null:
		world = _add_world(root)
	if world == null:
		return
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(world)
	EditorInterface.edit_node(world)


func _find_world(from: Node) -> Node:
	if from.get_script() == load(WORLD_SCRIPT):
		return from
	for child: Node in from.get_children():
		var found: Node = _find_world(child)
		if found != null:
			return found
	return null


## ⚠ ON PASSE PAR L'ANNULATION DE L'EDITEUR, PAS PAR add_child(). Un noeud pose sans elle
## ne se defait pas au Ctrl+Z, et l'acheteur se retrouve avec un noeud qu'il n'arrive pas a
## retirer par le geste qu'il emploie partout ailleurs.
func _add_world(root: Node) -> Node:
	var world: Node = (load(WORLD_SCRIPT) as GDScript).new()
	world.name = NODE_NAME
	var history: EditorUndoRedoManager = get_undo_redo()
	history.create_action("Ajouter un monde AbsoluPaint")
	history.add_do_method(root, "add_child", world)
	history.add_do_property(world, "owner", root)
	history.add_do_reference(world)
	history.add_undo_method(root, "remove_child", world)
	history.commit_action()
	return world
