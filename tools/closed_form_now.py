"""LA FORME FERMEE DU VOCABULAIRE DE SURFACE, AU JEU DE BITS D'AUJOURD'HUI.

⚠ ET C'EST LA BORNE HAUTE, celle qu'aucune enumeration de reliefs ne donne. Elargir une
famille de mondes fait monter la borne BASSE et ne touche jamais la haute : c'est pour ca
que la 7x7 (10,5 millions de reliefs) n'aurait rien prouve.

Chaque bit a une precondition lisible dans la silhouette -- et, pour quatre d'entre eux, dans
les bits deja poses. Sa valeur, elle, depend de cases HORS de la fenetre 3x3 : l'exterieur
etant libre sur un plan non borne, les deux valeurs sont realisables des que la precondition
tient. On compte donc les assignations valides, silhouette par silhouette.

⚠ ET LA TRANSCRIPTION SE VERIFIE, elle ne se croit pas : toute tuile REELLEMENT rencontree
doit tomber dans la forme calculee. Une seule dehors, et c'est la transcription qui est
fausse -- pas le monde.
"""
import sys

N, E, S, W = 1, 4, 16, 64
NE, SE, SW, NW = 2, 8, 32, 128
CARD = [N, E, S, W]
DIAG = [NW, NE, SE, SW]

BORD_E, BORD_W = 1, 2
NORTH_QUIET = 1024
ABOVE_E, ABOVE_W = 2048, 4096
FLUSH_E, FLUSH_W = 8192, 16384
BELOW_E, BELOW_W = 32768, 65536
# ⚠ LA LEVRE SEULE, NEE DU TRANSFERT DE LA CRETE. Depuis que la tuile de levre porte le haut
# de sa propre face, son BANDEAU a un bord lateral -- et ce bord se trace ou se tait selon ce
# qu'il y a a cote. Deux bits, absents de ce fichier tant que le transfert vivait derriere son
# drapeau : la forme fermee annoncait donc une borne d'un modele qui n'etait plus le modele.
LIP_ALONE_E, LIP_ALONE_W = 131072, 262144
# L'ergot d'un coin NORD : « ma diagonale ne trace pas ce cote-la ». `4 << coin`, coin 0 = NO.
ERGOT_NW, ERGOT_NE = 4, 8

# ⚠ ET LES DIAGONALES SUD SONT RETIREES -- theoreme, voir `Brink.shave`. Une diagonale n'est
# enregistree que si ses deux cardinaux sont pleins ; pour `SE` cela veut dire `S` PLEIN, et
# des L2 le sud ne se trace jamais. Le coin entre deux bords qu'on ne trace pas n'existe pas
# dans le trace : `SE` ne peut rien y changer, ni `SO`. Mesure : les 27 tombent a 17, la forme
# de 126 a 82 cles, et les DESSINS ne bougent pas -- 43 avant, 43 apres.
LES_27 = [5,7,20,23,28,29,31,65,71,80,92,112,113,116,119,124,127,193,197,199,209,221,
          223,241,247,253,255]
SILHOUETTES = sorted({s & ~(SE | SW) for s in LES_27})


RETIRES = 0
DIAG_ERGOT = True   # la regle ; `--ergot=voisine` rejoue l'ancienne


def forces(sil):
    """LES BITS QUE L'EPAISSEUR REND OBLIGATOIRES -- pas libres, pas absents : FORCES.

    ⚠ ET C'EST LA PREMISSE DE CE FICHIER QUI ETAIT FAUSSE. « L'exterieur etant libre sur un
    plan non borne, les deux valeurs sont realisables des que la precondition tient » : vrai
    d'un plan quelconque, FAUX sous min trois, ou l'epaisseur contraint aussi le dehors.

    L'argument, en trois pas, et il ne tient qu'aux diagonales NORD :
      1. NE vide -- enregistre, donc N et E pleins -- oblige la course de la rangee du nord a
         s'etendre vers l'OUEST, faute de pouvoir aller a l'est. Donc NO est PLEIN ;
      2. NO plein au-dessus d'un ouest VIDE, c'est une levre : sa face couvre mon ouest ;
      3. donc `BORD_W` vaut un, toujours. Et comme `ABOVE_W` et `BELOW_W` exigent que je
         trace vraiment ce cote-la, ils tombent avec.

    Le miroir vaut a l'est. Aucun autre coin ne force : une diagonale SUD pleine ne met
    aucune levre au-dessus de ma cardinale vide -- une robe se pose sous une levre, jamais
    au-dessus.

    Mesure : la borne haute passe de 125 cles / 31 dessins a ce que dit `--liste`, et les
    huit dessins qui tombent sont exactement ceux qu'aucun monde n'a jamais poses.
    """
    out = 0
    if sil & N and sil & E and not sil & NE and not sil & W:
        out |= BORD_W
    if sil & N and sil & W and not sil & NW and not sil & E:
        out |= BORD_E
    return out


def libres(sil):
    """Les bits dont la precondition ne depend que de la silhouette."""
    out = []
    tenus = forces(sil)
    if not sil & E and not tenus & BORD_E: out.append(BORD_E)
    if not sil & W and not tenus & BORD_W: out.append(BORD_W)
    if not sil & N: out.append(NORTH_QUIET)
    for coin in range(4):
        a, b = coin, (coin + 3) % 4
        if sil & CARD[a] and sil & CARD[b] and not sil & DIAG[coin]:
            # ⚠ PAR LA DIAGONALE : UN SEUL BIT PAR COIN, et c'est un FAIT du monde -- « une
            # face couvre ma diagonale » -- au lieu de deux DECISIONS de voisines.
            if DIAG_ERGOT:
                # ⚠ AUX COINS SUD, LA DIAGONALE EST TOUJOURS COUVERTE -- regle de la levre :
                # ma cardinale pleine a son sud vide, donc c'est une levre, donc sa face est
                # la. Constante, pas bit.
                if coin < 2:
                    out.append(4 << coin)
                continue
            # ⚠ ET L'ERGOT DONT LE PARTENAIRE EST AU SUD N'EST PAS UN BIT : des L2 le sud ne
            # se trace jamais, donc il vaudrait TOUJOURS 1. Une constante deguisee en bit
            # double le vocabulaire potentiel sans distinguer quoi que ce soit.
            if b != 2:
                out.append(4 << coin)
            if a != 2:
                out.append(64 << coin)
    # ⚠ ET `ABOVE_*` NE VIT QUE SI LE COTE EST VRAIMENT TRACE. Il ne fait qu'une chose --
    # ramener le bord lateral au ras a son premier pixel -- donc si le BORD a deja fait taire
    # ce cote-la, il ne change plus rien. La precondition complete est dans `valide()`, comme
    # celle de `BELOW_*` qui est exactement la meme d'un cran plus bas. Mesure : la sonde du
    # banc a designe ce bit en peignant la forme, 7 confusions de chaque cote.
    if sil & N and not sil & E: out.append(ABOVE_E)
    if sil & N and not sil & W: out.append(ABOVE_W)
    # ⚠ LA LEVRE SEULE : SA PRECONDITION EST TOUTE DANS LA FENETRE, sa valeur toute dehors.
    # Le bit se pose quand je suis une LEVRE (sud vide), que ma voisine laterale EXISTE a mon
    # etage (le cardinal est plein) et qu'elle n'est PAS elle-meme une levre -- c'est-a-dire
    # que sa case du sud est pleine, et sa case du sud est ma DIAGONALE. Trois faits de la
    # silhouette, donc une precondition lisible ici.
    #
    # Sa valeur, elle, depend de trois choses hors de la fenetre : la voisine peut etre une
    # levre elle aussi, une robe peut la couvrir, un etage plus haut peut l'enterrer. Les
    # trois sont libres sur un plan non borne -- donc le bit l'est aussi.
    #
    # ⚠ ET « SA VOISINE N'EST PAS UNE LEVRE » N'EST PAS LISIBLE DANS MA SILHOUETTE, meme si
    # ca en a l'air : c'est le sud de ma voisine, donc ma DIAGONALE -- et la canonicalisation
    # JETTE une diagonale dont les deux cardinaux ne sont pas tous deux pleins. Une levre a
    # son sud vide, donc son SE et son SO sont toujours a zero : le tester ici rendrait la
    # precondition impossible, et le bit disparaitrait de la forme alors que le monde le pose.
    # Premiere version ecrite ainsi, mesure : 101 cles, exactement comme sans le bit.
    #
    # ⚠ MAIS UNE ENCOCHE AU NORD-OUEST INTERDIT `LIP_ALONE_E`, ET C'EST UN THEOREME. Deuxieme
    # fois que l'epaisseur contraint le DEHORS la ou ce fichier le croyait libre -- la
    # premiere avait fait tomber la borne de 31 a 23 dessins.
    #
    #   1. l'encoche est ENREGISTREE, donc `N` et `O` sont pleins et (x-1, y-1) est VIDE ;
    #   2. la course pleine de la colonne x-1 qui contient (x-1, y) ne peut donc pas MONTER :
    #      min trois la fait descendre, et (x-1, y+1) est PLEIN ;
    #   3. je suis une levre, donc (x, y+1) est VIDE ; sa course vide ne peut pas aller vers
    #      l'ouest -- (x-1, y+1) est plein -- donc elle va vers l'EST : (x+1, y+1) est VIDE ;
    #   4. la voisine de l'est a donc son sud vide : c'est une LEVRE, et le bit vaut zero.
    #
    # Miroir exact a l'est : une encoche au NORD-EST interdit `LIP_ALONE_W`.
    notch_nw = sil & N and sil & W and not sil & NW
    notch_ne = sil & N and sil & E and not sil & NE
    if not sil & S and sil & E and not notch_nw: out.append(LIP_ALONE_E)
    if not sil & S and sil & W and not notch_ne: out.append(LIP_ALONE_W)
    return [b for b in out if not b & RETIRES]


def valide(sil, bits):
    """Les quatre bits conditionnes par les autres bits."""
    trace_n = not sil & N and not bits & NORTH_QUIET
    trace_e = not sil & E and not bits & BORD_E
    trace_w = not sil & W and not bits & BORD_W
    if bits & FLUSH_E and not (trace_n and sil & E): return False
    if bits & FLUSH_W and not (trace_n and sil & W): return False
    if bits & BELOW_E and not (sil & S and trace_e): return False
    if bits & BELOW_W and not (sil & S and trace_w): return False
    if bits & ABOVE_E and not trace_e: return False
    if bits & ABOVE_W and not trace_w: return False
    # ⚠ ET LES DEUX `LIP_ALONE` NE SE POSENT JAMAIS ENSEMBLE -- theoreme, et il tient en une
    # ligne : je suis une levre, donc (x, y+1) est VIDE, et min trois veut sa course vide a
    # trois au moins. Une course de trois qui contient x contient x-1 ou x+1 : au moins une de
    # mes deux voisines laterales a donc son sud vide, donc est une levre, donc SON bit est a
    # zero. Aucune levre au monde ne peut etre seule des deux cotes a la fois.
    if bits & LIP_ALONE_E and bits & LIP_ALONE_W: return False
    # ⚠ ET UNE LEVRE A ENCOCHE NE PEUT PAS TAIRE SON COTE SANS POSER SON ERGOT. Troisieme
    # theoreme, et c'est la sonde qui l'a rendu -- j'avais CONSTRUIT le contre-exemple, et le
    # modele a rendu la cle avec l'ergot en plus. Les trois routes pour eteindre le bit sont
    # fermees, une par une :
    #
    #   - « ma voisine de l'ouest est une levre » : impossible. L'encoche au nord-ouest force
    #     (x-1, y+1) a etre PLEIN -- la course pleine de sa colonne ne peut que descendre --
    #     donc elle n'est pas une levre ;
    #   - « elle est enterree sous un etage plus haut » : le bit ne s'eteint que si ce qu'on
    #     VOIT a sa place est une levre ; sa colonne aurait alors du vide au-dessus (l'encoche)
    #     ET au-dessous (sa propre face), donc une course pleine de UN. Fin, donc interdit ;
    #   - « une face la couvre » : possible -- mais une face est une colonne CONTINUE qui
    #     descend de sa levre, laquelle est au moins deux rangees au nord. Elle couvre donc
    #     aussi (x-1, y-1), c'est-a-dire MON ENCOCHE, et l'ergot se pose.
    #
    # Miroir exact a l'est.
    if not sil & S:
        if sil & N and sil & W and not sil & NW:
            if not bits & LIP_ALONE_W and not bits & ERGOT_NW: return False
        if sil & N and sil & E and not sil & NE:
            if not bits & LIP_ALONE_E and not bits & ERGOT_NE: return False
    return True


def forme():
    total, par_sil = 0, {}
    for sil in SILHOUETTES:
        base = libres(sil)
        vus = set()
        for n in range(1 << len(base)):
            bits = forces(sil)
            for i, b in enumerate(base):
                if n >> i & 1: bits |= b
            for extra in range(16):
                plus = 0
                if extra & 1: plus |= FLUSH_E
                if extra & 2: plus |= FLUSH_W
                if extra & 4: plus |= BELOW_E
                if extra & 8: plus |= BELOW_W
                if plus & RETIRES: continue
                if valide(sil, bits | plus):
                    vus.add(bits | plus)
        par_sil[sil] = len(vus)
        total += len(vus)
    return total, par_sil


NOMS = {"bord": BORD_E | BORD_W, "nq": NORTH_QUIET, "ergot": 1020,
        "above": ABOVE_E | ABOVE_W, "flush": FLUSH_E | FLUSH_W,
        "below": BELOW_E | BELOW_W}


def toutes():
    """La liste complete des tuiles de la forme : c'est elle qu'il faut DECIDER, une par une."""
    out = []
    for sil in SILHOUETTES:
        base = libres(sil)
        vus = set()
        for n in range(1 << len(base)):
            bits = forces(sil)
            for i, b in enumerate(base):
                if n >> i & 1: bits |= b
            for extra in range(16):
                plus = 0
                if extra & 1: plus |= FLUSH_E
                if extra & 2: plus |= FLUSH_W
                if extra & 4: plus |= BELOW_E
                if extra & 8: plus |= BELOW_W
                if plus & RETIRES: continue
                if valide(sil, bits | plus):
                    vus.add(bits | plus)
        for b in vus:
            out.append(sil | (b << 8))
    return sorted(out)


def main():
    global RETIRES, DIAG_ERGOT
    for a in sys.argv[1:]:
        if a == "--ergot=voisine":
            DIAG_ERGOT = False
        if a.startswith("--sans="):
            for nom in a.split("=")[1].split(","):
                RETIRES |= NOMS[nom]
    if "--liste" in sys.argv:
        print(",".join(str(k) for k in toutes()))
        return
    total, par_sil = forme()
    print("=== LA FORME FERMEE, AU JEU DE BITS D'AUJOURD'HUI ===")
    print("  %d tuiles de surface sur %d silhouettes" % (total, len(SILHOUETTES)))
    gros = sorted(par_sil.items(), key=lambda kv: -kv[1])[:6]
    print("  les plus chargees : %s" % ", ".join("%d en %d" % kv for kv in gros))
    petites = sum(1 for v in par_sil.values() if v == 1)
    print("  silhouettes a une seule tuile : %d" % petites)
    fichiers = [a for a in sys.argv[1:] if not a.startswith("--")]
    if fichiers:
        vues = set()
        for l in open(fichiers[0]):
            if "POSEES:" in l or "TUILES:" in l:
                cle = "POSEES:" if "POSEES:" in l else "TUILES:"
                vues |= {int(k) for k in l.split(cle)[1].strip().split(",")}
        dehors = []
        for k in vues:
            sil, bits = k & 0xff, k >> 8
            if sil not in SILHOUETTES:
                dehors.append((k, "silhouette hors des 27")); continue
            if not valide(sil, bits):
                dehors.append((k, "bits impossibles")); continue
            if bits & forces(sil) != forces(sil):
                dehors.append((k, "bit force par l'epaisseur, absent")); continue
            for b in [1 << i for i in range(17)]:
                if (bits & b and b not in libres(sil) and not b & forces(sil)
                        and b not in (FLUSH_E, FLUSH_W, BELOW_E, BELOW_W)):
                    dehors.append((k, "bit %d sans precondition" % b)); break
        print("  CONTROLE : %d tuiles rencontrees, %d HORS de la forme" % (len(vues), len(dehors)))
        for k, quoi in dehors[:8]:
            print("     %d (silhouette %d, bits %d) : %s" % (k, k & 0xff, k >> 8, quoi))


main()
