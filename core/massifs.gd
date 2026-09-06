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
##
## ⚠ IL SE RANGE AU-DESSUS DE LA BANDE, PAS A 256. Premier essai : `COVERS = 256`, c'est-a-dire
## exactement `CHAPITEAU << 8`. Le bit de contexte et la bande se melangeaient dans la meme cle,
## et le rapport annoncait deux fois « PIED 23 au ras » pour deux tuiles differentes. Un compteur
## qui ne mesure pas ce qu'il pretend mesurer est pire que pas de compteur.
const COVERS: int = 1 << 16

## LE CISAILLEMENT : de l'herbe et de la roche du MEME massif, cote a cote.
##
## ⚠ LA BANDE ENCODE DEJA LA TRANSITION VERTICALE -- surface, chapiteau, corps, pied -- et c'est
## pour ca que la levre porte son trait. RIEN n'encodait la transition HORIZONTALE : la
## silhouette se lit sur l'EMPREINTE, donc une case d'herbe dont la voisine est la falaise de son
## PROPRE massif a ce bit MIS, se croit pleine, et rend la tuile d'interieur qui se repete
## partout. Sa voisine de roche fait de meme, et personne ne trace la frontiere : la roche
## s'arrete NET contre l'herbe. Releve par l'utilisateur sur le massif 21 du guide, en regardant
## SON trait remonte -- pas le dessin calcule, qui est la specification et a donc l'air juste.
##
## ⚠ ET LES DEUX COTES LE PORTENT, PAS SEULEMENT LA ROCHE (decision utilisateur). La loi « un
## flanc qui s'arrete ne se creuse pas, il se trait » ne demandait que la roche ; mais une
## frontiere tracee d'un seul cote se voit, et le rendu semble faux.
##
## ⚠ ET ILS SE RANGENT AU-DESSUS DE `COVERS`, JAMAIS DEDANS. Meme lecon que `COVERS` lui-meme,
## qui valait 256 -- c'est-a-dire exactement `CHAPITEAU << 8` -- et melangeait le contexte avec
## la bande. Bits 17 et 18 : au-dessus de la bande (8..15) et du ras (16), sous l'etage que
## `massif_scene` empile a 20.
const CUT_WEST: int = 1 << 17
const CUT_EAST: int = 1 << 18

## LE CISAILLEMENT PAR LE NORD : de la roche du MEME massif au-dessus de l'herbe.
##
## ⚠ RELEVE PAR L'UTILISATEUR LE 06/09, ET C'EST LA MEME FAUTE QUE LE CISAILLEMENT D'ORIGINE,
## restee dans la seule direction que personne ne lisait. Quand un massif cisaille, la falaise
## cisaille -- et la SURFACE aussi a son extremite nord. La case du coude se croyait pleine et
## rendait la tuile d'interieur : le trait s'arretait net, sans pouvoir se refermer. Mesure
## avant le bit : 123 cases sur 635 mondes, sous DEUX cles seulement -- et ces memes cles
## servaient aussi aux cases SANS roche au nord, donc un seul dessin pour deux endroits.
##
## ⚠ ET IL NE SE LIT QUE POUR L'HERBE, PAS SYMETRIQUEMENT. Une case de falaise a toujours du
## massif au-dessus d'elle, et la BANDE le dit deja : chapiteau au premier pas, corps ensuite.
## Lire le nord des deux cotes mettrait le bit sur tous les chapiteaux du monde, pour une
## distinction que la bande porte depuis le debut.
const CUT_NORTH: int = 1 << 19
const CUTS: int = CUT_WEST | CUT_EAST | CUT_NORTH

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

	# QUI EST AU RAS, ET C'EST LE CHEVAUCHEMENT QUI LE DIT -- PAS L'ETAGE.
	#
	# ⚠ UN MASSIF ENTIEREMENT ENTOURE PAR CELUI QUI LE PORTE N'A AUCUNE RAISON D'ETRE AU RAS.
	# Son contour ne longe que de la matiere ; ce qu'il decouvre en vagabondant, c'est la surface
	# du porteur, qui est la de toute facon. Il garde donc toute sa liberte. Premiere version :
	# « etage >= 2 => au ras », ce qui plaquait au bord de tuile des massifs qui n'avaient rien a
	# rejoindre.
	#
	# ⚠ CE QUI FORCE LE RAS, C'EST LE CHEVAUCHEMENT : une partie dedans, une partie dehors. La,
	# le contour du massif du dessus longe la FRONTIERE du massif du dessous, et les deux
	# decrivent le meme endroit sans pouvoir se concerter -- une tuile ne repond que d'elle-meme.
	# Le seul point de rendez-vous qu'ils partagent tous les deux est la bordure de tuile : ils
	# n'ont, par principe, aucun autre choix.
	#
	# ⚠ ET C'EST UNE PROPRIETE DU MASSIF, PAS DE LA CASE. Un seul point de chevauchement met tout
	# le contour au ras : sans quoi le trace changerait de regle en cours de route, et deux
	# occurrences d'une meme tuile ne diraient plus la meme chose.
	var covers: Array[bool] = []
	covers.resize(groups.size())
	for mark2: int in range(groups.size()):
		covers[mark2] = false
	for mark3: int in range(groups.size()):
		if levels[mark3] < 1:
			continue
		var mine: Dictionary = footprint(world, groups[mark3] as Array, levels[mark3])
		# Le massif qui me porte : celui de l'etage juste en dessous qui contient mes cases.
		var below: int = int(of_cell.get(Vector3i((groups[mark3] as Array)[0].x,
				(groups[mark3] as Array)[0].y, levels[mark3] - 1), -1))
		if below < 0:
			covers[mark3] = true
			continue
		var host: Dictionary = footprint(world, groups[below] as Array, levels[below])
		for cell: Vector2i in mine.keys():
			if covers[mark3]:
				break
			for step: Vector2i in STEPS:
				var near: Vector2i = cell + step
				if mine.has(near) or host.has(near):
					continue
				covers[mark3] = true
				break
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
## ⚠ LA CHUTE N'EST PAS FORFAITAIRE : ELLE VA JUSQU'AU SOL QU'ELLE ATTEINT. Un massif porte qui
## DEBORDE de son porteur est plus haut que ce qui le borde -- c'est meme la definition d'etre
## porte -- donc la ou il sort du porteur, sa face doit descendre jusqu'a la plaine. Trois
## rangees forfaitaires dessinaient une falaise d'un etage la ou le relief en compte deux : le
## dessin mentait sur la hauteur, et c'est une question de 3D, pas de gout.
##
## La regle : un etage vaut TROIS rangees, donc la face cherche le premier palier `j` tel que le
## sol, `3j` rangees plus bas, soit exactement `j` etages sous la levre. Si elle n'en trouve
## aucun, elle tombe dans le vide et NE POSE PAS SON PIED -- on ne touche pas le fond d'un
## gouffre.
##
## ⚠ ET LA SONDE REGARDE SOUS LE PIED, JAMAIS LES RANGEES TRAVERSEES. Une terrasse posee sur le
## trajet n'arrete pas la chute : c'est le palier qui compte. Piege deja paye dans l'ancien
## modele, garde ici tel quel.
##
## ⚠ LE BORD SUD SE LIT PAR COLONNE, ET UN MASSIF PEUT EN AVOIR PLUSIEURS. Une encoche ouverte
## au sud donne deux bords sud dans la meme colonne, et chacune porte sa falaise.
## `lips`, s'il est fourni, recoit pour chaque case de falaise LA LEVRE dont elle pend. C'est la
## seule chose qui distingue une roche continue d'une ARETE INTERNE : deux faces cote a cote qui
## ne pendent pas de la meme levre ont de la roche des deux cotes et un vrai coin entre elles.
static func footprint(world: PackedStringArray, cells: Array, level: int,
		lips: Dictionary = {}, under: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {}
	var surface: Dictionary = {}
	for cell: Variant in cells:
		surface[cell as Vector2i] = true
		out[cell as Vector2i] = SURFACE
	for cell2: Variant in cells:
		var at: Vector2i = cell2 as Vector2i
		if surface.has(at + Vector2i.DOWN):
			continue
		# ⚠ ET LA FACE S'ARRETE OU LA ROCHE LA RENCONTRE. Chercher seulement les paliers de trois
		# laissait une face TRAVERSER du sol pose entre deux paliers : la falaise d'un etage 2
		# descendait neuf rangees a travers un plateau d'etage 1, et son bord venait se coller au
		# trait de ce que le sol dessinait dessous. On descend donc rangee par rangee, et on
		# regarde le sol a chaque pas : le bas de la face apres k rangees est a `etage - k/3`.
		#
		# ⚠ ET UNE FACE ECRETEE NE POSE PAS SON PIED : le pied est la preuve d'un atterrissage,
		# c'est-a-dire d'un palier atteint pile. Regle reprise telle quelle de l'ancien modele.
		var fall: int = 0
		var landed: bool = false
		for k: int in range(1, FALL * (level + 1) + 1):
			var ground: int = HeightMask.level_at(world, at.x, at.y + k)
			var bottom: int = level - k / FALL
			if ground > bottom:
				break
			fall = k
			if k % FALL == 0 and ground == bottom:
				# UN PIED SEULEMENT AU VRAI FOND, PAS LA OU LA FACE EST CACHEE (decision utilisateur
				# du 06/09) : « le massif de derriere se fait cacher par celui de devant, donc ses
				# tuiles de falaise qui arrivent juste avant d etre cachees n ont pas besoin d etre un
				# pied ». Une face qui rencontre le TOIT D UN AUTRE MASSIF ne se termine pas la : elle
				# disparait derriere lui. Le PIED est la preuve d un FOND atteint, et un fond est la
				# PLAINE, et rien d autre -- 386 poses sur 12 658 levres portaient un pied qui ne prouvait
				# rien. ⚠ ET LE VIDE N EST PAS UN FOND NON PLUS : « on ne touche pas le fond d un
				# gouffre ». Ecrit `ground <= 0`, le banc a rendu DEUX extremites ouvertes -- un
				# pied pose sur du vide trace le bas d une falaise qui ne s arrete nulle part.
				#
				# ⚠ ET SON DESSIN CESSE DE SERVIR A DEUX CHOSES. Une meme tuile devait convenir au bas
				# REEL d une falaise ET a une simple rencontre ; c est l artiste qui payait la
				# difference, en cherchant un trait qui aille aux deux.
				landed = ground == 0
				break
		for step: int in range(1, fall + 1):
			var below: Vector2i = at + Vector2i(0, step)
			# La surface l'emporte : une falaise qui retombe sur la surface du MEME massif est
			# cachee par elle.
			if out.has(below):
				continue
			out[below] = CHAPITEAU if step == 1 else (
					PIED if (landed and step == fall) else CORPS)
			lips[below] = at
		# ⚠ LE SOUS-PIED EST RETIRE (decision utilisateur). Il reposait le pied une case plus bas,
		# sous la surface d'atterrissage, pour boucher le mince decalage entre le ras d'un massif
		# porte et le contour libre de son porteur. Le code est retire, la mesure reste : il ne
		# coutait aucune tuile -- c'etait une pose de plus, pas un dessin de plus.
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
		var lips: Dictionary = {}
		var under: Dictionary = {}
		var print_of: Dictionary = footprint(world, groups[mark] as Array, levels[mark], lips,
				under)
		for cell: Vector2i in print_of.keys():
			var raw: int = 0
			for bit: int in range(8):
				if print_of.has(cell + BlobIndex.OFFSETS[bit]):
					raw |= 1 << bit
			# LE CISAILLEMENT SE LIT DANS L'EMPREINTE DU MASSIF, PAS SUR CE QUI SE VOIT.
			#
			# ⚠ ET C'EST LA MEME RAISON QUE TOUT LE RESTE DU MODELE : un massif se dessine
			# ENTIER, y compris sous ce qui le recouvre. Lire le cisaillement sur la carte
			# VISIBLE ferait dependre l'identite d'une tuile de ce qu'on pose dessus -- exactement
			# ce que le modele existe pour interdire. `print_of` est l'empreinte de CE massif :
			# une voisine qui s'y trouve est du meme massif par construction.
			var grass: bool = int(print_of[cell]) == SURFACE
			var cut: int = 0
			if print_of.has(cell + Vector2i.LEFT) \
					and (int(print_of[cell + Vector2i.LEFT]) == SURFACE) != grass:
				cut |= CUT_WEST
			if print_of.has(cell + Vector2i.RIGHT) \
					and (int(print_of[cell + Vector2i.RIGHT]) == SURFACE) != grass:
				cut |= CUT_EAST
			# ⚠ LE NORD NE SE LIT QUE POUR L'HERBE. Une falaise a toujours du massif au-dessus
			# d'elle et la bande le dit ; ce que personne ne disait, c'est « j'ai de la roche au
			# nord » pour une case de SURFACE -- le coude, ou le trait s'arretait net.
			if grass and print_of.has(cell + Vector2i.UP) \
					and int(print_of[cell + Vector2i.UP]) != SURFACE:
				cut |= CUT_NORTH
			out.append({"cell": cell, "band": int(print_of[cell]), "level": levels[mark],
					"sil": BlobIndex.canonicalize(raw), "flush": covers[mark], "cut": cut,
					"lip": lips.get(cell, Vector2i(-9999, -9999)), "massif": mark,
					"under": false})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ay: int = (a["cell"] as Vector2i).y
		var by: int = (b["cell"] as Vector2i).y
		if ay != by:
			return ay < by
		if bool(a["under"]) != bool(b["under"]):
			return bool(a["under"])
		return int(a["level"]) < int(b["level"]))
	return out


## LA MARGE DE PIED : sous chaque PIED, au moins TROIS rangees sans roche.
##
## ⚠ ELLE VALAIT UNE RANGEE, ET C'ETAIT LE MINIMUM SYNDICAL. A un, elle empechait seulement que
## deux traits se collent -- un pied juste au-dessus d'une levre, qui tracent a une rangee
## d'ecart. Mais elle laissait des RUBANS DE SOL D'UNE CASE entre la retombee d'une falaise et
## la levre suivante : le relief y est epais, et pourtant ce qu'on VOIT ne l'est pas.
##
## ⚠ ET AUCUNE TUILE NE PEUT LE RATTRAPER. Pour se taire, le pied devrait savoir qu'un chapiteau
## l'attend dessous -- un bit de contexte de plus, c'est-a-dire le cliquet dont ce modele sort.
## On paie donc en GRAMMAIRE.
##
## Rend les cases fautives, pour que le pinceau les corrige au lieu de les refuser.
## ⚠ ET ELLE VAUT UNE RANGEE, PAS TROIS -- mesure, pas prudence. A trois, elle refuse des
## reliefs que la reparation ne sait pas rattraper localement, et le generateur passe de 43
## mondes retenus a 8 pour 120 tirages. Sa raison d'etre est etroite : empecher que le trait
## d'un pied et celui d'une levre se collent, ce qui demande UNE rangee. La lisibilite, elle,
## est couverte par une autre clause -- l'epaisseur de ce qui SE VOIT, hors plaine.
const FOOT_MARGIN: int = 1


## ⚠ ET ELLE SE LIT SUR CE QUI EST VISIBLE, PAS SUR TOUTES LES POSES. Quand un massif porte
## deborde son porteur, sa longue face passe DEVANT celle du porteur : le pied du porteur se
## retrouve alors juste au-dessus du corps du porte -- et la regle criait, alors que ce pied est
## CACHE et que rien ne se colle a l'ecran. Six fautes sur le specimen de debordement, qui
## devenait irrealisable : le cas de la chute de SIX n'existait donc nulle part.
## ⚠ ET ELLE ACCEPTE DES POSES DEJA CALCULEES. `poses()` est LA carte couteuse du modele -- 14 ms
## sur 32x32 -- et trois clauses du geste la relisaient chacune pour son compte. Une carte
## couteuse ne se recalcule pas a chaque tour de boucle : la lecon est deja au dossier, payee
## sept fois, et elle vaut ici aussi.
static func foot_faults(world: PackedStringArray,
		given: Array[Dictionary] = []) -> Array[Vector2i]:
	var top: Dictionary = {}
	for one: Dictionary in (given if not given.is_empty() else poses(world)):
		var at: Vector2i = one["cell"]
		if bool(one["under"]):
			continue
		if top.has(at) and int((top[at] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[at] = one
	# ⚠ ET LE SOUS-PIED N'EN EST PAS : il est la MEME face qui continue une case plus bas, pas une
	# autre paroi. Compte comme de la roche, il declenchait la regle contre le pied juste
	# au-dessus de lui -- 257 fautes, toutes fausses.
	var bands_at: Dictionary = {}
	for cell3: Vector2i in top.keys():
		if bool((top[cell3] as Dictionary)["under"]):
			continue
		bands_at[cell3] = 1 << int((top[cell3] as Dictionary)["band"])
	var out: Array[Vector2i] = []
	var rock: int = (1 << CHAPITEAU) | (1 << CORPS) | (1 << PIED)
	for cell2: Vector2i in bands_at.keys():
		if (int(bands_at[cell2]) & (1 << PIED)) == 0:
			continue
		for step: int in range(1, FOOT_MARGIN + 1):
			if (int(bands_at.get(cell2 + Vector2i(0, step), 0)) & rock) == 0:
				continue
			out.append(cell2)
			break
	return out


## LA CLE D'UNE TUILE : le bit RECOUVRANT, la BANDE, la SILHOUETTE de l'empreinte.
##
## ⚠ UNE SEULE FAMILLE DE TUILES, ET C'EST LA SIMPLIFICATION QUI PORTE LE RESTE. L'ancien
## modele en avait deux -- les index de surface d'un cote, les roles de robe de l'autre -- avec
## deux carnets, deux compteurs, deux planches et deux facons de se contredire. Ici la surface et
## la falaise ne different que par leur BANDE : une seule table, un seul compteur, une seule
## planche.
## ⚠ ET LA CLE EST CELLE DU DESSIN, PAS DE LA SITUATION. Ce qu'on peint, c'est une image :
## deux situations qui rendent la meme image sont UNE tuile, sinon on fait peindre deux fois la
## meme chose et la planche exportee porte deux cases identiques.
##
## ⚠ AU RAS, LES DIAGONALES NE VEULENT PLUS RIEN DIRE. La profondeur y est nulle, donc rien ne
## se creuse -- ni les bords, ni les COINS RENTRANTS, dont le creusement se prend a la meme
## profondeur. Une tuile au ras est donc toujours pleine, avec un trait sur ses bords ouverts, et
## elle ne depend que de ses quatre cardinaux. Mesure : 55 tuiles ne rendaient que 42 dessins,
## et les treize doublons etaient tous de cette espece.
##
## ⚠ ET SI AUCUN BORD N'EST OUVERT, IL N'Y A MEME PLUS DE TRAIT : c'est la tuile PLEINE, la meme
## que la silhouette 255 en liberte. On ne la compte pas deux fois.
const CARDINALS: int = 0x55


## ⚠ ET LE CISAILLEMENT NE PASSE PAS PAR LA CANONICALISATION DU RAS. Au ras, seuls les cardinaux
## comptent -- la profondeur y est nulle, donc rien ne se creuse. Mais le cisaillement ne dit
## rien du CONTOUR : il dit quelle MATIERE est a cote, dans la meme empreinte. Les deux sont
## orthogonaux, et une tuile au ras porte son cisaillement comme une autre.
static func key(band: int, sil: int, flush: bool, cut: int = 0) -> int:
	if not flush:
		return cut | (band << 8) | sil
	var bare: int = sil & CARDINALS
	if bare == CARDINALS:
		return cut | (band << 8) | 255
	return cut | COVERS | (band << 8) | bare


static func key_of(pose: Dictionary) -> int:
	return key(int(pose["band"]), int(pose["sil"]), bool(pose["flush"]),
			int(pose.get("cut", 0)))


static func band_of(tile: int) -> int:
	return (tile >> 8) & 0xff


static func sil_of(tile: int) -> int:
	return tile & 0xff


static func flush_of(tile: int) -> bool:
	return (tile & COVERS) != 0


## De quel cote la matiere change, dans la meme empreinte. `0`, `CUT_WEST`, `CUT_EAST`.
##
## ⚠ ET JAMAIS LES DEUX A LA FOIS -- ce n'est pas de la chance, min trois l'interdit. Il faudrait
## un doigt d'herbe d'UNE colonne entre deux jupes du meme massif : a cette rangee, la silhouette
## de l'etage y ferait une course d'une case, donc fine. Verifie aussi par l'enumeration
## exhaustive de `massif_form.shear_vocabulary()` : zero fenetre des deux cotes sur 2^18.
static func cut_of(tile: int) -> int:
	return tile & CUTS


## Le nom d'une tuile, en clair.
static func describe(tile: int) -> String:
	var said: String = "%s %d %s" % [BAND_NAMES[band_of(tile)], sil_of(tile),
			"au ras" if flush_of(tile) else "libre"]
	var cut: int = cut_of(tile)
	var sides: PackedStringArray = PackedStringArray()
	if (cut & CUT_WEST) != 0:
		sides.append("a l ouest")
	if (cut & CUT_EAST) != 0:
		sides.append("a l est")
	if (cut & CUT_NORTH) != 0:
		sides.append("au nord")
	if not sides.is_empty():
		said += ", cisaille " + " et ".join(sides)
	return said


## CE QUE CHAQUE CASE MONTRE : la tuile du massif le plus haut qui la couvre.
##
## ⚠ UNE CASE N'A QU'UNE POSE PAR ETAGE, ET C'EST UN THEOREME -- sans quoi « la plus haute »
## ne designerait rien. A un etage donne, une case appartient a une seule composante ; et la
## jupe d'un massif ne peut pas tomber sur la surface d'un AUTRE massif du meme etage, puisque
## min trois separe deux composantes d'au moins trois rangees de vide alors que la jupe n'en
## descend que trois : elle s'arrete juste avant.
static func visible(world: PackedStringArray) -> Dictionary:
	var top: Dictionary = {}
	var level_at: Dictionary = {}
	for pose: Dictionary in poses(world):
		var cell: Vector2i = pose["cell"]
		if top.has(cell) and int(level_at[cell]) > int(pose["level"]):
			continue
		top[cell] = key_of(pose)
		level_at[cell] = int(pose["level"])
	return top


## CE QUI PREND LE CRAYON : ce que montre chaque case, hors de la plaine.
##
## ⚠ L'ETAGE 0 EST DU DECOR, ET IL RESTE DANS LES JUMELLES. La plaine ne se peint pas -- ni
## crayon, ni grille -- mais peindre une tuile la remplit sous les yeux, et c'est l'argument de
## vente : le sol du jeu sortira du meme tileset, sans rien de plus a dessiner.
static func paintable(world: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	var level_at: Dictionary = {}
	for pose: Dictionary in poses(world):
		var cell: Vector2i = pose["cell"]
		if out.has(cell) and int(level_at[cell]) > int(pose["level"]):
			continue
		out[cell] = key_of(pose)
		level_at[cell] = int(pose["level"])
	for cell2: Vector2i in level_at.keys():
		if int(level_at[cell2]) < 1:
			out.erase(cell2)
	return out


## LES JUMELLES : ce qui porte la meme tuile porte le meme dessin.
static func cells_by_key(map: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var order: Array[Vector2i] = []
	order.assign(map.keys())
	# ⚠ EN ORDRE DE LECTURE, le seul qui ne depende que du monde et jamais du remplissage d'un
	# dictionnaire. C'est lui qui donne son RANG a une occurrence, donc sa cle de sauvegarde.
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y if a.y != b.y else a.x < b.x)
	for cell: Vector2i in order:
		var tile: int = int(map[cell])
		if not out.has(tile):
			out[tile] = [] as Array[Vector2i]
		(out[tile] as Array[Vector2i]).append(cell)
	return out


## LE RAPPORT : ce que ce relief offre, et ce qui lui manque.
static func analyse(world: PackedStringArray, wanted: Array[int]) -> Dictionary:
	var groups: Dictionary = cells_by_key(paintable(world))
	var missing: Array[int] = []
	var least: int = -1
	for tile: int in wanted:
		var many: int = (groups[tile] as Array[Vector2i]).size() if groups.has(tile) else 0
		if many == 0:
			missing.append(tile)
		least = many if least < 0 else mini(least, many)
	return {"groups": groups, "missing": missing, "wanted": wanted.size(),
			"found": wanted.size() - missing.size(), "least": maxi(least, 0),
			"is_complete": missing.is_empty()}
