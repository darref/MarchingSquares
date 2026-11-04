# La page itch.io — texte prêt à coller

> Tout ce qui suit part **en anglais**, c'est la langue du public. Les commentaires en
> français (en `> citation`) sont pour toi, pas pour la page.
> Ce fichier ne part pas dans le paquet : `store/*` est exclu à l'export.

---

## Les champs du formulaire

| Champ itch | Valeur |
|---|---|
| **Title** | `MarchingSquares` |
| **Short description / tagline** | `Paint one landscape. Get a complete autotile tileset.` |
| **Classification** | `Tools` — ⚠ **pas `Games`** |
| **Kind of project** | `Downloadable` |
| **Release status** | `In development` — c'est ça qui affiche « accès anticipé » |
| **Pricing** | `Paid`, prix fixe (⚠ **pas** « pay what you want ») |
| **Uploads** | `MarchingSquares-win64.zip`, coché **Windows** |
| **Community** | `Comments` — un acheteur bloqué qui ne peut pas écrire demande un remboursement |
| **Visibility** | `Public` quand tu es prêt ; `Restricted` pour te relire d'abord |

**Tags** (itch en accepte une dizaine, tous en minuscules) :

```
godot, tileset, autotile, pixel-art, tilemap, level-editor, gamedev-tool, 2d, top-down
```

---

## L'encadré d'accès anticipé — tout en haut de la description

> ⚠ Il vient **avant** l'argumentaire. Quelqu'un qui découvre après avoir payé que l'eau
> n'y est pas demande un remboursement, et il a raison.

```
🚧 EARLY ACCESS

MarchingSquares builds TERRAIN today: surfaces, cliffs, multi-level falls, overlapping
massifs — a tile vocabulary that is proven complete, with the Godot plugin that
places it.

Water, holes, caves and surface materials are being built. No dates — I don't
promise what I can't date.

Updates are included, forever. The early access price only goes up.
```

---

## L'accroche — juste sous le GIF

```
Making an autotile tileset by hand is not hard because of the drawing.

It's hard because you don't know WHAT to draw — and you find out three months
later, when one corner of your map has no tile for it.

MarchingSquares gives you a landscape to paint over. Paint it, and you have a complete
autotile tileset — proven complete, not promised — plus the Godot plugin that
places it in your game.

Nothing is mirrored, composited, or generated. Every pixel is yours.
```

---

## How it works

```
HOW IT WORKS

1. Pick your pixel size and open the guide. Every case that can occur is already
   laid out in front of you.

2. Paint. Cells carrying the same tile fill together — it isn't another tile that
   looks alike, it's the same one, seen in several places. One stroke can touch a
   hundred cells.

3. Two gauges say what's left. They recompute at every stroke, with the same code
   the test suite runs. What the screen shows is what the tests prove.

4. Export opens when nothing is missing — and not before. A half-painted sheet
   isn't a tileset, it's a trap.

Then: one button installs the Godot plugin into your project, your tileset ships
with it, and you paint your world with your own tiles.
```

---

## Ce qui le distingue

```
WHY THIS AND NOT A GENERATOR

· Proven complete, not promised. The tool knows every configuration that can
  occur, shows you all of them, and refuses what it can't guarantee. The count is
  on screen while you paint.

· No pixel you didn't paint. No mirroring, no compositing, no AI. Mirrored
  tilesets betray themselves at the joins and turn your highlights the wrong way.
  Yours won't.

· The engine ships with it. The SoluPaint plugin places your world in Godot, as
  readable GDScript you can open and check. It stays yours once you buy.

· A cliff is not a terrain. A cliff leaves the plane: its face fills cells that,
  seen from above, belong to the ground below. No terrain system can place that.
  This one does.
```

---

## ⚠ Ce que ça ne fait pas — la section qui évite les remboursements

> Elle **augmente** la conversion sur un outil de dev : ce public a été déçu trop souvent.

```
WHAT IT DOESN'T DO (YET)

· No water, no holes, no caves, no surface materials, no slopes, no animation.
· Godot 4 only. No Unity, no Unreal, no Game Maker.
· Windows only for now.
· One drawing per tile. No variants — the sheet has a fixed size, and painting
  a thousand twins differently would silently throw all but one away.

If any of those is a dealbreaker today, don't buy today. The price will be higher
when they land, and that's the honest trade.
```

---

## Prérequis, droits, remboursement

```
REQUIREMENTS
Windows 10+, 64-bit. Godot 4.x for the plugin only — MarchingSquares itself needs
nothing installed.

The first launch may show "Windows protected your PC". The build isn't signed by
a certificate authority yet. Click More info → Run anyway.

YOUR WORK IS YOURS
The tilesets you make are yours. Commercial use included, no royalties, no
attribution required. Ship the exported sheets and the SoluPaint plugin inside
your game. You may not resell MarchingSquares itself.

REFUNDS
Fourteen days, no questions asked. Email me.
```

---

## ⚠ À FAIRE AVANT DE PUBLIER — les cases qui coûtent cher si on les oublie

- [ ] **`Dashboard → Settings → Payments` sur « Direct to you »** (PayPal ou Stripe).
      L'autre mode fait encaisser itch, avec seuil et délai. ⚠ **C'est le réglage
      qui décide si tu es payé cette semaine ou dans un mois.**
- [ ] **Le GIF en première position** dans les visuels — c'est lui qui vend, pas le texte.
- [ ] Une **adresse de contact** en clair sur la page, et dans `README.txt` et `LICENSE.txt`
      (les deux portent encore `[à remplir avant publication]`).
- [ ] Vérifier que l'upload est **coché Windows** — sinon les acheteurs ne reçoivent pas
      les mises à jour automatiquement.
- [ ] Se relire une fois en **Restricted** avant de passer en Public.

---

## Le premier devlog — à poster le jour même

> Un accès anticipé sans devlog se lit comme un produit abandonné. Celui-ci coûte dix minutes
> et il est la moitié de ce qui rassure un acheteur.

```
Title: MarchingSquares is out in early access — terrain first

What's in: surfaces, cliffs, multi-level falls, massifs that overlap. The tile
vocabulary is proven complete by program, and the count is on screen while you
paint.

What I'm building next, without dates: water basins, holes, caves, surface
materials.

Why early access: the terrain half is done and usable today, and I'd rather have
five people painting with it and telling me what breaks than six more months of
guessing on my own.

If you paint something with it, show me. I answer everything.
```
