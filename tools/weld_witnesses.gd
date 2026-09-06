extends SceneTree

## LA CHASSE AUX TEMOINS QUI SUPPORTENT LA SOUDURE.
##
##     godot --headless --path . --script res://tools/weld_witnesses.gd -- [sortie.gd]
##
## ⚠ ET CE N'EST PAS LA MEME CHASSE QUE `tools/massif_witnesses.gd`. Celle-la cherche un relief
## qui porte une tuile ; celle-ci cherche un relief qui la porte ENCORE UNE FOIS SOUDE, c'est-a-
## dire entoure de plaine continue au lieu d'etre isole dans son lisere de vide. Deux tuiles du
## vocabulaire n'ont aucun temoin de cette sorte -- `PIED 21 au ras` et `PIED 69 au ras, cisaille
## a l'ouest` -- et le paysage sort donc a 53 sur 55.
##
## ⚠ ET AGRANDIR LA DECOUPE NE PEUT RIEN, C'EST MESURE (`tools/weld_reach.gd`). Le seul monde du
## vivier qui porte `PIED 21 au ras` la perd A TOUTES LES TAILLES -- 11x11, 23x21, le monde
## ENTIER -- et toujours de la meme facon : elle devient `PIED 31 libre`. La silhouette ne bouge
## pas (au ras, `Massifs.key` ne garde que les cardinaux : 31 & CARDINALS = 21, c'est la MEME
## tuile) ; c'est le bit `COVERS` qui tombe. Aucune fenetre, aussi large soit-elle, ne rend le
## vide qu'on vient de combler -- la decoupe n'y etait pour rien.
##
## ⚠ ET LA RAISON EST DANS LE MODELE, PAS DANS LE HASARD. Les deux sont AU RAS, et « au ras »
## decrit un massif VIS-A-VIS DE SON PORTEUR : une partie dedans, une partie dehors. Dans un monde
## du vivier, ce qui joue le porteur est souvent le BORD DU MONDE -- le massif deborde dans le
## vide. Combler ce vide de plaine change precisement ce qui le porte : le massif cesse de
## deborder, donc cesse d'etre au ras, donc la case cesse de porter sa tuile. Chercher plus
## longtemps dans le vivier ne peut pas aider : c'est la forme du monde qui est en cause.
##
## LA REPONSE EST DONC DE CONSTRUIRE, PAS DE TIRER. Il faut un porteur qui soit un VRAI MASSIF --
## un plateau d'etage un -- et un massif d'etage deux qui le chevauche : une partie sur le
## plateau, une partie sur la plaine. Cette relation-la ne depend d'aucun vide, donc elle survit
## a la soudure par construction. Le reste est une enumeration bornee : on fait varier la forme
## du plateau et celle du massif porte, on balaie chaque monde case par case, et on GARDE ce qui
## passe l'epreuve de la soudure.
##
## ⚠ ET L'EPREUVE EST CELLE DU BATISSEUR, PAS UNE APPROXIMATION. Le monde retenu est repose dans
## le cadre exact que `build_terrain` lui donnera -- plaine autour, lisere de vide a `RIM + GAP`,
## et le rab de douze rangees sous lui -- puis on relit ce que la case porte. Un temoin juge dans
## un autre contexte que celui ou il servira ne prouve rien : la lecon est deja au dossier.
const Gesture := preload("res://core/gesture.gd")
const Massifs := preload("res://core/massifs.gd")
const Brush := preload("res://core/brush_vocabulary.gd")
const Witnesses := preload("res://core/massif_witnesses.gd")
const Lab := preload("res://tools/relief_lab.gd")
const Welded := preload("res://core/weld_witnesses.gd")

## Le cadre de l'epreuve -- les memes nombres que `tools/build_terrain.gd`, et pour la meme
## raison. ⚠ S'ILS Y CHANGENT, ILS CHANGENT ICI : un temoin juge sous d'autres marges que celles
## ou il sera pose ne prouve rien.
const RIM: int = 4
const GAP: int = 3
const FALLOUT: int = 12

## Le monde construit : assez grand pour porter un plateau, son chevauchement et la chute.
const WIDE: int = 26
const TALL: int = 24


func _initialize() -> void:
	var out: String = "res://core/weld_witnesses.gd"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]

	# CE QU'ON CHERCHE : les tuiles du geste qu'aucun temoin soudable ne porte.
	var blocks: Dictionary = Witnesses.blocks()
	var wanted: Array[int] = []
	for tile: int in Brush.tiles():
		# ⚠ UN BLOC SE JUGE DANS SON CADRE, JAMAIS NU. Premiere version : on lisait
		# `Massifs.paintable(bloc)` sans rien autour, et seize tuiles se declaraient sans temoin
		# alors que le batisseur en pose cinquante-trois sans faute. Un relief sans bord n'est
		# pas un relief -- la plaine y est un massif sans falaise, et tout se decale.
		if blocks.has(tile) and _survives(blocks[tile], Witnesses.AT, tile):
			continue
		wanted.append(tile)
	print("tuiles sans temoin soudable : %d" % wanted.size())
	for tile0: int in wanted:
		print("   %s" % Massifs.describe(tile0))

	var found: Dictionary = {}
	# ⚠ ON RELIT L'EXISTANT D'ABORD, ET ON LE REVALIDE. Une battue qui repart de zero jette les
	# temoins deja trouves des qu'une source coute trop cher pour etre rejouee -- et c'est
	# exactement la faute que `massif_witnesses._fuse()` a payee. On garde ce qui TIENT ENCORE,
	# jamais ce qui est simplement ecrit : quand la cle change de sens, une entree d'avant ne
	# designe plus rien, et `_survives` est le seul juge.
	var kept: int = 0
	var stale: int = 0
	for tile5: Variant in Welded.blocks().keys():
		var was: PackedStringArray = Welded.blocks()[tile5]
		var sat: Vector2i = Welded.seats()[tile5]
		if wanted.has(int(tile5)) and _survives(was, sat, int(tile5)):
			found[int(tile5)] = [was, sat]
			kept += 1
		else:
			stale += 1
	print("l'existant : %d temoin(s) gardes, %d perimes" % [kept, stale])

	var worlds: int = 0
	var legal: int = 0
	# ⚠ UNE BATTUE DOIT AVOIR VRAIMENT CHERCHE, et ca se compte. Une famille qui ne rencontre
	# aucune tuile AU RAS ne prouve rien sur celles qu'on cherche : son silence dirait seulement
	# qu'elle regardait ailleurs. On publie donc ce qu'elle a vu.
	var seen: Dictionary = {}
	# LES SOURCES, DE LA MOINS CHERE A LA PLUS CHERE, ET ON S'ARRETE DES QU'IL NE MANQUE RIEN.
	# ⚠ ET CE N'EST PAS UN CONFORT : la famille en L pese pres de vingt mille reliefs, et la payer
	# pour une tuile que quatre-vingt-seize formes construites portent deja rendait la chasse
	# injouable -- dix minutes sans rendre la main. Une carte couteuse ne se calcule pas quand la
	# reponse est deja la ; la lecon est au dossier, payee sept fois.
	var sources: Array[String] = ["le C construit", "le vivier commun", "la famille en L"]
	for which: int in range(sources.size()):
		if found.size() >= wanted.size():
			break
		var batch: Array[PackedStringArray] = _c_family() if which == 0 else (
				Lab.ground() if which == 1 else _family())
		print("%s : %d relief(s)" % [sources[which], batch.size()])
		for world: PackedStringArray in batch:
			worlds += 1
			if not Gesture.legal(world):
				continue
			legal += 1
			var posed: Dictionary = Massifs.paintable(world)
			for tile3: Variant in posed.values():
				seen[int(tile3)] = true
			for cell: Vector2i in posed.keys():
				var tile1: int = int(posed[cell])
				if found.has(tile1) or not wanted.has(tile1):
					continue
				# ⚠ ON RANGE LE BLOC, PAS LE MONDE QUI L'A PORTE. Le paysage paie chaque rangee
				# et chaque colonne d'un temoin, et le monde d'un vivier est large de son bord de
				# vide. On rogne donc jusqu'a la matiere, PUIS on reverifie -- « on ne coupe jamais
				# sans reverifier, et dans le contexte ou le temoin sera pose ».
				var trimmed: Array = _trim(world, cell)
				if _survives(trimmed[0], trimmed[1], tile1):
					found[tile1] = trimmed
				elif _survives(world, cell, tile1):
					found[tile1] = [world, cell]
				else:
					continue
				print("  TROUVE : %s -- a la case %s" % [Massifs.describe(tile1),
						(found[tile1] as Array)[1]])
	var flush: Array[String] = []
	for tile4: int in seen.keys():
		if Massifs.flush_of(tile4):
			flush.append(Massifs.describe(tile4))
	flush.sort()
	print("%d reliefs parcourus, %d legaux -- ils portent %d tuiles, dont %d AU RAS :"
			% [worlds, legal, seen.size(), flush.size()])
	for name: String in flush:
		print("    %s" % name)
	print("%d tuiles trouvees sur %d" % [found.size(), wanted.size()])
	for tile2: int in wanted:
		if not found.has(tile2):
			print("  MANQUE ENCORE : %s" % Massifs.describe(tile2))
	if found.is_empty():
		print("rien a ecrire")
		quit(1)
	_write(out, found)
	quit(0 if found.size() == wanted.size() else 1)


## LE C OUVERT A L'OUEST, PORTE PAR UN VRAI PLATEAU -- le temoin de `PIED 21 au ras`.
##
## ⚠ ON LE CONSTRUIT PARCE QUE LE MODELE DIT QUOI CONSTRUIRE, pas parce que le hasard a echoue.
## Trois exigences, et chacune fixe une piece :
##
##   · AU RAS SANS AUCUN VIDE. Un massif d'etage 2 dont le bord sud donne sur la plaine descend
##     SIX rangees, quand le massif d'etage 1 qui le porte n'en descend que TROIS : son empreinte
##     deborde de celle de son hote par construction. C'est « une partie dedans, une partie
##     dehors » obtenue sans le bord du monde -- donc ca survit a la soudure, ce qu'aucun temoin
##     tire au sort ne pouvait faire.
##   · PIED. `landed = ground == 0` : la face doit atteindre LA PLAINE. Le creux ou elle tombe est
##     donc un CANAL D'ETAGE 0 qui traverse le plateau, jamais un palier d'etage 1 -- sur un
##     palier la face ne pose pas son pied, elle disparait derriere ce qu'elle rencontre.
##   · SILHOUETTE 21 = N + E + S, SANS W. Du massif SOUS le pied (S) : une barre qui repasse au
##     sud du canal. Rien a l'ouest (W) : le canal OUVRE a l'ouest -- d'ou le C. Ferme, sa paroi
##     serait de la roche du meme massif et le bit W serait mis.
##     ⚠ Et les diagonales ne se discutent pas : au ras, `Massifs.key` ne garde que les cardinaux,
##     donc `PIED 31` et `PIED 21` sont la MEME tuile. C'est ce qui a fait croire une fois que le
##     temoin changeait de silhouette alors que seul le bit `COVERS` tombait.
func _c_family() -> Array[PackedStringArray]:
	var made: Array[PackedStringArray] = []
	for bar_h: int in [3, 4]:
		for notch_w: int in [3, 4]:
			for arm_w: int in [3, 4]:
				for west: int in [3, 4, 5]:
					for north: int in [3, 4]:
						for south: int in [3, 4]:
							made.append(_c_one(bar_h, notch_w, arm_w, west, north, south))
	return made


## UN PLATEAU D'ETAGE 1 traverse d'ouest en est par un canal de plaine ; un massif d'etage 2 pose
## dessus, en C, dont le bras est enjambe le canal. La face de la barre nord tombe DANS le canal,
## six rangees plus bas, et pose son pied sur la plaine, sans rien a l'ouest.
func _c_one(bar_h: int, notch_w: int, arm_w: int, west: int, north: int,
		south: int) -> PackedStringArray:
	var chan_h: int = 2 * Massifs.FALL
	var wide: int = west + notch_w + arm_w + 4
	var tall: int = north + bar_h + chan_h + bar_h + south
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(2)
		grid.append(line)
	var c_w: int = notch_w + arm_w
	for y1: int in range(bar_h):
		for x1: int in range(c_w):
			_c_raise(grid, west + x1, north + y1, tall, wide)
			_c_raise(grid, west + x1, north + bar_h + chan_h + y1, tall, wide)
	for y2: int in range(chan_h):
		for x2: int in range(arm_w):
			_c_raise(grid, west + notch_w + x2, north + bar_h + y2, tall, wide)
		for x3: int in range(west + notch_w):
			grid[north + bar_h + y2][x3] = 1
	return Gesture.text(grid)


func _c_raise(grid: Array[PackedByteArray], x: int, y: int, tall: int, wide: int) -> void:
	if y < 0 or y >= tall or x < 0 or x >= wide:
		return
	var line: PackedByteArray = grid[y]
	line[x] = 3
	grid[y] = line


## ROGNER LE MONDE JUSQU'A SA MATIERE. ⚠ LE PAYSAGE PAIE CHAQUE RANGEE D'UN TEMOIN : un monde du
## vivier traine son bord de vide, et le poser tel quel c'est poser vingt colonnes de plaine.
## On rogne, et l'appelant REVERIFIE -- la decoupe ment, et c'est deja au dossier.
func _trim(world: PackedStringArray, cell: Vector2i) -> Array:
	var x0: int = world[0].length()
	var y0: int = world.size()
	var x1: int = -1
	var y1: int = -1
	for y: int in range(world.size()):
		var row: String = world[y]
		for x: int in range(row.length()):
			var c: String = row[x]
			if c == "~" or c == "." or c == "0":
				continue
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
	if x1 < 0:
		return [world, cell]
	# ⚠ ON GARDE LA CASE CHERCHEE DANS LE BLOC, meme si elle tombe hors de la matiere : un pied
	# est de la falaise, et une falaise pend SOUS la surface qui la porte.
	x0 = mini(x0, cell.x)
	y0 = mini(y0, cell.y)
	x1 = maxi(x1, cell.x)
	y1 = maxi(y1, cell.y)
	var out: PackedStringArray = PackedStringArray()
	for y2: int in range(y0, y1 + 1):
		out.append(world[y2].substr(x0, x1 - x0 + 1))
	return [out, cell - Vector2i(x0, y0)]


## LA FAMILLE CONSTRUITE : un plateau d'etage un, et un massif d'etage deux qui le chevauche.
##
## ⚠ LE CHEVAUCHEMENT EST LE SUJET, PAS UN DETAIL DE POSE. C'est lui qui rend le massif AU RAS,
## et c'est pour ca que le porteur doit etre un vrai plateau plutot que le bord du monde : un
## porteur de matiere survit a la soudure, un porteur de vide non.
##
## ⚠ ET IL DOIT POUVOIR SE REFERMER EN C. Le L a suffi pour `PIED 69 cisaille a l'ouest`, pas
## pour `PIED 21 au ras`. Sa silhouette dit pourquoi : N+E+S, et rien a l'ouest. Il faut donc une
## POCHE fermee sur trois cotes -- la barre au nord, un bras a l'est, et un retour vers l'ouest
## au sud -- ouverte du seul cote ouest. Le bras seul ne ferme que deux cotes. On ajoute donc un
## retour, et la poche doit faire au moins trois cases de large, comme tout le reste : min trois
## vaut aussi pour le creux qu'on menage.
##
## ⚠ ET LE MASSIF PORTE DOIT POUVOIR ETRE EN L. Premiere famille : des rectangles, avec une
## simple entaille. Elle rencontrait bien quatorze tuiles AU RAS -- donc elle cherchait au bon
## endroit -- mais aucune des deux visees. La raison se lit dans leur silhouette : `PIED 21` vaut
## N+E+S, et `PIED 69 cisaille a l'ouest` demande de l'herbe du MEME massif a l'ouest du pied.
## Les deux reclament donc de la matiere AU SUD DE LA CHUTE, et l'empreinte d'un rectangle n'en
## a jamais : sous son pied, il n'y a plus rien. Il faut un massif dont un BRAS redescend le long
## de la chute -- une forme en L. C'est la meme piece qui porte les deux, ce qui est bon signe :
## une famille qui demanderait une forme par tuile ne serait pas une famille, ce serait une liste.
func _family() -> Array[PackedStringArray]:
	var made: Array[PackedStringArray] = []
	for plate_w: int in [10, 12]:
		for plate_h: int in [8]:
			for top_w: int in [4, 5, 6]:
				for top_h: int in [3, 4]:
					for arm_w: int in [0, 3]:
						for arm_h: int in [0, 3, 6]:
							for back_w: int in [0, 3, 4]:
								for east: int in [0, 1]:
									for dx: int in range(-top_w + 1, plate_w):
										for step: int in [0, 1, 2]:
											made.append(_one(plate_w, plate_h, top_w,
													top_h, arm_w, arm_h, back_w,
													east == 1, dx, step))
	return made


## UN MONDE. Le plateau au nord-ouest ; le massif porte a `dx` de son bord ouest ; un BRAS qui
## redescend au sud, large de `arm_w` et long de `arm_h`, colle a l'est ou a l'ouest du massif ;
## et `step` dit de combien de colonnes le massif est ENTAILLE a l'ouest -- c'est ce qui fabrique
## le cisaillement, de l'herbe et de la roche du meme massif cote a cote.
func _one(plate_w: int, plate_h: int, top_w: int, top_h: int, arm_w: int, arm_h: int,
		back_w: int, east: bool, dx: int, step: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for y: int in range(TALL):
		var line: PackedByteArray = PackedByteArray()
		line.resize(WIDE)
		line.fill(1)
		grid.append(line)
	var px: int = 5
	var py: int = 4
	for y1: int in range(plate_h):
		for x1: int in range(plate_w):
			grid[py + y1][px + x1] = 2
	for y2: int in range(top_h):
		for x2: int in range(top_w):
			if x2 < step and y2 >= top_h - 1:
				continue
			_raise(grid, px + dx + x2, py + y2)
	# LE BRAS. Il part du bord sud du massif et redescend le long de sa chute : c'est lui qui met
	# de la matiere sous le pied, donc du sud dans la silhouette de l'empreinte.
	var arm_x: int = px + dx + (top_w - arm_w if east else 0)
	for y3: int in range(arm_h):
		for x3: int in range(arm_w):
			_raise(grid, arm_x + x3, py + top_h + y3)
	# LE RETOUR. Il ferme la poche par le sud : la case qui s'y trouve a de la matiere au nord
	# (la barre), a l'est (le bras) et au sud (le retour), et rien a l'ouest.
	for x5: int in range(back_w):
		var bx: int = arm_x - x5 - 1 if east else arm_x + arm_w + x5
		for y5: int in range(3):
			_raise(grid, bx, py + top_h + arm_h - 3 + y5)
	for y4: int in range(TALL):
		for x4: int in range(WIDE):
			if y4 < 2 or y4 >= TALL - 2 or x4 < 2 or x4 >= WIDE - 2:
				grid[y4][x4] = 0
	return Gesture.text(grid)


func _raise(grid: Array[PackedByteArray], x: int, y: int) -> void:
	if y < 0 or y >= TALL or x < 0 or x >= WIDE:
		return
	var line: PackedByteArray = grid[y]
	line[x] = 3
	grid[y] = line


## LE TEMOIN, DANS LE CADRE EXACT QUE LE BATISSEUR LUI DONNERA.
func _survives(block: PackedStringArray, seat: Vector2i, tile: int) -> bool:
	if seat.x < 0:
		return false
	var edge: int = RIM + GAP
	var wide: int = block[0].length() + 2 * edge
	var tall: int = block.size() + edge + RIM + FALLOUT
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(1)
		grid.append(line)
	for y1: int in range(block.size()):
		var row: String = block[y1]
		for x1: int in range(row.length()):
			var c: String = row[x1]
			# ⚠ LE VIDE DU BLOC DEVIENT DE LA PLAINE : c'est ca, souder.
			var level: int = 0 if (c == "~" or c == "." or c == "0") else c.to_int()
			var line1: PackedByteArray = grid[edge + y1]
			line1[edge + x1] = maxi(int(line1[edge + x1]), level + 1)
			grid[edge + y1] = line1
	for y2: int in range(tall):
		for x2: int in range(wide):
			if y2 < RIM or y2 >= tall - RIM or x2 < RIM or x2 >= wide - RIM:
				grid[y2][x2] = 0
	var world: PackedStringArray = Gesture.text(grid)
	if not Gesture.legal(world):
		return false
	return int(Massifs.paintable(world).get(seat + Vector2i(edge, edge), -1)) == tile


## LE FICHIER GENERE. ⚠ TABLEAUX SIMPLES, ENVELOPPES A LA LECTURE : un `const` type
## `Array[PackedStringArray]` ne se resout pas, le membre cesse d'exister, et tout ce qui le
## precharge tombe avec lui sans une erreur claire. Piege deja paye.
func _write(path: String, found: Dictionary) -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# LES TEMOINS QUI SUPPORTENT LA SOUDURE.")
	lines.append("#")
	lines.append("# ⚠ GENERE PAR `tools/weld_witnesses.gd` -- ne pas editer a la main.")
	lines.append("# Chaque bloc est un relief qui porte sa tuile A SA CASE une fois entoure de")
	lines.append("# plaine continue -- ce que les blocs de `massif_witnesses.gd` ne font pas tous,")
	lines.append("# parce que leur porteur y est le bord du monde et non un vrai massif.")
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("")
	lines.append("## tuile -> les rangees du bloc.")
	lines.append("static func blocks() -> Dictionary:")
	lines.append("\treturn {")
	var keys: Array = found.keys()
	keys.sort()
	for tile: int in keys:
		var rows: PackedStringArray = (found[tile] as Array)[0]
		var quoted: PackedStringArray = PackedStringArray()
		for row: String in rows:
			quoted.append("\"%s\"" % row)
		lines.append("\t\t%d: PackedStringArray([%s]),  # %s"
				% [tile, ", ".join(quoted), Massifs.describe(tile)])
	lines.append("\t}")
	lines.append("")
	lines.append("")
	lines.append("## tuile -> la case ou le bloc la porte.")
	lines.append("static func seats() -> Dictionary:")
	lines.append("\treturn {")
	for tile1: int in keys:
		var cell: Vector2i = (found[tile1] as Array)[1]
		lines.append("\t\t%d: Vector2i(%d, %d),  # %s"
				% [tile1, cell.x, cell.y, Massifs.describe(tile1)])
	lines.append("\t}")
	lines.append("")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
	print("ecrit : %s (%d temoins)" % [path, found.size()])
