# SOLUPAINT — le monde, pose avec les tuiles achetees.
#
# On lui donne un relief -- une hauteur par case -- et il pose tout : chaque massif entier, sa
# surface et sa jupe. Rien d'autre a savoir. C'est la moitie du projet qui rend l'autre utile :
# le logiciel prouve que les tuiles sont completes, celui-ci s'en sert.
#
# ⚠ IL NE FABRIQUE AUCUNE TUILE (charte, regle 3). Il n'y a ici ni composition, ni miroir, ni
# rotation : chaque case va chercher, dans la planche, la tuile que la regle designe. Si la
# regle en designait une qui n'existe pas, ce serait un trou -- et le compte de ces cas est
# DIT, jamais tu (voir `last_warning`).
#
# ⚠ DESIGNER SON TILESET N'EST PAS « CONFIGURER » (charte, regle 1). Le chemin du manifeste est
# du meme statut que le mode dans le logiciel : c'est le choix de CE QU'ON FABRIQUE, fait une
# fois avant de peindre, pas un curseur a ajuster en cours de route.
#
# ⚠ ET IL POSE LE SOL. La plaine est un massif comme les autres -- elle a sa surface et sa
# falaise, celle du BORD DU MONDE -- depuis que le vide se declare. Une case absente du
# dictionnaire est du HORS-MONDE, jamais de la plaine : un moteur qui lirait l'absence comme de
# la plaine etendrait le sol a l'infini et ne poserait aucune falaise de bord.
@tool
extends Node2D

const Manifest := preload("res://addons/solupaint/manifest.gd")
const Rules := preload("res://addons/solupaint/rules.gd")
const TileSetBuilder := preload("res://addons/solupaint/tileset.gd")

## Le manifeste livre avec le tileset : `<nom>_tileset.txt`. La planche est lue a cote de lui,
## sous le nom qu'il donne.
@export_file("*.txt") var manifest_path: String = "":
	set(value):
		manifest_path = value
		_reload()

## Le relief : case -> etage, de 0 a 9. Une case absente est HORS DU MONDE.
##
## ⚠ C'EST LA SEULE DONNEE DU MONDE. Aucune tuile n'est rangee ici -- elles se deduisent
## toutes de ce dictionnaire, donc il n'existe aucun etat ou le relief et ce qu'on voit se
## contrediraient.
@export var heights: Dictionary = {}:
	set(value):
		heights = value
		rebuild()

## Ce qui a empeche de LIRE le tileset. Vide quand tout va bien : le pinceau s'y fie
## pour savoir s'il peut s'armer.
var last_error: String = ""

## ⚠ ET CE QUI S'EST MAL PASSE A LA POSE EST UNE AUTRE CHOSE, DONC UNE AUTRE VARIABLE. Un
## manifeste qui se lit tres bien peut poser un monde dont quelques cases sortent du
## domaine ; melanger les deux ferait dire au pinceau « ce tileset ne se lit pas » alors
## qu'il se lit, et enverrait l'acheteur resoudre le mauvais probleme.
var last_warning: String = ""

## ⚠ UNE COUCHE PAR ETAGE, ET L'ORDRE DES ENFANTS EST L'ORDRE DE POSE. Une case recoit une pose
## par massif qui la contient -- les massifs sont emboites -- et deux poses d'une meme case ont
## forcement des etages differents, puisqu'a un etage donne une case n'appartient qu'a une
## composante. Empiler par etage croissant rend donc exactement ce que rend la liste triee du
## modele.
##
## ⚠ ET IL N'Y A PLUS DE COUCHE DE FALAISES A PART. Un massif se dessine ENTIER : sa jupe est
## sur la meme couche que sa surface, parce que c'est le meme massif. C'est ce qui supprime la
## question « les falaises passent-elles devant les sommets ? » -- l'etage y repond.
var _layers: Array[TileMapLayer] = []
var _manifest: Dictionary = {}
var _source: int = -1
var _tile_set: TileSet = null


func _ready() -> void:
	_reload()


## Relit le manifeste et refabrique le TileSet. Appele des que le chemin change.
func _reload() -> void:
	last_error = ""
	last_warning = ""
	_source = -1
	_tile_set = null
	if manifest_path == "":
		_clear_layers()
		return

	_manifest = Manifest.read(manifest_path)
	if int(_manifest["error"]) != OK:
		last_error = String(_manifest["reason"])
		push_warning("SoluPaint: %s" % last_error)
		_clear_layers()
		return

	# ⚠ UN MANIFESTE INCOMPLET EST REFUSE (charte, regle 5). Il ne manque jamais une tuile a un
	# export honnete ; s'il en manque une ici, c'est que le fichier a ete retouche a la main, et
	# poser les autres laisserait un trou qu'on decouvrirait dans le jeu.
	if not Manifest.is_complete(_manifest):
		last_error = "Ce manifeste place %d tuiles ; il en faut %d." % [
				_manifest["slots"].size(), Manifest.MASSIF_TILES]
		push_warning("SoluPaint: %s" % last_error)
		_clear_layers()
		return

	var built: Dictionary = TileSetBuilder.build(manifest_path.get_base_dir(), _manifest)
	if int(built["error"]) != OK:
		last_error = String(built["reason"])
		push_warning("SoluPaint: %s" % last_error)
		_clear_layers()
		return

	_tile_set = built["tile_set"]
	_source = int(built["source"])
	rebuild()


## REPOSE TOUT LE MONDE DEPUIS LE RELIEF.
##
## ⚠ ET IL N'Y A PAS DE ZONE A REFAIRE ICI, CONTRAIREMENT A L'ANCIEN MODELE. La portee d'un
## changement n'y est pas bornee : un massif est une COMPOSANTE CONNEXE, et le bit « au ras »
## est une propriete du massif ENTIER. Poser une case peut donc reunir deux massifs, ou faire
## deborder un massif de son porteur -- et alors TOUT son contour change de regle, d'un bout du
## monde a l'autre. Une zone bornee laisserait le monde faux pendant qu'on le dessine, et rien
## ne le signalerait : entre « un peu lent » et « faux en silence », le choix n'est pas serre.
##
## Mesure, pour savoir ce qu'on paie : 3 ms sur 16x16, 14 ms sur 32x32, 75 ms sur 64x64,
## 209 ms sur 96x96. Une carte de jeu plus grande demandera un calcul incremental -- il est
## possible, il n'est pas ecrit, et il ne se devine pas.
func rebuild() -> void:
	if _tile_set == null or _source < 0:
		return
	var poses: Array[Dictionary] = Rules.poses(heights)
	var wanted: int = 0
	for one: Dictionary in poses:
		wanted = maxi(wanted, int(one["level"]) + 1)
	_ensure_layers(wanted)
	for layer: TileMapLayer in _layers:
		layer.clear()
	# ⚠ UNE TUILE QUE LA PLANCHE N'A PAS EST COMPTEE, PAS SAUTEE EN SILENCE. Un export honnete
	# les porte toutes ; s'il en manque une ici, c'est que le relief sort du domaine que le
	# pinceau garantit -- et un trou muet dans le monde est le pire des defauts.
	#
	# ⚠ ET UNE POSE QUI EN RECOUVRE UNE AUTRE SUR LA MEME COUCHE SE COMPTE AUSSI. « Une case
	# n'a qu'une pose par etage » est un theoreme SOUS min trois : deux composantes d'un meme
	# etage y sont separees d'au moins trois rangees de vide, alors qu'une jupe n'en descend
	# que trois. Un relief pose a l'inspecteur peut violer min trois -- le pinceau, lui, le
	# refuse -- et alors une jupe retombe sur la surface d'un voisin. Une couche ne peut porter
	# qu'une tuile par case : on le DIT plutot que d'en perdre une en silence.
	var unknown: int = 0
	var covered: int = 0
	var slots: Dictionary = _manifest["slots"]
	for two: Dictionary in poses:
		var tile: int = Rules.key_of(two)
		if not slots.has(tile):
			unknown += 1
			continue
		var layer2: TileMapLayer = _layers[int(two["level"])]
		var at: Vector2i = two["cell"]
		if layer2.get_cell_source_id(at) != -1:
			covered += 1
		layer2.set_cell(at, _source, slots[tile])
	var said: PackedStringArray = PackedStringArray()
	if unknown > 0:
		said.append("%d case(s) demandent une tuile que la planche n'a pas." % unknown)
	if covered > 0:
		said.append(("%d pose(s) en recouvrent une autre : ce relief a des bandes de moins "
				+ "de trois cases.") % covered)
	last_warning = " ".join(said)


## POSE OU RETIRE UN LOT DE CASES, ET REND LE CONTRE-GESTE : la valeur d'AVANT de chaque case
## reellement changee (`Rules.VOID` pour une case qui n'existait pas). Rejouer ce dictionnaire
## dans `apply()` defait exactement le geste -- c'est ce que l'annulation du pinceau
## enregistre, au lieu de photographier la carte entiere deux fois par trait.
##
## ⚠ UNE CASE QUI NE CHANGE PAS NE COUTE RIEN, et c'est ce qui garde le contre-geste minimal :
## une case intacte n'a rien a defaire. Le pinceau repasse sans cesse sur ses propres cases.
##
## ⚠ ON MUTE `heights` EN PLACE, SANS PASSER PAR SON SETTER. L'affectation declencherait un
## second `rebuild()` pour rien.
func apply(changes: Dictionary) -> Dictionary:
	var undo: Dictionary = {}
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
	if not undo.is_empty():
		rebuild()
	return undo


## Change l'etage d'une case, et repose le monde.
##
## ⚠ ET L'ETAGE 0 EST UN ETAGE, PAS UN EFFACEMENT. Depuis que l'absence vaut le HORS-MONDE,
## poser la plaine et retirer une case sont deux gestes differents -- et les confondre fait
## disparaitre le sol au lieu de l'aplanir. Pour retirer une case : `Rules.VOID`.
func set_level(cell: Vector2i, level: int) -> void:
	apply({cell: level})


## Retire une case du monde : elle redevient du hors-monde, pas de la plaine.
func clear_cell(cell: Vector2i) -> void:
	set_level(cell, Rules.VOID)


## Pose un rectangle de monde d'un seul etage. De quoi avoir un sol sous la main avant de
## dessiner le relief -- sans lui, un monde vide n'a rien a border et ne montre rien.
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


## ⚠ LES COUCHES SUIVENT LE MONDE. Un monde qui GRANDIT gardait ses couches d'avant, et les
## etages au-dessus n'etaient simplement pas poses -- des sommets absents, sans une erreur.
func _ensure_layers(wanted: int) -> void:
	while _layers.size() < maxi(1, wanted):
		var layer: TileMapLayer = TileMapLayer.new()
		layer.name = "Massif%d" % _layers.size()
		# ⚠ LE FILTRAGE EST AU PLUS PROCHE. Un lissage bilineaire melangerait les bords voisins
		# de l'atlas, et le monde montrerait des coutures que le dessin n'a pas.
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(layer)
		_layers.append(layer)
	for one: TileMapLayer in _layers:
		one.tile_set = _tile_set


func _clear_layers() -> void:
	for layer: TileMapLayer in _layers:
		layer.clear()
