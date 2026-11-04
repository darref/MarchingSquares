extends RefCounted

## LE RENDU D'UN RELIEF — le guide (ou n'importe quel relief) tel que le modèle le pose, avec les images PEINTES là où
## elles le sont et les aplats du guide ailleurs. Il garde, pour chaque pixel de l'écran, la pose qui s'y voit et le
## pixel de l'image qui lui répond : c'est ce qui permet de PEINDRE sur l'écran (on touche ce qui se voit, donc toujours
## dans la forme d'un archétype) et de ne redessiner, quand une image change, QUE ses pixels — dans toutes ses
## apparitions à la fois (« une tuile, une image »).
## UNE IMAGE = (archétype n, matière m, variante k) ; dans le carnet (`core/painting.gd`), la case Vector2i(n, m * 10 + k).
## Une variante pas encore peinte montre sa base ; une base pas encore peinte, l'aplat du guide.
## Aucune règle ici : les poses et les formes viennent de `modele.gd`, les archétypes de `archetypes.gd`.

const Modele := preload("res://addons/marching_squares/modele.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")

const FOND := Color(0.08, 0.1, 0.16)

var resolution := 16
var colonnes := 0
var rangees := 0
var hmax := 0
var image: Image
## Les poses du relief, dans l'ordre (`Modele.poses`), et pour chacune son image : Vector2i(n, m * 10 + k).
var poses: Array = []
var image_de_pose: Array[Vector2i] = []
## pixel de l'écran → la pose qui s'y voit (-1 : rien) et le pixel local (y * résolution + x).
var pose_de := PackedInt32Array()
var local_de := PackedInt32Array()
## image → [pixel écran, pixel local, …] de tous les endroits où elle se voit.
var _pixels_de := {}
## archétype → combien de fois il est posé.
var _poses_de := {}
static var _masques := {}
static var _jonctions := {}


func _init(res: int = 16) -> void:
	resolution = res


## Pose tout le relief. `mat` : un rang de matière par coin (facultatif). `variante` : Callable(indice de pose, pose, n, m)
## → k, la variante montrée par cette pose (absent : la base partout).
func construire(h: PackedInt32Array, nb_colonnes: int, nb_rangees: int, peinture: RefCounted,
		mat := PackedInt32Array(), variante := Callable()) -> void:
	colonnes = nb_colonnes
	rangees = nb_rangees
	hmax = 0
	for v: int in h:
		hmax = maxi(hmax, v)
	var w := colonnes * resolution
	var hp := (rangees + hmax + 1) * resolution
	pose_de = PackedInt32Array()
	pose_de.resize(w * hp)
	pose_de.fill(-1)
	local_de = PackedInt32Array()
	local_de.resize(w * hp)
	_poses_de.clear()
	poses = Modele.poses(h, colonnes, rangees, mat)
	image_de_pose.clear()
	for ip in poses.size():
		var p: Array = poses[ip]
		var n := Archetypes.numero(p[0], p[4], p[5])
		var m: int = p[5] if p[0] == Modele.MATIERE else 0
		var k: int = variante.call(ip, p, n, m) if variante.is_valid() else 0
		image_de_pose.append(Vector2i(n, m * 10 + k))
		_poses_de[n] = int(_poses_de.get(n, 0)) + 1
		var masque := masque_de(n, resolution)
		var x0: int = int(p[2]) * resolution
		var y0: int = (int(p[3]) + hmax) * resolution
		for ly in resolution:
			for lx in resolution:
				if masque[ly * resolution + lx] == 0:
					continue
				var i := (y0 + ly) * w + x0 + lx
				pose_de[i] = ip
				local_de[i] = ly * resolution + lx
	_pixels_de.clear()
	for i in pose_de.size():
		var ip := pose_de[i]
		if ip < 0:
			continue
		var cle := image_de_pose[ip]
		if not _pixels_de.has(cle):
			_pixels_de[cle] = PackedInt32Array()
		_pixels_de[cle].append(i)
		_pixels_de[cle].append(local_de[i])
	image = Image.create(w, hp, false, Image.FORMAT_RGBA8)
	image.fill(FOND)
	for cle: Vector2i in _pixels_de:
		repeindre(cle, peinture)


func largeur() -> int:
	return colonnes * resolution


## Redessine toutes les apparitions de l'image `cle` = Vector2i(n, m * 10 + k).
func repeindre(cle: Vector2i, peinture: RefCounted) -> void:
	var liste: PackedInt32Array = _pixels_de.get(cle, PackedInt32Array())
	if liste.is_empty():
		return
	var n := cle.x
	var m := cle.y / 10
	var base := Vector2i(n, m * 10)
	var masque := masque_de(n, resolution)
	var w := largeur()
	for k in range(0, liste.size(), 2):
		var i := liste[k]
		var l := liste[k + 1]
		var lx := l % resolution
		var ly := l / resolution
		var c := Color(0, 0, 0, 0)
		if peinture != null:
			c = peinture.pixel_at(cle, lx, ly)
			if c.a <= 0.0 and cle != base:
				c = peinture.pixel_at(base, lx, ly)
		if c.a <= 0.0:
			c = couleur_guide(masque[l], int(poses[pose_de[i]][1]), m)
		image.set_pixel(i % w, i / w, c)


## Redessine toutes les images d'un archétype dans une matière (une base qui change se voit dans ses variantes vierges).
func repeindre_famille(n: int, m: int, peinture: RefCounted) -> void:
	for cle: Vector2i in _pixels_de:
		if cle.x == n and cle.y / 10 == m:
			repeindre(cle, peinture)


## Ce qui se voit au pixel d'écran (x, y) : [image Vector2i, x local, y local, indice de pose], ou [] (rien ici).
func sous(x: int, y: int) -> Array:
	var w := largeur()
	if x < 0 or y < 0 or x >= w or y >= image.get_height():
		return []
	var i := y * w + x
	var ip := pose_de[i]
	if ip < 0:
		return []
	return [image_de_pose[ip], local_de[i] % resolution, local_de[i] / resolution, ip]


## Combien de fois l'archétype `n` est posé dans ce relief (toutes matières et variantes comprises).
func poses_de(n: int) -> int:
	return int(_poses_de.get(n, 0))


## Les images qui se voient dans ce relief.
func images_vues() -> Array:
	return _pixels_de.keys()


## Les pixels d'écran où l'image `cle` se voit (pour l'éclairer au survol).
func apparitions(cle: Vector2i) -> PackedInt32Array:
	var liste: PackedInt32Array = _pixels_de.get(cle, PackedInt32Array())
	var sortie := PackedInt32Array()
	for k in range(0, liste.size(), 2):
		sortie.append(liste[k])
	return sortie


## Les POINTS DE JONCTION visibles, en pixels d'écran : là où une bande (dessus, lèvre, corps, pied) arrive au bord de
## sa tuile — l'endroit où le dessin doit se continuer dans la voisine.
func jonctions_ecran() -> PackedVector2Array:
	var sortie := PackedVector2Array()
	var w := largeur()
	for ip in poses.size():
		var p: Array = poses[ip]
		var x0: int = int(p[2]) * resolution
		var y0: int = (int(p[3]) + hmax) * resolution
		for q: Vector2i in jonctions_de(image_de_pose[ip].x, resolution):
			var i := (y0 + q.y) * w + x0 + q.x
			if i >= 0 and i < pose_de.size() and pose_de[i] == ip:
				sortie.append(Vector2(x0 + q.x, y0 + q.y))
	return sortie


## Le masque d'un archétype à une résolution : l'étiquette (sorte, rôle) de chaque pixel, 0 hors de sa forme.
static func masque_de(n: int, res: int) -> PackedInt32Array:
	var k := "%d@%d" % [n, res]
	if _masques.has(k):
		return _masques[k]
	var a: Dictionary = Archetypes.liste()[n]
	var m := PackedInt32Array()
	m.resize(res * res)
	for ly in res:
		for lx in res:
			m[ly * res + lx] = Modele.etiquette(a.sorte, 1, a.c, a.cv, (lx + 0.5) / res, (ly + 0.5) / res)
	_masques[k] = m
	return m


## Les points de jonction d'un archétype (pixels locaux de ses quatre bords) : chaque bout de bande qui touche le bord.
static func jonctions_de(n: int, res: int) -> Array[Vector2i]:
	var k := "%d@%d" % [n, res]
	if _jonctions.has(k):
		return _jonctions[k]
	var m := masque_de(n, res)
	var points := {}
	for b in 4:
		for t in range(1, res):
			var a: Vector2i = [Vector2i(t - 1, 0), Vector2i(t - 1, res - 1), Vector2i(0, t - 1), Vector2i(res - 1, t - 1)][b]
			var c: Vector2i = [Vector2i(t, 0), Vector2i(t, res - 1), Vector2i(0, t), Vector2i(res - 1, t)][b]
			var ea := m[a.y * res + a.x]
			var ec := m[c.y * res + c.x]
			if ea == ec:
				continue
			if ea != 0:
				points[a] = true
			if ec != 0:
				points[c] = true
	var sortie: Array[Vector2i] = []
	for p: Vector2i in points:
		sortie.append(p)
	_jonctions[k] = sortie
	return sortie


## La couleur du guide là où rien n'est peint : les aplats du tileset de TEST, éteints (on voit qu'il reste à peindre).
static func couleur_guide(e: int, L: int, m := 0) -> Color:
	var c := Color.MAGENTA
	match e & 3:
		Modele.DESSUS:
			c = Color(0.25, 0.45, 0.2).lerp(Color(0.75, 0.9, 0.45), clampf(L / 6.0, 0, 1))
			if m > 0:
				c = [Color(0.86, 0.74, 0.42), Color(0.9, 0.92, 0.97), Color(0.35, 0.5, 0.85), Color(0.7, 0.4, 0.7)][(m - 1) % 4]
		Modele.HAUT:
			c = Color(0.92, 0.8, 0.55) if (e >> 10) & 1 else Color(0.6, 0.48, 0.38)
		Modele.BAS:
			c = Color(0.3, 0.22, 0.17) if (e >> 10) & 1 else Color(0.55, 0.44, 0.35)
	return c.darkened(0.35)
