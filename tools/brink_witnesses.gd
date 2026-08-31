extends SceneTree

## LES TEMOINS DES BITS DE BORD -- les agencements qu'un guide doit porter et qu'aucun
## paysage ne produit de lui-meme.
##
##     godot --headless --path . --script res://tools/brink_witnesses.gd -- <forme.txt> [battues]
##
## `forme.txt` est la sortie de `python tools/closed_form_now.py --liste` : la borne haute du
## modele, cle par cle. Peintes, ces cles tombent en un nombre fini de DESSINS -- c'est ce
## nombre-la qu'une planche doit porter, et donc ce qu'un guide doit exercer.
##
## ⚠ ET C'EST LA MEME METHODE QUE LES HUIT TEMOINS DE ROBE, POUR LA MEME RAISON. « Ils ne sont
## pas dessines a la main, ils sont TROUVES » : dessiner ces agencements a la main, c'est se
## tromper d'une case et d'un etage a chaque essai. Ici la difference est plus fine encore --
## un bit de bord ne se lit pas dans une silhouette, il depend d'une robe voisine, de la case
## du dessus, de celle du dessous. Le plan avait suppose « un accident par bit » ; la mesure dit
## que les sept bits sont tous exerces, et que ce sont des COMBINAISONS silhouette + bit qui
## manquent -- ce qu'aucun accident nomme ne va chercher.
##
## ⚠ ET LA DECOUPE MENT, C'EST DEJA MESURE AU DOSSIER : onze tuiles sur cinquante et une
## disparaissaient quand on coupait autour d'elles, parce que le bord de la fenetre change le
## voisinage. On ne coupe donc jamais sans REVERIFIER -- et on reverifie dans le contexte ou le
## temoin sera POSE, c'est-a-dire au milieu d'un champ de plaine, pas seul au monde.
##
## ⚠ LA BATTUE EST UN GENERATEUR, PAS UNE REGLE. Elle tire des gestes de pinceau -- tampons
## 3x3, refus de toute case fine -- comme celle du banc, mais elle n'a pas a lui etre
## identique : ce qu'elle trouve est verifie, ce qu'elle manque ne coute qu'une graine de plus.

const HeightMask := preload("res://core/height_mask.gd")
const Thickness := preload("res://core/thickness.gd")
const Brink := preload("res://core/brink.gd")
const Walls := preload("res://core/walls.gd")
const Compose := preload("res://render/contour.gd")
const Tiles := preload("res://render/contour_tiles.gd")
const Modes := preload("res://core/modes.gd")

## L3 : le monde complet -- etages empiles, falaises, poses arriere. C'est celui que le
## logiciel livre ; L5, la famille a cheval, reste au banc.
const LEVEL: int = 3
## F1 : le trait droit. Le compte de dessins ne bouge pas entre F1 et F2 -- mesure au dossier.
const FREEDOM: int = 1
## La plaine gardee autour d'une decoupe, dans le bloc lui-meme.
const FRAME: int = 2
## La plaine ajoutee autour du bloc POUR LE VERIFIER : c'est le champ de la reserve.
const PAD: int = 8
const OUT_PATH: String = "res://core/brink_witnesses.gd"

## cle -> empreinte de son dessin ; empreinte -> plus petite cle du groupe.
var _drawing: Dictionary = {}
var _rep: Dictionary = {}


## `PART=i/n` : la part de la recherche que ce processus prend en charge.
##
## ⚠ UN PROCESSUS N'UTILISE QU'UN COEUR, ET LA RECHERCHE EST EMBARRASSANTE DE PARALLELISME.
## C'est le meme decoupage que `LADDER_SHARD` au banc, pour la meme raison : chaque part
## cherche LES MEMES dessins dans SA tranche de graines, et la fusion garde les meilleurs.
## Les parts se recouvrent en temoins -- tant mieux, le recouvrement choisit.
var _part: int = 0
var _parts: int = 1


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("donner la forme fermee : -- <forme.txt> [battues] [blocs.txt]")
		printerr("ou fusionner les parts  : -- --fusion <forme.txt> <blocs.txt>...")
		quit(1)
		return
	Tiles.level = LEVEL
	if args[0] == "--fusion":
		_merge(args)
		return
	if args[0] == "--groupes":
		_show_groups(args[1] if args.size() > 1 else "")
		return
	if args[0] == "--couverture":
		_coverage(args)
		return
	var rounds: int = args[1].to_int() if args.size() > 1 else 60
	var raw: String = args[2] if args.size() > 2 else ""
	var cut: PackedStringArray = OS.get_environment("PART").split("/")
	if cut.size() == 2:
		_part = cut[0].to_int()
		_parts = maxi(1, cut[1].to_int())
	if not _forms(args[0]):
		quit(1)
		return
	var missing: Dictionary = _missing()
	if missing.is_empty():
		quit(0)
		return
	var found: Array[Dictionary] = _hunt(missing, rounds)
	if raw.is_empty():
		_write(_cover(found, missing))
	else:
		_store(found, raw)
	quit(0)


## Ce que le guide N'EXERCE PAS -- la seule question qui serve au redessin.
func _missing() -> Dictionary:
	var guide: PackedStringArray = HeightMask.read(Modes.guide_path(Modes.EPAIS))
	var touched: Dictionary = _drawings_of(_posed(guide))
	var missing: Dictionary = {}
	for mark: Variant in _rep.keys():
		if not touched.has(mark):
			missing[mark] = true
	print("=== LES TEMOINS DES BITS DE BORD (part %d/%d) ===" % [_part + 1, _parts])
	print("  %d dessins au total, %d exerces par le guide, %d A TROUVER"
			% [_rep.size(), touched.size(), missing.size()])
	print("  MANQUENT : %s" % _named(missing))
	return missing


## LA COUVERTURE DE PLUSIEURS MONDES REUNIS -- la question du redessin, posee a l'endroit.
##
## ⚠ ET C'EST L'UNION QUI COMPTE, PAS CHAQUE MONDE. Le guide livre porte le paysage, le guide
## des temoins porte ce qu'aucun paysage ne produit : un dessin exerce par l'un ou par l'autre
## est peignable, et c'est tout ce que la regle 5 demande.
func _coverage(args: PackedStringArray) -> void:
	if args.size() < 3:
		printerr("couverture : -- --couverture <forme.txt> <monde.txt>...")
		quit(1)
		return
	if not _forms(args[1]):
		quit(1)
		return
	var touched: Dictionary = {}
	print("=== LA COUVERTURE DE LA FORME FERMEE ===")
	for at: int in range(2, args.size()):
		var world: PackedStringArray = HeightMask.read(args[at])
		var mine: Dictionary = _drawings_of(_posed(world))
		for mark: Variant in mine.keys():
			touched[mark] = true
		print("  %s : %d dessin(s) sur %d" % [args[at], mine.size(), _rep.size()])
	var missing: Dictionary = {}
	for mark2: Variant in _rep.keys():
		if not touched.has(mark2):
			missing[mark2] = true
	print("  REUNIS : %d dessin(s) sur %d" % [touched.size(), _rep.size()])
	if missing.is_empty():
		print("  RIEN NE MANQUE.")
	else:
		print("  MANQUENT (%d) : %s" % [missing.size(), _named(missing)])
	quit(0 if missing.is_empty() else 1)


## ⚠ UN DESSIN N'EST PAS UNE CLE, C'EST UN GROUPE DE CLES -- et c'est ce qui decide de sa
## realisabilite. Le representant est la plus PETITE cle du groupe, pas la plus facile a
## produire : conclure « impossible » sur lui seul reviendrait a condamner un dessin que
## l'une de ses autres cles rend banal. On les nomme donc toutes.
func _show_groups(path: String) -> void:
	if not _forms(path):
		quit(1)
		return
	var missing: Dictionary = _missing()
	var members: Dictionary = {}
	for key: Variant in _drawing.keys():
		var mark: String = _drawing[key]
		if not members.has(mark):
			members[mark] = []
		(members[mark] as Array).append(int(key))
	var lines: Array[String] = []
	for mark2: Variant in missing.keys():
		var group: Array = members[mark2]
		group.sort()
		var told: PackedStringArray = PackedStringArray()
		for key2: int in group:
			told.append("s%d" % (key2 & 0xff))
		lines.append("  %d(b%d) <- %d cle(s) : %s"
				% [int(_rep[mark2]), int(_rep[mark2]) >> 8, group.size(), ", ".join(told)])
	lines.sort()
	for line: String in lines:
		print(line)
	if not path.is_empty():
		print("  (%s ignore)" % path)
	quit(0)


## LES BLOCS BRUTS D'UNE PART : rien de plus, la fusion recalcule ce qu'ils portent.
func _store(found: Array[Dictionary], path: String) -> void:
	var text: String = ""
	for block: Dictionary in found:
		for line: String in (block["rows"] as PackedStringArray):
			text += line + "\n"
		text += "---\n"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("ecriture impossible : %s" % path)
		return
	file.store_string(text)
	file.close()
	print("  %d bloc(s) ecrit(s) : %s" % [found.size(), path])


## LES BLOCS DEJA ECRITS, relus depuis `core/brink_witnesses.gd`.
##
## ⚠ ON LES RELIT COMME DES DONNEES, PAS COMME DU CODE. Le fichier est du GDScript, mais on
## n'a besoin que de ses lignes de bloc : les extraire au motif evite de le precharger, donc
## d'avoir a le regenerer avant de pouvoir le lire.
func _kept_blocks() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	var text: String = FileAccess.get_file_as_string(OUT_PATH)
	if text.is_empty():
		return out
	var rows: PackedStringArray = PackedStringArray()
	for line: String in text.split("
"):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("\"") and trimmed.ends_with("\","):
			rows.append(trimmed.substr(1, trimmed.length() - 3))
			continue
		if not rows.is_empty():
			out.append(rows)
			rows = PackedStringArray()
	if not rows.is_empty():
		out.append(rows)
	return out


## LA FUSION : toutes les parts, un seul recouvrement.
##
## ⚠ ET ON RECALCULE CE QUE CHAQUE BLOC PORTE, on ne le croit pas sur parole. Une part
## pourrait avoir ete lancee sur un autre etat de l'arbre ; recalculer coute quelques
## millisecondes par bloc et supprime la question.
func _merge(args: PackedStringArray) -> void:
	if args.size() < 3:
		printerr("fusionner : -- --fusion <forme.txt> <blocs.txt>...")
		quit(1)
		return
	if not _forms(args[1]):
		quit(1)
		return
	var missing: Dictionary = _missing()
	var found: Array[Dictionary] = []
	# ⚠ LA FUSION EST ADDITIVE, JAMAIS SOUSTRACTIVE -- et elle ne l'etait pas. Elle mesure ce
	# qui manque AU GUIDE, lequel contient deja sa reserve : les blocs qui la remplissent
	# paraissent donc inutiles, elle ne les retient pas, et le guide rebati les perd. Mesure :
	# deux fois de suite, le fichier des temoins est tombe de huit blocs a trois puis a ZERO,
	# et le guide de complet a onze manquants.
	#
	# ⚠ ET C'EST LA MEME ESPECE QUE LA REGLE DU DOSSIER SUR LES GARDE-FOUS : un outil qui
	# mesure « ce qui manque » sur un etat qui contient deja sa propre reponse ne mesure rien.
	# On relit donc ce qu'on a deja ecrit et on le garde -- la reserve ne peut que croitre.
	# ⚠ ET LE BUT AUSSI EST ADDITIF, PAS SEULEMENT LA LISTE DES CANDIDATS. Relire les anciens
	# blocs ne suffisait pas : le recouvrement ne visait que ce qui manque AU GUIDE, et le
	# guide contient deja la reserve -- donc les anciens ne couvraient « rien a faire » et
	# tombaient quand meme. Le but est donc `manque ∪ ce que la reserve porte deja`, ce qui
	# revient a mesurer sur le PAYSAGE SEUL sans avoir a le rebatir.
	for old_rows: PackedStringArray in _kept_blocks():
		var carried: Dictionary = _carried(old_rows)
		found.append({"rows": old_rows, "carries": carried})
		for mark4: Variant in carried.keys():
			if _rep.has(mark4):
				missing[mark4] = true
	for at: int in range(2, args.size()):
		var text: String = FileAccess.get_file_as_string(args[at])
		var rows: PackedStringArray = PackedStringArray()
		for line: String in text.split("\n"):
			if line == "---":
				if not rows.is_empty():
					found.append({"rows": rows, "carries": _carried(rows)})
					# ⚠ ET ON PROPOSE AUSSI LE BLOC RECADRE, sans jamais l'imposer. Une
					# decoupe large est surtout de la plaine, et chaque case coute de la
					# place a l'ecran -- mais recadrer CHANGE le voisinage, donc le
					# recadre entre au recouvrement comme un candidat de plus, verifie
					# comme les autres. Il gagne quand il porte autant, sur moins.
					var slim: PackedStringArray = _trim(rows)
					if slim.size() < rows.size():
						found.append({"rows": slim, "carries": _carried(slim)})
				rows = PackedStringArray()
				continue
			if not line.strip_edges().is_empty():
				rows.append(line)
	print("  %d bloc(s) relus de %d part(s)" % [found.size(), args.size() - 2])
	_write(_cover(found, missing))
	quit(0)


## LES DESSINS : on peint les cles de la forme et on compare LES PIXELS, pas les bits.
## C'est la meme fabrique que celle du banc et que celle du produit -- une seule source.
func _forms(path: String) -> bool:
	var text: String = FileAccess.get_file_as_string(path)
	if text.strip_edges().is_empty():
		printerr("liste de cles introuvable ou vide : %s" % path)
		return false
	var vocabulary: Dictionary = {}
	for piece: String in text.strip_edges().split(",", false):
		vocabulary[int(piece.strip_edges())] = true
	# ⚠ ON CHASSE DES CLES, PLUS DES DESSINS -- et c'est le modele qui a change, pas l'envie.
	# La premisse de cet outil etait « peintes, ces cles tombent en un nombre fini de DESSINS,
	# c'est ce nombre-la qu'une planche doit porter ». Elle est fausse depuis que la planche est
	# KEYEE : deux cles peuvent tomber dans deux classes de raccord differentes, donc exiger
	# deux bords differents, et une seule image ne peut pas satisfaire les deux. Mesure qui
	# tranche : les DESSINS de robe varient de 8 a 17 selon le monde, parce qu'ils dependent des
	# graines de classe -- ce n'est pas une constante du modele, donc pas une taille de planche.
	#
	# ⚠ ET CA REND L'OUTIL BEAUCOUP PLUS RAPIDE : plus rien a peindre pour savoir ce qui manque.
	for key: Variant in vocabulary.keys():
		_drawing[int(key)] = str(int(key))
		_rep[str(int(key))] = int(key)
	return true


## Les cles qu'un relief POSE, et ou : tous les etages, enterres compris.
func _posed(world: PackedStringArray) -> Dictionary:
	var made: Dictionary = Brink.keys(world, LEVEL)
	var out: Dictionary = {}
	for storey: Dictionary in (made["storeys"] as Array[Dictionary]):
		for cell: Vector2i in storey.keys():
			out[int(storey[cell])] = cell
	return out


## ⚠ ET UNE CLE HORS DE LA FORME EST UNE ERREUR DE TRANSCRIPTION, PAS UN MONDE FAUTIF. La
## forme est une borne HAUTE : un monde ne peut rien poser qu'elle ne contienne. On le dit
## plutot que de l'ignorer -- la lecon est au dossier, elle a deja mordu une fois.
func _drawings_of(posed: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var strays: Array[int] = []
	for key: Variant in posed.keys():
		if not _drawing.has(int(key)):
			strays.append(int(key))
			continue
		out[String(_drawing[int(key)])] = true
	if not strays.is_empty():
		strays.sort()
		printerr("  ⚠ %d cle(s) posee(s) HORS de la forme fermee : %s" % [strays.size(),
				str(strays)])
	return out


## LA BATTUE : des gestes de pinceau sur un champ de PLAINE, et le refus de toute case fine.
##
## ⚠ ET ELLE EST CLAIRSEMEE, LA OU CELLE DU BANC EST DENSE. C'est mesure : quatre cents gestes
## sur un cadre de vide font un monde ou presque tout est couvert par une robe, donc ou les
## bits de bord sont partout et ou aucun agencement SIMPLE ne survit -- trois battues denses
## n'ont rendu qu'un temoin sur dix-huit. Ce qui manque au guide, ce sont des accidents nets
## poses sur de la plaine : un coude franc, une terrasse qui descend d'un cran. On tire donc
## quelques gestes seulement, et le fond est de la plaine, jamais du vide.
func _battue(graine: int) -> PackedStringArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = graine
	var width: int = 26
	var height: int = 22
	var edge: int = 4
	var grid: Array[PackedByteArray] = []
	for y: int in range(height):
		var line: PackedByteArray = PackedByteArray()
		line.resize(width)
		line.fill(1)
		grid.append(line)
	for gesture: int in range(rng.randi_range(2, 14)):
		var level: int = rng.randi_range(0, 3)
		var ox: int = rng.randi_range(edge, width - edge - 3)
		var oy: int = rng.randi_range(edge, height - edge - 3)
		if rng.randf() < 0.7:
			ox = edge + ((ox - edge) / 3) * 3
			oy = edge + ((oy - edge) / 3) * 3
		var before: Array[PackedByteArray] = []
		for line2: PackedByteArray in grid:
			before.append(line2.duplicate())
		for y2: int in range(oy, oy + 3):
			for x2: int in range(ox, ox + 3):
				var row: PackedByteArray = grid[y2]
				row[x2] = level + 1
				grid[y2] = row
		if not Thickness.thin_cells(_text(grid)).is_empty():
			grid = before
	# ⚠ LA MARGE DU BAS VAUT UNE CHUTE ENTIERE. Une robe coupee par le cadre laisse son
	# contour ouvert -- ce serait un defaut du MONDE, et il accuserait la regle a tort.
	var out: PackedStringArray = _text(grid)
	var flat: String = ""
	for x3: int in range(width):
		flat += "0"
	for row2: int in range(Walls.STOREY_TILES * 4):
		out.append(flat)
	return out


## LES TERRASSES : des plateaux RECTANGULAIRES, pas des tampons de trois.
##
## ⚠ ET C'EST LA MESURE QUI A IMPOSE CE GENERATEUR-LA. Les dessins qui manquent au guide
## demandent un etage qui descend d'un cran, une chute qui atterrit juste au-dessus d'un bord,
## une face qui longe une autre face : des accidents a bords LONGS et droits. Un tampon de
## trois, tire au hasard, fait du bruit -- il en a rendu trois sur dix-huit. Un rectangle de
## six ou de neuf fait une terrasse, et une terrasse porte ces rencontres-la.
##
## ⚠ ET L'ETAGE ZERO EST UN ETAGE COMME UN AUTRE : le poser CREUSE, ce qui ouvre les ravins.
## Sans ravin, pas de face qui en longe une autre.
func _terraces(graine: int) -> PackedStringArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = graine
	var width: int = 30
	var height: int = 27
	var grid: Array[PackedByteArray] = []
	for y: int in range(height):
		var line: PackedByteArray = PackedByteArray()
		line.resize(width)
		line.fill(1)
		grid.append(line)
	for shape: int in range(rng.randi_range(2, 6)):
		var level: int = rng.randi_range(0, 3)
		var w: int = rng.randi_range(3, 12)
		var h: int = rng.randi_range(3, 12)
		var ox: int = rng.randi_range(3, width - 3 - w)
		var oy: int = rng.randi_range(3, height - 3 - h)
		# ⚠ ET LA POSE DECALEE EST INDISPENSABLE, C'EST MESURE. La famille ALIGNEE sur trois
		# s'enumere en entier -- 19 683 reliefs -- et elle ne rend AUCUN des dix-huit. La
		# raison est geometrique : ce qui manque demande une banquette qui s'arrete UNE
		# rangee au-dessus d'un bord, et un monde aligne ne s'arrete qu'aux multiples de
		# trois. Les gestes decales font partie du domaine -- le pinceau les pose -- et ce
		# sont eux, et eux seuls, qui ont rendu les sept premiers temoins.
		if rng.randf() < 0.4:
			ox = 3 + ((ox - 3) / 3) * 3
			oy = 3 + ((oy - 3) / 3) * 3
		var before: Array[PackedByteArray] = []
		for line2: PackedByteArray in grid:
			before.append(line2.duplicate())
		for y2: int in range(oy, mini(oy + h, height)):
			for x2: int in range(ox, mini(ox + w, width)):
				var row: PackedByteArray = grid[y2]
				row[x2] = level + 1
				grid[y2] = row
		if not Thickness.thin_cells(_text(grid)).is_empty():
			grid = before
	var out: PackedStringArray = _text(grid)
	var flat: String = ""
	for x3: int in range(width):
		flat += "0"
	for row2: int in range(Walls.STOREY_TILES * 4):
		out.append(flat)
	return out


func _text(grid: Array[PackedByteArray]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: PackedByteArray in grid:
		var said: String = ""
		for value: int in line:
			said += "~" if value == 0 else str(value - 1)
		out.append(said)
	return out


## LA DECOUPE : une fenetre du relief, le vide rendu a la plaine, et une plaine autour.
##
## ⚠ LE VIDE DEVIENT DE LA PLAINE, ET C'EST UNE DECISION. La reserve du guide EST un champ de
## plaine : un temoin qui porterait son propre gouffre y creuserait un trou que rien n'a
## demande, et sa robe tomberait de douze rangees dans la case du voisin.
func _cut(world: PackedStringArray, at: Vector2i, radius: int) -> PackedStringArray:
	var top: int = 0
	var rows: PackedStringArray = PackedStringArray()
	for y: int in range(at.y - radius, at.y + radius + 1):
		var line: String = ""
		for x: int in range(at.x - radius, at.x + radius + 1):
			var level: int = maxi(0, HeightMask.level_at(world, x, y))
			top = maxi(top, level)
			line += str(level)
		rows.append(line)
	return _framed(rows, top)


## La plaine autour, et la chute la plus longue en dessous : une robe hors du cadre est une
## tuile impeignable.
func _framed(rows: PackedStringArray, top: int) -> PackedStringArray:
	var width: int = rows[0].length() + 2 * FRAME
	var flat: String = ""
	for x: int in range(width):
		flat += "0"
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(FRAME):
		out.append(flat)
	var side: String = ""
	for x2: int in range(FRAME):
		side += "0"
	for line: String in rows:
		out.append(side + line + side)
	for y2: int in range(FRAME + Walls.STOREY_TILES * top + 2):
		out.append(flat)
	return out


## LE TEMOIN DANS LE CONTEXTE OU IL SERA POSE : au milieu d'un champ de plaine, jamais seul
## au monde. Un bloc verifie hors contexte se decale d'un bit une fois pose, et le decalage ne
## se voit nulle part.
func _in_field(block: PackedStringArray) -> PackedStringArray:
	var width: int = block[0].length() + 2 * PAD
	var flat: String = ""
	for x: int in range(width):
		flat += "0"
	var out: PackedStringArray = PackedStringArray()
	for y: int in range(PAD):
		out.append(flat)
	var side: String = ""
	for x2: int in range(PAD):
		side += "0"
	for line: String in block:
		out.append(side + line + side)
	for y2: int in range(PAD):
		out.append(flat)
	return out


## Ce qu'un bloc porte VRAIMENT, une fois pose : le dessin de chaque cle, et ou elle tombe.
func _carried(block: PackedStringArray) -> Dictionary:
	if not Thickness.thin_cells(block).is_empty():
		return {}
	var posed: Dictionary = _posed(_in_field(block))
	var out: Dictionary = {}
	for key: Variant in posed.keys():
		if not _drawing.has(int(key)):
			continue
		var cell: Vector2i = posed[key]
		out[String(_drawing[int(key)])] = Vector3i(cell.x - PAD, cell.y - PAD, int(key))
	return out


## LA FAMILLE ALIGNEE, ENUMEREE : `blocks_x` x `blocks_y` tampons de 3x3, un etage par tampon.
##
## ⚠ C'EST LE DOMAINE, ET IL EST DEJA MESURE AU DOSSIER. SoluPaint pose des tampons 3x3 et
## refuse toute case fine ; « une main pose aligne, le hasard non ». L'epaisseur y est donc
## GRATUITE -- toute course est un multiple de trois -- et la famille s'enumere, la ou l'espace
## des reliefs quelconques ne s'enumere pas. C'est aussi la seule qui produise ce qui manque :
## une battue clairsemee, tiree au hasard, n'a rendu que trois temoins sur dix-huit.
func _aligned(order: int, wide: int, tall: int, states: int) -> PackedStringArray:
	var levels: Array[int] = []
	var rest: int = order
	var top: int = 0
	for block: int in range(wide * tall):
		levels.append(rest % states)
		top = maxi(top, rest % states)
		rest /= states
	var rows: PackedStringArray = PackedStringArray()
	for y: int in range(tall * 3):
		var line: String = ""
		for x: int in range(wide * 3):
			line += str(levels[(y / 3) * wide + (x / 3)])
		rows.append(line)
	return _framed(rows, top)


## Ce qui n'est que de la plaine autour du bloc ne sert a rien -- et chaque case coute de la
## place a l'ecran. On recadre sur ce qui monte, en gardant la marge et la chute.
func _trim(block: PackedStringArray) -> PackedStringArray:
	var top: int = 0
	var first: int = block.size()
	var last: int = -1
	var left: int = block[0].length()
	var right: int = -1
	for y: int in range(block.size()):
		for x: int in range(block[y].length()):
			var level: int = int(block[y][x])
			if level <= 0:
				continue
			top = maxi(top, level)
			first = mini(first, y)
			last = maxi(last, y)
			left = mini(left, x)
			right = maxi(right, x)
	if last < 0:
		return block
	var rows: PackedStringArray = PackedStringArray()
	for y2: int in range(first, last + 1):
		rows.append(block[y2].substr(left, right - left + 1))
	return _framed(rows, top)


## LE BALAYAGE : chaque relief de la famille, et ce qu'il porte. Le relief EST le temoin --
## il est deja borde de plaine, deja epais, deja de la taille d'un ilot.
func _sweep(found: Array[Dictionary], still: Dictionary, wide: int, tall: int,
		states: int, budget_ms: int) -> void:
	var total: int = 1
	for block: int in range(wide * tall):
		total *= states
	var start: int = Time.get_ticks_msec()
	for order: int in range(total):
		if still.is_empty():
			break
		# ⚠ ET LE BUDGET SE DIT, IL NE SE TAIT PAS. Une famille plus large ne s'enumere pas
		# en une soiree -- 531 441 reliefs -- et un balayage qui s'arrete en silence ferait
		# passer « pas trouve » pour « n'existe pas ».
		if budget_ms > 0 and Time.get_ticks_msec() - start > budget_ms:
			print("  ⚠ budget epuise a %d/%d reliefs" % [order, total])
			break
		if order % _parts != _part:
			continue
		var block2: PackedStringArray = _trim(_aligned(order, wide, tall, states))
		var carries: Dictionary = _carried(block2)
		var useful: bool = false
		for mark: Variant in carries.keys():
			if still.has(mark):
				useful = true
		if not useful:
			continue
		found.append({"rows": block2, "carries": carries})
		for got: Variant in carries.keys():
			still.erase(got)
		print("     %d/%d : un temoin de plus, %d dessin(s) restant(s)"
				% [order + 1, total, still.size()])
	print("  famille %dx%d blocs, %d etats : %d relief(s) en %d ms, %d dessin(s) restant(s)"
			% [wide, tall, states, total, Time.get_ticks_msec() - start, still.size()])


## UN MONDE, DECOUPE PARTOUT OU IL PORTE CE QUI MANQUE.
func _from_world(found: Array[Dictionary], still: Dictionary,
		world: PackedStringArray) -> void:
	var made: Dictionary = Brink.keys(world, LEVEL)
	var seen: Dictionary = {}
	for storey: Dictionary in (made["storeys"] as Array[Dictionary]):
		for cell: Vector2i in storey.keys():
			var key: int = int(storey[cell])
			if not _drawing.has(key):
				continue
			var mark: String = _drawing[key]
			if not still.has(mark) or seen.has(mark):
				continue
			# ⚠ ET ON NE RAYE LE DESSIN QU'UNE FOIS LE TEMOIN TROUVE, jamais des qu'on
			# l'a vu. Une decoupe peut echouer la ou une autre case du meme monde aurait
			# tenu : rayer a la vue reviendrait a n'essayer qu'une fois par monde.
			for radius: int in [4, 6, 8, 11]:
				var block: PackedStringArray = _cut(world, cell, radius)
				var carries: Dictionary = _carried(block)
				if not carries.has(mark):
					continue
				seen[mark] = true
				found.append({"rows": block, "carries": carries})
				for got: Variant in carries.keys():
					still.erase(got)
				break


func _hunt(missing: Dictionary, rounds: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var still: Dictionary = missing.duplicate()
	# LES TERRASSES D'ABORD : ce sont elles qui portent les rencontres qui manquent.
	for run: int in range(rounds):
		if still.is_empty():
			break
		if run % _parts != _part:
			continue
		_from_world(found, still, _terraces(20260830 + run * 7919))
		if run % 50 == 49:
			print("  terrasses %d : %d dessin(s) encore introuvable(s)"
					% [run + 1, still.size()])
	# ⚠ ET LA FAMILLE ALIGNEE NE SERT PLUS DE MOTEUR, ELLE RESTE JOIGNABLE. Ses 19 683
	# reliefs ont ete parcourus EN ENTIER, cinq fois : ils n'ont rendu AUCUN des dix-huit.
	# Trois minutes par part pour rien -- la mesure vaut d'etre gardee, la depense non.
	# PUIS DES GESTES CLAIRSEMES, pour le reste.
	for run2: int in range(rounds):
		if still.is_empty():
			break
		if run2 % _parts != _part:
			continue
		_from_world(found, still, _battue(20260901 + run2 * 6997))
	if not still.is_empty():
		printerr("  ⚠ %d DESSIN(S) SANS TEMOIN : %s" % [still.size(), _named(still)])
	return found


## LE RECOUVREMENT : le moins de blocs possible, parce que chaque bloc coute de la place a
## l'ecran -- et que ce qui compte n'est pas le nombre de cases mais la taille de la case a
## l'ecran, deja mesure au dossier.
func _cover(found: Array[Dictionary], missing: Dictionary) -> Array[Dictionary]:
	var still: Dictionary = missing.duplicate()
	var kept: Array[Dictionary] = []
	while not still.is_empty():
		var best: int = -1
		var score: int = 0
		var area: int = 0
		for at: int in range(found.size()):
			var carries: Dictionary = found[at]["carries"]
			var gain: int = 0
			for mark: Variant in carries.keys():
				if still.has(mark):
					gain += 1
			if gain == 0:
				continue
			var rows: PackedStringArray = found[at]["rows"]
			var size: int = rows.size() * rows[0].length()
			if gain > score or (gain == score and size < area):
				best = at
				score = gain
				area = size
		if best < 0:
			break
		var chosen: Dictionary = found[best]
		var useful: Array[Vector3i] = []
		for mark2: Variant in (chosen["carries"] as Dictionary).keys():
			if still.has(mark2):
				useful.append((chosen["carries"] as Dictionary)[mark2])
				still.erase(mark2)
		chosen["useful"] = useful
		kept.append(chosen)
		found.remove_at(best)
	print("  %d bloc(s) retenu(s) pour %d dessin(s)" % [kept.size(), missing.size()])
	if not still.is_empty():
		printerr("  ⚠ %d dessin(s) sans temoin : %s" % [still.size(), _named(still)])
	return kept


func _named(marks: Dictionary) -> String:
	var told: PackedStringArray = PackedStringArray()
	for mark: Variant in marks.keys():
		var key: int = int(_rep[mark])
		told.append("%d(s%d,b%d)" % [key, key & 0xff, key >> 8])
	told.sort()
	return " ".join(told)


func _write(kept: Array[Dictionary]) -> void:
	var text: String = "## LES TEMOINS DES BITS DE BORD, pour la reserve du guide.\n"
	text += "##\n"
	text += "## Trouves par `tools/brink_witnesses.gd` dans des battues de pinceau, puis\n"
	text += "## decoupes et REVERIFIES au milieu d'un champ de plaine -- le contexte ou ils\n"
	text += "## seront poses. Ne pas editer a la main : le batisseur du guide reverifie chaque\n"
	text += "## cle a l'endroit ou il la pose.\n"
	text += "##\n"
	text += "## EN TABLEAUX SIMPLES, PAS EN PackedStringArray : GDScript ne fait pas une\n"
	text += "## constante d'un paquet type de ce genre -- le membre cesse de se resoudre, et\n"
	text += "## tout ce qui prechargeait le fichier tombe avec lui, sans erreur claire.\n"
	text += "const BLOCKS: Array = [\n"
	for block: Dictionary in kept:
		text += "\t[\n"
		for line: String in (block["rows"] as PackedStringArray):
			text += "\t\t\"%s\",\n" % line
		text += "\t],\n"
	text += "]\n\n\n"
	text += "## Ce que chaque bloc porte : `x, y, cle`, en coordonnees du bloc.\n"
	text += "const CARRIES: Array = [\n"
	for block2: Dictionary in kept:
		var told: PackedStringArray = PackedStringArray()
		for spot: Vector3i in (block2["useful"] as Array[Vector3i]):
			told.append("Vector3i(%d, %d, %d)" % [spot.x, spot.y, spot.z])
		text += "\t[%s],\n" % ", ".join(told)
	text += "]\n"
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("ecriture impossible : %s" % OUT_PATH)
		return
	file.store_string(text)
	file.close()
	print("  ecrit : %s" % OUT_PATH)
