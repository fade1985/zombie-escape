# Cómo llena la imagen la pantalla y la pantalla completa en el ordenador (autoload).
#
# La imagen llena toda la ventana, sin bordes negros. Para que el pixel art se vea nítido, cada píxel del dibujo (2
# unidades) tiene que medir un número exacto de píxeles de la pantalla, y por eso la escala va de medio en medio: ×1, ×1,5,
# ×2... Se coge la mayor con la que cabe la pantalla base (los menús están hechos para ella), y lo que sobra se ve de más:
# en Full HD, ×1,5 y 1280×720. Si sobrara demasiado (una ventana de navegador de 900 de alto, a ×1, enseñaría medio
# edificio con los muñecos diminutos), se agranda lo justo para la pantalla base, aunque unos píxeles salgan un
# poco más anchos que otros. Y a ×1, si cabe un 10 % más grande, también lo justo (9 nov): en pantallas pequeñas (la Steam
# Deck, 1280×800; portátiles de 1366×768) la letra se quedaba en 7 píxeles de alto y Valve pide por lo menos 9; así sale un
# 12-25 % más grande. En el móvil, siempre lo justo. Las pruebas (--captura) no lo tocan: sus fotos siguen igual (con
# --deck, cualquier prueba se ve en una ventana de 1280×800 con la escala de verdad).
#
# La pantalla completa arranca como se dejó la última vez (ajuste «pantalla_completa», que guarda
# Tactil.pantalla_completa al cambiarla) y se cambia con F11 o Alt+Intro desde cualquier sitio, también con un menú abierto.
# En la web las teclas no hacen nada: allí F11 es del navegador. Las pruebas no arrancan en pantalla completa (la prueba
# --pantalla prueba las teclas).
#
# En la web, Esc también es del navegador: quitaría la pantalla completa en vez de abrir la pausa. Por eso, mientras dura la
# pantalla completa se le pide que lo deje para el juego (QUEDARSE_ESC), y entonces se sale manteniendo Esc pulsado. Solo saben
# hacerlo Chrome, Edge y Opera, en ordenador y en https o localhost; en los demás navegadores no pasa nada y Esc sigue siendo suyo.
extends Node

const BASE := Vector2(960, 640)   # la pantalla base: siempre se ve por lo menos esto
const ALTO_MAXIMO := 800.0        # lo más alto que se deja ver antes de agrandar lo justo
const CRECER_DESDE_X1 := 1.1      # a ×1, si lo justo es por lo menos esto, se agranda (la letra, legible en la Steam Deck)
# Imágenes por segundo. Normalmente las frena el vsync (las que dé la pantalla: 60, 144, 165...), pero si falla
# (ventana minimizada en Windows, o el vsync quitado en el panel de la tarjeta) el juego dibujaría miles sin
# necesidad y pondría la gráfica a tope (11 nov). TOPE es el techo de siempre, por encima de cualquier pantalla
# normal; FUERA, el de cuando el juego no es la ventana activa (otra ventana delante o minimizado). Las pruebas
# (--captura) no se frenan fuera: se lanzan a menudo detrás de otras ventanas
const TOPE := 240
const FUERA := 30
# El brillo (ajuste «brillo» de Opciones → General, de 0 a 100; 50 = sin tocar). Una capa por encima de todo (menús,
# partida, botones táctiles) que vuelve a pintar la pantalla más clara o más oscura (escenas/luces/brillo_pantalla.gdshader).
# Con el brillo en 50 la capa no está: no gasta nada. A 100 lo oscuro se ve bastante más (gamma 0,55) y a 0 se ve
# más oscuro pero se sigue viendo (gamma 1,4 y un 15 % menos de luz: con más, la partida, que ya es oscura, quedaba negra)
const BRILLO_NORMAL := 50
const BRILLO_CLARO := 0.85    # cuánto baja la gamma de 50 a 100 (en potencias de 2)
const BRILLO_OSCURO := 0.5    # y cuánto sube de 50 a 0
const BRILLO_MENOS := 0.15    # cuánta luz se quita además a 0
const BRILLO_SHADER := preload("res://escenas/luces/brillo_pantalla.gdshader")
var capa_brillo: CanvasLayer
var tapa_brillo: ColorRect
const QUEDARSE_ESC := """
document.addEventListener('fullscreenchange', () => {
	if (!navigator.keyboard?.lock) return;
	if (document.fullscreenElement) navigator.keyboard.lock(['Escape']).catch(() => {});
	else navigator.keyboard.unlock();
});
"""   # no-tr (JavaScript)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# La interpolación de física (project.godot): Godot dibuja lo que se mueve a 60 pasos por segundo en sitios
	# intermedios, para que en pantallas de 120 o 144 Hz no vaya a saltitos. Aquí se apaga para todo el juego y se
	# enciende solo en Johnny (johnny.tscn), que es lo que sigue la cámara: lo que se mueve en cada fotograma en vez
	# de en cada paso (efectos, menús...) temblaría con ella
	get_tree().root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var captura := "--captura" in OS.get_cmdline_user_args()
	poner_brillo.call_deferred()
	Engine.max_fps = TOPE
	if captura and "--deck" in OS.get_cmdline_user_args():
		# Con --deck, cualquier prueba se ve como en la Steam Deck: ventana de 1280×800 y la escala del juego de verdad
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 800))
	if not captura or "--deck" in OS.get_cmdline_user_args():
		get_window().size_changed.connect(ajustar_escala)
		ajustar_escala()
	if OS.has_feature("web"):
		for mando in Input.get_connected_joypads():   # (los mandos que el navegador no reconoce, M73)
			Controles.ordenar_mando(mando)
		Input.joy_connection_changed.connect(func(mando: int, enchufado: bool) -> void:
			if enchufado:   # (un momento después, con el mando ya apuntado del todo en Godot)
				(func(): Controles.ordenar_mando(mando)).call_deferred())
		set_process_input(false)
		JavaScriptBridge.eval(QUEDARSE_ESC, true)
		return
	if not captura and Guardado.ajuste("pantalla_completa"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# Con el juego en segundo plano (otra ventana delante o minimizado), pocas imágenes por segundo: nadie lo está mirando.
# Al volver, el tope de siempre (ver TOPE y FUERA)
func _notification(que: int) -> void:
	if "--captura" in OS.get_cmdline_user_args() or OS.has_feature("web"):
		return
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Engine.max_fps = FUERA
	elif que == NOTIFICATION_APPLICATION_FOCUS_IN:
		Engine.max_fps = TOPE


# Pone el brillo guardado (o el que se le diga, de 0 a 100). Lo llama Opciones al cambiarlo y esto mismo al arrancar
func poner_brillo(valor := -1) -> void:
	if valor < 0:
		valor = int(Guardado.ajuste("brillo"))
	var t := clampf((valor - BRILLO_NORMAL) / float(BRILLO_NORMAL), -1.0, 1.0)   # -1 lo más oscuro, 0 normal, 1 lo más claro
	if is_zero_approx(t):
		if capa_brillo:
			capa_brillo.hide()
		return
	if capa_brillo == null:
		capa_brillo = CanvasLayer.new()
		capa_brillo.layer = 128   # la más alta que hay: por encima de todo
		add_child(capa_brillo)
		tapa_brillo = ColorRect.new()
		tapa_brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
		tapa_brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE   # (los clics pasan a lo de debajo)
		var m := ShaderMaterial.new()
		m.shader = BRILLO_SHADER
		tapa_brillo.material = m
		capa_brillo.add_child(tapa_brillo)
	var material: ShaderMaterial = tapa_brillo.material
	material.set_shader_parameter("gamma", pow(2.0, -t * (BRILLO_CLARO if t > 0.0 else BRILLO_OSCURO)))
	material.set_shader_parameter("ganancia", 1.0 + BRILLO_MENOS * minf(t, 0.0))
	capa_brillo.show()


# A qué escala se ve el juego en una ventana de ese tamaño (en píxeles de verdad)
static func escala_para(ventana: Vector2) -> float:
	var justa := minf(ventana.x / BASE.x, ventana.y / BASE.y)
	var exacta := floorf(justa * 2.0) / 2.0
	var letra_pequena := exacta == 1.0 and justa >= CRECER_DESDE_X1
	if exacta >= 1.0 and ventana.y / exacta <= ALTO_MAXIMO and not letra_pequena:
		return exacta
	return justa


# Se llama al arrancar y cada vez que cambia el tamaño de la ventana. Con content_scale_size a cero no hay pantalla base que
# respetar a la fuerza: lo que se ve es la ventana entre la escala, justo lo que llena sin bordes
func ajustar_escala() -> void:
	var ventana := get_window()
	ventana.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if Tactil.activo:
		ventana.content_scale_size = Vector2i(BASE)
		ventana.content_scale_factor = 1.0
	elif ventana.size.x > 0 and ventana.size.y > 0:   # (minimizada, la ventana no mide nada)
		ventana.content_scale_size = Vector2i.ZERO
		ventana.content_scale_factor = escala_para(Vector2(ventana.size))


func _input(evento: InputEvent) -> void:
	Controles.fijarse(evento)   # (¿juega con el mando o con el teclado? Para lo que se enseña en pantalla)
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	if evento.keycode == KEY_F11 or (evento.alt_pressed and evento.keycode in [KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
		Tactil.pantalla_completa()
