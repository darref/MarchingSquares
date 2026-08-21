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
	# ⚠ 23, PAS 22. Le 22 serait le compte du groupe complet -- rotations ET miroirs sur
	# les surfaces. Les miroirs de surface n y gagnent qu UNE tuile (15 orbites deviennent
	# 14), et on les a ecartes pour ca. Les robes, elles, n ont que le miroir : 12 -> 8.
	_check_equal(Symmetry.surface_work_count() + Symmetry.wall_work_count(), 23,
			"avec les rotations : 15 surfaces + 8 robes = 23, contre 59")
	_check(Modes.is_available(Modes.MINIMAL), "minimal a son guide, il se choisit")
	_check(Modes.is_available(Modes.AMPLE), "ample a son guide, il se choisit")
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
	_check_equal(present.size(), Modes.wall_tile_count(id), "les 12 roles de mur sont couverts")
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


func _test_symmetry() -> void:
	print("symetries : ce que la rotation et le miroir font, et dans quel sens")
	_check_equal(Symmetry.ROTATION_ORBITS.size(), 15, "les 47 index se rangent en 15 orbites")
	var counted: int = 0
	for orbit: PackedInt32Array in Symmetry.ROTATION_ORBITS:
		counted += orbit.size()
	_check_equal(counted, BLOB_TILE_COUNT, "les orbites couvrent les 47 index, sans doublon")
	_check_equal(Symmetry.MIRROR_ORBITS.size(), 8, "les 12 roles se rangent en 8 paires")

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
	_check_equal(Symmetry.mirror_role(Vector2i(Walls.PAN_LEFT, Walls.ROW_CROWN)),
			Vector2i(Walls.PAN_RIGHT, Walls.ROW_CROWN), "le pan gauche devient le pan droit")
	_check_equal(Symmetry.mirror_role(Vector2i(Walls.PAN_MIDDLE, Walls.ROW_FOOT)),
			Vector2i(Walls.PAN_MIDDLE, Walls.ROW_FOOT), "le pan courant est son propre miroir")


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
	_check(text.begins_with("absolutiles 1"), "le fichier s annonce des sa premiere ligne")

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
	_check_equal(written.size(), 3, "deux planches et un manifeste")
	var manifest: String = FileAccess.get_file_as_string(folder.path_join("essai_tileset.txt"))
	_check(manifest.begins_with("absolutiles-tileset 1"), "le manifeste s annonce")
	_check(manifest.contains("storey_tiles %d" % Walls.STOREY_TILES),
			"le manifeste donne la hauteur d etage, sans quoi on ne remonte pas une falaise")
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
	_check_equal(seen.size(), Walls.ALL_ROLES.size(),
			"le decor montre les DOUZE tuiles de falaise : c est la que le banding se voit")

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
	print("  (le decor montre %d des 47 index et %d des 12 roles)" % [shown.size(), seen.size()])


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

	# ⚠ LES QUATRE FONDS SORTENT DE LA MEME FONCTION ET DU MEME RELIEF, et aucun ne
	# ressemble a un autre : deux encres, deux usages.
	# ⚠ TROIS AXES INDEPENDANTS FONT HUIT DESSINS : deux paysages, deux techniques, deux
	# styles. Aucun ne doit ressembler a un autre, sans quoi l un serait rendu a la place
	# de l autre sans que personne ne le voie.
	var drawings: Array[PackedByteArray] = []
	for id: StringName in Modes.ids():
		var relief: PackedStringArray = HeightMask.read(Modes.guide_path(id))
		for ink: GuideImage.Ink in [GuideImage.Ink.PAINTED, GuideImage.Ink.WIREFRAME]:
			for purpose: GuideImage.Purpose in [GuideImage.Purpose.REPRESENTATIVE, GuideImage.Purpose.USABLE]:
				drawings.append(GuideImage.render(relief, 8, ink, purpose).get_data())
	_check_equal(drawings.size(), 8, "huit dessins : 2 paysages x 2 techniques x 2 styles")
	var all_different: bool = true
	for first: int in range(drawings.size()):
		for second: int in range(first + 1, drawings.size()):
			if drawings[first] == drawings[second]:
				all_different = false
	_check(all_different, "les huit sont differents deux a deux")

	var wire: Image = GuideImage.render(heights, GuideImage.TILE, GuideImage.Ink.WIREFRAME,
			GuideImage.Purpose.REPRESENTATIVE)
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
			GuideImage.Purpose.USABLE)
	var solid: Image = GuideImage.make_top(255, 1, side, GuideImage.Ink.WIREFRAME,
			GuideImage.Purpose.USABLE)
	var base: Color = GuideImage.WIRE_LEVELS[1]
	var notched_corner: Color = notched.get_pixel(side - 1, 0)
	var solid_corner: Color = solid.get_pixel(side - 1, 0)
	_check(not _same_ink(notched_corner, base),
			"l index 253 ferme son coude au nord-est : le vide y touche son angle")
	_check(_same_ink(solid_corner, base),
			"l index 255 ne trace rien : aucune de ses diagonales n est vide")

	# Un cote ouvert doit etre trace d'un bord a l'autre, sinon il ne rejoint pas la voisine.
	var open_north: Image = GuideImage.make_top(20, 1, side, GuideImage.Ink.WIREFRAME,
			GuideImage.Purpose.USABLE)
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
