# Las cortinas de los probadores de la tienda de ropa (18 nov, el dueño, a partir de dos fotos suyas de probadores), de
# dos imágenes de GPT sobre negro puro:
#   assets/sources/ropa/cortina-cerrada-destrozada-gpt.webp → assets/sprites/cortina-probador.png         (32 × 61: marco, barra y cortina)
#   assets/sources/ropa/cortina-abierta-destrozada-gpt.webp → assets/sprites/cortina-probador-abierta.png (32 × 61: con la cortina
#                                                              recogida a la izquierda y el hueco vacío)
# (19 nov, el dueño: destrozadas, rajadas, con arañazos y manos de sangre seca; ya vienen en beige. Las de antes, rojas de GPT,
# cortina-cerrada-gpt.webp y cortina-abierta-gpt.webp, se pasaban a beige con a_beige)
# 32 × 61 píxeles = el hueco de la puerta (64 unidades) y su pared alta (122 unidades: la hoja de 118 y el marco de 4).
# Se quita el negro puro (lo de fuera y el hueco de la abierta) y se reduce MEZCLANDO colores con LANCZOS, con el alfa
# premultiplicado, como los muebles (tools/muebles_gpt.py).
#   py tools/cortina_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

TAM = (32, 61)
SALEN = [("ropa/cortina-cerrada-destrozada-gpt.webp", "cortina-probador"),
         ("ropa/cortina-abierta-destrozada-gpt.webp", "cortina-probador-abierta")]


def guardar(im, nombre):
    im.save(f'assets/sprites/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [0, 0], 'scale': 1, 'suavizar': 0,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'assets/sprites/{nombre}.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f'{nombre}: {im.width}x{im.height}')


def a_beige(im):
    # 18 nov, el dueño: las cortinas, beige en vez de rojas. Solo se cambia lo rojo (la madera y el cromo se quedan): cada píxel rojo
    # pasa a un beige con la misma luz y sombra
    import colorsys
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, al = px[x, y]
            if not al:
                continue
            h, sat, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if (h < 0.04 or h > 0.96) and sat > 0.45:
                f = 0.5 + 0.5 * min(1.0, v / 0.95)
                px[x, y] = (int(230 * f), int(208 * f), int(176 * f), al)
    return im


for origen, nombre in SALEN:
    a = np.asarray(Image.open('assets/sources/' + origen).convert('RGB')).astype(float)
    vivo = a.max(axis=2) > 14          # lo que no es negro puro
    ys, xs = np.where(vivo)
    a, vivo = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1], vivo[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    alfa = vivo.astype(float)
    pre = np.dstack([a * alfa[..., None], alfa * 255])
    # premultiplicado: cada canal por separado, luego se deshace
    canales = [np.asarray(Image.fromarray(pre[..., i].astype(np.float32), 'F').resize(TAM, Image.LANCZOS)) for i in range(4)]
    r = np.dstack(canales)
    al = r[..., 3] / 255.0
    rgb = np.where(al[..., None] > 0.01, r[..., :3] / np.maximum(al[..., None], 0.01), 0)
    salida = np.dstack([np.clip(rgb, 0, 255), np.where(al > 0.5, 255, 0)]).astype(np.uint8)
    guardar(Image.fromarray(salida, 'RGBA'), nombre)
