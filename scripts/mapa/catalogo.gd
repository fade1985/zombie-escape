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
#   choque_lado  (opcional) en las paredes de los lados, lo alto de su choque si es menos que "len" (lo que mide su dibujo
#            de lado), pegado a su pie: así no queda un muro invisible por encima del dibujo (mueble.gd)
const MUEBLES := {
	"sofa":       {"len": 132, "dep": 60,  "paredes": "lados", "archivo": "salon/sofa"},
	# el sofá visto por detrás (girado 180° por PixelLab a partir del de frente), para ponerlo de cara a la tele, en medio del salón
	"sofaback":   {"len": 132, "dep": 60,  "paredes": "",      "archivo": "salon/sofa-espalda"},
	"tv":         {"len": 64,  "dep": 40,  "paredes": "",      "archivo": "salon/tele"},
	"armchair":   {"len": 90,  "dep": 60,  "paredes": "lados", "archivo": "salon/sillon"},
	"bookshelf":  {"len": 42,  "dep": 34,  "paredes": "",      "archivo": "salon/estanteria"},
	"lamp":       {"len": 30,  "dep": 30,  "paredes": "todas", "archivo": "comun/lampara"},
	"counter":    {"len": 158, "dep": 50,  "paredes": "",      "archivo": "cocina/encimera"},
	"fridge":     {"len": 44,  "dep": 58,  "paredes": "",      "archivo": "cocina/nevera"},
	"stove":      {"len": 56,  "dep": 50,  "paredes": "",      "archivo": "cocina/fogon"},
	# la mesa de la cocina con sus dos sillas, una a cada lado (un solo dibujo: van siempre juntas)
	"kitchentable": {"len": 112, "dep": 54, "paredes": "",     "archivo": "cocina/mesa"},
	# el dormitorio rehecho de frente (PixelLab, con las guías de tools/guias_dormitorio.py): la cama de matrimonio y la
	# individual, con el cabecero contra la pared y los pies abajo. La cama de matrimonio y la mesilla (con su lamparita)
	# tienen también dibujo de lado (cama-matrimonio-lado y mesilla-lado: PixelLab los giró a partir de los de frente)
	# (de lado, su dibujo mide 96 de alto y no 114: con todo "len", chocaba 18 por encima de la cama, junto a la mesilla de
	# arriba, y no dejaba arrimarse ni rodearla; F23, 16 nov, en el Bajo D)
	"doublebed":  {"len": 114, "dep": 140, "paredes": "lados", "archivo": "dormitorio/cama-matrimonio", "choque_lado": 96},
	"bed":        {"len": 62,  "dep": 140, "paredes": "lados", "archivo": "dormitorio/cama"},
	# lo de las habitaciones de los supervivientes (viviendas.gd), que son trasteros: un colchón en el suelo, con la almohada
	# descolocada y la colcha del color de cada uno (de GPT, tools/muebles_gpt.py; los colores, de
	# tools/camas_viviendas.py), y una estantería metálica vacía (de GPT, tools/muebles_gpt.py)
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
	# de mano cargada con dos cajas (de GPT, tools/muebles_gpt.py)
	"boxstack":  {"len": 64, "dep": 36, "paredes": "", "archivo": "viviendas/cajas-pila"},
	# (19 nov) los mismos montones de cajas, en el almacén de la tienda de ropa: estos se abren (Objetos.MUEBLES_CON_PIEZA) y los de los trasteros, no
	"cajasropa": {"len": 64, "dep": 36, "paredes": "", "archivo": "ropa/cajas-destrozadas-gpt"},
	# (19 nov, el dueño: «todas igual queda raro») y cuatro montones más, cada uno destrozado de otra forma: uno distinto en cada sitio
	"cajasropa2": {"len": 64, "dep": 36, "paredes": "", "archivo": "ropa/cajas-destrozadas2-gpt"},
	"cajasropa3": {"len": 64, "dep": 36, "paredes": "", "archivo": "ropa/cajas-destrozadas3-gpt"},
	"cajasropa4": {"len": 64, "dep": 36, "paredes": "", "archivo": "ropa/cajas-destrozadas4-gpt"},
	"cajasropa5": {"len": 64, "dep": 36, "paredes": "", "archivo": "ropa/cajas-destrozadas5-gpt"},
	"boxpile":   {"len": 56, "dep": 32, "paredes": "", "archivo": "viviendas/cajas-bajas"},
	"handtruck": {"len": 40, "dep": 28, "paredes": "", "archivo": "viviendas/carretilla"},
	# (19 nov, el dueño) la misma carretilla, destrozada, en el almacén de la tienda de ropa
	"carretillaropa": {"len": 40, "dep": 28, "paredes": "", "archivo": "ropa/carretilla-destrozada-gpt"},
	"wardrobe":   {"len": 78,  "dep": 44,  "paredes": "",      "archivo": "dormitorio/armario"},
	"nightstand": {"len": 34,  "dep": 36,  "paredes": "lados", "archivo": "dormitorio/mesilla"},
	"desk":       {"len": 92,  "dep": 50,  "paredes": "",      "archivo": "dormitorio/escritorio"},
	"shoerack":   {"len": 74,  "dep": 34,  "paredes": "",      "archivo": "pasillo/zapatero"},
	"coatstand":  {"len": 36,  "dep": 30,  "paredes": "todas", "archivo": "pasillo/perchero"},
	"console":    {"len": 68,  "dep": 34,  "paredes": "",      "archivo": "pasillo/consola"},
	"bathtub":    {"len": 116, "dep": 60,  "paredes": "lados", "archivo": "bano/banera"},
	"toilet":     {"len": 52,  "dep": 58,  "paredes": "lados", "archivo": "bano/vater"},
	"sink":       {"len": 64,  "dep": 46,  "paredes": "",      "archivo": "bano/lavabo"},
	"washer":     {"len": 46,  "dep": 50,  "paredes": "",      "archivo": "bano/lavadora"},
	"plant":      {"len": 40,  "dep": 36,  "paredes": "todas", "archivo": "comun/planta"},
	# la del pasillo de los Apartamentos, de GPT (tools/muebles_gpt.py): un ficus mustio en su maceta de barro
	"plantapasillo": {"len": 48, "dep": 36, "paredes": "todas", "archivo": "planta-pasillo-gpt"},
	# la de la galería del centro comercial, de GPT (tools/muebles_gpt.py): una palmera en su maceta alta de piedra blanca
	"palmera":    {"len": 84,  "dep": 36,  "paredes": "todas", "archivo": "palmera-gpt"},
	# y su banco, de GPT (tools/muebles_gpt.py): de acero inoxidable con listones de madera, en medio del pasillo (17 nov)
	"bancogaleria": {"len": 96, "dep": 36,  "paredes": "",      "archivo": "banco-galeria-gpt"},
	# el espejo de arco de los probadores de la tienda de ropa, de GPT (tools/muebles_gpt.py; 18 nov, el dueño): en la pared de arriba
	"espejoprobador": {"len": 72, "dep": 6,  "paredes": "todas", "archivo": "ropa/espejo-probador-gpt"},
	# y su puf redondo blanco, de GPT (tools/muebles_gpt.py): en la esquina de arriba a la izquierda de cada probador
	"pufprobador": {"len": 36, "dep": 30, "paredes": "todas", "archivo": "ropa/puf-probador-gpt"},
	# y su gancho doble cromado, de GPT (tools/muebles_gpt.py): de perfil (solo tiene dibujo de lado), en la pared derecha de cada probador
	"ganchoprobador": {"len": 16, "dep": 6, "paredes": "lados", "archivo": "ropa/perchero-probador-gpt"},
	# el aseo de la tienda de ropa: la taquilla, el lavabo, el váter y el banco del vestuario de Johnny, destrozados como el almacén
	# (19 nov, GPT, tools/muebles_gpt.py); tipos propios, para que el vestuario de la sala de mantenimiento y los baños de los pisos sigan igual
	"taquillaropa": {"len": 56, "dep": 36, "paredes": "", "archivo": "ropa/taquilla-destrozada-gpt"},
	"staffsinkropa": {"len": 52, "dep": 40, "paredes": "lados", "archivo": "ropa/lavabo-destrozado-gpt"},
	"stafftoiletropa": {"len": 40, "dep": 52, "paredes": "lados", "archivo": "ropa/vater-destrozado-gpt"},
	"lockerbenchropa": {"len": 128, "dep": 28, "paredes": "todas", "archivo": "ropa/banco-vestuario-destrozado-gpt", "choque_lado": 88},
	# las estanterías del almacén de la tienda de ropa, llenas de ropa doblada (la de los trasteros con montones de GPT, cuatro distintas:
	# tools/ropa_estanterias.py); desde el 19 nov, destrozadas (GPT, tools/muebles_gpt.py), como las cajas
	"ropashelf":  {"len": 88, "dep": 36, "paredes": "", "archivo": "ropa/estanteria1-destrozada-gpt"},
	"ropashelf2": {"len": 88, "dep": 36, "paredes": "", "archivo": "ropa/estanteria2-destrozada-gpt"},
	"ropashelf3": {"len": 88, "dep": 36, "paredes": "", "archivo": "ropa/estanteria3-destrozada-gpt"},
	"ropashelf4": {"len": 88, "dep": 36, "paredes": "", "archivo": "ropa/estanteria4-destrozada-gpt"},
	# los muebles de la sala de venta de la tienda de ropa (18 nov, el dueño; GPT, ropa de los años 90; tools/venta_ropa_gpt.py): a escala 1
	# (el doble de detalle, como la dependienta), así que "len" y "dep" son los píxeles del dibujo
	"ropamodulo": {"len": 155, "dep": 32, "paredes": "", "archivo": "ropa/venta-p1-destrozado-gpt", "escala": 1.0},
	"ropabarra": {"len": 190, "dep": 28, "paredes": "", "archivo": "ropa/venta-p2-destrozado-gpt", "escala": 1.0},
	"ropazapatos": {"len": 103, "dep": 32, "paredes": "", "archivo": "ropa/venta-p3-destrozado-gpt", "escala": 1.0},
	"ropavitrina": {"len": 73, "dep": 32, "paredes": "", "archivo": "ropa/venta-p4-destrozado-gpt", "escala": 1.0},
	"ropaoval": {"len": 42, "dep": 32, "paredes": "", "archivo": "ropa/venta-p5-destrozado-gpt", "escala": 1.0},
	"ropaperchero1": {"len": 126, "dep": 40, "paredes": "", "archivo": "ropa/venta-s1-destrozado-gpt", "escala": 1.0},
	"ropaperchero2": {"len": 137, "dep": 40, "paredes": "", "archivo": "ropa/venta-s2-destrozado-gpt", "escala": 1.0},
	"roparuedas": {"len": 85, "dep": 36, "paredes": "", "archivo": "ropa/venta-s3-destrozado-gpt", "escala": 1.0},
	"ropamesa": {"len": 149, "dep": 44, "paredes": "", "archivo": "ropa/venta-s4-destrozado-gpt", "escala": 1.0},
	"ropatarimas": {"len": 100, "dep": 56, "paredes": "", "archivo": "ropa/venta-s5-destrozado-gpt", "escala": 1.0},
	"ropamaniqui1": {"len": 29, "dep": 24, "paredes": "", "archivo": "ropa/venta-m1-destrozado-gpt", "escala": 1.0},
	"ropamaniqui2": {"len": 35, "dep": 24, "paredes": "", "archivo": "ropa/venta-m2-destrozado-gpt", "escala": 1.0},
	"ropamaniqui3": {"len": 30, "dep": 24, "paredes": "", "archivo": "ropa/venta-m3-destrozado-gpt", "escala": 1.0},
	"ropamaniqui4": {"len": 32, "dep": 24, "paredes": "", "archivo": "ropa/venta-m4-destrozado-gpt", "escala": 1.0},
	"ropamostrador": {"len": 229, "dep": 48, "paredes": "", "archivo": "ropa/venta-caja-destrozado-gpt", "escala": 1.0},
	# el mostrador de cobro de la ferretería (24 nov, el dueño; GPT, tools/muebles_ferreteria_gpt.py): el mismo por los dos lados,
	# desde el del cliente (la tienda normal) y desde el del dependiente (la inversa, que se entra por arriba)
	"ferremostrador":  {"len": 164, "dep": 48, "paredes": "", "archivo": "centro/mostrador-ferreteria-gpt", "escala": 1.0},
	"ferremostrador2": {"len": 164, "dep": 48, "paredes": "", "archivo": "centro/mostrador-ferreteria-dentro-gpt", "escala": 1.0},
	# tres palés de sacos de cemento (24 nov, el dueño; GPT): lleno, a medio gastar y con el plástico roto
	"ferrepale1": {"len": 80, "dep": 48, "paredes": "", "archivo": "centro/pale-cemento-gpt", "escala": 1.0},
	"ferrepale2": {"len": 80, "dep": 48, "paredes": "", "archivo": "centro/pale-cemento2-gpt", "escala": 1.0},
	"ferrepale3": {"len": 80, "dep": 48, "paredes": "", "archivo": "centro/pale-cemento3-gpt", "escala": 1.0},
	# dos montones de latas de pintura (24 nov, el dueño; GPT): uno alto y otro bajo y ancho, con las latas del mismo tamaño
	"ferrelatas1": {"len": 94, "dep": 48, "paredes": "", "archivo": "centro/latas-pintura-gpt", "escala": 1.0},
	"ferrelatas2": {"len": 116, "dep": 48, "paredes": "", "archivo": "centro/latas-pintura2-gpt", "escala": 1.0},
	# una transpaleta naranja, de lado (24 nov, el dueño; GPT; el asa y la rendija entre las horquillas, huecas)
	"ferretranspaleta": {"len": 110, "dep": 40, "paredes": "", "archivo": "centro/transpaleta-gpt", "escala": 1.0},
	# una escalera de tijera de aluminio, abierta y en diagonal (24 nov, el dueño; GPT; los huecos entre los peldaños, huecos)
	"ferreescalera": {"len": 72, "dep": 40, "paredes": "", "archivo": "centro/escalera-gpt", "escala": 1.0},
	# una carretilla de obra roja, en diagonal (24 nov, el dueño; GPT; los huecos entre los tubos, huecos)
	"ferrecarretilla": {"len": 100, "dep": 40, "paredes": "", "archivo": "centro/carretilla-gpt", "escala": 1.0},
	# dos góndolas de panel perforado, de tornillería y de cerrajería (24 nov, el dueño; GPT): el mismo mueble, con distinto género
	"ferregondola1": {"len": 140, "dep": 40, "paredes": "", "archivo": "centro/gondola-tornillos-gpt", "escala": 1.0},
	"ferregondola2": {"len": 140, "dep": 40, "paredes": "", "archivo": "centro/gondola-tornillos2-gpt", "escala": 1.0},
	# para el taller de la ferretería (24 nov, el dueño; GPT): un palé de bloques y un montón de tablones y barras, tapados con una lona
	"ferrelona1": {"len": 86, "dep": 48, "paredes": "", "archivo": "centro/lona-bloques-gpt", "escala": 1.0},
	"ferrelona2": {"len": 150, "dep": 40, "paredes": "", "archivo": "centro/lona-tablones-gpt", "escala": 1.0},
	# más para el taller (24 nov, el dueño; GPT): el banco de trabajo, el carro de herramientas, la hormigonera, los bidones y la estantería
	"ferrebanco": {"len": 150, "dep": 40, "paredes": "", "archivo": "centro/banco-taller-gpt", "escala": 1.0},
	"ferrecarro": {"len": 60, "dep": 36, "paredes": "", "archivo": "centro/carro-herramientas-gpt", "escala": 1.0},
	"ferrehormigonera": {"len": 88, "dep": 44, "paredes": "", "archivo": "centro/hormigonera-gpt", "escala": 1.0},
	"ferrebidones": {"len": 120, "dep": 48, "paredes": "", "archivo": "centro/bidones-gpt", "escala": 1.0},
	"ferreestanteria": {"len": 76, "dep": 32, "paredes": "", "archivo": "centro/estanteria-taller-gpt", "escala": 1.0},
	# los montones de cajas del almacén de la ferretería (24 nov, el dueño): taladros, tornillería, pintura, azulejos y fontanería
	"ferrecajas1": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/cajas-ferreteria-gpt", "escala": 1.0},
	"ferrecajas2": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/cajas-ferreteria2-gpt", "escala": 1.0},
	"ferrecajas3": {"len": 66, "dep": 36, "paredes": "", "archivo": "centro/cajas-ferreteria3-gpt", "escala": 1.0},
	"ferrecajas4": {"len": 56, "dep": 36, "paredes": "", "archivo": "centro/cajas-ferreteria4-gpt", "escala": 1.0},
	"ferrecajas5": {"len": 66, "dep": 36, "paredes": "", "archivo": "centro/cajas-ferreteria5-gpt", "escala": 1.0},
	# las estanterías del almacén de la ferretería (24 nov, el dueño), de la medida de las de ropa
	"ferrebalda1": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-ferreteria-gpt", "escala": 1.0},
	"ferrebalda2": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-ferreteria2-gpt", "escala": 1.0},
	"ferrebalda3": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-ferreteria3-gpt", "escala": 1.0},
	"ferrebalda4": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-ferreteria4-gpt", "escala": 1.0},
	# la carretilla de mano del almacén de la ferretería (24 nov, el dueño), de la medida de la de ropa
	"ferrecarretillamano": {"len": 40, "dep": 28, "paredes": "", "archivo": "centro/carretilla-almacen-ferreteria-gpt", "escala": 1.0},
	# (24 nov, el dueño) tres más para la sala de venta: el expositor de herramientas de jardín, la cesta de ofertas y el palé de malla
	"ferrejardin": {"len": 120, "dep": 40, "paredes": "", "archivo": "centro/expositor-jardin-gpt", "escala": 1.0},
	"ferrecesta": {"len": 90, "dep": 40, "paredes": "", "archivo": "centro/cesta-ofertas-gpt", "escala": 1.0},
	"ferremalla": {"len": 82, "dep": 48, "paredes": "", "archivo": "centro/pale-malla-gpt", "escala": 1.0},
	# los muebles de la farmacia (24 nov, el dueño; GPT desde fotos suyas, tools/muebles_farmacia_gpt.py): el mostrador por los dos
	# lados (el del cliente, la tienda normal, y el de la farmacéutica, la inversa), dos góndolas (medicinas y bebé), una vitrina de
	# cristal, un expositor en torre, uno de cepillos con ruedas, una mesa de cosmética, unas sillas de espera, una fuente de agua,
	# la estantería del almacén y el robot dispensador de la rebotica
	"farmamostrador":  {"len": 164, "dep": 48, "paredes": "", "archivo": "centro/mostrador-farmacia-gpt", "escala": 1.0},
	"farmamostrador2": {"len": 164, "dep": 48, "paredes": "", "archivo": "centro/mostrador-farmacia-dentro-gpt", "escala": 1.0},
	# (24 nov, el dueño) el segundo mostrador, con otras cosas encima y otros destrozos, por los dos lados
	"farmamostrador3": {"len": 164, "dep": 48, "paredes": "", "archivo": "centro/mostrador-farmacia2-gpt", "escala": 1.0},
	"farmamostrador4": {"len": 164, "dep": 48, "paredes": "", "archivo": "centro/mostrador-farmacia2-dentro-gpt", "escala": 1.0},
	"farmagondola1": {"len": 140, "dep": 40, "paredes": "", "archivo": "centro/gondola-medicinas-gpt", "escala": 1.0},
	"farmagondola2": {"len": 140, "dep": 40, "paredes": "", "archivo": "centro/gondola-bebe-gpt", "escala": 1.0},
	"farmagondola3": {"len": 140, "dep": 40, "paredes": "", "archivo": "centro/gondola-vitaminas-gpt", "escala": 1.0},
	"farmavitrina2": {"len": 150, "dep": 40, "paredes": "", "archivo": "centro/vitrina-farmacia2-gpt", "escala": 1.0},
	"farmavitrina": {"len": 150, "dep": 40, "paredes": "", "archivo": "centro/vitrina-farmacia-gpt", "escala": 1.0},
	"farmatorre": {"len": 64, "dep": 44, "paredes": "", "archivo": "centro/expositor-torre-gpt", "escala": 1.0},
	"farmacepillos": {"len": 52, "dep": 32, "paredes": "", "archivo": "centro/expositor-cepillos-gpt", "escala": 1.0},
	"farmacosmetica": {"len": 130, "dep": 48, "paredes": "", "archivo": "centro/mesa-cosmetica-gpt", "escala": 1.0},
	"farmasillas": {"len": 110, "dep": 36, "paredes": "", "archivo": "centro/sillas-espera-gpt", "escala": 1.0},
	"farmagarrafa": {"len": 32, "dep": 28, "paredes": "", "archivo": "centro/garrafa-agua-gpt", "escala": 1.0},
	"farmabalda1": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-farmacia-gpt", "escala": 1.0},
	"farmabalda2": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-farmacia2-gpt", "escala": 1.0},
	"farmabalda3": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-farmacia3-gpt", "escala": 1.0},
	"farmabalda4": {"len": 88, "dep": 36, "paredes": "", "archivo": "centro/estanteria-almacen-farmacia4-gpt", "escala": 1.0},
	# (24 nov, el dueño) los palets del almacén, en vez de las cajas de cartón de la ropa: de cajas de botellas de suero, medio vacío,
	# de cajas de bolsas de suero, derrumbado y de garrafas
	"farmapalet1": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/palet-suero-gpt", "escala": 1.0},
	"farmapalet2": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/palet-suero2-gpt", "escala": 1.0},
	"farmapalet3": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/palet-suero3-gpt", "escala": 1.0},
	"farmapalet4": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/palet-suero4-gpt", "escala": 1.0},
	"farmapalet5": {"len": 64, "dep": 36, "paredes": "", "archivo": "centro/palet-suero5-gpt", "escala": 1.0},
	# (24 nov, el dueño) la carretilla del almacén, como la de la ropa pero con cajas de suero
	"farmacarretilla": {"len": 40, "dep": 28, "paredes": "", "archivo": "centro/carretilla-farmacia-gpt", "escala": 1.0},
	"farmarobot": {"len": 150, "dep": 48, "paredes": "", "archivo": "centro/robot-farmacia-gpt", "escala": 1.0},
	# (24 nov, el dueño) otros tres robots: con el brazo arriba, con la puerta abierta y apagado y quemado
	"farmarobot2": {"len": 150, "dep": 48, "paredes": "", "archivo": "centro/robot-farmacia2-gpt", "escala": 1.0},
	"farmarobot3": {"len": 150, "dep": 48, "paredes": "", "archivo": "centro/robot-farmacia3-gpt", "escala": 1.0},
	"farmarobot4": {"len": 150, "dep": 48, "paredes": "", "archivo": "centro/robot-farmacia4-gpt", "escala": 1.0},
	# (24 nov, el dueño) lo demás del laboratorio: las dos mesas en isla con su estante alto (la de los microscopios y la del baño
	# maría), el taburete, la mesa de acero con cajones, el carro de acero y el cubo de residuos
	"farmaisla1": {"len": 160, "dep": 44, "paredes": "", "archivo": "centro/mesa-laboratorio-gpt", "escala": 1.0},
	"farmaisla2": {"len": 160, "dep": 44, "paredes": "", "archivo": "centro/mesa-laboratorio2-gpt", "escala": 1.0},
	"farmataburete": {"len": 30, "dep": 20, "paredes": "", "archivo": "centro/taburete-laboratorio-gpt", "escala": 1.0},
	"farmaacero": {"len": 136, "dep": 40, "paredes": "", "archivo": "centro/mesa-acero-gpt", "escala": 1.0},
	"farmacarro": {"len": 56, "dep": 28, "paredes": "", "archivo": "centro/carro-acero-gpt", "escala": 1.0},
	"farmaresiduos": {"len": 48, "dep": 28, "paredes": "", "archivo": "centro/contenedor-residuos-gpt", "escala": 1.0},
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
	# la olla gigante del cocinero, en medio de su cocina (cocinero.gd: la remueve y se come el guiso)
	"bigpot":          {"len": 156, "dep": 84, "paredes": "todas", "archivo": "centro/olla-gigante"},
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
	# Los aparatos de la azotea (planta.gd, AZOTEA_APARATOS): el aire acondicionado ("acunit") y la torre de antena
	# ("antennas"), de GPT desde el 11 nov (tools/muebles_gpt.py); los demás, de PixelLab (con las guías de
	# tools/guias_azotea.py), ya no salen
	"acunit":          {"len": 128, "dep": 72, "paredes": "todas", "archivo": "centro/aire-acondicionado"},
	"airhandler":      {"len": 184, "dep": 60, "paredes": "todas", "archivo": "centro/climatizadora"},
	"chimney":         {"len": 48,  "dep": 48, "paredes": "todas", "archivo": "centro/chimenea"},   # (ya no sale en la azotea)
	"vent":            {"len": 44,  "dep": 44, "paredes": "todas", "archivo": "centro/extractor"},
	# y los de la azotea de los Apartamentos (con el extractor): depósito de agua, antenas y (ya no sale) tendedero
	"watertank":       {"len": 96,  "dep": 64, "paredes": "todas", "archivo": "azotea/deposito-agua"},
	"antennas":        {"len": 72,  "dep": 40, "paredes": "todas", "archivo": "azotea/antenas"},
	"clothesline":     {"len": 160, "dep": 24, "paredes": "todas", "archivo": "azotea/tendedero"},   # (ya no sale en la azotea)
	# el garaje del reto del día (planta.gd, GARAJE_COLUMNAS y GARAJE_COCHES; de GPT, tools/garaje_gpt.py, 16 nov): la
	# columna de hormigón con su chevron amarillo y negro, y tres coches aparcados, todos de frente
	"garagecolumn":    {"len": 64,  "dep": 40, "paredes": "todas", "archivo": "garaje/columna"},
	"carsilver":       {"len": 112, "dep": 116, "paredes": "todas", "archivo": "garaje/coche-plata"},
	"carblue":         {"len": 112, "dep": 116, "paredes": "todas", "archivo": "garaje/coche-azul"},
	"carred":          {"len": 104, "dep": 108, "paredes": "todas", "archivo": "garaje/coche-rojo"},
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
	# tienen dibujo de frente); en el taller, la estantería metálica con cajas (tools/muebles_gpt.py); y en el despacho, la papelera
	"showertray":      {"len": 72,  "dep": 44, "paredes": "",      "archivo": "vestuario/plato-ducha"},
	"lockerbench":     {"len": 128, "dep": 28, "paredes": "todas", "archivo": "vestuario/banco-vestuario", "choque_lado": 88},
	"stafftoilet":     {"len": 40,  "dep": 52, "paredes": "lados", "archivo": "vestuario/vater-vestuario"},
	"staffsink":       {"len": 52,  "dep": 40, "paredes": "lados", "archivo": "vestuario/lavabo-espejo"},
	"canshelf":        {"len": 80,  "dep": 36, "paredes": "",      "archivo": "mantenimiento/estanteria-botes"},
	"wastebasket":     {"len": 28,  "dep": 22, "paredes": "todas", "archivo": "despacho/papelera"},
	# las tuberías de las paredes de los lados del taller, debajo de sus puertas (GPT, tools/taller_tuberias.py): las
	# blancas de la caldera, a la izquierda, y las rojas de incendios, a la derecha (solo de lado: no tienen dibujo de frente)
	"boilerpipes":     {"len": 100, "dep": 46, "paredes": "lados", "archivo": "mantenimiento/tuberias-caldera"},
	"firepipes":       {"len": 100, "dep": 46, "paredes": "lados", "archivo": "mantenimiento/tuberias-incendios"},
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
			"arriba": [["wardrobe", 9.0], ["nightstand", 4.55, "izquierda", "apagada"], ["doublebed", 5.25, "izquierda"],
				["nightstand", 7.25, "izquierda"]],
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
			"arriba": [["desk", 3.0], ["wardrobe", 10.0], ["bed", 5.0, "derecha"], ["nightstand", 6.45, "derecha"]],
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
			"abajo": [["showertray", 1.0, "libre", 0.5], ["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
			"arriba": [["showertray", 1.0, "libre", 0.5], ["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		},
	},
	"bano-individual": {
		"colocados": {
			"abajo": [["showertray", 6.0, "libre", 0.5, "espejo"], ["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
			"arriba": [["showertray", 6.0, "libre", 0.5, "espejo"], ["staffsink", 2.5, "izquierda"], ["stafftoilet", 6.0, "izquierda"]],
		},
	},
	# el pasillo de cada planta de los Apartamentos: de momento, sin muebles (si vuelven, solo poco hondos: el pasillo es
	# estrecho, "fondo_max": 46; los de antes: shoerack, coatstand, console, plant y bookshelf, de 5 a 8)
	# el pasillo de los Apartamentos: sin muebles al azar (sus plantas van puestas a mano: planta.gd)
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
		# (volteado, la sala es una L: arriba, un brazo estrecho hacia la derecha; las taquillas, al fondo de ese brazo, que no
		# tapen su boca ni la puerta de arriba: Muebles.repasar, 18 nov)
		"arriba": [["metalshelf", 1.5], ["lockers", 15.5], ["pallet", 7.0, "izquierda"], ["pallet", 3.0, "abajo"]],
	}},
	"bano-supermercado": {"colocados": {
		"abajo": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
		"arriba": [["staffsink", 2.5, "derecha"], ["stafftoilet", 6.0, "derecha"]],
	}},
	# M77: la ferretería fija (Tienda.PLANOS). (20 nov, el dueño) la sala de venta, sin muebles de momento: se rehará, como la de la
	# tienda de ropa (antes llevaba bancos de trabajo, palés, cajas y dos filas de estanterías: está en git)
	"tienda-ferreteria": {"colocados": {"abajo": [["ferremostrador", 16.0, "libre", 2.75], ["ferrepale1", 31.25, "libre", 7.0], ["ferrepale2", 34.0, "libre", 7.0], ["ferrepale3", 36.75, "libre", 7.0], ["ferretranspaleta", 40.25, "libre", 7.0], ["ferrelatas1", 5.5, "libre", 5.5], ["ferrelatas2", 9.0, "libre", 5.5], ["ferreescalera", 2.625, "libre", 5.5], ["ferrecarretilla", 34.0, "libre", 10.0], ["ferregondola1", 4.5, "libre", 10.5], ["ferregondola2", 9.25, "libre", 10.5], ["ferrejardin", 16.0, "libre", 6.5], ["ferrecesta", 16.0, "libre", 10.5], ["ferremalla", 27.5, "libre", 7.0]], "arriba": [["ferremostrador2", 16.0, "libre", 8.25], ["ferrepale1", 31.25, "libre", 4.5], ["ferrepale2", 34.0, "libre", 4.5], ["ferrepale3", 36.75, "libre", 4.5], ["ferretranspaleta", 40.25, "libre", 4.5], ["ferrelatas1", 5.5, "libre", 4.5], ["ferrelatas2", 9.0, "libre", 4.5], ["ferreescalera", 2.625, "libre", 4.5], ["ferrecarretilla", 34.0, "libre", 8.25], ["ferregondola1", 4.5, "libre", 8.25], ["ferregondola2", 9.25, "libre", 8.25], ["ferrejardin", 16.0, "libre", 4.5], ["ferrecesta", 28.0, "libre", 8.25], ["ferremalla", 27.5, "libre", 4.5]]}},
	# el almacén (20 nov, el dueño: el mismo que el de la tienda de ropa, almacen-ropa; 24 nov: con montones de cajas, estanterías y carretilla de
	# ferretería en los sitios de los de ropa) y el taller de la ferretería fija (M77)
	"almacen-ferreteria": {"colocados": {
		"abajo": [["ferrebalda1", 1.9], ["ferrebalda2", 5.2], ["ferrebalda4", 8.5], ["ferrebalda3", 11.8], ["ferrebalda1", 15.1],
			["ferrecajas1", 2.0, "libre", 7.4], ["ferrecajas4", 5.0, "libre", 7.4], ["ferrecajas2", 11.33, "libre", 7.4], ["ferrecajas5", 14.67, "libre", 7.4],
			["ferrecarretillamano", 15.8, "libre", 4.0]],
		"arriba": [["ferrebalda3", 1.88], ["ferrebalda1", 5.12], ["ferrebalda4", 11.21], ["ferrebalda2", 14.79],
			["ferrecajas3", 2.17, "abajo"], ["ferrecajas1", 5.33, "abajo"], ["ferrecajas5", 8.5, "abajo"], ["ferrecajas2", 11.67, "abajo"], ["ferrecajas4", 14.83, "abajo"],
			["ferrecarretillamano", 15.8, "libre", 6.0]]}},
	# (20 nov, el dueño) el aseo, el mismo que el de la tienda de ropa (bano-ropa: sus muebles destrozados, en los mismos sitios; el
	# banco, debajo de la puerta, como se ve en la ropa: a 5.85 tapaba la puerta y Muebles.repasar lo quitaba)
	"bano-ferreteria": {"colocados": {
		"abajo": [["taquillaropa", 6.0], ["staffsinkropa", 3.3, "izquierda"], ["stafftoiletropa", 6.7, "izquierda"], ["lockerbenchropa", 7.75, "derecha"]],
		"arriba": [["taquillaropa", 6.0], ["staffsinkropa", 3.3, "izquierda"], ["stafftoiletropa", 6.7, "izquierda"], ["lockerbenchropa", 9.2, "derecha"]],
	}},
	# (20 nov, el dueño) el taller (antes, dos bancos de trabajo, una estantería y palés: está en git). Desde el 24 nov, las dos lonas
	# contra la pared del fondo, la de enfrente de la puerta (que está en medio, casillas 9 a 11): el palé a la izquierda, los tablones a la derecha.
	# Con el banco, la estantería y el carro: en la normal, el banco y la estantería también en la del fondo y, por delante, los bidones,
	# la hormigonera y el carro; en la inversa (la puerta, arriba) los altos van en la de la puerta, a sus lados, para que se les vea de
	# frente, y las lonas en la de abajo. Libre siempre el paso de en medio, de la puerta al fondo
	"taller-ferreteria": {"colocados": {
		"abajo": [["ferrelona1", 3.5, "libre", 0.875], ["ferrebanco", 9.25, "libre", 0.75], ["ferrelona2", 15.0, "libre", 0.75],
			["ferreestanteria", 18.75, "libre", 0.5], ["ferrebidones", 3.0, "libre", 6.5], ["ferrehormigonera", 14.75, "libre", 6.5],
			["ferrecarro", 18.5, "libre", 6.0]],
		"arriba": [["ferrelona1", 3.5, "libre", 10.125], ["ferrelona2", 15.5, "libre", 10.25], ["ferrebanco", 4.75, "libre", 0.75],
			["ferreestanteria", 13.0, "libre", 0.5], ["ferrecarro", 16.5, "libre", 0.75], ["ferrebidones", 3.0, "libre", 6.0],
			["ferrehormigonera", 16.0, "libre", 6.0]]}},
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
	# La tienda de ropa (Tienda.PLANOS), la sala de venta (18 nov, el dueño; 46 × 17): los muebles de GPT de los años 90 (a escala 1),
	# todos "libre". Los de pared, pegados a la pared de arriba (normal: solo a la izquierda, con la base en la fila 4, sin tapar la
	# puerta del almacén; la pared de las cortinas de los probadores, sin nada; inversa: en la 0, a los lados de la entrada); por el suelo,
	# percheros, mesas, tarimas y maniquíes en filas con pasillo entre ellas, la caja (mostrador) junto a la entrada y libres el paso
	# de la entrada (casillas 21,5 a 24,5) y el de delante de los probadores
	"tienda-ropa": {"colocados": {
		"abajo": [
			["ropabarra", 6.79, "libre", 4.4375], ["ropaoval", 10.58, "libre", 4.5], ["ropamodulo", 21.5, "libre", 4.5], ["ropazapatos", 5.43, "libre", 9.25],
			["ropaperchero1", 38.0, "libre", 4.375], ["ropaperchero2", 38.0, "libre", 9.125], ["roparuedas", 38.0, "libre", 13.4375], ["ropatarimas", 5.38, "libre", 13.125],
			["ropamesa", 15.12, "libre", 13.3125], ["ropamaniqui1", 28.4, "libre", 9.375], ["ropamaniqui2", 30.0, "libre", 9.375], ["ropamaniqui3", 28.4, "libre", 13.625],
			["ropamaniqui4", 30.0, "libre", 13.625], ["ropamostrador", 15.12, "libre", 9.0]],
		# (19 nov, el dueño: «ordena la tienda inversa como la normal») los mismos 14, uno de cada y sin la vitrina, y luego colocados uno a
		# uno: en la pared de arriba, a la derecha de la entrada (de 24,5 a 46), la barra, el expositor redondeado y el módulo, con la misma
		# separación entre ellos y a los bordes; a la izquierda, el zapatero (encima de las tarimas) y dos maniquíes, con el mismo hueco entre el
		# zapatero, ellos y el marco de la puerta (21,875). Por el suelo, la mesa y la caja a la izquierda; en el medio, un maniquí y debajo el perchero pequeño
		# (el de ruedas); a la derecha, otro maniquí y debajo los dos percheros. El perchero de delante de los probadores, algo más arriba
		# (a 12,6 se pegaba a lo alto de su pared, que tapa las filas 13 a 17)
		"arriba": [
			["ropabarra", 29.82, "libre", 0.4375], ["ropaoval", 35.8, "libre", 0.5], ["ropamodulo", 41.23, "libre", 0.5], ["ropazapatos", 5.38, "libre", 0.5],
			["ropaperchero1", 38.0, "libre", 11.5], ["ropaperchero2", 38.0, "libre", 7.875], ["roparuedas", 29.2, "libre", 7.625], ["ropatarimas", 5.38, "libre", 3.875],
			["ropamesa", 15.12, "libre", 3.6875], ["ropamaniqui1", 29.2, "libre", 3.5625], ["ropamaniqui2", 38.0, "libre", 3.5625], ["ropamaniqui3", 11.8, "libre", 0.375],
			["ropamaniqui4", 17.06, "libre", 0.375], ["ropamostrador", 15.12, "libre", 8.0]]}},
	"probadores-ropa": {"colocados": {"abajo": [["espejoprobador", 3.0], ["pufprobador", 0.7], ["ganchoprobador", 2.5, "derecha"], ["ganchoprobador", 4.5, "derecha"]], "arriba": [["pufprobador", 0.7], ["ganchoprobador", 3.5, "derecha"], ["ganchoprobador", 5.5, "derecha"]]}},
	# el almacén de la tienda de ropa (18 nov, el dueño; 17 × 12; la puerta, en las casillas 7 y 8): estanterías de las habitaciones de los
	# supervivientes en la pared de arriba (normal: cinco, con la misma separación; inversa: dos a cada lado de la puerta), montones de cajas de
	# los trasteros en la pared de abajo (normal: dos a cada lado de la puerta; inversa: cinco con la misma separación) y la carretilla de los
	# trasteros, de frente y algo separada de la pared de la derecha ("libre"). En la normal, la pared de abajo y las 4 últimas filas quedan
	# detrás de la pared alta de la sala de venta: lo de abajo se pone a 8 filas ("libre", y 7,4) y la carretilla en el medio de esas 8 (la fila 4)
	"almacen-ropa": {"colocados": {
		"abajo": [["ropashelf", 1.9], ["ropashelf2", 5.2], ["ropashelf3", 8.5], ["ropashelf4", 11.8], ["ropashelf", 15.1],
			["cajasropa", 2.0, "libre", 7.4], ["cajasropa4", 5.0, "libre", 7.4], ["cajasropa2", 11.33, "libre", 7.4], ["cajasropa5", 14.67, "libre", 7.4],
			["carretillaropa", 15.8, "libre", 4.0]],
		"arriba": [["ropashelf3", 1.88], ["ropashelf", 5.12], ["ropashelf4", 11.21], ["ropashelf2", 14.79],
			["cajasropa3", 2.17, "abajo"], ["cajasropa", 5.33, "abajo"], ["cajasropa5", 8.5, "abajo"], ["cajasropa2", 11.67, "abajo"], ["cajasropa4", 14.83, "abajo"],
			["carretillaropa", 15.8, "libre", 6.0]]}},
	"bano-ropa": {"colocados": {"abajo": [["taquillaropa", 6.0], ["staffsinkropa", 3.3, "izquierda"], ["stafftoiletropa", 6.7, "izquierda"], ["lockerbenchropa", 5.85, "derecha"]],
		"arriba": [["taquillaropa", 6.0], ["staffsinkropa", 3.3, "izquierda"], ["stafftoiletropa", 6.7, "izquierda"], ["lockerbenchropa", 9.2, "derecha"]]}},
	# la farmacia, rehecha (24 nov, el dueño) con la distribución de la ferretería: la sala de venta y la rebotica, sin muebles de
	# momento (se van poniendo los de GPT); el almacén y el aseo, los mismos que los de la ropa y la ferretería (el almacén, con sus
	# estanterías de farmacia y, hasta que se hagan las suyas, las cajas y la carretilla de la ropa). La de antes, en git
	# La sala de venta (46 × 13; la entrada, en medio, casillas 22 y 23; la puerta del almacén, 15 y 16, y la de la rebotica, 35 y 36):
	# un mostrador delante de cada puerta, centrado con ella (24 nov, el dueño): el primero, en la de la rebotica (donde se esconde la
	# farmacéutica), y el segundo, en la del almacén, como el de la ferretería;
	# a la izquierda, las góndolas, la mesa de cosmética y los expositores; a la derecha, la vitrina y la fuente; las sillas de espera,
	# en la normal, pegadas a la pared de arriba, entre las puertas del almacén y de la rebotica, y la fuente a su derecha; y las dos
	# vitrinas, también pegadas a ella, entre la pared de la izquierda y la puerta del almacén, con el mismo espacio entre la pared, las
	# dos y la puerta; la mesa de cosmética, en el centro, delante de la entrada;
	# una góndola debajo de cada mostrador, con paso entre los dos, y a la izquierda de cada una, con media casilla de separación, los cepillos (la del almacén) y la
	# torre (la de la rebotica); y a la izquierda de los cepillos, también a media casilla, la tercera góndola (24 nov, el dueño).
	# Libre el paso de la entrada. En la inversa (la entrada arriba), lo mismo dado la vuelta de arriba abajo (24 nov, el dueño): los
	# mostradores abajo, delante de las puertas, y las vitrinas, las sillas y la garrafa por encima de la pared de abajo, que tapa lo de detrás
	"tienda-farmacia": {"colocados": {
		"abajo": [["farmamostrador", 36.0, "libre", 2.75], ["farmamostrador3", 16.0, "libre", 2.75], ["farmagondola1", 16.0, "libre", 7.5], ["farmagondola2", 36.0, "libre", 7.5],
			["farmacosmetica", 23.0, "libre", 7.0], ["farmacepillos", 12.5, "libre", 7.5], ["farmatorre", 32.31, "libre", 7.5],
			["farmavitrina", 4.22], ["farmavitrina2", 10.78], ["farmagondola3", 9.0, "libre", 7.5], ["farmasillas", 26.0], ["farmagarrafa", 28.25]],
		"arriba": [["farmamostrador2", 36.0, "libre", 8.25], ["farmamostrador4", 16.0, "libre", 8.25], ["farmagondola1", 16.0, "libre", 3.5], ["farmagondola2", 36.0, "libre", 3.5],
			["farmacosmetica", 23.0, "libre", 4.0], ["farmacepillos", 12.5, "libre", 3.5], ["farmatorre", 32.31, "libre", 3.5],
			["farmavitrina", 4.22, "libre", 9.4], ["farmavitrina2", 10.78, "libre", 9.4], ["farmagondola3", 9.0, "libre", 3.5],
			["farmasillas", 26.0, "libre", 9.5], ["farmagarrafa", 28.25, "libre", 9.6]]}},
	# la rebotica (20 × 12, la puerta en medio): en la normal, los cuatro robots dispensadores seguidos contra la pared de arriba, con el
	# mismo espacio entre ellos y las paredes (24 nov, el dueño); debajo, las dos mesas en isla, una a cada lado del paso de la puerta,
	# y a la derecha de la de la derecha, el cubo de residuos; y abajo, la mesa de acero, con el carro de acero a su izquierda; libre
	# el paso de la puerta al centro (todo por encima de la fila 9: lo de más abajo lo tapa la pared de abajo). En la inversa (la
	# puerta arriba), dos robots, uno a cada lado de la puerta, centrados en su trozo de pared (no caben los cuatro), y lo demás como
	# en la normal pero una casilla más abajo (24 nov, el dueño)
	"rebotica-farmacia": {"colocados": {"abajo": [["farmarobot", 2.59], ["farmarobot3", 7.53], ["farmarobot2", 12.47], ["farmarobot4", 17.41],
			["farmaisla1", 5.5, "libre", 4.3], ["farmaisla2", 14.5, "libre", 4.3], ["farmaresiduos", 18.25, "libre", 4.55],
			["farmaacero", 5.5, "libre", 8.4], ["farmacarro", 2.0, "libre", 8.59]],
		"arriba": [["farmarobot", 4.5], ["farmarobot2", 15.5],
			["farmaisla1", 5.5, "libre", 5.3], ["farmaisla2", 14.5, "libre", 5.3], ["farmaresiduos", 18.25, "libre", 5.55],
			["farmaacero", 5.5, "libre", 9.4], ["farmacarro", 2.0, "libre", 9.59]]}},
	"almacen-farmacia": {"colocados": {
		"abajo": [["farmabalda1", 1.9], ["farmabalda2", 5.2], ["farmabalda4", 8.5], ["farmabalda3", 11.8], ["farmabalda1", 15.1],
			["farmapalet1", 2.0, "libre", 7.4], ["farmapalet4", 5.0, "libre", 7.4], ["farmapalet3", 11.33, "libre", 7.4], ["farmapalet5", 14.67, "libre", 7.4],
			["farmacarretilla", 15.8, "libre", 4.0]],
		"arriba": [["farmabalda3", 1.88], ["farmabalda1", 5.12], ["farmabalda4", 11.21], ["farmabalda2", 14.79],
			["farmapalet3", 2.17, "abajo"], ["farmapalet1", 5.33, "abajo"], ["farmapalet5", 8.5, "abajo"], ["farmapalet2", 11.67, "abajo"], ["farmapalet4", 14.83, "abajo"],
			["farmacarretilla", 15.8, "libre", 6.0]]}},
	"bano-farmacia": {"colocados": {
		"abajo": [["taquillaropa", 6.0], ["staffsinkropa", 3.3, "izquierda"], ["stafftoiletropa", 6.7, "izquierda"], ["lockerbenchropa", 7.75, "derecha"]],
		"arriba": [["taquillaropa", 6.0], ["staffsinkropa", 3.3, "izquierda"], ["stafftoiletropa", 6.7, "izquierda"], ["lockerbenchropa", 9.2, "derecha"]],
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
	# (con la tele de las noticias de la torre: Planta.TELE_EN, M92)
	"office-atencion": {"colocados": {
		"abajo": [["officekitchen", 1.5], ["filecabinet", 4.0], ["tv", 6.0], ["drinkfridge", 8.0], ["watercooler", 6.0, "izquierda"]],
		# (volteada, la sala es una L, como el almacén del supermercado: la nevera, al fondo de su brazo estrecho, que no tape
		# la boca: Muebles.repasar, 18 nov)
		"arriba": [["officekitchen", 1.5], ["tv", 7.25], ["drinkfridge", 16.25], ["watercooler", 7.0, "izquierda"], ["watercooler", 3.0, "abajo"]],
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
	# el aseo de Recursos Humanos cuando la limpiadora de noche se encierra en él (planta.gd, cuarto_limpieza): el cuarto
	# de la limpieza, con el carro y un cubo de basura donde estaban el lavabo y el váter
	"limpieza-rrhh": {"colocados": {
		"abajo": [["janitorcart", 2.5, "izquierda"], ["trashcan", 6.0, "izquierda"]],
		"arriba": [["janitorcart", 2.5, "izquierda"], ["trashcan", 6.0, "izquierda"]],
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
	# la Cocina central del cocinero (minijefe; planta.gd pone apt.tipo = "cocinero"): tres fogones o freidoras en cada
	# pared (hasta el 23 nov rebosaban aceite hirviendo, M82), siempre en el mismo sitio (muebles.gd, fijos): en el fondo, dos
	# freidoras y un fogón industrial, con dos mesas de acero entre medias (no sueltan nada); a cada lado, tres fogones
	# (las freidoras no tienen dibujo de lado). La pared de abajo, vacía (ahí está la puerta)
	"jefe-cocinero": {
		"muebles": [],
		"cuantos": [0, 0],
		# y en medio, su olla gigante (cocinero.gd: va a removerla y, si termina, se cura)
		"en_medio": "bigpot",
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
	# la Oficina de seguridad del antidisturbios (minijefe; planta.gd pone apt.tipo = "antidisturbios"): taquillas
	# metálicas sueltas, muy separadas (muebles.gd, islas con su "pasillo"). Contra ellas se le agrieta el escudo al
	# estrellarse cargando (antidisturbios.gd: a la 3ª, revienta); el resto, libre para la pelea
	"jefe-antidisturbios": {
		"muebles": [],
		"cuantos": [0, 0],
		"islas": {"muebles": ["lockers"], "fila": 1, "entre": 0, "cada": 260, "pasillo": 300, "puerta": 120.0,
			"centro": Vector2(170, 110)},
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
		# (17 nov: el dueño la está rehaciendo y la ha dejado vacía, solo con las entradas de las tiendas; antes llevaba
		# plantas, bancos y maniquíes)
		# (17 nov: cuatro palmeras, todas en la pared de arriba: una en la 46,6, entre el escaparate y el cartel de salida, que
		# está siempre arriba a la derecha, y otra en su espejo, la 5,4; y una a cada lado del ascensor, la 23 y la 29. La
		# pared de abajo, sin nada. Los neones se apartan de ellas solos: mapa.poner_neones_galeria)
		# (y tres bancos en medio del pasillo: uno delante de cada tienda de la pared de abajo, mirando hacia ella, y otro
		# entre los dos, delante del ascensor. Obstáculos para despistar a los guardas dándoles la vuelta. El suelo tiene 8
		# casillas de hondo: el 4, su mitad)
		"colocados": {"abajo": [
			["palmera", 5.4], ["palmera", 23.0], ["palmera", 29.0], ["palmera", 46.6],
			["bancogaleria", 12.0, "libre", 4.0], ["bancogaleria", 26.0, "libre", 4.0], ["bancogaleria", 40.0, "libre", 4.0],
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
