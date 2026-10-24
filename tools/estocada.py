# La estocada sin echarse atrás. PixelLab dibujó el ataque de la lanza de lado moviendo a Johnny hacia atrás: la cabeza
# y los pies retroceden hasta 17 píxeles mientras la punta de la lanza casi no se mueve. En el juego Johnny no se mueve
# de su sitio, así que se veía cómo retrocedía en vez de clavar. Esto recoloca cada dibujo para que la cabeza (el centro
# del pañuelo rojo) se quede donde está en la guardia (el dibujo 0): así lo que avanza es la lanza.
#
# Lee los dibujos de PixelLab, tal cual, de assets/sources/<sprite>/ataque-pixellab/ y escribe los recolocados en
# assets/sources/<sprite>/ataque/, que es de donde monta la hoja tools/arma.py del juego JS. Solo se mueven de lado (no de
# arriba abajo) y solo en las direcciones que diga arma.json ("ataque" → "quieto"); las demás se copian tal cual. A las
# que se mueven se les deja un margen de MARGEN píxeles a cada lado, para que quepa la lanza al avanzar.
#   py tools/estocada.py conserje-48-lanza
# Después: la hoja (py C:/Users/angel/Projects/game/tools/arma.py conserje-48-lanza, desde esta carpeta), su .tres
# (py tools/hacer_frames.py assets/sprites/conserje-48-lanza) y las skins (py tools/cara.py <skin> lanza, con las 4).
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
DIRECCIONES = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
MARGEN = 24


def panuelo_x(im):
    """Dónde está la cabeza, de lado: el centro del pañuelo rojo (en píxeles del dibujo)."""
    px = im.load()
    xs = [x for y in range(im.height) for x in range(im.width)
          if px[x, y][3] > 128 and px[x, y][0] > 150 and px[x, y][1] < 70 and px[x, y][2] < 70]
    assert xs, "no encuentro el pañuelo"
    return round(sum(xs) / len(xs))


sprite = sys.argv[1]
fuente = RAIZ / "assets" / "sources" / sprite
quietos = json.load(open(fuente / "arma.json", encoding="utf-8"))["ataque"]["quieto"]
origen, destino = fuente / "ataque-pixellab", fuente / "ataque"
for d in DIRECCIONES:
    dibujos = sorted(origen.glob(f"{d}-*.png"), key=lambda p: int(p.stem.rsplit("-", 1)[1]))
    if d not in quietos:
        for p in dibujos:
            shutil.copyfile(p, destino / p.name)
        continue
    guardia = panuelo_x(Image.open(dibujos[0]).convert("RGBA"))
    movidos = []
    for p in dibujos:
        im = Image.open(p).convert("RGBA")
        dx = guardia - panuelo_x(im)
        nuevo = Image.new("RGBA", (im.width + 2 * MARGEN, im.height), (0, 0, 0, 0))
        nuevo.paste(im, (MARGEN + dx, 0), im)
        nuevo.save(destino / p.name)
        movidos.append(dx)
    print(f"{d:11s} movidos de lado {movidos}")
