# LES MURS — le second vocabulaire, celui qui sort du plan.
#
# Un terrain Wang resout les coins d'un PLAN : c'est le blob 47, la surface des plateaux.
# Une falaise sort de ce plan. Sa face occupe des cases qui, vues de dessus, appartiennent
# au sol d'en bas, et aucun systeme de terrain ne peut la poser. Son vocabulaire n'a donc
# rien a voir avec celui de la surface : ni coins, ni transitions. Trois pans et une
# descente verticale, c'est tout.
#
#        pan GAUCHE   pan COURANT   pan DROIT
#      ┌────────────┬────────────┬────────────┐
#      │  CHAPITEAU │  CHAPITEAU │  CHAPITEAU │  la premiere case sous la levre
#      ├────────────┼────────────┼────────────┤
#      │   corps 0  │   corps 0  │   corps 0  │  ┐ repetes autant de fois
#      ├────────────┼────────────┼────────────┤  ┘ que la chute l'exige
#      │   corps 1  │   corps 1  │   corps 1  │
#      ├────────────┼────────────┼────────────┤
#      │    PIED    │    PIED    │    PIED    │  la case qui touche le sol d'en bas
#      └────────────┴────────────┴────────────┘
#
# ⚠ DEUX RANGEES DE CORPS, PAS UNE. Avec une seule, une chute de six cases montre quatre
# fois la meme case l'une sur l'autre et l'oeil lit la repetition avant de lire la falaise.
# Avec deux, la periode double et la repetition passe sous le seuil. C'est ce qui permet
# une hauteur N quelconque avec une feuille finie.
#
# ⚠ UN PLATEAU N'A DE FACE QU'AU SUD. Les trois autres cotes ne montrent rien : on voit son
# dessus, puis le sol d'en dessous, sans transition.
#
# ⚠ LA HAUTEUR SE DEDUIT, ELLE NE SE DECLARE PAS. Sous une levre de l'etage N on cherche
# l'etage le plus haut qu'on atteigne vraiment, et la chute vaut STOREY_TILES x (N - M).
#
# Modele repris de Satyron, ou il a ete etabli empiriquement puis eprouve sur une vraie
# carte. Ce fichier le rejoue sur un relief, sans dependance a un TileSet ni a un noeud.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")

## Les trois pans, en colonnes du bloc.
const PAN_LEFT: int = 0    ## Rien de haut a l'ouest : la falaise commence ici.
const PAN_MIDDLE: int = 1  ## Le pan courant, celui qui se repete.
const PAN_RIGHT: int = 2   ## Rien de haut a l'est.
const PAN_COUNT: int = 3

## Les rangees du bloc.
const ROW_CROWN: int = 0
const BODY_ROWS: int = 2
const ROW_FOOT: int = 1 + BODY_ROWS
const BLOCK_ROWS: int = ROW_FOOT + 1

## De combien de cases de mur descend un etage.
const STOREY_TILES: int = 3

const PAN_NAMES: Array[String] = ["gauche", "courant", "droit"]
const ROW_NAMES: Array[String] = ["chapiteau", "corps 0", "corps 1", "pied"]

## Les 12 roles (pan, rangee) qu'un guide doit faire apparaitre.
## Calcules au chargement, jamais ecrits en dur.
static var ALL_ROLES: Array[Vector2i] = []

static func _static_init() -> void:
	for pan: int in range(PAN_COUNT):
		for row: int in range(BLOCK_ROWS):
			ALL_ROLES.append(Vector2i(pan, row))


static func role_name(role: Vector2i) -> String:
	return "%s / %s" % [PAN_NAMES[role.x], ROW_NAMES[role.y]]


## La rangee employee a la marche [param step] d'une chute de [param drop] cases.
##
## ⚠ LE CORPS TOURNE SUR LUI-MEME, et on compte depuis la premiere case de corps pour que
## deux robes de hauteurs differentes, cote a cote, presentent la meme case en haut. Sans
## quoi le raccord horizontal se verrait a chaque changement de hauteur.
static func row_for(step: int, drop: int, landed: bool) -> int:
	if landed and step == drop:
		return ROW_FOOT
	if step == 1 and drop > 1:
		return ROW_CROWN
	return 1 + maxi(0, step - 2) % BODY_ROWS


## La chute sous une levre : Vector2i(nombre de cases, 1 si elle atterrit).
static func fall_at(heights: PackedStringArray, level: int, cell: Vector2i) -> Vector2i:
	var drop: int = STOREY_TILES * level
	var landed: bool = false
	for below: int in range(level - 1, -1, -1):
		var candidate: int = STOREY_TILES * (level - below)
		# ⚠ ON SONDE LA CASE JUSTE SOUS LE PIED, pas celles que la robe traverse. Les etages
		# partagent la grille : l'etage N-1 continue SOUS la robe de l'etage N. Sonder au
		# fil de la descente repondrait « touche » des la premiere case, et toutes les
		# falaises feraient une case de haut.
		if HeightMask.level_at(heights, cell.x, cell.y + candidate + 1) >= below:
			drop = candidate
			landed = true
			break
	return _trim(heights, level, cell, drop, landed)


## Raccourcit une robe qui rencontrerait le sol de SON PROPRE etage.
##
## ⚠ UNE ROBE N'ECRASE JAMAIS CE QU'ELLE BORDE. Deux morceaux d'un meme etage separes de
## moins que la hauteur d'un etage -- une terrasse en L, une passerelle -- se marchent
## dessus. Et une robe raccourcie ne pose pas son pied : elle ne touche pas le sol d'en
## bas, elle bute contre un voisin de son propre niveau. Le pied dessine une base qui
## repose ; la, le dessin doit simplement se taire.
static func _trim(heights: PackedStringArray, level: int, cell: Vector2i, drop: int, landed: bool) -> Vector2i:
	for step: int in range(1, drop + 1):
		if HeightMask.level_at(heights, cell.x, cell.y + step) >= level:
			return Vector2i(step - 1, 0)
	if HeightMask.level_at(heights, cell.x, cell.y + drop + 1) >= level:
		return Vector2i(drop, 0)
	return Vector2i(drop, 1 if landed else 0)


## Le pan a employer sur UNE case de robe.
##
## ⚠ LE PAN SE CHOISIT PAR RANGEE, JAMAIS PAR COLONNE. C'est la regle que la hauteur
## variable impose : quand ma voisine de gauche tombe de trois cases et moi de six, alors
## sous son pied je n'ai plus de voisine haute a gauche -- je suis devenue un bord, et je
## montre mon pan gauche. Evalue par rangee, le vocabulaire a trois pans habille les
## escaliers sans une seule tuile d'angle. Evalue une fois pour toute la colonne, il aurait
## cousu deux robes de hauteurs differentes bord a bord, et la couture se verrait.
static func pan_at(heights: PackedStringArray, level: int, covered: Dictionary, at: Vector2i, step: int) -> int:
	var span: int = (maxi(1, step) - 1) / STOREY_TILES
	var beside: int = level - span
	var west: bool = _has_high_neighbour(heights, covered, at + Vector2i.LEFT, level, beside)
	var east: bool = _has_high_neighbour(heights, covered, at + Vector2i.RIGHT, level, beside)
	if west and east:
		return PAN_MIDDLE
	if east:
		return PAN_LEFT
	if west:
		return PAN_RIGHT
	# Une falaise d'UNE case de large. Elle n'a pas de pan courant : on prend le gauche.
	return PAN_LEFT


## ⚠ L'ETAGE QU'ON BORDE COMPTE A TOUTES LES RANGEES, pas seulement au premier cran : c'est
## l'angle rentrant, deux morceaux du meme plateau separes d'un creux dont la robe longe le
## second.
## ⚠ ET ON NE SONDE JAMAIS L'ETAGE 0. Dans un relief, toute case est a la plaine ou
## au-dessus : le tester rendrait « haut » partout et tous les pans seraient courants.
static func _has_high_neighbour(heights: PackedStringArray, covered: Dictionary, at: Vector2i, level: int, beside: int) -> bool:
	if covered.has(at):
		return true
	var neighbour_level: int = HeightMask.level_at(heights, at.x, at.y)
	if neighbour_level >= level:
		return true
	return beside >= 1 and neighbour_level >= beside


## Deroule toutes les robes du relief.
##
## Cles retournees :
##   roles   : Dictionary[Vector3i, Vector2i]  (x, y, etage) -> (pan, rangee)
##   outside : Array[Vector3i]                 cases de robe tombees hors de la grille
##
## La cle porte l'etage : deux robes d'etages differents peuvent se superposer sur la meme
## case, la plus haute masquant l'autre, exactement comme deux calques.
static func assemble(heights: PackedStringArray) -> Dictionary:
	var roles: Dictionary = {}
	var outside: Array[Vector3i] = []
	var grid_width: int = HeightMask.width(heights)
	var grid_height: int = HeightMask.height(heights)
	for level: int in range(1, HeightMask.top_level(heights) + 1):
		# PREMIERE PASSE -- la geometrie seule. On calcule toutes les chutes avant de poser
		# quoi que ce soit, parce que le pan d'une rangee depend de ce que les robes
		# VOISINES couvrent a cette hauteur-la : en posant, on ne connaitrait que la
		# moitie gauche.
		var drops: Dictionary = {}
		var covered: Dictionary = {}
		for y: int in range(grid_height):
			for x: int in range(grid_width):
				if HeightMask.level_at(heights, x, y) < level:
					continue
				if HeightMask.level_at(heights, x, y + 1) >= level:
					continue  # ce bord-la est interieur : rien a montrer
				var cell: Vector2i = Vector2i(x, y)
				var fall: Vector2i = fall_at(heights, level, cell)
				drops[cell] = fall
				for step: int in range(1, fall.x + 1):
					covered[cell + Vector2i(0, step)] = true
		# SECONDE PASSE -- la pose.
		for cell: Vector2i in drops:
			var fall: Vector2i = drops[cell]
			var drop: int = fall.x
			if drop <= 0:
				continue  # raccourcie a neant : un voisin du meme etage occupe deja la case
			var landed: bool = fall.y == 1
			for step: int in range(1, drop + 1):
				var at: Vector2i = cell + Vector2i(0, step)
				var role: Vector2i = Vector2i(pan_at(heights, level, covered, at, step), row_for(step, drop, landed))
				roles[Vector3i(at.x, at.y, level)] = role
				if at.y >= grid_height or at.x < 0 or at.x >= grid_width:
					outside.append(Vector3i(at.x, at.y, level))
	return {"roles": roles, "outside": outside}


## Rapport de couverture du vocabulaire de mur, meme forme que coverage.analyse().
##
## Cles retournees :
##   present     : Array[Vector2i]                roles couverts
##   missing     : Array[Vector2i]                roles absents
##   occurrences : Dictionary[Vector2i, int]      role -> nombre de cases
##   positions   : Dictionary[Vector2i, Array]    role -> Array[Vector3i] des cases
##   outside     : Array[Vector3i]                robes tombees hors de la grille
##   is_complete : bool
static func analyse(heights: PackedStringArray) -> Dictionary:
	var assembled: Dictionary = assemble(heights)
	var roles: Dictionary = assembled["roles"]
	var occurrences: Dictionary = {}
	var positions: Dictionary = {}
	for key: Vector3i in roles.keys():
		var role: Vector2i = roles[key]
		occurrences[role] = int(occurrences.get(role, 0)) + 1
		if not positions.has(role):
			var new_cells: Array[Vector3i] = []
			positions[role] = new_cells
		var cells: Array[Vector3i] = positions[role]
		cells.append(key)
	var present: Array[Vector2i] = []
	var missing: Array[Vector2i] = []
	for role: Vector2i in ALL_ROLES:
		if occurrences.has(role):
			present.append(role)
		else:
			missing.append(role)
	return {
		"present": present,
		"missing": missing,
		"occurrences": occurrences,
		"positions": positions,
		"outside": assembled["outside"],
		"is_complete": missing.is_empty(),
	}


## Le role VISIBLE de chaque case de robe : celui de l'etage le plus haut qui l'occupe.
## Deux robes peuvent se superposer sur une case ; on ne voit que la plus haute, donc
## c'est elle qu'on peint.
static func visible_roles(heights: PackedStringArray) -> Dictionary:
	var roles: Dictionary = assemble(heights)["roles"]
	var highest: Dictionary = {}
	var chosen: Dictionary = {}
	for key: Vector3i in roles.keys():
		var cell: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(cell) or key.z > int(highest[cell]):
			highest[cell] = key.z
			chosen[cell] = roles[key]
	# ⚠ LA CARTE SORT EN ORDRE DE LECTURE, ET C'EST TRIE UNE SEULE FOIS ICI. Les robes se
	# rassemblent etage par etage, donc dans un ordre qui n'est pas celui de l'ecran ; trier
	# a chaque coup de crayon coutait plus cher que le compte lui-meme.
	var cells: Array[Vector2i] = []
	for cell: Vector2i in chosen.keys():
		cells.append(cell)
	cells.sort_custom(_reading_order)
	var visible: Dictionary = {}
	for cell: Vector2i in cells:
		visible[cell] = chosen[cell]
	return visible


## La regle des variantes, appliquee aux robes : une case peinte est retenue pour son role,
## une case vierge ne sert pas. Memes cles que variants.resolve().
static func resolve(heights: PackedStringArray, painted_cells: Array[Vector2i]) -> Dictionary:
	return resolve_roles(visible_roles(heights), painted_cells)


## Meme chose a partir de roles deja rassembles. ⚠ RASSEMBLER LES ROBES COUTE UN PARCOURS
## COMPLET DU RELIEF : l'editeur les calcule une fois au chargement, et repasse par ici a
## chaque coup de crayon.
static func resolve_roles(visible: Dictionary, painted_cells: Array[Vector2i]) -> Dictionary:
	var painted: Dictionary = {}
	for cell: Vector2i in painted_cells:
		painted[cell] = true
	var retained: Dictionary = {}
	var unused: Array[Vector2i] = []
	for cell: Vector2i in visible.keys():
		var role: Vector2i = visible[cell]
		if not painted.has(cell):
			unused.append(cell)
			continue
		if not retained.has(role):
			var new_cells: Array[Vector2i] = []
			retained[role] = new_cells
		var kept: Array[Vector2i] = retained[role]
		kept.append(cell)
	var delivered: Array[Vector2i] = []
	var missing: Array[Vector2i] = []
	for role: Vector2i in ALL_ROLES:
		if retained.has(role):
			delivered.append(role)
		else:
			missing.append(role)
	return {
		"retained": retained,
		"unused": unused,
		"delivered": delivered,
		"missing": missing,
		"is_exportable": missing.is_empty(),
	}


static func _reading_order(left: Vector2i, right: Vector2i) -> bool:
	if left.y != right.y:
		return left.y < right.y
	return left.x < right.x


## Les cases de robe regroupees par role. Meme raison que coverage.cells_by_index() : deux
## cases du meme role portent la meme tuile.
static func cells_by_role(visible: Dictionary) -> Dictionary:
	var groups: Dictionary = {}
	for cell: Vector2i in visible.keys():
		var role: Vector2i = visible[cell]
		if not groups.has(role):
			var fresh: Array[Vector2i] = []
			groups[role] = fresh
		var cells: Array[Vector2i] = groups[role]
		cells.append(cell)
	return groups

