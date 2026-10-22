"""Rehace las filas de andar de la hoja de Johnny con un arma, eligiendo a mano qué dibujos de PixelLab se usan.

  py tools/andar_arma.py conserje-48-guardia

Lee assets/sources/<arma>/arma.json → "andar" → "fotogramas": para cada dirección, la lista de dibujos de
assets/sources/<arma>/walk/ que forman el paso, en orden (así se pueden saltar los que repiten postura). Las
direcciones de "espejo" ({"east": "west"}) se hacen con la otra dada la vuelta.

Cada dibujo se coloca como lo hacía tools/arma.py (que no está en git): centrado en la casilla y 1 píxel más abajo,
con cada color cambiado por el más parecido del dibujo quieto de esa dirección (rotations/<dirección>.png), que es
lo que quita los pocos colores sueltos que mete PixelLab. Con las listas antiguas sale la hoja de antes, píxel a píxel.

Toca solo las filas de andar de assets/sprites/<arma>.png y sus números en <arma>.json, y vuelve a sacar el .tres
con tools/hacer_frames.py.
"""
import json, subprocess, sys
import numpy as np
from PIL import Image

arma = sys.argv[1]
FUENTE = f"assets/sources/{arma}"
HOJA = f"assets/sprites/{arma}"

datos = json.load(open(f"{FUENTE}/arma.json", encoding="utf-8"))["andar"]
meta = json.load(open(f"{HOJA}.json", encoding="utf-8"))
hoja = np.array(Image.open(f"{HOJA}.png").convert("RGBA"))
cw, ch = meta["cell"]
filas = meta["anims"]["walk"]["dirs"]


def paleta(direccion):
    quieto = np.array(Image.open(f"{FUENTE}/rotations/{direccion}.png").convert("RGBA")).astype(int)
    return np.unique(quieto[quieto[..., 3] > 0][:, :3], axis=0)


def colocar(dibujo, colores):
    """El dibujo de PixelLab en una casilla de la hoja, con los colores del dibujo quieto."""
    d = dibujo.astype(int)
    visible = d[..., 3] > 0
    px = d[visible][:, :3]
    cerca = ((px[:, None, :] - colores[None, :, :]) ** 2).sum(2).argmin(1)
    d[visible, :3] = colores[cerca]
    casilla = np.zeros((ch, cw, 4), dtype=np.uint8)
    alto, ancho = d.shape[:2]
    x, y = (cw - ancho) // 2, (ch - alto) // 2 + 1
    casilla[y:y + alto, x:x + ancho] = d
    return casilla


espejo = datos.get("espejo", {})   # {"east": "west"}: el este es el oeste dado la vuelta
for direccion, info in filas.items():
    origen = espejo.get(direccion, direccion)
    lista = datos["fotogramas"][origen]
    colores = paleta(origen)
    fila = info["row"]
    hoja[fila * ch:(fila + 1) * ch, :] = 0   # la fila entera en blanco: puede tener menos dibujos que antes
    for i, n in enumerate(lista):
        dibujo = np.array(Image.open(f"{FUENTE}/walk/{origen}-{n}.png").convert("RGBA"))
        casilla = colocar(dibujo, colores)
        if origen != direccion:
            casilla = casilla[:, ::-1]
        hoja[fila * ch:(fila + 1) * ch, i * cw:(i + 1) * cw] = casilla
    info["frames"] = len(lista)
    print(f"{direccion}: {len(lista)} dibujos ({', '.join(map(str, lista))}{', en espejo' if origen != direccion else ''})")

Image.fromarray(hoja).save(f"{HOJA}.png", optimize=True)
json.dump(meta, open(f"{HOJA}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)
subprocess.run([sys.executable, "tools/hacer_frames.py", HOJA], check=True)
