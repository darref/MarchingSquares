extends SceneTree
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")

func _initialize() -> void:
	for what: String in ["planche", "guide"]:
		var relief: PackedStringArray = (ProofScene.relief(Families.BY_CELL) if what == "planche"
				else HeightMask.read(Modes.guide_path(Modes.EPAIS)))
		var seen: Dictionary = {}
		var visible: Dictionary = Walls.visible_roles(relief)
		for role: Vector2i in visible.values():
			seen[role] = int(seen.get(role, 0)) + 1
		var missing: Array[String] = []
		for role: Vector2i in Thickness.wall_roles():
			if not seen.has(role):
				missing.append("%s %s" % [Walls.pan_name(role.x), Walls.ROW_NAMES[role.y]])
		print("%s : %d roles vus sur %d ; manquent %d" % [what, seen.size(),
				Thickness.wall_roles().size(), missing.size()])
		for name: String in missing:
			print("    %s" % name)
		if what == "guide":
			var wanted: Array[String] = ["vide|vide corps 1", "vide|devant pied",
					"devant|vide pied", "devant|devant chapiteau", "devant|devant corps 0",
					"devant|devant corps 1", "devant|devant corps 2"]
			var where: Dictionary = {}
			var all_roles: Dictionary = Walls.visible_roles(relief)
			for key: Vector3i in all_roles.keys():
				var role: Vector2i = all_roles[key]
				var label: String = "%s %s" % [Walls.pan_name(role.x), Walls.ROW_NAMES[role.y]]
				if label in wanted and not where.has(label):
					where[label] = key
			for label: String in wanted:
				print("    %s -> %s" % [label, where.get(label, "nulle part")])
	quit()
