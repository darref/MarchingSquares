# LE VOCABULAIRE DU PINCEAU : les tuiles que le GESTE atteint.
#
# GENERE PAR `tools/brush_census.gd -- <gestes> --ecrire` -- ne pas editer.
#
# C'EST CELUI-LA QU'ON LIVRE, PAS LA FORME CLOSE. Min trois n'est pas une regle en
# soi : c'est la consequence d'un pinceau qui pose une tuile de surface PLEINE en 3x3
# et laisse les huit contours se raccommoder par calcul. Le peintre peint de la
# surface ; le reste suit. Le modele doit donc prevoir les tuiles necessaires a CELA,
# ni plus ni moins. La forme close, elle, reste la BORNE HAUTE : elle garde I8, elle
# n'est plus la cible.
#
# ET LA LISTE NE PEUT QUE CROITRE : une battue qui ne rencontre pas une tuile prouve
# qu'elle est rare, jamais qu'elle est impossible. Ecraser la liste avec le resultat
# d'une seule execution ferait disparaitre ce qu'une autre avait trouve.
extends RefCounted

static func tiles() -> Array[int]:
	return [28, 31, 112, 124, 127, 223, 241, 247, 253, 255, 287, 479, 497, 503, 511, 519, 543, 705, 735, 753, 759, 767, 775, 961, 967, 991, 65556, 65557, 65616, 65617, 65620, 65813, 65873, 66053, 66069, 66113, 66117, 66129, 66309, 66369, 66373] as Array[int]
