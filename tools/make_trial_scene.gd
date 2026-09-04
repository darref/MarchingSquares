# LA SCENE OU LE DEFAUT SE REGARDE — le guide entier, pose par SoluPaint avec l'essai.
#
# Elle avait ete fabriquee a la main dans une session precedente et PERDUE, parce que ni elle
# ni son fabricant n'etaient au depot. Cette fois le fabricant est commite, et la scene se
# regenere d'une commande :
#
#     godot --headless --path . --script res://tools/make_trial_scene.gd
#     godot --headless --path . --script res://tools/make_trial_scene.gd -- <manifeste.txt>
#
# ⚠ ET ELLE PREND VOTRE TILESET SI VOUS LUI EN DONNEZ UN. Sans argument elle exporte l'essai
# -- notre dessin de specification -- et pose le monde avec. Avec le chemin d'un manifeste
# exporte depuis le logiciel, c'est VOTRE art qu'on regarde dans le moteur, ce qui est le
# seul jugement qui compte.
#
# Ce qu'elle fait :
#   1. exporte l'essai -- notre propre trace livree comme tileset -- dans res://trial/ ;
#   2. releve le relief entier de guides/massifs.txt, plaine comprise, vide exclu ;
#   3. enregistre res://trial_solutiles_to_solupaint_full.tscn : un seul noeud
#      SoluPaintWorld, son manifeste et son relief. Les couches, il les repose seul.
#
# ⚠ LE RELIEF EST FIGE DANS LA SCENE, PAS RELU DU GUIDE A L'OUVERTURE. C'est voulu : la
# scene reproduit ce qu'un acheteur fait -- un monde pose a la main dans SON projet, ou
# guides/ n'existe pas -- et le defaut doit s'y regarder tel quel. Si le guide bouge, une
# commande la remet d'accord.
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const MassifTrial := preload("res://exporters/massif_trial.gd")
const WorldScript := preload("res://addons/solupaint/world.gd")

const FOLDER: String = "res://trial"
const SCENE_PATH: String = "res://trial_solutiles_to_solupaint_full.tscn"


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var manifest_path: String = arguments[0] if arguments.size() > 0 else ""
	if manifest_path == "":
		var report: Dictionary = MassifTrial.write(FOLDER, Modes.MASSIFS)
		if String(report["error"]) != "":
			push_error("make_trial_scene: l'export de l'essai a refuse (%s)."
					% String(report["error"]))
			quit(1)
			return
		for path: String in report["written"]:
			if path.ends_with("_tileset.txt"):
				manifest_path = path
	if manifest_path == "" or not FileAccess.file_exists(manifest_path):
		push_error("make_trial_scene: aucun manifeste a poser (%s)." % manifest_path)
		quit(1)
		return
	print("tileset : %s" % manifest_path)

	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MASSIFS))
	var heights: Dictionary = {}
	for y: int in range(HeightMask.height(guide)):
		for x: int in range(HeightMask.width(guide)):
			var level: int = HeightMask.level_at(guide, x, y)
			if level >= 0:
				heights[Vector2i(x, y)] = level

	# Le relief se donne AVANT le manifeste : le second declenche la pose, et elle doit
	# trouver le monde entier pour dimensionner ses couches.
	var world: Node2D = WorldScript.new()
	world.name = "SoluPaintWorld"
	world.set("heights", heights)
	world.set("manifest_path", manifest_path)
	var last_error: String = String(world.get("last_error"))
	if last_error != "":
		push_error("make_trial_scene: le monde refuse l'essai : %s" % last_error)
		world.free()
		quit(1)
		return
	var last_warning: String = String(world.get("last_warning"))
	if last_warning != "":
		# ⚠ UN TROU SE DIT, IL NE SE DECOUVRE PAS DANS LE JEU. La scene s'ecrit quand meme --
		# c'est un banc, on veut le regarder -- mais le compte part a la console.
		print("ATTENTION : %s" % last_warning)

	# ⚠ SEUL LE NOEUD RACINE PART DANS LA SCENE. Les couches qu'il vient de creer ne sont
	# pas siennes (pas d'owner) : PackedScene les ignore, et c'est le but -- il les refait
	# a l'ouverture, depuis le relief. Une scene qui les figerait pourrait mentir.
	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(world)
	if error == OK:
		error = ResourceSaver.save(packed, SCENE_PATH)
	world.free()
	if error != OK:
		push_error("make_trial_scene: ecriture impossible de la scene (erreur %d)." % error)
		quit(1)
		return
	print("Scene ecrite : %s" % ProjectSettings.globalize_path(SCENE_PATH))
	print("Ouvrez-la dans l'editeur : le monde s'y repose seul, depuis son relief.")
	quit(0)
