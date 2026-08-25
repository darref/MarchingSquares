# LES ROBES FINES — l'epaisseur s'arrete-t-elle vraiment au relief ?
#
# ⚠ LE MODE EPAIS INTERDIT LES BANDES FINES DANS LE RELIEF. IL N'INTERDIT RIEN DANS LA
# ROBE. Une paroi peut etre large d'UNE colonne en profondeur alors que le relief est
# epais partout : les voisines ont atterri sur une banquette, moi je continue seule. C'est
# exactement le REDAN -- et c'est la meme faute que celle que min trois existe pour
# supprimer, reapparue un cran plus loin.
#
# Une face d'une colonne n'a pas d'interieur : elle est du BORD des deux cotes. Ses tuiles
# sont `(vide,vide)`, `(vide,devant)` et `(devant,vide)` -- celles dont on ne peut rien
# supposer, ni a gauche ni a droite.
#
# Cet outil MESURE, il ne decide pas :
#   -- combien de cases de robe appartiennent a une face d'une colonne, de deux, de trois ;
#   -- sur le guide livre, sur la planche de preuve, et sur des reliefs epais tires au sort ;
#   -- ce que couterait la regle « aucune face plus etroite que trois colonnes ».
#
#     godot --headless --path . --script res://tools/thin_robes.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Families := preload("res://core/families.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Modes := preload("res://core/modes.gd")

const TRIALS: int = 200


## Les largeurs de face, rangee par rangee. Une FACE est l'ensemble des cases d'une meme
## rangee couvertes par des robes lancees de LA MEME LEVRE -- c'est ce que `lip_of` dit, et
## c'est la seule definition qui ne mente pas : deux colonnes de levres differentes sont
## deux parois, meme si elles se touchent.
func _widths(heights: PackedStringArray) -> Dictionary:
	var tally: Dictionary = {}
	var grid_width: int = HeightMask.width(heights)
	var grid_height: int = HeightMask.height(heights)
	for level: int in range(0, HeightMask.top_level(heights) + 1):
		# Meme premiere passe que `Walls.assemble` : la geometrie avant la pose.
		var lip_of: Dictionary = {}
		for y: int in range(grid_height):
			for x: int in range(grid_width):
				if HeightMask.level_at(heights, x, y) < level:
					continue
				if HeightMask.level_at(heights, x, y + 1) >= level:
					continue
				var fall: Vector2i = Walls.fall_at(heights, level, Vector2i(x, y))
				for step: int in range(1, fall.x + 1):
					lip_of[Vector2i(x, y + step)] = y
		# Les courses de meme levre, rangee par rangee.
		for y: int in range(grid_height + Walls.STOREY_TILES * 4):
			var run: int = 0
			var run_lip: int = -9999
			for x: int in range(grid_width + 1):
				var here: Vector2i = Vector2i(x, y)
				var lip: int = int(lip_of.get(here, -9999))
				if lip != -9999 and lip == run_lip:
					run += 1
					continue
				if run > 0:
					tally[run] = int(tally.get(run, 0)) + run
				run = 1 if lip != -9999 else 0
				run_lip = lip
	return tally


## Les cases BORD DES DEUX COTES : aucun flanc muet, donc aucun cote dont la tuile puisse
## supposer quoi que ce soit. C'est la mesure qui compte, et elle n'est PAS la largeur : une
## face d'une seule colonne dont le voisin est DEVANT porte quand meme un flanc muet -- il y
## a bien de la roche a cote, simplement en retrait. Ce qu'on veut interdire, ce n'est pas
## « etre seule », c'est « n'avoir de masse d'aucun cote ».
func _lonely(heights: PackedStringArray, where: Array[String] = []) -> int:
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	var count: int = 0
	for key: Vector3i in roles:
		var role: Vector2i = roles[key]
		if Walls.pan_west(role.x) == Walls.SIDE_MUTE:
			continue
		if Walls.pan_east(role.x) == Walls.SIDE_MUTE:
			continue
		count += 1
		if where.size() < 14:
			where.append("(%d,%d) e%d %s" % [key.x, key.y, key.z, Walls.role_name(role)])
	return count


func _random_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	var columns: int = 22
	var rows: int = 20
	for _try: int in range(40):
		var levels: Array = []
		for y: int in range(rows):
			var line: Array = []
			line.resize(columns)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(3, 6)):
			var w: int = rng.randi_range(3, 7)
			var h: int = rng.randi_range(3, 7)
			var px: int = rng.randi_range(0, columns - w)
			var py: int = rng.randi_range(0, rows - h)
			var lift: int = rng.randi_range(1, 3)
			for y: int in range(py, py + h):
				for x: int in range(px, px + w):
					levels[y][x] = maxi(levels[y][x] as int, lift)
		if rng.randf() < 0.5:
			for _hole: int in range(rng.randi_range(1, 2)):
				var hw: int = rng.randi_range(3, 6)
				var hh: int = rng.randi_range(3, 6)
				var hx: int = rng.randi_range(0, columns - hw)
				var hy: int = rng.randi_range(0, rows - hh)
				for y: int in range(hy, hy + hh):
					for x: int in range(hx, hx + hw):
						levels[y][x] = -1
		var heights: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				var level: int = levels[y][x] as int
				line += "~" if level < 0 else str(level)
			heights.append(line)
		if Thickness.thin_cells(heights).is_empty():
			return heights
	return PackedStringArray()


func _report(label: String, heights: PackedStringArray) -> void:
	var tally: Dictionary = _widths(heights)
	var total: int = 0
	for width: int in tally:
		total += int(tally[width])
	var narrow: int = int(tally.get(1, 0)) + int(tally.get(2, 0))
	print("  %-22s %6d cases de robe | largeur 1 : %5d | largeur 2 : %5d | < 3 : %5.1f %% | pan sans muet : %d"
			% [label, total, int(tally.get(1, 0)), int(tally.get(2, 0)),
			100.0 * float(narrow) / float(maxi(1, total)), _lonely(heights)])


func _initialize() -> void:
	print("LES ROBES FINES — largeur des faces, rangee par rangee")
	print("")
	var guide_path: String = Modes.guide_path(Modes.EPAIS)
	if FileAccess.file_exists(guide_path):
		_report("guide epais", HeightMask.read(guide_path))
	for family: StringName in Families.ids():
		_report("preuve/%s" % family, ProofScene.relief(family))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260825
	var total: int = 0
	var narrow: int = 0
	var lonely: int = 0
	var clean: int = 0
	var drawn: int = 0
	for _t: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if relief.is_empty():
			continue
		drawn += 1
		var tally: Dictionary = _widths(relief)
		var here: int = 0
		for width: int in tally:
			here += int(tally[width])
		total += here
		narrow += int(tally.get(1, 0)) + int(tally.get(2, 0))
		var alone: int = _lonely(relief)
		lonely += alone
		if alone == 0:
			clean += 1
	print("")
	print("  %d reliefs epais tires au sort : %d cases de robe, %d de largeur < 3 (%.1f %%),"
			% [drawn, total, narrow, 100.0 * float(narrow) / float(maxi(1, total))])
	print("  %d cases BORD DES DEUX COTES, et %d reliefs sur %d n'en portent AUCUNE (%.0f %%)."
			% [lonely, clean, drawn, 100.0 * float(clean) / float(maxi(1, drawn))])
	print("")
	print("Ou sont-elles, dans le guide livre :")
	var spots: Array[String] = []
	_lonely(HeightMask.read(guide_path), spots)
	for spot: String in spots:
		print("   " + spot)
	quit()
