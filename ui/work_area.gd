# LA ZONE DE TRAVAIL — la grille, le fond du guide, et les faux pixels qu'on y pose.
#
# Le fond n'est pas une image posee derriere : c'est le guide lui-meme, reconstitue depuis
# le relief par render/guide_image.gd, et cale sur la grille au pixel pres. Chaque case du
# guide porte `resolution` x `resolution` faux pixels, et ce sont eux qu'on peint.
#
# ⚠ LE PINCEAU REFUSE CE QUI N'EST PAS UNE TUILE (charte, regle 5). Seules les cases qui
# portent quelque chose -- une surface visible ou une case de robe -- se peignent. La
# plaine n'est pas une tuile du tileset : y poser un pixel ne produirait rien.
extends Control

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const GuideImage := preload("res://render/guide_image.gd")

## Emis des que la peinture change : l'editeur s'en sert pour rafraichir ses compteurs.
signal painting_changed

## Finesse du fond. Il est mis a l'echelle a l'affichage : plus fin coute cher pour rien,
## un guide se regarde, il ne se compte pas au pixel.
const GUIDE_TILE: int = 32

const MIN_TILE_PX: float = 5.0
const MAX_TILE_PX: float = 2000.0
const PIXEL_GRID_FROM: float = 5.0

const BACKDROP: Color = Color(0.106, 0.114, 0.125)
# Le fond representatif est soutenu : on l'attenue pour que les pixels poses ressortent.
# Le fond utilisable est deja en teinte basse, il n'a pas besoin d'etre efface.
const GUIDE_TINT: Color = Color(1.0, 1.0, 1.0, 0.55)
const GUIDE_TINT_USABLE: Color = Color(1.0, 1.0, 1.0, 0.92)
const TILE_LINE: Color = Color(1.0, 1.0, 1.0, 0.16)
const PIXEL_LINE: Color = Color(1.0, 1.0, 1.0, 0.05)
const HOVER_OK: Color = Color(1.0, 1.0, 1.0, 0.85)
const HOVER_REFUSED: Color = Color(0.925, 0.463, 0.396, 0.90)

var pencil: Color = Color(0.906, 0.855, 0.671)

## Peindre une case peint aussi toutes celles qui portent la meme tuile.
## ⚠ CE N'EST PAS UN REGLAGE DU PRODUIT, c'est une aide au geste : elle ne change rien a ce
## qui sort, seulement au nombre de fois qu'il faut refaire le meme dessin.
var paint_twins: bool = false

## Ce qu'on regarde en peignant. ⚠ Rien de ce qui sort n'en depend : ce n'est pas
## l'eclairage du tileset, c'est le fond de l'ecran.
var guide_style: GuideImage.Style = GuideImage.Style.REPRESENTATIVE

## Largeur occupee par la barre d'outils, qui est posee SUR la zone de travail.
## ⚠ ELLE NE SERT QU AU CADRAGE. On ne bride pas le dessin a cette marge : le guide peut
## passer sous la barre, et c'est meme le but -- on le voit a travers elle.
var reserved_left: float = 0.0

var _heights: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null
var _surface_cells: Dictionary = {}
var _wall_cells: Dictionary = {}
var _background: ImageTexture = null
var _textures: Dictionary = {}
var _tile_px: float = 32.0
var _origin: Vector2 = Vector2.ZERO
var _hover: Vector2i = Vector2i(-1, -1)
var _stroke: int = 0
var _last_paint: Vector2 = Vector2.ZERO
var _panning: bool = false
var _stale: Dictionary = {}
var _changed: bool = false
var _twin_of: Dictionary = {}
var _wall_roles: Dictionary = {}
var _needs_fit: bool = false


func _ready() -> void:
	resized.connect(_on_resized)


## ⚠ UNE TUILE NE REMONTE AU GPU QU UNE FOIS PAR IMAGE. Televerser la tuile entiere a
## chaque pixel pose ferait, a 256 de cote, un quart de mega-octet par pixel et par coup de
## souris. On marque la case sale, et on ne televerse qu ici.
func _process(_delta: float) -> void:
	if not _stale.is_empty():
		# ⚠ ON NE TELEVERSE QUE CE QU ON VOIT. Peindre les jumelles peut salir cent cases d un
		# coup ; a 256 pixels de cote, les remonter toutes ferait vingt-cinq mega-octets par
		# image. Les autres attendent d entrer dans le cadre.
		var done: Array[Vector2i] = []
		for cell: Vector2i in _stale.keys():
			if _on_screen(cell):
				_upload_cell(cell)
				done.append(cell)
		for cell: Vector2i in done:
			_stale.erase(cell)
		if not done.is_empty():
			queue_redraw()
	if _changed:
		_changed = false
		queue_redraw()
		painting_changed.emit()


func _on_screen(cell: Vector2i) -> bool:
	var rect: Rect2 = Rect2(_cell_origin(cell), Vector2(_tile_px, _tile_px))
	return rect.intersects(Rect2(Vector2.ZERO, size))


## Charge un guide et la peinture qui va avec. Tout est recalcule : les cases peignables,
## le fond, et le cadrage.
func show_guide(heights: PackedStringArray, painting: RefCounted) -> void:
	_heights = heights
	_painting = painting
	_textures.clear()
	_stale.clear()
	_surface_cells.clear()
	_wall_cells.clear()
	# La carte case -> index se calcule une fois : l'editeur en a besoin a chaque coup de
	# crayon, et la recalculer coutait un tiers du budget d'affichage.
	_surface_cells = Coverage.index_map(heights)
	# Les roles de robe sont rassembles une seule fois : ca coute un parcours complet du
	# relief, et l editeur en a besoin a chaque coup de crayon.
	_wall_roles = Walls.visible_roles(heights)
	for cell: Vector2i in _wall_roles.keys():
		_wall_cells[cell] = true
	# Les jumelles : deux cases du meme groupe portent la meme tuile. Le noyau les designe,
	# on ne fait ici que retenir, pour chaque case, la liste de ses semblables.
	_twin_of.clear()
	for group: Array in Coverage.cells_by_index(_surface_cells).values():
		var surface_twins: Array[Vector2i] = group
		for cell: Vector2i in surface_twins:
			_twin_of[cell] = surface_twins
	for group: Array in Walls.cells_by_role(_wall_roles).values():
		var wall_twins: Array[Vector2i] = group
		for cell: Vector2i in wall_twins:
			_twin_of[cell] = wall_twins
	_redraw_background()
	# ⚠ ON NE CADRE PAS TOUT DE SUITE. Au premier chargement, le conteneur n'a pas encore
	# donne sa taille : cadrer ici reviendrait a cadrer sur une fenetre qui n'existe plus.
	# On demande le cadrage, et c'est le premier redimensionnement qui l'execute.
	_needs_fit = true
	fit()


## La carte case -> index de surface, et plus bas les roles de robe. Toutes deux calculees
## une seule fois au chargement : l'editeur s'en sert sans jamais relire le relief.
func surface_index() -> Dictionary:
	return _surface_cells


func wall_roles() -> Dictionary:
	return _wall_roles


## Les cases de surface deja peintes, et plus bas les cases de robe. L'editeur en tire ses
## deux compteurs.
func painted_surface_cells() -> Array[Vector2i]:
	return _filter_painted(_surface_cells)


func painted_wall_cells() -> Array[Vector2i]:
	return _filter_painted(_wall_cells)


func _filter_painted(among: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if _painting == null:
		return cells
	for cell: Vector2i in _painting.painted_cells():
		if among.has(cell):
			cells.append(cell)
	return cells


## Change le style du fond. Le relief ne bouge pas : seule sa representation change.
func set_guide_style(style: GuideImage.Style) -> void:
	if style == guide_style:
		return
	guide_style = style
	_redraw_background()
	queue_redraw()


func _redraw_background() -> void:
	if _heights.is_empty():
		return
	_background = ImageTexture.create_from_image(GuideImage.render(_heights, GUIDE_TILE, guide_style))


## Recadre le guide entier dans la fenetre.
func fit() -> void:
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	if columns <= 0 or rows <= 0 or size.x <= 0.0:
		return
	var usable: float = maxf(size.x - reserved_left, 1.0)
	_tile_px = minf(usable / float(columns), size.y / float(rows)) * 0.94
	var span: Vector2 = Vector2(float(columns), float(rows)) * _tile_px
	_origin = Vector2(reserved_left + (usable - span.x) * 0.5, (size.y - span.y) * 0.5)
	_needs_fit = false
	queue_redraw()


func _on_resized() -> void:
	if _needs_fit:
		fit()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	if columns <= 0:
		return
	var span: Vector2 = Vector2(float(columns), float(rows)) * _tile_px
	if _background != null:
		var tint: Color = GUIDE_TINT_USABLE if guide_style == GuideImage.Style.USABLE else GUIDE_TINT
		draw_texture_rect(_background, Rect2(_origin, span), false, tint)

	for cell: Vector2i in _textures.keys():
		var texture: ImageTexture = _textures[cell]
		draw_texture_rect(texture, Rect2(_cell_origin(cell), Vector2(_tile_px, _tile_px)), false)

	# La grille des faux pixels n'apparait que lorsqu'elle est lisible : sinon elle noircit
	# l'ecran et cache le guide qu'elle est censee servir.
	if _painting != null and _tile_px / float(_painting.resolution) >= PIXEL_GRID_FROM:
		# ⚠ ON NE TRACE QUE CE QUI EST A L ECRAN. A 256 pixels par tuile, la grille complete
		# ferait seize mille traits dont la quasi-totalite hors cadre : de quoi mettre une
		# machine a genoux pour dessiner ce que personne ne voit.
		var step: float = _tile_px / float(_painting.resolution)
		var top: float = maxf(_origin.y, 0.0)
		var bottom: float = minf(_origin.y + span.y, size.y)
		var left: float = maxf(_origin.x, 0.0)
		var right: float = minf(_origin.x + span.x, size.x)
		var first: int = maxi(0, floori(-_origin.x / step))
		var last: int = mini(columns * _painting.resolution, ceili((size.x - _origin.x) / step))
		for i: int in range(first, last + 1):
			var x: float = _origin.x + float(i) * step
			draw_line(Vector2(x, top), Vector2(x, bottom), PIXEL_LINE, 1.0)
		first = maxi(0, floori(-_origin.y / step))
		last = mini(rows * _painting.resolution, ceili((size.y - _origin.y) / step))
		for i: int in range(first, last + 1):
			var y: float = _origin.y + float(i) * step
			draw_line(Vector2(left, y), Vector2(right, y), PIXEL_LINE, 1.0)

	for i: int in range(columns + 1):
		var gx: float = _origin.x + float(i) * _tile_px
		draw_line(Vector2(gx, _origin.y), Vector2(gx, _origin.y + span.y), TILE_LINE, 1.0)
	for i: int in range(rows + 1):
		var gy: float = _origin.y + float(i) * _tile_px
		draw_line(Vector2(_origin.x, gy), Vector2(_origin.x + span.x, gy), TILE_LINE, 1.0)

	if _hover.x >= 0:
		var accepted: bool = _is_paintable(_hover)
		draw_rect(Rect2(_cell_origin(_hover), Vector2(_tile_px, _tile_px)),
				HOVER_OK if accepted else HOVER_REFUSED, false, 2.0)


func _cell_origin(cell: Vector2i) -> Vector2:
	return _origin + Vector2(float(cell.x), float(cell.y)) * _tile_px


func _is_paintable(cell: Vector2i) -> bool:
	return _surface_cells.has(cell) or _wall_cells.has(cell)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					_zoom_at(button.position, 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					_zoom_at(button.position, 1.0 / 1.12)
			MOUSE_BUTTON_MIDDLE:
				_panning = button.pressed
			MOUSE_BUTTON_RIGHT:
				# Bouton droit : on pose. Bouton gauche : on efface.
				_stroke = 1 if button.pressed else 0
				if button.pressed:
					_last_paint = button.position
					_apply_stroke(button.position, button.position)
			MOUSE_BUTTON_LEFT:
				_stroke = -1 if button.pressed else 0
				if button.pressed:
					_last_paint = button.position
					_apply_stroke(button.position, button.position)
		accept_event()
		return
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _panning:
			_origin += motion.relative
			queue_redraw()
			return
		var moved: bool = _set_hover(motion.position)
		if _stroke != 0:
			_apply_stroke(_last_paint, motion.position)
			_last_paint = motion.position
		elif moved:
			queue_redraw()


## ⚠ LE SURVOL SE SUIT A LA CASE, PAS AU PIXEL. Suivre le pixel redessinait la zone de
## travail a chaque micro-mouvement de souris, pour un reperage dont on n a pas voulu.
func _set_hover(position: Vector2) -> bool:
	var cell: Vector2i = _cell_at(position)
	if cell == _hover:
		return false
	_hover = cell
	return true


func _cell_at(position: Vector2) -> Vector2i:
	var local: Vector2 = (position - _origin) / _tile_px
	return Vector2i(floori(local.x), floori(local.y))


func _zoom_at(pivot: Vector2, factor: float) -> void:
	var before: Vector2 = (pivot - _origin) / _tile_px
	_tile_px = clampf(_tile_px * factor, MIN_TILE_PX, MAX_TILE_PX)
	_origin = pivot - before * _tile_px
	queue_redraw()


## Trace du dernier point au point courant. Sans ce segment, un geste rapide laisserait des
## trous : la souris ne rend qu'une poignee de positions par seconde.
func _apply_stroke(from: Vector2, to: Vector2) -> void:
	if _painting == null:
		return
	var pixel_px: float = _tile_px / float(_painting.resolution)
	var steps: int = maxi(1, int(from.distance_to(to) / maxf(pixel_px, 0.5)) + 1)
	for i: int in range(steps + 1):
		var point: Vector2 = from.lerp(to, float(i) / float(steps))
		_touch(point)


func _touch(position: Vector2) -> bool:
	var local: Vector2 = (position - _origin) / _tile_px
	var cell: Vector2i = Vector2i(floori(local.x), floori(local.y))
	if not _is_paintable(cell):
		return false
	var inside: Vector2 = (local - Vector2(float(cell.x), float(cell.y))) * float(_painting.resolution)
	var px: int = clampi(floori(inside.x), 0, _painting.resolution - 1)
	var py: int = clampi(floori(inside.y), 0, _painting.resolution - 1)
	var targets: Array[Vector2i] = [cell]
	if paint_twins and _twin_of.has(cell):
		targets = _twin_of[cell]
	var changed: bool = false
	for target: Vector2i in targets:
		var touched: bool = _painting.paint(target, px, py, pencil) if _stroke > 0 else _painting.erase(target, px, py)
		if touched:
			_stale[target] = true
			changed = true
	if changed:
		_changed = true
	return changed


func _upload_cell(cell: Vector2i) -> void:
	var image: Image = _painting.image_of(cell)
	if image == null:
		return
	if _textures.has(cell):
		var texture: ImageTexture = _textures[cell]
		texture.update(image)
	else:
		_textures[cell] = ImageTexture.create_from_image(image)
