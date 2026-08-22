# -*- coding: utf-8 -*-
"""Le guide du mode « ample » : un archipel de trois iles.

Meme completude que `minimal` -- 47 index de surface, 15 croisements, 36 roles de robe --
mais chaque tuile portee TROIS fois.

⚠ CE FICHIER N'EST PAS DU LOGICIEL. C'est l'outil qui produit `guides/ample.txt`, garde
ici parce que sans lui le guide ne serait plus qu'un tapis de chiffres : on ne saurait plus
quel accident porte quelle famille, ni comment le retoucher sans tout casser. Le logiciel,
lui, ne le lit jamais -- il lit le guide.

    python tools/build_ample.py

Puis la suite de tests tranche : elle exige 47/47 index, 15/15 croisements, 36/36 roles,
chacun vu au moins trois fois, et aucune robe hors du cadre.
"""

from accidents import (Grille, lacs, cretes_v, cretes_h, aretes, escarpement, ilot,
                       contact_diagonal, QE, QW, QN, QS)

g = Grille(84, 46)

# ---------------------------------------------------------------- les trois iles
#
# ⚠ ELLES DOIVENT ETRE REELLEMENT DIFFERENTES, pas la meme trois fois. C'est la lecon des
# quatre cretes de `minimal` : la meme sequence repetee se voit a l'oeil. Chacune a donc sa
# largeur, sa levre cotiere, sa disposition interieure et son jeu d'eperons.
#
# ⚠ UN JEU D'EPERONS DOIT PORTER LES CINQ CONFIGURATIONS -- bout ouest, paire mitoyenne,
# eperon seul, bout est -- sans quoi il manque des pans a angle. La forme se varie, la
# grammaire non.


def ile(x0, largeur, lip, profil, flancs, garnir, spurs, banquette_ouest):
    """Une ile : la terre, sa cote nord decoupee, ses accidents, et son rivage sud en deux
    escarpements -- l'un a banquette, l'autre plongeant droit dans la plaine."""
    g.rect(x0, 1, x0 + largeur - 1, lip, 1)
    for dx in range(largeur):
        for y in range(1, profil[dx]):
            g.put(x0 + dx, y, 0)
    # ⚠ LES FLANCS SE CREUSENT AVANT LES ACCIDENTS, et jamais sous la levre : sous elle
    # c'est l'escarpement, et le creuser lui retirerait de la roche.
    ouest, est = flancs
    for y, profondeur in ouest:
        for k in range(profondeur):
            g.put(x0 + k, y, 0)
    for y, profondeur in est:
        for k in range(profondeur):
            g.put(x0 + largeur - 1 - k, y, 0)
    garnir(x0)
    moitie = (largeur - 2) // 2
    escarpement(g, x0, lip, moitie, spurs, banquette_ouest)
    escarpement(g, x0 + moitie + 2, lip, moitie, spurs, not banquette_ouest)


# ⚠ LA COTE NE PEUT PAS MORDRE PARTOUT : un district lacustre a besoin de sa bordure de
# terre, sinon ses fenetres 2x2 ne sont plus toutes distinctes.
PROFIL_A = [4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 4, 2, 2, 2, 2, 2, 2, 3, 4, 4, 3, 4]
PROFIL_B = [3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 5, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4]
PROFIL_C = [5, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 2, 2, 2, 2, 2, 2, 4, 4, 3, 3, 2,
            2, 3]

# Les criques des flancs : (rangee, profondeur). Aucune ne descend sous la levre.
FLANCS_A = ([(4, 1), (5, 1), (12, 1), (13, 2), (14, 2), (19, 1), (22, 1), (23, 1)],
            [(2, 1), (7, 1), (8, 2), (16, 1), (17, 1), (21, 1)])
FLANCS_B = ([(3, 1), (8, 1), (9, 2), (10, 1), (18, 1), (23, 1), (24, 2), (25, 1)],
            [(5, 1), (6, 1), (13, 1), (14, 2), (20, 1), (26, 1)])
FLANCS_C = ([(6, 1), (7, 2), (8, 1), (15, 1), (20, 1), (21, 1)],
            [(3, 1), (4, 1), (9, 1), (10, 2), (11, 1), (18, 1), (19, 1), (22, 1)])


def garnir_a(x0):
    """OUEST -- le district lacustre au nord-ouest, les cretes dressees au nord-est."""
    lacs(g, x0 + 1, 2, 0, 0)
    cretes_v(g, x0 + 14, 1, QE, QW)
    cretes_h(g, x0 + 1, 14, QN, QS)
    aretes(g, x0 + 13, 14)


def garnir_b(x0):
    """CENTRE -- l'inverse : les cretes au nord-ouest, les lacs au nord-est."""
    cretes_v(g, x0 + 1, 1, QW, QE)
    lacs(g, x0 + 12, 2, 1, 2)
    aretes(g, x0 + 1, 15)
    cretes_h(g, x0 + 13, 16, QS, QN)


def garnir_c(x0):
    """EST -- les cretes couchees au nord, les lacs dessous, le chaos a l'est."""
    cretes_h(g, x0 + 1, 1, QN, QE)
    lacs(g, x0 + 1, 9, 3, 1)
    cretes_v(g, x0 + 14, 0, QE, QN)
    aretes(g, x0 + 14, 13)


ile(1, 26, 26, PROFIL_A, FLANCS_A, garnir_a, [0, 3, 4, 7, 11], True)
ile(29, 24, 29, PROFIL_B, FLANCS_B, garnir_b, [0, 2, 3, 7, 10], False)
ile(55, 28, 25, PROFIL_C, FLANCS_C, garnir_c, [0, 5, 6, 9, 12], True)

# ---------------------------------------------------------------- la mer du sud
# ⚠ UN ECUEIL D'ETAGE 2 TOMBE DE SIX CASES : il lui faut six rangees de plaine sous lui,
# a l'interieur du cadre. Une robe qui sort de la grille est une tuile impeignable.
for x in (6, 34, 62):
    ilot(g, x, 38, 2)
for x in (12, 40, 68):
    ilot(g, x, 40)
for x in (18, 46, 74):
    contact_diagonal(g, x, 41, True)
for x in (24, 52, 78):
    contact_diagonal(g, x, 40, False)

g.ecrire('ample.txt')
