extends SceneTree

## LES CAPTURES DE L'ÉDITEUR, POUR LE SITE — dans une vraie fenêtre, l'éditeur réel, peint du tileset d'ESSAI que l'outil
## calcule lui-même (`core/coins/essai.gd` : une spécification, pas de l'art — les légendes du site le disent).
## Sortie : D:/SpannerGames/PROJETS/MarchingSquares/05_miniatures/site/*.png
##   Godot_v4.7-stable_win64_console.exe --path D:/MarchingSquares --resolution 1920x1080 --script res://proof/coins_photo_editeur.gd

const Essai := preload("res://core/coins/essai.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const Travail := preload("res://core/coins/travail.gd")
const Monde := preload("res://addons/marching_squares/world.gd")
const SORTIE := "D:/SpannerGames/PROJETS/MarchingSquares/05_miniatures/site/"


func _initialize() -> void:
	_derouler()


func _derouler() -> void:
	DirAccess.make_dir_recursive_absolute(SORTIE)
	root.size = Vector2i(1920, 1080)
	var e: Control = load("res://ui/coins/editeur.tscn").instantiate()
	root.add_child(e)
	for i in 4:
		await process_frame
	var z: Control = e._zone()
	e._apply_margins()
	z.fit()
	await _photo("01_guide")

	# Le tileset d'essai, et une variante fleurie du dessus plein, créée sur place.
	e._peinture = Essai.peindre(16)
	z.adopt(e._peinture, e._meta, e._guide, e._guide_mat)
	var plein := Archetypes.numero(Modele.DESSUS, 15, 0)
	for i: int in z.rendu.pose_de.size():
		var ip: int = z.rendu.pose_de[i]
		if ip >= 0 and z.rendu.image_de_pose[ip] == Vector2i(plein, 0):
			z._hover_pixel = Vector2i(i % z.rendu.largeur(), i / z.rendu.largeur())
			break
	z.nouvelle_variante()
	for f: Vector2i in [Vector2i(3, 4), Vector2i(11, 2), Vector2i(7, 10), Vector2i(13, 12), Vector2i(4, 13)]:
		e._peinture.paint(Vector2i(plein, 1), f.x, f.y, Color(0.95, 0.9, 0.35))
		e._peinture.paint(Vector2i(plein, 1), f.x + 1, f.y, Color(0.98, 0.55, 0.6))
	z.reconstruire()
	e._refresh_counters()
	z._tile_px = 32.0
	z._origin = Vector2(270 + (1310 - 36 * 32) / 2.0, 40)
	z.queue_redraw()
	await _photo("02_guide_peint")

	# De près : les points de jonction et la tuile survolée en grand.
	z._tile_px = 64.0
	z._origin = Vector2(-1350, -420)
	var survol := Vector2i(700, 420)
	for i: int in z.rendu.pose_de.size():
		var ip2: int = z.rendu.pose_de[i]
		if ip2 >= 0 and z.rendu.poses[ip2][0] == Modele.HAUT:
			var p := Vector2i(i % z.rendu.largeur(), i / z.rendu.largeur())
			if p.x > 500 and p.y > 200:
				survol = p
				break
	z._hover_pixel = survol
	z._origin = Vector2(900, 520) - Vector2(survol) * z._px()
	z._survoler(survol)
	z.queue_redraw()
	await _photo("03_jonctions")

	# La matière 1 : ses quinze formes sur le paysage.
	(e.get_node("%ModeChoice") as OptionButton).select(1)
	await e._on_paint_selected(1)
	e._on_grid_toggled(true)
	z._tile_px = 32.0
	z._origin = Vector2(270 + (1310 - 36 * 32) / 2.0, 40)
	z.queue_redraw()
	await _photo("04_matiere")
	(e.get_node("%ModeChoice") as OptionButton).select(0)
	await e._on_paint_selected(0)

	# Le mode Test : un monde sculpté, plateaux empilés, sable, variantes tirées.
	z.relief = _beau_monde()
	z.meta.relief = z.relief
	e.choisir_salle(e.TEST)
	z._tile_px = 32.0
	z._origin = Vector2(270 + (1310 - 40 * 32) / 2.0, 30 - 32 * 2)
	z.queue_redraw()
	await _photo("05_test")

	# Le greffon : le même monde posé par un MarchingSquaresWorld, la planche exportée.
	var exp := Travail.exporter(e._peinture, e._meta, ProjectSettings.globalize_path("user://photo_site"))
	var relief: Dictionary = z.relief
	e.queue_free()
	await process_frame
	var fond := ColorRect.new()
	fond.color = Color(0.08, 0.1, 0.16)
	fond.size = Vector2(1920, 1080)
	root.add_child(fond)
	var monde: Node2D = Monde.new()
	monde.tileset = exp[1]
	monde.columns = relief.colonnes
	monde.rows = relief.rangees
	monde.heights = relief.h
	monde.materials = relief.mat
	monde.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var echelle := floorf(minf(1920.0 / (relief.colonnes * 16), 1080.0 / ((relief.rangees + 5) * 16)))
	monde.scale = Vector2(echelle, echelle)
	monde.position = Vector2((1920 - relief.colonnes * 16 * echelle) / 2, 5 * 16 * echelle + (1080 - (relief.rangees + 5) * 16 * echelle) / 2)
	root.add_child(monde)
	await process_frame
	await _photo("06_greffon")
	quit(0)


## Un monde de 40 × 22 : une grande terrasse à trois étages, un éperon, deux îlots, une niche, et du sable.
func _beau_monde() -> Dictionary:
	var c := 40
	var r := 22
	var larg := c + 1
	var h := PackedInt32Array()
	h.resize(larg * (r + 1))
	var mat := PackedInt32Array()
	mat.resize(h.size())
	for j in r + 1:
		for x in larg:
			var v := 0
			if pow((x - 13) / 9.5, 2) + pow((j - 11) / 7.0, 2) <= 1.0:
				v = 2
			if pow((x - 12) / 6.0, 2) + pow((j - 9) / 4.0, 2) <= 1.0:
				v = 4
			if pow((x - 11) / 2.6, 2) + pow((j - 8) / 1.8, 2) <= 1.0:
				v = 6
			if x >= 26 and x <= 35 and j >= 4 and j <= 9:
				v = 3
			if x >= 29 and x <= 33 and j >= 13 and j <= 18:
				v = 1
			if pow((x - 25) / 1.6, 2) + pow((j - 15) / 1.6, 2) <= 1.0:
				v = 2
			h[j * larg + x] = v
			if pow((x - 31) / 6.0, 2) + pow((j - 16) / 4.5, 2) <= 1.0 or pow((x - 5) / 3.5, 2) + pow((j - 18) / 2.5, 2) <= 1.0:
				mat[j * larg + x] = 1
			if x < 1 or j < 1 or x > c - 1 or j > r - 1:
				h[j * larg + x] = 0
	h[17 * larg + 13] = 0
	h[16 * larg + 13] = 0
	# Un monde posé d'un coup, sans le pinceau : ses selles se comblent (la règle du 4 novembre 2026).
	Modele.combler_selles(h, mat, c, r)
	return {"h": h, "mat": mat, "colonnes": c, "rangees": r}


func _photo(nom: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SORTIE + nom + ".png")
	print("photo : " + nom)
