# La estantería del taller de la sala de mantenimiento (el mueble "canshelf" del catálogo, entre el banco y el baúl),
# desde el 7 nov como la de la foto del dueño pero toda de metal: una estantería de almacén de acero galvanizado, de un
# tramo, con cuatro baldas y cajas de cartón y cubos de plástico gris. Copia el dibujo de GPT que trajo
# (assets/sources/estanteria-metal-gpt.webp) con sus colores, redibujado a mano píxel a píxel (reducida sin más se
# emborrona: ver tools/banco_metal.py). De arriba abajo: los tapones de los postes, la balda de arriba vista desde
# arriba (con sus rayas de chapa), y cuatro huecos con sus cajas, cada uno con su larguero delante (con el brillo del
# metal); a los lados, los dos postes con su fila de agujeros. 40 × 68 (antes, de PixelLab, 40 × 59), a 2 unidades por
# píxel; ocupa 80 × 36 en el suelo (catalogo.gd).
#   py tools/estanteria_metal.py   → assets/sprites/mueble-canshelf.png y su .json  (y luego Godot --headless --path . --import)
# (No pasa por tools/importar.py: si se vuelve a importar mantenimiento/estanteria-botes.png, se pisaría esta.)
import json
from PIL import Image

SPRITE = "assets/sprites/mueble-canshelf.png"
ANCHO, ALTO = 40, 68

LINEA = (20, 19, 26)
POSTE_LUZ = (225, 227, 233)
POSTE = (178, 182, 194)
POSTE_OSC = (130, 136, 152)
AGUJERO = (20, 19, 26)
TAPA = (189, 197, 206)
BALDA_ARRIBA = (133, 141, 159)
BALDA_RAYA = (152, 160, 176)
BALDA_LUZ = (238, 240, 246)
BALDA = (122, 133, 159)
HUECO = (24, 23, 30)
HUECO_LADO = (60, 63, 73)
CARTON = (195, 138, 82)
CARTON_TAPA = (236, 192, 132)
CARTON_LADO = (150, 100, 55)
CINTA = (132, 87, 45)
CUBO_TAPA = (211, 216, 225)
CUBO = (164, 171, 184)
CUBO_LADO = (130, 137, 152)
CUBO_ASA = (68, 75, 87)

im = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))


def p(x, y, color):
    im.putpixel((x, y), color + (255,))


def caja(x0, y0, x1, y1, color):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p(x, y, color)


def borde(x0, y0, x1, y1, color=LINEA):
    for x in range(x0, x1 + 1):
        p(x, y0, color)
        p(x, y1, color)
    for y in range(y0, y1 + 1):
        p(x0, y, color)
        p(x1, y, color)


# ── La balda de arriba, vista desde arriba: un trapecio de chapa con rayas en diagonal ──
for i, y in enumerate(range(3, 8)):
    x0, x1 = 6 - i, 33 + i
    caja(x0, y, x1, y, BALDA_ARRIBA)
    for x in range(x0, x1 + 1):
        if (x + y) % 7 == 0:
            p(x, y, BALDA_RAYA)
    p(x0 - 1, y, LINEA)
    p(x1 + 1, y, LINEA)
caja(6, 2, 33, 2, LINEA)

# los tapones de arriba de los postes
for x0 in (3, 33):
    caja(x0, 0, x0 + 3, 2, TAPA)
    caja(x0 + 1, 0, x0 + 2, 0, POSTE_LUZ)
    borde(x0, 0, x0 + 3, 2)

# ── Los postes, con su fila de agujeros ──
for x0 in (0, 35):
    caja(x0, 7, x0 + 4, 67, LINEA)
    caja(x0 + 1, 8, x0 + 1, 66, POSTE_LUZ)
    caja(x0 + 2, 8, x0 + 2, 66, POSTE)
    caja(x0 + 3, 8, x0 + 3, 66, POSTE_OSC)
    for y in range(10, 65, 4):
        p(x0 + 2, y, AGUJERO)


# ── Las baldas: cada una, su larguero delante (la línea clara del brillo, el gris y la sombra) ──
def larguero(y):
    caja(5, y, 34, y, BALDA_LUZ)
    caja(5, y + 1, 34, y + 2, BALDA)
    caja(5, y + 3, 34, y + 3, LINEA)


# los huecos entre baldas: el fondo oscuro, con el canto de dentro de los postes un poco más claro
HUECOS = [11, 24, 37, 50]   # la fila de arriba de cada hueco (10 de alto)
for y in HUECOS:
    caja(5, y, 34, y + 9, HUECO)
    caja(5, y, 5, y + 9, HUECO_LADO)
    caja(34, y, 34, y + 9, HUECO_LADO)
for y in (7, 21, 34, 47, 60):
    larguero(y)
caja(5, 7, 34, 7, BALDA_LUZ)   # (la de arriba: el canto de la balda vista desde arriba)


# una caja de cartón: la tapa vista desde arriba (más clara) con su cinta, el frente y el lado derecho en sombra
def carton(x0, x1, arriba, abajo):
    caja(x0, arriba, x1, abajo, CARTON)
    caja(x0 + 1, arriba + 1, x1 - 1, arriba + 2, CARTON_TAPA)
    caja(x1 - 1, arriba + 1, x1 - 1, abajo - 1, CARTON_LADO)
    c = (x0 + x1) // 2
    caja(c, arriba + 1, c, arriba + 2, CINTA)
    caja(c, arriba + 3, c, arriba + 4, CINTA)
    borde(x0, arriba, x1, abajo)


# un cubo de plástico gris: la tapa que sobresale, el cuerpo con el asa y el lado en sombra
def cubo(x0, x1, arriba, abajo):
    caja(x0 - 1, arriba, x1 + 1, arriba + 2, CUBO_TAPA)
    borde(x0 - 1, arriba, x1 + 1, arriba + 2)
    caja(x0, arriba + 3, x1, abajo, CUBO)
    caja(x1 - 1, arriba + 3, x1 - 1, abajo - 1, CUBO_LADO)
    c = (x0 + x1) // 2
    caja(c - 2, arriba + 4, c + 2, arriba + 4, CUBO_ASA)
    borde(x0, arriba + 2, x1, abajo)


# (cada caja apoya en su balda: su fila de abajo, la de encima del larguero)
carton(6, 20, 12, 20)
cubo(23, 32, 12, 20)
carton(6, 21, 25, 33)
carton(24, 33, 27, 33)
cubo(8, 18, 37, 46)
carton(21, 33, 38, 46)
carton(6, 21, 51, 59)
carton(24, 33, 53, 59)

im.save(SPRITE)
with open("assets/sprites/mueble-canshelf.json", "w", encoding="utf-8", newline="\n") as f:
    json.dump({"cell": [ANCHO, ALTO], "pivot": [ANCHO // 2, ALTO], "scale": 1,
               "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
    f.write("\n")
print(f"{SPRITE}: {ANCHO}x{ALTO}")
