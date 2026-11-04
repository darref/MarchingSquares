@tool
extends Node2D

## LE MONDE MARCHING SQUARES — un relief (une hauteur par COIN de la grille) et ses matières (un rang par coin), posés
## avec la planche peinte dans Marching Squares. Il ne fabrique aucune tuile : chaque pose va chercher, dans la planche,
## l'image que la table désigne, dans l'ordre de `modele.gd` — qui EST l'occlusion. La même règle que l'appli, le même
## fichier : ce que l'artiste a vu dans son atelier est ce que le jeu pose.
## Une rangée d'écran par unité de hauteur : un coin de hauteur L est dessiné L tuiles plus haut ; les rangées négatives
## (au-dessus de l'origine du nœud) sont normales.

const Modele := preload("res://addons/marching_squares/modele.gd")
const Planche := preload("res://addons/marching_squares/planche.gd")

## Le manifeste exporté par Marching Squares (« Export tileset ») : marching_squares_planche.json.
@export_file("*.json") var tileset: String = "":
	set(v):
		tileset = v
		recharger()
@export_range(2, 512) var columns: int = 24:
	set(v):
		columns = maxi(2, v)
		_ajuster()
@export_range(2, 512) var rows: int = 16:
	set(v):
		rows = maxi(2, v)
		_ajuster()
## Une hauteur par coin : (rows + 1) rangées de (columns + 1) coins.
@export var heights: PackedInt32Array = PackedInt32Array():
	set(v):
		heights = v
		_ajuster()
## Un rang de matière par coin (0 = la surface de base ; 1.. = les matières de la planche, chacune posée sur les autres).
@export var materials: PackedInt32Array = PackedInt32Array():
	set(v):
		materials = v
		_ajuster()
## La matière que pose le pinceau (Maj + clic dans l'éditeur).
@export_range(0, 3) var brush_material: int = 1

var planche: Planche
var _liste: Array = []
var _sale := true


func _ready() -> void:
	recharger()


func recharger() -> void:
	planche = Planche.new()
	if tileset != "" and not planche.lire(tileset):
		push_warning("Marching Squares: " + planche.erreur)
	_ajuster()


## La taille des tableaux suit la grille ; ce qui existe est gardé à sa place.
func _ajuster() -> void:
	var n := (columns + 1) * (rows + 1)
	if heights.size() != n:
		heights = _redimensionner(heights, n)
		return
	if materials.size() != n:
		materials = _redimensionner(materials, n)
		return
	_sale = true
	queue_redraw()


func _redimensionner(a: PackedInt32Array, n: int) -> PackedInt32Array:
	var b := a.duplicate()
	b.resize(n)
	return b


## Ce qui se dessine, dans l'ordre : [rectangle de destination, région de la planche]. `_draw` et `composer` le lisent.
func liste_de_dessin() -> Array:
	if not _sale:
		return _liste
	_liste = []
	_sale = false
	if planche == null or planche.texture == null:
		return _liste
	var t := float(planche.tuile)
	for p: Array in Modele.poses(heights, columns, rows, materials):
		var sorte: int = p[0]
		var n := int(planche.table.get(Modele.cle(sorte, p[4], p[5]), -1))
		var f := planche.famille(n, p[5] if sorte == Modele.MATIERE else 0)
		if n < 0 or f.is_empty():
			continue
		var k := Modele.tirage(p[2], p[3], p[1], sorte, f.poids)
		_liste.append([Rect2(Vector2(p[2], p[3]) * t, Vector2(t, t)), f.regions[k]])
	return _liste


func _draw() -> void:
	for d: Array in liste_de_dessin():
		draw_texture_rect_region(planche.texture, d[0], d[1])


## Le monde en une image (CPU) : pour un aperçu, un export, ou la sonde qui le compare à l'atelier. L'origine de l'image
## est la rangée −hmax (le sommet le plus haut).
func composer() -> Image:
	var t := planche.tuile
	var hmax := 0
	for v: int in heights:
		hmax = maxi(hmax, v)
	var img := Image.create(columns * t, (rows + hmax + 1) * t, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var source := planche.texture.get_image()
	source.convert(Image.FORMAT_RGBA8)
	for d: Array in liste_de_dessin():
		var r: Rect2 = d[1]
		var dest: Rect2 = d[0]
		img.blend_rect(source, Rect2i(r), Vector2i(dest.position) + Vector2i(0, hmax * t))
	return img


# ── le pinceau (l'éditeur le transmet, la sonde l'appelle) ─────────────────────────────────────────────────────────

## L'indice du coin qui se voit au point `local` (coordonnées du nœud), ou -1.
func coin_sous(local: Vector2) -> int:
	if planche == null:
		return -1
	return Modele.coin_sous(heights, columns, rows, local / float(planche.tuile))


## Monte (+1) ou descend (−1) le coin qui se voit en `local`. Rend [indice, avant, après] ou [].
func sculpter(local: Vector2, sens: int) -> Array:
	var i := coin_sous(local)
	if i < 0:
		return []
	var avant := heights[i]
	var h := heights.duplicate()
	h[i] = clampi(avant + sens, 0, 64)
	heights = h
	return [i, avant, h[i]]


## Pose la matière `m` sur le coin qui se voit en `local`. Rend [indice, avant, après] ou [].
func poser_matiere(local: Vector2, m: int) -> Array:
	var i := coin_sous(local)
	if i < 0:
		return []
	var avant := materials[i]
	var mm := materials.duplicate()
	mm[i] = m
	materials = mm
	return [i, avant, m]
