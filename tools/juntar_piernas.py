"""Cierra las piernas de Johnny en unos dibujos del paso, para que no ande abierto como un pato.

  py tools/juntar_piernas.py conserje-48-pistola south 4,5 3

PixelLab, de frente, abre a veces las piernas a lo ancho a mitad del paso. Aquí, en cada fila de las piernas en la
que hay hueco entre las dos, la de la izquierda se mueve hacia la derecha y la de la derecha hacia la izquierda: nada
en la entrepierna y cada vez más hacia abajo, hasta "cierre" píxeles en los pies. Nunca más de lo que deja el hueco,
así que no se montan una encima de otra. Se mueven las filas enteras, con su borde, y el dibujo sigue igual de limpio
(23 oct). Lo fino que haya entre las piernas (el cañón de la MP5) se queda quieto; con la escopeta no vale, porque
el cañón toca los zapatos y se tuerce (y su paso agachado ya va abierto a propósito).

Hechos: pistola 4,5 (3); MP5 3,4,5 (2); bate 2,4 (3) y 3 (4); cuchillo 0 (4) y 5,6 (2).

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
    # Las piernas: desde la primera fila (de la mitad para abajo) con hueco en medio hasta el píxel más bajo, y
    # como mucho las 14 filas de encima del pie (más arriba, el hueco es el del arma con el cuerpo)
    abajo = max(y for y in range(ch) if any(p[3] for p in filas[y]))
    arriba = max(abajo - 14, next(y for y in range(ch // 2, abajo + 1) if len(tramos(filas[y])) >= 2))
    # La pierna de la izquierda es el primer trozo de la fila y la de la derecha, el último; lo que haya en medio (el
    # cañón de la MP5 o de la escopeta) se queda donde está. Cada pierna se acerca a lo que tenga al lado.
    # Cuánto se mueve cada fila: crece hacia abajo hasta "cierre" y en las 4 últimas (el zapato) es lo mismo, para
    # no torcerlo. Nunca tanto que toque lo de al lado (queda 1 píxel de hueco), nunca menos que la fila de
    # abajo (si no, salen muescas en el borde) y como mucho 1 más que la de arriba (el borde baja en escalera)
    trozos, izq, der = {}, {}, {}
    pie = abajo - 3
    for y in range(arriba, abajo + 1):
        t = tramos(filas[y])
        quiere = round(cierre * min(1.0, (y - arriba + 1) / (pie - arriba + 1)))
        # Solo son pierna los trozos de 4 píxeles o más: lo más fino es el cañón del arma
        anchos = [j for j, (a, b) in enumerate(t) if b - a >= 4]
        if not anchos:
            continue
        L, R = anchos[0], anchos[-1]

        def hasta(j, lado):
            """Lo que puede acercarse el trozo j hacia ese lado (1 = derecha) sin tocar lo de al lado."""
            k = j + lado
            if not 0 <= k < len(t):
                return quiere
            return min(quiere, (t[k][0] - t[j][1] if lado > 0 else t[j][0] - t[k][1]) - 1)

        if L == R:
            # Un trozo solo: si cae a un lado del centro es un pie más bajo que el otro y se mueve como su pierna;
            # si cruza el centro, las piernas aún van juntas y no se toca
            medio = cw // 2
            izq[y] = hasta(L, 1) if t[L][1] <= medio else (0 if t[L][0] < medio else None)
            der[y] = hasta(R, -1) if t[R][0] >= medio else (0 if t[R][1] > medio else None)
        elif R == L + 1:   # las dos piernas sin nada en medio: se reparten el hueco
            hueco = t[R][0] - t[L][1]
            izq[y] = min(quiere, (hueco - 1) // 2)
            der[y] = min(quiere, (hueco - 1) - (hueco - 1) // 2)
        else:
            izq[y], der[y] = hasta(L, 1), hasta(R, -1)
        trozos[y] = (t[L], t[R])
    # (None: en esa fila no está esa pierna, así que ni frena ni se mueve)
    for m in (izq, der):
        limite = None
        for y in range(abajo, arriba - 1, -1):   # sin muescas: si una fila puede menos, las de encima tampoco más
            if m.get(y) is None:
                continue
            if limite is not None:
                m[y] = min(m[y], limite)
            limite = m[y]
        antes = 0
        for y in range(arriba, abajo + 1):
            if m.get(y) is None:
                continue
            m[y] = min(m[y], antes + 1)
            antes = m[y]
    for y in trozos:
        t = trozos[y]
        nueva = list(filas[y])
        mueve = []
        if izq.get(y):
            mueve.append((t[0], izq[y]))
        if der.get(y):
            mueve.append((t[-1], -der[y]))
        for (a, b), _ in mueve:
            for x in range(a, b):
                nueva[x] = (0, 0, 0, 0)
        for (a, b), d in mueve:
            for x in range(a, b):
                nueva[x + d] = filas[y][x]
        for x in range(cw):
            px[x, y] = nueva[x]
    hoja.paste(casilla, (x0, y0))
    print(f"{direccion} {k}: piernas de la fila {arriba} a la {abajo}, hasta {cierre} píxeles hacia dentro")

hoja.save(f"{HOJA}.png", optimize=True)
