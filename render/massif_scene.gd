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
static func compose(world: PackedStringArray, freedom: int = 1) -> Image:
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	var image: Image = Image.create_empty(wide * RES, tall * RES, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var cache: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var key: int = (int(one["level"]) << 20) | (int(bool(one["flush"])) << 16) \
				| (int(one["band"]) << 8) | int(one["sil"])
		if not cache.has(key):
			cache[key] = MassifTiles.shape(int(one["sil"]), int(one["band"]),
					bool(one["flush"]), freedom, Color(0, 0, 0, 0), int(one["level"]))
		image.blend_rect(cache[key] as Image, Rect2i(0, 0, RES, RES),
				(one["cell"] as Vector2i) * RES)
	return image
