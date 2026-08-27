extends SceneTree

## LA PLANCHE ET LE GUIDE SONT-ILS EPAIS ? Question de l'utilisateur, et elle porte : le pinceau
## de SoluPaint pose des tampons 3x3 et efface par 3x3 au moins. Un specimen qui contiendrait un
## coude d'UNE tuile d'epaisseur ne serait donc pas produisible par le pinceau -- et n'aurait
## rien a faire ni dans la planche, ni dans le guide, ni dans le vocabulaire.
##
## ⚠ ET LA REPONSE SE LIT SILHOUETTE PAR SILHOUETTE, pas sur le relief. Une case peut etre
## epaisse a son etage et fine a l'etage d'en dessous : c'est la silhouette de CHAQUE etage qui
## doit tenir, plaine comprise, dans les deux etats. C'est la definition meme de min trois.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const ProofScene := preload("res://core/proof_scene.gd")
const Families := preload("res://core/families.gd")
const Modes := preload("res://core/modes.gd")


func _initialize() -> void:
	var bad: int = 0
	bad += _probe(ProofScene.relief(Families.BY_CELL), "la planche de preuve, par case")
	bad += _probe(ProofScene.relief(Families.BY_CORNER), "la planche de preuve, a cheval")
	bad += _probe(HeightMask.read(Modes.guide_path(Modes.EPAIS)), "le guide epais")
	print("")
	print("VERDICT : %s" % ("tout est epais -- le pinceau peut tout produire."
			if bad == 0 else "%d case(s) fine(s) : le pinceau ne peut pas les faire." % bad))
	quit(1 if bad > 0 else 0)


func _probe(relief: PackedStringArray, label: String) -> int:
	var thin: Array[Vector3i] = Thickness.thin_cells(relief)
	print("  %-34s %d x %d   cases fines : %d"
			% [label, HeightMask.width(relief), HeightMask.height(relief), thin.size()])
	for i: int in range(mini(thin.size(), 8)):
		var at: Vector3i = thin[i]
		print("      case %d,%d a l'etage %d" % [at.x, at.y, at.z])
	return thin.size()
