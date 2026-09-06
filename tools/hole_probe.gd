# LE TROU : COUTE-T-IL VRAIMENT QUELQUE CHOSE AU MODELE ?
#
# ⚠ ON REGARDE, ON NE DEDUIT PAS. La question posee par l'utilisateur le 06/09 : un trou pose
# DANS LA SURFACE, a une marge du bord, ne serait-il pas gratuit ? Le plan du jour affirmait le
# contraire (« il coute une face NORD ») sans l'avoir mesure -- exactement ce que la methode
# interdit.
#
# La sonde bat quelques reliefs troues, demande au GESTE s'il les accepte, puis compare les
# tuiles qu'ils posent au vocabulaire livre (`core/brush_vocabulary.gd`) et a la forme close
# (I8). Trois reponses possibles, et elles n'ont pas le meme prix :
#   - le geste refuse       -> c'est une clause du PINCEAU qu'il faudrait lever, pas le modele ;
#   - toutes les cles sont deja au vocabulaire -> le trou est GRATUIT ;
#   - des cles manquent     -> elles sont nommees, et c'est ca que le trou coute.
#
#     godot --headless --path . --script res://tools/hole_probe.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Gesture := preload("res://core/gesture.gd")
const Brush := preload("res://core/brush_vocabulary.gd")
const MassifForm := preload("res://core/massif_form.gd")

## La marge de vide autour du monde : au moins une chute entiere, sinon la falaise du bord du
## monde tombe hors du cadre.
const EDGE: int = 4


func _initialize() -> void:
	var known: Dictionary = {}
	for tile: int in Brush.tiles():
		known[tile] = true
	var closed: Dictionary = {}
	for tile2: int in MassifForm.vocabulary():
		closed[tile2] = true

	var cases: Array = [
		["cuvette 5x5 dans un plateau d'etage 1 (fond : la plaine)", _dug(1, 0, 13, 5)],
		["cuvette 5x5 dans un plateau d'etage 2 (fond : etage 1)", _dug(2, 1, 13, 5)],
		["trou 5x5 d'etage 2 jusqu'a la plaine (chute de deux etages)", _dug(2, 0, 13, 5)],
		["puits 5x5 dans la PLAINE, jusqu'au vide", _dug(0, HeightMask.VOID, 13, 5)],
		["cuvette 3x3, la plus petite que min trois autorise", _dug(1, 0, 13, 3)],
		["temoin : le meme plateau SANS trou", _dug(1, 1, 13, 5)],
	]

	for entry: Array in cases:
		_report(String(entry[0]), entry[1] as PackedStringArray, known, closed)

	# ⚠ UN SEUL POINT NE PROUVE RIEN. On balaie les tailles de trou et les etages, et l'on cumule
	# ce qui manque : une tuile absente sur un seul carre serait un accident, la meme absente sur
	# toute une famille est un defaut du recensement.
	print("")
	print("=== BALAYAGE : trous carres de 3 a 9, plateaux d'etage 1 a 3 ===")
	var short: Dictionary = {}
	var refused: int = 0
	var tried: int = 0
	for top: int in range(1, 4):
		for hole: int in range(3, 10):
			var world: PackedStringArray = _dug(top, top - 1, 21, hole)
			tried += 1
			var faults: Array[String] = Gesture.faults(world)
			if not faults.is_empty():
				refused += 1
				print("    REFUSE  etage %d, trou %dx%d : %s" % [top, hole, hole,
						", ".join(faults)])
				continue
			for pose: Dictionary in Massifs.poses(world):
				var tile4: int = Massifs.key_of(pose)
				if not known.has(tile4):
					var seen_in: Array = short.get(tile4, []) as Array
					seen_in.append("etage %d, trou %dx%d" % [top, hole, hole])
					short[tile4] = seen_in
	print("    %d reliefs, %d refuses par le geste" % [tried, refused])
	if short.is_empty():
		print("    AUCUNE tuile manquante : le trou carre est gratuit sur toute la famille")
	else:
		var order: Array[int] = []
		for tile5: Variant in short.keys():
			order.append(int(tile5))
		order.sort()
		for tile6: int in order:
			var cases_of: Array = short[tile6] as Array
			print("    %d  %s" % [tile6, Massifs.describe(tile6)])
			print("        vue dans %d relief(s), dont : %s" % [cases_of.size(),
					String(cases_of[0])])
	quit(0)


## Un plateau carre de `side` cases a l'etage `top`, creuse en son centre d'un carre de `hole`
## cases pose a l'etage `floor_level`. ⚠ LA MARGE EST CALCULEE, PAS SUPPOSEE : elle vaut
## (side - hole) / 2, et le rapport l'affiche pour qu'on la relise.
static func _dug(top: int, floor_level: int, side: int, hole: int) -> PackedStringArray:
	var span: int = side + 2 * EDGE
	var rows: PackedStringArray = PackedStringArray()
	var start: int = EDGE + (side - hole) / 2
	for y: int in range(span):
		var line: String = ""
		for x: int in range(span):
			var inside: bool = x >= EDGE and y >= EDGE and x < EDGE + side and y < EDGE + side
			if not inside:
				line += HeightMask.VOID_CHAR
				continue
			var dug: bool = x >= start and y >= start and x < start + hole and y < start + hole
			var level: int = floor_level if dug else top
			line += HeightMask.VOID_CHAR if level < 0 else String.num_int64(level)
		rows.append(line)
	return rows


static func _report(title: String, world: PackedStringArray, known: Dictionary,
		closed: Dictionary) -> void:
	print("")
	print("--- %s" % title)
	var faults: Array[String] = Gesture.faults(world)
	if faults.is_empty():
		print("    geste      : ACCEPTE")
	else:
		print("    geste      : REFUSE -- %s" % ", ".join(faults))
	var poses: Array[Dictionary] = Massifs.poses(world)
	var seen: Dictionary = {}
	for pose: Dictionary in poses:
		seen[Massifs.key_of(pose)] = true
	var missing: Array[int] = []
	var outside: Array[int] = []
	for tile: int in seen.keys():
		if not known.has(tile):
			missing.append(tile)
		if not closed.has(tile):
			outside.append(tile)
	missing.sort()
	outside.sort()
	print("    poses      : %d, pour %d tuiles distinctes" % [poses.size(), seen.size()])
	if missing.is_empty():
		print("    vocabulaire: TOUT EST DEJA LIVRE -- le trou ne coute aucune tuile")
	else:
		print("    vocabulaire: %d tuile(s) ABSENTE(S) du vocabulaire livre :" % missing.size())
		for tile2: int in missing:
			print("        %d  %s" % [tile2, Massifs.describe(tile2)])
	if not outside.is_empty():
		print("    I8         : %d tuile(s) HORS DE LA FORME CLOSE :" % outside.size())
		for tile3: int in outside:
			print("        %d  %s" % [tile3, Massifs.describe(tile3)])
