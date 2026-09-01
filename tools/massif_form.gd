extends SceneTree

## LA FORME FERMEE DU VOCABULAIRE DES MASSIFS.
##
##     godot --headless --path . --script res://tools/massif_form.gd -- [tirages]
##
## ⚠ ET ELLE SE CONTROLE DANS LES DEUX SENS, sinon elle ne garde rien. C'est la faute la plus
## chere du projet, deja payee deux fois : un garde-fou qui ne regarde que d'un cote laisse
## passer ce qu'il ne cherche pas. Donc :
##   la BORNE HAUTE  -- l'enumeration exhaustive ci-dessous : ce que le modele PEUT produire ;
##   la BORNE BASSE  -- une battue sur des reliefs epais : ce qu'il produit VRAIMENT.
## Si les deux se rejoignent, la forme est close. Sinon l'ecart se paie en temoins construits ou
## en arguments d'impossibilite -- jamais en « la battue ne l'a pas vu, donc ca n'existe pas » :
## une battue qui ne rencontre pas une tuile prouve qu'elle est rare, jamais qu'elle est
## impossible.
##
## LA FENETRE, ET POURQUOI ELLE SUFFIT. L'empreinte d'une colonne ne depend que de cette
## colonne : une case est de la falaise si un bord sud de son massif se trouve une, deux ou trois
## rangees plus haut. Pour lire la silhouette de la case centrale il faut l'empreinte de ses huit
## voisines, donc trois colonnes et trois rangees d'empreinte, donc trois colonnes et SIX rangees
## de surface. 2^18 fenetres : exhaustif.
##
## ⚠ ET MIN TROIS REND LA JUPE NON AMBIGUE. Deux bords sud dans une meme colonne sont separes
## d'au moins quatre rangees -- le vide entre eux est une course, donc au moins trois -- si bien
## que deux jupes ne se disputent jamais une case. Sans min trois, la bande d'une case dependrait
## de l'ordre de parcours, et le modele aurait un endroit ou mentir.

const BlobIndex := preload("res://core/blob_index.gd")
const Massifs := preload("res://core/massifs.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")

const COLS: int = 3
const ROWS: int = 6
const CX: int = 1
const CY: int = 4


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var draws: int = args[0].to_int() if not args.is_empty() else 400
	var upper: Dictionary = {}
	var kept: int = 0
	for bits: int in range(1 << (COLS * ROWS)):
		var surface: Array[PackedByteArray] = _window(bits)
		if _thin_inside(surface):
			continue
		kept += 1
		_couples(surface, upper)
	var met: Dictionary = _battue(draws)

	var only_high: Array[int] = []
	var only_low: Array[int] = []
	for key: int in upper.keys():
		if not met.has(key):
			only_high.append(key)
	for key2: int in met.keys():
		if not upper.has(key2):
			only_low.append(key2)
	only_high.sort()
	only_low.sort()

	print("=== LA FORME FERMEE DES MASSIFS ===")
	print("  fenetres retenues : %d sur %d" % [kept, 1 << (COLS * ROWS)])
	print("  BORNE HAUTE (enumeration) : %d couples (silhouette, bande)" % upper.size())
	print("  BORNE BASSE (battue)      : %d couples" % met.size())
	for band: int in range(4):
		var said: PackedStringArray = PackedStringArray()
		for key3: int in _sorted(upper):
			if (key3 >> 8) == band:
				said.append(str(key3 & 0xff))
		print("    %-10s %2d  %s" % [Massifs.BAND_NAMES[band], said.size(), " ".join(said)])
	print("")
	if not only_low.is_empty():
		print("  ⚠ %d couples POSES et pourtant hors de la forme -- la forme est FAUSSE :"
				% only_low.size())
		for key4: int in only_low:
			print("      %s/%d" % [Massifs.BAND_NAMES[key4 >> 8], key4 & 0xff])
	if only_high.is_empty():
		print("  les deux bornes se rejoignent : la forme est CLOSE.")
	else:
		print("  %d couples enumeres que la battue n'a pas rencontres :" % only_high.size())
		for key5: int in only_high:
			print("      %s/%d" % [Massifs.BAND_NAMES[key5 >> 8], key5 & 0xff])

	# ⚠ ET LE BIT RECOUVRANT NE DOUBLE QUE CE QUI SE DESSINE AUTREMENT. Il deplace le
	# RENDEZ-VOUS : une tuile dont aucun bord n'est ouvert et qui n'a aucun coin rentrant se
	# dessine pareil des deux cotes, et n'est donc qu'UNE tuile.
	var tiles: int = 0
	for key6: int in upper.keys():
		tiles += 2 if _varies(key6 & 0xff) else 1
	print("")
	print("  AVEC LE BIT RECOUVRANT : %d tuiles." % tiles)
	quit(0 if only_low.is_empty() else 1)


func _sorted(what: Dictionary) -> Array[int]:
	var out: Array[int] = []
	out.assign(what.keys())
	out.sort()
	return out


## Une tuile se dessine-t-elle autrement au ras qu'en liberte ? Oui des qu'un bord est ouvert --
## il rentre -- et oui aussi pour un COIN RENTRANT, qui se creuse a la meme profondeur que les
## bords alors que ses deux cardinaux sont pleins.
func _varies(sil: int) -> bool:
	for card: int in [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]:
		if (sil & card) == 0:
			return true
	for corner: int in range(4):
		var a: int = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W][corner]
		var b: int = [BlobIndex.W, BlobIndex.N, BlobIndex.E, BlobIndex.S][corner]
		var d: int = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW][corner]
		if (sil & a) != 0 and (sil & b) != 0 and (sil & d) == 0:
			return true
	return false


func _window(bits: int) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	for x: int in range(COLS):
		var col: PackedByteArray = PackedByteArray()
		col.resize(ROWS)
		for y: int in range(ROWS):
			col[y] = 1 if (bits & (1 << (x * ROWS + y))) != 0 else 0
		out.append(col)
	return out


## LA REFUTATION LOCALE : une course dont LES DEUX BOUTS sont dans la fenetre et qui fait moins
## de trois. Une course qui touche un bord de la fenetre se prolonge dehors, donc elle ne prouve
## rien -- c'est le meme argument que pour les 27 silhouettes.
func _thin_inside(surface: Array[PackedByteArray]) -> bool:
	for x: int in range(COLS):
		var run: int = 0
		var state: int = -1
		for y: int in range(ROWS):
			var here: int = int(surface[x][y])
			if here == state:
				run += 1
				continue
			if state != -1 and run < 3 and y - run > 0:
				return true
			state = here
			run = 1
	# A l'horizontale la fenetre n'a que trois colonnes : la seule course entierement dedans est
	# celle d'UNE case au milieu, bornee des deux cotes.
	for y2: int in range(ROWS):
		if int(surface[CX][y2]) != int(surface[0][y2]) \
				and int(surface[CX][y2]) != int(surface[2][y2]):
			return true
	return false


## LES COUPLES QUE CETTE FENETRE PRODUIT.
##
## ⚠ ET LE MASSIF SE CHOISIT, IL NE SE SUPPOSE PAS. Deux cases de surface qui se touchent sont
## forcement le MEME massif -- une composante connexe ne se coupe pas. Mais deux composantes
## distinctes de la fenetre peuvent aussi bien etre reliees DEHORS : les deux lectures sont
## realisables, donc on prend les deux. Supposer qu'elles sont separees sous-compterait la forme.
func _couples(surface: Array[PackedByteArray], out: Dictionary) -> void:
	var mark: Array[PackedByteArray] = _components(surface)
	# Le massif de la case centrale : le sien si elle est de la surface, sinon celui du bord sud
	# qui lance la jupe au-dessus d'elle.
	var mine: int = -1
	if int(surface[CX][CY]) == 1:
		mine = int(mark[CX][CY])
	else:
		for step: int in range(1, Massifs.FALL + 1):
			var at: int = CY - step
			if at < 0:
				break
			if int(surface[CX][at]) == 1 and int(surface[CX][at + 1]) == 0:
				mine = int(mark[CX][at])
				break
	if mine < 0:
		return
	var others: Array[int] = []
	for x: int in range(COLS):
		for y: int in range(ROWS):
			if int(surface[x][y]) == 1 and int(mark[x][y]) != mine \
					and not others.has(int(mark[x][y])):
				others.append(int(mark[x][y]))
	for choice: int in range(1 << others.size()):
		var joined: Dictionary = {mine: true}
		for at2: int in range(others.size()):
			if (choice & (1 << at2)) != 0:
				joined[others[at2]] = true
		var band_of: Dictionary = _footprint(surface, mark, joined)
		if not band_of.has(Vector2i(CX, CY)):
			continue
		var raw: int = 0
		for bit: int in range(8):
			if band_of.has(Vector2i(CX, CY) + BlobIndex.OFFSETS[bit]):
				raw |= 1 << bit
		out[(int(band_of[Vector2i(CX, CY)]) << 8) | BlobIndex.canonicalize(raw)] = true


## L'empreinte du massif choisi, sur les rangees qui portent la silhouette centrale.
func _footprint(surface: Array[PackedByteArray], mark: Array[PackedByteArray],
		joined: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for x: int in range(COLS):
		for y: int in range(CY - 1, CY + 2):
			if y < 0 or y >= ROWS:
				continue
			if int(surface[x][y]) == 1 and joined.has(int(mark[x][y])):
				out[Vector2i(x, y)] = Massifs.SURFACE
				continue
			for step: int in range(1, Massifs.FALL + 1):
				var at: int = y - step
				if at < 0:
					break
				if int(surface[x][at]) == 1 and joined.has(int(mark[x][at])) \
						and (at + 1 >= ROWS or int(surface[x][at + 1]) == 0
						or not joined.has(int(mark[x][at + 1]))):
					out[Vector2i(x, y)] = step
					break
	return out


func _components(surface: Array[PackedByteArray]) -> Array[PackedByteArray]:
	var mark: Array[PackedByteArray] = []
	for x: int in range(COLS):
		var col: PackedByteArray = PackedByteArray()
		col.resize(ROWS)
		col.fill(255)
		mark.append(col)
	var next: int = 0
	for x2: int in range(COLS):
		for y2: int in range(ROWS):
			if int(surface[x2][y2]) == 0 or int(mark[x2][y2]) != 255:
				continue
			var stack: Array[Vector2i] = [Vector2i(x2, y2)]
			mark[x2][y2] = next
			while not stack.is_empty():
				var here: Vector2i = stack.pop_back()
				for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
					var near: Vector2i = here + step
					if near.x < 0 or near.y < 0 or near.x >= COLS or near.y >= ROWS:
						continue
					if int(surface[near.x][near.y]) == 0 or int(mark[near.x][near.y]) != 255:
						continue
					mark[near.x][near.y] = next
					stack.append(near)
			next += 1
	return mark


## LA BORNE BASSE : ce que des reliefs epais tires au sort posent vraiment.
func _battue(draws: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x464F524D
	var met: Dictionary = {}
	var made: int = 0
	while made < draws:
		var world: PackedStringArray = _draw(rng)
		if world.is_empty():
			continue
		made += 1
		for pose: Dictionary in Massifs.poses(world):
			met[(int(pose["band"]) << 8) | int(pose["sil"])] = true
	return met


func _draw(rng: RandomNumberGenerator) -> PackedStringArray:
	var wide: int = rng.randi_range(18, 30)
	var tall: int = rng.randi_range(20, 32)
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
	# ⚠ ET IL FAUT EFFACER AUTANT QUE POSER. Un generateur qui ne fait qu'empiler des tampons ne
	# produit que des masses convexes : ni forme en C, ni trou, ni jupe qui retombe sur le massif
	# qui la lance. Il rendait 25 couples sur 46, et l'ecart n'etait pas dans le modele mais dans
	# la battue. Le pinceau, lui, pose ET efface -- le domaine enumere doit etre le domaine.
	for _stamp: int in range(rng.randi_range(3, 12)):
		var ox: int = rng.randi_range(5, wide - 8)
		var oy: int = rng.randi_range(5, tall - 12)
		var raise: bool = rng.randf() < 0.72
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				var row2: PackedByteArray = grid[y3]
				row2[x3] = mini(int(row2[x3]) + 1, 4) if raise else maxi(int(row2[x3]) - 1, 0)
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
