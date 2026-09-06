# MARKET.md — la stratégie de mise en vente

> **Ce fichier est un document de travail, pas une décision arrêtée.** Il porte ce qui est
> tranché, ce qui est proposé, et ce qui reste à discuter. On l'amende au fil des séances.
> Il ne gouverne rien dans le code : `PLAN.md` garde l'ordre du travail, `CLAUDE.md` le modèle.

**Objectif** : encaisser vite, sans budget, sans brûler la seule cartouche de lancement.
**Contrainte** : Steam est hors de portée aujourd'hui (Steam Direct = 100 $ à avancer par
produit, remboursés seulement après 1 000 $ de ventes). Donc **itch.io**, qui ne coûte rien.

---

## 0. LES BLOQUANTS DE LA MISE EN VENTE

Trouvés le 06/09, ni dans `PLAN.md` ni dans `CLAUDE.md`. Aucun ne se règle en peignant.
**Les deux sont faits.** Restent l'icône et l'essai sur machine vierge.

### ✅ A. LE BINAIRE EXISTE — fait le 06/09, 23 h

`export_presets.cfg` écrit (preset **Windows Desktop**, x86_64, `.pck` embarqué : **un seul
fichier**). Export lancé, **119 Mo**, dont **105 Mo de template Godot** — le projet n'ajoute que
14 Mo, et 13,8 d'entre eux sont le splash. Rien à optimiser.

**Le binaire démarre** : lancé `--headless --quit-after 300`, il boote, tourne 300 images et sort
en **code 0**, sans une erreur.

⚠ **TROIS PIÈGES ÉVITÉS, ET AUCUN N'AURAIT FAIT D'ERREUR :**

1. **Les guides ne seraient pas partis.** `core/mask_io.gd:44` les lit par `FileAccess`, pas par
   `load()` — donc le scanner de dépendances de Godot ne les voit pas. Sans `include_filter`,
   l'acheteur lançait un logiciel **sans un seul guide**. Même chose pour `examples/*.solutiles`.
   Vérifié présents dans le paquet.
2. **Le plugin serait parti en bytecode.** Godot 4.4+ compile le GDScript en jetons binaires à
   l'export (`script_export_mode`, **2 par défaut**). Or `PluginInstall` recopie
   `res://addons/solupaint/*.gd` **en octets** chez l'acheteur : il aurait reçu des fichiers
   illisibles, contre la charte (« il part en GDScript en clair »). Forcé à **`0` = texte**,
   vérifié dans le binaire.
3. **Mes documents internes seraient partis avec.** `MARKET.md` (ce fichier — prix, stratégie),
   `CLAUDE.md`, `PLAN.md`, `ARCHIVE.md`. Exclus, vérifiés absents. `tools/`, `proof/` et `tests/`
   aussi — dont `tools/make_key.gd`.

✅ **Et une fausse alerte, vérifiée dans les deux sens** : un `-----BEGIN RSA PRIVATE KEY-----`
apparaît dans le binaire. Ce n'est **pas** une clé : le marqueur est déjà dans le template Godot
nu (littéraux du parseur PEM de mbedtls), aucun `.pem` n'existe dans le dépôt, et `.gitignore:24`
les exclut. **Un contrôle de sécurité qui ne vérifie pas son propre positif est un contrôle qui
crie au loup.**

**RESTE SUR CE POINT :**

- [x] ✅ **L'ICÔNE — faite.** Décision utilisateur : **la même que le plugin**, donc une seule
      identité pour SoluTiles, SoluPaint et le futur plugin Unity. `tools/make_icon.gd`
      **rastérise** `addons/solupaint/icon.svg` (le plateau vu de dessus, sa falaise, et le coin
      rentrant qui dit « autotile ») en six tailles ; un `.ico` multi-résolution est empaqueté
      sans dépendance externe. ⚠ **On rastérise le vecteur à chaque taille, on n'agrandit pas un
      PNG** — c'est exactement ce que le produit refuse de faire aux tuiles. Vérifié : les
      **6/6 images sont dans le binaire**.
- [ ] ⚠ **Reste UNE ligne, dans un fichier tenu par l'autre session** : `config/icon="res://icon.png"`
      dans `[application]`. Elle donne l'icône de la **fenêtre** (barre des tâches pendant que le
      logiciel tourne) ; celle de l'exe est déjà posée. Demandée au pair.
- [ ] **Essai sur une machine SANS Godot installé** — le démarrage headless ici ne le remplace pas.
- [ ] Le ZIP final : `SoluTiles.exe` + `README.txt` + `LICENSE.txt`. ⚠ **Pas besoin d'y mettre
      `addons/solupaint/`** : le bouton « Install the Godot plugin » l'écrit depuis le paquet.

### ✅ B. L'INTERFACE EST PASSÉE À L'ANGLAIS — fait le 06/09, 22 h

L'UI était 100 % en français (aucun `tr()`, aucune locale, manuel de 304 lignes). C'est fait :

| Fichier | Chaînes | État |
|---|---|---|
| `ui/editor.tscn` — la barre, toutes les infobulles | 71 | ✅ |
| `ui/editor.gd` — bandeau, dialogues, messages d'export | 106 | ✅ |
| `ui/manual.gd` — le mode d'emploi à trois niveaux | 122 | ✅ |
| `ui/rooms.gd`, `ui/test_room.gd` | 6 | ✅ |
| `addons/solupaint/` — plugin, dock, world, tileset, signature | 61 | ✅ |
| `addons/solupaint/rules.gd`, `manifest.gd` | ~22 | ⏳ tenus par l'autre session |

**Total : 366 chaînes.** Vérifié par `tools/check_english_pass.gd` — **0 échec de compilation, 0 ligne
de français restante**. ⚠ **`can_instantiate()`, pas `load()`** : un script dont l'analyse échoue
rend quand même une ressource, vide de ses fonctions, et rien ne le signale.

⚠ **Décision prise : l'anglais est la SOURCE, pas une traduction.** Pas de `tr()` avec le français
en clé — une clé française se casse **en silence** au moindre retouche du texte source, et c'est
exactement le défaut que la charte refuse. Le français pourra revenir plus tard comme
*traduction depuis l'anglais* : le travail sera **additif**, pas à refaire.

⚠ **Les commentaires du code restent en français**, et c'est voulu : ils ne sont pas vendus.

**Reste à faire** : les deux fichiers du plugin tenus par l'autre session, dès que son correctif
terrain est posé. Ce sont des messages de refus — ils partent chez l'acheteur, donc ils comptent.

### Et le solde du terrain (déjà au PLAN, rappelé ici pour la case à cocher)

- [ ] le **coin haut du cisaillement** ;
- [ ] **`PIED 21 au ras`** ;
- [ ] la tuile **`132095`** — ⚠ **le seul défaut disqualifiant** : le pinceau livré l'atteint, la
      planche ne la porte pas, donc l'acheteur pose une case et **il a un trou dans sa carte** ;
- [ ] `examples/low_res.solutiles` complet (les tuiles restantes) — c'est la démo, pas un bonus ;
- [ ] `README.md` réécrit : il annonce encore « blob 47 tuiles » et « aucune UI, aucun rendu ».
- [ ] ⚠ **`ui/manual.gd` niveau 2 décrit l'ANCIEN modèle** : « deux planches séparées »,
      « à cheval », « 47 index », et « le manifeste porte la règle de pose » (faux depuis la
      décision du 04/09). Traduit fidèlement, **pas corrigé** : c'est du contenu produit, pas
      de la traduction. À rejuger avant de vendre — c'est l'onboarding de l'acheteur.

---

## 0 bis. LA BARRIÈRE DE MISE EN VENTE — ce qu'un humain doit avoir VU

⚠ **Écrit le 06/09 après un rappel de l'utilisateur, et la leçon est la mienne** : j'ai déclaré
la passe anglaise « faite » sur la foi de trois preuves automatiques — ça compile, il ne reste
aucune chaîne française, le binaire démarre. **La première capture d'écran a montré « Paysage »
en clair dans la liste déroulante.** Mon balayage ne couvrait que `ui/` et `addons/` ; les
libellés vivaient dans `core/`. *Un contrôle qui ne mesure pas ce qu'il prétend mesurer est pire
que pas de contrôle* — et aucune de mes trois preuves n'était fausse, elles ne prouvaient
simplement pas ce que je leur faisais dire.

**Rien ne part sans ces cases, et elles se cochent à l'œil, pas au banc :**

- [x] **L'écran, en anglais** — capturé (`build/vue/01_ecran.png`), relu par l'utilisateur :
      rien de tronqué, la barre n'a pas gonflé. ⚠ C'est ce qui a trouvé « Paysage ».
- [x] **Le mode d'emploi, ses trois onglets** — capturé (`build/vue/02_manuel.png`).
- [x] ✅ **LA ROOM DE TEST — validée en image le 06/09** (`build/vue/05_libelle.png`) : le
      relief posé au tampon 3×3, rendu avec les tuiles peintes à la main, par
      `addons/solupaint/rules.gd`. **C'est le contrôle croisé vivant sur la copie qui part chez
      l'acheteur.** ⚠ **Ma première tentative avait photographié la mauvaise room en silence** —
      j'avais tapé `test` là où le mot-clé était `essai`, et l'argument inconnu était *avalé*.
      Corrigé dans les deux sens (les deux mots acceptés, tout argument inconnu signalé).
      ⚠ **Et mon diagnostic était faux** (j'accusais un `await` manquant) : le carnet dit qu'un
      autre agent peut se tromper, et qu'on vérifie — ici c'est moi qui me trompais.
      ⚠ **À savoir** : sans travail chargé, la room rend une **aire vide** (« 0 tiles placed,
      68 placement(s) with no drawing »). Ce n'est pas une panne, mais qui l'ouvre en premier
      voit une boîte vide.
- [ ] ⚠ **L'EXEMPLE PEINT, VALIDÉ À L'ŒIL** (exigence utilisateur du 06/09, **précisée le même
      soir**) — et c'est **le trait peint qu'on juge, PAS le fond du guide**. La distinction est
      celle du carnet : *le dessin calculé est la spécification, il a donc toujours l'air juste ;
      un exemple est du vrai trait remonté, et c'est la seule vue où l'on voit ce que l'outil
      rend vraiment.* Le cisaillement du massif 21 a été relevé comme ça, et par aucun autre
      moyen.
      ⚠ **ORDRE IMPOSÉ, ET IL NE SE NÉGOCIE PAS** : les chasses finies → tout rebâti → **puis**
      la peinture → **puis** l'œil. Faire regarder l'utilisateur avant, c'est dépenser la seule
      ressource rare de la nuit sur un artefact qui va bouger.
      L'exemple sert **trois fois** : fond par défaut, démo de l'addon, visuels de vente.
- [ ] **La suite au vert.** Aujourd'hui **728 vérifications, 15 échecs** — 13 du solde terrain
      (deux témoins manquants), **2 de moi** (`tests/run.gd:281` épingle le libellé « Damier »
      que la passe anglaise a renommé ; l'identifiant `massifs`, lui, n'a pas bougé et son test
      passe — la séparation du carnet a fonctionné).
- [ ] **Le binaire lancé sur une machine qui n'est pas celle-ci** (voir ci-dessous).
- [ ] **Une session de peinture réelle, à la main, du début à l'export.** Personne n'a encore
      fait passer le logiciel anglais par le geste complet.

### ✅ CE QUE LA VÉRIFICATION HUMAINE A TROUVÉ, ET QU'AUCUN BANC NE VOYAIT

Trois défauts, **trois trouvés par l'œil, zéro par les bancs** — à garder en tête pour la suite :

1. **« Paysage » en clair dans la liste déroulante.** Mon balayage ne couvrait que `ui/` et
   `addons/` ; les libellés vivent dans `core/modes.gd`, `examples.gd`, `families.gd`.
2. **« Specimen boar »** — le libellé anglais **tronqué** dans la liste. Quatorze caractères ne
   rentrent pas. C'est *« un libellé qui s'allonge impose sa largeur à toute la barre »* dans sa
   variante coupée. Raccourci en « Specimens » (9, comme « Landscape »).
3. **La room de Test photographiée à la mauvaise pièce**, sans une erreur.

⚠ **La leçon, et elle vaut pour tout ce qui reste** : les bancs prouvent que le **modèle** est
juste ; ils ne regardent pas l'**écran**. Toute passe qui touche à du texte visible se termine
par une capture, pas par un test vert.

### ✅ LE RENDU PASSE EN `gl_compatibility` — décidé le 06/09

Vulkan (`forward_plus`, le défaut de Godot 4) ferme les vieux GPU intégrés, la plupart des
machines virtuelles et le **Bureau à distance**, sans rien apporter à un éditeur de pixel art 2D.
⚠ **Vérifié sans risque avant de le demander** : zéro `.gdshader`, et aucun usage de
`ShaderMaterial`, `Viewport`, `GPUParticles` ou `WorldEnvironment` dans tout le dépôt — le dessin
calculé se fait sur CPU dans `render/`. Ça élargit le vivier d'acheteurs, **et ça rend le test en
VM enfin significatif** : sous Vulkan, un échec en VM était une fausse alerte impossible à lire.

### ⚠ LA MACHINE VIRTUELLE SUFFIT-ELLE ? — non, elle couvre une moitié

**Ce qu'une VM prouve, et c'est l'essentiel de ce qu'on craint** : que le `.exe` tourne sans
Godot installé, sans les *export templates*, sans les DLL de développement — et que les guides
et les exemples sont bien dans le paquet. C'est **90 % du risque d'emballage**, et ça vaut
largement le déplacement. C'est aussi le seul endroit où l'on voit **l'avertissement SmartScreen**
tel que l'acheteur le verra (exe non signé, téléchargé) — à voir une fois avant de vendre.

**Ce qu'une VM ne prouve pas : le graphique.** `project.godot` ne déclare aucun
`rendering/renderer/rendering_method`, donc SoluTiles tourne en **forward_plus, c'est-à-dire
Vulkan**. Or la plupart des VM (VirtualBox, VMware, Hyper-V) n'ont **pas de Vulkan** : un échec
là-bas peut être une **fausse alerte** qui ne concerne aucun acheteur, et un succès sous
rendu logiciel ne dit rien d'un vieux GPU intégré.

⚠ **Et c'est une décision produit qui vaut de l'argent** : pour un éditeur de **pixel art 2D**,
Vulkan n'apporte rien et ferme des portes — vieux GPU intégrés, machines virtuelles, **Bureau à
distance**. `gl_compatibility` tournerait partout. Une ligne dans `project.godot`, à trancher
avant de vendre, et à tester en VM juste après (là, la VM devient un vrai test).

**Donc : VM pour l'emballage, plus deux ou trois vraies machines pour le reste.** Trois personnes
qui lancent l'exe et disent « ça s'ouvre » valent tous les bancs du monde sur ce point précis.

---

## 1. LA STRATÉGIE, EN UNE PAGE

**Le principe : deux événements séparés.** On peut encaisser plusieurs fois ; on ne peut se faire
découvrir qu'une seule.

1. **MAINTENANT — encaisser en silence.** Page itch payante, accès anticipé, prix bas, quelques
   posts ciblés. Objectif : premières ventes, premiers retours, premiers acheteurs à qui parler.
2. **PLUS TARD — le lancement bruyant.** Quand l'eau et les trous sont dedans : presse, gros posts,
   Steam (les 100 $ seront payés par les ventes itch), Asset Library, vidéo longue.

**Les trois règles qui protègent ça :**

- ⚠ **Aucune date, aucune liste nominative de ce qui vient.** Un roadmap annoncé fabrique une
  **raison d'attendre**, et fait payer une seule fois deux versions de travail.
- ⚠ **Le prix ne descend jamais, il monte.** C'est le mécanisme qui neutralise l'attente : attendre
  coûte de l'argent. Écrit noir sur blanc sur la page.
- ⚠ **Dire ce qui n'y est pas.** Pas comme une promesse (« bientôt l'eau ») mais comme un
  **périmètre** (« aujourd'hui : le terrain, et il est complet et prouvé sur ce périmètre »).
  C'est la règle 4 de la charte appliquée à la vente, et ça vaut moins de remboursements.

---

## 2. CE QU'ON VEND

### La phrase

Le `README` la tient déjà, et elle est bonne :

> **Paint one landscape. Every edge case covered.**
> *No pixel you didn't paint.*

### L'accroche longue (à mettre en haut de la page, sous le GIF)

> Making an autotile tileset by hand is not hard because of the drawing.
> It's hard because **you don't know what to draw** — and you find out three months later,
> when one corner in your map has no tile for it.
>
> SoluTiles gives you a landscape to paint over. Paint it, and you have a complete autotile
> tileset — **proven** complete, not promised — plus the Godot plugin that places it.
> Nothing is mirrored, composited, or generated. Every pixel is yours.

### Le vrai différenciateur

Ce n'est **pas** « ça fait des tilesets ». C'est :

1. **La complétude prouvée** — l'outil sait *quelles* configurations existent, il te les montre
   toutes, et il **refuse** ce qu'il ne garantit pas. Personne d'autre ne vend ça.
2. **Zéro pixel fabriqué** — pas de miroir, pas de composition, pas d'IA. Ton art reste ton art,
   et il ne « bave » pas aux jonctions comme un tileset miroité.
3. **Le moteur part avec** — SoluPaint pose le monde chez l'acheteur, avec un contrôle croisé.

### À quoi on nous compare (et ce qu'il faut savoir)

Tilesetter (~25 $), Aseprite (~20 $), LDtk / Tiled / Pixelorama (gratuits). ⚠ **Le marché des
outils est ancré bas** : au-dessus de 30 € il faut *expliquer*, en dessous de 20 € on achète par
réflexe. Et **il y aura le commentaire « pourquoi pas gratuit / open source »** — préparer la
réponse une fois pour toutes (voir §6).

### Qui achète

Un dev **solo ou duo** faisant du **top-down avec des falaises** (Zelda-like, RPG, gestion), sur
**Godot 4**, qui a **son propre art** ou un artiste. Il n'a pas besoin d'eau le premier jour :
il a **plusieurs dizaines de tuiles à dessiner** devant lui, c'est des jours de travail. ⚠ **Mais il juge avant
d'acheter, pas après** — donc la charge de travail protège la rétention, jamais la conversion.

---

## 3. LE PRIX ET L'ACCÈS ANTICIPÉ (sans Steam)

**« Accès anticipé » n'est pas un bouton sur itch.io** — c'est trois choses qu'on pose à la main :

1. Le champ **Status** du projet réglé sur **« In development »** (itch l'affiche sur la page) ;
2. **Un encadré en haut de la description** qui dit le périmètre, le prix qui monte, et que les
   mises à jour sont incluses ;
3. **Des devlogs** qui prouvent que ça avance — c'est ce qui distingue un accès anticipé d'un
   produit abandonné, et c'est ce que l'acheteur cherche avant de sortir sa carte.

### L'encadré, prêt à coller

> **Early access.** SoluTiles builds **terrain** today: surfaces, cliffs, multi-level falls,
> overlapping massifs — a proven-complete tile set, with the Godot plugin that places them.
> Water, holes, caves and surface materials are being built. **No dates — I don't promise
> what I can't date.**
>
> **The early access price only goes up.** Buy now, keep every update forever.

### Le prix

| | Montant | Pourquoi |
|---|---|---|
| Accès anticipé (maintenant) | **19 €** | Sous la barre du réflexe, au-dessus du gadget. |
| Version 1.0 (eau + trous) | ~**29–39 €** | À décider quand le périmètre sera là. |

⚠ **Point n°1 à discuter.** L'argument pour **15 €** : achat d'impulsion, volume, plus de retours.
L'argument pour **29 €** : les acheteurs d'outils pros ne sont pas élastiques à ces montants, et
35 ventes valent mieux que 70. Mon avis : **19 €**, parce qu'on vend un périmètre partiel et que le
prix doit pouvoir monter deux fois.

### ⚠ ENCAISSER VITE — le réglage qui compte vraiment

itch.io propose deux modes de paiement. **Il faut le bon.**

- **« Direct to you »** — l'argent arrive **immédiatement** sur ton PayPal ou ton Stripe.
  ⚠ **C'est celui-là.** À brancher dans `Dashboard → Settings → Payments` **avant** de publier.
- « Collected by itch.io » — itch encaisse et reverse **sur demande, avec un seuil et un délai**.
  Pour quelqu'un qui a besoin d'argent rapidement, c'est le mauvais choix.

Autres réglages : part reversée à itch **réglable par toi** (10 % par défaut, tu peux descendre) ;
prix **fixe**, pas « pay what you want » — un outil à prix libre se lit comme un projet d'amateur.

### Ce qu'il faut écrire sur les droits (les acheteurs le demandent en premier)

> **The tilesets you make are yours.** Commercial use included, no royalties, no attribution
> required. You may ship the exported sheets and the SoluPaint plugin inside your game.
> You may not resell SoluTiles itself.

⚠ **Point n°2 à discuter** : rédiger le `LICENSE.txt` en conséquence, et vérifier qu'il dit la
même chose que la page. Deux endroits qui se contredisent, c'est un litige.

---

## 4. LA PAGE ITCH — dans l'ordre où on la remplit

- [ ] **Titre** : `SoluTiles` · **Sous-titre** : `Paint one landscape. Get a complete autotile tileset.`
- [ ] **Classification** : `Tools` (pas `Games`) · **Kind of project** : `Downloadable`
- [ ] **Status** : `In development`
- [ ] **Prix** : fixe, 19 € (voir §3) · paiement **direct**
- [ ] **Le GIF en tout premier** (voir §5) — c'est lui qui vend, pas le texte
- [ ] **L'encadré d'accès anticipé** (§3)
- [ ] **L'accroche longue** (§2)
- [ ] **3 à 5 captures** : le guide en cours de peinture · les jumelles qui s'allument · la planche
      exportée · le monde posé dans Godot avec SES tuiles
- [ ] **« How it works »** en 4 lignes numérotées, pas un paragraphe
- [ ] **⚠ « What it does NOT do (yet) »** — l'eau, les trous, les grottes, les pentes ; et
      **Godot 4 uniquement** (pas d'Unity, pas de Unreal)
- [ ] **Prérequis** : Windows · Godot 4.x pour le plugin
- [ ] **Les droits** (§3)
- [ ] **Tags** (itch en accepte une dizaine) : `godot`, `tileset`, `autotile`, `pixel-art`,
      `tilemap`, `level-editor`, `gamedev-tool`, `2d`, `top-down`
- [ ] **Une adresse de contact** — un acheteur bloqué qui ne peut pas t'écrire demande un remboursement

---

## 5. LES VISUELS — le GIF est le produit

**Un seul visuel décide de tout** : le crayon passe, **les jumelles se remplissent en même temps**,
et une jauge monte. C'est incompréhensible en texte et évident en trois secondes. Rien d'autre
n'a cette densité.

**Le GIF principal (8–12 s, en boucle)** — un seul trait de crayon, plusieurs cases qui se
remplissent, la jauge qui bouge. Pas de curseur qui cherche, pas de menu. On coupe le début.

**La vidéo (45–60 s)**, structure imposée :
`0–5 s` le problème (une carte, un coin sans tuile) → `5–25 s` on peint → `25–40 s` on exporte →
`40–55 s` **le monde posé dans Godot avec ses propres tuiles** → `55–60 s` le nom, le prix, le lien.
⚠ **Pas de musique, pas d'intro animée.** On montre l'écran.

**Outils déjà là** : `ui/screenshot.gd` (`zoom=`, `survol=`, `apercu`) pour les captures propres,
`tools/preview_engine.gd` pour le monde posé, la **room de Test** pour la démo « je pose, ça se
rend avec mes tuiles » — qui est probablement le plus beau plan de la vidéo.

⚠ **Point n°3 à discuter** : la capture d'écran animée sous Windows (ShareX, gratuit, GIF et MP4)
et si on montre l'interface **française** ou si on attend la passe anglaise (§0.B).

---

## 6. LES RÉSEAUX — où poster, quand, et comment

### La règle générale, avant les endroits

1. **Le GIF est le post. Le texte est une légende.** Personne ne lit d'abord.
2. **Commence par le problème, pas par le nom du produit.** « Making autotile tilesets by hand
   means you find the missing corner three months later » attrape ; « I made a tool called… » non.
3. **Le lien en dernier, ou en commentaire.** Un post qui commence par un lien se lit comme une pub.
4. **Sois une personne.** « J'ai passé neuf mois là-dessus, voilà ce que ça fait. » Pas un
   communiqué. Les communautés dev achètent à des gens, pas à des marques.
5. ⚠ **Reste trois heures après le post et réponds à tout.** C'est ce qui nourrit l'algorithme
   **et** c'est là que les ventes se font, pas dans le post lui-même.
6. **Un post par plateforme.** Le même texte copié partout se voit et se punit.
7. ⚠ **Lis les règles de chaque endroit avant de poster.** Les subreddits changent leurs règles
   d'autopromotion et un post supprimé ne se repost pas.

### La réponse au commentaire qui va venir (« pourquoi pas gratuit / open source ? »)

> Because it's nine months of work and I need to eat. The Godot plugin ships as readable GDScript
> — you can see exactly what it does, and it stays yours forever once you buy. If you just want
> to see how the placement works, the plugin and the trial tileset are free.

⚠ **Répondre calmement une fois, ne jamais argumenter deux fois.** Un fil de dispute enterre le post.

### Les endroits, par rendement

| Où | Quand | Comment |
|---|---|---|
| **r/godot** | En semaine, **19 h–22 h Paris** (matinée US) | Le plus gros vivier. Flair « Tool »/« Resource ». Le GIF, le problème, le lien en bas. ⚠ Lire les règles d'autopromo. |
| **Discord Godot officiel** | N'importe quand | Canal de vitrine / promotion. **Y être avant de vendre**, pas débarquer pour vendre. |
| **X / Twitter** | **Samedi**, `#screenshotsaturday` | `#godotengine #gamedev #pixelart #indiedev`. Le GIF en natif (jamais un lien vers une vidéo). |
| **Bluesky** | Même jour, même GIF | La foule pixel-art/gamedev y est passée. Mêmes hashtags. |
| **r/gamedev** | **Screenshot Saturday** | Plus strict sur l'autopromo — passer par le fil hebdo. |
| **r/IndieDev, r/gamedevscreens** | Après r/godot | Public plus large, conversion plus faible. |
| **Devlog itch.io** | À chaque version | Circule dans les fils itch et chez tes abonnés. **C'est ce qui prouve qu'un accès anticipé est vivant.** |
| **YouTube** | Une fois | La vidéo de 60 s en public, titrée pour la recherche : `Godot autotile tileset from your own art`. **Durable** : elle se trouve encore dans six mois. |
| **Communautés FR** (Discord Godot FR, X gamedev FR) | Cette nuit possible | ⚠ **Le seul endroit où l'interface française n'est pas un problème.** Petit vivier, mais gratuit et disponible **tout de suite**. |
| **Godot Asset Library** | Voir ci-dessous | Le funnel gratuit. |

### ⚠ LE MEILLEUR COUP GRATUIT : le plugin seul, offert sur l'Asset Library

Publier **SoluPaint + le tileset d'essai** gratuitement sur la Godot Asset Library, avec un lien
vers SoluTiles dans la description.

- Ça met un **outil qui marche** entre les mains de gens qui n'auraient jamais cliqué sur une pub ;
- ça **est** la démo — l'acheteur voit le monde se poser avant de payer ;
- ça ne donne rien qui ne parte déjà : `rules.gd` est du GDScript en clair chez l'acheteur, et la
  charte a déjà tranché qu'un verrou serait du maquillage ;
- l'Asset Library est le premier endroit où un dev Godot cherche quelque chose.

⚠ **Point n°4 à discuter** : c'est mon plus fort levier de découverte, et c'est aussi le seul qui
donne quelque chose. À trancher ensemble.

---

## 7. LE CALENDRIER

**Cette nuit** — le modèle fermé et le guide juste ; le preset d'export **Windows** et le ZIP
essayé sur une machine vierge ; la page itch remplie, le paiement en **direct**, publiée **en
silence** ; les visuels capturés.

**J+1** — la passe anglaise (§0.B) ; la vidéo montée ; le premier devlog.

**J+2, une journée à bonne heure** — le post r/godot ; puis le Discord Godot ; puis
`#screenshotsaturday` le samedi. **Rester disponible pour répondre.**

**Semaine 1** — l'Asset Library (si tranché) ; YouTube ; répondre à chaque acheteur nommément et
**leur demander ce qui leur manque** — c'est là que se décide l'ordre réel des patchs.

**Ensuite** — les patchs selon `PLAN.md`, un devlog par jalon, le prix qui monte à la 1.0, Steam
payé par les ventes itch.

### ⚠ Ce qu'il faut attendre comme chiffres (pour ne pas être déçu)

Un bon post r/godot fait quelques milliers de vues ; un ou deux pour cent cliquent ; quelques
pour cent de ceux-là achètent. **Ordre de grandeur : 5 à 40 ventes**, soit **100 à 800 €**. Un post
qui prend fait dix fois ça, et ça ne se pilote pas. **Ce n'est pas un salaire — c'est un
démarrage, des retours, et la preuve que ça se vend.** L'argent sérieux est à la 1.0 et sur Steam.

---

## 8. CE QU'ON NE FAIT PAS

- ❌ **Pas de roadmap daté.** Jamais. C'est la source n°1 des remboursements sur les outils.
- ❌ **Pas de lancement bruyant maintenant** — on garde la cartouche pour l'eau + les trous.
- ❌ **Pas de promo, pas de réduction au lancement.** Le prix monte, il ne descend pas.
- ❌ **Pas de « pay what you want »** sur un outil professionnel.
- ❌ **Pas de Steam maintenant** (100 $ à avancer). Après les premières ventes itch.
- ❌ **Pas de Patreon / précommande / crowdfunding.** Ça demande une audience qu'on n'a pas encore.
- ❌ **Pas de version bridée payante.** La démo, c'est le plugin gratuit (§6).

---

## 9. CE QUI RESTE À TRANCHER — la liste de discussion

1. **Le prix** : 15 / 19 / 29 € ? *(mon avis : 19)*
2. ~~**La langue**~~ — **tranché le 06/09 : anglais source, passe faite.** Reste à décider si
   le français revient un jour comme traduction.
3. **Le plugin gratuit sur l'Asset Library** : oui ou non ?
4. **La licence** : rédiger `LICENSE.txt` et l'aligner sur la page.
5. **Le nom de la page itch** et l'URL (`solutiles.itch.io/solutiles` ?).
6. **Mac / Linux** : on exporte aussi, ou Windows seul avec la mention claire ?
7. **La mise à jour des acheteurs** : itch pousse les nouvelles versions aux acheteurs — vérifier
   que le ZIP est bien marqué comme la plateforme Windows, sinon ils ne reçoivent rien.
8. **Le remboursement** : itch laisse le vendeur décider. Écrire la règle sur la page (« email me,
   no questions asked, 14 days ») — ça vaut plus de ventes que ça n'en coûte.
