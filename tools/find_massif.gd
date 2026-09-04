extends SceneTree

## LA FRONTIERE INTERNE : de l'herbe et de la roche du MEME massif, cote a cote.
##
## La silhouette se lit sur l'EMPREINTE -- surface ∪ falaise. Une case de surface dont la
## voisine est la falaise de son PROPRE massif a donc ce bit MIS : elle se croit pleine, et
## rend `SURFACE 255`, la tuile d'interieur qui se repete partout. Sa voisine de roche, pour
## la meme raison, rend un corps plein. Aucune des deux ne peut marquer la frontiere.

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Families := preload("res://core/families.gd")


func _initialize() -> void:
	var world: PackedStringArray = HeightMask.read("res://guides/massifs.txt")
	var top: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one

	# La MEME numerotation que l'apercu : ancre par massif, puis ordre de lecture.
	var anchor: Dictionary = {}
	for cell2: Vector2i in top.keys():
		var one2: Dictionary = top[cell2]
		var mark: int = int(one2["massif"])
		var surface: bool = int(one2["band"]) == Massifs.SURFACE
		if anchor.has(mark):
			var had: Dictionary = anchor[mark]
			if bool(had["surface"]) and not surface:
				continue
			var was: Vector2i = had["cell"]
			if bool(had["surface"]) == surface \
					and (cell2.y > was.y or (cell2.y == was.y and cell2.x > was.x)):
				continue
		anchor[mark] = {"cell": cell2, "surface": surface}
	var order: Array[int] = []
	order.assign(anchor.keys())
	order.sort_custom(func(a: int, b: int) -> bool:
		var pa: Vector2i = (anchor[a] as Dictionary)["cell"]
		var pb: Vector2i = (anchor[b] as Dictionary)["cell"]
		return pa.y < pb.y if pa.y != pb.y else pa.x < pb.x)

	var wanted: int = int(OS.get_cmdline_user_args()[0])
	var mark2: int = order[wanted - 1]
	var box: Rect2i = Rect2i()
	var started: bool = false
	for cell3: Vector2i in top.keys():
		if int((top[cell3] as Dictionary)["massif"]) != mark2:
			continue
		if not started:
			box = Rect2i(cell3, Vector2i.ONE)
			started = true
		else:
			box = box.expand(cell3).expand(cell3 + Vector2i.ONE)
	print("massif %d (interne %d) : etage %d, cadre %s"
			% [wanted, mark2, int((top[(anchor[mark2] as Dictionary)["cell"]]
			as Dictionary)["level"]), box])

	# LA FRONTIERE : herbe et roche du meme massif, cote a cote horizontalement.
	var known: Dictionary = {}
	for tile: int in Families.massif_tiles():
		known[tile] = true
	var seams: Array = []
	var everywhere: Dictionary = {}
	for cell4: Vector2i in top.keys():
		var mine: Dictionary = top[cell4]
		if int(mine["band"]) != Massifs.SURFACE:
			continue
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			var near: Vector2i = cell4 + step
			if not top.has(near):
				continue
			var other: Dictionary = top[near]
			if int(other["massif"]) != int(mine["massif"]):
				continue
			if int(other["band"]) == Massifs.SURFACE:
				continue
			var pair: Array = [Massifs.key_of(mine), Massifs.key_of(other)]
			everywhere[pair] = int(everywhere.get(pair, 0)) + 1
			if int(mine["massif"]) == mark2:
				seams.append([cell4, near, pair])
	print("")
	print("SUR TOUT LE GUIDE : %d frontieres internes herbe|roche, %d couples de tuiles"
			% [_sum(everywhere), everywhere.size()])
	var rows: Array = []
	for pair2: Variant in everywhere.keys():
		rows.append([int(everywhere[pair2]), pair2])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	for k: int in range(mini(8, rows.size())):
		var pair3: Array = (rows[k] as Array)[1]
		print("  %5d x   %-24s | %s" % [int((rows[k] as Array)[0]),
				Massifs.describe(int(pair3[0])), Massifs.describe(int(pair3[1]))])
	print("")
	print("dans le massif %d : %d frontieres" % [wanted, seams.size()])
	for row: Array in seams:
		print("  herbe %s  contre  roche %s      %s | %s" % [row[0], row[1],
				Massifs.describe(int((row[2] as Array)[0])),
				Massifs.describe(int((row[2] as Array)[1]))])
	quit()


func _sum(table: Dictionary) -> int:
	var many: int = 0
	for key: Variant in table.keys():
		many += int(table[key])
	return many
