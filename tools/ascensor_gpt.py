# El ascensor averiado del pasillo de los Apartamentos y su cinta de balizamiento, de dos imágenes de GPT (8 nov):
#   assets/sources/ascensor-gpt.webp → assets/sprites/ascensor.png  (41 × 46): acero sucio y arañado, de frente, con el
#                                     indicador negro de encima apagado (la lucecita roja o verde la pinta puerta.gd)
#   assets/sources/cinta-gpt.webp    → assets/sprites/cinta.png     (48 × 6): un trozo de la cinta amarilla y negra que se
#                                     repite a lo largo (6 rayas de cada color, de raya a raya: empalma sin costura)
# Se recorta lo que no es fondo negro y se reduce MEZCLANDO colores (la media de cada trozo), como los muebles de GPT.
#   py tools/ascensor_gpt.py   (y luego Godot --headless --path . --import)
from PIL import Image

# el ascensor ocupa de x 173 a 1080 y de y 111 a 1138; 46 de alto (casi lo alto de la pared, 48) y el ancho por su forma
asc = Image.open('assets/sources/ascensor-gpt.webp').convert('RGB')
asc.resize((41, 46), Image.BOX, box=(173, 111, 1081, 1139)).save('assets/sprites/ascensor.png')
# la cinta, de y 433 a 590; sus rayas amarillas empiezan cada 215,7 píxeles (172, 385... 1466): seis vueltas enteras
cinta = Image.open('assets/sources/cinta-gpt.webp').convert('RGB')
cinta.resize((48, 6), Image.BOX, box=(172, 433, 1466, 591)).save('assets/sprites/cinta.png')
print('ascensor 41x46, cinta 48x6')
