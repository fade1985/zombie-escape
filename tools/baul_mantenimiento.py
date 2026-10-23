"""El baúl de la sala de mantenimiento (donde se guardan las armas creadas y los objetos), al estilo de los muebles.

Hasta el 23 oct era un dibujo hecho con rectángulos (copiado del juego JS, en tools/dibujos_7b.py) y desentonaba al
lado del banco de trabajo nuevo. Ahora sale de PixelLab con la misma receta que el banco (tools/banco_mantenimiento.py):
un boceto del baúl ya en la perspectiva del juego, sobre azul, que PixelLab "viste". De arriba abajo: la tapa vista
desde arriba (tablones, dos flejes de hierro con sus remaches, esquinas de hierro y una mancha de sangre) y el
frente, con el canto de la tapa, los flejes que bajan, la cerradura dorada en medio y el zócalo.

Mide como antes en el suelo (60 × 36 unidades, en scripts/mapa/mapa.gd): el dibujo, 32 píxeles de ancho (64
unidades), un poco más ancho que lo que ocupa, como el banco. Se pidieron 4 versiones (las cuatro, con su fondo azul,
en assets/sources/mantenimiento/intentos/; el texto y las semillas, en assets/pixellab.json → "baul-mantenimiento").

  py tools/baul_mantenimiento.py guia      → assets/sources/mantenimiento/guias/baul.png (el boceto)
  py tools/guias_centro.py quita <png>…    quita el fondo azul de lo que devuelve PixelLab
  py tools/baul_mantenimiento.py           assets/sources/mantenimiento/baul.png (el elegido, sin fondo)
                                           → assets/sprites/baul.png (y luego importar en Godot)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, RAYA, FONDO, tono
from importar import convierte

CARPETA = 'assets/sources/mantenimiento'
GUIA = f'{CARPETA}/guias/baul.png'
ORIGINAL = f'{CARPETA}/baul.png'
SPRITE = 'assets/sprites/baul.png'

ANCHO = 32      # en píxeles del juego
TAPA = 16       # la tapa vista desde arriba
FRENTE = 14     # el frente: más bajo que el del banco (18), que el baúl llega por la rodilla
MADERA = (140, 100, 60)
HIERRO = (95, 100, 110)
REMACHE = (165, 170, 178)
ORO = (205, 165, 60)
OSCURO = (40, 30, 25)
SANGRE = (120, 30, 30)
FLEJES = (6, 23)   # dónde empieza cada fleje (3 de ancho)


def guia():
    im = Image.new('RGBA', (ANCHO * S + 2 * M, (TAPA + FRENTE) * S + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)

    def caja(x0, y0, x1, y1, color, raya=True):
        """Un rectángulo en píxeles del juego, de (x0, y0) a (x1, y1) sin incluir"""
        dr.rectangle((M + x0 * S, M + y0 * S, M + x1 * S - 1, M + y1 * S - 1),
                     fill=color if len(color) == 4 else color + (255,),
                     outline=RAYA if raya else None)

    # la tapa, vista desde arriba: tres tablones, los dos flejes con remaches, las esquinas de hierro y sangre
    caja(0, 0, ANCHO, TAPA, tono(MADERA, 1.12))
    for y in (5, 10):
        caja(1, y, ANCHO - 1, y + 1, tono(MADERA, 0.8), raya=False)
    caja(11, 7, 17, 11, SANGRE, raya=False); caja(17, 8, 19, 9, SANGRE, raya=False)
    caja(13, 12, 14, 13, SANGRE, raya=False)
    for x in FLEJES:
        caja(x, 0, x + 3, TAPA, HIERRO)
        for y in (2, 7, 12):
            caja(x + 1, y, x + 2, y + 1, REMACHE, raya=False)
    for x, y in ((0, 0), (ANCHO - 3, 0), (0, TAPA - 3), (ANCHO - 3, TAPA - 3)):
        caja(x, y, x + 3, y + 3, HIERRO)

    # el frente: el canto de la tapa, el cuerpo con sus tablones, los flejes que bajan, las esquinas de hierro,
    # el zócalo y, en medio, la cerradura dorada que cuelga del canto
    y = TAPA
    caja(0, y, ANCHO, y + 3, tono(MADERA, 0.72))
    caja(0, y + 3, ANCHO, y + FRENTE, tono(MADERA, 0.9))
    for dy in (7, 10):
        caja(1, y + dy, ANCHO - 1, y + dy + 1, tono(MADERA, 0.65), raya=False)
    caja(0, y + FRENTE - 2, ANCHO, y + FRENTE, tono(MADERA, 0.55))
    for x in FLEJES:
        caja(x, y, x + 3, y + FRENTE, HIERRO)
        for dy in (1, 6, 11):
            caja(x + 1, y + dy, x + 2, y + dy + 1, REMACHE, raya=False)
    for x in (0, ANCHO - 3):
        caja(x, y, x + 3, y + 4, HIERRO); caja(x, y + FRENTE - 4, x + 3, y + FRENTE, HIERRO)
    caja(13, y + 1, 19, y + 9, ORO)
    caja(15, y + 4, 17, y + 7, OSCURO, raya=False)

    os.makedirs(os.path.dirname(GUIA), exist_ok=True)
    im.save(GUIA)
    print(GUIA, im.size)


def monta():
    """El elegido (ya sin fondo) → el sprite del juego, con la receta de los muebles (tools/importar.py): reducido a
    32 píxeles de ancho y con el contorno oscuro"""
    out = convierte(ORIGINAL, ANCHO, halo=False)
    out.save(SPRITE)
    print(SPRITE, out.size)


if __name__ == '__main__':
    if sys.argv[1:2] == ['guia']:
        guia()
    else:
        monta()
