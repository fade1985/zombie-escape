# El icono del programa Noticias (historia.gd) para el ordenador: una tele vieja con antena, la pantalla
# encendida en azul y el puntito rojo de "en directo". Se dibuja a 16x16 y se agranda al doble (32x32).
#   py tools/icono_noticias.py   → assets/ui/iconos/noticias.png
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
C = {
    "#": (29, 27, 44, 255),     # contorno
    "m": (122, 84, 52, 255),    # mueble de madera
    "o": (86, 58, 36, 255),     # madera en sombra
    "a": (140, 140, 150, 255),  # antena
    "p": (74, 120, 190, 255),   # pantalla
    "b": (150, 190, 235, 255),  # brillo de la pantalla
    "r": (230, 60, 60, 255),    # en directo
    "k": (220, 200, 150, 255),  # botones
}
DIBUJO = [
    "....a.....a.....",
    ".....a...a......",
    "......a.a.......",
    ".......#........",
    ".##############.",
    ".#mmmmmmmmmmmm#.",
    ".#m########mmm#.",
    ".#m#bbpppr#mkm#.",
    ".#m#bppppp#mmm#.",
    ".#m#pppppp#mkm#.",
    ".#m#pppppp#mmm#.",
    ".#m########mkm#.",
    ".#mmmmmmmmmmmm#.",
    ".#oooooooooooo#.",
    ".##############.",
    "..##........##..",
]
im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
for y, fila in enumerate(DIBUJO):
    for x, ch in enumerate(fila[:16]):
        if ch in C:
            im.putpixel((x, y), C[ch])
im.resize((32, 32), Image.NEAREST).save(RAIZ / "assets/ui/iconos/noticias.png")
print("assets/ui/iconos/noticias.png")
