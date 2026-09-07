# L'EXPORT DU MODELE DES MASSIFS : une planche, un manifeste.
#
# ⚠ UNE SEULE PLANCHE, ET C'EST LE MODELE QUI LE DIT. L'ancien exportateur en livrait deux --
# les surfaces d'un cote, les robes de l'autre -- parce qu'une falaise « sortait du plan » et
# relevait d'un second vocabulaire. Ici un massif se dessine ENTIER : sa surface et sa jupe sont
# le meme objet vu a deux hauteurs, une tuile est le couple (silhouette, bande), et les separer
# obligerait celui qui relit la feuille a savoir ou l'une s'arrete.
#
# ⚠ ET UNE FEUILLE INCOMPLETE EST REFUSEE, RIEN N'EST ECRIT (charte, regle 5). Un tileset a
# moitie peint n'est pas un tileset, c'est un piege : des trous transparents qu'on decouvrirait
# dans le jeu. Mais un refus n'est pas une erreur -- incomplet est l'etat NORMAL pendant tout le
# travail, donc on ne remplit pas la console de rouge.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const Families := preload("res://core/families.gd")
const Massifs := preload("res://core/massifs.gd")
const Signing := preload("res://core/signing.gd")

const MAGIC: String = "solutiles-tileset"

## ⚠ VERSION 10 : LE CISAILLEMENT ENTRE DANS L'IDENTITE DE LA TUILE. Une case d'herbe contre la
## falaise de son PROPRE massif ne rend plus la tuile d'interieur : elle a la sienne, et la roche
## d'en face aussi. Un lecteur v9 poserait la mauvaise tuile a ces endroits, sans une erreur.
##
## ⚠ VERSION 9 : LE MODELE DES MASSIFS. Le sens de la regle de pose change entierement -- un
## massif entier au lieu d'une surface plus une robe, deux bandes de plus, un seul bit de
## contexte au lieu de sept, une seule planche. Un lecteur v8 qui poserait un fichier v9
## fabriquerait un monde faux SANS UNE SEULE ERREUR, et c'est le pire des defauts. La v8 sera
## donc refusee nommement par le lecteur, comme la v7 l'etait par elle.
## ⚠ VERSION 11 : LE CISAILLEMENT PAR LE NORD ENTRE DANS L'IDENTITE DE LA TUILE. Une case
## d'herbe qui a la falaise de son PROPRE massif au-dessus d'elle -- le coude -- ne rend plus la
## tuile d'interieur : elle a la sienne, et elle trace son bord. Un lecteur v10 poserait
## l'interieur a ces endroits, donc un trait qui s'arrete net, SANS UNE SEULE ERREUR.
## ⚠ VERSION 12 : LE PIED NE SE POSE PLUS QUE SUR UN VRAI FOND. Une face qui rencontre le toit
## d un autre massif ne se termine pas la -- elle disparait derriere lui -- donc elle reste du
## CORPS. Un lecteur v11 poserait un pied a ces endroits, c est-a-dire le trait du bas d une
## falaise au milieu d une paroi qui continue, SANS UNE SEULE ERREUR.
const VERSION: int = 12

const COLUMNS: int = 8
const SUFFIX_SHEET: String = "_massifs.png"
const SUFFIX_MANIFEST: String = "_tileset.txt"


## LA PLACE D'UNE TUILE SUR LA PLANCHE : son rang dans le vocabulaire trie, huit par rangee.
##
## ⚠ ELLE SE CALCULE DU VOCABULAIRE, ELLE NE S'ECRIT PAS. Une table ecrite a la main serait une
## donnee a maintenir et un endroit ou mentir -- meme raison que les index calcules. Le
## manifeste la redit quand meme en clair : il dit ce qui est vrai, il n'oblige pas a le
## redemontrer.
static func slot_of(tile: int) -> Vector2i:
	var order: Array[int] = Families.massif_tiles()
	order.sort()
	var rank: int = order.find(tile)
	return Vector2i(-1, -1) if rank < 0 else Vector2i(rank % COLUMNS, rank / COLUMNS)


static func rows() -> int:
	return (Families.massif_tiles().size() + COLUMNS - 1) / COLUMNS


## CE QUI EST LIVRABLE, ET CE QUI MANQUE.
##
## ⚠ C'EST LA PREMIERE OCCURRENCE PEINTE QUI SORT, QUEL QUE SOIT SON RANG -- et on garde le PLUS
## PETIT rang plutot que le premier rencontre : un dictionnaire ne promet aucun ordre, et un
## export qui changerait d'une fois sur l'autre serait indefendable.
##
## ⚠ ET UNE TUILE N'EST LIVREE QUE SI ELLE PORTE VRAIMENT UN DESSIN, pas du seul fait qu'une cle
## existe. Un compte qui ne mesure pas ce qu'il pretend mesurer est pire que pas de compte.
static func analyse(painting: Painting, heights: PackedStringArray) -> Dictionary:
	var family: StringName = Families.BY_MASSIF
	var by_key: Dictionary = WorkIO.cells_by_key(heights, family)
	var by_cell: Dictionary = WorkIO.slots(heights, family)
	var source: Dictionary = {}
	for cell: Vector2i in painting.painted_cells():
		if not by_cell.has(cell):
			continue
		var slot: Dictionary = WorkIO.describe(String(by_cell[cell]))
		if String(slot["family"]) != "M":
			continue
		var tile: int = int(slot["index"])
		var rank: int = int(slot["rank"])
		var key: String = "M%d:%d" % [tile, rank]
		if not by_key.has(key) or painting.image_of(by_key[key]) == null:
			continue
		if source.has(tile) and int(source[tile]) <= rank:
			continue
		source[tile] = rank

	var wanted: Array[int] = Families.massif_tiles()
	var missing: Array[int] = []
	for tile2: int in wanted:
		if not source.has(tile2):
			missing.append(tile2)
	return {
		"family": family,
		"tile_size": painting.resolution,
		"source": source,
		"wanted": wanted,
		"missing": missing,
		"delivered": source.keys().size(),
		"is_exportable": missing.is_empty(),
	}


## LA PLANCHE : une case par tuile, a la place que le manifeste annonce.
static func compose(painting: Painting, heights: PackedStringArray,
		report: Dictionary) -> Image:
	var side: int = int(report["tile_size"])
	var tall: int = rows()
	if tall <= 0:
		return null
	var sheet: Image = Image.create_empty(COLUMNS * side, tall * side, false,
			Image.FORMAT_RGBA8)
	sheet.fill(Painting.TRANSPARENT)
	var by_key: Dictionary = WorkIO.cells_by_key(heights, Families.BY_MASSIF)
	var source: Dictionary = report["source"]
	for tile: Variant in source.keys():
		var at: Vector2i = slot_of(int(tile))
		var key: String = "M%d:%d" % [int(tile), int(source[tile])]
		if at.x < 0 or not by_key.has(key):
			continue
		var image: Image = painting.image_of(by_key[key])
		if image == null:
			continue
		sheet.blit_rect(image, Rect2i(0, 0, side, side), at * side)
	return sheet


## LE MANIFESTE : ce que la planche contient, ET LA REGLE DE POSE.
##
## ⚠ NECESSAIRE ET SUFFISANT. Quelqu'un qui n'a QUE ce fichier et la planche doit pouvoir poser
## un monde correct. Si une regle manque, elle vivra dans la tete de celui qui a ecrit le
## premier moteur -- et le second divergera sans que rien ne le dise. C'est nous qui ecrirons le
## lecteur, deux fois : la regle vit donc dans le fichier, une seule fois.
static func manifest(report: Dictionary, mode_id: StringName, basename: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s %d" % [MAGIC, VERSION])
	lines.append("mode %s" % mode_id)
	lines.append("famille massif")
	lines.append("tile_size %d" % int(report["tile_size"]))
	# ⚠ DEUX CONSTANTES LISIBLES PAR PROGRAMME, ET C'EST UN GARDE-FOU, PAS UNE REDITE. La regle
	# de pose est en prose plus bas -- necessaire pour REIMPLEMENTER -- mais un moteur doit
	# pouvoir REFUSER sans lire de la prose. `fall_rows` dit la hauteur d'un etage : un tileset
	# dont l'etage descend de quatre rangees, pose par un moteur qui en compte trois, donnerait
	# un monde faux SANS UNE SEULE ERREUR. `tiles` dit combien de tuiles le vocabulaire compte :
	# une planche a qui il en manque une laisserait un trou dans le monde de l'acheteur.
	lines.append("fall_rows %d" % Massifs.FALL)
	lines.append("tiles %d" % Families.massif_tiles().size())
	lines.append("")
	# ⚠ LA REGLE DE POSE N'EST PLUS ECRITE ICI (decision utilisateur du 04/09/2026), et ce
	# n'est PAS un affaiblissement de la justesse. Ce qui garantit que deux moteurs s'accordent,
	# c'est le CONTROLE CROISE -- 4 096 reliefs binaires, 19 683 ternaires, le guide livre et des
	# reliefs tires au sort, compares dans les deux sens a chaque execution. La prose, elle,
	# n'etait que de la documentation : utile a qui veut REIMPLEMENTER, c'est-a-dire au cloneur.
	#
	# ⚠ ET CE QUI RESTE SUFFIT A REFUSER. `fall_rows` et `tiles` sont les deux constantes que le
	# lecteur compare aux siennes : sans elles il ne pourrait plus distinguer un tileset qui
	# n'est pas le sien, et c'est le pire des defauts -- celui qui ne se signale pas. Un
	# garde-fou qui ne regarde que d'un cote ne garde rien.
	lines.append("# The placement rule is not in this file. It lives in the SoluPaint engine,")
	lines.append("# which carries it in full, and is licensed to anyone who wants to write")
	lines.append("# their own. This manifest says WHERE the tiles are, not how to place them.")
	lines.append("")
	lines.append("sheet %s %d %d" % [basename + SUFFIX_SHEET, COLUMNS, rows()])
	lines.append("# one single sheet: surfaces AND cliff faces, same vocabulary. Tiles are")
	lines.append("# ordered by increasing key, eight per row; the cells left over at the end")
	lines.append("# of the sheet are empty.")
	var order: Array[int] = []
	for tile: Variant in report["source"].keys():
		order.append(int(tile))
	order.sort()
	for tile2: int in order:
		var at: Vector2i = slot_of(tile2)
		lines.append("tile %d slot %d,%d  # %s" % [tile2, at.x, at.y,
				Massifs.describe(tile2)])
	return "\n".join(lines) + "\n"


## LA REGLE DE POSE, EN CLAIR -- pour le mode d'emploi et pour la licence, PLUS pour le fichier.
##
## ⚠ ELLE NE PART PLUS DANS LE MANIFESTE, et elle reste ici pour deux raisons. Le niveau 3 du
## mode d'emploi la LIT A LA SOURCE : le recopier dans l'interface donnerait deux textes a tenir
## d'accord, et le jour ou la regle bouge il y en a un qui ment. Et c'est elle qu'on fournit sous
## licence a qui veut ecrire son propre moteur -- une fois, sous contrat, plutot que dans chaque
## export livre a tout le monde.
static func placement_rules() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	spec(lines)
	return lines


static func spec(lines: PackedStringArray) -> void:
	lines.append("# ---- THE PLACEMENT RULE ----")
	lines.append("#")
	lines.append("# THE RELIEF. One height per cell: `~` the void, `0..9` the levels. Off-")
	lines.append("# map is VOID, never plain -- an engine reading absence as plain would")
	lines.append("# stretch the ground to infinity and would place no world-edge cliff at")
	lines.append("# all.")
	lines.append("void -1 out_of_map_is_void")
	lines.append("plain level_like_any_other")
	lines.append("#")
	lines.append("# THE MASSIF. For each level L from ZERO up, a connected component of the")
	lines.append("# cells of level AT LEAST L -- not exactly L. Massifs are therefore")
	lines.append("# NESTED: a level-3 cell belongs to massifs 3, 2, 1 and 0.")
	lines.append("# Grouped at the exact level, a carrier would become a RING, holed where")
	lines.append("# the massif above sits, and you would see ground through its middle.")
	lines.append("massif connected_component level_at_least from_zero")
	lines.append("#")
	lines.append("# THE FOOTPRINT. The massif's surface, PLUS the cliff hanging under each")
	lines.append("# south edge. The silhouette is read on the FOOTPRINT, never on the")
	lines.append("# surface alone: a cliff cell has cliff neighbours, and reading it in the")
	lines.append("# surface would call it isolated.")
	lines.append("footprint surface_plus_south_skirt")
	lines.append("silhouette read_on_footprint eight_bits blob_canonical")
	lines.append("#")
	lines.append("# THE FALL. One level is THREE rows. The face looks for the first step j")
	lines.append("# such that the ground, 3j rows below, is exactly j levels under the lip;")
	lines.append("# it is therefore NOT a flat rate. Finding none, it falls into the void")
	lines.append("# and PLACES NO FOOT -- you do not touch the bottom of a chasm. And the")
	lines.append("# probe looks UNDER THE FOOT, never at the rows it crosses: a terrace on")
	lines.append("# the way does not stop the fall.")
	lines.append("fall three_rows_per_storey probe_under_foot no_foot_into_void")
	lines.append("#")
	lines.append("# THE BANDS. The surface, then the cap at the first step, the body next,")
	lines.append("# the foot on landing. A tile IS the pair (silhouette, band) -- plus the")
	lines.append("# one bit of context that remains.")
	lines.append("bands surface crown body foot")
	lines.append("#")
	lines.append("# THE ONE BIT OF CONTEXT: DO I OVERLAP ANOTHER MASSIF?")
	lines.append("# If so, my outline is FLUSH everywhere -- its edge meets the tile border")
	lines.append("# at the meeting point, so that any neighbour can join it. If not, my")
	lines.append("# edges are FREE. The PLAIN does not count as something overlapped:")
	lines.append("# without that clause every massif would overlap something, so everything")
	lines.append("# would be flush, and the freedom would vanish.")
	lines.append("flush covers_another_massif plain_does_not_count")
	lines.append("#")
	lines.append("# DRAW ORDER. By ROW first, by LEVEL next; the last placement wins. An")
	lines.append("# overlap is ONLY occlusion by draw order: the massif above hides the")
	lines.append("# cliff below, it does not modify it. A tile's neighbourhood therefore")
	lines.append("# never depends on what is placed over it.")
	lines.append("draw_order by_row_then_level last_wins")
	lines.append("#")
	lines.append("# ⚠ AND THERE IS NO BACKING AND NO UNDERFOOT. Since the massif above is")
	lines.append("# flush everywhere, the one below never emerges IN THE MIDDLE of a tile:")
	lines.append("# it always emerges at a border. No composite tile exists, therefore, and")
	lines.append("# the massif below is drawn WHOLE.")
	lines.append("no_backing no_underfoot massif_drawn_whole")
	lines.append("#")
	lines.append("# THICKNESS. No run of cells of the same state -- full or empty -- is")
	lines.append("# shorter than THREE, in every level's silhouette. This is not a rule in")
	lines.append("# itself: it is the consequence of a brush that stamps 3x3.")
	lines.append("thin_forbidden run_shorter_than_three all_storeys both_states")
	lines.append("#")
	lines.append("sheet_rule fixed_size one_drawing_per_tile no_variants")


## L'ECRITURE : la planche et le manifeste, ou rien.
static func write(painting: Painting, heights: PackedStringArray, mode_id: StringName,
		folder: String, basename: String) -> Dictionary:
	var report: Dictionary = analyse(painting, heights)
	if not bool(report["is_exportable"]):
		return {"written": PackedStringArray(), "report": report,
				"error": "%d tile(s) missing" % (report["missing"] as Array).size()}
	var sheet: Image = compose(painting, heights, report)
	if sheet == null:
		return {"written": PackedStringArray(), "report": report, "error": "empty sheet"}
	# ⚠ LE DOSSIER SE CREE, IL NE SE SUPPOSE PAS. L'installateur ecrit dans `solutiles/` d'un
	# projet qui ne l'a jamais eu ; sans ca l'export echoue sur un chemin qui n'existe pas, et
	# le message parle d'ecriture impossible au lieu de dossier absent.
	if DirAccess.make_dir_recursive_absolute(folder) != OK 			and not DirAccess.dir_exists_absolute(folder):
		return {"written": PackedStringArray(), "report": report,
				"error": "cannot create folder"}
	var made: PackedStringArray = PackedStringArray()
	var sheet_path: String = folder.path_join(basename + SUFFIX_SHEET)
	if sheet.save_png(sheet_path) != OK:
		return {"written": made, "report": report, "error": "ecriture impossible"}
	made.append(sheet_path)
	# LE SCEAU PORTE LES PIXELS, PAS SEULEMENT LE TEXTE.
	#
	# ⚠ SIGNER LE SEUL MANIFESTE LAISSERAIT ECHANGER LA PLANCHE SOUS LUI : quelqu'un revendrait
	# notre planche d'essai sous son nom avec un manifeste refait, et le sceau tiendrait. On
	# scelle donc les octets de l'IMAGE, la table des cases et la version -- re-decouper,
	# re-empaqueter ou echanger l'image casse le sceau.
	#
	# ⚠ ET ON RELIT L'IMAGE DEPUIS LE DISQUE, pas depuis la memoire : c'est le fichier livre
	# qu'on scelle, pas ce qu'on croit avoir ecrit.
	var written_sheet: PackedByteArray = FileAccess.get_file_as_bytes(sheet_path)
	var seal: String = Signing.seal(written_sheet,
			Signing.table_of(report["source"]), VERSION)
	var text_path: String = folder.path_join(basename + SUFFIX_MANIFEST)
	var file: FileAccess = FileAccess.open(text_path, FileAccess.WRITE)
	if file == null:
		return {"written": made, "report": report, "error": "manifeste impossible"}
	var text: String = manifest(report, mode_id, basename)
	if not seal.is_empty():
		text += "seal %s\n" % seal
	file.store_string(text)
	file.close()
	made.append(text_path)
	return {"written": made, "report": report, "error": ""}
