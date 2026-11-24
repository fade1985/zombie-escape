# Los muebles de la farmacia (24 nov, el dueño; de GPT, desde fotos suyas): imágenes sobre negro puro
# (assets/sources/centro/<imagen>.webp) reducidas a sprite de escala 1 MEZCLANDO colores, como los de la ferretería
# (tools/muebles_ferreteria_gpt.py, de donde sale esta):
#   mostrador-farmacia-gpt         -> farmamostrador, el mostrador desde el lado del cliente (la tienda normal: se entra por abajo)
#   mostrador-farmacia-dentro-gpt  -> farmamostrador2, el mismo desde el lado de la farmacéutica (la inversa: se entra por arriba)
#   mostrador-farmacia2-gpt, mostrador-farmacia2-dentro-gpt  -> farmamostrador3, 4: el segundo mostrador (otras cosas encima y
#     otros destrozos), por los dos lados, como el primero
#   gondola-medicinas-gpt, gondola-bebe-gpt  -> farmagondola1, 2: góndolas blancas, la de medicinas y la de bebé (pañales y leche)
#   gondola-vitaminas-gpt    -> farmagondola3, la tercera góndola: vitaminas y cuidado personal
#   vitrina-farmacia-gpt     -> farmavitrina, una vitrina baja de cristal con cosmética, el cristal reventado
#   vitrina-farmacia2-gpt    -> farmavitrina2, la segunda vitrina: gafas, termómetros y un tensiómetro
#   expositor-torre-gpt      -> farmatorre, un expositor redondo de madera, en torre
#   expositor-cepillos-gpt   -> farmacepillos, un expositor rojo con ruedas, de cepillos y pasta de dientes
#   mesa-cosmetica-gpt       -> farmacosmetica, una mesa isla de madera con cremas y champús
#   sillas-espera-gpt        -> farmasillas, una bancada de tres sillas de espera naranjas
#   garrafa-agua-gpt         -> farmagarrafa, una fuente de agua de garrafa
#   estanteria-almacen-farmacia-gpt  -> farmabalda1, la estantería de metal del almacén, con cajitas de medicinas (rehecha el 24 nov:
#     la primera, de cinco baldas, se salía por encima de la pared)
#   estanteria-almacen-farmacia2-gpt -> farmabalda2, la de material de curas (gasas, vendas, guantes y sueros), de metal gris
#   robot-farmacia-gpt       -> farmarobot, el robot dispensador de la rebotica
#   robot-farmacia2-gpt .. 4  -> farmarobot2..4, otros tres: con el brazo arriba y la pantalla rota, con la puerta abierta y el
#     brazo caído, y apagado y quemado por dentro
#   mesa-laboratorio-gpt, mesa-laboratorio2-gpt  -> farmaisla1, 2: las mesas en isla del laboratorio con su estante alto, la de
#     los microscopios y la del baño maría
#   taburete-laboratorio-gpt -> farmataburete, un taburete alto de laboratorio
#   mesa-acero-gpt           -> farmaacero, la mesa de trabajo de acero con cajones y el brazo extractor
#   carro-acero-gpt          -> farmacarro, una estantería de acero con ruedas
#   contenedor-residuos-gpt  -> farmaresiduos, el cubo amarillo de residuos sanitarios
#   py tools/muebles_farmacia_gpt.py   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (imagen, tipo, largo): el largo en el juego, en unidades (escala 1: un píxel por unidad; una casilla, 32); el alto sale de la
# proporción. Los dos mostradores, del mismo largo, para que sean el mismo mueble (y como el de la ferretería); las dos góndolas,
# iguales; la estantería del almacén, del ancho de las de la ropa y la ferretería (88)
MUEBLES = [("mostrador-farmacia-gpt", "farmamostrador", 164), ("mostrador-farmacia-dentro-gpt", "farmamostrador2", 164),
           ("mostrador-farmacia2-gpt", "farmamostrador3", 164), ("mostrador-farmacia2-dentro-gpt", "farmamostrador4", 164),
           ("gondola-medicinas-gpt", "farmagondola1", 140), ("gondola-bebe-gpt", "farmagondola2", 140),
           ("gondola-vitaminas-gpt", "farmagondola3", 140), ("vitrina-farmacia2-gpt", "farmavitrina2", 150),
           ("vitrina-farmacia-gpt", "farmavitrina", 150), ("expositor-torre-gpt", "farmatorre", 64),
           ("expositor-cepillos-gpt", "farmacepillos", 52), ("mesa-cosmetica-gpt", "farmacosmetica", 130),
           ("sillas-espera-gpt", "farmasillas", 110), ("garrafa-agua-gpt", "farmagarrafa", 32),
           ("estanteria-almacen-farmacia-gpt", "farmabalda1", 88), ("estanteria-almacen-farmacia2-gpt", "farmabalda2", 88), ("robot-farmacia-gpt", "farmarobot", 150),
           ("robot-farmacia2-gpt", "farmarobot2", 150), ("robot-farmacia3-gpt", "farmarobot3", 150), ("robot-farmacia4-gpt", "farmarobot4", 150),
           ("mesa-laboratorio-gpt", "farmaisla1", 160), ("mesa-laboratorio2-gpt", "farmaisla2", 160),
           ("taburete-laboratorio-gpt", "farmataburete", 30), ("mesa-acero-gpt", "farmaacero", 136),
           ("carro-acero-gpt", "farmacarro", 56), ("contenedor-residuos-gpt", "farmaresiduos", 48)]
# los que llevan huecos cerrados de negro puro que han de verse transparentes (entre las baldas de la estantería del almacén): se
# quitan los de más de HUECO_MIN píxeles de GPT (los pequeños son sombras del dibujo)
CON_HUECOS = {"farmabalda1", "farmabalda2", "farmaisla1", "farmaisla2", "farmataburete", "farmacarro"}   # y entre la encimera y el estante, las patas, las baldas
HUECO_MIN = 1000
# lo más altos que pueden ser (las estanterías del almacén, contra la pared de arriba: lo que pase de lo que miden las de la
# ferretería, 136, se sale por encima de la pared)
ALTO_MAX = {"farmabalda1": 136, "farmabalda2": 136}
# lo grande que es cada píxel del dibujo (como los muebles de la tienda de ropa: 2, el mismo detalle que el resto del juego)
PIXEL = 2
# los de cosas pequeñas (cajitas, botes, cepillos), que con PIXEL 2 se emborronan, con el doble de detalle (un píxel por unidad)
FINOS = {"farmagondola1", "farmagondola2", "farmagondola3", "farmavitrina", "farmavitrina2", "farmatorre", "farmacepillos", "farmacosmetica", "farmabalda1", "farmabalda2", "farmarobot", "farmarobot2", "farmarobot3", "farmarobot4",
         "farmaisla1", "farmaisla2", "farmataburete", "farmaacero", "farmacarro", "farmaresiduos"}


def quitar_fondo(im):
    """El negro puro que se llega desde el borde, transparente."""
    px = im.load()
    w, h = im.size
    hecho = bytearray(w * h)
    cola = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or hecho[y * w + x] or max(px[x, y][:3]) >= 8:
            continue
        hecho[y * w + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(h):
        for x in range(w):
            if hecho[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
    return im


def quitar_huecos(im):
    """Los huecos cerrados de negro puro de más de HUECO_MIN píxeles, transparentes."""
    px = im.load()
    w, h = im.size
    visto = bytearray(w * h)
    for y0 in range(h):
        for x0 in range(w):
            if visto[y0 * w + x0] or px[x0, y0][3] == 0 or max(px[x0, y0][:3]) >= 8:
                continue
            visto[y0 * w + x0] = 1
            cola = deque([(x0, y0)])
            hueco = []
            while cola:
                x, y = cola.popleft()
                hueco.append((x, y))
                for a, b in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= a < w and 0 <= b < h and not visto[b * w + a] and px[a, b][3] and max(px[a, b][:3]) < 8:
                        visto[b * w + a] = 1
                        cola.append((a, b))
            if len(hueco) > HUECO_MIN:
                for x, y in hueco:
                    px[x, y] = (0, 0, 0, 0)
    return im


import sys
solo = set(sys.argv[1:])   # py tools/muebles_farmacia_gpt.py [tipo ...]: solo esos
for origen, tipo, largo in MUEBLES:
    if solo and tipo not in solo:
        continue
    im = quitar_fondo(Image.open(f"assets/sources/centro/{origen}.webp").convert("RGBA"))
    if tipo in CON_HUECOS:
        im = quitar_huecos(im)
    im = im.crop(im.getbbox())
    alto = round(largo * im.height / im.width)
    if tipo in ALTO_MAX and alto > ALTO_MAX[tipo]:   # más alta de la cuenta: se estrecha para que quepa
        largo, alto = round(largo * ALTO_MAX[tipo] / alto), ALTO_MAX[tipo]
    pixel = 1 if tipo in FINOS else PIXEL
    peq = (round(largo / pixel), round(alto / pixel))
    s = im.convert("RGBa").resize(peq, Image.LANCZOS).convert("RGBA")
    s.putalpha(s.split()[3].point(lambda v: 255 if v > 110 else 0))
    s = s.resize((peq[0] * pixel, peq[1] * pixel), Image.NEAREST)
    ancho, alto = s.size
    ruta = f"assets/sprites/mueble-{tipo}.png"
    s.save(ruta)
    with open(ruta.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [ancho, alto], "pivot": [ancho // 2, alto], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")
    print(f"{tipo}: {ancho}x{alto} (de {im.width}x{im.height})")
