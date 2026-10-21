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
	# Los del centro comercial (PixelLab, con las guías de tools/guias_centro.py). Los altos (estanterías,
	# taquillas, neveras) solo en la pared del fondo: de lado, vistos desde arriba, no se entienden
	"gondola":         {"len": 124, "dep": 44, "paredes": "",      "archivo": "centro/gondola"},
	"checkout":        {"len": 96,  "dep": 48, "paredes": "lados", "archivo": "centro/caja"},
	"drinkfridge":     {"len": 56,  "dep": 48, "paredes": "",      "archivo": "centro/nevera-bebidas"},
	"clothesrack":     {"len": 88,  "dep": 36, "paredes": "lados", "archivo": "centro/perchero-ropa"},
	"mannequin":       {"len": 32,  "dep": 28, "paredes": "todas", "archivo": "centro/maniqui"},
	"tvshelf":         {"len": 116, "dep": 40, "paredes": "",      "archivo": "centro/estanteria-teles"},
	"pharmacycounter": {"len": 100, "dep": 48, "paredes": "",      "archivo": "centro/mostrador-farmacia"},
	"metalshelf":      {"len": 80,  "dep": 40, "paredes": "",      "archivo": "centro/estanteria-metal"},
	"pallet":          {"len": 68,  "dep": 56, "paredes": "todas", "archivo": "centro/pale"},
	"lockers":         {"len": 100, "dep": 40, "paredes": "",      "archivo": "centro/taquillas"},
	"workbench":       {"len": 100, "dep": 48, "paredes": "lados", "archivo": "centro/banco-trabajo"},
	"freezershelf":    {"len": 84,  "dep": 44, "paredes": "",      "archivo": "centro/estanteria-camara"},
	"industrialstove": {"len": 84,  "dep": 54, "paredes": "lados", "archivo": "centro/fogon-industrial"},
	"steeltable":      {"len": 88,  "dep": 48, "paredes": "",      "archivo": "centro/mesa-acero"},
	"fryer":           {"len": 48,  "dep": 48, "paredes": "",      "archivo": "centro/freidora"},
	"diningtable":     {"len": 96,  "dep": 64, "paredes": "",      "archivo": "centro/mesa-restaurante"},
	"bench":           {"len": 92,  "dep": 36, "paredes": "lados", "archivo": "centro/banco-galeria"},
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
	# Las salas de las tiendas del centro comercial (tienda.gd). La sala de venta va por tipo de tienda
	# ("tienda-<tipo>", y "tienda" si un tipo no tiene la suya); la cocina del restaurante es "cocina-restaurante"
	# (Muebles.de_apartamento busca primero "<uso>-<tipo de tienda>"). Sin plantillas: son salas grandes y se
	# amueblan todas sus paredes
	"tienda": {
		"muebles": ["gondola", "metalshelf", "checkout", "pallet"],
		"cuantos": [9, 13],
		"iguales": {"gondola": 3, "metalshelf": 2},
	},
	"tienda-supermercado": {
		"muebles": ["gondola", "gondola", "drinkfridge", "checkout", "pallet"],
		"cuantos": [9, 13],
		"iguales": {"gondola": 4, "drinkfridge": 2, "checkout": 2, "pallet": 2},
	},
	"tienda-ferreteria": {
		"muebles": ["metalshelf", "metalshelf", "workbench", "checkout", "pallet"],
		"cuantos": [9, 13],
		"iguales": {"metalshelf": 4, "pallet": 2},
	},
	"tienda-electronica": {
		"muebles": ["tvshelf", "tvshelf", "metalshelf", "checkout", "pallet"],
		"cuantos": [9, 13],
		"iguales": {"tvshelf": 3, "metalshelf": 2},
	},
	"tienda-restaurante": {
		"muebles": ["diningtable", "diningtable", "checkout", "drinkfridge", "bench"],
		"cuantos": [9, 13],
		"iguales": {"diningtable": 4, "bench": 2},
	},
	"tienda-ropa": {
		"muebles": ["clothesrack", "clothesrack", "mannequin", "mannequin", "checkout", "bench"],
		"cuantos": [9, 13],
		"iguales": {"clothesrack": 4, "mannequin": 3},
	},
	"tienda-farmacia": {
		"muebles": ["pharmacycounter", "metalshelf", "metalshelf", "drinkfridge", "bench"],
		"cuantos": [8, 11],
		"iguales": {"metalshelf": 3},
	},
	# la tienda destrozada del jefe de la planta
	"jefe-tienda": {
		"muebles": ["gondola", "metalshelf", "pallet", "checkout", "mannequin"],
		"cuantos": [2, 3],
	},
	"almacen": {
		"muebles": ["metalshelf", "metalshelf", "pallet", "pallet", "lockers"],
		"cuantos": [2, 4],
		"iguales": {"metalshelf": 3, "pallet": 2},
	},
	"camara": {
		"muebles": ["freezershelf", "freezershelf", "pallet"],
		"cuantos": [2, 4],
		"iguales": {"freezershelf": 3},
	},
	"cocina-restaurante": {
		"muebles": ["industrialstove", "steeltable", "fryer", "metalshelf", "drinkfridge"],
		"cuantos": [2, 4],
	},
	"taller": {
		"muebles": ["workbench", "metalshelf", "pallet"],
		"cuantos": [2, 4],
		"iguales": {"metalshelf": 2},
	},
	"taquillas": {
		"muebles": ["lockers", "lockers", "bench"],
		"cuantos": [2, 4],
		"iguales": {"lockers": 2},
	},
	"probadores": {
		"muebles": ["mannequin", "clothesrack", "bench"],
		"cuantos": [2, 4],
		"iguales": {"mannequin": 2},
	},
	"rebotica": {
		"muebles": ["metalshelf", "metalshelf", "pharmacycounter", "pallet"],
		"cuantos": [2, 4],
		"iguales": {"metalshelf": 2},
	},
	# el pasillo del centro comercial
	"galeria": {
		"muebles": ["bench", "plant", "mannequin", "bench", "plant"],
		"cuantos": [5, 8],
		"iguales": {"bench": 3, "plant": 2},
		"fondo_max": 46,   # estrecho, como el de los pisos
	},
	# en mantenimiento la pared de arriba queda libre: ahí irán el ordenador, el baúl y el banco de trabajo
	"mantenimiento": {
		"muebles": ["washer", "bookshelf", "desk", "wardrobe", "shoerack"],
		"cuantos": [2, 3],
	},
}
