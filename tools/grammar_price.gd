# LE PRIX D'UNE CLAUSE DE GRAMMAIRE — chiffrer ce qu'on refuse, pas seulement ce qu'on paie.
#
# ⚠ LE VOCABULAIRE EST CALCULE COMME « TOUT CE QUE LE MODELE PEUT PRODUIRE », JAMAIS COMME
# « CE QU'ON ACCEPTE DE CONSTRUIRE ». C'est la faute de methode de la journee du 25/08 : a
# chaque correctif de justesse, ce qu'une tuile doit savoir s'elargit et le compte se
# multiplie -- 52, 65, 90, 96. La grammaire est une monnaie, ecrite comme telle des le
# premier jour, et depensee une seule fois (min trois), sur le relief seulement.
#
# Cet outil prend des CLAUSES candidates, les applique comme filtre a la battue, et rend le
# vocabulaire qui survit. On choisit alors le sweet spot en regardant des nombres.
#
# ⚠ IL CALCULE LE MODELE CORRIGE LUI-MEME, et c'est voulu. Les deux correctifs mesures --
# le BORD des tuiles de surface, et les LEVRES GLOBALES des pans -- sont justes mais mis de
# cote en attendant cette decision (voir les fiches de CLAUDE.md). Les chiffrer demande de
# les appliquer ; les appliquer avant de choisir serait du travail perime. L'outil porte donc
# sa propre copie, et elle mourra avec lui.
#
# ⚠ ET LES NOMBRES SONT DES RENCONTRES, PAS DES FORMES FERMEES. La forme fermee est toujours
# plus grande -- la battue ne produit pas les silhouettes de coin. Ce qui compte ici n'est
# pas le chiffre absolu mais l'ECART entre deux grammaires, et il est honnete.
#
#     godot --headless --path . --script res://tools/grammar_price.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Coverage := preload("res://core/coverage.gd")
const Families := preload("res://core/families.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Modes := preload("res://core/modes.gd")

const TRIALS: int = 300

## Les clauses, par leur bit.
const CLAUSE_WIDE_FACE: int = 1   ## A -- aucune paroi plus etroite que trois colonnes.
const CLAUSE_ONE_STOREY: int = 2  ## B -- deux faces d'etages differents ne se touchent pas.
const CLAUSE_CHUNKY_LIP: int = 4  ## C -- une levre ne se decale que par blocs de trois.
const CLAUSE_NAMES: Array[String] = [
	"A paroi >= 3 colonnes",
	"B faces d'un seul etage cote a cote",
	"C levre decalee par blocs de 3",
]


## Les levres, GLOBALEMENT : case couverte -> Vector2i(etage de la robe la plus haute,
## rangee de sa levre). Plus une carte par etage, pour retrouver MA propre levre.
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


## Le flanc, avec la comparaison GLOBALE des levres : ce qui situe une face voisine est SA
## LEVRE, pas son etage.
func _side(heights: PackedStringArray, global: Dictionary, at: Vector2i, level: int,
		step: int, my_lip: int) -> int:
	if global.has(at):
		return Walls.SIDE_FRONT if int((global[at] as Vector2i).y) < my_lip \
				else Walls.SIDE_MUTE
	return Walls.SIDE_VOID


## Le vocabulaire qu'un relief exhibe, sous le modele CORRIGE.
func _vocabulary(heights: PackedStringArray, surfaces: Dictionary, roles: Dictionary) -> void:
	var maps: Array = _lips(heights)
	var global: Dictionary = maps[0]
	var by_level: Array = maps[1]
	var walled: Dictionary = Walls.visible_roles(heights)

	# --- LES SURFACES, avec leur BORD.
	var visible: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	for storage: Vector2i in visible:
		var at: Vector2i = Families.from_storage(Families.BY_CELL, storage)
		var index: int = int(visible[storage])
		var edge: int = 0
		var sides: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
		var cardinals: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.W]
		var bits: Array[int] = [1, 2, 4]
		for k: int in range(3):
			if (index & cardinals[k]) != 0:
				continue
			if walled.has(at + sides[k]):
				edge |= bits[k]
		surfaces[index | (edge << 8)] = true

	# --- LES ROBES, avec le pan GLOBAL.
	var posed: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	for key: Vector3i in posed:
		var level: int = key.z
		if level >= by_level.size():
			continue
		var mine: Dictionary = by_level[level]
		var at: Vector2i = Vector2i(key.x, key.y)
		if not mine.has(at):
			continue
		var my_lip: int = int(mine[at])
		var step: int = at.y - my_lip
		var pan: int = Walls.pan_of(
				_side(heights, global, at + Vector2i.LEFT, level, step, my_lip),
				_side(heights, global, at + Vector2i.RIGHT, level, step, my_lip))
		roles[Vector2i(pan, (posed[key] as Vector2i).y)] = true


## --- LES CLAUSES ---------------------------------------------------------------------

## A. Aucune paroi plus etroite que trois colonnes, a aucune profondeur.
func _wide_faces(heights: PackedStringArray) -> bool:
	var by_level: Array = (_lips(heights)[1] as Array)
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights) + Walls.STOREY_TILES * 5
	for level: int in range(by_level.size()):
		var mine: Dictionary = by_level[level]
		for y: int in range(height):
			var run: int = 0
			var run_lip: int = -9999
			for x: int in range(width + 1):
				var lip: int = int(mine.get(Vector2i(x, y), -9999))
				if lip != -9999 and lip == run_lip:
					run += 1
					continue
				if run > 0 and run < 3:
					return false
				run = 1 if lip != -9999 else 0
				run_lip = lip
	return true


## B. Deux faces d'etages differents ne se touchent pas lateralement.
func _one_storey_side_by_side(heights: PackedStringArray) -> bool:
	var global: Dictionary = (_lips(heights)[0] as Dictionary)
	for at: Vector2i in global:
		var here: int = int((global[at] as Vector2i).x)
		var east: Vector2i = at + Vector2i.RIGHT
		if global.has(east) and int((global[east] as Vector2i).x) != here:
			return false
	return true


## C. Une levre ne se decale que par blocs de trois colonnes.
func _chunky_lips(heights: PackedStringArray) -> bool:
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	for level: int in range(0, HeightMask.top_level(heights) + 1):
		var lip_row: Dictionary = {}
		for y: int in range(height):
			for x: int in range(width):
				if HeightMask.level_at(heights, x, y) < level:
					continue
				if HeightMask.level_at(heights, x, y + 1) >= level:
					continue
				lip_row[x] = y
		var run: int = 0
		var last_row: int = -9999
		for x: int in range(width + 1):
			var row: int = int(lip_row.get(x, -9999))
			if row == last_row:
				run += 1
				continue
			if run > 0 and last_row != -9999 and run < 3:
				return false
			run = 1
			last_row = row
	return true


func _legal(heights: PackedStringArray, clauses: int) -> bool:
	if (clauses & CLAUSE_WIDE_FACE) != 0 and not _wide_faces(heights):
		return false
	if (clauses & CLAUSE_ONE_STOREY) != 0 and not _one_storey_side_by_side(heights):
		return false
	if (clauses & CLAUSE_CHUNKY_LIP) != 0 and not _chunky_lips(heights):
		return false
	return true


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


func _initialize() -> void:
	# On tire les reliefs UNE fois, et on les juge sous chaque grammaire : sans ca, deux
	# grammaires seraient comparees sur deux echantillons differents.
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

	print("LE PRIX D'UNE CLAUSE — %d reliefs epais, juges sous chaque grammaire" % pool.size())
	print("")
	print("  %-46s %8s %8s %8s %8s" % ["grammaire", "reliefs", "surfaces", "robes", "total"])
	for clauses: int in range(8):
		var surfaces: Dictionary = {}
		var roles: Dictionary = {}
		var kept: int = 0
		for heights: PackedStringArray in pool:
			if not _legal(heights, clauses):
				continue
			kept += 1
			_vocabulary(heights, surfaces, roles)
		var label: String = "(aucune)"
		if clauses != 0:
			var parts: Array[String] = []
			for bit: int in range(3):
				if (clauses & (1 << bit)) != 0:
					parts.append(CLAUSE_NAMES[bit].substr(0, 1))
			label = " + ".join(parts) + "  "
			for bit: int in range(3):
				if (clauses & (1 << bit)) != 0:
					label = " + ".join(parts)
		print("  %-46s %8d %8d %8d %8d" % [label, kept, surfaces.size(), roles.size(),
				surfaces.size() + roles.size()])
	print("")
	for bit: int in range(3):
		print("  %s" % CLAUSE_NAMES[bit])
	print("")
	print("⚠ Chiffres RENCONTRES, pas formes fermees : la forme fermee est toujours plus")
	print("  grande. Ce qui compte est l'ECART entre deux lignes, pas le chiffre absolu.")
	quit()
