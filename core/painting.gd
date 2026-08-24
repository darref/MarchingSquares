# LES FAUX PIXELS — ce que l'utilisateur pose dans chaque tuile.
#
# Une tuile du guide se peint dans une grille de `resolution` x `resolution` pixels. Ce
# fichier ne connait ni souris, ni ecran, ni noeud : il stocke des pixels et repond a la
# seule question que le reste du noyau lui pose -- « cette case porte-t-elle au moins un
# pixel ? ». C'est exactement le seuil de la regle de livraison.
#
# ⚠ ON N'ALLOUE QUE LES CASES TOUCHEES. Un guide de 980 cases a 256 pixels de cote ferait
# un quart de gigaoctet s'il fallait tout reserver d'avance. Une case vierge ne coute rien
# tant que personne n'y a pose de pixel.
#
# ⚠ DEUX JUMELLES SONT LA MEME TUILE, DONC LA MEME IMAGE. `share()` declare qu'un groupe de
# cases porte une seule tuile : elles partagent des lors UNE image, rangee sous la premiere
# d'entre elles en ordre de lecture. Avant ca, peindre l'index 255 ecrivait le meme pixel
# dans 1553 images -- six millisecondes par point, et un journal d'annulation de 1553
# entrees par pixel. Une tuile, un dessin : c'est deja ce que la planche exportee dit.
extends RefCounted

## Les resolutions offertes. Le choix se fait une fois, avant de dessiner : c'est ce qu'on
## fabrique, pas un reglage (charte, regle 1).
const RESOLUTIONS: Array[int] = [16, 32, 64, 128, 256]

## ⚠ SEIZE PAR DEFAUT, ET C'EST UN ARGUMENT DE VENTE AVANT D'ETRE UN REGLAGE. A
## l'ouverture, l'acheteur doit voir d'un coup d'oeil qu'il y a PEU de faux pixels a peindre.
## Seize est aussi la taille du marche. Monter est un choix, et il se fait avant de dessiner.
const DEFAULT_RESOLUTION: int = 16

const TRANSPARENT: Color = Color(0.0, 0.0, 0.0, 0.0)

## Combien de passes on peut defaire.
const HISTORY_LIMIT: int = 60

var resolution: int = DEFAULT_RESOLUTION

var _images: Dictionary = {}
var _counts: Dictionary = {}

## case -> la case qui tient l'image pour tout son groupe. Une case absente se tient
## elle-meme.
var _holder_of: Dictionary = {}

## ⚠ UN COUP DE CRAYON PEUT TOUCHER DEUX CENTS CASES. Avec les jumelles, un trait de
## travers ruine une tuile dans tous ses exemplaires a la fois : sans retour en arriere,
## il faudrait les reprendre une par une. On journalise donc les pixels CHANGES, pas les
## images -- une passe de dix pixels sur deux cents jumelles pese quelques dizaines de
## kilo-octets, la ou copier les images en pesserait cinquante mega.
var _stroke: Array = []
var _past: Array = []
var _future: Array = []


func _init(pixel_resolution: int = DEFAULT_RESOLUTION) -> void:
	resolution = pixel_resolution if RESOLUTIONS.has(pixel_resolution) else DEFAULT_RESOLUTION


## Declare que ces cases portent LA MEME tuile : elles partagent desormais une image.
##
## ⚠ CE QUI ETAIT DEJA PEINT EST RASSEMBLE, PAS JETE. Un travail relu pose ses images par
## rang d'occurrence, avant qu'on ne sache quelles cases sont jumelles ; et un fichier
## d'avant le partage portait une image par jumelle. On garde la premiere trouvee en ordre
## de lecture -- elles sont identiques par construction -- et on la range sous la case qui
## tient le groupe. Rien ne se journalise : ce n'est pas un coup de crayon.
func share(cells: Array[Vector2i]) -> void:
	if cells.size() < 2:
		return
	var ordered: Array[Vector2i] = cells.duplicate()
	ordered.sort_custom(_reading_order)
	var holder: Vector2i = ordered[0]
	var kept: Image = null
	var kept_count: int = 0
	for cell: Vector2i in ordered:
		var own: Vector2i = _holder_of.get(cell, cell)
		if kept == null and _images.has(own) and int(_counts.get(own, 0)) > 0:
			kept = _images[own]
			kept_count = int(_counts[own])
		_images.erase(own)
		_counts.erase(own)
	for cell: Vector2i in ordered:
		_holder_of[cell] = holder
	if kept != null:
		_images[holder] = kept
		_counts[holder] = kept_count


## La case qui tient l'image de celle-ci : elle-meme, ou la premiere de ses jumelles.
func holder(cell: Vector2i) -> Vector2i:
	return _holder_of.get(cell, cell)


## Pose un pixel. Rend vrai si l'image de la case a change.
func paint(cell: Vector2i, x: int, y: int, color: Color) -> bool:
	if x < 0 or y < 0 or x >= resolution or y >= resolution:
		return false
	var own: Vector2i = _holder_of.get(cell, cell)
	var image: Image = _image_for(own)
	var before: Color = image.get_pixel(x, y)
	if before.is_equal_approx(color):
		return false
	image.set_pixel(x, y, color)
	_stroke.append([own, x, y, before, color])
	if before.a <= 0.0 and color.a > 0.0:
		_counts[own] = int(_counts.get(own, 0)) + 1
	elif before.a > 0.0 and color.a <= 0.0:
		_counts[own] = maxi(0, int(_counts.get(own, 0)) - 1)
	return true


## Efface un pixel.
func erase(cell: Vector2i, x: int, y: int) -> bool:
	if not _images.has(_holder_of.get(cell, cell)):
		return false
	return paint(cell, x, y, TRANSPARENT)


## La couleur d'un pixel. Transparent si la case est vierge ou le pixel hors de la tuile.
func pixel_at(cell: Vector2i, x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= resolution or y >= resolution:
		return TRANSPARENT
	var image: Image = _images.get(_holder_of.get(cell, cell), null)
	if image == null:
		return TRANSPARENT
	return image.get_pixel(x, y)


## LE POT DE PEINTURE : remplit la plage de pixels contigus (quatre voisins) de la meme
## couleur que celui de depart. Rend les pixels changes.
##
## ⚠ LA PLAGE S'ARRETE AU BORD DE LA TUILE, PAR CONSTRUCTION. Une tuile est une image a
## elle seule : le pot n'a aucun moyen de deborder sur la voisine, et c'est exactement ce
## qu'on attend de lui. Chaque pixel passe par `paint()`, donc la passe se defait d'un bloc.
func fill(cell: Vector2i, x: int, y: int, color: Color) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if x < 0 or y < 0 or x >= resolution or y >= resolution:
		return changed
	var own: Vector2i = _holder_of.get(cell, cell)
	var image: Image = _image_for(own)
	var target: Color = image.get_pixel(x, y)
	if target.is_equal_approx(color):
		return changed
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [Vector2i(x, y)]
	seen[Vector2i(x, y)] = true
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		if not image.get_pixel(at.x, at.y).is_equal_approx(target):
			continue
		if paint(own, at.x, at.y, color):
			changed.append(at)
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if next.x < 0 or next.y < 0 or next.x >= resolution or next.y >= resolution:
				continue
			if seen.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return changed


## Vrai si la case porte au moins un pixel. C'est le seuil de la regle de livraison :
## un pixel suffit a prendre la case, aucun pixel et elle ne sert pas.
func is_painted(cell: Vector2i) -> bool:
	return int(_counts.get(_holder_of.get(cell, cell), 0)) > 0


func pixel_count(cell: Vector2i) -> int:
	return int(_counts.get(_holder_of.get(cell, cell), 0))


## Les cases peintes, en ordre de lecture pour que le resultat ne depende pas de l'ordre
## des coups de souris.
##
## ⚠ UN GROUPE PARTAGE NE COMPTE QU'UNE FOIS : la case qui tient l'image. C'est ce que
## l'export et la sauvegarde attendent -- une tuile, un dessin, quel que soit son rang.
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
	return _images.get(_holder_of.get(cell, cell), null)


## Repose une image entiere dans une case. C'est par la qu'un travail relu revient.
##
## ⚠ CE N'EST PAS UN COUP DE CRAYON, ET CA NE SE DEFAIT PAS. Recharger un fichier n'est
## pas un geste de dessin : le journal serait faux d'y voir une passe, et « annuler » juste
## apres une ouverture devrait ramener a la passe d'AVANT la sauvegarde, pas vider l'ecran.
## Le compteur de pixels est donc refait ici, a la main, puisque `paint()` n'est pas passe.
func set_image(cell: Vector2i, image: Image) -> bool:
	if image == null or image.get_width() != resolution or image.get_height() != resolution:
		return false
	var copy: Image = image.duplicate()
	if copy.get_format() != Image.FORMAT_RGBA8:
		copy.convert(Image.FORMAT_RGBA8)
	var opaque: int = 0
	for y: int in range(resolution):
		for x: int in range(resolution):
			if copy.get_pixel(x, y).a > 0.0:
				opaque += 1
	var own: Vector2i = _holder_of.get(cell, cell)
	_images[own] = copy
	_counts[own] = opaque
	return true


func clear_cell(cell: Vector2i) -> void:
	var own: Vector2i = _holder_of.get(cell, cell)
	_images.erase(own)
	_counts.erase(own)


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


## Ouvre une passe. Tout ce qui suit se defera d'un seul geste.
func begin_stroke() -> void:
	_stroke = []


## Ferme la passe. Une passe vide ne s'enregistre pas : annuler ne doit jamais avoir
## l'air de ne rien faire.
func end_stroke() -> void:
	if _stroke.is_empty():
		return
	_past.append(_stroke)
	if _past.size() > HISTORY_LIMIT:
		_past.pop_front()
	_future.clear()
	_stroke = []


func can_undo() -> bool:
	return not _past.is_empty()


func can_redo() -> bool:
	return not _future.is_empty()


## Defait la derniere passe. Rend les cases touchees, pour que l'affichage les reprenne.
## ⚠ CE SONT LES CASES QUI TIENNENT LES IMAGES : une par groupe de jumelles.
func undo() -> Array[Vector2i]:
	if _past.is_empty():
		return [] as Array[Vector2i]
	var entries: Array = _past.pop_back()
	_future.append(entries)
	return _replay(entries, 3)


## Refait la passe defaite.
func redo() -> Array[Vector2i]:
	if _future.is_empty():
		return [] as Array[Vector2i]
	var entries: Array = _future.pop_back()
	_past.append(entries)
	return _replay(entries, 4)


## ⚠ ON REJOUE A L'ENVERS EN DEFAISANT. Deux pixels poses au meme endroit dans la meme
## passe ne se defont correctement que dans l'ordre inverse.
func _replay(entries: Array, which: int) -> Array[Vector2i]:
	var touched: Dictionary = {}
	var order: Array = entries.duplicate()
	if which == 3:
		order.reverse()
	for entry: Array in order:
		var cell: Vector2i = entry[0]
		_restore(cell, int(entry[1]), int(entry[2]), entry[which])
		touched[cell] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in touched.keys():
		cells.append(cell)
	return cells


## Repose un pixel SANS journaliser : defaire ne doit pas s'inscrire dans l'historique.
func _restore(cell: Vector2i, x: int, y: int, color: Color) -> void:
	var own: Vector2i = _holder_of.get(cell, cell)
	var image: Image = _image_for(own)
	var before: Color = image.get_pixel(x, y)
	image.set_pixel(x, y, color)
	if before.a <= 0.0 and color.a > 0.0:
		_counts[own] = int(_counts.get(own, 0)) + 1
	elif before.a > 0.0 and color.a <= 0.0:
		_counts[own] = maxi(0, int(_counts.get(own, 0)) - 1)
