# ABSOLUPAINT — l'enregistrement du noeud, et rien d'autre.
#
# ⚠ UN EditorPlugin QUI FAIT DU TRAVAIL EST UN PIEGE. Tout ce qui compte -- la regle de
# pose, la lecture du manifeste, la fabrique du TileSet -- vit dans des fichiers qui ne
# connaissent ni l'editeur ni un noeud, donc qui se testent en headless. Ce fichier ne fait
# que declarer le type ; s'il grossit, c'est que quelque chose est au mauvais endroit.
@tool
extends EditorPlugin

const NODE_NAME: String = "AbsoluPaintWorld"
const WORLD_SCRIPT: String = "res://addons/absolupaint/world.gd"


func _enter_tree() -> void:
	add_custom_type(NODE_NAME, "Node2D", load(WORLD_SCRIPT), null)


func _exit_tree() -> void:
	remove_custom_type(NODE_NAME)
