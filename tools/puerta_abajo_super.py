# La puerta de entrada del supermercado vista desde arriba (26 nov, el dueño: «la puerta que se abre doble, pero vista desde arriba»):
# la que se ve dentro de la tienda normal, en el muro de abajo. La puerta automática de la fachada vista desde el techo, con sus mismas
# medidas (128 de ancho): dos cristales fijos a los lados y dos hojas en medio que se corren a esconderse detrás de ellos. Tres dibujos:
#   puerta-abajo-super.png        el paso: el hueco de siempre del centro comercial (puerta-abajo.png, el tercero) sin su hoja
#   puerta-abajo-super-marco.png  los dos cristales fijos y la caja del sensor
#   puerta-abajo-super-hojas.png  las dos hojas
# puerta.gd (puerta_super_abajo) pinta el paso, las hojas (corridas) y encima el marco. Los dos últimos, de 64 × 32 píxeles, 2 unidades cada uno
#   py tools/puerta_abajo_super.py   (y luego Godot --headless --path . --import)
from PIL import Image, ImageDraw

PASO = (70, 72, 88, 255)
LINEA = (28, 26, 38, 255)
LUZ, MEDIO, OSCURO = (176, 176, 182, 255), (118, 118, 124, 255), (66, 66, 74, 255)
CRISTAL, BRILLO, REFLEJO = (14, 52, 60, 255), (38, 96, 106, 255), (92, 158, 166, 255)
SANGRE = (110, 20, 22, 255)

base = Image.open("assets/sprites/puerta-abajo.png").convert("RGBA").crop((72, 0, 108, 32))
for y in range(0, 12):
    base.putpixel((2, y), (115, 119, 138, 255))
    base.putpixel((33, y), (43, 44, 65, 255))
    for x in range(3, 33):
        base.putpixel((x, y), PASO)
base.resize((72, 64), Image.NEAREST).save("assets/sprites/puerta-abajo-super.png")


def panel(d, x0, x1, y0, y1):
    """Un cristal visto desde arriba, entre las columnas x0 y x1 y las filas y0 e y1 (incluidas): contorno, canto de acero y cristal."""
    d.rectangle((x0, y0, x1, y1), fill=MEDIO, outline=LINEA)
    d.line((x0 + 1, y0 + 1, x1 - 1, y0 + 1), fill=LUZ)
    d.line((x0 + 1, y1 - 1, x1 - 1, y1 - 1), fill=OSCURO)
    d.rectangle((x0 + 2, y0 + 3, x1 - 2, y1 - 3), fill=CRISTAL)
    for sx in (x0 + 4, x0 + 9):   # los reflejos en diagonal
        for k in range(y1 - y0 - 5):
            x = sx + (y1 - y0 - 6 - k) // 1
            if x0 + 2 <= x <= x1 - 2:
                d.point((x, y0 + 3 + k), fill=BRILLO)
    d.line((x0 + 3, y0 + 3, x0 + 4, y0 + 3), fill=REFLEJO)


marco = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(marco)
panel(d, 0, 15, 6, 18)
panel(d, 48, 63, 6, 18)
for x0 in (0, 48):   # su sombra
    d.line((x0 + 1, 19, x0 + 15, 19), fill=(18, 15, 20, 255))
for p in ((6, 10), (7, 11), (8, 12), (5, 12), (7, 12), (9, 11), (6, 13)):   # el cristal de la izquierda, roto
    d.point(p, fill=REFLEJO)
d.point((7, 12), fill=LINEA)
d.rectangle((28, 3, 35, 6), fill=OSCURO, outline=LINEA)   # la caja del sensor, del lado de la tienda
d.rectangle((31, 4, 32, 5), fill=(46, 214, 74, 255))
marco.save("assets/sprites/puerta-abajo-super-marco.png")

hojas = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(hojas)
panel(d, 16, 31, 7, 17)
panel(d, 32, 47, 7, 17)
for x in (29, 34):   # los tiradores
    d.line((x, 10, x, 14), fill=LUZ)
for p in ((40, 11), (41, 11), (40, 12), (41, 13), (42, 12), (39, 13), (41, 14)):   # una mano de sangre
    d.point(p, fill=SANGRE)
d.line((17, 18, 47, 18), fill=(18, 15, 20, 255))
hojas.save("assets/sprites/puerta-abajo-super-hojas.png")
print("puerta-abajo-super: paso 72x64, marco y hojas 64x32")
