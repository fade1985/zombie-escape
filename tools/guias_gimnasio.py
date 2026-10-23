"""Bocetos (guías) de las máquinas del gimnasio del Gymbro (su habitación), para pedírselas a PixelLab rectas.

Lo mismo que tools/guias_centro.py (de ahí salen la perspectiva, los colores de la raya y del fondo azul y cómo se
quita el fondo después), con las máquinas de un gimnasio: la cinta de correr, el banco de press con su barra, la
máquina de poleas, el estante de mancuernas y la pila de discos. Las que tienen algo alto detrás (la consola de la
cinta, la barra del banco) lo llevan pintado encima de la tapa, subido lo que mide de alto.

  py tools/guias_gimnasio.py               → assets/sources/centro/guias/<archivo>[-lado].png
  py tools/guias_centro.py quita <png>…    quita el fondo azul de lo que devuelve PixelLab
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono, Tapa

NEGRO = (40, 40, 46)
ACERO = (170, 175, 185)
ROJO = (140, 40, 40)
# archivo: (largo, fondo, alto, arriba, color, lleva_lado): largo y fondo en unidades (los del catálogo); alto (el
# frente) y arriba (lo que sube por detrás de la tapa), en píxeles del juego
T = {
    'cinta-correr':       (56,  100, 6,  28, (90, 95, 105),   True),
    'banco-press':        (104, 72,  10, 24, (90, 95, 105),   True),
    'maquina-poleas':     (100, 52,  50, 0,  (110, 115, 125), False),
    'estante-mancuernas': (112, 40,  22, 0,  (90, 95, 105),   True),
    'discos':             (44,  44,  14, 0,  (60, 62, 70),    False),
}


def caja(dr, x0, y0, x1, y1, color):
    dr.rectangle((x0, y0, x1 - 1, y1 - 1), fill=color if len(color) == 4 else color + (255,), outline=RAYA)


def mancuerna(dr, x, y, largo, tumbada, color=NEGRO):
    """Una mancuerna vista desde arriba: la barra y un disco en cada punta (tumbada: a lo largo de la x)"""
    if tumbada:
        caja(dr, x, y + S, x + largo, y + 2 * S, ACERO)
        caja(dr, x, y - S, x + 2 * S, y + 4 * S, color)
        caja(dr, x + largo - 2 * S, y - S, x + largo, y + 4 * S, color)
    else:
        caja(dr, x + S, y, x + 2 * S, y + largo, ACERO)
        caja(dr, x - S, y, x + 4 * S, y + 2 * S, color)
        caja(dr, x - S, y + largo - 2 * S, x + 4 * S, y + largo, color)


def cinta(dr, x, y, w, d, h, a, color, lado):
    if not lado:
        # la consola (contra la pared, arriba) con sus dos postes, subida "a"; debajo la cinta vista desde arriba
        for px in (x + S, x + w - 3 * S):
            caja(dr, px, y + 4 * S, px + 2 * S, y + a + 2 * S, tono(color, 0.8))
        caja(dr, x, y, x + w, y + 8 * S, tono(color, 0.9))
        caja(dr, x + w // 4, y + 2 * S, x + w * 3 // 4, y + 6 * S, (70, 110, 120))   # la pantalla
        top = y + a
        caja(dr, x, top, x + w, top + d, tono(color, 1.1))                              # los raíles
        caja(dr, x + 4 * S, top + 6 * S, x + w - 4 * S, top + d - 2 * S, NEGRO)          # la cinta
        for yy in range(top + 9 * S, top + d - 3 * S, 4 * S):
            dr.line((x + 5 * S, yy, x + w - 5 * S, yy), fill=(60, 60, 68))
        caja(dr, x, top, x + w, top + 6 * S, tono(color, 0.85))                         # la tapa del motor
        caja(dr, x, top + d, x + w, top + d + h, tono(color, 0.7))                      # el canto de atrás
    else:
        # tumbada: sale de la pared (izquierda) hacia la habitación; la consola, subida, contra la pared
        top = y + a
        caja(dr, x, top, x + w, top + d, tono(color, 1.1))
        caja(dr, x + 6 * S, top + 4 * S, x + w - 2 * S, top + d - 4 * S, NEGRO)
        for xx in range(x + 9 * S, x + w - 3 * S, 4 * S):
            dr.line((xx, top + 5 * S, xx, top + d - 5 * S), fill=(60, 60, 68))
        caja(dr, x, top, x + 6 * S, top + d, tono(color, 0.85))
        for py in (top + S, top + d - 3 * S):   # los postes, de la base a la consola
            caja(dr, x + 2 * S, py - a + 4 * S, x + 4 * S, py + 2 * S, tono(color, 0.8))
        caja(dr, x, y, x + 8 * S, y + d, tono(color, 0.9))                              # la consola
        caja(dr, x + 2 * S, y + d // 4, x + 6 * S, y + d * 3 // 4, (70, 110, 120))
        caja(dr, x, top + d, x + w, top + d + h, tono(color, 0.7))                      # el costado largo


def banco(dr, x, y, w, d, h, a, color, lado):
    if not lado:
        top = y + a
        # el banco, de la pared hacia la habitación, visto desde arriba (el respaldo acolchado)
        caja(dr, x + w * 2 // 5, top + 4 * S, x + w * 3 // 5, top + d, tono(ROJO, 1.0))
        caja(dr, x + w * 2 // 5, top + d, x + w * 3 // 5, top + d + h, tono(ROJO, 0.7))   # su frente
        for px in (x + w * 2 // 5 + S, x + w * 3 // 5 - 3 * S):                           # las patas
            caja(dr, px, top + d + 2 * S, px + 2 * S, top + d + h, NEGRO)
        # los dos soportes de la barra, al principio del banco, y la barra con sus discos, subida "a"
        for px in (x + w // 4, x + w * 3 // 4 - 2 * S):
            caja(dr, px, y + 4 * S, px + 2 * S, top + 8 * S, tono(color, 0.9))
            caja(dr, px - S, top + 6 * S, px + 3 * S, top + 10 * S, tono(color, 0.7))      # su pie
        caja(dr, x, y + 4 * S, x + w, y + 6 * S, ACERO)                                    # la barra
        for px in (x + S, x + 4 * S, x + w - 4 * S, x + w - 7 * S):
            caja(dr, px, y, px + 3 * S, y + 10 * S, NEGRO)                                 # los discos, de canto
    else:
        top = y + a
        caja(dr, x + 4 * S, top + d * 2 // 5, x + w, top + d * 3 // 5, tono(ROJO, 1.0))     # el banco, hacia la habitación
        caja(dr, x + 4 * S, top + d * 3 // 5, x + w, top + d * 3 // 5 + h // 2, tono(ROJO, 0.7))
        for py in (top + d // 4, top + d * 3 // 4 - 2 * S):                                # los soportes
            caja(dr, x + 4 * S, py - a + 4 * S, x + 6 * S, py + 2 * S, tono(color, 0.9))
        caja(dr, x + 4 * S, y + 2 * S, x + 6 * S, y + d, ACERO)                             # la barra, a lo largo de la pared
        for py in (y, y + 3 * S, y + d - 3 * S, y + d - 6 * S):
            caja(dr, x, py, x + 10 * S, py + 3 * S, NEGRO)                                 # los discos, desde arriba


def poleas(dr, x, y, w, d, h, color):
    # desde arriba: las dos torres y la viga que las une
    caja(dr, x, y, x + w, y + d, tono(color, 0.5))
    caja(dr, x, y, x + 8 * S, y + d, tono(color, 1.1))
    caja(dr, x + w - 8 * S, y, x + w, y + d, tono(color, 1.1))
    caja(dr, x, y + d // 3, x + w, y + d * 2 // 3, tono(color, 1.0))
    top = y + d
    # de frente: el marco, la pila de pesas en medio (placas con el pasador), las poleas arriba y los cables
    for px in (x, x + w - 8 * S):
        caja(dr, px, top, px + 8 * S, top + h, tono(color, 0.8))
    caja(dr, x, top, x + w, top + 5 * S, tono(color, 0.9))
    caja(dr, x + w * 3 // 8, top + 12 * S, x + w * 5 // 8, top + h - 4 * S, NEGRO)
    for yy in range(top + 14 * S, top + h - 5 * S, 3 * S):
        dr.line((x + w * 3 // 8 + S, yy, x + w * 5 // 8 - 2 * S, yy), fill=(75, 75, 85))
    caja(dr, x + w // 2 - S, top + 5 * S, x + w // 2 + S, top + 12 * S, ACERO)              # la barra de la pila
    caja(dr, x + w * 5 // 8 - 3 * S, top + 26 * S, x + w * 5 // 8 + S, top + 28 * S, ROJO)  # el pasador
    for px in (x + 9 * S, x + w - 13 * S):
        dr.ellipse((px, top + 6 * S, px + 4 * S, top + 10 * S), fill=NEGRO + (255,), outline=RAYA)   # las poleas
        dr.line((px + 2 * S, top + 10 * S, px + 2 * S, top + h - 12 * S), fill=(30, 30, 34), width=S // 2 or 1)
        caja(dr, px - S, top + h - 12 * S, px + 5 * S, top + h - 10 * S, ACERO)          # los agarres
    caja(dr, x + 8 * S, top + h - 4 * S, x + w - 8 * S, top + h, tono(color, 0.6))        # la base


def estante(dr, x, y, w, d, h, color, lado):
    if not lado:
        caja(dr, x, y, x + w, y + d, tono(color, 1.1))
        n = 5
        for i in range(n):   # mancuernas en la balda de arriba, de cada vez más grandes
            mancuerna(dr, x + 4 * S + i * (w - 8 * S) // n, y + 4 * S, d - 8 * S, False)
        top = y + d
        caja(dr, x, top, x + w, top + h, tono(color, 0.7))
        caja(dr, x + 2 * S, top + 3 * S, x + w - 2 * S, top + h - 6 * S, tono(color, 0.4))
        for i in range(n):   # en la de abajo se ven los discos de frente
            cx = x + 6 * S + i * (w - 10 * S) // n
            caja(dr, cx, top + 5 * S, cx + 5 * S, top + h - 7 * S, NEGRO)
        for px in (x, x + w - 3 * S):
            caja(dr, px, top, px + 3 * S, top + h, tono(color, 0.55))
    else:
        caja(dr, x, y, x + w, y + d, tono(color, 1.1))
        n = 5
        for i in range(n):
            mancuerna(dr, x + 4 * S, y + 4 * S + i * (d - 8 * S) // n, w - 8 * S, True)
        caja(dr, x, y + d, x + w, y + d + h, tono(color, 0.7))
        for px in (x, x + w - 3 * S):
            caja(dr, px, y + d, px + 3 * S, y + d + h, tono(color, 0.55))


def discos(dr, x, y, w, d, h, color):
    # una pila de discos en el suelo, de los grandes a los pequeños: desde arriba, círculos; de frente, cantos
    cx = x + w // 2
    for i, f in enumerate((1.0, 0.82, 0.64)):
        r = int(w / 2 * f)
        yy = y + i * 3 * S
        dr.ellipse((cx - r, yy + d // 2 - int(d / 2 * f), cx + r, yy + d // 2 + int(d / 2 * f)),
                   fill=tono(color, 1.0 + 0.15 * i), outline=RAYA)
    dr.ellipse((cx - 3 * S, y + 6 * S + d // 2 - 3 * S, cx + 3 * S, y + 6 * S + d // 2 + 3 * S), fill=(25, 25, 28, 255), outline=RAYA)
    caja(dr, x, y + d // 2 + 6 * S, x + w, y + d + h, tono(color, 0.7))
    for k in range(1, 4):
        dr.line((x + S, y + d // 2 + 6 * S + k * 4 * S, x + w - 2 * S, y + d // 2 + 6 * S + k * 4 * S), fill=RAYA)


def guia(nombre, largo, fondo, alto, arriba, color, lado):
    w = (fondo if lado else largo) // 2 * S
    d = (largo if lado else fondo) // 2 * S
    h = alto * S
    a = arriba * S
    im = Image.new('RGBA', (w + 2 * M, a + d + h + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    x, y = M, M
    if nombre == 'cinta-correr':
        cinta(dr, x, y, w, d, h, a, color, lado)
    elif nombre == 'banco-press':
        banco(dr, x, y, w, d, h, a, color, lado)
    elif nombre == 'maquina-poleas':
        poleas(dr, x, y, w, d, h, color)
    elif nombre == 'estante-mancuernas':
        estante(dr, x, y, w, d, h, color, lado)
    elif nombre == 'discos':
        discos(dr, x, y, w, d, h, color)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}{"-lado" if lado else ""}.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    for nombre, (largo, fondo, alto, arriba, color, con_lado) in T.items():
        guia(nombre, largo, fondo, alto, arriba, color, False)
        if con_lado:
            guia(nombre, largo, fondo, alto, arriba, color, True)
