# Una mancha que se queda en el suelo: lo chamuscado de una granada o la ceniza de un fuego que se ha apagado.
# Es una lista de cuadraditos de pixel art (celdas de 2 píxeles del dibujo). Se quedan hasta dejar la planta;
# si hay demasiadas, se borran las más viejas.
class_name Mancha
extends Node2D

const CELDA := 4.0   # 2 píxeles del dibujo
const MAXIMO := 40

var celdas: Array = []   # [posición, color] de cada cuadradito (o [posición, color, tamaño], si no es una celda)
var fija := false        # las de las gotas, los casquillos y el rastro: no cuentan para el máximo (ver gota)
var maximo_celdas := 0   # si tiene, las celdas más viejas se van borrando al pasarse
# El charco que crece: cada celda aparece cuando "crecido" llega a su "aparece" (de 0 a 1)
var aparece: Array = []
var crecido := 1.0
var crece := 0.0         # lo que tarda en crecer del todo, en segundos
# La sangre de los golpes (salpicon) se seca: cada celda lleva cuándo cayó y se oscurece en SECADO segundos
const SECADO := 8.0
const MAXIMO_SANGRE := 3000   # las celdas de "Gotas" que se quedan, si hay sangre de golpes (cada gota deja varias)
var secando_hasta := 0.0
var repintar := 0.0


func _ready() -> void:
	z_index = -2   # en el suelo, por debajo de los charcos
	set_process(crece > 0.0)
	if fija:
		return
	add_to_group("manchas")
	var todas := get_tree().get_nodes_in_group("manchas")
	if todas.size() > MAXIMO:
		todas[0].queue_free()


func _process(delta: float) -> void:
	if crecido < 1.0:
		# crece deprisa al principio y cada vez más despacio, como la sangre que se va extendiendo
		crecido = minf(1.0, crecido + delta / crece * (1.6 - crecido))
		queue_redraw()
	if secando_hasta > 0.0:
		# la sangre que se seca: se repinta unas 6 veces por segundo (con miles de gotas, cada fotograma sería mucho)
		repintar -= delta
		if repintar <= 0.0:
			repintar = 0.16
			queue_redraw()
		if ahora() > secando_hasta:
			secando_hasta = 0.0
			queue_redraw()
	if crecido >= 1.0 and secando_hasta == 0.0:
		set_process(false)


func _draw() -> void:
	var t := ahora()
	for i in celdas.size():
		if i < aparece.size() and aparece[i] > crecido:
			continue
		var c: Array = celdas[i]
		var color: Color = c[1]
		if c.size() > 3:   # sangre que se seca: de su color a uno más oscuro y algo más apagado
			var k := clampf((t - c[3]) / SECADO, 0.0, 1.0)
			color = color.lerp(Color(color.darkened(0.5), color.a * 0.8), k)
		draw_rect(Rect2(c[0], c[2] if c.size() > 2 else Vector2(CELDA, CELDA)), color)


static func ahora() -> float:
	return Time.get_ticks_msec() / 1000.0


# Una marca pequeña en el suelo (una gota que cae, un casquillo, el rastro del que se arrastra) en el punto
# "donde" (de la escena). Todas las de un sitio van en la misma mancha "nombre", que se queda con las
# "maximo" últimas: así no hace falta un nodo por gota. "tam", en unidades (de 2 en 2)
static func gota(sala: Node, donde: Vector2, color: Color, tam := Vector2(CELDA, CELDA), nombre := "Gotas",
		maximo := 700) -> void:
	var m := de_gotas(sala, nombre, maximo)
	var p: Vector2 = (((m.to_local(donde) - tam / 2.0) / 2.0).round() * 2.0)
	m.celdas.append([p, color, tam])
	m.recortar()


# La mancha de pequeñas marcas "nombre" de ese sitio (se crea la primera vez)
static func de_gotas(sala: Node, nombre: String, maximo: int) -> Mancha:
	var m: Mancha = sala.get_node_or_null(nombre)
	if m == null:
		m = Mancha.new()
		m.name = nombre
		m.fija = true
		m.maximo_celdas = maximo
		sala.add_child(m)
		if nombre == "Casquillos":
			m.z_index = -1   # encima de la sangre (y del rastro), como los cuerpos
	return m


func recortar() -> void:
	if celdas.size() > maximo_celdas:
		celdas = celdas.slice(celdas.size() - maximo_celdas)
	queue_redraw()


# La marca de una gota de sangre de un golpe (Particulas.salpicar) al caer: alargada hacia donde iba ("hacia", su
# velocidad por el suelo), más larga cuanto más deprisa y más fina hacia la punta; la gota gorda ("grueso" de 4 a 6),
# con su cuerpo redondo y una cola corta. A veces, una o dos gotitas sueltas un poco más allá. Se va secando (SECADO)
static func salpicon(sala: Node, donde: Vector2, color: Color, hacia: Vector2, grueso: float) -> void:
	var m := de_gotas(sala, "Gotas", MAXIMO_SANGRE)
	m.maximo_celdas = maxi(m.maximo_celdas, MAXIMO_SANGRE)
	var t := ahora()
	var dir := hacia.normalized() if hacia.length() > 1.0 else Vector2.RIGHT
	var largo := clampf(hacia.length() * 0.035, 2.0, 14.0)   # en unidades: de 1 a 7 píxeles del dibujo
	var celda := func(centro: Vector2, lado: float) -> void:
		var l := maxf(2.0, roundf(lado / 2.0) * 2.0)
		m.celdas.append([((m.to_local(centro) - Vector2(l, l) / 2.0) / 2.0).round() * 2.0, color, Vector2(l, l), t])
	if grueso > 3.0:
		# la gorda: un cuerpo redondeado (una cruz de celdas) y una cola corta y fina hacia donde iba
		var g := roundf(grueso / 2.0) * 2.0
		celda.call(donde, g)
		celda.call(donde + Vector2(g / 2.0, 0), g - 2.0)
		celda.call(donde - Vector2(g / 2.0, 0), g - 2.0)
		for i in int(largo / 4.0):
			celda.call(donde + dir * (g / 2.0 + 2.0 + i * 2.0), 2.0)
	else:
		# la fina: un trazo de su largo, de 4 a 2 de grueso (más gruesa donde golpea primero, al final del vuelo)
		var pasos := maxi(1, int(largo / 2.0))
		for i in pasos:
			celda.call(donde - dir * i * 2.0, 4.0 if i == 0 and largo > 6.0 else 2.0)
	if randf() < 0.35:   # gotitas sueltas, un poco más allá
		for i in randi_range(1, 2):
			celda.call(donde + dir * randf_range(6.0, 14.0) + dir.orthogonal() * randf_range(-4.0, 4.0), 2.0)
	m.secando_hasta = t + SECADO
	m.set_process(true)
	m.recortar()


# El charco de un zombi muerto a golpes o a tiros: sale debajo del cuerpo y se va extendiendo. Oscuro y
# espeso, con el borde ondulado y algún brillo de lo mojado. Del color de su sangre
static func charco(sala: Node, donde: Vector2, radio: float, color: Color) -> void:
	var m := Mancha.new()
	m.position = (donde / CELDA).round() * CELDA
	m.crece = 1.6
	m.crecido = 0.0
	var semilla := randf() * TAU
	var oscuro := Color(color.darkened(0.4), 0.92)
	var medio := Color(color.darkened(0.15), 0.88)
	var borde_c := Color(color, 0.7)
	var brillo := Color(color.lightened(0.45), 0.75)
	var n := ceili(radio * 1.4 / CELDA)
	var lista := []
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var centro := p + Vector2(CELDA, CELDA) / 2.0
			var a := atan2(centro.y / 0.6, centro.x)
			var borde := radio * (0.85 + 0.12 * sin(a * 3.0 + semilla) + 0.08 * sin(a * 7.0 + semilla * 2.0))
			var d := Vector2(centro.x, centro.y / 0.6).length() / borde
			if d > 1.0:
				continue
			var c := oscuro if d < 0.55 else (medio if d < 0.85 else borde_c)
			# el brillo: una rayita arriba a la izquierda
			if y == -roundi(n * 0.35) and x > -roundi(n * 0.45) and x < -roundi(n * 0.1):
				c = brillo
			lista.append([d, p, c])
	lista.sort_custom(func(a, b): return a[0] < b[0])   # del centro hacia fuera, que es como aparece
	for c in lista:
		m.celdas.append([c[1], c[2]])
		m.aparece.append(c[0])
	sala.add_child(m)


# La marca negra de una explosión: un borrón irregular (aplastado, porque el suelo se ve de lado), negro en
# el centro y chamuscado alrededor
static func quemado(sala: Node, donde: Vector2, radio: float) -> void:
	var m := Mancha.new()
	m.position = (donde / CELDA).round() * CELDA
	var ondas := []
	for k in [3, 5, 8]:
		ondas.append([k, randf() * TAU, randf_range(0.06, 0.14)])
	var n := ceili(radio / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var d := Vector2(p.x, p.y / 0.6).length() / radio
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var ruido := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			if d > borde + (ruido - 0.5) * 0.15:
				continue
			var color := Color("#000000", 0.75) if d < 0.55 * borde else Color("#120d0b", 0.55)
			if ruido < 0.12:
				continue   # algún hueco suelto, para que no sea una mancha lisa
			m.celdas.append([p, color])
	sala.add_child(m)


# La mancha de un zombi derrotado (addDecal en src/game-efectos.js): un borrón ondulado, aplastado como el
# suelo, medio transparente y con tres gotas alrededor. Del color de su sangre
static func sangre(sala: Node, donde: Vector2, radio: float, color: Color) -> void:
	var m := Mancha.new()
	m.position = (donde / CELDA).round() * CELDA
	var semilla := randf() * TAU
	var tono := Color(color, 0.35)
	var gotas := []
	for i in 3:
		var a := semilla + i * 2.1
		gotas.append([Vector2(cos(a) * radio * 1.3, sin(a) * radio * 0.8), radio * 0.18])
	var n := ceili(radio * 1.6 / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var centro := p + Vector2(CELDA, CELDA) / 2.0
			var a := atan2(centro.y / 0.65, centro.x)
			var borde := radio * (0.75 + 0.3 * sin(a * 3.0 + semilla))
			var dentro := Vector2(centro.x, centro.y / 0.65).length() <= borde
			for g in gotas:
				dentro = dentro or centro.distance_to(g[0]) <= maxf(g[1], CELDA * 0.7)
			if dentro:
				m.celdas.append([p, tono])
	sala.add_child(m)
