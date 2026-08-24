# LES VOISINES — le raccord se juge PENDANT le geste, pas apres l'export.
#
# Trente-six tuiles de robe dont beaucoup ne different que par une arete de deux ou trois
# pixels : c'est repetitif, et la repetition est exactement la ou une main diverge. Le test
# des raccords attrape la divergence, mais l'attraper veut dire du rouge et des retouches --
# le va-et-vient que cet outil existe pour supprimer.
#
# Ce panneau montre donc la case survolee entouree de ses voisines REELLES, celles du guide,
# a la meme echelle et COLLEES. Si un bord ne rejoint pas celui d'a cote, ca se voit avant
# de lever le crayon.
#
# ⚠ AUCUN ECART ENTRE LES CASES, JAMAIS. Un panneau qui espacerait ses tuiles pour faire
# joli ne montrerait plus rien du tout : c'est precisement la ligne de contact qu'on vient
# regarder. Le reperage de la case centrale se fait donc par des marques posees DEHORS.
#
# ⚠ ET L'ECHELLE EST UN ENTIER. Un demi-pixel d'ecran par faux pixel inventerait des
# coutures que le dessin n'a pas -- le meme piege que l'apercu en jeu.
extends Control

const Painting := preload("res://core/painting.gd")

## Combien de cases de part et d'autre de la case regardee.
const REACH: int = 1

const FRAME: Color = Color(0.086, 0.094, 0.102, 1.0)
const EDGE: Color = Color(1.0, 1.0, 1.0, 0.10)
## ⚠ UN TROU EST NOIR, PAS COULEUR DE SOL. Le peindre a la teinte de l'etage 0 le faisait
## passer pour du terrain -- or ce n'est pas du terrain, c'est ce qu'il reste a faire. Et on
## vient justement de decider que le sol ne nous appartient pas.
## ⚠ MAIS UNE TUILE PEINTE POSE SON SOCLE. Depuis que la transparence est un moyen
## d'expression, ses pixels transparents montrent le sol couvert, comme toutes les vues.
## Le noir ne dit donc plus qu'une seule chose : cette TUILE-LA n'est pas peinte.
const HOLE: Color = Color(0.055, 0.060, 0.066)
const TICK: Color = Color(0.949, 0.792, 0.475, 0.9)
const TICK_LENGTH: float = 5.0
const MARGIN: float = 6.0

var _painting: RefCounted = null
## Case -> liste des cases dont les tuiles se posent dessous (le socle enterre), fournie
## par la zone de travail -- la regle d'empilement ne vit pas ici.
var _grounds: Dictionary = {}
var _focus: Vector2i = Vector2i(-1, -1)
var _textures: Dictionary = {}
var _dirty: bool = true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)


func show_guide(painting: RefCounted, grounds: Dictionary = {}) -> void:
	_painting = painting
	_grounds = grounds
	_textures.clear()
	_dirty = true
	queue_redraw()


func look_at_cell(cell: Vector2i) -> void:
	if cell == _focus:
		return
	_focus = cell
	_dirty = true


func mark_dirty() -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if not _dirty or not visible or _painting == null:
		return
	_dirty = false
	_textures.clear()
	if _focus.x >= 0:
		for dy: int in range(-REACH, REACH + 1):
			for dx: int in range(-REACH, REACH + 1):
				var cell: Vector2i = _focus + Vector2i(dx, dy)
				var image: Image = _painting.image_of(cell)
				if image != null:
					_textures[cell] = ImageTexture.create_from_image(image)
				for source: Vector2i in (_grounds.get(cell, []) as Array):
					if _textures.has(source):
						continue
					var ground: Image = _painting.image_of(source)
					if ground != null:
						_textures[source] = ImageTexture.create_from_image(ground)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FRAME)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)
	if _painting == null or _focus.x < 0:
		return

	var span: int = REACH * 2 + 1
	var usable: Vector2 = size - Vector2(MARGIN, MARGIN) * 2.0
	var pixels: int = span * _painting.resolution
	var scale: float = maxf(1.0, floorf(minf(usable.x, usable.y) / float(pixels)))
	var side: float = float(_painting.resolution) * scale
	var block: float = side * float(span)
	var origin: Vector2 = ((size - Vector2(block, block)) * 0.5).floor()

	for dy: int in range(-REACH, REACH + 1):
		for dx: int in range(-REACH, REACH + 1):
			var at: Vector2 = origin + Vector2(float(dx + REACH), float(dy + REACH)) * side
			var box: Rect2 = Rect2(at, Vector2(side, side))
			var cell: Vector2i = _focus + Vector2i(dx, dy)
			if _textures.has(cell):
				# La tuile peinte pose son socle : ses pixels transparents montrent le
				# sol qu'elle couvre, comme dans toutes les autres vues.
				for source: Vector2i in (_grounds.get(cell, []) as Array):
					if _textures.has(source):
						draw_texture_rect(_textures[source], box, false)
				draw_texture_rect(_textures[cell], box, false)
			else:
				# ⚠ UNE VOISINE NON PEINTE EST UN TROU, pas un aplat aimable : c'est
				# justement ce qu'il reste a faire.
				draw_rect(box, HOLE)

	# Les reperes de la case centrale, poses DEHORS pour ne pas couvrir les raccords.
	var low: float = origin.x + side * float(REACH)
	var high: float = low + side
	var top: float = origin.y + side * float(REACH)
	var bottom: float = top + side
	for pair: Array in [[low, origin.y, 0.0, -1.0], [high, origin.y, 0.0, -1.0],
			[low, origin.y + block, 0.0, 1.0], [high, origin.y + block, 0.0, 1.0],
			[origin.x, top, -1.0, 0.0], [origin.x, bottom, -1.0, 0.0],
			[origin.x + block, top, 1.0, 0.0], [origin.x + block, bottom, 1.0, 0.0]]:
		var from: Vector2 = Vector2(float(pair[0]), float(pair[1]))
		var away: Vector2 = Vector2(float(pair[2]), float(pair[3])) * TICK_LENGTH
		draw_line(from, from + away, TICK, 1.0)
