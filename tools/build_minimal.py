# -*- coding: utf-8 -*-
"""Le guide du mode « minimal » : une seule ile, qui porte tout.

Le plus petit paysage qui SONNE NATUREL A REGARDER tout en couvrant tous les cas.
Minimal n'est donc pas « le plus petit », c'est « le plus petit qui tienne les deux ».

Un exemplaire de chaque accident, et un seul -- c'est toute la difference avec `ample`,
qui en pose trois.

⚠ ET IL SE COUCHE, IL NE SE DRESSE PAS. Ce qui compte n'est pas le nombre de cases mais
la TAILLE DE LA CASE A L'ECRAN : l'acheteur doit voir, d'un coup d'oeil et en temps reel,
un grand nombre de tuiles se remplir sous son crayon. Un guide haut et etroit dans une
zone de travail large laisse la moitie du cadre vide et rapetisse chaque case d'autant.
Les accidents se posent donc COTE A COTE, en une bande, et non les uns sous les autres.

    python tools/build_minimal.py

Puis la suite de tests tranche : 47/47 index de surface, 15/15 croisements, 36/36 roles de
robe, et aucune robe hors du cadre.
"""

from accidents import (Grille, lacs, cretes_v, cretes_h, aretes, escarpement, ilot,
                       contact_diagonal, QE, QW, QN, QS)

LIP = 17                          # la levre de l'escarpement cotier
SPURS = [0, 5, 6, 11, 20]         # bout ouest, paire mitoyenne, eperon seul, bout est

g = Grille(46, 27)

# ---------------------------------------------------------------- l'ile
# Colonnes 1..44, une colonne de mer de chaque cote.
g.rect(1, 1, 44, LIP, 1)

# ⚠ LA COTE NE PEUT PAS MORDRE PARTOUT : chaque accident a besoin de sa bordure de terre.
# Elle ne mord donc qu'entre eux, la ou la terre est libre.
for x, y in [(12, 1), (13, 1), (12, 2), (19, 1), (20, 1), (21, 1), (20, 2), (31, 1),
             (44, 1), (44, 2), (43, 1), (1, 12), (1, 13), (2, 13), (44, 11), (44, 12),
             (43, 12), (1, 1), (11, 1)]:
    g.put(x, y, 0)

# ---------------------------------------------------------------- les accidents
# Une bande d'ouest en est : le district lacustre, les aretes dressees, les aretes
# couchees, et le chaos rocheux.
lacs(g, 1, 1)                     # colonnes 1..11, rangees 1..11
cretes_v(g, 12, 0, QE, QW)        # colonnes 14..18, rangees 2..11
cretes_h(g, 20, 1, QN, QS)        # colonnes 22..30, rangees 1..7
aretes(g, 32, 1)                  # colonnes 32..43, rangees 1..9

# Les ecueils, dans la clairiere laissee sous les aretes couchees.
# ⚠ IL LEUR FAUT QUATRE RANGEES SOUS EUX : trois de chute, et une de terre pour atterrir.
# Si la case juste sous le pied porte deja de l'etage 2, la robe rencontre son propre
# niveau, s'ecrete, et ne pose aucun pied.
ilot(g, 23, 9, 2)
contact_diagonal(g, 26, 10, True, 2)
contact_diagonal(g, 30, 9, False, 2)

# ---------------------------------------------------------------- le rivage sud
# Une moitie a banquette -- les cinq pieds a angle -- l'autre plongeant droit dans la
# plaine : sa chute de six cases passe par le corps 1.
escarpement(g, 1, LIP, 21, SPURS, True)
escarpement(g, 24, LIP, 21, SPURS, False)

g.ecrire('minimal.txt')
