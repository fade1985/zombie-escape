# El fondo de la ficha de Sujetos (Colecciones del ordenador, ui/ordenador.gd: ficha_bestiario): una sala de
# laboratorio a oscuras con una lámpara colgada que echa un cono de luz al suelo de baldosas. Sale de la imagen de GPT
# que pidió el dueño (8 nov), recortada al ancho y alto del escenario (404 × 208 unidades: 202 × 104 píxeles a 2 unidades
# por píxel) quitando suelo de abajo (la lámpara, arriba, se queda entera) y reducida MEZCLANDO colores (cada píxel, la
# media de su trozo), como los muebles de GPT (tools/muebles_gpt.py).
#   py tools/foco_sujetos.py   (y luego Godot --headless --path . --import)
from PIL import Image

ORIGEN = "assets/sources/foco-sujetos-gpt.webp"
SPRITE = "assets/ui/foco-sujetos.png"
ANCHO, ALTO = 202, 104

im = Image.open(ORIGEN).convert("RGB")
w, h = im.size
alto_recorte = round(w * ALTO / ANCHO)
if alto_recorte <= h:
    im = im.crop((0, 0, w, alto_recorte))   # se quita suelo de abajo
else:
    ancho_recorte = round(h * ANCHO / ALTO)
    x = (w - ancho_recorte) // 2
    im = im.crop((x, 0, x + ancho_recorte, h))   # se quita de los lados, por igual
im.resize((ANCHO, ALTO), Image.BOX).save(SPRITE)
print("%s: %d × %d (de %d × %d)" % (SPRITE, ANCHO, ALTO, w, h))
