# Las cortinas de los probadores de la tienda de ropa (18 nov, el dueño, a partir de dos fotos suyas de probadores), de
# dos imágenes de GPT sobre negro puro:
#   assets/sources/ropa/cortina-cerrada-gpt.webp → assets/sprites/cortina-probador.png         (32 × 61: marco, barra y cortina)
#   assets/sources/ropa/cortina-abierta-gpt.webp → assets/sprites/cortina-probador-abierta.png (32 × 61: con la cortina recogida
#                                                   a la izquierda y el hueco vacío)
# 32 × 61 píxeles = el hueco de la puerta (64 unidades) y su pared alta (122 unidades: la hoja de 118 y el marco de 4).
# Se quita el negro puro (lo de fuera y el hueco de la abierta) y se reduce MEZCLANDO colores con LANCZOS, con el alfa
# premultiplicado, como los muebles (tools/muebles_gpt.py).
#   py tools/cortina_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

TAM = (32, 61)
SALEN = [("ropa/cortina-cerrada-gpt.webp", "cortina-probador"), ("ropa/cortina-abierta-gpt.webp", "cortina-probador-abierta")]


def guardar(im, nombre):
    im.save(f'assets/sprites/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [0, 0], 'scale': 1, 'suavizar': 0,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'assets/sprites/{nombre}.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f'{nombre}: {im.width}x{im.height}')


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
