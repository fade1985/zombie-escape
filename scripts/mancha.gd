# Una mancha que se queda en el suelo: lo chamuscado de una granada o la ceniza de un fuego que se ha apagado.
# Es una lista de cuadraditos de pixel art (celdas de 2 píxeles del dibujo). Se quedan hasta salir del sitio;
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
	# crece deprisa al principio y cada vez más despacio, como la sangre que se va extendiendo
	crecido = minf(1.0, crecido + delta / crece * (1.6 - crecido))
	queue_redraw()
	if crecido >= 1.0:
		set_process(false)


func _draw() -> void:
	for i in celdas.size():
		if i < aparece.size() and aparece[i] > crecido:
			continue
		var c: Array = celdas[i]
		draw_rect(Rect2(c[0], c[2] if c.size() > 2 else Vector2(CELDA, CELDA)), c[1])


# Una marca pequeña en el suelo (una gota que cae, un casquillo, el rastro del que se arrastra) en el punto
# "donde" (de la escena). Todas las de un sitio van en la misma mancha "nombre", que se queda con las
# "maximo" últimas: así no hace falta un nodo por gota. "tam", en unidades (de 2 en 2)
static func gota(sala: Node, donde: Vector2, color: Color, tam := Vector2(CELDA, CELDA), nombre := "Gotas",
		maximo := 700) -> void:
	var m: Mancha = sala.get_node_or_null(nombre)
	if m == null:
		m = Mancha.new()
		m.name = nombre
		m.fija = true
		m.maximo_celdas = maximo
		sala.add_child(m)
		if nombre == "Casquillos":
			m.z_index = -1   # encima de la sangre (y del rastro), como los cuerpos
	var p: Vector2 = (((m.to_local(donde) - tam / 2.0) / 2.0).round() * 2.0)
	m.celdas.append([p, color, tam])
	if m.celdas.size() > m.maximo_celdas:
		m.celdas = m.celdas.slice(m.celdas.size() - m.maximo_celdas)
	m.queue_redraw()


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
