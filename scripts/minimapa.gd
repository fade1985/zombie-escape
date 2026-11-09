# El minimapa, arriba a la derecha. En el pasillo de la planta (y en la exposición y la sala de pruebas), el plano de la
# planta, como el de una mazmorra; dentro de un sitio (un piso, la habitación de un jefe, una tienda, la sala de
# mantenimiento, las viviendas...), el plano de ese sitio (ver "El plano del sitio", abajo).
# El plano de la planta: el pasillo en medio y, pegada a él (con el muro compartido y el hueco de la puerta), una sala
# por cada puerta (arriba y abajo, todas del mismo tamaño), la llegada a la izquierda y las escaleras a la derecha. Gris = sin visitar (con un «?»), rojo = con zombis dentro, claro = limpio; Johnny, un círculo
# rojo (en el pasillo, donde está). El piso de la portera lleva un candado y, cuando ya has entrado en el apartamento donde
# está su llave y aún no la has cogido, ese lleva la llave. Donde está encerrado el superviviente, un "!" rojo
# (supervivientes.gd).
# Con el técnico rescatado (vive en su habitación de las viviendas y ha arreglado las cámaras de seguridad), el plano
# enseña los zombis: un puntito rojo por cada uno, también en las salas sin visitar. Donde está Johnny, cada
# puntito va donde está su zombi y se mueve con él; en las demás salas, en filas.
extends Control

const ANCHO := 170.0
const ALTO := 106.0
const MARGEN := 14.0
const CABEZA := 22.0
const PUNTA := 18.0         # ancho de las casillas de los extremos
const GRIS := Color("#4a4552")
const CLARO := Color("#bdb59c")
const ROJO := Color("#b34030")
const VERDE := Color("#6f9a58")
const BORDE := Color("#1d1b2c")
const FONDO := Color("#141219")
const CUADRICULA := Color("#24212c")
const SOMBRA := Color(0, 0, 0, 0.45)
const SUELO := Color("#8f8775")     # los trocitos de pasillo que unen las salas
const PASILLO_Y := 58.0     # dónde empieza (por arriba) el pasillo
const CASILLA := 32.0
const PUNTO := Color("#ff3b3b")     # los zombis, con las cámaras
const BRILLO := Color("#ffb3a0")
const SALA := Vector2(34, 22)       # cada apartamento en el plano de la planta: todos iguales, sea como sea de grande
const OSCURA := Color("#2e2a36")    # en el plano de un sitio, las habitaciones aún sin pisar (con la niebla del mapa)
const DONDE := Color("#e6d68a")     # la habitación en la que está Johnny
const JOHNNY := Color("#e2382c")    # Johnny: un círculo rojo con el borde claro (los zombis son cuadraditos)
const PASILLO := Color("#9c9480")   # el suelo del pasillo de la planta
const PASO := Color("#a39a84")      # los huecos de las puertas de dentro
const ICONOS := {
	"puerta": preload("res://assets/ui/iconos/puerta.png"),
	"herramientas": preload("res://assets/ui/iconos/herramientas.png"),
	"candado": preload("res://assets/ui/iconos/candado.png"),
	"llave": preload("res://assets/ui/iconos/llave.png"),
	"escalera": preload("res://assets/ui/iconos/escalera.png"),
	"jefe": preload("res://assets/ui/iconos/jefe.png"),
}

var partida: Node           # de donde saca la planta y el sitio en el que está Johnny
var marco := StyleBoxTexture.new()
var tiempo := 0.0
var camaras := false        # el técnico ya está rescatado: se ven los zombis
# El plano del sitio, una casilla por píxel, y lo que lo cambia (para no rehacerlo en cada fotograma)
var plano := Image.new()
var plano_textura: ImageTexture
var plano_firma := ""
static var VISIBLE := {}    # lo que se ve de cada icono (sin el hueco de alrededor), medido una vez


func _ready() -> void:
	# el marco de metal oxidado de los botones, en 9 trozos (las esquinas no se estiran)
	marco.texture = preload("res://assets/ui/boton-oscuro.png")
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		marco.set_texture_margin(lado, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # (el plano del sitio, ampliado, con sus píxeles enteros)
	camaras = "tecnico" in Guardado.cargar().rescatados
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -ANCHO - 12
	offset_right = -12
	offset_top = 10
	offset_bottom = 10 + ALTO


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


# Las salas del plano de la planta: cada una un diccionario con su rectángulo, su color, si estás ahí, su icono, si está
# ahí el superviviente y el hueco de su puerta ("puerta"): todas pegadas al pasillo, compartiendo el muro.
# Todas del mismo tamaño (SALA). Todo cae en números pares: 2 unidades = un píxel del dibujo.
func casillas() -> Array:
	var planta: Dictionary = partida.planta
	var pasillo: Dictionary = planta.sitios[0]
	var aqui: int = partida.aqui
	var lista := []
	var x0 := MARGEN + PUNTA + 4
	var largo := ANCHO - x0 * 2
	var medio := PASILLO_Y + 5.0
	# (la recepcionista de la torre se esconde en el pasillo, detrás del mostrador: su "!", encima de él)
	var en_mostrador: bool = partida.supervivientes.encerrado() and planta.superviviente.has("mostrador")
	lista.append({"r": Rect2(x0, PASILLO_Y, largo, 10), "color": PASILLO, "aqui": aqui == 0, "pasillo": true, "icono": "", "sos": en_mostrador,
		"puerta": Rect2(), "sitio": -1 if abajo() else 0,
		"sos_x": x0 + planta.superviviente.mostrador.x / pasillo.ancho * largo if en_mostrador else 0.0})
	var sos: int = planta.superviviente.sitio if partida.supervivientes.encerrado() else -1
	for s in pasillo.salidas:
		match s.tipo:
			"llegada":
				lista.append({"r": Rect2(x0 - 2 - PUNTA, medio - 11, PUNTA, 22), "color": GRIS, "aqui": false, "icono": "puerta",
					"sos": false, "puerta": Rect2(x0 - 4, medio - 3, 4, 6)})
			"escaleras":
				var abiertas: bool = planta.jefa_muerta
				lista.append({"r": Rect2(x0 + largo + 2, medio - 11, PUNTA, 22), "color": VERDE if abiertas else GRIS,
					"aqui": false, "icono": "escalera" if abiertas else "candado", "sos": false,
					"puerta": Rect2(x0 + largo, medio - 3, 4, 6)})
			"puerta":
				if s.a < 0:
					continue
				var sitio: Dictionary = planta.sitios[s.a]
				var color := GRIS if not sitio.visitado else CLARO if sitio.limpio else ROJO
				var icono := ""
				if s.cerrojo == "llave":
					icono = "candado"
				elif planta.llave.sitio == s.a and sitio.visitado and not planta.tiene_llave and not planta.get("llave_usada", false):
					icono = "llave"
				elif sitio.tipo == "mantenimiento":
					icono = "herramientas"
				elif sitio.tipo == "jefe":
					icono = "jefe"
				var ancho := SALA.x
				var alto := SALA.y
				var x := par(x0 + float(s.en) / pasillo.ancho * largo)
				var arriba: bool = s.dir == "arriba"
				# pegada al pasillo: su muro y el del pasillo son uno, con el hueco de la puerta
				var y := PASILLO_Y - 2 - alto if arriba else PASILLO_Y + 12
				var puerta := Rect2(x - 3, PASILLO_Y - 4 if arriba else PASILLO_Y + 10, 6, 4)
				lista.append({"r": Rect2(x - ancho / 2.0, y, ancho, alto), "color": color,
					# (desde la exposición y las viviendas, que no salen en el plano, se marca la sala de mantenimiento)
					"aqui": aqui == s.a or (planta.sitios[aqui].tipo in ["expo", "armas", "viviendas"] and sitio.tipo == "mantenimiento"),
					"icono": icono, "sos": s.a == sos, "puerta": puerta, "sitio": s.a})
	return lista


# Si Johnny ha bajado en el ascensor a la sala de mantenimiento o a las viviendas (está en la planta baja, no en la suya)
func abajo() -> bool:
	return partida.planta.num > 1 and partida.planta.sitios[partida.aqui].tipo in ["mantenimiento", "viviendas"]


static func par(v: float) -> float:
	return roundf(v / 2.0) * 2.0


func _draw() -> void:
	if partida == null or partida.planta.is_empty():
		return
	draw_style_box(marco, Rect2(Vector2.ZERO, size))
	var letra := get_theme_default_font()
	# arriba, el nombre de la planta o, dentro de un sitio, el del sitio (ya traducidos)
	var titulo: String = Planta.nombre_de_sitio(partida.planta.sitios[partida.aqui]) if dentro() else Planta.nombre_de(partida.planta)
	draw_string_outline(letra, Vector2(4, 22), titulo, HORIZONTAL_ALIGNMENT_CENTER, ANCHO - 8, 16, 4, BORDE)
	draw_string(letra, Vector2(4, 22), titulo, HORIZONTAL_ALIGNMENT_CENTER, ANCHO - 8, 16, Color("#e6c34a"))
	# el fondo: papel oscuro cuadriculado, como el plano de una mazmorra, con su filo hundido
	var fondo := Rect2(8, 30, ANCHO - 16, ALTO - 38)
	draw_rect(fondo.grow(2), BORDE)
	draw_rect(fondo, FONDO)
	for gx in range(int(fondo.position.x) + 4, int(fondo.end.x), 8):
		for gy in range(int(fondo.position.y) + 4, int(fondo.end.y), 8):
			draw_rect(Rect2(gx, gy, 2, 2), CUADRICULA)
	draw_rect(Rect2(fondo.position, Vector2(fondo.size.x, 2)), SOMBRA)   # (la sombra del filo de arriba)
	if dentro():
		dibujar_sitio(fondo)
	else:
		dibujar_planta()


# El plano de la planta: el pasillo, las salas y sus iconos. Cada sala de su color (gris sin visitar, con un «?»; roja
# con zombis; clara ya limpia) y Johnny, un círculo rojo: en el pasillo, donde está; si no, en medio de su sala
func dibujar_planta() -> void:
	var letra := get_theme_default_font()
	var lista := casillas()
	# primero las sombras, luego los trocitos de pasillo que unen cada sala y, encima, las salas
	for c in lista:
		draw_rect(Rect2(c.r.position + Vector2(2, 2), c.r.size).grow(2), SOMBRA)
	for c in lista:
		var r: Rect2 = c.r
		var color: Color = c.color
		draw_rect(r.grow(2), BORDE)
		if c.get("pasillo", false):
			draw_rect(r, color)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), color.lightened(0.2))
		else:
			# cada sala, como una habitación vista desde arriba: el muro (más oscuro, con su filo de luz arriba) y,
			# dentro, el suelo del color de la sala, con su sombra arriba (la del muro)
			var muro := color.darkened(0.4)
			draw_rect(r, muro)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), muro.lightened(0.3))
			var suelo := r.grow(-2)
			draw_rect(suelo, color)
			draw_rect(Rect2(suelo.position, Vector2(suelo.size.x, 2)), color.darkened(0.2))
		if c.get("pasillo", false):
			# la raya del medio del pasillo, a trozos, como la de una carretera
			for x in range(int(r.position.x) + 4, int(r.end.x) - 4, 10):
				draw_rect(Rect2(x, r.get_center().y - 1, 4, 2), color.darkened(0.25))
		elif color == GRIS and c.icono == "" and c.has("sitio"):
			# sin visitar: un «?» pequeño
			draw_string(letra, Vector2(r.position.x, r.get_center().y + 7), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, GRIS.lightened(0.35))   # no-tr (un signo)
	# el hueco de cada puerta, encima, abre el muro que comparten la sala y el pasillo
	for c in lista:
		if c.puerta.has_area():
			draw_rect(c.puerta, PASILLO)
	if camaras:
		dibujar_zombis(lista)
	for c in lista:
		if c.icono != "":
			icono(c.icono, c.r.get_center())
	# el "!" del superviviente, dentro de su sala
	for c in lista:
		if c.sos:
			var sitio_sos := Vector2(c.r.end.x - 6, c.r.get_center().y)   # dentro de la sala, a la derecha
			if c.has("sos_x") and c.sos_x > 0.0:
				sitio_sos = Vector2(c.sos_x - 5, c.r.position.y + 2)
			exclamacion(sitio_sos)
	# Johnny
	for c in lista:
		if c.aqui:
			var p: Vector2 = c.r.get_center()
			var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
			if c.get("pasillo", false) and johnny and partida.mapa and partida.mapa.is_ancestor_of(johnny):
				var pasillo: Dictionary = partida.planta.sitios[0]
				p = c.r.position + johnny.position / Vector2(pasillo.ancho, pasillo.alto) * c.r.size
				p = p.clamp(c.r.position, c.r.end)
			marca_johnny(p)


# Johnny en el plano: un círculo rojo pequeño con el borde claro, quieto
func marca_johnny(p: Vector2) -> void:
	p = Vector2(par(p.x), par(p.y))
	draw_circle(p, 5.0, BORDE, true, -1.0, false)
	draw_circle(p, 4.0, Tema.TINTA, true, -1.0, false)
	draw_circle(p, 3.0, JOHNNY, true, -1.0, false)


# Un icono del plano (16 × 16) centrado en "centro", con su sombra para que se lea sobre cualquier sala
# (los dibujos son de 32 × 32 con huecos distintos alrededor: se centra lo que se ve, a la mitad)
func icono(nombre: String, centro: Vector2) -> void:
	var tex: Texture2D = ICONOS[nombre]
	if not VISIBLE.has(nombre):
		VISIBLE[nombre] = Rect2(tex.get_image().get_used_rect())
	var de: Rect2 = VISIBLE[nombre]
	var tam := de.size / 2.0
	var r := Rect2(Vector2(par(centro.x - tam.x / 2.0), par(centro.y - tam.y / 2.0)), tam)
	draw_texture_rect_region(tex, Rect2(r.position + Vector2(2, 2), r.size), de, SOMBRA)
	draw_texture_rect_region(tex, r, de)


# ── El plano del sitio ──
# Dentro de un sitio, su plano visto desde arriba, una casilla del mapa por píxel del dibujo (sin el muro de fuera):
# cada habitación clara si ya se ha pisado y a oscuras si no (con la misma niebla del mapa, que se va aclarando a la
# vez), la de Johnny más amarilla, los huecos de las puertas de dentro y las salidas en verde. Encima, Johnny (un
# círculo rojo que se mueve con él), la llave si está en el suelo de una habitación ya vista, el «!» del
# superviviente y, con las cámaras del técnico, los zombis

# ¿Se enseña el plano del sitio? En todos menos en el pasillo de la planta, la exposición y la sala de pruebas
func dentro() -> bool:
	var sitios: Array = partida.planta.sitios
	return partida.aqui > 0 and partida.aqui < sitios.size() and sitios[partida.aqui].tipo not in ["pasillo", "expo", "armas"]


# Las casillas del sitio: las del apartamento (con sus muros) o, si no tiene (la azotea, el laboratorio...), un
# rectángulo de suelo. "borde": las casillas de muro de fuera, que no se pintan
func rejilla(sitio: Dictionary) -> Dictionary:
	if sitio.has("apt"):
		return {"cols": sitio.apt.cols, "filas": sitio.apt.filas, "dueno": sitio.apt.dueno, "borde": Apartamento.BORDE}
	var cols := int(sitio.ancho / CASILLA)
	var filas := int(sitio.alto / CASILLA)
	var dueno := PackedInt32Array()
	dueno.resize(cols * filas)
	dueno.fill(0)
	return {"cols": cols, "filas": filas, "dueno": dueno, "borde": 0}


func dibujar_sitio(fondo: Rect2) -> void:
	var sitio: Dictionary = partida.planta.sitios[partida.aqui]
	var mapa: Node = partida.mapa
	if mapa == null:
		return
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	var en_mapa := johnny != null and mapa.is_ancestor_of(johnny)
	var g := rejilla(sitio)
	var b: int = g.borde
	var cols: int = g.cols - b * 2
	var filas: int = g.filas - b * 2
	# la escala: lo más grande que quepa, en números pares si se puede (cada casilla, píxeles enteros)
	var hueco := fondo.grow(-6)
	var k := minf(hueco.size.x / cols, hueco.size.y / filas)
	if k >= 2.0:
		k = floorf(k / 2.0) * 2.0
	var tam := Vector2(cols, filas) * k
	var origen := fondo.get_center() - tam / 2.0
	origen = Vector2(par(origen.x), par(origen.y))
	var aqui_sala: int = mapa.zona_en(johnny.position) if en_mapa else -1
	pintar_plano(g, mapa, aqui_sala)
	var r := Rect2(origen, tam)
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size).grow(2), SOMBRA)
	draw_rect(r.grow(2), BORDE)
	draw_texture_rect(plano_textura, r, false)
	# de casilla del mapa (en unidades) a punto del plano
	var a_plano := func(p: Vector2) -> Vector2: return origen + (p / CASILLA - Vector2(b, b)) * k
	# las salidas (la puerta de entrada, la del ascensor...), en verde por fuera del borde
	for s in sitio.get("salidas", []):
		var en: Vector2
		match s.dir:
			"abajo": en = Vector2(s.en, g.filas * CASILLA)
			"arriba": en = Vector2(s.en, 0)
			"izquierda": en = Vector2(0, s.en)
			"derecha": en = Vector2(g.cols * CASILLA, s.en)
			_: continue
		var p: Vector2 = a_plano.call(en).clamp(r.position, r.end)
		var hor: bool = s.dir in ["abajo", "arriba"]
		var trozo := Rect2(p - (Vector2(4, 2) if hor else Vector2(2, 4)), Vector2(8, 4) if hor else Vector2(4, 8))
		draw_rect(trozo.grow(2), BORDE)
		draw_rect(trozo, VERDE)
	# la llave (o la tarjeta) en el suelo, si su habitación ya se ha visto
	for nombre in ["Llave", "Dorada"]:
		var llave: Node2D = mapa.cosas.get_node_or_null(nombre) if mapa.cosas else null
		if llave and mapa.niebla.get(mapa.zona_en(llave.position), 0.0) < 0.5:
			icono("llave", a_plano.call(llave.position) - Vector2(0, 4))
	# el «!» del superviviente encerrado, en su habitación
	var sv: Dictionary = partida.planta.get("superviviente", {})
	if partida.supervivientes.encerrado() and sv.get("sitio", -1) == partida.aqui and sv.has("sala") and sitio.has("apt"):
		for sala in sitio.apt.salas:
			if sala.id == sv.sala:
				var c: Vector2 = a_plano.call((Vector2(sala.c0, sala.f0) + Vector2(sala.ancho, sala.fondo) / 2.0) * CASILLA)
				exclamacion(c - Vector2(0, 8))
	if camaras:
		for z in vivos():
			punto((a_plano.call(z.global_position - mapa.global_position) - Vector2(2, 2)).clamp(r.position, r.end - Vector2(4, 4)))
	# Johnny, un círculo rojo
	if en_mapa:
		marca_johnny(a_plano.call(johnny.position))


# Rehace la imagen del plano si ha cambiado algo: el sitio, la habitación de Johnny o la niebla
func pintar_plano(g: Dictionary, mapa: Node, aqui_sala: int) -> void:
	var niebla: Dictionary = mapa.niebla
	var firma := "%d/%d/%s" % [partida.aqui, aqui_sala, niebla.values().map(func(n): return snappedf(n, 0.05))]
	if firma == plano_firma and plano_textura:
		return
	plano_firma = firma
	var b: int = g.borde
	var cols: int = g.cols
	var dueno: PackedInt32Array = g.dueno
	plano = Image.create(cols - b * 2, g.filas - b * 2, false, Image.FORMAT_RGBA8)
	for f in range(b, g.filas - b):
		for c in range(b, cols - b):
			var o := dueno[f * cols + c]
			var color := BORDE
			if o >= 0:
				color = (DONDE if o == aqui_sala else CLARO).lerp(OSCURA, niebla.get(o, 0.0))
			elif o == -2:
				# el hueco de una puerta: claro si se ve alguna de las dos habitaciones que une
				var n := 1.0
				for v in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var cc: int = c + v.x
					var ff: int = f + v.y
					if cc >= 0 and ff >= 0 and cc < cols and ff < g.filas and dueno[ff * cols + cc] >= 0:
						n = minf(n, niebla.get(dueno[ff * cols + cc], 0.0))
				color = PASO.lerp(OSCURA, n)
			plano.set_pixel(c - b, f - b, color)
	if plano_textura and plano_textura.get_size() == Vector2(plano.get_size()):
		plano_textura.update(plano)
	else:
		plano_textura = ImageTexture.create_from_image(plano)


# El «!» del superviviente, como el de los avisos de la línea de abajo: la letra del juego a 16, hueso con el contorno oscuro
func exclamacion(centro: Vector2) -> void:
	var letra := get_theme_default_font()
	draw_string_outline(letra, centro + Vector2(-10, 6), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 16, 4, Tema.LINEA)
	draw_string(letra, centro + Vector2(-10, 6), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 16, Tema.TINTA)


# ── Las cámaras del técnico ──

# Un puntito por zombi en cada sala. Donde está Johnny, cada uno en su sitio (el sitio entero cabe en su
# rectángulo); en las demás, en filas, tantos como quepan
func dibujar_zombis(lista: Array) -> void:
	for c in lista:
		var i: int = c.get("sitio", -1)
		if i < 0:
			continue
		var r: Rect2 = c.r.grow(-2)
		if i == partida.aqui:
			var sitio: Dictionary = partida.planta.sitios[i]
			var tam := Vector2(sitio.ancho, sitio.alto)
			for z in vivos():
				var p: Vector2 = r.position + z.global_position / tam * r.size - Vector2(2, 2)
				punto(p.clamp(r.position, r.end - Vector2(4, 4)))
		else:
			var por_fila := maxi(1, int(r.size.x / 6.0))
			var filas := maxi(1, int(r.size.y / 6.0))
			for k in mini(zombis_en(i), por_fila * filas):
				punto(r.position + Vector2(k % por_fila, k / por_fila) * 6.0)


# Un puntito: rojo, con su sombra y un brillo (que se vea también sobre las salas rojas)
func punto(p: Vector2) -> void:
	p = Vector2(par(p.x), par(p.y))
	draw_rect(Rect2(p + Vector2(2, 2), Vector2(4, 4)), BORDE)
	draw_rect(Rect2(p, Vector2(4, 4)), PUNTO)
	draw_rect(Rect2(p, Vector2(2, 2)), BRILLO)


# Los zombis que quedan en el sitio "i" (donde no está Johnny: los que esperan dentro, si no está limpio; si ya se ha
# entrado, los que se quedaron vivos al salir)
func zombis_en(i: int) -> int:
	var sitio: Dictionary = partida.planta.sitios[i]
	if sitio.get("limpio", false):
		return 0
	return partida.mapas[i].quedan if partida.mapas.has(i) else sitio.get("zombis", []).size()


func vivos() -> Array:
	return get_tree().get_nodes_in_group("zombis").filter(func(z): return z.get("estado") != "muerto")


# Para las pruebas: cuántos puntitos lleva cada sala del plano ({sitio: zombis})
func zombis_por_sala() -> Dictionary:
	var cuenta := {}
	for c in casillas():
		var i: int = c.get("sitio", -1)
		if i >= 0:
			cuenta[i] = vivos().size() if i == partida.aqui else zombis_en(i)
	return cuenta
