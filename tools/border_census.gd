extends SceneTree

## LE RECENSEMENT DES FRONTIERES : pour chaque espece de frontiere que le modele pose,
## COMBIEN DE TUILES LA REVENDIQUENT.
##
##     godot --headless --path . --script res://tools/border_census.gd -- [mondes] [F]
##
## ⚠ IL EXISTE PARCE QUE I3 NE SAIT PAS NOMMER LES FRONTIERES D'UNE FACE, et il le dit
## lui-meme : « tant que le banc ne sait pas nommer les frontieres d'une face, on n'y juge que
## le DOUBLEMENT ». Sa boucle fait `continue` des qu'une robe est en jeu. Les frontieres qu'il
## compte excluent donc TOUTES celles qui touchent une falaise -- c'est-a-dire exactement la
## famille qu'on cherche a reattribuer. C'est pour ca qu'il restait vert pendant que I1
## explosait sous le transfert de la crete.
##
## ⚠ ET C'EST UN RECENSEMENT, PAS UNE FORMULE. Meme lecon que le recensement des jonctions :
## « `Seams` deduisait ses classes d'une FORMULE au lieu de les lire du monde », et il en
## ignorait 60 sur 109. On assemble, on regarde l'image, on note ce qu'on voit.
##
## ⚠ ET LA SONDE EST UNE COPIE DE CELLE DU BANC, DONC ELLE SE CONTROLE. Sur les frontieres que
## I3 sait juger -- celles sans robe -- les deux comptes doivent coincider. Deux copies d'une
## meme regle finissent toujours par se contredire, sauf si on les confronte.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Walls := preload("res://core/walls.gd")
const Brink := preload("res://core/brink.gd")
const Compose := preload("res://render/contour.gd")
const Tiles := preload("res://render/contour_tiles.gd")
const Modes := preload("res://core/modes.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")

const LEVEL: int = 3
const RES := Tiles.RES
const OUTLINE := Tiles.OUTLINE
const STEPS := Brink.STEPS
const SIDE_NAMES: Array[String] = ["nord", "est", "sud", "ouest"]

## espece -> {"vus": n, "zero": n, "un": n, "deux": n, "ou": [..]}
var _kinds: Dictionary = {}
## L'ordre d'apparition des especes, pour dire QUAND le recensement sature.
var _order: Array[String] = []
var _curve: Array[String] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var rounds: int = args[0].to_int() if args.size() > 0 else 120
	var freedom: int = args[1].to_int() if args.size() > 1 else 2
	Tiles.level = LEVEL
	print("=== LE RECENSEMENT DES FRONTIERES (L%d/F%d) ===" % [LEVEL, freedom])
	# ⚠ LES MONDES LIVRES D'ABORD : ils portent le vocabulaire PAR CONSTRUCTION, la ou une
	# battue ne porte que ce que le hasard lui donne.
	_walk("guide", HeightMask.read(Modes.guide_path(Modes.EPAIS)), freedom)
	_walk("planche", ProofScene.relief(Families.BY_CELL), freedom)
	for run: int in range(rounds):
		_walk("aligne %d" % run, _aligned(run), freedom)
	for run2: int in range(rounds):
		_walk("decale %d" % run2, _offset(20260901 + run2 * 7919), freedom)
	_report()
	quit(0)


## UNE ESPECE DE FRONTIERE : ce qu'il y a de chaque cote, dit en clair.
##
## ⚠ ET ON NOMME CE QUI EST VISIBLE, PAS CE QUE LA CARTE PORTE. Une case de robe est, sur la
## carte, une case du sol d'en bas -- lui demander son etage ne dit rien de la face qui la
## couvre. C'est le piege deja paye au dossier ; ici on demande d'abord `roles`.
func _face(cell: Vector2i, world: PackedStringArray, roles: Dictionary) -> String:
	if roles.has(cell):
		# ⚠ LA CLE D'UNE ROBE PORTE MAINTENANT SON ARETE, donc elle est en Vector3i. La lire
		# en Vector2i rendait une chaine VIDE, et toutes les especes de face se sont mises a
		# s'appeler « » -- une etiquette fausse qui ne ressemble meme pas a une erreur.
		var row: int = (roles[cell] as Vector3i).y if roles[cell] is Vector3i 				else (roles[cell] as Vector2i).y
		return "face:%s" % Walls.ROW_NAMES[row]
	var level: int = -1
	if cell.x >= 0 and cell.y >= 0 and cell.x < HeightMask.width(world) 			and cell.y < HeightMask.height(world):
		level = HeightMask.level_at(world, cell.x, cell.y)
	if level < 0:
		return "vide"
	return "sommet"


## LA LEVRE D'UNE CASE DE ROBE : on remonte jusqu'a la premiere case sans robe. Deux cases de
## face appartiennent a LA MEME FACE si elles pendent de la meme levre -- meme rangee, meme
## etage.
##
## ⚠ ET C'EST L'ARETE INTERNE QUI SE JOUE LA. Deux faces cote a cote qui ne pendent pas de la
## meme levre ont de la roche des DEUX cotes : aucun invariant ne reclamera jamais un trait --
## I1 ne voit pas de trou, I3 pas de frontiere. C'est pourtant elle qui donne le relief, et
## c'est pour ca qu'elle doit etre NOMMEE avant qu'on fixe quoi que ce soit : verte partout, et
## absente a l'oeil.
func _lip_of(cell: Vector2i, roles: Dictionary, lips: Dictionary) -> Vector2i:
	var up: Vector2i = cell
	var guard: int = 0
	while roles.has(up + Vector2i.UP) and guard < 64:
		up += Vector2i.UP
		guard += 1
	return Vector2i(up.y - 1, int(lips.get(cell, -1)))



## LE PARCOURS : chaque arete entre deux cases, nommee et comptee.
func _walk(name: String, world: PackedStringArray, freedom: int) -> void:
	var before: int = _kinds.size()
	var made: Dictionary = Compose.compose(world, LEVEL, freedom)
	var image: Image = made["image"]
	var roles: Dictionary = made["roles"]
	var lips: Dictionary = (made["seen"] as Dictionary).get("lips", {}) if made.has("seen") 			else {}
	var width: int = HeightMask.width(world)
	var height: int = HeightMask.height(world)
	for y: int in range(height):
		for x: int in range(width):
			var cell: Vector2i = Vector2i(x, y)
			# ⚠ CHAQUE ARETE UNE SEULE FOIS : depuis l'est et le sud. La compter des deux
			# cotes doublerait tout le tableau sans rien apprendre.
			for side: int in [1, 2]:
				var probe: Vector2i = cell + STEPS[side]
				var mine: String = _face(cell, world, roles)
				var theirs: String = _face(probe, world, roles)
				if mine == "vide" and theirs == "vide":
					continue
				var mine_level: int = HeightMask.level_at(world, x, y)
				var their_level: int = HeightMask.level_at(world, probe.x, probe.y)
				var step: String = "="
				if mine.begins_with("sommet") and theirs.begins_with("sommet"):
					step = "=" if mine_level == their_level else (
							">" if mine_level > their_level else "<")
				# ⚠ UNE ADJACENCE N'EST PAS UNE FRONTIERE, ET LA MATIERE NE PEUT PAS EN
				# DECIDER. Premiere version : lire la couleur au bord, des deux cotes, et
				# conclure « meme matiere -> interieur ». Faux, et de la pire facon -- elle
				# rendait 15 especes mal etiquetees, dont sommet/face. L'image est ASSEMBLEE :
				# la ou une tuile est coupee on voit LA COUCHE DU DESSOUS, donc de part et
				# d'autre d'une frontiere sommet/face le pixel visible est la meme herbe
				# enterree. La matiere ment ; c'est au MODELE de dire ou le monde a un bord.
				#
				# La regle, et elle tient en quatre cas :
				#   robe | robe   -> la roche est continue ; ce n'est pas une frontiere de
				#                    matiere. L'arete interne est traitee a part, plus haut.
				#   robe | sommet -> la roche s'arrete, le sommet commence : FRONTIERE.
				#   sommet|sommet -> frontiere si les etages different, interieur sinon.
				#   quoi que ce soit | vide -> frontiere.
				var wall_a: bool = mine.begins_with("face")
				var wall_b: bool = theirs.begins_with("face")
				var inner: bool = false
				if wall_a and wall_b:
					# ⚠ ET DEUX FACES NE SONT PAS FORCEMENT LA MEME FACE. Meme levre : la
					# roche est continue, zero trait est juste. Levres differentes : c'est
					# l'ARETE INTERNE, et depuis qu'elle est adoptee elle VEUT son trait --
					# la declarer interieure reprocherait au dessin de la porter.
					var a: Vector2i = _lip_of(cell, roles, lips)
					var b: Vector2i = _lip_of(probe, roles, lips)
					inner = a == b
					step = "meme levre" if inner else "ARETE INTERNE"
				elif mine == "vide" or theirs == "vide":
					inner = false
				elif wall_a != wall_b:
					inner = false
				else:
					inner = mine_level == their_level
				var kind: String = "%s %s %s %s" % [mine, SIDE_NAMES[side], theirs, step]
				if inner:
					kind = "INTERIEUR " + kind
				var claims: int = _claims(image, cell, probe, side)
				_note(kind, claims, "%s %d,%d" % [name, x, y])
	_pans(world, roles, lips)
	if _kinds.size() > before:
		_curve.append("  %-12s : %d espece(s) au total (+%d)"
				% [name, _kinds.size(), _kinds.size() - before])


func _note(kind: String, claims: int, where: String) -> void:
	if not _kinds.has(kind):
		_kinds[kind] = {"vus": 0, "zero": 0, "un": 0, "deux": 0, "ou": []}
		_order.append(kind)
	var box: Dictionary = _kinds[kind]
	box["vus"] = int(box["vus"]) + 1
	var slot: String = "zero" if claims == 0 else ("un" if claims == 1 else "deux")
	box[slot] = int(box[slot]) + 1
	if claims != 1 and (box["ou"] as Array).size() < 3:
		(box["ou"] as Array).append("%s (%d)" % [where, claims])


## LA SONDE, RESSERREE : trois positions au lieu d'une, et on garde la plus informee.
##
## ⚠ UNE SEULE LIGNE AU MILIEU LAISSE PASSER DES FRONTIERES COURTES. Le trait d'un bord peut
## rentrer, serpenter, ou ne border qu'une partie du cote : sonde au seul milieu, il echappe, et
## la frontiere se declare muette alors qu'elle est tracee deux pixels plus loin. Mesure : 157
## occurrences eparpillees sur vingt especes, toutes de cette espece-la.
##
## ⚠ MAIS ON NE BALAIE PAS TOUTE LA BANDE POUR AUTANT, et c'est la lecon du banc, REPAYEE ICI :
## le trait du NORD traverse la tuile de part en part, donc une sonde qui longe le bord OUEST le
## rencontre et le prend pour une revendication de l'ouest. Essaye aux QUARTS -- `RES/4` et
## `3*RES/4` -- ca recupere 158 muettes et fabrique **12 050 fausses revendications sur des
## aretes interieures**. Refute par sa propre mesure.
##
## ⚠ ET MEME A UN PIXEL PRES C'EST TROP : `RES/2 +/- 1` fabrique encore **3 144 fausses
## revendications**. La sonde reste donc au MILIEU SEUL -- celle du banc, et pour sa raison.
##
## ⚠ ET C'EST LA MESURE QUI L'A TRANCHE, PAS LE RAISONNEMENT. Les trois sondes donnent
## EXACTEMENT les memes 157 muettes hors de la levre : elargir n'en recupere aucune, ca ne
## deplace que des occurrences de la levre -- lesquelles sont justement celles que le trait
## perpendiculaire contamine. Les 157 ne sont donc pas un artefact de sonde ; ce sont de vraies
## frontieres que personne ne trace.
##
## La fonction garde sa forme a plusieurs positions : c'est la trace de l'essai, et un chiffre
## qu'on ne peut plus reproduire n'est plus un chiffre.
func _claims(image: Image, cell: Vector2i, probe: Vector2i, side: int) -> int:
	var best: int = 0
	for at: int in [RES / 2]:
		best = maxi(best, _draws(image, cell, side, at)
				+ _draws(image, probe, (side + 2) % 4, at))
	return best


## LA SONDE : combien de traits ce cote porte-t-il. Copie de celle du banc -- on part du bord
## vers le milieu, au MILIEU du cote, et on compte les passages de fond a trait.
func _draws(image: Image, cell: Vector2i, side: int, along: int = RES / 2) -> int:
	var middle: int = RES / 2
	var runs: int = 0
	var inside: bool = false
	for d: int in range(middle):
		var at: Vector2i = Vector2i.ZERO
		match side:
			0: at = Vector2i(cell.x * RES + along, cell.y * RES + d)
			1: at = Vector2i(cell.x * RES + RES - 1 - d, cell.y * RES + along)
			2: at = Vector2i(cell.x * RES + along, cell.y * RES + RES - 1 - d)
			_: at = Vector2i(cell.x * RES + d, cell.y * RES + along)
		if at.x < 0 or at.y < 0 or at.x >= image.get_width() or at.y >= image.get_height():
			inside = false
			continue
		var here: bool = image.get_pixel(at.x, at.y).is_equal_approx(OUTLINE)
		if here and not inside:
			runs += 1
		inside = here
	return runs


## LA FAMILLE ALIGNEE, ENUMEREE : 3x3 tampons de 3x3, trois etats. C'est le domaine du pinceau.
func _aligned(order: int) -> PackedStringArray:
	var levels: Array[int] = []
	var rest: int = order
	for block: int in range(9):
		levels.append(rest % 3)
		rest /= 3
	return _framed(levels, 3, 3)


## LES POSES DECALEES : le meme domaine, sans l'alignement. Mesure au dossier : la famille
## alignee ne rend AUCUN des dix dessins qui manquaient au guide -- il faut le decalage.
func _offset(graine: int) -> PackedStringArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = graine
	var width: int = 22
	var height: int = 20
	var grid: Array[PackedByteArray] = []
	for y: int in range(height):
		var line: PackedByteArray = PackedByteArray()
		line.resize(width)
		line.fill(1)
		grid.append(line)
	for shape: int in range(rng.randi_range(2, 6)):
		var level: int = rng.randi_range(0, 3)
		var w: int = rng.randi_range(3, 10)
		var h: int = rng.randi_range(3, 10)
		var ox: int = rng.randi_range(2, width - 2 - w)
		var oy: int = rng.randi_range(2, height - 2 - h)
		var before: Array[PackedByteArray] = []
		for line2: PackedByteArray in grid:
			before.append(line2.duplicate())
		for y2: int in range(oy, oy + h):
			for x2: int in range(ox, ox + w):
				var row: PackedByteArray = grid[y2]
				row[x2] = level + 1
				grid[y2] = row
		var said: PackedStringArray = PackedStringArray()
		for line3: PackedByteArray in grid:
			var text: String = ""
			for value: int in line3:
				text += "~" if value == 0 else str(value - 1)
			said.append(text)
		if not Thickness.thin_cells(said).is_empty():
			grid = before
	var out: PackedStringArray = PackedStringArray()
	for line4: PackedByteArray in grid:
		var text2: String = ""
		for value2: int in line4:
			text2 += "~" if value2 == 0 else str(value2 - 1)
		out.append(text2)
	var flat: String = ""
	for x3: int in range(width):
		flat += "0"
	for row2: int in range(Walls.STOREY_TILES * 4):
		out.append(flat)
	return out


func _framed(levels: Array[int], wide: int, tall: int) -> PackedStringArray:
	var top: int = 0
	for level: int in levels:
		top = maxi(top, level)
	var rows: PackedStringArray = PackedStringArray()
	var flat: String = ""
	for x: int in range(wide * 3 + 8):
		flat += "0"
	for y: int in range(4):
		rows.append(flat)
	for y2: int in range(tall * 3):
		var line: String = "0000"
		for x2: int in range(wide * 3):
			line += str(levels[(y2 / 3) * wide + (x2 / 3)])
		rows.append(line + "0000")
	for y3: int in range(4 + Walls.STOREY_TILES * (top + 1)):
		rows.append(flat)
	return rows


## LE PRIX DU TROISIEME ETAT DE FLANC.
##
## Aujourd'hui un flanc a DEUX etats -- ma roche s'arrete, ou elle continue -- donc 4 pans x 5
## rangees = 20 roles, et la famille est FERMEE par construction. L'arete interne demande de
## savoir QUI EST DEVANT, donc un troisieme etat : `arret`, `muet`, `devant`. Plafond 9 x 5 = 45.
##
## ⚠ ET « DERRIERE » N'EST PAS UN QUATRIEME ETAT : si mon voisin est devant, c'est LUI qui
## trace, et moi je ne fais rien -- donc je dessine comme `muet`. C'est ce qui garde le compte
## a neuf pans et non seize, et c'est deja la lecon de la 9.0.0 : « en donnant l'angle au seul
## bloc qui avance, le cote qui le porte dit lequel est devant ».
var _pans2: Dictionary = {}
var _pans3: Dictionary = {}
var _pans3_haut: Dictionary = {}


func _flank(cell: Vector2i, side: int, roles: Dictionary, lips: Dictionary,
		by_storey: bool) -> int:
	var probe: Vector2i = cell + STEPS[side]
	if not roles.has(probe):
		return 0
	var mine: Vector2i = _lip_of(cell, roles, lips)
	var theirs: Vector2i = _lip_of(probe, roles, lips)
	if mine == theirs:
		return 1
	# LA LEVRE LA PLUS AU SUD AVANCE VERS LE REGARD : son bloc saille, donc il porte l'angle.
	if mine.x > theirs.x:
		return 2
	if mine.x < theirs.x:
		return 1
	# Meme rangee : aucune ne saille. On mesure les deux conventions.
	if by_storey and mine.y > theirs.y:
		return 2
	return 1


func _pans(world: PackedStringArray, roles: Dictionary, lips: Dictionary) -> void:
	for cell: Vector2i in roles.keys():
		var row: int = (roles[cell] as Vector2i).y
		var west2: int = mini(1, _flank(cell, 3, roles, lips, false))
		var east2: int = mini(1, _flank(cell, 1, roles, lips, false))
		_pans2["%d,%d,%d" % [west2, east2, row]] = true
		_pans3["%d,%d,%d" % [_flank(cell, 3, roles, lips, false),
				_flank(cell, 1, roles, lips, false), row]] = true
		_pans3_haut["%d,%d,%d" % [_flank(cell, 3, roles, lips, true),
				_flank(cell, 1, roles, lips, true), row]] = true


func _report() -> void:
	print("\n--- LA COURBE : quand le recensement sature ---")
	for line: String in _curve:
		print(line)
	print("\n--- LA TABLE : %d espece(s) de frontiere ---" % _kinds.size())
	var orphans: int = 0
	var doubled: int = 0
	_order.sort()
	for kind: String in _order:
		var box: Dictionary = _kinds[kind]
		# ⚠ UNE ARETE INTERIEURE VEUT ZERO, UNE FRONTIERE VEUT UN. Juger les deux a la meme
		# aune ferait passer la continuite de la matiere pour un defaut -- 34 fausses muettes
		# au premier releve.
		var wanted: int = 0 if kind.begins_with("INTERIEUR") else 1
		var right: int = int(box["zero"]) if wanted == 0 else int(box["un"])
		var wrong: int = int(box["vus"]) - right
		var verdict: String = "ok"
		if wrong > 0:
			verdict = "%d HORS DE COMPTE (veut %d)" % [wrong, wanted]
			if wanted == 1 and int(box["zero"]) > 0:
				orphans += 1
			else:
				doubled += 1
		print("  %-42s %7d vus   0:%-6d 1:%-7d 2:%-6d  %s"
				% [kind, int(box["vus"]), int(box["zero"]), int(box["un"]),
				int(box["deux"]), verdict])
		if verdict != "ok":
			print("      %s" % ", ".join(PackedStringArray(box["ou"] as Array)))
	print("
--- LE PRIX DU TROISIEME ETAT DE FLANC ---")
	print("  deux etats (aujourd'hui)          : %d role(s) rencontre(s)" % _pans2.size())
	print("  trois etats, egalite -> muet      : %d role(s)" % _pans3.size())
	print("  trois etats, egalite -> le plus haut : %d role(s)" % _pans3_haut.size())
	print("
  %d espece(s) de FRONTIERE laissee muette, %d espece(s) autrement fautives"
			% [orphans, doubled])
