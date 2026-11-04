# Les visuels de vente — script de tournage

> ⚠ **Pas un teaser. Une démonstration.** Un teaser est une forme de marketing de *jeu* :
> ambiance, mystère, « coming soon ». Le dev qui regarde ne se demande pas ce que ça
> évoque, il se demande **si ça résout son problème**. On lui montre l'écran, on ne lui
> vend pas une émotion.
>
> ⚠ **Et ça ne contredit pas le lancement discret** : la vidéo est un *actif*, pas un
> *événement*. Ce qu'on garde pour plus tard, c'est le gros push coordonné — pas le
> fichier. La page itch a besoin de son GIF dès le premier jour.

---

## 1. LE GIF — l'actif le plus important du produit

**8 à 12 secondes, en boucle, muet, sans curseur qui cherche.** Il va en première position
sur la page itch, en tête du post r/godot, et en natif sur X et Bluesky.

**Le plan, et il n'y en a qu'un :**

> Un seul trait de crayon traverse quelques cases — et **une dizaine d'autres cases
> ailleurs sur le guide se remplissent en même temps**, pendant que la jauge monte.

⚠ **C'est le seul plan que personne d'autre ne peut tourner.** Un générateur de tileset
montre un résultat ; MarchingSquares montre **le geste qui remplit dix endroits à la fois**, parce
que ce sont la même tuile. Tout le reste du produit se déduit de là.

**À préparer avant d'enregistrer :**

- [ ] **Repérer la case qui a le plus de jumelles.** Le survol les allume en cyan — il
      suffit de balader le curseur et de noter celle qui en allume le plus. Le GIF vaut
      ce que vaut ce nombre.
- [ ] Zoom réglé pour qu'on voie **à la fois** la case peinte et ses jumelles. Si elles
      sont hors cadre, l'effet est perdu et le GIF ne dit rien.
- [ ] Les jauges visibles dans le cadre (coin haut droit). C'est elles qui prouvent que
      quelque chose *avance*.
- [ ] Couper les deux premières secondes au montage : on entre **pendant** le geste.

---

## 2. LA VIDÉO — 60 secondes, cinq temps

| Temps | Durée | Ce qu'on voit |
|---|---|---|
| **1. Le problème** | 0–8 s | Une carte de jeu, et **un coin qui n'a pas de tuile** — un trou, une jonction qui casse. ⚠ Le seul moment où l'on montre autre chose que MarchingSquares. |
| **2. Le guide** | 8–20 s | L'écran s'ouvre. Le guide est déjà là, entier. « Every case that can occur is already in front of you. » |
| **3. On peint** | 20–35 s | Le geste, les jumelles, la jauge. **C'est le GIF, en plus long.** |
| **4. L'export** | 35–45 s | Le bouton qui s'active quand il ne manque plus rien. La planche apparaît. |
| **5. Dans Godot** | 45–60 s | La room de Test ou le plugin : on pose du relief, **il se rend avec les tuiles qu'on vient de peindre**. Fin sur le nom et le prix. |

⚠ **Le temps 5 est celui qui conclut la vente**, et c'est le plus facile à rater : il faut
qu'on **reconnaisse** les tuiles peintes au temps 3. Peindre quelque chose de visuellement
distinctif au temps 3 — une couleur franche, un motif reconnaissable — pour que l'œil fasse
le lien sans qu'on ait à l'expliquer.

**Ce qu'on ne met pas :** musique, intro animée, logo qui tourne, voix off, transitions.
Un carton de texte tenu 2 s vaut mieux qu'une narration. La vidéo doit rester lisible **sans
le son**, parce que c'est comme ça qu'elle sera regardée.

---

## 3. La capture, en pratique

- **ShareX** (gratuit, Windows) fait le GIF **et** le MP4. Alternative : l'enregistreur de
  jeu de Windows (`Win+G`) pour le MP4 seul.
- **Fenêtre à 1280×720 exactement** pendant le tournage — pas en plein écran 1920. Le
  détail du pixel art se perd au redimensionnement de la plateforme, et un GIF 1920 pèse
  trop lourd pour itch.
- ⚠ **Le zoom se cale sur un multiple entier de la résolution** (c'est déjà la règle du
  logiciel) : à échelle libre, le dessin *bave* à l'intérieur des tuiles pendant que leur
  bordure reste franche, et la vidéo montrerait un défaut qui n'existe pas.
- **30 fps suffit.** Un GIF à 60 fps double le poids sans rien montrer de plus.
- Masquer la grille sur les derniers plans (case « Hide the grid ») : on juge le **rendu**,
  et la grille dit « outil » là où on veut dire « résultat ».

---

## 4. ⚠ CE QUI BLOQUE LE TOURNAGE AUJOURD'HUI

Ce n'est pas la stratégie, c'est l'état de l'écran :

- **5 tuiles sont encore vierges** dans `low_res.solutiles` (18/20 surfaces, 37/40
  falaises) — donc l'export est grisé, et le temps 4 est infilmable ;
- **le guide est en cours de rebâtissage** et a déjà changé de taille dans la nuit ;
- **`PIED 21 au ras`** n'a pas de témoin, d'où 14 échecs en cascade.

**Donc : le script se prépare maintenant, le repérage des jumelles aussi. L'enregistrement
attend le rebâtissage et la peinture.** Filmer avant, c'est refilmer.

---

## 5. Ce que la vidéo sert, et combien de fois

Une seule production, **cinq usages** — c'est ce qui justifie d'y passer une soirée :

1. le GIF en tête de la page itch ;
2. le post r/godot (le GIF, pas le lien) ;
3. `#screenshotsaturday` sur X et Bluesky ;
4. **YouTube**, titré pour la recherche (`Godot autotile tileset from your own art`) —
   le seul actif **durable** : il se trouve encore dans six mois ;
5. le lancement bruyant, plus tard, quand l'eau et les trous seront dedans.
