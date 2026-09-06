# LE MODE D'EMPLOI — trois niveaux, du geste a la regle.
#
# ⚠ TROIS NIVEAUX PARCE QU'IL Y A TROIS LECTEURS, ET QU'ILS NE CHERCHENT PAS LA MEME CHOSE.
# Celui qui vient d'acheter veut peindre dans la minute. Celui qui a peint veut savoir
# pourquoi l'outil lui refuse une case. Celui qui ecrit son moteur veut la regle, ligne par
# ligne, sans une phrase de plus. Un seul texte pour les trois ne sert aucun des trois.
#
# ⚠ ET LE TROISIEME NIVEAU N'EST PAS ECRIT ICI. Il est lu de `MassifTileset.placement_rules()`,
# c'est-a-dire de ce qui part VRAIMENT dans le manifeste. Le recopier donnerait deux textes a
# tenir d'accord, et le jour ou la regle bouge il y en a un qui ment.
extends Control

const MassifTileset := preload("res://exporters/massif_tileset.gd")
const Families := preload("res://core/families.gd")

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
	title.text = "User guide"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var shut: Button = Button.new()
	shut.text = "✕"
	shut.flat = true
	shut.tooltip_text = "Close (Esc)"
	shut.add_theme_font_size_override("font_size", 20)
	shut.pressed.connect(close)
	head.add_child(shut)

	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	_page(tabs, "1 · Getting started", _hands_on())
	_page(tabs, "2 · How it works", _how_it_works())
	_page(tabs, "3 · The placement rule", "")


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
	lines.append("[i]You paint one landscape, once. The software pulls a complete "
			+ "tileset out of it, and the engine places it with nothing for you to set.[/i]")

	lines.append(_titre("1. Choose what you are making"))
	lines.append("In the left bar, three choices, and they are made [b]before[/b] you "
			+ "draw: the [b]landscape[/b], the [b]fake pixel size[/b], the "
			+ "[b]layout[/b].")
	lines.append("They close on the first pixel placed: changing one would throw the work away, "
			+ "because they would no longer be the same tiles.")

	lines.append(_titre("2. Paint"))
	lines.append("[b]Left click[/b] paints, [b]right click[/b] erases. Pick a colour "
			+ "from the palette in the Tools section.")
	lines.append("Eight tools, one key each: [b]pencil[/b] (P), [b]brush[/b] (B), "
			+ "[b]spray[/b] (A), [b]fill[/b] (G), [b]line[/b] (L), [b]rectangle[/b] (R), "
			+ "[b]picker[/b] (I), [b]eraser[/b] (E). The [b]Size[/b] row -- or the keys "
			+ "[ and ] -- sets the diameter of the brush, the spray, the eraser, the "
			+ "line and the rectangle; the pencil is always one pixel.")
	lines.append("[b]Keep inside the tile[/b]: a stroke stays in the tile where it "
			+ "started, whatever spills onto a neighbour is ignored. The fill stops "
			+ "on its own at the tile edge.")
	lines.append("Cells carrying [b]the same tile[/b] fill together: it is not another "
			+ "tile that merely looks alike, it is the same one, seen in several "
			+ "places. One stroke can therefore touch a hundred.")
	lines.append("Cells [color=#e1b360]ringed in amber[/color] have no twin: "
			+ "nobody else will carry their tile.")
	lines.append("[b]Ctrl+Z[/b] undoes a whole stroke, [b]Ctrl+Y[/b] redoes it. "
			+ "[b]Ctrl+S[/b] saves, [b]Ctrl+O[/b] reopens.")
	lines.append("[color=#96a096]The two gauges at the top right say what is left. "
			+ "They recompute at every stroke, with the same functions as the "
			+ "test suite: what the screen shows is what the tests prove."
			+ "[/color]")

	lines.append(_titre("3. Export"))
	lines.append("The [b]Export[/b] button opens when not one tile is missing, and "
			+ "not before. A half-painted sheet is not a tileset, it is a trap: "
			+ "transparent holes you would only find in the game.")
	lines.append("It writes [b]two files[/b]: the [b]sheet[/b] -- surfaces and cliff "
			+ "faces together, one single vocabulary, tiles ordered by key -- and the "
			+ "[b]manifest[/b], which says where the tiles are.")

	lines.append(_titre("4. Install into your engine"))
	lines.append("The [b]Install the Godot plugin[/b] button, then choose [b]the project "
			+ "root[/b]: the folder holding [code]project.godot[/code]. Not "
			+ "[code]addons/[/code], not a sub-scene -- the root.")
	lines.append("A [b]tileset ships with it[/b], in [code]solutiles/[/code]: yours "
			+ "if it is complete, the [b]trial[/b] otherwise. The trial is made of the guide's own "
			+ "drawing: enough to place a world right away, without having painted.")

	lines.append(_titre("5. Paint the world, in Godot"))
	lines.append("[b]Project → Project Settings → Plugins[/b], tick "
			+ "[b]SoluPaint[/b].")
	lines.append("A [b]SoluPaint[/b] button appears in the top bar. Click it: "
			+ "it opens its panel, places a world in the open scene and takes you there.")
	lines.append("In the panel: choose a [b]level[/b] (0 is ground, 1 to 9 the "
			+ "plateaus, [b]Void[/b] removes the cell from the world), [b]arm the brush[/b], and "
			+ "paint. Left click places, right click removes.")
	lines.append("[color=#96a096]You have no file to point at: the panel searches "
			+ "the project for tilesets and offers them. If there is only one, it takes it."
			+ "[/color]")
	lines.append("[color=#96a096]The brush is armed by hand, on purpose: while it is armed, "
			+ "the mouse paints instead of moving nodes.[/color]")
	return "\n".join(lines)


func _how_it_works() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[i]This level explains why the tool refuses certain things. Nothing here "
			+ "is needed in order to paint.[/i]")

	lines.append(_titre("The guide is proven before you paint"))
	lines.append("A tile is not a picture you pick: it is [b]what its surroundings make it[/b]. "
			+ "The tool knows every case that can occur, it lays them all out in the guide, and it "
			+ "refuses whatever it cannot guarantee.")
	lines.append("[b]Nothing is one cell thick.[/b] Spikes, isthmuses, islets and one-cell "
			+ "holes do not exist -- not here, and not in the engine, whose brush refuses them as "
			+ "you draw them, corner pinches included.")
	# ⚠ ON FORME LA PHRASE PUIS ON LA REMPLIT. En GDScript, `%` mord sur le DERNIER
	# fragment d'une concatenation, pas sur l'ensemble : ecrit d'un trait, il cherchait ses
	# arguments dans un morceau qui n'en attendait aucun.
	#
	# ⚠ ET LE COMPTE SE LIT, IL NE S'ECRIT JAMAIS EN DUR. C'est l'expression dont l'export se
	# sert pour la planche ET pour le manifeste : le manuel dit donc toujours ce que l'acheteur
	# recoit vraiment. Un nombre ecrit ici mentirait des la tuile suivante -- le vocabulaire a
	# bouge trois fois dans la seule journee du 06/09.
	var proven: String = ("The guide you are given carries all [b]%d[/b] of them, verified by "
			+ "program. That is not a promise: it is a count.")
	lines.append(proven % Families.massif_tiles().size())

	lines.append(_titre("Why a terrain system is not enough"))
	lines.append("A terrain solves the corners of a [b]plane[/b]. A cliff [b]leaves the "
			+ "plane[/b]: its face fills cells which, seen from above, belong to the ground "
			+ "below. No terrain system can place it.")
	lines.append("Here a massif is [b]one whole thing[/b] -- its surface, and the cliff hanging "
			+ "under it -- and a tile is that one shape seen at a given height: [b]surface[/b], "
			+ "[b]cap[/b], [b]body[/b] or [b]foot[/b]. One vocabulary, one sheet.")

	lines.append(_titre("What the pencil does without asking you"))
	lines.append("[b]Twins.[/b] Two cells carrying the same tile do not "
			+ "merely look alike: they are the same tile. Filling them together can therefore "
			+ "never be wrong, and it is not an option. They share, in fact, a "
			+ "single image: painting one is painting the other, literally.")
	lines.append("[b]A cell under a cliff carries the cliff.[/b] On the map it is "
			+ "ground from below, but only the face is visible: it takes the cliff alone, never "
			+ "the surface it covers.")
	lines.append("[color=#96a096]All the context a tile ever gets is four bits: whether its "
			+ "massif overlaps another one, and whether grass and rock of the same massif meet on "
			+ "its west, east or north side. Nothing else.[/color]")

	lines.append(_titre("The void, the plain, and the world's edge"))
	lines.append("[b]The plain is a massif like any other.[/b] It has its silhouette, and its "
			+ "cliffs wherever it borders the [b]void[/b].")
	lines.append("The void is not the plain: it is outside the world. Without that distinction "
			+ "the engine would not know where the ground stops, and would place no level 0.")
	lines.append("In the plugin: a cell [b]present[/b] at level 0 is ground, a cell "
			+ "[b]absent[/b] is nothing.")

	lines.append(_titre("What the export refuses, and why"))
	lines.append("An incomplete sheet. A manifest too old or too new for the "
			+ "reader -- a rule may have changed meaning, and placing anyway would be a "
			+ "silent lie. Cliff constants the engine does not know how to "
			+ "replay.")
	lines.append("[color=#96a096]A refusal is not an error: incomplete is the normal state "
			+ "throughout the work. The button is greyed out, the count is shown, and that is "
			+ "all.[/color]")

	lines.append(_titre("What the plugin does with your sheet"))
	lines.append("It reads the manifest, builds a TileSet, and places [b]one layer per level, "
			+ "from the bottom up[/b]. What is higher covers what is lower, and the drawing order "
			+ "settles the rest -- there is nothing to assemble.")
	lines.append("[b]It makes no tile.[/b] Every cell fetches, from the "
			+ "sheet, the one the rule names. If the rule named one that did not "
			+ "exist, there would be a hole -- and that is exactly what refusing an incomplete "
			+ "sheet makes impossible.")
	return "\n".join(lines)


## LA REGLE DE POSE, telle qu'elle part dans le manifeste. Pas une paraphrase : le texte.
func _the_contract() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[i]What follows is [b]word for word[/b] what your engine receives, in "
			+ "the file [code]<name>_tileset.txt[/code]. Someone who has only this file "
			+ "and the sheet must be able to place a correct world: if a rule "
			+ "were missing here, it would live in the head of whoever wrote the first "
			+ "engine, and the second would diverge with nothing to say so.[/i]\n")
	lines.append("[code]")
	for line: String in MassifTileset.placement_rules():
		var clean: String = line.replace("[", "[lb]")
		if clean.strip_edges().is_empty():
			lines.append("")
		elif clean.begins_with("#"):
			lines.append("[color=#96a096]%s[/color]" % clean)
		else:
			lines.append("[color=#e1d9b0]%s[/color]" % clean)
	lines.append("[/code]")
	return "\n".join(lines)
