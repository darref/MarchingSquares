extends SceneTree

## LE CISAILLEMENT — de l'herbe et de la roche du MEME massif, cote a cote.
##
## ⚠ LA BANDE ENCODE DEJA LA TRANSITION VERTICALE -- surface, chapiteau, corps, pied -- et c'est
## pour ca que la levre porte son trait. RIEN n'encodait la transition HORIZONTALE : la
## silhouette se lit sur l'EMPREINTE, donc une case d'herbe dont la voisine est la falaise de son
## PROPRE massif a ce bit MIS, se croit pleine, et rend la tuile d'interieur qui se repete
## partout. Sa voisine de roche fait de meme. Personne ne trace la frontiere, et la roche
## s'arrete NET contre l'herbe.
##
## Releve par l'utilisateur sur le massif 21 du guide, en regardant SON propre trait remonte --
## pas sur le dessin calcule, qui est la specification et a donc toujours l'air juste.
##
## ⚠ ET LES DEUX COTES SE RESERVENT (decision utilisateur). La loi « un flanc qui s'arrete ne se
## creuse pas, il se trait » ne demandait que la roche ; mais une frontiere tracee d'un seul cote
## se voit, et le rendu semble faux. Jugement de peintre, et c'est lui qui tranche.
##
## ⚠ TROIS FORCES D'ARGUMENT, ET ON DIT LAQUELLE ON EMPLOIE. La forme close est un THEOREME sur
## la fenetre : elle donne le plafond. Les battues donnent un plancher -- ne pas rencontrer une
## tuile prouve qu'elle est RARE, jamais qu'elle est impossible. L'ecart se paie en temoins
## construits ou en arguments d'impossibilite, jamais en « on ne l'a pas vue ».
##
##     godot --headless --path . --script res://tools/shear.gd [-- <mondes au geste>]

const Gesture := preload("res://core/gesture.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Families := preload("res://core/families.gd")
const Form := preload("res://core/massif_form.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var rounds: int = args[0].to_int() if args.size() > 0 else 300

	# LE PLAFOND : la forme close, exhaustive sur la fenetre.
	var ceiling: Dictionary = {}
	for key: int in Form.shear_vocabulary():
		if Massifs.cut_of(key) != 0:
			ceiling[key] = true

	var union: Dictionary = {}
	var guide: Dictionary = {}
	_collect(HeightMask.read("res://guides/massifs.txt"), guide)

	var wild: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260904
	var worlds: int = 0
	for _turn: int in range(rounds):
		var made: PackedStringArray = Gesture.walk(rng, 30, 24, 4)
		if made.is_empty():
			continue
		worlds += 1
		_collect(made, wild)

	# ⚠ ET UNE BATTUE DOIT AVOIR VRAIMENT CHERCHE. Le geste produit peu de cisaillements -- deux
	# sur six paysages -- donc le hasard ne prouve presque rien ici. On FABRIQUE donc des bords
	# sud en marches, qui sont exactement ce qui en produit.
	var stairs: Dictionary = {}
	var legal: int = 0
	for top_level: int in [1, 2]:
		for plan: int in range(256):
			var deep: Array[int] = []
			var rest: int = plan
			for _b: int in range(4):
				deep.append(rest % 4)
				rest /= 4
			var world: PackedStringArray = _stairs(deep, top_level)
			if not Gesture.legal(world):
				continue
			legal += 1
			_collect(world, stairs)

	for source: Dictionary in [guide, wild, stairs]:
		for key2: int in source.keys():
			if Massifs.cut_of(key2) != 0:
				union[key2] = true

	print("LE CISAILLEMENT, ce que chaque source en dit :")
	print("  le guide livre                          : %d tuiles" % _cut(guide))
	print("  %d paysages batis au geste              : %d tuiles" % [worlds, _cut(wild)])
	print("  %d bords sud en marches (fabriques)     : %d tuiles" % [legal, _cut(stairs)])
	print("  ------------------------------------------------")
	print("  PLANCHER, l'union des trois             : %d tuiles" % union.size())
	print("  PLAFOND, la forme close (theoreme)      : %d tuiles" % ceiling.size())
	print("")
	print("  le vocabulaire livre passerait de %d a %d, et au pire %d"
			% [Families.massif_tiles().size(), Families.massif_tiles().size() + union.size(),
			Families.massif_tiles().size() + ceiling.size()])
	var outside: int = 0
	for key3: int in union.keys():
		if not ceiling.has(key3):
			outside += 1
	print("  ⚠ %d tuiles atteintes HORS du plafond : la forme close les manquerait" % outside)
	print("")
	print("  les tuiles du plancher :")
	var rows: Array = []
	rows.assign(union.keys())
	rows.sort()
	for key4: int in rows:
		print("      %s" % Massifs.describe(key4))
	quit()


func _cut(source: Dictionary) -> int:
	var many: int = 0
	for key: int in source.keys():
		if Massifs.cut_of(key) != 0:
			many += 1
	return many


## Un plateau dont le bord sud descend PAR MARCHES : quatre blocs de trois colonnes, chacun
## plongeant de zero a trois rangees. Min trois est respecte par construction -- les blocs font
## trois colonnes -- et `Gesture.legal` tranche le reste.
func _stairs(deep: Array[int], top_level: int) -> PackedStringArray:
	var wide: int = 24
	var tall: int = 30
	var grid: Array[PackedByteArray] = []
	for _y: int in range(tall):
		var row: PackedByteArray = PackedByteArray()
		row.resize(wide)
		row.fill(0)
		grid.append(row)
	for y2: int in range(4, tall - 4):
		for x: int in range(4, wide - 4):
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


## Les tuiles que ce relief pose, cisaillement compris.
##
## ⚠ ON DEMANDE AU MODELE, ON NE RECALCULE PAS. Cet outil portait sa propre lecture du
## cisaillement le temps de le chiffrer ; depuis que `Massifs.poses` le porte, en garder une
## seconde serait deux copies d'une meme regle -- et deux copies finissent toujours par diverger.
func _collect(world: PackedStringArray, seen: Dictionary) -> void:
	for one: Dictionary in Massifs.poses(world):
		seen[Massifs.key_of(one)] = true
