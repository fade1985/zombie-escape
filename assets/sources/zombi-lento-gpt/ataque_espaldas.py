"""El ataque del arrastrado de GPT de espaldas y en diagonal de espaldas: GPT no lo quiso dibujar (lo rechazaba por
violencia, aun con los textos más suaves y con el final del cuerpo en marrón). Se monta con sus fotogramas de
arrastrarse, que ya son de GPT: estira un brazo y luego el otro mientras el cuerpo se lanza unos píxeles hacia delante
(hacia donde mira: arriba, o arriba a la derecha) y vuelve. De espaldas no se le ve la cara, así que se entiende igual.

Se pasa después de montar arrastrarse en esas vistas (y de rojo_espalda.py):
  py assets/sources/zombi-lento-gpt/ataque_espaldas.py
Deja ataque/<north|north-east|north-west>-<0..12>.png en zombi-lento-gpt-48, en su lienzo de 96.
"""
import os
from PIL import Image, ImageOps

CARPETA = "assets/sources/zombi-lento-gpt-48"
# (fotograma de arrastrarse, cuánto se lanza hacia delante en píxeles): se levanta, estira un brazo, se lanza con el
# otro (el impacto, en el 7) y vuelve. El 0 es el dibujo quieto, como en todas
PASOS = [(0, 0), (1, 1), (3, 2), (4, 3), (5, 4), (6, 5), (11, 6), (12, 6), (12, 5), (1, 3), (2, 2), (0, 1), (0, 0)]
# hacia dónde es «delante» en cada vista (en píxeles por cada píxel de lanzarse)
DELANTE = {"north": (0, -1), "north-east": (0.7, -0.7)}
LADO = 96   # el lienzo del ataque (el de arrastrarse es de 64: el dibujo quieto, abajo y en medio en los dos)

for vista, (dx, dy) in DELANTE.items():
    for n, (fotograma, cuanto) in enumerate(PASOS):
        andar = Image.open(os.path.join(CARPETA, "walk", "%s-%d.png" % (vista, fotograma))).convert("RGBA")
        lienzo = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
        x = (LADO - andar.width) // 2 + round(dx * cuanto)
        y = LADO - andar.height + round(dy * cuanto)
        lienzo.paste(andar, (x, y), andar)
        lienzo.save(os.path.join(CARPETA, "ataque", "%s-%d.png" % (vista, n)))
        if vista == "north-east":
            ImageOps.mirror(lienzo).save(os.path.join(CARPETA, "ataque", "north-west-%d.png" % n))
    print(vista, len(PASOS))
