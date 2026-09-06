# LA REGLE DU GESTE — ce qu'un relief a le droit d'etre, ecrit UNE SEULE FOIS.
#
# ⚠ CE FICHIER EXISTE PARCE QUE LES CLAUSES ETAIENT EPARPILLEES, ET QUE CA FABRIQUAIT DES
# RUSTINES. L'epaisseur vivait dans `Thickness`, la marge de pied dans `Massifs`, le gouffre
# nulle part -- et chaque nouvelle clause devait etre recopiee dans le generateur, la chasse, le
# batisseur, l'audit et le banc. Il suffisait d'en oublier un pour qu'un relief illegal traverse
# toute la chaine : le guide a porte DEUX GOUFFRES, deux rectangles noirs en pleine matiere, et
# aucun invariant ne les a vus.
#
# Desormais : une clause s'ajoute ICI, et tout le monde la lit. Le pinceau du produit lira la
# meme.
#
# ⚠ ET LE DOMAINE, C'EST LE GESTE -- pas une esthetique. Chaque clause dit ce que le pinceau
# peut produire :
#
#   EPAISSEUR      il pose des tampons 3x3 : rien ne fait moins de trois, dans les deux etats ;
#   PINCEMENT      deux tampons poses en diagonale se toucheraient coin contre coin, et ca, il
#                  faut l'interdire a part -- min trois ne le couvre pas ;
#   MARGE DE PIED  un pied ne peut pas tomber juste au-dessus d'une levre : les deux tracent a
#                  une rangee d'ecart et leurs traits se collent ;
#   GOUFFRE        son effacement descend d'un etage a la fois et s'arrete a la PLAINE, jamais
#                  au vide. Le vide n'existe qu'au BORD du monde.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Massifs := preload("res://core/massifs.gd")

const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## LE VERDICT : ce relief est-il de ceux que le pinceau produit ?
##
## ⚠ IL COURT-CIRCUITE, ET CE N'EST PAS UNE COQUETTERIE. Il rendait `faults().is_empty()`, donc
## il calculait LES SIX CLAUSES meme quand la premiere avait deja tranche -- dont trois qui
## relisent chacune `Massifs.poses()`, la carte la plus couteuse du modele. Or `Gesture.walk`
## appelle `legal()` APRES CHAQUE TAMPON, et la plupart des tampons refuses le sont sur
## l'epaisseur, qui ne demande aucune pose. Mesure : 976 ms par monde de 24x30.
##
## ⚠ ET L'ORDRE EST CELUI DU COUT, PAS CELUI DU DOSSIER. Epaisseur et pincement se lisent sur le
## relief nu ; le gouffre est un simple remplissage ; seules les trois dernieres demandent les
## poses, et elles se les PARTAGENT desormais. Une carte couteuse ne se recalcule pas a chaque
## tour de boucle -- lecon deja payee sept fois ailleurs.
##
## ⚠ ET `faults()` GARDE SON ROLE, INCHANGE : nommer ce qui cloche, pour reparer. Un verdict
## booleen suffit a refuser, jamais a corriger.
static func legal(world: PackedStringArray) -> bool:
	if Thickness.any_thin(world):
		return false
	if Thickness.any_pinch(world):
		return false
	if chasms(world) > 0:
		return false
	var made: Array[Dictionary] = Massifs.poses(world)
	if not Massifs.foot_faults(world, made).is_empty():
		return false
	if not thin_cells_visible(world, made).is_empty():
		return false
	return narrow_lips(world, made).is_empty()


## CE QUI CLOCHE, NOMME. ⚠ Un verdict booleen suffit a refuser, jamais a corriger : le pinceau
## doit savoir OU reparer, et le banc doit savoir quoi dire.
static func faults(world: PackedStringArray) -> Array[String]:
	var out: Array[String] = []
	var thin: int = Thickness.thin_cells(world).size()
	if thin > 0:
		out.append("%d case(s) fine(s)" % thin)
	var pinch: int = Thickness.diagonal_pinches(world).size()
	if pinch > 0:
		out.append("%d pincement(s) diagonal(aux)" % pinch)
	# ⚠ ET LES TROIS DERNIERES SE PARTAGENT UNE SEULE LECTURE DES POSES. Elles la refaisaient
	# chacune : trois fois la carte la plus couteuse du modele, pour un seul verdict.
	var made: Array[Dictionary] = Massifs.poses(world)
	var feet: int = Massifs.foot_faults(world, made).size()
	if feet > 0:
		out.append("%d faute(s) de marge de pied" % feet)
	var holes: int = chasms(world)
	if holes > 0:
		out.append("%d gouffre(s) enclos" % holes)
	var ribbons: int = thin_cells_visible(world, made).size()
	if ribbons > 0:
		out.append("%d cell(s) of visible grass too thin" % ribbons)
	var steps: int = narrow_lips(world, made).size()
	if steps > 0:
		out.append("%d south edge(s) thinner than three" % steps)
	return out


## LE BORD SUD NE DECROCHE PAS PAR MOINS DE TROIS COLONNES.
##
## ⚠ ET C'EST UNE CLAUSE SUR L'HERBE, PAS SUR LA ROCHE -- une levre EST le bord sud d'une
## surface. Min trois y vaut comme partout ailleurs : un escalier dont les marches font une
## colonne donne des falaises d'une colonne, qui se touchent COIN CONTRE COIN. Mesure sur le
## guide : 9 levres de moins de trois colonnes, 4 contacts diagonaux de roche -- une seule et
## meme cause.
##
## ⚠ J'AVAIS D'ABORD MESURE LA ROCHE, ET C'ETAIT LE MAUVAIS BOUT. Une face n'est pas posee par
## le level designer, elle DECOULE du bord sud : lui demander d'etre epaisse revient a corriger
## le symptome. On contraint l'herbe, la roche suit -- ce qui est la regle du modele depuis le
## debut.
static func narrow_lips(world: PackedStringArray,
		given: Array[Dictionary] = []) -> Array[Vector2i]:
	var lips: Dictionary = {}
	for pose: Dictionary in (given if not given.is_empty() else Massifs.poses(world)):
		if int(pose["band"]) == Massifs.SURFACE:
			continue
		lips[pose["lip"]] = int(pose["level"])
	var out: Array[Vector2i] = []
	for lip: Vector2i in lips.keys():
		var length: int = 1
		for way: int in [-1, 1]:
			for step: int in [1, 2]:
				var near: Vector2i = lip + Vector2i(way * step, 0)
				if not lips.has(near) or int(lips[near]) != int(lips[lip]):
					break
				length += 1
		if length < 3:
			out.append(lip)
	return out


## ⚠ ET IL N'Y A PAS DE CLAUSE SUR LA ROCHE : DEPUIS LE DEBUT, LA ROCHE NE FAIT QUE SUIVRE
## L'HERBE. J'en avais ajoute une -- « une face d'une seule colonne est trop fine » -- en croyant
## completer min trois. Elle est fausse par principe : une face n'est pas posee par le level
## designer, elle DECOULE du bord sud de la surface. Ce qui compte est la SURFACE, parce que
## c'est la que le personnage marche.


static func thin_cells_visible(world: PackedStringArray,
		given: Array[Dictionary] = []) -> Array[Vector2i]:
	var top: Dictionary = {}
	for one: Dictionary in (given if not given.is_empty() else Massifs.poses(world)):
		var cell: Vector2i = one["cell"]
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var grass: Dictionary = {}
	for cell2: Vector2i in top.keys():
		var one2: Dictionary = top[cell2]
		if int(one2["band"]) == Massifs.SURFACE and int(one2["level"]) >= 1:
			grass[cell2] = int(one2["massif"])
	var out: Array[Vector2i] = []
	for cell3: Vector2i in grass.keys():
		var mine: int = int(grass[cell3])
		var held: bool = false
		for oy: int in range(-2, 1):
			for ox: int in range(-2, 1):
				var full: bool = true
				for dy: int in range(3):
					for dx: int in range(3):
						var at: Vector2i = cell3 + Vector2i(ox + dx, oy + dy)
						if not grass.has(at) or int(grass[at]) != mine:
							full = false
				if full:
					held = true
		if not held:
			out.append(cell3)
	return out


## LES GOUFFRES ENCLOS : des poches de VIDE au milieu du monde.
##
## ⚠ AUCUN INVARIANT NE LES VOYAIT, ET IL Y AVAIT DEUX RAISONS. I6 ne controle que les cases
## dont les HUIT voisines sont de la matiere -- une case au bord du gouffre en est exclue par
## definition. Et la sonde de creux partait de l'etage UN : la poche vit dans la silhouette de
## l'etage ZERO, la plaine, que personne n'avait regardee. Un compteur qui saute une famille
## entiere ne mesure pas ce qu'il pretend mesurer.
static func chasms(world: PackedStringArray) -> int:
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	var seen: Dictionary = {}
	var many: int = 0
	for y: int in range(tall):
		for x: int in range(wide):
			var here: Vector2i = Vector2i(x, y)
			if seen.has(here) or HeightMask.level_at(world, x, y) >= 0:
				continue
			var stack: Array[Vector2i] = [here]
			seen[here] = true
			var edge: bool = false
			while not stack.is_empty():
				var at: Vector2i = stack.pop_back()
				if at.x == 0 or at.y == 0 or at.x == wide - 1 or at.y == tall - 1:
					edge = true
				for step: Vector2i in STEPS:
					var near: Vector2i = at + step
					if near.x < 0 or near.y < 0 or near.x >= wide or near.y >= tall:
						continue
					if seen.has(near) or HeightMask.level_at(world, near.x, near.y) >= 0:
						continue
					seen[near] = true
					stack.append(near)
			if not edge:
				many += 1
	return many


## LA MARCHE DU PINCEAU : un monde fait de GESTES, et de rien d'autre.
##
## ⚠ ET C'EST CE QUI REND L'ATTEIGNABILITE GRATUITE. Un monde bati par une suite de gestes est
## atteignable PAR CONSTRUCTION -- la suite est la preuve. Le solveur glouton, lui, ne peut
## jamais conclure a l'impossible : il ne dit que « aucune suite simple n'y mene ».
##
## ⚠ ET C'EST LA QUE LE MODELE S'ETAIT DESACCORDE DE LUI-MEME. Le generateur posait des tampons
## puis appelait `mend`, qui corrige CASE PAR CASE -- abaisser une case fine, combler un gouffre.
## Ce sont des retouches d'une case, pas des tampons : le monde qui en sortait n'etait plus
## reconstructible au pinceau, et CINQ MONDES DU GUIDE SUR DIX etaient dans ce cas. Le guide
## montrait a l'artiste des reliefs que son pinceau ne produirait jamais.
##
## Deux gestes, et deux seulement :
##   POSER    un tampon 3x3, qui monte d'un etage, n'importe ou ;
##   EFFACER  un tampon 3x3 CENTRE SUR UNE CASE DE SURFACE PLEINE -- une case dont les huit
##            voisines sont de la surface du meme massif. Tout le reste, falaise et bords,
##            s'enleve en consequence.
##
## ⚠ ET L'EFFACEMENT SE LIMITE AU COEUR D'UNE MASSE POUR UNE RAISON MESUREE : pose au bord, il
## ronge une bande deja mince ; pose au coeur, il y creuse un trou de trois sur trois, epais par
## construction. Mesure : 62 % des gestes passent, contre un generateur qui devait tout reparer.
##
## Un geste qui rendrait le monde illegal est simplement REFUSE.
static func walk(rng: RandomNumberGenerator, wide: int, tall: int, rim: int = 4) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	for x: int in range(rim, wide - rim):
		for y2: int in range(rim, tall - rim):
			grid[y2][x] = 1
	for _move: int in range(rng.randi_range(10, 40)):
		var raise: bool = rng.randf() < 0.7
		var where: Vector2i = _where(grid, rng, raise, wide, tall, rim)
		if where.x < 0:
			continue
		var keep: Array[PackedByteArray] = []
		for row: PackedByteArray in grid:
			keep.append(row.duplicate())
		var floor_at: int = 9
		for y0: int in range(where.y, where.y + 3):
			for x0: int in range(where.x, where.x + 3):
				floor_at = mini(floor_at, int(grid[y0][x0]))
		var put: int = rng.randi_range(floor_at + 1, mini(floor_at + 2, 4)) if raise 				else rng.randi_range(1, maxi(floor_at - 1, 1))
		for y3: int in range(where.y, where.y + 3):
			for x3: int in range(where.x, where.x + 3):
				grid[y3][x3] = put
		if not legal(text(grid)):
			grid = keep
	return text(grid)


## Ou le geste peut se poser : la pose partout, l'effacement au COEUR d'une masse seulement.
static func _where(grid: Array[PackedByteArray], rng: RandomNumberGenerator, raise: bool,
		wide: int, tall: int, rim: int) -> Vector2i:
	if raise:
		return Vector2i(rng.randi_range(rim, wide - rim - 3), rng.randi_range(rim, tall - rim - 3))
	var top: Dictionary = {}
	for one: Dictionary in Massifs.poses(text(grid)):
		if bool(one["under"]):
			continue
		var cell: Vector2i = one["cell"]
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var full: Array[Vector2i] = []
	for cell2: Vector2i in top.keys():
		var one2: Dictionary = top[cell2]
		if int(one2["band"]) != Massifs.SURFACE or int(one2["level"]) < 1:
			continue
		var solid: bool = true
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var near: Dictionary = top.get(cell2 + Vector2i(dx, dy), {})
				if near.is_empty() or int(near["band"]) != Massifs.SURFACE 						or int(near["massif"]) != int(one2["massif"]):
					solid = false
		if solid:
			full.append(cell2)
	if full.is_empty():
		return Vector2i(-1, -1)
	var at: Vector2i = full[rng.randi() % full.size()]
	return Vector2i(clampi(at.x - 1, rim, wide - rim - 3), clampi(at.y - 1, rim, tall - rim - 3))


## LA CORRECTION : le pinceau corrige, il ne refuse pas (decision utilisateur).
##
## ⚠ ET ELLE N'A RIEN A FAIRE DANS UNE BATTUE. `mend` retouche CASE PAR CASE -- abaisser une
## case fine, combler un gouffre -- ce qui n'est pas un tampon : le monde qui en sort est LEGAL
## sans etre reconstructible au pinceau. Un generateur qui l'appelle apres chaque coup fabrique
## donc des reliefs que l'artiste ne produira jamais, et les tuiles qu'ils portent entrent au
## vocabulaire pour rien. C'est deja arrive une fois -- cinq mondes du guide sur dix -- et
## `walk` a ete ecrit pour ca. Le recenseur, lui, etait reste sur l'ancienne fabrique jusqu'au
## 05/09/2026 : SIX TUILES FANTOMES en sont sorties, qu'aucun geste n'atteint.
##
## `mend` sert au PINCEAU, qui repare le geste de l'artiste. Jamais a une battue.
##
## Chaque case fine s'aligne sur ses voisines cardinales ; chaque pincement diagonal se defait en
## alignant une cardinale sur sa diagonale ; chaque gouffre se comble a la plaine. Jusqu'au point
## fixe -- et si le point fixe n'est pas legal, le geste est abandonne.
static func mend(grid: Array[PackedByteArray]) -> PackedStringArray:
	var tall: int = grid.size()
	var wide: int = grid[0].size()
	for round: int in range(16):
		var world: PackedStringArray = text(grid)
		if legal(world):
			return world
		for cut: Vector3i in Thickness.diagonal_pinches(world):
			if cut.x < 0 or cut.y < 0 or cut.y + 1 >= tall or cut.x + 1 >= wide:
				continue
			grid[cut.y][cut.x + 1] = grid[cut.y][cut.x]
		for one: Vector3i in Thickness.thin_cells(world):
			if one.x < 0 or one.y < 0 or one.y >= tall or one.x >= wide:
				continue
			var votes: Dictionary = {}
			for step: Vector2i in STEPS:
				var nx: int = one.x + step.x
				var ny: int = one.y + step.y
				if nx < 0 or ny < 0 or ny >= tall or nx >= wide:
					continue
				votes[int(grid[ny][nx])] = int(votes.get(int(grid[ny][nx]), 0)) + 1
			var best: int = int(grid[one.y][one.x])
			var most: int = 0
			for value: int in votes.keys():
				if int(votes[value]) > most:
					most = int(votes[value])
					best = value
			grid[one.y][one.x] = best
		if chasms(text(grid)) > 0:
			_fill(grid)
		# ⚠ ET LE RUBAN FIN SE CORRIGE, IL NE SE REFUSE PAS. Une bande d'herbe visible d'une case
		# nait quand la falaise d'un massif plus haut recouvre une partie d'un plateau. On abaisse
		# la bande d'un etage : elle rejoint le sol au lieu de rester un rebord illisible. Refuser
		# le geste, au contraire, appauvrissait le generateur -- 129 especes de jonction tombaient
		# a 36 -- et le guide se serait mis a mentir par omission.
		_flatten(grid)
		# ⚠ ET UN BORD SUD TROP ETROIT S'ABAISSE : la marche d'une colonne disparait, et avec
		# elle la falaise d'une colonne qu'elle produisait.
		for lip: Vector2i in narrow_lips(text(grid)):
			if lip.y < 0 or lip.y >= tall or lip.x < 0 or lip.x >= wide:
				continue
			grid[lip.y][lip.x] = maxi(int(grid[lip.y][lip.x]) - 1, 1)
	var last: PackedStringArray = text(grid)
	return last if legal(last) else PackedStringArray()


## Abaisser les rubans d'herbe visible trop fins.
static func _flatten(grid: Array[PackedByteArray]) -> void:
	var world: PackedStringArray = text(grid)
	for cell: Vector2i in thin_cells_visible(world):
		if cell.y < 0 or cell.y >= grid.size() or cell.x < 0 or cell.x >= grid[0].size():
			continue
		grid[cell.y][cell.x] = maxi(int(grid[cell.y][cell.x]) - 1, 1)


## Combler les gouffres : toute poche de vide qui ne touche pas le bord devient de la plaine.
static func _fill(grid: Array[PackedByteArray]) -> void:
	var tall: int = grid.size()
	var wide: int = grid[0].size()
	var seen: Dictionary = {}
	for y: int in range(tall):
		for x: int in range(wide):
			if seen.has(Vector2i(x, y)) or int(grid[y][x]) != 0:
				continue
			var pocket: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			var edge: bool = false
			while not stack.is_empty():
				var at: Vector2i = stack.pop_back()
				pocket.append(at)
				if at.x == 0 or at.y == 0 or at.x == wide - 1 or at.y == tall - 1:
					edge = true
				for step: Vector2i in STEPS:
					var near: Vector2i = at + step
					if near.x < 0 or near.y < 0 or near.x >= wide or near.y >= tall:
						continue
					if seen.has(near) or int(grid[near.y][near.x]) != 0:
						continue
					seen[near] = true
					stack.append(near)
			if edge:
				continue
			for one: Vector2i in pocket:
				grid[one.y][one.x] = 1


static func text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: PackedByteArray in grid:
		var said: String = ""
		for v: int in line:
			said += "~" if v == 0 else str(v - 1)
		out.append(said)
	return out
