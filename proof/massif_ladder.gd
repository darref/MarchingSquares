extends SceneTree

## LE BANC DU NOUVEAU MODELE — il rend l'image et REGARDE LES PIXELS.
##
##     godot --headless --path . --script res://proof/massif_ladder.gd
##     godot --headless --path . --script res://proof/massif_ladder.gd -- 200   (tirages)
##
## ⚠ IL NE REDERIVE JAMAIS LE CALCUL QU'IL CONTROLE. C'est la faute la plus chere du projet, et
## elle est deja au dossier : un test qui recalcule avec la formule qu'il verifie certifie
## l'erreur au lieu de l'attraper. Ici on compose et on compte des pixels ; un trou est un trou,
## quelle que soit la regle qui a cru le boucher.
##
## Trois invariants, et ce sont ceux qui ont attrape TOUS les defauts de l'ancien modele :
##   I1 FERMETURE   le contour n'a aucune extremite ouverte -- rien ne pend dans le vide ;
##   I2 EPAISSEUR   aucun pave 2x2 entierement de trait -- deux traits ne se collent jamais ;
##   I6 VERITE      aucun pixel de fond la ou le monde a de la matiere ;
##   I7 UNICITE     deux tuiles ne rendent jamais la meme image ;
##   I8 FORME       toute tuile posee est dans la forme close ;
##   I9 LEGAL       le guide est un relief que le pinceau peut produire.
##
## ⚠ ET I6 NE REGARDE QUE LES CASES INTERIEURES. Une case du BORD du monde montre le vide sur
## une partie de sa case, et c'est juste -- c'est le rivage. Exiger l'opacite la accuserait le
## dessin d'etre fidele : on ne controle donc que les cases dont les HUIT voisines sont, elles
## aussi, de la matiere -- les huit, parce qu'un coin rentrant se creuse et montre la diagonale.

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")
const Scene := preload("res://render/massif_scene.gd")
const Thickness := preload("res://core/thickness.gd")
const MassifForm := preload("res://core/massif_form.gd")
const Gesture := preload("res://core/gesture.gd")
const Brush := preload("res://core/brush_vocabulary.gd")

## LES GUIDES LIVRES. ⚠ Ils se declarent ICI, une fois : le banc en lisait un seul,
## en dur, a deux endroits differents.
const GUIDES: Array[String] = ["res://guides/massifs.txt", "res://guides/terrain.txt"]

const RES: int = MassifTiles.RES
const OUTLINE: Color = MassifTiles.OUTLINE

## LES LIBERTES QUE LE BANC EPROUVE.
##
## ⚠ DEUX, PLUS TROIS. F2 -- le trait ondule -- est supprime (decision utilisateur du
## 05/09/2026) : le dessin calcule NE SERT QUE D'APERCU, l'artiste peint par-dessus. F0 reste, et
## ce n'est pas un style : c'est le PLANCHER, la profondeur d'UN pixel, et le banc doit prouver
## que les invariants tiennent aussi la ou le trait a le moins de place.
##
## ⚠ ET ELLE EST UNE CONSTANTE PARCE QU'UN COMPTE LA DIVISAIT EN DUR. I7 annoncait
## `drawings.size() / 3` : en passant de trois libertes a deux, il a dit « 55 tuiles, 36
## dessins » alors que le verdict etait juste. Un compteur qui ne mesure pas ce qu'il pretend
## mesurer est pire que pas de compteur -- et celui-la etait a UN chiffre ecrit a la main de le
## devenir.
const FREEDOMS: Array[int] = [0, 1]

## Le monde d'un tirage, et sa marge de vide : la falaise du bord du monde y tombe.
const WIDE: int = 22
const TALL: int = 38
const RIM: int = 4


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var draws: int = args[0].to_int() if not args.is_empty() else 60
	var worlds: Array[Dictionary] = []
	# ⚠ LES DEUX GUIDES LIVRES, PAS UN. Le banc ne lisait que le damier, et le paysage est un
	# guide LIVRE : personne n'avait jamais passe ses poses a I7 ni a I8. Un invariant qui ne
	# regarde qu'une moitie du produit ne garde que cette moitie.
	for path: String in GUIDES:
		worlds.append({"name": path.get_file().get_basename(), "world": HeightMask.read(path)})
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x4D415353
	var made: int = 0
	var refused: int = 0
	while made < draws:
		var one: PackedStringArray = _draw(rng)
		if one.is_empty():
			continue
		# ⚠ ET ON NE CACHE PAS CE QU'ON ECARTE. Un tirage qui viole la MARGE DE PIED est un
		# relief que le pinceau corrigera avant de le laisser poser : le banc prouve le DESSIN
		# sur des mondes legaux, pas sur des mondes que le produit ne fabriquera jamais. Le
		# compte est imprime -- une borne muette se lit comme « tout couvert ».
		if not Massifs.foot_faults(one).is_empty() 				or not Thickness.diagonal_pinches(one).is_empty() \
				or not _contained(one):
			refused += 1
			continue
		made += 1
		worlds.append({"name": "tirage %d" % made, "world": one})
	print("%d tirages retenus, %d ecartes (marge de pied ou pincement diagonal)"
			% [made, refused])

	var green: bool = true
	var vocabulary: Dictionary = {}
	for freedom: int in FREEDOMS:
		var ends: int = 0
		var pave: int = 0
		var holes: int = 0
		var mute: int = 0
		var poses: int = 0
		var worst: String = ""
		var species: Dictionary = {}
		for entry: Dictionary in worlds:
			var world: PackedStringArray = entry["world"]
			for pose: Dictionary in Massifs.poses(world):
				vocabulary[Massifs.key_of(pose)] = true
				poses += 1
			var image: Image = Scene.compose(world, freedom)
			var got: Dictionary = _measure(image, world, species, Massifs.poses(world))
			ends += int(got["ends"])
			pave += int(got["pave"])
			holes += int(got["holes"])
			mute += int(got["mute"])
			if worst.is_empty() and (int(got["ends"]) > 0 or int(got["pave"]) > 0
					or int(got["holes"]) > 0 or int(got["mute"]) > 0):
				worst = "%s : %s" % [entry["name"], got["where"]]
		var ok: bool = ends == 0 and pave == 0 and holes == 0 and mute == 0
		green = green and ok
		print("F%d  %s   I1 extremites %-5d I2 paves %-5d I6 trous %-5d I10 anneau %-5d  (%d poses)"
				% [freedom, "VERT " if ok else "ROUGE", ends, pave, holes, mute, poses])
		if not worst.is_empty():
			print("      premier defaut : %s" % worst)
			# ⚠ ET ON NOMME L'ESPECE, PAS SEULEMENT LE PIXEL. Un compte dit qu'il y a une
			# rupture, pas laquelle -- et sans le « qui trace contre qui » on corrige au juge.
			var kinds: Array[String] = []
			kinds.assign(species.keys())
			kinds.sort_custom(func(p: String, q: String) -> bool:
				return int(species[p]) > int(species[q]))
			for at: int in range(mini(6, kinds.size())):
				print("        %5d  %s" % [int(species[kinds[at]]), kinds[at]])

	var by_band: Dictionary = {}
	for key: int in vocabulary.keys():
		var name: String = "%s %s" % [Massifs.BAND_NAMES[Massifs.band_of(key)],
				"au ras" if Massifs.flush_of(key) else "libre"]
		by_band[name] = int(by_band.get(name, 0)) + 1
	var names: Array[String] = []
	names.assign(by_band.keys())
	names.sort()
	print("")
	print("LE VOCABULAIRE RENCONTRE : %d tuiles sur %d mondes" % [vocabulary.size(), worlds.size()])
	for name2: String in names:
		print("    %-22s %d" % [name2, int(by_band[name2])])
	print("")
	# I7 UNICITE : deux tuiles ne rendent jamais la meme image.
	#
	# ⚠ ET CE CONTROLE EST NE D'UNE QUESTION, PAS D'UNE INTUITION : « es-tu sur que les
	# specimens montrent des choses uniques ? ». Non -- 13 tuiles sur 55 rendaient une image
	# deja rendue par une autre. Au ras la profondeur est nulle, donc rien ne se creuse, pas
	# meme les coins rentrants : une tuile au ras ne depend que de ses quatre cardinaux. Faire
	# peindre deux fois le meme dessin est un cout pur, et la planche exportee en portait deux
	# cases identiques.
	var drawings: Dictionary = {}
	var twins: Array[String] = []
	for tile: int in vocabulary.keys():
		for freedom2: int in FREEDOMS:
			var one: Image = MassifTiles.shape(Massifs.sil_of(tile), Massifs.band_of(tile),
					Massifs.flush_of(tile), freedom2, Color(0, 0, 0, 0), 1,
					MassifTiles.PEINT, Massifs.cut_of(tile))
			var mark: String = "%d/%s" % [freedom2, Marshalls.raw_to_base64(one.get_data())]
			if drawings.has(mark):
				twins.append("F%d : %s == %s" % [freedom2, Massifs.describe(tile),
						drawings[mark]])
			else:
				drawings[mark] = Massifs.describe(tile)
	green = green and twins.is_empty()
	print("I7 unicite : %s (%d tuiles, %d dessins)"
			% ["VERT" if twins.is_empty() else "ROUGE", vocabulary.size(),
			drawings.size() / FREEDOMS.size()])
	for one2: String in twins:
		print("      %s" % one2)
	# I8 LA FORME CLOSE DIT-ELLE VRAI ? On compare dans les DEUX SENS : toute tuile POSEE doit
	# etre dans la forme. Une tuile posee hors de la forme n'est pas une curiosite -- c'est une
	# tuile que le guide ne portera pas, donc un trou dans le jeu, et une forme qui se croit
	# close alors qu'elle ne l'est pas. Un garde-fou qui ne regarde que d'un cote ne garde rien.
	var closed: Dictionary = {}
	for tile2: int in MassifForm.vocabulary():
		closed[tile2] = true
	var stray: Array[String] = []
	for tile3: int in vocabulary.keys():
		if not closed.has(tile3):
			stray.append(Massifs.describe(tile3))
	green = green and stray.is_empty()
	print("I8 forme close : %s (%d enumerees, %d posees, %d hors forme)"
			% ["VERT" if stray.is_empty() else "ROUGE", closed.size(), vocabulary.size(),
			stray.size()])
	for one3: String in stray:
		print("      %s" % one3)
	# I9 LE GUIDE EST LEGAL, au sens de la REGLE DU GESTE et d'elle seule.
	#
	# ⚠ IL MANQUAIT, ET C'EST PAR LA QUE DEUX GOUFFRES SONT PASSES. Les invariants regardaient
	# le DESSIN -- fermeture, epaisseur du trait, verite, unicite, forme -- et personne ne
	# regardait le RELIEF. Un guide qui contient un relief que le pinceau ne peut pas produire
	# fait peindre des tuiles qui n'arriveront jamais, et en cache d'autres.
	var wrongs: Array[String] = []
	for path1: String in GUIDES:
		for fault: String in Gesture.faults(HeightMask.read(path1)):
			wrongs.append("%s : %s" % [path1.get_file(), fault])
	green = green and wrongs.is_empty()
	print("I9 guide legal : %s%s" % ["VERT" if wrongs.is_empty() else "ROUGE",
			"" if wrongs.is_empty() else "  (" + ", ".join(wrongs) + ")"])

	# I11 LIVRAISON : un guide livre ne pose que des tuiles du vocabulaire livre.
	#
	# ⚠ ET CE N'EST PAS I8, MEME SI LES DEUX PARLENT DE LISTES. I8 compare a la FORME CLOSE --
	# un theoreme, exhaustif sur 2^18 fenetres, 140 tuiles : il dit que le modele n'invente rien.
	# I11 compare au VOCABULAIRE LIVRE -- ce qu'une BATTUE atteint, 60 tuiles, un echantillonnage :
	# il dit que la PLANCHE porte de quoi peindre le guide. Une tuile peut donc etre parfaitement
	# dans le modele et absente de la planche, et c'est exactement ce qui arrive.
	#
	# ⚠ ET IL MANQUAIT PARCE QU'ON NE COMPARAIT QUE DANS UN SENS. `build_terrain` verifie que
	# chacune des 60 tuiles visees est PRESENTE ; personne ne verifiait que le guide n'en pose
	# pas d'AUTRES. « Un garde-fou qui ne regarde que d'un cote ne garde rien » -- deja paye sur
	# le controle croise du plugin, puis sur les raccords, et repaye ici.
	#
	# ⚠ ET IL SE LIT SUR `visible`, PAS SUR `paintable` : le carnet range ce qui SE VOIT, etage 0
	# compris, et c'est lui qui decide ce que l'export doit porter.
	var absent: Array[String] = []
	var known: Dictionary = {}
	for tile3: int in Brush.tiles():
		known[tile3] = true
	for path2: String in GUIDES:
		var shown: Dictionary = Massifs.visible(HeightMask.read(path2))
		var said: Dictionary = {}
		for tile4: Variant in shown.values():
			if known.has(int(tile4)) or said.has(int(tile4)):
				continue
			said[int(tile4)] = true
			absent.append("%s : %s" % [path2.get_file(), Massifs.describe(int(tile4))])
	green = green and absent.is_empty()
	print("I11 livraison : %s (%d tuiles au vocabulaire livre)"
			% ["VERT" if absent.is_empty() else "ROUGE", known.size()])
	for line1: String in absent:
		print("    hors vocabulaire : %s" % line1)
	print("VERDICT : %s" % ("VERT" if green else "ROUGE"))
	quit(0 if green else 1)


## LES TROIS MESURES, sur l'image composee.
func _measure(image: Image, world: PackedStringArray, species: Dictionary,
		poses: Array[Dictionary] = []) -> Dictionary:
	var top: Dictionary = {}
	for pose: Dictionary in poses:
		if bool(pose["under"]):
			continue
		var at: Vector2i = pose["cell"]
		if top.has(at) and int((top[at] as Dictionary)["level"]) > int(pose["level"]):
			continue
		top[at] = pose
	var width: int = image.get_width()
	var height: int = image.get_height()
	var stroke: Array[PackedByteArray] = []
	var solid: Array[PackedByteArray] = []
	for y: int in range(height):
		var a: PackedByteArray = PackedByteArray()
		var b: PackedByteArray = PackedByteArray()
		a.resize(width)
		b.resize(width)
		for x: int in range(width):
			var c: Color = image.get_pixel(x, y)
			a[x] = 1 if c.is_equal_approx(OUTLINE) else 0
			b[x] = 1 if c.a >= 0.5 else 0
		stroke.append(a)
		solid.append(b)

	# I1 : un pixel de trait qui n'a qu'UN voisin de trait est une extremite. ⚠ Et une extremite
	# NOYEE dans la matiere n'est pas un trou -- le trait passe derriere une couche et reprend de
	# l'autre cote. On ne compte que celles qui touchent du fond.
	var ends: int = 0
	var where: String = ""
	for y2: int in range(height):
		for x2: int in range(width):
			if stroke[y2][x2] == 0:
				continue
			var around: int = 0
			var breathes: bool = false
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var nx: int = x2 + dx
					var ny: int = y2 + dy
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						breathes = true
						continue
					if solid[ny][nx] == 0:
						breathes = true
					if (dx != 0 or dy != 0) and stroke[ny][nx] == 1:
						around += 1
			if around > 1 or not breathes:
				continue
			ends += 1
			if not top.is_empty():
				var owner: Vector2i = Vector2i(x2 / RES, y2 / RES)
				var kind: String = "extremite de %s, au pixel %d,%d de sa case" 						% [_say(top.get(owner, {})), x2 % RES, y2 % RES]
				species[kind] = int(species.get(kind, 0)) + 1
			if where.is_empty():
				where = "extremite au pixel %d,%d (case %d,%d)" \
						% [x2, y2, x2 / RES, y2 / RES]

	# I2 : un pave 2x2 entierement de trait. ⚠ C'EST LUI QUI ATTRAPE LE DOUBLEMENT, pas le compte
	# de morceaux : deux traits colles forment UN seul morceau, donc le compte de morceaux est
	# content pendant que l'oeil voit un renflement.
	var pave: int = 0
	for y3: int in range(height - 1):
		for x3: int in range(width - 1):
			if stroke[y3][x3] == 1 and stroke[y3][x3 + 1] == 1 \
					and stroke[y3 + 1][x3] == 1 and stroke[y3 + 1][x3 + 1] == 1:
				# ⚠ UN PAVE N'EST UN DEFAUT QUE SI LES DEUX TRAITS DECRIVENT LA MEME FRONTIERE.
				# I2 a ete invente pour une frontiere tracee DEUX FOIS par deux couches : la ligne
				# devrait faire un pixel, elle en fait deux, et l'oeil lit un renflement. Deux faces
				# DIFFERENTES qui se rencontrent, ce n'est pas ca : il y a vraiment deux flancs, donc
				# deux traits, et la 3D est juste -- meme si ce sont deux massifs distincts.
				#
				# « Une adjacence n'est pas une frontiere », deja au dossier, applique a l'envers :
				# I2 comptait l'adjacence de pixels d'encre, pas l'identite de la frontiere.
				var one_a: Dictionary = top.get(Vector2i(x3 / RES, y3 / RES), {})
				var one_b: Dictionary = top.get(Vector2i((x3 + 1) / RES, (y3 + 1) / RES), {})
				if not one_a.is_empty() and not one_b.is_empty() and one_a != one_b \
						and (int(one_a["massif"]) != int(one_b["massif"])
						or (one_a["lip"] as Vector2i).y != (one_b["lip"] as Vector2i).y):
					continue
				pave += 1
				if where.is_empty():
					where = "pave au pixel %d,%d (case %d,%d)" % [x3, y3, x3 / RES, y3 / RES]
				if not top.is_empty():
					var ca: Vector2i = Vector2i(x3 / RES, y3 / RES)
					var cb: Vector2i = Vector2i((x3 + 1) / RES, (y3 + 1) / RES)
					var kind: String = "%s | %s (%s)" % [_say(top.get(ca, {})),
							_say(top.get(cb, {})),
							"vertical" if ca.y != cb.y else (
							"lateral" if ca.x != cb.x else "DEDANS")]
					species[kind] = int(species.get(kind, 0)) + 1

	# I6 : la matiere ne montre pas le fond. Cases INTERIEURES seulement -- voir l'en-tete.
	var holes: int = 0
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	for cy: int in range(tall):
		for cx: int in range(wide):
			if HeightMask.level_at(world, cx, cy) < 0:
				continue
			# ⚠ SUR LES HUIT VOISINES, PAS LES QUATRE. Un COIN RENTRANT se creuse, donc il
			# montre ce qui est en DIAGONALE : une case de plaine dont le coin touche le vide
			# laisse legitimement voir le vide a cet endroit. En ne regardant que les cardinales,
			# I6 accusait le dessin d'etre fidele.
			var inner: bool = true
			for dy2: int in range(-1, 2):
				for dx2: int in range(-1, 2):
					if HeightMask.level_at(world, cx + dx2, cy + dy2) < 0:
						inner = false
			if not inner:
				continue
			var pierced: bool = false
			for py: int in range(cy * RES, cy * RES + RES):
				for px: int in range(cx * RES, cx * RES + RES):
					if solid[py][px] == 0:
						pierced = true
			if pierced:
				holes += 1
				if where.is_empty():
					where = "case percee en %d,%d" % [cx, cy]

	# --- I10 : L'ANNEAU ---------------------------------------------------------------
	#
	# LE TRAIT QUI BORDE UNE SURFACE EST UN ANNEAU DEFORME CONTINU (formulation de
	# l'utilisateur, 06/09).
	#
	# ⚠ ET IL EST EPROUVE PAR SON ECHEC, PAS PAR SON SUCCES. Un invariant vert du premier coup ne
	# prouve rien : on a donc DESACTIVE `CUT_NORTH` le temps d'un banc, et I10 a compte QUATRE
	# anneaux coupes -- « guide : anneau coupe en 34,44 vers 0,-1 » -- pendant qu'I1, I2 et I6
	# restaient a zero. C'est la mesure qui montre que les cinq invariants d'avant ne voyaient
	# rien, et c'est la seule facon de savoir qu'un controle controle.
	#
	# ⚠ ET IL MANQUAIT, ALORS QUE LE BANC ETAIT VERT. I1 ne compte que les extremites QUI
	# TOUCHENT DU FOND -- « une extremite noyee dans la matiere n'est pas un trou : le trait
	# passe derriere une couche et reprend de l'autre cote » -- donc une coupure du trait AU
	# MILIEU DE L'HERBE lui echappe. C'est exactement ce qui s'est passe au coude du
	# cisaillement : la case rendait la tuile pleine, aucun pixel de trait, et les cinq
	# invariants restaient verts pendant que le contour s'interrompait.
	#
	# ⚠ ON NE PARCOURT PAS UN CYCLE, ON VERIFIE SES SEGMENTS -- et c'est ce qui rend la mesure
	# simple. La frontiere d'une surface est DEJA un cycle ferme par topologie : c'est le bord
	# d'un ensemble de cases. Si chaque segment porte du trait, l'anneau est continu ; il n'y a
	# donc rien a suivre, seulement a compter les segments MUETS.
	#
	# ⚠ ET LA FRONTIERE SE LIT SUR CE QUI SE VOIT, PAS SUR L'EMPREINTE. Une frontiere recouverte
	# par un troisieme massif n'a pas a etre tracee : c'est de l'occlusion, pas un trou. On ne
	# compte donc que les segments dont les DEUX cotes montrent des tuiles du MEME massif -- et
	# c'est la que le coude tombe, puisque ses deux cotes sont a lui.
	var mute: int = 0
	for cell: Vector2i in top.keys():
		var here: Dictionary = top[cell]
		if int(here["band"]) != Massifs.SURFACE:
			continue
		for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var near: Dictionary = top.get(cell + step, {})
			if near.is_empty():
				continue
			if int(near["massif"]) != int(here["massif"]):
				continue
			# Une frontiere : de l'herbe d'un cote, de la roche de l'autre, dans le meme massif.
			if int(near["band"]) == Massifs.SURFACE:
				continue
			# ⚠ LE SUD EST EXCLU, ET CE N'EST PAS UNE FAVEUR. Sous une surface, la roche est sa
			# propre falaise : le trait de la levre est porte par le CHAPITEAU, une rangee plus
			# bas, et le demander a la surface reviendrait a le tracer deux fois -- ce qu'I2
			# refuse.
			if step == Vector2i.DOWN:
				continue
			var inked: bool = false
			for along: int in range(RES):
				var ax: int = cell.x * RES + (along if step.y != 0 else (
						0 if step.x < 0 else RES - 1))
				var ay: int = cell.y * RES + (along if step.x != 0 else (
						0 if step.y < 0 else RES - 1))
				var bx: int = ax + step.x
				var by: int = ay + step.y
				if stroke[ay][ax] == 1:
					inked = true
					break
				if by >= 0 and by < height and bx >= 0 and bx < width and stroke[by][bx] == 1:
					inked = true
					break
			if not inked:
				mute += 1
				if where.is_empty():
					where = "anneau coupe en %d,%d vers %d,%d" % [cell.x, cell.y, step.x, step.y]

	return {"ends": ends, "pave": pave, "holes": holes, "mute": mute, "where": where}


func _say(pose: Variant) -> String:
	if not (pose is Dictionary) or (pose as Dictionary).is_empty():
		return "rien"
	var one: Dictionary = pose as Dictionary
	return "%s/%d/e%d/%s" % [Massifs.BAND_NAMES[int(one["band"])], int(one["sil"]),
			int(one["level"]), "ras" if bool(one["flush"]) else "libre"]


## UN RELIEF EPAIS TIRE AU SORT : des tampons 3x3, comme le pinceau les pose.
##
## ⚠ ET LE DOMAINE ENUMERE DOIT ETRE LE DOMAINE. Des blocs rectangulaires ne produisent ni
## encoche, ni coude, ni bord sud decroche : ils rendraient un vocabulaire deux fois trop petit
## et le banc ne verrait jamais les cas qui cassent.
func _draw(rng: RandomNumberGenerator) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for y: int in range(TALL):
		var line: PackedByteArray = PackedByteArray()
		line.resize(WIDE)
		line.fill(0)
		grid.append(line)
	for x: int in range(RIM, WIDE - RIM):
		for y2: int in range(RIM, TALL - RIM):
			var row: PackedByteArray = grid[y2]
			row[x] = 1
			grid[y2] = row
	# Les plateaux : des tampons 3x3, chacun elevant ce qu'il touche d'un etage.
	for _stamp: int in range(rng.randi_range(3, 10)):
		var ox: int = rng.randi_range(RIM + 1, WIDE - RIM - 4)
		var oy: int = rng.randi_range(RIM + 1, TALL - RIM - 8)
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				var row2: PackedByteArray = grid[y3]
				row2[x3] = mini(int(row2[x3]) + 1, 4)
				grid[y3] = row2
	var text: PackedStringArray = PackedStringArray()
	for line2: PackedByteArray in grid:
		var said: String = ""
		for v: int in line2:
			said += "~" if v == 0 else str(v - 1)
		text.append(said)
	if not Thickness.thin_cells(text).is_empty():
		return PackedStringArray()
	return text



## UN MONDE DOIT CONTENIR SES PROPRES CHUTES.
##
## ⚠ UNE FACE QUI SORT DU CADRE EST ECRETEE PAR L IMAGE, PAS PAR LE RELIEF : son trait meurt au
## bord, et le banc accuse le dessin d un defaut que seul le cadre a produit. Depuis le tampon a
## etage choisi, une chute de quatre etages fait quinze rangees -- le cadre d avant n en gardait
## que quatre sous la levre la plus basse. Meme lecon qu au premier modele : un relief declare
## son bord, et une robe hors grille est une tuile impeignable.
func _contained(world: PackedStringArray) -> bool:
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if cell.x < 0 or cell.y < 0 or cell.x >= wide or cell.y >= tall:
			return false
	return true
