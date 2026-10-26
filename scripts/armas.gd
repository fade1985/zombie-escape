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
#   Las tres últimas (el lanzallamas, el lanza ácido y el lanza rayos) eran armas creadas del banco de trabajo
#   hasta el 25 oct; ahora se compran en la tienda de armas como las demás. Llevan además:
#   relleno   no gastan munición de reserva: un objeto de la mochila (la gasolina, el bidón de ácido o la batería, que
#             van en los huecos de la munición) las llena enteras en "recarga" segundos
#   deposito  el lanzallamas, el lanza ácido y el lanza rayos no tienen cargador: un depósito de esos segundos de chorro
#   efecto    lo que hacen (llamarada.gd): "llama", "acido" o "rayo" · cano  hacia dónde apunta el tubo · saltos  el rayo
#             salta a ese número de zombis más, además del primero (la calidad suma)
class_name Armas


# Lo que cuesta cada una en la tienda de armas del ordenador (price en src/weapons.js; 0 = gratis). La fregona
# no se vende: se lleva siempre. El lanzallamas, el lanza ácido y el lanza rayos, las más caras (25 oct)
const PRECIOS := {"cuchillo": 10, "bate": 15, "pistola": 0, "escopeta": 30, "mp5": 40, "pistola_electrica": 45,
	"lanzallamas": 60, "desintegrador": 60}

# La familia de un arma (como las piezas del banco; las secciones de la tienda): "cuerpo" (cuerpo a cuerpo),
# "distancia" (pistola, escopeta y MP5) o "especial" (lanzallamas, lanza ácido y lanza rayos: las de "efecto").
# Por dentro, las de A distancia y las especiales son de tipo "fuego" y van en el mismo hueco
static func familia(id: String) -> String:
	var w: Dictionary = DATOS[id]
	return "cuerpo" if w.tipo == "cuerpo" else ("especial" if w.has("efecto") else "distancia")


# La pieza que gasta en el banco un arma o un arrojable (su id de Lanzables.DATOS): la de su familia (Objetos.PIEZAS)
static func pieza(id: String) -> String:
	return "pieza_" + (familia(id) if DATOS.has(id) else "arrojable")


# Las piezas que cuesta subir un arma o un arrojable a esa calidad en el banco (CALIDADES: "piezas" o "piezas_arrojable")
static func coste(id: String, calidad: int) -> int:
	return CALIDADES[calidad]["piezas" if DATOS.has(id) else "piezas_arrojable"]

# Las calidades de las armas y de los paquetes de arrojables, de peor a mejor (parte 4 de la tienda y las piezas): cada
# arma que lleva Johnny o que hay en el baúl tiene la suya (0 = Normal, la de la tienda; la joyería da una Épica). Se
# ve en el borde de su casilla. Cada una da más daño ("dano") y una cosa de su familia (números provisionales, para
# ajustarlos jugando):
#   cuerpo a cuerpo   el golpe llega más lejos y barre más ancho ("golpe": alcance y abanico)
#   a distancia       cargador más grande ("cargador") y recarga más rápida ("recarga": lo que tarda)
#   especiales        depósito más grande (el lanzallamas, el lanza ácido y el lanza rayos, "deposito") y la descarga
#                     del lanza rayos salta a más zombis ("saltos")
#   arrojables        radio más grande ("radio") y caben más ("unidades"; lanzables.gd)
# Y "piezas": lo que cuesta subir a esa calidad en el banco de trabajo (parte 5), en piezas de su familia (pieza); de
# una en una: las armas, de Normal a Poco común 3, luego 6 a Rara y 10 a Épica (19 en total); los arrojables,
# "piezas_arrojable", más baratos porque el paquete se gasta al lanzarlo: 1, 2 y 4 (7 en total). Provisional (parte 6)
const CALIDADES := [
	{"nombre": "Normal", "color": Color("#8a8494"), "dano": 1.0, "golpe": 1.0, "cargador": 1.0, "recarga": 1.0,
		"deposito": 1.0, "saltos": 0, "radio": 1.0, "unidades": 0, "piezas": 0, "piezas_arrojable": 0},
	{"nombre": "Poco común", "color": Color("#5fd35f"), "dano": 1.2, "golpe": 1.1, "cargador": 1.25, "recarga": 0.85,
		"deposito": 1.25, "saltos": 1, "radio": 1.1, "unidades": 1, "piezas": 3, "piezas_arrojable": 1},
	{"nombre": "Rara", "color": Color("#4aa3ff"), "dano": 1.45, "golpe": 1.2, "cargador": 1.5, "recarga": 0.7,
		"deposito": 1.5, "saltos": 2, "radio": 1.2, "unidades": 2, "piezas": 6, "piezas_arrojable": 2},
	{"nombre": "Épica", "color": Color("#c06bff"), "dano": 1.75, "golpe": 1.3, "cargador": 1.75, "recarga": 0.55,
		"deposito": 1.75, "saltos": 3, "radio": 1.3, "unidades": 3, "piezas": 10, "piezas_arrojable": 4},
]
const EPICA := 3   # la calidad más alta, la que trae el truco
# El truco de la Épica (parte 6), además de lo de su calidad; uno por familia:
#   cuerpo a cuerpo   golpe de gracia: cada "gracia" golpes que dan, uno es crítico seguro (johnny.gd, golpear)
#   a distancia       las balas (y los perdigones) atraviesan a "atraviesa" zombis y siguen (bala.gd)
#   especiales        estallido: el zombi que matan revienta y pasa su efecto (fuego, ácido o calambre) a los que
#                     tiene a menos de "estallido" (ArmasCreadas.estallido)
#   arrojables        racimo: al romperse o explotar sueltan "racimo" más pequeños alrededor, de "racimo_tamano" su
#                     tamaño y su daño (proyectil.gd y granada.gd)
const TRUCO := {"gracia": 4, "atraviesa": 1, "estallido": 80.0, "racimo": 2, "racimo_tamano": 0.5}
const SIEMPRE := {"cuerpo": "fregona", "fuego": "pistola"}   # las que lleva al empezar: en Normal no van al baúl


# ¿Va al baúl? Las armas, todas menos la fregona y la pistola Normales (SIEMPRE: las tiene siempre); los paquetes de
# arrojables (su id de Lanzables.DATOS), los mejorados (los Normales se compran en la tienda y los sueltan los zombis)
static func al_baul(id: String, calidad: int) -> bool:
	if not DATOS.has(id):
		return calidad > 0
	return calidad > 0 or not id in SIEMPRE.values()


# Los datos de un arma con su calidad ya aplicada (sin los atributos de Johnny: eso lo hace johnny.gd, arma_de)
static func con_calidad(id: String, calidad: int) -> Dictionary:
	var w: Dictionary = DATOS[id].duplicate()
	var c: Dictionary = CALIDADES[clampi(calidad, 0, CALIDADES.size() - 1)]
	w.calidad = calidad
	w.dano = w.dano * c.dano
	match familia(id):
		"cuerpo":
			w.alcance = w.alcance * c.golpe
			w.arco = w.arco * c.golpe
		"distancia":
			w.cargador = roundi(w.cargador * c.cargador)
			w.recarga = w.recarga * c.recarga
		"especial":
			if w.has("deposito"):
				w.deposito = w.deposito * c.deposito
			if w.has("saltos"):
				w.saltos = c.saltos   # el lanza rayos: a cuántos zombis más salta la descarga (además del primero)
	return w


# Lo que da una calidad a un arma o a un arrojable (su id de Lanzables.DATOS), para las fichas («Rara: daño +45 %,
# golpe un 20 % más largo y ancho.»). "" la Normal
static func que_da(id: String, calidad: int) -> String:
	if calidad <= 0:
		return ""
	var c: Dictionary = CALIDADES[calidad]
	var extra := ""
	match "arrojable" if not DATOS.has(id) else familia(id):
		"cuerpo":
			extra = "golpe un %d %% más largo y ancho" % roundi((c.golpe - 1.0) * 100)
		"distancia":
			extra = "cargador un %d %% más grande y recarga un %d %% más rápida" % [roundi((c.cargador - 1.0) * 100),
				roundi((1.0 - c.recarga) * 100)]
		"especial":
			extra = "depósito un %d %% más grande" % roundi((c.deposito - 1.0) * 100)
			if DATOS[id].has("saltos"):
				extra += " y la descarga salta a %d %s más" % [c.saltos, "zombi" if c.saltos == 1 else "zombis"]
		"arrojable":
			extra = "radio un %d %% más grande y caben %d más" % [roundi((c.radio - 1.0) * 100), c.unidades]
	var da := "%s: daño +%d %%, %s." % [c.nombre, roundi((c.dano - 1.0) * 100), extra]
	return da if calidad < EPICA else "%s %s" % [da, truco(id)]


# Lo que dice la ficha del truco de la Épica (TRUCO) de un arma o un arrojable
static func truco(id: String) -> String:
	match "arrojable" if not DATOS.has(id) else familia(id):
		"cuerpo":
			return "Truco: cada %d golpes que dan, uno es crítico (doble daño)." % TRUCO.gracia
		"distancia":
			return "Truco: sus balas atraviesan a un zombi y siguen." if TRUCO.atraviesa == 1 else \
				"Truco: sus balas atraviesan a %d zombis y siguen." % TRUCO.atraviesa
		"especial":
			return "Truco: los zombis que mata revientan y pasan su efecto a los de al lado."
	return "Truco: al %s suelta %d más pequeños alrededor." % ["romperse" if id == "molotov" else "explotar", TRUCO.racimo]

# Hacia dónde apunta el tubo en el dibujo quieto del lanzallamas en cada dirección (el del lanza ácido es el mismo: su
# hoja sale de la del lanzallamas), en grados en la pantalla (0 = a la derecha, 90 = abajo), medido en las hojas: las
# diagonales van más tumbadas que 45° (unos 24°), como se ven desde arriba. Con él se elige hacia dónde mira Johnny al
# echar el chorro: la dirección cuyo tubo apunte más hacia él (johnny.gd, mirar_con_chorro)
const CANO_LANZALLAMAS := {"e": 4.0, "se": 23.0, "s": 90.0, "so": 157.0, "o": 170.0, "no": 205.0, "n": 270.0, "ne": 334.0}
# Lo mismo del lanza rayos (el eje del arma en cada dibujo quieto de su hoja): de frente la lleva vertical, con la
# boca hacia el suelo, y de espaldas vertical sobre el hombro, con la boca arriba
const CANO_LANZA_RAYOS := {"e": 4.0, "se": 31.0, "s": 90.0, "so": 146.0, "o": 176.0, "no": 197.0, "n": 270.0, "ne": 341.0}

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
	# el lanzallamas: no dispara, echa una llamarada continua mientras se ataca (llamarada.gd) que llega a 10 casillas
	# ("alcance" y "velocidad" mandan en lo lejos que llega). No tiene cargador (el de 12 no lo usa): tiene un depósito
	# de "deposito" segundos de fuego que se llena entero con una gasolina de la mochila (en "recarga" segundos; las
	# balas no le valen). Su daño es por segundo (era 60 y se bajó a la mitad, 25 oct), y empuja cada medio segundo.
	# Johnny lleva dos bombonas rojas a la espalda y una manguera hasta el tubo (conserje-48-lanzallamas; la llama la
	# pinta el juego) y echa el fuego en la postura quieta de su hoja (la de apuntar, con el piloto encendido); la
	# casilla es la de siempre, de 96x96 con los pies en 48,72. La boca es la punta del tubo de esa postura (donde está
	# el piloto: el píxel del dibujo que más sale hacia donde apunta), medida en la hoja
	"lanzallamas": {
		"nombre": "Lanzallamas", "tipo": "fuego", "dano": 30, "ritmo": 2.5, "alcance": 320.0, "velocidad": 620.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.0, "empuje": 0.5, "cargador": 12, "recarga": 1.5,
		"cartucho": false, "deposito": 8.0, "relleno": "gasolina", "efecto": "llama", "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-lanzallamas.tres"),
		"boca": {"s": Vector2(2, 1), "se": Vector2(26, -13), "e": Vector2(28, -22), "ne": Vector2(24, -39),
			"n": Vector2(8, -52), "no": Vector2(-25, -40), "o": Vector2(-28, -21), "so": Vector2(-24, -10)},
		"cano": CANO_LANZALLAMAS,
	},
	# el desintegrador (en el juego, «Lanza ácido»; por dentro, el id, sus dibujos y el guardado siguen siéndolo): un
	# lanzallamas de ácido. Como el lanzallamas, no dispara: echa un chorro continuo de ácido mientras se ataca
	# (llamarada.gd, con su efecto "acido") que llega a 10 casillas, con un depósito de "deposito" segundos que se llena
	# entero en "recarga" segundos con un bidón de ácido de la mochila (los suelta el gordo); su daño es por segundo,
	# empuja cada medio segundo y, en vez de prenderlos, deja a los zombis la herida de ácido. Su hoja
	# (conserje-48-desintegrador) es la del lanzallamas con las dos bombonas de la espalda en verde ácido y sin la
	# llamita del piloto (tools/hoja_lanza_acido.py), que trae dónde está la punta del tubo en cada dibujo de reposo, de
	# donde cuelga la gota de ácido (goteo.gd); la casilla es la de siempre, de 96x96 con los pies en 48,72. La boca es
	# la punta del tubo de la postura quieta (el píxel del dibujo que más sale hacia donde apunta), medida en la hoja
	"desintegrador": {
		"nombre": "Lanza ácido", "tipo": "fuego", "dano": 30, "ritmo": 2.5, "alcance": 320.0, "velocidad": 620.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.0, "empuje": 0.5, "cargador": 12, "recarga": 1.5,
		"cartucho": false, "deposito": 8.0, "relleno": "bidon_acido", "efecto": "acido", "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-desintegrador.tres"),
		"boca": {"s": Vector2(1, 0), "se": Vector2(24, -11), "e": Vector2(26, -20), "ne": Vector2(24, -33),
			"n": Vector2(9, -45), "no": Vector2(-24, -33), "o": Vector2(-26, -20), "so": Vector2(-25, -11)},
		"cano": CANO_LANZALLAMAS,
	},
	# el lanza rayos: un arma de tamaño escopeta, blanca y gris con una franja de luz celeste en el costado, que Johnny
	# lleva a dos manos (conserje-48-lanza-rayos; antes era un táser pequeño que disparaba chispas sueltas, y desde el
	# 26 oct echa un rayo continuo, como el lanzallamas y el lanza ácido; el id sigue siendo "pistola_electrica"). No
	# dispara: mientras se ataca sale un rayo celeste en zigzag de la punta (llamarada.gd, con su efecto "rayo") que llega
	# a 8 casillas, con un depósito de "deposito" segundos que se llena entero en "recarga" segundos con una batería de
	# la mochila; su daño es por segundo, sin empuje: aturde a los zombis que toca y la descarga salta de cada uno a
	# 1 + "saltos" zombis más, con medio daño. Su hoja se monta con tools/hoja_lanza_rayos.py: la casilla es de 96x104,
	# con los pies en 48,80, y echa el rayo en la postura quieta (de frente la lleva vertical con la boca al suelo y de
	# espaldas vertical sobre el hombro, para que el rayo salga hacia donde Johnny mira). La boca NO sale de arma.py: es
	# la punta del arma de cada postura quieta, medida en la hoja
	"pistola_electrica": {
		"nombre": "Lanza rayos", "tipo": "fuego", "dano": 25, "ritmo": 2.5, "alcance": 256.0, "velocidad": 620.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.0, "empuje": 0.0, "cargador": 12, "recarga": 1.5,
		"cartucho": false, "deposito": 8.0, "relleno": "bateria", "efecto": "rayo", "saltos": 0, "pies": Vector2(48, 80),
		"hoja": preload("res://assets/sprites/conserje-48-lanza-rayos.tres"),
		"boca": {"s": Vector2(-3, 3), "se": Vector2(21, -18), "e": Vector2(26, -30), "ne": Vector2(21, -39),
			"n": Vector2(3, -70), "no": Vector2(-22, -39), "o": Vector2(-26, -30), "so": Vector2(-22, -18)},
		"cano": CANO_LANZA_RAYOS,
	},
}


# Cómo se dice cada tipo de arma en las fichas («Cuerpo a cuerpo · En la mano»)
const HUECOS := {"cuerpo": "Cuerpo a cuerpo", "fuego": "A distancia"}

# El color de una calidad (el borde de las casillas)
static func color(calidad: int) -> Color:
	return CALIDADES[clampi(calidad, 0, CALIDADES.size() - 1)].color


# Cómo se dice una calidad («Rara»)
static func calidad_nombre(calidad: int) -> String:
	return CALIDADES[clampi(calidad, 0, CALIDADES.size() - 1)].nombre


# Cómo se dice un arma (o un arrojable: su id de Lanzables.DATOS) con su calidad: «Bate» o «Bate (Rara)»
static func nombre(id: String, calidad := 0) -> String:
	var es: String = Objetos.nombre(id) if DATOS.has(id) else Lanzables.UNO[id]
	return es if calidad <= 0 else "%s (%s)" % [es, calidad_nombre(calidad)]

# Lo que llena las armas que tienen "relleno" (un objeto de la mochila): cómo se dice uno (en la sala de pruebas de
# armas). Su nombre y su icono, los de cualquier objeto; su aviso cuando ya no queda, en MUNICION
const RELLENOS := {
	"gasolina": {"uno": "una gasolina"},
	"bidon_acido": {"uno": "un bidón de ácido"},
	"bateria": {"uno": "una batería"},
}

# La munición, por tipos (parte 2 del inventario nuevo): cada arma a distancia gasta la de su "municion" (las de
# "relleno", lo que las llena), y la comparten todas las que gastan la misma (la MP5 gasta las balas de la pistola).
# Johnny la lleva en HUECOS_MUNICION huecos y en cada uno caben "hueco" (dos cargadores; si lleva más, ese tipo ocupa
# otro hueco): con todos llenos ya no coge más. "sin": el aviso cuando se le acaba; "para": las armas que la gastan
# (en el inventario). La gasolina, el bidón de ácido y la batería son además objetos (objetos.gd): van en la mochila de
# la partida, pero no ocupan casilla de la mochila, sino de la munición. Las pilas del lanza rayos se quitaron
# del juego el 25 oct: ahora gasta baterías
const MUNICION := {
	"balas": {"nombre": "Balas de pistola", "icono": "municion-pistola", "hueco": 24, "sin": "¡Sin balas!", "para": "la pistola y la MP5"},
	"cartuchos": {"nombre": "Cartuchos", "icono": "municion-escopeta", "hueco": 12, "sin": "¡Sin cartuchos!", "para": "la escopeta"},
	"gasolina": {"nombre": "Gasolina", "icono": "obj-gasolina", "hueco": 3, "sin": "¡Sin gasolina!", "para": "el lanzallamas"},
	"bidon_acido": {"nombre": "Bidón de ácido", "icono": "obj-bidon_acido", "hueco": 3, "sin": "¡Sin ácido!",
		"para": "el lanza ácido"},
	"bateria": {"nombre": "Batería", "icono": "obj-bateria", "hueco": 3, "sin": "¡Sin batería!", "para": "el lanza rayos"},
}
const HUECOS_MUNICION := 8


# El tipo de munición que gasta un arma (MUNICION): las de "relleno", lo que las llena ("" las de cuerpo a cuerpo)
static func municion(id: String) -> String:
	var w := datos(id)
	return w.get("relleno", w.get("municion", ""))


# Los datos de un arma por su id (DATOS)
static func datos(id: String) -> Dictionary:
	return DATOS[id]
