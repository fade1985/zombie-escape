# La puerta de entrada de la tienda de ropa vista desde arriba (19 nov, el dueño; GPT: assets/sources/ropa/puerta-entrada-arriba-gpt.webp,
# la puerta doble de cristal negro de la fachada, puerta-restaurante, vista desde el techo): la que se ve dentro de la tienda normal, en el
# muro de abajo. Sobre el hueco de siempre del centro comercial (puerta-abajo.png, el tercero: el marco y el suelo del paso), sin su hoja
# vieja, la hoja de GPT reducida MEZCLANDO colores (LANCZOS, alfa premultiplicado, como tools/muebles_gpt.py) al doble de detalle:
# 72 × 64 píxeles, que en el juego son 72 × 64 unidades (puerta.gd, ABAJO_ROPA)
#   py tools/puerta_abajo_ropa.py   (y luego Godot --headless --path . --import)
from collections import deque
from PIL import Image

ORIGEN = "assets/sources/ropa/puerta-entrada-arriba-gpt.webp"
SALIDA = "assets/sprites/puerta-abajo-ropa.png"
PASO = (70, 72, 88, 255)   # el suelo del paso, el de debajo de la hoja vieja
HOJA_ANCHO = 68            # en píxeles del dibujo nuevo (al doble de detalle)
GROSOR = 1.5              # 19 nov, el dueño: «un poco más gruesa» que la imagen de GPT (solo de alto)
HOJA_CENTRO_Y = 11         # la altura de su centro (la hoja vieja iba en las filas 3 a 8 del de 36 × 32)


def quitar_fondo(im):
    px = im.load()
    w, h = im.size
    hecho = bytearray(w * h)
    cola = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or hecho[y * w + x] or max(px[x, y][:3]) >= 8:
            continue
        hecho[y * w + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(h):
        for x in range(w):
            if hecho[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
    return im


# el hueco del centro comercial, sin la hoja vieja ni su pomo ni su sombra (filas 0 a 11, entre los dos lados del marco), y al doble
base = Image.open("assets/sprites/puerta-abajo.png").convert("RGBA").crop((72, 0, 108, 32))
for y in range(0, 12):
    base.putpixel((2, y), (115, 119, 138, 255))   # el canto del marco de la izquierda, seguido
    base.putpixel((33, y), (43, 44, 65, 255))     # y la sombra del de la derecha
    for x in range(3, 33):
        base.putpixel((x, y), PASO)
base = base.resize((72, 64), Image.NEAREST)

hoja = quitar_fondo(Image.open(ORIGEN).convert("RGBA"))
hoja = hoja.crop(hoja.getbbox())
alto = max(1, round(HOJA_ANCHO * hoja.height / hoja.width * GROSOR))
s = hoja.convert("RGBa").resize((HOJA_ANCHO, alto), Image.LANCZOS).convert("RGBA")
s.putalpha(s.split()[3].point(lambda v: 255 if v > 110 else 0))
arriba = HOJA_CENTRO_Y - alto // 2
# su sombra en el suelo del paso, justo debajo (como la de la hoja vieja)
for y in range(arriba + alto - 1, arriba + alto + 1):
    for x in range(4, 66):
        base.putpixel((x, y), (20, 16, 20, 255))
base.alpha_composite(s, ((72 - HOJA_ANCHO) // 2, arriba))
base.save(SALIDA)
print(f"{SALIDA}: hoja {HOJA_ANCHO}x{alto}")
