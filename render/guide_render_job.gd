# LE RENDU DU FOND, PAR ETAPES — pour qu'on puisse le regarder avancer.
#
# ⚠ MESURE : dessiner le fond coute de 2 a 5 secondes. Ce n'est pas une estimation, c'est
# chronometre sur les deux guides livres. En un seul appel, l'ecran gele et rien ne bouge ;
# decoupe, l'interface reste vivante et la barre avance sur du VRAI.
#
# ⚠ ET LA VALEUR AFFICHEE EST REELLE. L'unite de progression est la tuile distincte
# dessinee -- il y en a environ 150 --, pas un compte a rebours ni une animation qui tourne
# en attendant. Quand la barre est a la moitie, la moitie des tuiles est dessinee.
#
# Le gros du temps est la fabrication des tuiles distinctes ; le tamponnage des mille cases
# qui les reutilisent ne coute presque rien.
extends RefCounted

const GuideImage := preload("res://render/guide_image.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Walls := preload("res://core/walls.gd")
const Satyron := preload("res://render/satyron_tiles.gd")

## Nombre de tuiles a dessiner, plus une etape pour le tamponnage.
var total: int = 1

## Combien sont faites.
var done: int = 0

var _heights: PackedStringArray
var _tile_size: int
var _ink: GuideImage.Ink
var _purpose: GuideImage.Purpose
var _image: Image
var _tops: Dictionary = {}
var _faces: Dictionary = {}
var _top_queue: Array[Vector2i] = []
var _wall_queue: Array[Vector2i] = []
var _placements: Array = []
var _wall_placements: Array = []
var _feet: Array[Vector2i] = []
var _contacts: Array[Vector2i] = []
var _finished: bool = false


func _init(heights: PackedStringArray, tile_size: int, ink: GuideImage.Ink,
		purpose: GuideImage.Purpose) -> void:
	_heights = heights
	_tile_size = tile_size
	_ink = ink
	_purpose = purpose
	_prepare()


## Prepare la liste du travail. Tout ce qui est rapide se fait ici : on ne veut compter
## que ce qui coute, sinon la barre mentirait sur ce qu'il reste.
func _prepare() -> void:
	if _purpose == GuideImage.Purpose.EXAMPLE:
		_prepare_example()
		return
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	_image = Image.create_empty(maxi(columns, 1) * _tile_size, maxi(rows, 1) * _tile_size,
			false, Image.FORMAT_RGBA8)
	_image.fill(GuideImage.plain_color(_ink))

	var wanted: Dictionary = {}
	for level: int in range(1, HeightMask.top_level(_heights) + 1):
		for y: int in range(rows):
			for x: int in range(columns):
				var index: int = Coverage.index_at_level(_heights, x, y, level)
				if index == Coverage.NO_INDEX:
					continue
				var key: Vector2i = Vector2i(index, level)
				if not wanted.has(key):
					wanted[key] = true
					_top_queue.append(key)
				_placements.append([key, x, y])

	var assembled: Dictionary = Walls.assemble(_heights)
	var roles: Dictionary = assembled["roles"]
	var wanted_roles: Dictionary = {}
	for level: int in range(1, HeightMask.top_level(_heights) + 1):
		for key: Vector3i in roles.keys():
			if key.z != level:
				continue
			var role: Vector2i = roles[key]
			if not wanted_roles.has(role):
				wanted_roles[role] = true
				_wall_queue.append(role)
			_wall_placements.append([role, key.x, key.y])
			if role.y == Walls.ROW_FOOT:
				_feet.append(Vector2i(key.x, key.y + 1))

	if _ink == GuideImage.Ink.PAINTED:
		for y: int in range(rows):
			for x: int in range(columns):
				if HeightMask.level_at(_heights, x - 1, y) > HeightMask.level_at(_heights, x, y):
					_contacts.append(Vector2i(x, y))

	total = _top_queue.size() + _wall_queue.size() + 1


## LE BANC D'ESSAI — le guide assemble avec les vraies tuiles de Satyron.
##
## ⚠ DEUX GRILLES DUALES. Satyron peint ses sols par les COINS : une de ses tuiles est a
## cheval sur quatre des notres, et se pose donc decalee d'une demi-case. Ce n'est pas une
## approximation, c'est la geometrie de son systeme. Les falaises, elles, se posent case
## pour case : leur vocabulaire est le meme que le notre, puisque nous le lui avons pris.
##
## ⚠ SON KIT DE FALAISE N'A QU'UNE RANGEE DE CORPS la ou nous en avons deux. Nos deux
## corps retombent donc sur la meme : on ne peut pas montrer une rangee qui n'existe pas.
func _prepare_example() -> void:
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	var side: int = Satyron.SOURCE_TILE
	_image = Image.create_empty(maxi(columns, 1) * side, maxi(rows, 1) * side,
			false, Image.FORMAT_RGBA8)
	_image.fill(Color(0.086, 0.094, 0.102))
	total = 1
	if not Satyron.is_available():
		return
	var kit: Dictionary = Satyron.read()
	var images: Dictionary = kit["images"]
	var corners: Dictionary = kit["corners"]
	var resolved: Dictionary = {}

	# Les sols, sur la grille duale.
	for j: int in range(rows + 1):
		for i: int in range(columns + 1):
			var signature: String = "%d,%d,%d,%d" % [
					_terrain_at(i - 1, j - 1), _terrain_at(i, j - 1),
					_terrain_at(i - 1, j), _terrain_at(i, j)]
			var tile: Array = Satyron.floor_tile(corners, signature, resolved)
			if tile.is_empty():
				continue
			_blit(images, int(tile[0]), tile[1], i * side - side / 2, j * side - side / 2, side)

	# Les falaises, case pour case.
	var cliff: Dictionary = kit["cliff"]
	var body_rows: int = maxi(1, int(cliff["body_rows"]))
	var origin: Vector2i = cliff["origin"]
	var source: int = int(cliff["source"])
	var visible: Dictionary = Walls.visible_roles(_heights)
	for cell: Vector2i in visible.keys():
		var role: Vector2i = visible[cell]
		var row: int = 0
		if role.y == Walls.ROW_FOOT:
			row = body_rows + 1
		elif role.y > 0:
			row = 1 + (role.y - 1) % body_rows
		_blit(images, source, origin + Vector2i(role.x, row), cell.x * side, cell.y * side, side)


## La matiere de Satyron qui tient lieu de notre etage a cet endroit.
func _terrain_at(x: int, y: int) -> int:
	var level: int = HeightMask.level_at(_heights, x, y)
	return Satyron.LEVEL_TERRAIN[mini(level, Satyron.LEVEL_TERRAIN.size() - 1)]


## Recopie une case d'atlas, en coupant ce qui sort du cadre.
func _blit(images: Dictionary, source: int, coord: Vector2i, x: int, y: int, side: int) -> void:
	if not images.has(source):
		return
	var atlas: Image = images[source]
	var from: Rect2i = Rect2i(coord * side, Vector2i(side, side))
	if from.position.x < 0 or from.position.y < 0 \
			or from.end.x > atlas.get_width() or from.end.y > atlas.get_height():
		return
	_image.blend_rect(atlas, from, Vector2i(x, y))


## Avance d'au plus [param budget_usec] microsecondes. Rend vrai quand tout est fini.
func step(budget_usec: int) -> bool:
	if _finished:
		return true
	var deadline: int = Time.get_ticks_usec() + budget_usec
	while not _top_queue.is_empty():
		var key: Vector2i = _top_queue.pop_front()
		_tops[key] = GuideImage.make_top(key.x, key.y, _tile_size, _ink, _purpose)
		done += 1
		if Time.get_ticks_usec() >= deadline:
			return false
	while not _wall_queue.is_empty():
		var role: Vector2i = _wall_queue.pop_front()
		_faces[role] = GuideImage.make_wall(role, _tile_size, _ink, _purpose)
		done += 1
		if Time.get_ticks_usec() >= deadline:
			return false
	_stamp_everything()
	done = total
	_finished = true
	return true


## Le tamponnage : mille cases qui reutilisent les memes cent cinquante tuiles. C'est
## rapide, et ca ne vaut pas la peine d'etre decoupe -- une seule etape de la barre.
func _stamp_everything() -> void:
	# Le banc d'essai a tout pose dans _prepare_example() : rien a tamponner ici.
	if _purpose == GuideImage.Purpose.EXAMPLE:
		return
	for placement: Array in _placements:
		GuideImage.stamp(_image, _tops[placement[0]], placement[1], placement[2], _tile_size)
	if _ink == GuideImage.Ink.PAINTED:
		var contact: Image = GuideImage.make_contact_shadow(_tile_size)
		for cell: Vector2i in _contacts:
			GuideImage.stamp(_image, contact, cell.x, cell.y, _tile_size)
	for placement: Array in _wall_placements:
		GuideImage.stamp(_image, _faces[placement[0]], placement[1], placement[2], _tile_size)
	if _ink != GuideImage.Ink.PAINTED:
		return
	var shadow: Image = GuideImage.make_ground_shadow(_tile_size)
	var occupied: Dictionary = {}
	for placement: Array in _wall_placements:
		occupied[Vector2i(placement[1], placement[2])] = true
	for cell: Vector2i in _feet:
		if not occupied.has(cell):
			GuideImage.stamp(_image, shadow, cell.x, cell.y, _tile_size)


func image() -> Image:
	return _image
