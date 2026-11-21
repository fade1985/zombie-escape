# Limpia lo que dejó tools/gloton_sin_lengua.py en los fotogramas del golpe del latigazo del Glotón (5 a 8, las 8
# direcciones): al borrar las lenguas de PixelLab quedaron agujeros dentro de la boca (se veía el suelo a través),
# hilos oscuros de un píxel colgando de la boca y trocitos sueltos. Solo toca alrededor de la boca (BOCAS de
# gloton.gd, la de cada fotograma), salvo los trocitos sueltos, que se quitan estén donde estén:
#   1. los hilos: píxeles oscuros de uno o dos de ancho que no forman parte de nada más grueso;
#   2. los trocitos sueltos: grupos de menos de 120 píxeles que no tocan el cuerpo;
#   3. los agujeros de la boca: lo transparente que queda dentro de la silueta (cerrándola 3 píxeles y, en la boca
#      misma, 6), del oscuro de dentro de la boca.
# YA SE HA PASADO (21 nov): no volver a pasarlo con «guardar».
# Uso: py tools/gloton_restos.py [guardar] [vista.png]   (la vista: antes y después de cada fotograma, ×3)
import re, sys
from collections import deque
from PIL import Image

GUARDAR = len(sys.argv) > 1 and sys.argv[1] == "guardar"
VISTA = next((a for a in sys.argv[1:] if a.endswith(".png")), None)
DIRS = ["s", "se", "e", "ne", "n", "no", "o", "so"]
# Las de gloton.gd (en unidades, desde su centro; un píxel de la hoja son 2)
BOCAS = {
    "s": [(0, -28)] * 4,
    "se": [(31, -43), (34, -36), (28, -46), (24, -52)],
    "e": [(55, -39), (51, -33), (48, -53), (48, -60)],
    "ne": [(54, -56), (54, -56), (48, -56), (48, -63)],
    "n": [(0, -86)] * 4,
    "no": [(-62, -56), (-59, -56), (-52, -66), (-48, -70)],
    "o": [(-62, -40), (-59, -39), (-59, -59), (-56, -63)],
    "so": [(-49, -36), (-49, -49), (-42, -56), (-39, -63)],
}
DENTRO = (24, 10, 8)        # el oscuro de dentro de la boca
OSCURO = 75                 # hasta qué luminosidad es «oscuro» (hilos)
# Restos de lengua roja pegados al cuerpo, que no se van con lo anterior: (dirección, fotograma): caja (u0, v0, u1, v1)
ROJO = {("no", 8): (34, 69, 43, 78)}

tres = open("assets/sprites/jefe-gloton.tres", encoding="utf-8").read()
reg = {m[0]: tuple(map(int, m[1:])) for m in re.findall(
    r'id="(t\d+)"\]\natlas = ExtResource\("hoja"\)\nregion = Rect2\((\d+), (\d+), (\d+), (\d+)\)', tres)}
anims = {m[2]: re.findall(r'SubResource\("(t\d+)"\)', m[1]) for m in re.finditer(
    r'\{"frames": \[(.*?)\], "loop": \w+, "name": &"(\w+)"', tres)}
hoja = Image.open("assets/sprites/jefe-gloton.png").convert("RGBA")
vista = Image.new("RGBA", (129 * 3 * 8, 109 * 3 * 8), (40, 140, 60, 255)) if VISTA else None

V8 = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]


def limpiar(im, boca):
    w, h = im.size
    px = im.load()
    bu, bv = (boca[0] + 132) / 2, (boca[1] + 156) / 2
    def cerca(u, v):   # alrededor de la boca: 24 a cada lado, 18 por encima y 40 por debajo
        return abs(u - bu) <= 24 and -18 <= v - bv <= 40
    op = lambda u, v: 0 <= u < w and 0 <= v < h and px[u, v][3] > 0
    lum = lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
    cambios = 0
    # 1. hilos: lo oscuro que desaparece al «abrir» la silueta (comerle un píxel por todos lados y devolvérselo)
    for _ in range(2):
        nucleo = {(u, v) for u in range(w) for v in range(h) if op(u, v) and all(op(u + a, v + b) for a, b in V8)}
        queda = set(nucleo)
        for (u, v) in nucleo:
            for a, b in V8:
                queda.add((u + a, v + b))
        for u in range(w):
            for v in range(h):
                if op(u, v) and (u, v) not in queda and cerca(u, v) and lum(px[u, v]) < OSCURO:
                    px[u, v] = (0, 0, 0, 0)
                    cambios += 1
    # 2. trocitos sueltos (8 vecinos), menos de 120 píxeles
    vistos = set()
    for u in range(w):
        for v in range(h):
            if (u, v) in vistos or not op(u, v):
                continue
            grupo, q = [], deque([(u, v)])
            vistos.add((u, v))
            while q:
                a, b = q.popleft()
                grupo.append((a, b))
                for da, db in V8:
                    n = (a + da, b + db)
                    if n not in vistos and op(*n):
                        vistos.add(n)
                        q.append(n)
            if len(grupo) < 120:
                for p in grupo:
                    px[p] = (0, 0, 0, 0)
                cambios += len(grupo)
    # 3. agujeros de la boca: cerrar la silueta (engordarla R y adelgazarla R) y rellenar lo que entra. Alrededor
    #    3 píxeles; en la boca misma, 6 (por donde colgaba la lengua de PixelLab quedó un arco abierto hacia abajo)
    def cerrar(R, donde):
        nonlocal cambios
        disco = [(a, b) for a in range(-R, R + 1) for b in range(-R, R + 1) if a * a + b * b <= R * R + 1]
        gordo = set()
        for u in range(w):
            for v in range(h):
                if op(u, v):
                    for a, b in disco:
                        gordo.add((u + a, v + b))
        for u in range(w):
            for v in range(h):
                if not op(u, v) and donde(u, v) and all((u + a, v + b) in gordo for a, b in disco):
                    px[u, v] = DENTRO + (255,)
                    cambios += 1
    cerrar(3, cerca)
    cerrar(6, lambda u, v: abs(u - bu) <= 12 and -8 <= v - bv <= 16)
    return cambios


for fila, d in enumerate(DIRS):
    for col, f in enumerate(range(5, 9)):
        x, y, w, h = reg[anims["latigazo_" + d][f]]
        antes = hoja.crop((x, y, x + w, y + h))
        despues = antes.copy()
        n = limpiar(despues, BOCAS[d][f - 5])
        if (d, f) in ROJO:
            u0, v0, u1, v1 = ROJO[(d, f)]
            px = despues.load()
            for u in range(u0, u1):
                for v in range(v0, v1):
                    r, g, b, a = px[u, v]
                    if a and r >= g * 1.5 + 8 and r >= b * 1.4 + 8:
                        px[u, v] = (0, 0, 0, 0)
                        n += 1
        print(f"{d} f{f}: {n} píxeles")
        if GUARDAR:
            hoja.paste(despues, (x, y))
        if vista:
            vista.alpha_composite(antes.resize((w * 3, h * 3), Image.NEAREST), (col * 2 * w * 3, fila * h * 3))
            vista.alpha_composite(despues.resize((w * 3, h * 3), Image.NEAREST), ((col * 2 + 1) * w * 3, fila * h * 3))
if GUARDAR:
    hoja.save("assets/sprites/jefe-gloton.png")
    print("guardada assets/sprites/jefe-gloton.png")
if vista:
    vista.save(VISTA)
