# Las armas: solo datos, con los números del juego de navegador (src/weapons.js).
# Para añadir una, se copia una entrada y se cambian los números (y se le hace su hoja de Johnny).
#   tipo      "cuerpo" (cuerpo a cuerpo) o "fuego" (a distancia)
#   dano      daño por golpe (o por bala; la escopeta suelta varios perdigones)
#   ritmo     ataques por segundo
#   alcance   cuerpo a cuerpo: hasta dónde llega el golpe · de fuego: hasta dónde llega la bala
#   arco      cuerpo a cuerpo: grados del abanico que barre
#   empuje    cuánto echa para atrás al zombi (1 = normal)
#   hoja      las animaciones de Johnny con esa arma en la mano
#   pies      dónde caen los pies de Johnny en su hoja (en píxeles del dibujo): la escopeta es más alta
#   momento   en qué punto de la animación de golpe llega el arma (lo dice la hoja del juego)
#   De fuego: velocidad de la bala, perdigones, abertura (radianes entre el primero y el último perdigón),
#   temblor (cuánto se desvía cada bala al azar), cargador, recarga (segundos) y cartucho (recarga de uno en uno,
#   como la escopeta, y se puede disparar a mitad). "municion": el tipo de munición que gasta (MUNICION). "boca":
#   dónde está la boca del arma en cada dirección, en píxeles desde los pies (sale de la hoja .json del juego)
class_name Armas

const ORDEN := ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5"]   # las teclas 1 a 6

# Lo que cuesta cada una en la tienda de armas del ordenador (price en src/weapons.js; 0 = gratis). La fregona
# no se vende: se lleva siempre
const PRECIOS := {"cuchillo": 10, "bate": 15, "pistola": 0, "escopeta": 30, "mp5": 40}

const DATOS := {
	"fregona": {
		"nombre": "Fregona", "tipo": "cuerpo", "dano": 8, "ritmo": 1.8, "alcance": 62.0, "arco": 140.0,
		"empuje": 2.0, "momento": 0.333, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-guardia.tres"),
	},
	"bate": {
		"nombre": "Bate", "tipo": "cuerpo", "dano": 16, "ritmo": 1.6, "alcance": 66.0, "arco": 110.0,
		"empuje": 1.5, "momento": 0.333, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-bate.tres"),
	},
	"cuchillo": {
		"nombre": "Cuchillo", "tipo": "cuerpo", "dano": 9, "ritmo": 4.0, "alcance": 46.0, "arco": 60.0,
		"empuje": 0.5, "momento": 0.333, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-cuchillo.tres"),
	},
	"pistola": {
		"nombre": "Pistola", "tipo": "fuego", "dano": 10, "ritmo": 2.5, "alcance": 420.0, "velocidad": 620.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.0, "empuje": 0.8, "cargador": 12, "recarga": 1.1,
		"cartucho": false, "municion": "balas", "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-pistola.tres"),
		"boca": {"s": Vector2(0, -30), "se": Vector2(31, -27), "e": Vector2(33, -35), "ne": Vector2(31, -46),
			"n": Vector2(8, -59), "no": Vector2(-33, -43), "o": Vector2(-35, -37), "so": Vector2(-26, -30)},
	},
	"escopeta": {
		"nombre": "Escopeta", "tipo": "fuego", "dano": 7, "ritmo": 1.0, "alcance": 260.0, "velocidad": 540.0,
		"perdigones": 5, "abertura": 0.55, "temblor": 0.06, "empuje": 1.2, "cargador": 6, "recarga": 0.45,
		"cartucho": true, "municion": "cartuchos", "pies": Vector2(48, 96),
		"hoja": preload("res://assets/sprites/conserje-48-escopeta.tres"),
		"boca": {"s": Vector2(1, 9), "se": Vector2(26, -20), "e": Vector2(36, -32), "ne": Vector2(27, -48),
			"n": Vector2(12, -66), "no": Vector2(-28, -48), "o": Vector2(-39, -30), "so": Vector2(-35, -8)},
	},
	"mp5": {
		"nombre": "MP5", "tipo": "fuego", "dano": 4, "ritmo": 8.0, "alcance": 340.0, "velocidad": 640.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.14, "empuje": 0.3, "cargador": 30, "recarga": 1.8,
		"cartucho": false, "municion": "balas", "pies": Vector2(48, 72),   # (las mismas balas que la pistola)
		"hoja": preload("res://assets/sprites/conserje-48-mp5.tres"),
		"boca": {"s": Vector2(-1, 4), "se": Vector2(32, -23), "e": Vector2(33, -31), "ne": Vector2(27, -42),
			"n": Vector2(7, -61), "no": Vector2(-26, -40), "o": Vector2(-32, -30), "so": Vector2(-29, -21)},
	},
}


# Hacia dónde apunta el tubo en el dibujo quieto del lanzallamas en cada dirección (el del lanza ácido es el mismo: su
# hoja sale de la del lanzallamas), en grados en la pantalla (0 = a la derecha, 90 = abajo), medido en las hojas: las
# diagonales van más tumbadas que 45° (unos 24°), como se ven desde arriba. Con él se elige hacia dónde mira Johnny al
# echar el chorro: la dirección cuyo tubo apunte más hacia él (johnny.gd, mirar_con_chorro)
const CANO_LANZALLAMAS := {"e": 4.0, "se": 23.0, "s": 90.0, "so": 157.0, "o": 170.0, "no": 205.0, "n": 270.0, "ne": 334.0}

# ── Armas creadas (fase 7b2; CREADAS de src/armas-creadas.js) ──
# Cada una es su arma base con algunos números cambiados y un efecto (armas_creadas.gd) y lleva su "hoja". Son todas a
# distancia (las de cuerpo a cuerpo y el garfio se quitaron del juego el 25 oct): el lanzallamas
# (conserje-48-lanzallamas: dos bombonas rojas a la espalda y una manguera hasta el tubo, apuntando; la llama la pinta
# el juego) y el desintegrador, en el juego «Lanza ácido» (conserje-48-desintegrador: la
# del lanzallamas con las bombonas verdes de ácido y sin la llamita en la punta del tubo) y la
# pistola eléctrica (conserje-48-pistola-electrica: un táser azul marino con una batería gris pegada debajo, dos electrodos y una descarga
# celeste en zigzag; las chispas que vuelan y saltan las pone el juego, chorro.gd), con sus hojas de cada skin
# (tools/cara.py). El lanzallamas y el lanza ácido tienen un depósito, en
# segundos. El daño no está aquí: lo trae cada arma creada (receta + rareza,
# recetas.gd)
const CREADAS := {
	# "alcance" y "velocidad" mandan en lo lejos que llega el chorro
	# el lanzallamas: no dispara, echa una llamarada continua mientras se ataca (llamarada.gd) que llega a 10 casillas.
	# No tiene cargador: tiene un depósito de "deposito" segundos de fuego que se llena entero con lo de "relleno" (una
	# gasolina de la mochila; en "recarga" segundos, y las balas no le valen). Su daño es por segundo, y empuja cada medio segundo. Johnny
	# lleva dos bombonas a la espalda y echa el fuego en la postura quieta de su hoja (la de apuntar, con el piloto
	# encendido); la casilla es la de siempre, de 96x96 con los pies en 48,72. La boca es la punta del tubo de esa
	# postura (donde está el piloto: el píxel del dibujo que más sale hacia donde apunta), medida en la hoja
	"lanzallamas": {"base": "pistola", "alcance": 320.0, "deposito": 8.0, "recarga": 1.5, "relleno": "gasolina", "empuje": 0.5,
		"efecto": "llama","hoja": preload("res://assets/sprites/conserje-48-lanzallamas.tres"),
		"boca": {"s": Vector2(2, 1), "se": Vector2(26, -13), "e": Vector2(28, -22), "ne": Vector2(24, -39),
			"n": Vector2(8, -52), "no": Vector2(-25, -40), "o": Vector2(-28, -21), "so": Vector2(-24, -10)},
		"cano": CANO_LANZALLAMAS},
	# el desintegrador (en el juego, «Lanza ácido»): un lanzallamas de ácido. Como el lanzallamas, no dispara: echa un chorro
	# continuo de ácido mientras se ataca (llamarada.gd, con su efecto "acido") que llega a 10 casillas, con un depósito
	# de "deposito" segundos que se llena entero en "recarga" segundos con un bidón de ácido de la mochila (los suelta el
	# gordo); su daño es por segundo, empuja cada medio segundo
	# y, en vez de prenderlos, deja a los zombis la herida de ácido. Su hoja es la del lanzallamas con las dos bombonas
	# de la espalda en verde ácido y sin la llamita del piloto (tools/hoja_lanza_acido.py), que trae dónde está la punta
	# del tubo en cada dibujo de reposo, de donde cuelga la gota de ácido (goteo.gd); la casilla es la de siempre, de
	# 96x96 con los pies en 48,72. La boca es la punta del tubo de la postura quieta (el píxel del dibujo que más sale
	# hacia donde apunta), medida en la hoja
	"desintegrador": {"base": "pistola", "alcance": 320.0, "deposito": 8.0, "recarga": 1.5, "relleno": "bidon_acido", "empuje": 0.5,
		"efecto": "acido", "hoja": preload("res://assets/sprites/conserje-48-desintegrador.tres"),
		"boca": {"s": Vector2(1, 0), "se": Vector2(24, -11), "e": Vector2(26, -20), "ne": Vector2(24, -33),
			"n": Vector2(9, -45), "no": Vector2(-24, -33), "o": Vector2(-26, -20), "so": Vector2(-25, -11)},
		"cano": CANO_LANZALLAMAS},
	# la pistola eléctrica: su hoja lleva el retroceso corto y la descarga celeste en zigzag que sale de los dos electrodos del táser
	# (las chispas que vuelan, aturden y saltan al zombi de al lado las pone el juego, armas_creadas.gd y chorro.gd); la casilla es de
	# 180x168, con los pies en 90,88, porque la descarga llega a 88 píxeles a un lado, 86 al otro, 86 hacia arriba y 77 hacia abajo.
	# La boca NO sale de arma.py (las chispas son celestes: no hay fogonazo naranja que buscar, conserje-48-pistola-electrica.json no
	# tiene "muzzle"): es el centro de la chispita de los dos electrodos del dibujo quieto, a mano
	"pistola_electrica": {"base": "pistola", "ritmo": 5.0, "alcance": 230.0, "velocidad": 460.0, "cargador": 30, "recarga": 2.0,
		"municion": "pilas", "empuje": 0.2, "efecto": "chispa", "pies": Vector2(90, 88),
		"hoja": preload("res://assets/sprites/conserje-48-pistola-electrica.tres"),
		"boca": {"s": Vector2(0, -31), "se": Vector2(19, -17), "e": Vector2(22, -30), "ne": Vector2(18, -42),
			"n": Vector2(5, -48), "no": Vector2(-19, -42), "o": Vector2(-22, -30), "so": Vector2(-19, -17)}},
}

# Lo que llena el depósito de las armas que lo tienen (su "relleno", un objeto de la mochila): cómo se dice uno (en la
# sala de pruebas de armas). Su nombre y su icono, los de cualquier objeto; su aviso cuando ya no queda, en MUNICION
const RELLENOS := {
	"gasolina": {"uno": "una gasolina"},
	"bidon_acido": {"uno": "un bidón de ácido"},
}

# La munición, por tipos (parte 2 del inventario nuevo): cada arma a distancia gasta la de su "municion" (las de
# depósito, lo que las llena: su "relleno"), y la comparten todas las que gastan la misma (la MP5 gasta las balas de la
# pistola). Johnny la lleva en HUECOS_MUNICION huecos y en cada uno caben "hueco" (dos cargadores; si lleva más, ese tipo
# ocupa otro hueco): con todos llenos ya no coge más. "sin": el aviso cuando se le acaba; "para": las armas que la gastan
# (en el inventario). La gasolina y el bidón de ácido son además objetos (objetos.gd): van en la mochila de la partida y
# valen para las recetas, pero no ocupan casilla de la mochila, sino de la munición
const MUNICION := {
	"balas": {"nombre": "Balas de pistola", "icono": "municion-pistola", "hueco": 24, "sin": "¡Sin balas!", "para": "la pistola y la MP5"},
	"cartuchos": {"nombre": "Cartuchos", "icono": "municion-escopeta", "hueco": 12, "sin": "¡Sin cartuchos!", "para": "la escopeta"},
	"pilas": {"nombre": "Pilas", "icono": "obj-bateria", "hueco": 60, "sin": "¡Sin pilas!", "para": "la pistola eléctrica"},
	"gasolina": {"nombre": "Gasolina", "icono": "obj-gasolina", "hueco": 3, "sin": "¡Sin gasolina!", "para": "el lanzallamas"},
	"bidon_acido": {"nombre": "Bidón de ácido", "icono": "obj-bidon_acido", "hueco": 3, "sin": "¡Sin ácido!",
		"para": "el lanza ácido"},
}
const HUECOS_MUNICION := 8

# Las armas creadas sacadas del baúl en esta partida. Johnny y el inventario las nombran con un id como
# "creada_3" (así van en los mismos sitios que las de siempre): aquí está a qué arma creada corresponde cada uno.
# Lo que le quedaba en el depósito al guardarla se apunta en "balas"
static var sacadas := {}
static var contador := 0


# Al empezar una partida: las del baúl que se sacaron en la anterior ya se gastaron
static func olvidar_sacadas() -> void:
	sacadas.clear()


# Apunta un arma creada sacada del baúl y devuelve su id
static func apuntar(a: Dictionary) -> String:
	contador += 1
	var id := "creada_%d" % contador
	sacadas[id] = a.duplicate()
	return id


static func es_creada(id: String) -> bool:
	return sacadas.has(id)


# El tipo de munición que gasta un arma (MUNICION): las de depósito, lo que las llena ("" las de cuerpo a cuerpo)
static func municion(id: String) -> String:
	var w := datos(id)
	return w.get("relleno", w.get("municion", ""))


# Los datos de un arma por su id: las de siempre, de DATOS; las creadas, los de su base con lo suyo encima
static func datos(id: String) -> Dictionary:
	if DATOS.has(id):
		return DATOS[id]
	var a: Dictionary = sacadas[id]
	var c: Dictionary = CREADAS[a.receta]
	var w: Dictionary = DATOS[c.base].merged(c, true)
	w.nombre = a.nombre
	w.dano = a.dano
	w.creada = a
	return w
