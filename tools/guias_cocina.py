"""Boceto (guía) de la nevera de los pisos, para pedírsela a PixelLab recta y de frente.

La que había salió girada en diagonal (se le veía el costado derecho). Lo mismo que tools/guias_limpieza.py (de
tools/guias_centro.py salen la perspectiva, los colores de la raya y del fondo azul y cómo se quita el fondo después):
de arriba abajo, la tapa vista desde arriba (con una caja de cereales y una cesta encima: si la tapa es lisa, PixelLab
la deja lisa) y el frente, con la puerta del congelador, la de la nevera, sus asas, imanes y una nota. La tapa es más
corta que el fondo del catálogo (58), como en la nevera de bebidas del centro comercial: así se ve de frente y solo un
poco desde arriba.

  py tools/guias_cocina.py               → assets/sources/centro/guias/nevera.png
  py tools/guias_centro.py quita <png>…  quita el fondo azul de lo que devuelve PixelLab
Se pasa al juego con py tools/importar.py (su original, en assets/sources/salas/cocina/nevera.png).
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono, Tapa

BLANCO = (205, 205, 195)
ASA = (95, 95, 100)
# largo (el del catálogo, en unidades), tapa y alto del frente (en píxeles del juego)
LARGO, TAPA, ALTO = 62, 22, 46


def caja(dr, x0, y0, x1, y1, color):
    dr.rectangle((x0, y0, x1 - 1, y1 - 1), fill=color if len(color) == 4 else color + (255,), outline=RAYA)


def nevera():
    w, d, h = LARGO // 2 * S, TAPA * S, ALTO * S
    im = Image.new('RGBA', (w + 2 * M, d + h + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    x, y = M, M
    # la tapa, desde arriba: una caja de cereales (roja, con su franja amarilla) y una cesta de mimbre
    caja(dr, x, y, x + w, y + d, tono(BLANCO, 1.12))
    t = Tapa(dr, x, y, w, d, False)
    t.caja(0.1, 0.2, 0.38, 0.75, (170, 60, 50))
    t.caja(0.1, 0.42, 0.38, 0.55, (210, 180, 70), raya=False)
    t.caja(0.52, 0.25, 0.9, 0.85, (150, 110, 60))
    t.caja(0.58, 0.38, 0.84, 0.72, (110, 80, 45), raya=False)
    # el frente: el congelador arriba, la nevera debajo y el zócalo
    top = y + d
    caja(dr, x, top, x + w, top + h, tono(BLANCO, 0.95))
    corte = top + 15 * S
    dr.rectangle((x, corte, x + w - 1, corte + S - 1), fill=RAYA)
    caja(dr, x, top + h - 3 * S, x + w, top + h, (60, 60, 65))
    # las asas, largas y a la derecha
    caja(dr, x + w - 5 * S, top + 4 * S, x + w - 3 * S, top + 12 * S, ASA)
    caja(dr, x + w - 5 * S, corte + 3 * S, x + w - 3 * S, corte + 16 * S, ASA)
    # una nota de papel y unos imanes de colores en la puerta de la nevera
    caja(dr, x + 4 * S, corte + 4 * S, x + 10 * S, corte + 11 * S, (225, 215, 160))
    for (ix, iy, c) in ((13, 5, (170, 50, 50)), (17, 9, (60, 90, 160)), (12, 13, (200, 170, 50)), (19, 15, (70, 140, 80))):
        dr.rectangle((x + ix * S, corte + iy * S, x + (ix + 2) * S - 1, corte + (iy + 2) * S - 1), fill=c + (255,))
    # unas salpicaduras de sangre abajo
    for (bx, by) in ((5, 22), (6, 23), (8, 24), (22, 20), (23, 21)):
        dr.rectangle((x + bx * S, corte + by * S, x + (bx + 1) * S - 1, corte + (by + 1) * S - 1), fill=(120, 25, 25, 255))
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/nevera.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    nevera()
