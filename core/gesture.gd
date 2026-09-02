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
static func legal(world: PackedStringArray) -> bool:
	return faults(world).is_empty()


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
	var feet: int = Massifs.foot_faults(world).size()
	if feet > 0:
		out.append("%d faute(s) de marge de pied" % feet)
	var holes: int = chasms(world)
	if holes > 0:
		out.append("%d gouffre(s) enclos" % holes)
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


## LA CORRECTION : le pinceau corrige, il ne refuse pas (decision utilisateur).
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
	var last: PackedStringArray = text(grid)
	return last if legal(last) else PackedStringArray()


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
