# Runner de tests headless du noyau SoluTiles.
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
const PackedPNG := preload("res://exporters/packed_png.gd")
const Assembly := preload("res://render/assembly.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Families := preload("res://core/families.gd")
const PluginInstall := preload("res://core/plugin_install.gd")
const PluginRules := preload("res://addons/solupaint/rules.gd")
const PluginManifest := preload("res://addons/solupaint/manifest.gd")
const PluginTileSet := preload("res://addons/solupaint/tileset.gd")
const Trial := preload("res://exporters/trial_tileset.gd")
const Massifs := preload("res://core/massifs.gd")
const Gesture := preload("res://core/gesture.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")
const MassifTrial := preload("res://exporters/massif_trial.gd")
const Thickness := preload("res://core/thickness.gd")
const Domain := preload("res://core/domain.gd")
const Seams := preload("res://core/seams.gd")
const Junctions := preload("res://core/junctions.gd")
const WorkArea := preload("res://ui/work_area.gd")

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
	_test_shared_images()
	_test_bucket()
	_test_surface_map()
	_test_work_area()
	_test_symmetry()
	_test_work_io()
	_test_export()
	_test_packed()
	_test_assembly()
	_test_preview_scene()
	_test_vocabulary_is_closed()
	_test_domain()
	_test_thickness()
	_test_thickness_cross_check()
	_test_deep_falls()
	_test_proof_scene()
	_test_corner_network()
	_test_families()
	_test_dual_end_to_end()
	_test_seam_census()
	_test_seams()
	_test_seam_propagation()
	_test_junctions()
	_test_underfoot()
	_test_backing()
	_test_guide_image()
	_test_wireframe_joins()
	_test_manual()
	_test_plugin_rules()
	_test_trial_tileset()
	_test_stacked_levels()
	_test_plugin_manifest()
	_test_manifest_discovery()
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
	_check_equal(report["missing"].size(), Thickness.SURFACE_INDICES.size() - expected_present.size(), "18 index manquants")
	_check_equal(report["is_complete"], false, "le bloc 3x3 ne couvre pas les 48 tuiles")
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
	# Deux blocs 2x2 jumeaux : leurs coins haut-gauche portent le meme index 28 (E+SE+S),
	# un index EPAIS -- l ilot d une case est mort avec le mode.
	var mask: PackedStringArray = MaskIO.parse("##.##\n##.##")
	var painted: Array[Vector2i] = [Vector2i(0, 0)]
	var resolved: Dictionary = Delivery.resolve(mask, painted)
	var expected_retained: Array[Vector2i] = [Vector2i(0, 0)]
	_check_equal(resolved["retained"][28], expected_retained, "seule la variante peinte est retenue")
	_check_equal(resolved["unused"].size(), 7, "les sept autres cases ne servent pas")
	_check_equal(resolved["delivered"], PackedInt32Array([28]), "l index 28 est livre")
	_check_equal(resolved["missing"].size(), Thickness.SURFACE_INDICES.size() - 1,
			"les 26 autres index manquent")
	_check_equal(resolved["is_exportable"], false, "un seul index livre n est pas exportable")

	var nothing_painted: Array[Vector2i] = []
	var untouched: Dictionary = Delivery.resolve(mask, nothing_painted)
	_check(untouched["retained"].is_empty(), "sans peinture, aucune tuile n est retenue")
	_check_equal(untouched["unused"].size(), 8, "sans peinture, les huit cases restent inutilisees")

	# Peindre hors du guide est signale, jamais jete en silence.
	var outside_painted: Array[Vector2i] = [Vector2i(2, 0)]
	var outside_resolved: Dictionary = Delivery.resolve(mask, outside_painted)
	var expected_outside: Array[Vector2i] = [Vector2i(2, 0)]
	_check_equal(outside_resolved["outside"], expected_outside, "une case peinte hors du guide est signalee")

	# L ordre des cases fournies ne change pas le resultat.
	var both_orders: Array[Vector2i] = [Vector2i(3, 0), Vector2i(0, 0)]
	var reversed_resolved: Dictionary = Delivery.resolve(mask, both_orders)
	var expected_both: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 0)]
	_check_equal(reversed_resolved["retained"][28], expected_both, "les variantes sont rendues en ordre de lecture")


func _test_modes_catalogue() -> void:
	print("modes : catalogue")
	# ⚠ UN SEUL PAYSAGE SE CHOISIT, ET C EST CELUI DES MASSIFS. `epais` reste dans la table
	# comme TEMOIN de l ancien modele -- outils et suite s en servent encore -- mais il est
	# FERME : un mode qu on ne peut plus livrer ne se propose pas (charte, regle 5).
	var open_modes: Array[StringName] = []
	for id: StringName in Modes.ids():
		if Modes.is_available(id):
			open_modes.append(id)
	_check_equal(open_modes.size(), 1, "un seul paysage se choisit")
	_check_equal(open_modes[0], Modes.MASSIFS, "et c est massifs")
	_check(Modes.is_closed(Modes.EPAIS), "epais est ferme, pas retire : il reste un temoin")
	_check(not Modes.is_available(Modes.EPAIS), "et il ne se choisit plus")
	_check_equal(Modes.label(Modes.MASSIFS), "Massifs", "libelle du mode livre")
	_check(FileAccess.file_exists(Modes.guide_path(Modes.MASSIFS)),
			"massifs a son guide, il se choisit")

	# ⚠ LES COMPTES SONT CALCULES DU VOCABULAIRE, JAMAIS ECRITS. Une liste ecrite a la main
	# est une donnee a maintenir et un endroit ou mentir -- meme raison que les index calcules.
	var tiles: int = Families.massif_tiles().size()
	_check_equal(Modes.tile_count(Modes.MASSIFS), tiles,
			"%d tuiles en tout, et le compte est la somme des deux bandes" % tiles)
	_check(Modes.surface_tile_count(Modes.MASSIFS) > 0, "des surfaces")
	_check(Modes.wall_tile_count(Modes.MASSIFS) > 0, "et des jupes")
	_check_equal(Modes.min_occurrences(Modes.MASSIFS), 1,
			"massifs ne promet qu une occurrence")
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
	_check_equal(Walls.PAN_COUNT, 4,
			"quatre pans : deux etats de flanc, au carre -- ma roche continue, ou elle s arrete")
	# Une chute d un etage : chapiteau, corps 0, pied. Le corps 1 n y apparait jamais.
	_check_equal(Walls.row_for(1, 3, true), Walls.ROW_CROWN, "premiere case sous la levre : chapiteau")
	_check_equal(Walls.row_for(2, 3, true), 1, "deuxieme case : corps 0")
	_check_equal(Walls.row_for(3, 3, true), Walls.ROW_FOOT, "la case qui touche le sol : pied")
	# Deux etages : le corps tourne sur lui-meme, et c est ce qui evite le begaiement.
	var rows: Array[int] = []
	for step: int in range(1, 7):
		rows.append(Walls.row_for(step, 6, true))
	# ⚠ TROIS CORPS : la chute de six montre les trois avant de reboucler, et c est ce
	# rebouclage-la qui laisse trois profils de bord independants au lieu d un seul.
	var expected_rows: Array[int] = [0, 1, 2, 3, 1, 4]
	_check_equal(rows, expected_rows,
			"chute de six : chapiteau, corps 0, corps 1, corps 2, corps 0, pied")
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
	# ⚠ L ETAGE VOISIN N EST PAS DE LA ROCHE. Il rendait `muet` -- « il est devant moi,
	# c est a lui de tracer » -- et le delegataire etait une tuile de SURFACE, la meme a
	# des dizaines d endroits, incapable de tracer. `muet` ne dit plus qu une chose : de
	# la roche a cote. Un sommet de plateau, meme au ras de ma face, est de la terre.
	_check_equal(Walls.pan_east(stair_roles[Vector3i(2, 5, 2)].x), Walls.SIDE_VOID,
			"plus bas, l etage voisin n est pas de la roche : flanc vide")


## ⚠ TOUT MODE OUVERT DOIT PROUVER SON GUIDE. La boucle vaut declaration : ajouter un mode
## au catalogue, c'est s'engager a ce que son guide passe ici.
func _test_mode_guides_are_complete() -> void:
	# ⚠ LE GUIDE LIVRE SE CONTROLE DANS SON PROPRE MODELE. Les modes ouverts sont ceux du
	# modele des massifs ; `epais` est ferme et garde son controle a part, pour aussi
	# longtemps que l ancien noyau reste au depot.
	for id: StringName in Modes.ids():
		if Modes.is_available(id):
			_check_massif_guide(id)
	_check_one_guide(Modes.EPAIS)


## LE GUIDE DU MODELE DES MASSIFS : il porte tout le vocabulaire, et ce qui est peint decide.
func _check_massif_guide(id: StringName) -> void:
	print("mode %s : le guide est complet, et ce qui est peint decide" % Modes.label(id))
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(id))
	var report: Dictionary = Families.analyse(Families.BY_MASSIF, heights)
	_check(report["is_complete"], "aucune tuile manquante")
	_check_equal(report["present"].size(), Families.massif_tiles().size(),
			"les %d tuiles du vocabulaire sont couvertes" % Families.massif_tiles().size())
	print("  %d poses peignables dans le guide" % report["filled_count"])

	# ⚠ LA PROMESSE DU MODE EST CHIFFREE, DONC ELLE SE PROUVE.
	var promised: int = Modes.min_occurrences(id)
	var rarest: int = 1 << 30
	for tile: int in report["present"]:
		rarest = mini(rarest, int(report["occurrences"][tile]))
	_check(rarest >= promised,
			"chaque tuile est vue au moins %d fois, comme annonce (la plus rare : %d)"
			% [promised, rarest])
	var lonely: int = 0
	for tile2: int in report["present"]:
		if int(report["occurrences"][tile2]) == 1:
			lonely += 1
	print("  %d tuiles n ont AUCUNE jumelle : autant de cases obligatoires" % lonely)

	# ⚠ ET LE GUIDE EST DANS LE DOMAINE QU IL MONTRE. Un guide qui porterait un relief que le
	# pinceau ne produit pas montrerait a l artiste des tuiles qu il ne saura jamais poser.
	var faults: Array[String] = Gesture.faults(heights)
	_check(faults.is_empty(), "et le relief du guide est de ceux que le pinceau produit%s"
			% ("" if faults.is_empty() else " (%s)" % ", ".join(faults)))

	# UN GUIDE COMPLET NE SUFFIT PAS A EXPORTER : ce qui est peint decide.
	var painting: Painting = MassifTrial.paint(heights)
	_check(bool(MassifTileset.analyse(painting, heights)["is_exportable"]),
			"guide entierement peint : exportable")
	var target: int = int(report["present"][0])
	var partial: Painting = Painting.new(MassifTrial.TRIAL_RESOLUTION)
	for tile3: int in report["present"]:
		if tile3 == target:
			continue
		var cells: Array = report["positions"][tile3]
		partial.set_image(cells[0], MassifTrial.draw(tile3, MassifTrial.TRIAL_RESOLUTION))
	var short: Dictionary = MassifTileset.analyse(partial, heights)
	_check_equal(short["missing"], [target] as Array[int],
			"laisser une tuile entierement vierge la fait manquer, et elle seule")
	_check_equal(short["is_exportable"], false, "une tuile non peinte interdit l export")


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

	# Tout peindre livre les 27 index epais : la borne haute de ce que le guide permet.
	var every_cell: Array[Vector2i] = []
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			if Coverage.visible_index_at(heights, x, y) != Coverage.NO_INDEX:
				every_cell.append(Vector2i(x, y))
	var resolved: Dictionary = Delivery.resolve_relief(heights, every_cell)
	_check(resolved["is_exportable"], "guide complet entierement peint : exportable")
	_check_equal(resolved["delivered"].size(), Thickness.SURFACE_INDICES.size(), "les 48 tuiles sont livrees")
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
	# ⚠ LE VOCABULAIRE DE MUR APPARTIENT A L ANCIEN MODELE, DONC A SON GUIDE. Dans le modele
	# des massifs une jupe n est pas un second vocabulaire : c est le meme massif, vu plus bas.
	_check_one_guide_walls(Modes.EPAIS)


func _check_one_guide_walls(id: StringName) -> void:
	print("mode %s : le guide couvre aussi le vocabulaire de mur" % Modes.label(id))
	var guide_path: String = Modes.guide_path(id)
	var heights: PackedStringArray = HeightMask.read(guide_path)
	_check(HeightMask.top_level(heights) >= 2, "le guide a du relief : au moins deux etages")
	var report: Dictionary = Walls.analyse(heights, Thickness.wall_roles())
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
		# ⚠ LA MEME TABLE QUE L'EDITEUR. `Families.paintable_map` est ce que la zone de
		# travail lit pour tracer sa grille et refuser le crayon : hors de la plaine, et
		# hors des cases qu'une robe recouvre. Ce que l'ecran accepte est ce qu'on compte.
		var counts: Dictionary = {}
		var indices: Dictionary = Families.paintable_map(family, heights)
		for at: Vector2i in indices.keys():
			var index: int = int(indices[at])
			counts[index] = int(counts.get(index, 0)) + 1
		var missing: Array[int] = []
		for index: int in Families.surface_indices(family):
			if int(counts.get(index, 0)) < promised:
				missing.append(index)
		_check_equal(missing, [] as Array[int],
				"%s : les %d tuiles de surface « %s » se trouvent %d fois HORS de la plaine et des robes"
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
	for role: Vector2i in Thickness.wall_roles():
		if int(role_counts.get(role, 0)) < promised:
			absent_roles.append(role)
	_check_equal(absent_roles, [] as Array[Vector2i],
			"%s : les %d roles de robe descendent %d fois d'une levre qui n'est pas la plaine"
			% [Modes.label(id), Thickness.wall_roles().size(), promised])


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


## UNE TUILE, UNE IMAGE : les jumelles partagent leur dessin dans le carnet.
##
## ⚠ C'EST LA STRUCTURE, PAS UNE OPTIMISATION. Avant le partage, peindre l'index 255
## ecrivait le meme pixel dans 1553 images : 6,2 ms par point de crayon, 224 ms par point
## de BORD (les echos de raccord repassaient sur chaque jumelle de chaque echo), et un
## journal d'annulation de 1553 entrees par pixel. Mesure apres : 7 µs et 7 µs.
func _test_shared_images() -> void:
	print("partage : deux jumelles sont la meme image")
	var painting: RefCounted = Painting.new(16)
	var twins: Array[Vector2i] = [Vector2i(5, 3), Vector2i(1, 1), Vector2i(4, 3)]
	painting.share(twins)
	_check_equal(painting.holder(Vector2i(5, 3)), Vector2i(1, 1),
			"la premiere jumelle en ordre de lecture tient l image")
	_check_equal(painting.holder(Vector2i(9, 9)), Vector2i(9, 9),
			"une case hors de tout groupe se tient elle-meme")
	painting.begin_stroke()
	_check(painting.paint(Vector2i(5, 3), 2, 2, Color.RED), "peindre une jumelle")
	painting.end_stroke()
	_check(painting.is_painted(Vector2i(4, 3)), "en peint une autre")
	_check(painting.image_of(Vector2i(4, 3)) == painting.image_of(Vector2i(1, 1)),
			"et c est LA MEME image, pas une copie")
	_check_equal(painting.painted_cells(), [Vector2i(1, 1)] as Array[Vector2i],
			"le carnet ne compte le groupe qu une fois, par la case qui le tient")
	_check_equal(painting.pixel_at(Vector2i(5, 3), 2, 2), Color.RED, "la pipette lit a travers le groupe")
	var undone: Array[Vector2i] = painting.undo()
	_check_equal(undone, [Vector2i(1, 1)] as Array[Vector2i],
			"defaire rend la case qui tient l image")
	_check(not painting.is_painted(Vector2i(5, 3)), "et la jumelle est defaite avec")

	# ⚠ CE QUI ETAIT DEJA PEINT EST RASSEMBLE, PAS JETE. Un travail relu pose ses images par
	# rang, avant que les jumelles ne soient connues ; un fichier d avant le partage en
	# posait une par jumelle.
	var relu: RefCounted = Painting.new(16)
	var image: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	relu.set_image(Vector2i(4, 3), image)
	relu.set_image(Vector2i(5, 3), image)
	relu.share(twins)
	_check_equal(relu.painted_cells(), [Vector2i(1, 1)] as Array[Vector2i],
			"deux images relues sur deux jumelles n en font plus qu une, sous la bonne case")
	_check_equal(relu.pixel_count(Vector2i(1, 1)), 256, "et rien n est perdu")


## LE POT DE PEINTURE : la plage contigue, bornee par la tuile.
func _test_bucket() -> void:
	print("pot : la plage contigue, jamais au-dela de la tuile")
	var painting: RefCounted = Painting.new(16)
	var cell: Vector2i = Vector2i(2, 2)
	painting.begin_stroke()
	for y: int in range(16):
		painting.paint(cell, 7, y, Color.BLACK)
	painting.end_stroke()
	painting.begin_stroke()
	var poured: Array[Vector2i] = painting.fill(cell, 0, 0, Color.GREEN)
	painting.end_stroke()
	_check_equal(poured.size(), 7 * 16, "le pot s arrete a la ligne noire : 7 colonnes sur 16")
	_check_equal(painting.pixel_at(cell, 10, 10), Painting.TRANSPARENT, "l autre cote reste vierge")
	_check_equal(painting.pixel_at(cell, 7, 5), Color.BLACK, "la ligne n a pas bouge")
	_check(not painting.is_painted(Vector2i(1, 2)), "et la tuile voisine n a rien recu")
	painting.undo()
	_check_equal(painting.pixel_count(cell), 16, "un pot se defait d un seul geste")
	_check_equal(painting.fill(cell, 7, 0, Color.BLACK).size(), 0,
			"verser la couleur deja la ne change rien")
	var blank: RefCounted = Painting.new(16)
	blank.begin_stroke()
	_check_equal(blank.fill(Vector2i.ZERO, 3, 3, Color.RED).size(), 256,
			"sur une tuile vierge, le pot remplit tout")
	blank.end_stroke()


## CE QU UNE CASE PORTE : une case sous une face de falaise porte la robe, pas le sol d en bas.
func _test_surface_map() -> void:
	print("surface_map : une case sous une robe porte la robe")
	for id: StringName in Modes.ids():
		var heights: PackedStringArray = HeightMask.read(Modes.guide_path(id))
		var roles: Dictionary = Walls.visible_roles(heights)
		var carried: Dictionary = Families.surface_map(Families.BY_CELL, heights)
		var raw: Dictionary = Families.index_map(Families.BY_CELL, heights)
		var under: int = 0
		for cell: Vector2i in carried.keys():
			if roles.has(cell):
				under += 1
		_check_equal(under, 0, "%s : aucune case de robe ne porte aussi une surface" % Modes.label(id))
		_check(raw.size() > carried.size(),
				"%s : la carte brute en comptait %d de plus, toutes sous une face"
				% [Modes.label(id), raw.size() - carried.size()])
		var paintable: Dictionary = Families.paintable_map(Families.BY_CELL, heights)
		var on_plain: int = 0
		for cell: Vector2i in paintable.keys():
			if HeightMask.level_at(heights, cell.x, cell.y) < 1:
				on_plain += 1
		_check_equal(on_plain, 0, "%s : rien ne se peint sur la plaine" % Modes.label(id))
		# ⚠ ET CHAQUE RANG DE SURFACE EXISTE. Avant, la cle W ecrasait la cle S d une case
		# sous robe, et « S255:0 » pouvait ne designer personne.
		var by_key: Dictionary = WorkIO.cells_by_key(heights)
		var by_cell: Dictionary = WorkIO.slots(heights)
		# ⚠ ON COMPTE, ON NE FOUILLE PAS. Chercher chaque rang inferieur un par un est
		# quadratique en occurrences : sur un guide ou une tuile se voit deux mille fois,
		# c'est deux millions de chaines bâties pour une question qui se repond par une
		# soustraction. Les rangs se suivent sans trou si, et seulement si, le plus grand
		# vaut le nombre moins un.
		var top_rank: Dictionary = {}
		var count_rank: Dictionary = {}
		for key: String in by_key.keys():
			if not key.begins_with("S"):
				continue
			var cut: int = key.rfind(":")
			var prefix: String = key.substr(0, cut)
			var rank: int = int(key.substr(cut + 1))
			top_rank[prefix] = maxi(int(top_rank.get(prefix, 0)), rank)
			count_rank[prefix] = int(count_rank.get(prefix, 0)) + 1
		var holes: int = 0
		for prefix: String in top_rank.keys():
			holes += int(top_rank[prefix]) + 1 - int(count_rank[prefix])
		_check_equal(holes, 0, "%s : les rangs de surface se suivent sans trou" % Modes.label(id))
		var surface_slots: int = 0
		for cell: Vector2i in by_cell.keys():
			if String(by_cell[cell]).begins_with("S"):
				surface_slots += 1
		_check_equal(surface_slots, carried.size(), "%s : un rang par case qui porte une surface" % Modes.label(id))


## LA ZONE DE TRAVAIL, MONTEE EN HEADLESS : ce que l ecran fait d un coup de crayon.
##
## ⚠ C EST LE PREMIER TEST QUI MONTE L INTERFACE, et il existe parce que deux defauts n ont
## pu se voir nulle part ailleurs : peindre une surface « livrait » les 36 roles de robe, et
## le crayon ne savait pas peindre un croisement. Aucun test du noyau ne pouvait les voir --
## ils vivaient dans la traduction souris -> tuile.
func _test_work_area() -> void:
	print("zone de travail : le crayon, les outils, la contrainte")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var work: Control = WorkArea.new()
	root.add_child(work)
	work.size = Vector2(1200, 800)
	var painting: RefCounted = Painting.new(16)
	work.show_guide(heights, painting)
	work._job = null
	work._tile_px = 160.0
	# La case la plus reproduite : l herbe pleine.
	var grass: Vector2i = Vector2i.ZERO
	var most: int = 0
	for cell: Vector2i in work._paintable.keys():
		var twins: int = work._twin_of[cell].size() if work._twin_of.has(cell) else 1
		if twins > most:
			most = twins
			grass = cell
	_check_equal(int(work.surface_index()[grass]), 255, "la case la plus reproduite est l herbe pleine")
	work._origin = -Vector2(float(grass.x), float(grass.y)) * work._tile_px
	work._begin_or_end(true, 1, Vector2(80, 80))
	work._begin_or_end(false, 1, Vector2(80, 80))
	_check_equal(painting.painted_cells().size(), 1, "un pixel d herbe : UNE image dans le carnet")
	_check_equal(work.painted_wall_cells().size(), 0,
			"et aucune case de robe ne se dit peinte (elles portaient l herbe avant)")
	var walls: Dictionary = Walls.resolve_roles(work.wall_roles(), work.painted_wall_cells())
	_check_equal(walls["delivered"].size(), 0, "donc aucun role de robe n est livre par une surface")
	var surface: Dictionary = Delivery.resolve_indexed(work.surface_index(),
			work.painted_surface_cells(), Families.surface_indices(Families.BY_CELL))
	_check_equal(surface["delivered"].size(), 1, "et l index 255 l est")
	var shown: int = 0
	for cell: Vector2i in work._twin_of[grass]:
		if painting.is_painted(cell):
			shown += 1
	_check_equal(shown, most, "toutes les jumelles (%d) montrent le pixel" % most)

	# La contrainte : une passe reste dans la tuile ou elle a commence.
	# ⚠ IL FAUT DEUX VOISINES QUI NE SOIENT PAS JUMELLES : deux jumelles partagent leur
	# image, et « la voisine n a rien recu » n y voudrait rien dire.
	var left: Vector2i = WorkArea.NOWHERE
	for cell: Vector2i in work._paintable.keys():
		var next: Vector2i = cell + Vector2i.RIGHT
		if work._surface_cells.has(cell) and work._surface_cells.has(next) 				and work._paintable.has(next) and painting.holder(cell) != painting.holder(next):
			left = cell
			break
	_check(left != WorkArea.NOWHERE, "deux surfaces voisines de tuiles differentes existent")
	var right: Vector2i = left + Vector2i.RIGHT
	work._origin = -Vector2(float(left.x), float(left.y)) * work._tile_px
	work.lock_to_tile = true
	var before: int = painting.pixel_count(right)
	work._begin_or_end(true, 1, Vector2(150, 80))
	work._apply_stroke(Vector2(150, 80), Vector2(170, 80))
	work._begin_or_end(false, 1, Vector2(170, 80))
	_check_equal(painting.pixel_count(right), before, "contrainte : le trait qui deborde ne touche pas la voisine")
	_check(painting.pixel_at(left, 15, 8).a > 0.0, "mais il a bien peint jusqu au bord de la sienne")
	work.lock_to_tile = false
	work._begin_or_end(true, 1, Vector2(150, 40))
	work._apply_stroke(Vector2(150, 40), Vector2(170, 40))
	work._begin_or_end(false, 1, Vector2(170, 40))
	_check(painting.pixel_count(right) > before, "sans contrainte, le meme trait passe dans la voisine")
	work._origin = -Vector2(float(grass.x), float(grass.y)) * work._tile_px

	# Le pot : la tuile entiere, et rien d autre.
	work.tool = WorkArea.Tool.BUCKET
	work.pencil = Color.BLUE
	work._begin_or_end(true, 1, Vector2(40, 120))
	work._begin_or_end(false, 1, Vector2(40, 120))
	_check(painting.pixel_count(grass) >= 200, "le pot remplit la plage vierge de la tuile (%d pixels)" % painting.pixel_count(grass))
	_check_equal(painting.pixel_at(grass, 1, 14), Color.BLUE, "dans la couleur du crayon")

	# La pipette.
	work.tool = WorkArea.Tool.PICKER
	work.pencil = Color.WHITE
	work._begin_or_end(true, 1, Vector2(40, 120))
	_check_equal(work.pencil, Color.BLUE, "la pipette prend la couleur sous le clic")
	_check(not painting.can_redo() and painting.can_undo(), "et ne laisse aucune passe au journal")

	# La brosse : un disque, pas un point.
	work.tool = WorkArea.Tool.ERASER
	work.brush_size = 4
	work._begin_or_end(true, 1, Vector2(80, 80))
	work._begin_or_end(false, 1, Vector2(80, 80))
	_check_equal(painting.pixel_at(grass, 8, 8), Painting.TRANSPARENT, "la gomme efface sous le clic")
	_check_equal(painting.pixel_at(grass, 7, 7), Painting.TRANSPARENT, "et autour, a la taille choisie")
	_check_equal(painting.pixel_at(grass, 3, 3), Color.BLUE, "pas au-dela")

	# La ligne et le rectangle se posent au relachement.
	work.tool = WorkArea.Tool.LINE
	work.brush_size = 1
	work.pencil = Color.RED
	work._begin_or_end(true, 1, Vector2(5, 5))
	work._cursor = work._pixel_at(Vector2(155, 155))
	work._begin_or_end(false, 1, Vector2(155, 155))
	_check_equal(painting.pixel_at(grass, 8, 8), Color.RED, "la ligne passe par le milieu")
	_check_equal(painting.pixel_at(grass, 0, 0), Color.RED, "depuis le clic")
	_check_equal(painting.pixel_at(grass, 15, 15), Color.RED, "jusqu au relachement")
	work.tool = WorkArea.Tool.RECT
	work.pencil = Color.GREEN
	work._begin_or_end(true, 1, Vector2(25, 25))
	work._cursor = work._pixel_at(Vector2(135, 135))
	work._begin_or_end(false, 1, Vector2(135, 135))
	_check_equal(painting.pixel_at(grass, 2, 9), Color.GREEN, "le rectangle trace son contour")
	_check_equal(painting.pixel_at(grass, 8, 8), Color.RED, "et laisse l interieur")
	root.remove_child(work)
	work.free()

	# ⚠ A CHEVAL, LE CRAYON PEINT LE CROISEMENT. Il lisait la case sous la souris : un
	# croisement, decale d une demi-case et range dans les y negatifs, n etait jamais atteint.
	var dual: Control = WorkArea.new()
	root.add_child(dual)
	dual.size = Vector2(1200, 800)
	dual.guide_family = Families.BY_CORNER
	var dual_painting: RefCounted = Painting.new(16)
	dual.show_guide(heights, dual_painting)
	dual._job = null
	dual._tile_px = 160.0
	var corner: Vector2i = Vector2i.ZERO
	for key: Vector2i in dual._paintable.keys():
		if key.y < 0 and not dual._wall_cells.has(Families.from_storage(Families.BY_CORNER, key)):
			corner = key
			break
	var point: Vector2i = Families.from_storage(Families.BY_CORNER, corner)
	dual._origin = -Vector2(float(point.x) - 0.5, float(point.y) - 0.5) * dual._tile_px
	dual._begin_or_end(true, 1, Vector2(80, 80))
	dual._begin_or_end(false, 1, Vector2(80, 80))
	_check(dual_painting.is_painted(corner), "a cheval, un clic au centre d un croisement le peint")
	_check_equal(dual_painting.pixel_at(corner, 8, 8).a > 0.0, true, "au bon pixel de sa tuile")
	root.remove_child(dual)
	dual.free()


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
	# ⚠ QUINZE ORBITES POUR VINGT ROLES. Le miroir echange les deux flancs : deux pans sont
	# donc fixes -- (arret,arret) et (continue,continue) -- et les deux autres forment une
	# paire. Trois orbites par rangee, cinq rangees.
	_check_equal(Symmetry.MIRROR_ORBITS.size(), 15,
			"les 20 roles se rangent en 15 orbites de miroir")

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


## LA FEUILLE PACKED : les MEMES pixels, ranges autrement.
##
## ⚠ ET C'EST LA SEULE CHOSE QUI VAILLE D'ETRE ASSERTEE ICI. Verifier que la feuille packed
## est « bien remplie » ne dirait rien : ce qu'elle promet, c'est d'etre le tileset moteur
## sous une autre disposition. On compare donc case a case avec les deux planches -- si l'une
## des deux differait, l'une des deux mentirait.
func _test_packed() -> void:
	print("packed : une seule feuille, les memes pixels")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var by_key: Dictionary = WorkIO.cells_by_key(heights)
	var painting: Painting = Painting.new(16)
	for key: String in by_key.keys():
		if key.ends_with(":0"):
			painting.paint(by_key[key], 0, 0, _key_colour(key))

	var report: Dictionary = TilesetPNG.analyse(painting, heights)
	var slots: Array = PackedPNG.order()
	var columns: int = PackedPNG.columns_for(slots.size())
	var rows: int = (slots.size() + columns - 1) / columns
	_check_equal(slots.size(),
			Thickness.SURFACE_INDICES.size() + Thickness.wall_roles().size(),
			"la feuille packed porte le vocabulaire entier, surfaces et robes")
	_check(columns * rows >= slots.size(), "la grille contient toutes les tuiles")
	# ⚠ LA CARRURE EST LA REGLE, ET ELLE S ASSERTE : une bande d une seule colonne passerait
	# tous les autres controles. Premiere version ecrite a l envers -- 1 x 47 pour 47 tuiles.
	_check(maxf(float(columns) / float(rows), float(rows) / float(columns)) <= 1.5,
			"la feuille reste a peu pres carree")
	_check(columns * rows - slots.size() < columns, "et elle ne laisse pas une rangee vide")

	var sheet: Image = PackedPNG.compose(painting, heights, report)
	_check_equal(sheet.get_width(), columns * 16, "la feuille fait sa grille de large")
	_check_equal(sheet.get_height(), rows * 16, "et sa grille de haut")

	var surface_sheet: Image = TilesetPNG.compose(painting, heights, report, false)
	var wall_sheet: Image = TilesetPNG.compose(painting, heights, report, true)
	var astray: int = 0
	for at: int in range(slots.size()):
		var slot: Array = slots[at]
		var here: Vector2i = Vector2i(at % columns, at / columns) * 16
		var there: Vector2i
		var source: Image
		if String(slot[0]) == "W":
			source = wall_sheet
			there = TilesetPNG.wall_slot(slot[1] as Vector2i) * 16
		else:
			source = surface_sheet
			there = TilesetPNG.surface_slot(int(slot[1])) * 16
		for y: int in range(16):
			for x: int in range(16):
				if not sheet.get_pixel(here.x + x, here.y + y).is_equal_approx(
						source.get_pixel(there.x + x, there.y + y)):
					astray += 1
	_check_equal(astray, 0,
			"chaque pixel de la feuille packed est celui de la planche moteur")

	var legend: String = PackedPNG.legend(painting, Modes.MINIMAL, "essai", report)
	var listed: int = 0
	for line: String in legend.split("
"):
		if line.begins_with("case "):
			listed += 1
	_check_equal(listed, slots.size(), "la legende nomme chaque case de la feuille")
	_check(legend.contains("grille %d %d" % [columns, rows]), "et elle dit sa grille")
	# ⚠ ELLE NE PORTE AUCUNE REGLE DE POSE, et c est asserte : un acheteur qui croirait
	# pouvoir poser un monde avec elle fabriquerait un monde faux.
	_check(not legend.contains("canonicalise"), "la legende n est pas un manifeste")

	# LE REFUS, PAR LE MEME CHEMIN QUE L EXPORT MOTEUR.
	var partial: Painting = Painting.new(16)
	var refused: Dictionary = PackedPNG.write("user://packed_test", "essai", partial,
			heights, Modes.MINIMAL)
	_check_equal(int(refused["error"]), ERR_UNAVAILABLE,
			"une feuille incomplete ne part pas chez un acheteur")
	_check(PackedStringArray(refused["written"]).is_empty(), "et rien n est ecrit")


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
	_check_equal(first_keys.size(), Modes.tile_count(Modes.EPAIS),
			"le guide epais porte exactement autant de tuiles obligatoires que le vocabulaire")

	var report: Dictionary = TilesetPNG.analyse(painting, heights)
	_check(report["is_exportable"], "une occurrence de chaque tuile suffit a exporter")
	_check(report["missing_surface"].is_empty(), "aucune surface manquante")
	_check(report["missing_wall"].is_empty(), "aucune robe manquante")

	var sheet: Image = TilesetPNG.compose(painting, heights, report, false)
	_check_equal(sheet.get_width(), TilesetPNG.SURFACE_COLUMNS * 16, "huit tuiles de large")
	_check_equal(sheet.get_height(), TilesetPNG.surface_rows() * 16, "quatre rangees de haut")
	var astray: int = 0
	for index: int in Thickness.SURFACE_INDICES:
		var slot: Vector2i = TilesetPNG.surface_slot(index)
		if not sheet.get_pixel(slot.x * 16, slot.y * 16).is_equal_approx(
				_key_colour("S%d:0" % index)):
			astray += 1
	_check_equal(astray, 0, "les 48 tuiles tombent chacune sur SA case de la planche")

	var kit: Image = TilesetPNG.compose(painting, heights, report, true)
	_check_equal(kit.get_width(), Walls.PAN_COUNT * 16, "la planche de robes fait neuf pans")
	_check_equal(kit.get_height(), Walls.BLOCK_ROWS * 16, "et cinq rangees")
	var roles_astray: int = 0
	for role: Vector2i in Thickness.wall_roles():
		var at: Vector2i = TilesetPNG.wall_slot(role)
		if not kit.get_pixel(at.x * 16, at.y * 16).is_equal_approx(
				_key_colour("W%d,%d:0" % [role.x, role.y])):
			roles_astray += 1
	_check_equal(roles_astray, 0, "les 25 robes tombent chacune sur SA case")

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
		"pan west_times_two_plus_east lip_row_comparison per_row",
		"bits N=%d" % BlobIndex.N,
		"surface_offset none",
		"sheet fixed_size one_drawing_per_tile no_variants",
		"underfoot foot_role redrawn_below under_landing_surface",
		"backing next_body_row under_trimming_cell same_level_only",
		"lip_backing first_fall_row under_lip_cell",
		"thin_forbidden run_shorter_than_three all_storeys both_states",
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
	for tile: int in indices.values():
		if not BlobIndex.is_canonical(BlobIndex.silhouette(tile)):
			wild += 1
	_check_equal(wild, 0, "chaque case du decor porte une silhouette des 47")

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
		# ⚠ UNE TUILE DE SURFACE EST UN COUPLE (silhouette, bord) : la battue compare la
		# SILHOUETTE aux 47 canoniques, le bord n'ayant rien a voir avec la canonicalisation.
		for tile: int in Coverage.index_map(relief).values():
			if not canonical.has(BlobIndex.silhouette(tile)):
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
		for tile: int in Coverage.index_map(holed).values():
			if not canonical.has(BlobIndex.silhouette(tile)):
				wild += 1
		for role: Vector2i in Walls.visible_roles(holed).values():
			seen_roles[role] = true
			if not known.has(role):
				wild += 1
		for tile: int in Coverage.index_map(heights).values():
			if not canonical.has(BlobIndex.silhouette(tile)):
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
	_check_equal(centres.size(), Thickness.SURFACE_INDICES.size(), "un ilot par index, ni plus ni moins")
	# ⚠ ON DEMANDE LA TUILE, PAS LA SILHOUETTE : le bord se lit des robes voisines, donc il
	# faut la carte des robes. Sans elle la planche se compare a des index nus et croit que
	# toutes ses cases sont fausses.
	var board_walls: Dictionary = Walls.visible_roles(relief)
	var misplaced: Array[int] = []
	for index: int in centres.keys():
		var at: Vector2i = centres[index]
		if Coverage.visible_index_at(relief, at.x, at.y, board_walls) != index:
			misplaced.append(index)
	_check_equal(misplaced, [] as Array[int],
			"les 48 ilots portent chacun SON index, a la case annoncee")

	# Et les ilots ne se contaminent pas : la planche entiere ne montre que les 47.
	var report: Dictionary = Coverage.analyse_relief(relief)
	_check(report["is_complete"], "la planche couvre les 48 tuiles")
	var walls: Dictionary = Walls.analyse(relief, Thickness.wall_roles())
	_check(walls["is_complete"], "et les 44 roles de falaise, par les accidents epais")
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
	# ⚠ ET LE RESEAU DUAL APPARTIENT A L ANCIEN MODELE : il se controle sur SON guide. Le
	# guide des massifs n a aucune raison de couvrir des croisements qu il ne livre pas.
	for id: StringName in [Modes.EPAIS] as Array[StringName]:
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


## LE RECENSEMENT DES JONCTIONS — tout ce que le modele pose cote a cote, `Seams` le sait.
##
## ⚠ ON COMPARE DANS LES DEUX SENS, ET C'EST LA LECON QUI MANQUAIT ICI. `tools/check_seams.gd`
## verifiait depuis longtemps que `Seams` ne lie pas TROP ; personne ne verifiait qu il lie
## ASSEZ. Mesure avant correctif : le modele posait 70 jonctions verticales distinctes et
## `Seams` en connaissait 26, 39 muet/muet horizontales et il en connaissait 23 -- et
## l illustration cassait aux 60 inconnues SANS EXCEPTION, jusqu a 22 % d ecart. Deux causes,
## toutes deux des formules qui decrivaient ce qu on CROYAIT poser : les trois adossements
## (chapiteau sous la levre, sous-pied, pose derriere) sortent des pas 1..drop, et le pan
## d une colonne CHANGE en descendant des que la robe voisine s arrete.
##
## ⚠ ET ON LIT LES JONCTIONS D UN RELIEF ASSEMBLE, jamais de `row_for`. Deduire d une
## formule, c est enumerer ce qu on croit poser. Meme methode que `row_chains` un cran plus
## bas, et meme raison.
func _test_seam_census() -> void:
	var reliefs: Array[PackedStringArray] = []
	reliefs.append(HeightMask.read(Modes.guide_path(Modes.EPAIS)))
	for family: StringName in Families.ids():
		reliefs.append(ProofScene.relief(family))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260824
	for _try: int in range(120):
		var drawn: PackedStringArray = _random_thick_relief(rng)
		if not drawn.is_empty():
			reliefs.append(drawn)

	var vertical: Dictionary = {}
	var horizontal: Dictionary = {}
	for heights: PackedStringArray in reliefs:
		var assembled: Dictionary = Walls.assemble(heights)
		var roles: Dictionary = assembled["roles"]
		var underfoot: Dictionary = assembled["underfoot"]
		# ⚠ UNE CASE PORTE JUSQU A DEUX FRAGMENTS : la face devant, l adossement derriere.
		var frags: Dictionary = {}
		for key: Vector3i in roles:
			var bag: Array[Vector2i] = []
			bag.append(roles[key] as Vector2i)
			frags[key] = bag
		for key: Vector3i in underfoot:
			if not frags.has(key):
				var fresh: Array[Vector2i] = []
				frags[key] = fresh
			(frags[key] as Array[Vector2i]).append(underfoot[key] as Vector2i)
		for key: Vector3i in frags:
			var here: Array[Vector2i] = frags[key]
			var south: Vector3i = key + Vector3i(0, 1, 0)
			if frags.has(south):
				var below: Array[Vector2i] = frags[south]
				for up: Vector2i in here:
					for down: Vector2i in below:
						vertical[Vector4i(up.x, up.y, down.x, down.y)] = true
			var east: Vector3i = key + Vector3i(1, 0, 0)
			if frags.has(east):
				var beside: Array[Vector2i] = frags[east]
				for left: Vector2i in here:
					for right: Vector2i in beside:
						horizontal[Vector4i(left.x, left.y, right.x, right.y)] = true

	var unknown: Array[String] = []
	for key: Vector4i in vertical:
		var above: Vector3i = Vector3i(key.x, key.y, Seams.BOTTOM)
		var under: Vector3i = Vector3i(key.z, key.w, Seams.TOP)
		if not (Seams.GROUPS.get(above, []) as Array).has(under):
			unknown.append("%s %s SUR %s %s" % [Walls.SIDE_NAMES[Walls.pan_west(key.x)],
					Walls.ROW_NAMES[key.y], Walls.SIDE_NAMES[Walls.pan_west(key.z)],
					Walls.ROW_NAMES[key.w]])
	var mutes: int = 0
	for key: Vector4i in horizontal:
		if Walls.pan_east(key.x) != Walls.SIDE_MUTE:
			continue
		if Walls.pan_west(key.z) != Walls.SIDE_MUTE:
			continue
		mutes += 1
		var left_edge: Vector3i = Vector3i(key.x, key.y, Seams.RIGHT)
		var right_edge: Vector3i = Vector3i(key.z, key.w, Seams.LEFT)
		if not (Seams.GROUPS.get(left_edge, []) as Array).has(right_edge):
			unknown.append("%s CONTRE %s" % [Walls.ROW_NAMES[key.y], Walls.ROW_NAMES[key.w]])
	print("  jonctions posees : %d verticales, %d muet/muet horizontales, %d inconnues"
			% [vertical.size(), mutes, unknown.size()])
	if not unknown.is_empty():
		print("    %s" % ", ".join(unknown.slice(0, mini(6, unknown.size()))))
	_check(unknown.is_empty(),
			"toute jonction posee par le modele est connue de Seams (%d verticales, %d muettes)"
			% [vertical.size(), mutes])

	# ⚠ ET LA BATTUE DOIT AVOIR VRAIMENT CHERCHE. Un recensement qui ne rencontre rien
	# passerait au vert en ne prouvant rien -- meme piege que la battue des robes. La graine
	# est fixe, donc le compte est reproductible. ⚠ ET IL NE PRETEND PAS A L EXHAUSTIVITE :
	# `tools/seam_census.gd`, qui tire plus large et plus longtemps, en rencontre davantage.
	# La suite garde le garde-fou, l outil garde la battue.
	_check(vertical.size() >= 50 and mutes >= 37,
			"le recensement a vraiment cherche (%d verticales, %d muettes)"
			% [vertical.size(), mutes])

	# ⚠ LA FERMETURE EST PRUDENTE, ELLE N EST PAS DEGENEREE. Sur-joindre ne peut jamais
	# rendre un tileset faux, seulement plus contraint -- mais tout joindre le rendrait
	# impeignable, et un test qui ne verifie que « assez lie » passerait sur UNE classe.
	# ⚠ ET LE COMPTE SE SEPARE PAR AXE, parce que c est la moitie haut/bas qui porte la
	# liberte de l ARETE. A deux rangees de corps elle valait UNE classe -- un fil a
	# plomb, aucun vagabondage possible. A trois, elle en vaut TROIS : l arete se deplace
	# en trois crans le long d un etage, puis se repete.
	var seat: Dictionary = {}
	for role: Vector2i in Families.wall_roles():
		for side: int in range(4):
			seat[Vector3i(role.x, role.y, side)] = true
	var roots: Dictionary = {}
	for edge: Vector3i in seat:
		var best: Vector3i = edge
		for other: Vector3i in (Seams.GROUPS[edge] as Array):
			if not seat.has(other):
				continue
			if other.x < best.x or (other.x == best.x and (other.y < best.y
					or (other.y == best.y and other.z < best.z))):
				best = other
		roots[best] = true
	var upright: Dictionary = {}
	for edge: Vector3i in seat:
		if edge.z != Seams.TOP and edge.z != Seams.BOTTOM:
			continue
		var head: Vector3i = edge
		for other: Vector3i in (Seams.GROUPS[edge] as Array):
			if not seat.has(other):
				continue
			if other.x < head.x or (other.x == head.x and (other.y < head.y
					or (other.y == head.y and other.z < head.z))):
				head = other
		upright[head] = true
	# ⚠ VINGT-QUATRE CLASSES, CONTRE SOIXANTE-DEUX. La fermeture n'a pas change : ce sont les
	# PANS qui sont passes de neuf a quatre, et chaque pan de moins retire ses bords du compte.
	# Le nombre baisse donc sans qu'aucune liberte ne se perde -- les bords supprimes etaient
	# ceux de tuiles qui n'existent plus.
	_check_equal(roots.size(), 24, "la fermeture laisse 24 classes de bords independantes")
	_check_equal(upright.size(), 3,
			"et trois profils de frontiere de rangees -- le vagabondage de l arete")


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
##
## ⚠ ON VERIFIE LES CLASSES DE `Seams`, PLUS DES COUPLES REDEVINES. Ce test derivait ses
## enchainements de `row_for` sur trois chutes, a pan constant -- exactement la formule qui
## laissait 60 jonctions hors de toute classe. UN TEST QUI REFAIT LE CALCUL DU CODE QU IL
## VERIFIE NE VERIFIE RIEN : il recopie la meme erreur, et il l a fait tout du long. On lit
## donc `Seams.GROUPS`, c est-a-dire ce que la propagation ECRIT vraiment sous le crayon.
## Si l illustration contredit une classe, l artiste qui peint par-dessus voit son pixel
## bouger tout seul -- c est ca, l aller-retour.
##
## ⚠ ET LA COMPARAISON EST PAR CLASSE, PAS PAR COUPLE. Une classe est transitive : dans une
## chute de six, le chapiteau et le corps 1 ne se touchent jamais directement, et pourtant
## leurs bords portent le meme profil par la chaine qui les relie. Couple a couple, une
## derive qui s accumule le long de la chaine passerait inapercue.
##
## ⚠ ET LES DEUX AXES SONT ICI. L egalite laterale des flancs muets vivait dans
## `_check_wall_side_seams`, avec sa propre idee de ce qui doit etre egal ; deux endroits
## pour une seule regle finissent toujours par se contredire. Il ne lui reste que les trous.
func _check_wall_seams(ink: GuideImage.Ink, marks: bool, label: String) -> void:
	var live: Array[Vector2i] = Families.wall_roles()
	var tiles: Dictionary = {}
	var seat: Dictionary = {}
	for role: Vector2i in live:
		tiles[role] = GuideImage.make_wall(role, SEAM_TILE, ink, marks)
		for side: int in range(4):
			seat[Vector3i(role.x, role.y, side)] = true

	var classes: Dictionary = {}
	for edge: Vector3i in seat:
		var best: Vector3i = edge
		for other: Vector3i in (Seams.GROUPS[edge] as Array):
			if not seat.has(other):
				continue
			if other.x < best.x or (other.x == best.x and (other.y < best.y
					or (other.y == best.y and other.z < best.z))):
				best = other
		if not classes.has(best):
			var fresh: Array[Vector3i] = []
			classes[best] = fresh
		(classes[best] as Array[Vector3i]).append(edge)

	var worst: float = 0.0
	var worst_pair: String = ""
	var guilty: Array[String] = []
	var compared: int = 0
	for rep: Vector3i in classes:
		var members: Array[Vector3i] = classes[rep]
		if members.size() < 2:
			continue
		var head: Vector3i = members[0]
		var reference: PackedColorArray = _edge_profile(
				tiles[Vector2i(head.x, head.y)] as Image, head.z)
		for k: int in range(1, members.size()):
			var edge: Vector3i = members[k]
			var mine: PackedColorArray = _edge_profile(
					tiles[Vector2i(edge.x, edge.y)] as Image, edge.z)
			compared += 1
			var gap: float = 0.0
			for i: int in range(mine.size()):
				var one: Color = reference[i]
				var two: Color = mine[i]
				gap = maxf(gap, maxf(maxf(absf(one.r - two.r), absf(one.g - two.g)),
						maxf(absf(one.b - two.b), absf(one.a - two.a))))
			if gap > worst:
				worst = gap
				worst_pair = "%s / %s" % [_edge_name(head), _edge_name(edge)]
			if gap > WALL_SEAM_TOLERANCE:
				guilty.append("%s | %s (%.1f%%)" % [_edge_name(head), _edge_name(edge),
						gap * 100.0])
	print("  %s : %d classes de bords, %d comparaisons, le pire %.1f%% (%s)"
			% [label, classes.size(), compared, worst * 100.0, worst_pair])
	if guilty.size() > 0:
		print("    %s" % ", ".join(guilty.slice(0, mini(6, guilty.size()))))
	_check(worst <= WALL_SEAM_TOLERANCE,
			"%s : les bords d une meme classe portent le MEME profil (le pire : %.1f%%, %d fautifs)"
			% [label, worst * 100.0, guilty.size()])


## Les pixels d un bord, lus dans le sens de la pose : jamais retournes.
func _edge_profile(tile: Image, side: int) -> PackedColorArray:
	var out: PackedColorArray = PackedColorArray()
	var last: int = SEAM_TILE - 1
	for i: int in range(SEAM_TILE):
		match side:
			Seams.TOP:
				out.append(tile.get_pixel(i, 0))
			Seams.BOTTOM:
				out.append(tile.get_pixel(i, last))
			Seams.LEFT:
				out.append(tile.get_pixel(0, i))
			_:
				out.append(tile.get_pixel(last, i))
	return out


func _edge_name(edge: Vector3i) -> String:
	var sides: Array[String] = ["haut", "bas", "gauche", "droite"]
	return "%s %s %s" % [Walls.pan_name(edge.x), Walls.ROW_NAMES[edge.y], sides[edge.z]]


## LES ROBES, FLANC CONTRE FLANC.
##
## Deux cases de robe cote a cote decrivent la meme frontiere : ce que l'une met a son bord
## est, l'autre le met a son bord ouest. Mais elles ne doivent pas toujours dire la MEME
## chose, et c'est tout l'interet du vocabulaire a neuf pans.
##
## ⚠ « DEUX FLANCS MUETS SIGNIFIENT LA MEME RANGEE » ETAIT FAUX, et ce test le supposait.
## Deux colonnes d'une meme levre peuvent avoir des chutes differentes -- l'une atterrit sur
## une banquette pendant que l'autre continue -- et un `pied` se retrouve alors contre un
## `corps 1`. Le recensement en a compte 16 couples, que ce test sautait d'une ligne.
##
## ⚠ ET L EGALITE DES PROFILS N EST PLUS ICI. Elle vit dans `_check_wall_seams`, sur les
## classes de `Seams` elles-memes : une seule regle, un seul endroit. Il ne reste donc a ce
## test que ce que lui seul sait faire -- chercher les TROUS.
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
					if same_face:
						flush += 1
					else:
						stepped += 1

	print("  %s : %d raccords de paroi continue, %d au droit d une arete" % [label, flush,
			stepped])
	_check_equal(holes.size(), 0,
			"%s : aucun trou entre deux robes voisines%s" % [label, _first_few(holes)])


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
	print("familles : le catalogue, et les carnets qui ne se melangent jamais")
	# ⚠ UNE SEULE FAMILLE AU CATALOGUE, ET C EST CELLE DES MASSIFS. Les deux anciens
	# reseaux -- par case et a cheval -- ont quitte le produit : le modele des massifs n a
	# qu un vocabulaire, et offrir un choix qui n en est plus un ferait chercher a l acheteur
	# une decision qu il n a pas a prendre (charte, regle 1). Leurs constantes survivent le
	# temps que l ancien noyau soit demonte, et cette suite s en sert encore comme temoins.
	_check_equal(Families.ids().size(), 1, "une seule famille au catalogue")
	_check_equal(Families.ids()[0], Families.BY_MASSIF, "et c est celle des massifs")
	_check_equal(Families.key_letter(Families.BY_MASSIF), "M", "une tuile de massif s ecrit M")
	_check_equal(Families.surface_tile_count(Families.BY_MASSIF)
			+ Families.massif_skirts().size(), Families.massif_tiles().size(),
			"surfaces et jupes se partagent le vocabulaire, sans reste")

	var live: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MASSIFS))
	_check(Families.is_covered(Families.BY_MASSIF, live),
			"le guide livre couvre la famille « %s »"
			% Families.label(Families.BY_MASSIF))

	# LES TEMOINS DE L ANCIEN MODELE, tant que son noyau est au depot.
	_check_equal(Families.surface_tile_count(Families.BY_CELL), Thickness.SURFACE_INDICES.size(),
			"par case : 27 tuiles")
	_check_equal(Families.surface_tile_count(Families.BY_CORNER), CornerIndex.TILE_COUNT,
			"a cheval : 15 tuiles")
	_check_equal(Families.key_letter(Families.BY_CELL), "S", "la surface par case s ecrit S")
	_check_equal(Families.key_letter(Families.BY_CORNER), "C", "le croisement s ecrit C")

	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	for family: StringName in [Families.BY_CELL, Families.BY_CORNER] as Array[StringName]:
		_check(Families.is_covered(family, heights),
				"le guide epais couvre la famille « %s »" % Families.label(family))

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
	_check(Walls.analyse(relief, Thickness.wall_roles())["is_complete"], "et les 44 roles de falaise")
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
	_check_equal(firsts.size(), CornerIndex.TILE_COUNT + Thickness.wall_roles().size(),
			"a cheval, le guide porte 15 + 25 = %d tuiles obligatoires"
			% (CornerIndex.TILE_COUNT + Thickness.wall_roles().size()))

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
		"pan west_times_two_plus_east lip_row_comparison per_row",
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
## LES RACCORDS OBLIGATOIRES : le meme point de roche, vu dans deux tuiles.
##
## ⚠ CE TEST NE VERIFIE PAS QUE LE DESSIN EST JUSTE, IL VERIFIE QU IL NE PEUT PAS ETRE
## FAUX. `_test_seams` mesure les raccords d une illustration deja faite ; celui-ci peint
## n importe quoi, en propageant comme l editeur, et exige que les raccords sortent exacts
## quand meme. C est la difference entre controler et garantir.
func _test_seam_propagation() -> void:
	print("les raccords obligatoires : le meme pixel, vu dans deux tuiles")

	# --- LA STRUCTURE, telle que le modele la deduit.
	var tally: Dictionary = Seams.tally()
	_check_equal(int(tally["edges"]), Walls.PAN_COUNT * Walls.BLOCK_ROWS * 4,
			"les quatre bords de chaque tuile de robe sont recenses")
	_check(int(tally["linked"]) > 0, "et une bonne part est LIEE (%d sur %d)"
			% [int(tally["linked"]), int(tally["edges"])])
	_check(Seams.row_chains().size() > 0,
			"les enchainements de rangees se lisent des chutes reelles (%d)"
			% Seams.row_chains().size())

	# ⚠ UN PIXEL INTERIEUR N OBLIGE RIEN. Seuls les BORDS se touchent.
	var side: int = 16
	_check(Seams.mirrors(Vector2i(4, 1), side / 2, side / 2, side).is_empty(),
			"un pixel interieur ne propage rien : seuls les bords se touchent")

	# --- ON PEINT N IMPORTE QUOI, EN PROPAGEANT.
	var painting: Painting = Painting.new(side)
	var cell_of: Dictionary = {}
	var next: int = 0
	for role: Vector2i in Walls.ALL_ROLES:
		cell_of[role] = Vector2i(next, 0)
		next += 1
	for role: Vector2i in Walls.ALL_ROLES:
		for y: int in range(side):
			for x: int in range(side):
				# Une teinte qui ne doit RIEN a la structure des raccords : si le resultat
				# est continu, c est la propagation qui l a fait, pas le choix des couleurs.
				var tint: Color = _key_colour("%d,%d,%d,%d" % [role.x, role.y, x, y])
				painting.paint(cell_of[role], x, y, tint)
				for echo: Vector4i in Seams.mirrors(role, x, y, side):
					painting.paint(cell_of[Vector2i(echo.x, echo.y)], echo.z, echo.w, tint)

	# --- ET LES DEUX CONTRAINTES DOIVENT TENIR, SANS UNE RETOUCHE.
	# ⚠ ET L EGALITE NE VAUT QUE LA OU LES DEUX TUILES ONT DE LA ROCHE. L ancien contrat
	# disait « la derniere ligne EST la premiere », sur toute la largeur -- il supposait une
	# case de falaise pleine d un bord a l autre. Des qu on y trace un contour, la part au-dela
	# d un flanc `vide` est DEHORS, et forcer l egalite y ecrivait de la matiere dans le
	# transparent du voisin : le defaut des « tirets ».
	var vertical: int = 0
	var vertical_seen: int = 0
	for pair: Vector2i in Seams.row_chains():
		for pan: int in range(Walls.PAN_COUNT):
			var upper: Image = painting.image_of(cell_of[Vector2i(pan, pair.x)])
			var lower: Image = painting.image_of(cell_of[Vector2i(pan, pair.y)])
			for x: int in range(side):
				if not Seams.is_rock(Vector2i(pan, pair.x), Seams.BOTTOM, x, side):
					continue
				if not Seams.is_rock(Vector2i(pan, pair.y), Seams.TOP, x, side):
					continue
				vertical_seen += 1
				if upper.get_pixel(x, side - 1) != lower.get_pixel(x, 0):
					vertical += 1
	_check_equal(vertical, 0,
			"UNE FALAISE EST UNE FACE : la derniere ligne d une rangee EST la premiere de la suivante")
	# ⚠ ET LA MESURE DOIT AVOIR VU QUELQUE CHOSE. Une restriction qui ne laisserait rien a
	# comparer passerait au vert en ne prouvant rien -- meme piege que partout ailleurs ici.
	_check(vertical_seen > 0, "et la comparaison a vraiment porte (%d pixels)" % vertical_seen)

	var horizontal: int = 0
	for row: int in range(Walls.BLOCK_ROWS):
		for left: int in range(Walls.PAN_COUNT):
			if Walls.pan_east(left) != Walls.SIDE_MUTE:
				continue
			for right: int in range(Walls.PAN_COUNT):
				if Walls.pan_west(right) != Walls.SIDE_MUTE:
					continue
				var a: Image = painting.image_of(cell_of[Vector2i(left, row)])
				var b: Image = painting.image_of(cell_of[Vector2i(right, row)])
				for y: int in range(side):
					# Les bords lateraux gardent leur etendue pleine : une face va du haut au
					# bas de sa case, c est la chute qui la borne, pas le dessin.
					if a.get_pixel(side - 1, y) != b.get_pixel(0, y):
						horizontal += 1
	_check_equal(horizontal, 0,
			"DEUX FLANCS MUETS SONT LA MEME PAROI : leurs colonnes mitoyennes sont identiques")

	# ⚠ ET LA PROPAGATION NE DEBORDE PAS. La ou une arete est ATTENDUE -- un flanc qui dit
	# `devant` -- rien ne doit avoir ete recopie : le modele n y prouve aucune egalite, et
	# forcer les pixels y accuserait le dessin de faire ce qu on lui demande.
	var overreach: int = 0
	for row: int in range(Walls.BLOCK_ROWS):
		for pan: int in range(Walls.PAN_COUNT):
			if Walls.pan_east(pan) != Walls.SIDE_FRONT:
				continue
			for echo: Vector4i in Seams.mirrors(Vector2i(pan, row), side - 1, 3, side):
				if echo.z == 0:
					overreach += 1
	_check_equal(overreach, 0,
			"la ou une ARETE est attendue, rien n est recopie : on ne prouve pas l egalite la")

	# ⚠ ET RIEN N EST JAMAIS ECRIT DANS LE DEHORS D UNE TUILE. C est la propriete que le
	# defaut des « tirets » a fait ajouter : remplir une tuile tachait le transparent de sa
	# voisine et toute la chute, parce que les classes verticales joignaient le bord ENTIER
	# alors que deux pans n ont pas leur roche au meme endroit lateralement.
	var into_the_void: int = 0
	var writes: int = 0
	for role: Vector2i in Walls.ALL_ROLES:
		for x: int in range(side):
			for y: int in range(side):
				if x != 0 and x != side - 1 and y != 0 and y != side - 1:
					continue
				for echo: Vector4i in Seams.mirrors(role, x, y, side):
					writes += 1
					var other: Vector2i = Vector2i(echo.x, echo.y)
					var edge: int = -1
					if echo.w == 0:
						edge = Seams.TOP
					elif echo.w == side - 1:
						edge = Seams.BOTTOM
					if edge < 0:
						continue
					if not Seams.is_rock(other, edge, echo.z, side):
						into_the_void += 1
	_check_equal(into_the_void, 0,
			"la propagation n ecrit JAMAIS dans le dehors du destinataire (%d ecritures)"
			% writes)


## LES RACCORDS D'ILOTS : les 8, prouves dans les deux sens.
##
## ⚠ C'EST LE DEFAUT QUE L'UTILISATEUR A DESIGNE CASE PAR CASE. Deux ilots colles a des
## hauteurs differentes : le contour du haut voudrait mordre une demi-case dans la tuile de
## bord du voisin pour se refermer, et ne peut pas -- cette tuile est partagee, le bout de
## trait s'y repliquerait partout. La forme fermee dit combien de situations distinctes il
## faut dessiner : huit, et le test le prouve.
func _test_junctions() -> void:
	print("les raccords d ilots : ou le contour du haut quitte celui du bas")
	_check_equal(Junctions.SIGNATURES.size(), 8, "la forme fermee donne exactement 8 raccords")

	# ⚠ ET CHAQUE SIGNATURE A LA FORME QUE LE THEOREME ANNONCE : le haut est un COIN -- deux
	# cotes adjacents -- et le bas est l un de ses deux cotes. Le verifier ici, c est refuser
	# que la liste soit juste par hasard.
	for signature: Vector2i in Junctions.SIGNATURES:
		var high: int = signature.y
		var low: int = signature.x
		_check(_popcount(high) == 2, "%s : le haut porte deux cotes"
				% Junctions.name_of(signature))
		_check((high & Junctions.N) == 0 or (high & Junctions.S) == 0,
				"%s : jamais nord et sud ensemble" % Junctions.name_of(signature))
		_check((high & Junctions.E) == 0 or (high & Junctions.O) == 0,
				"%s : jamais est et ouest ensemble" % Junctions.name_of(signature))
		_check(_popcount(low) == 1 and (low & ~high) == 0,
				"%s : le bas est l un des deux cotes du haut" % Junctions.name_of(signature))

	# --- SENS 1 : chaque cas se rencontre-t-il sur un vrai relief ?
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x8ACC0
	var seen: Dictionary = {}
	var strays: Dictionary = {}
	var scanned: int = 0
	var total: int = 0
	for round: int in range(900):
		var relief: PackedStringArray = _random_thick_relief(rng)
		if relief.is_empty():
			continue
		scanned += 1
		for signature: Vector2i in Junctions.map(relief).values():
			total += 1
			if Junctions.is_known(signature):
				seen[signature] = true
			else:
				strays[signature] = int(strays.get(signature, 0)) + 1
	_check_equal(seen.size(), Junctions.SIGNATURES.size(),
			"les 8 se rencontrent tous (%d reliefs epais, %d raccords)" % [scanned, total])
	_check_equal(strays.size(), 0, "et le monde n en produit aucun autre")

	# --- SENS 2 : et sur le guide livre, qui n est pas du hasard.
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var on_guide: int = 0
	var wild: int = 0
	for signature: Vector2i in Junctions.map(guide).values():
		on_guide += 1
		if not Junctions.is_known(signature):
			wild += 1
	_check_equal(wild, 0, "le guide n en produit aucun hors forme (%d raccords)" % on_guide)

	# ⚠ ET LE THEOREME QUI TRANCHE « PAR TUILE OU PAR COTE » : les cotes ouverts du bas sont
	# TOUJOURS inclus dans ceux du haut, parce qu un voisin plus bas que L l est aussi que
	# L+1. Il ne peut donc jamais exister un cote « mer ouverte » en bas que le haut ne suive
	# pas -- donc un drapeau par tuile suffit, et ce n est pas une observation.
	var nested: int = 0
	for round: int in range(120):
		var relief: PackedStringArray = _random_thick_relief(rng)
		if relief.is_empty():
			continue
		var top: int = HeightMask.top_level(relief)
		for level: int in range(1, top + 1):
			for y: int in range(HeightMask.height(relief)):
				for x: int in range(HeightMask.width(relief)):
					if HeightMask.level_at(relief, x, y) < level + 1:
						continue
					var low: int = Junctions.open_sides(relief, x, y, level)
					var high: int = Junctions.open_sides(relief, x, y, level + 1)
					if (low & ~high) != 0:
						nested += 1
	_check_equal(nested, 0,
			"les cotes du bas sont toujours inclus dans ceux du haut : un drapeau par tuile suffit")


func _popcount(mask: int) -> int:
	var count: int = 0
	for bit: int in range(4):
		if (mask & (1 << bit)) != 0:
			count += 1
	return count


func _test_underfoot() -> void:
	print("la pose derriere : la roche continue derriere les coins decoupes")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MINIMAL))
	var under: Dictionary = Walls.visible_underfoot(heights)
	_check(under.size() > 0, "le guide pose des sous-pieds (%d)" % under.size())

	# ⚠ LE CHAPITEAU SOUS SA LEVRE (v6) : chaque levre porte, sous sa surface, la premiere
	# rangee de SA propre chute -- le vrai flanc de la vraie face de chaque occurrence.
	# C'est la pose qui rend honnetes les marges transparentes du peintre au bord sud.
	var lips_total: int = 0
	var lips_backed: int = 0
	var lips_exact: int = 0
	var roles_map: Dictionary = Walls.visible_roles(heights)
	for y: int in range(HeightMask.height(heights)):
		for x: int in range(HeightMask.width(heights)):
			var level: int = HeightMask.level_at(heights, x, y)
			if level < 0 or HeightMask.level_at(heights, x, y + 1) >= level:
				continue
			lips_total += 1
			var lip: Vector2i = Vector2i(x, y)
			if not under.has(lip):
				continue
			lips_backed += 1
			var south: Vector2i = lip + Vector2i(0, 1)
			if roles_map.has(south) and under[lip] == roles_map[south]:
				lips_exact += 1
	_check(lips_total > 0, "le guide a des levres (%d)" % lips_total)
	_check_equal(lips_backed, lips_total,
			"CHAQUE levre porte sa face reposee sous elle (%d/%d)" % [lips_backed, lips_total])
	_check(lips_exact > lips_total / 2,
			"et la rangee reposee est celle que la chute montre juste dessous (%d/%d)"
			% [lips_exact, lips_total])

	# Une case d'atterrissage au NORD DECOUPE : son voisin nord est la face, ses coins
	# nord laissent voir derriere -- c'est la que le defaut se voyait. (La case isolee de
	# l'ancien guide est morte avec le mode epais : l'ilot d'une case n'existe plus.)
	var target: Vector2i = Vector2i(-1, -1)
	for cell: Vector2i in under.keys():
		if HeightMask.level_at(heights, cell.x, cell.y) >= 1 \
				and (Coverage.visible_index_at(heights, cell.x, cell.y)
				& (BlobIndex.N | BlobIndex.W)) == 0:
			target = cell
			break
	_check(target.x >= 0, "et le guide en offre une au nord-ouest decoupe, ou le defaut se voyait")
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

	# ⚠ ET LE MEME PIXEL SE LIT DERRIERE UNE CASE QUI ECRETE -- l'angle noir d'hier. Le
	# coin nord d'un pilier isole, plante devant une face qui n'atterrit pas sur lui, doit
	# montrer la roche du corps qui continue derriere, plus jamais l'herbe ni le fond.
	var behind: Vector2i = Vector2i(-1, -1)
	for cell: Vector2i in under.keys():
		if (under[cell] as Vector2i).y != Walls.ROW_FOOT \
				and HeightMask.level_at(heights, cell.x, cell.y) >= 1 \
				and (Coverage.visible_index_at(heights, cell.x, cell.y)
				& (BlobIndex.N | BlobIndex.W)) == 0:
			behind = cell
			break
	_check(behind.x >= 0, "le guide offre une case au nord-ouest decoupe qui ecrete une robe")
	if behind.x >= 0:
		var notch: Color = image.get_pixel(behind.x * side + 1, behind.y * side + 1)
		var grass: Color = image.get_pixel(behind.x * side + side / 2,
				behind.y * side + side / 2)
		_check(notch.r > notch.g,
				"SON COIN NORD-OUEST EST DE LA ROCHE : la face continue derriere lui")
		_check(grass.g > grass.r, "et son sommet reste de l herbe")

	# ⚠ ET LA POSE DERRIERE N'AJOUTE AUCUNE TUILE. Pied ou corps, tout ce qui se repose
	# est l'un des 36 roles -- s'il en reclamait un autre, il faudrait le peindre, et
	# aucune case du guide ne pourrait le porter. Et chaque sorte dit ce qu'elle prouve :
	# le PIED ne se repose que sous une case d'ATTERRISSAGE (du sol plus bas que la
	# levre), le CORPS que sous une case DE L'ETAGE DE LA LEVRE, celle qui ecrete, et la
	# PREMIERE RANGEE (v6) que sous une LEVRE -- la case d'ou sa propre chute part.
	var known: Dictionary = {}
	for role: Vector2i in Walls.ALL_ROLES:
		known[role] = true
	var strays: int = 0
	var feet: int = 0
	var bodies: int = 0
	var crowns: int = 0
	var wrong_kind: int = 0
	var assembled: Dictionary = Walls.assemble(heights)["underfoot"]
	for key: Vector3i in assembled.keys():
		var role: Vector2i = assembled[key]
		if not known.has(role):
			strays += 1
		var cell_level: int = HeightMask.level_at(heights, key.x, key.y)
		var south_level: int = HeightMask.level_at(heights, key.x, key.y + 1)
		var is_lip: bool = cell_level >= key.z and south_level < key.z
		if is_lip:
			# La pose de levre : la premiere rangee de SA chute -- chapiteau d'ordinaire,
			# pied pour une chute d'une case qui atterrit.
			crowns += 1
		elif role.y == Walls.ROW_FOOT:
			feet += 1
			if cell_level >= key.z:
				wrong_kind += 1
		elif role.y >= 1 and role.y <= Walls.BODY_ROWS:
			# ⚠ « corps 0 ou corps 1 » ETAIT ECRIT EN DUR. A trois rangees de corps, la
			# pose derriere d'un pas 4 rend le corps 2, que ce test rangeait dans « ni pied
			# ni corps » -- il accusait le modele d'une faute qu'il n'a pas.
			bodies += 1
			if cell_level != key.z:
				wrong_kind += 1
		else:
			wrong_kind += 1
	_check(crowns > 0, "et chaque levre porte sa premiere rangee sous elle (%d)" % crowns)
	_check_equal(strays, 0, "AUCUNE TUILE DE PLUS : toute pose derriere est l un des %d roles"
			% Walls.ALL_ROLES.size())
	_check(feet > 0, "le guide repose des pieds sous ses atterrissages (%d)" % feet)
	_check(bodies > 0, "et des corps derriere ses cases qui ecretent (%d)" % bodies)
	_check_equal(wrong_kind, 0,
			"le pied dit l atterrissage, le corps dit l ecretage, jamais l inverse")


func _test_backing() -> void:
	print("la pose derriere : ecretage, atterrissage, et les cas ou l on ne pose rien")
	# La geometrie du defaut, nue : une masse d'etage 2, UNE case de creux, un pilier du
	# MEME etage. La robe de la masse est ecretee au premier pas.
	var pillar: PackedStringArray = HeightMask.parse("..2..
..2..
..1..
..2..
..1..
..1..
..1..
..1..
..1..
..1..
..1..
..1..
..1..")
	_check_equal(Walls.fall_at(pillar, 2, Vector2i(2, 1)), Vector2i(1, 0),
			"la robe de la masse est ecretee a une case, sans pied")
	var assembled: Dictionary = Walls.assemble(pillar)
	var under: Dictionary = assembled["underfoot"]
	var roles: Dictionary = assembled["roles"]
	_check_equal(under.get(Vector3i(2, 3, 2)),
			Vector2i(Walls.pan_of(Walls.SIDE_VOID, Walls.SIDE_VOID), 1),
			"le CORPS 0 du pas suivant se repose sous le pilier, au pan de la derniere rangee")
	_check(not roles.has(Vector3i(2, 3, 2)),
			"et le pilier ne devient pas une case de robe : la pose sort a part")
	_check_equal(under.get(Vector3i(2, 7, 2)),
			Vector2i(Walls.pan_of(Walls.SIDE_VOID, Walls.SIDE_VOID), Walls.ROW_FOOT),
			"la robe du pilier, elle, atterrit : son PIED se repose comme avant")

	# Un creux de deux cases : la rangee de la continuation alterne, comme dans une chute.
	var deeper: PackedStringArray = HeightMask.parse("..2..
..2..
..1..
..1..
..2..
..1..
..1..
..1..
..1..
..1..
..1..
..1..
..1..")
	_check_equal(Walls.fall_at(deeper, 2, Vector2i(2, 1)), Vector2i(2, 0),
			"deux cases de creux : ecretee a deux")
	_check_equal((Walls.assemble(deeper)["underfoot"] as Dictionary).get(Vector3i(2, 4, 2)),
			Vector2i(0, 2), "et c est le CORPS 1 qui continue derriere : la rangee alterne")

	# Ecretee a PLEINE longueur : le blocage est a la case sondee sous le pied.
	var brink: PackedStringArray = HeightMask.parse("..2..
..1..
..1..
..1..
..2..
..1..
..1..
..1..
..1..
..1..
..1..
..1..")
	_check_equal(Walls.fall_at(brink, 2, Vector2i(2, 0)), Vector2i(3, 0),
			"la chute fait sa longueur entiere mais ne pose pas son pied")
	_check_equal((Walls.assemble(brink)["underfoot"] as Dictionary).get(Vector3i(2, 4, 2)),
			Vector2i(0, Walls.row_for(4, 4, false)),
			"le corps du pas 4 se repose sous la case qui l ecrete (%s)"
			% Walls.ROW_NAMES[Walls.row_for(4, 4, false)])

	# ⚠ PLUS HAUTE QUE LA LEVRE : RIEN. Le sommet du bloc depasse la face ; derriere ses
	# coins c'est l'etage d'en dessous, que l'empilement montre deja.
	var taller: PackedStringArray = HeightMask.parse("..1..
.....
..2..
.....
.....
.....
.....
.....
.....
.....")
	_check_equal(Walls.fall_at(taller, 1, Vector2i(2, 0)), Vector2i(1, 0),
			"la robe de la masse basse est bien ecretee par le bloc haut")
	# ⚠ Depuis la pose de levre (v6), la case haute porte quand meme SA PROPRE premiere
	# rangee -- elle est une levre elle aussi -- mais jamais le corps de la robe ecretee.
	var taller_entry: Vector2i = (Walls.assemble(taller)["underfoot"] as Dictionary).get(
			Vector3i(2, 2, 1), Vector2i(0, Walls.ROW_CROWN))
	_check_equal(taller_entry.y, Walls.ROW_CROWN,
			"mais RIEN de la robe ecretee ne se repose sous une case plus haute que la levre")

	# ⚠ ET UNE ROBE QUI TOMBE DANS LE VIDE NE POSE RIEN NON PLUS : il n'y a pas de case
	# derriere laquelle continuer.
	var rim: PackedStringArray = HeightMask.parse("..1..
~~~~~
~~~~~
~~~~~")
	_check_equal(Walls.fall_at(rim, 1, Vector2i(2, 0)).y, 0,
			"la robe du bord tombe sans atterrir")
	var rim_under: Dictionary = Walls.assemble(rim)["underfoot"]
	var rim_backing: int = 0
	for key: Vector3i in rim_under.keys():
		if (rim_under[key] as Vector2i).y != Walls.ROW_CROWN:
			rim_backing += 1
	_check_equal(rim_backing, 0,
			"et aucune pose derriere n en sort -- seule sa levre porte sa premiere rangee")

	# ⚠ ET LA COMPARAISON AU PLUGIN A QUITTE CE TEST AVEC LE MODELE QU ELLE CONTROLAIT. La
	# POSE DERRIERE n existe plus : puisque le massif du dessus est au ras partout, celui du
	# dessous n emerge jamais en plein milieu d une tuile, il emerge a une bordure. Il n y a
	# donc plus rien a boucher, et `_test_plugin_rules` compare desormais des POSES.


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
	# Un seul mode desormais : le second paysage est le decor de l apercu, qui a autant
	# le droit d etre distinct dans chaque encre et chaque etat de marques.
	for relief_path: String in [Modes.guide_path(Modes.EPAIS), "res://guides/preview.txt"]:
		var relief: PackedStringArray = HeightMask.read(relief_path)
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
	print("  couverture %d/%d" % [present.size(), Thickness.SURFACE_INDICES.size()])
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


# --- SoluPaint : le plugin moteur ------------------------------------------

## ⚠ LE PLUGIN PORTE UNE COPIE DE LA REGLE, ET C'EST INEVITABLE : il part chez l acheteur,
## dans SON projet, ou `res://core/` n existe pas. La question n est donc pas « comment
## eviter la copie » mais « comment prouver que les deux disent la meme chose ». Ce test est
## la reponse, et c est le seul endroit du depot ou elle existe.
##
## ⚠ ON COMPARE LES TROIS VOCABULAIRES, PAS UN SEUL. Une divergence sur les robes ne se
## verrait jamais en ne comparant que les index de surface -- et c est justement la que la
## regle est la plus subtile, puisque le pan depend de la levre du voisin.
## LE MODE D EMPLOI NE PARAPHRASE PAS LE CONTRAT, IL LE LIT.
##
## ⚠ UN SECOND ENDROIT OU DIRE LA REGLE EST UN SECOND ENDROIT OU MENTIR. Le niveau 3 du
## manuel est la regle de pose ligne par ligne ; s'il en gardait sa propre copie, une clause
## qui bouge laisserait les deux textes en desaccord SANS QUE RIEN NE LE SIGNALE -- exactement
## le defaut que le manifeste existe pour supprimer. Il lit donc `placement_rules()`, la meme
## fonction qui ecrit le fichier, et ce test le prouve : chaque ligne rendue se retrouve
## telle quelle dans un manifeste vraiment ecrit.
func _test_manual() -> void:
	print("Mode d emploi : le niveau 3 est le contrat lui-meme")

	var manual: Script = load("res://ui/manual.gd")
	_check(manual != null and manual.can_instantiate(),
			"le mode d emploi s analyse et s instancie")

	# ⚠ ET C EST LE CONTRAT DU MODELE LIVRE QU IL LIT, pas celui d un modele retire. Le
	# manuel n en garde aucune copie : il met en forme les lignes que l exportateur ecrit.
	var rules: PackedStringArray = MassifTileset.placement_rules()
	_check(rules.size() > 20, "la regle de pose fait plus de vingt lignes (%d)" % rules.size())

	var folder: String = "user://manuel"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MASSIFS))
	var painting: Painting = MassifTrial.paint(heights)
	_check_equal(String(MassifTileset.write(painting, heights, Modes.MASSIFS, folder,
			"manuel")["error"]), "", "un manifeste s ecrit, pour avoir de quoi comparer")
	var manifest: String = FileAccess.get_file_as_string(
			folder.path_join("manuel_tileset.txt"))

	# ⚠ CE TEST EST RETOURNE, ET C'EST LE POINT (decision utilisateur du 04/09/2026). Il
	# verifiait que les lignes du manuel se trouvent DANS le manifeste, mot pour mot. Le
	# manifeste ne porte plus la regle : elle vit dans le moteur, et se fournit sous licence a
	# qui veut ecrire le sien. Ce qui etait la garantie devient donc la faute a surveiller.
	#
	# ⚠ ET CA N'AFFAIBLIT AUCUNE JUSTESSE. Ce qui garantit que deux moteurs s'accordent, c'est le
	# CONTROLE CROISE -- reliefs exhaustifs, compares dans les deux sens -- jamais la prose du
	# fichier. Celle-ci n'etait que de la documentation, utile a qui veut REIMPLEMENTER.
	var leaked: int = 0
	var first: String = ""
	for line: String in rules:
		var clean: String = line.strip_edges()
		# On ne cherche que les CLAUSES, pas les commentaires : un `#` peut coincider par
		# hasard, une clause non.
		if clean.is_empty() or clean.begins_with("#"):
			continue
		if manifest.find(clean) != -1:
			leaked += 1
			if first.is_empty():
				first = clean
	_check_equal(leaked, 0,
			"le manifeste ne porte AUCUNE clause de la regle de pose%s"
			% ("" if first.is_empty() else " (fuite : %s)" % first))

	# ⚠ MAIS IL DOIT GARDER DE QUOI REFUSER. Sans `fall_rows` ni `tiles`, un lecteur ne peut
	# plus distinguer un tileset qui n'est pas le sien -- et un monde faux qui ne se signale pas
	# est le pire des defauts.
	_check(manifest.contains("fall_rows "), "mais il garde `fall_rows`, qui sert a refuser")
	_check(manifest.contains("tiles "), "et `tiles`, pour la meme raison")

	# ET LE MODE D'EMPLOI, LUI, LA PORTE TOUJOURS -- lue a la source, jamais recopiee.
	var carries: bool = false
	for line2: String in rules:
		if line2.begins_with("void "):
			carries = true
	_check(carries, "et le manuel porte bien la clause du vide, pas seulement l en-tete")

	_wipe(folder)


func _test_plugin_rules() -> void:
	print("SoluPaint : la regle du plugin est CELLE DU NOYAU, pose pour pose")

	_check_equal(PluginRules.FALL, Massifs.FALL, "meme hauteur d etage")
	_check_equal(PluginRules.COVERS, Massifs.COVERS,
			"meme rangement du bit de contexte au-dessus de la bande")
	_check_equal(PluginManifest.MASSIF_TILES, Families.massif_tiles().size(),
			"et le plugin annonce le meme vocabulaire que le noyau (%d tuiles)"
			% Families.massif_tiles().size())

	# Les 256 voisinages bruts : la canonicalisation doit tomber au meme endroit, toujours.
	var canon_strays: int = 0
	for raw: int in range(256):
		if PluginRules.canonicalise(raw) != BlobIndex.canonicalize(raw):
			canon_strays += 1
	_check_equal(canon_strays, 0, "les 256 voisinages bruts se canonicalisent pareil")

	var seen: Dictionary = {}

	# EXHAUSTIF sur les reliefs binaires 3x4 : 4096 mondes, aucun tirage au sort.
	var drift: int = 0
	for pattern: int in range(1 << 12):
		drift += _plugin_drift(_relief_of(pattern, 3, 4), seen)
	_check_equal(drift, 0,
			"les 4096 reliefs binaires 3x4 : le plugin et le noyau ne divergent jamais")

	# ⚠ ET EXHAUSTIF SUR TROIS ETATS, PARCE QUE LE MONDE EN A TROIS. Un relief binaire ne
	# pose jamais de VIDE -- or c est lui qui distingue « case a l etage 0 » de « case hors
	# du monde », donc la falaise du bord du monde et la chute qui ne pose pas son pied. Une
	# battue qui ne pose pas de vide ne cherche pas dans tous les cas.
	var ternary: int = 0
	for pattern2: int in range(_pow(3, 9)):
		ternary += _plugin_drift(_relief_of3(pattern2, 3, 3), seen)
	_check_equal(ternary, 0,
			"les 19683 reliefs 3x3 a trois etats -- vide, plaine, plateau : aucune divergence")

	# ⚠ ET SUR LE RELIEF REEL, CELUI QUI PART CHEZ L ACHETEUR. Le tirage au sort ne rencontre
	# pas tout le vocabulaire : les tuiles les plus rares demandent une forme voulue, pas un
	# accident. Le guide les porte toutes par construction -- c est donc lui, et pas le
	# hasard, qui fait de cette battue une vraie battue.
	var on_guide: int = _plugin_drift(HeightMask.read(Modes.guide_path(Modes.MASSIFS)), seen)
	_check_equal(on_guide, 0, "sur le guide livre : aucune divergence")

	# ET AU HASARD, du relief a etages TROUE DE VIDE -- c est la que les chutes se compliquent.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260903
	var wild: int = 0
	for _attempt: int in range(PLUGIN_RANDOM_RELIEFS):
		wild += _plugin_drift(_holed_relief(rng, 9, 9, 3), seen)
	_check_equal(wild, 0, "%d reliefs 9x9 troues de vide, tires au sort : aucune divergence"
			% PLUGIN_RANDOM_RELIEFS)

	# ⚠ ET LA BATTUE DOIT AVOIR VRAIMENT CHERCHE. Une comparaison qui ne rencontre aucune
	# falaise ne prouve pas que les falaises s accordent : elle prouve qu elle n en a pas vu.
	var unmet: int = 0
	for tile: int in Families.massif_tiles():
		if not seen.has(tile):
			unmet += 1
	_check_equal(unmet, 0, "la battue a rencontre les %d tuiles du vocabulaire"
			% Families.massif_tiles().size())
	# ⚠ ET CE QU ELLE RENCONTRE EN PLUS N EST PAS UNE FAUTE. Les reliefs tires au sort ne
	# respectent pas min trois : ils posent des tuiles que le pinceau ne produira jamais. On
	# le DIT plutot que de l asserter -- ce compte depend du hasard, pas du modele.
	print("  info la battue a vu %d tuiles, dont %d hors du vocabulaire du pinceau"
			% [seen.size(), seen.size() - Families.massif_tiles().size()])


## Trois puissance n, sans flottant : `pow()` rend un reel, et 3^9 arrondi au mauvais entier
## ferait sauter un monde de l enumeration exhaustive sans que rien ne le dise.
func _pow(base: int, times: int) -> int:
	var out: int = 1
	for _step: int in range(times):
		out *= base
	return out


## Un relief a TROIS etats -- vide, plaine, plateau -- enumere exhaustivement.
func _relief_of3(pattern: int, columns: int, rows_count: int) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	var left: int = pattern
	for y: int in range(rows_count):
		var line: String = ""
		for x: int in range(columns):
			var state: int = left % 3
			left /= 3
			line += "~" if state == 0 else ("." if state == 1 else "1")
		rows.append(line)
	return rows


## Un relief tire au sort, puis troue de vide. ⚠ LE VIDE NE SE TIRE PAS COMME UN ETAGE : pose
## case par case il ne fait que du bruit, et la falaise du bord du monde -- celle qu on veut
## eprouver -- demande des poches franches.
func _holed_relief(rng: RandomNumberGenerator, columns: int, rows_count: int,
		top: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for y: int in range(rows_count):
		var line: PackedByteArray = PackedByteArray()
		line.resize(columns)
		for x: int in range(columns):
			line[x] = rng.randi_range(0, top) + 1
		grid.append(line)
	for _hole: int in range(rng.randi_range(0, 3)):
		var ox: int = rng.randi_range(-1, columns - 2)
		var oy: int = rng.randi_range(-1, rows_count - 2)
		for dy: int in range(rng.randi_range(1, 3)):
			for dx: int in range(rng.randi_range(1, 3)):
				if oy + dy < 0 or ox + dx < 0 or oy + dy >= rows_count or ox + dx >= columns:
					continue
				grid[oy + dy][ox + dx] = 0
	var out: PackedStringArray = PackedStringArray()
	for row: PackedByteArray in grid:
		var said: String = ""
		for value: int in row:
			said += "~" if value == 0 else str(value - 1)
		out.append(said)
	return out


## Compte les poses ou le plugin et le noyau ne disent pas la meme chose.
## Rend 0 quand tout s accorde, et note au passage les tuiles rencontrees.
##
## ⚠ ON COMPARE LES POSES, PAS CE QUI EST VISIBLE. Une case recoit une pose par massif qui la
## contient ; ne comparer que le sommet laisserait diverger tout ce qui est enterre -- et c est
## precisement ce qu on voit a travers la transparence d une tuile.
func _plugin_drift(heights: PackedStringArray, seen: Dictionary) -> int:
	var world: Dictionary = _plugin_world(heights)
	var mine: Dictionary = {}
	for one: Dictionary in Massifs.poses(heights):
		var at: Vector2i = one["cell"]
		mine[Vector3i(at.x, at.y, int(one["level"]))] = Massifs.key_of(one)
	var theirs: Dictionary = {}
	for other: Dictionary in PluginRules.poses(world):
		var at2: Vector2i = other["cell"]
		theirs[Vector3i(at2.x, at2.y, int(other["level"]))] = PluginRules.key_of(other)
	return _compare_maps(mine, theirs, seen)


## Deux cartes case -> tuile, comparees dans les DEUX sens.
##
## ⚠ COMPARER DANS UN SEUL SENS NE PROUVE RIEN. Un plugin qui ne poserait rien du tout
## passerait un test qui se contente de verifier que ce qu il pose est juste.
func _compare_maps(mine: Dictionary, theirs: Dictionary, seen: Dictionary) -> int:
	var apart: int = 0
	for at: Variant in mine.keys():
		seen[mine[at]] = true
		if not theirs.has(at) or theirs[at] != mine[at]:
			apart += 1
	for at2: Variant in theirs.keys():
		if not mine.has(at2):
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
## L'ESSAI : LE GUIDE LUI-MEME, LIVRE COMME TILESET, ET POSE PAR LE PLUGIN.
##
## ⚠ C'EST LE SEUL TEST QUI PARCOURE LA CHAINE ENTIERE. Tous les autres en eprouvent un
## maillon : celui-ci part de l'illustration, la verse dans un carnet de peinture, la fait
## sortir par le CHEMIN NORMAL de l'export, relit le manifeste avec le lecteur DU PLUGIN,
## en fabrique un TileSet, et pose un monde. S'il passe, un game dev peut essayer.
##
## ⚠ ET IL NE PREND AUCUN CHEMIN DE TRAVERSE. `TilesetPNG.write` ne sait pas qu'il exporte
## un essai : le refus d'une feuille incomplete s'applique, donc l'essai ne sort QUE s'il
## est vraiment complet.
func _test_trial_tileset() -> void:
	print("l essai : notre propre trace, livre comme tileset, et pose par le plugin")
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MASSIFS))
	var painting: Painting = MassifTrial.paint(heights)

	# Une occurrence par tuile, pas une par case : c est tout ce que l export retient.
	_check_equal(painting.painted_cells().size(), Families.massif_tiles().size(),
			"l essai dessine exactement %d tuiles, une fois chacune"
			% Families.massif_tiles().size())
	var report: Dictionary = MassifTileset.analyse(painting, heights)
	_check(report["is_exportable"],
			"SANS QU UN PIXEL SOIT PEINT A LA MAIN, la feuille est complete")

	var folder: String = "user://essai_test"
	var done: Dictionary = MassifTrial.write(folder)
	_check_equal(String(done["error"]), "", "l essai s ecrit par le chemin normal de l export")

	# --- LE PLUGIN LE RELIT, avec son propre lecteur et ses propres refus.
	var manifest_path: String = folder.path_join(MassifTrial.TRIAL_BASENAME + "_tileset.txt")
	var manifest: Dictionary = PluginManifest.parse(
			FileAccess.get_file_as_string(manifest_path))
	_check_equal(manifest["error"], OK, "et le plugin l accepte : %s" % manifest["reason"])
	_check_equal(int(manifest["version"]), MassifTileset.VERSION,
			"a la version que l exportateur vient d ecrire")
	_check(PluginManifest.is_complete(manifest), "et il se sait complet")

	var built: Dictionary = PluginTileSet.build(folder, manifest)
	_check_equal(built["error"], OK, "le TileSet se fabrique depuis la planche livree")
	var tile_set: TileSet = built["tile_set"]
	_check(tile_set != null, "et il existe")
	if tile_set != null:
		var source: TileSetAtlasSource = tile_set.get_source(
				int(built["source"])) as TileSetAtlasSource
		_check_equal(source.get_tiles_count(), Families.massif_tiles().size(),
				"%d tuiles creees, pas la grille entiere : les cases restantes sont vides"
				% Families.massif_tiles().size())

	# --- ET IL POSE UN MONDE. Chaque pose du guide doit trouver sa tuile.
	#
	# ⚠ C EST LE SEUL TEST QUI PARCOURE LA CHAINE ENTIERE. Tous les autres en eprouvent un
	# maillon : celui-ci part du dessin, le verse dans un carnet, le fait sortir par le CHEMIN
	# NORMAL de l export, relit le manifeste avec le lecteur DU PLUGIN, en fabrique un TileSet,
	# et pose un monde. S il passe, un game dev peut essayer.
	var world: Dictionary = _plugin_world(heights)
	var slots: Dictionary = manifest["slots"]
	var placed: Dictionary = PluginRules.layers(world)
	var missing: int = 0
	var posed: int = 0
	for level: int in placed.keys():
		for tile: int in (placed[level] as Dictionary).values():
			if slots.has(tile):
				posed += 1
			else:
				missing += 1
	_check_equal(missing, 0,
			"CHAQUE pose du guide trouve sa tuile dans l essai : aucun trou")
	_check(posed > 0, "et le monde n est pas vide (%d tuiles posees)" % posed)

	_wipe(folder)


## LA ZONE A REFAIRE, QUAND LE PINCEAU CHANGE UNE CASE.
##
## ⚠ DEUX FAUTES POSSIBLES, ET UNE SEULE SE VOIT. Une zone TROP GRANDE coute du temps ;
## une zone TROP PETITE laisse le monde faux pendant qu'on le dessine, et rien ne le
## signale. On mesure donc la seconde : tout ce qui change apres une retouche doit tomber
## DANS la zone -- sinon la zone ment.
##
## ⚠ ET LE CALCUL BORNE DOIT DIRE EXACTEMENT LA MEME CHOSE QUE LE COMPLET. Sans ca on
## aurait deux regles de pose au lieu d'une, et c'est precisement ce que le manifeste-contrat
## existe pour empecher.
## LES DEUX LECTEURS EMPILENT LES ETAGES DE LA MEME FACON.
##
## ⚠ C'EST LA DIVERGENCE QUE L'EPAULE CACHAIT. L'illustration pose une tuile par etage et
## par case -- l'etage N-1 continue SOUS le plateau de l'etage N -- tandis que le plugin ne
## posait que la tuile VISIBLE. Le coin decoupe d'un plateau etait donc plein dans le guide
## et TROUE dans le jeu : un angle noir en haut de chaque plateau. Mesure sur un plateau pose
## sur de la plaine : 108 pixels transparents sans empilement, 54 avec -- et les 54 qui
## restent sont les coins du BORD DU MONDE, ou il n'y a legitimement rien.
##
## ⚠ ON COMPARE AU NOYAU, PAS A SOI-MEME. `Coverage.index_at_level` est ce que
## l'illustration emploie : si les deux repondent pareil sur tous les etages, il n'existe
## aucun relief ou le guide et le jeu se contrediraient.
func _test_stacked_levels() -> void:
	print("les etages s empilent, et une couche par etage dit ce que dit la liste des poses")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260903
	var apart: int = 0
	var stacked: int = 0

	# ⚠ SUR DES RELIEFS QUE LE PINCEAU PRODUIT, ET C EST LA CONDITION DU THEOREME. « Une case
	# n a qu une pose par etage » tient parce que min trois separe deux composantes d au moins
	# trois rangees de vide, alors qu une jupe n en descend que trois : elle s arrete juste
	# avant. Sur un relief tire au sort, min trois ne tient pas, deux jupes du meme etage se
	# marchent dessus, et une couche par etage en perd une -- ce qui accuserait le rangement
	# d un defaut du relief.
	for _round: int in range(20):
		var relief: PackedStringArray = Gesture.walk(rng, 14, 14, 3)
		if relief.is_empty():
			continue
		var world: Dictionary = _plugin_world(relief)
		var placed: Dictionary = PluginRules.layers(world)
		var counted: int = 0
		for level: int in placed.keys():
			counted += (placed[level] as Dictionary).size()
		var poses: Array[Dictionary] = PluginRules.poses(world)
		if counted != poses.size():
			apart += 1
		for one: Dictionary in poses:
			var level2: int = int(one["level"])
			var at: Vector2i = one["cell"]
			if not placed.has(level2) or not (placed[level2] as Dictionary).has(at):
				apart += 1
			elif int((placed[level2] as Dictionary)[at]) != PluginRules.key_of(one):
				apart += 1
		var seen_cells: Dictionary = {}
		for two: Dictionary in poses:
			var cell: Vector2i = two["cell"]
			if seen_cells.has(cell):
				stacked += 1
			seen_cells[cell] = true

	_check_equal(apart, 0,
			"une couche par etage porte EXACTEMENT les poses du modele, sans en perdre une")
	# ⚠ ET IL FAUT QUE L EMPILEMENT AIT LIEU. Un monde plat passerait le test ci-dessus sans
	# rien empiler du tout : ce serait un compteur qui ne mesure pas ce qu il pretend mesurer.
	_check(stacked > 0,
			"et il y a bien des cases qui portent PLUSIEURS poses (%d) : l empilement sert"
			% stacked)


func _test_plugin_manifest() -> void:
	print("SoluPaint : le manifeste se relit, et le faux se refuse")
	var folder: String = "user://plugin_manifeste"
	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MASSIFS))
	var painting: Painting = MassifTrial.paint(heights)
	var done: Dictionary = MassifTileset.write(painting, heights, Modes.MASSIFS, folder,
			"essai")
	_check_equal(String(done["error"]), "", "un export complet pour eprouver le lecteur")

	var report: Dictionary = PluginManifest.read(folder.path_join("essai_tileset.txt"))
	_check_equal(report["error"], OK, "le manifeste se lit sans reproche : %s"
			% report["reason"])
	_check_equal(int(report["tile_size"]), MassifTrial.TRIAL_RESOLUTION,
			"la taille de tuile est relue")
	_check_equal(report["family"], PluginManifest.BY_MASSIF, "la famille est relue")
	_check_equal(report["slots"].size(), Families.massif_tiles().size(),
			"les %d cases de la planche" % Families.massif_tiles().size())
	_check(PluginManifest.is_complete(report), "et le manifeste se sait complet")

	# ⚠ LA TABLE DOIT DIRE LA MEME CHOSE QUE L EXPORTATEUR. Le plugin lit ce qui est ecrit ;
	# si l ecrit ne correspondait pas a ce que la planche contient, le monde sortirait
	# decale d une case sans qu une seule erreur ne soit levee.
	var misplaced: int = 0
	for tile: int in report["slots"].keys():
		if report["slots"][tile] != MassifTileset.slot_of(tile):
			misplaced += 1
	_check_equal(misplaced, 0, "chaque case relue est celle ou l exportateur a pose la tuile")

	# LE TILESET GODOT, fabrique depuis ce manifeste et cette planche.
	var built: Dictionary = PluginTileSet.build(folder, report)
	_check_equal(built["error"], OK, "le TileSet se fabrique depuis la planche ecrite")
	var tile_set: TileSet = built["tile_set"]
	var side: int = MassifTrial.TRIAL_RESOLUTION
	_check(tile_set != null and tile_set.tile_size == Vector2i(side, side),
			"il porte la taille de tuile du manifeste")

	# LES REFUS (charte, regle 5).
	_check(int(PluginManifest.parse("n importe quoi")["error"]) != OK,
			"un fichier qui ne s annonce pas est refuse")
	var future: String = "%s %d" % [PluginManifest.MAGIC, PluginManifest.READS_UP_TO + 1]
	_check(int(PluginManifest.parse(future)["error"]) != OK,
			"une version plus recente est refusee, pas devinee")
	# ⚠ ET LE TROP VIEUX AUSSI, pour exactement la meme raison. La v8 decrivait l ancien
	# modele -- une surface plus une robe, deux planches, sept bits de contexte. Un lecteur
	# qui la poserait avec les regles d aujourd hui fabriquerait un autre monde, sans une
	# seule erreur. Un garde-fou qui ne regarde que d un cote ne garde rien.
	var ancient: String = "%s %d" % [PluginManifest.MAGIC, PluginManifest.READS_FROM - 1]
	_check(int(PluginManifest.parse(ancient)["error"]) != OK,
			"UNE VERSION TROP VIEILLE EST REFUSEE : son sens a change sous elle")
	_check_equal(PluginManifest.READS_UP_TO, MassifTileset.VERSION,
			"et le plugin lit exactement ce que l exportateur ecrit")
	var written: String = FileAccess.get_file_as_string(
			folder.path_join("essai_tileset.txt"))
	var wrong_fall: String = written.replace("fall_rows 3", "fall_rows 4")
	_check(int(PluginManifest.parse(wrong_fall)["error"]) != OK,
			"un etage qui ne descend pas de trois rangees est REFUSE : le poser mentirait")
	var wrong_count: String = written.replace("tiles %d" % PluginManifest.MASSIF_TILES,
			"tiles %d" % (PluginManifest.MASSIF_TILES + 1))
	_check(int(PluginManifest.parse(wrong_count)["error"]) != OK,
			"et un vocabulaire qui n est pas le sien est REFUSE, pas pose a moitie")

	_wipe(folder)


## L installateur : le bouton destine a l acheteur.
## SOLUPAINT TROUVE SES TILESETS TOUT SEUL.
##
## ⚠ CE QU'ON PEUT TROUVER NE SE DEMANDE PAS. Pointer un manifeste a la main, c'est
## demander a l'acheteur de savoir ce qu'il cherche, ou il est, et que ce soit lui : trois
## occasions d'abandonner avant d'avoir rien vu. Un tileset SoluTiles se reconnait a son
## nom -- donc on le trouve, et s'il n'y en a qu'un on le pose sans rien demander.
func _test_manifest_discovery() -> void:
	print("SoluPaint : les tilesets se trouvent tout seuls")
	var folder: String = "user://decouverte"
	var deeper: String = folder.path_join("un/deux/trois")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(deeper))

	_check(PluginManifest.discover(folder).is_empty(),
			"un projet sans tileset n en propose aucun")

	var heights: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.MASSIFS))
	var painting: Painting = MassifTrial.paint(heights)
	_check_equal(String(MassifTileset.write(painting, heights, Modes.MASSIFS, folder,
			"premier")["error"]), "", "un tileset s ecrit a la racine")
	_check_equal(String(MassifTileset.write(painting, heights, Modes.MASSIFS, deeper,
			"second")["error"]), "", "et un autre, trois dossiers plus bas")

	var found: PackedStringArray = PluginManifest.discover(folder)
	_check_equal(found.size(), 2, "les deux se trouvent, quelle que soit leur profondeur")
	var names: PackedStringArray = PackedStringArray()
	for path: String in found:
		names.append(path.get_file())
	names.sort()
	_check_equal(names, PackedStringArray(["premier_tileset.txt", "second_tileset.txt"]),
			"et ce sont bien eux")
	_check_equal(PluginManifest.label_of(found[0]).is_empty(), false,
			"chacun sait se nommer court, pour une liste deroulante")

	# ⚠ ET IL FAUT QUE CE QU ON TROUVE SE LISE. Proposer un chemin que le lecteur refuse
	# ensuite serait pire que ne rien proposer : on aurait promis.
	for path: String in found:
		_check_equal(PluginManifest.parse(FileAccess.get_file_as_string(path))["error"], OK,
				"et %s se relit vraiment" % path.get_file())

	_wipe(folder)


## Efface un dossier et tout ce qu il contient.
func _wipe(folder: String) -> void:
	var directory: DirAccess = DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		var path: String = folder.path_join(entry)
		if directory.current_is_dir():
			_wipe(path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))


func _test_plugin_install() -> void:
	print("SoluPaint : l installation chez l acheteur")

	# ⚠ LA LISTE DES FICHIERS EST UNE DONNEE, DONC UN ENDROIT OU MENTIR. On la compare au
	# dossier reel : un fichier ajoute au plugin et oublie dans la liste ne partirait jamais
	# chez l acheteur, et le plugin arriverait casse sans que rien ne le dise.
	var on_disk: PackedStringArray = PackedStringArray()
	var directory: DirAccess = DirAccess.open(PluginInstall.SOURCE)
	if directory != null:
		directory.list_dir_begin()
		var entry: String = directory.get_next()
		while entry != "":
			# ⚠ NI LES .uid NI LES .import : ce ne sont pas des morceaux du plugin, ce sont
			# les papiers que Godot etablit POUR NOTRE projet. Un `.import` pointe sur un
			# fichier de notre dossier `.godot/` ; le copier chez l'acheteur y designerait
			# quelque chose qui n'existe pas. Son editeur reimporte, c'est son affaire.
			var papier: bool = entry.ends_with(".uid") or entry.ends_with(".import")
			if not directory.current_is_dir() and not papier:
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
	# ⚠ ET LA COMPARAISON AU PLUGIN A QUITTE CE TEST, avec le modele qu elle controlait. Les
	# chutes profondes du modele des massifs sont eprouvees par `_test_plugin_rules`, sur des
	# poses et non sur des roles de robe.

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

	# ⚠ ET LA QUESTION S EST SIMPLIFIEE AVEC L ALPHABET. Il fallait autrefois verifier que le
	# `vide` et l `arete` occupaient les MEMES colonnes, parce que l etat d un flanc change en
	# descendant et que deux geometries differentes auraient fait sauter la marque en plein
	# milieu de la falaise. Les deux etats n en font plus qu un -- `arret` -- et le defaut
	# devient inexprimable. Ce qu il reste a asserter est plus simple, et plus fort : la bande
	# EXISTE, et elle est la meme a toutes les rangees.
	for side: String in ["ouest", "est"]:
		var key: String = "%s|%s" % [side, Walls.SIDE_NAMES[Walls.SIDE_STOP]]
		var band: PackedInt32Array = by_state.get(key, PackedInt32Array())
		_check(band.size() == 0 or band[0] != -1,
				"%s : flanc %s -- la bande d arret est la MEME a toutes les rangees"
				% [label, side])
		if ink == GuideImage.Ink.PAINTED:
			_check(band.size() > 0 and band[0] != -1,
					"%s : flanc %s -- et la bande existe vraiment (%d colonnes, stable sur les %d rangees)"
					% [label, side, band.size(), Walls.BLOCK_ROWS])


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


## LE DOMAINE : ce qu'on refuse, a un seul endroit -- et on ne refuse pas ce qu'on livre.
##
## ⚠ UNE LISTE DE CLAUSES QUE PERSONNE NE VERIFIE N'EST QU'UN DOCUMENT, donc un endroit ou
## mentir de plus. Ce qui se prouve ici : les clauses sont completes et distinctes ; chaque
## guide LIVRE est dans le domaine ; un relief fin en sort et la clause est NOMMEE ; et une
## clause ecartee le reste tant que nos propres mondes la violent.
func _test_domain() -> void:
	print("domaine : les clauses, a un seul endroit, et nos mondes dedans")
	var seen: Dictionary = {}
	var kinds: Array[String] = [Domain.KIND_WORLD, Domain.KIND_GUIDE, Domain.KIND_ABSENT,
			Domain.KIND_DROPPED]
	for entry: Dictionary in Domain.clauses():
		var id: String = String(entry["id"])
		_check(not seen.has(id), "la clause %s n est declaree qu une fois" % id)
		seen[id] = true
		_check(kinds.has(String(entry["kind"])), "%s est d une espece connue" % id)
		_check(not String(entry["titre"]).is_empty(), "%s a un titre" % id)
		_check(not String(entry["enonce"]).is_empty(), "%s a un enonce" % id)
		_check_equal(Domain.clause(id)["titre"], entry["titre"], "%s se retrouve par son id" % id)
	_check(Domain.clause("cette clause n existe pas").is_empty(),
			"une clause inconnue rend un dictionnaire vide")

	# ⚠ ON NE REFUSE PAS UN MONDE QU ON LIVRE SOI-MEME. C est la contradiction qu un domaine
	# eparpille finit toujours par produire, et elle ne se voit qu en comparant les deux.
	for id: StringName in Modes.ids():
		if not Modes.is_available(id):
			continue
		var heights: PackedStringArray = HeightMask.read(Modes.guide_path(id))
		var faults: Array[String] = Domain.violations(heights)
		_check(faults.is_empty(), "le guide du mode %s est dans le domaine %s"
				% [Modes.label(id), str(faults)])
		# ⚠ ET LA CLAUSE ECARTEE RESTE ECARTEE TANT QUE LE GUIDE LA VIOLE. Le guide livre
		# porte des parois sans masse d aucun cote ; remettre X1 en clause de MONDE
		# refuserait notre propre guide, sans que rien d autre ne le dise.
		if not Thickness.lonely_robe_cells(heights).is_empty():
			_check_equal(Domain.clause("X1")["kind"], Domain.KIND_DROPPED,
					"X1 reste ecartee : le guide %s porte ce qu elle interdirait"
					% Modes.label(id))

	# ⚠ ET LE REFUS NOMME SA CLAUSE. Un refus muet est le pire des refus : le pinceau doit
	# pouvoir dire CE QUI manque, pas seulement qu il refuse.
	var isthmus: PackedStringArray = PackedStringArray([
			"~~~~~~~", "~11111~", "~11111~", "~~~1~~~", "~11111~", "~11111~", "~~~~~~~"])
	_check(not Domain.accepts(isthmus), "un isthme d une case sort du domaine")
	_check(Domain.violations(isthmus).has("D2"), "et c est la clause D2 qui le dit")

	var block: PackedStringArray = PackedStringArray([
			"~~~~~", "~111~", "~111~", "~111~", "~~~~~"])
	_check(Domain.accepts(block), "un bloc 3x3 est dans le domaine")
	# ⚠ UN CARACTERE ABERRANT SE LIT PLAINE EN SILENCE dans un masque bati a la main : c est
	# exactement ce que D1 garde, et la mesure doit avoir vu quelque chose.
	var junk: PackedStringArray = PackedStringArray([
			"~~~~~", "~111~", "~1A1~", "~111~", "~~~~~"])
	_check(Domain.violations(junk).has("D1"), "un caractere hors alphabet est nomme par D1")


func _test_thickness() -> void:
	print("thickness : le vocabulaire du mode epais")
	# Le vocabulaire est CALCULE (theoreme des 256 fenetres) ; le test epingle le
	# resultat du recensement (tools/thick_census.gd) pour attraper toute derive.
	# ⚠ LE VOCABULAIRE EST CLOS DES DEUX COTES, ET C EST LA FIN DU CLIQUET. Les 27 sont le
	# theoreme des 256 fenetres ; les 20 sont TOUS les pans x rangees possibles. Il n y a plus
	# de forme a chercher, donc plus de role a decouvrir un soir en peignant.
	_check_equal(Thickness.SURFACE_INDICES.size(), 27,
			"27 tuiles de surface : la silhouette, et rien d autre")
	var thick_shapes: Dictionary = {}
	for tile: int in Thickness.SURFACE_INDICES:
		var shape: int = BlobIndex.silhouette(tile)
		thick_shapes[shape] = true
		_check(BlobIndex.is_canonical(shape), "la silhouette epaisse %d est canonique" % shape)
	_check_equal(thick_shapes.size(), 27, "et chaque tuile EST sa silhouette")
	for index: int in [255, 31, 119, 124, 127, 253]:
		_check(thick_shapes.has(index), "la silhouette %d survit" % index)
	for index: int in [0, 1, 4, 16, 17, 21, 68, 85, 87, 95]:
		_check(not thick_shapes.has(index), "la silhouette %d meurt" % index)

	# ⚠ LE BORD A DISPARU AVEC LA DECOMPOSITION EN COUCHES, et il faut l asserter : une tuile
	# qui recommencerait a porter un bord ferait remonter le compte sans que rien ne le dise.
	for tile: int in Thickness.SURFACE_INDICES:
		_check_equal(BlobIndex.brink(tile), 0,
				"la tuile %d ne porte aucun bord : ce qui est a cote appartient au voisin"
				% tile)

	_check_equal(Thickness.wall_roles().size(), 20,
			"20 roles de robe : quatre pans x cinq rangees, TOUS vivants")
	# ⚠ ET TOUS VIVENT, SANS EXCEPTION. Avec trois etats de flanc la forme etait CHERCHEE --
	# on battait le monde en esperant qu aucun role de plus n apparaisse, et il en apparaissait.
	# Avec deux, il n y a rien a chercher : la forme est close par construction.
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			_check(Thickness.role_survives(Vector2i(pan, row)),
					"%s vit au %s" % [Walls.pan_name(pan), Walls.ROW_NAMES[row]])

	# Les cases fines se detectent : une bande d une case, un trou d une case.
	var thin_band: PackedStringArray = PackedStringArray(["000000", "011110", "000000"])
	_check(not Thickness.thin_cells(thin_band).is_empty(), "une bande d une case est fine")
	var thin_hole: PackedStringArray = PackedStringArray(
			["11111", "11011", "11111"])
	_check(not Thickness.thin_cells(thin_hole).is_empty(), "un trou d une case est fin")
	var pair_block: PackedStringArray = PackedStringArray(["0000", "0110", "0110", "0000"])
	_check(not Thickness.thin_cells(pair_block).is_empty(),
			"un bloc 2x2 est fin -- min trois, bord + centre + bord")
	var block: PackedStringArray = PackedStringArray(
			["00000", "01110", "01110", "01110", "00000"])
	_check(Thickness.thin_cells(block).is_empty(), "un bloc 3x3 est epais")
	# LA BATTUE : sur des reliefs epais tires au sort, tout ce qui devient visible tombe
	# dans le vocabulaire calcule -- surfaces ET robes. Une battue qui ne rencontre rien
	# ne prouve rien : on assere aussi qu elle a vu du pays.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0xE5A15
	var seen_indices: Dictionary = {}
	var seen_roles: Dictionary = {}
	var sampled: int = 0
	# ⚠ ET LE VOCABULAIRE EST CELUI DES CLES, PAS DES SILHOUETTES. Une tuile de surface est un
	# couple (silhouette, bord) : comparer ce que le relief POSE aux dix-sept silhouettes ne
	# controle plus rien depuis que la cle porte les deux. C'est aussi, du coup, le controle de
	# la FORME FERMEE sur des reliefs tires au sort -- « toute tuile reellement rencontree doit
	# tomber dans la forme calculee ; une seule dehors, et c'est la forme qui est fausse ».
	var vocabulary: Dictionary = {}
	for key: int in Families.surface_indices(Families.BY_CELL):
		vocabulary[key] = true
	# ⚠ ET ON NE CRIE QU'UNE FOIS PAR CLE FAUTIVE. Premiere version : un `_check` par
	# OCCURRENCE -- 38 126 lignes identiques pour une poignee de cles, et le vrai reste des
	# echecs devenait introuvable dans le flot.
	var strays: Dictionary = {}
	for _trial: int in range(400):
		var relief: PackedStringArray = _random_thick_relief(rng)
		if relief.is_empty():
			continue
		sampled += 1
		var indices: Dictionary = Families.surface_map(Families.BY_CELL, relief)
		for at: Vector2i in indices.keys():
			seen_indices[int(indices[at])] = true
			if not vocabulary.has(int(indices[at])):
				strays[int(indices[at])] = true
		var roles: Dictionary = Walls.visible(relief)["roles"]
		for cell: Vector2i in roles.keys():
			seen_roles[roles[cell]] = true
			if not Thickness.role_survives(roles[cell]):
				_check(false, "role (%d,%d) visible sur un relief epais mais hors vocabulaire"
						% [(roles[cell] as Vector2i).x, (roles[cell] as Vector2i).y])
	var named: Array[int] = []
	named.assign(strays.keys())
	named.sort()
	_check(strays.is_empty(), "tout ce qu un relief epais POSE tombe dans la forme fermee (%d hors : %s)"
			% [named.size(), str(named.slice(0, 8))])
	_check(sampled >= 200, "la battue a echantillonne assez de reliefs (%d)" % sampled)
	_check(seen_indices.size() >= 15, "la battue a rencontre des surfaces variees (%d)"
			% seen_indices.size())
	_check(seen_roles.size() >= 10, "la battue a rencontre des roles varies (%d)"
			% seen_roles.size())


## Un relief epais tire au sort : des blocs d au moins 2x2, rejet de tout relief fin.
func _random_thick_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	for _try: int in range(40):
		var levels: Array = []
		for y: int in range(12):
			var line: Array = []
			line.resize(14)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(2, 4)):
			var w: int = rng.randi_range(3, 6)
			var h: int = rng.randi_range(3, 6)
			var px: int = rng.randi_range(0, 14 - w)
			var py: int = rng.randi_range(0, 12 - h)
			var lift: int = rng.randi_range(1, 2)
			for y: int in range(py, py + h):
				for x: int in range(px, px + w):
					levels[y][x] = maxi(levels[y][x] as int, lift)
		var heights: PackedStringArray = PackedStringArray()
		for y: int in range(12):
			var line: String = ""
			for x: int in range(14):
				line += str(levels[y][x] as int)
			heights.append(line)
		# ⚠ UN RELIEF LEGAL EST EPAIS DANS LE RELIEF **ET** DANS LA ROBE. La battue qui
		# n'exigeait que la premiere moitie fabriquait des parois sans masse d'aucun cote --
		# des pans que le vocabulaire ne contient plus -- et accusait le noyau de les nier.
		if not Thickness.thin_cells(heights).is_empty():
			continue
		if Thickness.lonely_robe_cells(heights).is_empty():
			return heights
	return PackedStringArray()


## ⚠ LE PLUGIN PORTE SA COPIE DE LA REGLE D'EPAISSEUR, DONC ON LES COMPARE -- meme
## traitement que la regle de pose : deux copies qui se fient a leur memoire divergent.
func _test_thickness_cross_check() -> void:
	print("thickness : la copie du plugin dit exactement ce que dit le noyau")
	# ⚠ ET LE COMPTE DE TUILES A DEMENAGE AVEC LE MODELE : il n y a plus deux vocabulaires --
	# les surfaces d un cote, les robes de l autre -- mais un seul, celui des massifs. Il se
	# compare dans `_test_plugin_rules`, avec le reste de la regle de pose.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x7413C
	var drift: int = 0
	var probed: int = 0
	for _trial: int in range(40):
		var relief: PackedStringArray = _random_relief(rng, 8, 8, 3)
		var heights: Dictionary = {}
		for y: int in range(HeightMask.height(relief)):
			for x: int in range(HeightMask.width(relief)):
				var level: int = HeightMask.level_at(relief, x, y)
				if level >= 0:
					heights[Vector2i(x, y)] = level
		for y: int in range(-1, HeightMask.height(relief) + 1):
			for x: int in range(-1, HeightMask.width(relief) + 1):
				probed += 1
				var core_thin: bool = false
				var top: int = HeightMask.top_level(relief)
				for storey: int in range(0, top + 1):
					if Thickness.thin_at(relief, x, y, storey):
						core_thin = true
						break
				if PluginRules.thin_after(heights, {}, Vector2i(x, y)) != core_thin:
					drift += 1
	_check_equal(drift, 0, "sur %d cases sondees, la finesse du plugin est celle du noyau"
			% probed)
