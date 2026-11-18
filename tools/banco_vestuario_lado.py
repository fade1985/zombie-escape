# El banco del vestuario de Johnny (mueble-lockerbench.png, de frente) visto «en vertical», para ponerlo pegado a una pared de
# los lados (la del aseo de la tienda de ropa, 18 nov, el dueño): mueble-lockerbench-lado.png, 14 × 44 píxeles. Arriba, la tapa de
# listones vista desde arriba (los colores de los listones del dibujo de frente, ahora a lo largo) y, abajo, el extremo de
# delante: el canto de la tapa y las dos patas de acero con su travesaño.
#   py tools/banco_vestuario_lado.py   (y luego Godot --headless --path . --import)
import json
from PIL import Image

src = Image.open("assets/sprites/mueble-lockerbench.png").convert("RGBA")
W, ALTO_TAPA, ALTO_EXTREMO = 14, 30, 14
im = Image.new("RGBA", (W, ALTO_TAPA + ALTO_EXTREMO), (0, 0, 0, 0))
px = im.load()
col = [src.getpixel((32, y)) for y in range(0, 13)]   # los listones, de arriba abajo, en el dibujo de frente
contorno = (21, 19, 23, 255)
for x in range(W):
    c = contorno if x in (0, W - 1) else col[min(12, x)]
    for y in range(ALTO_TAPA):
        px[x, y] = c
for x in range(W):
    px[x, 0] = contorno   # el borde de más allá
# el extremo de delante
canto = [src.getpixel((32, 10)), src.getpixel((32, 11)), src.getpixel((32, 12))]
for x in range(W):
    for k, c in enumerate(canto):
        px[x, ALTO_TAPA + k] = contorno if x in (0, W - 1) else c
acero, sombra, oscuro = (116, 119, 127, 255), (59, 60, 66, 255), (16, 14, 20, 255)
for y in range(ALTO_TAPA + 3, ALTO_TAPA + ALTO_EXTREMO):
    for x in (1, 2, 3, 10, 11, 12):
        px[x, y] = acero if x in (1, 10) else sombra if x in (2, 11) else oscuro
for x in range(4, 10):   # el travesaño
    for y in (ALTO_TAPA + 6, ALTO_TAPA + 7):
        px[x, y] = sombra
for x in range(1, 4):
    px[x, ALTO_TAPA + ALTO_EXTREMO - 1] = oscuro
    px[x + 9, ALTO_TAPA + ALTO_EXTREMO - 1] = oscuro
im.save("assets/sprites/mueble-lockerbench-lado.png")
with open("assets/sprites/mueble-lockerbench-lado.json", "w", encoding="utf-8", newline="\n") as f:
    json.dump({"cell": [im.width, im.height], "pivot": [im.width // 2, im.height], "scale": 1,
               "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
    f.write("\n")
print(im.size)
