# El suelo y la pared de la sala de venta de la tienda de ropa (18 nov, el dueño, a partir de una foto suya de una
# boutique: tarima de roble claro, pared rosa empolvado y rodapié dorado acanalado), sacados de dos imágenes de GPT:
#   assets/sources/suelos/ropa-suelo-gpt.webp → assets/sprites/suelo-ropa.png  (16 filas de tablas de 8 píxeles, 128 × 128)
#   assets/sources/suelos/ropa-pared-gpt.webp → assets/sprites/pared-ropa.png  (192 × 64: la pared alta, de 4 casillas)
#                                                y techo-ropa.png (el remate de arriba, que con "cajas" no se ve)
# y, desde el 19 nov, sus tres destrozados (ropa-suelo-destrozado<N>-gpt → suelo-ropa-d<N>, ropa-pared-destrozada<N>-gpt → pared-ropa-d<N>),
# que en la tienda se mezclan a trozos (mapa.gd, MEZCLA_TIENDA)
# Como tools/galeria_gpt.py: cada trozo de tabla se reduce por dentro MEZCLANDO colores con LANCZOS («como los muebles») y
# las juntas se pintan aparte, de un píxel y con su color de la imagen, así salen rectas y la textura empalma consigo
# misma. Los listones del rodapié, tan finos que al reducirlos se emborronan, se pintan uno claro y uno oscuro sobre el
# color de cada fila del rodapié reducido.
#   py tools/ropa_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

FILAS = 16          # las filas de tablas de la imagen de GPT (de izquierda a derecha)
TAM = 128           # el suelo: 128 × 128 (cada fila, 8 píxeles: 1 de junta y 7 de madera)
PARED = (192, 64)   # la pared: 64 de alto, la pared alta de las tiendas (Tienda.TIPOS "sube": 4)
RODAPIE = 0.866     # dónde empieza el rodapié en la imagen de la pared (de arriba abajo, de 0 a 1)


def guardar(im, nombre):
    im.save(f'assets/sprites/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [0, 0], 'scale': 1, 'suavizar': 0,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'assets/sprites/{nombre}.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f'{nombre}: {im.width}x{im.height}')


def reducir(im, caja, ancho, alto):
    # mezclando colores con LANCZOS, de la caja (x0, y0, x1, y1, en píxeles de la imagen, con decimales)
    return np.asarray(im.resize((ancho, alto), Image.LANCZOS, box=caja)).astype(float)


def juntas_cortas(col, local):
    # las columnas de una fila mucho más oscuras que la madera: con «local» (los suelos destrozados), más oscuras que la madera de
    # a su lado (a 6 píxeles), para que una quemadura o una mancha grande no se tomen por juntas
    if not local:
        return [x for x in range(len(col)) if col[x] < np.median(col) - 25]
    n = len(col)
    return [x for x in range(n) if col[x] < min(col[(x - 6) % n], col[(x + 6) % n]) - 20]


def suelo(origen='ropa-suelo-gpt', nombre='suelo-ropa', local=False):
    im = Image.open(f'assets/sources/suelos/{origen}.webp').convert('RGB')
    a = np.asarray(im).astype(float)
    W, H = im.size
    alto = H / FILAS
    tres = Image.fromarray(np.tile(a, (1, 3, 1)).astype(np.uint8))   # repetida a los lados: los trozos que dan la vuelta
    luz = a.mean(axis=2)
    out = np.zeros((TAM, TAM, 3))
    juntas = []   # los píxeles de las juntas, para su color
    for f in range(FILAS):
        y0, y1 = f * alto, (f + 1) * alto
        # la junta larga, arriba de la fila
        juntas.append(a[int(y0):int(y0) + 2].reshape(-1, 3))
        # las juntas cortas de esta fila: las columnas mucho más oscuras que la madera de su fila
        dentro = luz[int(y0) + 6:int(y1) - 4]
        col = dentro.mean(axis=0)
        cortes = juntas_cortas(col, local)
        # (cada junta son 2 o 3 columnas seguidas: su medio)
        grupos = []
        for x in cortes:
            if grupos and x - grupos[-1][-1] <= 2:
                grupos[-1].append(x)
            else:
                grupos.append([x])
        xs = [sum(g) / len(g) for g in grupos]
        for g in grupos:
            juntas.append(a[int(y0) + 6:int(y1) - 4, g[0]:g[-1] + 1].reshape(-1, 3))
        destino = [round(x * TAM / W) % TAM for x in xs]
        fila = 1 + f * 8   # la primera de madera (la de encima es la junta)
        # cada tabla, de una junta a la siguiente (la última da la vuelta por el borde)
        for i in range(len(xs)):
            xa, xb = xs[i], xs[(i + 1) % len(xs)] + (W if i == len(xs) - 1 else 0)
            da, db = destino[i], destino[(i + 1) % len(xs)] + (TAM if i == len(xs) - 1 else 0)
            ancho = db - da - 1
            if ancho <= 0:
                continue
            trozo = reducir(tres, (W + xa + 2, y0 + 3, W + xb - 2, y1 - 1), ancho, 7)
            for k in range(ancho):
                out[fila:fila + 7, (da + 1 + k) % TAM] = trozo[:, k]
    color_junta = np.median(np.concatenate(juntas), axis=0)
    for f in range(FILAS):
        out[f * 8] = color_junta
    # las juntas cortas, otra vez fila a fila (ya con el color de junta de todas)
    for f in range(FILAS):
        y0, y1 = f * alto, (f + 1) * alto
        col = luz[int(y0) + 6:int(y1) - 4].mean(axis=0)
        xs = juntas_cortas(col, local)
        for x in xs:
            out[1 + f * 8:8 + f * 8, round(x * TAM / W) % TAM] = color_junta
    guardar(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)), nombre)


def pared(origen='ropa-pared-gpt', nombre='pared-ropa', destrozada=False):
    im = Image.open(f'assets/sources/suelos/{origen}.webp').convert('RGB')
    W, H = im.size
    ancho, alto = PARED
    rodapie = RODAPIE
    if destrozada:   # en las destrozadas el rodapié no empieza justo a la misma altura: la primera fila dorada (azul muy bajo)
        m = np.asarray(im).astype(float).mean(axis=1)
        rodapie = next(i for i in range(H // 2, H) if m[i, 0] - m[i, 2] > 90) / H
    corte = round(RODAPIE * alto)            # la primera fila del rodapié en la pequeña (en todas, la misma)
    y_rod = rodapie * H
    out = np.zeros((alto, ancho, 3))
    # el yeso rosa: reducido entero
    out[:corte] = reducir(im, (0, 0, W, y_rod - 3), ancho, corte)
    # el rodapié: el color de cada fila reducido (con su canto de arriba) y los listones, uno claro y uno oscuro
    rod = reducir(im, (0, y_rod, W, H), 1, alto - corte)[:, 0]
    # en las destrozadas, el rodapié reducido entero: sus listones salen igual, pero con sus golpes, su suciedad y sus trozos arrancados
    entero = reducir(im, (0, y_rod, W, H), ancho, alto - corte)
    for i in range(alto - corte):
        y = corte + i
        for x in range(ancho):
            base = rod[i]
            if destrozada:
                c = entero[i, x]
                if c[0] - c[2] < 70:   # no es dorado (un trozo arrancado): tal cual
                    out[y, x] = c
                    continue
                base = c
            out[y, x] = base * (1.15 if i == 0 else 1.18 if x % 2 == 0 else 0.78)   # el canto de arriba brilla
    guardar(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)), nombre)
    if destrozada:
        return
    # el remate de arriba (con "cajas" no se ve, pero cada estilo lo lleva): el rosa, un poco más oscuro
    techo = np.tile(out[2:3] * 0.85, (6, 1, 1))
    guardar(Image.fromarray(np.clip(techo, 0, 255).astype(np.uint8)), 'techo-ropa')


suelo()
pared()
# los destrozados (19 nov, el dueño: «se ven demasiado bien»), tres de cada, de GPT a partir de los de arriba
for i in (1, 2, 3):
    suelo(f'ropa-suelo-destrozado{i}-gpt', f'suelo-ropa-d{i}', local=True)
    pared(f'ropa-pared-destrozada{i}-gpt', f'pared-ropa-d{i}', destrozada=True)
# los tres suelos, del mismo color de media (GPT los dejó cada uno un poco distinto): en la tienda se mezclan a trozos (mapa.gd,
# MEZCLA_TIENDA) y si no, se verían los cuadros
suelos = [np.asarray(Image.open(f'assets/sprites/suelo-ropa-d{i}.png').convert('RGB')).astype(float) for i in (1, 2, 3)]
media = np.mean([s.reshape(-1, 3).mean(axis=0) for s in suelos], axis=0)
for i, s in zip((1, 2, 3), suelos):
    guardar(Image.fromarray(np.clip(s * media / s.reshape(-1, 3).mean(axis=0), 0, 255).astype(np.uint8)), f'suelo-ropa-d{i}')

# y el almacén de la tienda, destrozado (19 nov, el dueño; GPT, a partir del hormigón y las tablas del pasillo de los trasteros), tres
# suelos y tres paredes que se mezclan como los de la sala de venta: reducidos como los de los trasteros (tools/dormitorios.py), el
# suelo entero a 128 × 128 y la pared entera a un trozo de 48 × 48 (sin espejo: cada trozo sale de uno), con la última fila más oscura
for i in (1, 2, 3):
    s = Image.open(f'assets/sources/suelos/almacen-ropa-suelo-destrozado{i}-gpt.webp').convert('RGB')
    guardar(s.resize((128, 128), Image.LANCZOS), f'suelo-almacen-ropa-d{i}')
    p = Image.open(f'assets/sources/suelos/almacen-ropa-pared-destrozada{i}-gpt.webp').convert('RGB').resize((48, 48), Image.LANCZOS)
    for x in range(48):
        p.putpixel((x, 47), tuple(int(v * 0.72) for v in p.getpixel((x, 47))))
    guardar(p, f'pared-almacen-ropa-d{i}')


# y su aseo, destrozado (19 nov, el dueño; GPT, a partir del azulejo blanco y la baldosa beis del vestuario de Johnny): tres suelos
# (128 × 128, 8 × 8 baldosas) y tres paredes (48 × 48, 6 × 6 azulejos) que se mezclan igual. Para que los trozos no se vean como
# cuadrados de suelos distintos, a cada uno se le quita su mancha de color «de fondo» (lo borroso, no los detalles) y se le pone la de
# los tres: del todo en los bordes y solo un poco en el centro. En la pared, fila a fila (así empalman izquierda con derecha).
def _borroso(im, r):
    from PIL import ImageFilter
    w, h = im.size
    m = Image.new('RGB', (w * 3, h * 3))   # rodeado de copias de sí mismo, para que los bordes no salgan raros
    for i in range(3):
        for j in range(3):
            m.paste(im, (i * w, j * h))
    return m.filter(ImageFilter.GaussianBlur(r)).crop((w, h, 2 * w, 2 * h))


def _igualar(ims, r, k, centro, solo_lados):
    bs = [np.asarray(_borroso(im, r)).astype(float) for im in ims]
    h, w = bs[0].shape[:2]
    fondo = np.mean(bs, axis=0).mean(axis=1, keepdims=True) if solo_lados else np.mean(bs, axis=(0, 1, 2))
    x = np.arange(w)[None, :]; y = np.arange(h)[:, None]
    d = np.minimum(x, w - 1 - x) + 0 * y if solo_lados else np.minimum(np.minimum(x, w - 1 - x), np.minimum(y, h - 1 - y))
    a = np.where(d <= 1, 1.0, np.maximum(centro, 1.0 - (1.0 - centro) * (d - 1) / k))[..., None]
    return [Image.fromarray(np.clip(np.round(np.asarray(im).astype(float) - a * (b - fondo)), 0, 255).astype(np.uint8)) for im, b in zip(ims, bs)]


suelos = [Image.open(f'assets/sources/suelos/aseo-ropa-suelo-destrozado{i}-gpt.webp').convert('RGB').resize((128, 128), Image.LANCZOS) for i in (1, 2, 3)]
paredes = [Image.open(f'assets/sources/suelos/aseo-ropa-pared-destrozada{i}-gpt.webp').convert('RGB').resize((48, 48), Image.LANCZOS) for i in (1, 2, 3)]
for i, s, p in zip((1, 2, 3), _igualar(suelos, 10, 28, 0.45, False), _igualar(paredes, 5, 12, 0.45, True)):
    guardar(s, f'suelo-aseo-ropa-d{i}')
    for x in range(48):   # la última fila, más oscura, como la del vestuario
        p.putpixel((x, 47), tuple(int(v * 0.68) for v in p.getpixel((x, 47))))
    guardar(p, f'pared-aseo-ropa-d{i}')
