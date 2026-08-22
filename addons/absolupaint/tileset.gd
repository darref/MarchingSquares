# DU MANIFESTE AU TILESET GODOT — deux planches, deux sources d'atlas.
#
# ⚠ DEUX SOURCES, JAMAIS UNE. Un terrain Wang resout les coins d'un plan ; une falaise sort
# du plan. Les fondre dans un seul atlas obligerait le lecteur a savoir ou l'une s'arrete --
# c'est precisement pour ne pas avoir a le savoir que l'export livre deux fichiers.
#
# ⚠ ON NE CREE QUE LES CASES QUE LE MANIFESTE NOMME. `TileSetAtlasSource` accepterait qu'on
# declare toute la grille ; la derniere case de la planche de surface est vide (47 n'est pas
# un multiple de 8), et une tuile declaree sur du transparent est un trou qui attend son
# tour. On cree 47 tuiles, ou 15, et pas une de plus.
#
# ⚠ ET LE FILTRAGE EST AU PLUS PROCHE. Un lissage bilineaire melangerait les bords voisins
# de l'atlas : le monde montrerait des coutures que le dessin n'a pas -- exactement le
# defaut que tout ce projet existe pour eviter.
extends RefCounted

const Manifest := preload("res://addons/absolupaint/manifest.gd")


## Fabrique le TileSet decrit par un manifeste.
##
## [param folder] est le dossier ou vivent le manifeste et ses deux planches ; les noms de
## fichiers viennent du manifeste, jamais devines.
##
## Cles rendues :
##   error         : Error
##   reason        : String
##   tile_set      : TileSet
##   surface_source: int   identifiant de source, pour TileMapLayer.set_cell()
##   walls_source  : int
static func build(folder: String, report: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"error": OK,
		"reason": "",
		"tile_set": null,
		"surface_source": -1,
		"walls_source": -1,
	}
	if int(report["error"]) != OK:
		result["error"] = report["error"]
		result["reason"] = report["reason"]
		return result

	var side: int = int(report["tile_size"])
	if side <= 0:
		result["error"] = ERR_INVALID_DATA
		result["reason"] = "Le manifeste n'annonce aucune taille de tuile."
		return result

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(side, side)

	var surface: Dictionary = _source(folder, String(report["surface_sheet"]), side,
			report["surface_slots"].values())
	if int(surface["error"]) != OK:
		result["error"] = surface["error"]
		result["reason"] = surface["reason"]
		return result

	var walls: Dictionary = _source(folder, String(report["walls_sheet"]), side,
			report["wall_slots"].values())
	if int(walls["error"]) != OK:
		result["error"] = walls["error"]
		result["reason"] = walls["reason"]
		return result

	result["tile_set"] = tile_set
	result["surface_source"] = tile_set.add_source(surface["source"])
	result["walls_source"] = tile_set.add_source(walls["source"])
	return result


## Une source d'atlas, ses tuiles creees une par une aux cases demandees.
static func _source(folder: String, sheet: String, side: int, slots: Array) -> Dictionary:
	var outcome: Dictionary = {"error": OK, "reason": "", "source": null}
	var path: String = folder.path_join(sheet)
	var texture: Texture2D = _texture(path)
	if texture == null:
		outcome["error"] = ERR_FILE_NOT_FOUND
		outcome["reason"] = "Planche introuvable ou illisible : %s" % sheet
		return outcome

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(side, side)
	var columns: int = texture.get_width() / side
	var rows: int = texture.get_height() / side
	for slot: Vector2i in slots:
		# ⚠ UNE CASE HORS DE LA PLANCHE EST UN REFUS, PAS UN SAUT. Elle signale un manifeste
		# et une image qui ne parlent pas du meme tileset ; poser les autres quand meme
		# donnerait un monde troue dont personne ne saurait dire pourquoi.
		if slot.x < 0 or slot.y < 0 or slot.x >= columns or slot.y >= rows:
			outcome["error"] = ERR_INVALID_DATA
			outcome["reason"] = ("Le manifeste place une tuile en %d,%d, hors de %s "
					+ "(%d x %d cases).") % [slot.x, slot.y, sheet, columns, rows]
			return outcome
		source.create_tile(slot)
	outcome["source"] = source
	return outcome


## ⚠ LES PLANCHES NE SONT PAS DANS `res://`. L'acheteur range son tileset ou il veut, et un
## fichier hors du projet n'a pas de chemin de ressource : `load()` ne le verrait pas. On
## lit donc l'image, et on en fait une texture a la main.
static func _texture(path: String) -> Texture2D:
	if path.begins_with("res://"):
		var resource: Resource = ResourceLoader.load(path)
		if resource is Texture2D:
			return resource
	var image: Image = Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
