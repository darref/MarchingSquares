extends RefCounted

## LE TRAVAIL ET L'EXPORT DU MODÈLE PAR LES COINS.
##   Le travail (`.mqcoins`, JSON) : la résolution et l'image de chaque archétype peint (PNG en base64). Une image par
##   archétype — jamais par apparition : c'est le carnet qui le garantit.
##   L'EXPORT : la PLANCHE (les 35 archétypes en grille, un PNG) et son MANIFESTE (JSON) — la taille d'une tuile, la place
##   de chaque archétype dans la planche, et la TABLE : chaque clé de pose (« sorte:c:cv ») → son archétype. C'est tout ce
##   qu'un moteur (le greffon) doit savoir pour reconstruire n'importe quel relief : les poses se calculent depuis les
##   hauteurs des coins (`modele.gd`), l'archétype de chaque pose se lit dans la table.

const Archetypes := preload("res://core/coins/archetypes.gd")
const Painting := preload("res://core/painting.gd")

const FORMAT := "marching-squares-coins"
const VERSION := 1
const COLONNES_PLANCHE := 7


static func sauver(peinture: Painting, chemin: String) -> Error:
	var images := {}
	for n in Archetypes.liste().size():
		if peinture.is_painted(Vector2i(n, 0)):
			images[str(n)] = Marshalls.raw_to_base64(peinture.image_of(Vector2i(n, 0)).save_png_to_buffer())
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify({"format": FORMAT, "version": VERSION, "resolution": peinture.resolution,
			"archetypes": Archetypes.liste().size(), "images": images}, " "))
	return OK


static func relire(chemin: String) -> Painting:
	var texte := FileAccess.get_file_as_string(chemin)
	var d: Variant = JSON.parse_string(texte)
	if not (d is Dictionary) or d.get("format") != FORMAT:
		return null
	var p := Painting.new(int(d.get("resolution", 16)))
	for k: String in d.get("images", {}):
		var img := Image.new()
		if img.load_png_from_buffer(Marshalls.base64_to_raw(d.images[k])) == OK:
			img.convert(Image.FORMAT_RGBA8)
			p.set_image(Vector2i(int(k), 0), img)
	return p


## La planche et le manifeste, dans le dossier `dossier`. Rend [chemin de la planche, chemin du manifeste].
static func exporter(peinture: Painting, dossier: String) -> Array:
	DirAccess.make_dir_recursive_absolute(dossier)
	var liste := Archetypes.liste()
	var res := peinture.resolution
	var rangees := int(ceil(float(liste.size()) / COLONNES_PLANCHE))
	var planche := Image.create(COLONNES_PLANCHE * res, rangees * res, false, Image.FORMAT_RGBA8)
	planche.fill(Color(0, 0, 0, 0))
	var archetypes := []
	var table := {}
	for a: Dictionary in liste:
		var n: int = a.numero
		var place := Vector2i(n % COLONNES_PLANCHE, n / COLONNES_PLANCHE)
		if peinture.is_painted(Vector2i(n, 0)):
			planche.blit_rect(peinture.image_of(Vector2i(n, 0)), Rect2i(0, 0, res, res), place * res)
		archetypes.append({"numero": n, "sorte": ["", "dessus", "haut", "bas"][a.sorte], "colonne": place.x,
				"rangee": place.y, "cles": a.cles})
		for k: String in a.cles:
			table[k] = n
	var png := dossier.path_join("marching_squares_planche.png")
	var json := dossier.path_join("marching_squares_planche.json")
	planche.save_png(png)
	var f := FileAccess.open(json, FileAccess.WRITE)
	f.store_string(JSON.stringify({"format": FORMAT + "-planche", "version": VERSION, "tuile": res,
			"colonnes": COLONNES_PLANCHE, "archetypes": archetypes, "table": table,
			"modele": "hauteurs sur les coins ; une couche par unité, décalée d'une case vers le haut ; poses : modele.gd"}, " "))
	return [png, json]
