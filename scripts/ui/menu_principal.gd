# El menú principal (showMenu de src/ui.js): el logo, JUGAR, Tutorial (tutorial.gd), Opciones (opciones.gd), pantalla
# completa y salir, y el récord. Es la escena con la que arranca el juego. JUGAR abre "Elige edificio" (showBuildings
# de src/ui.js): una tarjeta por edificio (edificios.gd) con su progreso; el elegido lleva a la partida
# (escenas/partida.tscn).
# Debajo de cada tarjeta, el nivel de alerta con el que se juega (alerta.gd): se cambia con las flechas, entre los
# que estén abiertos, y se apunta en el guardado para la próxima vez.
# Con "-- --captura" saca fotos (captura-menu.png y captura-edificios.png) y pasa sola a la partida, para seguir
# con su prueba; con "--edificio centro" además, entra en el centro comercial aunque esté cerrado. Con
# "--alerta 3", la foto de "Elige edificio" sale con todas las alertas abiertas y la 3 elegida (sin guardarlo). Con
# "--edificios", solo esa pantalla (como está en el guardado de prueba y con el centro comercial cerrado) y se cierra.
extends Control

const LOGO := preload("res://assets/ui/logo.png")
const ANCHO_TARJETA := 312   # el ancho de una tarjeta de "Elige edificio": que quepa el selector de alerta de debajo (306), si no ensancha la suya
const ANCHO_TEXTO := ANCHO_TARJETA - 32   # lo que queda para sus textos, con 16 de margen a cada lado

var centro: CenterContainer       # el menú
var edificios: CenterContainer    # la pantalla "Elige edificio" (se crea al pulsar JUGAR)
var tarjetas: HBoxContainer
var alertas := {}                  # la alerta elegida en cada edificio (alerta.gd)
var centro_cerrado := false        # solo para la foto de "--edificios": los Apartamentos sin completar, el centro con candado


func _ready() -> void:
	Tactil.preparar(get_tree())   # en el móvil, la pantalla sin redondear
	Controles.aplicar()   # las teclas cambiadas en Opciones
	theme = Tema.crear()
	Sonido.musica("menu")
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.04, 0.06)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 12)
	centro.add_child(columna)

	# El logo es pixel art pequeño (119×75): se amplía ×3 sin suavizar
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.custom_minimum_size = LOGO.get_size() * 3
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(logo)
	var lema := Label.new()
	lema.text = "Limpia el edificio de zombis, planta a planta"
	lema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(lema)

	var jugar := boton(columna, "JUGAR", elegir_edificio, "BotonGrande")
	# Tutorial y Opciones, uno al lado del otro (uno debajo del otro, el menú ya no cabe en la pantalla)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 6)
	columna.add_child(fila)
	var tutorial := boton(fila, "Tutorial", func(): pass)
	tutorial.custom_minimum_size.x = 127
	tutorial.pressed.connect(func():
		Tutorial.lista(self, centro).cerrado.connect(tutorial.grab_focus))
	var opciones := boton(fila, "Opciones", func(): pass)
	opciones.custom_minimum_size.x = 127
	opciones.pressed.connect(func():
		Opciones.abrir(self, centro).cerrado.connect(opciones.grab_focus))
	if Tactil.puede_pantalla_completa():   # en iPhone no hay
		boton(columna, "Pantalla completa", Tactil.pantalla_completa)
	if not OS.has_feature("web"):
		boton(columna, "Salir", get_tree().quit)

	var ayuda := PanelContainer.new()
	ayuda.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(ayuda)
	var texto := Label.new()
	texto.theme_type_variation = "Sub"
	texto.text = ("Limpia cada apartamento para abrir su puerta y caza al zombi que lleva la llave de la portera\n"
		+ "Los controles y el modo de atacar están en Opciones")
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_child(texto)

	var s := Guardado.cargar()
	if s.mejor_planta > 0 or s.dolares > 0:
		var record := Tema.icono_y_texto("trofeo", "Mejor planta alcanzada: %d   ·   Dólares ahorrados: $%d" % [s.mejor_planta, s.dolares])
		record.alignment = BoxContainer.ALIGNMENT_CENTER
		columna.add_child(record)

	jugar.grab_focus.call_deferred()
	if Captura.activa():
		Captura.vigilar()
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-menu.png")
		elegir_edificio()
		await get_tree().create_timer(0.3).timeout
		var edificio := Captura.dato("--edificio", "apartamentos")
		if "--reto" in OS.get_cmdline_user_args():   # la prueba del reto del día: la tarjeta con su botón y su marca
			Captura.foto("captura-reto-tarjeta.png")
			jugar_reto(edificio)
		else:
			Captura.foto("captura-edificios.png")
			if "--edificios" in OS.get_cmdline_user_args():   # solo esta pantalla: otra foto con el centro cerrado, y se cierra
				centro_cerrado = true
				poner_tarjetas()
				await get_tree().create_timer(0.3).timeout
				Captura.foto("captura-edificios-cerrado.png")
				get_tree().quit()
				return
			jugar_partida(edificio)


func boton(caja: Container, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = variacion
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size.x = 260
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


# "Elige edificio": una tarjeta por edificio, con su progreso en el guardado. Los que aún no se pueden jugar
# (el centro comercial, hasta completar los Apartamentos) salen con candado
func elegir_edificio() -> void:
	centro.hide()
	tutorial_alerta.call_deferred()
	if edificios:
		edificios.show()
		primera_tarjeta().grab_focus.call_deferred()
		return
	edificios = CenterContainer.new()
	edificios.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(edificios)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 18)
	edificios.add_child(columna)
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = "Elige edificio"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	tarjetas = HBoxContainer.new()
	tarjetas.alignment = BoxContainer.ALIGNMENT_CENTER
	tarjetas.add_theme_constant_override("separation", 20)
	columna.add_child(tarjetas)
	poner_tarjetas()
	var volver := boton(columna, "Volver", volver_al_menu)
	volver.custom_minimum_size.x = 180
	primera_tarjeta().grab_focus.call_deferred()


# Las tarjetas, con lo que dice el guardado (se rehacen al pulsar N, la tecla de prueba que lo abre todo)
func poner_tarjetas() -> void:
	for caja in tarjetas.get_children():
		caja.free()
	var s := Guardado.cargar()
	if centro_cerrado:
		Guardado.edificio(s, "apartamentos").completado = false   # para la foto (no se guarda)
	if Captura.activa() and Captura.dato("--alerta") != "":
		for id in Edificios.LISTA:   # para la foto: todas abiertas y la pedida, elegida (no se guarda)
			Guardado.edificio(s, id).alerta_max = Alerta.MAX
			s.edificios[id].alerta = int(Captura.dato("--alerta"))
	if Captura.activa() and "--reto" in OS.get_cmdline_user_args():
		for id in Edificios.LISTA:   # para la foto: una marca de hoy inventada (no se guarda)
			var f := Reto.ficha(s, id, Reto.hoy())
			f.intentos = 2
			f.planta = 3
	for id in Edificios.LISTA:
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 6)
		caja.add_child(tarjeta(id, s))
		if Edificios.abierto(s, id):
			selector_alerta(caja, id, s.edificios.get(id, Guardado.EDIFICIO))
			boton_reto(caja, id, s)
		tarjetas.add_child(caja)


func primera_tarjeta() -> Button:
	return tarjetas.get_child(0).get_child(0)


# El alto de "n" líneas del texto gris de debajo de las tarjetas (la letra y los 3 que deja Label entre línea y línea)
func alto_lineas(n: int) -> float:
	return n * (get_theme_default_font().get_height(get_theme_default_font_size()) + 3.0)


# Debajo de la tarjeta: "< Alerta 2 >" y lo que trae. Sin ninguna abierta, solo cómo se abre la primera
func selector_alerta(caja: VBoxContainer, id: String, p: Dictionary) -> void:
	var maximo: int = p.alerta_max
	alertas[id] = clampi(p.alerta, 0, maximo)
	var explica := Label.new()
	explica.theme_type_variation = "Sub"
	explica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explica.custom_minimum_size = Vector2(300, 0)
	if maximo == 0:
		explica.text = "Complétalo para abrir la Alerta 1"
		explica.modulate = Color(1, 1, 1, 0.6)
		caja.add_child(explica)
		return
	# lo que trae cada alerta ocupa de una a tres líneas: siempre el alto de tres, para que el botón del reto de cada
	# edificio quede a la misma altura que el de los demás
	explica.custom_minimum_size.y = alto_lineas(3)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	caja.add_child(explica)
	var menos := Button.new()
	menos.text = "<"
	menos.custom_minimum_size = Vector2(44, 0)
	fila.add_child(menos)
	var nombre := Tema.icono_y_texto("alerta", "", 24)
	nombre.custom_minimum_size.x = 170
	nombre.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_child(nombre)
	var mas := Button.new()
	mas.text = ">"
	mas.custom_minimum_size = Vector2(44, 0)
	fila.add_child(mas)
	var texto: Label = nombre.get_child(nombre.get_child_count() - 1)
	var poner := func():
		var n: int = alertas[id]
		texto.text = "%s (de %d)" % [Alerta.nombre(n), maximo]
		nombre.get_child(0).modulate = Color.WHITE if n > 0 else Color(1, 1, 1, 0.35)
		explica.text = Alerta.resumen(n)
		menos.disabled = n <= 0
		mas.disabled = n >= maximo
	poner.call()
	var cambiar := func(paso: int):
		alertas[id] = clampi(alertas[id] + paso, 0, maximo)
		poner.call()
		Sonido.tocar("click")
		var n: int = alertas[id]
		if not Captura.activa():
			Guardado.cambiar(func(g): Guardado.edificio(g, id).alerta = n)
	menos.pressed.connect(cambiar.bind(-1))
	mas.pressed.connect(cambiar.bind(1))


# Debajo del selector de alerta: el botón del reto del día (reto.gd) y, debajo, la regla de hoy y tu marca
func boton_reto(caja: VBoxContainer, id: String, s: Dictionary) -> void:
	var b := Button.new()
	b.text = "Reto del día"
	b.icon = load("res://assets/ui/iconos/trofeo.png")
	b.expand_icon = true
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_constant_override("icon_max_width", 24)
	b.custom_minimum_size.x = 220
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(jugar_reto.bind(id))
	caja.add_child(b)
	var explica := Label.new()
	explica.theme_type_variation = "Sub"
	explica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explica.custom_minimum_size = Vector2(300, 0)
	explica.text = Reto.texto_tarjeta(Reto.ficha(s, id, Reto.hoy()))
	caja.add_child(explica)


# El reto del día de un edificio (reto.gd): el de hoy, sin alerta. En la prueba, "--reto <regla>" fuerza esa regla
func jugar_reto(id: String) -> void:
	Edificios.elegido = id
	Alerta.nivel = 0
	Reto.empezar(id)
	if Captura.activa() and Captura.dato("--reto") in Reto.REGLAS:
		Reto.regla = Captura.dato("--reto")
	Captura.ir_a_la_partida()


# Con el primer edificio completado (ya hay alguna alerta abierta), la primera vez: el tutorial de la alerta y el reto
# del día (tutoriales.gd)
func tutorial_alerta() -> void:
	if Captura.activa() or not Tutoriales.toca("alerta"):
		return
	if not Guardado.cargar().edificios.values().any(func(p): return int(p.alerta_max) > 0):
		return
	Tutoriales.apuntar("alerta")
	Tutorial.ventana(self, "alerta").cerrado.connect(func(): primera_tarjeta().grab_focus())


func volver_al_menu() -> void:
	edificios.hide()
	centro.show()
	centro.find_children("*", "Button", true, false)[0].grab_focus()


# Esc (o B en el mando) en "Elige edificio": vuelve al menú. N (tecla de prueba): abre todos los edificios
# hasta cerrar el juego, sin completar los anteriores (no se guarda nada)
func _unhandled_input(evento: InputEvent) -> void:
	if not (edificios and edificios.visible):
		return
	if evento.is_action_pressed("ui_cancel"):
		volver_al_menu()
		get_viewport().set_input_as_handled()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_N and not Edificios.abrir_todo:
		Edificios.abrir_todo = true
		poner_tarjetas()
		Sonido.tocar("click")
		primera_tarjeta().grab_focus()
		get_viewport().set_input_as_handled()


# La tarjeta de un edificio: un botón grande con su dibujo, su nombre, su descripción y cómo te ha ido en él
func tarjeta(id: String, s: Dictionary) -> Button:
	var datos: Dictionary = Edificios.LISTA[id]
	var abierto := Edificios.abierto(s, id)
	var p: Dictionary = s.edificios.get(id, Guardado.EDIFICIO)
	var b := Button.new()
	var lineas := lineas_descripcion()
	b.custom_minimum_size = Vector2(ANCHO_TARJETA, 250 + alto_lineas(maxi(lineas - 3, 0)))   # 250 da para tres líneas de descripción
	b.disabled = not abierto
	b.focus_mode = Control.FOCUS_ALL if abierto else Control.FOCUS_NONE
	b.pressed.connect(jugar_partida.bind(id))
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.offset_left = 16
	caja.offset_right = -16
	caja.offset_top = 14
	caja.offset_bottom = -14
	caja.alignment = BoxContainer.ALIGNMENT_BEGIN   # desde arriba: si no, la tarjeta con menos líneas se corre
	caja.add_theme_constant_override("separation", 8)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caja)
	var dibujo := TextureRect.new()
	dibujo.texture = load("res://assets/ui/iconos/%s.png" % ("candado" if not abierto else id))
	dibujo.custom_minimum_size = Vector2(64, 64)
	dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dibujo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dibujo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(dibujo)
	var textos := [[datos.nombre, ""], [datos.desc, "Sub"]]
	if abierto:
		var veces: int = p.partidas
		textos.append(["%d plantas y azotea · %d intento%s" % [Planta.PLANTAS - 1, veces, "" if veces == 1 else "s"], "Sub"])
		var progreso := "¡Sin explorar!"
		if p.completado:
			var t: float = p.mejor_tiempo
			progreso = "Completado ×%d%s" % [p.victorias, " · mejor tiempo %d:%02d" % [int(t) / 60, int(t) % 60] if t > 0.0 else ""]
		elif veces > 0:
			progreso = "Has llegado a la planta %d de %d" % [p.mejor_planta, Planta.PLANTAS]
		textos.append([progreso, ""])
	else:
		textos.append(["Completa %s para abrirlo" % Edificios.LISTA[datos.abre].el_nombre, ""])
	for i in textos.size():
		var t: Array = textos[i]
		var l := Label.new()
		l.text = t[0]
		l.theme_type_variation = t[1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 260
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == 1:   # la descripción
			l.custom_minimum_size.y = alto_lineas(lineas)   # el hueco de la más larga: lo de debajo no se corre
		if not abierto:
			l.modulate = Color(1, 1, 1, 0.6)
		caja.add_child(l)
	return b


# Cuántas líneas ocupa la descripción más larga de los edificios, medidas con la letra del texto gris (no hace falta que
# esté ya colocada). Todas las tarjetas dejan ese hueco, así lo de debajo queda a la misma altura en todas
func lineas_descripcion() -> int:
	var fuente := get_theme_font("font", "Sub")
	var tam := get_theme_font_size("font_size", "Sub")
	var cortes := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE   # los de AUTOWRAP_WORD_SMART
	var lineas := 1
	for id in Edificios.LISTA:
		var alto := fuente.get_multiline_string_size(Edificios.LISTA[id].desc, HORIZONTAL_ALIGNMENT_CENTER, ANCHO_TEXTO, tam, -1, cortes).y
		lineas = maxi(lineas, roundi(alto / fuente.get_height(tam)))
	return lineas


func jugar_partida(id := "apartamentos") -> void:
	Edificios.elegido = id
	Alerta.nivel = alertas.get(id, 0)
	Reto.quitar()   # (por si la partida anterior fue el reto del día)
	# con --captura, la partida de prueba: la misma, con las fotos (pruebas/partida_prueba.gd)
	Captura.ir_a_la_partida()

