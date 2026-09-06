# L'ICONE DU PRODUIT, TIREE DE CELLE DU PLUGIN.
#
# ⚠ UNE SEULE SOURCE POUR LES TROIS PRODUITS. `addons/solupaint/icon.svg` est deja l'icone du
# noeud et du bouton dans l'editeur de l'acheteur ; c'est elle qui doit se retrouver sur l'exe,
# sur la fenetre, et demain sur le plugin Unity. Deux dessins finiraient par diverger, et
# l'acheteur verrait deux produits la ou il y en a un.
#
# ⚠ ET ON RASTERISE, ON NE REDESSINE PAS. Le SVG est trace pour 16 px ; le relire a l'echelle
# donne un carre net a n'importe quelle taille, alors qu'un PNG agrandi baverait -- et c'est
# precisement ce que le produit refuse de faire aux tuiles.
extends SceneTree

const SOURCE: String = "res://addons/solupaint/icon.svg"
const OUT_DIR: String = "res://build/icon"

## Les tailles que Windows demande dans un `.ico`. 256 est celle du bureau et de la grande
## vignette ; 16 celle de la barre des taches.
const SIZES: PackedInt32Array = ([16, 32, 48, 64, 128, 256] as PackedInt32Array)


func _initialize() -> void:
	var file: FileAccess = FileAccess.open(SOURCE, FileAccess.READ)
	if file == null:
		print("ECHEC : %s illisible" % SOURCE)
		quit(1)
		return
	var svg: String = file.get_as_text()
	file.close()

	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR)) != OK \
			and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUT_DIR)):
		print("ECHEC : impossible de creer %s" % OUT_DIR)
		quit(1)
		return

	var bad: int = 0
	for size: int in SIZES:
		var image: Image = Image.new()
		# ⚠ L'ECHELLE, PAS UN REDIMENSIONNEMENT. `load_svg_from_string` retrace le vecteur a la
		# taille voulue ; passer par `resize()` reintroduirait exactement le flou qu'on evite.
		var err: Error = image.load_svg_from_string(svg, float(size) / 16.0)
		if err != OK or image.get_width() != size:
			print("ECHEC  %d px : erreur %d, largeur %d" % [size, err, image.get_width()])
			bad += 1
			continue
		var path: String = "%s/icon_%d.png" % [OUT_DIR, size]
		if image.save_png(path) != OK:
			print("ECHEC  %d px : ecriture impossible" % size)
			bad += 1
			continue
		print("ok     %3d x %3d  ->  %s" % [size, size, path.get_file()])

	# ⚠ ET CELLE-CI EST A PART : c'est le `config/icon` du projet, donc l'icone de la FENETRE.
	# Godot la veut a la racine et en PNG ; elle sert aussi de repli a l'exporteur.
	var big: Image = Image.new()
	if big.load_svg_from_string(svg, 16.0) == OK:
		if big.save_png("res://icon.png") == OK:
			print("ok     256 x 256  ->  res://icon.png  (icone de la fenetre)")
		else:
			bad += 1

	print("")
	print("%d echec(s)" % bad)
	quit(1 if bad > 0 else 0)
