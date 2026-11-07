# La puerta de chapa gris de la pared de abajo de la sala de mantenimiento (y, girada, la de su pared de la derecha, la
# que da a los trasteros, y la de las viviendas que vuelve a ella): la de puerta-abajo.png (el cuarto dibujo, el de chapa
# gris) con la hoja de la puerta metálica del despacho al taller (puerta-metal-lado-cerrada.png, de tools/puerta_metal.py)
# en vez de su barra gris lisa, para que todas las puertas de la sala sean iguales. Idea del dueño, 7 nov.
#   py tools/puerta_abajo_metal.py     → assets/sprites/puerta-abajo-metal.png (36 × 32)
from PIL import Image

base = Image.open("assets/sprites/puerta-abajo.png").convert("RGBA").crop((108, 0, 144, 32))
px = base.load()
# fuera la barra lisa (filas 3 a 8) y sus dos pomos (columnas 26 a 29, encima y debajo de la barra): el muro y el hueco
# de al lado, la columna 25
for y in list(range(0, 3)) + list(range(9, 12)):
    for x in range(26, 30):
        px[x, y] = px[25, y]
# la hoja metálica, tumbada (el pomo hacia la derecha, como el de antes): su barra cae justo en las filas 3 a 8
hoja = Image.open("assets/sprites/puerta-metal-lado-cerrada.png").convert("RGBA").rotate(90, expand=True)
base.alpha_composite(hoja, (2, -2))
base.save("assets/sprites/puerta-abajo-metal.png")
print("assets/sprites/puerta-abajo-metal.png", base.size)
