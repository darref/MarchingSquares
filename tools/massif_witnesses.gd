extends SceneTree

## LES TEMOINS DES TUILES QU'AUCUNE FENETRE ETIREE NE PORTE.
##
##     godot --headless --path . --script res://tools/massif_witnesses.gd -- [tirages]
##     PART=i/n godot --headless ...          (une part des graines)
##     godot --headless --path . --script res://tools/massif_witnesses.gd -- --fusion
##
## ⚠ ILS NE SONT PAS DESSINES A LA MAIN, ILS SONT TROUVES. Trente-six tuiles sur quatre-vingt-huit
## demandent que le massif se REFERME hors de la fenetre -- un U, une baie, un cirque. La fenetre
## de l'enumeration a le droit de supposer que deux de ses composantes sont reliees dehors ;
## l'ilot etire, lui, est un monde fini : ce qui n'est pas relie dedans ne l'est nulle part.
##
## ⚠ ET ON NE COUPE JAMAIS SANS REVERIFIER, DANS LE CONTEXTE OU LE TEMOIN SERA POSE. La decoupe
## ment : elle tranche des massifs, donc elle change les silhouettes qu'elle pretend capturer.
## Chaque bloc est donc RELU par le modele une fois decoupe, borde de plaine et encadre de vide --
## exactement comme il le sera dans le guide.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifForm := preload("res://core/massif_form.gd")

## La decoupe autour de la case, puis son etirement : le bloc pose dans le guide.
## ⚠ ONZE, PAS NEUF : l'ilot etire fait neuf de large, et il faut TROIS colonnes de chaque cote
## pour y accoler une echine. A neuf, l'echine n'en faisait que deux -- donc fine, donc refusee,
## et la construction ne rendait rien sans qu'on sache pourquoi.
const CUT_W: int = 11
const CUT_H: int = 12
const PAD: int = 2
const BLOCK_W: int = CUT_W + 2 * PAD
const BLOCK_H: int = CUT_H + 2 * PAD
## La case interessante, dans le bloc.
const AT: Vector2i = Vector2i(CUT_W / 2 + PAD, CUT_H / 2 + PAD)
const RIM: int = 4

const OUT: String = "res://core/massif_witnesses.gd"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "--fusion":
		_fuse()
		return
	var draws: int = args[0].to_int() if not args.is_empty() else 3000
	var part: int = 0
	var parts: int = 1
	var shard: String = OS.get_environment("PART")
	if not shard.is_empty():
		part = shard.split("/")[0].to_int()
		parts = maxi(1, shard.split("/")[1].to_int())

	var wanted: Array[int] = MassifForm.vocabulary()
	var wits: Dictionary = MassifForm.witnesses()
	var found: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x5749544E + part * 7919
	var seen: int = 0
	for run: int in range(draws):
		var world: PackedStringArray = _draw(rng)
		if world.is_empty():
			continue
		seen += 1
		var paint: Dictionary = Massifs.paintable(world)
		for cell: Vector2i in paint.keys():
			var tile: int = int(paint[cell])
			if found.has(tile):
				continue
			var block: PackedStringArray = _cut(world, cell)
			if not _carries(block, tile):
				continue
			found[tile] = block
		if found.size() >= wanted.size():
			break
	# ⚠ ET CE QUE LE HASARD NE TROUVE PAS SE CONSTRUIT AUTOUR DE SA FENETRE. Les tuiles qui
	# restent demandent que le massif se referme dehors -- une anse ouverte au nord rencontrant
	# une anse ouverte au sud, a une colonne pres. Une marche au hasard ne tombe jamais dessus :
	# elle prouve qu'elles sont rares, pas qu'elles sont impossibles, et c'est exactement la
	# faute contre laquelle le dossier met en garde. On part donc de la fenetre que l'enumeration
	# a retenue -- gelee, elle porte deja la bonne silhouette -- et on ne laisse bouger que ce
	# qui l'entoure, jusqu'a ce que les morceaux se rejoignent.
	for at: int in range(wanted.size()):
		var tile2: int = wanted[at]
		if found.has(tile2):
			continue
		# ⚠ ET CHAQUE PART PREND SA TRANCHE DE TUILES, pas les memes que les autres. Cinq parts
		# qui cherchent toutes le meme temoin coutent cinq fois le meme travail.
		if (at % parts) != part:
			continue
		var built: PackedStringArray = _construct(tile2, wits, rng)
		if not built.is_empty():
			found[tile2] = built
	var missing: Array[int] = []
	for tile2: int in wanted:
		if not found.has(tile2):
			missing.append(tile2)
	print("part %d/%d : %d mondes, %d/%d tuiles portees, %d manquantes"
			% [part, parts, seen, found.size(), wanted.size(), missing.size()])
	_write("%s.part%d" % [OUT, part], found)
	quit(0)


## ⚠ LA FUSION RECALCULE, ELLE NE CROIT PAS UNE PART SUR PAROLE. Chaque bloc est relu par le
## modele avant d'entrer dans la liste : une part qui se serait trompee ne contaminerait pas
## l'ensemble.
func _fuse() -> void:
	var wanted: Array[int] = MassifForm.vocabulary()
	var found: Dictionary = {}
	for part: int in range(16):
		var path: String = "%s.part%d" % [OUT, part]
		if not FileAccess.file_exists(path):
			continue
		var got: Dictionary = _read("%s.part%d" % [OUT, part])
		for tile: int in got.keys():
			if found.has(tile):
				continue
			var block: PackedStringArray = got[tile]
			if _carries(block, int(tile)):
				found[int(tile)] = block
	var missing: Array[String] = []
	for tile2: int in wanted:
		if not found.has(tile2):
			missing.append(Massifs.describe(tile2))
	print("fusion : %d/%d tuiles portees" % [found.size(), wanted.size()])
	if not missing.is_empty():
		print("  manquantes : %s" % " | ".join(missing))
	_write(OUT, found)
	quit(0)


## LE BLOC PORTE-T-IL VRAIMENT SA TUILE ? Relu par le modele, borde comme dans le guide.
func _carries(block: PackedStringArray, tile: int) -> bool:
	var world: PackedStringArray = _framed(block)
	if not Thickness.thin_cells(world).is_empty():
		return false
	if not Massifs.foot_faults(world).is_empty():
		return false
	var paint: Dictionary = Massifs.paintable(world)
	return int(paint.get(AT + Vector2i(RIM, RIM), -1)) == tile


## Le bloc, encadre de plaine puis de vide -- le contexte du guide.
func _framed(block: PackedStringArray) -> PackedStringArray:
	var wide: int = block[0].length() + 2 * RIM
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(block.size() + 2 * RIM):
		var line: String = ""
		for x: int in range(wide):
			if x < RIM or y < RIM or x >= wide - RIM or y >= block.size() + RIM:
				line += "~" if x < 2 or y < 2 or x >= wide - 2 or y >= block.size() + 2 * RIM - 2 \
						else "0"
			else:
				line += block[y - RIM].substr(x - RIM, 1)
		out.append(line)
	return out


## LA DECOUPE, ETIREE. Chaque case du pourtour prend l'etat de la case la plus proche vers le
## centre : toute course s'y prolonge d'au moins deux, ce qui garantit l'epaisseur sans une seule
## boucle de reparation. C'est le meme argument que l'ilot etire de la planche de preuve.
func _cut(world: PackedStringArray, cell: Vector2i) -> PackedStringArray:
	var ox: int = cell.x - CUT_W / 2
	var oy: int = cell.y - CUT_H / 2
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(BLOCK_H):
		var line: String = ""
		for x: int in range(BLOCK_W):
			var sx: int = ox + clampi(x - PAD, 0, CUT_W - 1)
			var sy: int = oy + clampi(y - PAD, 0, CUT_H - 1)
			var level: int = HeightMask.level_at(world, sx, sy)
			line += "~" if level < 0 else str(level)
		out.append(line)
	return out


func _write(path: String, found: Dictionary) -> void:
	var keys: Array[int] = []
	keys.assign(found.keys())
	keys.sort()
	var text: String = "# LES TEMOINS DES TUILES QUE LA FENETRE ETIREE NE PORTE PAS.\n"
	text += "#\n"
	text += "# ⚠ GENERE PAR `tools/massif_witnesses.gd` -- ne pas editer a la main.\n"
	text += "# Chaque bloc est un relief qui porte sa tuile a la case (%d, %d).\n" % [AT.x, AT.y]
	text += "extends RefCounted\n\n"
	text += "const AT: Vector2i = Vector2i(%d, %d)\n\n" % [AT.x, AT.y]
	text += "## tuile -> les rangees du bloc.\n"
	text += "static func blocks() -> Dictionary:\n\treturn {\n"
	for tile: int in keys:
		var rows: PackedStringArray = found[tile]
		var said: PackedStringArray = PackedStringArray()
		for row: String in rows:
			said.append("\"%s\"" % row)
		text += "\t\t%d: PackedStringArray([%s]),\n" % [tile, ", ".join(said)]
	text += "\t}\n"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("  ecrit : %s (%d blocs)" % [path, keys.size()])


func _read(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var out: Dictionary = {}
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if not line.begins_with("\t\t") and not line.contains(": PackedStringArray(["):
			continue
		var head: int = line.find(":")
		if head < 0:
			continue
		var tile: int = line.substr(0, head).strip_edges().to_int()
		var body: String = line.substr(line.find("[") + 1)
		body = body.substr(0, body.rfind("]"))
		var rows: PackedStringArray = PackedStringArray()
		for piece: String in body.split(","):
			var trimmed: String = piece.strip_edges()
			if trimmed.length() > 2:
				rows.append(trimmed.substr(1, trimmed.length() - 2))
		if not rows.is_empty():
			out[tile] = rows
	file.close()
	return out


## LA CONSTRUCTION : ON REJOINT PLUTOT QUE DE CHERCHER.
##
## ⚠ L'ENUMERATION SAIT CE QU'IL FAUT REJOINDRE, DONC ON N'A RIEN A CHERCHER. Ces tuiles-la
## demandent que deux morceaux de la fenetre soient LE MEME massif, relies hors du cadre. Une
## marche au hasard ne tombe jamais sur cet entrelacement -- vingt minutes pour rien -- alors
## qu'une ECHINE de trois colonnes accolee a l'ilot les relie d'un coup.
##
## ⚠ ET L'ECHINE NE PEUT PAS MENTIR SUR LA CASE CENTRALE. Elle est a trois colonnes de la
## fenetre, donc hors de la fenetre 3x3 que la silhouette lit ; et l'empreinte d'une colonne ne
## depend que de cette colonne. Elle ne change donc QUE l'appartenance -- exactement ce qu'on
## veut deplacer.
##
## ⚠ ET TOUTE COMPOSANTE TOUCHE LA COLONNE 0 OU LA COLONNE 2 : une composante qui ne vivrait
## qu'au milieu ferait une course d'UNE case, que min trois interdit. Deux echines suffisent
## donc a exprimer toutes les jonctions possibles.
func _construct(tile: int, wits: Dictionary, _rng: RandomNumberGenerator) -> PackedStringArray:
	var level: int = 2 if Massifs.flush_of(tile) else 1
	for bits: int in (wits[tile & 0xffff] as Array[int]):
		for shape: int in range(4):
			var block: PackedStringArray = _spined(bits, level, shape)
			if block.is_empty():
				continue
			var world: PackedStringArray = _framed(block)
			if not Thickness.thin_cells(world).is_empty():
				continue
			if not Massifs.foot_faults(world).is_empty():
				continue
			var paint: Dictionary = Massifs.paintable(world)
			if int(paint.get(AT + Vector2i(RIM, RIM), -1)) == tile:
				return block
	return PackedStringArray()


## L'ilot etire, flanque d'une echine a gauche (bit 0), a droite (bit 1), ou des deux.
func _spined(bits: int, level: int, shape: int) -> PackedStringArray:
	var isle: Array[PackedByteArray] = MassifForm.stretched(bits, 3)
	var isle_w: int = isle.size()
	var isle_h: int = isle[0].size()
	var left: bool = (shape & 1) != 0
	var right: bool = (shape & 2) != 0
	var grid: Array[PackedByteArray] = []
	for y: int in range(BLOCK_H):
		var line: PackedByteArray = PackedByteArray()
		line.resize(BLOCK_W)
		line.fill(1)
		grid.append(line)
	# La case interessante doit tomber sur AT : la fenetre est au centre de l'ilot etire.
	var ox: int = AT.x - (3 + MassifForm.CX)
	var oy: int = AT.y - (3 + MassifForm.CY)
	if ox < 0 or oy < 0 or ox + isle_w > BLOCK_W or oy + isle_h > BLOCK_H:
		return PackedStringArray()
	if level > 1:
		for y2: int in range(BLOCK_H):
			for x2: int in range(BLOCK_W):
				grid[y2][x2] = 2
	for x3: int in range(isle_w):
		for y3: int in range(isle_h):
			grid[oy + y3][ox + x3] = (level + 1) if int(isle[x3][y3]) == 1 else level
	if left:
		for y4: int in range(BLOCK_H):
			for x4: int in range(maxi(0, ox - 3), ox):
				grid[y4][x4] = level + 1
	if right:
		for y5: int in range(BLOCK_H):
			for x5: int in range(ox + isle_w, mini(BLOCK_W, ox + isle_w + 3)):
				grid[y5][x5] = level + 1
	return _text(grid)


func _freeze(grid: Array[PackedByteArray], core: Array[PackedByteArray], ox: int, oy: int,
		level: int) -> void:
	for x: int in range(MassifForm.COLS):
		for y: int in range(MassifForm.ROWS):
			grid[oy + y][ox + x] = (level + 1) if int(core[x][y]) == 1 else level


## La reparation, fenetre gelee : elle aligne chaque case fine sur ses voisines, puis remet la
## fenetre en place, jusqu'au point fixe.
func _mend(grid: Array[PackedByteArray], core: Array[PackedByteArray], ox: int, oy: int,
		level: int) -> PackedStringArray:
	for round: int in range(10):
		var text: PackedStringArray = _text(grid)
		var thin: Array[Vector3i] = Thickness.thin_cells(text)
		if thin.is_empty():
			return text
		for one: Vector3i in thin:
			if one.x < 1 or one.y < 1 or one.y >= grid.size() - 1 or one.x >= grid[0].size() - 1:
				continue
			var votes: Dictionary = {}
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				votes[int(grid[one.y + step.y][one.x + step.x])] = 						int(votes.get(int(grid[one.y + step.y][one.x + step.x]), 0)) + 1
			var best: int = int(grid[one.y][one.x])
			var most: int = 0
			for value: int in votes.keys():
				if int(votes[value]) > most:
					most = int(votes[value])
					best = value
			grid[one.y][one.x] = best
		_freeze(grid, core, ox, oy, level)
	var last: PackedStringArray = _text(grid)
	return last if Thickness.thin_cells(last).is_empty() else PackedStringArray()


## UN RELIEF EPAIS TIRE AU SORT -- pose ET efface, comme le pinceau.
func _draw(rng: RandomNumberGenerator) -> PackedStringArray:
	var wide: int = rng.randi_range(20, 32)
	var tall: int = rng.randi_range(22, 34)
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	for x: int in range(RIM, wide - RIM):
		for y2: int in range(RIM, tall - RIM):
			var row: PackedByteArray = grid[y2]
			row[x] = 1
			grid[y2] = row
	for _stamp: int in range(rng.randi_range(4, 16)):
		var ox: int = rng.randi_range(RIM + 1, wide - RIM - 4)
		var oy: int = rng.randi_range(RIM + 1, tall - RIM - 10)
		var raise: bool = rng.randf() < 0.7
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				var row2: PackedByteArray = grid[y3]
				row2[x3] = mini(int(row2[x3]) + 1, 4) if raise else maxi(int(row2[x3]) - 1, 0)
				grid[y3] = row2
	return _repair(grid)


## ⚠ ON REPARE, ON NE REFUSE PAS -- et c'est le geste meme du pinceau. Un generateur qui jette
## tout relief fin ne rendait que QUINZE mondes sur mille cinq cents : la battue ne cherchait
## presque rien, et son silence n'aurait rien prouve. Chaque case fine se fait aligner sur ce que
## ses voisines cardinales disent majoritairement, jusqu'au point fixe.
func _repair(grid: Array[PackedByteArray]) -> PackedStringArray:
	for round: int in range(14):
		var text: PackedStringArray = _text(grid)
		var thin: Array[Vector3i] = Thickness.thin_cells(text)
		if thin.is_empty():
			return text
		for one: Vector3i in thin:
			if one.x < 0 or one.y < 0 or one.y >= grid.size() or one.x >= grid[0].size():
				continue
			var votes: Dictionary = {}
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var nx: int = one.x + step.x
				var ny: int = one.y + step.y
				if nx < 0 or ny < 0 or ny >= grid.size() or nx >= grid[0].size():
					continue
				votes[int(grid[ny][nx])] = int(votes.get(int(grid[ny][nx]), 0)) + 1
			var best: int = int(grid[one.y][one.x])
			var most: int = 0
			for value: int in votes.keys():
				if int(votes[value]) > most:
					most = int(votes[value])
					best = value
			var row3: PackedByteArray = grid[one.y]
			row3[one.x] = best
			grid[one.y] = row3
	var last: PackedStringArray = _text(grid)
	return last if Thickness.thin_cells(last).is_empty() else PackedStringArray()


func _text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var text: PackedStringArray = PackedStringArray()
	for line: PackedByteArray in grid:
		var said: String = ""
		for v: int in line:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	return text
