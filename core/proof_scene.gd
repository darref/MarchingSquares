# LA PLANCHE DE PREUVE — chaque cas, isole, a une place connue d'avance.
#
# Un acheteur qui recoit une feuille de 47 tuiles ne peut pas verifier que ce sont bien
# TOUS les cas : il voit 47 dessins, il ne voit pas qu'il n'en manque aucun. Cette planche
# le lui montre. Elle pose un ilot de 3x3 par index, construit depuis les BITS de l'index
# lui-meme, et chaque ilot porte en son centre exactement la tuile annoncee. On peut donc
# pointer du doigt : « la, c'est l'index 117, N+E+S+SW+W ».
#
# ⚠ ELLE EST CALCULEE, JAMAIS DESSINEE. Meme raison que `BlobIndex.CANONICAL_INDICES` : un
# relief ecrit a la main serait une donnee a maintenir et un endroit ou mentir. Ici, si la
# regle de canonicalisation changeait, la planche changerait avec elle -- il n'existe aucun
# etat ou la preuve et la regle divergent.
#
# ⚠ LES ILOTS SUIVENT L'ORDRE DE LA PLANCHE EXPORTEE : index croissant, huit par rangee.
# Poser la feuille de tuiles a cote de la preuve fait correspondre les cases une a une.
#
# ⚠ UN ILOT NE DOIT PAS DEBORDER SUR SON VOISIN. Un voisinage porte a une case de distance :
# une colonne de garde suffit a l'horizontale. A la verticale il en faut quatre -- trois
# pour laisser tomber la robe de l'ilot, une pour respirer.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Families := preload("res://core/families.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")

## ⚠ L'ILOT EPAIS FAIT SEPT, ET IL EST ETIRE, PAS REPARE. Un ilot reduit a sa fenetre
## 3x3 canonique est fin presque partout -- c'est exactement ce que le mode interdit.
## L'ilot se batit depuis la PLUS PETITE FENETRE REALISABLE de l'index (les coins caches
## que la canonicalisation jette), ETIREE : chaque case du 7x7 prend l'etat de la case de
## fenetre la plus proche vers le centre (clamp des coordonnees). Toute course y fait
## mecaniquement au moins trois -- une course courte exigerait une cardinale sans
## partenaire lateral du meme etat, exactement ce que la realisabilite rejette. C'est un
## theoreme, pas une reparation, et la fenetre du centre -- la preuve -- ne bouge pas.
const ISLAND: int = 7
const COLUMNS: int = 8
const PITCH_X: int = ISLAND + 3
const PITCH_Y: int = ISLAND + 5

## L'ilot de la famille A CHEVAL : un simple bloc de 2 x 2 cases. Une tuile de croisement ne
## depend que des quatre cases qu'elle chevauche -- l'ilot EST donc la tuile, sans voisinage
## a mettre en scene. Cinq par rangee suffisent a poser les quinze.
## La marge de vide autour de la planche : une chute entiere, pour que la falaise du bord
## du monde tombe DANS le cadre.
const VOID_MARGIN: int = 3

## ⚠ LA MARGE BASSE VAUT UNE CHUTE D'ETAGE 1 DANS LE VIDE : six rangees, pas trois. Le
## bloc cotier de la tour du cap borde le vide ; sa robe tombe d'un etage de plus sans
## poser son pied -- 3 x (1 + 1) rangees -- et une marge de trois l'aurait fait sortir
## du cadre, c'est-a-dire rendue impeignable.
const DEEP_MARGIN: int = 6

## ⚠ L'ILOT DUAL EPAIS FAIT SIX : chaque quadrant plein est un bloc 3x3 qui s'etend en
## S'ELOIGNANT du croisement. Le croisement ne lit que ses quatre cases adjacentes -- sa
## config ne bouge pas -- mais un bloc plus petit serait fin, et la planche est un relief
## epais comme les autres.
const DUAL_ISLAND: int = 6
const DUAL_COLUMNS: int = 5
const DUAL_PITCH_X: int = DUAL_ISLAND + 3
const DUAL_PITCH_Y: int = DUAL_ISLAND + 5

## LA DEMONSTRATION DE FALAISE : deux peignes.
##
## Une simple butte ne montrait que trois pans. Depuis que le pan est le couple de ses deux
## flancs, il en faut neuf, et pour cela des faces MITOYENNES DE PROFONDEURS DIFFERENTES --
## c'est-a-dire un bord sud dente. Le motif des dents produit les neuf pans.
##
## ⚠ DEUX PEIGNES, PAS UN. A gauche les dents atterrissent sur une banquette : elles tombent
## de trois cases et posent leur PIED pendant que la voisine est encore en plein corps. A
## droite, pas de banquette : elles tombent de six et passent donc par le CORPS 1, ce que
## trois cases ne font jamais. Ni l'un ni l'autre ne suffit seul.
##
## ⚠ ET LA BANQUETTE EST QUATRE RANGEES SOUS LA LEVRE, pas trois : `fall_at` sonde la case
## juste sous le pied, jamais celles que la robe traverse.
##
## ⚠ ET UNE PAIRE QUI N'ATTERRIT PAS, tout a droite : une masse, UNE case de creux, deux
## piliers du meme etage. Leurs robes sont ecretees au premier pas -- c'est la POSE
## DERRIERE que cette paire existe pour montrer. Sans elle, la planche n'exprimait pas la
## famille de « l'angle noir » : toutes ses dents atterrissaient, et elle n'aurait pu ni
## montrer le defaut ni prouver son correctif.
## ⚠ LES PEIGNES SONT MORTS AVEC LE MODE EPAIS : leurs dents d'une colonne etaient fines.
## La demonstration reprend la geometrie PROUVEE du guide, en miniature -- CINQ
## accidents epais qui portent a eux seuls les 25 roles :
##   - l'escarpement a banquette : eperons TRIPLES, terrasses 3x3 exactement sous eux --
##     les pieds a angle, poses pendant que la paroi voisine tombe encore ;
##   - l'escarpement profond : chute de six, eperons triples -- les corps 1 a angle ;
##   - la gorge decalee : une chute longee par des murs a d'autres hauteurs --
##     (vide,vide) corps 1 et pied ;
##   - la tour du cap : la chute qui N'ATTERRIT PAS, calee sur le bord du monde de la
##     planche -- (vide,vide) corps 0, son dernier pas est un corps seul en profondeur ;
##   - les DEUX REDANS, les roles que min trois a reveles : un bord sud a decrochement
##     d'une rangee sur un tablier partiel -- (vide,devant) et (devant,vide) corps 1.
const DEMO_WIDTH: int = 71
const DEMO_HEIGHT: int = 15

## Le code du caractere « 0 » : un etage N s'ecrit ZERO + N.
const ZERO: int = 48


## Le relief de la planche.
static func relief(family: StringName = Families.BY_CELL) -> PackedStringArray:
	var indices: PackedInt32Array = Families.surface_indices(family)
	var dual: bool = family == Families.BY_CORNER
	var columns: int = DUAL_COLUMNS if dual else COLUMNS
	var pitch_x: int = DUAL_PITCH_X if dual else PITCH_X
	var pitch_y: int = DUAL_PITCH_Y if dual else PITCH_Y
	var island_rows: int = (indices.size() + columns - 1) / columns
	var width: int = columns * pitch_x
	var wall_top: int = island_rows * pitch_y
	width = maxi(width, DEMO_WIDTH + 2)
	var height: int = wall_top + DEMO_HEIGHT + 1

	# ⚠ LA PLANCHE S'ENTOURE DE VIDE, ELLE AUSSI. La plaine est un plateau : au bord du
	# monde elle a une falaise de trois cases, et sans marge celle-ci tomberait hors du
	# cadre. La marge vaut donc une chute entiere.
	width += 2 * VOID_MARGIN
	height += VOID_MARGIN + DEEP_MARGIN
	var blank: String = HeightMask.VOID_CHAR.repeat(width)
	var cells: Array = []
	for y: int in range(height):
		var row: PackedByteArray = blank.to_utf8_buffer()
		cells.append(row)
	for y: int in range(VOID_MARGIN, height - DEEP_MARGIN):
		for x: int in range(VOID_MARGIN, width - VOID_MARGIN):
			_put(cells, x, y, 0)

	for order: int in range(indices.size()):
		var origin: Vector2i = island_origin(order, family)
		if dual:
			_stamp_dual(cells, indices[order], origin)
		else:
			_stamp_island(cells, indices[order], origin)

	var wall_left: int = maxi(0, (width - DEMO_WIDTH) / 2)
	# ⚠ LE BAS DE LA DEMONSTRATION EST LA DERNIERE RANGEE DE PLAINE. La tour du cap sonde
	# le vide sous son pied -- c'est ce qui fait son (vide,vide) corps 0 -- donc sa chute
	# doit finir exactement au bord du monde de la planche.
	var demo_top: int = height - DEEP_MARGIN - DEMO_HEIGHT
	_stamp_wall_demo(cells, wall_left, demo_top)

	var rows: PackedStringArray = PackedStringArray()
	for row: PackedByteArray in cells:
		rows.append(row.get_string_from_utf8())
	return rows


## Le coin haut-gauche de l'ilot de rang [param order].
static func island_origin(order: int,
		family: StringName = Families.BY_CELL) -> Vector2i:
	var shift: Vector2i = Vector2i(VOID_MARGIN, VOID_MARGIN)
	if family == Families.BY_CORNER:
		return shift + Vector2i((order % DUAL_COLUMNS) * DUAL_PITCH_X,
				(order / DUAL_COLUMNS) * DUAL_PITCH_Y)
	return shift + Vector2i((order % COLUMNS) * PITCH_X, (order / COLUMNS) * PITCH_Y)


## Ou lire chaque index sur la planche : index -> case centrale de son ilot.
##
## C'est ce qui rend la preuve verifiable case par case, et c'est ce qui permettra plus tard
## d'ecrire les numeros a cote des ilots.
static func centres(family: StringName = Families.BY_CELL) -> Dictionary:
	var by_index: Dictionary = {}
	var indices: PackedInt32Array = Families.surface_indices(family)
	for order: int in range(indices.size()):
		by_index[indices[order]] = island_origin(order, family) + Vector2i(3, 3)
	return by_index


## Pose un ilot EPAIS : la plus petite fenetre realisable de l'index, etiree.
##
## ⚠ L'ILOT EST CONSTRUIT DEPUIS L'INDEX, PAS L'INVERSE. Le voisinage de son centre est donc
## exactement l'index voulu, par construction et non par verification -- et le test le
## reverifie quand meme, puisque c'est le genre d'evidence qui se revele fausse.
static func _stamp_island(cells: Array, index: int, origin: Vector2i) -> void:
	for offset: Vector2i in _thick_island(index):
		_put(cells, origin.x + 3 + offset.x, origin.y + 3 + offset.y, 1)


static var _islands: Dictionary = {}


## Les cases d'un ilot epais, autour de son centre (0,0).
##
## L'ETIREMENT, calcule et prouve :
##   1. la PLUS PETITE fenetre brute realisable dont la canonicalisation donne l'index --
##      ses coins caches sont exactement les appuis que la canonicalisation jette ;
##   2. chaque case du 7x7 prend l'etat de la case de fenetre la plus proche vers le
##      centre : l'etat de (clamp(x), clamp(y)). Le plan se partage en neuf secteurs
##      constants -- la fenetre etiree -- et toute course y fait au moins trois : une
##      course courte exigerait, au milieu d'une colonne ou d'une rangee, une case
##      differente de ses deux voisines, c'est-a-dire une cardinale sans partenaire
##      lateral du meme etat -- ce que la realisabilite rejette. Les courses vides du
##      bord s'ouvrent sur l'exterieur de l'ilot, qui est vide.
static func _thick_island(index: int) -> Array[Vector2i]:
	if _islands.has(index):
		return _islands[index]
	var raw: int = -1
	for candidate: int in range(256):
		if BlobIndex.canonicalize(candidate) == index and Thickness.window_realizable(candidate):
			raw = candidate
			break
	var window: Dictionary = {Vector2i.ZERO: true}
	if raw >= 0:
		for bit: int in range(8):
			if (raw & (1 << bit)) != 0:
				window[BlobIndex.OFFSETS[bit]] = true
	var out: Array[Vector2i] = []
	for y: int in range(-3, 4):
		for x: int in range(-3, 4):
			if window.has(Vector2i(clampi(x, -1, 1), clampi(y, -1, 1))):
				out.append(Vector2i(x, y))
	out.sort()
	_islands[index] = out
	return out


## ⚠ UN PackedByteArray SE COPIE QUAND ON L'AFFECTE. Modifier la copie locale ne touchait
## pas la rangee rangee dans le tableau, et la planche sortait vierge sans une seule erreur.
## On la repose explicitement.
## L'ILOT D'UN CROISEMENT : les quatre cases qu'il chevauche, remplies selon ses quatre bits.
##
## ⚠ ICI L'ILOT EST LA TUILE. Une tuile de croisement ne depend QUE de ces quatre cases : il
## n'y a pas de voisinage a mettre en scene, contrairement au blob dont l'ilot 3x3 doit
## porter huit voisins autour d'un centre.
static func _stamp_dual(cells: Array, index: int, origin: Vector2i) -> void:
	for bit: int in range(CornerIndex.BITS.size()):
		if (index & CornerIndex.BITS[bit]) == 0:
			continue
		var at: Vector2i = CornerIndex.OFFSETS[bit]
		# Le bloc 3x3 du quadrant s'etend en s'ELOIGNANT du croisement : les huit cases
		# ajoutees ne le touchent pas, sa config reste exactement l'index.
		var away: Vector2i = Vector2i(-1 if at.x < 0 else 1, -1 if at.y < 0 else 1)
		for dy: int in range(3):
			for dx: int in range(3):
				_put(cells, origin.x + 3 + at.x + dx * away.x,
						origin.y + 3 + at.y + dy * away.y, 1)


## Les cinq accidents de la demonstration, aux geometries PROUVEES par le guide epais.
static func _stamp_wall_demo(cells: Array, left: int, top: int) -> void:
	# L'escarpement a banquette : eperons triples y4, terrasses 3x3 quatre rangees sous
	# leur levre -- jamais sous leurs voisines, qui doivent tomber encore.
	_block(cells, left + 0, top + 0, 16, 4, 2)
	_block(cells, left + 3, top + 4, 3, 1, 2)
	_block(cells, left + 10, top + 4, 3, 1, 2)
	_block(cells, left + 3, top + 8, 3, 3, 1)
	_block(cells, left + 10, top + 8, 3, 3, 1)
	# L'escarpement profond : chute de six d'un trait, eperons triples.
	_block(cells, left + 19, top + 0, 17, 5, 2)
	_block(cells, left + 23, top + 5, 3, 1, 2)
	_block(cells, left + 30, top + 5, 3, 1, 2)
	# La gorge decalee : la colonne ouest de l'etage 2 chute seule, longee par les murs
	# du bloc d'etage 1 decale d'une colonne a l'est.
	_block(cells, left + 39, top + 0, 4, 5, 2)
	_block(cells, left + 40, top + 5, 4, 4, 1)
	# La tour du cap : une colonne atterrit court sur le bloc decale, l'autre plonge de
	# six jusqu'au vide sans poser son pied -- son dernier pas est un corps.
	_block(cells, left + 48, top + 4, 3, 5, 2)
	_block(cells, left + 47, top + 9, 3, 4, 1)
	# Les deux redans : le decrochement d'une rangee sur tablier partiel -- la colonne
	# entre tablier et retrait plonge seule, (vide,devant) corps 1 -- et son miroir.
	_block(cells, left + 54, top + 0, 7, 4, 2)
	_block(cells, left + 54, top + 4, 5, 1, 2)
	_block(cells, left + 54, top + 5, 4, 4, 1)
	_block(cells, left + 64, top + 0, 7, 4, 2)
	_block(cells, left + 66, top + 4, 5, 1, 2)
	_block(cells, left + 67, top + 5, 4, 4, 1)


static func _block(cells: Array, x0: int, y0: int, w: int, h: int, level: int) -> void:
	for y: int in range(y0, y0 + h):
		for x: int in range(x0, x0 + w):
			_put(cells, x, y, level)


static func _put(cells: Array, x: int, y: int, level: int) -> void:
	if y < 0 or y >= cells.size():
		return
	var row: PackedByteArray = cells[y]
	if x < 0 or x >= row.size():
		return
	row[x] = ZERO + level
	cells[y] = row
