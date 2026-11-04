extends RefCounted

## LA FORME D'UNE TUILE — le modèle par les COINS de MarchingSquares (Jordan, 4 novembre 2026 : « s'inspirer de
## MarchingBlocks »). Une tuile de la grille duale a quatre coins ; sa CONFIGURATION `c` dit lesquels sont « dedans »
## (pour une couche L : hauteur du coin ≥ L). La forme dans la tuile se lit QUART PAR QUART — chaque quart (½ × ½)
## appartient à son coin, et son état ne dépend que de ce coin, de ses deux voisins d'arête et de l'opposé :
##   PLEIN   le coin est dedans et au moins un voisin aussi (le bord passe droit, au milieu de l'arête) ;
##   DISQUE  le coin est dedans, seul de son côté : un quart de disque de rayon ½ (le coin SAILLANT, arrondi) ;
##   CREUX   le coin est dehors, ses deux voisins et l'opposé dedans : le quart moins le disque (le coin RENTRANT) ;
##   VIDE    sinon (une diagonale seule reste DEUX coins saillants : la selle est séparée, jamais pontée).
## Le bord croise toujours une arête en son MILIEU : deux tuiles voisines se raccordent quelles qu'elles soient.
## ⚠ PROUVÉ À LA MAIN, ÉPROUVÉ PAR LE BANC : dans une colonne de tuile, le « dedans » est UN seul intervalle, qui touche le
## haut ou le bas de la tuile ; une colonne est « de falaise » quand l'intervalle est [0, b] avec b < 1 (son bord sud est
## DANS la tuile). Et la forme d'une couche contient celle de la couche du dessus (monotone en `c`).

const NW := 8
const NE := 4
const SW := 2
const SE := 1
const RAYON := 0.5

const VIDE := 0
const PLEIN := 1
const DISQUE := 2
const CREUX := 3

const EPS := 1e-9


## L'état du quart du coin `coin` dans la configuration `c`.
static func quart(c: int, coin: int) -> int:
	var v: Array = _voisins(coin)
	var dedans := (c & coin) != 0
	var n1 := (c & int(v[0])) != 0
	var n2 := (c & int(v[1])) != 0
	var op := (c & int(v[2])) != 0
	if dedans:
		return PLEIN if (n1 or n2) else DISQUE
	return CREUX if (n1 and n2 and op) else VIDE


## [voisin d'arête, voisin d'arête, opposé]
static func _voisins(coin: int) -> Array:
	match coin:
		NW:
			return [NE, SW, SE]
		NE:
			return [NW, SE, SW]
		SW:
			return [NW, SE, NE]
	return [NE, SW, NW]


## Le « dedans » de la colonne `u` (0..1) : Vector2(a, b), ou Vector2(-1, -1) si vide.
static func colonne(c: int, u: float) -> Vector2:
	var gauche := u < 0.5
	var haut_coin := NW if gauche else NE
	var bas_coin := SW if gauche else SE
	var dx := u if gauche else 1.0 - u
	var s := sqrt(maxf(RAYON * RAYON - dx * dx, 0.0))
	var morceaux: Array[Vector2] = []
	match quart(c, haut_coin):
		PLEIN:
			morceaux.append(Vector2(0.0, 0.5))
		DISQUE:
			morceaux.append(Vector2(0.0, s))
		CREUX:
			morceaux.append(Vector2(s, 0.5))
	match quart(c, bas_coin):
		PLEIN:
			morceaux.append(Vector2(0.5, 1.0))
		DISQUE:
			morceaux.append(Vector2(1.0 - s, 1.0))
		CREUX:
			morceaux.append(Vector2(0.5, 1.0 - s))
	if morceaux.is_empty():
		return Vector2(-1, -1)
	if morceaux.size() == 1:
		return morceaux[0]
	# Deux morceaux : ils se touchent à ½ (sinon la forme ne serait pas un seul intervalle — le banc le dirait).
	if absf(morceaux[0].y - morceaux[1].x) < 1e-6:
		return Vector2(morceaux[0].x, morceaux[1].y)
	push_error("forme : deux intervalles disjoints, c=%d u=%f" % [c, u])
	return morceaux[0]


static func dedans(c: int, u: float, v: float) -> bool:
	var iv := colonne(c, u)
	return iv.x >= 0.0 and v >= iv.x - EPS and v <= iv.y + EPS


## La colonne porte-t-elle un bord SUD dans la tuile (une falaise y commence) ? Rend b, ou -1.
static func bord_sud(c: int, u: float) -> float:
	var iv := colonne(c, u)
	if iv.x < 0.0 or iv.x > EPS or iv.y >= 1.0 - EPS or iv.y <= EPS:
		return -1.0
	return iv.y
