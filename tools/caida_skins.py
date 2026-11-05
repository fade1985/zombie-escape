# Las skins en la hoja del tropiezo de Johnny (conserje-48-caida, tools/caida.py). tools/cara.py pega la cabeza de la
# skin en las hojas de siempre buscándola derecha, pero al caerse y tumbado la cabeza va girada. Aquí, en cada dibujo:
#   1. Se busca dónde está la cabeza de siempre y cuánto está girada: se prueba la cabeza del dibujo quieto de esa
#      dirección (hasta la barbilla) girada de GIRO en GIRO grados, en cada sitio cerca del pañuelo, y se queda la que
#      más se parece (cuántos de sus píxeles caen sobre uno de color parecido). Da igual la skin: se busca una vez.
#   2. Se borra la cabeza de siempre (lo que tape la cabeza girada y sea de cabeza: pelo, pañuelo, piel, contorno) y lo
#      que sobre del pelo y del pañuelo justo alrededor, según la skin (como SOBRA en cara.py).
#   3. Se pega la cabeza de la skin (la de cara.py: cabeza_nueva) girada igual, con el mismo giro de píxeles.
# Saca assets/sprites/conserje-48-caida-<skin>.png y .tres. Y, con "muestra", capturas/captura-caida-<skin>.png: la
# fila de cada dirección antes y después, para revisarla.
#   py tools/caida_skins.py                 → todas las skins
#   py tools/caida_skins.py gloton muestra  → solo esa, con la muestra
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cara  # noqa: E402

RAIZ = cara.RAIZ
SPRITES = cara.SPRITES
NOMBRE = "conserje-48-caida"
SKINS = ["portero", "gloton", "gymbro", "bombero", "salas", "cocinero", "antidisturbios", "modista", "mascota", "gerente",
         "directora", "informatico", "presentador", "becario", "sujeto"]
GIRO = 15          # de cuántos en cuántos grados se prueba
CERCA = 9          # hasta cuántos píxeles del pañuelo se busca el centro de la cabeza
PARECIDO = 70      # dos colores se parecen si la suma de sus diferencias es menor que esto
ALREDEDOR = 2      # lo que se mira alrededor de la cabeza pegada para quitar lo que sobre del pelo y del pañuelo


def quietos_de_siempre():
    base = cara.cargar(SPRITES / "conserje-48.png")
    datos = json.load(open(SPRITES / "conserje-48.json", encoding="utf-8"))
    q = {}
    for direc, v in datos["anims"]["still"]["dirs"].items():
        c, f = v.get("col", 0), v["row"]
        q[direc] = base.crop((c * 48, f * 48, c * 48 + 48, f * 48 + 48))
    return q


def girar(puntos: np.ndarray, centro: np.ndarray, grados: float) -> np.ndarray:
    a = math.radians(grados)
    r = np.array([[math.cos(a), -math.sin(a)], [math.sin(a), math.cos(a)]])
    return (puntos - centro) @ r.T


def buscar(celda: np.ndarray, cabeza: list, rojo_centro) -> tuple:
    """El mejor (giro, centro) de la cabeza de siempre en ese dibujo, y lo que se parece (0-1)."""
    pts = np.array([(x, y) for x, y, _ in cabeza], dtype=float)
    cols = np.array([c[:3] for _, _, c in cabeza], dtype=int)
    centro = pts.mean(axis=0)
    # por dónde buscar: cerca del pañuelo de este dibujo (si no se ve, por todo el dibujo)
    rojos = np.argwhere(np.array([[cara.panuelo(tuple(celda[y, x])) for x in range(celda.shape[1])]
                                  for y in range(celda.shape[0])]))
    if len(rojos):
        ry, rx = rojos.mean(axis=0)
        sitios = [(rx + dx, ry + dy) for dx in range(-CERCA, CERCA + 1) for dy in range(-CERCA, CERCA + 1)]
    else:
        sitios = [(x, y) for x in range(4, celda.shape[1] - 4) for y in range(4, celda.shape[0] - 4)]
    mejor = (0.0, 0.0, (0.0, 0.0))
    alto, ancho = celda.shape[:2]
    for g in range(0, 360, GIRO):
        rel = girar(pts, centro, g)
        # (la cabeza se coloca con el pañuelo de la plantilla cerca del de este dibujo: se prueba su centro alrededor)
        for sx, sy in sitios:
            xy = np.rint(rel + (sx, sy)).astype(int)
            dentro = (xy[:, 0] >= 0) & (xy[:, 0] < ancho) & (xy[:, 1] >= 0) & (xy[:, 1] < alto)
            if dentro.sum() < len(xy) * 0.8:
                continue
            p = celda[xy[dentro, 1], xy[dentro, 0]]
            bien = (p[:, 3] > 0) & (np.abs(p[:, :3].astype(int) - cols[dentro]).sum(axis=1) < PARECIDO)
            nota = bien.sum() / len(xy)
            if nota > mejor[0]:
                mejor = (nota, g, (sx, sy))
    return mejor


def pegar(celda: Image.Image, giro: float, sitio, quieto: Image.Image, nueva: dict, sobra: str) -> None:
    """Borra la cabeza de siempre de ese dibujo (girada "giro", con su centro en "sitio") y pega la nueva igual."""
    px = celda.load()
    w, h = celda.size
    zona = list(nueva.keys())
    # (el mismo centro que en buscar(): el de los píxeles de la cabeza de siempre)
    centro = np.array([(x, y) for x, y, _ in cara.plantilla(quieto)[0]], dtype=float).mean(axis=0)
    # para cada píxel del dibujo, de dónde viene en la cabeza derecha (girando al revés): así no quedan huecos
    a = math.radians(-giro)
    cos, sin = math.cos(a), math.sin(a)
    zona_set = set(zona)
    quieto_px = quieto.load()
    tapado = set()
    for y in range(h):
        for x in range(w):
            dx, dy = x - sitio[0], y - sitio[1]
            ox = round(dx * cos - dy * sin + centro[0])
            oy = round(dx * sin + dy * cos + centro[1])
            if (ox, oy) not in zona_set:
                continue
            tapado.add((x, y))
            c = px[x, y]
            nuevo = nueva[(ox, oy)]
            if nuevo[3] > 0:
                px[x, y] = nuevo
            elif c[3] > 0 and (cara.de_cabeza(c) or quieto_px[ox, oy][3] > 0):
                px[x, y] = (0, 0, 0, 0)   # lo de la cabeza de siempre que la nueva no tiene
    # lo que sobre del pelo (y del pañuelo, si la skin no lo lleva) justo alrededor
    if sobra in cara.QUITAN:
        for (x, y) in list(tapado):
            for vx in range(-ALREDEDOR, ALREDEDOR + 1):
                for vy in range(-ALREDEDOR, ALREDEDOR + 1):
                    X, Y = x + vx, y + vy
                    if (X, Y) in tapado or not (0 <= X < w and 0 <= Y < h):
                        continue
                    c = px[X, Y]
                    if cara.pelo(c) or (sobra != "calvo" and cara.panuelo(c)):
                        px[X, Y] = (0, 0, 0, 0)


def main():
    elegidas = [s for s in SKINS if s in sys.argv] or SKINS
    muestra = "muestra" in sys.argv
    datos = json.load(open(SPRITES / f"{NOMBRE}.json", encoding="utf-8"))
    cw, ch = datos["cell"]
    hoja = cara.cargar(SPRITES / f"{NOMBRE}.png")
    quietos = quietos_de_siempre()
    # 1. dónde está la cabeza en cada dibujo (una vez para todas las skins)
    sitios = {}
    for anim, direc, fila, col in cara.fotogramas(datos):
        celda = np.array(hoja.crop((col * cw, fila * ch, col * cw + cw, fila * ch + ch)))
        cabeza, rojo = cara.plantilla(quietos[direc])
        nota, giro, sitio = buscar(celda, cabeza, rojo)
        sitios[(fila, col)] = (giro, sitio, direc)
        print(f"{anim} {direc} {col}: giro {giro}°, en {tuple(round(v) for v in sitio)}, se parece {nota:.2f}")
    for skin in elegidas:
        fuente = RAIZ / "assets" / "sources" / f"skin-{skin}" / "quietos"
        nuevas = {d: cara.cabeza_nueva(quietos[d], cara.cargar(fuente / f"{d}.png"))[0] for d in quietos}
        sobra = cara.SOBRA.get(skin, "tenir")
        nueva_hoja = hoja.copy()
        for (fila, col), (giro, sitio, direc) in sitios.items():
            celda = nueva_hoja.crop((col * cw, fila * ch, col * cw + cw, fila * ch + ch))
            pegar(celda, giro, sitio, quietos[direc], nuevas[direc], sobra)
            nueva_hoja.paste(celda, (col * cw, fila * ch))
        nueva_hoja.save(SPRITES / f"{NOMBRE}-{skin}.png", optimize=True)
        tres = (SPRITES / f"{NOMBRE}.tres").read_text(encoding="utf-8")
        tres = tres.replace(f"res://assets/sprites/{NOMBRE}.png", f"res://assets/sprites/{NOMBRE}-{skin}.png")
        (SPRITES / f"{NOMBRE}-{skin}.tres").write_text(tres, encoding="utf-8", newline="\n")
        print(f"{NOMBRE}-{skin}: hecha")
        if muestra:
            fondo = Image.new("RGBA", (hoja.width, hoja.height * 2), (60, 60, 70, 255))
            fondo.alpha_composite(hoja, (0, 0))
            fondo.alpha_composite(nueva_hoja, (0, hoja.height))
            (RAIZ / "capturas").mkdir(exist_ok=True)
            fondo.resize((fondo.width * 2, fondo.height * 2), Image.NEAREST).save(RAIZ / "capturas" / f"captura-caida-{skin}.png")


if __name__ == "__main__":
    main()
