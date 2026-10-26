"""La puerta de dentro cerrada en los tabiques verticales (scripts/mapa/puerta_bano.gd, hoja_de_lado): una hoja de madera
que llena todo el hueco (16 × 32 píxeles del juego: el grueso del muro por lo largo de la puerta), con sus paneles y su
pomo, en el mismo marrón que nuestra puerta de frente (assets/sprites/puerta-bano.png).

Hasta el 26 oct era una tira marrón lisa de 14 unidades de ancho en un hueco de 32, con un cuadradito dorado: dejaba
suelo a los dos lados, parecía flotar y no tenía nada del arte del resto. Como el resto de lo que hay en los tabiques
verticales (que se ven planos, sin cara), la puerta se ve desde arriba y por delante a la vez: tumbada a lo largo del
hueco, con la bisagra arriba y el pomo en la punta de abajo (la que se abre; ver tools/puerta_abierta.py, "lado").

Se hace como las demás: un boceto con la forma, sobre azul, que PixelLab "viste" (create_image_pixflux con init_image).

  py tools/puerta_lado_cerrada.py guia          → assets/sources/puertas/guias/bano-lado-cerrada.png (sobre azul)
  py tools/guias_centro.py quita <png>…         quita el fondo azul de lo que devuelve PixelLab
  py tools/puerta_lado_cerrada.py sprite <png>  → assets/sprites/puerta-bano-lado-cerrada.png (de un intento ya sin
                                                  fondo, a 16 × 32, con la madera al marrón de nuestra puerta)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, FONDO
from puerta_abierta import a_nuestra_madera, OUTLINE

SPRITES = 'assets/sprites'
SRC = 'assets/sources/puertas'
OUT = f'{SRC}/guias'
ANCHO, ALTO = 16, 32                 # el hueco: 32 × 64 unidades, en píxeles del juego
HOJA = (110, 75, 53, 255)            # los de la puerta de frente (tools/guias_puertas.py, 'bano')
PANEL = (90, 61, 43, 255)
JAMBA = (74, 49, 35, 255)
LATON = (216, 176, 74, 255)


def caja(dr, x, y, w, h, color):
    """Un rectángulo en píxeles del juego (se pinta al doble, dentro del margen)"""
    dr.rectangle([M + x * S, M + y * S, M + (x + w) * S - 1, M + (y + h) * S - 1], fill=color)


def guia():
    im = Image.new('RGBA', (ANCHO * S + 2 * M, ALTO * S + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    caja(dr, 0, 0, ANCHO, ALTO, OUTLINE)       # el contorno
    caja(dr, 1, 1, ANCHO - 2, ALTO - 2, JAMBA)  # el marco, a los lados
    caja(dr, 2, 1, ANCHO - 4, ALTO - 2, HOJA)   # la hoja, de punta a punta
    caja(dr, 4, 3, ANCHO - 8, 12, PANEL)         # sus dos paneles, a lo largo
    caja(dr, 4, 17, ANCHO - 8, 12, PANEL)
    caja(dr, 9, 24, 2, 2, LATON)                 # el pomo, hacia la punta de abajo
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/bano-lado-cerrada.png'
    im.save(ruta)
    print(ruta, im.size)


def pomo_de_laton(im):
    """PixelLab dibujó el pomo del intento 404 como un aro negro a la izquierda (x 0 a 3, y 16 a 18). Se borra (con los
    colores de su alrededor) y se pinta el de latón de nuestra puerta (sus tres píxeles, de puerta-bano.png), hacia la
    punta de abajo, la que se abre"""
    im.putpixel((0, 16), (31, 23, 18, 255))
    for y in (16, 17, 18):
        im.putpixel((1, y), (104, 72, 50, 255))
        im.putpixel((2, y), (132, 91, 63, 255))
        im.putpixel((3, y), (166, 116, 79, 255))
    pomo = Image.open(f'{SPRITES}/puerta-bano.png').convert('RGBA')
    for dx, dy in ((0, 0), (0, 1), (1, 1)):
        im.putpixel((11 + dx, 23 + dy), pomo.getpixel((23 + dx, 21 + dy)))
    return im


def sprite(ruta):
    """De un intento ya sin fondo: recortado y a la mitad (16 × 32, el hueco entero), la madera al marrón de nuestra
    puerta; por abajo y por los lados, sin transparencia (llena el hueco)"""
    im = Image.open(ruta).convert('RGBA')
    im = im.crop(im.getbbox())
    color = im.convert('RGBa').resize((ANCHO, ALTO), Image.BOX).convert('RGBA')
    out = Image.new('RGBA', (ANCHO, ALTO))
    for y in range(ALTO):
        for x in range(ANCHO):
            r, g, b, _ = color.getpixel((x, y))
            out.putpixel((x, y), (r, g, b, 255))
    out = pomo_de_laton(a_nuestra_madera(out))
    out.save(f'{SPRITES}/puerta-bano-lado-cerrada.png')
    print(f'puerta-bano-lado-cerrada: {out.width}x{out.height}')


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'sprite':
        sprite(sys.argv[2])
    else:
        guia()
