# -*- coding: utf-8 -*-
"""Le vocabulaire de terrain des guides.

⚠ CE FICHIER N'EST PAS DU LOGICIEL. C'est l'outil qui produit `guides/minimal.txt` et
`guides/ample.txt` ; le logiciel, lui, ne lit que les guides.

⚠ UN GUIDE SE DECRIT ACCIDENT PAR ACCIDENT, JAMAIS EN ASCII. Dessiner ces formes a la main
fait se tromper d'une case et d'un etage a chaque essai -- c'est la lecon des contreforts.

Chaque famille d'index est portee par un accident de terrain CHOISI POUR CA, et c'est ce
qui permet a un guide de rester un paysage au lieu d'un damier :

  - le district lacustre       les seize index « tous cardinaux »
  - les cretes a rameaux       les seize « trois cardinaux », les pointes, les cretes etroites
  - les coudes et les fourches ce qu'aucune masse pleine ne donne
  - l'escarpement a contreforts les 36 roles de robe
  - l'ilot et le contact diagonal l'index 0, et les deux croisements du reseau dual

⚠ AUCUN ACCIDENT NE POSE SA PROPRE TERRE : c'est l'ile qui la porte. Un guide fait de
rectangles flottants se lit comme une planche de specimens, pas comme un paysage.
"""

import os


class Grille:
    """Un relief en construction. `.` est la plaine, 1..9 les plateaux."""

    def __init__(self, largeur, hauteur):
        self.w = largeur
        self.h = hauteur
        self.g = [[0] * largeur for _ in range(hauteur)]

    def put(self, x, y, niveau):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = niveau

    def rect(self, x0, y0, x1, y1, niveau):
        """⚠ EMPILE, ne remplace pas : un plateau haut repose sur tous ceux d'en dessous."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if 0 <= x < self.w and 0 <= y < self.h:
                    self.g[y][x] = max(self.g[y][x], niveau)

    def texte(self, marge=3):
        """⚠ LE RELIEF S'ENTOURE DE VIDE, ET LA MARGE VAUT UNE CHUTE ENTIERE.

        La plaine est un plateau comme les autres : la ou elle borde le vide, elle a une
        levre, donc une falaise de trois cases. Sans marge, cette falaise du BORD DU MONDE
        tomberait hors du cadre -- et une robe hors du cadre est une tuile impeignable."""
        vide = '~' * (self.w + 2 * marge)
        lignes = [vide] * marge
        for row in self.g:
            lignes.append('~' * marge
                          + ''.join('.' if v == 0 else str(v) for v in row)
                          + '~' * marge)
        lignes += [vide] * marge
        return '\n'.join(lignes) + '\n'

    def ecrire(self, nom):
        racine = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        chemin = os.path.join(racine, 'guides', nom)
        texte = self.texte()
        open(chemin, 'w', encoding='utf-8').write(texte)
        lignes = texte.rstrip('\n').split('\n')
        print("guides/%s : %d x %d (monde %d x %d, borde de vide)"
              % (nom, len(lignes[0]), len(lignes), self.w, self.h))


# ---------------------------------------------------------------- le district lacustre

TORE = ["0001", "0010", "1011", "0111"]


def lacs(g, ox, oy, di=0, dj=0):
    """Le motif des petits lacs est un TORE DE DE BRUIJN 4x4 : ses seize fenetres 2x2 sont
    toutes distinctes, donc chaque case entre quatre lacs voit une combinaison differente
    d'encoches. Les seize index « tous cardinaux » tombent ainsi d'un seul district, la ou
    les disperser en aurait demande le triple.

    Emprise : colonnes ox..ox+10, rangees oy..oy+10, terre comprise -- la bordure fait
    partie de l'accident, sans elle les fenetres du bord ne sont plus completes.
    Le decalage (di, dj) change le dessin sans changer le compte."""
    for i in range(5):
        for j in range(5):
            if TORE[(j + dj) % 4][(i + di) % 4] == '1':
                g.put(ox + 1 + 2 * i, oy + 1 + 2 * j, 0)


# ---------------------------------------------------------------- les cretes a rameaux

QE = [0, 1, 0, 1, 1, 0, 1, 1, 1, 0]
QW = [0, 1, 1, 1, 0, 1, 1, 0, 1, 0]
QN = [0, 1, 1, 0, 1, 0, 1, 1, 1, 0]
QS = [0, 1, 1, 1, 0, 1, 0, 1, 1, 0]


def cretes_v(g, ox, oy, qe, qw, niveau=2):
    """Une arete droite bordee d'un EPAULEMENT DISCONTINU. Le motif de l'epaulement porte
    les quatre voisinages utiles, ce qui donne les seize index « trois cardinaux », les
    pointes et les cretes etroites.
    Emprise : colonnes ox+2..ox+6, rangees oy+2..oy+11."""
    for k in range(10):
        g.put(ox + 2, oy + 2 + k, niveau)
        if qe[k]:
            g.put(ox + 3, oy + 2 + k, niveau)
        g.put(ox + 6, oy + 2 + k, niveau)
        if qw[k]:
            g.put(ox + 5, oy + 2 + k, niveau)


def cretes_h(g, ox, oy, qn, qs, niveau=2):
    """Les memes, couchees est-ouest.
    Emprise : colonnes ox+2..ox+10, rangees oy..oy+6."""
    for k in range(9):
        g.put(ox + 2 + k, oy + 1, niveau)
        if qn[k]:
            g.put(ox + 2 + k, oy, niveau)
        g.put(ox + 2 + k, oy + 5, niveau)
        if qs[k]:
            g.put(ox + 2 + k, oy + 6, niveau)


# ---------------------------------------------------------------- le chaos rocheux


def coude(g, x, y, dx, dy, niveau=2):
    """Deux cardinaux adjacents SANS diagonale. Ne s'obtient d'aucune masse pleine."""
    g.put(x, y, niveau)
    g.put(x + dx, y, niveau)
    g.put(x, y + dy, niveau)


def fourche(g, x, y, absent, niveau=2):
    """Trois cardinaux sans diagonale. Pas davantage dans une masse pleine."""
    g.put(x, y, niveau)
    for direction, dx, dy in [('N', 0, -1), ('S', 0, 1), ('W', -1, 0), ('E', 1, 0)]:
        if direction != absent:
            g.put(x + dx, y + dy, niveau)


def aretes(g, ox, oy, niveau=2):
    """Les quatre coudes et les quatre fourches, en chaos rocheux.
    Emprise : colonnes ox..ox+11, rangees oy..oy+8."""
    coude(g, ox + 1, oy, 1, 1, niveau)         # E+S
    coude(g, ox + 5, oy + 1, 1, -1, niveau)    # N+E
    coude(g, ox + 9, oy + 1, -1, -1, niveau)   # N+W
    coude(g, ox + 3, oy + 4, -1, 1, niveau)    # S+W
    fourche(g, ox + 7, oy + 4, 'E', niveau)    # N+S+W
    fourche(g, ox + 10, oy + 4, 'W', niveau)   # N+E+S
    fourche(g, ox + 1, oy + 7, 'N', niveau)    # E+S+W
    fourche(g, ox + 5, oy + 7, 'S', niveau)    # N+E+W


# ---------------------------------------------------------------- l'escarpement


def escarpement(g, ox, lip, largeur, spurs, banquette):
    """ESCARPEMENT COTIER A CONTREFORTS. Un contrefort est une colonne dont le bord sud
    AVANCE sur ses voisines : elle est donc devant, et porte son angle.

    ⚠ UN JEU D'EPERONS DOIT PORTER LES CINQ CONFIGURATIONS -- bout ouest, paire mitoyenne,
    eperon seul, bout est -- sans quoi il manque des pans a angle. Et il faut TROIS
    colonnes plates consecutives quelque part, sinon le pan (muet, muet) n'existe pas.
    La forme se varie, la grammaire non.

    ⚠ IL EN FAUT DES DEUX SORTES, pour une raison de terrain et non de mecanique. Avec
    banquette, les eperons posent leur PIED pendant que la paroi voisine tombe encore :
    c'est la seule facon d'avoir les cinq pieds a angle. Sans banquette, leur chute de six
    cases passe par le CORPS 1, ce qu'une chute de trois ne fait jamais.

    ⚠ La banquette est QUATRE rangees sous la levre de l'eperon, et d'etage 1 : `fall_at`
    sonde la case juste sous le pied -- une banquette posee sur le trajet ne l'arrete pas
    -- et a l'etage 2 la robe rencontrerait son propre niveau, s'ecreterait, et ne
    poserait aucun pied.

    Emprise, robes comprises : colonnes ox..ox+largeur-1, rangees lip-2..lip+9."""
    g.rect(ox, lip - 2, ox + largeur - 1, lip, 2)
    for c in spurs:
        g.put(ox + c, lip + 1, 2)
        g.put(ox + c, lip + 2, 2)
    if banquette:
        for c in spurs:
            g.put(ox + c, lip + 6, 1)


# ---------------------------------------------------------------- le menu fretin


def ilot(g, x, y, niveau=1):
    """Une seule case sans voisin : l'index 0.
    ⚠ IL LUI FAUT SA CHUTE ENTIERE SOUS LUI. Un ilot d'etage 2 tombe de six cases, et
    au-dessous il ne doit rencontrer ni son propre niveau ni le bord du cadre."""
    g.put(x, y, niveau)


def contact_diagonal(g, x, y, montant, niveau=1):
    """Deux cases qui ne se touchent QUE par le coin.
    ⚠ La canonicalisation du blob le JETTE -- un coin diagonal isole ne change pas la
    silhouette de la tuile -- mais le reseau dual a une tuile pour lui. Un guide complet en
    blob 47 n'est donc PAS automatiquement complet a cheval, et ne peut pas l'etre."""
    g.put(x, y, niveau)
    g.put(x + 1, y - 1 if montant else y + 1, niveau)
