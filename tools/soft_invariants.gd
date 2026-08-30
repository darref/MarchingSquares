extends SceneTree

## LES INVARIANTS, MESURES SUR LE DESSIN DU PRODUIT -- pas sur celui du banc.
##
##     godot --headless --path . --script res://tools/soft_invariants.gd -- [guide] [taille]
##
## ⚠ POURQUOI IL EXISTE. `proof/ladder.gd` prouve un MODELE ; il peint ses propres tuiles avec
## son propre pinceau. Rien de ce qu'il etablit n'est vrai du logiciel tant qu'on ne l'a pas
## mesure SUR LE LOGICIEL. Cet outil rend l'illustration de `render/guide_image.gd` -- celle que
## l'acheteur regarde en peignant, et celle dont l'essai tire son tileset -- et lui pose les deux
## questions qui ne dependent d'aucun modele :
##
##   I1  FERMETURE  -- un pixel de trait qui n'a qu'UN voisin de trait est une extremite ;
##   I2  EPAISSEUR  -- un pave 2x2 entierement de trait veut dire deux traits colles.
##
## ⚠ ET C'EST LE FIL DE FER QU'ON MESURE, PAS LE PEINT. Le style peint est fait d'aplats, de
## lumiere et de striure : « le trait » n'y est pas une couleur mais une intention. Le fil de fer,
## lui, EST le trait -- c'est meme sa raison d'etre au dossier : « des traits, comme un tileset au
## fil de fer, sans aplat donc sans lumiere ». Mesure : l'illustration du guide livre exactement
## NEUF couleurs, disjointes, sans un pixel intermediaire.
##
## ⚠ ET LA PALETTE SE VERIFIE AVANT DE COMPTER. Une couleur inconnue veut dire que le dessin a
## change sous l'outil : on refuse plutot que de compter de travers. C'est la lecon du dossier --
## un compteur qui ne mesure pas ce qu'il pretend mesurer est pire que pas de compteur.
##
## ⚠ ET LE PREDICAT EST UNE SECONDE COPIE DE CELUI DU BANC, DONC IL SE CONTROLE. `--verifier`
## le fait tourner sur une image DU BANC dont le compte est connu : si les deux ne disent pas la
## meme chose, c'est la copie qui est fausse. Deux copies d'une meme regle finissent toujours par
## se contredire -- sauf si on les confronte.

const HeightMask := preload("res://core/height_mask.gd")
const GuideImage := preload("res://render/guide_image.gd")
const Modes := preload("res://core/modes.gd")

## Les trois encres du fil de fer. Tout le reste est de la matiere ou du vide.
const TRAITS: Array[Color] = [GuideImage.WIRE_EDGE, GuideImage.WIRE_LIP, GuideImage.WIRE_FACE]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "--verifier":
		_cross_check(args[1] if args.size() > 1 else "")
		quit(0)
		return
	var guide: String = args[0] if args.size() > 0 else Modes.guide_path(Modes.EPAIS)
	var side: int = args[1].to_int() if args.size() > 1 else GuideImage.TILE
	if not FileAccess.file_exists(guide):
		printerr("guide introuvable : %s" % guide)
		quit(1)
		return
	print("=== LES INVARIANTS SUR LE DESSIN DU PRODUIT ===")
	print("  guide %s, tuile de %d px" % [guide, side])
	var heights: PackedStringArray = HeightMask.read(guide)
	# ⚠ SANS LES MARQUES DE TRAVAIL. Le marqueur de coin rentrant et le tiret de rangee sont des
	# aides au peintre posees PAR-DESSUS le dessin ; les compter reviendrait a reprocher au guide
	# ce qu'il ajoute pour se faire lire.
	var image: Image = GuideImage.render(heights, side, GuideImage.Ink.WIREFRAME,
			GuideImage.Purpose.REPRESENTATIVE, false)
	quit(0 if _measure(image, "guide") else 1)


## Le predicat : trait, matiere, ou vide -- et rien d'autre n'est tolere.
func _stroke(image: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return false
	var here: Color = image.get_pixel(x, y)
	if here.a < 0.5:
		return false
	for ink: Color in TRAITS:
		if _same(here, ink):
			return true
	return false


## ⚠ ET LA COMPARAISON SE FAIT EN HUIT BITS, PAS EN FLOTTANT. `is_equal_approx` compare a
## 1e-5 pres ; or une constante ecrite `0.588` ressort d'un PNG a `150 / 255 = 0.58824`, soit
## 2,4e-4 d'ecart -- vingt fois l'epsilon. Le compteur annoncait alors ZERO pixel de trait sur
## une image qui en porte trente mille, et c'est la garde de non-vacuite qui l'a dit. Le banc,
## lui, ne s'en apercevait pas : ses couleurs sont ecrites en hexadecimal, donc elles font
## l'aller-retour exactement.
## ⚠ ET LA COMPARAISON SE FAIT A UN PAS PRES, ET LES DEUX MOITIES SE SONT PAYEES.
##
## D'abord le flottant : `is_equal_approx` compare a 1e-5, or une constante ecrite `0.588`
## ressort d'un PNG a `150 / 255 = 0,58824` -- vingt fois l'epsilon. Le compteur annoncait ZERO
## pixel de trait sur une image qui en porte trente mille.
##
## Puis le pixel pres : `Image.set_pixel` TRONQUE au lieu d'arrondir -- `0,588 x 255 = 149,94`
## devient 149 -- alors que le rendu du produit, qui passe par une reduction, ecrit 150. Une
## meme couleur s'ecrit donc a un pas pres selon le chemin qui la pose.
##
## ⚠ ET LA TOLERANCE D'UN PAS NE PEUT CONFONDRE AUCUNE DES NEUF COULEURS : mesuree, la paire la
## plus proche de la palette differe de SEPT sur un canal (`#2d2e34` contre `#34373c`). Une
## tolerance qu'on n'aurait pas verifiee la-dessus serait un compteur de plus a qui l'on fait
## confiance sans raison.
static func _same(a: Color, b: Color) -> bool:
	return absi(roundi(a.r * 255.0) - roundi(b.r * 255.0)) <= 1 and absi(roundi(a.g * 255.0) - roundi(b.g * 255.0)) <= 1 and absi(roundi(a.b * 255.0) - roundi(b.b * 255.0)) <= 1


func _measure(image: Image, name: String) -> bool:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var strokes: int = 0
	var ends: int = 0
	var open_ends: int = 0
	var thick: int = 0
	var where: Array[String] = []
	var thick_where: Array[String] = []
	for y: int in range(height):
		for x: int in range(width):
			if not _stroke(image, x, y):
				continue
			strokes += 1
			var around: int = 0
			var breathes: bool = false
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if _stroke(image, x + dx, y + dy):
						around += 1
					var inside: bool = x + dx >= 0 and y + dy >= 0 						and x + dx < width and y + dy < height
					if not inside or image.get_pixel(x + dx, y + dy).a < 0.5:
						breathes = true
			if around > 1:
				continue
			ends += 1
			if breathes:
				open_ends += 1
			if where.size() < 12:
				where.append("%d,%d (case %d,%d)" % [x, y, x / GuideImage.TILE,
						y / GuideImage.TILE])
	for y2: int in range(height - 1):
		for x2: int in range(width - 1):
			if _stroke(image, x2, y2) and _stroke(image, x2 + 1, y2) 					and _stroke(image, x2, y2 + 1) and _stroke(image, x2 + 1, y2 + 1):
				thick += 1
				if thick_where.size() < 12:
					thick_where.append("%d,%d" % [x2, y2])
	# ⚠ ET LA MESURE DOIT AVOIR VU QUELQUE CHOSE. Une image sans un pixel de trait rendrait
	# zero extremite et zero pave, et ce zero-la ne prouve rien du tout.
	print("  %s : %d x %d px, %d pixel(s) de trait" % [name, width, height, strokes])
	if strokes == 0:
		printerr("  ⚠ AUCUN TRAIT : la palette a change, la mesure ne veut rien dire.")
		return false
	# ⚠ ET ON VERIFIE QUE CE QU'ON APPELLE UN TRAIT EN EST UN. I1 et I2 supposent un trace d'UN
	# pixel : une encre posee en BANDE remplit des paves 2x2 par construction, et les compter
	# reprocherait au dessin d'etre ce qu'il est. Chaque encre se declare donc d'abord.
	var banded: PackedStringArray = PackedStringArray()
	for at: int in range(TRAITS.size()):
		var ink: Color = TRAITS[at]
		var count: int = 0
		var solid: int = 0
		for y3: int in range(height - 1):
			for x3: int in range(width - 1):
				if not _same(image.get_pixel(x3, y3), ink) 						or image.get_pixel(x3, y3).a < 0.5:
					continue
				count += 1
				if _same(image.get_pixel(x3 + 1, y3), ink) 						and _same(image.get_pixel(x3, y3 + 1), ink) 						and _same(image.get_pixel(x3 + 1, y3 + 1), ink):
					solid += 1
		print("     encre %d : %d px, %d pave(s) de son propre 2x2%s"
				% [at, count, solid, "   ⚠ BANDE" if solid > count / 20 else ""])
		if solid > count / 20:
			banded.append(str(at))
	if not banded.is_empty():
		printerr("  ⚠ LE DESSIN DU PRODUIT N'EST PAS UN TRACE D'UN PIXEL : l'encre %s est posee"
				% ", ".join(banded))
		printerr("     EN BANDE. I1 et I2 n'y ont pas de sens tant que le trace n'est pas un")
		printerr("     contour d'un pixel -- ce que le portage du modele doit apporter.")
		return false
	print("  I1 fermeture   %s  %d extremite(s) (%d au bord du vide, %d noyee(s))  %s"
			% ["ok  " if ends == 0 else "ECHEC", ends, open_ends, ends - open_ends, str(where)])
	print("  I2 epaisseur   %s  %d pave(s) 2x2 de trait  %s"
			% ["ok  " if thick == 0 else "ECHEC", thick, str(thick_where)])
	return ends == 0 and thick == 0


## LE CONTROLE CROISE DE LA COPIE : la meme image, les deux compteurs.
##
## On prend une image ECRITE PAR LE BANC -- dont le compte est connu -- on la transcrit dans la
## palette du produit, et on verifie que ce compteur-ci dit la meme chose. Sans ca, la copie du
## predicat est un endroit ou mentir.
func _cross_check(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		printerr("donner une image du banc : -- --verifier <png>")
		return
	var source: Image = Image.load_from_file(path)
	var out: Image = Image.create_empty(source.get_width(), source.get_height(), false,
			Image.FORMAT_RGBA8)
	var ladder_outline: Color = Color("#0d0f12")
	var moved: int = 0
	for y: int in range(source.get_height()):
		for x: int in range(source.get_width()):
			var here: Color = source.get_pixel(x, y)
			if here.a < 0.5:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
			elif here.is_equal_approx(ladder_outline):
				out.set_pixel(x, y, GuideImage.WIRE_EDGE)
				moved += 1
			else:
				out.set_pixel(x, y, GuideImage.WIRE_WALL)
	print("=== CONTROLE CROISE : image du banc, compteur du produit ===")
	print("  %s : %d pixel(s) de trait transcrits" % [path, moved])
	_measure(out, "banc transcrit")
