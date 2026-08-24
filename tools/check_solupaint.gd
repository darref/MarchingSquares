# LE BANC D'SOLUPAINT — l'exactitude du plugin, et ses couts, hors suite.
#
# ⚠ POURQUOI CE FICHIER N'EST PAS DANS tests/run.gd : au moment de l'ecrire, l'arbre de
# travail portait le chantier NON COMMITE d'une autre session sur tests/run.gd. On ne pose
# pas ses assertions dans un fichier que quelqu'un d'autre a en main. A FONDRE DANS LA
# SUITE des que l'arbre est libre -- meme forme, meme code de sortie, rien a reecrire.
#
# Ce qu'il assere, et pourquoi chaque point a existe comme defaut :
#   - un monde qui GRANDIT par le setter `heights` retaille ses couches : avant, seul
#     `_reload` les taillait, et les etages au-dessus n'etaient pas poses -- des sommets
#     absents, sans une erreur ;
#   - `set_level` par la zone pose EXACTEMENT ce que poserait un monde rebati a neuf ;
#   - `apply()` rend le contre-geste, et le rejouer restaure le monde au tuile pres --
#     c'est ce que l'annulation du pinceau enregistre desormais ;
#   - en famille A CHEVAL, la pose derriere va SOUS la couche unique des tuiles duales :
#     posee sur SousPied1+, elle passait DEVANT elles et couvrait la case d'atterrissage
#     d'un carre de roche.
#
#     godot --headless --path . --script res://tools/check_solupaint.gd
extends SceneTree

const WorldScript := preload("res://addons/solupaint/world.gd")
const Rules := preload("res://addons/solupaint/rules.gd")

const TRIAL_MANIFEST: String = "res://trial/solutiles_essai_tileset.txt"
const CORNER_FOLDER: String = "user://solupaint_check"

var _checks: int = 0
var _failures: PackedStringArray = PackedStringArray()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)
	print("  %s  %s" % ["OK   " if ok else "ECHEC", label])


func _initialize() -> void:
	_test_layers_follow_growth()
	_test_writes_meet_full_rebuild()
	_test_apply_returns_counter_gesture()
	_test_corner_underfoot_below_duals()
	_bench()
	print("")
	if _failures.is_empty():
		print("BANC SOLUPAINT : %d verifications, 0 echec." % _checks)
		quit(0)
	else:
		print("BANC SOLUPAINT : %d verifications, %d ECHEC(S) :" % [_checks, _failures.size()])
		for failure: String in _failures:
			print("  - %s" % failure)
		quit(1)


func _flat(width: int, height: int, level: int = 0) -> Dictionary:
	var heights: Dictionary = {}
	for y: int in range(height):
		for x: int in range(width):
			heights[Vector2i(x, y)] = level
	return heights


func _world_with(heights: Dictionary, manifest: String = TRIAL_MANIFEST) -> Node2D:
	var world: Node2D = WorldScript.new()
	world.set("heights", heights.duplicate())
	world.set("manifest_path", manifest)
	return world


## Les tuiles posees, par nom de couche, en sautant les couches vides. Deux mondes n'ont
## pas a avoir le meme NOMBRE de couches -- un `_top` qui ne redescend pas en laisse de
## vides -- ils doivent poser les memes tuiles.
func _posed(world: Node2D) -> Dictionary:
	var by_layer: Dictionary = {}
	for child: Node in world.get_children():
		var layer: TileMapLayer = child as TileMapLayer
		if layer == null:
			continue
		var cells: Dictionary = {}
		for cell: Vector2i in layer.get_used_cells():
			cells[cell] = layer.get_cell_atlas_coords(cell)
		if not cells.is_empty():
			by_layer[String(layer.name)] = cells
	return by_layer


func _same_posed(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for layer: String in left.keys():
		if not right.has(layer):
			return false
		var mine: Dictionary = left[layer]
		var theirs: Dictionary = right[layer]
		if mine.size() != theirs.size():
			return false
		for cell: Vector2i in mine.keys():
			if not theirs.has(cell) or theirs[cell] != mine[cell]:
				return false
	return true


func _test_layers_follow_growth() -> void:
	print("le monde grandit par le setter : les couches suivent, rien ne manque")
	var world: Node2D = _world_with(_flat(5, 12))
	_check(String(world.get("last_error")) == "", "l essai se charge")
	var tall: Dictionary = _flat(5, 12)
	tall[Vector2i(2, 3)] = 2
	world.set("heights", tall)
	var surface2: TileMapLayer = world.get_node_or_null("Surface2") as TileMapLayer
	_check(surface2 != null, "la couche Surface2 existe apres le setter, sans _reload")
	_check(surface2 != null and surface2.get_cell_source_id(Vector2i(2, 3)) >= 0,
			"et le sommet d etage 2 y est pose : le monde ne perd plus ses etages")
	var fresh: Node2D = _world_with(tall)
	_check(_same_posed(_posed(world), _posed(fresh)),
			"le monde grandi est identique, tuile pour tuile, a un monde bati a neuf")
	world.free()
	fresh.free()


func _test_writes_meet_full_rebuild() -> void:
	print("set_level par la zone == monde rebati a neuf, sur des mondes tires au sort")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260823
	var apart: int = 0
	for _round: int in range(20):
		var base: Dictionary = {}
		for y: int in range(10):
			for x: int in range(10):
				if rng.randf() < 0.85:
					base[Vector2i(x, y)] = rng.randi_range(0, 2)
		var painted: Node2D = _world_with(base)
		var mirror: Dictionary = base.duplicate()
		for _stroke: int in range(8):
			var cell: Vector2i = Vector2i(rng.randi_range(0, 9), rng.randi_range(0, 9))
			var level: int = rng.randi_range(-1, 2)
			painted.call("set_level", cell, level)
			if level < 0:
				mirror.erase(cell)
			else:
				mirror[cell] = level
		var rebuilt: Node2D = _world_with(mirror)
		if not _same_posed(_posed(painted), _posed(rebuilt)):
			apart += 1
		painted.free()
		rebuilt.free()
	_check(apart == 0, "20 mondes, 8 retouches chacun : zero divergence")


func _test_apply_returns_counter_gesture() -> void:
	print("apply rend le contre-geste : le rejouer restaure le monde au tuile pres")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260824
	var wrong_inverse: int = 0
	var not_restored: int = 0
	var noop_paid: int = 0
	for _round: int in range(15):
		var base: Dictionary = {}
		for y: int in range(9):
			for x: int in range(9):
				if rng.randf() < 0.9:
					base[Vector2i(x, y)] = rng.randi_range(0, 2)
		var world: Node2D = _world_with(base)
		var snapshot: Dictionary = (world.get("heights") as Dictionary).duplicate()
		var reference: Dictionary = _posed(world)

		var batch: Dictionary = {}
		for _touch: int in range(6):
			batch[Vector2i(rng.randi_range(0, 8), rng.randi_range(0, 8))] = rng.randi_range(-1, 2)
		var inverse: Dictionary = world.call("apply", batch)
		for cell: Vector2i in inverse.keys():
			if int(inverse[cell]) != int(snapshot.get(cell, Rules.VOID)):
				wrong_inverse += 1
			if snapshot.get(cell, Rules.VOID) == batch.get(cell, -99):
				noop_paid += 1

		world.call("apply", inverse)
		var back: Dictionary = world.get("heights")
		if back.size() != snapshot.size():
			not_restored += 1
		else:
			for cell: Vector2i in snapshot.keys():
				if int(back.get(cell, Rules.VOID)) != int(snapshot[cell]):
					not_restored += 1
					break
		if not _same_posed(_posed(world), reference):
			not_restored += 1
		world.free()
	_check(wrong_inverse == 0, "le contre-geste porte la valeur d avant, exacte")
	_check(noop_paid == 0, "une case qui ne change pas n entre pas au contre-geste")
	_check(not_restored == 0, "aller puis retour : relief ET tuiles identiques, 15 mondes")


func _test_corner_underfoot_below_duals() -> void:
	print("famille a cheval : la pose derriere va SOUS la couche unique des duales")
	var manifest_path: String = _write_corner_kit()
	var relief: Dictionary = _flat(7, 14)
	relief[Vector2i(3, 2)] = 2
	relief[Vector2i(3, 3)] = 2
	relief[Vector2i(3, 7)] = 1
	# La levre (3,3) d etage 2 tombe de trois et atterrit sur la banquette (3,7), une case
	# d etage 1 : le sous-pied se repose sous ELLE.

	var dual: Node2D = _world_with(relief, manifest_path)
	_check(String(dual.get("last_error")) == "", "le kit a cheval fabrique se charge")
	var under0: TileMapLayer = dual.get_node_or_null("SousPied0") as TileMapLayer
	var under1: TileMapLayer = dual.get_node_or_null("SousPied1") as TileMapLayer
	_check(under0 != null and under0.get_cell_source_id(Vector2i(3, 7)) >= 0,
			"A CHEVAL : le sous-pied est sur SousPied0, sous la couche des duales")
	_check(under1 == null or under1.get_cell_source_id(Vector2i(3, 7)) < 0,
			"et plus jamais sur SousPied1, qui passerait DEVANT les tuiles duales")

	var cellwise: Node2D = _world_with(relief)
	var under1_cell: TileMapLayer = cellwise.get_node_or_null("SousPied1") as TileMapLayer
	_check(under1_cell != null and under1_cell.get_cell_source_id(Vector2i(3, 7)) >= 0,
			"PAR CASE : il reste sur la couche de son etage d atterrissage, sous Surface1")
	dual.free()
	cellwise.free()


## Un kit a cheval minimal, fabrique sur place : deux planches unies et un manifeste v5
## complet (15 index, 36 roles). Le contenu des pixels n'importe pas ici -- on verifie OU
## les tuiles se posent, pas ce qu'elles montrent.
func _write_corner_kit() -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CORNER_FOLDER))
	var surface: Image = Image.create_empty(8 * 16, 2 * 16, false, Image.FORMAT_RGBA8)
	surface.fill(Color(0.5, 0.55, 0.4))
	surface.save_png(ProjectSettings.globalize_path(CORNER_FOLDER.path_join("cheval_surface.png")))
	var walls: Image = Image.create_empty(9 * 16, 4 * 16, false, Image.FORMAT_RGBA8)
	walls.fill(Color(0.45, 0.4, 0.32))
	walls.save_png(ProjectSettings.globalize_path(CORNER_FOLDER.path_join("cheval_walls.png")))

	var lines: PackedStringArray = PackedStringArray()
	lines.append("solutiles-tileset 5")
	lines.append("mode minimal")
	lines.append("tile_size 16")
	lines.append("storey_tiles 3")
	lines.append("body_rows 2")
	lines.append("block_rows 4")
	lines.append("famille corner")
	lines.append("surface cheval_surface.png 8 2")
	lines.append("walls cheval_walls.png 9 4")
	for order: int in range(15):
		lines.append("index %d slot %d,%d" % [order + 1, order % 8, order / 8])
	for pan: int in range(9):
		for row: int in range(4):
			lines.append("role %d,%d slot %d,%d" % [pan, row, pan, row])
	var path: String = CORNER_FOLDER.path_join("cheval_tileset.txt")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	return path


func _bench() -> void:
	print("mesures, sur les memes gestes que le releve d avant :")
	for size: Vector2i in [Vector2i(64, 45), Vector2i(200, 150)]:
		var heights: Dictionary = {}
		for y: int in range(size.y):
			for x: int in range(size.x):
				heights[Vector2i(x, y)] = (x / 7 + y / 9) % 3
		var world: Node2D = WorldScript.new()
		world.set("heights", heights)
		world.set("manifest_path", TRIAL_MANIFEST)
		var centre: Vector2i = size / 2

		var start: int = Time.get_ticks_usec()
		for i: int in range(200):
			world.call("apply", {centre: 1 + (i % 2)})
		var spent: int = Time.get_ticks_usec() - start
		print("  apply (1 case, valeur qui change)    %3dx%-3d : %8.1f us/appel"
				% [size.x, size.y, spent / 200.0])

		world.call("apply", {centre: 2})
		start = Time.get_ticks_usec()
		for _i: int in range(200):
			world.call("apply", {centre: 2})
		spent = Time.get_ticks_usec() - start
		print("  apply (1 case, valeur identique)     %3dx%-3d : %8.1f us/appel"
				% [size.x, size.y, spent / 200.0])

		start = Time.get_ticks_usec()
		for i: int in range(200):
			world.call("set_level", centre, 1 + (i % 2))
		spent = Time.get_ticks_usec() - start
		print("  set_level (1 case)                   %3dx%-3d : %8.1f us/appel"
				% [size.x, size.y, spent / 200.0])

		var live: Dictionary = world.get("heights")
		var region: Rect2i = Rules.region_of(live, [centre], 2)
		start = Time.get_ticks_usec()
		for _i: int in range(100):
			Rules.corners_in(live, region)
		spent = Time.get_ticks_usec() - start
		print("  corners_in (zone d un coup de crayon) %3dx%-3d : %7.1f us/appel"
				% [size.x, size.y, spent / 100.0])

		world.free()
