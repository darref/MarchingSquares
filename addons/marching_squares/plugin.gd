@tool
extends EditorPlugin

## LE GREFFON MARCHING SQUARES — il déclare le nœud et transmet la souris ; il ne décide RIEN du relief (tout est dans
## `world.gd` et `modele.gd`, qui se testent sans éditeur). Sur un MarchingSquaresWorld sélectionné, dans la vue 2D :
## clic : monter le coin qui se voit ; clic droit : le descendre ; Maj + clic : y poser la matière du pinceau ;
## Maj + clic droit : l'ôter. Chaque clic se défait (Ctrl+Z). Un clic qui ferait se rencontrer deux plateaux en
## diagonale est REFUSÉ, et dit (comme dans l'éditeur).

const NOM := "MarchingSquaresWorld"

var _monde: Node2D = null


func _enter_tree() -> void:
	add_custom_type(NOM, "Node2D", preload("res://addons/marching_squares/world.gd"),
			preload("res://addons/marching_squares/icon.svg"))


func _exit_tree() -> void:
	remove_custom_type(NOM)


func _handles(objet: Object) -> bool:
	return objet is Node2D and (objet as Node2D).get_script() == preload("res://addons/marching_squares/world.gd")


func _edit(objet: Object) -> void:
	_monde = objet as Node2D


func _forward_canvas_gui_input(e: InputEvent) -> bool:
	var b := e as InputEventMouseButton
	if _monde == null or b == null or not b.pressed:
		return false
	if b.button_index != MOUSE_BUTTON_LEFT and b.button_index != MOUSE_BUTTON_RIGHT:
		return false
	var gauche := b.button_index == MOUSE_BUTTON_LEFT
	var local: Vector2 = _monde.get_local_mouse_position()
	var g: Dictionary = _monde.geste(local, 0 if b.shift_pressed else (1 if gauche else -1),
			(_monde.brush_material if gauche else 0) if b.shift_pressed else -1)
	if g.is_empty():
		if _monde.dernier_refus != "":
			push_warning("MarchingSquares: " + _monde.dernier_refus)
			return true
		return false
	var ur := get_undo_redo()
	ur.create_action("MarchingSquares: paint material" if b.shift_pressed else
			("MarchingSquares: raise corner" if gauche else "MarchingSquares: lower corner"))
	ur.add_do_property(_monde, "heights", g.heights)
	ur.add_undo_property(_monde, "heights", _monde.heights.duplicate())
	ur.add_do_property(_monde, "materials", g.materials)
	ur.add_undo_property(_monde, "materials", _monde.materials.duplicate())
	ur.commit_action()
	return true
