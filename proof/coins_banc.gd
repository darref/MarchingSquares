extends SceneTree

## LE BANC DU MODÈLE PAR LES COINS — avant toute peinture, la preuve (Jordan, 4 novembre 2026 : « avant de commencer à
## calculer quoi que ce soit, nous soyons déjà sûrs d'arriver au bout »).
##
## Pour des centaines de reliefs tirés au sort (plateaux empilés de toutes hauteurs, et du bruit pur, le cas hostile),
## deux images de la MÊME scène, pixel par pixel :
##   L'ORACLE   un lancer de rayons EXACT sur le vrai relief 3D (la hauteur en un point = la plus haute couche dont la
##              forme le contient ; les falaises verticales ; la projection de trois-quarts : écran y = monde y − z) ;
##              chaque pixel dit ce qu'il voit : quelle surface, ou quelle unité de falaise, avec son rôle (lèvre, pied) ;
##   L'ASSEMBLAGE  les archétypes posés par `core/coins/modele.gd`, dans son ordre, chacun ne dépendant que de sa clé.
## Le modèle est juste quand les deux sont IDENTIQUES partout. Puis le RECENSEMENT : toutes les clés possibles, groupées
## par image, donnent le vocabulaire FERMÉ — compté, pas chassé.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://proof/coins_banc.gd [-- mondes=200 casse=8]
## Rend 0 si tout est identique. Images : D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/.

const Forme := preload("res://core/coins/forme.gd")
const Modele := preload("res://core/coins/modele.gd")
const SORTIE := "D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/"
const SORTIE_GRANDE := "D:/SpannerGames/ATELIER/MarchingSquares/banc_coins/grand/"

var _casse := 8           # pixels par case


func _initialize() -> void:
	var mondes := 200
	for a in OS.get_cmdline_user_args():
		if a.begins_with("mondes="):
			mondes = int(a.substr(7))
		elif a.begins_with("casse="):
			_casse = int(a.substr(6))
	DirAccess.make_dir_recursive_absolute(SORTIE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261104
	var total_pixels := 0
	var total_ecarts := 0
	var mondes_faux := 0
	var cles_vues := {}
	for m in mondes:
		var hostile := m % 4 == 3
		var monde := _tirer(rng, 18 + rng.randi_range(0, 10), 12 + rng.randi_range(0, 8), hostile)
		var r := _comparer(monde, cles_vues, m < 3)
		total_pixels += int(r.pixels)
		total_ecarts += int(r.ecarts)
		if int(r.ecarts) > 0:
			mondes_faux += 1
			if mondes_faux <= 3:
				print("ÉCART monde %d (%s) : %d pixels — %s" % [m, "bruit" if hostile else "plateaux", r.ecarts, r.premier])
				_images(monde, "ecart_%d" % m)
		if m < 3:
			_images(monde, "monde_%d" % m)
	print("mondes : %d ; pixels comparés : %d ; écarts : %d ; mondes faux : %d" % [mondes, total_pixels, total_ecarts, mondes_faux])
	var ferme := _recenser()
	var hors := 0
	for k: String in cles_vues:
		if not ferme.cles.has(k):
			hors += 1
	print("vocabulaire FERMÉ : %d dessus, %d hauts, %d bas = %d archétypes distincts (%d clés) ; clés posées par les mondes : %d, hors du recensement : %d"
			% [ferme.dessus, ferme.hauts, ferme.bas, ferme.dessus + ferme.hauts + ferme.bas, ferme.cles.size(), cles_vues.size(), hors])
	quit(1 if total_ecarts > 0 or hors > 0 else 0)


# ── les reliefs ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _tirer(rng: RandomNumberGenerator, colonnes: int, rangees: int, hostile: bool) -> Dictionary:
	var larg := colonnes + 1
	var h := PackedInt32Array()
	h.resize(larg * (rangees + 1))
	if hostile:
		for j in rangees + 1:
			for x in larg:
				h[j * larg + x] = rng.randi_range(0, 5)
	else:
		for k in rng.randi_range(3, 9):
			var cx := rng.randi_range(0, colonnes)
			var cy := rng.randi_range(0, rangees)
			var rx := rng.randi_range(1, 7)
			var ry := rng.randi_range(1, 5)
			var d := rng.randi_range(1, 3)
			var disque := rng.randf() < 0.5
			for j in rangees + 1:
				for x in larg:
					var dedans := (absi(x - cx) <= rx and absi(j - cy) <= ry) if not disque \
							else (pow(float(x - cx) / rx, 2) + pow(float(j - cy) / ry, 2) <= 1.0)
					if dedans:
						h[j * larg + x] = mini(h[j * larg + x] + d, 9)
	# Le bord du monde reste au sol : une falaise ne tombe jamais hors de la carte.
	for j in rangees + 1:
		for x in larg:
			if x < 1 or j < 1 or x > colonnes - 1 or j > rangees - 1:
				h[j * larg + x] = 0
	return {"h": h, "colonnes": colonnes, "rangees": rangees}


# ── l'assemblage ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _assembler(monde: Dictionary, hmax: int, cles: Dictionary) -> PackedInt32Array:
	var w := int(monde.colonnes) * _casse
	var hpx := (int(monde.rangees) + hmax + 1) * _casse
	var img := PackedInt32Array()
	img.resize(w * hpx)
	for p: Array in Modele.poses(monde.h, monde.colonnes, monde.rangees):
		var sorte: int = p[0]
		var L: int = p[1]
		var cle := "%d:%d:%d" % [sorte, p[4], p[5] if sorte != Modele.DESSUS else 0]
		if cles != null:
			cles[cle] = true
		var x0: int = int(p[2]) * _casse
		var y0: int = (int(p[3]) + hmax) * _casse
		for py in _casse:
			for px in _casse:
				var e := Modele.etiquette(sorte, L, p[4], p[5], (px + 0.5) / _casse, (py + 0.5) / _casse)
				if e != 0:
					img[(y0 + py) * w + x0 + px] = e
	return img


# ── l'oracle : un lancer de rayons exact ─────────────────────────────────────────────────────────────────────────────

func _intervalle(monde: Dictionary, i: int, j: int, L: int, u: float) -> Vector2:
	if L == 0:
		return Vector2(0, 1)
	return Forme.colonne(Modele.config(monde.h, int(monde.colonnes) + 1, i, j, L), u)


func _hauteur(monde: Dictionary, x: float, wy: float, hmax: int) -> int:
	var j := floori(wy)
	if j < 0 or j >= int(monde.rangees):
		return -1
	var i := floori(x)
	var u := x - i
	var v := wy - j
	for L in range(hmax, 0, -1):
		var iv := _intervalle(monde, i, j, L, u)
		if iv.x >= 0.0 and v >= iv.x - 1e-9 and v <= iv.y + 1e-9:
			return L
	return 0


func _oracle(monde: Dictionary, x: float, sy: float, hmax: int) -> int:
	var i := floori(x)
	var u := x - i
	var meilleur := -INF
	var Lm := -1
	for L in range(hmax, -1, -1):
		var Y := sy + L
		var j := mini(floori(Y), int(monde.rangees) - 1)
		while j >= 0:
			var iv := _intervalle(monde, i, j, L, u)
			if iv.x >= 0.0 and j + iv.x <= Y:
				var cand := minf(j + iv.y, Y)
				if cand > meilleur + 1e-9:
					meilleur = cand
					Lm = L
				break
			j -= 1
	if Lm < 0:
		return 0
	if absf(meilleur - (sy + Lm)) < 1e-9:
		return Modele.lab(Modele.DESSUS, Lm, 0)
	if Lm == 0:
		return 0            # le bord sud de la carte : hors du monde
	var z := meilleur - sy
	var unite := ceili(z - 1e-9)
	var hn := _hauteur(monde, x, meilleur - 1e-7, hmax)
	var hs := _hauteur(monde, x, meilleur + 1e-7, hmax)
	var jb := floori(meilleur - 1e-9)
	var case := floori(sy)
	if case == jb - unite:
		return Modele.lab(Modele.HAUT, unite, 1 if unite == hn else 0)
	if case == jb - unite + 1:
		return Modele.lab(Modele.BAS, unite, 1 if unite - 1 == hs else 0)
	return 999


func _comparer(monde: Dictionary, cles: Dictionary, garder: bool) -> Dictionary:
	var hmax := 0
	for v: int in monde.h:
		hmax = maxi(hmax, v)
	var asm := _assembler(monde, hmax, cles)
	var w := int(monde.colonnes) * _casse
	var hpx := asm.size() / w
	var ecarts := 0
	var premier := ""
	for py in hpx:
		var sy := -hmax + (py + 0.5) / _casse
		for px in w:
			var x := (px + 0.5) / _casse
			var o := _oracle(monde, x, sy, hmax)
			var a := asm[py * w + px]
			if o != a:
				ecarts += 1
				if premier == "":
					premier = "pixel (%d,%d) oracle %s / assemblage %s" % [px, py, _nom(o), _nom(a)]
	return {"pixels": w * hpx, "ecarts": ecarts, "premier": premier}


func _nom(e: int) -> String:
	if e == 0:
		return "rien"
	if e == 999:
		return "INCLASSABLE"
	var s: String = ["", "dessus", "haut", "bas"][e & 3]
	var role := ""
	if (e & 3) == Modele.HAUT:
		role = " lèvre" if (e >> 10) & 1 else " corps"
	elif (e & 3) == Modele.BAS:
		role = " pied" if (e >> 10) & 1 else " corps"
	return "%s L%d%s" % [s, (e >> 2) & 255, role]


# ── le recensement : le vocabulaire fermé ────────────────────────────────────────────────────────────────────────────

func _recenser() -> Dictionary:
	var images := {}
	var cles := {}
	var compte := {Modele.DESSUS: {}, Modele.HAUT: {}, Modele.BAS: {}}
	for c in range(1, 16):
		_noter(Modele.DESSUS, c, 0, images, cles, compte)
		if Modele.a_falaise(c):
			for cv in 16:
				if (cv & c) == cv:          # la couche du dessus est contenue
					_noter(Modele.HAUT, c, cv, images, cles, compte)
				if (cv & c) == c:           # la couche du dessous contient
					_noter(Modele.BAS, c, cv, images, cles, compte)
	return {"cles": cles, "dessus": compte[Modele.DESSUS].size(), "hauts": compte[Modele.HAUT].size(),
			"bas": compte[Modele.BAS].size()}


func _noter(sorte: int, c: int, cv: int, images: Dictionary, cles: Dictionary, compte: Dictionary) -> void:
	cles["%d:%d:%d" % [sorte, c, cv]] = true
	var t := 16
	var sig := PackedInt32Array()
	for py in t:
		for px in t:
			sig.append(Modele.etiquette(sorte, 1, c, cv, (px + 0.5) / t, (py + 0.5) / t))
	compte[sorte][str(hash(sig))] = true


# ── les images (le tileset de TEST : des aplats calculés, aucun art) ─────────────────────────────────────────────────

func _couleur(e: int) -> Color:
	if e == 0:
		return Color(0.08, 0.1, 0.16)
	if e == 999:
		return Color(1, 0, 1)
	var L := (e >> 2) & 255
	match e & 3:
		Modele.DESSUS:
			return Color(0.25, 0.45, 0.2).lerp(Color(0.75, 0.9, 0.45), clampf(L / 6.0, 0, 1))
		Modele.HAUT:
			return Color(0.92, 0.8, 0.55) if (e >> 10) & 1 else Color(0.6, 0.48, 0.38)
		Modele.BAS:
			return Color(0.3, 0.22, 0.17) if (e >> 10) & 1 else Color(0.55, 0.44, 0.35)
	return Color.MAGENTA


func _images(monde: Dictionary, nom: String) -> void:
	var hmax := 0
	for v: int in monde.h:
		hmax = maxi(hmax, v)
	var asm := _assembler(monde, hmax, {})
	var w := int(monde.colonnes) * _casse
	var hpx := asm.size() / w
	var a := Image.create(w, hpx, false, Image.FORMAT_RGB8)
	var o := Image.create(w, hpx, false, Image.FORMAT_RGB8)
	for py in hpx:
		var sy := -hmax + (py + 0.5) / _casse
		for px in w:
			var oe := _oracle(monde, (px + 0.5) / _casse, sy, hmax)
			var col := _couleur(asm[py * w + px])
			# Un trait sombre là où l'étiquette change : on lit les formes (le contour d'une surface, la lèvre, le pied).
			if (px + 1 < w and asm[py * w + px + 1] != asm[py * w + px]) or (py + 1 < hpx and asm[(py + 1) * w + px] != asm[py * w + px]):
				col = col.darkened(0.45)
			a.set_pixel(px, py, col)
			o.set_pixel(px, py, _couleur(oe) if oe == asm[py * w + px] else Color(1, 0, 1))
	var dossier := SORTIE_GRANDE if _casse >= 16 else SORTIE
	a.save_png(dossier + nom + "_assemblage.png")
	o.save_png(dossier + nom + "_oracle.png")
