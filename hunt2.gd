extends SceneTree
const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const CornerIndex := preload("res://core/corner_index.gd")

func _initialize() -> void:
	var total: int = OS.get_cmdline_user_args()[0].to_int()
	var canonical: Dictionary = {}
	for index: int in BlobIndex.CANONICAL_INDICES:
		canonical[index] = true
	var known: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		known[role] = true

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260821
	var strays: int = 0
	var cells: int = 0
	var wall_cells: int = 0
	var seen_indices: Dictionary = {}
	var seen_roles: Dictionary = {}
	var seen_corners: Dictionary = {}
	var start: int = Time.get_ticks_msec()

	for attempt: int in range(total):
		var columns: int = rng.randi_range(3, 14)
		var rows: int = rng.randi_range(3, 14)
		var top: int = rng.randi_range(1, 4)
		var heights: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				var level: int = rng.randi_range(0, top)
				line += "." if level == 0 else str(level)
			heights.append(line)
		for index: int in Coverage.index_map(heights).values():
			cells += 1
			seen_indices[index] = true
			if not canonical.has(index):
				strays += 1
		for role: Vector2i in Walls.visible_roles(heights).values():
			wall_cells += 1
			seen_roles[role] = true
			if not known.has(role):
				strays += 1
		for code: int in CornerIndex.index_map(heights).values():
			seen_corners[code] = true
			if code < 1 or code > 15:
				strays += 1

	print("%d reliefs tires au sort (3..14 x 3..14, 1 a 4 etages, cases au hasard)" % total)
	print("  %d cases de surface, %d cases de robe" % [cells, wall_cells])
	print("  index de surface rencontres : %d / 47" % seen_indices.size())
	print("  roles de robe rencontres    : %d / 36" % seen_roles.size())
	print("  croisements rencontres      : %d / 15" % seen_corners.size())
	print("  CONTRE-EXEMPLES : %d" % strays)
	print("  en %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	quit(0)
