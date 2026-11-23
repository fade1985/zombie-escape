"""Reduce un dibujo detallado (los zombis a escala 1, con el doble de detalle) al tamaño y el acabado de los de 48 px (a
escala 2), como pidió el dueño el 19 nov para la dependienta y el de tentáculos: del alto de Johnny y con su borde negro.

Lo usan tools/hoja_112.py y tools/zombi.py cuando la ficha del zombi trae "reducir":
  "reducir": {"casilla": [ancho, alto], "pies": [x, y], "borde": "#050202"}
  - "casilla": lo que mide la casilla nueva. Lo que se reduce sale de su ancho: ancho nuevo / ancho de la casilla grande.
  - "pies": dónde quedan los pies en la casilla nueva (la grande los tiene en su sitio de siempre).
  - "borde": el color del borde de 1 píxel por fuera de la figura (#050202, el del contorno de Johnny).
  - "realce" (si se pone true): más nítido y un poco más claro. Para dibujos con muchas rayas negras finas (el de
    tentáculos), que al mezclar colores ensucian la piel y lo dejan casi negro.
Se reduce mezclando colores, como los muebles (LANCZOS premultiplicado: el fondo transparente no tiñe los bordes), y el
borde de la figura queda sin medias tintas.
"""
from PIL import Image, ImageFilter

VECINOS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def casilla(ficha):
    c = ficha['casilla']
    return (c, c) if isinstance(c, int) else tuple(c)


def reducida(f, pies_grande, ficha):
    """Un dibujo de la casilla grande (con los pies en "pies_grande"), reducido a la casilla de "ficha" con su borde."""
    ancho, alto = casilla(ficha)
    k = ancho / f.width                            # lo que se reduce
    px_, py_ = ficha['pies']
    # el trozo del dibujo grande que cae en la casilla nueva, con los pies en su sitio (puede empezar en medio píxel)
    x0, y0 = pies_grande[0] - px_ / k, pies_grande[1] - py_ / k
    # (por si el trozo se sale un poco del dibujo grande) 8, y más solo si hace falta: al de las uñas (de 220 a 94 con
    # los pies abajo) se le salía por arriba. No se pone más a todos porque cambia un poco cómo mezcla los bordes y
    # las hojas ya hechas (el explosivo) saldrían distintas.
    aire = max(8, int(-min(x0, y0)) + 2)
    grande = Image.new('RGBA', (f.width + 2 * aire, f.height + 2 * aire), (0, 0, 0, 0))
    grande.paste(f, (aire, aire))
    caja = (x0 + aire, y0 + aire, x0 + aire + ancho / k, y0 + aire + alto / k)
    out = grande.convert('RGBa').resize((ancho, alto), Image.LANCZOS, box=caja).convert('RGBA')
    alfa = out.split()[3].point(lambda v: 255 if v > 110 else 0)
    if ficha.get('realce'):
        rgb = out.convert('RGB').filter(ImageFilter.UnsharpMask(radius=1, percent=80, threshold=2))
        out = rgb.point(lambda v: int(255 * (v / 255) ** 0.8)).convert('RGBA')
    out.putalpha(alfa)
    borde = tuple(int(ficha['borde'][i:i + 2], 16) for i in (1, 3, 5)) + (255,)
    px = out.load()
    poner = [(x, y) for y in range(alto) for x in range(ancho) if px[x, y][3] == 0 and any(
        0 <= x + a < ancho and 0 <= y + b < alto and px[x + a, y + b][3] for a, b in VECINOS)]
    for q in poner:
        px[q] = borde
    return out
