extends SceneTree
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Coverage := preload("res://core/coverage.gd")
const Families := preload("res://core/families.gd")

func _initialize() -> void:
	var relief: PackedStringArray = ProofScene.relief(Families.BY_CELL)
	print("planche : %dx%d" % [relief[0].length(), relief.size()])
	print("fines : %d" % Thickness.thin_cells(relief).size())
	var report: Dictionary = Walls.analyse(relief, Thickness.wall_roles())
	print("robes hors cadre : %d" % (report["outside"] as Array).size())
	var visible: Dictionary = Walls.visible_roles(relief)
	var seen: Dictionary = {}
	for role: Vector2i in visible.values():
		seen[role] = true
	print("roles : %d sur %d" % [seen.size(), Thickness.wall_roles().size()])
	for role: Vector2i in Thickness.wall_roles():
		if not seen.has(role):
			print("    manque %s %s" % [Walls.pan_name(role.x), Walls.ROW_NAMES[role.y]])
	var cover: Dictionary = Coverage.analyse_relief(relief)
	print("surfaces : %d sur %d, complete=%s" % [(cover["present"] as Array).size(),
			Thickness.SURFACE_INDICES.size(), cover["is_complete"]])
	var centres: Dictionary = ProofScene.centres(Families.BY_CELL)
	var walled: Dictionary = visible
	var astray: int = 0
	for tile: int in centres.keys():
		var at: Vector2i = centres[tile]
		if Coverage.visible_index_at(relief, at.x, at.y, walled) != tile:
			astray += 1
	print("ilots hors de leur case : %d" % astray)
	quit()
