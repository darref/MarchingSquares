# LES SYMETRIES — et les conditions strictes qui les rendent licites.
#
# ⚠ ELLES SONT INTERDITES PAR DEFAUT. Tourner ou retourner une tuile FABRIQUE un dessin que
# personne n'a peint dans cette orientation, ce que la charte refuse (regle 3). Sur un
# tileset eclaire, c'est aussi visiblement faux : la lumiere vient du nord-ouest, et tourner
# une tuile tourne ses hautes lumieres avec elle. L'orbite des quatre coins d'une masse
# pleine le dit le mieux -- obtenus par rotation, ils sont tous les quatre eclaires pareil,
# soit l'air plat que cet outil existe pour eviter.
#
# ⚠ ELLES DEVIENNENT CORRECTES SANS LUMIERE. Si un mode livre des tuiles sans direction
# d'eclairage, rien dans le dessin ne contredit une rotation. C'est alors une PROPRIETE DU
# MODE, decidee une fois avec lui, jamais une case a cocher offerte au milieu du dessin.
#
# Ce que ca coute, mesure :
#   surfaces : 47 index -> 15 orbites sous la rotation (les miroirs n'en gagneraient qu'une
#              de plus, 14 : le jeu des 47 est deja presque clos par reflexion)
#   robes    : 12 roles -> 8 sous le miroir est-ouest. La rotation n'y a aucun sens, un
#              plateau n'a de face qu'au sud ; le miroir vertical non plus, le pied repose
#              sur le sol.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")

## Les transformations qu'une case peut subir.
const TURN_NONE: int = 0
const TURN_QUARTER: int = 1
const TURN_HALF: int = 2
const TURN_THREE_QUARTERS: int = 3
const MIRROR: int = 4

## Un quart de tour horaire, vu du voisinage : N devient E, NE devient SE, et ainsi de suite.
const CLOCKWISE: Dictionary = {
	1: 4, 2: 8, 4: 16, 8: 32, 16: 64, 32: 128, 64: 1, 128: 2,
}

## Le miroir est-ouest : N et S ne bougent pas, E et W s'echangent, les coins suivent.
const EAST_WEST: Dictionary = {
	1: 1, 2: 128, 4: 64, 8: 32, 16: 16, 32: 8, 64: 4, 128: 2,
}

## Les orbites des 47 index sous la rotation, triees et calculees au chargement.
static var ROTATION_ORBITS: Array[PackedInt32Array] = []

## Les orbites des 12 roles de robe sous le miroir est-ouest.
static var MIRROR_ORBITS: Array[Array] = []

## L'orbite de chaque index, pour la retrouver sans la chercher.
static var ORBIT_OF: Dictionary = {}


static func _static_init() -> void:
	var seen: Dictionary = {}
	for index: int in BlobIndex.CANONICAL_INDICES:
		if seen.has(index):
			continue
		var orbit: Array = []
		var walker: int = index
		for _turn: int in range(4):
			if not orbit.has(walker):
				orbit.append(walker)
			seen[walker] = true
			walker = rotate_index(walker)
		orbit.sort()
		var packed: PackedInt32Array = PackedInt32Array(orbit)
		ROTATION_ORBITS.append(packed)
		for member: int in packed:
			ORBIT_OF[member] = packed

	var role_seen: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		if role_seen.has(role):
			continue
		var pair: Array[Vector2i] = [role]
		var other: Vector2i = mirror_role(role)
		if other != role:
			pair.append(other)
		for member: Vector2i in pair:
			role_seen[member] = true
		MIRROR_ORBITS.append(pair)


## Un quart de tour horaire applique a un index de surface.
static func rotate_index(index: int) -> int:
	var turned: int = 0
	for bit: int in CLOCKWISE.keys():
		if (index & bit) != 0:
			turned |= int(CLOCKWISE[bit])
	return BlobIndex.canonicalize(turned)


## Le miroir est-ouest applique a un index de surface. Garde pour memoire : il ne sert pas
## au remplissage, puisqu'il n'apporte qu'une tuile de plus par-dessus les rotations.
static func mirror_index(index: int) -> int:
	var flipped: int = 0
	for bit: int in EAST_WEST.keys():
		if (index & bit) != 0:
			flipped |= int(EAST_WEST[bit])
	return BlobIndex.canonicalize(flipped)


## Le miroir est-ouest applique a un role de robe : le pan gauche devient le pan droit, le
## pan courant ne bouge pas, et la rangee est inchangee -- le haut reste en haut.
static func mirror_role(role: Vector2i) -> Vector2i:
	var pan: int = role.x
	if pan == Walls.PAN_LEFT:
		pan = Walls.PAN_RIGHT
	elif pan == Walls.PAN_RIGHT:
		pan = Walls.PAN_LEFT
	return Vector2i(pan, role.y)


## Combien de quarts de tour separent [param from] de [param to], ou -1 s'ils ne sont pas
## dans la meme orbite.
static func turns_between(from: int, to: int) -> int:
	var walker: int = from
	for turn: int in range(4):
		if walker == to:
			return turn
		walker = rotate_index(walker)
	return -1


## La transformation appliquee aux pixels d'une tuile de cote [param side].
##
## ⚠ LE PIXEL SUIT L'IMAGE, PAS L'INVERSE. Tourner la tuile d'un quart de tour horaire
## envoie ce qui etait en haut vers la droite : (x, y) devient (cote-1-y, x). C'est la meme
## rotation que celle du voisinage, sans quoi le dessin et sa silhouette se contrediraient.
static func transform_pixel(x: int, y: int, side: int, transform: int) -> Vector2i:
	match transform:
		TURN_QUARTER:
			return Vector2i(side - 1 - y, x)
		TURN_HALF:
			return Vector2i(side - 1 - x, side - 1 - y)
		TURN_THREE_QUARTERS:
			return Vector2i(y, side - 1 - x)
		MIRROR:
			return Vector2i(side - 1 - x, y)
	return Vector2i(x, y)


## Combien de tuiles il reste vraiment a peindre quand les symetries remplissent le reste.
static func surface_work_count() -> int:
	return ROTATION_ORBITS.size()


static func wall_work_count() -> int:
	return MIRROR_ORBITS.size()
