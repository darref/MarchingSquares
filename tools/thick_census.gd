# LE RECENSEMENT DU MODE EPAIS — quel vocabulaire survit quand rien ne fait une bande
# fine, prouve plutot que devine.
#
# LA REGLE, MIN TROIS : une case est « fine » si sa COURSE -- la suite de cases du meme
# etat qui la contient le long d'un axe -- fait moins de trois (bord + centre + bord).
# Le mode epais interdit toute case fine, pleine OU vide, dans chaque silhouette d'etage.
# L'epaisseur consultee est celle du noyau (core/thickness.gd) : une seule regle.
#
# LES SURFACES SE PROUVENT PAR FENETRES, EXHAUSTIVEMENT. L'index d'une case ne depend que
# de sa fenetre 3x3 ; il y en a 256 (centre plein). Sur un plan non borne, une fenetre est
# realisable en relief epais SI ET SEULEMENT SI :
#   - le centre n'est pas fin (ses deux paires sont dans la fenetre) ;
#   - aucune des quatre voisines cardinales n'est fine PAR SA PAIRE LATERALE interne
#     (ses deux coins adjacents) -- son autre paire touche l'exterieur, et l'exterieur est
#     libre : on y choisit une case du meme etat, puis on epaissit a l'infini.
#   Les coins, eux, ont leurs deux paires ouvertes sur l'exterieur : jamais forces.
# C'est un theoreme, pas un sondage : l'exterieur n'ajoute aucune contrainte vers
# l'interieur, puisqu'on n'ajoute jamais que des cases du meme etat que leur voisine.
# ⚠ ET IL VAUT A MIN TROIS COMME A MIN DEUX : toute course d'une fenetre a un bout sur le
# bord, donc prolongeable dehors -- sauf la course d'une case bornee des deux cotes, qui
# etait deja interdite. Memes 27 index.
#
# LES CROISEMENTS SE PROUVENT PAR TEMOINS : chaque config de quatre quadrants, batie en
# blocs 3x3, et le masque entier verifie epais.
#
# LES ROBES SE CHERCHENT : battue sur reliefs epais tires au sort, PLUS des escarpements
# construits (le hasard seul ne rencontre pas les pans a angle -- lecon deja payee par le
# controle croise). ⚠ C'est cette battue, passee a min trois, qui a revele les deux roles
# du REDAN -- (vide,devant) et (devant,vide) au corps 1 -- que le compte de 23 avait
# manques ; ils sont desormais construits, et la forme fermee du noyau est comparee au
# rencontre dans les deux sens.
#
#     godot --headless --path . --script res://tools/thick_census.gd
extends SceneTree

const BlobIndex := preload("res://core/blob_index.gd")
const Walls := preload("res://core/walls.gd")
const Thickness := preload("res://core/thickness.gd")

const TRIALS: int = 4000


func _bit(raw: int, flag: int) -> bool:
	return (raw & flag) != 0


## Le theoreme des fenetres, applique a une fenetre brute.
func _window_realizable(raw: int) -> bool:
	var n: bool = _bit(raw, BlobIndex.N)
	var e: bool = _bit(raw, BlobIndex.E)
	var s: bool = _bit(raw, BlobIndex.S)
	var w: bool = _bit(raw, BlobIndex.W)
	var ne: bool = _bit(raw, BlobIndex.NE)
	var se: bool = _bit(raw, BlobIndex.SE)
	var sw: bool = _bit(raw, BlobIndex.SW)
	var nw: bool = _bit(raw, BlobIndex.NW)
	# Le centre (plein) : fin si les deux d'un axe sont vides.
	if (not n and not s) or (not e and not w):
		return false
	# Les cardinales, par leur paire laterale interne.
	if ne != n and nw != n:
		return false
	if ne != e and se != e:
		return false
	if se != s and sw != s:
		return false
	if sw != w and nw != w:
		return false
	return true


## L'epaisseur est celle du noyau -- min TROIS, bord + centre + bord -- une seule regle.
func _mask_thick(mask: PackedStringArray) -> bool:
	return Thickness.thin_cells(mask).is_empty()


## ⚠ UN RELIEF LEGAL EST SIMPLEMENT EPAIS. La regle « au moins un flanc muet » a ete posee
## puis retiree : elle repondait au symptome, pas a la cause -- voir `role_survives`.
func _relief_thick(heights: PackedStringArray, _top: int) -> bool:
	return Thickness.thin_cells(heights).is_empty()

func _random_relief(rng: RandomNumberGenerator) -> PackedStringArray:
	# ⚠ LA BATTUE DOIT ETRE ASSEZ GRANDE POUR QUE LES ROLES PROFONDS EXISTENT. A 16x14 et
	# deux etages, la chute la plus longue fait six cases : le redan n'y etait rencontre
	# qu'au premier corps, et la forme fermee se serait figee sur ce sous-compte. Trois
	# etages donnent des chutes de neuf, donc les trois corps.
	var columns: int = 22
	var rows: int = 20
	for _try: int in range(60):
		var levels: Array = []
		for y: int in range(rows):
			var line: Array = []
			line.resize(columns)
			line.fill(0)
			levels.append(line)
		for _block: int in range(rng.randi_range(3, 6)):
			var w: int = rng.randi_range(3, 7)
			var h: int = rng.randi_range(3, 7)
			var px: int = rng.randi_range(0, columns - w)
			var py: int = rng.randi_range(0, rows - h)
			var lift: int = rng.randi_range(1, 3)
			for y: int in range(py, py + h):
				for x: int in range(px, px + w):
					levels[y][x] = maxi(levels[y][x] as int, lift)
		# ⚠ ET DU VIDE : LE MONDE A TROIS ETATS. Une battue qui ne pose jamais de vide ne
		# voit jamais une chute qui N'ATTERRIT PAS -- or c'est celle-la qui descend d'un
		# etage de plus, donc plus profond, donc jusqu'aux derniers corps. Le vide se pose
		# en blocs, jamais case par case : une case de vide isolee serait fine.
		if rng.randf() < 0.5:
			for _hole: int in range(rng.randi_range(1, 2)):
				var hw: int = rng.randi_range(3, 6)
				var hh: int = rng.randi_range(3, 6)
				var hx: int = rng.randi_range(0, columns - hw)
				var hy: int = rng.randi_range(0, rows - hh)
				for y: int in range(hy, hy + hh):
					for x: int in range(hx, hx + hw):
						levels[y][x] = -1
		var heights: PackedStringArray = PackedStringArray()
		for y: int in range(rows):
			var line: String = ""
			for x: int in range(columns):
				var level: int = levels[y][x] as int
				line += "~" if level < 0 else str(level)
			heights.append(line)
		if _relief_thick(heights, 2):
			return heights
	return PackedStringArray()


## Les escarpements construits : eperons de TROIS colonnes -- bord + centre + bord --
## avec et sans banquette, plus la gorge et la tour du cap pour les (vide,vide).
## ⚠ CHAQUE RELIEF CONSTRUIT EST AUSSI POSE EN MIROIR. Le miroir echange les deux flancs :
## l'ensemble des roles vivants est donc symetrique PAR CONSTRUCTION. Ne poser qu'un cote
## laissait la battue annoncer `(vide,devant)` a trois corps et `(devant,vide)` a un seul --
## un sous-compte qui ne vient pas du modele mais de ce qu'on a pris la peine de dessiner.
## C'est la meme faute que « le hasard seul ne rencontre pas les pans a angle », vue de
## l'autre cote.
func _mirrored(relief: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: String in relief:
		out.append(String(line).reverse())
	return out


func _escarpments() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	# Massif etage 1, deux eperons triples, chute vers la plaine.
	out.append(PackedStringArray([
		"0000000000000000000",
		"0111111111111111110",
		"0111111111111111110",
		"0111111111111111110",
		"0001110000011100000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
	]))
	# Massif etage 2 : chute de six, le corps 1 au rendez-vous.
	out.append(PackedStringArray([
		"0000000000000000000",
		"0222222222222222220",
		"0222222222222222220",
		"0222222222222222220",
		"0222222222222222220",
		"0002220000022200000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
	]))
	# Massif etage 2 a eperons triples, banquettes de TROIS rangees exactement sous eux,
	# quatre rangees sous leur levre : les pieds a angle se posent pendant que la paroi
	# voisine tombe encore.
	out.append(PackedStringArray([
		"0000000000000000000",
		"0222222222222222220",
		"0222222222222222220",
		"0222222222222222220",
		"0222222222222222220",
		"0002220000022200000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0001110000011100000",
		"0001110000011100000",
		"0001110000011100000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
		"0000000000000000000",
	]))
	# La gorge decalee : le bloc d'etage 2 dont la colonne ouest chute seule, longee par
	# les murs du bloc d'etage 1 decale.
	out.append(PackedStringArray([
		"0000000000",
		"0222200000",
		"0222200000",
		"0222200000",
		"0222200000",
		"0222200000",
		"0022220000",
		"0022220000",
		"0022220000",
		"0000000000",
		"0000000000",
		"0000000000",
		"0000000000",
	]))
	# La tour du cap : trois colonnes d'etage 2 ; deux atterrissent court sur le bloc
	# decale, la troisieme plonge jusqu'au bord du monde sans poser son pied -- son
	# dernier pas est un corps, seul en profondeur.
	out.append(PackedStringArray([
		"0000000000",
		"0022200000",
		"0022200000",
		"0022200000",
		"0022200000",
		"0022200000",
		"0111000000",
		"0111000000",
		"0111000000",
		"0000000000",
		"0000000000",
		"0000000000",
	]))
	# LE REDAN : un bord sud a decrochement d'une rangee, pose sur un tablier partiel
	# d'etage 1. La colonne entre le tablier et les colonnes en retrait plonge seule :
	# vide du cote tablier (sa robe est plus courte), devant du cote retrait (leur levre
	# est au nord de la sienne) -- (vide,devant) corps 1. Et son miroir pour (devant,vide).
	out.append(PackedStringArray([
		"0000000000000000",
		"0000000022222220",
		"0000000022222220",
		"0000000022222220",
		"0000000022222220",
		"0000000022222000",
		"0000000011110000",
		"0000000011110000",
		"0000000011110000",
		"0000000011110000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
	]))
	out.append(PackedStringArray([
		"0000000000000000",
		"0222222200000000",
		"0222222200000000",
		"0222222200000000",
		"0222222200000000",
		"0002222200000000",
		"0000111100000000",
		"0000111100000000",
		"0000111100000000",
		"0000111100000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
	]))
	for built: int in range(out.size()):
		out.append(_mirrored(out[built]))
	return out


func _initialize() -> void:
	# --- LES SURFACES, par le theoreme des fenetres.
	var alive: Dictionary = {}
	for raw: int in range(256):
		if _window_realizable(raw):
			alive[BlobIndex.canonicalize(raw)] = true
	var kept: Array = alive.keys()
	kept.sort()
	var dead: Array = []
	for index: int in BlobIndex.CANONICAL_INDICES:
		if not alive.has(index):
			dead.append(index)
	print("SURFACES : %d sur 47 survivent." % kept.size())
	print("  vivantes : %s" % str(kept))
	print("  mortes   : %s" % str(dead))

	# --- LES CROISEMENTS, par temoins en blocs 2x2.
	var corner_alive: int = 0
	for config: int in range(1, 16):
		var mask: PackedStringArray = PackedStringArray()
		for y: int in range(10):
			mask.append("..........")
		for quadrant: int in range(4):
			if (config & (1 << quadrant)) == 0:
				continue
			var base: Vector2i = [Vector2i(2, 2), Vector2i(5, 2),
					Vector2i(2, 5), Vector2i(5, 5)][quadrant]
			for dy: int in range(3):
				var line: String = mask[base.y + dy]
				for dx: int in range(3):
					line = line.substr(0, base.x + dx) + "#" + line.substr(base.x + dx + 1)
				mask[base.y + dy] = line
		if _mask_thick(mask):
			corner_alive += 1
	print("CROISEMENTS : %d sur 15 survivent." % corner_alive)

	# --- LES ROBES, par battue et par construction.
	var reached: Dictionary = {}
	var reliefs: Array[PackedStringArray] = _escarpments()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x50111
	for _trial: int in range(TRIALS):
		var relief: PackedStringArray = _random_relief(rng)
		if not relief.is_empty():
			reliefs.append(relief)
	for relief: PackedStringArray in reliefs:
		var roles: Dictionary = Walls.visible(relief)["roles"]
		for cell: Vector2i in roles.keys():
			reached[roles[cell]] = true
	var pans_alive: Dictionary = {}
	var role_count: int = 0
	for role: Vector2i in reached.keys():
		pans_alive[role.x] = true
		role_count += 1
	print("ROBES : %d roles sur 36 rencontres, %d pans sur 9." % [role_count, pans_alive.size()])
	for pan: int in range(Walls.PAN_COUNT):
		var line: String = "  (%s,%s) :" % [Walls.SIDE_NAMES[Walls.pan_west(pan)],
				Walls.SIDE_NAMES[Walls.pan_east(pan)]]
		for row: int in range(Walls.BLOCK_ROWS):
			line += " %s" % ("X" if reached.has(Vector2i(pan, row)) else ".")
		print(line)

	# --- LA FORME FERMEE DU NOYAU, comparee au rencontre DANS LES DEUX SENS.
	var disagreements: int = 0
	for pan: int in range(Walls.PAN_COUNT):
		for row: int in range(Walls.BLOCK_ROWS):
			var role: Vector2i = Vector2i(pan, row)
			var met: bool = reached.has(role)
			var claimed: bool = Thickness.role_survives(role)
			if met and not claimed:
				print("  ⚠ RENCONTRE MAIS NIE PAR LA FORME FERMEE : (%s,%s) %s" % [
						Walls.SIDE_NAMES[Walls.pan_west(pan)],
						Walls.SIDE_NAMES[Walls.pan_east(pan)], Walls.ROW_NAMES[row]])
				disagreements += 1
			if claimed and not met:
				print("  ⚠ PROMIS MAIS JAMAIS RENCONTRE : (%s,%s) %s" % [
						Walls.SIDE_NAMES[Walls.pan_west(pan)],
						Walls.SIDE_NAMES[Walls.pan_east(pan)], Walls.ROW_NAMES[row]])
				disagreements += 1
	if disagreements == 0:
		print("FORME FERMEE : d'accord avec le rencontre, %d roles." % role_count)
	quit(1 if disagreements > 0 else 0)
