# La ventanita del puesto del ferretero, en su habitación de las viviendas (supervivientes.gd: abrir_puesto). Al
# arrimarse por delante a su mostrador (mapa/mostrador.gd) el juego se para y sale: munición, molotovs y granadas,
# cada uno con su precio y lo que llevas. Se paga con los dólares ahorrados (como en el ordenador: los de la
# partida en curso no cuentan hasta completar el edificio) y lo comprado es para esta partida. Si no te llega o ya
# vas lleno, lo dice. Va con el ratón o el dedo, con flechas e Intro (o 1, 2 y 3) o con el mando (cruceta y A).
# Esc o B la cierra.
extends CanvasLayer

# Lo que vende (los precios son provisionales: un punto de talento cuesta 10 y la escopeta 30)
const COSAS := [
	{"id": "municion", "icono": "municion", "nombre": "Munición", "precio": 2, "desc": "Un cargador más para tu arma de fuego"},
	{"id": "molotov", "icono": "molotov", "nombre": "Molotov", "precio": 3, "desc": "Deja el suelo ardiendo un rato"},
	{"id": "granada", "icono": "granada", "nombre": "Granada", "precio": 4, "desc": "Explota al poco de caer"},
]

var partida: Node
var fondo: ColorRect
var saldo: Label
var info: Label
var llevas := {}    # lo que llevas de cada cosa (su etiqueta en la tarjeta)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abierta() -> bool:
	return fondo != null


# El fondo oscuro y, encima, el panel con las tres tarjetas (el juego ya está en pausa)
func abrir(p: Node) -> void:
	partida = p
	quitar()
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
	titulo.text = "Puesto del Ferretero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color("#ffb36b"))
	columna.add_child(titulo)
	var sub := Label.new()
	sub.theme_type_variation = "Sub"
	sub.text = "«Lo que necesites, chaval. Aquí se paga con lo ahorrado»"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(sub)
	var fila_saldo := Tema.icono_y_texto("billete", "", 24)
	fila_saldo.alignment = BoxContainer.ALIGNMENT_CENTER
	saldo = fila_saldo.get_child(1)
	columna.add_child(fila_saldo)

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	columna.add_child(fila)
	var primera: Button = null
	for i in COSAS.size():
		var cosa: Dictionary = COSAS[i]
		var carta := Button.new()
		carta.custom_minimum_size = Vector2(196, 150)
		carta.pressed.connect(comprar.bind(cosa.id))
		fila.add_child(carta)
		var dentro := VBoxContainer.new()
		dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
		dentro.offset_left = 12
		dentro.offset_right = -12
		dentro.offset_top = 10
		dentro.offset_bottom = -10
		dentro.add_theme_constant_override("separation", 4)
		dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		carta.add_child(dentro)
		var cabeza := Tema.icono_y_texto(cosa.icono, "%d. %s" % [i + 1, cosa.nombre], 32)
		cabeza.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(cabeza)
		var precio := etiqueta(dentro, "$%d" % cosa.precio, 32)
		precio.add_theme_color_override("font_color", Tema.VERDE)
		var desc := etiqueta(dentro, cosa.desc, 16)
		desc.theme_type_variation = "Sub"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		llevas[cosa.id] = etiqueta(dentro, "", 16)
		if primera == null:
			primera = carta

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
	primera.grab_focus.call_deferred()
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


# Los dólares ahorrados y lo que llevas de cada cosa
func refrescar() -> void:
	saldo.text = "Tienes $%d ahorrados" % Guardado.cargar().dolares
	var johnny: Node2D = partida.johnny
	var w: Dictionary = Armas.datos(johnny.huecos.fuego) if johnny.huecos.fuego != "" else {}
	if w.is_empty() or w.get("sin_municion", false):
		llevas.municion.text = "Tu arma no usa balas"
	else:
		llevas.municion.text = "Cargadores: %d de %d" % [johnny.reserva / w.cargador, johnny.RESERVA_MAX]
	for k in ["molotov", "granada"]:
		llevas[k].text = "Llevas %d de %d" % [partida.lanzables.cantidades[k], partida.lanzables.maximo(k)]


# Comprar una (si cabe y si llega con lo ahorrado). Devuelve si se ha comprado
func comprar(id: String) -> bool:
	if fondo == null:
		return false
	var cosa: Dictionary = COSAS.filter(func(c): return c.id == id)[0]
	var johnny: Node2D = partida.johnny
	var cabe: bool = johnny.quiere_municion() if id == "municion" else partida.lanzables.cabe(id)
	var s := Guardado.cargar()
	if not Reto.se_vende(id):   # el reto del día "Solo cuerpo a cuerpo"
		info.text = "Hoy el reto va solo a cuerpo a cuerpo: nada de esto."
		info.add_theme_color_override("font_color", Tema.ROJO)
		Sonido.tocar("no")
		return false
	if not cabe:
		if id != "municion":
			info.text = "No te cabe: ya llevas las %d %ss." % [partida.lanzables.maximo(id), cosa.nombre.to_lower()]
		elif llevas.municion.text.begins_with("Tu arma"):
			info.text = "Tu arma de fuego no usa balas: no te hace falta."
		else:
			info.text = "No te cabe: ya llevas todos los cargadores."
		info.add_theme_color_override("font_color", Tema.ROJO)
		Sonido.tocar("no")
		return false
	if s.dolares < cosa.precio:
		info.text = "No te llega: te faltan $%d." % (cosa.precio - s.dolares)
		info.add_theme_color_override("font_color", Tema.ROJO)
		Sonido.tocar("no")
		return false
	s.dolares -= cosa.precio
	Guardado.escribir(s)
	partida.ahorrados = s.dolares   # el HUD enseña lo ahorrado más lo de esta partida
	if id == "municion":
		johnny.sumar_municion()
	else:
		partida.lanzables.sumar(id)
	Sonido.tocar("compra")
	info.text = "+1 %s por $%d. ¡Que te aproveche!" % [cosa.nombre.to_lower(), cosa.precio]
	info.add_theme_color_override("font_color", Tema.VERDE)
	refrescar()
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


# Esc o B: cerrar. 1, 2 y 3: comprar esa
func _unhandled_input(evento: InputEvent) -> void:
	if fondo == null:
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()
	elif evento is InputEventKey and evento.pressed and not evento.echo:
		var n: int = {KEY_1: 0, KEY_KP_1: 0, KEY_2: 1, KEY_KP_2: 1, KEY_3: 2, KEY_KP_3: 2}.get(evento.keycode, -1)
		if n >= 0:
			get_viewport().set_input_as_handled()
			comprar(COSAS[n].id)
