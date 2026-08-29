"""ENGENDRER TOUS LES RELIEFS EPAIS D'UNE FENETRE.

    python3 tools/thick_reliefs.py LARGEUR HAUTEUR ETATS > reliefs.txt

⚠ ET C'EST LE DOMAINE SANS L'HYPOTHESE D'ALIGNEMENT. L'enumeration par blocs 3x3 alignes
etait une sous-famille -- mesure : 19 tuiles des mondes livres n'en sortaient pas, pour
l'essentiel des ergots de coin rentrant, des encoches qu'une grille alignee ne creuse pas.
Ici on engendre TOUT relief epais, donc aussi ce qu'un tampon decale produit.

Min trois : toute course entierement INTERIEURE a la fenetre fait au moins trois cases. Une
course qui touche un bord est prolongeable dehors, donc libre -- meme regle que
`window_realizable` pour les 27 silhouettes.

Sortie : un relief par bloc, lignes de `~` (le vide) et de chiffres (les etages), blocs
separes par une ligne vide. Le banc ajoute lui-meme la marge que la chute exige.
"""
import sys


def courses_ok(binaire, N):
    """⚠ ET UNE COURSE DE MATIERE DOIT FAIRE TROIS MEME AU BORD, parce que la fenetre est
    posee dans le VIDE : la marge la termine, elle ne la prolonge pas. Seules les courses de
    VIDE touchant un bord sont libres -- celles-la continuent dehors.

    Deuxieme version de cette fonction. La premiere laissait libres toutes les courses de
    bord, et `Thickness` -- le module que le pinceau consulte -- refusait 2 984 reliefs sur
    3 000. On ne reecrit pas une regle du depot, on la relit."""
    depart = 0
    for i in range(1, N + 1):
        if i == N or binaire[i] != binaire[depart]:
            court = i - depart < 3
            bord = depart == 0 or i == N
            if court and (binaire[depart] == 1 or not bord):
                return False
            depart = i
    return True


def lignes_valides(W, A):
    """⚠ L'EPAISSEUR SE JUGE PAR SILHOUETTE D'ETAGE, PAS SUR LES VALEURS. Des niveaux 1,0,1
    ont des courses de valeur longues d'une case chacune -- mais c'est la SILHOUETTE de
    l'etage 1 qui compte, et elle y fait `X.X` : un creux d'une case, donc fin. Premiere
    version fausse, prise en flagrant delit par le compte de silhouettes : 34 rencontrees
    la ou le vocabulaire epais en a 27."""
    out = []
    for n in range(A ** W):
        l, m = [], n
        for _ in range(W):
            l.append(m % A); m //= A
        if all(courses_ok([1 if v >= s else 0 for v in l], W) for s in range(1, A)):
            out.append(tuple(l))
    return out


def main():
    W, H, A = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
    lignes = lignes_valides(W, A)
    ecrire = sys.stdout.write

    # L'etat d'une colonne : pour CHAQUE silhouette, (bit, course plafonnee a 3, elle
    # touchait le haut). Une course qui se termine sans avoir atteint trois n'est tolerable
    # que si elle touchait le bord.
    def depart(l):
        return tuple(tuple((1 if v >= s else 0, 1, True) for s in range(1, A)) for v in l)

    def suivant(etat, l):
        neuf = []
        for x in range(W):
            colonne = []
            for i, s in enumerate(range(1, A)):
                bit = 1 if l[x] >= s else 0
                avant, k, haut = etat[x][i]
                if bit == avant:
                    colonne.append((bit, min(3, k + 1), haut))
                else:
                    # ⚠ MEME REGLE QU'EN LIGNE, ET JE NE L'AVAIS CORRIGEE QUE D'UN COTE :
                    # une course de MATIERE fait trois meme au bord, une course de VIDE qui
                    # touche un bord continue dehors. `Thickness` refusait encore 1 862
                    # reliefs sur 2 000 -- la ligne etait juste, la colonne non.
                    if k < 3 and (avant == 1 or not haut):
                        return None
                    colonne.append((bit, 1, False))
            neuf.append(tuple(colonne))
        return tuple(neuf)

    def fini(etat):
        # Au bas de la fenetre, la marge de vide TERMINE les courses de matiere en cours.
        for colonne in etat:
            for bit, k, _haut in colonne:
                if bit == 1 and k < 3:
                    return False
        return True

    def marche(y, grille, etat):
        if y == H:
            if not fini(etat):
                return
            for l in grille:
                ecrire("".join("~" if v == 0 else str(v - 1) for v in l) + "\n")
            ecrire("\n")
            return
        for l in lignes:
            neuf = suivant(etat, l)
            if neuf is not None:
                marche(y + 1, grille + [l], neuf)

    for l in lignes:
        marche(1, [l], depart(l))


main()
