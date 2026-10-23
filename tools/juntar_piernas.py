"""Cierra las piernas de Johnny en unos dibujos del paso, para que no ande abierto como un pato.

  py tools/juntar_piernas.py conserje-48-pistola south 4,5 3

PixelLab, de frente, abre a veces las piernas a lo ancho a mitad del paso. Aquí, en cada fila de las piernas en la
que hay hueco entre las dos, la de la izquierda se mueve hacia la derecha y la de la derecha hacia la izquierda: nada
en la entrepierna y cada vez más hacia abajo, hasta "cierre" píxeles en los pies. Nunca más de lo que deja el hueco,
así que no se montan una encima de otra. Se mueven las filas enteras, con su borde, y el dibujo sigue igual de limpio
(23 oct).

Toca solo esos dibujos de assets/sprites/<arma>.png. Si la fila de andar se rehace con tools/andar_arma.py, hay que
volver a pasar esto.
"""
import json, sys
from PIL import Image

arma, direccion = sys.argv[1], sys.argv[2]
cuales = [int(x) for x in sys.argv[3].split(",")]
cierre = int(sys.argv[4])
HOJA = f"assets/sprites/{arma}"
meta = json.load(open(f"{HOJA}.json", encoding="utf-8"))
hoja = Image.open(f"{HOJA}.png").convert("RGBA")
cw, ch = meta["cell"]
info = meta["anims"]["walk"]["dirs"][direccion]


def tramos(fila):
    """Los trozos seguidos de dibujo de una fila: [(desde, hasta)], hasta sin incluir."""
    t, desde = [], None
    for x, p in enumerate(fila + [(0, 0, 0, 0)]):
        if p[3] and desde is None:
            desde = x
        elif not p[3] and desde is not None:
            t.append((desde, x)); desde = None
    return t


for k in cuales:
    x0, y0 = (info.get("col", 0) + k) * cw, info["row"] * ch
    casilla = hoja.crop((x0, y0, x0 + cw, y0 + ch))
    px = casilla.load()
    filas = [[px[x, y] for x in range(cw)] for y in range(ch)]
    # Las piernas: desde la primera fila (de la mitad para abajo) con hueco en medio hasta el píxel más bajo
    abajo = max(y for y in range(ch) if any(p[3] for p in filas[y]))
    arriba = next(y for y in range(ch // 2, abajo + 1) if len(tramos(filas[y])) >= 2)
    # Cuánto se mueve cada fila: crece hacia abajo hasta "cierre" y en las 4 últimas (el zapato) es lo mismo, para
    # no torcerlo. Nunca tanto que las piernas se toquen (queda 1 píxel de hueco), nunca menos que la fila de
    # arriba (si no, salen muescas en el borde) y como mucho 1 más que ella (el borde baja en escalera)
    huecos, mover = {}, {}
    pie = abajo - 3
    for y in range(arriba, abajo + 1):
        t = tramos(filas[y])
        if len(t) < 2:
            mover[y] = 0
            continue
        # el hueco más ancho de la fila es el de entre las piernas
        i = max(range(len(t) - 1), key=lambda j: t[j + 1][0] - t[j][1])
        huecos[y] = (t[i], t[i + 1])
        hueco = t[i + 1][0] - t[i][1]
        mover[y] = min(round(cierre * min(1.0, (y - arriba + 1) / (pie - arriba + 1))), (hueco - 1) // 2)
    for y in range(abajo, arriba, -1):   # sin muescas: si una fila puede menos, las de encima tampoco más
        mover[y - 1] = min(mover[y - 1], mover[y])
    for y in range(arriba + 1, abajo + 1):
        mover[y] = min(mover[y], mover[y - 1] + 1)
    for y in range(arriba, abajo + 1):
        if y not in huecos or mover[y] <= 0:
            continue
        fin_izq, empieza_der = huecos[y][0][1], huecos[y][1][0]
        m = mover[y]
        nueva = [(0, 0, 0, 0)] * cw
        for x in range(fin_izq):
            if filas[y][x][3] and x + m < cw:
                nueva[x + m] = filas[y][x]
        for x in range(empieza_der, cw):
            if filas[y][x][3] and x - m >= 0:
                nueva[x - m] = filas[y][x]
        for x in range(cw):
            px[x, y] = nueva[x]
    hoja.paste(casilla, (x0, y0))
    print(f"{direccion} {k}: piernas de la fila {arriba} a la {abajo}, hasta {cierre} píxeles hacia dentro")

hoja.save(f"{HOJA}.png", optimize=True)
