"""La azotea entera con la imagen de GPT (11 nov, bloque M): assets/sources/helipuerto-gpt.webp es TODA la azotea del
centro comercial y de los Apartamentos, tal cual (el hormigón verde gastado con sus grietas y manchas, el aro amarillo
con la H, las líneas y los números blancos, las lucecitas azules, la barandilla de los cuatro lados, la caseta de
arriba a la izquierda y la pasarela de hormigón de la derecha, por donde se llega). Ya no hay plataforma elevada, ni
rampa, ni murete, ni aparatos.

Se quitan 16 píxeles de negro a cada lado (la imagen es 3:2 y la azotea, 44 × 30 casillas, un poco más estrecha: así
no se estira) y se reduce como los muebles (LANCZOS, mezclando colores: tools/muebles_gpt.py; la imagen no tiene
transparencias, así que no hace falta premultiplicar) a 704 × 480, la azotea entera a 2 unidades por píxel.

Dónde cae cada cosa (para planta.gd: los muros que siguen la barandilla, PLATAFORMA y el centro del aro) lo dice esta
herramienta al pasarla: py tools/azotea_gpt.py
"""
from PIL import Image

ORIGEN = 'assets/sources/helipuerto-gpt.webp'
SPRITE = 'assets/sprites/azotea-gpt.png'
ANCHO, ALTO = 704, 480                 # la azotea (planta.gd: AZOTEA_COLS × AZOTEA_FILAS casillas de 16 píxeles)
RECORTE = (16, 0, 1518, 1024)          # sin 16 píxeles de negro a cada lado: de 1536 × 1024 a 1502 × 1024 (como 704 × 480)

im = Image.open(ORIGEN).convert('RGB').crop(RECORTE).resize((ANCHO, ALTO), Image.LANCZOS)
im.save(SPRITE)
print(f'{SPRITE}: {ANCHO}x{ALTO}')

# Dónde está el aro amarillo (su centro: planta.gd, el "helipuerto") y el rectángulo de las líneas blancas (planta.gd,
# PLATAFORMA), en unidades (2 por píxel). El aro se busca por el medio, lejos de las lucecitas naranjas de la caseta
px = im.load()
amarillos = [(x, y) for y in range(110, 390) for x in range(200, 480)
             if px[x, y][0] > 170 and px[x, y][1] > 120 and px[x, y][2] < 90]
xs = [x for x, _ in amarillos]
ys = [y for _, y in amarillos]
print('aro amarillo: x %d..%d, y %d..%d -> centro (%d, %d) unidades' % (
    min(xs) * 2, max(xs) * 2, min(ys) * 2, max(ys) * 2, (min(xs) + max(xs)), (min(ys) + max(ys))))
blancas_x = [x for x in range(60, ANCHO - 60) if sum(1 for y in range(ALTO) if min(px[x, y]) > 200) > 80]
blancas_y = [y for y in range(60, ALTO - 50) if sum(1 for x in range(ANCHO) if min(px[x, y]) > 200) > 150]
print('líneas blancas: x %d..%d, y %d..%d unidades' % (
    min(blancas_x) * 2, max(blancas_x) * 2 + 2, min(blancas_y) * 2, max(blancas_y) * 2 + 2))
