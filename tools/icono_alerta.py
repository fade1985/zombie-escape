# El icono de los niveles de alerta (alerta.gd) para "Elige edificio" y el cartel del final: un triángulo de
# aviso amarillo con su exclamación. Se dibuja a 16x16 y se agranda al doble (32x32) como los demás iconos.
#   py tools/icono_alerta.py   → assets/ui/iconos/alerta.png
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
C = {
    "#": (29, 27, 44, 255),     # contorno y exclamación
    "a": (247, 196, 64, 255),   # amarillo
    "o": (214, 140, 40, 255),   # amarillo en sombra
    "b": (255, 236, 150, 255),  # brillo
}
DIBUJO = [
    "................",
    ".......##.......",
    "......#bb#......",
    "......#ba#......",
    ".....#baaa#.....",
    ".....#a##a#.....",
    "....#aa##aa#....",
    "....#aa##ao#....",
    "...#aaa##aao#...",
    "...#aaa##aao#...",
    "..#aaaaaaaaao#..",
    "..#aaaa##aaao#..",
    ".#aaaaa##aaaao#.",
    ".#oooooooooooo#.",
    ".##############.",
    "................",
]

img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
for y, fila in enumerate(DIBUJO):
    for x, c in enumerate(fila[:16]):
        if c in C:
            img.putpixel((x, y), C[c])
img.resize((32, 32), Image.NEAREST).save(RAIZ / "assets/ui/iconos/alerta.png")
print("assets/ui/iconos/alerta.png")
