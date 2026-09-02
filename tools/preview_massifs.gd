extends SceneTree

## LE GUIDE PEINT SOUS LE NOUVEAU MODELE -- le seul rendu qui dise si on va au bon endroit.
##
##     godot --headless --path . --script res://tools/preview_massifs.gd -- <sortie.png> [zoom] [x y w h]
##
## Variables : `GUIDE=` le relief a peindre, `F=` la liberte (0 1 2), `GRILLE=1` la grille.
##
## ⚠ ET IL NE CALCULE RIEN LUI-MEME. Il appelle `render/massif_scene.gd`, celui que le banc
## mesure : une image qu'on regarde et une image qu'on mesure doivent sortir du meme code, sinon
## l'oeil approuve ce que la mesure n'a pas vu.

const HeightMask := preload("res://core/height_mask.gd")
const Modes := preload("res://core/modes.gd")
const Scene := preload("res://render/massif_scene.gd")
const MassifTiles := preload("res://render/massif_tiles.gd")
const Massifs := preload("res://core/massifs.gd")

const RES: int = Scene.RES
## ⚠ LE FOND NE DOIT PAS AVALER LE TRAIT. A `#171719` il etait a trois valeurs du noir du
## contour (`#0d0f12`) : les massifs qui bordent le VIDE semblaient n'avoir aucun contour, alors
## que la mesure en trouvait zero pixel sans trait. Un fond d'aperçu n'est pas de la matiere --
## il doit se distinguer de tout ce que le dessin porte.
const VOID: Color = Color(0.20, 0.23, 0.28)


## Les chiffres, en 3x5. ⚠ Ecrits ici plutot que dessines a la main dans l'image : un chiffre
## trace au cas par cas est une donnee a maintenir de plus.
const DIGITS: Array[String] = [
	"111101101101111", "010110010010111", "111001111100111", "111001111001111",
	"101101111001001", "111100111001111", "111100111101111", "111001001001001",
	"111101111101111", "111101111001111",
]
const PLATE: Color = Color(0.97, 0.97, 0.94)
const INK: Color = Color(0.10, 0.10, 0.12)
const LABEL: Color = Color(1.0, 0.86, 0.42)


func _badge(image: Image, cell: Vector2i, level: int) -> void:
	if level < 0 or level > 9:
		return
	var ox: int = cell.x * RES + (RES - 5) / 2
	var oy: int = cell.y * RES + (RES - 7) / 2
	for y: int in range(7):
		for x: int in range(5):
			if ox + x >= image.get_width() or oy + y >= image.get_height():
				continue
			image.set_pixel(ox + x, oy + y, PLATE)
	var glyph: String = DIGITS[level]
	for y2: int in range(5):
		for x2: int in range(3):
			if glyph.substr(y2 * 3 + x2, 1) != "1":
				continue
			if ox + 1 + x2 >= image.get_width() or oy + 1 + y2 >= image.get_height():
				continue
			image.set_pixel(ox + 1 + x2, oy + 1 + y2, INK)


## LE NUMERO D'UN ENSEMBLE : plus gros que la pastille d'etage, pour qu'on ne confonde pas les
## deux -- l'un designe un MONDE, l'autre dit une hauteur.
func _label(image: Image, cell: Vector2i, number: int) -> void:
	var digits: PackedStringArray = PackedStringArray()
	var rest: int = number
	while rest > 0:
		digits.insert(0, str(rest % 10))
		rest /= 10
	if digits.is_empty():
		digits.append("0")
	var scale: int = 2
	var wide: int = digits.size() * 4 * scale + 2
	var tall: int = 5 * scale + 2
	var ox: int = cell.x * RES + 1
	var oy: int = cell.y * RES + 1
	for y: int in range(tall):
		for x: int in range(wide):
			if ox + x >= image.get_width() or oy + y >= image.get_height():
				continue
			image.set_pixel(ox + x, oy + y, LABEL)
	for at: int in range(digits.size()):
		var glyph: String = DIGITS[digits[at].to_int()]
		for y2: int in range(5):
			for x2: int in range(3):
				if glyph.substr(y2 * 3 + x2, 1) != "1":
					continue
				for dy: int in range(scale):
					for dx: int in range(scale):
						var px: int = ox + 1 + (at * 4 + x2) * scale + dx
						var py: int = oy + 1 + y2 * scale + dy
						if px >= image.get_width() or py >= image.get_height():
							continue
						image.set_pixel(px, py, INK)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	var zoom: int = args[1].to_int() if args.size() > 1 else 1
	var guide: String = OS.get_environment("GUIDE")
	if guide.is_empty():
		guide = Modes.guide_path(Modes.EPAIS)
	var freedom: int = 1
	if not OS.get_environment("F").is_empty():
		freedom = OS.get_environment("F").to_int()
	# ⚠ L'ENCRE : `ENCRE=contour` rend le CONTOUR PROUVE -- toute la matiere d'une seule teinte,
	# et seules restent les lignes que le modele prouve. C'est la seule vue ou l'on juge le TRACE
	# que l'artiste aura a poser : en aplats, la couche du dessus cache les traits du dessous.
	var ink: int = MassifTiles.CONTOUR if OS.get_environment("ENCRE") == "contour" 			else MassifTiles.PEINT
	var world: PackedStringArray = HeightMask.read(guide)
	var wide: int = HeightMask.width(world)
	var tall: int = HeightMask.height(world)
	# ⚠ LE FOND N'EST PEINT QUE POUR L'OEIL. Le composeur laisse le vide transparent -- c'est ce
	# qui rend la mesure possible -- mais un PNG a fond transparent se regarde mal.
	var image: Image = Image.create_empty(wide * RES, tall * RES, false, Image.FORMAT_RGBA8)
	image.fill(VOID)
	image.blend_rect(Scene.compose(world, freedom, ink),
			Rect2i(0, 0, wide * RES, tall * RES), Vector2i.ZERO)

	# ⚠ LA GRILLE SE REPERE, ELLE NE SE LIT PAS. Pleine et opaque, elle masquait le trait meme
	# qu'on vient regarder. En pointille clair, elle dit ou sont les bordures de tuile sans
	# jamais couvrir ce qui s'y passe -- c'est la meme lecon que la barre translucide de
	# l'editeur : une aide a viser, pas un decor.
	# ⚠ L'OMBRE PORTEE EST UNE AIDE A LA LECTURE, ET ELLE VIT HORS DES TUILES.
	#
	# Sans elle, un plateau a exactement le meme vert que la plaine -- c'est la verite du
	# tileset, une seule herbe -- donc il est invisible, et sa falaise semble flotter toute
	# seule. Mesure : zero chapiteau sans surface au-dessus, le defaut n'etait pas dans le
	# modele mais dans la lecture.
	#
	# ⚠ ET ELLE NE PEUT PAS VIVRE DANS UNE TUILE : elle tombe sur les cases VOISINES, qui
	# appartiennent a d'autres tuiles. La teinter par etage serait pire -- ce serait la MEME
	# tuile montree en deux tons, donc un mensonge sur ce que l'artiste peint. L'ombre, elle,
	# ne pretend rien : elle dit « ceci est plus haut que cela », et `OMBRE=` l'eteint.
	if OS.get_environment("OMBRE") == "":
		var levels: Dictionary = {}
		for one: Dictionary in Massifs.poses(world):
			var cell: Vector2i = one["cell"]
			levels[cell] = maxi(int(levels.get(cell, -1)), int(one["level"]))
		for cell2: Vector2i in levels.keys():
			var mine: int = int(levels[cell2])
			for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var near: Vector2i = cell2 + step
				# ⚠ ET ELLE NE SE POSE QUE SUR DE LA MATIERE. Une ombre portee sur le VIDE
				# dessinait un liseré hors du monde -- il n'y a rien la pour la recevoir.
				if not levels.has(near) or int(levels[near]) >= mine:
					continue
				for at: int in range(RES):
					for deep: int in range(2):
						var px: int = near.x * RES + (deep if step == Vector2i.RIGHT else at)
						var py: int = near.y * RES + (at if step == Vector2i.RIGHT else deep)
						if px >= wide * RES or py >= tall * RES:
							continue
						image.set_pixel(px, py, image.get_pixel(px, py).darkened(0.22))

	# ⚠ LA PASTILLE D'ETAGE : une fois par massif, sur sa surface visible.
	#
	# Elle repond a ce que l'ombre portee ne dit qu'a moitie : l'ombre dit « ceci est plus haut
	# que cela », la pastille dit DE COMBIEN. Et elle se pose une seule fois par massif -- une
	# par case ferait un tapis de chiffres et cacherait le dessin qu'on vient juger.
	#
	# ⚠ ET ELLE VIT DANS L'APERCU, JAMAIS DANS UNE TUILE. Un etage n'est pas une propriete de la
	# tuile -- c'est la MEME tuile a tous les etages. La peindre dedans serait le mensonge que la
	# teinte par etage etait deja.
	if OS.get_environment("PASTILLE") == "":
		var best: Dictionary = {}
		for one2: Dictionary in Massifs.poses(world):
			if int(one2["band"]) != Massifs.SURFACE:
				continue
			var mark: int = int(one2["massif"])
			var cell3: Vector2i = one2["cell"]
			# La plus au sud, puis la plus a l'est : loin des bords du nord, donc lisible.
			if best.has(mark):
				var had: Vector2i = best[mark]
				if cell3.y < had.y or (cell3.y == had.y and cell3.x < had.x):
					continue
			best[mark] = cell3
		for mark2: int in best.keys():
			var at2: Vector2i = best[mark2]
			var level2: int = HeightMask.level_at(world, at2.x, at2.y)
			_badge(image, at2, level2)

	# ⚠ CE SONT LES MASSIFS QU'ON NUMEROTE, PAS LES MONDES. Un monde est un cadre ; ce qu'on
	# regarde et ce qu'on veut designer, c'est un massif -- « le 7 est faux » doit pointer une
	# masse de terrain, pas un rectangle de la mosaique.
	#
	# ⚠ ET LE NUMERO SE POSE SUR CE QUI SE VOIT. Un massif entierement recouvert par un plus haut
	# n'a aucune surface visible : son numero irait sous une autre matiere, donc nulle part. On
	# le pose alors sur n'importe laquelle de ses cases visibles.
	#
	# ⚠ ET L'ORDRE EST CELUI DE LA LECTURE -- de haut en bas, de gauche a droite. Numerotes dans
	# l'ordre ou le modele les trouve, ils sauteraient d'un bout a l'autre du guide.
	if OS.get_environment("NUMEROS") == "":
		var top: Dictionary = {}
		for one3: Dictionary in Massifs.poses(world):
			var cell4: Vector2i = one3["cell"]
			if top.has(cell4) and int((top[cell4] as Dictionary)["level"]) > int(one3["level"]):
				continue
			top[cell4] = one3
		var anchor: Dictionary = {}
		for cell5: Vector2i in top.keys():
			var one4: Dictionary = top[cell5]
			var mark: int = int(one4["massif"])
			var surface: bool = int(one4["band"]) == Massifs.SURFACE
			if anchor.has(mark):
				var had: Dictionary = anchor[mark]
				if bool(had["surface"]) and not surface:
					continue
				var was: Vector2i = had["cell"]
				if bool(had["surface"]) == surface 						and (cell5.y > was.y or (cell5.y == was.y and cell5.x > was.x)):
					continue
			anchor[mark] = {"cell": cell5, "surface": surface}
		var order: Array[int] = []
		order.assign(anchor.keys())
		order.sort_custom(func(a: int, b: int) -> bool:
			var pa: Vector2i = (anchor[a] as Dictionary)["cell"]
			var pb: Vector2i = (anchor[b] as Dictionary)["cell"]
			return pa.y < pb.y if pa.y != pb.y else pa.x < pb.x)
		for at4: int in range(order.size()):
			_label(image, (anchor[order[at4]] as Dictionary)["cell"], at4 + 1)

	if OS.get_environment("GRILLE") != "":
		var grid: Color = Color(1.0, 0.35, 0.35, 0.30)
		for gy: int in range(tall + 1):
			var py: int = mini(gy * RES, tall * RES - 1)
			for gx: int in range(0, wide * RES, 3):
				image.set_pixel(gx, py, grid)
		for gx2: int in range(wide + 1):
			var px: int = mini(gx2 * RES, wide * RES - 1)
			for gy2: int in range(0, tall * RES, 3):
				image.set_pixel(px, gy2, grid)
	if args.size() >= 6:
		var crop: Image = Image.create_empty(args[4].to_int() * RES, args[5].to_int() * RES,
				false, image.get_format())
		crop.blit_rect(image, Rect2i(args[2].to_int() * RES, args[3].to_int() * RES,
				args[4].to_int() * RES, args[5].to_int() * RES), Vector2i.ZERO)
		image = crop
	if zoom > 1:
		image.resize(image.get_width() * zoom, image.get_height() * zoom,
				Image.INTERPOLATE_NEAREST)
	image.save_png(out)
	print("guide %dx%d a F%d (%s), ecrit : %s (%dx%d)"
			% [wide, tall, freedom, "contour" if ink == MassifTiles.CONTOUR else "peint",
			out, image.get_width(), image.get_height()])
	quit(0)
