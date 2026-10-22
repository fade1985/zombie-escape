# El ordenador de la sala de mantenimiento, "ConserjeOS" (src/ordenador.js del JS). Al arrimarse a la mesa
# (mapa/ordenador.gd) el juego se pausa y sale la pantalla: un monitor viejo con su escritorio, sus iconos, la
# barra de tareas con el reloj y una ventana para cada programa:
#   - "Compra de puntos e intercambio": cambia los dólares ahorrados por puntos de talento (talentos.gd) y los
#     gasta en el árbol de talentos. Lo comprado se nota al momento.
#   - "Tienda de armas": compra con los dólares ahorrados un arma (Armas.PRECIOS) para esta partida, y queda
#     desbloqueada en el guardado. La que llevaras en ese hueco: si es cuerpo a cuerpo, va al inventario (para
#     el banco de trabajo); si es de fuego, se pierde.
#   - "Logros": los retos del juego (logros.gd), para elegir cuál intentar en esta partida. Los conseguidos se
#     cobran aquí (su premio va a los dólares ahorrados).
#   - "Dosier": las páginas del dosier VD-7 encontradas junto a los científicos muertos (historia.gd), de todos
#     los edificios, para releerlas. Las que faltan salen como páginas arrancadas.
#   - "Noticias": las emisiones de Canal 8 ya salidas (historia.gd), en una tele vieja (ui/tele.gd). Las que no se
#     han visto llevan "¡NUEVA!" (y el icono del escritorio avisa).
# Solo se pueden gastar los dólares ahorrados: los de la partida en curso no cuentan hasta completar el edificio.
# Va con el ratón, con flechas + Intro o con el mando. Esc (o B) cierra la ventana y, si no hay ninguna, apaga.
extends CanvasLayer

signal apagado

const ESCRITORIO := Color("#15595d")   # el fondo del escritorio
const TITULO := Color("#20357a")       # la barra de título de las ventanas
const CARCASA := Color("#a49a83")      # el plástico del monitor, amarillento de viejo
const ICONOS := [   # [programa, icono, nombre]
	["puntos", "billete", "Puntos e\nintercambio"],
	["armas", "pistola", "Tienda\nde armas"],
	["logros", "trofeo", "Logros"],
	["dosier", "dosier", "Dosier\nVD-7"],
	["noticias", "noticias", "Noticias"],
	["apagar", "puerta", "Apagar"],
]
const NOMBRES := {"puntos": "PUNTOS.EXE", "armas": "ARMAS.EXE", "logros": "LOGROS.EXE", "dosier": "DOSIER.TXT", "noticias": "CANAL8.TV"}
const TAREAS := {"puntos": "Compra de puntos e intercambio", "armas": "Tienda de armas", "logros": "Logros", "dosier": "Dosier VD-7", "noticias": "Noticias de Canal 8"}
const ICONO_ARMA := {"mp5": "pistola"}
# Los colores de las ventanas, los de Windows 95 del JS (.pc-win en style.css)
const BEIS := Color("#c3bba5")         # el fondo de la ventana
const TARJETA := Color("#d8d1bb")
const TARJETA_LUZ := Color("#ebe4cd")  # la marcada
const LUZ := Color("#f4efe0")          # el relieve: borde con luz...
const SOMBRA := Color("#3a352b")       # ...y con sombra
const TINTA := Color("#1b1712")
const TINTA_SUAVE := Color("#4a4336")
const GRIS := Color("#8e8570")
const AZUL := Color("#1d2a6b")
const AZUL_CLARO := Color("#5a6ea8")
const VERDE := Color("#a9c79a")        # la que llevas o el talento lleno
const VERDE_OSCURO := Color("#2f6b2a")
const PIP := Color("#d8d0b8")          # los cuadraditos de nivel de los talentos
const PIP_LLENO := Color("#e8b923")

var partida: Node
var fondo: ColorRect
var pantalla: Control
var iconos: VBoxContainer
var ventana: Control
var info: Label             # la línea de abajo de la ventana: explica lo que está marcado
var tarea: Label
var reloj: Label
var abierta := ""           # el programa abierto ("" = solo el escritorio)


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


# Enciende el ordenador (el juego ya está en pausa)
func encender(p: Node) -> void:
	partida = p
	montar_monitor()
	# el efecto de encendido de los monitores viejos: una raya que se abre
	pantalla.pivot_offset = pantalla.custom_minimum_size / 2.0
	pantalla.scale = Vector2(1, 0.03)
	pantalla.modulate = Color(2, 2, 2)
	var tween := pantalla.create_tween().set_parallel()
	tween.tween_property(pantalla, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pantalla, "modulate", Color.WHITE, 0.35)
	abrir("")


func apagar() -> void:
	if fondo:
		fondo.queue_free()
		fondo = null
	abierta = ""
	apagado.emit()


func montar_monitor() -> void:
	fondo = ColorRect.new()
	fondo.color = Color(0.03, 0.02, 0.05, 0.85)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var monitor := PanelContainer.new()
	monitor.add_theme_stylebox_override("panel", caja(CARCASA, Color("#3b3529"), 4, 12, 18))
	centro.add_child(monitor)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	monitor.add_child(columna)

	pantalla = Control.new()
	pantalla.custom_minimum_size = Vector2(880, 556)
	pantalla.clip_contents = true
	columna.add_child(pantalla)
	var escritorio := ColorRect.new()
	escritorio.color = ESCRITORIO
	escritorio.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla.add_child(escritorio)

	iconos = VBoxContainer.new()
	iconos.position = Vector2(10, 12)
	iconos.add_theme_constant_override("separation", 4)
	pantalla.add_child(iconos)
	for i in ICONOS:
		var b := Button.new()
		b.name = "icono_" + i[0]
		b.text = i[2]
		b.icon = load("res://assets/ui/iconos/%s.png" % i[1])
		b.flat = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size = Vector2(132, 80)
		b.add_theme_stylebox_override("normal", caja(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 4, 2))   # sin el margen grande del tema: caben los 6
		b.add_theme_stylebox_override("hover", caja(Color(1, 1, 1, 0.12), Color(0, 0, 0, 0), 0, 4, 2))
		b.add_theme_stylebox_override("pressed", caja(Color(1, 1, 1, 0.2), Color(0, 0, 0, 0), 0, 4, 2))
		var programa: String = i[0]
		if programa == "noticias" and not Historia.noticias_nuevas(Guardado.cargar()).is_empty():
			b.text = "Noticias\n¡NUEVAS!"
			b.add_theme_color_override("font_color", Tema.AMARILLO)
		b.pressed.connect(func():
			if programa == "apagar":
				apagar()
			else:
				abrir(programa))
		iconos.add_child(b)

	# la barra de tareas
	var barra := PanelContainer.new()
	barra.add_theme_stylebox_override("panel", caja(Color("#1c1a24"), Color("#4a4556"), 2, 0, 4))
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_top = -34
	pantalla.add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	barra.add_child(fila)
	var inicio := PanelContainer.new()
	inicio.theme_type_variation = "PastillaOn"
	var marca := Label.new()
	marca.text = "ConserjeOS"
	inicio.add_child(marca)
	fila.add_child(inicio)
	tarea = Label.new()
	tarea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tarea.theme_type_variation = "Sub"
	fila.add_child(tarea)
	reloj = Label.new()
	fila.add_child(reloj)

	# las rayas de los monitores viejos, por encima de todo (sin quitarle el ratón a nadie)
	var rayas := TextureRect.new()
	var img := Image.create(1, 3, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0.18))
	rayas.texture = ImageTexture.create_from_image(img)
	rayas.stretch_mode = TextureRect.STRETCH_TILE
	rayas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rayas.set_anchors_preset(Control.PRESET_FULL_RECT)
	rayas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.add_child(rayas)

	# debajo de la pantalla, la marca y el piloto encendido
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 10)
	columna.add_child(pie)
	var nombre := Label.new()
	nombre.text = "CONSERJE  OS 95"
	nombre.add_theme_color_override("font_color", Color("#4d4537"))
	nombre.add_theme_constant_override("outline_size", 0)
	pie.add_child(nombre)
	var piloto := ColorRect.new()
	piloto.color = Tema.VERDE
	piloto.custom_minimum_size = Vector2(8, 8)
	piloto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pie.add_child(piloto)
	_process(0.0)


func _process(_delta: float) -> void:
	if reloj:
		var h := Time.get_time_dict_from_system()
		reloj.text = "%02d:%02d" % [h.hour, h.minute]


# Abre un programa ("" = cerrar la ventana y quedarse en el escritorio). "foco": el botón que hay que dejar
# marcado (al volver a pintar después de comprar algo)
func abrir(programa: String, foco := "") -> void:
	var antes := abierta
	abierta = programa
	if programa != antes:
		Sonido.tocar("click")
	if ventana:
		ventana.queue_free()
		ventana = null
	tarea.text = TAREAS.get(programa, "")
	if programa == "":
		var icono := iconos.get_node_or_null("icono_" + antes)
		(icono if icono else iconos.get_child(0)).grab_focus.call_deferred()
		return
	var contenido := montar_ventana(programa)
	if programa == "puntos":
		programa_puntos(contenido)
	elif programa == "logros":
		programa_logros(contenido)
	elif programa == "dosier":
		programa_dosier(contenido)
	elif programa == "noticias":
		foco = programa_noticias(contenido, foco)
	else:
		programa_armas(contenido)
	var marcado: Control = contenido.find_child(foco, true, false) if foco != "" else null
	if marcado == null:
		marcado = primer_boton(contenido)
	if marcado:
		marcado.grab_focus.call_deferred()


func primer_boton(nodo: Node) -> Button:
	for hijo in nodo.get_children():
		if hijo is Button:
			return hijo
		var dentro := primer_boton(hijo)
		if dentro:
			return dentro
	return null


# La ventana, como las de Windows 95 del JS (.pc-win en style.css): marco beis con relieve, barra de título azul
# con degradado y su X, el contenido (con barra de desplazamiento si no cabe) y, abajo, una barra de estado que
# explica lo que está marcado
func montar_ventana(programa: String) -> VBoxContainer:
	ventana = PanelContainer.new()
	ventana.add_theme_stylebox_override("panel", caja(BEIS, BEIS, 0, 0, 3))
	ventana.draw.connect(func(): relieve(ventana, false, 3.0))
	ventana.position = Vector2(152, 10)
	ventana.size = Vector2(718, 508)
	pantalla.add_child(ventana)
	pantalla.move_child(ventana, iconos.get_index() + 1)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	ventana.add_child(columna)

	var barra := PanelContainer.new()
	var degradado := Gradient.new()
	degradado.set_color(0, AZUL)
	degradado.set_color(1, AZUL_CLARO)
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.width = 64
	textura.height = 1
	var estilo := StyleBoxTexture.new()
	estilo.texture = textura
	estilo.set_content_margin_all(3)
	estilo.content_margin_left = 8
	barra.add_theme_stylebox_override("panel", estilo)
	columna.add_child(barra)
	var fila := HBoxContainer.new()
	barra.add_child(fila)
	var titulo := Label.new()
	titulo.text = "C:\\MANTENIMIENTO\\" + NOMBRES[programa]
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)
	var x := Button.new()
	x.text = "X"
	x.custom_minimum_size = Vector2(28, 22)
	for estado in ["normal", "hover", "pressed"]:
		x.add_theme_stylebox_override(estado, caja(TARJETA_LUZ if estado == "hover" else BEIS, BEIS, 0, 0, 0))
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		x.add_theme_color_override(c, TINTA)
	x.add_theme_constant_override("outline_size", 0)
	x.draw.connect(func(): relieve(x, x.button_pressed, 2.0))
	x.focus_mode = Control.FOCUS_NONE   # con el mando se cierra con B
	x.pressed.connect(abrir.bind(""))
	fila.add_child(x)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 8)
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(margen)
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.follow_focus = true
	margen.add_child(desliza)
	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 8)
	desliza.add_child(contenido)

	# la barra de estado, hundida
	var hueco := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		hueco.add_theme_constant_override("margin_" + lado, 3)
	columna.add_child(hueco)
	var estado_barra := PanelContainer.new()
	estado_barra.add_theme_stylebox_override("panel", caja(BEIS, BEIS, 0, 0, 5))
	estado_barra.draw.connect(func(): relieve(estado_barra, true, 2.0))
	hueco.add_child(estado_barra)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(0, 34)
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", TINTA)
	info.add_theme_constant_override("outline_size", 0)
	estado_barra.add_child(info)
	return contenido


# ── Compra de puntos e intercambio ──

func programa_puntos(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	var alcanzables: int = s.dolares / Talentos.PRECIO_PUNTO
	saldo(c, s)
	nota_partida(c)
	var cambio := grupo(c, "Intercambio · $%d = 1 punto" % Talentos.PRECIO_PUNTO)
	var botones := rejilla(cambio)
	var uno := tarjeta(botones, "b_comprar_1", "billete", "Comprar 1 punto", "Cuesta $%d" % Talentos.PRECIO_PUNTO,
		"Cambiar", "" if alcanzables >= 1 else "bloqueada")
	enlazar(uno, "Cambia $%d por 1 punto de talento" % Talentos.PRECIO_PUNTO, comprar.bind(1))
	var todo := tarjeta(botones, "b_comprar_todo", "billete",
		"Comprar %d puntos (todo)" % alcanzables if alcanzables > 1 else "Comprar todo lo posible",
		"Cuesta $%d" % (alcanzables * Talentos.PRECIO_PUNTO) if alcanzables >= 1 else "Necesitas $%d" % Talentos.PRECIO_PUNTO,
		"Cambiar", "" if alcanzables >= 1 else "bloqueada")
	enlazar(todo, "Cambia todos los dólares que puedas por puntos ($%d = 1 punto)" % Talentos.PRECIO_PUNTO,
		func(): comprar(maxi(1, Guardado.cargar().dolares / Talentos.PRECIO_PUNTO)))
	var arbol_grupo := grupo(c, "Árbol de talentos · cada punto sube un nivel")
	var arbol := HBoxContainer.new()
	arbol.add_theme_constant_override("separation", 10)
	arbol_grupo.add_child(arbol)
	for rama in Talentos.RAMAS:
		arbol.add_child(montar_rama(s, rama))
	info.text = "Cada punto sube un nivel. Para pasar al nivel siguiente, llena antes el talento que pide."


# Lo ahorrado (y, en la de puntos, los puntos): cajas azules hundidas, como .pc-saldo del JS
func saldo(c: VBoxContainer, s: Dictionary) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	c.add_child(fila)
	cajita(fila, "Dólares ahorrados", "billete", "$%d" % s.dolares)
	if abierta == "puntos":
		cajita(fila, "Puntos de talento", "trofeo", "%d" % s.puntos)


func cajita(fila: HBoxContainer, rotulo: String, icono: String, valor: String) -> void:
	var marco := PanelContainer.new()
	marco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_theme_stylebox_override("panel", caja(AZUL, AZUL, 0, 0, 6))
	marco.draw.connect(func(): relieve(marco, true, 2.0))
	fila.add_child(marco)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	marco.add_child(columna)
	var arriba := Label.new()
	arriba.text = rotulo
	arriba.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	columna.add_child(arriba)
	var abajo := Tema.icono_y_texto(icono, valor, 24)
	abajo.get_child(1).add_theme_color_override("font_color", Color.WHITE)
	columna.add_child(abajo)


func nota_partida(c: VBoxContainer) -> void:
	if partida.dolares > 0:
		nota(c, "Los $%d de esta partida no se pueden gastar hasta que completes el edificio." % partida.dolares)


func nota(c: VBoxContainer, texto: String) -> void:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = texto
	l.add_theme_color_override("font_color", TINTA_SUAVE)
	l.add_theme_constant_override("outline_size", 0)
	c.add_child(l)


# Un grupo con su título subrayado (.pc-grupo): devuelve dónde van sus cosas
func grupo(c: VBoxContainer, titulo: String) -> VBoxContainer:
	var caja_grupo := VBoxContainer.new()
	caja_grupo.add_theme_constant_override("separation", 4)
	c.add_child(caja_grupo)
	var l := Label.new()
	l.text = titulo
	l.add_theme_color_override("font_color", TINTA)
	l.add_theme_constant_override("outline_size", 0)
	caja_grupo.add_child(l)
	var raya := ColorRect.new()
	raya.color = GRIS
	raya.custom_minimum_size = Vector2(0, 2)
	caja_grupo.add_child(raya)
	return caja_grupo


# Las tarjetas en dos columnas
func rejilla(c: Container) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	c.add_child(g)
	return g


# Una rama del árbol (.pc-rama): su título en azul y, debajo, sus niveles (1 arriba, 3 abajo), cada uno con su
# número a la izquierda y sus talentos uno debajo de otro
func montar_rama(s: Dictionary, rama: Dictionary) -> VBoxContainer:
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 5)
	var titulo := PanelContainer.new()
	titulo.add_theme_stylebox_override("panel", caja(AZUL, AZUL, 0, 0, 4))
	columna.add_child(titulo)
	titulo.add_child(Tema.icono_y_texto(rama.icono, rama.nombre, 24))
	for nivel in [1, 2, 3]:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		columna.add_child(fila)
		var numero := Label.new()
		numero.text = str(nivel)
		numero.custom_minimum_size = Vector2(20, 22)
		numero.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numero.add_theme_color_override("font_color", TARJETA_LUZ)
		numero.add_theme_constant_override("outline_size", 0)
		numero.add_theme_stylebox_override("normal", caja(TINTA_SUAVE, TINTA_SUAVE, 0, 0, 0))
		fila.add_child(numero)
		var lista := VBoxContainer.new()
		lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lista.add_theme_constant_override("separation", 4)
		fila.add_child(lista)
		for t in Talentos.LISTA:
			if t.rama == rama.id and t.nivel == nivel:
				nodo_talento(lista, s, t)
	return columna


func nodo_talento(lista: VBoxContainer, s: Dictionary, t: Dictionary) -> void:
	var n := Talentos.nivel_de(s, t.id)
	var motivo := Talentos.motivo(s, t.id)
	var estado: String = {"max": "lleno", "bloqueado": "bloqueada", "sin_puntos": "apagada"}.get(motivo, "")
	var debajo: String = t.desc
	if motivo == "bloqueado":
		debajo = "Necesitas %s al máximo" % Talentos.talento(t.pide).nombre
	elif motivo == "max":
		debajo = "¡Al máximo!"
	var etiqueta := "MÁX" if motivo == "max" else ("" if motivo == "bloqueado" else "+1")
	var b := tarjeta(lista, "b_" + t.id, "candado" if motivo == "bloqueado" else t.icono, t.nombre, debajo, etiqueta,
		estado, [n, t.max])
	var texto: String = t.desc
	if t.id in Talentos.MAS_ADELANTE:
		texto += " (llega con los objetos, en la fase 7)"
	match motivo:
		"bloqueado": texto = "Necesitas %s al máximo. %s" % [Talentos.talento(t.pide).nombre, texto]
		"max": texto = "¡Al máximo! " + texto
		"sin_puntos": texto += ". Te hace falta 1 punto."
		"": texto += ". Pulsa para subirlo (1 punto)."
	enlazar(b, texto, subir.bind(t.id))


func comprar(n: int) -> void:
	var s := Talentos.comprar_puntos(n)
	if s.is_empty():
		info.text = "No te llega: cada punto cuesta $%d de lo ahorrado." % Talentos.PRECIO_PUNTO
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	partida.ahorrados = s.dolares   # el HUD enseña lo ahorrado más lo de esta partida
	abrir("puntos", "b_comprar_1" if s.dolares >= Talentos.PRECIO_PUNTO else "")
	info.set_deferred("text", "¡Hecho! Ahora tienes %d puntos para gastar." % s.puntos)   # después de marcar el botón (que pone su explicación)


func subir(id: String) -> void:
	var motivo := Talentos.motivo(Guardado.cargar(), id)
	if motivo != "":
		Sonido.tocar("no")
		return   # la línea de info ya dice por qué no se puede
	Sonido.tocar("compra")
	var s := Talentos.subir(id)
	partida.aplicar_talentos(s.talentos)
	abrir("puntos", "b_" + id)
	info.set_deferred("text", "¡%s sube a %d/%d!" % [Talentos.talento(id).nombre, Talentos.nivel_de(s, id), Talentos.talento(id).max])   # después de marcar el botón (que pone su explicación)


# ── Tienda de armas ──

func programa_armas(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	saldo(c, s)
	nota(c, "Lo que compres es para esta partida y queda desbloqueado. La de cuerpo a cuerpo que llevaras va al inventario; la de fuego, se pierde.")
	nota_partida(c)
	var ids := Armas.PRECIOS.keys()
	ids.sort_custom(func(a, b): return Armas.PRECIOS[a] < Armas.PRECIOS[b])
	for tipo in ["cuerpo", "fuego"]:
		var lista := rejilla(grupo(c, "Cuerpo a cuerpo" if tipo == "cuerpo" else "De fuego · con el cargador lleno y munición de reserva"))
		for id in ids:
			var w: Dictionary = Armas.DATOS[id]
			if w.tipo != tipo:
				continue
			var precio: int = Armas.PRECIOS[id]
			var lleva: bool = partida.johnny.huecos[tipo] == id
			var etiqueta := "LA LLEVAS" if lleva else ("GRATIS" if precio == 0 else "$%d" % precio)
			var estado := "puesta" if lleva else ("" if s.dolares >= precio else "bloqueada")
			var b := tarjeta(lista, "b_" + id, ICONO_ARMA.get(id, id), w.nombre, resumen_corto(w), etiqueta, estado)
			enlazar(b, resumen(w), comprar_arma.bind(id))
	info.text = "Elige un arma: se paga con los dólares ahorrados."


# Debajo del nombre, como weaponSummary del JS: "Cuerpo a cuerpo · Daño 9 · 4 ataques/s"
func resumen_corto(w: Dictionary) -> String:
	var dano := "%d × %d" % [w.dano, w.perdigones] if w.get("perdigones", 1) > 1 else str(w.dano)
	var texto := "%s · Daño %s · %s ataques/s" % ["Cuerpo a cuerpo" if w.tipo == "cuerpo" else "De fuego", dano,
		str(w.ritmo).trim_suffix(".0")]
	if w.tipo == "fuego":
		texto += " · Cargador %d" % w.cargador
	return texto


func resumen(w: Dictionary) -> String:
	var texto := "%s: daño %d" % [w.nombre, w.dano]
	if w.get("perdigones", 1) > 1:
		texto += " x%d perdigones" % w.perdigones
	texto += ", %.1f ataques por segundo" % w.ritmo
	if w.tipo == "fuego":
		texto += ", cargador de %d" % w.cargador
	return texto + "."


func comprar_arma(id: String) -> void:
	var w: Dictionary = Armas.DATOS[id]
	var johnny: Node = partida.johnny
	if johnny.huecos[w.tipo] == id:
		info.text = "Ya llevas %s." % w.nombre.to_lower()
		Sonido.tocar("no")
		return
	var s := Guardado.cargar()
	var precio: int = Armas.PRECIOS[id]
	if s.dolares < precio:
		info.text = "No te llega: te faltan $%d." % (precio - s.dolares)
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	s.dolares -= precio
	if not id in s.armas:
		s.armas.append(id)
	Guardado.escribir(s)
	partida.ahorrados = s.dolares
	var vieja: String = Armas.datos(johnny.huecos[w.tipo]).nombre
	if w.tipo == "cuerpo" or Armas.es_creada(johnny.huecos[w.tipo]):
		partida.armas_guardadas.append(johnny.huecos[w.tipo])   # al inventario (las creadas de fuego, también)
		partida.armas_guardadas.erase(id)   # si la compras teniéndola guardada, no se queda repetida
	johnny.coger(id)
	abrir("armas", "b_" + id)
	info.set_deferred("text", ("¡%s comprada! %s va al inventario." if w.tipo == "cuerpo" else "¡%s comprada! Dejas %s.") % [w.nombre, vieja if w.tipo == "cuerpo" else vieja.to_lower()])   # después de marcar el botón (que pone su explicación)


# ── Logros ──

func programa_logros(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	var hechos := 0
	var por_cobrar := 0
	for l in Logros.LISTA:
		var e := Logros.estado(s, l.id)
		if e != "pendiente":
			hechos += 1
		if e == "conseguido":
			por_cobrar += l.premio
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	c.add_child(fila)
	cajita(fila, "Logros conseguidos", "trofeo", "%d / %d" % [hechos, Logros.LISTA.size()])
	cajita(fila, "Premios por cobrar", "billete", "$%d" % por_cobrar)
	cajita(fila, "Dólares ahorrados", "billete", "$%d" % s.dolares)
	nota(c, "Elige un reto para esta partida. Al cumplirlo sale un aviso; vuelve aquí a cobrar el premio.")
	var lista := rejilla(grupo(c, "Retos"))
	for l in Logros.LISTA:
		var e := Logros.estado(s, l.id)
		var etiqueta: String = {"pendiente": "$%d" % l.premio, "conseguido": "COBRAR $%d" % l.premio, "cobrado": "HECHO"}[e]
		var hecho: int = l.meta if e != "pendiente" else mini(partida.logros.progreso(l.id), l.meta)
		var barra: Array = [hecho, l.meta] if l.meta > 1 else []
		var b := tarjeta(lista, "b_" + l.id, l.icono, l.nombre, l.desc, etiqueta,
			{"pendiente": "apagada", "conseguido": "", "cobrado": "lleno"}[e], [], barra)
		var cuenta: String = {"partida": " (en una partida)", "total": " (sumando partidas)"}.get(l.cuenta, "")
		var explica: String = {
			"pendiente": ("Premio: $%d. Llevas %d de %d%s." % [l.premio, hecho, l.meta, cuenta]) if l.meta > 1
				else "Premio: $%d. Aún no lo has conseguido." % l.premio,
			"conseguido": "¡Conseguido! Pulsa para cobrar $%d." % l.premio,
			"cobrado": "Conseguido y cobrado.",
		}[e]
		enlazar(b, "%s: %s %s" % [l.nombre, l.desc, explica], cobrar_logro.bind(l.id))
	info.text = "Pasa por encima de un logro para ver cómo vas."


func cobrar_logro(id: String) -> void:
	var dinero := Logros.cobrar(id)
	if dinero == 0:
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	partida.ahorrados = Guardado.cargar().dolares
	abrir("logros", "b_" + id)
	info.set_deferred("text", "¡Cobrados $%d! Ya puedes gastarlos en puntos o armas." % dinero)


# ── Dosier ──

# Las páginas de todos los edificios (no solo del que se juega): se guardan para siempre (Guardado: "paginas"),
# las encuentres donde las encuentres. A la izquierda, las páginas por edificio (con su propio desplazamiento);
# a la derecha, la hoja que se esté mirando. Las que faltan salen como páginas arrancadas
func programa_dosier(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	var halladas := 0
	var total := 0
	for id in Historia.DOSIERES:
		var paginas: Array = Historia.DOSIERES[id].paginas
		total += paginas.size()
		halladas += paginas.filter(func(p): return Historia.encontrada(s, p.id)).size()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	c.add_child(fila)
	cajita(fila, "Dosier VD-7", "dosier", "%d / %d páginas" % [halladas, total])
	nota(c, "Cada página que encuentres, en cualquier edificio y en cualquier planta, queda aquí para siempre.")
	var partes := HBoxContainer.new()
	partes.add_theme_constant_override("separation", 10)
	c.add_child(partes)
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.follow_focus = true
	desliza.custom_minimum_size = Vector2(240, Tele.CAJA_TEXTO.end.y - 40)
	partes.add_child(desliza)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	desliza.add_child(lista)
	var lado := CenterContainer.new()
	lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lado.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	partes.add_child(lado)
	for edificio in Historia.DOSIERES:
		var d: Dictionary = Historia.DOSIERES[edificio]
		var suyas: int = d.paginas.filter(func(p): return Historia.encontrada(s, p.id)).size()
		var nombre: String = Edificios.datos(edificio).nombre if edificio in Edificios.LISTA else edificio
		var del_edificio := grupo(lista, "%s · %d / %d" % [nombre, suyas, d.paginas.size()])
		for i in d.paginas.size():
			var p: Dictionary = d.paginas[i]
			var tiene := Historia.encontrada(s, p.id)
			var b := tarjeta(del_edificio, "b_" + p.id, "dosier" if tiene else "candado", "Página %d" % (i + 1),
				p.titulo if tiene else "Arrancada", "", "" if tiene else "bloqueada")
			var hoja := p if tiene else {"tipo": "???", "titulo": "Página arrancada", "nota": "",
				"texto": Historia.falta(edificio, p)}
			var ver := func():
				for h in lado.get_children():
					h.queue_free()
				lado.add_child(Historia.hoja(hoja, 410.0))
			enlazar(b, ("%s, página %d: %s. La llevaba %s." % [nombre, i + 1, p.titulo, p.cuerpo]) if tiene
				else "%s, página %d: aún no la has encontrado (%s)." % [nombre, i + 1, Historia.donde(p)], ver)
			b.focus_entered.connect(ver)
			b.mouse_entered.connect(ver)
	info.text = "Pasa por las páginas para leerlas."


# ── Noticias ──

# A la izquierda, las emisiones (las que aún no han salido, con candado); a la derecha, la tele. Devuelve la que
# hay que dejar marcada: la primera sin ver o, si no, la última emitida
func programa_noticias(c: VBoxContainer, foco: String) -> String:
	var s := Guardado.cargar()
	var partes := HBoxContainer.new()
	partes.add_theme_constant_override("separation", 10)
	c.add_child(partes)
	# las emisiones, con su propio desplazamiento (ya no caben todas): así la tele no se mueve al bajar por ellas
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.follow_focus = true
	desliza.custom_minimum_size.y = Tele.CAJA_TEXTO.end.y
	partes.add_child(desliza)
	var lista := VBoxContainer.new()
	lista.custom_minimum_size.x = 220
	lista.add_theme_constant_override("separation", 6)
	desliza.add_child(lista)
	var tele := Tele.new()
	tele.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	partes.add_child(tele)
	var nuevas := Historia.noticias_nuevas(s)
	var primera_nueva := ""
	var ultima := ""
	for i in Historia.NOTICIAS.size():
		var n: Dictionary = Historia.NOTICIAS[i]
		var sale := Historia.emitida(s, n)
		var nueva := n in nuevas
		var b := tarjeta(lista, "b_" + n.id, "noticias" if sale else "candado", "Emisión %d" % (i + 1),
			n.titular if sale else "Sin emitir", "¡NUEVA!" if nueva else "", "" if sale else "bloqueada")
		if not sale:
			var pista := ("Completa %s." % Edificios.datos(n.victoria).el_nombre) if n.victoria != "" else "Sigue buscando páginas del dosier VD-7."
			enlazar(b, "Emisión %d: aún no ha salido. %s" % [i + 1, pista], Sonido.tocar.bind("no"))
			continue
		ultima = "b_" + n.id
		if nueva and primera_nueva == "":
			primera_nueva = ultima
		var ver := func():
			if tele.noticia != n:
				tele.poner(n)
				Historia.ver_noticia(n.id)
		enlazar(b, "Emisión %d: «%s». Pulsa para saltar o repetir." % [i + 1, n.titular], tele.saltar)
		b.focus_entered.connect(ver)
		b.mouse_entered.connect(ver)
	info.text = "%s, con %s. Pasa por las emisiones para verlas." % [Historia.CANAL, Historia.REPORTERA]
	if foco != "":
		return foco
	return primera_nueva if primera_nueva != "" else ultima


# ── Piezas ──

# Una tarjeta (.pc-arma del JS): con relieve, su icono grande, el nombre (y, en los talentos, sus cuadraditos de
# nivel), una línea de explicación debajo y la etiqueta azul de la derecha ("$15", "+1 punto", "MÁX"...).
# "estado": "" (se puede usar), "bloqueada" (apagada), "apagada" (sin puntos: la etiqueta en gris), "puesta" o
# "lleno" (en verde). Por encima lleva un botón transparente del mismo tamaño, que es el que se marca y se pulsa
# (con el ratón, el teclado o el mando) y el que se devuelve
func tarjeta(padre: Container, nombre: String, icono: String, titulo: String, debajo: String, etiqueta: String,
		estado := "", pips := [], barra := []) -> Button:
	var marco := PanelContainer.new()
	marco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	padre.add_child(marco)
	var dentro := MarginContainer.new()
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right"]:
		dentro.add_theme_constant_override("margin_" + lado, 6)
	for lado in ["top", "bottom"]:
		dentro.add_theme_constant_override("margin_" + lado, 5)
	marco.add_child(dentro)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(fila)
	var imagen := TextureRect.new()
	imagen.texture = load("res://assets/ui/iconos/%s.png" % icono)
	imagen.custom_minimum_size = Vector2(32, 32)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if estado == "bloqueada":
		imagen.self_modulate = Color(0.55, 0.55, 0.55)
	fila.add_child(imagen)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 6)
	textos.add_child(arriba)
	arriba.add_child(texto_tarjeta(titulo, TINTA))
	if not pips.is_empty():
		var cuadros := HBoxContainer.new()
		cuadros.add_theme_constant_override("separation", 2)
		cuadros.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for i in pips[1]:
			var cuadro := Panel.new()
			cuadro.custom_minimum_size = Vector2(9, 9)
			cuadro.add_theme_stylebox_override("panel", caja(PIP_LLENO if i < pips[0] else PIP, TINTA, 2, 0, 0))
			cuadros.add_child(cuadro)
		arriba.add_child(cuadros)
	var linea := texto_tarjeta(debajo, TINTA_SUAVE)
	linea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linea.custom_minimum_size.x = 60   # que parta las líneas en vez de ensanchar la tarjeta
	linea.add_theme_font_size_override("font_size", 16)
	textos.add_child(linea)
	if not barra.is_empty():
		# la barra de progreso (los logros): hundida, rellena de amarillo hasta donde va
		var progreso := Control.new()
		progreso.custom_minimum_size = Vector2(0, 10)
		progreso.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progreso.draw.connect(func():
			progreso.draw_rect(Rect2(Vector2.ZERO, progreso.size), PIP)
			progreso.draw_rect(Rect2(Vector2(2, 2), Vector2((progreso.size.x - 4) * barra[0] / float(barra[1]), progreso.size.y - 4)), PIP_LLENO)
			relieve(progreso, true, 2.0))
		textos.add_child(progreso)
	if etiqueta != "":
		var marca := Label.new()
		marca.text = etiqueta
		marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		marca.add_theme_color_override("font_color", Color.WHITE)
		marca.add_theme_constant_override("outline_size", 0)
		var fondo_marca := VERDE_OSCURO if estado in ["puesta", "lleno"] else (GRIS if estado == "apagada" else AZUL)
		marca.add_theme_stylebox_override("normal", caja(fondo_marca, fondo_marca, 0, 0, 4))
		fila.add_child(marca)
	if estado == "bloqueada":
		dentro.modulate = Color(1, 1, 1, 0.55)

	var b := Button.new()
	b.name = nombre
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	marco.add_child(b)
	var fondo_tarjeta := VERDE if estado in ["puesta", "lleno"] else TARJETA
	marco.draw.connect(func():
		var encima := b.has_focus() or b.is_hovered()
		marco.draw_rect(Rect2(Vector2.ZERO, marco.size), TARJETA_LUZ if encima and estado != "bloqueada" else fondo_tarjeta)
		relieve(marco, estado == "puesta", 2.0)
		if encima:
			# el punteado de "marcado" de Windows, por dentro
			var r := Rect2(Vector2(5, 5), marco.size - Vector2(10, 10))
			for lado in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end],
					[r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
				marco.draw_dashed_line(lado[0], lado[1], TINTA, 1.0, 2.0))
	for senal in [b.focus_entered, b.focus_exited, b.mouse_entered, b.mouse_exited]:
		senal.connect(marco.queue_redraw)
	return b


func texto_tarjeta(texto: String, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	return l


# El relieve de Windows 95: luz arriba y a la izquierda, sombra abajo y a la derecha ("hundido": al revés)
func relieve(c: Control, hundido: bool, grosor: float) -> void:
	var luz := SOMBRA if hundido else LUZ
	var sombra := LUZ if hundido else SOMBRA
	var t := c.size
	c.draw_rect(Rect2(0, 0, t.x, grosor), luz)
	c.draw_rect(Rect2(0, 0, grosor, t.y), luz)
	c.draw_rect(Rect2(0, t.y - grosor, t.x, grosor), sombra)
	c.draw_rect(Rect2(t.x - grosor, 0, grosor, t.y), sombra)


# Al marcarlo (con el ratón encima, el teclado o el mando) explica lo que hace en la línea de info
func enlazar(b: Button, texto: String, al_pulsar: Callable) -> void:
	b.focus_entered.connect(func(): info.text = texto)
	b.mouse_entered.connect(func(): info.text = texto)
	b.pressed.connect(al_pulsar)


# Una caja de color con borde (los paneles del ordenador)
func caja(color: Color, borde: Color, grosor: int, redondeo: int, margen: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(redondeo)
	s.set_content_margin_all(margen)
	return s


# Esc o B: cierra la ventana y, si no hay ninguna, apaga el ordenador
func _unhandled_input(evento: InputEvent) -> void:
	if fondo and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		if abierta != "":
			abrir("")
		else:
			apagar()
