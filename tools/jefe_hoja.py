# Monta la hoja de un minijefe del centro comercial (lienzo de 72, como el zombi venenoso) y su SpriteFrames.
# Uso (desde la raíz del proyecto):  py tools/jefe_hoja.py antidisturbios-72 jefe-antidisturbios
#                                    py tools/jefe_hoja.py cocinero-72 jefe-cocinero
#                                    py tools/jefe_hoja.py modista-72 jefe-modista
#                                    py tools/jefe_hoja.py mascota-72 jefe-mascota
#                                    py tools/jefe_hoja.py gerente-128 jefe-gerente   (el jefe final, lienzo de 128)
#                                    py tools/jefe_hoja.py portera-72 jefe-portera    (la jefa de los Apartamentos)
# Lee assets/sources/<fuente>/: rotations/<dirección>.png (las 8 vistas quietas) y, si ya están, las animaciones
# de PixelLab en <carpeta>/<dirección>-<n>.png (las baja tools/bajar_zip.py). Saca assets/sprites/<salida>.png
# (todas las casillas seguidas, en filas de hasta ~4000 píxeles) y <salida>.tres con "quieto_s", "andar_ne",
# "porrazo_o"... Las animaciones que aún no estén dibujadas se rellenan con la vista quieta.
#
# PixelLab devuelve cada animación en un lienzo de otro tamaño (104, 128x140, 180x152...). Para que el muñeco no
# salte, cada animación se coloca de modo que su primer fotograma (que es la vista quieta) caiga encima de la
# vista quieta: mismo borde izquierdo y mismos pies. Y se le quitan las motas sueltas (gotas, rayas de
# movimiento) que PixelLab pinta fuera del cuerpo.
# Al final escribe el "offset" que hay que poner al Sprite de su escena (la casilla depende de lo que ocupen).
import os
import sys
from PIL import Image

fuente, salida = sys.argv[1], sys.argv[2]
src = f"assets/sources/{fuente}"
ANCHO_HOJA = 4000
MOTA = 30          # los trozos sueltos de menos píxeles que esto se borran
PIES = (36, 70)    # el punto de los pies en el lienzo de 72 (el centro del Sprite va ahí; el gerente pone el suyo)
DIRS = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne",
        "north": "n", "north-west": "no", "west": "o", "south-west": "so"}
# Lo de cada jefe. "anims": nombre en el juego: (carpeta de PixelLab, fotogramas por segundo, en bucle, quitar el
# último fotograma[, quitar el primero]) (el andar de PixelLab termina en la misma postura con la que empieza: sin
# quitarlo, ese paso se vería dos veces; y la embestida de la mascota empieza de pie: en la carrera sobra).
# "de_frente": las que solo se dibujan mirando hacia abajo. "sangre": oscurecer la sangre roja viva de PixelLab
# (como en tools/zombi.py, decidido por el dueño: que no desentone; con un número, solo los rojos a partir de ese,
# para no tocar la sangre oscura que ya trae el dibujo). "pies": el punto de los pies si el lienzo no es de 72.
# "motas": en esas animaciones se borran también los trozos sueltos más grandes (lo que lanza y sale volando, que ya
# lo dibuja el juego). "sin": fotogramas que se quitan de una animación en una dirección (el número del archivo)
JEFES = {
    "antidisturbios-72": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "porrazo": ("porrazo", 12, False, False),
            "carga": ("carga", 12, False, False),
            "golpe": ("golpe", 16, False, False),
            "muerte": ("muerte", 10, False, False),
            "silbato": ("silbato", 9, False, False),
        },
        "de_frente": ["silbato"],
    },
    # el cocinero: "lanzar" vale para el abanico, la lluvia y la sartén
    "cocinero-72": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "lanzar": ("lanzar", 12, False, False),
            "cuchillazo": ("cuchillazo", 12, False, False),
            "golpe": ("golpe", 16, False, False),
            "muerte": ("muerte", 10, False, False),
        },
        "sangre": True,
    },
    # la modista: los alfileres y el brillo de los ojos, con código
    "modista-72": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "alfileres": ("alfileres", 12, False, False),
            "tijeretazo": ("tijeretazo", 12, False, False),
            "golpe": ("golpe", 16, False, False),
            "muerte": ("muerte", 10, False, False),
        },
    },
    # la mascota: la embestida es una carrera en bucle y el salto va por fotogramas (agacharse, aire, caer)
    "mascota-72": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "embestida": ("embestida", 14, True, False, True),
            "salto": ("salto", 12, False, False),
            "golpe": ("golpe", 16, False, False),
            "muerte": ("muerte", 10, False, False),
        },
    },
    # el gerente (jefe final, lienzo de 128 como la portera): los contratos salen con código (contrato.gd). Sin
    # golpe ni muerte (cae de lado; en la parte 3 el que muere es el mutado); la jeringa es para la parte 3
    "gerente-128": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "contratos": ("contratos", 12, False, False),
            "maletinazo": ("maletinazo", 12, False, False),
            "a_trabajar": ("a-trabajar", 9, False, False),
            "jeringa": ("jeringa", 10, False, False),
            "muerte": ("muerte", 10, False, False),
        },
        "de_frente": ["a_trabajar", "jeringa"],
        "pies": (64, 124),
    },
    # el gerente mutado (parte 3 del trozo 6): los latigazos largos salen con código (gerente.gd); la embestida,
    # carrera en bucle como la de la mascota (sin el primer fotograma, que es de pie)
    "gerente-mutado-128": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "latigazo": ("latigazo", 12, False, False),
            "embestida": ("embestida", 14, True, False, True),
            "muerte": ("muerte", 10, False, False),
        },
        "pies": (64, 127),
    },
    # la portera (la jefa de los Apartamentos), rehecha a 72 como los minijefes: "ataque" es el fregonazo
    # (levanta la fregona y la baja) y "lanzar", la lejía; el abanico, el ácido y el giro usan esas mismas
    "portera-72": {
        "anims": {
            "quieto": ("rotations", 1, True, False),
            "reposo": ("rotations", 1, True, False),
            "andar": ("walk", 9, True, True),
            "ataque": ("fregonazo", 10, False, False),
            "lanzar": ("lanzar", 10, False, False),
            "grito": ("grito", 8, False, False),
            "muerte": ("muerte", 10, False, False),
        },
        "de_frente": ["grito"],
        "sangre": 160,                 # solo los salpicones rojo vivo del fregonazo
        "motas": {"lanzar": 300},      # la botella que sale volando
        "sin": {"lanzar_s": [6, 7]},   # de frente, la botella se ve enorme al venir hacia la cámara
    },
}
JEFE = JEFES[fuente]
PIES = JEFE.get("pies", PIES)
ANIMS = JEFE["anims"]


def oscurecer(im: Image.Image, desde: int = 110) -> Image.Image:
    """La sangre roja viva, a un rojo apagado: baja cada rojo por igual, para que no pierda sus sombras."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and r >= desde and r > 1.8 * g and r > 1.8 * b:
                px[x, y] = (int(r * 0.65), int(g * 0.3), int(b * 0.27), a)
    return im


def limpiar(im: Image.Image, mota: int = MOTA) -> Image.Image:
    """Borra los trozos sueltos pequeños (contando juntos los píxeles que se tocan, también en diagonal)."""
    w, h = im.size
    px = im.load()
    visto = [[False] * w for _ in range(h)]
    for y0 in range(h):
        for x0 in range(w):
            if visto[y0][x0] or px[x0, y0][3] == 0:
                continue
            trozo, pila = [], [(x0, y0)]
            visto[y0][x0] = True
            while pila:
                x, y = pila.pop()
                trozo.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not visto[ny][nx] and px[nx, ny][3] > 0:
                            visto[ny][nx] = True
                            pila.append((nx, ny))
            if len(trozo) < mota:
                for x, y in trozo:
                    px[x, y] = (0, 0, 0, 0)
    return im


def quieta(d: str) -> Image.Image:
    return Image.open(f"{src}/rotations/{d}.png").convert("RGBA")


# Los fotogramas de una animación y dónde va su esquina respecto al lienzo de 72
def fotogramas(carpeta: str, d: str, quitar_ultimo: bool, quitar_primero: bool = False, mota: int = MOTA,
               sin: tuple = ()) -> list:
    if carpeta == "rotations":
        return [(quieta(d), (0, 0))]
    ruta = f"{src}/{carpeta}"
    if not os.path.isdir(ruta):
        return []
    nombres = sorted((f for f in os.listdir(ruta) if f.startswith(d + "-") and f[len(d) + 1:-4].isdigit()),
                     key=lambda f: int(f[len(d) + 1:-4]))
    if not nombres:
        return []
    lista = [Image.open(f"{ruta}/{f}").convert("RGBA") for f in nombres if int(f[len(d) + 1:-4]) not in sin]
    if quitar_ultimo and len(lista) > 2:
        lista = lista[:-1]
    a, b = quieta(d).getbbox(), lista[0].getbbox()
    if abs((a[2] - a[0]) - (b[2] - b[0])) > 3:
        print(f"  ojo: {carpeta}/{d}: su primer fotograma no se parece a la vista quieta")
    sitio = (a[0] - b[0], a[3] - b[3])
    if quitar_primero:   # (después de alinear, que se hace con el primero)
        lista = lista[1:]
    return [(limpiar(im, mota), sitio) for im in lista]


filas = []   # (nombre, fps, bucle, [(imagen, sitio)])
for nombre, (carpeta, fps, bucle, *quitar) in ANIMS.items():
    for d, dd in DIRS.items():
        imgs = fotogramas(carpeta, d, *quitar, mota=JEFE.get("motas", {}).get(nombre, MOTA),
                          sin=JEFE.get("sin", {}).get(f"{nombre}_{dd}", ()))
        if not imgs:
            if nombre in JEFE.get("de_frente", []) and d != "south":
                continue   # solo está dibujada de frente
            imgs = fotogramas("rotations", d, False)
        filas.append((f"{nombre}_{dd}", fps if len(imgs) > 1 else 1, bucle, imgs))

# La casilla: lo justo para que quepa todo (con 2 píxeles de margen)
x0 = min(s[0] + im.getbbox()[0] for f in filas for im, s in f[3] if im.getbbox()) - 2
y0 = min(s[1] + im.getbbox()[1] for f in filas for im, s in f[3] if im.getbbox()) - 2
x1 = max(s[0] + im.getbbox()[2] for f in filas for im, s in f[3] if im.getbbox()) + 2
y1 = max(s[1] + im.getbbox()[3] for f in filas for im, s in f[3] if im.getbbox()) + 2
cw, ch = x1 - x0, y1 - y0
por_fila = ANCHO_HOJA // cw
total = sum(len(f[3]) for f in filas)
hoja = Image.new("RGBA", (por_fila * cw, -(-total // por_fila) * ch))
regiones = []   # por fila de animación, la casilla de cada fotograma
n = 0
for _, _, _, imgs in filas:
    casillas = []
    for im, s in imgs:
        cx, cy = (n % por_fila) * cw, (n // por_fila) * ch
        hoja.alpha_composite(im, (cx + s[0] - x0, cy + s[1] - y0))
        casillas.append((cx, cy))
        n += 1
    regiones.append(casillas)
if JEFE.get("sangre"):
    hoja = oscurecer(hoja, 110 if JEFE["sangre"] is True else JEFE["sangre"])
hoja.save(f"assets/sprites/{salida}.png")

subs, anims = [], []
for (nombre, fps, bucle, _), casillas in zip(filas, regiones):
    frames = []
    for cx, cy in casillas:
        sid = f"t{len(subs)}"
        subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("hoja")\n'
                    f'region = Rect2({cx}, {cy}, {cw}, {ch})\n')
        frames.append(f'{{"duration": 1.0, "texture": SubResource("{sid}")}}')
    anims.append(f'{{"frames": [{", ".join(frames)}], "loop": {str(bucle).lower()}, '
                 f'"name": &"{nombre}", "speed": {float(fps)}}}')
with open(f"assets/sprites/{salida}.tres", "w", encoding="utf-8", newline="\n") as out:
    out.write(f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n')
    out.write(f'[ext_resource type="Texture2D" path="res://assets/sprites/{salida}.png" id="hoja"]\n\n')
    out.write("\n".join(subs))
    out.write("\n[resource]\nanimations = [" + ", ".join(anims) + "]\n")
print(f"assets/sprites/{salida}: {len(filas)} animaciones, {total} fotogramas, casilla {cw}x{ch}, hoja {hoja.size}")
print(f"offset del Sprite en su escena: Vector2({x0 - PIES[0]}, {y0 - PIES[1]})")
