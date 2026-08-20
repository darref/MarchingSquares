# LES FAUX PIXELS — ce que l'utilisateur pose dans chaque tuile.
#
# Une tuile du guide se peint dans une grille de `resolution` x `resolution` pixels. Ce
# fichier ne connait ni souris, ni ecran, ni noeud : il stocke des pixels et repond a la
# seule question que le reste du noyau lui pose -- « cette case porte-t-elle au moins un
# pixel ? ». C'est exactement le seuil de la regle des variantes.
#
# ⚠ ON N'ALLOUE QUE LES CASES TOUCHEES. Un guide de 980 cases a 256 pixels de cote ferait
# un quart de gigaoctet s'il fallait tout reserver d'avance. Une case vierge ne coute rien
# tant que personne n'y a pose de pixel.
extends RefCounted

## Les resolutions offertes. Le choix se fait une fois, avant de dessiner : c'est ce qu'on
## fabrique, pas un reglage (charte, regle 1).
const RESOLUTIONS: Array[int] = [16, 32, 64, 128, 256]
const DEFAULT_RESOLUTION: int = 64

const TRANSPARENT: Color = Color(0.0, 0.0, 0.0, 0.0)

var resolution: int = DEFAULT_RESOLUTION

var _images: Dictionary = {}
var _counts: Dictionary = {}


func _init(pixel_resolution: int = DEFAULT_RESOLUTION) -> void:
	resolution = pixel_resolution if RESOLUTIONS.has(pixel_resolution) else DEFAULT_RESOLUTION


## Pose un pixel. Rend vrai si l'image de la case a change.
func paint(cell: Vector2i, x: int, y: int, color: Color) -> bool:
	if x < 0 or y < 0 or x >= resolution or y >= resolution:
		return false
	var image: Image = _image_for(cell)
	var before: Color = image.get_pixel(x, y)
	if before.is_equal_approx(color):
		return false
	image.set_pixel(x, y, color)
	if before.a <= 0.0 and color.a > 0.0:
		_counts[cell] = int(_counts.get(cell, 0)) + 1
	elif before.a > 0.0 and color.a <= 0.0:
		_counts[cell] = maxi(0, int(_counts.get(cell, 0)) - 1)
	return true


## Efface un pixel.
func erase(cell: Vector2i, x: int, y: int) -> bool:
	if not _images.has(cell):
		return false
	return paint(cell, x, y, TRANSPARENT)


## Vrai si la case porte au moins un pixel. C'est le seuil de la regle des variantes :
## un pixel suffit a prendre la case, aucun pixel et elle ne sert pas.
func is_painted(cell: Vector2i) -> bool:
	return int(_counts.get(cell, 0)) > 0


func pixel_count(cell: Vector2i) -> int:
	return int(_counts.get(cell, 0))


## Les cases peintes, en ordre de lecture pour que le resultat ne depende pas de l'ordre
## des coups de souris.
func painted_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _counts.keys():
		if int(_counts[cell]) > 0:
			cells.append(cell)
	cells.sort_custom(_reading_order)
	return cells


## L'image d'une case, ou null si personne n'y a touche. Ne pas la modifier a la main :
## le compteur de pixels ne le verrait pas.
func image_of(cell: Vector2i) -> Image:
	return _images.get(cell, null)


func clear_cell(cell: Vector2i) -> void:
	_images.erase(cell)
	_counts.erase(cell)


func _image_for(cell: Vector2i) -> Image:
	if _images.has(cell):
		return _images[cell]
	var image: Image = Image.create_empty(resolution, resolution, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	_images[cell] = image
	_counts[cell] = 0
	return image


static func _reading_order(left: Vector2i, right: Vector2i) -> bool:
	if left.y != right.y:
		return left.y < right.y
	return left.x < right.x
