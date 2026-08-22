# LE TRAVAIL EN COURS — lecture et ecriture de ce qui a ete peint.
#
# ⚠ LE FICHIER RANGE L'ART PAR TUILE, JAMAIS PAR CASE. C'est la seule decision de ce
# fichier, et elle porte tout le reste. Une case du guide n'est qu'un ENDROIT ou l'on a
# peint ; ce qui a de la valeur, c'est la TUILE -- l'index de surface, ou le role de robe.
# Rangee par case, une sauvegarde mourrait au premier retouchage du guide : compacter
# `minimal.txt` d'une ligne decalerait tout et l'art serait perdu. Rangee par tuile, le
# guide peut etre redessine, agrandi, compacte, remplace par celui d'un autre mode -- l'art
# retombe sur ses pieds, puisqu'on le range sous le nom de ce qu'il represente.
#
# Consequence heureuse et gratuite : un travail commence en `minimal` se recharge en
# `ample`. Les deux modes livrent les memes 59 tuiles ; seul le nombre d'exemplaires change.
#
# LES CLES. Une tuile se nomme par ce qu'elle est, plus son rang de variante :
#   S<index>:<variante>        surface par case, index blob canonique
#   C<index>:<variante>        surface a cheval, index du croisement
#   W<pan>,<rangee>:<variante> robe
#
# ⚠ `S` ET `C` NE SE MELANGENT JAMAIS DANS UN MEME FICHIER : ce sont deux familles, et un
# travail appartient a l'une ou a l'autre. L'en-tete le dit par une ligne `famille`.
# Le rang de variante est la position de la case dans son groupe, en ordre de lecture.
# Rang 0 est donc toujours la premiere occurrence de la tuile dans le guide, celle qui
# existe forcement -- une tuile n'entre au guide qu'au moins une fois.
#
# ⚠ CE QUI NE RETOMBE PAS SUR SES PIEDS EST DIT, PAS JETE. Si le nouveau guide offre moins
# d'exemplaires d'une tuile que le fichier n'en portait, les variantes en trop sont
# rendues dans `unplaced`. On ne perd pas du travail en silence -- meme regle que les
# pixels peints hors du guide dans `variants.gd`.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Families := preload("res://core/families.gd")

const EXTENSION: String = "absolutiles"

## En-tete du fichier. Le numero monte le jour ou le format change, et il ne changera que
## si les CLES changent -- pas pour un guide retouche, c'est tout l'interet.
const MAGIC: String = "absolutiles"
## ⚠ VERSION 2 : LE VOCABULAIRE DES ROBES A CHANGE. Un pan v1 valait 0..2 (gauche, courant,
## droit) ; un pan v2 vaut 0..8 (le couple des deux flancs). Reposer une cle `W` de v1 sous
## v2 la mettrait de travers en silence -- exactement ce que ce fichier existe pour eviter.
## Les cles `S` de surface, elles, n'ont pas bouge et se relisent sans rien perdre.
const VERSION: int = 2


## La cle de la tuile portee par chaque case du guide.
##
## Cette table est l'annuaire du fichier : elle dit sous quel nom ranger ce qui est peint
## ici, et reciproquement ou reposer ce qu'on relit. Les cases sans tuile -- la plaine --
## n'y figurent pas : elles ne se peignent pas (charte, regle 5).
static func slots(heights: PackedStringArray) -> Dictionary:
	var by_cell: Dictionary = {}

	var groups: Dictionary = Coverage.cells_by_index(Coverage.index_map(heights))
	for index: int in groups.keys():
		var cells: Array[Vector2i] = _sorted(groups[index])
		for rank: int in range(cells.size()):
			by_cell[cells[rank]] = "S%d:%d" % [index, rank]

	var roles: Dictionary = Walls.cells_by_role(Walls.visible_roles(heights))
	for role: Vector2i in roles.keys():
		var cells: Array[Vector2i] = _sorted(roles[role])
		for rank: int in range(cells.size()):
			by_cell[cells[rank]] = "W%d,%d:%d" % [role.x, role.y, rank]

	return by_cell


## Une cle, decomposee. C'est ce fichier qui possede le format des cles ; tout ce qui a
## besoin de les relire passe par ici plutot que de refaire l'analyse dans son coin.
##
## Cles rendues :
##   family : "S" surface par case, "C" surface a cheval, "W" robe, "" si illisible
##   index  : int      pour une surface
##   role   : Vector2i pour une robe (pan, rangee)
##   rank   : int      le rang de variante
static func describe(key: String) -> Dictionary:
	var blank: Dictionary = {"family": "", "index": -1, "role": Vector2i.ZERO, "rank": 0}
	var colon: int = key.rfind(":")
	if colon < 1:
		return blank
	var head: String = key.substr(1, colon - 1)
	var rank: int = key.substr(colon + 1).to_int()
	if key.begins_with("S") or key.begins_with("C"):
		return {"family": key.substr(0, 1), "index": head.to_int(), "role": Vector2i.ZERO,
				"rank": rank}
	if key.begins_with("W"):
		var comma: int = head.find(",")
		if comma < 0:
			return blank
		return {
			"family": "W",
			"index": -1,
			"role": Vector2i(head.substr(0, comma).to_int(), head.substr(comma + 1).to_int()),
			"rank": rank,
		}
	return blank


## L'ANNUAIRE DE LA FAMILLE A CHEVAL : croisement -> cle.
##
## ⚠ IL VIT A PART, ET IL LE DOIT. Un croisement et une case sont tous deux des `Vector2i`
## mais ne designent pas la meme chose : les melanger dans un seul carnet ferait se marcher
## dessus la tuile du croisement (3,4) et la robe de la case (3,4). Deux familles, deux
## carnets, et la collision devient impossible par construction.
static func corner_slots(heights: PackedStringArray) -> Dictionary:
	var by_point: Dictionary = {}
	var groups: Dictionary = CornerIndex.points_by_index(CornerIndex.index_map(heights))
	for index: int in groups.keys():
		var points: Array[Vector2i] = _sorted(groups[index])
		for rank: int in range(points.size()):
			by_point[points[rank]] = "C%d:%d" % [index, rank]
	return by_point


## L'annuaire d'une famille, dans l'autre sens : cle -> ce qui la porte.
static func keys_of(heights: PackedStringArray, family: StringName) -> Dictionary:
	var by_key: Dictionary = {}
	var source: Dictionary = corner_slots(heights) if family == Families.BY_CORNER 			else slots(heights)
	for at: Vector2i in source.keys():
		by_key[String(source[at])] = at
	return by_key


## L'annuaire dans l'autre sens : ou reposer chaque tuile.
static func cells_by_key(heights: PackedStringArray) -> Dictionary:
	var by_key: Dictionary = {}
	var by_cell: Dictionary = slots(heights)
	for cell: Vector2i in by_cell.keys():
		by_key[String(by_cell[cell])] = cell
	return by_key


## ⚠ LE RANG DOIT ETRE STABLE, SINON L'ART CHANGE DE PLACE D'UNE SAUVEGARDE A L'AUTRE.
## L'ordre de lecture est le seul qui ne depende que du guide, jamais de l'ordre dans
## lequel un dictionnaire a ete rempli.
static func _sorted(cells: Array) -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	for cell: Vector2i in cells:
		copy.append(cell)
	copy.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		if left.y != right.y:
			return left.y < right.y
		return left.x < right.x)
	return copy


## Le fichier, en texte.
##
## Chaque tuile peinte tient sur une ligne : sa cle, puis son image en PNG encode en
## base64. Le PNG compresse, ce que ne ferait pas une liste de pixels : un aplat coute
## quelques octets au lieu de soixante-cinq mille.
static func serialize(painting: Painting, heights: PackedStringArray,
		mode_id: StringName) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s %d" % [MAGIC, VERSION])
	lines.append("mode %s" % mode_id)
	lines.append("resolution %d" % painting.resolution)

	var by_cell: Dictionary = slots(heights)
	var keys: Array[String] = []
	var image_of: Dictionary = {}
	for cell: Vector2i in painting.painted_cells():
		if not by_cell.has(cell):
			continue
		var key: String = String(by_cell[cell])
		keys.append(key)
		image_of[key] = painting.image_of(cell)
	keys.sort()

	for key: String in keys:
		var image: Image = image_of[key]
		if image == null:
			continue
		lines.append("%s %s" % [key, Marshalls.raw_to_base64(image.save_png_to_buffer())])

	return "\n".join(lines) + "\n"


static func write(path: String, painting: Painting, heights: PackedStringArray,
		mode_id: StringName) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("work_io: ecriture impossible de '%s' (erreur %d)." % [path, open_error])
		return open_error
	file.store_string(serialize(painting, heights, mode_id))
	file.close()
	return OK


## Relit un travail et le repose sur [param heights].
##
## Cles rendues :
##   painting   : Painting            deja a la resolution du fichier
##   mode       : StringName          le mode dans lequel il a ete peint
##   resolution : int
##   placed     : int                 tuiles reposees
##   unplaced   : Array[String]       tuiles que le guide actuel n'accueille pas
##   error      : Error
static func parse(text: String, heights: PackedStringArray) -> Dictionary:
	var result: Dictionary = {
		"painting": Painting.new(),
		"mode": &"",
		"resolution": Painting.DEFAULT_RESOLUTION,
		"placed": 0,
		"unplaced": PackedStringArray(),
		"error": OK,
	}

	var lines: PackedStringArray = text.split("\n")
	if lines.is_empty() or not lines[0].begins_with(MAGIC + " "):
		push_error("work_io: ce fichier n'est pas un travail AbsoluTiles.")
		result["error"] = ERR_FILE_UNRECOGNIZED
		return result
	var written_with: int = lines[0].get_slice(" ", 1).to_int()
	if written_with > VERSION:
		push_error("work_io: fichier ecrit par une version plus recente.")
		result["error"] = ERR_FILE_UNRECOGNIZED
		return result

	var by_key: Dictionary = cells_by_key(heights)
	var painting: Painting = null
	var unplaced: PackedStringArray = PackedStringArray()
	var placed: int = 0

	for number: int in range(1, lines.size()):
		var line: String = lines[number].strip_edges()
		if line.is_empty():
			continue
		var head: String = line.get_slice(" ", 0)
		var tail: String = line.substr(head.length() + 1)
		if head == "mode":
			result["mode"] = StringName(tail.strip_edges())
			continue
		if head == "resolution":
			result["resolution"] = tail.strip_edges().to_int()
			continue
		if painting == null:
			painting = Painting.new(int(result["resolution"]))
			result["painting"] = painting

		var image: Image = _decode(tail, number + 1)
		if image == null:
			result["error"] = ERR_FILE_CORRUPT
			continue
		if image.get_width() != painting.resolution or image.get_height() != painting.resolution:
			push_error("work_io: ligne %d, tuile '%s' en %dx%d alors que le fichier annonce %d."
					% [number + 1, head, image.get_width(), image.get_height(),
					painting.resolution])
			result["error"] = ERR_FILE_CORRUPT
			continue
		# ⚠ LES ROBES D'UN FICHIER v1 SONT RENDUES, JAMAIS REPOSEES. Leur numero de pan ne
		# veut plus la meme chose ; les placer serait un mensonge silencieux.
		if written_with < 2 and head.begins_with("W"):
			unplaced.append(head)
			continue
		if not by_key.has(head):
			unplaced.append(head)
			continue
		painting.set_image(by_key[head], image)
		placed += 1

	if painting == null:
		result["painting"] = Painting.new(int(result["resolution"]))
	result["placed"] = placed
	result["unplaced"] = unplaced
	return result


## L'en-tete seul : de quel paysage et de quelle taille est ce fichier.
##
## ⚠ IL FAUT LE SAVOIR AVANT DE CHARGER LE GUIDE. On ne peut pas reposer un travail sans
## le relief sur lequel le reposer, et le relief depend du mode, qui est ecrit dans le
## fichier. D'ou cette lecture en deux temps -- et elle ne decode pas une seule image :
## on s'arrete a la premiere ligne de tuile, qui pese plusieurs kilo-octets a elle seule.
static func peek(path: String) -> Dictionary:
	var result: Dictionary = {
		"mode": &"",
		"resolution": Painting.DEFAULT_RESOLUTION,
		"error": OK,
	}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["error"] = FileAccess.get_open_error()
		return result
	if not file.get_line().begins_with(MAGIC + " "):
		file.close()
		result["error"] = ERR_FILE_UNRECOGNIZED
		return result
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("mode "):
			result["mode"] = StringName(line.substr(5).strip_edges())
		elif line.begins_with("resolution "):
			result["resolution"] = line.substr(11).strip_edges().to_int()
		else:
			break
	file.close()
	return result


static func read(path: String, heights: PackedStringArray) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("work_io: lecture impossible de '%s' (erreur %d)." % [path, open_error])
		var failed: Dictionary = parse("%s %d\n" % [MAGIC, VERSION], heights)
		failed["error"] = open_error
		return failed
	var text: String = file.get_as_text()
	file.close()
	return parse(text, heights)


static func _decode(payload: String, line_number: int) -> Image:
	var bytes: PackedByteArray = Marshalls.base64_to_raw(payload.strip_edges())
	if bytes.is_empty():
		push_error("work_io: ligne %d illisible." % line_number)
		return null
	var image: Image = Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		push_error("work_io: ligne %d, image illisible." % line_number)
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image
