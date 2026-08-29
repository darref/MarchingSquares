# LE DOMAINE -- QUELS RELIEFS L'ACHETEUR A LE DROIT DE BATIR, en clauses, a un seul endroit.
#
# ⚠ C'EST LA PREMISSE DE TOUT CE QUI SE COMPTE ENSUITE, et c'est ce qui lui vaut un fichier.
# Les 27 silhouettes sont le theoreme des 256 fenetres SOUS CE DOMAINE ; la borne haute du
# vocabulaire (`tools/closed_form_now.py`) se calcule SOUS CE DOMAINE ; le pinceau de
# SoluPaint refuse SOUS CE DOMAINE. Recite de memoire a trois endroits, il finit par dire
# trois choses -- exactement ce que le manifeste-contrat existe pour empecher, un cran plus
# haut. La promesse de l'acheteur en depend mot pour mot : AUCUN RELIEF REFUSE, SAUF CEUX
# QU'ON NE PROPOSE PAS A DESSEIN.
#
# ⚠ ET IL NE REIMPLEMENTE RIEN. Chaque clause nomme le code qui l'APPLIQUE, et `violations()`
# appelle ce code. Une clause avec sa propre copie de la regle serait un second endroit ou
# mentir -- la faute meme que ce fichier existe pour supprimer.
#
# ⚠ LES REFUS PAR ABSENCE SONT DES CLAUSES AUSSI. « Pas de rampes » n'est pas un trou du
# modele, c'est une decision. Sans elles ecrites, on ne distingue plus ce qui est refuse a
# dessein de ce qui est refuse par accident -- et c'est cette distinction qu'on vend.
#
# ⚠ ET LES CLAUSES ECARTEES RESTENT ECRITES AVEC LEUR MESURE. Trois clauses de grammaire ont
# ete chiffrees puis refusees ; sans la trace, elles se reproposent tous les mois.
#
# ⚠ CE QUI N'EST PAS UNE CLAUSE DE DOMAINE : tout ce qui dit comment le monde se DESSINE.
# « Un plateau n'a de face qu'au sud », « on ne voit que le sommet », « une robe qui tombe
# dans le vide ne pose pas son pied » sont des regles de POSE -- elles ne refusent aucun
# relief, elles disent quoi poser dessus. Leur place est au manifeste (`_spec()`), pas ici.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")

## Une clause qui restreint ce que le MONDE a le droit d'etre. Mesurable, donc mesuree.
const KIND_WORLD: String = "monde"
## Une clause qui ne pese que sur un GUIDE -- le monde de l'acheteur n'est pas borne.
const KIND_GUIDE: String = "guide"
## Un refus par ABSENCE : ce qu'on ne propose pas, et pourquoi. Rien a mesurer.
const KIND_ABSENT: String = "absence"
## Une clause CHIFFREE PUIS ECARTEE. Elle est ici pour ne pas se represcrire seule.
const KIND_DROPPED: String = "ecartee"


## Les clauses, une par une. `mesure` vide = rien a mesurer (absence, ou clause ecartee).
##
## ⚠ UNE FONCTION, PAS UN `const` : un `const` de tableau typé ne se resout pas toujours en
## GDScript, et quand il tombe il emporte tout ce qui precharge le fichier, SANS erreur
## claire. La lecon est deja au dossier, payee une fois.
static func clauses() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	out.append({
		"id": "D1", "kind": KIND_WORLD, "titre": "trois especes d'altitude",
		"enonce": "Une case est le VIDE (-1), la PLAINE (0), ou un plateau de 1 a "
				+ str(HeightMask.MAX_LEVEL) + ". Il n'y a rien d'autre, et le hors-monde "
				+ "est du vide : hors de la grille pour le logiciel, absent du "
				+ "dictionnaire pour le moteur.",
		"applique": "core/height_mask.gd (parseur strict, level_at) ; "
				+ "addons/solupaint/rules.gd (heights.get(cell, VOID))",
		"mesure": "chaque caractere est `~`, `.`, ou un chiffre 0..9",
	})

	out.append({
		"id": "D2", "kind": KIND_WORLD, "titre": "rien de fin -- min trois",
		"enonce": "La COURSE d'une case -- la suite de cases du meme etat qui la contient "
				+ "le long d'un axe -- fait au moins TROIS : bord, centre, bord. Dans "
				+ "CHAQUE silhouette d'etage, plaine comprise, pour l'etat PLEIN comme "
				+ "pour l'etat VIDE. C'est la seule clause qui refuse un geste.",
		"applique": "core/thickness.gd (thin_cells) ; addons/solupaint/rules.gd "
				+ "(stamp_creates_thin), copie comparee au noyau par la suite",
		"mesure": "Thickness.thin_cells() est vide",
	})

	out.append({
		"id": "D3", "kind": KIND_WORLD, "titre": "les chutes profondes sont acquises",
		"enonce": "Une levre tombe de UN A " + str(HeightMask.MAX_LEVEL) + " etages, soit 3 "
				+ "a 27 cases, avec la meme feuille finie. AUCUNE clause n'a le droit de "
				+ "les limiter -- decision utilisateur, et elle ecarte d'office toute "
				+ "grammaire qui les rognerait.",
		"applique": "core/walls.gd (fall_at, row_for : le corps tourne sur lui-meme)",
		"mesure": "",
	})

	out.append({
		"id": "G1", "kind": KIND_GUIDE, "titre": "un guide declare son bord",
		"enonce": "Un guide est borne, donc il s'entoure de vide sur une CHUTE ENTIERE -- "
				+ "trois rangees -- sinon la falaise du bord du monde tombe hors du cadre "
				+ "et devient impeignable. Le monde de l'acheteur, lui, n'est pas borne : "
				+ "la clause ne lui est jamais opposee.",
		"applique": "tests/run.gd (zero robe hors grille sur les guides livres)",
		"mesure": "",
	})

	out.append({
		"id": "G2", "kind": KIND_GUIDE, "titre": "un guide exerce tout le vocabulaire",
		"enonce": "Chaque tuile du vocabulaire s'y trouve au moins `min_occurrences` fois, "
				+ "HORS PLAINE puisque l'etage 0 ne se peint pas. Une tuile absente du "
				+ "guide est une tuile que l'acheteur ne peut pas peindre.",
		"applique": "core/modes.gd (min_occurrences) ; tests/run.gd (hors plaine)",
		"mesure": "",
	})

	out.append({
		"id": "A1", "kind": KIND_ABSENT, "titre": "pas de rampes ni d'escaliers doux",
		"enonce": "Deux etages adjacents sont une falaise, TOUJOURS. Une rampe ne se deduit "
				+ "pas : rien dans une carte de hauteurs ne la distingue d'une chute, il "
				+ "faudrait un marqueur declare comme `~` l'a ete pour le vide. Chantier "
				+ "ouvert, chiffre : un troisieme vocabulaire, sa regle au contrat, sa "
				+ "copie au plugin, son controle croise.",
		"applique": "", "mesure": "",
	})

	out.append({
		"id": "A2", "kind": KIND_ABSENT, "titre": "pas de matieres bordees",
		"enonce": "Ni eau ni sable : une seule matiere par etage. Une matiere est un etage "
				+ "sans falaise, donc +47 tuiles par matiere et par case -- a deux "
				+ "conditions qui sont des decisions (les matieres sont ORDONNEES, et une "
				+ "matiere ne touche ni la levre ni le bord de son etage). Chantier ouvert.",
		"applique": "", "mesure": "",
	})

	out.append({
		"id": "A3", "kind": KIND_ABSENT, "titre": "pas de gouffre a fond",
		"enonce": "Une robe qui tombe dans le vide ne pose pas son pied : on ne touche pas "
				+ "le fond d'un gouffre. Le vide est un dehors, pas un etage negatif.",
		"applique": "core/walls.gd (fall_at : un etage de plus, aucun pied)", "mesure": "",
	})

	out.append({
		"id": "X1", "kind": KIND_DROPPED, "titre": "aucune paroi de moins de trois colonnes",
		"enonce": "ECARTEE. Elle ne rendrait que le pan `arret|arret` et ses cinq rangees "
				+ "-- 20 roles a 15, rien sur les surfaces -- et NOS PROPRES MONDES LA "
				+ "VIOLENT : le guide livre porte 12 cases de ce pan. Refuser un relief "
				+ "qu'on livre soi-meme n'est pas une grammaire, c'est une contradiction.",
		"applique": "core/thickness.gd (lonely_robe_cells : la mesure, pas un refus)",
		"mesure": "",
	})

	out.append({
		"id": "X2", "kind": KIND_DROPPED,
		"titre": "deux faces d'etages differents ne se touchent pas",
		"enonce": "ECARTEE, et elle ne rend RIEN. Elle avait ete ecrite pour le pan "
				+ "`(devant, devant)`, qui N'EXISTE PLUS depuis la decomposition en "
				+ "couches. Une clause candidate se relit contre le vocabulaire DU JOUR, "
				+ "pas contre celui qui l'a fait naitre.",
		"applique": "", "mesure": "",
	})

	out.append({
		"id": "X3", "kind": KIND_DROPPED,
		"titre": "une levre ne se decale que par blocs de trois colonnes",
		"enonce": "ECARTEE. Elle rend UN role -- `arret|arret` au chapiteau seulement -- "
				+ "donc strictement moins que X1, pour des escaliers plus grossiers.",
		"applique": "", "mesure": "",
	})

	return out


## Les clauses de MONDE que ce relief viole, par identifiant. Vide = relief legal.
##
## ⚠ ON NOMME LA CLAUSE, ON NE REND PAS `false`. Un refus muet est le pire des refus : le
## pinceau doit pouvoir dire CE QUI manque, pas seulement qu'il refuse.
static func violations(heights: PackedStringArray) -> Array[String]:
	var out: Array[String] = []
	if not _levels_legal(heights):
		out.append("D1")
	if not Thickness.thin_cells(heights).is_empty():
		out.append("D2")
	return out


## Ce relief est-il dans le domaine ?
static func accepts(heights: PackedStringArray) -> bool:
	return violations(heights).is_empty()


## L'enonce d'une clause, par identifiant -- vide si elle n'existe pas.
static func clause(id: String) -> Dictionary:
	for entry: Dictionary in clauses():
		if String(entry["id"]) == id:
			return entry
	return {}


## D1 : le CARACTERE de chaque case est le vide, la plaine, ou un chiffre.
##
## ⚠ ON LIT LE CARACTERE, PAS `level_at` -- et c'est ce qui rend la mesure reelle. `level_at`
## rend `to_int()` sur ce qu'il ne connait pas, donc un caractere aberrant se lit PLAINE, en
## silence : une mesure qui passe par lui ne pourrait jamais rougir. Le parseur, lui, se
## defend deja ; ce qu'on garde ici, ce sont les masques batis A LA MAIN -- les outils, les
## battues, les temoins -- qui ne passent pas par le parseur.
static func _levels_legal(heights: PackedStringArray) -> bool:
	for row: String in heights:
		for column: int in range(row.length()):
			var character: String = row[column]
			if character == HeightMask.VOID_CHAR or character == HeightMask.PLAIN_CHAR:
				continue
			if character < "0" or character > "9":
				return false
	return true
