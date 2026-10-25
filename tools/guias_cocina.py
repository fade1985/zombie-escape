"""Bocetos (guías) de los muebles de la cocina de los pisos (nevera, encimera y fogón), para pedírselos a PixelLab
rectos, de frente y con el mismo estilo.

La nevera que había salió girada en diagonal (se le veía el costado derecho), y la encimera y el fogón se rehicieron
después para que pegaran con la nueva. Lo mismo que tools/guias_limpieza.py (de tools/guias_centro.py salen la
perspectiva, los colores de la raya y del fondo azul y cómo se quita el fondo después): de arriba abajo, la tapa vista
desde arriba (con lo que hay encima: si la tapa es lisa, PixelLab la deja lisa) y el frente. Las tapas son más cortas
que el fondo del catálogo, como en la nevera de bebidas del centro comercial: así se ven de frente y solo un poco
desde arriba. La encimera y el fogón llevan la misma tapa y el mismo alto, para que queden a la par uno junto al otro.
  - nevera: una caja de cereales y una cesta encima; el congelador, la nevera, las asas, imanes y una nota
  - encimera: el fregadero con su grifo, una tabla de cortar con un cuchillo, un plato y una taza encima; cuatro
    puertas de armario con sus tiradores
  - fogón: cuatro fuegos de gas sobre la placa negra; los mandos y la puerta del horno con su cristal y su asa

  py tools/guias_cocina.py               → assets/sources/centro/guias/<nevera|encimera|fogon>.png
  py tools/guias_centro.py quita <png>…  quita el fondo azul de lo que devuelve PixelLab
  py tools/guias_cocina.py limpia <png>… después de quita: la sombra azulada que PixelLab pinta debajo y las gotas
                                         sueltas que quedan fuera del mueble
Se pasan al juego con py tools/importar.py (sus originales, en assets/sources/salas/cocina/).
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono, Tapa

BLANCO = (205, 205, 195)
ASA = (95, 95, 100)
SANGRE = (120, 25, 25, 255)
# archivo: (largo, el del catálogo, en unidades; tapa y alto del frente, en píxeles del juego)
T = {
    'nevera':   (62, 22, 46),
    'encimera': (158, 20, 22),
    'fogon':    (56, 20, 22),
}


def caja(dr, x0, y0, x1, y1, color):
    dr.rectangle((x0, y0, x1 - 1, y1 - 1), fill=color if len(color) == 4 else color + (255,), outline=RAYA)


def punto(dr, x, y, px, py, color):
    """Un píxel del juego en (px, py), contado desde (x, y)"""
    dr.rectangle((x + px * S, y + py * S, x + (px + 1) * S - 1, y + (py + 1) * S - 1), fill=color)


def nevera(dr, x, y, w, d, h):
    # la tapa, desde arriba: una caja de cereales (roja, con su franja amarilla) y una cesta de mimbre
    caja(dr, x, y, x + w, y + d, tono(BLANCO, 1.12))
    t = Tapa(dr, x, y, w, d, False)
    t.caja(0.1, 0.2, 0.38, 0.75, (170, 60, 50))
    t.caja(0.1, 0.42, 0.38, 0.55, (210, 180, 70), raya=False)
    t.caja(0.52, 0.25, 0.9, 0.85, (150, 110, 60))
    t.caja(0.58, 0.38, 0.84, 0.72, (110, 80, 45), raya=False)
    # el frente: el congelador arriba, la nevera debajo y el zócalo
    top = y + d
    caja(dr, x, top, x + w, top + h, tono(BLANCO, 0.95))
    corte = top + 15 * S
    dr.rectangle((x, corte, x + w - 1, corte + S - 1), fill=RAYA)
    caja(dr, x, top + h - 3 * S, x + w, top + h, (60, 60, 65))
    # las asas, largas y a la derecha
    caja(dr, x + w - 5 * S, top + 4 * S, x + w - 3 * S, top + 12 * S, ASA)
    caja(dr, x + w - 5 * S, corte + 3 * S, x + w - 3 * S, corte + 16 * S, ASA)
    # una nota de papel y unos imanes de colores en la puerta de la nevera
    caja(dr, x + 4 * S, corte + 4 * S, x + 10 * S, corte + 11 * S, (225, 215, 160))
    for (ix, iy, c) in ((13, 5, (170, 50, 50)), (17, 9, (60, 90, 160)), (12, 13, (200, 170, 50)), (19, 15, (70, 140, 80))):
        dr.rectangle((x + ix * S, corte + iy * S, x + (ix + 2) * S - 1, corte + (iy + 2) * S - 1), fill=c + (255,))
    # unas salpicaduras de sangre abajo
    for (bx, by) in ((5, 22), (6, 23), (8, 24), (22, 20), (23, 21)):
        punto(dr, x, corte, bx, by, SANGRE)


def encimera(dr, x, y, w, d, h):
    # la tapa, desde arriba (gris claro, de piedra): el fregadero con su grifo junto a la pared, una tabla de cortar
    # con un cuchillo y un tomate, un plato y una taza
    caja(dr, x, y, x + w, y + d, (185, 180, 170))
    t = Tapa(dr, x, y, w, d, False)
    t.caja(0.1, 0.25, 0.34, 0.9, (150, 155, 160))
    t.caja(0.12, 0.38, 0.32, 0.82, (105, 110, 118), raya=False)
    t.caja(0.21, 0.05, 0.24, 0.4, (80, 82, 90))
    t.caja(0.46, 0.3, 0.64, 0.85, (160, 115, 65))
    t.caja(0.48, 0.55, 0.6, 0.65, (205, 205, 210), raya=False)
    t.caja(0.58, 0.35, 0.62, 0.5, (180, 50, 40), raya=False)
    t.caja(0.72, 0.3, 0.82, 0.8, (225, 225, 220))
    t.caja(0.88, 0.25, 0.93, 0.55, (60, 90, 150))
    # el frente: el canto de la tapa, cuatro puertas de armario blancas con su tirador y el zócalo
    top = y + d
    caja(dr, x, top, x + w, top + 2 * S, (150, 145, 135))
    caja(dr, x, top + 2 * S, x + w, top + h, tono(BLANCO, 0.95))
    ancho = w // 4
    for k in range(4):
        px = x + k * ancho
        caja(dr, px + S, top + 3 * S, px + ancho - S, top + h - 3 * S, tono(BLANCO, 0.98))
        caja(dr, px + ancho // 2 - 3 * S, top + 5 * S, px + ancho // 2 + 3 * S, top + 6 * S, ASA)
    caja(dr, x, top + h - 3 * S, x + w, top + h, (60, 60, 65))
    for (bx, by) in ((50, 12), (51, 13), (53, 14), (12, 15), (13, 16)):
        punto(dr, x, top, bx, by, SANGRE)


def fogon(dr, x, y, w, d, h):
    # la tapa, desde arriba: la placa negra con cuatro fuegos de gas y sus rejillas
    caja(dr, x, y, x + w, y + d, (45, 45, 50))
    t = Tapa(dr, x, y, w, d, False)
    for u in (0.28, 0.72):
        for v in (0.3, 0.72):
            t.fuego(u, v, 4)
    # el frente, blanco como la nevera: la franja de los mandos, la puerta del horno con su asa y su cristal, y el zócalo
    top = y + d
    caja(dr, x, top, x + w, top + h, tono(BLANCO, 0.95))
    caja(dr, x, top, x + w, top + 5 * S, tono(BLANCO, 0.82))
    for k in range(4):
        px = x + (4 + k * 6) * S
        caja(dr, px, top + S, px + 3 * S, top + 4 * S, (50, 50, 55))
    caja(dr, x + 2 * S, top + 6 * S, x + w - 2 * S, top + h - 3 * S, tono(BLANCO, 0.98))
    caja(dr, x + 4 * S, top + 7 * S, x + w - 4 * S, top + 8 * S + S, ASA)
    caja(dr, x + 5 * S, top + 10 * S, x + w - 5 * S, top + h - 5 * S, (40, 40, 48))
    caja(dr, x, top + h - 3 * S, x + w, top + h, (60, 60, 65))
    for (bx, by) in ((3, 15), (4, 16), (22, 6), (23, 6)):
        punto(dr, x, top, bx, by, SANGRE)


def guia(nombre, largo, tapa, alto):
    w, d, h = largo // 2 * S, tapa * S, alto * S
    im = Image.new('RGBA', (w + 2 * M, d + h + 2 * M), FONDO + (255,))
    {'nevera': nevera, 'encimera': encimera, 'fogon': fogon}[nombre](ImageDraw.Draw(im), M, M, w, d, h)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


def limpia(ruta):
    """Quita la sombra azulada que PixelLab pinta debajo del mueble (más oscura que el fondo, así que quita() no se la
    lleva): lo azulado pegado a lo transparente en la quinta parte de abajo. Y luego las manchitas sueltas (menos de 8
    píxeles sin tocar el mueble), como una gota de sangre que caiga fuera. Sobrescribe el archivo, ya sin fondo"""
    im = Image.open(ruta).convert('RGBA')
    px = im.load()
    W, H = im.size
    y0 = H * 4 // 5

    def azulado(c):
        return c[3] > 0 and c[2] > c[0] + 30 and c[2] >= c[1] and max(c[:3]) < 170

    pila = [(x, y) for y in range(y0, H) for x in range(W) if px[x, y][3] == 0]
    quitados = 0
    while pila:
        x, y = pila.pop()
        for v in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= v[0] < W and y0 <= v[1] < H and azulado(px[v]):
                px[v] = (0, 0, 0, 0)
                quitados += 1
                pila.append(v)
    visto = set()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0 or (x, y) in visto:
                continue
            trozo, pila = [], [(x, y)]
            visto.add((x, y))
            while pila:
                p = pila.pop()
                trozo.append(p)
                for v in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)):
                    if 0 <= v[0] < W and 0 <= v[1] < H and v not in visto and px[v][3] > 0:
                        visto.add(v)
                        pila.append(v)
            if len(trozo) < 8:
                for p in trozo:
                    px[p] = (0, 0, 0, 0)
                quitados += len(trozo)
    im.save(ruta)
    print('limpio:', ruta, quitados, 'píxeles')


if __name__ == '__main__':
    if sys.argv[1:2] == ['limpia']:
        for r in sys.argv[2:]:
            limpia(r)
        sys.exit()
    for nombre, (largo, tapa, alto) in T.items():
        guia(nombre, largo, tapa, alto)
