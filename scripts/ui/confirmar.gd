# La ventanita de «¿Estás seguro?», en el centro de la pantalla, para lo que no se puede deshacer (borrar una partida,
# destruir algo del inventario o del baúl). Debajo, si hace falta, qué se perdería, y los botones Sí y No. Empieza con
# el foco en No, para que un Intro sin mirar no borre nada; Esc o B también dicen que no.
#   Confirmar.preguntar(dueño, detalle).respondido.connect(func(si): ...)
# Mientras está abierta, Confirmar.abierta es true (el inventario la mira para no hacer caso de sus atajos).
class_name Confirmar
extends CanvasLayer

signal respondido(si: bool)

static var abierta := false

var detalle := ""
var hecho := false


static func preguntar(dueno: Node, que_se_pierde := "") -> Confirmar:
	var c := Confirmar.new()
	c.detalle = que_se_pierde
	dueno.add_child(c)
	return c


func _ready() -> void:
	abierta = true
	layer = 13   # encima de todo (también de los tutoriales)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, 0.6)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = Idioma.t("¿Estás seguro?")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	if detalle != "":
		var texto := Label.new()
		texto.theme_type_variation = "Sub"
		texto.text = detalle
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto.custom_minimum_size.x = 420
		columna.add_child(texto)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 16)
	columna.add_child(fila)
	var si := Button.new()
	si.text = Idioma.t("Sí")
	si.theme_type_variation = "BotonRojo"
	si.custom_minimum_size.x = 140
	si.pressed.connect(responder.bind(true))
	fila.add_child(si)
	var no := Button.new()
	no.text = Idioma.t("No")
	no.custom_minimum_size.x = 140
	no.pressed.connect(responder.bind(false))
	fila.add_child(no)
	no.grab_focus.call_deferred()
	Sonido.tocar("click")
	# Entra con un pequeño salto, como los menús
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.9, 0.9)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func responder(si: bool) -> void:
	if hecho:   # (Esc y un botón en el mismo fotograma)
		return
	hecho = true
	abierta = false
	respondido.emit(si)
	queue_free()


func _exit_tree() -> void:
	abierta = false


# Va antes que el _input de lo de detrás (es hija suya): Esc, B o Start dicen que no y no llegan al inventario ni a
# la pantalla de partidas (que se cerrarían)
func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		responder(false)
