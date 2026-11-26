# La puerta de entrada del supermercado vista desde arriba (26 nov, el dueño: «la puerta de fuera también dentro»): la que se ve dentro
# de la tienda normal, en el muro de abajo. Como la de la ropa (puerta_abajo_ropa.py): sobre el hueco de siempre del centro comercial
# (puerta-abajo.png, el tercero), sin su hoja vieja, la puerta automática de la fachada (puerta-super.png, sin la caja del motor ni el
# carril) aplastada en una tira, al doble de detalle: 72 × 64 píxeles para 72 × 64 unidades (puerta.gd, ABAJO_SUPER)
#   py tools/puerta_abajo_super.py   (y luego Godot --headless --path . --import)
from PIL import Image

SALIDA = "assets/sprites/puerta-abajo-super.png"
PASO = (70, 72, 88, 255)   # el suelo del paso
ANCHO, ALTO = 68, 11

base = Image.open("assets/sprites/puerta-abajo.png").convert("RGBA").crop((72, 0, 108, 32))
for y in range(0, 12):
    base.putpixel((2, y), (115, 119, 138, 255))
    base.putpixel((33, y), (43, 44, 65, 255))
    for x in range(3, 33):
        base.putpixel((x, y), PASO)
base = base.resize((72, 64), Image.NEAREST)

# los cristales: los dos fijos y las dos hojas, de la caja del motor (fuera) al carril
puerta = Image.open("assets/sprites/puerta-super.png").convert("RGBA").crop((2, 4, 62, 38))
s = puerta.convert("RGBa").resize((ANCHO, ALTO), Image.LANCZOS).convert("RGBA")
s.putalpha(s.split()[3].point(lambda v: 255 if v > 110 else 0))
arriba = 11 - ALTO // 2
for y in range(arriba + ALTO - 1, arriba + ALTO + 1):
    for x in range(4, 66):
        base.putpixel((x, y), (20, 16, 20, 255))
base.alpha_composite(s, ((72 - ANCHO) // 2, arriba))
base.save(SALIDA)
print(SALIDA, base.size)
