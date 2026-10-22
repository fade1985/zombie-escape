"""El científico de Velaria muerto (cientifico.gd): parte el dibujo de PixelLab en tres capas.

Uso:  py tools/cientifico_muerto.py

Lee assets/sources/cientifico-muerto/intento-9.png (el elegido: boca abajo, con su charco) y deja en assets/sprites/:
  cientifico-muerto.png        el cuerpo y el charco, sin la piel ni el pelo
  cientifico-muerto-piel.png   la piel (las manos) en grises: blanco = el color de la piel tal cual
  cientifico-muerto-pelo.png   el pelo (la nuca), igual
El juego pinta las dos últimas con los colores de cada página (el 'look' de historia.gd), así un solo dibujo
vale para todos.
"""
import colorsys
from PIL import Image

ORIGEN = 'assets/sources/cientifico-muerto/intento-9.png'
DESTINO = 'assets/sprites/cientifico-muerto'

TONO_PIEL = (28, 40)   # tonos carne, en grados (las manos; nada más del dibujo tiene ese color)
CABEZA = (0, 22, 15, 41)   # x0, y0, x1, y1: la cabeza, a la izquierda (el pantalón es del mismo gris que el pelo)
PELO = {(0x2e, 0x2d, 0x2d): 0.8, (0x4e, 0x4c, 0x4b): 1.0, (0x22, 0x21, 0x20): 0.6}   # sus grises: lo claro = brillo


def hsv(p):
    return colorsys.rgb_to_hsv(p[0] / 255, p[1] / 255, p[2] / 255)


def gris(v):
    g = round(max(0.0, min(1.0, v)) * 255)
    return (g, g, g, 255)


def main():
    cuerpo = Image.open(ORIGEN).convert('RGBA')
    piel = Image.new('RGBA', cuerpo.size, (0, 0, 0, 0))
    pelo = Image.new('RGBA', cuerpo.size, (0, 0, 0, 0))
    ancho, alto = cuerpo.size
    pieles = [(x, y) for y in range(alto) for x in range(ancho)
              if cuerpo.getpixel((x, y))[3] > 128 and TONO_PIEL[0] <= hsv(cuerpo.getpixel((x, y)))[0] * 360 <= TONO_PIEL[1]
              and hsv(cuerpo.getpixel((x, y)))[1] > 0.15 and hsv(cuerpo.getpixel((x, y)))[2] > 0.5]
    tope = max(hsv(cuerpo.getpixel(xy))[2] for xy in pieles)
    for xy in pieles:
        piel.putpixel(xy, gris(hsv(cuerpo.getpixel(xy))[2] / tope))
        cuerpo.putpixel(xy, (0, 0, 0, 0))
    x0, y0, x1, y1 = CABEZA
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = cuerpo.getpixel((x, y))
            if p[3] > 128 and p[:3] in PELO:
                pelo.putpixel((x, y), gris(PELO[p[:3]]))
                cuerpo.putpixel((x, y), (0, 0, 0, 0))
    # las tres capas, recortadas al mismo marco (el del dibujo entero)
    caja = Image.open(ORIGEN).getbbox()
    cuerpo.crop(caja).save(DESTINO + '.png')
    piel.crop(caja).save(DESTINO + '-piel.png')
    pelo.crop(caja).save(DESTINO + '-pelo.png')
    print('marco', caja, 'tamaño', (caja[2] - caja[0], caja[3] - caja[1]), 'piel', len(pieles))


main()
