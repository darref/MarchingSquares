# LES MASSIFS — un blob complet et autonome, et le seul bit de contexte qui reste.
#
# ⚠ UN MASSIF EXISTE ENTIEREMENT, Y COMPRIS SOUS CE QUI LE RECOUVRE. Un chevauchement n'est que
# de l'OCCLUSION PAR ORDRE DE RENDU : le massif du dessus masque la falaise du dessous, il ne la
# modifie pas. Le voisinage d'une tuile ne depend donc JAMAIS de ce qu'on pose dessus, et ses
# cases masquees sont des cases INTERIEURES ordinaires.
#
# ⚠ D'OU LA DEFINITION, ET ELLE A ETE FAUSSE UNE FOIS : un massif d'etage L est une composante
# connexe des cases de niveau **AU MOINS** L -- pas exactement L. Groupe a l'etage exact, le
# porteur devient un ANNEAU troue la ou le massif du dessus se pose, son bord interieur se
# creuse, et on voit la plaine a travers son propre milieu. Quatre specimens sur dix montraient
# ces trous.
#
# Les massifs sont donc EMBOITES : une case de niveau 3 appartient au massif de niveau 3, a
# celui de niveau 2 et a celui de niveau 1.
#
# ⚠ ET C'EST CE QUI FAIT TOMBER SEPT BITS. Tout le vocabulaire de bord -- `BORD`, `LIP_ALONE`,
# `NORTH_QUIET`, `FLUSH`, les ergots -- repondait a une seule question, posee sept fois :
# *que ma tuile doit-elle savoir de ses voisines ?* Ici la reponse tient en un bit :
#
#     EST-CE QUE JE RECOUVRE UN AUTRE MASSIF ?
#
# Si oui, mon contour est AU RAS partout -- son arete touche la bordure de tuile au rendez-vous,
# pour que n'importe quelle voisine puisse la rejoindre. Si non, mes aretes sont LIBRES.
#
# ⚠ ET LA PLAINE NE COMPTE PAS COMME CHOSE RECOUVERTE (decision utilisateur). Sans cette clause
# tout massif recouvre quelque chose -- ne serait-ce que le sol -- donc tout serait au ras, et on
# perdrait la liberte qu'on cherche precisement a montrer.
#
# ⚠ MAIS ELLE EST UN MASSIF POUR TOUT LE RESTE, ET C'EST CE QUI SUPPRIME SON CAS PARTICULIER.
# La plaine a une surface et une falaise -- celle du BORD DU MONDE, deja au dossier depuis la
# 4.0.0 -- donc elle se trouve, se dessine et se mesure comme les autres. On la cherche donc a
# partir de l'etage ZERO ; `covers` la laisse a `false` puisque son etage n'atteint pas deux, et
# la clause d'au-dessus tient sans qu'on ait rien a ecrire pour elle.
#
# ⚠ CONSEQUENCE STRUCTURANTE : puisque le massif du dessus est au ras partout, celui du dessous
# ne peut jamais emerger EN PLEIN MILIEU d'une tuile -- il emerge toujours a une bordure. Il
# n'existe donc aucune tuile composite « falaise devant falaise », et les POSES ARRIERE n'ont
# plus rien a boucher : le massif du dessous est dessine COMPLET.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const BlobIndex := preload("res://core/blob_index.gd")

## Le bit, et il n'y en a qu'un.
const COVERS: int = 256

const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## LES MASSIFS D'UN RELIEF.
##
## Rend `{"of_cell": {Vector3i(x, y, etage): int}, "level": [int], "covers": [bool],
## "cells": [Array[Vector2i]]}`.
##
## ⚠ L'IDENTITE SE DEDUIT, ELLE NE SE STOCKE PAS. Un massif EST une composante connexe : rien a
## tenir a jour, rien qui puisse diverger de la carte. C'est ce qui rend la FUSION gratuite --
## deux massifs de meme elevation qui se touchent sont deja le meme, sans qu'on ait a le decider
## ni a l'ecrire. La couture fantome entre deux massifs adjacents de meme niveau ne peut donc
## pas exister : il n'y a pas deux massifs.
static func of(world: PackedStringArray) -> Dictionary:
	var of_cell: Dictionary = {}
	var levels: Array[int] = []
	var groups: Array = []
	var width: int = HeightMask.width(world)
	var height: int = HeightMask.height(world)
	var top: int = 0
	for y: int in range(height):
		for x: int in range(width):
			top = maxi(top, HeightMask.level_at(world, x, y))
	# ⚠ DU PLUS BAS AU PLUS HAUT : les massifs sont emboites, donc on les trouve du dehors
	# vers le dedans. Un balayage par case tomberait sur le plus haut d'abord et couperait
	# celui qui le porte en deux.
	for level: int in range(0, top + 1):
		for y2: int in range(height):
			for x2: int in range(width):
				var here: Vector2i = Vector2i(x2, y2)
				if of_cell.has(Vector3i(x2, y2, level)):
					continue
				if HeightMask.level_at(world, x2, y2) < level:
					continue
				var mark: int = groups.size()
				var cells: Array[Vector2i] = []
				var queue: Array[Vector2i] = [here]
				of_cell[Vector3i(x2, y2, level)] = mark
				while not queue.is_empty():
					var at: Vector2i = queue.pop_back()
					cells.append(at)
					for step: Vector2i in STEPS:
						var near: Vector2i = at + step
						if of_cell.has(Vector3i(near.x, near.y, level)):
							continue
						if HeightMask.level_at(world, near.x, near.y) < level:
							continue
						of_cell[Vector3i(near.x, near.y, level)] = mark
						queue.append(near)
				groups.append(cells)
				levels.append(level)

	# QUI RECOUVRE QUOI : je recouvre un massif s'il en existe un sous moi, c'est-a-dire si mon
	# etage est au moins deux -- la plaine ne comptant pas. C'est une propriete DU MASSIF, pas
	# de la case : un seul de mes points suffit a mettre tout mon contour au ras.
	var covers: Array[bool] = []
	covers.resize(groups.size())
	for mark2: int in range(groups.size()):
		covers[mark2] = levels[mark2] >= 2
	return {"of_cell": of_cell, "level": levels, "covers": covers, "cells": groups}


## LE BIT D'UNE CASE, a l'etage demande : son massif en recouvre-t-il un autre ?
##
## ⚠ C'EST LE MASSIF QUI PORTE LE BIT, PAS LA CASE. Deux cases du meme massif repondent
## forcement pareil -- c'est toute la regle : « au ras sur TOUT son contour, pas seulement aux
## zones de contact ». Le trace ne depend donc pas du contexte local, et c'est ce qui permet au
## massif recouvert d'emerger n'importe ou.
static func flush_at(made: Dictionary, at: Vector2i, level: int) -> bool:
	var of_cell: Dictionary = made["of_cell"]
	var key: Vector3i = Vector3i(at.x, at.y, level)
	if not of_cell.has(key):
		return false
	return bool((made["covers"] as Array[bool])[int(of_cell[key])])


## LES BANDES, du haut vers le bas. ⚠ C'EST LE COUPLE (SILHOUETTE, BANDE) QUI EST LA TUILE :
## une meme silhouette d'empreinte tombe sur de l'herbe ou sur de la roche selon la bande, et ce
## sont deux matieres, donc deux dessins.
const SURFACE: int = 0
const CHAPITEAU: int = 1
const CORPS: int = 2
const PIED: int = 3
const BAND_NAMES: Array[String] = ["SURFACE", "CHAPITEAU", "CORPS", "PIED"]

## La hauteur d'une falaise, en tuiles. ⚠ FIXE, ET C'EST TOUT LE MODELE : plus de chute
## quantifiee par etage, plus d'ecretage, plus de pose arriere. Un massif porte une jupe de
## trois rangees, toujours.
const FALL: int = 3


## L'EMPREINTE D'UN MASSIF : sa SURFACE, plus la FALAISE qui pend sous chaque bord sud.
## Rend `{Vector2i: bande}`.
##
## ⚠ ET C'EST SUR L'EMPREINTE QUE LA SILHOUETTE SE LIT, PAS SUR LA SURFACE. Une case de falaise
## a des voisines de falaise ; lire son voisinage dans la surface la dirait isolee.
##
## ⚠ LE BORD SUD SE LIT PAR COLONNE, ET UN MASSIF PEUT EN AVOIR PLUSIEURS. Une encoche ouverte
## au sud donne deux bords sud dans la meme colonne, et chacun porte sa falaise.
static func footprint(cells: Array) -> Dictionary:
	var out: Dictionary = {}
	var surface: Dictionary = {}
	for cell: Variant in cells:
		surface[cell as Vector2i] = true
		out[cell as Vector2i] = SURFACE
	for cell2: Variant in cells:
		var at: Vector2i = cell2 as Vector2i
		if surface.has(at + Vector2i.DOWN):
			continue
		for step: int in range(1, FALL + 1):
			var below: Vector2i = at + Vector2i(0, step)
			# La surface l'emporte : une falaise qui retombe sur la surface du MEME massif est
			# cachee par elle.
			if not out.has(below):
				out[below] = step
	return out


## TOUT CE QU'UN RELIEF POSE, DANS L'ORDRE DE DESSIN.
##
## Rend une liste de `{"cell": Vector2i, "band": int, "sil": int, "flush": bool, "level": int}`.
##
## ⚠ UNE CASE RECOIT UNE POSE PAR MASSIF QUI LA CONTIENT. Les massifs sont emboites et chacun
## existe ENTIEREMENT : la case d'un plateau d'etage 3 est aussi une case interieure du massif
## d'etage 2, de celui d'etage 1 et de la plaine. On les pose toutes, du dessous vers le dessus ;
## la derniere gagne. C'est l'occlusion par ordre de rendu, et c'est tout ce qu'un chevauchement
## est.
##
## ⚠ ET L'ORDRE EST LA RANGEE, PAS L'ETAGE -- releve par l'utilisateur : « une falaise ne peut
## pas arriver devant une autre tout en etant plus haute a l'ecran ». La vue est de trois quarts,
## ce qui est plus au SUD est plus pres du regard. L'etage ne departage qu'a rangee EGALE.
static func poses(world: PackedStringArray) -> Array[Dictionary]:
	var made: Dictionary = of(world)
	var groups: Array = made["cells"]
	var levels: Array[int] = made["level"]
	var covers: Array[bool] = made["covers"]
	var out: Array[Dictionary] = []
	for mark: int in range(groups.size()):
		var print_of: Dictionary = footprint(groups[mark] as Array)
		for cell: Vector2i in print_of.keys():
			var raw: int = 0
			for bit: int in range(8):
				if print_of.has(cell + BlobIndex.OFFSETS[bit]):
					raw |= 1 << bit
			out.append({"cell": cell, "band": int(print_of[cell]), "level": levels[mark],
					"sil": BlobIndex.canonicalize(raw), "flush": covers[mark]})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ay: int = (a["cell"] as Vector2i).y
		var by: int = (b["cell"] as Vector2i).y
		if ay != by:
			return ay < by
		return int(a["level"]) < int(b["level"]))
	return out


## LA MARGE DE PIED : aucun PIED ne touche par le sud un CHAPITEAU.
##
## ⚠ MESUREE, PAS RAISONNEE. Quand la jupe d'un massif atterrit sur la DERNIERE rangee de
## surface de celui qui le porte, son PIED se retrouve juste au-dessus de la LEVRE de ce
## dernier. Les deux tracent -- le pied son bord sud, la levre son trait -- a une rangee
## d'ecart, et les deux traits se collent : 270 paves sur le seul specimen en cascade.
##
## ⚠ ET AUCUNE TUILE NE PEUT LE RATTRAPER. Pour se taire, le pied devrait savoir qu'un
## chapiteau l'attend dessous -- c'est-a-dire un bit de contexte de plus, et c'est exactement
## le cliquet dont le nouveau modele sort. On paie donc en GRAMMAIRE : il faut UNE rangee de
## surface porteuse visible sous le pied. Trois pour la jupe, une pour respirer.
##
## Rend les cases fautives, pour que le pinceau les corrige au lieu de les refuser.
static func foot_faults(world: PackedStringArray) -> Array[Vector2i]:
	var bands_at: Dictionary = {}
	for pose: Dictionary in poses(world):
		var cell: Vector2i = pose["cell"]
		bands_at[cell] = int(bands_at.get(cell, 0)) | (1 << int(pose["band"]))
	var out: Array[Vector2i] = []
	for cell2: Vector2i in bands_at.keys():
		if (int(bands_at[cell2]) & (1 << PIED)) == 0:
			continue
		if (int(bands_at.get(cell2 + Vector2i.DOWN, 0)) & (1 << CHAPITEAU)) != 0:
			out.append(cell2)
	return out
