"""LE GUIDE QUI EXERCE LE VOCABULAIRE : un temoin par tuile, cherche et non dessine.

    LADDER_RELIEFS=vivier.txt godot --headless ... proof/ladder.gd     (donne les TEMOINS)
    python3 tools/build_witness_guide.py vivier.txt temoins*.log > guides/temoins.txt

⚠ ET C'EST LA MEME METHODE QUE LES ILOTS DU DEPOT : « l'ilot est calcule, jamais dessine », et
sa levre voisine « se CHERCHE, elle ne se deduit pas ». Ici on ne cherche meme pas : on ENUMERE
tous les reliefs epais d'une fenetre, on note lequel produit chaque tuile en premier, et le
guide est la juxtaposition de ces temoins-la.

⚠ ET LES TEMOINS SE POSENT AVEC LEUR MARGE, JAMAIS COLLES. Un accident ne se pose pas sous un
autre -- la lecon est au dossier depuis `minimal.txt` : un coude tombe au sud d'une crete
devient une fourche, et l'index disparait du guide. Chaque temoin garde donc trois cases de
vide autour de lui, et une chute entiere en dessous.
"""
import sys


def lire_vivier(path):
    reliefs, bloc = [], []
    for ligne in open(path):
        ligne = ligne.rstrip("\n")
        if ligne:
            bloc.append(ligne)
        elif bloc:
            reliefs.append(bloc); bloc = []
    if bloc:
        reliefs.append(bloc)
    return reliefs


def main():
    vivier = lire_vivier(sys.argv[1])
    temoins = {}
    for path in sys.argv[2:]:
        for ligne in open(path):
            if "TEMOINS:" in ligne:
                for pair in ligne.split("TEMOINS:")[1].strip().split(","):
                    if "=" in pair:
                        cle, n = pair.split("=")
                        # ⚠ LE PLUS PETIT INDICE GAGNE, comme l'export garde le plus petit rang
                        # d'occurrence : un dictionnaire ne promet aucun ordre, et un guide qui
                        # changerait d'une execution a l'autre serait indefendable.
                        n = int(n)
                        if int(cle) not in temoins or n < temoins[int(cle)]:
                            temoins[int(cle)] = n
    sys.stderr.write("%d tuiles, %d temoins distincts\n"
                     % (len(temoins), len(set(temoins.values()))))

    choisis = sorted(set(temoins.values()))
    marge, colonnes = 3, 6
    haut = max(len(vivier[n]) for n in choisis)
    large = max(len(vivier[n][0]) for n in choisis)
    # Une chute d'etage 2 dans le vide descend de neuf rangees : la bande en garde douze.
    bande = haut + 12 + marge
    pas = large + marge
    lignes = []
    for depart in range(0, len(choisis), colonnes):
        rangee = choisis[depart:depart + colonnes]
        for y in range(bande):
            ligne = ""
            for n in rangee:
                relief = vivier[n]
                if y < len(relief):
                    ligne += relief[y] + "~" * marge
                else:
                    ligne += "~" * pas
            lignes.append(ligne)
    partout = max(len(l) for l in lignes)
    for l in lignes:
        print("~" * marge + l + "~" * (partout - len(l) + marge))
    sys.stderr.write("guide : %d x %d cases, %d temoins\n"
                     % (partout + 2 * marge, len(lignes), len(choisis)))


main()
