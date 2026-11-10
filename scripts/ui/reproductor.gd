# El reproductor multimedia de VIDEOS.EXE (M91), como los de los 90: marco azul de cristal oscuro, la pantalla con los
# subtítulos debajo (la emisión de Canal 8, tele.gd), la barra de avance, el contador de tiempo, y los botones de parar,
# anterior, reproducir/pausa y siguiente, con un volumen de adorno. Parar, reproducir/pausa, anterior y siguiente funcionan;
# la barra y el volumen son solo de adorno (el vídeo se ve seguido, como en la tele). "cambiar" dice a qué vídeo ir (-1, +1).
class_name Reproductor
extends Control

signal cambiar(delta: int)

const ANCHO := 452.0
const MARGEN := 10.0
const ALTO_TITULO := 16.0
const ALTO_CONTROLES := 44.0
const ALTO_BARRA := 8.0
const FONDO_ARRIBA := Color("#244a8a")
const FONDO_ABAJO := Color("#0a1630")
const BORDE := Color("#5d8fd6")
const CELESTE := Color("#6cb4ff")
const CRISTAL := Color("#0b1224")

var tele: Tele
var b_play: Button
var b_stop: Button
var b_prev: Button
var b_next: Button
var barra_y := 0.0     # dónde empieza la barra de avance
var mando_y := 0.0     # dónde empiezan los botones


func _ready() -> void:
	tele = Tele.new()
	tele.escala = 1.5
	tele.continuo = true
	tele.position = Vector2(MARGEN, ALTO_TITULO + 6.0)
	add_child(tele)   # (ya en el árbol: monta la pantalla y los subtítulos)
	barra_y = tele.position.y + tele.custom_minimum_size.y + 6.0
	mando_y = barra_y + ALTO_BARRA + 6.0
	custom_minimum_size = Vector2(ANCHO, mando_y + ALTO_CONTROLES + 6.0)
	size = custom_minimum_size
	var medio := mando_y + ALTO_CONTROLES / 2.0
	b_stop = boton_icono("b_stop", "stop", Rect2(96, medio - 15, 30, 30), true, Idioma.t("Parar"))
	b_prev = boton_icono("b_prev", "anterior", Rect2(138, medio - 15, 30, 30), true, Idioma.t("Anterior"))
	b_play = boton_icono("b_play", "play", Rect2(178, medio - 21, 42, 42), true, Idioma.t("Reproducir"))
	b_next = boton_icono("b_next", "siguiente", Rect2(230, medio - 15, 30, 30), true, Idioma.t("Siguiente"))
	b_stop.pressed.connect(tele.parar)
	b_play.pressed.connect(tele.alternar)
	b_prev.pressed.connect(func(): cambiar.emit(-1))
	b_next.pressed.connect(func(): cambiar.emit(1))


# Pone una noticia en la pantalla (empieza a verse)
func poner(n: Dictionary) -> void:
	tele.poner(n)


# Un botón redondo con su dibujo (se dibuja por código, para no depender de que la letra tenga las flechas)
func boton_icono(nombre: String, icono: String, r: Rect2, redondo: bool, pista: String) -> Button:
	var b := Button.new()
	b.name = nombre
	b.position = r.position
	b.size = r.size
	b.tooltip_text = pista
	b.focus_mode = Control.FOCUS_ALL
	var radio := int(r.size.x / 2.0) if redondo else 6
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.set_corner_radius_all(radio)
		e.bg_color = Color("#2d62b8") if estado == "normal" else (Color("#4a86e0") if estado == "hover" else Color("#1b3f80"))
		e.border_color = Color("#bfe0ff") if estado == "focus" else Color("#7db3f5")
		e.set_border_width_all(2 if estado != "focus" else 3)
		if estado == "focus":
			e.draw_center = false
		b.add_theme_stylebox_override(estado, e)
	b.draw.connect(dibujar_icono.bind(b, icono))
	add_child(b)
	return b


func dibujar_icono(b: Button, icono: String) -> void:
	var c := b.size / 2.0
	var k := b.size.x / 30.0
	var blanco := Color("#f4f8ff")
	if icono == "play":
		if tele.parada or tele.terminada or tele.noticia.is_empty():
			b.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -10) * k, c + Vector2(10, 0) * k, c + Vector2(-6, 10) * k]), blanco)
		else:   # (sonando: el botón es el de pausa)
			b.draw_rect(Rect2(c + Vector2(-8, -9) * k, Vector2(5, 18) * k), blanco)
			b.draw_rect(Rect2(c + Vector2(3, -9) * k, Vector2(5, 18) * k), blanco)
	elif icono == "stop":
		b.draw_rect(Rect2(c - Vector2(6, 6) * k, Vector2(12, 12) * k), blanco)
	elif icono == "anterior":
		b.draw_rect(Rect2(c + Vector2(-9, -7) * k, Vector2(3, 14) * k), blanco)
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 0) * k, c + Vector2(3, -7) * k, c + Vector2(3, 7) * k]), blanco)
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(3, 0) * k, c + Vector2(10, -7) * k, c + Vector2(10, 7) * k]), blanco)
	elif icono == "siguiente":
		b.draw_rect(Rect2(c + Vector2(6, -7) * k, Vector2(3, 14) * k), blanco)
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(5, 0) * k, c + Vector2(-3, -7) * k, c + Vector2(-3, 7) * k]), blanco)
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 0) * k, c + Vector2(-10, -7) * k, c + Vector2(-10, 7) * k]), blanco)


func _process(_delta: float) -> void:
	queue_redraw()
	b_play.queue_redraw()
	b_play.tooltip_text = Idioma.t("Pausa") if not (tele.parada or tele.terminada) else Idioma.t("Reproducir")


func _draw() -> void:
	var fuente := get_theme_default_font()
	# el marco: un degradado azul de arriba abajo y un filo claro
	var franjas := 24
	for i in franjas:
		var y0 := size.y * i / franjas
		draw_rect(Rect2(0, y0, size.x, size.y / franjas + 1.0), FONDO_ARRIBA.lerp(FONDO_ABAJO, float(i) / (franjas - 1)))
	draw_rect(Rect2(Vector2.ZERO, size), BORDE, false, 2.0)
	draw_string(fuente, Vector2(MARGEN, 12), Idioma.t("Reproductor de Canal 8"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#dbeaff"))
	# el hueco de la pantalla: un filo oscuro
	draw_rect(Rect2(tele.position - Vector2(2, 2), tele.custom_minimum_size + Vector2(4, 4)), Color("#050810"), false, 2.0)
	# la barra de avance: la pista, lo andado y el botón redondo
	var pista := Rect2(MARGEN, barra_y, size.x - MARGEN * 2.0, ALTO_BARRA)
	draw_rect(pista, CRISTAL)
	draw_rect(pista, Color("#38507f"), false, 1.0)
	var avance := clampf(tele.progreso(), 0.0, 1.0)
	draw_rect(Rect2(pista.position + Vector2(1, 1), Vector2((pista.size.x - 2.0) * avance, ALTO_BARRA - 2.0)), CELESTE)
	draw_circle(Vector2(pista.position.x + 1.0 + (pista.size.x - 2.0) * avance, barra_y + ALTO_BARRA / 2.0), 6.0, Color("#e8f3ff"))
	# el contador de tiempo, a la izquierda, y el volumen de adorno, a la derecha
	var segundos := int(tele.reproducido)
	var medio := mando_y + ALTO_CONTROLES / 2.0
	draw_string(fuente, Vector2(MARGEN + 4, medio + 6), "%02d:%02d" % [segundos / 60, segundos % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e8f3ff"))
	var altavoz := Vector2(size.x - 128.0, medio)
	draw_rect(Rect2(altavoz + Vector2(-8, -4), Vector2(5, 8)), Color("#dbeaff"))
	draw_colored_polygon(PackedVector2Array([altavoz + Vector2(-3, -4), altavoz + Vector2(4, -9), altavoz + Vector2(4, 9), altavoz + Vector2(-3, 4)]), Color("#dbeaff"))
	var carril := Rect2(altavoz.x + 14.0, medio - 3.0, 80.0, 6.0)
	draw_rect(carril, CRISTAL)
	draw_rect(Rect2(carril.position, Vector2(carril.size.x * 0.7, carril.size.y)), CELESTE)
	draw_circle(Vector2(carril.position.x + carril.size.x * 0.7, medio), 5.0, Color("#e8f3ff"))
