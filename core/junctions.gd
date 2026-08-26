## LES RACCORDS D'ILOTS : la ou le contour du haut quitte celui du bas.
##
## LE CAS, DIT SIMPLEMENT. Deux ilots colles a des hauteurs differentes. Sur une portion,
## leurs deux bords sont CONFONDUS -- le petit est au bord du grand, les deux contours
## passent au meme endroit. Puis le petit tourne vers l'INTERIEUR du grand, et son contour
## quitte celui du grand. C'est a cet endroit precis, et nulle part ailleurs, que le trait du
## haut doit rejoindre celui du bas.
##
## ⚠ ET C'EST LA QUE LE PARTAGE NE SUFFIT PLUS. Le trait du haut voudrait mordre une demi-case
## dans la tuile de bord du voisin pour se refermer -- mais cette tuile est partagee avec des
## dizaines d'endroits ou aucun raccord n'arrive : le bout de trait ajoute s'y repliquerait.
## Le raccord doit donc porter sa PROPRE tuile, que l'artiste dessine.
##
## LA FORME EST FERMEE, ET PROUVEE. A une case d'etage >= L+1, chaque voisin tombe dans trois
## seaux et trois seulement : plus bas que L (les deux contours passent la), exactement L (le
## contour du haut seul : c'est lui qui rentre), ou >= L+1 (aucun contour). Trois etats, quatre
## cotes : 81 combinaisons brutes, dont 50 sont des raccords. Puis :
##
##   1. LES COTES DU BAS SONT TOUJOURS INCLUS DANS CEUX DU HAUT. Si un voisin est plus bas que
##      L, il est aussi plus bas que L+1. C'est ce theoreme qui fait qu'un drapeau PAR TUILE
##      suffit : il ne peut jamais exister un cote « mer ouverte » en bas que le haut ne suive
##      pas. La question « par tuile ou par cote » se tranche donc definitivement, pas
##      statistiquement.
##
##   2. MIN TROIS INTERDIT DEUX COTES OPPOSES EN HAUT. Nord ET sud ouverts au meme etage, la
##      case fait une course d'UNE case dans la silhouette de cet etage : elle est fine.
##
## Un raccord demande du bas NON VIDE et du haut STRICTEMENT plus grand : le haut a donc au
## moins deux cotes, donc exactement deux, adjacents -- l'un des quatre coins. Et le bas est
## l'un de ses deux cotes. **4 coins x 2 = 8, exhaustif.**
##
## ⚠ ET C'EST EPROUVE DANS LES DEUX SENS par la suite, seule preuve que ce projet accepte :
## chacun des 8 a son temoin epais, et rien n'apparait hors de la forme.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")

const N: int = 1
const E: int = 2
const S: int = 4
const O: int = 8
const SIDE_BITS: Array[int] = [N, E, S, O]
const SIDE_NAMES: Array[String] = ["N", "E", "S", "O"]
const SIDE_STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Les 8 signatures (bas, haut), calculees -- jamais ecrites a la main.
static var SIGNATURES: Array[Vector2i] = []


static func _static_init() -> void:
	for high: int in range(16):
		if (high & N) != 0 and (high & S) != 0:
			continue                      # min trois : deux cotes opposes font une course d'une
		if (high & E) != 0 and (high & O) != 0:
			continue
		for low: int in range(16):
			if low == 0:
				continue                  # il faut du contour du bas : sinon rien a rejoindre
			if (low & ~high) != 0:
				continue                  # le bas est toujours inclus dans le haut
			if low == high:
				continue                  # il faut du rentrant : sinon les deux sont confondus
			SIGNATURES.append(Vector2i(low, high))
	SIGNATURES.sort()


## Les cotes ouverts d'une case a un etage donne : ceux dont le voisin est plus bas.
static func open_sides(heights: PackedStringArray, x: int, y: int, level: int) -> int:
	var mask: int = 0
	for side: int in range(4):
		var step: Vector2i = SIDE_STEPS[side]
		if HeightMask.level_at(heights, x + step.x, y + step.y) < level:
			mask |= SIDE_BITS[side]
	return mask


## La signature du raccord d'une case entre deux etages, ou (0, 0) s'il n'y en a pas.
##
## [param level] est l'etage du BAS : la case doit etre a [param level] + 1 ou plus haut.
static func signature_at(heights: PackedStringArray, x: int, y: int, level: int) -> Vector2i:
	if HeightMask.level_at(heights, x, y) < level + 1:
		return Vector2i.ZERO
	var low: int = open_sides(heights, x, y, level)
	var high: int = open_sides(heights, x, y, level + 1)
	if low == 0 or high == low:
		return Vector2i.ZERO
	return Vector2i(low, high)


## Cette signature est-elle de la forme fermee ?
static func is_known(signature: Vector2i) -> bool:
	return signature in SIGNATURES


## Tous les raccords d'un relief : case -> (bas, haut), l'etage le plus haut d'abord.
static func map(heights: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	var top: int = HeightMask.top_level(heights)
	for level: int in range(1, top + 1):
		for y: int in range(HeightMask.height(heights)):
			for x: int in range(HeightMask.width(heights)):
				var signature: Vector2i = signature_at(heights, x, y, level)
				if signature != Vector2i.ZERO:
					out[Vector3i(x, y, level)] = signature
	return out


## Le nom d'un masque de cotes, pour se relire.
static func mask_name(mask: int) -> String:
	if mask == 0:
		return "-"
	var parts: Array[String] = []
	for side: int in range(4):
		if (mask & SIDE_BITS[side]) != 0:
			parts.append(SIDE_NAMES[side])
	return "".join(parts)


## Le nom d'une signature.
static func name_of(signature: Vector2i) -> String:
	return "bas=%s haut=%s" % [mask_name(signature.x), mask_name(signature.y)]
