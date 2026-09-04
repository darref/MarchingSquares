extends SceneTree

## OU LE MODELE EST AVEUGLE — et ce que coûterait de lui ouvrir les yeux.
##
## ⚠ CE N'EST PAS `grammar_price.gd`, ET LES DEUX SE COMPLETENT. Celui-la chiffre ce qu'une
## clause REFUSE -- combien de vocabulaire survit quand on interdit une forme de relief.
## Celui-ci chiffre l'autre levier, le vrai selon le dossier : ce qu'une tuile a le DROIT DE
## SAVOIR. Il ne refuse rien ; il mesure ou une meme tuile est sommee d'etre plusieurs choses,
## et ce que le bit qui l'en sortirait couterait en tuiles a peindre.
##
## Une tuile voit (silhouette de l'empreinte, bande, au ras). Ce qu'elle NE voit pas, c'est ce
## qu'il y a AU-DELA de ses cardinaux ouverts -- du vide, l'herbe d'un autre massif, ou la roche
## d'une autre falaise. Si une meme tuile borde tantot l'un tantot l'autre, une seule image ne
## peut pas etre juste dans les deux cas : le CHOIX de la tuile parait faux, et c'est le modele
## qui est aveugle, pas l'artiste qui a mal dessine.
##
## ⚠ ET IL REGARDE UN VRAI PAYSAGE, PAS SEULEMENT LE GUIDE. Le guide est une planche de
## specimens : il serre les tuiles rares les unes contre les autres, donc ses bords ouverts
## rencontrent l'inhabituel bien plus souvent qu'une carte de jeu. Mesure le 04/09/2026 : 12,3 %
## sur le guide, 2,1 % a 7,0 % sur des paysages batis au geste. LE GUIDE EXAGERE LE DEFAUT.
##
##     godot --headless --path . --script res://tools/blind_spots.gd

const HeightMask := preload("res://core/height_mask.gd")
const Massifs := preload("res://core/massifs.gd")
const Families := preload("res://core/families.gd")
const BlobIndex := preload("res://core/blob_index.gd")

const CARDS: Array[int] = [BlobIndex.N, BlobIndex.E, BlobIndex.S, BlobIndex.W]
const WAYS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const NAMES: Array[String] = ["vide", "herbe", "roche"]


const Gesture := preload("res://core/gesture.gd")


func _initialize() -> void:
	_look("le guide livre (planche de specimens)",
			HeightMask.read("res://guides/massifs.txt"))
	# ⚠ ET SUR UN VRAI PAYSAGE, PARCE QUE LE GUIDE N'EN EST PAS UN. Il montre toutes les
	# tuiles ; un monde bati par une suite de GESTES est celui qu'un level designer produit,
	# et ses proportions n'ont aucune raison d'etre les memes.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260904
	for round: int in range(3):
		var made: PackedStringArray = Gesture.walk(rng, 46, 32, 4)
		if not made.is_empty():
			_look("un paysage bati au geste (%d)" % round, made)
	quit()


func _look(label: String, world: PackedStringArray) -> void:
	print("")
	print("=== %s" % label)
	var top: Dictionary = {}
	for pose: Dictionary in Massifs.poses(world):
		var at: Vector2i = pose["cell"]
		if top.has(at) and int((top[at] as Dictionary)["level"]) > int(pose["level"]):
			continue
		top[at] = pose

	var known: Dictionary = {}
	for tile: int in Families.massif_tiles():
		known[tile] = true

	# tuile -> { contexte : nombre de cases }
	var faces: Dictionary = {}
	for cell: Vector2i in top.keys():
		var one: Dictionary = top[cell]
		var tile2: int = Massifs.key_of(one)
		if not known.has(tile2):
			continue
		var sil: int = int(one["sil"])
		# ⚠ UN CARACTERE PAR COTE, ET C'EST LA LECON. Premier essai : `"%d%d%d%d"` avec -1
		# pour un cote ferme -- le mot faisait six caracteres pour quatre cotes, et le
		# libelle lisait de travers. Les comptes etaient justes, la lecture mentait.
		var word: String = ""
		for k: int in range(4):
			if (sil & CARDS[k]) != 0:
				word += "-"   # ferme : la tuile le voit deja
				continue
			var near: Vector2i = cell + WAYS[k]
			if not top.has(near):
				word += "0"   # vide
			elif int((top[near] as Dictionary)["band"]) == Massifs.SURFACE:
				word += "1"   # herbe
			else:
				word += "2"   # roche
		if not faces.has(tile2):
			faces[tile2] = {}
		var seen: Dictionary = faces[tile2]
		seen[word] = int(seen.get(word, 0)) + 1

	var overloaded: int = 0
	var cells_minority: int = 0
	var total: int = 0
	var worst: Array = []
	for tile3: int in faces.keys():
		var seen2: Dictionary = faces[tile3]
		var count: int = 0
		var best: int = 0
		for word2: String in seen2.keys():
			count += int(seen2[word2])
			best = maxi(best, int(seen2[word2]))
		total += count
		if seen2.size() > 1:
			overloaded += 1
			cells_minority += count - best
			worst.append([count - best, tile3, seen2.size(), count])
	worst.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))

	print("guide massifs.txt : %d cases visibles portent une tuile du vocabulaire" % total)
	print("tuiles du vocabulaire vues : %d sur %d" % [faces.size(),
			Families.massif_tiles().size()])
	print("")
	print("TUILES SOMMEES D'ETRE PLUSIEURS CHOSES : %d" % overloaded)
	print("  cases en situation MINORITAIRE (la tuile y sert un contexte rare) : "
			+ "%d sur %d  (%.1f %%)" % [cells_minority, total,
			100.0 * float(cells_minority) / float(maxi(total, 1))])
	# ⚠ CE QUE COUTERAIT LE BIT, CHIFFRE AVANT D'EN BATIR QUOI QUE CE SOIT. Donner a la tuile
	# ce qu'il y a au-dela de ses cardinaux ouverts, c'est multiplier son vocabulaire par le
	# nombre de situations qu'elle rencontre. On compte les deux granularites : trois etats
	# (vide / herbe / roche) et deux (vide / matiere).
	var fine: int = 0
	var coarse: int = 0
	var coarse_minority: int = 0
	for tile4: int in faces.keys():
		var seen4: Dictionary = faces[tile4]
		fine += seen4.size()
		var rough: Dictionary = {}
		for word4: String in seen4.keys():
			var flat: String = word4.replace("2", "1")
			rough[flat] = int(rough.get(flat, 0)) + int(seen4[word4])
		coarse += rough.size()
		var best2: int = 0
		var count2: int = 0
		for flat2: String in rough.keys():
			count2 += int(rough[flat2])
			best2 = maxi(best2, int(rough[flat2]))
		coarse_minority += count2 - best2
	print("")
	print("CE QUE COUTERAIT LA CLAUSE -- le vocabulaire, borne BASSE (ce que le guide exhibe) :")
	print("  aujourd'hui                        : %d tuiles" % faces.size())
	print("  + bord a TROIS etats (vide/herbe/roche) : %d tuiles  (x%.1f), plus aucune situation partagee"
			% [fine, float(fine) / float(maxi(faces.size(), 1))])
	print("  + bord a DEUX etats (vide/matiere)      : %d tuiles  (x%.1f), reste %d cases partagees (%.1f %%)"
			% [coarse, float(coarse) / float(maxi(faces.size(), 1)), coarse_minority,
			100.0 * float(coarse_minority) / float(maxi(total, 1))])
	print("")
	print("les dix plus couteuses :")
	for k2: int in range(mini(10, worst.size())):
		var row: Array = worst[k2]
		var seen3: Dictionary = faces[int(row[1])]
		var detail: PackedStringArray = PackedStringArray()
		var words: Array = seen3.keys()
		words.sort_custom(func(a: String, b: String) -> bool:
			return int(seen3[a]) > int(seen3[b]))
		for word3: String in words:
			detail.append("%s x%d" % [_say(word3), int(seen3[word3])])
		print("  %-28s %d situations, %d cases dont %d minoritaires"
				% [Massifs.describe(int(row[1])), int(row[2]), int(row[3]), int(row[0])])
		print("        %s" % ", ".join(detail))

	# ⚠ LA COURBE, ET C'EST ELLE QUI DIT S'IL Y A UN SWEET SPOT. Donner le bit a TOUT le monde
	# coute x2.8 ; le donner aux k tuiles les plus couteuses coute beaucoup moins. On veut
	# savoir ou la courbe se couche. Mesure du 04/09 : elle ne se couche PAS -- ~2 tuiles
	# pour ~0,5 point, lineairement. Il n'y a pas de sweet spot a trouver de ce cote.
	print("  le bit donne aux k tuiles les plus couteuses :")
	var left: int = cells_minority
	var added: int = 0
	for k3: int in range(worst.size()):
		var row2: Array = worst[k3]
		left -= int(row2[0])
		added += (faces[int(row2[1])] as Dictionary).size() - 1
		if k3 < 6 or k3 == 9 or k3 == 13 or k3 == worst.size() - 1:
			print("      k=%-3d  %3d tuiles   reste %5d cases partagees (%.1f %%)"
					% [k3 + 1, faces.size() + added, left,
					100.0 * float(left) / float(maxi(total, 1))])


## Le contexte, en clair : ce qu'il y a au-dela de chaque cardinal OUVERT.
func _say(word: String) -> String:
	var sides: Array[String] = ["N", "E", "S", "O"]
	var out: PackedStringArray = PackedStringArray()
	for k: int in range(4):
		var mark: String = word.substr(k, 1)
		if mark == "-":
			continue
		out.append("%s=%s" % [sides[k], NAMES[mark.to_int()]])
	return "aucun bord ouvert" if out.is_empty() else " ".join(out)
