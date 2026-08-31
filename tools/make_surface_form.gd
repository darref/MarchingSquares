extends SceneTree

## LA FORME FERMEE DES SURFACES, RANGEE POUR LE PRODUIT.
##
##     python tools/closed_form_now.py --liste > forme.txt
##     godot --headless --path . --script res://tools/make_surface_form.gd -- forme.txt
##
## ⚠ ET C'EST UNE DONNEE GENEREE, PAS UNE REGLE RECOPIEE. L'enumeration vit dans
## `closed_form_now.py`, une fois : elle sait quelles preconditions tiennent, et les trois
## theoremes qui ferment les bits. La reecrire en GDScript serait une SECONDE expression de la
## meme regle -- la faute que le dossier repete a chaque page.
##
## ⚠ ET LA DONNEE SE CONTROLE, elle ne se croit pas. La suite verifie que toute cle posee par
## les mondes livres tombe dedans, et l'outil verifie ici que rien n'y est absurde. Meme
## traitement que `core/brink_witnesses.gd`, pour la meme raison.

const Brink := preload("res://core/brink.gd")
const BlobIndex := preload("res://core/blob_index.gd")
const Thickness := preload("res://core/thickness.gd")

const OUT_PATH: String = "res://core/surface_form.gd"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("donner la forme : -- <forme.txt>")
		quit(1)
		return
	var text: String = FileAccess.get_file_as_string(args[0])
	if text.strip_edges().is_empty():
		printerr("liste vide ou introuvable : %s" % args[0])
		quit(1)
		return
	var keys: Array[int] = []
	for piece: String in text.strip_edges().split(",", false):
		keys.append(int(piece.strip_edges()))
	keys.sort()

	# ⚠ LE CONTROLE DE FORME, ICI ET PAS AILLEURS : chaque cle doit porter une silhouette du
	# vocabulaire epais, RABOTEE de ses diagonales sud. Une cle hors de la, c'est la
	# transcription qui est fausse, pas le monde -- et on veut le savoir avant d'ecrire.
	var allowed: Dictionary = Brink.silhouettes(3)
	var strayed: Array[int] = []
	for key: int in keys:
		if not allowed.has(key & 0xff):
			strayed.append(key)
	if not strayed.is_empty():
		printerr("%d cle(s) hors des silhouettes : %s" % [strayed.size(), str(strayed.slice(0, 8))])
		quit(1)
		return

	var lines: PackedStringArray = PackedStringArray()
	lines.append("## LA FORME FERMEE DES SURFACES -- ce que le modele PEUT exiger, cle par cle.")
	lines.append("##")
	lines.append("## ⚠ GENERE PAR `tools/make_surface_form.gd` DEPUIS `tools/closed_form_now.py`.")
	lines.append("## Ne pas editer a la main : l'enumeration vit dans l'outil, avec les")
	lines.append("## preconditions de chaque bit et les trois theoremes qui les ferment.")
	lines.append("##")
	lines.append("## ⚠ ET C'EST UNE BORNE HAUTE, PAS UN RELEVE. Elargir la famille de mondes fait")
	lines.append("## monter le compte RENCONTRE et ne touche jamais celui-ci. Les deux se")
	lines.append("## rejoignent quand le vocabulaire est serre -- c'est le critere 3 du plan.")
	lines.append("##")
	lines.append("## ⚠ UNE CLE EST UN COUPLE : la silhouette dans les huit bits bas, les bits de")
	lines.append("## bord au-dessus. `BlobIndex.silhouette()` et `BlobIndex.brink()` les separent.")
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("")
	lines.append("## Les %d cles, en ordre croissant." % keys.size())
	var said: PackedStringArray = PackedStringArray()
	for key2: int in keys:
		said.append(str(key2))
	var body: String = ", ".join(said)
	lines.append("const KEYS: Array[int] = [")
	var row: String = "\t"
	for at: int in range(said.size()):
		var piece2: String = said[at] + ("," if at < said.size() - 1 else "")
		if row.length() + piece2.length() + 1 > 96:
			lines.append(row)
			row = "\t"
		row += piece2 + " "
	if row.strip_edges() != "":
		lines.append(row.rstrip(" "))
	lines.append("]")
	lines.append("")
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("ecriture impossible : %s" % OUT_PATH)
		quit(1)
		return
	file.store_string("\n".join(lines))
	file.close()
	var silhouettes: Dictionary = {}
	for key3: int in keys:
		silhouettes[key3 & 0xff] = true
	print("  %d cles sur %d silhouettes  (%d caracteres)"
			% [keys.size(), silhouettes.size(), body.length()])
	print("  ecrit : %s" % OUT_PATH)
	quit(0)
