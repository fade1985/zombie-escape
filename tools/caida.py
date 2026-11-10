# La hoja del tropiezo de Johnny (johnny.gd, caer): se cae de espaldas, se queda tumbado y se levanta, sin el arma.
# Los dibujos son de PixelLab, con las plantillas "falling-back-death" (7 fotogramas, animación "caer") y "getting-up"
# (5, "levantarse") del Johnny sin arma (conserje-48; assets/pixellab.json), en las 8 direcciones, bajados a
# assets/sources/conserje-48/caer/ y levantarse/ (<dirección>-<n>.png, 48x48).
#
# PixelLab no deja a Johnny siempre en el mismo sitio del lienzo, así que aquí se colocan:
#   - caer: movido para que el primer fotograma (de pie) tenga los pies en el pivote de la hoja (el centro de abajo de
#     lo que se ve, como los pies de las demás hojas) y, poco a poco, para que el último (tumbado) quede en el suelo,
#     encima de su sombra (PixelLab lo dibuja flotando, más arriba que los pies: TUMBADO);
#   - levantarse: movido poco a poco, para que el primero (aún tumbado) quede donde acabó caer y el último (ya de pie)
#     con los pies en el pivote. Así no da saltos al pasar de una a otra ni al volver a su hoja de siempre.
# Saca assets/sprites/conserje-48-caida.png y .json (una fila por dirección: caer y luego levantarse) y, con
# tools/hacer_frames.py, su .tres (animaciones caer_<dir> y levantarse_<dir>). Las de las skins, después, con
# tools/caida_skins.py (tools/cara.py no sirve aquí: busca la cabeza derecha, y al caer va girada).
#   py tools/caida.py
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
FUENTE = RAIZ / "assets" / "sources" / "conserje-48"
SALIDA = RAIZ / "assets" / "sprites" / "conserje-48-caida"
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
CELDA = 64
PIVOTE = (32, 56)   # los pies, en la casilla
TUMBADO = 6         # tumbado, lo de más abajo del cuerpo queda estos píxeles por debajo de los pies (sobre la sombra)
CAER, LEVANTARSE = 7, 5
# Los dibujos de levantarse de cada dirección ("levantarse" o "caer", y cuál), siempre LEVANTARSE. Por defecto, los 5
# de PixelLab. Al sur, al noreste y al norte, su primer dibujo de levantarse ya está agachado y daba un salto desde
# tumbado: empiezan con uno de caer (sentado o boca arriba), como si se cayera al revés, y se quita uno repetido. Al
# sur, el último de levantarse sale de espaldas: fuera (después viene el reposo de siempre, de frente).
LEVANTARSE_DE = {
    "south": [("caer", 5), ("levantarse", 0), ("levantarse", 1), ("levantarse", 2), ("levantarse", 3)],
    "north-east": [("caer", 5), ("levantarse", 0), ("levantarse", 2), ("levantarse", 3), ("levantarse", 4)],
    "north": [("caer", 5), ("levantarse", 0), ("levantarse", 2), ("levantarse", 3), ("levantarse", 4)],
}


def dibujo(anim: str, d: str, i: int) -> Image.Image:
    return Image.open(FUENTE / anim / f"{d}-{i}.png").convert("RGBA")


def pies(im: Image.Image) -> tuple[float, float]:
    """El centro de abajo de lo que se ve"""
    x0, _, x1, y1 = im.getbbox()
    return (x0 + x1) / 2.0, float(y1)


hoja = Image.new("RGBA", (CELDA * (CAER + LEVANTARSE), CELDA * len(DIRS)))
for fila, d in enumerate(DIRS):
    # caer: movido para que de pie tenga los pies en el pivote
    px, py = pies(dibujo("caer", d, 0))
    mover_caer = (round(PIVOTE[0] - px), round(PIVOTE[1] - py))
    tx, ty = pies(dibujo("caer", d, CAER - 1))
    baja = PIVOTE[1] + TUMBADO - (ty + mover_caer[1])   # lo que hay que bajar lo tumbado hasta el suelo
    def en_caer(i):   # dónde va el dibujo i de caer
        return (mover_caer[0], mover_caer[1] + round(baja * i / (CAER - 1)))
    for i in range(CAER):
        m = en_caer(i)
        hoja.alpha_composite(dibujo("caer", d, i), (i * CELDA + m[0], fila * CELDA + m[1]))
    # levantarse: los de caer, donde estaban al caer; los de PixelLab, el primero donde acabó caer (el centro de
    # abajo de lo tumbado), el último de pie en el pivote y los de en medio, poco a poco
    sec = LEVANTARSE_DE.get(d, [("levantarse", i) for i in range(LEVANTARSE)])
    assert len(sec) == LEVANTARSE   # (johnny.gd: LEVANTARSE, lo que dura levantarse)
    suyos = [i for a, i in sec if a == "levantarse"]
    ax, ay = pies(dibujo("levantarse", d, suyos[0]))
    desde = (tx + mover_caer[0] - ax, ty + mover_caer[1] + baja - ay)
    fx, fy = pies(dibujo("levantarse", d, suyos[-1]))
    hasta = (PIVOTE[0] - fx, PIVOTE[1] - fy)
    for col, (anim, i) in enumerate(sec):
        if anim == "caer":
            m = en_caer(i)
        else:
            k = suyos.index(i) / (len(suyos) - 1)
            m = (round(desde[0] + (hasta[0] - desde[0]) * k), round(desde[1] + (hasta[1] - desde[1]) * k))
        hoja.alpha_composite(dibujo(anim, d, i), ((CAER + col) * CELDA + m[0], fila * CELDA + m[1]))
    print(f"{d}: caer movido {mover_caer} y baja {baja}; levantarse de {tuple(round(v) for v in desde)} a {tuple(round(v) for v in hasta)}")

hoja.save(SALIDA.with_suffix(".png"))
meta = {"cell": [CELDA, CELDA], "pivot": list(PIVOTE), "anims": {
    "fall": {"fps": 14, "loop": False, "dirs": {d: {"row": r, "col": 0, "frames": CAER} for r, d in enumerate(DIRS)}},
    "getup": {"fps": 12, "loop": False, "dirs": {d: {"row": r, "col": CAER, "frames": LEVANTARSE} for r, d in enumerate(DIRS)}},
}}
SALIDA.with_suffix(".json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
subprocess.run([sys.executable, str(RAIZ / "tools" / "hacer_frames.py"), "assets/sprites/conserje-48-caida"], cwd=RAIZ, check=True)
