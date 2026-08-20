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

## Nombre de tuiles a dessiner, plus une etape pour le tamponnage.
var total: int = 1

## Combien sont faites.
var done: int = 0

var _heights: PackedStringArray
var _tile_size: int
var _style: GuideImage.Style
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


func _init(heights: PackedStringArray, tile_size: int, style: GuideImage.Style) -> void:
	_heights = heights
	_tile_size = tile_size
	_style = style
	_prepare()


## Prepare la liste du travail. Tout ce qui est rapide se fait ici : on ne veut compter
## que ce qui coute, sinon la barre mentirait sur ce qu'il reste.
func _prepare() -> void:
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	_image = Image.create_empty(maxi(columns, 1) * _tile_size, maxi(rows, 1) * _tile_size,
			false, Image.FORMAT_RGBA8)
	_image.fill(GuideImage.plain_color(_style))

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

	if _style == GuideImage.Style.REPRESENTATIVE:
		for y: int in range(rows):
			for x: int in range(columns):
				if HeightMask.level_at(_heights, x - 1, y) > HeightMask.level_at(_heights, x, y):
					_contacts.append(Vector2i(x, y))

	total = _top_queue.size() + _wall_queue.size() + 1


## Avance d'au plus [param budget_usec] microsecondes. Rend vrai quand tout est fini.
func step(budget_usec: int) -> bool:
	if _finished:
		return true
	var deadline: int = Time.get_ticks_usec() + budget_usec
	while not _top_queue.is_empty():
		var key: Vector2i = _top_queue.pop_front()
		_tops[key] = GuideImage.make_top(key.x, key.y, _tile_size, _style)
		done += 1
		if Time.get_ticks_usec() >= deadline:
			return false
	while not _wall_queue.is_empty():
		var role: Vector2i = _wall_queue.pop_front()
		_faces[role] = GuideImage.make_wall(role, _tile_size, _style)
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
	for placement: Array in _placements:
		GuideImage.stamp(_image, _tops[placement[0]], placement[1], placement[2], _tile_size)
	if _style == GuideImage.Style.REPRESENTATIVE:
		var contact: Image = GuideImage.make_contact_shadow(_tile_size)
		for cell: Vector2i in _contacts:
			GuideImage.stamp(_image, contact, cell.x, cell.y, _tile_size)
	for placement: Array in _wall_placements:
		GuideImage.stamp(_image, _faces[placement[0]], placement[1], placement[2], _tile_size)
	if _style != GuideImage.Style.REPRESENTATIVE:
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
