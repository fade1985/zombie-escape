# Colorea los iconos amarillos del escritorio del ordenador que van de otro color (12 nov):
#   - Dosier VD-7: la carpeta, marrón como un fichero de cartón
#   - Talentos: cada una de las tres flechas con el color de su rama (izquierda Militar, en medio Superviviente,
#     derecha Químico: el orden del árbol, ui/arbol_talentos.gd, COLORES; el principal de cada una)
#   - Tienda de armas: la mirilla, de metal (gris acero; antes, en rojo)
#   - Sujetos: el cuaderno, casi negro (gris muy oscuro, para que se vea el borde)
#   - Vídeos: el «play», azul
#   - La interrogación de los sujetos sin ver (assets/ui/interrogacion.png), aún más negra
# Gira el tono del amarillo y le pone la viveza y la luz del color nuevo, sin tocar el borde oscuro: las luces y las
# sombras del dibujo se quedan como estaban.
# Se pasa después de tools/muebles_gpt.py (que los saca amarillos de la imagen de GPT):
#   py tools/muebles_gpt.py escritorio_talentos escritorio_armas escritorio_dosier escritorio_colecciones escritorio_videos interrogacion
#   py tools/colorear_iconos.py
# Si un icono ya está coloreado, no lo vuelve a tocar.
import colorsys
from PIL import Image

AMARILLO = "#d6a521"   # el amarillo de Químico, que es como están pintados los iconos

# [icono, colores(, ajustes)]: un color por trozo amarillo, de izquierda a derecha; con uno solo, todo el icono de ese
# color. Los ajustes, si hacen falta: "viveza", lo poco vivo que puede ser un amarillo para contar (0.45 si no se dice;
# en Sujetos, menos, para coger también el borde de arriba del cuaderno, más apagado, sin tocar la etiqueta crema), y
# "desde", el tono más rojizo que cuenta (0.08 si no se dice; en la interrogación, menos: abajo es naranja)
ICONOS = [
    ("assets/ui/iconos/escritorio-talentos.png", ["#d2452b", "#4f9e34", "#d6a521"]),
    ("assets/ui/iconos/escritorio-armas.png", ["#9aa4ae"]),
    ("assets/ui/iconos/escritorio-dosier.png", ["#a8743a"]),
    ("assets/ui/iconos/escritorio-colecciones.png", ["#3a3a42"], {"viveza": 0.35}),
    ("assets/ui/iconos/escritorio-videos.png", ["#3a78d4"], {"desde": 0.0}),   # (también el borde naranja oscuro: en azul se notaba)
    ("assets/ui/interrogacion.png", ["#141418"], {"desde": 0.05}),   # (la de los sujetos sin ver, casi negro del todo)
]


def hsv(hexa):
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hsv(r, g, b)


def amarillo(px, x, y, viveza, desde):
    r, g, b, a = px[x, y]
    if a == 0:
        return False
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return s > viveza and desde < h < 0.2 and v > 0.1


# Los trozos de amarillo que se tocan (en las flechas, cada una es uno: las separa el borde oscuro), de izquierda a derecha
def trozos(px, w, h, viveza, desde):
    grupo, lista = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in grupo or not amarillo(px, x, y, viveza, desde):
                continue
            pila, trozo = [(x, y)], []
            grupo.add((x, y))
            while pila:
                cx, cy = pila.pop()
                trozo.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in grupo and amarillo(px, nx, ny, viveza, desde):
                        grupo.add((nx, ny))
                        pila.append((nx, ny))
            lista.append(trozo)
    return sorted(lista, key=lambda t: min(p[0] for p in t))


ref = hsv(AMARILLO)
for ruta, colores, *ajustes in ICONOS:
    ajustes = ajustes[0] if ajustes else {}
    im = Image.open(ruta).convert("RGBA")
    px = im.load()
    partes = trozos(px, *im.size, ajustes.get("viveza", 0.45), ajustes.get("desde", 0.08))
    if len(colores) == 1:
        partes = [[p for t in partes for p in t]]
    todos = [colorsys.rgb_to_hsv(*(c / 255 for c in px[p][:3])) for t in partes for p in t]
    medio = sum(t[0] for t in todos) / len(todos) if todos else 0   # el tono medio del amarillo de ahora
    # (ya coloreado: no quedan los trozos de amarillo de antes o, como el marrón del Dosier, que también cuenta como
    # amarillo, su tono medio ya no es el del amarillo)
    if len(partes) != len(colores) or len(partes[0]) < 20 or abs(medio - ref[0]) > 0.025:
        print("%s: ya está coloreado (o el dibujo ha cambiado), no se toca" % ruta)
        continue
    for parte, color in zip(partes, colores):
        th, ts, tv = hsv(color)
        for p in parte:
            r, g, b, a = px[p]
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            nr, ng, nb = colorsys.hsv_to_rgb((th + h - medio) % 1.0, min(1, s * ts / ref[1]), min(1, v * tv / ref[2]))
            px[p] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    im.save(ruta)
    print("%s: coloreado" % ruta)
