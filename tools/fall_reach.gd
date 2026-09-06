# JUSQU'OU LA CHUTE VA, ET SUR QUOI ELLE POSE SON PIED.
#
# Deux observations de l'utilisateur (06/09), mesurees ici plutot que discutees :
#
#   1. « Quand un massif est devant un autre, tu as mis des tuiles de PIED dans le bas visible
#      de celui qui est derriere, alors qu'il devrait etre dessine EN ENTIER pour qu'avec la
#      transparence il laisse apparaitre ce qui depasse. »
#   2. « Les massifs au ras poses par-dessus la plaine ou un autre massif devraient descendre
#      jusqu'au pied de la falaise -- c'est le seul moyen que le relief soit bien lu. Tous
#      devraient chercher a se prolonger jusqu'au pied de la plaine, sauf quand ils ne le
#      peuvent pas. »
#
# ⚠ CE QUE LE CODE FAIT AUJOURD'HUI : `Massifs.footprint` sonde `HeightMask.level_at(world, ...)`
# -- LE MONDE ENTIER, tous massifs confondus. La face s'arrete donc des qu'elle rencontre du sol
# plus haut (`if ground > bottom: break`), et elle pose son PIED si elle tombe pile dessus. Le
# massif de derriere n'est PAS dessine en entier : il est tronque par ce qu'il y a devant.
#
# ⚠ ET DEUX LOIS DU CARNET S'Y OPPOSENT. « Un massif existe entierement, y compris sous ce qui le
# recouvre : le voisinage d'une tuile ne depend jamais de ce qu'on pose dessus » contre « LA CHUTE
# VA JUSQU'AU SOL QU'ELLE ATTEINT ». La mesure dit combien de cases sont prises entre les deux.
#
#     godot --headless --path . --script res://tools/fall_reach.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Lab := preload("res://tools/relief_lab.gd")


func _initialize() -> void:
	var worlds: Array[PackedStringArray] = []
	worlds.append(HeightMask.read("res://guides/massifs.txt"))
	for one: PackedStringArray in Lab.ground():
		worlds.append(one)

	var lips: int = 0
	var landed_on_plain: int = 0
	var landed_on_massif: int = 0
	var cropped: int = 0
	var into_void: int = 0
	var short_of_plain: int = 0
	var rows_missing: int = 0
	var flush_short: int = 0
	var example_massif: String = ""
	var example_cropped: String = ""

	for index: int in range(worlds.size()):
		var world: PackedStringArray = worlds[index]
		if world.is_empty():
			continue
		var made: Dictionary = Massifs.of(world)
		var groups: Array = made["cells"]
		var levels: Array[int] = made["level"]
		var covers: Array[bool] = made["covers"]
		for mark: int in range(groups.size()):
			var level: int = levels[mark]
			if level < 1:
				continue
			var print_of: Dictionary = Massifs.footprint(world, groups[mark] as Array, level)
			for cell: Variant in (groups[mark] as Array):
				var at: Vector2i = cell as Vector2i
				# Une levre : une case de surface dont le sud n'est pas la surface du massif.
				if print_of.get(at + Vector2i.DOWN, -1) == Massifs.SURFACE:
					continue
				if not print_of.has(at + Vector2i.DOWN):
					continue
				lips += 1
				# Jusqu'ou la face descend AUJOURD'HUI, et ce qu'elle pose en bas.
				var deep: int = 0
				var foot: bool = false
				while print_of.has(at + Vector2i(0, deep + 1)) 						and int(print_of[at + Vector2i(0, deep + 1)]) != Massifs.SURFACE:
					deep += 1
					foot = int(print_of[at + Vector2i(0, deep)]) == Massifs.PIED
				var under: int = HeightMask.level_at(world, at.x, at.y + deep + 1)
				if foot:
					if under <= 0:
						landed_on_plain += 1
					else:
						landed_on_massif += 1
						if example_massif.is_empty():
							example_massif = "monde %d, levre %d,%d -- pied pose sur l'etage %d" 									% [index, at.x, at.y, under]
				elif under < 0:
					into_void += 1
				else:
					cropped += 1
					if example_cropped.is_empty():
						example_cropped = "monde %d, levre %d,%d -- ecretee sur l'etage %d" 								% [index, at.x, at.y, under]
				# ⚠ ET CE QUE LA PROPOSITION COUTERAIT : descendre jusqu'au PIED DE LA PLAINE,
				# c'est-a-dire `FALL * level` rangees, quoi qu'il y ait devant.
				var full: int = Massifs.FALL * level
				if deep < full:
					short_of_plain += 1
					rows_missing += full - deep
					if covers[mark]:
						flush_short += 1

	print("%d mondes, %d levres" % [worlds.size(), lips])
	print("")
	print("CE QUE LA CHUTE FAIT AUJOURD'HUI")
	print("  pied pose sur la PLAINE (ou le vide sous elle) : %d" % landed_on_plain)
	print("  pied pose sur le TOIT D'UN AUTRE MASSIF        : %d   <- observation 1" %
			landed_on_massif)
	if not example_massif.is_empty():
		print("      %s" % example_massif)
	print("  face ECRETEE, sans pied (elle rencontre du sol) : %d" % cropped)
	if not example_cropped.is_empty():
		print("      %s" % example_cropped)
	print("  face qui tombe dans le VIDE, sans pied          : %d" % into_void)
	print("")
	print("CE QUE « DESCENDRE JUSQU'AU PIED DE LA PLAINE » CHANGERAIT")
	print("  levres qui s'arretent AVANT la plaine : %d sur %d" % [short_of_plain, lips])
	print("      dont AU RAS (posees sur autre chose) : %d   <- observation 2" % flush_short)
	print("  rangees de falaise a ajouter en tout   : %d" % rows_missing)
	quit(0)
