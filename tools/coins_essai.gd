extends SceneTree

## ÉCRIT LE TILESET D'ESSAI (planche + manifeste) dans un dossier — ce que l'éditeur fait par « Export the trial », pour
## la version publiée (le zip « trial tileset » de la release) sans ouvrir l'éditeur.
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://tools/coins_essai.gd -- <dossier> [16|32|64]

const Essai := preload("res://core/coins/essai.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage : -- <dossier> [résolution]")
		quit(2)
		return
	var res := int(args[1]) if args.size() > 1 else 16
	var sortie := Essai.ecrire(args[0], res)
	print("essai écrit : %s, %s (non peintes : %d)" % [sortie[0], sortie[1], sortie[2]])
	quit(0 if int(sortie[2]) == 0 else 1)
