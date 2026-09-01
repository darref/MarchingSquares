extends SceneTree

## LE GUIDE DU NOUVEAU MODELE : UN ILOT PAR TUILE, CALCULE.
##
##     godot --headless --path . --script res://tools/build_massifs.gd -- <sortie.txt>
##
## ⚠ IL N'EST PLUS DESSINE A LA MAIN, ET C'EST LA REPONSE A « COMMENT SAIT-ON QU'ON COUVRE
## TOUT ? ». Dix formes dessinees a la main exercaient 37 tuiles sur 88 -- et rien ne le disait.
## Un guide ecrit a la main est une donnee a maintenir, donc un endroit ou mentir : c'est
## exactement l'argument qui fait calculer les 47 index, la planche de preuve et les ilots de
## bord. Ici la FORME CLOSE donne la liste, l'enumeration donne pour chaque tuile une FENETRE qui
## la produit, et l'ilot n'est que cette fenetre ETIREE.
##
## ⚠ ET ON REVERIFIE DANS LE GUIDE ASSEMBLE, JAMAIS DANS SON COIN. Un temoin juste tout seul peut
## se faire manger par sa marge ou son socle : la decoupe ment, c'est deja au dossier. Le controle
## final lit `Massifs.analyse` sur le fichier ecrit, et il verifie en plus que CHAQUE ilot porte
## bien la tuile qu'il annonce -- sans quoi une tuile trouvee ailleurs par accident rendrait le
## compte vert pendant que l'ilot ment.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifForm := preload("res://core/massif_form.gd")
const Witnesses := preload("res://core/massif_witnesses.gd")

## L'ilot : la fenetre 3x6 etiree de deux cases de chaque cote.
const PAD: int = 2
const ISLE_W: int = MassifForm.COLS + 2 * PAD
const ISLE_H: int = MassifForm.ROWS + 2 * PAD

## Le pave qui porte un ilot, marges comprises.
##
## ⚠ ET C'EST LE SOCLE QUI DICTE SA LARGEUR, PAS L'ILOT. Premier essai a treize : l'ilot fait
## sept, mais son socle en fait onze, et il ne restait que DEUX colonnes de plaine entre deux
## paves -- une course de deux, donc fine, donc 1 368 cases refusees par l'epaisseur. On mesure
## la marge sur ce qu'on pose vraiment, jamais sur ce qu'on croit poser.
const BLOCK_W: int = 19
const BLOCK_H: int = 24
const COLUMNS: int = 8
## La marge de vide autour du guide : la falaise du bord du monde y tombe.
const RIM: int = 4
## Le socle d'un ilot AU RAS : il deborde d'autant, et de quoi porter le pied.
const BASE_SIDE: int = 2
const BASE_SOUTH: int = 4


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "res://guides/massifs.txt"
	var whole: Array[int] = MassifForm.vocabulary()
	# ⚠ DEUX TABLES, PARCE QU'UNE TUILE AU RAS N'A PAS LA MEME PROVENANCE QU'UNE LIBRE : la cle
	# du dessin ne remonte pas a un couple unique.
	var wits: Dictionary = MassifForm.sources(false)
	var wits_ras: Dictionary = MassifForm.sources(true)
	# ⚠ ON NE BATIT QUE CE QU'ON SAIT PORTER, ET ON DIT CE QU'ON LAISSE. La forme close est une
	# BORNE HAUTE : elle enonce ce que le modele peut produire, pas ce qu'on sait mettre sous le
	# crayon. Une tuile sans ilot est une tuile que personne ne pourra peindre -- donc un trou
	# dans le jeu -- et la charte tranche : ce qui n'est pas garanti est interdit. Les autres
	# restent au fichier avec leurs fenetres ; elles entreront le jour ou un temoin sera trouve.
	var blocks: Dictionary = Witnesses.blocks()
	var wanted: Array[int] = []
	var out_of_reach: Array[int] = []
	for tile: int in whole:
		if _choose(tile, wits_ras if Massifs.flush_of(tile) else wits) >= 0 or blocks.has(tile):
			wanted.append(tile)
		else:
			out_of_reach.append(tile)
	print("forme close %d tuiles ; %d portees, %d hors de portee"
			% [whole.size(), wanted.size(), out_of_reach.size()])
	var said0: Array[String] = []
	for tile2: int in out_of_reach:
		said0.append(Massifs.describe(tile2))
	if not said0.is_empty():
		print("  hors de portee : %s" % " | ".join(said0))

	var rows: int = (wanted.size() + COLUMNS - 1) / COLUMNS
	var wide: int = 2 * RIM + COLUMNS * BLOCK_W
	var tall: int = 2 * RIM + rows * BLOCK_H
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	# LA PLAINE, partout sauf le lisere de vide. ⚠ ETAGE ZERO -- a un, tout le cadre devient un
	# seul massif geant qui avale les ilots.
	for y2: int in range(RIM, tall - RIM):
		for x2: int in range(RIM, wide - RIM):
			_put(grid, x2, y2, 0)

	var centres: Array[Vector2i] = []
	var chosen: Array[int] = []
	var blind: int = 0
	for at: int in range(wanted.size()):
		var bx: int = RIM + (at % COLUMNS) * BLOCK_W
		var by: int = RIM + (at / COLUMNS) * BLOCK_H
		var bits: int = _choose(wanted[at],
				wits_ras if Massifs.flush_of(wanted[at]) else wits)
		chosen.append(bits)
		if bits >= 0:
			_stamp(grid, wanted[at], bits, bx, by)
			centres.append(Vector2i(bx + 3 + PAD + MassifForm.CX,
					by + 3 + PAD + MassifForm.CY))
			continue
		# ⚠ CE QUE LA FENETRE ETIREE NE PORTE PAS, LE TEMOIN TROUVE LE PORTE. Il n'est pas
		# dessine a la main : `tools/massif_witnesses.gd` le cherche, puis le relit.
		if not blocks.has(wanted[at]):
			blind += 1
			centres.append(Vector2i(-1, -1))
			continue
		_place(grid, blocks[wanted[at]] as PackedStringArray, bx + 2, by + 2)
		centres.append(Vector2i(bx + 2, by + 2) + Witnesses.AT)
	if blind > 0:
		print("  ⚠ %d tuile(s) sans fenetre ETIREE ni TEMOIN" % blind)

	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said: String = ""
		for v: int in line2:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(text) + "\n")
	file.close()
	print("guide ecrit : %s (%dx%d), %d ilots" % [out, wide, tall, wanted.size()])
	_audit(text, wanted, centres, chosen)
	quit(0)


func _put(grid: Array[PackedByteArray], x: int, y: int, level: int) -> void:
	if y < 0 or y >= grid.size():
		return
	var line: PackedByteArray = grid[y]
	if x < 0 or x >= line.size():
		return
	line[x] = maxi(int(line[x]), level + 1)
	grid[y] = line


## POSE UN BLOC DE TEMOIN, tel quel : ses etages sont ceux qu'on a mesures, pas un maximum.
func _place(grid: Array[PackedByteArray], block: PackedStringArray, ox: int, oy: int) -> void:
	for y: int in range(block.size()):
		for x: int in range(block[y].length()):
			var here: String = block[y].substr(x, 1)
			if here == "~":
				continue
			_put(grid, ox + x, oy + y, here.to_int())


## POSE L'ILOT D'UNE TUILE, et rend la fenetre retenue.
##
## ⚠ UNE TUILE AU RAS EST UN MASSIF D'ETAGE 2, ET C'EST TOUT CE QUE « AU RAS » VEUT DIRE : elle
## en recouvre un autre. On lui donne donc un socle d'etage 1 -- qui doit porter son PIED avec une
## rangee de rab, sans quoi la marge de pied saute.
func _stamp(grid: Array[PackedByteArray], tile: int, bits: int, bx: int, by: int) -> void:
	var flush: bool = Massifs.flush_of(tile)
	var level: int = 2 if flush else 1
	var isle: Array[PackedByteArray] = MassifForm.stretched(bits, PAD)
	var ox: int = bx + 3
	var oy: int = by + 3
	if flush:
		# ⚠ ET LE SOCLE S'ARRETE NET AU BORD OUEST DE L'ILOT -- c'est ce qui fait le
		# CHEVAUCHEMENT. Un socle qui entoure l'ilot en fait un massif « entierement entoure »,
		# donc LIBRE : les vingt-six tuiles au ras cessaient d'exister dans le guide sans que
		# rien ne le dise. En laissant l'ilot affleurer la frontiere du porteur, son contour
		# longe celle du massif du dessous -- une partie dedans, une partie dehors -- et il n'a
		# plus, par principe, d'autre rendez-vous que la bordure de tuile.
		for y: int in range(-BASE_SIDE, ISLE_H + Massifs.FALL + BASE_SOUTH):
			for x: int in range(0, ISLE_W + BASE_SIDE):
				_put(grid, ox + x, oy + y, 1)
	for x2: int in range(ISLE_W):
		for y2: int in range(ISLE_H):
			if int(isle[x2][y2]) == 1:
				_put(grid, ox + x2, oy + y2, level)


## LA FENETRE QUI TIENT, et c'est la seule facon honnete de la trouver.
##
## ⚠ UNE FENETRE N'EST PAS UN ILOT. L'enumeration raisonne sur trois colonnes et six rangees, et
## elle a le droit de supposer que deux composantes distinctes de la fenetre sont reliees DEHORS.
## L'ilot, lui, est un monde fini : ce qui n'est pas relie dedans ne l'est nulle part. Prendre la
## premiere fenetre venue donnait 53 ilots sur 88 qui portaient une AUTRE tuile que la leur --
## et le compte global, lui, restait content. On essaie donc toutes les fenetres du couple, on
## BATIT l'ilot, et on lit ce que la case porte vraiment.
func _choose(tile: int, wits: Dictionary) -> int:
	for bits: int in (wits[tile] as Array[int]):
		var mini: PackedStringArray = _alone(tile, bits)
		var paint: Dictionary = Massifs.paintable(mini)
		var centre: Vector2i = Vector2i(RIM + BASE_SIDE + PAD + MassifForm.CX,
				RIM + BASE_SIDE + PAD + MassifForm.CY)
		if int(paint.get(centre, -1)) != tile:
			continue
		if not Thickness.thin_cells(mini).is_empty():
			continue
		if not Massifs.foot_faults(mini).is_empty():
			continue
		return bits
	return -1


## L'ilot seul dans son cadre, pour le juger avant de le poser.
func _alone(tile: int, bits: int) -> PackedStringArray:
	var wide: int = 2 * RIM + 2 * BASE_SIDE + ISLE_W
	var tall: int = 2 * RIM + 2 * BASE_SIDE + ISLE_H + 2 * Massifs.FALL + BASE_SOUTH
	var grid: Array[PackedByteArray] = []
	for y: int in range(tall):
		var line: PackedByteArray = PackedByteArray()
		line.resize(wide)
		line.fill(0)
		grid.append(line)
	for y2: int in range(RIM, tall - RIM):
		for x2: int in range(RIM, wide - RIM):
			_put(grid, x2, y2, 0)
	_stamp(grid, tile, bits, RIM - 3 + BASE_SIDE, RIM - 3 + BASE_SIDE)
	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said: String = ""
		for v: int in line2:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	return text


## CE QUE LE GUIDE PORTE VRAIMENT, lu sur le fichier ecrit.
func _audit(world: PackedStringArray, wanted: Array[int], centres: Array[Vector2i],
		chosen: Array[int]) -> void:
	var got: Dictionary = Massifs.analyse(world, wanted)
	var thin: Array[Vector3i] = Thickness.thin_cells(world)
	var faults: Array[Vector2i] = Massifs.foot_faults(world)
	print("  %d/%d tuiles peignables" % [int(got["found"]), int(got["wanted"])])
	print("  %d case(s) fine(s), %d faute(s) de marge de pied" % [thin.size(), faults.size()])
	var paint: Dictionary = Massifs.paintable(world)
	var wrong: int = 0
	var said: Array[String] = []
	for at: int in range(wanted.size()):
		var here: int = int(paint.get(centres[at], -1))
		if here == wanted[at]:
			continue
		wrong += 1
		if said.size() < 10:
			said.append("%s : la case porte %s" % [Massifs.describe(wanted[at]),
					"rien" if here < 0 else Massifs.describe(here)])
	print("  %d ilot(s) qui ne portent pas leur tuile" % wrong)
	for one: String in said:
		print("      %s" % one)
	var missing: Array[String] = []
	for tile: int in (got["missing"] as Array[int]):
		missing.append(Massifs.describe(tile))
	if not missing.is_empty():
		print("  manquantes : %s" % " | ".join(missing))
