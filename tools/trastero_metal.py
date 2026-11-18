# La puerta de los trasteros de las viviendas (puerta-trastero.png y puerta-trastero-abierta.png, azules lisas con su pomo) en
# metalizado, gris acero en vez de azul (18 nov, el dueño): para la puerta del almacén de la tienda de ropa. Cada píxel azul pasa a un
# gris acero con la misma luz y sombra (algo frío); el pomo y el contorno se quedan.
# assets/sprites/puerta-trastero-metal.png y puerta-trastero-metal-abierta.png
#   py tools/trastero_metal.py   (y luego Godot --headless --path . --import)
import colorsys
from PIL import Image

for nombre in ("puerta-trastero", "puerta-trastero-abierta"):
    im = Image.open(f"assets/sprites/{nombre}.png").convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.5 < h < 0.7 and s > 0.3:   # lo azul
                luz = min(1.0, v * 0.78 + 0.02)
                px[x, y] = (int(luz * 0.90 * 255), int(luz * 0.95 * 255), int(luz * 1.03 * 255 if luz < 0.97 else 255), a)
    im.save(f"assets/sprites/{nombre.replace('puerta-trastero', 'puerta-trastero-metal')}.png")
    print(nombre, im.size)
