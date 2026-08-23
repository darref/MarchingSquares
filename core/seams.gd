# LES RACCORDS OBLIGATOIRES — les pixels que le modele PROUVE identiques.
#
# Deux cases de robe qui se touchent ne se ressemblent pas : par endroits, elles sont
# LA MEME PAROI. Le pixel qui borde l'une borde l'autre, et il n'y a aucune liberte a
# prendre -- c'est un seul point de roche, vu dans deux tuiles.
#
# ⚠ CE N'EST PAS UNE AIDE AU GESTE, C'EST LA MEME REGLE QUE LES JUMELLES, D'UN CRAN PLUS
# FIN. Une jumelle est la meme TUILE vue ailleurs ; ici c'est le meme PIXEL vu ailleurs.
# Rien n'est fabrique (charte, regle 3) : l'artiste peint, on recopie la ou l'egalite est
# demontree. Et comme elle l'est, ne pas recopier ne produirait qu'un tileset faux --
# d'ou l'absence de case a cocher (regle 5).
#
# DEUX FAMILLES DE CONTRAINTES, ET ELLES SONT DEJA ASSERTEES PAR LA SUITE.
#
#   VERTICALEMENT. Deux rangees qui se suivent dans une meme chute sont la meme face :
#   la derniere ligne de pixels de l'une EST la premiere de l'autre. Les enchainements se
#   lisent des chutes reelles, pas d'une intuition.
#
#   ⚠ ET LA CHAINE BOUCLE, CE QUI VA PLUS LOIN QU'IL N'Y PARAIT. Une chute de trois donne
#   « chapiteau, corps 0, pied » et une de six « chapiteau, corps 0, corps 1, corps 0,
#   corps 1, pied » : par transitivite, TOUS les raccords internes d'un pan portent LE
#   MEME profil. Le haut et le bas d'une tuile de corps sont donc identiques -- ce qui est
#   exactement ce qu'on attend d'une tuile qui se repete verticalement.
#
#   HORIZONTALEMENT. Deux flancs `muet` face a face signifient LA MEME LEVRE, donc la meme
#   face, donc le meme pas de chute, donc la meme rangee. La colonne droite de l'une EST la
#   colonne gauche de l'autre.
#
# ⚠ ET LES SURFACES N'EN SONT PAS. Le modele n'y exige que l'absence de TROU, jamais
# l'egalite : a la frontiere entre une case dont le nord est plein et une case dont il est
# vide, la levre eclairee s'arrete NET, et elle a raison -- le terrain fait une marche la.
# Y forcer les pixels accuserait le dessin d'etre fidele. Ce fichier ne parle que de robes.
#
# ⚠ NI LES ARETES. La ou un flanc dit `devant`, une arete est ATTENDUE : on n'y exige que
# de la matiere des deux cotes, pas la meme teinte.
extends RefCounted

const Walls := preload("res://core/walls.gd")

## Les quatre bords d'une tuile. Un pixel de coin appartient a DEUX bords, et se propage
## par les deux -- ses deux classes sont independantes et toutes deux legitimes.
const TOP: int = 0
const BOTTOM: int = 1
const LEFT: int = 2
const RIGHT: int = 3

## Un bord se nomme (pan, rangee, cote). Chaque bord pointe vers les AUTRES bords qui
## doivent porter exactement les memes pixels.
static var GROUPS: Dictionary = {}

## Les quatre coins d'une tuile.
const TOP_LEFT: int = 0
const TOP_RIGHT: int = 1
const BOTTOM_RIGHT: int = 2
const BOTTOM_LEFT: int = 3

## ⚠ UN PIXEL DE COIN APPARTIENT A DEUX BORDS, DONC A DEUX CLASSES, ET ELLES DOIVENT SE
## REJOINDRE LA. Le coin bas-droit d'une tuile est partage avec sa voisine de l'EST -- meme
## colonne mitoyenne -- et avec sa voisine du SUD -- meme ligne mitoyenne. Les deux
## contraintes portent sur le MEME point de roche : les ignorer laissait trente desaccords,
## tous sur des coins, alors que les milliers de pixels de bord tombaient juste.
##
## ⚠ ET LA FUSION NE VAUT QU'AU COIN. On ne marie pas les deux classes entieres -- une
## ligne et une colonne n'ont aucune raison d'etre egales sur toute leur longueur. Seuls
## leurs bouts se rejoignent.
static var CORNERS: Dictionary = {}

static var _parent: Dictionary = {}
static var _corner_parent: Dictionary = {}


static func _static_init() -> void:
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			for side: int in range(4):
				_root(Vector3i(pan, row, side))

	# --- VERTICALEMENT : les enchainements de rangees, lus des chutes REELLES.
	for pair: Vector2i in row_chains():
		for pan: int in range(Walls.PAN_COUNT):
			_join(Vector3i(pan, pair.x, BOTTOM), Vector3i(pan, pair.y, TOP))

	# --- HORIZONTALEMENT : les flancs muets qui se font face, a la meme rangee.
	for row: int in range(Walls.BLOCK_ROWS):
		for left: int in range(Walls.PAN_COUNT):
			if Walls.pan_east(left) != Walls.SIDE_MUTE:
				continue
			for right: int in range(Walls.PAN_COUNT):
				if Walls.pan_west(right) != Walls.SIDE_MUTE:
					continue
				_join(Vector3i(left, row, RIGHT), Vector3i(right, row, LEFT))

	var members: Dictionary = {}
	for edge: Vector3i in _parent.keys():
		var root: Vector3i = _root(edge)
		if not members.has(root):
			var fresh: Array[Vector3i] = []
			members[root] = fresh
		(members[root] as Array[Vector3i]).append(edge)
	for edge: Vector3i in _parent.keys():
		var others: Array[Vector3i] = []
		for member: Vector3i in members[_root(edge)]:
			if member != edge:
				others.append(member)
		GROUPS[edge] = others

	# --- LES COINS. Chaque classe de bords marie les coins de ses deux bouts.
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			for corner: int in range(4):
				_corner_root(Vector3i(pan, row, corner))
	for root: Vector3i in members.keys():
		var group: Array[Vector3i] = members[root]
		for k: int in range(1, group.size()):
			for far: int in [0, 1]:
				_corner_join(_corner_of(group[0], far), _corner_of(group[k], far))
	var corner_members: Dictionary = {}
	for key: Vector3i in _corner_parent.keys():
		var seat: Vector3i = _corner_root(key)
		if not corner_members.has(seat):
			var fresh: Array[Vector3i] = []
			corner_members[seat] = fresh
		(corner_members[seat] as Array[Vector3i]).append(key)
	for key: Vector3i in _corner_parent.keys():
		var others: Array[Vector3i] = []
		for member: Vector3i in corner_members[_corner_root(key)]:
			if member != key:
				others.append(member)
		CORNERS[key] = others


## Le coin ou aboutit un bord : `far` dit lequel de ses deux bouts.
static func _corner_of(edge: Vector3i, far: int) -> Vector3i:
	var corner: int = TOP_LEFT
	match edge.z:
		TOP:
			corner = TOP_RIGHT if far == 1 else TOP_LEFT
		BOTTOM:
			corner = BOTTOM_RIGHT if far == 1 else BOTTOM_LEFT
		LEFT:
			corner = BOTTOM_LEFT if far == 1 else TOP_LEFT
		RIGHT:
			corner = BOTTOM_RIGHT if far == 1 else TOP_RIGHT
	return Vector3i(edge.x, edge.y, corner)


## Les couples de rangees qui se suivent dans une chute reelle.
##
## ⚠ ON LES LIT DE `row_for`, ON NE LES DEVINE PAS. Deviner depuis les noms de rangees
## fabriquerait des enchainements que la chute ne produit jamais -- et un test faux coute
## plus cher qu'un test absent : il envoie corriger ce qui va bien.
static func row_chains() -> Array[Vector2i]:
	var seen: Dictionary = {}
	var chains: Array[Vector2i] = []
	for drop: int in range(1, Walls.STOREY_TILES * 9 + 1):
		var rows: Array[int] = []
		for step: int in range(1, drop + 1):
			rows.append(Walls.row_for(step, drop, true))
		for k: int in range(rows.size() - 1):
			var pair: Vector2i = Vector2i(rows[k], rows[k + 1])
			if not seen.has(pair):
				seen[pair] = true
				chains.append(pair)
	return chains


## Les pixels qu'un pixel oblige ailleurs : (pan, rangee, x, y).
##
## ⚠ LE MEME PIXEL PEUT REVENIR DANS SA PROPRE TUILE. Le haut et le bas d'une tuile de
## corps sont le meme profil : peindre l'un peint l'autre, sur la meme image.
static func mirrors(role: Vector2i, x: int, y: int, resolution: int) -> Array[Vector4i]:
	var out: Array[Vector4i] = []
	var last: int = resolution - 1
	var at_x: bool = x == 0 or x == last
	var at_y: bool = y == 0 or y == last
	if at_x and at_y:
		# Un coin : sa classe a lui, celle qui marie la ligne et la colonne.
		var corner: int = TOP_LEFT
		if x == last:
			corner = BOTTOM_RIGHT if y == last else TOP_RIGHT
		elif y == last:
			corner = BOTTOM_LEFT
		var here: Vector3i = Vector3i(role.x, role.y, corner)
		if CORNERS.has(here):
			for other: Vector3i in CORNERS[here]:
				out.append(_corner_pixel(other, last))
		return out
	if y == 0:
		_spread(out, role, TOP, x, last)
	elif y == last:
		_spread(out, role, BOTTOM, x, last)
	elif x == 0:
		_spread(out, role, LEFT, y, last)
	elif x == last:
		_spread(out, role, RIGHT, y, last)
	return out


static func _corner_pixel(corner: Vector3i, last: int) -> Vector4i:
	match corner.z:
		TOP_LEFT:
			return Vector4i(corner.x, corner.y, 0, 0)
		TOP_RIGHT:
			return Vector4i(corner.x, corner.y, last, 0)
		BOTTOM_RIGHT:
			return Vector4i(corner.x, corner.y, last, last)
	return Vector4i(corner.x, corner.y, 0, last)


## ⚠ LA POSITION NE SE RETOURNE PAS. Un bas colle a un haut garde ses colonnes ; une droite
## collee a une gauche garde ses rangees. Les deux tuiles sont posees dans le meme sens sur
## la carte -- il n'y a ni miroir ni rotation ici, et il ne doit pas y en avoir (regle 3).
static func _spread(into: Array[Vector4i], role: Vector2i, side: int, position: int,
		last: int) -> void:
	var here: Vector3i = Vector3i(role.x, role.y, side)
	if not GROUPS.has(here):
		return
	for other: Vector3i in GROUPS[here]:
		match other.z:
			TOP:
				into.append(Vector4i(other.x, other.y, position, 0))
			BOTTOM:
				into.append(Vector4i(other.x, other.y, position, last))
			LEFT:
				into.append(Vector4i(other.x, other.y, 0, position))
			RIGHT:
				into.append(Vector4i(other.x, other.y, last, position))


## Combien de bords sont lies, et combien restent libres. Pour le dire a l'ecran.
static func tally() -> Dictionary:
	var linked: int = 0
	for edge: Vector3i in GROUPS.keys():
		if not (GROUPS[edge] as Array).is_empty():
			linked += 1
	return {
		"edges": GROUPS.size(),
		"linked": linked,
		"free": GROUPS.size() - linked,
	}


static func _root(edge: Vector3i) -> Vector3i:
	if not _parent.has(edge):
		_parent[edge] = edge
		return edge
	if _parent[edge] == edge:
		return edge
	_parent[edge] = _root(_parent[edge])
	return _parent[edge]


static func _join(a: Vector3i, b: Vector3i) -> void:
	var ra: Vector3i = _root(a)
	var rb: Vector3i = _root(b)
	if ra != rb:
		_parent[ra] = rb


static func _corner_root(key: Vector3i) -> Vector3i:
	if not _corner_parent.has(key):
		_corner_parent[key] = key
		return key
	if _corner_parent[key] == key:
		return key
	_corner_parent[key] = _corner_root(_corner_parent[key])
	return _corner_parent[key]


static func _corner_join(a: Vector3i, b: Vector3i) -> void:
	var ra: Vector3i = _corner_root(a)
	var rb: Vector3i = _corner_root(b)
	if ra != rb:
		_corner_parent[ra] = rb
