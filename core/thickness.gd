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
#   ROBES : un seul pan meurt, et c'est encore min trois qui le tue. `(devant,devant)`
#   demanderait un eperon d'UNE colonne -- une course d'une case, donc fine. Les huit
#   autres pans vivent, a toutes les rangees.
#   Resultat : 40 roles sur 45 -- huit pans x cinq rangees.
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
	# ⚠ LE BORD DISPARAIT AVEC LA DECOMPOSITION EN COUCHES. Il a decline chaque silhouette
	# selon ce qu'il y avait au-dela de ses cardinaux vides -- du NU ou de la ROCHE -- parce
	# que le lisere d'epaisseur et l'eclairage de contour ne doivent pas se poser contre de la
	# roche. Ce sont deux marques qui parlent du VOISIN, et sous la regle des couches une tuile
	# ne dessine que sa propre matiere : elles n'ont plus lieu d'etre.
	#
	# La tuile redevient donc sa SILHOUETTE, et rien d'autre. Mesure : 48 -> 27, et ces 27
	# sont le theoreme des 256 fenetres, pas une forme cherchee.
	var tiles: Array = []
	for index: int in sorted_indices:
		tiles.append(int(index))
	tiles.sort()
	SURFACE_INDICES = PackedInt32Array(tiles)


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


## Un role de robe existe-t-il en relief epais ? UNE SEULE REGLE, et elle vient de
## l'epaisseur du RELIEF, pas d'une regle propre aux robes.
##
## ⚠ `(devant, devant)` EST LE SEUL MORT, ET C'EST LA BARRE DE MIN TROIS QUI LE TUE. Une
## colonne dont les DEUX voisines sont en retrait est un eperon d'UNE colonne -- une course
## d'une case dans la silhouette de son etage, donc fine, donc interdite. Un eperon epais
## fait au moins trois colonnes : ses deux bords portent (devant,muet) et (muet,devant), son
## milieu (muet,muet). Ce n'est donc pas une regle de plus, c'est une consequence.
##
## ⚠ ET LA REGLE « AU MOINS UN FLANC MUET » A ETE RETIREE, APRES AVOIR ETE POSEE. Elle
## repondait a un vrai defaut -- une meme tuile sommee de border tantot de l'herbe, tantot
## de la roche -- mais elle repondait au SYMPTOME. La cause etait que `muet` voulait dire
## deux choses, dont « le sommet d'un plateau est a cote, c'est A LUI de tracer » : et « lui »
## etait une tuile de SURFACE, la meme a des dizaines d'endroits, incapable de tracer quoi que
## ce soit. Depuis que le sommet d'un plateau rend `vide`, chaque etat ne dit plus qu'une
## chose et AUCUNE tuile n'est sommee d'etre deux choses. La regle n'avait plus de
## justification, et son prix avait triple : mesure, elle faisait passer les reliefs
## acceptables de 96 % a 68 %.
static func role_survives(role: Vector2i) -> bool:
	# ⚠ LES VINGT VIVENT, ET C'EST LA FIN DU CLIQUET. Avec trois etats de flanc, la forme
	# etait CHERCHEE : on battait le monde en esperant qu'aucun 45e role n'apparaisse, et il
	# en apparaissait -- le redan, puis les levres globales, puis les trois especes cachees
	# derriere `vide`. Avec deux etats, quatre pans x cinq rangees font vingt roles et la
	# battue les rencontre tous les vingt : il n'y a plus rien a chercher.
	#
	# Ce n'est pas que le modele en dit moins par prudence. C'est qu'une tuile ne repond plus
	# que d'elle-meme : « ma roche continue ou s'arrete ». Il n'existe aucune situation du
	# monde qui puisse la contredire, donc aucun role a decouvrir.
	var _unused: Vector2i = role
	return true


## Les cases de robe BORD DES DEUX COTES d'un relief : la regle ci-dessus, vue du monde.
##
## ⚠ ELLE NE SE LIT PAS SUR UNE FENETRE, IL FAUT ASSEMBLER. L'epaisseur du relief se voit
## sur une course de trois cases ; celle de la robe depend de la profondeur ou chaque
## colonne atterrit, donc des chutes. C'est la difference de nature entre les deux regles, et
## c'est ce qui la rend plus chere a controler sous le crayon -- mais pas plus chere que le
## remontage que le pinceau fait deja sur sa zone.
static func lonely_robe_cells(heights: PackedStringArray) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	for key: Vector3i in roles:
		var pan: int = (roles[key] as Vector2i).x
		if Walls.pan_west(pan) == Walls.SIDE_MUTE:
			continue
		if Walls.pan_east(pan) == Walls.SIDE_MUTE:
			continue
		out.append(key)
	return out


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


## LE PINCEMENT DIAGONAL : deux cases de meme etat qui se touchent COIN CONTRE COIN, alors que
## les deux cases cardinales qu'elles partagent sont de l'autre etat.
##
## ⚠ MIN TROIS DOIT VALOIR EN DIAGONALE AUSSI -- decision utilisateur. Deux massifs relies par
## un seul coin sont relies par une bande d'epaisseur UN : le modele doit alors exprimer une
## jonction que rien ne peut dessiner proprement, et le resultat est complique et laid. C'est
## exactement l'argument de min trois, sur l'autre axe : une bande d'epaisseur un n'a pas
## d'interieur, donc le peintre ne peut rien supposer de ses bords.
##
## ⚠ ET LA REGLE VAUT DANS LES DEUX ETATS. Un pincement de VIDE -- deux vides qui se touchent
## par un coin entre deux pleins -- est le meme defaut vu a l'envers : la matiere s'y etrangle.
##
## ⚠ ET ELLE NE TOUCHE PAS `thin_cells` : l'ancien modele a livre des guides qui contiennent des
## contacts diagonaux, deliberement -- ils portaient une tuile du reseau dual. Ajouter la clause
## la rendrait sa suite rouge sans rien reparer. Le nouveau modele l'appelle en plus.
static func diagonal_pinches(heights: PackedStringArray) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var top: int = 0
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			top = maxi(top, HeightMask.level_at(heights, x, y))
	for storey: int in range(0, top + 1):
		for y2: int in range(-1, HeightMask.height(heights) + 1):
			for x2: int in range(-1, HeightMask.width(heights) + 1):
				if pinched_at(heights, x2, y2, storey):
					out.append(Vector3i(x2, y2, storey))
	return out


## Le coin sud-est de la case (x, y) est-il un pincement, a cet etage ?
static func pinched_at(heights: PackedStringArray, x: int, y: int, storey: int) -> bool:
	var here: bool = HeightMask.level_at(heights, x, y) >= storey
	var down_right: bool = HeightMask.level_at(heights, x + 1, y + 1) >= storey
	var right: bool = HeightMask.level_at(heights, x + 1, y) >= storey
	var down: bool = HeightMask.level_at(heights, x, y + 1) >= storey
	if here == down_right and right == down and here != right:
		return true
	return false


## ⚠ Y A-T-IL UNE CASE FINE ? -- et on sort a la PREMIERE, sans batir la liste.
##
## `thin_cells` parcourt tous les etages et toutes les cases pour les COMPTER : c'est ce qu'il
## faut pour reparer, jamais pour refuser. Le pinceau et le generateur ne demandent qu'un oui ou
## non, et la plupart des reliefs refuses le sont des la premiere case examinee.
static func any_thin(heights: PackedStringArray) -> bool:
	var top: int = 0
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			top = maxi(top, HeightMask.level_at(heights, x, y))
	for storey: int in range(0, top + 1):
		for y2: int in range(-1, HeightMask.height(heights) + 1):
			for x2: int in range(-1, HeightMask.width(heights) + 1):
				if thin_at(heights, x2, y2, storey):
					return true
	return false


## Y A-T-IL UN PINCEMENT DIAGONAL ? Meme argument : on sort au premier.
static func any_pinch(heights: PackedStringArray) -> bool:
	var top: int = 0
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			top = maxi(top, HeightMask.level_at(heights, x, y))
	for storey: int in range(0, top + 1):
		for y2: int in range(-1, HeightMask.height(heights) + 1):
			for x2: int in range(-1, HeightMask.width(heights) + 1):
				if pinched_at(heights, x2, y2, storey):
					return true
	return false
