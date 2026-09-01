extends SceneTree

## LE GUIDE DU NOUVEAU MODELE : un massif par forme, libres et recouvrants.
##
##     godot --headless --path . --script res://tools/build_massifs.gd -- <sortie.txt>
##
## ⚠ ET IL EXERCE LE VOCABULAIRE, IL NE FAIT PAS JOLI. Le guide livre actuel a ete bati pour
## l'ancien vocabulaire : il n'empile presque jamais deux massifs, donc il ne peut montrer ni
## un massif RECOUVRANT, ni l'inversion de profondeur que l'ordre de pose doit eviter. Un guide
## qui ne montre pas un cas ne permet ni de le peindre ni de le juger.
##
## ⚠ ET CHAQUE MASSIF EST POSE DEUX FOIS : seul sur la plaine (LIBRE), puis sur un socle
## (RECOUVRANT). C'est la seule difference que le bit porte, et elle doit se voir cote a cote.

const HeightMask := preload("res://core/height_mask.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")
const Massifs := preload("res://core/massifs.gd")
const Bands := preload("res://tools/bands.gd")

## Les formes, dessinees a la main : chacune apporte des silhouettes qu'aucune autre ne donne.
##
## ⚠ ET ELLES SONT EPAISSES, min trois -- c'est ce que le pinceau laissera poser. Une forme
## fine serait un specimen que personne ne pourra jamais reproduire.
const SHAPES: Array = [
	# LE BLOC : les quatre coins, les quatre bords, l'interieur.
	["#####", "#####", "#####", "#####", "#####"],
	# L'EQUERRE : les coins RENTRANTS, que le bloc ne donne pas.
	["#####...", "#####...", "#####...", "########", "########", "########"],
	# LE T : deux coins rentrants d'un coup, et un bord sud a deux decrochements.
	["...###...", "...###...", "...###...", "#########", "#########", "#########"],
	# L'ESCALIER : un bord sud qui decroche d'une rangee a chaque marche.
	["#########", "#########", "#########", "######...", "######...", "###......"],
	# LA CROIX : les quatre coins rentrants sur un seul massif.
	["...###...", "...###...", "#########", "#########", "#########", "...###...", "...###..."],
]

## ⚠ L'ECART DOIT DEPASSER LA FALAISE, ET LARGEMENT. Deux massifs de MEME etage qui se
## touchent FUSIONNENT -- c'est la regle, et elle est juste -- mais un guide ou tous les
## specimens fusionnent en un seul massif ne montre plus rien. Premier essai a six : les dix
## massifs sont devenus six, dont un enorme. La falaise fait trois rangees, le socle en ajoute
## quatre au sud : il faut plus que la somme.
const GAP: int = 12
## Le socle d'un massif recouvrant : la marge autour, et les trois rangees au sud.
const BASE_SIDE: int = 2
const BASE_SOUTH: int = 4
## La marge de vide autour du guide : la plaine a sa falaise au bord du monde.
const RIM: int = 4


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "res://guides/massifs.txt"
	var placed: Array[Dictionary] = []
	var x: int = RIM + 2
	var y: int = RIM + 2
	var tallest: int = 0
	# ⚠ ET UNE CASCADE DE TROIS ETAGES, qui est le seul cas ou l'ORDRE DE POSE se juge. Un
	# massif haut mais situe au NORD ne doit pas passer devant une falaise plus au sud : la vue
	# est de trois quarts, c'est la RANGEE qui dit qui est devant, pas l'etage. Sans ce
	# specimen, ni l'oeil ni l'echelle ne peuvent voir l'inversion.
	#
	# ⚠ ET LE MASSIF DU MILIEU EST A LA FOIS PORTEUR ET PORTE -- il est deja au ras des deux
	# titres, donc rien ne se contredit. C'etait la premiere question de l'analyse, et la
	# cascade est ce qui la met sous les yeux.
	# ⚠ ET CHAQUE ETAGE A **QUATRE** RANGEES DE SURFACE SOUS LUI, PAS TROIS. Mesure, pas
	# raisonnement : a trois, le PIED du massif porte tombe exactement sur la derniere rangee de
	# surface du porteur, donc juste au-dessus de la LEVRE de celui-ci. Les deux tracent -- le
	# pied son bord sud, la levre son trait -- a une rangee d'ecart, et I2 compte 270 paves. Il
	# faut une rangee de surface porteuse VISIBLE sous le pied. Trois pour la jupe, une pour
	# respirer.
	placed.append({"x": RIM + 2, "y": y, "rows": [
		"##################", "##################", "##################",
		"##################", "##################", "##################",
		"##################", "##################", "##################",
		"##################", "##################", "##################",
		"##################", "##################", "##################",
		"##################",
	], "socle": false})
	placed.append({"x": RIM + 5, "y": y + 2, "rows": [
		"############", "############", "############", "############",
		"############", "############", "############", "############",
		"############", "############",
	], "socle": false, "level": 2})
	placed.append({"x": RIM + 8, "y": y + 4, "rows": [
		"######", "######", "######", "######",
	], "socle": false, "level": 3})
	y += 16 + Bands.FALL + GAP

	# Chaque forme deux fois : libre, puis sur son socle.
	for socle: bool in [false, true]:
		for shape: Variant in SHAPES:
			var rows: Array = shape as Array
			var w: int = String(rows[0]).length()
			var h: int = rows.size()
			var full_w: int = w + (2 * BASE_SIDE if socle else 0)
			var full_h: int = h + Bands.FALL + (BASE_SIDE + BASE_SOUTH if socle else 0)
			if x + full_w > 150:
				x = RIM + 2
				y += tallest + GAP
				tallest = 0
			placed.append({"x": x, "y": y, "rows": rows, "socle": socle})
			x += full_w + GAP
			tallest = maxi(tallest, full_h)
		x = RIM + 2
		y += tallest + GAP
		tallest = 0

	var wide: int = 0
	var tall: int = 0
	for one: Dictionary in placed:
		var rows2: Array = one["rows"] as Array
		var w2: int = String(rows2[0]).length() + (2 * BASE_SIDE if bool(one["socle"]) else 0)
		var h2: int = rows2.size() + Bands.FALL \
				+ (BASE_SIDE + BASE_SOUTH if bool(one["socle"]) else 0)
		wide = maxi(wide, int(one["x"]) + w2)
		tall = maxi(tall, int(one["y"]) + h2)
	wide += RIM + 2
	tall += RIM + 2

	var grid: Array[PackedByteArray] = []
	for row: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	# LA PLAINE, partout sauf le lisere de vide. ⚠ ETAGE ZERO -- premier essai a UN, et tout
	# le cadre devenait un seul massif geant qui avalait tous les specimens.
	for row2: int in range(RIM, tall - RIM):
		for col: int in range(RIM, wide - RIM):
			_put(grid, col, row2, 0)
	for one2: Dictionary in placed:
		_stamp(grid, one2)

	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said: String = ""
		for v: int in line2:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(text) + "\n")
	file.close()
	_audit(text)
	print("guide ecrit : %s (%dx%d), %d massifs poses" % [out, wide, tall, placed.size()])
	quit(0)


func _put(grid: Array[PackedByteArray], x: int, y: int, level: int) -> void:
	if y < 0 or y >= grid.size():
		return
	var line: PackedByteArray = grid[y]
	if x < 0 or x >= line.size():
		return
	line[x] = maxi(int(line[x]), level + 1)
	grid[y] = line


## Pose un massif : sa forme a l'etage 1, ou a l'etage 2 sur un socle d'etage 1.
func _stamp(grid: Array[PackedByteArray], one: Dictionary) -> void:
	var rows: Array = one["rows"] as Array
	var ox: int = int(one["x"])
	var oy: int = int(one["y"])
	var socle: bool = bool(one["socle"])
	var w: int = String(rows[0]).length()
	var h: int = rows.size()
	if socle:
		# ⚠ LE SOCLE DEBORDE DE TROIS AU SUD, PAS DE UN. La falaise du massif pose dessus
		# tombe de trois rangees et doit atterrir sur la SURFACE du socle : une marge de un
		# la ferait retomber sur la falaise du socle, et c'est la tuile composite que le
		# modele existe pour supprimer.
		for y: int in range(-BASE_SIDE, h + BASE_SOUTH):
			for x: int in range(-BASE_SIDE, w + BASE_SIDE):
				_put(grid, ox + x, oy + y, 1)
	var level: int = int(one.get("level", 2 if socle else 1))
	for y2: int in range(h):
		var line: String = String(rows[y2])
		for x2: int in range(line.length()):
			if line.substr(x2, 1) == "#":
				_put(grid, ox + x2, oy + y2, level)


## CE QUE LE GUIDE EXERCE, et ce qui lui manque.
func _audit(world: PackedStringArray) -> void:
	var made: Dictionary = Massifs.of(world)
	var seen: Dictionary = {}
	var groups: Array = made["cells"]
	var covers: Array[bool] = made["covers"]
	for mark: int in range(groups.size()):
		var footprint: Dictionary = _footprint(groups[mark] as Array)
		for cell: Vector2i in footprint.keys():
			var raw: int = 0
			for bit: int in range(8):
				if footprint.has(cell + BlobIndex.OFFSETS[bit]):
					raw |= 1 << bit
			seen[(int(covers[mark]) << 16) | (int(footprint[cell]) << 8)
					| BlobIndex.canonicalize(raw)] = true
	var thin: Array[Vector3i] = Thickness.thin_cells(world)
	print("  %d tuiles exercees ; %d case(s) fine(s)" % [seen.size(), thin.size()])
	var by_band: Dictionary = {}
	for key: int in seen.keys():
		var band: int = (key >> 8) & 0xff
		var flush: bool = (key >> 16) != 0
		var name: String = "%s %s" % [Bands.BAND_NAMES[band], "au ras" if flush else "libre"]
		by_band[name] = int(by_band.get(name, 0)) + 1
	var said2: Array[String] = []
	said2.assign(by_band.keys())
	said2.sort()
	for name2: String in said2:
		print("    %-22s %d" % [name2, int(by_band[name2])])


func _footprint(cells: Array) -> Dictionary:
	var out: Dictionary = {}
	var surface: Dictionary = {}
	for cell: Variant in cells:
		surface[cell as Vector2i] = true
		out[cell as Vector2i] = Bands.SURFACE
	for cell2: Variant in cells:
		var at: Vector2i = cell2 as Vector2i
		if surface.has(at + Vector2i.DOWN):
			continue
		for step: int in range(1, Bands.FALL + 1):
			var below: Vector2i = at + Vector2i(0, step)
			if not out.has(below):
				out[below] = step
	return out
