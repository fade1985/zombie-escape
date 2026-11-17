# El resplandor de los letreros de letras corpóreas de las tiendas (neon.gd, LETREROS; 17 nov): la luz que tienen las
# letras por detrás y que se ve en la pared alrededor. Se hace a partir del letrero (assets/sprites/letrero-<tipo>.png, de
# GPT con tools/muebles_gpt.py): su silueta, engordada y difuminada, en blanco (el juego le pone el color y lo hace
# parpadear). Sale con MARGEN píxeles de más por cada lado.
#   py tools/letrero_halo.py supermercado   (y luego Godot --headless --path . --import)
import sys
from PIL import Image, ImageFilter

MARGEN = 8

for tipo in sys.argv[1:] or ["supermercado"]:
    letras = Image.open(f"assets/sprites/letrero-{tipo}.png").convert("RGBA")
    silueta = Image.new("L", (letras.width + 2 * MARGEN, letras.height + 2 * MARGEN), 0)
    silueta.paste(letras.split()[3], (MARGEN, MARGEN))
    luz = silueta.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(3.5))
    luz = luz.point(lambda v: min(255, int(v * 1.6)))
    halo = Image.new("RGBA", silueta.size, (255, 255, 255, 0))
    halo.putalpha(luz)
    halo.save(f"assets/sprites/letrero-{tipo}-halo.png")
    print(f"assets/sprites/letrero-{tipo}-halo.png: {halo.width}x{halo.height}")
