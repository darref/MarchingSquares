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
# LES CLES. Une tuile se nomme par ce qu'elle est, plus son rang d'occurrence :
#   S<index>:<rang>        surface par case, index blob canonique
#   C<index>:<rang>        surface a cheval, index du croisement
#   W<pan>,<rangee>:<rang> robe
#
# ⚠ `S` ET `C` NE SE MELANGENT JAMAIS DANS UN MEME FICHIER : ce sont deux familles, et un
# travail appartient a l'une ou a l'autre. L'en-tete le dit par une ligne `famille`.
# Le rang est la position de la case dans son groupe, en ordre de lecture. ⚠ CE N'EST
# PAS UN NUMERO DE VARIANTE : c'est un ENDROIT, celui ou cette tuile se voit.
# Rang 0 est donc toujours la premiere occurrence de la tuile dans le guide, celle qui
# existe forcement -- une tuile n'entre au guide qu'au moins une fois.
#
# ⚠ CE QUI NE RETOMBE PAS SUR SES PIEDS EST DIT, PAS JETE. Si le nouveau guide offre moins
# d'exemplaires d'une tuile que le fichier n'en portait, les occurrences en trop sont
# rendues dans `unplaced`. On ne perd pas du travail en silence -- meme regle que les
# pixels peints hors du guide dans `delivery.gd`.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Families := preload("res://core/families.gd")

const EXTENSION: String = "solutiles"

## En-tete du fichier. Le numero monte le jour ou le format change, et il ne changera que
## si les CLES changent -- pas pour un guide retouche, c'est tout l'interet.
const MAGIC: String = "solutiles"
## ⚠ VERSION 2 : LE VOCABULAIRE DES ROBES A CHANGE. Un pan v1 valait 0..2 (gauche, courant,
## droit) ; un pan v2 vaut 0..8 (le couple des deux flancs). Reposer une cle `W` de v1 sous
## v2 la mettrait de travers en silence -- exactement ce que ce fichier existe pour eviter.
## Les cles `S` de surface, elles, n'ont pas bouge et se relisent sans rien perdre.
## ⚠ VERSION 4 : LE VOCABULAIRE DES FLANCS PASSE DE TROIS ETATS A DEUX. La decomposition en
## couches a supprime `devant` -- « qui est devant » se decide par l'ORDRE DE DESSIN, plus par
## la tuile -- donc un pan ne vaut plus 0..8 mais 0..3, et un `W5,2` de v3 ne designe plus
## rien. La traduction se fait PAR LE SENS, pas par le numero : `vide` devient `arret`, et
## `muet` comme `devant` deviennent `continue` -- tous deux voulaient dire « de la roche a ce
## flanc ».
##
## ⚠ ET NEUF PANS NE RENTRENT PAS DANS QUATRE SANS QUE DEUX SE RENCONTRENT. Quand deux tuiles
## de v3 tombent sur la meme de v4, la premiere est posee et les suivantes sont RENDUES dans
## `unplaced` -- jamais ecrasees en silence. C'est la meme regle que partout ici : ce qui ne
## retombe pas sur ses pieds est dit, pas jete.
##
## ⚠ LES SURFACES, ELLES, NE BOUGENT PAS. Le bord n'a jamais ete livre : une cle `S` d'un
## fichier v3 est une silhouette nue, et elle vaut encore.
##
## ⚠ VERSION 3 : LE NUMERO DE RANGEE A CHANGE DE SENS. A deux rangees de corps, le PIED
## portait le numero 3 ; a trois, c'est le corps 2 qui le porte et le pied passe a 4.
## Reposer un fichier v2 tel quel mettrait CHAQUE PIED SUR UN CORPS -- de travers, et en
## silence, ce que ce fichier existe pour empecher.
## ⚠ VERSION 5 : LE MODELE DES MASSIFS. Une tuile n'est plus un index de surface ni un role
## de robe, mais le couple (silhouette, bande) d'un massif dessine entier -- cle `M<tuile>`.
## La lettre suffirait a les distinguer ; la version bouge quand meme, parce qu'une version
## qui ne bouge pas quand le sens bouge ne protege de rien. Les fichiers v4 se relisent.
const VERSION: int = 5

## Ce que valaient les rangees quand un fichier v2 a ete ecrit.
const V2_BODY_ROWS: int = 2
const V2_ROW_FOOT: int = 1 + V2_BODY_ROWS


## La cle de la tuile portee par chaque case du guide.
##
## Cette table est l'annuaire du fichier : elle dit sous quel nom ranger ce qui est peint
## ici, et reciproquement ou reposer ce qu'on relit. Les cases sans tuile -- la plaine --
## n'y figurent pas : elles ne se peignent pas (charte, regle 5).
static func slots(heights: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var by_cell: Dictionary = {}

	# ⚠ LES CLES SONT CELLES DU CARNET, PAS CELLES DE L'ECRAN. Un croisement se range
	# dans les y negatifs (voir `Families.storage_key`) : tout ce qui suit -- serialisation,
	# relecture, export -- travaille donc sans jamais savoir de quelle famille il s'agit.
	#
	# ⚠ UNE CASE SOUS UNE ROBE PORTE LA ROBE, et elle ne prend donc pas de rang de surface.
	# Les rangs se comptaient sur toutes les cases de l'index, robes comprises, puis la cle
	# `W` ecrasait la cle `S` de ces cases-la : le rang `S255:0` pouvait ainsi designer une
	# case qui ne le portait plus, et tout ce qui demandait « la premiere occurrence » -- le
	# decor de l'apercu, l'essai -- ne trouvait rien. Les rangs se comptent sur ce que la
	# case porte vraiment (`Families.surface_map`), et chaque rang existe.
	var letter: String = Families.key_letter(family)
	var groups: Dictionary = Families.groups(family, Families.surface_map(family, heights))
	for index: int in groups.keys():
		var cells: Array[Vector2i] = _sorted(groups[index])
		for rank: int in range(cells.size()):
			by_cell[Families.storage_key(family, cells[rank])] = "%s%d:%d" % [letter, index,
					rank]

	# ⚠ PAS DE SECONDE PASSE DANS LE MODELE DES MASSIFS. La jupe y est deja rangee ci-dessus,
	# sous sa propre tuile : une case porte UNE pose. La passe des robes ECRASERAIT ces cles
	# par des cles `W` -- c'est meme ce qu'elle faisait exprès dans l'ancien modele, ou une
	# case de robe portait a tort l'index du sol d'en dessous.
	var roles: Dictionary = {} if family == Families.BY_MASSIF 			else Walls.cells_by_role(Walls.visible_roles(heights))
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
##   rank   : int      le rang de l'occurrence
static func describe(key: String) -> Dictionary:
	var blank: Dictionary = {"family": "", "index": -1, "role": Vector2i.ZERO, "rank": 0}
	var colon: int = key.rfind(":")
	if colon < 1:
		return blank
	var head: String = key.substr(1, colon - 1)
	var rank: int = key.substr(colon + 1).to_int()
	# ⚠ `M` EST LA CLE DU MODELE DES MASSIFS, ET ELLE SE LIT COMME `S`. Une tuile y est un
	# entier -- le couple (silhouette, bande) plus le bit de contexte -- exactement comme un
	# index de surface. Ne pas la reconnaitre ici rendait `blank` en silence : l'export
	# trouvait ZERO tuile livree sur un carnet entierement peint, sans une seule erreur.
	if key.begins_with("S") or key.begins_with("C") or key.begins_with("M"):
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
	# ⚠ ET LA FAMILLE SE TRANSMET. Elle etait perdue ici : `slots(heights)` repartait sur la
	# famille par defaut, si bien qu'un annuaire demande pour une autre famille rendait les
	# cles d'une troisieme. Le defaut ne se voyait pas tant qu'une seule famille ecrivait.
	var source: Dictionary = corner_slots(heights) if family == Families.BY_CORNER 			else slots(heights, family)
	for at: Vector2i in source.keys():
		by_key[String(source[at])] = at
	return by_key


## L'annuaire dans l'autre sens : ou reposer chaque tuile.
static func cells_by_key(heights: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var by_key: Dictionary = {}
	var by_cell: Dictionary = slots(heights, family)
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
static func serialize(painting: Painting, heights: PackedStringArray, mode_id: StringName,
		family: StringName = Families.BY_CELL) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s %d" % [MAGIC, VERSION])
	lines.append("mode %s" % mode_id)
	lines.append("resolution %d" % painting.resolution)
	lines.append("famille %s" % family)

	var by_cell: Dictionary = slots(heights, family)
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
		mode_id: StringName, family: StringName = Families.BY_CELL) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("work_io: ecriture impossible de '%s' (erreur %d)." % [path, open_error])
		return open_error
	file.store_string(serialize(painting, heights, mode_id, family))
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
		"family": Families.BY_CELL,
		"resolution": Painting.DEFAULT_RESOLUTION,
		"placed": 0,
		"unplaced": PackedStringArray(),
		"error": OK,
	}

	var lines: PackedStringArray = text.split("\n")
	if lines.is_empty() or not lines[0].begins_with(MAGIC + " "):
		push_error("work_io: ce fichier n'est pas un travail SoluTiles.")
		result["error"] = ERR_FILE_UNRECOGNIZED
		return result
	var written_with: int = lines[0].get_slice(" ", 1).to_int()
	if written_with > VERSION:
		push_error("work_io: fichier ecrit par une version plus recente.")
		result["error"] = ERR_FILE_UNRECOGNIZED
		return result

	# ⚠ LA FAMILLE SE LIT AVANT LES TUILES. Elle decide de l'annuaire ou l'on repose ce
	# qu'on relit ; la deviner apres coup mettrait chaque croisement a la place d'une case.
	# ⚠ ET ON S'ARRETE A LA PREMIERE LIGNE DE TUILE : une seule d'entre elles pese plusieurs
	# kilo-octets, et l'en-tete tient dans les premieres.
	for number: int in range(1, lines.size()):
		var head: String = lines[number].strip_edges()
		if head.begins_with("famille "):
			result["family"] = StringName(head.substr(8).strip_edges())
			break
		if not head.is_empty() and not head.begins_with("mode ") 				and not head.begins_with("resolution "):
			break
	var by_key: Dictionary = cells_by_key(heights, result["family"])
	var painting: Painting = null
	var unplaced: PackedStringArray = PackedStringArray()
	var taken: Dictionary = {}
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
		# Deja lue plus haut : elle decide de l'annuaire, elle ne se repose pas.
		if head == "famille":
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
		# veut plus la meme chose, et rien ne permet de deviner lequel : les placer serait
		# un mensonge silencieux.
		if written_with < 2 and head.begins_with("W"):
			unplaced.append(head)
			continue
		# ⚠ CELLES D'UN v2 SE TRADUISENT, PARCE QUE LA TRADUCTION EST EXACTE -- et c'est
		# toute la difference avec le v1. Le passage a trois rangees de corps a decale le
		# PIED de la rangee 3 a la rangee 4 ; le chapiteau et les deux premiers corps n'ont
		# pas bouge d'un cran. On sait donc ou chaque tuile doit aller, et rendre un travail
		# qu'on sait replacer serait le perdre pour rien. La troisieme rangee de corps est
		# simplement neuve -- une tuile de plus a peindre, aucune de moins a garder.
		if written_with < 3 and head.begins_with("W"):
			head = _row_from_v2(head)
		# ⚠ ET LE PAN D'UN v3 SE TRADUIT PAR LE SENS. `vide` devient `arret` ; `muet` et
		# `devant` deviennent tous deux `continue`, puisque tous deux voulaient dire « de la
		# roche a ce flanc ». Neuf pans tombent donc dans quatre, et deux tuiles peuvent se
		# rencontrer : la premiere est posee, les suivantes sont rendues.
		if written_with < 4 and head.begins_with("W"):
			head = _pan_from_v3(head)
		if not by_key.has(head):
			unplaced.append(head)
			continue
		if taken.has(head):
			unplaced.append(head)
			continue
		taken[head] = true
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
		"family": Families.BY_CELL,
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
		elif line.begins_with("famille "):
			result["family"] = StringName(line.substr(8).strip_edges())
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


## La cle d'une robe v2, traduite en v3 : seul le PIED change de numero.
##
## ⚠ ON NE TRADUIT QUE CE QU'ON SAIT TRADUIRE. Un pan v2 vaut deja ce qu'il vaut en v3 --
## neuf pans des la version 2 -- donc seule la rangee bouge. Si la cle ne se lit pas, on la
## rend telle quelle : elle finira dans `unplaced`, dit et non jete.
## La cle d'une robe v3, traduite en v4 : le pan passe de neuf a quatre, par le SENS.
##
## ⚠ ON TRADUIT L'ETAT, PAS LE NUMERO. Un pan v3 vaut `ouest * 3 + est` sur {0 vide, 1 muet,
## 2 devant} ; un pan v4 vaut `ouest * 2 + est` sur {0 arret, 1 continue}. `vide` dit « aucune
## roche a ce flanc », `muet` et `devant` disent tous deux « de la roche a ce flanc » -- l'un
## la meme face, l'autre celle d'un voisin en retrait. La distinction que `devant` portait est
## desormais rendue par l'ordre de dessin, et elle ne vit plus dans la tuile.
static func _pan_from_v3(key: String) -> String:
	var comma: int = key.find(",")
	if comma < 1 or not key.begins_with("W"):
		return key
	var pan: int = int(key.substr(1, comma - 1))
	if pan < 0 or pan >= 9:
		return key
	var west: int = 0 if pan / 3 == 0 else 1
	var east: int = 0 if pan % 3 == 0 else 1
	return "W%d%s" % [west * Walls.SIDE_COUNT + east, key.substr(comma)]


static func _row_from_v2(key: String) -> String:
	var comma: int = key.find(",")
	var colon: int = key.find(":")
	if comma < 0 or colon < 0 or colon < comma:
		return key
	var row: int = int(key.substr(comma + 1, colon - comma - 1))
	if row == V2_ROW_FOOT:
		row = Walls.ROW_FOOT
	return "%s,%d%s" % [key.substr(0, comma), row, key.substr(colon)]


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
