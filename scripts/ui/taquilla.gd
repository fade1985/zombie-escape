# La taquilla de Johnny, en el vestuario de la sala de mantenimiento (la pone mapa.gd): al arrimarse
# (mapa/arrimable.gd → partida.abrir_taquilla) el juego se para y sale esta ventanita para elegir la skin
# (skins.gd): a la izquierda, Johnny de frente con la skin marcada (en silueta si aún no se tiene), y a la derecha
# la lista: el conserje de siempre y las skins, con su cara de icono y lo que hacen puestas; las que faltan, con «???»
# y cómo se consiguen. Se elige una y Johnny se la pone en el acto, y se queda puesta (Skins.poner). Va con el ratón
# o el dedo, con flechas e Intro (o 1 a 5) o con el mando (cruceta y A). Esc o B la cierra.
extends CanvasLayer

const COLOR := Color("#9fd3ff")   # el color de la taquilla (el del título)

var partida: Node
var fondo: ColorRect
var info: Label
var vista: AnimatedSprite2D      # Johnny de frente, con la skin marcada
var nombre_vista: Label
var cartas := {}                 # id → su botón ("" = el conserje de siempre)
var puestos := {}                # id → la etiqueta «Puesta» de su carta (al lado del nombre)
var hoja: SpriteFrames           # la hoja de la fregona de siempre (la vista enseña la de cada skin)
var tenidos: Array = []          # las skins que se tienen (al abrir)
var marcado := ""                # la skin que enseña la vista


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abierta() -> bool:
	return fondo != null


# Los ids en el orden de la lista: el conserje de siempre y luego las skins
func ids() -> Array:
	return [""] + Skins.LISTA.keys()


func tiene(id: String) -> bool:
	return id == "" or id in tenidos


# El fondo oscuro y, encima, el panel: la vista de Johnny a la izquierda y la lista de skins a la derecha
func abrir(p: Node) -> void:
	partida = p
	quitar()
	tenidos = Skins.tenidas()
	Guardado.cambiar(func(g): g.skins_nuevo = false)   # ya las has visto: se quita el «!» de la taquilla
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
	titulo.text = Idioma.t("Taquilla de Johnny")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COLOR)
	columna.add_child(titulo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	columna.add_child(fila)
	# la vista: Johnny de frente, al triple, con la hoja de la fregona de la skin marcada (marcar)
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 4)
	fila.add_child(lado)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(160, 176)
	lado.add_child(hueco)
	var w: Dictionary = Armas.datos("fregona")
	hoja = w.hoja
	vista = AnimatedSprite2D.new()
	vista.sprite_frames = hoja
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

	# la lista: una carta por skin, con su cara de icono (tools/cara.py), su nombre y su efecto
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 6)
	lista.sort_children.connect(igualar.bind(lista))
	fila.add_child(lista)
	var todos := ids()
	for i in todos.size():
		var id: String = todos[i]
		# la carta crece con su frase (un botón no se agranda solo con lo que lleva dentro): en un marco, el botón
		# detrás y lo de dentro encima, y el marco se hace tan alto como haga falta para que no se salga nada
		var marco := PanelContainer.new()
		marco.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		lista.add_child(marco)
		var carta := Button.new()
		carta.custom_minimum_size = Vector2(500, 60)
		carta.pressed.connect(elegir.bind(id))
		carta.focus_entered.connect(marcar.bind(id))
		carta.mouse_entered.connect(marcar.bind(id))
		marco.add_child(carta)
		cartas[id] = carta
		var margen := MarginContainer.new()
		margen.add_theme_constant_override("margin_left", 12)
		margen.add_theme_constant_override("margin_right", 16)   # (que «Puesta» no se arrime al remache)
		for borde in ["top", "bottom"]:
			margen.add_theme_constant_override("margin_" + borde, 9)
		margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marco.add_child(margen)
		var dentro := HBoxContainer.new()
		dentro.add_theme_constant_override("separation", 10)
		dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margen.add_child(dentro)
		var imagen := TextureRect.new()
		imagen.texture = load("res://assets/ui/iconos/skin-%s.png" % ("conserje" if id == "" else id))
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
		# arriba, el nombre y, a su derecha, «Puesta» (en la línea del nombre, para que la frase tenga todo el ancho)
		var cabecera := HBoxContainer.new()
		cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
		textos.add_child(cabecera)
		var nombre := etiqueta(cabecera, "%d. %s" % [i + 1, Skins.nombre(id) if tiene(id) else "???"], 22)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		puestos[id] = etiqueta(cabecera, "", 18)
		puestos[id].add_theme_color_override("font_color", Tema.VERDE)
		puestos[id].size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# debajo, lo que hace llevarla puesta (las que faltan, cómo se consiguen); parte las líneas y la carta crece
		var frase: String
		if not tiene(id):
			frase = Idioma.t("Aún no la tienes: %s") % Skins.como(id).to_lower()
		elif id == "":
			frase = Idioma.t("Sin efecto especial.")
		else:
			frase = Skins.efecto(id)
		var efecto := etiqueta(textos, frase, 15)
		efecto.theme_type_variation = "Sub"
		efecto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size.y = 24
	columna.add_child(info)
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(pie)
	var cerrar_b := Button.new()
	cerrar_b.text = Idioma.t("Cerrar")
	cerrar_b.pressed.connect(cerrar)
	pie.add_child(cerrar_b)
	refrescar()
	var puesto := Skins.puesta()
	marcar(puesto)
	(cartas[puesto] as Button).grab_focus.call_deferred()
	# entra con un pequeño salto, como los menús
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.9, 0.9)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Todas las cartas tan altas como la más alta (la de la frase más larga), para que la lista quede pareja. Se mira lo
# que pide lo de dentro de cada una (no la carta, que ya lleva el alto igualado) y se repite cada vez que se recoloca
func igualar(lista: VBoxContainer) -> void:
	var alto := 0.0
	for marco in lista.get_children():
		for hijo in marco.get_children():
			alto = maxf(alto, hijo.get_combined_minimum_size().y)
	for marco in lista.get_children():
		marco.custom_minimum_size.y = alto


func etiqueta(padre: Container, texto: String, tamano: int) -> Label:
	var e := Label.new()
	e.text = texto
	e.add_theme_font_size_override("font_size", tamano)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(e)
	return e


# La marca «Puesta» en la carta de la skin que lleva
func refrescar() -> void:
	var puesto := Skins.puesta()
	for id in puestos:
		puestos[id].text = Idioma.t("Puesta") if id == puesto else ""


# La vista enseña esa skin (al pasar por su carta): si aún no se tiene, en silueta y «???»
func marcar(id: String) -> void:
	if fondo == null:
		return
	marcado = id
	vista.sprite_frames = Skins.hoja(hoja, id)
	vista.play("reposo_s")
	vista.modulate = Color.WHITE if tiene(id) else Color(0.05, 0.04, 0.08, 0.9)
	nombre_vista.text = Skins.nombre(id) if tiene(id) else "???"


# Ponerse esa skin (si se tiene): se guarda y Johnny cambia en el acto. Devuelve si se la ha puesto
func elegir(id: String) -> bool:
	if fondo == null or not id in ids():
		return false
	if not tiene(id):
		info.text = Idioma.t("Aún no la tienes. %s") % Skins.como(id)
		info.add_theme_color_override("font_color", Tema.ROJO)
		Sonido.tocar("no")
		return false
	if id == Skins.puesta():
		info.text = Idioma.t("Ya la llevas puesta.")
		info.add_theme_color_override("font_color", Tema.TINTA)
		return false
	Skins.poner(id)
	partida.johnny.vestir(id)
	Sonido.tocar("cambiar")
	info.text = Idioma.t("Vuelves a ser el conserje de siempre.") if id == "" \
		else Idioma.t("Te pones: %s. Se queda puesta.") % Skins.nombre(id)
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
