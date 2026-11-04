# La barrera que pone el grito de la dependienta (M80): la cúpula de cristal del científico jefe
# (assets/sprites/escudo-cristal-*.png, de escudo-cristal.js) pintada en dorado, sin volver a exportarla con pixelfx.
# Cada color de la paleta de cristal pasa a su dorado; el brillo (luz que se suma) se gira de azul a amarillo.
# Uso: py tools/pixelfx/escudo-barrera.py   →   assets/sprites/escudo-barrera-*.png
from PIL import Image

CRISTAL = ["#06101e", "#0e2a4a", "#1a4f86", "#2b7cc4", "#4aa8ee", "#8fd0ff", "#d0efff", "#f4fbff", "#ffffff"]
DORADO = ["#1a1206", "#3d2a0a", "#6e4a10", "#a87818", "#e0aa2a", "#ffd23f", "#ffeb94", "#fff8dc", "#ffffff"]


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


PAR = [(rgb(a), rgb(b)) for a, b in zip(CRISTAL, DORADO)]


def a_dorado(c):
    r, g, b, a = c
    if a == 0:
        return c
    # el color de la paleta de cristal más parecido, y su dorado
    _, d = min(PAR, key=lambda p: sum((x - y) ** 2 for x, y in zip(p[0], (r, g, b))))
    return d + (a,)


def brillo(c):
    r, g, b, a = c
    return (b, g, int(r * 0.4), a)   # de azul (b > g > r) a amarillo (r > g > b)


for capa, cambio in [("detras", a_dorado), ("delante", a_dorado), ("brillo", brillo)]:
    im = Image.open("assets/sprites/escudo-cristal-%s.png" % capa).convert("RGBA")
    im.putdata([cambio(c) for c in im.getdata()])
    im.save("assets/sprites/escudo-barrera-%s.png" % capa)
    print("escudo-barrera-%s.png" % capa)
