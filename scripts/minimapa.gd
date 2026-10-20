# El minimapa (como drawMinimap de src/render.js del juego JS): un plano de la planta arriba a la derecha.
# El pasillo en medio, una casilla por cada puerta (arriba y abajo), la llegada a la izquierda y las escaleras
# a la derecha. Gris = sin visitar, rojo = con zombis dentro, claro = limpio, amarillo = donde estás (con un
# marco que parpadea). El piso de la portera lleva un candado y, cuando ya has entrado en el apartamento donde
# está su llave y aún no la has cogido, ese lleva la llave. Donde está encerrado el superviviente, un "!" rojo
# (supervivientes.gd).
# Es provisional: el minimapa bonito llegará con el arte de los escenarios.
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


func _ready() -> void:
	# el marco de metal oxidado de los botones, en 9 trozos (las esquinas no se estiran)
	marco.texture = preload("res://assets/ui/boton-oscuro.png")
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		marco.set_texture_margin(lado, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -ANCHO - 12
	offset_right = -12
	offset_top = 10
	offset_bottom = 10 + ALTO


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


# Las casillas: [rectángulo, color, ¿estás aquí?, icono, ¿está ahí el superviviente?]
func casillas() -> Array:
	var planta: Dictionary = partida.planta
	var pasillo: Dictionary = planta.sitios[0]
	var aqui: int = partida.aqui
	var lista := []
	var arriba := CABEZA + MARGEN
	var x0 := MARGEN + PUNTA + 4
	var largo := ANCHO - (MARGEN + PUNTA + 4) * 2
	lista.append([Rect2(x0, arriba + 22, largo, 12), CLARO, aqui == 0, "", false])
	var sos: int = planta.superviviente.sitio if partida.supervivientes.encerrado() else -1
	for s in pasillo.salidas:
		match s.tipo:
			"llegada":
				lista.append([Rect2(x0 - PUNTA - 4, arriba + 19, PUNTA, 18), GRIS, false, "puerta", false])
			"escaleras":
				var abiertas: bool = planta.jefa_muerta
				lista.append([Rect2(x0 + largo + 4, arriba + 19, PUNTA, 18), VERDE if abiertas else GRIS, false,
					"escalera" if abiertas else "candado", false])
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
				var y := arriba if s.dir == "arriba" else arriba + 38
				lista.append([Rect2(x0 + float(s.en) / pasillo.ancho * largo - 15, y, 30, 18), color,
					aqui == s.a or (planta.sitios[aqui].tipo == "expo" and sitio.tipo == "mantenimiento"), icono, s.a == sos])
	return lista


func _draw() -> void:
	if partida == null or partida.planta.is_empty():
		return
	draw_style_box(marco, Rect2(Vector2.ZERO, size))
	var letra := get_theme_default_font()
	var titulo: String = partida.planta.nombre
	draw_string_outline(letra, Vector2(0, 19), titulo, HORIZONTAL_ALIGNMENT_CENTER, ANCHO, 12, 4, BORDE)
	draw_string(letra, Vector2(0, 19), titulo, HORIZONTAL_ALIGNMENT_CENTER, ANCHO, 12, Color("#e6c34a"))
	var lista := casillas()
	for c in lista:
		var r: Rect2 = c[0]
		draw_rect(r, AMARILLO if c[2] else c[1])
		draw_rect(r, Color("#f2e6c0") if c[2] else BORDE, false, 2.0)
		if c[3] != "":
			draw_texture_rect(ICONOS[c[3]], Rect2(r.get_center() - Vector2(8, 8), Vector2(16, 16)), false)
	# el "!" del superviviente, en una esquina de su casilla
	for c in lista:
		if c[4]:
			var centro: Vector2 = c[0].position + Vector2(c[0].size.x - 2, 2)
			draw_circle(centro, 7.0, BORDE)
			draw_circle(centro, 5.5, Color("#ff5d73"))
			draw_string(letra, centro + Vector2(-10, 4), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 12, Color.WHITE)
	# el marco que parpadea alrededor de donde estás
	for c in lista:
		if c[2]:
			draw_rect(c[0].grow(3), Color(AMARILLO, 0.5 + sin(tiempo * 6.0) * 0.3), false, 2.0)
