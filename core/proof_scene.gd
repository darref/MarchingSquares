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

const ISLAND: int = 3
const COLUMNS: int = 8
const PITCH_X: int = ISLAND + 1
const PITCH_Y: int = ISLAND + 4

## L'ilot de la famille A CHEVAL : un simple bloc de 2 x 2 cases. Une tuile de croisement ne
## depend que des quatre cases qu'elle chevauche -- l'ilot EST donc la tuile, sans voisinage
## a mettre en scene. Cinq par rangee suffisent a poser les quinze.
## La marge de vide autour de la planche : une chute entiere, pour que la falaise du bord
## du monde tombe DANS le cadre.
const VOID_MARGIN: int = 3

const DUAL_ISLAND: int = 2
const DUAL_COLUMNS: int = 5
const DUAL_PITCH_X: int = DUAL_ISLAND + 1
const DUAL_PITCH_Y: int = DUAL_ISLAND + 4

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
const WALL_DEMO: Array[String] = [
	"22222222..22222222",
	"22222222..22222222",
	"2.22.2.2..2.22.2.2",
	"..................",
	"..................",
	"..................",
	"1.11.1.1..........",
	"..................",
	"..................",
	"..................",
	"..................",
]

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
	width = maxi(width, WALL_DEMO[0].length() + 2)
	var height: int = wall_top + WALL_DEMO.size() + 1

	# ⚠ LA PLANCHE S'ENTOURE DE VIDE, ELLE AUSSI. La plaine est un plateau : au bord du
	# monde elle a une falaise de trois cases, et sans marge celle-ci tomberait hors du
	# cadre. La marge vaut donc une chute entiere.
	width += 2 * VOID_MARGIN
	height += 2 * VOID_MARGIN
	var blank: String = HeightMask.VOID_CHAR.repeat(width)
	var cells: Array = []
	for y: int in range(height):
		var row: PackedByteArray = blank.to_utf8_buffer()
		cells.append(row)
	for y: int in range(VOID_MARGIN, height - VOID_MARGIN):
		for x: int in range(VOID_MARGIN, width - VOID_MARGIN):
			_put(cells, x, y, 0)

	for order: int in range(indices.size()):
		var origin: Vector2i = island_origin(order, family)
		if dual:
			_stamp_dual(cells, indices[order], origin)
		else:
			_stamp_island(cells, indices[order], origin)

	var wall_left: int = maxi(0, (width - WALL_DEMO[0].length()) / 2)
	wall_top += VOID_MARGIN
	for y: int in range(WALL_DEMO.size()):
		for x: int in range(WALL_DEMO[y].length()):
			var glyph: String = WALL_DEMO[y][x]
			if glyph != ".":
				_put(cells, wall_left + x, wall_top + 1 + y, glyph.to_int())

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
		by_index[indices[order]] = island_origin(order, family) + Vector2i(1, 1)
	return by_index


## Pose un ilot : la case centrale, plus une case par bit de l'index.
##
## ⚠ L'ILOT EST CONSTRUIT DEPUIS L'INDEX, PAS L'INVERSE. Le voisinage de son centre est donc
## exactement l'index voulu, par construction et non par verification -- et le test le
## reverifie quand meme, puisque c'est le genre d'evidence qui se revele fausse.
static func _stamp_island(cells: Array, index: int, origin: Vector2i) -> void:
	_put(cells, origin.x + 1, origin.y + 1, 1)
	for bit: int in range(8):
		if (index & (1 << bit)) == 0:
			continue
		var offset: Vector2i = BlobIndex.OFFSETS[bit]
		_put(cells, origin.x + 1 + offset.x, origin.y + 1 + offset.y, 1)


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
		_put(cells, origin.x + 1 + at.x, origin.y + 1 + at.y, 1)


static func _put(cells: Array, x: int, y: int, level: int) -> void:
	if y < 0 or y >= cells.size():
		return
	var row: PackedByteArray = cells[y]
	if x < 0 or x >= row.size():
		return
	row[x] = ZERO + level
	cells[y] = row
