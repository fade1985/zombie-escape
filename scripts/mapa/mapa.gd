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
const OSCURO := Color(0.07, 0.063, 0.11)   # el color de la niebla
const ACLARA := 3.5                        # lo rápido que se aclara una habitación al descubrirla (por segundo)
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
var trozos_niebla := {}           # habitación -> los rectángulos de suelo que tapa la niebla
var expo_sprites: Array = []      # los zombis de la exposición, que van girando
var expo_t := 0.0


func montar(datos: Dictionary, llave := Vector2.INF) -> void:
	sitio = datos
	add_to_group("mapa")
	cols = int(sitio.ancho / CASILLA)
	filas = int(sitio.alto / CASILLA)
	if sitio.has("dueno"):
		# un rectángulo con muros de 2 casillas alrededor; todo el suelo es la "habitación" 0
		dueno = sitio.dueno
		if sitio.tipo == "pasillo":
			estilos[0] = textura("pasillo", "")
			tapa = load("res://assets/sprites/tapa-pasillo.png")
			alfombra = load("res://assets/sprites/alfombra-pasillo.png")
		else:
			estilos[0] = textura("mantenimiento", "")
			tapa = load("res://assets/sprites/tapa-generica.png")
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
	fondo.light_mask = Luz.CAPA_SUELO   # el suelo es lo único que recibe sombras (ver luz.gd)
	fondo.z_index = -10   # por debajo de todo: los charcos, las manchas y los cuerpos (z -1 y -2) quedan encima
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
	poner_muebles()
	poner_apliques()
	for a in sitio.get("armaritos", []):
		var armarito := ARMARITO.new()
		armarito.montar(a)
		cosas.add_child(armarito)
		armaritos.append(armarito)
	if llave != Vector2.INF:
		poner_llave(llave)
	if sitio.tipo == "expo":
		poner_exposicion()
	hornear(navegacion)
	if sitio.has("apt"):
		preparar_niebla()
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
	# las manchas de sangre de la sala de mantenimiento: cada una gira de 90 en 90 grados y se voltea al azar
	for m in sitio.get("manchas", []):
		lienzo.draw_set_transform(m.pos, m.giro * PI / 2.0, Vector2(-2 if m.espejo else 2, 2))
		lienzo.draw_texture_rect_region(MANCHAS, Rect2(-30, -18, 60, 36), Rect2(m.dibujo * 60, 0, 60, 36))


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


# ═════════════ Niebla ═════════════

func preparar_niebla() -> void:
	vistas = sitio.get_or_add("vistas", {})
	for s in sitio.apt.salas:
		niebla[s.id] = 0.0 if vistas.has(s.id) else 1.0
		trozos_niebla[s.id] = []
	# el suelo de cada habitación, por tramos de cada fila. Las casillas que tapa la cara de un muro de más
	# abajo (las dos últimas filas antes de un tabique) no se oscurecen: ya las tapa esa cara, que lleva la
	# niebla de su habitación (si no, la cara de una habitación descubierta quedaría a oscuras)
	for f in filas:
		var c := 0
		while c < cols:
			var sala := -1 if es_muro(c, f) or tapada(c, f) else sala_de(c, f)
			var fin := c + 1
			while fin < cols and (-1 if es_muro(fin, f) or tapada(fin, f) else sala_de(fin, f)) == sala:
				fin += 1
			if sala >= 0:
				trozos_niebla[sala].append(Rect2(c * CASILLA, f * CASILLA, (fin - c) * CASILLA, CASILLA))
			c = fin
	velo = Node2D.new()
	velo.name = "Niebla"
	velo.light_mask = 0   # las lámparas no la aclaran
	velo.draw.connect(func():
		for sala in niebla:
			if niebla[sala] > 0.0:
				for r in trozos_niebla[sala]:
					velo.draw_rect(r, Color(OSCURO, 0.9 * niebla[sala])))
	add_child(velo)
	actualizar_niebla(0.0)


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
	velo.queue_redraw()
	for sala in caras:
		for cara in caras[sala]:
			if cara.niebla != niebla.get(sala, 0.0):
				cara.niebla = niebla.get(sala, 0.0)
				cara.queue_redraw()
	for m in muebles:
		var n: float = niebla.get(m.zona, 0.0)
		m.modulate = Color(1, 1, 1).lerp(OSCURO, 0.85 * n)


# ¿Está esto en una habitación que aún no se ha pisado? (entonces ni se ve ni se le apunta)
func oculto(pos: Vector2) -> bool:
	return niebla.get(zona_en(pos), 0.0) > 0.5


func _process(delta: float) -> void:
	if not niebla.is_empty():
		actualizar_niebla(delta)
		for z in get_tree().get_nodes_in_group("zombis"):
			z.visible = not oculto(z.global_position)
	if not expo_sprites.is_empty():
		# los zombis de la exposición giran por sus 8 direcciones
		var antes := int(expo_t / 0.7)
		expo_t += delta
		if int(expo_t / 0.7) != antes:
			for s in expo_sprites:
				s.play("reposo_" + RUMBOS[int(expo_t / 0.7) % RUMBOS.size()])


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
	nombre.add_theme_font_size_override("font_size", 14)
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	nombre.add_theme_constant_override("outline_size", 4)
	nombre.size = Vector2(200, 20)
	nombre.position = pos - Vector2(100, 0)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.z_index = 5
	add_child(nombre)


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
