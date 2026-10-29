# Las pantallas de los tutoriales (tutoriales.gd):
#   - Tutorial.ventana(dueño, id): la ficha de algo nuevo, la primera vez que sale (la abre partida.gd con el juego
#     parado; el menú principal, la de la alerta). La cierran «Entendido», Esc, B o Start. El botón no hace caso las
#     primeras décimas (ESPERA): así, un Espacio de esquivar o un clic de atacar que pilla la ventana al salir no la
#     cierra sin leerla.
#   - Tutorial.lista(dueño, lo_que_tapa): el apartado Tutorial del menú principal y de la pausa. A la izquierda los
#     temas por grupos (los que aún no han salido, con «???») y a la derecha la ficha del elegido. Mientras está
#     abierto esconde "lo_que_tapa" (el menú de detrás), como Opciones.
# Las dos avisan al cerrarse con la señal "cerrado". Se manejan con el ratón, las flechas o el mando.
# La ficha (ficha()): el icono y el título, la foto (assets/ui/tutorial/<id>.png, a tamaño real) y las líneas.
class_name Tutorial
extends CanvasLayer

signal cerrado

const ANCHO := 520.0       # el de la ficha y el de su foto (520 × 180, recortada por tools/fotos_tutorial.py)
const ALTO_LISTA := 430.0  # el de la lista de temas (con barra si no caben)
const ESPERA := 0.6        # segundos que la ventana no hace caso al salir

var id := ""               # la ficha de la ventana ("" = es la lista)
var tapado: CanvasItem     # (lista) el menú de detrás
var listo := false         # (ventana) ya ha pasado la ESPERA
var derecha: VBoxContainer # (lista) donde va la ficha del elegido
var botones := {}          # (lista) el botón de cada tema
var elegido := ""


static func ventana(dueno: Node, cual: String) -> Tutorial:
	var t := Tutorial.new()
	t.id = cual
	dueno.add_child(t)
	return t


static func lista(dueno: Node, tapar: CanvasItem) -> Tutorial:
	var t := Tutorial.new()
	t.tapado = tapar
	dueno.add_child(t)
	return t


func _ready() -> void:
	layer = 12   # encima de todo lo demás (la pausa, Opciones, el ordenador...)
	process_mode = Node.PROCESS_MODE_ALWAYS   # sale con el juego parado
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, 0.8 if id != "" else 0.85)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	panel.add_child(columna)
	if id != "":
		montar_ventana(columna)
	else:
		if tapado:
			tapado.hide()
		montar_lista(columna)
	# Entra con un pequeño salto, como los menús
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.9, 0.9)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func montar_ventana(columna: VBoxContainer) -> void:
	Sonido.tocar("click")
	var nuevo := Label.new()
	nuevo.text = Idioma.t("¡Nuevo!")
	nuevo.add_theme_color_override("font_color", Tema.AMARILLO)
	nuevo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(nuevo)
	columna.add_child(ficha(id))
	var pie := Label.new()
	pie.theme_type_variation = "Sub"
	pie.text = Idioma.t("Puedes volver a verlo en Tutorial, en el menú principal y en la pausa")
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(pie)
	var vale := Button.new()
	vale.text = Idioma.t("Entendido")
	vale.custom_minimum_size.x = 200
	vale.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vale.disabled = true
	vale.pressed.connect(cerrar)
	columna.add_child(vale)
	# el foco, ya (si no, en el menú se quedaría en la tarjeta de detrás y un Intro empezaría la partida), y el botón,
	# al rato
	vale.grab_focus.call_deferred()
	await get_tree().create_timer(ESPERA).timeout
	listo = true
	vale.disabled = false
	vale.grab_focus()


func montar_lista(columna: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = Idioma.t("Tutorial")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	var lado := HBoxContainer.new()
	lado.add_theme_constant_override("separation", 24)
	columna.add_child(lado)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260, ALTO_LISTA)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	lado.add_child(scroll)
	# un margen a la izquierda, para que los temas no vayan pegados al borde de la ventana
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 16)
	scroll.add_child(margen)
	var temas := VBoxContainer.new()
	temas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	temas.add_theme_constant_override("separation", 0)
	margen.add_child(temas)
	var vacio := StyleBoxEmpty.new()
	for grupo in Tutoriales.GRUPOS:
		var g := Label.new()
		g.theme_type_variation = "Sub"
		g.text = grupo
		temas.add_child(g)
		for cual in Tutoriales.LISTA:
			if Tutoriales.LISTA[cual].grupo != grupo:
				continue
			var b := Button.new()
			b.theme_type_variation = "Celda"
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if Tutoriales.se_ve(cual):
				b.text = Tutoriales.LISTA[cual].titulo
				b.focus_entered.connect(ver.bind(cual))
				b.pressed.connect(ver.bind(cual))
			else:
				b.text = "???"
				b.disabled = true
				b.focus_mode = Control.FOCUS_NONE
				b.add_theme_stylebox_override("disabled", vacio)
				b.add_theme_color_override("font_disabled_color", Color(Tema.GRIS, 0.5))
			botones[cual] = b
			temas.add_child(b)
	derecha = VBoxContainer.new()
	derecha.custom_minimum_size = Vector2(ANCHO, ALTO_LISTA)
	lado.add_child(derecha)
	var volver := Button.new()
	volver.text = Idioma.t("Volver")
	volver.custom_minimum_size.x = 180
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(cerrar)
	columna.add_child(volver)
	ver("jugar")   # («Cómo se juega» siempre se ve)
	(botones.jugar as Button).grab_focus.call_deferred()


# (lista) Pone a la derecha la ficha de un tema y marca su botón en amarillo
func ver(cual: String) -> void:
	if cual == elegido:
		return
	elegido = cual
	for hijo in derecha.get_children():
		hijo.queue_free()
	derecha.add_child(ficha(cual))
	for k in botones:
		var b: Button = botones[k]
		if b.disabled:
			continue
		for c in ["font_color", "font_focus_color", "font_hover_color"]:
			b.add_theme_color_override(c, Tema.AMARILLO if k == cual else Tema.TINTA)


# La ficha de un tutorial: el icono y el título, la foto con su marco y las líneas, con las teclas en amarillo
static func ficha(cual: String) -> VBoxContainer:
	var d: Dictionary = Tutoriales.LISTA[cual]
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	var cabeza := Tema.icono_y_texto(d.icono, d.titulo, 32)
	cabeza.alignment = BoxContainer.ALIGNMENT_CENTER
	(cabeza.get_child(cabeza.get_child_count() - 1) as Label).theme_type_variation = "Titulo"
	caja.add_child(cabeza)
	var ruta := "res://assets/ui/tutorial/%s.png" % cual
	if ResourceLoader.exists(ruta):
		var marco := PanelContainer.new()
		var borde := StyleBoxFlat.new()
		borde.bg_color = Tema.LINEA
		borde.set_border_width_all(2)
		borde.border_color = Tema.OXIDO
		borde.set_content_margin_all(2)
		marco.add_theme_stylebox_override("panel", borde)
		marco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var foto := TextureRect.new()
		foto.texture = load(ruta)
		foto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marco.add_child(foto)
		caja.add_child(marco)
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.focus_mode = Control.FOCUS_NONE
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = ANCHO
	texto.add_theme_color_override("default_color", Tema.TINTA)
	texto.add_theme_color_override("font_outline_color", Tema.LINEA)
	texto.add_theme_constant_override("outline_size", 4)
	texto.add_theme_constant_override("line_separation", 2)
	texto.add_theme_constant_override("paragraph_separation", 6)
	texto.text = Tutoriales.texto(cual)
	caja.add_child(texto)
	return caja


func cerrar() -> void:
	if is_queued_for_deletion():   # (Esc y el botón en el mismo fotograma)
		return
	if tapado:
		tapado.show()
	cerrado.emit()
	queue_free()


# Esc o B cierran (la ventana, también Start; y no antes de la ESPERA)
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") or (id != "" and evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		if id == "" or listo:
			cerrar()
