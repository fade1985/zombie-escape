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
# con coleta y barba blanca, con el pañuelo rojo de siempre. Con ella puesta, la fregona hace un 100 % más de daño
# (+100 %, "fregona"; solo la fregona de siempre, no las armas creadas a partir de ella).
#
# Lo que dan de daño las skins se SUMA a lo de los talentos (Ataque, Camorrista, Tirador, Puntería), no se
# multiplica: con Ataque 5, Camorrista 5 y el gymbro, +50 +50 +50 = +150 % (johnny.gd, arma_de()). Antes se
# multiplicaba todo y, con una Épica, el jefe final caía en menos de 3 segundos (valoración del equilibrio, 27 oct).
#
# La segunda, el glotón (la suelta el Glotón al caer por primera vez, partida.gd): calvo y con la cara convertida en
# una boca enorme llena de dientes, como la del Glotón. Con ella puesta, quien le hace daño lo paga (johnny.gd,
# devolver()): un zombi normal muere al momento y un jefe pierde un 3 % de su vida máxima ("mordisco"). Era un 10 %
# hasta el 27 oct: con 10 golpes caía cualquier jefe, y bastaba con pegarse a él.
#
# La tercera, el gymbro (la suelta el Gymbro al caer por primera vez, partida.gd): calvo, con el pañuelo rojo de
# siempre y una barba negra. Con ella puesta, las armas cuerpo a cuerpo hacen un 50 % más de daño (+50 %, "cuerpo";
# la fregona, el bate y el cuchillo; el golpe de Ninja y los martillazos del ferretero, no).
#
# La cuarta, el bombero (la suelta el jefe de bomberos al caer por primera vez, partida.gd): un casco de bombero
# ajustado, negro con la raya amarilla reflectante, como el del jefe; tapa el pelo y el pañuelo. Con ella puesta:
#   - las armas que queman hacen un 50 % más de daño (+50 %, "quema"; hasta el 27 oct, × 3): el lanzallamas y el
#     molotov, y lo que siguen ardiendo los zombis que prenden (zombi.gd, prender(): eso, × 1,5). Las armas de fuego
#     de siempre (pistola, escopeta, MP5), no: no queman
#   - Johnny es inmune al fuego ("ignifugo"; johnny.gd, ignifugo()): el cono, las bolas, el aro y los molotovs del jefe
#     de bomberos, el fuego del suelo y de los charcos, el aceite hirviendo del cocinero y el seguir ardiendo al salir.
#     El hachazo del jefe y las explosiones, sí le quitan
class_name Skins

# "efecto": lo que hace llevarla puesta, tal cual sale en la taquilla (cómo es por fuera ya se ve en Johnny)
const LISTA := {
	"portero": {"nombre": "El portero", "efecto": "La fregona hace un 100 % más de daño.",
		"como": "Mata a la portera por primera vez.", "jefe": "portera", "fregona": 2.0},
	"gloton": {"nombre": "El glotón", "efecto": "Quien te hace daño lo paga: un zombi muere y un jefe pierde un 3 % de vida.",
		"como": "Mata al Glotón por primera vez.", "jefe": "gloton", "mordisco": 0.03},
	"gymbro": {"nombre": "El gymbro", "efecto": "Las armas cuerpo a cuerpo hacen un 50 % más de daño.",
		"como": "Mata al Gymbro por primera vez.", "jefe": "gymbro", "cuerpo": 1.5},
	"bombero": {"nombre": "El bombero", "efecto": "Las armas que queman hacen un 50 % más de daño y el fuego no te quema.",
		"como": "Mata al jefe de bomberos por primera vez.", "jefe": "bombero", "quema": 1.5, "ignifugo": true},
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


# La que va después de esa («Siguiente skin» del panel de pruebas): la de siempre, las de la lista en orden y vuelta a empezar
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


# Por cuánto se multiplica el daño de las armas que queman con esa skin (también lo que siguen ardiendo los zombis)
static func quema(id: String) -> float:
	return LISTA[id].get("quema", 1.0) if id in LISTA else 1.0


# Si con esa skin el fuego no le hace nada a Johnny
static func ignifugo(id: String) -> bool:
	return LISTA[id].get("ignifugo", false) if id in LISTA else false


# Qué parte de su vida máxima pierde un jefe que le hace daño con esa skin (0 = nada: el poder del glotón no está)
static func mordisco(id: String) -> float:
	return LISTA[id].get("mordisco", 0.0) if id in LISTA else 0.0
