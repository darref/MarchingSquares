extends SceneTree

## QUE COUTERAIT DE NE PAS CLOTURER UN FLANC QUI S'ARRETE ?
##
## Le trait de cloture est ce qui dit « ma roche finit la ». Le retirer supprime le second trait
## a la frontiere -- donc les demi-lentilles -- mais laisse deux especes de voisinage sans
## aucune limite tracee. On compte laquelle est laquelle.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const ProofScene := preload("res://core/proof_scene.gd")

const STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT]


func _initialize() -> void:
	var tally: Dictionary = {"robe": 0, "surface": 0, "rien": 0}
	_gather(HeightMask.read(Modes.guide_path(Modes.EPAIS)), tally)
	_gather(ProofScene.relief(Families.BY_CELL), tally)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260827
	var kept: int = 0
	while kept < 120:
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		kept += 1
		_gather(relief, tally)
	var total: int = int(tally["robe"]) + int(tally["surface"]) + int(tally["rien"])
	print("=== CE QU'IL Y A DERRIERE UN FLANC QUI S'ARRETE ===")
	print("%d flancs, sur le guide, la planche et %d reliefs epais" % [total, kept])
	for kind: String in ["robe", "surface", "rien"]:
		print("   %-8s %6d   %5.1f %%" % [kind, int(tally[kind]),
				100.0 * float(tally[kind]) / float(maxi(total, 1))])
	print("")
	print("⚠ `robe` est le SEUL cas ou retirer le trait ferait perdre une limite : deux faces")
	print("   cote a cote, meme roche, plus rien entre elles. Ailleurs la couleur change toute")
	print("   seule -- roche contre terre, ou roche contre le vide.")
	quit()


func _gather(heights: PackedStringArray, tally: Dictionary) -> void:
	var roles: Dictionary = Walls.visible_roles(heights)
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	for at: Vector2i in roles.keys():
		var role: Vector2i = roles[at]
		var sides: Array[int] = [Walls.pan_east(role.x), Walls.pan_west(role.x)]
		for i: int in range(2):
			if sides[i] == Walls.SIDE_MUTE:
				continue
			var probe: Vector2i = at + STEPS[i]
			if roles.has(probe):
				tally["robe"] = int(tally["robe"]) + 1
			elif surface.has(probe):
				tally["surface"] = int(tally["surface"]) + 1
			else:
				tally["rien"] = int(tally["rien"]) + 1


func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = rng.randi_range(12, 18)
	var h: int = rng.randi_range(14, 20)
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	for stamp: int in range(rng.randi_range(4, 12)):
		var level: int = rng.randi_range(0, 3)
		var bw: int = rng.randi_range(3, 7)
		var bh: int = rng.randi_range(3, 7)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = maxi(row[x], level + 1)
				grid[y] = row
	for dig: int in range(rng.randi_range(1, 5)):
		var level: int = rng.randi_range(-1, 2)
		var bw: int = rng.randi_range(3, 6)
		var bh: int = rng.randi_range(3, 6)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = mini(row[x], level + 1)
				grid[y] = row
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(h):
		var line: String = ""
		for x: int in range(w):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
