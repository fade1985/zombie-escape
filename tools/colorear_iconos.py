# Colorea los iconos amarillos del escritorio del ordenador que van de otro color (12 nov):
#   - Talentos: cada una de las tres flechas con el color de su rama (izquierda Militar, en medio Superviviente,
#     derecha Químico: el orden del árbol, ui/arbol_talentos.gd, COLORES; el principal de cada una)
#   - Tienda de armas: la mirilla, en rojo (el del icono de Apagar)
# Gira el tono del amarillo y le pone la viveza y la luz del color nuevo, sin tocar el borde oscuro: las luces y las
# sombras del dibujo se quedan como estaban.
# Se pasa después de tools/muebles_gpt.py (que los saca amarillos de la imagen de GPT):
#   py tools/muebles_gpt.py escritorio_talentos escritorio_armas
#   py tools/colorear_iconos.py
# Si un icono ya está coloreado, no lo vuelve a tocar.
import colorsys
from PIL import Image

AMARILLO = "#d6a521"   # el amarillo de Químico, que es como están pintados los iconos

# [icono, colores]: un color por trozo amarillo, de izquierda a derecha; con uno solo, todo el icono de ese color
ICONOS = [
    ("assets/ui/iconos/escritorio-talentos.png", ["#d2452b", "#4f9e34", "#d6a521"]),
    ("assets/ui/iconos/escritorio-armas.png", ["#d33a34"]),
]


def hsv(hexa):
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hsv(r, g, b)


def amarillo(px, x, y):
    r, g, b, a = px[x, y]
    if a == 0:
        return False
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return s > 0.45 and 0.08 < h < 0.2 and v > 0.1


# Los trozos de amarillo que se tocan (en las flechas, cada una es uno: las separa el borde oscuro), de izquierda a derecha
def trozos(px, w, h):
    grupo, lista = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in grupo or not amarillo(px, x, y):
                continue
            pila, trozo = [(x, y)], []
            grupo.add((x, y))
            while pila:
                cx, cy = pila.pop()
                trozo.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in grupo and amarillo(px, nx, ny):
                        grupo.add((nx, ny))
                        pila.append((nx, ny))
            lista.append(trozo)
    return sorted(lista, key=lambda t: min(p[0] for p in t))


ref = hsv(AMARILLO)
for ruta, colores in ICONOS:
    im = Image.open(ruta).convert("RGBA")
    px = im.load()
    partes = trozos(px, *im.size)
    if len(colores) == 1:
        partes = [[p for t in partes for p in t]]
    if len(partes) != len(colores) or len(partes[0]) < 20:
        print("%s: ya está coloreado (o el dibujo ha cambiado), no se toca" % ruta)
        continue
    todos = [colorsys.rgb_to_hsv(*(c / 255 for c in px[p][:3])) for t in partes for p in t]
    medio = sum(t[0] for t in todos) / len(todos)   # el tono medio del amarillo de ahora
    for parte, color in zip(partes, colores):
        th, ts, tv = hsv(color)
        for p in parte:
            r, g, b, a = px[p]
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            nr, ng, nb = colorsys.hsv_to_rgb((th + h - medio) % 1.0, min(1, s * ts / ref[1]), min(1, v * tv / ref[2]))
            px[p] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    im.save(ruta)
    print("%s: coloreado" % ruta)
