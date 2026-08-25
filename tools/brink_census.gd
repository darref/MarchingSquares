extends SceneTree

## LE RECENSEMENT DU BORD : quelles paires (silhouette, bord) un relief EPAIS produit-il ?
##
## ⚠ LA FORME FERMEE SE COMPARE AU RENCONTRE, DANS LES DEUX SENS. Une forme trop large
## fabrique des tuiles que personne ne peut peindre -- le batisseur s'y casse les dents ; une
## forme trop etroite laisse un trou dans la planche. Le seul juge est la battue.

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Thickness := preload("res://core/thickness.gd")
const BlobIndex := preload("res://core/blob_index.gd")


func _initialize() -> void:
	var seen: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260825
	var tried: int = 0
	for round: int in range(6000):
		var w: int = rng.randi_range(6, 13)
		var h: int = rng.randi_range(6, 13)
		var top: int = rng.randi_range(1, 3)
		var heights: PackedStringArray = _random(rng, w, h, top)
		if not Thickness.thin_cells(heights).is_empty():
			continue
		tried += 1
		for tile: int in Coverage.index_map(heights).values():
			seen[tile] = int(seen.get(tile, 0)) + 1
	# Et les guides livres, qui portent ce que le hasard ne fabrique pas.
	for path: String in ["res://guides/epais.txt",
			]:
		var heights: PackedStringArray = HeightMask.read(path)
		if heights.is_empty():
			continue
		for tile: int in Coverage.index_map(heights).values():
			seen[tile] = int(seen.get(tile, 0)) + 1
	var closed: Dictionary = {}
	for tile: int in Thickness.SURFACE_INDICES:
		closed[tile] = true
	var extra: Array[int] = []
	var missing: Array[int] = []
	for tile: int in seen.keys():
		if not closed.has(tile):
			extra.append(tile)
	for tile: int in closed.keys():
		if not seen.has(tile):
			missing.append(tile)
	extra.sort()
	missing.sort()
	print("reliefs epais parcourus : %d" % tried)
	print("forme fermee : %d   rencontrees : %d" % [closed.size(), seen.size()])
	print("")
	print("RENCONTREES HORS DE LA FORME (la forme est trop etroite) : %d" % extra.size())
	for tile: int in extra:
		print("  %s  x%d" % [_name(tile), int(seen[tile])])
	print("")
	print("DANS LA FORME, JAMAIS RENCONTREES (la forme est peut-etre trop large) : %d"
			% missing.size())
	for tile: int in missing:
		print("  %s" % _name(tile))
	print("")
	print("LES PLUS RARES :")
	var order: Array = seen.keys()
	order.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(seen[a]) < int(seen[b]))
	for i: int in range(mini(10, order.size())):
		print("  %s  x%d" % [_name(int(order[i])), int(seen[order[i]])])
	quit()


func _name(tile: int) -> String:
	var edge: String = BlobIndex.brink_name(tile)
	return "%3d %s" % [BlobIndex.silhouette(tile), edge]


func _random(rng: RandomNumberGenerator, w: int, h: int, top: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	# Des blocs epais, jamais du bruit case par case : le bruit n'est jamais epais.
	for stamp: int in range(rng.randi_range(3, 9)):
		var level: int = rng.randi_range(0, top)
		var bw: int = rng.randi_range(3, 6)
		var bh: int = rng.randi_range(3, 6)
		var ox: int = rng.randi_range(0, maxi(0, w - bw))
		var oy: int = rng.randi_range(0, maxi(0, h - bh))
		for y: int in range(oy, mini(h, oy + bh)):
			for x: int in range(ox, mini(w, ox + bw)):
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
