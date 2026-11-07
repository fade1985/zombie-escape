# El banco de trabajo de la sala de mantenimiento, desde el 7 nov como el de la foto del dueño: un banco de taller de
# acero gris antracita con el tablero perforado naranja detrás (las llaves, los destornilladores, los alicates y el
# hacha), la mesa con herramientas sueltas, los dos cajones y, abajo, el maletín negro y el naranja. Sale tal cual de la
# imagen de GPT que trajo (assets/sources/banco-trabajo-gpt.webp), pedida ya en pixel art de cuadrados grandes y
# colores planos: se quita el fondo (solo el negro puro que se llega desde el borde: los contornos y el hueco de abajo,
# casi negros, se quedan), se recorta y se reduce a 40 × 49 tomando en cada cuadrito el color que más hay (sin mezclar).
# El mismo ancho que el de antes (PixelLab, tools/banco_mantenimiento.py), un poco más alto: crece hacia la pared.
# A 2 unidades por píxel, como todos los muebles.
#   py tools/banco_metal.py   → assets/sprites/banco-trabajo.png  (y luego Godot --headless --path . --import)
from collections import Counter, deque
from PIL import Image

ORIGEN = "assets/sources/banco-trabajo-gpt.webp"
SPRITE = "assets/sprites/banco-trabajo.png"
ANCHO, ALTO = 40, 49

im = Image.open(ORIGEN).convert("RGB")
W, H = im.size
px = im.load()


def es_fondo(c):
    return max(c) < 6


# el fondo: lo negro puro que se llega desde el borde
fondo = bytearray(W * H)
cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
while cola:
    x, y = cola.popleft()
    if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or not es_fondo(px[x, y]):
        continue
    fondo[y * W + x] = 1
    cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

# el recorte: lo que no es fondo
xs = [x for x in range(W) if any(not fondo[y * W + x] for y in range(0, H, 2))]
ys = [y for y in range(H) if any(not fondo[y * W + x] for x in range(0, W, 2))]
x0, y0, x1, y1 = xs[0], ys[0], xs[-1] + 1, ys[-1] + 1
cw, ch = (x1 - x0) / ANCHO, (y1 - y0) / ALTO

sprite = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
for j in range(ALTO):
    for i in range(ANCHO):
        colores = Counter()
        fuera = 0
        for y in range(int(y0 + j * ch), int(y0 + (j + 1) * ch)):
            for x in range(int(x0 + i * cw), int(x0 + (i + 1) * cw)):
                if fondo[y * W + x]:
                    fuera += 1
                else:
                    c = px[x, y]
                    colores[(c[0] // 16 * 16 + 8, c[1] // 16 * 16 + 8, c[2] // 16 * 16 + 8)] += 1
        if fuera > sum(colores.values()):
            continue   # más fondo que banco: transparente
        sprite.putpixel((i, j), colores.most_common(1)[0][0] + (255,))

sprite.save(SPRITE)
print(f"{SPRITE}: {ANCHO}x{ALTO}")
