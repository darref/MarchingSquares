extends SceneTree

## LE RECENSEMENT DES RACCORDS : chiffrer la decomposition « +13 tuiles de bord ».
##
## Le cas, dit simplement. Deux ilots colles a des hauteurs differentes. Sur une portion,
## leurs deux bords sont CONFONDUS -- le petit est au bord du grand, et les deux contours
## passent au meme endroit. Puis le petit tourne vers l'INTERIEUR du grand, et son contour
## quitte celui du grand. C'est a cet endroit precis, et nulle part ailleurs, que le trait
## du haut doit rejoindre celui du bas -- donc c'est le seul endroit qui a besoin d'un point
## d'ancrage.
##
## Une case est un RACCORD si, a un etage L, elle porte a la fois :
##   - un cote ouvert aux DEUX etages L et L+1 (la portion confondue), et
##   - un cote ouvert au seul etage L+1 (le contour du haut qui rentre).
##
## Trois nombres :
##   1. combien de raccords ;
##   2. sur combien de couples de tuiles distincts -- c'est le prix du « +13 » ;
##   3. combien de ces cases ont AUSSI de la mer ouverte ailleurs. Celui-la decide si un
##      drapeau par tuile suffit, ou s'il faut le decliner par cote.

const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Thickness := preload("res://core/thickness.gd")

const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SIDE_NAMES: Array[String] = ["N", "E", "S", "O"]


func _initialize() -> void:
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	print("=== LE GUIDE (%d x %d) ===" % [HeightMask.width(guide), HeightMask.height(guide)])
	_survey(guide, true)
	print("")
	print("=== DU RELIEF EPAIS TIRE AU SORT ===")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var pool: Array[PackedStringArray] = []
	while pool.size() < 300:
		var relief: PackedStringArray = _random(rng)
		if Thickness.thin_cells(relief).is_empty():
			pool.append(relief)
	_survey_many(pool)
	quit()


func _survey(heights: PackedStringArray, verbose: bool) -> Dictionary:
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var top: int = HeightMask.top_level(heights)
	var junctions: int = 0
	var signatures: Dictionary = {}
	var also_open_sea: int = 0
	var flush_cells: int = 0
	var samples: Array[String] = []
	for level: int in range(1, top + 1):
		for y: int in range(height):
			for x: int in range(width):
				if HeightMask.level_at(heights, x, y) < level + 1:
					continue
				var lower: int = 0
				var upper: int = 0
				for side: int in range(4):
					var probe: Vector2i = Vector2i(x, y) + SIDES[side]
					var beside: int = HeightMask.level_at(heights, probe.x, probe.y)
					if beside < level:
						lower |= 1 << side
					if beside < level + 1:
						upper |= 1 << side
				var shared: int = lower & upper
				var inward: int = upper & ~lower
				if shared != 0:
					flush_cells += 1
				if shared == 0 or inward == 0:
					continue
				junctions += 1
				signatures[Vector2i(lower, upper)] = int(signatures.get(
						Vector2i(lower, upper), 0)) + 1
				# De la mer ouverte ailleurs : un cote ouvert en bas que le haut ne suit pas.
				if (lower & ~upper) != 0:
					also_open_sea += 1
					if samples.size() < 8:
						samples.append("%d,%d etage %d  bas=%s haut=%s" % [x, y, level,
								_mask_name(lower), _mask_name(upper)])
	if verbose:
		print("cases ou les deux contours sont CONFONDUS sur un cote : %d" % flush_cells)
		print("1. RACCORDS (le haut quitte le bas)          : %d" % junctions)
		print("2. couples de tuiles distincts               : %d" % signatures.size())
		var order: Array = signatures.keys()
		order.sort_custom(func(a: Variant, b: Variant) -> bool:
			return int(signatures[a]) > int(signatures[b]))
		for key: Variant in order:
			var pair: Vector2i = key as Vector2i
			print("     bas=%-9s haut=%-9s  x%d" % [_mask_name(pair.x), _mask_name(pair.y),
					int(signatures[key])])
		print("3. dont la case a AUSSI de la mer ouverte ailleurs : %d  (%.1f %%)"
				% [also_open_sea, 100.0 * also_open_sea / maxi(1, junctions)])
		for line: String in samples:
			print("     %s" % line)
	return {"junctions": junctions, "signatures": signatures, "mixed": also_open_sea}


func _survey_many(pool: Array[PackedStringArray]) -> void:
	var junctions: int = 0
	var mixed: int = 0
	var signatures: Dictionary = {}
	var with_any: int = 0
	for relief: PackedStringArray in pool:
		var report: Dictionary = _survey(relief, false)
		junctions += int(report["junctions"])
		mixed += int(report["mixed"])
		if int(report["junctions"]) > 0:
			with_any += 1
		for key: Variant in (report["signatures"] as Dictionary).keys():
			signatures[key] = true
	print("reliefs epais : %d, dont %d portent au moins un raccord (%.0f %%)"
			% [pool.size(), with_any, 100.0 * with_any / maxi(1, pool.size())])
	print("1. RACCORDS au total                         : %d" % junctions)
	print("2. couples de tuiles distincts               : %d" % signatures.size())
	print("3. dont la case a AUSSI de la mer ouverte    : %d  (%.1f %%)"
			% [mixed, 100.0 * mixed / maxi(1, junctions)])


func _mask_name(mask: int) -> String:
	if mask == 0:
		return "-"
	var parts: Array[String] = []
	for side: int in range(4):
		if (mask & (1 << side)) != 0:
			parts.append(SIDE_NAMES[side])
	return "".join(parts)


func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = 16
	var h: int = 16
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	for stamp: int in range(rng.randi_range(4, 10)):
		var level: int = rng.randi_range(0, 2)
		var bw: int = rng.randi_range(3, 7)
		var bh: int = rng.randi_range(3, 7)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = maxi(row[x], level + 1)
				grid[y] = row
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(h):
		var line: String = ""
		for x: int in range(w):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
