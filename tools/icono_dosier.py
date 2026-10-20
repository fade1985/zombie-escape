# El icono del Dosier VD-7 (historia.gd) para el ordenador: una carpeta marrón con una hoja asomando y una
# franja roja de "confidencial". Se dibuja a 16x16 y se agranda al doble (32x32) como los demás iconos.
#   py tools/icono_dosier.py   → assets/ui/iconos/dosier.png
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
C = {
    "#": (29, 27, 44, 255),     # contorno
    "c": (196, 150, 82, 255),   # carpeta
    "o": (150, 105, 52, 255),   # carpeta en sombra
    "p": (233, 223, 196, 255),  # papel
    "l": (140, 130, 110, 255),  # renglones
    "r": (163, 49, 43, 255),    # franja roja
}
DIBUJO = [
    "................",
    "................",
    ".####...........",
    ".#oo#######.....",
    ".#oooooooo#.....",
    ".#o#########....",
    ".#o#ppppppp#....",
    ".#o#plllllp#####",
    ".#o#ppppppp#ccc#",
    ".#o##############",
    ".#occcccccccccc#",
    ".#ocrrrrrrrrrcc#",
    ".#occcccccccccc#",
    ".#oooooooooooo#.",
    ".##############.",
    "................",
]
im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
for y, fila in enumerate(DIBUJO):
    for x, ch in enumerate(fila[:16]):
        if ch in C:
            im.putpixel((x, y), C[ch])
im.resize((32, 32), Image.NEAREST).save(RAIZ / "assets/ui/iconos/dosier.png")
print("assets/ui/iconos/dosier.png")
