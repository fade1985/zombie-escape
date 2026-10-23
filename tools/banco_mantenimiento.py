"""El banco de trabajo de la sala de mantenimiento (donde Johnny se fabrica las armas), al estilo de los muebles.

Hasta el 23 oct era un dibujo hecho con rectángulos (copiado del juego JS, en tools/dibujos_7b.py) y se veía de
dibujos animados. Ahora sale de PixelLab con la receta de los muebles del centro comercial (tools/guias_centro.py):
un boceto del banco ya en la perspectiva del juego, sobre azul, que PixelLab "viste". De arriba abajo: el tablero de
las herramientas colgado en la pared, la tapa vista desde arriba (con el tornillo de banco, un martillo, una sierra y
unos clavos) y el frente con dos cajones, las patas y una balda abajo con la caja de herramientas.

Mide como antes en el suelo (76 × 36 unidades, en scripts/mapa/mapa.gd): el dibujo, 40 píxeles de ancho (80
unidades), como la mesa del ordenador, un poco más ancha que lo que ocupa. Se pidieron 4 versiones y el dueño eligió
la 4 (las cuatro, con su fondo azul, en assets/sources/mantenimiento/intentos/; el texto y las semillas, en
assets/pixellab.json → "banco-mantenimiento").

  py tools/banco_mantenimiento.py guia      → assets/sources/mantenimiento/guias/banco-trabajo.png (el boceto)
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
  py tools/banco_mantenimiento.py           assets/sources/mantenimiento/banco-trabajo.png (el elegido, sin fondo)
                                            → assets/sprites/banco-trabajo.png (y luego importar en Godot)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, RAYA, FONDO, tono
from importar import convierte

CARPETA = 'assets/sources/mantenimiento'
GUIA = f'{CARPETA}/guias/banco-trabajo.png'
ORIGINAL = f'{CARPETA}/banco-trabajo.png'
SPRITE = 'assets/sprites/banco-trabajo.png'

ANCHO = 40      # en píxeles del juego
TABLERO = 12    # lo que sube el tablero de las herramientas por detrás
TAPA = 18       # la tapa vista desde arriba (el fondo del banco: 36 unidades)
FRENTE = 18     # el frente: los cajones y las patas
MADERA = (140, 100, 60)
ACERO = (175, 178, 185)
OSCURO = (60, 60, 66)
MANGO = (110, 70, 40)
ROJO = (150, 45, 40)


def guia():
    im = Image.new('RGBA', (ANCHO * S + 2 * M, (TABLERO + TAPA + FRENTE) * S + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)

    def caja(x0, y0, x1, y1, color, raya=True):
        """Un rectángulo en píxeles del juego, de (x0, y0) a (x1, y1) sin incluir"""
        dr.rectangle((M + x0 * S, M + y0 * S, M + x1 * S - 1, M + y1 * S - 1),
                     fill=color if len(color) == 4 else color + (255,),
                     outline=RAYA if raya else None)

    # el tablero de las herramientas, colgado en la pared: agujeritos y cinco herramientas colgadas
    caja(1, 0, ANCHO - 1, TABLERO + 1, (125, 100, 70))
    for x in range(3, ANCHO - 2, 3):
        for y in range(2, TABLERO, 3):
            caja(x, y, x + 1, y + 1, (80, 62, 45), raya=False)
    caja(6, 4, 8, 11, MANGO); caja(4, 2, 10, 4, OSCURO)             # un martillo
    caja(12, 3, 14, 11, ACERO); caja(11, 2, 15, 4, ACERO)           # una llave inglesa
    caja(17, 3, 26, 8, ACERO); caja(24, 2, 28, 6, MANGO)            # una sierra
    caja(30, 2, 32, 6, ROJO); caja(30, 6, 32, 10, ACERO, raya=False)  # un destornillador
    caja(34, 2, 36, 7, ACERO); caja(33, 7, 35, 11, ROJO); caja(35, 7, 37, 11, ROJO)   # unos alicates

    # la tapa, vista desde arriba, con lo que hay encima
    y = TABLERO
    caja(0, y, ANCHO, y + TAPA, tono(MADERA, 1.12))
    caja(2, y + 2, 9, y + 9, OSCURO); caja(3, y + 1, 8, y + 3, ACERO)   # el tornillo de banco, con sus mordazas
    caja(12, y + 10, 21, y + 12, MANGO); caja(20, y + 8, 22, y + 14, OSCURO)   # un martillo tumbado
    caja(24, y + 3, 37, y + 7, ACERO); caja(34, y + 2, 38, y + 8, MANGO)       # una sierra tumbada
    for cx, cy in ((13, 4), (15, 6), (17, 3), (26, 11), (11, 15), (35, 13)):   # clavos sueltos
        caja(cx, y + cy, cx + 1, y + cy + 1, ACERO, raya=False)
    caja(27, y + 11, 32, y + 15, (120, 30, 30), raya=False)               # una mancha de sangre

    # el frente: el faldón con dos cajones, las patas, una balda abajo con la caja de herramientas y un bote de
    # pintura, y la sombra de debajo del banco entre el faldón y la balda (por debajo de la balda se ve el suelo)
    y = TABLERO + TAPA
    caja(3, y + 6, ANCHO - 3, y + FRENTE - 5, (45, 40, 45), raya=False)
    caja(0, y, ANCHO, y + 6, tono(MADERA, 0.7))
    for x in (4, 23):
        caja(x, y + 1, x + 13, y + 5, tono(MADERA, 0.85))
        caja(x + 5, y + 2, x + 8, y + 3, ACERO, raya=False)
    caja(6, y + FRENTE - 10, 15, y + FRENTE - 5, ROJO); caja(9, y + FRENTE - 11, 12, y + FRENTE - 10, OSCURO)
    caja(27, y + FRENTE - 9, 31, y + FRENTE - 5, (150, 155, 160))
    caja(3, y + FRENTE - 5, ANCHO - 3, y + FRENTE - 3, tono(MADERA, 0.8))
    for x in (0, ANCHO - 3):
        caja(x, y, x + 3, y + FRENTE, tono(MADERA, 0.6))

    os.makedirs(os.path.dirname(GUIA), exist_ok=True)
    im.save(GUIA)
    print(GUIA, im.size)


def monta():
    """El elegido (ya sin fondo) → el sprite del juego, con la receta de los muebles (tools/importar.py): reducido a
    40 píxeles de ancho y con el contorno oscuro"""
    out = convierte(ORIGINAL, ANCHO, halo=False)
    out.save(SPRITE)
    print(SPRITE, out.size)


if __name__ == '__main__':
    if sys.argv[1:2] == ['guia']:
        guia()
    else:
        monta()
