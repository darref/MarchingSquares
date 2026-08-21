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
