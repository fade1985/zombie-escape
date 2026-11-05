# Las tiendas del centro comercial (el segundo edificio: docs/historial/CENTRO_COMERCIAL.md)
#
# Una tienda es como un apartamento (apartamento.gd): un rectángulo con su puerta al pasillo, con su sala de venta y,
# al fondo, sus habitaciones de dentro (almacén, cámara, taller...) y el aseo de empleados (M81). Desde la M77 cada
# tipo sale siempre igual, sacada de su plano (PLANOS) y con sus muebles puestos a mano (Catalogo.SALAS); antes se
# sorteaban (está en git, por si hiciera falta). Devuelve un plano igual que el de los apartamentos (cols, filas,
# dueno, salas, puertas, entrada...), así que el mapa, los muebles, los zombis, los botiquines, el superviviente y el
# científico funcionan igual que en un apartamento.
class_name Tienda

const CASILLA := 32
const BORDE := 2           # grosor del muro de fuera, en casillas

# Cada tipo de tienda: su nombre (el del letrero y el de la sala de venta) y sus habitaciones de dentro (solo para
# saberlas: las de verdad, con el aseo de empleados de todas, salen de su plano).
# "neon" es lo que pone el letrero de neón de encima de su puerta (neon.gd), con su color; su escaparate, el sprite
# escaparate-<tipo>.
# Los textos (el nombre y el neón, y los de NOMBRES) están en español, en líneas con la marca de traducir al final
# (docs/IDIOMAS.md): son datos (se guardan así en la planta) y se enseñan ya traducidos con nombre(), neon() y
# Planta.nombre_de_sitio
const TIPOS := {
	"supermercado": {"nombre": "Supermercado", "neon": "SUPER", "salas": ["almacen", "camara", "bano"],   # [traducir]
		"color": Color("#5dff8a")},
	"ferreteria": {"nombre": "Ferretería", "neon": "FERRETERIA", "salas": ["almacen", "taller"],   # [traducir]
		"color": Color("#ff9a3c")},
	"electronica": {"nombre": "Electrónica", "neon": "ELECTRO", "salas": ["almacen", "taquillas"],   # [traducir]
		"color": Color("#4fe3ff")},
	"restaurante": {"nombre": "Restaurante", "neon": "BURGER", "salas": ["cocina", "camara", "bano"],   # [traducir]
		"color": Color("#ff4f5e")},
	"ropa": {"nombre": "Tienda de ropa", "neon": "MODA", "salas": ["probadores", "almacen"],   # [traducir]
		"color": Color("#ff5fd0")},
	"farmacia": {"nombre": "Farmacia", "neon": "FARMACIA", "salas": ["rebotica", "bano"],   # [traducir]
		"color": Color("#3dff6e")},
	# la joyería (parte 9): no entra en el sorteo de cada planta, sale una por partida (Planta.joyeria_planta).
	# Al fondo, la cámara acorazada: la sala opcional con riesgo (su puerta y su premio, en los trozos 2 y 3)
	"joyeria": {"nombre": "Joyería", "neon": "JOYAS", "salas": ["trastienda", "acorazada"],   # [traducir]
		"color": Color("#ffd23f")},
	# Los departamentos de Torre Velaria (el tercer edificio: docs/PLAN_TERCER_EDIFICIO.md). Son tiendas para el código
	# (un local con su sala grande delante y sus habitaciones al fondo), pero de la torre ("edificio"); el "neon" es su
	# rótulo iluminado. "desde": la planta desde la que sale (Dirección, solo de la planta 20 arriba). De momento (parte 1,
	# el esqueleto) cada uno toma el plano y los muebles de una tienda del centro ("presta": esa tienda, y qué habitación
	# de ella hace de cada una suya); en la parte 2 llevan los suyos
	"atencion": {"nombre": "Atención al cliente", "neon": "CLIENTES", "salas": ["impresoras", "office", "bano"],   # [traducir]
		"color": Color("#dff1ff"), "edificio": "torre",
		"presta": {"tipo": "supermercado", "usos": {"impresoras": "camara", "office": "almacen"}}},
	"informatica": {"nombre": "Informática", "neon": "INFORMATICA", "salas": ["servidores", "almacen", "bano"],   # [traducir]
		"color": Color("#9fd8ff"), "edificio": "torre",
		"presta": {"tipo": "electronica", "usos": {"servidores": "taquillas"}}},
	"rrhh": {"nombre": "Recursos Humanos", "neon": "RR.HH.", "salas": ["archivo", "entrevistas", "bano"],   # [traducir]
		"color": Color("#ffe9c9"), "edificio": "torre",
		"presta": {"tipo": "ropa", "usos": {"archivo": "almacen", "entrevistas": "probadores"}}},
	"marketing": {"nombre": "Marketing", "neon": "MARKETING", "salas": ["almacen", "estudio", "bano"],   # [traducir]
		"color": Color("#ffc6ef"), "edificio": "torre",
		"presta": {"tipo": "ferreteria", "usos": {"estudio": "taller"}}},
	"seguridad": {"nombre": "Seguridad corporativa", "neon": "SEGURIDAD", "salas": ["camaras", "armero", "bano"],   # [traducir]
		"color": Color("#c9ffd8"), "edificio": "torre",
		"presta": {"tipo": "restaurante", "usos": {"camaras": "cocina", "armero": "camara"}}},
	"direccion": {"nombre": "Dirección", "neon": "DIRECCION", "salas": ["despacho", "juntas", "bano"],   # [traducir]
		"color": Color("#fff3b0"), "edificio": "torre", "desde": 3,
		"presta": {"tipo": "ropa", "usos": {"despacho": "almacen", "juntas": "probadores"}}},
}
# [traducir]
const NOMBRES := {"almacen": "Almacén", "camara": "Cámara frigorífica", "taller": "Taller", "taquillas": "Taquillas",
	"cocina": "Cocina", "probadores": "Probadores", "rebotica": "Rebotica", "bano": "Aseo de empleados",
	"trastienda": "Trastienda", "acorazada": "Cámara acorazada",
	# las de los departamentos de Torre Velaria
	"impresoras": "Sala de impresoras", "office": "Office", "servidores": "Sala de servidores", "archivo": "Archivo",
	"entrevistas": "Sala de entrevistas", "estudio": "Estudio de grabación", "camaras": "Sala de cámaras",
	"armero": "Armero", "despacho": "Despacho", "juntas": "Sala de juntas"}
# [/traducir]

# M77: las tiendas fijas, como el piso de los apartamentos (Apartamento.PLANO_PASILLO). Cada tipo de tienda que tiene
# aquí su plano sale siempre igual, dibujado con letras y con la puerta de entrada abajo (las de debajo de la galería, con
# la puerta arriba, salen volteadas); sus muebles, puestos a mano en los "colocados" de "<sala>-<tipo>" de
# Catalogo.SALAS (Muebles.de_tienda).
#   #  muro             (espacio)  hueco de una puerta          E  la puerta de entrada, en el muro de fuera
#   V  sala de venta    K  cámara frigorífica    A  almacén     B  aseo de empleados (M81: es de la habitación a la
#   T  taller           Q  taquillas             O  cocina         que da su puerta, con su botiquín en el armarito)
#   P  probadores       R  rebotica              Z  trastienda  X  cámara acorazada
#   ~  sala de venta con el charco con corriente de la electrónica (Peligros.agua: "agua", sus casillas)
# Cada trozo seguido de una misma letra es una habitación. Los tabiques de lado a lado tapan las tres últimas filas de
# lo que queda encima (como en el piso). Todas las filas, igual de largas; la prueba --tiendas-fijas dice si algo ha
# quedado mal
const LETRAS := {"V": {"uso": "tienda"}, "K": {"uso": "camara"}, "A": {"uso": "almacen"}, "B": {"uso": "bano"},
	"T": {"uso": "taller"}, "Q": {"uso": "taquillas"}, "O": {"uso": "cocina"}, "P": {"uso": "probadores"},
	"R": {"uso": "rebotica"}, "Z": {"uso": "trastienda"}, "X": {"uso": "acorazada"},
	# las de los departamentos de Torre Velaria
	"I": {"uso": "impresoras"}, "F": {"uso": "office"}, "S": {"uso": "servidores"}, "H": {"uso": "archivo"},
	"N": {"uso": "entrevistas"}, "U": {"uso": "estudio"}, "C": {"uso": "camaras"}, "Y": {"uso": "armero"},
	"D": {"uso": "despacho"}, "J": {"uso": "juntas"}}
const PLANOS := {
	# el supermercado: la cámara a la izquierda y el almacén a la derecha, con el aseo en su rincón; entre los dos, un
	# trozo de sala de venta que llega hasta el fondo
	"supermercado": [
		"############################################",
		"############################################",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA BBBBBBB##",   # no-tr (el plano, no es un texto)
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA BBBBBBB##",   # no-tr
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"##KKKKKKKKKKKK#VVVVVVVV#AAAAAAAAAA#BBBBBBB##",
		"#######  ######VVVVVVVV#AAAAAAAAAA##########",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVV#AAAAAAAAAAAAAAAAAA##",
		"##VVVVVVVVVVVVVVVVVVVVV#AAAAAAAAAAAAAAAAAA##",
		"##VVVVVVVVVVVVVVVVVVVVV#####  ##############",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"#####################EE#####################",
		"#####################EE#####################",
	],
	# la ferretería: a la izquierda, el aseo de empleados y el almacén (el aseo se abre a él); a la derecha, el taller;
	# entre los dos, un trozo de sala de venta que llega hasta el fondo
	"ferreteria": [
		"########################################",
		"########################################",
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##BBBBBBB AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",   # no-tr
		"##BBBBBBB AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",   # no-tr
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##BBBBBBB#AAAAAAAAA#VVVVV#TTTTTTTTTTTT##",
		"##############  ####VVVVV#####  ########",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"###################EE###################",
		"###################EE###################",
	],
	# la electrónica: a la izquierda, las taquillas; a la derecha, el almacén y el aseo de empleados; entre los dos, un
	# trozo de sala de venta hasta el fondo. El charco con corriente (~), siempre en el mismo sitio: a la izquierda,
	# delante de las taquillas
	"electronica": [
		"########################################",
		"########################################",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA BBBBBBB##",   # no-tr
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA BBBBBBB##",   # no-tr
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"##QQQQQQQQQQ#VVVVVVV#AAAAAAAAA#BBBBBBB##",
		"######  #####VVVVVVV####  ##############",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVV~~~~VVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVV~~~~~~VVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVV~~~~~~~~VVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVV~~~~~~~~VVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVV~~~~~VVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"###################EE###################",
		"###################EE###################",
	],
	# el restaurante: a la izquierda, el aseo de empleados y la cocina (el aseo se abre a ella; el fuego empieza delante
	# de sus fogones y freidoras); a la derecha, la cámara; entre las dos, un trozo de comedor hasta el fondo
	"restaurante": [
		"############################################",
		"############################################",
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"##BBBBBBB OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",   # no-tr
		"##BBBBBBB OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",   # no-tr
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"##BBBBBBB#OOOOOOOOOOOO#VVVVVVVV#KKKKKKKKKK##",
		"###############  ######VVVVVVVV#####  ######",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"#####################EE#####################",
		"#####################EE#####################",
	],
	# la tienda de ropa: a la izquierda, el aseo de empleados y el almacén (el aseo se abre a él); a la derecha, los
	# probadores; entre los dos, un trozo de tienda hasta el fondo, con el escaparate de maniquíes
	"ropa": [
		"########################################",
		"########################################",
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"##BBBBBBB AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",   # no-tr
		"##BBBBBBB AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",   # no-tr
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"##BBBBBBB#AAAAAAAAA#VVVVVVV#PPPPPPPPPP##",
		"#############  #####VVVVVVV#####  ######",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"###################EE###################",
		"###################EE###################",
	],
	# la farmacia: a la izquierda, el aseo de empleados y la rebotica (el aseo se abre a ella; la farmacéutica se esconde
	# en la rebotica, detrás de su puerta a la sala de venta); a la derecha, un trozo de venta hasta el fondo, con el mostrador
	"farmacia": [
		"##################################",
		"##################################",
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"##BBBBBBB RRRRRRRRRRRR#VVVVVVVVV##",   # no-tr
		"##BBBBBBB RRRRRRRRRRRR#VVVVVVVVV##",   # no-tr
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"##BBBBBBB#RRRRRRRRRRRR#VVVVVVVVV##",
		"###############  ######VVVVVVVVV##",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"################EE################",
		"################EE################",
	],
	# la joyería: al fondo, el aseo de empleados, la trastienda (el aseo se abre a ella) y la cámara acorazada, con su
	# única puerta a la sala de venta (Planta la vuelve de acero y cerrada: joyeria.gd). No le cabe un trozo de venta hasta
	# el fondo
	"joyeria": [
		"##################################",
		"##################################",
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##BBBBBBB ZZZZZZZZZZ#XXXXXXXXXXX##",   # no-tr
		"##BBBBBBB ZZZZZZZZZZ#XXXXXXXXXXX##",   # no-tr
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##BBBBBBB#ZZZZZZZZZZ#XXXXXXXXXXX##",
		"##############  ##########  ######",   # no-tr
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"##VVVVVVVVVVVVVVVVVVVVVVVVVVVVVV##",
		"################EE################",
		"################EE################",
	],
}

# Los tipos de local de ese edificio ("centro": las tiendas; "torre": los departamentos), sin la joyería (no se sortea)
static func de_edificio(edificio: String) -> Array:
	return TIPOS.keys().filter(func(t): return t != "joyeria" and TIPOS[t].get("edificio", "centro") == edificio)


# El plano de un local: el suyo o, en un departamento de la torre que aún no lo tiene, el de la tienda que le presta el
# suyo, con las letras de sus habitaciones cambiadas por las de las suyas
static func plano_de(tipo: String) -> Array:
	if PLANOS.has(tipo):
		return PLANOS[tipo]
	var presta: Dictionary = TIPOS[tipo].presta
	var cambio := {}   # letra de la tienda -> letra del departamento
	for uso in presta.usos:
		cambio[letra_de(presta.usos[uso])] = letra_de(uso)
	var plano := []
	for fila in PLANOS[presta.tipo]:
		var nueva := ""
		for c in fila:
			nueva += cambio.get(c, "V" if c == "~" else c)   # (sin el charco con corriente de la electrónica)
		plano.append(nueva)
	return plano


static func letra_de(uso: String) -> String:
	for l in LETRAS:
		if LETRAS[l].uso == uso:
			return l
	return ""


# El nombre de una tienda ("supermercado"...), ya traducido: para enseñarlo
static func nombre(tipo: String) -> String:
	return Idioma.t(TIPOS[tipo].nombre)


# Lo que pone su letrero de neón, ya traducido (corto y en mayúsculas: se pinta con la fuente del juego encima de la
# puerta, neon.gd)
static func neon(tipo: String) -> String:
	return Idioma.t(TIPOS[tipo].neon)


# Genera una tienda del tipo "tipo". "jefe": la del jefe de la planta (de momento, el mismo local diáfano y
# destrozado de la portera). "lado": dónde está la puerta al pasillo, "abajo" o "arriba". La semilla ya no se usa (M77: las
# tiendas son fijas); Planta la sigue sacando del dado para que lo demás de la planta salga igual
static func generar(_semilla: int, tipo: String, jefe := false, lado := "abajo") -> Dictionary:
	if jefe:
		var local := Apartamento.generar(true, lado)
		local.salas[0].nombre = "Tienda destrozada"   # [traducir]
		local.tipo = "tienda"   # sus muebles, los de "jefe-tienda" del catálogo (no los del salón de un piso)
		return local
	return del_plano(tipo, lado)   # M77: todas las tiendas, fijas (PLANOS)


# M77: la tienda de ese tipo, siempre la misma, sacada de su plano (PLANOS). "fijo": sus muebles son los puestos a mano
# (Muebles.de_tienda), no los del sorteo
static func del_plano(tipo: String, lado: String) -> Dictionary:
	# el charco (~) es sala de venta: se apuntan sus casillas y se lee como una V
	var plano: Array = plano_de(tipo).duplicate()
	var agua := []
	for f in plano.size():
		for c in plano[f].length():
			if plano[f][c] == "~":
				agua.append(Vector2i(c, f))
		plano[f] = plano[f].replace("~", "V")
	var t := Apartamento.del_plano(plano, LETRAS)
	t.tipo = tipo
	t.fijo = true
	if not agua.is_empty():
		var filas: int = plano.size()
		t.agua = agua if lado == "abajo" else agua.map(func(k): return Vector2i(k.x, filas - 1 - k.y))
	describir(t)
	var malos := Apartamento.fallos(t)
	if not malos.is_empty():
		push_error("El plano de la tienda %s (Tienda.PLANOS) está mal: %s" % [tipo, ", ".join(malos)])
	if lado == "arriba":
		Apartamento.voltear(t)
	t.lado = lado
	return t


# Como Apartamento.describir, con los nombres de las tiendas: la sala de venta se llama como la tienda
static func describir(t: Dictionary) -> void:
	for s in t.salas:
		var uso: String = s.uso
		s.uso = "salon"   # Apartamento.describir solo conoce los de los pisos: se le presta uno y se devuelve
		s.uso_real = uso
	Apartamento.describir(t)
	for s in t.salas:
		s.uso = s.uso_real
		s.erase("uso_real")
		s.nombre = TIPOS[t.tipo].nombre if s.uso == "tienda" else NOMBRES[s.uso]
