# CE QUE PORTE UNE CASE, ET CE QUE SES JUMELLES EXIGENT D'ELLE.
#
# ⚠ UNE TUILE PARTAGEE N'A QU'UNE IMAGE. Partout ou deux occurrences de la MEME tuile
# demandent matiere ici et transparence la, le partage ne suffit plus : il faut que le
# MOTEUR pose la vraie matiere derriere (famille sous-pied / pose derriere / chapiteau sous
# sa levre). Cet outil sert a trouver ces desaccords-la, case par case.
#
#     godot --headless --path . --script res://tools/inspect_cell.gd -- x y [guide]
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Coverage := preload("res://core/coverage.gd")
const Families := preload("res://core/families.gd")
const Modes := preload("res://core/modes.gd")
const BlobIndex := preload("res://core/blob_index.gd")


func _around(heights: PackedStringArray, at: Vector2i) -> String:
	var out: String = ""
	for dy: int in range(-2, 3):
		var line: String = "      "
		for dx: int in range(-3, 4):
			var level: int = HeightMask.level_at(heights, at.x + dx, at.y + dy)
			var glyph: String = "~" if level < 0 else str(level)
			if dx == 0 and dy == 0:
				glyph = "[" + glyph + "]"
			else:
				glyph = " " + glyph + " "
			line += glyph
		out += line + "\n"
	return out


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage : -- x y [guide]")
		quit(1)
		return
	var at: Vector2i = Vector2i(int(args[0]), int(args[1]))
	var guide_path: String = args[2] if args.size() > 2 else Modes.guide_path(Modes.EPAIS)
	var heights: PackedStringArray = HeightMask.read(guide_path)

	print("GUIDE %s  (%d x %d)" % [guide_path, HeightMask.width(heights),
			HeightMask.height(heights)])
	print("relief autour de (%d, %d) :" % [at.x, at.y])
	print(_around(heights, at))

	var assembled: Dictionary = Walls.assemble(heights)
	var roles: Dictionary = assembled["roles"]
	var underfoot: Dictionary = assembled["underfoot"]
	var level: int = HeightMask.level_at(heights, at.x, at.y)
	print("etage de la case : %d" % level)
	for storey: int in range(0, HeightMask.top_level(heights) + 1):
		var key: Vector3i = Vector3i(at.x, at.y, storey)
		if roles.has(key):
			print("  robe d'etage %d : %s" % [storey, Walls.role_name(roles[key])])
		if underfoot.has(key):
			print("  pose derriere d'etage %d : %s" % [storey,
					Walls.role_name(underfoot[key])])

	# La tuile de SURFACE que la case porte, et ses jumelles.
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var storage: Vector2i = Families.storage_key(Families.BY_CELL, at)
	if not surface.has(storage):
		print("  (aucune tuile de surface : la case porte une robe, ou rien)")
	else:
		var index: int = int(surface[storage])
		print("")
		print("TUILE DE SURFACE : index %d  (%s)" % [index,
				Families.describe(Families.BY_CELL, index)])
		var twins: Array[Vector2i] = []
		for other: Vector2i in surface:
			if int(surface[other]) == index:
				twins.append(other)
		twins.sort()
		print("  %d jumelles -- toutes le MEME dessin." % twins.size())
		# Ce qui differe d'une jumelle a l'autre : ce qu'il y a AU SUD et EN DESSOUS.
		var south_kinds: Dictionary = {}
		for twin: Vector2i in twins:
			var twin_level: int = HeightMask.level_at(heights, twin.x, twin.y)
			var south: int = HeightMask.level_at(heights, twin.x, twin.y + 1)
			var kind: String = ""
			if south >= twin_level:
				kind = "du sol de son etage"
			elif Walls.assemble(heights) != null and south < twin_level:
				kind = "une FALAISE (levre sud)"
			south_kinds[kind] = int(south_kinds.get(kind, 0)) + 1
		print("  au sud de ces jumelles :")
		for kind: String in south_kinds:
			print("     %-28s x %d" % [kind, int(south_kinds[kind])])
		var below_kinds: Dictionary = {}
		for twin: Vector2i in twins:
			var twin_level: int = HeightMask.level_at(heights, twin.x, twin.y)
			below_kinds["etage %d" % twin_level] = int(
					below_kinds.get("etage %d" % twin_level, 0)) + 1
		print("  etages de ces jumelles :")
		for kind: String in below_kinds:
			print("     %-28s x %d" % [kind, int(below_kinds[kind])])
	quit()
