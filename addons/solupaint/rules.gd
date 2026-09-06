# LA REGLE DE POSE — la meme que celle du logiciel, rejouee chez l'acheteur.
#
# Ce fichier est le portage EXACT de `core/massifs.gd`, de la canonicalisation de
# `core/blob_index.gd` et de l'epaisseur de `core/thickness.gd`. Il ne depend de rien : ni du
# logiciel, ni d'un noeud, ni d'une scene. On peut le lire en headless, et c'est ce que fait la
# suite de tests.
#
# ⚠ POURQUOI UNE COPIE, ALORS QUE DEUX COPIES D'UNE REGLE FINISSENT TOUJOURS PAR DIVERGER.
# Parce qu'il n'y a pas le choix : le plugin part chez l'acheteur, dans SON projet, ou
# `res://core/` n'existe pas. La question n'est donc pas « comment eviter la copie » mais
# « comment prouver que les deux disent la meme chose ». La reponse est dans `tests/run.gd` :
# sur des reliefs exhaustifs, sur les guides livres et sur des reliefs tires au sort, chaque
# case doit recevoir du plugin exactement la meme pose que du noyau -- meme etage, meme bande,
# meme silhouette, meme bit de ras. Une divergence d'une seule case fait echouer la suite
# (charte, regle 4). ⚠ ET LA COMPARAISON SE FAIT DANS LES DEUX SENS : un plugin qui ne poserait
# rien du tout passerait un controle qui se contente de verifier que ce qu'il pose est juste.
#
# ⚠ ET LE MONDE N'EST PAS BORNE ICI. Le logiciel travaille sur un guide rectangulaire ; un monde
# de jeu n'a pas de bord. Le relief est donc un dictionnaire case -> etage, et l'absence vaut le
# VIDE -- jamais la plaine. Un moteur qui lirait l'absence comme de la plaine etendrait le sol a
# l'infini et ne poserait aucune falaise de bord du monde, le tout sans une seule erreur.
extends RefCounted

# --- LE VOCABULAIRE DU VOISINAGE ---------------------------------------------

## Bits de voisinage, dans le sens horaire depuis le nord.
const N: int = 1
const NE: int = 2
const E: int = 4
const SE: int = 8
const S: int = 16
const SW: int = 32
const W: int = 64
const NW: int = 128

const CARDINALS: int = N | E | S | W

const BITS: Array[int] = [N, NE, E, SE, S, SW, W, NW]

const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Le hors-monde. ⚠ IL REND -1, PAS 0, ET C'EST CE QUI REND LE MODELE SUR : tout ce qui teste
## `>= N` avec N >= 1 est inchange -- le vide y echoue exactement comme la plaine -- et seul ce
## qui teste `>= 0` voit la difference, c'est-a-dire l'etage 0.
const VOID: int = -1

## LA CANONICALISATION. Un bit de coin n'est conserve que si les deux cardinaux adjacents sont
## pleins : un coin diagonal isole ne change pas la silhouette de la tuile, il ne doit donc pas
## produire une tuile de plus a peindre.
static func canonicalise(raw: int) -> int:
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


# --- LE MODELE DES MASSIFS ---------------------------------------------------

## LES BANDES, du haut vers le bas. ⚠ C'EST LE COUPLE (SILHOUETTE, BANDE) QUI EST LA TUILE :
## une meme silhouette d'empreinte tombe sur de l'herbe ou sur de la roche selon la bande, et ce
## sont deux matieres, donc deux dessins.
const SURFACE: int = 0
const CHAPITEAU: int = 1
const CORPS: int = 2
const PIED: int = 3
const BAND_NAMES: Array[String] = ["SURFACE", "CHAPITEAU", "CORPS", "PIED"]

## La hauteur d'un etage, en rangees de tuiles. ⚠ LE MANIFESTE LA REDIT, ET LE LECTEUR LA
## COMPARE A CELLE-CI : un tileset dont l'etage descend de quatre rangees, pose par un moteur
## qui en compte trois, donnerait un monde faux SANS UNE SEULE ERREUR.
const FALL: int = 3

## Le seul bit de contexte qui reste. ⚠ IL SE RANGE AU-DESSUS DE LA BANDE, PAS A 256 --
## `COVERS = 256` vaudrait exactement `CHAPITEAU << 8`, et le bit de contexte se melangerait
## a la bande dans la meme cle.
const COVERS: int = 1 << 16

## LE CISAILLEMENT : de l'herbe et de la roche du MEME massif, cote a cote.
##
## ⚠ LA BANDE ENCODE DEJA LA TRANSITION VERTICALE -- surface, chapiteau, corps, pied -- et c'est
## pour ca que la levre porte son trait. RIEN n'encodait la transition HORIZONTALE : la
## silhouette se lit sur l'EMPREINTE, donc une case d'herbe dont la voisine est la falaise de son
## PROPRE massif a ce bit MIS, se croit pleine, et rend la tuile d'interieur qui se repete
## partout. Personne ne tracait la frontiere, et la roche s'arretait NET contre l'herbe.
##
## ⚠ ET IL SE LIT SUR L'EMPREINTE DU MASSIF, JAMAIS SUR CE QUI SE VOIT. Un massif se dessine
## ENTIER, y compris sous ce qui le recouvre : lire le cisaillement sur la carte visible ferait
## dependre l'identite d'une tuile de ce qu'on pose dessus -- exactement ce que ce modele existe
## pour interdire.
const CUT_WEST: int = 1 << 17
const CUT_EAST: int = 1 << 18

## LE CISAILLEMENT PAR LE NORD : de la roche du MEME massif au-dessus de l'herbe. Quand un
## massif cisaille, la SURFACE aussi a son extremite nord, et la case du coude se croyait
## pleine : le trait s'arretait net au lieu de se refermer.
##
## ⚠ IL NE SE LIT QUE POUR L'HERBE, PAS SYMETRIQUEMENT. Une falaise a toujours du massif
## au-dessus d'elle, et la BANDE le dit deja -- chapiteau au premier pas, corps ensuite.
const CUT_NORTH: int = 1 << 19
const CUTS: int = CUT_WEST | CUT_EAST | CUT_NORTH

## Les quatre cardinaux, pour la cle au ras : au ras la profondeur est nulle, donc rien ne se
## creuse, pas meme les coins rentrants -- une tuile au ras ne depend que de ses cardinaux.
const KEY_CARDINALS: int = 0x55


## ⚠ ET LE CISAILLEMENT NE PASSE PAS PAR LA CANONICALISATION DU RAS. Au ras, seuls les cardinaux
## comptent -- la profondeur y est nulle. Mais le cisaillement ne dit rien du CONTOUR : il dit
## quelle MATIERE est a cote, dans la meme empreinte. Les deux sont orthogonaux.
static func key(band: int, sil: int, flush: bool, cut: int = 0) -> int:
	if not flush:
		return cut | (band << 8) | sil
	var bare: int = sil & KEY_CARDINALS
	if bare == KEY_CARDINALS:
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
## ⚠ JAMAIS LES DEUX A LA FOIS : il faudrait un doigt d'herbe d'UNE colonne entre deux jupes du
## meme massif, et min trois l'interdit.
static func cut_of(tile: int) -> int:
	return tile & CUTS


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


## L'etage d'une case. L'absence est du VIDE.
static func level_at(heights: Dictionary, cell: Vector2i) -> int:
	return int(heights.get(cell, VOID))


## L'etage le plus haut du monde.
static func top_level(heights: Dictionary) -> int:
	var top: int = 0
	for cell: Vector2i in heights.keys():
		top = maxi(top, int(heights[cell]))
	return top


## LES MASSIFS D'UN RELIEF.
##
## Rend `{"of_cell": {Vector3i(x, y, etage): int}, "level": [int], "covers": [bool],
## "cells": [Array[Vector2i]]}`.
##
## ⚠ UN MASSIF D'ETAGE L EST UNE COMPOSANTE CONNEXE DES CASES DE NIVEAU **AU MOINS** L -- pas
## exactement L. Groupe a l'etage exact, le porteur devient un ANNEAU troue la ou le massif du
## dessus se pose, son bord interieur se creuse, et on voit la plaine a travers son propre
## milieu. Les massifs sont donc EMBOITES : une case de niveau 3 appartient aux massifs 3, 2, 1
## et 0.
##
## ⚠ ET ON LES TROUVE DU PLUS BAS AU PLUS HAUT, du dehors vers le dedans. Un balayage par case
## tomberait sur le plus haut d'abord et couperait celui qui le porte en deux.
static func of(heights: Dictionary) -> Dictionary:
	var of_cell: Dictionary = {}
	var levels: Array[int] = []
	var groups: Array = []
	var order: Array[Vector2i] = _reading_order(heights)
	var top: int = top_level(heights)
	for level: int in range(0, top + 1):
		for here: Vector2i in order:
			if of_cell.has(Vector3i(here.x, here.y, level)):
				continue
			if level_at(heights, here) < level:
				continue
			var mark: int = groups.size()
			var cells: Array[Vector2i] = []
			var queue: Array[Vector2i] = [here]
			of_cell[Vector3i(here.x, here.y, level)] = mark
			while not queue.is_empty():
				var at: Vector2i = queue.pop_back()
				cells.append(at)
				for step: Vector2i in STEPS:
					var near: Vector2i = at + step
					if of_cell.has(Vector3i(near.x, near.y, level)):
						continue
					if level_at(heights, near) < level:
						continue
					of_cell[Vector3i(near.x, near.y, level)] = mark
					queue.append(near)
			groups.append(cells)
			levels.append(level)

	# QUI EST AU RAS, ET C'EST LE CHEVAUCHEMENT QUI LE DIT -- PAS L'ETAGE.
	#
	# ⚠ UN MASSIF ENTIEREMENT ENTOURE PAR CELUI QUI LE PORTE N'A AUCUNE RAISON D'ETRE AU RAS.
	# Son contour ne longe que de la matiere ; ce qu'il decouvre en vagabondant, c'est la surface
	# du porteur, qui est la de toute facon. Il garde donc toute sa liberte.
	#
	# ⚠ CE QUI FORCE LE RAS, C'EST LE CHEVAUCHEMENT : une partie dedans, une partie dehors. La,
	# le contour du massif du dessus longe la FRONTIERE du massif du dessous, et les deux
	# decrivent le meme endroit sans pouvoir se concerter -- une tuile ne repond que d'elle-meme.
	# Le seul point de rendez-vous qu'ils partagent est la bordure de tuile.
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
		var mine: Dictionary = footprint(heights, groups[mark3] as Array, levels[mark3])
		var first: Vector2i = (groups[mark3] as Array)[0]
		var below: int = int(of_cell.get(Vector3i(first.x, first.y, levels[mark3] - 1), -1))
		if below < 0:
			covers[mark3] = true
			continue
		var host: Dictionary = footprint(heights, groups[below] as Array, levels[below])
		for cell: Vector2i in mine.keys():
			if covers[mark3]:
				break
			for step2: Vector2i in STEPS:
				var near2: Vector2i = cell + step2
				if mine.has(near2) or host.has(near2):
					continue
				covers[mark3] = true
				break
	return {"of_cell": of_cell, "level": levels, "covers": covers, "cells": groups}


## ⚠ L'ORDRE DE PARCOURS EST CELUI DE LECTURE, comme dans le noyau. Il ne change aucune tuile --
## une composante connexe est la meme quel qu'en soit le point de depart -- mais il rend la
## numerotation des massifs identique des deux cotes, donc la comparaison lisible.
static func _reading_order(heights: Dictionary) -> Array[Vector2i]:
	var order: Array[Vector2i] = []
	order.assign(heights.keys())
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x if a.y == b.y else a.y < b.y)
	return order


## LE BIT D'UNE CASE, a l'etage demande : son massif en recouvre-t-il un autre ?
static func flush_at(made: Dictionary, at: Vector2i, level: int) -> bool:
	var of_cell: Dictionary = made["of_cell"]
	var cell_key: Vector3i = Vector3i(at.x, at.y, level)
	if not of_cell.has(cell_key):
		return false
	return bool((made["covers"] as Array[bool])[int(of_cell[cell_key])])


## L'EMPREINTE D'UN MASSIF : sa SURFACE, plus la FALAISE qui pend sous chaque bord sud.
## Rend `{Vector2i: bande}`.
##
## ⚠ ET C'EST SUR L'EMPREINTE QUE LA SILHOUETTE SE LIT, PAS SUR LA SURFACE. Une case de falaise
## a des voisines de falaise ; lire son voisinage dans la surface la dirait isolee.
##
## ⚠ LA CHUTE N'EST PAS FORFAITAIRE : ELLE VA JUSQU'AU SOL QU'ELLE ATTEINT. Un etage vaut TROIS
## rangees ; la face descend rangee par rangee et regarde le sol a chaque pas -- le bas de la
## face apres k rangees est a `etage - k/3`. Elle s'arrete des que la roche la rencontre, et
## elle NE POSE SON PIED que si elle atterrit pile sur un palier : le pied est la preuve d'un
## atterrissage. Sans palier, elle tombe dans le vide et ne pose rien -- on ne touche pas le
## fond d'un gouffre.
##
## ⚠ LE BORD SUD SE LIT PAR COLONNE, ET UN MASSIF PEUT EN AVOIR PLUSIEURS. Une encoche ouverte
## au sud donne deux bords sud dans la meme colonne, et chacune porte sa falaise. `lips`, s'il
## est fourni, recoit pour chaque case de falaise LA LEVRE dont elle pend.
static func footprint(heights: Dictionary, cells: Array, level: int,
		lips: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {}
	var surface: Dictionary = {}
	for cell: Variant in cells:
		surface[cell as Vector2i] = true
		out[cell as Vector2i] = SURFACE
	for cell2: Variant in cells:
		var at: Vector2i = cell2 as Vector2i
		if surface.has(at + Vector2i.DOWN):
			continue
		var fall: int = 0
		var landed: bool = false
		for k: int in range(1, FALL * (level + 1) + 1):
			var ground: int = level_at(heights, at + Vector2i(0, k))
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
	return out


## TOUT CE QU'UN RELIEF POSE, DANS L'ORDRE DE DESSIN.
##
## Rend une liste de `{"cell", "band", "sil", "flush", "level", "lip", "massif"}`.
##
## ⚠ UNE CASE RECOIT UNE POSE PAR MASSIF QUI LA CONTIENT. Les massifs sont emboites et chacun
## existe ENTIEREMENT : la case d'un plateau d'etage 3 est aussi une case interieure du massif
## d'etage 2, de celui d'etage 1 et de la plaine. On les pose toutes, du dessous vers le
## dessus ; la derniere gagne. C'est l'occlusion par ordre de rendu, et c'est tout ce qu'un
## chevauchement est.
##
## ⚠ ET L'ORDRE EST LA RANGEE, PAS L'ETAGE : la vue est de trois quarts, ce qui est plus au SUD
## est plus pres du regard. L'etage ne departage qu'a rangee EGALE -- ce qui est exactement le
## cas de deux poses sur une meme case.
static func poses(heights: Dictionary) -> Array[Dictionary]:
	var made: Dictionary = of(heights)
	var groups: Array = made["cells"]
	var levels: Array[int] = made["level"]
	var covers: Array[bool] = made["covers"]
	var out: Array[Dictionary] = []
	for mark: int in range(groups.size()):
		var lips: Dictionary = {}
		var print_of: Dictionary = footprint(heights, groups[mark] as Array, levels[mark], lips)
		for cell: Vector2i in print_of.keys():
			var raw: int = 0
			for bit: int in range(8):
				if print_of.has(cell + OFFSETS[bit]):
					raw |= 1 << bit
			# LE CISAILLEMENT SE LIT DANS L'EMPREINTE DE CE MASSIF : une voisine qui s'y
			# trouve est du meme massif par construction.
			var grass: bool = int(print_of[cell]) == SURFACE
			var cut: int = 0
			if print_of.has(cell + Vector2i.LEFT) \
					and (int(print_of[cell + Vector2i.LEFT]) == SURFACE) != grass:
				cut |= CUT_WEST
			if print_of.has(cell + Vector2i.RIGHT) \
					and (int(print_of[cell + Vector2i.RIGHT]) == SURFACE) != grass:
				cut |= CUT_EAST
			# ⚠ LE NORD NE SE LIT QUE POUR L'HERBE : la bande dit deja ce qu'une falaise a
			# au-dessus d'elle.
			if grass and print_of.has(cell + Vector2i.UP) \
					and int(print_of[cell + Vector2i.UP]) != SURFACE:
				cut |= CUT_NORTH
			out.append({"cell": cell, "band": int(print_of[cell]), "level": levels[mark],
					"sil": canonicalise(raw), "flush": covers[mark], "cut": cut,
					"lip": lips.get(cell, Vector2i(-9999, -9999)), "massif": mark})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ay: int = (a["cell"] as Vector2i).y
		var by: int = (b["cell"] as Vector2i).y
		if ay != by:
			return ay < by
		return int(a["level"]) < int(b["level"]))
	return out


## CE QUE CHAQUE COUCHE PORTE : `etage -> {case: cle de tuile}`.
##
## ⚠ UNE COUCHE PAR ETAGE, ET C'EST EXACTEMENT L'ORDRE DE POSE. Deux poses d'une meme case ont
## forcement des etages differents -- a un etage donne, une case n'appartient qu'a une
## composante -- donc les empiler par etage croissant rend le meme resultat que la liste triee.
## Et l'ordre des rangees ne compte pas ici : une tuile posee sur une case ne couvre jamais une
## autre case.
static func layers(heights: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for one: Dictionary in poses(heights):
		var level: int = int(one["level"])
		if not out.has(level):
			out[level] = {}
		(out[level] as Dictionary)[one["cell"]] = key_of(one)
	return out


# --- CE QUE LE PINCEAU A LE DROIT DE FAIRE -----------------------------------

## L'etage d'une case en tenant compte des changements mis en scene mais pas encore poses.
static func level_after(heights: Dictionary, staged: Dictionary, at: Vector2i) -> int:
	if staged.has(at):
		return int(staged[at])
	return int(heights.get(at, VOID))


## UNE CASE FINE : sa course le long d'un axe fait moins de TROIS, dans la silhouette d'un
## etage. ⚠ MIN TROIS, C'EST BORD + CENTRE + BORD. Une bande de deux n'a pas d'interieur -- deux
## bords dos a dos -- et le peintre ne peut alors rien supposer du cote masse de ses tuiles.
## La regle vaut dans les DEUX etats, plein et vide, et a tous les etages.
static func thin_after(heights: Dictionary, staged: Dictionary, at: Vector2i) -> bool:
	var centre: int = level_after(heights, staged, at)
	# ⚠ L'ETAGE LE PLUS HAUT SE CHERCHE SUR TOUTE LA PORTEE DE LA COURSE, PAS SUR LES QUATRE
	# VOISINES. La course va a DEUX cases : une voisine lointaine plus haute coupe une course de
	# vide a un etage que les quatre proches ne font pas exister, et cet etage-la n'etait jamais
	# examine. Le noyau, lui, parcourt tous les etages du monde -- avec la portee entiere les
	# deux disent exactement la meme chose, et c'est ce que le controle croise verifie.
	var top: int = centre
	for axis: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
		for direction: int in [-1, 1]:
			for reach: int in [1, 2]:
				top = maxi(top, level_after(heights, staged, at + axis * direction * reach))
	for storey: int in range(0, top + 1):
		var full: bool = centre >= storey
		for axis: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var length: int = 1
			for direction: int in [-1, 1]:
				for step: int in [1, 2]:
					var beside: int = level_after(heights, staged,
							at + axis * direction * step)
					if (beside >= storey) != full:
						break
					length += 1
			if length < 3:
				return true
	return false


## LE PINCEMENT DIAGONAL : deux cases de meme etat qui se touchent COIN CONTRE COIN, alors que
## les deux cases cardinales qu'elles partagent sont de l'autre etat.
##
## ⚠ MIN TROIS DOIT VALOIR EN DIAGONALE AUSSI, ET MIN TROIS NE LE COUVRE PAS. Deux massifs
## relies par un seul coin sont relies par une bande d'epaisseur UN : le modele doit alors
## exprimer une jonction que rien ne peut dessiner proprement. C'est l'argument de min trois,
## sur l'autre axe.
static func pinched_after(heights: Dictionary, staged: Dictionary, at: Vector2i) -> bool:
	var top: int = 0
	for dy: int in range(2):
		for dx: int in range(2):
			top = maxi(top, level_after(heights, staged, at + Vector2i(dx, dy)))
	for storey: int in range(0, top + 1):
		var here: bool = level_after(heights, staged, at) >= storey
		var down_right: bool = level_after(heights, staged, at + Vector2i(1, 1)) >= storey
		var right: bool = level_after(heights, staged, at + Vector2i(1, 0)) >= storey
		var down: bool = level_after(heights, staged, at + Vector2i(0, 1)) >= storey
		if here == down_right and right == down and here != right:
			return true
	return false


## LE TAMPON DU PINCEAU RENDRAIT-IL LE MONDE ILLEGAL ?
##
## S'il passe, ses changements RESTENT en scene -- les tampons suivants du meme trait les
## voient ; s'il est refuse, tout est remis comme avant, valeur par valeur.
##
## ⚠ ON NE CONTROLE QUE CE QUI SE LIT LOCALEMENT : l'epaisseur et le pincement, autour du
## tampon. La marge de pied et les gouffres, eux, demandent d'assembler le monde entier ; ils
## restent au logiciel, qui batit le guide. Un monde qui les violerait poserait des tuiles hors
## du vocabulaire, et `world.gd` le DIT plutot que de laisser un trou muet.
static func stamp_refused(heights: Dictionary, staged: Dictionary,
		cells: Array[Vector2i], level: int) -> bool:
	var before: Dictionary = {}
	for at: Vector2i in cells:
		before[at] = staged[at] if staged.has(at) else null
		staged[at] = level
	var probes: Dictionary = {}
	for at2: Vector2i in cells:
		for dy: int in range(-2, 3):
			for dx: int in range(-2, 3):
				probes[at2 + Vector2i(dx, dy)] = true
	var refused: bool = false
	for probe: Vector2i in probes.keys():
		if thin_after(heights, staged, probe) or pinched_after(heights, staged, probe):
			refused = true
			break
	if refused:
		for at3: Vector2i in cells:
			if before[at3] == null:
				staged.erase(at3)
			else:
				staged[at3] = before[at3]
	return refused
