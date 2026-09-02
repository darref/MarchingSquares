extends SceneTree

## LE CONTROLE CROISE GESTE <-> GUIDE, DANS L'AUTRE SENS.
##
##     godot --headless --path . --script res://tools/reachable.gd
##
## ⚠ ON COMPARE DANS LES DEUX SENS, ET JE NE REGARDAIS QU'UN COTE. Le recensement du pinceau
## prouve que toute tuile ATTEINTE par le geste est au guide. Il ne prouve pas l'inverse : que
## tout relief DU GUIDE soit atteignable par une suite de gestes. Or « legal » n'est pas
## « atteignable » -- le specimen de debordement, par exemple, est construit puis verifie legal,
## et rien ne dit qu'une suite de tampons 3x3 y arrive.
##
## Ce solveur part de la PLAINE et rebatit chaque monde du guide, tampon par tampon, en exigeant
## que chaque etat intermediaire soit legal. S'il n'y arrive pas, le guide montre a l'artiste un
## relief que son pinceau ne fabriquera jamais.
##
## ⚠ ET IL EST GLOUTON, DONC IL PEUT ECHOUER SUR UN MONDE ATTEIGNABLE. Un echec est une QUESTION,
## pas un verdict : il dit « aucune suite simple n'y mene », pas « aucune suite n'y mene ». Le
## dire autrement serait le meme abus que « la battue ne l'a pas vu, donc ca n'existe pas ».

const HeightMask := preload("res://core/height_mask.gd")
const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")

## Ce que le pinceau pose : un tampon de trois sur trois, qui monte ou qui descend d'un etage.
const STAMP: int = 3


func _initialize() -> void:
	var world: PackedStringArray = HeightMask.read("res://guides/massifs.txt")
	var pieces: Array[PackedStringArray] = _pieces(world)
	print("=== LE GUIDE EST-IL ATTEIGNABLE AU PINCEAU ? ===")
	print("  %d monde(s) dans le guide" % pieces.size())
	var won: int = 0
	for at: int in range(pieces.size()):
		var got: Dictionary = _solve(pieces[at])
		if bool(got["reached"]):
			won += 1
			print("  monde %2d : ATTEINT en %d gestes" % [at + 1, int(got["moves"])])
		else:
			print("  monde %2d : PAS ATTEINT -- %d case(s) d'ecart apres %d gestes"
					% [at + 1, int(got["left"]), int(got["moves"])])
	print("")
	print("VERDICT : %d/%d mondes atteignables" % [won, pieces.size()])
	quit(0 if won == pieces.size() else 1)


## LES MONDES DU GUIDE : chaque composante connexe de ce qui n'est pas du vide, encadree.
func _pieces(world: PackedStringArray) -> Array[PackedStringArray]:
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	var seen: Dictionary = {}
	var out: Array[PackedStringArray] = []
	for y: int in range(tall):
		for x: int in range(wide):
			if seen.has(Vector2i(x, y)) or HeightMask.level_at(world, x, y) < 0:
				continue
			var cells: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			var lo: Vector2i = Vector2i(x, y)
			var hi: Vector2i = Vector2i(x, y)
			while not stack.is_empty():
				var here: Vector2i = stack.pop_back()
				cells.append(here)
				lo = Vector2i(mini(lo.x, here.x), mini(lo.y, here.y))
				hi = Vector2i(maxi(hi.x, here.x), maxi(hi.y, here.y))
				for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
					var near: Vector2i = here + step
					if near.x < 0 or near.y < 0 or near.x >= wide or near.y >= tall:
						continue
					if seen.has(near) or HeightMask.level_at(world, near.x, near.y) < 0:
						continue
					seen[near] = true
					stack.append(near)
			# Le monde, avec son lisere de vide : quatre cases, comme partout.
			var rim: int = 4
			var piece: PackedStringArray = PackedStringArray()
			for y2: int in range(lo.y - rim, hi.y + rim + 1):
				var line: String = ""
				for x2: int in range(lo.x - rim, hi.x + rim + 1):
					var level: int = HeightMask.level_at(world, x2, y2)
					line += "~" if level < 0 or not seen.has(Vector2i(x2, y2)) else str(level)
				piece.append(line)
			out.append(piece)
	return out


## LE SOLVEUR : de la plaine au monde vise, tampon par tampon.
##
## ⚠ ET CHAQUE ETAT INTERMEDIAIRE DOIT ETRE LEGAL. Un chemin qui passerait par un relief que le
## pinceau refuse ne prouve rien : c'est justement ce qu'on veut savoir.
func _solve(want: PackedStringArray) -> Dictionary:
	var wide: int = HeightMask.width(want)
	var tall: int = HeightMask.height(want)
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		for x: int in range(wide):
			# On part de la PLAINE, avec le meme lisere de vide que la cible : le pinceau ne
			# creuse pas le vide, il ne peut donc que le trouver la ou il est.
			line[x] = 0 if HeightMask.level_at(want, x, y) < 0 else 1
		grid.append(line)
	var moves: int = 0
	while moves < 400:
		var left: int = _apart(grid, want)
		if left == 0:
			return {"reached": true, "moves": moves, "left": 0}
		# ⚠ ON ESSAIE LES CANDIDATS DANS L'ORDRE, PAS SEULEMENT LE MEILLEUR. Premiere version :
		# des que le meilleur tampon rendait le monde illegal, j'abandonnais -- 5 mondes sur 10
		# declares inatteignables, alors que c'etait le SOLVEUR qui renoncait. Un echec doit
		# accuser le guide, pas la paresse de celui qui cherche.
		var tries: Array[Vector3i] = []
		var scores: Dictionary = {}
		for y2: int in range(tall - STAMP + 1):
			for x2: int in range(wide - STAMP + 1):
				for way: int in [1, -1]:
					var score: int = _score(grid, want, x2, y2, way)
					if score <= 0:
						continue
					var key: Vector3i = Vector3i(x2, y2, way)
					tries.append(key)
					scores[key] = score
		tries.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
			return int(scores[a]) > int(scores[b]))
		var done: bool = false
		for one: Vector3i in tries:
			var keep: Array[PackedByteArray] = []
			for row: PackedByteArray in grid:
				keep.append(row.duplicate())
			_apply(grid, one.x, one.y, one.z)
			if Gesture.legal(Gesture.text(grid)):
				done = true
				break
			grid = keep
		if not done:
			return {"reached": false, "moves": moves, "left": left}
		moves += 1
	return {"reached": false, "moves": moves, "left": _apart(grid, want)}


func _apart(grid: Array[PackedByteArray], want: PackedStringArray) -> int:
	var many: int = 0
	for y: int in range(grid.size()):
		for x: int in range(grid[0].size()):
			var level: int = HeightMask.level_at(want, x, y)
			if int(grid[y][x]) != (0 if level < 0 else level + 1):
				many += 1
	return many


## Ce qu'un tampon rapprocherait de la cible, moins ce qu'il en eloignerait.
func _score(grid: Array[PackedByteArray], want: PackedStringArray, ox: int, oy: int,
		way: int) -> int:
	var score: int = 0
	for y: int in range(oy, oy + STAMP):
		for x: int in range(ox, ox + STAMP):
			var level: int = HeightMask.level_at(want, x, y)
			var goal: int = 0 if level < 0 else level + 1
			var here: int = int(grid[y][x])
			var after: int = mini(here + 1, 5) if way > 0 else maxi(here - 1, 1)
			if here == goal and after != goal:
				score -= 1
			elif here != goal and after == goal:
				score += 1
			elif here != goal and absi(after - goal) < absi(here - goal):
				score += 1
	return score


func _apply(grid: Array[PackedByteArray], ox: int, oy: int, way: int) -> void:
	for y: int in range(oy, oy + STAMP):
		for x: int in range(ox, ox + STAMP):
			grid[y][x] = mini(int(grid[y][x]) + 1, 5) if way > 0 else maxi(int(grid[y][x]) - 1, 1)
