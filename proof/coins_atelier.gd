extends SceneTree

## L'ATELIER DU MODÈLE PAR LES COINS, ÉPROUVÉ — headless, par ses fonctions publiques (`agir`, `sculpter`) comme le ferait
## la souris : le guide pose les 35 archétypes ; un pixel peint apparaît dans TOUTES les apparitions de son archétype ;
## le fond refuse le crayon ; le pot reste dans la forme ; l'annulation rend l'image ; le travail se relit à l'identique ;
## l'export porte la planche et la table des 79 clés ; le mode relief sculpte et rend avec les archétypes peints.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://proof/coins_atelier.gd

const Archetypes := preload("res://core/coins/archetypes.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Travail := preload("res://core/coins/travail.gd")

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
	var poses := 0
	for n in Archetypes.liste().size():
		if r.poses_de(n) > 0:
			poses += 1
	check(poses == 35, "le guide pose les 35 archétypes (%d)" % poses)

	# Peindre un pixel : il apparaît partout où l'archétype se voit, au même pixel local.
	var n := _le_plus_vu(r)
	var app := r.apparitions(n)
	var w := r.largeur()
	var i0 := app[0]
	var cible := r.sous(i0 % w, i0 / w)
	a.couleur = Color8(230, 25, 51)          # une couleur exacte en 8 bits : l'image est en RGBA8
	a.peinture.begin_stroke()
	a.agir(Vector2i(i0 % w, i0 / w))
	a.peinture.end_stroke()
	check(a.peinture.is_painted(Vector2i(n, 0)), "le crayon peint l'archétype %d" % n)
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
	var fond := -1
	for i in r.archetype_de.size():
		if r.archetype_de[i] < 0:
			fond = i
			break
	var avant: int = a.peinture.pixel_count(Vector2i(n, 0))
	a.agir(Vector2i(fond % w, fond / w))
	check(fond >= 0 and a.peinture.pixel_count(Vector2i(n, 0)) == avant, "le fond refuse le crayon")

	# L'annulation.
	a._rafraichir(a._numeros(a.peinture.undo()))
	check(not a.peinture.is_painted(Vector2i(n, 0)) and not r.image.get_pixel(i0 % w, i0 / w).is_equal_approx(a.couleur),
			"Ctrl+Z rend l'image du guide")

	# Le pot reste dans la forme.
	a.outil = a.Outil.POT
	a._dernier = Vector2i(-99999, -99999)
	a.agir(Vector2i(i0 % w, i0 / w))
	var masque := Rendu.masque_de(n, a.peinture.resolution)
	var dans := 0
	var hors := 0
	var res: int = a.peinture.resolution
	for y in res:
		for x in res:
			if a.peinture.pixel_at(Vector2i(n, 0), x, y).a > 0.0:
				if masque[y * res + x] != 0:
					dans += 1
				else:
					hors += 1
	var forme := 0
	for v: int in masque:
		if v != 0:
			forme += 1
	check(hors == 0 and dans == forme, "le pot remplit la forme, rien au-delà (%d / %d, hors %d)" % [dans, forme, hors])

	# Le travail se relit à l'identique.
	var chemin := "user://sonde_coins.mqcoins"
	check(Travail.sauver(a.peinture, chemin) == OK, "le travail s'enregistre")
	var relu: RefCounted = Travail.relire(chemin)
	check(relu != null and relu.image_of(Vector2i(n, 0)).get_data() == a.peinture.image_of(Vector2i(n, 0)).get_data(),
			"il se relit pixel pour pixel")

	# L'export.
	var sortie := Travail.exporter(a.peinture, ProjectSettings.globalize_path("user://sonde_export"))
	var manifeste: Variant = JSON.parse_string(FileAccess.get_file_as_string(sortie[1]))
	var table: Dictionary = manifeste.table if manifeste is Dictionary else {}
	var dans_bornes := true
	for k: String in table:
		dans_bornes = dans_bornes and int(table[k]) >= 0 and int(table[k]) < 35
	check(table.size() == 79 and dans_bornes, "le manifeste : les 79 clés vers 35 archétypes (%d)" % table.size())
	var planche := Image.load_from_file(sortie[0])
	check(planche != null and planche.get_width() == 7 * res and planche.get_height() == 5 * res, "la planche : 7 × 5 tuiles")

	# Le mode relief.
	a._basculer()
	check(a.mode_relief and a.rendu.colonnes == 24, "Tab : le relief de départ")
	var larg := 25
	var hav: int = a._relief.h[6 * larg + 10]
	var sy: int = (6 - hav + a.rendu.hmax) * res
	a.sculpter(Vector2i(10 * res, sy), 1)
	check(int(a._relief.h[6 * larg + 10]) == hav + 1, "un clic monte le coin le plus proche (%d → %d)" % [hav, a._relief.h[6 * larg + 10]])
	var peint_vu := false
	var r2: Rendu = a.rendu
	for i: int in r2.apparitions(n):
		if r2.image.get_pixel(i % r2.largeur(), i / r2.largeur()).a > 0.0 and a.peinture.pixel_at(Vector2i(n, 0), r2.local_de[i] % res, r2.local_de[i] / res).a > 0.0:
			peint_vu = true
			break
	check(peint_vu or r2.poses_de(n) == 0, "le relief se rend avec les archétypes peints")

	print("%d/%d" % [_ok, _ok + _faux])
	quit(1 if _faux else 0)


func _le_plus_vu(r: Rendu) -> int:
	var meilleur := 0
	for n in Archetypes.liste().size():
		if r.apparitions(n).size() > r.apparitions(meilleur).size():
			meilleur = n
	return meilleur
