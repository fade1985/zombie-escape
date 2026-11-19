"""Los cachos de carne que salen volando cuando revienta el zombi explosivo (19 nov, los pidió el dueño con una foto
suya de carne cruda, referencia-carne.jpg). Los hizo PixelLab (create_image_pixflux, el intento A:
pixellab/carne-a.png, con los colores de la foto); GPT no quiso hacerlos.

Recorta cada cacho (cada mancha suelta del dibujo), lo reduce (REDUCIR), le pone el borde negro de Johnny (#050202) y los pone en fila, cada
uno en el centro de una casilla de CELDA × CELDA, en assets/sprites/cachos-carne.png (los usa scripts/cachos.gd, a
escala 2 como todos los dibujos).

    py -I assets/sources/zombi-explosivo-gpt/carne.py
"""
import os
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, '..', '..', '..'))
CELDA = 16
REDUCIR = 0.55   # PixelLab los hizo grandes (hasta 27 píxeles): los más grandes, como la cabeza del zombi (unos 14)
BORDE = (5, 2, 2, 255)
VECINOS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def manchas(im):
    """Cada grupo de píxeles opacos que se tocan (también en diagonal), de más grande a más pequeño."""
    px = im.load()
    w, h = im.size
    visto, grupos = set(), []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] < 128 or (x, y) in visto:
                continue
            pila, grupo = [(x, y)], []
            visto.add((x, y))
            while pila:
                a, b = pila.pop()
                grupo.append((a, b))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        q = (a + dx, b + dy)
                        if 0 <= q[0] < w and 0 <= q[1] < h and q not in visto and px[q][3] >= 128:
                            visto.add(q)
                            pila.append(q)
            grupos.append(grupo)
    return sorted([g for g in grupos if len(g) >= 6], key=len, reverse=True)


def main():
    im = Image.open(os.path.join(AQUI, 'pixellab', 'carne-a.png')).convert('RGBA')
    px = im.load()
    cachos = []
    for g in manchas(im):
        xs, ys = [p[0] for p in g], [p[1] for p in g]
        x0, y0 = min(xs), min(ys)
        grande = Image.new('RGBA', (max(xs) - x0 + 1, max(ys) - y0 + 1), (0, 0, 0, 0))
        for x, y in g:
            r, gg, b, _ = px[x, y]
            grande.putpixel((x - x0, y - y0), (r, gg, b, 255))
        # más pequeño, mezclando colores como los muebles (LANCZOS premultiplicado) y sin medias tintas en el borde
        w, h = max(2, round(grande.width * REDUCIR)), max(2, round(grande.height * REDUCIR))
        peq = grande.convert('RGBa').resize((w, h), Image.LANCZOS).convert('RGBA')
        peq.putalpha(peq.split()[3].point(lambda v: 255 if v > 110 else 0))
        c = Image.new('RGBA', (w + 2, h + 2), (0, 0, 0, 0))
        c.alpha_composite(peq, (1, 1))
        cp = c.load()
        # el borde negro de 1 píxel por fuera, como los personajes
        poner = [(x, y) for y in range(c.height) for x in range(c.width) if cp[x, y][3] == 0 and any(
            0 <= x + a < c.width and 0 <= y + b < c.height and cp[x + a, y + b][3] for a, b in VECINOS)]
        for q in poner:
            cp[q] = BORDE
        if c.width > CELDA or c.height > CELDA:
            print('no cabe', c.size)
            continue
        cachos.append(c)
    hoja = Image.new('RGBA', (CELDA * len(cachos), CELDA), (0, 0, 0, 0))
    for i, c in enumerate(cachos):
        hoja.alpha_composite(c, (i * CELDA + (CELDA - c.width) // 2, (CELDA - c.height) // 2))
    hoja.save(os.path.join(RAIZ, 'assets', 'sprites', 'cachos-carne.png'))
    print(len(cachos), 'cachos:', [c.size for c in cachos])


if __name__ == '__main__':
    main()
