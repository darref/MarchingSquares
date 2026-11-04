extends SceneTree

## LE GUIDE DES MATIÈRES — un champ de matière posé SUR le paysage du guide (`guides/coins.txt`), pour que l'artiste
## peigne une matière là où elle vivra : sur des plateaux, au bord des falaises, contre les autres hauteurs. Une matière
## se pose avec les quinze formes du dessus ; le champ retenu les montre TOUTES, et le plus de raccords possible entre
## deux tuiles voisines (comptés, dits : pas de fermeture prétendue au-delà de ce qui est compté).
## Parmi 400 champs de taches tirés au sort (graine fixe), le meilleur : 15/15 formes vues, puis le plus de raccords ;
## ceux qui manquent encore sont incrustés là où le relief est plat. Un guide incomplet est REFUSÉ (mesuré : 114/114).
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://tools/coins_guide_matieres.gd
## Écrit `guides/coins_matieres.txt` (même format que le guide : « colonnes rangées », puis un rang par coin).

const Modele := preload("res://addons/marching_squares/modele.gd")
const Rendu := preload("res://core/coins/rendu.gd")
const Atelier := preload("res://ui/coins/atelier.gd")

const SORTIE := "res://guides/coins_matieres.txt"


func _initialize() -> void:
	var g: Dictionary = Atelier.lire_guide("res://guides/coins.txt")
	var larg: int = g.colonnes + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261104
	var meilleur := {}
	var score_max := -1
	for essai in 400:
		var mat := PackedInt32Array()
		mat.resize(g.h.size())
		for k in rng.randi_range(4, 14):
			var cx := rng.randi_range(0, g.colonnes)
			var cy := rng.randi_range(0, g.rangees)
			var rx := rng.randi_range(1, 6)
			var ry := rng.randi_range(1, 4)
			var rect := rng.randf() < 0.4
			for j: int in g.rangees + 1:
				for x: int in larg:
					var d := (absi(x - cx) <= rx and absi(j - cy) <= ry) if rect \
							else pow(float(x - cx) / rx, 2) + pow(float(j - cy) / ry, 2) <= 1.0
					if d:
						mat[j * larg + x] = 1
		var m := mesurer(g, mat)
		var score: int = int(m.formes) * 1000 + int(m.raccords)
		if score > score_max:
			score_max = score
			meilleur = {"mat": mat, "mesure": m, "essai": essai}
	# Les raccords qui manquent encore sont INCRUSTÉS, un à un, là où le relief est plat sur les six coins de la paire :
	# gardé seulement si le compte monte (et que les quinze formes restent vues).
	var mat_b: PackedInt32Array = meilleur.mat
	for paire: Array in manquants(meilleur.mesure):
		var fait := false
		for j: int in range(1, g.rangees - 1):
			for x: int in range(1, g.colonnes - 1):
				var coins := _coins_paire(paire[0], larg, x, j)
				var plat := true
				for c: int in coins:
					plat = plat and c < g.h.size() and g.h[c] == g.h[coins[0]]
				if not plat:
					continue
				var essai := mat_b.duplicate()
				var bits := _bits_paire(paire[0], paire[1], paire[2])
				for k in 6:
					essai[coins[k]] = bits[k]
				var mm := mesurer(g, essai)
				if int(mm.formes) == 15 and int(mm.raccords) > int(meilleur.mesure.raccords):
					mat_b = essai
					meilleur.mesure = mm
					fait = true
					break
			if fait:
				break
	meilleur.mat = mat_b
	var mesure: Dictionary = meilleur.mesure
	print("champ retenu : essai %d ; formes de matière vues %d / 15 ; raccords vus %d (sur %d possibles)"
			% [meilleur.essai, mesure.formes, mesure.raccords, mesure.possibles])
	if int(mesure.formes) < 15 or int(mesure.raccords) < int(mesure.possibles):
		printerr("GUIDE DES MATIÈRES INCOMPLET : refusé")
		quit(1)
		return
	var f := FileAccess.open(SORTIE, FileAccess.WRITE)
	f.store_line("%d %d" % [g.colonnes, g.rangees])
	var mat: PackedInt32Array = meilleur.mat
	for j: int in g.rangees + 1:
		var ligne := PackedStringArray()
		for x: int in larg:
			ligne.append(str(mat[j * larg + x]))
		f.store_line(" ".join(ligne))
	print("écrit : " + ProjectSettings.globalize_path(SORTIE))
	quit(0)


## Ce que le champ montre : les formes de matière VISIBLES (au moins un pixel), et les raccords visibles — deux poses de
## matière voisines (même couche, à droite ou au-dessous) dont chacune se voit, désignées par leurs deux configurations.
static func mesurer(g: Dictionary, mat: PackedInt32Array) -> Dictionary:
	var r := Rendu.new(8)
	r.construire(g.h, g.colonnes, g.rangees, null, mat)
	var vues := {}
	for i in r.pose_de.size():
		if r.pose_de[i] >= 0:
			vues[r.pose_de[i]] = true
	var formes := {}
	var place := {}
	for ip: int in vues:
		var p: Array = r.poses[ip]
		if p[0] != Modele.MATIERE:
			continue
		formes[p[4]] = true
		place["%d:%d:%d" % [p[1], p[2], p[3]]] = p[4]
	var raccords := {}
	for k: String in place:
		var t := k.split(":")
		var L := int(t[0])
		var x := int(t[1])
		var y := int(t[2])
		var droite := "%d:%d:%d" % [L, x + 1, y]
		var dessous := "%d:%d:%d" % [L, x, y + 1]
		if place.has(droite):
			raccords["D%d-%d" % [place[k], place[droite]]] = true
		if place.has(dessous):
			raccords["V%d-%d" % [place[k], place[dessous]]] = true
	# Les raccords possibles : deux configurations non vides qui s'accordent sur les deux coins qu'elles partagent.
	var possibles := 0
	for a in range(1, 16):
		for b in range(1, 16):
			if ((a >> 2) & 1) == ((b >> 3) & 1) and (a & 1) == ((b >> 1) & 1):
				possibles += 1
			if ((a >> 1) & 1) == ((b >> 3) & 1) and (a & 1) == ((b >> 2) & 1):
				possibles += 1
	return {"formes": formes.size(), "raccords": raccords.size(), "possibles": possibles, "vus": raccords}


## Les raccords possibles qui ne sont pas vus : [sens (« D » ou « V »), config a, config b].
static func manquants(mesure: Dictionary) -> Array:
	var sortie := []
	for a in range(1, 16):
		for b in range(1, 16):
			if ((a >> 2) & 1) == ((b >> 3) & 1) and (a & 1) == ((b >> 1) & 1) and not mesure.vus.has("D%d-%d" % [a, b]):
				sortie.append(["D", a, b])
			if ((a >> 1) & 1) == ((b >> 3) & 1) and (a & 1) == ((b >> 2) & 1) and not mesure.vus.has("V%d-%d" % [a, b]):
				sortie.append(["V", a, b])
	return sortie


## Les six coins d'une paire de tuiles dont la première est (x, j) : à droite (D) ou au-dessous (V).
static func _coins_paire(sens: String, larg: int, x: int, j: int) -> Array[int]:
	if sens == "D":
		return [j * larg + x, j * larg + x + 1, j * larg + x + 2, (j + 1) * larg + x, (j + 1) * larg + x + 1, (j + 1) * larg + x + 2]
	return [j * larg + x, j * larg + x + 1, (j + 1) * larg + x, (j + 1) * larg + x + 1, (j + 2) * larg + x, (j + 2) * larg + x + 1]


## Les rangs (0/1) des six coins, dans l'ordre de `_coins_paire`, pour les configurations a puis b.
static func _bits_paire(sens: String, a: int, b: int) -> Array[int]:
	var nw := func(c: int) -> int: return (c >> 3) & 1
	var ne := func(c: int) -> int: return (c >> 2) & 1
	var sw := func(c: int) -> int: return (c >> 1) & 1
	var se := func(c: int) -> int: return c & 1
	if sens == "D":
		return [nw.call(a), ne.call(a), ne.call(b), sw.call(a), se.call(a), se.call(b)]
	return [nw.call(a), ne.call(a), sw.call(a), se.call(a), sw.call(b), se.call(b)]
