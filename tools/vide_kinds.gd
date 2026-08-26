extends SceneTree

## CE QU'IL Y A DERRIERE UN FLANC `VIDE` -- et il y a trois choses, pas une.
##
## ⚠ MEME MALADIE QUE LE BORD, UN ETAGE PLUS BAS. Le bord d'une tuile de SURFACE a ete
## dedouble ce matin : un cardinal vide borde du NU ou de la ROCHE, et une seule image ne
## pouvait pas etre juste dans les deux cas. Le flanc d'une tuile de FALAISE a exactement le
## meme defaut, et je ne l'ai pas vu : `vide` dit « ma roche s'arrete » sans dire CE QU'IL Y A
## A LA PLACE. Le dossier l'ecrit lui-meme -- « de la terre, le sol d'en bas, le vide ».
##
## Trois especes, mesurees ici :
##   PLATEAU  -- la voisine est au niveau de ma levre ou au-dessus : le plateau continue,
##               et ce que la tuile doit montrer a son bord, c'est de la terre HAUTE ;
##   SOL      -- la voisine est plus bas que ma levre : du sol nu, tout en bas ;
##   VIDE     -- hors du monde.
##
## Un role qui rencontre deux especes est une tuile sommee d'etre deux choses.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")

const PLATEAU: int = 0
const SOL: int = 1
const DEHORS: int = 2
const KIND_NAMES: Array[String] = ["plateau", "sol", "dehors"]


func _initialize() -> void:
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	print("=== LE GUIDE ===")
	var on_guide: Dictionary = _survey(guide)
	_report(on_guide)

	print("")
	print("=== 200 RELIEFS EPAIS TIRES AU SORT ===")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var pooled: Dictionary = {}
	var kept: int = 0
	while kept < 200:
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		kept += 1
		var found: Dictionary = _survey(relief)
		for key: Variant in found.keys():
			if not pooled.has(key):
				pooled[key] = {}
			for kind: Variant in (found[key] as Dictionary).keys():
				(pooled[key] as Dictionary)[kind] = int((pooled[key] as Dictionary).get(kind, 0)) \
						+ int((found[key] as Dictionary)[kind])
	_report(pooled)
	quit()


## role+cote -> { espece : compte }
func _survey(heights: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	var covered: Dictionary = {}
	for key: Vector3i in roles.keys():
		covered[Vector2i(key.x, key.y)] = true
	for key: Vector3i in roles.keys():
		var at: Vector2i = Vector2i(key.x, key.y)
		var lip: int = key.z
		var role: Vector2i = roles[key] as Vector2i
		for side: int in range(2):
			var step: Vector2i = Vector2i.LEFT if side == 0 else Vector2i.RIGHT
			var flank: int = Walls.pan_west(role.x) if side == 0 else Walls.pan_east(role.x)
			if flank != Walls.SIDE_VOID:
				continue
			var probe: Vector2i = at + step
			var level: int = HeightMask.level_at(heights, probe.x, probe.y)
			var kind: int = DEHORS
			if level >= lip:
				kind = PLATEAU
			elif level >= 0:
				kind = SOL
			var tag: Vector3i = Vector3i(role.x, role.y, side)
			if not out.has(tag):
				out[tag] = {}
			(out[tag] as Dictionary)[kind] = int((out[tag] as Dictionary).get(kind, 0)) + 1
	return out


func _report(survey: Dictionary) -> void:
	var ambiguous: int = 0
	var lines: Array[String] = []
	for tag: Vector3i in survey.keys():
		var kinds: Dictionary = survey[tag]
		if kinds.size() < 2:
			continue
		ambiguous += 1
		var bits: Array[String] = []
		var order: Array = kinds.keys()
		order.sort()
		for kind: Variant in order:
			bits.append("%s x%d" % [KIND_NAMES[int(kind)], int(kinds[kind])])
		lines.append("   %s flanc %s : %s" % [Walls.pan_name(tag.x),
				"ouest" if tag.z == 0 else "est", ", ".join(bits)])
	lines.sort()
	print("flancs `vide` distincts (role + cote)   : %d" % survey.size())
	print("dont AMBIGUS -- deux especes ou plus    : %d" % ambiguous)
	for line: String in lines:
		print(line)


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
