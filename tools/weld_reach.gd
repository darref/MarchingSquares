# JUSQU'OU IL FAUT DECOUPER POUR QUE `PIED 21 AU RAS` SURVIVE.
#
# ⚠ ON NE DEDUIT PAS LA TAILLE, ON LA BALAIE. La tuile resiste a trois battues ; la question
# n'est plus « existe-t-elle » -- le vivier la porte -- mais « quel CONTEXTE faut-il garder
# autour d'elle pour qu'elle tienne ». « Au ras » est une propriete du MASSIF vis-a-vis de son
# porteur : une decoupe qui tranche le porteur, ou qui tranche la partie qui deborde, retire
# precisement ce qui la rend au ras. La sonde dit donc, pour chaque occurrence, la plus petite
# fenetre qui la porte encore une fois soudee.
#
#     godot --headless --path . --script res://tools/weld_reach.gd -- [tuile] [tirages]
extends SceneTree

const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")
const Lab := preload("res://tools/relief_lab.gd")

const GAP: int = 3
const RIM: int = 4
## Le rab sous le bloc, celui que `build_terrain` donne a sa derniere rangee.
const FALLOUT: int = 12


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tile: int = args[0].to_int() if not args.is_empty() else 66325
	var draws: int = args[1].to_int() if args.size() > 1 else 120
	print("on cherche : %s  (cle %d)" % [Massifs.describe(tile), tile])

	var pool: Array[PackedStringArray] = Lab.ground(draws)
	print("%d mondes au vivier" % pool.size())

	var hits: int = 0
	var whole_ok: int = 0
	var best: int = -1
	for index: int in range(pool.size()):
		var world: PackedStringArray = pool[index]
		var posed: Dictionary = Massifs.paintable(world)
		for cell: Vector2i in posed.keys():
			if int(posed[cell]) != tile:
				continue
			hits += 1
			# 1. LE MONDE ENTIER, SOUDE. C'est ce que `build_terrain._from_pool` teste.
			var full: String = _welds(world, cell, tile)
			if full == "OK":
				whole_ok += 1
			print("")
			print("  monde %d (%dx%d), case %d,%d" % [index, world[0].length(), world.size(),
					cell.x, cell.y])
			print("    monde ENTIER soude          : %s" % full)
			# 2. LES DECOUPES, DE LA PLUS PETITE A LA PLUS GRANDE.
			var kept: int = -1
			for half: int in [5, 7, 9, 11, 13, 16, 20, 25, 30, 40]:
				var block: PackedStringArray = _cut(world, cell, half)
				var seat: Vector2i = Vector2i(mini(half, cell.x), mini(half, cell.y))
				var verdict: String = _welds(block, seat, tile)
				print("    decoupe %2d autour (%2dx%2d) : %s" % [half, block[0].length(),
						block.size(), verdict])
				if verdict == "OK" and kept < 0:
					kept = half
			if kept >= 0 and (best < 0 or kept < best):
				best = kept
	print("")
	print("%d occurrence(s) ; %d monde(s) entier(s) survivent a la soudure" % [hits, whole_ok])
	if best < 0:
		print("AUCUNE DECOUPE NE LA PORTE, a aucune taille essayee")
	else:
		print("LA PLUS PETITE DECOUPE QUI LA PORTE : %d de rayon (%dx%d)"
				% [best, 2 * best + 1, 2 * best + 1])
	quit(0)


## LA DECOUPE BRUTE : un carre de rayon `half` autour de la case, borne au monde. ⚠ ON NE
## REPLIQUE PAS LES BORDS : l'etirement garantit l'epaisseur mais il ment sur ce qui s'arrete,
## et « au ras » tient precisement a ce qui s'arrete.
static func _cut(world: PackedStringArray, cell: Vector2i, half: int) -> PackedStringArray:
	var x0: int = maxi(0, cell.x - half)
	var y0: int = maxi(0, cell.y - half)
	var x1: int = mini(world[0].length() - 1, cell.x + half)
	var y1: int = mini(world.size() - 1, cell.y + half)
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(y0, y1 + 1):
		out.append(world[y].substr(x0, x1 - x0 + 1))
	return out


## LE BLOC SOUDE DANS LE CADRE QUE `build_terrain` LUI DONNE, puis relu. On rend le VERDICT,
## pas un booleen : « illegal » et « la tuile a change » ne s'aiguillent pas au meme endroit.
static func _welds(block: PackedStringArray, seat: Vector2i, tile: int) -> String:
	var pad: int = GAP + RIM
	var wide: int = block[0].length() + 2 * pad
	var tall: int = block.size() + 2 * pad + FALLOUT
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(1)
		grid.append(line)
	for y1: int in range(block.size()):
		var row: String = block[y1]
		for x1: int in range(row.length()):
			var c: String = row[x1]
			var level: int = 0 if (c == "~" or c == "." or c == "0") else c.to_int()
			var line1: PackedByteArray = grid[pad + y1]
			line1[pad + x1] = maxi(int(line1[pad + x1]), level + 1)
			grid[pad + y1] = line1
	for y2: int in range(tall):
		for x2: int in range(wide):
			if y2 < RIM or y2 >= tall - RIM or x2 < RIM or x2 >= wide - RIM:
				grid[y2][x2] = 0
	var text: PackedStringArray = Gesture.text(grid)
	if not Gesture.legal(text):
		return "relief illegal"
	var got: int = int(Massifs.paintable(text).get(seat + Vector2i(pad, pad), -1))
	if got == tile:
		return "OK"
	if got < 0:
		return "la case ne se peint plus"
	return "devenue %s" % Massifs.describe(got)
