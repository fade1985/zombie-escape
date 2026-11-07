# El banco de trabajo de la sala de mantenimiento, desde el 7 nov como el de la foto del dueño: un banco de taller de
# acero gris antracita con el tablero perforado naranja detrás. Copia el dibujo de GPT que trajo
# (assets/sources/banco-trabajo-gpt.webp) con sus colores, pero redibujado a mano píxel a píxel a 48 × 58: reducida sin
# más (lo que hacía antes esta herramienta), la imagen salía emborronada, porque GPT dibuja detalles más finos que un
# píxel del juego (como pasó con el baúl, tools/baul_plastico.py).
# De arriba abajo: el remate, el tablero perforado con las herramientas colgadas (dos llaves fijas, tres
# destornilladores, unos alicates y un hacha), la mesa con herramientas sueltas, los dos cajones con su etiqueta y su
# tirador, el hueco con el maletín negro y el naranja, y la balda. Cada herramienta lleva su contorno oscuro de 1 píxel
# (contornear), como en la de GPT. A 2 unidades por píxel, como todos los muebles.
#   py tools/banco_metal.py   → assets/sprites/banco-trabajo.png  (y luego Godot --headless --path . --import)
from PIL import Image

SPRITE = "assets/sprites/banco-trabajo.png"
ANCHO, ALTO = 48, 58

LINEA = (20, 19, 26)
REMATE = (56, 59, 70)
REMATE_LUZ = (110, 115, 128)
TABLERO = (240, 160, 80)
AGUJERO = (60, 40, 30)
PLATA = (214, 218, 226)
PLATA_OSC = (140, 146, 160)
NARANJA = (244, 120, 20)
NARANJA_OSC = (186, 82, 12)
NARANJA_LUZ = (255, 168, 72)
MANGO = (36, 36, 44)
MADERA = (214, 160, 98)
MESA = (72, 76, 88)
MESA_LUZ = (130, 136, 150)
CANTO = (56, 59, 70)
CAJON = (56, 59, 70)
CAJON_LUZ = (76, 80, 94)
ETIQUETA = (232, 232, 238)
TIRADOR = (100, 104, 118)
PATA = (64, 67, 80)
PATA_LUZ = (92, 96, 110)
HUECO = (30, 30, 38)
BALDA = (64, 67, 80)
BALDA_LUZ = (140, 145, 158)
MALETIN = (44, 46, 54)
MALETIN_LUZ = (70, 73, 84)
CIERRE = (72, 76, 88)

im = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
herramientas = set()   # los píxeles de las herramientas, para contornearlas al final


def p(x, y, color, herramienta=False):
    im.putpixel((x, y), color + (255,))
    if herramienta:
        herramientas.add((x, y))


def caja(x0, y0, x1, y1, color, herramienta=False):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p(x, y, color, herramienta)


def borde(x0, y0, x1, y1, color=LINEA):
    for x in range(x0, x1 + 1):
        p(x, y0, color)
        p(x, y1, color)
    for y in range(y0, y1 + 1):
        p(x0, y, color)
        p(x1, y, color)


# el contorno oscuro de las herramientas: lo de su alrededor que es tablero o mesa
def contornear():
    fondo = {TABLERO, AGUJERO, MESA}
    for (x, y) in herramientas:
        for (a, b) in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (a, b) not in herramientas and im.getpixel((a, b))[:3] in fondo:
                p(a, b, LINEA)


# ── El remate y el tablero perforado ──
caja(3, 0, 44, 4, REMATE)
caja(4, 1, 43, 1, REMATE_LUZ)
borde(3, 0, 44, 4)
caja(4, 5, 43, 23, LINEA)
caja(5, 5, 42, 23, TABLERO)
for y in range(7, 23, 4):
    for x in range(6, 42, 4):
        p(x, y, AGUJERO)


# una llave fija colgada: las bocas abiertas arriba y abajo y el mango en medio
def llave(c, t, b):
    for y in (t, t + 1, b - 1, b):
        p(c - 1, y, PLATA, True)
        p(c + 1, y, PLATA_OSC, True)
    caja(c - 1, t + 2, c + 1, t + 2, PLATA, True)
    caja(c - 1, b - 2, c + 1, b - 2, PLATA, True)
    caja(c, t + 3, c, b - 3, PLATA, True)


llave(7, 9, 20)
llave(12, 8, 21)


# un destornillador: el mango naranja con la virola negra y la punta de acero
def destornillador(x, t, b):
    caja(x, t, x, t + 3, NARANJA, True)
    caja(x + 1, t, x + 1, t + 3, NARANJA_OSC, True)
    p(x, t, NARANJA_LUZ, True)
    caja(x, t + 4, x + 1, t + 5, MANGO, True)
    caja(x, t + 6, x, b - 1, PLATA, True)
    p(x, b, PLATA_OSC, True)


destornillador(16, 8, 19)
destornillador(20, 8, 19)
destornillador(24, 8, 19)

# los alicates: la boca de acero arriba y los mangos naranjas abiertos abajo
caja(31, 9, 31, 11, PLATA, True)
caja(32, 9, 32, 11, PLATA_OSC, True)
caja(30, 12, 33, 12, PLATA_OSC, True)
for y in range(13, 16):
    p(30, y, NARANJA, True)
    p(33, y, NARANJA_OSC, True)
for y in range(16, 21):
    p(29, y, NARANJA, True)
    p(34, y, NARANJA_OSC, True)

# el hacha: la cabeza naranja y el mango de madera con la empuñadura negra
caja(37, 8, 40, 11, NARANJA, True)
caja(37, 8, 40, 8, NARANJA_LUZ, True)
caja(37, 11, 40, 11, NARANJA_OSC, True)
caja(39, 12, 39, 17, MADERA, True)
caja(39, 18, 39, 21, MANGO, True)

# ── La mesa, vista un poco desde arriba, con herramientas sueltas ──
caja(3, 24, 44, 25, MESA)
caja(1, 26, 46, 29, MESA)
p(2, 24, LINEA)
p(45, 24, LINEA)
caja(2, 25, 2, 25, LINEA)
caja(45, 25, 45, 25, LINEA)
p(1, 25, LINEA)
p(46, 25, LINEA)
caja(0, 26, 0, 31, LINEA)
caja(47, 26, 47, 31, LINEA)
caja(1, 30, 46, 30, MESA_LUZ)
caja(1, 31, 46, 31, CANTO)
caja(0, 32, 47, 32, LINEA)
# una llave grande y otra pequeña, tumbadas
caja(7, 27, 13, 27, PLATA, True)
for x in (6, 14):
    p(x, 26, PLATA, True)
    p(x, 28, PLATA, True)
caja(17, 28, 21, 28, PLATA, True)
p(16, 27, PLATA_OSC, True)
p(22, 27, PLATA_OSC, True)
# los alicates, con los mangos naranjas abiertos
caja(25, 27, 27, 27, PLATA, True)
p(28, 27, PLATA_OSC, True)
caja(29, 26, 32, 26, NARANJA, True)
caja(29, 28, 32, 28, NARANJA_OSC, True)
# un destornillador
caja(35, 27, 38, 27, PLATA, True)
p(39, 27, MANGO, True)
caja(40, 26, 43, 26, NARANJA, True)
caja(40, 27, 43, 27, NARANJA_OSC, True)
contornear()

# ── Las patas ──
for x0 in (1, 42):
    caja(x0, 33, x0 + 4, 57, PATA)
    borde(x0, 33, x0 + 4, 57)
    caja(x0 + 1, 33, x0 + 1, 56, PATA_LUZ)


# ── Los cajones, el hueco con los maletines y la balda ──
def cajon(x0, x1):
    caja(x0, 33, x1, 40, CAJON)
    caja(x0 + 1, 34, x1 - 1, 34, CAJON_LUZ)
    borde(x0, 33, x1, 40)
    c = (x0 + x1) // 2
    caja(c - 2, 35, c + 2, 35, ETIQUETA)
    caja(c - 4, 37, c + 4, 39, LINEA)
    caja(c - 3, 38, c + 3, 38, TIRADOR)


cajon(5, 23)
cajon(24, 42)
caja(5, 41, 42, 41, PATA_LUZ)
caja(5, 42, 42, 42, LINEA)
caja(6, 43, 41, 51, HUECO)

# el maletín negro, con el asa y los cierres naranjas
caja(12, 43, 17, 43, NARANJA)
caja(11, 44, 11, 44, NARANJA)
caja(18, 44, 18, 44, NARANJA)
caja(8, 45, 21, 51, MALETIN)
caja(9, 46, 20, 46, MALETIN_LUZ)
caja(9, 48, 20, 48, LINEA)
borde(8, 45, 21, 51)
caja(11, 47, 12, 49, NARANJA)
caja(17, 47, 18, 49, NARANJA)
# el maletín naranja, con el asa y los cierres oscuros
caja(29, 43, 35, 43, NARANJA_OSC)
caja(28, 44, 28, 44, NARANJA_OSC)
caja(36, 44, 36, 44, NARANJA_OSC)
caja(25, 45, 39, 51, NARANJA)
caja(26, 46, 38, 46, NARANJA_LUZ)
caja(26, 48, 38, 48, NARANJA_OSC)
caja(26, 50, 38, 50, NARANJA_OSC)
borde(25, 45, 39, 51)
caja(28, 47, 29, 49, CIERRE)
caja(35, 47, 36, 49, CIERRE)

caja(6, 52, 41, 52, BALDA_LUZ)
caja(6, 53, 41, 54, BALDA)
caja(5, 55, 42, 55, LINEA)
caja(5, 52, 5, 55, LINEA)
caja(42, 52, 42, 55, LINEA)

im.save(SPRITE)
print(f"{SPRITE}: {ANCHO}x{ALTO}")
