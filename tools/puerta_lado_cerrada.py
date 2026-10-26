"""La puerta de dentro cerrada en los tabiques verticales (scripts/mapa/puerta_bano.gd, hoja_de_lado): un tablón de madera
fino, del grueso de la puerta, metido en el hueco del tabique, con su pomo pequeño sobresaliendo por los dos lados.

Los tabiques verticales se ven planos, sin cara, así que la puerta cerrada se ve de canto: la hoja, tumbada a lo largo
del hueco (16 × 32 píxeles del juego; 32 × 64 unidades), con la bisagra arriba y el pomo hacia la punta de abajo, la que
se abre (ver tools/puerta_abierta.py, "lado"). Hasta el 26 oct era un rectángulo marrón liso con un cuadradito dorado;
una tanda de PixelLab con la puerta entera tumbada (assets/sources/puertas/descartes/bano-lado-cerrada-40x.png) se
descartó: la puerta llena el hueco y no era lo que se quería, sino un tablón fino.

A esa anchura (5 píxeles) PixelLab no puede dibujar más que un color por columna, así que el tablón se dibuja aquí con
la madera y el pomo de nuestra puerta de frente (assets/sprites/puerta-bano.png): su veta clara, su tono medio, su base
y su borde oscuro, con la veta repartida al azar a lo largo (una semilla fija: sale siempre igual).

  py tools/puerta_lado_cerrada.py     → assets/sprites/puerta-bano-lado-cerrada.png (16 × 32, con el fondo transparente)
"""
import os, random, sys
from PIL import Image

SPRITES = 'assets/sprites'
ANCHO, ALTO = 16, 32                 # el hueco, en píxeles del juego
X0, GROSOR = 5, 5                    # el tablón: de la columna 5 a la 9 (10 unidades, un poco más fino que el de antes)
LINEA = (29, 27, 44, 255)
# la madera de la puerta de frente, de fuera hacia dentro: la veta clara (con sus variantes), el tono medio y la base
CLARA = [(113, 75, 56), (112, 74, 55), (113, 79, 58), (111, 72, 54), (107, 72, 53), (102, 68, 51)]
MEDIA = [(88, 58, 43), (87, 57, 42), (88, 59, 44), (82, 57, 42)]
BASE = [(78, 54, 39), (74, 52, 38), (73, 50, 36), (78, 54, 39)]
Y_POMO = 22                          # la fila de arriba del pomo (de 2 de alto), hacia la punta de abajo


def tablon():
    rng = random.Random(7)
    im = Image.new('RGBA', (ANCHO, ALTO), (0, 0, 0, 0))
    # entre los dos contornos: la luz de la izquierda (veta clara), el tono medio y la sombra de la derecha (la base)
    for k, paleta in enumerate([CLARA, MEDIA, BASE]):
        y = 1
        while y < ALTO - 1:
            # la veta: tramos de 1 a 4 filas del mismo tono, como las vetas de un tablón
            color = rng.choice(paleta)
            largo = rng.randint(1, 4)
            for yy in range(y, min(ALTO - 1, y + largo)):
                im.putpixel((X0 + 1 + k, yy), color + (255,))
            y += largo
    # algunas vetas más marcadas: rayas oscuras y trocitos claros, con tonos de la propia puerta
    for _ in range(9):
        im.putpixel((X0 + rng.randint(1, 3), rng.randint(2, ALTO - 3)), (49, 35, 35, 255))
    for _ in range(5):
        im.putpixel((X0 + rng.randint(1, 2), rng.randint(2, ALTO - 3)), (127, 88, 64, 255))
    for y in range(1, ALTO - 1):   # los dos contornos largos
        im.putpixel((X0, y), LINEA)
        im.putpixel((X0 + GROSOR - 1, y), LINEA)
    for x in range(X0, X0 + GROSOR):   # los dos cantos de la hoja: arriba y abajo
        im.putpixel((x, 0), LINEA)
        im.putpixel((x, ALTO - 1), LINEA)
    # la sombra que echa en el suelo, a la derecha, fina y transparente
    for y in range(2, ALTO - 1):
        im.putpixel((X0 + GROSOR, y), (0, 0, 0, 70))
    return pomo(im)


def pomo(im):
    """El pomo, a cada lado de la hoja (una puerta lo lleva en las dos caras): una bolita de 2 × 2 de latón, con los
    píxeles del de nuestra puerta de frente, y su contorno, que sobresale 2 píxeles"""
    puerta = Image.open(f'{SPRITES}/puerta-bano.png').convert('RGBA')
    luz, medio, sombra = puerta.getpixel((24, 22)), puerta.getpixel((23, 21)), puerta.getpixel((23, 22))
    oscuro = puerta.getpixel((23, 24))
    for lado in (-1, 1):
        xs = (X0 - 2, X0 - 1) if lado < 0 else (X0 + GROSOR, X0 + GROSOR + 1)
        for dx, x in enumerate(xs):
            for dy in range(2):
                # luz arriba a la izquierda, sombra abajo a la derecha
                c = luz if (dx == 0 and dy == 0) else sombra if (dx == 1 and dy == 1) else medio
                im.putpixel((x, Y_POMO + dy), c)
        # su contorno: arriba, abajo y por fuera
        fuera = X0 - 3 if lado < 0 else X0 + GROSOR + 2
        for x in xs:
            im.putpixel((x, Y_POMO - 1), LINEA)
            im.putpixel((x, Y_POMO + 2), LINEA)
        for dy in range(2):
            im.putpixel((fuera, Y_POMO + dy), LINEA)
    return im


if __name__ == '__main__':
    im = tablon()
    im.save(f'{SPRITES}/puerta-bano-lado-cerrada.png')
    print(f'puerta-bano-lado-cerrada: {im.width}x{im.height}')
