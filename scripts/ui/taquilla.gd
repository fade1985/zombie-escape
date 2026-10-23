# La taquilla de Johnny, en la sala de mantenimiento (parte 11, trozo 3; mapa.gd la pone en la esquina):
# al arrimarse (mapa/arrimable.gd → partida.abrir_taquilla) el juego se para y sale esta ventanita para elegir
# el traje (trajes.gd): a la izquierda, Johnny de frente con el traje marcado (en silueta si aún no se tiene), y
# a la derecha la lista: el conserje de siempre y los cuatro trajes, los que faltan con «???». Se elige uno y
# Johnny se lo pone en el acto, y se queda puesto (Trajes.poner). Va con el ratón o el dedo, con flechas e Intro
# (o 1 a 5) o con el mando (cruceta y A). Esc o B la cierra.
extends CanvasLayer

const COLOR := Color("#9fd3ff")   # el color de la taquilla (su letrero en la sala, y el título)

var partida: Node
var fondo: ColorRect
var info: Label
var vista: AnimatedSprite2D      # Johnny de frente, con el traje marcado
var nombre_vista: Label
var cartas := {}                 # id → su botón ("" = el conserje de siempre)
var puestos := {}                # id → la etiqueta «Puesto» de su carta
var tenidos: Array = []          # los trajes que se tienen (al abrir)
var marcado := ""                # el traje que enseña la vista


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abierta() -> bool:
	return fondo != null


# Los ids en el orden de la lista: el conserje de siempre y luego los trajes
func ids() -> Array:
	return [""] + Trajes.LISTA.keys()


func tiene(id: String) -> bool:
	return id == "" or id in tenidos


# El fondo oscuro y, encima, el panel: la vista de Johnny a la izquierda y la lista de trajes a la derecha
func abrir(p: Node) -> void:
	partida = p
	quitar()
	tenidos = Trajes.tenidos()
	fondo = ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, 0.72)
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

	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = "Taquilla de Johnny"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COLOR)
	columna.add_child(titulo)
	var sub := Label.new()
	sub.theme_type_variation = "Sub"
	sub.text = "«La ropa de la tienda de ropa. Lo que te pongas se queda puesto»"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(sub)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	columna.add_child(fila)
	# la vista: Johnny de frente, al triple, con su hoja de la fregona y el shader de la cintura (los colores)
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 4)
	fila.add_child(lado)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(160, 176)
	lado.add_child(hueco)
	var w: Dictionary = Armas.datos("fregona")
	vista = AnimatedSprite2D.new()
	vista.sprite_frames = w.hoja
	vista.centered = false
	vista.offset = -w.pies
	vista.scale = Vector2(3, 3)
	vista.position = Vector2(80, 168)   # los pies
	vista.material = partida.johnny.sprite.material.duplicate()
	vista.material.set_shader_parameter("parte", 0)
	hueco.add_child(vista)
	vista.play("reposo_s")
	nombre_vista = Label.new()
	nombre_vista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_vista.custom_minimum_size.x = 160
	nombre_vista.add_theme_color_override("font_color", COLOR)
	lado.add_child(nombre_vista)

	# la lista: una carta por traje, con su icono, su nombre y su frase
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 6)
	fila.add_child(lista)
	var todos := ids()
	for i in todos.size():
		var id: String = todos[i]
		var carta := Button.new()
		carta.custom_minimum_size = Vector2(440, 60)
		carta.pressed.connect(elegir.bind(id))
		carta.focus_entered.connect(marcar.bind(id))
		carta.mouse_entered.connect(marcar.bind(id))
		lista.add_child(carta)
		cartas[id] = carta
		var dentro := HBoxContainer.new()
		dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
		dentro.offset_left = 12
		dentro.offset_right = -12
		dentro.offset_top = 6
		dentro.offset_bottom = -6
		dentro.add_theme_constant_override("separation", 10)
		dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		carta.add_child(dentro)
		var imagen := TextureRect.new()
		imagen.texture = load("res://assets/ui/iconos/%s.png" % ("fregona" if id == "" else "obj-" + Trajes.objeto(id)))
		imagen.custom_minimum_size = Vector2(32, 32)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		imagen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not tiene(id):
			imagen.modulate = Color(1, 1, 1, 0.35)   # apagado, como en Colecciones
		dentro.add_child(imagen)
		var textos := VBoxContainer.new()
		textos.add_theme_constant_override("separation", 0)
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(textos)
		etiqueta(textos, "%d. %s" % [i + 1, Trajes.nombre(id) if tiene(id) else "???"], 22)
		var frase: String
		if not tiene(id):
			frase = "Aún no lo tienes: lo sueltan los zombis de la tienda de ropa."
		elif id == "":
			frase = "La ropa de siempre: peto vaquero, camisa crema y pañuelo rojo."
		else:
			frase = Trajes.LISTA[id].desc
		var desc := etiqueta(textos, frase, 15)
		desc.theme_type_variation = "Sub"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		puestos[id] = etiqueta(dentro, "", 18)
		puestos[id].add_theme_color_override("font_color", Tema.VERDE)
		puestos[id].size_flags_vertical = Control.SIZE_SHRINK_CENTER

	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size.y = 24
	columna.add_child(info)
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(pie)
	var cerrar_b := Button.new()
	cerrar_b.text = "Cerrar"
	cerrar_b.pressed.connect(cerrar)
	pie.add_child(cerrar_b)
	refrescar()
	var puesto := Trajes.puesto()
	marcar(puesto)
	(cartas[puesto] as Button).grab_focus.call_deferred()
	# entra con un pequeño salto, como los menús
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.9, 0.9)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func etiqueta(padre: Container, texto: String, tamano: int) -> Label:
	var e := Label.new()
	e.text = texto
	e.add_theme_font_size_override("font_size", tamano)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(e)
	return e


# La marca «Puesto» en la carta del traje que lleva
func refrescar() -> void:
	var puesto := Trajes.puesto()
	for id in puestos:
		puestos[id].text = "Puesto" if id == puesto else ""


# La vista enseña ese traje (al pasar por su carta): si aún no se tiene, en silueta y «???»
func marcar(id: String) -> void:
	if fondo == null:
		return
	marcado = id
	Trajes.vestir(vista.material, id)
	vista.modulate = Color.WHITE if tiene(id) else Color(0.05, 0.04, 0.08, 0.9)
	nombre_vista.text = Trajes.nombre(id) if tiene(id) else "???"


# Ponerse ese traje (si se tiene): se guarda y Johnny cambia en el acto. Devuelve si se lo ha puesto
func elegir(id: String) -> bool:
	if fondo == null:
		return false
	if not tiene(id):
		info.text = "Aún no lo tienes: lo sueltan los zombis de la tienda de ropa (y la modista, uno seguro)."
		info.add_theme_color_override("font_color", Tema.ROJO)
		Sonido.tocar("no")
		return false
	if id == Trajes.puesto():
		info.text = "Ya lo llevas puesto."
		info.add_theme_color_override("font_color", Tema.TINTA)
		return false
	Trajes.poner(id)
	partida.johnny.vestir(id)
	Sonido.tocar("cambiar")
	info.text = "Vuelves a tu ropa de siempre." if id == "" else "Te pones: %s. Se queda puesto." % Trajes.nombre(id)
	info.add_theme_color_override("font_color", Tema.VERDE)
	refrescar()
	marcar(id)
	return true


func cerrar() -> void:
	if fondo == null:
		return
	quitar()
	get_tree().paused = false


func quitar() -> void:
	if fondo:
		fondo.queue_free()
		fondo = null
	cartas.clear()
	puestos.clear()


# Esc o B: cerrar. 1 a 5: ponerse ese
func _unhandled_input(evento: InputEvent) -> void:
	if fondo == null:
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()
	elif evento is InputEventKey and evento.pressed and not evento.echo:
		var n: int = {KEY_1: 0, KEY_KP_1: 0, KEY_2: 1, KEY_KP_2: 1, KEY_3: 2, KEY_KP_3: 2, KEY_4: 3, KEY_KP_4: 3,
			KEY_5: 4, KEY_KP_5: 4}.get(evento.keycode, -1)
		if n >= 0 and n < ids().size():
			get_viewport().set_input_as_handled()
			elegir(ids()[n])
