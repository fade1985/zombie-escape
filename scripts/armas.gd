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
		"boca": {"s": Vector2(-2, -31), "se": Vector2(23, -20), "e": Vector2(30, -33), "ne": Vector2(27, -45),
			"n": Vector2(-1, -51), "no": Vector2(-20, -47), "o": Vector2(-30, -35), "so": Vector2(-21, -18)},
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
# Cada una es su arma base con algunos números cambiados y un efecto (armas_creadas.gd). Hasta que tengan
# dibujo propio, Johnny usa la hoja del arma base y le salen unas chispitas del color "detalle" en la punta
# ("sube": hacia arriba, como fuego; si no, caen como gotas). Las que ya lo tienen llevan su "hoja" (y su
# "momento", el del golpe en su animación) y no llevan "detalle": de momento, la lanza (conserje-48-lanza, hecha
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
# negro y la batería en la punta, raya blanca y rayos celestes en zigzag a lo largo del cable), con sus hojas de cada skin
# (tools/cara.py). Las de fuego usan el
# cargador como depósito. El daño no está aquí: lo trae cada arma creada (receta + rareza, recetas.gd)
const CREADAS := {
	"lanza": {"base": "fregona", "alcance": 96.0, "arco": 35.0, "momento": 0.222,   # estocada que atraviesa
		"hoja": preload("res://assets/sprites/conserje-48-lanza.tres")},
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
	"lanzallamas": {"base": "pistola", "ritmo": 10.0, "alcance": 170.0, "velocidad": 320.0, "cargador": 40, "recarga": 2.0,
		"empuje": 0.3, "efecto": "llama", "detalle": Color("#ff9f1c"), "sube": true},
	"supersoplete": {"base": "escopeta", "perdigones": 1, "ritmo": 2.0, "alcance": 100.0, "velocidad": 300.0, "cargador": 12,
		"recarga": 2.2, "cartucho": false, "empuje": 1.0, "efecto": "cono", "detalle": Color("#ffd23f"), "sube": true},
	"desintegrador": {"base": "pistola", "ritmo": 12.0, "alcance": 220.0, "velocidad": 400.0, "cargador": 50, "recarga": 2.0,
		"empuje": 0.2, "efecto": "acido", "detalle": Color("#c7e04a")},
	"bumeran": {"base": "pistola", "ritmo": 1.0, "alcance": 300.0, "velocidad": 460.0, "cargador": 1, "recarga": 0.0,
		"empuje": 1.5, "efecto": "bumeran", "detalle": Color("#c0c4d0"), "sin_municion": true},
	# las del centro comercial: chispas que aturden y saltan, y el garfio, que sale y vuelve como el bumerán
	"pistola_electrica": {"base": "pistola", "ritmo": 5.0, "alcance": 230.0, "velocidad": 460.0, "cargador": 30, "recarga": 2.0,
		"empuje": 0.2, "efecto": "chispa", "detalle": Color("#9fe8ff"), "sube": true},
	"garfio": {"base": "pistola", "ritmo": 0.9, "alcance": 320.0, "velocidad": 620.0, "cargador": 1, "recarga": 0.0,
		"empuje": 0.0, "efecto": "garfio", "detalle": Color("#c0c4d0"), "sin_municion": true},
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
