# La pantalla de los relatos (historia.gd, RELATOS): un texto sobre negro, con las líneas apareciendo una a una.
# La abre partida.gd (ver_relato) con el juego parado, con Relato.abrir(dueño, id), y avisa al cerrarse con la señal
# "cerrado". Las líneas salen solas, cada una al cabo de lo que cuesta leer la anterior (POR_LINEA y POR_LETRA). Cualquier
# tecla, clic, toque o botón del mando saca la siguiente; con todas a la vista, otra pulsación cierra. Esc o B la saltan
# entera. Las primeras décimas no hace caso (ESPERA): así, un Espacio de esquivar o un clic de atacar que pilla la pantalla
# al salir no se la salta.
# Va por _input, antes que nadie: el fondo no recoge los clics y la pulsación no llega a lo que hay debajo.
class_name Relato
extends CanvasLayer

signal cerrado

const ANCHO := 1040.0     # lo más anchas que son las líneas (se parten solas si no caben)...
const MARGEN := 30.0      # ...y, en una pantalla estrecha, lo que dejan a cada lado
const ESPERA := 0.6       # segundos que la pantalla no hace caso al salir; a esa hora sale la primera línea
const POR_LINEA := 2.0    # lo que se queda sola cada línea, antes de la siguiente...
const POR_LETRA := 0.04   # ...más esto por cada letra: las largas tardan más en leerse
const FUNDIDO := 0.5      # lo que tarda en aparecer una línea y en irse la pantalla
const REBOTE := 150       # milisegundos sin hacer caso tras una pulsación: un toque llega dos veces (el dedo y el
                          # ratón que lo imita, ver tactil.gd)
# Las teclas que no pasan de línea: las que se pulsan para otra cosa (Alt+Tab) y la de la pantalla completa (pantalla.gd)
const NO_CUENTAN := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_F11]

var id := ""
var fondo: ColorRect
var columna: VBoxContainer
var lineas: Array[Label] = []
var vistas := 0               # cuántas están ya a la vista
var falta := ESPERA           # lo que queda para la siguiente
var abierta := 0.0            # cuánto lleva abierta
var ultima := -REBOTE         # cuándo fue la última pulsación que contó (en milisegundos)


static func abrir(dueno: Node, cual: String) -> Relato:
	var r := Relato.new()
	r.id = cual
	dueno.add_child(r)
	return r


func _ready() -> void:
	layer = 13   # encima de todo lo demás, también de los tutoriales
	process_mode = Node.PROCESS_MODE_ALWAYS   # sale con el juego parado
	fondo = ColorRect.new()
	fondo.color = Color.BLACK
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	columna = VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.custom_minimum_size.x = minf(ANCHO, get_viewport().get_visible_rect().size.x - 2.0 * MARGEN)
	columna.add_theme_constant_override("separation", 16)
	centro.add_child(columna)
	# Todas desde el principio, transparentes: así el texto no se mueve al ir saliendo
	for texto in Historia.lineas_de(id):
		var l := Label.new()
		l.text = texto
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 32)
		l.modulate.a = 0.0
		columna.add_child(l)
		lineas.append(l)
	lineas[-1].add_theme_color_override("font_color", Tema.AMARILLO)   # el estribillo
	var pie := Label.new()
	pie.theme_type_variation = "Sub"
	pie.text = como_seguir()
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.position.y = -32.0
	fondo.add_child(pie)


# Lo que se pulsa para seguir, según con qué se juegue (como Tutoriales.tecla)
func como_seguir() -> String:
	if Tactil.activo:
		return Idioma.t("Toca la pantalla para continuar")
	if not Input.get_connected_joypads().is_empty():
		return Idioma.t("Pulsa cualquier botón para continuar · B para saltar")
	return Idioma.t("Pulsa cualquier tecla para continuar · Esc para saltar")


func _process(delta: float) -> void:
	abierta += delta
	falta -= delta
	if falta <= 0.0 and vistas < lineas.size():
		siguiente()


func siguiente() -> void:
	var l := lineas[vistas]
	l.create_tween().tween_property(l, "modulate:a", 1.0, FUNDIDO)
	vistas += 1
	falta = POR_LINEA + l.text.length() * POR_LETRA


func cerrar() -> void:
	set_process(false)
	set_process_input(false)
	cerrado.emit()
	# se va despacio, con lo de detrás (la sala o el cartel del final) ya a punto
	var tween := fondo.create_tween()
	tween.tween_property(fondo, "modulate:a", 0.0, FUNDIDO)
	tween.tween_callback(queue_free)


# Una tecla, un clic (no la rueda), un toque o un botón del mando recién pulsados
func es_pulsacion(evento: InputEvent) -> bool:
	if evento is InputEventKey:
		return evento.pressed and not evento.echo and not evento.alt_pressed and not evento.keycode in NO_CUENTAN
	if evento is InputEventMouseButton:
		return evento.pressed and evento.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	return (evento is InputEventScreenTouch or evento is InputEventJoypadButton) and evento.pressed


func _input(evento: InputEvent) -> void:
	if not es_pulsacion(evento):
		return
	get_viewport().set_input_as_handled()
	var ahora := Time.get_ticks_msec()
	if abierta < ESPERA or ahora - ultima < REBOTE:
		return
	ultima = ahora
	# (ui_cancel solo trae Esc: el B del mando se mira aparte)
	var saltar: bool = evento.is_action_pressed("ui_cancel") or (evento is InputEventJoypadButton and evento.button_index == JOY_BUTTON_B)
	if saltar or vistas >= lineas.size():
		cerrar()
	else:
		siguiente()
