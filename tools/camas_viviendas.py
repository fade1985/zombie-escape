"""Las camas de las habitaciones de los supervivientes (viviendas.gd): la cama individual de siempre, con la colcha
del color de cada uno (el mismo de Supervivientes.DATOS en scripts/supervivientes.gd), para que se distinga de quién es
cada habitación.

  py tools/camas_viviendas.py   → assets/sources/salas/viviendas/cama-<id>.png (y luego: py tools/importar.py)

Parte de assets/sources/salas/dormitorio/cama.png y solo toca los píxeles de la colcha (la mostaza: tono naranja y
saturados, que en ese dibujo son solo la colcha; la madera, las sábanas y la sangre no). A cada uno le cambia el tono y
deja la luminosidad, así que las sombras y los pliegues quedan como en el original (los mismos pocos colores).
"""
import colorsys, os
from PIL import Image

ORIGEN = 'assets/sources/salas/dormitorio/cama.png'
SALIDA = 'assets/sources/salas/viviendas'
# el color de cada superviviente (Supervivientes.DATOS)
COLORES = {'policia': '#6fa8ff', 'medico': '#80ed99', 'militar': '#c9e265',
           'ferretero': '#ff9a3c', 'farmaceutica': '#3ddc84', 'tecnico': '#4fe3ff'}
SAT_MIN, SAT_MAX = 0.45, 0.85   # la colcha no ha de quedar ni grisácea ni chillona


def es_colcha(h, s):
    return 0.05 <= h <= 0.15 and s > 0.5


def tono(hexa):
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hls(r, g, b)[0]


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
        im.save(f'{SALIDA}/cama-{id}.png')
        print(f'  cama-{id}.png: {cambiados} píxeles de colcha')


if __name__ == '__main__':
    main()
