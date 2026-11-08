"""Un zombi hecho con GPT (la prueba del 8 nov fue la vecina, «vecino 2»), pasado a los dibujos que monta tools/zombi.py.

GPT dibuja cada cosa en una sola imagen, sobre fondo negro puro, con las vistas o los fotogramas en fila: así se parece
más de uno a otro. Esta herramienta:
  - quita el fondo (solo el negro que se llega desde el borde: los contornos, casi negros, se quedan),
  - separa los dibujos de la fila (por las columnas vacías que hay entre ellos),
  - los reduce todos con la MISMA escala (cada píxel, la media de su trozo, como los muebles de GPT:
    tools/muebles_gpt.py), para que no cambie de tamaño de uno a otro,
  - y los pone en su lienzo de 48 × 48 con los pies abajo y en medio, como los dibujos de PixelLab.

La escala sale de la referencia que se le da a GPT (capturas/referencia-vecino.png: el vecino a 8 píxeles de la imagen
por píxel del juego, en 2016 de ancho): GPT la devuelve a 2000 de ancho, así que 8 × 2000 / 2016.

Cada zombi tiene su ficha en ZOMBIS (sus carpetas). Sin decir cuál, es la vecina; para otro, su nombre delante:
  py tools/zombi_gpt.py --zombi normal personaje      (el vecino con GPT: zombi-normal-gpt → zombi-normal-gpt-48)
  py tools/zombi_gpt.py --zombi rapido personaje      (el crío con GPT: zombi-rapido-gpt → zombi-rapido-gpt-48;
                                                       su referencia, capturas/referencia-rapido.png)
  py tools/zombi_gpt.py --zombi lento personaje       (el arrastrado con GPT: zombi-lento-gpt → zombi-lento-gpt-48;
                                                       su referencia, capturas/referencia-lento.png)

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

# Cada zombi: dónde están sus imágenes de GPT, dónde van los dibujos que lee tools/zombi.py y hasta qué gris se toma
# por fondo, y de qué tamaño es el lienzo del ataque, el golpe y la muerte. Con 10, al vecino se le comía a trozos la pierna de detrás (los vaqueros en sombra, casi negros, se
# confundían con el fondo y salían huecos que parpadeaban al andar); con 5 se queda entera y sin cerco oscuro. El
# lienzo: el zarpazo del vecino, de perfil, alarga los brazos más allá de los 48 píxeles y se le cortaban las manos;
# en 96 cabe (tools/zombi.py coloca cada fotograma buscando en él el dibujo quieto, sea cual sea su tamaño). Y si el
# golpe va con los pies clavados: cada fotograma se coloca por sus propios pies, no por la rejilla de la fila (en el del
# vecino, al echarse atrás, GPT le corría los pies 2 o 3 píxeles adelante y parecía que resbalaba). Y el retoque de
# color (contraste, brillo, color): el vecino salía mucho más apagado que el de PixelLab, al lado del otro; con algo más
# de los tres se ve igual de vivo sin perder el volumen (lo pidió el dueño)
ZOMBIS = {
    "vecina": ("assets/sources/zombi-vecina-gpt", "assets/sources/zombi-vecina-48", 10, 48, False, (1.08, 1.0, 1.0)),
    "normal": ("assets/sources/zombi-normal-gpt", "assets/sources/zombi-normal-gpt-48", 5, 96, True, (1.2, 1.12, 1.1)),
    "rapido": ("assets/sources/zombi-rapido-gpt", "assets/sources/zombi-rapido-gpt-48", 5, 96, True, (1.2, 1.12, 1.1)),
    "lento": ("assets/sources/zombi-lento-gpt", "assets/sources/zombi-lento-gpt-48", 5, 96, True, (1.2, 1.12, 1.1)),
}
FUENTE, DESTINO, FONDO, LIENZO_ANIM, GOLPE_CLAVADO, RETOQUE = ZOMBIS["vecina"]
# Los que corren (el crío): al andar, la cabeza va a la altura que la pone GPT (casi siempre la misma) y los pies se
# levantan del suelo cuando van en el aire. Con los pies siempre abajo, como los que andan, la cabeza le subía y bajaba
# hasta 5 píxeles de un fotograma a otro y daba saltos
CORRE = False
# El lienzo del andar: 48, salvo los que se estiran (el crío corriendo, y el arrastrado, que de perfil echa un brazo
# muy adelante y el muñón detrás: el de PixelLab ya andaba en 60)
LIENZO_ANDAR = {"rapido": 64, "lento": 64}
# Los que van por el suelo (el arrastrado): en el ataque, el golpe y la muerte, cada fotograma a la altura a la que lo
# dibuja GPT, no con lo más bajo en el suelo. Al dar el zarpazo levanta las dos manos y, con lo más bajo abajo, todo
# el cuerpo se hundía 5 píxeles justo al atacar
ALTURA_GPT = False
ANDAR = 48
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
        if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= FONDO:
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
    """Al mezclar, los colores se lavan un poco: algo más de contraste. Poco (el 8 nov, de 1,25 y más color a 1,08):
    así se quedan las sombras suaves y el volumen de la imagen, como los muebles de GPT (lo eligió el dueño)"""
    alfa = dibujo.split()[3]
    rgb = ImageEnhance.Contrast(dibujo.convert("RGB")).enhance(RETOQUE[0])   # (cada zombi, el suyo: ZOMBIS)
    if RETOQUE[1] != 1.0:
        rgb = ImageEnhance.Brightness(rgb).enhance(RETOQUE[1])
    if RETOQUE[2] != 1.0:
        rgb = ImageEnhance.Color(rgb).enhance(RETOQUE[2])
    rgb.putalpha(alfa)
    return rgb


def contorno(dibujo):
    """Un contorno suave: el píxel del borde (el que toca lo transparente), algo más oscuro (al 60 %; no casi negro como
    los de PixelLab, que la dejaba plana, de cómic), para que se recorte contra el suelo sin perder el volumen"""
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
        px[x, y] = (round(r * 0.6), round(g * 0.6), round(b * 0.6), a)
    return dibujo


def en_lienzo(dibujo, corrido=0.0, lado=LIENZO, arriba=None):
    """En su lienzo de 48 × 48 (o de "lado"): en medio (o "corrido" píxeles a un lado, en las animaciones) y con los
    pies en la última fila (como los de PixelLab, fila 46)"""
    lienzo = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    y = lado - 1 - dibujo.height
    if arriba is not None:   # (el que corre: la cabeza a esa altura; los pies, nunca por debajo del suelo)
        y = min(y, round(arriba))
    lienzo.paste(dibujo, (round(lado / 2 + corrido - dibujo.width / 2), y), dibujo)
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


def fijo(dibujo, centro, por_la_cabeza):
    """El punto de un dibujo que no debería moverse de lado (en las mismas medidas que "centro", el centro de su caja):
    el centro de la cabeza (su décima parte de arriba) o el de los pies (la de abajo)"""
    alto = max(1, dibujo.height // 10)
    trozo = dibujo.crop((0, 0, dibujo.width, alto)) if por_la_cabeza else dibujo.crop((0, dibujo.height - alto, dibujo.width, dibujo.height))
    caja = trozo.getbbox() or (0, 0, dibujo.width, alto)
    return centro - dibujo.width / 2 + (caja[0] + caja[2]) / 2


def recta(puntos):
    """La rejilla de una fila: la recta (principio, paso) que mejor pasa por esos puntos, uno por columna"""
    n = len(puntos)
    if n < 2:
        return (puntos[0], 0.0)
    medio_i, medio = (n - 1) / 2, sum(puntos) / n
    paso = sum((i - medio_i) * (p - medio) for i, p in enumerate(puntos)) / sum((i - medio_i) ** 2 for i in range(n))
    return (medio - paso * medio_i, paso)


# Una animación de una dirección (andar-s.webp: andar de frente): cada fotograma de la fila, a la misma escala que el
# personaje y en su lienzo, en <animación>/<dirección>-<n>.png; el 0 es el dibujo quieto (así lo quiere tools/zombi.py)
def animacion(anim, vista):
    nombres = {"andar": "walk", "ataque": "ataque", "golpe": "golpe", "muerte": "muerte"}
    corta = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne", "north": "n"}[vista]
    im = sin_fondo(Image.open(os.path.join(FUENTE, "%s-%s.webp" % (anim, corta))))
    # Dónde va cada fotograma en el lienzo. GPT los pone en una rejilla de columnas iguales, pero no de 1/6 del ancho
    # justo (suele ser algo menos, y con márgenes): suponerlo hacía que la vecina se fuera corriendo de lado hasta 17
    # píxeles en cada fila y diera un salto al empezar la siguiente. Así que la rejilla se mide en cada fila, con un
    # punto que no debería moverse: al andar, la cabeza; en lo demás, los pies (se quedan plantados al atacar, al
    # recibir el golpe y al empezar a caer). La muerte acaba tendida y los pies ya no valen: su segunda fila usa las
    # columnas de la primera (las dos filas comparten rejilla). Lo que cada dibujo se aparta de su columna es lo que
    # se mueve de verdad (echarse adelante, caer), y así se mueve en el lienzo
    por_la_cabeza = anim == "andar"
    # El arrastrado, de perfil y en diagonal de frente: al atacar, lo más bajo son las manos, que se van adelante, y el
    # cuerpo entero se corría 16 píxeles hasta salirse del lienzo. Lo que se queda quieto es el final del cuerpo, que
    # en esas vistas es su borde izquierdo
    por_detras = ALTURA_GPT and anim != "andar" and vista in ("south-east", "east")
    trozos, rejilla = [], None
    for numero_fila, fila in enumerate(filas(im)):
        suyos = separar(fila)
        fijos = [fijo(d, centro, por_la_cabeza) for d, _, centro in suyos]
        if por_detras:
            fijos = [centro - d.width / 2 for d, _, centro in suyos]   # (su borde izquierdo: el final del cuerpo)
        if not (anim == "muerte" and numero_fila > 0 and rejilla):
            rejilla = recta(fijos)
        # lo alta que va la cabeza de cada uno respecto a las de su fila (para el que corre)
        cimas = [abajo - d.height for d, abajo, _ in suyos]
        cima = sum(cimas) / len(cimas)
        if ALTURA_GPT and anim != "andar":
            # (el arrastrado: lo que cada uno queda por encima del suelo de su fila, el más bajo de ella)
            suelo = max(abajo for _, abajo, _ in suyos)
            cimas, cima = [abajo - suelo for _, abajo, _ in suyos], 0
        if anim == "golpe" and GOLPE_CLAVADO:
            trozos += [(d, centro, f, c - cima) for (d, _, centro), f, c in zip(suyos, fijos, cimas)]   # cada uno, por sus pies
        else:
            trozos += [(d, centro, rejilla[0] + rejilla[1] * i, c - cima) for i, ((d, _, centro), c) in enumerate(zip(suyos, cimas))]
    # la escala: que el primero (de pie, como empiezan todas) mida de alto lo que el dibujo quieto
    quieto = Image.open(os.path.join(DESTINO, "rotations", vista + ".png"))
    caja = quieto.getbbox()
    escala = trozos[0][0].height / (caja[3] - caja[1])
    if ALTURA_GPT and anim == "muerte":
        # (el arrastrado: al empezar a caer GPT le alza la cabeza y, midiendo por el alto, encogía 6 píxeles de golpe;
        # por el ancho, que no cambia, se queda de su tamaño)
        escala = trozos[0][0].width / (caja[2] - caja[0])
    # el punto fijo del dibujo quieto: ahí cae la columna de cada fotograma (así no salta al pasar de quieta a andar)
    sitio = caja[0] if por_detras else fijo(quieto.crop(caja), (caja[0] + caja[2]) / 2, por_la_cabeza)
    carpeta = os.path.join(DESTINO, nombres[anim])
    os.makedirs(carpeta, exist_ok=True)
    # el lienzo: al andar, el de 48; en lo demás, el del zombi (el dibujo quieto, abajo y en medio)
    # (el que corre estira mucho la pierna de atrás: de perfil se le cortaba el pie en 48; en 64 cabe)
    lado = ANDAR if anim == "andar" else LIENZO_ANIM
    if lado != LIENZO:
        grande = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
        grande.paste(quieto, ((lado - LIENZO) // 2, lado - LIENZO))
        quieto = grande
    quieto.save(os.path.join(carpeta, "%s-0.png" % vista))
    # la dirección del otro lado (de perfil a la derecha → a la izquierda), la misma en espejo
    espejo = [otra for otra, de in ESPEJO.items() if de == vista]
    for otra in espejo:
        ImageOps.mirror(quieto).save(os.path.join(carpeta, "%s-0.png" % otra))
    for n, (dibujo, centro, columna, cima) in enumerate(trozos, 1):
        corrido = sitio - LIENZO / 2 + (centro - columna) / escala
        arriba = caja[1] + (lado - LIENZO) + cima / escala if CORRE and anim == "andar" else None
        reducido = reducir(dibujo, escala)
        if ALTURA_GPT and anim != "andar":
            arriba = lado - 1 - reducido.height + cima / escala
        hecho = en_lienzo(reducido, corrido, lado, arriba)
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
    if sys.argv[1:2] == ["--zombi"]:
        if len(sys.argv) < 3 or sys.argv[2] not in ZOMBIS:
            sys.exit("Zombis que conoce: " + ", ".join(ZOMBIS))
        FUENTE, DESTINO, FONDO, LIENZO_ANIM, GOLPE_CLAVADO, RETOQUE = ZOMBIS[sys.argv[2]]
        CORRE = sys.argv[2] == "rapido"
        ANDAR = LIENZO_ANDAR.get(sys.argv[2], LIENZO)
        ALTURA_GPT = sys.argv[2] == "lento"
        del sys.argv[1:3]
    if sys.argv[1:] == ["rellenar"]:
        rellenar()
        sys.exit()
    if len(sys.argv) > 2:
        animacion(sys.argv[1], sys.argv[2])   # py tools/zombi_gpt.py andar south
    else:
        personaje()
