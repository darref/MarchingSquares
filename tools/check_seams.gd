# LE BANC DES RACCORDS OBLIGES ET DU MIROIR — ce que le crayon recopie, verifie a plat.
#
# Existe parce que l'utilisateur, en peignant pour de vrai, est tombe sur un aller-retour
# sans issue autour des aretes de falaise : peindre le fond a cote d'une arete « devenait
# herbe » ailleurs et « effacait la terre ». Ce banc repond a deux questions :
#
#   1. Les classes d'egalite de Seams lient-elles UNIQUEMENT ce que le modele prouve ?
#      -- verticalement : jamais d'un pan a un autre ;
#      -- horizontalement : jamais ailleurs qu'entre deux flancs muets face a face.
#   2. Le miroir des robes echange-t-il exactement les deux flancs, pixels retournes ?
#
# Puis il REJOUE le geste : un pixel pose au bord de la bande d'arete, et la liste
# complete de ce que l'echo recopie -- pour dire a l'artiste OU son herbe est allee.
#
#     godot --headless --path . --script res://tools/check_seams.gd
extends SceneTree

const Walls := preload("res://core/walls.gd")
const Seams := preload("res://core/seams.gd")
const Symmetry := preload("res://core/symmetry.gd")

var _failures: int = 0


func _check(ok: bool, label: String) -> void:
	print(("  OK     " if ok else "  ECHEC  ") + label)
	if not ok:
		_failures += 1


func _pan_name(pan: int) -> String:
	return "(%s,%s)" % [Walls.SIDE_NAMES[Walls.pan_west(pan)],
			Walls.SIDE_NAMES[Walls.pan_east(pan)]]


func _initialize() -> void:
	# 1a. Verticalement : une classe de haut/bas ne quitte JAMAIS son pan.
	var vertical_pure: bool = true
	for edge: Vector3i in Seams.GROUPS.keys():
		if edge.z != Seams.TOP and edge.z != Seams.BOTTOM:
			continue
		for other: Vector3i in Seams.GROUPS[edge]:
			if other.x != edge.x:
				vertical_pure = false
				print("    fuite verticale : %s %s -> %s %s" % [_pan_name(edge.x),
						Walls.ROW_NAMES[edge.y], _pan_name(other.x), Walls.ROW_NAMES[other.y]])
	_check(vertical_pure, "verticalement, une classe reste dans son pan")

	# 1b. Horizontalement : chaque lien est muet-muet, a la meme rangee, et rien d'autre.
	var horizontal_pure: bool = true
	for edge: Vector3i in Seams.GROUPS.keys():
		if edge.z != Seams.LEFT and edge.z != Seams.RIGHT:
			continue
		var own_flank: int = Walls.pan_west(edge.x) if edge.z == Seams.LEFT \
				else Walls.pan_east(edge.x)
		for other: Vector3i in Seams.GROUPS[edge]:
			var other_flank: int = Walls.pan_west(other.x) if other.z == Seams.LEFT \
					else Walls.pan_east(other.x)
			if own_flank != Walls.SIDE_MUTE or other_flank != Walls.SIDE_MUTE \
					or other.y != edge.y:
				horizontal_pure = false
	_check(horizontal_pure, "horizontalement, uniquement muet-muet, a rangee egale")

	# 1c. Les flancs d'arete (devant) et de bord (vide) sont LIBRES : aucun echo lateral.
	var free_flanks: bool = true
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			if Walls.pan_east(pan) != Walls.SIDE_MUTE \
					and not (Seams.GROUPS[Vector3i(pan, row, Seams.RIGHT)] as Array).is_empty():
				free_flanks = false
			if Walls.pan_west(pan) != Walls.SIDE_MUTE \
					and not (Seams.GROUPS[Vector3i(pan, row, Seams.LEFT)] as Array).is_empty():
				free_flanks = false
	_check(free_flanks, "un flanc devant ou vide n'oblige rien lateralement")

	# 2. Le miroir : involution, flancs echanges, pixels retournes en x seulement.
	var mirror_sane: bool = true
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			var role: Vector2i = Vector2i(pan, row)
			var twin: Vector2i = Symmetry.mirror_role(role)
			if Symmetry.mirror_role(twin) != role or twin.y != row:
				mirror_sane = false
			if Walls.pan_west(twin.x) != Walls.pan_east(pan) \
					or Walls.pan_east(twin.x) != Walls.pan_west(pan):
				mirror_sane = false
	for x: int in range(16):
		for y: int in range(16):
			var moved: Vector2i = Symmetry.transform_pixel(x, y, 16, Symmetry.MIRROR)
			if moved != Vector2i(15 - x, y):
				mirror_sane = false
	_check(mirror_sane, "le miroir echange les flancs et retourne x, rien d'autre")

	# 3. Le geste rejoue : un pixel au bord bas de la bande d'arete, pan (muet, devant),
	# corps 0 -- et tout ce que l'echo recopie.
	var arete: Vector2i = Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_FRONT), 1)
	print("")
	print("pixel (14, 15) de %s %s -- l'echo recopie vers :" % [_pan_name(arete.x),
			Walls.ROW_NAMES[arete.y]])
	var echoes: Array[Vector4i] = Seams.mirrors(arete, 14, 15, 16)
	var stays_in_pan: bool = true
	for echo: Vector4i in echoes:
		print("    %s %-10s pixel (%d, %d)" % [_pan_name(echo.x),
				Walls.ROW_NAMES[echo.y], echo.z, echo.w])
		if echo.x != arete.x:
			stays_in_pan = false
	_check(stays_in_pan, "l'echo d'un bord haut/bas reste dans le pan de l'arete")
	var corner: Array[Vector4i] = Seams.mirrors(arete, 15, 15, 16)
	var corner_in_pan: bool = true
	for echo: Vector4i in corner:
		if echo.x != arete.x:
			corner_in_pan = false
			print("    coin (15,15) fuit vers %s %s (%d, %d)" % [_pan_name(echo.x),
					Walls.ROW_NAMES[echo.y], echo.z, echo.w])
	_check(corner_in_pan, "le coin (15,15) de l'arete reste aussi dans son pan")

	print("")
	print("BANC DES RACCORDS : %d echec(s)." % _failures)
	quit(0 if _failures == 0 else 1)
