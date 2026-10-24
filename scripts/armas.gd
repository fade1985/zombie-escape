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
#   como la escopeta, y se puede disparar a mitad). "boca": dónde está la boca del arma en cada dirección, en
#   píxeles desde los pies (sale de la hoja .json del juego)
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
		"cartucho": false, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-pistola.tres"),
		"boca": {"s": Vector2(0, -30), "se": Vector2(31, -27), "e": Vector2(33, -35), "ne": Vector2(31, -46),
			"n": Vector2(8, -59), "no": Vector2(-33, -43), "o": Vector2(-35, -37), "so": Vector2(-26, -30)},
	},
	"escopeta": {
		"nombre": "Escopeta", "tipo": "fuego", "dano": 7, "ritmo": 1.0, "alcance": 260.0, "velocidad": 540.0,
		"perdigones": 5, "abertura": 0.55, "temblor": 0.06, "empuje": 1.2, "cargador": 6, "recarga": 0.45,
		"cartucho": true, "pies": Vector2(48, 96),
		"hoja": preload("res://assets/sprites/conserje-48-escopeta.tres"),
		"boca": {"s": Vector2(1, 9), "se": Vector2(26, -20), "e": Vector2(36, -32), "ne": Vector2(27, -48),
			"n": Vector2(12, -66), "no": Vector2(-28, -48), "o": Vector2(-39, -30), "so": Vector2(-35, -8)},
	},
	"mp5": {
		"nombre": "MP5", "tipo": "fuego", "dano": 4, "ritmo": 8.0, "alcance": 340.0, "velocidad": 640.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.14, "empuje": 0.3, "cargador": 30, "recarga": 1.8,
		"cartucho": false, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-mp5.tres"),
		"boca": {"s": Vector2(-1, 4), "se": Vector2(32, -23), "e": Vector2(33, -31), "ne": Vector2(27, -42),
			"n": Vector2(7, -61), "no": Vector2(-26, -40), "o": Vector2(-32, -30), "so": Vector2(-29, -21)},
	},
}


# ── Armas creadas (fase 7b2; CREADAS de src/armas-creadas.js) ──
# Cada una es su arma base con algunos números cambiados y un efecto (armas_creadas.gd) y lleva su "hoja" (y su
# "momento", el del golpe en su animación): ya no queda ninguna con el dibujo del arma base. (Una arma sin "hoja"
# usaría la del arma base y le saldrían unas chispitas del color "detalle" en la punta, "sube": hacia arriba, como
# fuego, o si no caen como gotas: lo hace ArmasCreadas.detalle(); ninguna lo usa ya.) Son: la lanza (conserje-48-lanza, hecha
# con PixelLab: estocada hacia delante) y el aplastacabezas (conserje-48-aplastacabezas: el barrido del bate con el
# bate de clavos; de espaldas, de arriba abajo), el bate de fuego (conserje-48-bate-fuego: el mismo barrido con
# el bate ardiendo y una estela de llamas), el partecuerpos (conserje-48-partecuerpos: el barrido más ancho con el
# bate de cuchillas, estela blanca con gotas de sangre; de espaldas, de arriba abajo) y la inmovilizadora
# (conserje-48-inmovilizadora: el barrido con el bate con el táser atado a la punta, estela blanca con arcos
# eléctricos celestes), el látigo escorpión (conserje-48-latigo: el latigazo hacia delante, con una raya blanca y
# gotas verdes), la súper maza (conserje-48-supermaza: el giro entero con la maza de hierro, estela blanca circular con
# polvo y piedrecitas), el mangual (conserje-48-mangual: el mismo giro entero, con la cadena estirada y la mancuerna en la
# punta) y el bate helado (conserje-48-bate-helado: el barrido del bate con la cabeza cubierta de escarcha, estela blanca
# y azul clara con copos y cristalitos) y el látigo eléctrico (conserje-48-latigo-electrico: el latigazo con el cable
# negro y la batería en la punta, raya blanca y rayos celestes en zigzag a lo largo del cable) y el lanzallamas
# (conserje-48-lanzallamas: la pistola de agua con el depósito rojo de gas, un tubo largo y la llamarada de la boca) y el
# supersoplete (conserje-48-supersoplete: la escopeta casera hecha de un soplete, con la bombona amarilla, el cañón corto con
# la boca acampanada y una llamarada en cono) y el desintegrador (conserje-48-desintegrador: la pistola de agua con el
# depósito verde de ácido, la boquilla blanca y un chorrito fino de ácido) y el bumerán (conserje-48-bumeran: el gesto de lanzar el
# bumerán de acero con el mango rojo, con el bumerán en la mano al volver a la guardia; el que vuela lo dibuja el juego, bumeran.gd) y la
# pistola eléctrica (conserje-48-pistola-electrica: un táser azul marino con una batería gris pegada debajo, dos electrodos y una descarga
# celeste en zigzag; las chispas que vuelan y saltan las pone el juego, chorro.gd) y el garfio (conserje-48-garfio: el gesto de lanzar el
# gancho de perchas con la cuerda enrollada en la otra mano; el gancho que vuela, la cuerda y el zombi que arrastra los dibuja el juego,
# garfio.gd), con sus hojas de cada skin (tools/cara.py). El súpersoplete usa el cargador como depósito; el
# lanzallamas tiene un depósito de verdad, en segundos. El daño no está aquí: lo trae cada arma creada (receta + rareza,
# recetas.gd)
const CREADAS := {
	# la lanza: su casilla es más ancha (128x96, con los pies en 64,72) porque en la estocada Johnny se queda en su sitio
	# y la lanza avanza (tools/estocada.py)
	"lanza": {"base": "fregona", "alcance": 96.0, "arco": 35.0, "momento": 0.222,   # estocada que atraviesa
		"pies": Vector2(64, 72), "hoja": preload("res://assets/sprites/conserje-48-lanza.tres")},
	"aplastacabezas": {"base": "bate", "empuje": 3.0, "efecto": "aturde", "momento": 0.222,
		"hoja": preload("res://assets/sprites/conserje-48-aplastacabezas.tres")},
	"bate_fuego": {"base": "bate", "efecto": "fuego", "momento": 0.222,
		"hoja": preload("res://assets/sprites/conserje-48-bate-fuego.tres")},
	"partecuerpos": {"base": "bate", "arco": 170.0, "efecto": "sangra", "momento": 0.222,
		"hoja": preload("res://assets/sprites/conserje-48-partecuerpos.tres")},
	"inmovilizadora": {"base": "bate", "efecto": "descarga", "momento": 0.222,
		"hoja": preload("res://assets/sprites/conserje-48-inmovilizadora.tres")},
	# el látigo escorpión: su casilla es más ancha y alta (144x128, con los pies en 72,88) porque la cuerda se estira lejos
	"latigo": {"base": "cuchillo", "alcance": 110.0, "arco": 50.0, "efecto": "veneno", "momento": 0.333,
		"pies": Vector2(72, 88), "hoja": preload("res://assets/sprites/conserje-48-latigo.tres")},
	# la súper maza: su casilla es más ancha y alta (128x112, con los pies en 64,79) porque el giro rodea a Johnny con la estela
	"supermaza": {"base": "fregona", "ritmo": 0.8, "arco": 360.0, "empuje": 2.5, "efecto": "circulo", "momento": 0.3,
		"pies": Vector2(64, 79), "hoja": preload("res://assets/sprites/conserje-48-supermaza.tres")},
	# las del centro comercial (parte 6): el mangual echa muy lejos a todos los de alrededor y los deja un momento
	# tirados (su casilla es 144x128, con los pies en 72,88, porque la cadena estirada llega lejos); el bate helado
	# congela (es el barrido del bate, con su casilla de siempre); el látigo eléctrico es un látigo de cable (casilla 144x128 como
	# la del látigo escorpión, con los pies en 72,88) cuya descarga aturde y salta
	"mangual": {"base": "fregona", "ritmo": 1.2, "alcance": 90.0, "arco": 360.0, "empuje": 4.5, "efecto": "tira", "momento": 0.3,
		"pies": Vector2(72, 88), "hoja": preload("res://assets/sprites/conserje-48-mangual.tres")},
	"bate_helado": {"base": "bate", "efecto": "congela", "momento": 0.222,
		"hoja": preload("res://assets/sprites/conserje-48-bate-helado.tres")},
	"latigo_electrico": {"base": "cuchillo", "alcance": 110.0, "arco": 50.0, "efecto": "descarga", "momento": 0.286,
		"pies": Vector2(72, 88), "hoja": preload("res://assets/sprites/conserje-48-latigo-electrico.tres")},
	# a distancia: "alcance" y "velocidad" mandan en lo lejos que llega el chorro
	# el lanzallamas: no dispara, echa una llamarada continua mientras se ataca (llamarada.gd) que llega a 10 casillas.
	# No tiene cargador: tiene un depósito de "deposito" segundos de fuego que se llena entero con una gasolina de la
	# mochila (en "recarga" segundos; las balas no le valen). Su daño es por segundo, y empuja cada medio segundo. Johnny
	# echa el fuego en la postura quieta de su hoja (la de apuntar, con el piloto encendido); la casilla es de 96x104,
	# con los pies donde siempre. La boca es la punta del tubo de esa postura (donde está el piloto: el píxel del dibujo
	# que más sale hacia donde apunta), no la de conserje-48-lanzallamas.json ("muzzle"), que es el centro de la
	# llamarada del disparo de antes y caía 7 a 13 píxeles más allá: la llama salía despegada del tubo
	"lanzallamas": {"base": "pistola", "alcance": 320.0, "deposito": 8.0, "recarga": 1.5, "empuje": 0.5,
		"efecto": "llama", "hoja": preload("res://assets/sprites/conserje-48-lanzallamas.tres"),
		"boca": {"s": Vector2(0, 10), "se": Vector2(24, -12), "e": Vector2(27, -23), "ne": Vector2(20, -40),
			"n": Vector2(8, -53), "no": Vector2(-21, -39), "o": Vector2(-27, -22), "so": Vector2(-23, -12)}},
	# el supersoplete: su hoja lleva la llamarada en cono de la boca acampanada del soplete (las gotas del cono las pone el
	# juego, armas_creadas.gd); la casilla es de 144x152, con los pies en 72,72, porque la llamarada llega a 69 píxeles a un
	# lado y 77 hacia abajo. La boca NO es la que calcula arma.py (el centro de la llamarada, que cae a 40-50 píxeles de la
	# boquilla): es el piloto del dibujo quieto, a mano (conserje-48-supersoplete.json, "muzzle", tiene los mismos valores)
	"supersoplete": {"base": "escopeta", "perdigones": 1, "ritmo": 2.0, "alcance": 100.0, "velocidad": 300.0, "cargador": 12,
		"recarga": 2.2, "cartucho": false, "empuje": 1.0, "efecto": "cono", "pies": Vector2(72, 72),
		"hoja": preload("res://assets/sprites/conserje-48-supersoplete.tres"),
		"boca": {"s": Vector2(-2, 10), "se": Vector2(25, -22), "e": Vector2(26, -31), "ne": Vector2(24, -41),
			"n": Vector2(10, -52), "no": Vector2(-25, -40), "o": Vector2(-27, -30), "so": Vector2(-26, -22)}},
	# el desintegrador: su hoja lleva el chorrito fino de ácido verde pálido de la boquilla blanca de la pistola de agua (las
	# gotas las pone el juego, armas_creadas.gd y chorro.gd); la casilla es de 152x136, con los pies en 66,90, porque el chorro
	# llega a 62 píxeles a un lado, 82 al otro, 87 hacia arriba y 39 hacia abajo. La boca NO sale de arma.py (con ácido verde no
	# hay fogonazo naranja que buscar: conserje-48-desintegrador.json no tiene "muzzle"): es la punta blanca de la boquilla del
	# dibujo quieto, a mano
	"desintegrador": {"base": "pistola", "ritmo": 12.0, "alcance": 220.0, "velocidad": 400.0, "cargador": 50, "recarga": 2.0,
		"empuje": 0.2, "efecto": "acido", "pies": Vector2(66, 90),
		"hoja": preload("res://assets/sprites/conserje-48-desintegrador.tres"),
		"boca": {"s": Vector2(0, -17), "se": Vector2(18, -19), "e": Vector2(24, -26), "ne": Vector2(25, -36),
			"n": Vector2(6, -47), "no": Vector2(-23, -35), "o": Vector2(-23, -26), "so": Vector2(-19, -19)}},
	# el bumerán segador: su hoja lleva solo el GESTO de lanzar (el brazo hacia delante y la vuelta a la guardia con el bumerán en
	# la mano; el que sale volando y vuelve lo dibuja el juego, bumeran.gd, y andando no hay gesto: la hoja no tiene efectos); la casilla
	# es de 94x92, con los pies en 45,76, porque el brazo llega a 41 píxeles a un lado, 45 al otro, 72 hacia arriba (de espaldas, con
	# el bumerán de canto) y 12 hacia abajo. La boca NO sale de arma.py (no hay fogonazo naranja que buscar:
	# conserje-48-bumeran.json no tiene "muzzle"): es la mano que sujeta el bumerán (el mango rojo) del dibujo quieto, a mano
	"bumeran": {"base": "pistola", "ritmo": 1.0, "alcance": 300.0, "velocidad": 460.0, "cargador": 1, "recarga": 0.0,
		"empuje": 1.5, "efecto": "bumeran", "sin_municion": true, "pies": Vector2(45, 76),
		"hoja": preload("res://assets/sprites/conserje-48-bumeran.tres"),
		"boca": {"s": Vector2(-11, -36), "se": Vector2(-7, -35), "e": Vector2(-1, -37), "ne": Vector2(7, -37),
			"n": Vector2(12, -36), "no": Vector2(9, -38), "o": Vector2(2, -40), "so": Vector2(4, -35)}},
	# la pistola eléctrica: su hoja lleva el retroceso corto y la descarga celeste en zigzag que sale de los dos electrodos del táser
	# (las chispas que vuelan, aturden y saltan al zombi de al lado las pone el juego, armas_creadas.gd y chorro.gd); la casilla es de
	# 180x168, con los pies en 90,88, porque la descarga llega a 88 píxeles a un lado, 86 al otro, 86 hacia arriba y 77 hacia abajo.
	# La boca NO sale de arma.py (las chispas son celestes: no hay fogonazo naranja que buscar, conserje-48-pistola-electrica.json no
	# tiene "muzzle"): es el centro de la chispita de los dos electrodos del dibujo quieto, a mano
	"pistola_electrica": {"base": "pistola", "ritmo": 5.0, "alcance": 230.0, "velocidad": 460.0, "cargador": 30, "recarga": 2.0,
		"empuje": 0.2, "efecto": "chispa", "pies": Vector2(90, 88),
		"hoja": preload("res://assets/sprites/conserje-48-pistola-electrica.tres"),
		"boca": {"s": Vector2(0, -31), "se": Vector2(19, -17), "e": Vector2(22, -30), "ne": Vector2(18, -42),
			"n": Vector2(5, -48), "no": Vector2(-19, -42), "o": Vector2(-22, -30), "so": Vector2(-19, -17)}},
	# el garfio, que sale y vuelve como el bumerán: su hoja lleva solo el GESTO de lanzar (el brazo hacia delante y la vuelta a la guardia
	# con el gancho en la mano y el rollo de cuerda en la otra; el gancho que sale volando, la cuerda y el zombi arrastrado los dibuja el
	# juego, garfio.gd, y andando no hay gesto: la hoja no tiene efectos); la casilla es de 90x88, con los pies en 45,72, porque el brazo
	# llega a 41 píxeles a un lado, 41 al otro, 68 hacia arriba (de espaldas, con el brazo estirado) y 12 hacia abajo. La boca NO sale de
	# arma.py (no hay fogonazo naranja que buscar: conserje-48-garfio.json no tiene "muzzle"): es la mano que sujeta el gancho del dibujo
	# quieto, a mano
	"garfio": {"base": "pistola", "ritmo": 0.9, "alcance": 320.0, "velocidad": 620.0, "cargador": 1, "recarga": 0.0,
		"empuje": 0.0, "efecto": "garfio", "sin_municion": true, "pies": Vector2(45, 72),
		"hoja": preload("res://assets/sprites/conserje-48-garfio.tres"),
		"boca": {"s": Vector2(-15, -30), "se": Vector2(-6, -30), "e": Vector2(-6, -33), "ne": Vector2(-13, -35),
			"n": Vector2(15, -31), "no": Vector2(10, -35), "o": Vector2(7, -34), "so": Vector2(-16, -31)}},
}

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
