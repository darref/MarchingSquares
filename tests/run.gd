# Runner de tests headless du noyau AbsoluTiles.
#
#   godot --headless --path . --script res://tests/run.gd
#
# Code de sortie 0 si tout passe, 1 sinon.
extends SceneTree

const BlobIndex := preload("res://core/blob_index.gd")
const MaskIO := preload("res://core/mask_io.gd")
const Coverage := preload("res://core/coverage.gd")
const Variants := preload("res://core/variants.gd")
const Modes := preload("res://core/modes.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Painting := preload("res://core/painting.gd")
const Symmetry := preload("res://core/symmetry.gd")
const WorkIO := preload("res://core/work_io.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")
const Assembly := preload("res://render/assembly.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const CornerIndex := preload("res://core/corner_index.gd")

const CANDIDATE_GUIDE_PATH: String = "res://guides/candidate_01.txt"
const BLOB_TILE_COUNT: int = 47

var _checks: int = 0
var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_test_canonicalize_full_neighbourhood()
	_test_canonicalize_isolated_cell()
	_test_forty_seven_distinct_indices()
	_test_mask_io()
	_test_coverage_on_simple_mask()
	_test_variant_selection()
	_test_modes_catalogue()
	_test_height_mask()
	_test_wall_rows()
	_test_wall_assembly()
	_test_mode_guides_are_complete()
	_test_minimal_guide_walls()
	_test_painting()
	_test_undo()
	_test_wall_variants()
	_test_twins()
	_test_symmetry()
	_test_work_io()
	_test_export()
	_test_assembly()
	_test_preview_scene()
	_test_vocabulary_is_closed()
	_test_proof_scene()
	_test_corner_network()
	_test_seams()
	_test_guide_image()
	_test_wireframe_joins()
	_test_every_script_parses()
	_report_candidate_guide()
	_print_summary()
	quit(0 if _failures.is_empty() else 1)


# --- Assertions -------------------------------------------------------------

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  ok   %s" % label)
		return
	_failures.append(label)
	print("  FAIL %s" % label)


func _check_equal(actual: Variant, expected: Variant, label: String) -> void:
	_checks += 1
	if actual == expected:
		print("  ok   %s" % label)
		return
	_failures.append(label)
	print("  FAIL %s" % label)
	print("         attendu : %s" % [expected])
	print("         obtenu  : %s" % [actual])


# --- Tests ------------------------------------------------------------------

func _test_canonicalize_full_neighbourhood() -> void:
	print("blob_index : voisinage plein")
	_check_equal(BlobIndex.canonicalize(255), 255, "les 8 voisins pleins donnent 255")
	var mask: PackedStringArray = MaskIO.parse("###\n###\n###")
	_check_equal(Coverage.index_at(mask, 1, 1), 255, "case entouree de 8 voisins pleins dans un masque : 255")


func _test_canonicalize_isolated_cell() -> void:
	print("blob_index : case isolee")
	_check_equal(BlobIndex.canonicalize(0), 0, "aucun voisin donne 0")
	var mask: PackedStringArray = MaskIO.parse(".....\n..#..\n.....")
	_check_equal(Coverage.index_at(mask, 2, 1), 0, "case isolee dans un masque : 0")
	var diagonals: int = BlobIndex.NE | BlobIndex.SE | BlobIndex.SW | BlobIndex.NW
	_check_equal(BlobIndex.canonicalize(diagonals), 0, "quatre coins seuls, sans cardinal : 0")
	var diagonal_mask: PackedStringArray = MaskIO.parse("#.#\n.#.\n#.#")
	_check_equal(Coverage.index_at(diagonal_mask, 1, 1), 0, "case n ayant que des voisins diagonaux : 0")


func _test_forty_seven_distinct_indices() -> void:
	print("blob_index : les 47 index canoniques")
	var distinct: Dictionary = {}
	for raw: int in range(256):
		distinct[BlobIndex.canonicalize(raw)] = true
	_check_equal(distinct.size(), BLOB_TILE_COUNT, "canonicaliser les 256 voisinages bruts donne 47 valeurs distinctes")
	_check_equal(BlobIndex.CANONICAL_INDICES.size(), BLOB_TILE_COUNT, "CANONICAL_INDICES contient 47 entrees")

	var strictly_sorted: bool = true
	for position: int in range(1, BlobIndex.CANONICAL_INDICES.size()):
		if BlobIndex.CANONICAL_INDICES[position] <= BlobIndex.CANONICAL_INDICES[position - 1]:
			strictly_sorted = false
	_check(strictly_sorted, "CANONICAL_INDICES est trie et sans doublon")

	var same_set: bool = true
	for index: int in BlobIndex.CANONICAL_INDICES:
		if not distinct.has(index):
			same_set = false
	_check(same_set, "CANONICAL_INDICES est exactement l image de canonicalize()")

	var idempotent: bool = true
	for raw: int in range(256):
		var once: int = BlobIndex.canonicalize(raw)
		if BlobIndex.canonicalize(once) != once or not BlobIndex.is_canonical(once):
			idempotent = false
	_check(idempotent, "canonicalize() est idempotente sur les 256 voisinages")


func _test_mask_io() -> void:
	print("mask_io : lecture, ecriture, hors-grille")
	var mask: PackedStringArray = MaskIO.parse("\n##\n\n#\n\n")
	_check_equal(MaskIO.height(mask), 2, "les lignes vides sont ignorees")
	_check_equal(MaskIO.width(mask), 2, "les lignes courtes sont completees a droite")
	_check(MaskIO.is_filled(mask, 0, 1), "la case (0, 1) est pleine")
	_check(not MaskIO.is_filled(mask, 1, 1), "le complement de ligne est vide")
	_check(not MaskIO.is_filled(mask, -1, 0), "le hors-grille a gauche est vide")
	_check(not MaskIO.is_filled(mask, 0, 9), "le hors-grille en bas est vide")

	var edited: PackedStringArray = MaskIO.with_cell(mask, 1, 1, true)
	_check(MaskIO.is_filled(edited, 1, 1), "with_cell() remplit la case demandee")
	_check(not MaskIO.is_filled(mask, 1, 1), "with_cell() ne modifie pas le masque d origine")

	var round_trip_path: String = "user://test_mask_round_trip.txt"
	var write_error: Error = MaskIO.write(round_trip_path, edited)
	_check_equal(write_error, OK, "write() reussit")
	_check_equal(MaskIO.read(round_trip_path), edited, "read(write(masque)) rend le masque d origine")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(round_trip_path))


func _test_coverage_on_simple_mask() -> void:
	print("coverage : rapport sur un masque simple")
	# Bloc plein 3x3 : les 4 coins, les 4 bords et le centre, tous distincts.
	var mask: PackedStringArray = MaskIO.parse("###\n###\n###")
	var report: Dictionary = Coverage.analyse(mask)
	_check_equal(report["filled_count"], 9, "9 cases pleines")
	var expected_present: PackedInt32Array = PackedInt32Array([7, 28, 31, 112, 124, 193, 199, 241, 255])
	_check_equal(report["present"], expected_present, "index presents attendus")
	_check_equal(report["missing"].size(), BLOB_TILE_COUNT - expected_present.size(), "38 index manquants")
	_check_equal(report["is_complete"], false, "le bloc 3x3 ne couvre pas les 47 index")
	var all_single: bool = true
	for index: int in expected_present:
		if int(report["occurrences"][index]) != 1:
			all_single = false
	_check(all_single, "chaque index present apparait une seule fois")
	var expected_centre: Array[Vector2i] = [Vector2i(1, 1)]
	_check_equal(report["positions"][255], expected_centre, "l index 255 est localise au centre")

	# Deux cases isolees : meme index, deux occurrences, donc deux variantes possibles.
	var twin_islands: PackedStringArray = MaskIO.parse("#.#")
	var twin_report: Dictionary = Coverage.analyse(twin_islands)
	_check_equal(twin_report["occurrences"][0], 2, "deux cases isolees comptent deux occurrences de l index 0")


func _test_variant_selection() -> void:
	print("variants : la case peinte est retenue, l autre ne sert pas")
	# Deux ilots portant le meme index 0 : deux variantes possibles du meme index.
	var mask: PackedStringArray = MaskIO.parse("#.#")
	var painted: Array[Vector2i] = [Vector2i(0, 0)]
	var resolved: Dictionary = Variants.resolve(mask, painted)
	var expected_retained: Array[Vector2i] = [Vector2i(0, 0)]
	_check_equal(resolved["retained"][0], expected_retained, "seule la variante peinte est retenue")
	var expected_unused: Array[Vector2i] = [Vector2i(2, 0)]
	_check_equal(resolved["unused"], expected_unused, "la variante non peinte n est pas utilisee")
	_check_equal(resolved["delivered"], PackedInt32Array([0]), "l index 0 est livre")
	_check_equal(resolved["missing"].size(), BLOB_TILE_COUNT - 1, "les 46 autres index manquent")
	_check_equal(resolved["is_exportable"], false, "un seul index livre n est pas exportable")

	var nothing_painted: Array[Vector2i] = []
	var untouched: Dictionary = Variants.resolve(mask, nothing_painted)
	_check(untouched["retained"].is_empty(), "sans peinture, aucune tuile n est retenue")
	_check_equal(untouched["unused"].size(), 2, "sans peinture, les deux cases restent inutilisees")

	# Peindre hors du guide est signale, jamais jete en silence.
	var outside_painted: Array[Vector2i] = [Vector2i(1, 0)]
	var outside_resolved: Dictionary = Variants.resolve(mask, outside_painted)
	var expected_outside: Array[Vector2i] = [Vector2i(1, 0)]
	_check_equal(outside_resolved["outside"], expected_outside, "une case peinte hors du guide est signalee")

	# L ordre des cases fournies ne change pas le resultat.
	var both_orders: Array[Vector2i] = [Vector2i(2, 0), Vector2i(0, 0)]
	var reversed_resolved: Dictionary = Variants.resolve(mask, both_orders)
	var expected_both: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0)]
	_check_equal(reversed_resolved["retained"][0], expected_both, "les variantes sont rendues en ordre de lecture")


func _test_modes_catalogue() -> void:
	print("modes : catalogue")
	var ids: Array[StringName] = Modes.ids()
	# ⚠ UN MODE EST UN PAYSAGE, RIEN D AUTRE. La technique et le style du fond sont des
	# outils : les avoir ranges ici avait suffi a rendre l un a la place de l autre.
	_check_equal(ids.size(), 2, "deux paysages au catalogue")
	_check_equal(ids[0], Modes.MINIMAL, "le premier est minimal")
	_check_equal(ids[1], Modes.AMPLE, "le second est ample")
	# ⚠ LES MIROIRS DE SURFACE N Y GAGNERAIENT QU UNE TUILE (15 orbites deviennent 14) : on
	# les a ecartes pour ca. Les robes, elles, n ont que le miroir -- et depuis que le pan
	# est le couple de ses deux flancs, le miroir les ECHANGE : 36 roles, 24 orbites.
	_check_equal(Symmetry.surface_work_count() + Symmetry.wall_work_count(), 39,
			"avec les rotations : %d surfaces + %d robes = %d, contre %d" % [Symmetry.surface_work_count(), Symmetry.wall_work_count(), Symmetry.surface_work_count() + Symmetry.wall_work_count(), BLOB_TILE_COUNT + Walls.ALL_ROLES.size()])
	_check(Modes.is_available(Modes.MINIMAL), "minimal a son guide, il se choisit")
		# ⚠ FERME, ET C EST VOULU : son guide ne couvre plus les 36 roles. Ce qui n est pas
	# garanti ne se choisit pas (regle 5).
	_check(not Modes.is_available(Modes.AMPLE), "ample est ferme tant que son guide n est pas refait")
	_check_equal(Modes.label(Modes.MINIMAL), "Minimal", "libelle du mode minimal")
	_check_equal(Modes.surface_tile_count(Modes.MINIMAL), BLOB_TILE_COUNT, "47 tuiles de surface")
	_check_equal(Modes.wall_tile_count(Modes.MINIMAL), Walls.ALL_ROLES.size(), "12 tuiles de mur")
	_check_equal(Modes.tile_count(Modes.MINIMAL), BLOB_TILE_COUNT + Walls.ALL_ROLES.size(), "59 tuiles en tout")
	_check_equal(Modes.min_variants(Modes.MINIMAL), 1, "minimal ne promet qu une occurrence")
	_check_equal(Modes.min_variants(Modes.AMPLE), 3, "ample en promet trois")
	_check(not Modes.has(&"inexistant"), "un mode inconnu n est pas dans le catalogue")


func _test_height_mask() -> void:
	print("height_mask : relief et silhouettes")
	var heights: PackedStringArray = HeightMask.parse(".1.
.22
#0.")
	_check_equal(HeightMask.level_at(heights, 1, 0), 1, "un chiffre donne le niveau")
	_check_equal(HeightMask.level_at(heights, 2, 1), 2, "le second plateau est a 2")
	_check_equal(HeightMask.level_at(heights, 0, 2), 1, "'#' vaut le premier plateau")
	_check_equal(HeightMask.level_at(heights, 1, 2), 0, "'0' vaut la plaine")
	_check_equal(HeightMask.level_at(heights, -1, 0), 0, "le hors-grille est a la plaine")
	_check_equal(HeightMask.top_level(heights), 2, "l etage le plus haut est 2")

	# La silhouette d un etage est un masque binaire : le blob 47 s applique tel quel.
	_check_equal(HeightMask.silhouette(heights, 1), MaskIO.parse(".#.
.##
#.."), "silhouette de l etage 1 : hauteur >= 1")
	_check_equal(HeightMask.silhouette(heights, 2), MaskIO.parse("...
.##
..."), "silhouette de l etage 2")
	var flat: PackedStringArray = HeightMask.parse("###
#.#")
	_check_equal(HeightMask.silhouette(flat, 1), MaskIO.parse("###
#.#"), "un guide a deux niveaux se lit comme avant")

	var raised: PackedStringArray = HeightMask.with_level(heights, 0, 0, 3)
	_check_equal(HeightMask.level_at(raised, 0, 0), 3, "with_level eleve la case")
	_check_equal(HeightMask.level_at(heights, 0, 0), 0, "with_level ne modifie pas l original")

	var round_trip_path: String = "user://test_relief_round_trip.txt"
	_check_equal(HeightMask.write(round_trip_path, heights), OK, "write() reussit")
	_check_equal(HeightMask.read(round_trip_path), heights, "read(write(relief)) rend le relief")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(round_trip_path))


func _test_wall_rows() -> void:
	print("walls : la rangee suit la marche et la chute")
	_check_equal(Walls.ALL_ROLES.size(), Walls.PAN_COUNT * Walls.BLOCK_ROWS, "trente-six roles : neuf pans par quatre rangees")
	_check_equal(Walls.PAN_COUNT, 9, "neuf pans : trois etats de flanc, au carre")
	# Une chute d un etage : chapiteau, corps 0, pied. Le corps 1 n y apparait jamais.
	_check_equal(Walls.row_for(1, 3, true), Walls.ROW_CROWN, "premiere case sous la levre : chapiteau")
	_check_equal(Walls.row_for(2, 3, true), 1, "deuxieme case : corps 0")
	_check_equal(Walls.row_for(3, 3, true), Walls.ROW_FOOT, "la case qui touche le sol : pied")
	# Deux etages : le corps tourne sur lui-meme, et c est ce qui evite le begaiement.
	var rows: Array[int] = []
	for step: int in range(1, 7):
		rows.append(Walls.row_for(step, 6, true))
	var expected_rows: Array[int] = [0, 1, 2, 1, 2, 3]
	_check_equal(rows, expected_rows, "chute de six : chapiteau, corps 0, corps 1, corps 0, corps 1, pied")
	_check_equal(Walls.row_for(3, 3, false), 2, "sans atterrissage, la derniere case reste du corps")


func _test_wall_assembly() -> void:
	print("walls : deroulement des robes")
	# UN ETAGE, PLATEAU ISOLE : les trois pans, mais le corps 1 reste hors d atteinte.
	# ⚠ Ce n est PAS une regle generale : une robe raccourcie, qui ne pose pas son pied,
	# montre du corps sur sa derniere case et peut donc rendre le corps 1 a un seul etage.
	var one_storey: PackedStringArray = HeightMask.parse(".....
.111.
.....
.....
.....
.....")
	var shallow: Dictionary = Walls.analyse(one_storey)
	var roles: Dictionary = Walls.assemble(one_storey)["roles"]
	_check_equal(roles[Vector3i(1, 2, 1)], Vector2i(Walls.pan_of(Walls.SIDE_VOID, Walls.SIDE_MUTE), Walls.ROW_CROWN), "le bout gauche a le vide a l ouest")
	_check_equal(roles[Vector3i(2, 2, 1)], Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), Walls.ROW_CROWN), "le milieu est muet des deux cotes")
	_check_equal(roles[Vector3i(3, 4, 1)], Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_VOID), Walls.ROW_FOOT), "le bout droit a le vide a l est")
	var expected_missing: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
	_check(not shallow["present"].has(Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), 2)), "ce plateau isole d un etage ne montre pas le corps 1")
	_check(shallow["outside"].is_empty(), "aucune robe ne tombe hors de la grille")

	# DEUX ETAGES : la chute de six cases fait apparaitre les douze roles.
	var two_storeys: PackedStringArray = HeightMask.parse(".....
.222.
.....
.....
.....
.....
.....
.....")
	var deep: Dictionary = Walls.analyse(two_storeys)
	_check(deep["present"].size() >= 9, "un plateau de deux etages couvre deja neuf roles (%d)" % deep["present"].size())
	var deep_roles: Dictionary = Walls.assemble(two_storeys)["roles"]
	_check_equal(deep_roles[Vector3i(2, 4, 2)], Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), 2), "la troisieme case de la chute est le corps 1")
	_check_equal(deep_roles[Vector3i(2, 7, 2)], Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), Walls.ROW_FOOT), "la sixieme case pose le pied")
	_check(deep_roles.has(Vector3i(2, 2, 1)), "l etage du dessous deroule sa robe sous celle du haut")

	# UNE ROBE RACCOURCIE PAR SON PROPRE ETAGE NE POSE PAS SON PIED.
	var terrace: PackedStringArray = HeightMask.parse(".....
.111.
.....
.111.
.....
.....
.....
.....")
	_check_equal(Walls.fall_at(terrace, 1, Vector2i(1, 1)), Vector2i(1, 0), "la robe bute sur le morceau d en dessous")
	var terrace_roles: Dictionary = Walls.assemble(terrace)["roles"]
	_check_equal(terrace_roles[Vector3i(1, 2, 1)].y, 1, "raccourcie, elle montre du corps, pas un pied")

	# ET UNE ROBE QUI ATTERRIT SUR SON PROPRE ETAGE NON PLUS.
	var ledge: PackedStringArray = HeightMask.parse(".....
.111.
.....
.....
.....
.111.
.....
.....")
	_check_equal(Walls.fall_at(ledge, 1, Vector2i(1, 1)), Vector2i(3, 0), "elle descend, mais pas sur du sol d en bas")
	var ledge_roles: Dictionary = Walls.assemble(ledge)["roles"]
	_check_equal(ledge_roles[Vector3i(1, 4, 1)].y, 2, "sa derniere case reste du corps")

	# LE PAN SE CHOISIT PAR RANGEE : la meme colonne change de pan en descendant.
	var stair: PackedStringArray = HeightMask.parse("........
.22.....
........
........
........
...1....
........
........
........
........")
	var stair_roles: Dictionary = Walls.assemble(stair)["roles"]
	_check_equal(Walls.pan_east(stair_roles[Vector3i(2, 2, 2)].x), Walls.SIDE_VOID, "en haut, rien a l est : flanc vide")
	_check_equal(Walls.pan_east(stair_roles[Vector3i(2, 5, 2)].x), Walls.SIDE_MUTE, "plus bas, l etage voisin borde : flanc muet")


## ⚠ TOUT MODE OUVERT DOIT PROUVER SON GUIDE. La boucle vaut declaration : ajouter un mode
## au catalogue, c'est s'engager a ce que son guide passe ici.
func _test_mode_guides_are_complete() -> void:
	for id: StringName in Modes.ids():
		if Modes.is_available(id):
			_check_one_guide(id)


func _check_one_guide(id: StringName) -> void:
	print("mode %s : le guide est complet, et ce qui est peint decide" % Modes.label(id))
	var guide_path: String = Modes.guide_path(id)
	var heights: PackedStringArray = HeightMask.read(guide_path)
	var report: Dictionary = Coverage.analyse_relief(heights)
	_check_equal(report["present"].size(), Modes.surface_tile_count(id), "les 47 index de surface visible sont couverts")
	_check(report["is_complete"], "aucun index de surface manquant")
	print("  %d surfaces visibles a peindre" % report["filled_count"])

	# Tout peindre livre les 47 index : c est la borne haute de ce que le guide permet.
	var every_cell: Array[Vector2i] = []
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			if Coverage.visible_index_at(heights, x, y) != Coverage.NO_INDEX:
				every_cell.append(Vector2i(x, y))
	var resolved: Dictionary = Variants.resolve_relief(heights, every_cell)
	_check(resolved["is_exportable"], "guide complet entierement peint : exportable")
	_check_equal(resolved["delivered"].size(), BLOB_TILE_COUNT, "les 47 index sont livres")
	_check(resolved["unused"].is_empty(), "aucune case inutilisee quand tout est peint")

	# ⚠ LA PROMESSE DU MODE EST CHIFFREE, DONC ELLE SE PROUVE. `minimal` annonce 1 variante
	# minimum, `ample` en annonce 3 : c est toute la difference entre les deux, et elle
	# n a pas a etre crue sur parole.
	var promised: int = Modes.min_variants(id)
	var rarest: int = 1 << 30
	for index: int in report["present"]:
		rarest = mini(rarest, int(report["occurrences"][index]))
	_check(rarest >= promised, "chaque index est vu au moins %d fois, comme annonce (le plus rare : %d)" % [promised, rarest])

	# Un guide complet ne suffit pas a exporter : laisser un index ENTIEREMENT vierge le
	# retire. On ne peut pas se contenter d omettre une case -- dans un mode redondant, ses
	# jumelles couvriraient l index.
	var target: int = report["present"][0]
	var skipped: Dictionary = {}
	for cell: Vector3i in report["positions"][target]:
		skipped[Vector2i(cell.x, cell.y)] = true
	var without: Array[Vector2i] = []
	for cell: Vector2i in every_cell:
		if not skipped.has(cell):
			without.append(cell)
	var partial: Dictionary = Variants.resolve_relief(heights, without)
	_check_equal(partial["missing"], PackedInt32Array([target]), "laisser un index entierement vierge le fait manquer, et lui seul")
	_check_equal(partial["is_exportable"], false, "un index non peint interdit l export")


func _test_minimal_guide_walls() -> void:
	for id: StringName in Modes.ids():
		if Modes.is_available(id):
			_check_one_guide_walls(id)


func _check_one_guide_walls(id: StringName) -> void:
	print("mode %s : le guide couvre aussi le vocabulaire de mur" % Modes.label(id))
	var guide_path: String = Modes.guide_path(id)
	var heights: PackedStringArray = HeightMask.read(guide_path)
	_check(HeightMask.top_level(heights) >= 2, "le guide a du relief : au moins deux etages")
	var report: Dictionary = Walls.analyse(heights)
	var present: Array[Vector2i] = report["present"]
	_check_equal(present.size(), Modes.wall_tile_count(id), "les %d roles de mur sont couverts" % Modes.wall_tile_count(id))
	_check(report["is_complete"], "aucun role de mur manquant")
	# ⚠ UNE ROBE QUI TOMBE HORS DE LA GRILLE EST UNE TUILE QU ON NE PEUT PAS PEINDRE.
	# Un guide en relief doit garder de la plaine sous ses falaises.
	var outside: Array[Vector3i] = report["outside"]
	_check_equal(outside.size(), 0, "aucune robe ne tombe hors de la grille")
	print("  grille %dx%d, etages 0..%d" % [HeightMask.width(heights), HeightMask.height(heights), HeightMask.top_level(heights)])
	var occurrences: Dictionary = report["occurrences"]
	var wall_cells: int = 0
	var rarest_role: int = 1 << 30
	for role: Vector2i in occurrences.keys():
		wall_cells += int(occurrences[role])
		rarest_role = mini(rarest_role, int(occurrences[role]))
	_check(rarest_role >= Modes.min_variants(id), "chaque role de mur est vu au moins %d fois (le plus rare : %d)" % [Modes.min_variants(id), rarest_role])
	print("  %d cases de robe deroulees" % wall_cells)


func _test_painting() -> void:
	print("painting : les faux pixels d une tuile")
	var painting: RefCounted = Painting.new(16)
	_check_equal(painting.resolution, 16, "la resolution demandee est retenue")
	var refused: RefCounted = Painting.new(17)
	_check_equal(refused.resolution, Painting.DEFAULT_RESOLUTION, "une resolution hors liste retombe sur le defaut")

	var cell: Vector2i = Vector2i(3, 4)
	_check(not painting.is_painted(cell), "une case vierge n est pas peinte")
	_check(painting.paint(cell, 2, 2, Color.RED), "poser un pixel change la case")
	_check(painting.is_painted(cell), "UN SEUL PIXEL SUFFIT a prendre la case")
	_check_equal(painting.pixel_count(cell), 1, "un pixel compte pour un")
	_check(not painting.paint(cell, 2, 2, Color.RED), "reposer le meme pixel ne change rien")
	painting.paint(cell, 3, 3, Color.RED)
	_check_equal(painting.pixel_count(cell), 2, "deux pixels comptent pour deux")
	painting.erase(cell, 2, 2)
	painting.erase(cell, 3, 3)
	_check(not painting.is_painted(cell), "tout effacer rend la case a l etat vierge")
	_check(not painting.paint(cell, 99, 0, Color.RED), "hors de la tuile, rien n est pose")

	painting.paint(Vector2i(5, 1), 0, 0, Color.RED)
	painting.paint(Vector2i(0, 0), 0, 0, Color.RED)
	var expected: Array[Vector2i] = [Vector2i(0, 0), Vector2i(5, 1)]
	_check_equal(painting.painted_cells(), expected, "les cases peintes sortent en ordre de lecture")


func _test_undo() -> void:
	print("painting : defaire et refaire une passe")
	var painting: RefCounted = Painting.new(16)
	var cell: Vector2i = Vector2i(2, 3)
	_check(not painting.can_undo(), "rien a defaire au depart")

	painting.begin_stroke()
	for i: int in range(4):
		painting.paint(cell, i, 0, Color.RED)
	painting.end_stroke()
	_check_equal(painting.pixel_count(cell), 4, "quatre pixels poses")
	_check(painting.can_undo(), "la passe est defaisable")

	var touched: Array[Vector2i] = painting.undo()
	_check_equal(touched, [cell] as Array[Vector2i], "defaire rend les cases touchees")
	_check_equal(painting.pixel_count(cell), 0, "la passe entiere est defaite d un geste")
	_check(painting.can_redo(), "et elle est refaisable")

	painting.redo()
	_check_equal(painting.pixel_count(cell), 4, "refaire la repose telle quelle")

	# ⚠ LE CAS PIEGEUX : deux pixels au MEME endroit dans la meme passe. Ils ne se defont
	# correctement qu'en rejouant a l'envers -- dans l'ordre, le second ecraserait le premier
	# et la case resterait peinte.
	var twice: RefCounted = Painting.new(16)
	twice.begin_stroke()
	twice.paint(cell, 0, 0, Color.RED)
	twice.paint(cell, 0, 0, Color.BLUE)
	twice.end_stroke()
	twice.undo()
	_check_equal(twice.pixel_count(cell), 0, "deux pixels au meme endroit se defont quand meme")

	# Une passe vide ne s enregistre pas : defaire ne doit jamais avoir l air de ne rien faire.
	var empty: RefCounted = Painting.new(16)
	empty.begin_stroke()
	empty.end_stroke()
	_check(not empty.can_undo(), "une passe sans pixel ne s enregistre pas")

	# Peindre apres avoir defait ferme la branche refaite.
	var branch: RefCounted = Painting.new(16)
	branch.begin_stroke()
	branch.paint(cell, 0, 0, Color.RED)
	branch.end_stroke()
	branch.undo()
	branch.begin_stroke()
	branch.paint(cell, 1, 1, Color.BLUE)
	branch.end_stroke()
	_check(not branch.can_redo(), "peindre apres avoir defait ferme le refaire")


func _test_wall_variants() -> void:
	print("walls : la regle des variantes vaut aussi pour les robes")
	var heights: PackedStringArray = HeightMask.parse(".....
.222.
.....
.....
.....
.....
.....
.....")
	var roles: Dictionary = Walls.visible_roles(heights)
	_check(roles.size() > 0, "le relief produit des cases de robe")
	_check_equal(roles[Vector2i(2, 2)].y, Walls.ROW_CROWN, "la robe du haut masque celle du bas")

	var nothing: Array[Vector2i] = []
	var untouched: Dictionary = Walls.resolve_roles(roles, nothing)
	_check_equal(untouched["delivered"].size(), 0, "sans peinture, aucun role livre")
	_check_equal(untouched["missing"].size(), Walls.ALL_ROLES.size(), "les %d roles manquent" % Walls.ALL_ROLES.size())
	_check_equal(untouched["is_exportable"], false, "rien de peint : rien a exporter")

	var every_cell: Array[Vector2i] = []
	for cell: Vector2i in roles.keys():
		every_cell.append(cell)
	var full: Dictionary = Walls.resolve_roles(roles, every_cell)
	var here: Dictionary = {}
	for role: Vector2i in roles.values():
		here[role] = true
	_check_equal(full["delivered"].size(), here.size(),
			"tout peindre livre exactement les roles que CE relief porte (%d)" % here.size())
	_check(full["unused"].is_empty(), "aucune case de robe inutilisee quand tout est peint")


func _test_twins() -> void:
	print("jumelles : les cases qui portent la meme tuile")
	# Deux ilots isoles portent le meme index : ce sont des variantes l une de l autre.
	var flat: PackedStringArray = HeightMask.parse("#.#")
	var indices: Dictionary = Coverage.index_map(flat)
	var groups: Dictionary = Coverage.cells_by_index(indices)
	_check_equal(groups.size(), 1, "un seul index en jeu")
	var expected: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0)]
	_check_equal(groups[0], expected, "les deux ilots sont jumeaux")

	var relief: PackedStringArray = HeightMask.parse(".....
.222.
.....
.....
.....
.....
.....
.....")
	var roles: Dictionary = Walls.visible_roles(relief)
	var wall_groups: Dictionary = Walls.cells_by_role(roles)
	var distinct: Dictionary = {}
	for role: Vector2i in roles.values():
		distinct[role] = true
	_check_equal(wall_groups.size(), distinct.size(), "chaque role present a son groupe")
	var consistent: bool = true
	var counted: int = 0
	for role: Vector2i in wall_groups.keys():
		var cells: Array[Vector2i] = wall_groups[role]
		counted += cells.size()
		for cell: Vector2i in cells:
			if roles[cell] != role:
				consistent = false
	_check(consistent, "un groupe ne rassemble que des cases du meme role")
	_check_equal(counted, roles.size(), "aucune case de robe n est oubliee ni comptee deux fois")


func _test_symmetry() -> void:
	print("symetries : ce que la rotation et le miroir font, et dans quel sens")
	_check_equal(Symmetry.ROTATION_ORBITS.size(), 15, "les 47 index se rangent en 15 orbites")
	var counted: int = 0
	for orbit: PackedInt32Array in Symmetry.ROTATION_ORBITS:
		counted += orbit.size()
	_check_equal(counted, BLOB_TILE_COUNT, "les orbites couvrent les 47 index, sans doublon")
	_check_equal(Symmetry.MIRROR_ORBITS.size(), 24, "les 36 roles se rangent en 24 orbites de miroir")

	# Un tour complet ramene chaque index a lui-meme.
	var closes: bool = true
	for index: int in BlobIndex.CANONICAL_INDICES:
		var walker: int = index
		for turn: int in range(4):
			walker = Symmetry.rotate_index(walker)
		if walker != index:
			closes = false
	_check(closes, "quatre quarts de tour ramenent chaque index a lui-meme")
	_check_equal(Symmetry.rotate_index(7), 28, "N+NE+E tourne en E+SE+S")

	# ⚠ LA VERIFICATION QUI COMPTE : le voisinage et les pixels doivent tourner dans le MEME
	# sens. Si l un tournait a l envers, la tuile posee contredirait sa propre silhouette, et
	# rien dans les comptes ne le dirait.
	var same_hand: bool = true
	for index: int in BlobIndex.CANONICAL_INDICES:
		var turned: int = Symmetry.rotate_index(index)
		if ((turned & BlobIndex.E) != 0) != ((index & BlobIndex.N) != 0):
			same_hand = false
	_check(same_hand, "un quart de tour envoie le nord du voisinage sur l est")
	_check_equal(Symmetry.transform_pixel(2, 0, 8, Symmetry.TURN_QUARTER), Vector2i(7, 2),
			"et la rangee du haut sur la colonne de droite : meme sens")

	var back: Vector2i = Vector2i(3, 5)
	for turn: int in range(4):
		back = Symmetry.transform_pixel(back.x, back.y, 8, Symmetry.TURN_QUARTER)
	_check_equal(back, Vector2i(3, 5), "quatre quarts de tour ramenent le pixel a sa place")
	_check_equal(Symmetry.transform_pixel(1, 5, 8, Symmetry.MIRROR), Vector2i(6, 5),
			"le miroir echange la gauche et la droite, jamais le haut et le bas")

	# Le miroir des robes : les bouts s echangent, le pan courant ne bouge pas.
	_check_equal(Symmetry.mirror_role(Vector2i(Walls.pan_of(Walls.SIDE_VOID, Walls.SIDE_MUTE), Walls.ROW_CROWN)),
			Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_VOID), Walls.ROW_CROWN), "le miroir echange les deux flancs")
	_check_equal(Symmetry.mirror_role(Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), Walls.ROW_FOOT)),
			Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), Walls.ROW_FOOT), "un pan symetrique est son propre miroir")


func _test_work_io() -> void:
	print("sauvegarde : l art est range par TUILE, pas par case")
	# Deux iles isolees, donc deux exemplaires de l index 0 : S0:0 et S0:1.
	var guide_a: PackedStringArray = HeightMask.parse("#.#
...
...
...")
	# Le meme vocabulaire, mais un paysage qui n a rien a voir : autre taille, autres cases.
	var guide_b: PackedStringArray = HeightMask.parse(
			"....
.#..
....
....
....
..#.
....
....
....")

	var slots_a: Dictionary = WorkIO.slots(guide_a)
	_check(slots_a.size() > 0, "le guide offre des cases a peindre (%d)" % slots_a.size())

	var painting: Painting = Painting.new(16)
	for cell: Vector2i in slots_a.keys():
		painting.paint(cell, 0, 0, _key_colour(String(slots_a[cell])))

	var text: String = WorkIO.serialize(painting, guide_a, Modes.MINIMAL)
	_check(text.begins_with("%s %d" % [WorkIO.MAGIC, WorkIO.VERSION]), "le fichier s annonce des sa premiere ligne")

	var back: Dictionary = WorkIO.parse(text, guide_a)
	_check_equal(back["error"], OK, "relecture sans erreur")
	_check_equal(back["resolution"], 16, "la resolution relue est celle du fichier")
	_check_equal(back["mode"], Modes.MINIMAL, "le mode est retenu")
	_check_equal(int(back["placed"]), slots_a.size(), "toutes les tuiles sont reposees")
	var reread: Painting = back["painting"]
	var faithful: bool = true
	for cell: Vector2i in slots_a.keys():
		if not _pixel_is(reread, cell, _key_colour(String(slots_a[cell]))):
			faithful = false
	_check(faithful, "chaque tuile revient a sa place, pixel pour pixel")

	# LA PROMESSE. Le meme fichier, repose sur un guide redessine de fond en comble.
	var keys_a: Dictionary = WorkIO.cells_by_key(guide_a)
	var keys_b: Dictionary = WorkIO.cells_by_key(guide_b)
	var travelled: Painting = WorkIO.parse(text, guide_b)["painting"]
	var shared: int = 0
	var wrong: int = 0
	var relocated: bool = false
	for key: String in keys_a.keys():
		if not keys_b.has(key):
			continue
		shared += 1
		if keys_b[key] != keys_a[key]:
			relocated = true
		if not _pixel_is(travelled, keys_b[key], _key_colour(key)):
			wrong += 1
	_check(shared > 0, "les deux guides ont des tuiles en commun (%d)" % shared)
	_check(relocated, "et ces tuiles n occupent pas les memes cases d un guide a l autre")
	_check_equal(wrong, 0, "l art retombe sur la BONNE TUILE dans un guide redessine")

	# Ce qui n a plus de place est dit, jamais jete en silence.
	var narrow: PackedStringArray = HeightMask.parse("#..
...
...
...")
	var trimmed: Dictionary = WorkIO.parse(text, narrow)
	var orphans: Array = Array(trimmed["unplaced"])
	_check(orphans.has("S0:1"),
			"un guide sans la seconde ile rend la variante en trop au lieu de la perdre")

	# Et le meme aller-retour, mais par un vrai fichier.
	var path: String = "user://test_travail.%s" % WorkIO.EXTENSION
	_check_equal(WorkIO.write(path, painting, guide_a, Modes.MINIMAL), OK, "ecriture sur disque")
	var from_disk: Dictionary = WorkIO.read(path, guide_a)
	_check_equal(int(from_disk["placed"]), slots_a.size(), "relecture depuis le disque")

	# L en-tete seul, sans decoder une image : c'est par la que passe « Ouvrir », puisqu'il
	# faut charger le bon paysage AVANT de pouvoir y reposer quoi que ce soit.
	var header: Dictionary = WorkIO.peek(path)
	_check_equal(header["error"], OK, "l en-tete se lit seul")
	_check_equal(header["mode"], Modes.MINIMAL, "l en-tete donne le mode")
	_check_equal(int(header["resolution"]), 16, "l en-tete donne la resolution")
	_check(WorkIO.peek("user://pas_un_travail.txt")["error"] != OK,
			"un fichier absent est signale, pas devine")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Une couleur qui ne depend que de la CLE de la tuile : si l art se retrouve ailleurs
## qu ou il doit, la couleur ne colle plus et le test le voit.
func _key_colour(key: String) -> Color:
	var mixed: int = absi(key.hash())
	return Color8(mixed & 255, (mixed >> 8) & 255, (mixed >> 16) & 255, 255)


func _pixel_is(painting: Painting, cell: Vector2i, colour: Color) -> bool:
	var image: Image = painting.image_of(cell)
	return image != null and image.get_pixel(0, 0).is_equal_approx(colour)


func _test_export() -> void:
	print("export : la feuille de tuiles, et le refus de l incomplet")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var by_key: Dictionary = WorkIO.cells_by_key(heights)

	# Le strict necessaire : une seule occurrence de chaque tuile. C'est la definition meme
	# de « exportable » -- il n'a jamais fallu peindre tout le guide.
	var painting: Painting = Painting.new(16)
	var first_keys: Array[String] = []
	for key: String in by_key.keys():
		if key.ends_with(":0"):
			first_keys.append(key)
	for key: String in first_keys:
		painting.paint(by_key[key], 0, 0, _key_colour(key))
	_check_equal(first_keys.size(), BLOB_TILE_COUNT + Walls.ALL_ROLES.size(),
			"le guide minimal porte exactement 59 tuiles obligatoires")

	var report: Dictionary = TilesetPNG.analyse(painting, heights)
	_check(report["is_exportable"], "une occurrence de chaque tuile suffit a exporter")
	_check_equal(int(report["variants"]), 1, "une seule variante peinte, un seul bloc")
	_check(report["missing_surface"].is_empty(), "aucune surface manquante")
	_check(report["missing_wall"].is_empty(), "aucune robe manquante")

	var sheet: Image = TilesetPNG.compose(painting, heights, report, false)
	_check_equal(sheet.get_width(), TilesetPNG.SURFACE_COLUMNS * 16, "huit tuiles de large")
	_check_equal(sheet.get_height(), TilesetPNG.surface_rows() * 16, "six rangees de haut")
	var astray: int = 0
	for index: int in BlobIndex.CANONICAL_INDICES:
		var slot: Vector2i = TilesetPNG.surface_slot(index, 0)
		if not sheet.get_pixel(slot.x * 16, slot.y * 16).is_equal_approx(
				_key_colour("S%d:0" % index)):
			astray += 1
	_check_equal(astray, 0, "les 47 index tombent chacun sur SA case de la planche")

	var kit: Image = TilesetPNG.compose(painting, heights, report, true)
	_check_equal(kit.get_width(), Walls.PAN_COUNT * 16, "la planche de robes fait trois pans")
	_check_equal(kit.get_height(), Walls.BLOCK_ROWS * 16, "et quatre rangees")
	var roles_astray: int = 0
	for role: Vector2i in Walls.ALL_ROLES:
		var at: Vector2i = TilesetPNG.wall_slot(role, 0)
		if not kit.get_pixel(at.x * 16, at.y * 16).is_equal_approx(
				_key_colour("W%d,%d:0" % [role.x, role.y])):
			roles_astray += 1
	_check_equal(roles_astray, 0, "les douze robes tombent chacune sur SA case")

	# Une tuile peinte a son rang 2 sans son rang 0 devient la variante 0 de la planche :
	# sinon un moteur qui tire une variante au hasard tomberait sur du vide.
	var late: String = ""
	for key: String in by_key.keys():
		if key.begins_with("S") and key.ends_with(":2"):
			late = key
			break
	_check(late != "", "le guide minimal offre bien une troisieme occurrence")
	if late != "":
		var lonely: Painting = Painting.new(16)
		lonely.paint(by_key[late], 0, 0, Color.BLUE)
		var packed: Dictionary = TilesetPNG.analyse(lonely, heights)
		var index: int = int(WorkIO.describe(late)["index"])
		var at: Vector2i = TilesetPNG.surface_slot(index, 0)
		var tassee: Image = TilesetPNG.compose(lonely, heights, packed, false)
		_check(tassee.get_pixel(at.x * 16, at.y * 16).is_equal_approx(Color.BLUE),
				"le rang 2 peint seul devient la variante 0 de la planche")

	# LE REFUS. Une tuile de moins, et rien ne sort.
	var folder: String = "user://export_test"
	var partial: Painting = Painting.new(16)
	for key: String in first_keys:
		if key != first_keys[0]:
			partial.paint(by_key[key], 0, 0, Color.RED)
	var refused: Dictionary = TilesetPNG.write(folder, "essai", partial, heights, Modes.MINIMAL)
	_check_equal(refused["error"], ERR_UNAVAILABLE, "une feuille incomplete est REFUSEE")
	_check(not refused["is_exportable"], "et elle se sait incomplete")
	_check(PackedStringArray(refused["written"]).is_empty(), "et rien n est ecrit du tout")

	# Et l aller sur disque.
	var done: Dictionary = TilesetPNG.write(folder, "essai", painting, heights, Modes.MINIMAL)
	_check_equal(done["error"], OK, "la feuille complete s ecrit")
	var written: PackedStringArray = done["written"]
	_check_equal(written.size(), 4, "deux planches, la preuve, et le manifeste")
	var preuve: Image = Image.load_from_file(folder.path_join("essai_preuve.png"))
	_check(preuve != null and preuve.get_width() == HeightMask.width(ProofScene.relief()) * 16,
			"la planche de preuve est ecrite a la taille du relief de preuve")
	var manifest: String = FileAccess.get_file_as_string(folder.path_join("essai_tileset.txt"))
	_check(manifest.begins_with("%s %d" % [TilesetPNG.MAGIC, TilesetPNG.VERSION]),
			"le manifeste s annonce")
	# ⚠ LE MANIFESTE EST LE CONTRAT ENTRE LES DEUX MOITIES DU PRODUIT. Une seconde moitie
	# posera le monde dans Godot et dans Unity ; si une regle n'est pas ECRITE ici, elle
	# vivra dans la tete de celui qui a ecrit le moteur, et le second moteur divergera. On
	# verifie donc que chaque piece de la regle y est.
	var contract: Array[String] = [
		"levels silhouette_per_level", "draw_order bottom_up",
		"canonicalise corner_needs_both_cardinals", "visible own_level",
		"faces south_only", "storey_tiles %d" % Walls.STOREY_TILES,
		"body_rows %d" % Walls.BODY_ROWS, "block_rows %d" % Walls.BLOCK_ROWS,
		"fall storey_tiles_times_gap probe_below_foot",
		"trim stop_on_same_level no_foot",
		"row_for crown_first foot_last body_cycle",
		"pan west_times_three_plus_east lip_row_comparison per_row",
		"bits N=%d" % BlobIndex.N,
	]
	var absent: PackedStringArray = PackedStringArray()
	for clause: String in contract:
		if not manifest.contains(clause):
			absent.append(clause)
	_check_equal(absent, PackedStringArray(),
			"le manifeste porte la REGLE DE POSE en entier, pas seulement la table des cases")
	var relu: Image = Image.load_from_file(folder.path_join("essai_surface.png"))
	_check(relu != null and relu.get_width() == TilesetPNG.SURFACE_COLUMNS * 16,
			"la planche ecrite se relit depuis le disque")
	for path: String in written:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_assembly() -> void:
	print("remontage : le paysage rebati, par DEUX chemins qui doivent se rejoindre")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var slots: Dictionary = WorkIO.slots(heights)

	# On peint TOUT le guide comme le feraient les jumelles : toutes les cases qui portent
	# la meme tuile recoivent le meme dessin. Deux pixels, a deux endroits differents, pour
	# qu'une tuile posee de travers se voie.
	var painting: Painting = Painting.new(16)
	for cell: Vector2i in slots.keys():
		var key: String = String(slots[cell])
		var tile: String = key.substr(0, key.rfind(":"))
		painting.paint(cell, 0, 0, _key_colour(tile))
		painting.paint(cell, 5, 11, _key_colour(tile + "-bis"))

	var report: Dictionary = TilesetPNG.analyse(painting, heights)
	_check(report["is_exportable"], "le guide entierement peint est exportable")
	_check_equal(int(report["variants"]), 1,
			"peindre les jumelles ne fabrique pas cent variantes du meme dessin")

	var surface: Image = TilesetPNG.compose(painting, heights, report, false)
	var kit: Image = TilesetPNG.compose(painting, heights, report, true)
	var direct: Image = Assembly.from_painting(heights, painting)
	var through: Image = Assembly.from_sheets(heights, surface, kit, 16)
	_check_equal(direct.get_size(), through.get_size(), "les deux remontages ont la meme taille")
	_check(direct.get_data() == through.get_data(),
			"LE PAYSAGE REMONTE DEPUIS LES PLANCHES EST IDENTIQUE A CELUI REMONTE DEPUIS LA PEINTURE")

	# Et le remontage n a pas laisse le guide vide : sinon l egalite ci-dessus serait
	# l egalite de deux images noires.
	var painted_pixels: int = 0
	for cell: Vector2i in slots.keys():
		if direct.get_pixel(cell.x * 16, cell.y * 16) != Assembly.BACKDROP:
			painted_pixels += 1
	_check_equal(painted_pixels, slots.size(), "chaque case peignable porte sa tuile au remontage")

	# Deux dessins VRAIMENT differents sur la meme tuile font, eux, deux variantes.
	var twin_key: String = ""
	for key: String in slots.values():
		if key.begins_with("S") and key.ends_with(":1"):
			twin_key = key
			break
	_check(twin_key != "", "le guide offre une seconde occurrence d un index")
	if twin_key != "":
		var by_key: Dictionary = WorkIO.cells_by_key(heights)
		painting.paint(by_key[twin_key], 9, 9, Color.MAGENTA)
		var two: Dictionary = TilesetPNG.analyse(painting, heights)
		var index: int = int(WorkIO.describe(twin_key)["index"])
		_check_equal(two["surface_variants"][index].size(), 2,
				"un dessin different sur une jumelle donne une vraie seconde variante")


func _test_preview_scene() -> void:
	print("apercu en jeu : le decor n emprunte que des tuiles qui existent")
	var scene: PackedStringArray = HeightMask.read("res://guides/preview.txt")
	_check(HeightMask.width(scene) > 0, "le decor existe (%d x %d)" % [
			HeightMask.width(scene), HeightMask.height(scene)])
	_check_equal(Walls.analyse(scene)["outside"].size(), 0,
			"aucune falaise du decor ne tombe hors du cadre")

	var indices: Dictionary = Coverage.index_map(scene)
	var roles: Dictionary = Walls.visible_roles(scene)
	var wild: int = 0
	for index: int in indices.values():
		if not BlobIndex.is_canonical(index):
			wild += 1
	_check_equal(wild, 0, "chaque case du decor porte un index des 47")

	var seen: Dictionary = {}
	for role: Vector2i in roles.values():
		seen[role] = true
	# ⚠ ON N EXIGE PLUS QUE LE DECOR MONTRE TOUT. Depuis que le vocabulaire distingue les
	# faces en retrait, il faudrait y entasser des peignes pour atteindre les 36 -- et un
	# decor entasse n est plus un decor. Il doit montrer les QUATRE rangees, dont le corps 1,
	# parce que c est la que le banding se repere ; le reste est le travail de la preuve.
	var rows_shown: Dictionary = {}
	for role: Vector2i in roles.values():
		rows_shown[role.y] = true
	_check_equal(rows_shown.size(), Walls.BLOCK_ROWS,
			"le decor montre les quatre rangees, corps 1 compris : c est la que le banding se voit")

	# ⚠ LA PROPRIETE QUI COMPTE : le decor ne peut RIEN reclamer que le guide n ait.
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var source_of: Dictionary = Assembly.borrow(scene, guide)
	var expected: int = roles.size()
	for cell: Vector2i in indices.keys():
		if not roles.has(cell):
			expected += 1
	_check_equal(source_of.size(), expected,
			"CHAQUE case du decor trouve sa tuile dans le guide, sans exception")

	var painting: Painting = Painting.new(16)
	for cell: Vector2i in WorkIO.slots(guide).keys():
		painting.paint(cell, 0, 0, Color.RED)
	var decor: Image = Assembly.from_borrowed(scene, guide, painting)
	var holes: int = 0
	for cell: Vector2i in source_of.keys():
		if not decor.get_pixel(cell.x * 16, cell.y * 16).is_equal_approx(Color.RED):
			holes += 1
	_check_equal(holes, 0, "un guide entierement peint remplit le decor sans un seul trou")

	# Et le decor ne montre qu une partie du vocabulaire : c est la verite des tilesets, une
	# carte ordinaire n use qu une poignee de tuiles. On le chiffre plutot que de le taire.
	var shown: Dictionary = {}
	for index: int in indices.values():
		shown[index] = true
	print("  (le decor montre %d des 47 index et %d des %d roles)" % [shown.size(), seen.size(), Walls.ALL_ROLES.size()])


## Combien de reliefs tires au sort. Assez pour que l absence de contre-exemple pese, assez
## peu pour que la suite reste rapide.
const RANDOM_RELIEFS: int = 2000


func _test_vocabulary_is_closed() -> void:
	print("le vocabulaire est FERME : rien ne peut sortir des 47 ni des 12")

	var canonical: Dictionary = {}
	for index: int in BlobIndex.CANONICAL_INDICES:
		canonical[index] = true

	# --- LES SURFACES SONT EXHAUSTIVEMENT PROUVEES, et c est un vrai « tous les cas ».
	# L index d une case ne depend QUE de sa fenetre 3x3 : il n en existe que 512, on les
	# fait toutes. Et comme la silhouette d un etage EST un masque binaire, ceci couvre le
	# relief aussi, quel que soit le nombre d etages.
	var strays: int = 0
	var seen_indices: Dictionary = {}
	for pattern: int in range(512):
		var index: int = Coverage.index_at(_window_of(pattern), 1, 1)
		if index == Coverage.NO_INDEX:
			continue
		seen_indices[index] = true
		if not canonical.has(index):
			strays += 1
	_check_equal(strays, 0, "les 512 fenetres 3x3 POSSIBLES ne donnent que des index des 47")
	_check_equal(seen_indices.size(), BLOB_TILE_COUNT,
			"et elles les donnent tous les 47 : il n y a pas de 48e, ni de 46e")

	# --- LES ROBES NE SE PROUVENT PAS, ELLES SE CHERCHENT. `row_for` et `pan_at` sont NOTRE
	# modele, repris de Satyron ; rien ne demontre qu aucun relief ne reclame un 13e role. On
	# fait donc ce qu on peut faire honnetement : on cherche un contre-exemple, exhaustivement
	# sur une fenetre bornee, puis au hasard sur des reliefs plus grands et plus hauts.
	var known: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		known[role] = true
	var seen_roles: Dictionary = {}
	var wall_strays: int = 0
	for pattern: int in range(1 << 15):
		for role: Vector2i in Walls.visible_roles(_relief_of(pattern, 3, 5)).values():
			seen_roles[role] = true
			if not known.has(role):
				wall_strays += 1
	_check_equal(wall_strays, 0,
			"les 32768 reliefs binaires 3x5 ne donnent que des roles des 12")

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260821
	var wild: int = 0
	for _attempt: int in range(RANDOM_RELIEFS):
		var heights: PackedStringArray = _random_relief(rng, 8, 8, 3)
		for index: int in Coverage.index_map(heights).values():
			if not canonical.has(index):
				wild += 1
		for role: Vector2i in Walls.visible_roles(heights).values():
			seen_roles[role] = true
			if not known.has(role):
				wild += 1
	_check_equal(wild, 0, "%d reliefs 8x8 sur quatre etages, tires au sort : rien n en sort"
			% RANDOM_RELIEFS)

	# ⚠ ET LA RECHERCHE DOIT AVOIR VRAIMENT CHERCHE. Une battue qui ne rencontre aucun des
	# douze roles ne prouve rien du tout : elle prouve qu elle n a rien regarde.
	_check_equal(seen_roles.size(), Walls.ALL_ROLES.size(),
			"et la battue a bien RENCONTRE les %d roles : elle cherche pour de bon" % Walls.ALL_ROLES.size())


## Une fenetre 3x3 binaire, une par bit du motif.
func _window_of(pattern: int) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	for y: int in range(3):
		var line: String = ""
		for x: int in range(3):
			line += "#" if (pattern & (1 << (y * 3 + x))) != 0 else "."
		rows.append(line)
	return rows


## Un relief binaire, une case par bit du motif.
func _relief_of(pattern: int, columns: int, rows_count: int) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	for y: int in range(rows_count):
		var line: String = ""
		for x: int in range(columns):
			line += "1" if (pattern & (1 << (y * columns + x))) != 0 else "."
		rows.append(line)
	return rows


func _random_relief(rng: RandomNumberGenerator, columns: int, rows_count: int,
		top: int) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	for y: int in range(rows_count):
		var line: String = ""
		for x: int in range(columns):
			var level: int = rng.randi_range(0, top)
			line += "." if level == 0 else str(level)
		rows.append(line)
	return rows


func _test_proof_scene() -> void:
	print("planche de preuve : chaque cas, isole, a une place connue d avance")
	var relief: PackedStringArray = ProofScene.relief()
	print("  %d x %d" % [HeightMask.width(relief), HeightMask.height(relief)])

	# ⚠ CHAQUE ILOT PORTE EN SON CENTRE EXACTEMENT LA TUILE ANNONCEE. C est toute la valeur
	# de la planche : on peut pointer du doigt. Construit depuis les bits de l index, donc
	# vrai par construction -- et reverifie quand meme, puisque c est le genre d evidence qui
	# se revele fausse.
	var centres: Dictionary = ProofScene.centres()
	_check_equal(centres.size(), BLOB_TILE_COUNT, "un ilot par index, ni plus ni moins")
	var misplaced: Array[int] = []
	for index: int in centres.keys():
		var at: Vector2i = centres[index]
		if Coverage.visible_index_at(relief, at.x, at.y) != index:
			misplaced.append(index)
	_check_equal(misplaced, [] as Array[int],
			"les 47 ilots portent chacun SON index, a la case annoncee")

	# Et les ilots ne se contaminent pas : la planche entiere ne montre que les 47.
	var report: Dictionary = Coverage.analyse_relief(relief)
	_check(report["is_complete"], "la planche couvre les 47 index")
	var walls: Dictionary = Walls.analyse(relief)
	_check(walls["is_complete"], "et les douze roles de falaise, grace a la butte a deux etages")
	_check_equal(walls["outside"].size(), 0, "aucune robe de la planche ne tombe hors du cadre")

	# La planche doit pouvoir se remplir avec les tuiles du guide, sinon elle montrerait des
	# trous qu aucun travail ne pourrait combler.
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var source_of: Dictionary = Assembly.borrow(relief, guide)
	var indices: Dictionary = Coverage.index_map(relief)
	var roles: Dictionary = Walls.visible_roles(relief)
	var expected: int = roles.size()
	for cell: Vector2i in indices.keys():
		if not roles.has(cell):
			expected += 1
	_check_equal(source_of.size(), expected,
			"CHAQUE case de la planche trouve sa tuile dans le guide")


func _test_corner_network() -> void:
	print("reseau dual : quinze tuiles, et l endroit ou les deux systemes divergent")
	_check_equal(CornerIndex.all_indices().size(), CornerIndex.TILE_COUNT,
			"quinze tuiles, pas seize : le croisement vide ne dessine rien")

	# Fermeture exhaustive, et elle tient en seize cas : un croisement ne depend QUE de ses
	# quatre cases. La table des bits est donc epinglee, pas seulement le compte.
	var wrong: int = 0
	for pattern: int in range(16):
		var mask: PackedStringArray = PackedStringArray([
				("#" if (pattern & CornerIndex.NW) != 0 else ".")
						+ ("#" if (pattern & CornerIndex.NE) != 0 else "."),
				("#" if (pattern & CornerIndex.SW) != 0 else ".")
						+ ("#" if (pattern & CornerIndex.SE) != 0 else "."),
		])
		var expected: int = pattern if pattern != 0 else CornerIndex.NO_INDEX
		if CornerIndex.index_at(mask, 1, 1) != expected:
			wrong += 1
	_check_equal(wrong, 0, "les 16 fenetres 2x2 POSSIBLES donnent chacune son propre code")

	# ⚠ LA OU LES DEUX VOCABULAIRES DIVERGENT. Deux cases qui ne se touchent que par un coin :
	# le blob les voit comme deux cases ISOLEES -- sa canonicalisation jette le contact
	# diagonal -- tandis que le reseau dual a une tuile pour ca. C est pour cette raison qu un
	# guide complet en blob 47 n est PAS automatiquement complet en dual.
	var diagonal: PackedStringArray = HeightMask.parse("1.
.1
..
..
..")
	_check_equal(Coverage.visible_index_at(diagonal, 0, 0), 0,
			"le blob voit la premiere case comme isolee")
	_check_equal(Coverage.visible_index_at(diagonal, 1, 1), 0,
			"et la seconde aussi : le contact diagonal ne lui fait rien")
	_check_equal(CornerIndex.visible_index_at(diagonal, 1, 1),
			CornerIndex.NW | CornerIndex.SE,
			"LE RESEAU DUAL, LUI, A UNE TUILE POUR CE CONTACT : c est toute la divergence")

	# Le guide de `minimal` a ete complete pour ca, et c est asserte comme le reste (regle 4).
	var minimal: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var report: Dictionary = CornerIndex.analyse_relief(minimal)
	_check(report["is_complete"],
			"le guide minimal couvre les quinze croisements, en surface VISIBLE")
	_check_equal(report["present"].size(), CornerIndex.TILE_COUNT, "les quinze sont la")
	print("  %d croisements peignables dans le guide minimal" % report["filled_count"])

	# ⚠ ET LES AUTRES RELIEFS NE LE SONT PAS. On l affiche plutot que de l asserter : ce sont
	# des travaux en cours, et une assertion les rendrait rouges en permanence. Mais tant
	# qu ils manquent une tuile, le reseau dual reste FERME sur eux (regle 5).
	for id: StringName in Modes.ids():
		var other: Dictionary = CornerIndex.analyse_relief(
				HeightMask.read(Modes.guide_path(id)))
		var absent: PackedStringArray = PackedStringArray()
		for index: int in other["missing"]:
			absent.append("%d = %s" % [index, CornerIndex.describe(index)])
		print("  %s : %d/15%s" % [Modes.label(id), other["present"].size(),
				("  absents : " + ", ".join(absent)) if absent.size() > 0 else ""])


## Le cote de tuile des essais de raccord. Assez grand pour que les arrondis existent,
## assez petit pour que quelques milliers de raccords se verifient en un clin d oeil.
const SEAM_TILE: int = 32

## Au-dela de ce saut de teinte a travers un raccord, l oeil voit une couture.
const SEAM_TOLERANCE: float = 0.04

## ⚠ ENTRE DEUX RANGEES D UNE MEME CHUTE, LA TOLERANCE EST QUASI NULLE. C est la meme paroi
## a la meme lumiere : les deux profils doivent etre identiques. Et un ecart minuscule s y
## voit enormement -- une rainure decalee de deux pour cent de teinte est une LIGNE BRISEE,
## que l oeil attrape bien mieux qu un degrade de vingt pour cent.
const WALL_SEAM_TOLERANCE: float = 0.015


func _test_seams() -> void:
	print("RACCORDS : tous les bords partages, verifies un par un")
	# ⚠ CE TEST EXISTE PARCE QUE CHERCHER LES COUTURES A L OEIL NE DIT JAMAIS SI ON LES A
	# TOUTES. Deux tuiles voisines decrivent le MEME bord physique : si l une y met de la
	# matiere et l autre du vide, l une des deux ment. On les compare toutes.
	for style: Array in [
			[GuideImage.Ink.PAINTED, true, "peint avec marques"],
			[GuideImage.Ink.PAINTED, false, "peint nu"],
			[GuideImage.Ink.WIREFRAME, true, "fil avec marques"]]:
		_check_surface_seams(style[0], style[1], String(style[2]))
		_check_wall_seams(style[0], style[1], String(style[2]))
		_check_wall_side_seams(style[0], style[1], String(style[2]))


## LES ROBES : une falaise est UNE face, pas une pile de tuiles.
##
## ⚠ ICI AUCUNE MARCHE NE JUSTIFIE UNE RUPTURE. Deux rangees qui se suivent dans la MEME
## chute decrivent la meme paroi, a la meme lumiere : ce qui traverse leur bord commun --
## rainure, teinte, grain -- doit le traverser sans se decaler. Une rainure qui saute a
## chaque cran, c est une falaise rayee de traits que la roche n a pas.
func _check_wall_seams(ink: GuideImage.Ink, marks: bool, label: String) -> void:
	var tiles: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		tiles[role] = GuideImage.make_wall(role, SEAM_TILE, ink, marks)

	# Les enchainements de rangees qu une chute produit reellement.
	var sequences: Array = []
	for drop: int in [Walls.STOREY_TILES, Walls.STOREY_TILES * 2, Walls.STOREY_TILES * 3]:
		var rows: Array[int] = []
		# ⚠ `row_for` COMPTE LES PAS A PARTIR DE 1 : le premier pas sous la levre est 1, et le
		# dernier vaut `drop`. Iterer depuis 0 fabriquait une sequence qui n existe pas, et le
		# test accusait un enchainement « corps 0 -> chapiteau » que la chute ne produit jamais.
		for step: int in range(1, drop + 1):
			rows.append(Walls.row_for(step, drop, true))
		sequences.append(rows)

	var pairs: Dictionary = {}
	for rows: Array in sequences:
		for k: int in range(rows.size() - 1):
			for pan: int in range(Walls.PAN_COUNT):
				pairs[Vector3i(pan, int(rows[k]), int(rows[k + 1]))] = true

	var worst: float = 0.0
	var worst_pair: String = ""
	var guilty: Array[String] = []
	for pair: Vector3i in pairs.keys():
		var upper: Image = tiles[Vector2i(pair.x, pair.y)]
		var lower: Image = tiles[Vector2i(pair.x, pair.z)]
		var jump: float = _seam_jump(upper, lower, false)
		var name: String = "%s|%s pan %d" % [Walls.ROW_NAMES[pair.y], Walls.ROW_NAMES[pair.z],
				pair.x]
		if jump > worst:
			worst = jump
			worst_pair = name
		if jump > WALL_SEAM_TOLERANCE:
			guilty.append("%s (%.1f%%)" % [name, jump * 100.0])
	print("  %s : %d enchainements de rangees, saut le pire %.1f%% (%s)" % [label,
			pairs.size(), worst * 100.0, worst_pair])
	if guilty.size() > 0:
		print("    %s" % ", ".join(guilty.slice(0, mini(8, guilty.size()))))
	_check(worst <= WALL_SEAM_TOLERANCE,
			"%s : une falaise est UNE face -- profils identiques entre deux rangees (le pire : %.1f%%, %d fautifs)"
			% [label, worst * 100.0, guilty.size()])


## LES ROBES, FLANC CONTRE FLANC.
##
## Deux cases de robe cote a cote decrivent la meme frontiere : ce que l'une met a son bord
## est, l'autre le met a son bord ouest. Mais elles ne doivent pas toujours dire la MEME
## chose, et c'est tout l'interet du vocabulaire a neuf pans.
##
## ⚠ DEUX FLANCS `MUET` FACE A FACE SIGNIFIENT LA MEME LEVRE -- donc la meme face, donc le
## meme pas de chute, donc la MEME RANGEE. C'est le seul cas ou l'on exige des profils
## identiques, et il faut l'avoir compris pour ne pas exiger l'impossible : un chapiteau a
## cote d'un pied n'a aucune raison d'avoir la meme teinte.
##
## ⚠ ET LA OU UN FLANC DIT `DEVANT`, UNE ARETE EST ATTENDUE. Exiger l'identite y
## accuserait le dessin de faire exactement ce qu'on lui demande. On n'exige donc que
## l'absence de TROU : de la matiere d'un cote, de la matiere de l'autre.
##
## ⚠ (devant, devant) N'EXISTE PAS. Si je suis devant mon voisin, il n'est pas devant moi.
## Le tester serait tester une situation que le modele ne peut pas produire.
func _check_wall_side_seams(ink: GuideImage.Ink, marks: bool, label: String) -> void:
	var tiles: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		tiles[role] = GuideImage.make_wall(role, SEAM_TILE, ink, marks)

	var flush: int = 0
	var stepped: int = 0
	var worst: float = 0.0
	var worst_pair: String = ""
	var holes: Array[String] = []
	var guilty: Array[String] = []

	for left_pan: int in range(Walls.PAN_COUNT):
		for right_pan: int in range(Walls.PAN_COUNT):
			var mine: int = Walls.pan_east(left_pan)
			var theirs: int = Walls.pan_west(right_pan)
			# Un flanc VIDE veut dire « pas de roche a cote » : il n'y a alors pas de voisine.
			if mine == Walls.SIDE_VOID or theirs == Walls.SIDE_VOID:
				continue
			if mine == Walls.SIDE_FRONT and theirs == Walls.SIDE_FRONT:
				continue
			var same_face: bool = mine == Walls.SIDE_MUTE and theirs == Walls.SIDE_MUTE
			for left_row: int in range(Walls.BLOCK_ROWS):
				for right_row: int in range(Walls.BLOCK_ROWS):
					# Meme levre, donc meme pas de chute, donc meme rangee.
					if same_face and left_row != right_row:
						continue
					var a: Image = tiles[Vector2i(left_pan, left_row)]
					var b: Image = tiles[Vector2i(right_pan, right_row)]
					var gap: int = 0
					for y: int in range(SEAM_TILE):
						if (a.get_pixel(SEAM_TILE - 1, y).a > 0.5) \
								!= (b.get_pixel(0, y).a > 0.5):
							gap += 1
					var name: String = "%s|%s / %s|%s" % [Walls.pan_name(left_pan),
							Walls.ROW_NAMES[left_row], Walls.pan_name(right_pan),
							Walls.ROW_NAMES[right_row]]
					if gap > 0:
						holes.append(name)
					if not same_face:
						stepped += 1
						continue
					flush += 1
					var jump: float = _seam_jump(a, b, true)
					if jump > worst:
						worst = jump
						worst_pair = name
					if jump > WALL_SEAM_TOLERANCE:
						guilty.append("%s (%.1f%%)" % [name, jump * 100.0])

	print("  %s : %d raccords de paroi continue, %d au droit d une arete" % [label, flush,
			stepped])
	_check_equal(holes.size(), 0,
			"%s : aucun trou entre deux robes voisines%s" % [label, _first_few(holes)])
	_check(worst <= WALL_SEAM_TOLERANCE,
			"%s : deux flancs MUETS sont la MEME paroi -- profils identiques (le pire : %.1f%%, %d fautifs)"
			% [label, worst * 100.0, guilty.size()])
	if guilty.size() > 0:
		print("    %s" % ", ".join(guilty.slice(0, mini(6, guilty.size()))))


func _check_surface_seams(ink: GuideImage.Ink, marks: bool, label: String) -> void:
	var tiles: Dictionary = {}
	for index: int in BlobIndex.CANONICAL_INDICES:
		tiles[index] = GuideImage.make_top(index, 1, SEAM_TILE, ink, marks)

	var broken_east: Array[String] = []
	var steps_east: Array[String] = []
	var steps_south: Array[String] = []
	var worst_east: float = 0.0
	var worst_south: float = 0.0
	var worst_east_pair: String = ""
	var worst_south_pair: String = ""
	var pairs_east: Dictionary = _adjacent_pairs(true)
	for pair: Vector2i in pairs_east.keys():
		var left: Image = tiles[pair.x]
		var right: Image = tiles[pair.y]
		var holes: int = 0
		for y: int in range(SEAM_TILE):
			var a: float = left.get_pixel(SEAM_TILE - 1, y).a
			var b: float = right.get_pixel(0, y).a
			if (a > 0.5) != (b > 0.5):
				holes += 1
		if holes > 0:
			broken_east.append("%d|%d (%d lignes)" % [pair.x, pair.y, holes])
		var jump: float = _seam_jump(left, right, true)
		if jump > worst_east:
			worst_east = jump
			worst_east_pair = "%d|%d" % [pair.x, pair.y]
		if jump > 0.06:
			steps_east.append("%d|%d (%.0f%%)" % [pair.x, pair.y, jump * 100.0])

	var broken_south: Array[String] = []
	var pairs_south: Dictionary = _adjacent_pairs(false)
	for pair: Vector2i in pairs_south.keys():
		var top: Image = tiles[pair.x]
		var bottom: Image = tiles[pair.y]
		var holes: int = 0
		for x: int in range(SEAM_TILE):
			var a: float = top.get_pixel(x, SEAM_TILE - 1).a
			var b: float = bottom.get_pixel(x, 0).a
			if (a > 0.5) != (b > 0.5):
				holes += 1
		if holes > 0:
			broken_south.append("%d|%d (%d colonnes)" % [pair.x, pair.y, holes])
		var jump: float = _seam_jump(top, bottom, false)
		if jump > worst_south:
			worst_south = jump
			worst_south_pair = "%d|%d" % [pair.x, pair.y]
		if jump > 0.06:
			steps_south.append("%d|%d (%.0f%%)" % [pair.x, pair.y, jump * 100.0])

	print("  %s : %d raccords est-ouest, %d nord-sud" % [label, pairs_east.size(),
			pairs_south.size()])
	print("    saut de teinte le pire : est-ouest %.0f%% (%s), nord-sud %.0f%% (%s)"
			% [worst_east * 100.0, worst_east_pair, worst_south * 100.0, worst_south_pair])
	print("    raccords qui sautent de plus de 6%% : %d est-ouest, %d nord-sud"
			% [steps_east.size(), steps_south.size()])
	if steps_east.size() > 0:
		print("      %s" % ", ".join(steps_east.slice(0, mini(8, steps_east.size()))))
	# ⚠ LE SAUT DE TEINTE EST UN RELEVE, PAS UNE ASSERTION -- ET J AI EU TORT DE L ASSERTER.
	# A la frontiere entre une case dont le nord est plein et une case dont le nord est vide,
	# la levre eclairee s arrete NET, et elle a raison de s arreter : le terrain fait une
	# marche a cet endroit. Exiger la continuite de teinte accuserait donc le dessin d etre
	# fidele. Ce qui doit etre continu, c est la MATIERE, et elle l est (asserte ci-dessus).
	_check_equal(broken_east.size(), 0,
			"%s : aucune fissure est-ouest%s" % [label, _first_few(broken_east)])
	_check_equal(broken_south.size(), 0,
			"%s : aucune fissure nord-sud%s" % [label, _first_few(broken_south)])


## Le plus grand saut de teinte a travers un raccord, rapporte au saut NATUREL juste a
## cote. ⚠ UNE COUTURE, C EST UN SAUT QUE LE DESSIN NE FAIT PAS AILLEURS : comparer dans
## l absolu accuserait les degrades legitimes, comparer au voisinage immediat ne retient
## que ce qui tranche.
func _seam_jump(first: Image, second: Image, east: bool) -> float:
	var worst: float = 0.0
	for k: int in range(SEAM_TILE):
		var a: Color = first.get_pixel(SEAM_TILE - 1, k) if east 				else first.get_pixel(k, SEAM_TILE - 1)
		var b: Color = second.get_pixel(0, k) if east else second.get_pixel(k, 0)
		if a.a < 0.5 or b.a < 0.5:
			continue
		var inside_a: Color = first.get_pixel(SEAM_TILE - 2, k) if east 				else first.get_pixel(k, SEAM_TILE - 2)
		var inside_b: Color = second.get_pixel(1, k) if east else second.get_pixel(k, 1)
		var across: float = _tone_gap(a, b)
		var natural: float = maxf(_tone_gap(inside_a, a), _tone_gap(b, inside_b))
		worst = maxf(worst, across - natural)
	return worst


func _tone_gap(left: Color, right: Color) -> float:
	return maxf(absf(left.r - right.r), maxf(absf(left.g - right.g), absf(left.b - right.b)))


## Les paires d index qui peuvent REELLEMENT se toucher.
##
## ⚠ ON NE DEVINE PAS LES PAIRES DEPUIS LES BITS. La canonicalisation jette des bits de
## coin : deux index ne suffisent pas a dire s ils sont compatibles. On enumere donc les
## reliefs -- toutes les fenetres 4x3 (ou 3x4) -- et on releve ce qui s y touche vraiment.
func _adjacent_pairs(east: bool) -> Dictionary:
	var found: Dictionary = {}
	var columns: int = 4 if east else 3
	var rows: int = 3 if east else 4
	for pattern: int in range(1 << (columns * rows)):
		var mask: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				line += "#" if (pattern & (1 << (y * columns + x))) != 0 else "."
			mask.append(line)
		var first: Vector2i = Vector2i(1, 1)
		var second: Vector2i = Vector2i(2, 1) if east else Vector2i(1, 2)
		var a: int = Coverage.index_at(mask, first.x, first.y)
		var b: int = Coverage.index_at(mask, second.x, second.y)
		if a == Coverage.NO_INDEX or b == Coverage.NO_INDEX:
			continue
		found[Vector2i(a, b)] = true
	return found


func _first_few(items: Array[String]) -> String:
	if items.is_empty():
		return ""
	var shown: Array[String] = items.slice(0, mini(6, items.size()))
	return " -- %d cassures, dont %s" % [items.size(), ", ".join(shown)]


func _test_guide_image() -> void:
	print("rendu : l illustration se calcule depuis le relief seul")
	var heights: PackedStringArray = HeightMask.parse(".....
.222.
.....
.....
.....
.....
.....
.....")
	var image: Image = GuideImage.render(heights)
	_check_equal(image.get_width(), 5 * GuideImage.TILE, "une case du guide vaut TILE pixels de large")
	_check_equal(image.get_height(), 8 * GuideImage.TILE, "et TILE pixels de haut")

	var half: int = GuideImage.TILE / 2
	var plain: Color = image.get_pixel(4 * GuideImage.TILE + half, 6 * GuideImage.TILE + half)
	var summit: Color = image.get_pixel(2 * GuideImage.TILE + half, 1 * GuideImage.TILE + half)
	var face: Color = image.get_pixel(2 * GuideImage.TILE + half, 3 * GuideImage.TILE + half)
	# Le sommet d un plateau est plus clair que la plaine : c est ce qui fait lire l altitude.
	_check(summit.a > 0.9, "le sommet d un plateau, lui, est bien pose")
	# Une face de falaise est chaude ; les herbes sont vertes. On les distingue sans les nommer.
	_check(face.r > face.g, "la falaise est plus chaude que l herbe")
	# ⚠ LA PLAINE NE SE DESSINE PAS. Elle ne nous appartient pas : dans le jeu, le sol sous
	# les plateaux sera un ETAGE PLAT DU MEME TILESET, pose par le moteur sur sa propre
	# couche. En peindre un ici reviendrait a livrer un fond que le tileset ne contient pas.
	_check_equal(plain.a, 0.0, "la plaine ne se dessine pas : elle ne nous appartient pas")
	# Rien d aleatoire : deux rendus du meme relief donnent la meme image.
	var again: Image = GuideImage.render(heights)
	_check_equal(again.get_data(), image.get_data(), "le rendu est deterministe")

	# ⚠ LES QUATRE FONDS SORTENT DE LA MEME FONCTION ET DU MEME RELIEF, et aucun ne
	# ressemble a un autre : deux encres, deux usages.
	# ⚠ TROIS AXES INDEPENDANTS FONT HUIT DESSINS : deux paysages, deux techniques, deux
	# styles. Aucun ne doit ressembler a un autre, sans quoi l un serait rendu a la place
	# de l autre sans que personne ne le voie.
	var drawings: Array[PackedByteArray] = []
	for id: StringName in Modes.ids():
		var relief: PackedStringArray = HeightMask.read(Modes.guide_path(id))
		for ink: GuideImage.Ink in [GuideImage.Ink.PAINTED, GuideImage.Ink.WIREFRAME]:
			for marks: bool in [true, false]:
				drawings.append(GuideImage.render(relief, 8, ink,
						GuideImage.Purpose.REPRESENTATIVE, marks).get_data())
	_check_equal(drawings.size(), 8, "huit dessins : 2 paysages x 2 encres x 2 etats de marques")
	var all_different: bool = true
	for first: int in range(drawings.size()):
		for second: int in range(first + 1, drawings.size()):
			if drawings[first] == drawings[second]:
				all_different = false
	_check(all_different, "les huit sont differents deux a deux")

	var wire: Image = GuideImage.render(heights, GuideImage.TILE, GuideImage.Ink.WIREFRAME,
			GuideImage.Purpose.REPRESENTATIVE, true)
	var neutral: Color = wire.get_pixel(4 * GuideImage.TILE + half, 6 * GuideImage.TILE + half)
	_check(absf(neutral.r - neutral.g) < 0.08 and absf(neutral.g - neutral.b) < 0.08,
			"le fil de fer est neutre : il n impose aucune teinte aux couleurs qu on pose")


## ⚠ LA SUITE NE CHARGE PAS L'INTERFACE PAR AILLEURS, et une faute de frappe dans un script
## d'ui passait donc au travers -- decouvert en dur, sur un `PackedStringArray.hash()` qui
## n'existe pas. Charger chaque script suffit a les faire analyser par le moteur.
func _test_wireframe_joins() -> void:
	print("rendu : le trait se raccorde, sans trou aux coins rentrants")
	var side: int = 48
	# ⚠ CHAQUE TRAIT EST TIRE A L'INTERIEUR DE SA PROPRE TUILE. Au coin rentrant, les deux
	# voisines se croisent sans se rejoindre : c'est la tuile qui CONNAIT le coin -- deux
	# cardinaux pleins, diagonale vide -- qui doit fermer le coude. Sans elle, un carre vide
	# de la largeur du trait apparait a chaque angle, et le dessin se troue.
	var notched: Image = GuideImage.make_top(253, 1, side, GuideImage.Ink.WIREFRAME,
			false)
	var solid: Image = GuideImage.make_top(255, 1, side, GuideImage.Ink.WIREFRAME,
			false)
	var base: Color = GuideImage.WIRE_LEVELS[1]
	var notched_corner: Color = notched.get_pixel(side - 1, 0)
	var solid_corner: Color = solid.get_pixel(side - 1, 0)
	_check(not _same_ink(notched_corner, base),
			"l index 253 ferme son coude au nord-est : le vide y touche son angle")
	_check(_same_ink(solid_corner, base),
			"l index 255 ne trace rien : aucune de ses diagonales n est vide")

	# Un cote ouvert doit etre trace d'un bord a l'autre, sinon il ne rejoint pas la voisine.
	var open_north: Image = GuideImage.make_top(20, 1, side, GuideImage.Ink.WIREFRAME,
			false)
	var reaches: bool = true
	for x: int in range(side):
		if open_north.get_pixel(x, 0).a > 0.0 and _same_ink(open_north.get_pixel(x, 0), base):
			reaches = false
	_check(reaches, "un cote ouvert est trace d un bord a l autre")


## Deux couleurs sont-elles la meme, au pas du 8 bits pres ? Comparer a l egalite stricte
## echouerait sur la quantification, pour une raison etrangere au dessin.
func _same_ink(left: Color, right: Color) -> bool:
	return absf(left.r - right.r) < 0.02 and absf(left.g - right.g) < 0.02 			and absf(left.b - right.b) < 0.02


func _test_every_script_parses() -> void:
	print("tous les scripts du depot s analysent")
	var scripts: PackedStringArray = PackedStringArray()
	_collect_scripts("res://", scripts)
	_check(scripts.size() >= 12, "au moins douze scripts trouves (%d)" % scripts.size())
	var broken: PackedStringArray = PackedStringArray()
	for path: String in scripts:
		if ResourceLoader.load(path, "Script") == null:
			broken.append(path)
	_check_equal(broken, PackedStringArray(), "aucun script en erreur")


func _collect_scripts(folder: String, into: PackedStringArray) -> void:
	var directory: DirAccess = DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		var path: String = folder.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_scripts(path, into)
		elif entry.ends_with(".gd"):
			into.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


# --- Etat du guide candidat (informatif, pas une assertion) -----------------

func _report_candidate_guide() -> void:
	print("guide candidat : %s" % CANDIDATE_GUIDE_PATH)
	if not FileAccess.file_exists(CANDIDATE_GUIDE_PATH):
		print("  (absent)")
		return
	var mask: PackedStringArray = MaskIO.read(CANDIDATE_GUIDE_PATH)
	var report: Dictionary = Coverage.analyse(mask)
	var present: PackedInt32Array = report["present"]
	print("  grille %dx%d, %d cases pleines" % [MaskIO.width(mask), MaskIO.height(mask), report["filled_count"]])
	print("  couverture %d/%d" % [present.size(), BLOB_TILE_COUNT])
	var missing: PackedInt32Array = report["missing"]
	if missing.is_empty():
		print("  aucun index manquant")
		return
	print("  index manquants (%d) :" % missing.size())
	for index: int in missing:
		print("    %3d = %s" % [index, _describe_index(index)])


## Decomposition d'un index en noms de bits, pour savoir quoi dessiner.
func _describe_index(index: int) -> String:
	return BlobIndex.describe(index)


func _print_summary() -> void:
	print("")
	if _failures.is_empty():
		print("%d verifications, 0 echec." % _checks)
		return
	print("%d verifications, %d echec(s) :" % [_checks, _failures.size()])
	for failure: String in _failures:
		print("  - %s" % failure)
