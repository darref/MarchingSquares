# LE DESSIN D'UNE TUILE DU NOUVEAU MODELE : le couple (silhouette d'empreinte, bande), et le
# seul bit de contexte qui reste -- RECOUVRANT.
#
# ⚠ UNE TUILE NE REPOND QUE D'ELLE-MEME. Elle remplit sa case ; ce qui est a cote appartient a
# la couche de la voisine, qui le dessine elle-meme, et l'ORDRE DE POSE tranche qui est devant.
# C'est pour ca que le dehors d'une tuile est TRANSPARENT et jamais peint : c'est lui qui fait
# l'occlusion, et un fond opaque cerne chaque tuile d'un halo qui supprime tout le modele.
#
# ⚠ ET LA LIBERTE SE MONTRE, ELLE NE SE DEDUIT PAS. Un bord dessine AU RAS dit a l'artiste « ce
# bord ne t'appartient pas » ; dessine a mi-tuile, il dit « place-le ou tu veux ». Le fond du
# guide est la specification, donc il doit rendre la liberte evidente au premier coup d'oeil.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const Massifs := preload("res://core/massifs.gd")
const Tiles := preload("res://render/contour_tiles.gd")

const RES: int = Tiles.RES
const OUTLINE: Color = Tiles.OUTLINE

## DEUX MATIERES, ET DEUX SEULEMENT : l'herbe et la roche.
##
## ⚠ LE CHAPITEAU, LE CORPS ET LE PIED NE SONT PAS TROIS MATIERES -- ce sont trois POSITIONS
## dans une meme paroi. Les teinter chacune faisait lire un empilement de bandes la ou il y a
## une face continue, et c'etait le defaut le plus visible du fond : « il y a tellement
## d'erreurs que je ne reconnais plus rien ».
##
## ⚠ ET UNE SEULE TEINTE PAR MATIERE, QUEL QUE SOIT L'ETAGE. Le tileset livre n'en a qu'une ;
## teinter chaque etage est une bequille de mise au point qui ment sur ce qui sortira. Meme
## argument que pour l'essai, deja au dossier : un tileset n'a qu'un jeu de tuiles.
const GRASS: Color = Color(0.42, 0.58, 0.30)
const ROCK: Color = Color(0.66, 0.51, 0.38)

## LA LUMIERE VIENT DU NORD-OUEST. C'est ce qui fait lire le relief, et c'est CONSTANT dans la
## tuile -- une levre a toujours de la surface au-dessus d'elle, un pied est toujours en bas --
## donc c'est peignable, et une tuile exportee peut le porter.
const LIT: float = 0.16
const DARK: float = 0.13
## L'amplitude de l'ondulation, en pixels, a F2.
const SWELL: float = 3.0

## LES ENCRES DU FOND. ⚠ ET LE CONTOUR PROUVE N'EST PAS UNE COQUETTERIE : en aplats, la matiere
## d'une couche cache les traits de celle du dessous et l'oeil ne peut plus juger du TRACE. En
## contour, toute la matiere porte la meme teinte : ce qui reste visible, ce sont exactement les
## lignes que le modele prouve -- donc ce que l'artiste aura a poser, et la ou ca peut casser.
const PEINT: int = 0
const CONTOUR: int = 1

## La matiere du contour prouve : une seule teinte, pour toutes les bandes et tous les etages.
const PAPER: Color = Color(0.86, 0.85, 0.80)


## LA PROFONDEUR D'UN BORD OUVERT, le long de ce bord.
##
## ⚠ LE RENDEZ-VOUS EST LA SEULE CHOSE QUI SE NEGOCIE ENTRE DEUX TUILES ; ce que le trait fait
## ENTRE deux rendez-vous n'engage personne. D'ou les trois libertes :
##   F0  la plus petite : le rendez-vous rentre d'UN pixel, le trait est droit -- le plancher ;
##   F1  le rendez-vous descend a MI-TUILE quand le massif est libre, le trait reste droit ;
##   F2  le meme rendez-vous, et le trait ONDULE entre deux rendez-vous.
##
## ⚠ ET LA PROFONDEUR ZERO EST IMPOSSIBLE POUR UN MASSIF LIBRE -- mesure, pas gout. A zero, le
## contour d'un massif tombe exactement sur la bordure de tuile ; deux massifs voisins ont alors
## leur contour sur LA MEME LIGNE et le tracent tous les deux, puisqu'une tuile ne repond que
## d'elle-meme. 186 paves, tous de cette espece : un PIED au-dessus du bord nord d'un autre
## massif. Le seul remede serait un bit « qui trace ? » -- c'est-a-dire le cliquet dont ce modele
## sort. On paie donc UN PIXEL : la liberte n'est pas un ornement, c'est ce qui separe deux
## massifs voisins.
##
## ⚠ ET LES MASSIFS RECOUVRANTS N'ONT PAS BESOIN DE CE PIXEL : deux contours au ras ne se font
## jamais face. Un massif d'etage N+1 est EMBOITE dans celui d'etage N, qui est donc plein le
## long de son bord et n'y trace rien ; et deux composantes de meme etage qui se touchent sont
## le meme massif.
##
## ⚠ ET UN MASSIF RECOUVRANT GARDE SON ONDULATION. « Au ras » veut dire que son arete touche la
## bordure de tuile AU RENDEZ-VOUS -- pour que n'importe quelle voisine puisse la rejoindre --
## pas qu'elle est plaquee sur toute sa longueur.
static func depth_of(along: int, freedom: int, flush: bool) -> int:
	# ⚠ ET LE RENDEZ-VOUS LIBRE N'EST PAS PILE A LA MOITIE. A `RES / 2`, la coupe d'un cote
	# ouvert et le creusement d'un COIN RENTRANT se completent EXACTEMENT : `CORPS 23` rendait
	# alors la meme image que `CORPS 7`, alors que les deux situations different -- l'une a de la
	# roche sous elle, l'autre non. Une degenerescence d'arrondi, pas une verite du modele. Un
	# pixel plus haut, et les deux se distinguent.
	#
	# ⚠ ET DEUX PIXELS NE SUFFISENT PAS : IL EN FAUT TROIS. Une jupe d'UNE colonne -- l'escalier
	# d'un bord sud -- donne une tuile dont l'est ET l'ouest sont ouverts. A `RES / 2` elle
	# disparait entierement ; a `RES / 2 - 1` il lui reste deux pixels, tous deux de bord, donc
	# deux traits colles que I2 compte. C'est la meme barre que min trois, un cran plus bas :
	# bord, centre, bord.
	var meet: float = 0.0 if flush else (1.0 if freedom <= 0 else float(RES) / 2.0 - 1.0)
	if freedom < 2:
		return int(round(meet))
	return int(round(meet + SWELL * _swell(along)))


## ⚠ LE RENDEZ-VOUS EST UN SEGMENT PLAT, PAS UN POINT -- et c'est la discretisation qui l'exige,
## pas le gout. La ou deux cardinaux ouverts se rencontrent, la coupe de l'ouest se prend a
## `depth_of(y)` et celle du sud a `depth_of(x)` : avec une ondulation qui vaut zero PILE au coin
## et un juste a cote, le pixel du coin reste seul -- ses deux voisins sont coupes, lui non. Un
## pixel de trait isole est une extremite, et I1 la comptait. Deux pixels plats a chaque bout, et
## la question ne se pose plus.
static func _swell(along: int) -> float:
	if along < 2 or along > RES - 3:
		return 0.0
	return sin(PI * float(along) / float(RES - 1))


## LA TUILE. `backdrop` n'est peint que pour une PLANCHE de specimens : isolee, une tuile a
## dehors transparent se lit comme un trou.
##
## ⚠ ET LA TEINTE SUIT L'ETAGE, sans quoi un massif RECOUVRANT est invisible sur son socle --
## meme vert, meme matiere, on ne voit que son contour. La teinte est ce qui dit l'altitude
## quand la vue est de dessus.
static func shape(sil: int, band: int, flush: bool, freedom: int = 1,
		backdrop: Color = Color(0, 0, 0, 0), level: int = 1, ink: int = PEINT) -> Image:
	var out: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	out.fill(backdrop)
	var solid: Array[PackedByteArray] = []
	for y: int in range(RES):
		var line: PackedByteArray = PackedByteArray()
		line.resize(RES)
		for x: int in range(RES):
			line[x] = 1 if _inside(sil, x, y, freedom, flush) else 0
		solid.append(line)
	for y2: int in range(RES):
		for x2: int in range(RES):
			if solid[y2][x2] == 0:
				continue
			var edge: bool = false
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var near: Vector2i = Vector2i(x2, y2) + step
				if near.x < 0 or near.y < 0 or near.x >= RES or near.y >= RES:
					# ⚠ UNE TUILE AU RAS TRACE QUAND MEME SON BORD, et c'est le defaut qui
					# rendait un massif RECOUVRANT invisible sur son socle : son contour tombe
					# exactement sur la bordure de tuile, et un cerne qui ne regarde qu'a
					# l'INTERIEUR ne le voit jamais. Au ras veut dire « mon arete est sur la
					# bordure », pas « je n'ai pas d'arete ».
					var side: int = 0 if step == Vector2i.UP else (
							1 if step == Vector2i.RIGHT else (
							2 if step == Vector2i.DOWN else 3))
					if (sil & [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W][side]) == 0:
						edge = true
					continue
				if solid[near.y][near.x] == 0:
					edge = true
			# ⚠ LE TRAIT DE LEVRE VIT DANS LA TUILE, ET IL EST CONSTANT : un CHAPITEAU a toujours
			# de la surface au-dessus de lui -- c'est sa definition meme, il pend sous le bord sud
			# d'une surface. La frontiere herbe/roche tombe donc a sa rangee du haut, toujours, et
			# aucune tuile n'a besoin de savoir quoi que ce soit de sa voisine.
			#
			# ⚠ ET C'EST AUSSI LE TRAIT DES FALAISES INTERNES : une encoche ouverte au sud dans un
			# massif porte sa propre falaise -- meme chapiteau, meme trait, sans un cas de plus.
			if band == Massifs.CHAPITEAU and y2 == 0:
				out.set_pixel(x2, y2, OUTLINE)
				continue
			if edge:
				out.set_pixel(x2, y2, OUTLINE)
				continue
			out.set_pixel(x2, y2, _matter(band, x2, y2, ink))
	return out


## LA MATIERE D'UN PIXEL : l'herbe est plate, la roche est striee et prend le jour au nord-ouest.
##
## ⚠ LA STRIURE DIT « PAROI », ET SANS ELLE UNE FALAISE EST UN APLAT MARRON. Elle se tient a
## distance des deux bords lateraux : deux colonnes de face voisines sont souvent la MEME paroi,
## et une rainure posee sur le bord se dedoublerait au raccord. Lecon deja payee sur l'ancien
## modele -- « ce qui depend de la rangee se tient a distance des bords gauche et droit ».
##
## ⚠ ET LA LEVRE EST LA SEULE MARQUE QUI TOUCHE UN BORD, parce qu'elle est CONSTANTE : un
## chapiteau a toujours de la surface au-dessus de lui, c'est sa definition meme.
## ⚠ ET EN CONTOUR, LA MATIERE EST PLATE MAIS PAS MUETTE : deux teintes, l'herbe et la roche.
## Une empreinte toute d'une teinte ne dit pas OU la surface s'arrete et ou la face commence --
## or c'est la premiere chose a lire dessus. Le trait dit la forme, la teinte dit la matiere, et
## rien d'autre ne vient brouiller ni l'un ni l'autre.
static func _matter(band: int, x: int, y: int, ink: int = PEINT) -> Color:
	if ink == CONTOUR:
		return GRASS if band == Massifs.SURFACE else ROCK
	if band == Massifs.SURFACE:
		return GRASS
	var tint: Color = ROCK
	# La levre prend le jour, juste sous le trait ; le pied s'enfonce dans l'ombre.
	#
	# ⚠ ET LA MARQUE DU PIED PORTE SUR TOUTE LA TUILE, PAS SUR SES RANGEES DU BAS. Un pied a
	# TOUJOURS son sud ouvert -- il atterrit sur du sol, qui n'est pas de son empreinte -- donc
	# en liberte ses rangees basses sont coupees et la marque disparait : `CORPS 193` rendait
	# alors la meme image que `PIED 193`. I7 l'a dit a la seconde meme. Une marque doit se poser
	# la ou la tuile est TOUJOURS visible, et pour un pied c'est partout.
	if band == Massifs.CHAPITEAU and y <= 2:
		tint = tint.lightened(LIT * (1.0 - float(y - 1) / 2.0))
	elif band == Massifs.PIED:
		tint = tint.darkened(DARK * (0.5 + 0.5 * float(y) / float(RES - 1)))
	# La striure : deux rainures, au quart et aux trois quarts.
	if x == RES / 4 or x == RES - 1 - RES / 4:
		tint = tint.darkened(0.07)
	elif x == RES / 4 + 1 or x == RES - RES / 4:
		tint = tint.lightened(0.05)
	return tint


## LA MATIERE DERRIERE : le sous-pied, plein, SANS TRAIT.
##
## ⚠ IL N'A PAS DE CONTOUR, PARCE QU'IL N'EST PAS UNE FRONTIERE. C'est la meme face qui continue
## sous la surface d'atterrissage : on ne la voit que dans le mince decalage ou le contour de
## cette surface vagabonde vers l'interieur. Lui laisser tracer son bord ajoutait 30 extremites
## -- un trait qui s'arrete sous une couche, puis reapparait.
static func backing(level: int = 1) -> Image:
	var out: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	for y: int in range(RES):
		for x: int in range(RES):
			out.set_pixel(x, y, _matter(Massifs.PIED, x, y))
	return out


static func _inside(sil: int, x: int, y: int, freedom: int, flush: bool) -> bool:
	if (sil & BlobIndex.N) == 0 and y < depth_of(x, freedom, flush):
		return false
	if (sil & BlobIndex.S) == 0 and y > RES - 1 - depth_of(x, freedom, flush):
		return false
	if (sil & BlobIndex.W) == 0 and x < depth_of(y, freedom, flush):
		return false
	if (sil & BlobIndex.E) == 0 and x > RES - 1 - depth_of(y, freedom, flush):
		return false
	# LE COIN RENTRANT : les deux cardinaux pleins, la diagonale vide. C'est une encoche, et elle
	# se creuse a la meme profondeur que les bords -- sinon elle ne rejoindrait pas les voisines.
	for corner: int in range(4):
		var a: int = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W][corner]
		var b: int = [BlobIndex.W, BlobIndex.N, BlobIndex.E, BlobIndex.S][corner]
		var d: int = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW][corner]
		if (sil & a) == 0 or (sil & b) == 0 or (sil & d) != 0:
			continue
		var near_y: bool = y < depth_of(x, freedom, flush) if corner < 2 \
				else y > RES - 1 - depth_of(x, freedom, flush)
		var near_x: bool = x > RES - 1 - depth_of(y, freedom, flush) \
				if corner == 1 or corner == 2 else x < depth_of(y, freedom, flush)
		if near_x and near_y:
			return false
	return true
