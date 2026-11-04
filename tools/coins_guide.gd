extends SceneTree

## LE GUIDE DU MODÈLE PAR LES COINS — le paysage sur lequel l'artiste peindra (Jordan, 4 novembre 2026 : « le guide, le
## modèle mathématique et l'outil de peinture, les trois doivent fonctionner en même temps »). Il doit porter les 35
## archétypes ET les 261 jonctions (`core/coins/jonctions.gd`) : alors toute couture qu'un export pourra produire est déjà
## sous les yeux du peintre.
##
## Comment, sans chasse : (1) des paysages tirés au sort — plateaux et terrasses de toutes hauteurs, niches, piliers — et
## l'on garde celui qui couvre le plus ; (2) chaque jonction qui manque se POSE : elle ne dépend que de six coins, donc
## recopier ces six coins quelque part (à l'écart des autres, décalés en hauteur si l'on veut) la garantit ; (3) le
## contrôle final : couverture TOTALE, sinon rien ne sort.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://tools/coins_guide.gd
## Sortie : guides/coins.txt (les hauteurs des coins) ; l'aperçu au tileset de test dans
## D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/guide.png.

const Modele := preload("res://addons/marching_squares/modele.gd")
const Jonctions := preload("res://core/coins/jonctions.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")

const COLONNES := 36
const RANGEES := 22
const TIRAGES := 300
const FICHIER := "res://guides/coins.txt"
const APERCU := "D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/guide.png"


func _initialize() -> void:
	var ens := Jonctions.ensemble()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4112026
	var meilleur := {}
	var couvert := 0
	for t in TIRAGES:
		var m := _paysage(rng)
		var n := Jonctions.du_monde(m.h, m.colonnes, m.rangees).size()
		if n > couvert:
			couvert = n
			meilleur = m
	var vues := Jonctions.du_monde(meilleur.h, meilleur.colonnes, meilleur.rangees)
	print("paysage tiré : %d jonctions sur %d" % [vues.size(), ens.size()])
	vues = _incruster(meilleur, ens, vues, rng)
	var manquent: Array = []
	for k: String in ens:
		if not vues.has(k):
			manquent.append(k)
	print("paysage incrusté : %d jonctions sur %d ; à poser à part : %d" % [vues.size(), ens.size(), manquent.size()])
	var guide := _poser(meilleur, manquent, ens)
	var fin := Jonctions.du_monde(guide.h, guide.colonnes, guide.rangees)
	var trous := []
	for k: String in ens:
		if not fin.has(k):
			trous.append(k)
	var archetypes := {}
	for p: Array in Modele.poses(guide.h, guide.colonnes, guide.rangees):
		archetypes[Archetypes.numero(p[0], p[4], p[5])] = true
	print("guide %d × %d : jonctions %d / %d ; archétypes %d / %d" % [guide.colonnes, guide.rangees, fin.size(), ens.size(),
			archetypes.size(), Archetypes.liste().size()])
	if not trous.is_empty() or archetypes.size() != Archetypes.liste().size():
		printerr("⚠ GUIDE INCOMPLET — rien n'est écrit : %s" % str(trous.slice(0, 8)))
		quit(1)
		return
	_ecrire(guide)
	_apercu(guide)
	print("écrit : %s ; aperçu : %s" % [FICHIER, APERCU])
	quit(0)


# Un paysage : quelques grands plateaux étagés (terrasses), des niches creusées, des piliers, des marches.
func _paysage(rng: RandomNumberGenerator) -> Dictionary:
	var larg := COLONNES + 1
	var h := PackedInt32Array()
	h.resize(larg * (RANGEES + 1))
	for k in rng.randi_range(4, 8):
		var cx := rng.randi_range(3, COLONNES - 3)
		var cy := rng.randi_range(3, RANGEES - 3)
		var rx := rng.randi_range(2, 8)
		var ry := rng.randi_range(2, 6)
		var d := rng.randi_range(1, 3)
		var rond := rng.randf() < 0.5
		for j in RANGEES + 1:
			for x in larg:
				var dedans := (pow(float(x - cx) / rx, 2) + pow(float(j - cy) / ry, 2) <= 1.0) if rond \
						else (absi(x - cx) <= rx and absi(j - cy) <= ry)
				if dedans:
					h[j * larg + x] += d
	for k in rng.randi_range(2, 6):              # niches et piliers d'un coin
		var i := rng.randi_range(2, RANGEES - 2) * larg + rng.randi_range(2, COLONNES - 2)
		h[i] = maxi(0, h[i] + (rng.randi_range(1, 3) if rng.randf() < 0.5 else -rng.randi_range(1, 2)))
	_bordure(h, larg, RANGEES)
	return {"h": h, "colonnes": COLONNES, "rangees": RANGEES}


# Les jonctions manquantes, INCRUSTÉES dans le paysage : leurs six coins recopiés à un endroit tiré au sort, décalés à la
# hauteur du terrain (une jonction ne change pas quand tout son voisinage monte d'autant) ; on ne garde une incrustation
# que si la couverture MONTE — elle peut casser une jonction voisine, le compte le dit. Ce qui n'entre pas va à part.
func _incruster(m: Dictionary, ens: Dictionary, vues: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var larg := COLONNES + 1
	var h: PackedInt32Array = m.h
	var ordre: Array = ens.keys()
	for tour in 3:
		for k: String in ordre:
			if vues.has(k):
				continue
			var porteur: Array = ens[k]
			var pc: int = porteur[0]
			var pr: int = porteur[1]
			var ph: PackedInt32Array = porteur[2]
			var bas_min := 99
			for v: int in ph:
				bas_min = mini(bas_min, v)
			for essai in 40:
				var x0 := rng.randi_range(2, COLONNES - 2 - pc)
				var y0 := rng.randi_range(2, RANGEES - 2 - pr)
				var decale := maxi(0, h[y0 * larg + x0] - bas_min)
				var avant := PackedInt32Array()
				for j in pr + 1:
					for x in pc + 1:
						avant.append(h[(y0 + j) * larg + x0 + x])
						h[(y0 + j) * larg + x0 + x] = ph[j * (pc + 1) + x] + decale
				var apres := Jonctions.du_monde(h, COLONNES, RANGEES)
				if apres.size() > vues.size():
					vues = apres
					break
				var i := 0
				for j in pr + 1:
					for x in pc + 1:
						h[(y0 + j) * larg + x0 + x] = avant[i]
						i += 1
	m.h = h
	return vues


# Chaque jonction manquante : ses six coins recopiés dans une bande au sud, sur un pas de 4 coins (aucun coin partagé).
func _poser(m: Dictionary, manquent: Array, ens: Dictionary) -> Dictionary:
	if manquent.is_empty():
		return m
	var par_rangee := (COLONNES - 2) / 4
	var bandes := int(ceil(float(manquent.size()) / par_rangee))
	var rangees := RANGEES + bandes * 4
	var larg := COLONNES + 1
	var h := PackedInt32Array()
	h.resize(larg * (rangees + 1))
	var source: PackedInt32Array = m.h
	for i: int in source.size():
		h[i] = source[i]
	for n in manquent.size():
		var porteur: Array = ens[manquent[n]]
		var pc: int = porteur[0]
		var pr: int = porteur[1]
		var ph: PackedInt32Array = porteur[2]
		var x0 := 2 + (n % par_rangee) * 4
		var y0 := RANGEES + 1 + (n / par_rangee) * 4
		for j in pr + 1:
			for x in pc + 1:
				h[(y0 + j) * larg + x0 + x] = ph[j * (pc + 1) + x]
	_bordure(h, larg, rangees)
	return {"h": h, "colonnes": COLONNES, "rangees": rangees}


func _bordure(h: PackedInt32Array, larg: int, rangees: int) -> void:
	for j in rangees + 1:
		for x in larg:
			if x == 0 or j == 0 or x == larg - 1 or j == rangees:
				h[j * larg + x] = 0


func _ecrire(g: Dictionary) -> void:
	var f := FileAccess.open(FICHIER, FileAccess.WRITE)
	f.store_line("%d %d" % [g.colonnes, g.rangees])
	var larg: int = g.colonnes + 1
	for j: int in int(g.rangees) + 1:
		var ligne := PackedStringArray()
		for x in larg:
			ligne.append(str(g.h[j * larg + x]))
		f.store_line(" ".join(ligne))


func _apercu(g: Dictionary) -> void:
	var casse := 16
	var hmax := 0
	for v: int in g.h:
		hmax = maxi(hmax, v)
	var w: int = g.colonnes * casse
	var hpx: int = (g.rangees + hmax + 1) * casse
	var lab := PackedInt32Array()
	lab.resize(w * hpx)
	for p: Array in Modele.poses(g.h, g.colonnes, g.rangees):
		var x0: int = int(p[2]) * casse
		var y0: int = (int(p[3]) + hmax) * casse
		for py in casse:
			for px in casse:
				var e := Modele.etiquette(p[0], p[1], p[4], p[5], (px + 0.5) / casse, (py + 0.5) / casse)
				if e != 0:
					lab[(y0 + py) * w + x0 + px] = e
	var img := Image.create(w, hpx, false, Image.FORMAT_RGB8)
	for py in hpx:
		for px in w:
			var e := lab[py * w + px]
			var col := _couleur(e)
			if (px + 1 < w and lab[py * w + px + 1] != e) or (py + 1 < hpx and lab[(py + 1) * w + px] != e):
				col = col.darkened(0.45)
			img.set_pixel(px, py, col)
	img.save_png(APERCU)


func _couleur(e: int) -> Color:
	if e == 0:
		return Color(0.08, 0.1, 0.16)
	var L := (e >> 2) & 255
	match e & 3:
		Modele.DESSUS:
			return Color(0.25, 0.45, 0.2).lerp(Color(0.75, 0.9, 0.45), clampf(L / 6.0, 0, 1))
		Modele.HAUT:
			return Color(0.92, 0.8, 0.55) if (e >> 10) & 1 else Color(0.6, 0.48, 0.38)
		Modele.BAS:
			return Color(0.3, 0.22, 0.17) if (e >> 10) & 1 else Color(0.55, 0.44, 0.35)
	return Color.MAGENTA
