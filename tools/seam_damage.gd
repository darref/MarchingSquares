extends SceneTree

## LE DEGAT DES CLASSES DE RACCORD, MESURE SUR UN VRAI TRAVAIL PEINT.
##
## ⚠ LES CLASSES ONT ETE CALCULEES SOUS UNE HYPOTHESE QUE L'ARTISTE NE SUIT PAS. Le dossier
## la pose noir sur blanc : « UNE CASE DE FALAISE EST UNE CASE DE ROCHE ». Le modele suppose
## donc qu'une tuile de falaise est pleine d'un bord a l'autre, et il declare « ces deux
## pixels sont le meme point de roche ». Mais on y trace un contour qui VAGABONDE : une part
## de la case est dehors. La classe egale alors de la matiere a du transparent, et la
## propagation ecrit de la roche dans le dehors -- les tirets.
##
## On ne discute pas : on compte. Sur le fichier peint, pour chaque pixel de bord, on suit sa
## classe et on regarde si la destination est du meme etat. Le fichier n'est jamais reecrit.
##
##     godot --headless --path . --script res://tools/seam_damage.gd -- <chemin.solutiles>

const WorkIO := preload("res://core/work_io.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")
const Seams := preload("res://core/seams.gd")
const Painting := preload("res://core/painting.gd")

const SIDE_NAMES: Array[String] = ["haut", "bas", "gauche", "droite"]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage : -- <chemin.solutiles>")
		quit(1)
		return
	var path: String = args[0]
	if not FileAccess.file_exists(path):
		print("fichier introuvable : %s" % path)
		quit(1)
		return
	var header: Dictionary = WorkIO.peek(path)
	var resolution: int = int(header.get("resolution", 16))
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var result: Dictionary = WorkIO.read(path, heights)
	if int(result.get("error", OK)) != OK:
		print("REFUS : erreur %d" % int(result["error"]))
		quit(1)
		return
	var painting: Painting = result["painting"]
	var family: StringName = StringName(header.get("family", Families.BY_CELL))
	var slots: Dictionary = WorkIO.slots(heights, family)

	# role -> image peinte (la premiere occurrence trouvee suffit : une tuile, une image)
	var art: Dictionary = {}
	for at: Vector2i in painting.painted_cells():
		if not slots.has(at):
			continue
		var key: String = String(slots[at])
		if not key.begins_with("W"):
			continue
		var body: String = key.substr(1, key.rfind(":") - 1)
		var bits: PackedStringArray = body.split(",")
		var role: Vector2i = Vector2i(int(bits[0]), int(bits[1]))
		if not art.has(role):
			art[role] = painting.image_of(at)
	print("tuiles de falaise peintes : %d sur %d" % [art.size(), Walls.ALL_ROLES.size()])
	print("resolution : %d pixels" % resolution)
	print("")

	var last: int = resolution - 1
	var compared: int = 0
	var agree: int = 0
	var clash: int = 0
	var by_pair: Dictionary = {}
	for role: Vector2i in art.keys():
		var image: Image = art[role]
		for y: int in range(resolution):
			for x: int in range(resolution):
				if x != 0 and x != last and y != 0 and y != last:
					continue
				var mine: bool = image.get_pixel(x, y).a > 0.02
				for target: Vector4i in Seams.mirrors(role, x, y, resolution):
					var other: Vector2i = Vector2i(target.x, target.y)
					if other == role:
						continue
					if not art.has(other):
						continue
					compared += 1
					var theirs: bool = (art[other] as Image).get_pixel(target.z, target.w).a > 0.02
					if mine == theirs:
						agree += 1
					else:
						clash += 1
						var pair: String = "%s <-> %s" % [Walls.role_name(role),
								Walls.role_name(other)]
						by_pair[pair] = int(by_pair.get(pair, 0)) + 1
	print("=== CE QUE LES CLASSES IMPOSENT, SUR VOTRE TRAVAIL ===")
	print("pixels de bord compares          : %d" % compared)
	print("d'accord (meme etat)             : %d  (%.1f %%)"
			% [agree, 100.0 * agree / maxi(1, compared)])
	print("EN DESACCORD -- matiere contre transparent : %d  (%.1f %%)"
			% [clash, 100.0 * clash / maxi(1, compared)])
	print("")
	if clash > 0:
		print("Les couples les plus touches :")
		var order: Array = by_pair.keys()
		order.sort_custom(func(a: Variant, b: Variant) -> bool:
			return int(by_pair[a]) > int(by_pair[b]))
		for i: int in range(mini(14, order.size())):
			print("   %-46s x%d" % [order[i], int(by_pair[order[i]])])
	quit()
