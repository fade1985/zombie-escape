"""Bocetos (guías) de lo que hay en el pasillo de los trasteros (el de las viviendas, viviendas.gd), para pedírselo a
PixelLab recto: cajas de cartón apiladas y una carretilla de mano cargada, todo contra la pared de arriba, de frente.

Lo mismo que tools/guias_limpieza.py (de tools/guias_centro.py salen la perspectiva, los colores de la raya y del fondo
azul y cómo se quita el fondo después). En la perspectiva del juego el suelo se ve desde arriba sin encoger y lo que
tiene altura sube hacia arriba de la pantalla, así que cada caja es su tapa (ancho × fondo) y debajo su frente
(ancho × alto); una caja encima de otra, subida lo que mide de alto la de abajo.

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
}


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


def guia(nombre, largo, fondo, alto):
    im = Image.new('RGBA', (largo * S + 2 * M, (fondo + alto) * S + 2 * M), FONDO + (255,))
    capa = Image.new('RGBA', (largo * S, (fondo + alto) * S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(capa)
    {'cajas-pila': cajas_pila, 'cajas-bajas': cajas_bajas, 'carretilla': carretilla}[nombre](dr, alto)
    im.alpha_composite(capa, (M, M))
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


if __name__ == '__main__':
    for nombre, (largo, fondo, alto) in T.items():
        guia(nombre, largo, fondo, alto)
