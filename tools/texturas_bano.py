# Prepara las texturas del baño (de assets/sprites/) para el TileSet de Godot y las deja en assets/tiles/bano/.
#
#   py tools/texturas_bano.py
#
# - Suelos (192×192): tal cual. Son 12×12 casillas de 16 píxeles.
# - Paredes (209×48): se quita la última columna para que midan 208 (13 casillas justas) × 48 (3 de alto).
# - Tapa (128×128, 8×8 casillas): se oscurece como en el juego (un velo negro al 32 %), para que el
#   alto de los muros se vea por detrás del suelo.
# Los muebles no hace falta prepararlos: sus escenas usan directamente assets/sprites/mueble-*.png.
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
JUEGO = RAIZ / "assets" / "sprites"
AQUI = RAIZ / "assets" / "tiles" / "bano"
AQUI.mkdir(parents=True, exist_ok=True)

for nombre in ["suelo-bano-a", "suelo-bano-b"]:
    Image.open(JUEGO / f"{nombre}.png").save(AQUI / f"{nombre}.png")

for nombre in ["pared-bano-a", "pared-bano-b"]:
    pared = Image.open(JUEGO / f"{nombre}.png")
    pared.crop((0, 0, 208, 48)).save(AQUI / f"{nombre}.png")

tapa = Image.open(JUEGO / "tapa-bano.png").convert("RGBA")
velo = Image.new("RGBA", tapa.size, (0, 0, 0, round(255 * 0.32)))
Image.alpha_composite(tapa, velo).save(AQUI / "tapa-bano.png")
