# La pared y el suelo del dormitorio de matrimonio de los pisos (M13, 11 nov), de dos imágenes de GPT: pared de yeso blanco roto
# con rodapié de roble (assets/sources/dormitorio-matrimonio-pared-gpt.webp) y parqué en espiga del mismo roble
# (assets/sources/dormitorio-matrimonio-suelo-gpt.webp). Salen reducidas mezclando colores, como los muebles (tools/muebles_gpt.py).
#   pared → assets/sprites/pared-dormitorio-matrimonio.png  (204 × 48: cuatro trozos de 51, el 2.º y el 4.º en espejo, así empalma
#                                                            por todos los lados y las manchas no se repiten iguales)
#   techo → assets/sprites/techo-dormitorio-matrimonio.png  (204 × 6: el borde de arriba de la pared, del color del yeso)
#   suelo → assets/sprites/suelo-dormitorio-matrimonio.png  (el trozo que se repite, 96 × 96)
# mapa.gd los usa por ESTILO_FIJO ("-matrimonio"). Uso: py tools/dormitorio_matrimonio.py (y luego Godot --headless --path . --import)
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


# la pared: un trozo de 51 × 48 (el rodapié, las 3 filas de abajo), repetido 4 veces con el 2.º y el 4.º en espejo
pared = Image.open(FUENTES + "dormitorio-matrimonio-pared-gpt.webp").convert("RGB")
trozo = reducir(pared, 51, 48)
espejo = trozo.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
tira = Image.new("RGB", (204, 48))
for i in range(4):
    tira.paste(trozo if i % 2 == 0 else espejo, (i * 51, 0))
for x in range(204):   # la última fila, más oscura, donde la pared se curva hacia el suelo
    tira.putpixel((x, 47), tuple(int(v * 0.72) for v in tira.getpixel((x, 47))))
tira.save(CARPETA + "pared-dormitorio-matrimonio.png")
guardar_json("pared-dormitorio-matrimonio", 204, 48)

# el techo: el color medio del yeso, con un degradado suave
yeso = [tira.getpixel((x, y)) for x in range(204) for y in range(4, 30)]
medio = tuple(sum(c[i] for c in yeso) // len(yeso) for i in range(3))
techo = Image.new("RGB", (204, 6))
for y, f in enumerate((0.93, 0.96, 0.99, 0.97, 0.95, 0.93)):
    for x in range(204):
        techo.putpixel((x, y), tuple(min(255, int(v * f)) for v in medio))
techo.save(CARPETA + "techo-dormitorio-matrimonio.png")
guardar_json("techo-dormitorio-matrimonio", 204, 6)

# el suelo: la imagen se repite dos veces a lo ancho y a lo alto (el trozo es de 627 × 627)
suelo = Image.open(FUENTES + "dormitorio-matrimonio-suelo-gpt.webp").convert("RGB")
reducir(suelo.crop((0, 0, 627, 627)), 96, 96).save(CARPETA + "suelo-dormitorio-matrimonio.png")
guardar_json("suelo-dormitorio-matrimonio", 96, 96)
print("hecho")
