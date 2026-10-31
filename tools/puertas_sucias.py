"""Las puertas de madera, sucias (L23 de PENDIENTES): con mugre, arañazos de uñas, huellas de manos y sangre que chorrea.

De cada dibujo limpio (assets/sprites/puerta-piso.png y las puerta-bano*.png, de PixelLab y de tools/puerta_lado_cerrada.py) sale su
copia <nombre>-sucia.png. Los limpios no se tocan: la sala de mantenimiento es zona segura y los sigue usando (mapa/puerta_bano.gd).
Las de piso y las de dentro vistas de frente son tres dibujos, uno al lado de otro, para que no sean todas iguales (mapa/puerta.gd y
puerta_bano.gd). Lo que lleva cada una está a mano en RECETAS, en píxeles del dibujo: aquí la colocación importa más que el azar. Usa
siempre las mismas semillas.

  py tools/puertas_sucias.py     (y luego, para que Godot las importe: Godot --headless --path . --import)
"""
import math
import os
import random
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cartel_roto import ruido

SPRITES = "assets/sprites"
SANGRE = (136, 16, 20)
HUMEDA = (172, 28, 32)     # la que acaba de caer, con brillo
SECA = (84, 14, 18)        # la que ya se ha secado, más oscura
RAYA = (146, 102, 72)      # la madera clara que deja a la vista un arañazo
GASTADA = (114, 76, 54)    # la punta del arañazo, que apenas araña
SURCO = (38, 24, 24)       # su sombra, al lado
# Una mano abierta, de 6 × 7 píxeles
MANO = ["..X.X.", ".XX.XX", ".XXXXX", "X.XXXX", "XXXXXX", ".XXXX.", "..XX.."]
# Lo que lleva cada dibujo. "mano": x, y (la esquina de arriba a la izquierda) y lo que se arrastra hacia abajo; "uñas": x, y, largo y
# rayas; "chorro": x, y y largo; "salpicón": centro, radio y gotas
RECETAS = {
    "puerta-piso": [
        [("mano", 10, 12, 13), ("uñas", 16, 29, 11, 3), ("salpicón", 5, 34, 5, 12), ("chorro", 22, 8, 7)],
        [("uñas", 10, 12, 13, 3), ("mano", 18, 19, 7), ("chorro", 20, 8, 11), ("salpicón", 24, 34, 5, 12)],
        [("salpicón", 21, 13, 7, 20), ("chorro", 19, 16, 19), ("chorro", 23, 15, 13), ("chorro", 16, 17, 9), ("uñas", 10, 29, 10, 3), ("mano", 4, 22, 8)],
    ],
    "puerta-bano": [
        [("mano", 7, 12, 12), ("uñas", 12, 27, 11, 3), ("salpicón", 19, 10, 5, 14), ("chorro", 18, 12, 10), ("salpicón", 6, 36, 4, 9)],
        [("uñas", 7, 9, 13, 3), ("salpicón", 14, 30, 6, 16), ("chorro", 13, 32, 8), ("chorro", 16, 31, 6), ("mano", 16, 20, 4)],
        [("mano", 13, 27, 9), ("chorro", 7, 8, 24), ("chorro", 10, 8, 15), ("salpicón", 8, 8, 4, 10), ("uñas", 15, 8, 11, 3)],
    ],
    "puerta-bano-abierta": [[("uñas", 4, 24, 10, 2), ("chorro", 6, 12, 15), ("chorro", 8, 20, 9), ("salpicón", 6, 16, 4, 9)]],
    "puerta-bano-abierta-lado": [[("uñas", 5, 26, 10, 2), ("chorro", 6, 20, 15), ("chorro", 8, 30, 8), ("salpicón", 7, 24, 4, 9)]],
    "puerta-bano-lado-cerrada": [[("chorro", 7, 4, 5), ("chorro", 6, 15, 3), ("salpicón", 7, 26, 3, 5)]],
}


def linea(c):
    return c[0] + c[1] + c[2] < 110 and c[2] >= c[0]


def laton(c):
    return c[0] > 150 and c[1] > 120 and c[2] < 110


def madera(c):
    return c[3] == 255 and not linea(c) and not laton(c)


def dentro(im, x, y):
    return 0 <= x < im.width and 0 <= y < im.height


# Sangre encima de lo que haya, menos en el hueco de alrededor y en el pomo
def pintar(im, x, y, color):
    if dentro(im, x, y) and im.getpixel((x, y))[3] == 255 and not laton(im.getpixel((x, y))):
        im.putpixel((x, y), color + (255,))


# La mugre: manchas de tres tonos, más abajo más sucia
def mugre(im, dado):
    grande = ruido(dado, im.width, im.height, 6)
    fino = ruido(dado, im.width, im.height, 3)
    for y in range(im.height):
        for x in range(im.width):
            c = im.getpixel((x, y))
            if madera(c):
                n = grande(x, y) * 0.6 + fino(x, y) * 0.4 + 0.14 * y / im.height
                k = 1.0 if n < 0.52 else (0.82 if n < 0.62 else 0.66)
                im.putpixel((x, y), (int(c[0] * k), int(c[1] * k), int(c[2] * k), 255))


# Uñas: rayas en diagonal, las de en medio más largas y con algún corte, que se van apagando, con la sombra del surco al lado
def unas(im, x, y, largo, rayas):
    marcas = [(x + r * 3 + i // 4, y + i + r % 2, i) for r in range(rayas) for i in range(largo - abs(r * 2 - rayas + 1))
        if (i + r * 3) % 8 != 7]
    for rx, ry, _ in marcas:
        if dentro(im, rx + 1, ry) and madera(im.getpixel((rx + 1, ry))):
            im.putpixel((rx + 1, ry), SURCO + (255,))
    for rx, ry, i in marcas:
        if dentro(im, rx, ry) and madera(im.getpixel((rx, ry))):
            im.putpixel((rx, ry), (RAYA if i < largo * 0.55 else GASTADA) + (255,))


# La huella de una mano y, si se ha arrastrado, cuatro dedos de sangre hacia abajo, cada vez más secos y con cortes
def mano(im, dado, x, y, arrastre):
    for f, fila in enumerate(MANO):
        for c, letra in enumerate(fila):
            if letra == "X":
                pintar(im, x + c, y + f, SANGRE if (c + f) % 3 else SECA)
    for c in range(1, 5):
        fin = arrastre - dado.randrange(0, 5)
        for i in range(fin):
            if dado.random() < 0.9 - 0.6 * i / max(arrastre, 1):
                pintar(im, x + c, y + len(MANO) - 1 + i, SANGRE if i < arrastre * 0.45 else SECA)


def chorro(im, x, y, largo):
    for i in range(largo):
        pintar(im, x, y + i, HUMEDA if i % 5 == 0 else SANGRE)
    pintar(im, x, y + largo, SECA)
    pintar(im, x + 1, y + largo, SECA)
    pintar(im, x, y + largo + 1, SECA)


def salpicon(im, dado, cx, cy, radio, gotas):
    for _ in range(gotas):
        a = dado.uniform(0, math.tau)
        r = radio * dado.random() ** 0.7
        x, y = int(cx + math.cos(a) * r), int(cy + math.sin(a) * r)
        pintar(im, x, y, dado.choice((SANGRE, SANGRE, SECA, HUMEDA)))
        if r < radio * 0.5:
            pintar(im, x + dado.choice((-1, 1)), y, SANGRE)


def ensuciar(im, receta, semilla):
    dado = random.Random(semilla)
    mugre(im, dado)
    for cosa in receta:
        if cosa[0] == "uñas":
            unas(im, *cosa[1:])
        elif cosa[0] == "mano":
            mano(im, dado, *cosa[1:])
        elif cosa[0] == "chorro":
            chorro(im, *cosa[1:])
        else:
            salpicon(im, dado, *cosa[1:])


if __name__ == "__main__":
    for nombre, recetas in RECETAS.items():
        limpia = Image.open(os.path.join(SPRITES, nombre + ".png")).convert("RGBA")
        hoja = Image.new("RGBA", (limpia.width * len(recetas), limpia.height), (0, 0, 0, 0))
        for k, receta in enumerate(recetas):
            sucia = limpia.copy()
            ensuciar(sucia, receta, nombre + str(k))
            hoja.paste(sucia, (k * limpia.width, 0))
        hoja.save(os.path.join(SPRITES, nombre + "-sucia.png"))
        print(nombre, hoja.size)
