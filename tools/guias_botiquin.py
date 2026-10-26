"""Bocetos (guías) del botiquín del baño (el armarito colgado de la pared, scripts/mapa/armarito.gd), para pedírselo a
PixelLab de frente y con el mismo estilo que los muebles nuevos (tools/guias_cocina.py, de donde salen caja() y punto()).

Dos fotogramas, del mismo tamaño que el de antes (26 × 22 píxeles del juego):
  - botiquin-cerrado: el armarito blanco de metal con sus dos puertas, la cruz roja en medio y dos tiradores (se ve mientras
    tiene el botiquín dentro, con su brillo verde)
  - botiquin-abierto: las dos puertas abiertas a los lados (de canto), el hueco oscuro y una balda, vacío (ya cogido). Al final
    no se usó: el abierto se dibuja encima del cerrado (tools/botiquin.py)
Cada uno, al doble de píxeles que el juego (con el margen de siempre) y también a tamaño del juego (con "-1x" y 5 de margen:
PixelLab pide al menos 32 × 32 de área); el de a tamaño del juego salió borroso, y se usó el del doble.

  py tools/guias_botiquin.py   → assets/sources/centro/guias/botiquin-<cerrado|abierto>[-1x].png
Después, igual que con los muebles: py tools/guias_centro.py quita <png>… (y, si hace falta, guias_cocina.py limpia).
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono
from guias_cocina import caja

CAJA = (233, 237, 241)
BALDA = (201, 209, 218)
HUECO = (74, 85, 104)
ROJO = (230, 57, 70)
TIRADOR = (141, 153, 174)
ANCHO, ALTO = 26, 22     # el fotograma, en píxeles del juego
L = 4                    # la caja va de 4 a 22 (18 de ancho), con sitio a los lados para las puertas abiertas


def px(dr, x, y, a, b, w, h, color, s):
    """Un rectángulo sin raya, en píxeles del juego contados desde (x, y); s, píxeles de la guía por píxel del juego"""
    dr.rectangle((x + a * s, y + b * s, x + (a + w) * s - 1, y + (b + h) * s - 1), fill=color + (255,))


def cerrado(dr, x, y, s):
    caja(dr, x + L * s, y, x + (L + 18) * s, y + 20 * s, tono(CAJA, 1.0))
    # la balda de abajo, más ancha, con su canto
    caja(dr, x + (L - 1) * s, y + 17 * s, x + (L + 19) * s, y + 21 * s, tono(BALDA, 1.0))
    # la raja entre las dos puertas y la cruz roja encima
    px(dr, x, y, L + 8, 1, 1, 16, RAYA[:3], s)
    px(dr, x, y, L + 5, 6, 8, 3, ROJO, s)
    px(dr, x, y, L + 7, 4, 4, 7, ROJO, s)
    # los tiradores y los dos tornillos de arriba
    px(dr, x, y, L + 6, 12, 1, 2, TIRADOR, s)
    px(dr, x, y, L + 11, 12, 1, 2, TIRADOR, s)
    px(dr, x, y, L + 2, 1, 1, 1, (92, 100, 112), s)
    px(dr, x, y, L + 15, 1, 1, 1, (92, 100, 112), s)


def abierto(dr, x, y, s):
    caja(dr, x + L * s, y, x + (L + 18) * s, y + 20 * s, tono(CAJA, 1.0))
    px(dr, x, y, L + 1, 1, 16, 16, HUECO, s)
    px(dr, x, y, L + 1, 8, 16, 1, BALDA, s)
    caja(dr, x + (L - 1) * s, y + 17 * s, x + (L + 19) * s, y + 21 * s, tono(BALDA, 1.0))
    # las puertas abiertas, de canto, a los lados
    caja(dr, x, y, x + 4 * s, y + 18 * s, tono(CAJA, 1.0))
    caja(dr, x + 22 * s, y, x + 26 * s, y + 18 * s, tono(CAJA, 1.0))
    px(dr, x, y, L + 2, 1, 1, 1, (92, 100, 112), s)
    px(dr, x, y, L + 15, 1, 1, 1, (92, 100, 112), s)


def guia(nombre, dibuja, s=S):
    m = M if s == S else 5     # a tamaño del juego, 5 de margen: PixelLab pide al menos 32 × 32 de área
    im = Image.new('RGBA', (ANCHO * s + 2 * m, ALTO * s + 2 * m), FONDO + (255,))
    dibuja(ImageDraw.Draw(im), m, m, s)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}{"" if s == S else "-1x"}.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    for esc in (S, 1):
        guia('botiquin-cerrado', cerrado, esc)
        guia('botiquin-abierto', abierto, esc)
