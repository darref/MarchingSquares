extends SceneTree

## LES ILOTS DE LA PLANCHE DE PREUVE, DECOUPES DANS LE GUIDE.
##
##     godot --headless --path . --script res://tools/make_surface_demos.gd
##
## ⚠ ET ON LES PREND DANS LE GUIDE PLUTOT QUE DE LES CALCULER, ce qui renverse une decision du
## dossier -- il faut donc dire pourquoi. Tant qu'une tuile etait une SILHOUETTE, l'ilot se
## deduisait d'elle : la fenetre realisable, etiree, et le centre portait l'index par
## construction. Depuis que la tuile est le couple (silhouette, bord), son ilot doit aussi
## METTRE EN SCENE ce que le bord raconte -- une face voisine, un pied au-dessus, deux chutes
## decalees qui atterrissent sur la meme rangee. Ca ne se deduit plus : `tools/make_islands.gd`
## le cherche, et il ne trouve que 42 des 69.
##
## Le guide, lui, les porte TOUTES et PEIGNABLES, par construction et verifie. On y decoupe
## donc, comme `tools/make_wall_demos.gd` le fait deja pour les specimens de falaise, et pour
## la meme raison : « le guide est pose SUR LA PLAINE, exactement comme la planche ».
##
## ⚠ LA FENETRE EST DE TAILLE FIXE, ET C'EST CE QUI GARDE LA PLANCHE LISIBLE. Des decoupages
## de tailles differentes demanderaient un rangement, donc une table de positions, donc un
## second endroit ou mentir. A taille fixe, le centre EST le centre, et la planche garde la
## grille reguliere qu'un acheteur peut pointer du doigt.
##
## ⚠ ET CHAQUE DECOUPAGE EST REVERIFIE DANS LE CONTEXTE OU IL SERA POSE -- entoure de plaine,
## puis de vide. La decoupe ment : c'est mesure au dossier, onze tuiles sur cinquante et une
## avaient disparu au decoupage.

const HeightMask := preload("res://core/height_mask.gd")
const Brink := preload("res://core/brink.gd")
const Thickness := preload("res://core/thickness.gd")
const Modes := preload("res://core/modes.gd")
const SurfaceForm := preload("res://core/surface_form.gd")
const Walls := preload("res://core/walls.gd")

## Le demi-cote de l'ilot STOCKE : tous font cette taille, donc le centre est toujours au
## centre et la planche garde sa grille reguliere.
const HALF: int = 13

## ⚠ ET LE DEMI-COTE DE LA DECOUPE, LUI, SE CHERCHE. Large, la fenetre emporte les accidents
## VOISINS du guide, qui changent la cle du centre : mesure, 46 ilots sur 69 a treize contre
## 61 a dix. Etroite, elle perd ce qui CAUSE le bit -- une levre quatre rangees au nord. Aucune
## taille unique ne convient a toutes les tuiles.
##
## On coupe donc petit et on COMPLETE EN PLAINE jusqu'a la taille stockee : l'ilot garde son
## format fixe, et la recherche gagne un degre de liberte qu'elle n'avait pas.
const CUTS: Array[int] = [10, 9, 11, 8, 12, 7, 13, 6]
## La plaine ajoutee autour pour juger : de quoi atterrir.
const FIELD: int = 9
## Puis le vide, qui fait le bord du monde.
const RING: int = 3
const OUT_PATH: String = "res://core/surface_demos.gd"


func _initialize() -> void:
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var made: Dictionary = Brink.keys(guide, 3)
	var indices: Dictionary = made["indices"]
	var roles: Dictionary = made["roles"]
	# LES CANDIDATS : les cases PEIGNABLES qui portent chaque cle. L'etage 0 est du decor et
	# une case de robe porte la robe -- un ilot decoupe autour de l'une d'elles montrerait une
	# tuile que personne ne peut peindre.
	var spots: Dictionary = {}
	for at: Vector2i in indices.keys():
		if HeightMask.level_at(guide, at.x, at.y) < 1 or roles.has(at):
			continue
		var key: int = int(indices[at])
		if not spots.has(key):
			spots[key] = []
		if (spots[key] as Array).size() < 80:
			(spots[key] as Array).append(at)

	var kept: Array[PackedStringArray] = []
	var kept_keys: Array[int] = []
	var lost: Array[int] = []
	for key2: int in SurfaceForm.KEYS:
		var done: bool = false
		for at2: Variant in (spots.get(key2, []) as Array):
			for cut: int in CUTS:
				var crop: PackedStringArray = _crop(guide, (at2 as Vector2i).x,
						(at2 as Vector2i).y, cut)
				if not _carries(crop, key2):
					continue
				kept.append(crop)
				kept_keys.append(key2)
				done = true
				break
			if done:
				break
		if not done:
			lost.append(key2)
	print("ilots decoupes : %d sur %d" % [kept.size(), SurfaceForm.KEYS.size()])
	if not lost.is_empty():
		print("  SANS ILOT (%d) : %s" % [lost.size(), str(lost)])

	var out: String = ""
	out += "## LES ILOTS DE LA PLANCHE DE PREUVE, un par tuile de surface.\n"
	out += "##\n"
	out += "## Decoupes DANS LE GUIDE par `tools/make_surface_demos.gd`, a taille fixe, et\n"
	out += "## reverifies au milieu d'un champ de plaine -- le contexte ou la planche les pose.\n"
	out += "## Le centre de la fenetre porte la cle annoncee. Ne pas editer a la main : la suite\n"
	out += "## reverifie chaque ilot a la case ou il est pose.\n"
	out += "##\n"
	out += "## EN TABLEAUX SIMPLES, PAS EN PackedStringArray : GDScript ne fait pas une constante\n"
	out += "## d'un paquet type de ce genre -- le membre cesse de se resoudre, et tout ce qui\n"
	out += "## prechargeait le fichier tombe avec lui, sans erreur claire.\n"
	out += "extends RefCounted\n\n\n"
	out += "## Le demi-cote de la fenetre : le centre est en (HALF, HALF).\n"
	out += "const HALF: int = %d\n\n" % HALF
	out += "## Les cles, dans l'ordre des ilots.\n"
	out += "const KEYS: Array[int] = %s\n\n" % str(kept_keys)
	out += "const ISLANDS: Array = [\n"
	for at3: int in range(kept.size()):
		out += "\t[\n"
		for line: String in kept[at3]:
			out += "\t\t\"%s\",\n" % line
		out += "\t],\n"
	out += "]\n"
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("ecriture impossible : %s" % OUT_PATH)
		quit(1)
		return
	file.store_string(out)
	file.close()
	print("  ecrit : %s" % OUT_PATH)
	quit(0)


## Un carre du guide autour de la case, complete en PLAINE jusqu'a la taille stockee.
##
## ⚠ ET LE VIDE DU GUIDE DEVIENT DE LA PLAINE, comme pour les temoins : la planche EST un champ
## de plaine, et un ilot qui porterait son propre gouffre y creuserait un trou que rien n'a
## demande -- sa robe tomberait de douze rangees dans la case du voisin.
func _crop(guide: PackedStringArray, cx: int, cy: int, half: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(cy - HALF, cy + HALF + 1):
		var line: String = ""
		for x: int in range(cx - HALF, cx + HALF + 1):
			if absi(x - cx) > half or absi(y - cy) > half:
				line += "0"
				continue
			var level: int = HeightMask.level_at(guide, x, y)
			line += "0" if level < 0 else str(level)
		out.append(line)
	return out


## LE JUGE, DANS LE CONTEXTE DE LA PLANCHE : le decoupage entoure de plaine, puis de vide.
## Il doit etre epais, ne pas jeter de robe hors du cadre, et son CENTRE doit porter la cle.
func _carries(crop: PackedStringArray, key: int) -> bool:
	var pad: int = FIELD + RING
	var width: int = crop[0].length() + 2 * pad
	var height: int = crop.size() + 2 * pad
	var relief: PackedStringArray = PackedStringArray()
	for y: int in range(height):
		var line: String = ""
		for x: int in range(width):
			if y < RING or y >= height - RING or x < RING or x >= width - RING:
				line += "~"
			elif y < pad or y >= height - pad or x < pad or x >= width - pad:
				line += "0"
			else:
				line += crop[y - pad].substr(x - pad, 1)
		relief.append(line)
	if not Thickness.thin_cells(relief).is_empty():
		return false
	var report: Dictionary = Walls.analyse(relief, Thickness.wall_roles())
	if not (report["outside"] as Array).is_empty():
		return false
	var made: Dictionary = Brink.keys(relief, 3)
	var centre: Vector2i = Vector2i(pad + HALF, pad + HALF)
	var indices: Dictionary = made["indices"]
	if (made["roles"] as Dictionary).has(centre):
		return false
	if HeightMask.level_at(relief, centre.x, centre.y) < 1:
		return false
	return indices.has(centre) and int(indices[centre]) == key
