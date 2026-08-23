# LA REGLE DE POSE — la meme que celle du logiciel, rejouee chez l'acheteur.
#
# Ce fichier est le portage EXACT de `core/blob_index.gd`, `core/coverage.gd`,
# `core/corner_index.gd` et `core/walls.gd`. Il ne depend de rien : ni du logiciel, ni d'un
# noeud, ni d'une scene. On peut le lire en headless, et c'est ce que fait la suite de
# tests.
#
# ⚠ POURQUOI UNE COPIE, ALORS QUE DEUX COPIES D'UNE REGLE FINISSENT TOUJOURS PAR DIVERGER.
# Parce qu'il n'y a pas le choix : le plugin part chez l'acheteur, dans SON projet, ou
# `res://core/` n'existe pas. La question n'est donc pas « comment eviter la copie » mais
# « comment prouver que les deux disent la meme chose ». La reponse est dans
# `tests/run.gd` : sur des milliers de reliefs tires au sort, chaque case doit recevoir du
# plugin exactement ce que le noyau lui donne -- meme index de surface, meme croisement,
# meme role de robe. Une divergence d'une seule case fait echouer la suite (charte,
# regle 4 : l'exactitude se prouve, elle ne se promet pas).
#
# ⚠ ET LE MONDE N'EST PAS BORNE ICI. Le logiciel travaille sur un guide rectangulaire, ou
# une robe peut « tomber hors de la grille » ; un monde de jeu n'a pas de bord. Le relief
# est donc un dictionnaire case -> etage, l'absence valant la plaine. Consequence heureuse :
# le cas « robe hors grille » n'existe pas, il n'y a rien a signaler.
extends RefCounted

# --- LA SURFACE PAR CASE : le blob 47 ---------------------------------------

## Bits de voisinage, dans le sens horaire depuis le nord.
const N: int = 1
const NE: int = 2
const E: int = 4
const SE: int = 8
const S: int = 16
const SW: int = 32
const W: int = 64
const NW: int = 128

const CARDINALS: int = N | E | S | W

const BITS: Array[int] = [N, NE, E, SE, S, SW, W, NW]

## Decalages (dx, dy) associes aux bits. x croit vers l'est, y croit vers le sud.
const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
]

# --- LA SURFACE A CHEVAL : le reseau dual ------------------------------------

## Bits du croisement, dans le sens horaire depuis le nord-ouest.
const C_NW: int = 1
const C_NE: int = 2
const C_SE: int = 4
const C_SW: int = 8

const CORNER_BITS: Array[int] = [C_NW, C_NE, C_SE, C_SW]

## Decalages (dx, dy) de la case portee par chaque bit, depuis le croisement.
## Un croisement (i, j) touche les cases (i-1, j-1), (i, j-1), (i, j) et (i-1, j).
const CORNER_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(0, 0),
	Vector2i(-1, 0),
]

# --- LES FALAISES ------------------------------------------------------------

## Les trois etats d'un flanc.
const SIDE_VOID: int = 0   ## Ma roche s'arrete : rien a cote.
const SIDE_MUTE: int = 1   ## Meme face, ou voisin DEVANT moi -- rien a tracer de ce cote.
const SIDE_FRONT: int = 2  ## Voisin en retrait : je suis devant, je porte l'angle.
const SIDE_COUNT: int = 3

## Le pan est le couple (ouest, est).
const PAN_COUNT: int = SIDE_COUNT * SIDE_COUNT

const ROW_CROWN: int = 0
const BODY_ROWS: int = 2
const ROW_FOOT: int = 1 + BODY_ROWS
const BLOCK_ROWS: int = ROW_FOOT + 1

## De combien de cases de mur descend un etage.
const STOREY_TILES: int = 3

## Rendu quand une case ne porte aucune tuile.
const NO_INDEX: int = -1

## Le hors-monde. Ni un etage, ni une tuile : rien.
const VOID: int = -1


# --- LE RELIEF ---------------------------------------------------------------

## L'etage d'une case. Tout ce qui n'est PAS au relief est du VIDE, pas de la plaine.
##
## ⚠ C'EST L'INVERSION QUI DONNE SON SOL AU MONDE. Tant qu'une case absente valait la
## plaine, le relief s'etendait a l'infini et le plugin ne pouvait pas dire ou le sol
## s'arrete : il ne posait donc aucun etage 0. Une case presente a l'etage 0 est de la
## plaine, une case absente n'est rien. La plaine devient alors un plateau comme les
## autres : ses 47 index, et ses falaises la ou elle borde le vide.
static func level_at(heights: Dictionary, cell: Vector2i) -> int:
	return int(heights.get(cell, VOID))


## L'etage le plus haut du relief.
static func top_level(heights: Dictionary) -> int:
	var top: int = 0
	for cell: Vector2i in heights.keys():
		top = maxi(top, int(heights[cell]))
	return top


# --- LA SURFACE ---------------------------------------------------------------

## Reduit un voisinage brut (0..255) a son index canonique.
##
## ⚠ UN BIT DE COIN N'EST CONSERVE QUE SI LES DEUX CARDINAUX QUI L'ENCADRENT SONT PLEINS.
## Un coin diagonal isole ne change pas la silhouette de la tuile : il ne doit donc pas
## produire une tuile de plus. Les 256 voisinages bruts se reduisent a exactement 47 index.
static func canonicalise(raw: int) -> int:
	var canonical: int = raw & CARDINALS
	if (raw & NE) != 0 and (canonical & N) != 0 and (canonical & E) != 0:
		canonical |= NE
	if (raw & SE) != 0 and (canonical & S) != 0 and (canonical & E) != 0:
		canonical |= SE
	if (raw & SW) != 0 and (canonical & S) != 0 and (canonical & W) != 0:
		canonical |= SW
	if (raw & NW) != 0 and (canonical & N) != 0 and (canonical & W) != 0:
		canonical |= NW
	return canonical


## L'index d'une case dans la silhouette d'un etage donne.
## La silhouette de l'etage L est l'ensemble des cases d'etage >= L : un masque BINAIRE.
static func blob_index_at_level(heights: Dictionary, cell: Vector2i, level: int) -> int:
	if level_at(heights, cell) < level:
		return NO_INDEX
	var raw: int = 0
	for bit: int in range(BITS.size()):
		if level_at(heights, cell + OFFSETS[bit]) >= level:
			raw |= BITS[bit]
	return canonicalise(raw)


## L'index de la surface VISIBLE d'une case, ou NO_INDEX si elle est a la plaine.
##
## ⚠ ON NE VOIT QUE LE SOMMET. La tuile qu'une case porte est celle de SON etage, jamais de
## l'union des etages : vue de dessus, une case sous un plateau plus haut est masquee.
static func surface_index_at(heights: Dictionary, cell: Vector2i) -> int:
	var level: int = level_at(heights, cell)
	if level < 0:
		return NO_INDEX
	return blob_index_at_level(heights, cell, level)


## L'index VISIBLE d'un croisement, ou NO_INDEX s'il ne dessine rien.
##
## ⚠ LE CROISEMENT ENTIEREMENT VIDE N'EST PAS UNE TUILE, exactement comme la plaine n'est
## pas une tuile du blob. Le reseau dual livre donc quinze tuiles, pas seize.
static func corner_index_at(heights: Dictionary, crossing: Vector2i) -> int:
	var top: int = 0
	for bit: int in range(CORNER_BITS.size()):
		top = maxi(top, level_at(heights, crossing + CORNER_OFFSETS[bit]))
	if top == 0:
		return NO_INDEX
	var code: int = 0
	for bit: int in range(CORNER_BITS.size()):
		if level_at(heights, crossing + CORNER_OFFSETS[bit]) >= top:
			code |= CORNER_BITS[bit]
	return code if code != 0 else NO_INDEX


## Toutes les surfaces visibles du relief : case -> index blob.
static func surfaces(heights: Dictionary) -> Dictionary:
	var found: Dictionary = {}
	for cell: Vector2i in heights.keys():
		var index: int = surface_index_at(heights, cell)
		if index != NO_INDEX:
			found[cell] = index
	return found


## LES SURFACES D'UN ETAGE DONNE, dans une zone : case -> index.
##
## ⚠ CE N'EST PAS « LA TUILE VISIBLE », ET C'EST TOUT LE POINT. Une case a l'etage 2
## appartient AUSSI a la silhouette de l'etage 1 et a celle de l'etage 0 : les etages
## s'empilent, l'etage N-1 continue SOUS le plateau de l'etage N. Ne poser que la tuile
## visible laisse le coin decoupe d'un plateau ouvert sur RIEN -- un angle noir en haut de
## chaque plateau, la ou il devrait montrer l'etage d'en dessous.
##
## C'est deja ce que dit la regle de pose : « on dessine du bas vers le haut, chaque couche
## recouvrant la precedente ». L'illustration le faisait, le plugin non : l'epaule bouchait
## le trou au sud, et au nord il n'y avait rien pour le boucher.
static func surfaces_at_level(heights: Dictionary, level: int, region: Rect2i) -> Dictionary:
	var found: Dictionary = {}
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if not heights.has(cell) or level_at(heights, cell) < level:
				continue
			var index: int = blob_index_at_level(heights, cell, level)
			if index != NO_INDEX:
				found[cell] = index
	return found


## Tous les croisements qui dessinent quelque chose : croisement -> index dual.
##
## Un croisement ne compte que s'il touche au moins une case du relief ; on part donc des
## cases, jamais d'un rectangle a balayer -- le monde n'a pas de bord.
static func corners(heights: Dictionary) -> Dictionary:
	var seen: Dictionary = {}
	var found: Dictionary = {}
	for cell: Vector2i in heights.keys():
		if int(heights[cell]) < 1:
			continue
		for corner: Vector2i in [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1),
				cell + Vector2i(1, 1)]:
			if seen.has(corner):
				continue
			seen[corner] = true
			var index: int = corner_index_at(heights, corner)
			if index != NO_INDEX:
				found[corner] = index
	return found


# --- LES FALAISES ---------------------------------------------------------------

## La rangee employee a la marche [param step] d'une chute de [param drop] cases.
##
## ⚠ LE CORPS TOURNE SUR LUI-MEME, et on compte depuis la premiere case de corps pour que
## deux robes de hauteurs differentes, cote a cote, presentent la meme case en haut.
static func row_for(step: int, drop: int, landed: bool) -> int:
	if landed and step == drop:
		return ROW_FOOT
	if step == 1 and drop > 1:
		return ROW_CROWN
	return 1 + maxi(0, step - 2) % BODY_ROWS


## Le pan forme par ses deux flancs.
static func pan_of(west: int, east: int) -> int:
	return west * SIDE_COUNT + east


## La chute sous une levre : Vector2i(nombre de cases, 1 si elle atterrit).
##
## ⚠ ON SONDE LA CASE JUSTE SOUS LE PIED, jamais celles que la robe traverse. Les etages
## partagent la grille : l'etage N-1 continue SOUS la robe de l'etage N. Sonder au fil de
## la descente repondrait « touche » des la premiere case, et toutes les falaises feraient
## une case de haut.
static func fall_at(heights: Dictionary, level: int, cell: Vector2i) -> Vector2i:
	# ⚠ QUAND RIEN N'EST DESSOUS, LA ROBE NE S'ARRETE PAS A L'ETAGE 0 : elle tombe d'un
	# etage de plus, dans le vide, et ne pose pas son pied. C'est la falaise du bord du
	# monde -- celle qui borde le vide -- et c'est aussi celle de la plaine elle-meme, dont
	# aucun etage ne peut la recevoir.
	var drop: int = STOREY_TILES * (level + 1)
	var landed: bool = false
	for below: int in range(level - 1, -1, -1):
		var candidate: int = STOREY_TILES * (level - below)
		if level_at(heights, Vector2i(cell.x, cell.y + candidate + 1)) >= below:
			drop = candidate
			landed = true
			break
	return _trim(heights, level, cell, drop, landed)


## Raccourcit une robe qui rencontrerait le sol de SON PROPRE etage.
##
## ⚠ UNE ROBE RACCOURCIE NE POSE PAS SON PIED : elle ne touche pas le sol d'en bas, elle
## bute contre un voisin de son niveau. Le pied dessine une base qui repose ; la, le dessin
## doit simplement se taire.
static func _trim(heights: Dictionary, level: int, cell: Vector2i, drop: int,
		landed: bool) -> Vector2i:
	for step: int in range(1, drop + 1):
		if level_at(heights, Vector2i(cell.x, cell.y + step)) >= level:
			return Vector2i(step - 1, 0)
	if level_at(heights, Vector2i(cell.x, cell.y + drop + 1)) >= level:
		return Vector2i(drop, 0)
	return Vector2i(drop, 1 if landed else 0)


## L'etat d'un flanc.
##
## ⚠ L'ARETE APPARTIENT A CELUI QUI EST DEVANT. Une levre plus au NORD est une face en
## RETRAIT : c'est moi qui avance, donc c'est moi qui porte l'angle. Une levre plus au sud
## est une face devant moi : elle portera le sien, je me tais. Sans cette dissymetrie, deux
## aretes se dessineraient au meme endroit et rien ne dirait laquelle est proche.
static func _side(heights: Dictionary, lip_of: Dictionary, at: Vector2i, level: int,
		step: int, my_lip: int) -> int:
	if lip_of.has(at):
		return SIDE_FRONT if int(lip_of[at]) < my_lip else SIDE_MUTE
	# Le sommet d'un plateau a cote : sa propre face tombe plus au sud, donc il est devant
	# moi -- c'est a lui de tracer, pas a moi.
	if level_at(heights, at) >= level:
		return SIDE_MUTE
	# ⚠ L'ETAGE QU'ON BORDE COMPTE A TOUTES LES RANGEES, pas seulement au premier cran :
	# c'est l'angle rentrant, deux morceaux du meme plateau separes d'un creux.
	# ⚠ ET ON NE SONDE JAMAIS L'ETAGE 0 : toute case est a la plaine ou au-dessus, le
	# tester rendrait « haut » partout et tous les flancs seraient muets.
	var span: int = (maxi(1, step) - 1) / STOREY_TILES
	var beside: int = level - span
	if beside >= 1 and level_at(heights, at) >= beside:
		return SIDE_MUTE
	return SIDE_VOID


## Le pan d'une case de robe : l'etat de son flanc ouest et celui de son flanc est.
##
## ⚠ LE PAN SE CHOISIT PAR RANGEE, JAMAIS PAR COLONNE. Quand ma voisine de gauche tombe de
## trois cases et moi de six, alors sous son pied je n'ai plus de voisine haute a gauche :
## je suis devenue un bord, et je montre mon flanc. Evalue une fois pour toute la colonne,
## le vocabulaire coudrait deux robes de hauteurs differentes bord a bord.
static func pan_at(heights: Dictionary, level: int, lip_of: Dictionary, at: Vector2i,
		step: int, my_lip: int) -> int:
	return pan_of(_side(heights, lip_of, at + Vector2i.LEFT, level, step, my_lip),
			_side(heights, lip_of, at + Vector2i.RIGHT, level, step, my_lip))


## Deroule toutes les robes du relief : Vector3i(x, y, etage) -> Vector2i(pan, rangee).
##
## La cle porte l'etage : deux robes d'etages differents peuvent se superposer sur la meme
## case, la plus haute masquant l'autre, exactement comme deux calques.
## ⚠ ET LE SOUS-PIED, QUI NE COUTE AUCUNE TUILE. Une case d'atterrissage a ses coins nord
## DECOUPES -- son voisin du nord est plus bas, c'est la face de la falaise -- et par ces
## coins on voyait le sol au lieu de la roche qui continue derriere. On redessine donc le
## PIED une case plus bas, SOUS la surface : elle le recouvre entierement sauf par ses
## coins, et c'est exactement la qu'il manquait.
##
## ⚠ ET LA MEME POSE DERRIERE UNE CASE QUI ECRETE : une robe coupee par une case de son
## propre etage passe derriere elle, et repose sous cette case la rangee du pas suivant,
## un corps. Le pied si la robe atterrit, le corps qui continue si elle bute.
##
## ⚠ IL SORT A PART, PAS DANS `roles`. La case d'atterrissage est deja une case de SURFACE :
## la declarer case de robe la rendrait peignable deux fois, et l'editeur ne saurait plus
## quelle tuile elle porte. Le sous-pied n'est pas une tuile de plus, c'est une POSE de
## plus.
static func assemble_walls(heights: Dictionary) -> Dictionary:
	var roles: Dictionary = {}
	var underfoot: Dictionary = {}
	# ⚠ ON PART DE L'ETAGE 0, PAS DE 1. La plaine est un plateau comme les autres : la ou
	# elle borde le vide, elle a une levre et donc une falaise. C'est le bord du monde.
	for level: int in range(0, top_level(heights) + 1):
		# PREMIERE PASSE -- la geometrie seule. Le pan d'une rangee depend de ce que les
		# robes VOISINES couvrent a cette hauteur-la : en posant au fil de l'eau, on ne
		# connaitrait que la moitie gauche.
		var drops: Dictionary = {}
		var lip_of: Dictionary = {}
		for cell: Vector2i in heights.keys():
			if int(heights[cell]) < level:
				continue
			if level_at(heights, Vector2i(cell.x, cell.y + 1)) >= level:
				continue  # ce bord-la est interieur : rien a montrer
			var fall: Vector2i = fall_at(heights, level, cell)
			drops[cell] = fall
			for step: int in range(1, fall.x + 1):
				lip_of[Vector2i(cell.x, cell.y + step)] = cell.y
		# SECONDE PASSE -- la pose.
		for cell: Vector2i in drops.keys():
			var fall: Vector2i = drops[cell]
			var drop: int = fall.x
			if drop <= 0:
				continue  # raccourcie a neant : un voisin du meme etage occupe deja la case
			var landed: bool = fall.y == 1
			var last_pan: int = 0
			for step: int in range(1, drop + 1):
				var at: Vector2i = Vector2i(cell.x, cell.y + step)
				last_pan = pan_at(heights, level, lip_of, at, step, cell.y)
				roles[Vector3i(at.x, at.y, level)] = Vector2i(
						last_pan, row_for(step, drop, landed))
			# ⚠ LE SOUS-PIED REPREND LE PAN DU PIED : c'est la MEME face, une case plus bas.
			var next_cell: Vector2i = Vector2i(cell.x, cell.y + drop + 1)
			if landed:
				underfoot[Vector3i(next_cell.x, next_cell.y, level)] = Vector2i(
						last_pan, ROW_FOOT)
			elif level_at(heights, next_cell) == level:
				# ⚠ LA POSE DERRIERE : une robe ecretee passe DERRIERE la case de son etage
				# qui l'a coupee. On repose sous elle la rangee du pas suivant -- toujours
				# un corps, jamais un pied ni un chapiteau -- avec le pan de la derniere
				# rangee posee. Seulement si la case est EXACTEMENT de l'etage de la levre :
				# plus haute, son sommet depasse la face, et l'empilement montre deja
				# l'etage d'en dessous.
				underfoot[Vector3i(next_cell.x, next_cell.y, level)] = Vector2i(
						last_pan, row_for(drop + 1, drop + 1, false))
	return {"roles": roles, "underfoot": underfoot}


## LA ZONE QUE DES CASES CHANGEES PEUVENT AVOIR RENDUE FAUSSE.
##
## Refaire toute la carte a chaque coup de crayon est juste et intenable : mesure, 7 ms sur
## 32x24 mais 456 ms sur 256x192 -- et c'est PAR CASE PEINTE. Refaire trop peu est pire :
## le monde devient faux pendant qu'on le dessine, et rien ne le signale.
##
## ⚠ LA PORTEE SE DEDUIT DU MODELE, ELLE NE SE DEVINE PAS. Trois raisons, chacune donnant
## sa marge :
##
##   - l'index d'une case ne depend que de sa fenetre 3x3, et un croisement ne touche que
##     quatre cases : DEUX cases suffisent de tous les cotes ;
##   - une levre plus HAUT peut tomber a travers la case changee, et sa chute vaut au plus
##     `STOREY_TILES x (etage le plus haut + 1)` ; changer la case peut donc rallonger ou
##     raccourcir cette chute-la, qui commence bien au-dessus ;
##   - et vers le BAS, la case changee peut elle-meme devenir une levre, avec sa chute
##     entiere, plus la case de sous-pied qui la suit.
##
## ⚠ LE PAN D'UNE COLONNE SE COMPARE A CELUI DE SA VOISINE, d'ou les deux colonnes de
## marge : changer une colonne change le pan de celles d'a cote, jamais plus loin -- un pan
## ne modifie aucune levre, donc la cascade s'arrete la.##
## ⚠ `top` SE PASSE PLUTOT QUE DE SE RELIRE. `top_level` parcourt TOUT le dictionnaire :
## c'etait la derniere lecture proportionnelle a la carte, et elle suffisait a faire
## remonter le cout de 1,4 a 9,8 millisecondes entre 32x24 et 256x192 alors que la zone,
## elle, ne bougeait pas d'une case. Un -1 le fait relire.
##
## ⚠ ET UN `top` TROP GRAND N'EST JAMAIS FAUX, seulement un peu lent : la zone est plus
## large que necessaire, donc elle contient toujours ce qu'il fallait refaire. C'est la
## bonne direction pour une approximation -- l'inverse laisserait le monde faux.
static func region_of(heights: Dictionary, cells: Array, top: int = -1) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var low: Vector2i = cells[0]
	var high: Vector2i = cells[0]
	for cell: Vector2i in cells:
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	var reach: int = STOREY_TILES * ((top_level(heights) if top < 0 else top) + 1)
	var from: Vector2i = Vector2i(low.x - 2, low.y - reach - 2)
	var to: Vector2i = Vector2i(high.x + 2, high.y + reach + 3)
	return Rect2i(from, to - from + Vector2i.ONE)


## Les surfaces d'une zone, memes regles que partout.
static func surfaces_in(heights: Dictionary, region: Rect2i) -> Dictionary:
	# ⚠ ON PARCOURT LA ZONE, PAS LE DICTIONNAIRE. Filtrer les cases du monde une par une
	# reste proportionnel a la CARTE : la zone avait beau etre bornee, la recherche ne l'etait
	# pas, et 256x192 coutait encore dix-sept millisecondes la ou trente-deux sur vingt-quatre
	# en coutaient une et demie. Une borne qu'on franchit a la lecture n'est pas une borne.
	var visible: Dictionary = {}
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if not heights.has(cell):
				continue
			var index: int = surface_index_at(heights, cell)
			if index != NO_INDEX:
				visible[cell] = index
	return visible


## Les croisements d'une zone.
static func corners_in(heights: Dictionary, region: Rect2i) -> Dictionary:
	var visible: Dictionary = {}
	var narrow: Dictionary = {}
	var scan: Rect2i = Rect2i(region.position - Vector2i.ONE, region.size + Vector2i(2, 2))
	for y: int in range(scan.position.y, scan.end.y):
		for x: int in range(scan.position.x, scan.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if heights.has(cell):
				narrow[cell] = heights[cell]
	for crossing: Vector2i in corners(narrow).keys():
		if region.has_point(crossing):
			visible[crossing] = corners(narrow)[crossing]
	return visible


## Les robes et les sous-pieds d'une zone.
##
## ⚠ ON RAMASSE LES LEVRES PLUS LARGE QU'ON NE POSE. Le pan d'une case se lit de ce que
## les robes VOISINES couvrent a cette hauteur-la : en ne regardant que la zone, les
## colonnes du bord auraient un pan faux. On assemble donc sur une zone elargie, et on ne
## garde que le dedans.
static func walls_in(heights: Dictionary, region: Rect2i, top: int = -1) -> Dictionary:
	var reach: int = STOREY_TILES * ((top_level(heights) if top < 0 else top) + 1)
	var scan: Rect2i = Rect2i(region.position - Vector2i(2, reach + 2),
			region.size + Vector2i(4, 2 * reach + 4))
	var narrow: Dictionary = {}
	for y: int in range(scan.position.y, scan.end.y):
		for x: int in range(scan.position.x, scan.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if heights.has(cell):
				narrow[cell] = heights[cell]
	var assembled: Dictionary = assemble_walls(narrow)
	return {
		"roles": _keep_inside(_highest(assembled["roles"]), region),
		"underfoot": _keep_inside(_highest(assembled["underfoot"]), region),
	}


static func _highest(by_level: Dictionary) -> Dictionary:
	var highest: Dictionary = {}
	var chosen: Dictionary = {}
	for key: Vector3i in by_level.keys():
		var cell: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(cell) or key.z > int(highest[cell]):
			highest[cell] = key.z
			chosen[cell] = by_level[key]
	return chosen


static func _keep_inside(cells: Dictionary, region: Rect2i) -> Dictionary:
	var kept: Dictionary = {}
	for cell: Vector2i in cells.keys():
		if region.has_point(cell):
			kept[cell] = cells[cell]
	return kept


## Le role VISIBLE de chaque case de robe : celui de l'etage le plus haut qui l'occupe.
static func walls(heights: Dictionary) -> Dictionary:
	var roles: Dictionary = assemble_walls(heights)["roles"]
	var highest: Dictionary = {}
	var visible: Dictionary = {}
	for key: Vector3i in roles.keys():
		var cell: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(cell) or key.z > int(highest[cell]):
			highest[cell] = key.z
			visible[cell] = roles[key]
	return visible


## La POSE DERRIERE visible : le pied sous une case d'atterrissage, le corps sous une
## case qui ecrete. Celle de l'etage le plus haut.
## ⚠ ELLE SE POSE AVANT LA SURFACE QUI LA RECOUVRE. La case ne la laisse voir que par
## ses coins decoupes -- c'est exactement la qu'elle doit se voir.
static func underfoot(heights: Dictionary) -> Dictionary:
	var under: Dictionary = assemble_walls(heights)["underfoot"]
	var highest: Dictionary = {}
	var visible: Dictionary = {}
	for key: Vector3i in under.keys():
		var cell: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(cell) or key.z > int(highest[cell]):
			highest[cell] = key.z
			visible[cell] = under[key]
	return visible
