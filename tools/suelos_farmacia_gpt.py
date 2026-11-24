# El suelo y la pared de la sala de venta y de la rebotica (el laboratorio) de la farmacia, destrozados (24 nov, el dueño; de GPT, a
# partir de fotos suyas: la sala de venta, baldosa grande de porcelánico gris claro y pared blanca con una franja verde y rodapié de
# aluminio; la rebotica, de la foto del robot dispensador, losetas de vinilo gris azulado y paneles de chapa blanca con perfiles de
# aluminio y rodapié de acero). Tres suelos y tres paredes de cada una, que en la tienda se mezclan a trozos (mapa.gd, MEZCLA_TIENDA),
# hechos como los del taller de la ferretería (tools/taller_ferreteria_gpt.py, de donde salen las funciones):
#   assets/sources/suelos/<sala>-farmacia-suelo-destrozado<N>-gpt.webp → assets/sprites/suelo-<sala>-farmacia-d<N>.png (128 × 128)
#   assets/sources/suelos/<sala>-farmacia-pared-destrozada<N>-gpt.webp → assets/sprites/pared-<sala>-farmacia-d<N>.png (48 × 48)
# con <sala> venta o rebotica. El suelo, 8 × 8 baldosas de 16 píxeles (cada baldosa por dentro y las juntas aparte); la pared, entera
# a 48 × 48. A los tres de cada uno se les iguala la mancha de color de fondo, para que al mezclarse no se vean los cuadros.
#   py tools/suelos_farmacia_gpt.py   (y luego Godot --headless --path . --import)
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


for sala in ('venta', 'rebotica'):
    suelos = [suelo(f'assets/sources/suelos/{sala}-farmacia-suelo-destrozado{i}-gpt.webp') for i in (1, 2, 3)]
    paredes = [Image.open(f'assets/sources/suelos/{sala}-farmacia-pared-destrozada{i}-gpt.webp').convert('RGB').resize((48, 48), Image.LANCZOS)
               for i in (1, 2, 3)]
    # (solo lo claro u oscuro, no el color, como en la sala de venta de la ferretería: las manchas grandes, la sangre y el charco
    # verde, dejarían un halo de otro color)
    for i, s, p in zip((1, 2, 3), _igualar(suelos, 10, 28, 0.45, False, True), _igualar(paredes, 5, 12, 0.45, True, True)):
        guardar(s, f'suelo-{sala}-farmacia-d{i}')
        for x in range(48):   # la última fila, más oscura, como las de las otras paredes
            p.putpixel((x, 47), tuple(int(v * 0.68) for v in p.getpixel((x, 47))))
        guardar(p, f'pared-{sala}-farmacia-d{i}')
