# La pantalla de Opciones: se abre desde el menú principal y desde la pausa. Tiene dos pestañas:
#   - General: el modo de atacar (se guarda), la música, el sonido y la pantalla completa.
#   - Controles: qué hace cada tecla y cada botón del mando (leído del mapa de controles de Godot, así que si
#     cambian las teclas, la lista cambia sola). En el móvil, qué hace cada botón táctil.
# Se maneja igual que los otros menús: ratón, flechas + Intro o mando (A pulsar, B volver).
#
# Se usa así:  Opciones.abrir(self, lo_que_tapa, johnny)  (johnny puede ser null en el menú principal).
# Mientras está abierta, esconde "lo_que_tapa" (el menú de detrás) y, al cerrar, lo vuelve a enseñar y avisa
# con la señal "cerrado".
class_name Opciones
extends CanvasLayer

signal cerrado

# Lo que se explica de cada modo de atacar
const MODOS_AYUDA := {
	"asistido": "Johnny apunta y ataca solo al zombi más cercano. Tú solo te preocupas de moverte.",
	"mira": "Johnny ataca mientras mantienes pulsado atacar, hacia donde está mirando.",
	"libre": "Apuntas tú: con el ratón, con el stick derecho del mando o con el joystick derecho del móvil.",
}

# Las filas de la pestaña Controles: el nombre y las acciones del mapa de controles (project.godot) que juntan
const FILAS := [
	["Moverse", ["arriba", "izquierda", "abajo", "derecha"]],
	["Apuntar (modo libre)", ["apuntar_arriba", "apuntar_izquierda", "apuntar_abajo", "apuntar_derecha"]],
	["Atacar", ["atacar"]],
	["Esquivar", ["esquivar"]],
	["Cambiar de arma", ["cambiar_arma"]],
	["Recargar", ["recargar"]],
	["Lanzar (mantener y soltar)", ["lanzar"]],
	["Molotov o granada", ["cambiar_lanzable"]],
	["Inventario", ["inventario"]],
	["Pausa", ["pausa"]],
	["Modo de atacar", ["cambiar_modo"]],
]

# En el móvil, los botones táctiles (scripts/ui/tactil.gd)
const TACTIL := [
	["Moverse", "Joystick: toca y arrastra en la mitad izquierda"],
	["Atacar", "Solo en \"hacia donde mira\": el botón grande de abajo a la derecha"],
	["Apuntar", "Solo en \"apuntar libre\": el joystick de abajo a la derecha"],
	["Esquivar", "El botón del arco de la derecha"],
	["Armas", "Toca la otra arma para sacarla; toca la de fuego en la mano para recargar"],
	["Lanzar", "Arrastra desde el botón para apuntar y suelta para tirar"],
	["Molotov o granada", "El botoncito de al lado de lanzar"],
	["Modo, inventario y pausa", "Los botones de debajo del minimapa"],
]

const BOTONES_MANDO := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Select", JOY_BUTTON_GUIDE: "Guía", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "Pulsar stick izq.", JOY_BUTTON_RIGHT_STICK: "Pulsar stick dcho.",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Cruceta arriba", JOY_BUTTON_DPAD_DOWN: "Cruceta abajo",
	JOY_BUTTON_DPAD_LEFT: "Cruceta izq.", JOY_BUTTON_DPAD_RIGHT: "Cruceta dcha.",
}
const EJES_MANDO := {
	JOY_AXIS_LEFT_X: "Stick izq.", JOY_AXIS_LEFT_Y: "Stick izq.",
	JOY_AXIS_RIGHT_X: "Stick dcho.", JOY_AXIS_RIGHT_Y: "Stick dcho.",
	JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT",
}
const TECLAS := {
	KEY_SPACE: "Espacio", KEY_SHIFT: "Mayús", KEY_ESCAPE: "Esc", KEY_TAB: "Tab", KEY_ENTER: "Intro",
	KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_BACKSPACE: "Borrar",
	KEY_LEFT: "Flecha izq.", KEY_RIGHT: "Flecha dcha.", KEY_UP: "Flecha arriba", KEY_DOWN: "Flecha abajo",
}
const FLECHAS := [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]

var tapado: CanvasItem     # el menú de detrás, escondido mientras esto está abierto
var johnny: Node2D         # para cambiarle el modo de atacar en plena partida (null en el menú principal)
var fondo: ColorRect
var pestanas: HBoxContainer
var contenido: VBoxContainer
var pestana := "general"


static func abrir(dueno: Node, tapar: CanvasItem, jugador: Node2D = null) -> Opciones:
	var o := Opciones.new()
	o.tapado = tapar
	o.johnny = jugador
	dueno.add_child(o)
	return o


func _ready() -> void:
	layer = 11   # encima de la pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tapado:
		tapado.hide()
	fondo = ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, 0.85)
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
	columna.custom_minimum_size.x = 640
	panel.add_child(columna)
	var t := Label.new()
	t.theme_type_variation = "Titulo"
	t.text = "Opciones"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(t)
	pestanas = HBoxContainer.new()
	pestanas.alignment = BoxContainer.ALIGNMENT_CENTER
	pestanas.add_theme_constant_override("separation", 10)
	columna.add_child(pestanas)
	for p in [["general", "General"], ["controles", "Controles"]]:
		var b := Button.new()
		b.text = p[1]
		b.name = p[0]
		b.pressed.connect(func(): ver(p[0]))
		pestanas.add_child(b)
	contenido = VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 8)
	columna.add_child(contenido)
	var volver := Button.new()
	volver.text = "Volver"
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(cerrar)
	columna.add_child(volver)
	ver("general")


func cerrar() -> void:
	if tapado:
		tapado.show()
	cerrado.emit()
	queue_free()


# Pone una pestaña: vacía el contenido y lo vuelve a llenar
func ver(cual: String) -> void:
	pestana = cual
	for b: Button in pestanas.get_children():
		# La pestaña en la que estás, con las letras amarillas
		if b.name == cual:
			b.add_theme_color_override("font_color", Tema.AMARILLO)
			b.add_theme_color_override("font_focus_color", Tema.AMARILLO)
			b.add_theme_color_override("font_hover_color", Tema.AMARILLO)
		else:
			for c in ["font_color", "font_focus_color", "font_hover_color"]:
				b.remove_theme_color_override(c)
	for hijo in contenido.get_children():
		hijo.queue_free()
	if cual == "general":
		general()
	else:
		controles()
	(pestanas.get_node(cual) as Button).grab_focus.call_deferred()


func general() -> void:
	var modo: String = Guardado.cargar().ajustes.modo
	var ayuda := Label.new()
	ayuda.theme_type_variation = "Sub"
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.custom_minimum_size.x = 560
	ayuda.text = MODOS_AYUDA[modo]
	var boton_modo := opcion("Modo de atacar: %s" % modos()[modo])
	boton_modo.pressed.connect(func():
		var orden: Array = modos().keys()
		var nuevo: String = orden[(orden.find(Guardado.cargar().ajustes.modo) + 1) % orden.size()]
		poner_modo(nuevo)
		boton_modo.text = "Modo de atacar: %s" % modos()[nuevo]
		ayuda.text = MODOS_AYUDA[nuevo])
	contenido.add_child(ayuda)
	var musica := opcion(texto_musica())
	musica.pressed.connect(func():
		Guardado.cambiar(func(g): g.ajustes.musica = not g.ajustes.musica)
		Sonido.musica_si(Guardado.cargar().ajustes.musica)
		musica.text = texto_musica())
	# Quitar todo el sonido (como el botón del altavoz del JS): no se guarda
	var sonido := opcion(texto_sonido())
	sonido.pressed.connect(func():
		Sonido.silenciar(not Sonido.silenciado())
		sonido.text = texto_sonido())
	if Tactil.puede_pantalla_completa():   # en iPhone no hay
		opcion("Pantalla completa").pressed.connect(Tactil.pantalla_completa)


# Los nombres de los modos están en johnny.gd (MODOS)
func modos() -> Dictionary:
	return preload("res://scripts/johnny.gd").MODOS


func poner_modo(nuevo: String) -> void:
	Guardado.cambiar(func(g): g.ajustes.modo = nuevo)
	if johnny:
		johnny.poner_modo(nuevo)


func opcion(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size.x = 360
	contenido.add_child(b)
	return b


func controles() -> void:
	var tabla := GridContainer.new()
	tabla.add_theme_constant_override("h_separation", 24)
	tabla.add_theme_constant_override("v_separation", 4)
	contenido.add_child(tabla)
	if Tactil.activo:
		tabla.columns = 2
		for f in TACTIL:
			celda(tabla, f[0])
			celda(tabla, f[1], "Sub")
		return
	tabla.columns = 3
	celda(tabla, "", "Sub")
	celda(tabla, "Teclado y ratón", "Sub")
	celda(tabla, "Mando", "Sub")
	for f in FILAS:
		celda(tabla, f[0])
		if f[0].begins_with("Apuntar"):
			celda(tabla, "Ratón", "Sub")
		elif f[1].size() == 4:
			celda(tabla, teclas_direcciones(f[1]), "Sub")
		else:
			celda(tabla, nombres(f[1], false), "Sub")
		celda(tabla, nombres(f[1], true), "Sub")


func celda(tabla: GridContainer, texto: String, variacion := "") -> void:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = variacion
	tabla.add_child(l)


# Los nombres de las teclas (mando = false) o de los botones del mando (mando = true) de unas acciones,
# sin repetir, separados por " / "
func nombres(acciones: Array, mando: bool) -> String:
	var lista: Array[String] = []
	for a in acciones:
		for ev in InputMap.action_get_events(a):
			var n := nombre_evento(ev)
			var es_mando := ev is InputEventJoypadButton or ev is InputEventJoypadMotion
			if n != "" and es_mando == mando and not n in lista:
				lista.append(n)
	return " / ".join(lista) if not lista.is_empty() else "-"


# Moverse con el teclado: las cuatro direcciones juntas, como "WASD / Flechas"
func teclas_direcciones(acciones: Array) -> String:
	var grupos: Array[String] = []
	var i := 0
	while true:
		var codigos := []
		for a in acciones:
			var teclas := InputMap.action_get_events(a).filter(func(e): return e is InputEventKey)
			if i < teclas.size():
				codigos.append(codigo(teclas[i]))
		if codigos.is_empty():
			break
		if codigos == FLECHAS:
			grupos.append("Flechas")
		else:
			var letras := ""
			for c in codigos:
				letras += nombre_tecla(c)
			grupos.append(letras)
		i += 1
	return " / ".join(grupos) if not grupos.is_empty() else "-"


static func codigo(ev: InputEventKey) -> Key:
	return ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode


static func nombre_tecla(c: Key) -> String:
	if c in TECLAS:
		return TECLAS[c]
	# La letra que hay en esa posición del teclado del jugador (en un teclado francés, la A está donde la Q)
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(c))


# El nombre de una tecla, botón del ratón o del mando, para enseñarlo
static func nombre_evento(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return nombre_tecla(codigo(ev))
	if ev is InputEventMouseButton:
		return {MOUSE_BUTTON_LEFT: "Clic izq.", MOUSE_BUTTON_RIGHT: "Clic dcho.", MOUSE_BUTTON_MIDDLE: "Clic rueda",
			MOUSE_BUTTON_WHEEL_UP: "Rueda", MOUSE_BUTTON_WHEEL_DOWN: "Rueda"}.get(ev.button_index, "Ratón")
	if ev is InputEventJoypadButton:
		return BOTONES_MANDO.get(ev.button_index, "Botón %d" % ev.button_index)
	if ev is InputEventJoypadMotion:
		return EJES_MANDO.get(ev.axis, "Eje %d" % ev.axis)
	return ""


func texto_sonido() -> String:
	return "Sonido: %s" % ("No" if Sonido.silenciado() else "Sí")


func texto_musica() -> String:
	return "Música: %s" % ("Sí" if Guardado.cargar().ajustes.musica else "No")


# B del mando o Esc: volver
func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()
