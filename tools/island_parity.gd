extends SceneTree

## L'ALTERNANCE DES ILOTS : « quand deux ilots sont colles, un des deux ne peut pas etre
## vagabond, et ce generalise a N par alternance ».
##
## C'est une regle de COLORIAGE, et elle se teste. Formalisee :
##   ILOT      une composante connexe de la silhouette d'un etage -- (etage, composante).
##   COLLES    deux ilots dont les bords COINCIDENT quelque part : il existe une case qui
##             appartient aux deux, et un cardinal ouvert dans les deux silhouettes. C'est la,
##             et seulement la, que deux tuiles tracent le meme bord du monde -- ailleurs le
##             plus haut creuse et le plus bas est plein, donc un seul trait.
##   ALTERNER  colorier le graphe en deux : vagabond / droit, sans qu'aucune arete relie deux
##             vagabonds. Possible si, et seulement si, le graphe est BIPARTI.
##
## ⚠ CE QUI PEUT LE FAIRE ECHOUER EST UN CYCLE IMPAIR, et il y en a un evident a chercher :
## les silhouettes sont EMBOITEES -- celle de l'etage N+1 est incluse dans celle de N -- donc
## au-dessus d'une chute de trois etages, TROIS ilots partagent le meme bord. Trois ilots
## mutuellement colles forment un triangle, et un triangle ne se colorie pas en deux.
##
## On mesure donc : le graphe est-il biparti, et sinon ou casse-t-il.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")

const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _initialize() -> void:
	_probe(HeightMask.read(Modes.guide_path(Modes.EPAIS)), "le guide epais")
	_probe(ProofScene.relief(Families.BY_CELL), "la planche de preuve")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260827
	var kept: int = 0
	var bad: int = 0
	var worst: int = 0
	while kept < 200:
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		kept += 1
		var report: Dictionary = _measure(relief)
		if not bool(report["bipartite"]):
			bad += 1
		worst = maxi(worst, int(report["deepest"]))
	print("")
	print("%d reliefs epais tires au sort : %d NON bipartis (%.0f %%), plus grosse pile de bords"
			% [kept, bad, 100.0 * float(bad) / float(kept)] + " coincidents : %d" % worst)
	quit()


func _probe(heights: PackedStringArray, label: String) -> void:
	var report: Dictionary = _measure(heights)
	print("=== %s ===" % label)
	print("  ilots : %d   contacts : %d" % [int(report["islands"]), int(report["contacts"])])
	print("  la plus grosse pile de bords coincidents : %d" % int(report["deepest"]))
	print("  BIPARTI : %s   %s" % ["oui" if bool(report["bipartite"]) else "NON",
			str(report["witness"])])
	print("  bords ou DEUX traits ou plus se superposent : %d sur de la terre, %d sur le vide"
			% [int(report["sur_terre"]), int(report["sur_vide"])])


## Les ilots, leurs contacts, et le coloriage.
func _measure(heights: PackedStringArray) -> Dictionary:
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var top: int = 0
	for y: int in range(height):
		for x: int in range(width):
			top = maxi(top, HeightMask.level_at(heights, x, y))

	# 1. Un identifiant d'ilot par (etage, case).
	var island: Dictionary = {}          # Vector3i(x, y, etage) -> id
	var count: int = 0
	for level: int in range(top + 1):
		for y: int in range(height):
			for x: int in range(width):
				var here: Vector3i = Vector3i(x, y, level)
				if HeightMask.level_at(heights, x, y) < level or island.has(here):
					continue
				var id: int = count
				count += 1
				var stack: Array[Vector3i] = [here]
				island[here] = id
				while not stack.is_empty():
					var at: Vector3i = stack.pop_back()
					for step: Vector2i in STEPS:
						var probe: Vector3i = Vector3i(at.x + step.x, at.y + step.y, level)
						if island.has(probe):
							continue
						if HeightMask.level_at(heights, probe.x, probe.y) < level:
							continue
						island[probe] = id
						stack.append(probe)

	# 2. Les contacts : une case, un cardinal, ouvert dans plusieurs silhouettes a la fois.
	var edges: Dictionary = {}
	var piles: Dictionary = {}
	var deepest: int = 0
	for y: int in range(height):
		for x: int in range(width):
			var mine: int = HeightMask.level_at(heights, x, y)
			if mine < 0:
				continue
			for step: Vector2i in STEPS:
				var beyond: int = HeightMask.level_at(heights, x + step.x, y + step.y)
				if beyond >= mine:
					continue
				# ⚠ LA PILE EST EXACTEMENT LA CHUTE. Le cardinal est ouvert dans toutes les
				# silhouettes de `beyond + 1` a `mine` : autant d'ilots qui tracent LE MEME
				# bord du monde, chacun de son cote.
				var pile: Array[int] = []
				for level: int in range(maxi(beyond + 1, 0), mine + 1):
					pile.append(int(island[Vector3i(x, y, level)]))
				deepest = maxi(deepest, pile.size())
				# ⚠ ET ON SEPARE LES DEUX ESPECES DE PILE. Quand la voisine est de la TERRE,
				# elle dessine elle-meme ce qu'il y a au-dela : les etages enterres de ma case
				# n'ont qu'a etre PLEINS, et le seul trait est celui du sommet. Quand la
				# voisine est le VIDE, il n'y a personne au-dela, et remplir enterre laisserait
				# la vraie silhouette au ras du bord, droite et sans trait.
				if pile.size() >= 2:
					if beyond < 0:
						piles["vide"] = int(piles.get("vide", 0)) + 1
					else:
						piles["terre"] = int(piles.get("terre", 0)) + 1
				for a: int in range(pile.size()):
					for b: int in range(a + 1, pile.size()):
						if pile[a] != pile[b]:
							edges[Vector2i(mini(pile[a], pile[b]), maxi(pile[a], pile[b]))] = true

	# 3. Le coloriage en deux.
	var neighbours: Dictionary = {}
	for edge: Vector2i in edges.keys():
		for pair: Array in [[edge.x, edge.y], [edge.y, edge.x]]:
			if not neighbours.has(pair[0]):
				neighbours[pair[0]] = ([] as Array[int])
			(neighbours[pair[0]] as Array[int]).append(int(pair[1]))
	var colour: Dictionary = {}
	var witness: Array[String] = []
	for start: Variant in neighbours.keys():
		if colour.has(start):
			continue
		colour[start] = 0
		var queue: Array[int] = [int(start)]
		while not queue.is_empty():
			var at: int = queue.pop_front()
			for other: int in (neighbours[at] as Array[int]):
				if not colour.has(other):
					colour[other] = 1 - int(colour[at])
					queue.append(other)
				elif int(colour[other]) == int(colour[at]) and witness.size() < 3:
					witness.append("%d-%d" % [at, other])
	return {"islands": count, "contacts": edges.size(), "deepest": deepest,
			"bipartite": witness.is_empty(), "witness": witness,
			"sur_terre": int(piles.get("terre", 0)), "sur_vide": int(piles.get("vide", 0))}


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
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(h):
		var line: String = ""
		for x: int in range(w):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
