"""Los trasteros del edificio, donde viven los supervivientes rescatados (las habitaciones de las viviendas, viviendas.gd):
como los de la foto del dueño, de chapa metálica acanalada color crema, con el suelo de hormigón pulido gris azulado
claro y las puertas azules lisas con el pomo de metal. Todo dibujado aquí, a la densidad de los personajes (cada píxel,
2 unidades del juego), sin costuras, y vieja (grano, mugre, óxido, juntas y grietas: que no parezca de plástico):

  py tools/trastero.py   → assets/sprites/suelo-trastero.png    el suelo (128 × 128, se repite)
                           assets/sprites/pared-trastero.png    la cara de la pared de arriba (192 × 48, se repite a lo largo)
                           assets/sprites/techo-trastero.png    su moldura de arriba: el perfil de chapa galvanizada (192 × 6)
                           assets/sprites/pared-trastero-pasillo.png   la del pasillo de los trasteros: la misma chapa, con
                                                                       una franja de chapa lagrimada abajo (192 × 48)
                           assets/sprites/linea-trastero.png    la línea amarilla pintada a lo largo del suelo del pasillo
                                                                (128 × 3, se repite; la pinta mapa.gd)
                           assets/sprites/puerta-trastero.png   la hoja cerrada, de frente (28 × 43, como puerta-bano)
                           assets/sprites/puerta-trastero-abierta.png   abierta del todo, de frente (14 × 67, como
                                                                        puerta-bano-abierta: su forma, repintada)
                           assets/sprites/puerta-trastero-lado-cerrada.png   la cerrada en un tabique de lado (16 × 32,
                                                                             puerta-bano-lado-cerrada repintada)
                           assets/sprites/puerta-trastero-abierta-lado.png   y abierta del todo (14 × 67,
                                                                             puerta-bano-abierta-lado repintada)

Luego, en Godot: --headless --path . --import
"""
import colorsys, math, random
from PIL import Image

SALIDA = 'assets/sprites'
LINEA = (29, 27, 44)      # el contorno de siempre

# ── El suelo: hormigón pulido gris azulado claro, con manchas suaves y alguna motita ──
SUELO = 128
SUELO_TONOS = [(126, 131, 140), (134, 139, 147), (141, 146, 153), (149, 153, 159)]   # gris de hormigón, de oscuro a claro
MOTA_CLARA = (166, 170, 175)
MOTA_OSCURA = (106, 110, 118)
ACEITE = (78, 80, 88)             # la mancha de aceite
ROZADURA = (92, 94, 102)          # las de las ruedas
GRIETA = (84, 87, 96)
JUNTA = (70, 72, 82)              # el corte de la junta de dilatación
JUNTA_CANTO = (164, 168, 174)     # y su canto, con luz

# ── La pared: chapa acanalada crema; cada canal, PERIODO píxeles (16: una casilla), con su nervio ──
PARED_ANCHO, PARED_ALTO = 192, 48
PERIODO = 16
CREMA = (222, 216, 199)          # el liso de la chapa
CREMA_MOTA = (210, 204, 187)     # el grano del liso (que no quede de plástico): lo oscuro...
CREMA_CLARO = (229, 224, 209)    # ...y lo claro
PLANCHA = 64                     # cada plancha de chapa, de ancho (cuatro canales; 192 = tres)
NERVIO_LUZ = (240, 236, 222)     # el lado del nervio que da a la luz (la izquierda)
NERVIO_SOMBRA = (172, 166, 150)  # el lado en sombra
NERVIO_HONDO = (146, 140, 126)   # el pie del nervio, el más oscuro
JUNTO_NERVIO = (196, 190, 173)   # el liso pegado a la sombra del nervio
TORNILLO = (120, 116, 106)
SUCIO = (150, 142, 124)          # la mugre que sube del suelo
SUCIO_HONDO = (124, 116, 100)    # sus chorretones y los roces
OXIDO = (150, 88, 48)            # el que chorrea de los tornillos
# el perfil de abajo (de chapa galvanizada, como el de arriba): de arriba abajo
RODAPIE = [(96, 100, 110), (184, 190, 199), (156, 162, 172), (118, 124, 134)]
# ── La chapa lagrimada de abajo de la pared del pasillo (la de la foto): acero galvanizado con su relieve de rombos ──
LAGRIMADA = 14                   # lo que sube desde el suelo, en píxeles
LAGRIMADA_TONOS = [(146, 152, 162), (152, 158, 168)]   # el liso (dos, muy juntos, a manchas)
LAGRIMA_LUZ = (196, 202, 211)    # el relieve: la cara que da a la luz
LAGRIMA_SOMBRA = (110, 116, 127) # y su sombrita, debajo
LAGRIMADA_FILO = [(98, 102, 112), (204, 210, 218), (170, 176, 186)]   # el canto de arriba, doblado: junta, filo con luz y bajada
LAGRIMADA_PIE = (96, 100, 110)   # la última fila, en la sombra del suelo
# ── La línea amarilla del suelo del pasillo: pintura vieja, gastada a trozos ──
LINEA_ANCHO, LINEA_ALTO = 128, 3
PINTURA = [(214, 172, 58), (224, 186, 82), (190, 150, 52)]   # la de siempre, la gastada (más clara) y la sucia
# ── La moldura de arriba: el perfil galvanizado que remata la chapa, de arriba abajo ──
TECHO = [(92, 96, 106), (198, 204, 212), (174, 180, 189), (152, 158, 168), (126, 132, 142), (98, 102, 112)]

# ── La puerta: azul liso (pintura en polvo, como la de la foto) ──
AZUL = (52, 104, 160)
AZUL_LUZ = (86, 138, 190)
AZUL_SOMBRA = (38, 80, 128)
AZUL_HONDO = (26, 54, 92)
AZUL_CANTO = (120, 164, 206)     # el canto, con luz
MARCO = [(40, 52, 78), (28, 36, 58)]   # las dos columnas oscuras de los lados de la hoja cerrada
METAL = [(222, 226, 232), (170, 177, 188), (112, 118, 130)]   # el pomo y su placa: brillo, medio y sombra


def ruido_toro(tam, celda, rng):
    """Ruido suave que casa por los cuatro lados: una rejilla de valores al azar (con la vuelta) interpolada"""
    n = tam // celda
    rejilla = [[rng.random() for _ in range(n)] for _ in range(n)]
    def suave(t):
        return t * t * (3 - 2 * t)
    valores = []
    for y in range(tam):
        fila = []
        for x in range(tam):
            gx, gy = x / celda, y / celda
            x0, y0 = int(gx) % n, int(gy) % n
            x1, y1 = (x0 + 1) % n, (y0 + 1) % n
            tx, ty = suave(gx - int(gx)), suave(gy - int(gy))
            a = rejilla[y0][x0] * (1 - tx) + rejilla[y0][x1] * tx
            b = rejilla[y1][x0] * (1 - tx) + rejilla[y1][x1] * tx
            fila.append(a * (1 - ty) + b * ty)
        valores.append(fila)
    return valores


def mezcla(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def suelo():
    """Hormigón de verdad: el gris de fondo a manchas grandes (cuatro tonos, con el paso de uno a otro tramado para que
    no se vean escalones), el árido en motitas, la junta de dilatación cortada en los bordes (cada 128 píxeles, 4
    casillas: el suelo hecho por losas) con el canto algo desconchado, una grieta fina que sale de la junta, una mancha
    de aceite vieja y rozaduras oscuras de los carros. Todo casa por los cuatro lados"""
    rng = random.Random(14)
    grande = ruido_toro(SUELO, 32, rng)
    medio = ruido_toro(SUELO, 16, rng)
    chico = ruido_toro(SUELO, 4, rng)
    im = Image.new('RGB', (SUELO, SUELO))
    px = im.load()
    for y in range(SUELO):
        for x in range(SUELO):
            v = grande[y][x] * 0.6 + medio[y][x] * 0.25 + chico[y][x] * 0.15
            v += (rng.random() - 0.5) * 0.08   # el tramado entre tonos
            px[x, y] = SUELO_TONOS[0 if v < 0.36 else 1 if v < 0.52 else 2 if v < 0.68 else 3]
    # el árido: motitas claras y oscuras, alguna de dos píxeles
    for _ in range(260):
        x, y = rng.randrange(SUELO), rng.randrange(SUELO)
        c = MOTA_CLARA if rng.random() < 0.55 else MOTA_OSCURA
        px[x, y] = c
        if rng.random() < 0.2:
            px[(x + 1) % SUELO, y] = c
    # la mancha de aceite, vieja: un borrón oscuro de borde irregular, más oscuro por dentro
    cx, cy = 84, 40
    for y in range(-12, 13):
        for x in range(-16, 17):
            d = (x / 16) ** 2 + (y / 11) ** 2 + (chico[(cy + y) % SUELO][(cx + x) % SUELO] - 0.5) * 0.9
            if d < 1:
                p = ((cx + x) % SUELO, (cy + y) % SUELO)
                px[p] = mezcla(px[p], ACEITE, 0.4 if d < 0.45 else 0.22)
    # rozaduras de ruedas: trazos cortos y finos en horizontal, apenas más oscuros
    for _ in range(7):
        x, y = rng.randrange(SUELO), rng.randrange(SUELO)
        for k in range(rng.randint(6, 16)):
            p = ((x + k) % SUELO, (y + (k // 7)) % SUELO)
            if rng.random() < 0.8:
                px[p] = mezcla(px[p], ROZADURA, 0.5)
    # la grieta: sale de la junta de arriba y baja serpenteando, cada vez más fina (con su labio claro al lado)
    x, y = 30, 1
    for paso in range(46):
        px[x % SUELO, y] = GRIETA
        if paso < 30 and rng.random() < 0.5:
            px[(x + 1) % SUELO, y] = mezcla(px[(x + 1) % SUELO, y], MOTA_CLARA, 0.6)
        y += 1
        x += rng.choice((-1, 0, 0, 1))
        if paso > 34 and rng.random() < 0.5:
            y += 1
    # la junta de dilatación, en el borde de arriba y en el de la izquierda: el corte oscuro y, al lado, el canto con luz
    for i in range(SUELO):
        px[i, 0] = JUNTA
        px[0, i] = JUNTA
        px[i, 1] = mezcla(px[i, 1], JUNTA_CANTO, 0.6)
        px[1, i] = mezcla(px[1, i], JUNTA_CANTO, 0.6)
        px[i, SUELO - 1] = mezcla(px[i, SUELO - 1], JUNTA, 0.35)   # la sombra del otro canto
        px[SUELO - 1, i] = mezcla(px[SUELO - 1, i], JUNTA, 0.35)
    # algún desconchón en el canto de la junta
    for _ in range(6):
        k = rng.randrange(4, SUELO - 4)
        for d in range(rng.randint(1, 3)):
            if rng.random() < 0.5:
                px[k + d, 1] = JUNTA
                px[k + d, 2] = mezcla(px[k + d, 2], JUNTA, 0.5)
            else:
                px[1, k + d] = JUNTA
                px[2, k + d] = mezcla(px[2, k + d], JUNTA, 0.5)
    im.save(f'{SALIDA}/suelo-trastero.png')


def pared(lagrimada=False):
    """La cara de la pared de chapa acanalada, vieja: cada plancha (PLANCHA píxeles de ancho) con su tono, algo distinto
    del de al lado, y la junta donde una monta sobre la otra, con su fila de tornillos; el liso con grano; arriba, la
    sombra del perfil; abajo, la mugre que sube del suelo a manchas, con chorretones; el óxido que chorrea de algunos
    tornillos; y algún roce y algún bollo. La del pasillo (lagrimada) lleva abajo, en vez del perfil, una franja de
    chapa lagrimada que sube LAGRIMADA píxeles, como las de los pasillos de trasteros de verdad: que no se raye la chapa
    con los carros y las cajas"""
    rng = random.Random(7)
    im = Image.new('RGB', (PARED_ANCHO, PARED_ALTO))
    px = im.load()
    chapa = PARED_ALTO - (LAGRIMADA if lagrimada else len(RODAPIE))
    grano = ruido_toro(PARED_ANCHO, 4, rng)
    manchas = ruido_toro(PARED_ANCHO, 16, rng)
    tonos = [1.0, 0.965, 1.015]   # el de cada plancha
    for x in range(PARED_ANCHO):
        k = x % PERIODO
        tono = tonos[(x // PLANCHA) % len(tonos)]
        for y in range(chapa):
            # el nervio, en las últimas columnas de cada canal: luz a la izquierda, sombra a la derecha
            if k == 11:
                c = NERVIO_LUZ
            elif k in (12, 13):
                c = CREMA
            elif k == 14:
                c = NERVIO_SOMBRA
            elif k == 15:
                c = NERVIO_HONDO
            elif k == 0:
                c = JUNTO_NERVIO
            else:
                g = grano[y % PARED_ANCHO][x]
                c = CREMA_MOTA if g < 0.3 else CREMA_CLARO if g > 0.78 else CREMA
            c = tuple(min(255, round(v * tono)) for v in c)
            # la sombra del perfil de arriba, que se va en tres filas
            if y < 3:
                c = mezcla(c, NERVIO_HONDO, (0.5, 0.25, 0.1)[y])
            # la mugre de abajo: sube más donde hay mancha, y se apaga hacia arriba
            alto = 6 + manchas[(y * 3) % PARED_ANCHO][x] * 12
            sube = chapa - 1 - y
            if sube < alto:
                c = mezcla(c, SUCIO, 0.55 * (1 - sube / alto) ** 1.4)
            px[x, y] = c
        if not lagrimada:
            for i, c in enumerate(RODAPIE):
                px[x, chapa + i] = c
    # la junta de cada plancha: el canto de la de encima, con luz, y su sombra en la de debajo
    for x0 in range(0, PARED_ANCHO, PLANCHA):
        for y in range(chapa):
            px[x0, y] = mezcla(px[x0, y], NERVIO_LUZ, 0.6)
            px[(x0 + 1) % PARED_ANCHO, y] = mezcla(px[(x0 + 1) % PARED_ANCHO, y], NERVIO_HONDO, 0.55)
        for y in range(5, chapa - 3, 9):   # sus tornillos, a lo alto
            px[(x0 + 3) % PARED_ANCHO, y] = TORNILLO
    # los tornillos, arriba y abajo, en medio del liso de cada canal; de algunos chorrea óxido
    for x in range(5, PARED_ANCHO, PERIODO):
        for y in (4, chapa - 4):
            px[x, y] = TORNILLO
            if rng.random() < 0.35:
                largo = rng.randint(2, 7)
                for d in range(1, largo + 1):
                    if y + d < chapa:
                        px[x, y + d] = mezcla(px[x, y + d], OXIDO, 0.55 * (1 - d / (largo + 1)) + 0.1)
    # chorretones de mugre que suben desde el suelo
    for _ in range(14):
        x = rng.randrange(PARED_ANCHO)
        if x % PERIODO in (11, 14, 15):
            continue
        for y in range(chapa - 1, chapa - 1 - rng.randint(4, 14), -1):
            if rng.random() < 0.75:
                px[x, y] = mezcla(px[x, y], SUCIO_HONDO, 0.6)
    # roces: rayas horizontales cortas a media altura (cajas y carros), oscuras con un filo claro encima
    for _ in range(5):
        x, y = rng.randrange(PARED_ANCHO - 14), rng.randrange(chapa // 2, chapa - 6)
        for d in range(rng.randint(5, 14)):
            px[x + d, y] = mezcla(px[x + d, y], SUCIO_HONDO, 0.45)
            px[x + d, y - 1] = mezcla(px[x + d, y - 1], NERVIO_LUZ, 0.4)
    # un par de bollos: una sombra curva con su luz al otro lado
    for bx, by in ((40, chapa - 12), (150, chapa - 16)):
        for d in range(-3, 4):
            px[bx + d, by - 2 + abs(d) // 2] = mezcla(px[bx + d, by - 2 + abs(d) // 2], NERVIO_HONDO, 0.45)
            px[bx + d, by + 2 - abs(d) // 2] = mezcla(px[bx + d, by + 2 - abs(d) // 2], NERVIO_LUZ, 0.45)
    if lagrimada:
        lagrimas(px, chapa, rng)
        im.save(f'{SALIDA}/pared-trastero-pasillo.png')
        return
    im.save(f'{SALIDA}/pared-trastero.png')
    techo = Image.new('RGB', (PARED_ANCHO, len(TECHO)))
    tp = techo.load()
    for x in range(PARED_ANCHO):
        for y, c in enumerate(TECHO):
            tp[x, y] = c
    # las juntas del perfil, cada dos canales
    for x in range(0, PARED_ANCHO, PERIODO * 2):
        for y in range(1, len(TECHO) - 1):
            tp[x, y] = TECHO[-1]
    techo.save(f'{SALIDA}/techo-trastero.png')


def lagrimas(px, y0, rng):
    """La franja de chapa lagrimada, de y0 al suelo: el canto doblado arriba, el liso a manchas y el relieve, rayitas
    de 2 píxeles en diagonal, una "\\" y una "/" al tresbolillo (cada 8 a lo ancho, que casa con los 192 de la pared),
    cada una con su luz y, debajo, su sombrita"""
    manchas = ruido_toro(PARED_ANCHO, 16, rng)
    for x in range(PARED_ANCHO):
        for i, c in enumerate(LAGRIMADA_FILO):
            px[x, y0 + i] = c
        for y in range(y0 + len(LAGRIMADA_FILO), PARED_ALTO - 1):
            px[x, y] = LAGRIMADA_TONOS[manchas[y % PARED_ANCHO][x] > 0.5]
        px[x, PARED_ALTO - 1] = LAGRIMADA_PIE
    arriba = y0 + len(LAGRIMADA_FILO) + 1
    for fila, y in enumerate(range(arriba, PARED_ALTO - 3, 3)):
        for x in range(1 if fila % 2 == 0 else 5, PARED_ANCHO, 8):
            if fila % 2 == 0:   # "\"
                luces, sombras = [(x, y), (x + 1, y + 1)], [(x, y + 1), (x + 1, y + 2)]
            else:               # "/"
                luces, sombras = [(x + 1, y), (x, y + 1)], [(x + 1, y + 1), (x, y + 2)]
            for p in sombras:
                px[p] = LAGRIMA_SOMBRA
            for p in luces:
                px[p] = LAGRIMA_LUZ
    # algún roce oscuro de los carros, a la altura de las ruedas
    for _ in range(10):
        x, y = rng.randrange(PARED_ANCHO - 6), rng.randrange(PARED_ALTO - 7, PARED_ALTO - 2)
        for k in range(rng.randint(2, 6)):
            px[x + k, y] = LAGRIMA_SOMBRA


def linea():
    """La línea amarilla pintada a lo largo del suelo del pasillo, como en un garaje: tres filas de pintura gastada, con
    algún trozo levantado (transparente: se ve el hormigón) y alguno sucio, más en los bordes que en medio"""
    rng = random.Random(3)
    im = Image.new('RGBA', (LINEA_ANCHO, LINEA_ALTO), (0, 0, 0, 0))
    px = im.load()
    for x in range(LINEA_ANCHO):
        for y in range(LINEA_ALTO):
            borde = y != 1
            r = rng.random()
            if r < (0.1 if borde else 0.03):
                continue   # levantada
            c = PINTURA[1] if r < 0.2 else PINTURA[2] if r < (0.3 if borde else 0.24) else PINTURA[0]
            px[x, y] = c + (255,)
    im.save(f'{SALIDA}/linea-trastero.png')


def puerta_cerrada():
    """La hoja cerrada de frente, con la misma forma que puerta-bano (28 × 43): el contorno y las dos columnas oscuras de
    los lados se quedan; la hoja, azul lisa con su bisel (luz arriba y a la izquierda, sombra abajo y a la derecha); y
    el pomo, de metal, sobre una placa como la de la foto, donde el de la de madera"""
    base = Image.open(f'{SALIDA}/puerta-bano.png').convert('RGBA')
    im = Image.new('RGBA', base.size, (0, 0, 0, 0))
    px, bp = im.load(), base.load()
    W, H = base.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = bp[x, y]
            if a == 0:
                continue
            if (r, g, b) == LINEA:
                px[x, y] = bp[x, y]
            elif x in (1, W - 2) or y == 1:
                px[x, y] = MARCO[0] + (255,)
            elif x in (2, W - 3) or y == 2:
                px[x, y] = MARCO[1] + (255,)
            elif y == H - 1:
                px[x, y] = AZUL_HONDO + (255,)   # el pie de la hoja
            elif y == 3 or x == 3:
                px[x, y] = AZUL_LUZ + (255,)
            elif y == H - 2 or x == W - 4:
                px[x, y] = AZUL_SOMBRA + (255,)
            else:
                px[x, y] = AZUL + (255,)
    # la placa del pomo (2 × 7) y el pomo, que sobresale a su izquierda
    for y in range(18, 25):
        px[W - 6, y] = METAL[1] + (255,)
        px[W - 5, y] = METAL[2] + (255,)
    px[W - 6, 18] = METAL[0] + (255,)
    for x, y, c in ((W - 8, 21, METAL[0]), (W - 7, 21, METAL[1]), (W - 8, 22, METAL[1]), (W - 7, 22, METAL[2])):
        px[x, y] = c + (255,)
    im.save(f'{SALIDA}/puerta-trastero.png')


def puerta_abierta():
    """Abierta del todo, de frente: el dibujo de puerta-bano-abierta (la hoja casi de canto, con su canto, su pomo y su
    sombra) repintado. La madera tiene molduras (rayas claras y oscuras, y algún píxel de contorno por dentro): todo lo
    de dentro de la hoja pasa a ser del mismo azul, liso. Se quedan el contorno de fuera, la sombra del suelo, el canto
    (con luz) y el pomo (de metal)"""
    im = Image.open(f'{SALIDA}/puerta-bano-abierta.png').convert('RGBA')
    orig = im.copy().load()
    px = im.load()

    def lleno(x, y):
        return 0 <= x < im.width and 0 <= y < im.height and orig[x, y][3] == 255

    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 255:
                continue   # la sombra del suelo, como está
            borde = not all(lleno(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if (r, g, b) == LINEA:
                if not borde:
                    px[x, y] = AZUL + (255,)   # el contorno de las molduras, por dentro de la hoja
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            canto = x >= im.width - 2   # las dos columnas de la derecha: el canto, que da a la luz
            if 0.08 < h < 0.2 and s > 0.35 and l > 0.45 and not canto:
                c = METAL[0]   # el pomo de latón
            elif canto and l > 0.36:
                c = AZUL_CANTO if l > 0.46 else AZUL_LUZ
            elif x <= 2 and l > 0.36:
                c = AZUL_LUZ   # el filo de las bisagras, con algo de luz (como el de la cerrada)
            elif borde and l < 0.18:
                c = AZUL_SOMBRA
            else:
                c = AZUL
            px[x, y] = c + (255,)
    im.save(f'{SALIDA}/puerta-trastero-abierta.png')


def es_laton(r, g, b):
    """El pomo de latón de las de madera: amarillento, saturado y claro"""
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return 0.08 < h < 0.2 and s > 0.35 and l > 0.45


def puerta_lado_cerrada():
    """Cerrada, en un tabique de lado (la del fondo del pasillo): el tablón de puerta-bano-lado-cerrada (16 × 32) repintado.
    El contorno y la sombra del suelo se quedan; la madera, con sus vetas y nudos, pasa a azul liso con su luz a la
    izquierda y su sombra a la derecha; y el pomo, que sobresale por los dos lados del tablón, de metal (brillo arriba)"""
    im = Image.open(f'{SALIDA}/puerta-bano-lado-cerrada.png').convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] < 255 or px[x, y][:3] == LINEA:
                continue
            if x < 6 or x > 8:
                c = METAL[0] if px[x, y - 1][:3] == LINEA else METAL[1]   # el pomo, a los lados del tablón
            else:
                c = AZUL_LUZ if x == 6 else AZUL_SOMBRA if x == 8 else AZUL
            px[x, y] = c + (255,)
    im.save(f'{SALIDA}/puerta-trastero-lado-cerrada.png')


def puerta_lado_abierta():
    """Abierta del todo, en un tabique de lado: puerta-bano-abierta-lado (14 × 67), la hoja casi de canto vista desde
    el otro lado, repintada como puerta_abierta: todo lo de dentro, del mismo azul liso (sin las molduras de la madera);
    el canto de la izquierda y los filos que dan al aire, con luz; y el pomo, de metal. Se quedan el contorno de fuera y
    la sombra del suelo"""
    im = Image.open(f'{SALIDA}/puerta-bano-abierta-lado.png').convert('RGBA')
    orig = im.copy().load()
    px = im.load()

    def lleno(x, y):
        return 0 <= x < im.width and 0 <= y < im.height and orig[x, y][3] == 255

    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 255:
                continue   # la sombra del suelo, como está
            borde = not all(lleno(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if (r, g, b) == LINEA:
                if not borde:
                    px[x, y] = AZUL + (255,)   # el contorno de las molduras, por dentro de la hoja
                continue
            l = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)[1]
            if es_laton(r, g, b) or (l > 0.42 and 10 <= x <= 12 and 20 <= y <= 25):
                c = METAL[0] if es_laton(r, g, b) and orig[x, y - 1][:3] != LINEA else METAL[1]   # el pomo
            elif x == 1:
                c = AZUL_CANTO   # el canto, que da a la luz
            elif x == 0 or (borde and l > 0.3):
                c = AZUL_LUZ     # su filo y los de arriba y de las bisagras, que dan al aire
            else:
                c = AZUL
            px[x, y] = c + (255,)
    im.save(f'{SALIDA}/puerta-trastero-abierta-lado.png')


if __name__ == '__main__':
    suelo()
    pared()
    pared(lagrimada=True)
    linea()
    puerta_cerrada()
    puerta_abierta()
    puerta_lado_cerrada()
    puerta_lado_abierta()
    print('  suelo-trastero, pared-trastero, techo-trastero, pared-trastero-pasillo, linea-trastero, puerta-trastero, '
          'puerta-trastero-abierta, puerta-trastero-lado-cerrada y puerta-trastero-abierta-lado')
