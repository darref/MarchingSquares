# CE QUE LA JUPE DU BORD DU MONDE LIVRE, ET QUE LE PINCEAU N'ATTEINT PAS.
#
# ⚠ LE CARNET RANGE `Massifs.visible`, LE VOCABULAIRE SORT DE `Massifs.paintable`, ET LES DEUX
# NE VOIENT PAS LA MEME CHOSE. `paintable` efface l'etage 0 -- « l'etage 0 est du decor : il
# recoit le temps reel, il ne prend pas le crayon » -- mais il reste dans les groupes de
# jumelles, donc le guide LIVRE ses tuiles. Tant que chacune est portee ailleurs par un massif,
# une jumelle la peint et personne ne s'en apercoit. Le jour ou l'une ne l'est plus, la planche
# a un trou que rien ne peut combler : la case existe, le crayon la refuse.
#
# La sonde compte l'ecart, le nomme, et dit pour chaque tuile orpheline si un massif d'etage
# au moins un la porte QUELQUE PART -- c'est-a-dire si c'est le vivier qui est trop petit, ou
# le bord du monde qui fabrique quelque chose d'unique.
#
#     godot --headless --path . --script res://tools/edge_tiles.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Brush := preload("res://core/brush_vocabulary.gd")

const GUIDES: Array[String] = ["res://guides/massifs.txt", "res://guides/terrain.txt"]


func _initialize() -> void:
	var vocab: Dictionary = {}
	for tile: int in Brush.tiles():
		vocab[tile] = true
	print("le vocabulaire livre : %d tuiles" % vocab.size())

	var orphans: Dictionary = {}
	for path: String in GUIDES:
		var world: PackedStringArray = HeightMask.read(path)
		if world.is_empty():
			continue
		var shown: Dictionary = Massifs.visible(world)
		var here: Dictionary = {}
		for cell: Vector2i in shown.keys():
			var tile1: int = int(shown[cell])
			if vocab.has(tile1):
				continue
			here[tile1] = cell
			orphans[tile1] = true
		print("%s : %d cases posees, %d tuile(s) hors vocabulaire"
				% [path, shown.size(), here.size()])
		for tile2: Variant in here.keys():
			print("    %-46s premiere case %s" % [Massifs.describe(int(tile2)),
					here[tile2]])
	if orphans.is_empty():
		print("RIEN N'EST LIVRE QUE LE PINCEAU N'ATTEIGNE.")
		quit(0)
		return

	# ⚠ ET ON DIT LAQUELLE DES DEUX FAUTES C'EST, PARCE QU'ELLES NE SE REPARENT PAS AU MEME
	# ENDROIT -- et un compteur qui les melange envoie chercher au mauvais endroit.
	#
	#   · POSEE A L'ETAGE 0 : le crayon n'y va pas, donc AUCUN geste ne peut la peindre. C'est
	#     une decision de MODELE, jamais un tirage : chercher plus longtemps ne peut rien.
	#   · POSEE A L'ETAGE >= 1 DANS LE GUIDE : l'artiste PEUT la peindre, elle est simplement
	#     absente du vocabulaire -- le guide est bati de temoins soudes, et la soudure fabrique
	#     des jonctions qu'aucun monde du vivier n'avait. C'est le vivier qu'il faut nourrir.
	print("")
	print("OU CHACUNE SE POSE, ET DONC OU ELLE SE REPARE :")
	var deep: Dictionary = {}
	for path1: String in GUIDES:
		var world1: PackedStringArray = HeightMask.read(path1)
		if world1.is_empty():
			continue
		for tile3: Variant in Massifs.paintable(world1).values():
			if orphans.has(int(tile3)):
				deep[int(tile3)] = true
	for tile4: Variant in orphans.keys():
		print("    %-46s %s" % [Massifs.describe(int(tile4)),
				"ETAGE >= 1 dans le guide -- le VIVIER est trop petit" if deep.has(int(tile4))
				else "etage 0 seulement -- le crayon n'y va pas, c'est le MODELE"])
	quit(1)
