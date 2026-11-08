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

# La puerta de la calle del portal de los Apartamentos (la de llegada, en el muro de la izquierda del pasillo de la planta
# baja), igual pero con la hoja en gris marengo metalizado: el mismo dibujo, con los grises de la hoja oscurecidos a
# marengo (algo azulado) y sus brillos rebajados, sin tocar el contorno. Idea del dueño, 8 nov.
#   → assets/sprites/puerta-abajo-marengo.png (36 × 32)
LINEA = (29, 27, 44)
TINTE = (0.95, 1.0, 1.08)


def marengo(p):
    r, g, b, a = p
    if a == 0 or (r, g, b) == LINEA:
        return p
    luz = (r + g + b) / 3
    # el cuerpo de la hoja (134) pasa a 40 y el brillo (219) a 92; lo oscuro, a casi negro (más oscura, como pidió el dueño)
    nueva = 18 + (luz - 52) * 22 / 82 if luz <= 134 else 40 + (luz - 134) * 52 / 85
    return tuple(max(0, min(255, round(nueva * t))) for t in TINTE) + (a,)


hoja_m = hoja.copy()
hoja_m.putdata([marengo(p) for p in hoja.get_flattened_data()])
calle = Image.open("assets/sprites/puerta-abajo.png").convert("RGBA").crop((108, 0, 144, 32))
cpx = calle.load()
for y in list(range(0, 3)) + list(range(9, 12)):
    for x in range(26, 30):
        cpx[x, y] = cpx[25, y]
calle.alpha_composite(hoja_m, (2, -2))
calle.save("assets/sprites/puerta-abajo-marengo.png")
print("assets/sprites/puerta-abajo-marengo.png", calle.size)
