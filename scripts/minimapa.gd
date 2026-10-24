# El minimapa: un plano de la planta arriba a la derecha, como el de una mazmorra. El pasillo en medio y, unida
# a él por un trocito de pasillo, una sala por cada puerta (arriba y abajo), la llegada a la izquierda y las
# escaleras a la derecha. Gris = sin visitar, rojo = con zombis dentro, claro = limpio, amarillo = donde estás (con un
# marco que parpadea). El piso de la portera lleva un candado y, cuando ya has entrado en el apartamento donde
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
const AMARILLO := Color("#e0b030")
const BORDE := Color("#1d1b2c")
const FONDO := Color("#141219")
const CUADRICULA := Color("#24212c")
const SOMBRA := Color(0, 0, 0, 0.45)
const SUELO := Color("#8f8775")     # los trocitos de pasillo que unen las salas
const PASILLO_Y := 58.0     # dónde empieza (por arriba) el pasillo
const CASILLA := 32.0
const PUNTO := Color("#ff3b3b")     # los zombis, con las cámaras
const BRILLO := Color("#ffb3a0")
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


func _ready() -> void:
	# el marco de metal oxidado de los botones, en 9 trozos (las esquinas no se estiran)
	marco.texture = preload("res://assets/ui/boton-oscuro.png")
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		marco.set_texture_margin(lado, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	camaras = "tecnico" in Guardado.cargar().rescatados
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -ANCHO - 12
	offset_right = -12
	offset_top = 10
	offset_bottom = 10 + ALTO


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


# Las salas: cada una un diccionario con su rectángulo, su color, si estás ahí, su icono, si está ahí el
# superviviente y el trocito de pasillo ("puerta") que la une al pasillo, como en el plano de una mazmorra.
# Los apartamentos más grandes salen más anchos. Todo cae en números pares: 2 unidades = un píxel del dibujo.
func casillas() -> Array:
	var planta: Dictionary = partida.planta
	var pasillo: Dictionary = planta.sitios[0]
	var aqui: int = partida.aqui
	var lista := []
	var x0 := MARGEN + PUNTA + 4
	var largo := ANCHO - x0 * 2
	var medio := PASILLO_Y + 5.0
	lista.append({"r": Rect2(x0, PASILLO_Y, largo, 10), "color": CLARO, "aqui": aqui == 0, "icono": "", "sos": false,
		"puerta": Rect2(), "sitio": -1 if abajo() else 0})
	if abajo():
		# bajando en el ascensor: el pasillo de la planta baja y, en su puerta A, la sala de mantenimiento
		var x := par(x0 + float(Planta.PUERTA_A) / pasillo.ancho * largo)
		lista.append({"r": Rect2(x - 17, PASILLO_Y - 22, 34, 16), "color": CLARO, "aqui": true, "icono": "herramientas",
			"sos": false, "puerta": Rect2(x - 3, PASILLO_Y - 8, 6, 8)})
		return lista
	var sos: int = planta.superviviente.sitio if partida.supervivientes.encerrado() else -1
	for s in pasillo.salidas:
		match s.tipo:
			"llegada":
				lista.append({"r": Rect2(MARGEN, medio - 8, PUNTA, 16), "color": GRIS, "aqui": false, "icono": "puerta",
					"sos": false, "puerta": Rect2(MARGEN + PUNTA - 2, medio - 3, 8, 6)})
			"escaleras":
				var abiertas: bool = planta.jefa_muerta
				lista.append({"r": Rect2(x0 + largo + 4, medio - 8, PUNTA, 16), "color": VERDE if abiertas else GRIS,
					"aqui": false, "icono": "escalera" if abiertas else "candado", "sos": false,
					"puerta": Rect2(x0 + largo - 2, medio - 3, 8, 6)})
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
				# de 28 a 46 de ancho según lo grande que sea el apartamento
				var ancho := par(clampf(10.0 + sitio.ancho / CASILLA * 0.8, 28.0, 46.0))
				var alto := 18.0 if sitio.tipo == "jefe" else 16.0
				var x := par(x0 + float(s.en) / pasillo.ancho * largo)
				var arriba: bool = s.dir == "arriba"
				var y := PASILLO_Y - 6 - alto if arriba else PASILLO_Y + 16
				var puerta := Rect2(x - 3, PASILLO_Y - 8 if arriba else PASILLO_Y + 8, 6, 8)
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
	var titulo: String = Planta.nombre_planta(1) if abajo() else partida.planta.nombre
	draw_string_outline(letra, Vector2(0, 22), titulo, HORIZONTAL_ALIGNMENT_CENTER, ANCHO, 16, 4, BORDE)
	draw_string(letra, Vector2(0, 22), titulo, HORIZONTAL_ALIGNMENT_CENTER, ANCHO, 16, Color("#e6c34a"))
	# el fondo: papel oscuro cuadriculado, como el plano de una mazmorra
	var fondo := Rect2(8, 30, ANCHO - 16, ALTO - 38)
	draw_rect(fondo, FONDO)
	for gx in range(int(fondo.position.x) + 4, int(fondo.end.x), 8):
		for gy in range(int(fondo.position.y) + 4, int(fondo.end.y), 8):
			draw_rect(Rect2(gx, gy, 2, 2), CUADRICULA)
	var lista := casillas()
	# primero las sombras, luego los trocitos de pasillo que unen cada sala y, encima, las salas
	for c in lista:
		draw_rect(Rect2(c.r.position + Vector2(2, 2), c.r.size).grow(2), SOMBRA)
	for c in lista:
		if c.puerta.has_area():
			draw_rect(c.puerta.grow(2), BORDE)
			draw_rect(c.puerta, SUELO)
	for c in lista:
		var r: Rect2 = c.r
		var color: Color = AMARILLO if c.aqui else c.color
		draw_rect(r.grow(2), BORDE)
		draw_rect(r, color)
		# un poco de relieve: luz arriba, sombra abajo
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), color.lightened(0.25))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), color.darkened(0.3))
	# los trozos de pasillo se pintan otra vez por dentro, para que la sala y el pasillo queden abiertos
	for c in lista:
		if c.puerta.has_area():
			draw_rect(c.puerta, AMARILLO.darkened(0.15) if c.aqui else SUELO)
	if camaras:
		dibujar_zombis(lista)
	for c in lista:
		if c.icono != "":
			draw_texture_rect(ICONOS[c.icono], Rect2(c.r.get_center() - Vector2(8, 8), Vector2(16, 16)), false)
	# el "!" del superviviente, en una esquina de su sala
	for c in lista:
		if c.sos:
			var esquina: Vector2 = c.r.position + Vector2(c.r.size.x - 6, -4)
			draw_rect(Rect2(esquina, Vector2(10, 12)).grow(2), BORDE)
			draw_rect(Rect2(esquina, Vector2(10, 12)), Color("#ff5d73"))
			draw_string(letra, esquina + Vector2(-5, 12), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 16, Color.WHITE)
	# el marco que parpadea alrededor de donde estás
	for c in lista:
		if c.aqui:
			draw_rect(c.r.grow(4), Color(AMARILLO, 0.5 + sin(tiempo * 6.0) * 0.3), false, 2.0)


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


# Los zombis que quedan en el sitio "i" (donde no está Johnny: los que esperan dentro, si no está limpio)
func zombis_en(i: int) -> int:
	var sitio: Dictionary = partida.planta.sitios[i]
	return 0 if sitio.get("limpio", false) else sitio.get("zombis", []).size()


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
