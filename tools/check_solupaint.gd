# LE BANC D'SOLUPAINT — ce que la suite ne peut pas monter : un vrai noeud, dans un arbre.
#
# ⚠ CE QUI EST DANS LA SUITE N'EST PAS ICI. `tests/run.gd` compare deja la regle du plugin a
# celle du noyau, pose pour pose, sur des reliefs exhaustifs et sur le guide livre. Ce banc-la
# eprouve ce qu'une suite headless ne monte pas : le NOEUD -- ses couches, son setter, son
# contre-geste. Chaque point a existe comme defaut.
#
#   - un monde qui GRANDIT par le setter `heights` retaille ses couches. Avant, seul `_reload`
#     les taillait, et les etages au-dessus n'etaient simplement pas poses : des sommets
#     absents, sans une erreur ;
#   - `apply()` rend le CONTRE-GESTE, et le rejouer restaure le monde a la tuile pres. C'est
#     ce que l'annulation du pinceau enregistre : deux dictionnaires, pas deux cartes ;
#   - une couche qu'on pose sans la nettoyer est une FUITE : retirer un plateau doit retirer
#     sa falaise, pas la laisser sous le sol.
#
#     godot --headless --path . --script res://tools/check_solupaint.gd
extends SceneTree

const WorldScript := preload("res://addons/solupaint/world.gd")
const Rules := preload("res://addons/solupaint/rules.gd")
const MassifTrial := preload("res://exporters/massif_trial.gd")

const FOLDER: String = "user://solupaint_check"

var _checks: int = 0
var _failures: PackedStringArray = PackedStringArray()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)
	print("  %s  %s" % ["OK   " if ok else "ECHEC", label])


func _initialize() -> void:
	var report: Dictionary = MassifTrial.write(FOLDER)
	if String(report["error"]) != "":
		push_error("banc : l'essai n'a pas pu s'ecrire (%s)." % String(report["error"]))
		quit(1)
		return
	var manifest: String = ""
	for path: String in report["written"]:
		if path.ends_with("_tileset.txt"):
			manifest = path

	_layers_follow_growth(manifest)
	_apply_gives_back_the_gesture(manifest)
	_no_leak_when_a_plateau_goes(manifest)

	print("")
	print("%d verifications, %d echec(s)" % [_checks, _failures.size()])
	for said: String in _failures:
		print("  - %s" % said)
	quit(0 if _failures.is_empty() else 1)


func _world(manifest: String, heights: Dictionary) -> Node2D:
	var world: Node2D = WorldScript.new()
	world.set("heights", heights)
	world.set("manifest_path", manifest)
	root.add_child(world)
	return world


## Un plat de trois par trois, epais par construction : le plus petit monde legal.
func _flat(from: Vector2i, to: Vector2i, level: int, into: Dictionary) -> Dictionary:
	for y: int in range(from.y, to.y + 1):
		for x: int in range(from.x, to.x + 1):
			into[Vector2i(x, y)] = level
	return into


func _placed(world: Node2D) -> int:
	var many: int = 0
	for child: Node in world.get_children():
		if child is TileMapLayer:
			many += (child as TileMapLayer).get_used_cells().size()
	return many


## ⚠ LES COUCHES SUIVENT LE MONDE. Un monde qui grandit par le setter gardait ses couches
## d'avant : les etages au-dessus n'etaient pas poses, et rien ne le disait.
func _layers_follow_growth(manifest: String) -> void:
	print("les couches suivent le monde qui grandit")
	var world: Node2D = _world(manifest, _flat(Vector2i(0, 0), Vector2i(11, 11), 0, {}))
	_check(String(world.get("last_error")) == "",
			"le monde lit l'essai : %s" % String(world.get("last_error")))
	var flat: int = _placed(world)
	_check(flat > 0, "un plat de douze sur douze pose quelque chose (%d tuiles)" % flat)

	var taller: Dictionary = _flat(Vector2i(0, 0), Vector2i(11, 11), 0, {})
	_flat(Vector2i(3, 3), Vector2i(8, 8), 1, taller)
	_flat(Vector2i(4, 4), Vector2i(7, 7), 2, taller)
	world.set("heights", taller)
	var layers: int = 0
	for child: Node in world.get_children():
		if child is TileMapLayer:
			layers += 1
	_check(layers >= 3, "trois etages : trois couches au moins (%d)" % layers)
	_check(_placed(world) > flat, "et le monde porte plus de tuiles qu'avant")
	_check(String(world.get("last_warning")) == "",
			"sans une seule pose perdue : %s" % String(world.get("last_warning")))
	world.queue_free()


## ⚠ L'ANNULATION REJOUE DES GESTES, PAS DES CARTES. `apply()` rend la valeur d'AVANT de
## chaque case reellement changee ; la rejouer doit restaurer le monde a la tuile pres.
func _apply_gives_back_the_gesture(manifest: String) -> void:
	print("apply() rend le contre-geste, et il est exact")
	var start: Dictionary = _flat(Vector2i(0, 0), Vector2i(11, 11), 0, {})
	var world: Node2D = _world(manifest, start.duplicate())
	var before: Dictionary = _snapshot(world)

	var stroke: Dictionary = {}
	_flat(Vector2i(4, 4), Vector2i(6, 6), 1, stroke)
	var back: Dictionary = world.call("apply", stroke)
	_check(back.size() == 9, "neuf cases changees, neuf a defaire (%d)" % back.size())
	var after: Dictionary = _snapshot(world)
	_check(after != before, "le monde a bien change")

	world.call("apply", back)
	_check(_snapshot(world) == before,
			"et le contre-geste le restaure A LA TUILE PRES")

	# Repasser la meme valeur ne coute rien, et n'entre dans aucun contre-geste.
	_check(world.call("apply", {Vector2i(0, 0): 0}).is_empty(),
			"reposer la meme valeur ne laisse rien a defaire")
	world.queue_free()


## ⚠ UNE COUCHE QU'ON POSE SANS LA NETTOYER EST UNE FUITE. Retirer un plateau doit retirer sa
## falaise avec lui, pas la laisser sous le sol.
func _no_leak_when_a_plateau_goes(manifest: String) -> void:
	print("retirer un plateau retire aussi sa falaise")
	var flat: Dictionary = _flat(Vector2i(0, 0), Vector2i(13, 13), 0, {})
	var world: Node2D = _world(manifest, flat.duplicate())
	var bare: int = _placed(world)

	var raised: Dictionary = flat.duplicate()
	_flat(Vector2i(4, 3), Vector2i(9, 6), 1, raised)
	world.set("heights", raised)
	_check(_placed(world) > bare, "le plateau et sa falaise se posent (%d tuiles de plus)"
			% (_placed(world) - bare))

	world.set("heights", flat.duplicate())
	_check(_placed(world) == bare,
			"et tout repart quand il s'en va : %d tuiles, comme au depart" % _placed(world))
	world.queue_free()


func _snapshot(world: Node2D) -> Dictionary:
	var out: Dictionary = {}
	for child: Node in world.get_children():
		if not (child is TileMapLayer):
			continue
		var layer: TileMapLayer = child as TileMapLayer
		for at: Vector2i in layer.get_used_cells():
			out[Vector3i(at.x, at.y, layer.get_index())] = layer.get_cell_atlas_coords(at)
	return out
