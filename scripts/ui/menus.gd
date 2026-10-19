# Los menús de dentro de la partida (como showPause y showEnd de src/ui.js):
#   - Pausa (Esc o Start): el sitio en el que estás, los atributos de Johnny y sus armas, y los botones
#     Continuar, Música Sí/No y Abandonar partida. El juego se para mientras está abierta.
#   - El cartel del final: "¡Edificio completado!" o "¡Derrota!", con lo que has hecho en la partida y los
#     botones de volver a jugar o ir al menú principal.
# Se manejan con el ratón, con el teclado (flechas e Intro) o con el mando (cruceta o stick, A para pulsar y
# B para volver): Godot pasa de un botón a otro solo, y aquí se elige cuál empieza marcado.
extends CanvasLayer

signal continuar
signal abandonar
signal reintentar
signal menu_principal

var fondo: ColorRect
var abierto := ""         # "pausa", "fin" o "" (nada)


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


# B del mando o Esc: en la pausa, seguir jugando
func _unhandled_input(evento: InputEvent) -> void:
	if abierto == "pausa" and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		continuar.emit()
