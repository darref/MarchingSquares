extends SceneTree

## LE PRIX DE L'ENTAILLE -- la clause qui ferait tomber `vide_haut`.
##
## `vide_haut` veut dire : du terrain AU NIVEAU DE MA LEVRE, colle au flanc de ma face.
## Autrement dit, ma falaise est taillee dans une ENTAILLE -- une encoche dont la joue est du
## plateau, a la meme hauteur que la levre dont je tombe.
##
## Une clause qui l'interdirait -- « une face n'a pas de terrain de sa propre levre sur son
## flanc » -- ferait tomber 29 roles sur 72, et ramenerait le vocabulaire de robe a 43, soit
## MOINS qu'aujourd'hui. Reste a savoir ce qu'elle refuse.
##
## ⚠ MEME PROTOCOLE QUE LES DEUX CLAUSES MORTES DE LA VEILLE. « Un plateau se pose sur une
## banquette » refusait 99,3 % des reliefs ; « une face fait au moins trois colonnes » en
## refusait 78,8 %. Toutes deux sont mortes de leur chiffre, pas d'un avis. On mesure d'abord.
##
## On compte trois choses :
##   1. la proportion de reliefs epais qui posent au moins une entaille -- ce que la clause
##      refuserait en bloc ;
##   2. la proportion de CASES concernees -- l'ampleur du geste a corriger ;
##   3. et, pour les curieux, si l'entaille se limite a certaines rangees.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var thick: int = 0
	var offending: int = 0
	var cells: int = 0
	var notched: int = 0
	var by_row: Dictionary = {}
	for round: int in range(3000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		thick += 1
		var report: Dictionary = _survey(relief)
		cells += int(report["cells"])
		notched += int(report["notched"])
		if int(report["notched"]) > 0:
			offending += 1
		for row: Variant in (report["rows"] as Dictionary).keys():
			by_row[row] = int(by_row.get(row, 0)) + int((report["rows"] as Dictionary)[row])
	print("=== LE PRIX DE L'ENTAILLE ===")
	print("reliefs epais parcourus : %d   cases de robe : %d" % [thick, cells])
	print("")
	print("1. reliefs qui posent au moins une entaille : %d / %d  (%.1f %%)"
			% [offending, thick, 100.0 * offending / maxi(1, thick)])
	print("   donc ACCEPTES par la clause               : %.1f %%"
			% [100.0 * (thick - offending) / maxi(1, thick)])
	print("2. cases concernees                         : %d  (%.2f %%)"
			% [notched, 100.0 * notched / maxi(1, cells)])
	print("3. par rangee :")
	for row: int in range(Walls.BLOCK_ROWS):
		print("     %-10s x%d" % [Walls.ROW_NAMES[row], int(by_row.get(row, 0))])
	print("")
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var on_guide: Dictionary = _survey(guide)
	print("=== ET SUR LE GUIDE LIVRE ===")
	print("   %d cases de robe, dont %d en entaille"
			% [int(on_guide["cells"]), int(on_guide["notched"])])
	quit()


func _survey(heights: PackedStringArray) -> Dictionary:
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	var highest: Dictionary = {}
	for key: Vector3i in roles.keys():
		var at: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(at) or key.z > int((highest[at] as Vector3i).z):
			highest[at] = key
	var cells: int = 0
	var notched: int = 0
	var rows: Dictionary = {}
	for at: Vector2i in highest.keys():
		cells += 1
		var key: Vector3i = highest[at]
		var role: Vector2i = roles[key] as Vector2i
		var lip: int = key.z
		var caught: bool = false
		for side: int in range(2):
			var flank: int = Walls.pan_west(role.x) if side == 0 else Walls.pan_east(role.x)
			if flank != Walls.SIDE_VOID:
				continue
			var step: Vector2i = Vector2i.LEFT if side == 0 else Vector2i.RIGHT
			# ⚠ ON COMPARE A LA LEVRE, PAS A MON ETAGE. Une case de robe est, sur la carte,
			# une case du sol d'en bas : son etage ne dit rien de la falaise qui la couvre.
			if HeightMask.level_at(heights, at.x + step.x, at.y + step.y) >= lip:
				caught = true
		if caught:
			notched += 1
			rows[role.y] = int(rows.get(role.y, 0)) + 1
	return {"cells": cells, "notched": notched, "rows": rows}


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
