# INSTALLER SOLUPAINT CHEZ L'ACHETEUR — copier un dossier, et refuser le reste.
#
# Le logiciel fabrique un tileset ; le plugin le pose dans un jeu. Entre les deux il y a un
# geste que personne n'a envie de faire a la main : trouver le dossier `addons/`, creer
# l'arborescence, ne rien oublier. Ce bouton est pour l'acheteur, et il doit donc etre plus
# sur qu'un copier-coller, pas seulement plus rapide.
#
# ⚠ IL REFUSE UN DOSSIER QUI N'EST PAS UN PROJET GODOT (charte, regle 5). Sans `project.godot`
# a la racine, `addons/` ne veut rien dire : on ecrirait six fichiers dans les documents de
# quelqu'un sans que rien ne les lise jamais. Le refus se dit, il ne se devine pas.
#
# ⚠ ET IL NE TOUCHE PAS AU `project.godot` DE L'ACHETEUR. Activer l'extension demanderait de
# le reecrire ; un fichier de projet reecrit par un tiers perd ses commentaires et peut
# perdre bien pire. On copie, et on dit la seule chose qui reste a faire -- cocher la case
# dans les parametres. Une phrase a lire vaut mieux qu'un fichier abime.
#
# ⚠ LA LISTE DES FICHIERS EST ECRITE ICI, ET LA SUITE VERIFIE QU'ELLE DIT VRAI. Lister le
# dossier a l'execution marcherait en developpement et se casserait dans un binaire exporte,
# ou `res://` n'est plus un dossier mais une archive. La liste est donc une donnee -- donc un
# endroit ou mentir -- et c'est exactement pourquoi un test la compare au dossier reel.
extends RefCounted

## D'ou l'on copie, dans le logiciel.
const SOURCE: String = "res://addons/solupaint"

## Ou l'on ecrit, chez l'acheteur, relativement a la racine de son projet.
const TARGET: String = "addons/solupaint"

## Ce qui compose le plugin. Verifie par la suite de tests contre le dossier reel.
const FILES: Array[String] = [
	"README.md",
	"dock.gd",
	"icon.svg",
	"manifest.gd",
	"plugin.cfg",
	"plugin.gd",
	"rules.gd",
	"signature.gd",
	"tileset.gd",
	"world.gd",
]

## Le fichier qui fait d'un dossier un projet Godot.
const PROJECT_FILE: String = "project.godot"


## Ce que l'installation ferait, sans rien ecrire.
##
## C'est ce que le bouton interroge pour savoir s'il a le droit de s'ouvrir : la barre
## d'outils et l'ecriture repondent a la meme fonction, donc elles ne peuvent pas se
## contredire (charte, regle 4).
##
## Cles rendues :
##   is_project : bool    le dossier vise est bien un projet Godot
##   replaces   : bool    une version du plugin y est deja
##   reason     : String  pourquoi c'est refuse, en clair ; vide si tout va bien
##   can_install: bool
static func analyse(project_folder: String) -> Dictionary:
	if project_folder == "":
		return _verdict(false, false, "No folder chosen.")
	if not DirAccess.dir_exists_absolute(project_folder):
		return _verdict(false, false, "This folder does not exist.")
	if not FileAccess.file_exists(project_folder.path_join(PROJECT_FILE)):
		return _verdict(false, false,
				"This is not a Godot project: no %s at its root." % PROJECT_FILE)
	var replaces: bool = DirAccess.dir_exists_absolute(project_folder.path_join(TARGET))
	return _verdict(true, replaces, "")


## Copie le plugin dans le projet vise.
##
## Cles rendues : celles d'`analyse()`, plus
##   error   : Error
##   written : PackedStringArray  les chemins ecrits
static func install(project_folder: String) -> Dictionary:
	var report: Dictionary = analyse(project_folder)
	report["error"] = OK
	report["written"] = PackedStringArray()
	if not bool(report["can_install"]):
		report["error"] = ERR_UNAVAILABLE
		return report

	var destination: String = project_folder.path_join(TARGET)
	if DirAccess.make_dir_recursive_absolute(destination) != OK 			and not DirAccess.dir_exists_absolute(destination):
		report["error"] = ERR_CANT_CREATE
		report["reason"] = "Cannot create %s." % TARGET
		return report

	# ⚠ ON LIT EN OCTETS, PAS EN TEXTE. Un `.gd` relu comme texte puis reecrit changerait ses
	# fins de ligne selon la plateforme ; le plugin doit arriver identique a ce qu'on teste.
	var written: PackedStringArray = PackedStringArray()
	for file_name: String in FILES:
		var bytes: PackedByteArray = _read(SOURCE.path_join(file_name))
		if bytes.is_empty():
			report["error"] = ERR_FILE_NOT_FOUND
			report["reason"] = "Plugin file not found: %s" % file_name
			return report
		var out_path: String = destination.path_join(file_name)
		var out: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
		if out == null:
			report["error"] = FileAccess.get_open_error()
			report["reason"] = "Cannot write: %s" % out_path
			return report
		out.store_buffer(bytes)
		out.close()
		written.append(out_path)

	report["written"] = written
	return report


## La phrase a montrer apres coup. Elle dit ce qui a ete fait ET ce qui reste a faire :
## le plugin copie ne sert a rien tant qu'il n'est pas coche dans les parametres du projet.
static func summary(report: Dictionary) -> String:
	if int(report["error"]) != OK:
		return String(report["reason"])
	var verb: String = "replaced" if bool(report["replaces"]) else "installed"
	return "SoluPaint %s (%d files). You still have to tick it: Project > Settings > Plugins." 			% [verb, PackedStringArray(report["written"]).size()]


static func _read(path: String) -> PackedByteArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	return bytes


static func _verdict(is_project: bool, replaces: bool, reason: String) -> Dictionary:
	return {
		"is_project": is_project,
		"replaces": replaces,
		"reason": reason,
		"can_install": is_project,
	}
