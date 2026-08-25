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
	# ⚠ ET CHAQUE SILHOUETTE SE DECLINE SELON SON BORD -- MAIS PAS TOUJOURS DES DEUX
	# FACONS, ET C'EST UN THEOREME. Un cardinal vide borde soit de la ROCHE -- la face d'une
	# falaise voisine, dont le sommet est au niveau de mon sol, donc aucune marche -- soit du
	# NU, et ca tombe. Reste a savoir lesquelles des deux sont REALISABLES.
	#
	# ⚠ LE SUD N'EN EST PAS : une case au sud vide est une levre, sa propre face couvre la
	# case d'en dessous, TOUJOURS. C'est ce qui rend l'epaule peignable la ou aucun autre bord
	# ne le serait.
	#
	# ⚠ LE NORD EST LIBRE DES DEUX COTES. Pour couvrir ma voisine du nord il faut une levre
	# quatre rangees plus haut -- trois rangees de creux, sinon c'est fin -- et ces rangees-la
	# sont HORS de la fenetre 3x3 : l'exterieur est libre, on y met ce qu'on veut.
	#
	# ⚠ L'EST ET L'OUEST, NON. La levre qui couvre ma voisine de l'est est soit le coin NE
	# -- dans la fenetre -- soit une levre plus haut, ce qui exige que la colonne soit vide
	# sur trois rangees, donc que NE **et** SE soient vides. Et la realisabilite peut FORCER
	# le coin : pour la silhouette 5 (nord et est pleins, sud et ouest vides), le coin NE est
	# significatif et nul, donc la condition « une cardinale pleine a un coin adjacent plein »
	# oblige NO a etre plein -- donc une levre a l'ouest, donc de la ROCHE, sans alternative.
	# `5 [O=nu]` n'existe pas, et la planche ne pourrait jamais la montrer.
	var tiles: Array = []
	for index: int in sorted_indices:
		var choices: Array = [[0]]
		for side: int in range(BlobIndex.BRINK_BITS.size()):
			var bit: int = BlobIndex.BRINK_BITS[side]
			if (int(index) & BlobIndex.BRINK_CARDINALS[side]) != 0:
				continue  # ce cardinal est plein : pas de bord
			# ⚠ LA ROCHE EST TOUJOURS POSSIBLE, ET C'EST LE NU QUI SE REFUSE. Pour couvrir ma
			# voisine, la levre est soit LE COIN lui-meme -- juste au-dessus d'elle -- soit une
			# levre TROIS rangees plus haut, le creux entre les deux faisant exactement les
			# trois cases qu'exige l'epaisseur. Ce second cas ne demande rien a la fenetre :
			# les rangees en question sont dehors, et l'exterieur est libre.
			#
			# ⚠ LE NU, LUI, EXIGE QUE LE COIN PUISSE ETRE VIDE. S'il est plein, il fait levre,
			# donc de la roche, sans alternative -- et la realisabilite peut le FORCER : pour
			# la silhouette 5, le coin NE est significatif et nul, donc « une cardinale pleine
			# a un coin adjacent plein » oblige NO a etre plein. `5 [ouest=nu]` n'existe pas.
			var can_rock: bool = true
			var can_bare: bool = bit == BlobIndex.BRINK_N
			if not can_bare:
				var corner: int = BlobIndex.NE if bit == BlobIndex.BRINK_E else BlobIndex.NW
				for raw: int in range(256):
					if BlobIndex.canonicalize(raw) != int(index):
						continue
					if not window_realizable(raw):
						continue
					if (raw & corner) == 0:
						can_bare = true
						break
			var grown: Array = []
			for edge: Variant in choices:
				if can_bare:
					grown.append(int((edge as Array)[0]))
				if can_rock:
					grown.append(int((edge as Array)[0]) | bit)
			var wrapped: Array = []
			for value: Variant in grown:
				wrapped.append([int(value)])
			choices = wrapped
		for edge: Variant in choices:
			tiles.append(BlobIndex.compose(int(index), int((edge as Array)[0])))
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
	# ⚠ `(devant,devant)` EST RESSUSCITE PAR LES LEVRES GLOBALES, et l'argument qui le
	# tuait ne valait que pour un eperon d'UNE colonne AU MEME ETAGE. Entre etages, deux
	# faces dont les levres sont plus au nord de part et d'autre, c'est banal : je suis
	# devant les deux, et je porte mes deux angles. Min trois n'y peut rien.
	#
	# Il ne meurt qu'au PIED, ou la battue ne le rencontre jamais -- partie CHERCHEE de la
	# forme, gardee par la battue continue de la suite : si un 45e role apparait un jour,
	# elle echoue et la forme se corrige.
	return not (Walls.pan_west(role.x) == Walls.SIDE_FRONT
			and Walls.pan_east(role.x) == Walls.SIDE_FRONT
			and role.y == Walls.ROW_FOOT)


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
