# SoluPaint

> Posez votre monde avec les tuiles que vous avez peintes.

Plugin Godot 4 qui consomme un tileset exporté par **SoluTiles**. Vous lui donnez un
relief — une hauteur par case — et il pose tout : les sommets de chaque étage, puis les
faces de falaise.

## Installation

Le bouton **« Installer le plugin Godot »** d'SoluTiles copie ce dossier dans le projet
de votre choix. À la main, c'est un simple copier-coller de `addons/solupaint/` à la
racine du projet.

Ensuite : **Projet → Paramètres du projet → Extensions**, et cochez `SoluPaint`.

Un bouton **SoluPaint** apparaît aussitôt **dans la barre du haut**, à côté des menus.
Vous n'avez rien à chercher.

## Usage

1. Ouvrez une scène, puis cliquez le bouton **SoluPaint** de la barre du haut. Il
   **ouvre le panneau**, pose un nœud **`SoluPaintWorld`** dans la scène et vous y emmène — et s'il y en a déjà un, il
   vous y emmène sans en créer un second. (À la main : « Ajouter un nœud » →
   `SoluPaintWorld`.)

⚠ **Vous n'avez pas de manifeste à pointer.** Le panneau **cherche les tilesets SoluTiles
du projet** et les propose ; s'il n'y en a qu'un, il le pose sans rien demander. Le bouton
« Installer le plugin Godot » d'SoluTiles en dépose d'ailleurs un dans `solutiles/` en
même temps que l'extension — votre tileset s'il est complet, son **essai** sinon.
2. Choisissez le **tileset** dans le panneau, si le projet en contient plusieurs. Les deux
   planches sont lues à côté du manifeste, sous les noms qu'il donne.
3. Remplissez `heights` — un dictionnaire `Vector2i → étage`, de **0 à 9**.

### ⚠ Une case absente est HORS DU MONDE, pas à la plaine

C'est la règle qui donne son sol au monde, et elle se retient en une phrase : **la plaine
se déclare**. Une case à l'étage 0 est du sol — elle porte une tuile, et une falaise là
où elle borde le vide. Une case absente n'est rien : c'est le bord du monde.

Sans cette distinction le plugin ne saurait pas où le sol s'arrête, et ne pourrait poser
aucun étage 0.

### Le pinceau

Le panneau **SoluPaint** s'ouvre à droite dès que l'extension est cochée.

1. Choisissez un **étage** — `0` est du sol, `1` à `9` les plateaux, **`Vide`** retire la
   case du monde.
2. **Armez le pinceau.**
3. **Clic gauche** pose l'étage choisi, **clic droit** retire la case. Le glisser peint une
   ligne continue, sans trous.

⚠ **Rien ne refuse en silence.** Chaque fois qu'une action ne peut pas aboutir — armer le
pinceau sans scène, sans monde, sans tileset, ou avec un tileset illisible — une fenêtre
dit **ce qui manque** et **ce qu'il faut faire**, dans cet ordre. Un bouton qui se relève
tout seul sans rien dire laisse croire à une panne.

⚠ **Le pinceau s'arme à la main, exprès.** Tant qu'il est armé, la souris peint la carte
au lieu de déplacer les nœuds. Un outil qui intercepte la souris sans qu'on l'ait demandé
fait perdre le glisser-déposer, et on met dix minutes à comprendre pourquoi l'éditeur ne
répond plus.

⚠ **Ctrl+Z défait un TRAIT, pas une case.** L'annulation se pose au relâchement et d'un
seul bloc : défaire un trait de cent cases en cent Ctrl+Z n'est ce que personne n'attend
d'un pinceau.

### Par script

Le relief reste un simple dictionnaire, et tout est accessible :

```gdscript
@onready var monde: Node2D = $SoluPaintWorld

func _ready() -> void:
	monde.fill(Vector2i(0, 0), Vector2i(31, 23), 0)     # du sol, d'abord
	monde.fill(Vector2i(6, 5), Vector2i(18, 12), 1)     # un plateau
	monde.fill(Vector2i(9, 6), Vector2i(14, 9), 2)      # un second, dessus
	monde.set_level(Vector2i(24, 8), 1)                 # un îlot
	monde.clear_cell(Vector2i(0, 0))                    # et un trou dans le monde
```

| appel | ce qu'il fait |
|---|---|
| `fill(de, a, etage)` | pose un rectangle d'un seul étage |
| `set_level(case, etage)` | change une case. **0 est un étage**, pas un effacement |
| `clear_cell(case)` | retire la case du monde : elle redevient du hors-monde |
| `level_at(case)` | l'étage d'une case, ou `-1` si elle est hors du monde |
| `cell_at(point)` | la case sous un point local |

⚠ **Commencez toujours par du sol.** Un monde où seuls les plateaux sont déclarés n'a
rien à border : les plateaux flottent, et leurs falaises tombent dans le vide sans poser
leur pied. C'est exact, mais ce n'est probablement pas ce que vous vouliez voir.

## Ce qu'il garantit

- **Rien n'est fabriqué.** Aucune composition, aucun miroir, aucune rotation. Chaque case
  va chercher dans la planche la tuile que la règle désigne.
- **La règle est celle du manifeste**, pas une réinterprétation. Elle est vérifiée contre
  le noyau d'SoluTiles sur des milliers de reliefs tirés au sort : une seule case qui
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
