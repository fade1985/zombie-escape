# Arregla tres fallos de dibujo de la letra del juego (assets/fuentes/zombie-scape-ui.ttf), los de L24 y L31 de PENDIENTES:
#   1. Las tildes de á é í ó ú (y de las mayúsculas) iban de arriba a la izquierda a abajo a la derecha («`», la de las vocales
#      con acento grave: à è ì ò ù) en vez de al revés («´»). Se cambian de sitio los dos cuadraditos de cada una.
#   2. La í llevaba, además de la tilde, el punto de la i: se quita el punto y la tilde baja a donde la tienen las demás vocales.
#   3. El ¿ y el ¡ eran el ? y el ! volteados de arriba abajo (con el gancho y el recorte del lado contrario); se hacen girando el
#      ? y el ! media vuelta, como se escriben de verdad.
# Los tres venían de tools/fuente-tildes.py del juego JS (marcas() dibujaba la tilde «agudo» de arriba a la izquierda a abajo a la
# derecha; la í se hacía sobre la i con punto; el ¿ y el ¡ con una transformación (1, 0, 0, -1), que voltea y no gira).
# La letra es de píxeles: cada píxel de su dibujo son 64 unidades y cada contorno, un rectángulo. Se puede lanzar otra vez sin
# miedo: si algo ya está arreglado, lo deja como está. Uso: py tools/arreglar_tildes_fuente.py  (y luego, para que Godot la
# vuelva a importar: Godot --headless --path . --import)
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

RUTA = "assets/fuentes/zombie-scape-ui.ttf"
PX = 64   # unidades de la letra por píxel de su dibujo

f = TTFont(RUTA)
glyf = f["glyf"]
hmtx = f["hmtx"]
cmap = f.getBestCmap()


def contornos(nombre):
    g = glyf[nombre]
    resultado = []
    inicio = 0
    for fin in g.endPtsOfContours:
        resultado.append([tuple(p) for p in g.coordinates[inicio:fin + 1]])
        inicio = fin + 1
    return resultado


def caja(c):
    xs = [p[0] for p in c]
    ys = [p[1] for p in c]
    return min(xs), min(ys), max(xs), max(ys)


def poner(nombre, conts):
    pen = TTGlyphPen(None)
    for c in conts:
        pen.moveTo(c[0])
        for p in c[1:]:
            pen.lineTo(p)
        pen.closePath()
    g = pen.glyph()
    g.recalcBounds(glyf)
    glyf[nombre] = g
    hmtx[nombre] = (hmtx[nombre][0], g.xMin)


def mover(c, dx, dy):
    return [(x + dx, y + dy) for x, y in c]


cambios = []

# 1 y 2: las tildes. Son los dos contornos más altos de la letra: el de arriba tiene que quedar a la derecha del de abajo
for letra in "áéíóúÁÉÍÓÚ":
    nombre = cmap[ord(letra)]
    conts = contornos(nombre)
    minimo = 704 if letra.isupper() or letra == "í" else 576   # donde empieza la tilde (el punto de la í está justo debajo)
    tilde = [c for c in conts if caja(c)[1] >= minimo]
    if letra == "í" and not tilde:
        continue   # ya sin punto y con la tilde baja (arreglada de antes)
    assert len(tilde) == 2, (letra, len(tilde))
    arriba, abajo = sorted(tilde, key=lambda c: caja(c)[1], reverse=True)
    if caja(arriba)[0] > caja(abajo)[0]:
        continue   # ya está bien («´»)
    nuevos = []
    for c in conts:
        if c is arriba:
            nuevos.append(mover(c, PX, 0))
        elif c is abajo:
            nuevos.append(mover(c, -PX, 0))
        else:
            nuevos.append(c)
    if letra == "í":   # sin el punto de la i (los dos rectángulos entre la altura de la letra y la tilde) y con la tilde a su altura
        nuevos = [mover(c, 0, -2 * PX) if caja(c)[1] >= minimo else c
                  for c in nuevos if not (576 <= caja(c)[1] and caja(c)[3] <= 704)]
    poner(nombre, nuevos)
    cambios.append(letra)


# 3: ¿ y ¡ = ? y ! girados media vuelta (alrededor del centro de su caja, que es entero en píxeles)
for abierto, cerrado in (("¿", "?"), ("¡", "!")):
    origen = cmap[ord(cerrado)]
    destino = cmap[ord(abierto)]
    conts = contornos(origen)
    x0, y0, x1, y1 = (min(caja(c)[0] for c in conts), min(caja(c)[1] for c in conts),
                      max(caja(c)[2] for c in conts), max(caja(c)[3] for c in conts))
    girados = [[(x0 + x1 - x, y0 + y1 - y) for x, y in c] for c in conts]
    hoy = sorted(caja(c) for c in contornos(destino))
    if hoy == sorted(caja(c) for c in girados):
        continue   # ya está girado
    poner(destino, girados)
    cambios.append(abierto)

if cambios:
    f.save(RUTA)
print("Arreglado:", " ".join(cambios) if cambios else "nada (ya estaba todo bien)")
