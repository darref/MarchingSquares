# LE VOCABULAIRE DU PINCEAU : les tuiles que le GESTE atteint.
#
# GENERE PAR `tools/brush_census.gd -- <gestes> --ecrire`, et complete par le GUIDE --
# dont chaque monde sort d une suite de tampons, donc dont chaque tuile est atteignable
# par construction. Ne pas editer a la main.
#
# C EST CELUI-LA QU ON LIVRE, PAS LA FORME CLOSE. Min trois n est pas une regle en soi :
# c est la consequence d un pinceau qui pose une tuile de surface PLEINE en 3x3 et laisse
# les huit contours se raccommoder par calcul. Le peintre peint de la surface ; le reste
# suit. La forme close reste la BORNE HAUTE : elle garde I8, elle n est plus la cible.
#
# ET LA LISTE NE PEUT QUE CROITRE : une battue qui ne rencontre pas une tuile prouve
# qu elle est rare, jamais qu elle est impossible.
extends RefCounted

static func tiles() -> Array[int]:
	return [28, 31, 112, 124, 127, 223, 241, 253, 255, 287, 479, 497, 503, 511, 543, 735, 753, 759, 767, 775, 961, 967, 65556, 65557, 65616, 65617, 65620, 65813, 65873, 66053, 66065, 66069, 66113, 66117, 66129, 66305, 66309, 66369, 66373] as Array[int]
