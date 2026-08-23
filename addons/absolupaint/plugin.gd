# ABSOLUPAINT — l'enregistrement du noeud, le bouton qui le trouve, et le pinceau.
#
# ⚠ UN EditorPlugin QUI FAIT DU TRAVAIL EST UN PIEGE. Tout ce qui compte -- la regle de
# pose, la lecture du manifeste, la fabrique du TileSet -- vit dans des fichiers qui ne
# connaissent ni l'editeur ni un noeud, donc qui se testent en headless. Ce fichier ne fait
# que declarer le type, poser un bouton, et transmettre la souris ; s'il se met a decider
# quoi que ce soit du relief, c'est que quelque chose est au mauvais endroit.
#
# ⚠ ET LE BOUTON N'EST PAS UNE COQUETTERIE. Une extension qu'on coche et qui ne montre RIEN
# oblige a savoir d'avance qu'il faut ajouter un noeud, et lequel. C'est une des premieres
# causes d'abandon d'un outil : on ne le trouve pas, donc on croit qu'il ne marche pas.
@tool
extends EditorPlugin

const NODE_NAME: String = "AbsoluPaintWorld"
const WORLD_SCRIPT: String = "res://addons/absolupaint/world.gd"
const ICON: String = "res://addons/absolupaint/icon.svg"
const DOCK := preload("res://addons/absolupaint/dock.gd")

var _button: Button = null
var _dock: VBoxContainer = null

## Les cases du trait en cours, sans doublon. Vide hors trait.
var _stroke: Dictionary = {}
## Le relief tel qu'il etait avant le trait : c'est lui que l'annulation remet.
var _before: Dictionary = {}
var _erasing: bool = false
var _last_cell: Vector2i = Vector2i.ZERO
var _has_last: bool = false


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

	_dock = DOCK.new()
	_dock.name = "AbsoluPaint"
	_dock.armed_changed.connect(_on_armed)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if _button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null
	remove_custom_type(NODE_NAME)


# --- LE BOUTON DE LA BARRE DU HAUT ------------------------------------------

## Emmene l'acheteur au monde, et le cree s'il n'existe pas encore.
##
## ⚠ ON NE CREE JAMAIS UN SECOND MONDE EN SILENCE. Deux `AbsoluPaintWorld` dans la meme
## scene poseraient deux fois les memes tuiles, l'un sur l'autre : on chercherait longtemps
## pourquoi le monde parait juste mais se comporte mal. S'il y en a deja un, on y va.
func _on_pressed() -> void:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		_say("Ouvrez d'abord une scene.")
		return
	var world: Node = _find_world(root)
	if world == null:
		world = _add_world(root)
	if world == null:
		return
	_select(world)
	_say("Monde pret. Pointez son manifeste, puis armez le pinceau.")


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


# --- LE PINCEAU -------------------------------------------------------------

## ⚠ ON SELECTIONNE LE MONDE EN S'ARMANT. `_forward_canvas_gui_input` n'est appele que si
## `_handles` a dit oui de l'objet SELECTIONNE : sans selection, le pinceau serait arme et
## MUET -- le mode de panne le plus deroutant qu'un outil d'editeur puisse avoir.
func _on_armed(armed: bool) -> void:
	if not armed:
		_say("")
		return
	var world: Node = _world()
	if world == null:
		_dock.disarm()
		_say("Aucun monde AbsoluPaint dans la scene. Cliquez le bouton de la barre du haut.")
		return
	_select(world)
	_say("Arme. Clic gauche pose, clic droit retire.")


func _handles(object: Object) -> bool:
	return _dock != null and _dock.is_armed() and _world() != null and object is Node


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _dock == null or not _dock.is_armed():
		return false
	var world: Node = _world()
	if world == null:
		return false

	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.button_index != MOUSE_BUTTON_LEFT \
				and click.button_index != MOUSE_BUTTON_RIGHT:
			return false
		if click.pressed:
			_stroke.clear()
			_before = (world.heights as Dictionary).duplicate()
			# ⚠ LE BOUTON DROIT RETIRE TOUJOURS, quel que soit l'etage choisi. C'est le geste
			# de retouche -- reprendre un bord sans changer de reglage.
			_erasing = click.button_index == MOUSE_BUTTON_RIGHT
			_has_last = false
			_gather(world, click.position)
		else:
			_commit(world)
		return true

	if event is InputEventMouseMotion and not _stroke.is_empty():
		_gather(world, (event as InputEventMouseMotion).position)
		return true
	return false


## Ajoute au trait la case sous le curseur, et celles que le glisse a sautees.
##
## ⚠ ON COMBLE LA LIGNE. Une souris rapide ne rapporte qu'une position tous les cinq ou six
## pixels : sans ce remplissage, un trait franc laisse des trous tous les deux centimetres.
func _gather(world: Node, at: Vector2) -> void:
	var xform: Transform2D = (world as Node2D).get_viewport_transform() \
			* (world as Node2D).get_global_transform()
	var cell: Vector2i = world.cell_at(xform.affine_inverse() * at)
	var fresh: Array[Vector2i] = []
	if _has_last and _last_cell != cell:
		for step: Vector2i in _line(_last_cell, cell):
			if not _stroke.has(step):
				_stroke[step] = true
				fresh.append(step)
	if not _stroke.has(cell):
		_stroke[cell] = true
		fresh.append(cell)
	_last_cell = cell
	_has_last = true
	if fresh.is_empty():
		return
	# On pose tout de suite : un pinceau qui ne montre rien avant le relachement se peint a
	# l'aveugle. Mais on ne repose QUE la zone que le changement a pu rendre fausse -- refaire
	# la carte entiere par case peinte coute 456 ms sur 256x192, et le pinceau devient
	# inutilisable des qu'un monde grandit.
	var level: int = _dock.chosen_level()
	var changes: Dictionary = {}
	for step: Vector2i in fresh:
		changes[step] = -1 if (_erasing or level < 0) else level
	world.apply(changes)


## ⚠ L'ANNULATION SE POSE AU RELACHEMENT, ET D'UN SEUL BLOC. Une action par case ferait
## defaire un trait de cent cases en cent Ctrl+Z -- ce que personne n'attend d'un pinceau.
func _commit(world: Node) -> void:
	if _stroke.is_empty():
		return
	var painted: int = _stroke.size()
	_stroke.clear()
	_has_last = false
	var after: Dictionary = (world.heights as Dictionary).duplicate()
	var history: EditorUndoRedoManager = get_undo_redo()
	history.create_action("Peindre le relief (%d cases)" % painted)
	history.add_do_property(world, "heights", after)
	history.add_undo_property(world, "heights", _before)
	history.commit_action(false)
	_say("%d cases posees." % painted)


## Bresenham entier. ⚠ AVEC UNE BORNE : il tourne dans l'EDITEUR, et une boucle infinie y
## fige tout sans qu'on puisse meme enregistrer. Le prix d'un compteur est nul.
func _line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var span: Vector2i = Vector2i(absi(to.x - from.x), -absi(to.y - from.y))
	var step: Vector2i = Vector2i(1 if from.x < to.x else -1, 1 if from.y < to.y else -1)
	var error: int = span.x + span.y
	var at: Vector2i = from
	var guard: int = absi(to.x - from.x) + absi(to.y - from.y) + 2
	while at != to and guard > 0:
		guard -= 1
		var doubled: int = error * 2
		if doubled >= span.y:
			error += span.y
			at.x += step.x
		if doubled <= span.x:
			error += span.x
			at.y += step.y
		out.append(at)
	return out


func _world() -> Node:
	var root: Node = EditorInterface.get_edited_scene_root()
	return null if root == null else _find_world(root)


func _select(node: Node) -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	EditorInterface.edit_node(node)


func _say(message: String) -> void:
	if _dock != null:
		_dock.say(message)
