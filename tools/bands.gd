extends SceneTree

## L'ENUMERATION DU NOUVEAU MODELE : quels couples (silhouette d'EMPREINTE, BANDE) existent.
##
##     godot --headless --path . --script res://tools/bands.gd -- [tirages]
##
## ⚠ ET C'EST LE COUPLE QUI EST LA TUILE, PAS LA SILHOUETTE SEULE. Une meme silhouette
## d'empreinte peut tomber sur une case de SURFACE ou sur une case de FALAISE -- la matiere
## differe, donc ce sont deux tuiles. Le vocabulaire est donc (silhouette x bande), et beaucoup
## de couples sont impossibles : une case de falaise vit dans une jupe de trois rangees, son
## voisinage est tres contraint.
##
## ⚠ ET ON ENUMERE UN MASSIF SEUL. C'est tout l'interet du modele : un massif est AUTONOME, sa
## silhouette ne depend jamais de ce qu'on pose dessus ni de ce qui l'entoure. Ce qu'un massif
## seul produit est donc tout ce que le modele peut produire.

const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")

## Les bandes, dans l'ordre du haut vers le bas.
const SURFACE: int = 0
const CHAPITEAU: int = 1
const CORPS: int = 2
const PIED: int = 3
const BAND_NAMES: Array[String] = ["SURFACE", "CHAPITEAU", "CORPS", "PIED"]

## La hauteur d'une falaise, en tuiles.
const FALL: int = 3

const WIDE: int = 11
const TALL: int = 13


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var draws: int = args[0].to_int() if not args.is_empty() else 4000
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x50106
	var seen: Dictionary = {}
	var made: int = 0
	for run: int in range(draws):
		var surface: Array[PackedByteArray] = _surface(rng)
		if surface.is_empty():
			continue
		made += 1
		_collect(surface, seen)
	var keys: Array[int] = []
	keys.assign(seen.keys())
	keys.sort()
	var by_band: Dictionary = {}
	for key: int in keys:
		var band: int = key >> 8
		by_band[band] = int(by_band.get(band, 0)) + 1
	# ⚠ LE BIT RECOUVRANT NE DOUBLE QUE CE QUI SE DESSINE. Un massif recouvrant a son
	# rendez-vous AU RAS -- l'arete touche la bordure de tuile -- un massif libre l'a a
	# mi-tuile ; entre deux rendez-vous, les deux ondulent librement. Deux tuiles qui se
	# rencontrent doivent s'accorder sur ce point, donc c'est bien une tuile de plus -- mais
	# SEULEMENT si la tuile a un cote ouvert a dessiner. Une tuile sans aucun cote ouvert est
	# la meme des deux cotes.
	var doubled: int = 0
	for key3: int in keys:
		var sil: int = key3 & 0xff
		var open_sides: int = 0
		for card: int in [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]:
			if (sil & card) == 0:
				open_sides += 1
		doubled += 2 if open_sides > 0 else 1
	print("=== LE VOCABULAIRE DU NOUVEAU MODELE ===")
	print("  %d surfaces tirees, %d couples (silhouette, bande) distincts" % [made, keys.size()])
	for band2: int in range(4):
		var said: PackedStringArray = PackedStringArray()
		for key2: int in keys:
			if (key2 >> 8) == band2:
				said.append(str(key2 & 0xff))
		print("  %-10s : %2d  %s" % [BAND_NAMES[band2], said.size(), " ".join(said)])
	print("  avec le bit RECOUVRANT : %d tuiles" % doubled)
	quit(0)


## UNE SURFACE DE MASSIF : un blob epais tire au sort, d'un seul tenant.
func _surface(rng: RandomNumberGenerator) -> Array[PackedByteArray]:
	var grid: Array[PackedByteArray] = []
	for y: int in range(TALL):
		var line: PackedByteArray = PackedByteArray()
		line.resize(WIDE)
		line.fill(0)
		grid.append(line)
	# ⚠ DES TAMPONS 3x3, PAS DES RECTANGLES -- et c'est le geste REEL du pinceau. Des blocs
	# rectangulaires ne produisent ni encoche, ni coude, ni bord sud decroche : ils rendaient
	# dix silhouettes de surface sur les vingt-sept possibles, et l'enumeration aurait annonce
	# un vocabulaire deux fois trop petit. Le domaine enumere doit etre le domaine.
	for _stamp: int in range(rng.randi_range(2, 7)):
		var ox: int = rng.randi_range(1, WIDE - 4)
		var oy: int = rng.randi_range(1, TALL - 8)
		for y2: int in range(oy, oy + 3):
			for x2: int in range(ox, ox + 3):
				var row: PackedByteArray = grid[y2]
				row[x2] = 1
				grid[y2] = row
	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said2: String = ""
		for v: int in line2:
			said2 += "1" if v == 1 else "."
		text.append(said2)
	if not Thickness.thin_cells(text).is_empty():
		return []
	return grid


## L'EMPREINTE, PUIS LES COUPLES. La falaise pend sous le bord sud de la SURFACE : pour chaque
## colonne ou la surface s'arrete a la rangee s, elle occupe s+1, s+2, s+3.
func _collect(surface: Array[PackedByteArray], seen: Dictionary) -> void:
	var band_of: Dictionary = {}
	for x: int in range(WIDE):
		for y: int in range(TALL):
			if int(surface[y][x]) == 0:
				continue
			band_of[Vector2i(x, y)] = SURFACE
			# ⚠ LE BORD SUD SE LIT PAR COLONNE : c'est la derniere case pleine AVANT un vide,
			# pas la derniere de la colonne. Un massif peut avoir plusieurs bords sud dans une
			# meme colonne -- une encoche -- et chacun porte sa propre falaise.
			if y + 1 < TALL and int(surface[y + 1][x]) != 0:
				continue
			for step: int in range(1, FALL + 1):
				var at: Vector2i = Vector2i(x, y + step)
				if at.y >= TALL:
					break
				# La surface l'emporte : une falaise qui retombe sur la surface du meme
				# massif est cachee par elle.
				if not band_of.has(at):
					band_of[at] = step
	for cell: Vector2i in band_of.keys():
		var raw: int = 0
		for bit: int in range(8):
			var near: Vector2i = cell + BlobIndex.OFFSETS[bit]
			if band_of.has(near):
				raw |= 1 << bit
		seen[(int(band_of[cell]) << 8) | BlobIndex.canonicalize(raw)] = true
