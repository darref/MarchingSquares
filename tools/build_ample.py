# -*- coding: utf-8 -*-
"""Le guide du mode « ample » : un archipel de trois iles.

Meme completude que `minimal` -- 47 index de surface, 15 croisements, 36 roles de robe --
mais chaque tuile portee TROIS fois.

Le relief se decrit accident par accident, jamais en ASCII. Et les accidents se posent sur
une TERRE CONTINUE, pas chacun sur sa dalle : un guide fait de rectangles flottants se lit
comme une planche de specimens, pas comme un paysage.

⚠ CE FICHIER N'EST PAS DU LOGICIEL. C'est l'outil qui a produit `guides/ample.txt`, garde
ici parce que sans lui le guide ne serait plus qu'un tapis de chiffres : on ne saurait plus
quel accident porte quelle famille, ni comment le retoucher sans tout casser. Le logiciel,
lui, ne le lit jamais -- il lit le guide.

    python tools/build_ample.py

Puis la suite de tests tranche : elle exige 47/47 index, 15/15 croisements, 36/36 roles,
chacun vu au moins trois fois, et aucune robe hors du cadre.
"""

W, H = 84, 46
g = [[0] * W for _ in range(H)]


def put(x, y, l):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = l


def rect(x0, y0, x1, y1, l):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = max(g[y][x], l)


# ---------------------------------------------------------------- les accidents
# Aucun ne pose sa propre terre : c'est l'ile qui la porte.

TOR = ["0001", "0010", "1011", "0111"]


def lacs(ox, oy, di=0, dj=0):
    """DISTRICT LACUSTRE. Le motif des petits lacs est un tore de de Bruijn 4x4 : ses seize
    fenetres 2x2 sont toutes distinctes, donc chaque case entre quatre lacs voit une
    combinaison differente d'encoches -- les seize index « tous cardinaux » tombent d'un
    seul district. Le decalage (di, dj) change le dessin sans changer le compte."""
    for i in range(5):
        for j in range(5):
            if TOR[(j + dj) % 4][(i + di) % 4] == '1':
                put(ox + 1 + 2 * i, oy + 1 + 2 * j, 0)


QE = [0, 1, 0, 1, 1, 0, 1, 1, 1, 0]
QW = [0, 1, 1, 1, 0, 1, 1, 0, 1, 0]
QN = [0, 1, 1, 0, 1, 0, 1, 1, 1, 0]
QS = [0, 1, 1, 1, 0, 1, 0, 1, 1, 0]


def cretes_v(ox, oy, qe, qw):
    """CRETES A RAMEAUX, nord-sud : une arete droite bordee d'un epaulement discontinu.
    Le motif de l'epaulement porte les quatre voisinages utiles, ce qui donne les seize
    index « trois cardinaux », les pointes et les cretes etroites.
    Emprise : colonnes ox+2..ox+6, rangees oy+2..oy+11."""
    for k in range(10):
        put(ox + 2, oy + 2 + k, 2)
        if qe[k]:
            put(ox + 3, oy + 2 + k, 2)
        put(ox + 6, oy + 2 + k, 2)
        if qw[k]:
            put(ox + 5, oy + 2 + k, 2)


def cretes_h(ox, oy, qn, qs):
    """Les memes, couchees est-ouest. Emprise : colonnes ox+2..ox+10, rangees oy..oy+6."""
    for k in range(9):
        put(ox + 2 + k, oy + 1, 2)
        if qn[k]:
            put(ox + 2 + k, oy, 2)
        put(ox + 2 + k, oy + 5, 2)
        if qs[k]:
            put(ox + 2 + k, oy + 6, 2)


def coude(x, y, dx, dy):
    """COUDE D'ARETE : deux cardinaux adjacents SANS diagonale. Ne s'obtient d'aucune
    masse pleine."""
    put(x, y, 2)
    put(x + dx, y, 2)
    put(x, y + dy, 2)


def fourche(x, y, absent):
    """FOURCHE : trois cardinaux sans diagonale. Pas davantage dans une masse pleine."""
    put(x, y, 2)
    for direction, dx, dy in [('N', 0, -1), ('S', 0, 1), ('W', -1, 0), ('E', 1, 0)]:
        if direction != absent:
            put(x + dx, y + dy, 2)


def aretes(ox, oy):
    """Chaos rocheux : les quatre coudes et les quatre fourches.
    Emprise : colonnes ox..ox+11, rangees oy..oy+8."""
    coude(ox + 1, oy, 1, 1)         # E+S
    coude(ox + 5, oy + 1, 1, -1)    # N+E
    coude(ox + 9, oy + 1, -1, -1)   # N+W
    coude(ox + 3, oy + 4, -1, 1)    # S+W
    fourche(ox + 7, oy + 4, 'E')    # N+S+W
    fourche(ox + 10, oy + 4, 'W')   # N+E+S
    fourche(ox + 1, oy + 7, 'N')    # E+S+W
    fourche(ox + 5, oy + 7, 'S')    # N+E+W


def escarpement(ox, lip, largeur, spurs, banquette):
    """ESCARPEMENT COTIER A CONTREFORTS. Un contrefort est une colonne dont le bord sud
    AVANCE sur ses voisines : elle est donc devant, et porte son angle. Les eperons
    donnent les cinq pans a angle -- bout ouest, paire mitoyenne, eperon seul, bout est.

    ⚠ IL EN FAUT DES DEUX SORTES, pour une raison de terrain et non de mecanique. Avec
    banquette, les eperons posent leur PIED pendant que la paroi voisine tombe encore :
    c'est la seule facon d'avoir les cinq pieds a angle. Sans banquette, leur chute de six
    cases passe par le CORPS 1, ce qu'une chute de trois ne fait jamais.

    ⚠ La banquette est QUATRE rangees sous la levre de l'eperon, et d'etage 1 : `fall_at`
    sonde la case juste sous le pied -- une banquette posee sur le trajet ne l'arrete pas
    -- et a l'etage 2 la robe rencontrerait son propre niveau, s'ecreterait, et ne
    poserait aucun pied."""
    rect(ox, lip - 2, ox + largeur - 1, lip, 2)
    for c in spurs:
        put(ox + c, lip + 1, 2)
        put(ox + c, lip + 2, 2)
    if banquette:
        for c in spurs:
            put(ox + c, lip + 6, 1)


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
    rect(x0, 1, x0 + largeur - 1, lip, 1)
    for dx in range(largeur):
        for y in range(1, profil[dx]):
            put(x0 + dx, y, 0)
    # ⚠ LES FLANCS SE CREUSENT AVANT LES ACCIDENTS, et jamais sous la levre : sous elle
    # c'est l'escarpement, et le creuser lui retirerait de la roche.
    ouest, est = flancs
    for y, profondeur in ouest:
        for k in range(profondeur):
            put(x0 + k, y, 0)
    for y, profondeur in est:
        for k in range(profondeur):
            put(x0 + largeur - 1 - k, y, 0)
    garnir(x0)
    moitie = (largeur - 2) // 2
    escarpement(x0, lip, moitie, spurs, banquette_ouest)
    escarpement(x0 + moitie + 2, lip, moitie, spurs, not banquette_ouest)


# ⚠ LA COTE NE PEUT PAS MORDRE PARTOUT : un district lacustre a besoin de sa bordure de
# terre, sinon ses fenetres 2x2 ne sont plus toutes distinctes.
PROFIL_A = [4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 4, 2, 2, 2, 2, 2, 2, 3, 4, 4, 3, 4]
PROFIL_B = [3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 5, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4]
PROFIL_C = [5, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 2, 2, 2, 2, 2, 2, 4, 4, 3, 3, 2,
            2, 3]


def garnir_a(x0):
    """OUEST -- le district lacustre au nord-ouest, les cretes dressees au nord-est."""
    lacs(x0 + 1, 2, 0, 0)
    cretes_v(x0 + 14, 1, QE, QW)
    cretes_h(x0 + 1, 14, QN, QS)
    aretes(x0 + 13, 14)


def garnir_b(x0):
    """CENTRE -- l'inverse : les cretes au nord-ouest, les lacs au nord-est."""
    cretes_v(x0 + 1, 1, QW, QE)
    lacs(x0 + 12, 2, 1, 2)
    aretes(x0 + 1, 15)
    cretes_h(x0 + 13, 16, QS, QN)


def garnir_c(x0):
    """EST -- les cretes couchees au nord, les lacs dessous, le chaos a l'est."""
    cretes_h(x0 + 1, 1, QN, QE)
    lacs(x0 + 1, 9, 3, 1)
    cretes_v(x0 + 14, 0, QE, QN)
    aretes(x0 + 14, 13)


# Les criques des flancs : (rangee, profondeur). Aucune ne descend sous la levre.
FLANCS_A = ([(4, 1), (5, 1), (12, 1), (13, 2), (14, 2), (19, 1), (22, 1), (23, 1)],
            [(2, 1), (7, 1), (8, 2), (16, 1), (17, 1), (21, 1)])
FLANCS_B = ([(3, 1), (8, 1), (9, 2), (10, 1), (18, 1), (23, 1), (24, 2), (25, 1)],
            [(5, 1), (6, 1), (13, 1), (14, 2), (20, 1), (26, 1)])
FLANCS_C = ([(6, 1), (7, 2), (8, 1), (15, 1), (20, 1), (21, 1)],
            [(3, 1), (4, 1), (9, 1), (10, 2), (11, 1), (18, 1), (19, 1), (22, 1)])

ile(1, 26, 26, PROFIL_A, FLANCS_A, garnir_a, [0, 3, 4, 7, 11], True)
ile(29, 24, 29, PROFIL_B, FLANCS_B, garnir_b, [0, 2, 3, 7, 10], False)
ile(55, 28, 25, PROFIL_C, FLANCS_C, garnir_c, [0, 5, 6, 9, 12], True)

# ---------------------------------------------------------------- la mer du sud
# Ilots isoles -- l'index 0, une seule case sans voisin -- et contacts diagonaux : deux
# cases qui ne se touchent que par le coin. La canonicalisation du blob JETTE ce contact,
# le reseau dual a une tuile pour lui. Un guide complet en blob 47 n'est donc pas
# automatiquement complet a cheval.
def ilot(x, y, level=1):
    """Une seule case sans voisin : l'index 0."""
    put(x, y, level)


def contact_diagonal(x, y, montant):
    """Deux cases qui ne se touchent QUE par le coin.
    ⚠ La canonicalisation du blob le jette -- un coin diagonal isole ne change pas la
    silhouette -- mais le reseau dual a une tuile pour lui. Un guide complet en blob 47
    n'est donc PAS automatiquement complet a cheval, et ne peut pas l'etre."""
    put(x, y, 1)
    put(x + 1, y - 1 if montant else y + 1, 1)


# ⚠ UN ECUEIL D'ETAGE 2 TOMBE DE SIX CASES : il lui faut six rangees de plaine sous lui,
# a l'interieur du cadre. Une robe qui sort de la grille est une tuile impeignable.
for x in (6, 34, 62):
    ilot(x, 38, 2)
for x in (12, 40, 68):
    ilot(x, 40)
for x in (18, 46, 74):
    contact_diagonal(x, 41, True)
for x in (24, 52, 78):
    contact_diagonal(x, 40, False)

out = '\n'.join(''.join('.' if v == 0 else str(v) for v in row) for row in g)
open('D:/AbsoluTiles/guides/ample.txt', 'w', encoding='utf-8').write(out + '\n')
print("guides/ample.txt : %d x %d" % (W, H))
