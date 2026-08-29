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

SILHOUETTES = [5,7,20,23,28,29,31,65,71,80,92,112,113,116,119,124,127,193,197,199,209,221,
               223,241,247,253,255]


RETIRES = 0
DIAG_ERGOT = True   # la regle ; `--ergot=voisine` rejoue l'ancienne


def libres(sil):
    """Les bits dont la precondition ne depend que de la silhouette."""
    out = []
    if not sil & E: out.append(BORD_E)
    if not sil & W: out.append(BORD_W)
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
    if sil & N and not sil & E: out.append(ABOVE_E)
    if sil & N and not sil & W: out.append(ABOVE_W)
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
    return True


def forme():
    total, par_sil = 0, {}
    for sil in SILHOUETTES:
        base = libres(sil)
        vus = set()
        for n in range(1 << len(base)):
            bits = 0
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


def main():
    global RETIRES, DIAG_ERGOT
    for a in sys.argv[1:]:
        if a == "--ergot=voisine":
            DIAG_ERGOT = False
        if a.startswith("--sans="):
            for nom in a.split("=")[1].split(","):
                RETIRES |= NOMS[nom]
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
            for b in [1 << i for i in range(17)]:
                if bits & b and b not in libres(sil) and b not in (FLUSH_E, FLUSH_W, BELOW_E, BELOW_W):
                    dehors.append((k, "bit %d sans precondition" % b)); break
        print("  CONTROLE : %d tuiles rencontrees, %d HORS de la forme" % (len(vues), len(dehors)))
        for k, quoi in dehors[:8]:
            print("     %d (silhouette %d, bits %d) : %s" % (k, k & 0xff, k >> 8, quoi))


main()
