extends SceneTree

## LA PAIRE DE CLES DE SIGNATURE — fabriquee une fois, la privee gardee HORS du depot.
##
##     godot --headless --path . --script res://tools/make_key.gd -- <dossier hors depot>
##
## Elle ecrit deux fichiers :
##   `solutiles_prive.pem`  ⚠ NE JAMAIS COMMITER, NE JAMAIS LIVRER. C'est elle, et elle seule,
##                          qui rend un tileset signable. Un cloneur peut fabriquer des
##                          tilesets ; sans ce fichier il ne peut pas en fabriquer des SIGNES.
##   `solutiles_public.pem` la moitie qui part avec le plugin, et qui n'a rien a cacher : elle
##                          ne sert qu'a VERIFIER.
##
## ⚠ LE DOSSIER EST DEMANDE, PAS DEVINE, et le dossier par defaut est hors du depot. Ecrire une
## cle privee dans un arbre suivi par git est le genre de faute qu'on ne remarque qu'au push --
## c'est-a-dire trop tard, l'historique la garde.
##
## Ensuite, pour signer : `SOLUTILES_KEY=<chemin du .pem prive>` dans l'environnement de
## l'export. Sans elle, tout sort NON SIGNE et le dit.

const PRIVATE_NAME: String = "solutiles_prive.pem"
const PUBLIC_NAME: String = "solutiles_public.pem"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "user://cles"
	if folder.begins_with("res://"):
		printerr("make_key : refuse d'ecrire une cle privee DANS le depot (%s)." % folder)
		printerr("           Donnez un dossier hors de l'arbre suivi par git.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(folder) != OK \
			and not DirAccess.dir_exists_absolute(folder):
		printerr("make_key : dossier impossible a creer : %s" % folder)
		quit(1)
		return

	var private_path: String = folder.path_join(PRIVATE_NAME)
	# ⚠ ON N'ECRASE PAS UNE CLE EXISTANTE. La remplacer invaliderait d'un coup toutes les
	# signatures deja livrees, et rien ne le dirait avant qu'un acheteur ne s'en plaigne.
	if FileAccess.file_exists(private_path):
		printerr("make_key : une cle existe deja ici. La remplacer invaliderait toutes les")
		printerr("           signatures deja livrees. Effacez-la a la main si c'est voulu.")
		quit(1)
		return

	var crypto: Crypto = Crypto.new()
	var key: CryptoKey = crypto.generate_rsa(2048)
	if key.save(private_path, false) != OK:
		printerr("make_key : ecriture impossible de la cle privee.")
		quit(1)
		return
	var public_path: String = folder.path_join(PUBLIC_NAME)
	if key.save(public_path, true) != OK:
		printerr("make_key : ecriture impossible de la cle publique.")
		quit(1)
		return

	print("cle privee  : %s" % ProjectSettings.globalize_path(private_path))
	print("cle publique: %s" % ProjectSettings.globalize_path(public_path))
	print("")
	print("A FAIRE, dans cet ordre :")
	print("  1. gardez la privee hors du depot, et sauvegardez-la ailleurs qu'ici ;")
	print("  2. copiez le CONTENU de la publique dans addons/solupaint/signature.gd ;")
	print("  3. pour signer un export : SOLUTILES_KEY=%s"
			% ProjectSettings.globalize_path(private_path))
	quit(0)
