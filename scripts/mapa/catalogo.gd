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
	# el sofá visto por detrás (girado 180° por PixelLab a partir del de frente), para ponerlo de cara a la tele, en medio del salón
	"sofaback":   {"len": 132, "dep": 60,  "paredes": "",      "archivo": "salon/sofa-espalda"},
	"tv":         {"len": 80,  "dep": 40,  "paredes": "",      "archivo": "salon/tele"},
	"armchair":   {"len": 90,  "dep": 60,  "paredes": "lados", "archivo": "salon/sillon"},
	"bookshelf":  {"len": 46,  "dep": 34,  "paredes": "",      "archivo": "salon/estanteria"},
	"lamp":       {"len": 30,  "dep": 30,  "paredes": "todas", "archivo": "comun/lampara"},
	"counter":    {"len": 158, "dep": 50,  "paredes": "",      "archivo": "cocina/encimera"},
	"fridge":     {"len": 62,  "dep": 58,  "paredes": "",      "archivo": "cocina/nevera"},
	"stove":      {"len": 56,  "dep": 50,  "paredes": "",      "archivo": "cocina/fogon"},
	# la mesa de la cocina con sus dos sillas, una a cada lado (un solo dibujo: van siempre juntas)
	"kitchentable": {"len": 112, "dep": 54, "paredes": "",     "archivo": "cocina/mesa"},
	# el dormitorio rehecho de frente (PixelLab, con las guías de tools/guias_dormitorio.py): la cama de matrimonio y la
	# individual, con el cabecero contra la pared y los pies abajo. La cama de matrimonio y la mesilla (con su lamparita)
	# tienen también dibujo de lado (cama-matrimonio-lado y mesilla-lado: PixelLab los giró a partir de los de frente)
	"doublebed":  {"len": 124, "dep": 140, "paredes": "lados", "archivo": "dormitorio/cama-matrimonio"},
	"bed":        {"len": 84,  "dep": 140, "paredes": "lados", "archivo": "dormitorio/cama"},
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
	"chimney":         {"len": 48,  "dep": 48, "paredes": "todas", "archivo": "centro/chimenea"},   # (ya no sale en la azotea)
	"vent":            {"len": 44,  "dep": 44, "paredes": "todas", "archivo": "centro/extractor"},
	# y los de la azotea de los Apartamentos (con el extractor): depósito de agua, antenas y tendedero
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
	# los de la sala de mantenimiento (sus tres estancias, planta.gd; PixelLab, con las guías de
	# tools/guias_mantenimiento.py), que no salen en los pisos: en el vestuario, el plato de ducha, el banco largo sin
	# respaldo (suelto, se ve igual desde cualquier lado), el váter y el lavabo con su espejo (estos dos, solo de lado: no
	# tienen dibujo de frente); en el taller, la estantería metálica con botes; y en el despacho, la papelera
	"showertray":      {"len": 72,  "dep": 64, "paredes": "",      "archivo": "vestuario/plato-ducha"},
	"lockerbench":     {"len": 128, "dep": 28, "paredes": "todas", "archivo": "vestuario/banco-vestuario"},
	"stafftoilet":     {"len": 40,  "dep": 52, "paredes": "lados", "archivo": "vestuario/vater-vestuario"},
	"staffsink":       {"len": 52,  "dep": 40, "paredes": "lados", "archivo": "vestuario/lavabo-espejo"},
	"canshelf":        {"len": 80,  "dep": 36, "paredes": "",      "archivo": "mantenimiento/estanteria-botes"},
	"wastebasket":     {"len": 24,  "dep": 22, "paredes": "todas", "archivo": "despacho/papelera"},
}

# Cada sala, por su uso (el de apartamento.gd, más el pasillo; la sala de mantenimiento no tiene muebles sueltos):
#   muebles     los que puede tener (uno repetido en la lista sale más a menudo)
#   cuantos     [mínimo, máximo] de muebles sueltos (en las habitaciones grandes, alguno más)
#   iguales     cuántos de un mismo mueble caben (los que no salen aquí, uno)
#   plantillas  la pared del fondo es la que más se ve (es alta y de frente), así que en baño, cocina, salón y
#               dormitorio no se llena al azar: cada plantilla dice qué va en ella de izquierda a derecha y el
#               juego elige una que quepa. Los marcados con "?" son opcionales: si no cabe todo, se quitan en
#               el orden de "quitar". Cada mueble sale una vez por plantilla (nunca dos lavadoras en el mismo
#               baño). Con plantillas, solo se amuebla la pared del fondo; si en ella no cabe nada (una puerta
#               en medio), muebles sueltos en las demás paredes, como en las otras salas.
#   colocados   en vez de plantillas, los muebles puestos a mano, siempre en el mismo sitio, según el lado de la entrada
#               del piso: {"abajo": [[tipo, centro en casillas desde la esquina de arriba a la izquierda, pared], ...]};
#               la pared ("izquierda", "derecha" o "abajo"; sin ponerla, la de arriba) es la de la habitación, y el centro
#               va a lo largo de ella; un cuarto dato, "apagada", deja sin luz una lámpara o una mesilla y "espejo"
#               pone el dibujo del revés (ver Muebles.colocados y Muebles.de_piso: es lo único que lleva un piso; los
#               baños de los pisos van por "bano-<tipo de su dormitorio>")
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
		# puestos a mano en los pisos (idea del dueño), igual en el normal y en el volteado, en la pared de arriba: la tele sobre
		# las casillas 3 a 5, una lámpara de pie en la 1 y otra en la 18, la planta en la 9 y la estantería sobre la 16 y la 17;
		# el sofá, visto por detrás, de cara a la tele, en las filas 3 y 4; y la mesa de la cocina cerca de la esquina de abajo a
		# la derecha, sin pegarse. En el piso volteado, la pared del pasillo tapa las dos últimas filas: allí la mesa, más arriba
		"colocados": {
			"abajo": [["tv", 3.5], ["lamp", 0.5], ["lamp", 17.5], ["plant", 8.5], ["bookshelf", 16.0],
				["sofaback", 3.5, "libre", 3.0], ["kitchentable", 15.25, "libre", 6.15]],
			"arriba": [["tv", 3.5], ["lamp", 0.5], ["lamp", 17.5], ["plant", 8.5], ["bookshelf", 16.0],
				["sofaback", 3.5, "libre", 3.0], ["kitchentable", 15.25, "libre", 4.15]],
		},
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
	# la puerta). Sin lámparas: la luz es fija (peligros/luz_jefe.gd). Por el suelo, mancuernas con las que Johnny
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
		# el fogón es obligatorio; la encimera es larga (158), así que en las cocinas pequeñas se queda fuera. La mesa
		# con sus sillas sale en tres plantillas; si no cabe todo, se va antes la encimera que la mesa
		"plantillas": [
			["fridge", "counter?", "stove", "plant?"],
			["counter?", "stove", "fridge?", "plant?"],
			["fridge?", "stove", "counter?", "kitchentable?"],
			["plant?", "fridge?", "counter?", "stove", "kitchentable?"],
			["counter?", "stove", "counter?", "fridge?"],
			["fridge?", "counter?", "stove", "counter?"],
			["kitchentable?", "fridge?", "stove", "plant?"],
		],
		"quitar": ["plant", "counter", "kitchentable", "fridge"],
		# puestos a mano en los pisos (idea del dueño), igual en el normal y en el volteado, en la pared de arriba: la planta en la
		# casilla 2, la nevera sobre la 9 y la 10, el fogón sobre la 11 y la 12 y la encimera de la 13 a la 17; y la mesa con sus
		# sillas a la derecha, en las filas 4 y 5, sin pegarse a la pared
		"colocados": {
			"abajo": [["plant", 1.5], ["fridge", 9.0], ["stove", 11.0], ["counter", 14.5], ["kitchentable", 15.25, "libre", 4.0]],
			"arriba": [["plant", 1.5], ["fridge", 9.0], ["stove", 11.0], ["counter", 14.5], ["kitchentable", 15.25, "libre", 4.0]],
		},
	},
	# cada dormitorio del apartamento es "de matrimonio" o "individual" (apartamento.gd): el primero lleva la cama grande, con
	# una mesilla a cada lado (si falta sitio, se caen las dos juntas), y el segundo la pequeña, con una sola mesilla. La
	# cama es obligatoria
	"dormitorio-matrimonio": {
		"muebles": ["doublebed", "wardrobe", "nightstand", "desk", "lamp"],
		"cuantos": [2, 4],
		"iguales": {"nightstand": 2},
		"plantillas": [
			["wardrobe?", "nightstand?", "doublebed", "nightstand?", "lamp?"],
			["desk?", "nightstand?", "doublebed", "nightstand?", "wardrobe?"],
			["lamp?", "nightstand?", "doublebed", "nightstand?", "desk?"],
			["desk?", "wardrobe?", "nightstand?", "doublebed", "nightstand?", "lamp?"],
		],
		"quitar": ["lamp", "desk", "wardrobe", "nightstand"],
		# puestos a mano (idea del dueño). En el piso normal (el que se entra por abajo), en la pared de arriba: el armario sobre
		# las casillas 2 y 3, la mesilla en la 6, la cama de la 7 a la 10 y la otra mesilla en la 11. En el volteado (entrada
		# "arriba"), la pared de arriba es la del pasillo y la puerta (casillas 5 y 6) cae en ella: allí, el armario en medio de
		# esa pared (sobre las casillas 8 a 10, donde estaba la cama) y la cama con sus dos mesillas pegada a la pared de la
		# izquierda, con el cabecero contra ella y algo más abajo del centro (el centro de la cama, en la fila 5,25 de 9; las
		# mesillas, una a cada lado). La de arriba, pegada a la cama, con la lamparita apagada: su luz salía recortada por la
		# sombra de la cama; la de abajo, encendida, y parpadeando
		"colocados": {
			"abajo": [["wardrobe", 2.0], ["nightstand", 5.5], ["doublebed", 8.0], ["nightstand", 10.5]],
			"arriba": [["wardrobe", 9.0], ["nightstand", 3.85, "izquierda", "apagada"], ["doublebed", 5.25, "izquierda"],
				["nightstand", 7.88, "izquierda"]],
		},
	},
	"dormitorio-individual": {
		"muebles": ["bed", "wardrobe", "nightstand", "desk", "lamp"],
		"cuantos": [2, 4],
		"plantillas": [
			["bed", "nightstand?", "wardrobe?", "desk?"],
			["lamp?", "wardrobe?", "bed", "nightstand?", "desk?"],
			["wardrobe?", "bed", "nightstand?", "lamp?"],
			["desk?", "bed", "nightstand?", "wardrobe?"],
		],
		"quitar": ["lamp", "desk", "wardrobe", "nightstand"],
		# puestos a mano (idea del dueño). En el piso normal, en la pared de arriba: el escritorio sobre las casillas 2 a 4, el
		# armario sobre la 6 y la 7, y de la 9 a la 12 la mesilla pegada a la cama (la mesilla a la izquierda). En el volteado
		# (entrada "arriba"), la pared de arriba es la del pasillo, con la puerta en las casillas 7 y 8: el escritorio en medio del
		# trozo largo, a su izquierda (casilla 3), el armario en medio del corto, a su derecha (casilla 10), y en la pared de la
		# derecha la cama, de lado, con el cabecero contra ella, en la mitad algo más abajo, y la mesilla debajo (el dibujo de la
		# mesilla de lado, en espejo)
		"colocados": {
			"abajo": [["desk", 2.5], ["wardrobe", 6.0], ["nightstand", 8.65], ["bed", 10.6]],
			"arriba": [["desk", 3.0], ["wardrobe", 10.0], ["bed", 5.0, "derecha"], ["nightstand", 6.95, "derecha"]],
		},
	},
	# el de respaldo, para un dormitorio sin tipo: la mitad de las plantillas con la cama de matrimonio y la otra mitad con
	# la individual
	"dormitorio": {
		"muebles": ["bed", "doublebed", "wardrobe", "nightstand", "desk", "lamp"],
		"cuantos": [2, 4],
		"iguales": {"nightstand": 2},
		"plantillas": [
			["wardrobe?", "nightstand?", "doublebed", "nightstand?", "lamp?"],
			["desk?", "nightstand?", "doublebed", "nightstand?", "wardrobe?"],
			["lamp?", "nightstand?", "doublebed", "nightstand?", "desk?"],
			["bed", "nightstand?", "wardrobe?", "desk?"],
			["lamp?", "wardrobe?", "bed", "nightstand?", "desk?"],
			["wardrobe?", "bed", "nightstand?", "lamp?"],
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
	# los dos baños de los pisos, con los muebles del vestuario de la sala de mantenimiento, puestos a mano (idea del dueño;
	# cada baño, 7 casillas de ancho): el de la derecha, el de matrimonio, con la ducha en la esquina de arriba a la izquierda
	# (la de la pared de la puerta, que queda más abajo), como en el vestuario de mantenimiento, pero metida unas unidades en
	# los muros ("libre": 4 a un lado y 6 arriba) para que el borde del plato toque las dos paredes y no se vea suelo entre
	# medias; el lavabo, pegado a la pared de la derecha, centrado en la casilla 3 (más arriba, el espejo sobresaldría
	# del muro) y el váter en esa misma pared sobre las casillas 6 y 7; el de la izquierda, el del individual, es su espejo (todo cambia de
	# pared y la ducha lleva su dibujo del revés). Igual en los pisos volteados
	"bano-matrimonio": {
		"colocados": {
			"abajo": [["showertray", 1.0, "libre", 0.8125], ["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
			"arriba": [["showertray", 1.0, "libre", 0.8125], ["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		},
	},
	"bano-individual": {
		"colocados": {
			"abajo": [["showertray", 6.0, "libre", 0.8125, "espejo"], ["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
			"arriba": [["showertray", 6.0, "libre", 0.8125, "espejo"], ["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		},
	},
	# el pasillo de cada planta de los Apartamentos: de momento, sin muebles (si vuelven, solo poco hondos: el pasillo es
	# estrecho, "fondo_max": 46; los de antes: shoerack, coatstand, console, plant y bookshelf, de 5 a 8)
	"pasillo": {"muebles": [], "cuantos": [0, 0]},
	# el pasillo de dentro de un piso (apartamento.gd: PLANO_PASILLO), con su recibidor: pocos muebles
	"pasillo-piso": {
		"muebles": ["shoerack", "coatstand", "console", "plant"],
		"cuantos": [2, 4],
		"fondo_max": 46,
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
	# Las viviendas de los supervivientes rescatados (viviendas.gd): el pasillo y la habitación de cada uno
	# ("habitacion-<id>"; "habitacion", la de quien no tenga la suya). De momento, vacías: se decoran en otra tarea
	"pasillo-viviendas": {"muebles": [], "cuantos": [0, 0]},
	"habitacion": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-policia": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-medico": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-militar": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-ferretero": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-farmaceutica": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-tecnico": {"muebles": [], "cuantos": [0, 0]},
}
