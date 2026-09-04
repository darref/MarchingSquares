# LE MANIFESTE — ce que l'acheteur a recu, relu par le plugin.
#
# Le fichier `<nom>_tileset.txt` n'est pas une notice, c'est le CONTRAT : il porte la regle
# de pose en entier, et la table des cases. Ce lecteur en tire ce dont le plugin a besoin
# pour poser une tuile, et rien de plus.
#
# ⚠ IL REFUSE PLUTOT QUE DE DEVINER (charte, regle 5). Cinq refus, et chacun a sa raison :
#
#   - un fichier qui ne s'annonce pas comme un manifeste SoluTiles ;
#   - une version plus RECENTE que celle que ce plugin sait lire -- une regle de pose a pu
#     changer de sens, et poser quand meme serait un mensonge silencieux ;
#   - une version TROP VIEILLE, pour exactement la meme raison. ⚠ CE REFUS-LA A MANQUE UNE
#     FOIS, et son absence a laisse passer un vrai defaut : entre deux livraisons, le
#     hors-carte est passe de la plaine au VIDE sans que la version bouge, et le plugin
#     posait les deux. Un garde-fou qui ne regarde que d'un cote ne garde rien ;
#   - une HAUTEUR D'ETAGE qui n'est pas la sienne. Un tileset dont l'etage descend de quatre
#     rangees, pose par un moteur qui en compte trois, donnerait un monde faux SANS UNE
#     SEULE ERREUR -- le pire des defauts, celui qui ne se signale pas ;
#   - un VOCABULAIRE qui n'est pas le sien. Le nombre de tuiles est ecrit en clair dans le
#     manifeste ; s'il differe, la planche et ce moteur ne parlent pas du meme modele.
#
# ⚠ ET IL NE RECALCULE PAS LA TABLE DES CASES. Le manifeste la donne en clair ; la deduire
# de la regle marcherait aujourd'hui et se casserait le jour ou la disposition changera. On
# lit ce qui est ecrit.
extends RefCounted

const Rules := preload("res://addons/solupaint/rules.gd")

const MAGIC: String = "solutiles-tileset"

## Les versions que ce plugin sait lire, bornes comprises.
##
## ⚠ LES DEUX BORNES SONT NECESSAIRES. La haute dit « je ne connais pas encore cette
## regle » ; la basse dit « je ne connais plus celle-la ».
##
## ⚠ LA V8 EST REFUSEE NOMMEMENT. Elle decrivait l'ancien modele -- une surface plus une robe,
## deux planches, sept bits de contexte, des poses arriere. Le modele des massifs pose un
## massif ENTIER, une tuile est le couple (silhouette d'empreinte, bande), et il n'y a plus
## qu'un bit. Un lecteur qui poserait un v8 avec ces regles-ci fabriquerait un autre monde.
const READS_FROM: int = 9
const READS_UP_TO: int = 9

## La seule famille du modele.
const BY_MASSIF: StringName = &"massif"

## LE VOCABULAIRE QUE CE MOTEUR SAIT POSER. ⚠ ECRIT ICI, ET COMPARE AU NOYAU PAR LA SUITE :
## le plugin est SEUL dans le projet de l'acheteur, il porte donc sa copie du compte, et la
## suite verifie qu'il dit la meme chose que `Families.massif_tiles()`. Le jour ou le
## vocabulaire grandit -- il ne peut que grandir -- la suite le dit ici, et non chez
## l'acheteur.
const MASSIF_TILES: int = 39

## Le suffixe qui reconnait un manifeste sans l'ouvrir.
const SUFFIX: String = "_tileset.txt"

## Les dossiers qu'on ne fouille jamais : ceux du moteur, pas ceux de l'acheteur.
const SKIPPED: Array[String] = [".godot", ".git", ".import"]

## Jusqu'ou descendre. ⚠ UNE BORNE, PARCE QU'ON FOUILLE LE PROJET DE QUELQU'UN D'AUTRE :
## un lien circulaire ou une arborescence de mille dossiers ne doit pas figer son editeur.
const MAX_DEPTH: int = 6


## TOUS LES MANIFESTES DU PROJET, DANS L'ORDRE DE LECTURE.
##
## ⚠ ON NE DEMANDE PAS A L'ACHETEUR CE QU'ON PEUT TROUVER. Pointer un fichier a la main
## est le genre de geste qui fait abandonner un outil : il faut savoir ce qu'on cherche, ou
## il se trouve, et que ce soit LUI qu'on cherche. Un tileset SoluTiles se reconnait a son
## nom ; on le propose, et s'il n'y en a qu'un on le prend sans rien demander.
##
## ⚠ ON REGARDE LE NOM, PAS LE CONTENU. Ouvrir chaque `.txt` du projet pour voir s'il
## s'annonce couterait un balayage complet a chaque fois ; le suffixe suffit a proposer, et
## `parse` refuse ensuite ce qui n'en est pas un.
static func discover(from: String = "res://") -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	_walk(from, 0, found)
	found.sort()
	return found


static func _walk(folder: String, depth: int, into: PackedStringArray) -> void:
	if depth > MAX_DEPTH:
		return
	var directory: DirAccess = DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		if directory.current_is_dir():
			if not entry.begins_with(".") and not SKIPPED.has(entry):
				_walk(folder.path_join(entry), depth + 1, into)
		elif entry.ends_with(SUFFIX):
			into.append(folder.path_join(entry))
		entry = directory.get_next()
	directory.list_dir_end()


## Un nom court, pour une liste deroulante : le dossier et le tileset, sans le suffixe.
static func label_of(path: String) -> String:
	var name: String = path.get_file().trim_suffix(SUFFIX)
	var folder: String = path.get_base_dir().get_file()
	return name if folder.is_empty() else "%s  (%s)" % [name, folder]


## Relit un manifeste.
##
## Cles rendues :
##   error       : Error
##   reason      : String                    ce qui cloche, en clair, quand error != OK
##   version     : int
##   mode        : String
##   tile_size   : int
##   family      : StringName                `massif`
##   sheet       : String                    nom de fichier, a cote du manifeste
##   slots       : Dictionary[int, Vector2i] cle de tuile -> case de la planche
static func parse(text: String) -> Dictionary:
	var result: Dictionary = _blank()

	var lines: PackedStringArray = text.split("\n")
	if lines.is_empty() or not lines[0].begins_with(MAGIC + " "):
		return _refuse(result, "Ce fichier n'est pas un manifeste SoluTiles.")
	result["version"] = lines[0].get_slice(" ", 1).to_int()
	if int(result["version"]) > READS_UP_TO:
		return _refuse(result, "Manifeste en version %d ; ce plugin lit jusqu'a %d."
				% [int(result["version"]), READS_UP_TO])
	if int(result["version"]) < READS_FROM:
		return _refuse(result, "Manifeste en version %d ; ce plugin lit a partir de %d. "
				% [int(result["version"]), READS_FROM]
				+ "Reexportez le tileset : la regle de pose a change de sens depuis.")

	var fall: int = -1
	var counted: int = -1

	for number: int in range(1, lines.size()):
		var line: String = lines[number].strip_edges()
		# ⚠ LE COMMENTAIRE PEUT SUIVRE LA VALEUR. Le manifeste met le nom lisible d'une tuile
		# apres un `#` sur la meme ligne : le couper d'abord, sinon « slot 0,0  # SURFACE 255 »
		# se lirait comme une valeur de plusieurs mots.
		var hash: int = line.find("#")
		if hash >= 0:
			line = line.substr(0, hash).strip_edges()
		if line.is_empty():
			continue
		var head: String = line.get_slice(" ", 0)
		match head:
			"mode":
				result["mode"] = line.get_slice(" ", 1)
			"tile_size":
				result["tile_size"] = line.get_slice(" ", 1).to_int()
			"fall_rows":
				fall = line.get_slice(" ", 1).to_int()
			"tiles":
				counted = line.get_slice(" ", 1).to_int()
			"famille":
				result["family"] = StringName(line.get_slice(" ", 1))
			"sheet":
				result["sheet"] = line.get_slice(" ", 1)
			"tile":
				var tile: int = line.get_slice(" ", 1).to_int()
				result["slots"][tile] = _point(line.get_slice(" ", 3))

	# ⚠ UNE CONSTANTE ABSENTE SE REFUSE, ET SE DIT AUTREMENT QU UNE CONSTANTE FAUSSE. Un
	# manifeste qui ne declare pas sa hauteur d etage ne peut pas etre CONTROLE : le poser
	# reviendrait a le croire sur parole. Et le message doit envoyer au bon geste -- reexporter
	# -- plutot que d annoncer « -1 rangees par etage », qui n aide personne.
	if fall < 0 or counted < 0:
		return _refuse(result, "Ce manifeste ne declare ni sa hauteur d'etage ni son "
				+ "vocabulaire : il vient d'une version anterieure. Reexportez-le depuis "
				+ "SoluTiles.")
	if fall != Rules.FALL:
		return _refuse(result, ("Ce tileset compte %d rangees par etage ; ce plugin en pose %d."
				% [fall, Rules.FALL]))
	if counted != MASSIF_TILES:
		return _refuse(result, ("Ce tileset annonce %d tuiles ; ce plugin en pose %d. "
				% [counted, MASSIF_TILES])
				+ "Le vocabulaire a change : mettez le plugin a jour.")
	if result["family"] != BY_MASSIF:
		return _refuse(result, "Famille inconnue : '%s'." % result["family"])
	if result["sheet"] == "":
		return _refuse(result, "Le manifeste ne nomme pas sa planche.")
	if result["slots"].is_empty():
		return _refuse(result, "Le manifeste ne place aucune tuile.")
	return result


static func read(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var failed: Dictionary = _blank()
		return _refuse(failed, "Manifeste illisible : %s" % path)
	var text: String = file.get_as_text()
	file.close()
	return parse(text)


## Vrai si le manifeste place toutes les tuiles du vocabulaire.
##
## ⚠ ET C'EST UN CONTROLE, PAS UNE POLITESSE. Il ne manque jamais une tuile a un export
## honnete -- l'exportateur refuse une feuille incomplete. S'il en manque une ici, c'est que
## le fichier a ete retouche a la main, et poser les autres laisserait un trou qu'on
## decouvrirait dans le jeu.
static func is_complete(report: Dictionary) -> bool:
	if int(report["error"]) != OK:
		return false
	return report["slots"].size() == MASSIF_TILES


static func _point(text: String) -> Vector2i:
	var comma: int = text.find(",")
	if comma < 0:
		return Vector2i(-1, -1)
	return Vector2i(text.substr(0, comma).to_int(), text.substr(comma + 1).to_int())


static func _blank() -> Dictionary:
	var slots: Dictionary = {}
	return {
		"error": OK,
		"reason": "",
		"version": 0,
		"mode": "",
		"tile_size": 0,
		"family": BY_MASSIF,
		"sheet": "",
		"slots": slots,
	}


## ⚠ UN REFUS N'EST PAS UNE ERREUR DE CONSOLE. On rend la raison en clair, a charge de
## l'appelant de la montrer : un `push_error` ici remplirait la sortie de l'acheteur de
## rouge pour un fichier qu'il vient simplement de choisir par erreur.
static func _refuse(result: Dictionary, reason: String) -> Dictionary:
	result["error"] = ERR_FILE_UNRECOGNIZED
	result["reason"] = reason
	return result
