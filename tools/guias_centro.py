"""Bocetos (guías) para pedir a PixelLab los muebles del centro comercial rectos, sin girar.

PixelLab, si se le pide un mueble "en tres cuartos" sin más, a veces lo dibuja girado en diagonal. Con una guía
como imagen de partida (create_image_pixflux con init_image, fuerza 40-50) no puede: la guía ya tiene la forma del
mueble en la perspectiva del juego, y PixelLab solo la "viste".

La perspectiva del juego (la de los personajes y las paredes): el suelo se ve desde arriba sin encoger y lo que tiene
altura sube hacia arriba de la pantalla. Así que un mueble es:
  - de frente (pared de arriba): su tapa, de largo × fondo, y debajo su frente, de largo × alto;
  - de lado (paredes de los lados; hecho para la izquierda, en la derecha va en espejo): su tapa, de fondo × largo
    (tumbada a lo largo de la pared), y debajo su costado corto, de fondo × alto. Lo que mira a la habitación no se
    ve (como en Stardew Valley con los muebles girados).
Todo en píxeles del juego (largo y fondo = los del catálogo / 2). La guía se pinta al doble (cada píxel del juego,
2×2) con un margen, sobre azul (FONDO): con fondo transparente PixelLab se come la tapa del mueble. El azul se
quita después. Las tapas llevan dibujado lo que hay encima (fuegos, la caja registradora, cajas...): si la tapa es
lisa, PixelLab la deja lisa.

  py tools/guias_centro.py               → assets/sources/centro/guias/<archivo>[-lado].png
  py tools/guias_centro.py quita <png>…  quita el fondo azul de lo que devuelve PixelLab (lo deja transparente)
"""
import os, random, sys
from PIL import Image, ImageDraw

OUT = 'assets/sources/centro/guias'
S = 2        # píxeles de la guía por píxel del juego
M = 4        # margen
RAYA = (30, 26, 44, 255)
FONDO = (96, 112, 150)   # el azul de fondo (el mismo de tools/muebles3c.py del juego JS)
PRODUCTOS = [(170, 60, 50), (60, 120, 70), (190, 160, 70), (70, 90, 150), (200, 200, 190), (150, 90, 140)]

# archivo: (largo, fondo, alto, respaldo, color, estilo, lleva_lado)
#   respaldo   alto de un panel que sube por detrás (el tablero de herramientas); 0 = nada
#   estilo     cómo se pinta el frente: estantes, puertas-N, cristal, liso, mesa, cajas, carrito...
#   lleva_lado  si tiene dibujo de lado. Los altos (estanterías, taquillas, neveras) no: vistos desde arriba son
#               una barra larga que no se entiende (lo mismo pasó en los pisos con la cama y el armario), así que
#               van solo en la pared del fondo
#   lo de encima de la tapa, en encima() por el nombre
T = {
    'gondola':            (124, 44, 40, 0,  (120, 125, 130), 'estantes', False),
    'caja':               (96,  48, 22, 0,  (110, 100, 95),  'liso',     True),
    'nevera-bebidas':     (56,  48, 48, 0,  (60, 70, 85),    'cristal',  False),
    'perchero-ropa':      (88,  36, 36, 0,  (110, 70, 70),   'ropa',     True),
    'estanteria-teles':   (116, 40, 40, 0,  (70, 60, 60),    'teles',    False),
    'mostrador-farmacia': (100, 48, 26, 0,  (150, 150, 140), 'vitrina',  False),
    'estanteria-metal':   (80,  40, 46, 0,  (110, 115, 120), 'cajas',    False),
    'pale':               (68,  56, 28, 0,  (160, 120, 80),  'pale',     False),
    'taquillas':          (100, 40, 46, 0,  (95, 105, 100),  'puertas-4', False),
    'banco-trabajo':      (100, 48, 22, 20, (140, 100, 60),  'mesa',     True),
    'estanteria-camara':  (84,  44, 46, 0,  (150, 170, 185), 'camara',   False),
    'fogon-industrial':   (84,  54, 22, 0,  (140, 145, 150), 'horno',    True),
    'mesa-acero':         (88,  48, 22, 0,  (150, 155, 160), 'mesa',     False),
    'freidora':           (48,  48, 22, 0,  (140, 145, 150), 'liso',     False),
    'carrito':            (52,  40, 24, 0,  (130, 135, 140), 'carrito',  False),
    'mesa-restaurante':   (96,  64, 18, 0,  (190, 160, 110), 'mesa',     False),
    'banco-galeria':      (92,  36, 12, 14, (120, 85, 55),   'banco',    True),
    # la joyería (parte 9): la vitrina baja (mostrador de cristal con joyas), la vitrina alta y la caja fuerte
    'vitrina-joyeria':    (96,  44, 26, 0,  (120, 100, 80),  'vitrina',  True),
    'vitrina-alta':       (64,  36, 46, 0,  (80, 65, 55),    'cristal',  False),
    'caja-fuerte':        (56,  48, 46, 0,  (75, 80, 90),    'cajafuerte', False),
}


def tono(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c) + (255,)


class Tapa:
    """La tapa del mueble vista desde arriba. Se dibuja en (u, v) de 0 a 1: u a lo largo del mueble, v de la
    pared (0) hacia la habitación (1). De frente, u va a la derecha y v hacia abajo; de lado, u hacia abajo y v
    a la derecha."""
    def __init__(self, dr, x, y, w, d, lado):
        self.dr, self.x, self.y, self.w, self.d, self.lado = dr, x, y, w, d, lado

    def caja(self, u0, v0, u1, v1, color, raya=True):
        if self.lado:
            r = (self.x + v0 * self.w, self.y + u0 * self.d, self.x + v1 * self.w, self.y + u1 * self.d)
        else:
            r = (self.x + u0 * self.w, self.y + v0 * self.d, self.x + u1 * self.w, self.y + v1 * self.d)
        r = tuple(int(round(a / S)) * S for a in r)
        r = (r[0], r[1], max(r[2], r[0] + S), max(r[3], r[1] + S))   # al menos un píxel del juego
        self.dr.rectangle((r[0], r[1], r[2] - 1, r[3] - 1), fill=color if len(color) == 4 else color + (255,),
                          outline=RAYA if raya else None)

    def fuego(self, u, v, radio):
        cx, cy = (self.x + v * self.w, self.y + u * self.d) if self.lado else (self.x + u * self.w, self.y + v * self.d)
        r = radio * S
        self.dr.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(35, 35, 40, 255), outline=RAYA)
        self.dr.ellipse((cx - r // 2, cy - r // 2, cx + r // 2, cy + r // 2), outline=(90, 90, 95, 255))


def encima(t, nombre, color, rnd):
    """Lo que se ve encima de cada mueble, desde arriba"""
    if nombre in ('gondola', 'estanteria-teles'):
        t.caja(0, 0, 1, 0.12, tono(color, 0.6))   # el panel del fondo
        u = 0.03
        while u < 0.95:
            a = rnd.uniform(0.06, 0.12)
            c = (40, 45, 50) if nombre == 'estanteria-teles' else rnd.choice(PRODUCTOS)
            t.caja(u, 0.18, min(u + a, 0.97), rnd.uniform(0.5, 0.85), c)
            u += a + rnd.uniform(0.0, 0.05)
    elif nombre == 'estanteria-camara':
        # la tapa, cubierta de escarcha: manchas blancas sobre el metal, y un par de cajas encima
        for _ in range(14):
            u, v = rnd.uniform(0, 0.9), rnd.uniform(0, 0.85)
            t.caja(u, v, u + rnd.uniform(0.06, 0.16), v + rnd.uniform(0.1, 0.2), (225, 238, 245), False)
        t.caja(0.12, 0.2, 0.38, 0.75, (175, 195, 210))
        t.caja(0.6, 0.3, 0.82, 0.8, (175, 195, 210))
    elif nombre in ('estanteria-metal', 'pale'):
        u = 0.05
        while u < 0.85:
            a = rnd.uniform(0.2, 0.4)
            c = (150, 115, 75)
            t.caja(u, rnd.uniform(0.05, 0.2), min(u + a, 0.95), rnd.uniform(0.75, 0.95), c)
            u += a + rnd.uniform(0.03, 0.08)
    elif nombre == 'caja':
        t.caja(0.04, 0.3, 0.6, 0.8, (40, 40, 45))      # la cinta
        for k in range(1, 6):
            t.caja(0.04 + k * 0.56 / 6, 0.3, 0.04 + k * 0.56 / 6 + 0.01, 0.8, (70, 70, 75), False)
        t.caja(0.66, 0.1, 0.94, 0.75, (70, 72, 78))     # la caja registradora
        t.caja(0.7, 0.15, 0.9, 0.35, (90, 130, 120))    # su pantalla
    elif nombre == 'fogon-industrial':
        for i in range(3):
            for j in range(2):
                t.fuego(0.18 + i * 0.32, 0.3 + j * 0.42, 5)
    elif nombre == 'freidora':
        t.caja(0.08, 0.15, 0.46, 0.85, (90, 70, 30))     # las dos cubas de aceite
        t.caja(0.54, 0.15, 0.92, 0.85, (90, 70, 30))
        t.caja(0.12, 0.25, 0.42, 0.7, (150, 150, 150))   # las cestas
        t.caja(0.58, 0.25, 0.88, 0.7, (150, 150, 150))
    elif nombre == 'mesa-acero':
        t.caja(0.25, 0.2, 0.6, 0.75, (170, 120, 70))     # la tabla de cortar
        t.caja(0.65, 0.4, 0.9, 0.5, (190, 195, 200))     # el cuchillo
        t.caja(0.1, 0.25, 0.2, 0.5, (140, 30, 30))       # carne
    elif nombre == 'mostrador-farmacia':
        t.caja(0.03, 0.08, 0.97, 0.55, (130, 165, 170))  # la vitrina
        u = 0.07
        while u < 0.9:
            t.caja(u, 0.15, u + 0.06, 0.45, rnd.choice(PRODUCTOS))
            u += 0.1
    elif nombre == 'banco-trabajo':
        t.caja(0.05, 0.1, 0.18, 0.55, (60, 60, 65))      # el tornillo de banco
        t.caja(0.3, 0.3, 0.55, 0.42, (120, 80, 40))      # un martillo
        t.caja(0.5, 0.25, 0.58, 0.5, (80, 80, 85))
        t.caja(0.65, 0.2, 0.92, 0.6, (180, 180, 185))    # una sierra
    elif nombre == 'mesa-restaurante':
        t.caja(0.0, 0.15, 0.18, 0.85, (170, 40, 40))     # las dos sillas, a los lados
        t.caja(0.82, 0.15, 1.0, 0.85, (170, 40, 40))
        t.caja(0.22, 0.0, 0.78, 1.0, tono(color, 1.0))   # la mesa
        t.caja(0.38, 0.25, 0.62, 0.7, (190, 70, 50))     # una bandeja
    elif nombre == 'carrito':
        t.caja(0.2, 0.2, 0.5, 0.6, (170, 60, 50))
        t.caja(0.55, 0.4, 0.8, 0.8, (190, 160, 70))
    elif nombre == 'banco-galeria':
        t.caja(0, 0, 1, 0.25, tono(color, 0.6))          # el respaldo, contra la pared
        for k in range(3):
            t.caja(0, 0.3 + k * 0.23, 1, 0.3 + k * 0.23 + 0.18, tono(color, 1.0))
    elif nombre in ('taquillas', 'nevera-bebidas'):
        for k in range(1, 4):
            t.caja(0.1, k * 0.22, 0.9, k * 0.22 + 0.06, tono(color, 0.8), False)   # rejillas
    elif nombre == 'vitrina-joyeria':
        t.caja(0.03, 0.08, 0.97, 0.9, (130, 165, 170))      # el cristal de la tapa
        u = 0.07
        while u < 0.86:
            t.caja(u, 0.18, u + 0.12, 0.78, (60, 30, 70))   # bandejas de terciopelo...
            t.caja(u + 0.03, 0.3, u + 0.06, 0.42, (240, 220, 120), False)   # ...con joyas doradas y brillantes
            t.caja(u + 0.06, 0.55, u + 0.09, 0.67, (225, 235, 245), False)
            u += 0.16
    elif nombre == 'vitrina-alta':
        t.caja(0, 0, 1, 0.12, tono(color, 0.6))              # el panel del fondo
        t.caja(0.08, 0.2, 0.92, 0.85, tono(color, 0.95))     # la tapa de madera oscura


def frente(dr, x, y, w, h, color, estilo, rnd):
    """El frente (de frente) o el costado corto (de lado), en coordenadas de la guía"""
    if estilo == 'mesa':
        # un faldón arriba y dos patas: por debajo se ve el suelo
        dr.rectangle((x, y, x + w - 1, y + 4 * S - 1), fill=tono(color, 0.7), outline=RAYA)
        for px in (x, x + w - 3 * S):
            dr.rectangle((px, y, px + 3 * S - 1, y + h - 1), fill=tono(color, 0.6), outline=RAYA)
        return
    if estilo == 'carrito':
        dr.rectangle((x, y, x + w - 1, y + h - 5 * S), fill=tono(color, 0.75), outline=RAYA)
        for gx in range(x + 2 * S, x + w - 1, 3 * S):
            dr.line((gx, y, gx, y + h - 5 * S), fill=tono(color, 0.5))
        for px in (x + S, x + w - 4 * S):
            dr.rectangle((px, y + h - 3 * S, px + 3 * S - 1, y + h - 1), fill=RAYA)
        return
    if estilo == 'pale':
        dr.rectangle((x, y, x + w - 1, y + h - 4 * S), fill=(150, 120, 80, 255), outline=RAYA)   # cajas de cartón
        for bx in range(x, x + w, w // 2):
            dr.rectangle((bx, y, bx + w // 2 - 1, y + h - 4 * S), outline=RAYA)
        dr.rectangle((x, y + h - 4 * S, x + w - 1, y + h - 1), fill=(110, 80, 50, 255), outline=RAYA)  # el palé
        return
    if estilo == 'banco':
        dr.rectangle((x, y, x + w - 1, y + 3 * S - 1), fill=tono(color, 0.7), outline=RAYA)
        for px in (x, x + w - 3 * S):
            dr.rectangle((px, y, px + 3 * S - 1, y + h - 1), fill=(60, 60, 65, 255), outline=RAYA)
        return
    if estilo == 'ropa':
        dr.line((x, y, x + w - 1, y), fill=RAYA, width=S)
        cx = x + 2 * S
        while cx < x + w - 4 * S:
            cw = rnd.randint(4, 6) * S
            c = rnd.choice([(120, 50, 50), (60, 70, 110), (90, 90, 80), (130, 110, 70)])
            dr.rectangle((cx, y + S, cx + cw - 1, y + h * 2 // 3), fill=c + (255,), outline=RAYA)
            cx += cw
        for px in (x, x + w - S):
            dr.line((px, y, px, y + h - 1), fill=RAYA, width=S)
        return
    dr.rectangle((x, y, x + w - 1, y + h - 1), fill=tono(color, 0.72), outline=RAYA)
    if estilo == 'camara':
        # estantes metálicos con carne congelada (rojo con escarcha) y cajas blanquecinas; carámbanos bajo las baldas
        dr.rectangle((x + 2 * S, y + S, x + w - 3 * S, y + h - 2 * S), fill=tono(color, 0.4), outline=RAYA)
        n = 3
        paso = (h - 3 * S) / n
        for i in range(n):
            y1 = int(y + S + (i + 1) * paso)
            dr.rectangle((x + 2 * S, y1 - 2 * S, x + w - 3 * S, y1 - S), fill=tono(color, 1.0), outline=RAYA)   # la balda
            for k in range(x + 4 * S, x + w - 4 * S, 5 * S):   # carámbanos
                dr.rectangle((k, y1 - S, k + S - 1, y1 - S + rnd.randint(1, 2) * S), fill=(225, 238, 245, 255))
            bx = x + 3 * S
            while bx < x + w - 6 * S:
                bw = rnd.randint(5, 8) * S
                bh = rnd.randint(int(paso * 0.45), int(paso * 0.7))
                fin = min(bx + bw - 1, x + w - 4 * S)
                if rnd.random() < 0.6:   # carne congelada
                    dr.rectangle((bx, y1 - 2 * S - bh, fin, y1 - 2 * S - 1), fill=(150, 50, 55, 255), outline=RAYA)
                    dr.rectangle((bx + S, y1 - 2 * S - bh + S, fin - S, y1 - 2 * S - bh + 2 * S - 1), fill=(225, 238, 245, 255))
                else:                    # caja
                    dr.rectangle((bx, y1 - 2 * S - bh, fin, y1 - 2 * S - 1), fill=(185, 200, 210, 255), outline=RAYA)
                bx += bw + rnd.randint(0, 2) * S
        return
    if estilo in ('estantes', 'cajas', 'teles'):
        n = max(2, h // (11 * S))
        paso = h / n
        for i in range(n):
            y1 = int(y + (i + 1) * paso)
            dr.line((x + S, y1 - S, x + w - 2, y1 - S), fill=tono(color, 0.45))   # la balda
            bx = x + 2 * S
            while bx < x + w - 4 * S:
                bw = rnd.randint(3, 6 if estilo == 'estantes' else 9) * S
                bh = rnd.randint(int(paso * 0.45), int(paso * 0.8))
                c = rnd.choice(PRODUCTOS) if estilo == 'estantes' else (40, 45, 50) if estilo == 'teles' else (150, 115, 75)
                dr.rectangle((bx, y1 - S - bh, min(bx + bw - 1, x + w - 3 * S), y1 - S - 1), fill=c + (255,), outline=RAYA)
                if estilo == 'teles':
                    dr.rectangle((bx + S, y1 - bh, min(bx + bw - 2 * S, x + w - 4 * S), y1 - 3 * S), fill=(90, 120, 130, 255))
                bx += bw + rnd.randint(0, 2) * S
    elif estilo.startswith('puertas'):
        n = int(estilo.split('-')[1])
        for i in range(1, n):
            dr.line((x + w * i // n, y, x + w * i // n, y + h - 1), fill=RAYA)
        for i in range(n):
            gx = x + w * i // n
            for k in range(3):   # las rejillas de arriba
                dr.line((gx + 2 * S, y + 3 * S + k * 2 * S, gx + w // n - 3 * S, y + 3 * S + k * 2 * S), fill=tono(color, 0.5))
    elif estilo == 'cristal':
        dr.rectangle((x + 2 * S, y + 3 * S, x + w - 3 * S, y + h - 6 * S), fill=(110, 140, 150, 255), outline=RAYA)
        for i in range(1, 5):
            yy = y + 3 * S + (h - 9 * S) * i // 5
            dr.line((x + 3 * S, yy, x + w - 4 * S, yy), fill=(70, 80, 90, 255))
    elif estilo == 'vitrina':
        dr.rectangle((x + 2 * S, y + 2 * S, x + w - 3 * S, y + h // 2), fill=(120, 150, 150, 255), outline=RAYA)
    elif estilo == 'horno':
        dr.rectangle((x + 2 * S, y + 4 * S, x + w // 2 - 2 * S, y + h - 3 * S), fill=tono(color, 0.5), outline=RAYA)
        dr.rectangle((x + w // 2 + S, y + 4 * S, x + w - 3 * S, y + h - 3 * S), fill=tono(color, 0.5), outline=RAYA)
    elif estilo == 'cajafuerte':
        # la puerta de acero con la rueda de la combinación en medio y el tirador a la derecha
        dr.rectangle((x + 2 * S, y + 2 * S, x + w - 3 * S, y + h - 3 * S), fill=tono(color, 0.85), outline=RAYA)
        cx, cy = x + w // 2 - 2 * S, y + h // 2
        r = 5 * S
        dr.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(40, 40, 45, 255), outline=RAYA)
        dr.ellipse((cx - r // 2, cy - r // 2, cx + r // 2, cy + r // 2), outline=(160, 160, 170, 255))
        dr.rectangle((x + w - 9 * S, cy - S, x + w - 5 * S, cy + S), fill=(170, 170, 180, 255), outline=RAYA)


def costado(dr, x, y, w, h, color, estilo):
    """El costado corto (de lado): un panel liso, o las patas si es una mesa o un banco"""
    if estilo in ('mesa', 'banco'):
        dr.rectangle((x, y, x + w - 1, y + 3 * S), fill=tono(color, 0.7), outline=RAYA)
        for px in (x, x + w - 3 * S):
            dr.rectangle((px, y, px + 3 * S - 1, y + h - 1), fill=tono(color, 0.6), outline=RAYA)
    elif estilo == 'ropa':
        dr.rectangle((x + w // 2 - S, y, x + w // 2 + S - 1, y + h - 1), fill=RAYA)
        dr.rectangle((x + S, y + h - 2 * S, x + w - 2 * S, y + h - 1), fill=RAYA)
    else:
        dr.rectangle((x, y, x + w - 1, y + h - 1), fill=tono(color, 0.8), outline=RAYA)
        dr.line((x + 2 * S, y + 2 * S, x + 2 * S, y + h - 3 * S), fill=tono(color, 0.65))   # el canto de las baldas


def guia(nombre, largo, fondo, alto, respaldo, color, estilo, lado):
    w = (fondo if lado else largo) // 2 * S
    d = (largo if lado else fondo) // 2 * S
    h = alto * S
    p = 0 if lado else respaldo * S
    im = Image.new('RGBA', (w + 2 * M, p + d + h + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    rnd = random.Random(nombre + ('-lado' if lado else ''))
    x, y = M, M
    if p:   # el tablero de las herramientas, detrás
        dr.rectangle((x, y, x + w - 1, y + p + S), fill=(150, 120, 80, 255), outline=RAYA)
        for k in range(5):
            dr.rectangle((x + (2 + k * 4) * w // 22, y + 3 * S, x + (3 + k * 4) * w // 22, y + p - 3 * S), fill=(70, 70, 75, 255))
    if estilo == 'ropa':
        # el perchero no tiene tapa: de frente, la barra; de lado, la ropa colgada vista desde arriba
        if lado:
            dr.line((x + w // 2, y, x + w // 2, y + d - 1), fill=RAYA, width=S)
            cy = y + S
            while cy < y + d - 3 * S:
                ch = rnd.randint(3, 5) * S
                c = rnd.choice([(120, 50, 50), (60, 70, 110), (90, 90, 80), (130, 110, 70)])
                dr.rectangle((x + S, cy, x + w - 2 * S, cy + ch - 1), fill=c + (255,), outline=RAYA)
                cy += ch
        else:
            dr.line((x, y + d // 2, x + w - 1, y + d // 2), fill=RAYA, width=S)
    else:
        dr.rectangle((x, y + p, x + w - 1, y + p + d - 1),
                     fill=tono(color, 0.4) if estilo == 'carrito' else tono(color, 1.12), outline=RAYA)
        encima(Tapa(dr, x, y + p, w, d, lado), nombre, color, rnd)
    if lado:
        costado(dr, x, y + d, w, h, color, estilo)
    else:
        frente(dr, x, y + p + d, w, h, color, estilo, rnd)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}{"-lado" if lado else ""}.png'
    im.save(ruta)
    print(ruta, im.size)


def quita(ruta):
    """Quita el fondo: el color que más se repite en el borde de la imagen (PixelLab no siempre devuelve el mismo
    azul), y todo lo parecido que toque el borde (relleno desde los bordes)"""
    im = Image.open(ruta).convert('RGBA')
    px = im.load()
    W, H = im.size
    borde = [(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)]
    cuenta = {}
    for p in borde:
        c = px[p][:3]
        cuenta[c] = cuenta.get(c, 0) + 1
    fondo = max(cuenta, key=cuenta.get)
    def es_fondo(c):
        return c[3] == 0 or sum(abs(p - q) for p, q in zip(c[:3], fondo)) < 40
    pila = list(borde)
    visto = set()
    while pila:
        x, y = pila.pop()
        if (x, y) in visto or not (0 <= x < W and 0 <= y < H):
            continue
        visto.add((x, y))
        if es_fondo(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            pila += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    im.save(ruta)
    print('sin fondo:', ruta, fondo)


if __name__ == '__main__':
    if sys.argv[1:2] == ['quita']:
        for r in sys.argv[2:]:
            quita(r)
        sys.exit()
    for nombre, (largo, fondo, alto, respaldo, color, estilo, con_lado) in T.items():
        guia(nombre, largo, fondo, alto, respaldo, color, estilo, False)
        if con_lado:
            guia(nombre, largo, fondo, alto, respaldo, color, estilo, True)
