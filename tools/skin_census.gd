extends SceneTree

## LE RACCORD SURFACE ↔ ROBE : recensement avant fermeture.
##
## ⚠ IL N'EXISTE AUCUNE CLASSE ENTRE UNE SURFACE ET UNE ROBE, et c'est ce qui fabrique les
## lentilles. A la frontiere entre l'herbe d'un plateau et la roche d'une falaise voisine, LES
## DEUX COTES CREUSENT : la surface parce que son cardinal est vide, la robe parce que son
## flanc dit `arret`. Chacune bombe vers l'interieur, les deux se pincent aux coins -- d'ou une
## lentille fermee de six pixels sur une case de seize.
##
## `Seams` lie les robes entre elles ; le dossier ecrit que « les surfaces n'en sont pas ». A
## cette frontiere-la, les deux traits sont donc libres l'un de l'autre, et rien ne les oblige
## a se ressembler entre les deux coins.
##
## ⚠ ET LA REPONSE N'A PAS ETE UNE CLASSE. Le recensement a servi, mais pas a ce pour quoi il
## avait ete ecrit : il a montre que TOUS les couples sont lateraux -- est et ouest -- et cela
## a suffi a voir que lier les deux profils n'y changerait rien. Deux aretes qui se font face
## sont de part et d'autre de la MEME frontiere : chacune creuse vers son propre interieur,
## donc il reste un vide entre elles quoi qu'on impose a leurs formes. Les rendre egales rend
## le vide symetrique, pas nul.
##
## Mesure des deux reglages essayes, chacun echangeant un defaut contre l'autre :
##   * pincer les deux au bord : le vide se referme a chaque frontiere de rangees et se decoupe
##     en CHAINE DE LENTILLES -- 34 contours fermes, et des ovales plein la falaise ;
##   * pincer a profondeur commune : plus d'ovales, mais le vide ne se referme plus nulle part
##     -- 138 morceaux dont 114 segments ouverts.
##
## Ce qui a ferme la question : QUE L'UN DES DEUX NE CREUSE PAS. Un flanc qui s'arrete remplit
## sa case jusqu'au bord et marque sa fin d'un TRAIT. C'est la regle des couches a la lettre --
## une tuile remplit sa case, ce qui est a cote appartient au voisin -- et il n'y a plus de
## vide, donc plus rien a accorder. 34 contours, zero tiret, zero ovale.
##
## Le fichier reste comme trace de la mesure, et parce qu'il repond encore a une question
## utile : QUELLES frontieres portent deux aretes libres. S'il en apparaissait une au nord ou
## au sud un jour, la loi ci-dessus devrait etre reprise.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const ProofScene := preload("res://core/proof_scene.gd")

## Les quatre bords d'une tuile, dans l'ordre nord, est, sud, ouest.
const SIDE_NAMES: Array[String] = ["N", "E", "S", "O"]
const SIDE_STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SIDE_CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]

## Une arete se nomme : famille (0 surface, 1 robe), identite, cote.
static var _parent: Dictionary = {}


func _initialize() -> void:
	var pairs: Dictionary = {}
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	_gather(guide, pairs)
	_gather(ProofScene.relief(Families.BY_CELL), pairs)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var kept: int = 0
	while kept < 120:
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		kept += 1
		_gather(relief, pairs)

	print("=== LE RACCORD SURFACE ↔ ROBE ===")
	print("guide, planche et %d reliefs epais tires au sort" % kept)
	print("")
	print("1. COUPLES D'ARETES QUI SE TOUCHENT : %d" % pairs.size())
	var by_side: Dictionary = {}
	for key: Variant in pairs.keys():
		var side: int = int((key as Array)[4])
		by_side[side] = int(by_side.get(side, 0)) + 1
	for side: int in range(4):
		if by_side.has(side):
			print("   surface par son %s contre une robe : %d couples"
					% [SIDE_NAMES[side], int(by_side[side])])

	# 2. La fermeture : chaque couple lie deux aretes, on suit la transitivite.
	_parent = {}
	for key: Variant in pairs.keys():
		var entry: Array = key as Array
		_join(Vector3i(0, int(entry[0]), int(entry[1])),
				Vector3i(1, int(entry[2]) * 8 + int(entry[3]), int(entry[5])))
	var roots: Dictionary = {}
	var members: Dictionary = {}
	for edge: Vector3i in _parent.keys():
		var root: Vector3i = _find(edge)
		roots[root] = true
		members[root] = int(members.get(root, 0)) + 1
	print("")
	print("2. ARETES LIEES : %d   CLASSES : %d" % [_parent.size(), roots.size()])
	var sizes: Array[int] = []
	for root: Vector3i in members.keys():
		sizes.append(int(members[root]))
	sizes.sort()
	if not sizes.is_empty():
		print("   la plus petite : %d aretes   la plus grande : %d"
				% [sizes[0], sizes[sizes.size() - 1]])

	# 3. Combien d'aretes de chaque famille sont concernees, sur combien au total.
	var surfaces: Dictionary = {}
	var robes: Dictionary = {}
	for edge: Vector3i in _parent.keys():
		if edge.x == 0:
			surfaces[Vector2i(edge.y, edge.z)] = true
		else:
			robes[Vector2i(edge.y, edge.z)] = true
	print("")
	print("3. ARETES CONCERNEES")
	print("   de surface : %d   (sur %d tuiles x 4 cotes = %d)"
			% [surfaces.size(), Thickness.SURFACE_INDICES.size(),
			Thickness.SURFACE_INDICES.size() * 4])
	print("   de robe    : %d   (sur %d roles x 4 cotes = %d)"
			% [robes.size(), Thickness.wall_roles().size(),
			Thickness.wall_roles().size() * 4])
	quit()


## Les couples d'aretes qui se touchent, sur un relief.
func _gather(heights: PackedStringArray, pairs: Dictionary) -> void:
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var roles: Dictionary = Walls.visible_roles(heights)
	for at: Vector2i in surface.keys():
		var index: int = BlobIndex.silhouette(int(surface[at]))
		for side: int in range(4):
			# ⚠ ON NE RETIENT QUE LES CARDINAUX VIDES : ailleurs la matiere continue chez la
			# voisine, il n'y a pas d'arete. Et le SUD est exclu -- une case dont le sud est
			# vide est une levre, sa propre falaise commence juste dessous et il n'y a pas de
			# vide entre les deux.
			if side == 2:
				continue
			if (index & SIDE_CARDINALS[side]) != 0:
				continue
			var probe: Vector2i = at + SIDE_STEPS[side]
			if not roles.has(probe):
				continue
			var role: Vector2i = roles[probe]
			# Le cote de la robe qui me fait face.
			var facing: int = (side + 2) % 4
			# ⚠ ET LA ROBE NE CREUSE QU'A SES FLANCS ET A SA CRETE : ailleurs sa roche
			# continue d'un cran a l'autre de la chute, il n'y a rien a accorder.
			if facing == 1 and Walls.pan_east(role.x) == Walls.SIDE_MUTE:
				continue
			if facing == 3 and Walls.pan_west(role.x) == Walls.SIDE_MUTE:
				continue
			# ⚠ ET LE PIED, PAS LE CHAPITEAU. Mon nord vide veut dire que la case du dessus
			# est plus basse ; si elle porte une robe, c'est son bord SUD qui me fait face --
			# et ce bord ne se creuse qu'au pied. Premiere version : j'avais teste le
			# chapiteau, donc le cas nord ne sortait jamais et le recensement annoncait zero.
			if facing == 2 and role.y != Walls.ROW_FOOT:
				continue
			pairs[[index, side, role.x, role.y, side, facing]] = true


func _join(a: Vector3i, b: Vector3i) -> void:
	var ra: Vector3i = _find(a)
	var rb: Vector3i = _find(b)
	if ra != rb:
		_parent[ra] = rb


func _find(edge: Vector3i) -> Vector3i:
	if not _parent.has(edge):
		_parent[edge] = edge
		return edge
	var root: Vector3i = edge
	while _parent[root] != root:
		root = _parent[root]
	return root


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
