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

## ⚠ UNE COUCHE PAR ETAGE, ET UN SOUS-PIED PAR ETAGE. L'ordre des enfants EST l'ordre de
## pose : sous-pied 0, surface 0, sous-pied 1, surface 1... puis les falaises par-dessus.
## Le sous-pied d'une chute qui atterrit a l'etage L doit passer sous la surface L -- et
## au-dessus de celle d'en dessous, sans quoi elle le recouvrirait.
var _underfoot_layers: Array[TileMapLayer] = []
var _surface_layers: Array[TileMapLayer] = []
var _walls_layer: TileMapLayer = null
var _manifest: Dictionary = {}
## L'etage le plus haut du monde, garde sous la main.
## ⚠ IL NE REDESCEND QU'AU RELEVE COMPLET, et c'est voulu : le garder trop haut elargit la
## zone a refaire -- un peu de temps perdu -- alors que le garder trop bas la retrecirait, et
## laisserait le monde faux. Entre les deux erreurs, une seule est tolerable.
var _top: int = 0
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

	_top = Rules.top_level(heights)
	_ensure_layers()
	_walls_layer.tile_set = built["tile_set"]
	_surface_source = int(built["surface_source"])
	_walls_source = int(built["walls_source"])

	_dress_layers()

	rebuild()


## Repose tout le monde depuis le relief.
##
## ⚠ LES FACES APRES LES SOMMETS. Une falaise occupe des cases qui, vues de dessus,
## appartiennent au sol d'en bas : elle passe donc PAR-DESSUS, sur sa propre couche.
func rebuild() -> void:
	if _walls_layer == null or _surface_source < 0:
		return
	# ⚠ LES TROIS COUCHES, PAS DEUX. Le sous-pied n'etait pas nettoye : ses tuiles
	# s'accumulaient a chaque coup de crayon et ne disparaissaient jamais. Retirer un plateau
	# laissait donc la roche de sa falaise sous le sol, et le monde devenait faux PENDANT
	# qu'on le dessinait. Une couche qu'on pose sans la nettoyer est une fuite.
	_clear_layers()
	_top = Rules.top_level(heights)
	# ⚠ LES COUCHES SUIVENT LE MONDE, ICI AUSSI. Seul `_reload` les taillait : un monde qui
	# GRANDISSAIT par le setter `heights` gardait ses couches d'avant, et les etages
	# au-dessus n'etaient simplement pas poses -- des sommets absents, sans une erreur.
	# Mesure sur la scene d'essai instanciee : une seule couche de surface au lieu de trois.
	_ensure_layers()

	_lay_surfaces(_world_region())
	_lay_walls(Rules.underfoot(heights), Rules.walls(heights))


## POSE OU RETIRE UN LOT DE CASES, NE REPOSE QUE CE QUI A PU DEVENIR FAUX, ET REND LE
## CONTRE-GESTE : la valeur d'AVANT de chaque case reellement changee (`Rules.VOID` pour
## une case qui n'existait pas). Rejouer ce dictionnaire dans `apply()` defait exactement
## le geste -- c'est ce que l'annulation du pinceau enregistre, au lieu de photographier
## la carte entiere deux fois par trait.
##
## ⚠ C'EST LE CHEMIN DU PINCEAU, ET CELUI DE TOUTE ECRITURE. `rebuild()` refait la carte
## entiere : juste, et intenable au coup de crayon -- mesure, 7 ms sur 32x24 mais 456 ms
## sur 256x192, et c'est PAR CASE PEINTE. La zone, elle, ne depend que de la portee du
## modele, pas de la taille du monde. `set_level`, `clear_cell` et `fill` passent par ici.
##
## ⚠ UNE CASE QUI NE CHANGE PAS NE COUTE RIEN. Reposer la meme valeur repayait la zone
## entiere -- mesure, 2,9 ms l'appel pour ne rien changer, et le pinceau repasse sans
## cesse sur ses propres cases. Ne rien poser est aussi ce qui garde le contre-geste
## minimal : une case intacte n'a rien a defaire.
##
## ⚠ ON MUTE `heights` EN PLACE, SANS PASSER PAR SON SETTER. L'affectation declencherait
## `rebuild()` -- toute la carte -- et le gain serait perdu au premier pixel. Un dictionnaire
## se modifie par reference : c'est exactement ce qu'il faut ici.
func apply(changes: Dictionary) -> Dictionary:
	var undo: Dictionary = {}
	var touched: Array[Vector2i] = []
	for cell: Vector2i in changes.keys():
		var level: int = int(changes[cell])
		var wanted: int = clampi(level, 0, 9) if level >= 0 else Rules.VOID
		var previous: int = int(heights.get(cell, Rules.VOID))
		if previous == wanted:
			continue
		undo[cell] = previous
		if wanted < 0:
			heights.erase(cell)
		else:
			heights[cell] = wanted
			_top = maxi(_top, wanted)
		touched.append(cell)
	if not touched.is_empty():
		rebuild_region(Rules.region_of(heights, touched, _top))
	return undo


## Repose une zone : on efface d'abord, puis on pose. Les trois couches.
##
## ⚠ EFFACER D'ABORD N'EST PAS UNE PRECAUTION. Une case qui ne porte PLUS rien doit
## redevenir vide ; se contenter d'ecrire par-dessus laisse la tuile d'avant partout ou la
## nouvelle passe n'ecrit pas. C'est exactement la faute qui laissait le sous-pied
## s'accumuler sur toute la carte.
func rebuild_region(region: Rect2i) -> void:
	if _walls_layer == null or _surface_source < 0:
		return
	_ensure_layers()
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			var at: Vector2i = Vector2i(x, y)
			_walls_layer.erase_cell(at)
			for level: int in range(_surface_layers.size()):
				_underfoot_layers[level].erase_cell(at)
				_surface_layers[level].erase_cell(at)
	_lay_surfaces(region)
	var walls: Dictionary = Rules.walls_in(heights, region, _top)
	_lay_walls(walls["underfoot"], walls["roles"])


## POSE LES SURFACES D'UNE ZONE, ETAGE PAR ETAGE, DU BAS VERS LE HAUT.
##
## ⚠ UNE CASE PORTE AUTANT DE TUILES QU'ELLE A D'ETAGES SOUS ELLE. Une case a l'etage 2
## appartient AUSSI a la silhouette de l'etage 1 et a celle de l'etage 0 : l'etage N-1
## continue SOUS le plateau de l'etage N. Ne poser que la tuile VISIBLE laissait le coin
## decoupe d'un plateau ouvert sur RIEN -- un angle noir en haut de chaque plateau, la ou il
## devrait montrer l'etage d'en dessous.
##
## C'est deja ce que dit la regle de pose : « on dessine du bas vers le haut, chaque couche
## recouvrant la precedente ». L'illustration le faisait, le plugin non -- et l'epaule
## bouchait le trou au sud, ce qui a longtemps cache la divergence.
##
## ⚠ LA FAMILLE A CHEVAL NE S'EMPILE PAS. Une tuile de croisement se lit du sommet des
## quatre cases qu'elle chevauche, pas d'un etage : il n'y a rien a empiler, et une seule
## couche suffit. On ne fabrique pas un etage qu'elle n'a pas.
func _lay_surfaces(region: Rect2i) -> void:
	var slots: Dictionary = _manifest["surface_slots"]
	if _manifest["family"] == Manifest.BY_CORNER:
		var crossings: Dictionary = Rules.corners_in(heights, region)
		for at: Vector2i in crossings.keys():
			var index: int = int(crossings[at])
			if slots.has(index):
				_surface_layers[0].set_cell(at, _surface_source, slots[index])
		return
	for level: int in range(_surface_layers.size()):
		var floorwise: Dictionary = Rules.surfaces_at_level(heights, level, region)
		for at: Vector2i in floorwise.keys():
			var index: int = int(floorwise[at])
			if slots.has(index):
				_surface_layers[level].set_cell(at, _surface_source, slots[index])


## Pose les sous-pieds et les faces.
##
## ⚠ LE SOUS-PIED VA SUR LA COUCHE DE L'ETAGE OU IL ATTERRIT. C'est celle-la qu'il doit
## passer dessous -- il ne se montre que par ses coins decoupes -- et au-dessus de celle d'en
## dessous, sinon elle le recouvrirait.
func _lay_walls(underfoot: Dictionary, roles: Dictionary) -> void:
	var wall_slots: Dictionary = _manifest["wall_slots"]
	# ⚠ EN FAMILLE A CHEVAL, TOUTE POSE DERRIERE VA SOUS LA COUCHE UNIQUE. Les tuiles
	# duales vivent toutes sur Surface0 : posee sur SousPied1 ou plus, une roche passerait
	# DEVANT elles, et la case d'atterrissage montrait un carre de pierre a la place de
	# son dessus. L'assembly pose les sous-pieds avant toutes les tuiles ; ici pareil.
	var corner: bool = _manifest.get("family", "") == Manifest.BY_CORNER
	for cell: Vector2i in underfoot.keys():
		var under: Vector2i = underfoot[cell]
		if not wall_slots.has(under):
			continue
		var landing: int = 0 if corner else clampi(Rules.level_at(heights, cell), 0,
				_underfoot_layers.size() - 1)
		_underfoot_layers[landing].set_cell(cell, _walls_source, wall_slots[under])
	for cell: Vector2i in roles.keys():
		var role: Vector2i = roles[cell]
		if wall_slots.has(role):
			_walls_layer.set_cell(cell, _walls_source, wall_slots[role])


## L'etendue du monde, plus la marge qu'une falaise peut atteindre.
func _world_region() -> Rect2i:
	if heights.is_empty():
		return Rect2i()
	var cells: Array[Vector2i] = []
	for cell: Vector2i in heights.keys():
		cells.append(cell)
	return Rules.region_of(heights, cells, _top)


## Change l'etage d'une case, et repose ce qui en depend.
##
## ⚠ PAR LA ZONE, PLUS PAR LA CARTE ENTIERE. Cette fonction refaisait tout le monde a
## chaque appel -- « franc et tenable » du temps ou la zone n'existait pas. La zone est
## depuis PROUVEE equivalente au releve complet (le test du pinceau la compare dans les
## deux sens), et le releve complet coutait ici 48,9 ms sur 64x45 et 572,8 ms sur 200x150
## PAR CASE POSEE. On passe par `apply()`, comme toute ecriture : ~3 ms, quelle que soit
## la carte. Seule difference, deja documentee sur `_top` : il ne redescend qu'au releve
## complet -- trop haut elargit un peu la zone, trop bas laisserait le monde faux.
##
## ⚠ ET L'ETAGE 0 EST UN ETAGE, PAS UN EFFACEMENT. Cette fonction n'avait pas suivi
## l'inversion du vide : elle effacait la case des qu'on lui demandait l'etage 0, ce qui
## revenait a la sortir du monde. Depuis que l'absence vaut le HORS-MONDE, poser la plaine
## et retirer une case sont deux gestes differents -- et les confondre faisait disparaitre
## le sol au lieu de l'aplanir. Pour retirer une case, `Rules.VOID` ou n'importe quel
## niveau negatif.
func set_level(cell: Vector2i, level: int) -> void:
	apply({cell: level})


## Retire une case du monde : elle redevient du hors-monde, pas de la plaine.
func clear_cell(cell: Vector2i) -> void:
	set_level(cell, Rules.VOID)


## Pose un rectangle de monde d'un seul etage. De quoi avoir un sol sous la main avant de
## dessiner le relief -- sans lui, un monde vide n'a rien a border et ne montre rien.
## Par `apply()`, comme toute ecriture : les cases deja au bon etage ne coutent rien.
func fill(from: Vector2i, to: Vector2i, level: int = 0) -> void:
	var changes: Dictionary = {}
	for y: int in range(mini(from.y, to.y), maxi(from.y, to.y) + 1):
		for x: int in range(mini(from.x, to.x), maxi(from.x, to.x) + 1):
			changes[Vector2i(x, y)] = level
	apply(changes)


func level_at(cell: Vector2i) -> int:
	return Rules.level_at(heights, cell)


## La case du monde sous un point local, en coordonnees de case.
func cell_at(point: Vector2) -> Vector2i:
	var side: int = int(_manifest.get("tile_size", 0))
	if side <= 0:
		return Vector2i.ZERO
	return Vector2i(floori(point.x / float(side)), floori(point.y / float(side)))


## ⚠ L'ORDRE DES ENFANTS EST L'ORDRE DE POSE, et il dit la regle en clair : pour chaque
## etage, son sous-pied puis sa surface ; les falaises tout au-dessus.
func _ensure_layers() -> void:
	var wanted: int = maxi(1, _top + 1)
	while _surface_layers.size() < wanted:
		var level: int = _surface_layers.size()
		_underfoot_layers.append(_make_layer("SousPied%d" % level))
		_surface_layers.append(_make_layer("Surface%d" % level))
	if _walls_layer == null:
		_walls_layer = _make_layer("Falaises")
	else:
		# ⚠ LES FALAISES RESTENT LES DERNIERES. Ajouter la couche d'un nouvel etage l'insere
		# APRES elles : sans ce rappel a la fin, une falaise passerait derriere un sommet.
		move_child(_walls_layer, get_child_count() - 1)
	_dress_layers()


## ⚠ LA FAMILLE A CHEVAL DECALE LA COUCHE D'UNE DEMI-CASE, ET C'EST TOUT LE DECALAGE QU'IL
## FAUT. Une tuile duale est posee sur le CROISEMENT de quatre cases : le croisement (i, j)
## est le coin commun, donc la tuile qui s'y centre commence a une demi-case au nord-ouest.
## Le decalage vaut pour la couche entiere, jamais case par case.
func _dress_layers() -> void:
	if _walls_layer == null:
		return
	var side: int = int(_manifest.get("tile_size", 0))
	var corner: bool = _manifest.get("family", "") == Manifest.BY_CORNER
	var shift: float = -0.5 * float(side) if corner else 0.0
	for layer: TileMapLayer in _surface_layers:
		layer.tile_set = _walls_layer.tile_set
		layer.position = Vector2(shift, shift)
	for layer: TileMapLayer in _underfoot_layers:
		layer.tile_set = _walls_layer.tile_set


## ⚠ LE FILTRAGE EST AU PLUS PROCHE. Un lissage bilineaire melangerait les bords voisins de
## l'atlas, et le monde montrerait des coutures que le dessin n'a pas.
func _make_layer(layer_name: String) -> TileMapLayer:
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = layer_name
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(layer)
	return layer


func _clear_layers() -> void:
	for layer: TileMapLayer in _underfoot_layers:
		layer.clear()
	for layer: TileMapLayer in _surface_layers:
		layer.clear()
	if _walls_layer != null:
		_walls_layer.clear()
