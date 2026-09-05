# L'APERCU EN JEU — vos tuiles dans un decor ordinaire.
#
# Le guide est un banc d'epreuve : il entasse les accidents pour qu'aucune tuile ne manque. Il ne
# ressemblera jamais a une carte de jeu, donc il ne dira jamais si le tileset REND bien. Ce
# panneau montre les memes tuiles posees sur un relief CALME -- des masses franches, deux ou
# trois etages -- bati au GESTE, donc atteignable au pinceau comme tout le reste.
#
# ⚠ IL NE FABRIQUE AUCUNE TUILE (charte, regle 3). Chaque case emprunte, PAR IDENTITE, ce qui est
# peint dans le guide -- et toujours la PREMIERE occurrence, sinon le decor scintillerait a
# chaque coup de crayon. Rien de neuf n'est invente : c'est le meme dessin, vu ailleurs.
#
# ⚠ CE QUI N'EST PAS PEINT RESTE UN TROU, comme partout ailleurs. Le decor se remplit au fur et a
# mesure du travail, et ce qui manque se voit DANS SON CONTEXTE -- ce qu'aucune jauge ne montre.
#
# ⚠ ET IL NE MONTRE PAS TOUT, c'est meme le point. Un decor calme n'appelle qu'une trentaine des
# tuiles du vocabulaire : c'est la verite des tilesets, une carte ordinaire n'en use qu'une
# poignee. Le panneau dit COMMENT CA REND, pas SI TOUT EST PEINT -- les jauges sont la pour ca.
extends Control

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifScene := preload("res://render/massif_scene.gd")

## Le decor livre. ⚠ BATI AU GESTE ET LEGAL, verifie a la fabrication : l'ancien decor
## (`preview.txt`) appartenait au modele d'avant et n'etait plus legal sous celui des massifs --
## treize rubans d'herbe fins, dix bords sud trop etroits. Un apercu qui montre un relief que le
## pinceau refuse ment sur ce que l'outil produit.
const SCENE_PATH: String = "res://guides/apercu.txt"

## ⚠ OPAQUE, SANS DISCUSSION. On ne juge pas une couleur a travers autre chose -- meme six pour
## cent de zone de travail derriere fausseraient ce que le panneau existe pour montrer. C'est la
## meme raison qui fait disparaitre la grille quand on juge un aplat.
const FRAME: Color = Color(0.086, 0.094, 0.102, 1.0)
const EDGE: Color = Color(1.0, 1.0, 1.0, 0.10)
const MARGIN: float = 10.0

var _scene: PackedStringArray = PackedStringArray()
var _guide: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null
## Les poses du decor, dans l'ordre de dessin. ⚠ CALCULEES UNE FOIS : `Massifs.poses` coute
## des dizaines de millisecondes, et ce panneau se redessine a chaque coup de crayon.
var _poses: Array[Dictionary] = []
## L'ETENDUE REELLEMENT POSEE, en cases. ⚠ ELLE N'EST PAS CELLE DU RELIEF : une falaise pend
## SOUS la lèvre qui la lance, et une lèvre proche du bord pose donc des cases au-dela de la
## derniere rangee du monde. Mesure sur le decor livre : trois rangees de plus. Cadrer sur les
## rangees DECLAREES coupait la falaise au bord du panneau -- c'est la meme loi que « chaque
## relief doit declarer son bord », vue de l'autre cote : ici on ne peut pas exiger la marge du
## decor, alors on cadre sur ce qui existe.
var _span: Vector2i = Vector2i.ZERO
## Cle de tuile -> texture empruntee au guide.
var _textures: Dictionary = {}
var _dirty: bool = true


func _ready() -> void:
	# ⚠ FILTRAGE AU PLUS PROCHE. Un lissage bilineaire melangerait les bords de tuiles voisines
	# et fabriquerait des degrades la ou le dessin a des aretes nettes : le panneau montrerait
	# des defauts que la peinture n'a pas.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_scene(HeightMask.read(SCENE_PATH))
	set_process(true)


## Branche le panneau sur le guide en cours.
func show_guide(guide: PackedStringArray, painting: RefCounted) -> void:
	if _scene.is_empty():
		set_scene(HeightMask.read(SCENE_PATH))
	_guide = guide
	_painting = painting
	_textures.clear()
	_dirty = true
	queue_redraw()


## Change de decor. La colline dit COMMENT CA REND ; la planche de preuve montre que RIEN NE
## MANQUE. Deux questions differentes, deux decors.
func set_scene(relief: PackedStringArray) -> void:
	_scene = relief
	_poses = Massifs.poses(_scene) if not _scene.is_empty() else ([] as Array[Dictionary])
	_span = Vector2i(HeightMask.width(_scene), HeightMask.height(_scene))
	for pose: Dictionary in _poses:
		var at: Vector2i = pose["cell"]
		_span = Vector2i(maxi(_span.x, at.x + 1), maxi(_span.y, at.y + 1))
	_textures.clear()
	_dirty = true
	queue_redraw()


func mark_dirty() -> void:
	_dirty = true


## ⚠ ON REMONTE TOUT PLUTOT QUE DE TENIR UNE COMPTABILITE. Le decor n'emprunte qu'une trentaine
## de tuiles distinctes : les refaire toutes coute moins cher que de suivre celles qui ont bouge,
## et surtout ca ne peut pas se desynchroniser du carnet.
func _process(_delta: float) -> void:
	if not _dirty or not visible or _painting == null or _guide.is_empty():
		return
	_dirty = false
	var art: Dictionary = MassifScene.art_of(_guide, _painting)
	_textures.clear()
	for pose: Dictionary in _poses:
		var tile: int = Massifs.key_of(pose)
		if _textures.has(tile) or not art.has(tile):
			continue
		_textures[tile] = ImageTexture.create_from_image(art[tile] as Image)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FRAME)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)

	var columns: int = _span.x
	var rows: int = _span.y
	if columns <= 0 or rows <= 0:
		return
	var usable: Vector2 = size - Vector2(MARGIN, MARGIN) * 2.0
	# ⚠ LE COTE DE CASE EST ARRONDI A L'ENTIER. Une echelle fractionnaire etalerait chaque tuile
	# sur un nombre non entier de pixels d'ecran, et le rendu montrerait des coutures que le
	# dessin n'a pas -- exactement le defaut que ce panneau existe pour reveler.
	var side: float = maxf(1.0, floorf(minf(usable.x / float(columns), usable.y / float(rows))))
	var span: Vector2 = Vector2(float(columns), float(rows)) * side
	var origin: Vector2 = ((size - span) * 0.5).floor()

	# ⚠ DANS L'ORDRE DE POSE, ET C'EST LUI QUI FAIT L'OCCLUSION. Un massif se dessine ENTIER, y
	# compris sous ce qui le recouvre : ce qui passe apres est devant. On ne trie rien ici,
	# `Massifs.poses` rend deja les poses dans le bon ordre.
	for pose: Dictionary in _poses:
		var tile: int = Massifs.key_of(pose)
		if not _textures.has(tile):
			continue
		var cell: Vector2i = pose["cell"]
		draw_texture_rect(_textures[tile],
				Rect2(origin + Vector2(float(cell.x), float(cell.y)) * side,
				Vector2(side, side)), false)
