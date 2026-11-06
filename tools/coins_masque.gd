extends SceneTree

## ÉCRIT LE TILESET MASQUE (planche + manifeste) dans un dossier : chaque pixel peint de ce qu'il est — où l'on marche,
## ce qui bloque (`core/coins/masque.gd`). Pour un jeu qui propose ces tuiles à ses joueurs (Pix, les donjons).
##   Godot_v4.7-stable_win64_console.exe --headless --path D:/MarchingSquares --script res://tools/coins_masque.gd -- <dossier> [16|32|64]

const Masque := preload("res://core/coins/masque.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage : -- <dossier> [résolution]")
		quit(2)
		return
	var res := int(args[1]) if args.size() > 1 else 32
	var sortie := Masque.ecrire(args[0], res)
	print("masque écrit : %s, %s (non peintes : %d)" % [sortie[0], sortie[1], sortie[2]])
	quit(0 if int(sortie[2]) == 0 else 1)
