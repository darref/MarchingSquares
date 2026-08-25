# SOLUPAINT — l'enregistrement du noeud, le bouton qui le trouve, et le pinceau.
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

const NODE_NAME: String = "SoluPaintWorld"

## Le nom du panneau, qui est aussi le titre de son onglet.
const DOCK_TITLE: String = "SoluPaint"
const WORLD_SCRIPT: String = "res://addons/solupaint/world.gd"
const ICON: String = "res://addons/solupaint/icon.svg"
const DOCK := preload("res://addons/solupaint/dock.gd")
const Manifest := preload("res://addons/solupaint/manifest.gd")
const Rules := preload("res://addons/solupaint/rules.gd")

var _button: Button = null
var _dock: VBoxContainer = null
var _alert: AcceptDialog = null

## Les cases du trait en cours, sans doublon. Vide hors trait.
var _stroke: Dictionary = {}
## Tampons refuses pendant le trait en cours -- dits au relachement, jamais tus.
var _refused: int = 0
## Le contre-geste du trait : la valeur d'AVANT de chaque case changee, premiere touche.
var _undo_delta: Dictionary = {}
## Le geste net du trait : la valeur FINALE de chaque case reellement changee.
var _redo_delta: Dictionary = {}
var _erasing: bool = false
var _last_cell: Vector2i = Vector2i.ZERO
var _has_last: bool = false


func _enter_tree() -> void:
	var icon: Texture2D = load(ICON) as Texture2D
	add_custom_type(NODE_NAME, "Node2D", load(WORLD_SCRIPT), icon)

	_button = Button.new()
	_button.text = "SoluPaint"
	_button.icon = icon
	_button.flat = true
	_button.tooltip_text = "Pose un monde SoluPaint dans la scene ouverte, et le\n" \
			+ "selectionne. S'il y en a deja un, il vous y emmene."
	_button.pressed.connect(_on_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _button)

	_install_dock()
	# ⚠ DIFFERE D'UNE IMAGE, ET CE N'EST PAS UNE PRECAUTION. Un greffon entre dans l'arbre
	# AVANT que l'editeur n'ait restaure la scene ouverte a la fermeture : la chercher
	# maintenant rendrait nul, et la liste resterait vide toute la session.
	_offer.call_deferred()
	scene_changed.connect(func(_root: Node) -> void: _offer())


## Cree le panneau et le range dans sa pile.
func _install_dock() -> void:
	_dock = DOCK.new()
	_dock.name = DOCK_TITLE
	_dock.armed_changed.connect(_on_armed)
	_dock.tileset_chosen.connect(_on_tileset_chosen)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
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
## ⚠ ON NE CREE JAMAIS UN SECOND MONDE EN SILENCE. Deux `SoluPaintWorld` dans la meme
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
				"SoluPaint pose un monde DANS une scene.\n\n"
				+ "Ouvrez ou creez une scene, puis recliquez sur SoluPaint.")
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
	history.create_action("Ajouter un monde SoluPaint")
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
				+ "Ouvrez ou creez une scene, puis cliquez SoluPaint dans la barre du haut."]
	var world: Node = _world()
	if world == null:
		return ["Aucun monde dans cette scene",
				"Il faut un noeud SoluPaintWorld pour peindre.\n\n"
				+ "Cliquez le bouton SoluPaint de la barre du haut : il en pose un et vous "
				+ "y emmene."]
	if String(world.manifest_path).is_empty():
		if Manifest.discover().is_empty():
			return ["Aucun tileset dans ce projet",
					"Le pinceau pose des tuiles : il lui en faut.\n\n"
					+ "Dans SoluTiles, cliquez \u00ab Installer le plugin Godot \u00bb et ciblez CE "
					+ "projet. Le tileset part avec l'extension -- le votre s'il est complet, "
					+ "son essai sinon."]
		return ["Aucun tileset choisi",
				"Ce projet en contient plusieurs.\n\n"
				+ "Prenez-en un dans la liste \u00ab Tileset \u00bb du panneau SoluPaint."]
	if not String(world.last_error).is_empty():
		return ["Ce tileset ne se lit pas",
				"%s\n\nChoisissez-en un autre dans la liste, ou reexportez-le depuis "
				% String(world.last_error) + "SoluTiles."]
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
			# ⚠ ON N'EMPORTE PLUS LA CARTE ENTIERE. Photographier `heights` au clic puis au
			# relachement coutait deux copies completes par trait -- 3,4 ms chacune a
			# 200x150, et autant de memoire d'historique -- pour n'en rejouer que quelques
			# cases. `apply()` rend le contre-geste : l'annulation n'enregistre que le trait.
			_undo_delta = {}
			_redo_delta = {}
			# ⚠ LE BOUTON DROIT RETIRE TOUJOURS, quel que soit l'etage choisi. C'est le geste
			# de retouche -- reprendre un bord sans changer de reglage.
			_erasing = click.button_index == MOUSE_BUTTON_RIGHT
			_has_last = false
			_refused = 0
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
	# ⚠ LE PINCEAU EPAIS POSE DES TAMPONS 3x3 -- bord + centre + bord. Une bande de moins --
	# le mode l'interdit -- et un pinceau qui refuserait chaque premier coup de crayon
	# serait inutilisable. Le tampon n'est jamais fin par lui-meme ; le controle
	# d'epaisseur garde le reste : trous d'une case, ponts, tranchees. Un tampon qui en
	# creerait un est REFUSE en entier, et le trait le dit au relachement.
	var staged: Dictionary = {}
	var wanted: int = -1 if (_erasing or level < 0) else level
	for step: Vector2i in fresh:
		var stamp: Array[Vector2i] = []
		for dy: int in range(3):
			for dx: int in range(3):
				stamp.append(step + Vector2i(dx, dy))
		if Rules.stamp_creates_thin(world.get("heights"), staged, stamp, wanted):
			_refused += 1
			continue
		for spot: Vector2i in stamp:
			changes[spot] = wanted
	if changes.is_empty():
		return
	var inverse: Dictionary = world.apply(changes)
	# Premiere touche gagne cote annulation, geste final cote refaire : l'aller-retour est
	# exact, et une case que le trait n'a pas vraiment changee n'entre dans aucun des deux.
	_undo_delta.merge(inverse)
	for changed: Vector2i in inverse.keys():
		_redo_delta[changed] = changes[changed]


## ⚠ L'ANNULATION SE POSE AU RELACHEMENT, ET D'UN SEUL BLOC. Une action par case ferait
## defaire un trait de cent cases en cent Ctrl+Z -- ce que personne n'attend d'un pinceau.
##
## ⚠ ET ELLE REJOUE DES GESTES, PAS DES CARTES. `add_do_property(heights)` stockait DEUX
## reliefs entiers par trait dans l'historique, et chaque Ctrl+Z repayait un releve
## complet par le setter. Les deux dictionnaires du trait suffisent : `apply()` les
## rejoue par la zone, dans les deux sens, et l'historique pese le trait -- pas le monde.
func _commit(world: Node) -> void:
	if _stroke.is_empty():
		return
	_stroke.clear()
	_has_last = false
	# Un trait qui n'a rien change -- repasse sur ses propres valeurs -- ne merite pas une
	# entree d'historique : un Ctrl+Z qui « defait » sans rien defaire desoriente.
	if _redo_delta.is_empty():
		_undo_delta = {}
		_say("Rien a changer : ces cases portaient deja cet etage.")
		return
	var history: EditorUndoRedoManager = get_undo_redo()
	history.create_action("Peindre le relief (%d cases)" % _redo_delta.size())
	history.add_do_method(world, "apply", _redo_delta.duplicate())
	history.add_undo_method(world, "apply", _undo_delta.duplicate())
	history.commit_action(false)
	if _refused > 0:
		# ⚠ UN REFUS MUET EST LE PIRE DES REFUS : on dit ce qui a ete refuse, et pourquoi.
		_say("%d cases posees, %d tampon(s) refuses : un relief d'une tuile d'epaisseur n'a pas de tuiles."
				% [_redo_delta.size(), _refused])
	else:
		_say("%d cases posees." % _redo_delta.size())
	_undo_delta = {}
	_redo_delta = {}


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
## occasions d'abandonner avant d'avoir rien vu. Un tileset SoluTiles se reconnait a son
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
				+ "Cliquez le bouton SoluPaint de la barre du haut : il en pose un.")
		return
	world.manifest_path = path
	if not String(world.last_error).is_empty():
		_complain("Ce tileset ne se lit pas", String(world.last_error))
		return
	_say("Tileset : %s" % path.get_file())


## ⚠ LE PANNEAU EST UN ONGLET, ET UN ONGLET QU'ON NE VOIT PAS N'EXISTE PAS. Godot range
## les greffons dans des piles a onglets : le notre peut tres bien etre derriere « Scene »
## ou « Importer » depuis l'ouverture du projet. On le met devant.
##
## ⚠ CE N'EST PAS NOTRE NOEUD QUI EST L'ONGLET. `add_control_to_dock` l'EMBALLE dans un
## `EditorDock`, et c'est celui-la que la pile connait -- releve dans un vrai editeur :
##
##     SoluPaint (VBoxContainer) <- @EditorDock@ <- DockSlotRightUL (TabContainer)
##
## Chercher un TabContainer comme parent DIRECT ne trouvait donc rien, et la fonction ne
## faisait rien du tout, sans une erreur. On remonte jusqu'a trouver la pile, et on lui
## demande l'index de l'enfant qu'elle connait -- jamais `get_index()`, qui compterait aussi
## ce qui n'est pas un onglet.
##
## ⚠ ON CHERCHE L'ONGLET PAR SON NOM, ET C'EST CE QUI REND LA CHOSE SURE. Remonter les
## parents depuis notre controle marche -- une fois qu'on a compris que Godot l'EMBALLE dans
## un `EditorDock` -- mais ca depend de la facon dont il l'emballe, c'est-a-dire d'un detail
## interne qui peut changer d'une version a l'autre. Le NOM, lui, est le notre : il n'y a
## qu'un onglet au monde qui puisse s'appeler SoluPaint.
##
## ⚠ ET CA TIENT QUEL QUE SOIT L'ETAT DU PROJET DE L'ACHETEUR. Le panneau deplace dans une
## autre pile -- en bas, a gauche -- se retrouve pareil, puisqu'on ne suppose rien de la pile
## ou il est. Detache en fenetre flottante, il n'y a plus de pile du tout : c'est une
## fenetre, on la met devant. Et s'il reste introuvable, on le DIT plutot que de laisser un
## bouton sans effet.
func _reveal_dock() -> bool:
	# ⚠ S'IL A ETE FERME A LA MAIN, ON LE REPOSE. C'est plus simple, plus sur et plus court
	# que d'expliquer a l'acheteur ou le retrouver dans les menus de son editeur -- et ca
	# marche aussi s'il a ete detruit, pas seulement referme.
	if not is_instance_valid(_dock):
		_dock = null
	if _dock == null:
		_install_dock()
	if _select_tab_named(EditorInterface.get_base_control(), DOCK_TITLE):
		return true
	# ⚠ ET UN FILET, PARCE QUE LE TITRE EST POSE PAR L'EDITEUR, PAS PAR NOUS. C'est lui qui
	# le met en rangeant le panneau ; si une version le nommait autrement, la recherche par
	# nom ne trouverait rien. On remonte alors jusqu'a la pile qui contient notre controle --
	# quelle qu'elle soit -- en se souvenant que ce n'est pas lui l'onglet mais l'`EditorDock`
	# qui l'emballe.
	var node: Node = _dock
	while node != null:
		var tabs: TabContainer = node.get_parent() as TabContainer
		if tabs != null:
			var tab: int = tabs.get_tab_idx_from_control(node as Control)
			if tab >= 0:
				tabs.current_tab = tab
				return true
			break
		node = node.get_parent()
	var window: Window = _dock.get_window()
	if window != null and window != EditorInterface.get_base_control().get_window():
		window.grab_focus()
		return true
	# ⚠ INTROUVABLE VEUT DIRE FERME, ET ON LE RECREE A NEUF. On ne cherche pas a savoir
	# comment ni pourquoi : expliquer a l'acheteur ou le retrouver dans les menus de son
	# editeur serait plus long a lire qu'a refaire.
	#
	# ⚠ A NEUF, ET PAS LE MEME REPOSE. Mesure : apres `remove_control_from_docks`, rendre le
	# MEME controle a `add_control_to_dock` recree bien un onglet -- mais le controle, lui,
	# ne rentre jamais dans l'arbre, ni a l'image suivante. On aurait donc un onglet vide et
	# un panneau fantome. Une instance neuve, elle, se pose.
	#
	# ⚠ Elle repart de ses valeurs par defaut, et c'est sans consequence : `_offer` refait
	# aussitot la liste des tilesets, et l'etage se rechoisit d'un clic.
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null
	_install_dock()
	return _select_tab_named(EditorInterface.get_base_control(), DOCK_TITLE)


static func _select_tab_named(from: Node, title: String) -> bool:
	var tabs: TabContainer = from as TabContainer
	if tabs != null:
		for tab: int in range(tabs.get_tab_count()):
			if tabs.get_tab_title(tab) == title:
				tabs.current_tab = tab
				return true
	for child: Node in from.get_children():
		if _select_tab_named(child, title):
			return true
	return false


## Dit ce qui manque, en grand, et ce qu'il faut faire.
func _complain(title: String, what_to_do: String) -> void:
	_say(title)
	if _alert == null:
		_alert = AcceptDialog.new()
		_alert.ok_button_text = "Compris"
		EditorInterface.get_base_control().add_child(_alert)
	_alert.title = "SoluPaint \u2014 %s" % title
	_alert.dialog_text = what_to_do
	_alert.popup_centered()


func _say(message: String) -> void:
	if _dock != null:
		_dock.say(message)
