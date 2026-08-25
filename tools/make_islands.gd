extends SceneTree

## L'ILOT D'UNE TUILE, CHERCHE PUIS VERIFIE -- jamais raisonne.
##
## ⚠ LA GEOMETRIE D'UNE LEVRE VOISINE NE SE DEDUIT PAS A LA MAIN. J'ai essaye : une lèvre
## collee a l'ilot pince une colonne de vide d'UNE case ; posee trois rangees plus haut elle
## pince ailleurs ; et quand les deux bords veulent de la roche avec le nord vide, aucune
## position ne marche localement -- la levre doit venir de plus haut avec une chute longue.
## Trois raisonnements, trois erreurs. La lecon est deja au dossier : le relief se decrit
## accident par accident, jamais en ASCII, et ce qui se calcule ne se dessine pas.
##
## On CHERCHE donc : l'ilot etire, plus zero a deux blocs de falaise poses au balayage, et
## chaque candidat passe au juge -- epais ? porte-t-il la tuile annoncee ? Le premier qui
## passe est le bon, et il est prouve par construction.

const BlobIndex := preload("res://core/blob_index.gd")
const Coverage := preload("res://core/coverage.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const HeightMask := preload("res://core/height_mask.gd")

const SIDE: int = 33          # le cadre de recherche
const CENTRE: int = 16
const EDGE: int = 3           # la marge de vide, comme la planche
const DEEP: int = 6           # et la marge basse, une chute entiere
const GROUND: int = 1         # l'etage de l'ilot ; les falaises viennent au-dessus


func _initialize() -> void:
	# ⚠ ET LA LEVRE NE SE POSE PAS FORCEMENT ALIGNEE. Premier essai : blocs alignes sur
	# trois, comme une main. Quatre tuiles s'y perdaient -- celles dont le nord veut de la
	# roche et l'est du nu -- parce que leur bloc doit chevaucher la colonne du VOISIN PLEIN
	# pour ne pas tomber sur celle du voisin vide, et cette position-la n'est pas alignee.
	# La recherche a un bloc balaie donc TOUTES les positions ; celle a deux blocs reste
	# alignee, ou le nombre de couples exploserait.
	var spots: Array[Vector2i] = []
	for oy: int in range(-9, 7):
		for ox: int in range(-9, 7):
			spots.append(Vector2i(ox, oy))
	var pairs: Array[Vector2i] = []
	for oy: int in [-9, -6, -3, 0, 3, 6]:
		for ox: int in [-9, -6, -3, 0, 3, 6]:
			pairs.append(Vector2i(ox, oy))
	var solved: Dictionary = {}
	var lost: Array[int] = []
	for tile: int in Thickness.SURFACE_INDICES:
		var relief: PackedStringArray = _search(tile, spots, pairs)
		if relief.is_empty():
			lost.append(tile)
		else:
			solved[tile] = relief
	print("ilots trouves : %d   perdus : %d" % [solved.size(), lost.size()])
	for tile: int in lost:
		print("  perdue : %3d %s" % [BlobIndex.silhouette(tile), BlobIndex.brink_name(tile)])
	var text: String = ""
	var keys: Array = solved.keys()
	keys.sort()
	for tile: Variant in keys:
		text += "# %d %s\n" % [int(tile), BlobIndex.brink_name(int(tile))]
		for line: String in solved[tile] as PackedStringArray:
			text += "%s\n" % line
		text += "\n"
	var file: FileAccess = FileAccess.open("res://tools/islands.txt", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	quit()


func _search(tile: int, spots: Array[Vector2i],
		pairs: Array[Vector2i]) -> PackedStringArray:
	var base: Dictionary = {}
	for offset: Vector2i in ProofScene.island_cells(BlobIndex.silhouette(tile)):
		base[Vector2i(CENTRE, CENTRE) + offset] = GROUND
	# Zero bloc, puis un, puis deux : on prend le plus simple qui passe.
	var first: PackedStringArray = _judge(tile, base, [])
	if not first.is_empty():
		return first
	for a: Vector2i in spots:
		var one: PackedStringArray = _judge(tile, base, [a])
		if not one.is_empty():
			return one
	for a: Vector2i in pairs:
		for b: Vector2i in pairs:
			if b.x <= a.x and b.y <= a.y:
				continue
			var two: PackedStringArray = _judge(tile, base, [a, b])
			if not two.is_empty():
				return two
	return PackedStringArray()


## Le juge : epais, et la case du centre porte EXACTEMENT la tuile annoncee.
func _judge(tile: int, base: Dictionary, blocks: Array) -> PackedStringArray:
	var cells: Dictionary = base.duplicate()
	for at: Variant in blocks:
		for dy: int in range(3):
			for dx: int in range(3):
				cells[Vector2i(CENTRE, CENTRE) + (at as Vector2i) + Vector2i(dx, dy)] = GROUND + 1
	# ⚠ LE TEMOIN SE CHERCHE DANS LE CONTEXTE OU IL SERVIRA : sur la PLAINE, pas sur le
	# vide. Mesure avant d'ecrire : sur fond de vide, une levre d'etage 2 tombe de neuf
	# rangees et couvre ma voisine ; sur la plaine elle ne tombe que de six et s'arrete UNE
	# RANGEE TROP HAUT. Six tuiles a bord roche sortaient alors en bord nu -- l'ilot montrait
	# leur jumelle sans le dire. La planche de preuve et la reserve du guide sont toutes
	# deux posees sur la plaine : c'est donc la plaine qu'il faut mettre autour.
	var heights: PackedStringArray = PackedStringArray()
	for y: int in range(SIDE):
		var line: String = ""
		for x: int in range(SIDE):
			var key: Vector2i = Vector2i(x, y)
			if cells.has(key):
				line += str(int(cells[key]))
			elif y < EDGE or y >= SIDE - DEEP or x < EDGE or x >= SIDE - EDGE:
				line += "~"
			else:
				line += "0"
		heights.append(line)
	if not Thickness.thin_cells(heights).is_empty():
		return PackedStringArray()
	# ⚠ ET LA CASE DOIT RESTER PEIGNABLE, pas seulement porter le bon index. Une levre posee
	# au-dessus de MA PROPRE COLONNE fait tomber sa face sur moi : l'index ne bouge pas -- il
	# se lit de la silhouette de mon etage -- mais la case porte desormais la ROBE, et plus
	# aucune surface. L'ilot annoncait alors une tuile que personne ne pourrait peindre.
	# On juge donc sur la meme carte que le guide et l'editeur : `Families.surface_map`.
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var here: Vector2i = Vector2i(CENTRE, CENTRE)
	if not surface.has(here):
		return PackedStringArray()
	if HeightMask.level_at(heights, CENTRE, CENTRE) < 1:
		return PackedStringArray()
	if int(surface[here]) != tile:
		return PackedStringArray()
	return heights
