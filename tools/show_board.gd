extends SceneTree

## LA PLANCHE DE PREUVE, RENDUE : un ilot par tuile, tous les massifs, isoles.
##
## ⚠ L'ILLUSTRATION EST LE TAMPONNAGE DES TUILES, pas un dessin a cote. Elle fabrique les
## silhouettes et les robes une fois, puis les pose sur le relief -- c'est exactement ce que
## le jeu fera. Si le contour se referme ici, il se referme partout.

const GuideImage := preload("res://render/guide_image.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")
const HeightMask := preload("res://core/height_mask.gd")

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "res://planche.png"
	var tile: int = int(args[1]) if args.size() > 1 else 24
	var relief: PackedStringArray = ProofScene.relief(Families.BY_CELL)
	print("planche : %d x %d cases" % [HeightMask.width(relief), HeightMask.height(relief)])
	var image: Image = GuideImage.render(relief, tile)
	image.save_png(out)
	print("ecrit : %s  (%d x %d px)" % [out, image.get_width(), image.get_height()])
	quit()
