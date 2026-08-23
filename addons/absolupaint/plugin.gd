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
const Manifest := preload("res://addons/absolupaint/manifest.gd")

var _button: Button = null
var _dock: VBoxContainer = null
var _alert: AcceptDialog = null

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
	_dock.tileset_chosen.connect(_on_tileset_chosen)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	# ⚠ DIFFERE D'UNE IMAGE, ET CE N'EST PAS UNE PRECAUTION. Un greffon entre dans l'arbre
	# AVANT que l'editeur n'ait restaure la scene ouverte a la fermeture : la chercher
	# maintenant rendrait nul, et la liste resterait vide toute la session.
	_offer.call_deferred()
	scene_changed.connect(func(_root: Node) -> void: _offer())


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if _button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null
	if _alert != null:
		_alert.queue_free()
		_alert = null
	remove_custom_type(NODE_NAME)


# --- LE BOUTON DE LA BARRE DU HAUT ------------------------------------------

## Emmene l'acheteur au monde, et le cree s'il n'existe pas encore.
##
## ⚠ ON NE CREE JAMAIS UN SECOND MONDE EN SILENCE. Deux `AbsoluPaintWorld` dans la meme
## scene poseraient deux fois les memes tuiles, l'un sur l'autre : on chercherait longtemps
## pourquoi le monde parait juste mais se comporte mal. S'il y en a deja un, on y va.
func _on_pressed() -> void:
	# ⚠ LE BOUTON EMMENE AU PANNEAU, TOUJOURS. Il pose le monde, mais tout ce qui suit --
	# le tileset, l'etage, l'armement -- se passe dans le panneau : le laisser referme
	# reviendrait a livrer l'outil sans dire ou il est.
	_reveal_dock()
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		_complain("Aucune scene ouverte",
				"AbsoluPaint pose un monde DANS une scene.\n\n"
				+ "Ouvrez ou creez une scene, puis recliquez sur AbsoluPaint.")
		return
	var world: Node = _find_world(root)
	if world == null:
		world = _add_world(root)
	if world == null:
		return
	_select(world)
	_offer()


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
	var blocking: Array = _blocking()
	if not blocking.is_empty():
		_dock.disarm()
		_complain(String(blocking[0]), String(blocking[1]))
		return
	_select(_world())
	_say("Arme. Clic gauche pose, clic droit retire.")


## CE QUI MANQUE POUR PEINDRE, DIT EN TOUTES LETTRES : [titre, quoi faire].
##
## ⚠ UN REFUS MUET EST LE PIRE DES REFUS. Un bouton qui se releve tout seul sans rien dire
## laisse croire a une panne, et l'acheteur cherche la cause dans le mauvais endroit -- ou
## abandonne. Chaque condition dit donc CE QUI MANQUE et CE QU'IL FAUT FAIRE, dans cet
## ordre, et rien d'autre.
##
## ⚠ ET ON LES TESTE DANS L'ORDRE OU ON LES REMPLIT. Annoncer « aucun tileset » a
## quelqu'un qui n'a pas encore de scene ouverte l'enverrait resoudre le mauvais probleme.
func _blocking() -> Array:
	if EditorInterface.get_edited_scene_root() == null:
		return ["Aucune scene ouverte",
				"Le pinceau peint une scene.\n\n"
				+ "Ouvrez ou creez une scene, puis cliquez AbsoluPaint dans la barre du haut."]
	var world: Node = _world()
	if world == null:
		return ["Aucun monde dans cette scene",
				"Il faut un noeud AbsoluPaintWorld pour peindre.\n\n"
				+ "Cliquez le bouton AbsoluPaint de la barre du haut : il en pose un et vous "
				+ "y emmene."]
	if String(world.manifest_path).is_empty():
		if Manifest.discover().is_empty():
			return ["Aucun tileset dans ce projet",
					"Le pinceau pose des tuiles : il lui en faut.\n\n"
					+ "Dans AbsoluTiles, cliquez \u00ab Installer le plugin Godot \u00bb et ciblez CE "
					+ "projet. Le tileset part avec l'extension -- le votre s'il est complet, "
					+ "son essai sinon."]
		return ["Aucun tileset choisi",
				"Ce projet en contient plusieurs.\n\n"
				+ "Prenez-en un dans la liste \u00ab Tileset \u00bb du panneau AbsoluPaint."]
	if not String(world.last_error).is_empty():
		return ["Ce tileset ne se lit pas",
				"%s\n\nChoisissez-en un autre dans la liste, ou reexportez-le depuis "
				% String(world.last_error) + "AbsoluTiles."]
	return []


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
			# ⚠ LA SCENE PEUT AVOIR CHANGE DEPUIS L'ARMEMENT. Le pinceau resterait alors
			# arme et MUET -- on clique, rien ne se passe, et rien ne dit pourquoi. On
			# desarme franchement, en disant ce qui manque.
			var blocking: Array = _blocking()
			if not blocking.is_empty():
				_dock.disarm()
				_complain(String(blocking[0]), String(blocking[1]))
				return true
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


## PROPOSE LES TILESETS DU PROJET, ET EN PREND UN S'IL N'Y EN A QU'UN.
##
## ⚠ TOUT DOIT SE PASSER DANS LE PRODUIT. Demander a l'acheteur de pointer un fichier,
## c'est lui demander de savoir ce qu'il cherche, ou il est, et que ce soit lui : trois
## occasions d'abandonner avant d'avoir rien vu. Un tileset AbsoluTiles se reconnait a son
## nom, donc on le trouve.
##
## ⚠ ET ON NE CHOISIT A SA PLACE QUE QUAND IL N'Y A PAS DE CHOIX. Un seul tileset dans le
## projet : le doute n'existe pas, on le pose. Plusieurs : on montre celui du monde, ou le
## premier, et c'est lui qui tranche.
func _offer() -> void:
	if _dock == null:
		return
	var world: Node = _world()
	var found: PackedStringArray = Manifest.discover()
	var current: String = "" if world == null else String(world.manifest_path)
	_dock.fill_tilesets(found, current)
	if world == null:
		_say("Cliquez le bouton de la barre du haut pour poser un monde.")
		return
	if current.is_empty() and found.size() == 1:
		world.manifest_path = found[0]
		_say("Tileset trouve et pose : %s" % found[0].get_file())
		return
	if current.is_empty():
		_say("Aucun tileset trouve dans ce projet." if found.is_empty()
				else "Choisissez le tileset a peindre.")
		return
	_say("Monde pret. Armez le pinceau.")


func _on_tileset_chosen(path: String) -> void:
	var world: Node = _world()
	if world == null:
		_complain("Aucun monde dans cette scene",
				"Le tileset se pose sur un monde, et il n'y en a pas.\n\n"
				+ "Cliquez le bouton AbsoluPaint de la barre du haut : il en pose un.")
		return
	world.manifest_path = path
	if not String(world.last_error).is_empty():
		_complain("Ce tileset ne se lit pas", String(world.last_error))
		return
	_say("Tileset : %s" % path.get_file())


## ⚠ LE PANNEAU EST UN ONGLET, ET UN ONGLET QU'ON NE VOIT PAS N'EXISTE PAS. Godot range
## les greffons dans des piles a onglets : le notre peut tres bien etre derriere « Scene »
## ou « Importer » depuis l'ouverture du projet. On le met devant.
func _reveal_dock() -> void:
	if _dock == null:
		return
	var tabs: TabContainer = _dock.get_parent() as TabContainer
	if tabs != null:
		tabs.current_tab = _dock.get_index()


## Dit ce qui manque, en grand, et ce qu'il faut faire.
func _complain(title: String, what_to_do: String) -> void:
	_say(title)
	if _alert == null:
		_alert = AcceptDialog.new()
		_alert.ok_button_text = "Compris"
		EditorInterface.get_base_control().add_child(_alert)
	_alert.title = "AbsoluPaint \u2014 %s" % title
	_alert.dialog_text = what_to_do
	_alert.popup_centered()


func _say(message: String) -> void:
	if _dock != null:
		_dock.say(message)
