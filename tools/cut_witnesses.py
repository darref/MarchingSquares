"""DECOUPER UN TEMOIN PAR TUILE DANS LES MONDES QUI LES PORTENT.

    python3 tools/cut_witnesses.py monde.txt "OU: cle@x.y,..." > guide.txt

⚠ C'EST LA METHODE DES DEMONSTRATIONS DE FALAISE, reprise : « decoupee dans le guide, plus
dessinee a la main ». Un vivier de reliefs 7x5 ne produit que 29 tuiles ; les mondes livres en
portent 51. On ne fabrique donc pas le temoin, on va le CHERCHER la ou il vit.

⚠ ET LA DECOUPE PEUT MENTIR : le bord de la fenetre devient du vide, ce qui change le
voisinage -- donc la tuile. Le controle n'est pas optionnel, il EST la mesure : on repasse le
guide au banc et on compare la liste des tuiles a celle qu'on visait.

La fenetre est haute vers le NORD : une face qui couvre ma voisine vient d'une levre jusqu'a
neuf rangees plus haut, et la couper la ferait disparaitre.
"""
import sys

LARGE, HAUT, AU_DESSUS = 9, 15, 11
MARGE, COLONNES = 3, 5


def main():
    monde = [l.rstrip("\n") for l in open(sys.argv[1]) if l.strip()]
    largeur = max(len(l) for l in monde)
    monde = [l.ljust(largeur, "~") for l in monde]
    ou = {}
    for arg in sys.argv[2:]:
        for pair in arg.split("OU:")[-1].strip().split(","):
            if "@" in pair:
                cle, pos = pair.split("@")
                x, y = pos.split(".")
                ou[int(cle)] = (int(x), int(y))

    coupes = []
    for cle in sorted(ou):
        x, y = ou[cle]
        gauche = x - LARGE // 2
        haut = y - AU_DESSUS
        bloc = []
        for j in range(HAUT):
            ligne = ""
            for i in range(LARGE):
                px, py = gauche + i, haut + j
                if 0 <= px < largeur and 0 <= py < len(monde):
                    ligne += monde[py][px]
                else:
                    ligne += "~"
            bloc.append(ligne)
        coupes.append(bloc)

    # ⚠ MODE SEPARE : chaque temoin comme son propre relief, pour que `Thickness` les juge UN
    # PAR UN. Une planche entiere refusee ne dit pas combien de temoins sont bons ; cinquante
    # et un reliefs le disent.
    if "--separes" in sys.argv:
        for bloc in coupes:
            for l in bloc:
                print(l)
            print()
        sys.stderr.write("%d temoins, separes\n" % len(coupes))
        return
    pas = LARGE + MARGE
    bande = HAUT + 12 + MARGE
    lignes = []
    for depart in range(0, len(coupes), COLONNES):
        rangee = coupes[depart:depart + COLONNES]
        for j in range(bande):
            ligne = ""
            for bloc in rangee:
                ligne += (bloc[j] if j < len(bloc) else "~" * LARGE) + "~" * MARGE
            lignes.append(ligne)
    partout = max(len(l) for l in lignes)
    for l in lignes:
        print("~" * MARGE + l.ljust(partout, "~") + "~" * MARGE)
    sys.stderr.write("%d temoins decoupes, guide %d x %d\n"
                     % (len(coupes), partout + 2 * MARGE, len(lignes)))


main()
