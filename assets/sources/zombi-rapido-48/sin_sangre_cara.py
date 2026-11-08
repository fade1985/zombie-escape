"""Crío (zombi rápido): le quita las manchas rojas de la cara (sangre en la boca y en la mejilla, de PixelLab), que al
dueño le quedaban fatal (8 nov). En todos sus dibujos y todas las direcciones.

Cada mancha roja o naranja pequeña (10 píxeles como mucho: la chaqueta es mucho más grande) que esté entera en la
cabeza (entre la gorra y la barbilla) pasa a ser del color de alrededor: el verde de la piel o, si es una mota en el
borde de la gorra, su azul. Cambia los dibujos en su sitio: se pasa UNA vez (los de antes, en git).

Uso:  py assets/sources/zombi-rapido-48/sin_sangre_cara.py [carpeta para ver el antes y el después]
"""
import glob
import sys
from collections import Counter
from PIL import Image

BASE = 'assets/sources/zombi-rapido-48'
rojo = lambda c: c[0] > c[1] + 45 and c[0] > c[2] + 35 and c[0] > 90
verde = lambda c: c[1] >= c[0] - 5 and c[1] > c[2] + 8 and c[1] > 70    # la piel
azul = lambda c: c[2] > c[0] + 25 and c[2] > 60                        # la gorra
MAX_MANCHA = 10   # más grande ya es la chaqueta
VEC8 = ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, 1), (1, -1), (-1, -1))


def gorra(px, w, h):
    """Fila de abajo de la gorra (el grupo azul más grande) y su caja"""
    vistos, mejor = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in vistos or not px[x, y][3] or not azul(px[x, y]):
                continue
            grupo, pila = [], [(x, y)]
            vistos.add((x, y))
            while pila:
                p = pila.pop()
                grupo.append(p)
                for dx, dy in VEC8:
                    q = (p[0] + dx, p[1] + dy)
                    if 0 <= q[0] < w and 0 <= q[1] < h and q not in vistos and px[q][3] and azul(px[q]):
                        vistos.add(q)
                        pila.append(q)
            if len(grupo) > len(mejor):
                mejor = grupo
    return mejor


def sin_sangre(im):
    """Las manchas rojas pequeñas de la cabeza (las que no son parte de la chaqueta), del color de alrededor"""
    im = im.copy()
    px = im.load()
    w, h = im.size
    g = gorra(px, w, h)
    if len(g) < 8:
        return im, 0
    cx0, cx1 = min(x for x, _ in g) - 4, max(x for x, _ in g) + 4
    fondo = max(y for _, y in g)
    vistos, total = set(), 0
    for y in range(h):
        for x in range(w):
            if (x, y) in vistos or not px[x, y][3] or not rojo(px[x, y]):
                continue
            mancha, pila = [], [(x, y)]
            vistos.add((x, y))
            while pila:
                p = pila.pop()
                mancha.append(p)
                for dx, dy in VEC8:
                    q = (p[0] + dx, p[1] + dy)
                    if 0 <= q[0] < w and 0 <= q[1] < h and q not in vistos and px[q][3] and rojo(px[q]):
                        vistos.add(q)
                        pila.append(q)
            # pequeña y en la cabeza (entre poco por encima del fondo de la gorra y la barbilla)
            if len(mancha) > MAX_MANCHA or not all(cx0 <= a <= cx1 and fondo - 6 <= b <= fondo + 8 for a, b in mancha):
                continue
            dentro = set(mancha)
            alrededor = Counter()
            for radio in (1, 2):   # (si junto a la mancha solo hay contorno, un poco más lejos)
                alrededor = Counter(px[a + dx, b + dy] for a, b in mancha for dx in range(-radio, radio + 1)
                                    for dy in range(-radio, radio + 1)
                                    if 0 <= a + dx < w and 0 <= b + dy < h and (a + dx, b + dy) not in dentro
                                    and px[a + dx, b + dy][3] and (verde(px[a + dx, b + dy]) or azul(px[a + dx, b + dy])))
                if alrededor:
                    break
            if not alrededor:
                continue
            color = alrededor.most_common(1)[0][0]
            for q in mancha:
                px[q] = color
            total += len(mancha)
    return im, total


if __name__ == '__main__':
    ver = sys.argv[1] if len(sys.argv) > 1 else None
    antes, despues = [], []
    for f in sorted(glob.glob(f'{BASE}/rotations/*.png') + glob.glob(f'{BASE}/walk/*.png') + glob.glob(f'{BASE}/ataque/*.png')
                    + glob.glob(f'{BASE}/golpe/*.png') + glob.glob(f'{BASE}/muerte/*.png')):
        im = Image.open(f).convert('RGBA')
        nuevo, n = sin_sangre(im)
        if n:
            nuevo.save(f)
            antes.append(im)
            despues.append(nuevo)
        print(f, n)
    if ver and antes:
        L = max(i.width for i in antes)
        hoja = Image.new('RGBA', (L * len(antes), L * 2), (60, 60, 60, 255))
        for i, (a, d) in enumerate(zip(antes, despues)):
            hoja.alpha_composite(a, (i * L, L - a.height))
            hoja.alpha_composite(d, (i * L, 2 * L - d.height))
        hoja.save(f'{ver}/sin-sangre-cara.png')
