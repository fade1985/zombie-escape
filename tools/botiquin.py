"""El botiquín del baño (el armarito colgado de la pared, scripts/mapa/armarito.gd), al estilo de los muebles.

Hasta el 26 oct era un dibujo hecho con rectángulos (en tools/dibujos_7b.py). Ahora el cerrado, con su cruz roja, sale de
PixelLab con la receta de los muebles: un boceto ya de frente (tools/guias_botiquin.py) que PixelLab "viste", pedido al
doble del tamaño del juego (60 × 52; a tamaño del juego salió borroso) y encogido a la mitad. El abierto y vacío (las dos
puertas a los lados, el hueco oscuro y una balda) se dibuja aquí encima del cerrado ya encogido, con sus mismos colores y su
mismo contorno, para que sea la misma caja.

Se pidieron 8 versiones (fuerzas 60 y 120 × semillas 101, 202, 303 y 404; las ocho, con su fondo azul, en
assets/sources/botiquin/intentos/; el texto y los ajustes, en assets/pixellab.json → "botiquin"). El dueño eligió la 8 (fuerza 60,
semilla 404), pero sin el sombreado raro de la punta derecha de la cruz: la cruz del original mide 15 píxeles de ancho (impar)
y al encoger la última columna salía rosa; aquí se le quita (queda de 14 de ancho, 7 ya encogida).

  py tools/guias_botiquin.py               → assets/sources/centro/guias/botiquin-cerrado.png (el boceto)
  py tools/guias_centro.py quita <png>…    quita el fondo azul de lo que devuelve PixelLab
  py tools/botiquin.py                     assets/sources/botiquin/botiquin-cerrado.png (el elegido, sin fondo)
                                           → assets/sprites/armarito.png (2 fotogramas de 26 × 22, y luego importar en Godot)
"""
from PIL import Image

ORIGINAL = 'assets/sources/botiquin/botiquin-cerrado.png'
SPRITE = 'assets/sprites/armarito.png'

M, S = 4, 2           # margen del boceto y píxeles del original por píxel del juego
ANCHO, ALTO = 26, 22  # un fotograma, en píxeles del juego
ROJO = (208, 92, 89)
BLANCO = (239, 247, 245)
CONTORNO = (50, 58, 79, 255)
SOMBRA_PUERTA = (204, 210, 221, 255)
HUECO = (74, 85, 104, 255)
HUECO_ALTO = (58, 66, 86, 255)
BALDA = (200, 205, 218, 255)
BALDA_SOMBRA = (104, 113, 128, 255)


def sin_punta(im):
    """La cruz del original mide 15 de ancho (de 22 a 36): se le quita la última columna, que al encoger quedaba medio rosa"""
    px = im.load()
    for y in range(im.height):
        if px[36, y][:3] == ROJO and px[37, y][:3] == BLANCO:
            px[36, y] = BLANCO + (255,)
    return im


def encoge(im):
    """Del original (el cuadro del boceto, 52 × 44) al fotograma (26 × 22), bloque a bloque de 2 × 2: transparente si hay menos de
    2 píxeles llenos; si hay 2 o más oscuros, el contorno (el más oscuro); si no, el color medio de los claros. Así el contorno
    se queda fino y nítido en vez de teñirse de gris (con la media de todos, de siempre, quedaba borroso)"""
    im = im.crop((M, M, M + ANCHO * S, M + ALTO * S))
    px = im.load()
    out = Image.new('RGBA', (ANCHO, ALTO))
    for y in range(ALTO):
        for x in range(ANCHO):
            bloque = [px[x * S + i, y * S + j] for i in range(S) for j in range(S)]
            llenos = [p for p in bloque if p[3] > 128]
            if len(llenos) < 2:
                continue
            oscuros = [p for p in llenos if sum(p[:3]) < 225]
            if len(oscuros) >= 2:
                c = min(oscuros, key=lambda p: sum(p[:3]))
                out.putpixel((x, y), (c[0], c[1], c[2], 255))
            else:
                claros = [p for p in llenos if p not in oscuros] or llenos
                n = len(claros)
                out.putpixel((x, y), tuple(sum(p[k] for p in claros) // n for k in range(3)) + (255,))
    return out


def abierto(cerrado):
    """El cerrado, abierto y vacío: el hueco de las puertas (de 5 a 20 de ancho y de 1 a 15 de alto; el contorno de la caja, en 4
    y 21) en oscuro, con una sombra arriba y una balda, y las dos puertas abiertas a los lados (de 0 a 3 y de 22 a 25)"""
    im = cerrado.copy()
    px = im.load()
    bisagras = (3, 4, 13, 14)   # las filas donde el contorno de la caja lleva los grises de las bisagras
    for y in range(1, 16):
        for x in range(5, 21):
            px[x, y] = HUECO_ALTO if y <= 2 else HUECO
        for x in (4, 21):
            if y not in bisagras:
                px[x, y] = CONTORNO
    for x in range(5, 21):
        px[x, 8] = BALDA
        px[x, 9] = BALDA_SOMBRA
    for (x0, franja) in ((0, 2), (22, 23)):
        for y in range(0, 17):
            for x in range(x0, x0 + 4):
                borde = x in (x0, x0 + 3) or y in (0, 16)
                px[x, y] = CONTORNO if borde else (SOMBRA_PUERTA if x == franja else BLANCO + (255,))
    return im


if __name__ == '__main__':
    cerrado = encoge(sin_punta(Image.open(ORIGINAL).convert('RGBA')))
    hoja = Image.new('RGBA', (ANCHO * 2, ALTO))
    hoja.paste(cerrado, (0, 0))
    hoja.paste(abierto(cerrado), (ANCHO, 0))
    hoja.save(SPRITE)
    print(SPRITE, hoja.size)
