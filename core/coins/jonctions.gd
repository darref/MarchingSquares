extends RefCounted

## LES JONCTIONS — ce que le peintre doit VOIR pour qu'aucune couture ne le surprenne à l'export (charte : « le résultat
## est visible pendant le travail »). Une jonction est une COUTURE : deux archétypes qui appartiennent à la MÊME surface ou
## à la MÊME falaise et se touchent :
##   D  à DROITE    deux poses de la même couche, même sorte de ligne (dessus/haut dans une case, bas dans la suivante),
##                  dans deux tuiles voisines de la même rangée ;
##   V  en DESSOUS  dans la même colonne et la même couche : le dessus d'une rangée et celui de la suivante ; le haut d'une
##                  unité de falaise et son bas (l'unité est à cheval sur deux cases) ;
##   S  SUPERPOSÉES dans la même case et la même tuile : le bas de l'unité L et le haut de l'unité L−1 (deux unités
##                  empilées) ; le bas de l'unité L et le dessus de L−1 (le pied posé sur la terrasse) ; le dessus et le
##                  haut de la même couche (la surface et la lèvre).
## Ce qu'un plateau CACHE derrière lui n'en est pas une : c'est une silhouette, dont le contour est dans sa propre tuile.
##
## ⚠ L'ENSEMBLE EST FINI ET SE COMPTE. Une couture ne dépend que de deux tuiles voisines — six coins — comparés aux étages
## L−1, L et L+1 : quatre classes (en dessous de L−1, L−1, L, au-dessus), donc les hauteurs 0..3 à L = 2 les donnent
## toutes. `ensemble()` énumère les 4⁶ voisinages de chaque orientation ; le banc vérifie qu'aucun monde n'en sort.

const Modele := preload("res://addons/marching_squares/modele.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")

static var _ensemble := {}


## Les jonctions d'un monde : {"D:a:b" | "V:a:b" | "S:a:b": [x, j, L]} (une position où chacune se voit).
static func du_monde(h: PackedInt32Array, colonnes: int, rangees: int) -> Dictionary:
	var larg := colonnes + 1
	var hmax := 0
	for v: int in h:
		hmax = maxi(hmax, v)
	var sortie := {}
	for L in range(1, hmax + 1):
		for j in rangees:
			for x in colonnes:
				var ici := _pieces(h, larg, x, j, L)
				if ici.is_empty():
					continue
				# D : la tuile de droite, même couche.
				if x + 1 < colonnes:
					var droite := _pieces(h, larg, x + 1, j, L)
					for s: int in ici:
						if droite.has(s):
							_noter(sortie, "D", ici[s], droite[s], x, j, L)
				# V : dessus → dessus de la rangée suivante ; haut → bas (la même unité).
				if ici.has(Modele.DESSUS) and j + 1 < rangees:
					var dessous := _pieces(h, larg, x, j + 1, L)
					if dessous.has(Modele.DESSUS):
						_noter(sortie, "V", ici[Modele.DESSUS], dessous[Modele.DESSUS], x, j, L)
				if ici.has(Modele.HAUT):
					_noter(sortie, "V", ici[Modele.HAUT], ici[Modele.BAS], x, j, L)
					if ici.has(Modele.DESSUS):
						_noter(sortie, "S", ici[Modele.DESSUS], ici[Modele.HAUT], x, j, L)
				# S : sous le bas de l'unité L, l'unité L−1 (haut) ou la terrasse L−1 (dessus) de la même tuile.
				if ici.has(Modele.BAS) and L >= 2:
					var sous := _pieces(h, larg, x, j, L - 1)
					if sous.has(Modele.HAUT):
						_noter(sortie, "S", ici[Modele.BAS], sous[Modele.HAUT], x, j, L)
					if sous.has(Modele.DESSUS):
						_noter(sortie, "S", ici[Modele.BAS], sous[Modele.DESSUS], x, j, L)
	return sortie


## Les archétypes posés par la tuile (x, j) à la couche L : {sorte: numéro}.
static func _pieces(h: PackedInt32Array, larg: int, x: int, j: int, L: int) -> Dictionary:
	var c := Modele.config(h, larg, x, j, L)
	var p := {}
	if c == 0:
		return p
	p[Modele.DESSUS] = Archetypes.numero(Modele.DESSUS, c, 0)
	if L >= 1 and Modele.a_falaise(c):
		p[Modele.HAUT] = Archetypes.numero(Modele.HAUT, c, Modele.config(h, larg, x, j, L + 1))
		p[Modele.BAS] = Archetypes.numero(Modele.BAS, c, Modele.config(h, larg, x, j, L - 1))
	return p


static func _noter(sortie: Dictionary, sens: String, a: int, b: int, x: int, j: int, L: int) -> void:
	var k := "%s:%d:%d" % [sens, a, b]
	if not sortie.has(k):
		sortie[k] = [x, j, L]


## L'ensemble FERMÉ : {jonction: voisinage qui la porte — [colonnes, rangees, hauteurs (PackedInt32Array)]}.
static func ensemble() -> Dictionary:
	if not _ensemble.is_empty():
		return _ensemble
	for orientation: Array in [[2, 1], [1, 2]]:
		var colonnes: int = orientation[0]
		var rangees: int = orientation[1]
		var n := (colonnes + 1) * (rangees + 1)
		for code in int(pow(4, n)):
			var h := PackedInt32Array()
			h.resize(n)
			var r := code
			for i in n:
				h[i] = r % 4
				r /= 4
			# ⚠ Un voisinage en selle n'existe plus (Jordan, 4 novembre 2026) : 261 → 227 jonctions.
			if not Modele.sans_selle(h, PackedInt32Array(), colonnes, rangees):
				continue
			for k: String in du_monde(h, colonnes, rangees):
				if not _ensemble.has(k):
					_ensemble[k] = [colonnes, rangees, h]
	return _ensemble
