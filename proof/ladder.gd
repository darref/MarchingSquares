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
const Walls := preload("res://core/walls.gd")

## LE BORD D'UNE SURFACE : `nu` ou `roche`, a l'est et a l'ouest.
##
## ⚠ C'EST LA REPONSE DE L2 A « QUI TRACE ? », ET ELLE A ETE MESUREE CONTRE SON ALTERNATIVE.
## A la frontiere entre le flanc d'une falaise et le bord lateral de la surface voisine, les
## deux tracent. Il n'y a pas de theoreme pour trancher -- un flanc qui s'arrete ne borde jamais
## de la roche (0 sur 5 216) mais borde de la terre 35,5 % du temps et du vide 64,5 % -- donc
## l'un des deux doit porter un BIT de plus. Mesure sur le meme monde, a L2/F1 :
##
##     option                          tuiles    extremites   doublements
##     aucune                          47        213          196
##     A  troisieme etat de flanc      59        720          1450
##     B  le bord sur la surface       57        222          12
##
## ⚠ ON NE PEUT PAS FAIRE TAIRE LE FLANC, ON PEUT FAIRE TAIRE LA SURFACE. Le trait de flanc
## PORTE LA CONNEXITE du contour de la falaise -- deja mesure : le retirer coute deux tirets par
## falaise. Le faire taire contre du sol fragmente le contour, d'ou 720 extremites et 1 450
## doublements. Le bord lateral d'une surface, lui, se tait sans rien casser. Et B est moins
## cher : 57 tuiles contre 59.
##
## Le bit vaut 1 pour l'est, 2 pour l'ouest, et se range au-dessus des huit bits de silhouette.

## L'OPTION D, CHIFFREE ET REFUSEE : l'ergot de coin rentrant se tait quand ce qu'il devait
## rejoindre s'est tu.
##
## Diagnostic, vu au pixel apres deux hypotheses fausses : les 222 extremites sont des ERGOTS
## QUI PENDENT. Un ergot est trace pour rejoindre le bord lateral de la case d'a cote, en
## diagonale -- et le BORD (option B) vient justement de faire taire ce bord-la quand il longe
## de la roche. L'ergot tombe alors dans le vide.
##
## Le bit : pour chaque coin ou l'ergot se declenche, la case DIAGONALE porte-t-elle une robe ?
## Si oui, la voisine s'est tue et l'ergot n'a plus personne a rejoindre : on ne le trace pas.
##
## ⚠ MESURE, UNE FOIS LE CABLAGE D'APLOMB : ELLE NE FERME RIEN. 43 -> 43 extremites, pour
## 57 -> 67 tuiles. Les « 11 fermees » d'une premiere mesure venaient d'un GARDE PARASITE laisse
## par une edition anterieure -- `if (quiet & (1 << corner)): continue` -- qui supprimait les
## DEUX ergots au lieu du bon. L'option reste au depot derriere `LADDER_OPT=D`, comme trace.
##
## ⚠ ET C'EST LA TROISIEME FOIS QUE LE MEME PIEGE ME COUTE UNE MESURE : un remplacement dont
## l'ancrage rate en SILENCE, et je lis un chiffre qui ne mesure pas ce que je crois. Trois
## fois : le bit pose sur la carte visible mais pas sur la silhouette ; le bloc D jamais insere ;
## le garde parasite ci-dessus. Un `assert` a chaque ancrage coute une ligne.

## Cette case-la trace-t-elle son bord de ce cote ? Quatre facons de ne pas le tracer, et
## chacune fait pendre l'ergot qui comptait dessus : elle porte une ROBE, qui la recouvre ; son
## cardinal est PLEIN, donc elle n'a pas de bord la ; le BORD (option B) l'a fait TAIRE ; ou
## c'est son SUD, qui ne se trace plus du tout des L2.
## La robe au-dessus trace-t-elle son bas ? Seul un PIED le fait -- une rangee de corps s'arrete
## sans bord, qu'elle soit ecretee ou non.
static func _foot_above(cell: Vector2i, roles: Dictionary) -> bool:
	if not roles.has(cell):
		return false
	return (roles[cell] as Vector2i).y == Walls.ROW_FOOT


static func _draws_side(cell: Vector2i, side: int, indices: Dictionary,
		roles: Dictionary) -> bool:
	if side == 2:
		return false
	if roles.has(cell) or not indices.has(cell):
		return false
	var tile: int = int(indices[cell])
	if (tile & CARDINALS[side]) != 0:
		return false
	var quiet: int = tile >> 8
	if side == 1 and (quiet & 1) != 0:
		return false
	if side == 3 and (quiet & 2) != 0:
		return false
	return true


## La case du dessus laisse-t-elle un trait de ce cote-la ? Une ROBE le laisse si son flanc
## s'ARRETE ; une SURFACE le laisse si son cardinal est ouvert et que le bord ne l'a pas fait
## taire.
static func _above_draws(cell: Vector2i, side: int, indices: Dictionary,
		roles: Dictionary) -> bool:
	if roles.has(cell):
		var role: Vector2i = roles[cell]
		var flank: int = Walls.pan_east(role.x) if side == 1 else Walls.pan_west(role.x)
		return flank == Walls.SIDE_STOP
	return _draws_side(cell, side, indices, roles)


## L'OPTION C, chiffree et SANS EFFET : un bit sur la robe, « la case au-dessus trace de ce
## cote ». L'hypothese etait que les 222 venaient du flanc `continue` d'un chapiteau, qui laisse
## tomber le bord lateral de sa levre. Mesure : 222 inchangees, et le bit ne se declenche
## QU'UNE FOIS sur toute la planche -- 21 roles au lieu de 20. La cause etait ailleurs.
##
## L'OPTION C, a chiffrer : UN BIT SUR LA ROBE, « la case au-dessus trace de ce cote ».
##
## Les 222 extremites sont le bord lateral d'une LEVRE qui meurt a son bas, faute de retrouver
## la crete du chapiteau. Le cas n'arrive que quand le flanc du chapiteau dit `continue` : s'il
## dit `arret`, il trace son propre bord a la meme profondeur et les deux se retrouvent.
##
## Le chapiteau devrait donc savoir que la case au-dessus trace de ce cote-la, pour poser un
## ERGOT le long de son bord haut -- exactement le geste des coins rentrants, de l'autre cote
## de la frontiere. C'est une information qu'un role de robe ne porte pas : deux flancs, une
## rangee, rien d'autre.
static var _option: String = ""

## ⚠ J2 : LE CHOIX EST ARRETE -- C'EST LA SURFACE QUI SE TAIT. Trois conceptions mesurees sur
## le meme monde, a L2/F1 :
##
##     aucun bit            47 tuiles,  47 en borne,  2 extremites, 196 DOUBLEMENTS
##     bit sur la face      60 tuiles,  81 en borne, 32 EXTREMITES,   0 doublement
##     bit sur la surface   76 tuiles, 248 en borne,  2 extremites,   0 doublement
##
## La regle du projet est « traits continus SIMPLES, jamais doubles » -- c'est elle qui garantit
## la liberte maximale et l'exhaustivite de ce qu'on pourra dessiner. Elle elimine la premiere,
## dont les 196 doublements sont la chaine de lentilles vue a l'ecran. L'ordre des priorites
## elimine la deuxieme : trouee. Reste la troisieme.
##
## ⚠ ET SA MINIMALITE N'EST PAS PROUVEE : 248 est une BORNE, pas une preuve. C'est le travail qui
## reste, et il a une contrainte -- toute reduction doit garder I3 A ZERO et I1 A ZERO.
##
## Les deux autres restent joignables par `LADDER_J2=face` et `LADDER_J2=none`, comme trace des
## mesures : un chiffre qu'on ne peut plus reproduire n'est plus un chiffre.
static var _j2_on_face: bool = false

## ⚠ ET UNE TROISIEME CONCEPTION, LA MOINS CHERE DE TOUTES : AUCUN BIT. Les deux tracent, et on
## regarde si c'est vraiment un doublement. A F0 tout est au ras, donc les deux traits sont
## voisins d'un pixel et I3 crie ; des que le trait rentre, ils sont ecartes de DEUX traversees
## et bornent deux choses differentes -- la roche de la face d'un cote, le sol de la surface de
## l'autre, avec de la transparence entre les deux. Si F1 et F2 sont propres sans bit, J2 coute
## ZERO et le vocabulaire reste a 47.
static var _j2_none: bool = false

## L3 : CE QU'UNE POSE ARRIERE A LE DROIT DE TRACER. Trois conceptions, toutes mesurees, et
## c'est I6 QUI A TRANCHE -- les cinq premiers invariants ne les separaient pas.
##
##   `trace`   elle pose SA tuile, contour compris -- une tuile, un dessin, rien de neuf.
##             REFUSEE : 300 paves 2x2, le trait de la surface et celui de la roche reposee a
##             un pixel l'un de l'autre ;
##   `full`    elle pose la ROCHE PLEINE, c'est-a-dire le role (continue, continue) d'un corps,
##             qui n'a aucun cote ouvert donc aucun trait. Zero tuile de plus, et vert sur les
##             cinq premiers -- mais REFUSEE par I6 : 1 506 pixels de roche affirmee la ou le
##             modele n'en a pas, sur 5 828 pixels de transparence, soit 26 % de la fenetre ;
##   `mute`    (DEFAUT) elle pose sa matiere SANS son contour. Seule verte sur les six ; son
##             prix est un second dessin par role, et il se paiera au contrat.
##
## Les deux refusees restent joignables par `LADDER_BACKING`, comme trace de la mesure.
static var _backing: String = "mute"

## Combien de bords ouverts une surface porte, et combien ne donnent PAS sur une face.
static var _open_edges: int = 0
static var _bare_edges: int = 0
const MaskIO := preload("res://core/mask_io.gd")
const Modes := preload("res://core/modes.gd")

## La planche relue une fois, gardee pour le fond de contexte des images.
static var _board: PackedStringArray = PackedStringArray()

const RES: int = 16
## Ce qu'il faut ajouter sous la planche pour qu'une chute dans le vide y tienne entiere.
const MARGIN: int = 6
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
## La roche des falaises : claire elle aussi, pour que le trait noir s'y lise.
const ROCK: Color = Color("#d6bb95")

const BACKDROP: Color = Color("#23262b")
const CONTEXT: Color = Color("#3f4a38")

## Les couples deja gagnes, dans l'ordre. On les rejoue tous a chaque execution.
const ACQUIS: Array[String] = ["L0/F0", "L0/F1", "L0/F2", "L1/F0", "L1/F1", "L1/F2",
		"L2/F0", "L2/F1", "L2/F2", "L3/F0", "L3/F1", "L3/F2"]

const CARDINALS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
## La diagonale de chaque coin, dans le meme ordre : NO, NE, SE, SO.
const DIAGONALS: Array[int] = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW]
const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SIDE_NAMES: Array[String] = ["nord", "est", "sud", "ouest"]

## LES BITS DU BORD, au-dessus des huit de silhouette.
##
## ⚠ ET ILS DOIVENT ETRE DISJOINTS DE CEUX DE L'ERGOT : `4 << coin` couvre 4, 8, 16, 32 et
## `64 << coin` couvre 64 a 512. Le nord valait 8 -- exactement le bit du coin 1 de l'ergot.
## Collision silencieuse, trouvee en cherchant ou loger les suivants.
const NORTH_QUIET: int = 1024        ## une face me couvre au nord : c'est le PIED qui trace
const ABOVE_QUIET_EAST: int = 2048   ## la case du dessus s'est tue a l'est
const ABOVE_QUIET_WEST: int = 4096   ## la case du dessus s'est tue a l'ouest


func _initialize() -> void:
	_j2_on_face = OS.get_environment("LADDER_J2") == "face"
	_j2_none = OS.get_environment("LADDER_J2") == "none"
	# ⚠ ET LE DEFAUT NE SE FAIT PAS ECRASER PAR UNE VARIABLE ABSENTE : sans elle, on garde la
	# conception que la mesure a choisie.
	if not OS.get_environment("LADDER_BACKING").is_empty():
		_backing = OS.get_environment("LADDER_BACKING")
	if _j2_none:
		_j2_on_face = true
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
		canonical[BlobIndex.canonicalize(int(indices[cell]) & 0xff)] = true
	var expected: int = Thickness.SURFACE_INDICES.size()
	var complete: bool = canonical.size() == expected
	print("  vocabulaire exerce : %d / %d silhouettes%s   %d tuiles a peindre"
			% [canonical.size(), expected, "" if complete else "  ⚠ INCOMPLET",
			vocabulary.size()])

	# ⚠ LES FALAISES D'ABORD, LES TUILES ENSUITE. Le calcul des bords change le VOCABULAIRE ;
	# peindre avant, c'est peindre une liste a laquelle il manque des cles -- et l'assemblage
	# tombe alors sur une tuile nulle, sans rien dire de plus utile que « get_width sur null ».
	var roles: Dictionary = {}
	var role_tiles: Dictionary = {}
	if level >= 2:
		roles = Walls.visible(world)["roles"]
		# ⚠ UNE CHUTE QUI S'ARRETE DOIT SE FERMER, QUELLE QUE SOIT LA RAISON. Le modele ne pose
		# le PIED qu'a l'atterrissage : une chute qui tombe dans le VIDE n'en pose pas -- « on
		# ne touche pas le fond d'un gouffre » -- et une chute ECRETEE non plus, elle s'arrete
		# sur une rangee de corps. Or dans les deux cas la roche VISIBLE a une fin, et une
		# rangee de corps n'a pas de bord bas : personne ne la trace.
		#
		# On y pose donc le PIED, qui est exactement la tuile « bas de falaise ». Cout : ZERO
		# tuile. Ce qui change est le SENS du pied -- il ne prouve plus un atterrissage, il
		# FERME CE QU'ON VOIT DE LA FACE. C'est deja ce qu'il faisait pour le vide ; l'ecretage
		# est le meme fait, avec du sol derriere au lieu du neant.
		#
		# ⚠ ET LA CONDITION EST « AUCUNE ROBE EN DESSOUS », pas « du vide en dessous ». Un
		# atterrissage a deja son pied, donc la substitution y est un no-op ; ce qu'elle attrape
		# est exactement ce qui s'arretait sans bord.
		#
		# ⚠ ET ELLE SE FAIT AVANT LES BITS DE BORD, JAMAIS APRES. C'est `_foot_above` qui fait
		# taire le nord de la surface d'en dessous : calculee apres, la substitution arrive trop
		# tard, la surface trace son nord A SA PROFONDEUR et la frontiere a deux descriptions
		# qui ne se rejoignent pas au coin. Sixieme fois qu'un ordre de calcul me coute une
		# mesure.
		var closed: Dictionary = {}
		for cell: Vector2i in roles.keys():
			var role: Vector2i = roles[cell]
			var ends: bool = not roles.has(cell + Vector2i.DOWN)
			closed[cell] = Vector2i(role.x, Walls.ROW_FOOT) if ends else role
		roles = closed
		# ⚠ LE BIT SE CALCULE ICI, PAS DANS LA TUILE. C'est justement ce qu'une tuile ne peut
		# pas savoir : ce qu'il y a de l'autre cote. Le banc, lui, a le monde sous les yeux --
		# c'est ce qui permet de MESURER le prix avant de decider si on le paie.
		for y: int in range(HeightMask.height(world)):
			for x: int in range(HeightMask.width(world)):
				var cell2: Vector2i = Vector2i(x, y)
				if not indices.has(cell2):
					continue
				var tile2: int = int(indices[cell2])
				var edge: int = 0
				# ⚠ ET ON COMPTE CE QU'IL Y A DERRIERE CHAQUE BORD OUVERT. Si TOUT bord lateral
				# ou nord d'une surface donne sur une case couverte par une FACE, alors la
				# surface n'a jamais besoin de le tracer -- la face le fait -- et J2 coute ZERO
				# bit des deux cotes. C'est le seul chemin vers 47 tuiles, et il se mesure.
				for side: int in range(4):
					if side == 2 or (tile2 & CARDINALS[side]) != 0:
						continue
					_open_edges += 1
					if not roles.has(cell2 + STEPS[side]):
						_bare_edges += 1
				if not _j2_on_face and (tile2 & BlobIndex.E) == 0 and roles.has(cell2 + Vector2i.RIGHT):
					edge |= 1
				if not _j2_on_face and (tile2 & BlobIndex.W) == 0 and roles.has(cell2 + Vector2i.LEFT):
					edge |= 2
				# ⚠ ET LE NORD : SOUS UNE FACE, C'EST UN PLI, DONC C'EST LE BORD. Quand une
				# robe couvre ma voisine du nord, ce que j'ai au-dessus n'est pas un sol plus
				# bas mais le PIED d'une falaise -- il occupe sa case entiere, et la frontiere
				# entre nous est le bord de case. Mon bord nord s'y met donc au ras, et le pied
				# n'a plus a le tracer.
				#
				# ⚠ CE N'EST PAS « TOUT NORD AU RAS », ESSAYE ET REFUTE : 43 -> 65 extremites,
				# 94 paves. Contre un simple sol plus bas, le bord du voisin est libre, et
				# mettre le mien au ras l'empeche de le retrouver.
				# ⚠ ET SEULEMENT SI LA ROBE AU-DESSUS TRACE VRAIMENT SON BAS, c'est-a-dire si
				# c'est un PIED. Une chute ECRETEE s'arrete sur une rangee de corps, qui n'a pas
				# de bord bas : la faire taire quand meme laisse la frontiere sans personne, et
				# la roche bute sur l'herbe sans un trait. Vu au pixel, trois fois.
				if not _j2_on_face and (tile2 & BlobIndex.N) == 0 					and _foot_above(cell2 + Vector2i.UP, roles):
					edge |= NORTH_QUIET

				indices[cell2] = tile2 | (edge << 8)
				vocabulary[tile2 | (edge << 8)] = true
				# ⚠ ET DANS LA SILHOUETTE AUSSI, sinon rien ne bouge : c'est elle que
				# l'assemblage lit, pas la carte visible.
				var mine2: Dictionary = storeys[HeightMask.level_at(world, x, y)]
				mine2[cell2] = tile2 | (edge << 8)
		# ⚠ ET LES BITS DE L'ERGOT SE POSENT EN SECONDE PASSE. Ils demandent si la VOISINE
		# trace son bord -- ce qui depend du bord qu'on vient de lui poser. Calcules dans la
		# meme boucle, ils interrogent une case pas encore traitee et repondent au hasard : la
		# voisine du sud, en ordre de lecture, n'a jamais encore le sien. Cinquieme fois qu'un
		# ordre de calcul me coute une mesure.
		# ⚠ ET RIEN DE TOUT CA QUAND LA FACE PORTE LE BIT. L'ergot et la traversee au ras
		# sont des RUSTINES DU SILENCE DE LA SURFACE : ils existent pour rattraper un bord
		# que la surface a cesse de tracer. Si c'est la face qui cede, la surface ne se tait
		# jamais et il n'y a rien a rattraper -- les garder ferait payer 10 tuiles pour rien.
		if not _j2_on_face:
			for y2: int in range(HeightMask.height(world)):
				for x2: int in range(HeightMask.width(world)):
					var here2: Vector2i = Vector2i(x2, y2)
					if not indices.has(here2):
						continue
					var full: int = int(indices[here2])
					var shape: int = full & 0xff
					var more: int = full >> 8
					for corner: int in range(4):
						var a: int = corner
						var b: int = (corner + 3) % 4
						if (shape & CARDINALS[a]) == 0 or (shape & CARDINALS[b]) == 0:
							continue
						if (shape & DIAGONALS[corner]) != 0:
							continue
						if not _draws_side(here2 + STEPS[a], b, indices, roles):
							more |= 4 << corner
						if not _draws_side(here2 + STEPS[b], a, indices, roles):
							more |= 64 << corner
					# ⚠ ET LE BORD LATERAL MEURT A SON NORD QUAND LA CASE DU DESSUS S'EST TUE DE
					# CE COTE-LA. Elle s'est tue parce qu'une ROBE la longe : c'est donc le flanc
					# de cette robe qui porte la frontiere, une case plus haut et une colonne plus
					# loin. Mon bord doit alors traverser ma frontiere nord AU RAS, pour aller le
					# toucher au coin au lieu de s'arreter a sa profondeur.
					var over: Vector2i = here2 + Vector2i.UP
					if (shape & BlobIndex.N) != 0 and indices.has(over) and not roles.has(over):
						var up: int = int(indices[over]) >> 8
						if (shape & BlobIndex.E) == 0 and (up & 1) != 0:
							more |= ABOVE_QUIET_EAST
						if (shape & BlobIndex.W) == 0 and (up & 2) != 0:
							more |= ABOVE_QUIET_WEST
					if more == full >> 8:
						continue
					indices[here2] = shape | (more << 8)
					vocabulary[shape | (more << 8)] = true
					var mine3: Dictionary = storeys[HeightMask.level_at(world, x2, y2)]
					mine3[here2] = shape | (more << 8)
		# ⚠ J2 « SOMMET CONTRE FACE » : DE QUEL COTE ON POSE LE BIT. Un des deux doit se taire, donc
		# il faut un bit -- mais il MULTIPLIE la famille qui le porte. Sur la surface il double 27
		# silhouettes (jusqu'a 228 en forme fermee) ; sur la face il ne touche que 20 roles
		# (jusqu'a 54). Le compte se calcule avant de choisir, et se MESURE avant d'etre paye.
		if _j2_on_face:
			var yielded: Dictionary = {}
			for cell: Vector2i in roles.keys():
				var role: Vector2i = roles[cell]
				var ground: int = HeightMask.level_at(world, cell.x, cell.y)
				var give: int = 0
				if _j2_none:
					yielded[cell] = Vector3i(role.x, role.y, 0)
					continue
				# La face CEDE le trait a la surface qui le tracera de toute facon, et le GARDE
				# la ou rien ne la borde. Une surface trace son bord vers moi si elle est PLUS
				# HAUTE que le sol que je couvre : c'est ce qui rend son cardinal ouvert.
				var sides: Array[int] = [Walls.pan_west(role.x), Walls.pan_east(role.x)]
				for i: int in range(2):
					if sides[i] != Walls.SIDE_STOP:
						continue
					var probe: Vector2i = cell + (Vector2i.LEFT if i == 0 else Vector2i.RIGHT)
					if HeightMask.level_at(world, probe.x, probe.y) > ground:
						give |= 1 << i
				if role.y == Walls.ROW_FOOT:
					var under: Vector2i = cell + Vector2i.DOWN
					if HeightMask.level_at(world, under.x, under.y) > ground:
						give |= 4
				yielded[cell] = Vector3i(role.x, role.y, give)
			roles = yielded

	# ------------------------------------------------------------- L3 : LES POSES ARRIERE
	#
	# ⚠ UNE POSE, PAS UNE TUILE -- c'est la ligne du dossier, et c'est ce qui rend le niveau
	# bon marche. Les trois especes reposent une tuile de robe DEJA au vocabulaire, sous une
	# case de surface : le PIED sous une case d'atterrissage, un CORPS sous la case qui ecrete
	# une chute, le CHAPITEAU sous la levre qui lance la face. Rien de neuf a peindre.
	#
	# ⚠ CE QUI EST NEUF, C'EST QU'UNE CASE PORTE DEUX TUILES. Jusqu'ici chaque case avait un
	# seul occupant ; ici la surface recouvre la roche et ne la laisse voir que par ses coins
	# decoupes. C'est le « 2 revendiquants, dont une cachee » du plan, et toute la question du
	# niveau tient dans ce que la tuile cachee a le droit de tracer.
	#
	# ⚠ ET ELLES SE POSENT PAR ETAGE D'ATTERRISSAGE, jamais toutes au debut : l'assemblage
	# dessine les etages du bas vers le haut, et posees en tete la plaine les recouvrirait
	# avant meme que la banquette n'arrive. Meme regle que l'illustration du depot, meme
	# raison -- elle y a ete trouvee a l'ecran, pas au test.
	var under: Dictionary = {}
	var under_by_level: Array[Dictionary] = []
	for storey: int in range(storeys.size()):
		under_by_level.append({})
	if level >= 3:
		under = Walls.visible_underfoot(world)
		var by_kind: Dictionary = {}
		for cell: Vector2i in under.keys():
			var landing: int = HeightMask.level_at(world, cell.x, cell.y)
			if landing < 0:
				continue
			var role: Vector2i = under[cell]
			var kind: String = "corps (ecretage)"
			if role.y == Walls.ROW_FOOT:
				kind = "pied (atterrissage)"
			elif role.y == Walls.ROW_CROWN:
				kind = "chapiteau (sous sa levre)"
			by_kind[kind] = int(by_kind.get(kind, 0)) + 1
			# ⚠ `full` REPOSE UNE TUILE QUI EXISTE DEJA : le role (continue, continue) d'un
			# corps n'a aucun cote ouvert, donc aucun trait -- c'est le carre de roche plein.
			# Zero tuile de plus, et rien a fabriquer : le peintre l'a deja peinte.
			var posed: Vector2i = role
			if _backing == "full":
				posed = Vector2i(_solid_pan(), Walls.ROW_CROWN + 1)
			(under_by_level[landing] as Dictionary)[cell] = _wall_key(posed)
		var said: PackedStringArray = PackedStringArray()
		for kind: String in by_kind.keys():
			said.append("%d %s" % [int(by_kind[kind]), kind])
		said.sort()
		print("  poses arriere : %d  -- %s" % [under.size(), ", ".join(said)])

	var kinds: Dictionary = {}
	for cell: Vector2i in roles.keys():
		kinds[roles[cell]] = true
	print("  robes : %d roles distincts, %d cases de falaise"
			% [kinds.size(), roles.size()])
	var tiles: Dictionary = _paint(vocabulary, freedom, level)
	print("  A PEINDRE : %d tuiles de surface" % tiles.size())
	if _open_edges > 0:
		print("  bords ouverts d'une surface : %d, dont %d SANS face en face (%.1f %%)"
				% [_open_edges, _bare_edges, 100.0 * float(_bare_edges) / float(_open_edges)])
	if level >= 2:
		var kinds2: Dictionary = {}
		for cell: Vector2i in roles.keys():
			kinds2[roles[cell]] = true
		# ⚠ ET LES ROLES REPOSES AUSSI. Une pose arriere n'ajoute aucune tuile au vocabulaire,
		# mais elle peut etre la SEULE occurrence d'un role sur ce monde-la : sans sa cle, le
		# dictionnaire des tuiles n'a rien a rendre et l'assemblage tombe sur un nul, qui ne
		# dit rien de plus utile que « get_width sur null ».
		for cell: Vector2i in under.keys():
			kinds2[_wall_key(under[cell])] = true
		if _backing == "full":
			kinds2[_wall_key(Vector2i(_solid_pan(), Walls.ROW_CROWN + 1))] = true
		role_tiles = _wall_tiles(kinds2, freedom)
		print("  A PEINDRE : %d roles de robe   -- TOTAL %d"
				% [role_tiles.size(), tiles.size() + role_tiles.size()])
		# ⚠ ET ON MESURE LA LIBERTE RENDUE AUX FACES, au lieu de la supposer. Le pincement aux
		# deux traversees doit leur laisser un profil qui serpente ; s'il n'en laisse aucun,
		# c'est qu'on a paye la complication sans rien gagner.
		var shapes: Dictionary = {}
		var wavy: int = 0
		for key: Variant in role_tiles.keys():
			for side: int in range(4):
				var line: String = _profile(role_tiles[key] as Image, side)
				if not line.contains("-1"):
					shapes[line] = true
					var cut: PackedStringArray = line.split(",")
					for i: int in range(1, cut.size()):
						if cut[i] != cut[0]:
							wavy += 1
							break
		print("  liberte des faces : %d profil(s) distinct(s), %d qui serpentent"
				% [shapes.size(), wavy])
	# ⚠ `mute` EST LE SEUL DES TROIS QUI FABRIQUE UN SECOND DESSIN, et c'est son prix : la
	# planche exportee dit « une tuile, un dessin », donc un moteur devrait poser une seconde
	# feuille ou effacer un trait a l'execution. On le mesure quand meme -- refuser une option
	# sans son chiffre, c'est exactement ce que ce plan existe pour empecher.
	var backing_tiles: Dictionary = role_tiles
	if _backing == "mute":
		backing_tiles = {}
		for key: Variant in role_tiles.keys():
			backing_tiles[key] = _muted(role_tiles[key] as Image)
	var image: Image = _assemble(world, storeys, tiles, roles, role_tiles, under_by_level,
			backing_tiles)
	# LE TEMOIN DE I6 : le meme monde, sans une seule pose arriere. Ce que la pose donne a voir
	# est exactement ce qui differe entre les deux -- rien a classer par la couleur.
	var bare: Image = null
	if level >= 3:
		var none: Array[Dictionary] = []
		for storey: int in range(storeys.size()):
			none.append({})
		bare = _assemble(world, storeys, tiles, roles, role_tiles, none, backing_tiles)
	_write(image, couple)
	var report: Dictionary = _measure(image, world, indices, tiles, freedom, roles, under,
			role_tiles, bare)
	var ok: bool = complete
	for key: String in ["I1", "I2", "I3", "I4", "I5", "I6"]:
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
## ⚠ LA MARGE VAUT UNE CHUTE ENTIERE, ET LA PLANCHE N'EN A PAS ASSEZ. Une chute dans le VIDE
## descend de `STOREY_TILES x (etage + 1)` -- neuf rangees depuis l'etage 2 -- et la planche n'a
## que six rangees de vide sous elle. Sa falaise du bord du monde est donc COUPEE PAR LE CADRE,
## et son contour reste ouvert : deux extremites, aux deux coins bas.
##
## Ce n'est pas un defaut de regle, c'est un relief qui manque de place -- le dossier l'ecrit
## deja : « une robe hors grille est une tuile impeignable ». On rend donc la place ici, et on
## note que la planche du PRODUIT a le meme manque, a corriger de son cote.
func _with_margin(relief: PackedStringArray) -> PackedStringArray:
	var width: int = HeightMask.width(relief)
	var out: PackedStringArray = relief.duplicate()
	var empty: String = ""
	for x: int in range(width):
		empty += "~"
	for row: int in range(MARGIN):
		out.append(empty)
	return out


func _world(level: int) -> PackedStringArray:
	# ⚠ ET LE MONDE PEUT ETRE LE GUIDE, pour savoir s'il porte encore tout le vocabulaire.
	# La planche de preuve est batie POUR l'exercer ; le guide, lui, est ce que l'acheteur
	# peindra -- s'il ne porte pas une tuile, cette tuile est impeignable.
	if OS.get_environment("LADDER_WORLD") == "guide":
		_board = HeightMask.read(Modes.guide_path(Modes.EPAIS))
		return _board
	_board = _with_margin(ProofScene.relief(Families.BY_CELL))
	# ⚠ L3 NE CHANGE PAS LE MONDE, IL CHANGE CE QU'ON Y POSE. La planche porte deja les trois
	# especes de pose arriere -- l'atterrissage (le sous-pied), l'ecretage (la pose derriere,
	# c'est la paire de piliers ajoutee pour ca), et la levre (le chapiteau sous sa levre).
	# Un monde de plus ne prouverait rien de plus ; ce qui manquait, c'est la POSE.
	if level >= 1 and level <= 3:
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
func _paint(vocabulary: Dictionary, freedom: int, level: int) -> Dictionary:
	var tiles: Dictionary = {}
	for key: Variant in vocabulary.keys():
		var index: int = int(key) & 0xff
		var brink: int = int(key) >> 8
		var open: Array[bool] = [false, false, false, false]
		for side: int in range(4):
			open[side] = (index & CARDINALS[side]) == 0
		# Contre de la ROCHE, la surface se tait : c'est le flanc de la falaise qui trace.
		if (brink & 1) != 0:
			open[1] = false
		if (brink & 2) != 0:
			open[3] = false
		# ⚠ RIEN AU SUD -- MAIS SEULEMENT DANS UN MONDE QUI A DES FALAISES. Le theoreme est :
		# une case dont le sud est vide est une LEVRE, sa propre falaise commence juste
		# dessous, toujours. Le bord sud d'une surface et la crete du chapiteau sont donc LA
		# MEME frontiere, et c'est le chapiteau qui la porte -- lui seul sait de quelle face il
		# s'agit. Mesure : 780 doublements sans cette regle, 196 avec.
		#
		# ⚠ ET IL NE VAUT PAS A L0 NI A L1, dont les mondes n'ont pas de falaise : un sud vide
		# y est une vraie frontiere libre, que personne d'autre ne tracera. L'appliquer partout
		# a fait rougir les SIX couples acquis d'un coup -- c'est le rejeu qui l'a dit, pas moi.
		# Une regle juste a un niveau peut etre fausse au niveau d'en dessous.
		# ⚠ RIEN AU SUD, ET RENDRE LE SUD A ETE ESSAYE : 222 -> 669 extremites, 288
		# doublements, 11 388 parasites. Le bord sud d'une case et le bord NORD de celle d'en
		# dessous sont LA MEME frontiere -- l'une des deux doit se taire, et c'est le sud, dont
		# la voisine du nord existe toujours alors que la crete, elle, peut manquer.
		if level >= 2:
			open[2] = false
		# ⚠ ET SOUS UNE FACE, LA SURFACE SE TAIT AU NORD -- symetrique exact du bord lateral.
		# Le bas du PIED et mon bord nord sont la meme frontiere ; le pied la porte, parce que
		# son bas referme le contour de la falaise et que rien d'autre ne le peut.
		if (brink & NORTH_QUIET) != 0:
			open[0] = false
		tiles[int(key)] = _shape(open, freedom, GRASS, index, brink)
	return tiles


## LES ROBES : meme fabrique, autres bords ouverts.
##
## ⚠ ET C'EST TOUT CE QUE L2 AJOUTE AU DESSIN. Une tuile de robe a exactement les memes
## frontieres qu'une surface, seulement designees autrement : la CRETE en haut du chapiteau,
## le PIED en bas de la derniere rangee, et les flancs qui S'ARRETENT. Partout ailleurs la
## roche continue chez la voisine, comme la matiere d'une surface continue chez la sienne.
##
## ⚠ ET PAS D'ERGOT DE COIN RENTRANT. Il demande de savoir si la DIAGONALE est vide alors que
## les deux cardinaux sont pleins ; un role de robe -- deux flancs, une rangee -- ne porte pas
## cette information. On note ce que le banc en dira plutot que de l'inventer.
## LA CLE D'UNE TUILE DE ROBE A DEUX FORMES, selon le cote ou le bit de J2 est pose :
## (pan, rangee) quand c'est la surface qui se tait, (pan, rangee, cession) quand c'est la
## face. Une pose arriere est cachee sous une surface -- elle ne cede son trait a personne,
## d'ou zero.
func _wall_key(role: Vector2i) -> Variant:
	return Vector3i(role.x, role.y, 0) if _j2_on_face else role


## LE PAN DONT LES DEUX FLANCS CONTINUENT -- calcule, jamais ecrit en dur : c'est le seul
## role sans aucun cote ouvert, donc le seul carre de roche sans trait.
func _solid_pan() -> int:
	for pan: int in range(Walls.PAN_COUNT):
		if Walls.pan_west(pan) == Walls.SIDE_CONTINUE \
				and Walls.pan_east(pan) == Walls.SIDE_CONTINUE:
			return pan
	return 0


## La meme tuile, sa matiere sans son trait.
func _muted(tile: Image) -> Image:
	var out: Image = tile.duplicate() as Image
	for y: int in range(RES):
		for x: int in range(RES):
			if out.get_pixel(x, y).is_equal_approx(OUTLINE):
				out.set_pixel(x, y, ROCK)
	return out


func _wall_tiles(roles: Dictionary, freedom: int) -> Dictionary:
	var tiles: Dictionary = {}
	for key: Variant in roles.keys():
		var give: int = 0
		var role: Vector2i = Vector2i.ZERO
		if _j2_on_face:
			var wide: Vector3i = key as Vector3i
			role = Vector2i(wide.x, wide.y)
			give = wide.z
		else:
			role = key as Vector2i
		# ⚠ ET LE BAS DU PIED RESTE, APRES L'AVOIR RETIRE ET MESURE. Le raisonnement etait
		# symetrique de celui de la levre : un pied ATTERRIT toujours, la case d'atterrissage a
		# forcement son nord vide, donc le bas du pied et ce bord nord sont la meme frontiere
		# et la surface pourrait la porter seule. Essaye : 12 doublements de moins, mais 128
		# EXTREMITES DE PLUS -- le bas du pied est ce qui referme le contour de la falaise a sa
		# base, et sans lui les deux flancs s'arretent dans le vide.
		var open: Array[bool] = [role.y == Walls.ROW_CROWN,
				Walls.pan_east(role.x) == Walls.SIDE_STOP and (give & 2) == 0,
				role.y == Walls.ROW_FOOT and (give & 4) == 0,
				Walls.pan_west(role.x) == Walls.SIDE_STOP and (give & 1) == 0]
		# ESSAI : les bords d'une robe AU RAS de sa case.
		var tile: Image = _shape(open, freedom, ROCK, -1, 0, false, true)
		# L'ERGOT DE ROBE : le long du bord HAUT, depuis le coin du cote concerne, jusqu'a la
		# profondeur ou la case du dessus a laisse son trait.
		tiles[key] = tile
	return tiles


## LA FABRIQUE : la matiere que les quatre profils laissent, puis son bord.
##
## ⚠ LE TRAIT SE DEDUIT DE LA MATIERE, IL NE SE TRACE PAS A PART. Trace a part, il faut le
## decouper a la main partout ou deux cotes se rencontrent -- et c'est exactement la qu'il
## depassait, en ergot, a chaque coin saillant. Deduit, il epouse la matiere par construction.
## Tout ce qu'il faut savoir en plus est LOCAL : au-dela d'un cote ouvert il n'y a rien, au-dela
## d'un cote ferme la matiere continue chez la voisine.
## ⚠ ET LE BORD LATERAL NE SE PINCE PAS AU SUD, ESSAYE ET MESURE. L'idee : a L2 le sud d'une
## surface est toujours une LEVRE, et son bord lateral meurt a son bas faute de retrouver la
## crete du chapiteau ; en le ramenant au ras a son dernier pixel il toucherait au moins le coin
## de la case. Resultat : 222 extremites -> 848, et 61 paves. La loi de la traversee ne se plie
## pas -- un bord lateral doit franchir la frontiere horizontale a la profondeur COMMUNE, et le
## pincer d'un cote le brouille avec la case du dessus comme avec celle du dessous.
## ⚠ ET LE NORD D'UNE SURFACE NE SE MET PAS AU RAS, ESSAYE ET MESURE : 43 -> 65 extremites, et
## 94 paves la ou il n'y en avait aucun. Le raisonnement etait celui de la crete -- mon sol
## occupe ma case entiere, le sol plus bas occupe la sienne, la frontiere est le bord -- et il
## est FAUX ici. La difference : sous une crete il y a une FACE, qui occupe sa case et dont le
## haut EST le bord ; au nord il n'y a qu'un sol plus bas, dont le bord a lui est libre, et
## mettre le mien au ras l'empeche de le retrouver.
##
## Le parametre reste, inutilise, comme trace de la mesure.
## La profondeur d'un bord LATERAL, qui tombe a zero a son premier pixel quand la case du
## dessus s'est tue de ce cote : la frontiere y est portee par le flanc d'une robe, une case
## plus haut et une colonne plus loin, et il faut aller le toucher au coin.
func _side_depth(side: int, along: int, freedom: int, quiet: int) -> int:
	if along == 0:
		if side == 1 and (quiet & ABOVE_QUIET_EAST) != 0:
			return 0
		if side == 3 and (quiet & ABOVE_QUIET_WEST) != 0:
			return 0
	return _depth(side, along, freedom)


## LE PINCEMENT AUX DEUX TRAVERSEES : la loi du moindre ras.
##
## ⚠ ON NE MET AU RAS QUE CE QU'ON NE PEUT PAS LAISSER LIBRE. Le theoreme n'oblige pas une face
## a etre plate : deux lignes perpendiculaires qui vivent dans des tuiles DIFFERENTES ne peuvent
## se rejoindre qu'a leur frontiere commune, donc l'une doit toucher le bord AU POINT ou l'autre
## le traverse -- et rien de plus.
##
## Un bord de face touche donc le bord de sa case aux DEUX traversees canoniques de la famille
## perpendiculaire, et serpente entre les deux. Les traversees sont globales, donc connues de
## toutes les tuiles sans rien savoir du voisinage.
##
## Premiere formulation, trop forte : « les bords d'une face sont les bords de sa case ». Elle
## fermait bien (222 -> 43) mais confisquait toute la liberte du dessin de falaise.
func _wall_depth(side: int, along: int, freedom: int) -> int:
	if freedom == 0:
		return 0
	var first: int = 0
	var last: int = 0
	if side == 0 or side == 2:
		first = _depth(3, 0, freedom)
		last = RES - 1 - _depth(1, 0, freedom)
	else:
		first = _depth(0, 0, freedom)
		last = RES - 1 - _depth(2, 0, freedom)
	# ⚠ ET LE PINCEMENT SE FAIT A ZERO, ESSAYE AUTREMENT ET MESURE. Pincer a la profondeur
	# canonique -- pour que la face retrouve la surface -- fait sauter le contour a 186
	# extremites : la face y perd le contact avec les perpendiculaires DE SA PROPRE FAMILLE,
	# qui se rejoignent au coin de la case. Chaque famille a sa traversee ; c'est LEUR
	# rencontre qui doit se regler, pas l'une des deux qui doit ceder.
	if along <= first or along >= last or last <= first:
		return 0
	var seed: int = absi((side + 1) * 19349663)
	var reach: float = float(1 + seed % 3)
	var t: float = float(along - first) / float(last - first)
	return int(round(reach * sin(PI * t)))


func _shape(open: Array[bool], freedom: int, body: Color, index: int,
		quiet: int = 0, flat_north: bool = false, wall: bool = false) -> Image:
	var tile: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	var solid: Array[PackedByteArray] = []
	for y: int in range(RES):
		var line: PackedByteArray = PackedByteArray()
		line.resize(RES)
		for x: int in range(RES):
			var inside: bool = true
			if open[0] and y < (_wall_depth(0, x, freedom) if wall else (0 if flat_north else _depth(0, x, freedom))):
				inside = false
			if open[1] and x > RES - 1 - (_wall_depth(1, y, freedom) if wall else _side_depth(1, y, freedom, quiet)):
				inside = false
			if open[2] and y > RES - 1 - (_wall_depth(2, x, freedom) if wall else _depth(2, x, freedom)):
				inside = false
			if open[3] and x < (_wall_depth(3, y, freedom) if wall else _side_depth(3, y, freedom, quiet)):
				inside = false
			line[x] = 1 if inside else 0
		solid.append(line)

	# ⚠ ET LA MATIERE N'A PAS D'AIGUILLE. La ou deux courbes libres se rencontrent -- un coin
	# saillant dont les deux cotes serpentent -- il reste parfois une pointe d'un seul pixel,
	# accrochee par un coin ; son trait n'a alors qu'UN voisin, donc c'est une extremite. C'est
	# la regle d'epaisseur d'un cran plus bas. La tuile se relit elle-meme et la retire.
	var needled: bool = true
	while needled:
		needled = false
		for y: int in range(RES):
			for x: int in range(RES):
				if solid[y][x] == 0:
					continue
				var kin: int = 0
				for side: int in range(4):
					var near: Vector2i = Vector2i(x, y) + STEPS[side]
					if near.x < 0 or near.y < 0 or near.x >= RES or near.y >= RES:
						if not open[side]:
							kin += 1
						continue
					if solid[near.y][near.x] != 0:
						kin += 1
				if kin >= 2:
					continue
				var line2: PackedByteArray = solid[y]
				line2[x] = 0
				solid[y] = line2
				needled = true

	for y: int in range(RES):
		for x: int in range(RES):
			if solid[y][x] == 0:
				continue
			var edge: bool = false
			for side: int in range(4):
				var probe: Vector2i = Vector2i(x, y) + STEPS[side]
				if probe.x < 0 or probe.y < 0 or probe.x >= RES or probe.y >= RES:
					if open[side]:
						edge = true
					continue
				if solid[probe.y][probe.x] == 0:
					edge = true
			tile.set_pixel(x, y, OUTLINE if edge else body)
	if freedom > 0 and index >= 0:
		_reentrant(tile, index, freedom, quiet)
	return tile


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
func _reentrant(tile: Image, index: int, freedom: int, quiet: int = 0) -> void:
	for corner: int in range(4):
		var a: int = corner                 # N, E, S, O
		var b: int = (corner + 3) % 4       # le cote precedent : NO, NE, SE, SO
		if (index & CARDINALS[a]) == 0 or (index & CARDINALS[b]) == 0:
			continue
		if (index & DIAGONALS[corner]) != 0:
			continue
		if (quiet & (4 << corner)) == 0:
			_stub(tile, a, b, _depth(b, 0, freedom))
		if (quiet & (64 << corner)) == 0:
			_stub(tile, b, a, _depth(a, 0, freedom))


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
func _depth(side: int, along: int, freedom: int) -> int:
	if freedom == 0:
		return 0
	# ⚠ ET LA TRAVERSEE VAUT AU MOINS DEUX. L'ergot de coin rentrant se pose au RAS du bord --
	# il marque une marche sur un cote dont le cardinal est plein, il n'a nulle part ailleurs ou
	# aller. Si un bord traverse a la profondeur UN, les deux traits sont voisins d'un pixel et
	# forment un pave : deux terrasses collees, l'une par son ergot, l'autre par son bord.
	# Invisible a L0, ou les deux ne se rencontrent jamais dans la meme case ; flagrant des que
	# les etages s'empilent -- 5 paves a L1/F1, 12 a L1/F2.
	# ⚠ ET LA TRAVERSEE VAUT AU MOINS DEUX, essaye a zero et mesure. Au ras, la surface
	# retrouverait la face -- qui pince a zero -- mais elle perd ses propres ergots, poses au
	# bord : 57 paves a L2/F1. Chaque famille garde donc sa traversee.
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
		tiles: Dictionary, roles: Dictionary, role_tiles: Dictionary,
		under_by_level: Array[Dictionary], backing_tiles: Dictionary) -> Image:
	var canvas: Image = Image.create_empty(HeightMask.width(world) * RES,
			HeightMask.height(world) * RES, false, Image.FORMAT_RGBA8)
	for storey: int in range(storeys.size()):
		# ⚠ LA POSE ARRIERE PASSE JUSTE AVANT LA SURFACE DE SON ETAGE D'ATTERRISSAGE. Sous
		# celle-ci, donc invisible partout ou la surface est opaque -- et visible par ses
		# coins decoupes, ce qui est exactement l'endroit ou elle manquait.
		var backing: Dictionary = under_by_level[storey]
		for cell: Vector2i in backing.keys():
			canvas.blend_rect(backing_tiles[backing[cell]] as Image, Rect2i(0, 0, RES, RES),
					cell * RES)
		var map: Dictionary = storeys[storey]
		for cell: Vector2i in map.keys():
			var tile: Image = tiles[int(map[cell])]
			canvas.blend_rect(tile, Rect2i(0, 0, RES, RES), cell * RES)
	for cell: Vector2i in roles.keys():
		var rock: Image = role_tiles[roles[cell]] as Image
		canvas.blend_rect(rock, Rect2i(0, 0, RES, RES), cell * RES)
	return canvas


# ------------------------------------------------------------------ LES CINQ INVARIANTS

func _measure(image: Image, world: PackedStringArray, indices: Dictionary, tiles: Dictionary,
		freedom: int, roles: Dictionary, under: Dictionary = {}, role_tiles: Dictionary = {},
		bare: Image = null) -> Dictionary:
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
	var spread: Dictionary = {}
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
			var cell: Vector2i = Vector2i(x / RES, y / RES)
			var owner: int = int(indices.get(cell, -1))
			if ends.size() < 14:
				ends.append("%d,%d de la case %d,%d (tuile %d)"
						% [x % RES, y % RES, cell.x, cell.y, owner])
			# LA DISTRIBUTION. Trois hypotheses raisonnees sur ces extremites, trois fois
			# faux : on arrete de deviner et on compte. Chaque extremite se range par le
			# BORD ou elle se trouve, par ce que porte SA case, et par ce que porte la case
			# de l'autre cote de ce bord.
			var at_x: int = x % RES
			var at_y: int = y % RES
			var side: int = -1
			if at_y == 0:
				side = 0
			elif at_x == RES - 1:
				side = 1
			elif at_y == RES - 1:
				side = 2
			elif at_x == 0:
				side = 3
			var mine_kind: String = "robe" if roles.has(cell) else "surface"
			var label: String = ""
			if side < 0:
				label = "%s, en plein milieu" % mine_kind
			else:
				var probe: Vector2i = cell + STEPS[side]
				var kind: String = "vide"
				if roles.has(probe):
					kind = "robe"
				elif indices.has(probe):
					kind = "surface"
				label = "%s, bord %s, en face : %s" % [mine_kind, SIDE_NAMES[side], kind]
			spread[label] = int(spread.get(label, 0)) + 1

	# I2 EPAISSEUR. Un trait d'un pixel ne peut pas remplir un pave 2x2. Des qu'il y en a un,
	# deux traits se sont colles ou un trait a double.
	# ⚠ C'EST LUI QUI ATTRAPE LES LENTILLES, ET PAS I1 : deux traits qui se touchent forment
	# UN SEUL morceau, donc la fermeture passe au vert pendant que l'oeil voit un renflement.
	var thick: int = 0
	var thick_where: Array[String] = []
	# ⚠ ET ON DIT SOUS QUOI, comme I1 dit ou. Trois hypotheses raisonnees sur les extremites,
	# trois fois faux : la lecon vaut pour l'epaisseur. Chaque pave se range par ce que porte
	# sa case -- une surface, une robe -- et par l'espece de pose arriere posee dessous.
	var thick_spread: Dictionary = {}
	for y: int in range(height - 1):
		for x: int in range(width - 1):
			if not (_is_stroke(image, x, y) and _is_stroke(image, x + 1, y)
					and _is_stroke(image, x, y + 1) and _is_stroke(image, x + 1, y + 1)):
				continue
			thick += 1
			var at: Vector2i = Vector2i(x / RES, y / RES)
			if thick_where.size() < 10:
				thick_where.append("%d,%d de la case %d,%d" % [x % RES, y % RES, at.x, at.y])
			var mine: String = "robe" if roles.has(at) else "surface"
			var below: String = "rien dessous"
			if under.has(at):
				var role: Vector2i = under[at]
				if role.y == Walls.ROW_FOOT:
					below = "pied repose"
				elif role.y == Walls.ROW_CROWN:
					below = "chapiteau repose"
				else:
					below = "corps repose"
			var label: String = "%s, %s" % [mine, below]
			thick_spread[label] = int(thick_spread.get(label, 0)) + 1

	# I3 UNICITE. Chaque frontiere du monde est tracee par EXACTEMENT une tuile.
	var claims: Dictionary = _claims(image, world, indices, roles)
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
			# ⚠ ET ON NE PROFILE PAS UN COTE QUE LE BORD VIENT DE FAIRE TAIRE. La sonde y
			# rend « rien », et « rien » differe d'un profil trace : I5 comptait alors des
			# profils fantomes et declarait fausse une liberte parfaitement tenue.
			var bit: int = 0
			if side == 0:
				bit = NORTH_QUIET
			elif side == 1:
				bit = 1
			elif side == 3:
				bit = 2
			var quiet: bool = bit != 0 and ((int(key) >> 8) & bit) != 0
			if side == 2 or quiet or (int(key) & CARDINALS[side]) != 0:
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

	if thick > 0:
		var kinds3: Array[String] = []
		for key: Variant in thick_spread.keys():
			kinds3.append(str(key))
		kinds3.sort_custom(func(a: String, b: String) -> bool:
				return int(thick_spread[a]) > int(thick_spread[b]))
		print("  -- ou sont les %d paves --" % thick)
		for label: String in kinds3:
			print("     %4d  %s" % [int(thick_spread[label]), label])
	if end_count > 0:
		var labels: Array[String] = []
		for key: Variant in spread.keys():
			labels.append(str(key))
		labels.sort_custom(func(a: String, b: String) -> bool:
				return int(spread[a]) > int(spread[b]))
		print("  -- ou sont les %d extremites --" % end_count)
		for label: String in labels:
			print("     %4d  %s" % [int(spread[label]), label])
	# I6 VERITE. Ce qui se voit A TRAVERS UNE TRANSPARENCE est ce que le modele nomme.
	#
	# ⚠ C'EST LA MESURE QUI MANQUAIT, ET SON ABSENCE A LAISSE L3 SANS ARBITRE. Les cinq autres
	# ne distinguent pas `mute` de `full` : ils sont identiques sur les cinq, et pourtant les
	# deux images different a l'oeil. Ce qu'une pose arriere garantit n'est pas « de la matiere
	# quelque part » -- I4 le dit deja -- mais « LA matiere que le modele nomme, a cet
	# endroit-la ». Sans elle, un raccourci qui affirme de la roche jusqu'au bord de la case
	# passait au vert : le banc ne pouvait pas trancher, et le dossier le disait.
	#
	# ⚠ ET ON LIT LA CONTRIBUTION DE LA POSE, JAMAIS LA COULEUR DU PIXEL. Assembler une seconde
	# fois SANS les poses arriere donne un temoin : la pose a contribue exactement la ou les deux
	# images different. Classer par la couleur aurait demande de decider si un pixel de trait
	# vient de la roche reposee ou du sol d'en dessous -- deviner, la ou on peut mesurer.
	#
	# ⚠ ET LA FENETRE SE DIT, MEME QUAND LE COMPTE EST A ZERO. Une pose arriere ne se voit qu'a
	# travers une transparence : a F0 il n'y en a aucune, donc zero ne prouve rien. La lecon est
	# deja payee au dossier -- deux bandes vides sont trivialement egales.
	var invented: int = 0
	var lost: int = 0
	var window: int = 0
	var invented_where: Array[String] = []
	var invented_spread: Dictionary = {}
	if bare != null:
		for cell: Vector2i in under.keys():
			# Une case couverte par une robe VISIBLE ne montre rien de sa pose arriere : les robes
			# se posent en dernier, par-dessus tout.
			if roles.has(cell) or not indices.has(cell):
				continue
			var cover: Image = tiles[int(indices[cell])] as Image
			var named: Image = role_tiles[_wall_key(under[cell])] as Image
			for y: int in range(RES):
				for x: int in range(RES):
					if cover.get_pixel(x, y).a >= 0.5:
						continue
					window += 1
					var px: int = cell.x * RES + x
					var py: int = cell.y * RES + y
					var shown: bool = not image.get_pixel(px, py).is_equal_approx(
							bare.get_pixel(px, py))
					var truth: bool = named.get_pixel(x, y).a >= 0.5
					if shown == truth:
						continue
					if shown:
						invented += 1
						if invented_where.size() < 8:
							invented_where.append("%d,%d de la case %d,%d"
									% [x, y, cell.x, cell.y])
						# LA DISTRIBUTION, sur le modele de celle de I1 : on arrete de deviner et on
						# compte. Un pixel invente se range par la BANDE de la case ou il tombe -- le
						# cote dont il est le plus proche -- et par l'espece de la pose qui le porte.
						var reach: Array[int] = [y, RES - 1 - x, RES - 1 - y, x]
						var near: int = 0
						for side: int in range(1, 4):
							if reach[side] < reach[near]:
								near = side
						var row: int = (under[cell] as Vector2i).y
						var kind: String = "corps (ecretage)"
						if row == Walls.ROW_CROWN:
							kind = "chapiteau (sous sa levre)"
						elif row == Walls.ROW_FOOT:
							kind = "pied (atterrissage)"
						var label: String = "bande %s, sous un %s" % [SIDE_NAMES[near], kind]
						invented_spread[label] = int(invented_spread.get(label, 0)) + 1
					else:
						lost += 1

	if invented > 0:
		var spots: Array[String] = []
		spots.assign(invented_spread.keys())
		spots.sort_custom(func(a: String, b: String) -> bool:
				return int(invented_spread[a]) > int(invented_spread[b]))
		print("  -- ou est la matiere inventee (%d pixels sur %d de fenetre) --"
				% [invented, window])
		for label: String in spots:
			print("     %4d  %s" % [int(invented_spread[label]), label])

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
		"I6": {"nom": "verite", "ok": invented == 0 and lost == 0,
				"dit": "%d matiere(s) inventee(s), %d perdue(s), a travers %d pixel(s) de transparence %s"
				% [invented, lost, window, str(invented_where)]},
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
func _claims(image: Image, world: PackedStringArray, indices: Dictionary,
		roles: Dictionary) -> Dictionary:
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
			# ⚠ UNE CASE DE FALAISE NE SE JUGE PAS PAR SON ETAGE. Sur la carte, une case de
			# robe est une case du SOL D'EN BAS : lui demander son niveau ne dit rien de la
			# face qui la couvre. Tant que le banc ne sait pas nommer les frontieres d'une
			# face, on n'y juge que le DOUBLEMENT -- deux traits pour un meme bord -- qui, lui,
			# se lit sur l'image sans rien savoir du modele.
			if roles.has(cell) or roles.has(probe):
				if mine + theirs > 1:
					doubles += 1
					if witness.size() < 14:
						witness.append("%d,%d double (falaise)" % [cell.x, cell.y])
				continue
			if here == beyond:
				# Une arete INTERIEURE ne se voit qu'une fois : depuis l'est et le sud.
				if side != 1 and side != 2:
					continue
				if mine + theirs > 0:
					parasites += 1
					if witness.size() < 14:
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
				if witness.size() < 14:
					witness.append("%d,%d muette" % [cell.x, cell.y])
			elif claimants > 1:
				doubles += 1
				if witness.size() < 14:
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
