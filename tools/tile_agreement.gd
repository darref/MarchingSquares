# LES OCCURRENCES D'UNE MEME TUILE SONT-ELLES D'ACCORD ? — le detecteur general.
#
# ⚠ CE FICHIER EXISTE PARCE QUE L'UTILISATEUR TROUVAIT CES DEFAUTS A L'OEIL, UN PAR UN. Il a
# montre du doigt une case de mur `muet` dont l'arete n'appartenait a personne, puis deux
# cases d'herbe a six colonnes d'ecart dont l'une bordait de la roche et l'autre du nu. A
# chaque fois la meme espece de faute : UNE TUILE PARTAGEE SOMMEE D'ETRE DEUX CHOSES. Les
# chercher a la main ne dit jamais si on les a toutes.
#
# LE PRINCIPE. Une tuile est la meme image partout ou elle se pose. Deux occurrences ne
# peuvent donc differer que sur ce que la tuile n'a PAS le droit de montrer. On releve donc,
# pour chaque occurrence, ce que le modele affirme AUTOUR d'elle et A SON ALTITUDE, et on
# exige que toutes ses occurrences en disent la meme chose.
#
# LES QUATRE ESPECES DE VOISIN, vues d'une case a l'altitude N :
#   C  CONTIGU  une surface visible au niveau N ou plus haut : la matiere continue ;
#   R  ROCHE    une face de falaise visible : de la roche a mon altitude, sans marche ;
#   .  NU       tout le reste -- une surface plus bas, ou le vide : ca tombe, et ce qu'il y
#              a au fond n'est pas ma case.
#
# ⚠ LES CARDINAUX DOIVENT ETRE D'ACCORD, C'EST LE CONTRAT. `C` est dans les huit bits de
# voisinage ; `R` et `.` ne sont dans RIEN aujourd'hui -- c'est le BORD, mesure puis mis de
# cote en attendant que la grammaire soit choisie (voir la fiche du sweet spot). Ce detecteur
# criera donc sur les neuf couples, et c'est exactement ce qu'il doit faire.
#
# ⚠ LES DIAGONALES, ELLES, SE RELEVENT SANS SE JUGER. Un coin decoupe laisse voir ce qu'il y
# a derriere, et c'est l'EMPILEMENT qui le fournit -- ce n'est donc pas forcement une faute
# qu'elles divergent. L'outil les compte a part, pour qu'on decide en connaissance de cause
# plutot que de se le faire montrer du doigt.
#
#     godot --headless --path . --script res://tools/tile_agreement.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Families := preload("res://core/families.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Modes := preload("res://core/modes.gd")

const TRIALS: int = 150

## Les huit voisines, cardinaux d'abord : N E S O, puis NE SE SO NO.
const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1),
]
const NAMES: Array[String] = ["N", "E", "S", "O", "NE", "SE", "SO", "NO"]


## Ce que le modele affirme d'une case, vue d'une altitude.
func _kind(heights: PackedStringArray, surface: Dictionary, walled: Dictionary,
		at: Vector2i, altitude: int) -> String:
	# ⚠ CONTIGU AVANT ROCHE, ET L'ORDRE COMPTE. Une voisine au niveau de mon sol ou plus haut
	# est de la matiere qui CONTINUE la mienne -- meme si la face d'un plateau plus haut passe
	# par-dessus elle. Cette face-la est au-dessus de mon altitude : elle ne change rien a ce
	# que ma tuile doit montrer. Tester `walled` d'abord faisait crier le detecteur sur la
	# tuile 255, qui n'a pourtant aucun bord.
	var level: int = HeightMask.level_at(heights, at.x, at.y)
	if level >= altitude and level >= 0:
		return "C"
	# ⚠ ET LA ROCHE AVANT LE VIDE : une face qui tombe DANS le vide couvre quand meme les
	# cases qu'elle traverse. Tester le hors-monde d'abord masquait le sud de toutes les
	# levres du bord du monde, et faisait crier le detecteur sur un theoreme.
	if walled.has(at):
		return "R"
	# ⚠ « PLUS BAS » ET « LE VIDE » SONT LA MEME CHOSE POUR MOI. Ma tuile ne distingue que
	# la roche a mon altitude du reste : ce qu'il y a au-dela de mon bord n'est pas ma case.
	return "."


## La fiche d'une occurrence : quatre cardinaux, puis quatre diagonales.
func _fiche(heights: PackedStringArray, surface: Dictionary, walled: Dictionary,
		at: Vector2i) -> String:
	var altitude: int = HeightMask.level_at(heights, at.x, at.y)
	var out: String = ""
	for side: int in range(OFFSETS.size()):
		out += _kind(heights, surface, walled, at + OFFSETS[side], altitude)
	return out


func _gather(heights: PackedStringArray, label: String, book: Dictionary) -> void:
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var walled: Dictionary = Walls.visible_roles(heights)
	for storage: Vector2i in surface:
		var at: Vector2i = Families.from_storage(Families.BY_CELL, storage)
		var tile: int = int(surface[storage])
		var fiche: String = _fiche(heights, surface, walled, at)
		if not book.has(tile):
			book[tile] = {}
		var seen: Dictionary = book[tile]
		if not seen.has(fiche):
			seen[fiche] = ["%s (%d,%d)" % [label, at.x, at.y], 0]
		var row: Array = seen[fiche]
		row[1] = int(row[1]) + 1


func _random_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	for _try: int in range(40):
		var columns: int = 24
		var rows: int = 22
		var levels: Array = []
		for y: int in range(rows):
			var line: Array = []
			line.resize(columns)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(3, 7)):
			var w: int = rng.randi_range(3, 8)
			var h: int = rng.randi_range(3, 8)
			var px: int = rng.randi_range(0, columns - w)
			var py: int = rng.randi_range(0, rows - h)
			var lift: int = rng.randi_range(1, 3)
			for y: int in range(py, py + h):
				for x: int in range(px, px + w):
					levels[y][x] = maxi(levels[y][x] as int, lift)
		var heights: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				line += str(levels[y][x] as int)
			heights.append(line)
		if Thickness.thin_cells(heights).is_empty():
			return heights
	return PackedStringArray()


## LES ROBES — meme question, autre vocabulaire : le PAN recouvre-t-il vraiment tout ce qui
## peut se trouver a cote d'une face ?
##
## ⚠ C'EST ICI QUE LA FAUTE DE `muet` SE SERAIT VUE TOUTE SEULE. Il disait « de la roche a
## cote » ET « le sommet d'un plateau est a cote, c'est a lui de tracer » : deux especes sous
## un seul nom, donc deux occurrences d'une meme tuile sommees de montrer deux choses.
##
## Les especes qu'on distingue, vues d'une case de robe lancee d'une levre a la rangee L :
##   M  la MEME face -- une robe de mon etage, lancee de MA levre ;
##   D  une face en RETRAIT -- meme etage, levre plus au nord : je suis devant ;
##   A  une face en AVANT -- meme etage, levre plus au sud : c'est elle qui trace ;
##   X  une face d'un AUTRE etage -- de la roche, mais pas de ma paroi ;
##   T  de la TERRE au niveau de ma levre ou plus haut ;
##   b  de la terre plus bas ;
##   .  rien.
##
## ⚠ M ET A SONT LA MEME CHOSE POUR MOI, ET C'EST VOULU : dans les deux cas il y a de la
## roche jusqu'a mon bord et je n'ai rien a tracer. `muet` les reunit a bon droit. Ce qui ne
## doit PAS s'y trouver, c'est T -- de la terre n'est pas de la roche.
func _flank_kind(heights: PackedStringArray, lips: Array, visible: Dictionary,
		at: Vector2i, level: int, my_lip: int) -> String:
	# ⚠ LES LEVRES SE LISENT GLOBALEMENT, comme le modele les lit depuis le correctif : une
	# face d'un AUTRE etage est de la roche comme une autre, et ce qui la situe est SA LEVRE,
	# pas son etage. Ce detecteur les lisait par etage -- il etait perime par le correctif
	# qu'il avait lui-meme fait trouver.
	var book: Dictionary = lips[0]
	if book.has(at):
		var lip: int = int((book[at] as Vector2i).y)
		if lip == my_lip:
			return "M"
		return "D" if lip < my_lip else "A"
	var ground: int = HeightMask.level_at(heights, at.x, at.y)
	if ground < 0:
		return "."
	return "T" if ground >= level else "b"


## Les levres de chaque etage : case couverte -> rangee de la levre. Meme premiere passe que
## `Walls.assemble`, la geometrie avant la pose.
func _lips(heights: PackedStringArray) -> Array:
	var out: Array = []
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var book: Dictionary = {}
	for level: int in range(0, HeightMask.top_level(heights) + 1):
		for y: int in range(height):
			for x: int in range(width):
				if HeightMask.level_at(heights, x, y) < level:
					continue
				if HeightMask.level_at(heights, x, y + 1) >= level:
					continue
				var fall: Vector2i = Walls.fall_at(heights, level, Vector2i(x, y))
				for step: int in range(1, fall.x + 1):
					var covered: Vector2i = Vector2i(x, y + step)
					if not book.has(covered) or int((book[covered] as Vector2i).x) < level:
						book[covered] = Vector2i(level, y)
	out.append(book)
	return out


func _gather_robes(heights: PackedStringArray, label: String, book: Dictionary) -> void:
	var lips: Array = _lips(heights)
	var visible: Dictionary = Walls.visible_roles(heights)
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	for key: Vector3i in roles:
		var level: int = key.z
		var at: Vector2i = Vector2i(key.x, key.y)
		var mine: Dictionary = lips[level]
		if not mine.has(at):
			continue
		var my_lip: int = int((mine[at] as Vector2i).y)
		var role: Vector2i = roles[key]
		var fiche: String = _flank_kind(heights, lips, visible, at + Vector2i.LEFT, level,
				my_lip) + _flank_kind(heights, lips, visible, at + Vector2i.RIGHT, level,
				my_lip)
		if not book.has(role):
			book[role] = {}
		var seen: Dictionary = book[role]
		seen[fiche] = int(seen.get(fiche, 0)) + 1


func _initialize() -> void:
	var book: Dictionary = {}
	_gather(HeightMask.read(Modes.guide_path(Modes.EPAIS)), "guide", book)
	for family: StringName in Families.ids():
		_gather(ProofScene.relief(family), "preuve", book)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260825
	var drawn: int = 0
	for _t: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if relief.is_empty():
			continue
		drawn += 1
		_gather(relief, "hasard %d" % drawn, book)

	print("ACCORD DES OCCURRENCES — guide, planches de preuve, %d reliefs epais" % drawn)
	print("")
	var cardinal_faults: Array[String] = []
	var diagonal_only: int = 0
	var agreed: int = 0
	for tile: int in book:
		var seen: Dictionary = book[tile]
		var cardinals: Dictionary = {}
		for fiche: String in seen:
			cardinals[String(fiche).substr(0, 4)] = true
		if cardinals.size() > 1:
			var parts: Array[String] = []
			for fiche: String in seen:
				parts.append("%s x%d" % [String(fiche).substr(0, 4),
						int((seen[fiche] as Array)[1])])
			cardinal_faults.append("   silhouette %3d [%s] : %s"
					% [tile, "",
					", ".join(parts)])
		elif seen.size() > 1:
			diagonal_only += 1
		else:
			agreed += 1

	print("CARDINAUX — c'est le contrat, une divergence est un DEFAUT DU VOCABULAIRE.")
	if cardinal_faults.is_empty():
		print("   aucune. Les %d tuiles rencontrees disent la meme chose a leurs quatre"
				% book.size())
		print("   cardinaux, partout ou elles se posent.")
	else:
		cardinal_faults.sort()
		for line: String in cardinal_faults:
			print(line)
		print("   %d tuiles fautives." % cardinal_faults.size())
	print("")
	print("DIAGONALES — relevees, pas jugees : un coin decoupe laisse voir l'empilement.")
	print("   %d tuiles ne divergent que sur leurs diagonales, %d ne divergent pas du tout."
			% [diagonal_only, agreed])
	print("")
	# ⚠ ET ON DIT SUR QUOI, PAS SEULEMENT COMBIEN. Une divergence de diagonale n'est une
	# faute que si le COIN de la tuile montre quelque chose qui en depend. Le detecteur ne
	# tranche pas : il nomme, et c'est en le lisant qu'on decide.
	var lines: Array[String] = []
	for tile: int in book:
		var seen: Dictionary = book[tile]
		var corners: Dictionary = {}
		for fiche: String in seen:
			var tail: String = String(fiche).substr(4)
			corners[tail] = int(corners.get(tail, 0)) + int((seen[fiche] as Array)[1])
		if corners.size() < 2:
			continue
		var parts: Array[String] = []
		var order: Array = corners.keys()
		order.sort()
		for tail: String in order:
			parts.append("%s x%d" % [tail, int(corners[tail])])
		lines.append("   %3d [%-14s] cardinaux %s | coins NE SE SO NO : %s"
				% [tile, "",
				String(seen.keys()[0]).substr(0, 4), ", ".join(parts)])
	lines.sort()
	for line: String in lines.slice(0, mini(26, lines.size())):
		print(line)
	if lines.size() > 26:
		print("   ... et %d autres" % (lines.size() - 26))
	print("")
	print("%d tuiles rencontrees sur les %d du vocabulaire."
			% [book.size(), Thickness.SURFACE_INDICES.size()])
	# --- LES ROBES.
	var robes: Dictionary = {}
	_gather_robes(HeightMask.read(Modes.guide_path(Modes.EPAIS)), "guide", robes)
	for family: StringName in Families.ids():
		_gather_robes(ProofScene.relief(family), "preuve", robes)
	rng.seed = 20260825
	for _t: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if not relief.is_empty():
			_gather_robes(relief, "hasard", robes)

	print("")
	print("ROBES — le PAN recouvre-t-il tout ce qui peut etre a cote d'une face ?")
	var robe_faults: Array[String] = []
	for role: Vector2i in robes:
		var seen: Dictionary = robes[role]
		# On ne compare pas les fiches brutes : `M` et `A` sont la meme chose pour la tuile
		# -- de la roche jusqu'a mon bord, rien a tracer -- et le pan a raison de les reunir.
		var classes: Dictionary = {}
		for fiche: String in seen:
			# ⚠ ET `T`, `b`, `.` SE REPLIENT AUSSI : de la terre a mon niveau, de la terre plus
			# bas, le vide -- aucun des trois n'est de la ROCHE. Ma face s'arrete pareil dans
			# les trois cas, et ce qu'il y a au-dela n'est pas ma case. `vide` a raison de les
			# reunir. Ce qui reste apres ces deux repliements est la vraie divergence.
			var folded: String = String(fiche).replace("A", "M").replace("T", ".") 					.replace("b", ".")
			classes[folded] = int(classes.get(folded, 0)) + int(seen[fiche])
		if classes.size() < 2:
			continue
		var parts: Array[String] = []
		var order: Array = classes.keys()
		order.sort()
		for folded: String in order:
			parts.append("%s x%d" % [folded, int(classes[folded])])
		robe_faults.append("   %-34s : %s" % [Walls.role_name(role), ", ".join(parts)])
	if robe_faults.is_empty():
		print("   aucune. Les %d roles rencontres voient la MEME espece de chose a chacun de"
				% robes.size())
		print("   leurs deux flancs, partout ou ils se posent.")
	else:
		robe_faults.sort()
		for line: String in robe_faults.slice(0, mini(20, robe_faults.size())):
			print(line)
		print("   %d roles fautifs." % robe_faults.size())
	print("")
	print("%d roles rencontres sur les %d du vocabulaire."
			% [robes.size(), Thickness.wall_roles().size()])
	quit(1 if not cardinal_faults.is_empty() or not robe_faults.is_empty() else 0)
