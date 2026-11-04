extends Control

## L'ATELIER DU MODÈLE PAR LES COINS — le guide, le modèle et l'outil de peinture ENSEMBLE (Jordan, 4 novembre 2026 :
## « les trois doivent fonctionner en même temps »). Une seule source : `core/coins/` ; aucune règle ne vit ici.
##   GUIDE   le paysage livré (`guides/coins.txt` : les 35 archétypes, les 261 jonctions). On peint SUR lui : le crayon
##           touche l'archétype qui se voit sous la souris, donc toujours DANS sa forme (le reste n'est pas à peindre et le
##           curseur le dit) ; chaque pixel posé apparaît aussitôt dans TOUTES ses apparitions — toutes les coutures
##           possibles sont sous les yeux. Le survol éclaire l'archétype partout où il est.
##   RELIEF  on sculpte un relief à soi (clic : monter le coin le plus proche ; clic droit : le descendre), rendu avec ses
##           propres archétypes peints : on voit ce qu'on peut faire, à n'importe quelle hauteur.
## Outils : crayon (P), gomme (E, ou clic droit), pot (G), pipette (I) ; Ctrl+Z / Ctrl+Y ; molette : zoom ; bouton du
## milieu (ou Espace) : déplacer ; Tab : guide ↔ relief. Textes à l'écran : anglais (charte du studio).

const Rendu := preload("res://core/coins/rendu.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")
const Travail := preload("res://core/coins/travail.gd")
const Painting := preload("res://core/painting.gd")

const GUIDE := "res://guides/coins.txt"
const TRAVAIL := "user://marching_squares.mqcoins"
const EXPORT := "user://export"

enum Outil { CRAYON, GOMME, POT, PIPETTE }

var peinture: Painting
var rendu: Rendu
var mode_relief := false
var outil := Outil.CRAYON
var couleur := Color(0.36, 0.55, 0.27)
var zoom := 2
var origine := Vector2(24, 64)

var _guide := {}
var _relief := {}
var _vue: Control
var _image: TextureRect
var _halo: TextureRect
var _texture: ImageTexture
var _halo_image: Image
var _halo_texture: ImageTexture
var _halo_de := -1
var _statut: Label
var _boutons_outils := {}
var _bouton_mode: Button
var _choix_couleur: ColorPickerButton
var _peint := false
var _dernier := Vector2i(-99999, -99999)
var _glisse := false
var _espace := false


func _ready() -> void:
	peinture = Painting.new(16)
	_guide = lire_guide(GUIDE)
	_relief = _relief_de_depart()
	_construire_ui()
	_reposer()


# ── l'interface ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _construire_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = Color(0.05, 0.06, 0.09)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	_vue = Control.new()
	_vue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vue.clip_contents = true
	_vue.mouse_filter = Control.MOUSE_FILTER_STOP
	_vue.gui_input.connect(_entree_vue)
	_vue.mouse_exited.connect(func() -> void: _eclairer(-1))
	add_child(_vue)
	_image = TextureRect.new()
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(_image)
	_halo = TextureRect.new()
	_halo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(_halo)
	var barre := PanelContainer.new()
	barre.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.11, 0.16, 0.94)
	sb.set_content_margin_all(8)
	barre.add_theme_stylebox_override("panel", sb)
	add_child(barre)
	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 8)
	barre.add_child(rangee)
	var titre := Label.new()
	titre.text = "Marching Squares"
	titre.add_theme_font_size_override("font_size", 18)
	rangee.add_child(titre)
	rangee.add_child(VSeparator.new())
	for o: Array in [[Outil.CRAYON, "Pencil (P)"], [Outil.GOMME, "Eraser (E)"], [Outil.POT, "Fill (G)"], [Outil.PIPETTE, "Picker (I)"]]:
		var b := Button.new()
		b.text = o[1]
		b.toggle_mode = true
		var quel: int = o[0]
		b.pressed.connect(func() -> void: _choisir(quel))
		_boutons_outils[quel] = b
		rangee.add_child(b)
	_choix_couleur = ColorPickerButton.new()
	_choix_couleur.color = couleur
	_choix_couleur.custom_minimum_size = Vector2(44, 0)
	_choix_couleur.color_changed.connect(func(c: Color) -> void: couleur = c)
	rangee.add_child(_choix_couleur)
	rangee.add_child(VSeparator.new())
	_bouton_mode = Button.new()
	_bouton_mode.pressed.connect(_basculer)
	rangee.add_child(_bouton_mode)
	rangee.add_child(VSeparator.new())
	for a: Array in [["Save", _sauver], ["Reload", _relire], ["Export tileset", _exporter], ["Open folder", _ouvrir_dossier]]:
		var b := Button.new()
		b.text = a[0]
		b.pressed.connect(a[1])
		rangee.add_child(b)
	_statut = Label.new()
	_statut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_statut.clip_text = true
	rangee.add_child(_statut)
	_choisir(Outil.CRAYON)


func _choisir(o: int) -> void:
	outil = o
	for k: int in _boutons_outils:
		_boutons_outils[k].button_pressed = k == o


func _basculer() -> void:
	mode_relief = not mode_relief
	_reposer()


# ── le rendu ─────────────────────────────────────────────────────────────────────────────────────────────────────────

func _reposer() -> void:
	var m: Dictionary = _relief if mode_relief else _guide
	rendu = Rendu.new(peinture.resolution)
	rendu.construire(m.h, m.colonnes, m.rangees, peinture)
	_texture = ImageTexture.create_from_image(rendu.image)
	_image.texture = _texture
	_halo_image = Image.create(rendu.image.get_width(), rendu.image.get_height(), false, Image.FORMAT_RGBA8)
	_halo_texture = ImageTexture.create_from_image(_halo_image)
	_halo.texture = _halo_texture
	_halo_de = -1
	_placer()
	_bouton_mode.text = "Mode: Relief (Tab)" if mode_relief else "Mode: Guide (Tab)"
	_dire()


func _placer() -> void:
	var taille := Vector2(rendu.image.get_size()) * zoom
	for t: TextureRect in [_image, _halo]:
		t.position = origine
		t.size = taille


func _rafraichir(numeros: Array) -> void:
	for n: int in numeros:
		rendu.repeindre(n, peinture)
	_texture.update(rendu.image)


## Éclaire toutes les apparitions de l'archétype `n` (-1 : rien).
func _eclairer(n: int) -> void:
	if n == _halo_de or _halo_image == null:
		return
	var w := rendu.largeur()
	if _halo_de >= 0:
		for i: int in rendu.apparitions(_halo_de):
			_halo_image.set_pixel(i % w, i / w, Color(0, 0, 0, 0))
	_halo_de = n
	if n >= 0:
		for i: int in rendu.apparitions(n):
			_halo_image.set_pixel(i % w, i / w, Color(1.0, 0.85, 0.3, 0.22))
	_halo_texture.update(_halo_image)


func _dire(texte: String = "", alerte := false) -> void:
	var peints := 0
	for n in Archetypes.liste().size():
		if peinture.is_painted(Vector2i(n, 0)):
			peints += 1
	_statut.text = "%s   %d / %d archetypes painted" % [texte, peints, Archetypes.liste().size()]
	_statut.add_theme_color_override("font_color", Color(1, 0.45, 0.4) if alerte else Color(0.85, 0.86, 0.9))


# ── la souris et le clavier ──────────────────────────────────────────────────────────────────────────────────────────

func _pixel(pos: Vector2) -> Vector2i:
	return Vector2i(((pos - origine) / zoom).floor())


func _entree_vue(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var b := e as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_WHEEL_UP and b.pressed:
			_zoomer(1, b.position)
		elif b.button_index == MOUSE_BUTTON_WHEEL_DOWN and b.pressed:
			_zoomer(-1, b.position)
		elif b.button_index == MOUSE_BUTTON_MIDDLE or (b.button_index == MOUSE_BUTTON_LEFT and _espace):
			_glisse = b.pressed
		elif mode_relief and b.pressed and b.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			sculpter(_pixel(b.position), 1 if b.button_index == MOUSE_BUTTON_LEFT else -1)
		elif not mode_relief and b.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			if b.pressed:
				peinture.begin_stroke()
				_peint = true
				_dernier = Vector2i(-99999, -99999)
				agir(_pixel(b.position), b.button_index == MOUSE_BUTTON_RIGHT)
			else:
				_peint = false
				peinture.end_stroke()
	elif e is InputEventMouseMotion:
		var m := e as InputEventMouseMotion
		if _glisse:
			origine += m.relative
			_placer()
			return
		var p := _pixel(m.position)
		_survoler(p)
		if _peint:
			agir(p, (m.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0)


func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null:
		return
	if k.keycode == KEY_SPACE:
		_espace = k.pressed
		return
	if not k.pressed or k.echo:
		return
	if k.ctrl_pressed and k.keycode == KEY_Z:
		_rafraichir(_numeros(peinture.undo()))
	elif k.ctrl_pressed and k.keycode == KEY_Y:
		_rafraichir(_numeros(peinture.redo()))
	elif k.ctrl_pressed and k.keycode == KEY_S:
		_sauver()
	elif k.keycode == KEY_TAB:
		_basculer()
	elif k.keycode == KEY_P:
		_choisir(Outil.CRAYON)
	elif k.keycode == KEY_E:
		_choisir(Outil.GOMME)
	elif k.keycode == KEY_G:
		_choisir(Outil.POT)
	elif k.keycode == KEY_I:
		_choisir(Outil.PIPETTE)
	else:
		return
	get_viewport().set_input_as_handled()


func _zoomer(sens: int, autour: Vector2) -> void:
	var avant := zoom
	zoom = clampi(zoom + sens, 1, 12)
	if zoom == avant:
		return
	origine = autour - (autour - origine) * (float(zoom) / avant)
	_placer()


func _survoler(p: Vector2i) -> void:
	if mode_relief:
		_dire("Click: raise the nearest corner · right click: lower it")
		return
	var s := rendu.sous(p.x, p.y)
	if s.is_empty():
		_eclairer(-1)
		_dire("Nothing to paint here", true)
		return
	_eclairer(s[0])
	var a: Dictionary = Archetypes.liste()[s[0]]
	_dire("Archetype %d (%s) · seen %d times · pixel %d,%d" % [s[0], ["", "top", "cliff top", "cliff bottom"][a.sorte],
			_occurrences(s[0]), s[1], s[2]])


func _occurrences(n: int) -> int:
	return rendu.poses_de(n)


# ── peindre et sculpter (publics : la sonde les appelle) ─────────────────────────────────────────────────────────────

## Un geste de l'outil au pixel d'écran `p` (avec la ligne depuis le précédent, pour qu'un trait rapide reste continu).
func agir(p: Vector2i, effacer := false) -> void:
	var points: Array[Vector2i] = [p]
	if _dernier.x > -99999 and (outil == Outil.CRAYON or outil == Outil.GOMME or effacer):
		points = _ligne(_dernier, p)
	_dernier = p
	var touches := {}
	for q: Vector2i in points:
		var s := rendu.sous(q.x, q.y)
		if s.is_empty():
			continue
		var cle := Vector2i(s[0], 0)
		if effacer or outil == Outil.GOMME:
			if peinture.erase(cle, s[1], s[2]):
				touches[s[0]] = true
		elif outil == Outil.CRAYON:
			if peinture.paint(cle, s[1], s[2], couleur):
				touches[s[0]] = true
		elif outil == Outil.POT:
			if _remplir(s[0], s[1], s[2]):
				touches[s[0]] = true
		elif outil == Outil.PIPETTE:
			var c := peinture.pixel_at(cle, s[1], s[2])
			if c.a > 0.0:
				couleur = c
				_choix_couleur.color = c
	if not touches.is_empty():
		_rafraichir(touches.keys())
		_dire()


## Le pot, DANS la forme de l'archétype : la plage contiguë de même couleur, jamais au-delà de ce qui se voit.
func _remplir(n: int, x: int, y: int) -> bool:
	var res := peinture.resolution
	var masque := Rendu.masque_de(n, res)
	var cle := Vector2i(n, 0)
	var depart := peinture.pixel_at(cle, x, y)
	if depart.is_equal_approx(couleur):
		return false
	var vus := {}
	var file: Array[Vector2i] = [Vector2i(x, y)]
	var change := false
	while not file.is_empty():
		var q: Vector2i = file.pop_back()
		if vus.has(q) or q.x < 0 or q.y < 0 or q.x >= res or q.y >= res:
			continue
		vus[q] = true
		if masque[q.y * res + q.x] == 0 or not peinture.pixel_at(cle, q.x, q.y).is_equal_approx(depart):
			continue
		change = peinture.paint(cle, q.x, q.y, couleur) or change
		file.append_array([q + Vector2i.RIGHT, q + Vector2i.LEFT, q + Vector2i.UP, q + Vector2i.DOWN])
	return change


## Monte (+1) ou descend (−1) le coin du relief le plus proche du pixel d'écran `p`.
func sculpter(p: Vector2i, sens: int) -> void:
	var m := _relief
	var larg: int = m.colonnes + 1
	var res := peinture.resolution
	var x := clampi(roundi(float(p.x) / res), 1, m.colonnes - 1)
	var meilleur := -1
	var ecart := INF
	for j in range(1, m.rangees):
		var sy: float = (j - m.h[j * larg + x] + rendu.hmax) * res
		# ⚠ À égalité, le coin de DEVANT (le plus au sud) : deux coins de rangées différentes peuvent tomber au même
		# endroit de l'écran, et c'est celui de devant qui se voit (sonde du 4 novembre 2026 : on montait celui du fond).
		if absf(sy - p.y) <= ecart:
			ecart = absf(sy - p.y)
			meilleur = j
	if meilleur < 0:
		return
	var hh: PackedInt32Array = m.h
	var i := meilleur * larg + x
	hh[i] = clampi(hh[i] + sens, 0, 12)
	m.h = hh
	_reposer()


static func _ligne(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var sortie: Array[Vector2i] = []
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for k in n + 1:
		var t := float(k) / maxi(n, 1)
		sortie.append(Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t))))
	return sortie


static func _numeros(cases: Array[Vector2i]) -> Array:
	var s := {}
	for c: Vector2i in cases:
		s[c.x] = true
	return s.keys()


# ── le travail ───────────────────────────────────────────────────────────────────────────────────────────────────────

func _sauver() -> void:
	var e := Travail.sauver(peinture, TRAVAIL)
	_dire("Saved: %s" % ProjectSettings.globalize_path(TRAVAIL) if e == OK else "Could not save (%d)" % e, e != OK)


func _relire() -> void:
	if not FileAccess.file_exists(TRAVAIL):
		_dire("Nothing saved yet", true)
		return
	var p := Travail.relire(TRAVAIL)
	if p == null:
		_dire("This file is not a Marching Squares work", true)
		return
	peinture = p
	_reposer()
	_dire("Reloaded")


func _exporter() -> void:
	var sortie := Travail.exporter(peinture, ProjectSettings.globalize_path(EXPORT))
	_dire("Exported: %s" % sortie[0])


func _ouvrir_dossier() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))


# ── le guide et le relief ────────────────────────────────────────────────────────────────────────────────────────────

## Un relief au format texte : « colonnes rangées », puis les hauteurs des coins, une rangée par ligne.
static func lire_guide(chemin: String) -> Dictionary:
	var lignes := FileAccess.get_file_as_string(chemin).strip_edges().split("\n")
	var tete := lignes[0].split(" ")
	var colonnes := int(tete[0])
	var rangees := int(tete[1])
	var h := PackedInt32Array()
	for j in range(1, rangees + 2):
		for v: String in lignes[j].strip_edges().split(" "):
			h.append(int(v))
	return {"h": h, "colonnes": colonnes, "rangees": rangees}


## Un relief de départ pour le mode relief : un plateau à deux terrasses et une niche, sur une plaine.
static func _relief_de_depart() -> Dictionary:
	var colonnes := 24
	var rangees := 16
	var larg := colonnes + 1
	var h := PackedInt32Array()
	h.resize(larg * (rangees + 1))
	for j in rangees + 1:
		for x in larg:
			if x >= 5 and x <= 18 and j >= 4 and j <= 11:
				h[j * larg + x] = 2
			if x >= 8 and x <= 14 and j >= 5 and j <= 8:
				h[j * larg + x] = 4
	h[11 * larg + 11] = 0
	return {"h": h, "colonnes": colonnes, "rangees": rangees}
