# LA ZONE DE TRAVAIL — la grille, le fond du guide, et les faux pixels qu'on y pose.
#
# Le fond n'est pas une image posee derriere : c'est le guide lui-meme, reconstitue depuis
# le relief par render/guide_image.gd, et cale sur la grille au pixel pres. Chaque case du
# guide porte `resolution` x `resolution` faux pixels, et ce sont eux qu'on peint.
#
# ⚠ LE PINCEAU REFUSE CE QUI N'EST PAS UNE TUILE (charte, regle 5). Seules les cases qui
# portent quelque chose -- une surface visible ou une case de robe -- se peignent. La
# plaine n'est pas une tuile du tileset : y poser un pixel ne produirait rien.
#
# ⚠ TOUT GESTE SE FAIT EN PIXELS GLOBAUX, PAS EN CASES. Un point de l'ecran devient un faux
# pixel du plan entier ; c'est ce pixel qui dit quelle tuile il touche -- une case, une
# robe, ou un croisement decale d'une demi-case -- et ou il tombe dedans. Une seule
# resolution de « quelle tuile, quel pixel » sert tous les outils : le crayon, la brosse,
# l'aerographe, le pot, la ligne, le rectangle, la pipette et la gomme. Avant ca, le crayon
# lisait la CASE sous la souris, et ne savait donc pas peindre un croisement.
#
# ⚠ UNE TUILE, UNE IMAGE. Les jumelles partagent leur image dans le carnet (`Painting.share`)
# : peindre l'index 255 ecrit UN pixel, pas 1553, et l'ecran le dessine a chaque jumelle.
extends Control

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const Symmetry := preload("res://core/symmetry.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Examples := preload("res://core/examples.gd")
const Families := preload("res://core/families.gd")
const Seams := preload("res://core/seams.gd")
const RenderJob := preload("res://render/guide_render_job.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifScene := preload("res://render/massif_scene.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")

## Emis des que la peinture change : l'editeur s'en sert pour rafraichir ses compteurs.
signal painting_changed

## Emis pendant le calcul du fond, avec des valeurs REELLES : le nombre de tuiles
## distinctes deja dessinees, sur le nombre a dessiner.
signal loading_progress(done: int, total: int)

## Emis quand la case survolee change. L'editeur en fait un releve lisible.
signal hover_changed(cell: Vector2i)

## Finesse du fond. Il est mis a l'echelle a l'affichage : plus fin coute cher pour rien,
## un guide se regarde, il ne se compte pas au pixel.
const GUIDE_TILE: int = 32

const MIN_TILE_PX: float = 5.0
const MAX_TILE_PX: float = 2000.0
const PIXEL_GRID_FROM: float = 5.0

## Combien de cases au plus remontent au GPU par image.
## ⚠ SANS PLAFOND, OUVRIR UN TRAVAIL GELE LA FENETRE. Un guide entierement peint compte
## sept cents cases ; a 256 pixels de cote, les televerser d'un coup ferait cent quatre-vingt
## mega-octets en une seule image. Etalees, elles apparaissent en quelques dixiemes de
## seconde et rien ne bloque.
const UPLOAD_PER_FRAME: int = 48

## Temps accorde au calcul du fond a chaque image. Une tuile coute environ vingt
## millisecondes : le budget en laisse passer une par image, et l'interface reste vivante.
const LOAD_BUDGET_USEC: int = 12000

## LE VIDE -- hors du monde, c'est le fond du programme, et il est DECLARE ICI, une fois.
##
## ⚠ CE N'EST PAS UN TABLIER. L'ancien aplat de plaine debordait du guide et contredisait
## la falaise que celui-ci declare ; il a disparu en 4.0.0 et ne revient pas. Celui-ci
## n'ajoute aucune matiere : c'est exactement ce qu'on voit deja a cote du monde.
##
## ⚠ ET IL SE PEINT, IL NE SE SUPPOSE PAS. Sous la transparence d'une tuile COMMENCEE il
## faut effacer le guide, y compris la ou rien n'est pose dessous. La seule facon que
## l'efface et le dehors ne divergent JAMAIS est qu'ils sortent de la meme constante :
## s'en remettre a la couleur d'effacement du moteur, c'est deux endroits pour une couleur.
const VOID: Color = Color(0.3, 0.3, 0.3)

# Le fond representatif est soutenu : on l'attenue pour que les pixels poses ressortent.
# Le fond utilisable est deja en teinte basse, il n'a pas besoin d'etre efface.
const GUIDE_TINT: Color = Color(1.0, 1.0, 1.0, 0.55)
const GUIDE_TINT_WIRE: Color = Color(1.0, 1.0, 1.0, 0.92)
const TILE_LINE: Color = Color(1.0, 1.0, 1.0, 0.16)

## ⚠ LA CASE SANS JUMELLE. Quand une tuile n'apparait qu'UNE FOIS dans le guide, sa case
## est obligatoire : personne d'autre ne la portera, et l'oublier bloque l'export. Vingt-deux
## cases sur mille vingt-trois sont dans ce cas -- assez peu pour que les marquer se voie,
## assez pour que les oublier coute. Leur contour vire a l'ambre.
const LONE_LINE: Color = Color(0.980, 0.760, 0.330, 0.95)
const PIXEL_LINE: Color = Color(1.0, 1.0, 1.0, 0.05)
const HOVER_OK: Color = Color(1.0, 1.0, 1.0, 0.85)
const HOVER_REFUSED: Color = Color(0.925, 0.463, 0.396, 0.90)
## Les liees du survol : chaque case que le geste remplirait s'allume avant le clic. Un
## bleu franc, etranger a la palette du terrain comme aux autres marques (blanc du survol,
## rouge du refus, ambre des cases seules), pour que l'oeil ne les confonde jamais.
const LINKED_LINE: Color = Color(0.376, 0.804, 0.910, 0.85)
## La zone qui laisse voir derriere, hachuree legerement -- en peignant seulement. Les
## diagonales se posent ENTRE le socle et la tuile : la tuile les couvre la ou elle a de
## la matiere, elles ne restent donc visibles qu'au travers de sa transparence.
const SEE_THROUGH_HATCH: Color = Color(1.0, 1.0, 1.0, 0.18)

## ⚠ EN VUE D'ENSEMBLE, UN FAUX PIXEL MESURE MOINS D'UN PIXEL D'ECRAN. A la taille qui
## montre tout le guide, une case fait une trentaine de pixels et en porte soixante-quatre :
## ce qu'on pose est litteralement invisible, et l'on croit que rien ne se passe -- surtout
## quand le remplissage des jumelles touche cent cases d'un coup. En dessous de ce seuil, on
## cerne donc les cases qui portent de la peinture.
## Nulle part. ⚠ PAS Vector2i(-1, -1) : dans la famille a cheval c'est une cle valide,
## celle du croisement (0, 0).
const NOWHERE: Vector2i = Vector2i(-1048576, -1048576)

const TOUCHED_FROM: float = 1.6
const TOUCHED_MARK: Color = Color(0.949, 0.792, 0.475, 0.85)
const LOCK_RING: Color = Color(0.706, 0.741, 0.522, 0.95)
const PREVIEW_ERASE: Color = Color(1.0, 1.0, 1.0, 0.35)

var pencil: Color = Color(0.906, 0.855, 0.671)

## Emis quand la pipette a pris une couleur : l'editeur la pose dans le selecteur.
signal pencil_picked(color: Color)

## LES OUTILS. Tous posent des faux pixels par le meme chemin ; seule change la forme de ce
## qu'un point de souris depose.
enum Tool { PENCIL, BRUSH, AIRBRUSH, BUCKET, LINE, RECT, PICKER, ERASER }

var tool: Tool = Tool.PENCIL

## Le diametre, en faux pixels, de ce que posent la brosse, l'aerographe, la gomme, la
## ligne et le rectangle. Le crayon fait toujours un pixel : c'est sa definition.
var brush_size: int = 1

## Les diametres offerts. Une rangee de boutons, pas un curseur (charte, regle 1).
const BRUSH_SIZES: Array[int] = [1, 2, 3, 4, 6, 8]

## CONTRAINDRE LE CRAYON A LA TUILE : une passe reste dans la tuile ou elle a commence.
## Les pixels qui tombent dans une voisine sont ignores, pas ramenes au bord -- un geste
## qui deborde ne doit rien poser qu'on n'ait pas vise.
var lock_to_tile: bool = false

## La part des pixels du disque que l'aerographe depose a chaque jet.
const SPRAY_DENSITY: float = 0.08

## Peindre une case remplit aussi toutes ses symetriques, avec le dessin tourne ou
## retourne comme il faut. ⚠ CE N'EST PAS UNE CASE A COCHER : c'est le mode qui le decide,
## et seulement s'il livre des tuiles sans direction d'eclairage.
var paint_symmetry: bool = false

## Peindre une case peint aussi toutes celles qui portent la meme tuile.
## ⚠ CE N'EST PAS UN REGLAGE DU PRODUIT, c'est une aide au geste : elle ne change rien a ce
## qui sort, seulement au nombre de fois qu'il faut refaire le meme dessin.


## Ce qu'on regarde en peignant. ⚠ Rien de ce qui sort n'en depend : ce n'est pas
## l'eclairage du tileset, c'est le fond de l'ecran.
var guide_ink: GuideImage.Ink = GuideImage.Ink.PAINTED

## A quoi le fond sert : montrer le resultat, ou porter les marques de travail.
var guide_purpose: GuideImage.Purpose = GuideImage.Purpose.REPRESENTATIVE
## L'exemple montre en fond, s'il y en a un. Vide = notre dessin calcule.
## ⚠ IL EST A PART DE `guide_purpose`, qui appartient a l'ancien modele : un exemple se designe
## par son NOM, pas par une valeur d'enumeration qu'il faudrait etendre a chaque nouveau.
var guide_example: StringName = &""

## La famille de surface : par case (blob 47) ou a cheval (reseau dual, 15).
##
## ⚠ TOUT CE FICHIER TRAVAILLE EN CLES DE CARNET, PAS EN CASES. Dans la famille a cheval,
## un croisement et une case peuvent avoir les MEMES coordonnees -- 520 en commun sur le
## guide livre. La cle de carnet, elle, est disjointe par construction : les croisements
## vivent dans les y negatifs. En la prenant pour identite interne, la collision cesse
## d'exister au lieu d'etre evitee au cas par cas.
var guide_family: StringName = Families.BY_CELL

## Les marques de travail : les marqueurs de coin rentrant, les tirets de rangee, et
## l'EPAISSISSEMENT des traits. ⚠ Les trois se masquent ensemble parce que les trois sont
## des marques : le trait grossi n'existe pas pour etre beau, il existe pour rendre la
## specification lisible d'un coup d'oeil.
var guide_marks: bool = true

## Largeurs occupees par les deux barres, qui sont posees SUR la zone de travail.
## ⚠ ELLES NE SERVENT QU AU CADRAGE. On ne bride pas le dessin a ces marges : le guide
## peut passer dessous, et c'est meme le but -- on le voit a travers elles.
var reserved_left: float = 0.0
var reserved_right: float = 0.0

## LA GRILLE SE MONTRE OU SE CACHE — et elle emporte la NETTETE avec elle.
##
## Une grille est une aide a viser, pas un decor : quand on juge une couleur, elle gene. Mais
## la masquer ne suffisait pas a montrer le rendu final, et c'est la seconde moitie de son
## travail.
##
## ⚠ SOUS UN PIXEL D'ECRAN PAR FAUX PIXEL, UNE ECHELLE LIBRE RECOUPE LA TUILE. `_cell_box`
## arrondit chaque case a des pixels entiers -- il le faut, sinon deux voisines ne partagent
## pas leur frontiere -- donc la grille des faux pixels se remet d'aplomb A CHAQUE BORDURE.
## L'interieur bave, la bordure reste franche, et ce contraste EST la couture qu'on croyait
## voir apparaitre en masquant la grille. Elle etait la avant ; la grille la cachait.
##
## Grille masquee, l'echelle se cale donc a TOUS les crans : elle monte par multiples entiers
## de la resolution et descend par DIVISEURS entiers -- 1/2, 1/4, 1/8. Dans les deux sens
## chaque faux pixel est traite exactement comme son voisin, d'un bout du monde a l'autre.
##
## ⚠ ET ON PEINT TOUJOURS. C'est ce qui a fait supprimer le mode d'apercu qui portait ça au
## depart : si la nettete ne coute pas le crayon, elle n'a pas a se payer d'un mode ou l'on
## ne peut plus rien faire. Une case a cocher qui retire une gene, et rien d'autre.
##
## Grille visible, l'echelle garde sa liberte sous le pixel : la vue d'ensemble en a besoin,
## et c'est la qu'on CERNE les cases peintes plutot que de pretendre les montrer.
var show_grid: bool = true

## LE REMONTAGE : on efface tout ce qui n'est pas les tuiles peintes -- le fond du guide,
## les deux grilles, les cercles de repere -- et il ne reste que le paysage rebati.
##
## ⚠ C'EST LE SEUL CONTROLE QUE LE PROGRAMME NE PEUT PAS FAIRE. Il sait prouver que les
## tuiles existent ; il ne sait pas juger qu'elles SE RACCORDENT. Un bord est peint d'un
## cote, son voisin de l'autre, a deux moments differents. Seul l'oeil voit la couture.
##
## ⚠ ET UNE CASE NON PEINTE RESTE UN TROU. On ne la remplit pas d'un aplat aimable : le
## trou est la verite, et c'est exactement ce qu'on veut voir.
var assembled: bool = false

## L'inverse de `assembled` : on efface ce qui est peint et on ne garde que le guide.
## ⚠ LES DEUX SE COCHENT EN MEME TEMPS SANS SE CONTREDIRE : il ne reste alors rien du tout,
## et c'est une reponse honnete plutot qu'un cas interdit.
var hide_work: bool = false

## ⚠ LA LUMIERE PORTEE EST UNE DECORATION, PAS UN PRODUIT. Les ombres tombent sur des cases
## de plaine, et la plaine n'est pas une tuile : aucune tuile exportee ne peut les porter.
## Les masquer montre donc ce que le tileset sait REELLEMENT produire.
var hide_cast_light: bool = false

var _heights: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null
var _surface_cells: Dictionary = {}
var _wall_cells: Dictionary = {}
var _paintable: Dictionary = {}
var _lonely: Dictionary = {}
var _background: ImageTexture = null
var _background_flat: ImageTexture = null
var _textures: Dictionary = {}
var _tile_px: float = 32.0
var _origin: Vector2 = Vector2.ZERO
var _hover: Vector2i = NOWHERE
var _stroke: int = 0
var _last_paint: Vector2 = Vector2.ZERO
## La tuile ou la passe a commence, pour la contrainte.
var _stroke_tile: Vector2i = NOWHERE
## Le pixel global du clic, pour la ligne et le rectangle, et celui de la souris.
var _anchor: Vector2i = Vector2i.ZERO
var _cursor: Vector2i = Vector2i.ZERO
## Les disques de brosse, par diametre, calcules une fois.
var _discs: Dictionary = {}
var _panning: bool = false
var _stale: Dictionary = {}
var _changed: bool = false
var _twin_of: Dictionary = {}
var _wall_roles: Dictionary = {}
## Sous chaque case, la pile des sols enterres (un index par etage couvert) -- pour que le
## remontage empile comme le jeu : une tuile par etage et par case.
var _stack_below: Dictionary = {}
## LES CASES QUE LE MONDE OCCUPE : celles ou le modele pose au moins une tuile. C'est sur
## elles, et sur elles seules, que le guide s'efface quand la tuile est commencee.
##
## ⚠ CE N'EST PAS `_stack_below`, ET LES CONFONDRE ETAIT LE DEFAUT. Celui-la ne porte que
## les cases qui ont quelque chose SOUS elles ; une case dont la pile n'a qu'une pose n'y
## entrait pas, donc rien n'y effacait le guide, donc sa transparence montrait le guide au
## lieu du VIDE. Mesure sur le guide livre : 12 903 cases posees sur 19 492 n'ont qu'une
## pose -- toute la plaine et sa jupe de bord du monde -- dont 3 384 sont des tuiles de
## bord, celles qui ont justement de la transparence a montrer.
var _posed: Dictionary = {}
## Les poses du moteur : pied sous l'atterrissage, corps derriere l'ecretage, CHAPITEAU
## SOUS LA LEVRE. Case -> role de robe a dessiner entre le socle et la tuile.
var _under_roles: Dictionary = {}
var _by_index: Dictionary = {}
var _by_role: Dictionary = {}
var _targets: Dictionary = {}
var _needs_fit: bool = false
var _job: RefCounted = null
## Un fond de massifs annonce, pas encore compose. ⚠ IL LUI FAUT UNE IMAGE D'ECART : annoncer et
## composer dans la meme image ne montre rien, Godot ne dessine qu'entre deux images.
var _pending: bool = false
var _cache: Dictionary = {}
var _cache_key: String = ""


func _ready() -> void:
	resized.connect(_on_resized)


## ⚠ UNE TUILE NE REMONTE AU GPU QU UNE FOIS PAR IMAGE. Televerser la tuile entiere a
## chaque pixel pose ferait, a 256 de cote, un quart de mega-octet par pixel et par coup de
## souris. On marque la case sale, et on ne televerse qu ici.
func _process(_delta: float) -> void:
	if _pending:
		_compose_massifs()
	if _job != null:
		if _job.step(LOAD_BUDGET_USEC):
			_background = ImageTexture.create_from_image(_job.image())
			_background_flat = ImageTexture.create_from_image(_job.flat_image())
			_cache[_cache_key] = [_background, _background_flat]
			loading_progress.emit(_job.total, _job.total)
			_job = null
		else:
			loading_progress.emit(_job.done, _job.total)
		queue_redraw()
	# L'aerographe continue de cracher tant qu'on tient le bouton, meme immobile.
	if _stroke != 0 and tool == Tool.AIRBRUSH:
		_touch(_last_paint)
	if not _stale.is_empty():
		# ⚠ UNE IMAGE PAR TUILE, DONC QUATRE-VINGT-TROIS AU PLUS. Les jumelles partagent leur
		# image : un coup de crayon ne salit qu'une texture, quel que soit le nombre de cases
		# qui la montrent. Le plafond ne sert plus qu'a l'ouverture d'un travail a 256.
		var done: Array[Vector2i] = []
		for cell: Vector2i in _stale.keys():
			if done.size() >= UPLOAD_PER_FRAME:
				break
			_upload_cell(cell)
			done.append(cell)
		for cell: Vector2i in done:
			_stale.erase(cell)
		if not done.is_empty():
			queue_redraw()
	if _changed:
		_changed = false
		queue_redraw()
		painting_changed.emit()


## Les cases qui touchent le cadre, en coordonnees de case, avec une case de marge pour
## les croisements decales d'une demi-case.
func _visible_cells() -> Rect2i:
	var low: Vector2 = (-_origin) / _tile_px
	var high: Vector2 = (size - _origin) / _tile_px
	var from: Vector2i = Vector2i(floori(low.x) - 1, floori(low.y) - 1)
	var to: Vector2i = Vector2i(ceili(high.x) + 1, ceili(high.y) + 1)
	return Rect2i(from, to - from)


func _on_screen(cell: Vector2i, frame: Rect2i) -> bool:
	var at: Vector2i = Families.from_storage(guide_family, cell) if cell.y < 0 else cell
	return frame.has_point(at)


## Charge un guide et la peinture qui va avec. Tout est recalcule : les cases peignables,
## le fond, et le cadrage.
func show_guide(heights: PackedStringArray, painting: RefCounted) -> void:
	_heights = heights
	_painting = painting
	_textures.clear()
	_stale.clear()
	_surface_cells.clear()
	_wall_cells.clear()
	# La carte case -> index se calcule une fois : l'editeur en a besoin a chaque coup de
	# crayon, et la recalculer coutait un tiers du budget d'affichage.
	#
	# ⚠ UNE CASE SOUS UNE ROBE PORTE LA ROBE, PAS SA SURFACE (`Families.surface_map`).
	# `index_map` donne un index a TOUTE case de sol, y compris celles qu'une falaise
	# recouvre -- et ces cases-la sont, sur la carte, du sol d'en bas : de l'herbe pleine,
	# l'index 255. Elles entraient donc dans les jumelles de l'herbe, et peindre la tuile
	# pleine repeignait les falaises en temps reel : 404 cases de robe sur `minimal`, 936
	# sur `ample` -- et apres UNE surface peinte, les 36 roles se disaient livres.
	var indices: Dictionary = Families.surface_map(guide_family, heights)
	for at: Vector2i in indices.keys():
		_surface_cells[Families.storage_key(guide_family, at)] = indices[at]
	# Les roles de robe sont rassembles une seule fois : ca coute un parcours complet du
	# relief, et l editeur en a besoin a chaque coup de crayon.
	# ⚠ DANS LE MODELE DES MASSIFS IL N'Y A PAS DE SECOND VOCABULAIRE, ET LE LAISSER TOURNER
	# CASSE LES JUMELLES. Un massif se dessine entier : sa jupe est deja dans `_surface_cells`,
	# avec sa propre tuile. Faire tourner `Walls` par-dessus regroupait les MEMES cases une
	# seconde fois, par pan et par rangee -- un decoupage qui n'a rien a voir -- et le second
	# `share()` repartageait les images du premier. Mesure : sur 1 611 jumelles d'un corps,
	# 1 031 seulement portaient la tuile apres un pixel. Deux groupements du meme carnet ne
	# peuvent pas coexister ; il n'en faut qu'un.
	var seen: Dictionary = {"roles": {}, "lips": {}} if guide_family == Families.BY_MASSIF 			else Walls.visible(heights)
	_wall_roles = seen["roles"]
	var lips: Dictionary = seen["lips"]
	for cell: Vector2i in _wall_roles.keys():
		_wall_cells[cell] = true
	# La pile des sols enterres de chaque case : son index dans CHAQUE silhouette d'etage
	# sous son sommet -- et jusqu'au sommet inclus pour une case de robe, que la falaise
	# recouvre. Le remontage s'en sert pour empiler comme le jeu et l'illustration : une
	# tuile par etage et par case. Sans ca, un pixel transparent d'une tuile -- coin
	# decoupe, bord balade -- montrait le fond du programme la ou le jeu montrera le sol.
	_stack_below.clear()
	_posed.clear()
	if guide_family == Families.BY_MASSIF:
		# ⚠ LA PILE EST LE MODELE LUI-MEME, ET ELLE EST DEJA CALCULEE. Un massif se dessine
		# ENTIER, y compris sous ce qui le recouvre : une case porte donc autant de poses que
		# de massifs qui la couvrent, et l'ordre de pose tranche qui est devant. Ce qu'une
		# tuile laisse en transparence montre la pose juste en dessous -- de l'herbe, de la
		# roche ou le vide selon l'endroit.
		#
		# ⚠ ET C'EST POUR CA QUE LE PEINTRE DOIT LA VOIR. Mesure sur le guide : 25 tuiles sur
		# 39 se posent devant PLUSIEURS matieres -- le corps plein en voit trois, roche 693
		# fois, herbe 346, vide 572. Peindre son fond en herbe le rendrait faux partout
		# ailleurs : le fond decouvert se laisse en TRANSPARENCE, et seul le remontage dit
		# ce qu'on verra vraiment.
		var piles: Dictionary = {}
		for pose: Dictionary in Massifs.poses(heights):
			var at2: Vector2i = pose["cell"]
			if not piles.has(at2):
				piles[at2] = [] as Array[int]
			(piles[at2] as Array[int]).append(Massifs.key_of(pose))
		for at3: Vector2i in piles.keys():
			var pile: Array[int] = piles[at3]
			# ⚠ TOUTE CASE POSEE EST NOTEE, MEME SEULE SUR SA PILE. C'est elle qui dit ou le
			# guide doit s'effacer ; ne noter que les piles a plusieurs laissait la plaine
			# et sa jupe montrer le guide a travers leur transparence, au lieu du vide.
			_posed[at3] = true
			if pile.size() > 1:
				_stack_below[at3] = pile.slice(0, pile.size() - 1)
	elif guide_family == Families.BY_CELL:
		var columns: int = HeightMask.width(heights)
		var rows: int = HeightMask.height(heights)
		var top_level: int = 0
		for y: int in range(rows):
			for x: int in range(columns):
				top_level = maxi(top_level, HeightMask.level_at(heights, x, y))
		var storey_indices: Array[Dictionary] = []
		for storey: int in range(top_level + 1):
			var silhouette: PackedStringArray = PackedStringArray()
			for y: int in range(rows):
				var line: String = ""
				for x: int in range(columns):
					line += "#" if HeightMask.level_at(heights, x, y) >= storey else "."
				silhouette.append(line)
			storey_indices.append(Coverage.index_map(silhouette))
		for y: int in range(rows):
			for x: int in range(columns):
				var cell: Vector2i = Vector2i(x, y)
				var level: int = HeightMask.level_at(heights, x, y)
				if level < 0:
					continue
				var covered: int = level - 1 + (1 if _wall_roles.has(cell) else 0)
				if covered < 0:
					continue
				var stack: Array[int] = []
				for storey: int in range(covered + 1):
					stack.append(int(storey_indices[storey].get(cell, -1)))
				_stack_below[cell] = stack
	if guide_family != Families.BY_MASSIF:
		for cell2: Vector2i in _stack_below.keys():
			_posed[cell2] = true
	# Les poses du moteur, pretes a dessiner sous les tuiles -- memes entrees que le jeu.
	_under_roles = {} if guide_family == Families.BY_MASSIF else Walls.visible_underfoot(heights)
	# L'annuaire des cases qui portent quelque chose. La grille s'y appuie a chaque image :
	# la recalculer serait relire tout le relief soixante fois par seconde.
	#
	# ⚠ L'ETAGE 0 N'EN EST PAS, ET C'EST DELIBERE. La plaine est bien un plateau comme les
	# autres -- elle a sa silhouette, ses index et sa falaise sur le vide -- mais dans
	# l'editeur elle est du DECOR : elle montre a l'acheteur que le sol du jeu sortira du
	# meme tileset, sans etre un endroit ou l'on travaille. Elle ne prend donc pas le
	# crayon, et comme la grille ne se trace que sur ce qui se peint, elle n'en porte pas.
	#
	# ⚠ MAIS ELLE RECOIT LE TEMPS REEL, ET C'EST TOUT L'INTERET. Elle reste dans les
	# groupes de jumelles : peindre une tuile la remplit d'un coup, sous les yeux. C'est ce
	# que faisait le tablier de sol avant la 4.0.0 -- celle-ci a corrige la GEOMETRIE du
	# decor, en le faisant s'arreter a la falaise que le guide declare, mais lui avait fait
	# perdre son STATUT de decor. On rend le statut, on garde la geometrie.
	#
	# ⚠ ET CA NE COUTE AUCUNE TUILE. Mesure sur les deux guides livres : les 47 index, les
	# 15 croisements et les 36 roles se trouvent tous hors de la plaine, et `ample` y tient
	# meme ses TROIS occurrences. Si un guide futur portait une tuile sur la seule plaine,
	# elle deviendrait impeignable -- d'ou l'assertion dans la suite.
	_paintable.clear()
	if guide_family == Families.BY_MASSIF:
		# ⚠ UNE FACADE NE SE JUGE PAS SUR L'ETAGE DE SA CASE, ET C'EST CE QUI LA RENDAIT
		# IMPEIGNABLE. Sur la carte, une case de falaise est une case du sol d'en dessous --
		# de la plaine, etage 0 -- donc `_guide_level(cell) >= 1` la refusait, et l'on ne
		# pouvait peindre AUCUNE facade. Ce qui compte est l'etage de la POSE, celui du massif
		# dont la jupe pend ici. Le noyau le sait deja : on lui demande, plutot que de refaire
		# le calcul avec la mauvaise donnee sous la main.
		for cell: Vector2i in Families.paintable_map(guide_family, heights).keys():
			_paintable[cell] = true
	else:
		for cell: Vector2i in _surface_cells.keys():
			if _guide_level(cell) >= 1:
				_paintable[cell] = true
		for cell: Vector2i in _wall_cells.keys():
			if int(lips.get(cell, 0)) >= 1:
				_paintable[cell] = true
	# Les jumelles : deux cases du meme groupe portent la meme tuile. Le noyau les designe,
	# on ne fait ici que retenir, pour chaque case, la liste de ses semblables.
	_twin_of.clear()
	_targets.clear()
	_by_index = Families.groups(guide_family, _surface_cells)
	_by_role = Walls.cells_by_role(_wall_roles)
	# Les cases dont la tuile n'apparait qu'une fois : aucune jumelle pour la porter.
	#
	# ⚠ ET CA SE COMPTE APRES LES GROUPES, PAS AVANT. Cette boucle lisait `_by_index` a une
	# ligne ou il portait encore les groupes du guide PRECEDENT : au tout premier
	# chargement il etait vide, donc aucun contour ambre ne se dessinait, et a chaque
	# chargement suivant les marques etaient celles d'un autre paysage. Trouve en
	# deplacant ce bloc, pas a l'ecran -- une marque absente ne se remarque pas.
	#
	# ⚠ ON COMPTE SUR CE QUI SE PEINT, PAS SUR LE GUIDE ENTIER. Une tuile qui se voit trois
	# fois dont deux sur la plaine n'a en verite qu'UN endroit ou on puisse la faire : la
	# compter sur le guide entier laisserait l'utilisateur croire qu'il a le choix.
	_lonely.clear()
	for group: Array in _by_index.values():
		var kept: Array = _only_paintable(group)
		if kept.size() == 1:
			_lonely[kept[0]] = true
	for group: Array in _by_role.values():
		var kept_roles: Array = _only_paintable(group)
		if kept_roles.size() == 1:
			_lonely[kept_roles[0]] = true
	# ⚠ ET CHAQUE GROUPE PARTAGE UNE SEULE IMAGE. C'est le carnet qui le sait, pas l'ecran :
	# ainsi l'export, la sauvegarde, l'apercu et les voisines lisent la bonne image sans
	# connaitre les jumelles. Un travail relu est rassemble au passage.
	for group: Array in _by_index.values():
		var surface_twins: Array[Vector2i] = group
		for cell: Vector2i in surface_twins:
			_twin_of[cell] = surface_twins
		if _painting != null:
			_painting.share(surface_twins)
	for group: Array in _by_role.values():
		var wall_twins: Array[Vector2i] = group
		for cell: Vector2i in wall_twins:
			_twin_of[cell] = wall_twins
		if _painting != null:
			_painting.share(wall_twins)
	_discs.clear()
	_stroke = 0
	_stroke_tile = NOWHERE
	# ⚠ UN TRAVAIL RELU N'A JAMAIS ETE PEINT DEVANT NOUS. Ses cases doivent etre sales des
	# le depart : sans ca rien ne s'afficherait tant qu'on n'aurait pas repasse le crayon
	# par-dessus. L'art serait bien en memoire, les compteurs diraient 47/47, et l'ecran
	# resterait desesperement vide.
	if _painting != null:
		for cell: Vector2i in _painting.painted_cells():
			_stale[cell] = true

	_redraw_background()
	# ⚠ ON NE CADRE PAS TOUT DE SUITE. Au premier chargement, le conteneur n'a pas encore
	# donne sa taille : cadrer ici reviendrait a cadrer sur une fenetre qui n'existe plus.
	# On demande le cadrage, et c'est le premier redimensionnement qui l'execute.
	_needs_fit = true
	fit()


## La carte case -> index de surface, et plus bas les roles de robe. Toutes deux calculees
## une seule fois au chargement : l'editeur s'en sert sans jamais relire le relief.
func surface_index() -> Dictionary:
	return _surface_cells


func wall_roles() -> Dictionary:
	return _wall_roles


## Les cases de surface deja peintes, et plus bas les cases de robe. L'editeur en tire ses
## deux compteurs.
func painted_surface_cells() -> Array[Vector2i]:
	return _filter_painted(_surface_cells)


func painted_wall_cells() -> Array[Vector2i]:
	return _filter_painted(_wall_cells)


func _filter_painted(among: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if _painting == null:
		return cells
	for cell: Vector2i in _painting.painted_cells():
		if among.has(cell):
			cells.append(cell)
	return cells


## Change le style du fond. Le relief ne bouge pas : seule sa representation change.
## ⚠ CHANGER LA REGLE DE REMPLISSAGE VIDE LE CACHE DES CIBLES. Sans ca, un coup de crayon
## continuerait a suivre l'ancienne regle sur toutes les cases deja touchees.
## ⚠ LES JUMELLES SE REMPLISSENT TOUJOURS, ET CE N'EST PLUS UNE OPTION.
##
## Deux jumelles ne sont pas deux tuiles qui se ressemblent : c'est LA MEME tuile, vue a
## plusieurs endroits. Les remplir ensemble ne peut donc jamais etre faux.
##
## ⚠ ET DEPUIS QUE LES VARIANTES ONT DISPARU, LA DECOCHER NE POUVAIT PLUS QUE FAIRE PERDRE
## DU TRAVAIL. La planche a une taille fixe : une tuile, un dessin. Peindre mille jumelles
## differemment n'en sortait qu'une -- la premiere -- et jetait les autres EN SILENCE. La
## charte l'interdit deux fois : on ne perd pas du travail sans le dire, et ce qui n'est pas
## garanti ne se propose pas (regles 4 et 5). L'option est donc retiree ; elle reviendra
## avec un vrai systeme de variantes, concu pour lui-meme.
func set_fill_rules(symmetry: bool) -> void:
	paint_symmetry = symmetry
	_targets.clear()


func set_guide_style(ink: GuideImage.Ink, purpose: GuideImage.Purpose,
		example: StringName = &"") -> void:
	if ink == guide_ink and purpose == guide_purpose and example == guide_example:
		return
	guide_ink = ink
	guide_purpose = purpose
	guide_example = example
	_redraw_background()
	queue_redraw()


## LA ZONE TRAVAILLE-T-ELLE ? ⚠ C'EST ELLE QUI SAIT, PAS L'ECRAN. Le panneau d'attente etait
## BASCULE par qui parlait en dernier : au demarrage, le fond s'annoncait, puis `_apply_decor`
## annoncait son decor et refermait le panneau dans la MEME image -- donc il ne se peignait
## jamais, et il n'y avait aucune barre au demarrage. Une visibilite qui se DEDUIT de ce qui
## travaille ne peut pas se faire fermer sous elle.
func is_busy() -> bool:
	return _pending or _job != null


## Relance le calcul du fond. L'editeur s'en sert quand une aide a la vue change ce que le
## fond doit montrer.
func refresh_background() -> void:
	_redraw_background()
	queue_redraw()


## ⚠ LE FOND SE CALCULE PAR ETAPES, ET ON GARDE CE QU'ON A DEJA CALCULE. Le dessiner coute
## de deux a cinq secondes ; en un seul appel l'ecran gele. On lance un travail que
## _process() fait avancer, et on range le resultat : revenir a un style deja vu est
## instantane. La cle porte le contenu du relief, donc un guide modifie ne ressort jamais
## une vieille image.
func _redraw_background() -> void:
	if _heights.is_empty():
		return
	_cache_key = "%s:%d:%d:%d:%d:%d:%s" % [guide_family, "
".join(_heights).hash(), GUIDE_TILE, int(guide_ink), int(guide_purpose),
			1 if guide_marks else 0, guide_example]
	if _cache.has(_cache_key):
		var pair: Array = _cache[_cache_key]
		_background = pair[0]
		_background_flat = pair[1]
		_job = null
		loading_progress.emit(1, 1)
		return
	# ⚠ LE MODELE DES MASSIFS SE DESSINE D UN COUP, ET C EST MESURE : une seconde pour le
	# guide entier (2432x3968). Le decoupage par etapes existe parce que l ancien fond coutait
	# de deux a cinq secondes ; ici il n a pas lieu d etre. Et il n y a PAS d image plate a
	# part : le modele ne pose aucune ombre portee, donc rien a masquer -- l ancien en avait
	# une parce que ses ombres tombaient sur des cases de plaine qu aucune tuile ne porte.
	if guide_family == Families.BY_MASSIF:
		# ⚠ ON ANNONCE AVANT DE COMPOSER, ET ON REND LA MAIN A L'ECRAN. Le modele des massifs
		# compose d'un coup -- une seconde pour le guide entier -- et n'emettait donc son
		# avancement qu'UNE FOIS FINI : la fenetre restait figee sans rien dire, et il n'y avait
		# AUCUNE barre au demarrage ni au changement de paysage (releve par l'utilisateur).
		#
		# ⚠ ET IL NE SUFFIT PAS D'EMETTRE AVANT : Godot ne dessine qu'entre deux images. On pose
		# donc le travail en attente et `_process` le fait a l'image suivante -- c'est exactement
		# ce que faisait l'ancien fond par etapes, pour la meme raison.
		_pending = true
		loading_progress.emit(0, 1)
		return
	_background = null
	_background_flat = null
	_job = RenderJob.new(_heights, GUIDE_TILE, guide_ink, guide_purpose, guide_marks)
	loading_progress.emit(0, _job.total)


## LA COMPOSITION DIFFEREE DU FOND, faite une image apres l'annonce.
func _compose_massifs() -> void:
	_pending = false
	# ⚠ UN EXEMPLE N'EST PAS UNE ENCRE, C'EST UNE AUTRE SOURCE. « Notre dessin » se CALCULE
	# depuis le relief -- il ne peut pas mentir sur ce que le guide contient, donc il a toujours
	# l'air juste. Un exemple, lui, est du VRAI trait remonte : c'est la seule vue ou l'on voit ce
	# que l'outil rend vraiment, et c'est la que les defauts se trouvent.
	var made: Image = null
	if Examples.CATALOGUE.has(guide_example):
		var art: RefCounted = Examples.painting(guide_example, _heights)
		made = MassifScene.compose_painted(_heights, art) if art != null else null
	if made == null:
		made = MassifScene.compose(_heights, 1,
				MassifTiles.CONTOUR if guide_ink == GuideImage.Ink.WIREFRAME
				else MassifTiles.PEINT)
	_background = ImageTexture.create_from_image(made)
	_background_flat = _background
	_cache[_cache_key] = [_background, _background_flat]
	_job = null
	loading_progress.emit(1, 1)
	queue_redraw()


## ON MASQUE ET ON REMONTRE LA GRILLE PAR ICI, jamais en posant le drapeau a la main.
##
## ⚠ PARCE QUE LA CACHER RECALE L'ECHELLE, et que ca doit se faire au moment du geste. Sans
## ce recalage, masquer la grille laisse voir les coutures de l'echelle libre -- exactement
## ce qu'on vient de masquer la grille pour ne plus voir. On ne recale QUE dans ce sens : en
## remontrant la grille, rien ne presse de defaire un cadrage qui, lui, n'a rien de faux.
func set_grid(on: bool) -> void:
	if show_grid == on:
		return
	show_grid = on
	if not on:
		_tile_px = _crisp(_tile_px, false)
	queue_redraw()


## Recadre le guide entier dans la fenetre.
func fit() -> void:
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	if columns <= 0 or rows <= 0 or size.x <= 0.0:
		return
	var usable: float = maxf(size.x - reserved_left - reserved_right, 1.0)
	# ⚠ LE CADRAGE NE SE CALE PAS EN PEIGNANT, ET C'EST VOULU. Il vise la vue d'ensemble, ou un
	# faux pixel mesure moins d'un pixel d'ecran : rien n'y peut etre net, et forcer une echelle
	# entiere y ferait perdre la moitie du guide pour un gain nul. `_crisp` s'en charge des
	# qu'on zoome. ⚠ MAIS DANS L'APERCU IL SE CALE, comme tout le reste : on y descend par
	# diviseurs entiers, et `_crisp` rend toujours une echelle plus PETITE que demandee quand on
	# retrecit -- le guide continue donc de tenir dans le cadre.
	_tile_px = minf(usable / float(columns), size.y / float(rows)) * 0.94
	if not show_grid:
		_tile_px = _crisp(clampf(_tile_px, MIN_TILE_PX, MAX_TILE_PX), false)
	var span: Vector2 = Vector2(float(columns), float(rows)) * _tile_px
	_origin = Vector2(reserved_left + (usable - span.x) * 0.5, (size.y - span.y) * 0.5)
	_needs_fit = false
	queue_redraw()


func _on_resized() -> void:
	if _needs_fit:
		fit()
	queue_redraw()


func _draw() -> void:
	# ⚠ AUCUN APLAT PLEIN, ET PLUS AUCUN TABLIER. Le guide porte desormais SA PROPRE
	# plaine -- un plateau comme les autres, avec sa falaise au bord du monde -- et ce qui
	# l'entoure est du VIDE. Le decor que l'editeur posait autour a disparu : il aurait
	# etendu la plaine au-dela de la falaise que le guide vient de declarer, c'est-a-dire
	# contredit le guide. Hors du monde, c'est le fond du programme.
	var columns: int = HeightMask.width(_heights)
	var rows: int = HeightMask.height(_heights)
	if columns <= 0:
		return
	var span: Vector2 = Vector2(float(columns), float(rows)) * _tile_px
	# `bare` : le remontage, ou l'on efface tout ce qui n'est pas les tuiles peintes.
	# `helpers` : les trois aides qui suivent la grille -- le cerne des cases peintes, les
	# hachures du fond decouvert, et la grille elle-meme.
	var bare: bool = assembled
	var helpers: bool = show_grid and not bare
	# LE VIDE, POSE EN PREMIER. Il ne se voit nulle part -- c'est deja la couleur du fond du
	# programme -- mais il donne a l'efface d'en dessous une source unique : ce qu'on
	# retire sous une tuile commencee et ce qu'on voit a cote du monde sont la meme
	# constante, donc ils ne peuvent pas diverger.
	draw_rect(Rect2(Vector2.ZERO, size), VOID)
	if _background != null and not bare:
		# Un TRACE se lit presque opaque ; un aplat se laisse traverser pour qu'on voie
		# son propre travail par-dessus.
		var tint: Color = GUIDE_TINT_WIRE if guide_ink != GuideImage.Ink.PAINTED \
				else GUIDE_TINT
		var sheet: ImageTexture = _background
		if hide_cast_light and _background_flat != null:
			sheet = _background_flat
		draw_texture_rect(sheet, Rect2(_origin, span), false, tint)

	var pixel_px: float = _tile_px / float(_painting.resolution) if _painting != null else 1.0
	# ⚠ UNE TEXTURE PAR TUILE, DESSINEE A CHAQUE JUMELLE. C'est l'ecran qui repete, pas la
	# memoire : le carnet n'a qu'une image par groupe, et chaque case du groupe la montre.
	var frame: Rect2i = _visible_cells()
	# ⚠ LE CERNE ET LES HACHURES SONT DE LA GRILLE, ET ILS NE LA SUIVAIENT PAS. « Masquer la
	# grille » retirait les traits de case et la grille fine, mais laissait le cerne ambre de
	# chaque case peinte -- qui, sur un guide entierement peint et vu de loin, EST une grille
	# complete -- et les hachures du fond decouvert. Or la case existe pour une seule raison :
	# quand on juge une COULEUR, toute aide a viser gene. Elles sont donc de la meme famille et
	# suivent la meme case (releve par l'utilisateur).
	var ring: bool = helpers and pixel_px < TOUCHED_FROM
	# LE REMONTAGE EMPILE, comme le jeu : sous chaque robe, le sol qu'elle couvre. Sans ce
	# fond, un pixel de robe laisse transparent -- l'arete deplacee, un coin -- montrait le
	# fond du programme la ou le jeu montrera l'etage d'en bas : le remontage mentait par
	# omission. Famille par case seulement : a cheval, le dessous d'un croisement est fait
	# de quatre tuiles, il n'y a pas UNE surface a poser dessous.
	if not hide_work and _painting != null:
		for under: Vector2i in _posed.keys():
			if not _on_screen(under, frame):
				continue
			# EN PEIGNANT AUSSI, PAS SEULEMENT AU REMONTAGE : derriere la transparence
			# d'une tuile, la matiere peinte d'en dessous, jamais le guide (decision
			# utilisateur -- le peintre se guide sur la matiere reelle). Une nuance :
			# le socle ne se pose que sous une tuile COMMENCEE ; une tuile vierge garde
			# sa consigne, sans quoi l'herbe pleine d'en dessous effacerait le dessin
			# de ce qu'il reste a faire.
			if not bare and not _painting.is_painted(under):
				continue
			var box: Rect2 = _cell_box(under)
			# ⚠ ON EFFACE LE GUIDE AVANT D'EMPILER, ET SUR TOUTE CASE POSEE. « Jamais le
			# guide » ne valait que la ou une autre pose venait le recouvrir ; ailleurs --
			# la plaine, sa jupe de bord du monde, tout ce qui n'a qu'une pose -- il
			# restait visible sous la transparence, et le peintre voyait le guide la ou le
			# jeu montrera le VIDE. Herbe et roche etaient justes, le vide ne l'etait pas.
			draw_rect(box, VOID)
			for below: int in (_stack_below.get(under, []) as Array):
				var ground_group: Array = _by_index.get(below, [])
				if ground_group.is_empty():
					continue
				var ground: Vector2i = _painting.holder(ground_group[0])
				if _textures.has(ground):
					draw_texture_rect(_textures[ground], box, false)
			# LES POSES DU MOTEUR -- pied sous l'atterrissage, corps derriere l'ecretage,
			# CHAPITEAU SOUS LA LEVRE : la roche vraie de chaque occurrence, entre le
			# socle et la tuile. C'est ce qui rend les marges transparentes honnetes au
			# bord sud : on y voit la face qui commence, plus jamais le sol a travers.
			if _under_roles.has(under):
				var rock_group: Array = _by_role.get(_under_roles[under], [])
				if not rock_group.is_empty():
					var rock: Vector2i = _painting.holder(rock_group[0])
					if _textures.has(rock):
						draw_texture_rect(_textures[rock], box, false)
			# En peignant, la case se hachure sous sa tuile : seules les zones que la
			# tuile laisse transparentes montrent les diagonales -- « ici, on voit
			# derriere ». Le remontage reste nu : cette vue decrasse l'ecran.
			#
			# ⚠ ET SEULEMENT LA OU IL Y A QUELQUE CHOSE DERRIERE. Sur une case qui n'a
			# qu'une pose, ce qu'on voit par la transparence est le vide : hachurer toute
			# la plaine crierait plus fort que l'information.
			if helpers \
					and (_stack_below.has(under) or _under_roles.has(under)):
				_draw_hatch(box)
	for holder: Vector2i in (_textures.keys() if not hide_work else []):
		var texture: ImageTexture = _textures[holder]
		var painted: bool = ring and _painting.is_painted(holder)
		var twins: Array = _twin_of.get(holder, [holder])
		for cell: Vector2i in twins:
			if not _on_screen(cell, frame):
				continue
			var rect: Rect2 = _cell_box(cell)
			draw_texture_rect(texture, rect, false)
			# Trop dezoome pour qu'un faux pixel se voie : on cerne la case, sinon le
			# travail semble ne rien produire.
			#
			# ⚠ MAIS LE DECOR NE PORTE AUCUNE MARQUE -- la regle de l'etage 0, encore.
			# La plaine est jumelle des tuiles qu'on peint et recoit le temps reel, c'est
			# tout son interet ; le cadre, lui, dit « travaille ici », et la plaine n'est
			# pas un endroit ou l'on travaille. Le cerne suit ce qui prend le crayon.
			if painted and _paintable.has(cell):
				draw_rect(rect, TOUCHED_MARK, false, 1.0)

	if helpers:
		_draw_grid(pixel_px)

	_draw_shape_preview(pixel_px)

	if _stroke != 0 and lock_to_tile and _stroke_tile != NOWHERE:
		draw_rect(_cell_box(_stroke_tile),
				LOCK_RING, false, 3.0)
	if _hover != NOWHERE:
		var accepted: bool = _is_paintable(_hover)
		if accepted and not bare:
			_draw_linked(frame)
		draw_rect(_cell_box(_hover),
				HOVER_OK if accepted else HOVER_REFUSED, false, 2.0)


## LES LIEES DU SURVOL : chaque case que le geste remplirait, montree AVANT le clic.
## Les jumelles recoivent toujours le meme dessin ; les symetriques s'y joignent quand
## « Peindre les rotations » est demande. La liste vient de _targets_for -- la fonction
## meme qui remplit -- jamais d'un second calcul : ce qui s'allume est exactement ce qui
## se peindra, et une case qui s'allumerait sans se peindre serait un mensonge d'ecran.
## En remontage rien ne s'allume, comme les autres reperes : cette vue decrasse l'ecran.
func _draw_linked(frame: Rect2i) -> void:
	if _painting == null:
		return
	var side: Vector2 = Vector2(_tile_px, _tile_px)
	for target: Array in _targets_for(_hover):
		var holder: Vector2i = target[0]
		var twins: Array = _twin_of.get(holder, [holder])
		for cell: Vector2i in twins:
			# ⚠ LE DECOR NE PORTE AUCUNE MARQUE -- la regle de l'etage 0. Ses jumelles
			# recoivent bien le geste, et ca se VOIT : la peinture y tombe en temps
			# reel. La marque, elle, designe du travail, et le decor n'en est pas.
			if cell == _hover or not _paintable.has(cell) or not _on_screen(cell, frame):
				continue
			draw_rect(Rect2(_cell_origin(cell), side), LINKED_LINE, false, 2.0)


## ⚠ LE SURLIGNAGE VIOLET DES RACCORDS OBLIGES A ETE RETIRE -- decision utilisateur, prise a
## l'ecran : « il gache tout ». Il allumait, au survol d'une robe, toutes les tuiles dont un
## bord entier est le meme pixel (Seams.GROUPS) -- souvent une dizaine de cases d'un coup, sur
## un fond deja charge de trois autres marques. L'information est juste ; sa forme criait plus
## fort que le travail.
##
## Ce qu'il disait reste VRAI et reste APPLIQUE : peindre au bord d'une robe ecrit dans ses
## liees, par la propagation, qu'on le montre ou non. Si le besoin revient, ce sera sous une
## autre forme -- un liseré sur le seul BORD concerne plutot qu'un contour de case entier.
## De fines diagonales sur toute la case, a pas regulier. Posees entre le socle et la
## tuile, elles ne se voient qu'au travers de la transparence de celle-ci.
func _draw_hatch(box: Rect2) -> void:
	var step: float = maxf(5.0, box.size.x * 0.125)
	var travel: float = box.size.x + box.size.y
	var d: float = step
	while d < travel:
		var from: Vector2 = box.position + Vector2(maxf(0.0, d - box.size.y), minf(d, box.size.y))
		var to: Vector2 = box.position + Vector2(minf(d, box.size.x), maxf(0.0, d - box.size.x))
		draw_line(from, to, SEE_THROUGH_HATCH, 1.0)
		d += step


## Les socles enterres, prets a dessiner : case -> liste des cases (premieres de groupe)
## dont les tuiles se posent SOUS la tuile de la case, du bas vers le haut. Les voisines
## s'en servent pour empiler comme toutes les autres vues.
func ground_stacks() -> Dictionary:
	var stacks: Dictionary = {}
	for cell: Vector2i in _stack_below.keys():
		var sources: Array = []
		for below: int in (_stack_below[cell] as Array):
			var group: Array = _by_index.get(below, [])
			if not group.is_empty():
				sources.append(group[0])
		if _under_roles.has(cell):
			var rock_group: Array = _by_role.get(_under_roles[cell], [])
			if not rock_group.is_empty():
				sources.append(rock_group[0])
		if not sources.is_empty():
			stacks[cell] = sources
	return stacks


## La ligne ou le rectangle en cours, avant qu'on ne relache : on voit ce qu'on va poser.
func _draw_shape_preview(pixel_px: float) -> void:
	if _stroke == 0 or _painting == null or not (tool == Tool.LINE or tool == Tool.RECT):
		return
	var shade: Color = pencil if _stroke > 0 else PREVIEW_ERASE
	if _stroke > 0:
		shade.a = 0.75
	for pixel: Vector2i in _shape_pixels():
		if _tile_at_pixel(pixel) == NOWHERE:
			continue
		var at: Vector2 = _origin + Vector2(float(pixel.x), float(pixel.y)) * pixel_px
		draw_rect(Rect2(at, Vector2(pixel_px, pixel_px)), shade)


## LA GRILLE, DECOUPEE SUR CE QUI SE PEINT.
##
## ⚠ TRACEE SUR TOUT LE RECTANGLE, ELLE QUADRILLAIT SURTOUT CE QUI N'EST PAS LE TRAVAIL.
## La plaine occupe la plus grande part du cadre et ne se peint pas : la grille y dessinait
## une feuille de calcul, et le relief s'y noyait. Posee sur les seules cases peignables,
## elle dessine au contraire la SILHOUETTE de ce qu'il y a a faire -- on voit d'un coup
## d'oeil ou l'on a le droit de poser un pixel.
##
## ⚠ CHAQUE ARETE N'EST TRACEE QU'UNE FOIS. On pose toujours le haut et la gauche, et le
## bas ou la droite seulement au bord du peignable : une arete interieure appartient ainsi
## a la case du dessous ou de droite, jamais aux deux.
func _draw_grid(pixel_px: float) -> void:
	var fine: float = 0.0
	if _painting != null and pixel_px >= PIXEL_GRID_FROM:
		fine = pixel_px
	var frame: Rect2 = Rect2(Vector2.ZERO, size)
	for cell: Vector2i in _paintable.keys():
		# ⚠ LA GRILLE SE CALE COMME LES TUILES, sinon elle flotte a cote d'elles : un trait pose
		# a la fraction pres et une tuile posee a l'entier ne tombent pas au meme endroit, et la
		# grille cesse de dire ou sont les bordures -- ce pour quoi elle existe.
		var box: Rect2 = _cell_box(cell)
		var at: Vector2 = box.position
		# ⚠ ON NE TRACE QUE CE QUI EST A L'ECRAN. A fort zoom, la grille fine d'un guide
		# entier ferait des dizaines de milliers de traits dont la quasi-totalite hors cadre.
		if not frame.intersects(box):
			continue
		# ⚠ UNE CASE SANS JUMELLE PORTE SON PROPRE CONTOUR, ENTIER. Les aretes partagees
		# appartiennent d'ordinaire a une seule des deux cases ; ici on les redessine toutes
		# les quatre, sinon la marque serait rongee par les voisines et ne se lirait pas.
		if _lonely.has(cell):
			draw_rect(box, LONE_LINE, false, 1.0)
			continue
		draw_line(at, at + Vector2(box.size.x, 0.0), TILE_LINE, 1.0)
		draw_line(at, at + Vector2(0.0, box.size.y), TILE_LINE, 1.0)
		if not _paintable.has(_below(cell)):
			draw_line(at + Vector2(0.0, box.size.y), at + box.size, TILE_LINE, 1.0)
		if not _paintable.has(cell + Vector2i.RIGHT):
			draw_line(at + Vector2(box.size.x, 0.0), at + box.size, TILE_LINE, 1.0)
		if fine <= 0.0:
			continue
		for i: int in range(1, _painting.resolution):
			var offset: float = float(i) * fine
			draw_line(at + Vector2(offset, 0.0), at + Vector2(offset, box.size.y),
					PIXEL_LINE, 1.0)
			draw_line(at + Vector2(0.0, offset), at + Vector2(box.size.x, offset),
					PIXEL_LINE, 1.0)


## OU SE DESSINE CE QUE PORTE CETTE CLE.
##
## ⚠ UN CROISEMENT EST DECALE D'UNE DEMI-CASE. Sa tuile est a cheval sur quatre cases : sa
## boite va donc de (i-0.5, j-0.5) a (i+0.5, j+0.5). C'est ce decalage, et lui seul, qui met
## le guide sous la bonne tuile -- le fond, lui, ne bouge pas.
## LA BOITE D'UNE CASE, CALEE SUR DES PIXELS ENTIERS.
##
## ⚠ ET C'EST CE QUI SUPPRIME LES COUTURES. `_tile_px` est un FLOTTANT -- il vient du cadrage,
## donc il vaut 22,7 ou 31,4 -- et chaque case etait dessinee a `Rect2(origine, taille)` avec
## ces deux valeurs fractionnaires. Deux consequences, et la seconde est celle qui se voyait :
##
##   - `draw_rect` et `draw_texture_rect` ne rasterisent PAS un rectangle fractionnaire de la
##     meme facon. L'efface du VIDE et la tuile posee par-dessus ne couvraient donc pas
##     exactement les memes pixels, et un liseré de fond depassait d'un cote ;
##   - deux cases voisines ne partageaient pas leur frontiere au pixel pres : selon l'arrondi,
##     il restait un trou ou un recouvrement d'un pixel.
##
## En calculant les DEUX bords depuis la meme formule et en les arrondissant, la frontiere
## droite d'une case EST la frontiere gauche de sa voisine -- par construction, quel que soit le
## zoom. La lecon etait deja au dossier, appliquee au panneau d'apercu (« le cote de case est
## arrondi a l'entier, une echelle fractionnaire montrerait des coutures que le dessin n'a
## pas ») et jamais a la zone de travail.
##
## ⚠ ET ON NE FIGE PAS `_tile_px` A UN ENTIER : le zoom deviendrait saccade. C'est le TRACE qui
## se cale, pas l'echelle.
func _cell_box(cell: Vector2i) -> Rect2:
	var x0: float = roundf(_origin.x + float(cell.x) * _tile_px)
	var y0: float = roundf(_origin.y + float(cell.y) * _tile_px)
	var x1: float = roundf(_origin.x + float(cell.x + 1) * _tile_px)
	var y1: float = roundf(_origin.y + float(cell.y + 1) * _tile_px)
	return Rect2(x0, y0, maxf(1.0, x1 - x0), maxf(1.0, y1 - y0))


func _cell_origin(cell: Vector2i) -> Vector2:
	if cell.y < 0:
		var point: Vector2i = Families.from_storage(Families.BY_CORNER, cell)
		return _origin + (Vector2(float(point.x), float(point.y))
				- Vector2(0.5, 0.5)) * _tile_px
	return _origin + Vector2(float(cell.x), float(cell.y)) * _tile_px


## ⚠ « EN DESSOUS » S'INVERSE POUR UN CROISEMENT. Sa cle porte un y negatif : descendre
## d'une rangee a l'ecran, c'est DECREMENTER la cle. Sans ca la grille dessinerait ses bords
## a l'envers, et l'on ne verrait pas ou s'arrete le peignable.
func _below(key: Vector2i) -> Vector2i:
	return key + (Vector2i.UP if key.y < 0 else Vector2i.DOWN)


func _is_paintable(cell: Vector2i) -> bool:
	return _paintable.has(cell)


## L'etage que montre une cle de carnet : celui de la case, ou le plus haut des quatre
## cases d'un croisement.
##
## ⚠ ON NE VOIT QUE LE SOMMET, ici comme partout. Un croisement touche quatre cases qui
## peuvent etre a quatre etages ; celui qu'il montre est le plus haut des quatre.
func _guide_level(key: Vector2i) -> int:
	var at: Vector2i = Families.from_storage(guide_family, key)
	if guide_family != Families.BY_CORNER:
		return HeightMask.level_at(_heights, at.x, at.y)
	var top: int = HeightMask.VOID
	for offset: Vector2i in CornerIndex.OFFSETS:
		top = maxi(top, HeightMask.level_at(_heights, at.x + offset.x, at.y + offset.y))
	return top


## Le sous-ensemble d'un groupe de jumelles que l'utilisateur peut reellement peindre.
func _only_paintable(group: Array) -> Array:
	var kept: Array = []
	for key: Vector2i in group:
		if _paintable.has(key):
			kept.append(key)
	return kept


## Cette case porte-t-elle une tuile qui n'existe nulle part ailleurs dans le guide ?
func is_lonely(cell: Vector2i) -> bool:
	return _lonely.has(cell)


## Combien de cases sont dans ce cas.
func lonely_count() -> int:
	return _lonely.size()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					_zoom_at(button.position, 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					_zoom_at(button.position, 1.0 / 1.12)
			MOUSE_BUTTON_MIDDLE:
				_panning = button.pressed
			MOUSE_BUTTON_LEFT:
				# Bouton gauche : on pose. Bouton droit : on efface.
				_begin_or_end(button.pressed, 1, button.position)
			MOUSE_BUTTON_RIGHT:
				_begin_or_end(button.pressed, -1, button.position)
		accept_event()
		return
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _panning:
			_origin += motion.relative
			queue_redraw()
			return
		var moved: bool = _set_hover(motion.position)
		if _stroke != 0:
			if tool == Tool.LINE or tool == Tool.RECT:
				# La forme se pose au relachement ; en attendant on la montre.
				_cursor = _pixel_at(motion.position)
				queue_redraw()
			else:
				_apply_stroke(_last_paint, motion.position)
			_last_paint = motion.position
		elif moved:
			queue_redraw()


## ⚠ LE SURVOL SE SUIT A LA CASE, PAS AU PIXEL. Suivre le pixel redessinait la zone de
## travail a chaque micro-mouvement de souris, pour un reperage dont on n a pas voulu.
## Une passe s'ouvre au clic et se ferme au relachement : c'est l'unite qu'on defait.
##
## ⚠ LA PIPETTE NE PEINT PAS, ET LE POT N'A PAS DE TRAJET. La premiere prend une couleur au
## clic et ne laisse aucune passe au journal ; le second fait tout au clic, et la souris
## peut aller ou elle veut ensuite. La ligne et le rectangle, eux, ne posent rien avant le
## relachement : c'est la qu'on sait ou ils finissent.
func _begin_or_end(pressed: bool, direction: int, position: Vector2) -> void:
	if _painting == null:
		return
	if pressed:
		if tool == Tool.PICKER:
			_pick(position)
			return
		_stroke = direction
		_stroke_tile = NOWHERE
		_painting.begin_stroke()
		_last_paint = position
		_anchor = _pixel_at(position)
		_cursor = _anchor
		if tool == Tool.BUCKET:
			_pour(_anchor)
		elif tool == Tool.LINE or tool == Tool.RECT:
			queue_redraw()
		else:
			_apply_stroke(position, position)
		return
	if _stroke == 0:
		return
	if tool == Tool.LINE or tool == Tool.RECT:
		for pixel: Vector2i in _shape_pixels():
			_stamp_disc(pixel)
	_stroke = 0
	_stroke_tile = NOWHERE
	_painting.end_stroke()
	queue_redraw()


## ⚠ LES RACCOURCIS SONT PRIS ICI, PAS DANS _gui_input : celui-la exige que la zone ait le
## focus, et l'on vient souvent de cliquer une case a cocher.
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or not key.ctrl_pressed or _painting == null:
		return
	var cells: Array[Vector2i] = []
	if key.keycode == KEY_Z and not key.shift_pressed:
		cells = _painting.undo()
	elif key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed):
		cells = _painting.redo()
	else:
		return
	get_viewport().set_input_as_handled()
	for cell: Vector2i in cells:
		_stale[cell] = true
	if not cells.is_empty():
		_changed = true


func _set_hover(position: Vector2) -> bool:
	var cell: Vector2i = _target_at(position)
	if cell == _hover:
		return false
	_hover = cell
	hover_changed.emit(cell)
	return true


## CE QUE DESIGNE UN POINT DE L'ECRAN.
##
## ⚠ DANS LA FAMILLE A CHEVAL, LES DEUX GRILLES SE CHEVAUCHENT. Une tuile de croisement
## est decalee d'une demi-case, une robe est sur la case : leurs boites partagent un quart.
## LA ROBE GAGNE -- elle est dessinee devant, donc c'est elle qu'on voit sous le curseur.
##
## ⚠ QUARANTE-NEUF CROISEMENTS DEVIENNENT AINSI INATTEIGNABLES sur les 813 du guide.
## Aucune TUILE n'est perdue pour autant : les quinze index gardent chacun un croisement
## libre, et les jumelles remplissent le reste. C'est mesure, et asserte.
func _target_at(position: Vector2) -> Vector2i:
	var cell: Vector2i = _cell_at(position)
	if _wall_cells.has(cell):
		return cell
	if guide_family == Families.BY_CORNER:
		var offset: Vector2 = (position - _origin) / _tile_px + Vector2(0.5, 0.5)
		var key: Vector2i = Families.storage_key(Families.BY_CORNER,
				Vector2i(floori(offset.x), floori(offset.y)))
		return key if _surface_cells.has(key) else NOWHERE
	return cell if _paintable.has(cell) else NOWHERE


func _cell_at(position: Vector2) -> Vector2i:
	var local: Vector2 = (position - _origin) / _tile_px
	return Vector2i(floori(local.x), floori(local.y))


## LE PIXEL GLOBAL sous un point de l'ecran : le plan entier est une grille de faux pixels,
## `resolution` par case, et tout geste se fait la-dedans.
func _pixel_at(position: Vector2) -> Vector2i:
	var local: Vector2 = (position - _origin) / _tile_px * float(_painting.resolution)
	return Vector2i(floori(local.x), floori(local.y))


## LA TUILE QUI PREND CE PIXEL, ou NOWHERE. C'est l'unique endroit qui decide quelle tuile
## est sous un point -- la meme regle que le survol : la robe gagne, puis le croisement
## decale d'une demi-case, puis la case.
func _tile_at_pixel(pixel: Vector2i) -> Vector2i:
	var side: int = _painting.resolution
	var cell: Vector2i = Vector2i(_floordiv(pixel.x, side), _floordiv(pixel.y, side))
	if _wall_cells.has(cell):
		return cell if _paintable.has(cell) else NOWHERE
	if guide_family == Families.BY_CORNER:
		var half: int = side / 2
		var point: Vector2i = Vector2i(_floordiv(pixel.x + half, side),
				_floordiv(pixel.y + half, side))
		var key: Vector2i = Families.storage_key(Families.BY_CORNER, point)
		return key if _paintable.has(key) else NOWHERE
	return cell if _paintable.has(cell) else NOWHERE


## Ou tombe ce pixel global dans la tuile qui le prend.
func _pixel_in(pixel: Vector2i, key: Vector2i) -> Vector2i:
	var side: int = _painting.resolution
	if key.y < 0:
		var point: Vector2i = Families.from_storage(Families.BY_CORNER, key)
		return pixel - point * side + Vector2i(side / 2, side / 2)
	return pixel - key * side


static func _floordiv(value: int, by: int) -> int:
	@warning_ignore("integer_division")
	var quotient: int = value / by
	if (value % by != 0) and ((value < 0) != (by < 0)):
		quotient -= 1
	return quotient


func _zoom_at(pivot: Vector2, factor: float) -> void:
	var before: Vector2 = (pivot - _origin) / _tile_px
	_tile_px = _crisp(clampf(_tile_px * factor, MIN_TILE_PX, MAX_TILE_PX), factor > 1.0)
	_origin = pivot - before * _tile_px
	queue_redraw()


## UN FAUX PIXEL DOIT FAIRE UN NOMBRE ENTIER DE PIXELS D'ECRAN.
##
## ⚠ SANS CA, LE DESSIN EST BAVEUX PARTOUT SAUF AU BORD DES TUILES (releve par l'utilisateur).
## Une tuile de seize faux pixels etalee sur 22,7 pixels d'ecran donne 1,42 pixel par faux
## pixel : avec un filtrage AU PLUS PROCHE, certains en occupent UN et d'autres DEUX, au hasard
## de l'arrondi. L'interieur devient irregulier -- « baveux » -- tandis que la bordure de tuile,
## elle, est franche. Ce contraste EST la couture : ce n'est pas un trait en trop, c'est la
## grille des faux pixels qui se remet d'aplomb a chaque case.
##
## ⚠ ET AUCUN FILTRAGE NE REPARE CA. Un lissage etalerait la faute au lieu de la supprimer, et
## le dessin montrerait des degrades que la peinture n'a pas -- exactement ce que le filtrage au
## plus proche existe pour eviter. Le seul remede est l'echelle ENTIERE, et c'est ce que fait
## tout editeur de pixel art.
##
## ⚠ EN DESSOUS D'UN PIXEL PAR FAUX PIXEL, ON NE SNAPPE PLUS : rien ne peut y etre net, et
## bloquer le zoom a la vue d'ensemble empecherait de voir le guide entier. C'est la que les
## cases peintes se CERNENT, precisement parce qu'un faux pixel n'y est plus visible.
##
## ⚠ ET LE SENS DU ZOOM DECIDE DE L'ARRONDI, sans quoi un cran en avant suivi d'un cran en
## arriere ne revient pas au meme endroit : on monte vers l'entier superieur, on descend vers
## l'inferieur.
func _crisp(wanted: float, growing: bool) -> float:
	if _painting == null:
		return wanted
	var side: float = float(_painting.resolution)
	var per: float = wanted / side
	# ⚠ ON BORNE LES CRANS, PAS LE PRODUIT. Borner `steps * side` entre les deux limites rendrait
	# une valeur qui n'est plus un multiple des le premier ecretage -- 32 x 63 = 2016 devient 2000,
	# et le zoom le plus profond, celui ou la faute se voit le mieux, redeviendrait baveux.
	if per >= 1.0:
		var steps: float = ceilf(per) if growing else floorf(per)
		return clampf(steps, 1.0, floorf(MAX_TILE_PX / side)) * side
	# GRILLE VISIBLE, ON REND LA MAIN SOUS LE PIXEL -- voir plus haut.
	if show_grid:
		return wanted
	# ⚠ GRILLE MASQUEE, ON DESCEND PAR DIVISEURS ENTIERS. Sous un pixel d'ecran par faux pixel,
	# caler « vers le haut » n'a plus de sens : il n'y a plus de multiple a viser. Mais la
	# couture, elle, est toujours la -- `_cell_box` arrondit chaque case, donc une echelle libre
	# fait retomber la grille des faux pixels d'aplomb A CHAQUE BORDURE. Prendre exactement un
	# faux pixel sur D la supprime pour la meme raison qu'un multiple entier la supprimait :
	# chaque case subit le meme echantillonnage, et `_tile_px` reste un ENTIER.
	#
	# ⚠ ET D EST UNE PUISSANCE DE DEUX, parce que les resolutions le sont (16 a 256) : c'est la
	# seule facon que `side / D` tombe juste. Un D de 3 rendrait 5,33 pixels par case, et
	# l'arrondi de `_cell_box` recreerait exactement la couture qu'on chasse.
	var rank: float = log(side / wanted) / log(2.0)
	rank = floorf(rank) if growing else ceilf(rank)
	# ⚠ ET C'EST L'EXPOSANT QU'ON BORNE, PAS LE DIVISEUR -- la lecon d'un cran plus bas.
	# Ecreter D a trois rendrait 5,33 pixels par case : un non-entier, donc la couture
	# rentrerait par la porte qu'on vient de fermer.
	rank = clampf(rank, 0.0, floorf(log(side / MIN_TILE_PX) / log(2.0)))
	return side / pow(2.0, rank)


## Trace du dernier point au point courant. Sans ce segment, un geste rapide laisserait des
## trous : la souris ne rend qu'une poignee de positions par seconde.
func _apply_stroke(from: Vector2, to: Vector2) -> void:
	if _painting == null:
		return
	var pixel_px: float = _tile_px / float(_painting.resolution)
	var steps: int = maxi(1, int(from.distance_to(to) / maxf(pixel_px, 0.5)) + 1)
	for i: int in range(steps + 1):
		var point: Vector2 = from.lerp(to, float(i) / float(steps))
		_touch(point)


## Ce qu'un point de souris depose, selon l'outil.
func _touch(position: Vector2) -> bool:
	if _painting == null:
		return false
	var pixel: Vector2i = _pixel_at(position)
	match tool:
		Tool.PENCIL:
			return _plot(pixel)
		Tool.AIRBRUSH:
			return _spray(pixel)
		_:
			return _stamp_disc(pixel)


## Un pixel global, pose dans la tuile qui le prend -- et ses jumelles, ses symetriques,
## ses raccords obliges.
##
## ⚠ LA CONTRAINTE SE JUGE ICI, UN PIXEL A LA FOIS. Une brosse a cheval sur deux tuiles
## pose sa part dans celle qu'on tient et laisse l'autre intacte.
func _plot(pixel: Vector2i) -> bool:
	var key: Vector2i = _tile_at_pixel(pixel)
	if key == NOWHERE:
		return false
	if lock_to_tile:
		if _stroke_tile == NOWHERE:
			_stroke_tile = key
		elif key != _stroke_tile:
			return false
	var inside: Vector2i = _pixel_in(pixel, key)
	return _stamp(key, inside.x, inside.y)


## Le disque de la brosse autour d'un pixel.
func _stamp_disc(pixel: Vector2i) -> bool:
	var changed: bool = false
	for offset: Vector2i in _disc(brush_size):
		if _plot(pixel + offset):
			changed = true
	return changed


## L'aerographe : quelques pixels tires au hasard dans le disque, a chaque jet.
func _spray(pixel: Vector2i) -> bool:
	var disc: Array[Vector2i] = _disc(maxi(brush_size, 2))
	var drops: int = maxi(1, int(ceil(float(disc.size()) * SPRAY_DENSITY)))
	var changed: bool = false
	for _i: int in range(drops):
		if _plot(pixel + disc[randi() % disc.size()]):
			changed = true
	return changed


## LE POT : la plage contigue de meme couleur, dans la tuile sous le clic. Elle s'arrete au
## bord de la tuile par construction -- une tuile est une image a elle seule -- donc le pot
## n'a pas besoin de la contrainte, il la respecte d'office.
func _pour(pixel: Vector2i) -> void:
	var key: Vector2i = _tile_at_pixel(pixel)
	if key == NOWHERE:
		return
	_stroke_tile = key
	var inside: Vector2i = _pixel_in(pixel, key)
	var color: Color = pencil if _stroke > 0 else Painting.TRANSPARENT
	var last: int = _painting.resolution - 1
	var changed: bool = false
	for target: Array in _targets_for(key):
		var to: Vector2i = target[0]
		var seed: Vector2i = Symmetry.transform_pixel(inside.x, inside.y,
				_painting.resolution, int(target[1]))
		var poured: Array[Vector2i] = _painting.fill(to, seed.x, seed.y, color)
		if poured.is_empty():
			continue
		_stale[to] = true
		changed = true
		# Les raccords obliges ne concernent que le bord : inutile d'interroger le dedans.
		for at: Vector2i in poured:
			if at.x == 0 or at.y == 0 or at.x == last or at.y == last:
				_echo_seams(to, at.x, at.y)
	if changed:
		_changed = true


## LA PIPETTE : la couleur du pixel sous le clic, si la tuile en porte un.
func _pick(position: Vector2) -> void:
	var pixel: Vector2i = _pixel_at(position)
	var key: Vector2i = _tile_at_pixel(pixel)
	if key == NOWHERE:
		return
	var inside: Vector2i = _pixel_in(pixel, key)
	var color: Color = _painting.pixel_at(key, inside.x, inside.y)
	if color.a <= 0.0:
		return
	pencil = color
	pencil_picked.emit(color)


## Les pixels de la forme en cours, entre le clic et la souris.
func _shape_pixels() -> Array[Vector2i]:
	if tool == Tool.RECT:
		return _rect_pixels(_anchor, _cursor)
	return _line_pixels(_anchor, _cursor)


## Bresenham, borne par ses deux bouts : les deux sont des entiers finis.
static func _line_pixels(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var delta: Vector2i = Vector2i(absi(to.x - from.x), -absi(to.y - from.y))
	var step: Vector2i = Vector2i(1 if from.x < to.x else -1, 1 if from.y < to.y else -1)
	var err: int = delta.x + delta.y
	var at: Vector2i = from
	while true:
		out.append(at)
		if at == to:
			break
		var twice: int = 2 * err
		if twice >= delta.y:
			err += delta.y
			at.x += step.x
		if twice <= delta.x:
			err += delta.x
			at.y += step.y
	return out


## Le contour du rectangle, chaque pixel une fois.
static func _rect_pixels(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var low: Vector2i = Vector2i(mini(from.x, to.x), mini(from.y, to.y))
	var high: Vector2i = Vector2i(maxi(from.x, to.x), maxi(from.y, to.y))
	for x: int in range(low.x, high.x + 1):
		out.append(Vector2i(x, low.y))
		if high.y != low.y:
			out.append(Vector2i(x, high.y))
	for y: int in range(low.y + 1, high.y):
		out.append(Vector2i(low.x, y))
		if high.x != low.x:
			out.append(Vector2i(high.x, y))
	return out


## Les decalages d'un disque de ce diametre, centres sur le pixel vise.
func _disc(diameter: int) -> Array[Vector2i]:
	if _discs.has(diameter):
		return _discs[diameter]
	var out: Array[Vector2i] = []
	var radius: float = float(diameter) * 0.5
	var start: int = -(diameter / 2)
	for j: int in range(diameter):
		for i: int in range(diameter):
			var dx: float = float(i) + 0.5 - radius
			var dy: float = float(j) + 0.5 - radius
			if dx * dx + dy * dy <= radius * radius + 0.01:
				out.append(Vector2i(start + i, start + j))
	_discs[diameter] = out
	return out


## Pose un pixel d'une tuile -- dans l'image que partagent ses jumelles, dans celles de
## ses symetriques si les rotations sont demandees, et dans les raccords obliges.
func _stamp(key: Vector2i, px: int, py: int) -> bool:
	var changed: bool = false
	var erase: bool = _stroke < 0 or tool == Tool.ERASER
	for target: Array in _targets_for(key):
		var to: Vector2i = target[0]
		var moved: Vector2i = Symmetry.transform_pixel(px, py, _painting.resolution, int(target[1]))
		var touched: bool = _painting.erase(to, moved.x, moved.y) if erase \
				else _painting.paint(to, moved.x, moved.y, pencil)
		if touched:
			_stale[to] = true
			changed = true
		if _echo_seams(to, moved.x, moved.y):
			changed = true
	if changed:
		_changed = true
	return changed


## LES RACCORDS OBLIGATOIRES : le meme point de roche, vu dans une autre tuile.
##
## ⚠ ON PART DE LA TUILE REELLEMENT PEINTE, pas de la case survolee. Avec les rotations,
## le crayon pose son pixel ailleurs et autrement ; propager depuis l'origine recopierait le
## raccord au mauvais endroit. On propage depuis ce qui vient d'etre pose.
##
## ⚠ ET ON NE PROPAGE PAS L'ECHO DE L'ECHO. `Seams.mirrors` rend la classe ENTIERE d'un
## coup : repartir de chaque copie tournerait en rond pour rien.
##
## ⚠ UNE FOIS PAR ROLE, PAS PAR JUMELLE. Les jumelles partagent leur image : l'echo se pose
## sur celle qui la tient, et c'est fini. Avant ca, chaque pixel de bord d'une robe a cent
## jumelles repassait cent fois sur les cent jumelles de chaque echo -- dix mille poses
## pour un pixel, deux cents millisecondes par point de souris.
func _echo_seams(cell: Vector2i, x: int, y: int) -> bool:
	if _painting == null or not _wall_roles.has(cell):
		return false
	var echoes: Array[Vector4i] = Seams.mirrors(_wall_roles[cell], x, y,
			_painting.resolution)
	if echoes.is_empty():
		return false
	var erase: bool = _stroke < 0 or tool == Tool.ERASER
	var moved: bool = false
	for echo: Vector4i in echoes:
		var role: Vector2i = Vector2i(echo.x, echo.y)
		if not _by_role.has(role):
			continue
		var twin: Vector2i = _painting.holder(_by_role[role][0])
		var done: bool = _painting.erase(twin, echo.z, echo.w) if erase \
				else _painting.paint(twin, echo.z, echo.w, pencil)
		if done:
			_stale[twin] = true
			moved = true
	return moved


## Les tuiles qu'un coup de crayon touche, chacune avec la transformation a appliquer a ses
## pixels. Calcule une fois par case, puis garde : un trait repasse cent fois au meme
## endroit, et rien n'y bouge entre deux passages.
##
## ⚠ UNE CIBLE PAR GROUPE, PAS PAR JUMELLE : la case qui tient l'image partagee. C'est
## elle qu'on peint, et l'ecran la montre a chaque jumelle.
func _targets_for(cell: Vector2i) -> Array:
	if _targets.has(cell):
		return _targets[cell]
	var list: Array = []
	var own: Vector2i = _painting.holder(cell)
	if paint_symmetry and _surface_cells.has(cell):
		var source: int = int(_surface_cells[cell])
		for target_index: int in Symmetry.ORBIT_OF[source]:
			if not _by_index.has(target_index):
				continue
			var turns: int = Symmetry.turns_between(source, target_index)
			list.append([_painting.holder(_by_index[target_index][0]), turns])
	elif paint_symmetry and _wall_roles.has(cell):
		var role: Vector2i = _wall_roles[cell]
		var mirrored: Vector2i = Symmetry.mirror_role(role)
		list.append([own, Symmetry.TURN_NONE])
		if mirrored != role and _by_role.has(mirrored):
			list.append([_painting.holder(_by_role[mirrored][0]), Symmetry.MIRROR])
	else:
		list.append([own, Symmetry.TURN_NONE])
	_targets[cell] = list
	return list


func _upload_cell(cell: Vector2i) -> void:
	var image: Image = _painting.image_of(cell)
	if image == null:
		return
	if _textures.has(cell):
		var texture: ImageTexture = _textures[cell]
		texture.update(image)
	else:
		_textures[cell] = ImageTexture.create_from_image(image)
