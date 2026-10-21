"""Bocetos (guías) de los aparatos de la azotea del centro comercial, para pedírselos a PixelLab rectos.

Lo mismo que tools/guias_centro.py (de ahí salen la perspectiva, los colores de la raya y del fondo azul y cómo se
quita el fondo después), pero con los aparatos del tejado: el aire acondicionado, la climatizadora, la chimenea y
el extractor. Se ven todos de frente (están sueltos por la azotea, no contra una pared).

  py tools/guias_azotea.py                 → assets/sources/centro/guias/<archivo>.png
  py tools/guias_centro.py quita <png>…    quita el fondo azul de lo que devuelve PixelLab
"""
import os, random, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono, Tapa

# archivo: (largo, fondo, alto, color): largo y fondo en unidades (los del catálogo), alto en píxeles del juego
T = {
    'aire-acondicionado': (128, 72, 34, (165, 168, 160)),
    'climatizadora':      (184, 60, 30, (140, 150, 156)),
    'chimenea':           (48,  48, 56, (140, 72, 56)),
    'extractor':          (44,  44, 38, (165, 170, 175)),
}


def ventilador(dr, cx, cy, r, color):
    """Un ventilador grande visto desde arriba: la rejilla redonda y las aspas debajo"""
    dr.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(38, 40, 44, 255), outline=RAYA)
    for k in range(3):   # las aspas
        a = k * 2.094
        import math
        px, py = cx + math.cos(a) * r * 0.75, cy + math.sin(a) * r * 0.75
        dr.line((cx, cy, px, py), fill=tono(color, 0.75), width=3 * S)
    for f in (0.35, 0.7):   # los aros de la rejilla
        rr = r * f
        dr.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=tono(color, 0.9))
    dr.ellipse((cx - 2 * S, cy - 2 * S, cx + 2 * S, cy + 2 * S), fill=tono(color, 0.6), outline=RAYA)


def lamas(dr, x, y, w, h, color):
    """Una rejilla de lamas (rayas tumbadas) en el frente"""
    dr.rectangle((x, y, x + w - 1, y + h - 1), fill=tono(color, 0.5), outline=RAYA)
    for yy in range(y + 2 * S, y + h - S, 2 * S):
        dr.line((x + S, yy, x + w - 2, yy), fill=tono(color, 0.85))


def guia(nombre, largo, fondo, alto, color):
    w = largo // 2 * S
    d = fondo // 2 * S
    h = alto * S
    im = Image.new('RGBA', (w + 2 * M, d + h + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    rnd = random.Random(nombre)
    x, y = M, M
    t = Tapa(dr, x, y, w, d, False)
    if nombre == 'aire-acondicionado':
        # la tapa con los dos ventiladores y, en el frente, dos rejillas de lamas y la cajita de los cables
        dr.rectangle((x, y, x + w - 1, y + d - 1), fill=tono(color, 1.1), outline=RAYA)
        for u in (0.27, 0.69):
            ventilador(dr, x + u * w, y + d / 2, d * 0.4, color)
        dr.rectangle((x, y + d, x + w - 1, y + d + h - 1), fill=tono(color, 0.75), outline=RAYA)
        lamas(dr, x + 3 * S, y + d + 3 * S, w * 2 // 5, h - 7 * S, color)
        lamas(dr, x + w * 2 // 5 + 6 * S, y + d + 3 * S, w * 2 // 5, h - 7 * S, color)
        dr.rectangle((x + w - 12 * S, y + d + 4 * S, x + w - 4 * S, y + d + 13 * S), fill=tono(color, 0.6), outline=RAYA)
        dr.rectangle((x + 2 * S, y + d + h - 3 * S, x + w - 3 * S, y + d + h - 1), fill=(60, 60, 64, 255))   # las patas
    elif nombre == 'climatizadora':
        # una caja larga de chapa: en la tapa, paneles y el codo del conducto que se mete en el tejado
        dr.rectangle((x, y, x + w - 1, y + d - 1), fill=tono(color, 1.1), outline=RAYA)
        for k in range(1, 4):
            dr.line((x + w * k // 4, y + S, x + w * k // 4, y + d - 2), fill=tono(color, 0.85))
        t.caja(0.62, 0.15, 0.92, 0.85, tono(color, 0.95))   # el conducto, que sube...
        t.caja(0.67, 0.25, 0.87, 0.75, tono(color, 0.7))
        t.caja(0.08, 0.3, 0.2, 0.7, (50, 52, 56))           # una rejilla de salida
        dr.rectangle((x, y + d, x + w - 1, y + d + h - 1), fill=tono(color, 0.75), outline=RAYA)
        for k in range(3):   # las tres puertas de registro, con su asa
            px = x + 3 * S + k * (w - 6 * S) // 3
            pw = (w - 6 * S) // 3 - 2 * S
            dr.rectangle((px, y + d + 3 * S, px + pw, y + d + h - 5 * S), fill=tono(color, 0.68), outline=RAYA)
            dr.rectangle((px + pw - 5 * S, y + d + h // 2 - S, px + pw - 2 * S, y + d + h // 2 + S), fill=(50, 50, 55, 255))
        lamas(dr, x + 5 * S, y + d + 5 * S, 14 * S, h - 12 * S, color)
        dr.rectangle((x + 2 * S, y + d + h - 3 * S, x + w - 3 * S, y + d + h - 1), fill=(60, 60, 64, 255))
    elif nombre == 'chimenea':
        # de ladrillo, con su remate de hormigón y el agujero negro de hollín arriba
        dr.rectangle((x, y, x + w - 1, y + d - 1), fill=(150, 150, 145, 255), outline=RAYA)
        dr.rectangle((x + 4 * S, y + 4 * S, x + w - 5 * S, y + d - 5 * S), fill=(25, 22, 22, 255), outline=RAYA)
        dr.rectangle((x, y + d, x + w - 1, y + d + 3 * S), fill=(130, 130, 125, 255), outline=RAYA)
        dr.rectangle((x + S, y + d + 3 * S, x + w - 2 * S, y + d + h - 1), fill=tono(color, 0.9), outline=RAYA)
        fila = 0
        for yy in range(y + d + 3 * S, y + d + h - S, 4 * S):
            dr.line((x + S, yy, x + w - 2 * S, yy), fill=tono(color, 0.6))
            for xx in range(x + S + (fila % 2) * 4 * S, x + w - 2 * S, 8 * S):
                dr.line((xx, yy, xx, yy + 4 * S), fill=tono(color, 0.6))
            fila += 1
        dr.rectangle((x + 5 * S, y + d + 4 * S, x + w - 6 * S, y + d + 12 * S), fill=(40, 36, 36, 200))   # hollín
    elif nombre == 'extractor':
        # un extractor de turbina: la cúpula redonda de lamas en espiral, sobre su base cuadrada
        cx = x + w / 2
        r = w * 0.42
        cy = y + d / 2
        dr.rectangle((x, y, x + w - 1, y + d - 1), fill=tono(color, 0.8), outline=RAYA)       # la base, desde arriba
        dr.ellipse((cx - r, cy - r, cx + r, cy + r), fill=tono(color, 1.1), outline=RAYA)     # la cúpula
        import math
        for k in range(10):
            a = k * math.tau / 10
            dr.arc((cx - r, cy - r, cx + r, cy + r), math.degrees(a), math.degrees(a) + 20, fill=RAYA)
            dr.line((cx, cy, cx + math.cos(a) * r, cy + math.sin(a) * r), fill=tono(color, 0.75))
        dr.ellipse((cx - 2 * S, cy - 2 * S, cx + 2 * S, cy + 2 * S), fill=tono(color, 0.6), outline=RAYA)
        # de frente: la cúpula (con sus lamas tiesas), el cuello y la base
        top = y + d
        dr.rectangle((x + 3 * S, top, x + w - 4 * S, top + h * 3 // 5), fill=tono(color, 0.85), outline=RAYA)
        for xx in range(x + 5 * S, x + w - 5 * S, 3 * S):
            dr.line((xx, top + S, xx, top + h * 3 // 5 - 2), fill=tono(color, 0.6))
        dr.rectangle((x, top + h * 3 // 5, x + w - 1, y + d + h - 1), fill=tono(color, 0.7), outline=RAYA)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    for nombre, (largo, fondo, alto, color) in T.items():
        guia(nombre, largo, fondo, alto, color)
