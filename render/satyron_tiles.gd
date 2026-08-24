# LE TILESET DE SATYRON, LU DEPUIS SON PROJET — un oracle, pas une dependance.
#
# La technique « Example » assemble notre guide avec de VRAIES tuiles, dessinees ailleurs,
# par quelqu'un d'autre, pour un autre jeu. Si notre relief et nos regles de falaise sont
# justes, le paysage se tient ; chaque endroit ou il ne se tient pas est une erreur -- chez
# nous, ou chez Satyron.
#
# ⚠ ON LIT, ON NE COPIE PAS. Les images restent dans le projet Satyron, sur ce disque. Rien
# n'est embarque dans SoluTiles : le pack de tuiles est achete, sa licence autorise
# l'usage et interdit la redistribution. Sur une machine ou Satyron n'est pas la, la
# technique se ferme d'elle-meme (charte, regle 5).
#
# ⚠ ET LES DEUX SYSTEMES NE SONT PAS LE MEME. Satyron peint ses sols par les COINS -- son
# `icko_tileset.tres` declare `mode = 1`, quatre bits de coin par tuile. Nous peignons par
# les huit voisins d'une CASE. Les deux grilles sont duales : une tuile de Satyron est a
# cheval sur quatre des notres, et se pose donc decalee d'une demi-case. Ce n'est pas une
# approximation, c'est la geometrie du systeme -- mais cela veut dire qu'Example n'eprouve
# PAS la correspondance de nos 47 index : il n'existe aucune tuile en face.
extends RefCounted

## Ou trouver le projet. Surchargeable dans project.godot par `solutiles/satyron_path`.
const DEFAULT_ROOT: String = "D:/Satyron"

const TILESET_PATH: String = "WORLD/tiles/icko_tileset.tres"
const KITS_PATH: String = "WORLD/tiles/cliff_kits.tres"

## Cote d'une tuile chez Satyron.
const SOURCE_TILE: int = 64

## A quelle matiere de Satyron correspond chacun de nos etages. Arbitraire, mais stable :
## ce qui compte est que deux etages voisins soient de matieres differentes, pour que le
## systeme a coins dessine une transition entre eux.
const LEVEL_TERRAIN: Array[int] = [2, 0, 1, 3]


static func root() -> String:
	return String(ProjectSettings.get_setting("solutiles/satyron_path", DEFAULT_ROOT))


## Vrai si le projet est la, avec ce qu'il faut dedans.
static func is_available() -> bool:
	var base: String = root()
	return FileAccess.file_exists(base.path_join(TILESET_PATH)) \
			and FileAccess.file_exists(base.path_join(KITS_PATH))


## Lit tout ce dont le rendu a besoin.
##
## Cles retournees :
##   corners  : Dictionary[String, Array]  "tl,tr,bl,br" -> [source, Vector2i]
##   images   : Dictionary[int, Image]     source -> atlas
##   cliff    : Dictionary                 source, origin, body_rows
static func read() -> Dictionary:
	var base: String = root()
	var textures: Dictionary = {}
	var source_of: Dictionary = {}
	var corners: Dictionary = {}
	_parse_tileset(base.path_join(TILESET_PATH), textures, source_of, corners)

	var images: Dictionary = {}
	for source: int in textures.keys():
		var absolute: String = base.path_join(String(textures[source]).replace("res://", ""))
		var image: Image = Image.load_from_file(absolute)
		if image != null:
			if image.get_format() != Image.FORMAT_RGBA8:
				image.convert(Image.FORMAT_RGBA8)
			images[source] = image

	return {
		"corners": corners,
		"images": images,
		"cliff": _parse_kit(base.path_join(KITS_PATH)),
	}


## ⚠ ON ANALYSE LE TEXTE, ON NE CHARGE PAS LA RESSOURCE. Un `.tres` d'un autre projet
## reference ses images en `res://`, qui pointe chez NOUS : le charger echouerait sur la
## premiere texture. Le format est un fichier de configuration, il se lit a la main.
static func _parse_tileset(path: String, textures: Dictionary, source_of: Dictionary,
		corners: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("satyron_tiles: lecture impossible de '%s'." % path)
		return
	var text: String = file.get_as_text()
	file.close()

	var ext_paths: Dictionary = {}
	var block_texture: Dictionary = {}
	var block_tiles: Dictionary = {}
	var current: String = ""
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("[ext_resource"):
			var id: String = _quoted_after(line, " id=")
			var resource_path: String = _quoted_after(line, "path=")
			if id != "" and resource_path != "":
				ext_paths[id] = resource_path
			continue
		if line.begins_with("[sub_resource"):
			current = _quoted_after(line, " id=")
			continue
		if line.begins_with("[resource]"):
			current = ""
			continue
		if line.begins_with("texture = ExtResource("):
			block_texture[current] = _quoted_after(line, "ExtResource(")
			continue
		if line.begins_with("sources/"):
			var index: int = line.get_slice("/", 1).get_slice(" ", 0).to_int()
			source_of[_quoted_after(line, "SubResource(")] = index
			continue
		if current == "" or not line.contains("/terrains_peering_bit/"):
			continue
		var key: String = line.get_slice(" = ", 0)
		var value: int = line.get_slice(" = ", 1).to_int()
		var coord: String = key.get_slice("/", 0)
		var corner: String = key.get_slice("/", 3)
		if not block_tiles.has(current):
			block_tiles[current] = {}
		var tiles: Dictionary = block_tiles[current]
		if not tiles.has(coord):
			tiles[coord] = {}
		var faces: Dictionary = tiles[coord]
		faces[corner] = value

	for block: String in source_of.keys():
		var source: int = int(source_of[block])
		if block_texture.has(block):
			var ext: String = String(block_texture[block])
			if ext_paths.has(ext):
				textures[source] = ext_paths[ext]
		if not block_tiles.has(block):
			continue
		for coord: String in block_tiles[block].keys():
			var faces: Dictionary = block_tiles[block][coord]
			var signature: String = "%d,%d,%d,%d" % [
					int(faces.get("top_left_corner", -1)),
					int(faces.get("top_right_corner", -1)),
					int(faces.get("bottom_left_corner", -1)),
					int(faces.get("bottom_right_corner", -1))]
			if corners.has(signature):
				continue
			corners[signature] = [source, Vector2i(
					coord.get_slice(":", 0).to_int(), coord.get_slice(":", 1).to_int())]


## Le premier kit de falaise du fichier : source, coin de bloc, nombre de rangees de corps.
static func _parse_kit(path: String) -> Dictionary:
	var kit: Dictionary = {"source": -1, "origin": Vector2i.ZERO, "body_rows": 2}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return kit
	var text: String = file.get_as_text()
	file.close()
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("source_id = ") and int(kit["source"]) < 0:
			kit["source"] = line.get_slice(" = ", 1).to_int()
		elif line.begins_with("body_rows = "):
			kit["body_rows"] = maxi(1, line.get_slice(" = ", 1).to_int())
		elif line.begins_with("origin = Vector2i("):
			var inside: String = line.get_slice("(", 1).get_slice(")", 0)
			kit["origin"] = Vector2i(inside.get_slice(",", 0).to_int(),
					inside.get_slice(",", 1).strip_edges().to_int())
	return kit


## ⚠ LE MARQUEUR PORTE SON ESPACE. Chercher « id= » tombe sur celui de « uid= », qui le
## contient : on lisait alors l'identifiant unique a la place du nom de la ressource, et
## aucune texture ne se retrouvait.
static func _quoted_after(line: String, marker: String) -> String:
	var at: int = line.find(marker)
	if at < 0:
		return ""
	var rest: String = line.substr(at + marker.length())
	var start: int = rest.find("\"")
	if start < 0:
		return ""
	rest = rest.substr(start + 1)
	var stop: int = rest.find("\"")
	return rest.substr(0, stop) if stop >= 0 else ""


## La tuile de sol qui convient a quatre coins donnes.
##
## ⚠ TOUTES LES COMBINAISONS N'EXISTENT PAS. Le tileset en declare une centaine, pas les
## six cent vingt-cinq possibles : quand la combinaison exacte manque, on prend celle qui
## partage le plus de coins. Une approximation visible vaut mieux qu'un trou.
static func floor_tile(corners: Dictionary, signature: String, resolved: Dictionary) -> Array:
	if corners.has(signature):
		return corners[signature]
	if resolved.has(signature):
		return resolved[signature]
	var wanted: PackedStringArray = signature.split(",")
	var best: Array = []
	var best_score: int = -1
	for candidate: String in corners.keys():
		var faces: PackedStringArray = candidate.split(",")
		var score: int = 0
		for i: int in range(4):
			if faces[i] == wanted[i]:
				score += 1
		if score > best_score:
			best_score = score
			best = corners[candidate]
	resolved[signature] = best
	return best
