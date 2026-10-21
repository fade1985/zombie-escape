# Monta la hoja de un minijefe del centro comercial (lienzo de 72, como el zombi venenoso) y su SpriteFrames.
# Uso (desde la raíz del proyecto):  py tools/jefe_hoja.py antidisturbios-72 jefe-antidisturbios
# Lee assets/sources/<fuente>/: rotations/<dirección>.png (las 8 vistas quietas) y, si ya están, las animaciones
# de PixelLab en <carpeta>/<dirección>-<n>.png (las baja tools/bajar_zip.py). Saca assets/sprites/<salida>.png
# (una fila por animación y dirección, casillas de 144) y <salida>.tres con "quieto_s", "andar_ne", "porrazo_o"...
# Las animaciones que aún no estén dibujadas se rellenan con la vista quieta: así el juego ya funciona con las
# 8 vistas y, cuando llegan las de PixelLab, basta con volver a correr el script.
import os
import sys
from PIL import Image

fuente, salida = sys.argv[1], sys.argv[2]
src = f"assets/sources/{fuente}"
CASILLA = 144
# Dónde va cada lienzo dentro de su casilla: el de 72 (vistas y andar) en (36, 48); los de 128 (los que se
# pidieron con el dibujo pegado en (28, 44) de un lienzo mayor), en (8, 4), para que el muñeco caiga en el mismo sitio
ORIGEN = {72: (36, 48), 128: (8, 4)}
DIRS = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne",
        "north": "n", "north-west": "no", "west": "o", "south-west": "so"}
# nombre en el juego: (carpeta de PixelLab, fotogramas por segundo, en bucle, quitar el último fotograma)
# (el andar de PixelLab termina en la misma postura con la que empieza: sin quitarlo, ese paso se vería dos veces)
ANIMS = {
    "quieto": ("rotations", 1, True, False),
    "reposo": ("rotations", 1, True, False),
    "andar": ("walk", 9, True, True),
    "porrazo": ("porrazo", 12, False, False),
    "carga": ("carga", 12, False, False),
    "golpe": ("golpe", 16, False, False),
    "muerte": ("muerte", 10, False, False),
    "silbato": ("silbato", 9, False, False),
}


def fotogramas(carpeta: str, d: str, quitar_ultimo: bool) -> list:
    if carpeta == "rotations":
        return [Image.open(f"{src}/rotations/{d}.png").convert("RGBA")]
    ruta = f"{src}/{carpeta}"
    if not os.path.isdir(ruta):
        return []
    nombres = sorted((f for f in os.listdir(ruta) if f.startswith(d + "-") and f[len(d) + 1:-4].isdigit()),
                     key=lambda f: int(f[len(d) + 1:-4]))
    lista = [Image.open(f"{ruta}/{f}").convert("RGBA") for f in nombres]
    return lista[:-1] if quitar_ultimo and len(lista) > 2 else lista


filas = []   # (nombre, fps, bucle, [imágenes])
for nombre, (carpeta, fps, bucle, quitar) in ANIMS.items():
    for d, dd in DIRS.items():
        imgs = fotogramas(carpeta, d, quitar)
        if not imgs:
            if nombre == "silbato" and d != "south":
                continue   # el silbato solo está dibujado de frente
            imgs = fotogramas("rotations", d, False)
        filas.append((f"{nombre}_{dd}", fps if len(imgs) > 1 else 1, bucle, imgs))

ancho = max(len(f[3]) for f in filas)
hoja = Image.new("RGBA", (ancho * CASILLA, len(filas) * CASILLA))
for fila, (_, _, _, imgs) in enumerate(filas):
    for col, im in enumerate(imgs):
        hoja.alpha_composite(im, (col * CASILLA + ORIGEN[im.width][0], fila * CASILLA + ORIGEN[im.width][1]))
hoja.save(f"assets/sprites/{salida}.png")

subs, anims = [], []
for fila, (nombre, fps, bucle, imgs) in enumerate(filas):
    frames = []
    for col in range(len(imgs)):
        sid = f"t{len(subs)}"
        subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("hoja")\n'
                    f'region = Rect2({col * CASILLA}, {fila * CASILLA}, {CASILLA}, {CASILLA})\n')
        frames.append(f'{{"duration": 1.0, "texture": SubResource("{sid}")}}')
    anims.append(f'{{"frames": [{", ".join(frames)}], "loop": {str(bucle).lower()}, '
                 f'"name": &"{nombre}", "speed": {float(fps)}}}')
with open(f"assets/sprites/{salida}.tres", "w", encoding="utf-8", newline="\n") as out:
    out.write(f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n')
    out.write(f'[ext_resource type="Texture2D" path="res://assets/sprites/{salida}.png" id="hoja"]\n\n')
    out.write("\n".join(subs))
    out.write("\n[resource]\nanimations = [" + ", ".join(anims) + "]\n")
print(f"assets/sprites/{salida}: {len(filas)} animaciones, {len(subs)} fotogramas")
