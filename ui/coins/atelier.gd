extends Control

## L'ATELIER DU MODÈLE PAR LES COINS — le guide, le modèle et l'outil de peinture ENSEMBLE (Jordan, 4 novembre 2026 :
## « les trois doivent fonctionner en même temps »). Une seule source : `core/coins/` et `addons/marching_squares/` ;
## aucune règle ne vit ici.
##   GUIDE   le paysage livré (`guides/coins.txt` : les 35 archétypes, les 261 jonctions). On peint SUR lui : le crayon
##           touche l'image qui se voit sous la souris, donc toujours DANS la forme de son archétype (le reste n'est pas à
##           peindre et le curseur le dit) ; chaque pixel posé apparaît aussitôt dans TOUTES ses apparitions — toutes les
##           coutures possibles sont sous les yeux. Le survol éclaire l'image partout où elle est.
##           Avec une MATIÈRE choisie (M), le guide porte en plus son champ (`guides/coins_matieres.txt`) : ses quinze
##           formes de dessus posées sur les plateaux, à peindre là où elles vivront.
##   RELIEF  (le mode test) on sculpte un relief à soi avec l'outil SCULPT (S, le bouton « Sculpt plateaus », qui n'existe
##           qu'ici ; clic : monter le coin qui se voit ; clic droit : le descendre ; Maj + clic : y poser la matière
##           choisie, Maj + clic droit : l'ôter), rendu avec ses propres images, variantes TIRÉES comme le greffon les
##           tirera. Et on y PEINT avec les mêmes outils qu'au guide (Jordan, 4 novembre 2026 : « corriger certaines tuiles
##           ou les peindre directement dans le mode test, et que ça se répercute partout ») : c'est la même image, une par
##           tuile, donc la retouche est partout — au guide, dans l'export. ⚠ Le relief ne montre pas toutes les jonctions :
##           le survol dit combien de fois la tuile est au guide, où se vérifient ses 261 raccords (Tab).
##           Chaque mode garde son outil : le guide le sien, le relief le sien (Sculpt au départ).
##   VARIANTES (comme MarchingBlocks : créées une à une, sur place, parmi les vraies voisines) — V : nouvelle variante
##           depuis l'apparition survolée (elle la montre aussitôt) ; C : faire défiler la variante montrée ici ; X : ôter
##           cette variante ; + / − : son poids (le tirage).
## Outils : crayon (P), gomme (E, ou clic droit), pot (G), pipette (I), sculpter (S, au relief) ; Ctrl+Z / Ctrl+Y ; J : points de jonction et grille ;
## molette : zoom ; bouton du milieu (ou Espace) : déplacer ; Tab : guide ↔ relief. Textes à l'écran : anglais.

const Rendu := preload("res://core/coins/rendu.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")
const Travail := preload("res://core/coins/travail.gd")
const Painting := preload("res://core/painting.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")

const GUIDE := "res://guides/coins.txt"
const GUIDE_MATIERES := "res://guides/coins_matieres.txt"
const TRAVAIL := "user://marching_squares.mqcoins"
const EXPORT := "user://export"
const SORTES := ["", "top", "cliff top", "cliff bottom", "material"]

enum Outil { CRAYON, GOMME, POT, PIPETTE, SCULPT }

var peinture: Painting
var meta := {"poids": {}, "affectation": {}}
var rendu: Rendu
var mode_relief := false
var matiere := 0
var outil := Outil.CRAYON
## L'outil que l'autre mode retrouvera en revenant.
var _outil_autre := Outil.SCULPT
## archétype → combien de fois le guide le pose (dit au survol du relief).
var _au_guide := {}
var couleur := Color(0.36, 0.55, 0.27)
var zoom := 2
var origine := Vector2(24, 64)
var jonctions_visibles := false

var _guide := {}
var _guide_mat := PackedInt32Array()
var _relief := {}
var _vue: Control
var _image: TextureRect
var _halo: TextureRect
var _calque: Control
var _texture: ImageTexture
var _halo_image: Image
var _halo_texture: ImageTexture
var _halo_de := Vector2i(-1, -1)
var _points := PackedVector2Array()
var _statut: Label
var _boutons_outils := {}
var _bouton_mode: Button
var _bouton_matiere: Button
var _choix_couleur: ColorPickerButton
var _peint := false
var _dernier := Vector2i(-99999, -99999)
var _survol := Vector2i(-1, -1)
var _glisse := false
var _espace := false


func _ready() -> void:
	peinture = Painting.new(16)
	_guide = lire_guide(GUIDE)
	if FileAccess.file_exists(GUIDE_MATIERES):
		_guide_mat = lire_guide(GUIDE_MATIERES).h
	_relief = _relief_de_depart()
	for p: Array in Modele.poses(_guide.h, _guide.colonnes, _guide.rangees):
		var n := Archetypes.numero(p[0], p[4], p[5])
		_au_guide[n] = int(_au_guide.get(n, 0)) + 1
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
	_vue.mouse_exited.connect(func() -> void: _eclairer(Vector2i(-1, -1)))
	add_child(_vue)
	_image = TextureRect.new()
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(_image)
	_halo = TextureRect.new()
	_halo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(_halo)
	_calque = Control.new()
	_calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_calque.draw.connect(_dessiner_calque)
	_vue.add_child(_calque)
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
	titre.text = "MarchingSquares"
	titre.add_theme_font_size_override("font_size", 18)
	rangee.add_child(titre)
	rangee.add_child(VSeparator.new())
	for o: Array in [[Outil.SCULPT, "Sculpt plateaus (S)"], [Outil.CRAYON, "Pencil (P)"], [Outil.GOMME, "Eraser (E)"],
			[Outil.POT, "Fill (G)"], [Outil.PIPETTE, "Picker (I)"]]:
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
	_bouton_matiere = Button.new()
	_bouton_matiere.pressed.connect(func() -> void: choisir_matiere((matiere + 1) % Modele.MATIERES_MAXI))
	rangee.add_child(_bouton_matiere)
	var bj := Button.new()
	bj.text = "Junctions (J)"
	bj.pressed.connect(_basculer_jonctions)
	rangee.add_child(bj)
	rangee.add_child(VSeparator.new())
	for a: Array in [["Save", _sauver], ["Reload", _relire], ["Export tileset", _exporter], ["Open folder", _ouvrir_dossier]]:
		var b := Button.new()
		b.text = a[0]
		b.pressed.connect(a[1])
		rangee.add_child(b)
	# La barre d'état vit EN BAS, sur toute la largeur : en haut, les outils du mode test la coupaient (vu à l'image).
	var bas := PanelContainer.new()
	bas.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bas.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bas.add_theme_stylebox_override("panel", sb)
	add_child(bas)
	_statut = Label.new()
	_statut.clip_text = true
	bas.add_child(_statut)
	_choisir(Outil.CRAYON)


func _choisir(o: int) -> void:
	if o == Outil.SCULPT and not mode_relief:
		return
	outil = o
	for k: int in _boutons_outils:
		_boutons_outils[k].button_pressed = k == o
	_boutons_outils[Outil.SCULPT].visible = mode_relief


## Guide ↔ relief ; chaque mode retrouve son outil (le relief commence par Sculpt).
func _basculer() -> void:
	mode_relief = not mode_relief
	var avant := outil
	outil = _outil_autre
	_outil_autre = avant
	_choisir(outil)
	_reposer()


func choisir_matiere(m: int) -> void:
	matiere = clampi(m, 0, Modele.MATIERES_MAXI - 1)
	_reposer()


func _basculer_jonctions() -> void:
	jonctions_visibles = not jonctions_visibles
	_points = rendu.jonctions_ecran() if jonctions_visibles else PackedVector2Array()
	_calque.queue_redraw()


# ── le rendu ─────────────────────────────────────────────────────────────────────────────────────────────────────────

## Le relief montré : le guide (et le champ de la matière choisie), ou le relief sculpté.
func monde() -> Dictionary:
	if mode_relief:
		return _relief
	var mat := PackedInt32Array()
	if matiere > 0 and _guide_mat.size() == (_guide.h as PackedInt32Array).size():
		mat = _guide_mat.duplicate()
		for i in mat.size():
			mat[i] *= matiere
	return {"h": _guide.h, "mat": mat, "colonnes": _guide.colonnes, "rangees": _guide.rangees}


func _reposer() -> void:
	var m := monde()
	rendu = Rendu.new(peinture.resolution)
	rendu.construire(m.h, m.colonnes, m.rangees, peinture, m.get("mat", PackedInt32Array()), _variante)
	_texture = ImageTexture.create_from_image(rendu.image)
	_image.texture = _texture
	_halo_image = Image.create(rendu.image.get_width(), rendu.image.get_height(), false, Image.FORMAT_RGBA8)
	_halo_texture = ImageTexture.create_from_image(_halo_image)
	_halo.texture = _halo_texture
	_halo_de = Vector2i(-1, -1)
	_points = rendu.jonctions_ecran() if jonctions_visibles else PackedVector2Array()
	_placer()
	_bouton_mode.text = "Mode: Relief (Tab)" if mode_relief else "Mode: Guide (Tab)"
	_bouton_matiere.text = "Material: %s (M)" % ("base" if matiere == 0 else str(matiere))
	_dire()


## La variante montrée par une pose : au guide, celle que l'artiste y a mise ; au relief, le TIRAGE du greffon.
func _variante(ip: int, p: Array, n: int, m: int) -> int:
	var nb := Travail.nb_variantes(meta, n, m)
	if nb <= 1:
		return 0
	if mode_relief:
		return Modele.tirage(p[2], p[3], p[1], p[0], Travail.poids(meta, n, m))
	var a: Array = (meta.affectation as Dictionary).get(_id_pose(p), [])
	if a.size() == 3 and a[0] == n and a[1] == m and a[2] < nb:
		return a[2]
	return 0


static func _id_pose(p: Array) -> String:
	return "%d:%d:%d:%d:%d" % [p[0], p[1], p[2], p[3], p[5] if p[0] == Modele.MATIERE else 0]


func _placer() -> void:
	var taille := Vector2(rendu.image.get_size()) * zoom
	for t: TextureRect in [_image, _halo]:
		t.position = origine
		t.size = taille
	_calque.queue_redraw()


func _dessiner_calque() -> void:
	if not jonctions_visibles or rendu == null:
		return
	var res := rendu.resolution
	var w := rendu.image.get_width()
	var h := rendu.image.get_height()
	var ligne_grille := Color(1, 1, 1, 0.12)
	for x in range(0, w + 1, res):
		_calque.draw_line(origine + Vector2(x, 0) * zoom, origine + Vector2(x, h) * zoom, ligne_grille)
	for y in range(0, h + 1, res):
		_calque.draw_line(origine + Vector2(0, y) * zoom, origine + Vector2(w, y) * zoom, ligne_grille)
	for p: Vector2 in _points:
		var cote := maxf(zoom, 3.0)
		_calque.draw_rect(Rect2(origine + (p + Vector2(0.5, 0.5)) * zoom - Vector2(cote, cote) / 2.0, Vector2(cote, cote)),
				Color(1.0, 0.25, 0.6, 0.9))


func _rafraichir(cles: Array) -> void:
	var familles := {}
	for c: Vector2i in cles:
		familles[Vector2i(c.x, c.y / 10)] = true
	for f: Vector2i in familles:
		rendu.repeindre_famille(f.x, f.y, peinture)
	_texture.update(rendu.image)


## Éclaire toutes les apparitions de l'image `cle` ((-1, -1) : rien).
func _eclairer(cle: Vector2i) -> void:
	if cle == _halo_de or _halo_image == null:
		return
	var w := rendu.largeur()
	if _halo_de.x >= 0:
		for i: int in rendu.apparitions(_halo_de):
			_halo_image.set_pixel(i % w, i / w, Color(0, 0, 0, 0))
	_halo_de = cle
	if cle.x >= 0:
		for i: int in rendu.apparitions(cle):
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
		elif mode_relief and outil == Outil.SCULPT and b.pressed and b.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			var gauche := b.button_index == MOUSE_BUTTON_LEFT
			if b.shift_pressed:
				poser_matiere(_pixel(b.position), matiere if gauche else 0)
			else:
				sculpter(_pixel(b.position), 1 if gauche else -1)
		elif outil != Outil.SCULPT and b.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
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
		_rafraichir(peinture.undo())
	elif k.ctrl_pressed and k.keycode == KEY_Y:
		_rafraichir(peinture.redo())
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
	elif k.keycode == KEY_S:
		_choisir(Outil.SCULPT)
	elif k.keycode == KEY_J:
		_basculer_jonctions()
	elif k.keycode == KEY_M:
		choisir_matiere((matiere + 1) % Modele.MATIERES_MAXI)
	elif k.keycode == KEY_V:
		nouvelle_variante(_survol)
	elif k.keycode == KEY_C:
		changer_variante(_survol)
	elif k.keycode == KEY_X:
		oter_variante(_survol)
	elif k.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
		regler_poids(_survol, 1)
	elif k.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		regler_poids(_survol, -1)
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
	_survol = p
	if mode_relief and outil == Outil.SCULPT:
		_eclairer(Vector2i(-1, -1))
		_dire("Click: raise the corner you see · right click: lower it · Shift: paint material %d" % matiere)
		return
	var s := rendu.sous(p.x, p.y)
	if s.is_empty():
		_eclairer(Vector2i(-1, -1))
		_dire("Nothing to paint here", true)
		return
	var cle: Vector2i = s[0]
	_eclairer(cle)
	var n := cle.x
	var m := cle.y / 10
	var k := cle.y % 10
	var a: Dictionary = Archetypes.liste()[n]
	var nb := Travail.nb_variantes(meta, n, m)
	var quoi: String = SORTES[a.sorte] if m == 0 else "material %d" % m
	var var_txt := "" if nb <= 1 else " · variant %d of %d (weight %d)" % [k, nb - 1, Travail.poids(meta, n, m)[k]]
	if mode_relief:
		_dire("Archetype %d (%s)%s · %d times here, %d in the guide (Tab: check its junctions) · pixel %d,%d"
				% [n, quoi, var_txt, rendu.poses_de(n), int(_au_guide.get(n, 0)), s[1], s[2]])
		return
	_dire("Archetype %d (%s)%s · seen %d times · pixel %d,%d · V: new variant here" % [n, quoi, var_txt,
			rendu.poses_de(n), s[1], s[2]])


# ── peindre et sculpter (publics : la sonde les appelle) ─────────────────────────────────────────────────────────────

## Un geste de l'outil au pixel d'écran `p` (avec la ligne depuis le précédent, pour qu'un ligne_grille rapide reste continu).
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
		var cle: Vector2i = s[0]
		if effacer or outil == Outil.GOMME:
			if peinture.erase(cle, s[1], s[2]):
				touches[cle] = true
		elif outil == Outil.CRAYON:
			if peinture.paint(cle, s[1], s[2], couleur):
				touches[cle] = true
		elif outil == Outil.POT:
			if _remplir(cle, s[1], s[2]):
				touches[cle] = true
		elif outil == Outil.PIPETTE:
			var c := peinture.pixel_at(cle, s[1], s[2])
			if c.a > 0.0:
				couleur = c
				_choix_couleur.color = c
	if not touches.is_empty():
		_rafraichir(touches.keys())
		_dire()


## Le pot, DANS la forme de l'archétype : la plage contiguë de même couleur, jamais au-delà de ce qui se voit.
func _remplir(cle: Vector2i, x: int, y: int) -> bool:
	var res := peinture.resolution
	var masque := Rendu.masque_de(cle.x, res)
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


## Monte (+1) ou descend (−1) le coin du relief qui se voit au pixel d'écran `p`.
func sculpter(p: Vector2i, sens: int) -> void:
	var i := _coin(p)
	if i < 0:
		return
	var hh: PackedInt32Array = _relief.h.duplicate()
	hh[i] = clampi(hh[i] + sens, 0, 12)
	if Modele.cree_une_selle(hh, _relief.mat, _relief.colonnes, _relief.rangees, i).x >= 0:
		_dire("Refused: two plateaus would meet only at a corner", true)
		return
	_relief.h = hh
	_reposer()


## Pose la matière `m` (0 : l'ôter) sur le coin qui se voit au pixel d'écran `p`.
func poser_matiere(p: Vector2i, m: int) -> void:
	var i := _coin(p)
	if i < 0:
		return
	var mm: PackedInt32Array = _relief.mat.duplicate()
	mm[i] = m
	if Modele.cree_une_selle(_relief.h, mm, _relief.colonnes, _relief.rangees, i).x >= 0:
		_dire("Refused: two patches of material would meet only at a corner", true)
		return
	_relief.mat = mm
	_reposer()


func _coin(p: Vector2i) -> int:
	var res := float(peinture.resolution)
	return Modele.coin_sous(_relief.h, _relief.colonnes, _relief.rangees, Vector2(p.x / res, p.y / res - rendu.hmax))


# ── les variantes (publiques : la sonde les appelle) ─────────────────────────────────────────────────────────────────

## Une NOUVELLE variante de l'image qui se voit au pixel `p`, copiée d'elle ; cette apparition la montre aussitôt.
func nouvelle_variante(p: Vector2i) -> bool:
	var s := rendu.sous(p.x, p.y) if not mode_relief else []
	if s.is_empty():
		_dire("Hover a tile of the guide to make a variant of it", true)
		return false
	var cle: Vector2i = s[0]
	var n := cle.x
	var m := cle.y / 10
	var nb := Travail.nb_variantes(meta, n, m)
	if nb >= Modele.VARIANTES_MAXI + 1:
		_dire("%d variants at most" % Modele.VARIANTES_MAXI, true)
		return false
	if not peinture.is_painted(cle) and not peinture.is_painted(Vector2i(n, m * 10)):
		_dire("Paint this tile first: a variant starts as a copy", true)
		return false
	var source := cle if peinture.is_painted(cle) else Vector2i(n, m * 10)
	peinture.set_image(Vector2i(n, m * 10 + nb), peinture.image_of(source).duplicate())
	var p_ := Travail.poids(meta, n, m)
	p_.append(1)
	meta.poids["%d:%d" % [n, m]] = Array(p_)
	meta.affectation[_id_pose(rendu.poses[s[3]])] = [n, m, nb]
	_reposer()
	_dire("Variant %d of archetype %d made from this copy, shown here" % [nb, n])
	return true


## Fait défiler la variante montrée par l'apparition survolée (au guide seulement).
func changer_variante(p: Vector2i) -> void:
	var s := rendu.sous(p.x, p.y) if not mode_relief else []
	if s.is_empty():
		return
	var cle: Vector2i = s[0]
	var nb := Travail.nb_variantes(meta, cle.x, cle.y / 10)
	if nb <= 1:
		return
	meta.affectation[_id_pose(rendu.poses[s[3]])] = [cle.x, cle.y / 10, (cle.y % 10 + 1) % nb]
	_reposer()


## Ôte la variante montrée par l'apparition survolée ; les suivantes se renumérotent (une var3 sans var2 ne se tire jamais).
func oter_variante(p: Vector2i) -> void:
	var s := rendu.sous(p.x, p.y) if not mode_relief else []
	if s.is_empty():
		return
	var cle: Vector2i = s[0]
	var n := cle.x
	var m := cle.y / 10
	var k := cle.y % 10
	if k == 0:
		_dire("The base cannot be removed", true)
		return
	var nb := Travail.nb_variantes(meta, n, m)
	for j in range(k, nb - 1):
		peinture.set_image(Vector2i(n, m * 10 + j), peinture.image_of(Vector2i(n, m * 10 + j + 1)).duplicate())
	peinture.clear_cell(Vector2i(n, m * 10 + nb - 1))
	var p_ := Array(Travail.poids(meta, n, m))
	p_.remove_at(k)
	meta.poids["%d:%d" % [n, m]] = p_
	for id: String in (meta.affectation as Dictionary).keys():
		var a: Array = meta.affectation[id]
		if a[0] == n and a[1] == m:
			if a[2] == k:
				meta.affectation.erase(id)
			elif a[2] > k:
				a[2] -= 1
	_reposer()
	_dire("Variant %d of archetype %d removed" % [k, n])


## Change le poids de la variante survolée (le tirage du relief et du greffon).
func regler_poids(p: Vector2i, sens: int) -> void:
	var s := rendu.sous(p.x, p.y) if not mode_relief else []
	if s.is_empty():
		return
	var cle: Vector2i = s[0]
	var p_ := Array(Travail.poids(meta, cle.x, cle.y / 10))
	p_[cle.y % 10] = maxi(0, int(p_[cle.y % 10]) + sens)
	meta.poids["%d:%d" % [cle.x, cle.y / 10]] = p_
	_survoler(p)


static func _ligne(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var sortie: Array[Vector2i] = []
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for k in n + 1:
		var t := float(k) / maxi(n, 1)
		sortie.append(Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t))))
	return sortie


# ── le travail ───────────────────────────────────────────────────────────────────────────────────────────────────────

func _sauver() -> void:
	var e := Travail.sauver(peinture, meta, TRAVAIL)
	_dire("Saved: %s" % ProjectSettings.globalize_path(TRAVAIL) if e == OK else "Could not save (%d)" % e, e != OK)


func _relire() -> void:
	if not FileAccess.file_exists(TRAVAIL):
		_dire("Nothing saved yet", true)
		return
	var d := Travail.relire(TRAVAIL)
	if d.is_empty():
		_dire("This file is not a MarchingSquares work", true)
		return
	peinture = d.peinture
	meta = d.meta
	_reposer()
	_dire("Reloaded")


func _exporter() -> void:
	var sortie := Travail.exporter(peinture, meta, ProjectSettings.globalize_path(EXPORT))
	_dire("Exported: %s%s" % [sortie[0], "" if sortie[2] == 0 else " · %d tiles still unpainted" % sortie[2]], sortie[2] > 0)


func _ouvrir_dossier() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))


# ── le guide et le relief ────────────────────────────────────────────────────────────────────────────────────────────

## Un relief au format texte : « colonnes rangées », puis une valeur par coin, une rangée par ligne.
static func lire_guide(chemin: String) -> Dictionary:
	var lignes := FileAccess.get_file_as_string(chemin).strip_edges().split("\n")
	var tete := lignes[0].strip_edges().split(" ")
	var colonnes := int(tete[0])
	var rangees := int(tete[1])
	var h := PackedInt32Array()
	for j in range(1, rangees + 2):
		for v: String in lignes[j].strip_edges().split(" "):
			h.append(int(v))
	return {"h": h, "colonnes": colonnes, "rangees": rangees}


## Un relief de départ pour le mode relief : un plateau à deux terrasses et une niche, sur une plaine, avec une tache de
## matière 1 qui passe de la plaine au plateau.
static func _relief_de_depart() -> Dictionary:
	var colonnes := 24
	var rangees := 16
	var larg := colonnes + 1
	var h := PackedInt32Array()
	h.resize(larg * (rangees + 1))
	var mat := PackedInt32Array()
	mat.resize(h.size())
	for j in rangees + 1:
		for x in larg:
			if x >= 5 and x <= 18 and j >= 4 and j <= 11:
				h[j * larg + x] = 2
			if x >= 8 and x <= 14 and j >= 5 and j <= 8:
				h[j * larg + x] = 4
			if pow((x - 4) / 3.5, 2) + pow((j - 12) / 2.5, 2) <= 1.0:
				mat[j * larg + x] = 1
	h[11 * larg + 11] = 0
	return {"h": h, "mat": mat, "colonnes": colonnes, "rangees": rangees}
