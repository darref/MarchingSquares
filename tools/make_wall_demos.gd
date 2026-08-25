extends SceneTree

## LES SPECIMENS DE FALAISE DE LA PLANCHE, DECOUPES DANS LE GUIDE.
##
## ⚠ ELLE ETAIT DESSINEE A LA MAIN, ET ELLE A VIEILLI SANS RIEN DIRE. Cinq accidents
## « repris du guide en miniature » portaient les vingt-cinq roles d'alors ; le vocabulaire
## est passe a quarante-quatre et sept roles n'avaient plus de scene. Une demonstration
## ecrite est une donnee a maintenir, donc un endroit ou mentir -- meme raison qui fait
## calculer les 47 index et les ilots.
##
## ⚠ ET ON LA PREND DANS LE GUIDE PLUTOT QUE DE LA TIRER AU SORT. Deux raisons, la seconde
## etant celle qui a coute : le guide porte les 44 roles par construction, alors qu'une
## marche au hasard n'en rencontre que 42 -- les plus rares demandent un CONTREFORT, une
## forme voulue ; et surtout le guide est pose SUR LA PLAINE, exactement comme la planche.
## Un specimen cherche sur le vide y tombe de neuf rangees et montre ses trois corps ; pose
## sur la plaine il ne tombe que de six, et sept roles disparaissent sans un mot.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")

const HALVES: Array[int] = [7, 10, 13]
const FIELD: int = 12         # la plaine ajoutee autour pour juger : de quoi atterrir
const RING: int = 3           # puis le vide, qui fait le bord du monde


func _initialize() -> void:
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var roles: Dictionary = Walls.visible_roles(guide)
	var spots: Dictionary = {}
	for at: Vector2i in roles.keys():
		var role: Vector2i = roles[at]
		if not spots.has(role):
			spots[role] = []
		if (spots[role] as Array).size() < 4:
			(spots[role] as Array).append(at)
	var crops: Array[PackedStringArray] = []
	var carried: Array[Dictionary] = []
	var missing: Dictionary = {}
	for role: Vector2i in Thickness.wall_roles():
		missing[role] = true
	for role: Vector2i in Thickness.wall_roles():
		if not missing.has(role):
			continue
		var done: bool = false
		for at: Variant in (spots.get(role, []) as Array):
			for half: int in HALVES:
				var crop: PackedStringArray = _crop(guide, (at as Vector2i).x,
						(at as Vector2i).y, half)
				var here: Dictionary = _judge(crop)
				if here.is_empty() or not here.has(role):
					continue
				crops.append(crop)
				carried.append(here)
				for seen: Vector2i in here.keys():
					missing.erase(seen)
				done = true
				break
			if done:
				break
		if not done:
			print("  aucun decoupage pour %s %s" % [Walls.pan_name(role.x),
					Walls.ROW_NAMES[role.y]])
	# La couverture gloutonne : le moins de specimens possible.
	var todo: Dictionary = {}
	for role: Vector2i in Thickness.wall_roles():
		todo[role] = true
	var chosen: Array[int] = []
	while not todo.is_empty():
		var best: int = -1
		var best_score: int = 0
		for i: int in range(crops.size()):
			var score: int = 0
			for role: Vector2i in carried[i].keys():
				if todo.has(role):
					score += 1
			if score > best_score:
				best_score = score
				best = i
		if best < 0:
			break
		chosen.append(best)
		for role: Vector2i in carried[best].keys():
			todo.erase(role)
	print("decoupages : %d   specimens retenus : %d   roles sans scene : %d"
			% [crops.size(), chosen.size(), todo.size()])
	for role: Vector2i in todo.keys():
		print("    sans scene : %s %s" % [Walls.pan_name(role.x), Walls.ROW_NAMES[role.y]])
	var out: String = ""
	out += "## LES SPECIMENS DE FALAISE de la planche de preuve.\n"
	out += "##\n"
	out += "## Decoupes DANS LE GUIDE par `tools/make_wall_demos.gd` : il porte les 44 roles, et\n"
	out += "## il est pose sur la plaine, exactement comme la planche. Chacun est verifie epais,\n"
	out += "## sans robe hors du cadre, et porteur des roles qu'on lui demande. Ne pas editer a\n"
	out += "## la main : la suite reverifie.\n"
	out += "##\n"
	out += "## EN TABLEAUX SIMPLES, PAS EN PackedStringArray : GDScript ne fait pas une constante\n"
	out += "## d'un paquet type de ce genre -- le membre cesse de se resoudre, et tout ce qui\n"
	out += "## prechargeait le fichier tombe avec lui, sans erreur claire.\n"
	out += "const SPECIMENS: Array = [\n"
	for i: int in chosen:
		out += "\t[\n"
		for line: String in crops[i]:
			out += "\t\t\"%s\",\n" % line
		out += "\t],\n"
	out += "]\n"
	var file: FileAccess = FileAccess.open("res://core/wall_demos.gd", FileAccess.WRITE)
	file.store_string(out)
	file.close()
	quit()


## Un carre du guide autour de la case, tel quel -- la plaine du guide vient avec.
func _crop(guide: PackedStringArray, cx: int, cy: int, half: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(cy - half, cy + half + 1):
		var line: String = ""
		for x: int in range(cx - half, cx + half + 1):
			var level: int = HeightMask.level_at(guide, x, y)
			line += "~" if level < 0 else str(level)
		out.append(line)
	return out


## Le juge, DANS LE CONTEXTE DE LA PLANCHE : le decoupage entoure de plaine, puis de vide.
func _judge(crop: PackedStringArray) -> Dictionary:
	var pad: int = FIELD + RING
	var width: int = crop[0].length() + 2 * pad
	var height: int = crop.size() + 2 * pad
	var relief: PackedStringArray = PackedStringArray()
	for y: int in range(height):
		var line: String = ""
		for x: int in range(width):
			if y < RING or y >= height - RING or x < RING or x >= width - RING:
				line += "~"
			elif y < pad or y >= height - pad or x < pad or x >= width - pad:
				line += "0"
			else:
				line += crop[y - pad].substr(x - pad, 1)
		relief.append(line)
	if not Thickness.thin_cells(relief).is_empty():
		return {}
	var report: Dictionary = Walls.analyse(relief, Thickness.wall_roles())
	if not (report["outside"] as Array).is_empty():
		return {}
	# ⚠ ON NE COMPTE QUE LES ROLES DU DECOUPAGE, pas ceux que la plaine ajoutee fabrique
	# autour : ceux-la n'existeront pas sur la planche.
	var here: Dictionary = {}
	var visible: Dictionary = Walls.visible_roles(relief)
	for at: Vector2i in visible.keys():
		if at.x < pad or at.x >= width - pad or at.y < pad or at.y >= height - pad:
			continue
		here[visible[at]] = true
	return here
