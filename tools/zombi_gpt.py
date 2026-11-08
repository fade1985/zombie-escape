"""Un zombi hecho con GPT (la prueba del 8 nov: la vecina, «vecino 2»), pasado a los dibujos que monta tools/zombi.py.

GPT dibuja cada cosa en una sola imagen, sobre fondo negro puro, con las vistas o los fotogramas en fila: así se parece
más de uno a otro. Esta herramienta:
  - quita el fondo (solo el negro que se llega desde el borde: los contornos, casi negros, se quedan),
  - separa los dibujos de la fila (por las columnas vacías que hay entre ellos),
  - los reduce todos con la MISMA escala (cada píxel, la media de su trozo, como los muebles de GPT:
    tools/muebles_gpt.py), para que no cambie de tamaño de uno a otro,
  - y los pone en su lienzo de 48 × 48 con los pies abajo y en medio, como los dibujos de PixelLab.

La escala sale de la referencia que se le da a GPT (capturas/referencia-vecino.png: el vecino a 8 píxeles de la imagen
por píxel del juego, en 2016 de ancho): GPT la devuelve a 2000 de ancho, así que 8 × 2000 / 2016.

Uso (desde la carpeta del proyecto):
  py tools/zombi_gpt.py personaje      las 5 vistas quietas → assets/sources/zombi-vecina-48/rotations/ (y las 3 en espejo)
  py tools/zombi_gpt.py andar south    andar de frente (andar-s.webp) → assets/sources/zombi-vecina-48/walk/south-<n>.png
  py tools/zombi_gpt.py andar east     de perfil (andar-e.webp) → walk/east-<n>.png y, en espejo, walk/west-<n>.png
  py tools/zombi_gpt.py rellenar       las animaciones que aún no hay, con el dibujo quieto de su dirección
"""
import os
import sys
from collections import deque
from PIL import Image, ImageEnhance, ImageOps

FUENTE = "assets/sources/zombi-vecina-gpt"   # las imágenes de GPT
DESTINO = "assets/sources/zombi-vecina-48"   # lo que lee tools/zombi.py
LIENZO = 48
# las vistas de la fila, de izquierda a derecha, y las que salen de ellas en espejo
VISTAS = ["south", "south-east", "east", "north-east", "north"]
ESPEJO = {"south-west": "south-east", "west": "east", "north-west": "north-east"}


def sin_fondo(im):
    """El negro puro que se llega desde el borde, transparente"""
    im = im.convert("RGBA")
    W, H = im.size
    px = im.load()
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 10:
            continue
        fondo[y * W + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(H):
        for x in range(W):
            if fondo[y * W + x]:
                px[x, y] = (0, 0, 0, 0)
    return im


def separar(im):
    """Los dibujos de la fila, de izquierda a derecha: cada tramo de columnas con algo, recortado a lo que tiene"""
    alfa = im.split()[3]
    W, H = im.size
    llenas = [alfa.crop((x, 0, x + 1, H)).getbbox() is not None for x in range(W)]
    trozos, empieza = [], None
    for x, llena in enumerate(llenas + [False]):
        if llena and empieza is None:
            empieza = x
        elif not llena and empieza is not None:
            if x - empieza > 20:   # (motas sueltas, fuera)
                trozo = im.crop((empieza, 0, x, H))
                caja = trozo.getbbox()
                # el dibujo, dónde acaban sus pies y dónde está su centro en la fila (en píxeles de la imagen)
                trozos.append((trozo.crop(caja), caja[3], empieza + (caja[0] + caja[2]) / 2))
            empieza = None
    return trozos


def filas(im):
    """Las filas de dibujos de la imagen, de arriba abajo: cada tramo de filas de píxeles con algo"""
    alfa = im.split()[3]
    W, H = im.size
    llenas = [alfa.crop((0, y, W, y + 1)).getbbox() is not None for y in range(H)]
    tramos, empieza = [], None
    for y, llena in enumerate(llenas + [False]):
        if llena and empieza is None:
            empieza = y
        elif not llena and empieza is not None:
            if y - empieza > 20:
                tramos.append(im.crop((0, empieza, W, y)))
            empieza = None
    return tramos


def reducir(dibujo, escala):
    """A la escala del juego mezclando colores (premultiplicado: lo transparente no tiñe los bordes) y el borde, sin
    medias tintas"""
    ancho = max(1, round(dibujo.width / escala))
    alto = max(1, round(dibujo.height / escala))
    salida = dibujo.convert("RGBa").resize((ancho, alto), Image.BOX).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    return contorno(nitido(salida))


def nitido(dibujo):
    """Al mezclar, los colores se lavan: un poco más de contraste y de color, para que no desentone con los de PixelLab"""
    alfa = dibujo.split()[3]
    rgb = ImageEnhance.Color(ImageEnhance.Contrast(dibujo.convert("RGB")).enhance(1.25)).enhance(1.15)
    rgb.putalpha(alfa)
    return rgb


def contorno(dibujo):
    """El contorno oscuro de los zombis de PixelLab: el píxel del borde (el que toca lo transparente), oscurecido"""
    px = dibujo.load()
    W, H = dibujo.size
    borde = []
    for y in range(H):
        for x in range(W):
            if px[x, y][3] and any(not (0 <= x + dx < W and 0 <= y + dy < H) or not px[x + dx, y + dy][3]
                                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                borde.append((x, y))
    for x, y in borde:
        r, g, b, a = px[x, y]
        px[x, y] = (round(r * 0.3), round(g * 0.3), round(b * 0.3), a)
    return dibujo


def en_lienzo(dibujo, corrido=0.0):
    """En su lienzo de 48 × 48: en medio (o "corrido" píxeles a un lado, en las animaciones) y con los pies en la
    última fila (como los de PixelLab, fila 46)"""
    lienzo = Image.new("RGBA", (LIENZO, LIENZO), (0, 0, 0, 0))
    lienzo.paste(dibujo, (round(LIENZO / 2 + corrido - dibujo.width / 2), LIENZO - 1 - dibujo.height), dibujo)
    return lienzo


def personaje():
    im = Image.open(os.path.join(FUENTE, "personaje.webp"))
    escala = 8 * im.width / 2016
    trozos = separar(sin_fondo(im))
    if len(trozos) != len(VISTAS):
        sys.exit("Salen %d dibujos y tienen que ser %d" % (len(trozos), len(VISTAS)))
    carpeta = os.path.join(DESTINO, "rotations")
    os.makedirs(carpeta, exist_ok=True)
    hechas = {}
    for vista, (dibujo, _, _) in zip(VISTAS, trozos):
        hechas[vista] = en_lienzo(reducir(dibujo, escala))
    for vista, de in ESPEJO.items():
        hechas[vista] = ImageOps.mirror(hechas[de])
    for vista, dibujo in hechas.items():
        dibujo.save(os.path.join(carpeta, vista + ".png"))
        print("%s: %s" % (vista, dibujo.getbbox()))


# Una animación de una dirección (andar-s.webp: andar de frente): cada fotograma de la fila, a la misma escala que el
# personaje y en su lienzo, en <animación>/<dirección>-<n>.png; el 0 es el dibujo quieto (así lo quiere tools/zombi.py)
def animacion(anim, vista):
    nombres = {"andar": "walk", "ataque": "ataque", "golpe": "golpe", "muerte": "muerte"}
    corta = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne", "north": "n"}[vista]
    im = sin_fondo(Image.open(os.path.join(FUENTE, "%s-%s.webp" % (anim, corta))))
    # los fotogramas, fila a fila (GPT puede ponerlos en varias filas, que se leen como un libro)
    # y cuánto se aparta cada uno del centro de su hueco (GPT los reparte en huecos iguales): al caer o al echarse
    # atrás, el dibujo se mueve dentro de su hueco, y así se mueve igual en el lienzo
    trozos = []
    for fila in filas(im):
        suyos = separar(fila)
        hueco = im.width / len(suyos)
        trozos += [(d, (centro - (i + 0.5) * hueco)) for i, (d, _, centro) in enumerate(suyos)]
    # la escala: que el primero (de pie, como empiezan todas) mida de alto lo que el dibujo quieto
    quieto = Image.open(os.path.join(DESTINO, "rotations", vista + ".png"))
    caja = quieto.getbbox()
    escala = trozos[0][0].height / (caja[3] - caja[1])
    carpeta = os.path.join(DESTINO, nombres[anim])
    os.makedirs(carpeta, exist_ok=True)
    quieto.save(os.path.join(carpeta, "%s-0.png" % vista))
    # la dirección del otro lado (de perfil a la derecha → a la izquierda), la misma en espejo
    espejo = [otra for otra, de in ESPEJO.items() if de == vista]
    for otra in espejo:
        ImageOps.mirror(quieto).save(os.path.join(carpeta, "%s-0.png" % otra))
    for n, (dibujo, aparte) in enumerate(trozos, 1):
        corrido = (aparte - trozos[0][1]) / escala   # (el primero, en medio)
        hecho = en_lienzo(reducir(dibujo, escala), corrido)
        hecho.save(os.path.join(carpeta, "%s-%d.png" % (vista, n)))
        for otra in espejo:
            ImageOps.mirror(hecho).save(os.path.join(carpeta, "%s-%d.png" % (otra, n)))
        print("%s %s-%d%s" % (anim, vista, n, " (y en espejo: %s)" % otra if espejo else ""))


# Mientras solo estén hechas algunas direcciones (la prueba empezó solo de frente): las demás animaciones, con el
# dibujo quieto de su dirección repetido (tools/zombi.py quiere las 8 y con los mismos fotogramas)
def rellenar():
    rotaciones = os.path.join(DESTINO, "rotations")
    for anim in ["walk", "ataque", "golpe", "muerte"]:
        carpeta = os.path.join(DESTINO, anim)
        n = 0
        while os.path.exists(os.path.join(carpeta, "south-%d.png" % (n + 1))):
            n += 1
        for vista in VISTAS + list(ESPEJO):
            if os.path.exists(os.path.join(carpeta, "%s-1.png" % vista)) and vista != "south":
                continue
            if vista == "south":
                continue
            quieto = Image.open(os.path.join(rotaciones, vista + ".png"))
            for i in range(n + 1):
                quieto.save(os.path.join(carpeta, "%s-%d.png" % (vista, i)))
        print("%s: %d fotogramas; las direcciones sin hacer, quietas" % (anim, n))


if __name__ == "__main__":
    if sys.argv[1:] == ["rellenar"]:
        rellenar()
        sys.exit()
    if len(sys.argv) > 2:
        animacion(sys.argv[1], sys.argv[2])   # py tools/zombi_gpt.py andar south
    else:
        personaje()
