# Un guide en relief : une hauteur par case.
#
# '~' = le VIDE, le hors-monde. '.' ou '0' = la plaine, niveau 0. '1'..'9' = les plateaux.
# Le hors-grille est du vide.
#
# ⚠ LE VIDE N'EST PAS LA PLAINE, ET C'EST LA PIECE QUI MANQUAIT AU MOTEUR. Tant que le
# modele ne savait pas les distinguer, il ne pouvait pas dire OU LE SOL S'ARRETE : le plugin
# ne posait donc aucun etage 0, et le sol du jeu restait a la charge de l'acheteur. La
# plaine est un plateau comme les autres -- elle a sa silhouette, ses 47 index, et ses
# falaises la ou elle borde le vide. Le vide, lui, n'est rien : ni tuile, ni levre.
#
# ⚠ ET `level_at` REND -1 SUR LE VIDE, PAS 0. Tout le code qui teste `>= N` avec N >= 1 est
# donc inchange -- le vide y echoue exactement comme la plaine. Seul ce qui teste `>= 0`
# voit la difference, et c'est precisement l'etage 0.
#
# ⚠ LA SILHOUETTE D'UN ETAGE EST UN MASQUE BINAIRE. Les cases de hauteur >= N forment la
# silhouette de l'etage N, et cette silhouette est exactement ce que blob_index et coverage
# savent deja lire. Un plateau plus haut repose donc sur tous ceux d'en dessous, sans qu'on
# ait rien a declarer : l'etage N-1 continue sous la robe de l'etage N, il est juste masque.
# C'est ce qui permet d'appliquer le blob 47 etage par etage, sans une ligne de plus.
#
# Logique pure : aucune dependance UI.
extends RefCounted

const MaskIO := preload("res://core/mask_io.gd")

const PLAIN_CHAR: String = "."
const MAX_LEVEL: int = 9

## Le hors-monde. Ni un etage, ni une tuile : rien.
const VOID: int = -1
const VOID_CHAR: String = "~"

## Accepte par tolerance dans un guide a deux niveaux : '#' vaut le premier plateau.
const LEGACY_FILLED_CHAR: String = "#"


## Analyse un texte de guide en relief. Lignes vides ignorees, lignes courtes completees
## au VIDE -- une ligne qui s'arrete dit que le monde s'arrete, pas qu'il continue en plat.
static func parse(text: String) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	var widest: int = 0
	var line_number: int = 0
	for raw_line: String in text.split("\n"):
		line_number += 1
		var line: String = raw_line.strip_edges()
		if line.is_empty():
			continue
		var row: String = ""
		for column: int in range(line.length()):
			row += _level_char(line[column], line_number, column + 1)
		rows.append(row)
		widest = maxi(widest, row.length())
	for index: int in range(rows.size()):
		var missing_columns: int = widest - rows[index].length()
		if missing_columns > 0:
			rows[index] = rows[index] + VOID_CHAR.repeat(missing_columns)
	return rows


static func _level_char(character: String, line_number: int, column: int) -> String:
	if character == VOID_CHAR:
		return VOID_CHAR
	if character == PLAIN_CHAR or character == "0":
		return PLAIN_CHAR
	if character == LEGACY_FILLED_CHAR:
		return "1"
	if character >= "1" and character <= "9":
		return character
	push_error("height_mask: caractere inattendu '%s' ligne %d colonne %d, lu comme plaine." % [character, line_number, column])
	return PLAIN_CHAR


static func read(path: String) -> PackedStringArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("height_mask: lecture impossible de '%s' (erreur %d)." % [path, FileAccess.get_open_error()])
		return PackedStringArray()
	var text: String = file.get_as_text()
	file.close()
	return parse(text)


static func serialize(heights: PackedStringArray) -> String:
	if heights.is_empty():
		return ""
	return "\n".join(heights) + "\n"


static func write(path: String, heights: PackedStringArray) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("height_mask: ecriture impossible de '%s' (erreur %d)." % [path, open_error])
		return open_error
	file.store_string(serialize(heights))
	file.close()
	return OK


static func width(heights: PackedStringArray) -> int:
	if heights.is_empty():
		return 0
	return heights[0].length()


static func height(heights: PackedStringArray) -> int:
	return heights.size()


## Hauteur d'une case. Le hors-grille est a la plaine.
static func level_at(heights: PackedStringArray, x: int, y: int) -> int:
	if y < 0 or y >= heights.size():
		return VOID
	var row: String = heights[y]
	if x < 0 or x >= row.length():
		return VOID
	var character: String = row[x]
	if character == VOID_CHAR:
		return VOID
	if character == PLAIN_CHAR:
		return 0
	return character.to_int()


## L'etage le plus haut du guide.
static func top_level(heights: PackedStringArray) -> int:
	var top: int = 0
	for y: int in range(heights.size()):
		for x: int in range(heights[y].length()):
			top = maxi(top, level_at(heights, x, y))
	return top


## Silhouette de l'etage demande : masque binaire des cases de hauteur >= level.
## C'est la forme que blob_index et coverage attendent.
static func silhouette(heights: PackedStringArray, level: int) -> PackedStringArray:
	var mask: PackedStringArray = PackedStringArray()
	for y: int in range(heights.size()):
		var row: String = ""
		for x: int in range(heights[y].length()):
			row += MaskIO.FILLED_CHAR if level_at(heights, x, y) >= level else MaskIO.EMPTY_CHAR
		mask.append(row)
	return mask


## Retourne une copie du relief dont la case (x, y) passe au niveau demande.
static func with_level(heights: PackedStringArray, x: int, y: int, level: int) -> PackedStringArray:
	var updated: PackedStringArray = heights.duplicate()
	if y < 0 or y >= updated.size():
		return updated
	var row: String = updated[y]
	if x < 0 or x >= row.length():
		return updated
	var clamped: int = clampi(level, 0, MAX_LEVEL)
	var character: String = PLAIN_CHAR if clamped == 0 else str(clamped)
	updated[y] = row.substr(0, x) + character + row.substr(x + 1)
	return updated
