extends SceneTree

## LE BANC DU NOUVEAU MODELE — il rend l'image et REGARDE LES PIXELS.
##
##     godot --headless --path . --script res://proof/massif_ladder.gd
##     godot --headless --path . --script res://proof/massif_ladder.gd -- 200   (tirages)
##
## ⚠ IL NE REDERIVE JAMAIS LE CALCUL QU'IL CONTROLE. C'est la faute la plus chere du projet, et
## elle est deja au dossier : un test qui recalcule avec la formule qu'il verifie certifie
## l'erreur au lieu de l'attraper. Ici on compose et on compte des pixels ; un trou est un trou,
## quelle que soit la regle qui a cru le boucher.
##
## Trois invariants, et ce sont ceux qui ont attrape TOUS les defauts de l'ancien modele :
##   I1 FERMETURE   le contour n'a aucune extremite ouverte -- rien ne pend dans le vide ;
##   I2 EPAISSEUR   aucun pave 2x2 entierement de trait -- deux traits ne se collent jamais ;
##   I6 VERITE      aucun pixel de fond la ou le monde a de la matiere.
##
## ⚠ ET I6 NE REGARDE QUE LES CASES INTERIEURES. Une case du BORD du monde montre le vide sur
## une partie de sa case, et c'est juste -- c'est le rivage. Exiger l'opacite la accuserait le
## dessin d'etre fidele : on ne controle donc que les cases dont les quatre voisines cardinales
## sont, elles aussi, de la matiere.

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")
const Scene := preload("res://render/massif_scene.gd")
const Thickness := preload("res://core/thickness.gd")

const RES: int = MassifTiles.RES
const OUTLINE: Color = MassifTiles.OUTLINE

## Le monde d'un tirage, et sa marge de vide : la falaise du bord du monde y tombe.
const WIDE: int = 22
const TALL: int = 24
const RIM: int = 4


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var draws: int = args[0].to_int() if not args.is_empty() else 60
	var worlds: Array[Dictionary] = []
	worlds.append({"name": "guide", "world": HeightMask.read("res://guides/massifs.txt")})
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x4D415353
	var made: int = 0
	var refused: int = 0
	while made < draws:
		var one: PackedStringArray = _draw(rng)
		if one.is_empty():
			continue
		# ⚠ ET ON NE CACHE PAS CE QU'ON ECARTE. Un tirage qui viole la MARGE DE PIED est un
		# relief que le pinceau corrigera avant de le laisser poser : le banc prouve le DESSIN
		# sur des mondes legaux, pas sur des mondes que le produit ne fabriquera jamais. Le
		# compte est imprime -- une borne muette se lit comme « tout couvert ».
		if not Massifs.foot_faults(one).is_empty():
			refused += 1
			continue
		made += 1
		worlds.append({"name": "tirage %d" % made, "world": one})
	print("%d tirages retenus, %d ecartes par la marge de pied" % [made, refused])

	var green: bool = true
	var vocabulary: Dictionary = {}
	for freedom: int in [0, 1, 2]:
		var ends: int = 0
		var pave: int = 0
		var holes: int = 0
		var poses: int = 0
		var worst: String = ""
		var species: Dictionary = {}
		for entry: Dictionary in worlds:
			var world: PackedStringArray = entry["world"]
			for pose: Dictionary in Massifs.poses(world):
				vocabulary[Massifs.key_of(pose)] = true
				poses += 1
			var image: Image = Scene.compose(world, freedom)
			var got: Dictionary = _measure(image, world, species, Massifs.poses(world))
			ends += int(got["ends"])
			pave += int(got["pave"])
			holes += int(got["holes"])
			if worst.is_empty() and (int(got["ends"]) > 0 or int(got["pave"]) > 0
					or int(got["holes"]) > 0):
				worst = "%s : %s" % [entry["name"], got["where"]]
		var ok: bool = ends == 0 and pave == 0 and holes == 0
		green = green and ok
		print("F%d  %s   I1 extremites %-5d I2 paves %-5d I6 trous %-5d  (%d poses)"
				% [freedom, "VERT " if ok else "ROUGE", ends, pave, holes, poses])
		if not worst.is_empty():
			print("      premier defaut : %s" % worst)
			# ⚠ ET ON NOMME L'ESPECE, PAS SEULEMENT LE PIXEL. Un compte dit qu'il y a une
			# rupture, pas laquelle -- et sans le « qui trace contre qui » on corrige au juge.
			var kinds: Array[String] = []
			kinds.assign(species.keys())
			kinds.sort_custom(func(p: String, q: String) -> bool:
				return int(species[p]) > int(species[q]))
			for at: int in range(mini(6, kinds.size())):
				print("        %5d  %s" % [int(species[kinds[at]]), kinds[at]])

	var by_band: Dictionary = {}
	for key: int in vocabulary.keys():
		var name: String = "%s %s" % [Massifs.BAND_NAMES[Massifs.band_of(key)],
				"au ras" if Massifs.flush_of(key) else "libre"]
		by_band[name] = int(by_band.get(name, 0)) + 1
	var names: Array[String] = []
	names.assign(by_band.keys())
	names.sort()
	print("")
	print("LE VOCABULAIRE RENCONTRE : %d tuiles sur %d mondes" % [vocabulary.size(), worlds.size()])
	for name2: String in names:
		print("    %-22s %d" % [name2, int(by_band[name2])])
	print("")
	print("VERDICT : %s" % ("VERT" if green else "ROUGE"))
	quit(0 if green else 1)


## LES TROIS MESURES, sur l'image composee.
func _measure(image: Image, world: PackedStringArray, species: Dictionary,
		poses: Array[Dictionary] = []) -> Dictionary:
	var top: Dictionary = {}
	for pose: Dictionary in poses:
		top[pose["cell"]] = pose
	var width: int = image.get_width()
	var height: int = image.get_height()
	var stroke: Array[PackedByteArray] = []
	var solid: Array[PackedByteArray] = []
	for y: int in range(height):
		var a: PackedByteArray = PackedByteArray()
		var b: PackedByteArray = PackedByteArray()
		a.resize(width)
		b.resize(width)
		for x: int in range(width):
			var c: Color = image.get_pixel(x, y)
			a[x] = 1 if c.is_equal_approx(OUTLINE) else 0
			b[x] = 1 if c.a >= 0.5 else 0
		stroke.append(a)
		solid.append(b)

	# I1 : un pixel de trait qui n'a qu'UN voisin de trait est une extremite. ⚠ Et une extremite
	# NOYEE dans la matiere n'est pas un trou -- le trait passe derriere une couche et reprend de
	# l'autre cote. On ne compte que celles qui touchent du fond.
	var ends: int = 0
	var where: String = ""
	for y2: int in range(height):
		for x2: int in range(width):
			if stroke[y2][x2] == 0:
				continue
			var around: int = 0
			var breathes: bool = false
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var nx: int = x2 + dx
					var ny: int = y2 + dy
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						breathes = true
						continue
					if solid[ny][nx] == 0:
						breathes = true
					if (dx != 0 or dy != 0) and stroke[ny][nx] == 1:
						around += 1
			if around > 1 or not breathes:
				continue
			ends += 1
			if where.is_empty():
				where = "extremite au pixel %d,%d (case %d,%d)" \
						% [x2, y2, x2 / RES, y2 / RES]

	# I2 : un pave 2x2 entierement de trait. ⚠ C'EST LUI QUI ATTRAPE LE DOUBLEMENT, pas le compte
	# de morceaux : deux traits colles forment UN seul morceau, donc le compte de morceaux est
	# content pendant que l'oeil voit un renflement.
	var pave: int = 0
	for y3: int in range(height - 1):
		for x3: int in range(width - 1):
			if stroke[y3][x3] == 1 and stroke[y3][x3 + 1] == 1 \
					and stroke[y3 + 1][x3] == 1 and stroke[y3 + 1][x3 + 1] == 1:
				pave += 1
				if where.is_empty():
					where = "pave au pixel %d,%d (case %d,%d)" % [x3, y3, x3 / RES, y3 / RES]
				if not top.is_empty():
					var ca: Vector2i = Vector2i(x3 / RES, y3 / RES)
					var cb: Vector2i = Vector2i((x3 + 1) / RES, (y3 + 1) / RES)
					var kind: String = "%s | %s (%s)" % [_say(top.get(ca, {})),
							_say(top.get(cb, {})),
							"vertical" if ca.y != cb.y else (
							"lateral" if ca.x != cb.x else "DEDANS")]
					species[kind] = int(species.get(kind, 0)) + 1

	# I6 : la matiere ne montre pas le fond. Cases INTERIEURES seulement -- voir l'en-tete.
	var holes: int = 0
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	for cy: int in range(tall):
		for cx: int in range(wide):
			if HeightMask.level_at(world, cx, cy) < 0:
				continue
			var inner: bool = true
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if HeightMask.level_at(world, cx + step.x, cy + step.y) < 0:
					inner = false
			if not inner:
				continue
			var pierced: bool = false
			for py: int in range(cy * RES, cy * RES + RES):
				for px: int in range(cx * RES, cx * RES + RES):
					if solid[py][px] == 0:
						pierced = true
			if pierced:
				holes += 1
				if where.is_empty():
					where = "case percee en %d,%d" % [cx, cy]
	return {"ends": ends, "pave": pave, "holes": holes, "where": where}


func _say(pose: Variant) -> String:
	if not (pose is Dictionary) or (pose as Dictionary).is_empty():
		return "rien"
	var one: Dictionary = pose as Dictionary
	return "%s/%d/e%d/%s" % [Massifs.BAND_NAMES[int(one["band"])], int(one["sil"]),
			int(one["level"]), "ras" if bool(one["flush"]) else "libre"]


## UN RELIEF EPAIS TIRE AU SORT : des tampons 3x3, comme le pinceau les pose.
##
## ⚠ ET LE DOMAINE ENUMERE DOIT ETRE LE DOMAINE. Des blocs rectangulaires ne produisent ni
## encoche, ni coude, ni bord sud decroche : ils rendraient un vocabulaire deux fois trop petit
## et le banc ne verrait jamais les cas qui cassent.
func _draw(rng: RandomNumberGenerator) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for y: int in range(TALL):
		var line: PackedByteArray = PackedByteArray()
		line.resize(WIDE)
		line.fill(0)
		grid.append(line)
	for x: int in range(RIM, WIDE - RIM):
		for y2: int in range(RIM, TALL - RIM):
			var row: PackedByteArray = grid[y2]
			row[x] = 1
			grid[y2] = row
	# Les plateaux : des tampons 3x3, chacun elevant ce qu'il touche d'un etage.
	for _stamp: int in range(rng.randi_range(3, 10)):
		var ox: int = rng.randi_range(RIM + 1, WIDE - RIM - 4)
		var oy: int = rng.randi_range(RIM + 1, TALL - RIM - 8)
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				var row2: PackedByteArray = grid[y3]
				row2[x3] = mini(int(row2[x3]) + 1, 4)
				grid[y3] = row2
	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said: String = ""
		for v: int in line2:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	if not Thickness.thin_cells(text).is_empty():
		return PackedStringArray()
	return text
