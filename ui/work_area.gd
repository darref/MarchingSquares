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
const Symmetry := preload("res://core/symmetry.gd")
const GuideImage := preload("res://render/guide_image.gd")
const RenderJob := preload("res://render/guide_render_job.gd")

## Emis des que la peinture change : l'editeur s'en sert pour rafraichir ses compteurs.
signal painting_changed

## Emis pendant le calcul du fond, avec des valeurs REELLES : le nombre de tuiles
## distinctes deja dessinees, sur le nombre a dessiner.
signal loading_progress(done: int, total: int)

## Emis quand la case survolee change. L'editeur en fait un releve lisible.
signal hover_changed(cell: Vector2i)

## Finesse du fond. Il est mis a l'echelle a l'affichage : plus fin coute cher pour rien,
## un guide se regarde, il ne se compte pas au pixel.
const GUIDE_TILE: int = 32

const MIN_TILE_PX: float = 5.0
const MAX_TILE_PX: float = 2000.0
const PIXEL_GRID_FROM: float = 5.0

## Combien de cases au plus remontent au GPU par image.
## ⚠ SANS PLAFOND, OUVRIR UN TRAVAIL GELE LA FENETRE. Un guide entierement peint compte
## sept cents cases ; a 256 pixels de cote, les televerser d'un coup ferait cent quatre-vingt
## mega-octets en une seule image. Etalees, elles apparaissent en quelques dixiemes de
## seconde et rien ne bloque.
const UPLOAD_PER_FRAME: int = 48

## Temps accorde au calcul du fond a chaque image. Une tuile coute environ vingt
## millisecondes : le budget en laisse passer une par image, et l'interface reste vivante.
const LOAD_BUDGET_USEC: int = 12000

## L'ETAGE 0, CONCRETISE. Le guide ne dessine pas la plaine -- elle ne lui appartient pas --
## mais elle EXISTERA dans le jeu : le sol sous les plateaux sera un etage plat du meme
## tileset, pose par le moteur sur sa propre couche. La zone de travail la montre donc, en
## aplat, DEBORDANT LARGEMENT DU GUIDE : le relief se lit alors comme un morceau de monde et
## non comme une decoupe posee sur du vide.
##
## ⚠ ELLE EST A L'EDITEUR, PAS AU GUIDE. Aucun pixel de cet aplat ne sort a l'export, et
## `guide_image` continue de laisser le vide. C'est un fond d'ecran, pas une tuile.
const GROUND: Color = Color(0.204, 0.235, 0.188)
# Le fond representatif est soutenu : on l'attenue pour que les pixels poses ressortent.
# Le fond utilisable est deja en teinte basse, il n'a pas besoin d'etre efface.
const GUIDE_TINT: Color = Color(1.0, 1.0, 1.0, 0.55)
const GUIDE_TINT_WIRE: Color = Color(1.0, 1.0, 1.0, 0.92)
const TILE_LINE: Color = Color(1.0, 1.0, 1.0, 0.16)
const PIXEL_LINE: Color = Color(1.0, 1.0, 1.0, 0.05)
const HOVER_OK: Color = Color(1.0, 1.0, 1.0, 0.85)
const HOVER_REFUSED: Color = Color(0.925, 0.463, 0.396, 0.90)

## ⚠ EN VUE D'ENSEMBLE, UN FAUX PIXEL MESURE MOINS D'UN PIXEL D'ECRAN. A la taille qui
## montre tout le guide, une case fait une trentaine de pixels et en porte soixante-quatre :
## ce qu'on pose est litteralement invisible, et l'on croit que rien ne se passe -- surtout
## quand le remplissage des jumelles touche cent cases d'un coup. En dessous de ce seuil, on
## cerne donc les cases qui portent de la peinture.
const TOUCHED_FROM: float = 1.6
const TOUCHED_MARK: Color = Color(0.949, 0.792, 0.475, 0.85)

var pencil: Color = Color(0.906, 0.855, 0.671)

## Peindre une case remplit aussi toutes ses symetriques, avec le dessin tourne ou
## retourne comme il faut. ⚠ CE N'EST PAS UNE CASE A COCHER : c'est le mode qui le decide,
## et seulement s'il livre des tuiles sans direction d'eclairage.
var paint_symmetry: bool = false

## Peindre une case peint aussi toutes celles qui portent la meme tuile.
## ⚠ CE N'EST PAS UN REGLAGE DU PRODUIT, c'est une aide au geste : elle ne change rien a ce
## qui sort, seulement au nombre de fois qu'il faut refaire le meme dessin.
var paint_twins: bool = false

## Ce qu'on regarde en peignant. ⚠ Rien de ce qui sort n'en depend : ce n'est pas
## l'eclairage du tileset, c'est le fond de l'ecran.
var guide_ink: GuideImage.Ink = GuideImage.Ink.PAINTED

## A quoi le fond sert : montrer le resultat, ou porter les marques de travail.
var guide_purpose: GuideImage.Purpose = GuideImage.Purpose.REPRESENTATIVE

## Les marques de travail : les marqueurs de coin rentrant, les tirets de rangee, et
## l'EPAISSISSEMENT des traits. ⚠ Les trois se masquent ensemble parce que les trois sont
## des marques : le trait grossi n'existe pas pour etre beau, il existe pour rendre la
## specification lisible d'un coup d'oeil.
var guide_marks: bool = true

## Largeurs occupees par les deux barres, qui sont posees SUR la zone de travail.
## ⚠ ELLES NE SERVENT QU AU CADRAGE. On ne bride pas le dessin a ces marges : le guide
## peut passer dessous, et c'est meme le but -- on le voit a travers elles.
var reserved_left: float = 0.0
var reserved_right: float = 0.0

## La grille se montre ou se cache. Une grille est une aide a viser, pas un decor : quand
## on juge une couleur, elle gene.
var show_grid: bool = true

## LE REMONTAGE : on efface tout ce qui n'est pas les tuiles peintes -- le fond du guide,
## les deux grilles, les cercles de repere -- et il ne reste que le paysage rebati.
##
## ⚠ C'EST LE SEUL CONTROLE QUE LE PROGRAMME NE PEUT PAS FAIRE. Il sait prouver que les
## 59 tuiles existent ; il ne sait pas juger qu'elles SE RACCORDENT. Un bord est peint d'un
## cote, son voisin de l'autre, a deux moments differents. Seul l'oeil voit la couture.
##
## ⚠ ET UNE CASE NON PEINTE RESTE UN TROU. On ne la remplit pas d'un aplat aimable : le
## trou est la verite, et c'est exactement ce qu'on veut voir.
var assembled: bool = false

## L'inverse de `assembled` : on efface ce qui est peint et on ne garde que le guide.
## ⚠ LES DEUX SE COCHENT EN MEME TEMPS SANS SE CONTREDIRE : il ne reste alors rien du tout,
## et c'est une reponse honnete plutot qu'un cas interdit.
var hide_work: bool = false

## ⚠ LA LUMIERE PORTEE EST UNE DECORATION, PAS UN PRODUIT. Les ombres tombent sur des cases
## de plaine, et la plaine n'est pas une tuile : aucune tuile exportee ne peut les porter.
## Les masquer montre donc ce que le tileset sait REELLEMENT produire.
var hide_cast_light: bool = false

var _heights: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null
var _surface_cells: Dictionary = {}
var _wall_cells: Dictionary = {}
var _paintable: Dictionary = {}
var _background: ImageTexture = null
var _background_flat: ImageTexture = null
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
var _by_index: Dictionary = {}
var _by_role: Dictionary = {}
var _targets: Dictionary = {}
var _needs_fit: bool = false
var _job: RefCounted = null
var _cache: Dictionary = {}
var _cache_key: String = ""


func _ready() -> void:
	resized.connect(_on_resized)


## ⚠ UNE TUILE NE REMONTE AU GPU QU UNE FOIS PAR IMAGE. Televerser la tuile entiere a
## chaque pixel pose ferait, a 256 de cote, un quart de mega-octet par pixel et par coup de
## souris. On marque la case sale, et on ne televerse qu ici.
func _process(_delta: float) -> void:
	if _job != null:
		if _job.step(LOAD_BUDGET_USEC):
			_background = ImageTexture.create_from_image(_job.image())
			_background_flat = ImageTexture.create_from_image(_job.flat_image())
			_cache[_cache_key] = [_background, _background_flat]
			loading_progress.emit(_job.total, _job.total)
			_job = null
		else:
			loading_progress.emit(_job.done, _job.total)
		queue_redraw()
	if not _stale.is_empty():
		# ⚠ ON NE TELEVERSE QUE CE QU ON VOIT. Peindre les jumelles peut salir cent cases d un
		# coup ; a 256 pixels de cote, les remonter toutes ferait vingt-cinq mega-octets par
		# image. Les autres attendent d entrer dans le cadre.
		var done: Array[Vector2i] = []
		for cell: Vector2i in _stale.keys():
			if done.size() >= UPLOAD_PER_FRAME:
				break
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
	# L'annuaire des cases qui portent quelque chose. La grille s'y appuie a chaque image :
	# la recalculer serait relire tout le relief soixante fois par seconde.
	_paintable.clear()
	for cell: Vector2i in _surface_cells.keys():
		_paintable[cell] = true
	for cell: Vector2i in _wall_cells.keys():
		_paintable[cell] = true
	# Les jumelles : deux cases du meme groupe portent la meme tuile. Le noyau les designe,
	# on ne fait ici que retenir, pour chaque case, la liste de ses semblables.
	_twin_of.clear()
	_targets.clear()
	_by_index = Coverage.cells_by_index(_surface_cells)
	_by_role = Walls.cells_by_role(_wall_roles)
	for group: Array in _by_index.values():
		var surface_twins: Array[Vector2i] = group
		for cell: Vector2i in surface_twins:
			_twin_of[cell] = surface_twins
	for group: Array in _by_role.values():
		var wall_twins: Array[Vector2i] = group
		for cell: Vector2i in wall_twins:
			_twin_of[cell] = wall_twins
	# ⚠ UN TRAVAIL RELU N'A JAMAIS ETE PEINT DEVANT NOUS. Ses cases doivent etre sales des
	# le depart : sans ca rien ne s'afficherait tant qu'on n'aurait pas repasse le crayon
	# par-dessus. L'art serait bien en memoire, les compteurs diraient 47/47, et l'ecran
	# resterait desesperement vide.
	if _painting != null:
		for cell: Vector2i in _painting.painted_cells():
			_stale[cell] = true

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
## ⚠ CHANGER LA REGLE DE REMPLISSAGE VIDE LE CACHE DES CIBLES. Sans ca, un coup de crayon
## continuerait a suivre l'ancienne regle sur toutes les cases deja touchees.
func set_fill_rules(twins: bool, symmetry: bool) -> void:
	paint_twins = twins
	paint_symmetry = symmetry
	_targets.clear()


func set_guide_style(ink: GuideImage.Ink, purpose: GuideImage.Purpose) -> void:
	if ink == guide_ink and purpose == guide_purpose:
		return
	guide_ink = ink
	guide_purpose = purpose
	_redraw_background()
	queue_redraw()


## Relance le calcul du fond. L'editeur s'en sert quand une aide a la vue change ce que le
## fond doit montrer.
func refresh_background() -> void:
	_redraw_background()
	queue_redraw()


## ⚠ LE FOND SE CALCULE PAR ETAPES, ET ON GARDE CE QU'ON A DEJA CALCULE. Le dessiner coute
## de deux a cinq secondes ; en un seul appel l'ecran gele. On lance un travail que
## _process() fait avancer, et on range le resultat : revenir a un style deja vu est
## instantane. La cle porte le contenu du relief, donc un guide modifie ne ressort jamais
## une vieille image.
func _redraw_background() -> void:
	if _heights.is_empty():
		return
	_cache_key = "%d:%d:%d:%d:%d" % ["
".join(_heights).hash(), GUIDE_TILE, int(guide_ink), int(guide_purpose),
			1 if guide_marks else 0]
	if _cache.has(_cache_key):
		var pair: Array = _cache[_cache_key]
		_background = pair[0]
		_background_flat = pair[1]
		_job = null
		loading_progress.emit(1, 1)
		return
	_background = null
	_background_flat = null
	_job = RenderJob.new(_heights, GUIDE_TILE, guide_ink, guide_purpose, guide_marks)
	loading_progress.emit(0, _job.total)


## Recadre le guide entier dans la fenetre.
func fit() -> void:
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	if columns <= 0 or rows <= 0 or size.x <= 0.0:
		return
	var usable: float = maxf(size.x - reserved_left - reserved_right, 1.0)
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
	draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	if columns <= 0:
		return
	var span: Vector2 = Vector2(float(columns), float(rows)) * _tile_px
	if _background != null and not assembled:
		var tint: Color = GUIDE_TINT_WIRE if guide_ink == GuideImage.Ink.WIREFRAME else GUIDE_TINT
		var sheet: ImageTexture = _background
		if hide_cast_light and _background_flat != null:
			sheet = _background_flat
		draw_texture_rect(sheet, Rect2(_origin, span), false, tint)

	var pixel_px: float = _tile_px / float(_painting.resolution) if _painting != null else 1.0
	for cell: Vector2i in (_textures.keys() if not hide_work else []):
		var texture: ImageTexture = _textures[cell]
		var rect: Rect2 = Rect2(_cell_origin(cell), Vector2(_tile_px, _tile_px))
		draw_texture_rect(texture, rect, false)
		# Trop dezoome pour qu'un faux pixel se voie : on cerne la case, sinon le travail
		# semble ne rien produire.
		if not assembled and pixel_px < TOUCHED_FROM and _painting.is_painted(cell):
			draw_rect(rect, TOUCHED_MARK, false, 1.0)

	if show_grid and not assembled:
		_draw_grid(pixel_px)

	if _hover.x >= 0:
		var accepted: bool = _is_paintable(_hover)
		draw_rect(Rect2(_cell_origin(_hover), Vector2(_tile_px, _tile_px)),
				HOVER_OK if accepted else HOVER_REFUSED, false, 2.0)


## LA GRILLE, DECOUPEE SUR CE QUI SE PEINT.
##
## ⚠ TRACEE SUR TOUT LE RECTANGLE, ELLE QUADRILLAIT SURTOUT CE QUI N'EST PAS LE TRAVAIL.
## La plaine occupe la plus grande part du cadre et ne se peint pas : la grille y dessinait
## une feuille de calcul, et le relief s'y noyait. Posee sur les seules cases peignables,
## elle dessine au contraire la SILHOUETTE de ce qu'il y a a faire -- on voit d'un coup
## d'oeil ou l'on a le droit de poser un pixel.
##
## ⚠ CHAQUE ARETE N'EST TRACEE QU'UNE FOIS. On pose toujours le haut et la gauche, et le
## bas ou la droite seulement au bord du peignable : une arete interieure appartient ainsi
## a la case du dessous ou de droite, jamais aux deux.
func _draw_grid(pixel_px: float) -> void:
	var fine: float = 0.0
	if _painting != null and pixel_px >= PIXEL_GRID_FROM:
		fine = pixel_px
	var frame: Rect2 = Rect2(Vector2.ZERO, size)
	for cell: Vector2i in _paintable.keys():
		var at: Vector2 = _cell_origin(cell)
		var box: Rect2 = Rect2(at, Vector2(_tile_px, _tile_px))
		# ⚠ ON NE TRACE QUE CE QUI EST A L'ECRAN. A fort zoom, la grille fine d'un guide
		# entier ferait des dizaines de milliers de traits dont la quasi-totalite hors cadre.
		if not frame.intersects(box):
			continue
		draw_line(at, at + Vector2(_tile_px, 0.0), TILE_LINE, 1.0)
		draw_line(at, at + Vector2(0.0, _tile_px), TILE_LINE, 1.0)
		if not _paintable.has(cell + Vector2i.DOWN):
			draw_line(at + Vector2(0.0, _tile_px), at + Vector2(_tile_px, _tile_px),
					TILE_LINE, 1.0)
		if not _paintable.has(cell + Vector2i.RIGHT):
			draw_line(at + Vector2(_tile_px, 0.0), at + Vector2(_tile_px, _tile_px),
					TILE_LINE, 1.0)
		if fine <= 0.0:
			continue
		for i: int in range(1, _painting.resolution):
			var offset: float = float(i) * fine
			draw_line(at + Vector2(offset, 0.0), at + Vector2(offset, _tile_px),
					PIXEL_LINE, 1.0)
			draw_line(at + Vector2(0.0, offset), at + Vector2(_tile_px, offset),
					PIXEL_LINE, 1.0)


func _cell_origin(cell: Vector2i) -> Vector2:
	return _origin + Vector2(float(cell.x), float(cell.y)) * _tile_px


func _is_paintable(cell: Vector2i) -> bool:
	return _paintable.has(cell)


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
			MOUSE_BUTTON_LEFT:
				# Bouton gauche : on pose. Bouton droit : on efface.
				_begin_or_end(button.pressed, 1, button.position)
			MOUSE_BUTTON_RIGHT:
				_begin_or_end(button.pressed, -1, button.position)
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
## Une passe s'ouvre au clic et se ferme au relachement : c'est l'unite qu'on defait.
func _begin_or_end(pressed: bool, direction: int, position: Vector2) -> void:
	if _painting == null:
		return
	if pressed:
		_stroke = direction
		_painting.begin_stroke()
		_last_paint = position
		_apply_stroke(position, position)
		return
	_stroke = 0
	_painting.end_stroke()


## ⚠ LES RACCOURCIS SONT PRIS ICI, PAS DANS _gui_input : celui-la exige que la zone ait le
## focus, et l'on vient souvent de cliquer une case a cocher.
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or not key.ctrl_pressed or _painting == null:
		return
	var cells: Array[Vector2i] = []
	if key.keycode == KEY_Z and not key.shift_pressed:
		cells = _painting.undo()
	elif key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed):
		cells = _painting.redo()
	else:
		return
	get_viewport().set_input_as_handled()
	for cell: Vector2i in cells:
		_stale[cell] = true
	if not cells.is_empty():
		_changed = true


func _set_hover(position: Vector2) -> bool:
	var cell: Vector2i = _cell_at(position)
	if cell == _hover:
		return false
	_hover = cell
	hover_changed.emit(cell)
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
	var changed: bool = false
	for target: Array in _targets_for(cell):
		var to: Vector2i = target[0]
		var moved: Vector2i = Symmetry.transform_pixel(px, py, _painting.resolution, int(target[1]))
		var touched: bool = _painting.paint(to, moved.x, moved.y, pencil) if _stroke > 0 				else _painting.erase(to, moved.x, moved.y)
		if touched:
			_stale[to] = true
			changed = true
	if changed:
		_changed = true
	return changed


## Les cases qu'un coup de crayon touche, chacune avec la transformation a appliquer a ses
## pixels. Calcule une fois par case, puis garde : un trait repasse cent fois au meme
## endroit, et rien n'y bouge entre deux passages.
func _targets_for(cell: Vector2i) -> Array:
	if _targets.has(cell):
		return _targets[cell]
	var list: Array = []
	if paint_symmetry and _surface_cells.has(cell):
		var source: int = int(_surface_cells[cell])
		for target_index: int in Symmetry.ORBIT_OF[source]:
			if not _by_index.has(target_index):
				continue
			var turns: int = Symmetry.turns_between(source, target_index)
			for twin: Vector2i in _by_index[target_index]:
				list.append([twin, turns])
	elif paint_symmetry and _wall_roles.has(cell):
		var role: Vector2i = _wall_roles[cell]
		var mirrored: Vector2i = Symmetry.mirror_role(role)
		for twin: Vector2i in _by_role.get(role, [] as Array[Vector2i]):
			list.append([twin, Symmetry.TURN_NONE])
		if mirrored != role:
			for twin: Vector2i in _by_role.get(mirrored, [] as Array[Vector2i]):
				list.append([twin, Symmetry.MIRROR])
	elif paint_twins and _twin_of.has(cell):
		for twin: Vector2i in _twin_of[cell]:
			list.append([twin, Symmetry.TURN_NONE])
	else:
		list.append([cell, Symmetry.TURN_NONE])
	_targets[cell] = list
	return list


func _upload_cell(cell: Vector2i) -> void:
	var image: Image = _painting.image_of(cell)
	if image == null:
		return
	if _textures.has(cell):
		var texture: ImageTexture = _textures[cell]
		texture.update(image)
	else:
		_textures[cell] = ImageTexture.create_from_image(image)
