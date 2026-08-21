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

const ISLAND: int = 3
const COLUMNS: int = 8
const PITCH_X: int = ISLAND + 1
const PITCH_Y: int = ISLAND + 4

## La demonstration de falaise : une butte a deux etages, assez large pour montrer les trois
## pans, assez haute pour que la chute de six cases fasse passer les DEUX rangees de corps.
## C'est la seule facon d'obtenir les douze roles d'un seul bloc.
const WALL_WIDTH: int = 5
const WALL_HEIGHT: int = 2
const WALL_LEVEL: int = 2

## Le code du caractere « 0 » : un etage N s'ecrit ZERO + N.
const ZERO: int = 48


## Le relief de la planche.
static func relief() -> PackedStringArray:
	var indices: PackedInt32Array = BlobIndex.CANONICAL_INDICES
	var island_rows: int = (indices.size() + COLUMNS - 1) / COLUMNS
	var width: int = COLUMNS * PITCH_X
	var wall_top: int = island_rows * PITCH_Y
	# La butte tombe de STOREY_TILES x son etage : il lui faut ce vide sous sa levre.
	var height: int = wall_top + WALL_HEIGHT + Walls.STOREY_TILES * WALL_LEVEL + 1

	var blank: String = ".".repeat(width)
	var cells: Array = []
	for y: int in range(height):
		var row: PackedByteArray = blank.to_utf8_buffer()
		cells.append(row)

	for order: int in range(indices.size()):
		var origin: Vector2i = island_origin(order)
		_stamp_island(cells, indices[order], origin)

	var wall_left: int = maxi(0, (width - WALL_WIDTH) / 2)
	for y: int in range(WALL_HEIGHT):
		for x: int in range(WALL_WIDTH):
			_put(cells, wall_left + x, wall_top + 1 + y, WALL_LEVEL)

	var rows: PackedStringArray = PackedStringArray()
	for row: PackedByteArray in cells:
		rows.append(row.get_string_from_utf8())
	return rows


## Le coin haut-gauche de l'ilot de rang [param order].
static func island_origin(order: int) -> Vector2i:
	return Vector2i((order % COLUMNS) * PITCH_X, (order / COLUMNS) * PITCH_Y)


## Ou lire chaque index sur la planche : index -> case centrale de son ilot.
##
## C'est ce qui rend la preuve verifiable case par case, et c'est ce qui permettra plus tard
## d'ecrire les numeros a cote des ilots.
static func centres() -> Dictionary:
	var by_index: Dictionary = {}
	var indices: PackedInt32Array = BlobIndex.CANONICAL_INDICES
	for order: int in range(indices.size()):
		by_index[indices[order]] = island_origin(order) + Vector2i(1, 1)
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
static func _put(cells: Array, x: int, y: int, level: int) -> void:
	if y < 0 or y >= cells.size():
		return
	var row: PackedByteArray = cells[y]
	if x < 0 or x >= row.size():
		return
	row[x] = ZERO + level
	cells[y] = row
