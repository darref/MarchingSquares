# LE RECENSEMENT DES JONCTIONS — ce que le modele POSE cote a cote, et ce que `Seams` SAIT.
#
# ⚠ LA MEME LECON QUE `row_chains`, D'UN CRAN PLUS HAUT. `Seams` lit ses enchainements de
# `row_for`, sur les pas 1..drop, et les joint A PAN CONSTANT. Or `Walls.assemble()` pose
# aussi hors de cet intervalle -- chapiteau sous la levre (pas 0), sous-pied et pose
# derriere (pas drop+1) -- et le pan d'une colonne CHANGE en descendant, puisque l'etat
# d'un flanc change quand la robe voisine s'arrete. Deduire les jonctions d'une formule,
# c'est deduire ce qu'on croit poser ; les lire d'un relief assemble, c'est lire ce qu'on
# pose vraiment.
#
# Une jonction non couverte n'est pas une erreur de calcul : c'est un bord que la
# propagation n'ecrit pas et que la preuve ne regarde pas. L'artiste y peint deux fois le
# meme point de roche, librement, et rien ne le lui dit.
#
#     godot --headless --path . --script res://tools/seam_census.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Seams := preload("res://core/seams.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const GuideImage := preload("res://render/guide_image.gd")

const TRIALS: int = 300


## Toutes les tuiles de robe posees sur un relief, adossements compris.
## Une case peut en porter plus d'une : la face devant, l'adossement derriere.
func _fragments(heights: PackedStringArray) -> Dictionary:
	var assembled: Dictionary = Walls.assemble(heights)
	var roles: Dictionary = assembled["roles"]
	var underfoot: Dictionary = assembled["underfoot"]
	var out: Dictionary = {}
	for key: Vector3i in roles:
		var bag: Array[Vector2i] = []
		bag.append(roles[key] as Vector2i)
		out[key] = bag
	for key: Vector3i in underfoot:
		if not out.has(key):
			var fresh: Array[Vector2i] = []
			out[key] = fresh
		(out[key] as Array[Vector2i]).append(underfoot[key] as Vector2i)
	return out


func _note(book: Dictionary, a: Vector2i, b: Vector2i, where: Vector3i, label: String) -> void:
	var key: Vector4i = Vector4i(a.x, a.y, b.x, b.y)
	if book.has(key):
		book[key] = [(book[key] as Array)[0] as int + 1, (book[key] as Array)[1]]
		return
	book[key] = [1, "%s %s" % [label, where]]


func _scan(heights: PackedStringArray, label: String, vertical: Dictionary,
		horizontal: Dictionary) -> void:
	var frags: Dictionary = _fragments(heights)
	for key: Vector3i in frags:
		var here: Array[Vector2i] = frags[key]
		var south: Vector3i = key + Vector3i(0, 1, 0)
		if frags.has(south):
			var below: Array[Vector2i] = frags[south]
			for up: Vector2i in here:
				for down: Vector2i in below:
					_note(vertical, up, down, key, label)
		var east: Vector3i = key + Vector3i(1, 0, 0)
		if frags.has(east):
			var beside: Array[Vector2i] = frags[east]
			for left: Vector2i in here:
				for right: Vector2i in beside:
					_note(horizontal, left, right, key, label)


func _linked(a: Vector3i, b: Vector3i) -> bool:
	if not Seams.GROUPS.has(a):
		return false
	return (Seams.GROUPS[a] as Array).has(b)


func _role_name(role: Vector2i) -> String:
	return "(%s,%s) %s" % [Walls.SIDE_NAMES[Walls.pan_west(role.x)],
			Walls.SIDE_NAMES[Walls.pan_east(role.x)], Walls.ROW_NAMES[role.y]]


func _random_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	for _try: int in range(40):
		var columns: int = 16
		var rows: int = 14
		var levels: Array = []
		for y: int in range(rows):
			var line: Array = []
			line.resize(columns)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(2, 4)):
			var w: int = rng.randi_range(3, 6)
			var h: int = rng.randi_range(3, 6)
			var px: int = rng.randi_range(0, columns - w)
			var py: int = rng.randi_range(0, rows - h)
			var lift: int = rng.randi_range(1, 2)
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


## Les classes de bords telles que le monde les impose vraiment : union-find sur les
## jonctions RECENSEES, et non sur celles que `row_for` laisse deviner.
func _real_classes(vertical: Dictionary, horizontal: Dictionary, seen: Dictionary) -> void:
	var parent: Dictionary = {}
	var find: Callable = func(a: Vector3i) -> Vector3i:
		var root: Vector3i = a
		while (parent.get(root, root) as Vector3i) != root:
			root = parent.get(root, root) as Vector3i
		return root
	var join: Callable = func(a: Vector3i, b: Vector3i) -> void:
		var ra: Vector3i = find.call(a)
		var rb: Vector3i = find.call(b)
		if ra != rb:
			parent[ra] = rb
	for role: Vector2i in seen:
		for side: int in range(4):
			var edge: Vector3i = Vector3i(role.x, role.y, side)
			parent[edge] = edge
	for key: Vector4i in vertical:
		join.call(Vector3i(key.x, key.y, Seams.BOTTOM), Vector3i(key.z, key.w, Seams.TOP))
	for key: Vector4i in horizontal:
		var left: Vector2i = Vector2i(key.x, key.y)
		var right: Vector2i = Vector2i(key.z, key.w)
		if Walls.pan_east(left.x) != Walls.SIDE_MUTE or Walls.pan_west(right.x) != Walls.SIDE_MUTE:
			continue
		join.call(Vector3i(left.x, left.y, Seams.RIGHT), Vector3i(right.x, right.y, Seams.LEFT))
	var roots: Dictionary = {}
	for edge: Vector3i in parent:
		roots[find.call(edge)] = true
	print("")
	print("CLASSES DE BORDS, comptees sur les jonctions REELLES")
	print("   %d roles rencontres, donc %d bords ; %d classes independantes."
			% [seen.size(), seen.size() * 4, roots.size()])
	print("   Seams en declare %d libres sur %d bords des 36 roles." % [
			int((Seams.tally() as Dictionary)["free"]), int((Seams.tally() as Dictionary)["edges"])])


## Ce que l'ILLUSTRATION fait deja a ces jonctions. Un ecart ici n'est pas une menace
## theorique : c'est une cassure visible sur le guide, sur l'essai, et dans le jeu.
func _render_check(vertical: Dictionary, horizontal: Dictionary, seen: Dictionary) -> void:
	var size: int = 32
	var tiles: Dictionary = {}
	for role: Vector2i in seen:
		tiles[role] = GuideImage.make_wall(role, size, GuideImage.Ink.PAINTED, false)
	var last: int = size - 1
	for axis: int in range(2):
		var book: Dictionary = vertical if axis == 0 else horizontal
		var broken: int = 0
		var total: int = 0
		var worst: float = 0.0
		var worst_name: String = ""
		var loud: Array[String] = []
		for key: Vector4i in book:
			var a: Vector2i = Vector2i(key.x, key.y)
			var b: Vector2i = Vector2i(key.z, key.w)
			if axis == 1 and (Walls.pan_east(a.x) != Walls.SIDE_MUTE
					or Walls.pan_west(b.x) != Walls.SIDE_MUTE):
				continue
			var known: bool = _linked(
					Vector3i(a.x, a.y, Seams.BOTTOM if axis == 0 else Seams.RIGHT),
					Vector3i(b.x, b.y, Seams.TOP if axis == 0 else Seams.LEFT))
			if known:
				continue
			total += 1
			var one: Image = tiles[a]
			var two: Image = tiles[b]
			var gap: float = 0.0
			for i: int in range(size):
				var p: Color = one.get_pixel(i, last) if axis == 0 else one.get_pixel(last, i)
				var q: Color = two.get_pixel(i, 0) if axis == 0 else two.get_pixel(0, i)
				gap = maxf(gap, maxf(maxf(absf(p.r - q.r), absf(p.g - q.g)),
						maxf(absf(p.b - q.b), absf(p.a - q.a))))
			if gap > worst:
				worst = gap
				worst_name = "%s / %s" % [_role_name(a), _role_name(b)]
			if gap > 0.02:
				broken += 1
				loud.append("    %.1f%%  %-32s %s %s" % [gap * 100.0, _role_name(a),
						"SUR" if axis == 0 else "CONTRE", _role_name(b)])
		print("")
		print("%s — l'illustration aux jonctions INCONNUES : %d examinees, %d cassees, pire %.1f%% (%s)"
				% ["VERTICAL" if axis == 0 else "HORIZONTAL", total, broken, worst * 100.0,
				worst_name])
		loud.sort()
		loud.reverse()
		for line: String in loud.slice(0, mini(10, loud.size())):
			print(line)


## Trois manieres de fermer, trois libertes. Une fermeture PRUDENTE (joindre plus que
## necessaire) ne peut jamais rendre un tileset faux -- seulement plus contraint.
func _closures(vertical: Dictionary, horizontal: Dictionary, seen: Dictionary) -> void:
	var rows: Dictionary = {}
	for key: Vector4i in vertical:
		rows[Vector2i(key.y, key.w)] = true
	var pans: Dictionary = {}
	for role: Vector2i in seen:
		pans[role.x] = true
	for mode: int in range(3):
		var parent: Dictionary = {}
		var find: Callable = func(a: Vector3i) -> Vector3i:
			var root: Vector3i = a
			while (parent.get(root, root) as Vector3i) != root:
				root = parent.get(root, root) as Vector3i
			return root
		var join: Callable = func(a: Vector3i, b: Vector3i) -> void:
			if not parent.has(a) or not parent.has(b):
				return
			var ra: Vector3i = find.call(a)
			var rb: Vector3i = find.call(b)
			if ra != rb:
				parent[ra] = rb
		for role: Vector2i in seen:
			for side: int in range(4):
				parent[Vector3i(role.x, role.y, side)] = Vector3i(role.x, role.y, side)
		if mode == 0:
			for edge: Vector3i in Seams.GROUPS:
				for other: Vector3i in (Seams.GROUPS[edge] as Array):
					join.call(edge, other)
		elif mode == 1:
			for key: Vector4i in vertical:
				join.call(Vector3i(key.x, key.y, Seams.BOTTOM), Vector3i(key.z, key.w, Seams.TOP))
			for key: Vector4i in horizontal:
				if Walls.pan_east(key.x) == Walls.SIDE_MUTE and Walls.pan_west(key.z) == Walls.SIDE_MUTE:
					join.call(Vector3i(key.x, key.y, Seams.RIGHT), Vector3i(key.z, key.w, Seams.LEFT))
		else:
			for pair: Vector2i in rows:
				for a: int in pans:
					for b: int in pans:
						join.call(Vector3i(a, pair.x, Seams.BOTTOM), Vector3i(b, pair.y, Seams.TOP))
			for ra: int in range(Walls.BLOCK_ROWS):
				for rb: int in range(Walls.BLOCK_ROWS):
					for a: int in pans:
						for b: int in pans:
							if Walls.pan_east(a) == Walls.SIDE_MUTE and Walls.pan_west(b) == Walls.SIDE_MUTE:
								join.call(Vector3i(a, ra, Seams.RIGHT), Vector3i(b, rb, Seams.LEFT))
		var roots: Dictionary = {}
		for edge: Vector3i in parent:
			roots[find.call(edge)] = true
		var names: Array[String] = ["Seams aujourd'hui", "les jonctions REELLES",
				"fermeture prudente (tous pans, toutes rangees muettes)"]
		print("   %-52s -> %2d classes sur %d bords" % [names[mode], roots.size(), parent.size()])


func _initialize() -> void:
	var vertical: Dictionary = {}
	var horizontal: Dictionary = {}
	var seen: Dictionary = {}

	var guide_path: String = Modes.guide_path(Modes.EPAIS)
	if FileAccess.file_exists(guide_path):
		_scan(HeightMask.read(guide_path), "guide", vertical, horizontal)
	for family: StringName in Families.ids():
		_scan(ProofScene.relief(family), "preuve/%s" % family, vertical, horizontal)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260824
	var drawn: int = 0
	for _t: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if relief.is_empty():
			continue
		drawn += 1
		_scan(relief, "hasard %d" % drawn, vertical, horizontal)

	print("RECENSEMENT DES JONCTIONS — guide epais, planches de preuve, %d reliefs epais"
			% drawn)
	print("")

	# --- VERTICAL : toute jonction doit etre couverte, c'est la meme face.
	var holes: Array[String] = []
	var covered: int = 0
	var cross_pan: int = 0
	for key: Vector4i in vertical:
		var up: Vector2i = Vector2i(key.x, key.y)
		var down: Vector2i = Vector2i(key.z, key.w)
		if up.x != down.x:
			cross_pan += 1
		if _linked(Vector3i(up.x, up.y, Seams.BOTTOM), Vector3i(down.x, down.y, Seams.TOP)):
			covered += 1
			continue
		var row: Array = vertical[key]
		holes.append("    %-34s SUR %-34s  x%d   ex. %s" % [_role_name(up), _role_name(down),
				row[0] as int, row[1] as String])
	print("VERTICAL : %d jonctions distinctes posees, %d connues de Seams, %d INCONNUES"
			% [vertical.size(), covered, holes.size()])
	print("           dont %d a pan changeant (la colonne change de flanc en descendant)"
			% cross_pan)
	if not holes.is_empty():
		holes.sort()
		for line: String in holes.slice(0, mini(40, holes.size())):
			print(line)
		if holes.size() > 40:
			print("    ... et %d autres" % (holes.size() - 40))
	print("")

	# --- HORIZONTAL : seul muet/muet est cense etre contraint.
	var mute_holes: Array[String] = []
	var mute_covered: int = 0
	var free_pairs: int = 0
	for key: Vector4i in horizontal:
		var left: Vector2i = Vector2i(key.x, key.y)
		var right: Vector2i = Vector2i(key.z, key.w)
		var both_mute: bool = (Walls.pan_east(left.x) == Walls.SIDE_MUTE
				and Walls.pan_west(right.x) == Walls.SIDE_MUTE)
		if not both_mute:
			free_pairs += 1
			continue
		if _linked(Vector3i(left.x, left.y, Seams.RIGHT), Vector3i(right.x, right.y, Seams.LEFT)):
			mute_covered += 1
			continue
		var row: Array = horizontal[key]
		mute_holes.append("    %-34s CONTRE %-34s  x%d   ex. %s" % [_role_name(left),
				_role_name(right), row[0] as int, row[1] as String])
	print("HORIZONTAL : %d jonctions distinctes posees" % horizontal.size())
	print("             %d muet/muet, dont %d connues de Seams et %d INCONNUES"
			% [mute_covered + mute_holes.size(), mute_covered, mute_holes.size()])
	print("             %d a arete (rien a exiger que l'absence de trou)" % free_pairs)
	for line: String in mute_holes.slice(0, mini(20, mute_holes.size())):
		print(line)
	print("")
	for key: Vector4i in vertical:
		seen[Vector2i(key.x, key.y)] = true
		seen[Vector2i(key.z, key.w)] = true
	for key: Vector4i in horizontal:
		seen[Vector2i(key.x, key.y)] = true
		seen[Vector2i(key.z, key.w)] = true
	_real_classes(vertical, horizontal, seen)
	print("")
	print("TROIS FERMETURES POSSIBLES, sur les 25 roles vivants :")
	_closures(vertical, horizontal, seen)
	_render_check(vertical, horizontal, seen)
	quit(1 if (holes.size() + mute_holes.size()) > 0 else 0)
