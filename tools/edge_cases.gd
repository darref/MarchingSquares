extends SceneTree

## LES CINQ DERNIERES EXTREMITES DE L2 : cas de bordure, ou regle manquante ?
##
## Elles tombent aux rangees 152-153 et 170 d'une planche haute de 174, ce qui SENT le bord du
## monde -- mais « ca sent » n'est pas une mesure. On regarde donc le relief autour de chacune,
## et on repond a une question precise : la case est-elle a portee de la marge de vide, c'est-a-
## dire assez pres du bord pour que ce qui la ferme soit tombe hors du cadre ?
##
## ⚠ LA MARGE VAUT UNE CHUTE ENTIERE. Le dossier l'ecrit : « chaque relief doit declarer son
## bord, et la marge vaut une chute entiere -- trois rangees de vide autour ». Une case dont la
## falaise tomberait au-dela du cadre n'a pas de quoi se fermer, et ce n'est pas un defaut de
## regle : c'est un relief qui manque de place.

const HeightMask := preload("res://core/height_mask.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")

## Les cinq cases relevees par le banc, a L2/F1.
const SUSPECTS: Array[Vector2i] = [
	Vector2i(19, 152), Vector2i(16, 153), Vector2i(19, 153),
	Vector2i(3, 170), Vector2i(82, 170),
]


func _initialize() -> void:
	var board: PackedStringArray = ProofScene.relief(Families.BY_CELL)
	var width: int = HeightMask.width(board)
	var height: int = HeightMask.height(board)
	var roles: Dictionary = Walls.visible(board)["roles"]

	# Jusqu'ou va la matiere ? C'est ca, la marge.
	var last_row: int = -1
	var last_column: int = -1
	var first_column: int = width
	for y: int in range(height):
		for x: int in range(width):
			if HeightMask.level_at(board, x, y) < 0:
				continue
			last_row = maxi(last_row, y)
			last_column = maxi(last_column, x)
			first_column = mini(first_column, x)
	print("planche %d x %d" % [width, height])
	print("  derniere rangee de matiere : %d   (soit %d rangees de vide en dessous)"
			% [last_row, height - 1 - last_row])
	print("  colonnes de matiere : %d a %d   (soit %d et %d de vide de chaque cote)"
			% [first_column, last_column, first_column, width - 1 - last_column])
	print("")

	for cell: Vector2i in SUSPECTS:
		var level: int = HeightMask.level_at(board, cell.x, cell.y)
		var kind: String = "robe" if roles.has(cell) else ("vide" if level < 0 else "surface")
		var below: int = last_row - cell.y
		var side: int = mini(cell.x - first_column, last_column - cell.x)
		print("  %s  niveau %d, %s" % [str(cell), level, kind])
		print("      %d rangee(s) sous elle avant la fin de la matiere, %d colonne(s) du bord"
				% [below, side])
		# Ce qui l'entoure, sur trois rangees : de quoi voir si sa falaise a de la place.
		for dy: int in range(-1, 3):
			var line: String = "      "
			for dx: int in range(-3, 4):
				var here: int = HeightMask.level_at(board, cell.x + dx, cell.y + dy)
				var mark: String = "~" if here < 0 else str(here)
				if roles.has(Vector2i(cell.x + dx, cell.y + dy)):
					mark = mark.to_lower() + "*"
				else:
					mark += " "
				line += mark
			print("%s   %s" % [line, "<-- la case" if dy == 0 else ""])
		print("")
	print("⚠ `*` marque une case couverte par une robe. La colonne du milieu est la case.")
	quit()
