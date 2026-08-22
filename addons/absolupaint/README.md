# AbsoluPaint

> Posez votre monde avec les tuiles que vous avez peintes.

Plugin Godot 4 qui consomme un tileset exporté par **AbsoluTiles**. Vous lui donnez un
relief — une hauteur par case — et il pose tout : les sommets de chaque étage, puis les
faces de falaise.

## Installation

Le bouton **« Installer le plugin Godot »** d'AbsoluTiles copie ce dossier dans le projet
de votre choix. À la main, c'est un simple copier-coller de `addons/absolupaint/` à la
racine du projet.

Ensuite : **Projet → Paramètres du projet → Extensions**, et cochez `AbsoluPaint`.

## Usage

1. Ajoutez un nœud **`AbsoluPaintWorld`** à votre scène.
2. Dans l'inspecteur, pointez **`Manifest Path`** sur le `<nom>_tileset.txt` livré avec vos
   deux planches. Les images sont lues à côté de lui, sous les noms qu'il donne.
3. Remplissez `heights` — un dictionnaire `Vector2i → étage`, de 1 à 9. Une case absente
   est à la plaine.

Depuis le code :

```gdscript
$AbsoluPaintWorld.set_level(Vector2i(4, 3), 2)
```

## Ce qu'il garantit

- **Rien n'est fabriqué.** Aucune composition, aucun miroir, aucune rotation. Chaque case
  va chercher dans la planche la tuile que la règle désigne.
- **La règle est celle du manifeste**, pas une réinterprétation. Elle est vérifiée contre
  le noyau d'AbsoluTiles sur des milliers de reliefs tirés au sort : une seule case qui
  divergerait ferait échouer la suite de tests.
- **Il refuse plutôt que de deviner.** Un manifeste d'une version qu'il ne sait pas lire,
  des constantes de falaise qui ne sont pas les siennes, une planche à qui il manque une
  case : il le dit et ne pose rien.

## Ce qu'il ne fait pas encore

- **Pas de sol.** La plaine n'est pas une tuile du tileset, et le modèle ne distingue pas
  encore « case à l'étage 0 » de « case hors du monde ». Posez votre sol sur sa propre
  couche.
- **Pas d'outil de peinture dans l'éditeur.** On remplit `heights` par l'inspecteur ou par
  script. Le pinceau viendra.
- **Pas de collision, pas de navigation.** Les couches sont des `TileMapLayer` ordinaires :
  ce que vous leur ajoutez vous appartient.
