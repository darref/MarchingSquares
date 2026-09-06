# LA ROOM DE TEST — un vrai relief, pose par LE MOTEUR, rendu avec VOS tuiles.
#
# ⚠ ELLE POSE AVEC `addons/solupaint/rules.gd`, JAMAIS AVEC `core/massifs.gd`. C'est ce qui la
# rend juste : branchee sur le noyau, elle prouverait seulement que le noyau s'accorde avec
# lui-meme. Branchee sur la copie qui part chez l'acheteur, elle devient un CONTROLE CROISE
# VIVANT -- le desaccord, s'il existe, se voit a l'ecran, sur le trait de l'artiste, avant
# d'etre livre. `rules.gd` ne precharge rien et se lit en headless : rien n'empeche le produit
# de l'ouvrir.
#
# ⚠ ET CE N'EST PAS L'APERCU SUPPRIME LE 05/09. Celui-la reposait TOUT SEUL les memes tuiles
# sur une colline FIXE, et disait donc ce que le guide dit deja en permanence. Ici c'est
# l'artiste qui pose le relief, et ce qu'il regarde est precisement ce qu'aucun damier ne
# montre : ses tuiles VOISINES, dans des combinaisons que le guide juxtapose sans les composer.
# Le cisaillement du massif 21 a ete releve exactement comme ca -- sur du trait remonte, en
# situation, et par aucun autre moyen.
extends Control

const PluginRules := preload("res://addons/solupaint/rules.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")
const WorkIO := preload("res://core/work_io.gd")
const Families := preload("res://core/families.gd")
const WorkArea := preload("res://ui/work_area.gd")

## Ce que la room a sous la main : combien de tuiles elle sait poser, et combien de poses
## sont restees sans dessin.
signal report_changed(drawn: int, missing: int)

## L'AIRE D'ESSAI, BORNEE. ⚠ LE MONDE DU MOTEUR NE L'EST PAS -- c'est un dictionnaire case ->
## etage -- mais l'aire qu'on peint ici l'est, et pour une raison mesuree : on repose TOUT a
## chaque coup (voir `_stamp`), et le plugin met 3 ms sur 16x16, 14 sur 32x32, 75 sur 64x64,
## 209 sur 96x96. A 40x26 on reste sous la dizaine de millisecondes, donc sous le seuil ou la
## main sent l'attente.
const SPAN: Vector2i = Vector2i(40, 26)

## Le tampon du geste : trois sur trois, et c'est lui qui garantit min trois par construction.
const STAMP: int = 3

## L'etage le plus haut qu'on puisse empiler ici. Le dock du plugin en offre autant.
const TOP_LEVEL: int = 4

## Marge autour de l'aire, en cases, pour que la falaise du bord du monde ait ou tomber.
const MARGIN: float = 1.5

var _heights: Dictionary = {}
var _art: Dictionary = {}
var _hover: Vector2i = Vector2i(-999, -999)
var _refused: bool = true
var _missing: int = 0
## La carte des couches, tenue une fois par coup plutot que refaite a chaque dessin.
var _layers: Dictionary = {}
var _cell_px: float = 18.0
var _origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# ⚠ AU PLUS PROCHE, JAMAIS LISSE. Un filtrage bilineaire melangerait les bords voisins
	# et montrerait des degrades que la peinture n'a pas -- exactement le defaut que tout ce
	# projet existe pour eviter, et la meme ligne vit deja dans `addons/solupaint`.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# ⚠ ON PASSE PAR LE SIGNAL, PAS PAR LA VIRTUELLE `_gui_input`. Les deux recoivent les memes
	# evenements quand c'est la souris qui parle -- mais `gui_input.emit()` n'appelle QUE les
	# branchements du signal, jamais la virtuelle. Or la relecture (`ui/screenshot.gd`) pose son
	# relief en emettant de vrais clics : avec la virtuelle, elle capturait une room vide sans
	# une seule erreur. Le bandeau du mode d'emploi est branche de la meme facon, et pour la
	# meme raison.
	gui_input.connect(_on_input)
	resized.connect(_fit)
	_fit()


# --- CE QU'ON A SOUS LA MAIN ------------------------------------------------

## Reprend les tuiles peintes. ⚠ ON PASSE PAR `MassifTileset.analyse`, celui de l'EXPORT :
## c'est la premiere occurrence peinte qui sort, quel que soit son rang, exactement comme sur
## la planche livree. Une room de test qui choisirait autrement montrerait un tileset que
## personne ne recevra.
func adopt(painting: RefCounted, guide: PackedStringArray) -> void:
	_art.clear()
	if painting == null or guide.is_empty():
		_refresh()
		return
	var report: Dictionary = MassifTileset.analyse(painting, guide)
	var by_key: Dictionary = WorkIO.cells_by_key(guide, Families.BY_MASSIF)
	var source: Dictionary = report["source"]
	for tile: Variant in source.keys():
		var key: String = "M%d:%d" % [int(tile), int(source[tile])]
		if not by_key.has(key):
			continue
		var drawn: Image = painting.image_of(by_key[key])
		if drawn == null:
			continue
		_art[int(tile)] = ImageTexture.create_from_image(drawn)
	_refresh()


## Le relief courant, pour qui veut le relire. Le carnet ne le garde pas encore : la carte
## d'essai vit hors du `.solutiles` tant que le format n'a pas ouvert son troisieme axe.
func heights() -> Dictionary:
	return _heights.duplicate()


func clear_world() -> void:
	_heights.clear()
	_refresh()


# --- LE GESTE ---------------------------------------------------------------

func _on_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_hover_at(motion.position)
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_LEFT:
		_stamp(_cell_at(click.position), true)
	elif click.button_index == MOUSE_BUTTON_RIGHT:
		_stamp(_cell_at(click.position), false)


## LE TAMPON. Clic gauche monte d'un etage, clic droit abaisse -- et il descend jusqu'au VIDE,
## comme le pinceau livre qui offre les etages 0..N *et* « Vide ».
##
## ⚠ LE REFUS EST CELUI DU MOTEUR, PAS CELUI DU NOYAU. `PluginRules.stamp_refused` porte la
## case fine ET le pincement diagonal, et c'est le meme code qui refusera chez l'acheteur.
func _stamp(centre: Vector2i, raise: bool) -> void:
	if not _inside(centre):
		return
	var cells: Array[Vector2i] = _stamp_cells(centre)
	var wanted: int = _stamp_level(cells, raise)
	if raise and wanted > TOP_LEVEL:
		return
	var staged: Dictionary = {}
	if PluginRules.stamp_refused(_heights, staged, cells, wanted):
		return
	for at: Vector2i in cells:
		if wanted < 0:
			_heights.erase(at)
		else:
			_heights[at] = wanted
	_refresh()


## L'etage que le tampon poserait. ⚠ ON PART DU PLANCHER DU TAMPON, PAS DE LA CASE VISEE : un
## tampon qui monterait chaque case d'un etage fabriquerait des marches d'une case de large,
## que min trois refuse aussitot.
func _stamp_level(cells: Array[Vector2i], raise: bool) -> int:
	var floor_at: int = 9
	for at: Vector2i in cells:
		floor_at = mini(floor_at, PluginRules.level_at(_heights, at))
	return floor_at + 1 if raise else floor_at - 1


func _stamp_cells(centre: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var half: int = STAMP / 2
	for dy: int in range(-half, half + 1):
		for dx: int in range(-half, half + 1):
			out.append(centre + Vector2i(dx, dy))
	return out


## ⚠ LE REFUS SE VOIT AVANT LE CLIC. Le curseur est cercle de blanc la ou le tampon passe, de
## rouge la ou il ne passe pas -- meme grammaire que la case survolee de la zone de travail,
## ou le crayon dit non avant qu'on ait clique (charte, regle 5).
func _hover_at(where: Vector2) -> void:
	# ⚠ LE SURVOL SE SUIT A LA CASE, PAS AU PIXEL. Le refus demande vingt-cinq sondes de
	# finesse et de pincement ; le recalculer a chaque micro-mouvement rendrait la souris
	# lourde pour un verdict qui ne change qu'en changeant de case. Meme lecon que « pas de
	# surbrillance du pixel sous la souris ».
	var cell: Vector2i = _cell_at(where)
	if cell == _hover:
		return
	_hover = cell
	var staged: Dictionary = {}
	var cells: Array[Vector2i] = _stamp_cells(cell)
	var wanted: int = _stamp_level(cells, true)
	_refused = not _inside(cell) or wanted > TOP_LEVEL \
			or PluginRules.stamp_refused(_heights, staged, cells, wanted)
	queue_redraw()


# --- CE QUE LE MOTEUR POSE --------------------------------------------------

## ⚠ ON REPOSE TOUT, ET CE N'EST PAS UN RACCOURCI. « Au ras » est une propriete du massif
## ENTIER : poser une case peut reunir deux massifs, ou faire deborder un massif de son
## porteur, et alors tout son contour change de regle d'un bout du monde a l'autre. Une zone
## bornee laisserait le monde faux pendant qu'on le dessine, et rien ne le signalerait. C'est
## la meme decision que dans le plugin, prise pour la meme raison.
func _refresh() -> void:
	# ⚠ UNE CARTE COUTEUSE NE SE RECALCULE PAS A CHAQUE TOUR DE BOUCLE. Ecrit
	# `for x in cher().keys(): ... cher()[x] ...`, l'en-tete ne s'evalue qu'une fois mais le
	# CORPS rappelle la fonction a chaque iteration -- faute deja payee sept fois au dossier.
	# On tient donc la carte une fois par coup, et `_draw` la relit sans la refaire.
	_layers = PluginRules.layers(_heights)
	_missing = 0
	for level: Variant in _layers.keys():
		for tile: Variant in (_layers[level] as Dictionary).values():
			if not _art.has(int(tile)):
				_missing += 1
	report_changed.emit(_art.size(), _missing)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), WorkArea.VOID)
	var levels: Array[int] = []
	for level: Variant in _layers.keys():
		levels.append(int(level))
	levels.sort()
	# ⚠ DU BAS VERS LE HAUT, chaque couche recouvrant la precedente : c'est l'ordre de pose du
	# moteur, et c'est lui qui fait tout le travail d'occlusion.
	for level2: int in levels:
		var layer: Dictionary = _layers[level2]
		for cell: Vector2i in layer.keys():
			var tile: int = int(layer[cell])
			if not _art.has(tile):
				continue
			draw_texture_rect(_art[tile] as Texture2D, _cell_box(cell), false)
	if _heights.is_empty():
		_draw_invite()
	_draw_bounds()
	_draw_hover()


## ⚠ L'AIRE SE MONTRE, SINON SON REFUS EST UNE SURPRISE. Le curseur devient rouge des qu'on
## sort, mais un refus qu'on ne peut pas anticiper se lit comme une panne -- et « le refus se
## voit avant le clic » ne veut rien dire si l'on ne sait pas OU est le bord. Le lisere est
## discret : il borne, il ne quadrille pas.
func _draw_bounds() -> void:
	var start: Rect2 = _cell_box(Vector2i(1, 1))
	var stop: Rect2 = _cell_box(Vector2i(SPAN.x - 2, SPAN.y - 2))
	draw_rect(Rect2(start.position, stop.end - start.position), Color(1, 1, 1, 0.10), false, 1.0)


## ⚠ UN ECRAN VIDE QUI NE DIT RIEN EST UN REFUS MUET. La room s'ouvre SANS relief -- on ne
## fabrique rien a la place de l'artiste, et une colline posee d'office serait exactement
## l'apercu qu'on a supprime le 05/09 : « il reposait tout seul les memes tuiles sur une
## colline fixe ». Elle dit donc ce qu'il y a a faire, et attend.
func _draw_invite() -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var text: String = "Click to lay relief: left raises one level, right lowers it."
	var line: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(font, ((size - line) * 0.5).floor(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(0.74, 0.77, 0.74))


func _draw_hover() -> void:
	if not _inside(_hover):
		return
	var half: int = STAMP / 2
	var box: Rect2 = Rect2(_cell_box(_hover - Vector2i(half, half)).position,
			Vector2(_cell_px * STAMP, _cell_px * STAMP))
	draw_rect(box, Color(1.0, 0.35, 0.3) if _refused else Color(1, 1, 1), false, 2.0)


# --- LE CADRAGE -------------------------------------------------------------

func _fit() -> void:
	var span: Vector2 = Vector2(SPAN) + Vector2(MARGIN, MARGIN) * 2.0
	_cell_px = maxf(4.0, minf(size.x / span.x, size.y / span.y))
	var used: Vector2 = Vector2(SPAN) * _cell_px
	_origin = ((size - used) * 0.5).floor()
	queue_redraw()


## ⚠ LA BOITE D'UNE CASE SE POSE SUR DES PIXELS ENTIERS, pas a la fraction : les deux bords se
## calculent par la meme formule puis s'arrondissent, si bien que la frontiere droite d'une
## case EST la frontiere gauche de sa voisine, par construction et a tout zoom.
func _cell_box(cell: Vector2i) -> Rect2:
	var left: float = round(_origin.x + float(cell.x) * _cell_px)
	var top: float = round(_origin.y + float(cell.y) * _cell_px)
	var right: float = round(_origin.x + float(cell.x + 1) * _cell_px)
	var bottom: float = round(_origin.y + float(cell.y + 1) * _cell_px)
	return Rect2(left, top, right - left, bottom - top)


func _cell_at(where: Vector2) -> Vector2i:
	return Vector2i(floori((where.x - _origin.x) / _cell_px),
			floori((where.y - _origin.y) / _cell_px))


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 1 and cell.y >= 1 and cell.x < SPAN.x - 1 and cell.y < SPAN.y - 1
