# DE QUOI EST FAIT LE BORD D'UNE TUILE — et combien de tuiles ca ferait de le dire.
#
# ⚠ UN BORD VIDE NE VEUT PAS TOUJOURS DIRE UNE CHUTE. C'est ce que je croyais, et c'est
# faux. Quand la case d'a cote est couverte par une FACE, cette face a son sommet au niveau
# de mon propre sol : la roche continue de plain-pied, il n'y a aucune marche. Quand elle
# est nue, il y a bien une chute d'un etage au moins. Deux choses opposees derriere le meme
# bord, et une seule image pour les dire.
#
#   BORD DE TROU  la voisine est couverte par une face : la roche CONTINUE ;
#   PROLONGEMENT  la voisine est nue : le plateau DEPASSE, et ca tombe.
#
# Cet outil compte, index par index, quelles COMBINAISONS d'especes se rencontrent sur les
# bords vides -- car un index a un, deux, trois ou quatre bords vides, et chacun peut etre
# de l'une ou l'autre espece. Le nombre de tuiles qu'il faudrait est la somme, sur les 27
# index, des combinaisons REELLEMENT rencontrees. Le deviner, c'est se tromper : « un de
# chaque » suppose qu'un index n'a qu'un bord vide, ce qui est faux pour huit d'entre eux.
#
#     godot --headless --path . --script res://tools/brink_kinds.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Modes := preload("res://core/modes.gd")

const TRIALS: int = 500
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SIDE_BITS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
const SIDE_NAMES: Array[String] = ["N", "E", "S", "O"]


func _gather(heights: PackedStringArray, book: Dictionary) -> void:
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var walled: Dictionary = {}
	for key: Vector3i in (Walls.assemble(heights)["roles"] as Dictionary):
		walled[Vector2i(key.x, key.y)] = true
	for storage: Vector2i in surface:
		var at: Vector2i = Families.from_storage(Families.BY_CELL, storage)
		var index: int = int(surface[storage])
		# Le masque des bords « bord de trou » : un bit par cote vide dont la voisine est
		# couverte par une face.
		var mask: int = 0
		for side: int in range(4):
			if (index & SIDE_BITS[side]) != 0:
				continue
			if walled.has(at + SIDES[side]):
				mask |= 1 << side
		if not book.has(index):
			book[index] = {}
		var seen: Dictionary = book[index]
		seen[mask] = int(seen.get(mask, 0)) + 1


func _random_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	var columns: int = 26
	var rows: int = 24
	for _try: int in range(40):
		var levels: Array = []
		for y: int in range(rows):
			var line: Array = []
			line.resize(columns)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(3, 8)):
			var w: int = rng.randi_range(3, 8)
			var h: int = rng.randi_range(3, 8)
			var px: int = rng.randi_range(0, columns - w)
			var py: int = rng.randi_range(0, rows - h)
			var lift: int = rng.randi_range(1, 4)
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


func _mask_name(index: int, mask: int) -> String:
	var out: String = ""
	for side: int in range(4):
		if (index & SIDE_BITS[side]) != 0:
			continue
		out += SIDE_NAMES[side] + ("=trou " if (mask & (1 << side)) != 0 else "=nu ")
	return out if out != "" else "(aucun bord vide)"


func _initialize() -> void:
	var book: Dictionary = {}
	_gather(HeightMask.read(Modes.guide_path(Modes.EPAIS)), book)
	for family: StringName in Families.ids():
		_gather(ProofScene.relief(family), book)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260825
	var drawn: int = 0
	for _t: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if relief.is_empty():
			continue
		drawn += 1
		_gather(relief, book)

	print("DE QUOI EST FAIT LE BORD — guide, planches de preuve, %d reliefs epais" % drawn)
	print("")
	var tiles: int = 0
	var split: int = 0
	var keys: Array = book.keys()
	keys.sort()
	for index: int in keys:
		var seen: Dictionary = book[index]
		tiles += seen.size()
		if seen.size() > 1:
			split += 1
			var parts: Array[String] = []
			var masks: Array = seen.keys()
			masks.sort()
			for mask: int in masks:
				parts.append("%s(x%d)" % [_mask_name(index, mask), int(seen[mask])])
			print("   index %3d -> %d especes : %s" % [index, seen.size(),
					" | ".join(parts)])
	print("")
	# ⚠ LA FORME FERMEE : le SUD est toujours `trou` -- une case dont le sud est vide est
	# une levre, et sa propre face couvre la case d'en dessous. C'est un theoreme. Le nord,
	# l'est et l'ouest, eux, sont libres : chacun peut etre couvert ou nu.
	var promised: int = 0
	for index: int in Thickness.SURFACE_INDICES:
		var free_sides: int = 0
		for side: int in range(4):
			if side == 2:
				continue  # le sud est toujours couvert
			if (index & SIDE_BITS[side]) == 0:
				free_sides += 1
		promised += 1 << free_sides
	print("%d index rencontres, %d d'entre eux voient PLUSIEURS especes." % [keys.size(), split])
	print("FORME FERMEE (sud toujours couvert, N/E/O libres) : %d tuiles." % promised)
	print("Tuiles de surface s'il faut une image par espece rencontree : %d (au lieu de %d)."
			% [tiles, keys.size()])
	quit()
