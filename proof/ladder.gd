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
const MaskIO := preload("res://core/mask_io.gd")

## La planche relue une fois, gardee pour le fond de contexte des images.
static var _board: PackedStringArray = PackedStringArray()

const RES: int = 16
## La tuile pleine : huit voisins, aucun bord. C'est elle qu'on pose sous un sommet.
const SOLID: int = 255
## ⚠ LES COULEURS SONT CELLES D'UNE PREUVE, PAS D'UN PAYSAGE. Le premier jeu prenait la
## teinte du logiciel -- vert moyen, trait vert tres sombre -- et a l'ecran le trait se
## confondait avec la matiere : on ne voyait plus la silhouette, c'est-a-dire la seule chose
## que ce banc existe pour montrer. Matiere claire, trait noir, fond franchement autre.
const GRASS: Color = Color("#c3d98f")
const OUTLINE: Color = Color("#0d0f12")

## Uniquement pour REGARDER : le fond hors monde, et l'etage 0 de la planche, pose derriere
## en sourdine pour qu'on voie sur quoi les specimens reposent. Rien de tout cela n'entre dans
## la mesure -- celle-ci se fait sur l'image a fond transparent, avant compositation.
const BACKDROP: Color = Color("#23262b")
const CONTEXT: Color = Color("#3f4a38")

## Les couples deja gagnes, dans l'ordre. On les rejoue tous a chaque execution.
const ACQUIS: Array[String] = ["L0/F0", "L0/F1", "L0/F2", "L1/F0", "L1/F1", "L1/F2"]

const CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
## La diagonale de chaque coin, dans le meme ordre : NO, NE, SE, SO.
const DIAGONALS: Array[int] = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW]
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


## Ecrire l'image, pour la regarder plutot que la croire.
##
##     ... -- L0 F1 sortie.png                 la planche entiere
##     ... -- L0 F1 sortie.png 0 6 34 22 24    un gros plan, en CASES, puis le zoom
##
## ⚠ ET LE ZOOM EST AU PLUS PROCHE. Un lissage inventerait des coutures que le dessin n'a pas
## -- c'est la lecon deja ecrite pour l'apercu en jeu et pour les voisines.
func _write(image: Image, couple: String) -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		return
	var out: String = args[2]
	# ⚠ ON COMPOSITE POUR REGARDER, JAMAIS POUR MESURER. Le banc mesure sur l'image a fond
	# transparent ; ce qui suit ne sert qu'a l'oeil -- un fond franc, et l'etage 0 de la
	# planche pose EN SOURDINE derriere, parce qu'un specimen qui deborde sur la plaine ne se
	# juge pas sans voir la plaine.
	var shown: Image = Image.create_empty(image.get_width(), image.get_height(), false,
			Image.FORMAT_RGBA8)
	shown.fill(BACKDROP)
	if not _board.is_empty():
		for y: int in range(HeightMask.height(_board)):
			for x: int in range(HeightMask.width(_board)):
				if HeightMask.level_at(_board, x, y) < 0:
					continue
				shown.fill_rect(Rect2i(x * RES, y * RES, RES, RES), CONTEXT)
	shown.blend_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()), Vector2i.ZERO)
	if args.size() >= 7:
		var cw: int = int(args[5])
		var ch: int = int(args[6])
		var tile: int = int(args[7]) if args.size() > 7 else 20
		var crop: Image = Image.create_empty(cw * RES, ch * RES, false, shown.get_format())
		crop.blit_rect(shown, Rect2i(int(args[3]) * RES, int(args[4]) * RES, cw * RES,
				ch * RES), Vector2i.ZERO)
		crop.resize(cw * tile, ch * tile, Image.INTERPOLATE_NEAREST)
		shown = crop
	shown.save_png(out)
	print("  ecrit : %s  (%d x %d px)  [%s]" % [out, shown.get_width(), shown.get_height(),
			couple])


func _run(couple: String) -> bool:
	var parts: PackedStringArray = couple.split("/")
	if parts.size() != 2:
		push_error("ladder: couple illisible '%s' (attendu L0/F0)." % couple)
		return false
	var level: int = int(parts[0].substr(1))
	var freedom: int = int(parts[1].substr(1))
	print("=== %s ===" % couple)

	var world: PackedStringArray = _world(level)
	if world.is_empty():
		push_error("ladder: niveau L%d pas encore batissable." % level)
		return false
	# ⚠ `index_at` PREND UN MASQUE BINAIRE, `index_map` PREND UN RELIEF. Le second calcule les
	# robes visibles au passage -- c'est L2, pas L0 -- et lu sur un masque il rend une case par
	# case du cadre, vide comprise : premier essai, 3 339 cases de « matiere » sur un monde qui
	# en compte 1 323, et 9 silhouettes exercees sur 27. Un banc qui se trompe de fonction
	# mesure un autre monde que celui qu'il annonce.
	# Une silhouette par etage, du bas vers le haut. C'est tout ce que le dessin connait.
	var top: int = 0
	for y: int in range(HeightMask.height(world)):
		for x: int in range(HeightMask.width(world)):
			top = maxi(top, HeightMask.level_at(world, x, y))
	var storeys: Array[Dictionary] = []
	for storey: int in range(top + 1):
		var mask: PackedStringArray = HeightMask.silhouette(world, storey)
		var map: Dictionary = {}
		for y: int in range(HeightMask.height(mask)):
			for x: int in range(HeightMask.width(mask)):
				if Coverage.index_at(mask, x, y) == Coverage.NO_INDEX:
					continue
				# L'INDEX CANONIQUE SUFFIT, ET C'EST UN THEOREME. J'ai cru un moment qu'il
				# fallait le voisinage BRUT : la canonicalisation « jette une diagonale »,
				# donc elle jetterait le coin rentrant. Faux, et c'est l'inverse -- elle
				# CONSERVE un bit de coin exactement quand ses deux cardinaux sont pleins, et
				# c'est precisement la condition du coin rentrant. Un bit de diagonale ne sert
				# au dessin dans aucun autre cas. Le brut n'ajoute donc rien.
				#
				# Mesure : 51 voisinages bruts realisables en epais, 27 silhouettes -- et les
				# cinq invariants restent verts a l'identique avec 27 tuiles au lieu de 45.
				# La liberte laterale ne coute AUCUNE tuile.
				map[Vector2i(x, y)] = Coverage.index_at(mask, x, y)
		storeys.append(map)

	# La carte VISIBLE : chaque case porte la tuile de SON etage, celle qu'on voit de dessus.
	var indices: Dictionary = {}
	for y: int in range(HeightMask.height(world)):
		for x: int in range(HeightMask.width(world)):
			var here: int = HeightMask.level_at(world, x, y)
			if here < 0:
				continue
			indices[Vector2i(x, y)] = int((storeys[here] as Dictionary)[Vector2i(x, y)])
	var vocabulary: Dictionary = {}
	for storey: int in range(storeys.size()):
		for cell: Vector2i in (storeys[storey] as Dictionary).keys():
			vocabulary[int((storeys[storey] as Dictionary)[cell])] = true

	print("  monde : %d x %d, %d etage(s), %d cases visibles, %d tuiles a peindre"
			% [HeightMask.width(world), HeightMask.height(world), top + 1, indices.size(),
			vocabulary.size()])
	var canonical: Dictionary = {}
	for cell: Vector2i in indices.keys():
		canonical[BlobIndex.canonicalize(int(indices[cell]))] = true
	var expected: int = Thickness.SURFACE_INDICES.size()
	var complete: bool = canonical.size() == expected
	print("  vocabulaire exerce : %d / %d silhouettes%s   %d tuiles a peindre"
			% [canonical.size(), expected, "" if complete else "  ⚠ INCOMPLET",
			vocabulary.size()])

	vocabulary[SOLID] = true
	var tiles: Dictionary = _paint(vocabulary, freedom)
	var image: Image = _assemble(world, storeys, tiles)
	_write(image, couple)
	var report: Dictionary = _measure(image, world, indices, tiles, freedom)
	var ok: bool = complete
	for key: String in ["I1", "I2", "I3", "I4", "I5"]:
		var line: Dictionary = report[key]
		var green: bool = bool(line["ok"])
		ok = ok and green
		print("  %s %-11s %-4s %s" % [key, str(line["nom"]), "ok" if green else "ECHEC",
				str(line["dit"])])
	return ok


# ------------------------------------------------------------------ LE MONDE

## LE MONDE DE CHAQUE NIVEAU, toujours rendu comme un RELIEF -- une hauteur par case, le vide
## a -1. L0 n'en a qu'un etage, L1 en a plusieurs ; le reste du banc ne voit que des
## silhouettes d'etage, et ne change pas.
##
## L0 : UN SEUL MASQUE BINAIRE. Pas d'etage empile, pas de falaise, pas de pose arriere --
## chaque frontiere n'a qu'UN revendiquant. Le masque est la silhouette d'etage 1 de la planche
## de preuve : un ilot par silhouette, batis pour ca, donc 27 / 27 exercees.
##
## Et j'ai essaye de les batir ici, c'etait faux. L'ilot « etire » -- chaque case prend l'etat
## de la case de fenetre la plus proche vers le centre -- ne suffit PAS : la colonne du milieu
## d'une fenetre ne s'etire pas, elle reste large d'une case. L'index 5 (N+E) y devient une
## equerre d'un pixel de large, donc FINE, et l'ilot fabrique alors des silhouettes hors
## vocabulaire : 33 exercees pour 27 annoncees. La construction du depot, elle, CHERCHE une
## position et la juge.
##
## L1 : LA PLANCHE ENTIERE, avec ses etages. Une case appartient a toutes les silhouettes sous
## son sommet, et chacune y pose sa tuile. C'est la que plusieurs tuiles peuvent revendiquer
## une meme frontiere -- ce que L0 ne pouvait pas produire.
func _world(level: int) -> PackedStringArray:
	_board = ProofScene.relief(Families.BY_CELL)
	if level == 1:
		return _board
	if level != 0:
		return PackedStringArray()
	var flat: PackedStringArray = HeightMask.silhouette(_board, 1)
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(flat.size()):
		var line: String = ""
		for x: int in range(flat[y].length()):
			line += "0" if flat[y][x] == MaskIO.FILLED_CHAR else "~"
		out.append(line)
	return out


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
		# La matiere est ce que les quatre profils laissent. A F0 ils valent zero et elle
		# remplit la case ; a F1 ils sont constants ; a F2 ils serpentent.
		var solid: Array[PackedByteArray] = []
		for y: int in range(RES):
			var line: PackedByteArray = PackedByteArray()
			line.resize(RES)
			for x: int in range(RES):
				var inside: bool = true
				if (index & CARDINALS[0]) == 0 and y < _depth(index, 0, x, freedom):
					inside = false
				if (index & CARDINALS[1]) == 0 and x > RES - 1 - _depth(index, 1, y, freedom):
					inside = false
				if (index & CARDINALS[2]) == 0 and y > RES - 1 - _depth(index, 2, x, freedom):
					inside = false
				if (index & CARDINALS[3]) == 0 and x < _depth(index, 3, y, freedom):
					inside = false
				line[x] = 1 if inside else 0
			solid.append(line)
		# ⚠ ET LA MATIERE N'A PAS D'AIGUILLE. La ou deux courbes libres se rencontrent -- un
		# coin saillant dont les deux cotes serpentent -- il reste parfois une pointe d'un
		# seul pixel, accrochee par un coin. Son trait n'a alors qu'UN voisin : c'est une
		# extremite, donc une interruption. Mesure : deux, sur toute la planche, dans la
		# tuile 120.
		#
		# C'est la regle d'epaisseur d'un cran plus bas, et pour la meme raison : une aiguille
		# d'un pixel n'est pas une silhouette. On la retire, et on recommence jusqu'a ce qu'il
		# n'en reste plus -- retirer une pointe peut en decouvrir une autre. Rien la-dedans ne
		# demande de connaitre la voisine : la tuile se relit elle-meme.
		var needled: bool = true
		while needled:
			needled = false
			for y: int in range(RES):
				for x: int in range(RES):
					if solid[y][x] == 0:
						continue
					var kin: int = 0
					for step: Vector2i in STEPS:
						var near: Vector2i = Vector2i(x, y) + step
						if near.x < 0 or near.y < 0 or near.x >= RES or near.y >= RES:
							# Au-dela d'un cardinal plein la matiere continue chez la voisine.
							if (index & CARDINALS[STEPS.find(step)]) != 0:
								kin += 1
							continue
						if solid[near.y][near.x] != 0:
							kin += 1
					if kin >= 2:
						continue
					var line3: PackedByteArray = solid[y]
					line3[x] = 0
					solid[y] = line3
					needled = true

		# ⚠ LE TRAIT SE DEDUIT DE LA MATIERE, IL NE SE TRACE PAS A PART. Trace a part, il faut
		# le decouper a la main partout ou deux cotes se rencontrent -- et c'est exactement la
		# qu'il depassait, en ergot, a chaque coin saillant. Deduit, il epouse la matiere par
		# construction. Tout ce qu'il faut savoir en plus est LOCAL : au-dela d'un cardinal
		# plein il y a de la matiere, au-dela d'un cardinal vide il n'y a rien.
		for y: int in range(RES):
			for x: int in range(RES):
				if solid[y][x] == 0:
					continue
				var edge: bool = false
				for side: int in range(4):
					var probe: Vector2i = Vector2i(x, y) + STEPS[side]
					if probe.x < 0 or probe.y < 0 or probe.x >= RES or probe.y >= RES:
						if (index & CARDINALS[side]) == 0:
							edge = true
						continue
					if solid[probe.y][probe.x] == 0:
						edge = true
				tile.set_pixel(x, y, OUTLINE if edge else GRASS)
		if freedom > 0:
			_reentrant(tile, index, freedom)
		tiles[index] = tile
	return tiles


## LES COINS RENTRANTS : la marche que personne d'autre ne peut tracer.
##
## ⚠ ET C'EST LA SEULE CHOSE QUE F1 AJOUTE AU DESSIN. Quand le trait rentre, deux cases
## voisines dont les bords ne rentrent pas pareil laissent une MARCHE a leur frontiere. La
## marche est du cote de celle qui a de la matiere -- l'autre n'a que du fond a cet endroit,
## et on ne trace pas dans le vide. Cette case-la se reconnait a une signature, et une seule :
## ses DEUX cardinaux du coin sont pleins et sa DIAGONALE est vide.
##
## ⚠ C'EST EXACTEMENT LE BIT QUE LA CANONICALISATION JETTE. « Un coin diagonal isole ne change
## pas la silhouette de la tuile » -- vrai du remplissage, faux du trait : c'est la, et
## seulement la, que le bord fait une marche. F1 se paie donc en voisinages bruts.
##
## ⚠ ET UNE SEULE DES DEUX CASES TRACE. La voisine d'en face, elle, a son cardinal ouvert et
## n'a pas de matiere a cet endroit : si elle tracait aussi, les deux traits seraient colles
## de part et d'autre de la frontiere -- un pave 2x2, I2 rouge. Ils se rejoignent en diagonale,
## ce qui suffit a fermer.
func _reentrant(tile: Image, index: int, freedom: int) -> void:
	for corner: int in range(4):
		var a: int = corner                 # N, E, S, O
		var b: int = (corner + 3) % 4       # le cote precedent : NO, NE, SE, SO
		if (index & CARDINALS[a]) == 0 or (index & CARDINALS[b]) == 0:
			continue
		if (index & DIAGONALS[corner]) != 0:
			continue
		_stub(tile, a, b, _depth(index, b, 0, freedom))
		_stub(tile, b, a, _depth(index, a, 0, freedom))


## Un bout de trait le long du bord `along`, depuis le coin qu'il partage avec `from`.
func _stub(tile: Image, along: int, from: int, length: int) -> void:
	for i: int in range(length):
		var far: bool = from == 1 or from == 2
		var offset: int = RES - 1 - i if far else i
		match along:
			0: tile.set_pixel(offset, 0, OUTLINE)
			1: tile.set_pixel(RES - 1, offset, OUTLINE)
			2: tile.set_pixel(offset, RES - 1, OUTLINE)
			_: tile.set_pixel(0, offset, OUTLINE)


## LA PROFONDEUR DU TRAIT, le long d'un cote.
##
##   F0  zero partout : le trait est au ras du bord.
##   F1  une constante PAR COTE : le trait rentre, mais droit -- et commune, sinon il saute a
##       chaque changement d'index le long d'un meme bord (mesure : 168 morceaux pour 42
##       massifs, exactement quatre par massif).
##   F2  cette meme constante AUX DEUX BOUTS, libre entre les deux.
##
## ⚠ ET LA TRAVERSEE RESTE COMMUNE A F2 : C'EST LA SEULE CHOSE QUI NE SE NEGOCIE PAS. Deux
## tuiles qui se suivent le long d'un bord se retrouvent a leur frontiere ; si elles n'y
## arrivent pas a la meme profondeur, le trait se rompt. Entre ces deux points la ligne fait
## ce qu'elle veut -- c'est ca, la liberte de F2, et elle est entiere.
func _depth(index: int, side: int, along: int, freedom: int) -> int:
	if freedom == 0:
		return 0
	# ⚠ ET LA TRAVERSEE VAUT AU MOINS DEUX. L'ergot de coin rentrant se pose au RAS du bord --
	# il marque une marche sur un cote dont le cardinal est plein, il n'a nulle part ailleurs ou
	# aller. Si un bord traverse a la profondeur UN, les deux traits sont voisins d'un pixel et
	# forment un pave : deux terrasses collees, l'une par son ergot, l'autre par son bord.
	# Invisible a L0, ou les deux ne se rencontrent jamais dans la meme case ; flagrant des que
	# les etages s'empilent -- 5 paves a L1/F1, 12 a L1/F2.
	var crossing: int = 2 + absi((side + 1) * 19349663) % 3
	if freedom == 1:
		return crossing
	# ⚠ LA FORME D'UN BORD NE DEPEND QUE DE CE BORD-LA, jamais de la tuile qui le porte. Deux
	# silhouettes d'etages differents peuvent s'arreter au MEME endroit -- c'est la « pile »,
	# jusqu'a trois sur la planche -- et chacune y trace son bord. Si elles serpentent
	# differemment, le meme trait se dedouble : deux courbes qui se croisent et s'ecartent, et
	# la ou elles passent a un pixel l'une de l'autre, un pave. Mesure : 6 a L1/F2, tous dans
	# une seule case, invisibles a F0 et F1 ou les bords sont droits donc confondus.
	#
	# Tirees du seul cote, les deux courbes sont la MEME : elles se superposent au pixel pres,
	# et il ne reste qu'un trait. C'est la loi deja ecrite au dossier pour les falaises.
	#
	# ⚠ Et tiree, pas au hasard : deux executions doivent donner la meme image, sans quoi le
	# banc ne dit plus si un correctif a servi.
	var _unused: int = index
	var seed: int = absi((side + 1) * 19349663)
	var reach: float = float(1 + seed % 3)
	var skew: float = 0.7 + 0.6 * float(seed % 101) / 100.0
	var t: float = float(along) / float(RES - 1)
	return crossing + int(round(reach * sin(PI * pow(t, skew))))


## L'EMPILEMENT : une tuile par etage et par case, du bas vers le haut.
##
## C'est la regle du depot, pas une invention du banc : « on dessine du bas vers le haut,
## chaque couche recouvrant la precedente ».
##
## ⚠ ET « LE SOMMET TRACE, LES ENTERRES SE POSENT PLEINS » A ETE ESSAYE PUIS REFUTE. C'etait
## la reponse que le plan pronait pour L1, et elle se defend : une case appartient ENTIEREMENT
## a chaque silhouette qui la contient, donc le monde n'y a pas de bord et l'entaille n'est
## qu'une decoration du bord visible. Poser la tuile pleine sous le sommet efface bien les
## paves -- 6 a L1/F2, zero apres.
##
## Mais elle en ouvre 26 ailleurs : le bord d'un etage qui passe SOUS un plateau voisin cesse
## d'etre trace, et le contour de la terrasse s'arrete net au pied du plateau au lieu d'y
## rejoindre le sien. Ce que l'etage enterre dessine n'est donc pas une decoration : c'est ce
## qui RACCORDE deux terrasses de niveaux differents. Mesure : 26 extremites contre 6 paves.
##
## On garde donc l'empilement complet, et le defaut restant -- six pixels a une jonction en T
## entre les bords de deux etages -- attend son propre diagnostic.
static func _assemble(world: PackedStringArray, storeys: Array[Dictionary],
		tiles: Dictionary) -> Image:
	var canvas: Image = Image.create_empty(HeightMask.width(world) * RES,
			HeightMask.height(world) * RES, false, Image.FORMAT_RGBA8)
	for storey: int in range(storeys.size()):
		var map: Dictionary = storeys[storey]
		for cell: Vector2i in map.keys():
			var tile: Image = tiles[int(map[cell])]
			canvas.blend_rect(tile, Rect2i(0, 0, RES, RES), cell * RES)
	return canvas


# ------------------------------------------------------------------ LES CINQ INVARIANTS

func _measure(image: Image, world: PackedStringArray, indices: Dictionary, tiles: Dictionary,
		freedom: int) -> Dictionary:
	var width: int = image.get_width()
	var height: int = image.get_height()

	# I1 FERMETURE. Le contour d'un massif est d'un seul morceau -- et un massif troue en a
	# un de plus, par trou. On compare donc les morceaux de trait au compte ATTENDU.
	var strokes: int = _components(image, true)
	var massifs: int = _components(image, false)
	var holes: int = _holes(image, width, height)
	# ⚠ LE CRITERE EST ZERO EXTREMITE, ET LE COMPTE DE MORCEAUX N'EST QU'UN RENSEIGNEMENT.
	# Deux raisons, apprises l'une apres l'autre :
	#   - un contour ferme AVEC UN ERGOT reste d'un seul morceau. 42 morceaux pour 42 massifs,
	#     et 332 extremites quand meme ;
	#   - et des L1 le monde est d'un SEUL tenant avec des plateaux dedans : chaque bord de
	#     plateau est un contour ferme de plus, a l'interieur. 38 morceaux pour 1 massif, et
	#     c'est juste. Compter les morceaux reviendrait a compter les marches du relief.
	# Ce qui reste vrai a tous les niveaux, et c'est le mot demande : SANS INTERRUPTION. Un
	# trait d'un pixel qui se referme n'a aucune extremite.
	var i1: bool = true
	# ⚠ ET ON DIT OU LE TRAIT S'ARRETE. Un compte de morceaux dit qu'il y a une rupture, pas
	# ou -- et sans le « ou » on corrige au juge. Un trait d'un pixel qui se ferme n'a aucune
	# extremite : chaque pixel y a deux voisins. Une extremite est donc exactement un pixel
	# de trait qui n'en a qu'UN.
	var ends: Array[String] = []
	var end_count: int = 0
	for y: int in range(height):
		for x: int in range(width):
			if not _is_stroke(image, x, y):
				continue
			var around: int = 0
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if x + dx < 0 or y + dy < 0 or x + dx >= width or y + dy >= height:
						continue
					if _is_stroke(image, x + dx, y + dy):
						around += 1
			if around > 1:
				continue
			end_count += 1
			if ends.size() < 6:
				var owner: int = int(indices.get(Vector2i(x / RES, y / RES), -1))
				ends.append("%d,%d dans la tuile %d" % [x % RES, y % RES, owner])

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
	var claims: Dictionary = _claims(image, world, indices)
	var i3: bool = int(claims["doubles"]) == 0 and int(claims["muettes"]) == 0 \
			and int(claims["parasites"]) == 0

	# I4 MATIERE. Une case SANS AUCUN BORD est entierement opaque.
	#
	# ⚠ DEUX DEFINITIONS FAUSSES AVANT CELLE-CI, ET TOUTES DEUX AURAIENT CONDAMNE F1 A TORT.
	# « Aucun pixel de fond dans une case de matiere » : faux des que le trait rentre, car
	# l'entaille est de la transparence VOULUE -- le dossier l'ecrit, « le fond decouvert se
	# laisse en transparence, le jeu montre le vrai sol d'en dessous ». 28 290 faux trous.
	# Puis « la ligne de bord d'un cardinal plein est opaque » : faux au COIN -- une case dont
	# l'ouest rentre a forcement sa ligne nord entamee sur ses premiers pixels, et sa voisine
	# du nord l'entame exactement pareil, donc il n'y a aucun trou entre elles. 3 046 de plus.
	#
	# Ce qui reste vrai a toute liberte : une case dont les QUATRE cardinaux sont pleins n'a
	# aucun bord, donc aucune raison d'etre trouee nulle part. Les trous que le monde n'a pas,
	# eux, sont deja comptes par I1 -- un trou de trop est un contour de trop.
	var pierced: int = 0
	for cell: Vector2i in indices.keys():
		var index: int = int(indices[cell])
		if (index & BlobIndex.CARDINALS) != BlobIndex.CARDINALS:
			continue
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
	var wavy: int = 0
	for key: Variant in tiles.keys():
		for side: int in range(4):
			if (int(key) & CARDINALS[side]) != 0:
				continue
			var shape: String = _profile(tiles[key] as Image, side)
			profiles[shape] = true
			var parts: PackedStringArray = shape.split(",")
			for i: int in range(1, parts.size()):
				if parts[i] != parts[0]:
					wavy += 1
					break
	var promised: String = ""
	var i5: bool = true
	match freedom:
		0:
			promised = "un seul profil, plat"
			i5 = profiles.size() == 1 and wavy == 0
		1:
			promised = "plusieurs profils, tous plats"
			i5 = profiles.size() >= 2 and wavy == 0
		_:
			promised = "des profils qui serpentent"
			i5 = wavy > 0

	return {
		"I1": {"nom": "fermeture", "ok": end_count == 0,
				"dit": "%d extremites %s   (%d morceaux, %d massifs, %d trous)"
				% [end_count, str(ends), strokes, massifs, holes]},
		"I2": {"nom": "epaisseur", "ok": thick == 0,
				"dit": "%d pave(s) 2x2 de trait %s" % [thick, str(thick_where)]},
		"I3": {"nom": "unicite", "ok": i3,
				"dit": "%d frontieres (pile max %d), %d doubles, %d muettes, %d parasites  %s"
				% [int(claims["frontieres"]), int(claims["pile"]), int(claims["doubles"]),
				int(claims["muettes"]), int(claims["parasites"]), str(claims["ou"])]},
		"I4": {"nom": "matiere", "ok": pierced == 0,
				"dit": "%d pixel(s) de fond dans une case sans bord" % pierced},
		"I5": {"nom": "liberte", "ok": i5,
				"dit": "%d profil(s) distinct(s), %d qui serpentent -- promis : %s"
				% [profiles.size(), wavy, promised]},
	}


## QUI TRACE CHAQUE FRONTIERE ? Le coeur du banc, et le fil de tout le plan.
##
## ⚠ UNE FRONTIERE EST UNE MARCHE ENTRE DEUX ETAGES, pas « de la matiere contre rien ». A L0
## il n'y a qu'un etage, donc les deux definitions coincident et la premiere suffisait. Des
## L1, deux cases voisines de niveaux differents sont TOUTES DEUX de la matiere vue de dessus,
## et pourtant la silhouette du haut s'arrete la : c'est une vraie frontiere, et le bord du
## plateau doit s'y tracer. La premiere definition en faisait 1 105 « parasites » sur un monde
## parfaitement juste.
##
## La marche appartient a la case du HAUT -- c'est sa silhouette qui s'arrete -- donc on ne la
## compte qu'une fois, depuis elle. Et `pile` dit de combien d'etages elle tombe : c'est le
## nombre de silhouettes qui s'arretent au meme endroit, donc le nombre de tuiles qui
## POURRAIENT vouloir la tracer.
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
func _claims(image: Image, world: PackedStringArray, indices: Dictionary) -> Dictionary:
	var width: int = HeightMask.width(world)
	var height: int = HeightMask.height(world)
	var frontiers: int = 0
	var doubles: int = 0
	var mutes: int = 0
	var parasites: int = 0
	var deepest: int = 0
	var witness: Array[String] = []
	for cell: Vector2i in indices.keys():
		var here: int = HeightMask.level_at(world, cell.x, cell.y)
		for side: int in range(4):
			var probe: Vector2i = cell + STEPS[side]
			var beyond: int = -1
			if probe.x >= 0 and probe.y >= 0 and probe.x < width and probe.y < height:
				beyond = HeightMask.level_at(world, probe.x, probe.y)
			var mine: int = _draws(image, cell, side)
			var theirs: int = 0
			if beyond >= 0:
				theirs = _draws(image, probe, (side + 2) % 4)
			if here == beyond:
				# Une arete INTERIEURE ne se voit qu'une fois : depuis l'est et le sud.
				if side != 1 and side != 2:
					continue
				if mine + theirs > 0:
					parasites += 1
					if witness.size() < 3:
						witness.append("%d,%d parasite" % [cell.x, cell.y])
				continue
			if here < beyond:
				# La marche appartient a la case du HAUT : on la comptera depuis elle.
				continue
			frontiers += 1
			deepest = maxi(deepest, here - beyond)
			var claimants: int = mine + theirs
			if claimants == 0:
				mutes += 1
				if witness.size() < 3:
					witness.append("%d,%d muette" % [cell.x, cell.y])
			elif claimants > 1:
				doubles += 1
				if witness.size() < 3:
					witness.append("%d,%d double" % [cell.x, cell.y])
	return {"frontieres": frontiers, "doubles": doubles, "muettes": mutes,
			"parasites": parasites, "pile": deepest, "ou": witness}


## COMBIEN DE TRAITS CE COTE PORTE-T-IL ? On compte, on ne se contente pas de constater.
##
## ⚠ ET C'EST LA DIFFERENCE QUI FAIT TOUT. Premiere version : « y a-t-il du trait ? ». Elle
## repond OUI aussi bien pour un trait que pour deux, donc elle laisse passer exactement ce que
## I3 existe pour attraper -- deux tuiles qui tracent la meme frontiere. A L1/F2 elle annoncait
## zero double pendant que I2 comptait six paves. On compte donc les PASSAGES de fond a trait,
## en partant du bord vers le milieu.
##
## ⚠ ON SONDE PERPENDICULAIREMENT, AU MILIEU DU COTE -- et pas la ligne du bord.
##
## A F0 le trait est au ras, donc le lire sur la ligne du bord suffisait. Des que le trait a
## le droit de RENTRER, cette lecture ne trouve plus rien et toutes les frontieres se disent
## muettes. On part donc du bord et on avance vers le centre : la case revendique ce cote si
## elle pose du trait AVANT le milieu.
##
## ⚠ ET AU MILIEU, PAS PARTOUT. Balayer toute la bande ferait prendre le trait du NORD -- qui
## traverse la tuile de part en part -- pour une revendication de l'OUEST. La sonde au milieu
## ne rencontre que ce qui borde vraiment ce cote-la. Meme raison qui exclut le pixel de coin :
## ce qui appartient a deux aretes ne decide d'aucune.
func _draws(image: Image, cell: Vector2i, side: int) -> int:
	var middle: int = RES / 2
	var runs: int = 0
	var inside: bool = false
	for d: int in range(middle):
		var at: Vector2i = Vector2i.ZERO
		match side:
			0: at = Vector2i(cell.x * RES + middle, cell.y * RES + d)
			1: at = Vector2i(cell.x * RES + RES - 1 - d, cell.y * RES + middle)
			2: at = Vector2i(cell.x * RES + middle, cell.y * RES + RES - 1 - d)
			_: at = Vector2i(cell.x * RES + d, cell.y * RES + middle)
		var here: bool = _is_stroke(image, at.x, at.y)
		if here and not inside:
			runs += 1
		inside = here
	return runs


## Le profil d'un bord : la profondeur du trait, colonne par colonne. C'est la mesure de la
## liberte -- a F0 il n'y en a qu'un seul possible, a F1 sa hauteur varie, a F2 sa forme.
## ⚠ ET IL SE LIT LOIN DES COINS. Pres d'un coin saillant, la rangee n'a pas de matiere du
## tout -- l'autre cote l'a creusee -- et la sonde y rencontre le trait PERPENDICULAIRE, a une
## profondeur qui n'a rien a voir. Elle annoncait alors 24 profils « qui serpentent » sur un
## F1 parfaitement droit. On lit donc le quart central, la ou le cote est seul.
func _profile(tile: Image, side: int) -> String:
	var out: PackedStringArray = PackedStringArray()
	for i: int in range(RES / 4, 3 * RES / 4):
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
