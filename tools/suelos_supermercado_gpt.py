# El suelo y la pared de la sala de venta y de la cámara frigorífica del supermercado, destrozados (25 nov, el dueño; de GPT, a partir
# de fotos suyas: la sala de venta, baldosa grande de porcelánico gris claro y, en la pared, listones verticales de madera clara arriba,
# un panel de porcelánico gris abajo y rodapié antracita; la cámara, paneles de resina gris oscuro con juntas claras y paneles aislantes
# blancos con rodapié de acero inoxidable, con escarcha y hielo). Tres suelos y tres paredes, que en la tienda se mezclan a trozos (mapa.gd, MEZCLA_TIENDA), hechos como los de la
# farmacia (tools/suelos_farmacia_gpt.py, de donde sale esta):
#   assets/sources/suelos/<sala>-supermercado-suelo-destrozado<N>-gpt.webp → assets/sprites/suelo-<sala>-supermercado-d<N>.png (128 × 128)
#   assets/sources/suelos/<sala>-supermercado-pared-destrozada<N>-gpt.webp → assets/sprites/pared-<sala>-supermercado-d<N>.png (48 × 48)
# con <sala> venta o camara.
# El suelo, 8 × 8 baldosas de 16 píxeles (cada baldosa por dentro y las juntas aparte); la pared, entera a 48 × 48. A los tres de
# cada uno se les iguala la mancha de luz de fondo, para que al mezclarse no se vean los cuadros.
#   py tools/suelos_supermercado_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image, ImageFilter

BALDOSAS = 8   # por lado, en la imagen de GPT y en el suelo
LADO = 16      # cada baldosa en el suelo: 1 píxel de junta y 15 de baldosa
MEDIA_JUNTA = 5.0   # media junta en la imagen de GPT (la junta, centrada en cada múltiplo de 1254 / 8), en píxeles


def guardar(im, nombre):
    im.save(f'assets/sprites/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [0, 0], 'scale': 1, 'suavizar': 0,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'assets/sprites/{nombre}.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f'{nombre}: {im.width}x{im.height}')


def _borroso(im, r):
    w, h = im.size
    m = Image.new('RGB', (w * 3, h * 3))   # rodeado de copias de sí mismo, para que los bordes no salgan raros
    for i in range(3):
        for j in range(3):
            m.paste(im, (i * w, j * h))
    return m.filter(ImageFilter.GaussianBlur(r)).crop((w, h, 2 * w, 2 * h))


def _igualar(ims, r, k, centro, solo_lados, solo_luz=False):
    bs = [np.asarray(_borroso(im, r)).astype(float) for im in ims]
    h, w = bs[0].shape[:2]
    fondo = np.mean(bs, axis=0).mean(axis=1, keepdims=True) if solo_lados else np.mean(bs, axis=(0, 1, 2))
    x = np.arange(w)[None, :]; y = np.arange(h)[:, None]
    d = np.minimum(x, w - 1 - x) + 0 * y if solo_lados else np.minimum(np.minimum(x, w - 1 - x), np.minimum(y, h - 1 - y))
    a = np.where(d <= 1, 1.0, np.maximum(centro, 1.0 - (1.0 - centro) * (d - 1) / k))[..., None]
    # (con solo_luz, solo se iguala lo claro u oscuro, no el color: en la sala de venta, las manchas grandes de pintura amarilla
    # dejaban un halo azulado)
    dif = [(b - fondo).mean(axis=-1, keepdims=True) if solo_luz else b - fondo for b in bs]
    return [Image.fromarray(np.clip(np.round(np.asarray(im).astype(float) - a * d), 0, 255).astype(np.uint8)) for im, d in zip(ims, dif)]


def suelo(origen):
    im = Image.open(origen).convert('RGB')
    paso = im.width / BALDOSAS
    # la imagen rodeada de copias de sí misma, para poder coger la junta del borde entera (media a cada lado)
    m = Image.new('RGB', (im.width * 3, im.height * 3))
    for i in range(3):
        for j in range(3):
            m.paste(im, (i * im.width, j * im.height))
    o = im.width
    sal = Image.new('RGB', (BALDOSAS * LADO, BALDOSAS * LADO))
    for by in range(BALDOSAS):
        for bx in range(BALDOSAS):
            x0, y0 = o + bx * paso, o + by * paso   # el centro de la junta de la izquierda y de la de arriba
            x1, y1 = x0 + paso, y0 + paso
            dentro = (x0 + MEDIA_JUNTA, y0 + MEDIA_JUNTA, x1 - MEDIA_JUNTA, y1 - MEDIA_JUNTA)
            sal.paste(m.resize((LADO - 1, LADO - 1), Image.LANCZOS, box=dentro), (bx * LADO + 1, by * LADO + 1))
            # la junta de arriba, la de la izquierda y su cruce
            sal.paste(m.resize((LADO - 1, 1), Image.LANCZOS, box=(dentro[0], y0 - MEDIA_JUNTA, dentro[2], y0 + MEDIA_JUNTA)),
                      (bx * LADO + 1, by * LADO))
            sal.paste(m.resize((1, LADO - 1), Image.LANCZOS, box=(x0 - MEDIA_JUNTA, dentro[1], x0 + MEDIA_JUNTA, dentro[3])),
                      (bx * LADO, by * LADO + 1))
            sal.paste(m.resize((1, 1), Image.LANCZOS, box=(x0 - MEDIA_JUNTA, y0 - MEDIA_JUNTA, x0 + MEDIA_JUNTA, y0 + MEDIA_JUNTA)),
                      (bx * LADO, by * LADO))
    return sal


# Los listones de madera de la pared: en la imagen de GPT hay unos 38 de lado a lado, que a 48 píxeles se emborronan (poco más de un
# píxel cada uno). Se marcan a mano después de reducir, como en el pixel art: una ranura oscura cada RANURA píxeles (16 listones por
# tramo, que casa al repetirse), solo donde hay madera (no en los huecos de los listones arrancados ni en el panel gris de abajo)
RANURA = 3
MADERA_HASTA = 32   # las filas de la madera (en GPT, hasta la 820 de 1254)


def listones(p):
    for y in range(MADERA_HASTA):
        for x in range(RANURA - 1, 48, RANURA):
            r, g, b = p.getpixel((x, y))
            if r - b > 25 and r >= g >= b:   # madera (no el gris de detrás)
                p.putpixel((x, y), (int(r * 0.5), int(g * 0.45), int(b * 0.4)))


for sala in ('venta', 'camara'):
    suelos = [suelo(f'assets/sources/suelos/{sala}-supermercado-suelo-destrozado{i}-gpt.webp') for i in (1, 2, 3)]
    paredes = [Image.open(f'assets/sources/suelos/{sala}-supermercado-pared-destrozada{i}-gpt.webp').convert('RGB').resize((48, 48), Image.LANCZOS)
               for i in (1, 2, 3)]
    # (solo lo claro u oscuro, no el color, como en la farmacia: las manchas grandes y la sangre dejarían un halo de otro color)
    for i, s, p in zip((1, 2, 3), _igualar(suelos, 10, 28, 0.45, False, True), _igualar(paredes, 5, 12, 0.45, True, True)):
        guardar(s, f'suelo-{sala}-supermercado-d{i}')
        if sala == 'venta':
            listones(p)
        for x in range(48):   # la última fila, más oscura, como las de las otras paredes
            p.putpixel((x, 47), tuple(int(v * 0.68) for v in p.getpixel((x, 47))))
        guardar(p, f'pared-{sala}-supermercado-d{i}')
