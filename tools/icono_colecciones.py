# El icono de Colecciones (bestiario.gd y el programa del ordenador): un álbum de pegatinas cerrado, de tapas verdes
# oscuras, con tres pegatinas en la tapa (una amarilla redonda, una roja cuadrada y una cara verde de zombi) y una
# etiqueta beis. Se dibuja a 16x16 y se agranda al doble (32x32) como los demás iconos.
#   py tools/icono_colecciones.py   → assets/ui/iconos/colecciones.png
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
C = {
    "#": (29, 27, 44, 255),     # contorno
    "s": (34, 72, 48, 255),     # lomo del álbum
    "G": (52, 110, 66, 255),    # tapa verde oscura
    "y": (240, 204, 64, 255),   # pegatina amarilla redonda
    "r": (200, 56, 48, 255),    # pegatina roja cuadrada
    "z": (130, 196, 96, 255),   # pegatina: la cara del zombi
    "e": (29, 27, 44, 255),     # ojos y boca del zombi
    "b": (233, 223, 196, 255),  # etiqueta beis
    "l": (140, 130, 110, 255),  # renglón de la etiqueta
}
DIBUJO = [
    "................",
    ".##############.",
    ".#ssGGGGGGGGGG#.",
    ".#ssGzzzGGGyyG#.",
    ".#sszzzzzGyyyy#.",
    ".#sszezezGyyyy#.",
    ".#sszeeezGGyyG#.",
    ".#ssGzzzGGGGGG#.",
    ".#ssGGGGGGGrrr#.",
    ".#ssGGGGGGGrrr#.",
    ".#ssbbbbbbGrrr#.",
    ".#ssbllllbGGGG#.",
    ".#ssbbbbbbGGGG#.",
    ".#ssGGGGGGGGGG#.",
    ".##############.",
    "................",
]
im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
for y, fila in enumerate(DIBUJO):
    for x, ch in enumerate(fila[:16]):
        if ch in C:
            im.putpixel((x, y), C[ch])
im.resize((32, 32), Image.NEAREST).save(RAIZ / "assets/ui/iconos/colecciones.png")
print("assets/ui/iconos/colecciones.png")
