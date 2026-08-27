extends SceneTree

## LE VOCABULAIRE BRUT : ce que la liberte laterale a rendu necessaire, et qui le porte.
##
## Jusqu'ici une tuile de surface etait un INDEX CANONIQUE -- la canonicalisation jetant une
## diagonale des que ses deux cardinaux sont pleins, « un coin diagonal isole ne change pas la
## silhouette ». Vrai du REMPLISSAGE. Faux du TRAIT : c'est exactement la que le bord fait une
## marche, et la case qui la porte est la seule a pouvoir la tracer (voir PLAN.md, L0/F1).
##
## Le vocabulaire est donc le VOISINAGE BRUT, filtre par l'epaisseur. Trois questions, et on y
## repond dans les deux sens :
##   1. combien y en a-t-il, en forme fermee -- `Thickness.window_realizable` sur les 256 ;
##   2. le guide livre les porte-t-il tous, et sinon lesquels manquent ;
##   3. la planche de preuve aussi -- c'est elle que le banc de l'echelle exerce.
##
## ⚠ ET ON BAT AUSSI DU RELIEF AU HASARD, pour savoir si la forme fermee est trop large : un
## voisinage que la forme accepte et que le monde ne produit jamais serait une tuile a peindre
## pour rien.

const HeightMask := preload("res://core/height_mask.gd")
const Coverage := preload("res://core/coverage.gd")
const Thickness := preload("res://core/thickness.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Modes := preload("res://core/modes.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")


func _initialize() -> void:
	# 1. La forme fermee.
	var closed: Array[int] = []
	for raw: int in range(256):
		if Thickness.window_realizable(raw):
			closed.append(raw)
	var canonical: Dictionary = {}
	for raw: int in closed:
		canonical[BlobIndex.canonicalize(raw)] = true
	print("=== LA FORME FERMEE ===")
	print("  voisinages bruts realisables en epais : %d" % closed.size())
	print("  soit %d silhouettes canoniques (le compte d'avant)" % canonical.size())
	print("")

	# 2. et 3. Ce que chaque relief livre porte.
	var guide: Dictionary = _seen(HeightMask.read(Modes.guide_path(Modes.EPAIS)))
	var board: Dictionary = _seen(ProofScene.relief(Families.BY_CELL))
	print("=== CE QUE LES RELIEFS LIVRES PORTENT ===")
	_report("le guide epais", guide, closed)
	_report("la planche de preuve", board, closed)
	print("")

	# 4. La battue : la forme fermee est-elle trop large ?
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260827
	var wild: Dictionary = {}
	var kept: int = 0
	while kept < 400:
		var relief: PackedStringArray = _random(rng)
		if not Thickness.thin_cells(relief).is_empty():
			continue
		kept += 1
		for raw: Variant in _seen(relief).keys():
			wild[raw] = true
	print("=== LA BATTUE ===")
	_report("%d reliefs epais au hasard" % kept, wild, closed)
	var never: Array[int] = []
	for raw: int in closed:
		if not wild.has(raw) and not guide.has(raw) and not board.has(raw):
			never.append(raw)
	print("")
	print("⚠ jamais rencontres, nulle part : %d  %s" % [never.size(), str(never)])
	print("   (la forme les accepte ; si le monde ne les produit jamais, ce sont des tuiles")
	print("    a peindre pour rien -- mais une battue qui ne rencontre pas prouve que c'est")
	print("    RARE, jamais que c'est impossible.)")
	quit()


func _report(label: String, seen: Dictionary, closed: Array[int]) -> void:
	var missing: Array[int] = []
	var outside: int = 0
	for raw: int in closed:
		if not seen.has(raw):
			missing.append(raw)
	for raw: Variant in seen.keys():
		if not Thickness.window_realizable(int(raw)):
			outside += 1
	print("  %-28s %3d / %d   manquants : %d %s%s" % [label, seen.size() - outside,
			closed.size(), missing.size(),
			str(missing) if missing.size() <= 12 else "(%d)" % missing.size(),
			"   ⚠ %d HORS FORME" % outside if outside > 0 else ""])


## Les voisinages bruts qu'un relief produit, silhouette d'etage par silhouette d'etage.
func _seen(relief: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	var top: int = 0
	for y: int in range(HeightMask.height(relief)):
		for x: int in range(HeightMask.width(relief)):
			top = maxi(top, HeightMask.level_at(relief, x, y))
	for storey: int in range(top + 1):
		var mask: PackedStringArray = HeightMask.silhouette(relief, storey)
		for y: int in range(HeightMask.height(mask)):
			for x: int in range(HeightMask.width(mask)):
				if Coverage.index_at(mask, x, y) == Coverage.NO_INDEX:
					continue
				out[Coverage.raw_neighbourhood(mask, x, y)] = true
	return out


func _random(rng: RandomNumberGenerator) -> PackedStringArray:
	var w: int = rng.randi_range(14, 20)
	var h: int = rng.randi_range(14, 20)
	var grid: Array[PackedByteArray] = []
	for y: int in range(h):
		var row: PackedByteArray = PackedByteArray()
		row.resize(w)
		grid.append(row)
	for stamp: int in range(rng.randi_range(5, 14)):
		var level: int = rng.randi_range(0, 3)
		var bw: int = rng.randi_range(3, 8)
		var bh: int = rng.randi_range(3, 8)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = maxi(row[x], level + 1)
				grid[y] = row
	for dig: int in range(rng.randi_range(1, 6)):
		var level: int = rng.randi_range(-1, 2)
		var bw: int = rng.randi_range(3, 7)
		var bh: int = rng.randi_range(3, 7)
		var ox: int = rng.randi_range(0, w - bw)
		var oy: int = rng.randi_range(0, h - bh)
		for y: int in range(oy, oy + bh):
			for x: int in range(ox, ox + bw):
				var row: PackedByteArray = grid[y]
				row[x] = mini(row[x], level + 1)
				grid[y] = row
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(h):
		var line: String = ""
		for x: int in range(w):
			line += "~" if grid[y][x] == 0 else str(grid[y][x] - 1)
		out.append(line)
	return out
