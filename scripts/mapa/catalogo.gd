# Catálogo de muebles, sala por sala (el mismo que src/catalogo.js del juego JS)
#
# Todo lo que decide qué muebles salen y dónde está aquí, en un solo sitio:
#   MUEBLES -> cada mueble: sus medidas, en qué paredes puede ir y cómo se llama su archivo original
#   SALAS   -> cada sala: qué muebles lleva, cuántos, cuántos iguales y (baño, cocina, salón y dormitorio) las
#              plantillas de la pared del fondo
# Cómo se colocan, en muebles.gd; cómo se montan en el mapa, en mueble.gd.
#
# Los originales (los dibujos grandes) están en assets/sources/salas/<carpeta>/<archivo>.png (y
# <archivo>-lado.png, el dibujo para las paredes laterales). El juego usa el sprite assets/sprites/mueble-<tipo>.png.
# Variantes: nevera-b.png, nevera-c.png... (sprites mueble-fridge-b, -c...; de lado, nevera-b-lado.png). Cada
# apartamento elige una por tipo. Todas miden lo mismo de ancho: el "len" de aquí.
# "py tools/importar.py" convierte las imágenes nuevas o cambiadas en sprites (y las deja a ese ancho): lee este
# archivo, así que hay que escribirlo como hasta ahora (nombres entre comillas y nada de "#" dentro de los textos).
class_name Catalogo

# Cada mueble, por su tipo (el nombre que usa el juego):
#   len      largo a lo largo de la pared (el ancho del dibujo: así se choca justo con lo que se ve), en unidades
#   dep      fondo hacia la sala
#   paredes  en qué paredes puede ir. En la de arriba (el fondo), todos: se les ve de frente.
#            "lados" -> también en las laterales: tiene dibujo de lado (en la derecha se pone en espejo)
#            "todas" -> en cualquiera, también en la de abajo: se ve igual desde cualquier sitio
#            (sin nada, solo en la del fondo: en las demás se vería de lado o de espaldas)
#   archivo  nombre del original en assets/sources/salas/<carpeta>/
const MUEBLES := {
	"sofa":       {"len": 132, "dep": 60,  "paredes": "lados", "archivo": "salon/sofa"},
	"tv":         {"len": 80,  "dep": 40,  "paredes": "",      "archivo": "salon/tele"},
	"armchair":   {"len": 90,  "dep": 60,  "paredes": "lados", "archivo": "salon/sillon"},
	"bookshelf":  {"len": 46,  "dep": 34,  "paredes": "",      "archivo": "salon/estanteria"},
	"lamp":       {"len": 30,  "dep": 30,  "paredes": "todas", "archivo": "comun/lampara"},
	"counter":    {"len": 158, "dep": 50,  "paredes": "",      "archivo": "cocina/encimera"},
	"fridge":     {"len": 62,  "dep": 58,  "paredes": "",      "archivo": "cocina/nevera"},
	"stove":      {"len": 56,  "dep": 50,  "paredes": "",      "archivo": "cocina/fogon"},
	"bed":        {"len": 84,  "dep": 140, "paredes": "",      "archivo": "dormitorio/cama"},
	"wardrobe":   {"len": 96,  "dep": 44,  "paredes": "",      "archivo": "dormitorio/armario"},
	"nightstand": {"len": 40,  "dep": 36,  "paredes": "lados", "archivo": "dormitorio/mesilla"},
	"desk":       {"len": 92,  "dep": 50,  "paredes": "",      "archivo": "dormitorio/escritorio"},
	"shoerack":   {"len": 74,  "dep": 34,  "paredes": "",      "archivo": "pasillo/zapatero"},
	"coatstand":  {"len": 36,  "dep": 30,  "paredes": "todas", "archivo": "pasillo/perchero"},
	"console":    {"len": 68,  "dep": 34,  "paredes": "",      "archivo": "pasillo/consola"},
	"bathtub":    {"len": 116, "dep": 60,  "paredes": "lados", "archivo": "bano/banera"},
	"toilet":     {"len": 52,  "dep": 58,  "paredes": "lados", "archivo": "bano/vater"},
	"sink":       {"len": 64,  "dep": 46,  "paredes": "",      "archivo": "bano/lavabo"},
	"washer":     {"len": 46,  "dep": 50,  "paredes": "",      "archivo": "bano/lavadora"},
	"plant":      {"len": 40,  "dep": 36,  "paredes": "todas", "archivo": "comun/planta"},
}

# Cada sala, por su uso (el de apartamento.gd, más el pasillo y la sala de mantenimiento):
#   muebles     los que puede tener (uno repetido en la lista sale más a menudo)
#   cuantos     [mínimo, máximo] de muebles sueltos (en las habitaciones grandes, alguno más)
#   iguales     cuántos de un mismo mueble caben (los que no salen aquí, uno)
#   plantillas  la pared del fondo es la que más se ve (es alta y de frente), así que en baño, cocina, salón y
#               dormitorio no se llena al azar: cada plantilla dice qué va en ella de izquierda a derecha y el
#               juego elige una que quepa. Los marcados con "?" son opcionales: si no cabe todo, se quitan en
#               el orden de "quitar". Cada mueble sale una vez por plantilla (nunca dos lavadoras en el mismo
#               baño). Con plantillas, solo se amuebla la pared del fondo; si en ella no cabe nada (una puerta
#               en medio), muebles sueltos en las demás paredes, como en las otras salas.
#   fondo_max   el fondo máximo de sus muebles (para sitios estrechos)
const SALAS := {
	"salon": {
		"muebles": ["sofa", "tv", "armchair", "bookshelf", "lamp", "plant"],
		"cuantos": [4, 7],
		# el sofá es obligatorio; en los salones estrechos se caen primero la planta y la lámpara
		"plantillas": [
			["bookshelf?", "sofa", "tv", "plant?"],
			["plant?", "sofa", "lamp?", "bookshelf?"],
			["armchair?", "tv", "sofa", "lamp?"],
			["bookshelf?", "tv?", "sofa", "armchair?"],
			["lamp?", "sofa", "bookshelf?", "armchair?"],
			["plant?", "armchair?", "sofa", "tv?"],
		],
		"quitar": ["plant", "lamp", "armchair", "bookshelf", "tv"],
	},
	# el apartamento destrozado de la jefa: los muebles del salón, menos y sin plantillas
	"jefe": {
		"muebles": ["sofa", "tv", "armchair", "bookshelf", "lamp", "plant"],
		"cuantos": [2, 3],
	},
	"cocina": {
		"muebles": ["counter", "fridge", "stove", "counter", "plant"],
		"cuantos": [2, 4],
		"iguales": {"counter": 2},
		# el fogón es obligatorio; la encimera es larga (158), así que en las cocinas pequeñas se queda fuera
		"plantillas": [
			["fridge", "counter?", "stove", "plant?"],
			["counter?", "stove", "fridge?", "plant?"],
			["fridge?", "stove", "counter?"],
			["plant?", "fridge?", "counter?", "stove"],
			["counter?", "stove", "counter?", "fridge?"],
			["fridge?", "counter?", "stove", "counter?"],
		],
		"quitar": ["plant", "counter", "fridge"],
	},
	"dormitorio": {
		"muebles": ["bed", "wardrobe", "nightstand", "desk", "lamp"],
		"cuantos": [2, 4],
		"iguales": {"nightstand": 2},
		# la cama es obligatoria, casi siempre con una mesilla a cada lado (si falta sitio, se caen las dos juntas)
		"plantillas": [
			["wardrobe?", "nightstand?", "bed", "nightstand?", "lamp?"],
			["desk?", "nightstand?", "bed", "nightstand?", "wardrobe?"],
			["bed", "nightstand?", "wardrobe?", "desk?"],
			["lamp?", "wardrobe?", "bed", "nightstand?", "desk?"],
			["wardrobe?", "bed", "nightstand?", "lamp?"],
			["nightstand?", "bed", "nightstand?", "desk?"],
		],
		"quitar": ["lamp", "desk", "wardrobe", "nightstand"],
	},
	"bano": {
		"muebles": ["bathtub", "toilet", "sink", "washer"],
		"cuantos": [1, 3],
		"plantillas": [
			["bathtub?", "toilet", "sink?"],
			["sink?", "toilet", "bathtub?"],
			["toilet", "sink?", "washer?"],
			["washer?", "sink?", "toilet"],
			["sink?", "toilet", "washer?"],
			["bathtub?", "sink?", "toilet"],
		],
		"quitar": ["bathtub", "washer", "sink"],
	},
	"pasillo": {
		"muebles": ["shoerack", "coatstand", "console", "plant", "bookshelf"],
		"cuantos": [5, 8],
		"fondo_max": 46,   # el pasillo de cada planta es estrecho: solo muebles poco hondos
	},
	# en mantenimiento la pared de arriba queda libre: ahí irán el ordenador, el baúl y el banco de trabajo
	"mantenimiento": {
		"muebles": ["washer", "bookshelf", "desk", "wardrobe", "shoerack"],
		"cuantos": [2, 3],
	},
}
