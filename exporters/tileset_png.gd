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
const Families := preload("res://core/families.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Assembly := preload("res://render/assembly.gd")

const MAGIC: String = "absolutiles-tileset"
## ⚠ VERSION 2 : LE MANIFESTE EST DEVENU UN CONTRAT. Il ne decrit plus seulement OU sont
## les tuiles, il porte la REGLE DE POSE. Une seconde moitie du projet posera le monde dans
## Godot et dans Unity : c'est nous qui ecrirons le lecteur, deux fois, et deux lecteurs qui
## se fient a leur memoire finissent toujours par diverger. La regle vit ici, une seule fois.
const VERSION: int = 2

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
static func analyse(painting: Painting, heights: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var surface_ranks: Dictionary = {}
	var wall_ranks: Dictionary = {}

	var by_cell: Dictionary = WorkIO.slots(heights, family)
	for cell: Vector2i in painting.painted_cells():
		if not by_cell.has(cell):
			continue
		var slot: Dictionary = WorkIO.describe(String(by_cell[cell]))
		var rank: int = int(slot["rank"])
		if slot["family"] == "S" or slot["family"] == "C":
			_note(surface_ranks, int(slot["index"]), rank)
		elif slot["family"] == "W":
			_note(wall_ranks, slot["role"], rank)

	# ⚠ LE DEDOUBLONNAGE PASSE AVANT LE COMPTE. Sans lui, `variants` vaudrait le nombre
	# d'occurrences du guide -- une centaine pour les index courants -- et la planche
	# ferait cent blocs pour un seul dessin.
	var by_key: Dictionary = WorkIO.cells_by_key(heights, family)
	var letter: String = Families.key_letter(family)
	_dedupe(surface_ranks, letter, painting, by_key)
	_dedupe(wall_ranks, "W", painting, by_key)

	var missing_surface: Array[int] = []
	for index: int in Families.surface_indices(family):
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
		"family": family,
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
static func _key_for(letter: String, tile: Variant, rank: int) -> String:
	if letter == "W":
		var role: Vector2i = tile
		return "W%d,%d:%d" % [role.x, role.y, rank]
	return "%s%d:%d" % [letter, int(tile), rank]


static func _note(into: Dictionary, key: Variant, rank: int) -> void:
	if not into.has(key):
		var fresh: Array[int] = []
		into[key] = fresh
	var ranks: Array[int] = into[key]
	if not ranks.has(rank):
		ranks.append(rank)
		ranks.sort()


## La case de la planche de surface ou tombe l'index [param index], variante [param slot].
static func surface_slot(index: int, slot: int,
		family: StringName = Families.BY_CELL) -> Vector2i:
	var order: int = Families.surface_indices(family).find(index)
	if order < 0:
		return Vector2i(-1, -1)
	return Vector2i(order % SURFACE_COLUMNS,
			order / SURFACE_COLUMNS + slot * surface_rows(family))


## La hauteur d'un bloc de la planche de surface, en tuiles.
static func surface_rows(family: StringName = Families.BY_CELL) -> int:
	var count: int = Families.surface_indices(family).size()
	return (count + SURFACE_COLUMNS - 1) / SURFACE_COLUMNS


## La case de la planche de robes. Le pan donne la colonne, la rangee donne la rangee :
## la planche EST le bloc 3 x 4 du vocabulaire, sans traduction.
static func wall_slot(role: Vector2i, slot: int) -> Vector2i:
	return Vector2i(role.x, role.y + slot * Walls.BLOCK_ROWS)


## Compose une planche. Rend null si rien n'est a poser.
static func compose(painting: Painting, heights: PackedStringArray, report: Dictionary,
		walls: bool) -> Image:
	var family: StringName = report.get("family", Families.BY_CELL)
	var side: int = painting.resolution
	var variants: int = int(report["variants"])
	var columns: int = Walls.PAN_COUNT if walls else SURFACE_COLUMNS
	var rows: int = (Walls.BLOCK_ROWS if walls else surface_rows(family)) * variants
	if columns <= 0 or rows <= 0:
		return null

	var sheet: Image = Image.create_empty(columns * side, rows * side, false, Image.FORMAT_RGBA8)
	sheet.fill(Painting.TRANSPARENT)

	var by_key: Dictionary = WorkIO.cells_by_key(heights, family)
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

	_spec(lines)

	lines.append("")
	lines.append("surface %s %d %d" % [basename + SUFFIX_SURFACE, SURFACE_COLUMNS, surface_rows()])
	lines.append("# les %d index du blob, en ordre croissant, huit par rangee ; la derniere"
			% BlobIndex.CANONICAL_INDICES.size())
	lines.append("# case de la planche reste vide, 47 n'etant pas un multiple de 8.")
	var indices: Array[int] = []
	for index: int in report["surface_variants"].keys():
		indices.append(index)
	indices.sort()
	for index: int in indices:
		var slot: Vector2i = surface_slot(index, 0)
		lines.append("index %d slot %d,%d variants %d  # %s" % [index, slot.x, slot.y,
				report["surface_variants"][index].size(), BlobIndex.describe(index)])

	lines.append("")
	lines.append("proof %s" % [basename + SUFFIX_PROOF])
	lines.append("# chaque index sur son propre ilot, dans l'ordre de la planche de surface :")
	lines.append("# la preuve qu'il n'en manque aucun, peinte avec ces tuiles-ci.")

	lines.append("")
	lines.append("walls %s %d %d" % [basename + SUFFIX_WALLS, Walls.PAN_COUNT, Walls.BLOCK_ROWS])
	lines.append("# %d pans (le couple des deux flancs) x %d rangees = %d tuiles."
			% [Walls.PAN_COUNT, Walls.BLOCK_ROWS, Walls.ALL_ROLES.size()])
	for role: Vector2i in Walls.ALL_ROLES:
		if not report["wall_variants"].has(role):
			continue
		var at: Vector2i = wall_slot(role, 0)
		lines.append("role %d,%d slot %d,%d variants %d  # %s" % [role.x, role.y, at.x, at.y,
				report["wall_variants"][role].size(), Walls.role_name(role)])

	return "\n".join(lines) + "\n"


## LA REGLE DE POSE, ecrite noir sur blanc.
##
## ⚠ NECESSAIRE ET SUFFISANT. Ce qui suit doit permettre a quelqu'un qui n'a QUE ce fichier
## et les planches de poser un monde correct. Si une regle manque ici, elle vivra dans la
## tete de celui qui a ecrit le moteur -- et le jour ou il en ecrira un second, les deux
## divergeront sans que rien ne le dise.
static func _spec(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("# ======================= LA REGLE DE POSE =======================")
	lines.append("# Ce fichier n'est pas une notice, c'est le contrat. Tout ce qui suit est")
	lines.append("# necessaire et suffisant pour placer chaque tuile.")
	lines.append("")
	lines.append("# --- LE RELIEF ---")
	lines.append("# Une carte est une hauteur par case : 0 la plaine, 1..9 les plateaux. La")
	lines.append("# silhouette de l'etage N est l'ensemble des cases de hauteur >= N, et c'est")
	lines.append("# un masque BINAIRE : tout ce qui suit s'applique etage par etage. On dessine")
	lines.append("# du bas vers le haut, chaque couche recouvrant la precedente.")
	lines.append("levels silhouette_per_level")
	lines.append("draw_order bottom_up")
	lines.append("")
	lines.append("# --- LA SURFACE : le blob 47 ---")
	lines.append("# Voisinage 8 bits, sens horaire depuis le nord.")
	lines.append("bits N=%d NE=%d E=%d SE=%d S=%d SW=%d W=%d NW=%d" % [
			BlobIndex.N, BlobIndex.NE, BlobIndex.E, BlobIndex.SE,
			BlobIndex.S, BlobIndex.SW, BlobIndex.W, BlobIndex.NW])
	lines.append("# ⚠ UN BIT DE COIN N'EST CONSERVE QUE SI LES DEUX CARDINAUX QUI L'ENCADRENT")
	lines.append("# SONT PLEINS. Un coin diagonal isole ne change pas la silhouette de la tuile :")
	lines.append("# il ne doit donc pas produire une tuile de plus. Les 256 voisinages bruts se")
	lines.append("# reduisent ainsi a exactement %d index." % BlobIndex.CANONICAL_INDICES.size())
	lines.append("canonicalise corner_needs_both_cardinals")
	lines.append("# La tuile d'une case est celle de SON etage, jamais de l'union des etages.")
	lines.append("visible own_level")
	lines.append("")
	lines.append("# --- LES FALAISES ---")
	lines.append("# ⚠ UN PLATEAU N'A DE FACE QU'AU SUD. Les trois autres cotes ne montrent rien :")
	lines.append("# on voit son dessus, puis le sol d'en dessous, sans transition.")
	lines.append("faces south_only")
	lines.append("storey_tiles %d" % Walls.STOREY_TILES)
	lines.append("body_rows %d" % Walls.BODY_ROWS)
	lines.append("block_rows %d" % Walls.BLOCK_ROWS)
	lines.append("# LA CHUTE. Sous une levre de l'etage N -- une case de l'etage N dont la case")
	lines.append("# au sud est plus basse -- on cherche l'etage le plus haut M reellement")
	lines.append("# atteint, et la chute vaut storey_tiles * (N - M).")
	lines.append("# ⚠ ON SONDE LA CASE JUSTE SOUS LE PIED, jamais celles que la robe traverse :")
	lines.append("# les etages partagent la grille, et l'etage N-1 continue SOUS la robe de")
	lines.append("# l'etage N. Sonder au fil de la descente repondrait « touche » des la premiere")
	lines.append("# case, et toutes les falaises feraient une case de haut.")
	lines.append("fall storey_tiles_times_gap probe_below_foot")
	lines.append("# RACCOURCISSEMENT. Si la robe rencontre le sol de SON PROPRE etage, elle")
	lines.append("# s'arrete la et ne pose PAS son pied : elle ne touche pas le sol d'en bas,")
	lines.append("# elle bute contre un voisin de son niveau.")
	lines.append("trim stop_on_same_level no_foot")
	lines.append("# LA RANGEE, au pas `step` (1 = premiere case sous la levre) d'une chute de")
	lines.append("# `drop` cases :")
	lines.append("#     step == 1               -> %d  chapiteau" % Walls.ROW_CROWN)
	lines.append("#     step == drop et posee   -> %d  pied" % Walls.ROW_FOOT)
	lines.append("#     sinon                   -> 1 + (step - 2) modulo body_rows")
	lines.append("row_for crown_first foot_last body_cycle")
	lines.append("# LE PAN. C'est le couple des deux flancs : pan = ouest * %d + est."
			% Walls.SIDE_COUNT)
	lines.append("#     %d VIDE    aucune roche a ce flanc" % Walls.SIDE_VOID)
	lines.append("#     %d MUET    la meme face continue, OU le voisin est DEVANT moi"
			% Walls.SIDE_MUTE)
	lines.append("#     %d DEVANT  le voisin est en retrait : je porte l'angle"
			% Walls.SIDE_FRONT)
	lines.append("# ⚠ « EN RETRAIT » SE MESURE A LA LEVRE : la levre du voisin est plus au NORD")
	lines.append("# que la mienne. Deux faces mitoyennes issues de levres decalees ne sont PAS la")
	lines.append("# meme face, et l'arete appartient a celle qui AVANCE -- c'est ce qui rend")
	lines.append("# lisible laquelle des deux est la plus proche.")
	lines.append("# ⚠ ET LE PAN SE CHOISIT PAR RANGEE, JAMAIS PAR COLONNE : sous le pied d'une")
	lines.append("# voisine plus courte, un flanc redevient vide.")
	lines.append("pan west_times_three_plus_east lip_row_comparison per_row")
	lines.append("# ================================================================")


## Ecrit les deux planches et leur manifeste dans [param folder].
##
## Rend le rapport d'`analyse()`, augmente de :
##   error   : Error   OK, ou ERR_UNAVAILABLE si la feuille est incomplete
##   written : PackedStringArray  les chemins ecrits
static func write(folder: String, basename: String, painting: Painting,
		heights: PackedStringArray, mode_id: StringName,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var report: Dictionary = analyse(painting, heights, family)
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
