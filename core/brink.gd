# LES BITS DE BORD -- ce qu'une tuile de surface doit savoir de son voisinage.
#
# ⚠ C'EST DU MODELE, PAS DU DESSIN, et la difference porte le fichier. Une silhouette dit ce
# qu'il y a AUTOUR de la case ; un bit de bord dit ce que la voisine a decide d'en TRACER. Les
# deux ensemble font la cle d'une tuile -- et c'est la cle, pas la silhouette, qui designe une
# case de planche.
#
# ⚠ ET LE FIL EST TOUJOURS LE MEME : QUI TRACE ? Chaque bit repond a cette question a un endroit
# ou deux tuiles pourraient revendiquer la meme frontiere du monde. Le detail de chaque reponse,
# et le prix qu'elle a coute en tuiles, est au dossier -- `PLAN.md`.
#
# ⚠ ILS SORTENT DU BANC, ET C'EST LE SENS DU PORTAGE. `proof/ladder.gd` les a etablis cran par
# cran ; tant qu'ils y restaient, le LOGICIEL n'en avait rien. Ici, `core/` les porte, `render/`
# les lit pour dessiner, et le banc les lit pour mesurer : une seule source.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Coverage := preload("res://core/coverage.gd")


## LES BITS DU BORD, au-dessus des huit de silhouette.
##
## ⚠ ET ILS DOIVENT ETRE DISJOINTS DE CEUX DE L'ERGOT : `4 << coin` couvre 4, 8, 16, 32 et
## `64 << coin` couvre 64 a 512. Le nord valait 8 -- exactement le bit du coin 1 de l'ergot.
## Collision silencieuse, trouvee en cherchant ou loger les suivants.
const NORTH_QUIET: int = 1024        ## une face me couvre au nord : c'est le PIED qui trace


const ABOVE_QUIET_EAST: int = 2048   ## la case du dessus s'est tue a l'est


const ABOVE_QUIET_WEST: int = 4096   ## la case du dessus s'est tue a l'ouest


## ⚠ ET LE SYMETRIQUE : MON BORD NORD MEURT A SON EST QUAND LA CASE D'A COTE S'EST TUE AU NORD.
## Elle s'est tue parce qu'un PIED la couvre : la frontiere y est donc portee par le bas de ce
## pied, AU RAS du bord de sa case -- une rangee au-dessus de la mienne. Mon bord nord, lui, la
## trace a sa traversee, quatre pixels plus bas. Les deux decrivent la meme frontiere
## horizontale a deux hauteurs differentes, et elles ne se rejoignent pas au coin.
## Mon bord remonte donc au ras a ce bout-la, pour aller toucher le pied en diagonale.
const NORTH_FLUSH_EAST: int = 8192


const NORTH_FLUSH_WEST: int = 16384


## ⚠ ET LE SYMETRIQUE EXACT D'`ABOVE_QUIET_*`, VERS LE BAS. Celui-la fait mourir mon bord
## lateral a son NORD quand la case du dessus s'est tue de ce cote ; celui-ci le fait mourir a
## son SUD quand c'est la case du DESSOUS. Elle s'est tue parce qu'une robe la longe : la
## frontiere y est portee par le flanc de cette robe, une case plus bas et une colonne plus
## loin, et mon bord doit descendre au ras pour aller le toucher au coin.
const BELOW_QUIET_EAST: int = 32768


const BELOW_QUIET_WEST: int = 65536


## ⚠ LA LEVRE CONTRE UNE NON-LEVRE : le seul bord que le transfert de la crete laisse orphelin.
## Ma tuile porte le haut de ma face -- de la ROCHE dans sa bande basse -- et ma voisine
## laterale, si elle n'est pas une levre, y a de l'HERBE. Changement de matiere au bord de
## case, et aucune des deux ne le trace : 328 extremites, toutes en `0,y` et `15,y`.
##
## ⚠ ET LE RAS EST IMPOSSIBLE ICI, contrairement au cas du coin. Faire mourir la bande de roche
## a ses bouts lateraux mettrait de l'HERBE juste au-dessus de la roche de la robe : on
## deplacerait le changement de matiere d'un cran, sans personne pour le tracer non plus. La
## matiere doit rester continue vers le bas -- donc c'est un BIT, et il se paie.
##
## ⚠ ET IL SE POSE DU COTE DE LA LEVRE, PAS DE LA VOISINE. Sept silhouettes sur vingt-sept ont
## le sud vide ; vingt ne l'ont pas. Le meme fait coute donc trois fois moins cher enonce du
## bon cote.
const LIP_ALONE_EAST: int = 131072


const LIP_ALONE_WEST: int = 262144


## ⚠ ET « JE SUIS ENTERRE » N'EST PAS UN BIT DE TUILE, C'EST UNE POSE -- essaye, chiffre,
## retire. Un etage plus haut qui occupe ma case n'est pas une propriete de MA case vue de
## dessus : c'est une propriete de l'EMPILEMENT, que l'assemblage connait deja. Mesure du bit :
## il ferme cinq couples sur neuf et coute 74 -> 121 tuiles de surface pour UN dessin de plus.
## C'est payer quarante-sept tuiles ce que la pose sait faire gratuitement -- meme lecon que la
## pose arriere : « zero dessin de plus : on ne fait que ne pas poser ce que le modele ne met
## pas la ».


const CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]


## La diagonale de chaque coin, dans le meme ordre : NO, NE, SE, SO.
const DIAGONALS: Array[int] = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW]

const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## LES COTES OUVERTS D'UNE SURFACE -- tout ce que la tuile decide de son trait.
##
## ⚠ ET C'EST LE RECENSEMENT DES RACCORDS QUI L'A FAIT SORTIR DE `_paint`. Deux endroits
## devaient repondre a la meme question -- qui trace de quel cote -- et deux copies d'une meme
## regle finissent toujours par se contredire. C'est la lecon de `core/families.gd`, payee une
## fois de plus.
static func surface_open(key: int, level: int) -> Array[bool]:
	var index: int = key & 0xff
	var brink: int = key >> 8
	var open: Array[bool] = [false, false, false, false]
	for side: int in range(4):
		open[side] = (index & CARDINALS[side]) == 0
	# Contre de la ROCHE, la surface se tait : c'est le flanc de la falaise qui trace.
	if (brink & 1) != 0:
		open[1] = false
	if (brink & 2) != 0:
		open[3] = false
	# ⚠ RIEN AU SUD -- MAIS SEULEMENT DANS UN MONDE QUI A DES FALAISES. Le theoreme est :
	# une case dont le sud est vide est une LEVRE, sa propre falaise commence juste
	# dessous, toujours. Le bord sud d'une surface et la crete du chapiteau sont donc LA
	# MEME frontiere, et c'est le chapiteau qui la porte -- lui seul sait de quelle face il
	# s'agit. Mesure : 780 doublements sans cette regle, 196 avec.
	#
	# ⚠ ET IL NE VAUT PAS A L0 NI A L1, dont les mondes n'ont pas de falaise : un sud vide
	# y est une vraie frontiere libre, que personne d'autre ne tracera. L'appliquer partout
	# a fait rougir les SIX couples acquis d'un coup -- c'est le rejeu qui l'a dit, pas moi.
	# Une regle juste a un niveau peut etre fausse au niveau d'en dessous.
	# ⚠ RIEN AU SUD, ET RENDRE LE SUD A ETE ESSAYE : 222 -> 669 extremites, 288
	# doublements, 11 388 parasites. Le bord sud d'une case et le bord NORD de celle d'en
	# dessous sont LA MEME frontiere -- l'une des deux doit se taire, et c'est le sud, dont
	# la voisine du nord existe toujours alors que la crete, elle, peut manquer.
	if level >= 2:
		open[2] = false
	# ⚠ ET SOUS UNE FACE, LA SURFACE SE TAIT AU NORD -- symetrique exact du bord lateral.
	# Le bas du PIED et mon bord nord sont la meme frontiere ; le pied la porte, parce que
	# son bas referme le contour de la falaise et que rien d'autre ne le peut.
	if (brink & NORTH_QUIET) != 0:
		open[0] = false
	return open



## Les deux routes refusees, gardees joignables : un chiffre qu'on ne peut plus
## reproduire n'est plus un chiffre. Le produit les laisse a leur defaut.
static var j2_on_face: bool = false
static var ergot_diag: bool = true


## LE TRANSFERT DE LA CRETE : QUI TRACE LA FRONTIERE LEVRE / FALAISE.
##
## Faux (le regime mesure jusqu'ici) : c'est le CHAPITEAU. La surface ne trace jamais son sud,
## « lui seul sait de quelle face il s'agit ».
##
## Vrai : c'est la TUILE DE SURFACE A BORD SUD, et le chapiteau se tait. La licence est un
## theoreme deja au dossier -- « une case dont le sud est vide est une LEVRE, sa propre face
## couvre la case d'en dessous, TOUJOURS » -- donc c'est constant, donc c'est peignable dans la
## tuile de surface : mot pour mot l'argument qui autorise l'epaule, qui vit deja la.
##
## ⚠ ET CE N'EST PAS « RENDRE LE SUD », QUI A DEJA ETE ESSAYE ET REFUTE (222 -> 669 extremites,
## 11 388 parasites). Celui-la etait une ADDITION : la surface rouvrait son sud pendant que la
## crete continuait de tracer, donc deux traits pour une frontiere. Ici c'est un ECHANGE.
##
## ⚠ ET L'ENJEU EST LA LIBERTE DE LA FACE. Le bord d'une robe est plat sur dix pixels sur seize
## parce qu'il doit rencontrer un bord de surface qui serpente entre 4 et 7 sans qu'il sache ou
## -- et « ou le trait de ma voisine est passe » n'est pas exprimable en un bit fini, donc le
## ras est force. Si la surface possede la frontiere, personne ne devine : celui qui trace est
## celui qui sait.
static var crest_on_surface: bool = true


static func foot_above(cell: Vector2i, roles: Dictionary) -> bool:
	if not roles.has(cell):
		return false
	return (roles[cell] as Vector2i).y == Walls.ROW_FOOT


## Cette case-la trace-t-elle son bord de ce cote ? Quatre facons de ne pas le tracer, et
## chacune fait pendre l'ergot qui comptait dessus : elle porte une ROBE, qui la recouvre ; son
## cardinal est PLEIN, donc elle n'a pas de bord la ; le BORD (option B) l'a fait TAIRE ; ou
## c'est son SUD, qui ne se trace plus du tout des L2.
## La robe au-dessus trace-t-elle son bas ? Seul un PIED le fait -- une rangee de corps s'arrete
## sans bord, qu'elle soit ecretee ou non.
## LA CARTE DES ROBES, FERMEE : une chute qui s'arrete pose son PIED, quelle que soit la raison
## -- atterrissage, ecretage, ou chute dans le vide. Ce qui change est le SENS du pied : il ne
## prouve plus un atterrissage, il FERME CE QU'ON VOIT DE LA FACE.
##
## ⚠ ET C'EST LA SEULE SOURCE, DESORMAIS. La regle etait ecrite DEUX FOIS -- une pour le
## dessin, une pour les bits de silence a cheval, et celle-la lisait la carte BRUTE. La tuile de
## robe posait donc son bas -- pied substitue -- pendant que la tuile a cheval, croyant avoir un
## CORPS au-dessus, tracait la meme frontiere : deux traits pour un seul bord. Mesure sur
## `@battue1` : 26 doublements, tous etiquetes `falaise`.
##
## ⚠ MEME ESPECE QUE `_check_wall_seams` QUI REDERIVAIT `row_for`, ET QUE LES DEUX
## VOCABULAIRES DE SURFACE AVANT `core/families.gd`. Deux copies d'une meme regle finissent
## toujours par se contredire, et celle qui se tait est celle qu'on ne regarde pas.
static func closed_roles(roles: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for cell: Vector2i in roles.keys():
		var role: Vector2i = roles[cell]
		var ends: bool = not roles.has(cell + Vector2i.DOWN)
		out[cell] = Vector2i(role.x, Walls.ROW_FOOT) if ends else role
	return out


static func draws_side(cell: Vector2i, side: int, indices: Dictionary,
		roles: Dictionary, level: int) -> bool:
	if roles.has(cell) or not indices.has(cell):
		return false
	return surface_open(int(indices[cell]), level)[side]


static func why_stub(cell: Vector2i, side: int, indices: Dictionary, roles: Dictionary,
		level: int) -> void:
	var quoi: String = "?"
	if side == 2 and level >= 2:
		quoi = "c'est le SUD (constante : lisible dans ma silhouette)"
	elif roles.has(cell):
		quoi = "la voisine porte une ROBE"
	elif not indices.has(cell):
		quoi = "hors du monde"
	elif (int(indices[cell]) & CARDINALS[side]) != 0:
		quoi = "le cardinal de la voisine est PLEIN"
	else:
		quoi = "le BORD l'a fait taire"
	stub_why[quoi] = int(stub_why.get(quoi, 0)) + 1


## ⚠ ET IL DEMANDE A `_surface_open`, IL NE REFAIT PAS LE CALCUL. C'etait une TROISIEME copie
## de « qui trace de quel cote » : elle testait le bit contre-la-roche a l'est et a l'ouest,
## elle testait le sud, et elle NE TESTAIT JAMAIS `NORTH_QUIET`. Une case dont le nord s'est tu
## sous un pied s'y annoncait donc tracante, l'ergot du voisin se posait pour la rejoindre, et
## il ne rejoignait rien : 13 extremites sur le guide, aucune sur la planche -- qui ne met
## jamais les deux cas cote a cote.
##
## Meme espece que `_check_wall_seams` qui redérivait `row_for`, et que les deux vocabulaires de
## surface avant `core/families.gd` : deux copies d'une meme regle finissent toujours par se
## contredire, et celle qui se tait est celle qu'on ne regarde pas.
## POURQUOI L'ERGOT SE TAIT. Quatre raisons possibles, et elles ne se valent pas : trois
## demandent ce que la VOISINE a decide, la quatrieme -- « c'est le sud, qui ne se trace plus
## depuis L2 » -- se lit dans MA silhouette seule. Si c'est elle qui domine, la moitie des
## huit bits de l'ergot est une CONSTANTE deguisee en bit.
static var stub_why: Dictionary = {}


## Combien de bords ouverts une surface porte, et combien ne donnent PAS sur une face.
static var open_edges: int = 0


static var bare_edges: int = 0


## LES BITS D'UN RELIEF ENTIER : la cle de chaque case, a chaque etage.
##
## Elle prend le monde et ses robes, et ECRIT dans `storeys`, `indices` et `vocabulary` la cle
## complete de chaque case -- silhouette dans les huit bits bas, bord au-dessus. Elle rend la
## carte des robes FERMEE, celle qu'il faut ensuite dessiner : la substitution du pied se fait
## AVANT les bits, jamais apres.
##
## ⚠ ET C'EST LE MODELE, PAS LE DESSIN. Ce qui est decide ici est ce qu'une tuile doit SAVOIR ;
## comment elle le dessine appartient a `render/contour_tiles.gd`. La frontiere entre les deux
## est exactement celle que le portage a servi a tracer.
static func mark(world: PackedStringArray, storeys: Array[Dictionary], indices: Dictionary,
		vocabulary: Dictionary, roles: Dictionary, level: int, drop: int = 0) -> Dictionary:
	# ⚠ ET A CHEVAL, AUCUN BIT DE BORD. Une tuile de croisement ne porte que des frontieres
	# INTERNES : hors d'elle, sa voisine designe les memes cases. Elle n'a donc rien a
	# savoir de son voisinage, et la question « qui trace » ne se pose pas. C'est ce que le
	# temoin doit confirmer -- ou refuter.
	# ⚠ UNE CHUTE QUI S'ARRETE DOIT SE FERMER, QUELLE QUE SOIT LA RAISON. Le modele ne pose
	# le PIED qu'a l'atterrissage : une chute qui tombe dans le VIDE n'en pose pas -- « on
	# ne touche pas le fond d'un gouffre » -- et une chute ECRETEE non plus, elle s'arrete
	# sur une rangee de corps. Or dans les deux cas la roche VISIBLE a une fin, et une
	# rangee de corps n'a pas de bord bas : personne ne la trace.
	#
	# On y pose donc le PIED, qui est exactement la tuile « bas de falaise ». Cout : ZERO
	# tuile. Ce qui change est le SENS du pied -- il ne prouve plus un atterrissage, il
	# FERME CE QU'ON VOIT DE LA FACE. C'est deja ce qu'il faisait pour le vide ; l'ecretage
	# est le meme fait, avec du sol derriere au lieu du neant.
	#
	# ⚠ ET LA CONDITION EST « AUCUNE ROBE EN DESSOUS », pas « du vide en dessous ». Un
	# atterrissage a deja son pied, donc la substitution y est un no-op ; ce qu'elle attrape
	# est exactement ce qui s'arretait sans bord.
	#
	# ⚠ ET ELLE SE FAIT AVANT LES BITS DE BORD, JAMAIS APRES. C'est `_foot_above` qui fait
	# taire le nord de la surface d'en dessous : calculee apres, la substitution arrive trop
	# tard, la surface trace son nord A SA PROFONDEUR et la frontiere a deux descriptions
	# qui ne se rejoignent pas au coin. Sixieme fois qu'un ordre de calcul me coute une
	# mesure.
	roles = closed_roles(roles)
	# ⚠ LE BIT SE CALCULE ICI, PAS DANS LA TUILE. C'est justement ce qu'une tuile ne peut
	# pas savoir : ce qu'il y a de l'autre cote. Le banc, lui, a le monde sous les yeux --
	# c'est ce qui permet de MESURER le prix avant de decider si on le paie.
	for y: int in range(HeightMask.height(world) if level < 5 else 0):
		for x: int in range(HeightMask.width(world)):
			var cell2: Vector2i = Vector2i(x, y)
			if not indices.has(cell2):
				continue
			var tile2: int = int(indices[cell2])
			var edge: int = 0
			# ⚠ ET ON COMPTE CE QU'IL Y A DERRIERE CHAQUE BORD OUVERT. Si TOUT bord lateral
			# ou nord d'une surface donne sur une case couverte par une FACE, alors la
			# surface n'a jamais besoin de le tracer -- la face le fait -- et J2 coute ZERO
			# bit des deux cotes. C'est le seul chemin vers 47 tuiles, et il se mesure.
			for side: int in range(4):
				if side == 2 or (tile2 & CARDINALS[side]) != 0:
					continue
				open_edges += 1
				if not roles.has(cell2 + STEPS[side]):
					bare_edges += 1
			if not j2_on_face and (tile2 & BlobIndex.E) == 0 and roles.has(cell2 + Vector2i.RIGHT):
				edge |= 1
			if not j2_on_face and (tile2 & BlobIndex.W) == 0 and roles.has(cell2 + Vector2i.LEFT):
				edge |= 2
			# ⚠ ET LE NORD : SOUS UNE FACE, C'EST UN PLI, DONC C'EST LE BORD. Quand une
			# robe couvre ma voisine du nord, ce que j'ai au-dessus n'est pas un sol plus
			# bas mais le PIED d'une falaise -- il occupe sa case entiere, et la frontiere
			# entre nous est le bord de case. Mon bord nord s'y met donc au ras, et le pied
			# n'a plus a le tracer.
			#
			# ⚠ CE N'EST PAS « TOUT NORD AU RAS », ESSAYE ET REFUTE : 43 -> 65 extremites,
			# 94 paves. Contre un simple sol plus bas, le bord du voisin est libre, et
			# mettre le mien au ras l'empeche de le retrouver.
			# ⚠ ET SEULEMENT SI LA ROBE AU-DESSUS TRACE VRAIMENT SON BAS, c'est-a-dire si
			# c'est un PIED. Une chute ECRETEE s'arrete sur une rangee de corps, qui n'a pas
			# de bord bas : la faire taire quand meme laisse la frontiere sans personne, et
			# la roche bute sur l'herbe sans un trait. Vu au pixel, trois fois.
			if not j2_on_face and (tile2 & BlobIndex.N) == 0 					and foot_above(cell2 + Vector2i.UP, roles):
				edge |= NORTH_QUIET

			edge &= ~drop
			indices[cell2] = tile2 | (edge << 8)
			vocabulary[tile2 | (edge << 8)] = true
			# ⚠ ET DANS LA SILHOUETTE AUSSI, sinon rien ne bouge : c'est elle que
			# l'assemblage lit, pas la carte visible.
			#
			# ⚠ ET DANS TOUS LES ETAGES DE LA CASE, PAS SEULEMENT LE SIEN. Un bit de bord
			# repond a une question de CASE -- « qu'y a-t-il a cote de moi » -- pas d'etage :
			# la face qui couvre ma voisine la couvre pour tous mes etages a la fois. Ecrit
			# sur le seul etage visible, l'etage ENTERRE gardait son bord ouvert et le
			# tracait -- et on le voit, parce que la tuile du dessus est transparente a son
			# encoche. Mesure sur une battue : le trait fautif etait le bord EST d'un etage
			# enterre, a x=12, sous l'encoche nord de la tuile visible.
			# ⚠ ET CHAQUE ETAGE REPOND DEPUIS SA PROPRE SILHOUETTE. Un bit pose depuis
			# la silhouette VISIBLE fabrique des tuiles qui ne different par rien : sur un
			# etage ou le cardinal est deja plein, le bit est inerte, mais il change la cle.
			# Mesure : +5 tuiles a le poser en gros, +1 a le poser au bon endroit.
			for storey2: int in range(HeightMask.level_at(world, x, y) + 1):
				var mine2: Dictionary = storeys[storey2]
				if not mine2.has(cell2):
					continue
				var buried: int = int(mine2[cell2]) & 0xff
				var deep: int = 0
				if (buried & BlobIndex.E) == 0 and roles.has(cell2 + Vector2i.RIGHT):
					deep |= 1
				if (buried & BlobIndex.W) == 0 and roles.has(cell2 + Vector2i.LEFT):
					deep |= 2
				if (buried & BlobIndex.N) == 0 and foot_above(cell2 + Vector2i.UP, roles):
					deep |= NORTH_QUIET
				mine2[cell2] = buried | (((int(mine2[cell2]) >> 8) | deep) << 8)
				vocabulary[int(mine2[cell2])] = true
	# ⚠ ET LES BITS DE L'ERGOT SE POSENT EN SECONDE PASSE. Ils demandent si la VOISINE
	# trace son bord -- ce qui depend du bord qu'on vient de lui poser. Calcules dans la
	# meme boucle, ils interrogent une case pas encore traitee et repondent au hasard : la
	# voisine du sud, en ordre de lecture, n'a jamais encore le sien. Cinquieme fois qu'un
	# ordre de calcul me coute une mesure.
	# ⚠ ET RIEN DE TOUT CA QUAND LA FACE PORTE LE BIT. L'ergot et la traversee au ras
	# sont des RUSTINES DU SILENCE DE LA SURFACE : ils existent pour rattraper un bord
	# que la surface a cesse de tracer. Si c'est la face qui cede, la surface ne se tait
	# jamais et il n'y a rien a rattraper -- les garder ferait payer 10 tuiles pour rien.
	# ⚠ ET LA SECONDE PASSE SE FAIT PAR ETAGE, SUR LA SILHOUETTE DE CET ETAGE-LA. Meme
	# raison que pour les bits de bord, et meme mesure : ecrite sur le seul etage visible,
	# elle laissait les etages ENTERRES poser leurs ergots et leurs traversees au ras selon
	# un voisinage qui n'est pas le leur -- et on les voit, par les encoches du dessus.
	# Chaque etage interroge donc SES voisines, dans SA silhouette.
	if not j2_on_face and level < 5:
		for storey3: int in range(storeys.size()):
			var map3: Dictionary = storeys[storey3]
			for here2: Vector2i in map3.keys():
				var full: int = int(map3[here2])
				var shape: int = full & 0xff
				var more: int = full >> 8
				for corner: int in range(4):
					var a: int = corner
					var b: int = (corner + 3) % 4
					if (shape & CARDINALS[a]) == 0 or (shape & CARDINALS[b]) == 0:
						continue
					if (shape & DIAGONALS[corner]) != 0:
						continue
					# ⚠ L'ERGOT PAR LA DIAGONALE : UN FAIT DU MONDE, PAS UNE DECISION.
					# Les deux bits du coin demandaient « ma voisine trace-t-elle ce
					# cote-la ? » -- une DECISION, ce que la clause B interdit. Or le
					# diagnostic dit pourquoi elle ne trace pas : dans 43 a 67 cas sur
					# 47 a 73, c'est que « le bord l'a fait taire », c'est-a-dire qu'une
					# FACE couvre ma diagonale. La question se retourne donc en un fait
					# que je peux poser moi-meme, et un seul par coin au lieu de deux.
					if ergot_diag:
						# ⚠ ET AUX COINS SUD, LA REPONSE EST TOUJOURS OUI -- C'EST LA
						# REGLE DE LA LEVRE, UN CRAN PLUS BAS. Au coin SE, ma cardinale
						# EST est pleine et ma diagonale SE est vide : cette voisine a
						# donc son sud vide, c'est une LEVRE, et sa face couvre ma
						# diagonale. Toujours. Idem au SO par la voisine ouest. Mesure
						# avant d'ecrire : bit mis 6 fois sur 6 aux deux coins sud,
						# 2 fois sur 7 aux deux coins nord.
						if corner >= 2 and level >= 2:
							continue
						var coin: Vector2i = here2 + STEPS[a] + STEPS[b]
						if roles.has(coin):
							more |= 4 << corner
						continue
					# ⚠ ET LE PARTENAIRE AU SUD N'EST PAS UNE QUESTION, C'EST UNE
					# CONSTANTE. Des L2 le sud ne se trace plus jamais -- « le bord sud
					# d'une case et le bord nord de celle d'en dessous sont la meme
					# frontiere, et c'est le sud qui se tait ». Le bit valait donc
					# TOUJOURS 1 pour ces deux ergots-la : il ne nommait rien, il
					# doublait le vocabulaire pour rien. Mesure : la moitie des silences
					# de l'ergot etaient celui-la -- 47 sur la planche, 57 sur le guide.
					# Le dessin s'en charge, la cle n'en parle plus.
					if not (b == 2 and level >= 2):
						if not draws_side(here2 + STEPS[a], b, indices, roles, level):
							more |= 4 << corner
							why_stub(here2 + STEPS[a], b, indices, roles, level)
					if not (a == 2 and level >= 2):
						if not draws_side(here2 + STEPS[b], a, indices, roles, level):
							more |= 64 << corner
							why_stub(here2 + STEPS[b], a, indices, roles, level)
				# ⚠ ET LE BORD LATERAL MEURT A SON NORD QUAND LA CASE DU DESSUS S'EST TUE DE
				# CE COTE-LA. Elle s'est tue parce qu'une ROBE la longe : c'est donc le flanc
				# de cette robe qui porte la frontiere, une case plus haut et une colonne plus
				# loin. Mon bord doit alors traverser ma frontiere nord AU RAS, pour aller le
				# toucher au coin au lieu de s'arreter a sa profondeur.
				# ⚠ ET CE BIT-LA SE LIT SUR LA VOISINE LATERALE, DONC APRES LA PREMIERE
				# PASSE. Il demande si ELLE s'est tue au nord, ce qui n'est vrai qu'une fois
				# tous les `NORTH_QUIET` poses. Septieme fois qu'un ordre de calcul compte.
				# ⚠ ET IL NE SE POSE QUE LA OU IL SERT, SOUS TROIS CONDITIONS -- sans
				# quoi il fabrique des tuiles qui ne different par rien de visible :
				# je dois VRAIMENT tracer mon nord (pas seulement l'avoir vide : le bord
				# a pu me faire taire) ; le cardinal vers la voisine doit etre PLEIN,
				# sinon nos deux bords nord ne sont pas la meme frontiere ; et c'est
				# `_surface_open` qui repond, jamais un test refait a la main.
				if surface_open(full, level)[0]:
					for way: int in range(2):
						var toward: int = 1 if way == 0 else 3
						if (shape & CARDINALS[toward]) == 0:
							continue
						var beside: Vector2i = here2 + STEPS[toward]
						if roles.has(beside) or not indices.has(beside):
							continue
						if (int(indices[beside]) >> 8 & NORTH_QUIET) == 0:
							continue
						more |= NORTH_FLUSH_EAST if way == 0 else NORTH_FLUSH_WEST
				# ⚠ ET LE MEME, VERS LE BAS. Mesure : sans lui, faire taire l'ergot des
				# etages enterres -- ce qui est juste -- rouvre UNE extremite sur la planche
				# et une sur le guide. Elles n'etaient fermees que par accident, par un
				# ergot enterre qui passait par la.
				var down2: Vector2i = here2 + Vector2i.DOWN
				if (shape & BlobIndex.S) != 0 and map3.has(down2) and not roles.has(down2):
					var low: int = int(map3[down2]) >> 8
					if surface_open(full, level)[1] and (low & 1) != 0:
						more |= BELOW_QUIET_EAST
					if surface_open(full, level)[3] and (low & 2) != 0:
						more |= BELOW_QUIET_WEST
				var over: Vector2i = here2 + Vector2i.UP
				if (shape & BlobIndex.N) != 0 and indices.has(over) and not roles.has(over):
					var up: int = int(indices[over]) >> 8
					# ⚠ ET IL FAUT QUE JE TRACE VRAIMENT CE COTE-LA, comme son jumeau
					# `BELOW_*` le demande deja. `ABOVE_*` ne fait qu'une chose : ramener
					# mon bord lateral au ras a son premier pixel. Si le BORD a deja fait
					# taire ce cote, il ne change plus un pixel -- et il change quand meme
					# la cle, donc il fabrique une tuile pour rien.
					#
					# ⚠ TROUVE PAR LE CONTROLE DE LA FORME FERMEE, ET DANS LE BON SENS.
					# J'avais d'abord resserre l'ENUMERATION (`closed_form_now.py`), et
					# quatre cles posees par le guide sont aussitot tombees HORS de la
					# forme : c'est le monde qui avait raison. La regle appartient au
					# banc, pas a l'enumeration -- celle-ci ne fait que la transcrire.
					if surface_open(full, level)[1] and (up & 1) != 0:
						more |= ABOVE_QUIET_EAST
					if surface_open(full, level)[3] and (up & 2) != 0:
						more |= ABOVE_QUIET_WEST
				# ⚠ LA LEVRE SEULE : ma bande de roche bute sur l'herbe de ma voisine. Le bit
				# ne se pose que si la voisine EXISTE a mon etage -- si mon cardinal est
				# vide, mon bord est deja ouvert et le contour de la matiere trace tout
				# seul.
				if crest_on_surface and is_lip(shape, level):
					for way2: int in range(2):
						var toward2: int = 1 if way2 == 0 else 3
						if (shape & CARDINALS[toward2]) == 0:
							continue
						var next_to: Vector2i = here2 + STEPS[toward2]
						if not map3.has(next_to):
							continue
						if is_lip(int(map3[next_to]) & 0xff, level):
							continue
						# ⚠ ET PAS SI UNE ROBE COUVRE CETTE VOISINE -- « ma bande bute sur
						# son HERBE » est alors faux : elle montre de la ROCHE, et cette
						# roche est une face pleine, dont le flanc trace deja. Deux
						# tracants pour une frontiere : 10 paves, tous
						# `surface etage N | robe`, et ils ont survecu a la variante
						# enterree parce qu'ils n'ont rien a voir avec l'empilement.
						#
						# ⚠ C'EST LA FACE PLEINE QUI TRACE, LE LISERE SE TAIT. Le bandeau
						# n'est qu'un lisere de MA face vue de trois quarts ; en face, la
						# robe EST la face. Entre les deux, celui qui sait le plus trace --
						# meme arbitrage que l'arete interne, ou le bloc qui avance porte
						# l'angle.
						if roles.has(next_to):
							continue
						# ⚠ NI SI ELLE EST ENTERREE SOUS UN ETAGE PLUS HAUT -- meme faute,
						# meme forme : ce qu'on voit a cote n'est alors pas son herbe, c'est
						# la COUPE de l'etage qui la recouvre, et cette coupe trace son
						# propre bord ouest. La regle se dit d'une phrase : le bit parle de
						# ce qu'on VOIT a cote, jamais de ce que ma silhouette y trouve.
						#
						# ⚠ C'EST LA TROISIEME FOIS DE LA SESSION QU'UNE REGLE LIT LA
						# SILHOUETTE LA OU IL FALLAIT LIRE LA SURFACE VISIBLE. « On ne voit
						# que le sommet » est au dossier depuis la couverture ; elle vaut
						# aussi pour qui trace.
						# ⚠ NI SI CE QU'ON VOIT A COTE EST UNE LEVRE D'UN AUTRE ETAGE. Alors ce
						# n'est pas de l'herbe qui est en face, c'est SON bandeau -- de la
						# face, comme le mien -- et un bandeau ne se creuse pas
						# lateralement : il touche la frontiere et la trace. Deux liseres
						# de face pour une frontiere, c'est le doublement.
						#
						# ⚠ ET SE TAIRE DES QUE LA VOISINE EST ENTERREE, SANS REGARDER CE
						# QU'ON VOIT, A ETE ESSAYE ET REFUTE : 20 extremites, toutes noyees.
						# Une surface ordinaire, elle, CREUSE son bord lateral -- son trait
						# n'atteint jamais la frontiere, et le mien y etait le seul.
						# `is_lip` est exactement ce qui separe les deux.
						if HeightMask.level_at(world, next_to.x, next_to.y) != storey3 								and indices.has(next_to) 								and is_lip(int(indices[next_to]) & 0xff, level):
							continue
						more |= LIP_ALONE_EAST if way2 == 0 else LIP_ALONE_WEST
				more &= ~drop
				if more == full >> 8:
					continue
				map3[here2] = shape | (more << 8)
				vocabulary[shape | (more << 8)] = true
		# ⚠ ET LA CARTE VISIBLE SE REFAIT DEPUIS LES SILHOUETTES, jamais l'inverse. C'est
		# l'etage de la case qui dit quelle tuile on voit ; la garder a jour a la main
		# serait une seconde source, donc un endroit ou mentir.
		for cell3: Vector2i in indices.keys():
			indices[cell3] = int((storeys[HeightMask.level_at(world, cell3.x, cell3.y)]
					as Dictionary)[cell3])
	return roles


## LES CLES D'UN RELIEF, SANS RIEN DESSINER -- les silhouettes par etage, la carte visible,
## le vocabulaire, et les robes fermees.
##
## ⚠ ELLE N'AJOUTE RIEN AU MODELE, ELLE EN RETIRE UNE COPIE. Ce bloc vivait en entier dans
## `Contour.compose`, qui n'en avait besoin que pour appeler `mark()` ; tout outil qui voulait
## les cles d'un relief devait donc soit le recopier, soit DESSINER l'image entiere pour lire
## un dictionnaire. Deux copies d'une meme regle finissent toujours par se contredire -- la
## lecon est deja au dossier, payee sur `_check_wall_seams` et sur les deux vocabulaires de
## surface avant `core/families.gd`.
##
## ⚠ ET `seen` SORT AVEC, parce que la pose arriere en depend et qu'il serait absurde de
## refaire `Walls.visible_all` derriere.
static func keys(world: PackedStringArray, level: int) -> Dictionary:
	var top: int = 0
	for y: int in range(HeightMask.height(world)):
		for x: int in range(HeightMask.width(world)):
			top = maxi(top, HeightMask.level_at(world, x, y))
	var storeys: Array[Dictionary] = []
	for storey: int in range(top + 1):
		var mask: PackedStringArray = HeightMask.silhouette(world, storey)
		var map: Dictionary = {}
		for y: int in range(HeightMask.height(mask)):
			for x: int in range(HeightMask.width(mask)):
				if Coverage.index_at(mask, x, y) == Coverage.NO_INDEX:
					continue
				map[Vector2i(x, y)] = Coverage.index_at(mask, x, y)
		storeys.append(map)
	var indices: Dictionary = {}
	for y: int in range(HeightMask.height(world)):
		for x: int in range(HeightMask.width(world)):
			var here: int = HeightMask.level_at(world, x, y)
			if here < 0:
				continue
			indices[Vector2i(x, y)] = int((storeys[here] as Dictionary)[Vector2i(x, y)])
	var vocabulary: Dictionary = {}
	for storey: int in range(storeys.size()):
		for cell: Vector2i in (storeys[storey] as Dictionary).keys():
			vocabulary[int((storeys[storey] as Dictionary)[cell])] = true
	var roles: Dictionary = {}
	var seen: Dictionary = {}
	if level >= 2:
		seen = Walls.visible_all(world)
		roles = mark(world, storeys, indices, vocabulary, seen["roles"], level)
	return {"storeys": storeys, "indices": indices, "vocabulaire": vocabulary,
			"roles": roles, "seen": seen}


## LA CASE EST-ELLE UNE LEVRE ? Sud vide dans sa silhouette, donc sa propre face commence juste
## dessous -- theoreme du dossier, et c'est lui qui rend la chose CONSTANTE, donc peignable dans
## la tuile de surface. Meme licence que l'epaule, qui vit deja la.
static func is_lip(key: int, level: int) -> bool:
	return level >= 2 and (key & BlobIndex.S) == 0
