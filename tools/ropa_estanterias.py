# Las estanterías del almacén de la tienda de ropa, llenas de ropa doblada (18 nov, el dueño). De una hoja de GPT con seis montones
# (assets/sources/ropa/montones-ropa-gpt.webp: 3 columnas × 2 filas sobre negro puro) se recorta cada montón y se reduce a 15 × 9
# píxeles MEZCLANDO colores (LANCZOS, alfa premultiplicado, como los muebles). Se ponen sobre las tres baldas de abajo de la
# estantería de los trasteros (mueble-storageshelf.png), dos montones por balda como mucho, y salen cuatro estanterías distintas:
#   mueble-ropashelf.png, mueble-ropashelf2.png, mueble-ropashelf3.png, mueble-ropashelf4.png   (44 × 63, tipos "ropashelf"...)
#   py tools/ropa_estanterias.py   (y luego Godot --headless --path . --import)
import json
import random
from PIL import Image

HOJA = Image.open("assets/sources/ropa/montones-ropa-gpt.webp").convert("RGB")
ESTANTERIA = Image.open("assets/sprites/mueble-storageshelf.png").convert("RGBA")
TAM = (15, 9)
BALDAS = [19, 36, 53]      # la fila en la que se apoya cada montón (su pie), de arriba abajo
HUECOS = [5, 24]           # y la columna de la izquierda de cada uno de los dos sitios de una balda


def montones():
    w, h = HOJA.size
    salen = []
    for fila in range(2):
        for col in range(3):
            celda = HOJA.crop((col * w // 3, fila * h // 2, (col + 1) * w // 3, (fila + 1) * h // 2)).convert("RGBA")
            px = celda.load()
            for y in range(celda.height):
                for x in range(celda.width):
                    if max(px[x, y][:3]) < 14:
                        px[x, y] = (0, 0, 0, 0)
            celda = celda.crop(celda.getbbox())
            m = celda.convert("RGBa").resize(TAM, Image.LANCZOS).convert("RGBA")
            m.putalpha(m.split()[3].point(lambda v: 255 if v > 110 else 0))
            salen.append(m)
    return salen


def main():
    lista = montones()
    dado = random.Random(18)
    for n, nombre in enumerate(["ropashelf", "ropashelf2", "ropashelf3", "ropashelf4"]):
        im = ESTANTERIA.copy()
        previos = set()
        for pie in BALDAS:
            for x in HUECOS:
                if dado.random() < 0.2:
                    continue   # (a veces, un sitio vacío)
                libres = [i for i in range(len(lista)) if i not in previos] or list(range(len(lista)))
                i = dado.choice(libres)
                previos.add(i)
                im.alpha_composite(lista[i], (x, pie - TAM[1]))
        im.save(f"assets/sprites/mueble-{nombre}.png")
        with open(f"assets/sprites/mueble-{nombre}.json", "w", encoding="utf-8", newline="\n") as f:
            json.dump(json.load(open("assets/sprites/mueble-storageshelf.json", encoding="utf-8")), f, indent=2)
            f.write("\n")
        print(nombre, im.size)


main()
