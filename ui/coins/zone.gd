extends Control

## LA ZONE DE TRAVAIL DU MODÈLE PAR LES COINS — la vue centrale de l'éditeur (Jordan, 4 novembre 2026 : garder
## l'interface du début, les deux volets, la barre du haut, la vue centrale, Draw et Test). Elle reprend les gestes de
## l'ancienne zone (`ui/work_area.gd`) — huit outils, une passe par clic, Ctrl+Z, tailles, « rester dans la tuile »,
## zoom à échelle ENTIÈRE, bouton du milieu pour se déplacer — sur le nouveau modèle :
##   DRAW   le guide (`guides/coins.txt`, et le champ d'une matière si on en peint une) ; le pinceau touche l'IMAGE qui
##          se voit sous lui, donc toujours DANS la forme de son archétype, et le pixel paraît dans toutes ses apparitions.
##   TEST   le relief à soi : les mêmes outils y peignent (la retouche est partout), et l'outil SCULPT y monte et descend
##          les coins (Maj : la matière du pinceau de matière).
## Aucune règle ici : le rendu et les formes viennent de `core/coins/`, la pose de `addons/marching_squares/modele.gd`.

const Rendu := preload("res://core/coins/rendu.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")
const Travail := preload("res://core/coins/travail.gd")
const Painting := preload("res://core/painting.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")

signal painting_changed
signal relief_changed
signal hover_changed(info: Dictionary)
signal pencil_picked(color: Color)
## Un geste refusé (une rencontre diagonale), et pourquoi : l'éditeur le dit.
signal refused(why: String)

enum Tool { PENCIL, BRUSH, AIRBRUSH, BUCKET, LINE, RECT, PICKER, ERASER, SCULPT }
const BRUSH_SIZES: Array[int] = [1, 2, 3, 4, 6, 8]
const SPRAY_DENSITY: float = 0.08
const NOWHERE := Vector2i(-1048576, -1048576)
const MIN_TILE_PX := 4.0
const MAX_TILE_PX := 1024.0
const TILE_LINE := Color(1, 1, 1, 0.14)
const PIXEL_LINE := Color(1, 1, 1, 0.05)
const JONCTION := Color(1.0, 0.25, 0.6, 0.9)
const HOVER_OK := Color(1, 1, 1, 0.85)
const HOVER_REFUSED := Color(0.925, 0.463, 0.396, 0.9)
const HALO := Color(1.0, 0.85, 0.3, 0.2)

var pencil: Color = Color(0.36, 0.55, 0.27)
var tool: Tool = Tool.PENCIL
var brush_size: int = 1
var lock_to_tile: bool = false
var reserved_left: float = 0.0
var reserved_right: float = 0.0
## Ce qu'on regarde : la grille et les points de jonction ; le guide sous les tuiles non peintes ; le travail.
var show_grid: bool = true
var assembled: bool = false
var hide_work: bool = false

var peinture: Painting
var meta := {"poids": {}, "affectation": {}}
var guide := {}
var guide_mat := PackedInt32Array()
var relief := {}
var mode_relief := false
## La matière dont le GUIDE porte le champ (Draw) ; la matière que pose Maj + clic (Test).
var matiere := 0
var matiere_pinceau := 1
var rendu: Rendu

var _au_guide := {}
var _texture: ImageTexture
var _halo_image: Image
var _halo_texture: ImageTexture
var _halo_cle := Vector2i(-1, -1)
var _points := PackedVector2Array()
var _tile_px := 32.0
var _origin := Vector2.ZERO
var _panning := false
var _stroke := 0
var _stroke_pose := -1
var _last_paint := Vector2.ZERO
var _anchor := Vector2i.ZERO
var _cursor := Vector2i.ZERO
var _hover_pixel := NOWHERE
var _hover_pose := -2
var _touched := {}
var _discs := {}
## Le coin dont le geste vient d'être refusé (rond rouge jusqu'au prochain mouvement), ou -1.
var _refus_coin := -1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK


# ── le travail ───────────────────────────────────────────────────────────────────────────────────────────────────────

## Prend un carnet, ses réglages (variantes, poids, relief) et le guide ; recompose tout.
func adopt(p: Painting, m: Dictionary, g: Dictionary, gm: PackedInt32Array) -> void:
	peinture = p
	meta = m
	if not meta.has("poids"):
		meta.poids = {}
	if not meta.has("affectation"):
		meta.affectation = {}
	guide = g
	guide_mat = gm
	if meta.has("relief") and (meta.relief as Dictionary).has("h"):
		relief = meta.relief
	elif relief.is_empty():
		relief = relief_de_depart()
	meta.relief = relief
	_au_guide.clear()
	for p_: Array in Modele.poses(guide.h, guide.colonnes, guide.rangees):
		var n := Archetypes.numero(p_[0], p_[4], p_[5])
		_au_guide[n] = int(_au_guide.get(n, 0)) + 1
	reconstruire()


func au_guide(n: int) -> int:
	return int(_au_guide.get(n, 0))


## Le relief montré : le guide (et le champ de la matière peinte), ou le relief sculpté.
func monde() -> Dictionary:
	if mode_relief:
		return relief
	var mat := PackedInt32Array()
	if matiere > 0 and guide_mat.size() == (guide.h as PackedInt32Array).size():
		mat = guide_mat.duplicate()
		for i in mat.size():
			mat[i] *= matiere
	return {"h": guide.h, "mat": mat, "colonnes": guide.colonnes, "rangees": guide.rangees}


func reconstruire() -> void:
	if peinture == null:
		return
	var m := monde()
	rendu = Rendu.new(peinture.resolution)
	rendu.montrer_guide = not assembled
	rendu.montrer_travail = not hide_work
	rendu.construire(m.h, m.colonnes, m.rangees, peinture, m.get("mat", PackedInt32Array()), _variante)
	_texture = ImageTexture.create_from_image(rendu.image)
	_halo_image = Image.create(rendu.image.get_width(), rendu.image.get_height(), false, Image.FORMAT_RGBA8)
	_halo_texture = ImageTexture.create_from_image(_halo_image)
	_halo_cle = Vector2i(-1, -1)
	_points = rendu.jonctions_ecran() if show_grid else PackedVector2Array()
	_hover_pose = -2
	queue_redraw()


## Recolore sans recomposer (le guide masqué, le travail masqué).
func recolorer() -> void:
	if rendu == null:
		return
	rendu.montrer_guide = not assembled
	rendu.montrer_travail = not hide_work
	for cle: Vector2i in rendu.images_vues():
		rendu.repeindre(cle, peinture)
	_texture.update(rendu.image)
	queue_redraw()


func set_grid(on: bool) -> void:
	show_grid = on
	_points = rendu.jonctions_ecran() if (on and rendu != null) else PackedVector2Array()
	_tile_px = _crisp(_tile_px, true)
	queue_redraw()


func set_mode_relief(on: bool) -> void:
	if mode_relief == on:
		return
	mode_relief = on
	reconstruire()
	fit()


func set_matiere(m: int) -> void:
	matiere = clampi(m, 0, Modele.MATIERES_MAXI - 1)
	if not mode_relief:
		reconstruire()


## La variante montrée par une pose : au guide, celle que l'artiste y a mise ; au relief, le TIRAGE du greffon.
func _variante(_ip: int, p: Array, n: int, m: int) -> int:
	var nb := Travail.nb_variantes(meta, n, m)
	if nb <= 1:
		return 0
	if mode_relief:
		return Modele.tirage(p[2], p[3], p[1], p[0], Travail.poids(meta, n, m))
	var a: Array = (meta.affectation as Dictionary).get(id_pose(p), [])
	if a.size() == 3 and a[0] == n and a[1] == m and a[2] < nb:
		return a[2]
	return 0


static func id_pose(p: Array) -> String:
	return "%d:%d:%d:%d:%d" % [p[0], p[1], p[2], p[3], p[5] if p[0] == Modele.MATIERE else 0]


# ── le dessin ────────────────────────────────────────────────────────────────────────────────────────────────────────

func _px() -> float:
	return _tile_px / float(peinture.resolution) if peinture != null else 1.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.09))
	if rendu == null:
		return
	var px := _px()
	var taille := Vector2(rendu.image.get_size()) * px
	draw_texture_rect(_texture, Rect2(_origin, taille), false)
	draw_texture_rect(_halo_texture, Rect2(_origin, taille), false)
	if show_grid:
		_draw_grid(px, taille)
	if _stroke != 0 and (tool == Tool.LINE or tool == Tool.RECT):
		for q: Vector2i in _shape_pixels():
			for o: Vector2i in _disc(brush_size):
				draw_rect(Rect2(_origin + Vector2(q + o) * px, Vector2(px, px)), Color(pencil, 0.6) if _stroke > 0 else Color(1, 1, 1, 0.35))
	if _refus_coin >= 0 and mode_relief:
		draw_arc(_ecran_du_coin(_refus_coin), maxf(8.0, _tile_px * 0.35), 0.0, TAU, 32, HOVER_REFUSED, 3.0)
	if _hover_pixel != NOWHERE and tool != Tool.SCULPT:
		var s := rendu.sous(_hover_pixel.x, _hover_pixel.y)
		var res := peinture.resolution
		var cellule := Vector2(floori(float(_hover_pixel.x) / res), floori(float(_hover_pixel.y) / res)) * res
		draw_rect(Rect2(_origin + cellule * px, Vector2(res, res) * px), HOVER_OK if not s.is_empty() else HOVER_REFUSED, false, 1.0)
		var d := maxi(1, brush_size if tool != Tool.PENCIL else 1)
		draw_rect(Rect2(_origin + Vector2(_hover_pixel - Vector2i(d / 2, d / 2)) * px, Vector2(d, d) * px),
				HOVER_OK if not s.is_empty() else HOVER_REFUSED, false, 1.0)


func _draw_grid(px: float, taille: Vector2) -> void:
	var res := peinture.resolution
	var x0 := maxf(_origin.x, 0.0)
	var x1 := minf(_origin.x + taille.x, size.x)
	var y0 := maxf(_origin.y, 0.0)
	var y1 := minf(_origin.y + taille.y, size.y)
	if px >= 6.0:
		var a := floori((x0 - _origin.x) / px)
		var b := ceili((x1 - _origin.x) / px)
		for i in range(a, b + 1):
			draw_line(Vector2(_origin.x + i * px, y0), Vector2(_origin.x + i * px, y1), PIXEL_LINE)
		a = floori((y0 - _origin.y) / px)
		b = ceili((y1 - _origin.y) / px)
		for j in range(a, b + 1):
			draw_line(Vector2(x0, _origin.y + j * px), Vector2(x1, _origin.y + j * px), PIXEL_LINE)
	var t := px * res
	for i in range(floori((x0 - _origin.x) / t), ceili((x1 - _origin.x) / t) + 1):
		draw_line(Vector2(_origin.x + i * t, y0), Vector2(_origin.x + i * t, y1), TILE_LINE)
	for j in range(floori((y0 - _origin.y) / t), ceili((y1 - _origin.y) / t) + 1):
		draw_line(Vector2(x0, _origin.y + j * t), Vector2(x1, _origin.y + j * t), TILE_LINE)
	var cote := maxf(px, 3.0)
	for p: Vector2 in _points:
		var c := _origin + (p + Vector2(0.5, 0.5)) * px
		if c.x >= -cote and c.y >= -cote and c.x <= size.x + cote and c.y <= size.y + cote:
			draw_rect(Rect2(c - Vector2(cote, cote) / 2.0, Vector2(cote, cote)), JONCTION)


## Éclaire toutes les apparitions de l'image `cle` ((-1, -1) : rien).
func _eclairer(cle: Vector2i) -> void:
	if cle == _halo_cle or _halo_image == null:
		return
	var w := rendu.largeur()
	if _halo_cle.x >= 0:
		for i: int in rendu.apparitions(_halo_cle):
			_halo_image.set_pixel(i % w, i / w, Color(0, 0, 0, 0))
	_halo_cle = cle
	if cle.x >= 0:
		for i: int in rendu.apparitions(cle):
			_halo_image.set_pixel(i % w, i / w, HALO)
	_halo_texture.update(_halo_image)


## Cadre tout le relief dans la place que laissent les deux volets.
func fit() -> void:
	if rendu == null:
		return
	var libre := Vector2(maxf(size.x - reserved_left - reserved_right - 32.0, 64.0), maxf(size.y - 32.0, 64.0))
	var tuiles := Vector2(rendu.image.get_size()) / float(peinture.resolution)
	_tile_px = _crisp(minf(libre.x / tuiles.x, libre.y / tuiles.y), false)
	var taille := tuiles * _tile_px
	_origin = Vector2(reserved_left + 16.0 + (libre.x - taille.x) / 2.0, 16.0 + (libre.y - taille.y) / 2.0)
	queue_redraw()


func _zoom_at(pivot: Vector2, factor: float) -> void:
	var avant := (pivot - _origin) / _tile_px
	_tile_px = _crisp(clampf(_tile_px * factor, MIN_TILE_PX, MAX_TILE_PX), factor > 1.0)
	_origin = pivot - avant * _tile_px
	queue_redraw()


## UN FAUX PIXEL FAIT UN NOMBRE ENTIER DE PIXELS D'ÉCRAN (la leçon payée de l'ancienne zone : sinon le dessin est
## baveux partout sauf au bord des tuiles). Sous un pixel par faux pixel, on rend la main.
func _crisp(wanted: float, growing: bool) -> float:
	if peinture == null:
		return wanted
	var side := float(peinture.resolution)
	var per := wanted / side
	if per >= 1.0:
		var steps := ceilf(per) if growing else floorf(per)
		return clampf(steps, 1.0, floorf(MAX_TILE_PX / side)) * side
	return wanted


# ── la souris et le clavier ──────────────────────────────────────────────────────────────────────────────────────────

func _pixel_at(position: Vector2) -> Vector2i:
	var local := (position - _origin) / _px()
	return Vector2i(floori(local.x), floori(local.y))


func _gui_input(event: InputEvent) -> void:
	if rendu == null:
		return
	if event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		match b.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if b.pressed:
					_zoom_at(b.position, 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				if b.pressed:
					_zoom_at(b.position, 1.0 / 1.12)
			MOUSE_BUTTON_MIDDLE:
				_panning = b.pressed
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				var sens := 1 if b.button_index == MOUSE_BUTTON_LEFT else -1
				if tool == Tool.SCULPT:
					if b.pressed and mode_relief:
						if b.shift_pressed:
							poser_matiere(_pixel_at(b.position), matiere_pinceau if sens > 0 else 0)
						else:
							sculpter(_pixel_at(b.position), sens)
				else:
					_begin_or_end(b.pressed, sens, b.position)
		accept_event()
		return
	if event is InputEventMouseMotion:
		var m := event as InputEventMouseMotion
		if _panning:
			_origin += m.relative
			queue_redraw()
			return
		_survoler(_pixel_at(m.position))
		if _stroke != 0:
			if tool == Tool.LINE or tool == Tool.RECT:
				_cursor = _pixel_at(m.position)
				queue_redraw()
			else:
				_apply_stroke(_last_paint, m.position)
			_last_paint = m.position


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or not key.ctrl_pressed or peinture == null:
		return
	var cases: Array[Vector2i] = []
	if key.keycode == KEY_Z and not key.shift_pressed:
		cases = peinture.undo()
	elif key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed):
		cases = peinture.redo()
	else:
		return
	get_viewport().set_input_as_handled()
	_rafraichir(cases)


func _survoler(pixel: Vector2i) -> void:
	var avant := _hover_pixel
	_hover_pixel = pixel
	if _refus_coin >= 0 and avant != pixel:
		_refus_coin = -1
	var s := rendu.sous(pixel.x, pixel.y)
	var ip: int = s[3] if not s.is_empty() else -1
	_eclairer(s[0] if not s.is_empty() and tool != Tool.SCULPT else Vector2i(-1, -1))
	if ip != _hover_pose or tool == Tool.SCULPT:
		_hover_pose = ip
		hover_changed.emit(info())
	if avant != pixel:
		queue_redraw()


## Ce qui est sous la souris, pour la barre et le panneau de la tuile.
func info() -> Dictionary:
	var d := {"mode_relief": mode_relief, "outil": tool, "vide": true}
	if rendu == null or _hover_pixel == NOWHERE:
		return d
	var s := rendu.sous(_hover_pixel.x, _hover_pixel.y)
	if s.is_empty():
		return d
	var cle: Vector2i = s[0]
	var n := cle.x
	var m := cle.y / 10
	d.vide = false
	d.cle = cle
	d.archetype = n
	d.matiere = m
	d.variante = cle.y % 10
	d.variantes = Travail.nb_variantes(meta, n, m)
	d.poids = Travail.poids(meta, n, m)
	d.sorte = Archetypes.liste()[n].sorte
	d.ici = rendu.poses_de(n)
	d.au_guide = au_guide(n)
	d.x = s[1]
	d.y = s[2]
	return d


# ── peindre (les gestes de l'ancienne zone, sur l'image qui se voit) ─────────────────────────────────────────────────

func _begin_or_end(pressed: bool, sens: int, position: Vector2) -> void:
	if peinture == null:
		return
	if pressed:
		if tool == Tool.PICKER:
			_pick(_pixel_at(position))
			return
		_stroke = sens
		_stroke_pose = -1
		peinture.begin_stroke()
		_last_paint = position
		_anchor = _pixel_at(position)
		_cursor = _anchor
		if tool == Tool.BUCKET:
			_pour(_anchor)
		elif tool == Tool.LINE or tool == Tool.RECT:
			queue_redraw()
		else:
			_apply_stroke(position, position)
		return
	if _stroke == 0:
		return
	if tool == Tool.LINE or tool == Tool.RECT:
		for q: Vector2i in _shape_pixels():
			_stamp_disc(q)
	_stroke = 0
	_stroke_pose = -1
	peinture.end_stroke()
	_finir()
	queue_redraw()


## Une passe programmée (la sonde, et rien d'autre) : du pixel `a` au pixel `b` d'écran du relief, avec l'outil courant.
func passe(a: Vector2i, b: Vector2i, sens := 1) -> void:
	_stroke = sens
	_stroke_pose = -1
	peinture.begin_stroke()
	if tool == Tool.BUCKET:
		_pour(a)
	elif tool == Tool.LINE or tool == Tool.RECT:
		_anchor = a
		_cursor = b
		for q: Vector2i in _shape_pixels():
			_stamp_disc(q)
	else:
		for q: Vector2i in _line_pixels(a, b):
			_touch(q)
	_stroke = 0
	peinture.end_stroke()
	_finir()


func _apply_stroke(from: Vector2, to: Vector2) -> void:
	for q: Vector2i in _line_pixels(_pixel_at(from), _pixel_at(to)):
		_touch(q)
	_finir()


func _touch(pixel: Vector2i) -> bool:
	match tool:
		Tool.PENCIL:
			return _plot(pixel)
		Tool.AIRBRUSH:
			return _spray(pixel)
		_:
			return _stamp_disc(pixel)


## Un pixel d'écran, posé dans l'image qui s'y voit. ⚠ « Rester dans la tuile » se juge ici, pixel par pixel : une brosse
## à cheval sur deux tuiles pose sa part dans celle où la passe a commencé.
func _plot(pixel: Vector2i) -> bool:
	var s := rendu.sous(pixel.x, pixel.y)
	if s.is_empty():
		return false
	if lock_to_tile:
		if _stroke_pose < 0:
			_stroke_pose = s[3]
		elif s[3] != _stroke_pose:
			return false
	var cle: Vector2i = s[0]
	var efface := _stroke < 0 or tool == Tool.ERASER
	var fait := peinture.erase(cle, s[1], s[2]) if efface else peinture.paint(cle, s[1], s[2], pencil)
	if fait:
		_touched[cle] = true
	return fait


func _stamp_disc(pixel: Vector2i) -> bool:
	var fait := false
	for o: Vector2i in _disc(brush_size if tool != Tool.PENCIL else 1):
		fait = _plot(pixel + o) or fait
	return fait


func _spray(pixel: Vector2i) -> bool:
	var disc := _disc(maxi(brush_size, 2))
	var gouttes := maxi(1, int(ceil(float(disc.size()) * SPRAY_DENSITY)))
	var fait := false
	for _i in gouttes:
		fait = _plot(pixel + disc[randi() % disc.size()]) or fait
	return fait


## LE POT, DANS LA FORME : la plage contiguë de même couleur, jamais au-delà de ce que l'archétype dessine.
func _pour(pixel: Vector2i) -> void:
	var s := rendu.sous(pixel.x, pixel.y)
	if s.is_empty():
		return
	var cle: Vector2i = s[0]
	var res := peinture.resolution
	var masque := Rendu.masque_de(cle.x, res)
	var couleur := pencil if _stroke > 0 else Painting.TRANSPARENT
	var depart := peinture.pixel_at(cle, s[1], s[2])
	if depart.is_equal_approx(couleur):
		return
	var vus := {}
	var file: Array[Vector2i] = [Vector2i(s[1], s[2])]
	while not file.is_empty():
		var q: Vector2i = file.pop_back()
		if vus.has(q) or q.x < 0 or q.y < 0 or q.x >= res or q.y >= res:
			continue
		vus[q] = true
		if masque[q.y * res + q.x] == 0 or not peinture.pixel_at(cle, q.x, q.y).is_equal_approx(depart):
			continue
		if peinture.paint(cle, q.x, q.y, couleur):
			_touched[cle] = true
		file.append_array([q + Vector2i.RIGHT, q + Vector2i.LEFT, q + Vector2i.UP, q + Vector2i.DOWN])


func _pick(pixel: Vector2i) -> void:
	var s := rendu.sous(pixel.x, pixel.y)
	if s.is_empty():
		return
	var c := peinture.pixel_at(s[0], s[1], s[2])
	if c.a <= 0.0:
		return
	pencil = c
	pencil_picked.emit(c)


## Ce qui a été touché par la passe se redessine (toutes ses apparitions, et les variantes vierges de sa base).
func _finir() -> void:
	if _touched.is_empty():
		return
	var cles: Array[Vector2i] = []
	for c: Vector2i in _touched:
		cles.append(c)
	_touched.clear()
	_rafraichir(cles)


func _rafraichir(cles: Array[Vector2i]) -> void:
	if cles.is_empty() or rendu == null:
		return
	var familles := {}
	for c: Vector2i in cles:
		familles[Vector2i(c.x, c.y / 10)] = true
	for f: Vector2i in familles:
		rendu.repeindre_famille(f.x, f.y, peinture)
	_texture.update(rendu.image)
	queue_redraw()
	painting_changed.emit()


func _shape_pixels() -> Array[Vector2i]:
	if tool == Tool.RECT:
		return _rect_pixels(_anchor, _cursor)
	return _line_pixels(_anchor, _cursor)


static func _line_pixels(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var delta := Vector2i(absi(to.x - from.x), -absi(to.y - from.y))
	var step := Vector2i(1 if from.x < to.x else -1, 1 if from.y < to.y else -1)
	var err := delta.x + delta.y
	var at := from
	while true:
		out.append(at)
		if at == to:
			break
		var twice := 2 * err
		if twice >= delta.y:
			err += delta.y
			at.x += step.x
		if twice <= delta.x:
			err += delta.x
			at.y += step.y
	return out


static func _rect_pixels(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var low := Vector2i(mini(from.x, to.x), mini(from.y, to.y))
	var high := Vector2i(maxi(from.x, to.x), maxi(from.y, to.y))
	for x in range(low.x, high.x + 1):
		out.append(Vector2i(x, low.y))
		if high.y != low.y:
			out.append(Vector2i(x, high.y))
	for y in range(low.y + 1, high.y):
		out.append(Vector2i(low.x, y))
		if high.x != low.x:
			out.append(Vector2i(high.x, y))
	return out


func _disc(diameter: int) -> Array[Vector2i]:
	if _discs.has(diameter):
		return _discs[diameter]
	var out: Array[Vector2i] = []
	var radius := float(diameter) * 0.5
	var start := -(diameter / 2)
	for j in diameter:
		for i in diameter:
			var dx := float(i) + 0.5 - radius
			var dy := float(j) + 0.5 - radius
			if dx * dx + dy * dy <= radius * radius + 0.01:
				out.append(Vector2i(start + i, start + j))
	_discs[diameter] = out
	return out


# ── sculpter (Test) ──────────────────────────────────────────────────────────────────────────────────────────────────

func _coin(pixel: Vector2i) -> int:
	var res := float(peinture.resolution)
	return Modele.coin_sous(relief.h, relief.colonnes, relief.rangees, Vector2(pixel.x / res, pixel.y / res - rendu.hmax))


## Monte (+1) ou descend (−1) le coin du relief qui se voit au pixel d'écran `pixel`. ⚠ REFUSÉ s'il ferait se
## rencontrer deux plateaux en diagonale (Jordan, 4 novembre 2026 : « refuser le clic »). Rend vrai si le relief change.
func sculpter(pixel: Vector2i, sens: int) -> bool:
	var i := _coin(pixel)
	if i < 0:
		return false
	var hh: PackedInt32Array = relief.h.duplicate()
	hh[i] = clampi(hh[i] + sens, 0, 12)
	if hh[i] == relief.h[i]:
		return false
	if Modele.cree_une_selle(hh, relief.mat, relief.colonnes, relief.rangees, i).x >= 0:
		_refuser(i, "Refused: two plateaus would meet only at a corner. Raise or lower a neighbouring corner first.")
		return false
	relief.h = hh
	_apres_relief()
	return true


## Pose la matière `m` (0 : l'ôter) sur le coin qui se voit au pixel d'écran `pixel` — refusé de même.
func poser_matiere(pixel: Vector2i, m: int) -> bool:
	var i := _coin(pixel)
	if i < 0:
		return false
	var mm: PackedInt32Array = relief.mat.duplicate()
	mm[i] = m
	if mm[i] == relief.mat[i]:
		return false
	if Modele.cree_une_selle(relief.h, mm, relief.colonnes, relief.rangees, i).x >= 0:
		_refuser(i, "Refused: two patches of material would meet only at a corner. Paint a neighbouring corner first.")
		return false
	relief.mat = mm
	_apres_relief()
	return true


func _refuser(i: int, why: String) -> void:
	_refus_coin = i
	queue_redraw()
	refused.emit(why)


## Le centre du coin `i` du relief, à l'écran.
func _ecran_du_coin(i: int) -> Vector2:
	var larg: int = relief.colonnes + 1
	var res := float(peinture.resolution)
	var cx := i % larg
	var cy := i / larg
	return _origin + Vector2(cx * res, (cy - int(relief.h[i]) + rendu.hmax) * res) * _px()


func _apres_relief() -> void:
	meta.relief = relief
	var origine := _origin
	var t := _tile_px
	var hmax_avant := rendu.hmax
	reconstruire()
	# Le relief qui grandit vers le haut décale l'image : on garde la vue immobile sous la souris.
	_origin = origine - Vector2(0, (rendu.hmax - hmax_avant) * t)
	queue_redraw()
	relief_changed.emit()


## Un relief de départ pour le mode test : un plateau à deux terrasses et une niche, sur une plaine, avec une tache de
## matière 1 qui passe de la plaine au plateau.
static func relief_de_depart() -> Dictionary:
	var colonnes := 24
	var rangees := 16
	var larg := colonnes + 1
	var h := PackedInt32Array()
	h.resize(larg * (rangees + 1))
	var mat := PackedInt32Array()
	mat.resize(h.size())
	for j in rangees + 1:
		for x in larg:
			if x >= 5 and x <= 18 and j >= 4 and j <= 11:
				h[j * larg + x] = 2
			if x >= 8 and x <= 14 and j >= 5 and j <= 8:
				h[j * larg + x] = 4
			if pow((x - 4) / 3.5, 2) + pow((j - 12) / 2.5, 2) <= 1.0:
				mat[j * larg + x] = 1
	h[11 * larg + 11] = 0
	return {"h": h, "mat": mat, "colonnes": colonnes, "rangees": rangees}


# ── les variantes (l'éditeur les appelle ; le survol dit où) ─────────────────────────────────────────────────────────

func _sous_survol() -> Array:
	if rendu == null or _hover_pixel == NOWHERE:
		return []
	return rendu.sous(_hover_pixel.x, _hover_pixel.y)


## Une NOUVELLE variante de l'image survolée, copiée d'elle ; cette apparition la montre aussitôt. Rend un message.
func nouvelle_variante() -> String:
	var s := _sous_survol() if not mode_relief else []
	if s.is_empty():
		return "Hover a tile in Draw to make a variant of it."
	var cle: Vector2i = s[0]
	var n := cle.x
	var m := cle.y / 10
	var nb := Travail.nb_variantes(meta, n, m)
	if nb >= Modele.VARIANTES_MAXI + 1:
		return "%d variants at most." % Modele.VARIANTES_MAXI
	if not peinture.is_painted(cle) and not peinture.is_painted(Vector2i(n, m * 10)):
		return "Paint this tile first: a variant starts as a copy of it."
	var source := cle if peinture.is_painted(cle) else Vector2i(n, m * 10)
	peinture.set_image(Vector2i(n, m * 10 + nb), peinture.image_of(source).duplicate())
	var p := Array(Travail.poids(meta, n, m))
	p.append(1)
	meta.poids["%d:%d" % [n, m]] = p
	meta.affectation[id_pose(rendu.poses[s[3]])] = [n, m, nb]
	reconstruire()
	painting_changed.emit()
	return "Variant %d of tile %d made from this copy, and shown here." % [nb, n]


func changer_variante() -> String:
	var s := _sous_survol() if not mode_relief else []
	if s.is_empty():
		return ""
	var cle: Vector2i = s[0]
	var nb := Travail.nb_variantes(meta, cle.x, cle.y / 10)
	if nb <= 1:
		return "This tile has no variant: V makes one."
	var k := (cle.y % 10 + 1) % nb
	meta.affectation[id_pose(rendu.poses[s[3]])] = [cle.x, cle.y / 10, k]
	reconstruire()
	return "Showing variant %d here." % k if k > 0 else "Showing the base here."


func oter_variante() -> String:
	var s := _sous_survol() if not mode_relief else []
	if s.is_empty():
		return ""
	var cle: Vector2i = s[0]
	var n := cle.x
	var m := cle.y / 10
	var k := cle.y % 10
	if k == 0:
		return "The base cannot be removed."
	var nb := Travail.nb_variantes(meta, n, m)
	for j in range(k, nb - 1):
		peinture.set_image(Vector2i(n, m * 10 + j), peinture.image_of(Vector2i(n, m * 10 + j + 1)).duplicate())
	peinture.clear_cell(Vector2i(n, m * 10 + nb - 1))
	var p := Array(Travail.poids(meta, n, m))
	p.remove_at(k)
	meta.poids["%d:%d" % [n, m]] = p
	for id: String in (meta.affectation as Dictionary).keys():
		var a: Array = meta.affectation[id]
		if a[0] == n and a[1] == m:
			if a[2] == k:
				meta.affectation.erase(id)
			elif a[2] > k:
				a[2] -= 1
	reconstruire()
	painting_changed.emit()
	return "Variant %d of tile %d removed." % [k, n]


func regler_poids(sens: int) -> String:
	var s := _sous_survol()
	if s.is_empty():
		return ""
	var cle: Vector2i = s[0]
	var p := Array(Travail.poids(meta, cle.x, cle.y / 10))
	if p.size() <= 1:
		return "This tile has no variant: its weight does not matter."
	p[cle.y % 10] = maxi(0, int(p[cle.y % 10]) + sens)
	meta.poids["%d:%d" % [cle.x, cle.y / 10]] = p
	if mode_relief:
		reconstruire()
	hover_changed.emit(info())
	return "Weight of variant %d: %d." % [cle.y % 10, p[cle.y % 10]]
