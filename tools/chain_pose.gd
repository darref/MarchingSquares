# LE PARCOURS DE CHAINE, ACTE 2 — le monde pose CHEZ L'ACHETEUR, par SES copies.
#
# Se lance avec --path sur le projet acheteur fabrique par chain_proof.gd :
#
#     godot --headless --path <projet_acheteur> --script <ce fichier, chemin absolu>
#
# Le preload de res://addons/solupaint/world.gd resout alors la COPIE INSTALLEE, pas la
# notre : c'est tout l'interet. Le relief est relu du guide minimal en chemin absolu —
# l'acheteur n'a pas guides/, et le monde n'a besoin que d'un dictionnaire.
# Sortie 0 si le monde se pose entier, 1 sinon.
extends SceneTree

const WorldScript := preload("res://addons/solupaint/world.gd")

const GUIDE_PATH: String = "D:/AbsoluTiles/guides/minimal.txt"
const MANIFEST_PATH: String = "res://solutiles/chaine_tileset.txt"

var _failures: int = 0


func _check(ok: bool, label: String) -> void:
	print(("  OK     " if ok else "  ECHEC  ") + label)
	if not ok:
		_failures += 1


func _initialize() -> void:
	var text: String = FileAccess.get_file_as_string(GUIDE_PATH)
	var heights: Dictionary = {}
	var y: int = 0
	for line: String in text.split("\n"):
		if line.strip_edges() == "":
			continue
		for x: int in range(line.length()):
			var glyph: String = line[x]
			if glyph == "~":
				continue
			if glyph == ".":
				heights[Vector2i(x, y)] = 0
			elif glyph >= "0" and glyph <= "9":
				heights[Vector2i(x, y)] = glyph.to_int()
		y += 1
	_check(heights.size() > 1000, "relief relu : %d cases hors du vide" % heights.size())

	var world: Node2D = WorldScript.new()
	world.set("heights", heights)
	world.set("manifest_path", MANIFEST_PATH)
	var last_error: String = String(world.get("last_error"))
	_check(last_error == "", "le monde accepte le manifeste depose (" +
			(last_error if last_error != "" else "aucune erreur") + ")")

	var surface0: int = -1
	var walls: int = 0
	var total: int = 0
	for child: Node in world.get_children():
		if child is TileMapLayer:
			var layer: TileMapLayer = child
			var count: int = layer.get_used_cells().size()
			total += count
			print("    couche %-12s : %5d tuiles" % [layer.name, count])
			if String(layer.name) == "Surface0":
				surface0 = count
			elif String(layer.name).begins_with("Falaise"):
				walls += count
	_check(surface0 == heights.size(),
			"Surface0 couvre chaque case hors du vide (%d / %d)" % [surface0, heights.size()])
	_check(walls > 0, "les falaises sont posees (%d tuiles)" % walls)
	_check(total > heights.size(), "l'empilement pose plus que la seule surface (%d tuiles)" % total)

	world.free()
	print("")
	print("PARCOURS DE CHAINE (acte 2) : %d echec(s)." % _failures)
	quit(0 if _failures == 0 else 1)
