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
	# lo de las habitaciones de los supervivientes (viviendas.gd), que son trasteros: un colchón en el suelo, con la almohada
	# descolocada y la colcha del color de cada uno (PixelLab, con la guía de tools/guias_trasteros.py; los colores, de
	# tools/camas_viviendas.py), y una estantería metálica vacía (PixelLab, con su guía)
	"mattress_policia":      {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-policia"},
	"mattress_medico":       {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-medico"},
	"mattress_militar":      {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-militar"},
	"mattress_ferretero":    {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-ferretero"},
	"mattress_farmaceutica": {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-farmaceutica"},
	"mattress_tecnico":      {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-tecnico"},
	"mattress_programador":      {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-programador"},
	"mattress_recepcionista":    {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-recepcionista"},
	"mattress_limpiadora":       {"len": 84, "dep": 124, "paredes": "", "archivo": "viviendas/colchon-limpiadora"},
	"storageshelf":          {"len": 88, "dep": 36,  "paredes": "", "archivo": "viviendas/estanteria-trastero"},
	# lo del pasillo de los trasteros (el de las viviendas): cajas de cartón apiladas, unas altas y otras bajas, y una carretilla
	# de mano cargada con dos cajas (PixelLab, con las guías de tools/guias_trasteros.py)
	"boxstack":  {"len": 64, "dep": 36, "paredes": "", "archivo": "viviendas/cajas-pila"},
	"boxpile":   {"len": 56, "dep": 32, "paredes": "", "archivo": "viviendas/cajas-bajas"},
	"handtruck": {"len": 40, "dep": 28, "paredes": "", "archivo": "viviendas/carretilla"},
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
	# y los de la azotea de los Apartamentos (con el extractor): depósito de agua, antenas y (ya no sale) tendedero
	"watertank":       {"len": 96,  "dep": 64, "paredes": "todas", "archivo": "azotea/deposito-agua"},
	"antennas":        {"len": 64,  "dep": 40, "paredes": "todas", "archivo": "azotea/antenas"},
	"clothesline":     {"len": 160, "dep": 24, "paredes": "todas", "archivo": "azotea/tendedero"},   # (ya no sale en la azotea)
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
	# Los de Torre Velaria (parte 2 del tercer edificio; PixelLab, con las guías de tools/guias_torre.py): oficina,
	# vestíbulo, centro de datos, despachos y la sala de seguridad. Los altos (rack, archivador, librería, armero, pared de
	# monitores), solo en la pared del fondo
	"cubicle":         {"len": 96,  "dep": 48, "paredes": "lados", "archivo": "torre/cubiculo"},
	"officedesk":      {"len": 100, "dep": 48, "paredes": "lados", "archivo": "torre/escritorio"},
	"printer":         {"len": 64,  "dep": 48, "paredes": "",      "archivo": "torre/impresora"},
	"copier":          {"len": 80,  "dep": 52, "paredes": "",      "archivo": "torre/fotocopiadora"},
	"serverrack":      {"len": 56,  "dep": 44, "paredes": "",      "archivo": "torre/rack-servidores"},
	"watercooler":     {"len": 32,  "dep": 28, "paredes": "todas", "archivo": "torre/fuente-agua"},
	"lobbysofa":       {"len": 96,  "dep": 40, "paredes": "lados", "archivo": "torre/sofa-vestibulo"},
	"reception":       {"len": 124, "dep": 52, "paredes": ""     , "archivo": "torre/recepcion"},
	"turnstile":       {"len": 48,  "dep": 40, "paredes": "",      "archivo": "torre/torno"},
	"filecabinet":     {"len": 64,  "dep": 36, "paredes": "",      "archivo": "torre/archivador"},
	"boardtable":      {"len": 128, "dep": 64, "paredes": "",      "archivo": "torre/mesa-juntas"},
	"execdesk":        {"len": 100, "dep": 56, "paredes": "lados", "archivo": "torre/mesa-direccion"},
	"bookcase":        {"len": 80,  "dep": 36, "paredes": "",      "archivo": "torre/libreria"},
	"mixerdesk":       {"len": 100, "dep": 48, "paredes": "",      "archivo": "torre/mesa-mezclas"},
	"monitorwall":     {"len": 100, "dep": 36, "paredes": "",      "archivo": "torre/pared-monitores"},
	"armory":          {"len": 84,  "dep": 40, "paredes": "",      "archivo": "torre/armero"},
	"interviewtable":  {"len": 88,  "dep": 48, "paredes": "lados", "archivo": "torre/mesa-entrevistas"},
	"officekitchen":   {"len": 88,  "dep": 44, "paredes": "",      "archivo": "torre/office-cocina"},
	"towermodel":      {"len": 64,  "dep": 64, "paredes": "",      "archivo": "torre/maqueta-torre"},
	# el Plató de presentaciones del presentador (minijefe): las filas de butacas (vistas de espaldas: miran al escenario),
	# el atril, los focos de pie y la pantalla gigante de la pared del fondo
	"theaterseats":    {"len": 128, "dep": 36, "paredes": "",      "archivo": "torre/butacas"},
	"lectern":         {"len": 40,  "dep": 28, "paredes": "",      "archivo": "torre/atril"},
	"spotlight":       {"len": 40,  "dep": 36, "paredes": "",      "archivo": "torre/foco"},
	"stagescreen":     {"len": 160, "dep": 24, "paredes": "",      "archivo": "torre/pantalla-plato"},
	# el laboratorio de la planta 40 (el Sujeto 1, parte 6): las cápsulas de cristal con un sujeto dentro (la presidenta
	# las abre: laboratorio.gd cambia el dibujo por el de la abierta) y las mesas de laboratorio sueltas
	"capsule":         {"len": 48,  "dep": 40, "paredes": "",      "archivo": "torre/capsula"},
	"capsuleopen":     {"len": 48,  "dep": 40, "paredes": "",      "archivo": "torre/capsula-abierta"},
	"labbench":        {"len": 96,  "dep": 48, "paredes": "",      "archivo": "torre/mesa-laboratorio"},
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
	# Las salas de las tiendas del centro comercial (tienda.gd), fijas desde la M77: "<uso>-<tipo de tienda>" ("tienda-
	# supermercado", "cocina-restaurante", "bano-farmacia"...), cada una solo con sus "colocados" (Muebles.de_tienda)
	"tienda-supermercado": {
		# M77: el supermercado fijo (Tienda.PLANOS; casillas desde la esquina de la sala de venta, la 2,2 del plano). Con la
		# puerta abajo: tres neveras de bebidas al fondo del trozo que llega hasta atrás, palés y estanterías delante de la
		# cámara y del almacén (sueltos: esas paredes están más abajo que la de arriba de la sala), dos cajas a la izquierda,
		# dos filas de tres góndolas a cada lado del pasillo de la entrada y palés por la derecha y abajo. Volteada (la
		# puerta arriba), las neveras y las cajas en la pared de la entrada y las góndolas, más arriba
		"colocados": {
			"abajo": [
				["drinkfridge", 14.5], ["drinkfridge", 17.0], ["drinkfridge", 19.5],
				["pallet", 1.75, "libre", 10.875], ["metalshelf", 9.75, "libre", 10.625],
				["metalshelf", 23.5, "libre", 13.625], ["metalshelf", 30.5, "libre", 13.625],
				["metalshelf", 33.0, "libre", 13.625], ["pallet", 37.5, "libre", 13.875],
				["checkout", 17.0, "izquierda"], ["checkout", 21.0, "izquierda"],
				["pallet", 18.0, "derecha"], ["pallet", 22.0, "derecha"],
				["gondola", 5.4375, "libre", 16.75], ["gondola", 9.3125, "libre", 16.75], ["gondola", 13.1875, "libre", 16.75],
				["gondola", 26.4375, "libre", 16.75], ["gondola", 30.3125, "libre", 16.75], ["gondola", 34.1875, "libre", 16.75],
				["gondola", 5.4375, "libre", 22.25], ["gondola", 9.3125, "libre", 22.25], ["gondola", 13.1875, "libre", 22.25],
				["gondola", 26.4375, "libre", 22.25], ["gondola", 30.3125, "libre", 22.25], ["gondola", 34.1875, "libre", 22.25],
			],
			"arriba": [
				["drinkfridge", 2.0], ["drinkfridge", 4.0], ["drinkfridge", 6.0], ["metalshelf", 9.5],
				["checkout", 15.0], ["checkout", 25.0], ["metalshelf", 30.5], ["drinkfridge", 34.0], ["drinkfridge", 36.0],
				["pallet", 6.0, "izquierda"], ["pallet", 6.0, "derecha"], ["pallet", 15.0, "abajo"], ["pallet", 19.0, "abajo"],
				["gondola", 5.4375, "libre", 4.5], ["gondola", 9.3125, "libre", 4.5], ["gondola", 13.1875, "libre", 4.5],
				["gondola", 26.4375, "libre", 4.5], ["gondola", 30.3125, "libre", 4.5], ["gondola", 34.1875, "libre", 4.5],
				["gondola", 5.4375, "libre", 9.5], ["gondola", 9.3125, "libre", 9.5], ["gondola", 13.1875, "libre", 9.5],
				["gondola", 26.4375, "libre", 9.5], ["gondola", 30.3125, "libre", 9.5], ["gondola", 34.1875, "libre", 9.5],
			],
		},
	},
	# la cámara, el almacén y el aseo de empleados (M81: con su botiquín en el armarito, planta.gd, armaritos) del
	# supermercado fijo (M77)
	"camara-supermercado": {"colocados": {
		"abajo": [["freezershelf", 1.75], ["freezershelf", 6.0], ["freezershelf", 10.25], ["pallet", 4.5, "derecha"]],
		"arriba": [["freezershelf", 1.75], ["freezershelf", 9.25], ["pallet", 5.0, "derecha"], ["pallet", 6.0, "abajo"]],
	}},
	"almacen-supermercado": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["metalshelf", 4.0], ["lockers", 8.0], ["pallet", 6.0, "izquierda"]],
		"arriba": [["metalshelf", 1.5], ["lockers", 8.5], ["pallet", 7.0, "izquierda"], ["pallet", 3.0, "abajo"]],
	}},
	"bano-supermercado": {"colocados": {
		"abajo": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		"arriba": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
	}},
	# M77: la ferretería fija (Tienda.PLANOS; casillas desde la esquina de la sala de venta, la 2,2 del plano). Con la puerta
	# abajo: una estantería al fondo del trozo que llega hasta atrás, un banco de trabajo, estanterías y palés delante
	# del almacén y del taller (sueltos), palés a la izquierda, dos cajas a la derecha y dos filas de cuatro estanterías
	# a cada lado del pasillo de la entrada. Volteada, las cajas y las estanterías de pared, en la de la entrada
	"tienda-ferreteria": {
		"colocados": {
			"abajo": [
				["metalshelf", 20.5],
				["workbench", 3.0, "libre", 10.75], ["metalshelf", 7.5, "libre", 10.625], ["pallet", 16.0, "libre", 10.875],
				["metalshelf", 25.0, "libre", 10.625], ["pallet", 33.5, "libre", 10.875],
				["pallet", 16.0, "izquierda"], ["pallet", 20.0, "izquierda"],
				["checkout", 16.0, "derecha"], ["checkout", 20.0, "derecha"],
				["pallet", 3.0, "abajo"], ["pallet", 33.0, "abajo"],
				["metalshelf", 4.75, "libre", 14.0], ["metalshelf", 7.25, "libre", 14.0], ["metalshelf", 9.75, "libre", 14.0], ["metalshelf", 12.25, "libre", 14.0], ["metalshelf", 23.75, "libre", 14.0], ["metalshelf", 26.25, "libre", 14.0], ["metalshelf", 28.75, "libre", 14.0], ["metalshelf", 31.25, "libre", 14.0],
				["metalshelf", 4.75, "libre", 19.5], ["metalshelf", 7.25, "libre", 19.5], ["metalshelf", 9.75, "libre", 19.5], ["metalshelf", 12.25, "libre", 19.5], ["metalshelf", 23.75, "libre", 19.5], ["metalshelf", 26.25, "libre", 19.5], ["metalshelf", 28.75, "libre", 19.5], ["metalshelf", 31.25, "libre", 19.5],
			],
			"arriba": [
				["metalshelf", 2.0], ["metalshelf", 4.5], ["checkout", 12.0], ["checkout", 23.5], ["metalshelf", 28.0],
				["metalshelf", 30.5], ["pallet", 34.0],
				["pallet", 6.0, "izquierda"], ["pallet", 7.0, "derecha"], ["pallet", 19.25, "abajo"], ["pallet", 21.75, "abajo"],
				["metalshelf", 4.75, "libre", 4.5], ["metalshelf", 7.25, "libre", 4.5], ["metalshelf", 9.75, "libre", 4.5], ["metalshelf", 12.25, "libre", 4.5], ["metalshelf", 23.75, "libre", 4.5], ["metalshelf", 26.25, "libre", 4.5], ["metalshelf", 28.75, "libre", 4.5], ["metalshelf", 31.25, "libre", 4.5],
				["metalshelf", 4.75, "libre", 9.5], ["metalshelf", 7.25, "libre", 9.5], ["metalshelf", 9.75, "libre", 9.5], ["metalshelf", 12.25, "libre", 9.5], ["metalshelf", 23.75, "libre", 9.5], ["metalshelf", 26.25, "libre", 9.5], ["metalshelf", 28.75, "libre", 9.5], ["metalshelf", 31.25, "libre", 9.5],
			],
		},
	},
	# el almacén, el aseo de empleados (M81) y el taller de la ferretería fija (M77)
	"almacen-ferreteria": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["metalshelf", 4.0], ["pallet", 7.5]],
		"arriba": [["metalshelf", 1.5], ["pallet", 7.75], ["pallet", 4.5, "abajo"]],
	}},
	"bano-ferreteria": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	"taller-ferreteria": {"colocados": {
		"abajo": [["workbench", 2.0], ["metalshelf", 6.0], ["workbench", 10.0], ["pallet", 4.5, "derecha"]],
		"arriba": [["workbench", 2.0], ["metalshelf", 8.0], ["pallet", 5.0, "derecha"], ["pallet", 9.5, "abajo"]],
	}},
	# M77: la electrónica fija (Tienda.PLANOS, con el charco con corriente dibujado a la izquierda). Con la puerta abajo:
	# una estantería de teles al fondo del trozo que llega hasta atrás, teles, estanterías y palés delante de las
	# taquillas y del almacén, dos cajas a la derecha y dos filas de tres estanterías de teles a la derecha (a la izquierda,
	# el charco). Volteada, las cajas y las teles de pared, en la de la entrada
	"tienda-electronica": {
		"colocados": {
			"abajo": [
				["tvshelf", 14.5],
				["metalshelf", 2.0, "libre", 10.625], ["pallet", 8.75, "libre", 10.875],
				["tvshelf", 20.0, "libre", 10.625], ["tvshelf", 27.0, "libre", 10.625], ["tvshelf", 31.0, "libre", 10.625],
				["pallet", 34.5, "libre", 10.875],
				["pallet", 21.5, "izquierda"], ["checkout", 16.0, "derecha"], ["checkout", 20.0, "derecha"],
				["pallet", 2.0, "abajo"], ["pallet", 33.5, "abajo"],
				["tvshelf", 23.3125, "libre", 15.0], ["tvshelf", 26.9375, "libre", 15.0], ["tvshelf", 30.5625, "libre", 15.0],
				["tvshelf", 23.3125, "libre", 20.5], ["tvshelf", 26.9375, "libre", 20.5], ["tvshelf", 30.5625, "libre", 20.5],
			],
			"arriba": [
				["metalshelf", 2.0], ["tvshelf", 7.0], ["tvshelf", 11.0], ["checkout", 14.5], ["checkout", 22.0],
				["tvshelf", 27.0], ["tvshelf", 31.0], ["pallet", 34.5],
				["pallet", 3.0, "izquierda"], ["pallet", 7.75, "derecha"], ["pallet", 12.5, "abajo"], ["pallet", 16.5, "abajo"],
				["tvshelf", 23.3125, "libre", 5.0], ["tvshelf", 26.9375, "libre", 5.0], ["tvshelf", 30.5625, "libre", 5.0],
				["tvshelf", 23.3125, "libre", 10.5], ["tvshelf", 26.9375, "libre", 10.5], ["tvshelf", 30.5625, "libre", 10.5],
			],
		},
	},
	# las taquillas, el almacén (con sitio libre en su pared de arriba para el cuadro eléctrico: Peligros.cuadro_electrico)
	# y el aseo de empleados (M81) de la electrónica fija (M77)
	"taquillas-electronica": {"colocados": {
		"abajo": [["lockers", 1.75], ["lockers", 5.0], ["lockers", 8.25], ["bench", 4.5, "derecha"]],
		"arriba": [["lockers", 1.75], ["lockers", 8.25], ["bench", 4.5, "derecha"], ["bench", 4.5, "izquierda"]],
	}},
	"almacen-electronica": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["pallet", 7.5], ["pallet", 5.0, "izquierda"]],
		"arriba": [["metalshelf", 1.5], ["pallet", 4.5, "abajo"], ["pallet", 7.0, "abajo"], ["pallet", 4.0, "izquierda"]],
	}},
	"bano-electronica": {"colocados": {
		"abajo": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		"arriba": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
	}},
	# M77: el restaurante fijo (Tienda.PLANOS). Con la puerta abajo: neveras y una caja al fondo del trozo que llega hasta
	# atrás, bancos y neveras delante de la cocina y de la cámara, bancos en los lados y dos filas de tres mesas a cada
	# lado del pasillo de la entrada. Volteado, las neveras y las cajas, en la pared de la entrada
	"tienda-restaurante": {
		"colocados": {
			"abajo": [
				["drinkfridge", 22.5], ["drinkfridge", 24.5], ["checkout", 27.25],
				["bench", 4.0, "libre", 10.5625], ["bench", 9.0, "libre", 10.5625], ["drinkfridge", 18.0, "libre", 10.75],
				["drinkfridge", 31.5, "libre", 10.75], ["bench", 38.0, "libre", 10.5625],
				["bench", 15.0, "izquierda"], ["bench", 20.0, "izquierda"], ["bench", 15.0, "derecha"], ["bench", 20.0, "derecha"],
				["diningtable", 4.5, "libre", 14.5], ["diningtable", 8.75, "libre", 14.5], ["diningtable", 13.0, "libre", 14.5], ["diningtable", 25.5, "libre", 14.5], ["diningtable", 29.75, "libre", 14.5], ["diningtable", 34.0, "libre", 14.5],
				["diningtable", 4.5, "libre", 20.0], ["diningtable", 8.75, "libre", 20.0], ["diningtable", 13.0, "libre", 20.0], ["diningtable", 25.5, "libre", 20.0], ["diningtable", 29.75, "libre", 20.0], ["diningtable", 34.0, "libre", 20.0],
			],
			"arriba": [
				["drinkfridge", 1.5], ["drinkfridge", 3.5], ["checkout", 14.0], ["checkout", 25.0], ["drinkfridge", 36.5],
				["drinkfridge", 38.5],
				["bench", 6.5, "izquierda"], ["bench", 6.5, "derecha"], ["diningtable", 25.0, "libre", 21.0],
				["diningtable", 4.5, "libre", 5.0], ["diningtable", 8.75, "libre", 5.0], ["diningtable", 13.0, "libre", 5.0], ["diningtable", 25.5, "libre", 5.0], ["diningtable", 29.75, "libre", 5.0], ["diningtable", 34.0, "libre", 5.0],
				["diningtable", 4.5, "libre", 10.5], ["diningtable", 8.75, "libre", 10.5], ["diningtable", 13.0, "libre", 10.5], ["diningtable", 25.5, "libre", 10.5], ["diningtable", 29.75, "libre", 10.5], ["diningtable", 34.0, "libre", 10.5],
			],
		},
	},
	# la cocina (sus fogones y freidoras son los focos del fuego: Peligros.fuego), la cámara y el aseo de empleados (M81)
	# del restaurante fijo (M77)
	"cocina-restaurante": {
		"colocados": {
			"abajo": [["industrialstove", 1.75], ["fryer", 4.5], ["steeltable", 7.0], ["industrialstove", 10.25],
				["industrialstove", 4.5, "derecha"]],
			"arriba": [["industrialstove", 1.75], ["fryer", 3.6], ["steeltable", 8.5], ["fryer", 10.75],
				["industrialstove", 5.0, "derecha"]],
		},
	},
	"camara-restaurante": {"colocados": {
		"abajo": [["freezershelf", 1.5], ["freezershelf", 4.75], ["freezershelf", 8.0], ["pallet", 4.5, "derecha"]],
		"arriba": [["freezershelf", 1.75], ["freezershelf", 8.0], ["pallet", 4.75, "abajo"], ["pallet", 5.0, "derecha"]],
	}},
	"bano-restaurante": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# M77: la tienda de ropa fija (Tienda.PLANOS). Con la puerta abajo: un escaparate de tres maniquíes al fondo del trozo
	# que llega hasta atrás, un banco y percheros delante del almacén y de los probadores, dos cajas a la derecha, un banco
	# a la izquierda y dos filas de tres percheros y un maniquí a cada lado del pasillo de la entrada. Volteada, las cajas
	# a los lados de la entrada y los maniquíes del escaparate, en la pared del fondo del trozo
	"tienda-ropa": {
		"colocados": {
			"abajo": [
				["mannequin", 19.5], ["mannequin", 21.5], ["mannequin", 23.5],
				["bench", 4.0, "libre", 10.5625], ["clothesrack", 8.0, "libre", 10.5625],
				["clothesrack", 27.75, "libre", 10.5625], ["mannequin", 34.0, "libre", 10.4375],
				["checkout", 16.0, "derecha"], ["checkout", 20.0, "derecha"], ["bench", 18.0, "izquierda"],
				["clothesrack", 3.5, "libre", 15.0], ["clothesrack", 7.0, "libre", 15.0], ["clothesrack", 10.5, "libre", 15.0], ["mannequin", 13.5, "libre", 15.0],
				["mannequin", 21.5, "libre", 15.0], ["clothesrack", 25.0, "libre", 15.0], ["clothesrack", 28.5, "libre", 15.0], ["clothesrack", 32.0, "libre", 15.0],
				["clothesrack", 3.5, "libre", 20.5], ["clothesrack", 7.0, "libre", 20.5], ["clothesrack", 10.5, "libre", 20.5], ["mannequin", 13.5, "libre", 20.5],
				["mannequin", 21.5, "libre", 20.5], ["clothesrack", 25.0, "libre", 20.5], ["clothesrack", 28.5, "libre", 20.5], ["clothesrack", 32.0, "libre", 20.5],
			],
			"arriba": [
				["clothesrack", 3.0], ["clothesrack", 7.0], ["mannequin", 10.5], ["checkout", 14.5], ["checkout", 22.0],
				["mannequin", 25.5], ["clothesrack", 29.0], ["clothesrack", 33.0],
				["bench", 6.5, "izquierda"], ["bench", 6.5, "derecha"],
				["mannequin", 19.5, "abajo"], ["mannequin", 21.5, "abajo"], ["mannequin", 23.5, "abajo"],
				["clothesrack", 3.5, "libre", 5.0], ["clothesrack", 7.0, "libre", 5.0], ["clothesrack", 10.5, "libre", 5.0], ["mannequin", 13.5, "libre", 5.0],
				["mannequin", 21.5, "libre", 5.0], ["clothesrack", 25.0, "libre", 5.0], ["clothesrack", 28.5, "libre", 5.0], ["clothesrack", 32.0, "libre", 5.0],
				["clothesrack", 3.5, "libre", 10.5], ["clothesrack", 7.0, "libre", 10.5], ["clothesrack", 10.5, "libre", 10.5], ["mannequin", 13.5, "libre", 10.5],
				["mannequin", 21.5, "libre", 10.5], ["clothesrack", 25.0, "libre", 10.5], ["clothesrack", 28.5, "libre", 10.5], ["clothesrack", 32.0, "libre", 10.5],
			],
		},
	},
	# los probadores (bancos para sentarse, percheros y un maniquí), el almacén y el aseo de empleados (M81) de la tienda
	# de ropa fija (M77)
	"probadores-ropa": {"colocados": {
		"abajo": [["bench", 1.75], ["mannequin", 4.5], ["bench", 8.25], ["clothesrack", 4.5, "izquierda"],
			["clothesrack", 4.5, "derecha"]],
		"arriba": [["bench", 1.75], ["bench", 8.25], ["mannequin", 4.5, "abajo"], ["clothesrack", 4.5, "izquierda"],
			["clothesrack", 4.5, "derecha"]],
	}},
	"almacen-ropa": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["clothesrack", 4.75], ["pallet", 7.5], ["pallet", 4.5, "derecha"]],
		"arriba": [["metalshelf", 1.5], ["pallet", 7.5], ["pallet", 4.5, "derecha"], ["pallet", 4.5, "abajo"]],
	}},
	"bano-ropa": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	"tienda-farmacia": {
		# M77: la farmacia fija (Tienda.PLANOS). Con la puerta abajo: estanterías al fondo del trozo que llega hasta atrás y,
		# delante, el mostrador; estanterías y una nevera delante del aseo y de la rebotica, un banco a cada lado y dos filas
		# de tres estanterías a cada lado del pasillo de la entrada. Volteada, las neveras y las estanterías, en la pared de
		# la entrada, y el mostrador, en el trozo de abajo
		"colocados": {
			"abajo": [
				["metalshelf", 22.5], ["metalshelf", 25.25], ["metalshelf", 28.0], ["pharmacycounter", 25.25, "libre", 5.5],
				["metalshelf", 2.0, "libre", 10.625], ["drinkfridge", 6.0, "libre", 10.75], ["metalshelf", 18.0, "libre", 10.625],
				["bench", 18.0, "izquierda"], ["bench", 18.0, "derecha"],
				["metalshelf", 3.0, "libre", 15.0], ["metalshelf", 5.75, "libre", 15.0], ["metalshelf", 8.5, "libre", 15.0],
				["metalshelf", 20.5, "libre", 15.0], ["metalshelf", 23.25, "libre", 15.0], ["metalshelf", 26.0, "libre", 15.0],
				["metalshelf", 3.0, "libre", 20.5], ["metalshelf", 5.75, "libre", 20.5], ["metalshelf", 8.5, "libre", 20.5],
				["metalshelf", 20.5, "libre", 20.5], ["metalshelf", 23.25, "libre", 20.5], ["metalshelf", 26.0, "libre", 20.5],
			],
			"arriba": [
				["drinkfridge", 2.0], ["drinkfridge", 4.0], ["metalshelf", 8.0], ["metalshelf", 11.0],
				["metalshelf", 19.0], ["metalshelf", 22.0], ["metalshelf", 25.0], ["metalshelf", 28.0],
				["bench", 6.5, "izquierda"], ["bench", 6.5, "derecha"],
				["pharmacycounter", 25.25, "libre", 20.0], ["metalshelf", 22.75, "libre", 24.0], ["metalshelf", 27.75, "libre", 24.0],
				["metalshelf", 3.0, "libre", 5.0], ["metalshelf", 5.75, "libre", 5.0], ["metalshelf", 8.5, "libre", 5.0],
				["metalshelf", 20.5, "libre", 5.0], ["metalshelf", 23.25, "libre", 5.0], ["metalshelf", 26.0, "libre", 5.0],
				["metalshelf", 3.0, "libre", 10.5], ["metalshelf", 5.75, "libre", 10.5], ["metalshelf", 8.5, "libre", 10.5],
				["metalshelf", 20.5, "libre", 10.5], ["metalshelf", 23.25, "libre", 10.5], ["metalshelf", 26.0, "libre", 10.5],
			],
		},
	},
	# la rebotica (con sitio en medio para la farmacéutica) y el aseo de empleados (M81) de la farmacia fija (M77)
	"rebotica-farmacia": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["metalshelf", 4.25], ["metalshelf", 7.0], ["pallet", 10.25], ["pallet", 4.5, "derecha"],
			["pharmacycounter", 8.5, "libre", 5.0]],
		"arriba": [["metalshelf", 1.25], ["metalshelf", 3.5], ["pallet", 10.5], ["pallet", 4.5, "derecha"], ["pallet", 6.0, "abajo"],
			["pharmacycounter", 8.5, "libre", 5.0]],
	}},
	"bano-farmacia": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# la joyería (parte 9): vitrinas bajas en filas, vitrinas altas contra la pared; detrás, la trastienda (como un
	# almacén pequeño) y la cámara acorazada con sus cajas fuertes
	"tienda-joyeria": {
		# M77: la joyería fija (Tienda.PLANOS). Con la puerta abajo: vitrinas altas delante de la trastienda y de la cámara
		# acorazada (sin tapar su puerta), la caja a la derecha, un banco a la izquierda y dos filas de tres vitrinas a cada
		# lado del pasillo de la entrada. Volteada, las vitrinas altas en la pared de la entrada y las filas, más arriba, para
		# dejar sitio delante de la puerta de la cámara
		"colocados": {
			"abajo": [
				["jewelcabinet", 2.0, "libre", 0.5625], ["jewelcabinet", 5.5, "libre", 0.5625],
				["jewelcabinet", 21.0, "libre", 0.5625], ["jewelcabinet", 28.0, "libre", 0.5625],
				["checkout", 7.5, "derecha"], ["bench", 7.5, "izquierda"],
				["jewelcase", 2.75, "libre", 5.0], ["jewelcase", 6.5, "libre", 5.0], ["jewelcase", 10.25, "libre", 5.0],
				["jewelcase", 18.0, "libre", 5.0], ["jewelcase", 21.75, "libre", 5.0], ["jewelcase", 25.5, "libre", 5.0],
				["jewelcase", 2.75, "libre", 10.5], ["jewelcase", 6.5, "libre", 10.5], ["jewelcase", 10.25, "libre", 10.5],
				["jewelcase", 18.0, "libre", 10.5], ["jewelcase", 21.75, "libre", 10.5], ["jewelcase", 25.5, "libre", 10.5],
			],
			"arriba": [
				["jewelcabinet", 2.0], ["jewelcabinet", 5.0], ["jewelcabinet", 8.0], ["jewelcabinet", 11.0],
				["jewelcabinet", 19.0], ["jewelcabinet", 22.0], ["jewelcabinet", 25.0], ["jewelcabinet", 28.0],
				["checkout", 6.5, "derecha"], ["bench", 6.5, "izquierda"],
				["jewelcase", 2.75, "libre", 4.5], ["jewelcase", 6.5, "libre", 4.5], ["jewelcase", 10.25, "libre", 4.5],
				["jewelcase", 18.0, "libre", 4.5], ["jewelcase", 21.75, "libre", 4.5], ["jewelcase", 25.5, "libre", 4.5],
				["jewelcase", 2.75, "libre", 9.0], ["jewelcase", 6.5, "libre", 9.0], ["jewelcase", 10.25, "libre", 9.0],
				["jewelcase", 18.0, "libre", 9.0], ["jewelcase", 21.75, "libre", 9.0], ["jewelcase", 25.5, "libre", 9.0],
			],
		},
	},
	# la trastienda, la cámara acorazada (las cajas fuertes en el fondo y el centro libre, para la vitrina del premio:
	# joyeria.gd) y el aseo de empleados (M81) de la joyería fija (M77)
	"trastienda-joyeria": {"colocados": {
		"abajo": [["lockers", 1.75], ["metalshelf", 5.0], ["metalshelf", 8.25], ["workbench", 4.5, "derecha"]],
		"arriba": [["lockers", 1.75], ["metalshelf", 8.25], ["workbench", 4.5, "derecha"], ["pallet", 4.5, "abajo"]],
	}},
	"acorazada-joyeria": {"colocados": {
		"abajo": [["safe", 1.5], ["safe", 3.5], ["safe", 7.5], ["safe", 9.5]],
		"arriba": [["safe", 1.25], ["safe", 3.0], ["safe", 8.0], ["safe", 9.75]],
	}},
	"bano-joyeria": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# Los departamentos de Torre Velaria (parte 2 del tercer edificio): los muebles de oficina, en las casillas del
	# plano que les presta una tienda del centro (Tienda.TIPOS, "presta"). "<uso>-<tipo>", como las tiendas
	# Atención al cliente (plano del supermercado): impresoras, fotocopiadoras y fuentes de agua al fondo, filas de cubículos; el resto, como esa tienda (mismas casillas)
	"tienda-atencion": {
		"colocados": {
			"abajo": [
				["printer", 14.5], ["watercooler", 17.0], ["copier", 19.5],
				["filecabinet", 1.75, "libre", 10.875], ["filecabinet", 9.75, "libre", 10.625],
				["filecabinet", 23.5, "libre", 13.625], ["filecabinet", 30.5, "libre", 13.625],
				["filecabinet", 33.0, "libre", 13.625], ["filecabinet", 37.5, "libre", 13.875],
				["officedesk", 17.0, "izquierda"], ["officedesk", 21.0, "izquierda"],
				["watercooler", 18.0, "derecha"], ["watercooler", 22.0, "derecha"],
				["cubicle", 5.4375, "libre", 16.75], ["cubicle", 9.3125, "libre", 16.75], ["cubicle", 13.1875, "libre", 16.75],
				["cubicle", 26.4375, "libre", 16.75], ["cubicle", 30.3125, "libre", 16.75], ["cubicle", 34.1875, "libre", 16.75],
				["cubicle", 5.4375, "libre", 22.25], ["cubicle", 9.3125, "libre", 22.25], ["cubicle", 13.1875, "libre", 22.25],
				["cubicle", 26.4375, "libre", 22.25], ["cubicle", 30.3125, "libre", 22.25], ["cubicle", 34.1875, "libre", 22.25],
			],
			"arriba": [
				["printer", 2.0], ["watercooler", 4.0], ["copier", 6.0], ["filecabinet", 9.5],
				["officedesk", 15.0], ["officedesk", 25.0], ["filecabinet", 30.5], ["printer", 34.0], ["watercooler", 36.0],
				["watercooler", 6.0, "izquierda"], ["watercooler", 6.0, "derecha"], ["plant", 15.0, "abajo"], ["plant", 19.0, "abajo"],
				["cubicle", 5.4375, "libre", 4.5], ["cubicle", 9.3125, "libre", 4.5], ["cubicle", 13.1875, "libre", 4.5],
				["cubicle", 26.4375, "libre", 4.5], ["cubicle", 30.3125, "libre", 4.5], ["cubicle", 34.1875, "libre", 4.5],
				["cubicle", 5.4375, "libre", 9.5], ["cubicle", 9.3125, "libre", 9.5], ["cubicle", 13.1875, "libre", 9.5],
				["cubicle", 26.4375, "libre", 9.5], ["cubicle", 30.3125, "libre", 9.5], ["cubicle", 34.1875, "libre", 9.5],
			],
		},
	},
	"impresoras-atencion": {"colocados": {
		"abajo": [["copier", 1.75], ["printer", 6.0], ["copier", 10.25], ["plant", 4.5, "derecha"]],
		"arriba": [["copier", 1.75], ["printer", 9.25], ["plant", 5.0, "derecha"], ["plant", 6.0, "abajo"]],
	}},
	"office-atencion": {"colocados": {
		"abajo": [["officekitchen", 1.5], ["filecabinet", 4.0], ["drinkfridge", 8.0], ["watercooler", 6.0, "izquierda"]],
		"arriba": [["officekitchen", 1.5], ["drinkfridge", 8.5], ["watercooler", 7.0, "izquierda"], ["watercooler", 3.0, "abajo"]],
	}},
	"bano-atencion": {"colocados": {
		"abajo": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		"arriba": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
	}},
	# Informática (plano de la electrónica): racks de servidores en la pared y filas de escritorios; el resto, como esa tienda (mismas casillas)
	"tienda-informatica": {
		"colocados": {
			"abajo": [
				["serverrack", 14.5],
				["filecabinet", 2.0, "libre", 10.625], ["watercooler", 8.75, "libre", 10.875],
				["serverrack", 20.0, "libre", 10.625], ["serverrack", 27.0, "libre", 10.625], ["serverrack", 31.0, "libre", 10.625],
				["watercooler", 34.5, "libre", 10.875],
				["watercooler", 21.5, "izquierda"], ["officedesk", 16.0, "derecha"], ["officedesk", 20.0, "derecha"],
				["watercooler", 2.0, "abajo"], ["watercooler", 33.5, "abajo"],
				["serverrack", 23.3125, "libre", 15.0], ["serverrack", 26.9375, "libre", 15.0], ["serverrack", 30.5625, "libre", 15.0],
				["serverrack", 23.3125, "libre", 20.5], ["serverrack", 26.9375, "libre", 20.5], ["serverrack", 30.5625, "libre", 20.5],
			],
			"arriba": [
				["filecabinet", 2.0], ["serverrack", 7.0], ["serverrack", 11.0], ["officedesk", 14.5], ["officedesk", 22.0],
				["serverrack", 27.0], ["serverrack", 31.0], ["watercooler", 34.5],
				["watercooler", 3.0, "izquierda"], ["watercooler", 7.75, "derecha"], ["watercooler", 12.5, "abajo"], ["watercooler", 16.5, "abajo"],
				["serverrack", 23.3125, "libre", 5.0], ["serverrack", 26.9375, "libre", 5.0], ["serverrack", 30.5625, "libre", 5.0],
				["serverrack", 23.3125, "libre", 10.5], ["serverrack", 26.9375, "libre", 10.5], ["serverrack", 30.5625, "libre", 10.5],
			],
		},
	},
	"servidores-informatica": {"colocados": {
		"abajo": [["serverrack", 1.75], ["serverrack", 5.0], ["serverrack", 8.25], ["watercooler", 4.5, "derecha"]],
		"arriba": [["serverrack", 1.75], ["serverrack", 8.25], ["watercooler", 4.5, "derecha"], ["watercooler", 4.5, "izquierda"]],
	}},
	"almacen-informatica": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["pallet", 7.5], ["pallet", 5.0, "izquierda"]],
		"arriba": [["metalshelf", 1.5], ["pallet", 4.5, "abajo"], ["pallet", 7.0, "abajo"], ["pallet", 4.0, "izquierda"]],
	}},
	"bano-informatica": {"colocados": {
		"abajo": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		"arriba": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
	}},
	# Recursos Humanos (plano de la tienda de ropa): cubículos, sofás de espera y plantas; el resto, como esa tienda (mismas casillas)
	"tienda-rrhh": {
		"colocados": {
			"abajo": [
				["plant", 19.5], ["watercooler", 21.5], ["plant", 23.5],
				["lobbysofa", 4.0, "libre", 10.5625], ["cubicle", 8.0, "libre", 10.5625],
				["cubicle", 27.75, "libre", 10.5625], ["plant", 34.0, "libre", 10.4375],
				["officedesk", 16.0, "derecha"], ["officedesk", 20.0, "derecha"], ["lobbysofa", 18.0, "izquierda"],
				["cubicle", 3.5, "libre", 15.0], ["cubicle", 7.0, "libre", 15.0], ["cubicle", 10.5, "libre", 15.0], ["watercooler", 13.5, "libre", 15.0],
				["plant", 21.5, "libre", 15.0], ["cubicle", 25.0, "libre", 15.0], ["cubicle", 28.5, "libre", 15.0], ["cubicle", 32.0, "libre", 15.0],
				["cubicle", 3.5, "libre", 20.5], ["cubicle", 7.0, "libre", 20.5], ["cubicle", 10.5, "libre", 20.5], ["plant", 13.5, "libre", 20.5],
				["watercooler", 21.5, "libre", 20.5], ["cubicle", 25.0, "libre", 20.5], ["cubicle", 28.5, "libre", 20.5], ["cubicle", 32.0, "libre", 20.5],
			],
			"arriba": [
				["cubicle", 3.0], ["cubicle", 7.0], ["plant", 10.5], ["officedesk", 14.5], ["officedesk", 22.0],
				["plant", 25.5], ["cubicle", 29.0], ["cubicle", 33.0],
				["lobbysofa", 6.5, "izquierda"], ["lobbysofa", 6.5, "derecha"],
				["watercooler", 19.5, "abajo"], ["plant", 21.5, "abajo"], ["plant", 23.5, "abajo"],
				["cubicle", 3.5, "libre", 5.0], ["cubicle", 7.0, "libre", 5.0], ["cubicle", 10.5, "libre", 5.0], ["watercooler", 13.5, "libre", 5.0],
				["plant", 21.5, "libre", 5.0], ["cubicle", 25.0, "libre", 5.0], ["cubicle", 28.5, "libre", 5.0], ["cubicle", 32.0, "libre", 5.0],
				["cubicle", 3.5, "libre", 10.5], ["cubicle", 7.0, "libre", 10.5], ["cubicle", 10.5, "libre", 10.5], ["plant", 13.5, "libre", 10.5],
				["watercooler", 21.5, "libre", 10.5], ["cubicle", 25.0, "libre", 10.5], ["cubicle", 28.5, "libre", 10.5], ["cubicle", 32.0, "libre", 10.5],
			],
		},
	},
	"archivo-rrhh": {"colocados": {
		"abajo": [["filecabinet", 1.5], ["bookcase", 4.75], ["filecabinet", 7.5], ["watercooler", 4.5, "derecha"]],
		"arriba": [["filecabinet", 1.5], ["filecabinet", 7.5], ["watercooler", 4.5, "derecha"], ["plant", 4.5, "abajo"]],
	}},
	"entrevistas-rrhh": {"colocados": {
		"abajo": [["interviewtable", 1.75], ["watercooler", 4.5], ["interviewtable", 8.25], ["lobbysofa", 4.5, "izquierda"],
			["lobbysofa", 4.5, "derecha"]],
		"arriba": [["interviewtable", 1.75], ["interviewtable", 8.25], ["watercooler", 4.5, "abajo"], ["lobbysofa", 4.5, "izquierda"],
			["lobbysofa", 4.5, "derecha"]],
	}},
	"bano-rrhh": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# Marketing (plano de la ferretería): cubículos creativos en filas y escritorios; el resto, como esa tienda (mismas casillas)
	"tienda-marketing": {
		"colocados": {
			"abajo": [
				["cubicle", 20.5],
				["officedesk", 3.0, "libre", 10.75], ["plant", 16.0, "libre", 10.875],
				["cubicle", 25.0, "libre", 10.625], ["plant", 33.5, "libre", 10.875],
				["plant", 16.0, "izquierda"], ["plant", 20.0, "izquierda"],
				["officedesk", 16.0, "derecha"], ["officedesk", 20.0, "derecha"],
				["plant", 3.0, "abajo"], ["plant", 33.0, "abajo"],
				["cubicle", 7.25, "libre", 14.0], ["cubicle", 12.25, "libre", 14.0], ["cubicle", 26.25, "libre", 14.0], ["cubicle", 31.25, "libre", 14.0],
				["cubicle", 7.25, "libre", 19.5], ["cubicle", 12.25, "libre", 19.5], ["cubicle", 26.25, "libre", 19.5], ["cubicle", 31.25, "libre", 19.5],
			],
			"arriba": [
				["cubicle", 4.5], ["officedesk", 12.0], ["officedesk", 23.5], 
				["cubicle", 30.5], ["plant", 34.0],
				["plant", 6.0, "izquierda"], ["plant", 7.0, "derecha"], ["plant", 19.25, "abajo"], ["plant", 21.75, "abajo"],
				["cubicle", 7.25, "libre", 4.5], ["cubicle", 12.25, "libre", 4.5], ["cubicle", 26.25, "libre", 4.5], ["cubicle", 31.25, "libre", 4.5],
				["cubicle", 7.25, "libre", 9.5], ["cubicle", 12.25, "libre", 9.5], ["cubicle", 26.25, "libre", 9.5], ["cubicle", 31.25, "libre", 9.5],
			],
		},
	},
	"estudio-marketing": {"colocados": {
		"abajo": [["mixerdesk", 2.0], ["lobbysofa", 6.0], ["officedesk", 10.0], ["plant", 4.5, "derecha"]],
		"arriba": [["mixerdesk", 2.0], ["lobbysofa", 8.0], ["plant", 5.0, "derecha"], ["plant", 9.5, "abajo"]],
	}},
	"almacen-marketing": {"colocados": {
		"abajo": [["metalshelf", 1.5], ["metalshelf", 4.0], ["pallet", 7.5]],
		"arriba": [["metalshelf", 1.5], ["pallet", 7.75], ["pallet", 4.5, "abajo"]],
	}},
	"bano-marketing": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# Seguridad corporativa (plano del restaurante): filas de escritorios, archivadores y sofás; el resto, como esa tienda (mismas casillas)
	"tienda-seguridad": {
		"colocados": {
			"abajo": [
				["filecabinet", 22.5], ["filecabinet", 24.5], ["officedesk", 27.25],
				["lobbysofa", 4.0, "libre", 10.5625], ["lobbysofa", 9.0, "libre", 10.5625], ["filecabinet", 18.0, "libre", 10.75],
				["filecabinet", 31.5, "libre", 10.75], ["lobbysofa", 38.0, "libre", 10.5625],
				["lobbysofa", 15.0, "izquierda"], ["lobbysofa", 20.0, "izquierda"], ["lobbysofa", 15.0, "derecha"], ["lobbysofa", 20.0, "derecha"],
				["officedesk", 4.5, "libre", 14.5], ["officedesk", 8.75, "libre", 14.5], ["officedesk", 13.0, "libre", 14.5], ["officedesk", 25.5, "libre", 14.5], ["officedesk", 29.75, "libre", 14.5], ["officedesk", 34.0, "libre", 14.5],
				["officedesk", 4.5, "libre", 20.0], ["officedesk", 8.75, "libre", 20.0], ["officedesk", 13.0, "libre", 20.0], ["officedesk", 25.5, "libre", 20.0], ["officedesk", 29.75, "libre", 20.0], ["officedesk", 34.0, "libre", 20.0],
			],
			"arriba": [
				["filecabinet", 1.5], ["filecabinet", 3.5], ["officedesk", 14.0], ["officedesk", 25.0], ["filecabinet", 36.5],
				["filecabinet", 38.5],
				["lobbysofa", 6.5, "izquierda"], ["lobbysofa", 6.5, "derecha"], ["officedesk", 25.0, "libre", 21.0],
				["officedesk", 4.5, "libre", 5.0], ["officedesk", 8.75, "libre", 5.0], ["officedesk", 13.0, "libre", 5.0], ["officedesk", 25.5, "libre", 5.0], ["officedesk", 29.75, "libre", 5.0], ["officedesk", 34.0, "libre", 5.0],
				["officedesk", 4.5, "libre", 10.5], ["officedesk", 8.75, "libre", 10.5], ["officedesk", 13.0, "libre", 10.5], ["officedesk", 25.5, "libre", 10.5], ["officedesk", 29.75, "libre", 10.5], ["officedesk", 34.0, "libre", 10.5],
			],
		},
	},
	"camaras-seguridad": {
		"colocados": {
			"abajo": [["monitorwall", 1.75], ["serverrack", 4.5], ["officedesk", 7.0], ["officedesk", 10.25],
				["watercooler", 4.5, "derecha"]],
			"arriba": [["officedesk", 1.75], ["serverrack", 3.6], ["officedesk", 8.5], ["serverrack", 10.75],
				["watercooler", 5.0, "derecha"]],
		},
	},
	"armero-seguridad": {"colocados": {
		"abajo": [["armory", 1.5], ["armory", 4.75], ["armory", 8.0], ["pallet", 4.5, "derecha"]],
		"arriba": [["armory", 1.75], ["armory", 8.0], ["pallet", 4.75, "abajo"], ["pallet", 5.0, "derecha"]],
	}},
	"bano-seguridad": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# Dirección (plano de la tienda de ropa): mesas de dirección, sofás y plantas; el resto, como esa tienda (mismas casillas)
	"tienda-direccion": {
		"colocados": {
			"abajo": [
				["plant", 19.5], ["plant", 21.5], ["plant", 23.5],
				["lobbysofa", 4.0, "libre", 10.5625], ["execdesk", 8.0, "libre", 10.5625],
				["execdesk", 27.75, "libre", 10.5625], ["plant", 34.0, "libre", 10.4375],
				["execdesk", 16.0, "derecha"], ["execdesk", 20.0, "derecha"], ["lobbysofa", 18.0, "izquierda"],
				["execdesk", 3.5, "libre", 15.0], ["execdesk", 7.0, "libre", 15.0], ["execdesk", 10.5, "libre", 15.0], ["plant", 13.5, "libre", 15.0],
				["plant", 21.5, "libre", 15.0], ["execdesk", 25.0, "libre", 15.0], ["execdesk", 28.5, "libre", 15.0], ["execdesk", 32.0, "libre", 15.0],
				["execdesk", 3.5, "libre", 20.5], ["execdesk", 7.0, "libre", 20.5], ["execdesk", 10.5, "libre", 20.5], ["plant", 13.5, "libre", 20.5],
				["plant", 21.5, "libre", 20.5], ["execdesk", 25.0, "libre", 20.5], ["execdesk", 28.5, "libre", 20.5], ["execdesk", 32.0, "libre", 20.5],
			],
			"arriba": [
				["execdesk", 3.0], ["execdesk", 7.0], ["plant", 10.5], ["execdesk", 14.5], ["execdesk", 22.0],
				["plant", 25.5], ["execdesk", 29.0], ["execdesk", 33.0],
				["lobbysofa", 6.5, "izquierda"], ["lobbysofa", 6.5, "derecha"],
				["plant", 19.5, "abajo"], ["plant", 21.5, "abajo"], ["plant", 23.5, "abajo"],
				["execdesk", 3.5, "libre", 5.0], ["execdesk", 7.0, "libre", 5.0], ["execdesk", 10.5, "libre", 5.0], ["plant", 13.5, "libre", 5.0],
				["plant", 21.5, "libre", 5.0], ["execdesk", 25.0, "libre", 5.0], ["execdesk", 28.5, "libre", 5.0], ["execdesk", 32.0, "libre", 5.0],
				["execdesk", 3.5, "libre", 10.5], ["execdesk", 7.0, "libre", 10.5], ["execdesk", 10.5, "libre", 10.5], ["plant", 13.5, "libre", 10.5],
				["plant", 21.5, "libre", 10.5], ["execdesk", 25.0, "libre", 10.5], ["execdesk", 28.5, "libre", 10.5], ["execdesk", 32.0, "libre", 10.5],
			],
		},
	},
	"despacho-direccion": {"colocados": {
		"abajo": [["bookcase", 1.5], ["execdesk", 4.75], ["filecabinet", 7.5], ["watercooler", 4.5, "derecha"]],
		"arriba": [["bookcase", 1.5], ["filecabinet", 7.5], ["watercooler", 4.5, "derecha"], ["plant", 4.5, "abajo"]],
	}},
	"juntas-direccion": {"colocados": {
		"abajo": [["bookcase", 1.75], ["boardtable", 4.5], ["bookcase", 8.25], ["watercooler", 4.5, "izquierda"],
			["watercooler", 4.5, "derecha"]],
		"arriba": [["bookcase", 1.75], ["bookcase", 8.25], ["plant", 4.5, "abajo"], ["watercooler", 4.5, "izquierda"],
			["watercooler", 4.5, "derecha"]],
	}},
	"bano-direccion": {"colocados": {
		"abajo": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		"arriba": [["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
	}},
	# la tienda destrozada del jefe de la planta
	"jefe-tienda": {
		"muebles": ["gondola", "metalshelf", "pallet", "checkout", "mannequin"],
		"cuantos": [2, 3],
	},
	# la Cocina central del cocinero (minijefe; planta.gd pone apt.tipo = "cocinero"): tres muebles que rebosan aceite
	# hirviendo en cada pared (M82, cocinero.gd), siempre en el mismo sitio (muebles.gd, fijos): en el fondo, dos
	# freidoras y un fogón industrial, con dos mesas de acero entre medias (no sueltan nada); a cada lado, tres fogones
	# (las freidoras no tienen dibujo de lado). La pared de abajo, vacía (ahí está la puerta)
	"jefe-cocinero": {
		"muebles": [],
		"cuantos": [0, 0],
		"fijos": {
			"arriba": ["fryer", "steeltable", "industrialstove", "steeltable", "fryer"],
			"izquierda": ["industrialstove", "industrialstove", "industrialstove"],
			"derecha": ["industrialstove", "industrialstove", "industrialstove"],
		},
	},
	# el Despacho de Recursos Humanos de la directora (minijefa de Torre Velaria; planta.gd pone apt.tipo = "directora"):
	# siempre los mismos muebles en el mismo sitio (muebles.gd, fijos), todos de la torre: en el fondo, los archivadores,
	# las librerías y en medio su mesa de dirección (con una lámpara a cada lado, para que siempre haya luz); a cada lado,
	# la sala de espera (dos sofás, la fuente de agua y plantas). El medio, libre para la pelea; la pared de abajo, vacía
	# (ahí está la puerta)
	"jefe-directora": {
		"muebles": [],
		"cuantos": [0, 0],
		"fijos": {
			"arriba": ["filecabinet", "bookcase", "lamp", "execdesk", "lamp", "bookcase", "filecabinet"],
			"izquierda": ["plant", "lobbysofa", "watercooler", "lobbysofa", "plant"],
			"derecha": ["plant", "lobbysofa", "watercooler", "lobbysofa", "plant"],
		},
	},
	# el Centro de datos del informático (minijefe de Torre Velaria; planta.gd pone apt.tipo = "informatico"): en el fondo, una
	# pared de armarios de servidores (con dos lámparas, para que haya algo de luz) y, en medio, filas de armarios sueltos con
	# pasillos entre ellas (muebles.gd, islas), detrás de los que esconderse de los teclados. Sus lucecitas parpadean y lucen
	# también a oscuras (informatico.gd, pintar_lucecitas): con el apagón, lo único que se ve además de la linterna
	"jefe-informatico": {
		"muebles": [],
		"cuantos": [0, 0],
		"fijos": {
			"arriba": ["serverrack", "serverrack", "lamp", "serverrack", "serverrack", "watercooler", "serverrack", "serverrack",
				"lamp", "serverrack", "serverrack"],
		},
		"islas": {"muebles": ["serverrack"], "fila": 3, "entre": 0, "cada": 230},
	},
	# el Plató de presentaciones del presentador (minijefe de Torre Velaria): en el fondo, el escenario, con la pantalla
	# gigante, el atril y dos focos de pie (los de su ataque: presentador.gd) y, en el resto, filas de butacas vistas de
	# espaldas, con pasillos entre ellas, con el público de zombis sentado (lo sienta él al llegar)
	"jefe-presentador": {
		"muebles": [],
		"cuantos": [0, 0],
		"fijos": {
			"arriba": ["spotlight", "lamp", "lectern", "stagescreen", "lamp", "spotlight"],
		},
		"islas": {"muebles": ["theaterseats"], "fila": 2, "entre": 0, "cada": 150, "arriba": 170.0},
	},
	# la Sala de fotocopias del becario (minijefe de Torre Velaria): en el fondo, tres fotocopiadoras (las de su ataque:
	# corre a la más cercana y saca sus copias, becario.gd) con impresoras, archivadores y dos lámparas; a los lados, fuentes
	# de agua y plantas, y en medio dos filas de escritorios con pasillos, detrás de los que esconderse del carrito
	"jefe-becario": {
		"muebles": [],
		"cuantos": [0, 0],
		"fijos": {
			"arriba": ["copier", "printer", "lamp", "filecabinet", "copier", "filecabinet", "lamp", "printer", "copier"],
			"izquierda": ["plant", "watercooler", "plant"],
			"derecha": ["plant", "watercooler", "plant"],
		},
		"islas": {"muebles": ["officedesk"], "fila": 2, "entre": 120, "cada": 230, "arriba": 150.0},
	},
	# el Taller de costura de la modista (minijefa): lleno de maniquíes de cuerpo entero, entre los que se esconde
	"jefe-modista": {
		"muebles": ["tallmannequin", "clothesrack", "tallmannequin", "checkout"],
		"cuantos": [4, 6],
		"iguales": {"tallmannequin": 6, "clothesrack": 2},
		"islas": {"muebles": ["tallmannequin"], "fila": 2, "entre": 80, "cada": 230},
	},
	# el pasillo del centro comercial
	"galeria": {
		# M77: puestos a mano, iguales en todas las plantas (Planta.generar); casillas desde la esquina del suelo (la 2,2 de
		# la galería). Las puertas de las tiendas están siempre en las casillas 14 y 42 (12 y 40 desde aquí), arriba y
		# abajo, y el ascensor en la 28 (26), con su cartel a la izquierda; los escaparates, a cada lado de las puertas de
		# arriba, solo salen en algunas plantas (no junto a la sala de mantenimiento ni en la tienda de un minijefe), pero
		# su sitio se deja libre siempre. En el centro, nada: por ahí se va de una punta a la otra
		"colocados": {"abajo": [
			["plant", 1.0], ["bench", 4.5], ["bench", 19.5], ["bench", 30.0], ["mannequin", 33.5], ["bench", 47.5], ["plant", 51.0],
			["plant", 1.0, "abajo"], ["plant", 19.0, "abajo"], ["mannequin", 26.0, "abajo"], ["plant", 33.0, "abajo"],
			["plant", 51.0, "abajo"],
		]},
	},
	# Los pasillos de Torre Velaria (tercer edificio), puestos a mano como la galería (mismas casillas: las puertas de los
	# departamentos, en la 12 y la 40; el ascensor, en la 26, con su cartel a la izquierda, en la 22-24): el distribuidor de
	# oficina de las plantas 10 a 40, con fuentes de agua, sofás y plantas; y el vestíbulo de la planta baja (que no tiene la
	# puerta de la 12), con la recepción, la maqueta de la torre y los tornos de acceso
	"torre": {
		"colocados": {"abajo": [
			["plant", 1.0], ["watercooler", 5.0], ["lobbysofa", 18.5], ["plant", 21.5], ["watercooler", 30.0], ["lobbysofa", 34.0],
			["plant", 37.5], ["lobbysofa", 47.5], ["plant", 51.0],
			["plant", 1.0, "abajo"], ["watercooler", 19.0, "abajo"], ["plant", 26.0, "abajo"], ["watercooler", 33.0, "abajo"],
			["plant", 51.0, "abajo"],
		]},
	},
	"vestibulo": {
		"colocados": {"abajo": [
			["plant", 1.0], ["lobbysofa", 5.0], ["reception", 18.5], ["towermodel", 31.5], ["turnstile", 35.0], ["turnstile", 36.9],
			["lobbysofa", 47.5], ["plant", 51.0],
			["plant", 1.0, "abajo"], ["watercooler", 19.0, "abajo"], ["plant", 26.0, "abajo"], ["watercooler", 33.0, "abajo"],
			["plant", 51.0, "abajo"],
		]},
	},
	# Las viviendas de los supervivientes rescatados (viviendas.gd): el pasillo y la habitación de cada uno
	# ("habitacion-<id>"; "habitacion", la de quien no tenga la suya). Sin muebles sueltos: solo los "colocados" (la
	# entrada de las viviendas es "izquierda"). Cada habitación es un trastero: un colchón en el suelo en la esquina de arriba a
	# la derecha (donde estaba la cama), con la colcha del color de cada uno, para distinguir las habitaciones, y en la de
	# arriba a la izquierda una estantería metálica vacía, algo separada de ella (el centro, en la casilla 2,5)
	# El pasillo, el de una zona de trasteros: cajas de cartón y alguna carretilla contra la pared de arriba (la de abajo
	# queda detrás de la cara del tabique), lejos de las puertas de las habitaciones (en las casillas 5 y 6, 18 y 19, 31 y 32
	# del pasillo) y de la entrada, a la izquierda; a la izquierda de la primera puerta de arriba no hay nada: allí va el
	# cartel de «TRASTEROS» (mapa.gd). La carretilla de la derecha, contra el final del pasillo (que acaba en la casilla 38)
	"pasillo-viviendas": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["handtruck", 10.0], ["boxpile", 14.5],
		["boxstack", 24.5], ["boxpile", 26.6], ["handtruck", 36.5]]}},
	"habitacion": {"muebles": [], "cuantos": [0, 0]},
	"habitacion-policia": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_policia", 10.6]]}},
	"habitacion-medico": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_medico", 10.6]]}},
	"habitacion-militar": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_militar", 10.6]]}},
	"habitacion-ferretero": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_ferretero", 10.6]]}},
	"habitacion-farmaceutica": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_farmaceutica", 10.6]]}},
	"habitacion-tecnico": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_tecnico", 10.6]]}},
	"habitacion-programador": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_programador", 10.6]]}},
	"habitacion-recepcionista": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_recepcionista", 10.6]]}},
	"habitacion-limpiadora": {"muebles": [], "cuantos": [0, 0], "colocados": {"izquierda": [["storageshelf", 2.5], ["mattress_limpiadora", 10.6]]}},
}
