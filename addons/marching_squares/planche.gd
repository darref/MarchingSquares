@tool
extends RefCounted

## LA PLANCHE LIVRÉE, LUE — le PNG et le manifeste qu'exporte MarchingSquares (`core/coins/travail.gd`, v2) :
## la taille d'une tuile, la TABLE (clé de pose « sorte:c:cv » → archétype) et, pour chaque (archétype, matière), ses
## images (la base puis les variantes), leur place dans la planche et leurs poids. Rien d'autre à savoir : les poses se
## calculent par `modele.gd`, la variante se tire par `Modele.tirage`.

const FORMAT := "marching-squares-coins-planche"

var tuile := 16
var texture: Texture2D
var table := {}
## « n:m » → {"poids": PackedInt32Array, "regions": Array[Rect2]}
var familles := {}
var erreur := ""


## Lit le manifeste `chemin` (JSON) et la planche qu'il nomme, posée à côté de lui. Rend faux (et `erreur`) sinon.
func lire(chemin: String) -> bool:
	erreur = ""
	if not FileAccess.file_exists(chemin):
		erreur = "No tileset manifest at %s" % chemin
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(chemin))
	if not (d is Dictionary) or d.get("format") != FORMAT:
		erreur = "%s is not a MarchingSquares tileset" % chemin
		return false
	if int(d.get("version", 0)) > 2:
		erreur = "This tileset was exported by a newer MarchingSquares (manifest v%d)" % int(d.version)
		return false
	tuile = int(d.tuile)
	table.clear()
	for k: String in d.table:
		table[k] = int(d.table[k])
	familles.clear()
	for e: Dictionary in d.images:
		var cle := "%d:%d" % [int(e.archetype), int(e.matiere)]
		if not familles.has(cle):
			familles[cle] = {"poids": PackedInt32Array(), "regions": []}
		var f: Dictionary = familles[cle]
		var k := int(e.variante)
		while (f.poids as PackedInt32Array).size() <= k:
			f.poids.append(0)
			f.regions.append(Rect2())
		f.poids[k] = int(e.poids)
		f.regions[k] = Rect2(int(e.colonne) * tuile, int(e.rangee) * tuile, tuile, tuile)
	var png := chemin.get_base_dir().path_join(str(d.get("planche", "marching_squares_planche.png")))
	texture = null
	if png.begins_with("res://") and ResourceLoader.exists(png):
		texture = load(png)
	if texture == null:
		var img := Image.load_from_file(png)
		if img != null:
			texture = ImageTexture.create_from_image(img)
	if texture == null:
		erreur = "Tileset image missing: %s" % png
		return false
	return true


## La famille d'images d'un archétype dans une matière, ou {} (une matière qui n'a pas été livrée ne se pose pas).
func famille(n: int, m: int) -> Dictionary:
	return familles.get("%d:%d" % [n, m], {})
