extends RefCounted

## LE TRAVAIL ET L'EXPORT DU MODÈLE PAR LES COINS.
##   Le travail (`.mqcoins`, JSON, v2) : la résolution, l'image de chaque (archétype, matière, variante) peinte (PNG en
##   base64, clé « n:y » avec y = m * 10 + k), les POIDS des variantes (« n:m » → un entier par variante, la base
##   comprise) et l'AFFECTATION du guide (quelle apparition montre quelle variante, pour la juger parmi ses vraies
##   voisines, comme le témoin de MarchingBlocks). Une image par (archétype, matière, variante) — jamais par apparition.
##   ⚠ Un travail v1 (une image par archétype, clé « n ») se relit : ses images deviennent les bases.
##   Le RELIEF du mode test (hauteurs et matières des coins) part avec le travail.
##   ⚠ L'extension est `.mqcoins` ; les « .solutiles » de l'ancien modèle des massifs ne s'ouvrent pas ici.
##   L'EXPORT : la PLANCHE (un PNG, les images en grille) et son MANIFESTE (JSON, v2) — la taille d'une tuile, la TABLE
##   (chaque clé de pose « sorte:c:cv » → son archétype) et les IMAGES (archétype, matière, variante, poids, place dans la
##   planche). C'est tout ce qu'un moteur doit savoir : les poses se calculent depuis les hauteurs et les matières des
##   coins (`addons/marching_squares/modele.gd`), l'archétype de chaque pose se lit dans la table, la variante se tire.

const Archetypes := preload("res://core/coins/archetypes.gd")
const Modele := preload("res://addons/marching_squares/modele.gd")
const Painting := preload("res://core/painting.gd")

const FORMAT := "marching-squares-coins"
const VERSION := 2
const COLONNES_PLANCHE := 8
const EXTENSION := "mqcoins"


## Combien d'archétypes de base (matière 0) sont peints, par sorte : {dessus, falaises, total}.
static func compte(peinture: Painting) -> Dictionary:
	var dessus := 0
	var falaises := 0
	for a: Dictionary in Archetypes.liste():
		if peinture.is_painted(Vector2i(a.numero, 0)):
			if a.sorte == Modele.DESSUS:
				dessus += 1
			else:
				falaises += 1
	var t_dessus := 0
	for a: Dictionary in Archetypes.liste():
		if a.sorte == Modele.DESSUS:
			t_dessus += 1
	return {"dessus": dessus, "falaises": falaises, "total_dessus": t_dessus,
			"total_falaises": Archetypes.liste().size() - t_dessus}


## Combien de variantes (la base comprise) a l'archétype n dans la matière m.
static func nb_variantes(meta: Dictionary, n: int, m: int) -> int:
	return maxi(1, (meta.get("poids", {}) as Dictionary).get("%d:%d" % [n, m], [1]).size())


## Les poids des variantes de (n, m), la base comprise (1 par défaut).
static func poids(meta: Dictionary, n: int, m: int) -> PackedInt32Array:
	var p := PackedInt32Array()
	for w: Variant in (meta.get("poids", {}) as Dictionary).get("%d:%d" % [n, m], [1]):
		p.append(int(w))
	return p


static func sauver(peinture: Painting, meta: Dictionary, chemin: String) -> Error:
	var images := {}
	for cle: Vector2i in peinture.painted_cells():
		images["%d:%d" % [cle.x, cle.y]] = Marshalls.raw_to_base64(peinture.image_of(cle).save_png_to_buffer())
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify({"format": FORMAT, "version": VERSION, "resolution": peinture.resolution,
			"archetypes": Archetypes.liste().size(), "cles": Archetypes.liste().map(func(a: Dictionary) -> String: return a.cles[0]),
			"images": images, "poids": meta.get("poids", {}),
			"affectation": meta.get("affectation", {}), "relief": _relief_en_json(meta.get("relief", {}))}, " "))
	return OK


## Rend {peinture, meta}, ou {} si le fichier n'est pas un travail de MarchingSquares.
static func relire(chemin: String) -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(chemin))
	if not (d is Dictionary) or d.get("format") != FORMAT:
		return {}
	var p := Painting.new(int(d.get("resolution", 16)))
	# ⚠ UN NUMÉRO D'ARCHÉTYPE N'EST PAS UNE IDENTITÉ : le vocabulaire a changé (35 → 33 sans les selles, 4 novembre
	# 2026). Le fichier dit la CLÉ de chaque numéro ; on la retrouve dans le vocabulaire d'aujourd'hui. Un archétype qui
	# n'existe plus (une selle) est laissé de côté — c'est dit dans `oublies`.
	var renum := {}
	var anciennes: Array = d.get("cles", [])
	for n in anciennes.size():
		renum[n] = Archetypes.numero(int(String(anciennes[n]).split(":")[0]), int(String(anciennes[n]).split(":")[1]),
				int(String(anciennes[n]).split(":")[2]))
	var oublies := 0
	for k: String in d.get("images", {}):
		var t := k.split(":")
		var n0 := int(t[0])
		if renum.has(n0):
			if int(renum[n0]) < 0:
				oublies += 1
				continue
			n0 = renum[n0]
		var cle := Vector2i(n0, int(t[1]) if t.size() > 1 else 0)
		var img := Image.new()
		if img.load_png_from_buffer(Marshalls.base64_to_raw(d.images[k])) == OK:
			img.convert(Image.FORMAT_RGBA8)
			p.set_image(cle, img)
	var meta := {"poids": {}, "affectation": {}, "oublies": oublies}
	for k: String in d.get("poids", {}):
		var t2 := k.split(":")
		var n1: int = int(renum.get(int(t2[0]), int(t2[0])))
		if n1 >= 0:
			meta.poids["%d:%s" % [n1, t2[1]]] = (d.poids[k] as Array).map(func(w: Variant) -> int: return int(w))
	for k: String in d.get("affectation", {}):
		var a: Array = (d.affectation[k] as Array).map(func(w: Variant) -> int: return int(w))
		a[0] = int(renum.get(a[0], a[0]))
		if a[0] >= 0:
			meta.affectation[k] = a
	var rl: Variant = d.get("relief", {})
	if rl is Dictionary and (rl as Dictionary).has("h"):
		meta.relief = {"colonnes": int(rl.colonnes), "rangees": int(rl.rangees),
				"h": PackedInt32Array((rl.h as Array).map(func(v: Variant) -> int: return int(v))),
				"mat": PackedInt32Array((rl.get("mat", []) as Array).map(func(v: Variant) -> int: return int(v)))}
	return {"peinture": p, "meta": meta}


## Le relief du mode test, gardé avec le travail : on retrouve le monde qu'on sculptait.
static func _relief_en_json(rl: Dictionary) -> Dictionary:
	if not rl.has("h"):
		return {}
	return {"colonnes": rl.colonnes, "rangees": rl.rangees, "h": Array(rl.h), "mat": Array(rl.get("mat", PackedInt32Array()))}


## Les images à livrer : les 35 bases de la surface (peintes ou non : une non peinte est DITE), leurs variantes, et pour
## chaque matière qui a au moins une image peinte, ses quinze dessus et leurs variantes.
static func images_a_livrer(peinture: Painting, meta: Dictionary) -> Array:
	var matieres := {0: true}
	for cle: Vector2i in peinture.painted_cells():
		matieres[cle.y / 10] = true
	var sortie := []
	var liste := Archetypes.liste()
	for m: int in matieres.keys():
		for a: Dictionary in liste:
			if m > 0 and a.sorte != Modele.DESSUS:
				continue
			var p := poids(meta, a.numero, m)
			for k in p.size():
				sortie.append({"archetype": a.numero, "matiere": m, "variante": k, "poids": p[k],
						"peinte": peinture.is_painted(Vector2i(a.numero, m * 10 + k))})
	return sortie


## La planche et le manifeste, dans le dossier `dossier`. Rend [chemin de la planche, chemin du manifeste, images non
## peintes].
static func exporter(peinture: Painting, meta: Dictionary, dossier: String) -> Array:
	DirAccess.make_dir_recursive_absolute(dossier)
	var res := peinture.resolution
	var images := images_a_livrer(peinture, meta)
	var rangees := int(ceil(float(images.size()) / COLONNES_PLANCHE))
	var planche := Image.create(COLONNES_PLANCHE * res, maxi(rangees, 1) * res, false, Image.FORMAT_RGBA8)
	planche.fill(Color(0, 0, 0, 0))
	var manquantes := 0
	for i in images.size():
		var e: Dictionary = images[i]
		e.colonne = i % COLONNES_PLANCHE
		e.rangee = i / COLONNES_PLANCHE
		var cle := Vector2i(e.archetype, e.matiere * 10 + e.variante)
		var source := cle if peinture.is_painted(cle) else Vector2i(e.archetype, e.matiere * 10)
		if peinture.is_painted(source):
			planche.blit_rect(peinture.image_of(source), Rect2i(0, 0, res, res), Vector2i(e.colonne, e.rangee) * res)
		else:
			manquantes += 1
	var archetypes := []
	var table := {}
	for a: Dictionary in Archetypes.liste():
		archetypes.append({"numero": a.numero, "sorte": ["", "dessus", "haut", "bas"][a.sorte], "cles": a.cles})
		for k: String in a.cles:
			table[k] = a.numero
	var png := dossier.path_join("marching_squares_planche.png")
	var json := dossier.path_join("marching_squares_planche.json")
	planche.save_png(png)
	var f := FileAccess.open(json, FileAccess.WRITE)
	f.store_string(JSON.stringify({"format": FORMAT + "-planche", "version": VERSION, "tuile": res,
			"planche": png.get_file(), "table": table, "archetypes": archetypes, "images": images,
			"modele": "hauteurs et matières sur les coins ; une couche par unité, décalée d'une case vers le haut ; poses, tirage : addons/marching_squares/modele.gd"}, " "))
	return [png, json, manquantes]
