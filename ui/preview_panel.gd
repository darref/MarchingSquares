# L'APERCU EN JEU — vos tuiles dans un decor ordinaire.
#
# Le guide est un banc d'epreuve : lacs d'une case, pinacles isoles, encoches partout. Il ne
# ressemblera jamais a une carte de jeu, donc il ne dira jamais si le tileset REND bien. Ce
# panneau montre les memes tuiles posees sur un petit relief calme -- une colline en
# terrasses, ses falaises en escalier, une butte a deux etages, un rocher isole.
#
# ⚠ IL NE FABRIQUE AUCUNE TUILE. Chaque case emprunte, par index ou par role, ce qui est
# peint dans le guide. Rien de neuf n'est invente : c'est le meme dessin, vu ailleurs.
#
# ⚠ CE QUI N'EST PAS PEINT RESTE UN TROU, comme partout ailleurs. Le decor se remplit au fur
# et a mesure du travail, et ce qui manque se voit dans son contexte -- ce qu'aucune jauge
# ne peut montrer.
#
# ⚠ ET IL NE MONTRE PAS TOUT. Un decor calme n'appelle que seize des quarante-sept index :
# c'est la verite des tilesets, une carte ordinaire n'use qu'une poignee de tuiles. Le
# panneau dit comment ca rend, pas si tout est peint -- les jauges sont la pour ca.
extends Control

const HeightMask := preload("res://core/height_mask.gd")
const Assembly := preload("res://render/assembly.gd")

## Le decor. Un seul pour tous les modes : tous livrent les memes 59 tuiles.
const SCENE_PATH: String = "res://guides/preview.txt"

## ⚠ OPAQUE, SANS DISCUSSION. On ne juge pas une couleur a travers autre chose -- meme
## six pour cent de zone de travail derriere fausseraient ce que le panneau existe pour
## montrer. C'est la meme raison qui fait disparaitre la grille quand on juge un aplat.
const FRAME: Color = Color(0.086, 0.094, 0.102, 1.0)
const EDGE: Color = Color(1.0, 1.0, 1.0, 0.10)
const MARGIN: float = 10.0

var _scene: PackedStringArray = PackedStringArray()
var _guide: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null
## Case du decor -> PILE des cases du guide, du bas vers le haut. L'APERCU EMPILE comme le
## jeu : etages enterres, pied repose, tuile visible -- pour qu'un pixel transparent d'une
## tuile montre le sol couvert, jamais le fond du panneau. La regle vit dans Assembly.
var _layers_of: Dictionary = {}
var _textures: Dictionary = {}
var _dirty: bool = true


func _ready() -> void:
	# ⚠ FILTRAGE AU PLUS PROCHE. Un lissage bilineaire melangerait les bords de tuiles
	# voisines et fabriquerait des degrades la ou le dessin a des aretes nettes : le panneau
	# montrerait des defauts que la peinture n'a pas.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_scene = HeightMask.read(SCENE_PATH)
	set_process(true)


## Branche le panneau sur le guide en cours. C'est ici que s'etablit, une fois pour toutes,
## la correspondance case du decor -> case du guide.
func show_guide(guide: PackedStringArray, painting: RefCounted) -> void:
	if _scene.is_empty():
		_scene = HeightMask.read(SCENE_PATH)
	_guide = guide
	_painting = painting
	_layers_of = Assembly.borrow_layers(_scene, guide)
	_textures.clear()
	_dirty = true
	queue_redraw()


## Change de decor. La colline dit comment ca REND ; la planche de preuve montre que rien
## ne manque. Deux questions differentes, deux decors.
func set_scene(relief: PackedStringArray) -> void:
	_scene = relief
	if not _guide.is_empty():
		_layers_of = Assembly.borrow_layers(_scene, _guide)
	_textures.clear()
	_dirty = true
	queue_redraw()


func mark_dirty() -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if not _dirty or not visible or _painting == null:
		return
	_dirty = false
	# Le decor n'emprunte qu'une trentaine de tuiles distinctes : les remonter toutes coute
	# moins cher que de tenir la comptabilite de celles qui ont bouge.
	var wanted: Dictionary = {}
	for stack: Array in _layers_of.values():
		for cell: Vector2i in stack:
			wanted[cell] = true
	_textures.clear()
	for cell: Vector2i in wanted.keys():
		var image: Image = _painting.image_of(cell)
		if image != null:
			_textures[cell] = ImageTexture.create_from_image(image)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FRAME)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)

	var columns: int = HeightMask.width(_scene)
	var rows: int = HeightMask.height(_scene)
	if columns <= 0 or rows <= 0:
		return
	var usable: Vector2 = size - Vector2(MARGIN, MARGIN) * 2.0
	# ⚠ LE COTE DE CASE EST ARRONDI A L'ENTIER. Une echelle fractionnaire etalerait chaque
	# tuile sur un nombre non entier de pixels d'ecran, et le rendu montrerait des coutures
	# que le dessin n'a pas -- exactement le defaut que ce panneau existe pour reveler.
	var side: float = maxf(1.0, floorf(minf(usable.x / float(columns), usable.y / float(rows))))
	var span: Vector2 = Vector2(float(columns), float(rows)) * side
	var origin: Vector2 = ((size - span) * 0.5).floor()

	for cell: Vector2i in _layers_of.keys():
		var rect: Rect2 = Rect2(origin + Vector2(float(cell.x), float(cell.y)) * side,
				Vector2(side, side))
		for source: Vector2i in (_layers_of[cell] as Array):
			if _textures.has(source):
				draw_texture_rect(_textures[source], rect, false)
