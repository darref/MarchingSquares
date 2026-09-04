# LA CHAINE ENTIERE, SUR UN VRAI TRAVAIL PEINT — hors suite.
#
# ⚠ LA SUITE PEINT DES COULEURS TIREES DE LA POSITION ; un fichier de session porte du VRAI
# travail. C'est la difference qui a deja parle une fois : un carnet relu retombe sur ses
# pieds ou ne retombe pas, et seul un vrai fichier le dit.
#
# Ce banc part d'un `.solutiles`, le fait sortir par le chemin normal de l'export, relit le
# manifeste AVEC LE LECTEUR DU PLUGIN, en fabrique un TileSet et pose un monde. Rien n'est
# ecrit dans le depot : tout va dans `user://`.
#
#     godot --headless --path . --script res://tools/chain_massifs.gd -- <travail.solutiles>
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Families := preload("res://core/families.gd")
const WorkIO := preload("res://core/work_io.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")
const PluginManifest := preload("res://addons/solupaint/manifest.gd")
const PluginTileSet := preload("res://addons/solupaint/tileset.gd")
const PluginRules := preload("res://addons/solupaint/rules.gd")

const FOLDER: String = "user://chain_massifs"


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("chain : donnez un fichier .solutiles en argument.")
		quit(1)
		return
	var work_path: String = arguments[0]

	var head: Dictionary = WorkIO.peek(work_path)
	if int(head["error"]) != OK:
		push_error("chain : '%s' ne se lit pas (erreur %d)." % [work_path, int(head["error"])])
		quit(1)
		return
	var mode_id: StringName = head["mode"]
	print("travail : mode %s, famille %s, %d pixels par tuile"
			% [mode_id, head["family"], int(head["resolution"])])
	if head["family"] != Families.BY_MASSIF:
		push_error("chain : ce banc ne connait que la famille des massifs.")
		quit(1)
		return

	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(mode_id))
	var loaded: Dictionary = WorkIO.read(work_path, heights)
	if int(loaded["error"]) != OK:
		push_error("chain : la lecture a echoue (erreur %d)." % int(loaded["error"]))
		quit(1)
		return
	var painting: RefCounted = loaded["painting"]
	print("  %d tuiles relues, %d rendues"
			% [painting.painted_cells().size(), (loaded["unplaced"] as Array).size()])

	var report: Dictionary = MassifTileset.analyse(painting, heights)
	print("  %d tuiles sur %d livrees" % [int(report["delivered"]),
			(report["wanted"] as Array).size()])
	if not bool(report["is_exportable"]):
		print("  IL MANQUE %d TUILES : rien ne sort, et c'est la regle."
				% (report["missing"] as Array).size())
		for tile: int in report["missing"]:
			print("    - %s" % MassifTileset.Massifs.describe(tile))
		quit(1)
		return

	var done: Dictionary = MassifTileset.write(painting, heights, mode_id, FOLDER, "chaine")
	if String(done["error"]) != "":
		push_error("chain : l'export a refuse (%s)." % String(done["error"]))
		quit(1)
		return
	for path: String in done["written"]:
		print("  ecrit : %s" % ProjectSettings.globalize_path(path))

	# --- LE PLUGIN LE RELIT, avec son propre lecteur et ses propres refus.
	var manifest: Dictionary = PluginManifest.read(FOLDER.path_join("chaine_tileset.txt"))
	if int(manifest["error"]) != OK:
		push_error("chain : le plugin refuse le manifeste : %s" % String(manifest["reason"]))
		quit(1)
		return
	if not PluginManifest.is_complete(manifest):
		push_error("chain : le manifeste ne place que %d tuiles." % manifest["slots"].size())
		quit(1)
		return
	var built: Dictionary = PluginTileSet.build(FOLDER, manifest)
	if int(built["error"]) != OK:
		push_error("chain : le TileSet ne se fabrique pas : %s" % String(built["reason"]))
		quit(1)
		return
	print("  le plugin accepte : v%d, %d tuiles, %d pixels"
			% [int(manifest["version"]), manifest["slots"].size(), int(manifest["tile_size"])])

	# --- ET IL POSE UN MONDE. Chaque pose doit trouver sa tuile.
	var world: Dictionary = {}
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			var level: int = HeightMask.level_at(heights, x, y)
			if level >= 0:
				world[Vector2i(x, y)] = level
	var slots: Dictionary = manifest["slots"]
	var posed: int = 0
	var missing: int = 0
	for one: Dictionary in PluginRules.poses(world):
		if slots.has(PluginRules.key_of(one)):
			posed += 1
		else:
			missing += 1
	print("  le monde du guide : %d poses, %d sans tuile" % [posed, missing])
	if missing > 0:
		push_error("chain : %d poses ne trouvent pas leur tuile." % missing)
		quit(1)
		return
	print("LA CHAINE ENTIERE PASSE : peint -> exporte -> relu par le plugin -> pose.")
	quit(0)
