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
static var plantillas := {}   # las de la marca negra de las explosiones, por radio (plantilla_quemado)
static var punto: PhysicsPointQueryParameters2D   # la consulta de "¿hay pared aquí?" de salpicon, la misma siempre


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
	quitar_sobrantes()
	var t := ahora()
	var hay_aparece := not aparece.is_empty()
	for i in celdas.size():
		if hay_aparece and i < aparece.size() and aparece[i] > crecido:
			continue
		var c: Array = celdas[i]
		var color: Color = c[1]
		if c.size() > 4:   # sangre que se seca: de su color a uno más oscuro y algo más apagado (c[4], ya calculado)
			var k: float = (t - c[3]) / SECADO
			color = c[4] if k >= 1.0 else color.lerp(c[4], maxf(k, 0.0))
		draw_rect(Rect2(c[0], c[2] if c.size() > 2 else Vector2(CELDA, CELDA)), color)


static func ahora() -> float:
	return Time.get_ticks_msec() / 1000.0


# Una marca pequeña en el suelo (una gota que cae, un casquillo, el rastro del que se arrastra) en el punto
# "donde" (de la escena). Todas las de un sitio van en la misma mancha "nombre", que se queda con las
# "maximo" últimas: así no hace falta un nodo por gota. "tam", en unidades (de 2 en 2)
static func gota(sala: Node, donde: Vector2, color: Color, tam := Vector2(CELDA, CELDA), nombre := "Gotas",
		maximo := 700) -> void:
	if en_muro(donde, tam):
		return   # (encima de una pared, no: 20 nov)
	var m := de_gotas(sala, nombre, maximo)
	var p: Vector2 = (((m.to_local(donde) - tam / 2.0) / 2.0).round() * 2.0)
	m.celdas.append([p, color, tam])
	m.recortar()


# Si un cuadradito de "tam" con centro en "donde" pisa una casilla de muro (recorte.gd: sus cuatro esquinas)
static func en_muro(donde: Vector2, tam: Vector2) -> bool:
	var m := tam / 2.0 - Vector2(0.01, 0.01)
	return Recorte.muro_en(donde - m) or Recorte.muro_en(donde + m) or Recorte.muro_en(donde + Vector2(m.x, -m.y)) 		or Recorte.muro_en(donde + Vector2(-m.x, m.y))


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


# Las celdas de más se quitan una sola vez por fotograma, justo antes de pintar (_draw): con miles de celdas, quitarlas
# en cada gota que cae era copiar la lista entera cientos de veces seguidas (los tirones al reventar muchos zombis
# explosivos, 20 nov). Se ve igual: lo que se pinta nunca pasa del máximo
func recortar() -> void:
	queue_redraw()


func quitar_sobrantes() -> void:
	if maximo_celdas > 0 and celdas.size() > maximo_celdas:
		celdas = celdas.slice(celdas.size() - maximo_celdas)


# La marca de una gota de sangre de un golpe (Particulas.salpicar) al caer: alargada hacia donde iba ("hacia", su
# velocidad por el suelo), más larga cuanto más deprisa y más fina hacia la punta; la gota gorda ("grueso" de 4 a 6),
# con su cuerpo redondo y una cola corta. A veces, una o dos gotitas sueltas un poco más allá. Se va secando (SECADO)
static func salpicon(sala: Node, donde: Vector2, color: Color, hacia: Vector2, grueso: float) -> void:
	var m := de_gotas(sala, "Gotas", MAXIMO_SANGRE)
	m.maximo_celdas = maxi(m.maximo_celdas, MAXIMO_SANGRE)
	var t := ahora()
	var dir := hacia.normalized() if hacia.length() > 1.0 else Vector2.RIGHT
	var largo := clampf(hacia.length() * 0.035, 2.0, 14.0)   # en unidades: de 1 a 7 píxeles del dibujo
	var espacio := m.get_world_2d().direct_space_state
	if punto == null:   # (una sola consulta para todas las gotas: crear una en cada una pesaba con cientos a la vez)
		punto = PhysicsPointQueryParameters2D.new()
		punto.collision_mask = 1   # paredes y muebles
	var seco := Color(color.darkened(0.5), color.a * 0.8)   # el color al secarse del todo (ver _draw)
	var celda := func(centro: Vector2, lado: float) -> void:
		punto.position = centro
		if not espacio.intersect_point(punto, 1).is_empty():
			return   # (el trozo que caería dentro de una pared o de un mueble, no)
		var l := maxf(2.0, roundf(lado / 2.0) * 2.0)
		if en_muro(centro, Vector2(l, l)):
			return   # (ni el que asomaría a una casilla de muro, aunque su choque sea más fino: 20 nov)
		m.celdas.append([((m.to_local(centro) - Vector2(l, l) / 2.0) / 2.0).round() * 2.0, color, Vector2(l, l), t, seco])
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
	if hacia.length() > 1.0 and randf() < 0.35:   # gotitas sueltas, un poco más allá (no si se paró en una pared)
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
	m.material = Recorte.material("suelo")   # (no pasa a las paredes ni al otro lado, como la mancha; 20 nov)
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
	m.material = Recorte.material("suelo")   # (la quemadura no pasa a las paredes ni al otro lado: recorte.gd)
	var o0 := randf() * TAU   # el borde, ondulado: tres ondas (de 3, 5 y 8 bultos) de lado y fuerza al azar
	var f0 := randf_range(0.06, 0.14)
	var o1 := randf() * TAU
	var f1 := randf_range(0.06, 0.14)
	var o2 := randf() * TAU
	var f2 := randf_range(0.06, 0.14)
	var negro := Color("#000000", 0.75)
	var tizne := Color("#120d0b", 0.55)
	# (20 nov: lo que no depende del azar, de la plantilla; y las celdas seguidas de una fila con el mismo color, en un
	# solo rectángulo. Sale la misma mancha, pero con muchos zombis explosivos reventando a la vez ya no da tirones)
	var pl := plantilla_quemado(radio)
	var ps: PackedVector2Array = pl[0]
	var ds: PackedFloat64Array = pl[1]
	var angulos: PackedFloat64Array = pl[2]
	var ruidos: PackedFloat64Array = pl[3]
	var fila := INF
	var fin := INF                 # dónde acaba (en x) el último rectángulo de esta fila
	var ultimo: Array = []
	for i in ps.size():
		var a := angulos[i]
		var borde := 1.0 + sin(a * 3 + o0) * f0
		borde += sin(a * 5 + o1) * f1
		borde += sin(a * 8 + o2) * f2
		var d := ds[i]
		if d > borde + ruidos[i]:
			continue
		var color := negro if d < 0.55 * borde else tizne
		var p := ps[i]
		if p.y == fila and p.x == fin and ultimo[1] == color:
			ultimo[2] = Vector2(ultimo[2].x + CELDA, CELDA)   # (la de al lado, del mismo color: se alarga la de antes)
		else:
			ultimo = [p, color, Vector2(CELDA, CELDA)]
			m.celdas.append(ultimo)
			fila = p.y
		fin = p.x + CELDA
	sala.add_child(m)


# Las celdas que puede tener la marca negra de "radio" (sin los huecos sueltos, que no cambian), con lo que no depende
# del azar: su sitio, lo lejos que está del centro (de 0 a 1 en el borde), su ángulo y su ruido. Se calcula una vez
# por radio (la del zombi explosivo mira unas 2.600 celdas)
static func plantilla_quemado(radio: float) -> Array:
	if plantillas.has(radio):
		return plantillas[radio]
	var ps := PackedVector2Array()
	var ds := PackedFloat64Array()
	var angulos := PackedFloat64Array()
	var ruidos := PackedFloat64Array()
	var lejisimo := 1.0 + 0.14 * 3 + 0.075   # el borde más lejano que puede salir (las ondas y el ruido, al máximo)
	var n := ceili(radio / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var d := Vector2(p.x, p.y / 0.6).length() / radio
			var ruido := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			if d > lejisimo or ruido < 0.12:
				continue   # (ruido < 0.12: algún hueco suelto, para que no sea una mancha lisa)
			ps.append(p)
			ds.append(d)
			angulos.append(atan2(p.y / 0.6, p.x))
			ruidos.append((ruido - 0.5) * 0.15)
	if plantillas.size() > 16:
		plantillas.clear()
	plantillas[radio] = [ps, ds, angulos, ruidos]
	return plantillas[radio]


# La mancha de un zombi derrotado (addDecal en src/game-efectos.js): un borrón ondulado, aplastado como el
# suelo, medio transparente y con tres gotas alrededor. Del color de su sangre
static func sangre(sala: Node, donde: Vector2, radio: float, color: Color) -> void:
	var m := Mancha.new()
	m.position = (donde / CELDA).round() * CELDA
	m.material = Recorte.material("suelo")   # (como la quemadura: no pasa a las paredes ni al otro lado; 20 nov)
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
