extends SceneTree

## LA FORME FERMEE DES FALAISES -- le pendant exact de `junction_closure.gd`.
##
## LA TRANSPOSITION. Pour un plateau, un cote voyait trois seaux : plus bas que L, exactement
## L, plus haut. Pour une case de FACE, un cote voit :
##   - la MEME face        -- de la roche qui continue, aucun contour ;
##   - une AUTRE face      -- de la roche, mais celle d'une falaise a une autre profondeur ;
##   - RIEN               -- du nu : c'est la que passe le contour du cadre.
## Trois seaux, quatre cotes : 81 combinaisons brutes, comme pour les plateaux.
##
## CE QUE MIN TROIS INTERDIT, et c'est le meme argument aux deux axes :
##   - nu au NORD **et** au SUD : la chute ferait UNE case. Or une chute vaut au moins un
##     etage, soit trois cases. Impossible.
##   - nu a l'EST **et** a l'OUEST : la face ferait UNE colonne. Or elle est engendree par une
##     levre, et une levre d'une colonne demanderait un plateau d'une colonne. Impossible.
## Donc le masque du NU porte au plus un cote parmi {N,S} et un parmi {E,O} : neuf masques.
##
## On mesure, puis on ferme -- et on eprouve dans les deux sens, comme pour les 8.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const BlobIndex := preload("res://core/blob_index.gd")

const N: int = 1
const E: int = 2
const S: int = 4
const O: int = 8
const SIDE_BITS: Array[int] = [N, E, S, O]
const SIDE_NAMES: Array[String] = ["N", "E", "S", "O"]
const SIDE_STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _initialize() -> void:
	print("=== LA FORME FERMEE ===")
	var closed: Array[Vector2i] = _closed_form()
	print("combinaisons brutes (3 seaux, 4 cotes)        : 81")
	print("dont le NU n'a pas deux cotes opposes         : %d" % _thick_masks().size())
	print("couples (nu, autre face) de la forme          : %d" % closed.size())
	for pair: Vector2i in closed:
		print("    nu=%-3s  autre=%-3s" % [_name(pair.x), _name(pair.y)])
	print("")

	var failures: int = 0
	print("=== LA BATTUE ===")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var seen: Dictionary = {}
	var strays: Dictionary = {}
	var scanned: int = 0
	var cells: int = 0
	var frames: Dictionary = {}
	for round: int in range(4000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		scanned += 1
		for entry: Array in _read(relief):
			var sig: Vector2i = entry[0] as Vector2i
			cells += 1
			seen[sig] = int(seen.get(sig, 0)) + 1
			frames[int(entry[1])] = int(frames.get(int(entry[1]), 0)) + 1
			if not _has(closed, sig):
				strays[sig] = int(strays.get(sig, 0)) + 1
	print("reliefs epais : %d   cases de face : %d" % [scanned, cells])
	print("  signatures (nu, autre face)                 : %d" % seen.size())
	print("  CADRES distincts, en 8 bits canonicalises   : %d sur 47" % frames.size())
	var missing_frames: Array[int] = []
	for index: int in BlobIndex.CANONICAL_INDICES:
		if not frames.has(index):
			missing_frames.append(index)
	print("  les %d index jamais rencontres par un cadre : %s"
			% [missing_frames.size(), str(missing_frames.slice(0, 12))])

	print("")
	print("=== SENS 1 : chaque cas de la forme se rencontre-t-il ? ===")
	var unseen: Array[Vector2i] = []
	for pair: Vector2i in closed:
		if not seen.has(pair):
			unseen.append(pair)
	if unseen.is_empty():
		print("  les %d cas sont tous rencontres." % closed.size())
	else:
		print("  %d cas de la forme JAMAIS rencontres :" % unseen.size())
		for pair: Vector2i in unseen:
			print("     nu=%s autre=%s" % [_name(pair.x), _name(pair.y)])

	print("=== SENS 2 : le monde produit-il autre chose ? ===")
	if strays.is_empty():
		print("  aucune signature hors de la forme.")
	else:
		failures += 1
		print("  ECHEC : %d signature(s) hors forme :" % strays.size())
		var order: Array = strays.keys()
		order.sort_custom(func(a: Variant, b: Variant) -> bool:
			return int(strays[a]) > int(strays[b]))
		for pair: Variant in order:
			print("     nu=%s autre=%s  x%d" % [_name((pair as Vector2i).x),
					_name((pair as Vector2i).y), int(strays[pair])])

	print("")
	print("=== LE DETAIL : ce que la battue rencontre, par frequence ===")
	var order: Array = seen.keys()
	order.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(seen[a]) > int(seen[b]))
	for i: int in range(order.size()):
		var pair: Vector2i = order[i] as Vector2i
		print("    nu=%-3s autre=%-3s  x%d" % [_name(pair.x), _name(pair.y), int(seen[pair])])

	print("")
	print("=== ET SUR LE GUIDE ===")
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var on_guide: Dictionary = {}
	for sig: Vector2i in _signatures(guide):
		on_guide[sig] = int(on_guide.get(sig, 0)) + 1
	var guide_strays: int = 0
	for pair: Vector2i in on_guide.keys():
		if not _has(closed, pair):
			guide_strays += 1
	print("  %d signatures, %d hors forme" % [on_guide.size(), guide_strays])
	if guide_strays > 0:
		failures += 1
	print("")
	print("VERDICT : %s" % ("la forme tient dans les deux sens." if failures == 0
			else "%d echec(s)." % failures))
	quit(1 if failures > 0 else 0)


## Les masques de NU qu'une face peut porter : jamais deux cotes opposes.
func _thick_masks() -> Array[int]:
	var out: Array[int] = []
	for mask: int in range(16):
		# ⚠ N ET S ENSEMBLE : la chute ferait UNE case, or elle vaut au moins un etage.
		if (mask & N) != 0 and (mask & S) != 0:
			continue
		# ⚠ ET E/O ENSEMBLE EST POSSIBLE -- le REDAN. Une colonne qui plonge seule sous ses
		# voisines fait une face d'UNE colonne. Je l'avais exclue par analogie avec min trois :
		# la mesure l'a refutee, 226 fois.
		out.append(mask)
	return out


## La forme : un masque de nu, et parmi les cotes RESTANTS, ceux qui touchent une autre face.
func _closed_form() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for bare: int in _thick_masks():
		var free: int = 15 & ~bare
		var other: int = 0
		while true:
			out.append(Vector2i(bare, other))
			if other == free:
				break
			other = (other - free) & free       # sous-ensembles de `free`, en ordre
		out.append(Vector2i(bare, free))
	var unique: Dictionary = {}
	for pair: Vector2i in out:
		unique[pair] = true
	var final: Array[Vector2i] = []
	for pair: Vector2i in unique.keys():
		final.append(pair)
	final.sort()
	return final


## Les signatures d'un relief : pour chaque case de face visible, (nu, autre face).
##
## ⚠ ET LE CADRE SE LIT AUSSI EN HUIT BITS, comme un plateau. La question n'est pas la meme
## que celle du relief : ici la region est celle des cases COUVERTES PAR UNE FACE. Son
## contour a-t-il besoin de ses coins rentrants ? On canonicalise comme le blob -- une
## diagonale ne compte que si ses deux cardinales sont pleines -- et on compte.
func _signatures(heights: PackedStringArray) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for entry: Array in _read(heights):
		out.append(entry[0] as Vector2i)
	return out


## La lecture complete : [(nu, autre), index du cadre en 8 bits canonicalise]
func _read(heights: PackedStringArray) -> Array[Array]:
	var out: Array[Array] = []
	var visible: Dictionary = {}
	var assembled: Dictionary = Walls.assemble(heights)
	var roles: Dictionary = assembled["roles"]
	for key: Vector3i in roles.keys():
		var at: Vector2i = Vector2i(key.x, key.y)
		if not visible.has(at) or key.z > int(visible[at]):
			visible[at] = key.z
	for at: Vector2i in visible.keys():
		var mine: int = int(visible[at])
		var bare: int = 0
		var other: int = 0
		for side: int in range(4):
			var probe: Vector2i = at + SIDE_STEPS[side]
			if not visible.has(probe):
				bare |= SIDE_BITS[side]
			elif int(visible[probe]) != mine:
				other |= SIDE_BITS[side]
		var raw: int = 0
		for bit: int in range(8):
			if visible.has(at + BlobIndex.OFFSETS[bit]):
				raw |= BlobIndex.BITS[bit]
		out.append([Vector2i(bare, other), BlobIndex.canonicalize(raw)])
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
