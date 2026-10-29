# Las fotos de las fichas de los tutoriales (scripts/tutoriales.gd): un trozo de 520 x 180 de una captura de la prueba,
# a tamaño real (la captura ya está a la escala de la pantalla: 2 unidades por píxel del dibujo), en
# assets/ui/tutorial/<id>.png. Se rehacen cuando cambia lo que se ve: primero las capturas (la prueba que dice cada
# línea, con "-- --captura ..."; ver CLAUDE.md) y luego:  py tools/fotos_tutorial.py
# Para mover un recorte, se cambian su x e y (la esquina de arriba a la izquierda en la captura, de 1239 x 640).
# Las fotos llevan texto del juego dibujado: las de cada idioma van aparte, en assets/ui/tutorial/<idioma>/<id>.png
# (ui/tutorial.gd las elige según Idioma.actual y, si falta alguna, usa la de español). Se hacen igual pero con las capturas
# sacadas con "--lang <idioma>" (o "--ingles") y el idioma como parámetro:  py tools/fotos_tutorial.py de
# (o  py tools/fotos_tutorial.py de jugar curas). Idiomas: en, pt_BR, de, fr, ru, zh_CN (los de Idioma.IDIOMAS)
import os
import sys
from PIL import Image

ANCHO, ALTO = 520, 180
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CAPTURAS = os.path.join(RAIZ, "capturas")   # (donde las deja la prueba: Captura.foto)
SALIDA = os.path.join(RAIZ, "assets", "ui", "tutorial")

# id: (captura, x, y)   · la prueba que la saca
FOTOS = {
	"jugar": ("captura-curas-hud.png", 340, 230),                 # --curas
	"apartamentos": ("captura-alerta-llave-suelo.png", 300, 400),  # --alerta 1
	"tercios": ("captura-curas-tercio.png", 0, 460),               # --curas
	"curas": ("captura-curas-armarito.png", 0, 220),               # --curas
	"inventario": ("captura-inventario.png", 180, 22),             # --inventario
	"dolares": ("captura-curas-caer.png", 370, 240),               # --curas
	"armas": ("captura-repuesto.png", 190, 60),                    # --repuesto
	"municion": ("captura-municion-suelo.png", 520, 240),          # --municion-suelo
	"lanzables": ("captura-epica-molotov.png", 400, 110),          # --epicas
	"piezas": ("captura-piezas-mochila.png", 520, 90),             # --piezas
	"jefes": ("captura-jefe.png", 360, 230),                       # --jefe gymbro --presentacion
	"mutaciones": ("captura-mutacion.png", 360, 150),              # prueba larga
	"ascensor": ("captura-ascensor-arreglado.png", 360, 130),      # --ascensor
	"supervivientes": ("captura-escolta.png", 430, 90),            # --rescate --edificio centro
	"apagon": ("captura-evento-apagon-piso.png", 380, 232),        # --evento apagon
	"incendio": ("captura-evento-incendio-cable.png", 500, 290),   # --evento incendio
	"horda": ("captura-evento-horda.png", 360, 230),               # --evento horda
	"ordenador": ("captura-ordenador.png", 170, 30),               # prueba larga
	"taquilla": ("captura-skins-taquilla.png", 330, 50),           # --skins
	"banco": ("captura-banco.png", 300, 20),                       # --banco
	"baul": ("captura-baul.png", 300, 20),                         # --baul
	"centro": ("captura-guardia.png", 360, 230),                   # --edificio centro
	"peligros": ("captura-peligro-agua.png", 380, 130),            # --fotos-tiendas --edificio centro
	"alerta": ("captura-reto-tarjeta.png", 330, 330),              # --reto si
}

# En los otros idiomas, las que salen de otra captura (la prueba larga, que no hace falta repetir para una sola foto)
FOTOS_EN = {
	"ordenador": ("captura-arriba-puntos.png", 170, 30),           # --ordenador-arriba
	"mutaciones": ("captura-mutacion.png", 360, 150),              # --mutaciones
	"centro": ("captura-guardia.png", 40, 220),                    # --edificio centro (el guardia y su grito, a la izquierda)
	"supervivientes": ("captura-escolta.png", 180, 290),           # --rescate --edificio centro
}
# Las fotos sin ningún texto dibujado (la oscuridad, la horda, un molotov...) valen en todos los idiomas: no se rehacen.
SIN_TEXTO = ["apagon", "curas", "horda", "incendio", "jugar", "lanzables", "municion", "peligros"]

if __name__ == "__main__":
	args = sys.argv[1:]
	idiomas = [a for a in args if a in ("en", "pt_BR", "de", "fr", "ru", "zh_CN")]
	solo = [a for a in args if a not in idiomas]   # (se pueden pedir solo unas: py tools/fotos_tutorial.py jugar curas)
	if idiomas:
		SALIDA = os.path.join(SALIDA, idiomas[0])
		FOTOS.update(FOTOS_EN)
		for id in SIN_TEXTO:
			FOTOS.pop(id, None)
	os.makedirs(SALIDA, exist_ok=True)
	for id, (captura, x, y) in FOTOS.items():
		if solo and id not in solo:
			continue
		ruta = os.path.join(CAPTURAS, captura)
		if not os.path.exists(ruta):
			print("falta %s (para %s)" % (captura, id))
			continue
		im = Image.open(ruta).convert("RGB")
		x = max(0, min(x, im.width - ANCHO))
		y = max(0, min(y, im.height - ALTO))
		im.crop((x, y, x + ANCHO, y + ALTO)).save(os.path.join(SALIDA, id + ".png"))
		print("%s ← %s (%d, %d)" % (id, captura, x, y))
