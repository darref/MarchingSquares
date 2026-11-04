extends SceneTree

## L'ÉDITEUR COMPLET SUR LE MODÈLE PAR LES COINS, ÉPROUVÉ — headless : la scène de l'ancienne interface montée entière,
## ses salles, ses sections, ses outils, ses jauges, ses fichiers, son export, son essai et l'installation du greffon.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://proof/coins_editeur.gd

const Archetypes := preload("res://core/coins/archetypes.gd")
const Travail := preload("res://core/coins/travail.gd")
const Essai := preload("res://core/coins/essai.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const Rendu := preload("res://core/coins/rendu.gd")

var _ok := 0
var _faux := 0


func check(v: bool, quoi: String) -> void:
	if v:
		_ok += 1
		print("ok : " + quoi)
	else:
		_faux += 1
		printerr("ÉCHEC : " + quoi)


func _initialize() -> void:
	_derouler()


func _visible(e: Control, nom: String) -> bool:
	var n := e.find_child(nom, true, false) as Control
	return n != null and n.visible


func _derouler() -> void:
	var e: Control = load("res://ui/coins/editeur.tscn").instantiate()
	root.add_child(e)
	for i in 3:
		await process_frame
	var z: Control = e._zone()
	check(z.rendu != null and not z.mode_relief, "l'éditeur s'ouvre sur Draw, le guide composé")
	var poses := 0
	for n in Archetypes.liste().size():
		if z.rendu.poses_de(n) > 0:
			poses += 1
	check(poses == 33, "le guide des coins pose les 33 tuiles (%d)" % poses)
	check(_visible(e, "VariantsSection") and not _visible(e, "SculptSection") and not _visible(e, "BackgroundSection")
			and _visible(e, "PencilSection") and _visible(e, "NeighboursSection"), "Draw : ses sections (Variants, pas Sculpt)")
	check((e.find_child("Brand", true, false) as Label).text == "MarchingSquares", "la barre du haut dit MarchingSquares")
	check((e.get_node("%ExportButton") as Button).disabled, "l'export est refusé tant que rien n'est peint")

	# Peindre au crayon dans Draw : un pixel d'une tuile visible.
	var r: Rendu = z.rendu
	var i0 := -1
	for i: int in r.pose_de.size():
		if r.pose_de[i] >= 0 and r.poses[r.pose_de[i]][0] == Modele.DESSUS:
			i0 = i
			break
	var p0 := Vector2i(i0 % r.largeur(), i0 / r.largeur())
	var cle: Vector2i = r.sous(p0.x, p0.y)[0]
	z.pencil = Color8(200, 30, 30)
	e._choisir_outil(0)
	z.passe(p0, p0)
	check(e._peinture.is_painted(cle), "Draw : le crayon peint la tuile %s" % cle)
	check((e.get_node("%SurfaceLabel") as Label).text.contains("1 /"), "la jauge des dessus compte la tuile (%s)" % (e.get_node("%SurfaceLabel") as Label).text)

	# La brosse de taille 3 et « rester dans la tuile ».
	e._choisir_outil(1)
	z.brush_size = 3
	z.lock_to_tile = true
	var avant: int = e._peinture.painted_cells().size()
	z.passe(p0, p0 + Vector2i(40, 0))
	check(e._peinture.painted_cells().size() == avant, "« Keep inside the tile » : la brosse ne déborde pas sur la voisine")
	z.lock_to_tile = false

	# Les variantes, sur la tuile survolée.
	z._hover_pixel = p0
	var dit: String = z.nouvelle_variante()
	check(Travail.nb_variantes(z.meta, cle.x, 0) == 2, "V : une variante (%s)" % dit)
	z._hover_pixel = p0
	z.oter_variante()
	check(Travail.nb_variantes(z.meta, cle.x, 0) == 1, "X : la variante s'ôte")

	# Une matière dans Draw : la ligne « Paint ».
	(e.get_node("%ModeChoice") as OptionButton).select(1)
	await e._on_paint_selected(1)
	var formes := {}
	for k: Vector2i in z.rendu.images_vues():
		if k.y / 10 == 1:
			formes[k.x] = true
	check(formes.size() == 13, "Paint : Material 1 — ses 13 formes dans le guide (%d)" % formes.size())
	(e.get_node("%ModeChoice") as OptionButton).select(0)
	await e._on_paint_selected(0)

	# La salle Test : Sculpt d'abord, puis peindre au relief.
	e.choisir_salle(e.TEST)
	check(z.mode_relief and z.tool == e.SCULPT and e._sculpt_button.button_pressed, "Test : le relief, l'outil Sculpt plateaus")
	check(_visible(e, "SculptSection") and not _visible(e, "VariantsSection"), "Test : ses sections (Sculpt, pas Variants)")
	var larg: int = z.relief.colonnes + 1
	var res: int = e._peinture.resolution
	var hav: int = z.relief.h[6 * larg + 10]
	z.sculpter(Vector2i(10 * res, (6 - hav + z.rendu.hmax) * res), 1)
	check(int(z.relief.h[6 * larg + 10]) == hav + 1, "Test : Sculpt monte le coin qui se voit")
	# PAS DE RENCONTRE DIAGONALE (Jordan, 4 novembre 2026 : « refuser le clic ») : 400 clics au hasard, hauteurs et
	# matières ; le relief ne porte jamais de selle, et des clics ont bien été refusés (et dits).
	var refus := [0]
	z.refused.connect(func(_w: String) -> void: refus[0] += 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var taille_img: Vector2i = z.rendu.image.get_size()
	for k in 400:
		var q := Vector2i(rng.randi_range(0, taille_img.x - 1), rng.randi_range(0, taille_img.y - 1))
		if rng.randf() < 0.75:
			z.sculpter(q, 1 if rng.randf() < 0.6 else -1)
		else:
			z.poser_matiere(q, rng.randi_range(0, 2))
		taille_img = z.rendu.image.get_size()
	check(Modele.sans_selle(z.relief.h, z.relief.mat, z.relief.colonnes, z.relief.rangees) and refus[0] > 0,
			"400 clics au hasard : jamais de rencontre diagonale, %d clics refusés et dits" % refus[0])
	check((e.get_node("%Ticker") as Label).text.begins_with("Refused"), "le refus se lit dans le bandeau")
	e._choisir_outil(0)
	var rt: Rendu = z.rendu
	var it := -1
	for i: int in rt.pose_de.size():
		if rt.pose_de[i] >= 0 and rt.poses[rt.pose_de[i]][0] == Modele.HAUT:
			it = i
			break
	var pt := Vector2i(it % rt.largeur(), it / rt.largeur())
	var st: Array = rt.sous(pt.x, pt.y)
	z.pencil = Color8(30, 200, 30)
	z.passe(pt, pt)
	check(e._peinture.pixel_at(st[0], st[1], st[2]).is_equal_approx(z.pencil), "Test : le crayon peint la tuile qu'on voit")
	e.choisir_salle(e.DRAW)
	check(not z.mode_relief and z.tool == 1, "Draw retrouve son dernier outil (la brosse)")
	var vu := 0
	for i: int in z.rendu.apparitions(st[0]):
		if z.rendu.image.get_pixel(i % z.rendu.largeur(), i / z.rendu.largeur()).is_equal_approx(Color8(30, 200, 30)):
			vu += 1
	check(vu > 0, "la retouche faite en Test est dans le guide (%d pixels)" % vu)

	# Enregistrer, rouvrir : le carnet et le relief.
	var chemin := ProjectSettings.globalize_path("user://sonde_editeur.mqcoins")
	await e.enregistrer(chemin)
	var h_sauve: PackedInt32Array = z.relief.h.duplicate()
	await e.ouvrir(chemin)
	check(e._peinture.is_painted(cle) and z.relief.h == h_sauve, "Save puis Open : les tuiles et le monde du Test reviennent")

	# Tout peint (le motif d'essai) : l'export s'ouvre.
	e._peinture = Essai.peindre(e._current_resolution())
	z.adopt(e._peinture, e._meta, e._guide, e._guide_mat)
	e._refresh_counters()
	check(not (e.get_node("%ExportButton") as Button).disabled and (e.get_node("%RemainingLabel") as Label).text == "ready to export",
			"35 / 35 : l'export s'ouvre")
	var dossier := ProjectSettings.globalize_path("user://sonde_editeur_export")
	await e.exporter(dossier)
	check(FileAccess.file_exists(dossier.path_join("marching_squares_planche.json")), "Export tileset : la planche et le manifeste")

	# L'installation du greffon dans un projet Godot.
	var projet := ProjectSettings.globalize_path("user://sonde_projet")
	DirAccess.make_dir_recursive_absolute(projet)
	FileAccess.open(projet.path_join("project.godot"), FileAccess.WRITE).store_string("config_version=5\n")
	await e.installer(projet)
	check(FileAccess.file_exists(projet.path_join("addons/marching_squares/world.gd"))
			and FileAccess.file_exists(projet.path_join("marching_squares/marching_squares_planche.json")),
			"Install the Godot plugin : le greffon et le tileset dans le projet")
	check(preload("res://core/coins/installer.gd").ICONE == FileAccess.get_file_as_string("res://addons/marching_squares/icon.svg"),
			"l'icône que l'installeur emporte est celle du greffon")
	await e.installer(ProjectSettings.globalize_path("user://"))
	check((e.get_node("%PluginHint") as Label).text.contains("not a Godot project"), "un dossier qui n'est pas un projet est refusé, et dit")

	print("%d/%d" % [_ok, _ok + _faux])
	quit(1 if _faux else 0)
