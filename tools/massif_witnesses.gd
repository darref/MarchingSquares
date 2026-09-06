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
const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifForm := preload("res://core/massif_form.gd")
const Lab := preload("res://tools/relief_lab.gd")

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
	# ⚠ L'ENUMERATION CISAILLEE, PAS L'AUTRE. Une tuile cisaillee n'a pas de fenetre dans
	# `witnesses()` : la chercher la revient a demander une cle qui n'existe pas, et la chasse
	# s'arretait sur « Out of bounds get index ». Le cisaillement fait partie de l'identite
	# depuis qu'il est dans la cle ; l'enumeration qui sert de source doit le savoir aussi.
	var wits: Dictionary = MassifForm.shear_witnesses()
	var found: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x5749544E + part * 7919
	var seen: int = 0
	# ⚠ ET LE GUIDE EST UN MONDE COMME UN AUTRE. Il porte des situations que le hasard ne
	# fabrique pas -- c'est meme sa raison d'etre -- donc le laisser hors de la battue revenait a
	# chercher partout sauf la ou on avait deja regarde.
	for run: int in range(draws + 1):
		var world: PackedStringArray = HeightMask.read("res://guides/massifs.txt") if run == 0 				else _draw(rng)
		if world.is_empty():
			continue
		seen += 1
		var paint: Dictionary = Massifs.paintable(world)
		for cell: Vector2i in paint.keys():
			var tile: int = int(paint[cell])
			if found.has(tile):
				continue
			# ⚠ ON ESSAIE LA DECOUPE ETIREE **ET** LA DECOUPE BRUTE. L'etirement garantit
			# l'epaisseur, mais il replique les bords -- et la ou la tuile tient a un vide ou a
			# une chute qui s'arrete, repliquer la detruit. Deux lectures, on garde celle qui
			# porte vraiment.
			var block: PackedStringArray = _cut(world, cell, PAD)
			if not _carries(block, tile):
				block = _cut(world, cell, 0)
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
	# ⚠ ON RELIT L'EXISTANT D'ABORD, SINON LA FUSION PERD CE QU'ELLE N'A PAS RETROUVE. Elle
	# repartait des SEULES parts : une part absente, une chasse plus courte, une graine moins
	# heureuse, et un temoin trouve la veille disparaissait sans un mot. Elle a cru la derniere
	# fois ; rien ne le garantissait.
	#
	# ⚠ ET L'EXISTANT PASSE PAR LE MEME CONTROLE QUE LES PARTS. « Ce qui a ete trouve reste
	# trouve » ne vaut qu'A MODELE CONSTANT : quand la cle change de sens, un bloc d'avant ne
	# porte plus la tuile qu'il annonce, et le garder serait inscrire un temoin faux. `_carries`
	# tranche, et le compte des perimes est DIT -- une disparition silencieuse est precisement ce
	# qu'on repare ici.
	var kept: int = 0
	var stale: int = 0
	if FileAccess.file_exists(OUT):
		var had: Dictionary = _read(OUT)
		for tile0: Variant in had.keys():
			var block0: PackedStringArray = had[tile0]
			if _carries(block0, int(tile0)):
				found[int(tile0)] = block0
				kept += 1
			else:
				stale += 1
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
	print("  %d repris de l'existant, %d perimes (ne portent plus leur tuile), %d ajoutes"
			% [kept, stale, found.size() - kept])
	if not missing.is_empty():
		print("  manquantes : %s" % " | ".join(missing))
	_write(OUT, found)
	quit(0)


## LE BLOC PORTE-T-IL VRAIMENT SA TUILE ? Relu par le modele, borde comme dans le guide.
func _carries(block: PackedStringArray, tile: int) -> bool:
	var world: PackedStringArray = _framed(block)
	if not Lab.legal(world):
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
func _cut(world: PackedStringArray, cell: Vector2i, pad: int) -> PackedStringArray:
	var ox: int = cell.x - CUT_W / 2 - (PAD - pad)
	var oy: int = cell.y - CUT_H / 2 - (PAD - pad)
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(BLOCK_H):
		var line: String = ""
		for x: int in range(BLOCK_W):
			var sx: int = ox + (clampi(x - pad, 0, CUT_W + 2 * (PAD - pad) - 1) if pad > 0 else x)
			var sy: int = oy + (clampi(y - pad, 0, CUT_H + 2 * (PAD - pad) - 1) if pad > 0 else y)
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
	# La cle de l'enumeration cisaillee : la coupe en tete, puis la bande et la silhouette.
	# ⚠ ET UNE TUILE SANS FENETRE NE FAIT PAS PLANTER LA CHASSE, elle la laisse passer : c'est
	# une tuile a chercher autrement, pas une erreur de programme.
	var coupe: int = (Massifs.cut_of(tile) >> 17) & 3
	var source: int = (coupe << 24) | (tile & 0xffff)
	if not wits.has(source):
		return PackedStringArray()
	for bits: int in (wits[source] as Array[int]):
		for shape: int in range(4):
			var block: PackedStringArray = _spined(bits, level, shape)
			if block.is_empty():
				continue
			var world: PackedStringArray = _framed(block)
			if not Lab.legal(world):
				continue
			if not Lab.legal(world):
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
	return Lab.text(grid)


## ⚠ ET LA REPARATION AUSSI VIT EN UN SEUL ENDROIT. Deux reparateurs locaux vivaient ici, avec
## chacun leur idee de ce qu'il faut defaire : c'est exactement la fabrique a rustines qu'on
## vient de fermer.
func _mend(grid: Array[PackedByteArray], core: Array[PackedByteArray], ox: int, oy: int,
		level: int) -> PackedStringArray:
	for round: int in range(10):
		var world: PackedStringArray = Lab.text(grid)
		if Lab.legal(world):
			return world
		var mended: PackedStringArray = Gesture.mend(grid)
		if mended.is_empty():
			return mended
		for y: int in range(grid.size()):
			for x: int in range(grid[0].size()):
				var level2: int = HeightMask.level_at(mended, x, y)
				grid[y][x] = 0 if level2 < 0 else level2 + 1
		_freeze(grid, core, ox, oy, level)
	var last: PackedStringArray = Lab.text(grid)
	return last if Lab.legal(last) else PackedStringArray()


func _freeze(grid: Array[PackedByteArray], core: Array[PackedByteArray], ox: int, oy: int,
		level: int) -> void:
	for x: int in range(MassifForm.COLS):
		for y: int in range(MassifForm.ROWS):
			grid[oy + y][ox + x] = (level + 1) if int(core[x][y]) == 1 else level


## UN RELIEF EPAIS TIRE AU SORT -- pose ET efface, comme le pinceau.
func _draw(rng: RandomNumberGenerator) -> PackedStringArray:
	return Lab.draw(rng, rng.randi_range(20, 32), rng.randi_range(24, 34))
