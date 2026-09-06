# Le banc de la PASSE ANGLAISE : chaque fichier touche par la traduction se charge-t-il
# ENCORE, et compile-t-il ?
#
# ⚠ « CHARGE » NE VEUT PAS DIRE « COMPILE ». Un script dont l'analyse echoue rend quand meme
# une ressource, vide de ses fonctions -- et rien ne le signale. `can_instantiate()` tranche.
#
# ⚠ ET ON CHERCHE AUSSI CE QUI RESTE DE FRANCAIS, parce qu'une chaine oubliee ne se voit pas
# a la relecture : elle se voit a l'ecran, une fois vendue.
extends SceneTree

const TOUCHED: PackedStringArray = ([
	"res://ui/editor.gd",
	"res://ui/manual.gd",
	"res://ui/rooms.gd",
	"res://ui/test_room.gd",
	"res://addons/solupaint/plugin.gd",
	"res://addons/solupaint/dock.gd",
	"res://addons/solupaint/world.gd",
	"res://addons/solupaint/tileset.gd",
	"res://addons/solupaint/signature.gd",
] as PackedStringArray)

## Des mots qui n'existent qu'en francais, et qu'aucun mot anglais ne contient par accident.
const FRENCH: PackedStringArray = ([
	"Cliquez", "Choisissez", "Ouvrez", "Peindre", "peignez", "tuiles", "etage",
	"aucune", "Aucun", "n'est", "c'est", "d'un", "qu'il", "vous ", "votre ",
] as PackedStringArray)


func _initialize() -> void:
	var bad: int = 0

	for path: String in TOUCHED:
		var script: Resource = load(path)
		if script == null:
			print("ECHEC  %s : ne se charge pas" % path)
			bad += 1
			continue
		if not (script as GDScript).can_instantiate():
			print("ECHEC  %s : se charge mais NE COMPILE PAS" % path)
			bad += 1
			continue
		print("ok     %s" % path)

	# ⚠ COMPILER N'EST PAS S'EXECUTER. Le niveau 2 du manuel LIT son compte de tuiles dans
	# `Families.massif_tiles()` plutot que de l'ecrire en dur ; si cette expression cassait,
	# `can_instantiate()` resterait vert et l'acheteur ouvrirait un onglet vide. On BATIT donc
	# les trois pages, pour de vrai, et on regarde ce qui en sort.
	var manual: Object = (load("res://ui/manual.gd") as GDScript).new()
	for page: String in ["_hands_on", "_how_it_works", "_the_contract"]:
		var body: String = String(manual.call(page))
		if body.length() < 200:
			print("ECHEC  manual.%s() rend %d caracteres" % [page, body.length()])
			bad += 1
		else:
			print("ok     manual.%s()  %d caracteres" % [page, body.length()])
	manual.free()

	var scene: Resource = load("res://ui/editor.tscn")
	if scene == null:
		print("ECHEC  res://ui/editor.tscn : ne se charge pas")
		bad += 1
	else:
		print("ok     res://ui/editor.tscn")

	print("")
	var leftovers: int = 0
	var files: PackedStringArray = TOUCHED.duplicate()
	files.append("res://ui/editor.tscn")
	for path: String in files:
		var text: String = FileAccess.get_file_as_string(path)
		for word: String in FRENCH:
			for raw: String in text.split("\n"):
				if raw.find("\"") < 0 or raw.find(word) < 0:
					continue
				if raw.strip_edges().begins_with("#"):
					continue
				print("FRANCAIS  %s : %s" % [path.get_file(), raw.strip_edges()])
				leftovers += 1
				break

	print("")
	print("compilation : %d echec(s) sur %d fichiers" % [bad, files.size()])
	print("francais restant : %d ligne(s)" % leftovers)
	quit(1 if (bad > 0 or leftovers > 0) else 0)
