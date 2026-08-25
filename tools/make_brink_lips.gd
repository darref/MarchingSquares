extends SceneTree

## DU RELIEF TROUVE A LA TABLE QUE LE LOGICIEL LIT.
##
## ⚠ ON NE RANGE PAS LE RELIEF, ON RANGE LA LEVRE. L'ilot lui-meme reste CALCULE depuis
## l'index -- fenetre realisable, etirement -- comme les 47 index et la planche de preuve le
## sont : un relief ecrit serait une donnee a maintenir, donc un endroit ou mentir. Seule la
## position des blocs de falaise voisins se cherche, parce qu'elle ne se deduit pas ; c'est
## donc elle, et elle seule, qu'on ecrit. Quelques dizaines de couples, revérifiés par la
## suite : chaque ilot doit porter la tuile qu'il annonce.

const BlobIndex := preload("res://core/blob_index.gd")
const HeightMask := preload("res://core/height_mask.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Thickness := preload("res://core/thickness.gd")

const CENTRE: int = 16


func _initialize() -> void:
	var text: String = FileAccess.get_file_as_string("res://tools/islands.txt")
	var lips: Dictionary = {}
	var current: PackedStringArray = PackedStringArray()
	var tile: int = -1
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("#"):
			_harvest(lips, tile, current)
			current = PackedStringArray()
			tile = int(line.substr(1).strip_edges().split(" ")[0])
		elif line.is_empty():
			_harvest(lips, tile, current)
			current = PackedStringArray()
			tile = -1
		else:
			current.append(line)
	_harvest(lips, tile, current)
	var keys: Array = lips.keys()
	keys.sort()
	var out: String = ""
	out += "## LES LEVRES VOISINES D'UN ILOT DE PREUVE, cherchees puis verifiees.\n"
	out += "##\n"
	out += "## Une tuile de surface est le couple (silhouette, bord) : un cardinal vide borde\n"
	out += "## soit du NU -- ca tombe -- soit de la ROCHE, la face d'une falaise voisine. L'ilot\n"
	out += "## doit donc mettre en scene cette falaise, et SA POSITION NE SE DEDUIT PAS : collee,\n"
	out += "## elle pince une colonne de vide d'une case ; trois rangees plus haut, elle pince\n"
	out += "## ailleurs ; et quand le nord veut de la roche et l'est du nu, son bloc doit\n"
	out += "## chevaucher la colonne du voisin PLEIN. Trois raisonnements, trois erreurs.\n"
	out += "##\n"
	out += "## Genere par `tools/make_islands.gd` (balayage + juge : epais ? porte la tuile ?)\n"
	out += "## puis `tools/make_brink_lips.gd`. Ne pas editer a la main -- la suite reverifie.\n"
	out += "##\n"
	out += "## tuile -> cases d'un etage AU-DESSUS, en coordonnees relatives au centre de l'ilot.\n"
	out += "const LIPS: Dictionary = {\n"
	for key: Variant in keys:
		var cells: Array = lips[key]
		if cells.is_empty():
			continue
		var bits: Array[String] = []
		for at: Variant in cells:
			bits.append("Vector2i(%d, %d)" % [(at as Vector2i).x, (at as Vector2i).y])
		out += "\t%d: [%s],\n" % [int(key), ", ".join(bits)]
	out += "}\n"
	var file: FileAccess = FileAccess.open("res://core/brink_lips.gd", FileAccess.WRITE)
	file.store_string(out)
	file.close()
	var with_lips: int = 0
	for key: Variant in keys:
		if not (lips[key] as Array).is_empty():
			with_lips += 1
	print("tuiles lues : %d   dont a levre voisine : %d" % [keys.size(), with_lips])
	quit()


func _harvest(lips: Dictionary, tile: int, relief: PackedStringArray) -> void:
	if tile < 0 or relief.is_empty():
		return
	var cells: Array[Vector2i] = []
	for y: int in range(relief.size()):
		for x: int in range(relief[y].length()):
			if HeightMask.level_at(relief, x, y) >= 2:
				cells.append(Vector2i(x - CENTRE, y - CENTRE))
	cells.sort()
	lips[tile] = cells
