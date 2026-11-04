# LA SIGNATURE — ce qu'on scelle, et pourquoi ce n'est pas une serrure.
#
# ⚠ ELLE N'EMPECHE RIEN, ET NE DOIT PAS PRETENDRE LE CONTRAIRE. Le plugin part chez l'acheteur
# en GDScript EN CLAIR : un controle qui refuserait une planche non signee saute en trente
# secondes, et la charte interdit de maquiller un verrou qui ne tient pas. La signature est donc
# une AFFIRMATION, pas une porte : elle dit « ceci sort de MarchingSquares », et le moteur le REPETE
# a l'acheteur au lieu de bloquer quoi que ce soit.
#
# ⚠ ET C'EST CE RENVERSEMENT QUI LA REND UTILE. On cesse d'essayer d'empecher la copie -- ce qui
# est impossible pour du texte et des pixels -- pour rendre l'AUTHENTICITE LISIBLE, ce qui est
# faisable et honnete. L'asymetrie qui reste est la seule vraie : un cloneur peut fabriquer des
# tilesets, il ne peut pas en fabriquer des SIGNES.
#
# ⚠ ON SCELLE LES PIXELS, PAS SEULEMENT LE TEXTE. Signer le seul manifeste laisserait echanger
# la planche sous lui : quelqu'un revendrait TA planche d'essai sous son nom avec un manifeste
# refait. Le condense porte donc les octets de l'image, la table des cases et la version --
# re-decouper, re-empaqueter ou echanger l'image casse le sceau.
#
# ⚠ ET LA CLE PRIVEE NE PART JAMAIS. Elle se lit dans `SOLUTILES_KEY`, une variable
# d'environnement qui pointe un fichier HORS du depot. Sans elle, l'export sort NON SIGNE et le
# DIT -- le build d'essai n'a pas de cle du tout, et c'est la piece la plus forte du dispositif.
extends RefCounted

## La variable qui pointe la cle privee. Hors du depot, toujours.
const KEY_VAR: String = "SOLUTILES_KEY"


## LE CONDENSE : les octets de la planche, la table des cases, la version.
##
## ⚠ L'ORDRE ET LES SEPARATEURS FONT PARTIE DU CONTRAT. Deux implementations qui les melangent
## autrement calculent deux condenses differents pour la meme planche, et la signature parait
## fausse alors que tout est juste. Le plugin en porte sa copie, et la suite compare les deux.
static func digest(sheet: PackedByteArray, table: String, version: int) -> PackedByteArray:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(("solutiles-seal %d\n" % version).to_utf8_buffer())
	context.update(sheet)
	context.update("\n".to_utf8_buffer())
	context.update(table.to_utf8_buffer())
	return context.finish()


## LA TABLE DES CASES, telle qu'elle entre dans le condense : une ligne par tuile, triee.
## ⚠ TRIEE, PARCE QU'UN DICTIONNAIRE NE PROMET AUCUN ORDRE. Sans le tri, deux exports de la
## meme planche donneraient deux condenses -- et la signature serait fausse une fois sur deux.
static func table_of(source: Dictionary) -> String:
	var order: Array[int] = []
	for tile: Variant in source.keys():
		order.append(int(tile))
	order.sort()
	var lines: PackedStringArray = PackedStringArray()
	for tile2: int in order:
		lines.append("%d:%d" % [tile2, int(source[tile2])])
	return "\n".join(lines)


## Y a-t-il une cle privee sous la main ?
static func can_sign() -> bool:
	var path: String = OS.get_environment(KEY_VAR)
	return not path.is_empty() and FileAccess.file_exists(path)


## LE SCEAU, en base64. Vide s'il n'y a pas de cle -- et ce n'est pas une erreur.
##
## ⚠ UN EXPORT NON SIGNE EST UN EXPORT NORMAL. C'est l'etat du build d'essai, et celui de
## n'importe quelle machine qui n'a pas la cle. Le refuser reviendrait a exiger un secret pour
## faire tourner ses propres tests.
static func seal(sheet: PackedByteArray, table: String, version: int) -> String:
	if not can_sign():
		return ""
	var key: CryptoKey = CryptoKey.new()
	if key.load(OS.get_environment(KEY_VAR), false) != OK:
		push_warning("signing: la cle privee ne se lit pas ; l'export sortira non signe.")
		return ""
	var crypto: Crypto = Crypto.new()
	var made: PackedByteArray = crypto.sign(HashingContext.HASH_SHA256,
			digest(sheet, table, version), key)
	return Marshalls.raw_to_base64(made)
