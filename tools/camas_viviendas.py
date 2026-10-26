"""Las camas de las habitaciones de los supervivientes (viviendas.gd), que son trasteros: un colchón en el suelo, con la
almohada descolocada y la colcha del color de cada uno (el mismo de Supervivientes.DATOS en scripts/supervivientes.gd),
para que se distinga de quién es cada habitación.

  py tools/camas_viviendas.py   → assets/sources/salas/viviendas/colchon-<id>.png (y luego: py tools/importar.py)

Parte del colchón de PixelLab (assets/sources/viviendas/colchon.png, con la colcha mostaza; su guía, la cama individual de
siempre sin el cabecero ni el pie: tools/guias_trasteros.py) y solo toca los píxeles de la colcha (la mostaza: tono naranja
y saturados, que en ese dibujo son solo la colcha; las sábanas y la almohada no). A cada uno le cambia el tono y deja la
luminosidad, así que las sombras y los pliegues quedan como en el original (los mismos pocos colores).
"""
import colorsys, os
from collections import Counter
from PIL import Image

ORIGEN = 'assets/sources/viviendas/colchon.png'
CAMA = 'assets/sources/salas/dormitorio/cama.png'   # la cama de siempre, de la que sale la guía del colchón
SALIDA = 'assets/sources/salas/viviendas'
# el color de cada superviviente (Supervivientes.DATOS)
COLORES = {'policia': '#6fa8ff', 'medico': '#80ed99', 'militar': '#c9e265',
           'ferretero': '#ff9a3c', 'farmaceutica': '#3ddc84', 'tecnico': '#4fe3ff'}
SAT_MIN, SAT_MAX = 0.45, 0.85   # la colcha no ha de quedar ni grisácea ni chillona
# los colores de la sangre de la cama de siempre (la mancha de la almohada y el reguero de la sábana, y un píxel suelto de su
# borde): tools/guias_trasteros.py la quita antes de hacer la guía del colchón
SANGRE = {(113, 48, 49), (87, 14, 30), (134, 93, 73)}
CABECERO = 36   # de aquí hacia arriba es el cabecero (su madera no se toca)


def es_colcha(h, s):
    return 0.05 <= h <= 0.15 and s > 0.5


def tono(hexa):
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hls(r, g, b)[0]


def sin_sangre(im):
    px = im.load()
    return rellenar(im, {(x, y) for y in range(CABECERO, im.height) for x in range(im.width) if px[x, y][:3] in SANGRE})


def rellenar(im, manchas, evitar=()):
    """Cada píxel de "manchas" (un conjunto de (x, y): sangre, arañazos...) pasa a ser el color que más se repite entre
    sus vecinos que no lo son (sábana, almohada, madera), de fuera hacia dentro, hasta que no queda ninguno. Los colores
    de "evitar" (los oscuros del borde de un dibujo) solo se usan cuando ya no queda ningún píxel con otro vecino que
    rellenar"""
    px = im.load()
    while manchas:
        limpios = {}
        con_oscuros = {}
        for x, y in manchas:
            vecinos = Counter(px[x + dx, y + dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                              if (dx or dy) and 0 <= x + dx < im.width and 0 <= y + dy < im.height
                              and (x + dx, y + dy) not in manchas and px[x + dx, y + dy][3] > 0)
            claros = Counter({c: n for c, n in vecinos.items() if c[:3] not in evitar})
            if claros:
                limpios[(x, y)] = claros.most_common(1)[0][0]
            elif vecinos:
                con_oscuros[(x, y)] = vecinos.most_common(1)[0][0]
        limpios = limpios or con_oscuros
        if not limpios:
            break
        for q, color in limpios.items():
            px[q] = color
            manchas.discard(q)
    return im


def main():
    original = Image.open(ORIGEN).convert('RGBA')
    os.makedirs(SALIDA, exist_ok=True)
    for id, hexa in COLORES.items():
        th = tono(hexa)
        im = original.copy()
        px = im.load()
        cambiados = 0
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
                if not es_colcha(h, s):
                    continue
                s = min(SAT_MAX, max(SAT_MIN, s))
                r, g, b = (round(c * 255) for c in colorsys.hls_to_rgb(th, l, s))
                px[x, y] = (r, g, b, a)
                cambiados += 1
        im.save(f'{SALIDA}/colchon-{id}.png')
        print(f'  colchon-{id}.png: {cambiados} píxeles de colcha')


if __name__ == '__main__':
    main()
