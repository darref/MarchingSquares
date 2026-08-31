# LE BATISSEUR DU GUIDE EPAIS — les accidents composes, et le guide qui se prouve.
#
# Le mode epais interdit toute bande fine -- course de moins de TROIS, bord + centre +
# bord (core/thickness.gd). Son guide se compose donc d'accidents redessines en gras :
# encoches 3x2, sabliers a trous 3x3, moulins a bras triples, contacts diagonaux de
# blocs 3x3, gorge decalee, tour du cap, escarpements a eperons TRIPLES, et les deux
# REDANS -- les roles (vide,devant) et (devant,vide) du corps 1, ceux que min trois a
# reveles. Le relief se decrit accident par accident, jamais en ASCII -- lecon du
# depot -- et CE fichier est le seul endroit ou leur geometrie est ecrite.
#
# IL SE VERIFIE EN S'ECRIVANT : epaisseur, 27/27 surfaces, 25/25 roles, 15/15
# croisements, zero robe hors grille, vocabulaire entier hors de la plaine. S'il
# echoue, il ecrit quand meme le guide et dit ce qui manque -- c'est un outil
# d'iteration, le runner reste le juge final.
#
#     godot --headless --path . --script res://tools/build_epais.gd
extends SceneTree

const HeightMask := preload("res://core/height_mask.gd")
const Families := preload("res://core/families.gd")
const Walls := preload("res://core/walls.gd")
const CornerIndex := preload("res://core/corner_index.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const BrinkLips := preload("res://core/brink_lips.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Coverage := preload("res://core/coverage.gd")
const Brink := preload("res://core/brink.gd")
const BrinkWitnesses := preload("res://core/brink_witnesses.gd")

const WIDTH: int = 104
## ⚠ LE GUIDE S'ALLONGE POUR SA RESERVE, et c'est un prix a l'ecran qu'il faut assumer :
## la case retrecit. Le paysage occupe le nord, les temoins puis la reserve le sud.
## Un outil parfait ne peut pas ne pas montrer une tuile : le game dev qui construit
## precisement ce cas-la ne doit pas se retrouver bloque. Voir `_witnesses` et `_reserve`.
## ⚠ ET LA MARGE BASSE N'EST PAS UNE COQUETTERIE : la plaine borde le vide, donc elle a sa
## falaise, et une robe hors du cadre est une tuile impeignable. Sept rangees -- une chute de
## trois, plus le liseré de vide que chaque relief doit declarer.
const FOOTER: int = 7
const HEIGHT: int = 162
const OUT_PATH: String = "res://guides/epais.txt"

var _levels: Array = []


func _fill(x0: int, y0: int, x1: int, y1: int, level: int) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			(_levels[y] as Array)[x] = maxi((_levels[y] as Array)[x] as int, level)


func _carve(x0: int, y0: int, x1: int, y1: int, level: int) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			(_levels[y] as Array)[x] = level


## Un moulin : deux bras 3x3 en quinconce autour d'un coude -- deux cardinaux pleins,
## la diagonale entre eux vide. Chaque bras fait bord + centre + bord dans les deux
## axes, et le coude lui-meme a ses courses de trois. `turn` choisit l'orientation.
func _windmill(cx: int, cy: int, turn: int) -> void:
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	for dy: int in range(-3, 0):
		for dx: int in range(-2, 1):
			cells.append(Vector2i(dx, dy))
	for dy: int in range(0, 3):
		for dx: int in range(1, 4):
			cells.append(Vector2i(dx, dy))
	for offset: Vector2i in cells:
		var spun: Vector2i = offset
		for _quarter: int in range(turn):
			spun = Vector2i(-spun.y, spun.x)
		var at: Vector2i = Vector2i(cx, cy) + spun
		(_levels[at.y] as Array)[at.x] = maxi((_levels[at.y] as Array)[at.x] as int, 1)


func _compose() -> void:
	_levels.clear()
	for y: int in range(HEIGHT):
		var line: Array = []
		line.resize(WIDTH)
		line.fill(-1)
		_levels.append(line)

	# LA PLAINE : le socle, avec sa cote qui ondule par ajouts -- jamais par retraits.
	_fill(2, 4, 101, HEIGHT - 7, 0)
	_fill(12, 2, 17, 3, 0)
	_fill(52, 2, 57, 3, 0)
	_fill(8, 38, 23, 39, 0)
	_fill(28, 38, 55, 39, 0)
	_fill(60, 38, 67, 39, 0)

	# A. LE MASSIF A ENCOCHES : bords, coins, rentrants, et les bords-moins-un-coin --
	# une encoche de TROIS cases de long sur deux de profond par cote. Les encoches
	# ouest et est font ecreter la robe du dessus contre le massif qui reprend : deux
	# poses derriere gratuites.
	_fill(5, 7, 18, 15, 1)
	_carve(9, 7, 11, 8, 0)
	_carve(5, 10, 6, 12, 0)
	_carve(17, 10, 18, 12, 0)
	_carve(13, 14, 15, 15, 0)

	# B. LE SABLIER : trois trous 3x3 en quinconce -- les pincements 119 et 221 entre
	# eux. ⚠ TROIS rangees pleines au moins entre un trou et le bord, sinon la marge
	# est fine. Chaque trou ecrete la robe de sa levre interieure : poses derriere.
	_fill(22, 6, 38, 18, 1)
	_carve(25, 9, 27, 11, 0)
	_carve(29, 13, 31, 15, 0)
	_carve(33, 9, 35, 11, 0)

	# B'. LE DEFILE : un bloc 4x3 sous le rebord sud-ouest du sablier, a TROIS rangees
	# de creux -- il ECRETE les robes qui tombent sur lui et recoit leurs poses
	# derriere. Il touche l'escarpement a banquette par l'est : adjacence legale.
	_fill(27, 22, 30, 24, 1)

	# C. LES MOULINS : les quatre coudes, un par orientation, bras triples.
	_windmill(45, 9, 0)
	_windmill(55, 9, 1)
	_windmill(65, 9, 2)
	_windmill(75, 9, 3)

	# R. LES DEUX REDANS -- les roles que min trois a reveles : un bord sud a
	# decrochement d'une rangee, pose sur un tablier partiel d'etage 1. La colonne
	# entre le tablier et les colonnes en retrait plonge seule : vide du cote tablier,
	# devant du cote retrait -- (vide,devant) corps 1, et son miroir.
	_fill(81, 6, 87, 9, 2)
	_fill(81, 10, 85, 10, 2)
	_fill(81, 11, 84, 14, 1)
	_fill(91, 6, 97, 9, 2)
	_fill(93, 10, 97, 10, 2)
	_fill(94, 11, 97, 14, 1)

	# I. LE PIGNON A DEUX MARCHES -- les deux couples vide/devant du CORPS 1.
	# Un bloc dont le bord sud descend d'une rangee a CHAQUE bout, puis d'une autre : la
	# colonne du milieu de chaque marche a, d'un cote, une face lancee d'une levre plus au
	# nord (`devant`) et de l'autre LE SOMMET DU PLATEAU qui continue vers le sud (`vide`
	# depuis que le sommet d'un plateau n'est plus de la roche). Le pignon donne les deux
	# orientations d'un seul bloc, ce qui vaut mieux que deux accidents miroirs a caser.
	_fill(86, 18, 101, 21, 2)
	_fill(89, 22, 98, 22, 2)
	_fill(90, 23, 97, 29, 2)

	# J. LE CAP A UNE MARCHE -- (vide,vide) au CHAPITEAU. Une colonne qui tombe SEULE une
	# rangee avant ses voisines, au bout ouest d'une levre : a l'ouest le sol d'en bas, a
	# l'est le sommet du plateau qui n'est pas encore tombe. Ni l'un ni l'autre n'est de la
	# roche, donc les deux flancs sont vides -- et c'est le seul endroit du guide ou une
	# levre n'a de masse d'aucun cote.
	# ⚠ TROIS RANGEES DE PLAINE LA SEPARENT DES CONTACTS DIAGONAUX : posee plus haut,
	# elle laissait une rangee vide d'une case entre les deux -- fine.
	_fill(6, 32, 13, 35, 1)
	_fill(7, 36, 13, 36, 1)

	# D. LES CONTACTS DIAGONAUX : deux paires de blocs 3x3, une par orientation.
	_fill(5, 23, 7, 25, 1)
	_fill(8, 26, 10, 28, 1)
	_fill(14, 26, 16, 28, 1)
	_fill(17, 23, 19, 25, 1)

	# E. L'ESCARPEMENT A BANQUETTE : eperons TRIPLES avances d'une rangee, terrasses
	# 3x3 EXACTEMENT sous eux (jamais sous leurs voisines, qui doivent tomber encore
	# quand l'eperon pose son pied), quatre rangees sous leur levre -- les pieds a
	# angle. Trois colonnes plates consecutives entre les eperons : le chapiteau
	# (muet,muet).
	_fill(31, 23, 46, 26, 2)
	_fill(34, 27, 36, 27, 2)
	_fill(41, 27, 43, 27, 2)
	_fill(34, 31, 36, 33, 1)
	_fill(41, 31, 43, 33, 1)

	# F. L'ESCARPEMENT PROFOND : chute de six d'un trait, eperons triples -- les
	# corps a angle pendant que les parois voisines tombent encore.
	_fill(50, 23, 72, 27, 2)
	_fill(54, 28, 56, 28, 2)
	_fill(64, 28, 66, 28, 2)

	# G. LA GORGE DECALEE : un bloc d'etage 2 dont la colonne ouest chute seule de
	# six, longee par les murs du bloc d'etage 1 decale -- (vide,vide) en profondeur,
	# pied compris.
	_fill(76, 23, 79, 27, 2)
	_fill(77, 28, 80, 31, 1)

	# H. LA TOUR DU CAP : trois colonnes d'etage 2 ; deux atterrissent court sur le
	# bloc decale, la troisieme plonge de six jusqu'au vide SANS poser son pied --
	# son dernier pas est un corps, seul en profondeur : (vide,vide) corps 0.
	_fill(84, 27, 86, 31, 2)
	_fill(83, 32, 85, 35, 1)


## LES TEMOINS — les agencements que le paysage ne produit jamais de lui-meme.
##
## ⚠ CES HUIT ROLES-LA EXISTENT, ET UN OUTIL PARFAIT NE PEUT PAS NE PAS LES AVOIR. Le
## game dev qui construit precisement ce cas-la ne doit pas se retrouver bloque. Ils
## demandent tous la meme chose : la face d'un etage SUPERIEUR qui passe a cote de la
## mienne. `(devant,devant)` en est l'exemple pur -- ma voisine est couverte a la fois
## par la robe de mon etage et par celle d'un etage plus haut, et c'est la PLUS HAUTE
## qu'on voit, dont la levre est plus au nord : elle est en retrait, je suis devant.
##
## ⚠ ILS NE SONT PAS DESSINES A LA MAIN, ILS SONT TROUVES. La battue du recensement les
## rencontre ; on lui a demande d'en dumper un exemplaire, et ce sont ces reliefs-la,
## recopies tels quels. Dessiner ces croisements a la main, c'est se tromper d'une case
## et d'un etage a chaque essai -- la lecon est deja au dossier.
func _witnesses() -> Array:
	var out: Array = []
	# vide|vide / corps 0, vide|vide / corps 1
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
	# vide|devant / pied
	out.append(PackedStringArray([
			"0000000000000000000000",
			"0000000033300000000000",
			"0000000233322200000000",
			"0000000233322200000000",
			"0000000233322200000000",
			"0000000233322200000000",
			"0000000233322200000000",
			"0000000222222200000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000222200000000",
			"0000000000222233300000",
			"0000000000222233300000",
			"0000000000222233300000",
			"0000000000222233300000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
	]))
	# devant|vide / pied
	out.append(PackedStringArray([
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0111111100000000000000",
			"0133331100000000000000",
			"0133331100000000000000",
			"0333333100000000000000",
			"0333333100000000000000",
			"0333333100000000~~~000",
			"0111111100000000~~~000",
			"0000000000000000~~~000",
			"0000000000000000~~~000",
			"0000000000000000000000",
			"0000000000000000003333",
			"0000000000000000003333",
			"0000000000000000003333",
			"0000000000000000003333",
			"0000000000000000003333",
			"0000000000000000000000",
	]))
	# devant|devant / chapiteau, devant|devant / corps 0
	out.append(PackedStringArray([
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000002222000000000000",
			"0000002222000000000000",
			"0011112222000000000000",
			"0011112222000000000000",
			"0011112222000000000000",
			"0011112222000000000000",
			"0011112222000000000000",
			"0011111111000000000000",
			"0011111111000000000000",
			"0000011111000000000000",
			"0000000000000000000000",
			"0000000000000000000~~~",
			"0000000000000000000~~~",
			"0000000000000000000~~~",
			"0000000000000000000~~~",
			"0000000000000000000~~~",
	]))
	# devant|devant / corps 1, devant|devant / corps 2
	out.append(PackedStringArray([
			"0000000022222200000000",
			"0003333333222200000000",
			"0003333333222200000000",
			"0003333333222200000000",
			"0003333333222200000000",
			"0003333333200000000000",
			"0000000022200000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000111000000000000",
			"0000000111000000000000",
			"0000000111000000000000",
			"0000000000000000000000",
			"0000000000011111100000",
			"0000000000011111100000",
			"0000000000011111100000",
			"0000000000000000000000",
			"0000000000000000000000",
			"0000000000000000000000",
	]))
	return out


## Un temoin pose dans la reserve, avec de la plaine sous lui pour que ses chutes
## atterrissent : une robe hors du cadre est une tuile impeignable.
func _stamp_witness(x0: int, y0: int, rows: PackedStringArray) -> void:
	for y: int in range(rows.size()):
		var line: String = rows[y]
		for x: int in range(line.length()):
			var glyph: String = line[x]
			var level: int = -1 if glyph == "~" else int(glyph)
			_fill(x0 + x, y0 + y, x0 + x, y0 + y, level)

## LA RESERVE — les tuiles que le paysage ne produit pas de lui-meme.
##
## ⚠ UN GUIDE DOIT EXHIBER TOUT LE VOCABULAIRE, sinon la tuile qu'il ne montre pas n'est
## peignable nulle part et l'export se ferme pour toujours. Or certaines tuiles ne naissent
## que d'agencements que le paysage n'a aucune raison de contenir -- les silhouettes de COIN
## avec une falaise voisine, par exemple, que des accidents de terrain ne produisent pas.
##
## ⚠ ON NE LES DESSINE PAS A LA MAIN : on reutilise l'ilot de la PLANCHE DE PREUVE, qui
## sait fabriquer le voisinage exact d'une tuile depuis sa seule identite. Un accident de
## terrain dessine a la main se trompe d'une case et d'un etage a chaque essai -- la lecon
## est deja au dossier ; ici la geometrie est CALCULEE, comme la planche.
##
## ⚠ ET LA RESERVE N'EST PAS UN PAYSAGE, ELLE NE PRETEND PAS L'ETRE. Elle est au sud du
## guide, apres la terre. Le paysage sert a juger le rendu ; la reserve sert a ce qu'aucune
## tuile ne manque. Confondre les deux, c'etait demander a un seul dessin d'etre a la fois
## beau et exhaustif -- la double injonction qui deforme le guide depuis le debut.
func _reserve(top: int) -> int:
	# ⚠ ON COMPTE COMME LE CONTROLE COMPTE, sinon on ne repond pas a sa question. Le
	# controle exige la tuile HORS DE LA PLAINE et hors des cases de robe -- l'etage 0 est du
	# decor, il ne prend pas le crayon, et une case sous une face porte la face. Compter sur
	# la carte brute faisait croire deux tuiles deja la : elles n'etaient portees que par une
	# case de plaine, donc par personne.
	var heights: PackedStringArray = _mask()
	var have: Dictionary = {}
	var surface: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	for at: Vector2i in surface.keys():
		if HeightMask.level_at(heights, at.x, at.y) >= 1:
			have[int(surface[at])] = true
	var missing: Array[int] = []
	for tile: int in Thickness.SURFACE_INDICES:
		if not have.has(tile):
			missing.append(tile)
	# Les temoins d'abord : ils portent les roles de robe que le paysage n'a pas. Une seule
	# fois -- ils ne dependent pas de ce qui manque.
	if not _witnessed:
		_witnessed = true
		var band: int = top
		var wx: int = 4
		for rows: PackedStringArray in _witnesses():
			var w: int = rows[0].length()
			if wx + w > WIDTH - 4:
				wx = 4
				band += 26
			_stamp_witness(wx, band, rows)
			wx += w + 4
		top = band + 26

	# ⚠ ET LA RESERVE SE RELIT, PARCE QU'ELLE SE MODIFIE ELLE-MEME. Le compte des manquantes
	# se prend AVANT de poser quoi que ce soit -- or poser un ilot change les cases de plaine
	# autour de lui, et une tuile qu'une case de plaine portait toute seule peut disparaitre
	# en cours de route. Deux tuiles sortaient ainsi manquantes alors que chaque ilot pose
	# etait juste : elles n'avaient jamais ete posees, on les croyait deja la. On boucle donc
	# jusqu'au point fixe, ce qui est toujours atteint -- chaque tour ne fait qu'ajouter.
	if missing.is_empty():
		return top
	# ⚠ LE MEME ILOT QUE LA PLANCHE DE PREUVE, LEVRE COMPRISE. Le guide doit EXHIBER toute
	# tuile qu'il pretend livrer : celle qu'il ne montre pas n'est peignable nulle part, et
	# l'export se ferme pour toujours. On reutilise donc l'ilot -- calcule depuis l'index,
	# plus la falaise voisine que `core/brink_lips.gd` a cherchee et fait verifier.
	var pitch_x: int = ProofScene.PITCH_X
	var pitch_y: int = ProofScene.PITCH_Y
	var columns: int = maxi(1, (WIDTH - 8) / pitch_x)
	var rows: int = (missing.size() + columns - 1) / columns
	for order: int in range(missing.size()):
		var cx: int = 4 + (order % columns) * pitch_x + ProofScene.ISLAND_CENTRE.x
		var cy: int = top + (order / columns) * pitch_y + ProofScene.ISLAND_CENTRE.y
		for offset: Vector2i in ProofScene.island_cells(
				BlobIndex.silhouette(missing[order])):
			_fill(cx + offset.x, cy + offset.y, cx + offset.x, cy + offset.y, 1)
		for offset: Variant in (BrinkLips.LIPS.get(missing[order], []) as Array):
			var at: Vector2i = offset as Vector2i
			_fill(cx + at.x, cy + at.y, cx + at.x, cy + at.y, 2)
		_placed.append(Vector3i(cx, cy, missing[order]))
	return top + rows * pitch_y


var _placed: Array[Vector3i] = []
var _witnessed: bool = false


## Chaque temoin de bord pose : la case, et la cle qu'elle doit porter.
var _brinks: Array[Array] = []


## LA SECONDE RESERVE : LES TEMOINS DES BITS DE BORD.
##
## ⚠ ET C'EST UN AUTRE VOCABULAIRE QUE LES 27 SILHOUETTES. Une tuile du contour prouve est un
## couple (silhouette, bits de bord) -- ce qu'une case sait de ce que ses voisines TRACENT --
## et la forme fermee en compte 23 dessins. Dix d'entre eux ne naissent d'aucun accident
## nomme : ils demandent une banquette qui s'arrete UNE rangee au-dessus d'un bord, une face
## qui en longe une autre. La famille ALIGNEE sur trois, enumeree en entier (19 683 reliefs),
## n'en rend AUCUN -- il faut des poses decalees.
##
## ⚠ ILS NE SONT PAS DESSINES A LA MAIN, ILS SONT TROUVES -- meme raison, mot pour mot, que
## les huit temoins de robe plus haut. `tools/brink_witnesses.gd` les cherche, les decoupe et
## les reverifie au milieu d'un champ de plaine ; ici on les repose, et on revérifie encore.
##
## ⚠ ET ILS SONT DANS LE GUIDE, PAS DANS UN FICHIER A COTE -- regle utilisateur : « le but du
## soft est de tout avoir en face de soi en meme temps ». Le prix est en rangees, et il est
## dit : le guide s'allonge, la case retrecit a l'ecran. C'est le prix de l'exhaustivite.
func _brink_reserve(top: int) -> int:
	var band: int = top
	var wx: int = 4
	var tall: int = 0
	for at: int in range(BrinkWitnesses.BLOCKS.size()):
		var rows: PackedStringArray = PackedStringArray()
		for line: Variant in (BrinkWitnesses.BLOCKS[at] as Array):
			rows.append(String(line))
		var wide: int = rows[0].length()
		if wx + wide > WIDTH - 4:
			wx = 4
			band += tall + 4
			tall = 0
		_stamp_witness(wx, band, rows)
		for spot: Variant in (BrinkWitnesses.CARRIES[at] as Array):
			var where: Vector3i = spot as Vector3i
			_brinks.append([Vector2i(wx + where.x, band + where.y), where.z])
		wx += wide + 4
		tall = maxi(tall, rows.size())
	return band + tall + 4


## ⚠ ON REVERIFIE CHAQUE CLE LA OU ELLE EST POSEE, pas seulement la ou elle a ete trouvee.
## Un temoin est juste dans SON contexte -- au milieu d'un champ de plaine -- et le guide en
## est un autre, ou il a des voisins a quatre cases. La decoupe ment : deja mesure au dossier.
func _audit_brinks(heights: PackedStringArray) -> int:
	if _brinks.is_empty():
		return 0
	var made: Dictionary = Brink.keys(heights, 3)
	var lost: Array[String] = []
	for entry: Array in _brinks:
		var at: Vector2i = entry[0]
		var wanted: int = int(entry[1])
		var got: bool = false
		for storey: Dictionary in (made["storeys"] as Array[Dictionary]):
			if storey.has(at) and int(storey[at]) == wanted:
				got = true
		if not got:
			lost.append("%d en %d,%d" % [wanted, at.x, at.y])
	if not lost.is_empty():
		print("TEMOINS DE BORD PERDUS (%d) : %s" % [lost.size(), ", ".join(lost)])
	return lost.size()




## ⚠ ON REVERIFIE CHAQUE ILOT LA OU IL EST POSE, pas seulement la ou il a ete cherche. Un
## temoin est juste dans SON contexte ; le guide en est un autre.
func _audit() -> void:
	var heights: PackedStringArray = _mask()
	var walled: Dictionary = Walls.visible_roles(heights)
	for entry: Vector3i in _placed:
		var got: int = Coverage.visible_index_at(heights, entry.x, entry.y, walled)
		if got != entry.z:
			print("  ilot %d pose en %d,%d rend %d (%s au lieu de %s)" % [entry.z,
					entry.x, entry.y, got, BlobIndex.brink_name(got),
					BlobIndex.brink_name(entry.z)])


func _mask() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(HEIGHT):
		var line: String = ""
		for x: int in range(WIDTH):
			var level: int = (_levels[y] as Array)[x] as int
			if level < 0:
				line += "~"
			elif level == 0:
				line += "."
			else:
				line += str(level)
		out.append(line)
	return out


func _initialize() -> void:
	_compose()
	var band: int = 42
	for pass_number: int in range(4):
		var after: int = _reserve(band)
		if after == band:
			break
		band = after
	band = _brink_reserve(band)
	_audit()
	var heights: PackedStringArray = _mask()
	var failures: int = 0
	if band > HEIGHT:
		failures += 1
		print("LE CADRE EST TROP COURT : la reserve finit a %d, le guide fait %d"
				% [band, HEIGHT])
	# ⚠ ET TROP LONG EST UN DEFAUT AUSSI -- un garde-fou qui ne regarde que d'un cote ne garde
	# rien, deja paye sur la version du manifeste. Des rangees vides ne cassent aucun invariant
	# et ne se voient dans aucun test : elles se voient A L'ECRAN, ou elles retrecissent la
	# case. « Ce qui compte n'est pas le nombre de cases, c'est la taille de la case a
	# l'ecran » -- et c'est la mesure qui decide de la hauteur, pas une constante ecrite.
	elif band + FOOTER < HEIGHT:
		failures += 1
		print("LE CADRE EST TROP LONG : la reserve finit a %d, le guide fait %d -- %d rangee(s)"
				% [band, HEIGHT, HEIGHT - band - FOOTER])
	if _audit_brinks(heights) > 0:
		failures += 1

	# 1. L'epaisseur, partout, tous etages.
	var thin: Array[Vector3i] = Thickness.thin_cells(heights)
	if not thin.is_empty():
		failures += 1
		print("FIN : %d case(s) fine(s), par exemple %s" % [thin.size(),
				str(thin.slice(0, 6))])

	# 2. Les 27 surfaces, HORS de la plaine.
	var indices: Dictionary = Families.surface_map(Families.BY_CELL, heights)
	var seen_indices: Dictionary = {}
	for at: Vector2i in indices.keys():
		if HeightMask.level_at(heights, at.x, at.y) >= 1:
			seen_indices[int(indices[at])] = true
	var missing_indices: Array = []
	var extra_indices: Array = []
	for index: int in Thickness.SURFACE_INDICES:
		if not seen_indices.has(index):
			missing_indices.append(index)
	for index: int in seen_indices.keys():
		if not (index in Thickness.SURFACE_INDICES):
			extra_indices.append(index)
	if not missing_indices.is_empty():
		failures += 1
		print("SURFACES manquantes (%d) : %s" % [missing_indices.size(), str(missing_indices)])
	if not extra_indices.is_empty():
		failures += 1
		print("SURFACES HORS VOCABULAIRE (%d) : %s -- le relief n'est pas epais la ou elles vivent"
				% [extra_indices.size(), str(extra_indices)])

	# 3. Les 25 roles, hors plaine, et aucune robe hors grille.
	var seen_walls: Dictionary = Walls.visible(heights)
	var roles: Dictionary = seen_walls["roles"]
	var lips: Dictionary = seen_walls["lips"]
	var seen_roles: Dictionary = {}
	var outside: int = 0
	for cell: Vector2i in roles.keys():
		if cell.y >= HEIGHT or cell.y < 0 or cell.x < 0 or cell.x >= WIDTH:
			outside += 1
		if int(lips.get(cell, 0)) >= 1:
			seen_roles[roles[cell]] = true
	var missing_roles: Array = []
	var extra_roles: Array = []
	for role: Vector2i in Thickness.wall_roles():
		if not seen_roles.has(role):
			missing_roles.append(role)
	for role: Vector2i in seen_roles.keys():
		if not Thickness.role_survives(role):
			extra_roles.append(role)
	if not missing_roles.is_empty():
		failures += 1
		var told: PackedStringArray = PackedStringArray()
		for role: Vector2i in missing_roles:
			told.append("(%s,%s) %s" % [Walls.SIDE_NAMES[Walls.pan_west(role.x)],
					Walls.SIDE_NAMES[Walls.pan_east(role.x)], Walls.ROW_NAMES[role.y]])
		print("ROLES manquants (%d) : %s" % [missing_roles.size(), ", ".join(told)])
	if not extra_roles.is_empty():
		failures += 1
		var told_extra: PackedStringArray = PackedStringArray()
		for role: Vector2i in extra_roles:
			told_extra.append("(%s,%s) %s" % [Walls.SIDE_NAMES[Walls.pan_west(role.x)],
					Walls.SIDE_NAMES[Walls.pan_east(role.x)], Walls.ROW_NAMES[role.y]])
		print("ROLES HORS VOCABULAIRE (%d) : %s" % [extra_roles.size(), ", ".join(told_extra)])
	if outside > 0:
		failures += 1
		print("ROBES HORS GRILLE : %d" % outside)

	# 4. Les 15 croisements, hors plaine.
	var crossings: Dictionary = CornerIndex.index_map(heights)
	var seen_corners: Dictionary = {}
	for point: Vector2i in crossings.keys():
		var high: int = -1
		for offset: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
			high = maxi(high, HeightMask.level_at(heights, point.x + offset.x, point.y + offset.y))
		if high >= 1:
			seen_corners[int(crossings[point])] = true
	var missing_corners: Array = []
	for index: int in range(1, 16):
		if not seen_corners.has(index):
			missing_corners.append(index)
	if not missing_corners.is_empty():
		failures += 1
		print("CROISEMENTS manquants (%d) : %s" % [missing_corners.size(), str(missing_corners)])

	# L'ecriture, meme imparfaite : le guide est un travail d'iteration.
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	for line: String in heights:
		file.store_line(line)
	file.close()
	print("guide ecrit : %s (%dx%d)" % [OUT_PATH, WIDTH, HEIGHT])
	print("BATISSEUR EPAIS : %d probleme(s)." % failures)
	quit(0 if failures == 0 else 1)
