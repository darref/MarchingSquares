# LE TRAVAIL PEINT RETOMBE-T-IL SUR SES PIEDS ? — on relit un vrai fichier, sans l'ecrire.
#
# ⚠ C'EST LE SEUL CONTROLE QUE LE DEPOT NE PEUT PAS FABRIQUER. Les tests peignent des
# couleurs tirees de la position ; un fichier de session porte du VRAI travail, range par
# tuile, et c'est lui qui dit si un changement de vocabulaire deplace l'art en silence.
#
# ⚠ ET IL NE MODIFIE RIEN. Le fichier n'est jamais reecrit -- on le lit, on repose son
# contenu sur le guide courant, et on dit ce qui retombe et ce qui ne retombe pas.
#
# ⚠ ET LE PAYSAGE SE LIT DANS L'EN-TETE, IL NE SE SUPPOSE PAS. L'outil chargeait le guide
# d'`epais` quel que soit le fichier : un travail de massifs y retombait sur le relief d'un
# autre modele, et le compte qui en sortait ne mesurait rien. C'est pour ca que `peek()`
# existe -- le fichier dit sur quoi il a ete peint, on l'ecoute.
#
#     godot --headless --path . --script res://tools/reload_work.gd -- <chemin.solutiles>
extends SceneTree

const WorkIO := preload("res://core/work_io.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Families := preload("res://core/families.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")
const Painting := preload("res://core/painting.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage : --script res://tools/reload_work.gd -- <chemin.solutiles>")
		quit(1)
		return
	var path: String = args[0]
	if not FileAccess.file_exists(path):
		print("fichier introuvable : %s" % path)
		quit(1)
		return

	var header: Dictionary = WorkIO.peek(path)
	print("EN-TETE : %s" % str(header))
	var mode: StringName = StringName(header.get("mode", Modes.EPAIS))
	if not Modes.has(mode):
		print("REFUS : mode inconnu '%s'." % mode)
		quit(1)
		return
	var guide_path: String = Modes.guide_path(mode)
	print("GUIDE   : %s" % guide_path)
	var heights: PackedStringArray = HeightMask.read(guide_path)
	var result: Dictionary = WorkIO.read(path, heights)
	if int(result.get("error", OK)) != OK:
		print("REFUS : erreur %d" % int(result["error"]))
		quit(1)
		return

	var painting: Painting = result["painting"]
	var unplaced: Array = result.get("unplaced", [])
	print("")
	print("tuiles reposees : %d" % int(result.get("placed", 0)))
	print("tuiles RENDUES (aucune place dans le vocabulaire courant) : %d" % unplaced.size())
	for key: Variant in unplaced:
		print("   %s" % str(key))

	print("")
	if mode == Modes.MASSIFS:
		_report_massifs(painting, heights)
	else:
		_report_walls(painting, heights, header)
	quit()


## LE MODELE DU JOUR : on demande a l'EXPORTATEUR ce qui manque, on ne le recompte pas ici.
## ⚠ Un outil qui rederiverait la formule qu'il controle ne controlerait rien -- il la
## certifierait. Ce que cette ligne affiche est exactement ce que le bouton « Exporter » juge.
func _report_massifs(painting: Painting, heights: PackedStringArray) -> void:
	var report: Dictionary = MassifTileset.analyse(painting, heights)
	var wanted: Array = report["wanted"]
	var missing: Array = report["missing"]
	print("TUILES peintes : %d / %d" % [int(report["delivered"]), wanted.size()])
	for tile: int in missing:
		print("   manquante : %s" % Massifs.describe(tile))
	print("EXPORTABLE : %s" % ("oui" if bool(report["is_exportable"]) else "non"))


## L'ANCIEN MODELE, garde pour le mode `epais` -- son guide reste au depot comme temoin.
func _report_walls(painting: Painting, heights: PackedStringArray, header: Dictionary) -> void:
	var family: StringName = StringName(header.get("family", Families.BY_CELL))
	var slots: Dictionary = WorkIO.slots(heights, family)
	var painted: Dictionary = {}
	for at: Vector2i in painting.painted_cells():
		if slots.has(at):
			painted[String(slots[at]).split(":")[0]] = true
	var walls: int = 0
	var missing_walls: Array[String] = []
	for role: Vector2i in Thickness.wall_roles():
		if painted.has("W%d,%d" % [role.x, role.y]):
			walls += 1
		else:
			missing_walls.append(Walls.role_name(role))
	var wanted: PackedInt32Array = Families.surface_indices(family)
	var surfaces: int = 0
	var missing_surfaces: Array[String] = []
	for index: int in wanted:
		if painted.has("%s%d" % [Families.key_letter(family), index]):
			surfaces += 1
		else:
			missing_surfaces.append(str(index))
	print("SURFACES peintes : %d / %d" % [surfaces, wanted.size()])
	if not missing_surfaces.is_empty():
		print("   manquantes : %s" % ", ".join(missing_surfaces))
	print("FALAISES peintes : %d / %d" % [walls, Thickness.wall_roles().size()])
	if not missing_walls.is_empty():
		print("   manquantes : %s" % ", ".join(missing_walls))
