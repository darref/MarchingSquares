# L'ILLUSTRATION DU GUIDE — le paysage tel qu'il sera une fois peint.
#
# Elle se calcule entierement depuis le relief : aucune image n'est lue, aucun pixel n'est
# emprunte. Les 47 silhouettes et les 12 robes suffisent a la dessiner, si bien qu'elle ne
# peut pas mentir sur ce que le guide contient -- si le relief change, elle change avec.
#
# ⚠ ON DESSINE ETAGE PAR ETAGE, DU BAS VERS LE HAUT. Chaque couche recouvre la precedente,
# et ce que decoupent les coins arrondis laisse voir l'etage d'en dessous. C'est la meme
# regle que la couverture : on ne voit que le sommet.
#
# ⚠ AUCUNE DEPENDANCE A UN NOEUD. Image et Color sont des ressources : ce fichier tourne en
# headless, et l'interface n'aura qu'a en faire une ImageTexture.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")

## Cote d'une case, en pixels.
const TILE: int = 24

## On dessine chaque tuile trois fois plus grand puis on la reduit : c'est ce qui donne des
## bords lisses. Dessiner directement a la taille finale rendrait des escaliers de pixels.
const SUPERSAMPLE: int = 3

## Rayon des coins exterieurs, en fraction de case. Assez pour arrondir, pas assez pour
## faire une pastille.
const OUTER_ROUND: float = 0.34

## Rayon de l'encoche des coins rentrants. Plus petit : c'est un pincement, pas un trou.
const INNER_ROUND: float = 0.22

## Largeur de la levre eclairee, en fraction de case.
const LIP: float = 0.11

# ⚠ LA PLAINE EST PLUS SOMBRE ET PLUS FROIDE QUE TOUT LE RESTE, et les falaises plus
# chaudes que les herbes. C'est ce qui fait ressortir les massifs : sans cet ecart, trois
# verts voisins donnent une purée où l'on ne lit plus les etages.
const PLAIN_COLOR: Color = Color(0.243, 0.282, 0.224)
const LEVEL_COLORS: Array[Color] = [
	Color(0.243, 0.282, 0.224),
	Color(0.400, 0.451, 0.278),
	Color(0.525, 0.569, 0.376),
	Color(0.663, 0.694, 0.510),
]
const STONE_CROWN: Color = Color(0.576, 0.510, 0.420)
const STONE_BODY_A: Color = Color(0.478, 0.416, 0.337)
const STONE_BODY_B: Color = Color(0.431, 0.373, 0.302)
const STONE_FOOT: Color = Color(0.318, 0.278, 0.220)
const GROUND_SHADOW: Color = Color(0.086, 0.098, 0.086, 0.38)
const CONTACT_SHADOW: Color = Color(0.086, 0.098, 0.086, 0.30)


## Rend le relief en une image. Une case du guide = TILE pixels.
## Le cote de tuile est un parametre : l'illustration sert de fond d'ecran a l'editeur,
## et doit pouvoir se caler sur la resolution des faux pixels.
static func render(heights: PackedStringArray, tile_size: int = TILE) -> Image:
	var columns: int = HeightMask.width(heights)
	var rows: int = HeightMask.height(heights)
	var image: Image = Image.create_empty(columns * tile_size, rows * tile_size, false, Image.FORMAT_RGBA8)
	image.fill(PLAIN_COLOR)

	var top_level: int = HeightMask.top_level(heights)
	var tops: Dictionary = {}
	for level: int in range(1, top_level + 1):
		for y: int in range(rows):
			for x: int in range(columns):
				var index: int = Coverage.index_at_level(heights, x, y, level)
				if index == Coverage.NO_INDEX:
					continue
				var key: Vector2i = Vector2i(index, level)
				if not tops.has(key):
					tops[key] = _make_top(index, level, tile_size)
				_stamp(image, tops[key], x, y, tile_size)

	var assembled: Dictionary = Walls.assemble(heights)
	var roles: Dictionary = assembled["roles"]
	var faces: Dictionary = {}
	var feet: Array[Vector2i] = []
	for level: int in range(1, top_level + 1):
		for key: Vector3i in roles.keys():
			if key.z != level:
				continue
			var role: Vector2i = roles[key]
			if not faces.has(role):
				faces[role] = _make_wall(role, tile_size)
			_stamp(image, faces[role], key.x, key.y, tile_size)
			if role.y == Walls.ROW_FOOT:
				feet.append(Vector2i(key.x, key.y + 1))

	# ⚠ L'OMBRE DE CONTACT NE SE POSE QU'A L'EST. La lumiere vient du nord-ouest, donc un
	# voisin plus haut porte son ombre vers le sud-est ; au sud c'est deja une robe qui
	# couvre la case, et il ne reste que le flanc est a assombrir.
	var contact: Image = _make_contact_shadow(tile_size)
	for y: int in range(rows):
		for x: int in range(columns):
			if HeightMask.level_at(heights, x - 1, y) > HeightMask.level_at(heights, x, y):
				_stamp(image, contact, x, y, tile_size)

	# L'ombre portee au sol, sous les pieds de falaise. C'est elle qui donne la hauteur ;
	# sans elle, un mur ressemble a un aplat colle sur l'herbe.
	var shadow: Image = _make_ground_shadow(tile_size)
	for cell: Vector2i in feet:
		if _has_wall_at(roles, cell):
			continue
		_stamp(image, shadow, cell.x, cell.y, tile_size)
	return image


static func _has_wall_at(roles: Dictionary, cell: Vector2i) -> bool:
	for key: Vector3i in roles.keys():
		if key.x == cell.x and key.y == cell.y:
			return true
	return false


static func _stamp(image: Image, tile: Image, x: int, y: int, tile_size: int) -> void:
	if x < 0 or y < 0 or x * tile_size >= image.get_width() or y * tile_size >= image.get_height():
		return
	image.blend_rect(tile, Rect2i(0, 0, tile_size, tile_size), Vector2i(x * tile_size, y * tile_size))


# --- Fabrication des tuiles ------------------------------------------------
#
# Chaque tuile est dessinee une seule fois puis reutilisee : il n'y a que 47 silhouettes
# par etage et 12 robes, la ou une carte en compte des centaines de cases.

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


static func _put(buffer: PackedByteArray, side: int, x: int, y: int, color: Color) -> void:
	var offset: int = (y * side + x) * 4
	buffer[offset] = int(clampf(color.r, 0.0, 1.0) * 255.0)
	buffer[offset + 1] = int(clampf(color.g, 0.0, 1.0) * 255.0)
	buffer[offset + 2] = int(clampf(color.b, 0.0, 1.0) * 255.0)
	buffer[offset + 3] = int(clampf(color.a, 0.0, 1.0) * 255.0)


static func _finish(buffer: PackedByteArray, side: int, tile_size: int) -> Image:
	var image: Image = Image.create_from_data(side, side, false, Image.FORMAT_RGBA8, buffer)
	image.resize(tile_size, tile_size, Image.INTERPOLATE_BILINEAR)
	return image


static func _make_top(index: int, level: int, tile_size: int) -> Image:
	var side: int = tile_size * SUPERSAMPLE
	var base: Color = LEVEL_COLORS[mini(level, LEVEL_COLORS.size() - 1)]
	var buffer: PackedByteArray = _blank(side, base)
	var outer: float = OUTER_ROUND * float(side)
	var inner: float = INNER_ROUND * float(side)
	var lip: float = LIP * float(side)
	var north: bool = (index & BlobIndex.N) != 0
	var east: bool = (index & BlobIndex.E) != 0
	var south: bool = (index & BlobIndex.S) != 0
	var west: bool = (index & BlobIndex.W) != 0
	var last: float = float(side - 1)
	for y: int in range(side):
		for x: int in range(side):
			var px: float = float(x)
			var py: float = float(y)
			if _carved(px, py, last, outer, inner, index, north, east, south, west):
				continue
			var color: Color = base
			# La lumiere vient du nord-ouest : la levre y est eclairee, l'autre bord recule.
			if not north and py < lip:
				color = base.lightened(0.30)
			elif not west and px < lip:
				color = base.lightened(0.18)
			elif not south and py > last - lip:
				color = base.darkened(0.26)
			elif not east and px > last - lip:
				color = base.darkened(0.16)
			_put(buffer, side, x, y, color)
	return _finish(buffer, side, tile_size)


## Vrai si le pixel est hors de la matiere : coin exterieur arrondi, ou encoche d'un coin
## rentrant. Un coin est exterieur quand les deux cotes voisins manquent, rentrant quand
## les deux cotes sont la mais pas la diagonale.
static func _carved(px: float, py: float, last: float, outer: float, inner: float,
		index: int, north: bool, east: bool, south: bool, west: bool) -> bool:
	var corners: Array = [
		[north, east, (index & BlobIndex.NE) != 0, last, 0.0],
		[south, east, (index & BlobIndex.SE) != 0, last, last],
		[south, west, (index & BlobIndex.SW) != 0, 0.0, last],
		[north, west, (index & BlobIndex.NW) != 0, 0.0, 0.0],
	]
	for corner: Array in corners:
		var side_a: bool = corner[0]
		var side_b: bool = corner[1]
		var diagonal: bool = corner[2]
		var cx: float = corner[3]
		var cy: float = corner[4]
		var dx: float = px - cx
		var dy: float = py - cy
		var distance: float = sqrt(dx * dx + dy * dy)
		if not side_a and not side_b:
			# Coin exterieur : la matiere s'arrondit vers l'interieur.
			var centre_x: float = cx + (outer if cx == 0.0 else -outer)
			var centre_y: float = cy + (outer if cy == 0.0 else -outer)
			var ox: float = px - centre_x
			var oy: float = py - centre_y
			var outward_x: bool = (px < centre_x) if cx == 0.0 else (px > centre_x)
			var outward_y: bool = (py < centre_y) if cy == 0.0 else (py > centre_y)
			if outward_x and outward_y and sqrt(ox * ox + oy * oy) > outer:
				return true
		elif side_a and side_b and not diagonal:
			# Coin rentrant : la case vide d'en face pince le coin.
			if distance < inner:
				return true
	return false


static func _make_wall(role: Vector2i, tile_size: int) -> Image:
	var side: int = tile_size * SUPERSAMPLE
	var base: Color = STONE_BODY_A
	match role.y:
		Walls.ROW_CROWN:
			base = STONE_CROWN
		Walls.ROW_FOOT:
			base = STONE_FOOT
		_:
			base = STONE_BODY_A if role.y == 1 else STONE_BODY_B
	var buffer: PackedByteArray = _blank(side, base)
	var last: float = float(side - 1)
	var margin: float = 0.10 * float(side)
	var round_radius: float = 0.22 * float(side)
	var left_end: bool = role.x == Walls.PAN_LEFT
	var right_end: bool = role.x == Walls.PAN_RIGHT
	for y: int in range(side):
		for x: int in range(side):
			var px: float = float(x)
			var py: float = float(y)
			# Un pan de bout dit « il n'y a rien de ce cote » : la face s'y arrete.
			if left_end and px < margin:
				continue
			if right_end and px > last - margin:
				continue
			if role.y == Walls.ROW_CROWN:
				if left_end and px < margin + round_radius and py < round_radius:
					var dx: float = (margin + round_radius) - px
					var dy: float = round_radius - py
					if dx > 0.0 and dy > 0.0 and sqrt(dx * dx + dy * dy) > round_radius:
						continue
				if right_end and px > last - margin - round_radius and py < round_radius:
					var rx: float = px - (last - margin - round_radius)
					var ry: float = round_radius - py
					if rx > 0.0 and ry > 0.0 and sqrt(rx * rx + ry * ry) > round_radius:
						continue
			var color: Color = base
			var vertical: float = py / last
			if role.y == Walls.ROW_CROWN:
				# L'arete du haut prend la lumiere, puis la face s'enfonce dans l'ombre.
				color = base.lightened(0.34 * (1.0 - smoothstep(0.0, 0.42, vertical)))
			elif role.y == Walls.ROW_FOOT:
				color = base.darkened(0.30 * smoothstep(0.35, 1.0, vertical))
			# Une striation discrete, pour que la roche ne soit pas un aplat.
			var streak: float = fmod(px / float(side) * 2.0, 1.0)
			if streak < 0.045:
				color = color.darkened(0.045)
			if left_end and px < margin * 2.0:
				color = color.lightened(0.10)
			if right_end and px > last - margin * 2.0:
				color = color.darkened(0.12)
			_put(buffer, side, x, y, color)
	return _finish(buffer, side, tile_size)


static func _make_ground_shadow(tile_size: int) -> Image:
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


static func _make_contact_shadow(tile_size: int) -> Image:
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
