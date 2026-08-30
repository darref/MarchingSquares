# LE GUIDE DES TEMOINS — les dessins que le paysage ne produit jamais de lui-meme.
#
# ⚠ ET C'EST UN GUIDE A PART, PAS UNE RESERVE DE PLUS AU SUD D'`epais.txt`. Decision prise
# avec la mesure sous les yeux : les dix temoins allongent le guide de moitie -- 141 a 215
# rangees -- donc la case passe de vingt-six a dix-sept pixels d'ecran, pour un vocabulaire
# que le produit N'EXPORTE PAS ENCORE. Or « ce qui compte n'est pas le nombre de cases, c'est
# la taille de la case a l'ecran » est deja au dossier, mesure. On paiera cet ecran le jour de
# la bascule, quand ces tuiles deviendront peignables ; d'ici la, elles se prouvent ici.
#
# ⚠ ET IL N'EST PAS UN PAYSAGE, IL NE PRETEND PAS L'ETRE -- meme statut que la reserve
# d'`epais.txt`. Il ne s'affiche nulle part : il sert a ce qu'aucun dessin de la forme fermee
# ne soit sans monde qui le porte.
#
# IL SE VERIFIE EN S'ECRIVANT : epaisseur partout, et CHAQUE cle declaree posee a l'endroit
# ou son bloc a ete stampe. Un temoin est juste dans SON contexte ; ce guide en est un autre.
#
#     godot --headless --path . --script res://tools/build_temoins.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Brink := preload("res://core/brink.gd")
const Walls := preload("res://core/walls.gd")
const BrinkWitnesses := preload("res://core/brink_witnesses.gd")

const WIDTH: int = 104
## L3 : le monde complet -- etages empiles, falaises, poses arriere.
const LEVEL: int = 3
## La plaine entre deux temoins, et autour de la planche.
const GAP: int = 4
## ⚠ ET LE VIDE AUTOUR, PARCE QUE CHAQUE RELIEF DOIT DECLARER SON BORD. Sans lui la plaine
## court jusqu'au cadre de l'image et son propre contour s'y trouve COUPE : deux extremites,
## aux deux coins du bas, qui n'accusent que le cadre. La marge vaut une chute entiere -- la
## plaine tombe de trois rangees dans le vide -- plus de quoi respirer.
const MARGIN: int = 4
const OUT_PATH: String = "res://guides/temoins.txt"

var _levels: Array = []
## Chaque temoin pose : la case, et la cle qu'elle doit porter.
var _brinks: Array[Array] = []


func _initialize() -> void:
	var blocks: Array = BrinkWitnesses.BLOCKS
	if blocks.is_empty():
		printerr("aucun temoin : lancer d'abord tools/brink_witnesses.gd")
		quit(1)
		return
	var height: int = _place(blocks)
	var heights: PackedStringArray = _mask(height)
	var failures: int = 0

	# 1. L'epaisseur, partout, tous etages -- comme pour le guide livre.
	var thin: Array[Vector3i] = Thickness.thin_cells(heights)
	if not thin.is_empty():
		failures += 1
		print("FIN : %d case(s) fine(s), par exemple %s" % [thin.size(), str(thin.slice(0, 6))])

	# 2. ⚠ CHAQUE CLE, LA OU ELLE EST POSEE. Le temoin a ete verifie au milieu d'un champ de
	# plaine ; ici il a des voisins a quatre cases. La decoupe ment -- on reverifie.
	var made: Dictionary = Brink.keys(heights, LEVEL)
	var lost: Array[String] = []
	for entry: Array in _brinks:
		var at: Vector2i = entry[0]
		var wanted: int = int(entry[1])
		var got: bool = false
		for storey: Dictionary in (made["storeys"] as Array[Dictionary]):
			if storey.has(at) and int(storey[at]) == wanted:
				got = true
		if not got:
			lost.append("%d en %d,%d" % [wanted, at.x, at.y])
	if not lost.is_empty():
		failures += 1
		print("CLES PERDUES (%d) : %s" % [lost.size(), ", ".join(lost)])

	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	for line: String in heights:
		file.store_line(line)
	file.close()
	print("guide des temoins ecrit : %s (%dx%d), %d bloc(s), %d cle(s) tenue(s)"
			% [OUT_PATH, WIDTH + 2 * MARGIN, heights.size(), blocks.size(), _brinks.size()])
	print("BATISSEUR DES TEMOINS : %d probleme(s)." % failures)
	quit(0 if failures == 0 else 1)


## LES BLOCS RANGES EN LIGNES, avec de la plaine entre eux et autour.
##
## ⚠ ET LA PLAINE ENTRE DEUX BLOCS EST UNE MARGE, PAS UNE DECORATION : un temoin verifie au
## milieu d'un champ de plaine doit retrouver de la plaine, sinon son voisin lui change son
## voisinage et sa cle avec.
func _place(blocks: Array) -> int:
	var rows: int = 0
	var wx: int = GAP
	var band: int = GAP
	var tall: int = 0
	for at: int in range(blocks.size()):
		var lines: PackedStringArray = PackedStringArray()
		for line: Variant in (blocks[at] as Array):
			lines.append(String(line))
		var wide: int = lines[0].length()
		if wx + wide > WIDTH - GAP:
			wx = GAP
			band += tall + GAP
			tall = 0
		_stamp(wx, band, lines)
		for spot: Variant in (BrinkWitnesses.CARRIES[at] as Array):
			var where: Vector3i = spot as Vector3i
			# ⚠ ET LA MARGE DE VIDE DECALE TOUT : la cle est relue dans le masque final.
			_brinks.append([Vector2i(MARGIN + wx + where.x, MARGIN + band + where.y),
					where.z])
		wx += wide + GAP
		tall = maxi(tall, lines.size())
		rows = maxi(rows, band + lines.size())
	return rows + GAP


func _stamp(x0: int, y0: int, lines: PackedStringArray) -> void:
	for y: int in range(lines.size()):
		var line: String = lines[y]
		for x: int in range(line.length()):
			_put(x0 + x, y0 + y, -1 if line[x] == "~" else int(line[x]))


## ⚠ PAS `_set` : `Object._set(StringName, Variant)` existe deja, et redefinir sa
## signature est une erreur d'analyse -- le script ne charge plus du tout.
func _put(x: int, y: int, level: int) -> void:
	while _levels.size() <= y:
		var line: Array = []
		for column: int in range(WIDTH):
			line.append(0)
		_levels.append(line)
	if x >= 0 and x < WIDTH:
		(_levels[y] as Array)[x] = level


## L'interieur de plaine, borde de vide sur ses quatre cotes -- et plus bas, pour que la
## falaise du bord du monde ait ou tomber.
func _mask(height: int) -> PackedStringArray:
	var empty: String = ""
	for x: int in range(WIDTH + 2 * MARGIN):
		empty += "~"
	var side: String = ""
	for x2: int in range(MARGIN):
		side += "~"
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(MARGIN):
		out.append(empty)
	for y2: int in range(height):
		var line: String = ""
		for x3: int in range(WIDTH):
			var level: int = 0
			if y2 < _levels.size():
				level = (_levels[y2] as Array)[x3] as int
			line += "~" if level < 0 else str(level)
		out.append(side + line + side)
	for y3: int in range(MARGIN + Walls.STOREY_TILES):
		out.append(empty)
	return out
