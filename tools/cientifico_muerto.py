"""El científico de Velaria muerto (cientifico.gd): parte el dibujo de PixelLab en tres capas.

Uso:  py tools/cientifico_muerto.py

Lee assets/sources/cientifico-muerto/intento-3.png (el elegido) y deja en assets/sprites/:
  cientifico-muerto.png        el cuerpo, sin la piel ni el pelo
  cientifico-muerto-piel.png   la piel (cara y mano) en grises: blanco = el color de la piel tal cual
  cientifico-muerto-pelo.png   el pelo, igual
El juego pinta las dos últimas con los colores de cada página (el 'look' de historia.gd), así un solo dibujo
vale para todos. La cara de PixelLab salía como una calavera gris: se redibuja aquí a mano (CABEZA).
"""
from PIL import Image

ORIGEN = 'assets/sources/cientifico-muerto/intento-3.png'
DESTINO = 'assets/sprites/cientifico-muerto'
CONTORNO = (10, 8, 7, 255)

# La cabeza, tumbada con la coronilla a la izquierda y la cara mirando arriba. Empieza en el píxel (7, 24).
# a contorno · H pelo · h pelo en sombra · S piel · s piel en sombra · e ojo cerrado · espacio: no se toca
CABEZA = [
    '  aaaaa',
    ' aHHHhS',
    'aHHhSSS',
    'aHHhSeS',
    'aHHhSSs',
    'aHHhSeS',
    'aHhSSss',
    ' ahSssa',
]
CABEZA_EN = (7, 24)
GRIS = {'H': 1.0, 'h': 0.68, 'S': 1.0, 's': 0.8, 'e': 0.42}

# La mano que asoma por la manga, abajo: la piel se saca de sus grises (lo más claro = blanco)
MANO = (19, 42, 29, 48)   # x0, y0, x1, y1 (sin incluir los dos últimos)


def luz(p):
    return (p[0] * 0.3 + p[1] * 0.59 + p[2] * 0.11) / 255


def gris(v):
    g = round(max(0.0, min(1.0, v)) * 255)
    return (g, g, g, 255)


def main():
    cuerpo = Image.open(ORIGEN).convert('RGBA')
    piel = Image.new('RGBA', cuerpo.size, (0, 0, 0, 0))
    pelo = Image.new('RGBA', cuerpo.size, (0, 0, 0, 0))
    # la cabeza, redibujada
    for j, fila in enumerate(CABEZA):
        for i, c in enumerate(fila):
            xy = (CABEZA_EN[0] + i, CABEZA_EN[1] + j)
            if c == ' ':
                continue
            cuerpo.putpixel(xy, CONTORNO if c == 'a' else (0, 0, 0, 0))
            if c in 'Hh':
                pelo.putpixel(xy, gris(GRIS[c]))
            elif c in 'Sse':
                piel.putpixel(xy, gris(GRIS[c]))
    # la mano: lo que no es contorno
    x0, y0, x1, y1 = MANO
    trozo = [(x, y) for y in range(y0, y1) for x in range(x0, x1)
             if cuerpo.getpixel((x, y))[3] and luz(cuerpo.getpixel((x, y))) > 0.12]
    tope = max(luz(cuerpo.getpixel(xy)) for xy in trozo)
    for xy in trozo:
        piel.putpixel(xy, gris(0.45 + 0.55 * luz(cuerpo.getpixel(xy)) / tope))
        cuerpo.putpixel(xy, (0, 0, 0, 0))
    # las tres capas, recortadas al mismo marco
    caja = cuerpo.getbbox()
    for capa in (piel, pelo):
        b = capa.getbbox()
        caja = (min(caja[0], b[0]), min(caja[1], b[1]), max(caja[2], b[2]), max(caja[3], b[3]))
    cuerpo.crop(caja).save(DESTINO + '.png')
    piel.crop(caja).save(DESTINO + '-piel.png')
    pelo.crop(caja).save(DESTINO + '-pelo.png')
    print('marco', caja, 'tamaño', (caja[2] - caja[0], caja[3] - caja[1]))


main()
