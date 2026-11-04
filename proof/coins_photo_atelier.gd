extends SceneTree

## L'ATELIER À L'IMAGE — AVEC FENÊTRE. Les 35 archétypes sont remplis d'un motif d'ESSAI calculé (herbe, roche, lèvre
## claire, pied sombre — un motif qui dépend du seul pixel local, donc qui se raccorde de lui-même) : ce n'est PAS un
## tileset livré (charte : rien n'est fabriqué à la place de l'artiste), seulement de quoi voir le guide et le mode
## relief rendus. Photos : D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/atelier_*.png
##   Godot_v4.7-stable_win64_console.exe --path D:/MarchingSquares --resolution 1600x900 --script res://proof/coins_photo_atelier.gd

const Archetypes := preload("res://core/coins/archetypes.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const Travail := preload("res://core/coins/travail.gd")
const Monde := preload("res://addons/marching_squares/world.gd")
const SORTIE := "D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/"


func _initialize() -> void:
	_derouler()


func _derouler() -> void:
	var a: Control = load("res://ui/coins/atelier.tscn").instantiate()
	root.add_child(a)
	await process_frame
	await process_frame
	await _photo("atelier_guide_vierge")
	var res: int = a.peinture.resolution
	for n in Archetypes.liste().size():
		var m := Rendu.masque_de(n, res)
		for y in res:
			for x in res:
				var e := m[y * res + x]
				if e != 0:
					var c := _motif(e, x, y)
					# Le BORD du dessus : un liseré là où la forme s'arrête DANS la tuile — c'est l'artiste qui le dessine,
					# dans l'archétype de dessus, puisque ce dessus sert à toutes les hauteurs.
					if (e & 3) == Modele.DESSUS and _au_bord(m, res, x, y):
						c = Color(0.16, 0.3, 0.13)
					a.peinture.paint(Vector2i(n, 0), x, y, c)
	# LA MATIÈRE 1 (du sable) : ses quinze dessus, avec une transition FONDUE peinte dans la forme (le sable s'éclaircit
	# vers l'herbe sur trois pixels) — jamais un bord en escalier (charte du studio, 21 octobre 2026).
	for n in Archetypes.liste().size():
		if Archetypes.liste()[n].sorte != Modele.DESSUS:
			continue
		var m := Rendu.masque_de(n, res)
		for y in res:
			for x in res:
				if m[y * res + x] != 0:
					var d := _distance_au_bord(m, res, x, y)
					var sable := Color(0.86, 0.76, 0.5).lerp(Color(0.92, 0.83, 0.58), float((x * 31 + y * 17) % 7) / 7.0)
					var c := sable.lerp(Color(0.33, 0.58, 0.26), clampf((3.0 - d) / 3.5, 0.0, 0.8)) if d < 3 else sable
					a.peinture.paint(Vector2i(n, 10), x, y, c)
	a._reposer()
	# UNE VARIANTE du dessus plein : quelques fleurs, créée sur place (V) depuis une apparition du guide.
	var plein := Archetypes.numero(Modele.DESSUS, 15, 0)
	var ici := Vector2i(-1, -1)
	for i: int in a.rendu.pose_de.size():
		var ip: int = a.rendu.pose_de[i]
		if ip >= 0 and a.rendu.image_de_pose[ip] == Vector2i(plein, 0):
			ici = Vector2i(i % a.rendu.largeur(), i / a.rendu.largeur())
			break
	a.nouvelle_variante(ici)
	for f: Vector2i in [Vector2i(3, 4), Vector2i(11, 2), Vector2i(7, 10), Vector2i(13, 12), Vector2i(4, 13)]:
		a.peinture.paint(Vector2i(plein, 1), f.x, f.y, Color(0.95, 0.9, 0.35))
		a.peinture.paint(Vector2i(plein, 1), f.x + 1, f.y, Color(0.98, 0.55, 0.6))
	a.zoom = 2
	a._reposer()
	await process_frame
	await _photo("atelier_guide_peint")
	a.zoom = 4
	a.origine = Vector2(-700, -200)
	a._basculer_jonctions()
	a._placer()
	await process_frame
	await _photo("atelier_jonctions")
	a._basculer_jonctions()
	a.zoom = 2
	a.origine = Vector2(24, 64)
	a.choisir_matiere(1)
	await process_frame
	await _photo("atelier_guide_matiere")
	a.choisir_matiere(0)
	a._basculer()
	for k: int in 3:
		a.sculpter(Vector2i(16 * 16, (8 - 2 + a.rendu.hmax) * 16), 1)
	a.zoom = 3
	a.origine = Vector2(40, 70)
	a._placer()
	await process_frame
	await _photo("atelier_relief")
	# LE GREFFON : la planche exportée, un MarchingSquaresWorld dans une scène, dessiné par Godot lui-même.
	var exp := Travail.exporter(a.peinture, a.meta, ProjectSettings.globalize_path("user://photo_greffon"))
	var relief: Dictionary = a._relief
	a.queue_free()
	var monde: Node2D = Monde.new()
	monde.tileset = exp[1]
	monde.columns = relief.colonnes
	monde.rows = relief.rangees
	monde.heights = relief.h
	monde.materials = relief.mat
	monde.position = Vector2(40, 40 + 6 * 16 * 3)
	monde.scale = Vector2(3, 3)
	monde.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var fond := ColorRect.new()
	fond.color = Color(0.08, 0.1, 0.16)
	fond.size = Vector2(1600, 900)
	root.add_child(fond)
	root.add_child(monde)
	await process_frame
	await process_frame
	await _photo("greffon_monde")
	quit(0)


func _distance_au_bord(m: PackedInt32Array, res: int, x: int, y: int) -> float:
	var d := 9.0
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var q := Vector2i(x + dx, y + dy)
			if q.x >= 0 and q.y >= 0 and q.x < res and q.y < res and m[q.y * res + q.x] == 0:
				d = minf(d, Vector2(dx, dy).length())
	return d


func _au_bord(m: PackedInt32Array, res: int, x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q := Vector2i(x, y) + d
		if q.x >= 0 and q.y >= 0 and q.x < res and q.y < res and m[q.y * res + q.x] == 0:
			return true
	return false


func _motif(e: int, x: int, y: int) -> Color:
	var bruit := float((x * 73 + y * 151 + x * y * 7) % 17) / 17.0
	match e & 3:
		Modele.DESSUS:
			return Color(0.33, 0.58, 0.26).lerp(Color(0.45, 0.7, 0.32), bruit * 0.6)
		Modele.HAUT:
			if (e >> 10) & 1:
				return Color(0.86, 0.76, 0.52).lerp(Color(0.95, 0.86, 0.62), bruit * 0.5)
			return Color(0.52, 0.42, 0.34).lerp(Color(0.6, 0.5, 0.4), bruit)
		Modele.BAS:
			if (e >> 10) & 1:
				return Color(0.28, 0.21, 0.17).lerp(Color(0.34, 0.26, 0.2), bruit)
			return Color(0.5, 0.4, 0.32).lerp(Color(0.58, 0.47, 0.37), bruit)
	return Color.MAGENTA


func _photo(nom: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SORTIE + nom + ".png")
	print("photo : " + nom)
