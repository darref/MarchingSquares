# REGARDER PLUTOT QUE DEDUIRE : le monde qui porte une tuile, et l'empreinte de son massif.
#
#     godot --headless --path . --script res://tools/dump_witness.gd -- [tuile] [tirages]
extends SceneTree

const Massifs := preload("res://core/massifs.gd")
const Lab := preload("res://tools/relief_lab.gd")

const MARKS: Array[String] = ["S", "c", "o", "P"]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tile: int = args[0].to_int() if not args.is_empty() else 66325
	var draws: int = args[1].to_int() if args.size() > 1 else 120
	print("on cherche : %s" % Massifs.describe(tile))
	for world: PackedStringArray in Lab.ground(draws):
		var posed: Dictionary = Massifs.paintable(world)
		var seat: Vector2i = Vector2i(-1, -1)
		for cell: Vector2i in posed.keys():
			if int(posed[cell]) == tile:
				seat = cell
				break
		if seat.x < 0:
			continue
		print("")
		print("LE RELIEF (%dx%d), la case cherchee en %d,%d :"
				% [world[0].length(), world.size(), seat.x, seat.y])
		for y: int in range(world.size()):
			print("  %2d  %s%s" % [y, world[y], "   <---" if y == seat.y else ""])
		# L'empreinte du massif qui porte la case : S surface, c chapiteau, o corps, P pied.
		var made: Dictionary = Massifs.of(world)
		var groups: Array = made["cells"]
		var levels: Array[int] = made["level"]
		var covers: Array[bool] = made["covers"]
		for mark: int in range(groups.size()):
			var print_of: Dictionary = Massifs.footprint(world, groups[mark] as Array,
					levels[mark])
			if not print_of.has(seat):
				continue
			print("")
			print("L'EMPREINTE du massif %d (etage %d, %s) :"
					% [mark, levels[mark], "au ras" if covers[mark] else "libre"])
			for y1: int in range(world.size()):
				var row: String = ""
				for x1: int in range(world[0].length()):
					var at: Vector2i = Vector2i(x1, y1)
					if at == seat:
						row += "@"
					elif print_of.has(at):
						row += MARKS[int(print_of[at])]
					else:
						row += "."
				print("  %2d  %s" % [y1, row])
		quit(0)
	print("pas trouvee")
	quit(1)
