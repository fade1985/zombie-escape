# El cartel de «SALA DE MANTENIMIENTO» del pasillo, junto a la puerta de la sala (puerta.gd, la de la placa con la llave
# inglesa), de una imagen de GPT (8 nov) con el estilo del de TRASTEROS (cartel_trasteros.gd): chapa esmaltada azul con
# filete blanco, letras blancas y un tornillo a cada lado, vieja, desconchada y con óxido.
# Saca dos dibujos, reducidos MEZCLANDO colores como los muebles (tools/muebles_gpt.py: pasar):
#   assets/sprites/cartel-mantenimiento.png       → el de GPT tal cual, con las letras en español
#   assets/sprites/cartel-mantenimiento-liso.png  → la misma placa sin letras: en los otros idiomas el juego escribe
#                                                   encima la traducción (puerta.gd), que unas letras de GPT no se traducen
# Uso: py tools/cartel_mantenimiento.py  (y luego Godot --headless --path . --import)
import os
import sys
import tempfile
from PIL import Image, ImageFilter

sys.argv = sys.argv[:1] + ["corcho"]   # muebles_gpt.py pasa sus muebles al cargarse: que solo pase uno, y deprisa
sys.path.insert(0, os.path.dirname(__file__))
from muebles_gpt import pasar  # noqa: E402

ORIGEN = "assets/sources/cartel-mantenimiento-gpt.webp"
ANCHO, ALTO = 84, 24          # 168 × 48 unidades (el de TRASTEROS, unas 126 × 30)
LETRAS = (250, 205, 1690, 570)   # dónde van las letras en la imagen de GPT (dentro del filete y entre los tornillos)

pasar(ORIGEN, "assets/sprites/cartel-mantenimiento.png", ANCHO, ALTO, False)

# La placa sin letras: lo claro de las letras (y un poco alrededor) se tapa con el azul de al lado, emborronado
im = Image.open(ORIGEN).convert("RGB")
px = im.load()
mascara = Image.new("L", im.size, 0)
m = mascara.load()
x0, y0, x1, y1 = LETRAS
for y in range(y0, y1):
    for x in range(x0, x1):
        r, g, b = px[x, y]
        if r > 120 and r > b + 10:   # la letra, crema (el esmalte es azul: b muy por encima de r)
            m[x, y] = 255
mascara = mascara.filter(ImageFilter.MaxFilter(13))   # y su borde, que viene mezclado con el azul
conocido = im.convert("RGBA")
conocido.putalpha(mascara.point(lambda v: 0 if v else 255))
relleno = conocido.convert("RGBa").filter(ImageFilter.BoxBlur(40)).convert("RGBA")
relleno.putalpha(255)
liso = Image.composite(relleno.convert("RGB"), im, mascara)
tmp = os.path.join(tempfile.gettempdir(), "cartel-mantenimiento-liso.png")
liso.save(tmp)
pasar(tmp, "assets/sprites/cartel-mantenimiento-liso.png", ANCHO, ALTO, False)
os.remove(tmp)
