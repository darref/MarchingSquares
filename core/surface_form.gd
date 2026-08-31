## LA FORME FERMEE DES SURFACES -- ce que le modele PEUT exiger, cle par cle.
##
## ⚠ GENERE PAR `tools/make_surface_form.gd` DEPUIS `tools/closed_form_now.py`.
## Ne pas editer a la main : l'enumeration vit dans l'outil, avec les
## preconditions de chaque bit et les trois theoremes qui les ferment.
##
## ⚠ ET C'EST UNE BORNE HAUTE, PAS UN RELEVE. Elargir la famille de mondes fait
## monter le compte RENCONTRE et ne touche jamais celui-ci. Les deux se
## rejoignent quand le vocabulaire est serre -- c'est le critere 3 du plan.
##
## ⚠ UNE CLE EST UN COUPLE : la silhouette dans les huit bits bas, les bits de
## bord au-dessus. `BlobIndex.silhouette()` et `BlobIndex.brink()` les separent.
extends RefCounted


## Les 69 cles, en ordre croissant.
const KEYS: Array[int] = [
	7, 20, 23, 80, 84, 87, 193, 199, 209, 213, 215, 336, 337, 449, 465, 519, 532, 533, 535, 1095, 
	1111, 1345, 1361, 2245, 2261, 2565, 2581, 262164, 262224, 262228, 262480, 262676, 524481, 
	524497, 1048583, 1048599, 2097172, 2097236, 2097684, 4194384, 4194388, 4194640, 6291540, 
	8388688, 8388817, 8650832, 8913105, 12582992, 16777236, 16777239, 17039380, 17825815, 
	18874388, 33554439, 33554629, 33554631, 33554949, 33554951, 33556677, 33556997, 34603015, 
	67108935, 67109057, 67109063, 67109185, 67109313, 67109959, 67110209, 67633345
]
