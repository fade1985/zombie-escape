# El icono de Torre Velaria (el tercer edificio) para su tarjeta de «Elige edificio»: un rascacielos de cristal
# azul oscuro con ventanas encendidas y una antena roja arriba. Se dibuja a 16x16 y se agranda al doble (32x32) como
# los demás iconos.
#   py tools/icono_torre.py   → assets/ui/iconos/torre.png
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
C = {
    "#": (29, 27, 44, 255),     # contorno
    "t": (58, 72, 110, 255),    # cristal
    "s": (40, 50, 80, 255),     # cristal en sombra
    "v": (255, 214, 120, 255),  # ventana encendida
    "a": (150, 150, 165, 255),  # antena
    "r": (230, 60, 60, 255),    # piloto rojo
}
DIBUJO = [
    ".......r........",
    ".......a........",
    ".......a........",
    ".....#####......",
    ".....#tts#......",
    "....##tts##.....",
    "....#tvtts#.....",
    "....#ttvts#.....",
    "....#vttss#.....",
    "....#ttvts#.....",
    "....#tttvs#.....",
    "....#vttss#.....",
    "....#ttvts#.....",
    "....#tttss#.....",
    "....#tv#ts#.....",
    "....#######.....",
]
im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
for y, fila in enumerate(DIBUJO):
    for x, ch in enumerate(fila[:16]):
        if ch in C:
            im.putpixel((x, y), C[ch])
im.resize((32, 32), Image.NEAREST).save(RAIZ / "assets/ui/iconos/torre.png")
print("assets/ui/iconos/torre.png")
