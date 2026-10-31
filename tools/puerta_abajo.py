"""La puerta de la pared de abajo (L27 de PENDIENTES; mapa/puerta.gd). Esa pared se ve por detrás, así que la puerta no se puede ver
de frente como las de arriba: se ve el hueco en el muro, con su marco, y la hoja desde arriba, un tablón con su pomo a cada lado,
igual que las puertas de lado de dentro de los pisos (tools/puerta_lado_cerrada.py).

Saca assets/sprites/puerta-abajo.png, tres modelos de 36 × 32 píxeles (72 × 64 unidades, lo que mide de grueso el muro), uno al lado
de otro y en este orden: la de madera sucia (L23), la de madera limpia (las zonas seguras) y la de cristal y aluminio del centro
comercial. Hecha a mano: a 6 píxeles de grueso PixelLab no dibuja.

  py tools/puerta_abajo.py     (y luego, para que Godot la importe: Godot --headless --path . --import)
"""
import os
import random
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from puertas_sucias import SECA, chorro, ensuciar, salpicon, unas

SPRITES = "assets/sprites"
ANCHO, ALTO = 36, 32
LINEA = (29, 27, 44)
Y_HOJA, GROSOR = 3, 6     # el tablón: desde la fila 3, con su contorno
X_POMO = 27
LATON = (214, 178, 84), (150, 112, 54)
MADERA = {"marco": ((118, 65, 53), (92, 51, 38), (53, 27, 27)), "tablon": ((117, 71, 45), (92, 51, 38), (68, 37, 35)),
    "veta": (53, 27, 27), "suelo": ((74, 52, 40), (50, 36, 30), (30, 23, 24)), "pomo": LATON}
MODELOS = [
    MADERA,
    MADERA,
    {"marco": ((136, 138, 155), (115, 119, 138), (43, 44, 65)), "tablon": ((178, 197, 211), (87, 98, 118), (44, 56, 72)),
        "veta": (115, 119, 138), "suelo": ((70, 72, 88), (46, 48, 62), (26, 26, 36)), "pomo": ((178, 197, 211), (115, 119, 138))},
]


def caja(im, x, y, ancho, alto, color):
    for j in range(y, y + alto):
        for i in range(x, x + ancho):
            if 0 <= i < im.width and 0 <= j < im.height:
                im.putpixel((i, j), color + (255,))


def pomo(im, y, tonos):
    caja(im, X_POMO - 1, y - 1, 4, 4, LINEA)
    caja(im, X_POMO, y, 2, 2, tonos[1])
    im.putpixel((X_POMO, y), tonos[0] + (255,))


def puerta(modelo, semilla):
    dado = random.Random(semilla)
    im = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
    claro, medio, oscuro = modelo["suelo"]
    # el suelo del hueco: claro junto a la hoja y cada vez más oscuro hacia dentro del piso
    for y in range(ALTO):
        for x in range(3, ANCHO - 3):
            tono = claro if y < Y_HOJA + GROSOR + 3 else (medio if y < 18 else oscuro)
            im.putpixel((x, y), tono + (255,))
    # las jambas del marco, a los dos lados, con su contorno
    luz, cara, sombra = modelo["marco"]
    for x0, tonos in ((0, (luz, cara)), (ANCHO - 3, (cara, sombra))):
        caja(im, x0, 0, 3, ALTO, sombra)
        caja(im, x0 + 1, 0, 1, ALTO, tonos[0])
        caja(im, x0 + 2 if x0 == 0 else x0, 0, 1, ALTO, tonos[1])
    caja(im, 0, 0, 1, ALTO, LINEA)
    caja(im, ANCHO - 1, 0, 1, ALTO, LINEA)
    caja(im, 3, Y_HOJA + GROSOR, ANCHO - 6, 1, (20, 16, 20))     # la sombra de la hoja en el suelo
    # la hoja: el tablón, de jamba a jamba
    caja(im, 2, Y_HOJA, ANCHO - 4, GROSOR, LINEA)
    luz, cara, sombra = modelo["tablon"]
    for y, tono in zip(range(Y_HOJA + 1, Y_HOJA + GROSOR - 1), (luz, cara, cara, sombra)):
        caja(im, 3, y, ANCHO - 6, 1, tono)
    for _ in range(9):                                           # las vetas
        im.putpixel((dado.randrange(4, ANCHO - 4), dado.randrange(Y_HOJA + 2, Y_HOJA + GROSOR - 1)), modelo["veta"] + (255,))
    pomo(im, Y_HOJA - 2, modelo["pomo"])
    pomo(im, Y_HOJA + GROSOR, modelo["pomo"])
    return im


def sucia(im):
    ensuciar(im, [], "puerta-abajo")
    dado = random.Random("sangre")
    chorro(im, 8, Y_HOJA + 1, 7)
    chorro(im, 11, Y_HOJA + 2, 11)
    chorro(im, 22, Y_HOJA + 1, 5)
    salpicon(im, dado, 12, Y_HOJA + 3, 6, 14)
    for x in range(7, 15):                                       # el charco que se ha quedado en el suelo, detrás de la hoja
        im.putpixel((x, Y_HOJA + GROSOR + 7 + (x % 2)), SECA + (255,))
    unas(im, 17, Y_HOJA + 1, 4, 3)


if __name__ == "__main__":
    hoja = Image.new("RGBA", (ANCHO * len(MODELOS), ALTO), (0, 0, 0, 0))
    for k, modelo in enumerate(MODELOS):
        im = puerta(modelo, k)
        if k == 0:
            sucia(im)
        hoja.paste(im, (k * ANCHO, 0))
    hoja.save(os.path.join(SPRITES, "puerta-abajo.png"))
    print(hoja.size)
