extends SceneTree

## CE QUE COÛTERAIT D'INTERDIRE LES RENCONTRES DIAGONALES (la question de Jordan, 4 novembre 2026 : « dans MarchingBlocks,
## nous avions interdit les rencontres diagonales […] est-ce que ce serait bien de faire la même chose ? »).
## Une rencontre diagonale est une SELLE : dans une tuile, deux coins opposés dedans et les deux autres dehors
## (configurations 6 et 9), à une couche quelconque. On compte, sans rien changer : les clés, les archétypes et les
## jonctions qui disparaîtraient.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://proof/coins_diagonales.gd

const Modele := preload("res://addons/marching_squares/modele.gd")
const Archetypes := preload("res://core/coins/archetypes.gd")
const Jonctions := preload("res://core/coins/jonctions.gd")


func _initialize() -> void:
	var selle := func(c: int) -> bool: return c == 6 or c == 9
	var cles := 0
	var cles_sans := 0
	var arch_sans := {}
	var arch_par_sorte := {Modele.DESSUS: {}, Modele.HAUT: {}, Modele.BAS: {}}
	for a: Dictionary in Archetypes.liste():
		for k: String in a.cles:
			cles += 1
			var t := k.split(":")
			var c := int(t[1])
			var cv := int(t[2])
			if selle.call(c) or (int(t[0]) != Modele.DESSUS and selle.call(cv)):
				continue
			cles_sans += 1
			arch_sans[a.numero] = true
			arch_par_sorte[int(a.sorte)][a.numero] = true
	print("clés : %d → %d sans selle" % [cles, cles_sans])
	print("archétypes : %d → %d sans selle (dessus %d, hauts %d, bas %d)" % [Archetypes.liste().size(), arch_sans.size(),
			arch_par_sorte[Modele.DESSUS].size(), arch_par_sorte[Modele.HAUT].size(), arch_par_sorte[Modele.BAS].size()])
	# Les jonctions : l'ensemble fermé, recalculé sur les seuls voisinages SANS selle à aucune couche.
	var tout := Jonctions.ensemble()
	var sans := {}
	for orientation: Array in [[2, 1], [1, 2]]:
		var colonnes: int = orientation[0]
		var rangees: int = orientation[1]
		var n := (colonnes + 1) * (rangees + 1)
		for code in int(pow(4, n)):
			var h := PackedInt32Array()
			h.resize(n)
			var r := code
			for i in n:
				h[i] = r % 4
				r /= 4
			var a_selle := false
			for L in range(1, 4):
				for j in rangees:
					for x in colonnes:
						a_selle = a_selle or selle.call(Modele.config(h, colonnes + 1, x, j, L))
			if not a_selle:
				sans.merge(Jonctions.du_monde(h, colonnes, rangees))
	print("jonctions : %d → %d sans selle" % [tout.size(), sans.size()])
	quit(0)
