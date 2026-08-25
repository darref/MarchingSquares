# LE BANC DES RACCORDS OBLIGES ET DU MIROIR — ce que le crayon recopie, verifie a plat.
#
# Existe parce que l'utilisateur, en peignant pour de vrai, est tombe sur un aller-retour
# sans issue autour des aretes de falaise : peindre le fond a cote d'une arete « devenait
# herbe » ailleurs et « effacait la terre ». Ce banc repond a deux questions :
#
#   1. Les classes d'egalite de Seams lient-elles UNIQUEMENT ce que le modele prouve ?
#      -- jamais d'un axe a l'autre : un bord haut/bas ne lie que du haut/bas ;
#      -- horizontalement : jamais ailleurs qu'entre deux flancs muets face a face ;
#      -- et la fermeture n'est pas degeneree : elle laisse EXACTEMENT 28 classes.
#
#   ⚠ « JAMAIS D'UN PAN A UN AUTRE » A ETE RETIRE, ET C'EST UNE CORRECTION, PAS UN
#   RELACHEMENT. Le pan d'une colonne CHANGE en descendant : une classe verticale DOIT
#   traverser les pans, sans quoi 33 jonctions de pleine paroi restent hors de toute
#   classe. Ce banc verifiait que Seams ne liait pas trop ; personne ne verifiait qu'il
#   liait assez. Voir `tools/seam_census.gd`, qui compte les jonctions reellement posees.
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
const Families := preload("res://core/families.gd")

## ⚠ MESURE, PAS DECIDEE. Le monde autorise exactement 29 classes independantes sur les
## 25 roles vivants ; la fermeture prudente en laisse 28. Le chiffre est ici pour qu'un
## sur-joint accidentel se voie -- une classe perdue est une liberte perdue.
const EXPECTED_CLASSES: int = 28

var _failures: int = 0


func _check(ok: bool, label: String) -> void:
	print(("  OK     " if ok else "  ECHEC  ") + label)
	if not ok:
		_failures += 1


func _pan_name(pan: int) -> String:
	return "(%s,%s)" % [Walls.SIDE_NAMES[Walls.pan_west(pan)],
			Walls.SIDE_NAMES[Walls.pan_east(pan)]]


func _initialize() -> void:
	# 1a. Les axes ne se melangent pas : un bord haut/bas ne lie que du haut/bas.
	var axes_pure: bool = true
	for edge: Vector3i in Seams.GROUPS.keys():
		var upright: bool = edge.z == Seams.TOP or edge.z == Seams.BOTTOM
		for other: Vector3i in Seams.GROUPS[edge]:
			var other_upright: bool = other.z == Seams.TOP or other.z == Seams.BOTTOM
			if upright != other_upright:
				axes_pure = false
				print("    fuite d'axe : %s %s -> %s %s" % [_pan_name(edge.x),
						Walls.ROW_NAMES[edge.y], _pan_name(other.x), Walls.ROW_NAMES[other.y]])
	_check(axes_pure, "une classe ne melange jamais les deux axes")

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
			if own_flank != Walls.SIDE_MUTE or other_flank != Walls.SIDE_MUTE:
				horizontal_pure = false
	_check(horizontal_pure, "horizontalement, uniquement muet contre muet")

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
	var stays_upright: bool = true
	for echo: Vector4i in echoes.slice(0, mini(12, echoes.size())):
		print("    %s %-10s pixel (%d, %d)" % [_pan_name(echo.x),
				Walls.ROW_NAMES[echo.y], echo.z, echo.w])
	if echoes.size() > 12:
		print("    ... et %d autres" % (echoes.size() - 12))
	for echo: Vector4i in echoes:
		if echo.w != 0 and echo.w != 15:
			stays_upright = false
	_check(stays_upright, "l'echo d'un bord bas ne touche que des bords haut")
	# ⚠ ET LE FLANC D'ARETE, LUI, N'ECRIT NULLE PART. C'est la propriete qui compte pour
	# l'artiste : la ou une arete est ATTENDUE, il peint librement.
	var flank_free: bool = Seams.mirrors(arete, 15, 8, 16).is_empty()
	_check(flank_free, "un pixel de flanc `devant` n'oblige rien ailleurs")

	# 4. La fermeture n'est pas degeneree. Sur-joindre est SUR, mais tout joindre rendrait
	# le tileset impeignable -- et un banc qui ne verifie que « assez lie » passerait au
	# vert sur une seule classe. Le compte est celui des roles VIVANTS du mode epais.
	var live: Array[Vector2i] = Families.wall_roles()
	var seat: Dictionary = {}
	for role: Vector2i in live:
		for side: int in range(4):
			seat[Vector3i(role.x, role.y, side)] = true
	var roots: Dictionary = {}
	for edge: Vector3i in seat:
		var best: Vector3i = edge
		for other: Vector3i in (Seams.GROUPS[edge] as Array):
			if seat.has(other) and (other.x < best.x or (other.x == best.x
					and (other.y < best.y or (other.y == best.y and other.z < best.z)))):
				best = other
		roots[best] = true
	print("")
	print("  %d roles vivants, %d bords, %d classes independantes."
			% [live.size(), seat.size(), roots.size()])
	_check(roots.size() == EXPECTED_CLASSES,
			"la fermeture laisse %d classes, pas une de moins" % EXPECTED_CLASSES)

	print("")
	print("BANC DES RACCORDS : %d echec(s)." % _failures)
	quit(0 if _failures == 0 else 1)
