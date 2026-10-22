# Estados: lo que te hace pisar un charco (o lo que te pegue un ataque). Como src/estados.js del JS.
#
# Cada charco (charco.gd) dice qué estados pone, y puede cambiar algún número para él (la lejía es tóxica pero
# flojita). La ficha de cada estado:
#   dps:      vida por segundo que quita mientras lo pisas (y al salir, si "despues" > 0)
#   despues:  segundos que te sigue durando al salir del charco (0 = se acaba al salir)
#   resbala:  de 0 (nada) a 1 (como hielo): cuánto cuesta frenar y girar
#   frena:    de 0 (nada) a 1 (quieto): cuánto más lento anda (el frío de la cámara, el calambrazo del agua)
#   zombis:   si también les afecta a los zombis (a la portera, de momento, no)
#   color:    el de los números que saltan y el tinte
#
# Cómo se usa: en cada paso, los charcos llaman a pisar() de quien está dentro (Johnny o un zombi), que lo
# apunta en su "pisando". Luego ese, en su paso, llama a actualizar() con sus "estados" y lo que pisó: se
# renueva lo pisado, se descuenta lo demás y devuelve el daño de este paso.
# La esquiva cruza cualquier charco sin que te pase nada (lo que ya llevabas encima sigue).
# El fuego en los zombis va aparte (zombi.gd: arder), con los números del molotov.
class_name Estados

const LISTA := {
	"toxico": {"dps": 6.0, "despues": 0.0, "zombis": true, "color": Color("#c7e04a")},
	"veneno": {"dps": 4.0, "despues": 3.0, "zombis": false, "color": Color("#9be33b")},
	"fuego": {"dps": 12.0, "despues": 2.0, "zombis": false, "color": Color("#ff9f1c")},
	"resbaladizo": {"resbala": 0.8, "despues": 0.4, "zombis": true, "color": Color("#7fd0ff")},
	"acido": {"dps": 8.0, "despues": 0.0, "zombis": true, "color": Color("#c7e04a")},   # el vómito de Gastroenteritis
	"gases": {"dps": 10.0, "despues": 2.0, "zombis": true, "color": Color("#b5c94a")},  # Flatulento: se pone directamente
	# los peligros del centro comercial (peligros.gd, que pone sus números): el frío de la cámara y el
	# calambrazo del agua con corriente (a los zombis, el agua los aturde: agua.gd)
	"frio": {"dps": 3.0, "despues": 1.5, "frena": 0.4, "zombis": true, "color": Color("#9fd8ff")},
	"calambre": {"despues": 0.4, "frena": 1.0, "zombis": false, "color": Color("#bff4ff")},
	# la porquería del Glotón: mierda con ácido, solo a Johnny. Sus números (dps y despues) los manda siempre
	# peligros/porqueria.gd desde Peligros.PORQUERIA: aquí no se repiten, para que no se desparejen
	"porqueria": {"zombis": false, "color": Color("#c9a227")},
	# la carga del antidisturbios: te tira y tardas un momento en levantarte
	"tirado": {"despues": 0.7, "frena": 1.0, "zombis": false, "color": Color("#ffd23f")},
}

const TICK_ZOMBI := 0.5   # a los zombis el daño de los estados se les da a pellizcos, cada medio segundo


# Apunta en "pisando" los estados de un charco. Si pisa dos con el mismo estado, cuenta el más fuerte
# (con "solo_zombis", solo los que les afectan a ellos)
static func pisar(pisando: Dictionary, estados: Dictionary, solo_zombis := false) -> void:
	for nombre in estados:
		if solo_zombis and not LISTA[nombre].zombis:
			continue
		var f: Dictionary = LISTA[nombre].merged(estados[nombre], true)
		var ya: Dictionary = pisando.get(nombre, {})
		if ya.is_empty() or f.get("dps", 0.0) > ya.get("dps", 0.0) or f.get("resbala", 0.0) > ya.get("resbala", 0.0) \
				or f.get("frena", 0.0) > ya.get("frena", 0.0):
			pisando[nombre] = f


# Una vez por paso para cada uno: renueva lo que pisa, descuenta lo que le queda y devuelve el daño de este paso
static func actualizar(est: Dictionary, pisando: Dictionary, delta: float) -> float:
	var dano := 0.0
	for nombre in LISTA:
		if pisando.has(nombre):
			var f: Dictionary = pisando[nombre]
			est[nombre] = {"t": f.despues, "max": f.despues, "dps": f.get("dps", 0.0), "resbala": f.get("resbala", 0.0),
				"frena": f.get("frena", 0.0), "color": f.color}
			dano += f.get("dps", 0.0) * delta
			continue
		if not est.has(nombre):
			continue
		var e: Dictionary = est[nombre]
		e.t -= delta
		if e.t <= 0.0:
			est.erase(nombre)
			continue
		dano += e.dps * delta
	return dano


# Pone un estado directamente (los gases de Flatulento), sin charco
static func poner(est: Dictionary, nombre: String, segundos: float, dps: float) -> void:
	est[nombre] = {"t": segundos, "max": segundos, "dps": dps, "resbala": 0.0, "frena": 0.0, "color": LISTA[nombre].color}


# El color del estado que más daño hace (el de los números que saltan); blanco si no lleva ninguno
static func color(est: Dictionary) -> Color:
	var mejor := Color.WHITE
	var fuerte := 0.0
	for nombre in est:
		if est[nombre].dps > fuerte:
			fuerte = est[nombre].dps
			mejor = est[nombre].color
	return mejor


# Cuánto agarre le queda al andar (1 = normal, 0 = nada): dentro de la lejía casi nada, y al salir se
# recupera poco a poco
static func agarre(est: Dictionary) -> float:
	if not est.has("resbaladizo"):
		return 1.0
	var r: Dictionary = est.resbaladizo
	var k: float = r.t / r.max if r.max > 0.0 else 1.0
	return 1.0 - r.resbala * k


# Lo que le queda de su velocidad (1 = normal, 0 = quieto): dentro del frío, un 40 % menos, y al salir se
# recupera poco a poco; con el calambrazo, quieto un momento
static func frenado(est: Dictionary) -> float:
	var queda := 1.0
	for nombre in est:
		var e: Dictionary = est[nombre]
		if e.get("frena", 0.0) > 0.0:
			var k: float = e.t / e.max if e.max > 0.0 else 1.0
			queda = minf(queda, 1.0 - e.frena * k)
	return queda


# El tinte del dibujo de quien lleva fuego, veneno, lejía o frío: late suave (el calambrazo, a destellos)
static func tinte(est: Dictionary, t: float) -> Color:
	var late := 0.5 + 0.5 * sin(t * 6.0)
	var c := Color.WHITE
	if est.has("calambre"):
		return Color.WHITE.lerp(LISTA.calambre.color if int(t * 20.0) % 2 else Color("#3a6cff"), 0.75)
	if est.has("fuego"):
		c = Color("#ff7a1c")
	elif est.has("veneno") or est.has("acido") or est.has("gases") or est.has("toxico"):
		c = Color("#7ddc3a")
	elif est.has("porqueria"):
		c = Color("#9a8a2a")   # verde sucio
	elif est.has("resbaladizo") or est.has("frio"):
		c = Color("#9fd8ff")
	else:
		return Color.WHITE
	return Color.WHITE.lerp(c, 0.35 + 0.25 * late)


# Lo que se ve encima de quien lleva un estado: gotitas del veneno, chispas del fuego, salpicones al resbalar,
# vaho al respirar con frío y chispitas azules del calambrazo
static func efectos(nodo: Node2D, est: Dictionary, velocidad: Vector2, delta: float, alto := 40.0, radio := 16.0) -> void:
	var p := nodo.global_position
	if est.has("veneno") and randf() < 6.0 * delta:
		Particulas.soltar(nodo, p + Vector2(randf_range(-radio, radio) * 0.7, -randf_range(0, alto)), Vector2(randf_range(-8, 8), randf_range(30, 60)),
			LISTA.veneno.color if randf() < 0.5 else Color("#4f772d"), randf_range(2, 3), 0.5)
	if est.has("porqueria") and randf() < 6.0 * delta:
		# gotas marrones que caen de los pies y alguna chispita de ácido
		Particulas.soltar(nodo, p + Vector2(randf_range(-radio, radio) * 0.7, randf_range(-6, 4)), Vector2(randf_range(-10, 10), randf_range(20, 50)),
			Color("#6b4a1f") if randf() < 0.65 else Color("#b5d634"), randf_range(2, 3), 0.45)
	if est.has("fuego") and randf() < 30.0 * delta:
		Particulas.soltar(nodo, p + Vector2(randf_range(-radio, radio) * 0.6, 10.0 - randf_range(0, alto)), Vector2(randf_range(-18, 18), randf_range(-130, -60)),
			Llamas.FUEGO[randi() % 4], randf_range(2, 4), 0.4)
	if est.has("resbaladizo") and velocidad.length() > 60.0 and randf() < 10.0 * delta:
		var a := velocidad.angle() + PI + randf_range(-0.8, 0.8)
		Particulas.soltar(nodo, p + Vector2(randf_range(-6, 6), radio * 0.8), Vector2(cos(a) * randf_range(40, 90), sin(a) * randf_range(20, 50) - 30.0),
			Color.WHITE if randf() < 0.5 else LISTA.resbaladizo.color, randf_range(1, 3), 0.35)
	if est.has("frio") and randf() < 2.5 * delta:
		# una bocanada de vaho a la altura de la boca, que sube despacio y se deshace
		var boca := p + Vector2(randf_range(-4, 4), -alto * 0.8)
		for i in 4:
			Particulas.soltar(nodo, boca + Vector2(randf_range(-3, 3), randf_range(-2, 2)), Vector2(randf_range(-12, 12), randf_range(-26, -12)),
				Color(0.92, 0.97, 1.0, 0.45), randf_range(2, 4), randf_range(0.5, 0.8))
	if est.has("calambre") and randf() < 40.0 * delta:
		Particulas.soltar(nodo, p + Vector2(randf_range(-radio, radio), -randf_range(0, alto)), Vector2(randf_range(-40, 40), randf_range(-40, 40)),
			Color.WHITE if randf() < 0.4 else LISTA.calambre.color, 2, 0.15)
