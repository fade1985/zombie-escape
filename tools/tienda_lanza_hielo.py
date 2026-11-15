# Los dibujos del lanza hielo en la tienda de armas (assets/ui/tienda: lanza_hielo.png, de 48, para la casilla, y
# lanza_hielo-grande.png, en horizontal, para la ficha): los del lanzallamas, con el bidón y el grifo rojos en azul hielo
# y, en vez de la llama de la punta, una bocanada de niebla helada con un par de cristalitos.
#   1. Los rojos (los del lanzallamas son de GPT pasados a píxeles: muchos rojos casi iguales) se miran por su tono:
#      cada píxel rojo pasa al azul de la rampa del lanza hielo que tenga su misma luz.
#   2. La llama: los píxeles cálidos (rojos, naranjas, amarillos) de la zona de la punta ("LLAMA", por dibujo) se borran.
#   3. La niebla: una bocanada redonda pegada a la boca del tubo (el píxel de metal más a la punta), blanca en el centro,
#      celeste y azul por fuera, con borde oscuro, y dos cristalitos en cruz delante.
#   py tools/tienda_lanza_hielo.py
import colorsys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
TIENDA = RAIZ / "assets" / "ui" / "tienda"
# la rampa del hielo (la de las bombonas de Johnny, tools/hoja_lanza_hielo.py), de oscuro a claro
RAMPA = [(18, 34, 66), (34, 62, 112), (58, 118, 182), (102, 178, 228), (158, 222, 248), (236, 250, 255)]
BLANCO = (255, 255, 255)
BORDE = (3, 3, 6)
# por dibujo: la caja de la llama (x0, y0, x1, y1), hacia dónde apunta el tubo y el radio de la bocanada
DIBUJOS = {
    "": {"llama": (30, 0, 48, 18), "hacia": (1, -1), "radio": 4.5},
    "-grande": {"llama": (76, 0, 96, 48), "hacia": (1, 0), "radio": 6.5},
}


def tono(c):
    h, l, s = colorsys.rgb_to_hls(c[0] / 255, c[1] / 255, c[2] / 255)
    return h * 360, l, s


def calido(c):
    h, l, s = tono(c)
    return s > 0.45 and l > 0.12 and (h < 70 or h > 330)


def hacer(cual, cfg):
    im = Image.open(TIENDA / f"lanzallamas{cual}.png").convert("RGBA")
    px = im.load()
    w, h = im.size
    x0, y0, x1, y1 = cfg["llama"]
    # 2. fuera la llama
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] and x0 <= x < x1 and y0 <= y < y1 and calido(c):
                px[x, y] = (0, 0, 0, 0)
    # (y lo oscuro que quede suelto en el aire, el borde de la llama: sin vecinos que no sean borde)
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] and x0 <= x < x1 and y0 <= y < y1 and max(c[:3]) < 20:
                vecinos = [px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 <= x + dx < w and 0 <= y + dy < h]
                if not any(v[3] and max(v[:3]) >= 20 for v in vecinos):
                    px[x, y] = (0, 0, 0, 0)
    # 1. los rojos, a azules por su luz
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] and calido(c):
                _, l, _ = tono(c)
                i = min(len(RAMPA) - 1, max(0, int(l * 1.25 * len(RAMPA))))
                px[x, y] = RAMPA[i] + (c[3],)
    # 3. la boca: el píxel de metal (gris, no borde) que más sale hacia donde apunta, dentro de la caja de la llama o justo antes
    hx, hy = cfg["hacia"]
    mejor = None
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] and max(c[:3]) >= 40 and tono(c)[2] < 0.3 and x >= x0 - 12:
                v = x * hx + y * hy
                if mejor is None or v > mejor[0]:
                    mejor = (v, x, y)
    _, bx, by = mejor
    r = cfg["radio"]
    cx, cy = bx + hx * (r + 0.5), by + hy * (r + 0.5)
    solidos = []
    for y in range(h):
        for x in range(w):
            # una bocanada algo achatada y con bultos (tres círculos)
            d = min(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / r,
                    ((x - cx - hx * r * 0.7 + hy * r * 0.4) ** 2 + (y - cy - hy * r * 0.7 - hx * r * 0.4) ** 2) ** 0.5 / (r * 0.7),
                    ((x - cx - hx * r * 0.5 - hy * r * 0.5) ** 2 + (y - cy - hy * r * 0.5 + hx * r * 0.5) ** 2) ** 0.5 / (r * 0.6))
            if d <= 1.0 and px[x, y][3] == 0:
                luz = (x - cx) * -0.5 + (y - cy) * -0.5   # con luz de arriba a la izquierda
                k = d - luz / (r * 3)
                c = BLANCO if k < 0.35 else (RAMPA[5] if k < 0.6 else (RAMPA[4] if k < 0.85 else RAMPA[3]))
                px[x, y] = c + (255,)
                solidos.append((x, y))
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                px[nx, ny] = RAMPA[1] + (255,)
    # los cristalitos: dos crucecitas delante de la bocanada
    for k, (ax, ay) in enumerate(((r * 2.2, -r * 0.9), (r * 2.6, r * 0.8))):
        qx = round(cx + hx * ax - hy * ay)
        qy = round(cy + hy * ax + hx * ay)
        brazo = 1 if k else 2 if r > 5 else 1
        for dx, dy in [(0, 0)] + [(s * i, 0) for s in (1, -1) for i in range(1, brazo + 1)] + [(0, s * i) for s in (1, -1) for i in range(1, brazo + 1)]:
            if 0 <= qx + dx < w and 0 <= qy + dy < h:
                px[qx + dx, qy + dy] = (BLANCO if (dx, dy) == (0, 0) else RAMPA[4]) + (255,)
    salida = TIENDA / f"lanza_hielo{cual}.png"
    im.save(salida)
    print(salida, "boca", (bx, by))


for cual, cfg in DIBUJOS.items():
    hacer(cual, cfg)
