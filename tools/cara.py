# Las skins de Johnny (scripts/skins.gd): pega la cabeza nueva de una skin en todos los dibujos de sus hojas.
# PixelLab dibujó la cabeza nueva una sola vez, sobre los 8 dibujos de Johnny quieto (edit_image con las rotaciones
# de conserje-48; assets/pixellab.json → "skin-<id>"), y están en assets/sources/skin-<id>/quietos/<dirección>.png.
# Rehacer con PixelLab los ~1.850 dibujos de Johnny costaría miles de generaciones; esto es gratis.
#
# Para cada dirección:
#   1. Se alinea el dibujo nuevo con el de siempre mirando el cuerpo (PixelLab lo movió de lado unos píxeles).
#   2. La cabeza que se pega: los píxeles de arriba que cambian (pelo, barba, coleta: lo que cambia y está unido a
#      la cabeza; las motas sueltas del cuerpo, no) y los de la cabeza de siempre (hasta la barbilla).
# Para cada fotograma de cada hoja (conserje-48-<arma>.png; la fila dice la dirección):
#   3. Se busca dónde tiene la cabeza: primero por el pañuelo rojo y luego, cerca, donde mejor encaja la cabeza de
#      siempre (en las animaciones la cabeza sube, baja y se inclina un poco).
#   4. Se pega la nueva encima. Lo que no es de Johnny (la fregona, el bate, el agua...) se respeta: la cabeza
#      queda detrás. Donde la nueva no tiene nada, se borra solo lo que era de la cabeza de siempre.
#   5. Lo que quede cerca del pelo castaño de siempre (cada arma tiene su cabeza un poco distinta), según la skin
#      (SOBRA): del color del pelo nuevo (el portero), quitado y también lo que quede del pañuelo (el glotón, calvo y
#      sin pañuelo) o quitado solo el pelo, respetando el pañuelo y sus puntas (el gymbro, calvo con pañuelo).
#      Con un casco (el bombero), se quita como en el glotón, y lo que el casco se sale de la cabeza de siempre (el ala,
#      la parte de atrás) queda detrás de los brazos: solo se pinta sobre el aire o sobre el pelo y el pañuelo viejos.
# Los efectos (fila "fx": fogonazo, humo) no tienen a Johnny: se copian tal cual.
#
# Saca assets/sprites/conserje-48-<arma>-<id>.png y su .tres (el mismo con la otra imagen), y los iconos de la
# taquilla: assets/ui/iconos/skin-<id>.png y skin-conserje.png (la cara de frente, 16×16).
#   py tools/cara.py portero            → las hojas y los iconos (y luego importar en Godot)
#   py tools/cara.py portero muestra    → además, captura-cara-<arma>.png con antes y después, para revisarlos
#   py tools/cara.py gloton muestra     → lo mismo, con el glotón (gymbro, con el gymbro; bombero, con el bombero)
import colorsys
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
SPRITES = RAIZ / "assets" / "sprites"
ARMAS = ["guardia", "bate", "cuchillo", "pistola", "escopeta", "mp5", "lanza", "aplastacabezas", "bate-fuego", "partecuerpos", "inmovilizadora", "latigo", "supermaza", "mangual", "bate-helado", "latigo-electrico", "lanzallamas", "supersoplete", "desintegrador", "bumeran", "pistola-electrica", "garfio"]
DIRECCIONES = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
BARBILLA = 12     # hasta esta fila (del dibujo de 48) llega la cabeza de siempre
PARECIDO = 60     # dos colores se parecen si la suma de sus diferencias es menor que esto
DE_JOHNNY = 34    # un color es "de Johnny" si se parece así a alguno de sus colores (si no, es el arma u otra cosa)
# Qué se hace con lo que sobre del pelo de siempre alrededor de la cabeza nueva: "tenir", del color del pelo nuevo
# (el portero); "quitar", para una cabeza calva y sin pañuelo (el glotón: también lo que sobre del pañuelo); "calvo",
# para una calva con el pañuelo de siempre (el gymbro: se quita el pelo, y el pañuelo y sus puntas se quedan);
# "casco", para un casco que tapa el pelo y el pañuelo (el bombero: se quita como "quitar", y lo que el casco se sale
# de la cabeza de siempre va por detrás de los brazos, pegar())
SOBRA = {"portero": "tenir", "gloton": "quitar", "gymbro": "calvo", "bombero": "casco"}
QUITAN = ("quitar", "calvo", "casco")   # los modos que quitan lo que sobra (y tapan los rojos vivos del pañuelo)
# Las bombonas del lanzallamas se pintaron de rojo sobre el gris que dibujó PixelLab. Para pegar la cabeza se miran
# como si siguieran grises: el rojo se parece a la piel y al pañuelo, y la cabeza nueva quedaba detrás de las
# bombonas (motas rojas en la barba del portero) o les borraba brillos. Al acabar, lo que siga gris vuelve a su rojo.
# Lo mismo con las del lanza ácido (el desintegrador), verdes (tools/hoja_lanza_acido.py: cada rojo por su verde)
COMO_GRIS = {"lanzallamas": {
    (238, 96, 74): (163, 184, 199),
    (200, 58, 40): (119, 142, 155),
    (166, 50, 36): (143, 130, 120),
    (122, 40, 30): (98, 86, 73),
    (78, 36, 34): (52, 63, 76),
}, "desintegrador": {
    (236, 248, 150): (163, 184, 199),
    (199, 224, 74): (119, 142, 155),
    (150, 180, 48): (143, 130, 120),
    (96, 128, 40): (98, 86, 73),
    (48, 80, 44): (52, 63, 76),
}}


def dist(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def tsv(c):
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    return h * 360, s, v


def panuelo(c):
    """El rojo del pañuelo (no las sombras rojizas de la piel)."""
    if c[3] == 0:
        return False
    h, s, v = tsv(c)
    return (h >= 345 or h <= 5) and s >= 0.7 and v >= 0.3


def rojo_casco(c):
    """Con el casco: el rojo del pañuelo y también sus sombras más oscuras, que en algunos golpes PixelLab pintó fuera
    de la paleta de Johnny (y si no, pasarían por el arma). Las sombras rojizas de la piel son más claras."""
    if panuelo(c):
        return True
    if c[3] == 0:
        return False
    h, s, v = tsv(c)
    return (h >= 345 or h <= 14) and s >= 0.6 and 0.12 <= v <= 0.42


def vivo(c, johnny):
    """Un rojo vivísimo que no es de la paleta de Johnny: el de los cartuchos de la escopeta (el pañuelo más vivo que
    pintó PixelLab en algunos golpes no llega a tanto)."""
    return panuelo(c) and tsv(c)[1] >= 0.95 and not johnny.es_suyo(c)


def pelo(c):
    """El castaño del pelo de siempre: tono naranja apagado, no muy claro (la piel es más clara y rosada)."""
    if c[3] == 0:
        return False
    h, s, v = tsv(c)
    return 15 <= h <= 40 and s >= 0.35 and 0.15 <= v <= 0.7


def de_cabeza(c):
    """Lo que puede ser de la cabeza de siempre: pelo, pañuelo, contorno oscuro o piel."""
    if c[3] == 0:
        return False
    h, s, v = tsv(c)
    return pelo(c) or panuelo(c) or v < 0.22 or (h < 30 and s >= 0.3 and v >= 0.55)


def cargar(ruta):
    return Image.open(ruta).convert("RGBA")


def alinear(o, n):
    """Cuánto movió PixelLab el dibujo nuevo (mirando el cuerpo, de la fila 24 para abajo)."""
    po, pn = o.load(), n.load()
    mejor = (-1.0, 0, 0)
    for dy in range(-2, 3):
        for dx in range(-9, 10):
            bien = total = 0
            for y in range(24, 48):
                for x in range(48):
                    X, Y = x + dx, y + dy
                    a = po[x, y]
                    b = pn[X, Y] if 0 <= X < 48 and 0 <= Y < 48 else (0, 0, 0, 0)
                    if a[3] == 0 and b[3] == 0:
                        continue
                    total += 1
                    if a[3] > 0 and b[3] > 0 and dist(a, b) < 40:
                        bien += 1
            if total and bien / total > mejor[0]:
                mejor = (bien / total, dx, dy)
    return mejor[1], mejor[2]


def cabeza_nueva(o, n):
    """Los píxeles que se pegan: {(x, y): color del nuevo} en las coordenadas del dibujo de siempre."""
    dx, dy = alinear(o, n)
    po, pn = o.load(), n.load()

    def nuevo(x, y):
        X, Y = x + dx, y + dy
        return pn[X, Y] if 0 <= X < 48 and 0 <= Y < 48 else (0, 0, 0, 0)

    cambia = set()
    for y in range(48):
        for x in range(48):
            a, b = po[x, y], nuevo(x, y)
            if (a[3] > 0) != (b[3] > 0) or (a[3] > 0 and dist(a, b) >= 40):
                cambia.add((x, y))
    # lo que cambia unido a la cabeza (las motas sueltas del cuerpo, fuera)
    semillas = [p for p in cambia if p[1] <= BARBILLA]
    unido, pila = set(semillas), list(semillas)
    while pila:
        x, y = pila.pop()
        for vx in (-1, 0, 1):
            for vy in (-1, 0, 1):
                v = (x + vx, y + vy)
                if v in cambia and v not in unido:
                    unido.add(v)
                    pila.append(v)
    zona = unido | {(x, y) for y in range(BARBILLA + 1) for x in range(48) if po[x, y][3] > 0}
    return {p: nuevo(*p) for p in zona}, (dx, dy)


def plantilla(o):
    """La cabeza de siempre, para buscarla en cada fotograma: [(x, y, color)] y el centro de su pañuelo."""
    po = o.load()
    pix = [(x, y, po[x, y]) for y in range(BARBILLA + 1) for x in range(48) if po[x, y][3] > 0]
    rojos = [(x, y) for x, y, c in pix if panuelo(c)]
    return pix, centro(rojos)


def centro(puntos):
    if not puntos:
        return None
    return (sum(p[0] for p in puntos) / len(puntos), sum(p[1] for p in puntos) / len(puntos))


def manchas(puntos):
    """Los grupos de puntos que se tocan (también en diagonal)."""
    quedan, grupos = set(puntos), []
    while quedan:
        pila = [quedan.pop()]
        grupo = list(pila)
        while pila:
            x, y = pila.pop()
            for vx in (-1, 0, 1):
                for vy in (-1, 0, 1):
                    v = (x + vx, y + vy)
                    if v in quedan:
                        quedan.remove(v)
                        pila.append(v)
                        grupo.append(v)
        grupos.append(grupo)
    return grupos


def buscar(px, x0, y0, cw, ch, pix, rojo_o, cerca):
    """Dónde está la cabeza en el fotograma (desplazamiento del dibujo de 48 dentro de la celda). "cerca": dónde
    la tiene en el dibujo quieto (None en el propio quieto): en las animaciones no se aleja mucho de ahí."""
    # el pañuelo: cada mancha roja da un sitio posible (los cartuchos de la escopeta y las chispas también son
    # rojos, así que se prueban todas las que estén cerca, y la que mejor encaje con la cabeza de siempre gana)
    rojos = [(x, y) for y in range(ch) for x in range(cw) if panuelo(px[x0 + x, y0 + y])]
    grupos = manchas(rojos)
    sitios = set()
    for grupo in grupos:
        if len(grupo) >= 3 and rojo_o:
            # sola, y con los trozos de alrededor (el nudo y las puntas del pañuelo pueden quedar sueltos)
            c = centro(grupo)
            junto = [p for g in grupos for p in g if abs(centro(g)[0] - c[0]) + abs(centro(g)[1] - c[1]) <= 10]
            for c in (centro(grupo), centro(junto)):
                t = (round(c[0] - rojo_o[0]), round(c[1] - rojo_o[1]))
                if cerca is None or abs(t[0] - cerca[0]) + abs(t[1] - cerca[1]) <= 20:
                    sitios.add(t)
    if sitios:
        probar, radio = sitios, 4
    else:
        probar, radio = [cerca or ((cw - 48) // 2, (ch - 48) // 2)], 12
    mejor = (-1e9, 0, 0)
    for base in probar:
        for ty in range(base[1] - radio, base[1] + radio + 1):
            for tx in range(base[0] - radio, base[0] + radio + 1):
                s = 0
                for x, y, c in pix:
                    X, Y = x + tx, y + ty
                    if 0 <= X < cw and 0 <= Y < ch:
                        f = px[x0 + X, y0 + Y]
                        if f[3] > 0 and dist(f, c) < PARECIDO:
                            s += 1
                s -= 0.05 * (abs(tx - base[0]) + abs(ty - base[1]))
                if cerca:
                    s -= 0.05 * (abs(tx - cerca[0]) + abs(ty - cerca[1]))
                if s > mejor[0]:
                    mejor = (s, tx, ty)
    return (mejor[1], mejor[2]), mejor[0] / max(1, len(pix))


class Paleta:
    """Los colores de Johnny quieto (sin arma): para saber si un píxel es suyo o del arma."""

    def __init__(self, quietos):
        self.colores = {o.getpixel((x, y))[:3] for o in quietos.values() for y in range(48) for x in range(48)
                        if o.getpixel((x, y))[3] > 0}
        # los castaños del pelo de siempre (los de su cabeza), para teñir solo esos y no la madera del arma
        self.pelo = {o.getpixel((x, y))[:3] for o in quietos.values() for y in range(BARBILLA + 1) for x in range(48)
                     if pelo(o.getpixel((x, y)))}
        self.memo = {}

    def es_suyo(self, c):
        clave = c[:3]
        if clave not in self.memo:
            self.memo[clave] = min(dist(clave, j) for j in self.colores) < DE_JOHNNY
        return self.memo[clave]

    def es_pelo(self, c):
        return pelo(c) and min(dist(c[:3], j) for j in self.pelo) < 20


def pelo_nuevo(cabeza):
    """Los colores del pelo nuevo (blancos y grises), de oscuro a claro, para teñir el pelo castaño que sobre."""
    claros = sorted({c[:3] for c in cabeza.values() if c[3] > 0 and tsv(c)[1] < 0.2 and tsv(c)[2] > 0.45},
                    key=lambda c: sum(c))
    return claros


def tenir(c, claros):
    """Un castaño del pelo de siempre → el blanco/gris del pelo nuevo con la misma luz relativa."""
    v = tsv(c)[2]
    i = min(len(claros) - 1, max(0, int((v - 0.15) / 0.55 * len(claros))))
    return claros[i] + (c[3],)


def piel_nueva(cabeza):
    """El color de piel que más sale en la cabeza nueva: para tapar lo que sobre por dentro en una calva."""
    pieles = Counter(c for c in cabeza.values() if c[3] > 0 and tsv(c)[0] < 30 and tsv(c)[1] >= 0.3 and tsv(c)[2] >= 0.7)
    return pieles.most_common(1)[0][0] if pieles else (251, 179, 134, 255)


def quitar(px, x0, y0, cw, ch, zona, hechos, johnny, piel, solo_pelo=False, casco=False):
    """Calvo (el glotón): lo que sobre del pelo y del pañuelo de siempre alrededor de la cabeza nueva.
    "solo_pelo" (el gymbro, calvo con pañuelo): solo el pelo; el pañuelo, sus puntas y su contorno se quedan.
    "casco" (el bombero): como el glotón, pero el pelo también se busca más lejos, como el rojo (en los golpes la
    cabeza se gira y el pelo de atrás asoma por detrás del casco), el rojo son también las sombras más oscuras del
    pañuelo (rojo_casco()) y los cartuchos de la escopeta se respetan (vivo()).
    - Los trozos de pelo o de pañuelo (cada uno por su lado) que no salen de alrededor de la cabeza: si siguen, son
      otra cosa (el palo de un arma tiene los mismos castaños). Las puntas del pañuelo vuelan más lejos: para el rojo,
      "alrededor" es un poco más grande. Si tocan el aire, ellos o su contorno negro, se borran con su contorno; si
      quedan metidos entre otras cosas, del color de la piel.
    - Al final, las motas negras sueltas que no rodean nada (el contorno de las puntas del pelo y del pañuelo)."""
    dentro = set(zona)
    xs, ys = [p[0] for p in zona], [p[1] for p in zona]
    lejos = {(x, y) for y in range(min(ys) - 3, max(ys) + 4) for x in range(min(xs) - 6, max(xs) + 7)
             if 0 <= x < cw and 0 <= y < ch and (x, y) not in hechos}

    def color(p):
        return px[x0 + p[0], y0 + p[1]]

    def clase(p):
        if p in hechos:
            return None
        f = color(p)
        return "pelo" if johnny.es_pelo(f) else "rojo" if (rojo_casco(f) if casco else panuelo(f)) and not solo_pelo else None

    def oscuro(p):
        f = color(p)
        return p not in hechos and f[3] > 0 and tsv(f)[2] < 0.22

    def vecinos(p, cruz=False):
        x, y = p
        lista = ((1, 0), (-1, 0), (0, 1), (0, -1)) if cruz else \
            [(vx, vy) for vx in (-1, 0, 1) for vy in (-1, 0, 1) if vx or vy]
        return [(x + vx, y + vy) for vx, vy in lista]

    def en_celda(p):
        return 0 <= p[0] < cw and 0 <= p[1] < ch

    def aire(p):
        return not en_celda(p) or color(p)[3] == 0

    def mancha(p, igual, caja):
        """Los que se tocan con p y cumplen igual(); y si alguno se sale de la caja (alrededor de la cabeza)."""
        grupo, pila, sale = {p}, [p], False
        while pila:
            for v in vecinos(pila.pop()):
                if v not in grupo and en_celda(v) and igual(v):
                    grupo.add(v)
                    pila.append(v)
                    sale = sale or v not in caja
        return grupo, sale

    def rodea_algo(p):
        """Si p hace de contorno de algo que se queda (lo que no es de la cabeza nueva ni oscuro)."""
        return any(en_celda(v) and v not in hechos and color(v)[3] > 0 and tsv(color(v))[2] >= 0.22
                   for v in vecinos(p))

    vistos = set()
    for p in sorted(lejos):
        k = clase(p)
        caja = lejos if k == "rojo" or casco else dentro
        if k is None or p in vistos or p not in caja:
            continue
        trozo, sale = mancha(p, lambda v: clase(v) == k, caja)
        vistos |= trozo
        if sale:
            continue
        # (con el casco, el rojo más vivo, que no es de Johnny, es un cartucho de la escopeta: se queda)
        if casco and k == "rojo" and sum(vivo(color(q), johnny) for q in trozo) >= 3:
            continue
        contorno = {v for q in trozo for v in vecinos(q) if v in caja and oscuro(v)}
        if any(aire(v) for q in trozo | contorno for v in vecinos(q, True)):
            for q in trozo:
                px[x0 + q[0], y0 + q[1]] = (0, 0, 0, 0)
            for q in sorted(contorno):
                if not rodea_algo(q):
                    px[x0 + q[0], y0 + q[1]] = (0, 0, 0, 0)
        else:
            for q in trozo:
                px[x0 + q[0], y0 + q[1]] = piel
    # las motas negras sueltas
    for p in sorted(lejos):
        if p in vistos or not oscuro(p):
            continue
        mota, sale = mancha(p, oscuro, lejos)
        vistos |= mota
        if not sale and not any(rodea_algo(q) for q in mota):
            for q in mota:
                px[x0 + q[0], y0 + q[1]] = (0, 0, 0, 0)
    # y las islas pequeñas que quedan sueltas, casi todo contorno (lo que queda de una punta con algo de su color)
    for p in sorted(lejos):
        if p in vistos or color(p)[3] == 0:
            continue
        isla, sale = mancha(p, lambda v: color(v)[3] > 0, lejos)
        vistos |= isla
        if not sale and len(isla) < 10 and not isla & hechos and 2 * sum(oscuro(q) for q in isla) >= len(isla)                 and not (solo_pelo and any(panuelo(color(q)) for q in isla)):
            for q in isla:
                px[x0 + q[0], y0 + q[1]] = (0, 0, 0, 0)


def es_piel(c):
    h, s_, v = tsv(c)
    return c[3] > 0 and h < 30 and s_ >= 0.3 and v >= 0.55


def delante(px, x0, y0, cw, ch, t, cabeza, po, johnny):
    """El casco: lo que en el dibujo pasa por delante de la cabeza, donde está la de siempre (en los golpes, los brazos
    y las manos suben por encima): la camisa y el peto (ningún color de la cabeza) y las manos (la piel que tapa el pelo
    o el pañuelo de siempre, en trozos gruesos: una raya fina en la frente es la cabeza un poco distinta del arma)."""
    cuerpo, manos = set(), set()
    for (x, y), n in cabeza.items():
        X, Y = x + t[0], y + t[1]
        if n[3] == 0 or not (y <= BARBILLA and po[x, y][3] > 0) or not (0 <= X < cw and 0 <= Y < ch):
            continue
        f = px[x0 + X, y0 + Y]
        if f[3] > 0 and johnny.es_suyo(f) and not de_cabeza(f):
            cuerpo.add((X, Y))
        elif es_piel(f) and not es_piel(po[x, y]):
            manos.add((X, Y))

    def piel_en(p):
        return 0 <= p[0] < cw and 0 <= p[1] < ch and es_piel(px[x0 + p[0], y0 + p[1]])

    for grupo in manchas(manos):
        gordo = any(all(piel_en((x + vx, y + vy)) for vx, vy in ((1, 0), (-1, 0), (0, 1), (0, -1))) for x, y in grupo)
        if len(grupo) >= 5 and gordo:
            cuerpo |= set(grupo)
    return cuerpo


def pegar(px, x0, y0, cw, ch, t, cabeza, quieto_o, johnny, claros, sobra, piel):
    po = quieto_o.load()
    casco = sobra == "casco"
    hechos = set()
    # el casco: lo que va por delante de la cabeza (delante()) y lo que se sale de la cabeza de siempre (el ala, la
    # parte de atrás) se deja para el final (luego): solo se pinta donde, quitado lo que sobre, quede aire
    primero = delante(px, x0, y0, cw, ch, t, cabeza, po, johnny) if casco else set()
    luego = {}
    for (x, y), n in cabeza.items():
        X, Y = x + t[0], y + t[1]
        if not (0 <= X < cw and 0 <= Y < ch):
            continue
        f = px[x0 + X, y0 + Y]
        dentro = y <= BARBILLA and po[x, y][3] > 0
        if n[3] == 0:
            # la nueva no tiene nada aquí: se borra solo lo que era de la cabeza de siempre (con el casco, lo demás
            # queda para quitar(): las puntas del pañuelo y los pelos sueltos que vuelan fuera de la cabeza)
            if dentro and de_cabeza(f):
                px[x0 + X, y0 + Y] = (0, 0, 0, 0)
                hechos.add((X, Y))
            elif not casco:
                hechos.add((X, Y))
            continue
        if casco and ((X, Y) in primero or (not dentro and f[3] > 0 and not (johnny.es_pelo(f) or rojo_casco(f)))):
            luego[(X, Y)] = n
            continue
        hechos.add((X, Y))
        # (calvo, también los rojos que no son de su paleta: en algunos golpes PixelLab pintó el pañuelo más vivo)
        if f[3] == 0 or johnny.es_suyo(f) or (sobra in QUITAN and panuelo(f)) or (casco and rojo_casco(f)):
            px[x0 + X, y0 + Y] = n
    # lo que sobre alrededor del pelo de siempre (la cabeza de cada arma es un poco distinta)
    xs = [x for x, _ in cabeza]
    zona = [(X, Y) for Y in range(t[1], t[1] + BARBILLA + 3) for X in range(t[0] + min(xs) - 3, t[0] + max(xs) + 4)
            if 0 <= X < cw and 0 <= Y < ch and (X, Y) not in hechos]
    if sobra in QUITAN:
        quitar(px, x0, y0, cw, ch, zona, hechos, johnny, piel, sobra == "calvo", casco)
        for (X, Y), n in luego.items():
            if px[x0 + X, y0 + Y][3] == 0:
                px[x0 + X, y0 + Y] = n
        return
    for X, Y in zona:
        f = px[x0 + X, y0 + Y]
        if johnny.es_pelo(f):
            px[x0 + X, y0 + Y] = tenir(f, claros)


def fotogramas(datos):
    """[(animación, dirección, fila, columna)] de todos los dibujos de la hoja."""
    lista = []
    for anim, v in datos["anims"].items():
        for direc, dv in v["dirs"].items():
            for i in range(dv["frames"]):
                lista.append((anim, direc, dv["row"], dv.get("col", 0) + i))
    return lista


def main():
    skin = sys.argv[1] if len(sys.argv) > 1 else "portero"
    muestra = "muestra" in sys.argv
    fuente = RAIZ / "assets" / "sources" / f"skin-{skin}" / "quietos"
    base = cargar(SPRITES / "conserje-48.png")
    datos_base = json.load(open(SPRITES / "conserje-48.json", encoding="utf-8"))
    quietos, nuevos, cabezas, plantillas = {}, {}, {}, {}
    for direc, v in datos_base["anims"]["still"]["dirs"].items():
        c, f = v.get("col", 0), v["row"]
        quietos[direc] = base.crop((c * 48, f * 48, c * 48 + 48, f * 48 + 48))
        nuevos[direc] = cargar(fuente / f"{direc}.png")
        cabezas[direc], movido = cabeza_nueva(quietos[direc], nuevos[direc])
        plantillas[direc] = plantilla(quietos[direc])
        print(f"{direc}: PixelLab lo movió {movido}; se pegan {len(cabezas[direc])} píxeles")
    johnny = Paleta(quietos)
    claros = {d: pelo_nuevo(cabezas[d]) for d in cabezas}
    pieles = {d: piel_nueva(cabezas[d]) for d in cabezas}
    sobra = SOBRA.get(skin, "tenir")

    for arma in [a for a in ARMAS if a in sys.argv] or ARMAS:
        nombre = f"conserje-48-{arma}"
        datos = json.load(open(SPRITES / f"{nombre}.json", encoding="utf-8"))
        cw, ch = datos["cell"]
        hoja = cargar(SPRITES / f"{nombre}.png")
        antes = hoja.copy()
        px = hoja.load()
        grises = COMO_GRIS.get(arma, {})
        rojos = {}
        for y in range(hoja.height) if grises else ():
            for x in range(hoja.width):
                c = px[x, y]
                if c[3] and c[:3] in grises:
                    rojos[(x, y)] = c
                    px[x, y] = grises[c[:3]] + (c[3],)
        # dónde está la cabeza en el dibujo quieto de cada dirección (para cuando el pañuelo no se vea)
        cerca = {}
        for direc, v in datos["anims"]["still"]["dirs"].items():
            x0, y0 = v.get("col", 0) * cw, v["row"] * ch
            cerca[direc], _ = buscar(px, x0, y0, cw, ch, *plantillas[direc], None)
        dudosos = []
        hechos = []
        for anim, direc, fila, col in fotogramas(datos):
            if anim == "fx":
                continue
            x0, y0 = col * cw, fila * ch
            t, parecido = buscar(px, x0, y0, cw, ch, *plantillas[direc], cerca[direc])
            if parecido < 0.35:
                dudosos.append(f"{anim} {direc} {col} ({parecido:.2f})")
            pegar(px, x0, y0, cw, ch, t, cabezas[direc], quietos[direc], johnny, claros[direc], sobra, pieles[direc])
            hechos.append((anim, direc, fila, col, t))
        for (x, y), c in rojos.items():
            if px[x, y] == grises[c[:3]] + (c[3],):
                px[x, y] = c
        hoja.save(SPRITES / f"{nombre}-{skin}.png", optimize=True)
        tres = (SPRITES / f"{nombre}.tres").read_text(encoding="utf-8")
        tres = tres.replace(f"res://assets/sprites/{nombre}.png", f"res://assets/sprites/{nombre}-{skin}.png")
        (SPRITES / f"{nombre}-{skin}.tres").write_text(tres, encoding="utf-8", newline="\n")
        print(f"{nombre}-{skin}: {len(hechos)} dibujos; con la cabeza poco clara: {len(dudosos)}",
              ("(" + ", ".join(dudosos[:8]) + ("..." if len(dudosos) > 8 else "") + ")") if dudosos else "")
        if muestra:
            revisar(antes, hoja, hechos, cw, ch, RAIZ / f"captura-cara-{arma}.png")

    # los iconos de la taquilla: la cara de frente, 16×16
    iconos = RAIZ / "assets" / "ui" / "iconos"
    sur = quietos["south"]
    caja = sur.crop((0, 0, 48, BARBILLA + 1)).getbbox()
    x = (caja[0] + caja[2]) // 2 - 8
    sur.crop((x, 0, x + 16, 16)).save(iconos / "skin-conserje.png")
    nuevo_sur = Image.new("RGBA", (48, 48))
    for (px_, py_), c in cabezas["south"].items():
        nuevo_sur.putpixel((px_, py_), c)
    con_cuerpo = sur.copy()
    con_cuerpo.alpha_composite(nuevo_sur)
    for (px_, py_), c in cabezas["south"].items():
        if c[3] == 0:
            con_cuerpo.putpixel((px_, py_), c)
    con_cuerpo.crop((x, 1, x + 16, 17)).save(iconos / f"skin-{skin}.png")
    print("Iconos: skin-conserje.png y", f"skin-{skin}.png")


def revisar(antes, despues, hechos, cw, ch, salida):
    """Antes (arriba) y después (abajo) de la cabeza en los dibujos de andar y de golpe, al triple, para mirarlos."""
    sel = [h for h in hechos if h[0] in ("walk", "attack")]
    cols, w, h = 16, 44, 30
    filas = (len(sel) + cols - 1) // cols
    img = Image.new("RGBA", (cols * w, filas * h * 2), (60, 60, 60, 255))
    for k, (_, _, fila, col, t) in enumerate(sel):
        X, Y = (k % cols) * w, (k // cols) * h * 2
        x0, y0 = col * cw + t[0] + 2, fila * ch + t[1] - 2
        caja = (x0, y0, x0 + w, y0 + h)
        img.alpha_composite(antes.crop(caja), (X, Y))
        img.alpha_composite(despues.crop(caja), (X, Y + h))
    img.resize((img.width * 3, img.height * 3), Image.NEAREST).save(salida)


if __name__ == "__main__":
    main()
