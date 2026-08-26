extends SceneTree

## CE QUE LA DECOMPOSITION EN COUCHES FERAIT TOMBER.
##
## L'IDEE, EN UNE PHRASE : chaque etage et chaque face sur sa propre couche, l'ordre de dessin
## tranche qui passe devant, et **une tuile ne dessine que sa propre matiere** -- jamais rien
## de ce qui est a cote, qui appartient a la couche du voisin.
##
## CE QUE CETTE SEULE REGLE SUPPRIME, et c'est mecanique :
##
##   - LES TROIS ETATS DE FLANC DEVIENNENT DEUX. Aujourd'hui un flanc dit `muet`, `devant` ou
##     `vide` -- et ce soir on allait le porter a quatre, parce que `vide` cache trois choses.
##     Si ma tuile ne dit plus rien de ce qui est a cote, la seule question qui reste est :
##     **ma roche continue-t-elle, ou s'arrete-t-elle ici ?** `devant` et les deux `vide`
##     tombent dans le meme seau.
##
##   - LE BORD D'UNE SURFACE TOMBE AUSSI. Il a ete ajoute ce matin parce qu'un cardinal vide
##     borde du nu ou de la roche, et que le lisere d'epaisseur et l'eclairage de contour ne
##     doivent pas se poser contre de la roche. Ce sont deux marques qui parlent du VOISIN :
##     sous la regle, elles n'ont plus lieu d'etre, et la tuile revient a sa silhouette.
##
## On ne raisonne pas : on compte, sur les memes reliefs que les mesures precedentes.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Coverage := preload("res://core/coverage.gd")
const Modes := preload("res://core/modes.gd")

const CONTINUE: int = 0
const STOP: int = 1


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var two: Dictionary = {}
	var three: Dictionary = {}
	var four: Dictionary = {}
	var surfaces_now: Dictionary = {}
	var surfaces_bare: Dictionary = {}
	var scanned: int = 0
	var layers: int = 0
	var deepest: int = 0
	for round: int in range(3000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		scanned += 1
		var stack: int = HeightMask.top_level(relief) + 1
		layers += stack
		deepest = maxi(deepest, stack)
		for entry: Array in _roles(relief):
			two[entry[0]] = true
			three[entry[1]] = true
			four[entry[2]] = true
		for tile: int in Coverage.index_map(relief).values():
			surfaces_now[tile] = true
			surfaces_bare[BlobIndex.silhouette(tile)] = true

	print("=== CE QUE LA DECOMPOSITION EN COUCHES FERAIT TOMBER ===")
	print("reliefs epais parcourus : %d" % scanned)
	print("")
	print("LES FALAISES")
	print("   3 etats de flanc (aujourd'hui)     : %d roles rencontres   (forme fermee : %d)"
			% [three.size(), Thickness.wall_roles().size()])
	print("   4 etats (dedoubler `vide`)         : %d roles rencontres" % four.size())
	print("   2 etats (couches : continue/stop)  : %d roles rencontres   (%d au plus)"
			% [two.size(), 4 * Walls.BLOCK_ROWS])
	print("")
	print("LES SURFACES")
	print("   avec le BORD (aujourd'hui)         : %d tuiles rencontrees   (forme fermee : %d)"
			% [surfaces_now.size(), Thickness.SURFACE_INDICES.size()])
	print("   sans le bord (couches)             : %d silhouettes" % surfaces_bare.size())
	print("")
	var now_total: int = Thickness.SURFACE_INDICES.size() + Thickness.wall_roles().size()
	print("LE TOTAL, PAR CASE")
	print("   aujourd'hui                        : %d + %d = %d"
			% [Thickness.SURFACE_INDICES.size(), Thickness.wall_roles().size(), now_total])
	print("   en dedoublant `vide`               : %d + %d = %d"
			% [Thickness.SURFACE_INDICES.size(), four.size(),
			Thickness.SURFACE_INDICES.size() + four.size()])
	print("   en couches                         : %d + %d = %d"
			% [surfaces_bare.size(), two.size(), surfaces_bare.size() + two.size()])
	print("")
	print("CE QUE LES COUCHES COUTENT EN RETOUR")
	print("   couches de surface par relief, en moyenne : %.1f   au plus : %d"
			% [float(layers) / maxi(1, scanned), deepest])
	print("   plus une couche de falaise par etage, et une de pose derriere.")
	quit()


## Pour chaque case de robe : son role a 2, 3 et 4 etats de flanc.
func _roles(heights: PackedStringArray) -> Array[Array]:
	var out: Array[Array] = []
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	var highest: Dictionary = {}
	for key: Vector3i in roles.keys():
		var at: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(at) or key.z > int((highest[at] as Vector3i).z):
			highest[at] = key
	for at: Vector2i in highest.keys():
		var key: Vector3i = highest[at]
		var role: Vector2i = roles[key] as Vector2i
		var lip: int = key.z
		var west: int = Walls.pan_west(role.x)
		var east: int = Walls.pan_east(role.x)
		# ⚠ DEUX ETATS : ma roche continue, ou elle s'arrete. C'est tout ce qu'une tuile a le
		# droit de savoir si elle ne dessine que sa propre matiere.
		var w2: int = CONTINUE if west == Walls.SIDE_MUTE else STOP
		var e2: int = CONTINUE if east == Walls.SIDE_MUTE else STOP
		var w4: int = _four(heights, at + Vector2i.LEFT, west, lip)
		var e4: int = _four(heights, at + Vector2i.RIGHT, east, lip)
		out.append([Vector3i(w2, e2, role.y), Vector3i(role.x, role.y, 0),
				Vector3i(w4, e4, role.y)])
	return out


func _four(heights: PackedStringArray, probe: Vector2i, flank: int, lip: int) -> int:
	if flank != Walls.SIDE_VOID:
		return flank
	return 3 if HeightMask.level_at(heights, probe.x, probe.y) >= lip else 4


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
