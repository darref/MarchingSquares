extends Control

## LA TUILE SURVOLÉE, EN GRAND — à la place des « voisines » de l'ancien modèle. On y voit l'image qu'on peint (ou
## l'aplat du guide là où rien n'est peint), ce qui n'est PAS à peindre (hachuré : hors de la forme de l'archétype),
## et ses points de jonction (là où le dessin doit se continuer chez la voisine).

const Rendu := preload("res://core/coins/rendu.gd")

const HACHURE := Color(1, 1, 1, 0.07)
const JONCTION := Color(1.0, 0.25, 0.6, 0.95)

var _info := {}
var _peinture: RefCounted = null


func _ready() -> void:
	custom_minimum_size = Vector2(0, 200)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func montrer(info: Dictionary, peinture: RefCounted) -> void:
	_info = info
	_peinture = peinture
	queue_redraw()


## Le carnet a changé : la tuile montrée se redessine.
func mark_dirty() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.1))
	if _info.is_empty() or bool(_info.get("vide", true)) or _peinture == null:
		return
	var res: int = _peinture.resolution
	var cote := floorf(minf(size.x, size.y) / res)
	if cote < 1.0:
		return
	var depart := ((size - Vector2(res, res) * cote) / 2.0).floor()
	var cle: Vector2i = _info.cle
	var base := Vector2i(cle.x, (cle.y / 10) * 10)
	var masque := Rendu.masque_de(cle.x, res)
	for y in res:
		for x in res:
			var r := Rect2(depart + Vector2(x, y) * cote, Vector2(cote, cote))
			var e := masque[y * res + x]
			if e == 0:
				if (x + y) % 2 == 0:
					draw_rect(r, HACHURE)
				continue
			var c: Color = _peinture.pixel_at(cle, x, y)
			if c.a <= 0.0 and cle != base:
				c = _peinture.pixel_at(base, x, y)
			if c.a <= 0.0:
				c = Rendu.couleur_guide(e, 1, cle.y / 10)
			draw_rect(r, c)
	draw_rect(Rect2(depart, Vector2(res, res) * cote), Color(1, 1, 1, 0.25), false, 1.0)
	for q: Vector2i in Rendu.jonctions_de(cle.x, res):
		var c2 := depart + (Vector2(q) + Vector2(0.5, 0.5)) * cote
		draw_rect(Rect2(c2 - Vector2(3, 3), Vector2(6, 6)), JONCTION)
	if _info.has("x"):
		draw_rect(Rect2(depart + Vector2(int(_info.x), int(_info.y)) * cote, Vector2(cote, cote)), Color(1, 1, 1, 0.9), false, 1.0)
