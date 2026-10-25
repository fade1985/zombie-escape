"""El cartel de la planta, de suelo a techo junto al ascensor (mapa/puerta.gd: cartel_planta) → guías para PixelLab y,
después, sprites.

Es el número de la planta (0, 1, 2 o 3) pintado con plantilla en la pared del pasillo, con «PLANTA» pequeño encima.
Mide 28 × 42 píxeles del juego (56 × 84 unidades): lo que hay entre el pie de la pared y su moldura de arriba (la cara
de la pared mide 96 unidades y la moldura, 12). Igual que las puertas (tools/guias_puertas.py), la guía es el dibujo
de antes de pedírselo a PixelLab: al doble (cada píxel del juego, 2×2), con un margen de azul alrededor, y se pasa a
create_image_pixflux como init_image (view side, no_background false). PixelLab solo la «viste» (pintura vieja,
desconchada). Luego se le quita el azul con guias_centro.py quita.

  py tools/guias_cartel.py               → assets/sources/cartel/guias/<n>.png
  py tools/guias_cartel.py quita <n>…    de assets/sources/cartel/intentos/<n>-a.png (lo que devolvió PixelLab; el
                                         elegido) quita el fondo azul, también en las lascas de pintura que se han
                                         caído, y lo deja en assets/sources/cartel/<n>.png
  py tools/guias_cartel.py sprites       → assets/sprites/cartel-planta-<n>.png (recortado y a la mitad)
"""
import os, shutil, sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, FONDO, quita

OUT = 'assets/sources/cartel/guias'
SPRITES = 'assets/sprites'
ANCHO, ALTO = 28, 42          # en píxeles del juego
PINTURA = (206, 176, 52, 255)  # amarillo de pintura vieja
FUENTES = 'C:/Windows/Fonts/'
# «PLANTA» en letras de 3 × 5 como las de puerta.gd (LETRITAS; la N, sin el medio lleno, para que no parezca una W):
# a la mitad, PixelLab se las come, así que se repintan encima
LETRITAS = {'P': ['XXX', 'X.X', 'XXX', 'X..', 'X..'], 'L': ['X..', 'X..', 'X..', 'X..', 'XXX'],
            'A': ['XXX', 'X.X', 'XXX', 'X.X', 'X.X'], 'N': ['XXX', 'X.X', 'X.X', 'X.X', 'X.X'],
            'T': ['XXX', '.X.', '.X.', '.X.', '.X.']}


def guia(numero):
    im = Image.new('RGBA', ((ANCHO * S) + M * 2, (ALTO * S) + M * 2), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    # «PLANTA», arriba, en letras de palo
    chica = ImageFont.truetype(FUENTES + 'arialbd.ttf', 12)
    dr.text((M + ANCHO * S / 2, M + 4), 'PLANTA', font=chica, fill=PINTURA, anchor='mt')
    # el número, grande, de alto casi todo lo que queda
    grande = ImageFont.truetype(FUENTES + 'impact.ttf', 74)
    dr.text((M + ANCHO * S / 2, M + ALTO * S - 2), str(numero), font=grande, fill=PINTURA, anchor='ms')
    os.makedirs(OUT, exist_ok=True)
    ruta = '%s/%s.png' % (OUT, numero)
    im.save(ruta)
    print(ruta, im.size)


def quita_fondo(n):
    """Lo elegido, sin fondo: el azul de alrededor (guias_centro.quita) y el de dentro, donde la pintura está desconchada
    (ahí se ve la pared, que en el juego es lo que hay detrás)"""
    origen = f'{OUT}/../intentos/{n}-a.png'
    destino = f'{OUT}/../{n}.png'
    shutil.copy(origen, destino)
    quita(destino)
    im = Image.open(destino).convert('RGBA')
    px = im.load()
    fondo = Image.open(origen).convert('RGB').getpixel((0, 0))
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            if c[3] and sum(abs(a - b) for a, b in zip(c[:3], fondo)) < 60 and c[2] > c[0] + 25:
                px[x, y] = (0, 0, 0, 0)
    im.save(destino)


def sprite(n):
    """Sin fondo → sprite: recortado sin el margen y a la mitad (PixelLab lo dibuja al doble, como la guía); cada
    píxel nuevo es el color medio de los que cubría, si pintaban algo"""
    im = Image.open(f'{OUT}/../{n}.png').convert('RGBA').crop((M, M, M + ANCHO * S, M + ALTO * S))
    color = im.convert('RGBa').resize((ANCHO, ALTO), Image.BOX).convert('RGBA')
    lleno = im.getchannel('A').resize((ANCHO, ALTO), Image.BOX)
    out = Image.new('RGBA', (ANCHO, ALTO))
    for y in range(ALTO):
        for x in range(ANCHO):
            if lleno.getpixel((x, y)) > 110:
                r, g, b, _ = color.getpixel((x, y))
                out.putpixel((x, y), (r, g, b, 255))
    # la palabra, repintada con el amarillo más repetido del número
    cuenta = {}
    for y in range(11, ALTO):
        for x in range(ANCHO):
            c = out.getpixel((x, y))
            if c[3]:
                cuenta[c] = cuenta.get(c, 0) + 1
    amarillo = max(cuenta, key=cuenta.get)
    for y in range(9):
        for x in range(ANCHO):
            out.putpixel((x, y), (0, 0, 0, 0))
    x0 = 3
    for i, letra in enumerate('PLANTA'):
        for fy, fila in enumerate(LETRITAS[letra]):
            for fx, c in enumerate(fila):
                if c == 'X':
                    out.putpixel((x0 + i * 4 + fx, 2 + fy), amarillo)
    ruta = f'{SPRITES}/cartel-planta-{n}.png'
    out.save(ruta)
    print(ruta, out.size)


if __name__ == '__main__':
    if sys.argv[1:2] == ['quita']:
        for n in sys.argv[2:]:
            quita_fondo(n)
    elif sys.argv[1:2] == ['sprites']:
        for n in '0123':
            sprite(n)
    else:
        for n in (sys.argv[1:] or '0123'):
            guia(n)
