# Quita la sangre que PixelLab le puso a la muerte del durmiente de las uñas (23 nov, lo pidió el dueño): al recibir el
# tiro le salta un chorro rojo de la cabeza, aunque el texto decía «no blood splashes».
#   1. Sangre = un color rojizo que el cuerpo no usa nunca: se miran todos los colores de sus otras animaciones
#      (poses, andar, golpe, disparo; unos 270) y lo rojizo que no esté ahí es sangre o su brillo rosa.
#      En los fotogramas 1 y 2 (el tiro, aún de pie), por encima de los hombros vale cualquier rojizo: en abajo-derecha
#      el chorro es del mismo rojo oscuro que las manos.
#   2. Cada píxel de sangre encerrado en el cuerpo (cuerpo a los dos lados, a menos de 6 píxeles, en horizontal o en
#      vertical) toma el color de esos dos (así se tapa la sangre que cae encima de la cabeza); el resto se borra.
#      Una sola pasada: con varias, lo rellenado rellenaba más y el chorro entero salía como una mancha rosa.
#   3. Las gotas sueltas (trocitos de menos de MIN_TROZO píxeles que no tocan el cuerpo) se borran también, aunque sean
#      de un rojo que el cuerpo sí usa (las del tiro de arriba-derecha son del rojo oscuro de las manos).
# Trabaja sobre la copia original (capturas/unas-muerte-con-sangre/, fuera de git; si no está, la hace) y escribe los
# fotogramas limpios en assets/sources/unas-gpt/animaciones/muerte/. Uso: py tools/unas_sin_sangre.py
import glob
import os
import shutil
from PIL import Image
import numpy as np

ANIM = "assets/sources/unas-gpt/animaciones/"
CARPETA = ANIM + "muerte/"
ORIGINAL = "capturas/unas-muerte-con-sangre/"
MIN_TROZO = 200     # el cuerpo es siempre una sola pieza de miles de píxeles; el resto del chorro, unas decenas

if not os.path.isdir(ORIGINAL):
    shutil.copytree(CARPETA, ORIGINAL)

sanos = set()
for p in glob.glob(ANIM + "rotaciones/*.png") + glob.glob(ANIM + "andar/*/*.png") + \
        glob.glob(ANIM + "golpe/*/*.png") + glob.glob(ANIM + "disparo/*/*.png"):
    a = np.array(Image.open(p).convert("RGBA"))
    sanos |= set(map(tuple, a[a[..., 3] > 0][:, :3].tolist()))

VECINOS = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]


def es_sangre(a):
    h, w = a.shape[:2]
    m = np.zeros((h, w), bool)
    for y, x in zip(*np.nonzero(a[..., 3] > 0)):
        r, g, b = (int(v) for v in a[y, x, :3])
        if (r, g, b) not in sanos and r > g + 40 and r > b + 30:
            m[y, x] = True
    return m


def trozos(opaco):
    # los trozos sueltos (píxeles unidos por los lados o las esquinas), cada uno como lista de puntos
    h, w = opaco.shape
    visto = np.zeros_like(opaco)
    lista = []
    for y0, x0 in zip(*np.nonzero(opaco)):
        if visto[y0, x0]:
            continue
        pila, trozo = [(y0, x0)], []
        visto[y0, x0] = True
        while pila:
            y, x = pila.pop()
            trozo.append((y, x))
            for dy, dx in VECINOS:
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and opaco[yy, xx] and not visto[yy, xx]:
                    visto[yy, xx] = True
                    pila.append((yy, xx))
        lista.append(trozo)
    return lista


def rojizo(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (a[..., 3] > 0) & (r > g + 40) & (r > b + 30)


def encerrado(cuerpo, y, x, lejos=6):
    # el cuerpo más cercano a cada lado (izquierda y derecha, o arriba y abajo), si los dos están a menos de «lejos»
    h, w = cuerpo.shape
    for (dy, dx), (ey, ex) in (((0, -1), (0, 1)), ((-1, 0), (1, 0))):
        lados = []
        for sy, sx in ((dy, dx), (ey, ex)):
            for k in range(1, lejos + 1):
                yy, xx = y + sy * k, x + sx * k
                if not (0 <= yy < h and 0 <= xx < w):
                    break
                if cuerpo[yy, xx]:
                    lados.append((yy, xx))
                    break
        if len(lados) == 2:
            return lados
    return None


def limpiar(a, hombros=None):
    # hombros: en los primeros fotogramas (aún de pie), la fila de los hombros; por encima, todo lo rojizo que no
    # esté encerrado en la cabeza es el chorro (en abajo-derecha es del mismo rojo oscuro que las manos)
    sangre = es_sangre(a)
    if hombros is not None:
        sangre[:hombros] |= rojizo(a)[:hombros]
    cuerpo = (a[..., 3] > 0) & ~sangre
    cambios = []
    for y, x in zip(*np.nonzero(sangre)):
        lados = encerrado(cuerpo, y, x)
        if lados:
            cambios.append((y, x, np.mean([a[p][:3] for p in lados], axis=0)))
    for y, x, c in cambios:
        a[y, x, :3] = c
        a[y, x, 3] = 255
        sangre[y, x] = False
    borrados = int(sangre.sum())
    a[sangre] = 0
    for t in trozos(a[..., 3] > 0):
        if len(t) < MIN_TROZO:
            for y, x in t:
                a[y, x] = 0
            borrados += len(t)
    return borrados


PRIMEROS = 3        # los fotogramas 1 y 2: el tiro, aún de pie
SIN_CABEZA = {("south", 1)}     # los que pierden la cabeza al quitar el chorro (mirado a ojo)
for p in sorted(glob.glob(ORIGINAL + "*/frame_*.png")):
    a = np.array(Image.open(p).convert("RGBA")).astype(np.int32)
    numero = int(p[-7:-4])
    hombros = None
    if 1 <= numero < PRIMEROS:
        # los hombros, de la pose de pie (fotograma 0): unos 30 píxeles por debajo de lo alto de la cabeza
        hombros = Image.open(os.path.join(os.path.dirname(p), "frame_000.png")).getbbox()[1] + 30
    n = limpiar(a, hombros)
    direccion = os.path.basename(os.path.dirname(p))
    if (direccion, numero) in SIN_CABEZA:
        # el chorro tapaba la cabeza entera y al quitarlo se quedaba sin ella: se pone la de la pose de pie, que aún
        # no se ha movido (hacerlo solo cuando faltaba media cabeza no valía: al inclinarse, la cabeza baja de su
        # sitio y le salía otra)
        pie = np.array(Image.open(os.path.join(os.path.dirname(p), "frame_000.png")).convert("RGBA")).astype(np.int32)
        hueco = (a[:hombros, :, 3] == 0) & (pie[:hombros, :, 3] > 0)
        a[:hombros][hueco] = pie[:hombros][hueco]
    destino = CARPETA + os.path.relpath(p, ORIGINAL)
    Image.fromarray(a.astype(np.uint8), "RGBA").save(destino)
    if n:
        print(os.path.relpath(p, ORIGINAL), n)
