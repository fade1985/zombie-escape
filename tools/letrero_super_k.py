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
# (y la tenía pegada a la R: el dueño la quiere con aire a los dos lados. GPT dejó las letras casi tocándose, así que la E
# y la T se corren a la derecha CORRE píxeles para hacer sitio y la K va en medio del hueco, con HUECO a cada lado, que al
# reducir sale como una columna vacía entre las letras)
CORRE = 12
HUECO = 20
et = im.crop((1264, 370, 1536 - CORRE, 625))
d.rectangle((1126, 370, 1535, 625), fill=(0, 0, 0))   # la K vieja, la E y la T, a negro puro
im.paste(et, (1264 + CORRE, 370))

x0, y0, h = 1124 + HUECO, 392, 190   # (la R acaba en la 1124) la cara: de la 392 a la 582, como las demás letras
w, palo = 1264 + CORRE - HUECO - 8 - x0, 42   # hasta el canto de la E, dejando su hueco (el canto de la K, 8 más)
partes = [
    [(0, 0), (palo, 0), (palo, h), (0, h)],                     # el palo
    [(palo, 62), (palo + 18, 0), (w, 0), (palo, 118)],          # el brazo de arriba
    [(palo, 98), (palo + 22, 98), (w, h), (w - 40, h)],         # la pierna (entre los dos, la V abierta)
]
partes = [[(x0 + x, y0 + y) for x, y in q] for q in partes]
for dx, dy, color in [(8, 22, CANTO), (0, 0, CARA)]:
    for p in partes:
        d.polygon([(x + dx, y + dy) for x, y in p], fill=color)
im.save("assets/sources/letrero-super-arreglado.png")
im.crop((1040, 360, 1320, 640)).resize((560, 560), Image.NEAREST).save("capturas/letrero-k.png")
print("assets/sources/letrero-super-arreglado.png")
