extends SceneTree

## LE RECENSEMENT DU PINCEAU : ce que le GESTE peut produire, et rien d'autre.
##
##     godot --headless --path . --script res://tools/brush_census.gd -- [gestes]
##
## ⚠ LE DOMAINE N'EST PAS « LES RELIEFS MIN TROIS », C'EST « CE QUE LE PINCEAU ATTEINT ».
## Min trois n'est pas une regle en soi : c'est la CONSEQUENCE d'un pinceau qui pose une tuile
## de surface PLEINE en 3x3 et laisse les huit contours se raccommoder par calcul. Le peintre
## peint de la surface ; le reste suit. Le modele doit donc prevoir les tuiles necessaires a
## CELA -- ni plus, ni moins.
##
## ⚠ ET MIN TROIS NE SUFFIT PAS A DECRIRE LE GESTE. Deux tampons 3x3 poses en diagonale se
## touchent coin contre coin sans qu'aucune course ne fasse moins de trois : le pincement
## diagonal est une clause EN PLUS, pas une consequence. C'est pour ca qu'il a fallu l'ecrire.
##
## ⚠ ET UNE BATTUE QUI NE RENCONTRE PAS UNE TUILE PROUVE QU'ELLE EST RARE, JAMAIS QU'ELLE EST
## IMPOSSIBLE. Ce recensement ne conclut donc pas tout seul : il dit ce que le geste ATTEINT, et
## l'ecart avec la forme close est une liste de questions, pas un verdict.

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const MassifForm := preload("res://core/massif_form.gd")
const Thickness := preload("res://core/thickness.gd")
const Gesture := preload("res://core/gesture.gd")
const Lab := preload("res://tools/relief_lab.gd")
const Stored := preload("res://core/brush_vocabulary.gd")

const OUT: String = "res://core/brush_vocabulary.gd"

const WIDE: int = 26
const TALL: int = 32
const RIM: int = 4


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var runs: int = args[0].to_int() if not args.is_empty() else 300
	# ⚠ LE MEME VIVIER QUE LE BATISSEUR ET LA CHASSE. Ce recenseur tirait ses propres mondes :
	# il ecrivait alors au vocabulaire des tuiles que le batisseur ne savait pas porter, et le
	# guide sortait avec huit tuiles absentes. Deux battues qui ne cherchent pas au meme endroit
	# ne peuvent pas s'accorder -- c'est la faute des deux copies d'une regle, appliquee a la
	# recherche. Le vivier vit dans `relief_lab.gd`, et il est le seul.
	var met: Dictionary = {}
	var pool: Array[PackedStringArray] = Lab.ground(runs)
	for world: PackedStringArray in pool:
		for tile: Variant in Massifs.paintable(world).values():
			met[int(tile)] = true
	var made: int = pool.size()
	print("  vivier commun : %d mondes" % made)

	var form: Array[int] = MassifForm.vocabulary()
	var never: Array[int] = []
	for tile2: int in form:
		if not met.has(tile2):
			never.append(tile2)
	var stray: Array[int] = []
	for tile3: int in met.keys():
		if not form.has(tile3):
			stray.append(tile3)

	print("=== LE RECENSEMENT DU PINCEAU ===")
	print("  %d mondes battus (vivier commun)" % made)
	print("  la forme close  : %d tuiles" % form.size())
	print("  le geste atteint: %d tuiles" % met.size())
	print("  JAMAIS ATTEINTES : %d" % never.size())
	for tile4: int in never:
		print("      %s" % Massifs.describe(tile4))
	if not stray.is_empty():
		print("  ⚠ %d tuiles POSEES hors de la forme close :" % stray.size())
		for tile5: int in stray:
			print("      %s" % Massifs.describe(tile5))
	# ⚠ ET ON REGARDE LA QUESTION POSEE : reste-t-il une surface « toute seule », c'est-a-dire
	# une silhouette d'herbe qu'aucun tampon 3x3 ne peut produire ?
	var lonely: Array[int] = []
	for tile6: int in form:
		if Massifs.band_of(tile6) != Massifs.SURFACE:
			continue
		var sil: int = Massifs.sil_of(tile6)
		var cards: int = 0
		for card: int in [1, 4, 16, 64]:
			if (sil & card) != 0:
				cards += 1
		if cards < 2:
			lonely.append(tile6)
	print("  surfaces a moins de deux cardinaux : %d" % lonely.size())
	for tile7: int in lonely:
		print("      %s" % Massifs.describe(tile7))
	# ⚠ ET LA LISTE S'ECRIT EN S'AJOUTANT, JAMAIS EN REMPLACANT. Une battue qui ne rencontre pas
	# une tuile prouve qu'elle est rare, jamais qu'elle est impossible : ecraser la liste avec le
	# resultat d'une seule execution ferait DISPARAITRE des tuiles qu'une autre avait trouvees.
	# La liste ne peut donc que croitre, et chaque execution la corrobore ou l'etend.
	if args.has("--ecrire"):
		# ⚠ « LA LISTE NE PEUT QUE CROITRE » VAUT A MODELE CONSTANT, et c'est la precision qui
		# manquait. Quand la CLE change de sens -- le cisaillement entre dans l'identite -- une
		# entree d'avant ne designe plus rien : `SURFACE 223 libre` a survecu a l'union alors que
		# toutes ses occurrences portent desormais « cisaille a l'ouest ». Et quand une BATTUE
		# etait fausse -- l'ancien recenseur reparait ses mondes au lieu de refuser le coup --
		# elle a inscrit six tuiles qu'aucun geste n'atteint. Dans les deux cas la liste doit se
		# REDERIVER, pas se cumuler : `--refaire` le dit explicitement, et rien ne l'a en defaut.
		if not args.has("--refaire"):
			for old: int in Stored.tiles():
				met[old] = true
		var keys: Array[int] = []
		keys.assign(met.keys())
		keys.sort()
		var said: PackedStringArray = PackedStringArray()
		for key: int in keys:
			said.append(str(key))
		var lines: PackedStringArray = PackedStringArray([
			"# LE VOCABULAIRE DU PINCEAU : les tuiles que le GESTE atteint.",
			"#",
			"# GENERE PAR `tools/brush_census.gd -- <gestes> --ecrire` -- ne pas editer.",
			"#",
			"# C'EST CELUI-LA QU'ON LIVRE, PAS LA FORME CLOSE. Min trois n'est pas une regle en",
			"# soi : c'est la consequence d'un pinceau qui pose une tuile de surface PLEINE en 3x3",
			"# et laisse les huit contours se raccommoder par calcul. Le peintre peint de la",
			"# surface ; le reste suit. Le modele doit donc prevoir les tuiles necessaires a CELA,",
			"# ni plus ni moins. La forme close, elle, reste la BORNE HAUTE : elle garde I8, elle",
			"# n'est plus la cible.",
			"#",
			"# ET LA LISTE NE PEUT QUE CROITRE : une battue qui ne rencontre pas une tuile prouve",
			"# qu'elle est rare, jamais qu'elle est impossible. Ecraser la liste avec le resultat",
			"# d'une seule execution ferait disparaitre ce qu'une autre avait trouve.",
			"extends RefCounted",
			"",
			"static func tiles() -> Array[int]:",
			"	return [" + ", ".join(said) + "] as Array[int]",
			"",
		])
		var file: FileAccess = FileAccess.open(OUT, FileAccess.WRITE)
		file.store_string("
".join(lines))
		file.close()
		print("  ecrit : %s (%d tuiles)" % [OUT, keys.size()])
	quit(0)


## UNE MARCHE DU PINCEAU : des tampons 3x3 et des effacements 3x3, et rien d'autre.
##
## ⚠ ET LE PINCEAU CORRIGE, IL NE REFUSE PAS -- decision utilisateur. Un geste qui laisserait
## une case fine ou un pincement diagonal est RATTRAPE par la reparation ; s'il ne se rattrape
## pas, il est abandonne et le relief reste ce qu'il etait.
func _walk(rng: RandomNumberGenerator) -> Dictionary:
	var grid: Array[PackedByteArray] = []
	for y: int in range(TALL):
		var line: PackedByteArray = PackedByteArray()
		line.resize(WIDE)
		line.fill(0)
		grid.append(line)
	for x: int in range(RIM, WIDE - RIM):
		for y2: int in range(RIM, TALL - RIM):
			grid[y2][x] = 1
	var refused: int = 0
	var moves: int = 0
	var last: PackedStringArray = Lab.text(grid)
	for _move: int in range(rng.randi_range(6, 26)):
		moves += 1
		var keep: Array[PackedByteArray] = []
		for line2: PackedByteArray in grid:
			keep.append(line2.duplicate())
		var ox: int = rng.randi_range(RIM, WIDE - RIM - 3)
		var oy: int = rng.randi_range(RIM, TALL - RIM - 3)
		var raise: bool = rng.randf() < 0.68
		for y3: int in range(oy, oy + 3):
			for x3: int in range(ox, ox + 3):
				grid[y3][x3] = mini(int(grid[y3][x3]) + 1, 5) if raise \
						else maxi(int(grid[y3][x3]) - 1, 0)
		var mended: PackedStringArray = Lab.repair(grid)
		if mended.is_empty():
			refused += 1
			grid = keep
			continue
		last = mended
		for y4: int in range(TALL):
			for x4: int in range(WIDE):
				var level: int = HeightMask.level_at(mended, x4, y4)
				grid[y4][x4] = 0 if level < 0 else level + 1
	return {"world": last, "refused": refused, "moves": moves}


## UN BORD SUD EN MARCHES : quatre blocs de trois colonnes, chacun plongeant de zero a trois
## rangees. C'est exactement la forme qui fabrique un CISAILLEMENT -- la colonne de gauche
## s'arrete haut, sa jupe pend, et celle de droite continue en surface a cote d'elle.
##
## ⚠ MIN TROIS EST RESPECTE PAR CONSTRUCTION (les blocs font trois colonnes), mais on demande
## quand meme a `Gesture.legal` : la marge de pied et le gouffre ne se lisent pas sur la largeur.
func _stairs(deep: Array[int], top_level: int) -> PackedStringArray:
	var grid: Array[PackedByteArray] = []
	for _y: int in range(30):
		var row: PackedByteArray = PackedByteArray()
		row.resize(24)
		row.fill(0)
		grid.append(row)
	for y2: int in range(4, 26):
		for x: int in range(4, 20):
			grid[y2][x] = 1
	for x2: int in range(6, 18):
		var bottom: int = 10 + deep[mini((x2 - 6) / 3, 3)]
		for y3: int in range(6, bottom + 1):
			grid[y3][x2] = top_level + 1
	var out: PackedStringArray = PackedStringArray()
	for row2: PackedByteArray in grid:
		var said: String = ""
		for v: int in row2:
			said += "~" if v == 0 else str(v - 1)
		out.append(said)
	return out
