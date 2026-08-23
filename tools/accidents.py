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

import math
import os


def mini(a, b):
    return a if a < b else b


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

    def texte(self, rivage=4, marge=3):
        """LE RIVAGE, PUIS LE VIDE.

        ⚠ LA PLAINE EST DU DECOR, MAIS ELLE A UN ROLE : montrer que dans le jeu l'etage 0
        sera borde de falaises comme les autres. Une seule case d'epaisseur ne le montre
        pas -- on ne voit ni la masse pleine, ni un vrai coin. Il lui en faut plusieurs.

        ⚠ ET ELLE NE DOIT PAS ETRE RECTANGULAIRE. Le cadre du fichier est un artefact ;
        un rivage droit le donne a voir et fait ressembler le monde a une decoupe. La
        profondeur du rivage ondule donc le long de la cote, doucement -- deux sinus de
        periodes differentes, jamais du bruit case par case, qui donnerait une dentelure.

        ⚠ ON N'ENLEVE JAMAIS DE PLAINE, ON EN AJOUTE. Le rectangle d'origine reste plain
        en entier : les robes y tombent et y atterrissent, et raboter dessous les ferait
        toutes changer de role. Le rivage se pose AUTOUR.

        ⚠ ET LE VIDE VAUT UNE CHUTE ENTIERE au-dela : la plaine borde le vide, donc elle a
        une levre et une falaise de trois cases. Sans cette marge, la falaise du bord du
        monde tomberait hors du cadre -- et une robe hors du cadre est impeignable."""
        # ⚠ LE CADRE TIENT COMPTE DE L'AMPLITUDE. Une vague qui AJOUTE de la profondeur
        # mange la marge de vide sous elle : la ou le rivage descend le plus bas, sa falaise
        # tomberait hors du cadre. Le bord vaut donc rivage + amplitude + marge.
        bord = rivage + self.AMPLITUDE + marge
        largeur = self.w + 2 * bord
        hauteur = self.h + 2 * bord
        lignes = []
        for y in range(hauteur):
            ligne = ''
            for x in range(largeur):
                dx, dy = x - bord, y - bord
                if 0 <= dx < self.w and 0 <= dy < self.h:
                    v = self.g[dy][dx]
                    ligne += '.' if v == 0 else str(v)
                    continue
                # Distance de Tchebychev au rectangle d'origine, et la profondeur voulue
                # a cet endroit-la de la cote.
                ecart = max(0 - dx, dx - (self.w - 1), 0, 0 - dy, dy - (self.h - 1))
                ligne += '.' if ecart <= self._profondeur(dx, dy, rivage) else '~'
            lignes.append(ligne)
        return '\n'.join(lignes) + '\n'

    ## De combien la vague peut CREUSER en plus du rivage nominal.
    AMPLITUDE = 2

    @classmethod
    def _profondeur(cls, dx, dy, rivage):
        """La profondeur du rivage a cet endroit.

        ⚠ DEUX SINUS LENTS, JAMAIS DU BRUIT CASE PAR CASE. Un tirage par case donnerait
        une dentelure, pas une cote : ce qu'on veut, c'est que la profondeur derive
        doucement le long du rivage.

        ⚠ ET LA VAGUE N'AJOUTE QUE : le rivage nominal est un PLANCHER, pas une moyenne.
        Sous ce plancher on ne verrait plus ni masse pleine ni vrai coin, et la plaine
        cesserait de montrer ce qu'elle est la pour montrer."""
        onde = 0.62 * math.sin((dx + dy) * 0.21) + 0.38 * math.sin((dx - dy) * 0.37)
        # ⚠ ET ELLE SE BORNE A L'AMPLITUDE ANNONCEE. Sans ce plafond, la vague creusait
        # jusqu'a trois cases la ou le cadre n'en reservait que deux : la falaise du rivage
        # tombait hors du cadre, et seize robes devenaient impeignables.
        return rivage + mini(cls.AMPLITUDE, int(round(cls.AMPLITUDE * abs(onde) * 1.7)))

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
