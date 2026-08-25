# LE BATISSEUR DU GUIDE EPAIS — les accidents composes, et le guide qui se prouve.
#
# Le mode epais interdit toute bande fine -- course de moins de TROIS, bord + centre +
# bord (core/thickness.gd). Son guide se compose donc d'accidents redessines en gras :
# encoches 3x2, sabliers a trous 3x3, moulins a bras triples, contacts diagonaux de
# blocs 3x3, gorge decalee, tour du cap, escarpements a eperons TRIPLES, et les deux
# REDANS -- les roles (vide,devant) et (devant,vide) du corps 1, ceux que min trois a
# reveles. Le relief se decrit accident par accident, jamais en ASCII -- lecon du
# depot -- et CE fichier est le seul endroit ou leur geometrie est ecrite.
#
# IL SE VERIFIE EN S'ECRIVANT : epaisseur, 27/27 surfaces, 25/25 roles, 15/15
# croisements, zero robe hors grille, vocabulaire entier hors de la plaine. S'il
# echoue, il ecrit quand meme le guide et dit ce qui manque -- c'est un outil
# d'iteration, le runner reste le juge final.
#
#     godot --headless --path . --script res://tools/build_epais.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Thickness := preload("res://core/thickness.gd")

const WIDTH: int = 104
const HEIGHT: int = 44
const OUT_PATH: String = "res://guides/epais.txt"

var _levels: Array = []


func _fill(x0: int, y0: int, x1: int, y1: int, level: int) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			(_levels[y] as Array)[x] = maxi((_levels[y] as Array)[x] as int, level)


func _carve(x0: int, y0: int, x1: int, y1: int, level: int) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			(_levels[y] as Array)[x] = level


## Un moulin : deux bras 3x3 en quinconce autour d'un coude -- deux cardinaux pleins,
## la diagonale entre eux vide. Chaque bras fait bord + centre + bord dans les deux
## axes, et le coude lui-meme a ses courses de trois. `turn` choisit l'orientation.
func _windmill(cx: int, cy: int, turn: int) -> void:
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	for dy: int in range(-3, 0):
		for dx: int in range(-2, 1):
			cells.append(Vector2i(dx, dy))
	for dy: int in range(0, 3):
		for dx: int in range(1, 4):
			cells.append(Vector2i(dx, dy))
	for offset: Vector2i in cells:
		var spun: Vector2i = offset
		for _quarter: int in range(turn):
			spun = Vector2i(-spun.y, spun.x)
		var at: Vector2i = Vector2i(cx, cy) + spun
		(_levels[at.y] as Array)[at.x] = maxi((_levels[at.y] as Array)[at.x] as int, 1)


func _compose() -> void:
	_levels.clear()
	for y: int in range(HEIGHT):
		var line: Array = []
		line.resize(WIDTH)
		line.fill(-1)
		_levels.append(line)

	# LA PLAINE : le socle, avec sa cote qui ondule par ajouts -- jamais par retraits.
	_fill(2, 4, 101, 37, 0)
	_fill(12, 2, 17, 3, 0)
	_fill(52, 2, 57, 3, 0)
	_fill(8, 38, 23, 39, 0)
	_fill(28, 38, 55, 39, 0)
	_fill(60, 38, 67, 39, 0)

	# A. LE MASSIF A ENCOCHES : bords, coins, rentrants, et les bords-moins-un-coin --
	# une encoche de TROIS cases de long sur deux de profond par cote. Les encoches
	# ouest et est font ecreter la robe du dessus contre le massif qui reprend : deux
	# poses derriere gratuites.
	_fill(5, 7, 18, 15, 1)
	_carve(9, 7, 11, 8, 0)
	_carve(5, 10, 6, 12, 0)
	_carve(17, 10, 18, 12, 0)
	_carve(13, 14, 15, 15, 0)

	# B. LE SABLIER : trois trous 3x3 en quinconce -- les pincements 119 et 221 entre
	# eux. ⚠ TROIS rangees pleines au moins entre un trou et le bord, sinon la marge
	# est fine. Chaque trou ecrete la robe de sa levre interieure : poses derriere.
	_fill(22, 6, 38, 18, 1)
	_carve(25, 9, 27, 11, 0)
	_carve(29, 13, 31, 15, 0)
	_carve(33, 9, 35, 11, 0)

	# B'. LE DEFILE : un bloc 4x3 sous le rebord sud-ouest du sablier, a TROIS rangees
	# de creux -- il ECRETE les robes qui tombent sur lui et recoit leurs poses
	# derriere. Il touche l'escarpement a banquette par l'est : adjacence legale.
	_fill(27, 22, 30, 24, 1)

	# C. LES MOULINS : les quatre coudes, un par orientation, bras triples.
	_windmill(45, 9, 0)
	_windmill(55, 9, 1)
	_windmill(65, 9, 2)
	_windmill(75, 9, 3)

	# R. LES DEUX REDANS -- les roles que min trois a reveles : un bord sud a
	# decrochement d'une rangee, pose sur un tablier partiel d'etage 1. La colonne
	# entre le tablier et les colonnes en retrait plonge seule : vide du cote tablier,
	# devant du cote retrait -- (vide,devant) corps 1, et son miroir.
	_fill(81, 6, 87, 9, 2)
	_fill(81, 10, 85, 10, 2)
	_fill(81, 11, 84, 14, 1)
	_fill(91, 6, 97, 9, 2)
	_fill(93, 10, 97, 10, 2)
	_fill(94, 11, 97, 14, 1)

	# D. LES CONTACTS DIAGONAUX : deux paires de blocs 3x3, une par orientation.
	_fill(5, 23, 7, 25, 1)
	_fill(8, 26, 10, 28, 1)
	_fill(14, 26, 16, 28, 1)
	_fill(17, 23, 19, 25, 1)

	# E. L'ESCARPEMENT A BANQUETTE : eperons TRIPLES avances d'une rangee, terrasses
	# 3x3 EXACTEMENT sous eux (jamais sous leurs voisines, qui doivent tomber encore
	# quand l'eperon pose son pied), quatre rangees sous leur levre -- les pieds a
	# angle. Trois colonnes plates consecutives entre les eperons : le chapiteau
	# (muet,muet).
	_fill(31, 23, 46, 26, 2)
	_fill(34, 27, 36, 27, 2)
	_fill(41, 27, 43, 27, 2)
	_fill(34, 31, 36, 33, 1)
	_fill(41, 31, 43, 33, 1)

	# F. L'ESCARPEMENT PROFOND : chute de six d'un trait, eperons triples -- les
	# corps a angle pendant que les parois voisines tombent encore.
	_fill(50, 23, 72, 27, 2)
	_fill(54, 28, 56, 28, 2)
	_fill(64, 28, 66, 28, 2)

	# G. LA GORGE DECALEE : un bloc d'etage 2 dont la colonne ouest chute seule de
	# six, longee par les murs du bloc d'etage 1 decale -- (vide,vide) en profondeur,
	# pied compris.
	_fill(76, 23, 79, 27, 2)
	_fill(77, 28, 80, 31, 1)

	# H. LA TOUR DU CAP : trois colonnes d'etage 2 ; deux atterrissent court sur le
	# bloc decale, la troisieme plonge de six jusqu'au vide SANS poser son pied --
	# son dernier pas est un corps, seul en profondeur : (vide,vide) corps 0.
	_fill(84, 27, 86, 31, 2)
	_fill(83, 32, 85, 35, 1)


func _mask() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(HEIGHT):
		var line: String = ""
		for x: int in range(WIDTH):
			var level: int = (_levels[y] as Array)[x] as int
			if level < 0:
				line += "~"
			elif level == 0:
				line += "."
			else:
				line += str(level)
		out.append(line)
	return out


func _initialize() -> void:
	_compose()
	var heights: PackedStringArray = _mask()
	var failures: int = 0

	# 1. L'epaisseur, partout, tous etages.
	var thin: Array[Vector3i] = Thickness.thin_cells(heights)
	if not thin.is_empty():
		failures += 1
		print("FIN : %d case(s) fine(s), par exemple %s" % [thin.size(),
				str(thin.slice(0, 6))])

	# 2. Les 27 surfaces, HORS de la plaine.
	var indices: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var seen_indices: Dictionary = {}
	for at: Vector2i in indices.keys():
		if HeightMask.level_at(heights, at.x, at.y) >= 1:
			seen_indices[int(indices[at])] = true
	var missing_indices: Array = []
	var extra_indices: Array = []
	for index: int in Thickness.SURFACE_INDICES:
		if not seen_indices.has(index):
			missing_indices.append(index)
	for index: int in seen_indices.keys():
		if not (index in Thickness.SURFACE_INDICES):
			extra_indices.append(index)
	if not missing_indices.is_empty():
		failures += 1
		print("SURFACES manquantes (%d) : %s" % [missing_indices.size(), str(missing_indices)])
	if not extra_indices.is_empty():
		failures += 1
		print("SURFACES HORS VOCABULAIRE (%d) : %s -- le relief n'est pas epais la ou elles vivent"
				% [extra_indices.size(), str(extra_indices)])

	# 3. Les 25 roles, hors plaine, et aucune robe hors grille.
	var seen_walls: Dictionary = Walls.visible(heights)
	var roles: Dictionary = seen_walls["roles"]
	var lips: Dictionary = seen_walls["lips"]
	var seen_roles: Dictionary = {}
	var outside: int = 0
	for cell: Vector2i in roles.keys():
		if cell.y >= HEIGHT or cell.y < 0 or cell.x < 0 or cell.x >= WIDTH:
			outside += 1
		if int(lips.get(cell, 0)) >= 1:
			seen_roles[roles[cell]] = true
	var missing_roles: Array = []
	var extra_roles: Array = []
	for role: Vector2i in Thickness.wall_roles():
		if not seen_roles.has(role):
			missing_roles.append(role)
	for role: Vector2i in seen_roles.keys():
		if not Thickness.role_survives(role):
			extra_roles.append(role)
	if not missing_roles.is_empty():
		failures += 1
		var told: PackedStringArray = PackedStringArray()
		for role: Vector2i in missing_roles:
			told.append("(%s,%s) %s" % [Walls.SIDE_NAMES[Walls.pan_west(role.x)],
					Walls.SIDE_NAMES[Walls.pan_east(role.x)], Walls.ROW_NAMES[role.y]])
		print("ROLES manquants (%d) : %s" % [missing_roles.size(), ", ".join(told)])
	if not extra_roles.is_empty():
		failures += 1
		var told_extra: PackedStringArray = PackedStringArray()
		for role: Vector2i in extra_roles:
			told_extra.append("(%s,%s) %s" % [Walls.SIDE_NAMES[Walls.pan_west(role.x)],
					Walls.SIDE_NAMES[Walls.pan_east(role.x)], Walls.ROW_NAMES[role.y]])
		print("ROLES HORS VOCABULAIRE (%d) : %s" % [extra_roles.size(), ", ".join(told_extra)])
	if outside > 0:
		failures += 1
		print("ROBES HORS GRILLE : %d" % outside)

	# 4. Les 15 croisements, hors plaine.
	var crossings: Dictionary = CornerIndex.index_map(heights)
	var seen_corners: Dictionary = {}
	for point: Vector2i in crossings.keys():
		var high: int = -1
		for offset: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
			high = maxi(high, HeightMask.level_at(heights, point.x + offset.x, point.y + offset.y))
		if high >= 1:
			seen_corners[int(crossings[point])] = true
	var missing_corners: Array = []
	for index: int in range(1, 16):
		if not seen_corners.has(index):
			missing_corners.append(index)
	if not missing_corners.is_empty():
		failures += 1
		print("CROISEMENTS manquants (%d) : %s" % [missing_corners.size(), str(missing_corners)])

	# L'ecriture, meme imparfaite : le guide est un travail d'iteration.
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	for line: String in heights:
		file.store_line(line)
	file.close()
	print("guide ecrit : %s (%dx%d)" % [OUT_PATH, WIDTH, HEIGHT])
	print("BATISSEUR EPAIS : %d probleme(s)." % failures)
	quit(0 if failures == 0 else 1)
