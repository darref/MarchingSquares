# LE LABORATOIRE : fabriquer des reliefs epais, et nommer les jonctions qu'ils posent.
#
# ⚠ UN SEUL ENDROIT, PARCE QUE DEUX COPIES D'UNE MEME REGLE FINISSENT TOUJOURS PAR SE
# CONTREDIRE. Le recensement compte les especes de jonction ; le batisseur du guide cherche a
# les couvrir. S'ils ne les nomment pas de la meme facon, le guide se croira complet en
# couvrant autre chose que ce qu'on mesure -- exactement la faute du test qui redérive la
# formule qu'il verifie.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Thickness := preload("res://core/thickness.gd")

const BAND: Array[String] = ["surf", "chap", "corp", "pied"]


## L'ESPECE D'UNE JONCTION, et chaque champ y est parce qu'il change ce qui se dessine :
##   l'axe            lateral ou vertical ;
##   les deux bandes  surface, chapiteau, corps, pied ;
##   meme massif      sinon deux faces distinctes se rencontrent ;
##   meme levre       a massif egal, c'est ce qui separe la roche continue de l'ARETE INTERNE ;
##   l'ecart d'etage  qui est devant qui ;
##   les deux chutes  trois, six, ou davantage.
##
## Rend `{espece: occurrences}` sur ce qu'on VOIT -- la pose du dessus.
static func species(world: PackedStringArray) -> Dictionary:
	var top: Dictionary = {}
	var falls: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if int(one["band"]) != Massifs.SURFACE:
			var lip: Vector2i = one["lip"]
			var key: Vector3i = Vector3i(lip.x, lip.y, int(one["level"]))
			falls[key] = int(falls.get(key, 0)) + 1
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var out: Dictionary = {}
	for cell2: Vector2i in top.keys():
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var near: Vector2i = cell2 + step
			if not top.has(near):
				continue
			var key2: String = name_of(top[cell2], top[near], step == Vector2i.RIGHT, falls)
			out[key2] = int(out.get(key2, 0)) + 1
	return out


## Les memes especes, mais rangees par CASE -- pour aller decouper autour de l'une d'elles.
static func species_at(world: PackedStringArray) -> Dictionary:
	var top: Dictionary = {}
	var falls: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if int(one["band"]) != Massifs.SURFACE:
			var lip: Vector2i = one["lip"]
			var key: Vector3i = Vector3i(lip.x, lip.y, int(one["level"]))
			falls[key] = int(falls.get(key, 0)) + 1
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var out: Dictionary = {}
	for cell2: Vector2i in top.keys():
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var near: Vector2i = cell2 + step
			if not top.has(near):
				continue
			var key2: String = name_of(top[cell2], top[near], step == Vector2i.RIGHT, falls)
			if not out.has(key2):
				out[key2] = cell2
	return out


static func name_of(a: Dictionary, b: Dictionary, lateral: bool, falls: Dictionary) -> String:
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


static func _fall(falls: Dictionary, one: Dictionary) -> String:
	if int(one["band"]) == Massifs.SURFACE:
		return "-"
	var lip: Vector2i = one["lip"]
	var many: int = int(falls.get(Vector3i(lip.x, lip.y, int(one["level"])), 0))
	return "9+" if many > 6 else str(many)


## UN RELIEF EPAIS TIRE AU SORT -- pose ET efface, puis se repare, comme le pinceau.
##
## ⚠ ON REPARE, ON NE REFUSE PAS. Un generateur qui jette tout relief fin ne rendait que quinze
## mondes sur mille cinq cents : la battue ne cherchait presque rien, et son silence n'aurait
## rien prouve.
## ⚠ ET LA TAILLE EST FIXE, PARCE QUE LE GUIDE EN EST UNE MOSAIQUE. Chaque monde y entre
## ENTIER, avec son lisere de vide : rien n'est decoupe, donc rien ne peut mentir. La decoupe,
## elle, tranche des massifs et change les jonctions qu'elle pretend capturer -- il fallait la
## reparer, la reverifier, et elle en rejetait le tiers.
static func draw(rng: RandomNumberGenerator, wide: int = 24, tall: int = 30) -> PackedStringArray:
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
	for _stamp: int in range(rng.randi_range(4, 18)):
		var ox: int = rng.randi_range(5, wide - 8)
		var oy: int = rng.randi_range(5, tall - 12)
		var raise: bool = rng.randf() < 0.7
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				var row2: PackedByteArray = grid[y3]
				row2[x3] = mini(int(row2[x3]) + 1, 4) if raise else maxi(int(row2[x3]) - 1, 0)
				grid[y3] = row2
	return repair(grid)


## La reparation : chaque case fine s'aligne sur ses voisines, chaque pincement diagonal se
## defait, jusqu'au point fixe.
static func repair(grid: Array[PackedByteArray]) -> PackedStringArray:
	var tall: int = grid.size()
	var wide: int = grid[0].size()
	for round: int in range(16):
		var world: PackedStringArray = text(grid)
		var thin: Array[Vector3i] = Thickness.thin_cells(world)
		var pinch: Array[Vector3i] = Thickness.diagonal_pinches(world)
		if thin.is_empty() and pinch.is_empty():
			return world if Massifs.foot_faults(world).is_empty() else PackedStringArray()
		for cut: Vector3i in pinch:
			if cut.x < 0 or cut.y < 0 or cut.y + 1 >= tall or cut.x + 1 >= wide:
				continue
			grid[cut.y][cut.x + 1] = grid[cut.y][cut.x]
		for one: Vector3i in thin:
			if one.x < 0 or one.y < 0 or one.y >= tall or one.x >= wide:
				continue
			var votes: Dictionary = {}
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var nx: int = one.x + step.x
				var ny: int = one.y + step.y
				if nx < 0 or ny < 0 or ny >= tall or nx >= wide:
					continue
				votes[int(grid[ny][nx])] = int(votes.get(int(grid[ny][nx]), 0)) + 1
			var best: int = int(grid[one.y][one.x])
			var most: int = 0
			for value: int in votes.keys():
				if int(votes[value]) > most:
					most = int(votes[value])
					best = value
			grid[one.y][one.x] = best
	return PackedStringArray()


static func text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: PackedByteArray in grid:
		var said: String = ""
		for v: int in line:
			said += "~" if v == 0 else str(v - 1)
		out.append(said)
	return out


## Un relief est-il jouable : epais, sans pincement diagonal, sans faute de marge de pied ?
static func legal(world: PackedStringArray) -> bool:
	return Thickness.thin_cells(world).is_empty() \
			and Thickness.diagonal_pinches(world).is_empty() \
			and Massifs.foot_faults(world).is_empty()
