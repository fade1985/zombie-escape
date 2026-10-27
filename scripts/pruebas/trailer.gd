# El trailer del juego ("-- --captura --trailer", ver docs/TRAILER.md): Johnny juega solo una serie de escenas
# pensadas para lucir el juego, con sus textos en pantalla, el título al final, y se cierra. Para sacarlo en vídeo, se
# arranca con el Movie Maker de Godot (--write-movie) y luego se le pone la música (tools/trailer.ps1 lo hace todo).
# Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_larga.gd"

const TRAILER_PANTALLA := Vector2i(960, 540)   # 16:9, lo que piden Steam y YouTube (a 1920×1080, por 2 justo)
const LOGO := preload("res://assets/ui/logo.png")

var capa_trailer: CanvasLayer
var rotulo_trailer: Label
var rotulo_tween: Tween
var telon: ColorRect   # el negro de los cortes entre escenas
var grabando := false  # en el trailer, Johnny no dice nada (sus frases taparían los textos)


func grabar_trailer() -> void:
	set_process(false)   # sin la prueba larga
	grabando = true
	get_window().content_scale_size = TRAILER_PANTALLA
	Sonido.musica_si(false)   # la música va luego en el montaje, entera y sin cortes; aquí, solo los efectos
	montar_capa_trailer()
	await get_tree().process_frame
	print("TRAILER-EMPIEZA %d" % Engine.get_frames_drawn())   # (tools/trailer.py tira lo de antes: el menú y la carga)
	johnny.poner_modo("asistido")   # apunta y dispara solo al zombi más cercano
	johnny.municion_sin_fin = true
	get_tree().physics_frame.connect(func() -> void:   # en el trailer, Johnny no cae
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3)
	var pisos := apartamentos()

	# 1) Johnny en la sala de mantenimiento, con su fregona
	johnny.coger("fregona")
	await abrir_telon()
	rotulo("Eres Johnny. El conserje.", 2.4)
	await andar("derecha", 1.4)
	await andar("abajo", 0.8)
	await esperar(0.6)

	# 2) un apartamento a oscuras, con la linterna, y los zombis que despiertan
	await cerrar_telon()
	var sala := await entrar(pisos[0], false)
	johnny.coger("pistola")
	soltar_zombis(sala, ["normal", "lento", "normal"], 150.0)
	await abrir_telon()
	rotulo("El edificio está infestado.", 2.6)
	await andar("derecha", 1.0)
	await esperar(2.4)

	# 3) una habitación llena y la escopeta
	await cerrar_telon()
	sala = await entrar(pisos[1 % pisos.size()])
	johnny.coger("escopeta")
	soltar_zombis(sala, ["normal", "rapido", "normal", "lento", "rapido", "normal", "venenoso"], 120.0)
	await abrir_telon()
	rotulo("Limpia piso a piso.", 2.8)
	await andar("izquierda", 0.6)
	await esperar(3.4)

	# 4) armas: el bate de cerca y la MP5
	await cerrar_telon()
	sala = await entrar(pisos[2 % pisos.size()])
	johnny.coger("bate")
	soltar_zombis(sala, ["normal", "lento", "normal"], 60.0)
	await abrir_telon()
	rotulo("Busca armas.", 3.4)
	await esperar(1.8)
	johnny.coger("mp5")
	soltar_zombis(sala, ["rapido", "normal", "rapido", "normal"], 140.0)
	await esperar(2.0)

	# 5) la tienda del ordenador: el lanzallamas; luego, él, el lanza ácido y el lanza rayos
	await cerrar_telon()
	Guardado.cambiar(func(g): g.dolares = maxi(g.dolares, 500))
	abrir_ordenador()
	await esperar(0.3)
	ordenador.abrir("armas", "b_lanzallamas")
	await abrir_telon()
	rotulo("Compra lo que necesites.", 2.6)
	await esperar(1.6)
	ordenador.comprar_arma("lanzallamas")
	await esperar(0.8)
	await cerrar_telon()
	ordenador.abrir("")
	ordenador.apagar()
	get_tree().paused = false
	sala = await entrar(pisos[3 % pisos.size()])
	johnny.coger("lanzallamas")
	soltar_zombis(sala, ["normal", "lento", "normal", "lento", "normal"], 110.0)
	await abrir_telon()
	await esperar(2.6)
	johnny.coger("desintegrador")
	soltar_zombis(sala, ["normal", "lento", "normal"], 110.0)
	await esperar(2.0)
	johnny.coger("pistola_electrica")
	soltar_zombis(sala, ["rapido", "normal", "rapido"], 150.0)
	await esperar(2.0)

	# 6) el inventario: Johnny entre sus armas
	await cerrar_telon()
	johnny.coger("escopeta")
	llevar_arma("bate")
	mochila.append_array(["botiquin", "gasolina", "gasolina", "alcohol"])
	abrir_cosas("inventario")
	await abrir_telon()
	rotulo("Guarda lo que encuentres.", 2.4)
	await esperar(2.8)
	await cerrar_telon()
	inventario.cerrar()
	get_tree().paused = false

	# 7) los jefes: el Glotón, con su presentación, y el Gymbro
	presentar_en_prueba = true
	johnny.coger("escopeta")
	abrir_telon()   # (sin esperar: ir_al_jefe ya funde a negro y vuelve)
	await ir_al_jefe("gloton")
	rotulo("Sobrevive a ellos.", 2.8)
	await esperar(3.4)
	await cerrar_telon()
	presentar_en_prueba = false
	johnny.coger("lanzallamas")
	await ir_al_jefe("gymbro")
	await esperar(0.6)
	await abrir_telon()
	await esperar(3.0)

	# 8) varios pisos distintos, muy seguidos
	await cerrar_telon()
	rotulo("Nunca es el mismo edificio.", 4.0)
	for num in [1, 2, 3, 4]:
		nueva_planta(num)
		var otros := apartamentos()
		sala = await entrar(otros[0])
		soltar_zombis(sala, ["normal", "lento"], 160.0)
		await abrir_telon(0.08)
		await esperar(1.0)
		await cerrar_telon(0.08)

	# 9) el título
	await titulo_trailer()
	get_tree().quit()


# Los textos y el negro de los cortes, por encima de todo (también del ordenador y del inventario, con el juego parado)
func montar_capa_trailer() -> void:
	capa_trailer = CanvasLayer.new()
	capa_trailer.layer = 120
	capa_trailer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(capa_trailer)
	telon = ColorRect.new()
	telon.color = Color.BLACK
	telon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	telon.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_trailer.add_child(telon)
	rotulo_trailer = Label.new()
	rotulo_trailer.add_theme_font_override("font", Tema.FUENTE)
	rotulo_trailer.add_theme_font_size_override("font_size", 32)
	rotulo_trailer.add_theme_color_override("font_color", Color("#f2ead2"))
	rotulo_trailer.add_theme_color_override("font_outline_color", Color("#120d14"))
	rotulo_trailer.add_theme_constant_override("outline_size", 12)
	rotulo_trailer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_trailer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo_trailer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rotulo_trailer.offset_top = -150
	rotulo_trailer.offset_bottom = -90
	rotulo_trailer.modulate.a = 0.0
	capa_trailer.add_child(rotulo_trailer)


# Sale un texto de golpe (grande y encogiendo, con un saltito), se queda "segundos" y se va. No hay que esperarlo
func rotulo(texto: String, segundos: float) -> void:
	if rotulo_tween:
		rotulo_tween.kill()
	rotulo_trailer.text = texto
	rotulo_trailer.pivot_offset = rotulo_trailer.size / 2.0
	rotulo_trailer.scale = Vector2(1.7, 1.7)
	rotulo_trailer.modulate.a = 0.0
	rotulo_tween = capa_trailer.create_tween()
	rotulo_tween.tween_property(rotulo_trailer, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rotulo_tween.parallel().tween_property(rotulo_trailer, "modulate:a", 1.0, 0.1)
	rotulo_tween.tween_interval(segundos)
	rotulo_tween.tween_property(rotulo_trailer, "modulate:a", 0.0, 0.25)


func abrir_telon(dur := 0.18) -> void:
	await capa_trailer.create_tween().tween_property(telon, "modulate:a", 0.0, dur).finished


func cerrar_telon(dur := 0.18) -> void:
	await capa_trailer.create_tween().tween_property(telon, "modulate:a", 1.0, dur).finished


func decir(texto: String, segundos := 2.2) -> void:
	if not grabando:
		super(texto, segundos)


func esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


# Johnny anda hacia un lado un rato (como si se pulsara la tecla)
func andar(accion: String, segundos: float) -> void:
	Input.action_press(accion)
	await esperar(segundos)
	Input.action_release(accion)


# Los sitios de la planta con apartamento (sin las viviendas, la sala de mantenimiento ni el piso del jefe), el de más habitaciones primero
func apartamentos() -> Array:
	var lista := []
	for i in planta.sitios.size():
		if planta.sitios[i].has("apt") and not planta.sitios[i].tipo in ["viviendas", "mantenimiento", "jefe"]:
			lista.append(i)
	lista.sort_custom(func(a, b): return planta.sitios[a].apt.salas.size() > planta.sitios[b].apt.salas.size())
	return lista


# Monta ese apartamento sin sus zombis y deja a Johnny (y a los suyos) en medio de la habitación más grande; con
# "ver_todo", todo descubierto y con menos penumbra, para que se vea bien la pelea; sin él, a oscuras, con la
# linterna. Devuelve esa habitación
func entrar(idx: int, ver_todo := true) -> Dictionary:
	await montar(idx, 0, false)
	var apt: Dictionary = planta.sitios[idx].apt
	if ver_todo:
		for s in apt.salas:
			mapa.vistas[s.id] = true
			mapa.niebla[s.id] = 0.0
	luz.extra = -0.45 if ver_todo else 0.0
	luz.nivel = luz.oscuridad()
	luz.pintar()
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var grande: Dictionary = apt.salas[0]
	for s in apt.salas:
		if s.casillas > grande.casillas:
			grande = s
	johnny.position = grande.centro
	johnny.velocity = Vector2.ZERO
	johnny.get_node("Camara").reset_smoothing()
	for a in supervivientes.equipo:
		a.position = johnny.position + Vector2(-40, 24)
	Aliado.borrar_huellas()
	return grande


# Mete zombis despiertos en esa habitación, a "lejos" de Johnny o más, donde quepan
func soltar_zombis(sala: Dictionary, tipos: Array, lejos: float) -> void:
	var sitio: Dictionary = planta.sitios[aqui]
	var puestos := 0
	for intento in 600:
		if puestos >= tipos.size():
			return
		var pos: Vector2 = johnny.position + Vector2.from_angle(randf() * TAU) * randf_range(lejos, lejos + 160.0)
		if Planta.despejado(sitio.apt, pos, 20.0, sala.id) and Planta.lejos_de_muebles(sitio, pos, 30.0):
			var z := meter_zombi(tipos[puestos], pos)
			z.dormido = false
			puestos += 1


# El final: el logo del juego en grande sobre negro y, debajo, dónde sale
func titulo_trailer() -> void:
	await cerrar_telon(0.3)
	var pantalla := get_viewport().get_visible_rect().size
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.size = LOGO.get_size() * 4.0
	logo.position = (pantalla - logo.size) / 2.0 - Vector2(0, 40)
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.pivot_offset = logo.size / 2.0
	capa_trailer.add_child(logo)
	var debajo := Label.new()
	debajo.text = "Próximamente en Steam"
	debajo.add_theme_font_override("font", Tema.FUENTE)
	debajo.add_theme_font_size_override("font_size", 32)
	debajo.add_theme_color_override("font_color", Color("#c9b98f"))
	debajo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debajo.position = Vector2(0, logo.position.y + logo.size.y + 30)
	debajo.size = Vector2(pantalla.x, 40)
	debajo.modulate.a = 0.0
	capa_trailer.add_child(debajo)
	logo.scale = Vector2(1.25, 1.25)
	logo.modulate.a = 0.0
	var t := capa_trailer.create_tween()
	t.tween_property(logo, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(logo, "modulate:a", 1.0, 0.2)
	t.tween_interval(0.5)
	t.tween_property(debajo, "modulate:a", 1.0, 0.4)
	await t.finished
	await esperar(3.0)
