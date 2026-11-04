# Generador de tiendas del centro comercial (el segundo edificio: docs/historial/CENTRO_COMERCIAL.md)
#
# Una tienda es como un apartamento (apartamento.gd): un rectángulo con su puerta al pasillo. Por dentro:
#
#   1. La sala de venta lo ocupa todo, de momento (es la grande, la que hace de salón).
#   2. Las habitaciones de dentro (almacén, cámara, taller...) van en fila pegadas a la pared del fondo, cada una
#      con su puerta a la sala de venta. Entre ellas, a veces, un trozo de sala de venta que llega hasta el fondo.
#   3. El aseo, si la tienda tiene, se recorta en una esquina del fondo de otra habitación (como el baño del
#      dormitorio) y se entra por ella.
#
# Qué habitaciones lleva cada tienda lo dice TIPOS. Devuelve un plano igual que el de los apartamentos (cols,
# filas, dueno, salas, puertas, entrada...), así que el mapa, los muebles, los zombis, los botiquines, el
# superviviente y el científico funcionan igual que en un apartamento.
class_name Tienda

const CASILLA := 32
const BORDE := 2           # grosor del muro de fuera, en casillas
const PUERTA := 2          # ancho de las puertas, en casillas
const ANCHO := [8, 13]     # ancho mínimo y máximo de una habitación de dentro
const FONDO := [7, 9]      # y su fondo
const FONDO_ASEO := 12     # la que lleva el aseo dentro, más honda (para que le quede sitio alrededor)
const ASEO := [6, 7]       # ancho y fondo del aseo, en casillas
const HUECO := 5           # un trozo de sala de venta entre dos habitaciones, como poco
const DELANTE := 10        # fondo mínimo de sala de venta delante de las habitaciones

# Cada tipo de tienda: su nombre (el del letrero y el de la sala de venta), sus habitaciones de dentro en el
# orden en que se dan ("bano" es el aseo: va dentro de otra, la primera de ASEO_EN que tenga) y cuántas casillas de ancho mide
# (la profundidad sale de sus habitaciones). El peligro y los objetos de cada una llegan en las partes 3 y 6.
# "neon" es lo que pone el letrero de neón de encima de su puerta (neon.gd), con su color; su escaparate, el sprite
# escaparate-<tipo>.
# Los textos (el nombre y el neón, y los de NOMBRES) están en español, en líneas con la marca de traducir al final
# (docs/IDIOMAS.md): son datos (se guardan así en la planta) y se enseñan ya traducidos con nombre(), neon() y
# Planta.nombre_de_sitio
const TIPOS := {
	"supermercado": {"nombre": "Supermercado", "neon": "SUPER", "salas": ["almacen", "camara", "bano"], "cols": [40, 46],   # [traducir]
		"color": Color("#5dff8a")},
	"ferreteria": {"nombre": "Ferretería", "neon": "FERRETERIA", "salas": ["almacen", "taller"], "cols": [34, 40],   # [traducir]
		"color": Color("#ff9a3c")},
	"electronica": {"nombre": "Electrónica", "neon": "ELECTRO", "salas": ["almacen", "taquillas"], "cols": [34, 40],   # [traducir]
		"color": Color("#4fe3ff")},
	"restaurante": {"nombre": "Restaurante", "neon": "BURGER", "salas": ["cocina", "camara", "bano"], "cols": [40, 46],   # [traducir]
		"color": Color("#ff4f5e")},
	"ropa": {"nombre": "Tienda de ropa", "neon": "MODA", "salas": ["probadores", "almacen"], "cols": [34, 40],   # [traducir]
		"color": Color("#ff5fd0")},
	"farmacia": {"nombre": "Farmacia", "neon": "FARMACIA", "salas": ["rebotica", "bano"], "cols": [30, 34],   # [traducir]
		"color": Color("#3dff6e")},
	# la joyería (parte 9): no entra en el sorteo de cada planta, sale una por partida (Planta.joyeria_planta).
	# Al fondo, la cámara acorazada: la sala opcional con riesgo (su puerta y su premio, en los trozos 2 y 3)
	"joyeria": {"nombre": "Joyería", "neon": "JOYAS", "salas": ["trastienda", "acorazada"], "cols": [30, 34],   # [traducir]
		"color": Color("#ffd23f")},
}
const ASEO_EN := ["almacen", "cocina", "rebotica", "taller", "taquillas", "probadores"]   # nunca en la cámara
# [traducir]
const NOMBRES := {"almacen": "Almacén", "camara": "Cámara frigorífica", "taller": "Taller", "taquillas": "Taquillas",
	"cocina": "Cocina", "probadores": "Probadores", "rebotica": "Rebotica", "bano": "Aseo de empleados",
	"trastienda": "Trastienda", "acorazada": "Cámara acorazada"}
# [/traducir]

# M77: las tiendas fijas, como el piso de los apartamentos (Apartamento.PLANO_PASILLO). Cada tipo de tienda que tiene
# aquí su plano sale siempre igual, dibujado con letras y con la puerta de entrada abajo (las de debajo de la galería, con
# la puerta arriba, salen volteadas); sus muebles, puestos a mano en los "colocados" de "<sala>-<tipo>" de
# Catalogo.SALAS (Muebles.de_tienda). Las que aún no tienen plano se siguen sorteando (probar).
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
	"R": {"uso": "rebotica"}, "Z": {"uso": "trastienda"}, "X": {"uso": "acorazada"}}
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

static var rng := RandomNumberGenerator.new()


# El nombre de una tienda ("supermercado"...), ya traducido: para enseñarlo
static func nombre(tipo: String) -> String:
	return Idioma.t(TIPOS[tipo].nombre)


# Lo que pone su letrero de neón, ya traducido (corto y en mayúsculas: se pinta con la fuente del juego encima de la
# puerta, neon.gd)
static func neon(tipo: String) -> String:
	return Idioma.t(TIPOS[tipo].neon)


# Genera una tienda del tipo "tipo". "jefe": la del jefe de la planta (de momento, el mismo local diáfano y
# destrozado de la portera). "lado": dónde está la puerta al pasillo, "abajo" o "arriba"
static func generar(semilla: int, tipo: String, jefe := false, lado := "abajo") -> Dictionary:
	if jefe:
		var local := Apartamento.generar(true, lado)
		local.salas[0].nombre = "Tienda destrozada"   # [traducir]
		local.tipo = "tienda"   # sus muebles, los de "jefe-tienda" del catálogo (no los del salón de un piso)
		return local
	if PLANOS.has(tipo):
		return del_plano(tipo, lado)
	for intento in 500:
		rng.seed = semilla + intento * 7919
		var t := probar(tipo)
		if t.is_empty() or not Apartamento.fallos(t).is_empty():
			continue
		if lado == "arriba":
			Apartamento.voltear(t)
		t.lado = lado
		return t
	push_error("No se pudo generar la tienda %s (semilla %d)" % [tipo, semilla])
	return {}


# M77: la tienda de ese tipo, siempre la misma, sacada de su plano (PLANOS). "fijo": sus muebles son los puestos a mano
# (Muebles.de_tienda), no los del sorteo
static func del_plano(tipo: String, lado: String) -> Dictionary:
	# el charco (~) es sala de venta: se apuntan sus casillas y se lee como una V
	var plano: Array = PLANOS[tipo].duplicate()
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


static func probar(tipo: String) -> Dictionary:
	var datos: Dictionary = TIPOS[tipo]
	var usos: Array = datos.salas.filter(func(u): return u != "bano")
	var con_aseo: bool = "bano" in datos.salas
	var cols: int = rng.randi_range(datos.cols[0] / 2, datos.cols[1] / 2) * 2   # en casillas pares: queda centrado
	var iw := cols - BORDE * 2

	# Las habitaciones de dentro, en un orden al azar, con su ancho y su fondo
	usos.shuffle()
	var del_aseo := ""   # la habitación que lleva el aseo dentro
	if con_aseo:
		del_aseo = ASEO_EN.filter(func(u): return u in usos)[0]
	var cuartos := []
	for u in usos:
		var hondo: bool = u == del_aseo
		cuartos.append({"uso": u, "ancho": ANCHO[0] + (5 if hondo else 0),
			"fondo": FONDO_ASEO if hondo else rng.randi_range(FONDO[0], FONDO[1]), "aseo": hondo})
	usos = cuartos.map(func(q): return q.uso)
	var hondo_max: int = cuartos.reduce(func(m, q): return maxi(m, q.fondo), 0)
	var filas: int = (hondo_max + 1 + DELANTE + rng.randi_range(0, 4)) / 2 * 2 + BORDE * 2
	var ih := filas - BORDE * 2

	# Lo que sobra de ancho: unos huecos de sala de venta (en las puntas o entre dos habitaciones) y lo demás,
	# a ensanchar las habitaciones
	var huecos := []   # huecos[i]: sala de venta antes de la habitación i (el último, después de la última)
	huecos.resize(cuartos.size() + 1)
	huecos.fill(0)
	var sobra: int = iw - (cuartos.size() - 1)
	for q in cuartos:
		sobra -= q.ancho
	if sobra < 0:
		return {}
	# (un hueco nuevo gasta una casilla más que su suelo: el tabique de más que hace falta para cerrarlo)
	for i in rng.randi_range(0, 2):
		var i_hueco := rng.randi() % huecos.size()
		if sobra >= HUECO + 1 and huecos[i_hueco] == 0:
			huecos[i_hueco] = HUECO
			sobra -= HUECO + 1
	while sobra > 0:
		var pueden := cuartos.filter(func(q): return q.ancho < ANCHO[1] + (5 if q.aseo else 0))
		if pueden.is_empty() or rng.randf() < 0.25:
			# a un hueco que ya exista (o, si no hay, a una punta)
			var abiertos := []
			for i in huecos.size():
				if huecos[i] > 0:
					abiertos.append(i)
			var i: int = abiertos[rng.randi() % abiertos.size()] if not abiertos.is_empty() else [0, huecos.size() - 1][rng.randi() % 2]
			# un hueco nuevo, como poco HUECO; si no da, se ensancha una habitación aunque pase del máximo
			if huecos[i] == 0 and sobra < HUECO + 1:
				cuartos[rng.randi() % cuartos.size()].ancho += 1
			elif huecos[i] == 0:
				huecos[i] = HUECO
				sobra -= HUECO
			else:
				huecos[i] += 1
		else:
			pueden[rng.randi() % pueden.size()].ancho += 1
		sobra -= 1

	var dueno := PackedInt32Array()
	dueno.resize(cols * filas)
	dueno.fill(-1)
	var salon := {"id": 0, "uso": "tienda", "c0": BORDE, "f0": BORDE, "ancho": iw, "fondo": ih, "puertas": []}
	var salas := [salon]
	for f in range(BORDE, filas - BORDE):
		for c in range(BORDE, cols - BORDE):
			dueno[f * cols + c] = 0
	var c := BORDE
	for i in cuartos.size():
		if huecos[i] > 0:
			c += huecos[i] + 1   # el suelo del hueco y el tabique de la habitación
		var q: Dictionary = cuartos[i]
		var s := {"id": salas.size(), "uso": q.uso, "c0": c, "f0": BORDE, "ancho": q.ancho, "fondo": q.fondo, "puertas": [],
			"aseo": q.aseo}
		salas.append(s)
		c += q.ancho + 1
	var fin: int = c - 1 if huecos[-1] == 0 else c + huecos[-1]
	if fin != cols - BORDE:
		return {}   # las cuentas no cuadran (no debería pasar)
	# sus tabiques (y el muro de fuera, que ya lo es) y luego su suelo
	for s in salas.slice(1):
		for f in range(s.f0, s.f0 + s.fondo + 1):
			for cc in range(s.c0 - 1, s.c0 + s.ancho + 1):
				dueno[f * cols + cc] = -1
	for s in salas.slice(1):
		for f in range(s.f0, s.f0 + s.fondo):
			for cc in range(s.c0, s.c0 + s.ancho):
				dueno[f * cols + cc] = s.id

	# El aseo, en la esquina del fondo de su habitación que no da a la sala de venta (la que tiene muro al lado)
	var puertas := []
	var abrir := func(a: int, b: int, cc: int, f: int) -> void:
		for k in PUERTA:
			dueno[f * cols + cc + k] = -2
		var p := {"a": a, "b": b, "c": cc, "f": f, "ancho": PUERTA, "fondo": 1}
		puertas.append(p)
		salas[a].puertas.append(p)
		salas[b].puertas.append(p)
	if con_aseo:
		var cuarto: Dictionary = salas.filter(func(q): return q.uso == del_aseo)[0]
		var bw := rng.randi_range(ASEO[0], ASEO[1])
		var bh := rng.randi_range(ASEO[0], ASEO[1])
		var izq: bool = dueno[cuarto.f0 * cols + cuarto.c0 - 2] != 0 if rng.randf() < 0.8 else rng.randf() < 0.5
		var bano := {"id": salas.size(), "uso": "bano", "puertas": [], "dueno_bano": cuarto.id,
			"c0": cuarto.c0 if izq else cuarto.c0 + cuarto.ancho - bw, "f0": cuarto.f0, "ancho": bw, "fondo": bh}
		cuarto.bano = bano.id
		for f in range(bano.f0, bano.f0 + bh + 1):
			for cc in range(bano.c0 - 1, bano.c0 + bw + 1):
				if cc < cuarto.c0 or cc >= cuarto.c0 + cuarto.ancho:
					continue
				var dentro: bool = cc >= bano.c0 and cc < bano.c0 + bw and f < bano.f0 + bh
				dueno[f * cols + cc] = bano.id if dentro else -1
		salas.append(bano)
		# su puerta, en el tabique de abajo (lo que da a su habitación)
		var donde := []
		for cc in range(bano.c0 + 1, bano.c0 + bw - PUERTA):
			donde.append(cc)
		if donde.is_empty():
			return {}
		abrir.call(bano.id, cuarto.id, donde[rng.randi() % donde.size()], bano.f0 + bh)

	# Cada habitación de dentro, su puerta a la sala de venta (en su tabique de abajo, con muro a cada lado)
	for s in salas.slice(1):
		if s.uso == "bano":
			continue
		var f: int = s.f0 + s.fondo
		var donde := []
		for cc in range(s.c0 + 1, s.c0 + s.ancho - PUERTA):
			if dueno[(f - 1) * cols + cc] == s.id and dueno[(f - 1) * cols + cc + 1] == s.id:
				donde.append(cc)
		if donde.is_empty():
			return {}
		abrir.call(0, s.id, donde[rng.randi() % donde.size()], f)

	# La puerta de entrada, en la pared de delante (como en los apartamentos)
	var delante := filas - BORDE - 1
	var sitios := []
	for cc in range(BORDE + 2, cols - BORDE - PUERTA - 1):
		sitios.append(cc)
	var t := {"cols": cols, "filas": filas, "dueno": dueno, "salas": salas, "puertas": puertas,
		"entrada": {"c": sitios[rng.randi() % sitios.size()], "lado": "abajo"}, "jefe": false, "tipo": tipo}
	if dueno[delante * cols + t.entrada.c] != 0:
		return {}
	describir(t)
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
