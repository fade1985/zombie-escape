# La sangre de las paredes de las salas destrozadas de la tienda de ropa (18 nov, el dueño: GPT no se ha dejado pedir marcas de
# sangre en la pared). Salen de los charcos que ya hay en el suelo de los pasillos de los pisos (sangre-suelo-N.png, de GPT): cada uno,
# a un 75 %, con regueros que chorrean hacia abajo desde el borde de abajo del charco (de 1 píxel, algunos de 2, con una gota más
# gorda al final): assets/sprites/sangre-pared-1.png ... -12.png
#   py tools/sangre_pared.py   (y luego Godot --headless --path . --import)
import random
from PIL import Image

dado = random.Random(18)
for n in range(1, 13):
    src = Image.open(f"assets/sprites/sangre-suelo-{n}.png").convert("RGBA")
    w, h = max(8, round(src.width * 0.75)), max(6, round(src.height * 0.75))
    m = src.convert("RGBa").resize((w, h), Image.LANCZOS).convert("RGBA")
    m.putalpha(m.split()[3].point(lambda v: 255 if v > 110 else 0))
    largo_max = 16
    im = Image.new("RGBA", (w, h + largo_max + 2), (0, 0, 0, 0))
    im.alpha_composite(m, (0, 0))
    px = im.load()
    # el borde de abajo de cada columna del charco
    fondo = {}
    for x in range(w):
        for y in range(h - 1, -1, -1):
            if px[x, y][3]:
                fondo[x] = y
                break
    columnas = [x for x in fondo if 2 <= x < w - 2]
    dado.shuffle(columnas)
    puestos = []
    for x in columnas:
        if len(puestos) >= dado.randint(3, 5) or any(abs(x - p) < 4 for p in puestos):
            continue
        puestos.append(x)
        y0 = fondo[x]
        color = px[x, y0][:3]
        oscuro = tuple(int(c * 0.8) for c in color)
        largo = dado.randint(3, largo_max)
        ancho = 2 if dado.random() < 0.25 else 1
        for k in range(1, largo + 1):
            for dx in range(ancho):
                if x + dx < w:
                    px[x + dx, y0 + k] = (oscuro if k % 3 == 0 else color) + (255,)
        # la gota del final
        if x + 1 < w:
            px[x, y0 + largo + 1] = color + (255,)
            if ancho == 1:
                px[x, y0 + largo] = color + (255,)
    im = im.crop(im.getbbox())
    im.save(f"assets/sprites/sangre-pared-{n}.png")
    print(n, im.size)
