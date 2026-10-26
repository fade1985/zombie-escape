"""El helicóptero de Velaria (scripts/helicoptero.gd), al estilo de los demás dibujos.

Hasta el 26 oct estaba dibujado con rectángulos desde el código y se veía muy cuadrado. Ahora el cuerpo sale de
PixelLab con la receta de los muebles del centro comercial (tools/guias_centro.py): un boceto del helicóptero ya en
la perspectiva del juego, de lado y mirando a la izquierda, sobre azul, que PixelLab "viste". El boceto es el mismo
dibujo de antes (las mismas medidas, pasadas de los cuadraditos del código a píxeles del juego) con la tapa del
motor encima, y sin las aspas: el rotor grande y el de la cola los sigue pintando el código, girando.

En el código cada cuadradito medía 3 unidades (2 × ESCALA 1,5); el dibujo nuevo va a 2 unidades por píxel, como
todo lo demás, así que mide un 50 % más de píxeles y sale del mismo tamaño en pantalla. El boceto, al doble (cada
píxel del juego, 2×2), como siempre.

  py tools/helicoptero.py guia      → assets/sources/helicoptero/guia.png (el boceto)
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
  py tools/helicoptero.py           assets/sources/helicoptero/helicoptero.png (el elegido, sin fondo; le quita
                                    también el azul encerrado entre los patines)
                                    → assets/sprites/helicoptero.png (y luego importar en Godot); dice dónde cae
                                      el centro de la cabina, que va en ORIGEN de helicoptero.gd
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, FONDO
from importar import convierte

CARPETA = 'assets/sources/helicoptero'
GUIA = f'{CARPETA}/guia.png'
ORIGINAL = f'{CARPETA}/helicoptero.png'
SPRITE = 'assets/sprites/helicoptero.png'

C = 1.5 * S        # píxeles del boceto por cuadradito del código (1,5 píxeles del juego)
X0, Y0 = -32, -24  # la esquina de arriba a la izquierda, en cuadraditos del código (el centro de la cabina es 0, 0)
ANCHO, ALTO = 102, 44

CONTORNO = (13, 14, 18)
CHAPA = (53, 58, 69)
CHAPA_LUZ = (90, 98, 115)
CHAPA_SOMBRA = (34, 37, 45)
CRISTAL = (26, 42, 58)
REFLEJO = (109, 143, 174)
VELARIA = (95, 191, 74)
VELARIA_OSCURO = (47, 110, 42)


def guia():
    os.makedirs(os.path.dirname(GUIA), exist_ok=True)
    lado = lambda n: -(-(round(n * C) + 2 * M) // 4) * 4   # (PixelLab pide medidas múltiplos de 4)
    im = Image.new('RGBA', (lado(ANCHO), lado(ALTO)), FONDO + (255,))
    d = ImageDraw.Draw(im)

    def px(x, y, w, h, c):
        x0, y0 = M + (x - X0) * C, M + (y - Y0) * C
        d.rectangle([round(x0), round(y0), round(x0 + w * C) - 1, round(y0 + h * C) - 1], fill=c + (255,))

    def capsula(cx, cy, w, h, c):
        filas = int(h)
        for i in range(filas):
            y = (i + 0.5) / filas * 2.0 - 1.0
            medio = round(w / 2.0 * pow(1.0 - pow(abs(y), 4.0), 0.25))
            if medio > 0:
                px(cx - medio, cy - h / 2.0 + i, medio * 2, 1, c)

    # la cola: una viga que se estrecha hacia atrás, con la aleta (el rotor pequeño lo pinta el código)
    for x in range(16, 66):
        arriba = -9.0 + (x - 16) * 0.1
        abajo = 3.0 - (x - 16) * 0.12
        px(x, arriba - 1, 1, abajo - arriba + 2, CONTORNO)
        px(x, arriba, 1, abajo - arriba, CHAPA)
        px(x, arriba, 1, 1, CHAPA_LUZ)
    for i in range(8):
        px(60 + i * 0.6, -20 + i * 2, 4, 3, CONTORNO)
        px(61 + i * 0.6, -19 + i * 2, 2, 2, CHAPA)
    px(30, -6, 26, 1, VELARIA)
    px(66, -14, 4, 4, CONTORNO)   # el eje del rotor de la cola
    # los patines con sus patas
    px(-24, 13, 44, 2, CHAPA_SOMBRA)
    for x in (-14, 8):
        px(x, 9, 2, 8, CONTORNO)
    px(-28, 16, 48, 2, CONTORNO)
    px(-30, 15, 3, 2, CONTORNO)
    # la cabina: una cápsula con brillo arriba y sombra abajo
    capsula(-6, -2, 50, 26, CONTORNO)
    capsula(-6, -2, 48, 24, CHAPA)
    capsula(-8, -7, 38, 10, CHAPA_LUZ)
    px(-24, 7, 34, 3, CHAPA_SOMBRA)
    # la cristalera del morro, con un reflejo
    capsula(-22, -4, 18, 15, CONTORNO)
    capsula(-22, -4, 16, 13, CRISTAL)
    for i in range(4):
        px(-27 + i, -8 + i, 1, 1, REFLEJO)
    # la puerta con su ventanilla, la raya verde y la hoja de Velaria
    px(-6, -8, 1, 15, CHAPA_SOMBRA)
    px(10, -8, 1, 15, CHAPA_SOMBRA)
    px(-4, -7, 12, 5, CONTORNO)
    px(-3, -6, 10, 3, CRISTAL)
    px(-12, 4, 34, 1, VELARIA)
    for fila in [[-3, 1, 1], [-2, 0, 3], [-1, -1, 4], [0, -2, 5], [1, -2, 4], [2, -1, 2]]:
        px(14 + fila[1], fila[0], fila[2], 1, VELARIA)
    for x, y in [(12, 3), (13, 2), (14, 1), (15, 0)]:
        px(x, y, 1, 1, VELARIA_OSCURO)
    # la tapa del motor, encima de la cabina, por detrás del mástil
    capsula(6, -15, 28, 9, CONTORNO)
    capsula(6, -15, 26, 7, CHAPA)
    px(-5, -18, 22, 1, CHAPA_LUZ)
    for i in range(4):   # rejillas
        px(9 + i * 3, -15, 2, 2, CHAPA_SOMBRA)
    # el mástil del rotor
    px(-3, -18, 4, 4, CONTORNO)
    px(-2, -17, 2, 3, CHAPA_LUZ)
    px(-3, -21, 4, 2, CONTORNO)
    # las luces: verde en el morro, la lámpara del foco debajo
    px(-31, 2, 2, 2, (125, 255, 122))
    px(-20, 10, 4, 2, (255, 243, 196))
    im.save(GUIA)
    print(GUIA, im.size)


def huecos(fondo=(97, 123, 161)):
    """Lo que tools/guias_centro.py quita no llega: el azul que se queda encerrado debajo de la cabina, entre las
    patas de los patines. Se quita cada mancha de ese azul que sea grande y esté en la parte de abajo (las de arriba
    pueden ser brillos de la cristalera)"""
    im = Image.open(ORIGINAL).convert('RGBA')
    px = im.load()
    W, H = im.size
    visto = set()
    for y0 in range(H):
        for x0 in range(W):
            if (x0, y0) in visto or px[x0, y0][3] == 0 or sum(abs(a - b) for a, b in zip(px[x0, y0][:3], fondo)) >= 60:
                continue
            mancha, pila = [], [(x0, y0)]
            while pila:
                x, y = pila.pop()
                if (x, y) in visto or not (0 <= x < W and 0 <= y < H):
                    continue
                c = px[x, y]
                if c[3] == 0 or sum(abs(a - b) for a, b in zip(c[:3], fondo)) >= 60:
                    continue
                visto.add((x, y))
                mancha.append((x, y))
                pila += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
            if len(mancha) > 40 and sum(y for _, y in mancha) / len(mancha) > H * 0.6:
                for p in mancha:
                    px[p] = (0, 0, 0, 0)
                print('quitado el azul encerrado:', len(mancha), 'píxeles')
    im.save(ORIGINAL)


def monta():
    """El elegido (ya sin fondo) → el sprite del juego, a 2 píxeles del boceto por píxel del juego y con el contorno
    oscuro (tools/importar.py). Dice dónde cae el centro de la cabina en el sprite (ORIGEN de helicoptero.gd)"""
    caja = Image.open(ORIGINAL).getbbox()
    out = convierte(ORIGINAL, 0, bloque=S, halo=False)
    out.save(SPRITE)
    # el centro de la cabina, en píxeles del boceto, y luego en los del sprite (recortado y con 1 de contorno)
    gx, gy = M + (0 - X0) * C, M + (0 - Y0) * C
    print(SPRITE, out.size, '| ORIGEN := Vector2(%.1f, %.1f)' % ((gx - caja[0]) / S + 1, (gy - caja[1]) / S + 1))


if __name__ == '__main__':
    if sys.argv[1:2] == ['guia']:
        guia()
    else:
        huecos()
        monta()
