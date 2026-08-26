extends SceneTree

## LE BORD A FLEUR : la ou le trait du haut n'a rien sur quoi se refermer.
##
## ⚠ LE CAS SE DIT EXACTEMENT, ET C'EST CE QUI LE REND MESURABLE. La transparence d'une
## tuile de bord d'etage N laisse voir la tuile d'etage N-1 DE LA MEME CASE. Si la voisine
## est a l'etage N-1, cette tuile-la est PLEINE de ce cote : le trait du haut s'y referme,
## et tout va bien -- c'est le cas courant, celui qui marche. Si la voisine est a N-2 ou
## plus bas, la tuile d'en dessous est elle aussi une tuile de BORD, transparente du meme
## cote : les deux couches sont vides au meme endroit, et le trait n'a plus de matiere ou
## atterrir. C'est le surplomb : de la terre haute sans rien dessous.
##
## ⚠ LE SUD N'EN EST PAS. Un bord sud est une levre : sa propre face couvre la case d'en
## dessous, toujours. C'est ce qui rend l'epaule legitime la et nulle part ailleurs.
##
## On compte donc les marches de DEUX etages ou plus, au nord, a l'est et a l'ouest.

const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")
const Families := preload("res://core/families.gd")

const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
const SIDE_NAMES: Array[String] = ["nord", "est", "ouest"]
const DIAGONALS: Array[Vector2i] = [Vector2i(1, -1), Vector2i(1, 1),
		Vector2i(-1, 1), Vector2i(-1, -1)]


func _initialize() -> void:
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	print("guide : %d x %d" % [HeightMask.width(guide), HeightMask.height(guide)])
	_survey(guide)
	print("")
	_price()
	quit()


func _survey(heights: PackedStringArray) -> void:
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var flush: Array[Vector2i] = []
	var flush_south: int = 0
	var diagonal: int = 0
	var edge_cells: int = 0
	var by_tile: Dictionary = {}
	for y: int in range(height):
		for x: int in range(width):
			var level: int = HeightMask.level_at(heights, x, y)
			if level < 1:
				continue
			var at: Vector2i = Vector2i(x, y)
			var borders: bool = false
			var bare: bool = false
			for side: int in range(SIDES.size()):
				var probe: Vector2i = at + SIDES[side]
				var beside: int = HeightMask.level_at(heights, probe.x, probe.y)
				if beside < level:
					borders = true
				if beside <= level - 2:
					bare = true
			if borders:
				edge_cells += 1
			if bare:
				flush.append(at)
				if surface.has(at):
					by_tile[int(surface[at])] = int(by_tile.get(int(surface[at]), 0)) + 1
			var south: int = HeightMask.level_at(heights, x, y + 1)
			if south <= level - 2:
				flush_south += 1
			for step: Vector2i in DIAGONALS:
				if HeightMask.level_at(heights, x + step.x, y + step.y) <= level - 2:
					diagonal += 1
					break

	print("cases d'etage >= 1 qui bordent (N/E/O) : %d" % edge_cells)
	print("dont A FLEUR -- marche de deux etages ou plus : %d  (%.1f %%)"
			% [flush.size(), 100.0 * flush.size() / maxi(1, edge_cells)])
	print("  au sud (legitime, la levre couvre)      : %d" % flush_south)
	print("  en diagonale seulement                   : %d" % diagonal)
	print("")
	print("Les vingt premieres, en coordonnees du guide :")
	for i: int in range(mini(20, flush.size())):
		var at: Vector2i = flush[i]
		var label: String = "-"
		if surface.has(at):
			var tile: int = int(surface[at])
			label = "%d %s" % [BlobIndex.silhouette(tile), BlobIndex.brink_name(tile)]
		print("  %3d,%-3d  etage %d  tuile %s" % [at.x, at.y,
				HeightMask.level_at(heights, at.x, at.y), label])
	print("")
	print("Les tuiles concernees : %d distinctes sur %d"
			% [by_tile.size(), Thickness.SURFACE_INDICES.size()])


## LE PRIX DE LA CLAUSE : combien de reliefs epais poseraient un bord a fleur ?
##
## Meme protocole que pour « au moins un flanc muet », morte de son chiffre (96 % -> 68 %).
func _price() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var thick: int = 0
	var offending: int = 0
	for round: int in range(4000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		thick += 1
		if _has_flush(relief):
			offending += 1
	print("PRIX DE LA CLAUSE, sur %d reliefs epais tires au sort :" % thick)
	print("  qui posent un bord a fleur : %d  (%.1f %%)"
			% [offending, 100.0 * offending / maxi(1, thick)])
	print("  donc acceptes par la clause : %.1f %%"
			% [100.0 * (thick - offending) / maxi(1, thick)])


func _has_flush(heights: PackedStringArray) -> bool:
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			var level: int = HeightMask.level_at(heights, x, y)
			if level < 1:
				continue
			for side: Vector2i in SIDES:
				if HeightMask.level_at(heights, x + side.x, y + side.y) <= level - 2:
					return true
	return false


func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = 14
	var h: int = 14
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	for stamp: int in range(rng.randi_range(4, 10)):
		var level: int = rng.randi_range(0, 2)
		var bw: int = rng.randi_range(3, 6)
		var bh: int = rng.randi_range(3, 6)
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
