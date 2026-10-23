"""Iguala el ritmo del paso de Johnny en unas direcciones, sin tocar los dibujos de la hoja.

  py tools/ritmo_andar.py conserje-48-pistola south north

PixelLab no reparte bien los dibujos del paso: entre unos casi no cambia nada y entre otros las piernas pegan un
salto, y al andar se nota como una cojera. Aquí cada dibujo dura según cuánto cambian las piernas hasta el
siguiente (lo mismo que hace tools/andar_arma.py con "ritmo_parejo", pero para las hojas que no se rehacen desde
PixelLab): entre 0,6 y 1,4 veces lo normal, y entre todos suman lo mismo, así que la vuelta entera dura igual y el
PASO de johnny.gd sigue valiendo (23 oct). Solo usa Pillow.

Apunta los "durations" en assets/sprites/<arma>.json (de ahí los coge tools/hacer_frames.py) y en el .tres.
"""
import json, re, sys
from PIL import Image, ImageChops

arma, direcciones = sys.argv[1], sys.argv[2:]
HOJA = f"assets/sprites/{arma}"
meta = json.load(open(f"{HOJA}.json", encoding="utf-8"))
hoja = Image.open(f"{HOJA}.png").convert("RGBA")
cw, ch = meta["cell"]
piernas = int(ch * 0.58)   # de esta fila para abajo, las piernas (56 de 96, como en andar_arma.py)


def cambio(a, b):
    """Cuántos píxeles de las piernas son distintos entre dos dibujos."""
    dif = ImageChops.difference(a, b).convert("L").point(lambda v: 255 if v else 0)
    return dif.histogram()[255]


for direccion in direcciones:
    info = meta["anims"]["walk"]["dirs"][direccion]
    fila, col, n = info["row"], info.get("col", 0), info["frames"]
    casillas = [hoja.crop(((col + k) * cw, fila * ch + piernas, (col + k + 1) * cw, (fila + 1) * ch)) for k in range(n)]
    cambios = [cambio(casillas[k], casillas[(k + 1) % n]) for k in range(n)]
    media = sum(cambios) / n
    d = [min(1.4, max(0.6, c / media)) for c in cambios]
    info["durations"] = [round(x * n / sum(d), 2) for x in d]
    print(f"{direccion}: {info['durations']}")

json.dump(meta, open(f"{HOJA}.json", "w", encoding="utf-8", newline="\n"), ensure_ascii=False, indent=2)

# En el .tres solo se cambian las duraciones de esas animaciones (sacarlo entero con tools/hacer_frames.py
# también metería animaciones que el juego no usa)
DIRS = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne",
        "north": "n", "north-west": "no", "west": "o", "south-west": "so"}
tres = open(f"{HOJA}.tres", encoding="utf-8").read()
for direccion in direcciones:
    durs = iter(meta["anims"]["walk"]["dirs"][direccion]["durations"])
    patron = re.compile(r'\{"frames": \[([^\]]*)\], "loop": \w+, "name": &"andar_%s"' % DIRS[direccion])
    m = patron.search(tres)
    nuevo = re.sub(r'"duration": [\d.]+', lambda _: f'"duration": {next(durs)}', m[1])
    tres = tres[:m.start(1)] + nuevo + tres[m.end(1):]
open(f"{HOJA}.tres", "w", encoding="utf-8", newline="\n").write(tres)
