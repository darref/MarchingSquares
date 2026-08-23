# ABSOLUPAINT — le monde, pose avec les tuiles achetees.
#
# On lui donne un relief -- une hauteur par case -- et il pose tout : les sommets de chaque
# etage, puis les faces de falaise. Rien d'autre a savoir. C'est la moitie du projet qui
# rend l'autre utile : le logiciel prouve que les tuiles sont completes, celui-ci s'en sert.
#
# ⚠ IL NE FABRIQUE AUCUNE TUILE (charte, regle 3). Il n'y a ici ni composition, ni miroir,
# ni rotation : chaque case va chercher, dans la planche, la tuile que la regle designe. Si
# la regle en designait une qui n'existe pas, ce serait un trou -- et c'est justement ce que
# l'export rend impossible en refusant une feuille incomplete.
#
# ⚠ DESIGNER SON TILESET N'EST PAS « CONFIGURER » (charte, regle 1). Le chemin du manifeste
# est du meme statut que le mode dans le logiciel : c'est le choix de CE QU'ON FABRIQUE, fait
# une fois avant de peindre, pas un curseur a ajuster en cours de route.
#
# ⚠ ET IL N'Y A PAS DE SOL. La plaine n'est pas une tuile du tileset : le modele ne sait pas
# distinguer « case a l'etage 0 » de « case hors du monde », donc il ne peut pas dire ou le
# sol s'arrete. Poser un etage 0 ici reviendrait a inventer cette frontiere a la place de
# l'acheteur. Le sol se pose sur sa propre couche, par le jeu, tant que le modele n'a pas de
# marqueur de vide distinct de la plaine.
@tool
extends Node2D

const Manifest := preload("res://addons/absolupaint/manifest.gd")
const Rules := preload("res://addons/absolupaint/rules.gd")
const TileSetBuilder := preload("res://addons/absolupaint/tileset.gd")

## Le manifeste livre avec le tileset : `<nom>_tileset.txt`. Les deux planches sont lues a
## cote de lui, sous les noms qu'il donne.
@export_file("*.txt") var manifest_path: String = "":
	set(value):
		manifest_path = value
		_reload()

## Le relief : case -> etage, de 1 a 9. Une case absente est a la plaine.
##
## ⚠ C'EST LA SEULE DONNEE DU MONDE. Aucune tuile n'est rangee ici -- elles se deduisent
## toutes de ce dictionnaire, donc il n'existe aucun etat ou le relief et ce qu'on voit se
## contrediraient.
@export var heights: Dictionary = {}:
	set(value):
		heights = value
		rebuild()

## Dit ce qui s'est passe au dernier chargement. Vide quand tout va bien.
var last_error: String = ""

var _underfoot_layer: TileMapLayer = null
var _surface_layer: TileMapLayer = null
var _walls_layer: TileMapLayer = null
var _manifest: Dictionary = {}
var _surface_source: int = -1
var _walls_source: int = -1


func _ready() -> void:
	_reload()


## Relit le manifeste et refabrique le TileSet. Appele des que le chemin change.
func _reload() -> void:
	last_error = ""
	_surface_source = -1
	_walls_source = -1
	if manifest_path == "":
		_clear_layers()
		return

	_manifest = Manifest.read(manifest_path)
	if int(_manifest["error"]) != OK:
		last_error = String(_manifest["reason"])
		push_warning("AbsoluPaint: %s" % last_error)
		_clear_layers()
		return

	# ⚠ UN MANIFESTE INCOMPLET EST REFUSE (charte, regle 5). Il ne manque jamais une tuile a
	# un export honnete ; s'il en manque une ici, c'est que le fichier a ete retouche a la
	# main, et poser les autres laisserait un trou qu'on decouvrirait dans le jeu.
	if not Manifest.is_complete(_manifest):
		last_error = ("Ce manifeste place %d tuiles de surface et %d de falaise ; il en faut "
				+ "%d et %d.") % [_manifest["surface_slots"].size(),
				_manifest["wall_slots"].size(),
				Manifest.expected_surface_tiles(_manifest["family"]),
				Rules.PAN_COUNT * Rules.BLOCK_ROWS]
		push_warning("AbsoluPaint: %s" % last_error)
		_clear_layers()
		return

	var built: Dictionary = TileSetBuilder.build(manifest_path.get_base_dir(), _manifest)
	if int(built["error"]) != OK:
		last_error = String(built["reason"])
		push_warning("AbsoluPaint: %s" % last_error)
		_clear_layers()
		return

	_ensure_layers()
	_surface_layer.tile_set = built["tile_set"]
	_walls_layer.tile_set = built["tile_set"]
	_surface_source = int(built["surface_source"])
	_walls_source = int(built["walls_source"])

	# ⚠ LA FAMILLE A CHEVAL DECALE LA COUCHE D'UNE DEMI-CASE, ET C'EST TOUT LE DECALAGE
	# QU'IL FAUT. Une tuile duale est posee sur le CROISEMENT de quatre cases : le croisement
	# (i, j) est le coin commun, donc la tuile qui s'y centre commence a une demi-case au
	# nord-ouest. Le decalage vaut pour la couche entiere, jamais case par case.
	var side: int = int(_manifest["tile_size"])
	var shift: float = -0.5 * float(side) if _manifest["family"] == Manifest.BY_CORNER else 0.0
	_surface_layer.position = Vector2(shift, shift)

	rebuild()


## Repose tout le monde depuis le relief.
##
## ⚠ LES FACES APRES LES SOMMETS. Une falaise occupe des cases qui, vues de dessus,
## appartiennent au sol d'en bas : elle passe donc PAR-DESSUS, sur sa propre couche.
func rebuild() -> void:
	if _surface_layer == null or _surface_source < 0:
		return
	_surface_layer.clear()
	_walls_layer.clear()

	var slots: Dictionary = _manifest["surface_slots"]
	var surface: Dictionary = Rules.corners(heights) if _manifest["family"] == Manifest.BY_CORNER 			else Rules.surfaces(heights)
	for at: Vector2i in surface.keys():
		var index: int = int(surface[at])
		if slots.has(index):
			_surface_layer.set_cell(at, _surface_source, slots[index])

	var wall_slots: Dictionary = _manifest["wall_slots"]
	# ⚠ LE SOUS-PIED SE POSE SOUS LES SURFACES, sur sa propre couche. C'est le PIED repose
	# une case plus bas : la case d'atterrissage le recouvre sauf par ses coins decoupes, et
	# c'est exactement la que la roche manquait. Aucune tuile de plus -- une pose de plus.
	var underfoot: Dictionary = Rules.underfoot(heights)
	for cell: Vector2i in underfoot.keys():
		var under: Vector2i = underfoot[cell]
		if wall_slots.has(under):
			_underfoot_layer.set_cell(cell, _walls_source, wall_slots[under])
	var roles: Dictionary = Rules.walls(heights)
	for cell: Vector2i in roles.keys():
		var role: Vector2i = roles[cell]
		if wall_slots.has(role):
			_walls_layer.set_cell(cell, _walls_source, wall_slots[role])


## Change l'etage d'une case, et repose ce qui en depend.
##
## ⚠ UNE CASE CHANGE BIEN PLUS QUE SA PROPRE TUILE : ses huit voisines changent d'index, et
## une falaise peut s'allonger de six cases vers le sud. On repose donc tout. C'est franc,
## et ca reste tenable tant que le monde tient en memoire.
func set_level(cell: Vector2i, level: int) -> void:
	var clamped: int = clampi(level, 0, 9)
	if clamped <= 0:
		heights.erase(cell)
	else:
		heights[cell] = clamped
	rebuild()


func level_at(cell: Vector2i) -> int:
	return Rules.level_at(heights, cell)


## La case du monde sous un point local, en coordonnees de case.
func cell_at(point: Vector2) -> Vector2i:
	var side: int = int(_manifest.get("tile_size", 0))
	if side <= 0:
		return Vector2i.ZERO
	return Vector2i(floori(point.x / float(side)), floori(point.y / float(side)))


func _ensure_layers() -> void:
	# ⚠ L'ORDRE DES COUCHES EST L'ORDRE DE POSE, et le sous-pied vient EN PREMIER : il doit
	# passer SOUS la surface, sans quoi il masquerait le sol au lieu de se montrer par les
	# coins decoupes de la case d'atterrissage.
	if _underfoot_layer == null:
		_underfoot_layer = _make_layer("SousPied")
	if _surface_layer == null:
		_surface_layer = _make_layer("Surface")
	if _walls_layer == null:
		_walls_layer = _make_layer("Falaises")


## ⚠ LE FILTRAGE EST AU PLUS PROCHE. Un lissage bilineaire melangerait les bords voisins de
## l'atlas, et le monde montrerait des coutures que le dessin n'a pas.
func _make_layer(layer_name: String) -> TileMapLayer:
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = layer_name
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(layer)
	return layer


func _clear_layers() -> void:
	if _underfoot_layer != null:
		_underfoot_layer.clear()
	if _surface_layer != null:
		_surface_layer.clear()
	if _walls_layer != null:
		_walls_layer.clear()
