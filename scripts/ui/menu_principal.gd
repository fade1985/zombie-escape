# El menú principal (showMenu de src/ui.js): el logo, JUGAR, Opciones (opciones.gd), pantalla completa y salir, y el
# récord. Es la escena con la que arranca el juego; JUGAR lleva a la partida (escenas/partida.tscn).
# Con "-- --captura" saca una foto (captura-menu.png) y pasa sola a la partida, para seguir con su prueba.
extends Control

const LOGO := preload("res://assets/ui/logo.png")


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
	var centro := CenterContainer.new()
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

	var jugar := boton(columna, "JUGAR", jugar_partida, "BotonGrande")
	var opciones := boton(columna, "Opciones", func(): pass)
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
	texto.text = ("Limpia cada apartamento para abrir su puerta y busca la llave de la portera\n"
		+ "Los controles y el modo de atacar están en Opciones")
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_child(texto)

	var s := Guardado.cargar()
	if s.mejor_planta > 0 or s.dolares > 0:
		var record := Tema.icono_y_texto("trofeo", "Mejor planta alcanzada: %d   ·   Dólares ahorrados: $%d" % [s.mejor_planta, s.dolares])
		record.alignment = BoxContainer.ALIGNMENT_CENTER
		columna.add_child(record)

	jugar.grab_focus.call_deferred()
	if "--captura" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("res://captura-menu.png")
		jugar_partida()


func boton(caja: Container, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = variacion
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size.x = 260
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


func jugar_partida() -> void:
	get_tree().change_scene_to_file("res://escenas/partida.tscn")

