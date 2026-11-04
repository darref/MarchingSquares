extends RefCounted

## LE RENDU D'UN RELIEF — le guide (ou n'importe quel relief) tel que le modèle le pose, avec les archétypes PEINTS là
## où ils le sont et les aplats du guide ailleurs. Il garde, pour chaque pixel de l'écran, la pose qui s'y voit et le
## pixel de l'archétype qui lui répond : c'est ce qui permet de PEINDRE sur l'écran (on touche ce qui se voit, donc
## toujours dans la forme d'un archétype) et de ne redessiner, quand un archétype change, QUE ses pixels — dans toutes ses
## apparitions à la fois (« une tuile, une image »).
## Aucune règle ici : les poses et les formes viennent de `modele.gd`, les archétypes de `archetypes.gd`.

const Modele := preload("res://core/coins/modele.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")

const FOND := Color(0.08, 0.1, 0.16)

var resolution := 16
var colonnes := 0
var rangees := 0
var hauteurs := PackedInt32Array()
var hmax := 0
var image: Image
## pixel de l'écran → numéro d'archétype visible (-1 : rien) et le pixel local (y * résolution + x).
var archetype_de := PackedInt32Array()
var local_de := PackedInt32Array()
var couche_de := PackedInt32Array()
## archétype → [pixel écran, pixel local, …] de tous les endroits où il se voit.
var _pixels_de := {}
## archétype → combien de fois il est posé.
var _poses_de := {}
## archétype → [masque (étiquette par pixel local à L = 1)].
static var _masques := {}


func _init(res: int = 16) -> void:
	resolution = res


## Pose tout le relief. `peinture` : le carnet (`core/painting.gd`), une case par archétype — Vector2i(n, 0).
func construire(h: PackedInt32Array, nb_colonnes: int, nb_rangees: int, peinture: RefCounted) -> void:
	hauteurs = h
	colonnes = nb_colonnes
	rangees = nb_rangees
	hmax = 0
	for v: int in h:
		hmax = maxi(hmax, v)
	var w := colonnes * resolution
	var hp := (rangees + hmax + 1) * resolution
	archetype_de = PackedInt32Array()
	archetype_de.resize(w * hp)
	archetype_de.fill(-1)
	local_de = PackedInt32Array()
	local_de.resize(w * hp)
	couche_de = PackedInt32Array()
	couche_de.resize(w * hp)
	_poses_de.clear()
	for p: Array in Modele.poses(h, colonnes, rangees):
		var n := Archetypes.numero(p[0], p[4], p[5])
		_poses_de[n] = int(_poses_de.get(n, 0)) + 1
		var masque := masque_de(n, resolution)
		var x0: int = int(p[2]) * resolution
		var y0: int = (int(p[3]) + hmax) * resolution
		for ly in resolution:
			for lx in resolution:
				if masque[ly * resolution + lx] == 0:
					continue
				var i := (y0 + ly) * w + x0 + lx
				archetype_de[i] = n
				local_de[i] = ly * resolution + lx
				couche_de[i] = p[1]
	_pixels_de.clear()
	for i in archetype_de.size():
		var n := archetype_de[i]
		if n < 0:
			continue
		if not _pixels_de.has(n):
			_pixels_de[n] = PackedInt32Array()
		_pixels_de[n].append(i)
		_pixels_de[n].append(local_de[i])
	image = Image.create(w, hp, false, Image.FORMAT_RGBA8)
	image.fill(FOND)
	for n: int in _pixels_de:
		repeindre(n, peinture)


func largeur() -> int:
	return colonnes * resolution


## Redessine toutes les apparitions de l'archétype `n` (après un coup de crayon, une annulation, une relecture).
func repeindre(n: int, peinture: RefCounted) -> void:
	var liste: PackedInt32Array = _pixels_de.get(n, PackedInt32Array())
	var masque := masque_de(n, resolution)
	var w := largeur()
	for k in range(0, liste.size(), 2):
		var i := liste[k]
		var l := liste[k + 1]
		var c: Color = peinture.pixel_at(Vector2i(n, 0), l % resolution, l / resolution) if peinture != null else Color(0, 0, 0, 0)
		if c.a <= 0.0:
			c = couleur_guide(masque[l], couche_de[i])
		image.set_pixel(i % w, i / w, c)


## Ce qui se voit au pixel d'écran (x, y) : [archétype, x local, y local], ou [] (rien à peindre ici).
func sous(x: int, y: int) -> Array:
	var w := largeur()
	if x < 0 or y < 0 or x >= w or y >= image.get_height():
		return []
	var i := y * w + x
	var n := archetype_de[i]
	if n < 0:
		return []
	return [n, local_de[i] % resolution, local_de[i] / resolution]


## Combien de fois l'archétype `n` est posé dans ce relief.
func poses_de(n: int) -> int:
	return int(_poses_de.get(n, 0))


## Les pixels d'écran où l'archétype `n` se voit (pour l'éclairer au survol).
func apparitions(n: int) -> PackedInt32Array:
	var liste: PackedInt32Array = _pixels_de.get(n, PackedInt32Array())
	var sortie := PackedInt32Array()
	for k in range(0, liste.size(), 2):
		sortie.append(liste[k])
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


## La couleur du guide là où rien n'est peint : les aplats du tileset de TEST, éteints (on voit qu'il reste à peindre).
static func couleur_guide(e: int, L: int) -> Color:
	var c := Color.MAGENTA
	match e & 3:
		Modele.DESSUS:
			c = Color(0.25, 0.45, 0.2).lerp(Color(0.75, 0.9, 0.45), clampf(L / 6.0, 0, 1))
		Modele.HAUT:
			c = Color(0.92, 0.8, 0.55) if (e >> 10) & 1 else Color(0.6, 0.48, 0.38)
		Modele.BAS:
			c = Color(0.3, 0.22, 0.17) if (e >> 10) & 1 else Color(0.55, 0.44, 0.35)
	return c.darkened(0.35)
