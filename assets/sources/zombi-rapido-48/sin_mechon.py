"""Crío (zombi rápido): le quita el mechón rubio que le asoma por detrás de la nuca en las vistas de perfil (lo pidió el
dueño el 8 nov: de lejos parecía que le salía algo de la cabeza).

En los dibujos de perfil (este y oeste: quieto, andar, ataque, golpe y muerte) busca las manchas amarillas (el pelo)
que quedan por debajo de la gorra: el pelo de debajo de la visera, junto a la cara, se queda; el mechón de la nuca se
quita. Lo de fuera del cuerpo se borra, lo de dentro se rellena con el color de alrededor, y se limpian los restos
sueltos que quedan (su contorno, algún píxel rojo). Cambia los dibujos en su sitio: se pasa UNA vez (los de antes, en git).

Uso:  py assets/sources/zombi-rapido-48/sin_mechon.py [carpeta para ver el antes y el después]
"""
import glob
import sys
from collections import Counter
from PIL import Image

BASE = 'assets/sources/zombi-rapido-48'
amarillo = lambda c: c[0] > 180 and c[1] > 120 and c[2] < 130 and c[0] - c[2] > 100
azul = lambda c: c[2] > c[0] + 25 and c[2] > 60          # la gorra azul marino
VEC4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
VEC8 = VEC4 + ((1, 1), (-1, 1), (1, -1), (-1, -1))


def manchas(px, w, h, cumple):
    """Grupos de píxeles que cumplen `cumple`, tocándose (también en diagonal)"""
    vistos, grupos = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in vistos or not px[x, y][3] or not cumple(px[x, y]):
                continue
            grupo, pila = [], [(x, y)]
            vistos.add((x, y))
            while pila:
                p = pila.pop()
                grupo.append(p)
                for dx, dy in VEC8:
                    q = (p[0] + dx, p[1] + dy)
                    if 0 <= q[0] < w and 0 <= q[1] < h and q not in vistos and px[q][3] and cumple(px[q]):
                        vistos.add(q)
                        pila.append(q)
            grupos.append(grupo)
    return grupos


def sin_mechon(im):
    im = im.copy()
    px = im.load()
    w, h = im.size
    gorra = max(manchas(px, w, h, azul), key=len, default=None)
    if not gorra:
        return im, 0
    fondo_gorra = max(y for _, y in gorra)
    quitar = [g for g in manchas(px, w, h, amarillo) if sum(y for _, y in g) / len(g) > fondo_gorra + 1]
    if not quitar:
        return im, 0
    fuera = {p for g in quitar for p in g}
    x0 = min(x for x, _ in fuera) - 2
    x1 = max(x for x, _ in fuera) + 2
    y0 = min(y for _, y in fuera) - 2
    y1 = max(y for _, y in fuera) + 2
    # de fuera hacia dentro: lo que asoma al aire se borra; lo rodeado de cuerpo, del color de alrededor
    for _ in range(8):
        hecho = {}
        for (x, y) in fuera:
            alrededor = [px[x + dx, y + dy] for dx, dy in VEC8
                         if 0 <= x + dx < w and 0 <= y + dy < h and (x + dx, y + dy) not in fuera]
            solido = [c for c in alrededor if c[3]]
            if len(alrededor) >= 3:
                hecho[(x, y)] = Counter(solido).most_common(1)[0][0] if len(solido) >= 6 else (0, 0, 0, 0)
        for q, c in hecho.items():
            px[q] = c
        fuera -= set(hecho)
        if not fuera:
            break
    for q in fuera:
        px[q] = (0, 0, 0, 0)
    # restos sueltos alrededor (el contorno del mechón, algún píxel rojo): los que se quedan colgando
    for _ in range(3):
        borrar = [(x, y) for y in range(max(0, y0), min(h, y1 + 1)) for x in range(max(0, x0), min(w, x1 + 1))
                  if px[x, y][3] and sum(1 for dx, dy in VEC4 if 0 <= x + dx < w and 0 <= y + dy < h
                                         and px[x + dx, y + dy][3]) <= 1]
        for q in borrar:
            px[q] = (0, 0, 0, 0)
    return im, len(quitar)


if __name__ == '__main__':
    ver = sys.argv[1] if len(sys.argv) > 1 else None
    antes, despues = [], []
    for lado in ('east', 'west'):
        for f in sorted(glob.glob(f'{BASE}/rotations/{lado}.png') + glob.glob(f'{BASE}/*/{lado}-*.png')):
            if '/rotations-original' in f.replace('\\', '/'):
                continue
            im = Image.open(f).convert('RGBA')
            nuevo, n = sin_mechon(im)
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
        hoja.save(f'{ver}/sin-mechon.png')
