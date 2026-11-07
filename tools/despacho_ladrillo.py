# El suelo y la pared del despacho de la sala de mantenimiento, como los de la foto del dueño (7 nov): pared de ladrillo
# rojo visto y tarima de madera envejecida. Salen de dos imágenes de GPT (assets/sources/despacho-pared-gpt.webp y
# despacho-suelo-gpt.webp), que ya vienen repetidas varias veces, como las del taller (tools/taller_vinilo.py).
#   pared → assets/sprites/pared-despacho.png  (48 de alto, como las demás paredes; empalma a izquierda y derecha)
#   suelo → assets/sprites/suelo-despacho.png  (empalma por los cuatro lados)
# La pared no se reduce sin más (las juntas, más finas que un píxel, saldrían a trozos): se mide cada ladrillo de la
# imagen (dónde empieza, dónde acaba y su color) y se vuelve a dibujar limpio, 3 píxeles de ladrillo y 1 de junta.
# (Antes salían de tools/sala_sin_sangre.py, de los de los pisos sin sangre: ya no.)
# Uso: py tools/despacho_ladrillo.py  (y luego Godot --headless --path . --import)
import random
from PIL import Image

FUENTES = "assets/sources/"
CARPETA = "assets/sprites/"


# Cada cuántos píxeles se repite la imagen a lo ancho (o a lo alto): el desplazamiento con el que más se parece a sí misma
def periodo(im, desde, hasta, vertical=False):
    g = im.convert("L")
    if vertical:
        g = g.transpose(Image.Transpose.TRANSPOSE)
    w, h = g.size
    p = g.load()
    mejor, cual = None, desde
    for d in range(desde, hasta):
        dif = 0
        for y in range(0, h, 7):
            for x in range(0, w - d, 5):
                dif += abs(p[x, y] - p[x + d, y])
        dif /= (w - d)
        if mejor is None or dif < mejor:
            mejor, cual = dif, d
    return cual


def es_junta(c):
    return sum(c) / 3 > 170 and max(c) - min(c) < 70   # el mortero: claro y casi sin color


# --- La pared ---
pared = Image.open(FUENTES + "despacho-pared-gpt.webp").convert("RGB")
W, H = pared.size
px = pared.load()
# las filas de ladrillos: dónde caen las juntas de entre filas (las filas claras de arriba abajo)
claras = [y for y in range(H) if sum(sum(px[x, y]) for x in range(0, W, 4)) / (W // 4) / 3 > 170]
juntas = []
for y in claras:
    if not juntas or y > juntas[-1][1] + 1:
        juntas.append([y, y])
    else:
        juntas[-1][1] = y
filas = [(juntas[i][1] + 1, juntas[i + 1][0]) for i in range(len(juntas) - 1)]   # (arriba, abajo) de cada fila de ladrillos
paso = (filas[-1][0] - filas[0][0]) / (len(filas) - 1)   # lo que mide una fila con su junta
ancho_rep = periodo(pared, W // 4, W * 3 // 4)           # cada cuánto se repite a lo ancho
FILAS = 12                                               # 48 de alto: 12 filas de 4 píxeles (3 de ladrillo y 1 de junta)
ANCHO = round(ancho_rep * 4 / paso)                      # el trozo que se repite, en píxeles del juego
escala = ancho_rep / ANCHO
print("pared: filas cada %.1f, se repite cada %d → %d píxeles de ancho" % (paso, ancho_rep, ANCHO))
mortero = (196, 180, 156)
trozo = Image.new("RGB", (ANCHO, FILAS * 4), mortero)
for f in range(FILAS):
    arriba, abajo = filas[f + 1]   # (la primera fila puede venir cortada por el borde)
    y = (arriba + abajo) // 2
    # los ladrillos de esta fila, de dos repeticiones seguidas (así el que cruza el borde sale entero)
    x = 0
    while x < 2 * ancho_rep and x < W:
        if es_junta(px[x, y]):
            x += 1
            continue
        x0 = x
        suma = [0, 0, 0]
        while x < W and not es_junta(px[x, y]):
            for i in range(3):
                suma[i] += px[x, y][i]
            x += 1
        n = x - x0
        if n < 8:
            continue
        color = tuple(v // n for v in suma)
        a, b = round(x0 / escala), round(x / escala)   # del ladrillo, sin la junta de su derecha
        for i in range(a, b - 1 if b - a > 1 else b):
            for j in range(3):
                trozo.putpixel((i % ANCHO, f * 4 + j), color)
# Más real (los colores planos y vivos de GPT parecían de dibujo animado, 7 nov): cada ladrillo, más apagado y oscuro,
# tirando a marrón como el de la foto; cada píxel con su grano (y alguna picadura más oscura); la fila de arriba de cada
# ladrillo, algo más clara, y la de abajo, más oscura; el mortero, gris arena sucio con su grano y en sombra bajo el ladrillo
azar = random.Random(7)
def apagado(c):
    gris = sum(c) / 3
    c = [v * 0.62 + gris * 0.38 for v in c]           # menos color
    c = [c[0] * 0.80, c[1] * 0.74, c[2] * 0.70]       # más oscuro y más marrón
    return c
for x in range(ANCHO):
    for f in range(FILAS):
        for j in range(4):
            c = trozo.getpixel((x, f * 4 + j))
            if c == mortero:
                k = azar.uniform(0.86, 1.0) * (0.84 if j == 3 else 1.0)
                trozo.putpixel((x, f * 4 + j), tuple(int(v * k) for v in (150, 138, 122)))
                continue
            k = azar.uniform(0.90, 1.06) * (0.78 if azar.random() < 0.08 else 1.0) * {0: 1.08, 1: 1.0, 2: 0.84}[j]
            trozo.putpixel((x, f * 4 + j), tuple(max(0, min(255, int(v * k))) for v in apagado(c)))
veces = max(1, round(480 / ANCHO))
tira = Image.new("RGB", (ANCHO * veces, FILAS * 4))
for i in range(veces):
    tira.paste(trozo, (i * ANCHO, 0))
tira.save(CARPETA + "pared-despacho.png")
print("pared-despacho.png:", tira.size)

# --- El suelo ---
suelo = Image.open(FUENTES + "despacho-suelo-gpt.webp").convert("RGB")
w, h = suelo.size
rx = periodo(suelo, w // 3, w * 2 // 3)
ry = periodo(suelo, h // 3, h * 2 // 3, True)
LADO = 128
tarima = suelo.crop((0, 0, rx, ry)).resize((LADO, LADO), Image.Resampling.BOX)
tarima = tarima.quantize(colors=14, method=Image.Quantize.MEDIANCUT).convert("RGB")
tarima.save(CARPETA + "suelo-despacho.png")
print("suelo: se repite cada %d x %d → suelo-despacho.png %dx%d" % (rx, ry, LADO, LADO))
