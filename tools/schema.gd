extends SceneTree

## LE SCHEMA — dessiner une question avant de la modeliser.
##
##     godot --headless --path . --script res://tools/schema.gd -- <sortie.png> <nom>
##
## ⚠ ET C'EST UN OUTIL, PAS UNE ILLUSTRATION. On ne modelise plus sans avoir dessine le cas :
## une phrase sur un decrochement de bord sud se lit de trois facons, un dessin d'une seule.
## Chaque schema porte sa legende, avec les NOMS du modele -- pas des couleurs a deviner.
##
## LE VOCABULAIRE, une fois pour toutes :
##
##   MASSIF      l'objet complet : sa surface ET sa falaise. Autonome : il existe entierement,
##               y compris sous ce qui le recouvre.
##   SURFACE     la face superieure du massif, vue de dessus.
##   FALAISE     la jupe de TROIS rangees qui pend sous le bord sud de la SURFACE.
##   EMPREINTE   surface + falaise : toutes les cases que le massif occupe vu de dessus.
##               C'est sur l'EMPREINTE que se lit la silhouette d'une tuile, jamais sur la
##               seule surface.
##   BANDE       a quelle hauteur du massif une case appartient :
##               SURFACE, CHAPITEAU (falaise rangee 1), CORPS (rangee 2), PIED (rangee 3).
##   RECOUVRANT  un massif qui en recouvre un autre. Son contour est AU RAS partout.
##   RECOUVERT   celui du dessous. Il garde ses aretes LIBRES.
##   PLAINE      l'etage 0, le sol. Ce n'est PAS un massif : elle ne recouvre rien.
##   VIDE        hors du monde.
##   AU RAS      l'arete est plaquee sur la bordure de tuile, sans vagabondage.
##   LIBRE       l'arete vagabonde a l'interieur de la tuile.
##   DECROCHEMENT  un pas du bord sud de la surface, d'une colonne a la suivante.

const CELL: int = 48
const PAD: int = 8

## Le code d'une case -> sa couleur et son nom.
const PALETTE: Dictionary = {
	".": [Color(0.76, 0.80, 0.60), "PLAINE"],
	"~": [Color(0.11, 0.12, 0.13), "VIDE"],
	"S": [Color(0.44, 0.60, 0.32), "SURFACE"],
	"C": [Color(0.72, 0.55, 0.40), "CHAPITEAU"],
	"O": [Color(0.62, 0.46, 0.33), "CORPS"],
	"P": [Color(0.52, 0.38, 0.27), "PIED"],
	"s": [Color(0.30, 0.44, 0.22), "SURFACE (recouverte)"],
	"c": [Color(0.50, 0.38, 0.28), "FALAISE (recouverte)"],
	"?": [Color(0.85, 0.30, 0.30), "LA QUESTION"],
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	var name: String = args[1] if args.size() > 1 else "anatomie"
	var rows: PackedStringArray = _scene(name)
	if rows.is_empty():
		printerr("schema inconnu : %s" % name)
		quit(1)
		return
	var wide: int = 0
	for line: String in rows:
		wide = maxi(wide, line.length())
	var image: Image = Image.create_empty(wide * CELL + 2 * PAD, rows.size() * CELL + 2 * PAD,
			false, Image.FORMAT_RGBA8)
	image.fill(Color(0.14, 0.15, 0.16))
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			var code: String = rows[y].substr(x, 1)
			if not PALETTE.has(code):
				continue
			var colour: Color = (PALETTE[code] as Array)[0]
			for py: int in range(CELL):
				for px: int in range(CELL):
					# La bordure de tuile, en clair : c'est la GRILLE, et tout le modele
					# se dit par rapport a elle.
					var edge: bool = px == 0 or py == 0 or px == CELL - 1 or py == CELL - 1
					image.set_pixel(PAD + x * CELL + px, PAD + y * CELL + py,
							colour.lightened(0.35) if edge else colour)
	image.save_png(out)
	var seen: Dictionary = {}
	for line2: String in rows:
		for at: int in range(line2.length()):
			seen[line2.substr(at, 1)] = true
	var legend: PackedStringArray = PackedStringArray()
	for code2: String in PALETTE.keys():
		if seen.has(code2):
			legend.append("%s = %s" % [code2, (PALETTE[code2] as Array)[1]])
	print("%s : %d x %d cases" % [name, wide, rows.size()])
	print("  %s" % "   ".join(legend))
	quit(0)


func _scene(name: String) -> PackedStringArray:
	match name:
		# L'ANATOMIE : un massif seul sur la plaine. Surface, puis sa falaise de trois
		# rangees sous son bord sud. L'EMPREINTE est tout ce qui n'est pas plaine.
		"anatomie":
			return PackedStringArray([
				"..........",
				"..SSSSSS..",
				"..SSSSSS..",
				"..SSSSSS..",
				"..CCCCCC..",
				"..OOOOOO..",
				"..PPPPPP..",
				"..........",
			])
		# LE DECROCHEMENT : le bord sud de la surface fait un pas. La falaise le suit.
		# La case marquee a, a son OUEST, la falaise DU MEME MASSIF.
		"decrochement":
			return PackedStringArray([
				"..........",
				"..SSSSSS..",
				"..SSSSSS..",
				"..SSS?SS..",
				"..CCCSSS..",
				"..OOOCCC..",
				"..PPPOOO..",
				"..!..PPP..",
				"..........",
			])
		# LE VRAI BORD : meme tuile, meme silhouette de SURFACE -- mais a l'ouest il n'y a
		# rien. C'est la paire qui obligeait a un bit tant qu'on lisait la seule surface.
		"vrai-bord":
			return PackedStringArray([
				"..........",
				".....SSS..",
				".....SSS..",
				"....?SSS..",
				".....CCC..",
				".....OOO..",
				".....PPP..",
				"..........",
			])
		# LE RECOUVREMENT : un massif RECOUVRANT pose sur un RECOUVERT. Le recouvert existe
		# ENTIEREMENT dessous -- ce qu'on ne voit pas de lui est de l'occlusion, pas un trou.
		"recouvrement":
			return PackedStringArray([
				"............",
				"..ssssssss..",
				"..ssSSSSss..",
				"..ssSSSSss..",
				"..ssCCCCss..",
				"..ssOOOOss..",
				"..ssPPPPss..",
				"..ssssssss..",
				"..cccccccc..",
				"..oooooooo..",
				"..pppppppp..",
				"............",
			])
	return PackedStringArray()
