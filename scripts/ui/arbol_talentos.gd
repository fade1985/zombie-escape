# El árbol de talentos del ordenador (TALENTOS.EXE, en ordenador.gd): una chapa oscura con las tres ramas a la vez,
# cada una de su color (Militar en rojo, Superviviente en verde y Químico en amarillo). Cada talento es un hexágono con su
# icono y sus cuadraditos de nivel; las rayas lo unen con el que pide y se encienden cuando ese está lleno.
#
# Al pasar el ratón por un talento (o al marcarlo con el teclado o el mando) sale a su lado su ficha: qué hace, lo que da
# ahora y con otro punto, qué abre y lo que cuesta. Con el ratón, el teclado o el mando se compra al pulsarlo; con el dedo,
# el primer toque solo enseña la ficha y el segundo compra (que no se gasten dólares sin querer).
#
# Arriba, en la misma chapa, lo ahorrado y el botón «Resetear talentos». Todo se dibuja con código (_draw); encima de
# cada hexágono hay un botón transparente, "b_<id>", que es el que se marca y se pulsa (como las tarjetas del ordenador)
extends Control

# Los colores de cada rama: [claro, medio, oscuro, el fondo de su columna]
const COLORES := {
	"militar": [Color("#ff8a5c"), Color("#d2452b"), Color("#5a1a12"), Color("#2a1a17")],
	"superviviente": [Color("#9be36a"), Color("#4f9e34"), Color("#173a12"), Color("#18241a")],
	"quimico": [Color("#ffe066"), Color("#d6a521"), Color("#4d3a08"), Color("#26231a")],
}
# los colores de la chapa, los de chapa.gd (la comparte con la tienda de armas)
const PLACA := preload("res://scripts/ui/chapa.gd")
const APAGADO := PLACA.APAGADO       # las rayas y los bordes de lo bloqueado
const NEGRO := PLACA.NEGRO           # el relleno de lo bloqueado
const REMACHE := PLACA.REMACHE
const TEXTO := PLACA.TEXTO
const TEXTO_SUAVE := PLACA.TEXTO_SUAVE
const AMARILLO := PLACA.AMARILLO     # lo ahorrado y los cuadraditos llenos
const RADIO := 24                    # del hexágono (de la punta de arriba al centro)
const ARRIBA := PLACA.ARRIBA         # lo alto de la franja de lo ahorrado
const CABECERA := 34                 # lo alto del emblema y el nombre de cada rama
const ANCHO_FICHA := 236

# Cómo se está moviendo el jugador por la pantalla: "raton" (la ficha sigue al ratón) o "foco" (el teclado o el mando: la
# ficha es la del talento marcado). Se queda al volver a montar la ventana después de comprar
static var modo := "raton"

var ordenador: Node
var s: Dictionary                    # el guardado
var botones := {}                    # id del talento → su botón
var centros := {}                    # id → el centro de su hexágono
var columnas := []                   # [x, ancho] de cada rama
var resetear: Button
var ficha: PanelContainer
var ficha_id := ""                   # el talento que enseña la ficha ("" = ninguno)
var ficha_desde := 0.0               # desde cuándo (en s): un toque del dedo justo al elegirlo no compra
var listo := {}                      # id → si al pulsarlo ya enseñaba su ficha (con el dedo, el segundo toque)


func montar(o: Node, guardado: Dictionary) -> void:
	ordenador = o
	s = guardado
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 380)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for t in Talentos.LISTA:
		var b := Button.new()
		b.name = "b_" + t.id
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		b.size = Vector2(RADIO * 2 - 4, RADIO * 2)
		for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
		b.focus_entered.connect(actualizar_ficha)
		b.focus_exited.connect(actualizar_ficha)
		b.button_down.connect(func(): listo[t.id] = ficha_id == t.id and ahora() - ficha_desde > 0.25)
		add_child(b)
		botones[t.id] = b
	montar_resetear()
	montar_ficha()
	for nombre in ["billete", "candado"] + Talentos.RAMAS.map(func(r): return r.icono) + Talentos.LISTA.map(func(t): return t.icono):
		icono(nombre)
	resized.connect(colocar)


# «Resetear talentos»: un botón de la chapa con las herramientas y su nombre (al pulsarlo, el ordenador pregunta con una
# ventanita: ordenador.preguntar_reseteo)
func montar_resetear() -> void:
	var marco := PanelContainer.new()
	marco.name = "resetear"
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#2f333a")
	estilo.border_color = REMACHE
	estilo.set_border_width_all(2)
	# más bajo y más estrecho que antes (11 nov: iba pegado arriba y abajo de la franja): icono de 24 y letra de 14
	estilo.set_content_margin_all(2)
	estilo.content_margin_left = 6
	estilo.content_margin_right = 6
	marco.add_theme_stylebox_override("panel", estilo)
	add_child(marco)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(fila)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", -2)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # el nombre, a la altura de la mitad del icono
	fila.add_child(textos)
	var se_puede := Talentos.se_puede_resetear(s)
	var herramientas := TextureRect.new()
	herramientas.texture = icono("herramientas")
	herramientas.custom_minimum_size = Vector2(24, 24)
	herramientas.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	herramientas.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	herramientas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	herramientas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	herramientas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	herramientas.modulate = Color.WHITE if se_puede else Color(0.6, 0.6, 0.6, 0.7)
	fila.add_child(herramientas)
	fila.move_child(herramientas, 0)
	var nombre := etiqueta(Idioma.t("Resetear talentos"), TEXTO if se_puede else TEXTO_SUAVE)
	nombre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nombre.add_theme_font_size_override("font_size", 14)
	textos.add_child(nombre)
	resetear = Button.new()
	resetear.name = "b_resetear"
	resetear.flat = true
	resetear.focus_mode = Control.FOCUS_ALL
	for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		resetear.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	marco.add_child(resetear)
	# marcado (con el ratón encima, el teclado o el mando): el borde en claro
	var marcar_borde := func():
		estilo.border_color = TEXTO if resetear.has_focus() or resetear.is_hovered() else REMACHE
	for senal in [resetear.focus_entered, resetear.focus_exited, resetear.mouse_entered, resetear.mouse_exited]:
		senal.connect(marcar_borde)


# La ficha: no se puede pulsar (el ratón la atraviesa), solo enseña
func montar_ficha() -> void:
	ficha = PanelContainer.new()
	ficha.name = "ficha"
	ficha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ficha.visible = false
	ficha.z_index = 1
	add_child(ficha)


func etiqueta(texto: String, color: Color, partir := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	if partir:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = ANCHO_FICHA - 16
	return l


func ahora() -> float:
	return Time.get_ticks_msec() / 1000.0


# ── Dónde va cada cosa (al cambiar de tamaño) ──

func colocar() -> void:
	var margen := 8.0
	var hueco := 4.0
	var ancho := (size.x - margen * 2 - hueco * 2) / 3.0
	columnas.clear()
	for k in 3:
		columnas.append([margen + k * (ancho + hueco), ancho])
	var arriba := ARRIBA + CABECERA + 4.0
	var fila := (size.y - arriba - 8.0) / 5.0
	var paso := minf(ancho / 3.0, 70.0)   # de un hexágono al de al lado
	for k in Talentos.RAMAS.size():
		var rama: Dictionary = Talentos.RAMAS[k]
		var medio: float = columnas[k][0] + ancho / 2.0
		for nivel in range(1, 6):
			var de_la_fila: Array = Talentos.LISTA.filter(func(t): return t.rama == rama.id and t.nivel == nivel)
			# tres: izquierda, centro y derecha; uno, en el centro; dos, encima de sus talentos (el 1.º sobre los dos de
			# su izquierda y el 2.º sobre el de la derecha, como los piden en el nivel 2)
			var sitios: Array = [-1.0, 0.0, 1.0] if de_la_fila.size() == 3 else ([0.0] if de_la_fila.size() == 1 else [-0.5, 1.0])
			for i in de_la_fila.size():
				var c := Vector2(roundf(medio + sitios[i] * paso), roundf(arriba + fila * (nivel - 0.5) - 3.0))
				centros[de_la_fila[i].id] = c
				botones[de_la_fila[i].id].position = c - botones[de_la_fila[i].id].size / 2.0
	var marco: Control = resetear.get_parent()
	marco.reset_size()
	marco.position = Vector2(size.x - margen - marco.size.x - 6, roundf((ARRIBA - marco.size.y) / 2.0) + 2)
	poner_vecinos()
	actualizar_ficha()
	queue_redraw()


# Con el teclado o el mando, a qué hexágono se pasa con cada flecha: el más cercano en esa dirección, de los que caen
# hacia allí más que de lado. Arriba del todo, a «Resetear talentos»; abajo del todo, no se mueve (si no, Godot buscaría
# solo y se iría a los iconos del escritorio). A la izquierda de Militar sí se sale a ellos, como en los demás programas
func poner_vecinos() -> void:
	var sitios := {}   # botón → su centro
	for id in botones:
		sitios[botones[id]] = centros[id]
	for b: Button in sitios:
		for lado in [[Vector2.UP, "focus_neighbor_top"], [Vector2.DOWN, "focus_neighbor_bottom"],
				[Vector2.LEFT, "focus_neighbor_left"], [Vector2.RIGHT, "focus_neighbor_right"]]:
			var mejor: Button = null
			var menor := INF
			for o: Button in sitios:
				var d: Vector2 = sitios[o] - sitios[b]
				var hacia := d.dot(lado[0])
				var de_lado := absf(d.dot(Vector2(lado[0].y, lado[0].x)))
				if hacia > 4.0 and de_lado < hacia * (2.5 if lado[0].y != 0 else 0.6) and hacia + de_lado * 2.0 < menor:
					menor = hacia + de_lado * 2.0
					mejor = o
			if mejor:
				b.set(lado[1], b.get_path_to(mejor))
			elif lado[0] == Vector2.UP:
				b.set(lado[1], b.get_path_to(resetear))
			elif lado[0] != Vector2.LEFT:
				b.set(lado[1], b.get_path_to(b))
	resetear.focus_neighbor_bottom = resetear.get_path_to(botones[Talentos.LISTA.filter(func(t): return t.rama == "quimico")[1].id])
	resetear.focus_neighbor_top = resetear.get_path_to(resetear)
	resetear.focus_neighbor_right = resetear.get_path_to(resetear)


# ── El dibujo ──

func _draw() -> void:
	var fuente := get_theme_default_font()
	PLACA.dibujar(self, size)   # la chapa, con su marco y sus remaches
	PLACA.dibujar_ahorrado(self, fuente, s.dolares)
	if columnas.is_empty():
		return
	for k in Talentos.RAMAS.size():
		dibujar_rama(Talentos.RAMAS[k], columnas[k][0], columnas[k][1], fuente)


func dibujar_rama(rama: Dictionary, x: float, ancho: float, fuente: Font) -> void:
	var color: Array = COLORES[rama.id]
	var alto := size.y - ARRIBA - 8
	draw_rect(Rect2(x, ARRIBA, ancho, alto), color[3])
	# el recuadro de su color, alrededor de toda la rama
	draw_rect(Rect2(x, ARRIBA, ancho, 2), color[1])
	draw_rect(Rect2(x, ARRIBA + alto - 2, ancho, 2), color[1])
	draw_rect(Rect2(x, ARRIBA, 2, alto), color[1])
	draw_rect(Rect2(x + ancho - 2, ARRIBA, 2, alto), color[1])
	# el emblema redondo, el nombre y los puntos puestos
	var e := Vector2(x + 22, ARRIBA + CABECERA / 2.0 + 2)
	draw_circle(e, 16, color[1], true, -1.0, false)
	draw_circle(e, 13, color[2], true, -1.0, false)
	draw_texture_rect(icono(rama.icono), en_caja(icono(rama.icono), e, 24.0), false)
	draw_string(fuente, Vector2(x + 44, e.y + 6), Talentos.nombre_rama(rama.id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color[0])
	var puestos := 0
	var total := 0
	for t in Talentos.LISTA:
		if t.rama == rama.id:
			puestos += Talentos.nivel_de(s, t.id)
			total += t.max
	draw_string(fuente, Vector2(x, e.y + 6), "%d/%d" % [puestos, total], HORIZONTAL_ALIGNMENT_RIGHT, ancho - 8, 16, TEXTO_SUAVE)   # no-tr
	# las rayas: del que pide al pedido, primero (que queden debajo de los hexágonos)
	for t in Talentos.LISTA:
		if t.rama != rama.id:
			continue
		for p in Talentos.requisitos(t.id):
			var a: Vector2 = centros[p]
			var b: Vector2 = centros[t.id]
			var lleno: bool = Talentos.nivel_de(s, p) >= Talentos.talento(p).max
			var c: Color = color[0] if lleno else APAGADO
			var medio := roundf((a.y + RADIO + b.y - RADIO) / 2.0) + 3.0
			draw_rect(Rect2(a.x - 1, a.y + RADIO + 8, 2, medio - a.y - RADIO - 7), c)
			draw_rect(Rect2(minf(a.x, b.x) - 1, medio - 1, absf(b.x - a.x) + 2, 2), c)
			draw_rect(Rect2(b.x - 1, medio, 2, b.y - RADIO - medio), c)
	for t in Talentos.LISTA:
		if t.rama == rama.id:
			dibujar_talento(t, color)


func dibujar_talento(t: Dictionary, color: Array) -> void:
	var c: Vector2 = centros[t.id]
	var n := Talentos.nivel_de(s, t.id)
	var motivo := Talentos.motivo(s, t.id)
	var borde: Color = APAGADO
	var relleno: Color = NEGRO
	if motivo == "max":
		borde = color[0]
		relleno = color[1]
	elif motivo != "bloqueado":
		borde = color[1] if n == 0 else color[0]
		relleno = color[2]
	var r := RADIO
	if t.id == ficha_id or (botones[t.id].has_focus() and modo == "foco"):
		borde = Color.WHITE
		r += 2
	hexagono(c, r, borde)
	hexagono(c, r - 3, relleno)
	if motivo == "bloqueado":
		draw_texture_rect(icono("candado"), Rect2(c - Vector2(16, 16), Vector2(32, 32)), false, Color(0.55, 0.55, 0.55, 0.8))
	else:
		draw_texture_rect(icono(t.icono), en_caja(icono(t.icono), c, 32.0), false)
	# los cuadraditos de nivel, debajo
	var ancho_pips: float = t.max * 6 - 2
	for i in t.max:
		draw_rect(Rect2(c.x - ancho_pips / 2.0 + i * 6, c.y + RADIO + 2, 4, 4), AMARILLO if i < n else APAGADO)


# Un hexágono de punta (lados rectos a izquierda y derecha), sin suavizar: con escalones de píxel
func hexagono(c: Vector2, r: float, color: Color) -> void:
	var h := roundf(r * 0.87)
	var m := roundf(r / 2.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(h, -m), c + Vector2(h, m), c + Vector2(0, r),
		c + Vector2(-h, m), c + Vector2(-h, -m)]), color)


# El sitio de un icono dentro de un cuadrado de lado «lado» con centro «c», sin estirarlo: los de GPT (talento-*.png)
# no siempre son cuadrados, y el lado más largo llena el cuadrado
func en_caja(tex: Texture2D, c: Vector2, lado: float) -> Rect2:
	var t := tex.get_size() * (lado / maxf(tex.get_width(), tex.get_height()))
	return Rect2(c - t / 2.0, t)


# Los iconos se cargan una vez (assets/ui/iconos)
var iconos := {}
func icono(nombre: String) -> Texture2D:
	if not iconos.has(nombre):
		iconos[nombre] = load("res://assets/ui/iconos/%s.png" % nombre)
	return iconos[nombre]


# ── La ficha ──

func _input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var antes := modo
	if evento is InputEventKey or evento is InputEventJoypadButton or (evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.5):
		modo = "foco"
	elif evento is InputEventMouseMotion or evento is InputEventMouseButton or evento is InputEventScreenTouch:
		modo = "raton"
	if evento is InputEventMouseMotion or modo != antes:
		actualizar_ficha()


# Al subir un talento, la ventana se vuelve a montar y la ficha nueva no sabía dónde estaba el ratón hasta moverlo: se
# iba. Mirándolo cada fotograma, sale en cuanto la ventana está colocada, con el nivel nuevo (11 nov)
func _process(_delta: float) -> void:
	if modo == "raton" and is_visible_in_tree():
		actualizar_ficha()
	if not ordenador.colocando:
		seguir = ""


# El talento recién subido (ordenador.subir): mientras la ventana nueva se coloca, su ficha sigue a la vista, sin parpadear
static var seguir := ""


# El talento que tiene que enseñar la ficha: con el ratón, el que está debajo; con el teclado, el mando o el dedo, el
# marcado (el toque marca el botón, pero no mueve el ratón de Godot: se quedaría en el sitio de antes)
func quien() -> String:
	var con_dedo := Tactil.activo and Tactil.con_dedo
	if modo == "raton" and not con_dedo and ordenador.colocando and centros.has(seguir):
		return seguir
	if modo == "raton" and not con_dedo and not ordenador.colocando:
		var raton := get_local_mouse_position()
		for id in centros:
			if raton.distance_to(centros[id]) <= RADIO:
				return id
	if modo == "foco" or con_dedo:
		var foco := get_viewport().gui_get_focus_owner()
		for id in botones:
			if botones[id] == foco:
				return id
	return ""


func actualizar_ficha() -> void:
	var id := quien()
	if id == ficha_id:
		return
	ficha_id = id
	ficha_desde = ahora()
	queue_redraw()
	ficha.visible = id != ""
	if id == "":
		return
	llenar_ficha(id)
	# a la derecha del hexágono, o a la izquierda si no cabe; sin salirse por arriba ni por abajo
	ficha.reset_size()
	var c: Vector2 = centros[id]
	var x := c.x + RADIO + 6
	if x + ficha.size.x > size.x - 6:
		x = c.x - RADIO - 6 - ficha.size.x
	ficha.position = Vector2(x, clampf(c.y - 30, 6, size.y - ficha.size.y - 6))


# Lo que pone la ficha de un talento, línea a línea, cada una con su color: qué hace (claro), cómo va (del color de la
# rama) y qué abre (gris). Lo usan también las pruebas
func lineas_ficha(id: String) -> Array:
	var t := Talentos.talento(id)
	var n := Talentos.nivel_de(s, id)
	var motivo := Talentos.motivo(s, id)
	var color: Color = COLORES[t.rama][0]
	var lineas := [[Talentos.desc_de(id), TEXTO]]
	var ahora_da := Talentos.efecto(id, n)
	if motivo == "bloqueado":
		lineas.append([Idioma.t("Necesitas %s al máximo") % Talentos.nombres(Talentos.faltan(s, id)), color])
	elif motivo == "max":
		lineas.append([Idioma.t("¡Al máximo! %s") % ahora_da if ahora_da != "" else Idioma.t("¡Al máximo!"), color])
	elif n > 0 and ahora_da != "":
		lineas.append([Idioma.t("Ahora: %s · Con otro: %s") % [ahora_da, Talentos.efecto(id, n + 1)], color])
	# (lo que abre al llenarlo ya no sale: lo dice la ficha del talento siguiente, con lo que pide, 11 nov)
	return lineas


# El pie de la ficha: cómo se compra y cuánto cuesta (o por qué no se puede)
func pie_ficha(id: String) -> String:
	var motivo := Talentos.motivo(s, id)
	var precio := Talentos.precio(id)
	match motivo:
		"max": return Idioma.t("MÁX")
		"bloqueado": return Idioma.t("Bloqueado")
		"sin_dinero": return Idioma.t("Cuesta $%d") % precio   # (solo el precio, sin lo que falta: 11 nov)
	if Tactil.activo and Tactil.con_dedo:
		return Idioma.t("Toca otra vez: comprar · $%d") % precio
	if Controles.con_mando:
		return Idioma.t("A: comprar · $%d") % precio
	if modo == "foco":
		return Idioma.t("Intro: comprar · $%d") % precio
	return Idioma.t("Clic: comprar · $%d") % precio


func llenar_ficha(id: String) -> void:
	var t := Talentos.talento(id)
	var color: Array = COLORES[t.rama]
	for hijo in ficha.get_children():
		hijo.free()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#101215")
	estilo.border_color = color[1]
	estilo.set_border_width_all(2)
	ficha.add_theme_stylebox_override("panel", estilo)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.custom_minimum_size.x = ANCHO_FICHA
	ficha.add_child(columna)
	# la cabecera: el nombre y los puntos
	var cabecera := PanelContainer.new()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = color[2]
	fondo.set_content_margin_all(4)
	fondo.content_margin_left = 8
	fondo.content_margin_right = 8
	cabecera.add_theme_stylebox_override("panel", fondo)
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(cabecera)
	var fila := HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera.add_child(fila)
	var nombre := etiqueta(Talentos.nombre_de(id), Color.WHITE)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	fila.add_child(etiqueta("%d/%d" % [Talentos.nivel_de(s, id), t.max], AMARILLO))   # no-tr
	var lineas := lineas_ficha(id)
	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 8)
	columna.add_child(margen)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 4)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(textos)
	for linea in lineas:
		textos.add_child(etiqueta(linea[0], linea[1], true))
	# el pie: un botón pintado (el de verdad es el hexágono), del color de la rama si se puede comprar
	var motivo := Talentos.motivo(s, id)
	var pie := etiqueta(pie_ficha(id), Color.WHITE if motivo == "" else TEXTO_SUAVE)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fondo_pie := StyleBoxFlat.new()
	fondo_pie.bg_color = color[1] if motivo == "" else Color("#2f333a")
	fondo_pie.set_content_margin_all(4)
	pie.add_theme_stylebox_override("normal", fondo_pie)
	var abajo := MarginContainer.new()
	abajo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "bottom"]:
		abajo.add_theme_constant_override("margin_" + lado, 6)
	abajo.add_child(pie)
	columna.add_child(abajo)


# Al pulsar un hexágono: con el dedo, si su ficha no estaba ya a la vista, el toque solo la enseña
func al_pulsar(id: String) -> void:
	if Tactil.activo and Tactil.con_dedo and not listo.get(id, false):
		return
	ordenador.subir(id)
