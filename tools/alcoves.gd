# LES ALCOVES : ce qu'un massif ENTAILLE pose, et que la battue au hasard ne fabrique pas.
#
# ⚠ CE N'EST PAS UNE FORME EXOTIQUE, C'EST CELLE QUE LE PAYSAGE POSE DEJA. `tools/edge_tiles.gd`
# a releve quatre tuiles que `guides/terrain.txt` pose a l'etage >= 1 -- donc peignables -- et que
# le vocabulaire livre n'a pas. En regardant OU elles tombent, c'est deux fois la meme figure : un
# massif rectangulaire dont une barre du milieu est EVIDEE, l'entaille ouverte sur un cote, et la
# barre du sud decalee par rapport a celle du nord. Une alcove, un renfoncement, un porche.
#
# ⚠ ET C'EST LA MEME FAMILLE DE FAUTE QUE LES MARCHES, LES TERRASSES, LES SOLS ETAGES ET LES
# CUVETTES : `Gesture.walk` ne fabrique pas ces figures-la, et « une battue qui ne rencontre pas
# une tuile prouve qu'elle est RARE, jamais qu'elle est impossible ». On construit ce qu'aucune
# autre source ne fabrique, on ne l'espere pas du hasard.
#
# ⚠ ET LE BALAYAGE EST EXHAUSTIF SUR SA FAMILLE, pas un tirage : deux intervalles evides -- celui
# de la barre du milieu, celui de la barre du sud -- fois la profondeur, fois l'etage. C'est un
# argument de force MOYENNE : exhaustif sur une famille bornee de mondes, donc il sature ; il ne
# dit rien des familles qu'on n'a pas ecrites.
#
#     godot --headless --path . --script res://tools/alcoves.gd
extends SceneTree
const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")
const Brush := preload("res://core/brush_vocabulary.gd")
const Lab := preload("res://tools/relief_lab.gd")
const W: int = 26
const H: int = 30
func _initialize() -> void:
	var vocab: Dictionary = {}
	for t: int in Brush.tiles():
		vocab[t] = true
	var hits: Dictionary = {}
	var legal: int = 0
	var tried: int = 0
	var span: int = W - 12
	for level: int in [1, 2]:
		for deep: int in [3, 4, 6]:
			for m0: int in [0, 3, 6, 9]:
				for m1: int in [3, 6, 9, 12, span]:
					for s0: int in [0, 3, 6, 9]:
						for s1: int in [0, 3, 6, 9, 12, span]:
							if m1 <= m0 or s1 < s0:
								continue
							tried += 1
							var w: PackedStringArray = _one(level, deep, m0, m1, s0, s1)
							if not Gesture.legal(w):
								continue
							legal += 1
							for v: Variant in Massifs.paintable(w).values():
								if not vocab.has(int(v)):
									hits[int(v)] = ("etage %d profond %d milieu %d-%d sud %d-%d"
											% [level, deep, m0, m1, s0, s1])
	print("%d formes essayees, %d legales" % [tried, legal])
	print("")
	print("CE QUE LA FAMILLE AJOUTE AU VOCABULAIRE LIVRE : %d tuile(s)" % hits.size())
	for k: Variant in hits.keys():
		print("    %-40s %s" % [Massifs.describe(int(k)), hits[k]])
	quit(0)
## Un massif rectangulaire, entaille d'une ALCOVE ouverte sur un cote.
func _one(level: int, deep: int, m0: int, m1: int, s0: int, s1: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for _y: int in range(H):
		var row: PackedByteArray = PackedByteArray()
		row.resize(W)
		row.fill(1)
		grid.append(row)
	for y: int in range(6, 6 + 3 + deep + 3):
		for x: int in range(6, W - 6):
			grid[y][x] = level + 1
	# LE CREUX : la barre du milieu est evidee de [m0, m1), celle du sud de [s0, s1).
	for y1: int in range(6 + 3, 6 + 3 + deep):
		for x1: int in range(m0, m1):
			grid[y1][6 + x1] = 1
	for y3: int in range(6 + 3 + deep, 6 + 3 + deep + 3):
		for x3: int in range(s0, s1):
			grid[y3][6 + x3] = 1
	for y2: int in range(H):
		for x2: int in range(W):
			if y2 < 4 or y2 >= H - 4 or x2 < 4 or x2 >= W - 4:
				grid[y2][x2] = 0
	return Lab.text(grid)
