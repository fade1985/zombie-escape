# La pantalla de Opciones: se abre desde el menú principal y desde la pausa. Tiene cuatro pestañas:
#   - General: el idioma (idioma.gd; la pantalla se vuelve a montar al cambiarlo), Audio (la música y el sonido) y
#     Pantalla (la pantalla completa, el brillo y el temblor de pantalla: Normal, Suave o No, lo que tiembla la
#     cámara y lo que se frena el juego al golpear, temblor.gd; se guarda). En el móvil, además, el tamaño y la transparencia de los botones
#     táctiles y la vibración (se guardan).
#   - Controles: qué hace cada tecla y cada botón del mando (leído del mapa de controles de Godot). Se pueden
#     cambiar: se pulsa la casilla y luego la tecla o el botón nuevo (controles.gd lo pone y lo guarda).
#     En el móvil, qué hace cada botón táctil.
#   - Ayudas: para que más gente pueda terminar los edificios (vida entera, pistola sin fin, lanzar apuntando solo,
#     disparo asistido). Se guardan y se
#     notan al momento, también desde la pausa (johnny.gd y hud.gd las miran con Guardado.ajuste). Y los
#     tutoriales (tutoriales.gd): si salen sus ventanas, y que vuelvan a salir todos.
#   - Créditos: quién ha hecho el juego (AUTORES), con qué, y las letras que no son nuestras (LETRAS_DE_OTROS). Su botón
#     Licencias enseña los textos legales enteros: los de esas letras y los de Godot y sus piezas (texto_de_licencias).
# Se maneja igual que los otros menús: ratón, flechas + Intro o mando (A pulsar, B volver).
#
# Se usa así:  Opciones.abrir(self, lo_que_tapa, johnny)  (johnny puede ser null en el menú principal).
# Mientras está abierta, esconde "lo_que_tapa" (el menú de detrás) y, al cerrar, lo vuelve a enseñar y avisa
# con la señal "cerrado".
class_name Opciones
extends CanvasLayer

signal cerrado

# Pestaña Créditos. Quién ha hecho el juego, en una línea («Un juego de …»): vacía, no sale (29 oct 2026: el dueño la
# rellenará cuando lo tengan claro)
const AUTORES := ""
# Las letras que no son nuestras: [nombre, autores, su licencia]. La licencia (SIL OFL 1.1) pide citarlas y que su texto vaya
# con el juego: los .txt se exportan (export_presets.cfg, include_filter) y el botón Licencias los enseña
const LETRAS_DE_OTROS := [
	["Jersey 25", "The Soft Type Project Authors", "res://assets/fuentes/jersey-25-OFL.txt"],   # no-tr
	["Ark Pixel", "TakWolf", "res://assets/fuentes/ark-pixel-OFL.txt"],   # no-tr
	["GNU Unifont", "Roman Czyborra, Paul Hardy et al.", "res://assets/fuentes/unifont-OFL.txt"],   # no-tr
	["Rubik", "The Rubik Project Authors", "res://assets/fuentes/rubik-OFL.txt"],   # no-tr
	["Noto Sans SC", "Adobe, Google", "res://assets/fuentes/noto-sans-sc-OFL.txt"],   # no-tr
]

# Todos los textos de las tablas de aquí abajo se traducen al enseñarlos (Idioma.t); las marcas son para
# tools/traducciones.py (docs/IDIOMAS.md)
# [traducir]
# Las filas de la pestaña Controles: el nombre y las acciones del mapa de controles (project.godot) que juntan
# (apuntar no se cambia aquí: es el ratón o el stick derecho)
const FILAS := [
	["Moverse: arriba", ["arriba"]],
	["Moverse: izquierda", ["izquierda"]],
	["Moverse: abajo", ["abajo"]],
	["Moverse: derecha", ["derecha"]],
	["Apuntar", []],
	["Atacar", ["atacar"]],
	["Esquivar", ["esquivar"]],
	["Cambiar de arma", ["cambiar_arma"]],
	["Recargar", ["recargar"]],
	["Lanzar (mantener y soltar)", ["lanzar"]],
	["Molotov o granada", ["cambiar_lanzable"]],
	["Usar vendas", ["usar_vendas"]],
	["Usar botiquín", ["usar_botiquin"]],
	["Inventario", ["inventario"]],
	["Pausa", ["pausa"]],
]

# En el móvil, los botones táctiles (scripts/ui/tactil.gd)
const TACTIL := [
	["Moverse", "Joystick: toca y arrastra en la mitad izquierda"],
	["Apuntar", "El joystick de abajo a la derecha (sin él con «Disparo asistido»)"],
	["Esquivar", "En asistido, el de la esquina de abajo a la derecha; si no, el del arco"],
	["Armas", "Toca la otra arma para sacarla; toca la de a distancia en la mano para recargar"],
	["Lanzar", "Arrastra desde el botón para apuntar y suelta para tirar"],
	["Molotov o granada", "El botoncito de al lado de lanzar"],
	["Vendas y botiquín", "Los botones de debajo del minimapa (solo salen si llevas)"],
	["Inventario y pausa", "Los botones de debajo del minimapa"],
]

# Los ajustes del móvil (tactil.gd): los valores por los que va pasando cada botón, con su nombre.
# Más de 1,4 no cabe: los botones del arco chocarían con los de debajo del minimapa
const TAMANOS := [[0.8, "Pequeño"], [1.0, "Normal"], [1.2, "Grande"], [1.4, "Muy grande"]]
const OPACIDADES := [[1.0, "100 %"], [0.75, "75 %"], [0.5, "50 %"], [0.3, "30 %"]]
const SI_NO := [[true, "Sí"], [false, "No"]]
# El temblor de pantalla (temblor.gd): por cuánto se multiplica el temblor de la cámara y el parón de los golpes
const TEMBLORES := [[1.0, "Normal"], [0.5, "Suave"], [0.0, "No"]]
# El hueco entre los botones grandes (General, Idioma, Audio y Pantalla): con 8 iban muy juntos y sobraba media ventana
const HUECO_GRANDES := 18

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
# Hacia dónde se empuja el stick: [hacia el negativo, hacia el positivo]
const SENTIDOS := {
	JOY_AXIS_LEFT_X: [" izq.", " dcha."], JOY_AXIS_LEFT_Y: [" arriba", " abajo"],
	JOY_AXIS_RIGHT_X: [" izq.", " dcha."], JOY_AXIS_RIGHT_Y: [" arriba", " abajo"],
}
const TECLAS := {
	KEY_SPACE: "Espacio", KEY_SHIFT: "Mayús", KEY_ESCAPE: "Esc", KEY_TAB: "Tab", KEY_ENTER: "Intro",
	KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_BACKSPACE: "Borrar",
	KEY_LEFT: "Flecha izq.", KEY_RIGHT: "Flecha dcha.", KEY_UP: "Flecha arriba", KEY_DOWN: "Flecha abajo",
}
const RATON := {MOUSE_BUTTON_LEFT: "Clic izq.", MOUSE_BUTTON_RIGHT: "Clic dcho.", MOUSE_BUTTON_MIDDLE: "Clic rueda",
	MOUSE_BUTTON_WHEEL_UP: "Rueda", MOUSE_BUTTON_WHEEL_DOWN: "Rueda"}
# [/traducir]

var tapado: CanvasItem     # el menú de detrás, escondido mientras esto está abierto
var johnny: Node2D         # para cambiarle el modo de atacar en plena partida (null en el menú principal)
var fondo: ColorRect
var pestanas: HBoxContainer
var contenido: VBoxContainer
var pestana := "general"
var casillas := []         # pestaña Controles: [botón, acción, si es del mando] de cada casilla que se cambia
var aviso: Label           # debajo de la tabla: qué hacer o qué ha pasado
var esperando: Button = null   # la casilla que espera una tecla nueva (o null)
var esperando_accion := ""
var esperando_mando := false
var esperando_desde := 0   # cuándo empezó a esperar (ms): lo que llegue justo después es el mismo pulsar
var ancho_grande := 0.0   # lo que mide el botón grande más ancho de General, Audio y Pantalla (igualar())
var boton_idioma: Button   # el botón de Idioma de la pestaña General (si está), para devolverle el foco al cambiarlo


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
	Idioma.cambiado.connect(reconstruir)
	construir()


# Al cambiar de idioma: la pantalla se monta otra vez, en la misma pestaña y con el foco en el botón del idioma
func reconstruir() -> void:
	var cual := pestana
	fondo.hide()
	fondo.queue_free()   # (el cambio viene de un botón de dentro: se libera al acabar el fotograma)
	construir(cual)
	if boton_idioma:
		boton_idioma.grab_focus.call_deferred()


func construir(cual := "general") -> void:
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
	t.text = Idioma.t("Opciones")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(t)
	pestanas = HBoxContainer.new()
	pestanas.alignment = BoxContainer.ALIGNMENT_CENTER
	pestanas.add_theme_constant_override("separation", 10)
	columna.add_child(pestanas)
	for p in [["general", "General"], ["controles", "Controles"], ["ayudas", "Ayudas"], ["creditos", "Créditos"]]:   # [traducir]
		var b := Button.new()
		b.text = Idioma.t(p[1])
		b.name = p[0]
		b.pressed.connect(func(): ver(p[0]))
		pestanas.add_child(b)
	# Las cuatro pestañas, del tamaño de la más grande: así la ventana no cambia al pasar de una a otra. Se monta cada
	# una de prueba (en una caja que se tira enseguida), se mide y el contenido se queda con lo más ancho y lo más alto
	var medida := Vector2.ZERO
	ancho_grande = 0.0
	for p in ["audio", "pantalla", "general", "controles", "ayudas", "creditos"]:   # (audio y pantalla, solo para el ancho de sus botones)
		contenido = VBoxContainer.new()
		contenido.add_theme_constant_override("separation", 8)
		columna.add_child(contenido)
		call(p)
		if p in ["general", "controles", "ayudas", "creditos"]:
			medida = medida.max(contenido.get_combined_minimum_size())
		columna.remove_child(contenido)
		contenido.free()
	casillas.clear()
	aviso = null
	boton_idioma = null
	contenido = VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 8)
	contenido.custom_minimum_size = medida
	columna.add_child(contenido)
	var volver := Button.new()
	volver.text = Idioma.t("Volver")
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(atras)
	columna.add_child(volver)
	ver(cual)


# Volver (o Esc, B, Start): al menú de antes. De Idioma, Audio y Pantalla, a General (con el foco en su botón); de las
# Licencias, a Créditos; de una pestaña, se cierra Opciones (y se vuelve al menú o a la pausa de detrás)
func atras() -> void:
	if pestana in ["idioma", "audio", "pantalla", "contacto"]:
		var de := pestana
		ver("general")
		var b := contenido.find_child(de, true, false) as Button
		if b:
			b.grab_focus.call_deferred()
	elif pestana == "licencias":
		ver("creditos")
	else:
		cerrar()


# Los botones grandes de la página (los de General, Audio y Pantalla), todos tan anchos como el más ancho de las tres
# páginas (ancho_grande: construir() las monta todas antes, para medirlas). Y más separados que los demás (HUECO_GRANDES)
func igualar() -> void:
	var grandes := contenido.find_children("*", "Button", true, false).filter(func(b): return b.theme_type_variation == "BotonGrande")
	for b: Button in grandes:
		ancho_grande = maxf(ancho_grande, b.get_combined_minimum_size().x)
	for b: Button in grandes:
		b.custom_minimum_size.x = ancho_grande
	if not grandes.is_empty():
		contenido.add_theme_constant_override("separation", HUECO_GRANDES)


func cerrar() -> void:
	if tapado:
		tapado.show()
	cerrado.emit()
	queue_free()


# Pone una pestaña: vacía el contenido y lo vuelve a llenar
func ver(cual: String) -> void:
	pestana = cual
	for b: Button in pestanas.get_children():
		# La pestaña en la que estás, con las letras amarillas (las licencias son parte de Créditos, y los idiomas, de General)
		if b.name == cual or (cual == "licencias" and b.name == "creditos") or (cual in ["idioma", "audio", "pantalla", "contacto"] and b.name == "general"):
			b.add_theme_color_override("font_color", Tema.AMARILLO)
			b.add_theme_color_override("font_focus_color", Tema.AMARILLO)
			b.add_theme_color_override("font_hover_color", Tema.AMARILLO)
		else:
			for c in ["font_color", "font_focus_color", "font_hover_color"]:
				b.remove_theme_color_override(c)
	for hijo in contenido.get_children():
		hijo.queue_free()
	contenido.add_theme_constant_override("separation", 8)   # (igualar() lo abre en las páginas de botones grandes)
	casillas.clear()
	esperando = null
	boton_idioma = null
	if cual == "general":
		general()
	elif cual == "ayudas":
		ayudas()
	elif cual == "creditos":
		creditos()
	elif cual == "licencias":
		licencias()
		return   # (el foco va a su botón de volver a los créditos)
	elif cual == "idioma":
		idiomas()
		return   # (el foco va al idioma de ahora)
	elif cual == "audio":
		audio()
		return   # (el foco va a la música)
	elif cual == "pantalla":
		pantalla()
		return   # (el foco va a su primer botón)
	elif cual == "contacto":
		contacto()
		return   # (el foco va al cuadro del mensaje)
	else:
		controles()
	(pestanas.get_node(cual) as Button).grab_focus.call_deferred()


func general() -> void:
	var fuera := contenido
	if Tactil.activo:   # en el móvil hay más filas de las que caben en la pantalla: todo va en una caja con barra, como Controles
		var caja := ScrollContainer.new()
		caja.custom_minimum_size = Vector2(620, 330)
		caja.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		caja.follow_focus = true
		fuera.add_child(caja)
		contenido = VBoxContainer.new()
		contenido.add_theme_constant_override("separation", 8)
		contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.add_child(contenido)
	# El idioma: un botón que lleva a la lista de idiomas (idiomas(), desde el 8 nov), con el nombre del de ahora
	var idioma_ahora: String = Idioma.IDIOMAS.filter(func(i): return i[0] == Idioma.actual)[0][1]
	var al_idioma := opcion("%s: %s" % [Idioma.t("Idioma"), idioma_ahora], "BotonGrande")
	al_idioma.name = "idioma"   # no-tr
	var letra_ahora := Tema.fuente_del_idioma(Idioma.actual)
	if letra_ahora != null:
		al_idioma.add_theme_font_override("font", letra_ahora)
	al_idioma.pressed.connect(func(): ver("idioma"))
	boton_idioma = al_idioma   # (al volver de la lista de idiomas, el foco va aquí)
	# la música y el sonido, tras el botón Audio (audio(), desde el 8 nov)
	var al_audio := opcion(Idioma.t("Audio"), "BotonGrande")
	al_audio.name = "audio"   # no-tr
	al_audio.pressed.connect(func(): ver("audio"))
	# la pantalla completa y el temblor, tras el botón Pantalla (pantalla(), desde el 8 nov)
	var a_pantalla := opcion(Idioma.t("Pantalla"), "BotonGrande")
	a_pantalla.name = "pantalla"   # no-tr
	a_pantalla.pressed.connect(func(): ver("pantalla"))
	if johnny == null:   # en el menú principal (en la pausa, el Tutorial tiene su propio botón)
		var tutorial := opcion(Idioma.t("Tutorial"), "BotonGrande")
		tutorial.pressed.connect(func(): Tutorial.lista(self, fondo).cerrado.connect(tutorial.grab_focus))
	# Escribirnos un mensaje, tras el botón Contáctanos (contacto(), desde el 10 nov: en lugar del botón del registro de errores)
	var a_contacto := opcion(Idioma.t("Contáctanos"), "BotonGrande")
	a_contacto.name = "contacto"   # no-tr
	a_contacto.pressed.connect(func(): ver("contacto"))
	igualar()
	if Tactil.activo:
		var titulo := Label.new()
		titulo.theme_type_variation = "Sub"
		titulo.text = Idioma.t("Móvil")
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contenido.add_child(titulo)
		rotar(Idioma.t("Tamaño de los botones"), "tactil_tamano", TAMANOS)
		rotar(Idioma.t("Transparencia"), "tactil_opacidad", OPACIDADES)
		rotar(Idioma.t("Vibración"), "vibracion", SI_NO)
	contenido = fuera


# La lista de idiomas (el botón «Idioma / Language» de General): un botón por idioma, cada uno con su nombre en su idioma
# (y el rótulo, en dos), para encontrarlo aunque el juego esté en otro. El de ahora, con las letras amarillas como la
# pestaña en la que estás. Al elegir uno se vuelve a General (y sin elegir, con la pestaña General)
func idiomas() -> void:
	var rotulo_idioma := Label.new()
	rotulo_idioma.theme_type_variation = "Sub"
	rotulo_idioma.text = Idioma.t("Idioma")
	rotulo_idioma.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(rotulo_idioma)
	var fila_idioma := VBoxContainer.new()   # (uno debajo de otro, desde el 9 nov)
	fila_idioma.add_theme_constant_override("separation", 8)
	fila_idioma.size_flags_vertical = Control.SIZE_EXPAND_FILL   # (llena el sitio hasta «Volver»: ver abajo)
	contenido.add_child(fila_idioma)
	# Los botones, más grandes desde el 12 nov (a petición del dueño): la letra de BotonGrande (32), tan anchos como los botones
	# grandes de General (ancho_grande) y estirados de alto hasta llenar el sitio que hay hasta «Volver» (el contenido mide lo que la
	# pestaña más alta), con el mismo hueco por debajo que en General. Llevan menos hueco por arriba y por abajo que el botón grande
	# normal: es lo mínimo que miden
	var chapas := {}
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		var s: StyleBox = Tema.crear().get_stylebox(estado, "Button").duplicate()
		s.content_margin_top = 4
		s.content_margin_bottom = 6
		chapas[estado] = s
	for i in Idioma.IDIOMAS:
		var b := Button.new()
		b.text = i[1]
		b.theme_type_variation = "BotonGrande"
		b.custom_minimum_size.x = maxf(340.0, ancho_grande)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		for estado in chapas:
			b.add_theme_stylebox_override(estado, chapas[estado])
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var letra := Tema.fuente_del_idioma(i[0])   # (el ruso y el chino se escriben con su letra, en cualquier idioma)
		if letra != null:
			b.add_theme_font_override("font", letra)
		b.pressed.connect(func():   # al elegirlo, de vuelta a General (con el foco en el botón del idioma)
			pestana = "general"
			if i[0] == Idioma.actual:
				ver("general")
				boton_idioma.grab_focus.call_deferred()
			else:
				Idioma.poner(i[0]))
		if i[0] == Idioma.actual:
			boton_idioma = b
			for c in ["font_color", "font_focus_color", "font_hover_color"]:
				b.add_theme_color_override(c, Tema.AMARILLO)
		fila_idioma.add_child(b)
	if boton_idioma:
		boton_idioma.grab_focus.call_deferred()


# El brillo (11 nov; desde el 12 nov en Pantalla y con una barra): «Brillo: 50» encima de una barra recta con un punto que se
# arrastra de izquierda a derecha, de 0 a 100 de 5 en 5 (50, en la mitad, es como se ve sin tocar nada y como empieza el
# juego la primera vez). También se mueve con un clic en la barra, la rueda del ratón o, con ella elegida, las flechas
# izquierda y derecha (también las del mando). Se guarda y se nota al momento en todo el juego (Pantalla.poner_brillo)
func barra_brillo() -> HSlider:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_theme_constant_override("separation", 10)
	contenido.add_child(caja)
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)
	var barra := HSlider.new()
	barra.name = "brillo"   # no-tr
	barra.min_value = 0
	barra.max_value = 100
	barra.step = 5
	barra.custom_minimum_size.x = 360   # (al final de pantalla(), tan ancha como los botones grandes)
	barra.value = clampi(int(Guardado.ajuste("brillo")), 0, 100)
	titulo.text = "%s: %d" % [Idioma.t("Brillo"), int(barra.value)]
	barra.value_changed.connect(func(valor: float):
		var v := int(valor)
		titulo.text = "%s: %d" % [Idioma.t("Brillo"), v]
		Pantalla.poner_brillo(v)
		if v != int(Guardado.ajuste("brillo")):
			Guardado.cambiar(func(g): g.ajustes.brillo = v))
	# Cómo se ve: la barra de metal oscuro con el borde negro, lo que va del principio al punto en amarillo, y el punto
	# redondo color hueso (amarillo al pasar por encima o con la barra elegida, que además lleva el marco amarillo)
	var tira := func(color: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = color
		s.border_color = Tema.LINEA
		s.set_border_width_all(3)
		s.set_corner_radius_all(6)
		s.content_margin_top = 7
		s.content_margin_bottom = 7
		return s
	barra.add_theme_stylebox_override("slider", tira.call(Tema.METAL))
	barra.add_theme_stylebox_override("grabber_area", tira.call(Tema.AMARILLO.darkened(0.25)))
	barra.add_theme_stylebox_override("grabber_area_highlight", tira.call(Tema.AMARILLO))
	var marco := StyleBoxFlat.new()
	marco.draw_center = false
	marco.border_color = Tema.AMARILLO
	marco.set_border_width_all(3)
	marco.set_corner_radius_all(8)
	marco.set_expand_margin_all(8)
	barra.add_theme_stylebox_override("focus", marco)
	barra.add_theme_icon_override("grabber", _punto(Color("#e6dec8")))
	barra.add_theme_icon_override("grabber_highlight", _punto(Tema.AMARILLO))
	caja.add_child(barra)
	return barra


# El punto de la barra del brillo: un círculo de 30 px del color dado, con el borde negro
func _punto(color: Color) -> ImageTexture:
	const LADO := 30
	var imagen := Image.create_empty(LADO, LADO, false, Image.FORMAT_RGBA8)
	var centro := Vector2(LADO, LADO) / 2.0
	for y in LADO:
		for x in LADO:
			var d := (Vector2(x, y) + Vector2(0.5, 0.5)).distance_to(centro)
			if d <= LADO / 2.0 - 3.0:
				imagen.set_pixel(x, y, color)
			elif d <= LADO / 2.0:
				imagen.set_pixel(x, y, Tema.LINEA)
	return ImageTexture.create_from_image(imagen)


# El audio (el botón Audio de General): la música y quitar todo el sonido. Se vuelve con la pestaña General
func audio() -> void:
	var musica := opcion(texto_musica(), "BotonGrande")
	musica.pressed.connect(func():
		Guardado.cambiar(func(g): g.ajustes.musica = not g.ajustes.musica)
		Sonido.musica_si(Guardado.cargar().ajustes.musica)
		musica.text = texto_musica())
	# Quitar todo el sonido (como el botón del altavoz del JS): no se guarda
	var sonido := opcion(texto_sonido(), "BotonGrande")
	sonido.pressed.connect(func():
		Sonido.silenciar(not Sonido.silenciado())
		sonido.text = texto_sonido())
	igualar()
	musica.grab_focus.call_deferred()


# La pantalla (el botón Pantalla de General): la pantalla completa, el brillo (barra_brillo) y el temblor. Se vuelve con la pestaña General
func pantalla() -> void:
	if Tactil.puede_pantalla_completa():   # en iPhone no hay
		var texto_completa := func(si: bool) -> String:
			return "%s: %s" % [Idioma.t("Pantalla completa"), Idioma.t("Sí") if si else Idioma.t("No")]
		var completa := opcion(texto_completa.call(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN), "BotonGrande")
		completa.pressed.connect(func():
			# (el texto, con lo que va a ser: en la web la ventana tarda un poco en cambiar)
			var ahora := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			Tactil.pantalla_completa()
			completa.text = texto_completa.call(not ahora))
	var brillo := barra_brillo()
	rotar(Idioma.t("Temblor"), "temblor", TEMBLORES, "BotonGrande")
	igualar()
	brillo.custom_minimum_size.x = ancho_grande
	# (el foco, en lo primero de la página: la pantalla completa o, en iPhone, que no la tiene, la barra del brillo)
	(contenido.get_child(0) if contenido.get_child(0) is Button else brillo).grab_focus.call_deferred()


# Contáctanos (el botón de General, desde el 10 nov): un cuadro para escribirnos qué falla, qué no le gusta o qué mejoraría,
# y Enviar (solo va el texto, desde el 10 nov: sin datos técnicos). Lo manda contacto.gd. Se vuelve con la pestaña General.
# También es para avisar de un texto mal escrito o mal traducido (12 nov: sustituye al botón «Avisar de un texto mal traducido»
# de la lista de idiomas, que abría un formulario de Google)
func contacto() -> void:
	explicar(Idioma.t("Cuéntanos con tus palabras qué falla, qué no te gusta o qué se podría mejorar."))
	explicar(Idioma.t("También sirve para avisarnos de un texto mal escrito o mal traducido."))
	# (en el móvil de la web, Godot no saca el teclado de la pantalla: se escribe en una ventanita del navegador, abajo)
	var por_ventanita := OS.has_feature("web") and Tactil.activo
	var cuadro := TextEdit.new()
	cuadro.name = "mensaje"   # no-tr
	cuadro.editable = not por_ventanita
	cuadro.placeholder_text = Idioma.t("Escribe aquí tu mensaje")
	cuadro.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	cuadro.custom_minimum_size = Vector2(600, 140)
	cuadro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contenido.add_child(cuadro)
	var letras := Label.new()   # cuántas letras van de las que caben
	letras.theme_type_variation = "Sub"
	letras.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	letras.custom_minimum_size.x = 600
	letras.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contenido.add_child(letras)
	var contar := func():
		if cuadro.text.length() > Contacto.MAX_LETRAS:   # (no se deja pasar del máximo: lo que sobra se corta)
			cuadro.text = cuadro.text.left(Contacto.MAX_LETRAS)
			cuadro.set_caret_line(cuadro.get_line_count() - 1)
			cuadro.set_caret_column(cuadro.get_line(cuadro.get_line_count() - 1).length())
		letras.text = "%d / %d" % [cuadro.text.length(), Contacto.MAX_LETRAS]
	cuadro.text_changed.connect(contar)
	contar.call()
	var enviar := opcion(Idioma.t("Enviar"), "BotonGrande")   # (grande y del mismo ancho que Contáctanos)
	enviar.name = "enviar"   # no-tr
	enviar.custom_minimum_size.x = maxf(ancho_grande, enviar.custom_minimum_size.x)
	var estado := explicar("")
	estado.name = "estado"   # no-tr
	estado.add_theme_color_override("font_color", Tema.AMARILLO)
	cuadro.text_changed.connect(func(): estado.text = "")   # (al volver a escribir, el aviso de antes sobra)
	enviar.pressed.connect(func():
		if cuadro.text.strip_edges().length() < 3:
			estado.text = Idioma.t("Escribe tu mensaje antes de enviarlo.")
			return
		enviar.disabled = true
		cuadro.editable = false
		estado.text = Idioma.t("Enviando…")
		Contacto.enviar(self, cuadro.text, func(llegado: bool):
			if not is_instance_valid(estado):
				return   # (ya se ha ido de esta página: el mensaje ha llegado igual, o no)
			enviar.disabled = false
			cuadro.editable = not por_ventanita
			if llegado:
				cuadro.text = ""
				contar.call()
				estado.text = Idioma.t("¡Gracias! Tu mensaje nos ha llegado.")
			else:
				estado.text = Idioma.t("No se ha podido enviar. Mira tu conexión e inténtalo otra vez.")))
	# Del cuadro se sale hacia abajo con Tab o con el mando (con las flechas, se mueve el cursor por el texto)
	cuadro.gui_input.connect(func(e: InputEvent):
		var tab: bool = e is InputEventKey and e.pressed and e.keycode == KEY_TAB and not e.shift_pressed
		var mando: bool = (e is InputEventJoypadButton or e is InputEventJoypadMotion) and e.is_action_pressed("ui_down")
		if tab or mando:
			cuadro.accept_event()
			enviar.grab_focus())
	# La ventanita del navegador (prompt) del móvil: al tocar el cuadro, y lo escrito pasa al cuadro
	if por_ventanita:
		cuadro.gui_input.connect(func(e: InputEvent):
			if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed and not enviar.disabled:
				var escrito = JavaScriptBridge.eval("window.prompt(%s, %s)" % [JSON.stringify(Idioma.t("Escribe aquí tu mensaje")), JSON.stringify(cuadro.text)])   # no-tr
				if escrito is String:
					cuadro.text = escrito.left(Contacto.MAX_LETRAS)
					contar.call())
	cuadro.grab_focus.call_deferred()


# Las ayudas: cada una, un botón de Sí/No con lo que hace debajo, y el aviso de los logros arriba. Todas a la vista,
# sin barra (desde que los tutoriales se fueron a la lista de Tutorial, caben)
func ayudas() -> void:
	var aviso := explicar(Idioma.t("El uso de ayudas desactiva la obtención de logros en la partida actual, incluso si se desactivan posteriormente. Los logros obtenidos con anterioridad no se verán afectados."))
	aviso.add_theme_color_override("font_color", Tema.AMARILLO)
	rotar(Idioma.t("Vida entera"), "vida_entera", SI_NO)
	explicar(Idioma.t("La vida no se parte en tercios: curándote llegas siempre a la vida máxima y no andas más lento."))
	rotar(Idioma.t("Pistola sin fin"), "pistola_sin_fin", SI_NO)
	explicar(Idioma.t("La pistola no gasta balas ni hay que recargarla. Las demás armas, igual que siempre."))
	rotar(Idioma.t("Lanzar apuntando solo"), "lanzar_solo", SI_NO)
	explicar(Idioma.t("El molotov, la granada y las arrojadizas van solos al zombi más cercano que veas. Si no ves ninguno, se lanzan como siempre."))
	rotar(Idioma.t("Disparo asistido"), "disparo_asistido", SI_NO)
	explicar(Idioma.t("Johnny apunta y ataca solo al zombi más cercano. Tú solo te preocupas de moverte."))


func explicar(texto: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = "Sub"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 620   # (el ancho de la tabla de Controles: así se mide como se ve y no sobra hueco abajo)
	l.text = texto
	contenido.add_child(l)
	return l


func creditos() -> void:
	if AUTORES != "":
		var quien := Label.new()
		quien.text = AUTORES
		quien.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contenido.add_child(quien)
	apartado(Idioma.t("Hecho con Godot Engine"))
	explicar("godotengine.org")   # no-tr
	apartado(Idioma.t("Tipografías"))
	for l in LETRAS_DE_OTROS:
		explicar("%s · %s" % [l[0], l[1]])
	apartado(Idioma.t("Herramientas"))
	explicar(Idioma.t("Dibujos hechos con PixelLab"))
	explicar(Idioma.t("Programado y traducido con ayuda de Claude"))
	var boton := opcion(Idioma.t("Licencias"))
	boton.pressed.connect(func(): ver("licencias"))


# El título de un apartado de los créditos, en amarillo
func apartado(texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Tema.AMARILLO)
	contenido.add_child(l)


# Las licencias enteras, en una caja con barra: es mucho texto (unas 110.000 letras), y la caja solo dibuja lo que se ve. Con el
# foco en ella, las flechas y la cruceta del mando la bajan y la suben
func licencias() -> void:
	var volver := opcion(Idioma.t("Volver a los créditos"))
	volver.pressed.connect(func(): ver("creditos"))
	volver.grab_focus.call_deferred()
	explicar(Idioma.t("Los textos legales, tal como se publicaron (en inglés)"))
	var caja := RichTextLabel.new()
	caja.custom_minimum_size = Vector2(620, 280)
	caja.focus_mode = Control.FOCUS_ALL
	caja.add_theme_color_override("default_color", Tema.GRIS)
	caja.text = texto_de_licencias()
	contenido.add_child(caja)


# Las licencias: las de las letras de otros (sus .txt) y la de Godot, con las de las piezas de otros que lleva dentro (Godot las
# da: Engine.get_license_text, get_copyright_info y get_license_info). En inglés, como se publicaron
static func texto_de_licencias() -> String:
	var partes := PackedStringArray(["Johnny Rush: Zombie Escape uses these fonts, under the SIL Open Font License 1.1:"])   # no-tr
	for l in LETRAS_DE_OTROS:
		partes.append(FileAccess.get_file_as_string(l[2]).strip_edges())
	partes.append("This game uses Godot Engine (godotengine.org), available under the following license:\n\n"   # no-tr
		+ Engine.get_license_text().strip_edges())
	var piezas := PackedStringArray()
	for c: Dictionary in Engine.get_copyright_info():
		for p: Dictionary in c.parts:
			piezas.append("%s\n(c) %s\nLicense: %s" % [c.name, "\n(c) ".join(p.copyright), p.license])   # no-tr
	partes.append("Godot Engine includes these third-party components:\n\n" + "\n\n".join(piezas))   # no-tr
	var textos := Engine.get_license_info()
	for nombre: String in textos:
		partes.append("License: %s\n\n%s" % [nombre, textos[nombre].strip_edges()])   # no-tr
	return "\n\n= = = = =\n\n".join(partes)


# Un botón que, a cada pulsación, pasa al siguiente valor de la lista, lo guarda en los ajustes y se lo
# dice a los botones táctiles (se nota al momento, también al volver de la pausa)
func rotar(nombre: String, clave: String, valores: Array, variacion := "") -> void:
	var cual := func() -> int:
		var actual = Guardado.cargar().ajustes[clave]
		for i in valores.size():
			if str(valores[i][0]) == str(actual):   # con str: el guardado trae los números con decimales
				return i
		return 0
	var b := opcion("%s: %s" % [nombre, Idioma.t(valores[cual.call()][1])], variacion)
	b.pressed.connect(func():
		var nuevo: Array = valores[(cual.call() + 1) % valores.size()]
		Guardado.cambiar(func(g): g.ajustes[clave] = nuevo[0])
		Tactil.ajustar()
		b.text = "%s: %s" % [nombre, Idioma.t(nuevo[1])])


# Un botón de la lista, centrado. "variacion": "BotonGrande" para los de General, como los del menú de inicio
func opcion(texto: String, variacion := "") -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = variacion
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size.x = 360
	contenido.add_child(b)
	return b


func controles() -> void:
	var tabla := GridContainer.new()
	tabla.add_theme_constant_override("h_separation", 24)
	tabla.add_theme_constant_override("v_separation", 2)
	if Tactil.activo:
		contenido.add_child(tabla)
		tabla.columns = 2
		for f in TACTIL:
			celda(tabla, Idioma.t(f[0]))
			celda(tabla, Idioma.t(f[1]), "Sub")
		return
	# La tabla va en una caja con barra, por si no cabe (con el mando, la barra sigue a la casilla elegida)
	var caja := ScrollContainer.new()
	caja.custom_minimum_size = Vector2(620, 330)
	caja.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.follow_focus = true
	contenido.add_child(caja)
	tabla.columns = 3
	tabla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_child(tabla)
	celda(tabla, "", "Sub")
	celda(tabla, Idioma.t("Teclado y ratón"), "Sub")
	celda(tabla, Idioma.t("Mando"), "Sub")
	for f in FILAS:
		celda(tabla, Idioma.t(f[0]))
		if f[1].is_empty():   # apuntar
			celda(tabla, Idioma.t("Ratón"), "Sub")
			celda(tabla, Idioma.t("Stick dcho."), "Sub")
			continue
		casilla(tabla, f[1][0], false)
		casilla(tabla, f[1][0], true)
	# Debajo de la tabla, lo que ha pasado (esperando una tecla, cambiado, restablecido...): vacío hasta que pasa algo
	aviso = Label.new()
	aviso.theme_type_variation = "Sub"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(aviso)
	opcion(Idioma.t("Restablecer controles")).pressed.connect(func():
		Controles.restablecer()
		refrescar()
		aviso.text = Idioma.t("Vuelven a estar los controles de serie"))


func celda(tabla: GridContainer, texto: String, variacion := "") -> void:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = variacion
	tabla.add_child(l)


# Una casilla de la tabla que se puede pulsar para cambiar la tecla (o el botón del mando) de una acción
func casilla(tabla: GridContainer, accion: String, mando: bool) -> void:
	var b := Button.new()
	b.theme_type_variation = "Celda"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text = nombres([accion], mando)
	b.pressed.connect(func(): esperar(b, accion, mando))
	tabla.add_child(b)
	casillas.append([b, accion, mando])


func esperar(b: Button, accion: String, mando: bool) -> void:
	if esperando:
		refrescar()
	esperando = b
	esperando_accion = accion
	esperando_mando = mando
	esperando_desde = Time.get_ticks_msec()
	b.text = Idioma.t("Pulsa un botón del mando...") if mando else Idioma.t("Pulsa una tecla o un clic...")
	aviso.text = Idioma.t("Esc para dejarlo como estaba")


# Vuelve a escribir lo que pone cada casilla (tras cambiar una, que puede haber cambiado otra al intercambiarse)
func refrescar() -> void:
	esperando = null
	for c in casillas:
		c[0].text = nombres([c[1]], c[2])


# Los nombres de las teclas (mando = false) o de los botones del mando (mando = true) de unas acciones,
# sin repetir, separados por " / "
func nombres(acciones: Array, mando: bool) -> String:
	var lista: Array[String] = []
	for a in acciones:
		for ev in Controles.eventos(a, mando):
			var n := nombre_evento(ev)
			if n != "" and not n in lista:
				lista.append(n)
	return " / ".join(lista) if not lista.is_empty() else "-"


static func nombre_tecla(c: Key) -> String:
	if c in TECLAS:
		return Idioma.t(TECLAS[c])
	if OS.has_feature("web"):
		return Controles.letra_web(c)
	# La letra que hay en esa posición del teclado del jugador (en un teclado francés, la A está donde la Q)
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(c))


# El nombre de una tecla, botón del ratón o del mando, para enseñarlo
static func nombre_evento(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return nombre_tecla(Controles.codigo(ev))
	if ev is InputEventMouseButton:
		return Idioma.t(RATON.get(ev.button_index, "Ratón"))
	if ev is InputEventJoypadButton:
		return Idioma.t(BOTONES_MANDO[ev.button_index]) if ev.button_index in BOTONES_MANDO else Idioma.t("Botón %d") % ev.button_index
	if ev is InputEventJoypadMotion:
		var sentido: String = Idioma.t(SENTIDOS[ev.axis][1 if ev.axis_value > 0 else 0]) if ev.axis in SENTIDOS else ""
		return (Idioma.t(EJES_MANDO[ev.axis]) if ev.axis in EJES_MANDO else Idioma.t("Eje %d") % ev.axis) + sentido
	return ""


func texto_sonido() -> String:
	return Idioma.t("Sonido: %s") % (Idioma.t("No") if Sonido.silenciado() else Idioma.t("Sí"))


func texto_musica() -> String:
	return Idioma.t("Música: %s") % (Idioma.t("Sí") if Guardado.cargar().ajustes.musica else Idioma.t("No"))


# B del mando o Esc: volver. Si una casilla espera tecla, lo que se pulse es para ella (Esc la deja como estaba)
func _input(evento: InputEvent) -> void:
	if esperando:
		esperar_tecla(evento)
		return
	if not find_children("*", "Tutorial", false, false).is_empty():   # no-tr (con el Tutorial abierto encima, su Esc es suyo: vuelve aquí)
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		atras()


func esperar_tecla(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()   # que no lo use nadie más (ni para moverse por el menú)
	if Time.get_ticks_msec() - esperando_desde < 200:
		return   # aún es el pulsar con el que se eligió la casilla
	var cancelar: bool = evento is InputEventKey and evento.pressed and Controles.codigo(evento) == KEY_ESCAPE
	# Esperando un botón del mando, un clic también lo deja como estaba (por si no hay mando)
	if esperando_mando and evento is InputEventMouseButton and evento.pressed:
		cancelar = true
	var casilla_elegida := esperando
	if cancelar:
		refrescar()
		aviso.text = Idioma.t("Sin cambios")
		casilla_elegida.grab_focus()
		return
	var nuevo := Controles.capturar(evento, esperando_mando)
	if nuevo == null:
		return
	Controles.cambiar(esperando_accion, nuevo)
	refrescar()
	aviso.text = Idioma.t("Cambiado a %s") % nombre_evento(nuevo)
	casilla_elegida.grab_focus()
