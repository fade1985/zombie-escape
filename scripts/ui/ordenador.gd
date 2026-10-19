# El ordenador de la sala de mantenimiento, "ConserjeOS" (src/ordenador.js del JS). Al arrimarse a la mesa
# (mapa/ordenador.gd) el juego se pausa y sale la pantalla: un monitor viejo con su escritorio, sus iconos, la
# barra de tareas con el reloj y una ventana para cada programa:
#   - "Compra de puntos e intercambio": cambia los dólares ahorrados por puntos de talento (talentos.gd) y los
#     gasta en el árbol de talentos. Lo comprado se nota al momento.
#   - "Tienda de armas": compra con los dólares ahorrados un arma (Armas.PRECIOS) para esta partida, y queda
#     desbloqueada en el guardado. La que llevaras en ese hueco se pierde (aún no hay armas por el suelo).
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
	["apagar", "puerta", "Apagar"],
]
const NOMBRES := {"puntos": "PUNTOS.EXE", "armas": "ARMAS.EXE"}
const TAREAS := {"puntos": "Compra de puntos e intercambio", "armas": "Tienda de armas"}
const ICONO_ARMA := {"mp5": "pistola"}

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


func esta_encendido() -> bool:
	return fondo != null


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
	iconos.add_theme_constant_override("separation", 8)
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
		b.add_theme_stylebox_override("hover", caja(Color(1, 1, 1, 0.12), Color(0, 0, 0, 0), 0, 4, 4))
		b.add_theme_stylebox_override("pressed", caja(Color(1, 1, 1, 0.2), Color(0, 0, 0, 0), 0, 4, 4))
		var programa: String = i[0]
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


# La ventana: barra de título con su X, el contenido (con barra de desplazamiento si no cabe) y la línea de info
func montar_ventana(programa: String) -> VBoxContainer:
	ventana = PanelContainer.new()
	ventana.add_theme_stylebox_override("panel", caja(Tema.METAL, Tema.LINEA, 2, 0, 0))
	ventana.position = Vector2(152, 10)
	ventana.size = Vector2(718, 508)
	pantalla.add_child(ventana)
	pantalla.move_child(ventana, iconos.get_index() + 1)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	ventana.add_child(columna)

	var barra := PanelContainer.new()
	barra.add_theme_stylebox_override("panel", caja(TITULO, TITULO, 0, 0, 4))
	columna.add_child(barra)
	var fila := HBoxContainer.new()
	barra.add_child(fila)
	var titulo := Label.new()
	titulo.text = "C:\\MANTENIMIENTO\\" + NOMBRES[programa]
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)
	var x := Button.new()
	x.text = "X"
	x.custom_minimum_size = Vector2(28, 24)
	for estado in ["normal", "hover", "pressed"]:
		var c := Color("#b8454f") if estado != "hover" else Color("#e0606a")
		x.add_theme_stylebox_override(estado, caja(c, Tema.LINEA, 2, 2, 0))
	x.focus_mode = Control.FOCUS_NONE   # con el mando se cierra con B
	x.pressed.connect(abrir.bind(""))
	fila.add_child(x)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(margen)
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.follow_focus = true
	margen.add_child(desliza)
	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 6)
	desliza.add_child(contenido)

	var abajo := PanelContainer.new()
	abajo.add_theme_stylebox_override("panel", caja(Color("#1c1a24"), Tema.LINEA, 0, 0, 5))
	columna.add_child(abajo)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(0, 34)
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color("#9fe8ff"))
	abajo.add_child(info)
	return contenido


# ── Compra de puntos e intercambio ──

func programa_puntos(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	var alcanzables: int = s.dolares / Talentos.PRECIO_PUNTO
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 14)
	c.add_child(arriba)
	saldo(arriba, s)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	var uno := boton(arriba, "b_comprar_1", "billete", "Comprar 1 punto", alcanzables >= 1)
	enlazar(uno, "Cambia $%d por 1 punto de talento" % Talentos.PRECIO_PUNTO, comprar.bind(1))
	var todo := boton(arriba, "b_comprar_todo", "billete", "Comprar %d" % alcanzables if alcanzables > 1 else "Comprar todo",
		alcanzables >= 1)
	enlazar(todo, "Cambia todos los dólares que puedas por puntos ($%d = 1 punto)" % Talentos.PRECIO_PUNTO,
		func(): comprar(maxi(1, Guardado.cargar().dolares / Talentos.PRECIO_PUNTO)))
	nota_partida(c)
	for rama in Talentos.RAMAS:
		c.add_child(montar_rama(s, rama))
	info.text = "Cada punto sube un nivel. Para pasar a la columna siguiente, llena antes el talento que pide."


func saldo(fila: HBoxContainer, s: Dictionary) -> void:
	var dinero := Tema.icono_y_texto("billete", "$%d ahorrados" % s.dolares, 24)
	dinero.get_child(1).add_theme_color_override("font_color", Tema.VERDE)
	fila.add_child(dinero)
	if abierta == "puntos":
		var puntos := Tema.icono_y_texto("trofeo", "%d puntos" % s.puntos, 24)
		puntos.get_child(1).add_theme_color_override("font_color", Tema.AMARILLO)
		fila.add_child(puntos)


func nota_partida(c: VBoxContainer) -> void:
	if partida.dolares > 0:
		var nota := Label.new()
		nota.theme_type_variation = "Sub"
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nota.text = "Los $%d de esta partida no se pueden gastar hasta que completes el edificio." % partida.dolares
		c.add_child(nota)


# Una rama del árbol: sus talentos en tres columnas (nivel 1, 2 y 3), de izquierda a derecha
func montar_rama(s: Dictionary, rama: Dictionary) -> PanelContainer:
	var marco := PanelContainer.new()
	marco.add_theme_stylebox_override("panel", caja(Color("#221f29"), Tema.OXIDO, 2, 4, 6))
	var columna := VBoxContainer.new()
	marco.add_child(columna)
	var titulo := Tema.icono_y_texto(rama.icono, rama.nombre, 24)
	titulo.get_child(1).add_theme_color_override("font_color", Tema.AMARILLO)
	columna.add_child(titulo)
	var niveles := HBoxContainer.new()
	niveles.add_theme_constant_override("separation", 10)
	columna.add_child(niveles)
	for nivel in [1, 2, 3]:
		var lista := VBoxContainer.new()
		lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		niveles.add_child(lista)
		for t in Talentos.LISTA:
			if t.rama == rama.id and t.nivel == nivel:
				lista.add_child(nodo_talento(s, t))
	return marco


func nodo_talento(s: Dictionary, t: Dictionary) -> Button:
	var n := Talentos.nivel_de(s, t.id)
	var motivo := Talentos.motivo(s, t.id)
	var b := boton(null, "b_" + t.id, "candado" if motivo == "bloqueado" else t.icono, "%s  %d/%d" % [t.nombre, n, t.max],
		motivo == "")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if motivo == "max":
		for c in ["font_color", "font_hover_color", "font_focus_color"]:
			b.add_theme_color_override(c, Tema.AMARILLO)
	var texto: String = t.desc
	if t.id in Talentos.MAS_ADELANTE:
		texto += " (llega con los objetos, en la fase 7)"
	match motivo:
		"bloqueado": texto = "Necesitas %s al máximo. %s" % [Talentos.talento(t.pide).nombre, texto]
		"max": texto = "¡Al máximo! " + texto
		"sin_puntos": texto += ". Te hace falta 1 punto."
		"": texto += ". Pulsa para subirlo (1 punto)."
	enlazar(b, texto, subir.bind(t.id))
	return b


func comprar(n: int) -> void:
	var s := Talentos.comprar_puntos(n)
	if s.is_empty():
		info.text = "No te llega: cada punto cuesta $%d de lo ahorrado." % Talentos.PRECIO_PUNTO
		return
	partida.ahorrados = s.dolares   # el HUD enseña lo ahorrado más lo de esta partida
	abrir("puntos", "b_comprar_1" if s.dolares >= Talentos.PRECIO_PUNTO else "")
	info.set_deferred("text", "¡Hecho! Ahora tienes %d puntos para gastar." % s.puntos)   # después de marcar el botón (que pone su explicación)


func subir(id: String) -> void:
	var motivo := Talentos.motivo(Guardado.cargar(), id)
	if motivo != "":
		return   # la línea de info ya dice por qué no se puede
	var s := Talentos.subir(id)
	partida.aplicar_talentos(s.talentos)
	abrir("puntos", "b_" + id)
	info.set_deferred("text", "¡%s sube a %d/%d!" % [Talentos.talento(id).nombre, Talentos.nivel_de(s, id), Talentos.talento(id).max])   # después de marcar el botón (que pone su explicación)


# ── Tienda de armas ──

func programa_armas(c: VBoxContainer) -> void:
	var s := Guardado.cargar()
	var arriba := HBoxContainer.new()
	c.add_child(arriba)
	saldo(arriba, s)
	var nota := Label.new()
	nota.theme_type_variation = "Sub"
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.text = "Lo que compres es para esta partida y queda desbloqueado. La que llevaras en ese hueco se pierde."
	c.add_child(nota)
	nota_partida(c)
	var ids := Armas.PRECIOS.keys()
	ids.sort_custom(func(a, b): return Armas.PRECIOS[a] < Armas.PRECIOS[b])
	for tipo in ["cuerpo", "fuego"]:
		var titulo := Label.new()
		titulo.text = "Cuerpo a cuerpo" if tipo == "cuerpo" else "De fuego (con el cargador lleno)"
		titulo.add_theme_color_override("font_color", Tema.AMARILLO)
		c.add_child(titulo)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		c.add_child(fila)
		for id in ids:
			var w: Dictionary = Armas.DATOS[id]
			if w.tipo != tipo:
				continue
			var precio: int = Armas.PRECIOS[id]
			var lleva: bool = partida.johnny.huecos[tipo] == id
			var etiqueta := "LA LLEVAS" if lleva else ("GRATIS" if precio == 0 else "$%d" % precio)
			var b := boton(fila, "b_" + id, ICONO_ARMA.get(id, id), "%s  %s" % [w.nombre, etiqueta], not lleva and s.dolares >= precio)
			if lleva:
				for col in ["font_color", "font_hover_color", "font_focus_color"]:
					b.add_theme_color_override(col, Tema.AMARILLO)
			enlazar(b, resumen(w), comprar_arma.bind(id))
	info.text = "Elige un arma: se paga con los dólares ahorrados."


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
		return
	var s := Guardado.cargar()
	var precio: int = Armas.PRECIOS[id]
	if s.dolares < precio:
		info.text = "No te llega: te faltan $%d." % (precio - s.dolares)
		return
	s.dolares -= precio
	if not id in s.armas:
		s.armas.append(id)
	Guardado.escribir(s)
	partida.ahorrados = s.dolares
	var vieja: String = Armas.DATOS[johnny.huecos[w.tipo]].nombre
	johnny.coger(id)
	abrir("armas", "b_" + id)
	info.set_deferred("text", "¡%s comprada! Dejas %s." % [w.nombre, vieja.to_lower()])   # después de marcar el botón (que pone su explicación)


# ── Piezas ──

# Un botón de chapa con icono. "vivo": si se puede usar ahora (si no, se ve apagado, pero se puede marcar
# para leer en la línea de info por qué no)
func boton(caja_padre: Container, nombre: String, icono: String, texto: String, vivo := true) -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.icon = load("res://assets/ui/iconos/%s.png" % icono)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_max_width", 24)
	for estado in ["normal", "hover", "pressed"]:
		var chapa: StyleBoxTexture = Tema.crear().get_stylebox(estado, "Button").duplicate()
		chapa.content_margin_left = 10
		chapa.content_margin_right = 12
		chapa.content_margin_top = 4
		chapa.content_margin_bottom = 6
		b.add_theme_stylebox_override(estado, chapa)
	if not vivo:
		b.modulate = Color(0.62, 0.6, 0.62)
	if caja_padre:
		caja_padre.add_child(b)
	return b


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
