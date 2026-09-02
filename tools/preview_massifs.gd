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
