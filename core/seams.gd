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
# DEUX FAMILLES DE CONTRAINTES, ET ELLES SONT ASSERTEES PAR LA SUITE — DANS LES DEUX SENS.
#
#   VERTICALEMENT. Deux rangees qui se suivent dans une meme chute sont la meme face :
#   la derniere ligne de pixels de l'une EST la premiere de l'autre.
#
#   ⚠ ET LA CHAINE BOUCLE, CE QUI VA PLUS LOIN QU'IL N'Y PARAIT. Une chute de trois donne
#   « chapiteau, corps 0, pied » et une de six « chapiteau, corps 0, corps 1, corps 0,
#   corps 1, pied » : par transitivite, TOUS les raccords internes portent LE MEME profil.
#   Le haut et le bas d'une tuile de corps sont donc identiques -- ce qui est exactement ce
#   qu'on attend d'une tuile qui se repete verticalement.
#
#   HORIZONTALEMENT. Deux flancs `muet` face a face signifient la meme levre, donc la meme
#   face. La colonne droite de l'une EST la colonne gauche de l'autre.
#
# ⚠ ON FERME PRUDEMMENT, ET C'EST UNE DECISION. Deux formulations de ce fichier etaient
# FAUSSES, et le recensement des jonctions les a prises en flagrant delit
# (`tools/seam_census.gd`, qui assemble des reliefs au lieu de relire `row_for`) :
#
#   « la meme rangee » -- non : deux colonnes d'une meme levre peuvent avoir des chutes
#   differentes, l'une atterrissant sur une banquette pendant que l'autre continue. Un
#   `pied` se retrouve alors contre un `corps 1`.
#
#   « d'un meme pan » -- non : l'etat d'un flanc CHANGE en descendant, des que la robe
#   voisine s'arrete. Une colonne traverse plusieurs pans.
#
# Mesure avant correctif : le modele posait 70 jonctions verticales distinctes, `Seams` en
# connaissait 26 ; 39 muet/muet horizontales, il en connaissait 23. Et l'illustration
# cassait aux 60 jonctions inconnues, SANS EXCEPTION, jusqu'a 22 % d'ecart.
#
# On joint donc a TOUS les couples de pans et a TOUTES les rangees muettes, sans chercher
# lesquels sont realisables. Sur-joindre ne peut jamais rendre un tileset faux -- seulement
# plus contraint -- et le prix est mesure : 28 classes independantes au lieu des 29 que le
# monde autorise exactement. UNE classe sur vingt-neuf, contre une forme fermee a demontrer
# et a maintenir, c'est-a-dire un endroit de plus ou mentir. Le choix n'est pas serre.
#
# ⚠ ET DEUX REGLES DE DESSIN EN DECOULENT, qui rendent la fusion gratuite :
#   -- ce qui depend du PAN se tient a distance des bords HAUT et BAS (le pan change d'une
#      rangee a l'autre) ;
#   -- ce qui depend de la RANGEE se tient a distance des bords GAUCHE et DROIT (la colonne
#      voisine peut etre a une autre rangee).
# C'est la generalisation de l'assise, « tenue a distance des deux bords, donc incapable de
# se voir au raccord ».
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

## LE RETRAIT DES FLANCS NON MUETS -- ou la roche d'une tuile de falaise s'arrete.
##
## ⚠ CETTE CONSTANTE RENVERSE UNE DECISION DU DOSSIER, ET C'EST VOULU. Il y etait ecrit :
## « UNE CASE DE FALAISE EST UNE CASE DE ROCHE -- le vide se dit par l'ombre du bord, jamais
## en mangeant la roche. » Cette regle rendait la face RECTANGULAIRE : sa roche allait d'un
## bord a l'autre, quel que soit le flanc. Elle est incompatible avec un contour de falaise
## qui se trace -- un cadre vagabond -- puisqu'un tel contour s'arrete AVANT le bord des que
## le flanc n'est pas muet.
##
## ⚠ ET LE DEFAUT QUE CETTE DECISION SOIGNAIT NE REVIENT PAS, parce que le retrait est
## CONSTANT. Ce qui pulsait autrefois, c'etait deux largeurs differentes -- 0,10 pour le
## lisere, 0,055 pour l'arete -- qui se relayaient en cours de colonne. Ici la roche s'arrete
## au meme endroit pour `vide` et pour `devant` : seule la teinte les distingue, comme le
## dossier l'a deja tranche. La face ne change pas d'epaisseur en descendant.
##
## ⚠ POURQUOI C'EST NECESSAIRE, mesure : les classes VERTICALES joignent le bord haut d'une
## tuile a 35 autres bords, sur TOUTE sa largeur. Deux pans differents n'ont pas leur roche
## au meme endroit lateralement ; le modele les egalait quand meme, et la propagation ecrivait
## de la matiere dans le dehors du voisin. C'est le defaut des « tirets », signale case par
## case : remplir (6,10) tachait le transparent de (5,10) et toute la chute.
const FLANK_INSET: float = 0.16

static var _parent: Dictionary = {}
static var _corner_parent: Dictionary = {}


static func _static_init() -> void:
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			for side: int in range(4):
				_root(Vector3i(pan, row, side))

	# --- VERTICALEMENT : les enchainements de rangees, A TOUS LES COUPLES DE PANS.
	# ⚠ LE PAN D'UNE COLONNE CHANGE EN DESCENDANT. L'etat d'un flanc se lit de ce que la
	# robe voisine couvre A CETTE HAUTEUR : quand elle s'arrete, le flanc passe de `muet`
	# a `vide` en pleine paroi. Joindre a pan constant laissait donc 33 jonctions
	# verticales hors de toute classe, toutes en plein milieu d'une face.
	for pair: Vector2i in row_chains():
		for above: int in range(Walls.PAN_COUNT):
			for below: int in range(Walls.PAN_COUNT):
				_join(Vector3i(above, pair.x, BOTTOM), Vector3i(below, pair.y, TOP))

	# --- HORIZONTALEMENT : les flancs muets face a face, A TOUTES LES RANGEES.
	# ⚠ « MEME LEVRE DONC MEME RANGEE » ETAIT FAUX. Deux colonnes d'une meme levre peuvent
	# avoir des chutes DIFFERENTES -- l'une atterrit sur une banquette pendant que l'autre
	# continue -- et alors un `pied` se retrouve contre un `corps 1`, deux flancs muets a
	# deux rangees. Recense sur le guide livre : 16 couples, ecart 18 % dans l'illustration.
	for left_row: int in range(Walls.BLOCK_ROWS):
		for right_row: int in range(Walls.BLOCK_ROWS):
			for left: int in range(Walls.PAN_COUNT):
				if Walls.pan_east(left) != Walls.SIDE_MUTE:
					continue
				for right: int in range(Walls.PAN_COUNT):
					if Walls.pan_west(right) != Walls.SIDE_MUTE:
						continue
					_join(Vector3i(left, left_row, RIGHT), Vector3i(right, right_row, LEFT))

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


## Les couples de rangees que le modele pose l'une SUR l'autre, adossements compris.
##
## ⚠ ON LES LIT DE `row_for`, ON NE LES DEVINE PAS. Deviner depuis les noms de rangees
## fabriquerait des enchainements que la chute ne produit jamais -- et un test faux coute
## plus cher qu'un test absent : il envoie corriger ce qui va bien.
##
## ⚠ MAIS UNE CHUTE NE COMMENCE PAS AU PAS 1 ET NE FINIT PAS AU PAS `drop`. `assemble()`
## pose AUSSI le chapiteau sous sa levre (pas 0) et, sous la case qui l'arrete, le pied ou
## le corps du pas suivant (pas drop+1). N'iterer que 1..drop laissait « chapiteau sur
## chapiteau » et « pied sur pied » hors de TOUTE classe : le modele les posait, la
## propagation ne les ecrivait pas, la preuve ne les regardait pas. Recense sur le guide
## livre : 7 431 et 1 641 occurrences.
static func row_chains() -> Array[Vector2i]:
	var seen: Dictionary = {}
	var chains: Array[Vector2i] = []
	# ⚠ ET UNE CHUTE NE FAIT JAMAIS MOINS D'UN ETAGE, EN EPAIS. Celle qui atterrit est
	# un multiple de `STOREY_TILES` ; celle qui tombe dans le vide vaut au moins un
	# etage ; et celle qui s'ecrete laisse, entre la levre et la case qui la coupe, une
	# COURSE de cases sous le niveau de la levre -- que la barre de min trois oblige a
	# faire trois au moins. Iterer depuis 1 fabriquait une chute d'UNE case, laquelle
	# n'a meme pas de chapiteau (`row_for` n'en rend qu'a partir de `drop > 1`) et pose
	# un corps sur lui-meme : cet enchainement-la, que le monde ne produit pas, refermait
	# la chaine et faisait tomber la liberte de trois profils a deux. Une seule chute
	# degeneree valait une classe.
	#
	# ⚠ C'est une claim sur LE MONDE, pas sur la formule : elle est donc gardee par
	# `_test_seam_census`, qui recense les jonctions reellement posees et echoue si l'une
	# d'elles sort de ces chaines.
	for drop: int in range(Walls.STOREY_TILES, Walls.STOREY_TILES * 9 + 1):
		for landed: bool in [true, false]:
			# ⚠ ATTERRIR EST QUANTIFIE PAR TROIS ; DESCENDRE NE L'EST PAS. `fall_at` ne rend
			# une chute qui ATTERRIT que pour un multiple de `STOREY_TILES` -- c'est la
			# difference d'etage, en cases. Fabriquer un atterrissage de quatre ou de cinq
			# cases inventait des enchainements que le monde ne produit pas : le pied y
			# suivait tantot le corps 1, tantot le corps 2, alors qu'il suit TOUJOURS le
			# corps 0. Et ces faux enchainements refermaient la chaine : les trois profils
			# independants que trois rangees de corps achetent retombaient a UN SEUL.
			#
			# ⚠ C'est la faute exacte contre laquelle l'en-tete de cette fonction met en
			# garde -- deviner un enchainement plutot que le lire -- commise en croyant s'en
			# garder. Elle ne se voyait pas a deux rangees de corps : la chaine s'y refermait
			# de toute facon.
			if landed and drop % Walls.STOREY_TILES != 0:
				continue
			var rows: Array[int] = []
			# L'adossement sous la levre porte la rangee du PREMIER PAS.
			rows.append(Walls.row_for(1, drop, landed))
			for step: int in range(1, drop + 1):
				rows.append(Walls.row_for(step, drop, landed))
			# L'adossement sous la case qui l'arrete : le pied si la robe atterrit, le
			# corps qui continue si elle bute.
			rows.append(Walls.ROW_FOOT if landed
					else Walls.row_for(drop + 1, drop + 1, false))
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
		# ⚠ LE COIN AUSSI. Un pixel de coin est sur un bord haut ou bas, donc soumis a la
		# meme etendue de roche -- l'oublier laissait quatre ecritures dans le dehors du
		# voisin, exactement la ou le defaut se voyait.
		if CORNERS.has(here) and _corner_is_rock(role, corner, resolution):
			for other: Vector3i in CORNERS[here]:
				if _corner_is_rock(Vector2i(other.x, other.y), other.z, resolution):
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


## Un coin porte-t-il de la roche ? Il est sur un bord haut ou bas : meme etendue.
static func _corner_is_rock(role: Vector2i, corner: int, resolution: int) -> bool:
	var last: int = resolution - 1
	match corner:
		TOP_LEFT:
			return is_rock(role, TOP, 0, resolution)
		TOP_RIGHT:
			return is_rock(role, TOP, last, resolution)
		BOTTOM_RIGHT:
			return is_rock(role, BOTTOM, last, resolution)
	return is_rock(role, BOTTOM, 0, resolution)


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
## OU CE BORD PORTE DE LA ROCHE : les positions [premiere, derniere], incluses.
##
## Un bord HAUT ou BAS court sur les colonnes : sa roche s'arrete au retrait de chaque flanc
## non muet. Un bord GAUCHE ou DROIT court sur les rangees : rien ne l'entame -- une face va
## du haut au bas de sa case, c'est la chute qui la borne, pas le dessin.
static func rock_span(role: Vector2i, side: int, resolution: int) -> Vector2i:
	var last: int = resolution - 1
	if side == LEFT or side == RIGHT:
		return Vector2i(0, last)
	# ⚠ SEUL `vide` RETIRE LA ROCHE. Le dossier le dit en trois etats : `muet`, c'est la meme
	# face ou un voisin en avant -- de la roche ; `devant`, c'est de la roche EN RETRAIT, et
	# je porte l'angle -- de la roche encore ; `vide` seul veut dire qu'il n'y a rien. Mettre
	# `devant` au retrait aurait ouvert un trou la ou deux parois se touchent.
	var inset: int = int(round(FLANK_INSET * float(resolution)))
	var first: int = inset if Walls.pan_west(role.x) == Walls.SIDE_VOID else 0
	var stop: int = last - inset if Walls.pan_east(role.x) == Walls.SIDE_VOID else last
	return Vector2i(first, stop)


## Ce bord porte-t-il de la roche a cette position ?
static func is_rock(role: Vector2i, side: int, position: int, resolution: int) -> bool:
	var span: Vector2i = rock_span(role, side, resolution)
	return position >= span.x and position <= span.y


static func _spread(into: Array[Vector4i], role: Vector2i, side: int, position: int,
		last: int) -> void:
	var here: Vector3i = Vector3i(role.x, role.y, side)
	if not GROUPS.has(here):
		return
	# ⚠ ON NE PROPAGE QUE LA OU LES DEUX TUILES ONT DE LA ROCHE. Une classe dit « ces deux
	# bords sont la meme paroi » ; elle ne dit pas que la paroi occupe toute la largeur. La
	# joindre bout a bout ecrivait de la matiere dans le dehors du voisin.
	if not is_rock(role, side, position, last + 1):
		return
	for other: Vector3i in GROUPS[here]:
		if not is_rock(Vector2i(other.x, other.y), other.z, position, last + 1):
			continue
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
