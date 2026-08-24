# BANC : le cout d'un coup de crayon sur une tuile massivement reproduite.
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const Delivery := preload("res://core/delivery.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const WorkAreaScript := preload("res://ui/work_area.gd")


func _init() -> void:
	for resolution: int in [16, 256]:
		_bench(resolution)
	quit()


func _bench(resolution: int) -> void:
	var heights: PackedStringArray = HeightMask.read("res://guides/minimal.txt")
	var work: Control = WorkAreaScript.new()
	root.add_child(work)
	work.size = Vector2(1200, 800)
	var painting: RefCounted = Painting.new(resolution)
	work.show_guide(heights, painting)
	work._job = null
	work._tile_px = 400.0
	# La case la plus reproduite : l'index 255, la masse pleine.
	var best: Vector2i = Vector2i.ZERO
	var most: int = 0
	for cell: Vector2i in work._paintable.keys():
		var twins: int = work._twin_of[cell].size() if work._twin_of.has(cell) else 1
		if twins > most:
			most = twins
			best = cell
	print("res %d : case %s, %d jumelles" % [resolution, best, most])
	work._origin = -Vector2(float(best.x), float(best.y)) * work._tile_px
	# Un trait en diagonale a travers la case, bord a bord (touche les raccords).
	var t0: int = Time.get_ticks_usec()
	work._begin_or_end(true, 1, Vector2(0.5, 0.5))
	work._apply_stroke(Vector2(0.5, 0.5), Vector2(399.5, 399.5))
	work._begin_or_end(false, 1, Vector2(399.5, 399.5))
	var t1: int = Time.get_ticks_usec()
	print("  trait diagonal (%d points) : %.2f ms" % [resolution, (t1 - t0) / 1000.0])
	# Un seul point interieur, repete : le cout par point.
	work._begin_or_end(true, 1, Vector2(200, 200))
	var t2: int = Time.get_ticks_usec()
	for i: int in range(100):
		work._touch(Vector2(100.0 + i, 200.0))
	var t3: int = Time.get_ticks_usec()
	work._begin_or_end(false, 1, Vector2(200, 200))
	print("  100 points interieurs : %.2f ms (%.1f us/point)" % [(t3 - t2) / 1000.0, (t3 - t2) / 100.0])
	# Un point de bord, repete.
	work._begin_or_end(true, 1, Vector2(200, 1))
	var t4: int = Time.get_ticks_usec()
	for i: int in range(100):
		work._touch(Vector2(50.0 + i * 3.0, 1.0))
	var t5: int = Time.get_ticks_usec()
	work._begin_or_end(false, 1, Vector2(200, 1))
	print("  100 points de bord : %.2f ms (%.1f us/point)" % [(t5 - t4) / 1000.0, (t5 - t4) / 100.0])
	# Une robe tres reproduite.
	var wall: Vector2i = Vector2i.ZERO
	most = 0
	for cell: Vector2i in work._wall_cells.keys():
		if not work._paintable.has(cell):
			continue
		var twins: int = work._twin_of[cell].size() if work._twin_of.has(cell) else 1
		if twins > most:
			most = twins
			wall = cell
	print("  robe %s, %d jumelles" % [wall, most])
	work._origin = -Vector2(float(wall.x), float(wall.y)) * work._tile_px
	work._begin_or_end(true, 1, Vector2(200, 1))
	var t6: int = Time.get_ticks_usec()
	for i: int in range(100):
		work._touch(Vector2(50.0 + i * 3.0, 1.0))
	var t7: int = Time.get_ticks_usec()
	work._begin_or_end(false, 1, Vector2(200, 1))
	print("  100 points de bord de robe : %.2f ms (%.1f us/point)" % [(t7 - t6) / 1000.0, (t7 - t6) / 100.0])
	work._begin_or_end(true, 1, Vector2(200, 200))
	var t8: int = Time.get_ticks_usec()
	for i: int in range(100):
		work._touch(Vector2(50.0 + i * 3.0, 200.0))
	var t9: int = Time.get_ticks_usec()
	work._begin_or_end(false, 1, Vector2(200, 200))
	print("  100 points interieurs de robe : %.2f ms (%.1f us/point)" % [(t9 - t8) / 1000.0, (t9 - t8) / 100.0])
	# Le televersement d'une image de cases sales.
	var ta: int = Time.get_ticks_usec()
	var done: int = 0
	for cell: Vector2i in work._stale.keys():
		if done >= 48:
			break
		work._upload_cell(cell)
		done += 1
	var tb: int = Time.get_ticks_usec()
	print("  televersement de %d cases : %.2f ms (sales : %d)" % [done, (tb - ta) / 1000.0, work._stale.size()])
	# Les compteurs.
	var tc: int = Time.get_ticks_usec()
	var surface: Dictionary = Delivery.resolve_indexed(work.surface_index(),
			work.painted_surface_cells(), Families.surface_indices(Families.BY_CELL))
	var walls: Dictionary = Walls.resolve_roles(work.wall_roles(), work.painted_wall_cells())
	var td: int = Time.get_ticks_usec()
	print("  compteurs : %.2f ms (%d / %d)" % [(td - tc) / 1000.0, surface["delivered"].size(), walls["delivered"].size()])
	root.remove_child(work)
	work.free()
