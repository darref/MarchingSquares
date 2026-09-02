extends SceneTree

## LE RECENSEMENT DES JONCTIONS — ce que le guide montre, et ce qu'il ne montre pas.
##
##     godot --headless --path . --script res://tools/junction_census.gd -- [tirages]
##
## ⚠ L'UNITE N'EST PAS LA TUILE, C'EST LA JONCTION. Un guide bati « un ilot par tuile » est une
## PROJECTION : il garantit que chaque dessin est peignable, et perd tout ce qui se passe ENTRE
## deux cases. Or c'est la que le modele decide -- meme massif ou non, meme rangee de levre ou
## non, quel ecart d'etage, quelle longueur de chute. Tous les manques trouves a l'oeil depuis
## le debut sont des jonctions absentes, jamais des tuiles absentes :
##
##     « tes chevauchements ne rejoignent pas la plaine »   -> chute de six, jamais posee
##     « pas de massif vraiment a cheval »                  -> ecart d'etage sans porteur dessous
##     « l'arete se repete dans la falaise »                -> rangees de levre comparees a tort
##
## ⚠ ET C'EST CE QUI DOIT FAIRE CONVERGER. Tant que la couverture se juge a l'oeil, chaque
## regard trouve un manque de plus et le guide se refait a chaque fois. Mesuree, elle devient un
## invariant : le guide est complet ou il est rouge, et on sait de combien.
##
## L'ESPECE D'UNE JONCTION, et chaque champ y est parce qu'il change ce qui se dessine :
##   l'axe            lateral ou vertical ;
##   les deux bandes  surface, chapiteau, corps, pied ;
##   meme massif      sinon deux faces distinctes se rencontrent ;
##   meme levre       a massif egal, c'est ce qui separe la roche continue de l'ARETE INTERNE ;
##   l'ecart d'etage  qui est devant qui ;
##   les deux chutes  trois, six, ou davantage -- et « sans pied » est une chute a part.

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Thickness := preload("res://core/thickness.gd")

const BAND: Array[String] = ["surf", "chap", "corp", "pied"]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var draws: int = args[0].to_int() if not args.is_empty() else 400

	var guide: Dictionary = _species(HeightMask.read("res://guides/massifs.txt"))
	var world: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x4A554E43
	var made: int = 0
	while made < draws:
		var one: PackedStringArray = _draw(rng)
		if one.is_empty():
			continue
		made += 1
		for key: String in _species(one).keys():
			world[key] = int(world.get(key, 0)) + 1

	var missing: Array[String] = []
	for key2: String in world.keys():
		if not guide.has(key2):
			missing.append(key2)
	missing.sort_custom(func(a: String, b: String) -> bool:
		return int(world[a]) > int(world[b]))
	var extra: Array[String] = []
	for key3: String in guide.keys():
		if not world.has(key3):
			extra.append(key3)
	extra.sort()

	print("=== LE RECENSEMENT DES JONCTIONS ===")
	print("  %d mondes tires au sort" % made)
	print("  le monde pose      : %d especes" % world.size())
	print("  le guide en montre : %d" % guide.size())
	print("  MANQUANTES AU GUIDE : %d" % missing.size())
	for at: int in range(mini(24, missing.size())):
		print("      %-52s vue %d fois" % [missing[at], int(world[missing[at]])])
	if missing.size() > 24:
		print("      ... et %d autres" % (missing.size() - 24))
	# ⚠ ET ON DIT AUSSI CE QUE LE GUIDE MONTRE ET QUE LE HASARD NE PRODUIT PAS. C'est la raison
	# d'etre du guide : porter ce qu'aucune marche au hasard n'atteint. Le silence sur ce point
	# laisserait croire que la battue est le juge, alors qu'elle n'est que l'un des deux.
	print("  au guide seulement : %d especes" % extra.size())
	quit(0)


## LES ESPECES DE JONCTION D'UN RELIEF, sur ce qu'on VOIT -- la pose du dessus.
func _species(world: PackedStringArray) -> Dictionary:
	var top: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var falls: Dictionary = _falls(world)
	var out: Dictionary = {}
	for cell2: Vector2i in top.keys():
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var near: Vector2i = cell2 + step
			if not top.has(near):
				continue
			var key: String = _say(top[cell2], top[near], step == Vector2i.RIGHT, falls)
			out[key] = int(out.get(key, 0)) + 1
	return out


func _say(a: Dictionary, b: Dictionary, lateral: bool, falls: Dictionary) -> String:
	var same_massif: bool = int(a["massif"]) == int(b["massif"])
	var lip_a: Vector2i = a["lip"]
	var lip_b: Vector2i = b["lip"]
	var same_lip: bool = same_massif and lip_a.y == lip_b.y
	var drop: int = clampi(int(b["level"]) - int(a["level"]), -2, 2)
	return "%s %s|%s %s %s etage%+d chute %s|%s" % [
			"lateral" if lateral else "vertical",
			BAND[int(a["band"])], BAND[int(b["band"])],
			"meme-massif" if same_massif else "deux-massifs",
			"meme-levre" if same_lip else "levres-differentes",
			drop, _fall(falls, a), _fall(falls, b)]


func _fall(falls: Dictionary, one: Dictionary) -> String:
	if int(one["band"]) == Massifs.SURFACE:
		return "-"
	var lip: Vector2i = one["lip"]
	var key: Vector3i = Vector3i(lip.x, lip.y, int(one["level"]))
	var many: int = int(falls.get(key, 0))
	return "9+" if many > 6 else str(many)


## La longueur de chaque chute, par levre.
func _falls(world: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		if int(one["band"]) == Massifs.SURFACE:
			continue
		var lip: Vector2i = one["lip"]
		var key: Vector3i = Vector3i(lip.x, lip.y, int(one["level"]))
		out[key] = int(out.get(key, 0)) + 1
	return out


## UN RELIEF EPAIS TIRE AU SORT -- pose ET efface, puis se repare, comme le pinceau.
func _draw(rng: RandomNumberGenerator) -> PackedStringArray:
	var wide: int = rng.randi_range(20, 32)
	var tall: int = rng.randi_range(24, 36)
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	for x: int in range(4, wide - 4):
		for y2: int in range(4, tall - 4):
			var row: PackedByteArray = grid[y2]
			row[x] = 1
			grid[y2] = row
	for _stamp: int in range(rng.randi_range(4, 16)):
		var ox: int = rng.randi_range(5, wide - 8)
		var oy: int = rng.randi_range(5, tall - 12)
		var raise: bool = rng.randf() < 0.7
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				var row2: PackedByteArray = grid[y3]
				row2[x3] = mini(int(row2[x3]) + 1, 4) if raise else maxi(int(row2[x3]) - 1, 0)
				grid[y3] = row2
	for round: int in range(14):
		var text: PackedStringArray = _text(grid)
		var thin: Array[Vector3i] = Thickness.thin_cells(text)
		var pinch: Array[Vector3i] = Thickness.diagonal_pinches(text)
		if thin.is_empty() and pinch.is_empty():
			return text if Massifs.foot_faults(text).is_empty() else PackedStringArray()
		for cut: Vector3i in pinch:
			if cut.x < 0 or cut.y < 0 or cut.y + 1 >= tall or cut.x + 1 >= wide:
				continue
			grid[cut.y][cut.x + 1] = grid[cut.y][cut.x]
		for one2: Vector3i in thin:
			if one2.x < 0 or one2.y < 0 or one2.y >= tall or one2.x >= wide:
				continue
			var votes: Dictionary = {}
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var nx: int = one2.x + step.x
				var ny: int = one2.y + step.y
				if nx < 0 or ny < 0 or ny >= tall or nx >= wide:
					continue
				votes[int(grid[ny][nx])] = int(votes.get(int(grid[ny][nx]), 0)) + 1
			var best: int = int(grid[one2.y][one2.x])
			var most: int = 0
			for value: int in votes.keys():
				if int(votes[value]) > most:
					most = int(votes[value])
					best = value
			grid[one2.y][one2.x] = best
	return PackedStringArray()


func _text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var text: PackedStringArray = PackedStringArray()
	for line: PackedByteArray in grid:
		var said: String = ""
		for v: int in line:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	return text
