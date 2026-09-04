# LE MONDE TEL QUE LE MOTEUR LE POSERA — avec VOTRE planche, et rien d'autre.
#
# ⚠ CE N'EST PAS LE FOND DU GUIDE. Le fond est calcule depuis le relief : il montre la
# specification. Ici on ne calcule aucun pixel -- on lit la PLANCHE EXPORTEE, on demande a la
# copie de la regle qui part chez l'acheteur (`addons/solupaint/rules.gd`) quelle tuile va ou,
# et on tamponne. Ce qui sort est donc exactement ce qu'un jeu affichera.
#
# ⚠ ET LE RELIEF EST UN PAYSAGE, PAS LE GUIDE. Le guide est une planche de specimens : il
# montre toutes les tuiles, jamais comment elles rendent. Un monde bati par une suite de
# GESTES -- des tampons 3x3, comme le pinceau -- est celui qu'un level designer produira.
#
#     godot --headless --path . --script res://tools/preview_engine.gd -- <manifeste.txt> [sortie.png] [graine]
extends SceneTree

const Gesture := preload("res://core/gesture.gd")
const HeightMask := preload("res://core/height_mask.gd")
const PluginManifest := preload("res://addons/solupaint/manifest.gd")
const PluginRules := preload("res://addons/solupaint/rules.gd")


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("apercu : donnez le chemin d'un manifeste `<nom>_tileset.txt`.")
		quit(1)
		return
	var manifest_path: String = arguments[0]
	var target: String = arguments[1] if arguments.size() > 1 else "apercu_moteur.png"
	var seed_value: int = arguments[2].to_int() if arguments.size() > 2 else 20260903

	var manifest: Dictionary = PluginManifest.read(manifest_path)
	if int(manifest["error"]) != OK:
		push_error("apercu : %s" % String(manifest["reason"]))
		quit(1)
		return
	var side: int = int(manifest["tile_size"])
	var sheet: Image = Image.new()
	if sheet.load(manifest_path.get_base_dir().path_join(String(manifest["sheet"]))) != OK:
		push_error("apercu : la planche ne se lit pas.")
		quit(1)
		return

	# ⚠ LE MONDE SE BATIT PAR GESTES : la suite de tampons EST la preuve qu'il est
	# atteignable au pinceau. Un relief tire au sort ne le serait pas.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var relief: PackedStringArray = Gesture.walk(rng, 44, 30, 5)
	if relief.is_empty():
		push_error("apercu : le geste n'a produit aucun monde legal.")
		quit(1)
		return
	var world: Dictionary = {}
	for y: int in range(HeightMask.height(relief)):
		for x: int in range(HeightMask.width(relief)):
			var level: int = HeightMask.level_at(relief, x, y)
			if level >= 0:
				world[Vector2i(x, y)] = level

	var wide: int = HeightMask.width(relief)
	var tall: int = HeightMask.height(relief)
	var image: Image = Image.create_empty(wide * side, tall * side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var slots: Dictionary = manifest["slots"]
	var posed: int = 0
	var missing: int = 0
	# ⚠ DANS L'ORDRE DE POSE, ET C'EST LUI QUI FAIT L'OCCLUSION. Un massif se dessine entier ;
	# ce qui le recouvre passe simplement apres.
	for one: Dictionary in PluginRules.poses(world):
		var tile: int = PluginRules.key_of(one)
		if not slots.has(tile):
			missing += 1
			continue
		var slot: Vector2i = slots[tile]
		image.blend_rect(sheet, Rect2i(slot * side, Vector2i(side, side)),
				(one["cell"] as Vector2i) * side)
		posed += 1

	if image.save_png(target) != OK:
		push_error("apercu : ecriture impossible de '%s'." % target)
		quit(1)
		return
	print("apercu ecrit : %s (%d x %d)" % [ProjectSettings.globalize_path(target),
			image.get_width(), image.get_height()])
	print("  %d tuiles posees, %d sans tuile, graine %d" % [posed, missing, seed_value])
	quit(0)
