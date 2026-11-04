extends RefCounted

## LE MODÈLE PAR LES COINS — des hauteurs (entières, sur les COINS de la grille) aux ARCHÉTYPES à poser, dans l'ordre où
## ils se posent (Jordan, 4 novembre 2026 : « des tuiles archétypes […] utilisées au bon endroit de manière automatique
## et précalculée, comme MarchingBlocks »). Une couche par unité de hauteur ; la couche L est décalée de L cases vers le
## haut à l'écran, et une falaise fait une case par unité.
##
## Trois sortes d'archétypes, chacun NE DÉPENDANT QUE DE SA CLÉ :
##   DESSUS   (c)        la surface de la couche dans la tuile (sa forme `Forme.colonne`) ;
##   HAUT     (c, c_up)  sous le bord sud, dans la MÊME case : le haut de l'unité de falaise. LÈVRE là où la couche du
##                       dessus (c_up, même tuile) n'a pas le même bord — sinon CORPS ;
##   BAS      (c, c_down) la case du DESSOUS : le bas de l'unité. PIED là où la couche du dessous (c_down) continue
##                       au-delà du bord — sinon CORPS.
## L'ORDRE : couche après couche, du bas vers le haut ; dans une couche, rangée après rangée du nord au sud ; dans une
## rangée, les dessus et les hauts, puis les bas. Ce qui est devant se pose après : c'est TOUTE l'occlusion.
## Le banc (`proof/coins_banc.gd`) compare ce qu'on obtient à un lancer de rayons exact sur le vrai relief.
##
## ⚠ CE FICHIER VIT DANS LE GREFFON (`addons/marching_squares/`) : l'appli et le greffon posent avec LA MÊME règle — une
## règle, un endroit. L'appli le charge d'ici ; le greffon l'emporte dans le projet de l'acheteur.
##
## LES MATIÈRES (Jordan, 4 novembre 2026 : « les variantes, les transitions, tout ça, tu t'en inspires ») : une matière
## est un étage sans falaise. Chaque coin porte un rang de matière (0 = la surface de base) ; sur le dessus de la couche L,
## la matière m occupe la forme de la configuration « coin dans la couche ET rang ≥ m » — les MÊMES quinze formes que les
## dessus, arrondies, qui se raccordent au milieu des arêtes : une transition fondue, jamais un bord en escalier. Ordonnées
## (sable sur herbe, neige sur sable), posées juste après leur dessus ; la forme est contenue dans celle du dessus (la
## forme est monotone en c), donc rien ne déborde sur la falaise.
##
## LES VARIANTES (comme celles de MarchingBlocks) : plusieurs images pour un même archétype, tirées par un HACHAGE de la
## pose (jamais `randi()` : le même monde à chaque reconstruction), pondérées par des poids entiers.

const Forme := preload("res://addons/marching_squares/forme.gd")

const DESSUS := 1
const HAUT := 2
const BAS := 3
const MATIERE := 4

const VARIANTES_MAXI := 9
const MATIERES_MAXI := 4


## La configuration de la tuile (x, j) pour la couche L ; `larg` = nombre de coins par rangée (colonnes + 1).
static func config(h: PackedInt32Array, larg: int, x: int, j: int, L: int) -> int:
	var c := 0
	if h[j * larg + x] >= L:
		c |= Forme.NW
	if h[j * larg + x + 1] >= L:
		c |= Forme.NE
	if h[(j + 1) * larg + x] >= L:
		c |= Forme.SW
	if h[(j + 1) * larg + x + 1] >= L:
		c |= Forme.SE
	return c


## La configuration a-t-elle au moins une colonne de falaise ?
static func a_falaise(c: int) -> bool:
	return Forme.bord_sud(c, 0.25) > 0.0 or Forme.bord_sud(c, 0.75) > 0.0


## La configuration de la matière m sur le dessus de la couche L : coin dans la couche ET de rang ≥ m.
static func config_matiere(h: PackedInt32Array, mat: PackedInt32Array, larg: int, x: int, j: int, L: int, m: int) -> int:
	var c := 0
	var coins: Array[int] = [j * larg + x, j * larg + x + 1, (j + 1) * larg + x, (j + 1) * larg + x + 1]
	var bits: Array[int] = [Forme.NW, Forme.NE, Forme.SW, Forme.SE]
	for k in 4:
		if h[coins[k]] >= L and mat[coins[k]] >= m:
			c |= bits[k]
	return c


## La clé d'une pose dans la table du manifeste : « sorte:c:cv » (cv = 0 pour un dessus). Une matière se pose avec
## l'archétype du DESSUS de sa configuration : sa clé est celle de ce dessus.
static func cle(sorte: int, c: int, cv: int) -> String:
	if sorte == MATIERE:
		return "%d:%d:0" % [DESSUS, c]
	return "%d:%d:%d" % [sorte, c, cv if sorte != DESSUS else 0]


## Le tirage d'une variante pour une pose : `poids` = un poids entier par variante (0 = la base). Hachage de Teschner
## puis deux brassages (sans eux, h mod n dessine des bandes — leçon de MarchingBlocks).
static func tirage(x: int, rangee: int, L: int, sorte: int, poids: PackedInt32Array) -> int:
	var total := 0
	for w: int in poids:
		total += maxi(w, 0)
	if total <= 0 or poids.size() <= 1:
		return 0
	var hh := ((x * 73856093) ^ (rangee * 19349663) ^ ((L * 8 + sorte) * 83492791)) & 0xFFFFFFFF
	hh = ((hh ^ (hh >> 16)) * 0x45d9f3b) & 0xFFFFFFFF
	hh = ((hh ^ (hh >> 16)) * 0x45d9f3b) & 0xFFFFFFFF
	hh = hh ^ (hh >> 16)
	var t := hh % total
	for k in poids.size():
		t -= maxi(poids[k], 0)
		if t < 0:
			return k
	return 0


## Le coin du relief qui se voit au point `p` (en cases ; y en rangées d'écran, comme les poses : j − L), ou -1.
## ⚠ À égalité, le coin de DEVANT (le plus au sud) : deux coins de rangées différentes peuvent tomber au même endroit de
## l'écran, et c'est celui de devant qui se voit (sonde de l'atelier, 4 novembre 2026). Les coins du bord restent au sol.
static func coin_sous(h: PackedInt32Array, colonnes: int, rangees: int, p: Vector2) -> int:
	var larg := colonnes + 1
	var x := clampi(roundi(p.x), 1, colonnes - 1)
	var meilleur := -1
	var ecart := INF
	for j in range(1, rangees):
		var d := absf(float(j - h[j * larg + x]) - p.y)
		if d <= ecart:
			ecart = d
			meilleur = j
	return -1 if meilleur < 0 else meilleur * larg + x


## Les poses, dans l'ordre : [sorte, L, x, case (rangée d'écran), c, c_voisine] ; une matière : [MATIERE, L, x, case,
## c de la matière, m], juste après son dessus. `mat` (un rang par coin) est facultatif.
static func poses(h: PackedInt32Array, colonnes: int, rangees: int, mat := PackedInt32Array()) -> Array:
	var larg := colonnes + 1
	var hmax := 0
	for v: int in h:
		hmax = maxi(hmax, v)
	var nb_mat := 0
	if mat.size() == h.size():
		for v: int in mat:
			nb_mat = maxi(nb_mat, v)
	var sortie := []
	for L in range(0, hmax + 1):
		for j in rangees:
			var bas := []
			for x in colonnes:
				var c := config(h, larg, x, j, L)
				if c == 0:
					continue
				sortie.append([DESSUS, L, x, j - L, c, 0])
				for m in range(1, nb_mat + 1):
					var cm := config_matiere(h, mat, larg, x, j, L, m)
					if cm != 0:
						sortie.append([MATIERE, L, x, j - L, cm, m])
				if L >= 1 and a_falaise(c):
					sortie.append([HAUT, L, x, j - L, c, config(h, larg, x, j, L + 1)])
					bas.append([BAS, L, x, j - L + 1, c, config(h, larg, x, j, L - 1)])
			sortie.append_array(bas)
	return sortie


## L'étiquette d'un pixel (u, v dans la case) d'un archétype ; 0 = transparent.
static func etiquette(sorte: int, L: int, c: int, cv: int, u: float, v: float) -> int:
	match sorte:
		DESSUS, MATIERE:
			return lab(DESSUS, L, 0) if Forme.dedans(c, u, v) else 0
		HAUT:
			var b := Forme.bord_sud(c, u)
			if b < 0.0 or v <= b:
				return 0
			# La couche du dessus a-t-elle le MÊME bord dans cette colonne ? Alors l'unité continue plus haut : corps.
			var bu := Forme.bord_sud(cv, u)
			var levre := not (bu > 0.0 and absf(bu - b) < 1e-7)
			return lab(HAUT, L, 1 if levre else 0)
		BAS:
			var b := Forme.bord_sud(c, u)
			if b < 0.0 or v >= b:
				return 0
			# La couche du dessous va-t-elle au-delà du bord ? Alors c'est le sol où la falaise se pose : pied.
			var ivd := Forme.colonne(cv, u)
			var pied := ivd.x >= 0.0 and ivd.y > b + 1e-7
			return lab(BAS, L, 1 if pied else 0)
	return 0


static func lab(sorte: int, L: int, role: int) -> int:
	return sorte | (L << 2) | (role << 10)
