"""El cartel de la planta en cada idioma: «PLANTA» → «FLOOR», «ANDAR», «ETAGE»...

Los carteles de la planta (assets/sprites/cartel-planta-N.png, 28 × 42 píxeles, de PixelLab: tools/guias_cartel.py) llevan «PLANTA»
pintado en la fila de arriba, en un solo color y con letras de 3 × 5 píxeles. Aquí se borra esa palabra y se pone la del idioma con
las mismas letras y el mismo color, centrada, y se guarda como cartel-planta-N-<idioma>.png. El número de debajo no se toca.
mapa/puerta.gd elige el juego de carteles según Idioma.actual (CARTELES_POR_IDIOMA).

  py tools/cartel_planta_idiomas.py          (todos los idiomas de PALABRAS)

Para un idioma nuevo: su palabra en PALABRAS (en mayúsculas, sin acentos: la letra es de 3 × 5 píxeles) y las letras que le falten
en LETRAS; luego, su juego de carteles en puerta.gd.
"""
import os
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(RAIZ, "assets", "sprites")
FILAS = range(2, 7)   # las cinco filas de la palabra
PALABRAS = {"en": "FLOOR", "pt_BR": "ANDAR", "de": "ETAGE", "fr": "ETAGE"}
LETRAS = {
    "A": ["###", "#.#", "###", "#.#", "#.#"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": ["###", "#..", "#.#", "#.#", "###"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
    "O": ["###", "#.#", "#.#", "#.#", "###"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
}

for idioma, palabra in PALABRAS.items():
    for n in range(4):
        im = Image.open(os.path.join(SPRITES, f"cartel-planta-{n}.png")).convert("RGBA")
        color = next(im.getpixel((x, 3)) for x in range(im.width) if im.getpixel((x, 3))[3] > 128)   # el amarillo de la palabra
        for y in FILAS:
            for x in range(im.width):
                im.putpixel((x, y), (0, 0, 0, 0))
        ancho = len(palabra) * 3 + (len(palabra) - 1)
        x0 = (im.width - ancho) // 2
        for i, letra in enumerate(palabra):
            for f, fila in enumerate(LETRAS[letra]):
                for c, p in enumerate(fila):
                    if p == "#":
                        im.putpixel((x0 + i * 4 + c, FILAS[0] + f), color)
        im.save(os.path.join(SPRITES, f"cartel-planta-{n}-{idioma}.png"))
    print(idioma, palabra)
