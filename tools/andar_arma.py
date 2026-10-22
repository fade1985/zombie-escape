"""Rehace las filas de andar de la hoja de Johnny con un arma, eligiendo a mano qué dibujos de PixelLab se usan.

  py tools/andar_arma.py conserje-48-guardia

Lee assets/sources/<arma>/arma.json → "andar" → "fotogramas": para cada dirección, la lista de dibujos de
assets/sources/<arma>/walk/ que forman el paso, en orden (así se pueden saltar los que repiten postura). Las
direcciones de "espejo" ({"east": "west"}) se hacen con la otra dada la vuelta.

Cada dibujo se coloca como lo hacía tools/arma.py (que no está en git): centrado en la casilla y 1 píxel más abajo,
con cada color cambiado por el más parecido del dibujo quieto de esa dirección (rotations/<dirección>.png), que es
lo que quita los pocos colores sueltos que mete PixelLab. Luego se sube o se baja entero para que su píxel más bajo
(el pie que pisa) quede a la altura de los pies de Johnny quieto en esa dirección (la fila "still" de la hoja): así
no se hunde en el suelo ni flota al andar (paso 2, 23 oct).

Antes de eso se limpian los pies (paso 3): se quitan los píxeles gris mopa que quedan sueltos debajo de un zapato, y en
los dibujos de "zapatos_negros" ({"north": [1, 4, 5]}) el zapato relleno del color del borde se pinta de marrón.

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


BORDE, ZAPATO, GRIS = (5, 2, 2), (49, 17, 8), (143, 140, 137)   # colores de la paleta de Johnny con fregona
ZONA_PIES = 8   # filas desde abajo en las que se buscan zapatos y grises


def limpiar_pies(casilla, zapato_negro):
    """Quita los grises sueltos bajo los zapatos y, si zapato_negro, pinta de marrón el zapato relleno de borde."""
    c = casilla.copy()
    visible = c[..., 3] > 0
    arriba = suelo(c) - ZONA_PIES + 1
    def de_color(color):
        sitio = (c[..., :3] == color).all(-1) & visible
        sitio[:arriba] = False
        return sitio
    nada_debajo = np.ones_like(visible)
    nada_debajo[:-1] = ~visible[1:]
    c[de_color(GRIS) & nada_debajo] = 0
    if zapato_negro:
        rodeado = np.zeros_like(visible)   # con dibujo arriba, abajo y a los lados: no es borde
        rodeado[1:-1, 1:-1] = visible[:-2, 1:-1] & visible[2:, 1:-1] & visible[1:-1, :-2] & visible[1:-1, 2:]
        c[de_color(BORDE) & rodeado, :3] = ZAPATO
    return c


def suelo(casilla):
    """La fila del píxel visible más bajo de una casilla: donde pisa."""
    return int(np.nonzero(casilla[..., 3].any(1))[0].max())


def a_ras(casilla, fila_pies):
    """La casilla movida arriba o abajo para que pise en fila_pies."""
    return np.roll(casilla, fila_pies - suelo(casilla), axis=0)


espejo = datos.get("espejo", {})   # {"east": "west"}: el este es el oeste dado la vuelta
zapatos_negros = datos.get("zapatos_negros", {})
for direccion, info in filas.items():
    origen = espejo.get(direccion, direccion)
    lista = datos["fotogramas"][origen]
    colores = paleta(origen)
    fila = info["row"]
    quieto = meta["anims"]["still"]["dirs"][direccion]
    pies = suelo(hoja[quieto["row"] * ch:(quieto["row"] + 1) * ch, quieto["col"] * cw:(quieto["col"] + 1) * cw])
    hoja[fila * ch:(fila + 1) * ch, :] = 0   # la fila entera en blanco: puede tener menos dibujos que antes
    for i, n in enumerate(lista):
        dibujo = np.array(Image.open(f"{FUENTE}/walk/{origen}-{n}.png").convert("RGBA"))
        casilla = limpiar_pies(colocar(dibujo, colores), n in zapatos_negros.get(origen, []))
        casilla = a_ras(casilla, pies)
        if origen != direccion:
            casilla = casilla[:, ::-1]
        hoja[fila * ch:(fila + 1) * ch, i * cw:(i + 1) * cw] = casilla
    info["frames"] = len(lista)
    print(f"{direccion}: {len(lista)} dibujos ({', '.join(map(str, lista))}{', en espejo' if origen != direccion else ''})")

Image.fromarray(hoja).save(f"{HOJA}.png", optimize=True)
json.dump(meta, open(f"{HOJA}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)
subprocess.run([sys.executable, "tools/hacer_frames.py", HOJA], check=True)
