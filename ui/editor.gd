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
var _promise: int = 0
var _elapsed: float = PROMISE_SECONDS


func _ready() -> void:
	_apply_window_size()
	_fill_modes()
	_fill_resolutions()
	var work: Control = %WorkArea
	work.painting_changed.connect(_refresh_counters)
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
	(%TwinsCheck as CheckBox).toggled.connect(_on_twins_toggled)
	(%FitButton as Button).pressed.connect(_on_fit_pressed)
	(%ExportButton as Button).pressed.connect(_on_export_pressed)
	work.reserved_left = (%Sidebar as Control).size.x
	_load_current_mode()
	# ⚠ ON REPOSE LA TAILLE APRES LA PREMIERE IMAGE. Selon la facon dont on lance -- depuis
	# l'editeur Godot, depuis un raccourci --, la taille demandee dans _ready peut etre
	# ecrasee par celle du projet ou par le placement de l'editeur. On la repose une fois la
	# fenetre reellement ouverte, et on dit ce qu'on a obtenu.
	await get_tree().process_frame
	_apply_window_size()
	work.reserved_left = (%Sidebar as Control).size.x
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
	work.paint_twins = (%TwinsCheck as CheckBox).button_pressed
	work.show_guide(_heights, _painting)
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


func _on_twins_toggled(pressed: bool) -> void:
	(%WorkArea as Control).paint_twins = pressed


func _on_fit_pressed() -> void:
	(%WorkArea as Control).fit()


func _on_export_pressed() -> void:
	# ⚠ IL N'Y A PAS ENCORE D'EXPORTEUR, et on le dit plutot que d'ecrire un fichier a
	# moitie juste. exporters/ est vide tant que les regles d'exportation d'un mode ne
	# sont pas arretees.
	(%Ticker as Label).text = "Aucun exporteur pour l'instant : exporters/ est vide."
	_elapsed = 0.0


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
	export_button.text = "Exporter le tileset" if complete else "Exporter  —  %d tuiles a peindre" % [
			(surface_total - surface_done) + (wall_total - wall_done)]

	# ⚠ LA TAILLE DES PIXELS SE CHOISIT AVANT DE DESSINER, pas apres : en changer
	# rejetterait tout ce qui est peint. Le choix se ferme au premier pixel pose.
	var touched: bool = not _painting.painted_cells().is_empty()
	(%SizeChoice as OptionButton).disabled = touched
