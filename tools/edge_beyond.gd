# CE QU'IL Y A AU-DELA D'UN BORD VIDE — et si la meme tuile en voit deux choses.
#
# ⚠ UNE TUILE PARTAGEE N'A QU'UNE IMAGE. L'index de surface ne connait que la SILHOUETTE de
# son etage : huit bits qui disent ou est la terre. Il ne dit RIEN de ce qui occupe la case
# d'a cote -- de l'herbe de l'etage du dessous, ou la FACE d'une falaise voisine. Or ces
# deux-la ne se dessinent pas pareil : contre de l'herbe, un bord de plateau tombe dans le
# vide ; contre une paroi, la roche continue.
#
# ⚠ ET C'EST LA RAISON D'ETRE DE L'EPAULE. Elle n'est dessinee QU'AU SUD, parce que sous un
# bord sud il y a TOUJOURS une falaise -- c'est constant, donc ca vit dans la tuile. Aux
# trois autres bords, ce n'est pas constant : la meme tuile borde tantot de l'herbe, tantot
# de la roche, et elle ne peut pas etre juste dans les deux cas.
#
# Cet outil compte, index par index et bord par bord, les occurrences de chaque espece.
# Un index qui voit les DEUX est un index somme d'etre deux choses a la fois.
#
#     godot --headless --path . --script res://tools/edge_beyond.gd [-- guide]
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Modes := preload("res://core/modes.gd")

const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SIDE_NAMES: Array[String] = ["nord", "est", "sud", "ouest"]
const SIDE_BITS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var guide_path: String = args[0] if args.size() > 0 else Modes.guide_path(Modes.EPAIS)
	var heights: PackedStringArray = HeightMask.read(guide_path)
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)

	# Quelles cases sont couvertes par une paroi, quel que soit l'etage de la levre ?
	var walled: Dictionary = {}
	var assembled: Dictionary = Walls.assemble(heights)
	for key: Vector3i in (assembled["roles"] as Dictionary):
		walled[Vector2i(key.x, key.y)] = true

	# index -> cote -> {"roche": n, "herbe": n}
	var book: Dictionary = {}
	for storage: Vector2i in surface:
		var at: Vector2i = Families.from_storage(Families.BY_CELL, storage)
		var index: int = int(surface[storage])
		for side: int in range(4):
			if (index & SIDE_BITS[side]) != 0:
				continue  # ce bord-la est plein : rien au-dela, la terre continue
			var beyond: Vector2i = at + SIDES[side]
			var kind: String = "roche" if walled.has(beyond) else "herbe"
			if not book.has(index):
				book[index] = {}
			var per_side: Dictionary = book[index]
			if not per_side.has(side):
				per_side[side] = {"roche": 0, "herbe": 0}
			var counts: Dictionary = per_side[side]
			counts[kind] = int(counts[kind]) + 1

	print("AU-DELA DES BORDS VIDES — guide %s" % guide_path)
	print("")
	var torn: int = 0
	var torn_cells: int = 0
	var lines: Array[String] = []
	for index: int in book:
		var per_side: Dictionary = book[index]
		for side: int in per_side:
			var counts: Dictionary = per_side[side]
			var rock: int = int(counts["roche"])
			var grass: int = int(counts["herbe"])
			if rock == 0 or grass == 0:
				continue
			torn += 1
			torn_cells += mini(rock, grass)
			lines.append("   index %3d, bord %-6s : %4d fois contre de la ROCHE, %4d contre de l'HERBE"
					% [index, SIDE_NAMES[side], rock, grass])
	lines.sort()
	for line: String in lines:
		print(line)
	print("")
	print("%d couples (index, bord) voient les DEUX especes." % torn)
	print("La tuile ne peut etre juste que dans l'une : %d cases au moins sont fausses." % torn_cells)
	print("")
	print("Pour comparaison, le bord SUD -- celui de l'epaule :")
	for index: int in book:
		var per_side: Dictionary = book[index]
		if not per_side.has(2):
			continue
		var counts: Dictionary = per_side[2]
		if int(counts["herbe"]) > 0:
			print("   index %3d : %d bords sud SANS falaise dessous -- l'epaule y mentirait"
					% [index, int(counts["herbe"])])
	quit()
