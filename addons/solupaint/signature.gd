# LE SCEAU, VERIFIE CHEZ L'ACHETEUR — et il DIT, il ne bloque pas.
#
# ⚠ CE N'EST PAS UNE SERRURE, ET CE FICHIER NE DOIT JAMAIS LE DEVENIR. Le plugin part en
# GDScript EN CLAIR : un controle qui refuserait une planche non signee saute en trente
# secondes, et la charte interdit de maquiller un verrou qui ne tient pas. On rend donc un
# VERDICT LISIBLE -- signe, non signe, ou sceau invalide -- et le monde le repete a l'acheteur.
#
# ⚠ ET « NON SIGNE » N'EST PAS UNE FAUTE. C'est l'etat de l'essai livre avec le plugin, et celui
# de tout export fait sans la cle privee. Refuser reviendrait a interdire a l'acheteur d'utiliser
# ses propres planches -- exactement ce que l'outil existe pour lui permettre.
#
# ⚠ LA CLE PUBLIQUE N'A RIEN A CACHER : elle ne sait que VERIFIER. La privee ne part jamais, et
# c'est la seule asymetrie qui compte -- un cloneur peut fabriquer des tilesets, il ne peut pas
# en fabriquer des signes.
extends RefCounted

## L'etat d'un tileset, en clair.
enum { ABSENT, VALIDE, INVALIDE }

## LA CLE PUBLIQUE DE SOLUTILES. Remplacee par `tools/make_key.gd` a la premiere paire.
## Vide tant qu'aucune paire n'existe : tout est alors « non signe », ce qui est vrai.
const PUBLIC_KEY: String = "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsX8/V2Zp0Kk6ueKeYzTe
hcteVbg7A65muGkh/DCPSjgsTRROg4Svp5X3zfHRChGZXfKNcI+ID9/rMNJ6HIDC
WIm8P+UL4AbvpQd3XaIRKvTMem6r4gZGTI83l+B7cMtswMLoJF2dHKnHYzrvYvnN
22IVzGcb3nCledVKZDb2USlrWh1AxZId9bHCW4+xHSxiZPUBoRpVxoHbuGlnjUpZ
2WGAuNewEDs2Z30HHZG6htjnSHU29vf6apbuB33FJ1caWGp07iFAWYzlk/cFQwXV
E0GtsRTbH56EhL+l+i3gvSOtsOUeQLBMFPWuVkiLLK1pZ1DXxCQtiBYPrMmEingY
HQIDAQAB
-----END PUBLIC KEY-----"


## LE CONDENSE — ⚠ COPIE EXACTE DE `core/signing.gd`, et la suite compare les deux.
##
## L'ordre et les separateurs font partie du contrat : deux implementations qui les melangent
## autrement calculent deux condenses differents pour la meme planche, et le sceau parait faux
## alors que tout est juste. Meme raison que la copie de la regle de pose -- le plugin est SEUL
## chez l'acheteur, donc il porte sa copie, et on PROUVE que les deux disent la meme chose.
static func digest(sheet: PackedByteArray, table: String, version: int) -> PackedByteArray:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(("solutiles-seal %d\n" % version).to_utf8_buffer())
	context.update(sheet)
	context.update("\n".to_utf8_buffer())
	context.update(table.to_utf8_buffer())
	return context.finish()


## La table des cases telle qu'elle entre dans le condense : une ligne par tuile, TRIEE.
static func table_of(slots: Dictionary, ranks: Dictionary) -> String:
	var order: Array[int] = []
	for tile: Variant in slots.keys():
		order.append(int(tile))
	order.sort()
	var lines: PackedStringArray = PackedStringArray()
	for tile2: int in order:
		lines.append("%d:%d" % [tile2, int(ranks.get(tile2, 0))])
	return "\n".join(lines)


## LE VERDICT. Rend `ABSENT`, `VALIDE` ou `INVALIDE`.
static func judge(sheet: PackedByteArray, table: String, version: int, seal: String) -> int:
	if seal.is_empty() or PUBLIC_KEY.is_empty():
		return ABSENT
	var key: CryptoKey = CryptoKey.new()
	if key.load_from_string(PUBLIC_KEY, true) != OK:
		return ABSENT
	var raw: PackedByteArray = Marshalls.base64_to_raw(seal)
	if raw.is_empty():
		return INVALIDE
	var crypto: Crypto = Crypto.new()
	return VALIDE if crypto.verify(HashingContext.HASH_SHA256,
			digest(sheet, table, version), raw, key) else INVALIDE


## Ce qu'on montre a l'acheteur. ⚠ EN CLAIR ET SANS DRAMATISER : « non signe » decrit un etat
## normal, « sceau invalide » decrit un fichier qui a bouge depuis sa signature.
static func say(verdict: int) -> String:
	match verdict:
		VALIDE:
			return "tileset signe SoluTiles"
		INVALIDE:
			return "sceau invalide : la planche ou la table a change depuis la signature"
		_:
			return "tileset non signe"
