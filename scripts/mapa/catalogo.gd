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
	"tallmannequin":   {"len": 60,  "dep": 28, "paredes": "todas", "archivo": "centro/maniqui-alto"},
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
	# los de la joyería (parte 9): la vitrina baja (mostrador de cristal con joyas), la vitrina alta y la caja fuerte
	"jewelcase":       {"len": 96,  "dep": 44, "paredes": "lados", "archivo": "centro/vitrina-joyeria"},
	"jewelcabinet":    {"len": 64,  "dep": 36, "paredes": "",      "archivo": "centro/vitrina-alta"},
	"safe":            {"len": 56,  "dep": 48, "paredes": "",      "archivo": "centro/caja-fuerte"},
	# Los aparatos de la azotea del centro comercial (PixelLab, con las guías de tools/guias_azotea.py): van sueltos
	# por la azotea, no contra una pared (los coloca planta.gd)
	"acunit":          {"len": 128, "dep": 72, "paredes": "todas", "archivo": "centro/aire-acondicionado"},
	"airhandler":      {"len": 184, "dep": 60, "paredes": "todas", "archivo": "centro/climatizadora"},
	"chimney":         {"len": 48,  "dep": 48, "paredes": "todas", "archivo": "centro/chimenea"},
	"vent":            {"len": 44,  "dep": 44, "paredes": "todas", "archivo": "centro/extractor"},
	# y los de la azotea de los Apartamentos (con la chimenea y el extractor): depósito de agua, antenas y tendedero
	"watertank":       {"len": 96,  "dep": 64, "paredes": "todas", "archivo": "azotea/deposito-agua"},
	"antennas":        {"len": 64,  "dep": 40, "paredes": "todas", "archivo": "azotea/antenas"},
	"clothesline":     {"len": 160, "dep": 24, "paredes": "todas", "archivo": "azotea/tendedero"},
	# las máquinas del gimnasio del Gymbro (su habitación; PixelLab, con las guías de tools/guias_gimnasio.py): la
	# cinta de correr y el banco de press salen de la pared hacia la habitación; la máquina de poleas, alta, solo en
	# la del fondo; la pila de discos se ve igual desde cualquier lado
	"treadmill":       {"len": 56,  "dep": 100, "paredes": "lados", "archivo": "gimnasio/cinta-correr"},
	"benchpress":      {"len": 104, "dep": 72, "paredes": "lados", "archivo": "gimnasio/banco-press"},
	"cablemachine":    {"len": 100, "dep": 52, "paredes": "",      "archivo": "gimnasio/maquina-poleas"},
	"dumbbellrack":    {"len": 112, "dep": 40, "paredes": "lados", "archivo": "gimnasio/estante-mancuernas"},
	"weightplates":    {"len": 44,  "dep": 44, "paredes": "todas", "archivo": "gimnasio/discos"},
	# los del cuarto de la limpieza de la portera (su habitación; PixelLab, con las guías de tools/guias_limpieza.py):
	# el contenedor de basura de la comunidad, el cubo de basura de metal (los dos se ven igual desde cualquier lado) y
	# el carro de limpieza, con su cubo y su fregona
	"wheeliebin":      {"len": 56,  "dep": 48, "paredes": "todas", "archivo": "limpieza/contenedor"},
	"trashcan":        {"len": 36,  "dep": 36, "paredes": "todas", "archivo": "limpieza/cubo-basura"},
	"janitorcart":     {"len": 84,  "dep": 44, "paredes": "lados", "archivo": "limpieza/carro-limpieza"},
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
#   primero     muebles que se ponen antes que los demás, uno de cada en la lista (las lámparas de la portera)
#   fijos       en vez de unos cuantos sueltos, cada pared con sus muebles en un orden fijo (siempre igual), de punta
#               a punta: {pared: [tipos de izquierda a derecha o de arriba abajo]} (el gimnasio)
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
	# la habitación del Glotón (planta.gd pone apt.tipo = "gloton"): sin muebles (el dueño, 23 oct: tampoco lámparas);
	# el suelo lo llena su porquería (peligros/porqueria.gd) y la luz la da el resplandor del ácido
	"jefe-gloton": {
		"muebles": [],
		"cuantos": [0, 0],
	},
	# el gimnasio del Gymbro (planta.gd pone apt.tipo = "gymbro"): tres paredes llenas de máquinas, siempre en el mismo
	# sitio (muebles.gd, fijos), que le quitan sitio a la pelea: las 8 cintas de correr a la derecha; a la izquierda, los
	# 6 bancos de press y 2 pilas de discos; y en el fondo, simétrico (las poleas, la del medio justo enfrente de la
	# puerta), con las pilas de discos en las esquinas y las taquillas a continuación. La pared de abajo, vacía (ahí está
	# la puerta). Sin lámparas: la luz es fija (peligros/luz_gimnasio.gd). Por el suelo, mancuernas con las que Johnny
	# tropieza (peligros/tropiezos.gd)
	"jefe-gymbro": {
		"muebles": [],
		"cuantos": [0, 0],
		"fijos": {
			"arriba": ["weightplates", "weightplates", "lockers", "cablemachine", "dumbbellrack", "dumbbellrack",
				"cablemachine", "dumbbellrack", "dumbbellrack", "cablemachine", "lockers", "weightplates", "weightplates"],
			"izquierda": ["benchpress", "benchpress", "benchpress", "benchpress", "benchpress", "benchpress",
				"weightplates", "weightplates"],
			"derecha": ["treadmill", "treadmill", "treadmill", "treadmill", "treadmill", "treadmill", "treadmill",
				"treadmill"],
		},
	},
	# el cuarto de la limpieza de la portera (planta.gd pone apt.tipo = "portera"): contenedores y cubos de basura y el
	# carro de limpieza contra las paredes, sueltos (con hueco para esquivar su embestida); antes que nada (primero),
	# tres lámparas de pie, para que siempre haya luz, y un carro, que siempre esté. En la pared de arriba cuelgan
	# fregonas y cubos (mapa.gd, colgados) y por el suelo hay cubos con los que Johnny tropieza (peligros/tropiezos.gd)
	"jefe-portera": {
		"primero": ["lamp", "lamp", "lamp", "janitorcart"],
		"muebles": ["wheeliebin", "wheeliebin", "trashcan", "trashcan", "janitorcart"],
		"cuantos": [10, 12],
		"iguales": {"lamp": 3, "wheeliebin": 5, "trashcan": 5, "janitorcart": 2},
	},
	# la habitación del jefe de bomberos (planta.gd pone apt.tipo = "bombero"): sin muebles, que quedarían dentro del
	# fuego del borde (peligros/cerco.gd); la luz la da el propio fuego. Su cono de fuego llega así hasta la pared
	"jefe-bombero": {
		"muebles": [],
		"cuantos": [0, 0],
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
	# amueblan todas sus paredes, y además "islas": filas de muebles en medio, con pasillos (Muebles.islas)
	"tienda": {
		"muebles": ["gondola", "metalshelf", "checkout", "pallet"],
		"cuantos": [8, 11],
		"iguales": {"gondola": 3, "metalshelf": 2},
		"islas": {"muebles": ["gondola"], "fila": 3, "entre": 0, "cada": 176},
	},
	"tienda-supermercado": {
		"muebles": ["gondola", "gondola", "drinkfridge", "checkout", "pallet"],
		"cuantos": [8, 11],
		"iguales": {"gondola": 4, "drinkfridge": 2, "checkout": 2, "pallet": 2},
		"islas": {"muebles": ["gondola"], "fila": 3, "entre": 0, "cada": 176},
	},
	"tienda-ferreteria": {
		"muebles": ["metalshelf", "metalshelf", "workbench", "checkout", "pallet"],
		"cuantos": [8, 11],
		"iguales": {"metalshelf": 4, "pallet": 2},
		"islas": {"muebles": ["metalshelf"], "fila": 4, "entre": 0, "cada": 176},
	},
	"tienda-electronica": {
		"muebles": ["tvshelf", "tvshelf", "metalshelf", "checkout", "pallet"],
		"cuantos": [8, 11],
		"iguales": {"tvshelf": 3, "metalshelf": 2},
		"islas": {"muebles": ["tvshelf"], "fila": 2, "entre": 0, "cada": 176},
	},
	"tienda-restaurante": {
		"muebles": ["diningtable", "diningtable", "checkout", "drinkfridge", "bench"],
		"cuantos": [8, 11],
		"iguales": {"diningtable": 4, "bench": 2},
		"islas": {"muebles": ["diningtable"], "fila": 4, "entre": 40, "cada": 150},
	},
	"tienda-ropa": {
		"muebles": ["clothesrack", "clothesrack", "mannequin", "mannequin", "checkout", "bench"],
		"cuantos": [8, 11],
		"iguales": {"clothesrack": 4, "mannequin": 3},
		"islas": {"muebles": ["clothesrack", "clothesrack", "mannequin"], "fila": 3, "entre": 36, "cada": 150},
	},
	"tienda-farmacia": {
		"muebles": ["pharmacycounter", "metalshelf", "metalshelf", "drinkfridge", "bench"],
		"cuantos": [8, 11],
		"iguales": {"metalshelf": 3},
		"islas": {"muebles": ["metalshelf"], "fila": 2, "entre": 0, "cada": 176},
	},
	# la joyería (parte 9): vitrinas bajas en filas, vitrinas altas contra la pared; detrás, la trastienda (como un
	# almacén pequeño) y la cámara acorazada con sus cajas fuertes
	"tienda-joyeria": {
		"muebles": ["jewelcase", "jewelcase", "jewelcabinet", "checkout", "bench"],
		"cuantos": [7, 10],
		"iguales": {"jewelcase": 4, "jewelcabinet": 3},
		"islas": {"muebles": ["jewelcase"], "fila": 2, "entre": 40, "cada": 150},
	},
	"trastienda": {
		"muebles": ["metalshelf", "workbench", "lockers", "pallet"],
		"cuantos": [2, 4],
		"iguales": {"metalshelf": 2},
	},
	"acorazada": {
		"muebles": ["safe", "safe", "metalshelf"],
		"cuantos": [2, 4],
		"iguales": {"safe": 3, "metalshelf": 1},
	},
	# la tienda destrozada del jefe de la planta
	"jefe-tienda": {
		"muebles": ["gondola", "metalshelf", "pallet", "checkout", "mannequin"],
		"cuantos": [2, 3],
	},
	# el Taller de costura de la modista (minijefa): lleno de maniquíes de cuerpo entero, entre los que se esconde
	"jefe-modista": {
		"muebles": ["tallmannequin", "clothesrack", "tallmannequin", "checkout"],
		"cuantos": [4, 6],
		"iguales": {"tallmannequin": 6, "clothesrack": 2},
		"islas": {"muebles": ["tallmannequin"], "fila": 2, "entre": 80, "cada": 230},
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
