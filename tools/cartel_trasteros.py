# La placa del cartel de «TRASTEROS» del pasillo de las viviendas (cartel_trasteros.gd), de una imagen de GPT (8 nov):
# chapa esmaltada azul, vieja, con su filete crema, óxido en las esquinas y un tornillo a cada lado, SIN letras (el juego
# escribe encima «TRASTEROS» ya traducido y la estira por en medio con lo que mida el texto).
# Se reduce MEZCLANDO colores como los muebles (tools/muebles_gpt.py: pasar):
#   assets/sprites/cartel-trasteros.png   → 64 × 15 píxeles (30 unidades de alto, como antes)
# Uso: py tools/cartel_trasteros.py  (y luego Godot --headless --path . --import)
import os
import sys

sys.argv = sys.argv[:1] + ["corcho"]   # muebles_gpt.py pasa sus muebles al cargarse: que solo pase uno, y deprisa
sys.path.insert(0, os.path.dirname(__file__))
from muebles_gpt import pasar  # noqa: E402

pasar("assets/sources/cartel-trasteros-gpt.webp", "assets/sprites/cartel-trasteros.png", 64, 15, False)
