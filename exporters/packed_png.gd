# LA PLANCHE PACKED — une seule image, pour la vendre.
#
# L'export moteur livre DEUX planches et un manifeste : c'est un CONTRAT, fait pour qu'un
# lecteur pose un monde sans se tromper. Un acheteur de place de marche n'a pas ce
# lecteur-la : il ouvre le PNG dans son editeur, decoupe, et pose a la main. Ce qu'il attend
# est une feuille unique, serree, avec une legende lisible a cote.
#
# ⚠ ET CE N'EST PAS UN AUTRE TILESET, C'EST LE MEME RANGE AUTREMENT. Aucun pixel n'est
# recalcule, aucune tuile n'est fabriquee : on relit exactement ce que l'export moteur
# ecrirait, et on le pose sur une grille d'une seule piece. Si les deux sortaient des images
# differentes, l'une des deux mentirait.
#
# ⚠ ET IL REFUSE UNE FEUILLE INCOMPLETE, PAR LE MEME CHEMIN (charte, regle 5). Il ne
# reimplemente pas le refus : il demande son rapport a `TilesetPNG.analyse` et s'arrete
# dessus. Un tileset a moitie peint vendu a quelqu'un est pire qu'un tileset a moitie peint
# garde chez soi.
#
# ⚠ ET LA GRILLE EST LA PLUS CARREE POSSIBLE, ce qui n'est pas une coquetterie : une feuille
# longue et fine gaspille la memoire de texture d'un moteur, qui arrondit a la puissance de
# deux superieure dans les deux sens. Deux ou trois cases vides a la fin ne coutent rien --
# voir `columns_for`, ou la premiere version cherchait l'inverse et rendait une bande d'une
# seule colonne.
extends RefCounted

const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")
const Massifs := preload("res://core/massifs.gd")

const SUFFIX_SHEET: String = "_packed.png"
const SUFFIX_LEGEND: String = "_packed.txt"


## LE NOMBRE DE COLONNES : le plus CARRE, et a egalite celui qui laisse le moins de vide.
## Pour 47 tuiles c'est 7 (49 cases, 2 vides) ; pour 20 c'est 4 (20 cases, aucune).
##
## ⚠ ET C'EST LA CARRURE QUI PASSE D'ABORD, PAS LE VIDE -- premiere version ecrite a l'envers,
## et la mesure l'a dit tout de suite : « minimiser le vide » rend 1 x 47 pour 47 tuiles, une
## bande d'une seule colonne, parce qu'un nombre PREMIER n'a pas d'autre grille sans reste.
## Deux cases vides ne coutent rien ; une feuille de 47 tuiles de haut est inutilisable.
##
## ⚠ ET ON NE CHERCHE PAS « LA PUISSANCE DE DEUX » : la taille de la case varie (16, 32, 64,
## 128, 256), donc c'est le PIXEL final qui devrait etre puissance de deux, pas le nombre de
## tuiles. Viser la puissance de deux en tuiles ferait des feuilles a moitie vides sans rien
## garantir en pixels.
static func columns_for(count: int) -> int:
	if count <= 0:
		return 1
	var best: int = 1
	var best_ratio: float = 1e9
	var best_waste: int = count * count
	for columns: int in range(1, count + 1):
		var rows: int = (count + columns - 1) / columns
		var waste: int = columns * rows - count
		var ratio: float = maxf(float(columns) / float(rows), float(rows) / float(columns))
		if ratio < best_ratio - 0.0001 or (absf(ratio - best_ratio) <= 0.0001
				and waste < best_waste):
			best = columns
			best_ratio = ratio
			best_waste = waste
	return best


## L'ORDRE DES TUILES, ET IL EST LE MEME QUE CELUI DES DEUX PLANCHES : les surfaces d'abord,
## dans l'ordre de la famille, puis les robes, pan par pan et rangee par rangee. Poser la
## feuille packed a cote de la feuille moteur fait donc se correspondre les cases une a une.
##
## Chaque entree dit ce qu'elle est, pour la legende : `["S", index]` ou `["W", role]`.
static func order(family: StringName = Families.BY_CELL) -> Array:
	var out: Array = []
	# ⚠ LE MODELE DES MASSIFS N A QU UN VOCABULAIRE, DONC QU UNE SUITE. Surfaces et jupes y
	# sont le meme objet vu a deux hauteurs : les separer en deux blocs redirait une coupure
	# que le modele a justement supprimee.
	if family == Families.BY_MASSIF:
		var tiles: Array[int] = Families.massif_tiles()
		tiles.sort()
		for tile: int in tiles:
			out.append(["M", tile])
		return out
	for index: int in Families.surface_indices(family):
		out.append(["S", index])
	for role: Vector2i in Families.wall_roles():
		out.append(["W", role])
	return out


## Compose la feuille unique. Rend null si rien n'est a poser.
static func compose(painting: Painting, heights: PackedStringArray,
		report: Dictionary) -> Image:
	var family: StringName = report.get("family", Families.BY_CELL)
	var side: int = painting.resolution
	var slots: Array = order(family)
	if slots.is_empty() or side <= 0:
		return null
	var columns: int = columns_for(slots.size())
	var rows: int = (slots.size() + columns - 1) / columns
	var sheet: Image = Image.create_empty(columns * side, rows * side, false,
			Image.FORMAT_RGBA8)
	sheet.fill(Painting.TRANSPARENT)

	var by_key: Dictionary = WorkIO.cells_by_key(heights, family)
	if family == Families.BY_MASSIF:
		var source: Dictionary = report["source"]
		for spot: int in range(slots.size()):
			var tile: int = int((slots[spot] as Array)[1])
			if not source.has(tile):
				continue
			var image_key: String = "M%d:%d" % [tile, int(source[tile])]
			if not by_key.has(image_key):
				continue
			var drawn: Image = painting.image_of(by_key[image_key])
			if drawn == null:
				continue
			sheet.blit_rect(drawn, Rect2i(0, 0, side, side),
					Vector2i(spot % columns, spot / columns) * side)
		return sheet
	var surfaces: Dictionary = report["surface_source"]
	var walls: Dictionary = report["wall_source"]
	for at: int in range(slots.size()):
		var slot: Array = slots[at]
		var wall: bool = String(slot[0]) == "W"
		var tile: Variant = slot[1]
		var table: Dictionary = walls if wall else surfaces
		if not table.has(tile):
			continue
		var letter: String = "W" if wall else Families.key_letter(family)
		var key: String = TilesetPNG._key_for(letter, tile, int(table[tile]))
		if not by_key.has(key):
			continue
		var image: Image = painting.image_of(by_key[key])
		if image == null:
			continue
		sheet.blit_rect(image, Rect2i(0, 0, side, side),
				Vector2i(at % columns, at / columns) * side)
	return sheet


## LA LEGENDE : ce que porte chaque case, en clair.
##
## ⚠ UNE FEUILLE SANS LEGENDE N'EST PAS VENDABLE. L'acheteur doit pouvoir dire « la case
## 3,2 est la tuile dont le nord et l'est sont pleins » sans ouvrir notre logiciel -- sinon
## il decoupe quarante-sept images et il en fait ce qu'il peut.
##
## ⚠ ET CE N'EST PAS UN MANIFESTE : elle ne porte AUCUNE regle de pose. Le contrat vit dans
## `<nom>_tileset.txt`, et c'est lui que les moteurs lisent. Melanger les deux ferait croire
## qu'on peut poser un monde avec la feuille packed, ce qui est faux.
static func legend(painting: Painting, mode_id: StringName, basename: String,
		report: Dictionary) -> String:
	var family: StringName = report.get("family", Families.BY_CELL)
	var slots: Array = order(family)
	var columns: int = columns_for(slots.size())
	var rows: int = (slots.size() + columns - 1) / columns
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# %s -- feuille packed" % basename)
	lines.append("#")
	lines.append("# Une seule image, %d colonnes x %d rangees, %d pixels par case." % [
			columns, rows, painting.resolution])
	lines.append("# Les tuiles dans l'ordre du vocabulaire, en lecture -- gauche a droite,")
	lines.append("# haut en bas. Les cases de la fin peuvent etre vides.")
	lines.append("#")
	lines.append("# ⚠ CETTE FEUILLE NE PORTE AUCUNE REGLE DE POSE. Pour poser un monde,")
	lines.append("#   c'est `%s_tileset.txt` qu'il faut lire, avec ses deux planches." % basename)
	lines.append("")
	lines.append("mode %s" % mode_id)
	lines.append("famille %s" % family)
	lines.append("image %s" % (basename + SUFFIX_SHEET))
	lines.append("tuile %d" % painting.resolution)
	lines.append("grille %d %d" % [columns, rows])
	lines.append("cases %d" % slots.size())
	lines.append("")
	for at: int in range(slots.size()):
		var slot: Array = slots[at]
		var where: String = "%d,%d" % [at % columns, at / columns]
		if String(slot[0]) == "M":
			lines.append("case %s tuile %d  # %s" % [where, int(slot[1]),
					Massifs.describe(int(slot[1]))])
		elif String(slot[0]) == "W":
			var role: Vector2i = slot[1] as Vector2i
			lines.append("case %s robe pan %d rangee %d" % [where, role.x, role.y])
		else:
			lines.append("case %s surface %d  # %s" % [where, int(slot[1]),
					Families.describe(family, int(slot[1]))])
	return "\n".join(lines) + "\n"


## Ecrit la feuille et sa legende. Meme rapport, meme refus que l'export moteur.
static func write(folder: String, basename: String, painting: Painting,
		heights: PackedStringArray, mode_id: StringName,
		family: StringName = Families.BY_CELL) -> Dictionary:
	# ⚠ LE REFUS NE SE REIMPLEMENTE PAS : on demande son rapport a l exportateur moteur du
	# modele, et on s arrete dessus. Deux refus separes finiraient par se contredire, et la
	# feuille vendue sortirait la ou la feuille moteur refuse.
	var report: Dictionary = MassifTileset.analyse(painting, heights) \
			if family == Families.BY_MASSIF \
			else TilesetPNG.analyse(painting, heights, family)
	report["written"] = PackedStringArray()
	report["error"] = OK
	if not report["is_exportable"]:
		report["error"] = ERR_UNAVAILABLE
		return report
	if DirAccess.make_dir_recursive_absolute(folder) != OK \
			and not DirAccess.dir_exists_absolute(folder):
		push_error("packed_png: dossier '%s' introuvable et impossible a creer." % folder)
		report["error"] = ERR_CANT_CREATE
		return report

	var sheet: Image = compose(painting, heights, report)
	if sheet == null:
		report["error"] = ERR_CANT_CREATE
		return report
	var written: PackedStringArray = PackedStringArray()
	var sheet_path: String = folder.path_join(basename + SUFFIX_SHEET)
	var saved: Error = sheet.save_png(sheet_path)
	if saved != OK:
		push_error("packed_png: ecriture impossible de '%s' (erreur %d)." % [sheet_path, saved])
		report["error"] = saved
		return report
	written.append(sheet_path)

	var legend_path: String = folder.path_join(basename + SUFFIX_LEGEND)
	var file: FileAccess = FileAccess.open(legend_path, FileAccess.WRITE)
	if file == null:
		push_error("packed_png: ecriture impossible de '%s'." % legend_path)
		report["error"] = ERR_CANT_CREATE
		return report
	file.store_string(legend(painting, mode_id, basename, report))
	file.close()
	written.append(legend_path)

	report["written"] = written
	return report
