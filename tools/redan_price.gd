extends SceneTree

## LE PRIX DU REDAN : combien de reliefs perdrait-on en interdisant une face trop etroite ?
##
## Une FACE, c'est la paroi qu'on voit sous une levre. La plupart font plusieurs colonnes de
## large. Mais quand une colonne plonge plus bas que ses voisines -- un REDAN -- il existe des
## rangees ou la paroi ne fait qu'UNE ou DEUX colonnes.
##
## C'est le seul obstacle qui empeche le vocabulaire des falaises de se fermer comme celui des
## plateaux. La question n'est donc pas « est-ce joli » mais « combien ca coute de l'interdire ».
## Meme protocole que les deux regles mortes de la journee : on mesure avant de decider.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var thick: int = 0
	var with_narrow: Dictionary = {1: 0, 2: 0}
	var face_cells: int = 0
	var narrow_cells: Dictionary = {1: 0, 2: 0}
	for round: int in range(4000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		thick += 1
		var report: Dictionary = _runs(relief)
		face_cells += int(report["cells"])
		for width: int in [1, 2]:
			narrow_cells[width] = int(narrow_cells[width]) + int((report["narrow"] as Dictionary)[width])
			if int((report["narrow"] as Dictionary)[width]) > 0:
				with_narrow[width] = int(with_narrow[width]) + 1
	print("=== LE PRIX DU REDAN ===")
	print("reliefs epais parcourus : %d   cases de face : %d" % [thick, face_cells])
	print("")
	print("interdire une face d'UNE colonne :")
	print("   reliefs refuses : %d / %d  (%.1f %%)   -> acceptes : %.1f %%"
			% [int(with_narrow[1]), thick, 100.0 * int(with_narrow[1]) / maxi(1, thick),
			100.0 * (thick - int(with_narrow[1])) / maxi(1, thick)])
	print("   cases concernees : %d  (%.2f %%)"
			% [int(narrow_cells[1]), 100.0 * int(narrow_cells[1]) / maxi(1, face_cells)])
	print("")
	print("interdire une face de MOINS DE TROIS colonnes :")
	print("   reliefs refuses : %d / %d  (%.1f %%)   -> acceptes : %.1f %%"
			% [int(with_narrow[2]), thick, 100.0 * int(with_narrow[2]) / maxi(1, thick),
			100.0 * (thick - int(with_narrow[2])) / maxi(1, thick)])
	print("   cases concernees : %d  (%.2f %%)"
			% [int(narrow_cells[2]), 100.0 * int(narrow_cells[2]) / maxi(1, face_cells)])
	print("")
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var on_guide: Dictionary = _runs(guide)
	print("=== ET SUR LE GUIDE LIVRE ===")
	print("   %d cases de face ; %d en face d'une colonne, %d en face de moins de trois"
			% [int(on_guide["cells"]), int((on_guide["narrow"] as Dictionary)[1]),
			int((on_guide["narrow"] as Dictionary)[2])])
	quit()


## Les rangees de face, et leur largeur.
func _runs(heights: PackedStringArray) -> Dictionary:
	var visible: Dictionary = {}
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	for key: Vector3i in roles.keys():
		var at: Vector2i = Vector2i(key.x, key.y)
		if not visible.has(at) or key.z > int(visible[at]):
			visible[at] = key.z
	# On regroupe par rangee, puis on coupe en courses de meme profondeur.
	var rows: Dictionary = {}
	for at: Vector2i in visible.keys():
		if not rows.has(at.y):
			rows[at.y] = []
		(rows[at.y] as Array).append(at.x)
	var cells: int = 0
	var narrow: Dictionary = {1: 0, 2: 0}
	for y: Variant in rows.keys():
		var xs: Array = rows[y]
		xs.sort()
		var start: int = 0
		while start < xs.size():
			var stop: int = start
			# ⚠ UNE COURSE, C'EST LA MEME FACE : meme rangee, colonnes voisines, MEME
			# profondeur de levre. Deux parois cote a cote a des profondeurs differentes sont
			# deux faces, pas une large.
			while stop + 1 < xs.size() and int(xs[stop + 1]) == int(xs[stop]) + 1 \
					and int(visible[Vector2i(int(xs[stop + 1]), int(y))]) \
						== int(visible[Vector2i(int(xs[stop]), int(y))]):
				stop += 1
			var width: int = stop - start + 1
			cells += width
			if width == 1:
				narrow[1] = int(narrow[1]) + width
			if width < 3:
				narrow[2] = int(narrow[2]) + width
			start = stop + 1
	return {"cells": cells, "narrow": narrow}


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
