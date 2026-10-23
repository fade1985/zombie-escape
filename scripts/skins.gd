# Las skins de Johnny: otra cara y una ventaja. Se desbloquean haciendo algo en el juego y se quedan para siempre
# ("skins" del guardado); la puesta va en "skin" ("" = el conserje de siempre) y se elige en la taquilla del
# vestuario de la sala de mantenimiento (ui/taquilla.gd; mapa.gd la pone). Tecla de prueba Z: la siguiente, sin
# guardarla.
#
# Cada skin tiene sus propias hojas de Johnny, una por arma: las de siempre con la cabeza cambiada. La cabeza nueva
# se pidió a PixelLab una sola vez, en las 8 direcciones de Johnny quieto (assets/pixellab.json → "skin-portero"),
# y tools/cara.py la pega en todos los dibujos de cada hoja (conserje-48-guardia.png → conserje-48-guardia-portero.png,
# con su .json y su .tres). hoja() da la de la skin, si la tiene.
#
# La primera, el portero (la portera la suelta al caer por primera vez, partida.gd): un viejo de pelo largo blanco
# con coleta y barba blanca, con el pañuelo rojo de siempre. Con ella puesta, la fregona hace un 300 % más de daño
# (× 4, "fregona"; solo la fregona de siempre, no las armas creadas a partir de ella).
#
# La segunda, el glotón (la suelta el Glotón al caer por primera vez, partida.gd): calvo y con la cara convertida en
# una boca enorme llena de dientes, como la del Glotón. Con ella puesta, quien le hace daño lo paga (johnny.gd,
# devolver()): un zombi normal muere al momento y un jefe pierde un 10 % de su vida máxima ("mordisco").
#
# La tercera, el gymbro (la suelta el Gymbro al caer por primera vez, partida.gd): calvo, con el pañuelo rojo de
# siempre y una barba negra. Con ella puesta, las armas cuerpo a cuerpo hacen un 200 % más de daño (× 3, "cuerpo";
# todas las que lleve Johnny en la mano, también las creadas en el banco de trabajo; el golpe de Ninja y los
# martillazos del ferretero, no).
class_name Skins

const LISTA := {
	"portero": {"nombre": "El portero", "desc": "Pelo largo blanco, coleta y barba. La fregona hace un 300 % más de daño.",
		"como": "Mata a la portera por primera vez.", "jefe": "portera", "fregona": 4.0},
	"gloton": {"nombre": "El glotón", "desc": "Calvo y todo boca. Quien te hace daño lo paga: un zombi muere y un jefe pierde un 10 % de vida.",
		"como": "Mata al Glotón por primera vez.", "jefe": "gloton", "mordisco": 0.1},
	"gymbro": {"nombre": "El gymbro", "desc": "Calvo y barbudo. Las armas cuerpo a cuerpo hacen un 200 % más de daño.",
		"como": "Mata al Gymbro por primera vez.", "jefe": "gymbro", "cuerpo": 3.0},
}


# El nombre de una skin ("" = el conserje de siempre)
static func nombre(id: String) -> String:
	return LISTA[id].nombre if id in LISTA else "Conserje"


# La que lleva puesta, según el guardado (si no es ninguna conocida o no la tiene, la de siempre)
static func puesta() -> String:
	var g := Guardado.cargar()
	return g.skin if g.skin in LISTA and g.skin in g.skins else ""


# Se queda con esa skin para siempre (hasta que elija otra)
static func poner(id: String) -> void:
	Guardado.cambiar(func(g): g.skin = id if id in LISTA else "")


# Las que ya se tienen (ids), según el guardado
static func tenidas() -> Array:
	return Guardado.cargar().skins


# La skin que suelta ese jefe la primera vez que cae (partida.gd; "" = ninguna)
static func de_jefe(tipo: String) -> String:
	for id in LISTA:
		if LISTA[id].get("jefe", "") == tipo:
			return id
	return ""


# La apunta para siempre (no se la pone: eso, en la taquilla). Devuelve si es nueva
static func desbloquear(id: String) -> bool:
	if not id in LISTA or id in tenidas():
		return false
	Guardado.cambiar(func(g): g.skins.append(id))
	return true


# La que va después de esa (tecla Z): la de siempre, las de la lista en orden y vuelta a empezar
static func siguiente(id: String) -> String:
	var todas: Array = [""] + LISTA.keys()
	return todas[(todas.find(id) + 1) % todas.size()]


# La hoja de Johnny de esa skin para un arma (la de siempre si la skin no tiene: "" o una sin hacer)
static func hoja(de_siempre: SpriteFrames, id: String) -> SpriteFrames:
	if not id in LISTA:
		return de_siempre
	var ruta := de_siempre.resource_path.trim_suffix(".tres") + "-" + id + ".tres"
	return load(ruta) if ResourceLoader.exists(ruta) else de_siempre


# Por cuánto se multiplica el daño de la fregona con esa skin
static func fregona(id: String) -> float:
	return LISTA[id].get("fregona", 1.0) if id in LISTA else 1.0


# Por cuánto se multiplica el daño de todas las armas cuerpo a cuerpo con esa skin
static func cuerpo(id: String) -> float:
	return LISTA[id].get("cuerpo", 1.0) if id in LISTA else 1.0


# Qué parte de su vida máxima pierde un jefe que le hace daño con esa skin (0 = nada: el poder del glotón no está)
static func mordisco(id: String) -> float:
	return LISTA[id].get("mordisco", 0.0) if id in LISTA else 0.0
