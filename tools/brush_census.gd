extends SceneTree

## LE RECENSEMENT DU PINCEAU : ce que l'ALPHABET REEL de l'acheteur produit.
##
## ⚠ LE VOCABULAIRE N'EST PAS « TOUT RELIEF EPAIS », C'EST « TOUT RELIEF QUE LE PINCEAU PEUT
## FAIRE ». SoluPaint pose des tampons 3x3 et efface en 3x3, et refuse tout geste qui
## laisserait une case fine. Une battue qui tire des rectangles au hasard cherche donc dans
## un ensemble qui n'est pas celui-la : elle peut fabriquer des tuiles que personne ne pourra
## jamais poser -- et alors on peine a les mettre au guide, ce qui est le symptome.
##
## On simule donc le geste : un tampon, un etage, un refus si ca devient fin.

const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const HeightMask := preload("res://core/height_mask.gd")

const BOARD: int = 16
const MARGIN: int = 3


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260825
	var seen: Dictionary = {}
	var witness: Dictionary = {}
	var roles: Dictionary = {}
	var reliefs: Array[PackedStringArray] = []
	var carried: Array[Dictionary] = []
	var strokes: int = 0
	var refused: int = 0
	for run: int in range(2600):
		var grid: Array[PackedByteArray] = _empty()
		for gesture: int in range(rng.randi_range(6, 30)):
			var level: int = rng.randi_range(-1, 3)
			# ⚠ UNE MAIN POSE ALIGNE, LE HASARD NON. Un tampon 3x3 pose a un decalage
			# quelconque laisse presque toujours une case fine -- 47 % des gestes refuses --
			# et la battue passe son temps a se faire dire non au lieu de chercher. Une main
			# accole ses tampons ; on tire donc surtout des poses alignees sur trois, et
			# quelques-unes decalees pour ne pas s'interdire ce qu'une main fait aussi.
			var ox: int = rng.randi_range(MARGIN, BOARD - MARGIN - 3)
			var oy: int = rng.randi_range(MARGIN, BOARD - MARGIN - 3)
			if rng.randf() < 0.8:
				ox = MARGIN + ((ox - MARGIN) / 3) * 3
				oy = MARGIN + ((oy - MARGIN) / 3) * 3
			var before: Array[PackedByteArray] = _copy(grid)
			for y: int in range(oy, oy + 3):
				for x: int in range(ox, ox + 3):
					var row: PackedByteArray = grid[y]
					row[x] = level + 1
					grid[y] = row
			strokes += 1
			# LE REFUS DU PINCEAU : un geste qui laisse une case fine ne se pose pas.
			if not Thickness.thin_cells(_text(grid)).is_empty():
				grid = before
				refused += 1
				continue
			var heights: PackedStringArray = _text(grid)
			var tiles: Dictionary = {}
			for tile: int in Coverage.index_map(heights).values():
				seen[tile] = int(seen.get(tile, 0)) + 1
				tiles[tile] = true
				if not witness.has(tile):
					witness[tile] = heights
			for role: Vector2i in Walls.visible_roles(heights).values():
				roles[role] = int(roles.get(role, 0)) + 1
			reliefs.append(heights)
			carried.append(tiles)
	var closed: Dictionary = {}
	for tile: int in Thickness.SURFACE_INDICES:
		closed[tile] = true
	var extra: Array[int] = []
	var never: Array[int] = []
	for tile: int in seen.keys():
		if not closed.has(tile):
			extra.append(tile)
	for tile: int in closed.keys():
		if not seen.has(tile):
			never.append(tile)
	extra.sort()
	never.sort()
	print("gestes tentes : %d   refuses (fins) : %d   etats retenus : %d"
			% [strokes, refused, reliefs.size()])
	print("forme fermee : %d   rencontrees par le pinceau : %d"
			% [closed.size(), seen.size()])
	print("roles de falaise rencontres : %d sur %d" % [roles.size(), Thickness.wall_roles().size()])
	print("")
	print("LE PINCEAU FABRIQUE, HORS DE LA FORME : %d" % extra.size())
	for tile: int in extra:
		print("  %3d %s  x%d" % [BlobIndex.silhouette(tile), BlobIndex.brink_name(tile),
				int(seen[tile])])
	print("")
	print("DANS LA FORME, LE PINCEAU NE LES ATTEINT JAMAIS : %d" % never.size())
	for tile: int in never:
		print("  %3d %s" % [BlobIndex.silhouette(tile), BlobIndex.brink_name(tile)])
	# La couverture gloutonne, pour le guide.
	var missing: Dictionary = {}
	for tile: int in seen.keys():
		missing[tile] = true
	var chosen: Array[int] = []
	while not missing.is_empty():
		var best: int = -1
		var best_score: int = 0
		for i: int in range(reliefs.size()):
			var score: int = 0
			for tile: int in carried[i].keys():
				if missing.has(tile):
					score += 1
			if score > best_score:
				best_score = score
				best = i
		if best < 0:
			break
		chosen.append(best)
		for tile: int in carried[best].keys():
			missing.erase(tile)
	print("")
	print("TEMOINS SUFFISANTS : %d reliefs de %dx%d" % [chosen.size(), BOARD, BOARD])
	# ⚠ UN TEMOIN PAR TUILE, DANS LE FORMAT QUE LE CONVERTISSEUR ATTEND.
	var proof: String = ""
	var order: Array = witness.keys()
	order.sort()
	for tile: Variant in order:
		proof += "# %d %s
" % [int(tile), BlobIndex.brink_name(int(tile))]
		for line: String in witness[tile] as PackedStringArray:
			proof += "%s
" % line
		proof += "
"
	var proof_file: FileAccess = FileAccess.open("res://tools/brush_reach.txt", FileAccess.WRITE)
	proof_file.store_string(proof)
	proof_file.close()
	var text: String = ""
	for i: int in chosen:
		text += "\tPackedStringArray([\n"
		for line: String in reliefs[i]:
			text += "\t\t\"%s\",\n" % line
		text += "\t]),\n"
	var file: FileAccess = FileAccess.open("res://tools/brush_witnesses.txt", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	quit()


func _empty() -> Array[PackedByteArray]:
	var grid: Array[PackedByteArray] = []
	for y: int in range(BOARD):
		var row: PackedByteArray = PackedByteArray()
		row.resize(BOARD)
		grid.append(row)
	return grid


func _copy(grid: Array[PackedByteArray]) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	for row: PackedByteArray in grid:
		out.append(row.duplicate())
	return out


func _text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(BOARD):
		var line: String = ""
		for x: int in range(BOARD):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
