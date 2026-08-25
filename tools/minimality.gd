# LE MINIMUM DEMONTRE — chaque distinction porte-t-elle vraiment quelque chose ?
#
# ⚠ ON A PASSE LA JOURNEE A AJOUTER DES DISTINCTIONS parce que le dessin en manquait. On n'a
# jamais verifie qu'une SEULE d'entre elles etait necessaire. Or c'est le meme detecteur,
# retourne :
#
#   on RETIRE une distinction de l'identite d'une tuile, et on relance l'accord.
#     -- il reste muet  -> la distinction ne portait rien : on la retire, rien n'est perdu ;
#     -- il crie        -> elle est necessaire, et on a la PREUVE, pas l'intuition.
#
# « Minimum » ne veut pas dire « petit » : ca veut dire qu'aucune tuile ne pourrait etre
# fusionnee avec une autre. Que ca fasse soixante ou quatre-vingt-seize, ce sera le bon
# nombre, et on saura pourquoi.
#
# ⚠ UNE EXCLUSION A POSER D'EMBLEE : le NOMBRE DE RANGEES DE CORPS n'est pas paye pour la
# justesse, il est paye pour le VAGABONDAGE DE L'ARETE. Ce detecteur dira « deux rangees
# suffisent » -- il aura raison sur la justesse et tort sur le produit. Cette ligne-la se
# decide a l'oeil, et elle l'a ete. Toutes les autres, non.
#
# ⚠ ET IL PORTE SA PROPRE COPIE DU MODELE CORRIGE -- le BORD des surfaces et les LEVRES
# GLOBALES des pans -- parce que ces deux correctifs sont mesures mais mis de cote en
# attendant cette decision. Voir les fiches de CLAUDE.md.
#
#     godot --headless --path . --script res://tools/minimality.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Modes := preload("res://core/modes.gd")

const TRIALS: int = 200

const BRINK_SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
const BRINK_CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.W]
const BRINK_NAMES: Array[String] = ["nord", "est", "ouest"]

## Une occurrence de surface : sa silhouette, son bord complet, et la verite complete de ses
## quatre cardinaux.
var _surface_seen: Array = []
## Une occurrence de robe : son pan complet, sa rangee, et la verite complete de ses flancs
## et de ses voisines verticales.
var _robe_seen: Array = []


func _lips(heights: PackedStringArray) -> Array:
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var global: Dictionary = {}
	var by_level: Array = []
	for level: int in range(0, HeightMask.top_level(heights) + 1):
		var mine: Dictionary = {}
		for y: int in range(height):
			for x: int in range(width):
				if HeightMask.level_at(heights, x, y) < level:
					continue
				if HeightMask.level_at(heights, x, y + 1) >= level:
					continue
				var fall: Vector2i = Walls.fall_at(heights, level, Vector2i(x, y))
				for step: int in range(1, fall.x + 1):
					var at: Vector2i = Vector2i(x, y + step)
					mine[at] = y
					if not global.has(at) or int((global[at] as Vector2i).x) < level:
						global[at] = Vector2i(level, y)
		by_level.append(mine)
	return [global, by_level]


## Ce qu'il y a au-dela d'un cardinal, a MON altitude. `C` contigu, `R` roche, `.` le reste.
func _beyond(heights: PackedStringArray, walled: Dictionary, at: Vector2i,
		altitude: int) -> String:
	var level: int = HeightMask.level_at(heights, at.x, at.y)
	if level >= altitude and level >= 0:
		return "C"
	return "R" if walled.has(at) else "."


func _gather(heights: PackedStringArray) -> void:
	var walled: Dictionary = Walls.visible_roles(heights)
	var visible: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	for storage: Vector2i in visible:
		var at: Vector2i = Families.from_storage(Families.BY_CELL, storage)
		var index: int = int(visible[storage])
		var altitude: int = HeightMask.level_at(heights, at.x, at.y)
		var edge: int = 0
		var truth: String = ""
		for k: int in range(3):
			if (index & BRINK_CARDINALS[k]) != 0:
				truth += "C"
				continue
			var kind: String = _beyond(heights, walled, at + BRINK_SIDES[k], altitude)
			truth += kind
			if kind == "R":
				edge |= 1 << k
		_surface_seen.append([index, edge, truth])

	var maps: Array = _lips(heights)
	var global: Dictionary = maps[0]
	var by_level: Array = maps[1]
	var posed: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	for key: Vector3i in posed:
		var level: int = key.z
		if level >= by_level.size():
			continue
		var mine: Dictionary = by_level[level]
		var cell: Vector2i = Vector2i(key.x, key.y)
		if not mine.has(cell):
			continue
		var my_lip: int = int(mine[cell])
		var role: Vector2i = posed[key]
		# ⚠ LE PAN SE RECALCULE ICI, avec les levres GLOBALES. Celui que rend `assemble` est
		# encore celui des levres par etage -- le correctif est mesure mais mis de cote en
		# attendant cette decision. Le comparer a une verite globale ferait crier l'outil
		# sur tout, et pour une raison qui n'est pas celle qu'il cherche.
		var flanks: String = ""
		var states: Array[int] = []
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			var beside: Vector2i = cell + offset
			if not global.has(beside):
				flanks += "."
				states.append(Walls.SIDE_VOID)
			else:
				var lip: int = int((global[beside] as Vector2i).y)
				if lip >= my_lip:
					flanks += "M"
					states.append(Walls.SIDE_MUTE)
				else:
					flanks += "D"
					states.append(Walls.SIDE_FRONT)
		role = Vector2i(Walls.pan_of(states[0], states[1]), role.y)
		# Ce qu'il y a AU-DESSUS : la levre, ou une autre case de la meme face.
		#
		# ⚠ ET RIEN SUR LE DESSOUS. Ce qu'il y a sous ma derniere rangee -- une autre case de
		# face, ou la case qui m'ecrete -- n'est PAS dans ma case : ma rangee du bas
		# appartient a une classe de raccord partagee, donc je la dessine pareil dans les
		# deux cas. Le mettre dans la verite faisait crier l'outil sur une difference qui est
		# entierement chez le voisin.
		var above: String = "L" if cell.y == my_lip + 1 else "F"
		_robe_seen.append([role.x, role.y, flanks + above])


func _random_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	for _try: int in range(40):
		var columns: int = 24
		var rows: int = 22
		var levels: Array = []
		for y: int in range(rows):
			var line: Array = []
			line.resize(columns)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(3, 7)):
			var w: int = rng.randi_range(3, 8)
			var h: int = rng.randi_range(3, 8)
			var px: int = rng.randi_range(0, columns - w)
			var py: int = rng.randi_range(0, rows - h)
			var lift: int = rng.randi_range(1, 3)
			for y: int in range(py, py + h):
				for x: int in range(px, px + w):
					levels[y][x] = maxi(levels[y][x] as int, lift)
		var heights: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				line += str(levels[y][x] as int)
			heights.append(line)
		if Thickness.thin_cells(heights).is_empty():
			return heights
	return PackedStringArray()


## Le verdict pour une identite reduite : combien de tuiles, et est-elle encore d'accord ?
func _judge(label: String, groups: Dictionary) -> void:
	var faults: int = 0
	var sample: String = ""
	for key: Variant in groups:
		var truths: Dictionary = groups[key]
		if truths.size() > 1:
			faults += 1
			if sample == "":
				var order: Array = truths.keys()
				order.sort()
				sample = " (%s : %s)" % [str(key), ", ".join(order)]
	var verdict: String = "NECESSAIRE -- %d tuiles se contredisent%s" % [faults, sample] \
			if faults > 0 else "INUTILE -- rien ne se contredit"
	print("  %-44s %4d tuiles   %s" % [label, groups.size(), verdict])


func _initialize() -> void:
	var pool: Array[PackedStringArray] = []
	pool.append(HeightMask.read(Modes.guide_path(Modes.EPAIS)))
	for family: StringName in Families.ids():
		pool.append(ProofScene.relief(family))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260825
	for _t: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if not relief.is_empty():
			pool.append(relief)
	for heights: PackedStringArray in pool:
		_gather(heights)

	print("LE MINIMUM DEMONTRE — %d reliefs, %d cases de surface, %d cases de robe"
			% [pool.size(), _surface_seen.size(), _robe_seen.size()])
	print("")
	print("SURFACES — on retire un bit du bord, et on regarde si les occurrences se")
	print("contredisent encore.")
	for keep: int in range(8):
		var groups: Dictionary = {}
		for row: Array in _surface_seen:
			var key: int = int(row[0]) | ((int(row[1]) & keep) << 8)
			if not groups.has(key):
				groups[key] = {}
			(groups[key] as Dictionary)[String(row[2])] = true
		var parts: Array[String] = []
		for k: int in range(3):
			if (keep & (1 << k)) != 0:
				parts.append(BRINK_NAMES[k])
		_judge("bord garde : " + ("aucun" if parts.is_empty() else " ".join(parts)), groups)

	print("")
	print("ROBES — on grossit le pan, puis la rangee.")
	for coarse: int in range(2):
		for rows: int in range(3):
			var groups: Dictionary = {}
			for row: Array in _robe_seen:
				var pan: int = int(row[0])
				var west: int = Walls.pan_west(pan)
				var east: int = Walls.pan_east(pan)
				if coarse == 1:
					# `devant` fondu dans `muet` : de la roche, sans plus.
					west = Walls.SIDE_MUTE if west == Walls.SIDE_FRONT else west
					east = Walls.SIDE_MUTE if east == Walls.SIDE_FRONT else east
				var line: int = int(row[1])
				if rows == 1:
					# chapiteau / corps / pied, sans distinguer les corps entre eux.
					line = 0 if line == Walls.ROW_CROWN \
							else (2 if line == Walls.ROW_FOOT else 1)
				elif rows == 2:
					line = 0
				var key: Vector2i = Vector2i(Walls.pan_of(west, east), line)
				if not groups.has(key):
					groups[key] = {}
				(groups[key] as Dictionary)[String(row[2])] = true
			var names: Array[String] = ["cinq rangees", "chapiteau/corps/pied", "une rangee"]
			_judge("pan %s, %s" % ["grossier" if coarse == 1 else "complet", names[rows]],
					groups)
	print("")
	print("⚠ Le NOMBRE de rangees de corps n'est pas juge ici : il est paye pour le")
	print("  vagabondage de l'arete, pas pour la justesse.")
	quit()
