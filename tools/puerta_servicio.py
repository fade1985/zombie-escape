# La puerta de la sala de mantenimiento vista de frente desde el pasillo (la de la placa con la llave inglesa, en los dos
# edificios: puerta.gd, "servicio"), más real (8 nov). La de PixelLab (assets/sources/puertas/servicio.png) era de un gris
# claro liso, limpia y sin desgaste: al lado de la pared sucia del pasillo parecía de plástico. Esta se dibuja aquí,
# píxel a píxel, con la misma forma (36 × 43: el marco, la hoja, las bisagras, la manilla y la rejilla de abajo, en los
# mismos sitios) pero como las paredes nuevas del vestuario y el despacho (tools/vestuario_azulejo.py,
# tools/despacho_ladrillo.py): acero gris apagado con grano, más sucio cuanto más abajo, la chapa de las patadas
# arañada, la mancha de las manos alrededor de la manilla, polvo en la rejilla, pintura saltada y algo de óxido.
# Siempre sale igual (la suerte va con semilla fija).
# Uso: py tools/puerta_servicio.py  (y luego Godot --headless --path . --import)
import random
from PIL import Image

SALIDA = "assets/sprites/puerta-servicio.png"
W, H = 36, 43
FILO = (29, 27, 44)            # el contorno de siempre (el de todos los dibujos)
FILO_2 = (30, 31, 50)
HOJA = (114, 120, 122)          # el acero pintado de la hoja: gris apagado, algo azulado
MARCO = (56, 58, 61)            # el marco de hierro, oscuro
OXIDO = [(98, 68, 48), (80, 54, 40), (116, 82, 56)]
MUGRE = (58, 50, 40)            # la suciedad: marrón grisáceo

r = random.Random(7)
im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
p = im.load()


def mezcla(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def grano(c, n):
    d = r.randint(-n, n)
    return tuple(max(0, min(255, v + d)) for v in c)


def pon(x, y, c):
    p[x, y] = tuple(c) + (255,)


# --- El contorno y el marco de hierro (2 píxeles a cada lado y arriba) ---
for y in range(H):
    for x in range(W):
        if y == 0 and 1 <= x <= 34 or y >= 1 and x in (0, 35):
            pon(x, y, FILO)
        elif y >= 1 and (x == 1 or x == 34 or y == 1):
            pon(x, y, FILO_2)
for y in range(2, H):
    for x in list(range(2, 4)) + list(range(32, 34)):
        c = grano(MARCO, 4)
        if y == 2 or x == 2:
            c = mezcla(c, (96, 100, 104), 0.35)     # el canto de arriba y de la izquierda coge algo de luz
        pon(x, y, c)
for y in (2, 3):
    for x in range(4, 32):
        c = grano(MARCO, 4)
        if y == 2:
            c = mezcla(c, (96, 100, 104), 0.35)
        pon(x, y, c)
# la pintura del marco, saltada aquí y allá (el hierro de debajo, más claro) y con óxido en los golpes de abajo
for _ in range(6):
    x, y = r.choice([2, 3, 32, 33]), r.randint(4, H - 2)
    pon(x, y, mezcla(MARCO, (120, 122, 122), 0.5))
for x, y in [(2, 40), (3, 41), (33, 39), (32, 41), (33, 42), (3, 26), (32, 14)]:
    pon(x, y, r.choice(OXIDO))

# --- La hoja ---
# El tono de cada píxel: el acero con grano, un poco más claro arriba, rayas verticales suaves (el churretón de la
# pintura vieja) y cada vez más mugre al bajar, a manchas
churre = [r.uniform(-1, 1) for _ in range(W)]
manchas = {}
for _ in range(14):   # manchas grandes de mugre, sobre todo en la mitad de abajo
    cx, cy = r.uniform(4, 31), r.triangular(10, 43, 40)
    rad = r.uniform(2.0, 5.0)
    for y in range(4, H):
        for x in range(4, 32):
            d = ((x - cx) ** 2 + ((y - cy) * 1.3) ** 2) ** 0.5
            if d < rad:
                manchas[(x, y)] = max(manchas.get((x, y), 0), (1 - d / rad) * r.uniform(0.15, 0.3))
for y in range(4, H):
    for x in range(4, 32):
        alto = (y - 4) / (H - 5)
        c = mezcla(HOJA, (140, 146, 148), max(0.0, 0.35 - alto) )          # algo más clara arriba
        c = tuple(v + round(churre[x] * 3) for v in c)
        c = grano(c, 3)
        sucio = max(0.0, alto - 0.55) * 0.9 + manchas.get((x, y), 0)        # la mugre sube desde el suelo
        sucio += r.uniform(0, 0.08)
        c = mezcla(c, MUGRE, min(0.55, sucio))
        pon(x, y, c)
# el canto de arriba de la hoja, con un poco de luz (antes, una raya casi blanca)
for x in range(4, 32):
    pon(x, 4, mezcla(p[x, 4][:3], (168, 174, 176), 0.4))
# la sombra que deja el marco a la derecha y arriba de la hoja
for y in range(5, H):
    pon(31, y, mezcla(p[31, y][:3], (40, 42, 46), 0.35))
    pon(4, y, mezcla(p[4, y][:3], (150, 156, 158), 0.15))

# --- La chapa de las patadas, abajo del todo: más oscura y llena de arañazos claros ---
for y in range(40, H):
    for x in range(5, 31):
        c = mezcla(grano((100, 104, 104), 6), MUGRE, 0.35 + (y - 40) * 0.08)
        pon(x, y, c)
for x in range(5, 31):
    pon(x, 40, mezcla(p[x, 40][:3], (150, 154, 152), 0.3))   # su canto de arriba
for _ in range(7):   # los arañazos: rayitas claras torcidas, de las botas
    x, y = r.randint(6, 27), r.randint(41, 42)
    for i in range(r.randint(2, 4)):
        if x + i < 31:
            pon(x + i, y, mezcla(p[x + i, y][:3], (160, 162, 158), 0.45))

# --- Las bisagras, a la izquierda ---
for y0 in (8, 33):
    for y in range(y0, y0 + 4):
        pon(4, y, (44, 46, 52))
        pon(5, y, mezcla((96, 100, 104), r.choice(OXIDO), 0.3 if y > y0 + 1 else 0.0))
    pon(5, y0, (130, 134, 136))

# --- La rejilla de ventilación (de y 31 a 39): marco hundido, lamas con polvo y las ranuras casi negras ---
for y in range(31, 40):
    for x in range(7, 29):
        borde = y in (31, 39) or x in (7, 28)
        if borde:
            c = mezcla(p[x, y][:3], (70, 72, 74), 0.45)
            if y == 39 or x == 28:
                c = mezcla(c, (150, 154, 156), 0.3)   # el canto de abajo y de la derecha, con luz
        elif y % 2 == 0:
            c = grano((34, 33, 34), 3)                # la ranura: oscura, con el polvo de dentro
            if r.random() < 0.25:
                c = mezcla(c, MUGRE, 0.5)
        else:
            c = grano(mezcla((112, 116, 116), MUGRE, 0.25 + r.uniform(0, 0.25)), 4)   # la lama, con polvo encima
        pon(x, y, c)
for x, y in [(7, 31), (28, 31), (7, 39), (28, 39)]:     # los cuatro tornillos, con su óxido
    pon(x, y, r.choice(OXIDO[:2]))
pon(8, 39, mezcla(p[8, 39][:3], OXIDO[0], 0.5))
pon(27, 40, mezcla(p[27, 40][:3], OXIDO[1], 0.6))

# --- La mancha de las manos alrededor de la manilla: más oscura y grasienta ---
for y in range(15, 31):
    for x in range(20, 32):
        d = ((x - 26.5) ** 2 + ((y - 22) * 0.7) ** 2) ** 0.5
        if d < 6.5:
            pon(x, y, mezcla(p[x, y][:3], (62, 60, 56), (1 - d / 6.5) * 0.4 * r.uniform(0.6, 1.0)))

# --- La manilla: el escudo (de y 18 a 27) y la palanca hacia abajo, de acero gastado ---
for y in range(18, 28):
    for x in range(26, 29):
        c = (92, 96, 98)
        if x == 26:
            c = (134, 138, 140)          # el canto de la izquierda, con luz
        elif x == 28:
            c = (60, 62, 66)
        pon(x, y, grano(c, 3))
for y, x0 in [(18, 25), (19, 25), (20, 25)]:   # la palanca, que sale hacia la izquierda
    for x in range(x0 - 1, 26):
        pon(x, y, (150, 154, 154) if y == 18 else ((110, 114, 116) if y == 19 else (52, 54, 58)))
pon(23, 19, (40, 40, 46))
pon(27, 25, (36, 36, 40))   # el ojo de la cerradura
pon(27, 26, (50, 50, 54))

# --- La pintura saltada de la hoja: desconchones pequeños con el metal claro o el óxido ---
for _ in range(9):
    x, y = r.randint(6, 30), r.randint(6, 38)
    if 7 <= x <= 28 and 31 <= y <= 39 or 22 <= x <= 29 and 17 <= y <= 28:
        continue
    pon(x, y, mezcla(p[x, y][:3], (60, 58, 56), 0.5))
    if r.random() < 0.6:
        pon(x + 1, y, mezcla(p[x + 1, y][:3], (168, 170, 168), 0.4))
# el óxido de las esquinas de abajo, que es donde se moja al fregar
for x, y in [(4, 41), (5, 42), (4, 42), (6, 42), (30, 42), (31, 41), (31, 42), (29, 42)]:
    pon(x, y, r.choice(OXIDO))

# la fila de abajo, como la de antes: el contorno solo en las esquinas, el resto es la hoja que toca el suelo
for x in (0, 35):
    p[x, H - 1] = (0, 0, 0, 0)

im.save(SALIDA)
print("puerta guardada en", SALIDA)
