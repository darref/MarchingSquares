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
	_test_minimal_guide_is_complete()
	_test_minimal_guide_walls()
	_test_painting()
	_test_wall_variants()
	_test_twins()
	_test_guide_image()
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
	_check_equal(ids.size(), 2, "deux modes au catalogue")
	_check_equal(ids[0], Modes.MINIMAL, "le premier est minimal")
	_check_equal(ids[1], Modes.AMPLE, "le second est ample")
	_check(Modes.is_available(Modes.MINIMAL), "minimal a son guide, il se choisit")
	_check(not Modes.is_available(Modes.AMPLE), "ample n a pas encore de guide : il reste ferme")
	_check_equal(Modes.label(Modes.MINIMAL), "Minimal", "libelle du mode minimal")
	_check_equal(Modes.surface_tile_count(Modes.MINIMAL), BLOB_TILE_COUNT, "47 tuiles de surface")
	_check_equal(Modes.wall_tile_count(Modes.MINIMAL), Walls.ALL_ROLES.size(), "12 tuiles de mur")
	_check_equal(Modes.tile_count(Modes.MINIMAL), BLOB_TILE_COUNT + Walls.ALL_ROLES.size(), "59 tuiles en tout")
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
	_check_equal(Walls.ALL_ROLES.size(), 12, "douze roles : trois pans par quatre rangees")
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
	_check_equal(roles[Vector3i(1, 2, 1)], Vector2i(Walls.PAN_LEFT, Walls.ROW_CROWN), "le bout gauche montre son pan gauche")
	_check_equal(roles[Vector3i(2, 2, 1)], Vector2i(Walls.PAN_MIDDLE, Walls.ROW_CROWN), "le milieu montre le pan courant")
	_check_equal(roles[Vector3i(3, 4, 1)], Vector2i(Walls.PAN_RIGHT, Walls.ROW_FOOT), "le bout droit pose son pied")
	var expected_missing: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
	_check_equal(shallow["missing"], expected_missing, "ce plateau isole d un etage ne montre pas le corps 1")
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
	_check(deep["is_complete"], "un plateau de deux etages couvre les douze roles")
	var deep_roles: Dictionary = Walls.assemble(two_storeys)["roles"]
	_check_equal(deep_roles[Vector3i(2, 4, 2)], Vector2i(Walls.PAN_MIDDLE, 2), "la troisieme case de la chute est le corps 1")
	_check_equal(deep_roles[Vector3i(2, 7, 2)], Vector2i(Walls.PAN_MIDDLE, Walls.ROW_FOOT), "la sixieme case pose le pied")
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
	_check_equal(stair_roles[Vector3i(2, 2, 2)].x, Walls.PAN_RIGHT, "en haut, rien de haut a l est : pan droit")
	_check_equal(stair_roles[Vector3i(2, 5, 2)].x, Walls.PAN_MIDDLE, "plus bas, l etage voisin borde : pan courant")


func _test_minimal_guide_is_complete() -> void:
	print("mode minimal : le guide est complet, et ce qui est peint decide")
	var guide_path: String = Modes.guide_path(Modes.MINIMAL)
	_check(FileAccess.file_exists(guide_path), "le guide du mode minimal existe")
	if not FileAccess.file_exists(guide_path):
		return
	var heights: PackedStringArray = HeightMask.read(guide_path)
	var report: Dictionary = Coverage.analyse_relief(heights)
	_check_equal(report["present"].size(), Modes.surface_tile_count(Modes.MINIMAL), "les 47 index de surface visible sont couverts")
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

	# Un guide complet ne suffit pas : laisser une case seule non peinte retire son index.
	var solo_index: int = -1
	for index: int in report["present"]:
		if int(report["occurrences"][index]) == 1:
			solo_index = index
			break
	_check(solo_index >= 0, "le guide contient au moins un index a occurrence unique")
	if solo_index < 0:
		return
	var solo_cells: Array[Vector3i] = report["positions"][solo_index]
	var solo_cell: Vector2i = Vector2i(solo_cells[0].x, solo_cells[0].y)
	var without_solo: Array[Vector2i] = []
	for cell: Vector2i in every_cell:
		if cell != solo_cell:
			without_solo.append(cell)
	var partial: Dictionary = Variants.resolve_relief(heights, without_solo)
	_check_equal(partial["missing"], PackedInt32Array([solo_index]), "laisser cette case non peinte fait manquer exactement son index")
	_check_equal(partial["is_exportable"], false, "un index non peint interdit l export")


func _test_minimal_guide_walls() -> void:
	print("mode minimal : le guide couvre aussi le vocabulaire de mur")
	var guide_path: String = Modes.guide_path(Modes.MINIMAL)
	if not FileAccess.file_exists(guide_path):
		_check(false, "le guide du mode minimal existe")
		return
	var heights: PackedStringArray = HeightMask.read(guide_path)
	_check(HeightMask.top_level(heights) >= 2, "le guide a du relief : au moins deux etages")
	var report: Dictionary = Walls.analyse(heights)
	var present: Array[Vector2i] = report["present"]
	_check_equal(present.size(), Modes.wall_tile_count(Modes.MINIMAL), "les 12 roles de mur sont couverts")
	_check(report["is_complete"], "aucun role de mur manquant")
	# ⚠ UNE ROBE QUI TOMBE HORS DE LA GRILLE EST UNE TUILE QU ON NE PEUT PAS PEINDRE.
	# Un guide en relief doit garder de la plaine sous ses falaises.
	var outside: Array[Vector3i] = report["outside"]
	_check_equal(outside.size(), 0, "aucune robe ne tombe hors de la grille")
	print("  grille %dx%d, etages 0..%d" % [HeightMask.width(heights), HeightMask.height(heights), HeightMask.top_level(heights)])
	var occurrences: Dictionary = report["occurrences"]
	var wall_cells: int = 0
	for role: Vector2i in occurrences.keys():
		wall_cells += int(occurrences[role])
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
	_check_equal(roles[Vector2i(2, 2)], Vector2i(Walls.PAN_MIDDLE, Walls.ROW_CROWN), "la robe du haut masque celle du bas")

	var nothing: Array[Vector2i] = []
	var untouched: Dictionary = Walls.resolve_roles(roles, nothing)
	_check_equal(untouched["delivered"].size(), 0, "sans peinture, aucun role livre")
	_check_equal(untouched["missing"].size(), Walls.ALL_ROLES.size(), "les douze roles manquent")
	_check_equal(untouched["is_exportable"], false, "rien de peint : rien a exporter")

	var every_cell: Array[Vector2i] = []
	for cell: Vector2i in roles.keys():
		every_cell.append(cell)
	var full: Dictionary = Walls.resolve_roles(roles, every_cell)
	_check(full["is_exportable"], "tout peindre livre les douze roles")
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
	_check_equal(wall_groups.size(), Walls.ALL_ROLES.size(), "les douze roles forment douze groupes")
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
	_check(summit.get_luminance() > plain.get_luminance(), "le plateau ressort sur la plaine")
	# Une face de falaise est chaude ; les herbes sont vertes. On les distingue sans les nommer.
	_check(face.r > face.g, "la falaise est plus chaude que l herbe")
	_check(plain.g > plain.r, "la plaine est verte")
	# Rien d aleatoire : deux rendus du meme relief donnent la meme image.
	var again: Image = GuideImage.render(heights)
	_check_equal(again.get_data(), image.get_data(), "le rendu est deterministe")

	# ⚠ LES DEUX STYLES SORTENT DE LA MEME FONCTION ET DU MEME RELIEF, mais ne montrent pas
	# la meme chose : l un le resultat, l autre la structure.
	var usable: Image = GuideImage.render(heights, GuideImage.TILE, GuideImage.Style.USABLE)
	_check_equal(usable.get_size(), image.get_size(), "les deux styles ont la meme taille")
	_check(usable.get_data() != image.get_data(), "le style utilisable rend autre chose")
	var neutral: Color = usable.get_pixel(4 * GuideImage.TILE + half, 6 * GuideImage.TILE + half)
	_check(absf(neutral.r - neutral.g) < 0.08 and absf(neutral.g - neutral.b) < 0.08,
			"le fond utilisable est neutre : il n impose aucune teinte aux couleurs qu on pose")


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
	const NAMES: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var parts: PackedStringArray = PackedStringArray()
	for bit_index: int in range(BlobIndex.BITS.size()):
		if (index & BlobIndex.BITS[bit_index]) != 0:
			parts.append(NAMES[bit_index])
	if parts.is_empty():
		return "aucun voisin"
	return "+".join(parts)


func _print_summary() -> void:
	print("")
	if _failures.is_empty():
		print("%d verifications, 0 echec." % _checks)
		return
	print("%d verifications, %d echec(s) :" % [_checks, _failures.size()])
	for failure: String in _failures:
		print("  - %s" % failure)
