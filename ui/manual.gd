# LE MODE D'EMPLOI — trois niveaux, du geste a la regle.
#
# ⚠ TROIS NIVEAUX PARCE QU'IL Y A TROIS LECTEURS, ET QU'ILS NE CHERCHENT PAS LA MEME CHOSE.
# Celui qui vient d'acheter veut peindre dans la minute. Celui qui a peint veut savoir
# pourquoi l'outil lui refuse une case. Celui qui ecrit son moteur veut la regle, ligne par
# ligne, sans une phrase de plus. Un seul texte pour les trois ne sert aucun des trois.
#
# ⚠ ET LE TROISIEME NIVEAU N'EST PAS ECRIT ICI. Il est lu de `TilesetPNG.placement_rules()`,
# c'est-a-dire de ce qui part VRAIMENT dans le manifeste. Le recopier donnerait deux textes a
# tenir d'accord, et le jour ou la regle bouge il y en a un qui ment.
extends Control

const TilesetPNG := preload("res://exporters/tileset_png.gd")
const Walls := preload("res://core/walls.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const CornerIndex := preload("res://core/corner_index.gd")

const VEIL: Color = Color(0.055, 0.063, 0.055, 0.82)
const PAPER: Color = Color(0.118, 0.129, 0.118, 1.0)
const INK: Color = Color(0.855, 0.871, 0.839, 1.0)
const FAINT: Color = Color(0.588, 0.612, 0.588, 1.0)
const TITLE: Color = Color(0.733, 0.792, 0.514, 1.0)

## Part de la fenetre que prend le panneau. ⚠ PAS TOUT L'ECRAN : voir le guide depasser
## derriere rappelle qu'on est pose PAR-DESSUS le travail, pas parti ailleurs.
const SHARE: float = 0.86


## ⚠ `set_anchors_and_offsets_preset`, PAS `set_anchors_preset`. Le second recalcule les
## decalages pour CONSERVER la taille courante -- qui vaut zero a `_ready`. Le panneau
## restait donc grand comme son contenu minimum, colle en haut a gauche, et le voile ne
## couvrait rien. Rien ne le signalait : les ancres etaient bien celles qu'on avait demandees.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _build() -> void:
	var veil: ColorRect = ColorRect.new()
	veil.color = VEIL
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(veil)

	var frame: PanelContainer = PanelContainer.new()
	frame.anchor_left = 0.5 - SHARE * 0.5
	frame.anchor_right = 0.5 + SHARE * 0.5
	frame.anchor_top = 0.5 - SHARE * 0.5
	frame.anchor_bottom = 0.5 + SHARE * 0.5
	frame.offset_left = 0.0
	frame.offset_right = 0.0
	frame.offset_top = 0.0
	frame.offset_bottom = 0.0
	var skin: StyleBoxFlat = StyleBoxFlat.new()
	skin.bg_color = PAPER
	skin.border_color = Color(0.239, 0.263, 0.231, 1.0)
	skin.set_border_width_all(1)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(18)
	frame.add_theme_stylebox_override("panel", skin)
	add_child(frame)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	frame.add_child(column)

	var head: HBoxContainer = HBoxContainer.new()
	column.add_child(head)
	var title: Label = Label.new()
	title.text = "Mode d'emploi"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var shut: Button = Button.new()
	shut.text = "✕"
	shut.flat = true
	shut.tooltip_text = "Fermer (Echap)"
	shut.add_theme_font_size_override("font_size", 20)
	shut.pressed.connect(close)
	head.add_child(shut)

	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	_page(tabs, "1 · Prise en main", _hands_on())
	_page(tabs, "2 · Comment ça marche", _how_it_works())
	_page(tabs, "3 · La règle de pose", "")


## Une page : du texte enrichi, qui defile.
func _page(tabs: TabContainer, name: String, body: String) -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = name
	tabs.add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var text: RichTextLabel = RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.selection_enabled = true
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("default_color", INK)
	text.text = body if not body.is_empty() else _the_contract()
	margin.add_child(text)


func open() -> void:
	visible = true
	move_to_front()
	grab_focus()


func close() -> void:
	visible = false


## ⚠ ECHAP FERME, PARCE QUE C'EST LE GESTE QU'ON FAIT SANS Y PENSER. Une fenetre qui ne se
## ferme que par sa croix oblige a viser pour sortir de quelque chose qu'on a ouvert par
## curiosite.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		close()
		accept_event()


func _titre(text: String) -> String:
	return "\n[font_size=17][color=#bbca83]%s[/color][/font_size]\n" % text


func _hands_on() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[i]Vous peignez un paysage une fois. Le logiciel en tire un tileset "
			+ "complet, et le moteur le pose sans que vous ayez rien a regler.[/i]")

	lines.append(_titre("1. Choisir ce qu'on fabrique"))
	lines.append("Dans la barre de gauche, trois choix, et ils se font [b]avant[/b] de "
			+ "dessiner : le [b]paysage[/b], la [b]taille des faux pixels[/b], le "
			+ "[b]reseau[/b].")
	lines.append("Ils se ferment au premier pixel pose : en changer rejetterait le travail, "
			+ "puisque ce ne seraient plus les memes tuiles.")

	lines.append(_titre("2. Peindre"))
	lines.append("[b]Clic gauche[/b] pose, [b]clic droit[/b] efface. Choisissez une couleur "
			+ "dans la palette du Crayon.")
	lines.append("Les cases qui portent [b]la meme tuile[/b] se remplissent ensemble : ce "
			+ "n'est pas une autre tuile qui se ressemble, c'est la meme, vue a plusieurs "
			+ "endroits. Un coup de crayon peut donc en toucher cent.")
	lines.append("Les cases [color=#e1b360]cerclees d'ambre[/color] n'ont pas de jumelle : "
			+ "personne d'autre ne portera leur tuile.")
	lines.append("[b]Ctrl+Z[/b] defait un trait entier, [b]Ctrl+Y[/b] le refait. "
			+ "[b]Ctrl+S[/b] enregistre, [b]Ctrl+O[/b] rouvre.")
	lines.append("[color=#96a096]Les deux jauges en haut a droite disent ce qui reste. "
			+ "Elles se recalculent a chaque coup de crayon, avec les memes fonctions que la "
			+ "suite de tests : ce que l'ecran affiche est ce que les tests prouvent."
			+ "[/color]")

	lines.append(_titre("3. Exporter"))
	lines.append("Le bouton [b]Exporter[/b] s'ouvre quand il ne manque plus une tuile, et "
			+ "pas avant. Une feuille a moitie peinte n'est pas un tileset, c'est un piege : "
			+ "des trous transparents qu'on decouvrirait dans le jeu.")
	lines.append("Il ecrit [b]quatre fichiers[/b] : les deux planches, une planche de "
			+ "[b]preuve[/b] -- chaque cas isole, a une place connue d'avance -- et le "
			+ "[b]manifeste[/b], qui porte la regle de pose en entier.")

	lines.append(_titre("4. Installer dans votre moteur"))
	lines.append("Bouton [b]Installer le plugin Godot[/b], puis choisissez [b]la racine du "
			+ "projet[/b] : le dossier qui contient [code]project.godot[/code]. Pas "
			+ "[code]addons/[/code], pas une sous-scene -- la racine.")
	lines.append("Un [b]tileset part avec[/b], dans [code]absolutiles/[/code] : le votre "
			+ "s'il est complet, son [b]essai[/b] sinon. L'essai est fait du dessin du guide "
			+ "lui-meme : de quoi poser un monde tout de suite, sans avoir peint.")

	lines.append(_titre("5. Peindre le monde, dans Godot"))
	lines.append("[b]Projet → Parametres du projet → Extensions[/b], cochez "
			+ "[b]AbsoluPaint[/b].")
	lines.append("Un bouton [b]AbsoluPaint[/b] apparait dans la barre du haut. Cliquez-le : "
			+ "il ouvre son panneau, pose un monde dans la scene ouverte et vous y emmene.")
	lines.append("Dans le panneau : choisissez un [b]etage[/b] (0 est du sol, 1 a 9 les "
			+ "plateaux, [b]Vide[/b] retire la case du monde), [b]armez le pinceau[/b], et "
			+ "peignez. Clic gauche pose, clic droit retire.")
	lines.append("[color=#96a096]Vous n'avez aucun fichier a pointer : le panneau cherche "
			+ "les tilesets du projet et les propose. S'il n'y en a qu'un, il le prend."
			+ "[/color]")
	lines.append("[color=#96a096]Le pinceau s'arme a la main, expres : tant qu'il est arme, "
			+ "la souris peint au lieu de deplacer les noeuds.[/color]")
	return "\n".join(lines)


func _how_it_works() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[i]Ce niveau explique pourquoi l'outil refuse certaines choses. Rien ici "
			+ "n'est necessaire pour peindre.[/i]")

	lines.append(_titre("Le guide est prouve avant que vous ne peigniez"))
	# ⚠ ON FORME LA PHRASE PUIS ON LA REMPLIT. En GDScript, `%` mord sur le DERNIER
	# fragment d'une concatenation, pas sur l'ensemble : ecrit d'un trait, il cherchait ses
	# arguments dans un morceau qui n'en attendait aucun.
	var count: int = BlobIndex.CANONICAL_INDICES.size()
	var neighbourhood: String = ("Une tuile de surface ne depend que du voisinage de sa "
			+ "case : huit voisins, donc 256 configurations, qui se ramenent a [b]%d[/b] une "
			+ "fois qu'on jette les coins diagonaux isoles -- ils ne changent pas la "
			+ "silhouette.")
	lines.append(neighbourhood % count)
	var proven: String = ("Le guide livre contient les %d, verifie par programme. Ce n'est "
			+ "pas une promesse : c'est un compte.")
	lines.append(proven % count)

	lines.append(_titre("Deux vocabulaires, jamais melanges"))
	lines.append("Un terrain resout les coins d'un [b]plan[/b]. Une falaise [b]sort du "
			+ "plan[/b] : sa face occupe des cases qui, vues de dessus, appartiennent au sol "
			+ "d'en bas. Aucun systeme de terrain ne peut la poser.")
	var families: String = ("D'ou deux familles : [b]%d[/b] tuiles de surface et [b]%d[/b] "
			+ "de mur, soit [b]%d[/b] en tout -- et deux planches separees, pour qu'on sache "
			+ "toujours ou l'une s'arrete.")
	lines.append(families % [count, Walls.ALL_ROLES.size(), count + Walls.ALL_ROLES.size()])
	var astride: String = ("En reseau [b]a cheval[/b], une tuile est posee sur le croisement "
			+ "de quatre cases : [b]%d[/b] tuiles de surface au lieu de %d, les murs ne "
			+ "changeant pas.")
	lines.append(astride % [CornerIndex.TILE_COUNT, count])

	lines.append(_titre("Ce que le crayon fait sans vous le demander"))
	lines.append("[b]Les jumelles.[/b] Deux cases qui portent la meme tuile ne se "
			+ "ressemblent pas : c'est la meme tuile. Les remplir ensemble ne peut donc "
			+ "jamais etre faux, et ce n'est pas une option.")
	lines.append("[b]Les raccords obligatoires.[/b] Par endroits, deux tuiles de falaise "
			+ "[b]sont la meme paroi[/b] : deux rangees qui se suivent dans une chute, deux "
			+ "flancs muets face a face. Le pixel qui borde l'une borde l'autre -- on le "
			+ "recopie la ou l'egalite est demontree, et nulle part ailleurs.")
	lines.append("[color=#96a096]Sur les surfaces, aucune egalite n'est exigee : a la "
			+ "frontiere entre une case dont le nord est plein et une case dont il est vide, "
			+ "la levre eclairee s'arrete net, et elle a raison -- le terrain fait une marche "
			+ "la.[/color]")

	lines.append(_titre("Le vide, la plaine, et le bord du monde"))
	var plain: String = ("[b]La plaine est un plateau comme les autres.[/b] Elle a sa "
			+ "silhouette, ses %d index, et ses falaises la ou elle borde le [b]vide[/b].")
	lines.append(plain % count)
	lines.append("Le vide n'est pas la plaine : c'est le hors-monde. Sans cette distinction "
			+ "le moteur ne saurait pas ou le sol s'arrete, et ne poserait aucun etage 0.")
	lines.append("Dans le plugin : une case [b]presente[/b] a l'etage 0 est du sol, une case "
			+ "[b]absente[/b] n'est rien.")

	lines.append(_titre("Ce que l'export refuse, et pourquoi"))
	lines.append("Une feuille incomplete. Un manifeste trop vieux ou trop recent pour le "
			+ "lecteur -- une regle a pu changer de sens, et poser quand meme serait un "
			+ "mensonge silencieux. Des constantes de falaise que le moteur ne sait pas "
			+ "rejouer.")
	lines.append("[color=#96a096]Un refus n'est pas une erreur : incomplet est l'etat normal "
			+ "pendant tout le travail. Le bouton est grise, le compte s'affiche, et c'est "
			+ "tout.[/color]")

	lines.append(_titre("Ce que le plugin fait de votre feuille"))
	lines.append("Il lit le manifeste, fabrique un TileSet, et pose : les sommets de chaque "
			+ "etage [b]du bas vers le haut[/b], puis les faces de falaise par-dessus.")
	lines.append("[b]Il ne fabrique aucune tuile.[/b] Chaque case va chercher, dans la "
			+ "planche, celle que la regle designe. Si la regle en designait une qui n'existe "
			+ "pas, ce serait un trou -- et c'est exactement ce que le refus d'une feuille "
			+ "incomplete rend impossible.")
	return "\n".join(lines)


## LA REGLE DE POSE, telle qu'elle part dans le manifeste. Pas une paraphrase : le texte.
func _the_contract() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[i]Ce qui suit est [b]mot pour mot[/b] ce que votre moteur recoit, dans "
			+ "le fichier [code]<nom>_tileset.txt[/code]. Quelqu'un qui n'a que ce fichier "
			+ "et les deux planches doit pouvoir poser un monde correct : si une regle "
			+ "manquait ici, elle vivrait dans la tete de celui qui a ecrit le premier "
			+ "moteur, et le second divergerait sans que rien ne le dise.[/i]\n")
	lines.append("[code]")
	for line: String in TilesetPNG.placement_rules():
		var clean: String = line.replace("[", "[lb]")
		if clean.strip_edges().is_empty():
			lines.append("")
		elif clean.begins_with("#"):
			lines.append("[color=#96a096]%s[/color]" % clean)
		else:
			lines.append("[color=#e1d9b0]%s[/color]" % clean)
	lines.append("[/code]")
	return "\n".join(lines)
