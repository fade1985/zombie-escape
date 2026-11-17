# La K del letrero SUPERMARKET (17 nov): GPT la dibujó rota y no se entendía (los dos brazos pegados en un bloque con un
# agujero negro), así que se borra de su imagen y se pinta una nueva encima, con polígonos, en el mismo estilo que las demás
# letras: la cara azul marino y el canto azul claro abajo y a la derecha. Sale assets/sources/letrero-super-arreglado.png,
# que es la que reduce tools/muebles_gpt.py (letrero_super).
#   py tools/letrero_super_k.py && py tools/muebles_gpt.py letrero_super && py tools/letrero_halo.py
from PIL import Image, ImageDraw

CARA = (8, 24, 52)
CANTO = (58, 184, 251)

im = Image.open("assets/sources/letrero-super-gpt.webp").convert("RGB")
d = ImageDraw.Draw(im)
# el sitio de la K (entre el canto de la R y la E), a negro puro
d.rectangle((1126, 380, 1262, 615), fill=(0, 0, 0))

x0, y0, h = 1128, 392, 190      # la cara: de la 392 a la 582, como las demás letras
w, palo = 114, 48               # (lo que deja sitio a su canto antes de la E)
partes = [
    [(0, 0), (palo, 0), (palo, h), (0, h)],                 # el palo
    [(palo, 70), (palo + 20, 0), (w, 0), (palo, 125)],      # el brazo de arriba
    [(palo, 100), (palo + 24, 100), (w, h), (palo + 18, h)],   # la pierna (entre los dos, la V abierta)
]
partes = [[(x0 + x, y0 + y) for x, y in q] for q in partes]
for dx, dy, color in [(8, 22, CANTO), (0, 0, CARA)]:
    for p in partes:
        d.polygon([(x + dx, y + dy) for x, y in p], fill=color)
im.save("assets/sources/letrero-super-arreglado.png")
im.crop((1040, 360, 1320, 640)).resize((560, 560), Image.NEAREST).save("capturas/letrero-k.png")
print("assets/sources/letrero-super-arreglado.png")
