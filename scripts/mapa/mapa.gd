# Monta un sitio de la planta (el pasillo o un apartamento) a partir de sus datos (planta.gd):
#   - el suelo de cada habitación y la tapa de los muros (vistos desde arriba), en un dibujo de fondo
#   - las caras de los muros (de frente, 3 casillas de alto), ordenadas con los personajes
#   - los choques de los muros, las puertas, la llave y, en los baños, el váter y el lavabo de la fase 1
#   - el mapa de por dónde se puede andar (navegación), para que los zombis rodeen tabiques y muebles
#
# Las texturas son las mismas del juego JS (assets/sprites/): cada habitación elige su suelo y su pared con
# una cuenta sobre su posición, así que dos habitaciones iguales de sitio salen iguales.
extends Node2D

signal llave_cogida

const CASILLA := 32
const MURO := 64
const VELO := Color(0.68, 0.68, 0.68)   # la tapa de los muros, oscurecida para que quede por detrás del suelo
const CARA := preload("res://scripts/mapa/cara_pared.gd")
const PUERTA := preload("res://scripts/mapa/puerta.gd")
const VATER := preload("res://escenas/muebles/vater.tscn")
const LAVABO := preload("res://escenas/muebles/lavabo.tscn")
const LLAVE := preload("res://assets/sprites/objeto-llave-puerta.png")
const ESTILO_DE := {"salon": "salon", "jefe": "salon", "cocina": "cocina", "dormitorio": "dormitorio", "bano": "bano"}

var sitio: Dictionary
var cols := 0
var filas := 0
var dueno := PackedInt32Array()   # de quién es cada casilla: su habitación (0, 1...), -1 muro, -2 hueco de puerta
var estilos := {}                 # habitación -> {suelo, pared, techo} (texturas)
var tapa: Texture2D
var alfombra: Texture2D
var cosas: Node2D                 # personajes, muebles y caras de muro, ordenados por su "y"
var puertas: Array = []           # una por salida, en el mismo orden


func montar(datos: Dictionary, llave := Vector2.INF) -> void:
	sitio = datos
	add_to_group("mapa")
	cols = int(sitio.ancho / CASILLA)
	filas = int(sitio.alto / CASILLA)
	if sitio.tipo == "pasillo":
		# un rectángulo con muros de 2 casillas alrededor; todo el suelo es la "habitación" 0
		dueno.resize(cols * filas)
		dueno.fill(-1)
		for f in range(2, filas - 2):
			for c in range(2, cols - 2):
				dueno[f * cols + c] = 0
		estilos[0] = textura("pasillo", "")
		tapa = load("res://assets/sprites/tapa-pasillo.png")
		alfombra = load("res://assets/sprites/alfombra-pasillo.png")
	else:
		dueno = sitio.apt.dueno
		tapa = load("res://assets/sprites/tapa-salon.png")   # la de todo el piso, como en el JS
		for s in sitio.apt.salas:
			var h: int = s.c0 * 7 + s.f0 * 13 + s.casillas
			var estilo: String = ESTILO_DE[s.uso]
			if estilo == "bano":
				estilos[s.id] = textura("bano", "-a" if h % 2 else "-b", "-a" if (h >> 1) % 2 else "-b")
			else:
				estilos[s.id] = textura(estilo, ["-a", "-b", "-c"][h % 3], ["-a", "-b", "-c"][(h / 3) % 3])

	var fondo := Node2D.new()
	fondo.name = "Fondo"
	fondo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fondo.draw.connect(dibujar_fondo.bind(fondo))
	add_child(fondo)
	var navegacion := NavigationRegion2D.new()
	navegacion.name = "Navegacion"
	add_child(navegacion)
	cosas = Node2D.new()
	cosas.name = "Cosas"
	cosas.y_sort_enabled = true
	add_child(cosas)

	poner_muros()
	poner_caras()
	poner_puertas()
	if sitio.tipo == "apartamento":
		amueblar_banos()
	if llave != Vector2.INF:
		poner_llave(llave)
	hornear(navegacion)


func textura(estilo: String, suelo: String, pared := "") -> Dictionary:
	return {"suelo": load("res://assets/sprites/suelo-%s%s.png" % [estilo, suelo]),
		"pared": load("res://assets/sprites/pared-%s%s.png" % [estilo, pared]),
		"techo": load("res://assets/sprites/techo-%s%s.png" % [estilo, pared])}


func es_muro(c: int, f: int) -> bool:
	return c < 0 or f < 0 or c >= cols or f >= filas or dueno[f * cols + c] == -1


# La habitación de una casilla de suelo; los huecos de puerta toman la de al lado
func sala_de(c: int, f: int) -> int:
	var v := dueno[f * cols + c]
	if v != -2:
		return v
	for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]:
		if not es_muro(c + d.x, f + d.y) and dueno[(f + d.y) * cols + c + d.x] >= 0:
			return dueno[(f + d.y) * cols + c + d.x]
	return 0


# En qué habitación está un punto (-1 si es muro o está fuera)
func zona_en(pos: Vector2) -> int:
	var c := int(pos.x / CASILLA)
	var f := int(pos.y / CASILLA)
	if es_muro(c, f):
		return -1
	return sala_de(c, f)


func nombre_zona(zona: int) -> String:
	if sitio.tipo == "pasillo" or zona < 0:
		return ""
	return sitio.apt.salas[zona].nombre


# Suelos y tapas, en píxeles del dibujo (por eso el transform x2). La textura se repite contando desde la
# esquina del mapa, así que las baldosas casan aunque una habitación tenga forma de L.
func dibujar_fondo(lienzo: Node2D) -> void:
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	# la franja de tapa de encima del mapa (la cámara deja ver un poco más arriba, por la cara del muro de arriba)
	lienzo.draw_texture_rect_region(tapa, Rect2(-16, -48, cols * 16 + 32, 48), Rect2(-16, -48, cols * 16 + 32, 48), VELO)
	for f in filas:
		var c := 0
		while c < cols:
			var muro := es_muro(c, f)
			var sala := -1 if muro else sala_de(c, f)
			var fin := c + 1
			while fin < cols and es_muro(fin, f) == muro and (muro or sala_de(fin, f) == sala):
				fin += 1
			var trozo := Rect2(c * 16, f * 16, (fin - c) * 16, 16)
			if muro:
				lienzo.draw_texture_rect_region(tapa, trozo, trozo, VELO)
			else:
				lienzo.draw_texture_rect_region(estilos[sala].suelo, trozo, trozo)
			c = fin
	if alfombra:
		# la alfombra larga del pasillo, por el centro y de punta a punta (a media escala)
		var largo := (cols - 4) * 16 - 56
		var y := filas * 8 - 16
		lienzo.draw_texture_rect_region(alfombra, Rect2(32 + 28, y, largo, 32), Rect2(0, 0, largo * 2, alfombra.get_height()))


# Los choques de los muros: rectángulos grandes (se juntan las casillas seguidas de cada fila, y las filas
# iguales seguidas)
func poner_muros() -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = "Muros"
	cuerpo.add_to_group("obstaculos")
	add_child(cuerpo)
	var abiertos := {}   # "c0,c1" -> [fila de inicio, fila de fin]
	var cajas := []
	for f in filas + 1:
		var tramos := {}
		var c := 0
		while f < filas and c < cols:
			if es_muro(c, f):
				var fin := c
				while fin + 1 < cols and es_muro(fin + 1, f):
					fin += 1
				tramos["%d,%d" % [c, fin]] = true
				c = fin + 1
			else:
				c += 1
		for clave in abiertos.keys():
			if not tramos.has(clave):
				cajas.append([clave, abiertos[clave][0], f - 1])
				abiertos.erase(clave)
		for clave in tramos:
			if not abiertos.has(clave):
				abiertos[clave] = [f]
	for caja in cajas:
		var c0 := int(caja[0].get_slice(",", 0))
		var c1 := int(caja[0].get_slice(",", 1))
		var forma := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2((c1 - c0 + 1) * CASILLA, (caja[2] - caja[1] + 1) * CASILLA)
		forma.shape = rect
		forma.position = Vector2(c0 * CASILLA, caja[1] * CASILLA) + rect.size / 2.0
		cuerpo.add_child(forma)


# Una cara en cada tramo de muro que tiene suelo justo debajo, con el papel de la habitación de debajo
func poner_caras() -> void:
	for f in filas - 1:
		var c := 0
		while c < cols:
			if not (es_muro(c, f) and not es_muro(c, f + 1)):
				c += 1
				continue
			var sala := sala_de(c, f + 1)
			var fin := c + 1
			while fin < cols and es_muro(fin, f) and not es_muro(fin, f + 1) and sala_de(fin, f + 1) == sala:
				fin += 1
			var cara := CARA.new()
			cara.position = Vector2(c * CASILLA, (f + 1) * CASILLA)
			cara.ancho = (fin - c) * CASILLA
			cara.pared = estilos[sala].pared
			cara.techo = estilos[sala].techo
			cara.puede_tapar = f > 1   # el muro de fuera de arriba no tiene a nadie detrás
			cosas.add_child(cara)
			c = fin


func poner_puertas() -> void:
	for i in sitio.salidas.size():
		var salida: Dictionary = sitio.salidas[i]
		var puerta := PUERTA.new()
		puerta.salida = salida
		puerta.indice = i
		puerta.name = "Puerta%d" % i
		match salida.dir:
			"arriba": puerta.position = Vector2(salida.en, MURO)
			"abajo": puerta.position = Vector2(salida.en, sitio.alto - MURO)
			"izquierda": puerta.position = Vector2(MURO, salida.en)
			"derecha": puerta.position = Vector2(sitio.ancho - MURO, salida.en)
		if salida.dir == "arriba":
			# delante de la cara del muro (que tiene su pie en la misma "y")
			puerta.position.y += 1
			cosas.add_child(puerta)
		else:
			add_child(puerta)
			move_child(puerta, 1)   # justo encima del suelo, por debajo de los personajes
		puertas.append(puerta)


# Los baños llevan el váter y el lavabo de la fase 1 contra la pared de arriba, si en ella no hay puerta
# (ni en los laterales cerca de esa pared, para no tapar el paso)
func amueblar_banos() -> void:
	for s in sitio.apt.salas:
		if s.uso != "bano":
			continue
		var libre := true
		for c in range(s.c0, s.c0 + s.ancho):
			if dueno[(s.f0 - 1) * cols + c] == -2:
				libre = false
		for f in range(s.f0, s.f0 + 3):
			if dueno[f * cols + s.c0 - 1] == -2 or dueno[f * cols + s.c0 + s.ancho] == -2:
				libre = false
		if not libre:
			continue
		var vater := VATER.instantiate()
		vater.position = Vector2(s.c0 * CASILLA + 44, s.f0 * CASILLA + 26)
		cosas.add_child(vater)
		var lavabo := LAVABO.instantiate()
		lavabo.position = Vector2(s.c0 * CASILLA + 140, s.f0 * CASILLA + 14)
		cosas.add_child(lavabo)


# La llave del apartamento de la jefa: brilla un poco y sube y baja hasta que Johnny la pisa
func poner_llave(pos: Vector2) -> void:
	var zona := Area2D.new()
	zona.name = "Llave"
	zona.position = pos
	zona.collision_layer = 0
	zona.collision_mask = 2
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 22.0
	forma.shape = circulo
	zona.add_child(forma)
	var dibujo := Sprite2D.new()
	dibujo.texture = LLAVE
	dibujo.scale = Vector2(2, 2)
	dibujo.offset = Vector2(0, -8)
	zona.add_child(dibujo)
	cosas.add_child(zona)
	var vaiven := dibujo.create_tween().set_loops()
	vaiven.tween_property(dibujo, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(dibujo, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	zona.body_entered.connect(func(cuerpo):
		if cuerpo.is_in_group("jugador"):
			llave_cogida.emit()
			zona.queue_free())


# "Hornear" la navegación: Godot mira los muros y los muebles (grupo "obstaculos") y recorta del suelo todo
# lo que choca, dejando el sitio justo para el radio de un zombi (como en la sala de la fase 1)
func hornear(navegacion: NavigationRegion2D) -> void:
	var poligono := NavigationPolygon.new()
	poligono.add_outline(PackedVector2Array([Vector2.ZERO, Vector2(sitio.ancho, 0), Vector2(sitio.ancho, sitio.alto),
		Vector2(0, sitio.alto)]))
	poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poligono.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	poligono.source_geometry_group_name = &"obstaculos"
	poligono.agent_radius = 18.0
	navegacion.navigation_polygon = poligono
	navegacion.bake_navigation_polygon(false)


# Un punto de suelo con sitio alrededor y a más de "distancia" de "lejos_de" (para las teclas de prueba)
func punto_libre(lejos_de: Vector2, distancia: float) -> Vector2:
	for i in 300:
		var pos := Vector2(randf_range(MURO + 30, sitio.ancho - MURO - 30), randf_range(MURO + 30, sitio.alto - MURO - 30))
		if pos.distance_to(lejos_de) < distancia:
			continue
		var bien := true
		for d in [Vector2.ZERO, Vector2(-26, -26), Vector2(26, -26), Vector2(-26, 26), Vector2(26, 26)]:
			if zona_en(pos + d) < 0:
				bien = false
		if bien:
			return pos
	return Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
