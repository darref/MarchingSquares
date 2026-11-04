extends RefCounted

## L'ESSAI — un tileset de SPÉCIFICATION, calculé, pour poser un monde avant d'avoir peint (le même rôle que l'essai de
## l'ancien éditeur : l'export refuse une planche incomplète, et il a raison ; l'essai permet quand même d'essayer le
## greffon tout de suite). Ce n'est PAS de l'art et il ne fait pas semblant : de l'herbe, une lèvre claire, une roche,
## un pied sombre, un liseré au bord des dessus, et une matière (du sable, fondu vers l'herbe sur trois pixels).
## Le motif ne dépend que du pixel local : il se raccorde de lui-même partout.

const Archetypes := preload("res://core/coins/archetypes.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Travail := preload("res://core/coins/travail.gd")
const Painting := preload("res://core/painting.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")


## Un carnet peint du motif d'essai : les 35 bases et les quinze dessus de la matière 1.
static func peindre(res: int) -> Painting:
	var p := Painting.new(res)
	for a: Dictionary in Archetypes.liste():
		var m := Rendu.masque_de(a.numero, res)
		for y in res:
			for x in res:
				var e := m[y * res + x]
				if e == 0:
					continue
				var c := motif(e, x * 16 / res, y * 16 / res)
				if (e & 3) == Modele.DESSUS and distance_au_bord(m, res, x, y) < maxf(1.0, res / 16.0):
					c = Color(0.16, 0.3, 0.13)
				p.paint(Vector2i(a.numero, 0), x, y, c)
				if (e & 3) == Modele.DESSUS:
					var d := distance_au_bord(m, res, x, y) * 16.0 / res
					var sable := Color(0.86, 0.76, 0.5).lerp(Color(0.92, 0.83, 0.58), float((x * 31 + y * 17) % 7) / 7.0)
					p.paint(Vector2i(a.numero, 10), x, y,
							sable.lerp(Color(0.33, 0.58, 0.26), clampf((3.0 - d) / 3.5, 0.0, 0.8)) if d < 3.0 else sable)
	return p


## Écrit l'essai (planche + manifeste) dans `dossier`. Rend [planche, manifeste, non peintes].
static func ecrire(dossier: String, res: int) -> Array:
	return Travail.exporter(peindre(res), {"poids": {}, "affectation": {}}, dossier)


static func motif(e: int, x: int, y: int) -> Color:
	var bruit := float((x * 73 + y * 151 + x * y * 7) % 17) / 17.0
	match e & 3:
		Modele.DESSUS:
			return Color(0.33, 0.58, 0.26).lerp(Color(0.45, 0.7, 0.32), bruit * 0.6)
		Modele.HAUT:
			if (e >> 10) & 1:
				return Color(0.86, 0.76, 0.52).lerp(Color(0.95, 0.86, 0.62), bruit * 0.5)
			return Color(0.52, 0.42, 0.34).lerp(Color(0.6, 0.5, 0.4), bruit)
		Modele.BAS:
			if (e >> 10) & 1:
				return Color(0.28, 0.21, 0.17).lerp(Color(0.34, 0.26, 0.2), bruit)
			return Color(0.5, 0.4, 0.32).lerp(Color(0.58, 0.47, 0.37), bruit)
	return Color.MAGENTA


## La distance (en pixels) au plus proche pixel HORS de la forme, dans la tuile (le bord de la tuile n'en est pas un :
## la forme continue chez la voisine).
static func distance_au_bord(m: PackedInt32Array, res: int, x: int, y: int) -> float:
	var r := maxi(3, res * 3 / 16)
	var d := 99.0
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := Vector2i(x + dx, y + dy)
			if q.x >= 0 and q.y >= 0 and q.x < res and q.y < res and m[q.y * res + q.x] == 0:
				d = minf(d, Vector2(dx, dy).length())
	return d
