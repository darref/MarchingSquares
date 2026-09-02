# L'IMAGE D'UN RELIEF SOUS LE NOUVEAU MODELE.
#
# ⚠ IL N'Y A RIEN A ASSEMBLER : chaque massif se dessine ENTIER, du plus au nord au plus au sud,
# et l'occlusion est l'ordre de pose. Pas de tuile composite, pas de pose arriere, pas
# d'ecretage -- ce que l'ancien modele passait son temps a rattraper n'existe plus.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")

const RES: int = MassifTiles.RES


## L'IMAGE. ⚠ LE FOND RESTE TRANSPARENT, ET C'EST CE QUI REND LA MESURE POSSIBLE : un trou se
## reconnait a son alpha, quelle que soit la regle qui a cru le boucher.
static func compose(world: PackedStringArray, freedom: int = 1,
		ink: int = MassifTiles.PEINT) -> Image:
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	var image: Image = Image.create_empty(wide * RES, tall * RES, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var cache: Dictionary = {}
	var seen: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var key: int = (ink << 24) | (int(one["level"]) << 20) | Massifs.key_of(one)
		if not cache.has(key):
			cache[key] = MassifTiles.shape(int(one["sil"]), int(one["band"]),
					bool(one["flush"]), freedom, Color(0, 0, 0, 0), int(one["level"]), ink)
		image.blend_rect(cache[key] as Image, Rect2i(0, 0, RES, RES),
				(one["cell"] as Vector2i) * RES)
		# La derniere pose gagne : c'est celle qu'on voit, donc celle dont la levre compte.
		if int(one["band"]) != Massifs.SURFACE:
			seen[one["cell"]] = one
		else:
			seen.erase(one["cell"])
	if ink == MassifTiles.CONTOUR:
		_inner_edges(image, seen)
	return image


## LES ARETES INTERNES D'UNE FALAISE.
##
## ⚠ CE N'EST PAS LE QUADRILLAGE DES TUILES -- premiere version, et elle etait fausse. Deux cases
## de face qui pendent de la MEME levre sont la meme paroi : la roche y est continue et tout
## trait serait faux, c'est meme ce que les classes de raccord existent pour garantir. Une arete
## interne, c'est le contraire : deux faces cote a cote qui ne pendent PAS de la meme levre, donc
## de la roche des deux cotes et un vrai coin entre elles.
##
## ⚠ ET ELLE NE SE TRACE QUE DANS LE FOND, JAMAIS DANS LA TUILE. Une tuile ne sait rien de la
## levre de sa voisine ; c'est le fond, qui connait le relief entier, qui peut la montrer. C'est
## precisement ce qu'on vient regarder : ou le modele pose une frontiere qu'aucune tuile ne
## saurait dessiner seule.
static func _inner_edges(image: Image, seen: Dictionary) -> void:
	for cell: Vector2i in seen.keys():
		var mine: Dictionary = seen[cell]
		var near: Vector2i = cell + Vector2i.RIGHT
		if not seen.has(near):
			continue
		var other: Dictionary = seen[near]
		# ⚠ ON COMPARE LA RANGEE DE LA LEVRE, PAS LA LEVRE-CASE. La levre de la colonne x est
		# (x, y) et celle de x+1 est (x+1, y) : comparees telles quelles, elles different
		# TOUJOURS, et la paroi se couvrait d'un peigne -- un trait a chaque bordure de colonne.
		# Ce qui fait la continuite d'une face, c'est que ses colonnes pendent de la MEME
		# RANGEE ; ce qui fait l'arete, c'est que la levre y prend un virage a angle droit.
		if int(mine["massif"]) == int(other["massif"]) \
				and (mine["lip"] as Vector2i).y == (other["lip"] as Vector2i).y:
			continue
		for y: int in range(RES):
			image.set_pixel(near.x * RES, cell.y * RES + y, MassifTiles.OUTLINE)
