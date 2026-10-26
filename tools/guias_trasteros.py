"""Bocetos (guías) de lo que hay en los trasteros de las viviendas (viviendas.gd), para pedírselo a PixelLab recto: en el
pasillo, cajas de cartón apiladas y una carretilla de mano cargada; en cada habitación, una estantería metálica vacía
y un colchón en el suelo. Todo contra la pared de arriba, de frente.

Lo mismo que tools/guias_limpieza.py (de tools/guias_centro.py salen la perspectiva, los colores de la raya y del fondo
azul y cómo se quita el fondo después). En la perspectiva del juego el suelo se ve desde arriba sin encoger y lo que
tiene altura sube hacia arriba de la pantalla, así que cada caja es su tapa (ancho × fondo) y debajo su frente
(ancho × alto); una caja encima de otra, subida lo que mide de alto la de abajo.

El colchón no se dibuja con cajas: es la cama de siempre (assets/sources/salas/dormitorio/cama.png, sin la sangre) sin el
cabecero ni el pie de madera, con el canto del colchón delante, para que PixelLab deje la almohada descolocada como está.

  py tools/guias_trasteros.py               → assets/sources/centro/guias/<archivo>.png
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
Los originales, ya sin fondo, en assets/sources/salas/viviendas/; al juego, con py tools/importar.py.
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono

CARTON = (176, 132, 84)
CINTA = (205, 180, 130)
ETIQUETA = (225, 222, 210)
HIERRO = (150, 40, 36)       # la carretilla, de tubo pintado de rojo
RUEDA = (40, 40, 46)
CHAPA = (150, 155, 162)
# archivo: (largo, fondo, alto) en píxeles del juego (largo y fondo, los del catálogo / 2; alto, lo que sube lo más alto)
T = {
    'cajas-pila':  (32, 18, 25),
    'cajas-bajas': (28, 16, 19),
    'carretilla':  (20, 14, 34),
    'estanteria-trastero': (44, 18, 46),
}
GALVA = (165, 170, 178)      # la estantería, de acero galvanizado
# el colchón: de qué fila a qué fila de la cama se coge (de la sábana de debajo del cabecero a la de antes del pie de madera),
# y su canto de delante, de arriba abajo: la colcha que cuelga, la tela del colchón a rayas y el contorno (píxeles de la guía)
COLCHON = (33, 147)
CUELGA, TELA, CONTORNO = 6, 4, 2
TELA_COLOR = [(206, 208, 216), (176, 182, 196)]   # la tela del colchón: el claro y la raya


def rect(dr, x0, y0, x1, y1, color, raya=True):
    dr.rectangle((x0 * S, y0 * S, x1 * S - 1, y1 * S - 1), fill=color if len(color) == 4 else color + (255,),
                 outline=RAYA if raya else None)


def caja(dr, x, suelo, ancho, fondo, alto, base=0, atras=0, etiqueta=False):
    """Una caja de cartón: x, su izquierda; suelo, la "y" del pie de la pared; atras, lo que se separa de la pared;
    base, a qué altura está apoyada (encima de otra). Todo en píxeles del juego"""
    arriba = suelo + atras - base - alto
    rect(dr, x, arriba, x + ancho, arriba + fondo, tono(CARTON, 1.12))                    # la tapa
    rect(dr, x + ancho // 2, arriba, x + ancho // 2 + 1, arriba + fondo, tono(CARTON, 0.85), False)   # la junta de las solapas
    rect(dr, x + ancho // 2 - 2, arriba, x + ancho // 2 + 3, arriba + fondo, CINTA, False)   # y la cinta encima
    rect(dr, x + ancho // 2, arriba, x + ancho // 2 + 1, arriba + fondo, tono(CINTA, 0.85), False)
    frente = arriba + fondo
    rect(dr, x, frente, x + ancho, frente + alto, tono(CARTON, 0.88))                    # el frente
    rect(dr, x + ancho // 2 - 2, frente, x + ancho // 2 + 3, frente + 3, CINTA, False)     # la cinta, que baja un poco
    if etiqueta:
        rect(dr, x + 2, frente + alto // 2 - 1, x + 7, frente + alto // 2 + 3, ETIQUETA)
    # las tres rayas de contorno otra vez, que la cinta no se las coma
    dr.rectangle((x * S, arriba * S, (x + ancho) * S - 1, (frente + alto) * S - 1), outline=RAYA)
    dr.line((x * S, frente * S, (x + ancho) * S - 1, frente * S), fill=RAYA)


def cajas_pila(dr, suelo):
    caja(dr, 0, suelo, 17, 18, 13, etiqueta=True)
    caja(dr, 17, suelo, 15, 18, 13)
    caja(dr, 6, suelo, 18, 14, 12, base=13)


def cajas_bajas(dr, suelo):
    caja(dr, 15, suelo, 13, 13, 9, atras=0)
    caja(dr, 0, suelo, 15, 16, 12, etiqueta=True)
    caja(dr, 3, suelo, 10, 10, 7, base=12)


def carretilla(dr, suelo):
    # las ruedas, a los lados, junto a la pared; el armazón (dos tubos que suben hasta el asa) y la pala del suelo
    for x in (0, 16):
        rect(dr, x, suelo - 4, x + 4, suelo + 3, RUEDA)
        rect(dr, x + 1, suelo - 2, x + 3, suelo + 1, tono(RUEDA, 1.8), False)
    for x in (3, 15):
        rect(dr, x, suelo - 34, x + 2, suelo + 2, HIERRO)
    rect(dr, 3, suelo - 34, 17, suelo - 32, HIERRO)          # el asa
    rect(dr, 3, suelo - 26, 17, suelo - 25, HIERRO, False)   # un travesaño
    rect(dr, 2, suelo + 9, 18, suelo + 12, CHAPA)           # la pala, delante, en el suelo (asoma por debajo de las cajas)
    caja(dr, 4, suelo, 12, 9, 10, atras=2)
    caja(dr, 5, suelo, 10, 8, 8, base=10, atras=2, etiqueta=False)


def estanteria(dr, suelo):
    """Una estantería de trastero, vacía: la balda de arriba vista desde arriba, y de frente los dos postes de angular
    agujereado y cuatro baldas sin nada, cada una con su canto y, detrás, lo que se ve de su tabla"""
    rect(dr, 0, suelo - 46, 44, suelo - 28, GALVA)
    rect(dr, 2, suelo - 44, 42, suelo - 30, tono(GALVA, 1.08), False)
    baldas = [suelo - 28, suelo - 14, suelo, suelo + 14]
    for y0, y1 in zip(baldas, baldas[1:] + [suelo + 18]):
        rect(dr, 3, y0, 41, y1, tono(GALVA, 0.55))                 # el hueco, en sombra
        if y1 - y0 > 6:
            rect(dr, 3, y1 - 6, 41, y1, tono(GALVA, 0.85), False)  # la tabla de la balda de debajo, que se ve desde arriba
        rect(dr, 3, y0, 41, y0 + 2, tono(GALVA, 1.12))             # el canto de la balda
    for x in (0, 41):
        rect(dr, x, suelo - 28, x + 3, suelo + 18, tono(GALVA, 0.8))
        for y in range(suelo - 26, suelo + 16, 3):
            rect(dr, x + 1, y, x + 2, y + 1, tono(GALVA, 0.4), False)   # los agujeros del angular


def guia(nombre, largo, fondo, alto):
    im = Image.new('RGBA', (largo * S + 2 * M, (fondo + alto) * S + 2 * M), FONDO + (255,))
    capa = Image.new('RGBA', (largo * S, (fondo + alto) * S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(capa)
    {'cajas-pila': cajas_pila, 'cajas-bajas': cajas_bajas, 'carretilla': carretilla, 'estanteria-trastero': estanteria}[nombre](dr, alto)
    im.alpha_composite(capa, (M, M))
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


def guia_colchon():
    from camas_viviendas import CAMA, sin_sangre
    cama = sin_sangre(Image.open(CAMA).convert('RGBA'))
    W = cama.width
    arriba, abajo = COLCHON
    top = cama.crop((0, arriba, W, abajo))
    tp = top.load()
    alto = CONTORNO + top.height + CUELGA + TELA + CONTORNO
    capa = Image.new('RGBA', (W, alto), (0, 0, 0, 0))
    capa.alpha_composite(top, (0, CONTORNO))
    px = capa.load()
    for x in range(W):
        c = tp[x, 0]
        if c[3]:   # el contorno de arriba, donde estaba el cabecero
            for y in range(CONTORNO):
                px[x, y] = RAYA
        c = tp[x, top.height - 1]
        if not c[3]:
            continue
        y = CONTORNO + top.height
        oscuro = c[:3] == RAYA[:3] or max(c[:3]) < 50
        for i in range(CUELGA):   # la colcha, que cuelga por delante (en sombra)
            px[x, y + i] = RAYA if oscuro else tono(c[:3], 0.72)
        for i in range(TELA):     # la tela del colchón, a rayas
            px[x, y + CUELGA + i] = RAYA if oscuro else TELA_COLOR[(x // 4) % 2] + (255,)
        for i in range(CONTORNO):
            px[x, y + CUELGA + TELA + i] = RAYA
    im = Image.new('RGBA', (W + 2 * M, alto + 2 * M), FONDO + (255,))
    im.alpha_composite(capa, (M, M))
    ruta = f'{OUT}/colchon.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    for nombre, (largo, fondo, alto) in T.items():
        guia(nombre, largo, fondo, alto)
    guia_colchon()
