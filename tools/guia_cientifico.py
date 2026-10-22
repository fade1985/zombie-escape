"""Bocetos para pedir a PixelLab el científico muerto (cientifico.gd), a la escala de Johnny (46 px de alto, cabeza de 14).

Uso:  py tools/guia_cientifico.py
Deja en assets/sources/cientifico-muerto/: guia-a.png (boca abajo, tumbado a lo largo, se ve la nuca) y guia-b.png
(boca arriba, con la cabeza arriba, se le ve la cara). 64x64, sobre transparente, con el charco de sangre debajo.
"""
from PIL import Image, ImageDraw

D = 'assets/sources/cientifico-muerto/'
LINEA = (20, 16, 18, 255)
PIEL = (232, 200, 170, 255)
PELO = (60, 45, 35, 255)
BATA = (236, 236, 230, 255)
SOMBRA = (190, 192, 200, 255)
PANTALON = (55, 58, 72, 255)
ZAPATO = (30, 24, 22, 255)
CHARCO = (110, 14, 22, 255)
CHARCO2 = (80, 8, 16, 255)
MANCHA = (130, 30, 30, 255)
TARJETA = (61, 99, 201, 255)


def caja(d, r, color):
    d.rectangle(r, fill=color, outline=LINEA)


def charco(d, cx, cy, rx, ry):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=CHARCO)
    d.ellipse([cx - rx + 6, cy - ry + 3, cx + rx - 10, cy + ry - 3], fill=CHARCO2)
    for x, y, r in [(cx - rx - 2, cy + 2, 2), (cx + rx, cy - 3, 2), (cx + 4, cy + ry + 1, 2)]:
        d.ellipse([x - r, y - r, x + r, y + r], fill=CHARCO)


def manchas(d, puntos):
    for x, y, r in puntos:
        d.ellipse([x - r, y - r, x + r, y + r], fill=MANCHA)


def guia_a():
    # boca abajo, a lo largo: la cabeza a la izquierda (se ve la nuca), un brazo estirado hacia arriba
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    charco(d, 22, 36, 20, 10)
    caja(d, [48, 25, 58, 31], PANTALON)          # piernas
    caja(d, [48, 32, 58, 38], PANTALON)
    caja(d, [58, 24, 62, 31], ZAPATO)
    caja(d, [58, 32, 62, 39], ZAPATO)
    caja(d, [20, 8, 26, 22], BATA)               # brazo estirado
    caja(d, [20, 3, 26, 8], PIEL)
    caja(d, [17, 22, 50, 41], BATA)              # la bata, hasta las rodillas
    d.line([20, 31, 48, 31], fill=SOMBRA)
    caja(d, [24, 39, 40, 44], BATA)              # el otro brazo, pegado
    caja(d, [40, 39, 44, 44], PIEL)
    manchas(d, [(24, 27, 3), (33, 35, 2), (42, 26, 2), (21, 37, 2)])
    caja(d, [5, 23, 19, 38], PELO)               # la cabeza: la nuca, toda pelo
    d.rectangle([14, 26, 17, 29], fill=PIEL)     # la oreja y el cuello
    d.rectangle([17, 28, 19, 33], fill=PIEL)
    im.save(D + 'guia-a.png')


def guia_b():
    # boca arriba, con la cabeza arriba: la cara se ve derecha (ojos cerrados, boca abierta)
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    charco(d, 32, 26, 22, 12)
    caja(d, [24, 46, 30, 55], PANTALON)          # piernas
    caja(d, [34, 46, 40, 55], PANTALON)
    caja(d, [23, 55, 30, 59], ZAPATO)
    caja(d, [34, 55, 41, 59], ZAPATO)
    caja(d, [44, 22, 55, 27], BATA)              # brazo abierto
    caja(d, [55, 21, 59, 27], PIEL)
    caja(d, [20, 19, 44, 47], BATA)              # la bata, hasta las rodillas, abierta por delante
    d.rectangle([29, 20, 35, 34], fill=(200, 205, 215, 255))
    d.line([32, 20, 32, 46], fill=SOMBRA)
    d.rectangle([22, 24, 25, 28], fill=TARJETA)
    caja(d, [15, 24, 20, 40], BATA)              # el otro brazo, pegado
    caja(d, [15, 40, 20, 44], PIEL)
    manchas(d, [(38, 30, 3), (26, 38, 2), (35, 43, 2), (41, 22, 2)])
    caja(d, [25, 5, 39, 20], PIEL)               # la cabeza
    d.rectangle([25, 5, 39, 9], fill=PELO)
    d.rectangle([25, 5, 26, 14], fill=PELO)
    d.rectangle([38, 5, 39, 14], fill=PELO)
    d.line([28, 13, 30, 13], fill=LINEA)         # ojos cerrados
    d.line([34, 13, 36, 13], fill=LINEA)
    d.rectangle([31, 16, 33, 17], fill=(70, 20, 25, 255))   # la boca abierta
    d.rectangle([25, 5, 39, 20], outline=LINEA)
    im.save(D + 'guia-b.png')


guia_a()
guia_b()
