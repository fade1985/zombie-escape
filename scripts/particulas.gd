# Partículas sencillas (las "particles" del JS): chispas, gotitas, gases y anillos que se abren. Todas en un
# solo nodo que las pinta de golpe, en vez de un nodo por chispa. Se usa desde cualquier sitio con
# Particulas.soltar(...) o Particulas.anillo(...): si aún no existe el nodo, se crea en la escena.
#
# Algunas vuelan "de verdad" (las gotas de sangre, los trozos y los casquillos): llevan su altura sobre el suelo
# ("z"), suben, caen por su peso, rebotan y, al quedarse en el suelo, dejan su marca en él (Mancha.gota).
class_name Particulas
extends Node2D

const PESO := 620.0   # lo que tira hacia abajo de las que vuelan (unidades por segundo, cada segundo)

var lista: Array[Dictionary] = []


static func capa(desde: Node) -> Particulas:
	var arbol := desde.get_tree()
	var p := arbol.get_first_node_in_group("particulas") as Particulas
	if p == null:
		p = Particulas.new()
		p.add_to_group("particulas")
		p.z_index = 20   # por encima de los personajes
		arbol.current_scene.add_child(p)
	return p


# Un cuadradito de "tamano" unidades que sale de "donde" con esa velocidad y dura "vida" segundos
static func soltar(desde: Node, donde: Vector2, velocidad: Vector2, color: Color, tamano: float, vida: float) -> void:
	capa(desde).lista.append({"p": donde, "v": velocidad, "c": color, "s": tamano, "t": vida, "max": vida, "r": 0.0})


# Una que vuela: sale de "pie" (el punto del suelo de debajo) a "altura" sobre él, con "velocidad" por el suelo
# y "sube" hacia arriba. Al caer rebota "rebotes" veces y, si hay "suelo", deja allí su marca de color "marca"
# ("marca_tam" es el tamaño de la marca, en unidades). Redonda (gotas) o cuadrada (casquillos)
static func volar(desde: Node, pie: Vector2, altura: float, velocidad: Vector2, sube: float, color: Color,
		tamano: float, suelo: Node = null, marca := Color.TRANSPARENT, marca_tam := Vector2.ZERO,
		redonda := true, borde := false, rebotes := 0, mancha := "Gotas") -> void:
	capa(desde).lista.append({"p": pie, "v": velocidad, "c": color, "s": tamano, "t": 3.0, "max": 3.0, "r": 0.0,
		"z": altura, "vz": sube, "suelo": suelo, "marca": marca, "marca_tam": marca_tam, "redonda": redonda,
		"borde": borde, "rebotes": rebotes, "mancha": mancha})


# Sangre que salta de un golpe: unas gotas hacia donde va el golpe ("hacia"), que caen y manchan el suelo
static func salpicar(desde: Node, suelo: Node, pie: Vector2, altura: float, hacia: Vector2, color: Color, n := 6) -> void:
	var base := hacia.angle() if hacia.length() > 0.1 else randf() * TAU
	for i in n:
		var v := Vector2.from_angle(base + randf_range(-0.7, 0.7)) * randf_range(60.0, 230.0)
		var tam := randf_range(2.0, 5.0)
		volar(desde, pie, altura + randf_range(-8, 8), Vector2(v.x, v.y * 0.6), randf_range(20.0, 140.0), color,
			tam, suelo, Color(color, randf_range(0.45, 0.7)), Vector2.ONE * (4.0 if tam < 4.0 else 8.0))


# El reventón de un zombi al morir (burst en src/game-efectos.js): "n" trozos de su color, redondos y con su
# borde oscuro, que saltan en todas direcciones y caen; y gotas de su sangre, que manchan el suelo donde caen.
# Si "con_anillo", un anillo blanco que se abre
static func reventon(desde: Node, donde: Vector2, color: Color, n: int, radio: float, con_anillo := true,
		sangre := Color.TRANSPARENT, suelo: Node = null) -> void:
	var marca := Color(sangre, 0.6) if sangre.a > 0.0 else Color.TRANSPARENT
	# los trozos: la mitad que antes, más pequeños y manchados de sangre (no todos del mismo verde)
	for i in n / 2:
		var v := Vector2.from_angle(randf() * TAU) * randf_range(60.0, 200.0)
		var tono := color.lerp(sangre, randf_range(0.0, 0.5)) if sangre.a > 0.0 else color
		volar(desde, donde + v.normalized() * radio * 0.3, randf_range(20.0, 44.0), Vector2(v.x, v.y * 0.6),
			randf_range(80.0, 200.0), tono, randf_range(4.0, 7.0), suelo, marca, Vector2.ONE * 4.0, true, true, 1)
	if sangre.a > 0.0:
		for i in n + 4:
			var v := Vector2.from_angle(randf() * TAU) * randf_range(40.0, 260.0)
			volar(desde, donde, randf_range(16.0, 40.0), Vector2(v.x, v.y * 0.6), randf_range(60.0, 200.0), sangre,
				randf_range(2.0, 5.0), suelo, Color(sangre, randf_range(0.45, 0.7)), Vector2.ONE * 4.0)
	if con_anillo:
		anillo(desde, donde, radio, Color.WHITE)


# Un anillo que se abre desde "donde" hasta "radio" (en el suelo: aplastado como las elipses)
static func anillo(desde: Node, donde: Vector2, radio: float, color: Color, vida := 0.3) -> void:
	capa(desde).lista.append({"p": donde, "v": Vector2.ZERO, "c": color, "s": 0.0, "t": vida, "max": vida, "r": radio})


func _process(delta: float) -> void:
	for q in lista:
		q.t -= delta
		q.p += q.v * delta
		if q.has("z"):
			volando(q, delta)
		else:
			q.v *= exp(-delta * 2.0)
	lista = lista.filter(func(q): return q.t > 0.0)
	queue_redraw()


# Sube, cae y, al tocar el suelo, rebota (perdiendo fuerza) o se queda y deja su marca
func volando(q: Dictionary, delta: float) -> void:
	q.vz -= PESO * delta
	q.z += q.vz * delta
	if q.z > 0.0:
		return
	q.z = 0.0
	if q.rebotes > 0:
		q.rebotes -= 1
		q.vz = -q.vz * 0.35
		q.v *= 0.45
		return
	q.t = 0.0
	if is_instance_valid(q.suelo) and q.marca.a > 0.0:
		Mancha.gota(q.suelo, q.p, q.marca, q.marca_tam, q.mancha, 150 if q.mancha == "Casquillos" else 700)


func _draw() -> void:
	for q in lista:
		var k: float = q.t / q.max
		var c: Color = q.c
		if q.r > 0.0:
			# el anillo crece y se apaga
			draw_set_transform(q.p, 0.0, Vector2(1.0, 0.6))
			Formas.arco(self, Vector2.ZERO, q.r * (1.0 - k * 0.6), 0.0, TAU, 48, Color(c, k), 4.0)
			draw_set_transform(Vector2.ZERO)
			continue
		var s: float = maxf(2.0, round(q.s / 2.0) * 2.0)
		var donde: Vector2 = q.p - Vector2(0, q.get("z", 0.0))
		var p: Vector2 = (donde / 2.0).round() * 2.0   # en píxeles enteros del dibujo
		var alfa := 1.0 if q.has("z") else minf(1.0, k * 2.0)
		# redondas: las que lo piden y todas las sueltas que no sean diminutas (ácido, veneno, vómito, destellos);
		# las chispas pequeñas y los casquillos siguen cuadrados
		if q.get("redonda", not q.has("z") and s >= 6.0):
			if q.get("borde", false):
				bolita(p, s + 4.0, Color(0.11, 0.1, 0.17, alfa))
			bolita(p, s, Color(c, alfa))
			continue
		if q.get("borde", false):
			draw_rect(Rect2(p - Vector2(s, s) / 2.0 - Vector2(2, 2), Vector2(s + 4, s + 4)), Color(0.11, 0.1, 0.17, alfa))
		draw_rect(Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), Color(c, alfa))


# Un círculo de pixel art de "lado" unidades, hecho con una fila de píxeles (de 2 unidades) por cada altura
func bolita(centro: Vector2, lado: float, color: Color) -> void:
	var n := maxi(1, roundi(lado / 2.0))   # cuántos píxeles mide de lado a lado
	if n <= 2:
		draw_rect(Rect2(centro - Vector2(n, n), Vector2(n, n) * 2.0), color)
		return
	var r := n / 2.0
	for j in n:
		var dy := j + 0.5 - r
		var media := roundf(sqrt(maxf(r * r - dy * dy, 0.0)))   # medio ancho de esta fila, en píxeles
		if media <= 0.0:
			continue
		draw_rect(Rect2(centro + Vector2(-media, j - r) * 2.0, Vector2(media * 4.0, 2.0)), color)
