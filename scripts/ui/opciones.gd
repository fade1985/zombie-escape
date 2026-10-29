# La pantalla de Opciones: se abre desde el menú principal y desde la pausa. Tiene cuatro pestañas:
#   - General: el idioma (idioma.gd; la pantalla se vuelve a montar al cambiarlo), el modo de atacar (se guarda), la
#     música, el sonido, la pantalla completa y el temblor de pantalla (Normal, Suave o Sin temblor: lo que tiembla la
#     cámara y lo que se frena el juego al golpear, temblor.gd; se guarda). En el móvil, además, el tamaño y la transparencia de los botones
#     táctiles y la vibración (se guardan).
#   - Controles: qué hace cada tecla y cada botón del mando (leído del mapa de controles de Godot). Se pueden
#     cambiar: se pulsa la casilla y luego la tecla o el botón nuevo (controles.gd lo pone y lo guarda).
#     En el móvil, qué hace cada botón táctil.
#   - Ayudas: para que más gente pueda terminar los edificios (vida entera, pistola sin fin, lanzar apuntando solo). Se guardan y se
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
]

# Todos los textos de las tablas de aquí abajo se traducen al enseñarlos (Idioma.t); las marcas son para
# tools/traducciones.py (docs/IDIOMAS.md)
# [traducir]
# Lo que se explica de cada modo de atacar
const MODOS_AYUDA := {
	"asistido": "Johnny apunta y ataca solo al zombi más cercano. Tú solo te preocupas de moverte.",
	"libre": "Apuntas tú: con el ratón, con el stick derecho del mando o con el joystick derecho del móvil.",
}

# Las filas de la pestaña Controles: el nombre y las acciones del mapa de controles (project.godot) que juntan
# (apuntar no se cambia aquí: es el ratón o el stick derecho)
const FILAS := [
	["Moverse: arriba", ["arriba"]],
	["Moverse: izquierda", ["izquierda"]],
	["Moverse: abajo", ["abajo"]],
	["Moverse: derecha", ["derecha"]],
	["Apuntar (modo libre)", []],
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
	["Modo de atacar", ["cambiar_modo"]],
]

# En el móvil, los botones táctiles (scripts/ui/tactil.gd)
const TACTIL := [
	["Moverse", "Joystick: toca y arrastra en la mitad izquierda"],
	["Apuntar", "Solo en \"apuntar libre\": el joystick de abajo a la derecha"],
	["Esquivar", "En asistido, el de la esquina de abajo a la derecha; si no, el del arco"],
	["Armas", "Toca la otra arma para sacarla; toca la de a distancia en la mano para recargar"],
	["Lanzar", "Arrastra desde el botón para apuntar y suelta para tirar"],
	["Molotov o granada", "El botoncito de al lado de lanzar"],
	["Vendas y botiquín", "Los botones de debajo del minimapa (solo salen si llevas)"],
	["Modo, inventario y pausa", "Los botones de debajo del minimapa"],
]

# Los ajustes del móvil (tactil.gd): los valores por los que va pasando cada botón, con su nombre.
# Más de 1,4 no cabe: los botones del arco chocarían con los de debajo del minimapa
const TAMANOS := [[0.8, "Pequeño"], [1.0, "Normal"], [1.2, "Grande"], [1.4, "Muy grande"]]
const OPACIDADES := [[1.0, "100 %"], [0.75, "75 %"], [0.5, "50 %"], [0.3, "30 %"]]
const SI_NO := [[true, "Sí"], [false, "No"]]
# El temblor de pantalla (temblor.gd): por cuánto se multiplica el temblor de la cámara y el parón de los golpes
const TEMBLORES := [[1.0, "Normal"], [0.5, "Suave"], [0.0, "Sin temblor"]]

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
	contenido = VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 8)
	columna.add_child(contenido)
	var volver := Button.new()
	volver.text = Idioma.t("Volver")
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(cerrar)
	columna.add_child(volver)
	ver(cual)


func cerrar() -> void:
	if tapado:
		tapado.show()
	cerrado.emit()
	queue_free()


# Pone una pestaña: vacía el contenido y lo vuelve a llenar
func ver(cual: String) -> void:
	pestana = cual
	for b: Button in pestanas.get_children():
		# La pestaña en la que estás, con las letras amarillas (las licencias son parte de Créditos)
		if b.name == cual or (cual == "licencias" and b.name == "creditos"):
			b.add_theme_color_override("font_color", Tema.AMARILLO)
			b.add_theme_color_override("font_focus_color", Tema.AMARILLO)
			b.add_theme_color_override("font_hover_color", Tema.AMARILLO)
		else:
			for c in ["font_color", "font_focus_color", "font_hover_color"]:
				b.remove_theme_color_override(c)
	for hijo in contenido.get_children():
		hijo.queue_free()
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
	var modo: String = Guardado.cargar().ajustes.modo
	var ayuda := Label.new()
	ayuda.theme_type_variation = "Sub"
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.custom_minimum_size.x = 560
	ayuda.text = Idioma.t(MODOS_AYUDA[modo])
	# El idioma: un botón por idioma, cada uno con su nombre en su idioma (y el rótulo, en dos), para encontrarlo aunque
	# el juego esté en otro. El de ahora, con las letras amarillas como la pestaña en la que estás
	var rotulo_idioma := Label.new()
	rotulo_idioma.theme_type_variation = "Sub"
	rotulo_idioma.text = "Idioma / Language"   # no-tr
	rotulo_idioma.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(rotulo_idioma)
	var fila_idioma := HFlowContainer.new()   # (los botones pasan a otra fila si no caben en el ancho)
	fila_idioma.alignment = FlowContainer.ALIGNMENT_CENTER
	fila_idioma.custom_minimum_size.x = 600
	fila_idioma.add_theme_constant_override("h_separation", 6)
	fila_idioma.add_theme_constant_override("v_separation", 4)
	contenido.add_child(fila_idioma)
	for i in Idioma.IDIOMAS:
		var b := Button.new()
		b.text = i[1]
		var letra := Tema.fuente_del_idioma(i[0])   # (el ruso y el chino se escriben con su letra, en cualquier idioma)
		if letra != null:
			b.add_theme_font_override("font", letra)
		b.pressed.connect(func(): Idioma.poner(i[0]))
		if i[0] == Idioma.actual:
			boton_idioma = b
			for c in ["font_color", "font_focus_color", "font_hover_color"]:
				b.add_theme_color_override(c, Tema.AMARILLO)
		fila_idioma.add_child(b)
	var boton_modo := opcion(Idioma.t("Modo de atacar: %s") % Idioma.t(modos()[modo]))
	boton_modo.pressed.connect(func():
		var orden: Array = modos().keys()
		var nuevo: String = orden[(orden.find(Guardado.cargar().ajustes.modo) + 1) % orden.size()]
		poner_modo(nuevo)
		boton_modo.text = Idioma.t("Modo de atacar: %s") % Idioma.t(modos()[nuevo])
		ayuda.text = Idioma.t(MODOS_AYUDA[nuevo]))
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
		opcion(Idioma.t("Pantalla completa")).pressed.connect(Tactil.pantalla_completa)
	rotar(Idioma.t("Temblor de pantalla"), "temblor", TEMBLORES)
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


# Las ayudas: cada una, un botón de Sí/No con lo que hace debajo
func ayudas() -> void:
	var aviso := explicar(Idioma.t("Con alguna de estas tres ayudas encendida no se consiguen logros en esa partida (aunque la apagues luego). Los que ya tienes se quedan."))
	aviso.add_theme_color_override("font_color", Tema.AMARILLO)
	rotar(Idioma.t("Vida entera"), "vida_entera", SI_NO)
	explicar(Idioma.t("La vida no se parte en tercios: curándote llegas siempre a la vida máxima y no andas más lento."))
	rotar(Idioma.t("Pistola sin fin"), "pistola_sin_fin", SI_NO)
	explicar(Idioma.t("La pistola no gasta balas ni hay que recargarla. Las demás armas, igual que siempre."))
	rotar(Idioma.t("Lanzar apuntando solo"), "lanzar_solo", SI_NO)
	explicar(Idioma.t("El molotov, la granada y las arrojadizas van solos al zombi más cercano que veas. Si no ves ninguno, se lanzan como siempre."))
	rotar(Idioma.t("Tutoriales"), "tutoriales", SI_NO)
	explicar(Idioma.t("La primera vez que te encuentras algo nuevo, una ventana explica qué pasa y cómo se hace. Las ya vistas están en Tutorial."))
	var otra_vez := opcion(Idioma.t("Que vuelvan a salir todos"))
	otra_vez.pressed.connect(func():
		Tutoriales.olvidar()
		Sonido.tocar("click")
		otra_vez.text = Idioma.t("Volverán a salir desde el principio")
		otra_vez.disabled = true)


func explicar(texto: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = "Sub"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 560
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
	var partes := PackedStringArray(["Zombie Escape uses these fonts, under the SIL Open Font License 1.1:"])   # no-tr
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
func rotar(nombre: String, clave: String, valores: Array) -> void:
	var cual := func() -> int:
		var actual = Guardado.cargar().ajustes[clave]
		for i in valores.size():
			if str(valores[i][0]) == str(actual):   # con str: el guardado trae los números con decimales
				return i
		return 0
	var b := opcion("%s: %s" % [nombre, Idioma.t(valores[cual.call()][1])])
	b.pressed.connect(func():
		var nuevo: Array = valores[(cual.call() + 1) % valores.size()]
		Guardado.cambiar(func(g): g.ajustes[clave] = nuevo[0])
		Tactil.ajustar()
		b.text = "%s: %s" % [nombre, Idioma.t(nuevo[1])])


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
	aviso = Label.new()
	aviso.theme_type_variation = "Sub"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.text = Idioma.t("Pulsa una casilla para cambiar esa tecla o ese botón")
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
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()


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
