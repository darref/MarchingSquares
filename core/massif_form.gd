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
static func vocabulary() -> Array[int]:
	var found: Dictionary = {}
	for couple: int in couples():
		var band: int = (couple >> 8) & 0xff
		found[Massifs.key(band, couple & 0xff, false)] = true
		found[Massifs.key(band, couple & 0xff, true)] = true
	var out: Array[int] = []
	out.assign(found.keys())
	out.sort()
	return out


## LES FENETRES D'UNE TUILE, une fois le dessin canonicalise.
##
## ⚠ ET UNE TUILE PEUT VENIR DE PLUSIEURS COUPLES. Au ras, cinq silhouettes rendent le meme
## dessin : remonter d'une tuile vers « son » couple n'a plus de sens, il faut LES couples. Sans
## cette table, chercher l'ilot d'une tuile au ras cherchait une cle qui n'existe pas.
static func sources(flush: bool) -> Dictionary:
	var wits: Dictionary = witnesses()
	var out: Dictionary = {}
	for couple: int in wits.keys():
		var tile: int = Massifs.key((couple >> 8) & 0xff, couple & 0xff, flush)
		if not out.has(tile):
			out[tile] = [] as Array[int]
		for bits: int in (wits[couple] as Array[int]):
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
static func _couples_of(surface: Array[PackedByteArray], out: Dictionary) -> void:
	var mark: Array[PackedByteArray] = _components(surface)
	var mine: int = -1
	if int(surface[CX][CY]) == 1:
		mine = int(mark[CX][CY])
	else:
		for step: int in range(1, Massifs.FALL + 1):
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
			if int(surface[x][y]) == 1 and int(mark[x][y]) != mine \
					and not others.has(int(mark[x][y])):
				others.append(int(mark[x][y]))
	for choice: int in range(1 << others.size()):
		var joined: Dictionary = {mine: true}
		for at2: int in range(others.size()):
			if (choice & (1 << at2)) != 0:
				joined[others[at2]] = true
		var band_of: Dictionary = _footprint(surface, mark, joined)
		if not band_of.has(Vector2i(CX, CY)):
			continue
		var raw: int = 0
		for bit: int in range(8):
			if band_of.has(Vector2i(CX, CY) + BlobIndex.OFFSETS[bit]):
				raw |= 1 << bit
		out[(int(band_of[Vector2i(CX, CY)]) << 8) | BlobIndex.canonicalize(raw)] = true


static func _footprint(surface: Array[PackedByteArray], mark: Array[PackedByteArray],
		joined: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for x: int in range(COLS):
		for y: int in range(CY - 1, CY + 2):
			if y < 0 or y >= ROWS:
				continue
			if int(surface[x][y]) == 1 and joined.has(int(mark[x][y])):
				out[Vector2i(x, y)] = Massifs.SURFACE
				continue
			for step: int in range(1, Massifs.FALL + 1):
				var at: int = y - step
				if at < 0:
					break
				if int(surface[x][at]) == 1 and joined.has(int(mark[x][at])) \
						and (at + 1 >= ROWS or int(surface[x][at + 1]) == 0
						or not joined.has(int(mark[x][at + 1]))):
					out[Vector2i(x, y)] = step
					break
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
