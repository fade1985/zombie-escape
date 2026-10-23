"""Las puertas vistas de frente (mapa/puerta.gd y mapa/puerta_bano.gd) → bocetos para PixelLab y, después, sprites.

Igual que lo colgado de la portera (tools/guias_limpieza.py): la guía es la puerta tal y como se dibujaba antes con
código, al doble (cada píxel del juego, 2×2) y con un margen de azul alrededor. Se pasa a create_image_pixflux como
init_image (view side, no_background false) y PixelLab solo la "viste". Cuatro puertas:
  piso      la de cada piso de los Apartamentos (y la de la jefa y la de entrada vista desde dentro): de madera,
            de dos hojas (piso) o de una con su moldura alrededor (piso-sencilla)
  tienda    la de las tiendas del centro comercial: de cristal con marco de aluminio
  servicio  la de la sala de mantenimiento, en los dos edificios: de acero
  bano      la del baño donde se esconde el superviviente: una hoja de madera de interior, más estrecha y sin marco

  py tools/guias_puertas.py               → assets/sources/puertas/guias/<puerta>.png
  py tools/guias_centro.py quita <png>…    quita el fondo azul de lo que devuelve PixelLab
  py tools/guias_puertas.py sprites       → assets/sprites/puerta-<puerta>.png (de assets/sources/puertas/)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, RAYA, FONDO

OUT = 'assets/sources/puertas/guias'
SRC = 'assets/sources/puertas'
SPRITES = 'assets/sprites'
OUTLINE = (29, 27, 44, 255)
# puerta: (ancho, alto) en píxeles del juego, contorno incluido (los de puerta.gd y puerta_bano.gd entre 2)
TAMANO = {'piso': (36, 43), 'piso-sencilla': (36, 43), 'tienda': (36, 43), 'servicio': (36, 43), 'bano': (28, 43)}
# Lo que eligió el dueño (23 oct) de los intentos (descartes/): assets/sources/puertas/<puerta>.png, ya sin el fondo azul
# (la de la tienda, tal cual: PixelLab le pintó el suelo debajo y se queda como zócalo). De cada uno se recorta la
# puerta (en píxeles del original): la de piso, con la moldura de arriba, que sobresale un poco
RECORTE = {'piso': (3, 4, 76, 90), 'tienda': (4, 4, 76, 90), 'servicio': (4, 4, 76, 90), 'bano': (4, 4, 60, 90)}


def caja(dr, x, y, w, h, color, raya=False):
    """Un rectángulo en píxeles del juego (se pinta al doble, dentro del margen)"""
    dr.rectangle([M + x * S, M + y * S, M + (x + w) * S - 1, M + (y + h) * S - 1], fill=color,
                 outline=RAYA if raya else None, width=S)


def hoja_madera(dr, x, y, w, h, hoja, panel, pomo_x):
    caja(dr, x, y, w, h, hoja)
    caja(dr, x + 2, y + 3, w - 4, h // 2 - 5, panel)
    caja(dr, x + 2, y + h // 2 + 1, w - 4, h // 2 - 4, panel)
    caja(dr, pomo_x, y + h // 2 - 2, 2, 2, (216, 176, 74))


def guia(nombre):
    w, h = TAMANO[nombre]
    im = Image.new('RGBA', (w * S + 2 * M, h * S + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    if nombre == 'piso':
        # la de antes: marco oscuro, dos hojas con dos cuarterones cada una y los pomos en el medio
        caja(dr, 0, 0, w, h, (43, 29, 22), True)
        for x in (2, 19):
            hoja_madera(dr, x, 3, 15, h - 3, (107, 67, 41), (87, 52, 32), 15 if x == 2 else 19)
        caja(dr, 17, 3, 2, h - 3, (43, 29, 22))
        caja(dr, 11, 13, 2, 2, (20, 16, 14))   # la mirilla
    elif nombre == 'piso-sencilla':
        # una sola hoja, con la moldura de madera alrededor
        caja(dr, 0, 0, w, h, (70, 46, 30), True)
        caja(dr, 2, 2, w - 4, h - 2, (96, 62, 40))
        caja(dr, 4, 4, w - 8, h - 4, (43, 29, 22))
        hoja_madera(dr, 5, 5, w - 10, h - 5, (107, 67, 41), (87, 52, 32), w - 10)
        caja(dr, w // 2 - 1, 12, 2, 2, (20, 16, 14))   # la mirilla
    elif nombre == 'tienda':
        # marco de aluminio, dos hojas de cristal con la tienda oscura detrás, tiradores y el zócalo de abajo
        caja(dr, 0, 0, w, h, (150, 155, 160), True)
        for x in (2, 19):
            caja(dr, x, 2, 15, h - 7, (36, 48, 58))
            for i in range(3):   # reflejos en diagonal
                for k in range(6):
                    caja(dr, x + 3 + i * 4 + k // 2, 4 + i * 9 + k * 2, 1, 2, (78, 98, 110))
        caja(dr, 17, 2, 2, h - 2, (120, 125, 130))
        caja(dr, 0, h - 5, w, 5, (130, 135, 140))
        caja(dr, 14, 16, 1, 12, (205, 210, 215))
        caja(dr, 21, 16, 1, 12, (205, 210, 215))
    elif nombre == 'servicio':
        # dos hojas de acero con su ventanuco de cristal armado, la barra antipánico y la rejilla de abajo
        caja(dr, 0, 0, w, h, (60, 66, 66), True)
        for x in (2, 19):
            caja(dr, x, 2, 15, h - 2, (110, 118, 116))
            caja(dr, x + 4, 6, 7, 9, (40, 50, 56))
            caja(dr, x + 2, 34, 11, 1, (70, 76, 76))
            caja(dr, x + 2, 36, 11, 1, (70, 76, 76))
            caja(dr, x + 2, 38, 11, 1, (70, 76, 76))
        caja(dr, 17, 2, 2, h - 2, (60, 66, 66))
        caja(dr, 3, 23, w - 6, 2, (170, 175, 172))
    else:
        # bano: una hoja de madera de interior, sin marco (el hueco es del tabique)
        caja(dr, 0, 0, w, h, (74, 49, 35), True)
        hoja_madera(dr, 2, 2, w - 4, h - 2, (110, 75, 53), (90, 61, 43), w - 7)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


def sprite(nombre):
    """Ya sin fondo → sprite: recortado, a la mitad (PixelLab lo dibuja al doble, como la guía), justo del tamaño de la
    puerta de antes y con el contorno de los muebles (la receta de tools/importar.py) a los lados y arriba: abajo está
    el suelo"""
    w, h = TAMANO[nombre]
    im = Image.open(f'{SRC}/{nombre}.png').convert('RGBA').crop(RECORTE[nombre])
    # color medio de cada píxel nuevo, contando solo lo que no es fondo
    color = im.convert('RGBa').resize((w - 2, h - 1), Image.BOX).convert('RGBA')
    lleno = im.getchannel('A').resize((w - 2, h - 1), Image.BOX)
    out = Image.new('RGBA', (w, h))
    for y in range(h - 1):
        for x in range(w - 2):
            if lleno.getpixel((x, y)) > 110:
                r, g, b, _ = color.getpixel((x, y))
                out.putpixel((x + 1, y + 1), (r, g, b, 255))
    # contorno: cada hueco vacío pegado al dibujo (menos por abajo)
    borde = [(x, y) for y in range(h - 1) for x in range(w) if out.getpixel((x, y))[3] == 0 and any(
        0 <= x + dx < w and 0 <= y + dy < h and out.getpixel((x + dx, y + dy))[3] == 255
        for dx, dy in ((1, 0), (-1, 0), (0, 1)))]
    for p in borde:
        out.putpixel(p, OUTLINE)
    out.save(f'{SPRITES}/puerta-{nombre}.png')
    print(f'puerta-{nombre}: {w}x{h}')


if __name__ == '__main__':
    if sys.argv[1:2] == ['sprites']:
        for nombre in RECORTE:
            sprite(nombre)
        sys.exit()
    for nombre in TAMANO:
        guia(nombre)
