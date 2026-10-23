"""Bocetos (guías) de los muebles nuevos de la sala de mantenimiento, para pedírselos a PixelLab rectos.

La sala de mantenimiento tiene tres estancias (planta.gd): el vestuario de Johnny, su despacho y el taller. Sus
muebles nuevos salen de PixelLab con la misma receta que el banco de trabajo, el baúl y la mesa del ordenador
(tools/banco_mantenimiento.py): un boceto ya en la perspectiva del juego, sobre azul, que PixelLab "viste" (la
perspectiva, los colores de la raya y del fondo y cómo se quita el fondo, de tools/guias_centro.py). Dos clases:
  - muebles del catálogo (catalogo.gd), que se pasan al juego con py tools/importar.py (sus originales, en
    assets/sources/salas/vestuario/, mantenimiento/ y despacho/): el plato de ducha, el banco largo del vestuario,
    el váter y el lavabo con su espejo (estos dos, solo de lado: van en la pared de la izquierda), la estantería
    metálica con botes del taller y la papelera del despacho;
  - el corcho del despacho, que cuelga de la pared de arriba, visto de frente y plano (mapa.gd lo pone en la cara del
    muro, como los escaparates de la galería): su original en assets/sources/mantenimiento/corcho.png.

  py tools/guias_mantenimiento.py           → assets/sources/mantenimiento/guias/<archivo>.png (los bocetos)
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
  py tools/guias_mantenimiento.py limpia <desde> <hasta> <png>…   y luego lo azulado que pinta alrededor (la pared de
                                            detrás de la ducha: 0 0.45; la sombra del banco y de la papelera: 0.5 1)
  py tools/guias_mantenimiento.py corcho    assets/sources/mantenimiento/corcho.png (el elegido, sin fondo)
                                            → assets/sprites/corcho.png (y luego importar en Godot)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, RAYA, FONDO, tono
from importar import convierte

CARPETA = 'assets/sources/mantenimiento'
GUIAS = f'{CARPETA}/guias'
CORCHO = f'{CARPETA}/corcho.png'
CORCHO_SPRITE = 'assets/sprites/corcho.png'
CORCHO_ANCHO = 44   # en píxeles del juego (88 unidades)

BLANCO = (222, 224, 226)
CROMO = (170, 176, 184)
MADERA = (150, 105, 60)
ACERO = (120, 124, 132)
SANGRE = (120, 30, 30)
AGUA = (70, 95, 110)
CORTINA = (90, 140, 150)
CORCHO_COLOR = (180, 130, 80)
PAPEL = (225, 220, 200)
PLANO = (55, 90, 150)


def lienzo(w, h):
    """Un lienzo de w × h píxeles del juego, sobre azul, y su "caja": un rectángulo de (x0, y0) a (x1, y1) sin incluir"""
    im = Image.new('RGBA', (w * S + 2 * M, h * S + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)

    def caja(x0, y0, x1, y1, color, raya=True):
        dr.rectangle((M + x0 * S, M + y0 * S, M + x1 * S - 1, M + y1 * S - 1),
                     fill=color if len(color) == 4 else color + (255,), outline=RAYA if raya else None)

    def ovalo(x0, y0, x1, y1, color, raya=True):
        dr.ellipse((M + x0 * S, M + y0 * S, M + x1 * S - 1, M + y1 * S - 1),
                   fill=color if len(color) == 4 else color + (255,), outline=RAYA if raya else None)
    return im, caja, ovalo


def guardar(im, nombre):
    os.makedirs(GUIAS, exist_ok=True)
    ruta = f'{GUIAS}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


def plato_ducha():
    """De frente, en la esquina de arriba a la izquierda (72 × 64 unidades): en la pared, el tubo de la ducha con su
    alcachofa y el grifo; delante, la barra de la cortina, con la cortina recogida a la izquierda, que cuelga hasta el
    suelo; el plato visto desde arriba, con su borde y el desagüe; y el canto del plato"""
    W, ARRIBA, TAPA, CANTO = 36, 26, 32, 3
    im, caja, ovalo = lienzo(W, ARRIBA + TAPA + CANTO)
    caja(27, 4, 29, ARRIBA + 2, CROMO)                     # el tubo
    caja(21, 2, 30, 5, CROMO); caja(22, 5, 27, 6, tono(CROMO, 0.7), raya=False)   # la alcachofa
    caja(25, 15, 32, 18, CROMO)                            # el grifo
    y = ARRIBA
    caja(0, y, W, y + TAPA, BLANCO)                        # el plato
    caja(2, y + 2, W - 2, y + TAPA - 2, tono(BLANCO, 0.9))
    ovalo(16, y + 14, 21, y + 18, (60, 62, 66))            # el desagüe
    caja(5, y + 22, 11, y + 26, SANGRE, raya=False); caja(24, y + 8, 27, y + 10, SANGRE, raya=False)
    caja(0, y + TAPA, W, y + TAPA + CANTO, tono(BLANCO, 0.75))   # el canto
    caja(0, 19, W, 21, CROMO)                              # la barra de la cortina
    caja(0, 21, 8, y + TAPA - 2, CORTINA)                  # la cortina, recogida
    for x in (2, 4, 6):
        caja(x, 22, x + 1, y + TAPA - 3, tono(CORTINA, 0.75), raya=False)   # sus pliegues
    guardar(im, 'plato-ducha')


def banco_vestuario():
    """El banco largo sin respaldo del vestuario (128 × 28 unidades), suelto, de frente: el asiento de tres listones
    visto desde arriba, su canto, las patas de hierro con su travesaño y unas botas viejas debajo"""
    W, TAPA, FRENTE = 64, 14, 10
    im, caja, ovalo = lienzo(W, TAPA + FRENTE)
    caja(0, 0, W, TAPA, tono(MADERA, 1.1))
    for y in (4, 9):
        caja(1, y, W - 1, y + 1, tono(MADERA, 0.7), raya=False)   # las rendijas entre listones
    caja(20, 5, 27, 8, SANGRE, raya=False)
    caja(0, TAPA, W, TAPA + 3, tono(MADERA, 0.75))          # el canto
    for x in (4, W - 8):
        caja(x, TAPA + 3, x + 4, TAPA + FRENTE, ACERO)       # las patas
    caja(8, TAPA + 6, W - 8, TAPA + 7, tono(ACERO, 0.8))    # el travesaño
    caja(38, TAPA + 5, 44, TAPA + FRENTE, (70, 55, 45)); caja(45, TAPA + 5, 51, TAPA + FRENTE, (70, 55, 45))   # las botas
    guardar(im, 'banco-vestuario')


def vater_lado():
    """El váter, de lado, para la pared de la izquierda (40 a lo largo de la pared × 52 de fondo): la cisterna pegada a
    la pared (su tapa vista desde arriba y su costado, que llega al suelo) y la taza, más baja, que sale hacia la
    habitación (el asiento visto desde arriba, con el agua, y el costado que se estrecha en el pie)"""
    W, H = 26, 40
    im, caja, ovalo = lienzo(W, H)
    caja(0, 0, 9, 20, BLANCO)                              # la tapa de la cisterna
    caja(3, 8, 6, 11, CROMO)                               # el pulsador
    caja(0, 20, 9, H, tono(BLANCO, 0.8))                   # su costado
    ovalo(8, 13, 25, 28, BLANCO)                           # el asiento
    ovalo(11, 16, 22, 25, AGUA)                            # el agua
    caja(9, 27, 24, 33, tono(BLANCO, 0.8))                 # el costado de la taza
    caja(10, 33, 19, H, tono(BLANCO, 0.72))                # el pie
    caja(14, 21, 17, 23, SANGRE, raya=False)
    guardar(im, 'vater-vestuario-lado')


def lavabo_lado():
    """El lavabo con su espejo, de lado, para la pared de la izquierda (52 a lo largo de la pared × 40 de fondo): el
    espejo, en la pared, se ve de canto (su marco y un filo de cristal); debajo, la pila vista desde arriba, con el
    grifo junto a la pared, y su costado con el pie"""
    W, H = 20, 68
    im, caja, ovalo = lienzo(W, H)
    caja(0, 0, 4, 34, (95, 80, 65))                        # el marco del espejo
    caja(1, 2, 3, 32, (175, 205, 215), raya=False)         # el cristal, de canto
    caja(3, 28, 5, 29, SANGRE, raya=False)
    caja(0, 22, 18, 46, BLANCO)                            # la pila, desde arriba
    ovalo(4, 26, 16, 42, tono(BLANCO, 0.8))                # su hueco
    ovalo(8, 32, 11, 35, (60, 62, 66), raya=False)         # el desagüe
    caja(1, 30, 6, 33, CROMO)                              # el grifo
    caja(0, 46, 18, 49, tono(BLANCO, 0.8))                 # el canto de la pila
    caja(5, 49, 12, H, tono(BLANCO, 0.72))                 # el pie
    guardar(im, 'lavabo-espejo-lado')


def estanteria_botes():
    """La estantería metálica del taller (80 × 36 unidades), de frente: arriba, unos botes vistos desde arriba; el
    frente, con cuatro baldas llenas de botes de pintura, esprays, tarros y garrafas, y abajo dos cubos grandes"""
    W, TAPA, FRENTE = 40, 18, 46
    im, caja, ovalo = lienzo(W, TAPA + FRENTE)
    caja(0, 0, W, TAPA, tono(ACERO, 1.1))
    for x, c in ((4, (170, 60, 50)), (12, (200, 200, 190)), (28, (60, 100, 160))):
        ovalo(x, 5, x + 7, 12, c)                          # botes encima
    y = TAPA
    caja(0, y, W, y + FRENTE, tono(ACERO, 0.45))           # el fondo, a la sombra
    for x in (0, W - 2):
        caja(x, y, x + 2, y + FRENTE, ACERO)               # los montantes
    botes = [
        [(3, 7, (170, 60, 50)), (11, 6, (190, 160, 70)), (19, 4, (60, 120, 70)), (25, 4, (60, 120, 70)), (31, 6, (200, 200, 190))],
        [(3, 5, (70, 90, 150)), (9, 8, (200, 200, 190)), (19, 6, (150, 90, 140)), (27, 9, (190, 160, 70))],
        [(3, 9, (220, 220, 210)), (14, 5, (170, 60, 50)), (21, 5, (60, 120, 70)), (28, 8, (70, 90, 150))],
    ]
    for k, fila in enumerate(botes):
        fondo = y + 11 + k * 11                            # la balda de esta fila
        for x, w, c in fila:
            caja(x, fondo - 8, x + w, fondo, c)            # cada bote
            caja(x, fondo - 5, x + w, fondo - 3, tono(c, 1.3), raya=False)   # su etiqueta
        caja(0, fondo, W, fondo + 2, ACERO)                # la balda
    for x in (4, 21):
        caja(x, y + FRENTE - 10, x + 14, y + FRENTE, (200, 200, 190))   # los cubos grandes de abajo
        caja(x, y + FRENTE - 8, x + 14, y + FRENTE - 6, (170, 60, 50), raya=False)
    caja(33, y + 14, 35, y + 20, SANGRE, raya=False)
    guardar(im, 'estanteria-botes')


def papelera():
    """La papelera del despacho (24 × 22 unidades), de frente: la boca vista desde arriba, llena de papeles arrugados,
    y el cuerpo de rejilla"""
    W, TAPA, FRENTE = 12, 11, 10
    im, caja, ovalo = lienzo(W, TAPA + FRENTE)
    ovalo(0, 0, W, TAPA, (60, 62, 70))                     # la boca
    for x, y in ((2, 2), (6, 4), (3, 6)):
        ovalo(x, y, x + 5, y + 4, PAPEL)                   # los papeles arrugados
    caja(1, TAPA - 2, W - 1, TAPA + FRENTE, (80, 82, 90))  # el cuerpo
    for x in (3, 6, 9):
        caja(x, TAPA, x + 1, TAPA + FRENTE - 1, (55, 57, 64), raya=False)   # la rejilla
    guardar(im, 'papelera')


def corcho():
    """El corcho del despacho, colgado en la pared, de frente y plano: el marco de madera y, clavados con chinchetas
    rojas, el plano del edificio en medio (sus cinco plantas) y papeles, notas y una foto alrededor"""
    W, H = 44, 28
    im, caja, ovalo = lienzo(W, H)
    caja(0, 0, W, H, (110, 75, 45))                        # el marco
    caja(2, 2, W - 2, H - 2, CORCHO_COLOR, raya=False)
    caja(14, 3, 31, 24, PLANO)                             # el plano del edificio
    for k in range(5):
        caja(17, 5 + k * 3, 28, 7 + k * 3, (200, 220, 240), raya=False)   # sus plantas
    caja(3, 4, 11, 12, PAPEL); caja(4, 6, 10, 7, (150, 150, 145), raya=False); caja(4, 8, 9, 9, (150, 150, 145), raya=False)
    caja(4, 15, 11, 22, (230, 210, 90))                    # una nota amarilla
    caja(33, 4, 41, 11, (200, 200, 190)); caja(34, 5, 40, 10, (110, 120, 110), raya=False)   # una foto
    caja(34, 14, 41, 24, PAPEL)
    for x, y in ((7, 4), (7, 15), (22, 3), (37, 4), (37, 14)):
        caja(x, y, x + 1, y + 1, (200, 40, 40), raya=False)   # las chinchetas
    caja(26, 18, 29, 20, SANGRE, raya=False)
    guardar(im, 'corcho')


def limpia(ruta, desde, hasta):
    """Quita lo azulado que PixelLab pinta alrededor del mueble y que quita() no se lleva porque es más oscuro que el
    fondo: la pared de detrás de la ducha y la sombra del suelo debajo del banco y de la papelera (sobrescribe el
    archivo, ya sin fondo). Solo lo pegado a lo transparente y entre las alturas "desde" y "hasta" (de 0 a 1). No toca
    la raya oscura del contorno (que hace de tope), ni lo claro (el cromo de la ducha), ni lo verdoso (la cortina)"""
    im = Image.open(ruta).convert('RGBA')
    px = im.load()
    W, H = im.size
    y0, y1 = int(H * desde), int(H * hasta)

    def azulado(c):
        return c[3] > 0 and c[2] > c[0] + 12 and c[2] > c[1] + 8 and c[0] > 30 and max(c[:3]) < 150

    # desde lo transparente y desde el borde de la imagen (la pared de la ducha llega hasta él)
    pila = [(x, y) for y in range(y0, y1) for x in range(W) if px[x, y][3] == 0]
    pila += [(-1, y) for y in range(y0, y1)] + [(W, y) for y in range(y0, y1)]
    pila += ([(x, -1) for x in range(W)] if y0 == 0 else []) + ([(x, H) for x in range(W)] if y1 == H else [])
    visto = set()
    quitados = 0
    while pila:
        x, y = pila.pop()
        for v in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if v in visto or not (0 <= v[0] < W and y0 <= v[1] < y1):
                continue
            visto.add(v)
            if azulado(px[v]):
                px[v] = (0, 0, 0, 0)
                quitados += 1
                pila.append(v)
    im.save(ruta)
    print('limpio:', ruta, quitados, 'píxeles')


def monta_corcho():
    """El elegido (ya sin fondo) → el sprite del juego, con la receta de los muebles (tools/importar.py)"""
    out = convierte(CORCHO, CORCHO_ANCHO, halo=False)
    out.save(CORCHO_SPRITE)
    print(CORCHO_SPRITE, out.size)


if __name__ == '__main__':
    if sys.argv[1:2] == ['corcho']:
        monta_corcho()
    elif sys.argv[1:2] == ['limpia']:
        desde, hasta = float(sys.argv[2]), float(sys.argv[3])
        for r in sys.argv[4:]:
            limpia(r, desde, hasta)
    else:
        for hacer in (plato_ducha, banco_vestuario, vater_lado, lavabo_lado, estanteria_botes, papelera, corcho):
            hacer()
