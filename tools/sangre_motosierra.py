"""Mancha de sangre la mitad delantera de la espada de la motosierra en todos los dibujos de Johnny con ella.

  py tools/sangre_motosierra.py            pinta todo
  py tools/sangre_motosierra.py muestra    además guarda capturas/sangre-motosierra.png (antes y después)

Lee los dibujos tal cual salen de PixelLab de assets/sources/conserje-48-motosierra/sin_sangre/ (rotations, walk y
ataque) y escribe los manchados en rotations/, walk/ y ataque/, que son los que monta en la hoja tools/arma.py.

Cómo encuentra la espada: es el trozo gris más grande del dibujo (píxeles casi sin color, ni muy oscuros, que son el
contorno, ni muy claros, que son la estela del golpe). Su base es el píxel gris más cercano al centro del cuerpo de
Johnny, y su punta el más lejano. Se mancha a partir del 40 % del largo y más cuanto más cerca de la punta.
Las manchas no salen al azar en cada dibujo: dependen de la distancia a la base y a la raya del medio de la espada,
así que al andar o al girarla la sangre se queda en el mismo sitio de la espada y no parpadea.
"""
import math, os, sys
from PIL import Image

SRC = 'assets/sources/conserje-48-motosierra'
# la sangre: oscura, la de siempre (partida.gd, SANGRE) y una algo más viva para los brillos de la cadena (sin blancos)
OSCURA, MEDIA, VIVA = (94, 21, 18, 255), (122, 31, 26, 255), (160, 44, 34, 255)
DESDE = 0.40   # desde qué parte del largo de la espada empieza a mancharse


def gris(p):
    r, g, b, a = p
    return a > 0 and max(r, g, b) - min(r, g, b) < 30 and 48 <= (r + g + b) / 3 <= 190


def trozos(px, w, h):
    """Los trozos de píxeles grises que se tocan (también en diagonal)."""
    visto, salen = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in visto or not gris(px[x, y]):
                continue
            pila, trozo = [(x, y)], []
            visto.add((x, y))
            while pila:
                cx, cy = pila.pop()
                trozo.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visto and gris(px[nx, ny]):
                            visto.add((nx, ny))
                            pila.append((nx, ny))
            salen.append(trozo)
    return salen


def hash2(a, b):
    return ((a * 73856093) ^ (b * 19349663)) % 1000 / 1000.0


def manchar(im):
    im = im.convert('RGBA')
    w, h = im.size
    px = im.load()
    ts = trozos(px, w, h)
    if not ts:
        return im, 0
    espada = max(ts, key=len)
    if len(espada) < 12:
        return im, 0
    dentro = set(espada)
    cuerpo = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] and (x, y) not in dentro]
    cx = sum(p[0] for p in cuerpo) / len(cuerpo)
    cy = sum(p[1] for p in cuerpo) / len(cuerpo)
    base = min(espada, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
    punta = max(espada, key=lambda p: (p[0] - base[0]) ** 2 + (p[1] - base[1]) ** 2)
    largo = math.dist(base, punta)
    if largo < 8:
        return im, 0
    ux, uy = (punta[0] - base[0]) / largo, (punta[1] - base[1]) / largo
    n = 0
    for (x, y) in espada:
        d = (x - base[0]) * ux + (y - base[1]) * uy      # a lo largo de la espada
        lado = -(x - base[0]) * uy + (y - base[1]) * ux  # a un lado y a otro de la raya del medio
        f = d / largo
        if f < DESDE:
            continue
        cuanto = 0.25 + 0.75 * (f - DESDE) / (1 - DESDE)   # más cerca de la punta, más sangre
        if hash2(int(d // 2), int(lado // 2) + 50) > cuanto:
            continue
        r, g, b, a = px[x, y]
        v = (r + g + b) / 3
        px[x, y] = OSCURA if v < 95 else (MEDIA if v < 145 else VIVA)
        n += 1
    return im, n


def main():
    hechos = 0
    for carpeta in ('rotations', 'walk', 'ataque'):
        os.makedirs(f'{SRC}/{carpeta}', exist_ok=True)
        for nombre in sorted(os.listdir(f'{SRC}/sin_sangre/{carpeta}')):
            if not nombre.endswith('.png'):
                continue
            im, n = manchar(Image.open(f'{SRC}/sin_sangre/{carpeta}/{nombre}'))
            im.save(f'{SRC}/{carpeta}/{nombre}')
            hechos += 1
    print(f'{hechos} dibujos manchados')
    if 'muestra' in sys.argv:
        dirs = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
        filas = []
        for carpeta in ('sin_sangre/rotations', 'rotations'):
            filas.append([Image.open(f'{SRC}/{carpeta}/{d}.png').convert('RGBA') for d in dirs])
        Z = 4
        hoja = Image.new('RGBA', (64 * 8 * Z, 64 * 2 * Z), (60, 60, 70, 255))
        for r, fila in enumerate(filas):
            for i, im in enumerate(fila):
                hoja.alpha_composite(im.resize((64 * Z, 64 * Z), Image.NEAREST), (i * 64 * Z, r * 64 * Z))
        os.makedirs('capturas', exist_ok=True)
        hoja.save('capturas/sangre-motosierra.png')
        print('capturas/sangre-motosierra.png')


main()
