# LA CARTE NUMEROTEE : chaque massif porte son numero et son repere.
#
# ⚠ ELLE EXISTE POUR QU'UN DEFAUT SE DESIGNE EN DEUX NOMBRES. Relever un defaut a l'oeil sur un
# guide de 303 x 175 demandait jusqu'ici de decrire un endroit -- « le massif en haut a gauche,
# celui qui a une encoche » -- et de compter les cases une par une. Ici chaque groupe porte un
# NUMERO, et un repere local court le long de ses deux bords : le defaut se dit « massif 12,
# case 3,2 », et se retrouve sans chercher.
#
# ⚠ ET LE REPERE EST LOCAL, PAS GLOBAL. Une coordonnee globale sur un guide de cette taille se
# recompte a chaque fois qu'on la relit ; une coordonnee locale se lit sur les deux graduations
# qui encadrent le massif, sans quitter des yeux ce qu'on regarde. La table imprimee donne
# l'origine globale de chaque massif, pour la conversion.
#
# ⚠ ET LES GROUPES SE FORMENT PAR PROXIMITE, PAS PAR COMPOSANTE CONNEXE. Un temoin soude peut
# etre fait de deux blobs qui ne se touchent pas -- un plateau et son massif porte, separes par
# une rangee de plaine. Les compter separement donnerait deux numeros pour ce que l'oeil voit
# comme une seule chose. On dilate donc de `REACH` cases avant de grouper.
#
#     godot --headless --path . --script res://tools/numbered_map.gd -- <sortie.png> [guide] [F]
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Scene := preload("res://render/massif_scene.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")

const RES: int = MassifTiles.RES
## La distance a laquelle deux blobs comptent pour un seul massif, en cases.
const REACH: int = 2

const BOX: Color = Color(1.0, 0.85, 0.2)
const TICK: Color = Color(1.0, 1.0, 1.0)
const TICK_ALT: Color = Color(0.55, 0.85, 1.0)
const BADGE: Color = Color(0.05, 0.05, 0.08)
const NUMBER: Color = Color(1.0, 0.85, 0.2)

## Un chiffre en 3 x 5. ⚠ DESSINE ICI, PAS PRIS A UNE POLICE : `draw_string` demande un
## CanvasItem, donc une scene, donc un viewport -- pour dix glyphes qu'on sait ecrire.
const DIGITS: Array[String] = [
	"111101101101111", "010110010010111", "111001111100111", "111001111001111",
	"101101111001001", "111100111001111", "111100111101111", "111001001001001",
	"111101111101111", "111101111001111",
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var target: String = args[0] if args.size() > 0 else "carte.png"
	var path: String = args[1] if args.size() > 1 else "res://guides/terrain.txt"
	var freedom: int = args[2].to_int() if args.size() > 2 else 1
	var world: PackedStringArray = HeightMask.read(path)
	if world.is_empty():
		printerr("carte : '%s' ne se lit pas." % path)
		quit(1)
		return
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)

	var boxes: Array[Rect2i] = _groups(world)
	print("%s : %dx%d cases, %d massif(s)" % [path, wide, tall, boxes.size()])

	var image: Image = Scene.compose(world, freedom)
	print("")
	print("  no   origine globale   taille")
	for at: int in range(boxes.size()):
		var box: Rect2i = boxes[at]
		print("  %-4d %4d,%-4d        %d x %d" % [at + 1, box.position.x, box.position.y,
				box.size.x, box.size.y])
		_frame(image, box)
		_ruler(image, box)
		_badge(image, box, at + 1)
	if image.save_png(target) != OK:
		printerr("carte : impossible d'ecrire %s" % target)
		quit(1)
		return
	print("")
	print("carte ecrite : %s (%dx%d)" % [target, image.get_width(), image.get_height()])
	quit(0)


## LES GROUPES, PAR PROXIMITE, en ordre de lecture.
func _groups(world: PackedStringArray) -> Array[Rect2i]:
	# ⚠ ON GROUPE SUR CE QUI SE PEINT, PAS SUR LES CASES HAUTES. Une falaise pend SOUS la
	# surface qui la porte : bornee aux cases d'etage >= 1, la boite coupait chaque massif au
	# ras de son herbe, et une case de ROCHE n'avait alors aucune coordonnee locale -- or c'est
	# exactement la ou les defauts se voient. `paintable` rend les poses d'etage >= 1, jupe
	# comprise, et c'est aussi ce que le crayon accepte : la boite couvre donc exactement ce
	# qu'on peut peindre, ni plus ni moins.
	var solid: Dictionary = {}
	for cell0: Vector2i in Massifs.paintable(world).keys():
		solid[cell0] = true
	# La dilatation : une case compte si de la matiere est a `REACH` ou moins.
	var near: Dictionary = {}
	for cell: Vector2i in solid.keys():
		for dy: int in range(-REACH, REACH + 1):
			for dx: int in range(-REACH, REACH + 1):
				near[cell + Vector2i(dx, dy)] = true
	var seen: Dictionary = {}
	var boxes: Array[Rect2i] = []
	for cell1: Vector2i in near.keys():
		if seen.has(cell1):
			continue
		var queue: Array[Vector2i] = [cell1]
		seen[cell1] = true
		var box: Rect2i = Rect2i()
		var carries: bool = false
		while not queue.is_empty():
			var here: Vector2i = queue.pop_back()
			if solid.has(here):
				box = Rect2i(here, Vector2i.ONE) if not carries \
						else box.merge(Rect2i(here, Vector2i.ONE))
				carries = true
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = here + step
				if seen.has(next) or not near.has(next):
					continue
				seen[next] = true
				queue.append(next)
		if carries:
			boxes.append(box)
	# ⚠ EN RANGEES, PAS EN Y STRICT. Deux massifs cote a cote ne commencent presque jamais a la
	# meme rangee ; trier sur `y` seul les entrelacerait, et le numero sauterait d'un bout a
	# l'autre de l'ecran a chaque increment.
	boxes.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
		var band_a: int = a.position.y / 20
		var band_b: int = b.position.y / 20
		if band_a != band_b:
			return band_a < band_b
		return a.position.x < b.position.x)
	return boxes


## LE CADRE, une case plus large que le massif : il ne mange pas ce qu'on regarde.
func _frame(image: Image, box: Rect2i) -> void:
	var left: int = (box.position.x - 1) * RES
	var top: int = (box.position.y - 1) * RES
	var right: int = (box.end.x + 1) * RES - 1
	var bottom: int = (box.end.y + 1) * RES - 1
	for x: int in range(left, right + 1):
		_dot(image, x, top, BOX)
		_dot(image, x, bottom, BOX)
	for y: int in range(top, bottom + 1):
		_dot(image, left, y, BOX)
		_dot(image, right, y, BOX)


## LES DEUX GRADUATIONS : les colonnes le long du bord haut, les rangees le long du bord gauche.
## ⚠ ELLES SE POSENT DANS LA MARGE DU CADRE, jamais sur la matiere : un chiffre pose sur le
## dessin cacherait exactement ce qu'on cherche a juger. Et une graduation sur cinq est blanche,
## les autres bleues -- compter dix chiffres identiques a la file est ce qu'on cherche a eviter.
func _ruler(image: Image, box: Rect2i) -> void:
	# ⚠ ET LES GRADUATIONS S'ALTERNENT SUR DEUX LIGNES. A deux chiffres, une etiquette fait
	# quatorze pixels dans une case qui en fait seize : ecrites a la file, « 10 11 12 13 » se
	# lisait « 10111213 ». Une case sur deux descend d'une demi-hauteur, et chacune a donc deux
	# fois la place. Une graduation sur cinq est blanche, les autres bleues : compter dix
	# chiffres identiques a la file est precisement ce qu'on cherche a eviter.
	for column: int in range(box.size.x):
		_number(image, (box.position.x + column) * RES + 2,
				(box.position.y - 1) * RES + (2 if column % 2 == 0 else 8),
				column, 2, TICK if column % 5 == 0 else TICK_ALT)
	for row: int in range(box.size.y):
		_number(image, (box.position.x - 1) * RES + (2 if row % 2 == 0 else 9),
				(box.position.y + row) * RES + 3,
				row, 2, TICK if row % 5 == 0 else TICK_ALT)


## LE NUMERO DU MASSIF, en grand, sur une pastille sombre au-dessus du cadre.
func _badge(image: Image, box: Rect2i, mark: int) -> void:
	var scale: int = 4
	var wide: int = str(mark).length() * 4 * scale + scale
	var tall: int = 7 * scale
	var left: int = (box.position.x - 1) * RES
	var top: int = (box.position.y - 1) * RES - tall - 2
	if top < 0:
		top = (box.end.y + 1) * RES + 2
	for y: int in range(top, top + tall):
		for x: int in range(left, left + wide):
			_dot(image, x, y, BADGE)
	_number(image, left + scale, top + scale, mark, scale, NUMBER)


func _number(image: Image, x: int, y: int, value: int, scale: int, tint: Color) -> void:
	var text: String = str(value)
	var cursor: int = x
	for at: int in range(text.length()):
		var glyph: String = DIGITS[text.unicode_at(at) - 48]
		for row: int in range(5):
			for column: int in range(3):
				if glyph[row * 3 + column] != "1":
					continue
				for sy: int in range(scale):
					for sx: int in range(scale):
						_dot(image, cursor + column * scale + sx, y + row * scale + sy, tint)
		cursor += 4 * scale


func _dot(image: Image, x: int, y: int, tint: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, tint)
