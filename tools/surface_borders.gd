# LES QUATRE CARDINAUX D'UNE SURFACE, ET CE QUE LA CLE EN DIT.
#
# Question de l'utilisateur (06/09) : une fois le cisaillement NORD ajoute, la surface sera-t-elle
# bordee ENTIEREMENT, aux quatre cardinaux, quelles que soient sa forme et sa taille ?
#
# ⚠ ON NE LE RAISONNE PAS, ON LE MESURE -- ET DANS LE SENS QUI ATTRAPE. La question n'est pas
# « le modele a-t-il un bit pour chaque cote » : c'est « DEUX SITUATIONS DIFFERENTES RENDENT-ELLES
# LA MEME CLE ». Si oui, un seul dessin doit servir aux deux, et l'un des deux est faux -- c'est
# exactement ainsi que le cisaillement d'origine avait ete trouve.
#
# Pour chaque case de SURFACE, on releve sa SITUATION : aux quatre cardinaux, ce qu'il y a dans
# l'empreinte de son propre massif -- de la surface, de la roche, ou rien. Puis on groupe par cle.
# Une cle qui porte plusieurs situations est un bord MUET.
#
#     godot --headless --path . --script res://tools/surface_borders.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Lab := preload("res://tools/relief_lab.gd")

## Ce qu'un cardinal peut avoir en face, dans l'empreinte du MEME massif.
const HERBE: int = 0
const ROCHE: int = 1
const RIEN: int = 2
const FACE: Array[String] = ["herbe", "roche", "rien"]
## ⚠ LES HUIT, PAS LES QUATRE. Une bordure n'est pas quatre cotes : c'est un ANNEAU DEFORME
## CONTINU (formulation de l'utilisateur, 06/09), et un anneau passe par les COINS. Un cardinal
## muet coupe le trait ; une diagonale muette l'empeche de TOURNER.
const WAYS: Array[Vector2i] = [Vector2i.UP, Vector2i(1, -1), Vector2i.RIGHT, Vector2i(1, 1),
		Vector2i.DOWN, Vector2i(-1, 1), Vector2i.LEFT, Vector2i(-1, -1)]
const NAMES: Array[String] = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]


func _initialize() -> void:
	var worlds: Array[PackedStringArray] = []
	worlds.append(HeightMask.read("res://guides/massifs.txt"))
	for one: PackedStringArray in Lab.ground():
		worlds.append(one)

	# cle -> { situation -> nombre }
	var by_key: Dictionary = {}
	var where: Dictionary = {}
	for index: int in range(worlds.size()):
		var world: PackedStringArray = worlds[index]
		if world.is_empty():
			continue
		# ⚠ Une carte couteuse ne se recalcule pas a chaque tour de boucle.
		var key_of: Dictionary = {}
		for pose: Dictionary in Massifs.poses(world):
			var at: Vector2i = pose["cell"]
			key_of[Vector3i(at.x, at.y, int(pose["massif"]))] = Massifs.key_of(pose)
		var made: Dictionary = Massifs.of(world)
		var groups: Array = made["cells"]
		var levels: Array[int] = made["level"]
		for mark: int in range(groups.size()):
			var print_of: Dictionary = Massifs.footprint(world, groups[mark] as Array,
					levels[mark])
			for cell: Vector2i in print_of.keys():
				if int(print_of[cell]) != Massifs.SURFACE:
					continue
				var tile: int = int(key_of.get(Vector3i(cell.x, cell.y, mark), -1))
				if tile < 0:
					continue
				var shape: String = _situation(print_of, cell)
				if not by_key.has(tile):
					by_key[tile] = {}
				var tally: Dictionary = by_key[tile]
				tally[shape] = int(tally.get(shape, 0)) + 1
				if not where.has("%d/%s" % [tile, shape]):
					where["%d/%s" % [tile, shape]] = "monde %d, case %d,%d" % [index, cell.x,
							cell.y]

	var mute: Array[int] = []
	for tile2: Variant in by_key.keys():
		if (by_key[tile2] as Dictionary).size() > 1:
			mute.append(int(tile2))
	mute.sort()

	print("%d mondes, %d cles de surface relevees" % [worlds.size(), by_key.size()])
	print("")
	if mute.is_empty():
		print("AUCUN BORD MUET : chaque cle de surface ne se pose que dans UNE situation.")
		print("La surface est donc bordee aux quatre cardinaux, quelles que soient sa forme")
		print("et sa taille -- sur ces mondes.")
		quit(0)
	# ⚠ ET ON DIT QUELLE DIRECTION EST MUETTE, pas seulement combien. « Onze cles fautives »
	# n'oriente aucun travail ; « le sud, et il est trace par le chapiteau d'en dessous » en
	# oriente un.
	var blame: Dictionary = {}
	for tile4: int in mute:
		var seen_faces: Dictionary = {}
		for shape4: Variant in (by_key[tile4] as Dictionary).keys():
			for piece: String in String(shape4).split(" "):
				var bits: PackedStringArray = piece.split("=")
				if not seen_faces.has(bits[0]):
					seen_faces[bits[0]] = {}
				(seen_faces[bits[0]] as Dictionary)[bits[1]] = true
		for way: Variant in seen_faces.keys():
			if (seen_faces[way] as Dictionary).size() > 1:
				blame[String(way)] = int(blame.get(String(way), 0)) + 1
	print("LA DIRECTION QUI VARIE SOUS UNE MEME CLE :")
	for name: String in NAMES:
		if blame.has(name):
			print("    %-3s  %d cle(s)" % [name, int(blame[name])])
	print("")
	print("CLES QUI SERVENT A PLUSIEURS SITUATIONS : %d" % mute.size())
	print("(nord/est/sud/ouest, tels qu'ils sont dans l'empreinte du massif)")
	for tile3: int in mute:
		print("")
		print("  %d  %s" % [tile3, Massifs.describe(tile3)])
		var tally2: Dictionary = by_key[tile3]
		var shapes: Array[String] = []
		for shape2: Variant in tally2.keys():
			shapes.append(String(shape2))
		shapes.sort()
		for shape3: String in shapes:
			print("      %-28s %8d fois   (%s)" % [shape3, int(tally2[shape3]),
					String(where["%d/%s" % [tile3, shape3]])])
	quit(0)


## Ce qu'il y a aux quatre cardinaux, DANS L'EMPREINTE DE CE MASSIF -- jamais sur ce qui se voit :
## l'identite d'une tuile ne depend pas de ce qu'on pose dessus.
static func _situation(print_of: Dictionary, cell: Vector2i) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for index: int in range(WAYS.size()):
		var near: Vector2i = cell + WAYS[index]
		var face: int = RIEN
		if print_of.has(near):
			face = HERBE if int(print_of[near]) == Massifs.SURFACE else ROCHE
		parts.append("%s=%s" % [NAMES[index], FACE[face]])
	return " ".join(parts)
