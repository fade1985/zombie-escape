# El menú principal (showMenu de src/ui.js): el logo, JUGAR, Opciones (opciones.gd, con el Tutorial y la pantalla
# completa dentro) y salir (en la web, una despedida: M46). JUGAR abre
# «Elige partida» (huecos.gd): cambiar de hueco, o borrar uno para empezar de cero. Con una partida a medias (partida_guardada.gd), encima de JUGAR sale «Continuar
# partida» con su edificio y su planta. Es la escena con la que arranca el juego. Elegida una partida sin nada a medias, se abre "Elige edificio" (showBuildings
# de src/ui.js): una tarjeta por edificio (edificios.gd) con su progreso; el elegido lleva a la partida
# (escenas/partida.tscn).
# Debajo de cada tarjeta, el nivel de alerta con el que se juega (alerta.gd): se cambia con las flechas, entre los
# que estén abiertos, y se apunta en el guardado para la próxima vez.
# Con "-- --captura" saca fotos (captura-menu.png y captura-edificios.png) y pasa sola a la partida, para seguir
# con su prueba; con "--edificio centro" además, entra en el centro comercial aunque esté cerrado. Con
# "--alerta 3", la foto de "Elige edificio" sale con todas las alertas abiertas y la 3 elegida (sin guardarlo). Con
# "--edificios", solo esa pantalla (como está en el guardado de prueba y con el centro comercial cerrado) y se cierra.
extends Control

# el título y el fondo, de GPT (tools/menu_gpt.py); el logo viejo, assets/ui/logo.png, sigue en el trailer
const SOBRE_MARCO := 16   # el cuadro del reto acaba esto por encima del final de la tarjeta del edificio (su marco)
const TAM_RETO := 17   # la letra lisa (Rubik) del reto del día: su cuadro y lo de debajo del botón (12 nov)
const PLACA := preload("res://scripts/ui/chapa.gd")   # los colores de la chapa (también los del cuadro del reto)
const LOGO := preload("res://assets/ui/titulo.png")
const FONDO := preload("res://assets/ui/menu-fondo.png")
const ANCHO_TARJETA := 312   # el ancho de una tarjeta de "Elige edificio": que quepa el selector de alerta de debajo (306), si no ensancha la suya
const ANCHO_TEXTO := ANCHO_TARJETA - 32   # lo que queda para sus textos, con 16 de margen a cada lado

var centro: CenterContainer       # el menú
var edificios: CenterContainer    # la pantalla "Elige edificio" (se crea al pulsar JUGAR)
var tarjetas: HBoxContainer
var alertas := {}                  # la alerta elegida en cada edificio (alerta.gd)
# solo para las fotos de "--edificios" (no se guarda): los requisitos de los Apartamentos para abrir el centro comercial,
# "nada" (ninguno: sin completar, sin páginas y sin vídeos), "medias" (completado, 2 páginas y 1 vídeo) o "todo"
var foto_requisitos := ""


func _ready() -> void:
	Tactil.preparar()   # en el móvil, la pantalla sin redondear
	Controles.aplicar()   # las teclas cambiadas en Opciones
	theme = Tema.crear()
	Sonido.edificio = ""   # (fuera de la partida, la de los menús)
	Sonido.musica("menu")
	Calentador.empezar(self)   # los shaders grandes, antes de jugar
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.04, 0.06)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	# el portal de noche con Johnny de espaldas (480 × 320, ×2 sin suavizar): llena la pantalla, recortando lo que sobre
	var portal := TextureRect.new()
	portal.texture = FONDO
	portal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(portal)
	centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	# fuera del menú (Elige edificio, partidas guardadas, despedida) el fondo se oscurece, para que se lean los textos sueltos
	centro.visibility_changed.connect(func(): portal.modulate = Color.WHITE if centro.visible else Color(0.35, 0.35, 0.4))
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 18)   # (12 hasta el 9 nov: los botones iban muy juntos)
	centro.add_child(columna)

	# El título (300 × 100): se amplía ×2 sin suavizar
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.custom_minimum_size = LOGO.get_size() * 2
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(logo)
	# (debajo del título iba el lema «Limpia el edificio de zombis, planta a planta»: quitado el 8 nov)

	var foto := PartidaGuardada.guardada()
	var seguir: Button = null
	var donde := Label.new()
	if not foto.is_empty():
		seguir = boton(columna, Idioma.t("Continuar partida"), PartidaGuardada.seguir.bind(foto), "BotonGrande")
		var azotea: bool = Edificios.datos(foto.edificio).get("azotea", false) and foto.planta == Planta.PLANTAS
		donde.theme_type_variation = "Sub"
		donde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		donde.text = "%s · %s" % [Idioma.t(Edificios.datos(foto.edificio).nombre),
			Planta.nombre_de({"num": foto.planta, "azotea": azotea, "edificio": foto.edificio})] + (" · " + Idioma.t("Reto del día") if foto.reto.activo else "")
		columna.add_child(donde)
	# JUGAR abre «Elige partida» (huecos.gd, desde el 8 nov): la que esté a medias se sigue y las demás pasan a «Elige edificio»
	var jugar := boton(columna, Idioma.t("JUGAR"), abrir_huecos, "BotonGrande")
	jugar.pressed.connect(Sonido.grunir)   # el gruñido de zombi: solo aquí (11 nov, a petición del dueño)
	# Opciones (con el Tutorial y la pantalla completa dentro) y Salir, grandes como JUGAR
	var opciones := boton(columna, Idioma.t("Opciones"), func(): pass, "BotonGrande")
	opciones.pressed.connect(func():
		var idioma_antes := Idioma.actual
		Opciones.abrir(self, centro).cerrado.connect(func():
			if Idioma.actual != idioma_antes:   # el menú escribió sus textos al montarse: se monta otra vez
				get_tree().reload_current_scene()
			else:
				opciones.grab_focus()))
	boton(columna, Idioma.t("Salir"), salir, "BotonGrande")

	# (debajo de los botones iba un marco con consejos para jugar: quitado el 9 nov)

	# (debajo de Salir iban la mejor planta y los dólares ahorrados: quitados el 8 nov, a petición del dueño)

	(seguir if seguir else jugar).grab_focus.call_deferred()
	# el aviso de fotosensibilidad, encima de todo, la primera vez que sale el menú desde que se abre el juego (aviso_luces.gd)
	if not Captura.activa() or "--aviso" in OS.get_cmdline_user_args():
		AvisoLuces.poner(self)
	if Huecos.a_edificios:   # se acaba de elegir en «Elige partida» una partida sin nada a medias
		Huecos.a_edificios = false
		elegir_edificio.call_deferred()
	if Captura.activa():
		Captura.vigilar()
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-menu.png")
		if "--mando" in OS.get_cmdline_user_args():   # A y B del mando en este menú; luego sigue a la partida, que hace el resto (pruebas/prueba_mando.gd)
			await PruebaMando.menu_principal(self)
		if "--grunido" in OS.get_cmdline_user_args():   # el gruñido de JUGAR (pruebas/prueba_grunido.gd)
			PruebaGrunido.probar(self)
			get_tree().quit()
			return
		if "--aviso" in OS.get_cmdline_user_args():   # el aviso de fotosensibilidad (pruebas/prueba_aviso.gd)
			await PruebaAviso.probar(self)
			get_tree().quit()
			return
		if "--letras" in OS.get_cmdline_user_args():   # qué letras de las traducciones no tiene ninguna fuente (pruebas/prueba_letras.gd)
			PruebaLetras.probar()
			get_tree().quit()
			return
		if "--tildes" in OS.get_cmdline_user_args():   # una foto ampliada de las tildes y los ¿ ¡ en cada idioma (pruebas/prueba_letras.gd)
			await PruebaLetras.tildes(self)
			get_tree().quit()
			return
		if "--medidas" in OS.get_cmdline_user_args():   # los textos cortos que se pasan de ancho en cada idioma (pruebas/prueba_letras.gd)
			PruebaLetras.medidas()
			get_tree().quit()
			return
		if "--huecos" in OS.get_cmdline_user_args():   # los tres huecos de guardado (pruebas/prueba_huecos.gd)
			await PruebaHuecos.probar(self)
			get_tree().quit()
			return
		if "--despedida" in OS.get_cmdline_user_args():   # la despedida de «Salir» en la web (aquí, aunque no sea la web)
			despedida()
			await get_tree().create_timer(0.4).timeout
			Captura.foto("captura-despedida.png")
			get_tree().quit()
			return
		if "--idioma" in OS.get_cmdline_user_args():   # solo las pantallas del menú en el idioma de la prueba (pruebas/prueba_idioma.gd)
			await PruebaIdioma.probar(self)
			get_tree().quit()
			return
		if seguir and "--continuar" in OS.get_cmdline_user_args():   # la vuelta de la prueba de la partida a medias
			PartidaGuardada.seguir(foto)
			return
		elegir_edificio()
		await get_tree().create_timer(0.3).timeout
		var edificio := Captura.dato("--edificio", "apartamentos")
		if "--reto" in OS.get_cmdline_user_args():   # la prueba del reto del día: la tarjeta con su botón y su marca
			Captura.foto("captura-reto-tarjeta.png")
			jugar_reto(edificio)
		else:
			Captura.foto("captura-edificios.png")
			if "--edificios" in OS.get_cmdline_user_args():   # solo esta pantalla: los requisitos del centro, y se cierra
				for como in ["nada", "medias", "todo"]:
					foto_requisitos = como
					poner_tarjetas()
					await get_tree().create_timer(0.3).timeout
					print("Edificios · requisitos «%s»: centro abierto %s (esperado: %s) · torre abierta %s (esperado: false)" % [
						como, not tarjetas.get_child(1).get_child(0).disabled, como == "todo",
						not tarjetas.get_child(2).get_child(0).disabled])
					print("Edificios · tarjeta de los Apartamentos «%s»: «%s» (esperado: sin completar, «Has llegado a la planta N de 5» y, completado, «Récord: m:ss»: sin las veces ni el tanto por ciento)" % [
						como, (tarjetas.get_child(0).get_child(0).get_child(0).get_child(2) as Label).text])
					Captura.foto("captura-edificios-%s.png" % como)
				# el cuadro del reto del día (11 nov): con el ratón encima del botón de los Apartamentos
				var reto_b: Button = tarjetas.get_child(0).find_children("*", "Button", true, false).filter(func(x): return x.has_meta("cuadro"))[0]
				reto_b.mouse_entered.emit()
				await get_tree().create_timer(0.3).timeout
				var cuadro: Control = reto_b.get_meta("cuadro")
				print("Edificios · reto del día: botón «%s» de %s · cuadro a la vista %s (esperado: true) en %s dentro de la pantalla %s (esperado: true) · su borde de abajo %.0f, el botón empieza en %.0f (esperado: el borde, 8 o más por encima)" % [
					reto_b.text, reto_b.size, cuadro.visible, cuadro.global_position, get_viewport_rect().encloses(cuadro.get_global_rect()),
					cuadro.get_global_rect().end.y, reto_b.global_position.y])
				Captura.foto("captura-edificios-reto.png")
				reto_b.mouse_exited.emit()
				print("Edificios · reto del día: cuadro a la vista al apartar el ratón %s (esperado: false)" % cuadro.visible)
				get_tree().quit()
				return
			jugar_partida(edificio)


# Salir: en el ordenador cierra el juego. En la web no se puede (el navegador no deja que una página cierre su propia
# pestaña): sale una despedida (M46)
func salir() -> void:
	if OS.has_feature("web"):
		despedida()
	else:
		get_tree().quit()


# La despedida de la web: «¡Gracias por jugar!», que la partida está guardada y que ya se puede cerrar la pestaña. La música
# se apaga y se quita la pantalla completa, para que se vea la pestaña. «Volver al menú» (o Esc) lo deja todo como estaba
var adios: CenterContainer

func despedida() -> void:
	centro.hide()
	Sonido.musica("")
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	adios = CenterContainer.new()
	adios.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(adios)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 18)
	adios.add_child(columna)
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = Idioma.t("¡Gracias por jugar!")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	var texto := Label.new()
	texto.text = Idioma.t("Tu partida está guardada. Ya puedes cerrar la pestaña")
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(texto)
	var volver := boton(columna, Idioma.t("Volver al menú"), quitar_despedida)
	volver.grab_focus.call_deferred()


func quitar_despedida() -> void:
	adios.queue_free()
	adios = null
	Sonido.musica("menu")
	centro.show()
	centro.find_children("*", "Button", true, false)[0].grab_focus()


# «Elige partida» (huecos.gd), tapando el menú
func abrir_huecos() -> Huecos:
	centro.hide()
	var h := Huecos.new()
	add_child(h)
	h.cerrado.connect(func():
		centro.show()
		centro.find_children("*", "Button", true, false)[0].grab_focus())
	return h


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
	titulo.text = Idioma.t("Elige edificio")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	tarjetas = HBoxContainer.new()
	tarjetas.alignment = BoxContainer.ALIGNMENT_CENTER
	tarjetas.add_theme_constant_override("separation", 20)
	columna.add_child(tarjetas)
	poner_tarjetas()
	var volver := boton(columna, Idioma.t("Volver"), volver_al_menu)
	volver.custom_minimum_size.x = 180
	primera_tarjeta().grab_focus.call_deferred()


# Las tarjetas, con lo que dice el guardado (se rehacen al pulsar N, la tecla de prueba que lo abre todo)
func poner_tarjetas() -> void:
	for caja in tarjetas.get_children():
		caja.free()
	var s := Guardado.cargar()
	if foto_requisitos != "":   # para las fotos de --edificios (no se guarda)
		var paginas: Array = Historia.dosier("apartamentos").paginas.map(func(p): return p.id)
		var noticias: Array = Historia.noticias_de("apartamentos").map(func(n): return n.id)
		var cuantas: int = {"nada": 0, "medias": 2, "todo": 99}[foto_requisitos]
		Guardado.edificio(s, "apartamentos").completado = foto_requisitos != "nada"
		s.edificios.apartamentos.victorias = 0 if foto_requisitos == "nada" else 1
		s.paginas = s.paginas.filter(func(id): return not id in paginas) + paginas.slice(0, cuantas)
		s.videos_vistos = s.videos_vistos.filter(func(id): return not id in noticias) + noticias.slice(0, cuantas / 2)
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
		explica.text = Idioma.t("Complétalo para abrir la Alerta 1")
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
		texto.text = Idioma.t("%s (de %d)") % [Alerta.nombre(n), maximo]
		nombre.get_child(0).modulate = Color.WHITE if n > 0 else Color(1, 1, 1, 0.35)
		explica.text = Alerta.resumen(n, id)
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


# Debajo del selector de alerta: el botón del reto del día (reto.gd; apagado si ya se ha jugado hoy, M71), grande, con el
# premio debajo como el dinero de la tienda de armas («$» y la cifra en su pantallita: premio_reto, 12 nov) y, al pasar
# el ratón o marcarlo, su cuadro (11 nov)
func boton_reto(caja: VBoxContainer, id: String, s: Dictionary) -> void:
	var f := Reto.ficha(s, id, Reto.hoy())
	var b := Button.new()
	b.text = Idioma.t("Reto del día")
	b.theme_type_variation = "BotonGrande"   # no-tr
	b.custom_minimum_size = Vector2(280, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(jugar_reto.bind(id))
	var jugado := Reto.jugado(f)
	if jugado:   # una vez al día (M71): apagado hasta mañana
		b.disabled = true
		b.focus_mode = Control.FOCUS_NONE
	caja.add_child(b)
	var premio: Control
	if not jugado:
		premio = premio_reto()
	else:
		var texto := etiqueta_reto(Idioma.t("Premio $%d cobrado") % Reto.PREMIO if f.completado else Idioma.t("Vuelve mañana"),
			PLACA.TEXTO_SUAVE)
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		premio = texto
	caja.add_child(premio)
	var cuadro := cuadro_reto(f)
	cuadro.visible = false
	b.add_child(cuadro)
	# encima del botón, con su borde de abajo a 8 del botón y por encima del marco de abajo de la tarjeta del edificio (si
	# no, ese marco y sus remaches salían a los lados de la última línea y parecía que se metía por debajo, 12 nov). Las
	# frases partidas en líneas no saben lo que miden hasta que se colocan: al crecer el cuadro, se vuelve a subir
	var tarjeta_edificio: Control = caja.get_child(0)
	var colocar := func():
		var abajo := minf(b.global_position.y - 8, tarjeta_edificio.get_global_rect().end.y - SOBRE_MARCO)
		var donde := Vector2(b.global_position.x + (b.size.x - cuadro.size.x) / 2.0, abajo - cuadro.size.y)
		var pantalla := get_viewport_rect().size
		cuadro.global_position = Vector2(clampf(donde.x, 6.0, pantalla.x - cuadro.size.x - 6.0), maxf(6.0, donde.y))
	cuadro.resized.connect(colocar)
	var enseñar := func(si: bool):
		if si:
			cuadro.visible = true
			cuadro.reset_size()
			colocar.call()
		else:
			cuadro.visible = false
	b.mouse_entered.connect(enseñar.bind(true))
	b.mouse_exited.connect(enseñar.bind(false))
	b.focus_entered.connect(enseñar.bind(true))
	b.focus_exited.connect(enseñar.bind(false))
	b.set_meta("cuadro", cuadro)   # (las pruebas lo leen)
	# apagado el botón no recibe el ratón: el cuadro sale también al pasar por encima del premio
	if jugado:
		premio.mouse_filter = Control.MOUSE_FILTER_STOP
		premio.mouse_entered.connect(enseñar.bind(true))
		premio.mouse_exited.connect(enseñar.bind(false))


# El cuadro del reto de hoy, como la ficha de un talento (arbol_talentos.gd, llenar_ficha): la regla de hoy en la cabecera,
# qué hace y tu marca
func cuadro_reto(f: Dictionary) -> PanelContainer:
	var cuadro := PanelContainer.new()
	cuadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cuadro.top_level = true
	cuadro.z_index = 20
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#101215")
	estilo.border_color = PLACA.AMARILLO
	estilo.set_border_width_all(2)
	cuadro.add_theme_stylebox_override("panel", estilo)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.custom_minimum_size.x = 260
	cuadro.add_child(columna)
	var cabecera := PanelContainer.new()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#6b5a10")
	fondo.set_content_margin_all(4)
	fondo.content_margin_left = 8
	fondo.content_margin_right = 8
	cabecera.add_theme_stylebox_override("panel", fondo)
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(cabecera)
	cabecera.add_child(etiqueta_reto(Reto.nombre(f.regla), Color.WHITE, false, Tema.PESO_LISA_TITULO))
	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 8)
	columna.add_child(margen)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 4)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(textos)
	textos.add_child(etiqueta_reto(Reto.desc(f.regla), PLACA.TEXTO, true))
	textos.add_child(etiqueta_reto(Reto.marca(f), Color("#ff9a5c"), true))
	if Reto.jugado(f):
		textos.add_child(etiqueta_reto(Idioma.t("Ya lo has jugado hoy: vuelve mañana"), PLACA.TEXTO_SUAVE, true))
	# (el premio ya no va aquí: sale debajo del botón, y dos veces quedaba feo, 12 nov)
	var abajo := Control.new()
	abajo.custom_minimum_size.y = 8   # (aire bajo la marca: con 4 se pegaba al borde, 12 nov)
	abajo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(abajo)
	return cuadro


# Un texto del reto, con la letra lisa (Rubik) de ese grosor y algo más pequeña que la de siempre, para que quepa (12 nov)
func etiqueta_reto(texto: String, color: Color, partir := false, peso := Tema.PESO_LISA) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", Tema.lisa(peso))
	l.add_theme_font_size_override("font_size", TAM_RETO)
	if partir:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 244
	return l


# El premio del reto que aún se puede cobrar, como el dinero de la tienda de armas: «Premio» y, a su lado, la pantallita
# hundida con el «$» y la cifra en amarillo (chapa.gd, dibujar_marcador; sin los «8» apagados de fondo) (12 nov)
func premio_reto() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var palabra := etiqueta_reto(Idioma.t("Premio"), PLACA.AMARILLO, false, Tema.PESO_LISA_TITULO)
	palabra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(palabra)
	var fuente := get_theme_default_font()   # (la pixelada, la del marcador de la tienda)
	var pantallita := Control.new()
	pantallita.custom_minimum_size = PLACA.medida_marcador(fuente, Reto.PREMIO)
	pantallita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantallita.draw.connect(func():
		PLACA.dibujar_marcador(pantallita, fuente, Rect2(Vector2.ZERO, pantallita.size), Reto.PREMIO, PLACA.AMARILLO))
	fila.add_child(pantallita)
	return fila


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


# Volver (o Esc) en «Elige edificio»: a la pantalla de antes, «Elige partida» (huecos.gd), que al cerrarse vuelve al menú
func volver_al_menu() -> void:
	edificios.hide()
	abrir_huecos()


# Esc (o B en el mando) en "Elige edificio" o en la despedida: vuelve al menú. N (tecla de prueba): abre todos los edificios
# hasta cerrar el juego, sin completar los anteriores (no se guarda nada)
func _unhandled_input(evento: InputEvent) -> void:
	if adios and evento.is_action_pressed("ui_cancel"):
		quitar_despedida()
		get_viewport().set_input_as_handled()
		return
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
	var abierto := Edificios.abierto(s, id)
	var b := Button.new()
	# 250 de alto, como cuando llevaba la descripción; si en algún idioma los textos ocupan más, crece hasta lo que ocupan
	b.custom_minimum_size = Vector2(ANCHO_TARJETA, maxf(250, medir_tarjetas(s)))
	b.disabled = not abierto
	b.focus_mode = Control.FOCUS_ALL if abierto else Control.FOCUS_NONE
	b.pressed.connect(jugar_partida.bind(id))
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.offset_left = 16
	caja.offset_right = -16
	caja.offset_top = 14
	caja.offset_bottom = -14
	caja.alignment = BoxContainer.ALIGNMENT_CENTER   # el dibujo y los textos, en medio de la tarjeta (9 nov)
	caja.add_theme_constant_override("separation", 8)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caja)
	var dibujo := TextureRect.new()
	# (los Apartamentos y el candado, con su dibujo de GPT para la tarjeta: tools/muebles_gpt.py, 9 nov)
	var nombre_dibujo: String = "candado" if not abierto else id
	var de_tarjeta := "res://assets/ui/tarjeta-%s.png" % nombre_dibujo
	dibujo.texture = load(de_tarjeta if ResourceLoader.exists(de_tarjeta) else "res://assets/ui/iconos/%s.png" % nombre_dibujo)
	dibujo.custom_minimum_size = Vector2(64, 64)
	dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dibujo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dibujo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(dibujo)
	var textos := textos_tarjeta(id, s)
	for i in textos.size():
		var t: Array = textos[i]
		var l := Label.new()
		l.text = t[0]
		l.theme_type_variation = t[1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 260
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if t.size() > 2 and t[2]:   # un requisito ya cumplido: en verde y sin apagar
			l.add_theme_color_override("font_color", Tema.VERDE)
		elif not abierto:
			l.modulate = Color(1, 1, 1, 0.6)
		caja.add_child(l)
	return b


# Los textos de una tarjeta, cada uno con el estilo de su etiqueta: [texto, estilo] del nombre y de cómo te ha ido (o, cerrado,
# [texto, estilo, cumplido] de cada requisito para abrirlo). (Hasta el 9 nov llevaba también la descripción del edificio y las plantas y los intentos)
func textos_tarjeta(id: String, s: Dictionary) -> Array:
	var datos: Dictionary = Edificios.LISTA[id]
	var p: Dictionary = s.edificios.get(id, Guardado.EDIFICIO)
	var textos := [[Idioma.t(datos.nombre), ""]]
	if Edificios.abierto(s, id):
		var veces: int = p.partidas
		var progreso := Idioma.t("¡Sin explorar!")
		# el tanto por ciento del edificio (completarlo, sus dosieres y sus vídeos: Edificios.porcentaje), si ya hay algo
		var por_ciento := Edificios.porcentaje(s, id)
		var con_por_ciento := " · %d%%" % por_ciento if por_ciento > 0 else ""   # no-tr
		if p.completado:
			# completado: solo «Récord: 3:12» (11 nov; sin las veces ni el tanto por ciento)
			var t: float = p.mejor_tiempo
			progreso = Idioma.t("Récord: %d:%02d") % [int(t) / 60, int(t) % 60] if t > 0.0 else Idioma.t("Completado ×%d") % p.victorias
		elif veces > 0 or por_ciento > 0:
			progreso = Idioma.t("Has llegado a la planta %d de %d") % [p.mejor_planta, Planta.PLANTAS] + con_por_ciento
		textos.append([progreso, ""])
	else:
		# cerrado: lo que pide para abrirse (Edificios.requisitos), un renglón cada uno; los cumplidos, en verde
		for r: Dictionary in Edificios.requisitos(s, id):
			textos.append([r.texto + (" · " + r.cuenta if r.cuenta != "" else ""), "", r.hecho])
	return textos


# Lo que ocupa un texto en una etiqueta con ese estilo, partido en líneas del ancho de la tarjeta: las líneas que saca una etiqueta de
# verdad (puesta un momento para que use la letra del tema) por lo que mide cada una, la altura de la letra más lo que Label deja entre
# línea y línea. (No vale su get_minimum_size: en ruso y chino da la altura de la letra del juego y el texto se dibuja con la de la
# letra de reserva, 5 px más alta por línea)
func alto_texto(texto: String, estilo: String) -> float:
	var l := Label.new()
	l.theme_type_variation = estilo
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = texto
	add_child(l)
	l.size = Vector2(ANCHO_TEXTO, 0)
	var alto := l.get_line_count() * (l.get_theme_font("font").get_height(l.get_theme_font_size("font_size")) + l.get_theme_constant("line_spacing"))
	remove_child(l)
	l.free()
	return alto


# El alto de la tarjeta que más ocupa en el idioma de ahora, con sus 14 de margen arriba y abajo, el dibujo (64), 8 entre un texto
# y otro y 12 de sobra para que el último no quede pegado al borde. En ruso y chino las líneas son más altas que en español (la letra
# de reserva mide 22 en vez de 17)
func medir_tarjetas(s: Dictionary) -> float:
	var total := 0.0
	for id in Edificios.LISTA:
		var textos := textos_tarjeta(id, s)
		var suma := 28.0 + 64.0 + textos.size() * 8.0 + 6.0
		for t: Array in textos:
			suma += alto_texto(t[0], t[1])
		total = maxf(total, suma)
	return total


func jugar_partida(id := "apartamentos") -> void:
	Edificios.elegido = id
	Alerta.nivel = alertas.get(id, 0)
	Reto.quitar()   # (por si la partida anterior fue el reto del día)
	# con --captura, la partida de prueba: la misma, con las fotos (pruebas/partida_prueba.gd)
	Captura.ir_a_la_partida()

