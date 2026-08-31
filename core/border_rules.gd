# LA DERIVATION : ce que la liberte des SURFACES impose au bord d'une FACE.
#
# ⚠ ET L'ORDRE N'EST PAS UN CHOIX, C'EST LA DEPENDANCE. La liberte d'une face depend de celle
# des surfaces ; l'inverse est faux -- mesure deux fois : la face est plate LA OU le bord
# perpendiculaire d'une surface peut arriver, et liberer la face n'a jamais rien change aux
# surfaces. Le graphe est donc `silhouettes -> surfaces -> faces`, sans retour, et tout ce qui
# tente de resoudre les deux ensemble casse trois choses pour en bouger une.
#
# ⚠ ET CE FICHIER NE DESSINE PAS, IL CONTRAINT. Il rend les points IMPOSES d'un bord de face --
# `along -> profondeur` -- et laisse tout le reste libre. `render/contour_tiles.gd` s'en sert
# pour fabriquer un profil ; un autre dessin pourrait en fabriquer un autre, du moment qu'il
# passe par les memes points. C'est ca, un formalisme : la contrainte est au modele, la forme
# est au dessin.
extends RefCounted


## LA PROFONDEUR DU COIN, et c'est la seule constante que le modele choisit ici.
##
## ⚠ « ZERO EST LA SEULE PROFONDEUR QUE DEUX BORDS SAVENT SANS SE PARLER » ETAIT FAUX, et cette
## erreur a coute une nuit. Ils savent aussi une CONSTANTE : au coin, les deux bords
## perpendiculaires d'une face se posent tous deux a `CORNER` et s'y rejoignent en
## `(CORNER, CORNER)` -- exactement comme deux bords de surface se rejoignent en `(c, c)`.
static var CORNER: int = 0


## ⚠ ET LE COIN DEMANDE UN SEGMENT PLAT, PAS UN POINT. Deux droites perpendiculaires posees a
## la profondeur `E` ne se rencontrent qu'en `(E, E)` -- encore faut-il que chacune soit
## VRAIMENT a `E` quand l'autre y arrive, c'est-a-dire sur tout `[0, E]`. Pincer au seul point
## du coin laisse les deux se manquer : mesure, 271 extremites.
static func flat_span() -> int:
	return CORNER


## LES POINTS IMPOSES D'UN BORD DE FACE, par ordre de `along`.
##
## `crossing` est la traversee canonique des surfaces -- la profondeur a laquelle le bord d'une
## surface atteint le bord de sa case. C'est une CONSTANTE du modele, la meme pour toutes les
## surfaces : c'est precisement ce qui permet a la face de savoir ou la surface arrivera, sans
## rien connaitre de sa voisine.
##
## Trois familles de contraintes, et rien d'autre :
##   1. LA CONTINUITE -- deux tuiles de la meme face qui se suivent partagent leur bord, donc
##      la profondeur aux deux bouts vaut `CORNER` : c'est la seule valeur que les deux savent.
##   2. LE COIN -- sur `[0, CORNER]` et le segment symetrique, la profondeur reste a `CORNER`,
##      sans quoi les deux bords perpendiculaires de la tuile se manquent.
##   3. LA RENCONTRE -- a `along == crossing`, le bord d'une surface voisine arrive sur le bord
##      de case ; la face doit l'y toucher, donc profondeur ZERO.
##
## Entre ces points, RIEN N'EST IMPOSE : c'est la liberte residuelle, et elle se calcule au
## lieu de se constater.
static func imposed(size: int, crossing: int) -> Dictionary:
	var out: Dictionary = {}
	var span: int = flat_span()
	for along: int in range(span + 1):
		out[along] = CORNER
		out[size - 1 - along] = CORNER
	# ⚠ ET LA RENCONTRE SE FAIT A LA TRAVERSEE, PAS AU RAS -- c'est la correction qui manquait,
	# et elle vient d'une question simple : les coins de surface, les jonctions en T et les
	# coins de falaise sont-ils alignes verticalement ? Mesure :
	#
	#     coin de surface  (4, 4)      constante, MEME a F2
	#     jonction en T     4          le bord d'une surface atteint son bord de case a 4
	#     coin de falaise   0          AU RAS  <- le seul desaligne du modele
	#
	# Le bord d'une surface serpente entre 4 et 7 EN SON MILIEU, mais il revient toujours a 4
	# a ses deux bouts : c'est ce qui lui permet de rejoindre ses voisines sans jamais leur
	# parler. La face doit donc y arriver a 4 ELLE AUSSI, pas a zero. « La face touche le bord
	# de case a la traversee » etait faux, et c'est cette contradiction qui laissait 136
	# extremites : le coin demandait 4, la rencontre demandait 0.
	out[crossing] = crossing
	out[size - 1 - crossing] = crossing
	return out


## LA QUATRIEME CONTRAINTE, ET C'EST LE TRANSFERT QUI LA CREE.
##
## ⚠ LA CRETE N'EXISTE PLUS, DONC EN HAUT D'UNE FACE LE FLANC N'A PLUS RIEN A RENCONTRER. Dans
## l'ancien modele, le flanc montait jusqu'a la crete, qui le refermait. La crete etant passee
## a la tuile de levre, c'est le BANDEAU de cette tuile qui doit continuer le flanc -- et a la
## MEME profondeur, sans quoi le trait saute d'un cran a la frontiere.
##
## Elle ne se pose que la ou le flanc TRACE, c'est-a-dire la ou la face s'arrete de ce cote --
## exactement ce que le bit `LIP_ALONE` dit deja de la levre. Aucun bit de plus.
static func lip_side_depth() -> int:
	return CORNER


## LA LIBERTE RESIDUELLE : le nombre de positions qu'aucune contrainte ne fixe.
##
## ⚠ ET ELLE SE CALCULE, ELLE NE SE CONSTATE PAS. C'est la difference entre un modele et un
## dessin qu'on mesure apres coup : ici on peut DIRE, avant de peindre, combien de pixels de
## bord l'artiste possede.
static func free_count(size: int, crossing: int) -> int:
	return size - imposed(size, crossing).size()
