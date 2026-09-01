extends SceneTree

## LES SPECIMENS DU NOUVEAU MODELE : a quoi chaque tuile ressemblera.
##
##     godot --headless --path . --script res://tools/specimens.gd -- <sortie.png> [libre|ras]
##
## ⚠ ET LE TRAIT SE POSE A MI-TUILE PARTOUT OU LA LIBERTE EXISTE -- decision utilisateur, et
## c'est une decision de PEDAGOGIE, pas de dessin : « autant montrer la liberte des qu'elle
## existe, ce sera l'indication pour l'artiste de ce qu'il peut faire ». Un bord dessine au ras
## dit a l'artiste « ce bord ne t'appartient pas » ; dessine a mi-tuile, il dit « place-le ou tu
## veux ».
##
## ⚠ ET UN MASSIF RECOUVRANT N'EST PAS FIGE POUR AUTANT. « Au ras » veut dire que son arete
## touche la bordure de tuile AU RENDEZ-VOUS -- pour que n'importe quelle voisine puisse la
## rejoindre -- mais entre deux rendez-vous elle ONDULE comme les autres. La difference entre
## les deux planches est donc la position du rendez-vous, pas la presence de liberte.

const BlobIndex := preload("res://core/blob_index.gd")
const Bands := preload("res://tools/bands.gd")

const RES: int = 16
const ZOOM: int = 5
const GAP: int = 2
const COLUMNS: int = 10

## ⚠ L'AMPLITUDE EST A ZERO POUR COMMENCER -- decision utilisateur : « fais des traits droits
## pour commencer, les ondulations viendront gratuitement ensuite ». Elle est gratuite en effet :
## le rendez-vous d'un bord est ce qui se negocie entre deux tuiles ; ce que le trait fait ENTRE
## deux rendez-vous n'engage personne. On juge donc d'abord la GEOMETRIE, sans que l'ondulation
## brouille la lecture.
const SWELL: float = 0.0

const VOID: Color = Color(0.14, 0.15, 0.16)
const LINE: Color = Color(0.09, 0.09, 0.10)
const BODY: Array[Color] = [
	Color(0.44, 0.60, 0.32),   # SURFACE
	Color(0.74, 0.57, 0.42),   # CHAPITEAU
	Color(0.64, 0.48, 0.35),   # CORPS
	Color(0.54, 0.40, 0.29),   # PIED
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	var flush: bool = args.size() > 1 and args[1] == "ras"
	var couples: Array[int] = _couples()
	var rows: int = (couples.size() + COLUMNS - 1) / COLUMNS
	var step: int = RES + GAP
	var sheet: Image = Image.create_empty(COLUMNS * step * ZOOM, rows * step * ZOOM,
			false, Image.FORMAT_RGBA8)
	sheet.fill(VOID)
	for at: int in range(couples.size()):
		var one: Image = tile(couples[at] & 0xff, couples[at] >> 8, flush, VOID)
		var big: Image = one.duplicate()
		big.resize(RES * ZOOM, RES * ZOOM, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(big, Rect2i(0, 0, RES * ZOOM, RES * ZOOM),
				Vector2i((at % COLUMNS) * step * ZOOM, (at / COLUMNS) * step * ZOOM))
	sheet.save_png(out)
	var said: PackedStringArray = PackedStringArray()
	for key: int in couples:
		said.append("%s/%d" % [Bands.BAND_NAMES[key >> 8], key & 0xff])
	print("%d specimens, %s" % [couples.size(), "au ras" if flush else "libres"])
	print("  ordre de lecture : %s" % " ".join(said))
	quit(0)


## Les couples que l'enumeration a rendus, ranges par bande.
func _couples() -> Array[int]:
	var out: Array[int] = []
	var found: Dictionary = {
		Bands.SURFACE: [28, 31, 112, 124, 127, 223, 241, 247, 253, 255],
		Bands.CHAPITEAU: [31, 127, 223, 241, 247, 253, 255],
		Bands.CORPS: [31, 127, 223, 241, 247, 253, 255],
		Bands.PIED: [7, 193, 199],
	}
	for band: int in [Bands.SURFACE, Bands.CHAPITEAU, Bands.CORPS, Bands.PIED]:
		for sil: Variant in (found[band] as Array):
			out.append((band << 8) | int(sil))
	return out


## LA PROFONDEUR D'UN BORD OUVERT, le long de ce bord.
##
## ⚠ LIBRE : le rendez-vous est a MI-TUILE, et l'arete bombe autour. RECOUVRANT : le rendez-vous
## est AU RAS -- zero -- et l'arete bombe quand meme. C'est la seule difference entre les deux.
## L'EPAISSEUR DU TRAIT DE LEVRE, le long du bord haut du chapiteau.
static func _lip(along: int, flush: bool) -> int:
	return 1


static func depth_of(along: int, flush: bool) -> int:
	var meet: float = 0.0 if flush else float(RES) / 2.0
	var t: float = float(along) / float(RES - 1)
	return int(round(meet + SWELL * sin(PI * t)))


## UN SPECIMEN : la matiere de sa bande, rognee sur ses cotes OUVERTS, et cernee d'un trait.
## ⚠ ET LE DEHORS EST TRANSPARENT PAR DEFAUT, PAS PEINT. C'est lui qui fait l'occlusion : le
## massif du dessous se voit A TRAVERS ce que celui du dessus ne remplit pas. Un fond opaque
## cerne chaque tuile d'un halo et supprime tout le modele. La planche de SPECIMENS, elle, en
## demande un -- isolee, une tuile a dehors transparent se lit comme un trou.
## ⚠ ET LA TEINTE SUIT L'ETAGE, sans quoi un massif RECOUVRANT est invisible sur son socle :
## meme vert, meme matiere, on ne voit que son contour -- d'ou les « arches » que l'utilisateur
## a vues. L'ancien rendu teintait chaque etage, et il avait raison : la teinte est ce qui dit
## l'altitude quand la vue est de dessus.
static func tile(sil: int, band: int, flush: bool, backdrop: Color = Color(0, 0, 0, 0),
		level: int = 1) -> Image:
	var out: Image = Image.create_empty(RES, RES, false, Image.FORMAT_RGBA8)
	out.fill(backdrop)
	var solid: Array[PackedByteArray] = []
	for y: int in range(RES):
		var line: PackedByteArray = PackedByteArray()
		line.resize(RES)
		for x: int in range(RES):
			var inside: bool = true
			if (sil & BlobIndex.N) == 0 and y < depth_of(x, flush):
				inside = false
			if (sil & BlobIndex.S) == 0 and y > RES - 1 - depth_of(x, flush):
				inside = false
			if (sil & BlobIndex.W) == 0 and x < depth_of(y, flush):
				inside = false
			if (sil & BlobIndex.E) == 0 and x > RES - 1 - depth_of(y, flush):
				inside = false
			# LE COIN RENTRANT : les deux cardinaux pleins, la diagonale vide. C'est une
			# encoche, et elle se creuse a la meme profondeur que les bords.
			for corner: int in range(4):
				var a: int = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W][corner]
				var b: int = [BlobIndex.W, BlobIndex.N, BlobIndex.E, BlobIndex.S][corner]
				var d: int = [BlobIndex.NW, BlobIndex.NE, BlobIndex.SE, BlobIndex.SW][corner]
				if (sil & a) == 0 or (sil & b) == 0 or (sil & d) != 0:
					continue
				var near_y: bool = y < depth_of(x, flush) if corner < 2 \
						else y > RES - 1 - depth_of(x, flush)
				var near_x: bool = x > RES - 1 - depth_of(y, flush) \
						if corner == 1 or corner == 2 else x < depth_of(y, flush)
				if near_x and near_y:
					inside = false
			line[x] = 1 if inside else 0
		solid.append(line)
	for y2: int in range(RES):
		for x2: int in range(RES):
			if solid[y2][x2] == 0:
				continue
			var edge: bool = false
			for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var near: Vector2i = Vector2i(x2, y2) + step
				# ⚠ UNE TUILE AU RAS TRACE QUAND MEME SON BORD, et c'est le defaut qui rendait
				# un massif RECOUVRANT invisible sur son socle : son contour tombe exactement
				# sur la bordure de tuile, et un cerne qui ne regarde qu'a l'INTERIEUR ne le
				# voit jamais. Au ras veut dire « mon arete est sur la bordure », pas « je n'ai
				# pas d'arete ».
				if near.x < 0 or near.y < 0 or near.x >= RES or near.y >= RES:
					var side: int = 0 if step == Vector2i.UP else (
							1 if step == Vector2i.RIGHT else (
							2 if step == Vector2i.DOWN else 3))
					var card: int = [BlobIndex.N, BlobIndex.E, BlobIndex.S,
							BlobIndex.W][side]
					if (sil & card) == 0:
						edge = true
					continue
				if solid[near.y][near.x] == 0:
					edge = true
			# ⚠ LE TRAIT DE LEVRE VIT DANS LA TUILE, et il est CONSTANT : un CHAPITEAU a
			# toujours de la surface au-dessus de lui -- c'est sa definition, il pend sous le
			# bord sud de la surface. La frontiere herbe/roche tombe donc a sa rangee du haut,
			# toujours, et aucune tuile n'a besoin de savoir quoi que ce soit de sa voisine.
			#
			# ⚠ ET C'EST AUSSI LE TRAIT DES FALAISES INTERNES. Une encoche ouverte au sud
			# dans un massif porte sa propre falaise : c'est le meme chapiteau, donc le meme
			# trait, sans un cas de plus.
			if band == 1 and y2 < _lip(x2, flush):
				out.set_pixel(x2, y2, LINE)
				continue
			out.set_pixel(x2, y2, LINE if edge else BODY[band].lightened(0.13 * float(level - 1)))
	return out
