# La puerta automática del supermercado (puerta.gd, "super"; 17 nov), partida en dos dibujos a partir de la entera
# (assets/sprites/puerta-super.png, que sale de la imagen de GPT con tools/muebles_gpt.py puerta_super):
#   puerta-super-marco.png: la caja del motor, los dos cristales fijos y el carril, con el hueco de las hojas vacío
#   puerta-super-hojas.png: solo las dos hojas correderas del medio (lo demás, transparente)
# El juego pinta primero el oscuro de dentro, luego las hojas (cada una corrida hacia su lado) y encima el marco, así
# que al abrirse las hojas se esconden detrás de los cristales fijos.
#   py tools/muebles_gpt.py puerta_super && py tools/puerta_super.py   (y luego Godot --headless --path . --import)
from PIL import Image

HUECO = (17, 4, 47, 38)   # x0, y0, x1, y1 (sin incluir x1 ni y1): las dos hojas, de 15 píxeles cada una

entera = Image.open("assets/sprites/puerta-super.png").convert("RGBA")
marco = entera.copy()
hojas = Image.new("RGBA", entera.size, (0, 0, 0, 0))
hojas.paste(entera.crop(HUECO), HUECO[:2])
marco.paste(Image.new("RGBA", (HUECO[2] - HUECO[0], HUECO[3] - HUECO[1]), (0, 0, 0, 0)), HUECO[:2])
marco.save("assets/sprites/puerta-super-marco.png")
hojas.save("assets/sprites/puerta-super-hojas.png")
# dónde está la lucecita verde del sensor (puerta.gd la pinta de rojo mientras la tienda esté cerrada con llave)
verdes = [(x, y) for y in range(8) for x in range(64) if entera.getpixel((x, y))[1] > entera.getpixel((x, y))[0] + 40]
print("lucecita:", verdes)
