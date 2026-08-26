extends SceneTree

## CE QU'UN PIXEL DE BORD ECRIT AILLEURS -- avant et apres la restriction.
const Walls := preload("res://core/walls.gd")
const Seams := preload("res://core/seams.gd")

func _initialize() -> void:
	var a: Vector2i = Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_VOID), 0)
	var b: Vector2i = Vector2i(Walls.pan_of(Walls.SIDE_VOID, Walls.SIDE_MUTE), 0)
	var res: int = 16
	print("A = %s   (6,10)" % Walls.role_name(a))
	print("B = %s   (5,10)" % Walls.role_name(b))
	print("etendue de roche du bord HAUT : A %s   B %s"
			% [str(Seams.rock_span(a, Seams.TOP, res)), str(Seams.rock_span(b, Seams.TOP, res))])
	print("")
	var into_b: int = 0
	var outside_b: int = 0
	var span_b: Vector2i = Seams.rock_span(b, Seams.TOP, res)
	for x: int in range(res):
		for target: Vector4i in Seams.mirrors(a, x, 0, res):
			if Vector2i(target.x, target.y) != b:
				continue
			into_b += 1
			if target.z < span_b.x or target.z > span_b.y:
				outside_b += 1
	print("en remplissant tout le bord HAUT de A :")
	print("   pixels ecrits chez B          : %d" % into_b)
	print("   dont HORS de la roche de B    : %d" % outside_b)
	# ⚠ LE COTE D'UNE DESTINATION SE LIT DE SA POSITION, PAS DE SON `w`. Premiere sonde :
	# je prenais un bord GAUCHE (x=0, y=position) pour un bord HAUT, et je testais son
	# etendue sur la mauvaise coordonnee. Vingt et un mille faux positifs.
	var total: int = 0
	var stray: int = 0
	for role: Vector2i in Walls.ALL_ROLES:
		for x: int in range(res):
			for y: int in range(res):
				if x != 0 and x != res - 1 and y != 0 and y != res - 1:
					continue
				for target: Vector4i in Seams.mirrors(role, x, y, res):
					total += 1
					var other: Vector2i = Vector2i(target.x, target.y)
					var side: int = -1
					var position: int = 0
					if target.w == 0:
						side = Seams.TOP
						position = target.z
					elif target.w == res - 1:
						side = Seams.BOTTOM
						position = target.z
					else:
						continue          # bord lateral : son etendue est pleine
					if not Seams.is_rock(other, side, position, res):
						stray += 1
	print("")
	print("SUR TOUT LE VOCABULAIRE, bords haut et bas :")
	print("   ecritures                      : %d" % total)
	print("   HORS de la roche du destinataire : %d" % stray)
	quit()
