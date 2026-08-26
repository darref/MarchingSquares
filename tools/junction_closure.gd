extends SceneTree

## LA FORME FERMEE DES RACCORDS -- prouvee, puis eprouvee dans les deux sens.
##
## LE RAISONNEMENT, en trois pas, chacun verifie par la machine plus bas.
##
## 1. UN COTE TOMBE DANS TROIS SEAUX, ET TROIS SEULEMENT. A une case d'etage >= L+1, chaque
##    voisin est soit **plus bas que L** (le contour du bas passe la, et celui du haut aussi),
##    soit **exactement L** (le contour du haut seul : c'est lui qui rentre), soit **>= L+1**
##    (aucun contour). Trois etats, quatre cotes : 81 combinaisons brutes.
##
## 2. LES COTES DU BAS SONT TOUJOURS INCLUS DANS CEUX DU HAUT. Si un voisin est plus bas que
##    L, il est aussi plus bas que L+1. C'est un theoreme, pas une observation -- et c'est lui
##    qui fait qu'un drapeau PAR TUILE suffit : il ne peut jamais exister un cote « mer
##    ouverte » en bas que le haut ne suive pas.
##
## 3. MIN TROIS INTERDIT DEUX COTES OPPOSES EN HAUT. Si le nord ET le sud sont ouverts a
##    l'etage L+1, la case fait une course d'UNE case dans la silhouette de cet etage : elle
##    est fine. Idem est/ouest. Donc l'ensemble du haut porte au plus un cote parmi {N,S} et
##    au plus un parmi {E,O}.
##
## Un raccord demande du bas NON VIDE et du haut STRICTEMENT plus grand : donc le haut a au
## moins deux cotes, donc exactement deux, adjacents -- l'un des quatre coins. Et le bas est
## l'un de ses deux cotes.
##
##     4 coins x 2 = 8. Exhaustif.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")

const N: int = 1
const E: int = 2
const S: int = 4
const O: int = 8
const SIDE_BITS: Array[int] = [N, E, S, O]
const SIDE_NAMES: Array[String] = ["N", "E", "S", "O"]
const SIDE_STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _initialize() -> void:
	var closed: Array[Vector2i] = _closed_form()
	print("=== LA FORME FERMEE ===")
	print("combinaisons brutes (3 seaux, 4 cotes)      : 81")
	print("dont un raccord (du bas ET du rentrant)     : %d" % _raw_junctions())
	print("dont epaisses (pas deux cotes opposes)      : %d" % closed.size())
	for pair: Vector2i in closed:
		print("    bas=%-3s  haut=%-3s" % [_name(pair.x), _name(pair.y)])
	print("")

	var failures: int = 0
	if closed.size() != 8:
		failures += 1
		print("ECHEC : la forme fermee ne donne pas 8.")

	# --- Sens 1 : chacune des 8 est-elle REALISABLE ? Un temoin epais pour chacune.
	print("=== SENS 1 : chaque cas de la forme se rencontre-t-il ? ===")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var witness: Dictionary = {}
	var strays: Dictionary = {}
	var scanned: int = 0
	var junctions: int = 0
	for round: int in range(9000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		scanned += 1
		for found: Vector3i in _junctions(relief):
			junctions += 1
			var pair: Vector2i = Vector2i(found.x, found.y)
			if not _has(closed, pair):
				strays[pair] = int(strays.get(pair, 0)) + 1
			elif not witness.has(pair):
				witness[pair] = relief
	print("reliefs epais parcourus : %d   raccords rencontres : %d" % [scanned, junctions])
	var unseen: Array[Vector2i] = []
	for pair: Vector2i in closed:
		if not witness.has(pair):
			unseen.append(pair)
	if unseen.is_empty():
		print("  les %d cas ont chacun un temoin epais." % closed.size())
	else:
		failures += 1
		print("  ECHEC : %d cas sans temoin :" % unseen.size())
		for pair: Vector2i in unseen:
			print("     bas=%s haut=%s" % [_name(pair.x), _name(pair.y)])

	# --- Sens 2 : le monde produit-il autre chose que les 8 ?
	print("=== SENS 2 : le monde produit-il autre chose ? ===")
	if strays.is_empty():
		print("  aucun raccord hors de la forme.")
	else:
		failures += 1
		print("  ECHEC : %d signature(s) hors forme :" % strays.size())
		for pair: Vector2i in strays.keys():
			print("     bas=%s haut=%s  x%d" % [_name(pair.x), _name(pair.y),
					int(strays[pair])])

	# --- Et sur le guide livre, qui n'est pas du hasard.
	print("=== ET SUR LE GUIDE ===")
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var on_guide: Dictionary = {}
	for found: Vector3i in _junctions(guide):
		var pair: Vector2i = Vector2i(found.x, found.y)
		on_guide[pair] = int(on_guide.get(pair, 0)) + 1
	var guide_strays: int = 0
	for pair: Vector2i in on_guide.keys():
		if not _has(closed, pair):
			guide_strays += 1
	print("  %d raccords, %d signatures, %d hors forme"
			% [_junctions(guide).size(), on_guide.size(), guide_strays])
	if guide_strays > 0:
		failures += 1

	print("")
	print("VERDICT : %s" % ("les 8 sont prouves." if failures == 0
			else "%d echec(s)." % failures))
	quit(1 if failures > 0 else 0)


## Les couples (bas, haut) que le modele autorise -- le raisonnement de l'en-tete, en code.
func _closed_form() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for high: int in range(16):
		# ⚠ MIN TROIS : deux cotes opposes ouverts au meme etage font une course d'une case.
		if (high & N) != 0 and (high & S) != 0:
			continue
		if (high & E) != 0 and (high & O) != 0:
			continue
		for low: int in range(16):
			if low == 0:
				continue              # il faut du contour du bas : sinon rien a rejoindre
			if (low & ~high) != 0:
				continue              # le bas est toujours inclus dans le haut (theoreme)
			if low == high:
				continue              # il faut du rentrant : sinon les deux sont confondus
			out.append(Vector2i(low, high))
	out.sort()
	return out


## Les combinaisons brutes qui sont des raccords, AVANT la regle d'epaisseur.
func _raw_junctions() -> int:
	var count: int = 0
	for high: int in range(16):
		for low: int in range(16):
			if low == 0 or low == high or (low & ~high) != 0:
				continue
			count += 1
	return count


## Les raccords d'un relief : (bas, haut, etage), lus case par case.
func _junctions(heights: PackedStringArray) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var top: int = HeightMask.top_level(heights)
	for level: int in range(1, top + 1):
		for y: int in range(height):
			for x: int in range(width):
				if HeightMask.level_at(heights, x, y) < level + 1:
					continue
				var low: int = 0
				var high: int = 0
				for side: int in range(4):
					var probe: Vector2i = Vector2i(x, y) + SIDE_STEPS[side]
					var beside: int = HeightMask.level_at(heights, probe.x, probe.y)
					if beside < level:
						low |= SIDE_BITS[side]
					if beside < level + 1:
						high |= SIDE_BITS[side]
				if low != 0 and high != low:
					out.append(Vector3i(low, high, level))
	return out


func _has(list: Array[Vector2i], pair: Vector2i) -> bool:
	for item: Vector2i in list:
		if item == pair:
			return true
	return false


func _name(mask: int) -> String:
	if mask == 0:
		return "-"
	var parts: Array[String] = []
	for side: int in range(4):
		if (mask & SIDE_BITS[side]) != 0:
			parts.append(SIDE_NAMES[side])
	return "".join(parts)


## ⚠ DES BLOCS ET DES CREUX, PAS DU BRUIT. Un relief tire case par case n'est jamais epais ;
## et sans creux, on ne rencontre ni coude ni rentrant. La lecon est deja au dossier.
func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = rng.randi_range(12, 18)
	var h: int = rng.randi_range(12, 18)
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
