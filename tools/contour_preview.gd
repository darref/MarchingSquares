extends SceneTree

## LE CONTOUR PROUVE, DESSINE PAR LE PRODUIT -- pas par le banc.
##
##     godot --headless --path . --script res://tools/contour_preview.gd -- [guide] [sortie] [F]
##
## ⚠ C'EST LE PREMIER ECRAN QUE LE PORTAGE REND POSSIBLE. Le modele est dans `core/brink.gd`, le
## pinceau dans `render/contour_tiles.gd`, l'assemblage dans `render/contour.gd` : plus une seule
## ligne de `proof/` n'est necessaire pour obtenir l'image que l'echelle prouve fermee.
##
## ⚠ ET LA LIBERTE PAR DEFAUT EST F1 -- LE TRAIT DROIT. C'est celle qu'on regarde en premier :
## le trait rentre, mais il ne serpente pas, donc ce qu'on voit est la GEOMETRIE du modele et
## non le style d'une main.
##
## Le fond est transparent : `tools/soft_invariants.gd -- --verifier <png>` le mesure tel quel.

const HeightMask := preload("res://core/height_mask.gd")
const Contour := preload("res://render/contour.gd")
const Modes := preload("res://core/modes.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var guide: String = args[0] if args.size() > 0 else Modes.guide_path(Modes.EPAIS)
	var out: String = args[1] if args.size() > 1 else "res://guides/epais_contour.png"
	var freedom: int = args[2].to_int() if args.size() > 2 else 1
	if not FileAccess.file_exists(guide):
		printerr("guide introuvable : %s" % guide)
		quit(1)
		return
	var heights: PackedStringArray = HeightMask.read(guide)
	var start: int = Time.get_ticks_msec()
	# ⚠ L3 : LE NIVEAU DU MONDE COMPLET -- etages empiles, falaises, poses arriere. C'est celui
	# que le logiciel livre ; L5, la famille a cheval, reste au banc.
	var made: Dictionary = Contour.compose(heights, 3, freedom)
	var image: Image = made["image"]
	print("=== LE CONTOUR PROUVE, PAR LE PRODUIT ===")
	print("  guide %s  ->  %d x %d px, F%d, %d ms"
			% [guide, image.get_width(), image.get_height(), freedom,
			Time.get_ticks_msec() - start])
	print("  %d cases visibles, %d tuiles de surface, %d cases de falaise"
			% [(made["indices"] as Dictionary).size(), (made["tiles"] as Dictionary).size(),
			(made["roles"] as Dictionary).size()])
	var error: Error = image.save_png(ProjectSettings.globalize_path(out))
	if error != OK:
		printerr("ecriture impossible : %d" % error)
		quit(1)
		return
	print("  ecrit : %s" % out)
	quit(0)
