# L'EPAISSEUR — la regle du mode epais : bord + centre + bord, rien de plus fin.
#
# UNE CASE EST « FINE » si sa COURSE -- la suite de cases du meme etat qui la contient le
# long d'un axe -- fait moins de TROIS. Le mode epais interdit toute case fine, pleine OU
# vide, dans CHAQUE silhouette d'etage. Deux decisions utilisateur, prises en peignant :
# d'abord interdire les reliefs d'UNE tuile d'epaisseur (pointes, isthmes, ilots, trous
# d'une case -- les tuiles a matiere minoritaire concentraient tous les problemes
# d'expression) ; puis monter la barre a TROIS -- une bande de deux n'a pas d'interieur,
# c'est deux bords dos a dos, et le peintre ne peut rien supposer du cote masse de ses
# tuiles de bord.
#
# ⚠ LA BARRE A TROIS NE CHANGE PAS LE VOCABULAIRE, et c'est un theoreme : dans une
# fenetre 3x3, toute course a au moins un bout sur le bord de la fenetre -- donc
# prolongeable a l'infini dehors -- SAUF la course d'une seule case bornee des deux
# cotes. La condition de realisabilite des fenetres est donc la meme qu'a min deux,
# et les 27 index tiennent. Ce que min trois change, ce sont les ADJACENCES (deux bords
# opposes ne se collent plus) et la geometrie des guides, preuves et pinceaux.
#
# LE VOCABULAIRE QUI SURVIT SE CALCULE, IL NE S'ECRIT PAS EN DUR -- meme raison que
# CANONICAL_INDICES : une liste ecrite a la main est un endroit ou mentir.
#
#   SURFACES : un THEOREME, par les 256 fenetres 3x3 (centre plein). Sur un plan non
#   borne, une fenetre est realisable en relief epais si et seulement si son centre
#   n'est pas fin (ses deux paires sont internes) et qu'aucune voisine cardinale n'est
#   fine par sa paire laterale interne (ses deux coins adjacents) -- l'autre paire de
#   chaque cardinale et les deux paires de chaque coin touchent l'exterieur, et
#   l'exterieur est libre : on y pose une case du meme etat, puis on epaissit. Ajouter
#   des cases du meme etat que leur voisine ne rend fine aucune case interieure, donc
#   l'exterieur n'ajoute jamais de contrainte : c'est une equivalence, pas une borne.
#   Resultat : 27 index sur 47.
#
#   ROBES : une forme fermee, PORTEE par le recensement (tools/thick_census.gd -- battue
#   sur reliefs epais plus escarpements construits) :
#     - un flanc DEVANT exige un flanc MUET de l'autre cote : un bloc qui avance fait au
#       moins deux colonnes, donc sa colonne d'angle a toujours sa jumelle muette a cote.
#       (vide,devant), (devant,vide) et (devant,devant) exigeraient un surplomb d'une
#       colonne -- une levre fine ;
#     - le CHAPITEAU exige au moins un flanc muet : une levre aux deux flancs vides
#       serait une langue d'une case. Les rangees basses de (vide,vide) survivent : une
#       colonne peut finir seule en profondeur, ses voisines ayant atterri avant elle.
#   Resultat : 23 roles sur 36.
#
#   CROISEMENTS : les 15 survivent tous (temoins en blocs 2x2 au recensement).
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")
const HeightMask := preload("res://core/height_mask.gd")

## Les index de surface realisables en relief epais, calcules au chargement.
static var SURFACE_INDICES: PackedInt32Array = PackedInt32Array()


static func _static_init() -> void:
	var alive: Dictionary = {}
	for raw: int in range(256):
		if window_realizable(raw):
			alive[BlobIndex.canonicalize(raw)] = true
	var sorted_indices: Array = alive.keys()
	sorted_indices.sort()
	SURFACE_INDICES = PackedInt32Array(sorted_indices)


## Le theoreme des fenetres : cette fenetre brute (8 bits de voisinage, centre plein)
## peut-elle exister dans un relief ou rien n'est fin ?
static func window_realizable(raw: int) -> bool:
	var n: bool = (raw & BlobIndex.N) != 0
	var e: bool = (raw & BlobIndex.E) != 0
	var s: bool = (raw & BlobIndex.S) != 0
	var w: bool = (raw & BlobIndex.W) != 0
	var ne: bool = (raw & BlobIndex.NE) != 0
	var se: bool = (raw & BlobIndex.SE) != 0
	var sw: bool = (raw & BlobIndex.SW) != 0
	var nw: bool = (raw & BlobIndex.NW) != 0
	if (not n and not s) or (not e and not w):
		return false
	if ne != n and nw != n:
		return false
	if ne != e and se != e:
		return false
	if se != s and sw != s:
		return false
	if sw != w and nw != w:
		return false
	return true


## Un role de robe existe-t-il en relief epais ? Forme fermee, portee par le recensement.
##
## ⚠ LE PASSAGE A MIN TROIS EN A REVELE DEUX DE PLUS : (vide,devant) et (devant,vide) au
## corps 1 -- le REDAN, une colonne qui plonge seule entre un tablier partiel et des
## colonnes en retrait. Ils etaient atteignables des min deux, la battue d'alors ne les
## avait pas rencontres : un sous-compte, expose avant qu'un acheteur ne tombe dessus.
## La battue continue de la suite garde cette forme : si un 26e role apparait un jour
## sur un relief epais, elle echoue, et la forme se corrige.
static func role_survives(role: Vector2i) -> bool:
	var west: int = Walls.pan_west(role.x)
	var east: int = Walls.pan_east(role.x)
	# (devant,devant) : mort -- si je suis devant mon voisin, il n'est pas devant moi.
	if west == Walls.SIDE_FRONT and east == Walls.SIDE_FRONT:
		return false
	# Le chapiteau exige un flanc muet : une levre sans voisine serait une bande fine.
	if role.y == Walls.ROW_CROWN and west != Walls.SIDE_MUTE and east != Walls.SIDE_MUTE:
		return false
	# Un couple vide-devant -- le redan -- n'existe qu'au corps 1, seul en profondeur.
	var mixed: bool = (west == Walls.SIDE_VOID and east == Walls.SIDE_FRONT) \
			or (west == Walls.SIDE_FRONT and east == Walls.SIDE_VOID)
	if mixed and role.y != 2:
		return false
	return true


## Les roles de robe du mode epais, dans l'ordre des pans puis des rangees.
static func wall_roles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			var role: Vector2i = Vector2i(pan, row)
			if role_survives(role):
				out.append(role)
	return out


## Une case fine dans la silhouette de l'etage [param storey] -- l'exterieur est vide.
##
## ⚠ MIN TROIS : BORD + CENTRE + BORD. Decision utilisateur du 24/08 : une bande de deux
## n'a pas d'interieur -- deux bords colles dos a dos -- et le peintre ne peut plus rien
## supposer du cote « masse » de ses tuiles de bord. La regle est donc : la COURSE de la
## case (la suite de cases du meme etat qui la contient, le long de chaque axe) fait au
## moins trois. Une course vide qui touche l'exterieur est infinie, jamais courte.
static func thin_at(heights: PackedStringArray, x: int, y: int, storey: int) -> bool:
	var full: bool = HeightMask.level_at(heights, x, y) >= storey
	return _run(heights, x, y, storey, full, Vector2i.RIGHT) < 3 \
			or _run(heights, x, y, storey, full, Vector2i.DOWN) < 3


## La longueur de la course du meme etat le long d'un axe, plafonnee a trois -- on n'a
## jamais besoin d'en savoir plus.
static func _run(heights: PackedStringArray, x: int, y: int, storey: int, full: bool,
		axis: Vector2i) -> int:
	var length: int = 1
	for direction: int in [-1, 1]:
		for step: int in [1, 2]:
			var same: bool = HeightMask.level_at(heights, x + axis.x * direction * step,
					y + axis.y * direction * step) >= storey
			if same != full:
				break
			length += 1
			if length >= 3:
				return length
	return length


## Toutes les cases fines d'un relief, tous etages confondus. Vide = relief epais.
## C'est la fonction que le pinceau consultera : un geste qui en cree une se refuse.
## ⚠ L'ETAGE 0 EN EST : depuis que le vide existe, la plaine a sa silhouette (tout ce
## qui n'est pas le vide), et un pont de plaine d'une case est aussi fin qu'une crete.
static func thin_cells(heights: PackedStringArray) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var top: int = 0
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			top = maxi(top, HeightMask.level_at(heights, x, y))
	for storey: int in range(0, top + 1):
		for y: int in range(-1, HeightMask.height(heights) + 1):
			for x: int in range(-1, HeightMask.width(heights) + 1):
				if thin_at(heights, x, y, storey):
					out.append(Vector3i(x, y, storey))
	return out
