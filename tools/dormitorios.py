# La pared y el suelo de los dormitorios (y, al final, la cocina, el salón, el baño y el pasillo de los pisos) de los pisos (M13, 11 nov), de dos imágenes cada uno. Matrimonio: de dos imágenes de GPT: pared de yeso blanco roto
# con rodapié de roble (assets/sources/dormitorio-matrimonio-pared-gpt.webp) y parqué en espiga del mismo roble
# (assets/sources/dormitorio-matrimonio-suelo-gpt.webp). Salen reducidas mezclando colores, como los muebles (tools/muebles_gpt.py).
#   pared → assets/sprites/pared-dormitorio-matrimonio.png  (204 × 48: cuatro trozos de 51, el 2.º y el 4.º en espejo, así empalma
#                                                            por todos los lados y las manchas no se repiten iguales)
#   techo → assets/sprites/techo-dormitorio-matrimonio.png  (204 × 6: el borde de arriba de la pared, del color del yeso)
#   suelo → assets/sprites/suelo-dormitorio-matrimonio.png  (el trozo que se repite, 96 × 96)
#   (y lo mismo para el individual: verde manzana con rodapié blanco y parqué oscuro de listones; sufijo -individual)
# mapa.gd los usa por ESTILO_FIJO ("-matrimonio"). Uso: py tools/dormitorios.py (y luego Godot --headless --path . --import)
import json
from PIL import Image

FUENTES = "assets/sources/"
CARPETA = "assets/sprites/"


def reducir(im, ancho, alto):
    return im.convert("RGB").resize((ancho, alto), Image.LANCZOS)


def guardar_json(nombre, ancho, alto):
    with open(CARPETA + nombre + ".json", "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [ancho, alto], "pivot": [0, 0], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")


def pared_y_techo(nombre, origen, techo_f, estilo="dormitorio"):
    # la pared: un trozo de 51 × 48 (el rodapié, las 3 filas de abajo), repetido 4 veces con el 2.º y el 4.º en espejo
    pared = Image.open(FUENTES + origen).convert("RGB")
    trozo = reducir(pared, 51, 48)
    espejo = trozo.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    tira = Image.new("RGB", (204, 48))
    for i in range(4):
        tira.paste(trozo if i % 2 == 0 else espejo, (i * 51, 0))
    for x in range(204):   # la última fila, más oscura, donde la pared se curva hacia el suelo
        tira.putpixel((x, 47), tuple(int(v * 0.72) for v in tira.getpixel((x, 47))))
    tira.save(CARPETA + "pared-" + estilo + "-" + nombre + ".png")
    guardar_json("pared-" + estilo + "-" + nombre, 204, 48)
    # el techo: el color medio de la pared, con un degradado suave
    yeso = [tira.getpixel((x, y)) for x in range(204) for y in range(4, 30)]
    medio = tuple(sum(c[i] for c in yeso) // len(yeso) for i in range(3))
    techo = Image.new("RGB", (204, 6))
    for y, f in enumerate(techo_f):
        for x in range(204):
            techo.putpixel((x, y), tuple(min(255, int(v * f)) for v in medio))
    techo.save(CARPETA + "techo-" + estilo + "-" + nombre + ".png")
    guardar_json("techo-" + estilo + "-" + nombre, 204, 6)


def suelo(nombre, origen, recorte, lado, estilo="dormitorio"):
    im = Image.open(FUENTES + origen).convert("RGB")
    reducir(im.crop((0, 0, recorte, recorte)), lado, lado).save(CARPETA + "suelo-" + estilo + "-" + nombre + ".png")
    guardar_json("suelo-" + estilo + "-" + nombre, lado, lado)


CLARO = (0.93, 0.96, 0.99, 0.97, 0.95, 0.93)
# matrimonio: el suelo se repite dos veces a lo ancho y a lo alto (el trozo es de 627 × 627)
pared_y_techo("matrimonio", "dormitorio-matrimonio-pared-gpt.webp", CLARO)
suelo("matrimonio", "dormitorio-matrimonio-suelo-gpt.webp", 627, 96)
# individual (11 nov): pared verde manzana con rodapié blanco y parqué oscuro de listones; el suelo, la imagen entera, a 128
pared_y_techo("individual", "dormitorio-individual-pared-gpt.webp", CLARO)
suelo("individual", "dormitorio-individual-suelo-gpt.webp", 1254, 128)
# cocina de los pisos (11 nov): yeso crema con rodapié de terracota y baldosas de barro cocido; el suelo, la imagen entera, a 128
pared_y_techo("pisos", "cocina-pared-gpt.webp", CLARO, "cocina")
suelo("pisos", "cocina-suelo-gpt.webp", 1254, 128, "cocina")
# salón de los pisos (11 nov): ladrillo pintado de blanco con rodapié de madera oscura y tablas anchas oscuras; el suelo, la imagen entera, a 128
pared_y_techo("pisos", "salon-pared-gpt.webp", CLARO, "salon")
suelo("pisos", "salon-suelo-gpt.webp", 1254, 128, "salon")
# baño de los pisos (11 nov): azulejo verde botella con zócalo blanco y baldosa hidráulica de cruces granates; el suelo, la imagen entera, a 128
pared_y_techo("pisos", "bano-pared-gpt.webp", CLARO, "bano")
suelo("pisos", "bano-suelo-gpt.webp", 1254, 128, "bano")
# pasillo (y recibidor) de dentro de los pisos (11 nov): pintura crema arriba y rayas crema y beige abajo con moldura y rodapié de roble,
# y tarima de roble claro; el suelo, la imagen entera, a 128. (El pasillo del portal del edificio es otro: tools/portal_gpt.py)
pared_y_techo("gpt", "pasillo-piso-pared-gpt.webp", CLARO, "pasillopiso")
suelo("gpt", "pasillo-piso-suelo-gpt.webp", 1254, 128, "pasillopiso")
print("hecho")
