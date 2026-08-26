# L'EXPORT — la feuille de tuiles, et rien d'autre que ce qui a ete peint.
#
# Deux familles, deux planches. Un terrain Wang resout les coins d'un plan ; une falaise
# sort du plan. Les melanger dans une seule image obligerait celui qui la relit a savoir ou
# l'une s'arrete et ou l'autre commence -- c'est exactement ce que Satyron fait en gardant
# `icko_tileset.tres` d'un cote et `cliff_kits.tres` de l'autre.
#
# ⚠ L'EXPORT REFUSE UNE FEUILLE INCOMPLETE (charte, regle 5). Il ne reste pas des trous
# transparents en esperant que personne ne s'en serve : il rend la liste de ce qui manque
# et n'ecrit rien. Un tileset a moitie peint n'est pas un tileset, c'est un piege.
#
# ⚠ UNE TUILE, UN DESSIN, UNE CASE DE PLANCHE. Le guide porte une tuile en beaucoup
# d'exemplaires -- ses JUMELLES -- mais ce ne sont pas des variantes : c'est le meme endroit
# vu plusieurs fois. « Peindre les jumelles » est coche d'emblee, elles portent donc toutes
# le meme dessin. La planche a exactement une case par tuile, et sa taille ne depend pas de
# ce qui a ete peint.
#
# ⚠ CE QUE LES JUMELLES APPORTENT N'EST PAS « PLUSIEURS DESSINS ». C'est que peindre une
# tuile en remplit des dizaines sous les yeux, en temps reel -- l'acheteur voit d'un coup
# d'œil le peu qu'il aura a dessiner. C'est un argument, pas une donnee d'export.
#
# ⚠ ON PREND LA PREMIERE OCCURRENCE PEINTE, quelle que soit sa place dans le guide. Si
# l'utilisateur a peint la troisieme sans peindre la premiere, c'est la troisieme qui sort :
# le rang dans le guide n'a aucun sens pour qui relit la feuille.
#
# LA DISPOSITION EST MECANIQUE, ET LE MANIFESTE LA REDIT QUAND MEME. Les 47 index rangent
# en ordre croissant, huit par rangee ; les 12 robes tombent naturellement en 3 pans x 4
# rangees, la forme meme du vocabulaire. Un lecteur pourrait recalculer chaque case a partir
# de la regle, mais le manifeste donne la table en clair : le fichier dit ce qui est vrai,
# il n'oblige pas a le redemontrer.
extends RefCounted

const BlobIndex := preload("res://core/blob_index.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Walls := preload("res://core/walls.gd")
const Painting := preload("res://core/painting.gd")
const WorkIO := preload("res://core/work_io.gd")
const Families := preload("res://core/families.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Assembly := preload("res://render/assembly.gd")

const MAGIC: String = "solutiles-tileset"
## LE MANIFESTE EST UN CONTRAT. Il ne decrit pas seulement OU sont les tuiles, il porte la
## REGLE DE POSE. Une seconde moitie du projet posera le monde dans Godot et dans Unity :
## c'est nous qui ecrirons le lecteur, deux fois, et deux lecteurs qui se fient a leur
## memoire finissent toujours par diverger. La regle vit ici, une seule fois.
##
## ⚠ VERSION 8 : LA DECOMPOSITION EN COUCHES. Une tuile ne repond QUE D'ELLE-MEME : elle
## remplit sa case, et ce qui est a cote appartient a la couche du voisin, qui le dessine.
## Trois distinctions tombent avec ca, toutes nees du besoin qu'une tuile SUGGERE son
## voisinage -- le BORD d'une surface (nu ou roche a ce cardinal), et les etats de flanc VIDE
## et DEVANT, qui disaient qui etait en avant. C'est desormais l'ORDRE DE DESSIN qui tranche.
## Le vocabulaire passe de 48 + 44 = 92 tuiles a 27 + 20 = 47.
##
## ⚠ ET LE SENS DE LA V7 A CHANGE SANS QUE SES TUILES CHANGENT DE NOM : un `role 2,1` de la v7
## n'est pas celui de la v8, et une planche v7 posee par un moteur v8 sortirait un monde faux
## SANS UNE SEULE ERREUR. La v7 est donc refusee nommement.
##
## ⚠ VERSION 6 : LE MODE EPAIS EST LE PRODUIT, A MIN TROIS. Rien ne fait une bande
## fine -- une case, pleine OU vide, dont la COURSE (la suite de cases du meme etat
## qui la contient le long d'un axe) fait moins de trois est FINE, dans chaque
## silhouette d'etage, et le pinceau du moteur la refuse : le tileset n'a pas de
## tuile pour elle. Le vocabulaire tombe a 27 index de surface et 25 roles de robe
## (le redan compris -- vide-devant au corps 1, dans les deux sens). Un moteur v5
## poserait des reliefs fins avec des tuiles qui n'existent plus : la version bouge,
## et la v5 est refusee nommement.
##
## ⚠ VERSION 5 : LA POSE DERRIERE. Une robe ecretee passe derriere la case de son etage
## qui l'a coupee, et repose sous elle la rangee du pas suivant -- un corps. Un moteur v4
## ne pose rien la : derriere les coins decoupes de cette case, il montre l'etage d'en
## dessous au lieu de la roche qui continue. Meme espece de changement que le sous-pied
## en v4, meme traitement : la version bouge, et la v4 est refusee nommement.
##
## ⚠ VERSION 4 : LE HORS-CARTE EST DU VIDE, ET LE PIED SE REPOSE DESSOUS.
##
## Deux changements de SENS, et la version n'avait pas bouge -- c'est le defaut qu'on repare
## ici. Le hors-carte valait la plaine, il vaut maintenant le VIDE : un moteur qui lit
## l'ancienne regle etend le sol a l'infini et ne pose jamais la falaise du bord du monde.
## Et une robe qui atterrit repose son pied une case plus bas, sous la surface.
##
## ⚠ UN MANIFESTE V3 D'AVANT ET UN V3 D'APRES DECRIVAIENT DEUX MONDES DIFFERENTS, et le
## plugin les acceptait tous les deux sans broncher : son garde-fou ne refusait que le TROP
## NEUF. Une version qui ne bouge pas quand le sens bouge ne protege de rien.
##
## ⚠ VERSION 3 : LES VARIANTES ONT DISPARU. La planche avait des rangees empilees, une par
## dessin distinct, et le manifeste portait une cle `variants`. Le mot faisait deux metiers
## -- les jumelles du guide et les dessins de la planche -- et le second n'a jamais servi :
## avec « Peindre les jumelles » coche, il valait toujours 1. La planche a desormais une
## taille FIXE, ce qui rend le lecteur trivial. Un systeme de variantes digne de ce nom
## viendra plus tard, et il sera concu pour lui-meme.
const VERSION: int = 8

## Largeur de la planche de surface, en tuiles. 47 n'a pas de forme naturelle -- huit
## colonnes donnent six rangees, et la derniere case reste vide. Elle est dite au manifeste.
const SURFACE_COLUMNS: int = 8

const SUFFIX_SURFACE: String = "_surface.png"
const SUFFIX_WALLS: String = "_walls.png"
const SUFFIX_MANIFEST: String = "_tileset.txt"

## ⚠ CE QUI PROUVE A L'ACHETEUR QU'IL N'EN MANQUE AUCUNE. Une feuille de 47 dessins ne
## montre pas qu'elle est complete : on y voit 47 tuiles, pas l'absence d'une 48e. La
## planche de preuve pose chaque index sur son propre ilot, dans l'ordre de la feuille,
## et peinte avec les tuiles achetees. On peut pointer du doigt.
const SUFFIX_PROOF: String = "_preuve.png"


## Ce que l'export donnerait, et s'il peut avoir lieu.
##
## C'est aussi ce que le bouton d'export interroge pour savoir s'il a le droit de s'ouvrir :
## la barre d'outils et le fichier repondent a la meme fonction, donc ils ne peuvent pas se
## contredire (charte, regle 4).
##
## Cles rendues :
##   surface_source : Dictionary[int, int]      index -> rang de l'occurrence retenue
##   wall_source    : Dictionary[Vector2i, int] role  -> rang de l'occurrence retenue
##   missing_surface : Array[int]
##   missing_wall    : Array[Vector2i]
##   tile_size       : int
##   family          : StringName
##   is_exportable   : bool
static func analyse(painting: Painting, heights: PackedStringArray,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var by_key: Dictionary = WorkIO.cells_by_key(heights, family)
	var letter: String = Families.key_letter(family)

	var surface_source: Dictionary = {}
	var wall_source: Dictionary = {}
	var by_cell: Dictionary = WorkIO.slots(heights, family)
	for cell: Vector2i in painting.painted_cells():
		if not by_cell.has(cell):
			continue
		var slot: Dictionary = WorkIO.describe(String(by_cell[cell]))
		var rank: int = int(slot["rank"])
		if slot["family"] == "S" or slot["family"] == "C":
			_keep(surface_source, int(slot["index"]), rank, letter, painting, by_key)
		elif slot["family"] == "W":
			_keep(wall_source, slot["role"], rank, "W", painting, by_key)

	# ⚠ UNE TUILE N'EST LIVREE QUE SI ELLE A VRAIMENT UN DESSIN A POSER, et pas du seul fait
	# qu'une cle existe au rapport. Une cle irresolue ou une image absente laissait autrefois
	# la liste vide, et le compte annoncait « exportable » pour une case blanche : le rapport
	# disait 15/15 et la planche sortait vide. `_keep` ne retient que ce qui porte une image,
	# donc la presence AU RAPPORT vaut desormais preuve (charte, regle 4).
	var missing_surface: Array[int] = []
	for index: int in Families.surface_indices(family):
		if not surface_source.has(index):
			missing_surface.append(index)
	missing_surface.sort()

	var missing_wall: Array[Vector2i] = []
	# ⚠ La barre est celle du MODE : les 25 roles epais, pas les 36 de la mathematique.
	for role: Vector2i in Families.wall_roles():
		if not wall_source.has(role):
			missing_wall.append(role)

	return {
		"surface_source": surface_source,
		"wall_source": wall_source,
		"missing_surface": missing_surface,
		"missing_wall": missing_wall,
		"tile_size": painting.resolution,
		"family": family,
		"is_exportable": missing_surface.is_empty() and missing_wall.is_empty(),
	}


## Retient l'occurrence qui fournira le dessin de cette tuile.
##
## ⚠ LA PREMIERE PEINTE GAGNE, et une seule est retenue. On garde le plus petit rang pour
## que la feuille ne depende pas de l'ordre dans lequel le carnet a ete parcouru -- un
## dictionnaire ne promet aucun ordre, et un export qui changerait d'une fois sur l'autre
## serait indefendable.
static func _keep(into: Dictionary, tile: Variant, rank: int, letter: String,
		painting: Painting, by_key: Dictionary) -> void:
	if into.has(tile) and int(into[tile]) <= rank:
		return
	var key: String = _key_for(letter, tile, rank)
	if not by_key.has(key) or painting.image_of(by_key[key]) == null:
		return
	into[tile] = rank


## La cle de sauvegarde d'une tuile. Le format appartient a `work_io` ; on le compose ici
## par la meme regle, une seule fois, plutot que de le reecrire a chaque usage.
static func _key_for(letter: String, tile: Variant, rank: int) -> String:
	if letter == "W":
		var role: Vector2i = tile
		return "W%d,%d:%d" % [role.x, role.y, rank]
	return "%s%d:%d" % [letter, int(tile), rank]


## La case de la planche de surface ou tombe l'index [param index].
static func surface_slot(index: int, family: StringName = Families.BY_CELL) -> Vector2i:
	var order: int = Families.surface_indices(family).find(index)
	if order < 0:
		return Vector2i(-1, -1)
	return Vector2i(order % SURFACE_COLUMNS, order / SURFACE_COLUMNS)


## La hauteur de la planche de surface, en tuiles.
static func surface_rows(family: StringName = Families.BY_CELL) -> int:
	var count: int = Families.surface_indices(family).size()
	return (count + SURFACE_COLUMNS - 1) / SURFACE_COLUMNS


## La case de la planche de robes. Le pan donne la colonne, la rangee donne la rangee :
## la planche EST le bloc 3 x 4 du vocabulaire, sans traduction.
static func wall_slot(role: Vector2i) -> Vector2i:
	return role


## Compose une planche. Rend null si rien n'est a poser.
static func compose(painting: Painting, heights: PackedStringArray, report: Dictionary,
		walls: bool) -> Image:
	var family: StringName = report.get("family", Families.BY_CELL)
	var side: int = painting.resolution
	var columns: int = Walls.PAN_COUNT if walls else SURFACE_COLUMNS
	var rows: int = Walls.BLOCK_ROWS if walls else surface_rows(family)
	if columns <= 0 or rows <= 0:
		return null

	var sheet: Image = Image.create_empty(columns * side, rows * side, false, Image.FORMAT_RGBA8)
	sheet.fill(Painting.TRANSPARENT)

	var by_key: Dictionary = WorkIO.cells_by_key(heights, family)
	var table: Dictionary = report["wall_source"] if walls else report["surface_source"]
	for tile: Variant in table.keys():
		var letter: String = "W" if walls else Families.key_letter(family)
		var key: String = _key_for(letter, tile, int(table[tile]))
		var at: Vector2i = wall_slot(tile) if walls else surface_slot(int(tile), family)
		if at.x < 0 or not by_key.has(key):
			continue
		var image: Image = painting.image_of(by_key[key])
		if image == null:
			continue
		sheet.blit_rect(image, Rect2i(0, 0, side, side), at * side)
	return sheet


## Le manifeste : ce que contiennent les deux planches, en clair.
static func manifest(report: Dictionary, mode_id: StringName, basename: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s %d" % [MAGIC, VERSION])
	lines.append("mode %s" % mode_id)
	lines.append("tile_size %d" % int(report["tile_size"]))

	var family: StringName = report.get("family", Families.BY_CELL)
	_spec(lines, family)

	lines.append("")
	lines.append("surface %s %d %d" % [basename + SUFFIX_SURFACE, SURFACE_COLUMNS,
			surface_rows(family)])
	lines.append("famille %s" % family)
	lines.append("# les %d index de la famille, en ordre croissant, huit par rangee ; les"
			% Families.surface_tile_count(family))
	lines.append("# cases qui restent en fin de planche sont vides.")
	var indices: Array[int] = []
	for index: int in report["surface_source"].keys():
		indices.append(index)
	indices.sort()
	for index: int in indices:
		var slot: Vector2i = surface_slot(index, family)
		lines.append("index %d slot %d,%d  # %s" % [index, slot.x, slot.y,
				Families.describe(family, index)])

	lines.append("")
	lines.append("proof %s" % [basename + SUFFIX_PROOF])
	lines.append("# chaque index sur son propre ilot, dans l'ordre de la planche de surface :")
	lines.append("# la preuve qu'il n'en manque aucun, peinte avec ces tuiles-ci.")

	lines.append("")
	lines.append("walls %s %d %d" % [basename + SUFFIX_WALLS, Walls.PAN_COUNT, Walls.BLOCK_ROWS])
	lines.append("# %d pans (le couple des deux flancs) x %d rangees = %d tuiles."
			% [Walls.PAN_COUNT, Walls.BLOCK_ROWS, Walls.ALL_ROLES.size()])
	for role: Vector2i in Walls.ALL_ROLES:
		if not report["wall_source"].has(role):
			continue
		var at: Vector2i = wall_slot(role)
		lines.append("role %d,%d slot %d,%d  # %s" % [role.x, role.y, at.x, at.y,
				Walls.role_name(role)])

	return "\n".join(lines) + "\n"


## LA REGLE DE POSE, telle qu'elle part dans le manifeste.
##
## ⚠ LE MODE D'EMPLOI LA LIT D'ICI, ET C'EST TOUT L'INTERET. La recopier dans l'interface
## donnerait deux textes a tenir d'accord, et le jour ou la regle bouge il y en a un qui
## ment. Ce que l'acheteur lit a l'ecran est mot pour mot ce que son moteur recevra.
static func placement_rules() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	_spec(lines)
	return lines


## LA REGLE DE POSE, ecrite noir sur blanc.
##
## ⚠ NECESSAIRE ET SUFFISANT. Ce qui suit doit permettre a quelqu'un qui n'a QUE ce fichier
## et les planches de poser un monde correct. Si une regle manque ici, elle vivra dans la
## tete de celui qui a ecrit le moteur -- et le jour ou il en ecrira un second, les deux
## divergeront sans que rien ne le dise.
##
## ⚠ ET LA SECTION DE SURFACE EST CELLE DE LA FAMILLE EXPORTEE, JAMAIS LES DEUX. Un
## manifeste qui decrirait la canonicalisation du blob au-dessus d'une planche a cheval
## serait faux deux fois : il enonce une regle que ses tuiles n'emploient pas, et il tait
## celle qu'elles emploient. Le contrat porte sur les planches qui sont a cote de lui.
static func _spec(lines: PackedStringArray, family: StringName = Families.BY_CELL) -> void:
	lines.append("")
	lines.append("# ======================= LA REGLE DE POSE =======================")
	lines.append("# Ce fichier n'est pas une notice, c'est le contrat. Tout ce qui suit est")
	lines.append("# necessaire et suffisant pour placer chaque tuile.")
	lines.append("")
	lines.append("# --- LE RELIEF ---")
	lines.append("# Une carte est une hauteur par case, et elle a TROIS etats, pas deux :")
	lines.append("#     %s   le VIDE, le hors-monde : il n'y a pas de sol du tout ;"
			% HeightMask.VOID_CHAR)
	lines.append("#     0   la plaine ;")
	lines.append("#     1.. les plateaux.")
	lines.append("# ⚠ LE HORS-CARTE EST DU VIDE, PAS DE LA PLAINE. Une case qu'on ne declare")
	lines.append("# pas n'est pas au niveau 0 : elle n'existe pas. C'est la seule facon de")
	lines.append("# savoir OU LE SOL S'ARRETE, donc de border le monde -- un moteur qui lirait")
	lines.append("# l'absence comme de la plaine etendrait le sol a l'infini sans une erreur.")
	lines.append("void %d out_of_map_is_void" % HeightMask.VOID)
	lines.append("# La silhouette de l'etage N est l'ensemble des cases de hauteur >= N, et")
	lines.append("# c'est un masque BINAIRE : tout ce qui suit s'applique etage par etage. On")
	lines.append("# dessine du bas vers le haut, chaque couche recouvrant la precedente.")
	lines.append("levels silhouette_per_level")
	lines.append("# ⚠ ET LA PLAINE EST UN PLATEAU COMME LES AUTRES. Elle a sa silhouette, ses")
	lines.append("# index de surface, et ses FALAISES la ou elle borde le vide : c'est le bord")
	lines.append("# du monde. Aucune tuile nouvelle n'en decoule -- les memes index, les memes")
	lines.append("# roles -- mais un moteur qui traiterait l'etage 0 a part n'en poserait")
	lines.append("# aucune, et son monde flotterait sur un sol sans fin.")
	lines.append("plain level_like_any_other")
	lines.append("draw_order bottom_up")
	lines.append("")
	if family == Families.BY_CORNER:
		_spec_corner(lines)
	else:
		_spec_cell(lines)
	lines.append("")
	lines.append("# --- LES FALAISES ---")
	lines.append("# ⚠ UN PLATEAU N'A DE FACE QU'AU SUD. Les trois autres cotes ne montrent rien :")
	lines.append("# on voit son dessus, puis le sol d'en dessous, sans transition.")
	lines.append("faces south_only")
	lines.append("storey_tiles %d" % Walls.STOREY_TILES)
	lines.append("body_rows %d" % Walls.BODY_ROWS)
	lines.append("block_rows %d" % Walls.BLOCK_ROWS)
	lines.append("# LA CHUTE. Sous une levre de l'etage N -- une case de l'etage N dont la case")
	lines.append("# au sud est plus basse -- on cherche l'etage le plus haut M reellement")
	lines.append("# atteint, et la chute vaut storey_tiles * (N - M).")
	lines.append("# ⚠ ON SONDE LA CASE JUSTE SOUS LE PIED, jamais celles que la robe traverse :")
	lines.append("# les etages partagent la grille, et l'etage N-1 continue SOUS la robe de")
	lines.append("# l'etage N. Sonder au fil de la descente repondrait « touche » des la premiere")
	lines.append("# case, et toutes les falaises feraient une case de haut.")
	lines.append("fall storey_tiles_times_gap probe_below_foot")
	lines.append("# ⚠ ET QUAND RIEN N'EST DESSOUS, LA ROBE NE S'ARRETE PAS A L'ETAGE 0 : elle")
	lines.append("# tombe d'un etage de PLUS -- storey_tiles * (N + 1) -- et ne pose PAS son")
	lines.append("# pied. On ne touche pas le fond d'un gouffre. C'est la falaise du bord du")
	lines.append("# monde, et c'est aussi celle de la plaine elle-meme, qu'aucun etage ne peut")
	lines.append("# recevoir. Partir de storey_tiles * N donnerait zero pour la plaine, qui")
	lines.append("# n'aurait alors jamais de falaise du tout.")
	lines.append("fall_into_void one_storey_more no_foot")
	lines.append("# LE MODE EPAIS, A MIN TROIS. Rien ne fait une bande fine : une case --")
	lines.append("# pleine OU vide -- dont la course (la suite de cases du meme etat qui la")
	lines.append("# contient le long d'un axe) fait moins de trois -- bord + centre + bord --")
	lines.append("# est FINE, et ce dans CHAQUE silhouette d'etage, plaine comprise.")
	lines.append("# Le pinceau du moteur refuse tout geste qui en creerait une : le tileset")
	lines.append("# n'a pas de tuile pour elle, et la table de ce fichier est le vocabulaire")
	lines.append("# entier qui survit a cet interdit.")
	lines.append("thin_forbidden run_shorter_than_three all_storeys both_states")
	lines.append("# RACCOURCISSEMENT. Si la robe rencontre le sol de SON PROPRE etage, elle")
	lines.append("# s'arrete la et ne pose PAS son pied : elle ne touche pas le sol d'en bas,")
	lines.append("# elle bute contre un voisin de son niveau.")
	lines.append("trim stop_on_same_level no_foot")
	lines.append("# LA RANGEE, au pas `step` (1 = premiere case sous la levre) d'une chute de")
	lines.append("# `drop` cases :")
	lines.append("#     step == 1               -> %d  chapiteau" % Walls.ROW_CROWN)
	lines.append("#     step == drop et posee   -> %d  pied" % Walls.ROW_FOOT)
	lines.append("#     sinon                   -> 1 + (step - 2) modulo body_rows")
	lines.append("row_for crown_first foot_last body_cycle")
	lines.append("# LE PAN. C'est le couple des deux flancs : pan = ouest * %d + est."
			% Walls.SIDE_COUNT)
	lines.append("#     %d ARRET     ma roche s'arrete a ce flanc" % Walls.SIDE_STOP)
	lines.append("#     %d CONTINUE  de la ROCHE a ce flanc : la meme face se poursuit"
			% Walls.SIDE_CONTINUE)
	lines.append("# ⚠ DEUX ETATS, PAS TROIS, ET C'EST LA REGLE DES COUCHES QUI LE PERMET. Un")
	lines.append("# troisieme etat, DEVANT, disait « mon voisin est en retrait, je porte")
	lines.append("# l'angle » -- c'est-a-dire une affirmation sur le VOISIN. Or « qui est")
	lines.append("# devant » ne se demande plus a la tuile : la face la plus proche se pose")
	lines.append("# par-dessus l'autre, et l'ORDRE DE DESSIN tranche. La dissymetrie que les")
	lines.append("# neuf pans achetaient au prix de vingt-sept roles, l'empilement la donne")
	lines.append("# pour rien. Les %d pans vivent tous, a toutes les rangees." % Walls.PAN_COUNT)
	lines.append("# ⚠ ET `ARRET` NE BORDE JAMAIS DE LA ROCHE : c'est un theoreme -- il veut dire")
	lines.append("# qu'aucune face ne couvre la case d'a cote -- verifie sur 5 216 flancs, dont")
	lines.append("# 35,5 %% de terre et 64,5 %% de vide, et zero de roche.")
	lines.append("# ⚠ ET LE PAN SE CHOISIT PAR RANGEE, JAMAIS PAR COLONNE : sous le pied d'une")
	lines.append("# voisine plus courte, un flanc redevient `arret`.")
	lines.append("pan west_times_two_plus_east lip_row_comparison per_row")

	lines.append("")
	lines.append("# --- LA POSE DERRIERE : le sous-pied, et le corps derriere une case qui ecrete ---")
	lines.append("# Une robe qui atterrit repose son PIED une case plus bas, SOUS la surface")
	lines.append("# de cette case. Raison : la case d'atterrissage a ses coins nord decoupes")
	lines.append("# -- son voisin du nord est la face de la falaise -- et par ces coins on")
	lines.append("# verrait le sol au lieu de la roche qui continue derriere.")
	lines.append("# Ce n'est PAS une tuile de plus : c'est la meme, posee une fois de plus.")
	lines.append("# Le pan est celui du pied, sans rien recalculer : c'est la meme face.")
	lines.append("# ORDRE : le sous-pied se pose JUSTE AVANT la surface de l'etage ou il")
	lines.append("# atterrit -- pas avant toutes les surfaces. Un moteur qui dessine tous les")
	lines.append("# etages du bas vers le haut recouvrirait sinon le sous-pied avec l'etage")
	lines.append("# d'en dessous, et les coins montreraient de nouveau le sol.")
	lines.append("underfoot foot_role redrawn_below under_landing_surface")
	lines.append("# ⚠ ET UNE ROBE ECRETEE PASSE DERRIERE LA CASE QUI L'A COUPEE. Sous cette")
	lines.append("# case -- seulement si elle est EXACTEMENT de l'etage de la levre : plus")
	lines.append("# haute, son sommet depasse la face -- on repose la rangee du pas suivant,")
	lines.append("# row_for(drop + 1) : toujours un CORPS. Jamais un pied, qui reste la preuve")
	lines.append("# d'un atterrissage ; jamais un chapiteau, un blocage au premier pas ayant")
	lines.append("# reduit la robe a neant. Le pan est celui de la derniere rangee posee, et")
	lines.append("# l'ordre est celui du sous-pied : juste avant la surface de l'etage de la")
	lines.append("# case qui la recouvre. Sans cette pose, le coin nord decoupe de la case qui")
	lines.append("# ecrete s'ouvre sur l'etage d'en dessous -- de l'herbe ou du vide, la ou la")
	lines.append("# roche continue.")
	lines.append("backing next_body_row under_trimming_cell same_level_only")
	lines.append("# LE CHAPITEAU SOUS SA LEVRE. La face COMMENCE sous la case qui la lance :")
	lines.append("# sous chaque levre se repose la premiere rangee de SA chute, avec le pan")
	lines.append("# du premier pas. Les marges transparentes de la tuile de surface montrent")
	lines.append("# ainsi le VRAI flanc de la vraie face de chaque occurrence, au lieu de")
	lines.append("# l'etage d'en dessous vu a travers le haut de la paroi. Une pose de plus,")
	lines.append("# AUCUNE tuile de plus. Le sous-pied garde une case disputee.")
	lines.append("lip_backing first_fall_row under_lip_cell")

	lines.append("")
	lines.append("# --- LA PLANCHE ---")
	lines.append("# Une tuile, un dessin, une case. Les deux planches ont une taille FIXE :")
	lines.append("# elle ne depend ni du guide ni de ce qui a ete peint, seulement du")
	lines.append("# vocabulaire. Le lecteur peut donc calculer la case d'une tuile sans rien")
	lines.append("# lire d'autre que ce fichier. Il n'y a PAS de variantes : plusieurs cases")
	lines.append("# du guide portent la meme tuile, mais elles portent le meme dessin.")
	lines.append("sheet fixed_size one_drawing_per_tile no_variants")
	lines.append("# ================================================================")


## LA SURFACE PAR CASE : le blob 47.
static func _spec_cell(lines: PackedStringArray) -> void:
	lines.append("# --- LA SURFACE : le blob 47 ---")
	lines.append("# La tuile occupe UNE CASE, et son dessin depend des huit voisins de cette")
	lines.append("# case. Voisinage 8 bits, sens horaire depuis le nord.")
	lines.append("bits N=%d NE=%d E=%d SE=%d S=%d SW=%d W=%d NW=%d" % [
			BlobIndex.N, BlobIndex.NE, BlobIndex.E, BlobIndex.SE,
			BlobIndex.S, BlobIndex.SW, BlobIndex.W, BlobIndex.NW])
	lines.append("# ⚠ UN BIT DE COIN N'EST CONSERVE QUE SI LES DEUX CARDINAUX QUI L'ENCADRENT")
	lines.append("# SONT PLEINS. Un coin diagonal isole ne change pas la silhouette de la tuile :")
	lines.append("# il ne doit donc pas produire une tuile de plus. Les 256 voisinages bruts se")
	lines.append("# reduisent ainsi a exactement %d index." % BlobIndex.CANONICAL_INDICES.size())
	lines.append("canonicalise corner_needs_both_cardinals")
	lines.append("# La tuile d'une case est celle de SON etage, jamais de l'union des etages.")
	lines.append("visible own_level")
	lines.append("# La couche de surface est posee sur la grille des cases, sans decalage.")
	lines.append("surface_offset none")


## LA SURFACE A CHEVAL : le reseau dual, quinze tuiles.
##
## ⚠ CETTE SECTION MANQUAIT, ET C'ETAIT EXACTEMENT LA DEPENDANCE QUE LE CONTRAT EXISTE POUR
## SUPPRIMER. Un export `corner` annoncait bien sa famille et ses quinze index, mais la
## regle de pose ne decrivait que le blob : ni les bits du croisement, ni les quatre cases
## qu'il touche, ni le decalage d'une demi-case. Notre plugin les connait parce que c'est
## NOUS qui l'avons ecrit -- c'est-a-dire de memoire, et le second lecteur aurait diverge.
static func _spec_corner(lines: PackedStringArray) -> void:
	lines.append("# --- LA SURFACE : le reseau dual, %d tuiles ---" % CornerIndex.TILE_COUNT)
	lines.append("# ⚠ LA TUILE N'EST PAS POSEE SUR UNE CASE, ELLE EST POSEE SUR LE CROISEMENT DE")
	lines.append("# QUATRE CASES, et son dessin ne depend que de ces quatre-la. Le croisement")
	lines.append("# (i, j) est leur coin commun ; une carte de W x H cases porte donc")
	lines.append("# (W+1) x (H+1) croisements. Quatre cases, deux etats : seize combinaisons.")
	var bits: PackedStringArray = PackedStringArray()
	var cells: PackedStringArray = PackedStringArray()
	for bit: int in range(CornerIndex.BITS.size()):
		var at: Vector2i = CornerIndex.OFFSETS[bit]
		bits.append("%s=%d" % [CornerIndex.BIT_NAMES[bit], CornerIndex.BITS[bit]])
		cells.append("%s=%d,%d" % [CornerIndex.BIT_NAMES[bit], at.x, at.y])
	lines.append("# Bits dans le sens horaire depuis le nord-ouest, comme le blob part du nord.")
	lines.append("corner_bits %s" % " ".join(bits))
	lines.append("# Le decalage (dx, dy) de la case que porte chaque bit, depuis le croisement.")
	lines.append("corner_cells %s" % " ".join(cells))
	lines.append("# ⚠ ON NE VOIT QUE LE SOMMET, ICI AUSSI. Les quatre cases peuvent etre a quatre")
	lines.append("# etages differents : on prend le plus haut des quatre, et on met le bit de")
	lines.append("# chaque case qui ATTEINT cet etage. Compter aussi les etages du dessous")
	lines.append("# poserait des tuiles que la couche du dessus recouvre.")
	lines.append("corner_visible top_of_four bits_reaching_top")
	lines.append("# ⚠ LE CROISEMENT ENTIEREMENT VIDE NE DESSINE RIEN -- ses quatre cases sont a la")
	lines.append("# plaine -- exactement comme la plaine n'est pas une tuile du blob. Le code 0")
	lines.append("# n'a donc pas de case sur la planche : la famille livre QUINZE tuiles, pas")
	lines.append("# seize. Un croisement qui ne touche aucune case du relief ne se pose pas.")
	lines.append("corner_empty draws_nothing")
	lines.append("# ⚠ ET C'EST LA COUCHE QUI SE DECALE D'UNE DEMI-CASE VERS LE NORD-OUEST, JAMAIS")
	lines.append("# LA TUILE. La tuile du croisement (i, j) se centre sur ce coin commun : elle")
	lines.append("# commence donc une demi-case plus au nord et plus a l'ouest. Le decalage vaut")
	lines.append("# pour la couche entiere, et il n'y a rien a decaler case par case.")
	lines.append("surface_offset minus_half_tile whole_layer")
	lines.append("# ⚠ LES FALAISES NE CHANGENT PAS DE GRILLE. Une falaise sort du plan : elle se")
	lines.append("# pose case pour case, sur sa propre couche NON decalee, quel que soit le")
	lines.append("# reseau du sol. Les %d roles valent pour les deux familles."
			% Walls.ALL_ROLES.size())
	lines.append("walls_offset none")


## Ecrit les deux planches et leur manifeste dans [param folder].
##
## Rend le rapport d'`analyse()`, augmente de :
##   error   : Error   OK, ou ERR_UNAVAILABLE si la feuille est incomplete
##   written : PackedStringArray  les chemins ecrits
static func write(folder: String, basename: String, painting: Painting,
		heights: PackedStringArray, mode_id: StringName,
		family: StringName = Families.BY_CELL) -> Dictionary:
	var report: Dictionary = analyse(painting, heights, family)
	report["written"] = PackedStringArray()
	report["error"] = OK

	# ⚠ UN REFUS N'EST PAS UNE ERREUR. Une feuille incomplete est l'etat NORMAL tant que
	# l'utilisateur peint : le bouton est grise, le compte s'affiche, et c'est tout. Le
	# signaler par `push_error` remplirait la console de rouge pendant tout le travail, et
	# apprendrait a ignorer le rouge. Le rapport dit ce qui manque, il suffit de le lire.
	if not report["is_exportable"]:
		report["error"] = ERR_UNAVAILABLE
		return report

	if DirAccess.make_dir_recursive_absolute(folder) != OK and not DirAccess.dir_exists_absolute(folder):
		push_error("tileset_png: dossier '%s' introuvable et impossible a creer." % folder)
		report["error"] = ERR_CANT_CREATE
		return report

	var written: PackedStringArray = PackedStringArray()
	for walls: bool in [false, true]:
		var sheet: Image = compose(painting, heights, report, walls)
		if sheet == null:
			report["error"] = ERR_CANT_CREATE
			return report
		var path: String = folder.path_join(basename + (SUFFIX_WALLS if walls else SUFFIX_SURFACE))
		var saved: Error = sheet.save_png(path)
		if saved != OK:
			push_error("tileset_png: ecriture impossible de '%s' (erreur %d)." % [path, saved])
			report["error"] = saved
			return report
		written.append(path)

	var proof: Image = Assembly.from_borrowed(ProofScene.relief(family), heights, painting,
			family)
	var proof_path: String = folder.path_join(basename + SUFFIX_PROOF)
	var proof_saved: Error = proof.save_png(proof_path)
	if proof_saved != OK:
		push_error("tileset_png: ecriture impossible de '%s' (erreur %d)." % [proof_path, proof_saved])
		report["error"] = proof_saved
		return report
	written.append(proof_path)

	var manifest_path: String = folder.path_join(basename + SUFFIX_MANIFEST)
	var file: FileAccess = FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("tileset_png: ecriture impossible de '%s' (erreur %d)."
				% [manifest_path, open_error])
		report["error"] = open_error
		return report
	file.store_string(manifest(report, mode_id, basename))
	file.close()
	written.append(manifest_path)

	report["written"] = written
	return report
