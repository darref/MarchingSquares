# L'EXPORT — la feuille de tuiles, et rien d'autre que ce qui a ete peint.
#
# Deux familles, deux planches. Un terrain Wang resout les coins d'un plan ; une falaise
# sort du plan. Les melanger dans une seule image obligerait celui qui la relit a savoir ou
# l'une s'arrete et ou l'autre commence -- c'est exactement ce que Satyron fait en gardant
# `icko_tileset.tres` d'un cote et `cliff_kits.tres` de l'autre.
#
# ⚠ L'EXPORT REFUSE UNE FEUILLE INCOMPLETE (charte, regle 5). Il ne reste pas des trous
# transparents en esperant que personne ne s'en serve : il rend la liste de ce qui manque
# et n'ecrit rien. Un tileset a moitie peint n'est pas un tileset, c'est un piege.
#
# ⚠ UNE VARIANTE EST UN DESSIN DIFFERENT, PAS UNE CASE DIFFERENTE. « Peindre les
# jumelles » est coche d'emblee : les cent cases qui portent le meme index portent alors le
# MEME dessin. Les exporter toutes gonflerait la planche de cent blocs identiques, pour une
# feuille cent fois plus lourde qui ne montre rien de plus. On compare donc le CONTENU, et
# l'on ne garde que ce qui differe vraiment.
#
# ⚠ ET ELLES SONT TASSEES, PAS RECOPIEES A LEUR RANG D'ORIGINE. Si l'utilisateur a peint
# la troisieme occurrence d'un index sans peindre la premiere, sa tuile devient la variante
# 0 de la planche. Sinon un moteur qui tire une variante au hasard tomberait sur une case
# vide -- et le rang dans le guide n'a aucun sens pour qui relit la feuille.
#
# LA DISPOSITION EST MECANIQUE, ET LE MANIFESTE LA REDIT QUAND MEME. Les 47 index rangent
# en ordre croissant, huit par rangee ; les 12 robes tombent naturellement en 3 pans x 4
# rangees, la forme meme du vocabulaire. Un lecteur pourrait recalculer chaque case a partir
# de la regle, mais le manifeste donne la table en clair : le fichier dit ce qui est vrai,
# il n'oblige pas a le redemontrer.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Assembly := preload("res://render/assembly.gd")

const MAGIC: String = "absolutiles-tileset"
const VERSION: int = 1

## Largeur de la planche de surface, en tuiles. 47 n'a pas de forme naturelle -- huit
## colonnes donnent six rangees, et la derniere case reste vide. Elle est dite au manifeste.
const SURFACE_COLUMNS: int = 8

const SUFFIX_SURFACE: String = "_surface.png"
const SUFFIX_WALLS: String = "_walls.png"
const SUFFIX_MANIFEST: String = "_tileset.txt"

## ⚠ CE QUI PROUVE A L'ACHETEUR QU'IL N'EN MANQUE AUCUNE. Une feuille de 47 dessins ne
## montre pas qu'elle est complete : on y voit 47 tuiles, pas l'absence d'une 48e. La
## planche de preuve pose chaque index sur son propre ilot, dans l'ordre de la feuille,
## et peinte avec les tuiles achetees. On peut pointer du doigt.
const SUFFIX_PROOF: String = "_preuve.png"


## Ce que l'export donnerait, et s'il peut avoir lieu.
##
## C'est aussi ce que le bouton d'export interroge pour savoir s'il a le droit de s'ouvrir :
## la barre d'outils et le fichier repondent a la meme fonction, donc ils ne peuvent pas se
## contredire (charte, regle 4).
##
## Cles rendues :
##   surface_variants : Dictionary[int, Array[int]]      index -> rangs peints, tasses
##   wall_variants    : Dictionary[Vector2i, Array[int]] role  -> rangs peints, tasses
##   missing_surface  : Array[int]
##   missing_wall     : Array[Vector2i]
##   variants         : int   nombre de blocs de la planche
##   tile_size        : int
##   is_exportable    : bool
static func analyse(painting: Painting, heights: PackedStringArray) -> Dictionary:
	var surface_ranks: Dictionary = {}
	var wall_ranks: Dictionary = {}

	var by_cell: Dictionary = WorkIO.slots(heights)
	for cell: Vector2i in painting.painted_cells():
		if not by_cell.has(cell):
			continue
		var slot: Dictionary = WorkIO.describe(String(by_cell[cell]))
		var rank: int = int(slot["rank"])
		if slot["family"] == "S":
			_note(surface_ranks, int(slot["index"]), rank)
		elif slot["family"] == "W":
			_note(wall_ranks, slot["role"], rank)

	# ⚠ LE DEDOUBLONNAGE PASSE AVANT LE COMPTE. Sans lui, `variants` vaudrait le nombre
	# d'occurrences du guide -- une centaine pour les index courants -- et la planche
	# ferait cent blocs pour un seul dessin.
	var by_key: Dictionary = WorkIO.cells_by_key(heights)
	_dedupe(surface_ranks, "S", painting, by_key)
	_dedupe(wall_ranks, "W", painting, by_key)

	var missing_surface: Array[int] = []
	for index: int in BlobIndex.CANONICAL_INDICES:
		if not surface_ranks.has(index):
			missing_surface.append(index)
	missing_surface.sort()

	var missing_wall: Array[Vector2i] = []
	for role: Vector2i in Walls.ALL_ROLES:
		if not wall_ranks.has(role):
			missing_wall.append(role)

	var variants: int = 1
	for ranks: Array in surface_ranks.values():
		variants = maxi(variants, ranks.size())
	for ranks: Array in wall_ranks.values():
		variants = maxi(variants, ranks.size())

	return {
		"surface_variants": surface_ranks,
		"wall_variants": wall_ranks,
		"missing_surface": missing_surface,
		"missing_wall": missing_wall,
		"variants": variants,
		"tile_size": painting.resolution,
		"is_exportable": missing_surface.is_empty() and missing_wall.is_empty(),
	}


## Ne garde, parmi les occurrences peintes d'une tuile, que les dessins REELLEMENT
## differents. La comparaison est exacte -- octet pour octet -- et non par empreinte : une
## empreinte qui se cognerait ferait disparaitre une variante en silence, et l'utilisateur
## perdrait un dessin sans que rien ne le dise.
static func _dedupe(ranks_by_tile: Dictionary, family: String, painting: Painting,
		by_key: Dictionary) -> void:
	for tile: Variant in ranks_by_tile.keys():
		var kept: Array[int] = []
		var seen: Array[PackedByteArray] = []
		for rank: int in ranks_by_tile[tile]:
			if not by_key.has(_key_for(family, tile, rank)):
				continue
			var image: Image = painting.image_of(by_key[_key_for(family, tile, rank)])
			if image == null:
				continue
			var data: PackedByteArray = image.get_data()
			var already: bool = false
			for other: PackedByteArray in seen:
				if other == data:
					already = true
					break
			if already:
				continue
			seen.append(data)
			kept.append(rank)
		ranks_by_tile[tile] = kept


## La cle de sauvegarde d'une tuile. Le format appartient a `work_io` ; on le compose ici
## par la meme regle, une seule fois, plutot que de le reecrire a chaque usage.
static func _key_for(family: String, tile: Variant, rank: int) -> String:
	if family == "W":
		var role: Vector2i = tile
		return "W%d,%d:%d" % [role.x, role.y, rank]
	return "S%d:%d" % [int(tile), rank]


static func _note(into: Dictionary, key: Variant, rank: int) -> void:
	if not into.has(key):
		var fresh: Array[int] = []
		into[key] = fresh
	var ranks: Array[int] = into[key]
	if not ranks.has(rank):
		ranks.append(rank)
		ranks.sort()


## La case de la planche de surface ou tombe l'index [param index], variante [param slot].
static func surface_slot(index: int, slot: int) -> Vector2i:
	var order: int = BlobIndex.CANONICAL_INDICES.find(index)
	if order < 0:
		return Vector2i(-1, -1)
	return Vector2i(order % SURFACE_COLUMNS,
			order / SURFACE_COLUMNS + slot * surface_rows())


## La hauteur d'un bloc de la planche de surface, en tuiles.
static func surface_rows() -> int:
	var count: int = BlobIndex.CANONICAL_INDICES.size()
	return (count + SURFACE_COLUMNS - 1) / SURFACE_COLUMNS


## La case de la planche de robes. Le pan donne la colonne, la rangee donne la rangee :
## la planche EST le bloc 3 x 4 du vocabulaire, sans traduction.
static func wall_slot(role: Vector2i, slot: int) -> Vector2i:
	return Vector2i(role.x, role.y + slot * Walls.BLOCK_ROWS)


## Compose une planche. Rend null si rien n'est a poser.
static func compose(painting: Painting, heights: PackedStringArray, report: Dictionary,
		walls: bool) -> Image:
	var side: int = painting.resolution
	var variants: int = int(report["variants"])
	var columns: int = Walls.PAN_COUNT if walls else SURFACE_COLUMNS
	var rows: int = (Walls.BLOCK_ROWS if walls else surface_rows()) * variants
	if columns <= 0 or rows <= 0:
		return null

	var sheet: Image = Image.create_empty(columns * side, rows * side, false, Image.FORMAT_RGBA8)
	sheet.fill(Painting.TRANSPARENT)

	var by_key: Dictionary = WorkIO.cells_by_key(heights)
	var table: Dictionary = report["wall_variants"] if walls else report["surface_variants"]
	for tile: Variant in table.keys():
		var ranks: Array[int] = table[tile]
		for slot: int in range(ranks.size()):
			var key: String = _key_for("W" if walls else "S", tile, ranks[slot])
			var at: Vector2i = wall_slot(tile, slot) if walls 					else surface_slot(int(tile), slot)
			if at.x < 0 or not by_key.has(key):
				continue
			var image: Image = painting.image_of(by_key[key])
			if image == null:
				continue
			sheet.blit_rect(image, Rect2i(0, 0, side, side), at * side)
	return sheet


## Le manifeste : ce que contiennent les deux planches, en clair.
static func manifest(report: Dictionary, mode_id: StringName, basename: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s %d" % [MAGIC, VERSION])
	lines.append("mode %s" % mode_id)
	lines.append("tile_size %d" % int(report["tile_size"]))
	lines.append("variants %d" % int(report["variants"]))
	lines.append("")
	lines.append("surface %s %d %d" % [basename + SUFFIX_SURFACE, SURFACE_COLUMNS, surface_rows()])
	lines.append("# les 47 index du blob, en ordre croissant, huit par rangee ;")
	lines.append("# la derniere case de la planche reste vide, 47 n'etant pas un multiple de 8.")
	var indices: Array[int] = []
	for index: int in report["surface_variants"].keys():
		indices.append(index)
	indices.sort()
	for index: int in indices:
		var slot: Vector2i = surface_slot(index, 0)
		lines.append("index %d slot %d,%d variants %d"
				% [index, slot.x, slot.y, report["surface_variants"][index].size()])

	lines.append("")
	lines.append("")
	lines.append("proof %s" % [basename + SUFFIX_PROOF])
	lines.append("# chaque index sur son propre ilot, dans l'ordre de la planche de surface :")
	lines.append("# la preuve qu'il n'en manque aucun, peinte avec ces tuiles-ci.")
	lines.append("")
	lines.append("walls %s %d %d" % [basename + SUFFIX_WALLS, Walls.PAN_COUNT, Walls.BLOCK_ROWS])
	lines.append("# 3 pans (gauche, courant, droit) x 4 rangees (chapiteau, corps 0, corps 1, pied).")
	lines.append("storey_tiles %d" % Walls.STOREY_TILES)
	lines.append("body_rows %d" % Walls.BODY_ROWS)
	for role: Vector2i in Walls.ALL_ROLES:
		if not report["wall_variants"].has(role):
			continue
		var at: Vector2i = wall_slot(role, 0)
		lines.append("role %d,%d slot %d,%d variants %d"
				% [role.x, role.y, at.x, at.y, report["wall_variants"][role].size()])

	return "\n".join(lines) + "\n"


## Ecrit les deux planches et leur manifeste dans [param folder].
##
## Rend le rapport d'`analyse()`, augmente de :
##   error   : Error   OK, ou ERR_UNAVAILABLE si la feuille est incomplete
##   written : PackedStringArray  les chemins ecrits
static func write(folder: String, basename: String, painting: Painting,
		heights: PackedStringArray, mode_id: StringName) -> Dictionary:
	var report: Dictionary = analyse(painting, heights)
	report["written"] = PackedStringArray()
	report["error"] = OK

	# ⚠ UN REFUS N'EST PAS UNE ERREUR. Une feuille incomplete est l'etat NORMAL tant que
	# l'utilisateur peint : le bouton est grise, le compte s'affiche, et c'est tout. Le
	# signaler par `push_error` remplirait la console de rouge pendant tout le travail, et
	# apprendrait a ignorer le rouge. Le rapport dit ce qui manque, il suffit de le lire.
	if not report["is_exportable"]:
		report["error"] = ERR_UNAVAILABLE
		return report

	if DirAccess.make_dir_recursive_absolute(folder) != OK and not DirAccess.dir_exists_absolute(folder):
		push_error("tileset_png: dossier '%s' introuvable et impossible a creer." % folder)
		report["error"] = ERR_CANT_CREATE
		return report

	var written: PackedStringArray = PackedStringArray()
	for walls: bool in [false, true]:
		var sheet: Image = compose(painting, heights, report, walls)
		if sheet == null:
			report["error"] = ERR_CANT_CREATE
			return report
		var path: String = folder.path_join(basename + (SUFFIX_WALLS if walls else SUFFIX_SURFACE))
		var saved: Error = sheet.save_png(path)
		if saved != OK:
			push_error("tileset_png: ecriture impossible de '%s' (erreur %d)." % [path, saved])
			report["error"] = saved
			return report
		written.append(path)

	var proof: Image = Assembly.from_borrowed(ProofScene.relief(), heights, painting)
	var proof_path: String = folder.path_join(basename + SUFFIX_PROOF)
	var proof_saved: Error = proof.save_png(proof_path)
	if proof_saved != OK:
		push_error("tileset_png: ecriture impossible de '%s' (erreur %d)." % [proof_path, proof_saved])
		report["error"] = proof_saved
		return report
	written.append(proof_path)

	var manifest_path: String = folder.path_join(basename + SUFFIX_MANIFEST)
	var file: FileAccess = FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("tileset_png: ecriture impossible de '%s' (erreur %d)."
				% [manifest_path, open_error])
		report["error"] = open_error
		return report
	file.store_string(manifest(report, mode_id, basename))
	file.close()
	written.append(manifest_path)

	report["written"] = written
	return report
