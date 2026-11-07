# La puerta metálica de la sala de mantenimiento (la del despacho al taller, en un tabique de lado), del 7 nov (el dueño
# probó también una verde dibujada a mano como su foto, assets/sources/puerta-metal-foto.webp, y se quedó con esta): sale de
# la imagen de GPT que trajo el dueño (assets/sources/puerta-metal-gpt.webp: la cerrada vista desde arriba a la
# izquierda y la abierta, de pie y torcida, a la derecha). Para que gire igual que la de madera (puerta_bano.gd), copia la
# forma exacta de sus dibujos y la rellena de acero:
#   puerta-metal-lado-cerrada  (16x32, como puerta-bano-lado-cerrada): la tira de canto de acero, con la manilla negra a
#                              los dos lados (la de GPT eran dos ganchos hacia arriba: aquí, el bulto del pomo de madera)
#   puerta-metal-abierta-lado  (14x67, como puerta-bano-abierta-lado): el mismo paralelogramo, con la cara de la puerta de
#                              GPT (sus remaches, la chapa de abajo y la manilla), enderezada y vuelta a torcer a su forma
#   puerta-metal               (28x43, como puerta-bano): la misma cara, de frente, para mientras gira
#   py tools/puerta_metal.py   (y luego Godot --headless --path . --import)
from PIL import Image

ORIGEN = "assets/sources/puerta-metal-gpt.webp"
CARPETA = "assets/sprites/"
LINEA = (29, 27, 44)
OSCURO, MEDIO, CLARO, BRILLO = (79, 84, 91), (128, 133, 140), (168, 172, 178), (196, 200, 205)
MANILLA, MANILLA_LUZ = (34, 34, 38), (78, 80, 86)

gpt = Image.open(ORIGEN).convert("RGBA")
# la cara de la abierta, enderezada: de la x 920 a la 1145, cada columna desde su borde de arriba (que baja 0,6 por
# columna) hasta el de abajo
X0, X1, ALTO_CARA = 920, 1145, 778
cara = Image.new("RGBA", (X1 - X0, ALTO_CARA))
for u in range(X1 - X0):
    arriba = 44 + u * 0.6
    for v in range(ALTO_CARA):
        cara.putpixel((u, v), gpt.getpixel((X0 + u, int(arriba + v))))


def muestra(u, v):
    """El color de la cara en (u, v), de 0 a 1, del cuadrito que le toca de la imagen de GPT: si en él manda lo negro de
    la manilla (más de un tercio, y solo donde está ella), negro de manilla limpio; si no, la media de lo que no es negro.
    Así la manilla no se mezcla con la chapa en un borrón gris, y las rayas negras de los bordes de GPT no se cuelan"""
    x, y = int(u * (cara.width - 1)), int(v * (cara.height - 1))
    caja = cara.crop((max(0, x - 8), max(0, y - 8), x + 9, y + 9)).convert("RGB")
    claros, negros = [], 0
    for c in caja.get_flattened_data():
        if sum(c) < 200:
            negros += 1
        else:
            claros.append(c)
    manilla = 0.38 < u < 0.95 and 0.42 < v < 0.62   # (dónde está la manilla en la cara: fuera, lo negro son bordes)
    if manilla and negros * 3 > caja.width * caja.height or not claros:
        return MANILLA
    return tuple(sum(c[i] for c in claros) // len(claros) for i in range(3))


# 1 · De frente (28x43): la cara reducida, con su contorno
frente = Image.new("RGBA", (28, 43), (0, 0, 0, 0))
for y in range(43):
    for x in range(28):
        if x in (0, 27) or y in (0, 42):
            frente.putpixel((x, y), LINEA + (255,))
        else:
            frente.putpixel((x, y), muestra((x - 1) / 25, (y - 1) / 40) + (255,))
frente.save(CARPETA + "puerta-metal.png")

# 2 · Abierta de lado (14x67): la forma de la de madera; las dos primeras columnas, el canto de la bisagra (claro), lo de
# abajo del todo, su sombra en el suelo (se queda), el contorno (se queda) y lo demás, la cara
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
        elif abs(c[0] - LINEA[0]) + abs(c[1] - LINEA[1]) + abs(c[2] - LINEA[2]) < 24:
            abierta.putpixel((x, y), LINEA + (255,))
        elif x < 2:
            abierta.putpixel((x, y), (BRILLO if x == 0 else CLARO) + (255,))
        else:
            v = (y - arriba) / max(1, abajo - 3 - arriba)
            abierta.putpixel((x, y), muestra((x - 2) / (w - 3), min(1.0, v)) + (255,))
abierta.save(CARPETA + "puerta-metal-abierta-lado.png")

# 3 · Cerrada de lado (16x32): la forma de la de madera; la tira, de acero (oscuro a un lado, claro al otro, con brillo
# en medio) y el bulto del pomo, la manilla negra
madera = Image.open(CARPETA + "puerta-bano-lado-cerrada.png").convert("RGBA")
cerrada = Image.new("RGBA", madera.size, (0, 0, 0, 0))
for y in range(madera.height):
    for x in range(madera.width):
        c = madera.getpixel((x, y))
        if not c[3]:
            continue
        if abs(c[0] - LINEA[0]) + abs(c[1] - LINEA[1]) + abs(c[2] - LINEA[2]) < 24:
            color = LINEA
        elif x < 5 or x > 10:
            color = MANILLA_LUZ if y == 21 or y == 22 else MANILLA   # (la manilla, con su luz arriba)
        elif y in (0, 1, 30, 31):
            color = OSCURO   # (los cantos de arriba y abajo)
        else:
            color = [OSCURO, MEDIO, BRILLO, CLARO, MEDIO, OSCURO][x - 5]
        cerrada.putpixel((x, y), color + (c[3],))
cerrada.save(CARPETA + "puerta-metal-lado-cerrada.png")
print("puerta-metal, puerta-metal-abierta-lado y puerta-metal-lado-cerrada")
