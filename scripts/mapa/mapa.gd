# Monta un sitio de la planta (el pasillo, un apartamento, la sala de mantenimiento o la exposición) a partir
# de sus datos (planta.gd):
#   - el suelo de cada habitación y la tapa de los muros (vistos desde arriba), en un dibujo de fondo
#   - las caras de los muros (de frente, 3 casillas de alto), ordenadas con los personajes
#   - los choques de los muros, las puertas, los muebles (mueble.gd) y la llave
#   - el mapa de por dónde se puede andar (navegación), para que los zombis rodeen tabiques y muebles
#   - la niebla: en un apartamento, las habitaciones que aún no se han pisado se ven a oscuras, y lo que hay
#     dentro ni se ve ni se le puede apuntar (como src/game-mapa.js del juego JS)
#
# Las texturas son las mismas del juego JS (assets/sprites/): cada habitación elige su suelo y su pared con
# una cuenta sobre su posición, así que dos habitaciones iguales de sitio salen iguales.
extends Node2D

signal llave_cogida

const CASILLA := 32
const MURO := 64
const VELO := Color(0.68, 0.68, 0.68)   # la tapa de los muros, oscurecida para que quede por detrás del suelo
const CONTORNO := Color("#1d1b2c")      # la raya oscura "de dibujo animado" donde el suelo toca un muro (como en el JS)
const FILO := Color(1, 1, 1, 0.14)      # el filo de luz de la tapa de los muros, junto al contorno
# la pletina de latón gastado del paso entre dos habitaciones, en rayas de 1 píxel: sombra, brillo, latón y sombra
const PLETINA := [Color("#2a221c"), Color("#b8a37a"), Color("#8a7552"), Color("#4a3c2c")]
const CARA := preload("res://scripts/mapa/cara_pared.gd")
const PUERTA := preload("res://scripts/mapa/puerta.gd")
const MUEBLE := preload("res://scripts/mapa/mueble.gd")
const ORDENADOR := preload("res://scripts/mapa/ordenador.gd")
const ORDENADOR_X := 240.0   # dónde va la mesa del ordenador en la sala de mantenimiento (como en el JS)
const ARMARITO := preload("res://scripts/mapa/armarito.gd")
const ARRIMABLE := preload("res://scripts/mapa/arrimable.gd")
const BANCO_X := 135.0       # el banco de trabajo, a su izquierda, y el baúl, a su derecha (fase 7b)
const BAUL_X := 340.0
const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const APLIQUE := preload("res://assets/sprites/aplique-pared.png")
const LLAVE := preload("res://assets/sprites/objeto-llave-puerta.png")
const MANCHAS := preload("res://assets/sprites/manchas-suelo.png")
const ESTILO_DE := {"salon": "salon", "jefe": "salon", "cocina": "cocina", "dormitorio": "dormitorio", "bano": "bano"}
# Las salas de las tiendas del centro comercial: [suelos (uno al azar), pared]. Sprites suelo-<x>, pared-<x> y
# techo-<x>. El aseo de las tiendas usa los del baño de los pisos (ESTILO_DE).
const ESTILO_TIENDA := {
	"tienda": [["venta-a", "venta-b"], "venta"], "jefe": [["venta-a", "venta-b"], "venta"],
	"almacen": [["almacen"], "almacen"], "camara": [["camara"], "camara"], "cocina": [["cocinaind"], "cocinaind"],
	"taller": [["linoleo"], "almacen"], "taquillas": [["linoleo"], "almacen"], "rebotica": [["linoleo"], "venta"],
	"probadores": [["moqueta"], "venta"]}
# El pasillo de cada edificio (planta.gd lo apunta en "estilo"): su suelo y pared, su tapa y si lleva alfombra
const PASILLOS := {"pasillo": {"tapa": "pasillo", "alfombra": true}, "galeria": {"tapa": "centro", "alfombra": false}}
const NEON := preload("res://scripts/mapa/neon.gd")
# Los peligros de las tiendas del centro comercial (peligros.gd): cada uno con su nodo
const PELIGROS := {"frio": preload("res://scripts/peligros/frio.gd"), "fuego": preload("res://scripts/peligros/fuego.gd"),
	"agua": preload("res://scripts/peligros/agua.gd")}
# Los restos sueltos del centro comercial (sprites resto-<nombre>, tools/centro_sprites.py): el juego los reparte al
# azar por el suelo y las paredes de cada tienda y de la galería, para que haya sangre y destrozo por todas partes
# sin que se note que la textura se repite. Los repetidos en la lista salen más a menudo.
const RESTOS_SUELO := ["sangre", "sangre", "cristales", "cristales", "latas", "ropa", "cascotes", "papeles", "papeles"]
const RESTOS_PARED := ["salpicon", "salpicon", "huellas", "pintada", "agujero"]
const RESTOS_POR_CASILLA := 1.0 / 30.0    # en el suelo, uno de cada tantas casillas libres (entre 4 y 24)
const RESTOS_PARED_CADA := 192.0          # en las paredes, como mucho uno por cada tramo de este largo...
const RESTOS_PARED_SUERTE := 0.45         # ...y no siempre
const OSCURO := Color(0.07, 0.063, 0.11)   # el color de la niebla
const NIEBLA := preload("res://escenas/luces/niebla.gdshader")
const NIEBLA_FONDO := 0.74                 # lo que tapa la niebla a tope (1 = no se ve nada debajo)
const ACLARA := 3.5                       # lo rápido que se aclara una habitación al descubrirla (por segundo)
# los zombis de la exposición, en el orden de las teclas de prueba
const EXPO_ZOMBIS := ["zombi_normal", "zombi_lento", "zombi_rapido", "zombi_explosivo", "zombi_tentaculos",
	"zombi_venenoso", "portera"]
const RUMBOS := ["s", "so", "o", "no", "n", "ne", "e", "se"]

var sitio: Dictionary
var cols := 0
var filas := 0
var dueno := PackedInt32Array()   # de quién es cada casilla: su habitación (0, 1...), -1 muro, -2 hueco de puerta
var estilos := {}                 # habitación -> {suelo, pared, techo} (texturas)
var tapa: Texture2D
var alfombra: Texture2D
var cosas: Node2D                 # personajes, muebles y caras de muro, ordenados por su "y"
var puertas: Array = []           # una por salida, en el mismo orden
var muebles: Array = []
var ordenador: Node2D = null     # la mesa del ordenador (solo en la sala de mantenimiento)
var baul: Node2D = null          # y el baúl y el banco de trabajo
var banco: Node2D = null
var armaritos: Array = []        # los armaritos con botiquín de los baños (armarito.gd)
# La niebla (solo en los apartamentos): por habitación, cuánta oscuridad le queda (1 negro, 0 nada). Las
# habitaciones ya descubiertas se apuntan en el sitio ("vistas"), así siguen claras al volver.
var niebla := {}
var vistas := {}
var caras := {}                   # habitación -> sus caras de muro (llevan su propia niebla)
var velo: Node2D                  # donde se pinta la niebla, por encima de todo
var sala_casilla := PackedInt32Array()   # la habitación de cada casilla (-1 muro), para la niebla
var con_niebla := PackedByteArray()      # 1 en las casillas a las que se les pinta niebla encima
var mascara: Image                # la textura de la niebla, una casilla por píxel (ver pintar_mascara)
var textura_niebla: ImageTexture
var expo_sprites: Array = []      # los zombis de la exposición, que van girando
var expo_t := 0.0
var centro := false               # si es del centro comercial (una tienda o la galería): lleva restos sueltos
var restos: Array = []            # los del suelo: {dibujo (textura), pos, giro, espejo}
var dado_restos := RandomNumberGenerator.new()   # con la semilla del sitio: al volver, todo sigue en su sitio
var peligros: Array = []          # los nodos de los peligros del sitio (frío, fuego, agua con corriente)


func montar(datos: Dictionary, llave := Vector2.INF, tarjeta := false) -> void:
	sitio = datos
	add_to_group("mapa")
	cols = int(sitio.ancho / CASILLA)
	filas = int(sitio.alto / CASILLA)
	if sitio.has("dueno"):
		# un rectángulo con muros de 2 casillas alrededor; todo el suelo es la "habitación" 0
		dueno = sitio.dueno
		if sitio.tipo == "pasillo":
			var estilo: String = sitio.get("estilo", "pasillo")
			estilos[0] = textura(estilo, "")
			tapa = load("res://assets/sprites/tapa-%s.png" % PASILLOS[estilo].tapa)
			if PASILLOS[estilo].alfombra:
				alfombra = load("res://assets/sprites/alfombra-pasillo.png")
		else:
			estilos[0] = textura("mantenimiento", "")
			tapa = load("res://assets/sprites/tapa-generica.png")
	else:
		dueno = sitio.apt.dueno
		var tienda: bool = sitio.get("tienda", "") != ""
		# la de todo el piso, como en el JS; en el centro comercial, la suya
		tapa = load("res://assets/sprites/tapa-centro.png" if tienda else "res://assets/sprites/tapa-salon.png")
		for s in sitio.apt.salas:
			var h: int = s.c0 * 7 + s.f0 * 13 + s.casillas
			if tienda and ESTILO_TIENDA.has(s.uso):
				var suelos: Array = ESTILO_TIENDA[s.uso][0]
				var pared: String = ESTILO_TIENDA[s.uso][1]
				estilos[s.id] = {"suelo": load("res://assets/sprites/suelo-%s.png" % suelos[h % suelos.size()]),
					"pared": load("res://assets/sprites/pared-%s.png" % pared),
					"techo": load("res://assets/sprites/techo-%s.png" % pared)}
				continue
			var estilo: String = ESTILO_DE[s.uso]
			if estilo == "bano":
				estilos[s.id] = textura("bano", "-a" if h % 2 else "-b", "-a" if (h >> 1) % 2 else "-b")
			else:
				estilos[s.id] = textura(estilo, ["-a", "-b", "-c"][h % 3], ["-a", "-b", "-c"][(h / 3) % 3])

	centro = sitio.get("tienda", "") != "" or sitio.get("estilo", "") == "galeria"
	if centro:
		dado_restos.seed = int(sitio.get("surtido", 0)) + 7
		preparar_restos()

	var fondo := Node2D.new()
	fondo.name = "Fondo"
	fondo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fondo.light_mask = Luz.CAPA_SUELO   # el suelo es lo único que recibe sombras (ver luz.gd)
	fondo.z_index = -10   # por debajo de todo: los charcos, las manchas y los cuerpos (z -1 y -2) quedan encima
	fondo.draw.connect(dibujar_fondo.bind(fondo))
	add_child(fondo)
	var tapas := Node2D.new()
	tapas.name = "Tapas"
	tapas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tapas.light_mask = Luz.CAPA_COSAS
	tapas.z_index = -10
	tapas.draw.connect(dibujar_tapas.bind(tapas))
	add_child(tapas)
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
	poner_muebles()
	poner_apliques()
	poner_escaparates()
	poner_peligros()
	for a in sitio.get("armaritos", []):
		var armarito := ARMARITO.new()
		armarito.montar(a)
		armarito.mapa = self
		armarito.zona = zona_en(Vector2(a.x, a.y + 24.0))   # la habitación que tiene delante
		cosas.add_child(armarito)
		armaritos.append(armarito)
	if llave != Vector2.INF:
		poner_llave(llave, tarjeta)
	if sitio.tipo == "expo":
		poner_exposicion()
	hornear(navegacion)
	if sitio.has("apt"):
		preparar_niebla()
	# Johnny y los suyos vienen de otro sitio: vuelven a la capa 1 (en un apartamento, separar_salas les pone
	# la de su habitación)
	Luz.capa_johnny = Luz.CAPA_COSAS
	for quien in get_tree().get_nodes_in_group("jugador") + get_tree().get_nodes_in_group("presa"):
		quien.remove_meta("sala")
		Luz.poner_capa(quien, Luz.CAPA_COSAS)
	set_process(sitio.has("apt") or sitio.tipo == "expo")


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
	if not sitio.has("apt") or zona < 0:
		return ""
	return sitio.apt.salas[zona].nombre


# Las tapas de los muros, aparte del suelo: se quedan en la capa 1, que en un apartamento alumbran las lámparas
# pero no la linterna de Johnny (ver separar_salas). Si no, el haz se subiría encima de los muros y parecería
# que los atraviesa
func dibujar_tapas(lienzo: Node2D) -> void:
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	# la franja de tapa de encima del mapa (la cámara deja ver un poco más arriba, por la cara del muro de arriba)
	lienzo.draw_texture_rect_region(tapa, Rect2(-16, -48, cols * 16 + 32, 48), Rect2(-16, -48, cols * 16 + 32, 48), VELO)
	for f in filas:
		var c := 0
		while c < cols:
			if not es_muro(c, f):
				c += 1
				continue
			var fin := c + 1
			while fin < cols and es_muro(fin, f):
				fin += 1
			var trozo := Rect2(c * 16, f * 16, (fin - c) * 16, 16)
			lienzo.draw_texture_rect_region(tapa, trozo, trozo, VELO)
			c = fin
	# el filo de luz por fuera del mapa, arriba y a la izquierda (como en el JS)
	lienzo.draw_rect(Rect2(2, 2, cols * 16 - 4, 2), FILO)
	lienzo.draw_rect(Rect2(2, 2, 2, filas * 16 - 4), FILO)
	# y donde el muro toca el suelo: el filo de luz en la tapa y el contorno oscuro justo en la raya (mitad en el
	# muro, mitad en el suelo), así cada muro se ve como un bloque con borde y no se funde con el suelo
	for f in filas:
		for c in cols:
			if not es_muro(c, f):
				continue
			var x := c * 16
			var y := f * 16
			if not es_muro(c, f - 1):   # suelo arriba
				lienzo.draw_rect(Rect2(x, y + 1, 16, 1), FILO)
				lienzo.draw_rect(Rect2(x, y - 1, 16, 2), CONTORNO)
			if not es_muro(c, f + 1):   # suelo abajo
				lienzo.draw_rect(Rect2(x, y + 14, 16, 1), FILO)
				lienzo.draw_rect(Rect2(x, y + 15, 16, 2), CONTORNO)
			if not es_muro(c - 1, f):   # suelo a la izquierda
				lienzo.draw_rect(Rect2(x + 1, y, 1, 16), FILO)
				lienzo.draw_rect(Rect2(x - 1, y, 2, 16), CONTORNO)
			if not es_muro(c + 1, f):   # suelo a la derecha
				lienzo.draw_rect(Rect2(x + 14, y, 1, 16), FILO)
				lienzo.draw_rect(Rect2(x + 15, y, 2, 16), CONTORNO)


# La habitación de una casilla (-1 si es muro o está fuera del mapa, -2 si es un hueco de puerta)
func dueno_en(c: int, f: int) -> int:
	return -1 if c < 0 or f < 0 or c >= cols or f >= filas else dueno[f * cols + c]


# Los suelos, en píxeles del dibujo (por eso el transform x2). La textura se repite contando desde la
# esquina del mapa, así que las baldosas casan aunque una habitación tenga forma de L.
func dibujar_fondo(lienzo: Node2D) -> void:
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	for f in filas:
		var c := 0
		while c < cols:
			var muro := es_muro(c, f)
			var sala := -1 if muro else sala_de(c, f)
			var fin := c + 1
			while fin < cols and es_muro(fin, f) == muro and (muro or sala_de(fin, f) == sala):
				fin += 1
			var trozo := Rect2(c * 16, f * 16, (fin - c) * 16, 16)
			if not muro:
				lienzo.draw_texture_rect_region(estilos[sala].suelo, trozo, trozo)
			c = fin
	# Los huecos de puerta entre dos habitaciones: cada suelo llega hasta la mitad del paso (arriba se ha
	# pintado entero con el de una de ellas) y, donde se juntan, la pletina de latón
	for f in filas:
		for c in cols:
			if dueno_en(c, f) != -2:
				continue
			var abajo := dueno_en(c, f + 1)
			var derecha := dueno_en(c + 1, f)
			if dueno_en(c, f - 1) >= 0 and abajo >= 0:   # habitaciones arriba y abajo: pletina tumbada
				var mitad := Rect2(c * 16, f * 16 + 8, 16, 8)
				lienzo.draw_texture_rect_region(estilos[abajo].suelo, mitad, mitad)
				for i in PLETINA.size():
					lienzo.draw_rect(Rect2(c * 16, f * 16 + 6 + i, 16, 1), PLETINA[i])
			elif dueno_en(c - 1, f) >= 0 and derecha >= 0:   # a izquierda y derecha: pletina de pie
				var mitad := Rect2(c * 16 + 8, f * 16, 8, 16)
				lienzo.draw_texture_rect_region(estilos[derecha].suelo, mitad, mitad)
				for i in PLETINA.size():
					lienzo.draw_rect(Rect2(c * 16 + 6 + i, f * 16, 1, 16), PLETINA[i])
	if alfombra:
		# la alfombra larga del pasillo, por el centro y de punta a punta (a media escala)
		var largo := (cols - 4) * 16 - 56
		var y := filas * 8 - 16
		lienzo.draw_texture_rect_region(alfombra, Rect2(32 + 28, y, largo, 32), Rect2(0, 0, largo * 2, alfombra.get_height()))
	# las manchas de sangre de la sala de mantenimiento: cada una gira de 90 en 90 grados y se voltea al azar
	for m in sitio.get("manchas", []):
		lienzo.draw_set_transform(m.pos, m.giro * PI / 2.0, Vector2(-2 if m.espejo else 2, 2))
		lienzo.draw_texture_rect_region(MANCHAS, Rect2(-30, -18, 60, 36), Rect2(m.dibujo * 60, 0, 60, 36))
	# y los restos sueltos del centro comercial, igual (de 90 en 90 grados y volteados)
	for r in restos:
		var t: Texture2D = r.dibujo
		lienzo.draw_set_transform(r.pos, r.giro * PI / 2.0, Vector2(-2 if r.espejo else 2, 2))
		lienzo.draw_texture(t, -(t.get_size() / 2.0).floor())


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
		# y su sombra: la luz de una habitación no pasa a la de al lado a través del tabique
		var sombra := LightOccluder2D.new()
		var huella := OccluderPolygon2D.new()
		var r := Rect2(forma.position - rect.size / 2.0, rect.size)
		huella.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		sombra.occluder = huella
		cuerpo.add_child(sombra)


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
			if centro:
				cara.adornos = restos_de_pared(cara.ancho)
			cosas.add_child(cara)
			if not caras.has(sala):
				caras[sala] = []
			caras[sala].append(cara)
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
			if salida.has("neon"):
				# la fachada de una tienda del centro comercial: su letrero de neón encima de la puerta
				var neon := NEON.new()
				var tipo: Dictionary = Tienda.TIPOS[salida.neon]
				neon.texto = tipo.neon
				neon.color = tipo.color
				neon.semilla = fposmod(sin(salida.en * 12.9898) * 43758.5453, 1.0)
				neon.position = puerta.position
				cosas.add_child(neon)
		else:
			add_child(puerta)
			move_child(puerta, 1)   # justo encima del suelo, por debajo de los personajes
		puertas.append(puerta)


# Los muebles que planta.gd ha decidido para este sitio (muebles.gd), con su variante
func poner_muebles() -> void:
	for m in sitio.get("muebles", []):
		var mueble := MUEBLE.new()
		mueble.montar(m, sitio.surtido)
		cosas.add_child(mueble)
		muebles.append(mueble)
		if m.tipo == "lamp" or m.tipo == "nightstand":
			poner_lampara(mueble, m)
	if sitio.tipo == "mantenimiento":
		ordenador = ORDENADOR.new()
		ordenador.montar(ORDENADOR_X, MURO)
		cosas.add_child(ordenador)
		baul = ARRIMABLE.new()
		baul.montar("Baul", "res://assets/sprites/baul.png", "Baúl", Color("#ffd98a"), BAUL_X, MURO, 60.0, 36.0)
		cosas.add_child(baul)
		banco = ARRIMABLE.new()
		banco.montar("Banco", "res://assets/sprites/banco-trabajo.png", "Banco", Color("#ffb36b"), BANCO_X, MURO, 76.0, 36.0)
		cosas.add_child(banco)


# Las lámparas de pie y las mesillas (con su lamparita) dan luz de verdad; algunas fallan, como los apliques.
# Su propia sombra se quita: la luz sale de dentro de su hueco y lo dejaría todo a oscuras.
func poner_lampara(mueble: Node2D, m: Dictionary) -> void:
	mueble.get_node("Sombra").free()
	var luz := LAMPARA.instantiate()
	luz.semilla = fposmod(sin(m.x * 12.9898 + m.y * 78.233) * 43758.5453, 1.0)
	luz.parpadea = luz.semilla < 0.2
	luz.alto = 72.0 if m.tipo == "lamp" else 56.0
	luz.radio = 210.0 if m.tipo == "lamp" else 150.0
	luz.mapa = self
	luz.zona = m.zona
	if sitio.has("apt"):   # en un apartamento, solo alumbra su habitación (y las tapas de los muros)
		luz.get_node("LuzCosas").range_item_cull_mask = Luz.CAPA_COSAS | Luz.capa_sala(m.zona)
	mueble.add_child(luz)


# Los apliques de la pared de arriba del pasillo (planta.gd): su dibujo y su luz. El nodo va en el pie de la
# cara del muro, para ordenarse con ella; el charco de luz cae 60 unidades más abajo, en el suelo.
func poner_apliques() -> void:
	for a in sitio.get("apliques", []):
		var luz := LAMPARA.instantiate()
		luz.position = Vector2(a.x, MURO + 1)
		luz.semilla = a.semilla
		luz.parpadea = a.parpadea
		luz.alto = 38.0
		luz.suelo = Vector2(0, 60)
		# si el centro de la luz cae dentro de un mueble, su sombra lo dejaría todo a oscuras: más abajo
		for m in muebles:
			var hueco := Rect2(m.datos.x - m.datos.w / 2.0, m.datos.y - m.datos.h / 2.0, m.datos.w, m.datos.h)
			if hueco.grow(4.0).has_point(luz.position + luz.suelo):
				luz.suelo.y = hueco.end.y + 8.0 - luz.position.y
		var dibujo := Sprite2D.new()
		dibujo.texture = APLIQUE
		dibujo.scale = Vector2(2, 2)
		dibujo.position = Vector2(0, -36)
		luz.add_child(dibujo)
		luz.move_child(dibujo, 0)
		cosas.add_child(luz)


# Los peligros de una tienda (peligros.gd): el frío de la cámara, el fuego de la cocina y el agua con corriente.
# Van en el suelo, por debajo de los personajes (lo que va en la pared, el cuadro y el cable, lo ponen ellos en cosas)
func poner_peligros() -> void:
	for d in sitio.get("peligros", []):
		var nodo: Node2D = PELIGROS[d.tipo].new()
		nodo.montar(d, self)
		add_child(nodo)
		peligros.append(nodo)


# Los escaparates de las tiendas, en la pared de arriba de la galería (planta.gd): el dibujo apoyado encima del
# rodapié y, a veces, un salpicón o unas huellas de sangre en el cristal. Van en el pie de la cara del muro, como
# los apliques, para ordenarse con ella.
func poner_escaparates() -> void:
	for e in sitio.get("escaparates", []):
		var nodo := Node2D.new()
		nodo.position = Vector2(e.x, MURO + 1)
		var dibujo := Sprite2D.new()
		dibujo.texture = load("res://assets/sprites/escaparate-%s.png" % e.tienda)
		dibujo.centered = false
		dibujo.scale = Vector2(2, 2)
		var t := dibujo.texture.get_size()
		dibujo.position = Vector2(-t.x, -9 - t.y * 2)   # el pie, 4 píxeles por encima del suelo (el rodapié)
		nodo.add_child(dibujo)
		if dado_restos.randf() < 0.6:
			var mancha := Sprite2D.new()
			mancha.texture = load("res://assets/sprites/resto-%s.png" % ["salpicon", "huellas"][dado_restos.randi() % 2])
			mancha.scale = Vector2(2, 2)
			mancha.flip_h = dado_restos.randf() < 0.5
			mancha.position = dibujo.position + Vector2(dado_restos.randf_range(0.25, 0.75) * t.x * 2, t.y * 0.8)
			nodo.add_child(mancha)
		cosas.add_child(nodo)


# Los restos sueltos del suelo de una tienda o de la galería: en casillas de suelo rodeadas de suelo (para que no
# se monten en un muro), con giro y volteo al azar
func preparar_restos() -> void:
	var libres := []
	for f in range(1, filas - 1):
		for c in range(1, cols - 1):
			if dueno[f * cols + c] >= 0 and not (es_muro(c - 1, f) or es_muro(c + 1, f) or es_muro(c, f - 1) or es_muro(c, f + 1)):
				libres.append(Vector2(c, f))
	if libres.is_empty():
		return
	var cuantos := clampi(roundi(libres.size() * RESTOS_POR_CASILLA), 4, 24)
	for i in cuantos:
		var casilla: Vector2 = libres[dado_restos.randi() % libres.size()]
		var nombre: String = RESTOS_SUELO[dado_restos.randi() % RESTOS_SUELO.size()]
		restos.append({"dibujo": load("res://assets/sprites/resto-%s.png" % nombre),
			"pos": (casilla + Vector2(0.5, 0.5)) * CASILLA + Vector2(dado_restos.randi_range(-4, 4), dado_restos.randi_range(-4, 4)) * 2.0,
			"giro": dado_restos.randi() % 4, "espejo": dado_restos.randf() < 0.5})


# Los restos de una cara de muro de "ancho" unidades: [{dibujo, x, y}] en píxeles del dibujo, contando desde la
# esquina de abajo a la izquierda de la cara (cara_pared.gd los pinta encima del papel)
func restos_de_pared(ancho: float) -> Array:
	var lista := []
	var tramos := floori(ancho / RESTOS_PARED_CADA)
	for i in tramos:
		if dado_restos.randf() > RESTOS_PARED_SUERTE:
			continue
		var t: Texture2D = load("res://assets/sprites/resto-%s.png" % RESTOS_PARED[dado_restos.randi() % RESTOS_PARED.size()])
		var tramo := RESTOS_PARED_CADA / 2.0   # en píxeles del dibujo
		var x := i * tramo + dado_restos.randf_range(0.0, maxf(0.0, tramo - t.get_width()))
		var y := -dado_restos.randf_range(t.get_height() + 6.0, 44.0)   # sin pisar el rodapié ni la moldura
		lista.append({"dibujo": t, "x": floorf(x), "y": floorf(y)})
	return lista


# ═════════════ Niebla ═════════════

func preparar_niebla() -> void:
	vistas = sitio.get_or_add("vistas", {})
	for s in sitio.apt.salas:
		niebla[s.id] = 0.0 if vistas.has(s.id) else 1.0
	# De qué habitación es cada casilla (-1 los muros) y si se le pinta niebla encima. Las casillas que tapa la
	# cara de un muro de más abajo (las dos últimas filas antes de un tabique) no: ya las tapa esa cara, que
	# lleva la niebla de su habitación (si no, la cara de una habitación descubierta quedaría a oscuras)
	sala_casilla.resize(cols * filas)
	con_niebla.resize(cols * filas)
	for f in filas:
		for c in cols:
			sala_casilla[f * cols + c] = -1 if es_muro(c, f) else sala_de(c, f)
			con_niebla[f * cols + c] = 0 if es_muro(c, f) or tapada(c, f) else 1
	# Se pinta de una vez, con el shader de la niebla y una textura de una casilla por píxel (ver el shader)
	mascara = Image.create(cols, filas, false, Image.FORMAT_RGBA8)
	pintar_mascara()
	textura_niebla = ImageTexture.create_from_image(mascara)
	velo = Node2D.new()
	velo.name = "Niebla"
	velo.light_mask = 0   # las lámparas no la aclaran
	velo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # para difuminar entre casillas
	var sombra := ShaderMaterial.new()
	sombra.shader = NIEBLA
	sombra.set_shader_parameter("oscuro", OSCURO)
	sombra.set_shader_parameter("fondo", NIEBLA_FONDO)
	velo.material = sombra
	velo.draw.connect(func():
		velo.draw_texture_rect(textura_niebla, Rect2(0, 0, cols * CASILLA, filas * CASILLA), false))
	add_child(velo)
	actualizar_niebla(0.0)


# La textura de la niebla: en rojo, lo oscura que está cada casilla (los muros toman la más oscura de al lado,
# para que la niebla no se aclare al llegar a una pared, solo al llegar a una puerta); en verde, si se pinta
func pintar_mascara() -> void:
	for f in filas:
		for c in cols:
			var n := 0.0
			var sala := sala_casilla[f * cols + c]
			if sala >= 0:
				n = niebla.get(sala, 0.0)
			else:
				for df in [-1, 0, 1]:
					for dc in [-1, 0, 1]:
						var c2: int = c + dc
						var f2: int = f + df
						if c2 >= 0 and f2 >= 0 and c2 < cols and f2 < filas and sala_casilla[f2 * cols + c2] >= 0:
							n = maxf(n, niebla.get(sala_casilla[f2 * cols + c2], 0.0))
			mascara.set_pixel(c, f, Color(n, con_niebla[f * cols + c], 0.0, 1.0))


# ¿Tapa esta casilla de suelo la cara de un muro de debajo?
func tapada(c: int, f: int) -> bool:
	for k in [1, 2]:
		if es_muro(c, f + k) and f + k + 1 < filas and not es_muro(c, f + k + 1):
			return true
	return false


# Descubre la habitación en la que está Johnny y, si está en una puerta o pegado a ella, las dos que comunica;
# y va aclarando las descubiertas
func actualizar_niebla(delta: float) -> void:
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and johnny.get_parent() == cosas:
		var c := int(johnny.position.x / CASILLA)
		var f := int(johnny.position.y / CASILLA)
		var aqui := zona_en(johnny.position)
		if aqui >= 0:
			vistas[aqui] = true
		for d in sitio.apt.puertas:
			if d.get("cerrada", false):
				continue   # la puerta del baño del superviviente: no deja ver lo de dentro (supervivientes.gd)
			if c >= d.c - 1 and c <= d.c + d.ancho and f >= d.f - 1 and f <= d.f + d.fondo:
				vistas[d.a] = true
				vistas[d.b] = true
	var cambia := delta == 0.0
	for sala in niebla:
		if vistas.has(sala) and niebla[sala] > 0.0:
			niebla[sala] = maxf(0.0, niebla[sala] - delta * ACLARA)
			cambia = true
	if not cambia:
		return
	pintar_mascara()
	textura_niebla.update(mascara)
	for sala in caras:
		for cara in caras[sala]:
			if cara.niebla != niebla.get(sala, 0.0):
				cara.niebla = niebla.get(sala, 0.0)
				cara.queue_redraw()
	for m in muebles:
		var n: float = niebla.get(m.zona, 0.0)
		m.modulate = Color(1, 1, 1).lerp(OSCURO, 0.4 * n)   # poco: encima ya va la niebla, y se intuye la silueta


# ¿Está esto en una habitación que aún no se ha pisado? (entonces ni se ve ni se le apunta)
func oculto(pos: Vector2) -> bool:
	return niebla.get(zona_en(pos), 0.0) > 0.5


func _process(delta: float) -> void:
	if not niebla.is_empty():
		actualizar_niebla(delta)
		for z in get_tree().get_nodes_in_group("zombis"):
			z.visible = not oculto(z.global_position)
		separar_salas()
	if not expo_sprites.is_empty():
		# los zombis de la exposición giran por sus 8 direcciones
		var antes := int(expo_t / 0.7)
		expo_t += delta
		if int(expo_t / 0.7) != antes:
			for s in expo_sprites:
				s.play("reposo_" + RUMBOS[int(expo_t / 0.7) % RUMBOS.size()])


# Cada cosa del mapa (muros, muebles, puertas, zombis, cuerpos, objetos, aliados, Johnny...) va en la capa de
# luz de la habitación en la que tiene los pies (Luz.capa_sala), y las lámparas y la linterna solo alumbran la
# suya: así su luz (la que no hace sombras) no se cuela por las paredes. Las sombras no bastarían: con la vista
# desde arriba, la cara de un muro se dibuja encima del suelo de la habitación de detrás. Solo se cambia lo
# que ha cambiado de habitación (lo nuevo empieza en la capa 1); lo que está en un muro se queda en la 1
func separar_salas() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and zona_en(johnny.global_position) >= 0:
		Luz.capa_johnny = Luz.capa_sala(zona_en(johnny.global_position))
	for cosa in cosas.get_children():
		var sala := zona_en(cosa.global_position)
		if sala < 0 or cosa.get_meta("sala", -1) == sala:
			continue
		cosa.set_meta("sala", sala)
		Luz.poner_capa(cosa, Luz.capa_sala(sala))


# ═════════════ Exposición (modo pruebas) ═════════════

# Todos los muebles del catálogo con sus variantes y su dibujo de lado, a su tamaño real y con su nombre debajo
# (el rectángulo claro es el hueco que ocupa en el suelo); y debajo, los zombis con todas sus ropas, girando.
# Nada choca: es para mirar.
func poner_exposicion() -> void:
	var x := float(MURO + 30)
	var y := float(MURO + 150)    # el pie de la fila
	var alto_fila := 0.0
	for tipo in Catalogo.MUEBLES:
		var p: Dictionary = Catalogo.MUEBLES[tipo]
		var ids := ["mueble-" + tipo]
		for letra in MUEBLE.LETRAS:
			if not MUEBLE.existe("mueble-%s-%s" % [tipo, letra]):
				break
			ids.append("mueble-%s-%s" % [tipo, letra])
		for id in ids.duplicate():
			if MUEBLE.existe(id + "-lado"):
				ids.append(id + "-lado")
		for id in ids:
			var lado: bool = id.ends_with("-lado")
			var tex: Texture2D = load(MUEBLE.ruta(id))
			var w: float = maxf(tex.get_width() * 2.0, p.dep if lado else p.len)
			if x + w > sitio.ancho - MURO - 30:
				x = MURO + 30
				y += alto_fila + 70
				alto_fila = 0.0
			alto_fila = maxf(alto_fila, tex.get_height() * 2.0)
			var pie := Vector2(x + w / 2.0, y)
			var hueco := ColorRect.new()
			hueco.color = Color(1, 1, 1, 0.18)
			hueco.size = Vector2(p.dep, p.len) if lado else Vector2(p.len, p.dep)
			hueco.position = pie - Vector2(hueco.size.x / 2.0, hueco.size.y)
			add_child(hueco)
			move_child(hueco, 1)
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.scale = Vector2(2, 2)
			sprite.centered = false
			sprite.offset = Vector2(-floorf(tex.get_width() / 2.0), -tex.get_height())
			sprite.position = pie
			cosas.add_child(sprite)
			etiqueta(id.trim_prefix("mueble-"), pie + Vector2(0, 6))
			x += maxf(w + 24, 110.0)
	# los zombis, en una fila por tipo: el de siempre y sus ropas
	y += alto_fila + 150
	for nombre in EXPO_ZOMBIS:
		var muestra: Node2D = load("res://escenas/personajes/%s.tscn" % nombre).instantiate()
		var base: AnimatedSprite2D = muestra.get_node("Sprite")
		var ropas: Array = muestra.get("ropas") if muestra.get("ropas") else [base.sprite_frames]
		x = MURO + 60
		for ropa in ropas:
			var sprite: AnimatedSprite2D = base.duplicate()
			sprite.sprite_frames = ropa
			sprite.position += Vector2(x, y)
			sprite.play("reposo_s")
			cosas.add_child(sprite)
			expo_sprites.append(sprite)
			x += 110
		etiqueta(nombre.trim_prefix("zombi_"), Vector2(MURO + 60, y + 40))
		muestra.free()
		y += 150


func etiqueta(texto: String, pos: Vector2) -> void:
	var nombre := Label.new()
	nombre.text = texto
	nombre.theme = Tema.crear()   # la fuente pixel art, a 16 para que se vea nítida
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	nombre.add_theme_constant_override("outline_size", 4)
	nombre.size = Vector2(200, 20)
	nombre.position = pos - Vector2(100, 0)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.z_index = 5
	add_child(nombre)


# La llave del apartamento de la jefa: brilla un poco y sube y baja hasta que Johnny la pisa. En el centro
# comercial, la tarjeta de acceso (la suelta el guardia al caer)
func poner_llave(pos: Vector2, tarjeta := false) -> void:
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
	dibujo.texture = dibujo_tarjeta() if tarjeta else LLAVE
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


# La tarjeta de acceso, dibujada con código hasta que tenga su sprite (parte 2 del centro comercial): una
# tarjeta azul de 12 × 8 píxeles con su banda magnética, su chip dorado y el borde oscuro
static func dibujo_tarjeta() -> Texture2D:
	var img := Image.create(12, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color("#3d7be0"))
	for x in 12:
		img.set_pixel(x, 0, Color("#1b2f5c"))
		img.set_pixel(x, 7, Color("#1b2f5c"))
		img.set_pixel(x, 2, Color("#14161f"))   # la banda
		img.set_pixel(x, 1, Color("#8fb8ff"))   # el brillo de arriba
	for y in 8:
		img.set_pixel(0, y, Color("#1b2f5c"))
		img.set_pixel(11, y, Color("#1b2f5c"))
	for p in [Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5)]:
		img.set_pixelv(p, Color("#ffd23f"))   # el chip
	for x in range(6, 10):
		img.set_pixel(x, 5, Color("#dfe8ff"))   # el nombre
	return ImageTexture.create_from_image(img)


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


# Otra vez, cuando algo deja de chocar (la puerta del baño del superviviente, al abrirse)
func rehornear() -> void:
	hornear(get_node("Navegacion"))


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
