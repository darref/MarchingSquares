extends SceneTree

## DEUX IMAGES POUR TRANCHER UNE QUESTION QUI NE SE TRANCHE PAS EN DISCUTANT.
##
## 1. `demo_cote.png` -- une cote tracee avec le PINCEMENT : le trait traverse toujours le
##    bord d'une case au meme endroit, et fait ce qu'il veut a l'interieur. Trois amplitudes,
##    de la plus timide a la plus large. La grille n'est posee que sur le tiers gauche : a
##    gauche on voit ou sont les points de passage, a droite on voit ce que ca donne.
##
## 2. `demo_jonction.png` -- deux ilots colles a des hauteurs differentes. Le contour du bas
##    en brun, celui du haut en cyan. La ou les deux bords sont confondus, les deux contours
##    portent la MEME tuile donc le MEME dessin : ils se superposent. La ou le haut tourne
##    vers l'interieur, il quitte le bas exactement au point de passage -- a la frontiere
##    d'une case, la ou les deux sont pinces.
##
## Rien de tout cela ne touche au logiciel : c'est un banc d'essai jetable.

const SS: int = 3                 # sur-echantillonnage
const TILE: int = 48              # pixels par case, en sortie
const INSET: float = 0.34         # ou passe le trait, en fraction de case

const VOID_COLOUR: Color = Color("#1b1d1f")
const LEVEL1: Color = Color("#667347")
const LEVEL2: Color = Color("#8a9a5b")
const GRID: Color = Color(1, 1, 1, 0.16)
const LINE1: Color = Color("#3a2a1c")
const LINE2: Color = Color("#3fd0d8")

const COAST: Array[String] = [
	"~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~1111111111~~~~",
	"~~~~~~1111111111~~~~",
	"~~~1111111111111~~~~",
	"~~~1111111111111~~~~",
	"~~~1111111111111~~~~",
	"~~~11111111111~~~~~~",
	"~~~11111111111~~~~~~",
	"~~~~~~1111111~~~~~~~",
	"~~~~~~1111111~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~",
]

const JOIN: Array[String] = [
	"~~~~~~~~~",
	"~~2221111",
	"~~2221111",
	"~~2221111",
	"~~1111111",
	"~~1111111",
	"~~~~~~~~~",
]


func _initialize() -> void:
	_coast()
	_junction()
	quit()


# --- 1. LA COTE, TROIS AMPLITUDES -------------------------------------------------------

func _coast() -> void:
	# La MEME amplitude dans les deux bandes : la seule difference est le nombre de dessins
	# par tuile. En haut UN seul -- donc toutes les cases d'un meme bord portent exactement le
	# meme trait, et le rythme est periodique PAR CONSTRUCTION. En bas QUATRE, tires par la
	# position : meme pincement, memes points de passage, mais le motif ne se repete plus.
	var bands: Array[int] = [1, 4]
	var w: int = COAST[0].length() * TILE
	var h: int = COAST.size() * TILE * bands.size()
	var sheet: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(VOID_COLOUR)
	for i: int in range(bands.size()):
		var band: Image = _draw(COAST, 1, 0.26, bands[i])
		_grid(band, band.get_width() / 3)
		sheet.blit_rect(band, Rect2i(Vector2i.ZERO, band.get_size()),
				Vector2i(0, i * COAST.size() * TILE))
	sheet.save_png("res://demo_cote.png")
	print("ecrit : demo_cote.png  (%d x %d)  haut = 1 dessin par tuile, bas = 4" % [w, h])


# --- 2. LA JONCTION ---------------------------------------------------------------------

func _junction() -> void:
	var image: Image = _draw(JOIN, 2, 0.30)
	# Les deux contours, en couleurs distinctes, par-dessus le dessin.
	_outline(image, JOIN, 1, LINE1, 3)
	_outline(image, JOIN, 2, LINE2, 1)
	_grid(image, image.get_width())
	image.save_png("res://demo_jonction.png")
	print("ecrit : demo_jonction.png  (%d x %d)" % [image.get_width(), image.get_height()])


# --- LE DESSIN --------------------------------------------------------------------------

## Le relief, dessine etage par etage, du bas vers le haut.
func _draw(cells: Array[String], top: int, amp: float, variants: int = 1) -> Image:
	var cols: int = cells[0].length()
	var rows: int = cells.size()
	var big: Image = Image.create(cols * TILE * SS, rows * TILE * SS, false, Image.FORMAT_RGBA8)
	big.fill(VOID_COLOUR)
	for level: int in range(1, top + 1):
		var tint: Color = LEVEL1 if level == 1 else LEVEL2
		var mask: Array[PackedByteArray] = _mask(cells, level, amp, variants)
		for y: int in range(big.get_height()):
			var row: PackedByteArray = mask[y]
			for x: int in range(big.get_width()):
				if row[x] != 0:
					big.set_pixel(x, y, tint)
	big.resize(cols * TILE, rows * TILE, Image.INTERPOLATE_BILINEAR)
	return big


## Le masque d'un etage, en pixels sur-echantillonnes : 1 = de la terre.
##
## ⚠ C'EST ICI QUE LE PINCEMENT SE JOUE. Le bord d'une case ouverte est pose a INSET, et
## le vagabondage s'y ajoute -- mais il vaut ZERO aux deux extremites de la case. Deux cases
## voisines se rejoignent donc au pixel pres, quelles que soient leurs deux tuiles.
func _mask(cells: Array[String], level: int, amp: float,
		variants: int = 1) -> Array[PackedByteArray]:
	var cols: int = cells[0].length()
	var rows: int = cells.size()
	var span: int = TILE * SS
	var out: Array[PackedByteArray] = []
	for y: int in range(rows * span):
		var row: PackedByteArray = PackedByteArray()
		row.resize(cols * span)
		out.append(row)
	var reach: float = amp * span
	for cy: int in range(rows):
		for cx: int in range(cols):
			if _level_at(cells, cx, cy) < level:
				continue
			# Les cotes ouvertes : nord, est, sud, ouest.
			var open: Array[bool] = [
				_level_at(cells, cx, cy - 1) < level,
				_level_at(cells, cx + 1, cy) < level,
				_level_at(cells, cx, cy + 1) < level,
				_level_at(cells, cx - 1, cy) < level,
			]
			var id: int = 0
			for side: int in range(4):
				if open[side]:
					id |= 1 << side
			var variant: int = 0 if variants <= 1 else (cx * 7 + cy * 13) % variants
			var base: float = INSET * span
			for py: int in range(span):
				var row: PackedByteArray = out[cy * span + py]
				for px: int in range(span):
					var u: float = float(px) / float(span - 1)
					var v: float = float(py) / float(span - 1)
					var keep: bool = true
					if open[0] and float(py) < base + _wander(id, 0, u, reach, variant):
						keep = false
					if open[2] and float(span - 1 - py) < base + _wander(id, 2, u, reach, variant):
						keep = false
					if open[3] and float(px) < base + _wander(id, 3, v, reach, variant):
						keep = false
					if open[1] and float(span - 1 - px) < base + _wander(id, 1, v, reach, variant):
						keep = false
					if keep:
						row[cx * span + px] = 1
				out[cy * span + py] = row
	return out


## LE VAGABONDAGE : nul aux deux bouts, libre au milieu.
##
## ⚠ UN SEUL LOBE PAR CASE, PAS TROIS. Premier essai : deux ou trois oscillations a
## l'interieur d'une case. Le trait ne se lisait pas comme une cote mais comme une SCIE --
## le pincement revient tous les trente pixels, et si le trait bouge plus vite que ca, l'oeil
## ne voit plus que des dents. Une case porte donc une bosse, et une seule.
##
## ⚠ ET LA VARIANTE SE CHOISIT PAR LA POSITION, JAMAIS PAR L'ETAGE. Sinon deux etages dont
## les bords sont confondus tireraient deux dessins differents et le trait se dedoublerait.
func _wander(id: int, side: int, t: float, reach: float, variant: int) -> float:
	# ⚠ LA FORME D'UN BORD NE DEPEND QUE DE CE BORD-LA. Premier essai : elle dependait de
	# TOUTE l'identite de la tuile. Consequence vue a l'image : sur une portion ou deux etages
	# ont exactement le meme bord, la case du COIN a un voisin different selon l'etage -- donc
	# une autre identite, donc un autre bord NORD, alors que le nord, lui, n'a pas bouge. Les
	# deux contours se dedoublaient sur toute la portion commune.
	#
	# C'est une LOI DE DESSIN, de la meme famille que celles deja au dossier : ce qui depend
	# d'un cote se tient sur ce cote. Deux tuiles differentes partagent alors le meme profil
	# partout ou leur situation est la meme, et les etages se superposent au pixel pres.
	var seed: int = absi(((side + 1) * 19349663) ^ ((variant + 1) * 83492791))
	var skew: float = 0.75 + 0.55 * float(seed % 101) / 100.0
	var height: float = 0.45 + 0.55 * float((seed / 101) % 97) / 96.0
	if (seed / 9973) % 2 == 0:
		height = -height
	return reach * height * sin(PI * pow(t, skew))


## Le contour d'un etage, pose par-dessus.
func _outline(image: Image, cells: Array[String], level: int, tint: Color, extra: int) -> void:
	var mask: Array[PackedByteArray] = _mask(cells, level, 0.26)
	var w: int = image.get_width()
	var h: int = image.get_height()
	var big_w: int = cells[0].length() * TILE * SS
	var big_h: int = cells.size() * TILE * SS
	for y: int in range(h):
		for x: int in range(w):
			var bx: int = int(float(x) * big_w / w)
			var by: int = int(float(y) * big_h / h)
			if bx <= 0 or by <= 0 or bx >= big_w - 1 or by >= big_h - 1:
				continue
			if mask[by][bx] == 0:
				continue
			var border: bool = (mask[by - 1][bx] == 0 or mask[by + 1][bx] == 0
					or mask[by][bx - 1] == 0 or mask[by][bx + 1] == 0)
			if not border:
				continue
			for dy: int in range(-extra, extra + 1):
				for dx: int in range(-extra, extra + 1):
					var qx: int = x + dx
					var qy: int = y + dy
					if qx >= 0 and qy >= 0 and qx < w and qy < h:
						image.set_pixel(qx, qy, tint)


func _grid(image: Image, until_x: int) -> void:
	for y: int in range(image.get_height()):
		for x: int in range(mini(until_x, image.get_width())):
			if x % TILE == 0 or y % TILE == 0:
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(Color.WHITE, GRID.a))


func _level_at(cells: Array[String], x: int, y: int) -> int:
	if y < 0 or y >= cells.size():
		return 0
	if x < 0 or x >= cells[y].length():
		return 0
	var glyph: String = cells[y].substr(x, 1)
	return 0 if glyph == "~" else int(glyph)
