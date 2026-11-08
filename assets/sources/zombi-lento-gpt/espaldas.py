"""El ataque y el golpe del arrastrado de GPT de espaldas y en diagonal de espaldas: GPT no lo quiso dibujar (lo rechazaba por
violencia, aun con los textos más suaves y con el final del cuerpo en marrón). Se monta con sus fotogramas de
arrastrarse, que ya son de GPT: estira un brazo y luego el otro mientras el cuerpo se lanza unos píxeles hacia delante
(hacia donde mira: arriba, o arriba a la derecha) y vuelve. De espaldas no se le ve la cara, así que se entiende igual.
La muerte, el dibujo quieto aplastándose contra el suelo (se le doblan los brazos y se queda tendido).
El golpe (también de perfil), igual: el dibujo quieto echándose unos píxeles hacia atrás y volviendo (a GPT ni se le pidió).

Se pasa después de montar arrastrarse en esas vistas (y de rojo_espalda.py):
  py assets/sources/zombi-lento-gpt/espaldas.py
Deja ataque/<north|north-east|north-west>-<0..12>.png golpe/...-<0..6>.png y muerte/...-<0..12>.png en zombi-lento-gpt-48, en su lienzo de 96.
"""
import os
from PIL import Image, ImageOps

CARPETA = "assets/sources/zombi-lento-gpt-48"
# (fotograma de arrastrarse, cuánto se lanza hacia delante en píxeles): se levanta, estira un brazo, se lanza con el
# otro (el impacto, en el 7) y vuelve. El 0 es el dibujo quieto, como en todas
ATAQUE = [(0, 0), (1, 1), (3, 2), (4, 3), (5, 4), (6, 5), (11, 6), (12, 6), (12, 5), (1, 3), (2, 2), (0, 1), (0, 0)]
# el golpe: el dibujo quieto, empujado hacia atrás (en negativo) y de vuelta
GOLPE = [(0, 0), (0, -2), (0, -3), (0, -3), (0, -2), (0, -1), (0, 0)]
# hacia dónde es «delante» en cada vista (en píxeles por cada píxel de lanzarse)
DELANTE = {"north": (0, -1), "north-east": (0.7, -0.7), "east": (1, 0)}
# (el golpe de perfil tampoco lo quiso dibujar GPT: también sale de aquí, solo el golpe)
ESPEJO = {"north-east": "north-west", "east": "west"}
LADO = 96   # el lienzo del ataque (el de arrastrarse es de 64: el dibujo quieto, abajo y en medio en los dos)

for anim, PASOS in [("ataque", ATAQUE), ("golpe", GOLPE)]:
    for vista, (dx, dy) in DELANTE.items():
        if anim == "ataque" and vista == "east":
            continue
        for n, (fotograma, cuanto) in enumerate(PASOS):
            andar = Image.open(os.path.join(CARPETA, "walk", "%s-%d.png" % (vista, fotograma))).convert("RGBA")
            lienzo = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
            x = (LADO - andar.width) // 2 + round(dx * cuanto)
            y = LADO - andar.height + round(dy * cuanto)
            lienzo.paste(andar, (x, y), andar)
            lienzo.save(os.path.join(CARPETA, anim, "%s-%d.png" % (vista, n)))
            if vista in ESPEJO:
                ImageOps.mirror(lienzo).save(os.path.join(CARPETA, anim, "%s-%d.png" % (ESPEJO[vista], n)))
        print(anim, vista, len(PASOS))


# La muerte de espaldas: el dibujo quieto, cada vez más bajo (se le doblan los brazos) y algo más ancho, hasta quedarse
# tendido (los últimos, iguales). (alto, ancho) de cada fotograma, respecto al quieto
MUERTE = [(1, 1), (0.97, 1.01), (0.92, 1.02), (0.86, 1.04), (0.79, 1.05), (0.72, 1.07), (0.66, 1.08), (0.62, 1.09),
          (0.6, 1.1), (0.6, 1.1), (0.6, 1.1), (0.6, 1.1), (0.6, 1.1)]
for vista in ["north", "north-east"]:
    quieto = Image.open(os.path.join(CARPETA, "rotations", vista + ".png")).convert("RGBA")
    caja = quieto.getbbox()
    dibujo = quieto.crop(caja)
    for n, (alto, ancho) in enumerate(MUERTE):
        d = dibujo.resize((round(dibujo.width * ancho), round(dibujo.height * alto)), Image.NEAREST)
        lienzo = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
        centro = (LADO - 48) // 2 + (caja[0] + caja[2]) / 2
        lienzo.paste(d, (round(centro - d.width / 2), LADO - 48 + caja[3] - d.height), d)
        lienzo.save(os.path.join(CARPETA, "muerte", "%s-%d.png" % (vista, n)))
        if vista in ESPEJO:
            ImageOps.mirror(lienzo).save(os.path.join(CARPETA, "muerte", "%s-%d.png" % (ESPEJO[vista], n)))
    print("muerte", vista, len(MUERTE))
