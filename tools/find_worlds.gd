extends SceneTree

## LES MONDES QUI PORTENT CE QUE LE VIVIER N'ATTEINT PAS.
##
##     godot --headless --path . --script res://tools/find_worlds.gd -- [tirages] [--ecrire]
##
## ⚠ UN MONDE QUI PORTE UNE TUILE **EST** SON TEMOIN, et la battue l'avait sous la main : elle
## le jetait. C'est de la que venait toute la divergence -- le recenseur rencontrait une tuile
## dans un monde tire au sort, l'ecrivait au vocabulaire, puis oubliait le monde ; le batisseur,
## qui tirait les siens, ne la retrouvait jamais, et le guide sortait avec DOUZE TUILES ABSENTES.
##
## Cet outil cherche les tuiles que `Lab.ground()` n'atteint pas, garde le monde qui les porte,
## et l'ecrit dans `core/found_worlds.gd`. Le vivier les relit ensuite : ce qui a ete trouve UNE
## FOIS reste trouve, et le vivier devient reproductible SANS cesser de croitre.
##
## ⚠ ET C'EST CE QUI FERME LA CLASSE ENTIERE DU PROBLEME. « Vivier partage » n'est plus une
## discipline qu'on peut oublier : c'est une consequence, puisque toute tuile du vocabulaire
## arrive desormais avec le relief qui la prouve.

const Gesture := preload("res://core/gesture.gd")
const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Brush := preload("res://core/brush_vocabulary.gd")
const Lab := preload("res://tools/relief_lab.gd")
const Found := preload("res://core/found_worlds.gd")

const OUT: String = "res://core/found_worlds.gd"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var draws: int = args[0].to_int() if not args.is_empty() else 600
	var writing: bool = args.has("--ecrire")

	# CE QUE LE VIVIER ATTEINT DEJA -- inutile de rechercher ce qu'on tient.
	var held: Dictionary = {}
	for world: PackedStringArray in Lab.ground():
		for tile: Variant in Massifs.paintable(world).values():
			held[int(tile)] = true
	var wanted: Array[int] = []
	for tile2: int in Brush.tiles():
		if not held.has(tile2):
			wanted.append(tile2)
	print("le vivier atteint %d tuiles ; %d a trouver" % [held.size(), wanted.size()])
	if wanted.is_empty():
		print("  rien a chercher : le vivier porte tout le vocabulaire.")
		quit(0)
		return

	# ⚠ ON GARDE LES MONDES DEJA TROUVES. Meme regle que le vocabulaire : ce qui a ete trouve
	# une fois ne se reperd pas parce qu'une execution a eu moins de chance.
	var keep: Array[PackedStringArray] = []
	var covered: Dictionary = {}
	for old: PackedStringArray in Found.all():
		keep.append(old)
		for tile3: Variant in Massifs.paintable(old).values():
			covered[int(tile3)] = true

	# ⚠ ET ON BALAIE PLUSIEURS GRAINES. Une seule suite de tirages est un seul chemin dans
	# l'espace des reliefs : c'est exactement pour ca que les anciennes executions trouvaient
	# des tuiles que la suivante manquait.
	var still: Array[int] = []
	for tile4: int in wanted:
		if not covered.has(tile4):
			still.append(tile4)
	var seen: int = 0
	for seed: int in range(24):
		if still.is_empty():
			break
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 0x574F524C + seed * 104729
		for _turn: int in range(draws):
			if still.is_empty():
				break
			var made: PackedStringArray = Lab.draw(rng, Lab.GROUND_W, Lab.GROUND_H)
			if made.is_empty():
				continue
			seen += 1
			var brought: Array[int] = []
			var paint: Dictionary = Massifs.paintable(made)
			for tile5: Variant in paint.values():
				if still.has(int(tile5)):
					brought.append(int(tile5))
			if brought.is_empty():
				continue
			keep.append(made)
			for tile6: int in brought:
				covered[tile6] = true
				still.erase(tile6)
			print("  monde retenu : %d tuile(s) neuve(s), reste %d"
					% [brought.size(), still.size()])
			# ⚠ ON ECRIT A CHAQUE PRISE, PAS A LA FIN. Cet outil n'ecrivait qu'apres toute la
			# boucle : trois heures de chasse ont ete perdues d'un coup en l'interrompant, alors
			# qu'elle avait deja des mondes en main. Une recherche longue qui ne pose pas de
			# jalons transforme toute interruption -- une coupure, une erreur, un arret voulu --
			# en perte totale. Le cout est nul : quelques kilo-octets ecrits par prise.
			if writing:
				_write(keep)
	print("%d mondes battus, %d mondes gardes, %d tuiles encore sans monde"
			% [seen, keep.size(), still.size()])
	for lost: int in still:
		print("      sans monde : %s" % Massifs.describe(lost))
	if writing:
		_write(keep)
		print("  ecrit : %s (%d mondes)" % [OUT, keep.size()])
	quit(0)


## ⚠ EN TABLEAUX SIMPLES, ENVELOPPES A LA LECTURE. Un `const` type `Array[PackedStringArray]`
## NE SE RESOUT PAS en Godot : le membre cesse d'exister, tout ce qui le precharge tombe avec
## lui, et le programme tourne sans fin sans une erreur claire. Piege deja paye au dossier.
func _write(worlds: Array[PackedStringArray]) -> void:
	var lines: PackedStringArray = PackedStringArray([
		"# LES MONDES QUI PORTENT CE QU'AUCUN VIVIER CONSTRUIT N'ATTEINT.",
		"#",
		"# GENERE PAR `tools/find_worlds.gd -- <tirages> --ecrire` -- ne pas editer a la main.",
		"#",
		"# UN MONDE QUI PORTE UNE TUILE EST SON TEMOIN, et la battue l'avait sous la main : elle",
		"# le jetait. Le recenseur rencontrait une tuile dans un monde tire au sort, l'ecrivait au",
		"# vocabulaire, puis oubliait le monde ; le batisseur, qui tirait les siens, ne la",
		"# retrouvait jamais. Douze tuiles manquaient au guide pour cette seule raison.",
		"#",
		"# ⚠ CE QUI EST ICI NE SE REPERD PAS. Le vivier les relit a chaque battue : il reste",
		"# reproductible SANS cesser de croitre.",
		"extends RefCounted",
		"",
		"const WORLDS: Array = [",
	])
	for world: PackedStringArray in worlds:
		lines.append("\t[")
		for row: String in world:
			lines.append("\t\t\"%s\"," % row)
		lines.append("\t],")
	lines.append("]")
	lines.append("")
	lines.append("")
	lines.append("## ⚠ ENVELOPPES ICI, PAS DANS LA CONSTANTE. Voir l'avertissement ci-dessus.")
	lines.append("static func all() -> Array[PackedStringArray]:")
	lines.append("\tvar out: Array[PackedStringArray] = []")
	lines.append("\tfor one: Array in WORLDS:")
	lines.append("\t\tvar world: PackedStringArray = PackedStringArray()")
	lines.append("\t\tfor row: Variant in one:")
	lines.append("\t\t\tworld.append(String(row))")
	lines.append("\t\tout.append(world)")
	lines.append("\treturn out")
	var file: FileAccess = FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
