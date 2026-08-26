# Calcul de l'index blob 47 a partir d'un voisinage 8 bits.
# Logique pure : aucun noeud, aucune ressource, aucune dependance UI.
extends RefCounted

## Bits de voisinage, dans le sens horaire depuis le nord.
const N: int = 1
const NE: int = 2
const E: int = 4
const SE: int = 8
const S: int = 16
const SW: int = 32
const W: int = 64
const NW: int = 128

## Les quatre bits cardinaux, toujours conserves tels quels.
const CARDINALS: int = N | E | S | W

## Les huit bits, dans l'ordre horaire depuis le nord.
const BITS: Array[int] = [N, NE, E, SE, S, SW, W, NW]

## Les noms des huit bits, dans le meme ordre.
const BIT_NAMES: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

## Decalages (dx, dy) associes aux bits, dans le meme ordre.
## Repere ecran : x croit vers l'est, y croit vers le sud.
const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
]

## Ensemble trie des 47 index canoniques valides.
## Calcule au chargement de la classe par _static_init(), jamais ecrit en dur :
## la liste est une consequence de canonicalize(), pas une donnee a maintenir.
static var CANONICAL_INDICES: PackedInt32Array = PackedInt32Array()

static func _static_init() -> void:
	var distinct: Dictionary = {}
	for raw: int in range(256):
		distinct[canonicalize(raw)] = true
	var sorted_indices: Array = distinct.keys()
	sorted_indices.sort()
	CANONICAL_INDICES = PackedInt32Array(sorted_indices)


## Reduit un voisinage brut (0..255) a son index canonique.
## Un bit de coin n'est conserve que si les deux bits cardinaux adjacents sont pleins :
## un coin diagonal isole ne change rien a la silhouette de la tuile, il ne doit donc
## pas produire une tuile supplementaire a peindre.
static func canonicalize(raw: int) -> int:
	var canonical: int = raw & CARDINALS
	if (raw & NE) != 0 and (canonical & N) != 0 and (canonical & E) != 0:
		canonical |= NE
	if (raw & SE) != 0 and (canonical & S) != 0 and (canonical & E) != 0:
		canonical |= SE
	if (raw & SW) != 0 and (canonical & S) != 0 and (canonical & W) != 0:
		canonical |= SW
	if (raw & NW) != 0 and (canonical & N) != 0 and (canonical & W) != 0:
		canonical |= NW
	return canonical


## Vrai si l'index fait partie des 47 configurations couvertes.
## Charte, regle 5 : ce qui n'est pas garanti est interdit.
static func is_canonical(index: int) -> bool:
	return canonicalize(index) == index


## Un index ecrit par ses bits : « 117 = N+E+S+SW+W ».
##
## ⚠ UN NUMERO SEUL NE DIT RIEN. « 117 » ne se visualise pas ; « N+E+S+SW+W » donne la
## silhouette, donc ce qu'il faut dessiner. Partout ou un index s'affiche, il s'affiche
## avec ses bits -- dans le runner comme dans l'editeur, et depuis cette fonction-ci pour
## que les deux ne puissent pas diverger.
static func describe(index: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for bit: int in range(BITS.size()):
		if (index & BITS[bit]) != 0:
			parts.append(BIT_NAMES[bit])
	return "aucun voisin" if parts.is_empty() else "+".join(parts)


## LE BORD — ce qu'il y a AU-DELA de chaque cardinal vide, et pourquoi ca vit dans la tuile.
##
## ⚠ UN BORD VIDE NE VEUT PAS TOUJOURS DIRE UNE CHUTE. Quand la case d'a cote est couverte
## par une FACE, cette face a son sommet au niveau de mon propre sol : la roche continue de
## plain-pied, il n'y a aucune marche. Quand elle est nue, il y a bien une chute d'un etage
## au moins. Deux choses opposees derriere le meme bord -- et les huit bits de voisinage,
## qui ne disent que l'endroit ou est la terre, ne savent pas les distinguer. Une seule
## image ne peut pas etre juste dans les deux cas : c'est la meme impossibilite que celle
## des trois pans, portee cette fois par les tuiles de SURFACE.
##
## Mesure sur le guide et 500 reliefs epais : NEUF silhouettes sur vingt-sept voient les
## deux especes, et la 241 borde de la roche 191 fois pour 3206 fois du nu.
##
## ⚠ LE SUD N'EN EST PAS, ET C'EST UN THEOREME. Une case dont le sud est vide est une
## levre : sa propre face couvre la case d'en dessous, TOUJOURS. Le sud ne porte donc aucune
## information -- et c'est exactement ce qui rend l'EPAULE peignable dans la tuile de
## surface, la ou aucun autre bord ne le serait. Restent le nord, l'est et l'ouest.
##
## ⚠ UNE TUILE DE SURFACE EST DONC UN COUPLE (silhouette, bord), RANGE DANS UN ENTIER :
## la silhouette dans les huit bits bas, le bord au-dessus. Tout ce qui ne fait que
## transporter une tuile -- les jumelles, le carnet, la planche, l'export -- continue de
## manipuler un entier sans rien savoir de la coupure.
const BRINK_SHIFT: int = 8
const BRINK_N: int = 1
const BRINK_E: int = 2
const BRINK_W: int = 4
const BRINK_BITS: Array[int] = [BRINK_N, BRINK_E, BRINK_W]
const BRINK_CARDINALS: Array[int] = [N, E, W]
const BRINK_OFFSETS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
const BRINK_NAMES: Array[String] = ["N", "E", "O"]


## La silhouette seule : les huit bits de voisinage, sans le bord.
static func silhouette(tile: int) -> int:
	return tile & ((1 << BRINK_SHIFT) - 1)


## Le bord seul : quels cardinaux vides ont de la ROCHE au-dela.
static func brink(tile: int) -> int:
	return tile >> BRINK_SHIFT


static func compose(index: int, edge: int) -> int:
	return index | (edge << BRINK_SHIFT)


## Les bords qu'une silhouette peut decliner : ses cardinaux vides, sud exclu.
static func free_brinks(index: int) -> Array[int]:
	var out: Array[int] = []
	for side: int in range(BRINK_BITS.size()):
		if (index & BRINK_CARDINALS[side]) == 0:
			out.append(BRINK_BITS[side])
	return out


## Le nom d'un bord, pour les rapports.
## ⚠ ET IL NE DIT PLUS RIEN, PARCE QU'IL N'Y A PLUS RIEN A DIRE. Le bord annoncait, pour chaque
## cardinal vide, si la case d'a cote montrait du NU ou de la ROCHE -- c'est-a-dire une
## affirmation sur le VOISIN, ecrite dans le nom de la tuile et recopiee telle quelle au
## manifeste. La decomposition en couches l'a supprimee : ce qui est a cote appartient a la
## couche du voisin, qui le dessine elle-meme.
##
## La fonction reste et rend le vide : tout ce qui nomme une tuile passe par elle, et un nom qui
## affirmerait le voisinage serait, au contrat, un endroit ou mentir.
static func brink_name(tile: int) -> String:
	var _unused: int = tile
	return ""
