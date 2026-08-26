extends SceneTree

## LA GARANTIE QUI REMPLACE TOUTES LES AUTRES : LES COUCHES RECOUVRENT TOUT.
##
## ⚠ CE FICHIER EXISTE PARCE QUE LA DECOMPOSITION EN COUCHES A RETIRE LES BEQUILLES. Le bord
## d'une surface, les trois etats de flanc, le lisere d'epaisseur, l'ombre du flanc : toutes
## ces distinctions existaient pour qu'une tuile puisse SUGGERER ce qu'il y a a cote d'elle.
## La regle des couches les rend inutiles -- ce qui est a cote appartient a la couche du
## voisin, qui le dessine elle-meme. Le vocabulaire tombe de 92 a 47.
##
## Mais ce qu'on retire d'un cote, il faut le garantir de l'autre. L'ancienne garantie etait
## une LISTE : « chaque tuile connait assez son voisinage » -- non bornee, on la chassait, et
## on en trouvait encore une hier soir. La nouvelle est UNE PROPRIETE, et elle est bornee :
##
##     AUCUN PIXEL DE L'IMAGE COMPOSEE NE MONTRE LE FOND LA OU LE MONDE A DE LA MATIERE.
##
## ⚠ ET C'EST UN CONTROLE, PAS UNE TAUTOLOGIE. Il ne redemande pas au modele ce que le modele
## affirme : il rend l'image, puis regarde les pixels. Un trou est un trou, quelle que soit la
## regle qui a cru le boucher. C'est la difference qui a manque deux fois cette nuit -- une
## mesure qui donnait zero parce que la propagation force l'accord, et un detecteur qui criait
## parce qu'il exigeait un contrat perime.

const HeightMask := preload("res://core/height_mask.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")

const TILE: int = 12
## Un pixel est « du fond » s'il est transparent, ou de la couleur que le rendu pose dehors.
const CLEAR: float = 0.5


func _initialize() -> void:
	var total_holes: int = 0
	var total_cells: int = 0

	print("=== LE GUIDE ===")
	total_holes += _probe(HeightMask.read(Modes.guide_path(Modes.EPAIS)), "guide")
	print("")
	print("=== LES PLANCHES DE PREUVE ===")
	for family: StringName in Families.ids():
		total_holes += _probe(ProofScene.relief(family), "preuve %s" % family)
	print("")
	print("=== DU RELIEF EPAIS TIRE AU SORT ===")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260826
	var kept: int = 0
	var holes: int = 0
	var cells: int = 0
	while kept < 40:
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		kept += 1
		var report: Dictionary = _measure(relief)
		holes += int(report["holes"])
		cells += int(report["cells"])
	total_holes += holes
	total_cells += cells
	print("  %d reliefs, %d cases de terre : %d cases trouees" % [kept, cells, holes])
	print("")
	print("VERDICT : %s" % ("les couches recouvrent tout." if total_holes == 0
			else "%d cases trouees." % total_holes))
	quit(1 if total_holes > 0 else 0)


func _probe(heights: PackedStringArray, label: String) -> int:
	var report: Dictionary = _measure(heights)
	print("  %-16s %d cases de terre, %d trouees   %s" % [label, int(report["cells"]),
			int(report["holes"]), str(report["examples"])])
	return int(report["holes"])


## Rend l'illustration, puis regarde les pixels : une case de terre entierement percee est un
## trou. On tolere les coins arrondis -- ils laissent voir l'etage d'en dessous, c'est voulu --
## et on ne compte que les cases dont le CENTRE montre le fond.
func _measure(heights: PackedStringArray) -> Dictionary:
	var image: Image = GuideImage.render(heights, TILE)
	var width: int = HeightMask.width(heights)
	var height: int = HeightMask.height(heights)
	var cells: int = 0
	var holes: int = 0
	var examples: Array[String] = []
	for y: int in range(height):
		for x: int in range(width):
			if HeightMask.level_at(heights, x, y) < 0:
				continue
			cells += 1
			# ⚠ LE CENTRE, PAS LE BORD. Les coins d'une tuile sont arrondis et laissent voir
			# ce qu'il y a dessous : c'est l'empilement qui fournit, et c'est voulu. Le centre,
			# lui, doit TOUJOURS porter de la matiere -- aucune regle ne le troue.
			var px: int = x * TILE + TILE / 2
			var py: int = y * TILE + TILE / 2
			if px >= image.get_width() or py >= image.get_height():
				continue
			if image.get_pixel(px, py).a < CLEAR:
				holes += 1
				if examples.size() < 5:
					examples.append("%d,%d" % [x, y])
	return {"cells": cells, "holes": holes, "examples": examples}


func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = rng.randi_range(12, 16)
	var h: int = rng.randi_range(14, 18)
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	for stamp: int in range(rng.randi_range(4, 10)):
		var level: int = rng.randi_range(0, 3)
		var bw: int = rng.randi_range(3, 7)
		var bh: int = rng.randi_range(3, 7)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = maxi(row[x], level + 1)
				grid[y] = row
	for dig: int in range(rng.randi_range(1, 4)):
		var level: int = rng.randi_range(-1, 2)
		var bw: int = rng.randi_range(3, 6)
		var bh: int = rng.randi_range(3, 6)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = mini(row[x], level + 1)
				grid[y] = row
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(h):
		var line: String = ""
		for x: int in range(w):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
