# LA FENETRE DE L'EDITEUR — cablage, et rien d'autre.
#
# Toute la logique vit dans core/ ; ce fichier ne fait que brancher des boutons sur elle et
# afficher ce qu'elle repond. Si une regle du produit apparait ici, c'est qu'elle est mal
# rangee.
#
# ⚠ LE COMPTE EST A L'ECRAN PENDANT QU'ON PEINT (charte, regle 6). Les deux jauges se
# recalculent a chaque coup de crayon, depuis les memes fonctions que les tests : ce que
# l'ecran affiche est ce que la suite prouve.
extends Control

const Modes := preload("res://core/modes.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Painting := preload("res://core/painting.gd")
const Variants := preload("res://core/variants.gd")
const Walls := preload("res://core/walls.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Symmetry := preload("res://core/symmetry.gd")
const Satyron := preload("res://render/satyron_tiles.gd")
const WorkIO := preload("res://core/work_io.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")
const ProofScene := preload("res://core/proof_scene.gd")

## Part de l'ecran occupee par la fenetre au lancement.
const WINDOW_SCREEN_SHARE: float = 0.95

## Le bandeau du haut, qui deroule la charte. C'est la seule fantaisie du logiciel, et elle
## dit quelque chose de vrai a chaque phrase.
const PROMISES: Array[String] = [
	"Le guide est prouve complet avant que vous ne posiez un pixel.",
	"On dessine, on ne configure pas.",
	"Un seul passage, du debut a la fin. Pas de boucle essai-export-correction.",
	"Rien n'est fabrique a votre place : ni composition, ni miroir, ni IA.",
	"L'exactitude se prouve, elle ne se promet pas.",
	"Ce qui n'est pas garanti est interdit : le crayon refuse le reste.",
	"47 tuiles de surface, 12 de mur. Le compte est tenu a l'ecran.",
	"Une case laissee vierge n'est pas utilisee. Peindre, c'est choisir.",
]
const PROMISE_SECONDS: float = 6.0

var _heights: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null

## Le fichier de travail en cours, vide tant qu on n a pas enregistre une fois.
var _work_path: String = ""
var _open_dialog: FileDialog = null
var _save_dialog: FileDialog = null
var _export_dialog: FileDialog = null
var _promise: int = 0
var _elapsed: float = PROMISE_SECONDS


func _ready() -> void:
	# ⚠ LA VERSION SE LIT DANS project.godot, elle ne se recopie pas ici. Deux endroits, et
	# ils finissent toujours par se contredire.
	(%Version as Label).text = String(ProjectSettings.get_setting("application/config/version", "?"))
	_apply_window_size()
	_fill_modes()
	_fill_resolutions()
	_fill_styles()
	_fill_inks()
	_fill_decors()
	var work: Control = %WorkArea
	work.painting_changed.connect(_refresh_counters)
	work.loading_progress.connect(_on_loading_progress)
	work.hover_changed.connect(_on_hover_changed)
	var mode_choice: OptionButton = %ModeChoice
	mode_choice.item_selected.connect(_on_mode_selected)
	var size_choice: OptionButton = %SizeChoice
	size_choice.item_selected.connect(_on_resolution_selected)
	var pencil: ColorPickerButton = %PencilColor
	pencil.color_changed.connect(_on_pencil_changed)
	for swatch: Node in %Swatches.get_children():
		var button: Button = swatch as Button
		if button != null:
			button.pressed.connect(_on_swatch_pressed.bind(button))
	(%StyleChoice as OptionButton).item_selected.connect(_on_style_selected)
	(%InkChoice as OptionButton).item_selected.connect(_on_style_selected)
	(%RotationsCheck as CheckBox).toggled.connect(_on_twins_toggled)
	(%TwinsCheck as CheckBox).toggled.connect(_on_twins_toggled)
	(%FitButton as Button).pressed.connect(_on_fit_pressed)
	(%GridCheck as CheckBox).toggled.connect(_on_grid_toggled)
	(%AssembledCheck as CheckBox).toggled.connect(_on_assembled_toggled)
	(%PreviewCheck as CheckBox).toggled.connect(_on_preview_toggled)
	(%WorkCheck as CheckBox).toggled.connect(_on_work_hidden)
	(%DecorChoice as OptionButton).item_selected.connect(_on_decor_selected)
	work.painting_changed.connect((%PreviewPanel as Control).mark_dirty)
	(%ExportButton as Button).pressed.connect(_on_export_pressed)
	(%OpenButton as Button).pressed.connect(_on_open_pressed)
	(%SaveButton as Button).pressed.connect(_on_save_pressed)
	_build_dialogs()
	_apply_margins()
	_load_current_mode()
	# ⚠ ON REPOSE LA TAILLE APRES LA PREMIERE IMAGE. Selon la facon dont on lance -- depuis
	# l'editeur Godot, depuis un raccourci --, la taille demandee dans _ready peut etre
	# ecrasee par celle du projet ou par le placement de l'editeur. On la repose une fois la
	# fenetre reellement ouverte, et on dit ce qu'on a obtenu.
	await get_tree().process_frame
	_apply_window_size()
	_apply_margins()
	work.fit()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < PROMISE_SECONDS:
		return
	_elapsed = 0.0
	(%Ticker as Label).text = PROMISES[_promise]
	_promise = (_promise + 1) % PROMISES.size()


## La fenetre occupe 95% de l'ecran, centree. Assez grand pour travailler, assez petit pour
## qu'on voie qu'il y a un bureau derriere.
func _apply_window_size() -> void:
	var window: Window = get_window()
	if window == null:
		return
	# Une fenetre maximisee ignore toute taille qu'on lui demande.
	if window.mode != Window.MODE_WINDOWED:
		window.mode = Window.MODE_WINDOWED
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	var target: Vector2i = Vector2i(
			int(float(usable.size.x) * WINDOW_SCREEN_SHARE),
			int(float(usable.size.y) * WINDOW_SCREEN_SHARE))
	window.size = target
	window.position = usable.position + (usable.size - target) / 2
	print("AbsoluTiles : fenetre %dx%d, ecran utile %dx%d" % [
			window.size.x, window.size.y, usable.size.x, usable.size.y])


func _fill_modes() -> void:
	var choice: OptionButton = %ModeChoice
	choice.clear()
	var first_open: int = -1
	for id: StringName in Modes.ids():
		choice.add_item(Modes.label(id))
		var index: int = choice.item_count - 1
		choice.set_item_metadata(index, id)
		# Un mode dont le guide n'existe pas figure a la liste mais ne se choisit pas.
		var open: bool = Modes.is_available(id)
		choice.set_item_disabled(index, not open)
		if open and first_open < 0:
			first_open = index
	choice.select(maxi(first_open, 0))


func _fill_resolutions() -> void:
	var choice: OptionButton = %SizeChoice
	choice.clear()
	for resolution: int in Painting.RESOLUTIONS:
		choice.add_item("%d x %d" % [resolution, resolution])
		choice.set_item_metadata(choice.item_count - 1, resolution)
		if resolution == Painting.DEFAULT_RESOLUTION:
			choice.select(choice.item_count - 1)


## ⚠ TROIS AXES INDEPENDANTS, ET ILS NE SE COMMANDENT PAS L UN L AUTRE.
##   le PAYSAGE   -- quel relief : minimal ou ample. C est le mode.
##   la TECHNIQUE -- ce que le fond montre : le resultat seul, ou plus les marques.
##   le STYLE     -- de quoi le fond est fait : des aplats, ou des traits.
## Les deux derniers sont des aides a la vue : rien de ce qui sort n en depend. Les
## avoir melanges une fois a suffi a rendre l un a la place de l autre.
func _fill_styles() -> void:
	var choice: OptionButton = %StyleChoice
	choice.clear()
	choice.add_item("Representatif")
	choice.set_item_metadata(0, GuideImage.Purpose.REPRESENTATIVE)
	choice.add_item("Utilisable")
	choice.set_item_metadata(1, GuideImage.Purpose.USABLE)
	# ⚠ LE BANC D'ESSAI NE S'OUVRE QUE SI SATYRON EST LA. On lit son tileset chez lui, on ne
	# le copie pas : sur une machine sans lui, la technique reste fermee (charte, regle 5).
	choice.add_item("Example")
	choice.set_item_metadata(2, GuideImage.Purpose.EXAMPLE)
	choice.set_item_disabled(2, not Satyron.is_available())
	choice.select(0)


func _fill_inks() -> void:
	var choice: OptionButton = %InkChoice
	choice.clear()
	choice.add_item("Peint")
	choice.set_item_metadata(0, GuideImage.Ink.PAINTED)
	choice.add_item("Fil de fer")
	choice.set_item_metadata(1, GuideImage.Ink.WIREFRAME)
	choice.select(0)


func _on_style_selected(_index: int) -> void:
	_apply_background_style()


func _apply_background_style() -> void:
	var technic: OptionButton = %StyleChoice
	var style: OptionButton = %InkChoice
	var purpose: GuideImage.Purpose = technic.get_item_metadata(technic.selected)
	# ⚠ LE STYLE N'A PAS DE SENS SUR LE BANC D'ESSAI : ce ne sont ni nos aplats ni nos traits,
	# ce sont les tuiles de quelqu'un d'autre. On ferme le choix plutot que de l'ignorer.
	style.disabled = purpose == GuideImage.Purpose.EXAMPLE
	(%WorkArea as Control).set_guide_style(style.get_item_metadata(style.selected), purpose)


func _current_mode() -> StringName:
	var choice: OptionButton = %ModeChoice
	return choice.get_item_metadata(choice.selected)


func _current_resolution() -> int:
	var choice: OptionButton = %SizeChoice
	return int(choice.get_item_metadata(choice.selected))


func _load_current_mode() -> void:
	var id: StringName = _current_mode()
	var path: String = Modes.guide_path(id)
	if not FileAccess.file_exists(path):
		push_error("editor: guide introuvable pour le mode '%s' : %s" % [id, path])
		return
	_heights = HeightMask.read(path)
	_painting = Painting.new(_current_resolution())
	var work: Control = %WorkArea
	work.pencil = (%PencilColor as ColorPickerButton).color
	_apply_fill_rules()
	var technic: OptionButton = %StyleChoice
	var style: OptionButton = %InkChoice
	work.guide_ink = style.get_item_metadata(style.selected)
	work.guide_purpose = technic.get_item_metadata(technic.selected)
	work.show_guide(_heights, _painting)
	(%PreviewPanel as Control).show_guide(_heights, _painting)
	_apply_decor()
	_refresh_counters()


func _on_mode_selected(_index: int) -> void:
	_load_current_mode()


func _on_resolution_selected(_index: int) -> void:
	_load_current_mode()


func _on_pencil_changed(color: Color) -> void:
	(%WorkArea as Control).pencil = color


func _on_swatch_pressed(button: Button) -> void:
	if not button.has_meta("color"):
		return
	var color: Color = button.get_meta("color")
	(%PencilColor as ColorPickerButton).color = color
	(%WorkArea as Control).pencil = color


## ⚠ LA VALEUR AFFICHEE EST CELLE DU TRAVAIL REEL : des tuiles dessinees sur des tuiles a
## dessiner. Pas un compte a rebours, pas une animation qui tourne pendant qu'on attend.
func _on_loading_progress(done: int, total: int) -> void:
	var panel: Control = %LoadingPanel
	panel.visible = done < total
	var bar: ProgressBar = %LoadingBar
	bar.max_value = float(maxi(total, 1))
	bar.value = float(done)
	(%LoadingCount as Label).text = "%d / %d tuiles" % [done, total]


func _on_twins_toggled(_pressed: bool) -> void:
	_apply_fill_rules()


## ⚠ LES ROTATIONS SONT OFFERTES, PAS IMPOSEES, ET L OUTIL NE PEUT PAS TRANCHER A
## VOTRE PLACE. Une rotation FABRIQUE une tuile dans une orientation que personne n a
## peinte : sur un dessin eclaire c est visiblement faux, la lumiere tourne avec la
## tuile ; sur un dessin sans direction d eclairage c est correct. Or l outil ne sait
## pas ce que vous dessinez. La case le dit dans son infobulle, et le choix reste
## le votre.
func _apply_fill_rules() -> void:
	var work: Control = %WorkArea
	var rotations: bool = (%RotationsCheck as CheckBox).button_pressed
	var twins: CheckBox = %TwinsCheck
	work.set_fill_rules(twins.button_pressed, rotations)
	# Les jumelles sont deja comprises dans l orbite : la case devient sans objet.
	twins.disabled = rotations
	var note: Label = %ModeNote
	note.visible = rotations
	if rotations:
		note.text = "Rotations : les orbites se remplissent seules, %d tuiles a peindre au lieu de %d." % [
				Symmetry.surface_work_count() + Symmetry.wall_work_count(),
				Modes.tile_count(_current_mode())]


## Les deux barres flottent SUR la zone de travail : elles ne lui prennent pas de place,
## elles lui disent seulement ou cadrer pour ne rien masquer au depart.
func _apply_margins() -> void:
	var work: Control = %WorkArea
	work.reserved_left = (%Sidebar as Control).size.x
	work.reserved_right = (%Toolbar as Control).size.x


## ⚠ LES TROIS CASES DISENT « MASQUER », PAS « AFFICHER ». Une case a cocher qui commence
## cochee est un mensonge d'ergonomie : elle donne a croire qu'on ajoute quelque chose alors
## qu'on en retire. Les trois retirent une couche -- la grille, le guide, le travail -- et
## elles partent toutes decochees, l'ecran complet.
func _on_work_hidden(pressed: bool) -> void:
	var work: Control = %WorkArea
	work.hide_work = pressed
	work.queue_redraw()
	_announce("Travail masque : le guide seul." if pressed else "Travail revenu.")


func _on_grid_toggled(pressed: bool) -> void:
	var work: Control = %WorkArea
	work.show_grid = not pressed
	work.queue_redraw()
	_announce("Grille masquee : on juge la couleur sans rien par-dessus." if pressed
			else "Grille revenue.")


## L'APERCU EN JEU. Le guide est un banc d'epreuve -- lacs d'une case, pinacles isoles ; il
## ne dira jamais si le tileset REND bien. Ce panneau montre les memes tuiles sur un petit
## decor ordinaire. ⚠ Il n'invente rien : chaque case y emprunte, par index ou par role, ce
## qui est peint dans le guide.
## Les deux decors. ⚠ CE N'EST PAS UN REGLAGE DU PRODUIT : ils repondent a deux questions
## differentes -- « comment ca rend » et « est-ce que rien ne manque » -- et ni l'un ni
## l'autre ne change d'un iota ce qui sort a l'export.
func _fill_decors() -> void:
	var choice: OptionButton = %DecorChoice
	choice.clear()
	choice.add_item("Decor : la colline")
	choice.set_item_metadata(0, "colline")
	choice.add_item("Decor : la preuve")
	choice.set_item_metadata(1, "preuve")
	choice.selected = 0


func _on_decor_selected(_index: int) -> void:
	_apply_decor()


func _apply_decor() -> void:
	var choice: OptionButton = %DecorChoice
	var wanted: String = String(choice.get_item_metadata(choice.selected))
	var panel: Control = %PreviewPanel
	if wanted == "preuve":
		panel.set_scene(ProofScene.relief())
		_announce("La planche de preuve : un ilot par index, aucun ne manque.")
	else:
		panel.set_scene(HeightMask.read(panel.SCENE_PATH))
		_announce("La colline : comment vos tuiles rendent dans un decor ordinaire.")


func _on_preview_toggled(pressed: bool) -> void:
	var panel: Control = %PreviewPanel
	panel.visible = pressed
	if pressed:
		panel.mark_dirty()
	_announce("Apercu en jeu : vos tuiles dans un decor ordinaire." if pressed
			else "Retour au guide seul.")


## ⚠ MASQUER LE GUIDE NE TOUCHE A RIEN DE CE QUI SORT. C'est une facon de regarder, au meme
## titre que la grille : le tileset exporte est le meme, coche ou non.
func _on_assembled_toggled(pressed: bool) -> void:
	var work: Control = %WorkArea
	work.assembled = pressed
	work.queue_redraw()
	_announce("Guide masque : vos tuiles seules." if pressed else "Guide revenu.")


## LE RELEVE DE LA CASE SURVOLEE. Savoir QUELLE tuile on s'apprete a peindre est utile en
## soi ; et ca donne de quoi designer une case sans la decrire -- « (12, 7), index 117 ».
##
## ⚠ ON DECRIT L'INDEX PAR SES BITS, pas par son numero seul. « 117 » ne dit rien ;
## « N+E+S+SW+W » dit la forme, donc ce qu'il faut dessiner.
func _on_hover_changed(cell: Vector2i) -> void:
	var label: Label = %HoverLabel
	if cell.x < 0:
		label.text = "survolez une case"
		return
	var work: Control = %WorkArea
	var roles: Dictionary = work.wall_roles()
	if roles.has(cell):
		label.text = "(%d, %d)  robe : %s" % [cell.x, cell.y, Walls.role_name(roles[cell])]
		return
	var indices: Dictionary = work.surface_index()
	if indices.has(cell):
		var index: int = int(indices[cell])
		label.text = "(%d, %d)  index %d = %s" % [cell.x, cell.y, index,
				BlobIndex.describe(index)]
		return
	label.text = "(%d, %d)  la plaine : rien a peindre" % [cell.x, cell.y]


func _on_fit_pressed() -> void:
	(%WorkArea as Control).fit()


# --- Ouvrir, enregistrer, exporter -----------------------------------------

## Les trois selecteurs de fichiers, fabriques une fois. On demande le selecteur NATIF :
## c'est un outil de bureau, et celui du systeme connait les dossiers de l'utilisateur.
func _build_dialogs() -> void:
	var work_filter: PackedStringArray = PackedStringArray(
			["*.%s ; Travail AbsoluTiles" % WorkIO.EXTENSION])
	_open_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_FILE, "Ouvrir un travail", work_filter)
	_open_dialog.file_selected.connect(_on_open_chosen)
	_save_dialog = _make_dialog(FileDialog.FILE_MODE_SAVE_FILE, "Enregistrer le travail", work_filter)
	_save_dialog.file_selected.connect(_write_work)
	_export_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR, "Exporter le tileset",
			PackedStringArray())
	_export_dialog.dir_selected.connect(_on_export_chosen)


func _make_dialog(mode: FileDialog.FileMode, title: String,
		filters: PackedStringArray) -> FileDialog:
	var dialog: FileDialog = FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.title = title
	dialog.filters = filters
	dialog.use_native_dialog = true
	add_child(dialog)
	return dialog


func _on_open_pressed() -> void:
	_open_dialog.popup_centered_ratio(0.6)


## ⚠ ON LIT EN DEUX TEMPS. Le fichier dit dans quel paysage et a quelle taille il a ete
## peint ; il faut charger ce paysage AVANT de pouvoir y reposer quoi que ce soit. D'ou
## l'en-tete d'abord, le guide ensuite, les tuiles en dernier.
func _on_open_chosen(path: String) -> void:
	var header: Dictionary = WorkIO.peek(path)
	if int(header["error"]) != OK:
		_announce("Ce fichier n'est pas un travail AbsoluTiles.")
		return
	_select_metadata(%ModeChoice, header["mode"])
	_select_metadata(%SizeChoice, int(header["resolution"]))
	_load_current_mode()

	var report: Dictionary = WorkIO.read(path, _heights)
	if int(report["error"]) != OK:
		_announce("Fichier illisible.")
		return
	_painting = report["painting"]
	(%WorkArea as Control).show_guide(_heights, _painting)
	(%PreviewPanel as Control).show_guide(_heights, _painting)
	_work_path = path
	_refresh_counters()

	var orphans: int = PackedStringArray(report["unplaced"]).size()
	if orphans > 0:
		_announce("%d tuiles reposees ; %d n'ont pas de place dans ce paysage."
				% [int(report["placed"]), orphans])
	else:
		_announce("%d tuiles reposees." % int(report["placed"]))


func _on_save_pressed() -> void:
	if _work_path != "":
		_write_work(_work_path)
		return
	_save_dialog.current_file = "%s.%s" % [_current_mode(), WorkIO.EXTENSION]
	_save_dialog.popup_centered_ratio(0.6)


func _write_work(path: String) -> void:
	if _painting == null:
		return
	if WorkIO.write(path, _painting, _heights, _current_mode()) != OK:
		_announce("Enregistrement impossible.")
		return
	_work_path = path
	(%WorkHint as Label).text = path.get_file()
	_announce("Enregistre dans %s" % path.get_file())


func _on_export_pressed() -> void:
	_export_dialog.popup_centered_ratio(0.6)


func _on_export_chosen(folder: String) -> void:
	if _painting == null:
		return
	var basename: String = _work_path.get_file().get_basename()
	if basename == "":
		basename = String(_current_mode())
	var report: Dictionary = TilesetPNG.write(folder, basename, _painting, _heights,
			_current_mode())
	if int(report["error"]) == ERR_UNAVAILABLE:
		# Le bouton est cense etre grise ; si on arrive ici, c'est qu'il ne l'etait pas.
		var left: int = report["missing_surface"].size() + report["missing_wall"].size()
		_announce("Il manque %d tuiles : rien n'est ecrit." % left)
		return
	if int(report["error"]) != OK:
		_announce("Export impossible dans ce dossier.")
		return
	_announce("Exporte dans %s : deux planches et leur manifeste." % folder.get_file())


## Choisit dans une liste deroulante l'entree qui porte [param value]. Sans effet si elle
## n'y est pas -- un fichier peut nommer un mode que cette version ne connait plus.
func _select_metadata(choice: OptionButton, value: Variant) -> void:
	for index: int in range(choice.item_count):
		if choice.get_item_metadata(index) == value:
			choice.selected = index
			return


func _announce(text: String) -> void:
	(%Ticker as Label).text = text
	_elapsed = 0.0


## ⚠ CTRL+S EST UN REFLEXE, PAS UN CONFORT. Un outil de dessin qui ne le prend pas se fait
## perdre du travail par la main de l'utilisateur lui-meme.
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or not key.ctrl_pressed:
		return
	if key.keycode == KEY_S:
		_on_save_pressed()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_O:
		_on_open_pressed()
		get_viewport().set_input_as_handled()


## Recalcule les deux jauges depuis le noyau. Aucune regle n'est reecrite ici.
func _refresh_counters() -> void:
	if _painting == null:
		return
	var work: Control = %WorkArea
	var surface: Dictionary = Variants.resolve_indexed(work.surface_index(), work.painted_surface_cells())
	# On repasse par les roles deja rassembles : les recalculer a chaque coup de crayon
	# relirait tout le relief pour rien.
	var walls: Dictionary = Walls.resolve_roles(work.wall_roles(), work.painted_wall_cells())
	var surface_done: int = surface["delivered"].size()
	var surface_total: int = BlobIndex.CANONICAL_INDICES.size()
	var wall_done: int = walls["delivered"].size()
	var wall_total: int = Walls.ALL_ROLES.size()

	(%SurfaceLabel as Label).text = "Surfaces     %d / %d" % [surface_done, surface_total]
	(%SurfaceBar as ProgressBar).max_value = float(surface_total)
	(%SurfaceBar as ProgressBar).value = float(surface_done)
	(%WallLabel as Label).text = "Falaises     %d / %d" % [wall_done, wall_total]
	(%WallBar as ProgressBar).max_value = float(wall_total)
	(%WallBar as ProgressBar).value = float(wall_done)

	var complete: bool = bool(surface["is_exportable"]) and bool(walls["is_exportable"])
	var export_button: Button = %ExportButton
	export_button.disabled = not complete
	var left: int = (surface_total - surface_done) + (wall_total - wall_done)
	(%RemainingLabel as Label).text = "pret a exporter" if complete else "%d tuiles a peindre" % left

	# ⚠ LA TAILLE DES PIXELS SE CHOISIT AVANT DE DESSINER, pas apres : en changer
	# rejetterait tout ce qui est peint. Le choix se ferme au premier pixel pose.
	var touched: bool = not _painting.painted_cells().is_empty()
	(%SizeChoice as OptionButton).disabled = touched
