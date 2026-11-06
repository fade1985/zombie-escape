# El bate de Johnny, de metal: aluminio plateado con el mango de cinta negra, como el de la tienda de armas
# (assets/ui/tienda/bate-grande.png, de PixelLab). Sin PixelLab: se repinta el bate de madera de la hoja de siempre.
# El bate de madera usa los mismos colores que la piel de Johnny (y que su pelo), así que no vale cambiar colores:
# se busca, dibujo a dibujo, por su forma.
#   1. Los píxeles "de madera": los tostados (de_madera; salen también en la cara, las manos y el pelo).
#   2. La barra: de todas las rectas posibles (cada pocos grados y a cada altura), el tramo más largo de madera que va
#      entre dos contornos oscuros que no están a más de ANCHO píxeles (el bate tiene su raya oscura a cada lado; la
#      cara y las manos son más anchas o no tienen esa raya). El bate es lo más largo y recto del dibujo.
#   3. Se alarga por los dos lados mientras la madera siga siendo estrecha: por un lado llega a la punta (y se coge el
#      redondeo de la punta) y por el otro, a las manos, donde la madera se ensancha.
#   4. Cada color de madera pasa a su gris (GRIS, por lo claro que es); los últimos AGARRE píxeles antes de las manos,
#      a los negros de la cinta (CINTA). El contorno oscuro de Johnny, que también rodea el bate, se deja como está.
#   5. AJUSTES: los dibujos en los que lo de arriba se equivoca (los golpes, sobre todo), arreglados a mano.
#   6. La estela de los golpes (las rayas tostadas que deja el bate en el aire, sin contorno): también a gris.
# Lee la hoja de madera (assets/sources/conserje-48-bate/hoja-madera.png, la que hizo tools/arma.py) y saca
# assets/sprites/conserje-48-bate.png. Las skins, después, con tools/cara.py (que mira los grises del bate como si
# fueran la madera de siempre, COMO_GRIS, para que la cabeza nueva quede igual que antes):
#   py tools/bate_metal.py            → la hoja (y luego, para cada skin, py tools/cara.py <skin> bate)
#   py tools/bate_metal.py muestra    → además, capturas/captura-bate-metal-<animación>.png: antes, lo que ha
#                                       encontrado (rosa el bate, azul el agarre) y después, al doble
import colorsys
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
SPRITES = RAIZ / "assets" / "sprites"
MADERA = RAIZ / "assets" / "sources" / "conserje-48-bate" / "hoja-madera.png"
HOJA = "conserje-48-bate"
ANCHO = 4.5      # lo más ancho que es el bate de contorno a contorno (de lado a lado de su recta)
BARRIL = 6.5     # y por la punta, que es más gorda
LARGO = 7        # un tramo más corto que esto no es el bate
AGARRE = 3       # cuántos píxeles antes de las manos son de cinta negra
PUNTA = 3        # cuánto más allá del final del tramo se coge la punta redondeada
# Los grises del aluminio (de bate-grande.png), de oscuro a claro, y los negros de la cinta del mango. Ninguno sale
# en la hoja de madera (si no, tools/cara.py los confundiría con otra cosa)
GRIS = [(52, 49, 52), (70, 66, 70), (86, 82, 86), (102, 98, 100), (119, 117, 118), (135, 134, 134), (156, 151, 149),
        (175, 168, 166), (192, 186, 184), (210, 206, 203), (226, 223, 220)]
CINTA = [(21, 20, 21), (33, 31, 32), (47, 44, 46)]
# Para tools/cara.py: cada gris y cada negro de la cinta, con el tostado de la madera de lo claro que es (cara.py mira
# el bate como si siguiera siendo de madera, como antes, para que la cabeza nueva de cada skin quede igual)
MADERA_LUZ = [(64, 31, 16), (112, 63, 34), (140, 58, 40), (130, 93, 60), (175, 109, 50), (185, 87, 60),
              (205, 103, 72), (224, 125, 89), (238, 148, 111), (249, 161, 110)]
VECINOS = [(dx, dy) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dx or dy]

# Los dibujos que el buscador no acierta solo (los golpes con el bate muy gordo, de punta, o pasando por detrás de la
# cabeza), arreglados a mano, en píxeles de la casilla (96x96, pies en 48,72): (animación, dirección, fotograma) →
#   "linea": ((x, y) de la punta, (x, y) de donde lo agarran o se esconde, grosor): el bate es la madera que hay a
#            menos de grosor de esa línea (sin pasarse de sus dos extremos), en vez de lo que haya encontrado
#   "poner": [(x0, y0, x1, y1)]: cajas con madera que sí es del bate (o de su estela) y no ha cogido
#   "quitar": [(x0, y0, x1, y1)]: cajas con lo que ha cogido y no es del bate
AJUSTES = {
    ("attack", "south", 2): {"poner": [(10, 20, 27, 47)]},                  # la estela, con los tostados de la piel
    ("attack", "south-east", 7): {"linea": ((36, 20), (45, 27), 3.5)},      # de punta y gordo, por detrás de la cabeza
    ("attack", "east", 8): {"linea": ((41, 19), (46, 27), 3)},              # por detrás de la cabeza
    ("attack", "north-west", 7): {"linea": ((75, 33), (57, 46), 3.5)},      # gordo, hacia la cámara
    ("attack", "west", 5): {"poner": [(18, 17, 50, 26)]},                   # la estela, con los cremas de la camisa
}


def como_madera():
    """{gris o negro del bate: tostado de la madera}, para tools/cara.py (COMO_GRIS)."""
    return {c: min(MADERA_LUZ, key=lambda m: abs(luz(m) - luz(c) - (40 if c in CINTA else 0))) for c in GRIS + CINTA}


def fotogramas(datos):
    """[(animación, dirección, número, fila, columna)] de todos los dibujos de la hoja."""
    lista = []
    for anim, v in datos["anims"].items():
        for direc, dv in v["dirs"].items():
            for i in range(dv["frames"]):
                lista.append((anim, direc, i, dv["row"], dv.get("col", 0) + i))
    return lista


_memo = {}


def de_madera(c):
    """Los tostados del bate (y de la piel y el pelo de Johnny)."""
    if c[3] == 0:
        return False
    clave = tuple(int(v) for v in c[:3])
    if clave not in _memo:
        h, s, v = colorsys.rgb_to_hsv(clave[0] / 255, clave[1] / 255, clave[2] / 255)
        _memo[clave] = 7 <= h * 360 <= 31 and s >= 0.45 and v >= 0.27
    return _memo[clave]


def claro(c):
    """Los tostados claros (el brillo de la punta del bate)."""
    if c[3] == 0:
        return False
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    return 5 <= h * 360 <= 45 and s >= 0.15 and v >= 0.6


def blanco(c):
    """Los blancos y grises claros de la estela, y sus tostados muy pálidos (no los cremas de la camisa)."""
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    return s < 0.12 and v > 0.6 or s < 0.3 and v > 0.97


def luz(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


class Dibujo:
    """Un dibujo de la hoja (una casilla), con sus máscaras de madera, de contorno y de lo que se ve."""

    def __init__(self, cel):
        self.cel = cel
        self.alto, self.ancho = cel.shape[:2]
        self.opaco = cel[..., 3] > 0
        self.oscuro = self.opaco & (cel[..., :3].max(axis=2) < 40)
        self.madera = np.zeros(self.opaco.shape, bool)
        ys, xs = np.nonzero(self.opaco)
        for y, x in zip(ys, xs):
            self.madera[y, x] = de_madera(cel[y, x])

    def dentro(self, x, y):
        return 0 <= x < self.ancho and 0 <= y < self.alto

    def entre_contornos(self, cx, cy, nx, ny):
        """Lo que mide de contorno oscuro a contorno oscuro, de lado a lado de la recta, si en (cx, cy) hay madera;
        99 si no la hay, o si por algún lado se acaba en el aire."""
        x, y = round(cx), round(cy)
        if not self.dentro(x, y) or not self.madera[y, x]:
            return 99
        total = 0
        for sg in (1, -1):
            k = 0.5
            while True:
                x, y = round(cx + sg * k * nx), round(cy + sg * k * ny)
                if not self.dentro(x, y) or not self.opaco[y, x]:
                    return 99
                if self.oscuro[y, x]:
                    break
                k += 0.5
                if k > 8:
                    return 99
            total += k
        return total

    def ancho_madera(self, cx, cy, nx, ny):
        """Cuánta madera seguida hay de lado a lado de la recta en (cx, cy) (99 si ahí no hay madera)."""
        x, y = round(cx), round(cy)
        if not self.dentro(x, y) or not self.madera[y, x]:
            return 99
        total = 0
        for sg in (1, -1):
            k = 0.5
            while True:
                x, y = round(cx + sg * k * nx), round(cy + sg * k * ny)
                if not self.dentro(x, y) or not self.madera[y, x]:
                    break
                k += 0.5
                if k > 8:
                    return 99
            total += k
        return total


def ejes(angulo):
    a = math.radians(angulo)
    dx, dy = math.cos(a), math.sin(a)
    return dx, dy, -dy, dx


def punto(angulo, altura, t):
    dx, dy, nx, ny = ejes(angulo)
    return t * dx + altura * nx, t * dy + altura * ny


def buscar(d):
    """La recta del bate: (angulo, altura, desde, hasta) del tramo estrecho entre contornos más largo, o None."""
    ys, xs = np.nonzero(d.madera)
    if len(xs) < LARGO:
        return None
    candidatos = []
    for angulo in range(0, 180, 3):
        dx, dy, nx, ny = ejes(angulo)
        t = xs * dx + ys * dy
        s = xs * nx + ys * ny
        for altura in np.arange(math.floor(s.min()), s.max() + 0.5, 0.5):
            sel = np.abs(s - altura) <= 1.0
            if sel.sum() < LARGO:
                continue
            tb = np.unique(np.round(t[sel]).astype(int))
            ini = prev = tb[0]
            for v in list(tb[1:]) + [10 ** 6]:
                if v - prev > 2:
                    if prev - ini >= LARGO:
                        candidatos.append((prev - ini, angulo, float(altura), int(ini), int(prev)))
                    ini = v
                prev = v
    mejor = None
    for largo, angulo, altura, t0, t1 in sorted(candidatos, reverse=True):
        if mejor and largo <= mejor[0]:
            break
        dx, dy, nx, ny = ejes(angulo)
        ini = None
        for tt in range(t0, t1 + 2):
            ok = tt <= t1 and d.entre_contornos(tt * dx + altura * nx, tt * dy + altura * ny, nx, ny) <= ANCHO
            if ok and ini is None:
                ini = tt
            if not ok and ini is not None:
                if tt - 1 - ini >= 4 and (mejor is None or tt - 1 - ini > mejor[0]):
                    mejor = (tt - 1 - ini, angulo, altura, ini, tt - 1)
                ini = None
    return mejor[1:] if mejor else None


def centrar(d, angulo, altura, t):
    """En el punto t de la recta, la altura (de -1,5 a +1,5 de la de la recta) con la madera más estrecha, por si el
    bate se tuerce un poco (o la recta no va justo por su medio). (ancho, altura)."""
    dx, dy, nx, ny = ejes(angulo)
    mejor = (99, altura)
    # si justo en la recta hay un contorno, no se busca al lado (se colaría al otro lado del contorno: el pelo)
    x, y = round(t * dx + altura * nx), round(t * dy + altura * ny)
    if not d.dentro(x, y) or not d.opaco[y, x] or max(d.cel[y, x, :3]) < 70:
        return mejor
    for o in (altura, altura - 0.5, altura + 0.5, altura - 1, altura + 1, altura - 1.5, altura + 1.5):
        w = d.ancho_madera(t * dx + o * nx, t * dy + o * ny, nx, ny)
        if w < mejor[0]:
            mejor = (w, o)
    return mejor


def alargar(d, angulo, altura, t0, t1):
    """Sigue el bate desde el tramo por los dos lados mientras la madera siga estrecha (se deja saltar un punto).
    Devuelve (camino, manos): camino es [(t, altura)] por el medio del bate, de un extremo a otro; manos es el lado
    ("desde" o "hasta") de las manos: el que queda más cerca del cuerpo (del centro de los contornos oscuros, que la
    estela no tiene)."""
    ys, xs = np.nonzero(d.oscuro)
    centro = xs.mean(), ys.mean()
    lejos = {"desde": math.dist(punto(angulo, altura, t0), centro), "hasta": math.dist(punto(angulo, altura, t1), centro)}
    manos = min(lejos, key=lejos.get)
    camino = {}
    for t in range(t0, t1 + 1):
        w, o = centrar(d, angulo, altura, t)
        camino[t] = o if w <= ANCHO else altura
    for lado, sg, t in (("desde", -1, t0), ("hasta", 1, t1)):
        # hacia la punta, el bate engorda (BARRIL); hacia las manos, en cuanto se ensancha se para
        ancho = ANCHO if lado == manos else BARRIL
        o = altura
        fallos = 0
        while abs(t - (t0 if sg < 0 else t1)) < 18 and fallos < 2:
            w, o2 = centrar(d, angulo, o, t + sg)
            t += sg
            if w <= ancho:
                camino[t] = o = o2
                fallos = 0
            else:
                # se deja saltar un punto ancho (una mano, un nudillo), pero no un contorno: detrás está otra cosa
                x, y = (round(v) for v in punto(angulo, o, t))
                if not d.dentro(x, y) or not d.opaco[y, x] or max(d.cel[y, x, :3]) < 70:
                    break
                fallos += 1
    # las manos, mirando ya los dos extremos del bate entero
    camino = [(t, camino[t]) for t in sorted(camino)]
    lejos = {"desde": math.dist(punto(angulo, camino[0][1], camino[0][0]), centro),
             "hasta": math.dist(punto(angulo, camino[-1][1], camino[-1][0]), centro)}
    return camino, min(lejos, key=lejos.get)


def pixeles_del_bate(d, angulo, camino, manos):
    """{(x, y): distancia a las manos a lo largo del bate} de la madera del bate."""
    dx, dy, nx, ny = ejes(angulo)
    t0, t1 = camino[0][0], camino[-1][0]
    sel = {}

    def coger(tt, altura, punta):
        for oo in (altura - 0.5, altura, altura + 0.5):
            cx, cy = tt * dx + oo * nx, tt * dy + oo * ny
            for sg in (1, -1):
                k = 0.0
                while k <= 3:
                    x, y = round(cx + sg * k * nx), round(cy + sg * k * ny)
                    if not d.dentro(x, y) or not (d.madera[y, x] or punta and claro(d.cel[y, x])):
                        break
                    t = x * dx + y * dy
                    sel[(x, y)] = t - t0 if manos == "desde" else t1 - t
                    k += 0.5

    for (ta, oa), (tb, ob) in zip(camino, camino[1:] + [camino[-1]]):
        coger(ta, oa, False)
        coger((ta + tb) / 2, (oa + ob) / 2, False)
    # la punta redondeada: por el lado que no es el de las manos, un poco más allá (ahí también los tostados claros del
    # brillo de la punta, que no cuentan como madera)
    t, o, sg = (camino[-1][0], camino[-1][1], 1) if manos == "desde" else (camino[0][0], camino[0][1], -1)
    for k in range(1, 2 * PUNTA + 1):
        coger(t + sg * k / 2, o, True)
    # y lo que quede de la punta pegado a lo cogido (el redondeo, que la recta no alcanza)
    pendientes = [p for p in sel if sg * (p[0] * dx + p[1] * dy - t) >= -1]
    while pendientes:
        x, y = pendientes.pop()
        for vx, vy in VECINOS:
            q = (x + vx, y + vy)
            if q in sel or not d.dentro(*q):
                continue
            tq = q[0] * dx + q[1] * dy
            if sg * (tq - t) < -1 or sg * (tq - t) > 3 * PUNTA or abs(q[0] * nx + q[1] * ny - o) > 4.5:
                continue
            if d.madera[q[1], q[0]] or claro(d.cel[q[1], q[0]]):
                sel[q] = tq - t0 if manos == "desde" else t1 - tq
                pendientes.append(q)
    return sel


def enderezar(bate):
    """(angulo, altura, desde, hasta) de la recta que mejor pasa por unos píxeles (el eje largo de la mancha)."""
    if len(bate) < LARGO:
        return None
    p = np.array(list(bate), float)
    m = p.mean(axis=0)
    _, _, v = np.linalg.svd(p - m)
    dx, dy = v[0]
    angulo = math.degrees(math.atan2(dy, dx)) % 180
    dx, dy, nx, ny = ejes(angulo)
    t = p[:, 0] * dx + p[:, 1] * dy
    altura = float(m[0] * nx + m[1] * ny)
    # el tramo del medio (lo de los extremos lo vuelve a buscar alargar())
    a, b = np.percentile(t, [15, 85])
    return angulo, altura, int(round(a)), int(round(b))


def detectar(d, clave):
    """{(x, y): distancia a las manos} del bate de un dibujo (con sus AJUSTES)."""
    ajuste = AJUSTES.get(clave, {})
    if ajuste == "no":
        return {}
    if "linea" in ajuste:
        bate = linea(d, *ajuste["linea"])
    else:
        recta = buscar(d)
        if not recta:
            return {}
        camino, manos = alargar(d, *recta)
        bate = pixeles_del_bate(d, recta[0], camino, manos)
        # la recta buena: la que mejor pasa por lo encontrado (la primera puede ir algo torcida, y al seguir el bate
        # se sale de él), y otra vez desde ahí
        recta = enderezar(bate) or recta
        camino, manos = alargar(d, *recta)
        bate = pixeles_del_bate(d, recta[0], camino, manos)
    # los marrones casi negros del borde del bate (también son el borde del pelo: solo si casi todo lo de alrededor
    # es bate)
    for (x, y), dist in list(bate.items()):
        for vx, vy in VECINOS:
            q = (x + vx, y + vy)
            if q in bate or not d.dentro(*q) or not tostado(d.cel[q[1], q[0]]) or max(d.cel[q[1], q[0], :3]) >= 70:
                continue
            if sum((q[0] + a, q[1] + b) in bate for a, b in VECINOS) >= 3:
                bate[q] = dist
    # las motas de otros tostados que quedan dentro del bate (casi rodeadas de bate)
    for _ in range(2):
        for (x, y), dist in list(bate.items()):
            for vx, vy in VECINOS:
                q = (x + vx, y + vy)
                if q in bate or not d.dentro(*q) or not tostado(d.cel[q[1], q[0]]):
                    continue
                if sum((q[0] + a, q[1] + b) in bate for a, b in VECINOS) >= 5:
                    bate[q] = dist
    for x0, y0, x1, y1 in ajuste.get("quitar", []):
        bate = {p: v for p, v in bate.items() if not (x0 <= p[0] <= x1 and y0 <= p[1] <= y1)}
    for x0, y0, x1, y1 in ajuste.get("poner", []):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if d.dentro(x, y) and (d.madera[y, x] or claro(d.cel[y, x])):
                    bate.setdefault((x, y), 99)
    return bate


def linea(d, punta, manos, grosor):
    """{(x, y): distancia a las manos} de la madera a menos de grosor de la línea de la punta a las manos."""
    (px, py), (mx, my) = punta, manos
    largo = math.dist(punta, manos)
    ux, uy = (mx - px) / largo, (my - py) / largo
    bate = {}
    for y in range(d.alto):
        for x in range(d.ancho):
            t = (x - px) * ux + (y - py) * uy
            lado = abs(-(x - px) * uy + (y - py) * ux)
            if -1 <= t <= largo and lado <= grosor and (d.madera[y, x] or claro(d.cel[y, x])):
                bate[(x, y)] = largo - t
    return bate


def estela(d, de_johnny):
    """La estela del golpe: los tostados que no salen en Johnny quieto ni andando (de_johnny: los colores de esas
    filas; la estela tiene los suyos, más vivos o más pálidos) y a los que se llega desde el aire pasando solo por
    ellos y por los blancos de la estela (de lado, no en diagonal): los de dentro de Johnny (la camisa y la piel en
    pleno golpe también estrenan colores) quedan detrás de su contorno."""
    nuevo = np.zeros(d.opaco.shape, bool)
    ys, xs = np.nonzero(d.opaco)
    for y, x in zip(ys, xs):
        nuevo[y, x] = tuple(int(v) for v in d.cel[y, x, :3]) not in de_johnny and tostado(d.cel[y, x])
    fuera = ~d.opaco
    pendientes = list(zip(*np.nonzero(fuera)))
    while pendientes:
        y, x = pendientes.pop()
        for vx, vy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            qx, qy = x + vx, y + vy
            if d.dentro(qx, qy) and not fuera[qy, qx] and (nuevo[qy, qx] or blanco(d.cel[qy, qx])):
                fuera[qy, qx] = True
                pendientes.append((qy, qx))
    return {(x, y) for y, x in zip(*np.nonzero(fuera & nuevo))}


def tostado(c):
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    return 5 <= h * 360 <= 45 and s >= 0.15 and v >= 0.2


def gris(c):
    """El gris del aluminio que va en lugar de un tostado (por lo claro que es)."""
    l = luz(c)
    return GRIS[max(0, min(len(GRIS) - 1, round((l - 40) / 150 * (len(GRIS) - 1))))]


def cinta(c):
    l = luz(c)
    return CINTA[0] if l < 90 else CINTA[1] if l < 150 else CINTA[2]


def pintar(cel, bate):
    nuevo = cel.copy()
    for (x, y), dist in bate.items():
        c = cel[y, x]
        nuevo[y, x, :3] = cinta(c) if dist < AGARRE else gris(c)
    return nuevo


def main():
    datos = json.load(open(SPRITES / f"{HOJA}.json", encoding="utf-8"))
    cw, ch = datos["cell"]
    hoja = np.array(Image.open(MADERA).convert("RGBA"))
    for c in GRIS + CINTA:
        assert not np.any(np.all(hoja[..., :3] == c, axis=2)), f"el color {c} ya sale en la hoja de madera"
    nueva = hoja.copy()
    filas = [dv["row"] for anim, v in datos["anims"].items() if anim != "attack" for dv in v["dirs"].values()]
    de_johnny = {tuple(int(v) for v in c[:3]) for f in filas for c in hoja[f * ch:(f + 1) * ch].reshape(-1, 4) if c[3]}
    muestras = {}
    for anim, direc, i, fila, col in fotogramas(datos):
        y0, x0 = fila * ch, col * cw
        cel = hoja[y0:y0 + ch, x0:x0 + cw]
        if not cel[..., 3].any():
            continue
        d = Dibujo(cel)
        bate = detectar(d, (anim, direc, i))
        rastro = estela(d, de_johnny) - set(bate) if anim == "attack" else set()
        hecho = pintar(cel, bate | {p: 99 for p in rastro})
        nueva[y0:y0 + ch, x0:x0 + cw] = hecho
        if "muestra" in sys.argv:
            marcas = cel.copy()
            for (x, y), dist in bate.items():
                marcas[y, x] = (0, 220, 255, 255) if dist < AGARRE else (255, 0, 255, 255)
            for x, y in rastro:
                marcas[y, x] = (255, 230, 0, 255)
            muestras.setdefault(anim, []).append((direc, i, cel, marcas, hecho))
        if not bate:
            print(f"sin bate: {anim} {direc} {i}")
    Image.fromarray(nueva).save(SPRITES / f"{HOJA}.png", optimize=True)
    print(f"hecho: assets/sprites/{HOJA}.png")
    if "muestra" in sys.argv:
        muestra(muestras, cw, ch)


def muestra(muestras, cw, ch):
    z = 2
    fondo = (58, 74, 58, 255)
    for anim, lista in muestras.items():
        direcs = list(dict.fromkeys(dv for dv, *_ in lista))
        ancho = max(sum(1 for dv, *_ in lista if dv == d) for d in direcs)
        img = Image.new("RGBA", (ancho * cw * z, len(direcs) * 3 * ch * z), fondo)
        for direc, i, cel, marcas, hecho in lista:
            fila = direcs.index(direc) * 3
            for k, dib in enumerate((cel, marcas, hecho)):
                im = Image.fromarray(dib).resize((cw * z, ch * z), Image.NEAREST)
                img.alpha_composite(im, (i * cw * z, (fila + k) * ch * z))
        ruta = RAIZ / "capturas" / f"captura-bate-metal-{anim}.png"
        ruta.parent.mkdir(exist_ok=True)
        img.save(ruta)
        print(f"muestra: capturas/{ruta.name}")


if __name__ == "__main__":
    main()
