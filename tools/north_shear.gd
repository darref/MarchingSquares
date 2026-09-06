# LE CISAILLEMENT PAR LE NORD : DE LA ROCHE AU-DESSUS DE L'HERBE, DANS LE MEME MASSIF.
#
# ⚠ CE QUE LE MODELE LIT AUJOURD'HUI, ET RIEN D'AUTRE. `Massifs.poses` calcule le cisaillement
# sur deux voisins seulement -- LEFT et RIGHT -- et la bande porte la transition VERTICALE
# descendante (surface -> chapiteau -> corps -> pied). Reste une direction que personne ne lit :
# le voisin du NORD. Une case de SURFACE dont la voisine du dessus est la FALAISE de son propre
# massif ne le sait pas : elle se croit pleine au nord, exactement comme l'herbe se croyait
# pleine a l'ouest avant que le cisaillement n'existe.
#
# ⚠ ET CE N'EST PAS UNE HYPOTHESE GRATUITE : un massif peut avoir PLUSIEURS bords sud dans la
# meme colonne (« une encoche ouverte au sud donne deux bords sud, et chacune porte sa falaise »).
# Quand cette falaise s'arrete juste au-dessus d'une case de surface du meme massif -- la surface
# l'emporte, `footprint` le dit -- la case d'en dessous a de la roche au nord.
#
# La sonde compte l'endroit, pas l'opinion : combien de cases, dans quels mondes, sous quelles
# cles, et si deux situations differentes rendent la MEME cle.
#
#     godot --headless --path . --script res://tools/north_shear.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Lab := preload("res://tools/relief_lab.gd")
const Brush := preload("res://core/brush_vocabulary.gd")


func _initialize() -> void:
	var worlds: Array[PackedStringArray] = []
	worlds.append(HeightMask.read("res://guides/massifs.txt"))
	for one: PackedStringArray in Lab.ground():
		worlds.append(one)
	print("%d mondes : le guide livre, plus le vivier commun" % worlds.size())

	# cle -> {"nord": n, "plein": n} : la MEME cle posee avec et sans roche au nord est la
	# preuve qu'une distinction manque.
	var seen: Dictionary = {}
	var north: int = 0
	var example: Dictionary = {}
	for index: int in range(worlds.size()):
		var world: PackedStringArray = worlds[index]
		if world.is_empty():
			continue
		# ⚠ UNE CARTE COUTEUSE NE SE RECALCULE PAS A CHAQUE TOUR DE BOUCLE : les poses sont
		# tenues UNE FOIS par monde, sous la cle (case, massif). Faute deja payee sept fois.
		var key_of: Dictionary = {}
		for pose: Dictionary in Massifs.poses(world):
			key_of[Vector3i((pose["cell"] as Vector2i).x, (pose["cell"] as Vector2i).y,
					int(pose["massif"]))] = Massifs.key_of(pose)
		var made: Dictionary = Massifs.of(world)
		var groups: Array = made["cells"]
		var levels: Array[int] = made["level"]
		for mark: int in range(groups.size()):
			var print_of: Dictionary = Massifs.footprint(world, groups[mark] as Array,
					levels[mark])
			for cell: Vector2i in print_of.keys():
				if int(print_of[cell]) != Massifs.SURFACE:
					continue
				var above: Vector2i = cell + Vector2i.UP
				# ⚠ ON NE REGARDE QUE L'EMPREINTE DE CE MASSIF : une voisine qui s'y trouve est
				# du meme massif par construction, et c'est la seule lecture que le modele
				# s'autorise.
				if not print_of.has(above):
					continue
				var rock: bool = int(print_of[above]) != Massifs.SURFACE
				var tile: int = int(key_of.get(Vector3i(cell.x, cell.y, mark), -1))
				if not seen.has(tile):
					seen[tile] = {"nord": 0, "plein": 0}
				var tally: Dictionary = seen[tile]
				if rock:
					tally["nord"] = int(tally["nord"]) + 1
					north += 1
					if not example.has(tile):
						example[tile] = "monde %d, case %d,%d" % [index, cell.x, cell.y]
				else:
					tally["plein"] = int(tally["plein"]) + 1

	print("")
	print("cases de SURFACE avec de la ROCHE DU MEME MASSIF au nord : %d" % north)
	if north == 0:
		print("  le cas n'existe pas dans ces mondes -- rien ne manque de ce cote")
		quit(0)

	# ⚠ LA QUESTION N'EST PAS « LE CAS EXISTE-T-IL », C'EST « DEUX SITUATIONS DIFFERENTES
	# RENDENT-ELLES LA MEME CLE ». Si une cle se pose tantot avec de la roche au nord, tantot
	# sans, alors UN SEUL DESSIN doit servir aux deux -- et l'un des deux sera faux.
	var clashing: Array[int] = []
	var only_north: Array[int] = []
	for tile2: Variant in seen.keys():
		var tally2: Dictionary = seen[tile2]
		if int(tally2["nord"]) == 0:
			continue
		if int(tally2["plein"]) > 0:
			clashing.append(int(tile2))
		else:
			only_north.append(int(tile2))
	clashing.sort()
	only_north.sort()

	print("")
	print("LES CLES QUI SERVENT AUX DEUX SITUATIONS : %d" % clashing.size())
	for tile3: int in clashing:
		var tally3: Dictionary = seen[tile3]
		print("  %d  %s" % [tile3, Massifs.describe(tile3)])
		print("      %d fois avec de la roche au nord, %d fois sans  (%s)"
				% [int(tally3["nord"]), int(tally3["plein"]), String(example[tile3])])
	print("")
	print("LES CLES QU'ON NE VOIT QU'AVEC DE LA ROCHE AU NORD : %d" % only_north.size())
	for tile4: int in only_north:
		print("  %d  %s  (%s)" % [tile4, Massifs.describe(tile4), String(example[tile4])])

	# ⚠ CE QUE COUTERAIT LE BIT, MESURE PLUTOT QU'ESTIME. Un `CUT_NORTH` ne double pas le
	# vocabulaire : il ne separe que les cles reellement posees DANS LES DEUX SITUATIONS --
	# les autres gardent leur unique sens. Le compte ci-dessous est donc le prix exact sur ces
	# mondes, et un PLANCHER ailleurs : une battue prouve la presence, jamais l'absence.
	var vocab: Dictionary = {}
	for tile5: Variant in Brush.tiles():
		vocab[int(tile5)] = true
	var touched: int = 0
	for tile6: int in clashing:
		if vocab.has(tile6):
			touched += 1
	print("")
	print("LE PRIX D'UN BIT `CUT_NORTH`, SUR CES MONDES :")
	print("  %d cle(s) du vocabulaire livre se dedoubleraient : %d -> %d tuiles"
			% [touched, vocab.size(), vocab.size() + touched])
	for tile7: int in clashing:
		if vocab.has(tile7):
			print("      %d  %s" % [tile7, Massifs.describe(tile7)])
	quit(0)
