# DU MANIFESTE AU TILESET GODOT — une planche, une source d'atlas.
#
# ⚠ UNE SEULE SOURCE, ET C'EST LE MODELE QUI LE DIT. L'ancien lecteur en montait deux -- les
# surfaces d'un cote, les robes de l'autre -- parce qu'une falaise « sortait du plan » et
# relevait d'un second vocabulaire. Un massif se dessine ENTIER : sa surface et sa jupe sont le
# meme objet vu a deux hauteurs, une tuile est le couple (silhouette, bande), et les separer
# obligerait a savoir ou l'une s'arrete.
#
# ⚠ ON NE CREE QUE LES CASES QUE LE MANIFESTE NOMME. `TileSetAtlasSource` accepterait qu'on
# declare toute la grille ; les dernieres cases de la planche sont vides (le vocabulaire n'est
# pas un multiple de huit), et une tuile declaree sur du transparent est un trou qui attend son
# tour.
#
# ⚠ ET LE FILTRAGE EST AU PLUS PROCHE. Un lissage bilineaire melangerait les bords voisins de
# l'atlas : le monde montrerait des coutures que le dessin n'a pas -- exactement le defaut que
# tout ce projet existe pour eviter.
extends RefCounted


## Fabrique le TileSet decrit par un manifeste.
##
## [param folder] est le dossier ou vivent le manifeste et sa planche ; le nom du fichier vient
## du manifeste, jamais devine.
##
## Cles rendues :
##   error   : Error
##   reason  : String
##   tile_set: TileSet
##   source  : int   identifiant de source, pour TileMapLayer.set_cell()
static func build(folder: String, report: Dictionary) -> Dictionary:
	var result: Dictionary = {"error": OK, "reason": "", "tile_set": null, "source": -1}
	if int(report["error"]) != OK:
		result["error"] = report["error"]
		result["reason"] = report["reason"]
		return result

	var side: int = int(report["tile_size"])
	if side <= 0:
		result["error"] = ERR_INVALID_DATA
		result["reason"] = "The manifest announces no tile size."
		return result

	var made: Dictionary = _source(folder, String(report["sheet"]), side,
			report["slots"].values())
	if int(made["error"]) != OK:
		result["error"] = made["error"]
		result["reason"] = made["reason"]
		return result

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(side, side)
	result["tile_set"] = tile_set
	result["source"] = tile_set.add_source(made["source"])
	return result


## Une source d'atlas, ses tuiles creees une par une aux cases demandees.
static func _source(folder: String, sheet: String, side: int, slots: Array) -> Dictionary:
	var outcome: Dictionary = {"error": OK, "reason": "", "source": null}
	var path: String = folder.path_join(sheet)
	var texture: Texture2D = _texture(path)
	if texture == null:
		outcome["error"] = ERR_FILE_NOT_FOUND
		outcome["reason"] = "Sheet missing or unreadable: %s" % sheet
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
			outcome["reason"] = ("The manifest places a tile at %d,%d, outside %s "
					+ "(%d x %d cells).") % [slot.x, slot.y, sheet, columns, rows]
			return outcome
		source.create_tile(slot)
	outcome["source"] = source
	return outcome


## ⚠ LA PLANCHE N'EST PAS FORCEMENT DANS `res://`. L'acheteur range son tileset ou il veut, et
## un fichier hors du projet n'a pas de chemin de ressource : `load()` ne le verrait pas. On lit
## donc l'image, et on en fait une texture a la main.
static func _texture(path: String) -> Texture2D:
	# ⚠ ON DEMANDE D ABORD SI LA RESSOURCE EXISTE. Un PNG qu on vient d ecrire dans `res://`
	# n a pas encore ete importe par l editeur : `load()` echoue en remplissant la console de
	# rouge, alors que le fichier est la et se lit tres bien a la main. Un refus bruyant sur un
	# chemin qui marche apprend a ignorer le rouge.
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource: Resource = ResourceLoader.load(path)
		if resource is Texture2D:
			return resource
	var image: Image = Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
