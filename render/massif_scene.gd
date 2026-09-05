# L'IMAGE D'UN RELIEF SOUS LE NOUVEAU MODELE.
#
# ⚠ IL N'Y A RIEN A ASSEMBLER : chaque massif se dessine ENTIER, du plus au nord au plus au sud,
# et l'occlusion est l'ordre de pose. Pas de tuile composite, pas de pose arriere, pas
# d'ecretage -- ce que l'ancien modele passait son temps a rattraper n'existe plus.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")
const Families := preload("res://core/families.gd")
const WorkIO := preload("res://core/work_io.gd")

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
		var key: int = (ink << 24) | (int(one["level"]) << 20) | Massifs.key_of(one) 				| (1 << 28 if bool(one["under"]) else 0)
		if not cache.has(key):
			cache[key] = MassifTiles.backing(int(one["level"])) if bool(one["under"]) 					else MassifTiles.shape(int(one["sil"]), int(one["band"]),
					bool(one["flush"]), freedom, Color(0, 0, 0, 0), int(one["level"]), ink,
					int(one.get("cut", 0)))
		image.blend_rect(cache[key] as Image, Rect2i(0, 0, RES, RES),
				(one["cell"] as Vector2i) * RES)
		# La derniere pose gagne : c'est celle qu'on voit, donc celle dont la levre compte.
		if bool(one["under"]):
			continue
		if int(one["band"]) != Massifs.SURFACE:
			seen[one["cell"]] = one
		else:
			seen.erase(one["cell"])
	# ⚠ LES ARETES INTERNES ATTENDENT. Elles sont justes -- 53 sur 1 577 paires -- mais on avance
	# par crans : d'abord lire l'empreinte, ensuite ce qui la traverse. `ARETES=1` les rallume.
	if ink == MassifTiles.CONTOUR and OS.get_environment("ARETES") != "":
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


## LE PAYSAGE REMONTE AVEC UN CARNET PEINT — le meme chemin que le jeu.
##
## ⚠ CHAQUE CASE EMPRUNTE, ELLE NE FABRIQUE RIEN (charte, regle 3), et TOUJOURS LA PREMIERE
## OCCURRENCE PEINTE : c'est deja la regle de l'export et celle de l'apercu en jeu. Une autre
## occurrence rendrait une autre image pour la meme tuile, et le paysage scintillerait d'une
## execution a l'autre.
##
## ⚠ ET L'ORDRE DE POSE FAIT TOUT. On ne trie rien ici : `Massifs.poses` rend deja les poses dans
## l'ordre de dessin -- par rangee, puis par etage -- et la derniere gagne. C'est de la que vient
## l'occlusion, et c'est ce qu'on vient regarder.
##
## ⚠ ET CE QUI N'EST PAS PEINT RESTE TRANSPARENT, jamais bouche. Un exemple incomplet doit se
## voir incomplet : le combler donnerait a croire qu'il est fini.
static func compose_painted(world: PackedStringArray, painting: RefCounted) -> Image:
	return compose_with(world, art_of(world, painting))


## L'ART D'UN CARNET : `{cle de tuile: Image}`, la PREMIERE occurrence peinte de chacune.
##
## ⚠ TOUJOURS LA PREMIERE, ET C'EST DEJA LA REGLE DE L'EXPORT. Une autre occurrence rendrait une
## autre image pour la meme tuile, et le decor scintillerait a chaque coup de crayon.
##
## ⚠ ET ON GARDE LE PLUS PETIT RANG, pas le premier rencontre : un dictionnaire ne promet aucun
## ordre, et une vue qui changerait d'une fois sur l'autre serait indefendable.
static func art_of(guide: PackedStringArray, painting: RefCounted) -> Dictionary:
	var out: Dictionary = {}
	if painting == null:
		return out
	var by_key: Dictionary = WorkIO.cells_by_key(guide, Families.BY_MASSIF)
	var rank_of: Dictionary = {}
	for key: String in by_key.keys():
		var slot: Dictionary = WorkIO.describe(key)
		if String(slot["family"]) != "M":
			continue
		var tile: int = int(slot["index"])
		var rank: int = int(slot["rank"])
		if rank_of.has(tile) and int(rank_of[tile]) <= rank:
			continue
		var drawn: Image = painting.image_of(by_key[key])
		if drawn != null:
			rank_of[tile] = rank
			out[tile] = drawn
	return out


## UN DECOR POSE AVEC CET ART — et le decor n'est pas forcement le guide.
##
## ⚠ C'EST TOUT L'INTERET DE LA SEPARATION. L'apercu en jeu emprunte l'art du GUIDE et le pose
## sur un AUTRE relief : un decor calme, qui ressemble a une carte de jeu. Le guide, lui, est un
## banc d'epreuve -- il ne dira jamais si le tileset REND bien.
##
## ⚠ ET CE QUI N'EST PAS PEINT RESTE UN TROU, jamais bouche. Le decor se remplit au fur et a
## mesure du travail, et ce qui manque se voit DANS SON CONTEXTE -- ce qu'aucune jauge ne montre.
static func compose_with(world: PackedStringArray, art: Dictionary, side: int = 0) -> Image:
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	var edge: int = side
	if edge <= 0:
		for one: Variant in art.values():
			edge = (one as Image).get_width()
			break
	if edge <= 0 or wide <= 0:
		return null
	var canvas: Image = Image.create_empty(wide * edge, tall * edge, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	for pose: Dictionary in Massifs.poses(world):
		var tile2: int = Massifs.key_of(pose)
		if not art.has(tile2):
			continue
		canvas.blend_rect(art[tile2] as Image, Rect2i(0, 0, edge, edge),
				(pose["cell"] as Vector2i) * edge)
	return canvas
