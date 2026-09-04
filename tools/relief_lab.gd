# LE LABORATOIRE : fabriquer des reliefs epais, et nommer les jonctions qu'ils posent.
#
# ⚠ UN SEUL ENDROIT, PARCE QUE DEUX COPIES D'UNE MEME REGLE FINISSENT TOUJOURS PAR SE
# CONTREDIRE. Le recensement compte les especes de jonction ; le batisseur du guide cherche a
# les couvrir. S'ils ne les nomment pas de la meme facon, le guide se croira complet en
# couvrant autre chose que ce qu'on mesure -- exactement la faute du test qui redérive la
# formule qu'il verifie.
extends RefCounted

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Thickness := preload("res://core/thickness.gd")
const Gesture := preload("res://core/gesture.gd")
const Found := preload("res://core/found_worlds.gd")

const BAND: Array[String] = ["surf", "chap", "corp", "pied"]


## L'ESPECE D'UNE JONCTION, et chaque champ y est parce qu'il change ce qui se dessine :
##   l'axe            lateral ou vertical ;
##   les deux bandes  surface, chapiteau, corps, pied ;
##   meme massif      sinon deux faces distinctes se rencontrent ;
##   meme levre       a massif egal, c'est ce qui separe la roche continue de l'ARETE INTERNE ;
##   l'ecart d'etage  qui est devant qui ;
##   les deux chutes  trois, six, ou davantage.
##
## Rend `{espece: occurrences}` sur ce qu'on VOIT -- la pose du dessus.
static func species(world: PackedStringArray) -> Dictionary:
	var top: Dictionary = {}
	var falls: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if int(one["band"]) != Massifs.SURFACE:
			var lip: Vector2i = one["lip"]
			var key: Vector3i = Vector3i(lip.x, lip.y, int(one["level"]))
			falls[key] = int(falls.get(key, 0)) + 1
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var out: Dictionary = {}
	for cell2: Vector2i in top.keys():
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var near: Vector2i = cell2 + step
			if not top.has(near):
				continue
			var key2: String = name_of(top[cell2], top[near], step == Vector2i.RIGHT, falls)
			out[key2] = int(out.get(key2, 0)) + 1
	return out


## Les memes especes, mais rangees par CASE -- pour aller decouper autour de l'une d'elles.
static func species_at(world: PackedStringArray) -> Dictionary:
	var top: Dictionary = {}
	var falls: Dictionary = {}
	for one: Dictionary in Massifs.poses(world):
		var cell: Vector2i = one["cell"]
		if int(one["band"]) != Massifs.SURFACE:
			var lip: Vector2i = one["lip"]
			var key: Vector3i = Vector3i(lip.x, lip.y, int(one["level"]))
			falls[key] = int(falls.get(key, 0)) + 1
		if top.has(cell) and int((top[cell] as Dictionary)["level"]) > int(one["level"]):
			continue
		top[cell] = one
	var out: Dictionary = {}
	for cell2: Vector2i in top.keys():
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var near: Vector2i = cell2 + step
			if not top.has(near):
				continue
			var key2: String = name_of(top[cell2], top[near], step == Vector2i.RIGHT, falls)
			if not out.has(key2):
				out[key2] = cell2
	return out


static func name_of(a: Dictionary, b: Dictionary, lateral: bool, falls: Dictionary) -> String:
	var same_massif: bool = int(a["massif"]) == int(b["massif"])
	var lip_a: Vector2i = a["lip"]
	var lip_b: Vector2i = b["lip"]
	var same_lip: bool = same_massif and lip_a.y == lip_b.y
	var drop: int = clampi(int(b["level"]) - int(a["level"]), -2, 2)
	return "%s %s|%s %s %s etage%+d chute %s|%s" % [
			"lateral" if lateral else "vertical",
			BAND[int(a["band"])], BAND[int(b["band"])],
			"meme-massif" if same_massif else "deux-massifs",
			"meme-levre" if same_lip else "levres-differentes",
			drop, _fall(falls, a), _fall(falls, b)]


static func _fall(falls: Dictionary, one: Dictionary) -> String:
	if int(one["band"]) == Massifs.SURFACE:
		return "-"
	var lip: Vector2i = one["lip"]
	var many: int = int(falls.get(Vector3i(lip.x, lip.y, int(one["level"])), 0))
	return "9+" if many > 6 else str(many)


## UN RELIEF EPAIS TIRE AU SORT -- pose ET efface, puis se repare, comme le pinceau.
##
## ⚠ ON REPARE, ON NE REFUSE PAS. Un generateur qui jette tout relief fin ne rendait que quinze
## mondes sur mille cinq cents : la battue ne cherchait presque rien, et son silence n'aurait
## rien prouve.
## ⚠ ET LA TAILLE EST FIXE, PARCE QUE LE GUIDE EN EST UNE MOSAIQUE. Chaque monde y entre
## ENTIER, avec son lisere de vide : rien n'est decoupe, donc rien ne peut mentir. La decoupe,
## elle, tranche des massifs et change les jonctions qu'elle pretend capturer -- il fallait la
## reparer, la reverifier, et elle en rejetait le tiers.
static func draw(rng: RandomNumberGenerator, wide: int = 24, tall: int = 30) -> PackedStringArray:
	return Gesture.walk(rng, wide, tall)


## ⚠ LA REGLE DU GESTE VIT DANS `core/gesture.gd`, ET NULLE PART AILLEURS. Ce fichier n'en est
## qu'une facade : les clauses etaient eparpillees -- epaisseur dans `Thickness`, marge de pied
## dans `Massifs`, gouffre nulle part -- et chaque nouvelle clause devait etre recopiee dans le
## generateur, la chasse, le batisseur, l'audit et le banc. Il suffisait d'en oublier un pour
## qu'un relief illegal traverse toute la chaine.
static func repair(grid: Array[PackedByteArray]) -> PackedStringArray:
	return Gesture.mend(grid)


static func text(grid: Array[PackedByteArray]) -> PackedStringArray:
	return Gesture.text(grid)


static func legal(world: PackedStringArray) -> bool:
	return Gesture.legal(world)


static func chasms(world: PackedStringArray) -> int:
	return Gesture.chasms(world)


# --- LE VIVIER -----------------------------------------------------------------------

## LA TAILLE D'UN MONDE DU VIVIER. ⚠ FIXE, parce que le guide en est une MOSAIQUE : chaque
## monde y entre entier, avec son lisere de vide.
const GROUND_W: int = 24
const GROUND_H: int = 30

## LA GRAINE DU VIVIER. ⚠ FIXE AUSSI : deux battues qui tirent des mondes differents trouvent
## des tuiles differentes, et c'est exactement le defaut qu'on repare ici.
const GROUND_SEED: int = 0x475549


## LE VIVIER — LES MEMES MONDES POUR TOUTES LES BATTUES.
##
## ⚠ CE FICHIER EXISTE PARCE QUE DEUX BATTUES QUI NE CHERCHENT PAS AU MEME ENDROIT NE PEUVENT
## PAS S'ACCORDER. Le recenseur tirait ses mondes, le batisseur les siens, la chasse les siens :
## le recenseur ecrivait au vocabulaire des tuiles que le batisseur ne savait pas porter, et le
## guide sortait avec HUIT TUILES ABSENTES -- sans que rien ne le dise avant l'export. C'est mot
## pour mot la faute des deux copies d'une regle, appliquee a la RECHERCHE au lieu du calcul.
##
## Trois sources CONSTRUITES, et chacune paie sa place :
##   LES MARCHES        un bord sud EN MARCHES est ce qui fabrique un CISAILLEMENT, et le
##                      tampon pose au hasard n'en produit presque jamais. ⚠ UNE BATTUE QUI NE
##                      CHERCHE PAS LA OU CA SE TROUVE N'A PAS CHERCHE : en donnant cette
##                      famille au recenseur, NEUF TUILES DE BASE sont apparues qui existaient
##                      depuis toujours ;
##   LES TERRASSES      des blocs a ETAGES differents, qui seuls fabriquent une chute d'UNE
##                      colonne -- donc les corps a peu de voisins. Une marche ne fait varier que
##                      la rangee du bord sud, jamais l'etage : elle ne les produit jamais ;
##   LES SOLS ETAGES  un plateau a bord sud DROIT dont la chute traverse un sol en paliers :
##                      les colonnes voisines atterrissent a des profondeurs differentes, donc
##                      les corps y sont etroits ;
##   LES TROUVES        les mondes qu'une battue a rencontres et qu'on a GARDES ;
##   LE HASARD          pour tout ce qu'on n'a pas su prevoir -- et c'est la seule des trois qui
##                      ne prouve rien toute seule.
##
## ⚠ ET TOUT CE QUI EN SORT EST LEGAL. `Gesture.legal` tranche chaque monde : un relief que le
## pinceau ne produirait pas n'a rien a faire dans une battue qui cherche ce qu'il produit.
## ⚠ ET LE GUIDE N'EST PAS DANS LE VIVIER, C'EST UN PIEGE QUI A ETE POSE PUIS RETIRE. Le guide
## est BATI DEPUIS le vocabulaire ; l'y remettre ferait du vocabulaire une fonction de lui-meme,
## et le cycle ne convergerait plus vers le haut mais vers le BAS -- mesure : 55 tuiles atteintes,
## puis 50 au tour suivant, parce qu'un guide qui avait rate neuf tuiles les retirait du vivier
## qui les lui aurait rendues. Un vivier doit etre CONSTRUIT, donc independant de ce qu'il sert
## a construire.
static func ground(draws: int = 400) -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	for top_level: int in [1, 2]:
		for plan: int in range(64):
			var deep: Array[int] = []
			var rest: int = plan
			for _b: int in range(3):
				deep.append(rest % 4)
				rest /= 4
			var stair: PackedStringArray = stairs(deep, top_level)
			if Gesture.legal(stair):
				out.append(stair)
	# ⚠ ET LES TERRASSES, PARCE QUE LES MARCHES NE SUFFISENT PAS. Un `CORPS 1` -- un corps dont
	# seule la voisine du NORD est dans l'empreinte -- est le fond d'une chute d'UNE colonne : il
	# faut que la colonne voisine tombe MOINS loin, donc que les deux partent d'ETAGES
	# differents. Une marche ne fait varier que la rangee du bord sud, jamais l'etage : elle ne
	# produit donc jamais ces fonds-la. Huit tuiles manquaient au guide pour cette seule raison.
	for shape: int in range(81):
		var levels: Array[int] = []
		var rest2: int = shape
		for _c: int in range(4):
			levels.append(rest2 % 3)
			rest2 /= 3
		var terrace: PackedStringArray = terraces(levels)
		if Gesture.legal(terrace):
			out.append(terrace)
	# ⚠ ET LES MONDES DEJA TROUVES, qui sont la quatrieme source et la plus importante : UN MONDE
	# QUI PORTE UNE TUILE EST SON TEMOIN. La battue les jetait -- elle rencontrait une tuile,
	# l'ecrivait au vocabulaire, puis oubliait le relief qui la prouvait. Gardes ici, ils rendent
	# le vivier reproductible SANS l'empecher de croitre : ce qui a ete trouve une fois reste
	# trouve. C'est ce qui ferme la classe entiere des divergences entre battues.
	for kept: PackedStringArray in Found.all():
		out.append(kept)
	# ⚠ ET LES SOLS ETAGES, parce que les terrasses ne suffisent pas non plus. Un `CORPS 17` --
	# un corps qui n'a que le nord et le sud -- est une chute d'UNE colonne encadree de vide :
	# il faut que les colonnes voisines aient ATTERRI plus haut. Les marches font varier la
	# rangee du bord sud, les terrasses l'etage du plateau ; ni l'une ni l'autre ne fait varier
	# LE SOL QUI RECOIT. Sept tuiles manquaient au vivier pour cette seule raison, et douze mille
	# tirages au hasard ne les avaient pas rencontrees.
	for deep_plan: int in range(64):
		var steps: Array[int] = []
		var left: int = deep_plan
		for _d: int in range(3):
			steps.append(left % 4)
			left /= 4
		for high: int in [2, 3]:
			var landed: PackedStringArray = landings(steps, high)
			if Gesture.legal(landed):
				out.append(landed)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GROUND_SEED
	var drawn: int = 0
	while drawn < draws:
		var one: PackedStringArray = draw(rng, GROUND_W, GROUND_H)
		if one.is_empty():
			continue
		out.append(one)
		drawn += 1
	return out


## UN BORD SUD EN MARCHES : trois blocs de trois colonnes, chacun plongeant de zero a trois
## rangees. La colonne de gauche s'arrete haut, sa jupe pend, et celle de droite continue en
## surface a cote d'elle -- c'est-a-dire un CISAILLEMENT.
##
## ⚠ MIN TROIS EST RESPECTE PAR CONSTRUCTION (les blocs font trois colonnes), et on demande
## quand meme a `Gesture.legal` : ni la marge de pied ni le gouffre ne se lisent sur la largeur.
static func stairs(deep: Array[int], top_level: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for _y: int in range(GROUND_H):
		var row: PackedByteArray = PackedByteArray()
		row.resize(GROUND_W)
		row.fill(0)
		grid.append(row)
	for y2: int in range(4, GROUND_H - 4):
		for x: int in range(4, GROUND_W - 4):
			grid[y2][x] = 1
	for x2: int in range(6, 15):
		var bottom: int = 10 + deep[mini((x2 - 6) / 3, 2)]
		for y3: int in range(6, mini(bottom + 1, GROUND_H - 4)):
			grid[y3][x2] = top_level + 1
	return text(grid)


## DES TERRASSES A ETAGES DIFFERENTS : quatre blocs de trois colonnes, chacun a son etage.
##
## ⚠ C'EST CE QUI FABRIQUE UNE CHUTE D'UNE SEULE COLONNE, et donc les corps a peu de voisins.
## Deux colonnes voisines parties d'etages differents ne tombent pas de la meme hauteur : au bas
## de la plus haute, la voisine s'est deja arretee, et le corps s'y retrouve seul. Une marche --
## qui ne fait varier que la RANGEE du bord sud -- ne produit jamais ca.
static func terraces(levels: Array[int]) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for _y: int in range(GROUND_H):
		var row: PackedByteArray = PackedByteArray()
		row.resize(GROUND_W)
		row.fill(0)
		grid.append(row)
	for y2: int in range(4, GROUND_H - 4):
		for x: int in range(4, GROUND_W - 4):
			grid[y2][x] = 1
	for x2: int in range(6, 18):
		var step: int = levels[mini((x2 - 6) / 3, 3)]
		if step == 0:
			continue
		for y3: int in range(6, 12):
			grid[y3][x2] = step + 1
	return text(grid)


## UN SOL EN PALIERS SOUS UNE LEVRE DROITE.
##
## ⚠ C'EST CE QUI FABRIQUE LES CORPS ETROITS, et rien d'autre ne le fait. Le plateau a un bord
## sud DROIT -- donc toutes ses colonnes partent de la meme rangee -- mais le sol qu'elles
## rencontrent est a des etages differents : chacune s'arrete ou elle atterrit, et au bas de la
## plus longue, ses voisines se sont deja tues. Les marches font varier la rangee du bord sud,
## les terrasses l'etage du plateau ; seule celle-ci fait varier LE SOL QUI RECOIT.
static func landings(steps: Array[int], top_level: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for _y: int in range(GROUND_H):
		var row: PackedByteArray = PackedByteArray()
		row.resize(GROUND_W)
		row.fill(0)
		grid.append(row)
	for y2: int in range(4, GROUND_H - 4):
		for x: int in range(4, GROUND_W - 4):
			grid[y2][x] = 1
	# les paliers du sol, sous la levre
	for x2: int in range(6, 15):
		var step: int = mini(steps[mini((x2 - 6) / 3, 2)], top_level - 1)
		if step <= 0:
			continue
		for y3: int in range(12, GROUND_H - 4):
			grid[y3][x2] = step + 1
	# le plateau, bord sud DROIT
	for x3: int in range(6, 15):
		for y4: int in range(5, 11):
			grid[y4][x3] = top_level + 1
	return text(grid)
