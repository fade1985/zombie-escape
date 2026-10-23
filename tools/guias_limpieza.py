"""Bocetos (guías) de las cosas del cuarto de la limpieza de la portera (su habitación), para pedírselas a PixelLab rectas.

Lo mismo que tools/guias_gimnasio.py (de tools/guias_centro.py salen la perspectiva, los colores de la raya y del fondo
azul y cómo se quita el fondo después). Dos clases de cosas:
  - muebles, contra la pared (catalogo.gd): el contenedor de basura de la comunidad, el cubo de basura de metal y el
    carro de limpieza (este, con dibujo de lado). Lo que sobresale por encima (la fregona del carro) va subido.
  - lo que cuelga de la pared de arriba, visto de frente y plano (mapa.gd, colgados): una fregona colgada de su pinza,
    cabeza abajo, y un cubo colgado de un gancho por el asa.

  py tools/guias_limpieza.py               → assets/sources/centro/guias/<archivo>[-lado].png
  py tools/guias_centro.py quita <png>…    quita el fondo azul de lo que devuelve PixelLab
Los muebles se pasan al juego con py tools/importar.py (sus originales, en assets/sources/salas/limpieza/). Lo colgado
(sus originales, en assets/sources/limpieza/), con estos dos:
  py tools/guias_limpieza.py pared <png>…  quita el trozo de pared que PixelLab pinta detrás (después de quita)
  py tools/guias_limpieza.py colgados      → assets/sprites/colgado-fregona.png y colgado-cubo.png
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import OUT, S, M, RAYA, FONDO, tono

GRIS = (120, 124, 132)
NEGRO = (40, 40, 46)
AMARILLO = (200, 160, 40)
AZUL = (60, 100, 160)
MADERA = (150, 105, 60)
FLECOS = (205, 200, 185)
# archivo: (largo, fondo, alto, arriba, color, lleva_lado): largo y fondo en unidades (los del catálogo); alto (el
# frente) y arriba (lo que sube por detrás de la tapa), en píxeles del juego
T = {
    'contenedor':     (56, 48, 22, 0,  (55, 95, 60),   False),
    'cubo-basura':    (36, 36, 18, 0,  (150, 155, 160), False),
    'carro-limpieza': (84, 44, 20, 20, (70, 72, 80),   True),
}
# lo colgado: (ancho, alto) en píxeles del juego
COLGADOS = {
    'fregona-colgada': (12, 34),
    'cubo-colgado':    (16, 22),
}


def caja(dr, x0, y0, x1, y1, color):
    dr.rectangle((x0, y0, x1 - 1, y1 - 1), fill=color if len(color) == 4 else color + (255,), outline=RAYA)


def contenedor(dr, x, y, w, d, h, color):
    # desde arriba: la tapa, con su asa junto a la pared y las bisagras; de frente: el cuerpo con sus nervios
    caja(dr, x, y, x + w, y + d, tono(color, 1.1))
    caja(dr, x + 2 * S, y + S, x + w - 2 * S, y + 4 * S, tono(color, 0.75))                 # el asa de atrás
    for k in range(1, 4):
        dr.line((x + 2 * S, y + d * k // 4, x + w - 2 * S, y + d * k // 4), fill=tono(color, 0.9))
    caja(dr, x - S, y + d - 2 * S, x + w + S, y + d + 2 * S, tono(color, 0.8))              # el borde de la tapa
    top = y + d + 2 * S
    caja(dr, x + S, top, x + w - S, top + h, tono(color, 0.7))
    for px in range(x + 5 * S, x + w - 4 * S, 5 * S):                                        # los nervios
        caja(dr, px, top + 2 * S, px + 2 * S, top + h - 3 * S, tono(color, 0.6))
    caja(dr, x + w // 2 - 4 * S, top + 3 * S, x + w // 2 + 4 * S, top + 6 * S, (220, 220, 220))   # la pegatina


def cubo_basura(dr, x, y, w, d, h, color):
    # desde arriba: la tapa redonda con su asa; de frente: el cilindro con sus aros
    dr.rectangle((x + S, y + d // 2, x + w - S - 1, y + d // 2 + h), fill=tono(color, 0.75), outline=RAYA)
    dr.ellipse((x + S, y + d // 2 + h - d // 2, x + w - S - 1, y + d // 2 + h + d // 2), fill=tono(color, 0.75), outline=RAYA)
    dr.rectangle((x + 2 * S, y + d // 2, x + w - 2 * S - 1, y + d // 2 + h), fill=tono(color, 0.75))
    for k in (1, 2):   # los aros del cuerpo
        yy = y + d // 2 + h * k // 3
        dr.line((x + 2 * S, yy, x + w - 2 * S, yy), fill=tono(color, 0.55), width=S)
    dr.ellipse((x, y, x + w - 1, y + d), fill=tono(color, 1.15), outline=RAYA)              # la tapa
    dr.ellipse((x + 3 * S, y + 3 * S, x + w - 3 * S - 1, y + d - 3 * S), fill=tono(color, 1.0), outline=tono(color, 0.8))
    caja(dr, x + w // 2 - 3 * S, y + d // 2 - S, x + w // 2 + 3 * S, y + d // 2 + S, tono(color, 0.6))   # el asa


def carro(dr, x, y, w, d, h, a, color, lado):
    if not lado:
        top = y + a
        # el palo de la fregona (subido) y, en la tapa: el cubo amarillo con el escurridor (izquierda), botellas en medio
        # y la bolsa de basura en su aro (derecha)
        caja(dr, x + 6 * S, y, x + 8 * S, top + 8 * S, MADERA)
        caja(dr, x, top, x + w, top + d, tono(color, 1.1))
        caja(dr, x + S, top + S, x + w * 2 // 5, top + d - S, AMARILLO)
        caja(dr, x + 3 * S, top + 3 * S, x + w * 2 // 5 - 2 * S, top + d - 3 * S, (90, 95, 80))   # el agua sucia
        caja(dr, x + 2 * S, top + 2 * S, x + 12 * S, top + 7 * S, tono(GRIS, 0.9))                  # el escurridor
        for i, c in enumerate(((60, 140, 200), (200, 60, 60), (230, 230, 230))):
            bx = x + w * 2 // 5 + 2 * S + i * 4 * S
            caja(dr, bx, top + 3 * S, bx + 3 * S, top + 7 * S, c)
        caja(dr, x + w * 3 // 4, top + S, x + w - S, top + d - S, (35, 35, 40))                  # la bolsa negra
        caja(dr, x, top + d, x + w, top + d + h, tono(color, 0.75))                                # el frente
        caja(dr, x + w * 2 // 5 + S, top + d + 3 * S, x + w * 3 // 4 - S, top + d + h - 5 * S, tono(color, 0.5))   # la balda
        caja(dr, x + S, top + d + 2 * S, x + w * 2 // 5 - S, top + d + h - 4 * S, tono(AMARILLO, 0.8))
        caja(dr, x + w * 3 // 4, top + d, x + w - S, top + d + h - 3 * S, (35, 35, 40))
        for px in (x + 2 * S, x + w - 6 * S):                                                      # las ruedas
            caja(dr, px, top + d + h - 3 * S, px + 4 * S, top + d + h, NEGRO)
    else:
        # tumbado a lo largo de la pared (la izquierda): la tapa, de fondo × largo, y debajo su costado corto
        top = y + a
        caja(dr, x, top, x + w, top + d, tono(color, 1.1))
        caja(dr, x + S, top + S, x + w - S, top + d * 2 // 5, AMARILLO)
        caja(dr, x + 3 * S, top + 3 * S, x + w - 3 * S, top + d * 2 // 5 - 2 * S, (90, 95, 80))
        caja(dr, x + 2 * S, top + 2 * S, x + 7 * S, top + 12 * S, tono(GRIS, 0.9))
        for i, c in enumerate(((60, 140, 200), (200, 60, 60), (230, 230, 230))):
            by = top + d * 2 // 5 + 2 * S + i * 4 * S
            caja(dr, x + 4 * S, by, x + 8 * S, by + 3 * S, c)
        caja(dr, x + S, top + d * 3 // 4, x + w - S, top + d - S, (35, 35, 40))
        caja(dr, x + w // 2 - S, y, x + w // 2 + S, top + 6 * S, MADERA)                          # el palo de la fregona
        caja(dr, x, top + d, x + w, top + d + h, tono(color, 0.75))                                # el costado corto
        caja(dr, x + S, top + d + 2 * S, x + w - S, top + d + h - 4 * S, (35, 35, 40))
        for px in (x + S, x + w - 5 * S):
            caja(dr, px, top + d + h - 3 * S, px + 4 * S, top + d + h, NEGRO)


def fregona(dr, x, y, w, h):
    # la pinza en la pared, el palo de madera hacia abajo y la cabeza de flecos colgando
    cx = x + w // 2
    caja(dr, cx - 3 * S, y, cx + 3 * S, y + 3 * S, tono(GRIS, 0.8))
    caja(dr, cx - S, y + S, cx + S, y + h - 12 * S, MADERA)
    caja(dr, cx - 2 * S, y + h - 13 * S, cx + 2 * S, y + h - 11 * S, tono(GRIS, 1.1))           # el casquillo
    dr.polygon([(cx - 2 * S, y + h - 11 * S), (cx + 2 * S, y + h - 11 * S), (x + w, y + h), (x, y + h)],
               fill=FLECOS + (255,), outline=RAYA)
    for k in range(1, 6):
        xx = x + w * k // 6
        dr.line((cx, y + h - 10 * S, xx, y + h - S), fill=tono(FLECOS, 0.75))


def cubo_colgado(dr, x, y, w, h):
    # el gancho, el asa en arco y el cubo de plástico de frente (más ancho arriba)
    cx = x + w // 2
    caja(dr, cx - S, y, cx + S, y + 3 * S, tono(GRIS, 0.8))
    dr.arc((x + S, y + 2 * S, x + w - S, y + 14 * S), 180, 360, fill=RAYA, width=S)
    top = y + 8 * S
    dr.polygon([(x, top), (x + w, top), (x + w - 2 * S, y + h), (x + 2 * S, y + h)], fill=AZUL + (255,), outline=RAYA)
    caja(dr, x, top, x + w, top + 2 * S, tono(AZUL, 1.25))                                       # el borde
    dr.line((x + 2 * S, top + 7 * S, x + w - 2 * S, top + 7 * S), fill=tono(AZUL, 0.7), width=S)


def guia(nombre, largo, fondo, alto, arriba, color, lado):
    w = (fondo if lado else largo) // 2 * S
    d = (largo if lado else fondo) // 2 * S
    h = alto * S
    a = arriba * S
    im = Image.new('RGBA', (w + 2 * M, a + d + h + 2 * M + 2 * S), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    x, y = M, M
    if nombre == 'contenedor':
        contenedor(dr, x, y, w, d, h, color)
    elif nombre == 'cubo-basura':
        cubo_basura(dr, x, y, w, d, h, color)
    elif nombre == 'carro-limpieza':
        carro(dr, x, y, w, d, h, a, color, lado)
    guardar(im, f'{nombre}{"-lado" if lado else ""}')


def guia_colgado(nombre, ancho, alto):
    w, h = ancho * S, alto * S
    im = Image.new('RGBA', (w + 2 * M, h + 2 * M), FONDO + (255,))
    dr = ImageDraw.Draw(im)
    if nombre == 'fregona-colgada':
        fregona(dr, M, M, w, h)
    else:
        cubo_colgado(dr, M, M, w, h)
    guardar(im, nombre)


def guardar(im, nombre):
    # PixelLab pide como poco 32 × 32 de área: lo que no llegue, con más azul alrededor
    W, H = im.size
    if W * H < 1024 or W < 16 or H < 16:
        W2, H2 = max(W, 32), max(H, 32)
        grande = Image.new('RGBA', (W2, H2), FONDO + (255,))
        grande.paste(im, ((W2 - W) // 2, (H2 - H) // 2))
        im = grande
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/{nombre}.png'
    im.save(ruta)
    print(ruta, im.size)


def quita_pared(ruta):
    """Desde lo ya transparente, se come el trozo de pared gris azulado que PixelLab pinta detrás de lo colgado (claro,
    poco saturado y más azul que rojo) y la sombra azulada que deja alrededor (oscura, más azul que roja y sin ser el
    negro del contorno). Se para en el contorno oscuro, así que no toca el cubo azul"""
    im = Image.open(ruta).convert('RGBA')
    px = im.load()
    W, H = im.size
    def es_pared(c):
        r, g, b, a = c
        if a == 0:
            return True
        mx, mn = max(r, g, b), min(r, g, b)
        return (b - r > 12 and mx > 90 and (mx - mn) / mx < 0.42) or (b - r > 22 and b > 70 and mx <= 130)
    pila = [(x, y) for y in range(H) for x in range(W) if px[x, y][3] == 0]
    visto = set()
    while pila:
        x, y = pila.pop()
        if (x, y) in visto or not (0 <= x < W and 0 <= y < H):
            continue
        visto.add((x, y))
        if es_pared(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            pila += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    im.save(ruta)
    print('sin pared:', ruta)


def colgados():
    """Lo colgado, ya sin fondo → sprite del juego: a la mitad (PixelLab lo dibuja al doble, como la guía) y con el
    contorno de los muebles (la receta de tools/importar.py)"""
    from importar import convierte
    for nombre in COLGADOS:
        src = f'assets/sources/limpieza/{nombre}.png'
        x0, _, x1, _ = Image.open(src).getbbox()
        im = convierte(src, round((x1 - x0) / 2) + 2, halo=False)
        ruta = f'assets/sprites/colgado-{nombre.split("-")[0]}.png'   # colgado-fregona, colgado-cubo
        im.save(ruta)
        print(ruta, im.size)


if __name__ == '__main__':
    if sys.argv[1:2] == ['pared']:
        for r in sys.argv[2:]:
            quita_pared(r)
        sys.exit()
    if sys.argv[1:2] == ['colgados']:
        colgados()
        sys.exit()
    for nombre, (largo, fondo, alto, arriba, color, con_lado) in T.items():
        guia(nombre, largo, fondo, alto, arriba, color, False)
        if con_lado:
            guia(nombre, largo, fondo, alto, arriba, color, True)
    for nombre, (ancho, alto) in COLGADOS.items():
        guia_colgado(nombre, ancho, alto)
