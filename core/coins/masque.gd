extends RefCounted

## LE MASQUE — un tileset d'APLATS qui MONTRE ce que chaque pixel d'un archétype EST : la surface où l'on MARCHE, et la
## falaise qui BLOQUE (sa lèvre, son corps, son pied). Pas de l'art : le point de départ qu'un JEU propose à ses joueurs
## pour qu'ils dessinent par-dessus sans jamais changer la forme (Pix, les donjons — Jordan, 6 novembre 2026 : « les tuiles
## proposées au départ, c'est vraiment le masque lui-même, peint avec des couleurs génériques pour montrer ce qu'on peut
## faire »). Chaque catégorie est UN aplat : l'outil Remplir d'un joueur la prend d'un seul clic.
##
## Comme l'essai, le motif ne dépend que de l'étiquette du pixel (`Modele.etiquette`, par `Rendu.masque_de`) : il se
## raccorde de lui-même partout.

const Archetypes := preload("res://core/coins/archetypes.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Travail := preload("res://core/coins/travail.gd")
const Painting := preload("res://core/painting.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const Essai := preload("res://core/coins/essai.gd")

## Où l'on marche.
const MARCHER := Color(0.83, 0.79, 0.68)
## Le TRAIT au bord de chaque dessus (Jordan, 6 novembre 2026 : « il manque des contours autour des plateaux […] le sol
## d'un plateau et de celui qui est au-dessus ou au-dessous sont confondus ») : un pixel, DANS la tuile, sur le vrai bord
## de la forme (jamais le bord de la tuile : la forme continue chez la voisine). On y marche aussi.
const TRAIT := Color(0.42, 0.38, 0.33)
## Ce qui bloque : la lèvre (le haut de la falaise), le corps, le pied.
const LEVRE := Color(0.62, 0.6, 0.62)
const CORPS := Color(0.44, 0.42, 0.46)
const PIED := Color(0.27, 0.25, 0.29)


## La couleur d'une étiquette (0 = transparent).
static func couleur(e: int) -> Color:
	match e & 3:
		Modele.DESSUS:
			return MARCHER
		Modele.HAUT:
			return LEVRE if (e >> 10) & 1 else CORPS
		Modele.BAS:
			return PIED if (e >> 10) & 1 else CORPS
	return Color(0, 0, 0, 0)


## Un carnet peint du masque : les bases seulement (pas de matière : la forme est tout).
static func peindre(res: int) -> Painting:
	var p := Painting.new(res)
	for a: Dictionary in Archetypes.liste():
		var m := Rendu.masque_de(a.numero, res)
		for y in res:
			for x in res:
				var e := m[y * res + x]
				if e == 0:
					continue
				var c := couleur(e)
				if (e & 3) == Modele.DESSUS and Essai.distance_au_bord(m, res, x, y) < 1.5 * maxf(1.0, res / 32.0):
					c = TRAIT
				p.paint(Vector2i(a.numero, 0), x, y, c)
	return p


## Écrit le masque (planche + manifeste) dans `dossier`. Rend [planche, manifeste, non peintes].
static func ecrire(dossier: String, res: int) -> Array:
	return Travail.exporter(peindre(res), {"poids": {}, "affectation": {}}, dossier)
