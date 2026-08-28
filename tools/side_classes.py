"""COMBIEN DE CLASSES CHAQUE COTE DOIT-IL VRAIMENT DISTINGUER ?

    LADDER_DUMP=ctx.tsv godot --headless --path . --script res://proof/ladder.gd -- L3 F2
    python3 tools/side_classes.py ctx_*.tsv

Le recensement des jonctions dit que l'espace des especes est fini et petit -- treize par
cote -- et que la forme fermee du vocabulaire serait le PRODUIT, sur les quatre cotes, du
nombre de classes que chacun doit distinguer. Ce nombre-la ne se raisonne pas : deux especes
qui donnent TOUJOURS la meme tuile sont interchangeables, et les fusionner ne coute RIEN.

⚠ ET ON NE CONCLUT QUE DE CE QU'ON A COMPARE. Deux especes qu'aucun monde n'a jamais mises
dans le meme contexte ne sont pas « fusionnables » : elles sont NON EPROUVEES. C'est la meme
regle que pour les battues -- une rencontre qui n'a pas eu lieu ne prouve rien.
"""
import sys
from collections import defaultdict
from itertools import combinations

COTES = ["nord", "est", "sud", "ouest"]


def lire(paths):
    lignes = []
    for path in paths:
        for ligne in open(path):
            ligne = ligne.rstrip("\n")
            if not ligne:
                continue
            bouts = ligne.split("\t")
            # ⚠ LA TABLE PORTE MAINTENANT LE RAYON 2 -- les colonnes suivantes sont les
            # contextes des quatre voisines. On n'en lit ici que les trois premieres.
            cle, contexte = bouts[0], bouts[1].split("|")
            lignes.append((int(cle), int(contexte[0]), contexte[1:]))
    return lignes


def main():
    lignes = lire(sys.argv[1:])
    print("%d cases lues sur %d monde(s)" % (len(lignes), len(sys.argv) - 1))

    # LE CONTEXTE : la silhouette et les quatre especes. Une tuile qui n'en est pas une
    # fonction ne se compte par aucun produit.
    par_contexte = defaultdict(set)
    for cle, silhouette, especes in lignes:
        par_contexte[(silhouette, tuple(especes))].add(cle)
    eclates = [c for c, cles in par_contexte.items() if len(cles) > 1]
    print("contextes : %d, dont %d recoivent plusieurs tuiles" % (len(par_contexte), len(eclates)))

    total_classes = 1
    classes_par_cote = []
    for cote in range(4):
        # On tient le RESTE fixe -- la silhouette et les trois autres cotes -- et on regarde
        # ce que le cote fait varier.
        groupes = defaultdict(dict)
        for cle, silhouette, especes in lignes:
            reste = (silhouette,) + tuple(e for i, e in enumerate(especes) if i != cote)
            groupes[reste].setdefault(especes[cote], set()).add(cle)

        vues = set()
        separees = set()
        comparees = set()
        for vus in groupes.values():
            for a, b in combinations(sorted(vus), 2):
                comparees.add((a, b))
                if vus[a] != vus[b]:
                    separees.add((a, b))
            vues.update(vus)

        # Fusion de tout ce qui a ete compare sans jamais etre separe.
        parent = {e: e for e in vues}

        def racine(e):
            while parent[e] != e:
                parent[e] = parent[parent[e]]
                e = parent[e]
            return e

        for a, b in comparees - separees:
            ra, rb = racine(a), racine(b)
            if ra != rb:
                parent[ra] = rb
        classes = defaultdict(list)
        for e in vues:
            classes[racine(e)].append(e)

        jamais = len(list(combinations(sorted(vues), 2))) - len(comparees)
        print("\n--- cote %s : %d especes vues, %d classes ---"
              % (COTES[cote], len(vues), len(classes)))
        print("    paires comparees %d, dont SEPAREES %d ; jamais comparees %d"
              % (len(comparees), len(separees), jamais))
        for membres in sorted(classes.values(), key=lambda m: (-len(m), m)):
            marque = "fusionnables" if len(membres) > 1 else "SEULE       "
            print("    %s : %s" % (marque, " = ".join(sorted(membres))))
        total_classes *= len(classes)
        classes_par_cote.append({e: racine(e) for e in vues})
    print("\nPRODUIT des quatre cotes : %d   (l'alphabet brut en donnerait 13^4 = 28561)"
          % total_classes)

    # ⚠ ET LA BORNE QUI COMPTE EST PAR SILHOUETTE, PAS EN PRODUIT BRUT. Un cote dont le
    # cardinal est PLEIN n'a rien a distinguer -- il n'a pas de bord. La forme fermee est donc
    # la SOMME, sur les silhouettes, du produit des classes de ses cotes OUVERTS.
    par_silhouette = defaultdict(lambda: [set(), set(), set(), set()])
    for _cle, silhouette, especes in lignes:
        for cote in range(4):
            par_silhouette[silhouette][cote].add(classes_par_cote[cote][especes[cote]])
    borne = 0
    for silhouette, cotes in sorted(par_silhouette.items()):
        produit = 1
        for vus in cotes:
            produit *= max(1, len(vus))
        borne += produit
    print("BORNE par silhouette (somme des produits des cotes ouverts) : %d tuiles"
          % borne)
    print("  sur %d silhouettes vues" % len(par_silhouette))


main()
