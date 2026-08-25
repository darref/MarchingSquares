## LES LEVRES VOISINES D'UN ILOT DE PREUVE, cherchees puis verifiees.
##
## Une tuile de surface est le couple (silhouette, bord) : un cardinal vide borde
## soit du NU -- ca tombe -- soit de la ROCHE, la face d'une falaise voisine. L'ilot
## doit donc mettre en scene cette falaise, et SA POSITION NE SE DEDUIT PAS : collee,
## elle pince une colonne de vide d'une case ; trois rangees plus haut, elle pince
## ailleurs ; et quand le nord veut de la roche et l'est du nu, son bloc doit
## chevaucher la colonne du voisin PLEIN. Trois raisonnements, trois erreurs.
##
## Genere par `tools/make_islands.gd` (balayage + juge : epais ? porte la tuile ?)
## puis `tools/make_brink_lips.gd`. Ne pas editer a la main -- la suite reverifie.
##
## tuile -> cases d'un etage AU-DESSUS, en coordonnees relatives au centre de l'ilot.
const LIPS: Dictionary = {
	276: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	284: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	336: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	348: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	368: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	372: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	380: [Vector2i(-2, -9), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-1, -9), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(0, -9), Vector2i(0, -8), Vector2i(0, -7)],
	592: [Vector2i(1, -8), Vector2i(1, -7), Vector2i(1, -6), Vector2i(2, -8), Vector2i(2, -7), Vector2i(2, -6), Vector2i(3, -8), Vector2i(3, -7), Vector2i(3, -6)],
	624: [Vector2i(1, -8), Vector2i(1, -7), Vector2i(1, -6), Vector2i(2, -8), Vector2i(2, -7), Vector2i(2, -6), Vector2i(3, -8), Vector2i(3, -7), Vector2i(3, -6)],
	705: [Vector2i(1, -8), Vector2i(1, -7), Vector2i(1, -6), Vector2i(2, -8), Vector2i(2, -7), Vector2i(2, -6), Vector2i(3, -8), Vector2i(3, -7), Vector2i(3, -6)],
	721: [Vector2i(1, -8), Vector2i(1, -7), Vector2i(1, -6), Vector2i(2, -8), Vector2i(2, -7), Vector2i(2, -6), Vector2i(3, -8), Vector2i(3, -7), Vector2i(3, -6)],
	753: [Vector2i(1, -8), Vector2i(1, -7), Vector2i(1, -6), Vector2i(2, -8), Vector2i(2, -7), Vector2i(2, -6), Vector2i(3, -8), Vector2i(3, -7), Vector2i(3, -6)],
	848: [Vector2i(-1, -6), Vector2i(-1, -5), Vector2i(-1, -4), Vector2i(0, -6), Vector2i(0, -5), Vector2i(0, -4), Vector2i(1, -6), Vector2i(1, -5), Vector2i(1, -4)],
	880: [Vector2i(-1, -6), Vector2i(-1, -5), Vector2i(-1, -4), Vector2i(0, -6), Vector2i(0, -5), Vector2i(0, -4), Vector2i(1, -6), Vector2i(1, -5), Vector2i(1, -4)],
	1031: [Vector2i(-3, -8), Vector2i(-3, -7), Vector2i(-3, -6), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-2, -6), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(-1, -6)],
	1044: [Vector2i(-3, -8), Vector2i(-3, -7), Vector2i(-3, -6), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-2, -6), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(-1, -6)],
	1047: [Vector2i(-3, -8), Vector2i(-3, -7), Vector2i(-3, -6), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-2, -6), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(-1, -6)],
	1052: [Vector2i(-3, -8), Vector2i(-3, -7), Vector2i(-3, -6), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-2, -6), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(-1, -6)],
	1055: [Vector2i(-3, -8), Vector2i(-3, -7), Vector2i(-3, -6), Vector2i(-2, -8), Vector2i(-2, -7), Vector2i(-2, -6), Vector2i(-1, -8), Vector2i(-1, -7), Vector2i(-1, -6)],
	1300: [Vector2i(-2, -6), Vector2i(-2, -5), Vector2i(-2, -4), Vector2i(-1, -6), Vector2i(-1, -5), Vector2i(-1, -4), Vector2i(0, -6), Vector2i(0, -5), Vector2i(0, -4)],
	1308: [Vector2i(-2, -6), Vector2i(-2, -5), Vector2i(-2, -4), Vector2i(-1, -6), Vector2i(-1, -5), Vector2i(-1, -4), Vector2i(0, -6), Vector2i(0, -5), Vector2i(0, -4)],
}
