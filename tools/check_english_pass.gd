# LE BANC DE LA PASSE ANGLAISE : ce que l'acheteur LIT est-il en anglais, et tout compile-t-il ?
#
# ⚠ CE BANC A DEJA MENTI UNE FOIS, ET C'EST POURQUOI IL EST REECRIT. Premiere version : une
# LISTE de neuf fichiers ecrite a la main, et une poignee de mots francais. Elle annoncait
# « 0 ligne de francais » pendant que `core/plugin_install.gd` -- qui n'etait pas dans la liste --
# affichait « SoluPaint remplace (9 files) » a l'acheteur. Les deux fautes sont la meme :
#
#   1. UNE LISTE ECRITE A LA MAIN NE COUVRE QUE CE QU'ON A PENSE A Y METTRE. On PARCOURT donc
#      les dossiers : un fichier neuf est couvert le jour ou il nait, sans que personne y pense.
#   2. UNE POIGNEE DE MOTS NE COUVRE QUE LES MOTS QU'ON A PREVUS. `remplace` et `installe`
#      passaient a travers -- des VERBES, la ou la liste ne portait que des noms.
#
# ⚠ ET LES MOTS SE TESTENT AUX FRONTIERES. Sans ca `installe` matche `installed`, et le banc crie
# au loup jusqu'a ce qu'on cesse de le lire. Un controle qui ne verifie pas son propre positif use
# la confiance qu'il devrait construire.
#
# ⚠ ET « CHARGE » NE VEUT PAS DIRE « COMPILE ». Un script dont l'analyse echoue rend quand meme
# une ressource, vide de ses fonctions, sans un mot. `can_instantiate()` tranche.
extends SceneTree

## Ce que l'acheteur peut LIRE : l'editeur, le noyau qui l'alimente, le plugin qui part chez lui.
## ⚠ `tools/`, `proof/` et `tests/` sont exclus a l'export : leur francais ne se vend pas.
const LOOKED_AT: PackedStringArray = ([
	"res://core", "res://ui", "res://addons/solupaint", "res://exporters", "res://render",
] as PackedStringArray)

## Des mots qui n'existent qu'en francais. ⚠ TESTES AUX FRONTIERES DE MOT -- voir l'en-tete.
## ⚠ On evite tout ce que l'anglais partage : `case`, `image`, `table`, `note`, `impossible`,
## `distance`, `simple`. Un faux positif de plus, c'est un vrai de moins qu'on lit.
const FRENCH: PackedStringArray = ([
	"Cliquez", "Choisissez", "Ouvrez", "Ouvrir", "Enregistrer", "Peindre", "peignez", "peint",
	"tuile", "tuiles", "etage", "etages", "aucune", "aucun", "Aucun", "Aucune",
	"remplace", "remplacee", "installe", "installee", "ecrit", "ecrire", "ecrite",
	"cree", "creer", "trouve", "trouvee", "manque", "fichier", "dossier", "planche",
	"falaise", "jupe", "monde", "voisine", "pinceau", "crayon", "gomme",
	"vide", "plaine", "reseau", "paysage", "damier", "sceau", "carnet",
	"vous", "votre", "avec", "dans", "pour", "sans", "deja", "meme", "cette", "chaque",
	"toutes", "rien", "depuis", "ainsi", "donc", "ceci", "cela",
] as PackedStringArray)

## ⚠ CE QUI N'EST PAS VENDU, ET POURQUOI. Ces fichiers portent du francais et le garderont :
## aucun n'est atteignable depuis l'ecran de l'acheteur. Les ecarter est un choix, donc il
## s'ecrit -- une exclusion muette redeviendrait le trou que ce banc existe pour fermer.
##   domain.gd          la DOC du domaine, lue par nous, jamais affichee
##   brink.gd           ANCIEN modele, plus preche par ui/ ni par addons/
##   contour.gd         ANCIEN modele, idem
##   tileset_png.gd     ANCIEN exportateur, remplace par massif_tileset
##   trial_tileset.gd   ANCIEN essai, remplace par massif_trial
const NOT_SOLD: PackedStringArray = ([
	"domain.gd", "brink.gd", "contour.gd", "tileset_png.gd", "trial_tileset.gd",
] as PackedStringArray)


func _initialize() -> void:
	var files: PackedStringArray = PackedStringArray()
	for root: String in LOOKED_AT:
		_gather(root, files)

	var bad: int = 0
	var scripts: int = 0
	for path: String in files:
		if not path.ends_with(".gd"):
			continue
		scripts += 1
		var script: Resource = load(path)
		if script == null:
			print("ECHEC  %s : ne se charge pas" % path)
			bad += 1
		elif not (script as GDScript).can_instantiate():
			print("ECHEC  %s : se charge mais NE COMPILE PAS" % path)
			bad += 1

	# ⚠ COMPILER N'EST PAS S'EXECUTER. Le manuel LIT son compte de tuiles dans
	# `Families.massif_tiles()` plutot que de l'ecrire en dur ; si l'expression cassait,
	# `can_instantiate()` resterait vert et l'acheteur ouvrirait un onglet VIDE.
	var manual: Object = (load("res://ui/manual.gd") as GDScript).new()
	for page: String in ["_hands_on", "_how_it_works", "_the_contract"]:
		var body: String = String(manual.call(page))
		if body.length() < 200:
			print("ECHEC  manual.%s() rend %d caracteres" % [page, body.length()])
			bad += 1
	manual.free()

	if load("res://ui/editor.tscn") == null:
		print("ECHEC  res://ui/editor.tscn : ne se charge pas")
		bad += 1

	var leftovers: int = 0
	for path2: String in files:
		if NOT_SOLD.has(path2.get_file()):
			continue
		for hit: String in _french_in(path2):
			print("FRANCAIS  %-24s %s" % [path2.get_file(), hit])
			leftovers += 1

	print("")
	print("%d fichiers parcourus (%d scripts), %d echec(s) de compilation"
			% [files.size(), scripts, bad])
	print("francais visible restant : %d" % leftovers)
	quit(1 if (bad > 0 or leftovers > 0) else 0)


## Tout ce qui peut porter du texte visible, en descendant les dossiers.
func _gather(root: String, into: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var found: String = dir.get_next()
	while found != "":
		var path: String = root.path_join(found)
		if dir.current_is_dir():
			if not found.begins_with("."):
				_gather(path, into)
		elif found.ends_with(".gd") or found.ends_with(".tscn") or found.ends_with(".cfg"):
			into.append(path)
		found = dir.get_next()
	dir.list_dir_end()


## Les chaines d'un fichier qui portent un mot francais.
##
## ⚠ ON IGNORE LES COMMENTAIRES : le code est ecrit en francais et le restera -- il ne se vend
## pas. Ce qu'on traque, c'est ce qui sort a l'ecran, donc ce qui est ENTRE GUILLEMETS.
func _french_in(path: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return found
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("#") or line.begins_with(";"):
			continue
		for piece: String in _quoted(line):
			if piece.begins_with("res://") or piece.begins_with("user://"):
				continue
			for word: String in FRENCH:
				if _has_word(piece, word):
					found.append("%-11s dans \"%s\"" % [word, piece.substr(0, 60)])
					break
	return found


## Les morceaux entre guillemets d'une ligne.
func _quoted(line: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var parts: PackedStringArray = line.split("\"")
	var index: int = 1
	while index < parts.size():
		out.append(parts[index])
		index += 2
	return out


## ⚠ AUX FRONTIERES DE MOT. Sans ca `installe` matche `installed` et le banc crie au loup.
func _has_word(text: String, word: String) -> bool:
	var at: int = text.findn(word)
	while at >= 0:
		var before_ok: bool = at == 0 or not _is_letter(text[at - 1])
		var after: int = at + word.length()
		var after_ok: bool = after >= text.length() or not _is_letter(text[after])
		if before_ok and after_ok:
			return true
		at = text.findn(word, at + 1)
	return false


func _is_letter(glyph: String) -> bool:
	return (glyph >= "a" and glyph <= "z") or (glyph >= "A" and glyph <= "Z")
