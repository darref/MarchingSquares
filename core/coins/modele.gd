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

const Forme := preload("res://core/coins/forme.gd")

const DESSUS := 1
const HAUT := 2
const BAS := 3


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


## Les poses, dans l'ordre : [sorte, L, x, case (rangée d'écran), c, c_voisine].
static func poses(h: PackedInt32Array, colonnes: int, rangees: int) -> Array:
	var larg := colonnes + 1
	var hmax := 0
	for v: int in h:
		hmax = maxi(hmax, v)
	var sortie := []
	for L in range(0, hmax + 1):
		for j in rangees:
			var bas := []
			for x in colonnes:
				var c := config(h, larg, x, j, L)
				if c == 0:
					continue
				sortie.append([DESSUS, L, x, j - L, c, 0])
				if L >= 1 and a_falaise(c):
					sortie.append([HAUT, L, x, j - L, c, config(h, larg, x, j, L + 1)])
					bas.append([BAS, L, x, j - L + 1, c, config(h, larg, x, j, L - 1)])
			sortie.append_array(bas)
	return sortie


## L'étiquette d'un pixel (u, v dans la case) d'un archétype ; 0 = transparent.
static func etiquette(sorte: int, L: int, c: int, cv: int, u: float, v: float) -> int:
	match sorte:
		DESSUS:
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
