extends SceneTree

## L'ATELIER À L'IMAGE — AVEC FENÊTRE. Les 35 archétypes sont remplis d'un motif d'ESSAI calculé (herbe, roche, lèvre
## claire, pied sombre — un motif qui dépend du seul pixel local, donc qui se raccorde de lui-même) : ce n'est PAS un
## tileset livré (charte : rien n'est fabriqué à la place de l'artiste), seulement de quoi voir le guide et le mode
## relief rendus. Photos : D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/atelier_*.png
##   Godot_v4.7-stable_win64_console.exe --path D:/MarchingSquares --resolution 1600x900 --script res://proof/coins_photo_atelier.gd

const Archetypes := preload("res://core/coins/archetypes.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Modele := preload("res://core/coins/modele.gd")
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
	a._reposer()
	a.zoom = 2
	a._placer()
	await process_frame
	await _photo("atelier_guide_peint")
	a._basculer()
	for k in 3:
		a.sculpter(Vector2i(16 * 16, (8 - 2 + a.rendu.hmax) * 16), 1)
	a.zoom = 3
	a.origine = Vector2(40, 70)
	a._placer()
	await process_frame
	await _photo("atelier_relief")
	quit(0)


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
