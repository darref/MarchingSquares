# Lecture, ecriture et acces d'un masque de guide au format texte.
# Un masque est une PackedStringArray de lignes de meme longueur, composees
# uniquement de FILLED_CHAR et EMPTY_CHAR. Le hors-grille est vide.
# Logique pure : aucune dependance UI.
extends RefCounted

const FILLED_CHAR: String = "#"
const EMPTY_CHAR: String = "."


## Analyse un texte de masque.
## '#' = plein, '.' = vide, lignes vides ignorees.
## Les lignes plus courtes sont completees a droite avec des cases vides, ce qui
## revient au meme que le hors-grille : le masque reste rectangulaire.
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
			var character: String = line[column]
			if character == FILLED_CHAR:
				row += FILLED_CHAR
				continue
			if character != EMPTY_CHAR:
				push_error("mask_io: caractere inattendu '%s' ligne %d colonne %d, lu comme vide." % [character, line_number, column + 1])
			row += EMPTY_CHAR
		rows.append(row)
		widest = maxi(widest, row.length())
	for index: int in range(rows.size()):
		var missing_columns: int = widest - rows[index].length()
		if missing_columns > 0:
			rows[index] = rows[index] + EMPTY_CHAR.repeat(missing_columns)
	return rows


## Lit un masque depuis un fichier. Retourne un masque vide en cas d'echec.
static func read(path: String) -> PackedStringArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("mask_io: lecture impossible de '%s' (erreur %d)." % [path, FileAccess.get_open_error()])
		return PackedStringArray()
	var text: String = file.get_as_text()
	file.close()
	return parse(text)


## Rend le masque sous forme de texte, une ligne par rangee, saut de ligne final.
static func serialize(mask: PackedStringArray) -> String:
	if mask.is_empty():
		return ""
	return "\n".join(mask) + "\n"


## Ecrit un masque modifie sur disque. Retourne OK ou le code d'erreur.
static func write(path: String, mask: PackedStringArray) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("mask_io: ecriture impossible de '%s' (erreur %d)." % [path, open_error])
		return open_error
	file.store_string(serialize(mask))
	file.close()
	return OK


static func width(mask: PackedStringArray) -> int:
	if mask.is_empty():
		return 0
	return mask[0].length()


static func height(mask: PackedStringArray) -> int:
	return mask.size()


## Etat d'une case. Toute coordonnee hors-grille est vide.
static func is_filled(mask: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= mask.size():
		return false
	var row: String = mask[y]
	if x < 0 or x >= row.length():
		return false
	return row[x] == FILLED_CHAR


## Retourne une copie du masque dont la case (x, y) est mise a l'etat demande.
## Hors-grille : le masque est retourne inchange, on n'agrandit pas la grille.
static func with_cell(mask: PackedStringArray, x: int, y: int, filled: bool) -> PackedStringArray:
	var updated: PackedStringArray = mask.duplicate()
	if y < 0 or y >= updated.size():
		return updated
	var row: String = updated[y]
	if x < 0 or x >= row.length():
		return updated
	updated[y] = row.substr(0, x) + (FILLED_CHAR if filled else EMPTY_CHAR) + row.substr(x + 1)
	return updated
