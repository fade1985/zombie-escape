"""El cartel de la planta en inglés: «PLANTA» → «FLOOR».

Los carteles de la planta (assets/sprites/cartel-planta-N.png, 28 × 42 píxeles, de PixelLab: tools/guias_cartel.py) llevan «PLANTA»
pintado en la fila de arriba, en un solo color y con letras de 3 × 5 píxeles. Aquí se borra esa palabra y se pone «FLOOR» con las
mismas letras y el mismo color, centrado, y se guarda como cartel-planta-N-en.png. El número de debajo no se toca.
puerta.gd elige un juego u otro según Idioma.actual.

  py tools/cartel_planta_en.py
"""
import os
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(RAIZ, "assets", "sprites")
FILAS = range(2, 7)   # las cinco filas de la palabra
LETRAS = {
    "F": ["###", "#..", "##.", "#..", "#.."],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "O": ["###", "#.#", "#.#", "#.#", "###"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
}
PALABRA = "FLOOR"

for n in range(4):
    im = Image.open(os.path.join(SPRITES, f"cartel-planta-{n}.png")).convert("RGBA")
    color = next(im.getpixel((x, 3)) for x in range(im.width) if im.getpixel((x, 3))[3] > 128)   # el amarillo de la palabra
    for y in FILAS:
        for x in range(im.width):
            im.putpixel((x, y), (0, 0, 0, 0))
    ancho = len(PALABRA) * 3 + (len(PALABRA) - 1)
    x0 = (im.width - ancho) // 2
    for i, letra in enumerate(PALABRA):
        for f, fila in enumerate(LETRAS[letra]):
            for c, p in enumerate(fila):
                if p == "#":
                    im.putpixel((x0 + i * 4 + c, FILAS[0] + f), color)
    im.save(os.path.join(SPRITES, f"cartel-planta-{n}-en.png"))
    print("cartel-planta-%d-en.png" % n)
