extends SceneTree

## L'ATELIER ET LE GREFFON DU MODÈLE PAR LES COINS, ÉPROUVÉS — headless, par leurs fonctions publiques comme le ferait la
## souris : le guide pose les 35 archétypes ; un pixel peint apparaît dans TOUTES les apparitions de son image ; le fond
## refuse le crayon ; le pot reste dans la forme ; l'annulation rend l'image ; les VARIANTES naissent d'une copie, se
## montrent là où on les a créées seulement, s'ôtent ; le guide d'une MATIÈRE montre ses quinze formes ; le travail se
## relit à l'identique ; l'export porte la planche et la table ; le relief se sculpte et prend des matières ; et le
## GREFFON, avec la planche exportée, pose EXACTEMENT ce que montre l'atelier, pixel pour pixel.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://proof/coins_atelier.gd

const Archetypes := preload("res://core/coins/archetypes.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Travail := preload("res://core/coins/travail.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const Monde := preload("res://addons/marching_squares/world.gd")

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


func _derouler() -> void:
	var a: Control = load("res://ui/coins/atelier.tscn").instantiate()
	root.add_child(a)
	await process_frame
	var r: Rendu = a.rendu
	var res: int = a.peinture.resolution
	var poses := 0
	for n in Archetypes.liste().size():
		if r.poses_de(n) > 0:
			poses += 1
	check(poses == 33, "le guide pose les 33 archétypes (%d)" % poses)

	# Peindre un pixel : il apparaît partout où l'image se voit, au même pixel local.
	var cle := _la_plus_vue(r)
	var app := r.apparitions(cle)
	var w := r.largeur()
	var i0 := app[0]
	var cible := r.sous(i0 % w, i0 / w)
	a.couleur = Color8(230, 25, 51)          # une couleur exacte en 8 bits : l'image est en RGBA8
	a.peinture.begin_stroke()
	a.agir(Vector2i(i0 % w, i0 / w))
	a.peinture.end_stroke()
	check(a.peinture.is_painted(cle), "le crayon peint l'image %s" % cle)
	var partout := 0
	var attendus := 0
	for i: int in app:
		var s := r.sous(i % w, i / w)
		if s[1] == cible[1] and s[2] == cible[2]:
			attendus += 1
			if r.image.get_pixel(i % w, i / w).is_equal_approx(a.couleur):
				partout += 1
	check(attendus >= 2 and partout == attendus, "le pixel peint se voit dans les %d apparitions (%d)" % [attendus, partout])

	# Le fond refuse.
	var fond := r.pose_de.find(-1)
	var avant: int = a.peinture.pixel_count(cle)
	a.agir(Vector2i(fond % w, fond / w))
	check(fond >= 0 and a.peinture.pixel_count(cle) == avant, "le fond refuse le crayon")

	# L'annulation.
	a._rafraichir(a.peinture.undo())
	check(not a.peinture.is_painted(cle) and not r.image.get_pixel(i0 % w, i0 / w).is_equal_approx(a.couleur),
			"Ctrl+Z rend l'image du guide")

	# Le pot reste dans la forme.
	a.outil = a.Outil.POT
	a._dernier = Vector2i(-99999, -99999)
	a.agir(Vector2i(i0 % w, i0 / w))
	var masque := Rendu.masque_de(cle.x, res)
	var dans := 0
	var hors := 0
	for y in res:
		for x in res:
			if a.peinture.pixel_at(cle, x, y).a > 0.0:
				if masque[y * res + x] != 0:
					dans += 1
				else:
					hors += 1
	var forme := 0
	for v: int in masque:
		if v != 0:
			forme += 1
	check(hors == 0 and dans == forme, "le pot remplit la forme, rien au-delà (%d / %d, hors %d)" % [dans, forme, hors])

	# Les variantes : V sur une apparition, elle seule la montre ; on la peint sans toucher la base ; X l'ôte.
	var ici := Vector2i(i0 % w, i0 / w)
	check(a.nouvelle_variante(ici), "V : une variante naît de l'apparition survolée")
	r = a.rendu
	var vue: Vector2i = r.sous(ici.x, ici.y)[0]
	check(vue == Vector2i(cle.x, cle.y + 1), "cette apparition montre la variante 1 (%s)" % vue)
	var autres := 0
	for i: int in r.apparitions(cle):
		autres += 1
	check(autres > 0 and r.apparitions(vue).size() < app.size(), "les autres apparitions gardent la base (%d pixels)" % autres)
	a.outil = a.Outil.CRAYON
	a.couleur = Color8(20, 40, 200)
	a._dernier = Vector2i(-99999, -99999)
	a.peinture.begin_stroke()
	a.agir(ici)
	a.peinture.end_stroke()
	check(a.peinture.pixel_at(vue, cible[1], cible[2]).is_equal_approx(a.couleur)
			and not a.peinture.pixel_at(cle, cible[1], cible[2]).is_equal_approx(a.couleur),
			"peindre la variante ne touche pas la base")
	a.regler_poids(ici, 2)
	check(Travail.poids(a.meta, cle.x, 0) == PackedInt32Array([1, 3]), "+ : le poids de la variante monte (%s)" % Travail.poids(a.meta, cle.x, 0))

	# Le travail se relit à l'identique, variantes et poids compris.
	var chemin := "user://sonde_coins.mqcoins"
	check(Travail.sauver(a.peinture, a.meta, chemin) == OK, "le travail s'enregistre")
	var relu := Travail.relire(chemin)
	check(not relu.is_empty() and relu.peinture.image_of(vue).get_data() == a.peinture.image_of(vue).get_data()
			and relu.meta.poids == a.meta.poids and relu.meta.affectation == a.meta.affectation,
			"il se relit pixel pour pixel, poids et affectation compris")

	a.oter_variante(ici)
	check(Travail.nb_variantes(a.meta, cle.x, 0) == 1 and not a.peinture.is_painted(vue) and a.meta.affectation.is_empty(),
			"X : la variante s'ôte, l'apparition revient à la base")

	# Le guide d'une matière : ses quinze formes de dessus se voient.
	a.choisir_matiere(1)
	var formes := {}
	for k: Vector2i in a.rendu.images_vues():
		if k.y / 10 == 1:
			formes[k.x] = true
	check(formes.size() == 13, "M : le guide de la matière 1 montre ses 13 formes (%d)" % formes.size())
	a.choisir_matiere(0)

	# L'export.
	var sortie := Travail.exporter(a.peinture, a.meta, ProjectSettings.globalize_path("user://sonde_export"))
	var manifeste: Variant = JSON.parse_string(FileAccess.get_file_as_string(sortie[1]))
	var table: Dictionary = manifeste.table if manifeste is Dictionary else {}
	check(table.size() == 57, "le manifeste : la table des 57 clés (%d)" % table.size())

	# Le mode relief.
	a._basculer()
	check(a.mode_relief and a.rendu.colonnes == 24, "Tab : le relief de départ")
	var larg := 25
	var hav: int = a._relief.h[6 * larg + 10]
	a.sculpter(Vector2i(10 * res, (6 - hav + a.rendu.hmax) * res), 1)
	check(int(a._relief.h[6 * larg + 10]) == hav + 1, "un clic monte le coin qui se voit (%d → %d)" % [hav, a._relief.h[6 * larg + 10]])
	var mav: int = a._relief.mat[6 * larg + 10]
	a.matiere = 2
	a.poser_matiere(Vector2i(10 * res, (6 - hav - 1 + a.rendu.hmax) * res), 2)
	check(int(a._relief.mat[6 * larg + 10]) == 2, "Maj + clic pose la matière 2 sur ce coin (%d → 2)" % mav)

	# PEINDRE EN MODE TEST : le relief s'ouvre sur Sculpt ; avec le crayon, un pixel peint au relief est l'image de la tuile,
	# donc il est au guide et dans l'export.
	check(a.outil == a.Outil.SCULPT and a._boutons_outils[a.Outil.SCULPT].visible, "le mode test s'ouvre sur « Sculpt plateaus »")
	var h_avant: PackedInt32Array = a._relief.h.duplicate()
	a._choisir(a.Outil.CRAYON)
	a.couleur = Color8(255, 128, 0)
	var rr: Rendu = a.rendu
	var px_t := Vector2i(-1, -1)
	for i in rr.pose_de.size():
		var ip := rr.pose_de[i]
		if ip >= 0 and rr.poses[ip][0] == Modele.HAUT:
			px_t = Vector2i(i % rr.largeur(), i / rr.largeur())
			break
	var s_t := rr.sous(px_t.x, px_t.y)
	var cle_t: Vector2i = s_t[0]
	a._dernier = Vector2i(-99999, -99999)
	a.peinture.begin_stroke()
	a.agir(px_t)
	a.peinture.end_stroke()
	check(a.peinture.pixel_at(cle_t, s_t[1], s_t[2]).is_equal_approx(a.couleur) and a._relief.h == h_avant,
			"au mode test, le crayon peint la tuile %s (et ne sculpte pas)" % cle_t)
	check(rr.image.get_pixel(px_t.x, px_t.y).is_equal_approx(a.couleur), "la retouche se voit au relief")
	a._basculer()
	check(not a.mode_relief and a.outil == a.Outil.CRAYON and not a._boutons_outils[a.Outil.SCULPT].visible,
			"Tab : le guide retrouve son outil, sans Sculpt")
	var au_guide := 0
	var rg: Rendu = a.rendu
	for i: int in rg.apparitions(cle_t):
		var sg := rg.sous(i % rg.largeur(), i / rg.largeur())
		if sg[1] == s_t[1] and sg[2] == s_t[2] and rg.image.get_pixel(i % rg.largeur(), i / rg.largeur()).is_equal_approx(a.couleur):
			au_guide += 1
	check(au_guide > 0, "la retouche du mode test est au guide (%d apparitions)" % au_guide)
	var exp_t := Travail.exporter(a.peinture, a.meta, ProjectSettings.globalize_path("user://sonde_test"))
	var man_t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(exp_t[1]))
	var planche_t := Image.load_from_file(exp_t[0])
	var dans_export := false
	for e: Dictionary in man_t.images:
		if int(e.archetype) == cle_t.x and int(e.matiere) * 10 + int(e.variante) == cle_t.y:
			var q := Vector2i(int(e.colonne) * res + s_t[1], int(e.rangee) * res + s_t[2])
			dans_export = planche_t.get_pixel(q.x, q.y).is_equal_approx(a.couleur)
	check(dans_export, "et dans la planche exportée")
	a._basculer()
	check(a.mode_relief and a.outil == a.Outil.CRAYON and a._boutons_outils[a.Outil.SCULPT].visible,
			"Tab : le mode test retrouve son dernier outil (le crayon), Sculpt à portée")
	a._choisir(a.Outil.SCULPT)

	# LE GREFFON pose ce que montre l'atelier : tout peint d'un motif, une variante tirée, deux matières.
	_peindre_tout(a)
	a.mode_relief = false
	a._reposer()
	a.choisir_matiere(0)
	var guide_ici := _une_apparition(a.rendu, Modele.DESSUS)
	a.nouvelle_variante(guide_ici)
	var cv: Vector2i = a.rendu.sous(guide_ici.x, guide_ici.y)[0]
	_motif_sur(a, cv, Color8(250, 250, 0))
	a.mode_relief = true
	a._reposer()
	var exp := Travail.exporter(a.peinture, a.meta, ProjectSettings.globalize_path("user://sonde_greffon"))
	var monde: Node2D = Monde.new()
	monde.tileset = exp[1]
	monde.columns = a._relief.colonnes
	monde.rows = a._relief.rangees
	monde.heights = a._relief.h
	monde.materials = a._relief.mat
	root.add_child(monde)
	var img: Image = monde.composer()
	var ra: Rendu = a.rendu
	var egaux := 0
	var differents := 0
	var couverture := 0
	var tires := 0
	for y in ra.image.get_height():
		for x in ra.image.get_width():
			var i := y * ra.largeur() + x
			var g := img.get_pixel(x, y)
			if (ra.pose_de[i] >= 0) != (g.a > 0.0):
				couverture += 1
			elif ra.pose_de[i] >= 0:
				if g.is_equal_approx(ra.image.get_pixel(x, y)):
					egaux += 1
				else:
					differents += 1
				if ra.image_de_pose[ra.pose_de[i]] == cv:
					tires += 1
	check(img.get_size() == ra.image.get_size() and differents == 0 and couverture == 0 and egaux > 1000,
			"le greffon pose exactement l'atelier : %d pixels égaux, %d différents, %d de couverture" % [egaux, differents, couverture])
	check(tires > 0, "la variante est tirée dans le relief (%d pixels)" % tires)
	var avant_s: int = monde.heights[6 * larg + 10]
	var t := float(monde.planche.tuile)
	var rs: bool = monde.sculpter(Vector2(10 * t, (6 - avant_s) * t), 1)
	check(rs and int(monde.heights[6 * larg + 10]) == avant_s + 1, "le pinceau du greffon monte le même coin")
	# Le greffon refuse aussi la rencontre diagonale : 400 gestes au hasard, jamais de selle.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var refuses := 0
	for k in 400:
		var q := Vector2(rng.randf_range(0, monde.columns * t), rng.randf_range(-4 * t, monde.rows * t))
		var ok: bool = monde.sculpter(q, 1 if rng.randf() < 0.6 else -1) if rng.randf() < 0.75 else monde.poser_matiere(q, rng.randi_range(0, 2))
		if not ok and monde.dernier_refus != "":
			refuses += 1
	check(Modele.sans_selle(monde.heights, monde.materials, monde.columns, monde.rows) and refuses > 0,
			"le greffon : 400 gestes, jamais de rencontre diagonale (%d refusés)" % refuses)

	print("%d/%d" % [_ok, _ok + _faux])
	quit(1 if _faux else 0)


## Toutes les images de base de la surface et les quinze dessus des matières 1 et 2, remplis d'un motif opaque.
func _peindre_tout(a: Control) -> void:
	var res: int = a.peinture.resolution
	for n in Archetypes.liste().size():
		var dessus: bool = Archetypes.liste()[n].sorte == Modele.DESSUS
		for m: int in ([0, 1, 2] if dessus else [0]):
			_motif_sur(a, Vector2i(n, m * 10), Color8(40 + 60 * m, 90 + n * 4, 60 + 50 * m))
	a._reposer()


func _motif_sur(a: Control, cle: Vector2i, c: Color) -> void:
	var res: int = a.peinture.resolution
	var masque := Rendu.masque_de(cle.x, res)
	for y in res:
		for x in res:
			if masque[y * res + x] != 0:
				a.peinture.paint(cle, x, y, c.darkened(0.04 * ((x + y) % 3)))


func _une_apparition(r: Rendu, sorte: int) -> Vector2i:
	for i in r.pose_de.size():
		var ip := r.pose_de[i]
		if ip >= 0 and r.poses[ip][0] == sorte and r.poses_de(r.image_de_pose[ip].x) > 4:
			return Vector2i(i % r.largeur(), i / r.largeur())
	return Vector2i(-1, -1)


func _la_plus_vue(r: Rendu) -> Vector2i:
	var meilleur := Vector2i(-1, -1)
	var nb := -1
	for k: Vector2i in r.images_vues():
		if r.apparitions(k).size() > nb:
			nb = r.apparitions(k).size()
			meilleur = k
	return meilleur
