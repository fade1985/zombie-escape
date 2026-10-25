"""Bocetos (guías) de los muebles del dormitorio de los pisos y de la lámpara de pie, para pedírselos a PixelLab
rectos, de frente y con el mismo estilo que la cocina nueva (tools/guias_cocina.py, de donde salen caja() y punto()).

Lo mismo que allí (de tools/guias_centro.py salen la perspectiva, los colores de la raya y del fondo azul y cómo se quita
el fondo después): de arriba abajo, lo que se ve desde arriba (con lo que hay encima: si es liso, PixelLab lo deja liso)
y el frente. Las tapas son más cortas que el fondo del catálogo, para que se vean de frente y solo un poco desde arriba.
  - cama de matrimonio y cama individual: el cabecero de madera de frente contra la pared, el colchón visto desde arriba
    (las almohadas arriba y la colcha con su dobladillo hasta abajo) y los pies de la cama, de frente
  - mesilla: la lamparita encima (su pantalla sube por encima del borde de atrás, sobre la pared; es la que da luz en el
    juego), un despertador, y dos cajones de frente
  - armario: alto, como la nevera; encima una caja de cartón y una maleta; dos puertas con sus tiradores
  - escritorio: un portátil abierto, una pila de libros, papeles y una taza encima; cajones a los lados y el hueco de las
    piernas en medio (sin silla)
  - lámpara de pie: la pantalla vista desde arriba (su borde, un óvalo), la pantalla, la barra y la base

  py tools/guias_dormitorio.py   → assets/sources/centro/guias/<cama-matrimonio|cama|mesilla|armario|escritorio|lampara>.png
Después, igual que con la cocina: py tools/guias_centro.py quita <png>… y py tools/guias_cocina.py limpia [--todo] <png>…
Se pasan al juego con py tools/importar.py (sus originales, en assets/sources/salas/dormitorio/ y comun/).
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono, Tapa
from guias_cocina import caja, punto, ASA, SANGRE, MADERA

SABANA = (215, 205, 185)
ALMOHADA = (230, 228, 220)
# archivo: (largo, el del catálogo, en unidades; lo que se ve desde arriba y alto del frente, en píxeles del juego)
#   cama: el cabecero (12) y el colchón (54) suman 66 de "arriba", y los pies, 10 de frente
#   mesilla: 8 de pantalla de la lámpara sobre el borde de atrás + 14 de tapa
T = {
    'cama-matrimonio': (124, 66, 10),
    'cama':            (84, 66, 10),
    'mesilla':         (40, 22, 14),
    'armario':         (96, 20, 52),
    'escritorio':      (92, 22, 20),
    'lampara':         (30, 7, 47),
}


def cama(dr, x, y, w, d, h, almohadas, colcha, sangre):
    cab = 12 * S
    # el cabecero, de frente contra la pared: dos postes y un panel de madera en medio, con una tabla encima
    caja(dr, x, y, x + w, y + cab, tono(MADERA, 0.6))
    caja(dr, x + 3 * S, y + 3 * S, x + w - 3 * S, y + cab - S, tono(MADERA, 0.78))
    caja(dr, x, y, x + 3 * S, y + cab, tono(MADERA, 0.5))
    caja(dr, x + w - 3 * S, y, x + w, y + cab, tono(MADERA, 0.5))
    # el colchón, desde arriba: el marco de madera, la sábana, las almohadas arriba y la colcha con su dobladillo
    top = y + cab
    caja(dr, x, top, x + w, y + d, tono(MADERA, 0.7))
    t = Tapa(dr, x + 2 * S, top, w - 4 * S, d - cab, False)
    t.caja(0, 0, 1, 1, SABANA)
    if almohadas == 2:
        t.caja(0.06, 0.05, 0.47, 0.27, ALMOHADA)
        t.caja(0.53, 0.05, 0.94, 0.27, ALMOHADA)
    else:
        t.caja(0.1, 0.05, 0.9, 0.27, ALMOHADA)
    t.caja(0, 0.34, 1, 1, colcha)
    t.caja(0, 0.34, 1, 0.41, tono(colcha, 1.25), raya=False)     # el dobladillo, doblado hacia las almohadas
    t.caja(0.05, 0.6, 0.95, 0.63, tono(colcha, 0.85), raya=False)   # unas arrugas
    t.caja(0.1, 0.8, 0.9, 0.83, tono(colcha, 0.85), raya=False)
    for (px, py) in sangre:
        punto(dr, x + 2 * S, top, px, py, SANGRE)
    # los pies de la cama, de frente: la tabla, más baja que el cabecero, con los postes en las esquinas
    pie = y + d
    caja(dr, x, pie, x + w, pie + h, tono(MADERA, 0.65))
    caja(dr, x + 3 * S, pie + S, x + w - 3 * S, pie + h - 2 * S, tono(MADERA, 0.8))
    caja(dr, x, pie, x + 3 * S, pie + h, tono(MADERA, 0.5))
    caja(dr, x + w - 3 * S, pie, x + w, pie + h, tono(MADERA, 0.5))


def cama_matrimonio(dr, x, y, w, d, h):
    cama(dr, x, y, w, d, h, 2, (140, 50, 55), ((20, 22), (21, 23), (23, 23), (40, 34), (41, 35)))


def cama_individual(dr, x, y, w, d, h):
    # la colcha, mostaza: con una verde oliva PixelLab dibujaba casi todo el colchón blanco, con una franja turquesa abajo
    # y sin pies de cama (lo mismo con un tono granate pero con menos ganas: la de matrimonio ya es granate)
    cama(dr, x, y, w, d, h, 1, (185, 140, 55), ((10, 22), (11, 23), (28, 34), (29, 35)))


def mesilla(dr, x, y, w, d, h):
    luz = 8 * S                       # la pantalla de la lámpara sube por encima del borde de atrás
    sup = y + luz
    # la tapa de madera, desde arriba, con la base de la lámpara y un despertador
    caja(dr, x, sup, x + w, y + d, tono(MADERA, 1.05))
    t = Tapa(dr, x, sup, w, d - luz, False)
    t.caja(0.14, 0.3, 0.42, 0.7, (70, 60, 50))                  # la base de la lámpara
    t.caja(0.58, 0.3, 0.88, 0.7, (150, 50, 45))                 # el despertador
    t.caja(0.64, 0.4, 0.82, 0.58, (200, 200, 190), raya=False)
    punto(dr, x, sup, 14, 9, SANGRE)
    punto(dr, x, sup, 15, 10, SANGRE)
    # la lámpara: la barra y la pantalla de tela, que sube sobre el borde de atrás
    dr.rectangle((x + 5 * S + 1, y + 7 * S, x + 5 * S + S, sup + 5 * S), fill=(110, 90, 50, 255))
    dr.polygon([(x + 2 * S, y + 7 * S), (x + 9 * S, y + 7 * S), (x + 8 * S, y), (x + 3 * S, y)],
               fill=(225, 195, 120, 255), outline=RAYA)
    # el frente: el canto de la tapa, dos cajones con su tirador y las patas
    top = y + d
    caja(dr, x, top, x + w, top + h, tono(MADERA, 0.8))
    caja(dr, x, top, x + w, top + 2 * S, tono(MADERA, 0.65))
    for k in range(2):
        cy = top + (3 + k * 5) * S
        caja(dr, x + 2 * S, cy, x + w - 2 * S, cy + 4 * S, tono(MADERA, 0.95))
        caja(dr, x + w // 2 - S, cy + S + 1, x + w // 2 + S, cy + 3 * S, ASA)
    caja(dr, x, top + h - 2 * S, x + w, top + h, tono(MADERA, 0.5))
    punto(dr, x, top, 12, 12, SANGRE)
    punto(dr, x, top, 13, 12, SANGRE)


def armario(dr, x, y, w, d, h):
    # lo de encima, desde arriba: la madera, una caja de cartón y una maleta vieja
    caja(dr, x, y, x + w, y + d, tono(MADERA, 1.0))
    t = Tapa(dr, x, y, w, d, False)
    t.caja(0.08, 0.2, 0.4, 0.8, (170, 135, 90))
    t.caja(0.08, 0.2, 0.4, 0.35, (200, 165, 115), raya=False)
    t.caja(0.52, 0.25, 0.92, 0.85, (110, 70, 50))
    t.caja(0.58, 0.45, 0.86, 0.5, (190, 170, 60), raya=False)
    # el frente: la cornisa, dos puertas con su panel y su tirador, y el zócalo con las patas
    top = y + d
    caja(dr, x, top, x + w, top + h, tono(MADERA, 0.8))
    caja(dr, x, top, x + w, top + 3 * S, tono(MADERA, 0.65))
    mitad = w // 2
    for k in range(2):
        px = x + k * mitad
        caja(dr, px + 2 * S, top + 5 * S, px + mitad - S, top + h - 6 * S, tono(MADERA, 0.88))
        caja(dr, px + 5 * S, top + 8 * S, px + mitad - 4 * S, top + h - 9 * S, tono(MADERA, 0.78))
    caja(dr, x + mitad - 3 * S - S, top + h // 2 - 3 * S, x + mitad - 2 * S, top + h // 2 + 3 * S, (205, 170, 60))
    caja(dr, x + mitad + 2 * S, top + h // 2 - 3 * S, x + mitad + 3 * S + S, top + h // 2 + 3 * S, (205, 170, 60))
    caja(dr, x, top + h - 4 * S, x + w, top + h, tono(MADERA, 0.55))
    for (bx, by) in ((6, 40), (7, 41), (9, 41), (36, 30), (36, 31), (37, 32)):
        punto(dr, x, top, bx, by, SANGRE)


def escritorio(dr, x, y, w, d, h):
    # la tapa, desde arriba: un portátil abierto (la pantalla detrás, el teclado delante), libros, papeles y una taza
    caja(dr, x, y, x + w, y + d, tono(MADERA, 1.0))
    t = Tapa(dr, x, y, w, d, False)
    t.caja(0.06, 0.05, 0.4, 0.4, (50, 55, 62))                  # la pantalla
    t.caja(0.09, 0.09, 0.37, 0.34, (95, 130, 125), raya=False)
    t.caja(0.06, 0.4, 0.4, 0.88, (160, 160, 165))               # el teclado
    t.caja(0.1, 0.5, 0.36, 0.75, (95, 95, 100), raya=False)
    t.caja(0.5, 0.15, 0.7, 0.5, (150, 50, 45))                  # una pila de libros
    t.caja(0.5, 0.15, 0.7, 0.26, (60, 90, 70), raya=False)
    t.caja(0.52, 0.3, 0.68, 0.42, (200, 170, 60), raya=False)
    t.caja(0.55, 0.55, 0.78, 0.9, (225, 222, 210))              # unos papeles
    t.caja(0.82, 0.3, 0.9, 0.6, (225, 225, 220))                # una taza
    punto(dr, x, y, 29, 13, SANGRE)
    punto(dr, x, y, 30, 14, SANGRE)
    # el frente: el canto, el cajón de arriba, un cajonero a cada lado y el hueco de las piernas en medio
    top = y + d
    caja(dr, x, top, x + w, top + h, tono(MADERA, 0.8))
    caja(dr, x, top, x + w, top + 2 * S, tono(MADERA, 0.65))
    lado = 13 * S
    caja(dr, x + lado, top + 2 * S, x + w - lado, top + h - 2 * S, (45, 38, 35))     # el hueco de las piernas
    caja(dr, x + lado, top + 2 * S, x + w - lado, top + 6 * S, tono(MADERA, 0.9))    # el cajón de arriba
    caja(dr, x + w // 2 - 2 * S, top + 3 * S + 1, x + w // 2 + 2 * S, top + 5 * S, ASA)
    for px in (x, x + w - lado):
        for k in range(2):
            cy = top + 2 * S + k * 8 * S
            caja(dr, px + S, cy + S, px + lado - S, cy + 8 * S, tono(MADERA, 0.92))
            caja(dr, px + lado // 2 - S, cy + 4 * S, px + lado // 2 + S, cy + 5 * S, ASA)
    caja(dr, x, top + h - 2 * S, x + lado, top + h, tono(MADERA, 0.5))
    caja(dr, x + w - lado, top + h - 2 * S, x + w, top + h, tono(MADERA, 0.5))
    punto(dr, x, top, 6, 12, SANGRE)
    punto(dr, x, top, 7, 13, SANGRE)


def lampara(dr, x, y, w, d, h):
    # la lámpara de pie, de 15 píxeles de ancho: el borde de arriba de la pantalla (un óvalo visto desde arriba), la
    # pantalla de tela que baja desde él, una barra fina de latón y la base redonda
    cx = x + w // 2
    pantalla = (215, 190, 130, 255)
    abajo = y + d + 11 * S
    dr.polygon([(x, y + d // 2), (x + w, y + d // 2), (x + w - 3 * S, abajo), (x + 3 * S, abajo)],
               fill=pantalla, outline=RAYA)
    dr.ellipse((x, y, x + w - 1, y + d), fill=tono((215, 190, 130), 1.1), outline=RAYA)
    dr.ellipse((x + 3 * S, y + S, x + w - 3 * S - 1, y + d - S), fill=(240, 215, 140, 255))
    dr.rectangle((cx - 1, abajo, cx, y + d + h - 5 * S), fill=(110, 90, 50, 255), outline=RAYA)
    caja(dr, cx - 1 * S, abajo + S, cx + S, abajo + 2 * S, (110, 90, 50))
    dr.ellipse((cx - 5 * S, y + d + h - 5 * S, cx + 5 * S - 1, y + d + h), fill=(75, 62, 50, 255), outline=RAYA)
    punto(dr, x, y + d, 5, 24, SANGRE)


FUNCIONES = {'cama-matrimonio': cama_matrimonio, 'cama': cama_individual, 'mesilla': mesilla, 'armario': armario,
             'escritorio': escritorio, 'lampara': lampara}


def guia(nombre, largo, tapa, alto):
    w, d, h = largo // 2 * S, tapa * S, alto * S
    im = Image.new('RGBA', (w + 2 * M, d + h + 2 * M), FONDO + (255,))
    FUNCIONES[nombre](ImageDraw.Draw(im), M, M, w, d, h)
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    for nombre, (largo, tapa, alto) in T.items():
        guia(nombre, largo, tapa, alto)
