# L'ILLUSTRATION DU GUIDE — deux axes, quatre fonds, une seule géométrie.
#
# ENCRE — de quoi la tuile est faite.
#   PAINTED   : des aplats, comme un tileset peint.
#   WIREFRAME : des traits, comme un tileset au fil de fer. Sans aplat, donc sans lumiere,
#               donc les symetries y sont licites (cf. core/symmetry.gd).
#
# USAGE — a quoi le fond sert.
#   USABLE         : rien qui paraisse irreel, rien qu'on regarde. Le dessin seul, tel que
#                    le tileset le montrera assemble -- c'est le fond sur lequel on peint.
#   REPRESENTATIVE : le meme dessin, mais APPUYE. Trait plus gras sur les cotes ouverts,
#                    marque franche aux coins rentrants, code de rangee bien lisible : on
#                    voit d'un coup ce qu'on attend de la tuile en cours.
#
# ⚠ AUCUNE DISCONTINUITE. Chaque trait est tire A L'INTERIEUR de sa propre tuile, si bien
# qu'a un coin rentrant -- trois cases pleines autour d'un vide -- il manque un carre de la
# largeur du trait, que ni l'une ni l'autre des deux voisines ne couvre. Ce carre tombe chez
# la TROISIEME, celle dont les deux cardinaux sont pleins et la diagonale vide -- et elle le
# SAIT, ce bit-la etant justement celui que la canonicalisation conserve. C'est donc elle qui
# ferme le coude, et le trait devient continu de bout en bout.
#
# ⚠ EN REVANCHE ON N'ARRONDIT PAS LA TERRE A CET ENDROIT. Les deux voisines tracent leur
# cote droit jusqu'au coin et ne peuvent pas savoir qu'il faudrait la courber : une case dont
# le sud est ouvert porte le meme index que son voisin du sud-ouest soit plein ou vide.
# Courber la, ce serait poser un arc que personne ne rejoint. Seuls les coins SORTANTS
# s'arrondissent : la, aucune voisine ne dessine quoi que ce soit.
#
# ⚠ ON DESSINE ETAGE PAR ETAGE, DU BAS VERS LE HAUT. Chaque couche recouvre la precedente.
#
# ⚠ AUCUNE DEPENDANCE A UN NOEUD. Image et Color sont des ressources : ce fichier tourne en
# headless, et l'interface n'a qu'a en faire une ImageTexture.
extends RefCounted

enum Ink {
	PAINTED,    ## Des aplats.
	WIREFRAME,  ## Des traits.
}

enum Purpose {
	## Des formes volontairement APPUYEES, pour qu'on sache tout de suite ce qu'on attend
	## de la tuile qu'on peint : trait plus gras sur les cotes ouverts, marque franche aux
	## coins rentrants, code de rangee bien lisible.
	REPRESENTATIVE,
	## Rien qui paraisse irreel, rien qu'on regarde : le dessin seul, tel que le tileset
	## le montrera une fois assemble. Aucune marque, aucune exageration.
	USABLE,
	## Le guide assemble avec un VRAI tileset, celui de Satyron, lu depuis son projet.
	## ⚠ L'encre n'a plus de sens ici : ce ne sont ni nos aplats ni nos traits, ce sont les
	## tuiles de quelqu'un d'autre. C'est un banc d'essai, pas un fond de travail.
	EXAMPLE,
}

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")

## Cote d'une case, en pixels.
const TILE: int = 24

## On dessine chaque tuile trois fois plus grand puis on la reduit : c'est ce qui donne des
## bords lisses.
const SUPERSAMPLE: int = 3

## Rayon des coins sortants, en fraction de case.
const OUTER_ROUND: float = 0.34

## Largeur de la levre eclairee, en fraction de case.
const LIP: float = 0.11

## Epaisseur du trait, en fraction de case.
const STROKE: float = 0.055

## ⚠ LE LITTORAL EST PLUS APPUYE QUE LES COURBES DE NIVEAU. Un dessin ou tous les traits
## pesent pareil se lit comme un plan de cuisine ; en allegeant a mesure qu'on monte, l'oeil
## trouve tout de suite le bord de la terre et lit les etages comme un relief.
const LEVEL_WEIGHTS: Array[float] = [1.0, 1.35, 1.0, 0.78]

# ⚠ LA PLAINE EST PLUS SOMBRE ET PLUS FROIDE QUE TOUT LE RESTE, et les falaises plus
# chaudes que les herbes : sans cet ecart, trois verts voisins donnent une purée.
const PLAIN_COLOR: Color = Color(0.243, 0.282, 0.224)
const LEVEL_COLORS: Array[Color] = [
	Color(0.243, 0.282, 0.224),
	Color(0.400, 0.451, 0.278),
	Color(0.525, 0.569, 0.376),
	Color(0.663, 0.694, 0.510),
]
const STONE_CROWN: Color = Color(0.576, 0.510, 0.420)
# ⚠ LES DEUX RANGEES DE CORPS ONT LA MEME TEINTE. Les avoir distinguees par la couleur
# rayait la falaise de bandes horizontales a chaque changement de rangee. Ce qui doit
# differer, c'est la TEXTURE -- d'ou un decalage de striure, invisible en bande, suffisant
# pour que l'oeil ne lise pas la repetition.
const STONE_BODY: Color = Color(0.478, 0.416, 0.337)
const STONE_FOOT: Color = Color(0.318, 0.278, 0.220)
const GROUND_SHADOW: Color = Color(0.086, 0.098, 0.086, 0.38)
const CONTACT_SHADOW: Color = Color(0.086, 0.098, 0.086, 0.30)

# ⚠ TOUT L'ECART DU FIL DE FER TIENT DANS UNE BANDE ETROITE. Les etages doivent se
# distinguer, mais aucun ne doit peser assez pour qu'on juge mal la couleur qu'on pose.
const WIRE_PLAIN: Color = Color(0.145, 0.153, 0.169)
const WIRE_LEVELS: Array[Color] = [
	Color(0.145, 0.153, 0.169),
	Color(0.204, 0.216, 0.235),
	Color(0.243, 0.255, 0.278),
	Color(0.282, 0.294, 0.318),
]
const WIRE_WALL: Color = Color(0.176, 0.180, 0.204)
const WIRE_EDGE: Color = Color(0.588, 0.627, 0.678)
const WIRE_LIP: Color = Color(0.870, 0.898, 0.933)
const WIRE_FACE: Color = Color(0.400, 0.427, 0.470)

## La couleur des MARQUES de travail. Volontairement autre chose que le trait du dessin :
## une marque ne doit jamais pouvoir passer pour une cote.
const MARK_WIRE: Color = Color(0.882, 0.702, 0.376)
const MARK_PAINT: Color = Color(0.965, 0.902, 0.729)


## ⚠ CE CHEMIN DESSINE TOUT D'UN COUP, et cela prend de deux a cinq secondes. Il sert aux
## tests et a l'ecriture sur disque, ou personne ne regarde l'ecran. L'interface passe par
## guide_render_job.gd, qui fait le meme travail par etapes.
static func render(heights: PackedStringArray, tile_size: int = TILE,
		ink: Ink = Ink.PAINTED, purpose: Purpose = Purpose.REPRESENTATIVE) -> Image:
	var job: RefCounted = load("res://render/guide_render_job.gd").new(heights, tile_size, ink, purpose)
	while not job.step(1 << 40):
		pass
	return job.image()


## La couleur hors de tout relief.
static func plain_color(ink: Ink) -> Color:
	return WIRE_PLAIN if ink == Ink.WIREFRAME else PLAIN_COLOR


static func stamp(image: Image, tile: Image, x: int, y: int, tile_size: int) -> void:
	if x < 0 or y < 0 or x * tile_size >= image.get_width() or y * tile_size >= image.get_height():
		return
	image.blend_rect(tile, Rect2i(0, 0, tile_size, tile_size), Vector2i(x * tile_size, y * tile_size))


# --- Fabrication des tuiles ------------------------------------------------

static func _blank(side: int, tint: Color) -> PackedByteArray:
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(side * side * 4)
	for i: int in range(side * side):
		# ⚠ LE DEHORS PORTE LA COULEUR DE LA TUILE, EN TRANSPARENT. A la reduction, les
		# pixels de bord se melangent a leurs voisins : un dehors noir cernerait chaque
		# tuile d'un liseré sombre.
		buffer[i * 4] = int(tint.r * 255.0)
		buffer[i * 4 + 1] = int(tint.g * 255.0)
		buffer[i * 4 + 2] = int(tint.b * 255.0)
		buffer[i * 4 + 3] = 0
	return buffer


## ⚠ ON ARRONDIT, ON NE TRONQUE PAS. Tronquer decale chaque canal d un demi-pas vers le
## sombre : invisible sur une couleur, mais la teinte rendue n est alors plus exactement
## celle qu on a demandee, et un test qui compare les deux echoue pour une raison qui n a
## rien a voir avec le dessin.
static func _put(buffer: PackedByteArray, side: int, x: int, y: int, color: Color) -> void:
	var offset: int = (y * side + x) * 4
	buffer[offset] = roundi(clampf(color.r, 0.0, 1.0) * 255.0)
	buffer[offset + 1] = roundi(clampf(color.g, 0.0, 1.0) * 255.0)
	buffer[offset + 2] = roundi(clampf(color.b, 0.0, 1.0) * 255.0)
	buffer[offset + 3] = roundi(clampf(color.a, 0.0, 1.0) * 255.0)


static func _finish(buffer: PackedByteArray, side: int, tile_size: int) -> Image:
	var image: Image = Image.create_from_data(side, side, false, Image.FORMAT_RGBA8, buffer)
	image.resize(tile_size, tile_size, Image.INTERPOLATE_BILINEAR)
	return image


static func make_top(index: int, level: int, tile_size: int, ink: Ink, purpose: Purpose) -> Image:
	var side: int = tile_size * SUPERSAMPLE
	var wire: bool = ink == Ink.WIREFRAME
	var base: Color = WIRE_LEVELS[mini(level, WIRE_LEVELS.size() - 1)] if wire \
			else LEVEL_COLORS[mini(level, LEVEL_COLORS.size() - 1)]
	var buffer: PackedByteArray = _blank(side, base)
	var outer: float = OUTER_ROUND * float(side)
	var lip: float = LIP * float(side) * (1.7 if purpose == Purpose.REPRESENTATIVE else 1.0)
	var weight: float = LEVEL_WEIGHTS[mini(level, LEVEL_WEIGHTS.size() - 1)]
	var stroke: float = STROKE * float(side) * weight \
			* (1.9 if purpose == Purpose.REPRESENTATIVE else 1.0)
	var north: bool = (index & BlobIndex.N) != 0
	var east: bool = (index & BlobIndex.E) != 0
	var south: bool = (index & BlobIndex.S) != 0
	var west: bool = (index & BlobIndex.W) != 0
	var last: float = float(side - 1)
	var mark: Color = MARK_WIRE if wire else MARK_PAINT
	for y: int in range(side):
		for x: int in range(side):
			var px: float = float(x)
			var py: float = float(y)
			if _carved(px, py, last, outer, north, east, south, west):
				continue
			var color: Color = base
			if wire:
				var on_line: bool = _on_edge(px, py, last, outer, stroke, north, east, south, west)
				# Le coude d'un coin rentrant : c'est ce qui rend le trait continu.
				if not on_line:
					on_line = _on_inner_elbow(px, py, last, stroke, index, north, east, south, west)
				if on_line:
					color = WIRE_EDGE
					if not north and py < stroke * 2.0:
						color = WIRE_LIP
					elif not south and py > last - stroke * 2.0:
						color = WIRE_FACE
			else:
				var shade: float = _rim_shade(px, py, last, outer, lip, index,
						north, east, south, west)
				if shade > 0.0:
					color = base.lightened(0.34 * shade)
				elif shade < 0.0:
					color = base.darkened(0.30 * -shade)
			if purpose == Purpose.REPRESENTATIVE and _on_inner_tick(px, py, last, stroke, index,
					north, east, south, west):
				color = mark
			_put(buffer, side, x, y, color)
	return _finish(buffer, side, tile_size)


## LA LEVRE PEINTE — l'ombre et la lumiere le long du contour, arrondis compris.
##
## ⚠ ELLE SUIT LE CONTOUR, PAS LES QUATRE COTES. Peindre quatre bandes droites laissait
## la levre s'arreter net avant chaque coin arrondi, et manquer entierement les coins
## rentrants -- le meme trou que le trait avait au fil de fer, en plus sournois parce
## qu'une bande claire qui s'interrompt se lit comme un defaut de peinture.
##
## Rend un nombre entre -1 et 1 : positif du cote eclaire (nord-ouest), negatif du cote
## qui recule, nul au coeur de la tuile. Le fondu evite la bande franche.
static func _rim_shade(px: float, py: float, last: float, outer: float, lip: float,
		index: int, north: bool, east: bool, south: bool, west: bool) -> float:
	var nearest: float = lip
	var tone: float = 0.0
	# Les cotes ouverts.
	var sides: Array = [
		[not north, py, 1.0],
		[not west, px, 0.62],
		[not south, last - py, -0.86],
		[not east, last - px, -0.56],
	]
	for side: Array in sides:
		if not bool(side[0]):
			continue
		var distance: float = float(side[1])
		if distance < nearest:
			nearest = distance
			tone = float(side[2])
	# Les coins sortants : la levre epouse l'arc.
	var corners: Array = [
		[not north and not east, last, 0.0, 0.22],
		[not south and not east, last, last, -0.71],
		[not south and not west, 0.0, last, -0.12],
		[not north and not west, 0.0, 0.0, 0.81],
	]
	for corner: Array in corners:
		if not bool(corner[0]):
			continue
		var cx: float = float(corner[1])
		var cy: float = float(corner[2])
		var centre_x: float = cx + (outer if cx == 0.0 else -outer)
		var centre_y: float = cy + (outer if cy == 0.0 else -outer)
		var outward_x: bool = (px < centre_x) if cx == 0.0 else (px > centre_x)
		var outward_y: bool = (py < centre_y) if cy == 0.0 else (py > centre_y)
		if not outward_x or not outward_y:
			continue
		var ox: float = px - centre_x
		var oy: float = py - centre_y
		var along: float = outer - sqrt(ox * ox + oy * oy)
		if along < nearest:
			nearest = along
			tone = float(corner[3])
	# ⚠ ET LES COINS RENTRANTS. Le vide y touche la case par un point : sans ce carre, la
	# levre des deux voisines s'arrete de part et d'autre et laisse un manque a l'angle.
	var notches: Array = [
		[north and east, (index & BlobIndex.NE) != 0, last, 0.0, 0.22],
		[south and east, (index & BlobIndex.SE) != 0, last, last, -0.71],
		[south and west, (index & BlobIndex.SW) != 0, 0.0, last, -0.12],
		[north and west, (index & BlobIndex.NW) != 0, 0.0, 0.0, 0.81],
	]
	for notch: Array in notches:
		if not bool(notch[0]) or bool(notch[1]):
			continue
		var reach: float = maxf(absf(px - float(notch[2])), absf(py - float(notch[3])))
		if reach < nearest:
			nearest = reach
			tone = float(notch[4])
	if nearest >= lip:
		return 0.0
	return tone * smoothstep(0.0, 1.0, 1.0 - nearest / lip)


## Vrai si le pixel est hors de la matiere. ⚠ SEULS LES COINS SORTANTS SONT ARRONDIS --
## voir l'avertissement en tete de fichier.
static func _carved(px: float, py: float, last: float, outer: float,
		north: bool, east: bool, south: bool, west: bool) -> bool:
	for corner: Array in _corners(last, north, east, south, west):
		if bool(corner[0]) or bool(corner[1]):
			continue
		if _in_outer_corner(px, py, float(corner[2]), float(corner[3]), outer, 0.0):
			return true
	return false


## Le trait du dessin : les cotes ouverts, et les arcs des coins sortants. Rien d'autre.
static func _on_edge(px: float, py: float, last: float, outer: float, stroke: float,
		north: bool, east: bool, south: bool, west: bool) -> bool:
	if not north and py < stroke:
		return true
	if not south and py > last - stroke:
		return true
	if not west and px < stroke:
		return true
	if not east and px > last - stroke:
		return true
	for corner: Array in _corners(last, north, east, south, west):
		if bool(corner[0]) or bool(corner[1]):
			continue
		if _in_outer_corner(px, py, float(corner[2]), float(corner[3]), outer, stroke):
			return true
	return false


## Le pixel est-il au-dela de l'arc d'un coin sortant (marge nulle), ou SUR cet arc (marge
## non nulle) ?
static func _in_outer_corner(px: float, py: float, cx: float, cy: float,
		outer: float, band: float) -> bool:
	var centre_x: float = cx + (outer if cx == 0.0 else -outer)
	var centre_y: float = cy + (outer if cy == 0.0 else -outer)
	var outward_x: bool = (px < centre_x) if cx == 0.0 else (px > centre_x)
	var outward_y: bool = (py < centre_y) if cy == 0.0 else (py > centre_y)
	if not outward_x or not outward_y:
		return false
	var ox: float = px - centre_x
	var oy: float = py - centre_y
	var distance: float = sqrt(ox * ox + oy * oy)
	if band <= 0.0:
		return distance > outer
	return absf(distance - outer) < band


## LE COUDE D'UN COIN RENTRANT — le petit carre qui ferme la jonction.
##
## ⚠ SANS LUI, LE TRAIT EST TROUE. Chaque cote ouvert est tire a l'interieur de sa propre
## tuile ; au coin, les deux traits voisins se croisent sans se rejoindre et laissent un
## carre vide de la largeur du trait. Ce carre tombe ici, chez la case dont les deux
## cardinaux sont pleins et la diagonale vide -- la seule qui sache que le vide touche son
## angle, et le seul bit de coin que la canonicalisation conserve.
static func _on_inner_elbow(px: float, py: float, last: float, stroke: float, index: int,
		north: bool, east: bool, south: bool, west: bool) -> bool:
	var diagonals: Array = [
		[north and east, (index & BlobIndex.NE) != 0, last, 0.0],
		[south and east, (index & BlobIndex.SE) != 0, last, last],
		[south and west, (index & BlobIndex.SW) != 0, 0.0, last],
		[north and west, (index & BlobIndex.NW) != 0, 0.0, 0.0],
	]
	for corner: Array in diagonals:
		if not bool(corner[0]) or bool(corner[1]):
			continue
		if absf(px - float(corner[2])) < stroke and absf(py - float(corner[3])) < stroke:
			return true
	return false


## La MARQUE d'un coin rentrant : un petit carre pose en retrait de l'angle, la ou le vide
## touche la case par un point. ⚠ C'est une marque, pas un trait du dessin -- elle dit
## « cette tuile n'est pas la meme que sa voisine » sans pretendre etre une cote.
static func _on_inner_tick(px: float, py: float, last: float, stroke: float, index: int,
		north: bool, east: bool, south: bool, west: bool) -> bool:
	var gap: float = stroke * 2.2
	var half: float = stroke * 1.15
	var diagonals: Array = [
		[north and east, (index & BlobIndex.NE) != 0, last, 0.0],
		[south and east, (index & BlobIndex.SE) != 0, last, last],
		[south and west, (index & BlobIndex.SW) != 0, 0.0, last],
		[north and west, (index & BlobIndex.NW) != 0, 0.0, 0.0],
	]
	for corner: Array in diagonals:
		if not bool(corner[0]) or bool(corner[1]):
			continue
		var cx: float = float(corner[2])
		var cy: float = float(corner[3])
		var mx: float = cx + (gap if cx == 0.0 else -gap)
		var my: float = cy + (gap if cy == 0.0 else -gap)
		if absf(px - mx) < half and absf(py - my) < half:
			return true
	return false


## Les quatre coins : [cote A, cote B, x, y].
static func _corners(last: float, north: bool, east: bool, south: bool, west: bool) -> Array:
	return [
		[north, east, last, 0.0],
		[south, east, last, last],
		[south, west, 0.0, last],
		[north, west, 0.0, 0.0],
	]


static func make_wall(role: Vector2i, tile_size: int, ink: Ink, purpose: Purpose) -> Image:
	var side: int = tile_size * SUPERSAMPLE
	var wire: bool = ink == Ink.WIREFRAME
	var last: float = float(side - 1)
	var stroke: float = STROKE * float(side) * (1.9 if purpose == Purpose.REPRESENTATIVE else 1.0)
	# ⚠ TROIS ETATS PAR FLANC, ET CHACUN A SON TRACE.
	#   VIDE   la roche s'arrete : un liseré au bord, et la case voisine dessine la plaine.
	#   MUET   rien : ou la meme face continue, ou c'est le voisin qui portera l'angle.
	#   DEVANT je suis le bloc qui avance : je porte mon angle, POSE JUSQU'AU BORD.
	# ⚠ ET L'ANGLE N'EST PAS SYMETRIQUE : lumiere du nord-ouest, donc l'angle ouest accroche
	# le jour et l'angle est recule. C'est ce qui fait qu'on lit DE QUEL COTE est le retrait.
	var west: int = Walls.pan_west(role.x)
	var east: int = Walls.pan_east(role.x)
	# ⚠ LE RAPPORT DES DEUX MARQUES EST VOULU, ET IL NE L'ETAIT PAS. Le liseré du vide etait
	# une fraction fixe de la tuile tandis que l'angle derivait de `stroke`, lequel porte le
	# facteur d'exageration du mode representatif : l'angle etait donc plus LARGE que le
	# liseré en representatif et plus ETROIT en utilisable, le rapport s'inversant d'une
	# technique a l'autre. Accident, pas intention.
	#
	# ⚠ ET LA LARGEUR EST LA MEME POUR LES DEUX. Elle ne l'etait pas -- 0,10 pour le vide,
	# 0,055 pour l'arete -- et comme l'ETAT D'UN FLANC CHANGE EN DESCENDANT (le voisin est
	# en retrait sur trois rangees, puis sa robe s'arrete), la bande passait de large a
	# etroite EN COURS DE COLONNE. Elle pulsait, et ca se lit comme une negligence.
	#
	# Une seule largeur, donc, et c'est la TEINTE qui dit ce qui se passe : le vide est doux
	# -- la plaine a cote fait deja tout le contraste -- l'arete est franche, puisqu'elle a
	# de la roche des deux cotes. La bande descend d'un trait, et seule sa couleur bouge.
	var swell: float = 1.6 if purpose == Purpose.REPRESENTATIVE else 1.0
	var band: float = 0.09 * float(side) * swell
	var rim: float = band
	var edge: float = band
	var base: Color = WIRE_WALL
	if not wire:
		base = STONE_BODY
	var buffer: PackedByteArray = _blank(side, base)
	var mark: Color = MARK_WIRE if wire else MARK_PAINT
	var inset: float = last * 0.32
	for y: int in range(side):
		for x: int in range(side):
			var px: float = float(x)
			var py: float = float(y)
			# ⚠ ON NE RENTRE PLUS LE FLANC VIDE. Il rentrait de 10 %, et c'etait faux deux
			# fois. D'abord parce qu'UNE CASE DE FALAISE EST UNE CASE DE ROCHE : la mettre a
			# 80 % de sa case fait disparaitre de la matiere que le modele affirme. Ensuite
			# et surtout : des qu'une colonne descend plus bas que ses voisines -- ce qui
			# arrive des que deux chutes ne font pas la meme hauteur, donc partout -- ses
			# flancs passent de MUET a VIDE en cours de route, et la face CHANGEAIT
			# D'EPAISSEUR EN DESCENDANT. Le vide se dit par l'ombre du bord, pas en mangeant
			# la roche.
			var color: Color = base
			if wire:
				# ⚠ SEULS LES VRAIS BORDS SE TRACENT. Le haut du chapiteau est la levre, le
				# bas du pied est le sol ; entre deux rangees de corps il n'y a AUCUNE
				# ligne, la face est continue -- sans quoi la falaise serait rayee de traits
				# que rien ne justifie.
				if west == Walls.SIDE_VOID and px < rim:
					color = WIRE_EDGE
				elif east == Walls.SIDE_VOID and px > last - rim:
					color = WIRE_EDGE
				elif west == Walls.SIDE_FRONT and px < edge:
					color = WIRE_LIP
				elif east == Walls.SIDE_FRONT and px > last - edge:
					color = WIRE_FACE
				elif role.y == Walls.ROW_CROWN and py < stroke:
					color = WIRE_LIP
				elif role.y == Walls.ROW_FOOT and py > last - stroke:
					color = WIRE_FACE
			else:
				# ⚠ CHAQUE RANGEE COMMENCE ET FINIT SUR LA TEINTE DU CORPS. Le chapiteau part de
				# la lumiere en haut et REJOINT le corps en bas ; le pied part du corps et
				# s'enfonce. Sans ca, deux rangees voisines se raccordent sur deux teintes
				# differentes, et la falaise est barree d'une couture a chaque cran.
				var vertical: float = py / last
				if role.y == Walls.ROW_CROWN:
					color = base.lightened(0.34 * (1.0 - smoothstep(0.0, 1.0, vertical)))
				elif role.y == Walls.ROW_FOOT:
					color = base.darkened(0.34 * smoothstep(0.0, 1.0, vertical))
				# ⚠ LA STRIURE NE SE DECALE PLUS D'UNE RANGEE A L'AUTRE. Elle le faisait,
				# pour « varier le grain » -- et cassait CHAQUE rainure a CHAQUE cran : sur
				# une chute de six cases, la paroi se lisait comme une pile de tuiles au lieu
				# d'une face. Mesuree, la rupture ne pesait que 2,4 % de teinte et elle
				# sautait aux yeux : une LIGNE BRISEE se voit bien mieux qu'un degrade.
				var streak: float = fmod(px / float(side) * 2.0, 1.0)
				if streak < 0.05:
					color = color.darkened(0.05)
				# ⚠ CE QUI DISTINGUE LES DEUX RANGEES DE CORPS EST UNE ASSISE, PAS UN
				# DECALAGE DE GRAIN. Elle se tient loin des deux bords, donc elle ne peut pas
				# se voir au raccord, quelle que soit la rangee qui suit.
				if role.y == 1 or role.y == 2:
					var ledge: float = 0.40 if role.y == 1 else 0.62
					if absf(vertical - ledge) < 0.055:
						color = color.darkened(0.07)
				if west == Walls.SIDE_VOID and px < rim:
					color = color.lightened(0.13)
				elif west == Walls.SIDE_FRONT and px < edge:
					color = color.lightened(0.30)
				if east == Walls.SIDE_VOID and px > last - rim:
					color = color.darkened(0.16)
				elif east == Walls.SIDE_FRONT and px > last - edge:
					color = color.darkened(0.36)
			# ⚠ LE CODE DE RANGEE EST UNE MARQUE, PAS UN TRAIT. Un tiret pour le premier
			# corps, deux pour le second : sans lui rien ne distingue les deux rangees, et
			# c'est exactement ce qu'il faut savoir en peignant.
			if purpose == Purpose.REPRESENTATIVE and px > inset and px < last - inset:
				if role.y == 1 and absf(py - last * 0.5) < stroke * 0.6:
					color = mark
				elif role.y == 2 and (absf(py - last * 0.35) < stroke * 0.6 \
						or absf(py - last * 0.65) < stroke * 0.6):
					color = mark
			_put(buffer, side, x, y, color)
	return _finish(buffer, side, tile_size)


static func make_ground_shadow(tile_size: int) -> Image:
	var side: int = tile_size * SUPERSAMPLE
	var buffer: PackedByteArray = _blank(side, GROUND_SHADOW)
	var last: float = float(side - 1)
	for y: int in range(side):
		var fade: float = 1.0 - smoothstep(0.0, 0.55, float(y) / last)
		if fade <= 0.0:
			continue
		for x: int in range(side):
			var shade: Color = GROUND_SHADOW
			shade.a = GROUND_SHADOW.a * fade
			_put(buffer, side, x, y, shade)
	return _finish(buffer, side, tile_size)


static func make_contact_shadow(tile_size: int) -> Image:
	var side: int = tile_size * SUPERSAMPLE
	var buffer: PackedByteArray = _blank(side, CONTACT_SHADOW)
	var last: float = float(side - 1)
	for x: int in range(side):
		var fade: float = 1.0 - smoothstep(0.0, 0.5, float(x) / last)
		if fade <= 0.0:
			continue
		for y: int in range(side):
			var shade: Color = CONTACT_SHADOW
			shade.a = CONTACT_SHADOW.a * fade
			_put(buffer, side, x, y, shade)
	return _finish(buffer, side, tile_size)
