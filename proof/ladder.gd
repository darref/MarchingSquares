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
## ⚠ ET LE REJEU SE DECOUPE : `LADDER_SHARD=i/n` n'en garde qu'un couple sur n. Trois
## processus en parallele rendent le verdict en un tiers du temps, et le verdict global est
## l'ET des trois -- chacun imprime le sien.
##
##     for i in 0 1 2; do LADDER_SHARD=$i/3 godot --headless --path . \
##             --script res://proof/ladder.gd > /tmp/rejeu$i.txt 2>&1 & done; wait
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
const CornerIndex := preload("res://core/corner_index.gd")
## ⚠ LE PINCEAU EST SORTI DU BANC, ET LE BANC LE LIT. Une seule source pour le dessin ;
## le rejeu des vingt-six couples prouve que le deplacement n'a pas change un pixel.
const Contour := preload("res://render/contour_tiles.gd")
## ⚠ ET LES BITS VIENNENT DE `core/`, PAS DU RENDU. Ce qu'une tuile doit SAVOIR est du
## modele ; ce qu'elle DESSINE est du rendu. Le banc lit les deux, chacun chez lui.
const Brink := preload("res://core/brink.gd")
const BorderRules := preload("res://core/border_rules.gd")
## ⚠ ET L'ASSEMBLAGE AUSSI EST CHEZ LE PRODUIT. Le banc n'a plus que ce qui lui est
## propre : les mondes, les six invariants, les battues et la forme fermee.
const Compose := preload("res://render/contour.gd")
const RES := Contour.RES
const GRASS := Contour.GRASS
const OUTLINE := Contour.OUTLINE
const ROCK := Contour.ROCK
const CARDINALS := Contour.CARDINALS
const DIAGONALS := Contour.DIAGONALS
const STEPS := Contour.STEPS
const NORTH_QUIET := Contour.NORTH_QUIET
const ABOVE_QUIET_EAST := Contour.ABOVE_QUIET_EAST
const ABOVE_QUIET_WEST := Contour.ABOVE_QUIET_WEST
const NORTH_FLUSH_EAST := Contour.NORTH_FLUSH_EAST
const NORTH_FLUSH_WEST := Contour.NORTH_FLUSH_WEST
const BELOW_QUIET_EAST := Contour.BELOW_QUIET_EAST
const BELOW_QUIET_WEST := Contour.BELOW_QUIET_WEST
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










## La case du dessus laisse-t-elle un trait de ce cote-la ? Une ROBE le laisse si son flanc
## s'ARRETE ; une SURFACE le laisse si son cardinal est ouvert et que le bord ne l'a pas fait
## taire.
static func _above_draws(cell: Vector2i, side: int, indices: Dictionary,
		roles: Dictionary, level: int) -> bool:
	if roles.has(cell):
		var role: Vector2i = roles[cell]
		var flank: int = Walls.pan_east(role.x) if side == 1 else Walls.pan_west(role.x)
		return flank == Walls.SIDE_STOP
	return Brink.draws_side(cell, side, indices, roles, level)


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
## (declaree dans `render/contour_tiles.gd` -- le banc ne fait que la poser)

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

## Ou sortir la table brute (cle, silhouette, les quatre especes) -- vide, on n'ecrit rien.
## LA CLAUSE B, CHIFFREE : quels bits retirer, pour voir ce que chacun paie.
##
## ⚠ « UN BIT NE SE PAIE QUE S'IL FERME UNE JONCTION ENTIERE » -- la clause est au plan depuis
## longtemps et n'a jamais ete appliquee, faute d'un tarif. Le voici : on retire un bit, on
## regarde ce qui s'ouvre (I1, I2, I3) et ce qu'on economise (le vocabulaire). Un bit qui ne
## ferme rien est une rustine ; un bit qui ferme cher est une regle.
##
##     LADDER_DROP=bord,nq,ergot,above,flush,below   (au choix, separes par des virgules)
static var _drop: int = 0

## Le niveau du couple en cours -- le dessin en a besoin pour savoir si le sud se trace.
## (declaree dans `render/contour_tiles.gd` -- le banc ne fait que la poser)

## L'ERGOT PAR LA DIAGONALE : un bit par coin, et c'est un FAIT du monde -- « une face couvre
## ma diagonale » -- au lieu de deux DECISIONS de voisines. C'est la regle ; `LADDER_ERGOT=voisine`
## rejoue l'ancienne.
## (declaree dans `render/contour_tiles.gd` -- le banc ne fait que la poser)

static var _dump: String = ""
static var _dumped: PackedStringArray = PackedStringArray()
## Le contexte de chaque case, garde pour pouvoir sortir celui de ses VOISINES : c'est ce qui
## fait la difference entre un rayon 1 et un rayon 2.
static var _local: Dictionary = {}

## L'ENUMERATION EXHAUSTIVE : on se tait, sinon deux cent mille reliefs font un million de
## lignes. Seul le releve de saturation parle.
static var _quiet: bool = false
## Le relief injecte par l'enumeration -- `_world()` le rend tel quel quand il n'est pas vide.
static var _injected: PackedStringArray = PackedStringArray()

## Le monde a batir : vide pour la planche de preuve, « guide » pour le guide livre.
static var _world_name: String = ""

## Dire, pour chaque extremite, ce que la case et ses quatre voisines tracent (`LADDER_WHY=1`).
static var _why: bool = false

## Les etages enterres se posent-ils PLEINS ? (`LADDER_BURIED=plein`)
static var _buried_full: bool = false

## La pile des silhouettes, gardee pour que le rapport « pourquoi » puisse la lire.
static var _storeys: Array[Dictionary] = []

## LA BATTUE DE VOCABULAIRE : on ne veut que la LISTE des tuiles, pas leur dessin.
static var _vocab_only: bool = false
static var _vocab_seen: Dictionary = {}
static var _vocab_roles: Dictionary = {}
## ⚠ ET LE TEMOIN DE CHAQUE TUILE, PAS SEULEMENT SA PRESENCE. Un guide qui EXERCE le
## vocabulaire se batit de temoins -- « l'ilot est calcule, jamais dessine » -- et pour ca il
## faut savoir QUEL relief a produit chaque tuile, pas seulement qu'elle existe.
static var _witness_of: Dictionary = {}
static var _current: int = -1

## LA CLAUSE DE GRAMMAIRE A L'ESSAI (`LADDER_CLAUSE=`), et il y en a trois candidates :
##   `paroi3`  aucune paroi de moins de trois colonnes ;
##   `etages`  deux faces d'etages differents ne se touchent pas lateralement ;
##   `levre3`  une levre ne se decale que par blocs de trois colonnes.
static var _clause: String = ""

## L5 : QUI CEDE A LA JONCTION LATERALE (`LADDER_ASTRIDE=`) -- `surface` (defaut) ou `face`.
## (declaree dans `render/contour_tiles.gd` -- le banc ne fait que la poser)
## (declaree dans `render/contour_tiles.gd` -- le banc ne fait que la poser)
## (declaree dans `render/contour_tiles.gd` -- le banc ne fait que la poser)
static var _idle_pairs: PackedStringArray = PackedStringArray()
static var _backing_traces: bool = false

const MaskIO := preload("res://core/mask_io.gd")
const Modes := preload("res://core/modes.gd")

## La planche relue une fois, gardee pour le fond de contexte des images.
static var _board: PackedStringArray = PackedStringArray()

## Ce qu'il faut ajouter sous la planche pour qu'une chute dans le vide y tienne entiere.
const MARGIN: int = 6
## La tuile pleine : huit voisins, aucun bord. C'est elle qu'on pose sous un sommet.
const SOLID: int = 255


const BACKDROP: Color = Color("#23262b")
const CONTEXT: Color = Color("#3f4a38")

## Les couples deja gagnes, dans l'ordre. On les rejoue tous a chaque execution.
## ⚠ ET LE DERNIER COUPLE SE REJOUE SUR UN SECOND MONDE. La planche de preuve est batie pour
## exercer le VOCABULAIRE -- elle porte les 27 silhouettes -- mais pas les RENCONTRES : le guide
## en portait treize que la planche ne met jamais cote a cote, et elles etaient rouges pendant
## que le banc etait vert. Un banc qui ne connait qu'un monde ne prouve que ce monde.
## On ne rejoue que le couple le plus exigeant : vingt secondes de plus, et le trou est ferme.
const ACQUIS: Array[String] = ["L0/F0", "L0/F1", "L0/F2", "L1/F0", "L1/F1", "L1/F2",
		"L2/F0", "L2/F1", "L2/F2", "L3/F0", "L3/F1", "L3/F2", "L3/F2@guide",
		"L2/F2@battue1", "L2/F2@battue2", "L2/F2@battue3",
		"L3/F2@battue1", "L3/F2@battue2", "L3/F2@battue3",
		"L5/F0", "L5/F1", "L5/F2", "L5/F2@guide",
		"L5/F2@battue1", "L5/F2@battue2", "L5/F2@battue3"]

const SIDE_NAMES: Array[String] = ["nord", "est", "sud", "ouest"]



func _initialize() -> void:
	Brink.j2_on_face = OS.get_environment("LADDER_J2") == "face"
	_j2_none = OS.get_environment("LADDER_J2") == "none"
	# ⚠ ET LE DEFAUT NE SE FAIT PAS ECRASER PAR UNE VARIABLE ABSENTE : sans elle, on garde la
	# conception que la mesure a choisie.
	if not OS.get_environment("LADDER_BACKING").is_empty():
		_backing = OS.get_environment("LADDER_BACKING")
	_why = not OS.get_environment("LADDER_WHY").is_empty()
	_dump = OS.get_environment("LADDER_DUMP")
	# ⚠ LA DIAGONALE EST LA REGLE, ET L'ANCIENNE FORMULATION RESTE JOIGNABLE COMME TRACE :
	# un chiffre qu'on ne peut plus reproduire n'est plus un chiffre.
	Brink.ergot_diag = OS.get_environment("LADDER_ERGOT") != "voisine"
	for nom: String in OS.get_environment("LADDER_DROP").split(",", false):
		match nom.strip_edges():
			"bord": _drop |= 1 | 2
			"nq": _drop |= NORTH_QUIET
			"ergot": _drop |= 1020
			"above": _drop |= ABOVE_QUIET_EAST | ABOVE_QUIET_WEST
			"flush": _drop |= NORTH_FLUSH_EAST | NORTH_FLUSH_WEST
			"below": _drop |= BELOW_QUIET_EAST | BELOW_QUIET_WEST
			_: push_error("ladder: bit inconnu '%s'." % nom)
	_buried_full = OS.get_environment("LADDER_BURIED") == "plein"
	_clause = OS.get_environment("LADDER_CLAUSE")
	Contour.astride = OS.get_environment("LADDER_ASTRIDE")
	# ⚠ LE RENDEZ-VOUS SE DEBRANCHE, PARCE QU'UN CORRECTIF DONT ON NE SAIT PAS CE QU'IL COUTE
	# N'EST PAS MESURE. `none`, `orig`, `miroir` -- et `both` par defaut, ce que la mesure a
	# choisi. Sans ce robinet on ne peut pas dire, monde par monde, ce que le raccord FERME et
	# ce qu'il CASSE : sur la planche il ferme 43 extremites pour zero pave, ailleurs il faut
	# le savoir avant de l'accuser ou de le defendre.
	Contour.meet = OS.get_environment("LADDER_MEET")
	Contour.half_axis = OS.get_environment("LADDER_HALF") == "axe"
	Contour.wall_free = OS.get_environment("LADDER_WALLFREE")
	if not OS.get_environment("LADDER_CROSSING").is_empty():
		Contour.forced_crossing = int(OS.get_environment("LADDER_CROSSING"))
	if not OS.get_environment("LADDER_WALLCORNER").is_empty():
		BorderRules.CORNER = int(OS.get_environment("LADDER_WALLCORNER"))
	# LE TRANSFERT DE LA CRETE : la surface de levre prend le haut de sa face, le
	# chapiteau se tait. Voir `Brink.crest_on_surface`.
	# ⚠ LE TRANSFERT EST LE MODELE, DONC C'EST LUI LE DEFAUT. Il a vecu derriere son
	# drapeau tant qu'il etait rouge -- « on ne met pas un modele rouge par defaut, meme
	# quand c'est lui la cible ». Il est vert sur les 26 couples : le drapeau change de
	# sens, et `LADDER_CREST=crete` rend l'ancien modele pour pouvoir les comparer.
	Brink.crest_on_surface = OS.get_environment("LADDER_CREST") != "crete"
	var asked: String = OS.get_environment("LADDER_RIDGE")
	if not asked.is_empty():
		Contour.wall_ridge = "" if asked == "aucune" else asked
	if not OS.get_environment("LADDER_WALLREACH").is_empty():
		Contour.wall_reach = int(OS.get_environment("LADDER_WALLREACH"))
	_backing_traces = OS.get_environment("LADDER_UNDERFOOT") == "trace"
	if Contour.meet.is_empty():
		Contour.meet = "both"
	if _j2_none:
		Brink.j2_on_face = true
	# ⚠ LA BATTUE DE VOCABULAIRE : « combien de tuiles le modele peut-il produire ? »
	#
	# Sans elle on ne sait pas ce qui manque au guide, seulement qu'il manque quelque chose --
	# l'union de cinq mondes n'est pas une forme fermee. Elle ne la donne pas non plus : UNE
	# BATTUE QUI NE RENCONTRE PAS UNE TUILE PROUVE QU'ELLE EST RARE, JAMAIS QU'ELLE EST
	# IMPOSSIBLE. Ce qu'elle donne est une BORNE BASSE qui se stabilise, et la courbe de sa
	# croissance -- laquelle dit si l'on a fini de chercher ou pas.
	# ⚠ ET LES RELIEFS PEUVENT VENIR D'UN FICHIER, parce que l'enumeration par BLOCS ALIGNES
	# etait une sous-famille : 19 tuiles des mondes livres n'en sortaient pas. `tools/
	# thick_reliefs.py` engendre TOUT relief epais d'une fenetre -- donc aussi ce qu'un tampon
	# DECALE produit -- et le banc n'a plus qu'a les poser dans leur marge.
	# ⚠ LA FORME FERMEE, PEINTE. `tools/closed_form_now.py --liste` enumere les cles que le
	# modele PEUT exiger ; ce robinet les PEINT et compte les DESSINS distincts. Les deux
	# nombres ne disent pas la meme chose : la forme compte ce que la regle sait distinguer,
	# le dessin compte ce que la planche doit porter. Une cle de plus qui ne change pas un
	# pixel est une case de planche pour rien.
	#
	# ⚠ ET ON REUTILISE LES DEUX SOURCES, ON N'EN ECRIT PAS UNE TROISIEME : l'enumeration
	# vient de l'outil, le pinceau est celui du banc. Retranscrire l'une ou l'autre ici serait
	# la faute que le dossier repete a chaque page.
	var forme: String = OS.get_environment("LADDER_FORM")
	if not forme.is_empty():
		_closed_form(forme)
		quit(0)
		return
	var fichier: String = OS.get_environment("LADDER_RELIEFS")
	if not fichier.is_empty():
		_from_file(fichier)
		quit(0)
		return
	var full: int = int(OS.get_environment("LADDER_EXHAUSTIVE"))
	if full > 0:
		_enumerate(full)
		quit(0)
		return
	var sweep: int = int(OS.get_environment("LADDER_SWEEP"))
	if sweep > 0:
		_vocab_only = true
		var mark: int = 0
		for run: int in range(1, sweep + 1):
			_run("L3/F2@battue%d" % run)
			if run % 10 == 0 or run == sweep:
				print("  %4d mondes : %d tuiles de surface, %d roles   (+%d depuis le releve)"
						% [run, _vocab_seen.size(), _vocab_roles.size(),
						_vocab_seen.size() - mark])
				mark = _vocab_seen.size()
		var listing: Array[int] = []
		listing.assign(_vocab_seen.keys())
		listing.sort()
		print("VOCAB %s" % str(listing))
		var shapes: Dictionary = {}
		for key: int in listing:
			shapes[key & 0xff] = true
		print("silhouettes rencontrees : %d" % shapes.size())
		# ⚠ ET ON DIT QUELS ROLES, PAS COMBIEN. « 20 -> 15 » ne dit pas si la clause supprime
		# une famille entiere ou cinq cas epars -- et c'est toute la difference entre une
		# regle et un hasard de battue.
		var said3: PackedStringArray = PackedStringArray()
		for role: Vector2i in _vocab_roles.keys():
			said3.append("(%s, rangee %d)" % [Walls.pan_name(role.x), role.y])
		said3.sort()
		print("ROLES %s" % ", ".join(said3))
		quit(0)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var couples: Array[String] = []
	if args.size() >= 2:
		couples.append("%s/%s" % [args[0].to_upper(), args[1].to_upper()])
	elif args.size() == 1:
		couples.append(args[0].to_upper())
	else:
		couples.assign(ACQUIS)
		# ⚠ LE REJEU SE DECOUPE, PARCE QU'UN BANC QU'ON N'OSE PLUS LANCER NE PROUVE PLUS RIEN.
		# `LADDER_SHARD=i/n` ne garde qu'un couple sur n : trois processus en parallele font le
		# rejeu en un tiers du temps, et le verdict est l'ET des trois. Meme lecon que la suite
		# de tests passee de cinq minutes a une -- ce qui coute du temps finit par couter des
		# mesures qu'on ne fait pas.
		var shard: PackedStringArray = OS.get_environment("LADDER_SHARD").split("/")
		if shard.size() == 2:
			var mine: int = int(shard[0])
			var total: int = maxi(1, int(shard[1]))
			var kept: Array[String] = []
			for at: int in range(couples.size()):
				if at % total == mine % total:
					kept.append(couples[at])
			couples = kept
			print("REJEU %d/%d : %d couple(s)" % [mine, total, couples.size()])
	var failed: int = 0
	for couple: String in couples:
		if not _run(couple):
			failed += 1
	print("")
	print("VERDICT : %s" % ("l echelle tient." if failed == 0
			else "%d couple(s) en echec." % failed))
	quit(1 if failed > 0 else 0)


## LA FORME FERMEE, PEINTE : combien de DESSINS pour combien de cles ?
##
##     tools/closed_form_now.py --liste > /tmp/forme.txt
##     LADDER_FORM=/tmp/forme.txt godot --headless --path . \
##             --script res://proof/ladder.gd -- L3 F1
##
## ⚠ LES GRAINES DE RACCORD VALENT ZERO ICI, ET IL FAUT LE DIRE. Les classes de L4 sont une
## propriete du MONDE -- l'union-find se calcule des adjacences observees -- alors que la forme
## fermee est une propriete du MODELE. On peint donc a graine nulle : deux cles qui rendent la
## meme image ici peuvent differer dans un monde qui les met dans deux classes. Le compte est
## donc le vocabulaire de FORMES, pas le nombre de cases d'une planche donnee.
## L'ECHANGE : un silence devient la matiere qu'il fait taire.
##
##   bord est   -> le cardinal EST se remplit, plus NE si le nord est plein, SE si le sud l'est
##   bord ouest -> idem a l'ouest
##   nord muet  -> le cardinal NORD, plus NE si l'est est plein, NO si l'ouest l'est
##   ergot d'un coin -> la DIAGONALE de ce coin
##
## Les autres bits ne s'echangent pas : ils ne disent pas « la voisine trace », ils changent
## la PROFONDEUR du trait. Rien de plein ne les remplace.
static func _swap(key: int) -> int:
	var sil: int = key & 0xff
	var bits: int = key >> 8
	var fill: Array[int] = []
	if (bits & 1) != 0:
		fill.append(BlobIndex.E)
		bits &= ~1
	if (bits & 2) != 0:
		fill.append(BlobIndex.W)
		bits &= ~2
	if (bits & Brink.NORTH_QUIET) != 0:
		fill.append(BlobIndex.N)
		bits &= ~Brink.NORTH_QUIET
	for corner: int in range(4):
		if (bits & (4 << corner)) != 0:
			sil |= DIAGONALS[corner]
			bits &= ~(4 << corner)
	for card: int in fill:
		sil |= card
	# LES DIAGONALES QUE LES CARDINAUX NEUFS VIENNENT DE COMPLETER.
	for corner: int in range(4):
		var a: int = corner
		var b: int = (corner + 3) % 4
		if (sil & CARDINALS[a]) == 0 or (sil & CARDINALS[b]) == 0:
			continue
		if fill.has(CARDINALS[a]) or fill.has(CARDINALS[b]):
			sil |= DIAGONALS[corner]
	# ⚠ ET PAS LES DIAGONALES SUD, DES QU'IL Y A DES FACES. Une diagonale sud n'est enregistree
	# que si `S` est plein, or a partir de L2 le sud ne se trace jamais -- theoreme de la levre.
	# Elle ne peut donc rien changer au dessin, et la remplir fabrique une silhouette qui n'est
	# pas dans la forme. Mesure : c'est cet oubli, et lui seul, qui laissait huit cles de trop.
	if Contour.level >= 2:
		sil &= ~(BlobIndex.SE | BlobIndex.SW)
	return sil | (bits << 8)


func _closed_form(path: String) -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var level: int = int(String(args[0]).substr(1)) if args.size() > 0 else 3
	var freedom: int = int(String(args[1]).substr(1)) if args.size() > 1 else 1
	Contour.level = level
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ladder: liste de cles introuvable : %s" % path)
		return
	var vocab: Dictionary = {}
	for piece: String in text.strip_edges().split(",", false):
		vocab[int(piece.strip_edges())] = true
	var tiles: Dictionary = Compose.paint(vocab, freedom, level, {})
	var groups: Dictionary = {}
	for key: Variant in tiles.keys():
		var mark: String = (tiles[key] as Image).get_data().hex_encode()
		if not groups.has(mark):
			groups[mark] = []
		(groups[mark] as Array).append(int(key))
	print("=== LA FORME FERMEE, PEINTE A L%d/F%d ===" % [level, freedom])
	print("  %d cles enumerees  ->  %d DESSINS distincts" % [vocab.size(), groups.size()])
	# ⚠ LA CANONISATION : ON RETIRE D'UNE CLE TOUT BIT DONT LE RETRAIT NE CHANGE PAS UN PIXEL.
	#
	# Le detecteur de bits inertes ne compare que des paires DEJA ENUMEREES, et il ne conclut
	# que sur une paire qui ne differe QUE par un bit. Quand la forme ne contient pas la
	# variante -- parce qu'une precondition l'exclut -- la paire n'existe pas, et le bit passe
	# inapercu : c'est exactement le mur ou le critere 3 s'etait arrete, 82 cles pour 43
	# dessins et pas une paire a un bit.
	#
	# ⚠ ON PEINT DONC LA VARIANTE MEME SI ELLE N'EST PAS DANS LA FORME. La question n'est pas
	# « ce monde la produit-il ? » mais « ce bit change-t-il le dessin ? » -- et un bit qui n'en
	# change aucun n'a pas a figurer dans la cle, quelle que soit la raison de sa presence.
	#
	# ⚠ ET LE RETRAIT EST GLOUTON, DU BIT DE POIDS FAIBLE AU FORT. Deux bits peuvent etre
	# redondants ENSEMBLE sans l'etre separement ; l'ordre decide alors lequel des deux part.
	# Le compte, lui, ne depend pas de l'ordre : c'est le nombre de cles qui restent.
	var canon: Dictionary = {}
	var families: Dictionary = {}
	for key9: Variant in vocab.keys():
		var start: int = int(key9)
		var want: String = (tiles[start] as Image).get_data().hex_encode()
		var kept: int = start
		for bit9: int in range(24):
			var without: int = kept & ~(1 << bit9)
			if without == kept:
				continue
			var one: Dictionary = {}
			one[without] = true
			var made: Dictionary = Compose.paint(one, freedom, level, {})
			if (made[without] as Image).get_data().hex_encode() == want:
				kept = without
		canon[start] = kept
		if not families.has(kept):
			families[kept] = []
		(families[kept] as Array).append(start)
	print("  CANONISEES : %d cles distinctes  (%d retirees)"
			% [families.size(), vocab.size() - families.size()])
	# ⚠ LA SUBSTITUTION : TAIRE UN COTE, C'EST DESSINER COMME SI LA MATIERE Y ETAIT.
	#
	# Aucun bit ne se retire SEUL -- 0 sur 69 -- et pourtant quinze groupes se confondent. Le
	# motif se lit dans le premier : `s199 sans bit`, `s193 + bordE`, `s7 + bordW`,
	# `s71 + ergot0`, `s65 + bordE + ergot0`... Ce ne sont pas des bits inertes, c'est **la
	# meme tuile ecrite de sept facons**. Un silence dit « la voisine trace ce cote » ; du
	# point de vue du DESSIN, c'est exactement ce que dit un cardinal plein.
	#
	# La reduction n'est donc pas un retrait mais un ECHANGE : on remplit le cardinal que le
	# bit fait taire, et la diagonale des coins que ce cardinal vient de completer -- sans
	# quoi on ferait naitre un ergot que l'original n'avait pas.
	#
	# ⚠ ET ON NE REMPLIT PAS TOUTES LES DIAGONALES. Une silhouette nue dont un coin a ses deux
	# cardinaux pleins et sa diagonale vide porte un ERGOT, et c'est une tuile a part entiere.
	# Seules les diagonales des coins SILENCIEUX se remplissent.
	var swapped: Dictionary = {}
	var wrong: Array[String] = []
	for key10: Variant in vocab.keys():
		var from: int = int(key10)
		var into: int = _swap(from)
		swapped[into] = true
		var one2: Dictionary = {}
		one2[into] = true
		if (Compose.paint(one2, freedom, level, {})[into] as Image).get_data().hex_encode() \
				!= (tiles[from] as Image).get_data().hex_encode():
			if wrong.size() < 10:
				wrong.append("%d -> %d" % [from, into])
	print("  ECHANGEES : %d cles distinctes, %d qui ne rendent PAS le meme dessin  %s"
			% [swapped.size(), wrong.size(), str(wrong)])
	# ⚠ ET CE QUI SE CONFOND ENCORE APRES L'ECHANGE EST LE VRAI RESTE DU CRITERE 3. On les
	# nomme : c'est la seule facon de savoir si c'est une regle de plus ou une coincidence.
	var after: Dictionary = {}
	for kept3: Variant in swapped.keys():
		var one3: Dictionary = {}
		one3[int(kept3)] = true
		var mark5: String = (Compose.paint(one3, freedom, level,
				{})[int(kept3)] as Image).get_data().hex_encode()
		if not after.has(mark5):
			after[mark5] = []
		(after[mark5] as Array).append(int(kept3))
	var left: Array[String] = []
	for mark6: Variant in after.keys():
		var lot2: Array = after[mark6]
		if lot2.size() < 2:
			continue
		lot2.sort()
		var said4: PackedStringArray = PackedStringArray()
		for k4: int in lot2:
			said4.append("%d(s%d,b%d)" % [k4, k4 & 0xff, k4 >> 8])
		left.append("[%s]" % " ".join(said4))
	left.sort()
	print("  APRES L'ECHANGE : %d dessins pour %d cles, %d groupe(s) encore confondu(s)"
			% [after.size(), swapped.size(), left.size()])
	for at3: int in range(left.size()):
		print("     %s" % left[at3])
	if families.size() != groups.size():
		# ⚠ ET SI LES DEUX COMPTES DIFFERENT, LA REDONDANCE QUI RESTE N'EST PAS UN BIT : deux
		# cles canoniques qui peignent la MEME image ne different par aucun bit retirable une
		# a une. On les nomme, parce que c'est la qu'il faudra regarder.
		var by_mark: Dictionary = {}
		for kept2: Variant in families.keys():
			var mark3: String = (Compose.paint({int(kept2): true}, freedom, level,
					{})[int(kept2)] as Image).get_data().hex_encode()
			if not by_mark.has(mark3):
				by_mark[mark3] = []
			(by_mark[mark3] as Array).append(int(kept2))
		var stuck: Array[String] = []
		for mark4: Variant in by_mark.keys():
			var lot: Array = by_mark[mark4]
			if lot.size() < 2:
				continue
			lot.sort()
			var said3: PackedStringArray = PackedStringArray()
			for k3: int in lot:
				said3.append("%d(s%d,b%d)" % [k3, k3 & 0xff, k3 >> 8])
			stuck.append("[%s]" % " ".join(said3))
		stuck.sort()
		print("  IRREDUCTIBLES A DEUX : %d groupe(s) que le retrait d'un bit ne fusionne pas"
				% stuck.size())
		for at2: int in range(mini(10, stuck.size())):
			print("     %s" % stuck[at2])
	# ⚠ ET ON DIT QUELLES CLES SE CONFONDENT, pas seulement combien. Un compte range le
	# constat ; la liste designe le bit qui ne sert a rien.
	var fused: Array[String] = []
	var pairs: Dictionary = {}
	var shapes: Dictionary = {}
	for mark2: Variant in groups.keys():
		var group: Array = groups[mark2]
		if group.size() < 2:
			continue
		group.sort()
		var told: PackedStringArray = PackedStringArray()
		for key2: int in group:
			told.append(str(key2))
		fused.append("[%s]" % ",".join(told))
		for a: int in range(group.size()):
			for b: int in range(a + 1, group.size()):
				var diff: int = int(group[a]) ^ int(group[b])
				if diff != 0 and (diff & (diff - 1)) == 0:
					pairs[diff] = int(pairs.get(diff, 0)) + 1
		shapes[int(group[0]) & 0xff] = true
	print("  %d groupe(s) de cles confondues, sur %d silhouette(s)"
			% [fused.size(), shapes.size()])
	if not pairs.is_empty():
		var bits: Array[int] = []
		bits.assign(pairs.keys())
		bits.sort()
		var said: PackedStringArray = PackedStringArray()
		for bit: int in bits:
			said.append("%d x%d" % [bit, int(pairs[bit])])
		print("  bits qui ne distinguent RIEN : %s" % ", ".join(said))
	# ⚠ ET ON LES NOMME TOUS, un par ligne : c'est la LISTE qu'il faut decider, tuile par
	# tuile, pas le compte. La cle la plus petite du groupe sert de representant -- c'est elle
	# qui ira sur la planche, et les autres s'y ramenent.
	var reps: Array[int] = []
	for mark3: Variant in groups.keys():
		var group3: Array = groups[mark3]
		group3.sort()
		reps.append(int(group3[0]))
	reps.sort()
	var lines: PackedStringArray = PackedStringArray()
	for rep: int in reps:
		lines.append("%d(s%d,b%d)" % [rep, rep & 0xff, rep >> 8])
	print("  LES %d DESSINS : %s" % [reps.size(), " ".join(lines)])
	# ⚠ ET ON DIT CE QU'UN MONDE EN EXERCE, parce que c'est la seule question qui serve au
	# guide : quels dessins ne se peignent NULLE PART ? `LADDER_SEEN` prend la sortie d'un
	# `LADDER_VOCAB=1` -- la ligne `POSEES:` -- et rend les groupes que ce monde ne touche pas.
	var seen_path: String = OS.get_environment("LADDER_SEEN")
	if seen_path.is_empty():
		return
	var seen: Dictionary = {}
	for line: String in FileAccess.get_file_as_string(seen_path).split("\n"):
		if not line.contains("POSEES:"):
			continue
		for piece2: String in line.split("POSEES:")[1].strip_edges().split(",", false):
			seen[int(piece2.strip_edges())] = true
	var touched: Dictionary = {}
	var outside: Array[int] = []
	for mark4: Variant in groups.keys():
		for key4: int in (groups[mark4] as Array):
			if seen.has(key4):
				touched[mark4] = true
	for key5: Variant in seen.keys():
		if not tiles.has(int(key5)):
			outside.append(int(key5))
	var missing: PackedStringArray = PackedStringArray()
	for mark5: Variant in groups.keys():
		if not touched.has(mark5):
			var g5: Array = groups[mark5]
			g5.sort()
			missing.append("%d(s%d,b%d)" % [int(g5[0]), int(g5[0]) & 0xff, int(g5[0]) >> 8])
	missing.sort()
	print("  MONDE : %d cles posees, %d dessins sur %d touches"
			% [seen.size(), touched.size(), groups.size()])
	if not missing.is_empty():
		print("  LUI MANQUE (%d) : %s" % [missing.size(), " ".join(missing)])
	if not outside.is_empty():
		outside.sort()
		print("  ⚠ %d CLE(S) HORS DE LA FORME : %s" % [outside.size(), str(outside)])


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
	# LE MONDE SE NOMME APRES LE COUPLE : « L3/F2@guide ».
	var named: PackedStringArray = couple.split("@")
	# ⚠ ET ON RABAISSE LA CASSE : la ligne de commande MAJUSCULE ses arguments, si bien que
	# `-- L3 F2@guide` demandait le monde « GUIDE », qui n'existe pas -- et le banc rendait la
	# planche en annoncant le guide. Une option qui echoue en silence vaut moins que pas
	# d'option : elle fait croire qu'on a mesure ce qu'on n'a pas mesure.
	_world_name = String(named[1]).to_lower() if named.size() > 1 			else OS.get_environment("LADDER_WORLD").to_lower()
	var parts: PackedStringArray = String(named[0]).split("/")
	if parts.size() != 2:
		push_error("ladder: couple illisible '%s' (attendu L0/F0)." % couple)
		return false
	var level: int = int(parts[0].substr(1))
	var freedom: int = int(parts[1].substr(1))
	if not _quiet:
		print("=== %s ===" % couple)

	Contour.level = level
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
				#
				# ⚠ ET DES L2 LES DIAGONALES SUD TOMBENT -- theoreme, voir `Brink.shave`. Le
				# banc le demande au modele, il ne le refait pas : c'est la troisieme fois de
				# la session qu'une regle posee d'un cote n'a rien change parce que l'autre
				# cote avait sa copie.
				map[Vector2i(x, y)] = Brink.shave(Coverage.index_at(mask, x, y), level)
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

	if not _quiet:
		print("  monde : %d x %d, %d etage(s), %d cases visibles, %d tuiles a peindre"
					% [HeightMask.width(world), HeightMask.height(world), top + 1, indices.size(),
					vocabulary.size()])
	# L5 : LA FAMILLE A CHEVAL REMPLACE LE VOCABULAIRE DE SURFACE, PAS LE MONDE. Meme relief,
	# memes falaises ; ce qui change est la grille sur laquelle les surfaces se posent -- le
	# CROISEMENT de quatre cases au lieu de la case, donc un demi-pas de decalage.
	if level >= 5:
		var dual: Array[Dictionary] = []
		for storey: int in range(storeys.size()):
			var mask: PackedStringArray = HeightMask.silhouette(world, storey)
			var map: Dictionary = {}
			for j: int in range(HeightMask.height(mask) + 1):
				for i: int in range(HeightMask.width(mask) + 1):
					var code: int = CornerIndex.index_at(mask, i, j)
					if code != CornerIndex.NO_INDEX and code != 0:
						map[Vector2i(i, j)] = code
			dual.append(map)
		storeys = dual
		indices = {}
		vocabulary = {}
		for point: Vector2i in CornerIndex.index_map(world).keys():
			var code2: int = int(CornerIndex.index_map(world)[point])
			if code2 != 0:
				indices[point] = code2
		for storey: int in range(storeys.size()):
			for point: Vector2i in (storeys[storey] as Dictionary).keys():
				vocabulary[int((storeys[storey] as Dictionary)[point])] = true
		# ⚠ LE BIT SE CALCULE ICI, PAS DANS LA TUILE : c'est ce qu'une tuile ne peut pas savoir.
		# Une demi-frontiere verticale se tait quand l'une des deux cases qu'elle separe est
		# couverte par une FACE -- c'est le flanc de cette face qui la porte, au meme endroit.
		if Contour.astride != "face":
			var walls5: Dictionary = Brink.closed_roles(Walls.visible(world)["roles"])
			var under5: Dictionary = Walls.visible_underfoot(world)
			for storey: int in range(storeys.size()):
				var map5: Dictionary = storeys[storey]
				for point: Vector2i in map5.keys():
					var quiet5: int = 0
					# ⚠ ET LE BIT SE DEDOUBLE PAR COTE. Il ne suffit pas de savoir qu'une robe
					# borde cette demi-frontiere : il faut savoir DE QUEL COTE, parce que son
					# flanc rentre CHEZ ELLE. A l'ouest il recule l'axe, a l'est il l'avance --
					# un bit qui dit « l'une ou l'autre » ne permet pas de choisir le signe, et
					# les deux essais a un seul bit ont mesure 123 et 77 extremites contre 43.
					var forme5: int = int(map5[point]) & 0xf
					for half: int in range(2):
						var a: Vector2i = point + CornerIndex.OFFSETS[0 if half == 0 else 3]
						var b: Vector2i = point + CornerIndex.OFFSETS[1 if half == 0 else 2]
						if walls5.has(a) or walls5.has(b):
							quiet5 |= 1 << half
					# Les deux moities de la frontiere HORIZONTALE : ouest (NO au-dessus de SO)
					# et est (NE au-dessus de SE). Elles se taisent sous un PIED.
					for half: int in range(2):
						var over5: Vector2i = point + CornerIndex.OFFSETS[0 if half == 0 else 1]
						# ⚠ ET UN PIED REPOSE COMPTE AUTANT QU'UN PIED VISIBLE. Il trace son
						# bord bas au meme endroit ; ne pas le voir laissait 47 paves, tous
						# « robe, pied repose ».
						# ⚠ ET UN PIED REPOSE NE TRACE RIEN DEPUIS QUE L3 A CHOISI `mute` : c'est sa
						# matiere SANS son contour. Le faire taire au-dessus laissait la frontiere
						# sans personne. Joignable par `LADDER_UNDERFOOT=trace`.
						if Brink.foot_above(over5, walls5) \
								or (_backing_traces and Brink.foot_above(over5, under5)):
							quiet5 |= 4 << half
					# ⚠ ET SUR LE CARRE PLEIN, AUCUN SILENCE NE DISTINGUE RIEN -- DEMONTRE, PAS
					# MESURE. La forme 15 a ses quatre quadrants pleins : tout pixel y est de la
					# matiere, aucun n'a de voisin vide, la tuile est un aplat sans un trait, et
					# ni l'axe ni les silences n'y changent un pixel. Les garder dans la cle
					# fabrique jusqu'a trente-deux tuiles pour un seul aplat.
					#
					# ⚠ ET LE MASQUAGE PLUS LARGE -- « un silence ne se pose que la ou sa
					# demi-frontiere existe » -- EST REFUTE PAR LA MESURE : 48 -> 31 cles sur la
					# planche, mais I1 passe de 0 a 37 extremites et I2 de 0 a 35 paves. La
					# raison est nette et vaut d'etre gardee : le bit ne fait pas que TAIRE un
					# trait, il PINCE L'AXE -- et l'axe vertical gouverne aussi la frontiere
					# HORIZONTALE, dont les quadrants dependent des deux axes a la fois. Un bit
					# sans frontiere a taire n'est donc pas sans effet.
					# ⚠ ET L'ETENDUE ASYMETRIQUE A ETE ESSAYEE PUIS REFUTEE, ce qui apprend ou s'arrete
					# la demonstration. `vx >= half - 1` et `hy >= half - 1` toujours : les colonnes 0 a
					# `half - 1` sont donc toujours a l'ouest et les rangees 0 a `half - 1` toujours au
					# nord, d'ou -- pour la MATIERE -- `bit 1 inerte si NO == NE`, `bit 4 si NO == SO`,
					# et les deux autres sous les deux conditions. Mesure : 40 -> 34 cles sur la planche,
					# 59 -> 49 sur `@battue1`, les dessins inchanges... et I2 passe de 0 a 9 paves.
					#
					# ⚠ LA RAISON, ET ELLE BORNE TOUTE REDUCTION FUTURE : le bit ne decide pas que la
					# MATIERE, il decide aussi SI LE RENDEZ-VOUS EXISTE -- `steps` vaut « exactement une
					# des deux moities se tait ». Retirer un bit inerte pour la matiere fait donc
					# APPARAITRE une marche la ou il n'y en avait pas. Un bit n'est retirable que s'il
					# est inerte pour TOUT ce que la tuile en fait, et l'aplat est le seul cas ou on
					# sait le demontrer.
					if forme5 == 15:
						quiet5 = 0
					# ⚠ ET LE CINQUIEME BIT SE LIT APRES LE MASQUAGE, jamais avant : il ne sert qu'au
					# rendez-vous, et le rendez-vous n'existe que si le silence vertical a survecu.
					# ⚠ ET LE CINQUIEME BIT NE SE POSE QUE LA OU IL CHANGE QUELQUE CHOSE. Il
					# ne sert qu'au rendez-vous -- savoir si le chapiteau d'en dessous est du
					# cote EST, donc si sa crete au ras donne deja le contact -- et le
					# rendez-vous ne se pose que quand exactement une des deux moities
					# verticales se tait. Pose partout, il doublerait la cle pour rien : c'est
					# la lecon deja payee deux fois (`+5 tuiles` a poser un bit en gros,
					# `+0` a le poser au bon endroit).
					if (quiet5 & 2) != 0 and (quiet5 & 1) == 0 \
							and walls5.has(point + CornerIndex.OFFSETS[2]):
						quiet5 |= 16
					map5[point] = int(map5[point]) | (quiet5 << 4)
			indices = {}
			vocabulary = {}
			for point: Vector2i in CornerIndex.index_map(world).keys():
				var here5: int = HeightMask.level_at(world, point.x, point.y)
				var top5: int = 0
				for off: Vector2i in CornerIndex.OFFSETS:
					top5 = maxi(top5, HeightMask.level_at(world, point.x + off.x,
							point.y + off.y))
				if (storeys[top5] as Dictionary).has(point):
					indices[point] = int((storeys[top5] as Dictionary)[point])
			for storey: int in range(storeys.size()):
				for point: Vector2i in (storeys[storey] as Dictionary).keys():
					vocabulary[int((storeys[storey] as Dictionary)[point])] = true
		print("  a cheval : %d croisements visibles, %d tuiles de croisement"
				% [indices.size(), vocabulary.size()])
		# ⚠ UNE SONDE, PARCE QUE TROIS HYPOTHESES DE SUITE ONT ETE FAUSSES SUR LE MEME PIXEL.
		# `LADDER_PROBE=i,j` dit tout ce qu'un croisement sait : les quatre cases, leur etage,
		# la robe qui les couvre et sa levre, puis la cle a cheval de chaque etage avec ses
		# quatre bits de silence en clair. Lire l'image dit OU le trait est ; ceci dit POURQUOI.
		var probe5: String = OS.get_environment("LADDER_PROBE")
		if not probe5.is_empty():
			var cut5: PackedStringArray = probe5.split(",")
			var point5: Vector2i = Vector2i(int(cut5[0]), int(cut5[1]))
			var walls6: Dictionary = Walls.visible(world)
			var under6: Dictionary = Walls.visible_underfoot(world)
			print("  -- sonde du croisement %d,%d --" % [point5.x, point5.y])
			for corner5: int in range(4):
				var at5: Vector2i = point5 + CornerIndex.OFFSETS[corner5]
				var said5: String = "etage %d" % HeightMask.level_at(world, at5.x, at5.y)
				if (walls6["roles"] as Dictionary).has(at5):
					var role5: Vector2i = (walls6["roles"] as Dictionary)[at5]
					said5 += ", ROBE pan %d rangee %d (levre etage %d)" % [role5.x, role5.y,
							int((walls6["lips"] as Dictionary)[at5])]
				if under6.has(at5):
					said5 += ", pose arriere rangee %d" % (under6[at5] as Vector2i).y
				print("     case %s %s : %s" % [CornerIndex.BIT_NAMES[corner5], at5, said5])
			for storey5: int in range(storeys.size()):
				var map6: Dictionary = storeys[storey5]
				if not map6.has(point5):
					continue
				var key5: int = int(map6[point5])
				var mute5: PackedStringArray = PackedStringArray()
				for bit5: int in range(4):
					if ((key5 >> 4) & (1 << bit5)) != 0:
						mute5.append(["vert-nord", "vert-sud", "horiz-ouest",
								"horiz-est"][bit5])
				print("     etage %d : cle %d (forme %d, silences %s)" % [storey5, key5,
						key5 & 0xf, "aucun" if mute5.is_empty() else " ".join(mute5)])

	var canonical: Dictionary = {}
	for cell: Vector2i in indices.keys():
		canonical[BlobIndex.canonicalize(int(indices[cell]) & 0xff)] = true
	var expected: int = Brink.silhouettes(level).size()
	var complete: bool = canonical.size() == expected
	if level >= 5:
		# ⚠ ET ON COMPTE LES QUINZE SILHOUETTES, PAS LES TUILES. Les bits de bord multiplient
		# les tuiles ; ce que le monde doit exercer, c'est le vocabulaire de FORMES.
		expected = CornerIndex.TILE_COUNT
		canonical = {}
		for key6: Variant in vocabulary.keys():
			canonical[int(key6) & 0xf] = true
		complete = canonical.size() == expected
	if not _quiet:
		print("  vocabulaire exerce : %d / %d silhouettes%s   %d tuiles a peindre"
					% [canonical.size(), expected, "" if complete else "  ⚠ INCOMPLET",
					vocabulary.size()])

	# ⚠ LES FALAISES D'ABORD, LES TUILES ENSUITE. Le calcul des bords change le VOCABULAIRE ;
	# peindre avant, c'est peindre une liste a laquelle il manque des cles -- et l'assemblage
	# tombe alors sur une tuile nulle, sans rien dire de plus utile que « get_width sur null ».
	var roles: Dictionary = {}
	## Les robes POSEES : la meme carte, mais keyee par la cle de tuile -- arete comprise.
	var posted: Dictionary = {}
	var role_tiles: Dictionary = {}
	# ⚠ UN SEUL ASSEMBLAGE POUR LES DEUX CARTES, ET IL SE DECLARE ICI. `visible()` et
	# `visible_underfoot()` refaisaient chacune le parcours complet du relief, pour deux
	# moities du meme calcul -- et la pose arriere se lit vingt lignes plus bas, donc la
	# carte doit vivre a la portee de la fonction, pas du bloc.
	var seen: Dictionary = {}
	if level >= 2:
		seen = Walls.visible_all(world)
		roles = seen["roles"]
		roles = Brink.mark(world, storeys, indices, vocabulary, roles, level, _drop)
		# ⚠ J2 « SOMMET CONTRE FACE » : DE QUEL COTE ON POSE LE BIT. Un des deux doit se taire, donc
		# il faut un bit -- mais il MULTIPLIE la famille qui le porte. Sur la surface il double 27
		# silhouettes (jusqu'a 228 en forme fermee) ; sur la face il ne touche que 20 roles
		# (jusqu'a 54). Le compte se calcule avant de choisir, et se MESURE avant d'etre paye.
		if Brink.j2_on_face:
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
		under = seen["underfoot"]
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
				posed = Vector2i(Compose.solid_pan(), Walls.ROW_CROWN + 1)
			(under_by_level[landing] as Dictionary)[cell] = Compose.wall_key(posed)
		var said: PackedStringArray = PackedStringArray()
		for kind: String in by_kind.keys():
			said.append("%d %s" % [int(by_kind[kind]), kind])
		said.sort()
		if not _quiet:
			print("  poses arriere : %d  -- %s" % [under.size(), ", ".join(said)])

	# ⚠ « LE SOMMET TRACE, LES ENTERRES SE POSENT PLEINS » -- la question de L1, remise sur le
	# banc maintenant que L2 et L3 sont la. Une case appartient ENTIEREMENT a chaque silhouette
	# qui la contient : le monde n'y a pas de bord, et l'entaille du sommet n'est qu'une
	# decoration du bord VISIBLE. Poser la tuile pleine sous le sommet supprime d'un coup tout
	# ce qu'un etage enterre peut laisser fuir par une encoche.
	if _buried_full:
		for storey4: int in range(storeys.size()):
			var map4: Dictionary = storeys[storey4]
			for cell4: Vector2i in map4.keys():
				if HeightMask.level_at(world, cell4.x, cell4.y) != storey4:
					map4[cell4] = 0xff
		vocabulary[0xff] = true

	_storeys = storeys

	if level >= 2 and level < 5 and not _quiet:
		var junc: Dictionary = _junctions(world, indices, roles, under)
		var said4: Array[String] = []
		said4.assign((junc["kinds"] as Dictionary).keys())
		said4.sort()
		print("  jonctions : %d especes distinctes sur %d adjacences ; %d couples (silhouette,"
				% [(junc["kinds"] as Dictionary).size(), int(junc["total"]),
				int(junc["couples"])]
				+ " cote) dont %d EN VOIENT PLUSIEURS (jusqu'a %d)"
				% [int(junc["forces"]), int(junc["pire"])])
		for label: String in said4:
			print("     %6d  %s" % [int((junc["kinds"] as Dictionary)[label]), label])
		var verdict: String = "LE PRODUIT TIENT" if int(junc["eclates"]) == 0 			else "LE PRODUIT NE TIENT PAS"
		print("  contextes (silhouette + les 4 especes) : %d, dont %d recoivent PLUSIEURS"
				% [int(junc["contextes"]), int(junc["eclates"])]
				+ " tuiles (jusqu'a %d)  -- %s" % [int(junc["plus"]), verdict])
		if int(junc["eclates"]) > 0:
			print("     temoin : %s" % str(junc["temoin"]))
		print("  le prix du SECOND ORDRE : %d tuiles de surface, %d sans les quatre bits qui"
				% [int(junc["entier"]), int(junc["premier"])]
				+ " demandent ce que la voisine trace  -- %d de moins"
				% [int(junc["entier"]) - int(junc["premier"])])

	var kinds: Dictionary = {}
	for cell: Vector2i in roles.keys():
		kinds[roles[cell]] = true
	# ET CE QUE LE MONDE DOIT AUX TROIS CLAUSES CANDIDATES, dit au passage : savoir si nos
	# mondes LIVRES les respectent deja est la moitie de leur mesure.
	if not _quiet:
		print("  robes : %d roles distincts, %d cases de falaise" % [kinds.size(), roles.size()]
					+ "   -- %d paroi(s) fine(s), %d contact(s) d'etages, %d marche(s) courte(s)"
					% [_narrow_walls(roles), _mixed_faces(Walls.visible(world)), _short_lips(world)])
	# LA BATTUE DE VOCABULAIRE S'ARRETE ICI : elle veut la LISTE des tuiles, pas leur dessin.
	# Peindre et mesurer coute trente secondes par monde ; batir le monde et poser ses bits en
	# coute une fraction. C'est ce qui rend deux cents mondes tenables.
	if _vocab_only:
		for key: Variant in vocabulary.keys():
			if _current >= 0 and not _vocab_seen.has(int(key)):
				_witness_of[int(key)] = _current
			_vocab_seen[int(key)] = true
		for cell: Vector2i in roles.keys():
			_vocab_roles[roles[cell]] = true
		return true

	# L4 : LE RECENSEMENT DES RACCORDS, ET IL SE FAIT AVANT DE PEINDRE. Il ne decrit pas le
	# dessin, il le CONTRAINT : chaque classe recoit sa graine, et deux bords qui doivent etre
	# le meme dessin le sont par construction.
	#
	# ⚠ DEUX CLOTURES, ET UNE SEULE EST REQUISE. La SUPERPOSITION l'est -- deux tuiles empilees
	# dans une meme case tracent le meme bord, et si elles ne le tracent pas pareil le trait se
	# dedouble (c'est le defaut mesure a L1/F2, six paves). La CONTINUATION, elle, ne l'est
	# PAS : deux bords colineaires dans deux cases voisines se rencontrent a leur frontiere
	# commune parce que la TRAVERSEE les y ramene tous les deux, quelle que soit leur classe.
	# On mesure les deux et on ne joint que la premiere -- et c'est l'experience qui tranche,
	# pas le raisonnement : si les six invariants restent verts, la liberte mesuree est reelle.
	var seams: Dictionary = Compose.seam_classes(storeys, roles, level, false)
	var welded: Dictionary = Compose.seam_classes(storeys, roles, level, true)
	var said2: String = "  raccords : %d bords traces -> %d classes independantes" 			% [int(seams["bords"]), int(seams["classes"])]
	print(said2 + "   (%d liens de superposition ; la continuation en joindrait %d de plus,"
			% [int(seams["superposition"]), int(welded["continuation"])]
			+ " et n'en laisserait que %d)" % [int(welded["classes"])])
	var tiles: Dictionary = {}
	if level >= 5:
		for key5: Variant in vocabulary.keys():
			tiles[int(key5)] = Contour.corner_tile(int(key5) & 0xf, freedom, [], level,
					int(key5) >> 4)
	else:
		tiles = Compose.paint(vocabulary, freedom, level, seams["graine"])
	# ⚠ ET ON DIT COMBIEN SONT VRAIMENT POSEES, PAS SEULEMENT COMBIEN SONT PEINTES. `vocabulary`
	# est nourri A CHAQUE PASSE -- silhouette nue, puis bords, puis ergots -- et une cle ajoutee
	# avant d'etre affinee y RESTE : plus aucune case ne la porte, et le banc la peignait quand
	# meme. Le compte annonce etait donc un majorant, jamais le vocabulaire. Mesure sur la
	# planche : 59 peintes pour 45 posees.
	#
	# ⚠ ET C'EST LE CHIFFRE SUR LEQUEL TOUTE LA DISCUSSION DU SWEET SPOT REPOSE. Un compteur qui
	# ne mesure pas ce qu'il pretend mesurer est pire que pas de compteur.
	var posed: Dictionary = {}
	for storey6: Dictionary in storeys:
		for cell6: Vector2i in storey6.keys():
			posed[int(storey6[cell6])] = true
	var ghost: int = 0
	for key6: Variant in tiles.keys():
		if not posed.has(int(key6)):
			ghost += 1
	# ⚠ ET « POSEE » N'EST PAS ENCORE « DISTINCTE ». Deux cles qui peignent LA MEME IMAGE sont
	# une seule tuile : le peintre la dessine une fois, la planche en porte une case. Une cle de
	# plus qui ne change pas un pixel est exactement ce que le critere 3 du plan interdit --
	# *aucune tuile de la planche n'est la pour rien* -- et c'est la signature d'un bit dont la
	# precondition ne tient pas : il est pose, il change la cle, et il ne distingue RIEN.
	#
	# ⚠ ET ON COMPARE LES PIXELS, PAS LES BITS. Chercher les bits inertes demanderait de
	# redemontrer, bit par bit, quand la precondition tient -- c'est-a-dire de rederiver le
	# calcul qu'on controle. On rend les images et on les compare, comme le reste du banc.
	var drawings: Dictionary = {}
	for key8: Variant in posed.keys():
		var image8: Image = tiles[int(key8)] as Image
		var print8: String = image8.get_data().hex_encode()
		if not drawings.has(print8):
			drawings[print8] = []
		(drawings[print8] as Array).append(int(key8))
	# ⚠ ET ON DIT QUELS BITS NE DISTINGUENT RIEN, PAS SEULEMENT COMBIEN. « 48 cles pour 31
	# dessins » range le defaut ; il ne dit pas lequel des bits est de trop. Deux cles du meme
	# dessin ne different que par des bits INERTES : on les accumule, et le compte par bit dit
	# ou la precondition ne tient pas.
	# ⚠ ET ON N'ACCUSE QU'UN BIT ISOLE. Deux cles qui different par TROIS bits et peignent la
	# meme image ne prouvent rien sur chacun d'eux -- ils peuvent se compenser. Ce qui prouve
	# qu'un bit ne distingue rien, c'est une paire qui ne differe QUE par lui. Premiere version
	# comptee sur tous les bits differents : elle accusait les cinq a la fois, ce qui envoie
	# corriger au hasard.
	var idle: Dictionary = {}
	for print9: Variant in drawings.keys():
		var group9: Array = drawings[print9]
		for a9: int in range(group9.size()):
			for b9: int in range(a9 + 1, group9.size()):
				# ⚠ ET LA CLE ENTIERE, SILHOUETTE COMPRISE. Comparee sur les seuls bits de bord,
				# la sonde accusait « le bit 2 ne distingue rien » sur la paire 255 / 543 --
				# deux SILHOUETTES differentes (255 pleine, 31 dont l'ouest est ouvert puis
				# tu). Le fait est vrai et interessant : une silhouette dont on tait le seul
				# cote ouvert devient la tuile pleine. Mais ce n'est pas un bit inerte, c'est
				# une COLLISION -- et les confondre envoie retirer un bit qui sert.
				var diff9: int = int(group9[a9]) ^ int(group9[b9])
				if diff9 != 0 and (diff9 & (diff9 - 1)) == 0:
					idle[diff9] = int(idle.get(diff9, 0)) + 1
					if _idle_pairs.size() < 8:
						_idle_pairs.append("bit %d : %d = %d" % [diff9,
								int(group9[a9]), int(group9[b9])])
	print("  A PEINDRE : %d tuiles de surface   (%d posees, %d JAMAIS POSEE(S), %d DESSINS)"
			% [tiles.size(), posed.size(), ghost, drawings.size()])
	if not idle.is_empty():
		var bits9: Array[int] = []
		bits9.assign(idle.keys())
		bits9.sort()
		var said9: PackedStringArray = PackedStringArray()
		for bit10: int in bits9:
			said9.append("%d x%d" % [bit10, int(idle[bit10])])
		print("  -- bits qui ne distinguent RIEN : %s" % ", ".join(said9))
		print("     exemples : %s" % " ; ".join(_idle_pairs))
	if not OS.get_environment("LADDER_VOCAB").is_empty():
		var listing: Array[int] = []
		listing.assign(tiles.keys())
		listing.sort()
		print("  VOCAB %s" % str(listing))
		# ⚠ ET LA LISTE DES POSEES, PAS SEULEMENT DES PEINTES. C'est elle qui se compare a un
		# domaine enumere : une tuile peinte que rien ne pose n'est nulle part dans le monde.
		var placed: Array[int] = []
		placed.assign(posed.keys())
		placed.sort()
		var told: PackedStringArray = PackedStringArray()
		for key7: int in placed:
			told.append(str(key7))
		print("  POSEES: %s" % ",".join(told))
		# ⚠ ET OU CHACUNE SE TROUVE, parce qu'un guide qui EXERCE le vocabulaire se decoupe
		# dans les mondes qui le portent -- c'est deja la methode des demonstrations de
		# falaise : « decoupee dans le guide, plus dessinee a la main ». Un vivier de reliefs
		# 7x5 n'en produit que 29 ; les mondes livres en portent 51.
		var ou: Dictionary = {}
		for storey8: int in range(storeys.size()):
			var map8: Dictionary = storeys[storey8]
			for cell8: Vector2i in map8.keys():
				var key8: int = int(map8[cell8])
				if not ou.has(key8):
					ou[key8] = cell8
		var dits: PackedStringArray = PackedStringArray()
		for key9: int in placed:
			if ou.has(key9):
				dits.append("%d@%d.%d" % [key9, (ou[key9] as Vector2i).x,
						(ou[key9] as Vector2i).y])
		print("  OU: %s" % ",".join(dits))
		var out8: FileAccess = FileAccess.open("user://monde.txt", FileAccess.WRITE)
		if out8 != null:
			out8.store_string("\n".join(world) + "\n")
			out8.close()
			print("  MONDE ECRIT : %s" % ProjectSettings.globalize_path("user://monde.txt"))
	if Brink.open_edges > 0:
		print("  bords ouverts d'une surface : %d, dont %d SANS face en face (%.1f %%)"
				% [Brink.open_edges, Brink.bare_edges, 100.0 * float(Brink.bare_edges) / float(Brink.open_edges)])
	if level >= 2:
		if not Brink.stub_why.is_empty():
			var raisons: Array[String] = []
			raisons.assign(Brink.stub_why.keys())
			raisons.sort_custom(func(x: String, y: String) -> bool:
					return int(Brink.stub_why[x]) > int(Brink.stub_why[y]))
			print("  -- pourquoi l'ergot se tait --")
			for quoi: String in raisons:
				print("     %5d  %s" % [int(Brink.stub_why[quoi]), quoi])
			Brink.stub_why.clear()
		# ⚠ ET L'ARETE INTERNE ENTRE DANS LA CLE DE LA ROBE. Une tuile posee avec et sans son
		# angle serait la meme tuile dans deux situations differentes -- exactement ce qu'une
		# tuile partagee ne peut pas faire. La cle passe donc de (pan, rangee) a
		# (pan, rangee, arete), et c'est `Compose.wall_key` qui la fabrique, une seule fois.
		var lip_rows: Dictionary = (seen.get("lips", {}) as Dictionary)
		for cell: Vector2i in roles.keys():
			posted[cell] = Compose.wall_key(roles[cell],
					Compose.ridge_bits(cell, roles, lip_rows))
		var kinds2: Dictionary = {}
		for cell: Vector2i in roles.keys():
			kinds2[posted[cell]] = true
		# ⚠ ET LES ROLES REPOSES AUSSI. Une pose arriere n'ajoute aucune tuile au vocabulaire,
		# mais elle peut etre la SEULE occurrence d'un role sur ce monde-la : sans sa cle, le
		# dictionnaire des tuiles n'a rien a rendre et l'assemblage tombe sur un nul, qui ne
		# dit rien de plus utile que « get_width sur null ».
		for cell: Vector2i in under.keys():
			kinds2[Compose.wall_key(under[cell])] = true
		if _backing == "full":
			kinds2[Compose.wall_key(Vector2i(Compose.solid_pan(), Walls.ROW_CROWN + 1))] = true
		role_tiles = Compose.wall_tiles(kinds2, freedom, seams["graine"])
		# ⚠ ET « ROLE » N'EST PAS « DESSIN » NON PLUS. La regle est deja ecrite pour les
		# surfaces -- *deux cles qui peignent la meme image sont une seule tuile, le peintre la
		# dessine une fois* -- et elle n'avait jamais ete appliquee aux robes. Le banc annoncait
		# donc un total qui melangeait des dessins d'un cote et des cles de l'autre : le seul
		# chiffre qui compte pour l'acheteur est ce qu'il aura a peindre.
		var wall_prints: Dictionary = {}
		for key10: Variant in role_tiles.keys():
			wall_prints[(role_tiles[key10] as Image).get_data().hex_encode()] = true
		print("  A PEINDRE : %d roles de robe, %d DESSINS   -- TOTAL %d dessins"
				% [role_tiles.size(), wall_prints.size(),
				tiles.size() + wall_prints.size()])
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
	if _backing == "bout" or _backing == "cote":
		backing_tiles = {}
		for key: Variant in role_tiles.keys():
			backing_tiles[key] = Compose.muted_but(role_tiles[key] as Image, _backing == "bout")
	if _backing == "mute":
		backing_tiles = {}
		for key: Variant in role_tiles.keys():
			backing_tiles[key] = Compose.muted(role_tiles[key] as Image)
	# ⚠ ET ON DEMANDE A L'ASSEMBLAGE QUI A POSE QUEL PIXEL. Sans ca, une frontiere ENTRE
	# COUCHES ne se diagnostique pas : I2 compte le pave, I3 ne le voit meme pas, et personne
	# ne peut dire entre qui. Redeviner l'ordre d'empilement ici serait une seconde copie de
	# la regle -- la faute la plus chere du depot.
	var who: Image = Image.create_empty(HeightMask.width(world) * RES,
			HeightMask.height(world) * RES, false, Image.FORMAT_RGBA8)
	var image: Image = Compose.assemble(world, storeys, tiles, posted, role_tiles, under_by_level,
			backing_tiles, level >= 5, who, level)
	# LE TEMOIN DE I6 : le meme monde, sans une seule pose arriere. Ce que la pose donne a voir
	# est exactement ce qui differe entre les deux -- rien a classer par la couleur.
	var bare: Image = null
	var cover: Image = null
	if level >= 3:
		var none: Array[Dictionary] = []
		for storey: int in range(storeys.size()):
			none.append({})
		bare = Compose.assemble(world, storeys, tiles, posted, role_tiles, none, backing_tiles,
				level >= 5, null, level)
		# ⚠ ET LA COUVERTURE SE LIT SUR UNE ASSEMBLEE DES SURFACES SEULES, PAS SUR UNE TUILE.
		# I6 demandait « la tuile qui couvre cette case » -- une question qui n'a plus de
		# reponse des que les surfaces sont DECALEES D'UN DEMI-PAS : une case y est couverte
		# par QUATRE tuiles a cheval. Une assemblee sans robes ni poses arriere repond pour
		# toutes les familles, et sans rien redemander au modele.
		cover = Compose.assemble(world, storeys, tiles, {}, role_tiles, none, backing_tiles,
				level >= 5, null, level)
	_write(image, couple)
	var report: Dictionary = _measure(image, world, indices, tiles, freedom, roles, under,
			role_tiles, bare, cover, level, who)
	# ⚠ LA COMPLETUDE DU VOCABULAIRE EST UNE EXIGENCE DE SPECIMEN, PAS DE MONDE. La planche et
	# le guide sont batis POUR porter les 27 silhouettes, et un manque y est un defaut. Une
	# battue, elle, n'a pas a les porter : elle est la pour eprouver les RENCONTRES, et lui
	# demander la couverture reviendrait a l'exclure de l'acquis pour une raison qui n'est pas
	# la sienne. Le compte reste imprime -- « une battue qui ne rencontre pas le vocabulaire ne
	# prouve pas qu'il est sain, elle prouve qu'elle n'a rien regarde » -- il ne juge plus.
	var ok: bool = complete or _world_name.begins_with("battue")
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


## UN MONDE TIRE AU SORT, MAIS PAR LE GESTE DU PINCEAU -- pas par des rectangles au hasard.
##
## ⚠ LE VOCABULAIRE N'EST PAS « TOUT RELIEF EPAIS », C'EST « TOUT RELIEF QUE LE PINCEAU PEUT
## FAIRE ». SoluPaint pose des tampons 3x3, efface en 3x3, et refuse tout geste qui laisserait
## une case fine. Une battue qui tire des blocs au hasard cherche donc ailleurs que la ou
## l'acheteur dessine : elle peut fabriquer des rencontres que personne ne produira jamais, et
## en manquer d'autres. C'est la regle de `tools/brush_census.gd`, reprise ici.
##
## ⚠ ET UNE MAIN POSE ALIGNE, LE HASARD NON. Un tampon pose a un decalage quelconque laisse
## presque toujours une case fine -- la moitie des gestes refuses -- et la battue passe son
## temps a se faire dire non. On tire donc surtout des poses alignees sur trois.
##
## ⚠ LA GRAINE EST FIXE, ET C'EST VOULU. « Deux executions doivent donner la meme image, sans
## quoi le banc ne dit plus si un correctif a servi » -- deja ecrit au dossier pour le trace.
## Un monde tire a chaque fois trouverait plus de defauts et ne dirait jamais si on en a
## corrige un.
func _battue(name: String) -> PackedStringArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260827 + int(name.substr(6))
	var width: int = 40
	var height: int = 30
	var edge: int = 4
	var grid: Array[PackedByteArray] = []
	for y: int in range(height):
		var line: PackedByteArray = PackedByteArray()
		line.resize(width)
		grid.append(line)
	# ⚠ ET IL EN FAUT BEAUCOUP : a quatre-vingt-dix gestes la battue ne remplissait qu'un quart
	# du cadre et n'exercait que 13 silhouettes sur 27. Une battue qui ne rencontre pas le
	# vocabulaire ne prouve pas qu'il est sain, elle prouve qu'elle n'a rien regarde.
	var refused: int = 0
	for gesture: int in range(400):
		var level: int = rng.randi_range(-1, 3)
		var ox: int = rng.randi_range(edge, width - edge - 3)
		var oy: int = rng.randi_range(edge, height - edge - 3)
		if rng.randf() < 0.8:
			ox = edge + ((ox - edge) / 3) * 3
			oy = edge + ((oy - edge) / 3) * 3
		var before: Array[PackedByteArray] = []
		for line: PackedByteArray in grid:
			before.append(line.duplicate())
		for y: int in range(oy, oy + 3):
			for x: int in range(ox, ox + 3):
				var row: PackedByteArray = grid[y]
				row[x] = level + 1
				grid[y] = row
		# LE REFUS DU PINCEAU : un geste qui laisse une case fine ne se pose pas.
		var said2: PackedStringArray = _text(grid)
		if not Thickness.thin_cells(said2).is_empty():
			grid = before
			refused += 1
			continue
		# LES CLAUSES, quand on les mesure : le meme refus, un cran plus loin.
		var broken: bool = false
		if _clause == "paroi3":
			broken = _narrow_walls(Walls.visible(said2)["roles"]) > 0
		elif _clause == "etages":
			broken = _mixed_faces(Walls.visible(said2)) > 0
		elif _clause == "levre3":
			broken = _short_lips(said2) > 0
		elif _clause == "paroi3+etages":
			var built2: Dictionary = Walls.visible(said2)
			broken = _narrow_walls(built2["roles"]) > 0 or _mixed_faces(built2) > 0
		if broken:
			grid = before
			refused += 1
	# ⚠ ET LA MARGE DU BAS VAUT UNE CHUTE ENTIERE DEPUIS LE PLUS HAUT ETAGE. Une chute dans le
	# vide descend de STOREY_TILES x (etage + 1) -- douze rangees depuis l'etage 3 -- et une
	# robe coupee par le cadre laisse son contour ouvert. Ce serait un defaut du MONDE, pas du
	# dessin, et il accuserait la regle a tort.
	var out: PackedStringArray = _text(grid)
	if _vocab_only:
		# ⚠ ET ON DIT CE QUI RESTE, PAS SEULEMENT CE QU'ON A REFUSE. Une clause qui refuse peu
		# peut vouloir dire deux choses opposees -- que le defaut est rare, ou que le detecteur
		# ne le voit pas. Le compte du monde FINI tranche, et on donne les trois pour que
		# chaque clause dise aussi ce qu'elle fait aux deux autres.
		var built3: Dictionary = Walls.visible(out)
		print("  %s : %d gestes refuses sur 400 -- restent %d paroi(s) fine(s), %d contact(s)"
				% [name, refused, _narrow_walls(built3["roles"]), _mixed_faces(built3)]
				+ ", %d marche(s) courte(s)" % [_short_lips(out)])
	var empty: String = ""
	for x: int in range(width):
		empty += "~"
	for row: int in range(Walls.STOREY_TILES * 5):
		out.append(empty)
	return out


## LES PAROIS TROP ETROITES : la clause de grammaire, chiffree avant d'etre decidee.
##
## Une PAROI est un segment de face : une suite de cases de robe, sur une meme rangee, jointes
## par des flancs qui CONTINUENT. La clause dit qu'aucune ne doit faire moins de trois cases --
## c'est l'epaisseur, deja imposee au relief, portee a la FACE.
##
## ⚠ ON COMPTE LES SEGMENTS, PAS LES CASES. Un segment de deux cases est UN defaut, pas deux :
## compter les cases ferait croire que la clause coute le double de ce qu'elle coute.
static func _narrow_walls(roles: Dictionary) -> int:
	var narrow: int = 0
	for cell: Vector2i in roles.keys():
		var role: Vector2i = roles[cell]
		# On ne part que du bout OUEST d'un segment, sinon on le compte autant de fois qu'il
		# a de cases.
		if Walls.pan_west(role.x) != Walls.SIDE_STOP:
			continue
		var run: int = 1
		var at: Vector2i = cell
		while Walls.pan_east((roles[at] as Vector2i).x) == Walls.SIDE_CONTINUE 				and roles.has(at + Vector2i.RIGHT) and run < 64:
			at += Vector2i.RIGHT
			run += 1
		if run < 3:
			narrow += 1
	return narrow


## CLAUSE 2 : deux faces d'ETAGES DIFFERENTS ne se touchent pas lateralement.
##
## C'est le cas qui avait ressuscite le pan (devant, devant) avant la decomposition en couches :
## deux parois cote a cote dont les levres ne sont pas au meme etage. `Walls.visible` rend
## justement l'etage de la levre de chaque case couverte -- on compare, on ne devine pas.
##
## ⚠ ON COMPTE LES CONTACTS, PAS LES CASES : un contact est une PAIRE de cases voisines.
static func _mixed_faces(built: Dictionary) -> int:
	var roles: Dictionary = built["roles"]
	var lips: Dictionary = built["lips"]
	var mixed: int = 0
	for cell: Vector2i in roles.keys():
		var east: Vector2i = cell + Vector2i.RIGHT
		if roles.has(east) and int(lips[cell]) != int(lips[east]):
			mixed += 1
	return mixed


## CLAUSE 3 : une LEVRE ne se decale que par blocs de trois colonnes.
##
## Une levre est une case pleine dans la silhouette d'un etage dont la voisine du SUD ne l'est
## pas : c'est de la que part une face. La clause dit que la marche d'un escalier fait au moins
## trois colonnes -- les escaliers restent, plus grossiers.
##
## ⚠ ET CE N'EST PAS LA CLAUSE 1. Celle-ci ne contraint que la rangee du CHAPITEAU ; le flanc
## d'une face, lui, change en descendant -- une colonne dont la chute s'arrete plus tot coupe le
## segment plus bas. La clause 1 est donc la plus forte des deux, et la mesure doit le montrer.
static func _short_lips(relief: PackedStringArray) -> int:
	var width: int = HeightMask.width(relief)
	var height: int = HeightMask.height(relief)
	var top: int = 0
	for y: int in range(height):
		for x: int in range(width):
			top = maxi(top, HeightMask.level_at(relief, x, y))
	var short: int = 0
	for storey: int in range(top + 1):
		# On balaie rangee par rangee ; une marche est un segment de levres de meme rangee.
		for y: int in range(height):
			var run: int = 0
			for x: int in range(width + 1):
				var lip: bool = x < width 						and HeightMask.level_at(relief, x, y) >= storey 						and HeightMask.level_at(relief, x, y + 1) < storey
				if lip:
					run += 1
					continue
				if run > 0 and run < 3:
					short += 1
				run = 0
	return short


func _text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: PackedByteArray in grid:
		var said: String = ""
		for value: int in line:
			said += "~" if value == 0 else str(value - 1)
		out.append(said)
	return out


## L'ENUMERATION DU DOMAINE REALISABLE.
##
## ⚠ ET LE DOMAINE N'EST PAS « TOUT RELIEF EPAIS », C'EST CE QUE LE PINCEAU PEUT FAIRE. SoluPaint
## pose des tampons 3x3 et refuse tout geste qui laisserait une case fine ; une main pose aligne.
## Le domaine est donc l'ensemble des reliefs faits de BLOCS 3x3 ALIGNES, chacun a un etage --
## et celui-la s'enumere, la ou l'espace des reliefs quelconques ne s'enumere pas (5^25 pour une
## fenetre 5x5).
##
## ⚠ ET L'EPAISSEUR EST GRATUITE PAR CONSTRUCTION. Une silhouette d'etage est une union de blocs
## alignes sur trois : toute course y fait un multiple de trois, donc jamais moins de trois. Le
## pinceau n'a rien a refuser -- c'est exactement pour ca qu'il pose des tampons.
##
## ⚠ CE QUE ÇA N'ENUMERE PAS, ET IL FAUT LE DIRE : les poses NON alignees, les fenetres plus
## larges que trois blocs, et les etages au-dela de l'alphabet demande. C'est une famille close,
## pas le monde entier.
func _enumerate(alphabet: int) -> void:
	_quiet = true
	_vocab_only = true
	# ⚠ LA FENETRE SE PARAMETRE, PARCE QUE C'EST LA DIRECTION QUI COMPTE. Un etage de plus ne
	# fait que rallonger l'alphabet ; une fenetre plus large eprouve la seule chose que le rayon
	# 2 laisse ouverte -- une dependance qui deborderait la fenetre. On fixe donc l'alphabet et
	# on fait varier la fenetre, jamais les deux a la fois.
	var asked: String = OS.get_environment("LADDER_BLOCKS")
	var wide: int = 3
	var tall: int = 3
	if asked.contains("x"):
		wide = maxi(2, int(asked.split("x")[0]))
		tall = maxi(2, int(asked.split("x")[1]))
	elif not asked.is_empty():
		wide = maxi(2, int(asked))
		tall = wide
	var blocks: int = wide * tall
	var total: int = 1
	for i: int in range(blocks):
		total *= alphabet
	# ⚠ ET LA PLAGE SE DECOUPE, PARCE QUE L'ENUMERATION EST PARFAITEMENT SEPARABLE. Chaque
	# relief est independant des autres : huit processus sur huit coeurs font le meme travail
	# huit fois plus vite, et l'union de leurs listes est la reponse. C'est le seul levier qui
	# vaille -- une machine plus rapide donne trois, le decoupage donne huit.
	var from: int = int(OS.get_environment("LADDER_FROM"))
	var upto: int = total
	if not OS.get_environment("LADDER_TO").is_empty():
		upto = mini(total, int(OS.get_environment("LADDER_TO")))
	print("=== DOMAINE REALISABLE : %d reliefs (%dx%d blocs de 3x3, %d etages avec le vide)"
			% [total, wide, tall, alphabet]
			+ "  -- part [%d, %d) ===" % [from, upto])
	var mark: int = 0
	var stable: int = 0
	for n: int in range(from, upto):
		var code: int = n
		var levels: Array[int] = []
		for b: int in range(blocks):
			levels.append(code % alphabet)
			@warning_ignore("integer_division")
			code = code / alphabet
		_injected = _blocks(levels, alphabet, wide, tall)
		_run("L3/F2")
		if n % maxi(1, (upto - from) / 10) == 0 or n == upto - 1:
			var added: int = _vocab_seen.size() - mark
			stable = stable + 1 if added == 0 else 0
			print("  %8d / %d reliefs : %d tuiles de surface, %d roles   (+%d)"
					% [n + 1, total, _vocab_seen.size(), _vocab_roles.size(), added])
			mark = _vocab_seen.size()
	print("  DOMAINE EPUISE : %d tuiles de surface, %d roles de robe   -- TOTAL %d"
			% [_vocab_seen.size(), _vocab_roles.size(),
			_vocab_seen.size() + _vocab_roles.size()])
	# ⚠ ET CHAQUE PART REND SA LISTE, PAS SON COMPTE. Huit comptes ne s'additionnent pas -- les
	# parts se recouvrent -- alors que huit listes s'unissent.
	var keys: Array[int] = []
	keys.assign(_vocab_seen.keys())
	keys.sort()
	var said: PackedStringArray = PackedStringArray()
	for key: int in keys:
		said.append(str(key))
	print("  TUILES: %s" % ",".join(said))
	var found: PackedStringArray = PackedStringArray()
	for role: Vector2i in _vocab_roles.keys():
		found.append("%d.%d" % [role.x, role.y])
	found.sort()
	print("  ROLES: %s" % ",".join(found))


## Un relief fait de neuf blocs 3x3, avec la marge que le modele exige : une chute dans le vide
## descend de STOREY_TILES x (etage + 1), et une robe coupee par le cadre laisserait un contour
## ouvert -- ce serait un defaut du MONDE, pas du dessin.
## LES RELIEFS D'UN FICHIER : un par bloc, separes par une ligne vide.
func _from_file(path: String) -> void:
	_quiet = true
	_vocab_only = true
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ladder: fichier de reliefs illisible '%s'." % path)
		return
	var all: PackedStringArray = file.get_as_text().split("\n\n", false)
	file.close()
	var from: int = int(OS.get_environment("LADDER_FROM"))
	var upto: int = all.size()
	if not OS.get_environment("LADDER_TO").is_empty():
		upto = mini(upto, int(OS.get_environment("LADDER_TO")))
	print("=== RELIEFS EPAIS : %d dans %s  -- part [%d, %d) ===" % [all.size(), path, from, upto])
	var mark: int = 0
	# ⚠ ET C'EST LE MODULE DU DEPOT QUI JUGE L'EPAISSEUR, PAS LE GENERATEUR. Deux fois de suite
	# j'ai reecrit la regle en Python et deux fois elle etait fausse -- d'abord « courses de
	# meme valeur » au lieu de « courses par silhouette », puis des courses de bord laissees
	# libres alors que la marge de vide les TERMINE. Le compte de silhouettes l'a dit chaque
	# fois : 34 rencontrees pour 27 au vocabulaire. On pose donc le relief dans sa marge, et
	# on demande a `Thickness` -- celui-la meme que le pinceau consulte -- s'il est epais.
	var refuses: int = 0
	for n: int in range(from, upto):
		_injected = _framed(String(all[n]).split("\n", false))
		if not Thickness.thin_cells(_injected).is_empty():
			refuses += 1
			continue
		_current = n
		_run("L3/F2")
		if n % maxi(1, (upto - from) / 10) == 0 or n == upto - 1:
			print("  %8d / %d reliefs : %d tuiles de surface, %d roles   (+%d)"
					% [n + 1, all.size(), _vocab_seen.size(), _vocab_roles.size(),
					_vocab_seen.size() - mark])
			mark = _vocab_seen.size()
	print("  DOMAINE EPUISE : %d tuiles de surface, %d roles de robe   -- TOTAL %d"
			% [_vocab_seen.size(), _vocab_roles.size(),
			_vocab_seen.size() + _vocab_roles.size()]
			+ "   (%d relief(s) refuse(s) comme FINS par Thickness)" % refuses)
	var keys: Array[int] = []
	keys.assign(_vocab_seen.keys())
	keys.sort()
	var said: PackedStringArray = PackedStringArray()
	for key: int in keys:
		said.append(str(key))
	print("  TUILES: %s" % ",".join(said))
	var found: PackedStringArray = PackedStringArray()
	for role: Vector2i in _vocab_roles.keys():
		found.append("%d.%d" % [role.x, role.y])
	found.sort()
	print("  ROLES: %s" % ",".join(found))
	var temoins: PackedStringArray = PackedStringArray()
	for key: int in _witness_of.keys():
		temoins.append("%d=%d" % [key, int(_witness_of[key])])
	temoins.sort()
	print("  TEMOINS: %s" % ",".join(temoins))


## LA MARGE QUE LE MODELE EXIGE, POSEE AUTOUR D'UNE FENETRE. Une chute dans le vide descend de
## STOREY_TILES x (etage + 1) ; une robe coupee par le cadre laisserait un contour ouvert, et ce
## serait un defaut du MONDE, pas du dessin.
func _framed(rows: PackedStringArray) -> PackedStringArray:
	var top: int = 0
	for row: String in rows:
		for i: int in range(row.length()):
			if row[i] != "~":
				top = maxi(top, int(row[i]))
	var edge: int = 3
	var below: int = Walls.STOREY_TILES * (top + 1) + edge
	var wide: int = rows[0].length() + 2 * edge
	var empty: String = ""
	for x: int in range(wide):
		empty += "~"
	var out: PackedStringArray = PackedStringArray()
	for row: int in range(edge):
		out.append(empty)
	for row: String in rows:
		out.append("~~~" + row + "~~~")
	for row: int in range(below):
		out.append(empty)
	return out


func _blocks(levels: Array[int], alphabet: int, blocks: int, rows: int) -> PackedStringArray:
	var side: int = 3
	var wide: int = side * blocks
	var high: int = side * rows
	var edge: int = 3
	var below: int = Walls.STOREY_TILES * alphabet + edge
	var out: PackedStringArray = PackedStringArray()
	var empty: String = ""
	for x: int in range(wide + 2 * edge):
		empty += "~"
	for row: int in range(edge):
		out.append(empty)
	for y: int in range(high):
		var line: String = ""
		for x: int in range(edge):
			line += "~"
		for x: int in range(wide):
			@warning_ignore("integer_division")
			var level: int = levels[(y / side) * blocks + (x / side)]
			line += "~" if level == 0 else str(level - 1)
		for x: int in range(edge):
			line += "~"
		out.append(line)
	for row: int in range(below):
		out.append(empty)
	return out


func _world(level: int) -> PackedStringArray:
	if not _injected.is_empty():
		return _injected
	# ⚠ ET LE MONDE PEUT ETRE LE GUIDE, pour savoir s'il porte encore tout le vocabulaire.
	# La planche de preuve est batie POUR l'exercer ; le guide, lui, est ce que l'acheteur
	# peindra -- s'il ne porte pas une tuile, cette tuile est impeignable.
	if _world_name.begins_with("battue"):
		return _battue(_world_name)
	if _world_name == "guide":
		_board = HeightMask.read(Modes.guide_path(Modes.EPAIS))
		return _board
	# ⚠ ET A L5 C'EST LA PLANCHE DUALE, PAS CELLE DES CASES. Le depot en a une pour chaque
	# famille -- « les deux planches sortent de la meme fonction » -- et le banc bâtissait la
	# mauvaise : 13 formes a cheval sur 15, les deux manquantes etant justement les contacts
	# diagonaux, que la canonicalisation du blob JETTE. Un monde bati pour un vocabulaire
	# n'exerce pas l'autre, et c'est ecrit au dossier depuis longtemps.
	_board = _with_margin(ProofScene.relief(
			Families.BY_CORNER if level >= 5 else Families.BY_CELL))
	# ⚠ L3 NE CHANGE PAS LE MONDE, IL CHANGE CE QU'ON Y POSE. La planche porte deja les trois
	# especes de pose arriere -- l'atterrissage (le sous-pied), l'ecretage (la pose derriere,
	# c'est la paire de piliers ajoutee pour ca), et la levre (le chapiteau sous sa levre).
	# Un monde de plus ne prouverait rien de plus ; ce qui manquait, c'est la POSE.
	if level >= 1 and level <= 5:
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


# ------------------------------------------------------- LE RECENSEMENT DES JONCTIONS

## CE QUE LE MONDE PEUT METTRE EN FACE D'UNE TUILE.
##
## ⚠ C'EST LA MESURE QUI MANQUAIT A LA QUESTION DU VOCABULAIRE. Il ne grossit pas a cause du
## trait : il grossit d'un bit a chaque JONCTION que le modele sait produire et qu'une tuile ne
## sait pas reconnaitre. Si le nombre de jonctions distinctes est fini et se calcule, le
## vocabulaire a une forme fermee ; sinon, c'est la qu'une clause de grammaire doit mordre --
## sur les RENCONTRES, pas sur la forme du relief.
##
## ⚠ ET CE QUI COMPTE N'EST PAS LE NOMBRE DE JONCTIONS, C'EST LE NOMBRE DE COUPLES (TUILE,
## COTE) QUI EN VOIENT PLUSIEURS. Un cote qui ne voit jamais qu'une seule chose n'a rien a
## savoir : il n'a pas besoin de bit. Un cote qui en voit deux doit choisir, donc payer.
func _junctions(world: PackedStringArray, indices: Dictionary, roles: Dictionary,
		under: Dictionary) -> Dictionary:
	var kinds: Dictionary = {}
	var seen: Dictionary = {}
	var contexts: Dictionary = {}
	var total: int = 0
	for cell: Vector2i in indices.keys():
		var mine: int = HeightMask.level_at(world, cell.x, cell.y)
		var faces: PackedStringArray = PackedStringArray()
		for side: int in range(4):
			var probe: Vector2i = cell + STEPS[side]
			var kind: String = "vide"
			if roles.has(probe):
				var role: Vector2i = roles[probe]
				if role.y == Walls.ROW_CROWN:
					kind = "face, chapiteau"
				elif role.y == Walls.ROW_FOOT:
					kind = "face, pied"
				else:
					kind = "face, corps"
			elif indices.has(probe):
				var there: int = HeightMask.level_at(world, probe.x, probe.y)
				if there == mine:
					kind = "sol, meme etage"
				elif there < mine:
					kind = "sol, plus bas"
				else:
					kind = "sol, plus haut"
			# ⚠ ET LA POSE ARRIERE COMPTE, parce qu'elle change ce qu'on voit derriere une
			# transparence -- c'est exactement ce que I6 mesure.
			if under.has(probe):
				kind += " + pose"
			var label: String = "%s : %s" % [SIDE_NAMES[side], kind]
			kinds[label] = int(kinds.get(label, 0)) + 1
			total += 1
			var who: String = "%d/%d" % [int(indices[cell]) & 0xff, side]
			if not seen.has(who):
				seen[who] = {}
			(seen[who] as Dictionary)[kind] = true
			faces.append(kind)
		# ⚠ ET LE PARI DU RECENSEMENT SE VERIFIE ICI, PARCE QU'IL EST FALSIFIABLE. Le plan
		# ecrit que « la forme fermee est le PRODUIT, sur les quatre cotes, du nombre de
		# classes que chacun doit distinguer ». Ce produit n'a de sens que si la tuile posee
		# est une FONCTION de (silhouette, les quatre especes en face) : si un meme contexte
		# recoit deux tuiles differentes, alors la tuile depend d'autre chose que du
		# voisinage par cote, et aucun produit ne la compte.
		#
		# On range donc chaque case sous son contexte et on regarde combien de tuiles
		# distinctes chaque contexte recoit. Un seul contexte a deux tuiles suffit a refuter.
		var context: String = "%d|%s" % [int(indices[cell]) & 0xff, "|".join(faces)]
		if not contexts.has(context):
			contexts[context] = {}
		(contexts[context] as Dictionary)[int(indices[cell])] = true
		# ⚠ ET ON PEUT SORTIR LA TABLE BRUTE, parce que la question suivante ne se repond pas
		# d'un compteur : COMBIEN DE CLASSES CHAQUE COTE DOIT-IL VRAIMENT DISTINGUER ? Deux
		# especes qui donnent toujours la meme tuile sont interchangeables -- les fusionner ne
		# coute RIEN, et c'est exactement la restriction gratuite qu'on cherche. Le banc ne
		# juge pas ca : il rend ce qu'il a vu, et l'analyse se fait a cote.
		if not _dump.is_empty():
			_local[cell] = "%d|%s" % [int(indices[cell]) & 0xff, "|".join(faces)]
	var forced: int = 0
	var worst: int = 0
	for who: String in seen.keys():
		var many: int = (seen[who] as Dictionary).size()
		worst = maxi(worst, many)
		if many > 1:
			forced += 1
	# ⚠ ET CE QUE COUTENT LES BITS DE SECOND ORDRE, puisque ce sont eux qui font l'exception.
	# `nu/roche` et `NORTH_QUIET` demandent CE QU'IL Y A EN FACE : ils sont une fonction de
	# l'espece, donc le produit les compte. Les quatre autres demandent CE QUE MA VOISINE A
	# DECIDE DE TRACER -- une information du second ordre, absente de l'alphabet des especes,
	# et c'est exactement elle qui fait eclater les contextes. On compte donc le vocabulaire
	# deux fois : tel quel, et une fois ces quatre bits effaces.
	# ⚠ LE RAYON DE DEPENDANCE : LA QUESTION QUI DECIDE S'IL Y A UNE FERMETURE. Les contextes
	# eclates sont tous des bits de SECOND ORDRE -- ils demandent ce que la voisine a decide de
	# tracer, et sa decision depend de SA voisine. Une chaine, pas une fenetre : rien ne
	# garantit qu'elle s'arrete, et la borne monte a chaque monde de plus.
	#
	# On sort donc, pour chaque case, SON contexte et celui de ses quatre voisines. Si les
	# contextes eclates au rayon 1 se resolvent au rayon 2, la dependance est BORNEE, donc
	# enumerable, donc close. S'ils survivent, c'est la cascade -- et il faudra changer la
	# decomposition, pas chercher plus loin.
	if not _dump.is_empty():
		for cell: Vector2i in _local.keys():
			var around: PackedStringArray = PackedStringArray()
			for side: int in range(4):
				around.append(String(_local.get(cell + STEPS[side], "hors")))
			_dumped.append("%d\t%s\t%s" % [int(indices[cell]), String(_local[cell]),
					"\t".join(around)])
		var out: FileAccess = FileAccess.open(_dump, FileAccess.WRITE)
		if out != null:
			out.store_string("\n".join(_dumped) + "\n")
			out.close()
			print("  table brute ecrite : %s  (%d lignes)" % [_dump, _dumped.size()])
	var second: int = ABOVE_QUIET_EAST | ABOVE_QUIET_WEST | BELOW_QUIET_EAST 			| BELOW_QUIET_WEST | NORTH_FLUSH_EAST | NORTH_FLUSH_WEST
	# ⚠ ET ON COMPTE SUR TOUS LES ETAGES, PAS SUR LA CARTE VISIBLE. Le vocabulaire est ce que
	# l'assemblage POSE, et il pose une tuile par etage et par case : compte sur les seules
	# cases visibles, il annoncait 45 la ou le banc en peint 59. Un compteur qui ne mesure pas
	# ce qu'il pretend mesurer est pire que pas de compteur.
	var whole: Dictionary = {}
	var first: Dictionary = {}
	for storey: Dictionary in _storeys:
		for cell: Vector2i in storey.keys():
			whole[int(storey[cell])] = true
			first[int(storey[cell]) & ~second] = true

	# Combien de contextes recoivent PLUSIEURS tuiles, et le pire d'entre eux.
	var split: int = 0
	var most: int = 1
	var example: String = ""
	for context: String in contexts.keys():
		var many: int = (contexts[context] as Dictionary).size()
		if many > 1:
			split += 1
			if many > most or example.is_empty():
				most = many
				var which: Array[String] = []
				for key: Variant in (contexts[context] as Dictionary).keys():
					which.append("%d (silhouette %d, bits %d)"
							% [int(key), int(key) & 0xff, int(key) >> 8])
				which.sort()
				example = "%s  ->  %s" % [context, ", ".join(which)]
	return {"kinds": kinds, "total": total, "couples": seen.size(), "forces": forced,
			"pire": worst, "contextes": contexts.size(), "eclates": split,
			"plus": most, "temoin": example, "entier": whole.size(),
			"premier": first.size()}


# ------------------------------------------------------------ L5 : LA FAMILLE A CHEVAL





# ------------------------------------------------------------------ LE DESSIN





































# ------------------------------------------------------------------ L4 : LES RACCORDS









# ------------------------------------------------------------------ LES CINQ INVARIANTS

func _measure(image: Image, world: PackedStringArray, indices: Dictionary, tiles: Dictionary,
		freedom: int, roles: Dictionary, under: Dictionary = {}, role_tiles: Dictionary = {},
		bare: Image = null, cover: Image = null, level: int = 0,
		who: Image = null) -> Dictionary:
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
	var open_ends: int = 0
	var buried_ends: int = 0
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
			# ⚠ UNE EXTREMITE NOYEE DANS LA MATIERE N'EST PAS UN TROU. Un trait qui s'arrete
			# contre du vide laisse le contour ouvert : on voit le fond a travers. Un trait qui
			# s'arrete au milieu de la matiere est OCCULTE -- la terrasse passe derriere la
			# falaise, et son contour reprend de l'autre cote. On compte les deux separement
			# AVANT de decider si la distinction vaut quelque chose.
			var breathes: bool = false
			for dy2: int in range(-1, 2):
				for dx2: int in range(-1, 2):
					if x + dx2 < 0 or y + dy2 < 0 or x + dx2 >= width or y + dy2 >= height:
						breathes = true
						continue
					if image.get_pixel(x + dx2, y + dy2).a < 0.5:
						breathes = true
			if breathes:
				open_ends += 1
			else:
				buried_ends += 1
			# ⚠ ET A CHEVAL, LE PIXEL SE RANGE PAR CROISEMENT, PAS PAR CASE. Les tuiles y sont
			# decalees d'un demi-pas : lire `x / RES` designe la case, donc une AUTRE tuile que
			# celle qui porte le pixel, et le releve accuse une innocente. Trois lectures au
			# pixel perdues avant de s'en apercevoir.
			var cell: Vector2i = Vector2i(x / RES, y / RES)
			if level >= 5:
				cell = Vector2i((x + RES / 2) / RES, (y + RES / 2) / RES)
			var owner: int = int(indices.get(cell, -1))
			if ends.size() < 14:
				ends.append("%d,%d de la case %d,%d (tuile %d)"
						% [x % RES, y % RES, cell.x, cell.y, owner])
			# LA DISTRIBUTION. Trois hypotheses raisonnees sur ces extremites, trois fois
			# faux : on arrete de deviner et on compte. Chaque extremite se range par le
			# BORD ou elle se trouve, par ce que porte SA case, et par ce que porte la case
			# de l'autre cote de ce bord.
			var at_x: int = x % RES if level < 5 else (x + RES / 2) % RES
			var at_y: int = y % RES if level < 5 else (y + RES / 2) % RES
			var side: int = -1
			if at_y == 0:
				side = 0
			elif at_x == RES - 1:
				side = 1
			elif at_y == RES - 1:
				side = 2
			elif at_x == 0:
				side = 3
			# ⚠ ET LES ROBES RESTENT PAR CASE, MEME A CHEVAL. Les chercher au croisement les
			# rend toutes invisibles, et le releve annonce « surface » partout.
			var home: Vector2i = Vector2i(x / RES, y / RES)
			var mine_kind: String = "robe" if roles.has(home) else "surface"
			var label: String = ""
			if side < 0:
				label = "%s, en plein milieu" % mine_kind
			else:
				var probe: Vector2i = home + STEPS[side]
				var kind: String = "vide"
				if roles.has(probe):
					kind = "robe"
				elif indices.has(cell + STEPS[side]):
					kind = "surface"
				label = "%s, bord %s, en face : %s" % [mine_kind, SIDE_NAMES[side], kind]
			spread[label] = int(spread.get(label, 0)) + 1
			# ⚠ ET ON DIT CE QUE LA TUILE TRACE, PAS SEULEMENT OU ELLE EST. Un compte par bord
			# range les defauts ; il ne dit pas POURQUOI le trait s'arrete. La reponse est
			# toujours dans ce que la case et sa vis-a-vis ont decide de tracer -- et c'est
			# `_surface_open` qui repond, la seule source.
			if _why and end_count <= 24:
				print("     %d,%d de %d,%d : %s | voisines %s"
						% [at_x, at_y, cell.x, cell.y, _tells(cell, indices, roles, freedom),
						_around(cell, indices, roles, freedom)])
				# ⚠ ET LA PILE, parce que c'est elle qui fuit. Un etage ENTERRE trace son bord
				# sous le sommet, et on le voit par l'encoche de celui-ci : dire seulement la
				# tuile visible, c'est accuser celle qui n'a rien fait.
				var deep2: PackedStringArray = PackedStringArray()
				for storey5: int in range(_storeys.size()):
					var map5: Dictionary = _storeys[storey5]
					if map5.has(cell):
						deep2.append("etage %d: %s" % [storey5,
								_tells_key(int(map5[cell]), freedom)])
				print("          pile  %s" % " ; ".join(deep2))

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
				var said2: String = "%d,%d de la case %d,%d" % [x % RES, y % RES, at.x, at.y]
				# ⚠ ET ON DIT QUELLE COUCHE POSE CHACUN DES QUATRE PIXELS. « Trois hypotheses
				# raisonnees, trois fois faux » : un pave se lit, il ne se devine pas.
				if who != null:
					var four: Array[String] = []
					for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1),
							Vector2i(1, 1)]:
						four.append(Compose.layer_name(who.get_pixel(x + d.x, y + d.y).r8))
					said2 += " [" + ", ".join(four) + "]"
				thick_where.append(said2)
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
	var stacked: Dictionary = _layer_claims(image, who) if who != null 			else {"vues": 0, "muettes": 0, "doubles": 0, "couples": {}}
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
	# ⚠ LE PROFIL D'UNE TUILE A CHEVAL EST CELUI DE SA FRONTIERE INTERNE. Ses quatre cotes sont
	# a moitie pleins par construction ; leur demander leur profondeur ne mesure rien. Ce qui a
	# une position, chez elle, c'est l'axe entre deux quadrants -- et c'est ca que la liberte
	# ferait bouger.
	if level >= 5:
		for key: Variant in tiles.keys():
			for vertical: int in range(2):
				var line2: String = _corner_profile(tiles[key] as Image, vertical == 0,
						int(key) >> 4, freedom)
				if line2.is_empty():
					continue
				profiles[line2] = true
				var cut2: PackedStringArray = line2.split(",")
				for i: int in range(1, cut2.size()):
					if cut2[i] != cut2[0]:
						wavy += 1
						break
	for key: Variant in tiles.keys():
		if level >= 5:
			break
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
			if level >= 5:
				# ⚠ A CHEVAL, LA LIBERTE LATERALE EST GLOBALE, PAS PAR TUILE -- theoreme de la
				# famille, voir `_corner_shift`. La promesse juste est donc « un profil plat,
				# mais DEPLACE » : un seul, sans ondulation, et ailleurs qu'au milieu.
				promised = "un profil plat, mais deplace"
				# ⚠ ET LE TEMOIN DU MILIEU SE LIT REPLIE LUI AUSSI : un axe plat non deplace
				# rend la seule valeur `RES / 2 - 1`. Le comparer a la forme longue le rendrait
				# introuvable, et le garde-fou anti-triche ne garderait plus rien.
				i5 = profiles.size() == 1 and wavy == 0 						and not profiles.has(str(RES / 2 - 1))
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
			if roles.has(cell):
				continue
			var named: Image = role_tiles[Compose.wall_key(under[cell])] as Image
			for x: int in range(RES):
				# ⚠ ET L'ENCOCHE NORD NE REGARDE PAS VERS LE BAS, ELLE REGARDE VERS LE NORD.
				# Une pose arriere remplit les marges ou le modele met la face -- au sud et sur
				# les flancs. Au-dessus du bord nord de la case qui la couvre, ce que le monde a
				# n'est pas la face : c'est le sol plus au nord, ou le vide. Y exiger de la
				# roche accuserait le dessin d'etre juste -- et sans ce recadrage la roche y
				# sortait avec un bord que personne ne trace.
				var above: int = 0
				while above < RES and cover.get_pixel(cell.x * RES + x,
						cell.y * RES + above).a < 0.5:
					above += 1
				for y: int in range(RES):
					if cover.get_pixel(cell.x * RES + x, cell.y * RES + y).a >= 0.5 							or y < above:
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
				"dit": "%d extremites (%d au bord du vide, %d noyees) %s"
				% [end_count, open_ends, buried_ends, str(ends)]
				+ "   (%d morceaux, %d massifs, %d trous)" % [strokes, massifs, holes]},
		"I2": {"nom": "epaisseur", "ok": thick == 0,
				"dit": "%d pave(s) 2x2 de trait %s" % [thick, str(thick_where)]},
		# ⚠ ET LES FRONTIERES ENTRE COUCHES SONT AFFICHEES, PAS ASSERTEES -- pour l'instant, et
		# la raison compte. Elles accusent une dette qui PREEXISTE a la mesure : 116
		# doublements sur le modele livre, que personne n'avait jamais regardes parce que
		# l'ancien I3 ne juge que les frontieres d'une meme case. Les mettre au verdict
		# rendrait les vingt-six couples rouges d'un coup, y compris ceux qui n'ont pas bouge,
		# et une echelle toujours rouge ne dit plus si un correctif a servi. C'est le meme
		# statut que la couverture du guide tant qu'elle etait un travail en cours : « affiche,
		# pas asserte » -- et ca redevient une assertion le jour ou la dette est payee.
		"I3": {"nom": "unicite", "ok": i3,
				"dit": "%d frontieres (pile max %d), %d doubles, %d muettes, %d parasites"
				% [int(claims["frontieres"]), int(claims["pile"]), int(claims["doubles"]),
				int(claims["muettes"]), int(claims["parasites"])]
				# ⚠ ET LES FRONTIERES ENTRE COUCHES SE DISENT A PART, parce qu'elles ne se
				# comptent pas dans la meme unite : les premieres sont des ARETES DE CASE,
				# celles-ci des PAIRES DE PIXELS. Les additionner ferait un nombre qui ne
				# veut rien dire.
				+ "  -- entre couches : %d vues, %d doubles %s" % [int(stacked["vues"]),
				int(stacked["doubles"]), str(stacked["couples"])]
				+ ("  " + str(claims["ou"]) if not i3 else "")},
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
## I3, ELARGI AUX COUCHES : les frontieres qui vivent A L'INTERIEUR d'une case.
##
## ⚠ L'ANCIEN I3 NE POUVAIT PAS LES VOIR, et ce n'est pas un oubli : il marche de case en case,
## et demande qui trace l'arete PARTAGEE par deux cases. Or depuis que la tuile de levre porte
## le haut de sa propre face, deux COUCHES se rencontrent dans la meme case -- le bandeau de
## roche par-dessus l'etage enterre -- et cette frontiere-la n'a jamais eu de juge. I2 la
## compte quand elle double, sans pouvoir dire entre qui ; I3 l'ignorait.
##
## La regle ne change pas d'un mot : exactement un tracant par frontiere. Ce qui change est ou
## on la cherche -- entre deux pixels voisins poses par des couches DIFFERENTES.
##
## ⚠ ET DEUX COUCHES VOISINES NE FONT PAS TOUJOURS UNE FRONTIERE. De l'herbe posee par l'etage
## enterre a cote de l'herbe de la surface, c'est la meme matiere : rien a tracer. On exige donc
## que la MATIERE change aussi -- herbe contre roche, ou matiere contre rien.
func _layer_claims(image: Image, who: Image) -> Dictionary:
	var seen: int = 0
	var mute: int = 0
	var double: int = 0
	var pairs: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			for side: int in [1, 2]:
				var to: Vector2i = Vector2i(x, y) + STEPS[side]
				if to.x >= image.get_width() or to.y >= image.get_height():
					continue
				var a: int = int(round(who.get_pixel(x, y).r * 255.0))
				var b: int = int(round(who.get_pixel(to.x, to.y).r * 255.0))
				if a == b:
					continue
				var pa: Color = image.get_pixel(x, y)
				var pb: Color = image.get_pixel(to.x, to.y)
				var ta: bool = _is_stroke(image, x, y)
				var tb: bool = _is_stroke(image, to.x, to.y)
				var ma: String = "rien" if pa.a < 0.5 else ("trait" if ta
						else ("roche" if pa.is_equal_approx(Contour.ROCK) else "herbe"))
				var mb: String = "rien" if pb.a < 0.5 else ("trait" if tb
						else ("roche" if pb.is_equal_approx(Contour.ROCK) else "herbe"))
				if not ta and not tb and ma == mb:
					continue
				seen += 1
				var claimants: int = (1 if ta else 0) + (1 if tb else 0)
				if claimants == 0:
					mute += 1
				elif claimants > 1:
					double += 1
					var name: String = "%s | %s" % [Compose.layer_name(mini(a, b)),
							Compose.layer_name(maxi(a, b))]
					pairs[name] = int(pairs.get(name, 0)) + 1
	return {"vues": seen, "muettes": mute, "doubles": double, "couples": pairs}


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
			# ⚠ ET ON REGARDE CHEZ LA VOISINE MEME QUAND ELLE EST HORS DU MONDE. « Pas de case
			# la » n'est pas « pas de pixels la » : l'image, elle, couvre toute la grille. Le
			# garde `beyond >= 0` confondait les deux, et a cheval ca se paie -- l'axe d'une
			# tuile de croisement se DEPLACE au-dela du bord de case, donc le trait d'une
			# frontiere contre le vide est peint DANS le carre de la case vide. La sonde ne le
			# trouvait pas et declarait la frontiere muette : 26 fausses muettes sur `@battue1`,
			# pour un trait parfaitement present a deux pixels de la.
			#
			# ⚠ ET ELARGIR UNE SONDE NE PEUT QUE RENDRE LA MESURE PLUS SEVERE, JAMAIS PLUS
			# COMPLAISANTE : on ajoute un revendiquant possible, donc une muette peut devenir
			# juste et une juste peut devenir DOUBLE. Dans la famille par case, ou le trait ne
			# rentre que chez lui, la sonde ne trouve rien de plus -- c'est le rejeu qui le dit.
			if probe.x >= 0 and probe.y >= 0 and probe.x < width and probe.y < height:
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
## CE QU'UNE CASE TRACE, EN CLAIR -- pour lire une extremite au lieu de la deviner.
func _tells_key(key: int, freedom: int) -> String:
	var open2: Array[bool] = Brink.surface_open(key, 2)
	var sides2: PackedStringArray = PackedStringArray()
	for side: int in range(4):
		if open2[side]:
			sides2.append(SIDE_NAMES[side])
	return "%d (silhouette %d, bord %d) [%s]" % [key, key & 0xff, key >> 8, ", ".join(sides2)]


func _tells(cell: Vector2i, indices: Dictionary, roles: Dictionary, freedom: int) -> String:
	if roles.has(cell):
		var role: Vector2i = roles[cell]
		var open: Array[bool] = Contour.wall_open(roles[cell])
		var sides: PackedStringArray = PackedStringArray()
		for side: int in range(4):
			if open[side]:
				sides.append(SIDE_NAMES[side])
		return "ROBE pan %d rangee %d, trace [%s]" % [role.x, role.y, ", ".join(sides)]
	if not indices.has(cell):
		return "RIEN"
	var key: int = int(indices[cell])
	var level: int = 2 if freedom >= 0 else 2
	var open2: Array[bool] = Brink.surface_open(key, level)
	var sides2: PackedStringArray = PackedStringArray()
	for side: int in range(4):
		if open2[side]:
			sides2.append(SIDE_NAMES[side])
	return "surface %d (silhouette %d, bord %d), trace [%s]" % [key, key & 0xff, key >> 8,
			", ".join(sides2)]


func _around(cell: Vector2i, indices: Dictionary, roles: Dictionary, freedom: int) -> String:
	var said: PackedStringArray = PackedStringArray()
	for side: int in range(4):
		said.append("%s: %s" % [SIDE_NAMES[side],
				_tells(cell + STEPS[side], indices, roles, freedom)])
	return " ; ".join(said)


## LE PROFIL DE LA FRONTIERE INTERNE d'une tuile a cheval : pour chaque rangee (ou colonne), ou
## se trouve le trait. Vide s'il n'y en a pas de ce sens-la.
## Un profil plat a la position donnee, pour le comparer.
func _flat(at: int) -> PackedStringArray:
	var said: PackedStringArray = PackedStringArray()
	for i: int in range(RES):
		said.append(str(at))
	return said




## Cette ligne reste-t-elle du meme cote de l'axe perpendiculaire sur toute sa longueur ?
func _straddles(along: int, vertical: bool, quiet: int, freedom: int) -> bool:
	var first: bool = false
	for step: int in range(RES):
		var axis: int = Contour.corner_axis(step, not vertical, quiet, freedom)
		var side: bool = along > axis
		if step == 0:
			first = side
		elif side != first:
			return true
	return false


## ⚠ ET UNE LIGNE QUI CHANGE DE COTE NE SE PROFILE PAS. Le pincage met l'axe perpendiculaire
## a deux endroits selon la moitie ; une ligne situee ENTRE les deux passe d'un quadrant a
## l'autre en chemin, et la premiere transition qu'on y rencontre est LA MARCHE DU PINCAGE,
## pas l'axe qu'on croit mesurer. Meme espece d'artefact que la longueur de chaine : la
## fonction rendait une valeur qui ne repond pas a la question posee.
func _corner_profile(tile: Image, vertical: bool, quiet: int = 0, freedom: int = 0) -> String:
	# ⚠ ON SUIT LA TRANSITION DE MATIERE, PAS LE PREMIER PIXEL DE TRAIT. Chercher le trait
	# trouve celui de l'AUTRE orientation quand la sienne n'existe pas -- et une frontiere que
	# le bit vient de faire taire n'a pas de trait du tout, alors que sa matiere, elle, est
	# toujours la. C'est la position de la matiere que la liberte ferait bouger.
	var said: PackedStringArray = PackedStringArray()
	var found: bool = false
	for along: int in range(RES):
		var owned: int = (1 if along < RES / 2 else 2) if vertical \
				else (4 if along < RES / 2 else 8)
		if (quiet & owned) != 0:
			continue
		if _straddles(along, vertical, quiet, freedom):
			continue
		var at: int = -1
		for step: int in range(RES - 1):
			var here: bool = tile.get_pixel(step if vertical else along,
					along if vertical else step).a >= 0.5
			var next: bool = tile.get_pixel(step + 1 if vertical else along,
					along if vertical else step + 1).a >= 0.5
			if here != next:
				at = step
				found = true
				break
		if at < 0:
			# ⚠ ET ON NE PROFILE QU'UNE FRONTIERE ENTIERE. Une demi-frontiere -- un seul
			# quadrant plein -- n'existe que sur la moitie de l'axe ; melanger les deux
			# longueurs compte des profils la ou il n'y a qu'une forme de tuile. Meme regle
			# que dans la famille par case, ou l'on ne profile pas un cote qui ne trace pas.
			return ""
		# ⚠ ET ON REPLIE LES REPETITIONS : le profil est la SUITE DES POSITIONS DISTINCTES,
		# pas une valeur par rangee. Sans ce repli, deux tuiles dont l'axe est au meme endroit
		# mais qui ne possedent pas les memes rangees rendent deux chaines de longueurs
		# differentes -- donc deux profils la ou il n'y a qu'une forme. Mesure : L5/F0, ou
		# rien ne bouge, passait a DEUX profils et rougissait un couple ACQUIS. Replie, un axe
		# plat rend une seule valeur, un axe qui ondule en rend plusieurs, et la mesure ne
		# depend plus de ce que la tuile possede.
		if said.is_empty() or said[said.size() - 1] != str(at):
			said.append(str(at))
	return ",".join(said) if found else ""


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
