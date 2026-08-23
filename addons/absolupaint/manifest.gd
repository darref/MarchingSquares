# LE MANIFESTE — ce que l'acheteur a recu, relu par le plugin.
#
# Le fichier `<nom>_tileset.txt` n'est pas une notice, c'est le CONTRAT : il porte la regle
# de pose en entier, et la table des cases. Ce lecteur en tire ce dont le plugin a besoin
# pour poser une tuile, et rien de plus.
#
# ⚠ IL REFUSE PLUTOT QUE DE DEVINER (charte, regle 5). Trois refus, et chacun a sa raison :
#
#   - un fichier qui ne s'annonce pas comme un manifeste AbsoluTiles ;
#   - une version plus recente que celle que ce plugin sait lire -- une regle de pose a pu
#     changer de sens, et poser quand meme serait un mensonge silencieux ;
#   - une version TROP VIEILLE, pour exactement la meme raison. ⚠ CE REFUS-LA MANQUAIT, et
#     son absence a laisse passer un vrai defaut : entre deux livraisons, le hors-carte est
#     passe de la plaine au VIDE et le sous-pied est apparu, SANS que la version bouge. Un
#     manifeste v3 d'avant et un v3 d'apres decrivaient deux mondes differents, et le plugin
#     les posait tous les deux. Un garde-fou qui ne regarde que d'un cote ne garde rien ;
#   - des constantes de falaise (`storey_tiles`, `body_rows`, `block_rows`) qui ne sont pas
#     celles que `rules.gd` sait rejouer. Un tileset dont l'etage descend de quatre cases
#     pose sur un moteur qui en compte trois donnerait un monde faux SANS UNE SEULE ERREUR.
#
# ⚠ ET IL NE RECALCULE PAS LA TABLE DES CASES. Le manifeste la donne en clair ; la deduire
# de la regle marcherait aujourd'hui et se casserait le jour ou la disposition changera. On
# lit ce qui est ecrit.
extends RefCounted

const Rules := preload("res://addons/absolupaint/rules.gd")

const MAGIC: String = "absolutiles-tileset"

## Les versions que ce plugin sait lire, bornes comprises.
##
## ⚠ LES DEUX BORNES SONT NECESSAIRES. La haute dit « je ne connais pas encore cette
## regle » ; la basse dit « je ne connais plus celle-la ». La v3 est refusee parce que son
## sens a change sous elle : le hors-carte y valait la plaine, et rien ne distingue un v3
## d'avant d'un v3 d'apres.
##
## ⚠ LA V4 TOMBE POUR LA MEME RAISON : la POSE DERRIERE -- le corps repose sous une case
## qui ecrete -- n'y est pas ecrite, et ce plugin la pose. Un second lecteur, fidele a un
## fichier v4, poserait un autre monde que lui : deux lecteurs, deux mondes, exactement
## ce que le contrat existe pour interdire.
const READS_FROM: int = 5
const READS_UP_TO: int = 5

const BY_CELL: StringName = &"cell"
const BY_CORNER: StringName = &"corner"


## Relit un manifeste.
##
## Cles rendues :
##   error          : Error
##   reason         : String       ce qui cloche, en clair, quand error != OK
##   version        : int
##   mode           : String
##   tile_size      : int
##   family         : StringName   `cell` ou `corner`
##   surface_sheet  : String       nom de fichier, a cote du manifeste
##   surface_slots  : Dictionary[int, Vector2i]       index -> case de la planche
##   walls_sheet    : String
##   wall_slots     : Dictionary[Vector2i, Vector2i]  role  -> case de la planche
##   proof_sheet    : String       peut rester vide : c'est une preuve, pas une donnee
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
## il se trouve, et que ce soit LUI qu'on cherche. Un tileset AbsoluTiles se reconnait a son
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


static func parse(text: String) -> Dictionary:
	var result: Dictionary = _blank()

	var lines: PackedStringArray = text.split("\n")
	if lines.is_empty() or not lines[0].begins_with(MAGIC + " "):
		return _refuse(result, "Ce fichier n'est pas un manifeste AbsoluTiles.")
	result["version"] = lines[0].get_slice(" ", 1).to_int()
	if int(result["version"]) > READS_UP_TO:
		return _refuse(result, "Manifeste en version %d ; ce plugin lit jusqu'a %d."
				% [int(result["version"]), READS_UP_TO])
	if int(result["version"]) < READS_FROM:
		return _refuse(result, "Manifeste en version %d ; ce plugin lit a partir de %d. "
				% [int(result["version"]), READS_FROM]
				+ "Reexportez le tileset : la regle de pose a change de sens depuis.")

	var storey: int = -1
	var body: int = -1
	var block: int = -1

	for number: int in range(1, lines.size()):
		var line: String = lines[number].strip_edges()
		# ⚠ LE COMMENTAIRE PEUT SUIVRE LA VALEUR. Le manifeste met le nom lisible d'un index
		# apres un `#` sur la meme ligne : le couper d'abord, sinon « slot 0,0  # N+E » se
		# lirait comme une valeur de trois mots.
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
			"storey_tiles":
				storey = line.get_slice(" ", 1).to_int()
			"body_rows":
				body = line.get_slice(" ", 1).to_int()
			"block_rows":
				block = line.get_slice(" ", 1).to_int()
			"famille":
				result["family"] = StringName(line.get_slice(" ", 1))
			"surface":
				result["surface_sheet"] = line.get_slice(" ", 1)
			"walls":
				result["walls_sheet"] = line.get_slice(" ", 1)
			"proof":
				result["proof_sheet"] = line.get_slice(" ", 1)
			"index":
				var index: int = line.get_slice(" ", 1).to_int()
				result["surface_slots"][index] = _point(line.get_slice(" ", 3))
			"role":
				var role: Vector2i = _point(line.get_slice(" ", 1))
				result["wall_slots"][role] = _point(line.get_slice(" ", 3))

	if storey != Rules.STOREY_TILES or body != Rules.BODY_ROWS or block != Rules.BLOCK_ROWS:
		return _refuse(result, ("Ce tileset compte %d cases par etage, %d rangees de corps "
				+ "et %d rangees de bloc ; ce plugin en pose %d, %d et %d.")
				% [storey, body, block, Rules.STOREY_TILES, Rules.BODY_ROWS, Rules.BLOCK_ROWS])
	if result["surface_sheet"] == "" or result["walls_sheet"] == "":
		return _refuse(result, "Le manifeste ne nomme pas ses deux planches.")
	if result["surface_slots"].is_empty() or result["wall_slots"].is_empty():
		return _refuse(result, "Le manifeste ne place aucune tuile.")
	if not (result["family"] == BY_CELL or result["family"] == BY_CORNER):
		return _refuse(result, "Famille de surface inconnue : '%s'." % result["family"])
	return result


static func read(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var failed: Dictionary = _blank()
		return _refuse(failed, "Manifeste illisible : %s" % path)
	var text: String = file.get_as_text()
	file.close()
	return parse(text)


## Le nombre de tuiles de surface que la famille attend. Sert au controle de completude :
## une planche a qui il manque une case laisserait un trou dans le monde de l'acheteur.
static func expected_surface_tiles(family: StringName) -> int:
	return 15 if family == BY_CORNER else 47


## Vrai si le manifeste place toutes les tuiles que sa famille exige.
static func is_complete(report: Dictionary) -> bool:
	if int(report["error"]) != OK:
		return false
	if report["surface_slots"].size() != expected_surface_tiles(report["family"]):
		return false
	return report["wall_slots"].size() == Rules.PAN_COUNT * Rules.BLOCK_ROWS


static func _point(text: String) -> Vector2i:
	var comma: int = text.find(",")
	if comma < 0:
		return Vector2i(-1, -1)
	return Vector2i(text.substr(0, comma).to_int(), text.substr(comma + 1).to_int())


static func _blank() -> Dictionary:
	var surface_slots: Dictionary = {}
	var wall_slots: Dictionary = {}
	return {
		"error": OK,
		"reason": "",
		"version": 0,
		"mode": "",
		"tile_size": 0,
		"family": BY_CELL,
		"surface_sheet": "",
		"walls_sheet": "",
		"proof_sheet": "",
		"surface_slots": surface_slots,
		"wall_slots": wall_slots,
	}


## ⚠ UN REFUS N'EST PAS UNE ERREUR DE CONSOLE. On rend la raison en clair, a charge de
## l'appelant de la montrer : un `push_error` ici remplirait la sortie de l'acheteur de
## rouge pour un fichier qu'il vient simplement de choisir par erreur.
static func _refuse(result: Dictionary, reason: String) -> Dictionary:
	result["error"] = ERR_FILE_UNRECOGNIZED
	result["reason"] = reason
	return result
