# El ordenador de la sala de mantenimiento, "ConserjeOS" (src/ordenador.js del JS). Al arrimarse a la mesa
# (mapa/ordenador.gd) el juego se pausa y sale la pantalla: un monitor viejo con su escritorio, sus iconos, la
# barra de tareas con el reloj y una ventana para cada programa:
#   - "Compra de puntos e intercambio": cambia los dólares ahorrados por puntos de talento (talentos.gd) y los
#     gasta en el árbol de talentos. Lo comprado se nota al momento.
#   - "Tienda de armas": compra con los dólares ahorrados un arma (Armas.PRECIOS), en calidad Normal (parte 4 de la
#     tienda y las piezas: Armas.CALIDADES), y queda desbloqueada en el guardado. Va a la mano, y la que llevaras de ese tipo pasa al repuesto o, si ya
#     tienes una de repuesto, se queda en el suelo (partida.llevar_arma: dos de cada tipo como mucho). Desde el
#     25 oct también vende el lanzallamas, el lanza ácido y el lanza rayos, que antes se creaban en el banco.
#     Cuatro secciones, las familias de las piezas (Armas.familia): Cuerpo a cuerpo, A distancia, Especiales y
#     Arrojables. Los arrojables (Lanzables.PRECIOS) se compran de uno en uno, mientras quepan (van a sus montones de
#     5); los que sobren al completar el edificio van al baúl.
#   - "Logros": los retos del juego (logros.gd), por apartados (Logros.TEMAS), para elegir cuál intentar en esta
#     partida. Los conseguidos se cobran aquí (su premio va a los dólares ahorrados).
#   - "Dosier": las páginas del dosier VD-7 encontradas junto a los científicos muertos (historia.gd), de todos
#     los edificios, para releerlas. Las que faltan salen como páginas arrancadas.
#   - "Noticias": las emisiones de Canal 8 ya salidas (historia.gd), en una tele vieja (ui/tele.gd). Las que no se
#     han visto llevan "¡NUEVA!" (y el icono del escritorio avisa).
#   - "Colecciones": lo encontrado y visto alguna vez, por edificio y en porcentaje, y el bestiario
#     (bestiario.gd) con cada enemigo, su dibujo y una frase. Queda entre partidas; el icono avisa si hay algo nuevo.
# Solo se pueden gastar los dólares ahorrados: los de la partida en curso no cuentan hasta que acaba (todos si
# completas el edificio; la mitad si caes).
# Va con el ratón, con flechas + Intro o con el mando. Esc (o B) cierra la ventana y, si no hay ninguna, apaga.
extends CanvasLayer

signal apagado

const ESCRITORIO := Color("#15595d")   # el fondo del escritorio
const CARCASA := Color("#a49a83")      # el plástico del monitor, amarillento de viejo
# Los textos de estas tablas se traducen al enseñarlos (Idioma.t); las marcas son para tools/traducciones.py
# [traducir]
const ICONOS := [   # [programa, icono, nombre]
	["puntos", "billete", "Puntos e\nintercambio"],
	["armas", "pistola", "Tienda\nde armas"],
	["logros", "trofeo", "Logros"],
	["dosier", "dosier", "Dosier\nVD-7"],
	["noticias", "noticias", "Noticias"],
	["colecciones", "colecciones", "Colecciones"],
	["apagar", "puerta", "Apagar"],
]
const NOMBRES := {"puntos": "PUNTOS.EXE", "armas": "ARMAS.EXE", "logros": "LOGROS.EXE", "dosier": "DOSIER.TXT", "noticias": "CANAL8.TV",
	"colecciones": "COLECCION.EXE"}
const TAREAS := {"puntos": "Compra de puntos e intercambio", "armas": "Tienda de armas", "logros": "Logros", "dosier": "Dosier VD-7",
	"noticias": "Noticias de Canal 8", "colecciones": "Colecciones y bestiario"}
# [/traducir]
# Las secciones de armas de la tienda: [familia (Armas.familia), título]. Las especiales, aparte (como sus piezas),
# aunque van en el hueco de las de A distancia. Debajo, los arrojables
# [traducir]
const SECCIONES := [
	["cuerpo", "Cuerpo a cuerpo"],
	["distancia", "A distancia · llenas, y con munición de reserva"],
	["especial", "Especiales · llenas; van en el hueco de las de A distancia"],
]
# [/traducir]
const INVENTARIO := preload("res://scripts/ui/inventario.gd")   # lo que hace cada arrojable (QUE_HACE)
const MESA := preload("res://scripts/mapa/ordenador.gd")   # qué tiene algo nuevo (novedades)
# El rótulo de un icono con algo nuevo (y, en su esquina, un «!» que bota: marca_nuevo)
# [traducir]
const AVISO_ICONO := {"noticias": "Noticias\n¡NUEVAS!", "colecciones": "Colecciones\n¡NUEVO!", "logros": "Logros\n¡COBRAR!"}
# [/traducir]
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
var rama_abierta := "militar"   # en Puntos, la pestaña de la rama del árbol que se ve


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


# El «!» amarillo que bota en la esquina de arriba a la derecha de un icono del escritorio con algo nuevo
func marca_nuevo() -> Label:
	var marca := Label.new()
	marca.text = "!"
	marca.size = Vector2(24, 24)
	marca.position = Vector2(102, 2)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marca.add_theme_color_override("font_color", TINTA)
	marca.add_theme_constant_override("outline_size", 0)
	marca.add_theme_stylebox_override("normal", caja(Tema.AMARILLO, TINTA, 2, 12, 0))
	var bote := marca.create_tween().set_loops()
	bote.tween_property(marca, "position:y", -3.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bote.tween_property(marca, "position:y", 3.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return marca


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
	iconos.add_theme_constant_override("separation", 1)
	pantalla.add_child(iconos)
	var nuevos: Array = MESA.novedades(Guardado.cargar())   # una sola vez, para los avisos de los iconos
	for i in ICONOS:
		var b := Button.new()
		b.name = "icono_" + i[0]
		b.flat = true
		b.custom_minimum_size = Vector2(132, 72)
		b.add_theme_stylebox_override("normal", caja(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 4, 2))   # sin el margen grande del tema: caben los 7
		b.add_theme_stylebox_override("hover", caja(Color(1, 1, 1, 0.12), Color(0, 0, 0, 0), 0, 4, 2))
		b.add_theme_stylebox_override("pressed", caja(Color(1, 1, 1, 0.2), Color(0, 0, 0, 0), 0, 4, 2))
		# El dibujo y el rótulo van dentro, no como icono y texto del botón: con el dibujo arriba, Button cuenta
		# una línea de más y los rótulos de dos líneas pedirían 84 de alto (y los 7 ya no cabrían)
		var dentro := VBoxContainer.new()
		dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
		dentro.offset_top = 2
		dentro.offset_bottom = -6   # más hueco abajo: el marco de madera del foco es más grueso que el texto
		dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_theme_constant_override("separation", 0)
		b.add_child(dentro)
		var dibujo := TextureRect.new()
		dibujo.texture = load("res://assets/ui/iconos/%s.png" % i[1])
		dibujo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		dibujo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(dibujo)
		var rotulo := Label.new()
		rotulo.name = "rotulo_" + i[0]
		rotulo.text = Idioma.t(i[2])
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rotulo.add_theme_constant_override("line_spacing", 0)
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(rotulo)
		var programa: String = i[0]
		if programa in nuevos:
			rotulo.text = Idioma.t(AVISO_ICONO[programa])
			rotulo.add_theme_color_override("font_color", Tema.AMARILLO)
			b.add_child(marca_nuevo())
		b.pressed.connect(func():
			if programa == "apagar":
				apagar()
			else:
				abrir(programa))
		# el marco de madera sigue al ratón (solo con el escritorio a la vista: con un programa abierto, el foco es suyo)
		b.mouse_entered.connect(func():
			if abierta == "":
				b.grab_focus())
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
	marca.text = Idioma.t("ConserjeOS")
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
	nombre.text = Idioma.t("CONSERJE  OS 95")
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
	# Al volver a abrir el mismo programa (tras comprar o subir algo), cada desplazamiento se queda donde estaba
	var desplazados := []
	if ventana:
		if programa == antes:
			desplazados = ventana.find_children("*", "ScrollContainer", true, false).map(func(d): return d.scroll_vertical)   # no-tr
		ventana.queue_free()
		ventana = null
	tarea.text = Idioma.t(TAREAS.get(programa, ""))
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
	elif programa == "colecciones":
		programa_colecciones(contenido)
	else:
		programa_armas(contenido)
	var marcado: Control = contenido.find_child(foco, true, false) if foco != "" else null
	if marcado == null:
		marcado = primer_boton(contenido)
	if marcado:
		marcar(marcado, foco != "", desplazados)


# Marca el botón (en el mismo instante de siempre: así el aviso que pone después, como «¡Compra hecha!», le gana a la
# explicación del botón) y deja los desplazamientos de la ventana en su sitio. Si se marca nada más montarla, los
# desplazamientos siguen al foco con la ventana a medio colocar y se abren bajados (Puntos a medias; Armas y Logros, hasta
# el fondo): por eso no siguen al foco hasta pasado un fotograma, cuando ya está todo en su sitio. Entonces cada uno
# vuelve a donde estaba (arriba, la primera vez) y, solo si se pidió un botón concreto, se asegura de que se vea
func marcar(boton: Control, concreto: bool, desplazados: Array) -> void:
	var esta := ventana
	var deslizas: Array = esta.find_children("*", "ScrollContainer", true, false)   # no-tr
	for d: ScrollContainer in deslizas:
		d.follow_focus = false
	boton.grab_focus.call_deferred()
	await get_tree().process_frame
	if not is_instance_valid(esta) or ventana != esta:
		return   # (se ha cerrado o abierto otro programa mientras tanto)
	for i in range(deslizas.size() - 1, -1, -1):   # del de más dentro al de más fuera
		var d: ScrollContainer = deslizas[i]
		d.scroll_vertical = desplazados[i] if i < desplazados.size() else 0
		if concreto and d.is_ancestor_of(boton):
			d.ensure_control_visible(boton)
		d.follow_focus = true   # (con el teclado o el mando, bajar por las tarjetas sí lo sigue)


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
	titulo.text = Idioma.t("C:\\MANTENIMIENTO\\%s") % Idioma.t(NOMBRES[programa])
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
	contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL   # llena la ventana: un programa puede repartirse el hueco
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
	var cambio := grupo(c, Idioma.t("Intercambio · $%d = 1 punto") % Talentos.PRECIO_PUNTO)
	var botones := rejilla(cambio)
	var uno := tarjeta(botones, "b_comprar_1", "billete", Idioma.t("Comprar 1 punto"), Idioma.t("Cuesta $%d") % Talentos.PRECIO_PUNTO,
		Idioma.t("Cambiar"), "" if alcanzables >= 1 else "bloqueada")
	enlazar(uno, Idioma.t("Cambia $%d por 1 punto de talento") % Talentos.PRECIO_PUNTO, comprar.bind(1))
	var todo := tarjeta(botones, "b_comprar_todo", "billete",
		Idioma.t("Comprar %d puntos (todo)") % alcanzables if alcanzables > 1 else Idioma.t("Comprar todo lo posible"),
		Idioma.t("Cuesta $%d") % (alcanzables * Talentos.PRECIO_PUNTO) if alcanzables >= 1 else Idioma.t("Necesitas $%d") % Talentos.PRECIO_PUNTO,
		Idioma.t("Cambiar"), "" if alcanzables >= 1 else "bloqueada")
	enlazar(todo, Idioma.t("Cambia todos los dólares que puedas por puntos ($%d = 1 punto)") % Talentos.PRECIO_PUNTO,
		func(): comprar(maxi(1, Guardado.cargar().dolares / Talentos.PRECIO_PUNTO)))
	var arbol := grupo(c, Idioma.t("Árbol de talentos · cada punto sube un nivel"))
	# Una pestaña por rama (con tres, una al lado de otra no cabían): la abierta, hundida y en verde, y debajo su árbol
	var pestanas := HBoxContainer.new()
	pestanas.add_theme_constant_override("separation", 6)
	arbol.add_child(pestanas)
	for rama in Talentos.RAMAS:
		var puestos := 0
		var total := 0
		for t in Talentos.LISTA:
			if t.rama == rama.id:
				puestos += Talentos.nivel_de(s, t.id)
				total += t.max
		var b := tarjeta(pestanas, "b_rama_" + rama.id, rama.icono, Talentos.nombre_rama(rama.id), Idioma.t("%d de %d") % [puestos, total], "",
			"puesta" if rama.id == rama_abierta else "")
		enlazar(b, Idioma.t("Rama %s: %d de sus %d puntos puestos. Pulsa para ver su árbol.") % [Talentos.nombre_rama(rama.id), puestos, total],
			ver_rama.bind(rama.id))
	for rama in Talentos.RAMAS:
		if rama.id == rama_abierta:
			arbol.add_child(montar_rama(s, rama))
	info.text = Idioma.t("Cada punto sube un nivel. Para pasar al nivel siguiente, llena antes el talento que pide.")


func ver_rama(id: String) -> void:
	rama_abierta = id
	abrir("puntos", "b_rama_" + id)


# Lo ahorrado (y, en la de puntos, los puntos): cajas azules hundidas, como .pc-saldo del JS
func saldo(c: VBoxContainer, s: Dictionary) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	c.add_child(fila)
	cajita(fila, Idioma.t("Dólares ahorrados"), "billete", "$%d" % s.dolares)
	if abierta == "puntos":
		cajita(fila, Idioma.t("Puntos de talento"), "trofeo", "%d" % s.puntos)


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
		nota(c, Idioma.t("Los $%d de esta partida se guardan al acabarla: todos si completas el edificio, la mitad si caes.") % partida.dolares)


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


# Una rama del árbol (.pc-rama): su título en azul y, debajo, sus niveles (1 arriba, 5 abajo), cada uno con su
# número a la izquierda y sus talentos en dos columnas
func montar_rama(s: Dictionary, rama: Dictionary) -> VBoxContainer:
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 5)
	var titulo := PanelContainer.new()
	titulo.add_theme_stylebox_override("panel", caja(AZUL, AZUL, 0, 0, 4))
	columna.add_child(titulo)
	titulo.add_child(Tema.icono_y_texto(rama.icono, Talentos.nombre_rama(rama.id), 24))
	for nivel in range(1, 6):
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
		var lista := rejilla(fila)
		lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for t in Talentos.LISTA:
			if t.rama == rama.id and t.nivel == nivel:
				nodo_talento(lista, s, t)
	return columna


func nodo_talento(lista: Container, s: Dictionary, t: Dictionary) -> void:
	var n := Talentos.nivel_de(s, t.id)
	var motivo := Talentos.motivo(s, t.id)
	var estado: String = {"max": "lleno", "bloqueado": "bloqueada", "sin_puntos": "apagada"}.get(motivo, "")
	# debajo del nombre: con algún punto puesto, lo que da ahora y lo que daría el siguiente (Talentos.efecto); sin
	# ninguno, lo que hace cada punto
	var ahora := Talentos.efecto(t.id, n)
	var debajo: String = Talentos.desc_de(t.id)
	var faltan := Talentos.nombres(Talentos.faltan(s, t.id))   # (los del nivel 5 piden tres: solo salen los que faltan)
	if motivo == "bloqueado":
		debajo = Idioma.t("Necesitas %s al máximo") % faltan
	elif motivo == "max":
		debajo = Idioma.t("¡Al máximo! %s") % ahora if ahora != "" else Idioma.t("¡Al máximo!")
	elif n > 0 and ahora != "":
		debajo = Idioma.t("Ahora: %s · Con otro: %s") % [ahora, Talentos.efecto(t.id, n + 1)]
	var etiqueta := Idioma.t("MÁX") if motivo == "max" else ("" if motivo == "bloqueado" else "+1")
	var b := tarjeta(lista, "b_" + t.id, "candado" if motivo == "bloqueado" else t.icono, Talentos.nombre_de(t.id), debajo, etiqueta,
		estado, [n, t.max])
	var texto: String = Talentos.desc_de(t.id)
	match motivo:
		"bloqueado": texto = Idioma.t("Necesitas %s al máximo. %s") % [faltan, texto]
		"max": texto = Idioma.t("¡Al máximo! %s") % texto
		"sin_puntos": texto = Idioma.t("%s. Te hace falta 1 punto.") % texto
		"": texto = Idioma.t("%s. Pulsa para subirlo (1 punto).") % texto
	enlazar(b, texto, subir.bind(t.id))


func comprar(n: int) -> void:
	var s := Talentos.comprar_puntos(n)
	if s.is_empty():
		info.text = Idioma.t("No te llega: cada punto cuesta $%d de lo ahorrado.") % Talentos.PRECIO_PUNTO
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	partida.ahorrados = s.dolares   # el HUD enseña lo ahorrado más lo de esta partida
	abrir("puntos", "b_comprar_1" if s.dolares >= Talentos.PRECIO_PUNTO else "")
	# (el español pone «puntos» también con 1, como siempre; el inglés sí distingue)
	info.set_deferred("text", Idioma.n("¡Hecho! Ahora tienes %d puntos para gastar.", "¡Hecho! Ahora tienes %d puntos para gastar.", s.puntos) % s.puntos)   # después de marcar el botón (que pone su explicación)


func subir(id: String) -> void:
	var motivo := Talentos.motivo(Guardado.cargar(), id)
	if motivo != "":
		Sonido.tocar("no")
		return   # la línea de info ya dice por qué no se puede
	Sonido.tocar("compra")
	var s := Talentos.subir(id)
	partida.aplicar_talentos(s.talentos)
	rama_abierta = Talentos.talento(id).rama   # (si se sube desde fuera, como en las pruebas, que se vea)
	abrir("puntos", "b_" + id)
	info.set_deferred("text", Idioma.t("¡%s sube a %d/%d!") % [Talentos.nombre_de(id), Talentos.nivel_de(s, id), Talentos.talento(id).max])   # después de marcar el botón (que pone su explicación)


# ── Tienda de armas ──

func programa_armas(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	saldo(c, s)
	nota(c, Idioma.t("Se venden en calidad Normal. Lo que llevas encima se pierde si caes: guárdalo en el baúl del taller (al completar el edificio, va solo). Llevas dos de cada tipo: la que tenías en la mano pasa al repuesto y, si ya tienes una de repuesto, se queda en el suelo."))
	nota_partida(c)
	var ids := Armas.PRECIOS.keys()
	ids.sort_custom(func(a, b): return Armas.PRECIOS[a] < Armas.PRECIOS[b])
	for seccion in SECCIONES:
		var lista := rejilla(grupo(c, seccion[1]))
		for id in ids:
			if Armas.familia(id) != seccion[0]:
				continue
			var w: Dictionary = Armas.DATOS[id]
			var precio: int = Armas.PRECIOS[id]
			var lleva: bool = partida.johnny.huecos[w.tipo] == id
			var etiqueta := Idioma.t("LA LLEVAS") if lleva else (Idioma.t("GRATIS") if precio == 0 else "$%d" % precio)
			var estado := "puesta" if lleva else ("" if s.dolares >= precio else "bloqueada")
			var b := tarjeta(lista, "b_" + id, id, Armas.nombre(id), resumen_corto(w), etiqueta, estado)
			enlazar(b, resumen(w), comprar_arma.bind(id))
	# los arrojables, de uno en uno: «AL MÁXIMO» (en verde) si ya no le cabe ninguno más (sus montones llenos y sin hueco
	# para otro: lanzables.cabe)
	var lz: Lanzables = partida.lanzables
	var lista := rejilla(grupo(c, Idioma.t("Arrojables · de uno en uno, hasta los que caben")))
	for k in Lanzables.PRECIOS:
		var precio: int = Lanzables.PRECIOS[k]
		var lleno := not lz.cabe(k)
		var estado := "lleno" if lleno else ("" if s.dolares >= precio and not Reto.sin_municion() else "bloqueada")
		var b := tarjeta(lista, "b_" + k, k, Lanzables.uno(k), Idioma.t("Llevas %d") % lz.total(k),
			Idioma.t("AL MÁXIMO") if lleno else "$%d" % precio, estado)
		var que: String = Idioma.t(INVENTARIO.QUE_HACE[k])
		enlazar(b, Idioma.t("%s: %s Cada uno, $%d.") % [Lanzables.uno(k), que[0].to_lower() + que.substr(1), precio],
			comprar_lanzable.bind(k))
	info.text = Idioma.t("Elige un arma: se paga con los dólares ahorrados.")


# Debajo del nombre, como weaponSummary del JS pero sin el tipo (ya lo dice su sección): "Daño 9 · 4 ataques/s" (el
# lanzallamas, el lanza ácido y el lanza rayos, su daño por segundo y su depósito)
func resumen_corto(w: Dictionary) -> String:
	if w.has("deposito"):
		return Idioma.t("Daño %d/s · Depósito %d s") % [w.dano, roundi(w.deposito)]
	var dano := "%d × %d" % [w.dano, w.perdigones] if w.get("perdigones", 1) > 1 else str(w.dano)
	# (cada dato es un texto entero y se unen con « · »: así cada idioma ordena y escribe el suyo)
	var partes := [Idioma.t("Daño %s") % dano, Idioma.t("%s ataques/s") % str(w.ritmo).trim_suffix(".0")]
	if w.tipo == "fuego":
		partes.append(Idioma.t("Cargador %d") % w.cargador)
	return " · ".join(PackedStringArray(partes))


# La línea de abajo: sus números y, las que se llenan con un objeto de la mochila, con cuál
func resumen(w: Dictionary) -> String:
	var nombre := Idioma.t(w.nombre)
	var con: String = Armas.relleno_uno(w.relleno) if w.has("relleno") else ""   # con qué se llena (un objeto de la mochila)
	if w.has("deposito"):
		var chorro := Idioma.t("rayo continuo") if w.get("efecto", "") == "rayo" else Idioma.t("chorro continuo")
		if con != "":
			return Idioma.t("%s: daño %d por segundo, %s, depósito de %d s que se llena con %s.") % [nombre, w.dano, chorro, roundi(w.deposito), con]
		return Idioma.t("%s: daño %d por segundo, %s, depósito de %d s.") % [nombre, w.dano, chorro, roundi(w.deposito)]
	# lo demás, una lista de datos separados por comas
	var partes := []
	if w.get("perdigones", 1) > 1:
		partes.append(Idioma.t("daño %d x%d perdigones") % [w.dano, w.perdigones])
	else:
		partes.append(Idioma.t("daño %d") % w.dano)
	partes.append(Idioma.t("%.1f ataques por segundo") % w.ritmo)
	if w.tipo == "fuego":
		if con != "":
			partes.append(Idioma.t("cargador de %d que se llena con %s") % [w.cargador, con])
		else:
			partes.append(Idioma.t("cargador de %d") % w.cargador)
	return "%s: %s." % [nombre, ", ".join(PackedStringArray(partes))]


# El nombre de un arma o arrojable dentro de una frase: en español va en minúscula; en inglés se queda como viene
# (MP5, nombres propios...)
func en_frase(nombre: String) -> String:
	return nombre.to_lower() if Idioma.actual == Idioma.ORIGEN else nombre


func comprar_arma(id: String) -> void:
	var w: Dictionary = Armas.DATOS[id]
	var johnny: Node = partida.johnny
	if johnny.huecos[w.tipo] == id:
		info.text = Idioma.t("Ya llevas %s.") % en_frase(Armas.nombre(id))
		Sonido.tocar("no")
		return
	if partida.repuesto(w.tipo) == id:
		info.text = Idioma.t("Ya llevas %s de repuesto: póntela desde el inventario.") % en_frase(Armas.nombre(id))
		Sonido.tocar("no")
		return
	var s := Guardado.cargar()
	var precio: int = Armas.PRECIOS[id]
	if s.dolares < precio:
		info.text = Idioma.t("No te llega: te faltan $%d.") % (precio - s.dolares)
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	s.dolares -= precio
	if not id in s.armas:
		s.armas.append(id)
	Guardado.escribir(s)
	partida.ahorrados = s.dolares
	var vieja: String = Armas.nombre(johnny.huecos[w.tipo], johnny.calidad(johnny.huecos[w.tipo]))
	var suelo: Dictionary = partida.llevar_arma(id)   # (en Normal: las mejoradas salen del banco y de la joyería)
	abrir("armas", "b_" + id)
	info.set_deferred("text", (Idioma.t("¡Compra hecha! %s a la mano; %s pasa al repuesto.") if suelo.is_empty() else
		Idioma.t("¡Compra hecha! %s a la mano; %s se queda en el suelo: ya llevabas dos.")) % [Armas.nombre(id), vieja])   # después de marcar el botón (que pone su explicación)


# Un arrojable más para esta partida (como cogerlo del suelo: lanzables.sumar), si cabe y le llega
func comprar_lanzable(k: String) -> void:
	var lz: Lanzables = partida.lanzables
	var no := ""
	if Reto.sin_municion():
		no = Idioma.t("En el reto «%s» no se lleva nada que lanzar.") % Reto.nombre("cuerpo")
	elif not lz.cabe(k):
		no = Idioma.t("No te caben más %s: tus montones están llenos y no te queda hueco para otro.") % Lanzables.varios(k)
	var s := Guardado.cargar()
	var precio: int = Lanzables.PRECIOS[k]
	if no == "" and s.dolares < precio:
		no = Idioma.t("No te llega: te faltan $%d.") % (precio - s.dolares)
	if no != "":
		info.text = no
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	s.dolares -= precio
	Guardado.escribir(s)
	partida.ahorrados = s.dolares
	lz.sumar(k)
	abrir("armas", "b_" + k)
	var n := lz.total(k)
	info.set_deferred("text", Idioma.t("¡Compra hecha! Ya llevas %d %s.") % [n, Lanzables.varios(k) if n != 1 else en_frase(Lanzables.uno(k))])


# ── Logros ──

func programa_logros(c: VBoxContainer) -> void:
	partida.logros.revisar()   # (lo que ya llegue por el guardado, como un talento recién comprado, sale conseguido)
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
	cajita(fila, Idioma.t("Logros conseguidos"), "trofeo", "%d / %d" % [hechos, Logros.LISTA.size()])
	cajita(fila, Idioma.t("Premios por cobrar"), "billete", "$%d" % por_cobrar)
	cajita(fila, Idioma.t("Dólares ahorrados"), "billete", "$%d" % s.dolares)
	nota(c, Idioma.t("Elige un reto para esta partida. Al cumplirlo sale un aviso; vuelve aquí a cobrar el premio."))
	if partida.logros.sin_logros():
		nota(c, Idioma.t("Esta partida va con ayudas (Opciones → Ayudas): no se consiguen logros. Los que ya tienes se quedan y puedes cobrarlos."))
	# por apartados (Logros.TEMAS), cada uno con sus tarjetas en dos columnas
	for tema in Logros.TEMAS:
		var lista := rejilla(grupo(c, Logros.nombre_tema(tema)))
		for l in Logros.LISTA.filter(func(x): return x.tema == tema):
			var e := Logros.estado(s, l.id)
			var etiqueta: String = {"pendiente": "$%d" % l.premio, "conseguido": Idioma.t("COBRAR $%d") % l.premio, "cobrado": Idioma.t("HECHO")}[e]
			var meta := Logros.meta(l)
			var hecho: int = meta if e != "pendiente" else mini(partida.logros.progreso(l.id, s), meta)
			var barra: Array = [hecho, meta] if meta > 1 else []
			var b := tarjeta(lista, "b_" + l.id, l.icono, Logros.nombre_de(l.id), Logros.desc_de(l.id), etiqueta,
				{"pendiente": "apagada", "conseguido": "", "cobrado": "lleno"}[e], [], barra)
			enlazar(b, "%s: %s %s" % [Logros.nombre_de(l.id), Logros.desc_de(l.id), explica_logro(l, e, hecho, meta)], cobrar_logro.bind(l.id))
	info.text = Idioma.t("Pasa por encima de un logro para ver cómo vas.")


# Lo que dice la línea de abajo de un logro (e: su estado; hecho y meta: cuánto lleva), cada caso en una frase entera
func explica_logro(l: Dictionary, e: String, hecho: int, meta: int) -> String:
	if e == "conseguido":
		return Idioma.t("¡Conseguido! Pulsa para cobrar $%d.") % l.premio
	if e == "cobrado":
		return Idioma.t("Conseguido y cobrado.")
	if meta <= 1:
		return Idioma.t("Premio: $%d. Aún no lo has conseguido.") % l.premio
	match l.cuenta:   # (de dónde sale la cuenta: de una sola partida o sumando todas)
		"partida": return Idioma.t("Premio: $%d. Llevas %d de %d (en una partida).") % [l.premio, hecho, meta]
		"total": return Idioma.t("Premio: $%d. Llevas %d de %d (sumando partidas).") % [l.premio, hecho, meta]
	return Idioma.t("Premio: $%d. Llevas %d de %d.") % [l.premio, hecho, meta]


func cobrar_logro(id: String) -> void:
	var dinero := Logros.cobrar(id)
	if dinero == 0:
		Sonido.tocar("no")
		return
	Sonido.tocar("compra")
	partida.ahorrados = Guardado.cargar().dolares
	abrir("logros", "b_" + id)
	info.set_deferred("text", Idioma.t("¡Cobrados $%d! Ya puedes gastarlos en puntos o armas.") % dinero)


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
	cajita(fila, Idioma.t("Dosier VD-7"), "dosier", Idioma.t("%d / %d páginas") % [halladas, total])
	nota(c, Idioma.t("Cada página que encuentres, en cualquier edificio y en cualquier planta, queda aquí para siempre."))
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
		var nombre: String = Idioma.t(Edificios.datos(edificio).nombre) if edificio in Edificios.LISTA else edificio
		var del_edificio := grupo(lista, "%s · %d / %d" % [nombre, suyas, d.paginas.size()])
		for i in d.paginas.size():
			var p: Dictionary = d.paginas[i]
			var tiene := Historia.encontrada(s, p.id)
			var b := tarjeta(del_edificio, "b_" + p.id, "dosier" if tiene else "candado", Idioma.t("Página %d") % (i + 1),
				Historia.titulo_de(p) if tiene else Idioma.t("Arrancada"), "", "" if tiene else "bloqueada")
			var ver := func():
				for h in lado.get_children():
					h.queue_free()
				lado.add_child(Historia.hoja(p, 410.0) if tiene else Historia.hoja_arrancada(edificio, p, 410.0))
			enlazar(b, (Idioma.t("%s, página %d: %s. La llevaba %s.") % [nombre, i + 1, Historia.titulo_de(p), Historia.cuerpo_de(p)]) if tiene
				else Idioma.t("%s, página %d: aún no la has encontrado (%s).") % [nombre, i + 1, Historia.donde(p)], ver)
			b.focus_entered.connect(ver)
			b.mouse_entered.connect(ver)
	info.text = Idioma.t("Pasa por las páginas para leerlas.")


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
		var b := tarjeta(lista, "b_" + n.id, "noticias" if sale else "candado", Idioma.t("Emisión %d") % (i + 1),
			Historia.titular_de(n) if sale else Idioma.t("Sin emitir"), Idioma.t("¡NUEVA!") if nueva else "", "" if sale else "bloqueada")
		if not sale:
			var pista := (Idioma.t("Completa %s.") % Idioma.t(Edificios.datos(n.victoria).el_nombre)) if n.victoria != "" else Idioma.t("Sigue buscando páginas del dosier VD-7.")
			enlazar(b, Idioma.t("Emisión %d: aún no ha salido. %s") % [i + 1, pista], Sonido.tocar.bind("no"))
			continue
		ultima = "b_" + n.id
		if nueva and primera_nueva == "":
			primera_nueva = ultima
		var ver := func():
			if tele.noticia != n:
				tele.poner(n)
				Historia.ver_noticia(n.id)
		enlazar(b, Idioma.t("Emisión %d: «%s». Pulsa para saltar o repetir.") % [i + 1, Historia.titular_de(n)], tele.saltar)
		b.focus_entered.connect(ver)
		b.mouse_entered.connect(ver)
	info.text = Idioma.t("%s, con %s. Pasa por las emisiones para verlas.") % [Historia.canal(), Historia.REPORTERA]
	if foco != "":
		return foco
	return primera_nueva if primera_nueva != "" else ultima


# ── Colecciones ──

# Lo que se ha encontrado y visto alguna vez, de todos los edificios (Guardado: "encontrados" y "bestiario").
# Arriba, las cuentas totales; a la izquierda, por edificio, dos fichas (objetos y páginas del dosier) con su barra, y
# el bestiario con una ficha por enemigo; a la derecha, lo que se esté mirando: la rejilla de objetos, las páginas,
# o el dibujo del enemigo (en silueta si no se ha visto)
func programa_colecciones(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	if s.colecciones_nuevo:
		# ya está visto: el aviso del icono se quita hasta que haya algo nuevo
		s = Guardado.cambiar(func(g): g.colecciones_nuevo = false)
		var rotulo: Label = iconos.find_child("rotulo_colecciones", true, false)
		if rotulo:
			rotulo.text = Idioma.t("Colecciones")
			rotulo.remove_theme_color_override("font_color")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	c.add_child(fila)
	cajita(fila, Idioma.t("Objetos"), "mochila", "%d / %d" % [cuantos(Objetos.NOMBRES.keys(), s.encontrados), Objetos.NOMBRES.size()])
	var vistos := cuantos(Bestiario.LISTA.keys(), s.bestiario)
	cajita(fila, Idioma.t("Bestiario"), "zombi", "%d / %d" % [vistos, Bestiario.LISTA.size()])
	# la lista y el visor se quedan con el hueco que dejan las cajas (con un alto fijo, el contenido se pasaba unos
	# píxeles y la ventana se desplazaba al marcar una ficha, tapando las cajas)
	var partes := HBoxContainer.new()
	partes.add_theme_constant_override("separation", 10)
	partes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(partes)
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.follow_focus = true
	desliza.custom_minimum_size = Vector2(240, 200)
	desliza.size_flags_vertical = Control.SIZE_EXPAND_FILL
	partes.add_child(desliza)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	desliza.add_child(lista)
	var lado := CenterContainer.new()
	lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lado.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	partes.add_child(lado)

	for ed in Edificios.LISTA:
		var nombre: String = Idioma.t(Edificios.datos(ed).nombre)
		var paginas: Array = Historia.dosier(ed).paginas
		# [ficha, icono, título, cuántos, de cuántos, la frase de la línea de abajo (nombre, cuántos y de cuántos)]
		var fichas := [
			["objetos", "mochila", Idioma.t("Objetos"), cuantos(Objetos.de_edificio(ed), s.encontrados), Objetos.de_edificio(ed).size(),
				Idioma.t("%s: %d de %d objetos encontrados.")],
			["dosier", "dosier", Idioma.t("Dosier"), paginas.filter(func(p): return Historia.encontrada(s, p.id)).size(), paginas.size(),
				Idioma.t("%s: %d de %d páginas del dosier.")],
		]
		fichas = fichas.filter(func(f): return f[4] > 0)
		var hecho := 0
		var meta := 0
		for f in fichas:
			hecho += f[3]
			meta += f[4]
		var del_edificio := grupo(lista, "%s · %d %%" % [nombre, roundi(100.0 * hecho / maxi(meta, 1))])
		for f in fichas:
			var cual: String = f[0]
			var clave := "c_%s_%s" % [ed, cual]
			var b := tarjeta(del_edificio, clave, f[1], f[2], "%d / %d" % [f[3], f[4]], "",
				"lleno" if f[4] > 0 and f[3] >= f[4] else "", [], [f[3], f[4]] if f[4] > 0 else [])
			var hacer := ficha_edificio.bind(s, ed, cual)
			var ver := func(): mostrar(lado, clave, hacer)
			enlazar(b, f[5] % [nombre, f[3], f[4]], ver)
			b.focus_entered.connect(ver)
			b.mouse_entered.connect(ver)

	var del_bestiario := grupo(lista, Idioma.t("Bestiario · %d / %d") % [vistos, Bestiario.LISTA.size()])
	for id: String in Bestiario.LISTA:
		var d: Dictionary = Bestiario.LISTA[id]
		var visto := Bestiario.visto(s, id)
		var clave := "z_" + id
		var b := tarjeta(del_bestiario, clave, "jefe" if d.get("jefe", false) else "zombi", Bestiario.nombre(id) if visto else "???",
			sale_en(d) if visto else Idioma.t("Sin ver"), "", "" if visto else "bloqueada")
		var hacer := ficha_bestiario.bind(id, visto)
		var ver := func(): mostrar(lado, clave, hacer)
		enlazar(b, (Idioma.t("%s: sale en %s.") % [Bestiario.nombre(id), sale_en(d, true)]) if visto
			else Idioma.t("Un enemigo que aún no te has cruzado. Los que veas en una partida se apuntan aquí."), ver)
		b.focus_entered.connect(ver)
		b.mouse_entered.connect(ver)
	info.text = Idioma.t("Lo que encuentras o te cruzas queda aquí para siempre. Pasa por las fichas para verlo.")


# Cuántos de estos ids están ya en una lista del guardado
func cuantos(ids: Array, tenidos: Array) -> int:
	return ids.filter(func(id): return id in tenidos).size()


# Dónde sale un enemigo: corto para las fichas ("Apartamentos y centro") o con artículo para las frases
func sale_en(d: Dictionary, con_articulo := false) -> String:
	var eds: Array = d.edificios
	if con_articulo:
		# «los Apartamentos y el Centro comercial»: de uno en uno, cada idioma pone su «y»
		var texto: String = Idioma.t(Edificios.datos(eds[0]).el_nombre)
		for e in eds.slice(1):
			texto = Idioma.t("%s y %s") % [texto, Idioma.t(Edificios.datos(e).el_nombre)]
		return texto
	return Idioma.t("Apartamentos y centro") if eds.size() > 1 else Idioma.t(Edificios.datos(eds[0]).nombre)


# Pone una ficha en el visor de la derecha. Si ya es la que está, nada (el foco y el ratón la piden a la vez).
# "hacer" la construye, solo entonces: las rejillas de iconos no se montan hasta que se miran
func mostrar(lado: CenterContainer, clave: String, hacer: Callable) -> void:
	if lado.get_meta("ficha", "") == clave:
		return
	lado.set_meta("ficha", clave)
	# si el foco (el mando) estaba dentro del visor y el ratón pide otra ficha, que no se pierda: pasa a la ficha
	# nueva o, si esa no tiene botones, a su tarjeta de la lista
	var foco := get_viewport().gui_get_focus_owner()
	var dentro := foco != null and lado.is_ancestor_of(foco)
	for h in lado.get_children():
		lado.remove_child(h)
		h.queue_free()
	var ficha: Control = hacer.call()
	lado.add_child(ficha)
	if dentro:
		var b: Control = primer_boton(ficha)
		if b == null:
			b = ventana.find_child(clave, true, false)
		if b:
			b.grab_focus()


# La ficha de un edificio en el visor: sus objetos (una rejilla de casillas, apagadas las que faltan) o sus páginas
# del dosier (solo los títulos: se leen en DOSIER.TXT)
func ficha_edificio(s: Dictionary, ed: String, cual: String) -> Control:
	var nombre: String = Idioma.t(Edificios.datos(ed).nombre)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	if cual == "dosier":
		var paginas: Array = Historia.dosier(ed).paginas
		var halladas := paginas.filter(func(p): return Historia.encontrada(s, p.id)).size()
		var l := texto_tarjeta(Idioma.t("%d de %d páginas de %s. Léelas en DOSIER.TXT.") % [halladas, paginas.size(), nombre], TINTA)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 400
		columna.add_child(l)
		for i in paginas.size():
			if Historia.encontrada(s, paginas[i].id):
				columna.add_child(texto_tarjeta(Idioma.t("Página %d · %s") % [i + 1, Historia.titulo_de(paginas[i])], TINTA_SUAVE))
		return columna
	columna.add_child(texto_tarjeta(Idioma.t("Objetos · %s") % nombre, TINTA))
	var casillas := GridContainer.new()
	casillas.columns = 6
	casillas.add_theme_constant_override("h_separation", 4)
	casillas.add_theme_constant_override("v_separation", 4)
	columna.add_child(casillas)
	for id in Objetos.de_edificio(ed):
		var tiene: bool = id in s.encontrados
		var b := casilla(casillas, "o_" + id, "obj-" + id, tiene)
		enlazar(b, ("%s · %s" if tiene else Idioma.t("%s (sin encontrar) · %s")) % [Objetos.nombre(id), Objetos.donde(id, ed)], func(): pass)
	return columna


# Una casilla de la rejilla de objetos: un botón de 52 × 52 con el icono a 32 × 32; apagado si aún no se tiene. Se
# marca (el mando entra en la rejilla) pero no hace nada al pulsarlo: solo explica en la línea de abajo
func casilla(padre: Container, nombre: String, icono: String, tiene: bool) -> Button:
	var b := Button.new()
	b.name = nombre
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_stylebox_override("normal", caja(TARJETA, TARJETA, 0, 0, 0))
	for e in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(e, caja(TARJETA_LUZ, TINTA, 2, 0, 0))
	padre.add_child(b)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(centro)
	var imagen := TextureRect.new()
	imagen.texture = load("res://assets/ui/iconos/%s.png" % icono)
	imagen.custom_minimum_size = Vector2(32, 32)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not tiene:
		imagen.modulate = Color(1, 1, 1, 0.35)   # apagado, como las tarjetas "bloqueada"
	centro.add_child(imagen)
	return b


# La ficha de un enemigo en el visor: su dibujo de frente al tamaño del juego (en silueta si no se ha visto), su
# nombre, dónde sale y su frase
func ficha_bestiario(id: String, visto: bool) -> Control:
	var d: Dictionary = Bestiario.LISTA[id]
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	var retrato := TextureRect.new()
	retrato.texture = Bestiario.retrato(id)
	# cada píxel del dibujo, "escala" en pantalla (como en el juego); los más altos (el gerente y su mutación), a 1,
	# para que quepan con el nombre y la frase
	var escala: int = d.escala
	if retrato.texture.get_size().y * escala > 220:
		escala = 1
	retrato.custom_minimum_size = retrato.texture.get_size() * escala
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_SCALE
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not visto:
		retrato.modulate = Color(0, 0, 0, 0.85)   # la silueta
	columna.add_child(retrato)
	var nombre := texto_tarjeta(Bestiario.nombre(id) if visto else "???", TINTA)
	nombre.add_theme_font_size_override("font_size", 32)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(nombre)
	var donde := texto_tarjeta(Idioma.t("Sale en: %s") % (sale_en(d) if visto else "???"), TINTA_SUAVE)
	donde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(donde)
	var frase := texto_tarjeta(Bestiario.frase(id) if visto else Idioma.t("Aún no te lo has cruzado."), TINTA)
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.custom_minimum_size.x = 420
	frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(frase)
	return columna


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
