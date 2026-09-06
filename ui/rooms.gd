# LES ROOMS — les ateliers du logiciel, et rien d'autre.
#
# Une room n'est PAS un reglage : c'est un endroit ou l'on travaille. Le travail lui-meme --
# le carnet, le guide, le mode, la resolution -- est PARTAGE ; la room ne change que ce que
# le centre montre et les gestes qu'on a en main. Dessin aujourd'hui, Test et Animation
# demain.
#
# ⚠ CE FICHIER NE CONNAIT NI NOEUD NI SCENE, seulement des NOMS. C'est ce qui le rend
# mesurable sans monter l'editeur -- meme raison que `Editor.must_confirm`, et la lecon est
# deja payee : aucun banc ne monte l'interface, donc tout ce qui n'est pas sorti d'elle ne
# se verifie jamais. Il vit dans `ui/` et non dans `core/` parce qu'il parle bien de
# l'ecran ; il n'en manipule simplement aucun morceau.
#
# ⚠ ET LES ROOMS SONT FIXES : elles font partie du logiciel. Ce qui s'ajoute et se supprime,
# ce sont les ENSEMBLES -- un tileset complet par art -- et ils vivront dans une bande
# flottante au-dessus de la zone, pas ici. Un nom d'ensemble est du texte libre, et un
# libelle qui s'allonge impose sa largeur a toute la barre : c'est exactement pourquoi les
# deux ne peuvent pas partager le meme endroit.
extends RefCounted

## L'atelier d'aujourd'hui : le guide, le crayon, les jauges.
const DESSIN: StringName = &"dessin"
## Poser un vrai relief au pinceau du moteur et le voir rendu avec SES tuiles.
const TEST: StringName = &"test"
## La frame courante bascule pour tout le guide ; on peint comme avant.
const ANIMATION: StringName = &"animation"

## ⚠ UN LIBELLE QUI S'ALLONGE IMPOSE SA LARGEUR A TOUTE LA BARRE. Paye deux fois au dossier,
## et une grille de boutons est l'endroit ou ca se repaie : deux colonnes, donc chaque nom
## pousse la moitie de la barre. La borne est verifiee au banc, pas esperee.
const LABEL_MAX: int = 12

## Les sections repliables de l'ecran, par leur NOM DE NOEUD -- trois a gauche, trois a
## droite. ⚠ ELLES SE VERIFIENT CONTRE LA SCENE au banc : une room qui nommerait une section
## fantome ne montrerait rien, sans une erreur, et c'est le genre de faute qu'aucune
## relecture ne voit (« une insertion qui se trompe ne se voit nulle part »).
static func known_sections() -> PackedStringArray:
	return PackedStringArray(["WorkSection", "BackgroundSection", "EngineSection",
			"PencilSection", "NeighboursSection", "ViewSection"])


static var ROOMS: Dictionary = {}


static func _static_init() -> void:
	ROOMS = {
		DESSIN: {
			"label": "Dessin",
			"sections": known_sections(),
		},
		TEST: {
			"label": "Test",
			# Ni crayon, ni voisines, ni cases de vue : on n'y peint pas de faux pixels, on y
			# pose du RELIEF, et les cases de vue parlent toutes du guide. « Projet » et
			# « Moteur » restent -- on vient ici pour juger ce qu'on exportera.
			"sections": PackedStringArray(["WorkSection", "EngineSection"]),
		},
		ANIMATION: {
			"label": "Animation",
			"sections": known_sections(),
			"closed": true,
			"why": "L'animation par frame demande d'abord l'axe des frames au carnet.",
		},
	}


## Les rooms OUVERTES, dans l'ordre des boutons.
##
## ⚠ UNE ROOM FERMEE NE FIGURE PAS DANS LA LISTE, elle n'y est pas grisee. Une entree grisee
## ne dit « ceci viendra » que si l'on sait ce qu'est « ceci » -- et le dossier a deja retire
## une entree pour cette raison exacte. Meme regle que `Modes.is_closed`.
static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in ROOMS.keys():
		if not is_closed(id):
			out.append(id)
	return out


## Toutes les rooms, ouvertes ou non. Pour le banc, et pour rien d'autre.
static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in ROOMS.keys():
		out.append(id)
	return out


static func has(id: StringName) -> bool:
	return ROOMS.has(id)


static func is_closed(id: StringName) -> bool:
	return ROOMS.has(id) and bool(ROOMS[id].get("closed", false))


## La room ou l'on entre en ouvrant le logiciel.
static func default_id() -> StringName:
	return DESSIN


static func label(id: StringName) -> String:
	if not ROOMS.has(id):
		push_error("rooms: room inconnue '%s'." % id)
		return ""
	return String(ROOMS[id]["label"])


## Ce qui manque pour qu'une room s'ouvre. ⚠ UN REFUS MUET EST LE PIRE DES REFUS : le jour ou
## une room se montre fermee, elle doit dire de quoi elle depend.
static func why_closed(id: StringName) -> String:
	if not is_closed(id):
		return ""
	return String(ROOMS[id].get("why", ""))


## Les sections que cette room montre.
static func sections(id: StringName) -> PackedStringArray:
	if not ROOMS.has(id):
		push_error("rooms: room inconnue '%s'." % id)
		return PackedStringArray()
	return ROOMS[id]["sections"]


## Cette room montre-t-elle cette section ? ⚠ UNE SECTION INCONNUE EST CACHEE, pas montree :
## le jour ou l'ecran en gagne une que personne n'a rangee dans une room, elle ne doit pas
## apparaitre partout par accident.
static func shows(id: StringName, section: String) -> bool:
	return sections(id).has(section)


## ⚠ UNE LISTE A UNE SEULE ENTREE N'EST PAS UN CHOIX, C'EST UN DECOR. La regle est deja
## ecrite dans l'editeur pour le reseau -- « la ligne entiere s'efface tant qu'il n'y a qu'un
## reseau, et reparaitra d'elle-meme le jour ou un second existera » -- et elle vaut ici
## telle quelle : tant que Dessin est seule, la grille ne montre rien qu'on puisse choisir.
## Elle s'allumera d'elle-meme quand la room de test ouvrira.
static func worth_showing() -> bool:
	return ids().size() >= 2
