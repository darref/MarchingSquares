extends SceneTree

## LA FORME FERMEE DU VOCABULAIRE DE L2 : combien de tuiles, au plus, le modele peut-il exiger ?
##
## ⚠ ET C'EST LA QUESTION QU'ON A CESSE DE SE POSER. Avant, 27 etait un THEOREME -- les 256
## fenetres 3x3, filtrees par l'epaisseur. Depuis que la tuile est « silhouette + bits sur le
## voisinage », on ne compte plus que ce que DEUX reliefs produisent : 55 pour la planche, 61
## pour le guide. Ce sont des RENCONTRES, pas des bornes.
##
## Chaque bit a une PRECONDITION lisible dans la silhouette seule, et sa valeur depend de cases
## HORS de la fenetre 3x3 -- donc, l'exterieur etant libre sur un plan non borne, les deux
## valeurs sont realisables des que la precondition tient. Le compte se calcule alors :
##
##     tuiles = somme, sur les 27 silhouettes, de 2 ^ (nombre de bits applicables)
##
## ⚠ CE N'EST PAS UN MINIMUM, C'EST UN MAXIMUM -- ce que le modele PEUT exiger. Si ce nombre
## est enorme, ce n'est pas le compte qu'il faut accepter : c'est le modele qu'il faut reprendre.

const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")

const CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
const DIAGONALS: Array[int] = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW]


func _initialize() -> void:
	var total: int = 0
	var by_bits: Dictionary = {}
	var worst: int = 0
	var worst_index: int = -1
	for tile: int in Thickness.SURFACE_INDICES:
		var index: int = BlobIndex.silhouette(tile)
		var bits: int = _free_bits(index)
		var count: int = 1 << bits
		total += count
		by_bits[bits] = int(by_bits.get(bits, 0)) + 1
		if bits > worst:
			worst = bits
			worst_index = index
	print("=== LA FORME FERMEE DE L2 ===")
	print("  27 silhouettes epaisses")
	var keys: Array[int] = []
	for key: Variant in by_bits.keys():
		keys.append(int(key))
	keys.sort()
	for bits: int in keys:
		print("     %2d silhouette(s) a %d bit(s) libre(s)  ->  %d tuiles chacune"
				% [int(by_bits[bits]), bits, 1 << bits])
	print("")
	print("  TOTAL : %d tuiles de surface" % total)
	print("  la pire : silhouette %d (%s), %d bits, %d tuiles a elle seule"
			% [worst_index, BlobIndex.describe(worst_index), worst, 1 << worst])
	print("")
	print("  pour memoire : la planche en exerce 55, le guide 61.")
	print("  ⚠ Un compte rencontre n'est pas une borne : voila la borne.")
	print("")
	# ⚠ ET LE MEME BIT COUTE TROIS FOIS MOINS CHER SUR L'AUTRE FAMILLE. La jonction
	# « sommet contre face » demande qu'un des deux se taise, donc un bit -- mais le poser sur
	# la SURFACE multiplie 27, alors que le poser sur la FACE multiplie 20. Le compte se calcule
	# des deux cotes avant de choisir.
	var flanks: int = 3          # continue, s'arrete seule, s'arrete et cede
	var pans: int = flanks * flanks
	var rows: int = 5
	var foot_variants: int = 2   # le pied trace son bas, ou le cede a l'atterrissage
	var faces: int = pans * (rows - 1) + pans * foot_variants
	print("=== LE MEME BIT, POSE SUR LA FACE ===")
	print("  %d etats de flanc -> %d pans ; %d rangees dont le pied a %d variantes"
			% [flanks, pans, rows, foot_variants])
	print("  faces : %d roles" % faces)
	print("  TOTAL : 27 + %d = %d tuiles" % [faces, 27 + faces])
	print("")
	print("  contre %d + 20 = %d de l'autre cote." % [total, total + 20])
	quit()


## Les bits qui peuvent varier pour une silhouette donnee. Chacun a sa precondition ; hors de
## la fenetre 3x3 le monde est libre, donc des que la precondition tient, les deux valeurs le
## sont aussi.
func _free_bits(index: int) -> int:
	var bits: int = 0
	var north: bool = (index & BlobIndex.N) != 0
	var east: bool = (index & BlobIndex.E) != 0
	var west: bool = (index & BlobIndex.W) != 0
	# Le BORD : mon voisin lateral est-il couvert par une robe ? Il faut que le cardinal soit
	# vide, sinon il n'y a pas de bord de ce cote.
	if not east:
		bits += 1
	if not west:
		bits += 1
	# Le NORD SOUS UNE FACE : une robe me couvre-t-elle au nord ?
	if not north:
		bits += 1
	# LA VOISINE DU DESSUS S'EST-ELLE TUE de mon cote ? Il faut une case au nord (donc le
	# cardinal PLEIN) et un bord lateral de ce cote.
	if north and not east:
		bits += 1
	if north and not west:
		bits += 1
	# L'ERGOT : deux ergots par coin rentrant, et un coin rentrant se lit dans la silhouette --
	# deux cardinaux pleins, la diagonale vide.
	for corner: int in range(4):
		var a: int = corner
		var b: int = (corner + 3) % 4
		if (index & CARDINALS[a]) == 0 or (index & CARDINALS[b]) == 0:
			continue
		if (index & DIAGONALS[corner]) != 0:
			continue
		bits += 2
	return bits
