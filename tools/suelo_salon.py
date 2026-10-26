"""El suelo del salón de los pisos: el de madera clara de siempre (suelo-salon-b), con las tablas giradas (en horizontal) y
oscurecido, de color nogal, para que no se confunda con el del pasillo, que sigue con el de antes (mapa.gd, ESTILO_FIJO).

  py tools/suelo_salon.py   → assets/sprites/suelo-salon-nogal.png (y su .json, copia del de suelo-salon-b)
Después, importar en Godot (--headless --path . --import).
"""
import shutil
from PIL import Image

ORIGEN = 'assets/sprites/suelo-salon-b'
SALIDA = 'assets/sprites/suelo-salon-nogal'
NOGAL = (0.52, 0.42, 0.34)   # por cuánto se multiplica el rojo, el verde y el azul: más oscuro y más cálido

im = Image.open(ORIGEN + '.png').convert('RGBA').rotate(90)   # el suelo es un cuadrado que se repite: girado, sigue encajando
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        px[x, y] = (int(r * NOGAL[0]), int(g * NOGAL[1]), int(b * NOGAL[2]), a)
im.save(SALIDA + '.png')
shutil.copyfile(ORIGEN + '.json', SALIDA + '.json')
print(SALIDA + '.png', im.size)
