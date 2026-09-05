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
const Delivery := preload("res://core/delivery.gd")
const Walls := preload("res://core/walls.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Symmetry := preload("res://core/symmetry.gd")
const Families := preload("res://core/families.gd")
const WorkIO := preload("res://core/work_io.gd")
const TilesetPNG := preload("res://exporters/tileset_png.gd")
const MassifTileset := preload("res://exporters/massif_tileset.gd")
const PackedPNG := preload("res://exporters/packed_png.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Examples := preload("res://core/examples.gd")
const PluginInstall := preload("res://core/plugin_install.gd")
const MANUAL := preload("res://ui/manual.gd")
const Trial := preload("res://exporters/trial_tileset.gd")
const MassifTrial := preload("res://exporters/massif_trial.gd")

## Part de l'ecran occupee par la fenetre au lancement.
const WINDOW_SCREEN_SHARE: float = 0.95

## Le bandeau du haut, qui deroule la charte ET des conseils.
##
## ⚠ IL DIT QUELQUE CHOSE DE VRAI A CHAQUE PHRASE, et c'est ce qui l'autorise a etre la
## seule fantaisie du logiciel. Une banniere qui se contenterait de vanter le produit serait
## du bruit ; celle-ci apprend a s'en servir pendant qu'on regarde ailleurs.
##
## ⚠ ET ON PEUT CLIQUER DESSUS. Un conseil qui passe en six secondes est un conseil qu'on
## rate : la zone entiere ouvre le mode d'emploi, ou tout est ecrit et rien ne defile.
const PROMISES: Array[String] = [
	"Le guide est prouve complet avant que vous ne posiez un pixel.",
	"On dessine, on ne configure pas.",
	"Un seul passage, du debut a la fin. Pas de boucle essai-export-correction.",
	"Rien n'est fabrique a votre place : ni composition, ni miroir, ni IA.",
	"L'exactitude se prouve, elle ne se promet pas.",
	"Ce qui n'est pas garanti est interdit : le crayon refuse le reste.",
	"47 tuiles de surface, 12 de mur. Le compte est tenu a l'ecran.",
	"Une case laissee vierge n'est pas utilisee. Peindre, c'est choisir.",
	"Cliquez ici : le mode d'emploi s'ouvre en grand.",
	"Clic gauche pose, clic droit efface. Ctrl+Z defait un trait entier.",
	"Huit outils, une touche chacune : P B A G L R I E. Les crochets changent la taille.",
	"Contraindre a la tuile : le trait ne deborde plus sur la voisine.",
	"Les cases cerclees d'ambre n'ont pas de jumelle : personne d'autre ne les portera.",
	"Peindre une case en remplit toutes les jumelles : c'est la meme tuile, vue ailleurs.",
	"Le paysage, la taille et le reseau se choisissent AVANT de dessiner.",
	"Installer le plugin : ciblez la racine du projet, celle qui contient project.godot.",
	"Un tileset part avec le plugin -- le votre s'il est complet, son essai sinon.",
	"Dans Godot : bouton SoluPaint dans la barre du haut, et tout est deja propose.",
]
const PROMISE_SECONDS: float = 6.0

var _heights: PackedStringArray = PackedStringArray()
var _painting: RefCounted = null

## Le fichier de travail en cours, vide tant qu on n a pas enregistre une fois.
var _work_path: String = ""

## Y A-T-IL QUELQUE CHOSE A PERDRE ? ⚠ ET C'EST BIEN LA QUESTION, PAS « A-T-ON PEINT ». Un
## travail peint puis enregistre ne se perd pas en recommencant : il est sur le disque, et se
## rouvre. Demander confirmation la-dessus apprendrait a cliquer « oui » sans lire, et le jour
## ou la question compte vraiment, elle serait deja devenue un reflexe.
var _dirty: bool = false

## Recommencer une fois l'enregistrement fini. ⚠ IL FAUT UN DRAPEAU PARCE QUE LA BOITE DE
## FICHIER EST ASYNCHRONE : « Enregistrer, puis recommencer » ne peut pas recommencer tout de
## suite quand le travail n'a pas encore de nom -- il faut attendre le choix, et NE PAS
## recommencer si l'on annule.
var _reset_after_save: bool = false
var _new_dialog: ConfirmationDialog = null
var _open_dialog: FileDialog = null
var _manual: Control = null
var _save_dialog: FileDialog = null
var _export_dialog: FileDialog = null
var _packed_dialog: FileDialog = null
var _plugin_dialog: FileDialog = null
var _trial_dialog: FileDialog = null
var _promise: int = 0
var _elapsed: float = PROMISE_SECONDS


func _ready() -> void:
	# ⚠ LA VERSION SE LIT DANS project.godot, elle ne se recopie pas ici. Deux endroits, et
	# ils finissent toujours par se contredire.
	(%Version as Label).text = String(ProjectSettings.get_setting("application/config/version", "?"))
	_apply_window_size()
	_fill_modes()
	_fill_resolutions()
	_fill_families()
	_fill_styles()
	_fill_inks()
	var work: Control = %WorkArea
	work.painting_changed.connect(_refresh_counters)
	work.painting_changed.connect(_on_painting_changed)
	(%NewButton as Button).pressed.connect(_on_new_pressed)
	work.loading_progress.connect(_on_loading_progress)
	work.hover_changed.connect(_on_hover_changed)
	var mode_choice: OptionButton = %ModeChoice
	mode_choice.item_selected.connect(_on_mode_selected)
	var size_choice: OptionButton = %SizeChoice
	size_choice.item_selected.connect(_on_resolution_selected)
	(%FamilyChoice as OptionButton).item_selected.connect(_on_family_selected)
	# ⚠ UNE LISTE A UNE SEULE ENTREE N'EST PAS UN CHOIX, C'EST UN DECOR. On dessine, on ne
	# configure pas (charte, regle 1) : la ligne entiere s'efface tant qu'il n'y a qu'un
	# reseau, et reparaitra d'elle-meme le jour ou un second existera.
	if Families.ids().size() < 2:
		var row: Node = (%FamilyChoice as Control).get_parent()
		if row is Control:
			(row as Control).visible = false
	var pencil: ColorPickerButton = %PencilColor
	pencil.color_changed.connect(_on_pencil_changed)
	for swatch: Node in %Swatches.get_children():
		var button: Button = swatch as Button
		if button != null:
			button.pressed.connect(_on_swatch_pressed.bind(button))
	(%StyleChoice as OptionButton).item_selected.connect(_on_style_selected)
	(%InkChoice as OptionButton).item_selected.connect(_on_style_selected)
	(%RotationsCheck as CheckBox).toggled.connect(_on_twins_toggled)
	(%LockCheck as CheckBox).toggled.connect(_on_lock_toggled)
	for child: Node in %ToolGrid.get_children():
		var tool_button: Button = child as Button
		if tool_button != null and tool_button.has_meta("tool"):
			tool_button.toggled.connect(_on_tool_toggled.bind(tool_button))
	for child: Node in %BrushRow.get_children():
		var size_button: Button = child as Button
		if size_button != null and size_button.has_meta("size"):
			size_button.toggled.connect(_on_size_toggled.bind(size_button))
	work.pencil_picked.connect(_on_pencil_picked)
	(%FitButton as Button).pressed.connect(_on_fit_pressed)
	# ⚠ LE MODE D'EMPLOI SE POSE EN DERNIER, donc par-dessus tout le reste. Ajoute plus
	# tot, il passerait sous la zone de travail et le clic ne l'atteindrait jamais.
	_manual = MANUAL.new()
	add_child(_manual)
	var ticker: Label = %Ticker
	ticker.mouse_filter = Control.MOUSE_FILTER_STOP
	ticker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ticker.tooltip_text = "Mode d'emploi"
	ticker.gui_input.connect(_on_ticker_input)
	(%GridCheck as CheckBox).toggled.connect(_on_grid_toggled)
	(%AssembledCheck as CheckBox).toggled.connect(_on_assembled_toggled)
	(%WorkCheck as CheckBox).toggled.connect(_on_work_hidden)
	work.painting_changed.connect((%NeighboursPanel as Control).mark_dirty)
	(%ExportButton as Button).pressed.connect(_on_export_pressed)
	(%PackedButton as Button).pressed.connect(_on_packed_pressed)
	(%OpenButton as Button).pressed.connect(_on_open_pressed)
	(%SaveButton as Button).pressed.connect(_on_save_pressed)
	(%InstallPluginButton as Button).pressed.connect(_on_install_plugin_pressed)
	(%TrialButton as Button).pressed.connect(_on_trial_pressed)
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
	print("SoluTiles : fenetre %dx%d, ecran utile %dx%d" % [
			window.size.x, window.size.y, usable.size.x, usable.size.y])


func _fill_modes() -> void:
	var choice: OptionButton = %ModeChoice
	choice.clear()
	var first_open: int = -1
	for id: StringName in Modes.ids():
		# ⚠ UN MODE FERME NE FIGURE PLUS DU TOUT, IL N'EST PLUS GRISE. Un guide absent se
		# grise -- c'est un accident, et le dire aide. Un mode FERME, lui, appartient a un
		# modele qui n'existe plus : le montrer barre ferait chercher a l'acheteur ce qu'il
		# a rate, alors qu'il n'y a rien a rater.
		if Modes.is_closed(id):
			continue
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
##   la TECHNIQUE -- d'ou vient le fond : de notre dessin, ou d'un vrai tileset.
##   le STYLE     -- de quoi notre dessin est fait : des aplats, ou des traits.
## Les deux derniers sont des aides a la vue : rien de ce qui sort n en depend.
##
## ⚠ ET « BANC SATYRON » A DISPARU AUSSI -- decision utilisateur : le libelle ne dit rien a
## personne. C'etait le guide assemble avec un VRAI tileset achete, lu chez lui, pour comparer
## notre dessin a du trait de metier ; il ne s'ouvrait que sur la machine ou ce projet est
## installe, et restait grise partout ailleurs. Une entree grisee ne dit « ceci viendra » que
## si l'on sait ce qu'est « ceci » -- ici l'acheteur lisait un nom propre qui ne le concerne
## pas. Le code de rendu reste (`render/guide_render_job.gd`, `render/satyron_tiles.gd`) : il
## sert de reference quand un doute survient sur une falaise, et se rappelle d'un outil.
##
## ⚠ « UTILISABLE » A DISPARU DE CETTE LISTE, ET C'EST UN GAIN. Il n'etait rien d'autre que
## le representatif SANS SES MARQUES -- ni marqueurs, ni traits epaissis. Or l'epaississement
## est lui-meme une marque de travail : la levre grossie et le trait large n'existent pas
## pour etre beaux, ils existent pour rendre la specification lisible. Les masquer tous
## ensemble redonne exactement l'ancien « utilisable ». Une entree de liste est donc devenue
## une case a cocher, qui rejoint la famille des « Masquer » -- rien n'est perdu.
func _fill_styles() -> void:
	var choice: OptionButton = %StyleChoice
	choice.clear()
	choice.add_item("Notre dessin")
	choice.set_item_metadata(0, "")
	# ⚠ UN EXEMPLE N'EST PAS UN STYLE, C'EST UNE PREUVE. « Notre dessin » est la SPECIFICATION :
	# calculee depuis le relief, elle ne peut pas mentir sur ce que le guide contient -- et elle
	# a donc toujours l'air juste. Un exemple, lui, est du VRAI trait remonte en paysage : c'est
	# la seule vue ou l'on voit ce que l'outil rend vraiment. Le cisaillement du massif 21 a ete
	# releve comme ca, et par aucun autre moyen.
	#
	# ⚠ ET UN EXEMPLE ABSENT SE MONTRE QUAND MEME, GRISE. Une place vide dit « ceci viendra » ;
	# une absence ne dit rien, et l'acheteur ne cherche pas ce qu'il ne voit pas.
	for id: StringName in Examples.ids():
		var at: int = choice.item_count
		choice.add_item("%s -- %s" % [Examples.label(id), Examples.note(id)])
		choice.set_item_metadata(at, id)
		choice.set_item_disabled(at, not Examples.is_available(id))
	choice.select(0)


func _fill_inks() -> void:
	var choice: OptionButton = %InkChoice
	choice.clear()
	choice.add_item("Peint")
	choice.set_item_metadata(0, GuideImage.Ink.PAINTED)
	choice.add_item("Fil de fer")
	choice.set_item_metadata(1, GuideImage.Ink.WIREFRAME)
	# ⚠ LE CONTOUR PROUVE N'EST PAS UN STYLE, C'EST UN AUTRE MODELE -- et il est dans la meme
	# liste pour qu'on puisse les comparer a l'ecran, ce qu'aucun chiffre ne remplace.
	choice.add_item("Contour prouve")
	choice.set_item_metadata(2, GuideImage.Ink.CONTOUR)
	choice.select(0)


func _on_style_selected(_index: int) -> void:
	_apply_background_style()


func _apply_background_style() -> void:
	var picked: Dictionary = _style_pick()
	# ⚠ L'ENCRE N'A PAS DE SENS SUR UN TRAIT PEINT : ce ne sont ni nos aplats ni nos traits, ce
	# sont des pixels poses a la main. On ferme le choix plutot que de l'ignorer.
	(%InkChoice as OptionButton).disabled = StringName(picked["example"]) != &"" 			or int(picked["purpose"]) == GuideImage.Purpose.EXAMPLE
	(%WorkArea as Control).set_guide_style(picked["ink"], picked["purpose"], picked["example"])


## CE QUE LES DEUX LISTES DISENT, LU UNE SEULE FOIS.
##
## ⚠ DEUX ENDROITS QUI RESOLVENT LE MEME CHOIX FINISSENT PAR SE CONTREDIRE, et ca vient d'etre
## paye : `_load_current_mode` lisait la metadonnee et l'affectait directement. Depuis qu'elle
## designe un EXEMPLE par son nom, il ecrivait un `StringName` dans un champ d'enumeration --
## coerce en silence -- et surtout il PERDAIT l'exemple choisi des qu'on changeait de paysage.
func _style_pick() -> Dictionary:
	var technic: OptionButton = %StyleChoice
	var style: OptionButton = %InkChoice
	var pick: StringName = StringName(technic.get_item_metadata(technic.selected))
	return {
		"ink": style.get_item_metadata(style.selected),
		"purpose": GuideImage.Purpose.REPRESENTATIVE,
		"example": pick if Examples.CATALOGUE.has(pick) else &"",
	}


## La famille de surface choisie. ⚠ ELLE SE CHOISIT AVANT DE DESSINER, comme le paysage et
## la taille des faux pixels : c'est ce qu'on fabrique, pas un reglage.
## LES DEUX FAMILLES DE SURFACE.
##
## ⚠ UNE FAMILLE NE SE CHOISIT QUE SI LE GUIDE LA COUVRE (charte, regle 5). Un guide
## complet en blob 47 n'est PAS automatiquement complet a cheval : la canonicalisation du
## blob jette le contact diagonal isole, dont le reseau dual a besoin. On grise plutot que
## de laisser choisir ce qu'on ne peut pas garantir.
func _fill_families() -> void:
	var choice: OptionButton = %FamilyChoice
	choice.clear()
	for family: StringName in Families.ids():
		choice.add_item("%s -- %s" % [Families.label(family), Families.note(family)])
		choice.set_item_metadata(choice.item_count - 1, family)
	choice.select(0)
	_refresh_family_availability()


## ⚠ LA DISPONIBILITE DEPEND DU GUIDE, donc elle se relit a chaque changement de paysage.
func _refresh_family_availability() -> void:
	var choice: OptionButton = %FamilyChoice
	for index: int in range(choice.item_count):
		var family: StringName = choice.get_item_metadata(index)
		choice.set_item_disabled(index, not Families.is_covered(family, _heights))
	# ⚠ ET SI LE RESEAU CHOISI N EST PAS COUVERT, ON EN PREND UN QUI L EST. Un paysage et un
	# reseau se choisissent separement, mais tous les couples n existent pas : le modele des
	# massifs a son propre guide, et l ancien vocabulaire ne le couvre pas. Laisser la liste
	# sur une entree grisee chargerait un guide avec un reseau qu il ne porte pas -- des
	# compteurs a zero et un crayon qui refuse tout, sans que rien ne le dise.
	if choice.item_count > 0 and choice.is_item_disabled(choice.selected):
		for index2: int in range(choice.item_count):
			if not choice.is_item_disabled(index2):
				choice.selected = index2
				break


func _on_family_selected(_index: int) -> void:
	await _show_then("Changement de reseau", "on recalcule les tuiles")
	_load_current_mode()
	_idle()


func _current_family() -> StringName:
	var choice: OptionButton = %FamilyChoice
	if choice == null or choice.item_count == 0:
		return Families.BY_CELL
	return choice.get_item_metadata(choice.selected)


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
	_refresh_family_availability()
	_painting = Painting.new(_current_resolution())
	var work: Control = %WorkArea
	work.guide_family = _current_family()
	work.pencil = (%PencilColor as ColorPickerButton).color
	_apply_fill_rules()
	var picked: Dictionary = _style_pick()
	work.guide_ink = picked["ink"]
	work.guide_purpose = picked["purpose"]
	work.guide_example = picked["example"]
	work.show_guide(_heights, _painting)
	(%NeighboursPanel as Control).show_guide(_painting, work.ground_stacks())
	_refresh_counters()


func _on_mode_selected(_index: int) -> void:
	await _show_then("Chargement du paysage", "le relief et ses tuiles")
	_load_current_mode()
	_idle()


func _on_resolution_selected(_index: int) -> void:
	_load_current_mode()


func _on_pencil_changed(color: Color) -> void:
	(%WorkArea as Control).pencil = color


## Le bandeau ouvre le mode d'emploi.
func _on_ticker_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_manual.open()
		(%Ticker as Label).accept_event()


## LES OUTILS : une rangee de boutons exclusifs, et la zone de travail ne connait que le
## choix. Le bouton presse est l'outil ; il n'y a rien d'autre a regler.
func _on_tool_toggled(pressed: bool, button: Button) -> void:
	if not pressed:
		return
	(%WorkArea as Control).tool = int(button.get_meta("tool"))


func _on_size_toggled(pressed: bool, button: Button) -> void:
	if not pressed:
		return
	(%WorkArea as Control).brush_size = int(button.get_meta("size"))


func _on_lock_toggled(pressed: bool) -> void:
	(%WorkArea as Control).lock_to_tile = pressed


## La pipette a pris une couleur : le selecteur la montre, sinon on peindrait avec une
## couleur qu'aucun bouton n'affiche.
func _on_pencil_picked(color: Color) -> void:
	(%PencilColor as ColorPickerButton).color = color


## Presse le bouton d'outil ou de taille qui porte cette valeur. Passer par le bouton
## garde l'ecran et la zone de travail d'accord : c'est lui qui est la source.
func _press_meta(row: Node, key: String, value: int) -> void:
	for child: Node in row.get_children():
		var button: Button = child as Button
		if button != null and button.has_meta(key) and int(button.get_meta(key)) == value:
			button.button_pressed = true
			return


func _on_swatch_pressed(button: Button) -> void:
	if not button.has_meta("color"):
		return
	var color: Color = button.get_meta("color")
	(%PencilColor as ColorPickerButton).color = color
	(%WorkArea as Control).pencil = color


## ⚠ LA VALEUR AFFICHEE EST CELLE DU TRAVAIL REEL : des tuiles dessinees sur des tuiles a
## dessiner. Pas un compte a rebours, pas une animation qui tourne pendant qu'on attend.
## ⚠ ET LE FOND NE FERME PAS UN PANNEAU QUI NE LUI APPARTIENT PAS. Il emet `(1, 1)` des qu'il a
## fini -- le modele des massifs compose d'un coup -- et comme `done == total`, il refermait le
## panneau EN PLEIN MILIEU d'une ouverture de travail, qui l'avait ouvert avant lui et n'avait
## pas fini. Resultat : la barre clignotait et disparaissait, donc il n'y avait PAS de barre a
## l'ouverture (releve par l'utilisateur). Une operation longue GARDE la main jusqu'a son
## annonce ; le fond ne fait que remplir la barre quand personne d'autre ne l'occupe.
func _on_loading_progress(done: int, total: int) -> void:
	if done < total:
		# ⚠ ON NE COMPTE QUE CE QUI SE COMPTE. L'ancien fond se dessinait par etapes, tuile par
		# tuile, et sa jauge disait un vrai avancement. Le modele des massifs compose D'UN SEUL
		# TENANT : annoncer « 0 / 1 tuiles » serait un compteur qui ne mesure rien. On nomme
		# alors l'etat, ce qui est vrai, plutot que d'inventer une fraction.
		_busy("Dessin du fond du guide",
				"%d / %d tuiles" % [done, total] if total > 1 else "le paysage entier",
				done, total)
	elif not _busy_held:
		_idle()


## L'ATTENTE SE MONTRE, PARTOUT OU ELLE EST IMPOSEE.
##
## ⚠ ET C'EST UNE DECISION PRISE CONTRE UNE REGLE DU DOSSIER, DONC ELLE SE JUSTIFIE. Le dossier
## dit : « chercher la cause avant de decorer le symptome -- une barre de progression aurait
## MONTRE l'attente au lieu de la supprimer, et rendu le defaut acceptable ». C'est vrai d'une
## lenteur qu'on peut corriger. Ce n'en est pas une ici : composer une planche ou relire un
## carnet de cinquante-cinq images PREND du temps, et une fenetre figee pendant ce temps est le
## pire des deux maux -- elle ne dit meme pas qu'elle travaille. Decision utilisateur.
##
## ⚠ ET ELLE EST HONNETE : du VRAI avancement la ou il existe (le fond du guide compte ses
## tuiles), un etat NOMME sinon. Jamais un pourcentage invente -- une jauge qui ne mesure pas ce
## qu'elle pretend mesurer est pire que pas de jauge.
## Vrai tant qu'une operation longue tient le panneau. ⚠ SANS LUI, N'IMPORTE QUEL SIGNAL
## D'AVANCEMENT PEUT LE REFERMER SOUS ELLE.
var _busy_held: bool = false


func _busy(title: String, note: String, done: int = 0, total: int = 0) -> void:
	(%LoadingPanel as Control).visible = true
	(%LoadingTitle as Label).text = title
	var bar: ProgressBar = %LoadingBar
	# ⚠ SANS COMPTE CONNU, LA BARRE SE REMPLIT ENTIEREMENT plutot que de rester a zero. Une
	# barre vide se lit comme « bloque » ; une barre pleine sous un etat nomme se lit comme
	# « en cours », ce qui est la verite.
	bar.max_value = float(maxi(total, 1))
	bar.value = float(total if total > 0 else 1) if done <= 0 and total <= 0 else float(done)
	(%LoadingCount as Label).text = note


## ⚠ FERMER, C'EST LACHER SA PRISE -- PAS ETEINDRE L'ECRAN. Le panneau reste tant qu'un fond est
## en cours : sinon la premiere annonce venue le referme sous le travail qui n'a pas fini. C'est
## exactement ce qui supprimait la barre au demarrage -- le fond s'annoncait, puis une autre
## annonce refermait le panneau dans la MEME image, donc il ne se peignait jamais.
func _idle() -> void:
	_busy_held = false
	(%LoadingPanel as Control).visible = (%WorkArea as Control).is_busy()


## ⚠ IL FAUT RENDRE LA MAIN A L'ECRAN POUR QU'IL PEIGNE. Poser le panneau puis travailler dans
## la meme image ne montre rien du tout : Godot ne dessine qu'entre deux images. Un `await` sur
## la suivante coute une image et rend la barre reelle.
func _show_then(title: String, note: String) -> void:
	_busy(title, note)
	_busy_held = true
	await get_tree().process_frame


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
	work.set_fill_rules(rotations)
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
##
## ⚠ ET ELLES NE SONT PLUS QUE TROIS -- « masquer les marques » et « masquer les ombres » ont
## ete retirees (decision utilisateur du 05/09/2026), parce qu'elles ne masquaient plus rien.
## Les deux appartenaient a l'ancien modele : le dessin des massifs ne pose ni marqueur de
## coin ni tiret de rangee, et il n'a pas de lumiere portee a eteindre -- `_background_flat`
## y EST `_background`. Une case qui ne change rien a l'ecran est pire qu'absente : on la
## coche, on ne voit aucun effet, et l'on cherche la panne.
func _on_work_hidden(pressed: bool) -> void:
	var work: Control = %WorkArea
	work.hide_work = pressed
	work.queue_redraw()
	_announce("Travail masque : le guide seul." if pressed else "Travail revenu.")


## MASQUER LA GRILLE — et avec elle, ce qui empechait de juger le rendu.
##
## ⚠ ELLE FAIT DEUX CHOSES, ET LA SECONDE N'ETAIT PAS FAITE. Retirer les traits ne suffisait
## pas : sous un pixel d'ecran par faux pixel, l'echelle libre recoupe la tuile et l'on voyait
## apparaitre des coutures a chaque bordure -- qui etaient la avant, cachees par la grille
## elle-meme. `set_grid` recale donc l'echelle sur un multiple ou un diviseur entier de la
## resolution, et le rendu devient exactement ce qui sortira.
##
## ⚠ ET LE CRAYON RESTE EN MAIN. C'est ce qui a fait supprimer le mode d'apercu qui portait ça
## d'abord (decision utilisateur) : si la nettete ne coute pas la peinture, elle n'a pas a se
## payer d'un mode ou l'on ne peut plus rien faire.
func _on_grid_toggled(pressed: bool) -> void:
	var work: Control = %WorkArea
	work.set_grid(not pressed)
	_announce("Grille masquee : le rendu final, a l'echelle juste." if pressed
			else "Grille revenue.")


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
	(%NeighboursPanel as Control).look_at_cell(cell)
	var label: Label = %HoverLabel
	if cell.x < 0:
		label.text = "survolez une case"
		return
	var work: Control = %WorkArea
	var roles: Dictionary = work.wall_roles()
	if roles.has(cell):
		label.text = "(%d, %d)  robe : %s%s" % [cell.x, cell.y,
				Walls.role_name(roles[cell]), _lonely_note(cell)]
		return
	var indices: Dictionary = work.surface_index()
	if indices.has(cell):
		var index: int = int(indices[cell])
		var family: StringName = _current_family()
		var at: Vector2i = Families.from_storage(family, cell)
		label.text = "(%d, %d)  index %d = %s%s" % [at.x, at.y, index,
				Families.describe(family, index), _lonely_note(cell)]
		return
	label.text = "(%d, %d)  la plaine : rien a peindre" % [cell.x, cell.y]


## ⚠ « SEULE OCCURRENCE » N'EST PAS UN DETAIL. Cette tuile n'apparait qu'ici dans tout le
## guide : aucune jumelle ne la portera, et l'oublier bloque l'export. Le contour ambre de la
## case le dit d'ensemble, ce releve le dit au survol.
func _lonely_note(cell: Vector2i) -> String:
	return "   [SEULE OCCURRENCE]" if (%WorkArea as Control).is_lonely(cell) else ""


func _on_fit_pressed() -> void:
	(%WorkArea as Control).fit()


# --- Ouvrir, enregistrer, exporter -----------------------------------------

## Les trois selecteurs de fichiers, fabriques une fois. On demande le selecteur NATIF :
## c'est un outil de bureau, et celui du systeme connait les dossiers de l'utilisateur.
func _build_dialogs() -> void:
	var work_filter: PackedStringArray = PackedStringArray(
			["*.%s ; Travail SoluTiles" % WorkIO.EXTENSION])
	_open_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_FILE, "Ouvrir un travail", work_filter)
	_open_dialog.file_selected.connect(_on_open_chosen)
	_save_dialog = _make_dialog(FileDialog.FILE_MODE_SAVE_FILE, "Enregistrer le travail", work_filter)
	_save_dialog.file_selected.connect(_write_work)
	# ⚠ ANNULER L'ENREGISTREMENT ANNULE AUSSI CE QUI DEVAIT LE SUIVRE. Sans ca, le drapeau
	# resterait leve et le PROCHAIN enregistrement, sans rapport, effacerait le travail.
	_save_dialog.canceled.connect(_forget_reset)
	_build_new_dialog()
	_export_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR, "Exporter le tileset",
			PackedStringArray())
	_export_dialog.dir_selected.connect(_on_export_chosen)
	_packed_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR,
			"Exporter le tileset packe", PackedStringArray())
	_packed_dialog.dir_selected.connect(_on_packed_chosen)
	_plugin_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR,
			"Choisir un projet Godot", PackedStringArray())
	_plugin_dialog.dir_selected.connect(_on_plugin_folder_chosen)
	_trial_dialog = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR,
			"Ou ecrire l essai", PackedStringArray())
	_trial_dialog.dir_selected.connect(_on_trial_folder_chosen)


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


## LA BOITE DE « NOUVEAU PROJET » — trois issues, dans l'ordre ou l'on veut les lire.
##
## ⚠ LA PLUS SURE EN PREMIER, ET C'EST LA REGLE DES REFUS DU DOSSIER : chaque condition dit ce
## qui manque puis ce qu'il faut faire, dans l'ordre ou on les remplit. Ici : enregistrer, puis
## recommencer ; recommencer sans enregistrer ; ne rien faire. Une boite qui mettrait « perdre »
## sous le pouce ferait perdre du travail a la main de l'utilisateur lui-meme.
func _build_new_dialog() -> void:
	_new_dialog = ConfirmationDialog.new()
	_new_dialog.title = "Nouveau projet"
	_new_dialog.ok_button_text = "Enregistrer, puis recommencer"
	_new_dialog.get_cancel_button().text = "Annuler"
	_new_dialog.add_button("Recommencer sans enregistrer", false, "jeter")
	_new_dialog.confirmed.connect(_on_new_saved_first)
	_new_dialog.custom_action.connect(_on_new_discarded)
	add_child(_new_dialog)


func _on_painting_changed() -> void:
	_dirty = true


func _forget_reset() -> void:
	_reset_after_save = false


## QUAND FAUT-IL DEMANDER ? Peint ET pas enregistre depuis. Rien d'autre.
##
## ⚠ ET C'EST UNE FONCTION A PART PARCE QU'AUCUN BANC NE SAIT MONTER L'EDITEUR ENTIER. La suite
## ne mesure jamais l'interface complete -- l'editeur charge un guide, compose un fond, et son
## `_ready` demande une image pour tourner. La regle, elle, se mesure sans rien monter, et c'est
## elle qui peut regresser en silence dans les deux sens : ne plus jamais demander fait perdre
## du travail ; demander toujours apprend a cliquer « oui » sans lire, et le jour ou la question
## compte, elle est deja devenue un reflexe.
static func must_confirm(painted: int, dirty: bool) -> bool:
	return dirty and painted > 0


## ⚠ LA QUESTION NE SE POSE QUE S'IL Y A QUELQUE CHOSE A PERDRE. Rien de peint, ou tout deja
## enregistre : on recommence sans rien demander. C'est la regle 1 de la charte appliquee a une
## boite de dialogue -- une confirmation qui ne protege de rien n'est pas une securite, c'est
## une gene, et elle use la seule confirmation qui compte.
func _on_new_pressed() -> void:
	if _painting == null or not must_confirm(_painting.painted_cells().size(), _dirty):
		_new_project()
		return
	var count: int = _painting.painted_cells().size()
	# ⚠ ON DIT COMBIEN, PAS « DES MODIFICATIONS ». Un nombre se pese ; « des modifications » se
	# lit sans rien apprendre, et c'est ce qui fait cliquer sans lire.
	var where: String = ("Le dernier enregistrement est %s." % _work_path.get_file()
			if _work_path != "" else "Ce travail n'a jamais ete enregistre.")
	_new_dialog.dialog_text = ("%d cases peintes ne sont pas enregistrees.
%s"
			% [count, where])
	_new_dialog.popup_centered()


func _on_new_saved_first() -> void:
	_reset_after_save = true
	_on_save_pressed()


func _on_new_discarded(action: StringName) -> void:
	if action != &"jeter":
		return
	_new_dialog.hide()
	_new_project()


## REPARTIR D'UN GUIDE VIERGE. ⚠ ET CA ROUVRE LES CHOIX QUE LE PREMIER PIXEL AVAIT FERMES : la
## taille des faux pixels et le reseau se referment au premier pixel parce qu'en changer
## rejetterait tout le travail. Sans « nouveau projet », le seul moyen d'en changer d'avis
## etait de relancer le logiciel.
func _new_project() -> void:
	_work_path = ""
	(%WorkHint as Label).text = "Rien d'enregistre pour l'instant."
	_load_current_mode()
	_dirty = false
	_announce("Nouveau projet : le guide est vierge, et les choix sont rouverts.")


func _on_open_pressed() -> void:
	_open_dialog.popup_centered_ratio(0.6)


## ⚠ ON LIT EN DEUX TEMPS. Le fichier dit dans quel paysage et a quelle taille il a ete
## peint ; il faut charger ce paysage AVANT de pouvoir y reposer quoi que ce soit. D'ou
## l'en-tete d'abord, le guide ensuite, les tuiles en dernier.
func _on_open_chosen(path: String) -> void:
	# ⚠ TROIS ETAPES REELLES, PAS UN ETAT FIGE. Ouvrir lit en DEUX TEMPS -- le fichier dit dans
	# quel paysage il a ete peint, et il faut charger ce paysage AVANT de pouvoir y reposer quoi
	# que ce soit -- puis il faut remonter l'ecran. Ce sont trois attentes distinctes, de durees
	# tres differentes : les nommer vaut mieux qu'un pourcentage invente.
	await _show_then("Ouverture du travail", "1/3  on lit l'en-tete")
	var header: Dictionary = WorkIO.peek(path)
	if int(header["error"]) != OK:
		_announce("Ce fichier n'est pas un travail SoluTiles.")
		return
	_select_metadata(%ModeChoice, header["mode"])
	_select_metadata(%SizeChoice, int(header["resolution"]))
	_select_metadata(%FamilyChoice, header["family"])
	_busy("Ouverture du travail", "2/3  le paysage : %s" % header["mode"], 1, 3)
	await get_tree().process_frame
	_load_current_mode()

	_busy("Ouverture du travail", "3/3  on repose les tuiles", 2, 3)
	await get_tree().process_frame
	var report: Dictionary = WorkIO.read(path, _heights)
	if int(report["error"]) != OK:
		_announce("Fichier illisible.")
		return
	_painting = report["painting"]
	(%WorkArea as Control).show_guide(_heights, _painting)
	(%NeighboursPanel as Control).show_guide(_painting,
			(%WorkArea as Control).ground_stacks())
	_work_path = path
	_dirty = false
	_refresh_counters()

	var orphans: int = PackedStringArray(report["unplaced"]).size()
	if orphans > 0:
		_announce("%d tuiles reposees ; %d n'ont pas de place dans ce paysage."
				% [int(report["placed"]), orphans])
	else:
		_announce("%d tuiles reposees." % int(report["placed"]))
	_idle()


func _on_save_pressed() -> void:
	if _work_path != "":
		_write_work(_work_path)
		return
	_save_dialog.current_file = "%s.%s" % [_current_mode(), WorkIO.EXTENSION]
	_save_dialog.popup_centered_ratio(0.6)


func _write_work(path: String) -> void:
	if _painting == null:
		return
	if WorkIO.write(path, _painting, _heights, _current_mode(), _current_family()) != OK:
		_announce("Enregistrement impossible.")
		return
	_work_path = path
	_dirty = false
	(%WorkHint as Label).text = path.get_file()
	_announce("Enregistre dans %s" % path.get_file())
	if _reset_after_save:
		_reset_after_save = false
		_new_project()


func _on_export_pressed() -> void:
	_export_dialog.popup_centered_ratio(0.6)


func _on_export_chosen(folder: String) -> void:
	await _show_then("Export du tileset", "planche et manifeste")
	if _painting == null:
		return
	var basename: String = _work_path.get_file().get_basename()
	if basename == "":
		basename = String(_current_mode())
	# ⚠ LE MODELE DES MASSIFS A SON EXPORTATEUR, ET IL NE LIVRE QU'UNE PLANCHE. Faire passer
	# son vocabulaire par l'ancien -- deux feuilles, surfaces d'un cote, robes de l'autre --
	# demanderait de couper en deux un massif qui se dessine entier.
	if _current_family() == Families.BY_MASSIF:
		var done: Dictionary = MassifTileset.write(_painting, _heights, _current_mode(),
				folder, basename)
		if String(done["error"]) != "":
			_announce("Rien n'est ecrit : %s." % String(done["error"]))
			return
		_announce("Exporte dans %s : une planche et son manifeste." % folder.get_file())
		return
	var report: Dictionary = TilesetPNG.write(folder, basename, _painting, _heights,
			_current_mode(), _current_family())
	if int(report["error"]) == ERR_UNAVAILABLE:
		# Le bouton est cense etre grise ; si on arrive ici, c'est qu'il ne l'etait pas.
		var left: int = report["missing_surface"].size() + report["missing_wall"].size()
		_announce("Il manque %d tuiles : rien n'est ecrit." % left)
		return
	if int(report["error"]) != OK:
		_announce("Export impossible dans ce dossier.")
		return
	_announce("Exporte dans %s : deux planches et leur manifeste." % folder.get_file())


## ⚠ LA FEUILLE PACKED EST POUR LA VENTE, PAS POUR LE MOTEUR, et le bouton doit le dire.
## L'export moteur livre un CONTRAT -- deux planches et la regle de pose ; celui-ci livre une
## seule image serree et sa legende, ce qu'attend une place de marche. Les deux sortent des
## MEMES pixels : si l'un des deux differait, l'un des deux mentirait.
func _on_packed_pressed() -> void:
	_packed_dialog.popup_centered_ratio(0.6)


func _on_packed_chosen(folder: String) -> void:
	await _show_then("Export du tileset packe", "une seule image, et sa legende")
	if _painting == null:
		return
	var basename: String = _work_path.get_file().get_basename()
	if basename == "":
		basename = String(_current_mode())
	var report: Dictionary = PackedPNG.write(folder, basename, _painting, _heights,
			_current_mode(), _current_family())
	if int(report["error"]) == ERR_UNAVAILABLE:
		# ⚠ LES DEUX RAPPORTS NE NOMMENT PAS LEUR MANQUE PAREIL : l ancien le coupe en deux
		# familles, celui des massifs n en a qu une. On lit celle qui existe.
		var left2: int = 0
		if report.has("missing"):
			left2 = int(report["missing"].size())
		else:
			left2 = report["missing_surface"].size() + report["missing_wall"].size()
		_announce("Il manque %d tuiles : rien n'est ecrit." % left2)
		return
	if int(report["error"]) != OK:
		_announce("Export impossible dans ce dossier.")
		return
	_announce("Feuille packed ecrite dans %s, avec sa legende." % folder.get_file())


# --- Installer le plugin moteur ---------------------------------------------

## ⚠ CE BOUTON EST POUR L'ACHETEUR, PAS POUR NOUS. Il ferme le seul geste manuel qui restait
## entre « j'ai peint mon tileset » et « je pose mon monde » : trouver le dossier `addons/`
## d'un projet Godot et n'y rien oublier.
func _on_install_plugin_pressed() -> void:
	_plugin_dialog.popup_centered_ratio(0.6)


## ⚠ L'ESSAI EXISTE PARCE QUE L'EXPORT REFUSE UNE FEUILLE INCOMPLETE, et qu'il a raison de
## le faire. Tant qu'aucun pixel n'est peint, le game dev n'a rien a poser : il devait donc
## croire sur parole. Le dessin du guide, lui, est complet par construction et entierement a
## nous -- on le livre tel quel, et la chaine entiere devient essayable en un clic.
##
## ⚠ CE N'EST PAS DE L'ART, ET LE BOUTON NE FAIT PAS SEMBLANT. C'est un dessin de
## specification : il sert a poser un monde qui se tient, pas a habiller un jeu.
func _on_trial_pressed() -> void:
	_trial_dialog.popup_centered_ratio(0.6)


func _on_trial_folder_chosen(folder: String) -> void:
	await _show_then("Ecriture de l'essai", "notre propre trace, livree comme tileset")
	# ⚠ L'ESSAI SUIT LE MODELE, comme l'export : celui des massifs livre une planche unique et
	# un manifeste v9, l'ancien deux planches. Les faire passer par le meme exportateur
	# demanderait de couper en deux un massif qui se dessine entier.
	var report: Dictionary = MassifTrial.write(folder, _current_mode()) \
			if _current_family() == Families.BY_MASSIF \
			else Trial.write(folder, _current_mode(), _current_resolution())
	if _failed(report):
		_announce("L essai n a pas pu s ecrire.")
		return
	var written: PackedStringArray = report["written"]
	_announce("Essai ecrit : %d fichiers dans %s." % [written.size(), folder])
	(%PluginHint as Label).text = \
			"L essai est ecrit. Ouvrez-le avec SoluPaint pour poser un monde tout de suite."


## ⚠ ON REFUSE UN DOSSIER QUI N'EST PAS UN PROJET GODOT (charte, regle 5), et on le DIT.
## Ecrire six fichiers dans les documents de quelqu'un sans que rien ne les lise jamais
## serait pire qu'un refus : ca ressemblerait a une reussite.
func _on_plugin_folder_chosen(folder: String) -> void:
	await _show_then("Installation de SoluPaint", "le plugin et de quoi peindre")
	var report: Dictionary = PluginInstall.install(folder)
	var said: String = PluginInstall.summary(report)
	if int(report["error"]) == OK:
		said += "\n" + _install_tileset(folder)
	_announce(said)
	(%PluginHint as Label).text = said


## ⚠ ON INSTALLE AUSSI DE QUOI PEINDRE, ET C'EST LA MOITIE QUI MANQUAIT. Un plugin pose
## dans un projet vide ne montre rien : il faut un tileset, donc l'exporter, donc savoir
## qu'il existe, ou l'ecrire, et le retrouver ensuite. Quatre gestes entre « j'installe » et
## « je vois quelque chose » -- et chacun est une occasion d'abandonner.
##
## Un seul geste, donc : on cible un projet, et il repart avec le plugin ET un tileset. De
## l'autre cote, SoluPaint le trouve tout seul.
##
## ⚠ ET C'EST LE VOTRE S'IL EST COMPLET, L'ESSAI SINON. Ecrire un travail a moitie peint
## serait un piege : des trous transparents qu'on decouvrirait dans le jeu. L'export refuse
## deja une feuille incomplete -- on ne contourne pas ce refus, on retombe sur l'essai, et
## on le DIT.
func _install_tileset(folder: String) -> String:
	var into: String = folder.path_join("solutiles")
	# ⚠ ET IL SUIT LE MODELE. Le plugin livre lit un manifeste v9 -- celui des massifs ; lui
	# poser une planche de l'ancien modele donnerait un refus la ou l'acheteur attend un monde.
	if _current_family() == Families.BY_MASSIF:
		var ready: Dictionary = MassifTileset.analyse(_painting, _heights)
		if bool(ready["is_exportable"]):
			var done: Dictionary = MassifTileset.write(_painting, _heights, _current_mode(),
					into, "mon_tileset")
			if not _failed(done):
				return "Votre tileset est parti avec, dans solutiles/."
			return "Le plugin est installe, mais votre tileset n'a pas pu s'ecrire."
		var essai: Dictionary = MassifTrial.write(into, _current_mode())
		if not _failed(essai):
			return "L'essai est parti avec, dans solutiles/ : de quoi poser un monde tout " \
					+ "de suite, sans avoir peint."
		return "Le plugin est installe, mais l'essai n'a pas pu s'ecrire."
	var old_ready: Dictionary = TilesetPNG.analyse(_painting, _heights, _current_family())
	if bool(old_ready["is_exportable"]):
		var done2: Dictionary = TilesetPNG.write(into, "mon_tileset", _painting, _heights,
				_current_mode(), _current_family())
		if int(done2["error"]) == OK:
			return "Votre tileset est parti avec, dans solutiles/."
		return "Le plugin est installe, mais votre tileset n'a pas pu s'ecrire."
	var trial: Dictionary = Trial.write(into, _current_mode())
	if int(trial["error"]) == OK:
		return "L'essai est parti avec, dans solutiles/ : de quoi poser un monde tout " \
				+ "de suite, sans avoir peint."
	return "Le plugin est installe, mais l'essai n'a pas pu s'ecrire."


## ⚠ LES DEUX EXPORTATEURS NE DISENT PAS L'ECHEC DE LA MEME FACON : l'ancien rend un `Error`,
## celui des massifs une raison en clair. Une seule fonction pour les lire, plutot que deux
## tests qui finiraient par se contredire.
func _failed(report: Dictionary) -> bool:
	var trouble: Variant = report.get("error", OK)
	return String(trouble) != "" if trouble is String else int(trouble) != OK



## Choisit dans une liste deroulante l'entree qui porte [param value]. Sans effet si elle
## n'y est pas -- un fichier peut nommer un mode que cette version ne connait plus.
func _select_metadata(choice: OptionButton, value: Variant) -> void:
	for index: int in range(choice.item_count):
		if choice.get_item_metadata(index) == value:
			choice.selected = index
			return


func _announce(text: String) -> void:
	# ⚠ ANNONCER UN RESULTAT, C'EST QUE L'ATTENTE EST FINIE. Refermer le panneau ici plutot qu'a
	# chaque sortie de fonction evite l'oubli : ces chemins ont des `return` precoces -- dossier
	# refuse, feuille incomplete, ecriture impossible -- et il suffirait d'en manquer un pour
	# laisser l'ecran bloque sous un panneau qui ne partira plus.
	_idle()
	(%Ticker as Label).text = text
	_elapsed = 0.0


## ⚠ CTRL+S EST UN REFLEXE, PAS UN CONFORT. Un outil de dessin qui ne le prend pas se fait
## perdre du travail par la main de l'utilisateur lui-meme.
## Une lettre par outil, et les crochets pour la taille. ⚠ SANS MODIFICATEUR : Ctrl+S et
## Ctrl+O sont pris au-dessus, et une lettre avec Ctrl ne doit pas changer d'outil.
const TOOL_KEYS: Dictionary = {
	KEY_P: 0, KEY_B: 1, KEY_A: 2, KEY_G: 3, KEY_L: 4, KEY_R: 5, KEY_I: 6, KEY_E: 7,
}


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.ctrl_pressed:
		if key.keycode == KEY_S:
			_on_save_pressed()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_O:
			_on_open_pressed()
			get_viewport().set_input_as_handled()
		return
	if key.alt_pressed or key.meta_pressed:
		return
	if TOOL_KEYS.has(key.keycode):
		_press_meta(%ToolGrid, "tool", int(TOOL_KEYS[key.keycode]))
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_BRACKETLEFT or key.keycode == KEY_BRACKETRIGHT:
		var sizes: Array[int] = (%WorkArea as Control).BRUSH_SIZES
		var at: int = sizes.find((%WorkArea as Control).brush_size)
		at = clampi(at + (1 if key.keycode == KEY_BRACKETRIGHT else -1), 0, sizes.size() - 1)
		_press_meta(%BrushRow, "size", sizes[at])
		get_viewport().set_input_as_handled()


## Recalcule les deux jauges depuis le noyau. Aucune regle n'est reecrite ici.
func _refresh_counters() -> void:
	if _painting == null:
		return
	var work: Control = %WorkArea
	var surface: Dictionary = Delivery.resolve_indexed(work.surface_index(),
			work.painted_surface_cells(), Families.surface_indices(_current_family()))
	# On repasse par les roles deja rassembles : les recalculer a chaque coup de crayon
	# relirait tout le relief pour rien.
	var walls: Dictionary = Walls.resolve_roles(work.wall_roles(), work.painted_wall_cells(),
			Families.wall_roles(_current_family()))
	# ⚠ DANS LE MODELE DES MASSIFS, LES DEUX JAUGES LISENT LA MEME CARTE. Un massif se dessine
	# entier : sa surface et sa jupe sont dans UN vocabulaire, sur UNE planche, dans UN carnet.
	# La coupure entre les deux jauges n est plus celle de deux familles qui s ignorent, c est
	# la BANDE de la tuile -- et elle ne sert qu a dire ou en est le travail.
	if _current_family() == Families.BY_MASSIF:
		walls = Delivery.resolve_indexed(work.surface_index(), work.painted_surface_cells(),
				Families.massif_skirts())
	var surface_done: int = surface["delivered"].size()
	var surface_total: int = Families.surface_tile_count(_current_family())
	var wall_done: int = walls["delivered"].size()
	var wall_total: int = Families.wall_roles(_current_family()).size()
	if _current_family() == Families.BY_MASSIF:
		wall_total = Families.massif_skirts().size()

	(%SurfaceLabel as Label).text = "Surfaces     %d / %d" % [surface_done, surface_total]
	(%SurfaceBar as ProgressBar).max_value = float(surface_total)
	(%SurfaceBar as ProgressBar).value = float(surface_done)
	(%WallLabel as Label).text = "Falaises     %d / %d" % [wall_done, wall_total]
	(%WallBar as ProgressBar).max_value = float(wall_total)
	(%WallBar as ProgressBar).value = float(wall_done)

	var complete: bool = bool(surface["is_exportable"]) and bool(walls["is_exportable"])
	var export_button: Button = %ExportButton
	export_button.disabled = not complete
	# ⚠ MEME REFUS POUR LES DEUX BOUTONS. Une feuille packed a moitie peinte serait pire
	# qu'un export moteur a moitie peint : elle part chez un acheteur.
	(%PackedButton as Button).disabled = not complete
	var left: int = (surface_total - surface_done) + (wall_total - wall_done)
	(%RemainingLabel as Label).text = "pret a exporter" if complete else "%d tuiles a peindre" % left

	# ⚠ LA TAILLE DES PIXELS SE CHOISIT AVANT DE DESSINER, pas apres : en changer
	# rejetterait tout ce qui est peint. Le choix se ferme au premier pixel pose.
	var touched: bool = not _painting.painted_cells().is_empty()
	(%SizeChoice as OptionButton).disabled = touched
	# ⚠ LE RESEAU SE FERME AU PREMIER PIXEL, comme la taille : en changer rejetterait tout
	# ce qui est peint, puisque ce ne sont plus les memes tuiles.
	(%FamilyChoice as OptionButton).disabled = touched
