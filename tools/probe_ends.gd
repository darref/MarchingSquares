extends SceneTree

## SONDE : ce que le modele dit autour d'une case, pour lire une extremite au pixel.
##
##     godot --headless --path . --script res://tools/probe_ends.gd -- x0 y0 largeur hauteur
##
## ⚠ `Walls.visible()` REND SES ROLES KEYES PAR Vector2i, pas par Vector3i -- c'est
## `assemble()` qui porte l'etage de la levre dans la cle. Lire l'un pour l'autre fait une
## erreur de type dans `_initialize`, donc pas de `quit()`, donc une boucle principale sans
## fin : le programme tourne sans rien dire. Une heure payee.

const HeightMask := preload("res://core/height_mask.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")

const MARGIN: int = 6


func _initialize() -> void:
	var relief: PackedStringArray = ProofScene.relief(Families.BY_CELL)
	var width: int = HeightMask.width(relief)
	var empty: String = ""
	for x: int in range(width):
		empty += "~"
	for row: int in range(MARGIN):
		relief.append(empty)
	var roles: Dictionary = Walls.visible(relief)["roles"]
	var under: Dictionary = Walls.visible_underfoot(relief)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var x0: int = int(args[0])
	var y0: int = int(args[1])
	var w: int = int(args[2])
	var h: int = int(args[3])
	var head: String = "      "
	for x: int in range(x0, x0 + w):
		head += _pad("x=" + str(x))
	print(head)
	for y: int in range(y0, y0 + h):
		var line: String = _pad(str(y)).substr(0, 6)
		for x: int in range(x0, x0 + w):
			var cell: Vector2i = Vector2i(x, y)
			var lvl: int = HeightMask.level_at(relief, x, y)
			var said: String = ("n" + str(lvl)) if lvl >= 0 else "~"
			if roles.has(cell):
				var r: Vector2i = roles[cell]
				said += " R" + str(r.x) + "." + str(r.y)
			if under.has(cell):
				var u: Vector2i = under[cell]
				said += " U" + str(u.x) + "." + str(u.y)
			line += _pad(said)
		print(line)
	print("")
	print("rangees : chapiteau=" + str(Walls.ROW_CROWN) + "  corps=1.." + str(Walls.BODY_ROWS)
			+ "  pied=" + str(Walls.ROW_FOOT) + "   pans=" + str(Walls.PAN_COUNT)
			+ " (ouest*2+est, arret=0 continue=1)")
	quit()


func _pad(text: String) -> String:
	var out: String = text
	while out.length() < 12:
		out += " "
	return out
