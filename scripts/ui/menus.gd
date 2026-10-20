# Los menús de dentro de la partida (como showPause y showEnd de src/ui.js):
#   - Pausa (Esc o Start): el sitio en el que estás, los atributos de Johnny y sus armas, y los botones
#     Continuar, Música Sí/No y Abandonar partida. El juego se para mientras está abierta.
#   - El cartel del final: "¡Edificio completado!" o "¡Derrota!", con lo que has hecho en la partida y los
#     botones de volver a jugar o ir al menú principal.
#   - Las mutaciones (showMutacion del JS): tras caer la portera, dos cartas para elegir una (también con 1 y 2).
# Se manejan con el ratón, con el teclado (flechas e Intro) o con el mando (cruceta o stick, A para pulsar y
# B para volver): Godot pasa de un botón a otro solo, y aquí se elige cuál empieza marcado.
extends CanvasLayer

signal continuar
signal abandonar
signal reintentar
signal menu_principal

var fondo: ColorRect
var abierto := ""         # "pausa", "fin", "mutacion" o "" (nada)
var elegir_mutacion := Callable()   # a quién avisar con la mutación elegida
var cartas: Array = []    # las dos mutaciones que se ofrecen


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue funcionando con el juego en pausa


# El fondo oscuro y, encima, un panel de metal centrado. Devuelve la columna de dentro del panel
func abrir(nombre: String, oscuro := 0.72) -> VBoxContainer:
	cerrar()
	abierto = nombre
	fondo = ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, oscuro)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	panel.add_child(columna)
	# Entra con un pequeño salto, como en el JS
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.9, 0.9)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return columna


func cerrar() -> void:
	abierto = ""
	if fondo:
		fondo.queue_free()
		fondo = null


func titulo(columna: VBoxContainer, texto: String, sub := "") -> void:
	var t := Label.new()
	t.theme_type_variation = "Titulo"
	t.text = texto
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(t)
	if sub != "":
		var s := Label.new()
		s.theme_type_variation = "Sub"
		s.text = sub
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 420
		columna.add_child(s)


# Una fila de estadística: icono y nombre a la izquierda, el valor a la derecha
func dato(lista: VBoxContainer, icono: String, nombre: String, valor: String, color := Tema.TINTA) -> void:
	var fila := HBoxContainer.new()
	var izquierda := Tema.icono_y_texto(icono, nombre, 20)
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(izquierda)
	var v := Label.new()
	v.text = valor
	v.add_theme_color_override("font_color", color)
	fila.add_child(v)
	lista.add_child(fila)


func boton(caja: Container, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = variacion
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


func pausa(partida: Node) -> void:
	var columna := abrir("pausa")
	var johnny: Node2D = partida.johnny
	var s: Dictionary = johnny.stats
	titulo(columna, "Pausa", partida.lugar.text.replace("\n", " · "))
	var lado := HBoxContainer.new()
	lado.add_theme_constant_override("separation", 28)
	columna.add_child(lado)
	var izquierda := VBoxContainer.new()
	izquierda.custom_minimum_size.x = 300
	lado.add_child(izquierda)
	var w: Dictionary = johnny.arma()
	dato(izquierda, "corazon", "Vida", "%d / %d" % [johnny.vida, s.vida_max])
	dato(izquierda, "fuerza", "Daño", "x%.2f" % s.dano)
	dato(izquierda, "cafe", "Velocidad de ataque", "x%.2f" % s.ritmo)
	dato(izquierda, "guantes", "Alcance", "x%.2f" % (s.alcance * (s.alcance_cuerpo if w.tipo == "cuerpo" else 1.0)))
	dato(izquierda, "dash", "Velocidad", str(roundi(s.velocidad)))
	dato(izquierda, "casco", "Daño recibido", "x%.2f" % s.dano_recibido)
	dato(izquierda, "diana", "Crítico", "%d%%" % roundi(s.critico * 100))
	var derecha := VBoxContainer.new()
	lado.add_child(derecha)
	var armas := Label.new()
	armas.text = "Armas"
	armas.theme_type_variation = "Sub"
	derecha.add_child(armas)
	for hueco in ["cuerpo", "fuego"]:
		var id: String = johnny.huecos[hueco]
		var a: Dictionary = Armas.DATOS[id]
		var resumen := "%s · daño %d · %.1f/s" % [a.nombre, a.dano * (a.get("perdigones", 1)), a.ritmo]
		derecha.add_child(Tema.icono_y_texto({"mp5": "pistola"}.get(id, id), resumen, 20))
	var lz: Lanzables = partida.lanzables
	derecha.add_child(Tema.icono_y_texto("molotov", "Molotovs: %d / %d" % [lz.cantidades.molotov, lz.maximo("molotov")], 20))
	derecha.add_child(Tema.icono_y_texto("granada", "Granadas: %d / %d" % [lz.cantidades.granada, lz.maximo("granada")], 20))
	if not partida.mutaciones.tengo.is_empty():
		var muts := Label.new()
		muts.text = "Mutaciones"
		muts.theme_type_variation = "Sub"
		derecha.add_child(muts)
		for id in partida.mutaciones.tengo:
			var m := Mutaciones.mutacion(id)
			derecha.add_child(Tema.icono_y_texto(m.icono, m.nombre, 20))
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 10)
	columna.add_child(botones)
	var seguir := boton(botones, "Continuar", func(): continuar.emit())
	# La música llega en la fase 8: de momento solo se guarda lo que se elige
	var musica := boton(botones, texto_musica(), func(): pass)
	musica.pressed.connect(func():
		Guardado.cambiar(func(g): g.ajustes.musica = not g.ajustes.musica)
		musica.text = texto_musica())
	boton(botones, "Abandonar partida", func(): abandonar.emit(), "BotonRojo")
	seguir.grab_focus.call_deferred()


func texto_musica() -> String:
	return "Música: %s" % ("Sí" if Guardado.cargar().ajustes.musica else "No")


# r: gano, titulo, sub, plantas, muertos, visitados, tiempo, dolares, cartera
func fin(r: Dictionary) -> void:
	var columna := abrir("fin")
	titulo(columna, r.titulo, r.sub)
	var lista := VBoxContainer.new()
	lista.custom_minimum_size.x = 440
	columna.add_child(lista)
	dato(lista, "apartamentos", "Plantas superadas", r.plantas)
	dato(lista, "zombi", "Enemigos derrotados", str(r.muertos))
	dato(lista, "puerta", "Apartamentos visitados (última planta)", r.visitados)
	if r.tiempo != "":
		dato(lista, "trofeo", "Tiempo", r.tiempo)
	if r.gano:
		dato(lista, "billete", "Dólares conseguidos", "+$%d  (tienes $%d)" % [r.dolares, r.cartera], Tema.VERDE)
	else:
		dato(lista, "billete", "Dólares perdidos", "$%d  (tienes $%d)" % [r.dolares, r.cartera], Tema.ROJO)
	var botones := VBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(botones)
	var otra := boton(botones, "Jugar otra vez" if r.gano else "Reintentar edificio", func(): reintentar.emit(), "BotonGrande")
	boton(botones, "Menú principal", func(): menu_principal.emit())
	for b in botones.get_children():
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	otra.grab_focus.call_deferred()


# El recuadro de las mutaciones: dos cartas (icono, nombre y lo que hace). "llevas": las que ya tiene
func mutacion(opciones: Array, llevas: int, al_elegir: Callable) -> void:
	var columna := abrir("mutacion", 0.8)
	elegir_mutacion = al_elegir
	cartas = opciones
	var virus := Label.new()
	virus.text = "La exposición prolongada al virus hace que te sientas..."
	virus.theme_type_variation = "Sub"
	virus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(virus)
	var t := Label.new()
	t.theme_type_variation = "Titulo"
	t.text = "¡¡¡DIFERENTE!!!"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color("#e05ce0"))
	columna.add_child(t)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 16)
	columna.add_child(fila)
	var primera: Button = null
	for i in opciones.size():
		var m: Dictionary = opciones[i]
		var carta := Button.new()
		carta.custom_minimum_size = Vector2(260, 200)
		carta.pressed.connect(func(): elegir(m.id))
		fila.add_child(carta)
		var dentro := VBoxContainer.new()
		dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
		dentro.offset_left = 16
		dentro.offset_right = -16
		dentro.offset_top = 12
		dentro.offset_bottom = -12
		dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		carta.add_child(dentro)
		var cabeza := Tema.icono_y_texto(m.icono, "%d. %s" % [i + 1, m.nombre], 32)
		cabeza.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(cabeza)
		var desc := Label.new()
		desc.text = m.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 16)
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(desc)
		if primera == null:
			primera = carta
	var pie := Label.new()
	pie.text = "Mutación %d de %d · dura hasta que acabe la partida" % [llevas + 1, Mutaciones.MAXIMO]
	pie.theme_type_variation = "Sub"
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(pie)
	primera.grab_focus.call_deferred()


func elegir(id: String) -> void:
	if abierto != "mutacion":
		return
	cerrar()
	elegir_mutacion.call(id)


# B del mando o Esc: en la pausa, seguir jugando. En las mutaciones, 1 y 2 eligen carta
func _unhandled_input(evento: InputEvent) -> void:
	if abierto == "mutacion" and evento is InputEventKey and evento.pressed and not evento.echo:
		var n: int = {KEY_1: 0, KEY_KP_1: 0, KEY_2: 1, KEY_KP_2: 1}.get(evento.keycode, -1)
		if n >= 0 and n < cartas.size():
			get_viewport().set_input_as_handled()
			elegir(cartas[n].id)
		return
	if abierto == "pausa" and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		continuar.emit()
