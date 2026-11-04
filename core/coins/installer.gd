extends RefCounted

## INSTALLER LE GREFFON — copier `addons/marching_squares/` dans un projet Godot, et y poser de quoi peindre : le
## tileset de l'artiste s'il est complet, l'ESSAI sinon (on ne livre jamais une planche à trous ; on le DIT).
## ⚠ On refuse un dossier qui n'est pas un projet Godot : écrire des fichiers que rien ne lira ressemblerait à une
## réussite (la règle de l'ancien installeur, `core/plugin_install.gd`, reprise telle quelle).

const Travail := preload("res://core/coins/travail.gd")
const Essai := preload("res://core/coins/essai.gd")
const Painting := preload("res://core/painting.gd")

const SOURCE := "res://addons/marching_squares"
const CIBLE := "addons/marching_squares"
const TILESET := "marching_squares"
## ⚠ L'EXPORT N'EMPORTE PAS L'ICÔNE EN CLAIR (seulement sa version importée : mesuré sur le pck du 4 novembre 2026) :
## depuis l'exe, la lire échouerait et l'installation s'arrêterait. Sa copie en texte est ici ; la sonde de l'éditeur
## vérifie qu'elle reste IDENTIQUE à `addons/marching_squares/icon.svg`.
const ICONE := """<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
  <!-- MARCHING SQUARES : un plateau arrondi vu de trois-quarts, sa lèvre claire et sa falaise. -->
  <path d="M3 3h10a2 2 0 0 1 2 2v4H1V5a2 2 0 0 1 2-2z" fill="#6fbf5a"/>
  <rect x="1" y="9" width="14" height="2" fill="#e8d394"/>
  <path d="M1 11h14v2a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2z" fill="#8a6c55"/>
</svg>
"""
const FICHIERS: Array[String] = ["README.md", "forme.gd", "icon.svg", "modele.gd", "planche.gd", "plugin.cfg",
		"plugin.gd", "world.gd"]


## Rend {erreur: OK ou code, dit: phrase à montrer, ecrits: [...]}.
static func installer(projet: String, peinture: Painting, meta: Dictionary) -> Dictionary:
	if projet == "" or not DirAccess.dir_exists_absolute(projet):
		return {"erreur": ERR_FILE_NOT_FOUND, "dit": "This folder does not exist.", "ecrits": []}
	if not FileAccess.file_exists(projet.path_join("project.godot")):
		return {"erreur": ERR_UNAVAILABLE, "dit": "This is not a Godot project: no project.godot at its root.", "ecrits": []}
	var dest := projet.path_join(CIBLE)
	var remplace := DirAccess.dir_exists_absolute(dest)
	DirAccess.make_dir_recursive_absolute(dest)
	var ecrits := []
	for nom: String in FICHIERS:
		var f := FileAccess.open(SOURCE.path_join(nom), FileAccess.READ)
		var octets := PackedByteArray()
		if f != null:
			octets = f.get_buffer(f.get_length())
		elif nom == "icon.svg":
			octets = ICONE.to_utf8_buffer()
		else:
			return {"erreur": ERR_FILE_NOT_FOUND, "dit": "Plugin file not found: %s" % nom, "ecrits": ecrits}
		var o := FileAccess.open(dest.path_join(nom), FileAccess.WRITE)
		if o == null:
			return {"erreur": FileAccess.get_open_error(), "dit": "Cannot write %s" % dest.path_join(nom), "ecrits": ecrits}
		o.store_buffer(octets)
		ecrits.append(dest.path_join(nom))
	var dit := "MarchingSquares plugin %s (%d files). Tick it in Project > Project Settings > Plugins." \
			% ["replaced" if remplace else "installed", ecrits.size()]
	var c := Travail.compte(peinture)
	var complet: bool = int(c.dessus) + int(c.falaises) == int(c.total_dessus) + int(c.total_falaises)
	var dossier := projet.path_join(TILESET)
	if complet:
		Travail.exporter(peinture, meta, dossier)
		dit += "\nYour tileset went with it, in %s/." % TILESET
	else:
		Essai.ecrire(dossier, peinture.resolution)
		dit += "\nYour tileset is not complete yet: the TRIAL went with it, in %s/, to place a world right away." % TILESET
	return {"erreur": OK, "dit": dit, "ecrits": ecrits}
