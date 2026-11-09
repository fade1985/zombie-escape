# El ordenador de la sala de mantenimiento, "ConserjeOS" (src/ordenador.js del JS). Al arrimarse a la mesa
# (mapa/ordenador.gd) el juego se pausa y sale la pantalla: un monitor viejo con su escritorio, sus iconos, la
# barra de tareas con el reloj y una ventana para cada programa:
#   - "Talentos": el árbol de talentos (arbol_talentos.gd), con las tres ramas a la vez; cada punto se compra en su
#     talento con los dólares ahorrados (talentos.gd). Lo comprado se nota al momento.
#   - "Tienda de armas": compra con los dólares ahorrados un arma (Armas.PRECIOS), en calidad Normal (parte 4 de la
#     tienda y las piezas: Armas.CALIDADES), y queda desbloqueada en el guardado. Va a la mano, y la que llevaras de ese tipo pasa al repuesto o, si ya
#     tienes una de repuesto, esa va al baúl en el momento (partida.repuesto_al_baul; si no cabe o no se puede
#     guardar, la de la mano se queda en el suelo: partida.llevar_arma, dos de cada tipo como mucho). Desde el
#     25 oct también vende el lanzallamas, el lanza ácido y el lanza rayos, que antes se creaban en el banco.
#     Todo a la vez en una chapa oscura, con la ficha de lo elegido a la derecha (tienda_armas.gd). Cuatro grupos,
#     las familias de las piezas (Armas.familia): Cuerpo a cuerpo, A distancia, Especiales y
#     Arrojables. Los arrojables (Lanzables.PRECIOS) se compran de uno en uno, mientras quepan (van a sus montones de
#     5); los que sobren al completar el edificio van al baúl.
#   - "Logros": los retos del juego (logros.gd), para elegir cuál intentar en esta partida. En la chapa oscura, como un
#     archivador (archivador_logros.gd): a la izquierda, el Resumen y un apartado por tema (Logros.TEMAS); a la
#     derecha, la página elegida. Los conseguidos se cobran aquí (su premio va a los dólares ahorrados).
#   - "Dosier": las páginas del dosier VD-7 encontradas junto a los científicos muertos (historia.gd), de todos
#     los edificios, para releerlas. Una carpeta de archivo con una pestaña por edificio (carpeta_dosier.gd): las
#     páginas como fichas a la izquierda y la hoja a la derecha. Las que faltan salen como páginas arrancadas.
#   - "Noticias": las emisiones de Canal 8 ya salidas (historia.gd), en una tele vieja (ui/tele.gd). Las que no se
#     han visto llevan "¡NUEVA!" (y el icono del escritorio avisa).
#   - "Colecciones": el bestiario (bestiario.gd): cada enemigo visto alguna vez, por familias, con su dibujo, su
#     frase y cuántos se han matado. Queda entre partidas; el icono avisa si hay algo nuevo.
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
	["puntos", "escritorio-talentos", "Talentos"],   # (por dentro se sigue llamando "puntos": antes se compraban puntos de talento)
	["armas", "escritorio-armas", "Tienda\nde armas"],
	["logros", "escritorio-logros", "Logros"],
	["dosier", "escritorio-dosier", "Dosier\nVD-7"],
	["noticias", "noticias", "Noticias"],
	["colecciones", "escritorio-colecciones", "Colecciones"],
	["apagar", "escritorio-apagar", "Apagar"],
]
const NOMBRES := {"puntos": "TALENTOS.EXE", "armas": "ARMAS.EXE", "logros": "LOGROS.EXE", "dosier": "DOSIER.TXT", "noticias": "CANAL8.TV",
	"colecciones": "COLECCION.EXE"}
const TAREAS := {"puntos": "Árbol de talentos", "armas": "Tienda de armas", "logros": "Logros", "dosier": "Dosier VD-7",
	"noticias": "Noticias de Canal 8", "colecciones": "Sujetos"}
# [/traducir]
const INVENTARIO := preload("res://scripts/ui/inventario.gd")   # lo que hace cada arrojable (QUE_HACE)
const ARBOL := preload("res://scripts/ui/arbol_talentos.gd")   # el árbol de talentos (TALENTOS.EXE)
const TIENDA := preload("res://scripts/ui/tienda_armas.gd")   # la tienda de armas (ARMAS.EXE)
const ARCHIVADOR := preload("res://scripts/ui/archivador_logros.gd")   # los logros (LOGROS.EXE)
const CARPETA_DOSIER := preload("res://scripts/ui/carpeta_dosier.gd")   # el dosier (DOSIER.TXT)
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
var iconos: Control         # los botones del escritorio, colocados a mano (Noticias, sola arriba a la derecha)
var colocando := false   # marcar: la ventana recién rehecha aún se está colocando, y lo que hay bajo el ratón no es lo que se ve
var ventana: Control
var info: Label             # la línea de abajo de la ventana: explica lo que está marcado
var tarea: Label
var reloj: Label
var abierta := ""           # el programa abierto ("" = solo el escritorio)
var aviso: Control               # en Talentos, la ventanita de «¿Seguro?» al resetear (M32); null = no está


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
func marca_nuevo() -> TextureRect:
	var marca := TextureRect.new()
	marca.name = "marca_nuevo"   # no-tr
	# el «!» de GPT, de amarillo a naranja (M3; el mismo que en los apartados de Logros)
	marca.texture = load("res://assets/ui/exclamacion-pequena.png")
	marca.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marca.size = Vector2(24, 24)
	marca.position = Vector2(102, 2)
	marca.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bote := marca.create_tween().set_loops()
	bote.tween_property(marca, "position:y", -3.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bote.tween_property(marca, "position:y", 3.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return marca


# Pone o quita el aviso de un icono del escritorio ("icono": su fila de ICONOS): el rótulo en amarillo y el «!» que bota
func poner_aviso(b: Button, icono: Array, nuevo: bool) -> void:
	var programa: String = icono[0]
	var rotulo: Label = b.find_child("rotulo_" + programa, true, false)
	var marca := b.get_node_or_null("marca_nuevo")
	if nuevo:
		rotulo.text = Idioma.t(AVISO_ICONO[programa])
		rotulo.add_theme_color_override("font_color", Tema.AMARILLO)
		if marca == null:
			b.add_child(marca_nuevo())
	else:
		rotulo.text = Idioma.t(icono[2])
		rotulo.remove_theme_color_override("font_color")
		if marca:
			b.remove_child(marca)
			marca.queue_free()


# Pone al día los avisos de los iconos con lo que dice el guardado ahora: así se quitan en cuanto se mira o se cobra lo
# nuevo, sin tener que apagar el ordenador
func refrescar_avisos() -> void:
	var nuevos: Array = MESA.novedades(Guardado.cargar())
	for i in ICONOS:
		var b := iconos.get_node_or_null("icono_" + i[0]) as Button
		if b:
			poner_aviso(b, i, i[0] in nuevos)


func apagar() -> void:
	if fondo:
		fondo.queue_free()
		fondo = null
	abierta = ""
	# el «!» de encima de la mesa lo mira el juego cada segundo, y parado no lo hace: se pone al día al salir
	var mesa: Node2D = partida.mapa.ordenador if partida and partida.mapa else null
	if mesa:
		mesa.get_node("Exclamacion").refrescar()
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

	# los iconos, en columna a la izquierda; Noticias, sola en la esquina de arriba a la derecha (como la tele de una
	# esquina)
	iconos = Control.new()
	iconos.set_anchors_preset(Control.PRESET_FULL_RECT)
	iconos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.add_child(iconos)
	var en_columna := 0
	var nuevos: Array = MESA.novedades(Guardado.cargar())   # al encender; luego los avisos se ponen al día con refrescar_avisos
	for i in ICONOS:
		var b := Button.new()
		b.name = "icono_" + i[0]
		b.flat = true
		b.custom_minimum_size = Vector2(132, 72)
		b.size = b.custom_minimum_size
		if i[0] == "noticias":
			b.position = Vector2(pantalla.custom_minimum_size.x - 10 - 132, 12)
		else:
			b.position = Vector2(10, 12 + en_columna * 73)
			en_columna += 1
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
		poner_aviso(b, i, programa in nuevos)
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
	cerrar_aviso(false)
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
		foco = programa_logros(contenido, foco)
	elif programa == "dosier":
		foco = programa_dosier(contenido, foco)
	elif programa == "noticias":
		foco = programa_noticias(contenido, foco)
	elif programa == "colecciones":
		foco = programa_colecciones(contenido, foco)
	else:
		programa_armas(contenido, foco)
	var marcado: Control = contenido.find_child(foco, true, false) if foco != "" else null
	if marcado == null:
		marcado = primer_boton(contenido)
	if marcado:
		marcar(marcado, foco != "", desplazados)


# Marca el botón (en el mismo instante de siempre: así el aviso que pone después, como «¡Compra hecha!», le gana a la
# explicación del botón) y deja los desplazamientos de la ventana en su sitio. Si se marca nada más montarla, los
# desplazamientos siguen al foco con la ventana a medio colocar y se abren bajados (Puntos a medias; Armas y Logros, hasta
# el fondo): por eso no siguen al foco hasta pasados dos fotogramas, cuando ya está todo en su sitio. Con uno no basta: al
# pulsar con el ratón, el aviso del fotograma puede llegar antes de que se marque el botón, si en ese fotograma no toca
# paso de física (F13 y F14). Cada uno vuelve a donde estaba (arriba, la primera vez) según crece su barra, para que no se
# vea ni un fotograma arriba del todo, y al final, solo si se pidió un botón concreto, se asegura de que se vea
func marcar(boton: Control, concreto: bool, desplazados: Array) -> void:
	var esta := ventana
	var deslizas: Array = esta.find_children("*", "ScrollContainer", true, false)   # no-tr
	var a_su_sitio := []
	colocando = true
	for i in deslizas.size():
		var d: ScrollContainer = deslizas[i]
		d.follow_focus = false
		a_su_sitio.append(func(): d.scroll_vertical = desplazados[i] if i < desplazados.size() else 0)
		d.get_v_scroll_bar().changed.connect(a_su_sitio[i])
	boton.grab_focus.call_deferred()
	await get_tree().process_frame
	await get_tree().process_frame
	colocando = false
	if not is_instance_valid(esta) or ventana != esta:
		return   # (se ha cerrado o abierto otro programa mientras tanto)
	var encadenados := []
	for i in range(deslizas.size() - 1, -1, -1):   # del de más dentro al de más fuera
		var d: ScrollContainer = deslizas[i]
		d.get_v_scroll_bar().changed.disconnect(a_su_sitio[i])
		a_su_sitio[i].call()
		if concreto and d.is_ancestor_of(boton):
			d.ensure_control_visible(boton)
		d.follow_focus = true   # (con el teclado o el mando, bajar por las tarjetas sí lo sigue)
		encadenar(d, encadenados)


# Con el teclado o el mando, Godot solo pasa a un botón que se vea: en una lista con desplazamiento, la marca se atascaba
# al llegar abajo de lo visible y, arriba del todo, se iba a los iconos del escritorio. Por eso cada botón de la lista sabe
# cuál tiene encima y debajo; el primero y el último, él mismo, y no salen de ella (izquierda y derecha, como siempre).
# Las listas sin nada oculto no lo necesitan (y en Colecciones, los botones del visor cambian). "encadenados": los que ya
# van con un desplazamiento de más dentro
func encadenar(desliza: ScrollContainer, encadenados: Array) -> void:
	var botones: Array = desliza.find_children("*", "Button", true, false).filter(func(b):   # no-tr
		return b.focus_mode != Control.FOCUS_NONE and b.is_visible_in_tree() and not b in encadenados)
	encadenados.append_array(botones)
	var barra := desliza.get_v_scroll_bar()
	if barra.max_value <= barra.page:
		return
	for b: Button in botones:
		var encima := vecino(b, botones, -1.0)
		b.focus_neighbor_top = b.get_path_to(encima)
		b.focus_neighbor_bottom = b.get_path_to(vecino(b, botones, 1.0))
		if encima == b:
			b.focus_entered.connect(al_principio.bind(b))


# Al llegar arriba de una lista con el teclado o el mando, que se vea también lo que hay encima de ella (el saldo, los
# títulos): sin ratón no habría otra forma de verlo. Con el ratón, la ventana no se mueve
func al_principio(b: Button) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var d: Node = b.get_parent()
	while d != ventana:
		if d is ScrollContainer:
			d.scroll_vertical = 0
		d = d.get_parent()


# El botón de "botones" más cercano a "b" hacia arriba (-1) o hacia abajo (1), de los que caen en su columna (el que más
# coincida con ella, si hay varios a la misma altura); si en su columna no hay ninguno, el más cercano de la otra (en
# una rejilla de dos con la última fila a medias, para llegar a la tarjeta que queda sola); si no hay ninguno, él mismo
func vecino(b: Button, botones: Array, hacia: float) -> Button:
	var mejor := b
	var menor := INF
	var otro := b            # el más cercano en esa dirección, de cualquier columna
	var menor_otro := INF
	var caja := b.get_global_rect()
	for o: Button in botones:
		var otra := o.get_global_rect()
		var lejos := (otra.get_center().y - caja.get_center().y) * hacia
		var coinciden := minf(otra.end.x, caja.end.x) - maxf(otra.position.x, caja.position.x)
		if lejos > 1.0 and coinciden > 0.0 and lejos - coinciden * 0.001 < menor:
			menor = lejos - coinciden * 0.001
			mejor = o
		var de_lado := absf(otra.get_center().x - caja.get_center().x) * 0.001
		if lejos > 1.0 and lejos + de_lado < menor_otro:
			menor_otro = lejos + de_lado
			otro = o
	return mejor if mejor != b else otro


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
	if programa == "dosier" or programa == "colecciones":
		# el Dosier, maximizado (tapa los iconos): las hojas llevan mucho texto y así se leen con la letra más grande;
		# y Colecciones, para que quepan a la vez la ficha grande y la cuadrícula
		ventana.position = Vector2(4, 4)
		ventana.size = Vector2(872, 514)
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
	# siempre con sitio para dos renglones (y nunca más), para que un texto largo no encoja la ventana de encima
	info.max_lines_visible = 2
	info.ready.connect(func(): info.custom_minimum_size.y = maxf(34.0, info.get_line_height() * 2 + info.get_theme_constant("line_spacing")))
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", TINTA)
	info.add_theme_constant_override("outline_size", 0)
	estado_barra.add_child(info)
	return contenido


# ── Talentos: cada punto se compra en su talento, con lo ahorrado ──

# Las tres ramas a la vez en una chapa oscura, cada talento un hexágono con su ficha al pasar por encima (arbol_talentos.gd).
# Aquí se le pone a cada botón lo que explica en la línea de abajo y lo que hace al pulsarlo
func programa_puntos(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	var arbol: Control = ARBOL.new()
	arbol.name = "arbol"
	arbol.montar(self, s)
	c.add_child(arbol)
	# Resetear (M32): quita los puntos del árbol, sin devolver lo gastado. Se pulsa dos veces, por si acaso
	enlazar(arbol.resetear, Idioma.t("Quita todos los puntos del árbol. Lo que gastaste en ellos no se devuelve."), resetear_talentos)
	for t in Talentos.LISTA:
		enlazar(arbol.botones[t.id], explica_talento(s, t), arbol.al_pulsar.bind(t.id))
	info.text = Idioma.t("Los $%d de esta partida se guardan al acabarla: todos si completas el edificio, la mitad si caes.") % 		partida.dolares if partida.dolares > 0 else 		Idioma.t("Cada punto se paga con lo ahorrado y sube un nivel. Para pasar al nivel siguiente, llena antes el talento que pide.")


# Lo que dice la línea de abajo de un talento marcado
func explica_talento(s: Dictionary, t: Dictionary) -> String:
	var texto: String = Talentos.desc_de(t.id)
	var precio := Talentos.precio(t.id)
	match Talentos.motivo(s, t.id):
		"bloqueado": texto = Idioma.t("Necesitas %s al máximo. %s") % [Talentos.nombres(Talentos.faltan(s, t.id)), texto]
		"max": texto = Idioma.t("¡Al máximo! %s") % texto
		"sin_dinero": texto = Idioma.t("%s. Cuesta $%d: te faltan $%d.") % [texto, precio, precio - s.dolares]
		"": texto = Idioma.t("%s. Pulsa para subirlo ($%d).") % [texto, precio]
	return texto


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


# «Resetear talentos»: no lo hace todavía, saca la ventanita que pregunta si de verdad (preguntar_reseteo)
func resetear_talentos() -> void:
	var s := Guardado.cargar()
	if not Talentos.se_puede_resetear(s):
		Sonido.tocar("no")
		info.text = Idioma.t("No tienes ningún punto puesto.")
		return
	preguntar_reseteo(s)


# La ventanita de aviso, como un cuadro de diálogo de Windows 95, en medio del programa: «¿Seguro? Perderás todo el
# dinero invertido…», con «Sí, resetear» y «Cancelar» (el marcado al salir, por si acaso). Detrás, una sombra que tapa la
# ventana para que no se pueda pulsar nada más; Esc o B cierran el aviso (_unhandled_input), y las flechas no salen de él
func preguntar_reseteo(s: Dictionary) -> void:
	cerrar_aviso(false)
	Sonido.tocar("click")
	aviso = ColorRect.new()
	aviso.name = "aviso"
	aviso.color = Color(0, 0, 0, 0.45)
	aviso.mouse_filter = Control.MOUSE_FILTER_STOP
	aviso.position = ventana.position
	aviso.size = ventana.size
	pantalla.add_child(aviso)
	pantalla.move_child(aviso, ventana.get_index() + 1)
	var centro := CenterContainer.new()
	centro.size = aviso.size
	aviso.add_child(centro)
	var cuadro := PanelContainer.new()
	cuadro.add_theme_stylebox_override("panel", caja(BEIS, BEIS, 0, 0, 3))
	cuadro.draw.connect(func(): relieve(cuadro, false, 3.0))
	centro.add_child(cuadro)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	cuadro.add_child(columna)
	var barra := PanelContainer.new()
	barra.add_theme_stylebox_override("panel", caja(AZUL, AZUL, 0, 0, 3))
	columna.add_child(barra)
	var titulo := Label.new()
	titulo.text = Idioma.t("Resetear talentos")
	barra.add_child(titulo)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	columna.add_child(margen)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 14)
	margen.add_child(dentro)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	dentro.add_child(fila)
	var alerta := TextureRect.new()
	alerta.texture = load("res://assets/ui/iconos/alerta.png")
	alerta.custom_minimum_size = Vector2(32, 32)
	alerta.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	alerta.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	fila.add_child(alerta)
	var texto := texto_tarjeta(Idioma.t("¿Seguro? Perderás todo el dinero que has invertido en los talentos ($%d). El árbol se quedará vacío para repartirlo otra vez.") %
		s.dolares_talentos, TINTA)
	texto.name = "texto"
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 320
	fila.add_child(texto)
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 12)
	dentro.add_child(botones)
	var si := boton_aviso(botones, "b_si", Idioma.t("Sí, resetear"), reseteo_confirmado)
	var no := boton_aviso(botones, "b_cancelar", Idioma.t("Cancelar"), cerrar_aviso)
	for b: Button in [si, no]:
		var otro: Button = no if b == si else si
		b.focus_neighbor_left = b.get_path_to(otro)
		b.focus_neighbor_right = b.get_path_to(otro)
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(b)
	no.grab_focus.call_deferred()
	info.text = Idioma.t("Lo que gastaste en los talentos no se devuelve.")


# Un botón de la ventanita de aviso, como los de Windows 95: con relieve, más claro con el ratón encima y con el punteado
# de «marcado» con el teclado o el mando
func boton_aviso(padre: Container, nombre: String, texto: String, al_pulsar: Callable) -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.custom_minimum_size = Vector2(130, 32)
	b.focus_mode = Control.FOCUS_ALL
	for estado in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(estado, caja(TARJETA_LUZ if estado in ["hover", "hover_pressed"] else TARJETA, TARJETA, 0, 0, 4))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, TINTA)
	b.add_theme_constant_override("outline_size", 0)
	b.draw.connect(func():
		relieve(b, b.button_pressed, 2.0)
		if b.has_focus():
			var r := Rect2(Vector2(5, 5), b.size - Vector2(10, 10))
			for lado in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end],
					[r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
				b.draw_dashed_line(lado[0], lado[1], TINTA, 1.0, 2.0))
	b.pressed.connect(al_pulsar)
	padre.add_child(b)
	return b


# Quita la ventanita de aviso; "volver": deja marcado otra vez «Resetear talentos» (al cancelar)
func cerrar_aviso(volver := true) -> void:
	if aviso == null:
		return
	aviso.queue_free()
	aviso = null
	if volver and ventana:
		var b := ventana.find_child("b_resetear", true, false)
		if b:
			b.grab_focus()
		info.text = Idioma.t("Quita todos los puntos del árbol. Lo que gastaste en ellos no se devuelve.")


# «Sí, resetear» en la ventanita: quita todos los puntos (lo gastado no se devuelve) y Johnny pierde lo que le daban
func reseteo_confirmado() -> void:
	cerrar_aviso(false)
	var s := Talentos.resetear()
	if s.is_empty():
		return
	Sonido.tocar("compra")
	partida.ahorrados = s.dolares   # el HUD enseña lo ahorrado más lo de esta partida
	partida.aplicar_talentos(s.talentos)
	abrir("puntos", "b_resetear")
	info.set_deferred("text", Idioma.t("¡Hecho! El árbol está vacío para volver a repartirlo. Tienes $%d ahorrados.") % s.dolares)


func subir(id: String) -> void:
	var motivo := Talentos.motivo(Guardado.cargar(), id)
	if motivo != "":
		Sonido.tocar("no")
		return   # la línea de info ya dice por qué no se puede
	Sonido.tocar("compra")
	var s := Talentos.subir(id)
	partida.ahorrados = s.dolares   # el HUD enseña lo ahorrado más lo de esta partida
	partida.aplicar_talentos(s.talentos)
	abrir("puntos", "b_" + id)
	info.set_deferred("text", Idioma.t("¡%s sube a %d/%d!") % [Talentos.nombre_de(id), Talentos.nivel_de(s, id), Talentos.talento(id).max])   # después de marcar el botón (que pone su explicación)


# ── Tienda de armas ──

# La chapa oscura con todo a la vez: las casillas por grupos a la izquierda y la ficha de lo elegido a la derecha
# (tienda_armas.gd). Aquí se le pone a cada casilla lo que explica en la línea de abajo y lo que hace al pulsarla.
# "foco": la casilla que se marca (después de comprar, lo comprado: la ficha lo sigue enseñando)
func programa_armas(c: VBoxContainer, foco := "") -> void:
	var tienda: Control = TIENDA.new()
	tienda.name = "tienda"
	tienda.montar(self, Guardado.cargar(), foco.trim_prefix("b_"))
	c.add_child(tienda)
	for id in Armas.PRECIOS:
		enlazar(tienda.botones[id], resumen(Armas.DATOS[id]), tienda.al_pulsar.bind(id))
	for k in Lanzables.PRECIOS:
		var que: String = Idioma.t(INVENTARIO.QUE_HACE[k])
		enlazar(tienda.botones[k], Idioma.t("%s: %s Cada uno, $%d.") % [Lanzables.uno(k), que[0].to_lower() + que.substr(1),
			Supervivientes.precio(Lanzables.PRECIOS[k])], tienda.al_pulsar.bind(k))
	info.text = Idioma.t("Elige un arma: se paga con los dólares ahorrados.")


# Debajo del nombre, como weaponSummary del JS pero sin el tipo (ya lo dice su sección): "Daño 9 · 4 ataques/s" (el
# lanzallamas, el lanza ácido y el lanza rayos, su daño por segundo y su depósito)
func resumen_corto(w: Dictionary) -> String:
	if w.has("deposito"):
		return Idioma.t("Daño %d/s · Depósito %d s") % [w.dano, roundi(w.deposito)]
	var dano := "%d × %d" % [w.dano, w.perdigones] if w.get("perdigones", 1) > 1 else str(w.dano)
	# (cada dato es un texto entero y se unen con « · »: así cada idioma ordena y escribe el suyo)
	var partes := [Idioma.t("Daño %s") % dano, Idioma.t("%s ataques/s") % Idioma.puntuar(str(w.ritmo).trim_suffix(".0"))]
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
	partes.append(Idioma.t("%s ataques por segundo") % Idioma.puntuar("%.1f" % w.ritmo))
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
	var precio: int = Supervivientes.precio(Armas.PRECIOS[id])
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
	var sin_vieja: bool = johnny.huecos[w.tipo] == ""   # (sin arma a distancia: no hay una vieja que pase al repuesto)
	var vieja: String = Armas.nombre(johnny.huecos[w.tipo], johnny.calidad(johnny.huecos[w.tipo]))
	var al_baul: Dictionary = partida.repuesto_al_baul(w.tipo)   # (con los dos huecos llenos, la de repuesto va al baúl: M26)
	var suelo: Dictionary = partida.llevar_arma(id)   # (en Normal: las mejoradas salen del banco y de la joyería)
	abrir("armas", "b_" + id)
	var texto: String
	if not al_baul.is_empty():
		texto = Idioma.t("¡Compra hecha! %s a la mano; %s pasa al repuesto y %s va al baúl.") % [
			Armas.nombre(id), vieja, Armas.nombre(al_baul.id, al_baul.calidad)]
	elif sin_vieja:
		texto = Idioma.t("¡Compra hecha! %s a la mano.") % Armas.nombre(id)
	elif suelo.is_empty():
		texto = Idioma.t("¡Compra hecha! %s a la mano; %s pasa al repuesto.") % [Armas.nombre(id), vieja]
	else:
		texto = Idioma.t("¡Compra hecha! %s a la mano; %s se queda en el suelo: ya llevabas dos.") % [Armas.nombre(id), vieja]
	info.set_deferred("text", texto)   # después de marcar el botón (que pone su explicación)


# Un arrojable más para esta partida (como cogerlo del suelo: lanzables.sumar), si cabe y le llega
func comprar_lanzable(k: String) -> void:
	var lz: Lanzables = partida.lanzables
	var no := ""
	if Reto.sin_municion():
		no = Idioma.t("En el reto «%s» no se lleva nada que lanzar.") % Reto.nombre("cuerpo")
	elif not lz.cabe(k):
		no = Idioma.t("No te caben más %s: tus montones están llenos y no te queda hueco para otro.") % Lanzables.varios(k)
	var s := Guardado.cargar()
	var precio: int = Supervivientes.precio(Lanzables.PRECIOS[k])
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

# La chapa oscura como un archivador (archivador_logros.gd): las páginas a la izquierda (Resumen y un apartado por tema)
# y la elegida a la derecha. Aquí se le pone a cada fila lo que explica en la línea de abajo y lo que hace al pulsarla.
# "foco": lo que se marca; sin nada (al abrirlo desde el escritorio) se empieza por el Resumen. Devuelve lo que hay que
# marcar de verdad (una fila que ya no está en la página, como lo recién cobrado en el Resumen, marca su página)
func programa_logros(c: VBoxContainer, foco := "") -> String:
	partida.logros.revisar()   # (lo que ya llegue por el guardado, como un talento recién comprado, sale conseguido)
	var s := Guardado.cargar()
	if foco == "":
		ARCHIVADOR.pagina = "resumen"
	elif foco.begins_with("b_tema_"):
		ARCHIVADOR.pagina = foco.trim_prefix("b_tema_")
	elif ARCHIVADOR.pagina != "resumen" and Logros.datos(foco.trim_prefix("b_")).get("tema", "") != ARCHIVADOR.pagina:
		ARCHIVADOR.pagina = Logros.datos(foco.trim_prefix("b_")).get("tema", "resumen")   # (un logro de otro apartado: su página)
	var archivador: Control = ARCHIVADOR.new()
	archivador.name = "archivador"
	archivador.montar(self, s)
	c.add_child(archivador)
	for t in archivador.temas:
		var lista: Array = Logros.LISTA if t == "resumen" else archivador.de_tema(t)
		var texto: String = Idioma.t("Lo que tienes por cobrar y cómo vas en cada apartado.") if t == "resumen" else 			Idioma.t("%s: llevas %d de %d.") % [Logros.nombre_tema(t), archivador.conseguidos(lista), lista.size()]
		enlazar(archivador.temas[t], texto, func(): pass)   # (cambiar de página ya lo hace el archivador)
	for id in archivador.botones:
		var l := Logros.datos(id)
		var e := Logros.estado(s, id)
		var meta := Logros.meta(l)
		var hecho: int = meta if e != "pendiente" else mini(partida.logros.progreso(id, s), meta)
		enlazar(archivador.botones[id], "%s: %s %s" % [Logros.nombre_de(id), Logros.desc_de(id), explica_logro(l, e, hecho, meta)], cobrar_logro.bind(id))
	info.text = Idioma.t("Esta partida va con ayudas (Opciones → Ayudas): no se consiguen logros. Los que ya tienes se quedan y puedes cobrarlos.") 		if partida.logros.sin_logros() else Idioma.t("Elige un reto para esta partida. Al cumplirlo sale un aviso; vuelve aquí a cobrar el premio.")
	if foco.begins_with("b_tema_") or archivador.botones.has(foco.trim_prefix("b_")):
		return foco
	return "b_tema_" + ARCHIVADOR.pagina if foco != "" else ""


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
	refrescar_avisos()   # (con el último premio cobrado, se quita el aviso de Logros)
	abrir("logros", "b_" + id)
	info.set_deferred("text", Idioma.t("¡Cobrados $%d! Ya puedes gastarlos en puntos o armas.") % dinero)


# ── Dosier ──

# Las páginas de todos los edificios (no solo del que se juega): se guardan para siempre (Guardado: "paginas"),
# las encuentres donde las encuentres. Una carpeta con una pestaña por edificio (carpeta_dosier.gd): a la izquierda,
# las páginas de ese edificio como fichas, y a la derecha, la hoja que se esté mirando; las que faltan salen
# arrancadas. Aquí se le pone a cada pestaña y a cada ficha lo que explica en la línea de abajo. "foco": lo que se
# marca (una página o una pestaña, "b_edificio_<id>"). Devuelve lo que hay que marcar de verdad: sin nada, la página
# que se mira
func programa_dosier(c: VBoxContainer, foco := "") -> String:
	var s := Guardado.cargar()
	var carpeta: Control = CARPETA_DOSIER.new()
	carpeta.name = "carpeta"
	carpeta.montar(self, s, foco)
	c.add_child(carpeta)
	for e in carpeta.pestanas:
		enlazar(carpeta.pestanas[e], Idioma.t("%s: %d de %d páginas del dosier.") % [carpeta.nombre_edificio(e), carpeta.halladas(e),
			carpeta.del_edificio(e).size()], func(): pass)   # (cambiar de pestaña ya lo hace la carpeta)
	var nombre: String = carpeta.nombre_edificio(carpeta.edificio)
	var paginas: Array = carpeta.del_edificio()
	for i in paginas.size():
		var p: Dictionary = paginas[i]
		enlazar(carpeta.botones[p.id], (Idioma.t("%s, página %d: %s. La llevaba %s.") % [nombre, i + 1, Historia.titulo_de(p), Historia.cuerpo_de(p)])
			if Historia.encontrada(s, p.id) else Idioma.t("%s, página %d: aún no la has encontrado (%s).") % [nombre, i + 1,
			Historia.donde(p, carpeta.edificio)], func(): pass)
	info.text = Idioma.t("Pasa por las páginas para leerlas.")
	if foco.begins_with("b_edificio_"):
		return foco
	return "b_" + carpeta.vista


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
				refrescar_avisos()   # (con la última nueva vista, se quita el aviso de Noticias)
		enlazar(b, Idioma.t("Emisión %d: «%s». Pulsa para saltar o repetir.") % [i + 1, Historia.titular_de(n)], tele.saltar)
		b.focus_entered.connect(ver)
		b.mouse_entered.connect(ver)
	info.text = Idioma.t("%s, con %s. Pasa por las emisiones para verlas.") % [Historia.canal(), Historia.REPORTERA]
	if foco != "":
		return foco
	return primera_nueva if primera_nueva != "" else ultima


# ── Colecciones: el bestiario ──

const FICHA_ANCHO := 404       # la ficha de la izquierda (el escenario, el nombre, la frase...)
const ESCENARIO := Vector2(404, 208)   # donde sale el enemigo grande, con su luz
# En el escenario (medido en su fondo, foco-sujetos.png): los pies, en el charco de luz del suelo, y lo más alto a lo
# que puede llegar la cabeza, unos píxeles por debajo de la lámpara, para no tocarla
const PIES_ESCENARIO := 186.0
const TECHO_ESCENARIO := 46.0
const FONDO_ESCENARIO := preload("res://assets/ui/foco-sujetos.png")   # su fondo, 202 × 90 (tools/foco_sujetos.py)
const CASILLA_ZOMBI := 100     # cada casilla de la cuadrícula de la derecha (4 por fila)
const POR_PAGINA := 12         # las casillas de cada página de la cuadrícula (4 × 3)
var familia_vista := "durmientes"   # la pestaña abierta de Colecciones (Bestiario.familias)
var pagina_vista := 0               # y su página


# Todos los enemigos del juego, como un álbum (desde el 8 nov, solo ellos: los objetos y las páginas del dosier ya no
# salen aquí; las páginas se leen en DOSIER.TXT). Se llama «Sujetos» (los de Velaria). Arriba, cuántos se han visto,
# con su barra; debajo, una pestaña por familia (los durmientes, los zombis de siempre, y los sonámbulos, los jefes) y, a
# la derecha, las flechas de las páginas de la cuadrícula (si tiene más de una); a la izquierda, el que se esté mirando,
# grande y moviéndose bajo un foco, con su nombre, dónde sale, su frase y cuántos se han matado; a la derecha, la
# cuadrícula de la familia: los vistos a color, los que faltan en silueta negra y los jefes con marco dorado. "foco":
# "z_<id>" abre su familia y su página con él marcado; "pes_<familia>", esa pestaña; "pag_ant" o "pag_sig", la flecha.
# Devuelve lo que hay que marcar
func programa_colecciones(c: VBoxContainer, foco: String) -> String:
	var s := Guardado.cargar()
	if s.colecciones_nuevo:
		# ya está visto: el aviso del icono se quita hasta que haya algo nuevo
		s = Guardado.cambiar(func(g): g.colecciones_nuevo = false)
		refrescar_avisos()
	if foco.begins_with("z_") and foco.substr(2) in Bestiario.LISTA:
		familia_vista = Bestiario.familia(foco.substr(2))
		pagina_vista = Bestiario.de_familia(familia_vista).find(foco.substr(2)) / POR_PAGINA
	elif foco.begins_with("pes_") and foco.substr(4) in Bestiario.familias():
		familia_vista = foco.substr(4)
	if not familia_vista in Bestiario.familias():
		familia_vista = Bestiario.familias()[0]
	var todos := Bestiario.de_familia(familia_vista)
	var paginas := ceili(todos.size() / float(POR_PAGINA))
	pagina_vista = posmod(pagina_vista, paginas)

	# arriba: el título y lo visto de todo el bestiario, con su barra
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 8)
	c.add_child(arriba)
	var titulo := texto_tarjeta(Idioma.t("Sujetos"), TINTA)
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(titulo)
	var vistos := cuantos(Bestiario.LISTA.keys(), s.bestiario)
	for h: Control in [texto_tarjeta(Idioma.t("Vistos"), TINTA_SUAVE), barra_progreso(vistos, Bestiario.LISTA.size()),
			texto_tarjeta("%d / %d" % [vistos, Bestiario.LISTA.size()], TINTA)]:
		h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		arriba.add_child(h)

	# las pestañas: una por familia, con cuántos se han visto de ella
	var pestanas := HBoxContainer.new()
	pestanas.add_theme_constant_override("separation", 6)
	c.add_child(pestanas)
	for fam: String in Bestiario.familias():
		var suyos := Bestiario.de_familia(fam)
		var hechos := cuantos(suyos, s.bestiario)
		var b := Button.new()
		b.name = "pes_" + fam
		b.text = "%s · %d / %d" % [nombre_familia(fam), hechos, suyos.size()]
		b.custom_minimum_size.x = 200
		estilo_pestana(b, fam == familia_vista)
		pestanas.add_child(b)
		enlazar(b, Idioma.t("%s: %d de %d vistos.") % [nombre_familia(fam), hechos, suyos.size()], func():
			if familia_vista != fam:
				familia_vista = fam
				pagina_vista = 0
				abrir("colecciones", "pes_" + fam))
	# las páginas de la cuadrícula, a la derecha de las pestañas: < 1 / 2 > (dan la vuelta)
	if paginas > 1:
		var hueco := Control.new()
		hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pestanas.add_child(hueco)
		for flecha in [["pag_ant", "<", -1], ["pag_sig", ">", 1]]:
			var b := Button.new()
			b.name = flecha[0]
			b.text = flecha[1]
			b.custom_minimum_size.x = 36
			estilo_pestana(b, false)
			if flecha[2] > 0:
				var cual := texto_tarjeta("%d / %d" % [pagina_vista + 1, paginas], TINTA)
				cual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				pestanas.add_child(cual)
			pestanas.add_child(b)
			var paso: int = flecha[2]
			var nombre_boton: String = flecha[0]
			enlazar(b, Idioma.t("Página %d de %d.") % [pagina_vista + 1, paginas], func():
				pagina_vista = posmod(pagina_vista + paso, paginas)
				abrir("colecciones", nombre_boton))

	# debajo: la ficha a la izquierda y la cuadrícula a la derecha
	var partes := HBoxContainer.new()
	partes.add_theme_constant_override("separation", 12)
	partes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(partes)
	var lado := CenterContainer.new()
	lado.custom_minimum_size.x = FICHA_ANCHO
	lado.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	partes.add_child(lado)
	var cuadricula := GridContainer.new()
	cuadricula.columns = 4
	cuadricula.add_theme_constant_override("h_separation", 6)
	cuadricula.add_theme_constant_override("v_separation", 4)
	cuadricula.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	partes.add_child(cuadricula)
	var ids := todos.slice(pagina_vista * POR_PAGINA, (pagina_vista + 1) * POR_PAGINA)
	for id: String in ids:
		var visto := Bestiario.visto(s, id)
		var clave := "z_" + id
		var b := casilla_zombi(cuadricula, id, visto)
		var hacer := ficha_bestiario.bind(s, id, visto)
		var ver := func():
			mostrar(lado, clave, hacer)
			senalar_casilla(cuadricula, clave)
		enlazar(b, (Idioma.t("%s: sale en %s. Matados: %d.") % [Bestiario.nombre(id), sale_en(Bestiario.LISTA[id], true),
			Bestiario.matados(s, id)]) if visto
			else Idioma.t("Un enemigo que aún no te has cruzado. Los que veas en una partida se apuntan aquí."), ver)
		# (su ficha sale al elegirla: con un clic, o con Intro o A en la marcada. Antes salía con solo pasar por encima,
		# y el dueño prefiere elegirla, 8 nov)
	# con el teclado o el mando, de los bordes no se sale: la ventana tapa los iconos del escritorio, y Godot, sin esto,
	# pasaba a ellos al bajar de la última fila o ir a la izquierda
	var casillas := cuadricula.get_children()
	for i in casillas.size():
		var b: Button = casillas[i]
		if i + cuadricula.columns >= casillas.size():
			b.focus_neighbor_bottom = b.get_path()
		if i % cuadricula.columns == 0:
			b.focus_neighbor_left = b.get_path()
		if i % cuadricula.columns == cuadricula.columns - 1 or i == casillas.size() - 1:
			b.focus_neighbor_right = b.get_path()
	var de_arriba := pestanas.get_children().filter(func(h): return h is Button)
	for b: Button in de_arriba:
		b.focus_neighbor_top = b.get_path()
	de_arriba[0].focus_neighbor_left = de_arriba[0].get_path()
	de_arriba[-1].focus_neighbor_right = de_arriba[-1].get_path()
	# al abrir, en la ficha: el pedido o el primero de la familia
	var empieza: String = foco if foco.begins_with("z_") and foco.substr(2) in ids else "z_" + ids[0]
	var primero: String = empieza.substr(2)
	mostrar(lado, empieza, ficha_bestiario.bind(s, primero, Bestiario.visto(s, primero)))
	senalar_casilla(cuadricula, empieza)
	info.text = Idioma.t("Cada enemigo que te cruzas queda aquí para siempre. Elige una casilla para ver su ficha.")
	return foco if foco.begins_with("pes_") or foco.begins_with("pag_") else empieza


# Las pestañas y las flechas de Colecciones: como una tarjeta, con borde oscuro la abierta, la marcada y la de debajo
# del ratón
func estilo_pestana(b: Button, abierta_ya: bool) -> void:
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", caja(TARJETA_LUZ if abierta_ya else TARJETA, TINTA if abierta_ya else TARJETA, 2, 0, 4))
	for e in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(e, caja(TARJETA_LUZ, TINTA, 2, 0, 4))
	for color in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(color, TINTA)
	b.add_theme_constant_override("outline_size", 0)


# El nombre de una familia en su pestaña
func nombre_familia(fam: String) -> String:
	return Idioma.t("Sonámbulos") if fam == "sonambulos" else Idioma.t("Durmientes")


# Una barra hundida, verde hasta donde se ha llegado (lo visto del bestiario)
func barra_progreso(hecho: int, total: int) -> Control:
	var barra := Control.new()
	barra.custom_minimum_size = Vector2(160, 16)
	barra.draw.connect(func():
		var t := barra.size
		barra.draw_rect(Rect2(Vector2.ZERO, t), TARJETA)
		barra.draw_rect(Rect2(2, 2, (t.x - 4) * hecho / maxf(total, 1), t.y - 4), VERDE_OSCURO)
		relieve(barra, true, 2.0))
	return barra


# Cuántos de estos ids están ya en una lista del guardado
func cuantos(ids: Array, tenidos: Array) -> int:
	return ids.filter(func(id): return id in tenidos).size()


# Dónde sale un enemigo: corto para las fichas ("Apartamentos y centro") o con artículo para las frases
func sale_en(d: Dictionary, con_articulo := false) -> String:
	var eds: Array = d.edificios
	if eds.size() >= Edificios.LISTA.size():   # los zombis de siempre: en todos
		return Idioma.t("todos los edificios") if con_articulo else Idioma.t("Todos los edificios")
	if con_articulo:
		# «los Apartamentos y el Centro comercial»: de uno en uno, cada idioma pone su «y»
		var texto: String = Idioma.t(Edificios.datos(eds[0]).el_nombre)
		for e in eds.slice(1):
			texto = Idioma.t("%s y %s") % [texto, Idioma.t(Edificios.datos(e).el_nombre)]
		return texto
	return Idioma.t("Apartamentos y centro") if eds.size() > 1 else Idioma.t(Edificios.datos(eds[0]).nombre)


# Pone una ficha en el visor de la izquierda. Si ya es la que está, nada (el foco y el ratón la piden a la vez).
# "hacer" la construye, solo entonces
func mostrar(lado: CenterContainer, clave: String, hacer: Callable) -> void:
	if lado.get_meta("ficha", "") == clave:
		return
	lado.set_meta("ficha", clave)
	for h in lado.get_children():
		lado.remove_child(h)
		h.queue_free()
	lado.add_child(hacer.call())


# Una casilla de la cuadrícula: un botón con el dibujo de frente del enemigo, encajado; en silueta negra si aún no se ha
# visto y con marco dorado si es un jefe. Al pulsarla, su ficha sale a la izquierda (sus bordes los pone senalar_casilla)
func casilla_zombi(padre: Container, id: String, visto: bool) -> Button:
	var b := Button.new()
	b.name = "z_" + id
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(CASILLA_ZOMBI, CASILLA_ZOMBI)
	b.set_meta("jefe", Bestiario.LISTA[id].get("jefe", false))
	padre.add_child(b)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(centro)
	var imagen := TextureRect.new()
	imagen.texture = Bestiario.retrato(id)
	# a escala entera, lo más grande que quepa (como mucho, a 2)
	var t := imagen.texture.get_size()
	var escala := clampf(floorf((CASILLA_ZOMBI - 4) / maxf(t.x, t.y)), 1.0, 2.0)
	if t.x * escala > CASILLA_ZOMBI - 8 or t.y * escala > CASILLA_ZOMBI - 8:
		escala = minf((CASILLA_ZOMBI - 8) / t.x, (CASILLA_ZOMBI - 8) / t.y)   # los grandes, a menos de 1
	imagen.custom_minimum_size = t * escala
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not visto:
		imagen.modulate = Color.BLACK   # la silueta
	centro.add_child(imagen)
	return b


# La casilla elegida (la que sale en la ficha): clara y con el borde negro grueso, pase lo que pase. Las demás, normales
# (las de los jefes, con su marco dorado) y, con el ratón encima o marcadas con el teclado o el mando, se aclaran y
# llevan un borde gris más fino: así se nota por dónde se va sin confundirla con la elegida
func senalar_casilla(cuadricula: GridContainer, clave: String) -> void:
	var elegida := caja(TARJETA_LUZ, TINTA, 3, 0, 0)
	var encima := caja(TARJETA_LUZ, TINTA_SUAVE, 2, 0, 0)
	for b: Button in cuadricula.get_children():
		var jefe: bool = b.get_meta("jefe", false)
		var es := b.name == clave
		b.add_theme_stylebox_override("normal", elegida if es else caja(TARJETA, PIP_LLENO if jefe else TARJETA, 3, 0, 0))
		for e in ["hover", "focus", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(e, elegida if es else encima)


# La ficha de un enemigo, a la izquierda: él grande y moviéndose (en silueta, quieto, si no se ha visto) en un escenario con
# su luz, y debajo su nombre, dónde sale, su frase y cuántos se han matado
func ficha_bestiario(s: Dictionary, id: String, visto: bool) -> Control:
	var d: Dictionary = Bestiario.LISTA[id]
	var columna := VBoxContainer.new()
	columna.custom_minimum_size.x = FICHA_ANCHO
	columna.add_theme_constant_override("separation", 2)
	var escenario := Control.new()
	escenario.name = "escenario"
	escenario.custom_minimum_size = ESCENARIO
	escenario.clip_contents = true
	escenario.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	escenario.draw.connect(pintar_escenario.bind(escenario))
	columna.add_child(escenario)
	# el dibujo, con los pies en el centro del suelo: a escala entera, lo más grande que quepa (como mucho, a 3)
	var usado: Rect2i = d.recorte
	var escala := clampi(int((PIES_ESCENARIO - TECHO_ESCENARIO) / usado.size.y), 1, 3)
	var pies := Vector2(ESCENARIO.x / 2, PIES_ESCENARIO)
	var recurso: Resource = load(d.hoja)
	var dibujo: Node2D
	if recurso is SpriteFrames and (recurso as SpriteFrames).has_animation(d.retrato):
		var animado := AnimatedSprite2D.new()
		animado.sprite_frames = recurso
		animado.animation = d.retrato
		if visto:
			animado.play()
		dibujo = animado
		animado.centered = false
	else:   # el maniquí: un PNG entero
		var quieto := Sprite2D.new()
		quieto.texture = recurso as Texture2D
		quieto.centered = false
		dibujo = quieto
	dibujo.name = "dibujo"
	dibujo.scale = Vector2(escala, escala)
	dibujo.position = (pies - Vector2(usado.position.x + usado.size.x / 2.0, usado.position.y + usado.size.y) * escala).round()
	dibujo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not visto:
		dibujo.modulate = Color.BLACK   # la silueta
	escenario.add_child(dibujo)
	polvo_y_parpadeo(escenario)

	var nombre := texto_tarjeta(Bestiario.nombre(id) if visto else "???", TINTA)
	nombre.add_theme_font_size_override("font_size", 24)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(nombre)
	# dónde sale y cuántos se han matado, en la misma línea (así cabe el escenario alto)
	var linea := HBoxContainer.new()
	linea.alignment = BoxContainer.ALIGNMENT_CENTER
	linea.add_theme_constant_override("separation", 12)
	columna.add_child(linea)
	linea.add_child(texto_tarjeta(Idioma.t("Sale en: %s") % (sale_en(d) if visto else "???"), TINTA_SUAVE))
	if visto:
		linea.add_child(texto_tarjeta(Idioma.t("Matados: %d") % Bestiario.matados(s, id), VERDE_OSCURO))
	var frase := texto_tarjeta(Bestiario.frase(id) if visto else Idioma.t("Aún no te lo has cruzado."), TINTA)
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.custom_minimum_size.x = FICHA_ANCHO
	frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(frase)
	return columna


# El fondo del escenario de la ficha: la sala a oscuras con la lámpara y su cono de luz (la imagen de GPT reducida,
# assets/ui/foco-sujetos.png), a 2 unidades por píxel como todo el juego. La luz deja ver la silueta negra de los que
# aún no se han visto
func pintar_escenario(e: Control) -> void:
	e.draw_texture_rect(FONDO_ESCENARIO, Rect2(Vector2.ZERO, e.size), false)
	relieve(e, true, 2.0)


# Lo que le da vida al escenario: motas de polvo que suben despacio dentro del cono de luz (delante del enemigo) y,
# de vez en cuando, la lámpara que falla un instante (como las de los apartamentos): se oscurece todo y vuelve
func polvo_y_parpadeo(e: Control) -> void:
	var polvo := CPUParticles2D.new()
	polvo.name = "polvo"
	polvo.amount = 22
	polvo.lifetime = 5.0
	polvo.preprocess = 5.0   # ya flotando al abrir la ficha
	polvo.position = Vector2(ESCENARIO.x / 2, 110)
	polvo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	polvo.emission_rect_extents = Vector2(70, 60)   # el ancho del cono por en medio
	polvo.direction = Vector2(0, -1)
	polvo.spread = 40.0
	polvo.gravity = Vector2.ZERO
	polvo.initial_velocity_min = 2.0
	polvo.initial_velocity_max = 6.0
	polvo.scale_amount_min = 2.0   # un píxel del dibujo (2 unidades)
	polvo.scale_amount_max = 2.0
	var tono := Gradient.new()   # aparece y se apaga poco a poco
	tono.set_color(0, Color(1.0, 0.9, 0.6, 0.0))
	tono.set_color(1, Color(1.0, 0.9, 0.6, 0.0))
	tono.add_point(0.3, Color(1.0, 0.9, 0.6, 0.7))
	tono.add_point(0.7, Color(1.0, 0.9, 0.6, 0.5))
	polvo.color_ramp = tono
	e.add_child(polvo)
	var reloj := Timer.new()
	reloj.wait_time = 0.5
	reloj.autostart = true
	reloj.timeout.connect(func():
		if randf() < 0.08:
			var fallo := e.create_tween()
			fallo.tween_property(e, "modulate", Color(0.45, 0.45, 0.45), 0.05)
			fallo.tween_property(e, "modulate", Color.WHITE, 0.05)
			if randf() < 0.5:   # a veces, dos seguidos
				fallo.tween_property(e, "modulate", Color(0.6, 0.6, 0.6), 0.04).set_delay(0.06)
				fallo.tween_property(e, "modulate", Color.WHITE, 0.06))
	e.add_child(reloj)


# ── Piezas ──

# Una tarjeta (.pc-arma del JS): con relieve, su icono grande, el nombre (y, en los talentos, sus cuadraditos de
# nivel), una línea de explicación debajo y la etiqueta azul de la derecha ("$15", "+1 punto", "MÁX"...).
# "estado": "" (se puede usar), "bloqueada" (apagada), "apagada" (sin dinero: la etiqueta en gris), "puesta" o
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
	var titular := texto_tarjeta(titulo, TINTA)
	# los nombres largos («La directora de Recursos Humanos») parten la línea en vez de ensanchar la lista y, con ella,
	# la ventana, que se saldría de la pantalla del monitor
	titular.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titular.custom_minimum_size.x = 60
	titular.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(titular)
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
		var encima := b.has_focus() or (b.is_hovered() and not Controles.con_mando)   # (con el mando, solo lo que marca él)
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
	b.mouse_entered.connect(func():
		if not colocando:
			info.text = texto)
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
		if aviso:
			cerrar_aviso()   # (la ventanita de «¿Seguro?», antes que el programa)
		elif abierta != "":
			abrir("")
		else:
			apagar()
