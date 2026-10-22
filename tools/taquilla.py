# La taquilla de Johnny, la de la sala de mantenimiento donde se elige el traje (parte 11 de
# docs/CENTRO_COMERCIAL.md): dos puertas de chapa con sus rejillas, tiradores y etiquetas, dibujada con rectángulos
# de píxeles como el baúl y el banco de tools/dibujos_7b.py. Sale en assets/sprites/taquilla.png (28×40 píxeles;
# en el juego va al doble, pegada a la pared de arriba a la derecha del baúl: mapa.gd, TAQUILLA_X).
#   py tools/taquilla.py   (y luego importar en Godot)
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
SPRITES = RAIZ / "assets" / "sprites"


def hexa(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# Un lienzo donde se pintan rectángulos de píxeles (el Lienzo de dibujos_7b.py)
class Lienzo:
    def __init__(self, ancho, alto):
        self.img = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))

    def px(self, x, y, w, h, color):
        c = hexa(color)
        for i in range(x, x + w):
            for j in range(y, y + h):
                if 0 <= i < self.img.width and 0 <= j < self.img.height:
                    self.img.putpixel((i, j), c)


def taquilla():
    g = Lienzo(28, 40)
    borde, chapa, clara, oscura, muy_oscura = "#1d1b2c", "#5a6678", "#7d8ba0", "#3e4756", "#2a303c"
    asa, etiqueta, pegatina = "#c9d1dc", "#e8e2c8", "#b8433a"
    # el cuerpo con su borde; la tapa de arriba más clara y la base más oscura
    g.px(0, 0, 28, 40, borde)
    g.px(1, 1, 26, 38, chapa)
    g.px(1, 1, 26, 2, clara)
    g.px(1, 37, 26, 2, muy_oscura)
    # dos puertas: el marco oscuro, la hoja con su luz arriba y a la izquierda y su sombra a la derecha
    for x in (2, 15):
        g.px(x, 4, 11, 32, oscura)
        g.px(x + 1, 5, 9, 30, chapa)
        g.px(x + 1, 5, 1, 30, clara)
        g.px(x + 1, 5, 9, 1, clara)
        g.px(x + 9, 6, 1, 29, oscura)
        # las rejillas de ventilación, arriba
        for y in (8, 10, 12):
            g.px(x + 3, y, 5, 1, muy_oscura)
        # el tirador
        g.px(x + 7, 19, 2, 4, borde)
        g.px(x + 7, 19, 1, 3, asa)
        # la etiqueta con el nombre
        g.px(x + 3, 27, 5, 3, etiqueta)
        g.px(x + 4, 28, 3, 1, oscura)
    # la junta entre las dos puertas
    g.px(13, 4, 2, 32, borde)
    # una pegatina roja en la puerta de la izquierda (la de Johnny)
    g.px(5, 31, 3, 3, pegatina)
    g.img.save(SPRITES / "taquilla.png")


if __name__ == "__main__":
    taquilla()
    print("Hecho: assets/sprites/taquilla.png")
