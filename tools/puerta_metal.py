# La puerta metálica de la sala de mantenimiento (la del despacho al taller, en un tabique de lado), del 7 nov. Primero
# salió de una imagen de GPT (assets/sources/puerta-metal-gpt.webp), de acero gris claro, pero su manilla negra sobre la
# chapa clara no se veía bien; ahora es como la foto que trajo el dueño (assets/sources/puerta-metal-foto.webp): una
# puerta de seguridad verde oscuro con la manilla plateada y el bombín debajo, dibujada a mano píxel a píxel.
# Para que gire igual que la de madera (puerta_bano.gd), copia la forma exacta de sus dibujos:
#   puerta-metal-lado-cerrada  (16x32, como puerta-bano-lado-cerrada): la tira de canto, verde, con la manilla plateada
#                              asomando a los dos lados
#   puerta-metal-abierta-lado  (14x67, como puerta-bano-abierta-lado): el mismo paralelogramo, con su cara verde, el canto
#                              de la bisagra más claro, la manilla y el bombín, y su sombra en el suelo
#   puerta-metal               (28x43, como puerta-bano): la misma de frente, para mientras gira
#   py tools/puerta_metal.py   (y luego Godot --headless --path . --import)
from PIL import Image

CARPETA = "assets/sprites/"
LINEA = (29, 27, 44)
OSCURO, VERDE, LUZ, CANTO, CANTO_LUZ = (27, 45, 40), (40, 66, 57), (55, 86, 75), (72, 106, 93), (98, 134, 119)
PLATA, PLATA_LUZ, PLATA_SOMBRA = (190, 192, 186), (232, 234, 228), (118, 120, 116)
HUECO = (14, 16, 18)   # el agujero de la llave


def pon(im, puntos):
    for x, y, c in puntos:
        im.putpixel((x, y), c + (255,))


def es_linea(c):
    return abs(c[0] - LINEA[0]) + abs(c[1] - LINEA[1]) + abs(c[2] - LINEA[2]) < 24


# 1 · De frente (28x43): la hoja verde con su contorno, un poco más clara arriba a la izquierda, un panel marcado, la
# manilla plateada (la base redonda y la palanca hacia la bisagra, a la izquierda) y el bombín debajo
frente = Image.new("RGBA", (28, 43), (0, 0, 0, 0))
for y in range(43):
    for x in range(28):
        if x in (0, 27) or y in (0, 42):
            c = LINEA
        elif x in (1, 26) or y in (1, 41):
            c = OSCURO
        elif x == 2 or y == 2:
            c = LUZ
        else:
            c = VERDE
        frente.putpixel((x, y), c + (255,))
for y in range(6, 37):   # el panel: una raya oscura y otra clara
    pon(frente, [(5, y, OSCURO), (22, y, LUZ)])
for x in range(5, 23):
    pon(frente, [(x, 6, OSCURO), (x, 36, LUZ)])
pon(frente, [(20, 20, PLATA_LUZ), (21, 20, PLATA), (20, 21, PLATA), (21, 21, PLATA_SOMBRA),
             (16, 20, PLATA_LUZ), (17, 20, PLATA_LUZ), (18, 20, PLATA_LUZ), (19, 20, PLATA_LUZ),
             (16, 21, PLATA_SOMBRA), (17, 21, PLATA_SOMBRA), (18, 21, PLATA_SOMBRA), (19, 21, PLATA_SOMBRA),
             (20, 24, PLATA), (21, 24, PLATA), (20, 25, HUECO), (21, 25, PLATA_SOMBRA), (20, 26, PLATA), (21, 26, PLATA)])
frente.save(CARPETA + "puerta-metal.png")

# 2 · Abierta de lado (14x67): la forma de la de madera. Las dos primeras columnas, el canto de la bisagra; lo de abajo
# del todo, su sombra en el suelo (se queda); el contorno (se queda); lo demás, la cara verde, más oscura hacia abajo
madera = Image.open(CARPETA + "puerta-bano-abierta-lado.png").convert("RGBA")
abierta = Image.new("RGBA", madera.size, (0, 0, 0, 0))
w, h = madera.size
for x in range(w):
    filas = [y for y in range(h) if madera.getpixel((x, y))[3]]
    if not filas:
        continue
    arriba, abajo = filas[0], filas[-1]
    for y in filas:
        c = madera.getpixel((x, y))
        if c[3] < 255 or y > abajo - 3 and x > 1:
            abierta.putpixel((x, y), c)   # (la sombra del suelo)
        elif es_linea(c) and (y in (arriba, abajo) or x == w - 1 or not madera.getpixel((x, y - 1))[3]
                              or not madera.getpixel((x, y + 1))[3]):
            abierta.putpixel((x, y), LINEA + (255,))   # (solo el contorno de fuera: las rayas de la madera, no)
        elif x < 2:
            abierta.putpixel((x, y), (CANTO_LUZ if x == 0 else CANTO) + (255,))
        elif y == arriba or y == arriba + 1:
            abierta.putpixel((x, y), LUZ + (255,))   # (el borde de arriba, con luz)
        else:
            v = (y - arriba) / max(1, abajo - arriba)
            abierta.putpixel((x, y), (LUZ if x == 2 else VERDE if v < 0.75 else OSCURO) + (255,))
# la manilla, a media altura de su columna y cerca del canto libre (a la derecha): la base redonda, la palanca de 3
# hacia la bisagra, con su luz arriba y su sombra abajo; y el bombín, dos más abajo
filas = [y for y in range(h) if abierta.getpixel((11, y))[3]]
m = (filas[0] + filas[-1]) // 2 - 2
pon(abierta, [(10, m, PLATA_LUZ), (11, m, PLATA), (10, m + 1, PLATA), (11, m + 1, PLATA_SOMBRA),
              (7, m, PLATA_LUZ), (8, m, PLATA_LUZ), (9, m, PLATA_LUZ),
              (7, m + 1, PLATA_SOMBRA), (8, m + 1, PLATA_SOMBRA), (9, m + 1, PLATA_SOMBRA),
              (7, m + 2, OSCURO), (8, m + 2, OSCURO), (9, m + 2, OSCURO),
              (10, m + 4, PLATA), (11, m + 4, PLATA), (10, m + 5, HUECO), (11, m + 5, PLATA_SOMBRA), (10, m + 6, PLATA),
              (11, m + 6, PLATA)])
abierta.save(CARPETA + "puerta-metal-abierta-lado.png")

# 3 · Cerrada de lado (16x32): la forma de la de madera; la tira, verde (oscura a un lado y clara al otro) y lo que
# sobresale a los lados, la manilla plateada
madera = Image.open(CARPETA + "puerta-bano-lado-cerrada.png").convert("RGBA")
cerrada = Image.new("RGBA", madera.size, (0, 0, 0, 0))
for y in range(madera.height):
    for x in range(madera.width):
        c = madera.getpixel((x, y))
        if not c[3]:
            continue
        if es_linea(c):
            color = LINEA
        elif x < 5 or x > 10:
            color = PLATA_LUZ if y == 21 else PLATA_SOMBRA if y == 24 else PLATA
        elif y in (0, 1, 30, 31):
            color = OSCURO   # (los cantos de arriba y abajo)
        else:
            color = [OSCURO, VERDE, CANTO_LUZ, CANTO, VERDE, OSCURO][x - 5]
        cerrada.putpixel((x, y), color + (c[3],))
cerrada.save(CARPETA + "puerta-metal-lado-cerrada.png")
print("puerta-metal, puerta-metal-abierta-lado y puerta-metal-lado-cerrada")
