# LE PARCOURS DE CHAINE — tout le trajet d'un travail, hors suite, en conditions reelles.
#
# Existe parce que l'utilisateur l'a pose comme barre : « je ne peins rien tant que je ne
# suis pas sur que tout fonctionne dans toute la chaine ». La suite eprouve chaque maillon ;
# ce banc parcourt LE TRAJET ENTIER, une fois, dans l'ordre ou l'utilisateur le vivra :
#
#   peindre (l'essai verse comme peinture) -> enregistrer un .solutiles -> le rouvrir
#   -> exporter les planches et le manifeste -> installer le plugin chez un « acheteur »
#   -> y deposer le tileset. La pose du monde chez l'acheteur est le second acte :
#   tools/chain_pose.gd, lance AVEC --path sur le projet de l'acheteur, pour que ce soient
#   SES copies du plugin qui posent.
#
#     godot --headless --path . --script res://tools/chain_proof.gd
#
# Ecrit tout sous user://chain_proof/ (vide d'abord : user:// survit d'une execution a
# l'autre, lecon deja payee par le test d'installation) et imprime le chemin OS du projet
# acheteur pour l'acte deux. Sortie 0 si tout passe, 1 sinon.
extends SceneTree

const Modes := preload("res://core/modes.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const Trial := preload("res://exporters/trial_tileset.gd")
const WorkIO := preload("res://core/work_io.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")
const PluginInstall := preload("res://core/plugin_install.gd")

const ROOT: String = "user://chain_proof"

var _failures: int = 0


func _check(ok: bool, label: String) -> void:
	print(("  OK     " if ok else "  ECHEC  ") + label)
	if not ok:
		_failures += 1


func _wipe(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var child: String = path + "/" + entry
		if dir.current_is_dir():
			_wipe(child)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = dir.get_next()
	dir.list_dir_end()


func _copy_bytes(from_path: String, to_path: String) -> bool:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(from_path)
	if bytes.is_empty() and FileAccess.get_open_error() != OK:
		return false
	var out: FileAccess = FileAccess.open(to_path, FileAccess.WRITE)
	if out == null:
		return false
	out.store_buffer(bytes)
	out.close()
	return true


func _initialize() -> void:
	_wipe(ROOT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))

	# 1. Peindre. L'essai verse l'illustration dans un carnet comme si elle avait ete
	# peinte a la main — la seule source complete qui ne fabrique rien.
	var painting: Painting = Trial.paint(guide)
	_check(not painting.painted_cells().is_empty(), "peindre : le carnet porte des tuiles")

	# 2. Enregistrer, puis relire — l'aller-retour du .solutiles.
	var work_path: String = ROOT + "/travail.solutiles"
	var write_error: Error = WorkIO.write(work_path, painting, guide, Modes.MINIMAL)
	_check(write_error == OK, "enregistrer : .solutiles ecrit")
	var head: String = FileAccess.get_file_as_string(work_path).get_slice("\n", 0)
	_check(head.begins_with("solutiles"), "enregistrer : l'en-tete porte le nouveau nom (" + head + ")")
	var peeked: Dictionary = WorkIO.peek(work_path)
	_check(int(peeked.get("error", FAILED)) == OK and StringName(peeked.get("mode", &"")) == Modes.MINIMAL,
			"rouvrir : peek lit l'en-tete (mode, taille) sans charger les tuiles")
	var reread: Dictionary = WorkIO.read(work_path, guide)
	var painting2: Painting = reread.get("painting")
	_check(painting2 != null and not painting2.painted_cells().is_empty(),
			"rouvrir : les tuiles retombent sur leurs pieds")
	_check(Array(reread.get("unplaced", [])).is_empty(), "rouvrir : rien d'orphelin (unplaced vide)")

	# 3. Exporter — depuis le carnet RELU, pas l'original : c'est le trajet vecu.
	var export_dir: String = ROOT + "/export"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_dir))
	var report: Dictionary = TilesetPNG.write(export_dir, "chaine", painting2, guide, Modes.MINIMAL)
	_check(int(report.get("error", FAILED)) == OK and bool(report.get("is_exportable", false)),
			"exporter : la feuille est complete et l'export accepte")
	var written: PackedStringArray = report.get("written", PackedStringArray())
	_check(written.size() >= 4, "exporter : planches, preuve et manifeste ecrits (%d fichiers)" % written.size())

	# 4. Installer chez un acheteur : un dossier avec un project.godot, rien d'autre.
	var buyer: String = ROOT + "/acheteur"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(buyer))
	var config: FileAccess = FileAccess.open(buyer + "/project.godot", FileAccess.WRITE)
	config.store_string("config_version=5\n\n[application]\n\nconfig/name=\"AcheteurTest\"\n\n[editor_plugins]\n\nenabled=PackedStringArray(\"res://addons/solupaint/plugin.cfg\")\n")
	config.close()
	var verdict: Dictionary = PluginInstall.analyse(buyer)
	_check(bool(verdict.get("can_install", false)), "installer : le projet acheteur est reconnu")
	var installed: Dictionary = PluginInstall.install(buyer)
	_check(int(installed.get("error", FAILED)) == OK and not PackedStringArray(installed.get("written", PackedStringArray())).is_empty(),
			"installer : le plugin est copie (%d fichiers)" % PackedStringArray(installed.get("written", PackedStringArray())).size())

	# 5. Deposer le tileset exporte chez l'acheteur, en octets.
	var deposit: String = buyer + "/solutiles"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(deposit))
	var deposited: int = 0
	for path: String in written:
		if _copy_bytes(path, deposit + "/" + path.get_file()):
			deposited += 1
	_check(deposited == written.size(), "deposer : le tileset est chez l'acheteur (%d fichiers)" % deposited)

	print("")
	print("projet acheteur : " + ProjectSettings.globalize_path(buyer))
	print("PARCOURS DE CHAINE (acte 1) : %d echec(s)." % _failures)
	quit(0 if _failures == 0 else 1)
