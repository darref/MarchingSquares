extends SceneTree

## LE PRIX DE DEDOUBLER `vide` -- mesure avant de toucher au modele.
##
## LE DEFAUT, DESIGNE CASE PAR CASE. `(6,10)` et `(18,10)` portent la meme tuile
## `muet|vide / chapiteau`, et derriere leur flanc est il n'y a pas la meme chose : chez l'un
## le PLATEAU au niveau de la levre -- de la terre a ma hauteur, ma roche finit contre elle --
## chez l'autre le SOL un etage plus bas, et ma roche est surelevee, elle doit montrer sa
## tranche. Mesure : 28 flancs `vide` sur 29 voient deux especes ou plus.
##
## LE CORRECTIF : `vide` devient deux etats.
##   `vide_haut` -- du terrain SURELEVE a cote (au niveau de ma levre ou au-dessus) ;
##   `vide_bas`  -- rien de sureleve : le sol d'en bas, ou le hors-monde.
##
## ⚠ ET `sol` ET `dehors` RESTENT CONFONDUS, ce qui divise le prix par deux. Dans les deux cas
## il n'y a rien de sureleve a cote de moi, et ma tuile fait la meme chose ; ce qui est peint
## la-bas appartient a la tuile du voisin, pas a la mienne.
##
## On compte donc : avec quatre etats de flanc au lieu de trois, combien de roles le monde
## produit-il vraiment ? 16 pans x 5 rangees = 80 au plus -- mais la plupart ne sont surement
## pas realisables, comme les 9 pans d'aujourd'hui n'en font que 44.

const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")

## Les quatre etats, dans l'ordre ou on les nommera.
const MUTE: int = 0
const FRONT: int = 1
const VOID_HIGH: int = 2
const VOID_LOW: int = 3
const STATE_NAMES: Array[String] = ["muet", "devant", "vide_haut", "vide_bas"]


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var seen: Dictionary = {}
	var old_seen: Dictionary = {}
	var scanned: int = 0
	var cells: int = 0
	for round: int in range(3000):
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		scanned += 1
		for entry: Array in _read(relief):
			cells += 1
			seen[entry[0]] = int(seen.get(entry[0], 0)) + 1
			old_seen[entry[1]] = true
	# Et le guide livre, qui n'est pas du hasard.
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var on_guide: Dictionary = {}
	for entry: Array in _read(guide):
		seen[entry[0]] = int(seen.get(entry[0], 0)) + 1
		on_guide[entry[0]] = true

	print("=== LE PRIX DE DEDOUBLER `vide` ===")
	print("reliefs epais : %d   cases de robe : %d" % [scanned, cells])
	print("")
	print("AUJOURD'HUI, 3 etats de flanc :")
	print("   9 pans x %d rangees = %d au plus, %d vivants (forme fermee)"
			% [Walls.BLOCK_ROWS, Walls.PAN_COUNT * Walls.BLOCK_ROWS,
			Thickness.wall_roles().size()])
	print("   rencontres par cette battue : %d" % old_seen.size())
	print("")
	print("AVEC 4 etats de flanc :")
	print("   16 pans x %d rangees = %d au plus" % [Walls.BLOCK_ROWS, 16 * Walls.BLOCK_ROWS])
	print("   RENCONTRES : %d          (dont %d sur le guide)" % [seen.size(), on_guide.size()])
	print("")
	var pans: Dictionary = {}
	for key: Vector3i in seen.keys():
		pans[Vector2i(key.x, key.y)] = true
	print("pans distincts rencontres : %d sur 16" % pans.size())
	var dead: Array[String] = []
	for west: int in range(4):
		for east: int in range(4):
			if not pans.has(Vector2i(west, east)):
				dead.append("%s|%s" % [STATE_NAMES[west], STATE_NAMES[east]])
	print("pans JAMAIS rencontres : %s" % ("aucun" if dead.is_empty() else ", ".join(dead)))
	print("")
	print("Les roles, par frequence :")
	var order: Array = seen.keys()
	order.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(seen[a]) > int(seen[b]))
	for i: int in range(order.size()):
		var key: Vector3i = order[i] as Vector3i
		print("   %-22s %-10s x%d" % ["%s|%s" % [STATE_NAMES[key.x], STATE_NAMES[key.y]],
				Walls.ROW_NAMES[key.z], int(seen[key])])
	quit()


## Chaque case de robe visible : [role a quatre etats, role a trois etats]
func _read(heights: PackedStringArray) -> Array[Array]:
	var out: Array[Array] = []
	var roles: Dictionary = (Walls.assemble(heights)["roles"] as Dictionary)
	var highest: Dictionary = {}
	for key: Vector3i in roles.keys():
		var at: Vector2i = Vector2i(key.x, key.y)
		if not highest.has(at) or key.z > int((highest[at] as Vector3i).z):
			highest[at] = key
	for at: Vector2i in highest.keys():
		var key: Vector3i = highest[at]
		var role: Vector2i = roles[key] as Vector2i
		var lip: int = key.z
		var west: int = _split(heights, at + Vector2i.LEFT, Walls.pan_west(role.x), lip)
		var east: int = _split(heights, at + Vector2i.RIGHT, Walls.pan_east(role.x), lip)
		out.append([Vector3i(west, east, role.y), Vector3i(role.x, role.y, 0)])
	return out


## L'etat d'un flanc, `vide` dedouble selon ce qu'il y a derriere.
func _split(heights: PackedStringArray, probe: Vector2i, flank: int, lip: int) -> int:
	if flank == Walls.SIDE_MUTE:
		return MUTE
	if flank == Walls.SIDE_FRONT:
		return FRONT
	# ⚠ LE PARTAGE SE FAIT SUR LA LEVRE, PAS SUR MON ETAGE. Une case de robe est, sur la
	# carte, une case du sol d'en bas : lui demander SON etage ne dit rien de la falaise.
	return VOID_HIGH if HeightMask.level_at(heights, probe.x, probe.y) >= lip else VOID_LOW


func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = rng.randi_range(12, 18)
	var h: int = rng.randi_range(14, 20)
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	for stamp: int in range(rng.randi_range(4, 12)):
		var level: int = rng.randi_range(0, 3)
		var bw: int = rng.randi_range(3, 7)
		var bh: int = rng.randi_range(3, 7)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = maxi(row[x], level + 1)
				grid[y] = row
	for dig: int in range(rng.randi_range(1, 5)):
		var level: int = rng.randi_range(-1, 2)
		var bw: int = rng.randi_range(3, 6)
		var bh: int = rng.randi_range(3, 6)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = mini(row[x], level + 1)
				grid[y] = row
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(h):
		var line: String = ""
		for x: int in range(w):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
