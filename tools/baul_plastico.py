# El baúl (de la sala de mantenimiento y de la sala de pruebas), desde el 7 nov como el de la foto del dueño: un arcón
# de plástico negro de los de jardín. Copia el dibujo de GPT que eligió (assets/sources/baul-plastico-gpt.webp) con sus
# mismos colores, pero pasado a mano píxel a píxel: reducida sin más, la imagen se emborronaba y se perdían las rayas.
# De arriba abajo: la tapa vista desde arriba (con las esquinas achaflanadas y sus tablillas), el canto de la tapa con
# luz, el frente de la tapa con el asa en medio, la sombra que hace la tapa, el cuerpo en tres tablas y el zócalo.
# A 2 unidades por píxel, como todos los muebles. Antes era el baúl de madera con flejes de PixelLab
# (tools/baul_mantenimiento.py).
#   py tools/baul_plastico.py   → assets/sprites/baul.png  (y luego Godot --headless --path . --import)
from PIL import Image

SPRITE = "assets/sprites/baul.png"
ANCHO, ALTO = 42, 23

BORDE = (6, 7, 10)
TAPA = (59, 60, 67)
RAYA_TAPA = (79, 80, 88)
CANTO = (140, 142, 148)
FRENTE = (39, 40, 47)
SOMBRA = (18, 19, 23)
CUERPO = (36, 37, 43)
LADO = (29, 30, 35)
RAYA = (89, 92, 100)
ZOCALO = (85, 85, 94)

im = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))


def fila(y, desde, hasta, color):
    for x in range(desde, hasta + 1):
        im.putpixel((x, y), color + (255,))


# la tapa vista desde arriba: más estrecha arriba (las esquinas, achaflanadas), con tablillas claras cada dos filas
for y in range(0, 8):
    chaflan = max(0, 4 - y // 2)
    fila(y, chaflan, ANCHO - 1 - chaflan, BORDE)
    if y > 0:
        fila(y, chaflan + 1, ANCHO - 2 - chaflan, RAYA_TAPA if y % 2 == 0 and y < 7 else TAPA)
# el canto de la tapa, con luz, y su frente (algo más oscuro)
fila(7, 1, ANCHO - 2, CANTO)
for y in (8, 9):
    fila(y, 0, ANCHO - 1, BORDE)
    fila(y, 1, ANCHO - 2, FRENTE)
fila(10, 0, ANCHO - 1, BORDE)   # (debajo de la tapa)
# el asa: un hueco con su borde y una raya de luz abajo
mitad = ANCHO // 2
for y in (8, 9, 10, 11):
    fila(y, mitad - 3, mitad + 2, BORDE)
fila(9, mitad - 2, mitad + 1, SOMBRA)
fila(10, mitad - 2, mitad + 1, RAYA)
# el cuerpo, un poco más estrecho que la tapa: tres tablas separadas por rayas claras, más oscuro en los lados
for y in range(11, ALTO):
    fila(y, 1, ANCHO - 2, BORDE)
    fila(y, 2, ANCHO - 3, CUERPO)
    for x in (2, ANCHO - 3):
        im.putpixel((x, y), LADO + (255,))
fila(11, 2, ANCHO - 3, SOMBRA)   # la sombra de la tapa
fila(11, mitad - 3, mitad + 2, BORDE)   # (el asa sobresale un poco)
fila(14, 3, ANCHO - 4, RAYA)
fila(17, 3, ANCHO - 4, RAYA)
# el zócalo: un poco más ancho, con su raya de luz
for y in (20, 21):
    fila(y, 1, ANCHO - 2, BORDE)
    fila(y, 2, ANCHO - 3, CUERPO)
fila(20, 2, ANCHO - 3, ZOCALO)
fila(ALTO - 1, 1, ANCHO - 2, BORDE)
im.save(SPRITE)
print(SPRITE, im.size)
