"""La mesa del ordenador de la sala de mantenimiento (donde Johnny abre ConserjeOS), al estilo de los muebles.

Hasta el 23 oct era el dibujo que dio el dueño en el juego JS (19 oct), pasado a píxeles y sin fondo, tal cual. Para
que todos los muebles de la sala estén hechos con la misma herramienta, ahora sale de PixelLab con la misma receta
que el banco y el baúl (tools/banco_mantenimiento.py): un boceto de la mesa ya en la perspectiva del juego, sobre
azul, que PixelLab "viste". Conserva la idea del dibujo del dueño. De arriba abajo: el monitor beis de los 90 con la
pantalla encendida, encima de la caja del ordenador; la tapa vista desde arriba (el teclado, el ratón con su
alfombrilla, una taza de café, unos papeles y sangre) y el frente, con el faldón, la cajonera de la derecha, la pata
de la izquierda y el panel del fondo (por debajo se ve el suelo).

Mide como antes en el suelo (92 × 44 unidades, en scripts/mapa/ordenador.gd): el dibujo, 48 píxeles de ancho (96
unidades), un poco más ancho que lo que ocupa, como el banco y el baúl. Se pidieron 4 versiones y el dueño eligió la
2 (las cuatro, con su fondo azul, en assets/sources/mantenimiento/intentos/; el texto y las semillas, en
assets/pixellab.json → "mesa-ordenador-mantenimiento"). Tres de las cuatro (la 2 también) traían debajo de la mesa
una sombra azulada pintada sobre el fondo, más oscura que él, que quita() no se lleva y en el juego se vería como un
parche azul: se le quita después con "sombra".

  py tools/ordenador_mantenimiento.py guia  → assets/sources/mantenimiento/guias/mesa-ordenador.png (el boceto)
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
  py tools/ordenador_mantenimiento.py sombra <png>…   y luego la sombra azulada de debajo de la mesa
  py tools/ordenador_mantenimiento.py       assets/sources/mantenimiento/mesa-ordenador.png (la elegida, sin fondo)
                                            → assets/sprites/mesa-ordenador.png (y luego importar en Godot)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, RAYA, FONDO, tono
from importar import convierte

CARPETA = 'assets/sources/mantenimiento'
GUIA = f'{CARPETA}/guias/mesa-ordenador.png'
ORIGINAL = f'{CARPETA}/mesa-ordenador.png'
SPRITE = 'assets/sprites/mesa-ordenador.png'

ANCHO = 48      # en píxeles del juego
MONITOR = 13    # lo que asoma el monitor por encima de la tapa
TAPA = 18       # la tapa vista desde arriba
FRENTE = 16     # el frente: el faldón, la cajonera y las patas
MADERA = (140, 100, 60)
BEIS = (200, 190, 160)
PANTALLA = (70, 175, 225)   # el azul de la pantalla encendida: más claro y más cian que el fondo, para no confundirlos
OSCURO = (45, 40, 45)
SANGRE = (120, 30, 30)
PAPEL = (225, 220, 200)
ACERO = (175, 178, 185)


def guia():
    im = Image.new('RGBA', (ANCHO * S + 2 * M, (MONITOR + TAPA + FRENTE) * S + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)

    def caja(x0, y0, x1, y1, color, raya=True):
        """Un rectángulo en píxeles del juego, de (x0, y0) a (x1, y1) sin incluir"""
        dr.rectangle((M + x0 * S, M + y0 * S, M + x1 * S - 1, M + y1 * S - 1),
                     fill=color if len(color) == 4 else color + (255,),
                     outline=RAYA if raya else None)

    # la tapa, vista desde arriba (empieza en la pared, donde acaba lo que asoma el monitor), con lo que hay encima:
    # a la izquierda una taza de café y unos papeles; delante del ordenador, el teclado; a la derecha, el ratón en su
    # alfombrilla; y sangre
    y = MONITOR
    caja(0, y, ANCHO, y + TAPA, tono(MADERA, 1.12))
    caja(2, y + 3, 7, y + 8, (215, 210, 195)); caja(3, y + 4, 6, y + 7, (70, 45, 30), raya=False)   # la taza
    caja(7, y + 5, 8, y + 7, (215, 210, 195), raya=False)                                            # su asa
    caja(1, y + 10, 9, y + 16, PAPEL); caja(3, y + 9, 10, y + 14, tono(PAPEL, 1.05))                 # los papeles
    for dy in (10, 12):
        caja(4, y + dy, 9, y + dy + 1, (150, 150, 145), raya=False)                                  # sus renglones
    caja(12, y + 11, 32, y + 16, tono(BEIS, 1.05))                                                   # el teclado
    for kx in range(13, 31, 2):
        for ky in (12, 14):
            caja(kx, y + ky, kx + 1, y + ky + 1, (140, 135, 120), raya=False)                        # sus teclas
    caja(35, y + 10, 43, y + 16, (50, 60, 85))                                                       # la alfombrilla
    caja(38, y + 11, 40, y + 14, tono(BEIS, 1.05))                                                   # el ratón
    caja(38, y + 8, 39, y + 11, (90, 85, 80), raya=False)                                            # su cable
    caja(38, y + 2, 44, y + 5, SANGRE, raya=False); caja(42, y + 5, 44, y + 7, SANGRE, raya=False)   # sangre
    caja(26, y + 16, 29, y + 17, SANGRE, raya=False)

    # el ordenador de los 90, beis, apoyado al fondo de la tapa: la caja (de las de tumbar, con la disquetera y la luz
    # verde) y, encima, el monitor con la pantalla encendida. De él se ve la parte de arriba (lo que va hacia la pared)
    # y la cara de delante
    caja(10, 15, 34, 22, tono(BEIS, 0.88))                                                           # la caja
    caja(25, 17, 32, 18, OSCURO, raya=False)                                                         # la disquetera
    caja(12, 18, 13, 19, (80, 200, 90), raya=False)                                                  # la luz
    for vx in range(15, 22, 2):
        caja(vx, 19, vx + 1, 21, tono(BEIS, 0.7), raya=False)                                        # la rejilla
    caja(15, 0, 29, 4, tono(BEIS, 1.08))                                                             # el monitor, por arriba
    caja(13, 3, 31, 16, BEIS)                                                                        # su cara
    caja(15, 5, 29, 14, PANTALLA)                                                                    # la pantalla
    caja(16, 6, 23, 7, (200, 240, 255), raya=False); caja(16, 8, 21, 9, (200, 240, 255), raya=False)  # unas letras
    caja(16, 10, 25, 11, (200, 240, 255), raya=False)
    caja(27, 14, 30, 15, tono(BEIS, 0.7), raya=False)                                                # sus botones

    # el frente: el faldón; debajo, el panel del fondo a la sombra (y por debajo el suelo); la pata de la izquierda y
    # la cajonera de la derecha con tres cajones y sus tiradores; y un goterón de sangre que cae por el faldón
    y = MONITOR + TAPA
    caja(3, y + 3, 32, y + 10, OSCURO, raya=False)
    caja(0, y, ANCHO, y + 3, tono(MADERA, 0.7))
    caja(0, y, 3, y + FRENTE, tono(MADERA, 0.6))
    caja(32, y, ANCHO, y + FRENTE, tono(MADERA, 0.8))
    for dy in (1, 6, 11):
        caja(33, y + dy, ANCHO - 1, y + dy + 4, tono(MADERA, 0.9))
        caja(38, y + dy + 1, 42, y + dy + 2, ACERO, raya=False)
    caja(42, y, 44, y + 4, SANGRE, raya=False)

    os.makedirs(os.path.dirname(GUIA), exist_ok=True)
    im.save(GUIA)
    print(GUIA, im.size)


def sombra(ruta):
    """Quita la sombra azulada que PixelLab pinta en el suelo, debajo de la mesa y a su lado (sobrescribe el
    archivo, ya sin fondo): lo azulado pegado a lo transparente, solo en la mitad de abajo, que arriba está la
    pantalla. Los tiradores azulados de los cajones no se tocan: están rodeados de madera"""
    im = Image.open(ruta).convert('RGBA')
    px = im.load()
    W, H = im.size

    def azulado(c):
        return c[3] > 0 and c[2] > c[0] + 12 and c[2] >= c[1]

    pila = [(x, y) for y in range(H // 2, H) for x in range(W) if px[x, y][3] == 0]
    visto = set()
    while pila:
        x, y = pila.pop()
        for v in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if v in visto or not (0 <= v[0] < W and H // 2 <= v[1] < H):
                continue
            visto.add(v)
            if azulado(px[v]):
                px[v] = (0, 0, 0, 0)
                pila.append(v)
    im.save(ruta)
    print('sin sombra:', ruta)


def monta():
    """La elegida (ya sin fondo) → el sprite del juego, con la receta de los muebles (tools/importar.py): reducida a
    48 píxeles de ancho y con el contorno oscuro"""
    out = convierte(ORIGINAL, ANCHO, halo=False)
    out.save(SPRITE)
    print(SPRITE, out.size)


if __name__ == '__main__':
    if sys.argv[1:2] == ['guia']:
        guia()
    elif sys.argv[1:2] == ['sombra']:
        for r in sys.argv[2:]:
            sombra(r)
    else:
        monta()
