extends RefCounted

## LES ARCHÉTYPES — le vocabulaire FERMÉ du modèle par les coins : toutes les clés possibles (DESSUS c ; HAUT c, c_dessus ;
## BAS c, c_dessous), groupées par IMAGE (deux clés qui dessinent exactement la même chose sont le même archétype, peint
## une seule fois). Compté, jamais chassé : 79 clés, 35 archétypes (banc du 4 novembre 2026).
## `numero(sorte, c, cv)` rend l'archétype d'une pose ; `liste()` les archétypes, chacun avec une clé qui le représente.

const Modele := preload("res://core/coins/modele.gd")
const COTE := 16          # la résolution de la signature (assez fine pour séparer les formes)

static var _par_cle := {}
static var _liste: Array = []


static func cle(sorte: int, c: int, cv: int) -> String:
	return "%d:%d:%d" % [sorte, c, cv if sorte != Modele.DESSUS else 0]


static func numero(sorte: int, c: int, cv: int) -> int:
	_construire()
	return int(_par_cle.get(cle(sorte, c, cv), -1))


## [{numero, sorte, c, cv, cles: [..]}] dans un ordre fixe (dessus, hauts, bas ; puis par clé).
static func liste() -> Array:
	_construire()
	return _liste


static func _construire() -> void:
	if not _liste.is_empty():
		return
	var par_image := {}
	var candidats := []
	for c in range(1, 16):
		candidats.append([Modele.DESSUS, c, 0])
	for sorte: int in [Modele.HAUT, Modele.BAS]:
		for c in range(1, 16):
			if not Modele.a_falaise(c):
				continue
			for cv in 16:
				var ok := (cv & c) == cv if sorte == Modele.HAUT else (cv & c) == c
				if ok:
					candidats.append([sorte, c, cv])
	for k: Array in candidats:
		var sig := PackedInt32Array()
		for py in COTE:
			for px in COTE:
				sig.append(Modele.etiquette(k[0], 1, k[1], k[2], (px + 0.5) / COTE, (py + 0.5) / COTE))
		var s := "%d/%d" % [k[0], hash(sig)]
		if not par_image.has(s):
			par_image[s] = {"numero": _liste.size(), "sorte": k[0], "c": k[1], "cv": k[2], "cles": []}
			_liste.append(par_image[s])
		par_image[s].cles.append(cle(k[0], k[1], k[2]))
		_par_cle[cle(k[0], k[1], k[2])] = par_image[s].numero
