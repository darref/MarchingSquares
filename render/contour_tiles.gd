# LE PINCEAU DU CONTOUR PROUVE -- une tuile, un dessin d'un pixel.
#
# ⚠ IL VIENT DU BANC, ET C'EST TOUT L'INTERET. `proof/ladder.gd` a etabli, cran par cran, ce
# qu'une tuile doit savoir et ou son trait a le droit d'aller ; ces regles-la vivaient dans le
# banc, donc le LOGICIEL n'en avait rien. Elles sont ici desormais, et le banc les LIT : une
# seule source, et le rejeu des vingt-six couples est la preuve que le deplacement n'a pas
# change un pixel.
#
# ⚠ ET C'EST LA PREMIERE MOITIE DU PORTAGE. Le modele -- quels bits une case porte -- est encore
# au banc ; ce qui est ici est le DESSIN : quels cotes s'ouvrent, a quelle profondeur le trait
# rentre, ou il se pince, et les deux rendez-vous de la famille a cheval.
#
# ⚠ LES REGLAGES DE MESURE RESTENT DES VARIABLES, et ils sont la trace des routes refusees --
# `meet`, `half_axis`, `ergot_diag`, `j2_on_face`, `astride`. Un chiffre qu'on ne peut plus
# reproduire n'est plus un chiffre ; le banc les pose, le produit les laisse a leur defaut.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
## ⚠ LES BITS SONT DU MODELE, DONC ILS VIVENT DANS `core/` -- et le dessin les LIT.
## L'inverse mettrait une question de modele dans un fichier de rendu, et `core/` ne
## doit rien devoir a `render/`.
const Brink := preload("res://core/brink.gd")
const BorderRules := preload("res://core/border_rules.gd")
const NORTH_QUIET := Brink.NORTH_QUIET
const ABOVE_QUIET_EAST := Brink.ABOVE_QUIET_EAST
const ABOVE_QUIET_WEST := Brink.ABOVE_QUIET_WEST
const NORTH_FLUSH_EAST := Brink.NORTH_FLUSH_EAST
const NORTH_FLUSH_WEST := Brink.NORTH_FLUSH_WEST
const BELOW_QUIET_EAST := Brink.BELOW_QUIET_EAST
const BELOW_QUIET_WEST := Brink.BELOW_QUIET_WEST
const CARDINALS := Brink.CARDINALS
const STEPS := Brink.STEPS
const DIAGONALS := Brink.DIAGONALS
const CornerIndex := preload("res://core/corner_index.gd")
const Walls := preload("res://core/walls.gd")

## L'etage du monde en cours de dessin : plusieurs regles ne valent qu'a partir de L2 -- rien au
## sud, les deux coins sud muets -- et le dessin doit savoir lequel il sert.
static var level: int = 0

## LA LIBERTE DU BORD D'UNE FACE. Vide : le bord est plat de part et d'autre des deux
## traversees et serpente entre elles -- ce que la mesure impose. `points` rejoue la route
## refusee, qui ne pincait qu'aux quatre points ; gardee joignable comme les autres, parce
## qu'un chiffre qu'on ne peut plus reproduire n'est plus un chiffre.
static var wall_free: String = ""

## L'AMPLITUDE MAXIMALE DE LA BOSSE D'UN BORD DE FACE, en pixels de tuile.
##
## ⚠ SIX, ET C'EST MESURE. Elle valait TROIS, sans que personne l'ait interrogee : une face
## respirait de trois pixels la ou une surface en prend quatre a sept. Portee a six, les six
## invariants restent verts sur les VINGT-SIX couples, et les profils de face passent de 12 a
## 24 sur le guide. C'etait la seule liberte encore disponible une fois le ras des intervalles
## demontre -- et elle ne coute rien. `LADDER_WALLREACH` la fait varier.
static var wall_reach: int = 6


## L'ARETE INTERNE : le trait qui descend entre deux faces voisines qui ne pendent pas de la
## meme levre. C'est elle qui donne le relief, et sans elle deux falaises accolees se lisent
## comme UNE SEULE masse de roche.
##
## ⚠ ET AUCUN INVARIANT NE LA RECLAMERA JAMAIS. La matiere y est continue des deux cotes :
## I1 ne voit pas de trou, I3 pas de frontiere, I2 pas de pave. Tous verts, et le relief
## absent. C'est la seule espece du recensement qui veuille UN trait la ou le modele n'a AUCUN
## bord -- donc la seule qui se decide a l'oeil, et il fallait la decider avant de figer.
##
## ⚠ ELLE NE COUPE PAS LA MATIERE, ELLE LA MARQUE. Un flanc `arret` coupe -- au-dela il n'y a
## rien -- alors qu'ici la roche continue chez la voisine et je pose seulement mon angle. Les
## deux se distinguent donc a l'oeil DANS la tuile, ce qui est la condition pour qu'un artiste
## puisse les peindre : une distinction qu'il ne voit pas dans sa tuile n'est pas dessinable.
##
## ⚠ ET « PAS DE DOUBLE ARETE » EST UN INVARIANT, PAS UN GOUT. Faire tracer les deux voisines
## donnerait un trait de deux pixels -- exactement ce que I2 compte comme pave. Un seul trace,
## et c'est celui qui AVANCE : sa levre est plus au SUD, donc son bloc saille vers le regard.
##
## ⚠ ET A EGALITE DE RANGEE, C'EST LE PLUS HAUT QUI PORTE L'ANGLE. Deux levres sur la MEME
## rangee mais a des etages differents, ce sont deux hauteurs 3D differentes : il y a bien une
## marche entre les deux blocs, et c'est celui du dessus qui la porte. Decision utilisateur, et
## elle corrige un premier choix pris a l'ecran (`personne`) : l'image ne montrait pas la
## marche, le raisonnement l'a retrouvee. Les deux conventions coutent EXACTEMENT 44 roles --
## le choix est donc de lecture, jamais de prix.
##
## `haut` : la regle. `personne` : la route refusee, gardee joignable. Vide : aucune arete,
## l'etat d'avant -- deux falaises accolees se lisent alors comme une seule masse de roche.
static var wall_ridge: String = "haut"

## La traversee forcee a une valeur unique, pour mesurer ce qui en depend. Zero : le tirage
## d'origine, une constante par cote.
static var forced_crossing: int = 0
## La regle de l'ergot, par la DIAGONALE ; `false` rejoue l'ancienne, par la voisine.
static var ergot_diag: bool = true
## Le rendez-vous : `both` (la regle), `none`, `orig`, `miroir`.
static var meet: String = "both"
## Les moities comptees depuis l'axe -- refute deux fois, garde comme trace.
static var half_axis: bool = false
## La cession de J2 portee par la FACE au lieu de la surface -- refute.
static var j2_on_face: bool = false
## La famille a cheval : `face` fait ceder ses flancs a la robe -- refute.
static var astride: String = ""


const RES: int = 16

## ⚠ LES COULEURS SONT CELLES D'UNE PREUVE, PAS D'UN PAYSAGE. Le premier jeu prenait la
## teinte du logiciel -- vert moyen, trait vert tres sombre -- et a l'ecran le trait se
## confondait avec la matiere : on ne voyait plus la silhouette, c'est-a-dire la seule chose
## que ce banc existe pour montrer. Matiere claire, trait noir, fond franchement autre.
const GRASS: Color = Color("#c3d98f")

const OUTLINE: Color = Color("#0d0f12")

## Uniquement pour REGARDER : le fond hors monde, et l'etage 0 de la planche, pose derriere
## en sourdine pour qu'on voie sur quoi les specimens reposent. Rien de tout cela n'entre dans
## la mesure -- celle-ci se fait sur l'image a fond transparent, avant compositation.
## La roche des falaises : claire elle aussi, pour que le trait noir s'y lise.
const ROCK: Color = Color("#d6bb95")












## LA TUILE D'UN CROISEMENT : quatre quadrants, un par case touchee.
##
## ⚠ ET SON CONTOUR EST ENTIEREMENT INTERNE, C'EST LE THEOREME DU NIVEAU. Le quadrant SE de la
## tuile d'un croisement et le quadrant SO de sa voisine de l'est designent LA MEME CASE : la
## matiere traverse le bord de tuile sans qu'il y ait de frontiere. Une tuile a cheval n'a donc
## jamais a savoir ce qu'il y a a cote -- toute frontiere qu'elle porte est chez elle, entre
## deux de ses propres quadrants. C'est pour ca que la famille n'a que quinze tuiles et pas un
## seul bit de bord.
##
## ⚠ ET UNE FRONTIERE DU MONDE EST PARTAGEE ENTRE DEUX TUILES, chacune en tracant sa moitie :
## le bord entre deux cases court sur une case entiere, et deux tuiles voisines s'en partagent
## les deux demis. Elles se rejoignent a leur bord commun, ou toutes deux tracent au meme
## endroit -- l'axe de leur quadrant.
## ⚠ ET « RIEN AU SUD » VAUT AUSSI A CHEVAL, PAR LE MEME THEOREME. Une frontiere horizontale
## interne dont le HAUT est plein et le bas vide est une LEVRE : la face commence juste dessous,
## et c'est son chapiteau qui porte cette frontiere. Sans cette regle, la tuile de croisement et
## le chapiteau la tracent tous les deux, a un pixel l'un de l'autre -- mesure du temoin :
## 7 446 paves et 744 doublements, tous a la falaise.
## ⚠ ET LES DEUX ISSUES DE LA JONCTION LATERALE SE CHIFFRENT ICI. La frontiere verticale interne
## d'une tuile a cheval tombe sur le BORD DE CASE -- son axe -- donc la ou une robe trace son
## flanc. Deux facons d'en sortir, et le banc les mesure toutes les deux :
##   `surface`  la tuile a cheval se tait, et paie DEUX BITS -- un par demi-frontiere, nord et
##              sud, chacun leve quand cette moitie-la borde de la roche ;
##   `face`     la robe cede son flanc, et paie une CESSION sur la famille des robes.
static func corner_tile(index: int, freedom: int, seams: Array[int], level: int = 0,
		quiet: int = 0) -> Image:
	var tile: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	var half: int = RES / 2
	var solid: Array[PackedByteArray] = []
	for y: int in range(RES):
		var line: PackedByteArray = PackedByteArray()
		line.resize(RES)
		for x: int in range(RES):
			# ⚠ ET LES DEUX AXES SE DEPLACENT, C'EST TOUTE LA LIBERTE DE CETTE FAMILLE. Une
			# tuile a cheval n'a pas de bord a faire rentrer -- ses cotes sont a moitie pleins
			# par construction. Ce qui a une position, chez elle, c'est l'AXE entre deux
			# quadrants ; le peintre le deplace, et c'est ca que I5 mesure.
			# ⚠ GELER L'AXE LA OU C'EST LA ROBE QUI TRACE A ETE ESSAYE, ET MESURE MAUVAIS.
			# L'idee : le flanc d'une robe est sur le BORD DE CASE, donc si l'axe s'en ecarte
			# la frontiere que la robe porte n'est plus celle de la tuile. Le bit qui fait
			# taire la moitie dit deja exactement ou -- il pouvait donc aussi figer sa
			# position, pour zero tuile. Resultat : 43 extremites -> 40 a F1, et I5 rouge --
			# l'axe fige d'un cote et libre de l'autre fait une MARCHE au milieu du profil,
			# donc plusieurs profils dont onze qui ondulent la ou F1 les promet plats. Trois
			# pixels contre la liberte annoncee : on ne paie pas.
			# ⚠ QUATRE FACONS D'ACCORDER L'AXE AU FLANC DE LA ROBE, TOUTES MESUREES, AUCUNE
			# PAYEE. La geometrie du defaut est exacte : l'axe d'une tuile a cheval tombe sur
			# le BORD DE CASE, et le flanc d'une robe RENTRE de `_wall_depth` des F1 -- les
			# deux ne coincident plus, le trait que la robe porte n'est plus sur la frontiere
			# de la tuile, et il meurt dans la matiere.
			#
			#   l'axe reste libre (garde)                 43 ext a F1, 91 a F2,  64 tuiles
			#   geler l'axe la ou la robe trace           40 a F1, et I5 ROUGE
			#   suivre -`_wall_depth`, sans le cote      123 a F1
			#   suivre +`_wall_depth`, sans le cote       77 a F1
			#   BIT DEDOUBLE PAR COTE, et suivre          40 a F1, 40 a F2, 105 tuiles
			#   demi-frontieres comptees depuis l'AXE     46 a F1, 94 a F2  (PIRE)
			#   LE RENDEZ-VOUS AVEC LA CRETE               43 -> 7 a F1, 0 tuile  (GARDE)
			#   l'axe PAR-DESSUS le rendez-vous            46 a F1  (il l'ANNULE)
			#   PINCER l'axe dans la moitie muette          7 -> 4 a F1 ET a F2  (GARDE)
			#   + la RANGEE DE PASSAGE, du cote libre       53 a F1, 35 paves, I5 rouge (NON)
			#
			# ⚠ LA DERNIERE EST REFUSEE NET, ET ELLE VISAIT LES QUATRE QUI RESTENT. L'idee :
			# le trait ne devient visible qu'une fois sorti de sous la robe, donc sa premiere
			# rangee visible est la premiere rangee de la moitie qui TRACE, et sa position y
			# serait imposee comme celle de la moitie muette. Mesure : le pas se deplace d'une
			# rangee sans disparaitre, et il tombe la ou la matiere ne le porte plus -- 4 -> 53.
			# Le passage de main ne se decale pas d'une rangee : il est OU IL EST.
			#
			# ⚠ ET LE PINCAGE EST LE PIEGE QUE I5 EXISTE POUR ATTRAPER. Il ferme trois des
			# sept -- en ramenant la frontiere sur la grille des cases la ou la main se passe,
			# ce qui est geometriquement JUSTE -- et il le paie en LIBERTE : 5 profils dont 11
			# qui serpentent, la ou F1 en promet UN, plat. Un axe pince d'un cote et libre de
			# l'autre fait une marche au milieu du profil. C'est mot pour mot « fermer en
			# figeant », et le plan l'interdit tant que l'impossibilite n'est pas DEMONTREE.
			#
			# ⚠ ET CE N'EST PAS REGLABLE : toute forme de pincage rend le profil non plat,
			# donc I5 rouge, par definition de F1 pour cette famille. La question n'est donc
			# pas « comment pincer moins » mais « le retour a la grille des cases au passage
			# de main est-il une REGLE DE LA FAMILLE plutot qu'une perte de liberte ? ». Si
			# c'en est une, c'est la promesse de F1 qui doit se relire -- un profil plat
			# deplace ENTRE les passages de main -- et I5 avec elle. Decision ouverte.
			#
			# ⚠ ET LA DERNIERE DIT POURQUOI LA COUPE A `RES / 2` EST JUSTE, ce qu'aucune des
			# deux mesures ne pouvait dire seule. `RES / 2` n'est pas « le milieu de la
			# tuile » : c'est LE BORD DE CASE en repere de tuile -- le pixel 8 est le premier
			# de la case suivante. Or la moitie qui se tait passe la main a une ROBE, et une
			# robe vit sur la grille des CASES. La coupe doit donc etre sur cette grille-la,
			# pas sur l'axe deplace : c'est elle qui arrete le trait a la derniere rangee
			# VISIBLE, exactement ou le rendez-vous vient le chercher. Comptee depuis l'axe,
			# la coupe rend deux rangees invisibles au trait, le rendez-vous se pose au milieu
			# de lui et ne ferme plus rien -- 46, le chiffre de l'axe seul.
			#
			# ⚠ LA REGLE GENERALE, ET ELLE VAUT AU-DELA DE CE NIVEAU : UNE FRONTIERE PARTAGEE
			# AVEC UNE AUTRE FAMILLE SE COUPE SUR LA GRILLE DE CETTE FAMILLE. La liberte peut
			# deplacer ce qu'une tuile dessine CHEZ ELLE ; elle ne peut pas deplacer l'endroit
			# ou elle passe la main.
			#
			# ⚠ LA DERNIERE EST INSTRUCTIVE, ET C'EST POUR CA QU'ELLE EST GARDEE ICI. Les bits
			# de silence se classent a `RES / 2` fixe alors que les deux axes SE DEPLACENT des
			# F1 : pour l'index 1, le quadrant NO descend jusqu'a `hy = 9` et ses rangees 8 et
			# 9 se faisaient taire sur le bit du SUD. Corrige -- demi-frontiere comptee depuis
			# l'axe -- le trait descend bien jusqu'au centre de la tuile... et l'extremite se
			# DEPLACE de (9,7) a (9,9) sans disparaitre : 43 -> 46 et 91 -> 94. Les noyees, 42
			# a F1 et 90 a F2, ne bougent pas d'une.
			#
			# ⚠ CE QUE CA PROUVE : LA CLASSIFICATION DES MOITIES N'EST PAS LA CAUSE. Le trait
			# vertical n'a rien pour le fermer EN BAS, ou qu'il s'arrete -- sa frontiere
			# horizontale est portee par le chapiteau, qui est sur la grille des CASES pendant
			# que l'axe, lui, se deplace. Deplacer l'extremite d'un bout a l'autre du meme
			# segment ne ferme rien : c'est le RENDEZ-VOUS avec la crete qui manque, et c'est
			# la seule piste qui reste.
			#
			# ⚠ LE DEDOUBLEMENT EST LE SEUL QUI MORDE VRAIMENT -- il divise F2 par plus de deux
			# -- ET IL NE FERME PAS. Quarante extremites restent, les MEMES a F1 et a F2 : une
			# autre cause est devenue dominante. Payer 41 tuiles pour une fermeture partielle
			# contredit les deux premieres priorites du plan ; on garde la mesure et on cherche
			# la cause qui reste.
			# ⚠ L'AXE REVIENT SUR LA GRILLE DES CASES LA OU IL PASSE LA MAIN -- REGLE DE LA
			# FAMILLE, decidee. Une tuile a cheval deplace librement une frontiere qu'elle
			# porte SEULE ; elle n'a jamais eu le droit de deplacer celle qu'elle PARTAGE avec
			# une autre famille, parce que l'autre famille, elle, vit sur la grille des cases
			# et ne peut pas suivre. C'est la meme loi que « une frontiere partagee se coupe
			# sur la grille de cette famille », un cran plus loin : elle s'y coupe ET elle s'y
			# pose.
			#
			# ⚠ ET LA POSITION DE L'AXE A UNE SEULE SOURCE, `_corner_axis`. Elle a eu deux
			# copies pendant trois mesures -- une ici, une dans la fonction que lisent la
			# mesure et le raccord -- et la rangee de passage n'a ete ajoutee qu'a la seconde.
			# Le dessin ne pincait donc pas ou le raccord croyait qu'il pincait : quatre
			# extremites avant, quatre apres, DEUX FOIS, sans un pixel de difference. C'est la
			# faute que le depot repete a chaque page, et je l'ai commise dans le fichier qui
			# la denonce.
			var vx: int = corner_axis(y, true, quiet, freedom)
			var hy: int = corner_axis(x, false, quiet, freedom)
			# Les quadrants dans l'ordre des bits : NO, NE, SE, SO.
			var corner: int = 0
			if x > vx and y <= hy:
				corner = 1
			elif x > vx and y > hy:
				corner = 2
			elif x <= vx and y > hy:
				corner = 3
			line[x] = 1 if (index & CornerIndex.BITS[corner]) != 0 else 0
		solid.append(line)
	for y: int in range(RES):
		for x: int in range(RES):
			if solid[y][x] == 0:
				continue
			var edge: bool = false
			for side: int in range(4):
				# RIEN AU SUD des que le monde a des falaises : c'est le chapiteau qui trace.
				if side == 2 and level >= 2:
					continue
				# CONTRE DE LA ROCHE, LA TUILE A CHEVAL SE TAIT AUSSI -- par demi-frontiere.
				if side == 1 or side == 3:
					# ⚠ LA MOITIE SE COMPTE DEPUIS L'AXE PERPENDICULAIRE, PAS DEPUIS LE MILIEU
					# DE LA TUILE. Les deux axes SE DEPLACENT des F1 : les rangees 8 et 9 d'une
					# tuile dont le quadrant nord descend jusqu'a `hy = 9` appartiennent encore
					# au NORD, et se faisaient taire sur le bit du SUD.
					var half2: int = 1 if y < RES / 2 else 2
					if half_axis:
						half2 = 1 if y <= corner_axis(x, false, quiet, freedom) else 2
					if (quiet & half2) != 0:
						continue
				# ET SOUS UN PIED, ELLE SE TAIT AU NORD -- meme regle que `NORTH_QUIET` dans la
				# famille par case : le bas du pied et cette frontiere sont la meme, et c'est
				# le pied qui la porte.
				if side == 0:
					var half3: int = 4 if x < RES / 2 else 8
					if half_axis:
						half3 = 4 if x <= corner_axis(y, true, quiet, freedom) else 8
					if (quiet & half3) != 0:
						continue
				var probe: Vector2i = Vector2i(x, y) + STEPS[side]
				# ⚠ HORS DE LA TUILE N'EST JAMAIS UN BORD : la voisine y porte la meme case.
				if probe.x < 0 or probe.y < 0 or probe.x >= RES or probe.y >= RES:
					continue
				if solid[probe.y][probe.x] == 0:
					edge = true
			tile.set_pixel(x, y, OUTLINE if edge else GRASS)

	# ⚠ LE RENDEZ-VOUS AVEC LA CRETE -- L'AXE REVIENT SUR LA GRILLE DES CASES POUR PASSER LA
	# MAIN. Lu au pixel sur l'image assemblee, pas deduit : le trait vertical descend a
	# x = 97, la crete du chapiteau s'arrete a x = 95, et les deux ne se touchent pas. Ce sont
	# pourtant LES DEUX MOITIES DE LA MEME FRONTIERE du monde -- la tuile a cheval la porte
	# au-dessus de la levre, la robe en dessous -- et elles se donnent rendez-vous a deux
	# colonnes d'ecart.
	#
	# ⚠ ET LA COLONNE DU RENDEZ-VOUS N'EST PAS NEGOCIABLE : c'est celle ou vit le flanc de la
	# robe, la DERNIERE COLONNE DE LA CASE, soit `half - 1` en repere de tuile. A F0 l'axe y
	# est deja -- `_corner_shift` rend zero -- et c'est exactement pour ca que le temoin est
	# vert et que la faute n'existe qu'une fois l'axe deplace.
	#
	# ⚠ ET IL SE POSE A LA DERNIERE RANGEE VISIBLE, PAS LA OU LA MATIERE S'ARRETE. Les deux
	# rangees du dessous sont deja SOUS la robe, qui se pose par-dessus : un raccord pose la
	# est invisible, et c'est ce qui avait fait mesurer 354 au lieu de fermer.
	# ⚠ ET SEULEMENT S'IL Y A UN TRAIT A FERMER. Pose des que la moitie sud se tait, le raccord
	# court le long de la rangee juste AU-DESSUS de la crete et la DOUBLE : 482 paves 2x2, tous
	# a cheval sur le bord de case. La moitie nord de la frontiere verticale n'existe que si
	# exactement l'un des deux quadrants du haut est plein -- sinon il n'y a aucune frontiere,
	# donc rien a raccorder, et le raccord n'est plus qu'un second trait sur le bord du voisin.
	# ⚠ LE RENDEZ-VOUS : LA MARCHE QUE LE PINCAGE CREE, ET IL N'Y EN A QU'UN.
	#
	# Le pincage remet la moitie MUETTE sur le bord de case et laisse l'autre libre : entre les
	# deux, l'axe fait une marche, donc la matiere de la rangee `half - 1` surplombe le vide de
	# la rangee `half`. Ce surplomb est un vrai bord du dessin -- c'est la tuile qui l'a cree,
	# c'est a elle de le tracer -- et sans lui le trait vertical de la moitie libre n'a rien a
	# rejoindre.
	#
	# ⚠ ET LA MARCHE EST TOUJOURS A LA RANGEE `half - 1`, C'EST UN THEOREME. Le deplacement de
	# l'axe est SIGNE -- vers l'est, toujours -- donc la matiere de l'ouest est plus LARGE
	# au-dessus de la marche et celle de l'est plus ETROITE en dessous : dans les deux cas le
	# surplomb est au-dessus. On trace le bord de la matiere, jamais le vide.
	#
	# ⚠ ET IL SE LIT DANS LES PIXELS, PAS DANS LA SILHOUETTE. Trois conditions successives ont
	# ete essayees -- `north_split`, puis `south_split` pour le miroir -- et la seconde laissait
	# passer la forme 14, dont le pincage creuse un TROU de 3x3 au milieu de la tuile : ses deux
	# moities sud sont pleines, donc `south_split` est faux, et pourtant la marche est la. On
	# demande donc a la tuile ce qu'elle a peint : de la matiere ici, du vide juste dessous.
	# Mesure : 4 extremites sur le guide, 2 sur `@battue1`, toutes de cette espece.
	#
	# ⚠ ET IL S'ARRETE UNE COLONNE AVANT LE BORD DE CASE. Le chapiteau d'en dessous trace sa
	# crete AU RAS aux colonnes qui bordent la case -- `_wall_depth` s'y pince a zero -- et deux
	# traits rangee contre rangee font un pave. Le contact en diagonale avec le coin du
	# chapiteau suffit : 14 -> 10 paves sur `@battue1`, planche inchangee.
	var steps: bool = ((quiet & 1) != 0) != ((quiet & 2) != 0)
	if meet == "none":
		steps = false
	elif meet == "miroir":
		steps = steps and (quiet & 1) != 0
	elif meet == "orig":
		steps = steps and (quiet & 2) != 0
	if freedom > 0 and steps:
		var meet: int = half - 1
		# La moitie LIBRE est celle qui ne se tait pas ; c'est son ecart que la marche franchit.
		var free: int = half if (quiet & 1) != 0 else meet
		var axis: int = half - 1 + corner_shift(free, freedom, true)
		# ⚠ ET IL NE MARCHE PAS SUR LA CRETE. Quand le chapiteau d'en dessous est a l'EST, sa
		# crete est AU RAS sur ses premieres colonnes -- `_wall_depth` s'y pince jusqu'a
		# `depth(3, 0)` -- et la marche, une rangee plus haut, la longe : un pave par colonne.
		# Or ce ras-la donne deja le contact a l'axe : il n'y a rien a marcher. Quand le
		# chapiteau est a l'OUEST, sa crete ne couvre pas ces colonnes et la marche doit aller
		# jusqu'au bord de case pour toucher son coin en diagonale.
		var floor3: int = half + depth(3, 0, freedom) + 1 if (quiet & 16) != 0 else half
		for x3: int in range(mini(floor3, axis), maxi(floor3, axis) + 1):
			if tile.get_pixel(x3, meet).a >= 0.5 and tile.get_pixel(x3, meet + 1).a < 0.5:
				tile.set_pixel(x3, meet, OUTLINE)

	# ⚠ RACCORDER L'AXE DEPLACE AU BORD DE CASE : DEUX ESSAIS, DEUX FOIS PIRE.
	#
	# Le diagnostic tient et il est lu au pixel : « rien au sud » rend la frontiere horizontale
	# a la CRETE du chapiteau, qui est sur la grille des CASES, tandis que l'axe vertical se
	# deplace avec la liberte -- trait vertical a x=97, crete qui s'arrete a x=95, UN pixel de
	# trou, quarante-trois fois.
	#
	#   le petit bout horizontal a CHAQUE rangee ou la matiere s'arrete   43 -> 12 500
	#   le meme, a la SEULE rangee ou le trait vertical finit             43 ->    354
	#
	# ⚠ ET LE SECOND ECHOUE POUR UNE RAISON PRECISE, QUI EST LA CLE DU RESTE : la rangee ou la
	# MATIERE s'arrete est deja SOUS LA ROBE, donc invisible -- la robe se pose par-dessus. Le
	# dernier pixel VISIBLE du trait vertical est une rangee plus haut, au bord de case. Le
	# raccord doit donc se poser la, et pas ou la tuile croit finir. C'est la prochaine mesure.
	return tile


## LE DEPLACEMENT D'UN AXE, le long de lui-meme.
##
##   F0  zero : l'axe est au milieu, exactement.
##   F1  une constante GLOBALE. ⚠ Et elle ne peut pas etre par tuile, c'est un theoreme de la
##       famille : deux tuiles voisines se partagent les deux moities d'une meme frontiere, et
##       se rejoignent a leur bord commun. Un axe plat DEPLACE ne se rejoint que si toutes les
##       tuiles le deplacent pareil. La liberte laterale de F1 est donc GLOBALE ici, la ou elle
##       est par tuile dans la famille par case.
##   F2  la meme constante AUX DEUX BOUTS, libre entre les deux -- meme loi que partout.
static func corner_shift(along: int, freedom: int, vertical: bool) -> int:
	if freedom == 0:
		return 0
	# ⚠ ET LE MEME DEPLACEMENT POUR LES DEUX AXES. Deux valeurs differentes font deux profils
	# plats la ou la liberte n'en promet qu'un -- et I5 le disait.
	var shift: int = 2
	if freedom == 1:
		return shift
	var seed: int = absi((3 if vertical else 5) * 19349663)
	var reach: float = float(1 + seed % 3)
	var t: float = float(along) / float(RES - 1)
	return shift + int(round(reach * sin(PI * t)))




## LES COTES OUVERTS D'UNE ROBE : la CRETE en haut du chapiteau, le PIED en bas de la derniere
## rangee, et les flancs qui S'ARRETENT. Partout ailleurs la roche continue chez la voisine.
##
## ⚠ ET LE BAS DU PIED RESTE, APRES L'AVOIR RETIRE ET MESURE. Le raisonnement etait symetrique
## de celui de la levre : un pied ATTERRIT toujours, la case d'atterrissage a forcement son nord
## vide, donc le bas du pied et ce bord nord sont la meme frontiere et la surface pourrait la
## porter seule. Essaye : 12 doublements de moins, mais 128 EXTREMITES DE PLUS -- le bas du pied
## est ce qui referme le contour de la falaise a sa base, et sans lui les deux flancs s'arretent
## dans le vide.
static func wall_open(key: Variant) -> Array[bool]:
	var role: Vector2i = Vector2i.ZERO
	var give: int = 0
	if j2_on_face:
		var wide: Vector3i = key as Vector3i
		role = Vector2i(wide.x, wide.y)
		give = wide.z
	else:
		role = key as Vector2i
	# ⚠ L'ISSUE A DE LA JONCTION LATERALE : LA FACE CEDE SES FLANCS. Si la tuile a cheval les
	# trace de toute facon -- son axe tombe exactement sur le bord de case -- alors le flanc
	# d'une robe est un second traceur, et c'est lui qu'on peut retirer. Le PAN ne sert plus a
	# rien : les vingt roles tombent aux cinq rangees. On mesure si ca ferme.
	# LE TRANSFERT DE LA CRETE : quand la surface prend son sud, le chapiteau se tait.
	# ⚠ ET LE TRANSFERT NE VAUT QUE POUR LA FAMILLE PAR CASE. A cheval, une tuile de surface
	# est posee sur le CROISEMENT de quatre cases : elle chevauche la levre ET sa face, donc
	# le bandeau tomberait en son milieu. Le chapiteau y garde sa crete tant que la famille
	# duale n'a pas sa propre reponse -- et `compose()` ne sert de toute facon que la famille
	# par case, celle que le logiciel livre.
	var crown: bool = role.y == Walls.ROW_CROWN 			and not (Brink.crest_on_surface and level < 5)
	# ⚠ ET LES FLANCS SE TAISENT AVEC LA CRETE, POUR LA MEME RAISON. La jonction laterale est
	# le miroir de la verticale : tant que c'est la FACE qui trace son flanc, elle doit etre
	# plate partout ou le bord perpendiculaire de la surface peut arriver -- entre 4 et 7.
	# Rendue a la surface, qui SAIT ou est son propre trait, la face n'a plus rien a deviner.
	# ⚠ ET LES FLANCS NE SE TAISENT PAS : la surface n'a pas de lisere lateral a peindre, donc
	# personne d'autre ne peut tracer cette frontiere. Route joignable, gardee pour le chiffre.
	var mute_sides: bool = Brink.crest_on_surface and level < 5 			and OS.get_environment("LADDER_SIDES") == "surface"
	if astride == "face":
		return [crown, false,
				role.y == Walls.ROW_FOOT and (give & 4) == 0, false]
	return [crown,
			Walls.pan_east(role.x) == Walls.SIDE_STOP and (give & 2) == 0 and not mute_sides,
			role.y == Walls.ROW_FOOT and (give & 4) == 0,
			Walls.pan_west(role.x) == Walls.SIDE_STOP and (give & 1) == 0 and not mute_sides]


## LA FABRIQUE : la matiere que les quatre profils laissent, puis son bord.
##
## ⚠ LE TRAIT SE DEDUIT DE LA MATIERE, IL NE SE TRACE PAS A PART. Trace a part, il faut le
## decouper a la main partout ou deux cotes se rencontrent -- et c'est exactement la qu'il
## depassait, en ergot, a chaque coin saillant. Deduit, il epouse la matiere par construction.
## Tout ce qu'il faut savoir en plus est LOCAL : au-dela d'un cote ouvert il n'y a rien, au-dela
## d'un cote ferme la matiere continue chez la voisine.
## ⚠ ET LE BORD LATERAL NE SE PINCE PAS AU SUD, ESSAYE ET MESURE. L'idee : a L2 le sud d'une
## surface est toujours une LEVRE, et son bord lateral meurt a son bas faute de retrouver la
## crete du chapiteau ; en le ramenant au ras a son dernier pixel il toucherait au moins le coin
## de la case. Resultat : 222 extremites -> 848, et 61 paves. La loi de la traversee ne se plie
## pas -- un bord lateral doit franchir la frontiere horizontale a la profondeur COMMUNE, et le
## pincer d'un cote le brouille avec la case du dessus comme avec celle du dessous.
## ⚠ ET LE NORD D'UNE SURFACE NE SE MET PAS AU RAS, ESSAYE ET MESURE : 43 -> 65 extremites, et
## 94 paves la ou il n'y en avait aucun. Le raisonnement etait celui de la crete -- mon sol
## occupe ma case entiere, le sol plus bas occupe la sienne, la frontiere est le bord -- et il
## est FAUX ici. La difference : sous une crete il y a une FACE, qui occupe sa case et dont le
## haut EST le bord ; au nord il n'y a qu'un sol plus bas, dont le bord a lui est libre, et
## mettre le mien au ras l'empeche de le retrouver.
##
## Le parametre reste, inutilise, comme trace de la mesure.
## La profondeur d'un bord LATERAL, qui tombe a zero a son premier pixel quand la case du
## dessus s'est tue de ce cote : la frontiere y est portee par le flanc d'une robe, une case
## plus haut et une colonne plus loin, et il faut aller le toucher au coin.
## LA PROFONDEUR D'UN BORD NORD, qui remonte au ras a son bout quand la case d'a cote s'est tue
## au nord -- c'est le bas d'un PIED qui y porte la frontiere, au ras du bord de sa case.
static func north_depth(along: int, freedom: int, quiet: int, seam: int) -> int:
	if along == RES - 1 and (quiet & NORTH_FLUSH_EAST) != 0:
		return 0
	if along == 0 and (quiet & NORTH_FLUSH_WEST) != 0:
		return 0
	return depth(0, along, freedom, seam)


static func side_depth(side: int, along: int, freedom: int, quiet: int, seam: int = 0) -> int:
	if along == 0:
		if side == 1 and (quiet & ABOVE_QUIET_EAST) != 0:
			return 0
		if side == 3 and (quiet & ABOVE_QUIET_WEST) != 0:
			return 0
	if along == RES - 1:
		if side == 1 and (quiet & BELOW_QUIET_EAST) != 0:
			return 0
		if side == 3 and (quiet & BELOW_QUIET_WEST) != 0:
			return 0
	return depth(side, along, freedom, seam)


## LE PINCEMENT AUX DEUX TRAVERSEES : la loi du moindre ras.
##
## ⚠ ON NE MET AU RAS QUE CE QU'ON NE PEUT PAS LAISSER LIBRE. Le theoreme n'oblige pas une face
## a etre plate : deux lignes perpendiculaires qui vivent dans des tuiles DIFFERENTES ne peuvent
## se rejoindre qu'a leur frontiere commune, donc l'une doit toucher le bord AU POINT ou l'autre
## le traverse -- et rien de plus.
##
## Un bord de face touche donc le bord de sa case aux DEUX traversees canoniques de la famille
## perpendiculaire, et serpente entre les deux. Les traversees sont globales, donc connues de
## toutes les tuiles sans rien savoir du voisinage.
##
## Premiere formulation, trop forte : « les bords d'une face sont les bords de sa case ». Elle
## fermait bien (222 -> 43) mais confisquait toute la liberte du dessin de falaise.
static func wall_depth(side: int, along: int, freedom: int, seam: int = 0) -> int:
	if freedom == 0:
		return 0
	var first: int = 0
	var last: int = 0
	if side == 0 or side == 2:
		first = depth(3, 0, freedom)
		last = RES - 1 - depth(1, 0, freedom)
	else:
		first = depth(0, 0, freedom)
		last = RES - 1 - depth(2, 0, freedom)
	# ⚠ ET RESSERRER LE PINCEMENT A CHEVAL EST REFUTE, MESURE. Les traversees ci-dessus sont
	# celles de la famille PAR CASE -- `depth(3, 0)` vaut 4 -- qui n'existe pas a L5 : la crete
	# s'y retrouve plate sur cinq colonnes, exactement celles ou le rendez-vous d'une tuile a
	# cheval pose sa marche, d'ou dix paves. Reduit aux deux colonnes du bord -- le minimum qui
	# fasse se rejoindre deux cretes voisines -- `@battue1` passe de 0 extremite et 10 paves a
	# **25 extremites et 8 paves** : le plat de la crete est ce sur quoi retombent les bords
	# lateraux des tuiles a cheval, et il en porte bien plus qu'une marche.
	# ⚠ ET LE PINCEMENT SE FAIT A ZERO, ESSAYE AUTREMENT ET MESURE. Pincer a la profondeur
	# canonique -- pour que la face retrouve la surface -- fait sauter le contour a 186
	# extremites : la face y perd le contact avec les perpendiculaires DE SA PROPRE FAMILLE,
	# qui se rejoignent au coin de la case. Chaque famille a sa traversee ; c'est LEUR
	# rencontre qui doit se regler, pas l'une des deux qui doit ceder.
	if last <= first:
		return 0
	var seed: int = absi((side + 1 + 7 * seam) * 19349663)
	# ⚠ L'AMPLITUDE EST LE SEUL AXE DE LIBERTE QUI RESTE A LA FACE, une fois le ras des
	# intervalles demontre. Elle vaut `WALL_REACH` au plus ; le banc la fait varier par
	# `LADDER_WALLREACH` pour qu'on puisse dire ou elle casse, et pourquoi.
	var reach: float = float(1 + seed % maxi(1, wall_reach))
	# ⚠ « AUX DEUX TRAVERSEES » NE VEUT PAS DIRE « DEUX POINTS » -- ESSAYE, MESURE, REFUSE.
	# La loi du moindre ras exige qu'on demontre le ras avant de le poser : le theoreme parle
	# de deux traversees, et le code aplatit deux INTERVALLES entiers, soit dix pixels de bord
	# sur seize. Rendre la liberte partout sauf aux quatre points (les deux coins, les deux
	# traversees) fait passer le ras de 56 % a 28 % -- et casse l'echelle : 13 a 35 extremites
	# et jusqu'a 555 paves, sur trois mondes.
	#
	# ⚠ ET LES COORDONNEES DISENT POURQUOI, ce qui vaut mieux que le compte. Elles tombent aux
	# COINS (0,0 · 15,0 · 0,15 · 15,15) et aux TRAVERSEES (4,15 · 12,15 · 0,4), et les tuiles
	# nommees sont des SURFACES : ce qui casse est la jonction face-surface. Le bord d'une
	# surface arrive n'importe ou dans `[4, 7]` selon SA propre liberte -- il serpente -- donc
	# la face doit etre plate sur TOUT l'intervalle ou une perpendiculaire peut se presenter,
	# pas au seul point canonique. « Collees au bord » est donc un theoreme, pas un accident.
	#
	# La route refusee reste joignable par `LADDER_WALLFREE=points`.
	# ⚠ LA LIBERTE DE LA FACE SE DEDUIT DE CELLE DE LA SURFACE -- proposition utilisateur, et
	# elle nomme ce qui manquait. Le bord d'une surface n'arrive pas « n'importe ou » a une
	# frontiere partagee : il y arrive A LA TRAVERSEE CANONIQUE, qui est une CONSTANTE du
	# modele. Ce que la face ignorait n'etait donc pas ou la surface arrive, mais ou son
	# PROPRE autre bord est passe -- les deux tirant des amplitudes differentes.
	#
	# ⚠ ET « ZERO EST LA SEULE PROFONDEUR QUE LES DEUX SAVENT SANS SE PARLER » ETAIT FAUX. Ils
	# savent aussi une CONSTANTE : au coin, les deux bords d'une face se posent a
	# `wall_corner` et s'y rejoignent en (c, c) -- exactement comme deux bords de surface se
	# rejoignent en (4, 4). Route `LADDER_WALLCORNER=n`.
	# ⚠ LA DERIVATION : les points imposes viennent du MODELE, pas d'ici. `core/border_rules.gd`
	# les calcule depuis la seule chose que la face puisse savoir de ses voisines -- la
	# traversee canonique des surfaces, qui est une constante. Ce fichier ne fait plus que
	# remplir ce qui reste libre.
	if BorderRules.CORNER > 0:
		var imposed: Dictionary = BorderRules.imposed(RES, first)
		if imposed.has(along):
			return int(imposed[along])
		# LA LIBERTE RESIDUELLE : entre deux points imposes, on interpole et on bombe.
		var before: int = along
		var after: int = along
		while before > 0 and not imposed.has(before):
			before -= 1
		while after < RES - 1 and not imposed.has(after):
			after += 1
		var lo: float = float(imposed.get(before, 0))
		var hi: float = float(imposed.get(after, 0))
		var t: float = float(along - before) / float(maxi(1, after - before))
		var swell: float = reach * sin(PI * t) if after - before > 2 else 0.0
		return int(round(lo + (hi - lo) * t + swell))
	# ⚠ L'EXPERIENCE ISOLEE : ne bouger QUE la valeur aux deux bouts. La question posee est
	# « le bout d'un flanc doit-il valoir zero ? » -- et elle ne se repond que si on ne touche
	# a rien d'autre : ni la longueur du plat, ni la profondeur de rencontre. Mon premier essai
	# changeait les trois a la fois, donc il ne repondait a rien.
	#
	# La rampe descend de `wall_end` au bout jusqu'a ZERO a la traversee, ou le T arrive.
	if BorderRules.CORNER > 0 and wall_free != "points":
		if along < first:
			return int(round(float(BorderRules.CORNER) * float(first - along) / float(first)))
		if along > last:
			return int(round(float(BorderRules.CORNER) * float(along - last)
					/ float(RES - 1 - last)))
		return int(round(reach * sin(PI * float(along - first) / float(last - first))))
	if wall_free != "points":
		if along <= first or along >= last:
			return 0
		return int(round(reach * sin(PI * float(along - first) / float(last - first))))
	if along == 0 or along == RES - 1 or along == first or along == last:
		return 0
	var lo: int = first
	var hi: int = last
	if along < first:
		lo = 0
		hi = first
	elif along > last:
		lo = last
		hi = RES - 1
	if hi <= lo:
		return 0
	return int(round(reach * sin(PI * float(along - lo) / float(hi - lo))))


## `lip` : LA TUILE DE SURFACE PORTE LE HAUT DE SA PROPRE FACE.
##
## ⚠ ET SA MATIERE N'EST PAS COUPEE AU SUD, ELLE CHANGE DE MATIERE. C'est toute la difference
## avec « rendre le sud », essaye et refute : la ou celui-la ouvrait le bord -- donc coupait la
## matiere et laissait un trou entre la surface et la roche d'en dessous, 6 263 pixels vus a
## travers la transparence -- ici la tuile continue en ROCHE jusqu'a son bord bas, et c'est la
## frontiere HERBE/ROCHE, a l'interieur de la tuile, qui porte le trait.
##
## La licence est un theoreme du dossier : une case dont le sud est vide est une LEVRE, sa face
## couvre la case d'en dessous TOUJOURS. Constant, donc peignable dans la tuile -- mot pour mot
## l'argument de l'epaule.
##
## ⚠ ET LE CHAPITEAU SE TAIT ALORS, sinon deux traits pour une frontiere. C'est un ECHANGE.
static func shape(open: Array[bool], freedom: int, body: Color, index: int,
		quiet: int = 0, flat_north: bool = false, wall: bool = false,
		seams: Array[int] = [], bands: int = 0, alone: int = 0) -> Image:
	while seams.size() < 4:
		seams.append(0)
	var tile: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	# LA RANGEE LA PLUS HAUTE QUE LE BANDEAU DE LEVRE ATTEIGNE.
	# LES TROIS BANDEAUX D'UNE SURFACE, ET C'EST LA MEME IDEE TROIS FOIS : la tuile porte le
	# morceau de face qui la borde, la ou le modele garantit qu'il y en a un.
	#   bit 0 -- au SUD  : je suis une LEVRE, ma face est dessous, TOUJOURS (theoreme).
	#   bit 1 -- a l'EST : le bit `bord` dit qu'une robe couvre ma voisine de l'est.
	#   bit 2 -- a l'OUEST : idem.
	# ⚠ ET LES DEUX LATERAUX SONT AUSSI CONSTANTS QUE LE SUD, mais pour une autre raison : le
	# sud l'est par theoreme, les cotes le sont PARCE QU'UN BIT LE DIT. La cle porte
	# l'information, donc la tuile a le droit de la peindre.
	var lip: bool = (bands & 1) != 0
	var band: int = 0
	if lip:
		for x0: int in range(RES):
			band = maxi(band, depth(2, x0, freedom, seams[2]))
	var solid: Array[PackedByteArray] = []
	for y: int in range(RES):
		var line: PackedByteArray = PackedByteArray()
		line.resize(RES)
		for x: int in range(RES):
			var inside: bool = true
			if open[0] and y < (wall_depth(0, x, freedom, seams[0]) if wall
					else (0 if flat_north else north_depth(x, freedom, quiet, seams[0]))):
				inside = false
			# ⚠ LE BANDEAU DE ROCHE APPARTIENT A LA FACE, DONC IL SUIT SES REGLES DE BORD.
			# Coupe a la profondeur d'une SURFACE (4 a 7) alors que la face juste dessous
			# coupe a la sienne (pincee a zero au coin), il ne la rejoint pas au bord de
			# case : 202 extremites, toutes a cette jonction. La profondeur se lit donc en
			# distance au BAS de la tuile, pour valoir zero la ou la face commence.
			# ⚠ ET C'EST LA RANGEE QUI DECIDE, PAS LA COLONNE. Le bandeau varie par COLONNE
			# -- 2 ou 3 de profondeur -- et la coupe laterale par RANGEE : entrelaces, ils
			# laissent un ILOT de roche de deux pixels, detache, donc cerne de tous cotes,
			# donc epais. Mesure : 4 paves, et trois hypotheses fausses avant de regarder
			# les pixels. La coupe s'arrete donc a la rangee la plus HAUTE que le bandeau
			# atteigne, et le bandeau ne decide plus que de la matiere.
			var stony: bool = lip and y > RES - 1 - band
			if open[1] and not stony and x > RES - 1 - (wall_depth(1, y, freedom, seams[1])
					if wall else side_depth(1, y, freedom, quiet, seams[1])):
				inside = false
			if open[2] and y > RES - 1 - (wall_depth(2, x, freedom, seams[2]) if wall
					else depth(2, x, freedom, seams[2])):
				inside = false
			if open[3] and not stony and x < (wall_depth(3, y, freedom, seams[3]) if wall
					else side_depth(3, y, freedom, quiet, seams[3])):
				inside = false
			line[x] = 1 if inside else 0
		solid.append(line)

	# ⚠ ET LA MATIERE N'A PAS D'AIGUILLE. La ou deux courbes libres se rencontrent -- un coin
	# saillant dont les deux cotes serpentent -- il reste parfois une pointe d'un seul pixel,
	# accrochee par un coin ; son trait n'a alors qu'UN voisin, donc c'est une extremite. C'est
	# la regle d'epaisseur d'un cran plus bas. La tuile se relit elle-meme et la retire.
	var needled: bool = true
	while needled:
		needled = false
		for y: int in range(RES):
			for x: int in range(RES):
				if solid[y][x] == 0:
					continue
				var kin: int = 0
				for side: int in range(4):
					var near: Vector2i = Vector2i(x, y) + STEPS[side]
					if near.x < 0 or near.y < 0 or near.x >= RES or near.y >= RES:
						if not open[side]:
							kin += 1
						continue
					if solid[near.y][near.x] != 0:
						kin += 1
				if kin >= 2:
					continue
				var line2: PackedByteArray = solid[y]
				line2[x] = 0
				solid[y] = line2
				needled = true

	# LA ROCHE DE LA LEVRE : sous le profil sud, la face qui continue. Elle ne coupe rien --
	# elle change la MATIERE, et c'est leur frontiere qui portera le trait.
	var stone: Array[PackedByteArray] = []
	for y: int in range(RES):
		var strip: PackedByteArray = PackedByteArray()
		strip.resize(RES)
		# ⚠ ET IL N'Y A PAS DE BANDEAU LATERAL, ESSAYE ET REFUSE -- pour une raison de
		# PROJECTION, pas de technique. Le bandeau sud existe parce que la vue est de trois
		# quarts : le bord sud d'un plateau montre un liseré de SA PROPRE FACE, et c'est
		# l'argument meme de l'epaule. Lateralement il n'y a aucun lisere -- la face est de
		# l'autre cote de la frontiere, dans la case voisine. En peindre serait de la matiere
		# INVENTEE. Mesure : 149 / 226 / 395 extremites, toutes aux coins de tuile.
		#
		# Consequence, et elle ferme la question : la jonction laterale NE SE TRANSFERE PAS.
		# La face garde son flanc, donc elle reste plate la ou le bord perpendiculaire de la
		# surface peut se presenter. Ce ras-la n'est pas une decision qui manque, c'est la
		# geometrie de la vue.
		if lip:
			for x: int in range(RES):
				strip[x] = 1 if y > RES - 1 - depth(2, x, freedom, seams[2]) else 0
		stone.append(strip)

	for y: int in range(RES):
		for x: int in range(RES):
			if solid[y][x] == 0:
				continue
			var edge: bool = false
			for side: int in range(4):
				var probe: Vector2i = Vector2i(x, y) + STEPS[side]
				if probe.x < 0 or probe.y < 0 or probe.x >= RES or probe.y >= RES:
					if open[side]:
						edge = true
					# ⚠ SOUS UNE LEVRE, CE QUI EST EN DESSOUS DE LA TUILE **EST** LA FACE.
					# C'est un theoreme du dossier -- « une case dont le sud est vide est une
					# levre, sa propre face couvre la case d'en dessous, TOUJOURS » -- et
					# c'est lui qui rend la regle uniforme a toutes les libertes. A F0 le
					# bandeau a une profondeur NULLE : l'herbe touche donc la face, et son
					# trait tombe sur la rangee du bas. A F1 et F2 le bandeau est la, la
					# roche continue chez la robe, et rien ne se trace. Une seule regle, pas
					# deux -- sans quoi F0, qui est le TEMOIN, n'aurait plus de dessin.
					elif lip and side == 2 and stone[y][x] == 0:
						edge = true
					continue
				if solid[probe.y][probe.x] == 0:
					edge = true
				# ⚠ ET UN CHANGEMENT DE MATIERE EST UN BORD -- MAIS D'UN SEUL COTE. Trace des
				# deux, il fait deux pixels d'epaisseur : 5 734 paves, mesure. C'est la meme
				# regle que pour la matiere et le vide, ou seul le PLEIN porte le trait ; ici
				# c'est l'HERBE qui le porte, et la roche reste nette pour continuer chez la
				# robe d'en dessous sans un pixel de plus.
				# ⚠ ET ELLE EST HORIZONTALE PAR NATURE : c'est le HAUT de la face. Tracee
				# aussi lateralement -- la ou sa profondeur change d'une colonne a
				# l'autre -- elle double le trait du bord : 4 paves, mesures. La marche
				# d'une colonne a la suivante est portee par le pixel du DESSUS, comme
				# toute marche d'un trait horizontal.
				elif side != 1 and side != 3 and stone[probe.y][probe.x] != 0 						and stone[y][x] == 0:
					edge = true
			# LE TRAIT AU BORD DE CASE, SANS COUPER LA MATIERE. Deux usages, une mecanique :
			# la LEVRE SEULE (ma roche touche l'herbe de ma voisine) et l'ARETE INTERNE (ma
			# face avance sur celle d'a cote). Dans les deux cas c'est moi qui trace : ma
			# voisine ne sait rien de moi.
			# ⚠ ET LA MARQUE SE POSE A LA PROFONDEUR DU COIN, PAS AU RAS. C'est elle qui
			# continue le flanc de la face d'en dessous : a une autre profondeur, le trait
			# sauterait d'un cran a la frontiere entre les deux tuiles.
			var mark: int = BorderRules.lip_side_depth()
			if stone[y][x] != 0 or wall:
				if x == RES - 1 - mark and (alone & 1) != 0:
					edge = true
				if x == mark and (alone & 2) != 0:
					edge = true
			tile.set_pixel(x, y, OUTLINE if edge
					else (ROCK if stone[y][x] != 0 else body))
	if freedom > 0 and index >= 0:
		reentrant(tile, index, freedom, quiet, level)
	return tile


## LES COINS RENTRANTS : la marche que personne d'autre ne peut tracer.
##
## ⚠ ET C'EST LA SEULE CHOSE QUE F1 AJOUTE AU DESSIN. Quand le trait rentre, deux cases
## voisines dont les bords ne rentrent pas pareil laissent une MARCHE a leur frontiere. La
## marche est du cote de celle qui a de la matiere -- l'autre n'a que du fond a cet endroit,
## et on ne trace pas dans le vide. Cette case-la se reconnait a une signature, et une seule :
## ses DEUX cardinaux du coin sont pleins et sa DIAGONALE est vide.
##
## ⚠ C'EST EXACTEMENT LE BIT QUE LA CANONICALISATION JETTE. « Un coin diagonal isole ne change
## pas la silhouette de la tuile » -- vrai du remplissage, faux du trait : c'est la, et
## seulement la, que le bord fait une marche. F1 se paie donc en voisinages bruts.
##
## ⚠ ET UNE SEULE DES DEUX CASES TRACE. La voisine d'en face, elle, a son cardinal ouvert et
## n'a pas de matiere a cet endroit : si elle tracait aussi, les deux traits seraient colles
## de part et d'autre de la frontiere -- un pave 2x2, I2 rouge. Ils se rejoignent en diagonale,
## ce qui suffit a fermer.
static func reentrant(tile: Image, index: int, freedom: int, quiet: int = 0,
		level: int = 0) -> void:
	for corner: int in range(4):
		var a: int = corner                 # N, E, S, O
		var b: int = (corner + 3) % 4       # le cote precedent : NO, NE, SE, SO
		if (index & CARDINALS[a]) == 0 or (index & CARDINALS[b]) == 0:
			continue
		if (index & DIAGONALS[corner]) != 0:
			continue
		# ⚠ PAR LA DIAGONALE : un seul bit gouverne les deux ergots du coin. De la roche a ma
		# diagonale veut dire que la voisine s'est tue de ce cote -- pour l'une comme pour
		# l'autre, puisque c'est la MEME face qui les longe.
		if ergot_diag:
			# La levre couvre toujours une diagonale sud : les deux ergots de ce coin sont
			# muets sans qu'aucun bit n'ait a le dire.
			if corner >= 2 and level >= 2:
				continue
			if (quiet & (4 << corner)) == 0:
				if not (b == 2 and level >= 2):
					stub(tile, a, b, depth(b, 0, freedom))
				if not (a == 2 and level >= 2):
					stub(tile, b, a, depth(a, 0, freedom))
			continue
		# ⚠ LE PARTENAIRE AU SUD NE TRACE JAMAIS DES L2 : l'ergot qui comptait sur lui pend,
		# toujours. Le dessin le sait sans qu'on le lui dise -- c'est une constante du niveau,
		# pas un fait du voisinage.
		if (quiet & (4 << corner)) == 0 and not (b == 2 and level >= 2):
			stub(tile, a, b, depth(b, 0, freedom))
		if (quiet & (64 << corner)) == 0 and not (a == 2 and level >= 2):
			stub(tile, b, a, depth(a, 0, freedom))


## Un bout de trait le long du bord `along`, depuis le coin qu'il partage avec `from`.
static func stub(tile: Image, along: int, from: int, length: int) -> void:
	for i: int in range(length):
		var far: bool = from == 1 or from == 2
		var offset: int = RES - 1 - i if far else i
		match along:
			0: tile.set_pixel(offset, 0, OUTLINE)
			1: tile.set_pixel(RES - 1, offset, OUTLINE)
			2: tile.set_pixel(offset, RES - 1, OUTLINE)
			_: tile.set_pixel(0, offset, OUTLINE)


## LA PROFONDEUR DU TRAIT, le long d'un cote.
##
##   F0  zero partout : le trait est au ras du bord.
##   F1  une constante PAR COTE : le trait rentre, mais droit -- et commune, sinon il saute a
##       chaque changement d'index le long d'un meme bord (mesure : 168 morceaux pour 42
##       massifs, exactement quatre par massif).
##   F2  cette meme constante AUX DEUX BOUTS, libre entre les deux.
##
## ⚠ ET LA TRAVERSEE RESTE COMMUNE A F2 : C'EST LA SEULE CHOSE QUI NE SE NEGOCIE PAS. Deux
## tuiles qui se suivent le long d'un bord se retrouvent a leur frontiere ; si elles n'y
## arrivent pas a la meme profondeur, le trait se rompt. Entre ces deux points la ligne fait
## ce qu'elle veut -- c'est ca, la liberte de F2, et elle est entiere.
## ⚠ LA GRAINE CHANGE LE VENTRE, JAMAIS LA TRAVERSEE. Les deux bouts d'un bord valent la
## traversee canonique de sa famille, et c'est ce qui le fait rencontrer son voisin colineaire
## a la frontiere commune, quelle que soit sa classe. Ce qui reste libre est ce qu'il y a entre
## les deux -- et c'est ca que la classe fait varier.
static func depth(side: int, along: int, freedom: int, seam: int = 0) -> int:
	if freedom == 0:
		return 0
	# ⚠ ET LA TRAVERSEE VAUT AU MOINS DEUX. L'ergot de coin rentrant se pose au RAS du bord --
	# il marque une marche sur un cote dont le cardinal est plein, il n'a nulle part ailleurs ou
	# aller. Si un bord traverse a la profondeur UN, les deux traits sont voisins d'un pixel et
	# forment un pave : deux terrasses collees, l'une par son ergot, l'autre par son bord.
	# Invisible a L0, ou les deux ne se rencontrent jamais dans la meme case ; flagrant des que
	# les etages s'empilent -- 5 paves a L1/F1, 12 a L1/F2.
	# ⚠ ET LA TRAVERSEE VAUT AU MOINS DEUX, essaye a zero et mesure. Au ras, la surface
	# retrouverait la face -- qui pince a zero -- mais elle perd ses propres ergots, poses au
	# bord : 57 paves a L2/F1. Chaque famille garde donc sa traversee.
	# ⚠ LA TRAVERSEE EST UN CHOIX D'ARTISTE, PAS UNE REGLE -- et c'est la formulation juste.
	# Le modele n'impose aucune valeur : il impose une COHERENCE, parce que toutes les lignes
	# d'une meme famille sont des morceaux d'une seule frontiere vus dans des tuiles
	# differentes. Le 4 de notre dessin est le choix que NOTRE dessin a fait. `LADDER_CROSSING`
	# le force ailleurs, pour mesurer si le reste en depend.
	var crossing: int = forced_crossing if forced_crossing > 0 			else 2 + absi((side + 1) * 19349663) % 3
	if freedom == 1:
		return crossing
	# ⚠ LA FORME D'UN BORD NE DEPEND QUE DE CE BORD-LA, jamais de la tuile qui le porte. Deux
	# silhouettes d'etages differents peuvent s'arreter au MEME endroit -- c'est la « pile »,
	# jusqu'a trois sur la planche -- et chacune y trace son bord. Si elles serpentent
	# differemment, le meme trait se dedouble : deux courbes qui se croisent et s'ecartent, et
	# la ou elles passent a un pixel l'une de l'autre, un pave. Mesure : 6 a L1/F2, tous dans
	# une seule case, invisibles a F0 et F1 ou les bords sont droits donc confondus.
	#
	# Tirees du seul cote, les deux courbes sont la MEME : elles se superposent au pixel pres,
	# et il ne reste qu'un trait. C'est la loi deja ecrite au dossier pour les falaises.
	#
	# ⚠ Et tiree, pas au hasard : deux executions doivent donner la meme image, sans quoi le
	# banc ne dit plus si un correctif a servi.
	var seed: int = absi((side + 1 + 7 * seam) * 19349663)
	var reach: float = float(1 + seed % 3)
	var skew: float = 0.7 + 0.6 * float(seed % 101) / 100.0
	var t: float = float(along) / float(RES - 1)
	return crossing + int(round(reach * sin(PI * pow(t, skew))))


## ⚠ ET IL NE MESURE QUE L'AXE QUE LA TUILE POSSEDE. La moitie qui passe la main a une robe
## est POSEE PAR LE MODELE, sur la grille des cases : sa position n'est pas un choix du
## peintre, donc la compter dans la liberte accuse le dessin d'obeir a la regle. C'est le
## meme traitement que les classes de raccord a L4, qui imposent des pixels sans que I5 les
## reproche -- « les raccords rendent de la liberte au lieu d'en prendre ».
##
## ⚠ ET LE GARDE-FOU RESTE ENTIER : la moitie que la tuile possede, elle, doit toujours etre
## UN profil plat et DEPLACE. Un dessin qui figerait sa liberte au milieu ferait rougir I5
## exactement comme avant -- on n'a retire de la mesure que ce que le peintre ne choisit pas.
## L'axe PERPENDICULAIRE, a la ligne demandee -- la meme formule que dans `_corner_tile`,
## pincage compris.
static func corner_axis(at: int, vertical: bool, quiet: int, freedom: int) -> int:
	var half: int = RES / 2
	var mute: int = (1 if at < half else 2) if vertical else (4 if at < half else 8)
	if (quiet & mute) != 0:
		return half - 1
	return half - 1 + corner_shift(at, freedom, vertical)
