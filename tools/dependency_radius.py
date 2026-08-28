"""JUSQU'OU FAUT-IL REGARDER POUR SAVOIR QUELLE TUILE POSER ?

    LADDER_DUMP=ctx.tsv godot --headless --path . --script res://proof/ladder.gd -- L3 F2
    python3 tools/dependency_radius.py ctx_*.tsv

⚠ C'EST LA QUESTION QUI DECIDE S'IL Y A UNE FERMETURE. Les 47 silhouettes ferment parce que
la tuile ne depend que d'une fenetre 3x3 -- 512 cas, enumerables. Le vocabulaire d'aujourd'hui
ne ferme pas parce que certains bits demandent CE QUE LA VOISINE A DECIDE DE TRACER, et sa
decision depend de SA voisine : une chaine, pas une fenetre.

Si les contextes eclates au rayon 1 se resolvent au rayon 2, la dependance est BORNEE, donc
enumerable, donc close. S'ils survivent, c'est la cascade, et il faut changer la decomposition
plutot que chercher plus loin.

Une ligne du dump : cle, mon contexte, puis celui de mes quatre voisines (« hors » au bord).
"""
import sys
from collections import defaultdict


def main():
    lignes = []
    for path in sys.argv[1:]:
        for ligne in open(path):
            ligne = ligne.rstrip("\n")
            if not ligne:
                continue
            bouts = ligne.split("\t")
            lignes.append((int(bouts[0]), bouts[1], bouts[2:6]))
    print("%d cases lues sur %d monde(s)" % (len(lignes), len(sys.argv) - 1))

    for rayon, nom in ((1, "rayon 1  (moi seul)"), (2, "rayon 2  (moi + mes quatre voisines)")):
        groupes = defaultdict(set)
        for cle, moi, autour in lignes:
            clef = moi if rayon == 1 else moi + "//" + "//".join(autour)
            groupes[clef].add(cle)
        eclates = {c: k for c, k in groupes.items() if len(k) > 1}
        cases = 0
        for cle, moi, autour in lignes:
            clef = moi if rayon == 1 else moi + "//" + "//".join(autour)
            if clef in eclates:
                cases += 1
        print("\n%s : %d contextes, %d ECLATES, %d cases concernees"
              % (nom, len(groupes), len(eclates), cases))
        for clef, cles in list(eclates.items())[:3]:
            print("    %s" % clef[:150])
            print("      -> tuiles %s" % sorted(cles))


main()
