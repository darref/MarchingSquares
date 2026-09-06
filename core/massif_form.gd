# LA FORME FERMEE DU VOCABULAIRE DES MASSIFS — ce que le modele PEUT produire, exhaustivement.
#
# ⚠ ET C'EST UNE BORNE HAUTE, DONC ELLE NE SUFFIT PAS SEULE. Elle dit ce qui est realisable ;
# elle ne dit pas ce qui arrive. Le controle se fait dans les DEUX SENS -- l'enumeration
# ci-dessous, et une battue sur des reliefs epais -- et l'ecart se paie en temoins construits ou
# en arguments d'impossibilite. Jamais en « la battue ne l'a pas vu, donc ca n'existe pas » : une
# battue qui ne rencontre pas une tuile prouve qu'elle est rare, jamais qu'elle est impossible.
# C'est la faute la plus chere du projet, deja payee deux fois.
#
# LA FENETRE, ET POURQUOI ELLE SUFFIT. L'empreinte d'une colonne ne depend que de cette colonne :
# une case est de la falaise si un bord sud de son massif se trouve une, deux ou trois rangees
# plus haut. Pour lire la silhouette de la case centrale il faut l'empreinte de ses huit
# voisines -- trois colonnes et trois rangees d'empreinte -- donc trois colonnes et SIX rangees
# de surface. 2^18 fenetres : exhaustif, et c'est un theoreme, pas un sondage.
#
# ⚠ ET MIN TROIS REND LA JUPE NON AMBIGUE. Deux bords sud d'une meme colonne sont separes d'au
# moins quatre rangees -- le vide entre eux est une course, donc au moins trois -- si bien que
# deux jupes ne se disputent jamais une case. Sans min trois, la bande d'une case dependrait de
# l'ordre de parcours, et le modele aurait un endroit ou mentir.
#
# ⚠ LE RESULTAT EST GENERE, PAS CALCULE AU DEMARRAGE. 262 144 fenetres coutent des secondes ;
# l'editeur ne peut pas les payer a chaque ouverture. La liste vit donc dans
# `core/massif_vocabulary.gd`, et la suite la COMPARE a cette enumeration -- une donnee est un
# endroit ou mentir tant que rien ne la confronte a sa source.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const Massifs := preload("res://core/massifs.gd")
const Witnesses := preload("res://core/massif_witnesses.gd")

const COLS: int = 3
const ROWS: int = 6
const CX: int = 1
const CY: int = 4


## LES COUPLES (silhouette d'empreinte, bande) REALISABLES, ranges croissants.
## La cle est `(bande << 8) | silhouette` -- sans le bit RECOUVRANT, qui ne double que le dessin.
static func couples() -> Array[int]:
	var out: Array[int] = []
	out.assign(witnesses().keys())
	out.sort()
	return out


## ⚠ ET L'ENUMERATION GARDE SES TEMOINS, CE QUI REND LE GUIDE GRATUIT. Chaque couple est produit
## par des fenetres concretes ; les jeter reviendrait a savoir qu'une tuile existe sans savoir
## quel relief la porte -- et il faudrait ensuite la CHERCHER pour pouvoir la peindre. On les
## garde toutes : il n'y a que 1 734 fenetres realisables en tout.
##
## Rend `{couple: [bits de fenetre]}`.
static func witnesses() -> Dictionary:
	var found: Dictionary = {}
	for bits: int in range(1 << (COLS * ROWS)):
		var surface: Array[PackedByteArray] = _window(bits)
		if _thin_inside(surface):
			continue
		var here: Dictionary = {}
		_couples_of(surface, here)
		for couple: int in here.keys():
			if not found.has(couple):
				found[couple] = [] as Array[int]
			(found[couple] as Array[int]).append(bits)
	return found


## LES COUPLES AVEC LEUR CISAILLEMENT, exhaustivement.
##
## ⚠ POURQUOI CE BIT-LA ET PAS UN AUTRE. La BANDE encode deja la transition VERTICALE -- surface,
## chapiteau, corps, pied -- et c'est pour ca que la levre porte son trait. Rien n'encodait la
## transition HORIZONTALE : la silhouette se lit sur l'EMPREINTE, donc une case d'herbe dont la
## voisine est la falaise de son propre massif a ce bit MIS, se croit pleine, et rend la tuile
## d'interieur qui se repete partout. Sa voisine de roche fait de meme. La frontiere n'est
## dessinee par personne, et la roche s'arrete net (releve par l'utilisateur, massif 21).
##
## ⚠ ET LES DEUX COTES SE RESERVENT, PAS SEULEMENT LA ROCHE (decision utilisateur). La loi
## « un flanc qui s'arrete ne se creuse pas, il se trait » ne demandait que la roche ; mais une
## frontiere tracee d'un seul cote se voit, et le rendu semble faux. C'est un jugement de
## peintre, et c'est lui qui tranche ici.
##
## Rend `{(coupe << 24) | (bande << 8) | silhouette: [bits de fenetre]}`.
static func shear_witnesses() -> Dictionary:
	var found: Dictionary = {}
	for bits: int in range(1 << (COLS * ROWS)):
		var surface: Array[PackedByteArray] = _window(bits)
		if _thin_inside(surface):
			continue
		var here: Dictionary = {}
		var cuts: Dictionary = {}
		_couples_of(surface, here, cuts)
		for key: int in cuts.keys():
			if not found.has(key):
				found[key] = [] as Array[int]
			(found[key] as Array[int]).append(bits)
	return found


## LE VOCABULAIRE SI LE CISAILLEMENT ENTRE DANS L'IDENTITE DE LA TUILE.
## Cle : `(coupe << 24) | (ras << 16) | (bande << 8) | silhouette`.
static func shear_vocabulary() -> Array[int]:
	var found: Dictionary = {}
	for key: int in shear_witnesses().keys():
		var cut: int = key >> 24
		var band: int = (key >> 8) & 0xff
		var sil: int = key & 0xff
		var bits: int = (Massifs.CUT_WEST if (cut & 1) != 0 else 0) 				| (Massifs.CUT_EAST if (cut & 2) != 0 else 0) 				| (Massifs.CUT_NORTH if (cut & 4) != 0 else 0)
		found[Massifs.key(band, sil, false, bits)] = true
		found[Massifs.key(band, sil, true, bits)] = true
	var out: Array[int] = []
	out.assign(found.keys())
	out.sort()
	return out


## LA FENETRE ETIREE : la fenetre 3x6, bordee en repliquant ses bords vers l'exterieur.
##
## ⚠ ET L'ETIREMENT EST CE QUI GARANTIT L'EPAISSEUR, sans une seule boucle de reparation. Toute
## course de la fenetre se prolonge dehors d'au moins deux cases, donc en fait au moins trois ;
## et une course d'UNE case au milieu etait deja refusee par la refutation locale. C'est le meme
## argument que l'ilot etire de l'ancienne planche de preuve.
static func stretched(bits: int, pad: int = 2) -> Array[PackedByteArray]:
	var window: Array[PackedByteArray] = _window(bits)
	var out: Array[PackedByteArray] = []
	for x: int in range(COLS + 2 * pad):
		var col: PackedByteArray = PackedByteArray()
		col.resize(ROWS + 2 * pad)
		for y: int in range(ROWS + 2 * pad):
			col[y] = window[clampi(x - pad, 0, COLS - 1)][clampi(y - pad, 0, ROWS - 1)]
		out.append(col)
	return out


## LE VOCABULAIRE COMPLET : chaque couple, une fois s'il se dessine pareil au ras et en liberte,
## deux fois sinon. La cle est `(ras << 16) | (bande << 8) | silhouette`.
## ⚠ ET LA FORME EST L'UNION DE L'ENUMERATION ET DES TEMOINS TROUVES. La fenetre de six rangees
## suffisait tant qu'une jupe faisait trois rangees ; depuis que la chute va jusqu'au sol qu'elle
## atteint, une chute de six ou neuf a sa LEVRE HORS DE LA FENETRE, et l'enumeration ne voit plus
## ses derniers corps. L'enumerer demanderait une fenetre de douze rangees -- 2^36 -- ou de
## traiter les chutes deja en cours, ce qui coute des centaines de millions de combinaisons.
##
## On ferme donc la boucle par l'autre bout : ce que la BATTUE a trouve et qu'un temoin porte
## entre dans la forme. Ce n'est pas circulaire -- une tuile posee qui n'est ni enumeree ni
## portee par un temoin fait rougir I8, et la reponse est alors d'aller lui chercher un temoin,
## pas de baisser la barre. La forme reste ce qu'on sait PEINDRE.
## ⚠ ET ELLE PORTE LE CISAILLEMENT DEPUIS QU'IL EST DANS LA CLE. Sans lui, I8 -- « toute tuile
## posee est dans la forme close » -- rougirait sur chaque tuile cisaillee, alors que ce sont
## exactement les tuiles qu'on vient d'ajouter au modele. Une forme close qui ne connait pas la
## cle qu'elle juge ne juge rien.
static func vocabulary() -> Array[int]:
	var found: Dictionary = {}
	for tile: int in Witnesses.blocks().keys():
		found[int(tile)] = true
	for tile2: int in shear_vocabulary():
		found[tile2] = true
	var out: Array[int] = []
	out.assign(found.keys())
	out.sort()
	return out


## LES FENETRES D'UNE TUILE, une fois le dessin canonicalise.
##
## ⚠ ET UNE TUILE PEUT VENIR DE PLUSIEURS COUPLES. Au ras, cinq silhouettes rendent le meme
## dessin : remonter d'une tuile vers « son » couple n'a plus de sens, il faut LES couples. Sans
## cette table, chercher l'ilot d'une tuile au ras cherchait une cle qui n'existe pas.
## ⚠ ET ELLE LIT L'ENUMERATION CISAILLEE, PAS L'AUTRE. C'est elle qui donne au batisseur du
## guide, pour chaque tuile, une fenetre qui la produit : branchee sur l'enumeration sans
## cisaillement, elle ne trouverait d'ilot pour AUCUNE tuile cisaillee, et le guide les
## laisserait impeignables sans que rien ne le dise.
static func sources(flush: bool) -> Dictionary:
	var wits: Dictionary = shear_witnesses()
	var out: Dictionary = {}
	for key: int in wits.keys():
		var cut: int = key >> 24
		var bits_of: int = (Massifs.CUT_WEST if (cut & 1) != 0 else 0) 				| (Massifs.CUT_EAST if (cut & 2) != 0 else 0) 				| (Massifs.CUT_NORTH if (cut & 4) != 0 else 0)
		var tile: int = Massifs.key((key >> 8) & 0xff, key & 0xff, flush, bits_of)
		if not out.has(tile):
			out[tile] = [] as Array[int]
		for bits: int in (wits[key] as Array[int]):
			(out[tile] as Array[int]).append(bits)
	return out


## ⚠ GARDE COMME TRACE, ET FAUSSE : elle repondait « oui » pour un coin rentrant, alors qu'AU
## RAS un coin rentrant ne se creuse pas plus qu'un bord -- la profondeur y est nulle. C'est
## `Massifs.key` qui tranche desormais, en canonicalisant le dessin.
static func varies(sil: int) -> bool:
	for card: int in [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]:
		if (sil & card) == 0:
			return true
	for corner: int in range(4):
		var a: int = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W][corner]
		var b: int = [BlobIndex.W, BlobIndex.N, BlobIndex.E, BlobIndex.S][corner]
		var d: int = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW][corner]
		if (sil & a) != 0 and (sil & b) != 0 and (sil & d) == 0:
			return true
	return false


static func _window(bits: int) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	for x: int in range(COLS):
		var col: PackedByteArray = PackedByteArray()
		col.resize(ROWS)
		for y: int in range(ROWS):
			col[y] = 1 if (bits & (1 << (x * ROWS + y))) != 0 else 0
		out.append(col)
	return out


## LA REFUTATION LOCALE : une course dont LES DEUX BOUTS sont dans la fenetre et qui fait moins
## de trois. Une course qui touche un bord de la fenetre se prolonge dehors, donc elle ne prouve
## rien -- c'est le meme argument, mot pour mot, que celui des 27 silhouettes.
static func _thin_inside(surface: Array[PackedByteArray]) -> bool:
	for x: int in range(COLS):
		var run: int = 0
		var state: int = -1
		for y: int in range(ROWS):
			var here: int = int(surface[x][y])
			if here == state:
				run += 1
				continue
			if state != -1 and run < 3 and y - run > 0:
				return true
			state = here
			run = 1
	# A l'horizontale la fenetre n'a que trois colonnes : la seule course entierement dedans est
	# celle d'UNE case au milieu, bornee des deux cotes.
	for y2: int in range(ROWS):
		if int(surface[CX][y2]) != int(surface[0][y2]) \
				and int(surface[CX][y2]) != int(surface[2][y2]):
			return true
	return false


## LES COUPLES QUE CETTE FENETRE PRODUIT.
##
## ⚠ ET LE MASSIF SE CHOISIT, IL NE SE SUPPOSE PAS. Deux cases de surface qui se touchent sont
## forcement le MEME massif -- une composante connexe ne se coupe pas. Mais deux composantes
## distinctes de la fenetre peuvent aussi bien etre reliees DEHORS : les deux lectures sont
## realisables, donc on prend les deux. Les supposer separees sous-compterait la forme.
## ⚠ `cuts` EST UNE SORTIE DE PLUS, PAS UN AUTRE PARCOURS. Le cisaillement se lit sur la MEME
## fenetre et le MEME plan de chute que le couple : l'enumerer a part demanderait une seconde
## copie de cette fonction, et deux copies d'une enumeration finissent toujours par diverger.
## Cle : `(coupe << 24) | (bande << 8) | silhouette`, coupe = bit 0 l'ouest, bit 1 l'est.
static func _couples_of(surface: Array[PackedByteArray], out: Dictionary,
		cuts: Dictionary = {}) -> void:
	var mark: Array[PackedByteArray] = _components(surface)
	var mine: int = -1
	if int(surface[CX][CY]) == 1:
		mine = int(mark[CX][CY])
	else:
		for step: int in range(1, ROWS):
			var at: int = CY - step
			if at < 0:
				break
			if int(surface[CX][at]) == 1 and int(surface[CX][at + 1]) == 0:
				mine = int(mark[CX][at])
				break
	if mine < 0:
		return
	var others: Array[int] = []
	for x: int in range(COLS):
		for y: int in range(ROWS):
			if int(surface[x][y]) == 1 and int(mark[x][y]) != mine 					and not others.has(int(mark[x][y])):
				others.append(int(mark[x][y]))
	for choice: int in range(1 << others.size()):
		var joined: Dictionary = {mine: true}
		for at2: int in range(others.size()):
			if (choice & (1 << at2)) != 0:
				joined[others[at2]] = true
		var lips: Array[Vector2i] = []
		for x2: int in range(COLS):
			for y2: int in range(ROWS):
				if int(surface[x2][y2]) == 0 or not joined.has(int(mark[x2][y2])):
					continue
				if y2 + 1 < ROWS and int(surface[x2][y2 + 1]) == 1 						and joined.has(int(mark[x2][y2 + 1])):
					continue
				lips.append(Vector2i(x2, y2))
		# ⚠ ET CHAQUE LEVRE PEUT TOMBER DE TROIS, SIX OU NEUF -- ET ATTERRIR OU NON. La chute
		# n'est plus forfaitaire : un massif porte qui deborde tombe jusqu'au sol qu'il atteint,
		# et une chute qui ne trouve rien NE POSE PAS SON PIED. Ce qui reste une BORNE HAUTE :
		# certaines combinaisons ne sont pas realisables, et c'est l'autre sens du controle qui
		# le dira.
		var plans: int = 1
		for _one: Vector2i in lips:
			plans *= 6
		for plan: int in range(plans):
			var band_of: Dictionary = _footprint(surface, mark, joined, lips, plan)
			if not band_of.has(Vector2i(CX, CY)):
				continue
			var raw: int = 0
			for bit: int in range(8):
				if band_of.has(Vector2i(CX, CY) + BlobIndex.OFFSETS[bit]):
					raw |= 1 << bit
			var couple: int = (int(band_of[Vector2i(CX, CY)]) << 8) 					| BlobIndex.canonicalize(raw)
			out[couple] = true
			# LE CISAILLEMENT : de l'herbe et de la roche du MEME massif, cote a cote.
			#
			# ⚠ ET « MEME MASSIF » EST ACQUIS ICI SANS RIEN DE PLUS : `band_of` ne porte que les
			# composantes JOINTES, donc une voisine qui s'y trouve est du meme massif par
			# construction. C'est ce qui rend la propriete LOCALE, donc enumerable : la colonne
			# voisine dont la levre est plus haute est reliee a la mienne par la rangee de cette
			# levre, qui est dans la fenetre.
			var centre: Vector2i = Vector2i(CX, CY)
			var grass: bool = int(band_of[centre]) == Massifs.SURFACE
			# ⚠ TROIS DIRECTIONS, PAS DEUX, DEPUIS LE 06/09 : le nord aussi. Et il ne se lit
			# que pour l'HERBE -- une falaise a toujours du massif au-dessus d'elle, et la
			# bande le dit deja ; lire le nord des deux cotes marquerait tous les chapiteaux.
			var cut: int = 0
			for k: int in range(2):
				var near2: Vector2i = centre + (Vector2i.LEFT if k == 0 else Vector2i.RIGHT)
				if not band_of.has(near2):
					continue
				if (int(band_of[near2]) == Massifs.SURFACE) != grass:
					cut |= 1 << k
			if grass and band_of.has(centre + Vector2i.UP) 					and int(band_of[centre + Vector2i.UP]) != Massifs.SURFACE:
				cut |= 1 << 2
			cuts[(cut << 24) | couple] = true


static func _footprint(surface: Array[PackedByteArray], mark: Array[PackedByteArray],
		joined: Dictionary, lips: Array[Vector2i], plan: int) -> Dictionary:
	var out: Dictionary = {}
	for x: int in range(COLS):
		for y: int in range(ROWS):
			if int(surface[x][y]) == 1 and joined.has(int(mark[x][y])):
				out[Vector2i(x, y)] = Massifs.SURFACE
	var rest: int = plan
	for lip: Vector2i in lips:
		var choice: int = rest % 6
		rest /= 6
		var fall: int = Massifs.FALL * (1 + choice / 2)
		var landed: bool = (choice % 2) == 0
		for step: int in range(1, fall + 1):
			var below: Vector2i = lip + Vector2i(0, step)
			if below.y >= ROWS:
				break
			if out.has(below):
				continue
			out[below] = Massifs.CHAPITEAU if step == 1 else (
					Massifs.PIED if (landed and step == fall) else Massifs.CORPS)
	return out


static func _components(surface: Array[PackedByteArray]) -> Array[PackedByteArray]:
	var mark: Array[PackedByteArray] = []
	for x: int in range(COLS):
		var col: PackedByteArray = PackedByteArray()
		col.resize(ROWS)
		col.fill(255)
		mark.append(col)
	var next: int = 0
	for x2: int in range(COLS):
		for y2: int in range(ROWS):
			if int(surface[x2][y2]) == 0 or int(mark[x2][y2]) != 255:
				continue
			var stack: Array[Vector2i] = [Vector2i(x2, y2)]
			mark[x2][y2] = next
			while not stack.is_empty():
				var here: Vector2i = stack.pop_back()
				for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
					var near: Vector2i = here + step
					if near.x < 0 or near.y < 0 or near.x >= COLS or near.y >= ROWS:
						continue
					if int(surface[near.x][near.y]) == 0 or int(mark[near.x][near.y]) != 255:
						continue
					mark[near.x][near.y] = next
					stack.append(near)
			next += 1
	return mark
