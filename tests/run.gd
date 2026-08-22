# Runner de tests headless du noyau AbsoluTiles.
#
#   godot --headless --path . --script res://tests/run.gd
#
# Code de sortie 0 si tout passe, 1 sinon.
extends SceneTree

const BlobIndex := preload("res://core/blob_index.gd")
const MaskIO := preload("res://core/mask_io.gd")
const Coverage := preload("res://core/coverage.gd")
const Delivery := preload("res://core/delivery.gd")
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
const Families := preload("res://core/families.gd")
const PluginInstall := preload("res://core/plugin_install.gd")
const PluginRules := preload("res://addons/absolupaint/rules.gd")
const PluginManifest := preload("res://addons/absolupaint/manifest.gd")
const PluginTileSet := preload("res://addons/absolupaint/tileset.gd")

const CANDIDATE_GUIDE_PATH: String = "res://guides/candidate_01.txt"
const BLOB_TILE_COUNT: int = 47

## Combien de mondes tires au sort la comparaison plugin / noyau examine a chaque execution.
const PLUGIN_RANDOM_RELIEFS: int = 400

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
	_test_wall_delivery()
	_test_twins()
	_test_symmetry()
	_test_work_io()
	_test_export()
	_test_assembly()
	_test_preview_scene()
	_test_vocabulary_is_closed()
	_test_deep_falls()
	_test_proof_scene()
	_test_corner_network()
	_test_families()
	_test_dual_end_to_end()
	_test_seams()
	_test_underfoot()
	_test_guide_image()
	_test_wireframe_joins()
	_test_plugin_rules()
	_test_plugin_manifest()
	_test_plugin_install()
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
	print("livraison : la case peinte est retenue, l autre ne sert pas")
	# Deux ilots portant le meme index 0 : deux variantes possibles du meme index.
	var mask: PackedStringArray = MaskIO.parse("#.#")
	var painted: Array[Vector2i] = [Vector2i(0, 0)]
	var resolved: Dictionary = Delivery.resolve(mask, painted)
	var expected_retained: Array[Vector2i] = [Vector2i(0, 0)]
	_check_equal(resolved["retained"][0], expected_retained, "seule la variante peinte est retenue")
	var expected_unused: Array[Vector2i] = [Vector2i(2, 0)]
	_check_equal(resolved["unused"], expected_unused, "la variante non peinte n est pas utilisee")
	_check_equal(resolved["delivered"], PackedInt32Array([0]), "l index 0 est livre")
	_check_equal(resolved["missing"].size(), BLOB_TILE_COUNT - 1, "les 46 autres index manquent")
	_check_equal(resolved["is_exportable"], false, "un seul index livre n est pas exportable")

	var nothing_painted: Array[Vector2i] = []
	var untouched: Dictionary = Delivery.resolve(mask, nothing_painted)
	_check(untouched["retained"].is_empty(), "sans peinture, aucune tuile n est retenue")
	_check_equal(untouched["unused"].size(), 2, "sans peinture, les deux cases restent inutilisees")

	# Peindre hors du guide est signale, jamais jete en silence.
	var outside_painted: Array[Vector2i] = [Vector2i(1, 0)]
	var outside_resolved: Dictionary = Delivery.resolve(mask, outside_painted)
	var expected_outside: Array[Vector2i] = [Vector2i(1, 0)]
	_check_equal(outside_resolved["outside"], expected_outside, "une case peinte hors du guide est signalee")

	# L ordre des cases fournies ne change pas le resultat.
	var both_orders: Array[Vector2i] = [Vector2i(2, 0), Vector2i(0, 0)]
	var reversed_resolved: Dictionary = Delivery.resolve(mask, both_orders)
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
	_check(Modes.is_available(Modes.AMPLE), "ample a son guide refait, il se choisit")
	_check_equal(Modes.label(Modes.MINIMAL), "Minimal", "libelle du mode minimal")
	_check_equal(Modes.surface_tile_count(Modes.MINIMAL), BLOB_TILE_COUNT, "47 tuiles de surface")
	_check_equal(Modes.wall_tile_count(Modes.MINIMAL), Walls.ALL_ROLES.size(), "12 tuiles de mur")
	_check_equal(Modes.tile_count(Modes.MINIMAL), BLOB_TILE_COUNT + Walls.ALL_ROLES.size(), "59 tuiles en tout")
	_check_equal(Modes.min_occurrences(Modes.MINIMAL), 1, "minimal ne promet qu une occurrence")
	_check_equal(Modes.min_occurrences(Modes.AMPLE), 3, "ample en promet trois")
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
	_check_equal(HeightMask.level_at(heights, -1, 0), HeightMask.VOID,
			"LE HORS-GRILLE EST DU VIDE, pas de la plaine : c est ce qui dit ou le sol s arrete")
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
	# UN ETAGE, PLATEAU ISOLE : les trois pans, mais le corps 1 reste hors d atteinte
	# A CET ETAGE-LA.
	# ⚠ Ce n est PAS une regle generale, et deux raisons y suffisent. Une robe raccourcie,
	# qui ne pose pas son pied, montre du corps sur sa derniere case. Et la PLAINE elle-meme
	# a sa falaise : au bord du monde elle tombe de trois cases sans jamais atterrir, donc
	# sa derniere case est du corps 1. On regarde donc l etage 1 seul.
	# La marge de vide est ce qui rend le bord du monde explicite : sans elle, la falaise
	# de la plaine tomberait hors du cadre.
	var one_storey: PackedStringArray = HeightMask.parse("~~~~~~~
~.....~
~.111.~
~.....~
~.....~
~.....~
~.....~
~~~~~~~
~~~~~~~
~~~~~~~")
	var shallow: Dictionary = Walls.analyse(one_storey)
	var roles: Dictionary = Walls.assemble(one_storey)["roles"]
	_check_equal(roles[Vector3i(2, 3, 1)], Vector2i(Walls.pan_of(Walls.SIDE_VOID, Walls.SIDE_MUTE), Walls.ROW_CROWN), "le bout gauche a le vide a l ouest")
	_check_equal(roles[Vector3i(3, 3, 1)], Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), Walls.ROW_CROWN), "le milieu est muet des deux cotes")
	_check_equal(roles[Vector3i(4, 5, 1)], Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_VOID), Walls.ROW_FOOT), "le bout droit a le vide a l est")
	var storey_one: Dictionary = {}
	for key: Vector3i in roles.keys():
		if key.z == 1:
			storey_one[roles[key]] = true
	_check(not storey_one.has(Vector2i(Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE), 2)), "ce plateau isole d un etage ne montre pas le corps 1")
	_check(shallow["outside"].is_empty(), "aucune robe ne tombe hors de la grille")

	# DEUX ETAGES : la chute de six cases fait apparaitre les douze roles.
	var two_storeys: PackedStringArray = HeightMask.parse(".....
.222.
.....
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
	# ⚠ UNE TUILE VUE UNE SEULE FOIS N A PAS DE JUMELLE : sa case est obligatoire, personne
	# d autre ne la portera, et l oublier bloque l export. On l affiche plutot que de
	# l asserter -- le compte depend du guide, et le figer interdirait de le retoucher.
	var lonely: int = 0
	for group: Array in Coverage.cells_by_index(Coverage.index_map(heights)).values():
		if group.size() == 1:
			lonely += 1
	for group: Array in Walls.cells_by_role(Walls.visible_roles(heights)).values():
		if group.size() == 1:
			lonely += 1
	print("  %d tuiles n ont AUCUNE variante : autant de cases obligatoires" % lonely)

	# Tout peindre livre les 47 index : c est la borne haute de ce que le guide permet.
	var every_cell: Array[Vector2i] = []
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			if Coverage.visible_index_at(heights, x, y) != Coverage.NO_INDEX:
				every_cell.append(Vector2i(x, y))
	var resolved: Dictionary = Delivery.resolve_relief(heights, every_cell)
	_check(resolved["is_exportable"], "guide complet entierement peint : exportable")
	_check_equal(resolved["delivered"].size(), BLOB_TILE_COUNT, "les 47 index sont livres")
	_check(resolved["unused"].is_empty(), "aucune case inutilisee quand tout est peint")

	# ⚠ LA PROMESSE DU MODE EST CHIFFREE, DONC ELLE SE PROUVE. `minimal` annonce 1 variante
	# minimum, `ample` en annonce 3 : c est toute la difference entre les deux, et elle
	# n a pas a etre crue sur parole.
	var promised: int = Modes.min_occurrences(id)
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
	var partial: Dictionary = Delivery.resolve_relief(heights, without)
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
	_check(rarest_role >= Modes.min_occurrences(id), "chaque role de mur est vu au moins %d fois (le plus rare : %d)" % [Modes.min_occurrences(id), rarest_role])
	print("  %d cases de robe deroulees" % wall_cells)
	_check_off_plain(id, heights)


## ⚠ TOUT DOIT SE TROUVER HORS DE LA PLAINE, ET LA PROMESSE DU MODE AUSSI.
##
## Dans l'editeur, l'etage 0 est du DECOR : il montre que le sol du jeu sortira du meme
## tileset, il recoit le temps reel par les jumelles, mais il ne prend pas le crayon -- et
## la grille ne se trace que sur ce qui se peint. Une tuile qui n'apparaitrait QUE sur la
## plaine serait donc impeignable, et le guide deviendrait inexportable **sans que rien ne
## le signale** : le rapport de couverture, lui, la compterait.
##
## Mesure au moment d'ecrire : sur les deux guides livres, les 47 index, les 15 croisements
## et les 36 roles se trouvent tous hors de la plaine, et `ample` y tient meme ses trois
## occurrences. C'est donc gratuit -- mais c'est gratuit AUJOURD'HUI, et un guide retouche
## demain pourrait poser un accident sur la plaine sans que personne y pense.
func _check_off_plain(id: StringName, heights: PackedStringArray) -> void:
	var promised: int = Modes.min_occurrences(id)

	for family: StringName in Families.ids():
		# ⚠ LA CARTE SE BATIT UNE FOIS. La relire par case refait un parcours complet du
		# relief a chaque tour : sur `ample` a cheval, la mesure passait de la seconde aux
		# minutes. Meme lecon que `CornerIndex.index_map`.
		var counts: Dictionary = {}
		var indices: Dictionary = Families.index_map(family, heights)
		for at: Vector2i in indices.keys():
			var top: int = HeightMask.level_at(heights, at.x, at.y)
			if family == Families.BY_CORNER:
				top = HeightMask.VOID
				for offset: Vector2i in CornerIndex.OFFSETS:
					top = maxi(top, HeightMask.level_at(heights, at.x + offset.x, at.y + offset.y))
			if top >= 1:
				var index: int = int(indices[at])
				counts[index] = int(counts.get(index, 0)) + 1
		var missing: Array[int] = []
		for index: int in Families.surface_indices(family):
			if int(counts.get(index, 0)) < promised:
				missing.append(index)
		_check_equal(missing, [] as Array[int],
				"%s : les %d tuiles de surface « %s » se trouvent %d fois HORS de la plaine"
				% [Modes.label(id), Families.surface_tile_count(family),
						Families.label(family), promised])

	var seen: Dictionary = Walls.visible(heights)
	var lips: Dictionary = seen["lips"]
	var roles: Dictionary = seen["roles"]
	var role_counts: Dictionary = {}
	for cell: Vector2i in roles.keys():
		if int(lips[cell]) >= 1:
			role_counts[roles[cell]] = int(role_counts.get(roles[cell], 0)) + 1
	var absent_roles: Array[Vector2i] = []
	for role: Vector2i in Walls.ALL_ROLES:
		if int(role_counts.get(role, 0)) < promised:
			absent_roles.append(role)
	_check_equal(absent_roles, [] as Array[Vector2i],
			"%s : les %d roles de robe descendent %d fois d'une levre qui n'est pas la plaine"
			% [Modes.label(id), Walls.ALL_ROLES.size(), promised])


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


func _test_wall_delivery() -> void:
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
	# Deux ilots isoles portent le meme index : ce sont les jumelles l une de l autre.
	# ⚠ LA CASE DU MILIEU N EST PAS VIDE, C EST DE LA PLAINE, et la plaine est un plateau
	# comme les autres : elle porte donc son propre index. Pour ne regarder que les ilots,
	# on met du VIDE entre eux.
	var flat: PackedStringArray = HeightMask.parse("#~#")
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
	_check(report["missing_surface"].is_empty(), "aucune surface manquante")
	_check(report["missing_wall"].is_empty(), "aucune robe manquante")

	var sheet: Image = TilesetPNG.compose(painting, heights, report, false)
	_check_equal(sheet.get_width(), TilesetPNG.SURFACE_COLUMNS * 16, "huit tuiles de large")
	_check_equal(sheet.get_height(), TilesetPNG.surface_rows() * 16, "six rangees de haut")
	var astray: int = 0
	for index: int in BlobIndex.CANONICAL_INDICES:
		var slot: Vector2i = TilesetPNG.surface_slot(index)
		if not sheet.get_pixel(slot.x * 16, slot.y * 16).is_equal_approx(
				_key_colour("S%d:0" % index)):
			astray += 1
	_check_equal(astray, 0, "les 47 index tombent chacun sur SA case de la planche")

	var kit: Image = TilesetPNG.compose(painting, heights, report, true)
	_check_equal(kit.get_width(), Walls.PAN_COUNT * 16, "la planche de robes fait trois pans")
	_check_equal(kit.get_height(), Walls.BLOCK_ROWS * 16, "et quatre rangees")
	var roles_astray: int = 0
	for role: Vector2i in Walls.ALL_ROLES:
		var at: Vector2i = TilesetPNG.wall_slot(role)
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
		var at: Vector2i = TilesetPNG.surface_slot(index)
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
		# ⚠ LE VIDE EST DANS LE CONTRAT, ET C'EST LA CLAUSE QUI PORTE LE PLUS. Un moteur
		# qui lirait « case absente = plaine » -- l'ancien modele -- etendrait le sol a
		# l'infini, ne poserait aucune falaise de bord du monde, et poserait des pieds au
		# fond du gouffre. Le tout SANS UNE SEULE ERREUR, ce qui est le pire des defauts.
		"void %d out_of_map_is_void" % HeightMask.VOID,
		"plain level_like_any_other",
		"fall_into_void one_storey_more no_foot",
		"canonicalise corner_needs_both_cardinals", "visible own_level",
		"faces south_only", "storey_tiles %d" % Walls.STOREY_TILES,
		"body_rows %d" % Walls.BODY_ROWS, "block_rows %d" % Walls.BLOCK_ROWS,
		"fall storey_tiles_times_gap probe_below_foot",
		"trim stop_on_same_level no_foot",
		"row_for crown_first foot_last body_cycle",
		"pan west_times_three_plus_east lip_row_comparison per_row",
		"bits N=%d" % BlobIndex.N,
		"surface_offset none",
		"sheet fixed_size one_drawing_per_tile no_variants",
		"underfoot foot_role redrawn_below under_landing_surface",
	]
	var absent: PackedStringArray = PackedStringArray()
	for clause: String in contract:
		if not manifest.contains(clause):
			absent.append(clause)
	_check_equal(absent, PackedStringArray(),
			"le manifeste porte la REGLE DE POSE en entier, pas seulement la table des cases")
	# ⚠ ET RIEN QUE LA SIENNE. Une planche par case decrite avec la regle du croisement
	# enoncerait une regle que ses tuiles n'emploient pas : le lecteur aurait le choix, donc
	# deux lecteurs auraient deux mondes.
	_check(not manifest.contains("corner_bits"),
			"et il ne decrit PAS la famille qu il n a pas exportee")
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
	_check_equal(TilesetPNG.compose(painting, heights, report, false).get_height(),
			TilesetPNG.surface_rows() * 16,
			"LA PLANCHE A UNE TAILLE FIXE : peindre les jumelles ne l'allonge pas")

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

	# ⚠ ET DEUX DESSINS DIFFERENTS SUR DEUX JUMELLES NE FONT PLUS DEUX TUILES. Le systeme
	# de variantes empilait alors une rangee de plus dans la planche ; il a ete retire, le
	# mot faisant deux metiers. La premiere occurrence peinte gagne, et la feuille garde
	# exactement la meme taille -- c'est ce qui rend le lecteur trivial.
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
		_check_equal(int(two["surface_source"][index]), 0,
				"un dessin different sur une jumelle ne change rien : la premiere gagne")
		_check_equal(TilesetPNG.compose(painting, heights, two, false).get_height(),
				TilesetPNG.surface_rows() * 16, "et la planche ne grandit pas d'une rangee")


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
			"les 32768 reliefs binaires 3x5 ne donnent que des roles des %d"
			% Walls.ALL_ROLES.size())

	# ⚠ ET LA BATTUE DOIT CONNAITRE LE VIDE. Un relief binaire n'a que deux etats -- plaine
	# et plateau -- alors que le monde en a TROIS depuis que le hors-monde se declare. Une
	# battue qui ne pose jamais de vide ne cherche pas dans tous les cas : elle ne verrait
	# jamais la falaise du bord du monde, ni une robe qui n'atterrit pas.
	var ternary_strays: int = 0
	for pattern: int in range(_TERNARY_RELIEFS):
		var relief: PackedStringArray = _ternary_relief(pattern, 3, 3)
		for role: Vector2i in Walls.visible_roles(relief).values():
			seen_roles[role] = true
			if not known.has(role):
				ternary_strays += 1
		for index: int in Coverage.index_map(relief).values():
			if not canonical.has(index):
				ternary_strays += 1
	_check_equal(ternary_strays, 0,
			"les %d reliefs 3x3 a TROIS etats -- vide, plaine, plateau -- ne donnent rien d autre"
			% _TERNARY_RELIEFS)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260821
	var wild: int = 0
	for _attempt: int in range(RANDOM_RELIEFS):
		var heights: PackedStringArray = _random_relief(rng, 8, 8, 3)
		# ⚠ LE MEME RELIEF, TROUE DE VIDE. C'est la ou le modele est le plus jeune : la robe
		# qui ne trouve rien sous elle, celle du bord du monde, et la plaine qui devient une
		# ile. On cherche aussi la.
		var holed: PackedStringArray = _with_void(rng, heights)
		for index: int in Coverage.index_map(holed).values():
			if not canonical.has(index):
				wild += 1
		for role: Vector2i in Walls.visible_roles(holed).values():
			seen_roles[role] = true
			if not known.has(role):
				wild += 1
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


## Le nombre de reliefs a trois etats passes en revue : 3 puissance 9.
##
## ⚠ EN 3x4 -- 531 441 reliefs -- LA SUITE PASSAIT DE UNE A SEPT MINUTES. Une suite qu'on
## n'ose plus lancer ne prouve plus rien. La battue exhaustive de la suite tient donc en
## 3x3 ; le 3x4 a ete passe UNE FOIS, hors suite : 531 441 reliefs, ZERO contre-exemple.
const _TERNARY_RELIEFS: int = 19683


## Un relief 3x4 a TROIS etats : vide, plaine, plateau. Un chiffre du motif par case.
func _ternary_relief(pattern: int, columns: int, rows_count: int) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	var left: int = pattern
	for _y: int in range(rows_count):
		var line: String = ""
		for _x: int in range(columns):
			var digit: int = left % 3
			left /= 3
			line += "~" if digit == 0 else ("." if digit == 1 else "1")
		rows.append(line)
	return rows


## Le meme relief, avec un peu de vide creuse dedans.
func _with_void(rng: RandomNumberGenerator, heights: PackedStringArray) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	for y: int in range(heights.size()):
		var line: String = ""
		for x: int in range(heights[y].length()):
			line += "~" if rng.randf() < 0.25 else heights[y][x]
		rows.append(line)
	return rows


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

	# ⚠ ET C EST VRAI DE TOUT MODE LIVRE, pas du seul `minimal`. Un mode dont le guide ne
	# couvre pas les quinze ne peut pas offrir la famille a cheval, donc il ne se choisit
	# pas (regle 5) : la couverture duale fait partie de ce qu un mode ouvert garantit.
	for id: StringName in Modes.ids():
		if not Modes.is_available(id):
			continue
		var other: Dictionary = CornerIndex.analyse_relief(
				HeightMask.read(Modes.guide_path(id)))
		var absent: PackedStringArray = PackedStringArray()
		for index: int in other["missing"]:
			absent.append("%d = %s" % [index, CornerIndex.describe(index)])
		_check(other["is_complete"], "%s couvre les quinze croisements%s" % [Modes.label(id),
				("  absents : " + ", ".join(absent)) if absent.size() > 0 else ""])
		var rarest: int = 1 << 30
		for index: int in other["present"]:
			rarest = mini(rarest, int(other["occurrences"][index]))
		_check(rarest >= Modes.min_occurrences(id),
				"%s : chaque croisement est vu au moins %d fois (le plus rare : %d)"
				% [Modes.label(id), Modes.min_occurrences(id), rarest])


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
		_check_wall_band(style[0], style[1], String(style[2]))
		_check_lip_seams(style[0], style[1], String(style[2]))


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


func _test_families() -> void:
	print("familles : les deux vocabulaires de surface, interchangeables")
	_check_equal(Families.ids().size(), 2, "deux familles au catalogue")
	_check_equal(Families.surface_tile_count(Families.BY_CELL), BLOB_TILE_COUNT,
			"par case : 47 tuiles")
	_check_equal(Families.surface_tile_count(Families.BY_CORNER), CornerIndex.TILE_COUNT,
			"a cheval : 15 tuiles")
	_check_equal(Families.key_letter(Families.BY_CELL), "S", "la surface par case s ecrit S")
	_check_equal(Families.key_letter(Families.BY_CORNER), "C", "le croisement s ecrit C")

	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	for family: StringName in Families.ids():
		_check(Families.is_covered(family, heights),
				"le guide minimal couvre la famille « %s »" % Families.label(family))

	# ⚠ LES DEUX CARNETS NE SE MELANGENT JAMAIS. Un croisement et une case sont tous deux des
	# Vector2i mais ne designent pas la meme chose : les melanger ferait se marcher dessus la
	# tuile du croisement (3,4) et la robe de la case (3,4).
	var cells: Dictionary = WorkIO.slots(heights)
	var points: Dictionary = WorkIO.corner_slots(heights)
	_check(points.size() > 0, "le reseau dual offre des croisements a peindre (%d)"
			% points.size())
	var mixed: int = 0
	for at: Vector2i in points.keys():
		if cells.has(at) and String(cells[at]).begins_with("S"):
			mixed += 1
	_check(mixed > 0,
			"les deux familles emploient bien les MEMES coordonnees (%d en commun)" % mixed)
	var clashes: int = 0
	for at: Vector2i in points.keys():
		if String(points[at]).begins_with("S") or String(points[at]).begins_with("W"):
			clashes += 1
	_check_equal(clashes, 0, "et pourtant aucune cle ne se confond : C d un cote, S et W de l autre")

	# L annuaire dans les deux sens, pour chaque famille.
	for family: StringName in Families.ids():
		var by_key: Dictionary = WorkIO.keys_of(heights, family)
		var letter: String = Families.key_letter(family)
		var first: String = "%s%d:0" % [letter, Families.surface_indices(family)[0]]
		_check(by_key.has(first),
				"« %s » : la premiere tuile a sa place (%s)" % [Families.label(family), first])

	# ⚠ UN CROISEMENT SE RANGE DANS LES Y NEGATIFS. C est ce qui permet UN SEUL carnet --
	# donc un seul historique d annulation, une seule taille de pixel, un seul fichier.
	# ⚠ UN CARNET « A CHEVAL » CONTIENT AUSSI LES ROBES, et elles restent sur les CASES : une
	# falaise sort du plan et se pose case pour case quel que soit le reseau du sol. Ce qui
	# doit etre disjoint, ce sont les SURFACES des deux familles.
	var dual: Dictionary = WorkIO.slots(heights, Families.BY_CORNER)
	var flat: Dictionary = WorkIO.slots(heights, Families.BY_CELL)
	var strayed: int = 0
	var surfaces: int = 0
	for at: Vector2i in dual.keys():
		if not String(dual[at]).begins_with("C"):
			continue
		surfaces += 1
		if at.y >= 0:
			strayed += 1
		if flat.has(at):
			strayed += 1
	_check_equal(surfaces, points.size(), "les %d croisements sont au carnet" % points.size())
	_check_equal(strayed, 0,
			"toute cle de croisement tombe dans les y negatifs, et n y rencontre aucune case")

	# Et l aller-retour complet d un travail « a cheval ».
	var corner_slots: Dictionary = WorkIO.slots(heights, Families.BY_CORNER)
	var painting: Painting = Painting.new(16)
	for at: Vector2i in corner_slots.keys():
		painting.paint(at, 0, 0, _key_colour(String(corner_slots[at])))
	var text: String = WorkIO.serialize(painting, heights, Modes.MINIMAL, Families.BY_CORNER)
	_check(text.contains("famille %s" % Families.BY_CORNER),
			"le fichier dit a quelle famille il appartient")
	var back: Dictionary = WorkIO.parse(text, heights)
	_check_equal(back["error"], OK, "un travail a cheval se relit sans erreur")
	_check_equal(back["family"], Families.BY_CORNER, "et il se relit dans SA famille")
	_check_equal(int(back["placed"]), corner_slots.size(),
			"les %d croisements sont reposes" % corner_slots.size())
	var reread: Painting = back["painting"]
	var astray: int = 0
	for at: Vector2i in corner_slots.keys():
		if not _pixel_is(reread, at, _key_colour(String(corner_slots[at]))):
			astray += 1
	_check_equal(astray, 0, "chaque croisement retrouve SA tuile, pixel pour pixel")


func _test_dual_end_to_end() -> void:
	print("a cheval : la planche de preuve, et l export de bout en bout")
	var family: StringName = Families.BY_CORNER

	# La planche de preuve des quinze. ⚠ ICI L ILOT EST LA TUILE : une tuile de croisement ne
	# depend QUE des quatre cases qu elle chevauche, il n y a pas de voisinage a mettre en
	# scene contrairement au blob.
	var relief: PackedStringArray = ProofScene.relief(family)
	var centres: Dictionary = ProofScene.centres(family)
	_check_equal(centres.size(), CornerIndex.TILE_COUNT, "un ilot par croisement, ni plus ni moins")
	var misplaced: Array[int] = []
	for index: int in centres.keys():
		var at: Vector2i = centres[index]
		if CornerIndex.visible_index_at(relief, at.x, at.y) != index:
			misplaced.append(index)
	_check_equal(misplaced, [] as Array[int],
			"les quinze ilots portent chacun SON croisement, a la case annoncee")
	_check(Families.is_covered(family, relief), "la planche couvre les quinze")
	_check(Walls.analyse(relief)["is_complete"], "et les 36 roles de falaise")
	_check_equal(Walls.analyse(relief)["outside"].size(), 0, "aucune robe hors du cadre")

	# L export complet, dans la famille duale.
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var by_cell: Dictionary = WorkIO.slots(heights, family)
	var painting: Painting = Painting.new(16)
	var firsts: Array[String] = []
	for at: Vector2i in by_cell.keys():
		if String(by_cell[at]).ends_with(":0"):
			firsts.append(String(by_cell[at]))
			painting.paint(at, 0, 0, _key_colour(String(by_cell[at])))
	_check_equal(firsts.size(), CornerIndex.TILE_COUNT + Walls.ALL_ROLES.size(),
			"a cheval, le guide porte 15 + 36 = %d tuiles obligatoires"
			% (CornerIndex.TILE_COUNT + Walls.ALL_ROLES.size()))

	var report: Dictionary = TilesetPNG.analyse(painting, heights, family)
	_check(report["is_exportable"], "une occurrence de chaque tuile suffit a exporter")
	var sheet: Image = TilesetPNG.compose(painting, heights, report, false)
	_check_equal(sheet.get_height(), TilesetPNG.surface_rows(family) * 16,
			"la planche des quinze tient en %d rangees" % TilesetPNG.surface_rows(family))
	var astray: int = 0
	for index: int in Families.surface_indices(family):
		var slot: Vector2i = TilesetPNG.surface_slot(index, family)
		if not sheet.get_pixel(slot.x * 16, slot.y * 16).is_equal_approx(
				_key_colour("C%d:0" % index)):
			astray += 1
	_check_equal(astray, 0, "les quinze croisements tombent chacun sur SA case de la planche")

	var folder: String = "user://export_dual"
	var done: Dictionary = TilesetPNG.write(folder, "dual", painting, heights, Modes.MINIMAL,
			family)
	_check_equal(done["error"], OK, "la feuille a cheval s ecrit")
	var written: PackedStringArray = done["written"]
	_check_equal(written.size(), 4, "deux planches, la preuve, et le manifeste")
	var manifest: String = FileAccess.get_file_as_string(folder.path_join("dual_tileset.txt"))
	_check(manifest.contains("famille %s" % family),
			"le manifeste dit de quelle famille est la planche")

	# ⚠ ET IL EN PORTE LA REGLE DE POSE, PAS SEULEMENT LE NOM. C'etait le trou : un export
	# a cheval annoncait sa famille et ses quinze index au-dessus d'une regle qui ne
	# decrivait que le blob. Ni les bits du croisement, ni les quatre cases qu'il touche, ni
	# le decalage d'une demi-case n'etaient ecrits nulle part -- notre plugin les connait de
	# memoire, c'est-a-dire exactement la dependance que le contrat existe pour supprimer.
	var bits: PackedStringArray = PackedStringArray()
	var cells: PackedStringArray = PackedStringArray()
	for bit: int in range(CornerIndex.BITS.size()):
		var at: Vector2i = CornerIndex.OFFSETS[bit]
		bits.append("%s=%d" % [CornerIndex.BIT_NAMES[bit], CornerIndex.BITS[bit]])
		cells.append("%s=%d,%d" % [CornerIndex.BIT_NAMES[bit], at.x, at.y])
	var dual_contract: Array[String] = [
		"levels silhouette_per_level", "draw_order bottom_up",
		"void %d out_of_map_is_void" % HeightMask.VOID,
		"plain level_like_any_other",
		"fall_into_void one_storey_more no_foot",
		"corner_bits %s" % " ".join(bits),
		"corner_cells %s" % " ".join(cells),
		"corner_visible top_of_four bits_reaching_top",
		"corner_empty draws_nothing",
		"surface_offset minus_half_tile whole_layer",
		# LES ROBES NE CHANGENT PAS DE FAMILLE : leur regle doit etre la, entiere, et sur
		# la grille des cases.
		"walls_offset none", "faces south_only",
		"fall storey_tiles_times_gap probe_below_foot",
		"trim stop_on_same_level no_foot",
		"row_for crown_first foot_last body_cycle",
		"pan west_times_three_plus_east lip_row_comparison per_row",
		"sheet fixed_size one_drawing_per_tile no_variants",
	]
	var missing_clauses: PackedStringArray = PackedStringArray()
	for clause: String in dual_contract:
		if not manifest.contains(clause):
			missing_clauses.append(clause)
	_check_equal(missing_clauses, PackedStringArray(),
			"le manifeste a cheval porte SA regle de pose en entier")
	# ⚠ ET IL NE PORTE PAS CELLE DU BLOB. Un croisement ne se canonicalise pas : ses quatre
	# bits sont tous significatifs, et le contact diagonal -- que le blob JETTE -- est
	# precisement une de ses quinze tuiles. Laisser la regle du blob a cote serait pire
	# qu'un oubli : ce serait une regle fausse ecrite noir sur blanc.
	_check(not manifest.contains("canonicalise corner_needs_both_cardinals"),
			"et surtout PAS la canonicalisation du blob, qui n a pas cours ici")
	_check(not manifest.contains("bits N=%d" % BlobIndex.N),
			"ni le voisinage a huit bits d une famille qu il n exporte pas")
	for path: String in written:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## ⚠ CE QU'ON MESURE ICI EST UN PIXEL, PAS UNE INTENTION. Le defaut se voyait a l'ecran et
## nulle part ailleurs : une case d'atterrissage isolee -- une banquette au pied d'un
## contrefort -- montrait le SOL par ses coins nord decoupes, alors que la face de la
## falaise continue derriere. On lit donc le coin, et on exige de la roche.
func _test_underfoot() -> void:
	print("le sous-pied : la roche continue derriere les coins decoupes")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var under: Dictionary = Walls.visible_underfoot(heights)
	_check(under.size() > 0, "le guide pose des sous-pieds (%d)" % under.size())

	# Une case d'atterrissage ISOLEE : ses quatre coins sont decoupes, donc le defaut s'y voit.
	var target: Vector2i = Vector2i(-1, -1)
	for cell: Vector2i in under.keys():
		if HeightMask.level_at(heights, cell.x, cell.y) >= 1 \
				and Coverage.visible_index_at(heights, cell.x, cell.y) == 0:
			target = cell
			break
	_check(target.x >= 0, "et le guide en offre une isolee, ou le defaut se voyait")
	if target.x < 0:
		return

	var side: int = 32
	var image: Image = GuideImage.render(heights, side, GuideImage.Ink.PAINTED,
			GuideImage.Purpose.REPRESENTATIVE, false)
	var corner: Color = image.get_pixel(target.x * side + 1, target.y * side + 1)
	var middle: Color = image.get_pixel(target.x * side + side / 2, target.y * side + side / 2)
	# La roche est chaude, l'herbe est verte. On les distingue sans les nommer.
	_check(corner.r > corner.g,
			"LE COIN NORD-OUEST EST DE LA ROCHE : la falaise continue derriere")
	_check(middle.g > middle.r, "et le milieu de la case est bien de l herbe")

	# ⚠ ET LE SOUS-PIED N'AJOUTE AUCUNE TUILE. C'est le PIED, repose une case plus bas :
	# tout role de sous-pied est donc l'un des 36, et c'est toujours un PIED. S'il en
	# reclamait un autre, il faudrait le peindre -- et il n'y aurait aucune case du guide
	# pour le porter, puisque la case d'atterrissage est deja une case de surface.
	var known: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		known[role] = true
	var strays: int = 0
	var not_feet: int = 0
	for role: Vector2i in under.values():
		if not known.has(role):
			strays += 1
		if role.y != Walls.ROW_FOOT:
			not_feet += 1
	_check_equal(strays, 0, "AUCUNE TUILE DE PLUS : tout sous-pied est l un des %d roles"
			% Walls.ALL_ROLES.size())
	_check_equal(not_feet, 0, "et c est toujours un PIED : la meme face, une case plus bas")


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
	# ⚠ LA PLAINE SE DESSINE, ET C'EST NOUVEAU. Elle est un plateau comme les autres : elle
	# a sa silhouette, ses 47 index et ses falaises au bord du monde. Ce qui ne se dessine
	# pas, c'est le VIDE -- et lui seul.
	_check(plain.a > 0.9, "la plaine se dessine : c'est un plateau comme les autres")
	_check(plain != summit, "mais elle ne se confond pas avec un sommet : l'altitude se lit")
	var nothing: Color = GuideImage.render(HeightMask.parse("~~~
~~~
~~~")).get_pixel(
			GuideImage.TILE + half, GuideImage.TILE + half)
	_check_equal(nothing.a, 0.0, "LE VIDE, LUI, NE SE DESSINE PAS : le monde s'arrete la")
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
	# ⚠ « CHARGE » NE VEUT PAS DIRE « COMPILE ». Un script dont l analyse echoue rend malgre
	# tout une ressource -- vide de ses fonctions. Le test disait alors « aucun script en
	# erreur » pendant que la suite perdait quinze verifications en silence, les appels
	# tombant sur des fonctions inexistantes. `can_instantiate()` tranche, lui.
	# ⚠ ET ON NE RELIT PAS HORS CACHE : recharger un script en cours d usage fait planter le
	# moteur, pile de C++ a l appui.
	var broken: PackedStringArray = PackedStringArray()
	for path: String in scripts:
		var script: GDScript = ResourceLoader.load(path, "Script") as GDScript
		if script == null or not script.can_instantiate():
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


# --- AbsoluPaint : le plugin moteur ------------------------------------------

## ⚠ LE PLUGIN PORTE UNE COPIE DE LA REGLE, ET C'EST INEVITABLE : il part chez l acheteur,
## dans SON projet, ou `res://core/` n existe pas. La question n est donc pas « comment
## eviter la copie » mais « comment prouver que les deux disent la meme chose ». Ce test est
## la reponse, et c est le seul endroit du depot ou elle existe.
##
## ⚠ ON COMPARE LES TROIS VOCABULAIRES, PAS UN SEUL. Une divergence sur les robes ne se
## verrait jamais en ne comparant que les index de surface -- et c est justement la que la
## regle est la plus subtile, puisque le pan depend de la levre du voisin.
func _test_plugin_rules() -> void:
	print("AbsoluPaint : la regle du plugin est CELLE DU NOYAU, case pour case")

	_check_equal(PluginRules.STOREY_TILES, Walls.STOREY_TILES, "meme hauteur d etage")
	_check_equal(PluginRules.BODY_ROWS, Walls.BODY_ROWS, "meme nombre de rangees de corps")
	_check_equal(PluginRules.PAN_COUNT, Walls.PAN_COUNT, "meme nombre de pans")
	_check_equal(PluginRules.BLOCK_ROWS, Walls.BLOCK_ROWS, "meme nombre de rangees de bloc")

	# Les 256 voisinages bruts : la canonicalisation doit tomber au meme endroit, toujours.
	var canon_strays: int = 0
	for raw: int in range(256):
		if PluginRules.canonicalise(raw) != BlobIndex.canonicalize(raw):
			canon_strays += 1
	_check_equal(canon_strays, 0, "les 256 voisinages bruts se canonicalisent pareil")

	# EXHAUSTIF sur les reliefs binaires 3x4 : 4096 mondes, aucun tirage au sort.
	var seen_surface: Dictionary = {}
	var seen_roles: Dictionary = {}
	var seen_corners: Dictionary = {}
	var drift: int = 0
	for pattern: int in range(1 << 12):
		drift += _plugin_drift(_relief_of(pattern, 3, 4), seen_surface, seen_roles, seen_corners)
	_check_equal(drift, 0, "les 4096 reliefs binaires 3x4 : le plugin et le noyau ne divergent jamais")

	# ⚠ ET SUR LES RELIEFS REELS, CEUX QUI PARTENT CHEZ L ACHETEUR. Le tirage au sort ne
	# rencontre pas les 36 roles : les plus rares demandent un contrefort, c est-a-dire une
	# forme voulue, pas un accident. Les guides livres les portent tous par construction --
	# ce sont donc eux, et pas le hasard, qui font de cette battue une vraie battue.
	var real: Array[String] = []
	for mode_id: StringName in Modes.ids():
		real.append(Modes.guide_path(mode_id))
	real.append("res://guides/preview.txt")
	var on_guides: int = 0
	for path: String in real:
		on_guides += _plugin_drift(HeightMask.read(path), seen_surface, seen_roles, seen_corners)
	on_guides += _plugin_drift(ProofScene.relief(), seen_surface, seen_roles, seen_corners)
	_check_equal(on_guides, 0,
			"sur les guides livres et la planche de preuve : aucune divergence")

	# ET AU HASARD, sur du relief a etages -- c est la que les robes se compliquent.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260822
	var wild: int = 0
	for _attempt: int in range(PLUGIN_RANDOM_RELIEFS):
		wild += _plugin_drift(_random_relief(rng, 9, 9, 3), seen_surface, seen_roles, seen_corners)
	_check_equal(wild, 0, "%d reliefs 9x9 sur quatre etages, tires au sort : aucune divergence"
			% PLUGIN_RANDOM_RELIEFS)

	# ⚠ ET LA BATTUE DOIT AVOIR VRAIMENT CHERCHE. Une comparaison qui ne rencontre aucune
	# robe ne prouve pas que les robes s accordent : elle prouve qu elle n en a pas vu.
	_check_equal(seen_roles.size(), Walls.ALL_ROLES.size(),
			"la battue a rencontre les %d roles de robe" % Walls.ALL_ROLES.size())
	_check_equal(seen_surface.size(), BLOB_TILE_COUNT,
			"et les %d index de surface" % BLOB_TILE_COUNT)
	_check_equal(seen_corners.size(), CornerIndex.TILE_COUNT,
			"et les %d croisements" % CornerIndex.TILE_COUNT)


## Compte les cases ou le plugin et le noyau ne disent pas la meme chose.
## Rend 0 quand tout s accorde, et note au passage ce qui a ete rencontre.
func _plugin_drift(heights: PackedStringArray, seen_surface: Dictionary,
		seen_roles: Dictionary, seen_corners: Dictionary) -> int:
	var world: Dictionary = _plugin_world(heights)
	var apart: int = 0

	var mine: Dictionary = Coverage.index_map(heights)
	var theirs: Dictionary = PluginRules.surfaces(world)
	apart += _compare_maps(mine, theirs, seen_surface)

	var my_corners: Dictionary = CornerIndex.index_map(heights)
	var their_corners: Dictionary = PluginRules.corners(world)
	apart += _compare_maps(my_corners, their_corners, seen_corners)

	var my_walls: Dictionary = Walls.visible_roles(heights)
	var their_walls: Dictionary = PluginRules.walls(world)
	apart += _compare_maps(my_walls, their_walls, seen_roles)

	return apart


## Deux cartes case -> tuile, comparees dans les DEUX sens.
##
## ⚠ COMPARER DANS UN SEUL SENS NE PROUVE RIEN. Un plugin qui ne poserait rien du tout
## passerait un test qui se contente de verifier que ce qu il pose est juste.
func _compare_maps(mine: Dictionary, theirs: Dictionary, seen: Dictionary) -> int:
	var apart: int = 0
	for at: Vector2i in mine.keys():
		seen[mine[at]] = true
		if not theirs.has(at) or theirs[at] != mine[at]:
			apart += 1
	for at: Vector2i in theirs.keys():
		if not mine.has(at):
			apart += 1
	return apart


## Le relief du noyau, traduit dans la forme que le plugin attend : case -> etage.
##
## ⚠ LA PLAINE EST UNE CASE DU MONDE, ELLE AUSSI. Ce qui est absent du dictionnaire n'est
## plus « de la plaine » mais du VIDE -- c'est l'inversion qui donne son sol au monde. Ne
## porter ici que les plateaux reviendrait a dire au plugin que tout le reste est hors-monde,
## et les deux lecteurs divergeraient des la premiere case plate.
func _plugin_world(heights: PackedStringArray) -> Dictionary:
	var world: Dictionary = {}
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			var level: int = HeightMask.level_at(heights, x, y)
			if level >= 0:
				world[Vector2i(x, y)] = level
	return world


## Le lecteur de manifeste, eprouve sur un VRAI export -- pas sur une chaine ecrite a la main.
func _test_plugin_manifest() -> void:
	print("AbsoluPaint : le manifeste se relit, et le faux se refuse")
	var folder: String = "user://plugin_manifeste"
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var by_key: Dictionary = WorkIO.cells_by_key(heights)
	var painting: Painting = Painting.new(16)
	for key: String in by_key.keys():
		if key.ends_with(":0"):
			painting.paint(by_key[key], 0, 0, _key_colour(key))
	var done: Dictionary = TilesetPNG.write(folder, "essai", painting, heights, Modes.MINIMAL)
	_check_equal(done["error"], OK, "un export complet pour eprouver le lecteur")

	var report: Dictionary = PluginManifest.read(folder.path_join("essai_tileset.txt"))
	_check_equal(report["error"], OK, "le manifeste se lit sans reproche")
	_check_equal(int(report["tile_size"]), 16, "la taille de tuile est relue")
	_check_equal(report["family"], PluginManifest.BY_CELL, "la famille est relue")
	_check_equal(report["surface_slots"].size(), BLOB_TILE_COUNT, "les 47 cases de surface")
	_check_equal(report["wall_slots"].size(), Walls.ALL_ROLES.size(),
			"les %d cases de robe" % Walls.ALL_ROLES.size())
	_check(PluginManifest.is_complete(report), "et le manifeste se sait complet")

	# ⚠ LA TABLE DOIT DIRE LA MEME CHOSE QUE L EXPORTATEUR. Le plugin lit ce qui est ecrit ;
	# si l ecrit ne correspondait pas a ce que la planche contient, le monde sortirait
	# decale d une case sans qu une seule erreur ne soit levee.
	var misplaced: int = 0
	for index: int in report["surface_slots"].keys():
		if report["surface_slots"][index] != TilesetPNG.surface_slot(index):
			misplaced += 1
	for role: Vector2i in report["wall_slots"].keys():
		if report["wall_slots"][role] != TilesetPNG.wall_slot(role):
			misplaced += 1
	_check_equal(misplaced, 0, "chaque case relue est celle ou l exportateur a pose la tuile")

	# LE TILESET GODOT, fabrique depuis ce manifeste et ces deux planches.
	var built: Dictionary = PluginTileSet.build(folder, report)
	_check_equal(built["error"], OK, "le TileSet se fabrique depuis les planches ecrites")
	var tile_set: TileSet = built["tile_set"]
	_check(tile_set != null and tile_set.tile_size == Vector2i(16, 16),
			"il porte la taille de tuile du manifeste")
	if tile_set != null:
		var surface: TileSetAtlasSource = tile_set.get_source(int(built["surface_source"])) as TileSetAtlasSource
		var walls: TileSetAtlasSource = tile_set.get_source(int(built["walls_source"])) as TileSetAtlasSource
		_check_equal(surface.get_tiles_count(), BLOB_TILE_COUNT,
				"47 tuiles creees, pas la grille entiere : la 48e case reste vide")
		_check_equal(walls.get_tiles_count(), Walls.ALL_ROLES.size(),
				"et les %d robes" % Walls.ALL_ROLES.size())

	# LES REFUS (charte, regle 5).
	_check(int(PluginManifest.parse("n importe quoi\n")["error"]) != OK,
			"un fichier qui ne s annonce pas est refuse")
	var future: String = "%s %d\n" % [PluginManifest.MAGIC, PluginManifest.READS_UP_TO + 1]
	_check(int(PluginManifest.parse(future)["error"]) != OK,
			"une version plus recente est refusee, pas devinee")
	# ⚠ ET LE TROP VIEUX AUSSI, pour exactement la meme raison. Ce refus-la manquait,
	# et son absence a laisse passer un vrai defaut : entre deux livraisons, le
	# hors-carte est passe de la plaine au VIDE et le sous-pied est apparu, SANS que la
	# version bouge. Un manifeste v3 d'avant et un v3 d'apres decrivaient deux mondes
	# differents, et le plugin les posait tous les deux. Un garde-fou qui ne regarde
	# que d'un cote ne garde rien.
	var ancient: String = "%s %d\n" % [PluginManifest.MAGIC, PluginManifest.READS_FROM - 1]
	_check(int(PluginManifest.parse(ancient)["error"]) != OK,
			"UNE VERSION TROP VIEILLE EST REFUSEE : son sens a change sous elle")
	_check_equal(PluginManifest.READS_UP_TO, TilesetPNG.VERSION,
			"et le plugin lit exactement ce que l exportateur ecrit")
	var wrong: String = FileAccess.get_file_as_string(folder.path_join("essai_tileset.txt")) 			.replace("storey_tiles 3", "storey_tiles 4")
	_check(int(PluginManifest.parse(wrong)["error"]) != OK,
			"un etage qui ne descend pas de trois cases est REFUSE : le poser mentirait")


## L installateur : le bouton destine a l acheteur.
func _test_plugin_install() -> void:
	print("AbsoluPaint : l installation chez l acheteur")

	# ⚠ LA LISTE DES FICHIERS EST UNE DONNEE, DONC UN ENDROIT OU MENTIR. On la compare au
	# dossier reel : un fichier ajoute au plugin et oublie dans la liste ne partirait jamais
	# chez l acheteur, et le plugin arriverait casse sans que rien ne le dise.
	var on_disk: PackedStringArray = PackedStringArray()
	var directory: DirAccess = DirAccess.open(PluginInstall.SOURCE)
	if directory != null:
		directory.list_dir_begin()
		var entry: String = directory.get_next()
		while entry != "":
			if not directory.current_is_dir() and not entry.ends_with(".uid"):
				on_disk.append(entry)
			entry = directory.get_next()
		directory.list_dir_end()
	on_disk.sort()
	var declared: PackedStringArray = PackedStringArray(PluginInstall.FILES)
	declared.sort()
	_check_equal(on_disk, declared, "la liste des fichiers du plugin dit vrai")

	# LE REFUS : un dossier qui n est pas un projet Godot.
	var plain: String = "user://pas_un_projet"
	DirAccess.make_dir_recursive_absolute(plain)
	var refused: Dictionary = PluginInstall.install(plain)
	_check_equal(refused["error"], ERR_UNAVAILABLE, "un dossier sans project.godot est REFUSE")
	_check(not bool(refused["is_project"]), "et il se sait hors sujet")
	_check(PackedStringArray(refused["written"]).is_empty(), "et rien n est ecrit du tout")
	_check(String(refused["reason"]) != "", "le refus dit pourquoi, en clair")

	# L INSTALLATION dans un vrai projet.
	# ⚠ `user://` SURVIT D UNE EXECUTION A L AUTRE. Sans effacement, la seconde execution
	# trouvait le plugin deja pose et « la premiere fois » n etait plus la premiere : le test
	# passait au vert le jour de son ecriture et rougissait le lendemain.
	var project: String = "user://faux_projet"
	_erase_tree(project)
	DirAccess.make_dir_recursive_absolute(project)
	var stub: FileAccess = FileAccess.open(project.path_join("project.godot"), FileAccess.WRITE)
	stub.store_string("config_version=5\n")
	stub.close()

	var first: Dictionary = PluginInstall.install(project)
	_check_equal(first["error"], OK, "le plugin s installe dans un projet Godot")
	_check(not bool(first["replaces"]), "la premiere fois, il ne remplace rien")
	_check_equal(PackedStringArray(first["written"]).size(), PluginInstall.FILES.size(),
			"tous les fichiers sont ecrits")

	# ⚠ OCTET POUR OCTET. Un `.gd` relu comme texte puis reecrit changerait ses fins de ligne
	# selon la plateforme : le plugin doit arriver identique a celui qu on vient de tester.
	var altered: int = 0
	for file_name: String in PluginInstall.FILES:
		var here: PackedByteArray = FileAccess.get_file_as_bytes(
				PluginInstall.SOURCE.path_join(file_name))
		var there: PackedByteArray = FileAccess.get_file_as_bytes(
				project.path_join(PluginInstall.TARGET).path_join(file_name))
		if here != there or here.is_empty():
			altered += 1
	_check_equal(altered, 0, "chaque fichier arrive identique, octet pour octet")

	# ⚠ ET LE `project.godot` DE L ACHETEUR N EST PAS TOUCHE. Le reecrire pour cocher
	# l extension lui ferait perdre ses commentaires, et peut-etre bien pire.
	_check_equal(FileAccess.get_file_as_string(project.path_join("project.godot")),
			"config_version=5\n", "le project.godot de l acheteur reste intact")

	var again: Dictionary = PluginInstall.install(project)
	_check_equal(again["error"], OK, "reinstaller par-dessus fonctionne")
	_check(bool(again["replaces"]), "et la seconde fois, il se sait remplacant")
	_check(PluginInstall.summary(again).contains("Extensions"),
			"le resume dit la seule chose qui reste a faire")



## Efface un dossier et ce qu il contient. Sert a rendre un test reproductible : `user://`
## garde ce qu on y ecrit, donc un test qui ecrit doit d abord faire le vide.
func _erase_tree(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		var child: String = path.path_join(entry)
		if directory.current_is_dir():
			_erase_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)

## LES CHUTES PROFONDES — une falaise de vingt-sept cases avec les memes trente-six tuiles.
##
## ⚠ CE TEST COMBLE UN TROU QU ON A VU EN REGARDANT, PAS EN LISANT. Les reliefs tires au
## sort plafonnent a quatre etages, donc a des chutes de neuf ; le guide minimal monte a
## trois. Les longueurs 12 a 27 n etaient eprouvees NULLE PART. Elles passaient -- mais par
## chance, et rien ne l aurait garanti demain.
##
## ⚠ C EST LA PROMESSE MEME DES DEUX RANGEES DE CORPS : `1 + (step - 2) modulo body_rows`
## fait tourner le corps sur lui-meme, ce qui permet une hauteur quelconque avec une feuille
## FINIE. Si cette assertion tombe, c est que la feuille a cesse d etre suffisante.
func _test_deep_falls() -> void:
	print("chutes profondes : n importe quel multiple de trois, avec la meme feuille")
	var known: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		known[role] = true

	var lengths: Array[int] = []
	var strays: int = 0
	var drift: int = 0
	var unfooted: int = 0
	var body_one_seen: int = 0

	for level: int in range(1, HeightMask.MAX_LEVEL + 1):
		# Un plateau de cet etage, et assez de plaine dessous pour qu il atterrisse.
		var relief: PackedStringArray = PackedStringArray()
		for _top: int in range(3):
			relief.append(str(level).repeat(7))
		for _below: int in range(Walls.STOREY_TILES * HeightMask.MAX_LEVEL + 4):
			relief.append(".".repeat(7))

		var fall: Vector2i = Walls.fall_at(relief, level, Vector2i(3, 2))
		lengths.append(fall.x)
		if fall.y != 1:
			unfooted += 1

		var roles: Dictionary = Walls.visible_roles(relief)
		for role: Vector2i in roles.values():
			if not known.has(role):
				strays += 1
		# ⚠ ON NE COMPTE LE CORPS 1 QUE SUR LA CHUTE DE CET ETAGE. La PLAINE a elle aussi
		# sa falaise -- au bord du monde elle tombe de trois cases sans jamais atterrir, donc
		# sa derniere case est du corps 1. La compter ici dirait « le corps 1 des l etage 1 »
		# alors que le fait mesure est plus etroit : une chute QUI ATTERRIT de trois cases ne
		# le montre pas.
		var rows_used: Dictionary = {}
		for key: Vector3i in Walls.assemble(relief)["roles"].keys():
			if key.z == level:
				rows_used[(Walls.assemble(relief)["roles"][key] as Vector2i).y] = true
		if rows_used.has(2):
			body_one_seen += 1

		# ⚠ ET LE PLUGIN DOIT SUIVRE JUSQU EN BAS. C est la ou une copie de la regle derive
		# en premier : le corps qui tourne est la seule partie recursive du vocabulaire.
		var theirs: Dictionary = PluginRules.walls(_plugin_world(relief))
		for cell: Vector2i in roles.keys():
			if not theirs.has(cell) or theirs[cell] != roles[cell]:
				drift += 1
		for cell: Vector2i in theirs.keys():
			if not roles.has(cell):
				drift += 1

	var expected: Array[int] = []
	for level: int in range(1, HeightMask.MAX_LEVEL + 1):
		expected.append(Walls.STOREY_TILES * level)
	print("  chutes obtenues : %s" % str(lengths))
	_check_equal(lengths, expected,
			"chaque etage tombe de %d x son niveau, jusqu a %d cases"
			% [Walls.STOREY_TILES, Walls.STOREY_TILES * HeightMask.MAX_LEVEL])
	_check_equal(unfooted, 0, "et toutes posent leur pied : elles atterrissent vraiment")
	_check_equal(strays, 0,
			"aucune de ces chutes ne reclame un role hors des %d" % Walls.ALL_ROLES.size())
	# ⚠ ON NE COMPTE QUE LES CHUTES QUI ATTERRISSENT. La falaise du bord du monde, elle,
	# ne pose pas son pied : sa troisieme case est du corps 1, et elle apparait des l etage 1.
	# Le fait mesure ici est plus etroit : une chute QUI ATTERRIT de trois cases ne montre
	# pas le corps 1.
	_check_equal(body_one_seen, HeightMask.MAX_LEVEL - 1,
			"le corps 1 apparait des deux etages, et pas avant : une chute de trois ne le voit pas")
	_check_equal(drift, 0, "le plugin dit la meme chose jusqu a la chute de %d cases"
			% (Walls.STOREY_TILES * HeightMask.MAX_LEVEL))

	# ⚠ ET L AUTRE REGIME : UNE ROBE ECRETEE FAIT N IMPORTE QUELLE LONGUEUR, mais elle ne
	# pose PAS son pied. Atterrir est quantifie par trois ; descendre ne l est pas.
	var pinched: PackedStringArray = PackedStringArray([
		"22222",
		".....",
		".....",
		"22222",
	])
	var short: Vector2i = Walls.fall_at(pinched, 2, Vector2i(2, 0))
	_check_equal(short.x, 2, "butee contre son propre etage : la robe fait deux cases")
	_check(short.y != 1, "et elle ne pose pas son pied : elle ne touche pas le sol d en bas")
	# ⚠ ON REGARDE LES CASES DE CETTE ROBE-LA, PAS LE RELIEF ENTIER. Le SECOND bloc de
	# niveau 2 lance sa propre robe, qui elle atterrit et pose son pied : asserter sur tout
	# le relief accusait la regle d un defaut qu elle n a pas. Le test avait tort, pas le code.
	var pinched_roles: Dictionary = Walls.visible_roles(pinched)
	var footed: int = 0
	for step: int in range(1, short.x + 1):
		var at: Vector2i = Vector2i(2, step)
		if pinched_roles.has(at) and Vector2i(pinched_roles[at]).y == Walls.ROW_FOOT:
			footed += 1
	_check_equal(footed, 0, "et aucune de ses cases n est un pied : le dessin se tait")

## LA BANDE DE FLANC NE BOUGE PAS QUAND LE PAN CHANGE DANS UNE COLONNE.
##
## ⚠ TROU TROUVE EN RELISANT `_check_wall_seams` : elle compare bien deux rangees qui se
## suivent, mais toujours A PAN CONSTANT. Or L ETAT D UN FLANC CHANGE EN DESCENDANT -- le
## voisin est en retrait sur trois rangees, puis sa robe s arrete et le flanc passe de
## `devant` a `vide`. Les deux dessinent une bande AU MEME BORD : si elles n ont pas la meme
## geometrie, la marque saute lateralement EN PLEIN MILIEU de la falaise.
##
## Ce defaut a deja eu lieu : le lisere du vide faisait 0,10 de tuile et l arete 0,055, et
## « la bande passait de large a etroite en cours de colonne, elle pulsait ». La correction
## fut une largeur unique, la TEINTE portant la difference. C etait une convention du rendu ;
## c est desormais une assertion.
##
## ⚠ ON COMPARE LA GEOMETRIE, PAS LES PIXELS. Le vide est doux et l arete est franche : leurs
## couleurs DOIVENT differer, c est ce qui dit lequel des deux blocs est devant. Ce qui ne
## doit pas differer, c est OU la bande se trouve.
func _check_wall_band(ink: GuideImage.Ink, marks: bool, label: String) -> void:
	var mute_pan: int = Walls.pan_of(Walls.SIDE_MUTE, Walls.SIDE_MUTE)
	var by_state: Dictionary = {}
	var mute_strays: int = 0

	for row: int in range(Walls.BLOCK_ROWS):
		var base: Image = GuideImage.make_wall(Vector2i(mute_pan, row), SEAM_TILE, ink, marks)
		for pan: int in range(Walls.PAN_COUNT):
			var tile: Image = GuideImage.make_wall(Vector2i(pan, row), SEAM_TILE, ink, marks)
			for west: bool in [true, false]:
				var state: int = Walls.pan_west(pan) if west else Walls.pan_east(pan)
				var extent: PackedInt32Array = _band_extent(tile, base, west)
				if state == Walls.SIDE_MUTE:
					mute_strays += extent.size()
					continue
				var key: String = "%s|%s" % ["ouest" if west else "est", Walls.SIDE_NAMES[state]]
				if not by_state.has(key):
					by_state[key] = extent
				elif PackedInt32Array(by_state[key]) != extent:
					by_state[key] = PackedInt32Array([-1])  # marque une divergence

	_check_equal(mute_strays, 0,
			"%s : un flanc MUET ne trace rien -- ni bande, ni lisere" % label)

	for side: String in ["ouest", "est"]:
		var empty_side: PackedInt32Array = PackedInt32Array()
		var void_band: PackedInt32Array = by_state.get("%s|vide" % side, empty_side)
		var front_band: PackedInt32Array = by_state.get("%s|devant" % side, empty_side)
		_check_equal(void_band, front_band,
				"%s : flanc %s -- le vide et l arete occupent EXACTEMENT les memes colonnes"
				% [label, side])
		# ⚠ ET LA MESURE DOIT AVOIR VU QUELQUE CHOSE. Deux bandes vides sont trivialement
		# egales : sans ce controle, un rendu qui cesserait de tracer la bande passerait.
		if ink == GuideImage.Ink.PAINTED:
			_check(void_band.size() > 0 and void_band[0] != -1,
					"%s : flanc %s -- et la bande existe vraiment (%d colonnes, stable sur les %d rangees)"
					% [label, side, void_band.size(), Walls.BLOCK_ROWS])


## Les colonnes d une moitie de tuile qui different de la tuile sans flanc.
func _band_extent(tile: Image, base: Image, west: bool) -> PackedInt32Array:
	var columns: PackedInt32Array = PackedInt32Array()
	var from: int = 0 if west else SEAM_TILE / 2
	var to: int = SEAM_TILE / 2 if west else SEAM_TILE
	for x: int in range(from, to):
		for y: int in range(SEAM_TILE):
			if not tile.get_pixel(x, y).is_equal_approx(base.get_pixel(x, y)):
				columns.append(x)
				break
	return columns


## LA LEVRE : le bord sud d un plateau contre le haut de sa propre falaise.
##
## ⚠ C EST LA COUTURE LA PLUS VISIBLE DU TILESET, et elle n avait aucun garde-fou. `_test_seams`
## verifiait surface contre surface, et robe contre robe -- jamais surface contre robe. Or
## sous CHAQUE bord sud il y a une falaise : c est l endroit ou le plateau bascule dans le
## vide, celui que l oeil regarde en premier.
##
## Une surface dont le bit S est clair a forcement un chapiteau dessous. Les deux doivent
## etre pleines a leur bord commun : c est exactement ce que L EPAULE existe pour garantir --
## le coin de roche qui bouche le petit angle entre l arrondi du plateau et le haut de la
## face. Sans elle, on voyait le fond A TRAVERS la roche.
func _check_lip_seams(ink: GuideImage.Ink, marks: bool, label: String) -> void:
	var lipped: int = 0
	var pierced: Array[String] = []
	for index: int in BlobIndex.CANONICAL_INDICES:
		if (index & BlobIndex.S) != 0:
			continue  # un voisin au sud : pas de falaise ici, donc pas de levre
		lipped += 1
		var top: Image = GuideImage.make_top(index, 1, SEAM_TILE, ink, marks)
		var holes: int = 0
		for x: int in range(SEAM_TILE):
			if top.get_pixel(x, SEAM_TILE - 1).a <= 0.5:
				holes += 1
		if holes > 0:
			pierced.append("%s (%d px)" % [BlobIndex.describe(index), holes])

	var crown_holes: Array[String] = []
	for pan: int in range(Walls.PAN_COUNT):
		var crown: Image = GuideImage.make_wall(Vector2i(pan, Walls.ROW_CROWN), SEAM_TILE,
				ink, marks)
		var holes: int = 0
		for x: int in range(SEAM_TILE):
			if crown.get_pixel(x, 0).a <= 0.5:
				holes += 1
		if holes > 0:
			crown_holes.append("%s (%d px)" % [Walls.pan_name(pan), holes])

	_check(lipped > 0, "%s : %d surfaces portent une levre" % [label, lipped])
	_check_equal(crown_holes, PackedStringArray([]) as Array,
			"%s : aucun chapiteau n est troue a son bord haut" % label)

	# ⚠ ASSERTE DANS LES TROIS STYLES, ET CE N ETAIT PAS LE CAS. Le fil de fer ne portait pas
	# l epaule : 8 des 13 levres y laissaient voir le fond, jusqu a la moitie du bord pour
	# l index 0 dont les deux coins bas sont decoupes. Les deux styles decrivent LA MEME
	# GEOMETRIE -- « sous un bord sud il y a toujours une falaise » -- donc l un des deux
	# mentait. L epaule se ferme desormais dans les deux, chacune dans sa palette.
	_check_equal(pierced, PackedStringArray([]) as Array,
			"%s : aucun bord sud ne laisse voir le fond -- l epaule bouche l angle" % label)
