extends SceneTree

## LE BANC DE L'ECHELLE — voir `PLAN.md`.
##
## Il prend un couple **(L, F)** : L la complexite du MONDE, F la liberte du DESSIN. Il batit
## le monde de ce niveau, le peint a cette liberte, l'assemble, puis **regarde les pixels** et
## rend les cinq invariants.
##
##     godot --headless --path . --script res://proof/ladder.gd -- L0 F0
##     godot --headless --path . --script res://proof/ladder.gd            (tout l'acquis)
##
## ⚠ IL NE REDERIVE JAMAIS LE CALCUL QU'IL CONTROLE. C'est la faute la plus chere du projet :
## `_check_wall_seams` recalculait ses enchainements avec la formule meme qu'il verifiait --
## la meme formule, donc la meme erreur, donc rien de verifie -- et la suite etait verte
## pendant que le dessin cassait aux deux tiers de ses jonctions. Ici on rend l'image et on
## compte des pixels ; un trou est un trou, quelle que soit la regle qui a cru le boucher.
##
## ⚠ ET IL REJOUE TOUT L'ACQUIS. Sans argument, il parcourt chaque couple deja gagne. Un
## couple acquis qui rougit arrete tout : c'est ca, « rien ne regresse ».

const HeightMask := preload("res://core/height_mask.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Coverage := preload("res://core/coverage.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")

const RES: int = 16
const GRASS: Color = Color("#6f8a4a")
const OUTLINE: Color = Color("#1d2414")

## Les couples deja gagnes, dans l'ordre. On les rejoue tous a chaque execution.
const ACQUIS: Array[String] = ["L0/F0"]

const CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var couples: Array[String] = []
	if args.size() >= 2:
		couples.append("%s/%s" % [args[0].to_upper(), args[1].to_upper()])
	elif args.size() == 1:
		couples.append(args[0].to_upper())
	else:
		couples.assign(ACQUIS)
	var failed: int = 0
	for couple: String in couples:
		if not _run(couple):
			failed += 1
	print("")
	print("VERDICT : %s" % ("l echelle tient." if failed == 0
			else "%d couple(s) en echec." % failed))
	quit(1 if failed > 0 else 0)


func _run(couple: String) -> bool:
	var parts: PackedStringArray = couple.split("/")
	if parts.size() != 2:
		push_error("ladder: couple illisible '%s' (attendu L0/F0)." % couple)
		return false
	var level: int = int(parts[0].substr(1))
	var freedom: int = int(parts[1].substr(1))
	print("=== %s ===" % couple)

	var mask: PackedStringArray = _world(level)
	if mask.is_empty():
		push_error("ladder: niveau L%d pas encore batissable." % level)
		return false
	# ⚠ `index_at` PREND UN MASQUE BINAIRE, `index_map` PREND UN RELIEF. Le second calcule les
	# robes visibles au passage -- c'est L2, pas L0 -- et lu sur un masque il rend une case par
	# case du cadre, vide comprise : premier essai, 3 339 cases de « matiere » sur un monde qui
	# en compte 1 323, et 9 silhouettes exercees sur 27. Un banc qui se trompe de fonction
	# mesure un autre monde que celui qu'il annonce.
	var indices: Dictionary = {}
	for y: int in range(HeightMask.height(mask)):
		for x: int in range(HeightMask.width(mask)):
			var tile: int = Coverage.index_at(mask, x, y)
			if tile != Coverage.NO_INDEX:
				indices[Vector2i(x, y)] = tile
	var vocabulary: Dictionary = {}
	for cell: Vector2i in indices.keys():
		vocabulary[int(indices[cell])] = true
	print("  monde : %d x %d, %d cases de matiere, %d silhouettes distinctes"
			% [HeightMask.width(mask), HeightMask.height(mask), indices.size(),
			vocabulary.size()])
	# ⚠ ON DIT CE QUE LE MONDE COUVRE, ET ON L'EXIGE. Un banc qui tournerait sur un monde
	# n'exercant que trois silhouettes serait vert sans rien prouver -- exactement la faute
	# deja payee : « une battue qui ne rencontre aucun des douze roles ne prouve rien ».
	var expected: int = Thickness.SURFACE_INDICES.size()
	var complete: bool = vocabulary.size() == expected
	print("  vocabulaire exerce : %d / %d %s" % [vocabulary.size(), expected,
			"" if complete else "  ⚠ INCOMPLET"])

	var tiles: Dictionary = _paint(vocabulary, freedom)
	var image: Image = _assemble(mask, indices, tiles)
	var report: Dictionary = _measure(image, mask, indices, tiles, freedom)
	var ok: bool = complete
	for key: String in ["I1", "I2", "I3", "I4", "I5"]:
		var line: Dictionary = report[key]
		var green: bool = bool(line["ok"])
		ok = ok and green
		print("  %s %-11s %-4s %s" % [key, str(line["nom"]), "ok" if green else "ECHEC",
				str(line["dit"])])
	return ok


# ------------------------------------------------------------------ LE MONDE

## L0 : UN SEUL MASQUE BINAIRE. Pas d'etage empile, pas de falaise, pas de pose arriere.
## Chaque frontiere n'a qu'UN revendiquant : la seule tuile qui la touche.
##
## Le monde est la SILHOUETTE D'ETAGE de la planche de preuve : un ilot par silhouette, batis
## pour ca. Lue a l'etage 1, la planche rend donc un masque binaire qui exerce les 27, et rien
## d'autre. Mesure : 1 347 cases, 42 massifs, 27 / 27.
##
## ⚠ ET J'AI ESSAYE DE LES BATIR ICI, C'ETAIT FAUX. L'ilot « etire » -- chaque case prend
## l'etat de la case de fenetre la plus proche vers le centre -- ne suffit PAS : la colonne du
## milieu d'une fenetre ne s'etire pas, elle reste large d'une case. L'index 5 (N+E) y devient
## une equerre d'un pixel de large, donc FINE, et l'ilot fabrique alors des silhouettes hors
## vocabulaire. Mesure : 33 silhouettes exercees pour 27 annoncees.
##
## La construction du depot, elle, CHERCHE une position et la juge -- epaisse ? le centre
## porte-t-il la tuile annoncee ? reste-t-elle peignable ? C'est la lecon deja ecrite au
## dossier : « le relief se decrit accident par accident, jamais en ASCII ». Elle valait aussi
## pour moi.
func _world(level: int) -> PackedStringArray:
	if level != 0:
		return PackedStringArray()
	return HeightMask.silhouette(ProofScene.relief(Families.BY_CELL), 1)


# ------------------------------------------------------------------ LE DESSIN

## F0 : LE TRAIT AU RAS DU BORD DE LA CASE. Aucune liberte.
##
## ⚠ C'EST LE TEMOIN, ET C'EST SA SEULE RAISON D'ETRE. A F0 le dessin ne peut rien inventer :
## la tuile remplit sa case et pose son trait sur la colonne ou la rangee du bord, la ou son
## cardinal est vide. Si un invariant rougit ici, le defaut est dans le MODELE -- pas dans la
## main. C'est le seul instrument qui separe les deux, et il nous a manque toute la semaine.
func _paint(vocabulary: Dictionary, freedom: int) -> Dictionary:
	var tiles: Dictionary = {}
	for key: Variant in vocabulary.keys():
		var index: int = int(key)
		var tile: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
		tile.fill(GRASS)
		if freedom == 0:
			for side: int in range(4):
				if (index & CARDINALS[side]) != 0:
					continue
				_edge(tile, side, 0)
		tiles[index] = tile
	return tiles


## Pose le trait sur la ligne de bord d'un cote, a `depth` pixels du ras.
func _edge(tile: Image, side: int, depth: int) -> void:
	for i: int in range(RES):
		match side:
			0: tile.set_pixel(i, depth, OUTLINE)
			1: tile.set_pixel(RES - 1 - depth, i, OUTLINE)
			2: tile.set_pixel(i, RES - 1 - depth, OUTLINE)
			_: tile.set_pixel(depth, i, OUTLINE)


## L0 : une tuile par case, et rien d'autre. L'empilement, les falaises et les poses arriere
## sont les niveaux suivants ; les poser ici serait mesurer autre chose que L0.
func _assemble(mask: PackedStringArray, indices: Dictionary, tiles: Dictionary) -> Image:
	var width: int = HeightMask.width(mask)
	var height: int = HeightMask.height(mask)
	var canvas: Image = Image.create_empty(width * RES, height * RES, false,
			Image.FORMAT_RGBA8)
	for cell: Vector2i in indices.keys():
		var tile: Image = tiles[int(indices[cell])]
		canvas.blit_rect(tile, Rect2i(0, 0, RES, RES), cell * RES)
	return canvas


# ------------------------------------------------------------------ LES CINQ INVARIANTS

func _measure(image: Image, mask: PackedStringArray, indices: Dictionary, tiles: Dictionary,
		freedom: int) -> Dictionary:
	var width: int = image.get_width()
	var height: int = image.get_height()

	# I1 FERMETURE. Le contour d'un massif est d'un seul morceau -- et un massif troue en a
	# un de plus, par trou. On compare donc les morceaux de trait au compte ATTENDU.
	var strokes: int = _components(image, true)
	var massifs: int = _components(image, false)
	var holes: int = _holes(image, width, height)
	var i1: bool = strokes == massifs + holes

	# I2 EPAISSEUR. Un trait d'un pixel ne peut pas remplir un pave 2x2. Des qu'il y en a un,
	# deux traits se sont colles ou un trait a double.
	# ⚠ C'EST LUI QUI ATTRAPE LES LENTILLES, ET PAS I1 : deux traits qui se touchent forment
	# UN SEUL morceau, donc la fermeture passe au vert pendant que l'oeil voit un renflement.
	var thick: int = 0
	var thick_where: Array[String] = []
	for y: int in range(height - 1):
		for x: int in range(width - 1):
			if not (_is_stroke(image, x, y) and _is_stroke(image, x + 1, y)
					and _is_stroke(image, x, y + 1) and _is_stroke(image, x + 1, y + 1)):
				continue
			thick += 1
			if thick_where.size() < 3:
				thick_where.append("%d,%d" % [x / RES, y / RES])

	# I3 UNICITE. Chaque frontiere du monde est tracee par EXACTEMENT une tuile.
	var claims: Dictionary = _claims(image, mask, indices)
	var i3: bool = int(claims["doubles"]) == 0 and int(claims["muettes"]) == 0 \
			and int(claims["parasites"]) == 0

	# I4 MATIERE. Aucun pixel de fond la ou le monde a de la matiere.
	var pierced: int = 0
	for cell: Vector2i in indices.keys():
		for y: int in range(RES):
			for x: int in range(RES):
				if image.get_pixel(cell.x * RES + x, cell.y * RES + y).a < 0.5:
					pierced += 1

	# I5 LIBERTE. Le peintre fait-il vraiment ce que la liberte promet ?
	# ⚠ SANS LUI, TOUT CONVERGE EN FIGEANT LE DESSIN : F0 serait vert a tous les niveaux et ne
	# prouverait rien. A F0 la promesse est justement NULLE -- un seul profil de bord possible,
	# et en mesurer deux voudrait dire que le banc ment sur ce qu'il peint.
	# ⚠ ET ON NE PROFILE QUE LES BORDS REELLEMENT TRACES. Un cote plein n'a pas de trait :
	# lui demander son profil rend « rien », et « rien » differe d'une tuile a l'autre selon
	# le coin que son voisin y a laisse. Sept profils au premier essai, tous fantomes.
	var profiles: Dictionary = {}
	for key: Variant in tiles.keys():
		for side: int in range(4):
			if (int(key) & CARDINALS[side]) != 0:
				continue
			profiles[_profile(tiles[key] as Image, side)] = true
	var promised: int = 1 if freedom == 0 else 2
	var i5: bool = profiles.size() == 1 if freedom == 0 else profiles.size() >= promised

	return {
		"I1": {"nom": "fermeture", "ok": i1,
				"dit": "%d morceaux de trait pour %d massifs + %d trous"
				% [strokes, massifs, holes]},
		"I2": {"nom": "epaisseur", "ok": thick == 0,
				"dit": "%d pave(s) 2x2 de trait %s" % [thick, str(thick_where)]},
		"I3": {"nom": "unicite", "ok": i3,
				"dit": "%d frontieres, %d doubles, %d muettes, %d parasites  %s"
				% [int(claims["frontieres"]), int(claims["doubles"]),
				int(claims["muettes"]), int(claims["parasites"]), str(claims["ou"])]},
		"I4": {"nom": "matiere", "ok": pierced == 0,
				"dit": "%d pixel(s) de fond sur de la matiere" % pierced},
		"I5": {"nom": "liberte", "ok": i5,
				"dit": "%d profil(s) de bord distinct(s), %d promis" % [profiles.size(),
				promised]},
	}


## QUI TRACE CHAQUE FRONTIERE ? Le coeur du banc, et le fil de tout le plan.
##
## Une frontiere est une arete entre deux cases dont l'une porte de la matiere et l'autre non.
## On compte, de chaque cote, si la tuile pose du trait sur la ligne qui borde cette arete :
##   deux -> le trait est DOUBLE (les lentilles, les demi-ovales, les ovales) ;
##   zero -> la frontiere est MUETTE, le monde s'arrete sans que rien ne le dise.
## Et une arete INTERIEURE -- de la matiere des deux cotes -- ne doit porter aucun trait :
## ce serait un quadrillage, un trait la ou le monde n'a pas de bord.
##
## ⚠ LA DEFINITION S'ELARGIRA A F1. Au ras du bord, « tracer » se lit sur la ligne du bord ;
## des que le trait a le droit de rentrer, il faudra le chercher plus loin dans la tuile. La
## regle, elle, ne bouge pas : exactement un revendiquant par frontiere.
func _claims(image: Image, mask: PackedStringArray, indices: Dictionary) -> Dictionary:
	var width: int = HeightMask.width(mask)
	var height: int = HeightMask.height(mask)
	var frontiers: int = 0
	var doubles: int = 0
	var mutes: int = 0
	var parasites: int = 0
	var witness: Array[String] = []
	for cell: Vector2i in indices.keys():
		for side: int in range(4):
			var probe: Vector2i = cell + STEPS[side]
			var inside: bool = probe.x >= 0 and probe.y >= 0 					and probe.x < width and probe.y < height
			var mine: bool = _draws(image, cell, side)
			var theirs: bool = inside and _draws(image, probe, (side + 2) % 4)
			if indices.has(probe):
				# Une arete INTERIEURE ne se voit qu'une fois : on la regarde depuis l'est et
				# le sud, jamais depuis les quatre cotes.
				if side != 1 and side != 2:
					continue
				if mine or theirs:
					parasites += 1
					if witness.size() < 3:
						witness.append("%d,%d" % [cell.x, cell.y])
				continue
			frontiers += 1
			var claimants: int = (1 if mine else 0) + (1 if theirs else 0)
			if claimants == 0:
				mutes += 1
				if witness.size() < 3:
					witness.append("%d,%d muette" % [cell.x, cell.y])
			elif claimants > 1:
				doubles += 1
				if witness.size() < 3:
					witness.append("%d,%d double" % [cell.x, cell.y])
	return {"frontieres": frontiers, "doubles": doubles, "muettes": mutes,
			"parasites": parasites, "ou": witness}


## Cette case pose-t-elle du trait sur la ligne qui borde ce cote ?
## ⚠ ET LE PIXEL DE COIN NE DECIDE DE RIEN. Il appartient a DEUX aretes a la fois : le trait
## d'un flanc ouest y pose son premier pixel, qui tombe aussi sur la ligne du bord nord. Sans
## l'exclure, chaque case semblait revendiquer des cotes qu'elle ne trace pas -- 516 faux
## parasites au premier essai, sur un monde parfaitement juste.
func _draws(image: Image, cell: Vector2i, side: int) -> bool:
	for i: int in range(1, RES - 1):
		var at: Vector2i = Vector2i.ZERO
		match side:
			0: at = Vector2i(cell.x * RES + i, cell.y * RES)
			1: at = Vector2i(cell.x * RES + RES - 1, cell.y * RES + i)
			2: at = Vector2i(cell.x * RES + i, cell.y * RES + RES - 1)
			_: at = Vector2i(cell.x * RES, cell.y * RES + i)
		if _is_stroke(image, at.x, at.y):
			return true
	return false


## Le profil d'un bord : la profondeur du trait, colonne par colonne. C'est la mesure de la
## liberte -- a F0 il n'y en a qu'un seul possible, a F1 sa hauteur varie, a F2 sa forme.
func _profile(tile: Image, side: int) -> String:
	var out: PackedStringArray = PackedStringArray()
	for i: int in range(1, RES - 1):
		var depth: int = -1
		for d: int in range(RES):
			var at: Vector2i = Vector2i.ZERO
			match side:
				0: at = Vector2i(i, d)
				1: at = Vector2i(RES - 1 - d, i)
				2: at = Vector2i(i, RES - 1 - d)
				_: at = Vector2i(d, i)
			if tile.get_pixel(at.x, at.y).is_equal_approx(OUTLINE):
				depth = d
				break
		out.append(str(depth))
	return ",".join(out)


func _is_stroke(image: Image, x: int, y: int) -> bool:
	return image.get_pixel(x, y).is_equal_approx(OUTLINE)


func _components(image: Image, stroke: bool) -> int:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var seen: Dictionary = {}
	var count: int = 0
	for y: int in range(height):
		for x: int in range(width):
			if not _kind(image, x, y, stroke) or seen.has(y * width + x):
				continue
			count += 1
			var stack: Array[int] = [y * width + x]
			seen[y * width + x] = true
			while not stack.is_empty():
				var here: int = stack.pop_back()
				var hx: int = here % width
				var hy: int = here / width
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var nx: int = hx + dx
						var ny: int = hy + dy
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							continue
						if seen.has(ny * width + nx) or not _kind(image, nx, ny, stroke):
							continue
						seen[ny * width + nx] = true
						stack.append(ny * width + nx)
	return count


## Les trous : le fond qui ne touche pas le bord du cadre. Un massif troue porte un contour
## de plus par trou -- sans quoi le compte attendu de I1 serait faux.
func _holes(image: Image, width: int, height: int) -> int:
	var seen: Dictionary = {}
	var count: int = 0
	for y: int in range(height):
		for x: int in range(width):
			if image.get_pixel(x, y).a >= 0.5 or seen.has(y * width + x):
				continue
			var touches: bool = false
			var stack: Array[int] = [y * width + x]
			seen[y * width + x] = true
			while not stack.is_empty():
				var here: int = stack.pop_back()
				var hx: int = here % width
				var hy: int = here / width
				if hx == 0 or hy == 0 or hx == width - 1 or hy == height - 1:
					touches = true
				for step: Vector2i in STEPS:
					var nx: int = hx + step.x
					var ny: int = hy + step.y
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					if seen.has(ny * width + nx) or image.get_pixel(nx, ny).a >= 0.5:
						continue
					seen[ny * width + nx] = true
					stack.append(ny * width + nx)
			if not touches:
				count += 1
	return count


func _kind(image: Image, x: int, y: int, stroke: bool) -> bool:
	var c: Color = image.get_pixel(x, y)
	return c.is_equal_approx(OUTLINE) if stroke else c.a >= 0.5
