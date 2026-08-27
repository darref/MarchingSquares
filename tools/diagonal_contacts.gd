extends SceneTree

## LES CONTACTS DIAGONAUX : deux blocs qui ne se touchent que par un coin.
##
## Question posee sur une capture d'ecran : ces specimens montrent-ils un coude d'UNE tuile
## d'epaisseur ? Le pinceau pose des tampons 3x3 et efface par 3x3 au moins ; un coude fin ne
## serait pas produisible.
##
## ⚠ ET LE CONTACT DIAGONAL N'EST PAS UN COUDE. Un coude RELIE deux bras par des cases ; un
## contact diagonal ne relie rien -- les deux blocs se touchent en un POINT, il n'y a aucune
## case entre eux. Aucune course n'y est raccourcie, donc l'epaisseur est intacte. C'est un
## accident voulu (`accidents.contact_diagonal`), et il existe parce que le reseau dual a une
## tuile pour ca -- celle que la canonicalisation du blob JETTE.
##
## On le montre plutot que de l'affirmer : chaque contact trouve est dumpe avec son voisinage.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")


## LES COUDES : deux cardinaux adjacents, et la diagonale entre eux VIDE. C'est l'accident du
## « moulin », et il y en a quatre au guide -- ce qui colle au compte de la capture d'ecran.
## La question est de savoir si ses bras font UNE case ou TROIS.
func _elbows(relief: PackedStringArray) -> void:
	var width: int = HeightMask.width(relief)
	var height: int = HeightMask.height(relief)
	var top: int = 0
	for y: int in range(height):
		for x: int in range(width):
			top = maxi(top, HeightMask.level_at(relief, x, y))
	var seen: Dictionary = {}
	for storey: int in range(top + 1):
		for y: int in range(height):
			for x: int in range(width):
				if not _filled(relief, x, y, storey):
					continue
				for corner: int in range(4):
					var a: Vector2i = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN,
							Vector2i.LEFT][corner]
					var b: Vector2i = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,
							Vector2i.UP][corner]
					if not _filled(relief, x + a.x, y + a.y, storey):
						continue
					if not _filled(relief, x + b.x, y + b.y, storey):
						continue
					if _filled(relief, x + a.x + b.x, y + a.y + b.y, storey):
						continue
					seen[Vector3i(x, y, storey)] = true
	print("=== les coudes du guide : %d ===" % seen.size())
	var shown: int = 0
	for key: Vector3i in seen.keys():
		if shown >= 2:
			break
		shown += 1
		print("  coude en (%d,%d), etage %d :" % [key.x, key.y, key.z])
		for dy: int in range(-4, 5):
			var line: String = "      "
			for dx: int in range(-4, 5):
				var mark: String = "#" if _filled(relief, key.x + dx, key.y + dy, key.z) else "."
				line += "O" if dx == 0 and dy == 0 else mark
			print(line)
	print("")


func _initialize() -> void:
	_elbows(HeightMask.read(Modes.guide_path(Modes.EPAIS)))
	_scan(HeightMask.read(Modes.guide_path(Modes.EPAIS)), "le guide epais")
	_scan(ProofScene.relief(Families.BY_CELL), "la planche de preuve, par case")
	_scan(ProofScene.relief(Families.BY_CORNER), "la planche de preuve, a cheval")
	quit()


func _scan(relief: PackedStringArray, label: String) -> void:
	var width: int = HeightMask.width(relief)
	var height: int = HeightMask.height(relief)
	var top: int = 0
	for y: int in range(height):
		for x: int in range(width):
			top = maxi(top, HeightMask.level_at(relief, x, y))
	var found: Array[Vector3i] = []
	for storey: int in range(top + 1):
		for y: int in range(height):
			for x: int in range(width):
				if not _filled(relief, x, y, storey):
					continue
				# ⚠ LES DEUX DIAGONALES, pas une. Mon premier balayage ne regardait que le
				# coin sud-est : un contact orienté sud-ouest lui echappait entierement.
				for dx: int in [1, -1]:
					if not _filled(relief, x + dx, y + 1, storey):
						continue
					if _filled(relief, x + dx, y, storey) or _filled(relief, x, y + 1, storey):
						continue
					found.append(Vector3i(x, y, storey))
	print("=== %s : %d contact(s) diagonal(aux) ===" % [label, found.size()])
	for i: int in range(mini(found.size(), 3)):
		var at: Vector3i = found[i]
		print("  a l'etage %d, entre (%d,%d) et (%d,%d) :" % [at.z, at.x, at.y, at.x + 1, at.y + 1])
		for dy: int in range(-3, 5):
			var line: String = "      "
			for dx: int in range(-3, 5):
				line += "#" if _filled(relief, at.x + dx, at.y + dy, at.z) else "."
			print(line)
	# ⚠ ET ON DIT SI LE RELIEF EST EPAIS, sans quoi ce qui precede ne prouve rien.
	print("  cases fines dans tout le relief : %d" % Thickness.thin_cells(relief).size())
	print("")


func _filled(relief: PackedStringArray, x: int, y: int, storey: int) -> bool:
	return HeightMask.level_at(relief, x, y) >= storey
