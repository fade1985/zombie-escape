# El panel de la sala de pruebas (sala_armas.gd): con la P, allí dentro, se para el juego y sale esta ventana. A la
# izquierda, las pestañas; a la derecha, sus botones:
#   Jefes     uno por jefe, y dos casillas: «a media vida» (sale ya enfadado) y «quieto» (ataca y avisa, pero no se
#             mueve de su sitio: para mirar sus avisos)
#   Zombis    uno por tipo, cuántos sacar de golpe y «borrar todos»
#   Ayudas    cada una se enciende y se apaga: las líneas de la sala, el panel de daño, los avisos de los jefes en el
#             suelo (aviso.gd) y la penumbra
#   Johnny    invencible, munición sin fin, la diana y la siguiente skin
#   Ir a      la exposición, la azotea, el superviviente y la habitación de cada minijefe del edificio
#   Varios    mutaciones, un objeto, piezas al baúl de verdad, Colecciones completas y un científico muerto
# Lo que saca algo o lleva a otro sitio cierra el panel. Va con el ratón o el dedo, con el teclado (flechas e Intro) o
# con el mando. P, Esc o B lo cierran.
extends CanvasLayer

const PESTANAS := ["Jefes", "Zombis", "Ayudas", "Johnny", "Ir a", "Varios"]
const JEFES := {"portera": "Portera", "antidisturbios": "Antidisturbios", "cocinero": "Cocinero", "modista": "Modista",
	"mascota": "Mascota", "gerente": "Gerente", "gloton": "Glotón", "gymbro": "Gymbro", "bombero": "Jefe de bomberos",
	"cientifico_jefe": "Científico jefe"}
const ZOMBIS := {"normal": "Normal", "lento": "Lento", "rapido": "Rápido", "explosivo": "Explosivo",
	"tentaculos": "Tentáculos", "venenoso": "Venenoso", "vigilante": "Vigilante", "dependienta": "Dependienta"}
const CUANTOS := [1, 3, 5, 10]
const AYUDAS := {"alcance": "Alcance del arma", "apuntado": "A quién apunta", "trayectoria": "Por dónde irá la bala",
	"circulos": "Círculos de acierto", "balas": "Camino de las balas"}

var partida: Node
var fondo: ColorRect
var pestanas := {}             # nombre → su botón
var hoja: GridContainer        # los botones de la pestaña elegida
var pie: Label
var elegida := "Jefes"
# Las opciones de sacar (static: se acuerdan de una vez para otra)
static var media_vida := false
static var quieto := false
static var cuantos := 1


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abierto() -> bool:
	return fondo != null


func abrir(p: Node) -> void:
	partida = p
	quitar()
	fondo = ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, 0.72)
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
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = "Panel de pruebas"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	columna.add_child(fila)
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 6)
	fila.add_child(lado)
	for nombre in PESTANAS:
		var b := Button.new()
		b.text = nombre
		b.custom_minimum_size = Vector2(120, 40)
		b.pressed.connect(elegir.bind(nombre))
		lado.add_child(b)
		pestanas[nombre] = b
	hoja = GridContainer.new()
	hoja.columns = 3
	hoja.custom_minimum_size = Vector2(570, 310)
	hoja.add_theme_constant_override("h_separation", 8)
	hoja.add_theme_constant_override("v_separation", 8)
	fila.add_child(hoja)
	pie = Label.new()
	pie.theme_type_variation = "Sub"
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(pie)
	elegir(elegida)
	pestanas[elegida].grab_focus()


# Una pestaña: se pintan sus botones
func elegir(nombre: String) -> void:
	elegida = nombre
	for n in pestanas:
		pestanas[n].add_theme_color_override("font_color", Tema.AMARILLO if n == nombre else Color("#e6dec8"))
	for hijo in hoja.get_children():
		hoja.remove_child(hijo)
		hijo.queue_free()
	pie.text = "P, Esc o B: cerrar"
	var la_sala := sala()
	match nombre:
		"Jefes":
			for tipo in JEFES:
				boton(JEFES[tipo], sacar_jefe.bind(tipo))
			interruptor("A media vida", media_vida, func(si): media_vida = si)
			interruptor("Quieto", quieto, func(si): quieto = si)
			pie.text = "Salen lejos de Johnny. Lo que pasa en la sala no cuenta  ·  " + pie.text
		"Zombis":
			for tipo in ZOMBIS:
				boton(ZOMBIS[tipo], sacar_zombis.bind(tipo))
			boton("Cuántos: %d" % cuantos, func():
				cuantos = CUANTOS[(CUANTOS.find(cuantos) + 1) % CUANTOS.size()]
				elegir("Zombis")
				hoja.get_child(ZOMBIS.size()).grab_focus())
			boton("Borrar todos", borrar_zombis)
		"Ayudas":
			for k in AYUDAS:
				interruptor(AYUDAS[k], SalaArmas.ayudas[k], func(si): SalaArmas.ayudas[k] = si)
			interruptor("Panel de daño", SalaArmas.con_panel, func(si): SalaArmas.con_panel = si)
			interruptor("Avisos de los jefes", not Aviso.apagados, func(si): Aviso.apagados = not si)
			interruptor("Penumbra", not Luz.apagada, func(si): Luz.apagada = not si)
		"Johnny":
			interruptor("Invencible", partida.johnny.invencible, func(si): partida.johnny.invencible = si)
			interruptor("Munición sin fin", SalaArmas.sin_fin, func(si):
				SalaArmas.sin_fin = si
				if la_sala:
					la_sala.con_sin_fin(si))
			interruptor("Diana", SalaArmas.con_diana, func(si):
				SalaArmas.con_diana = si
				if la_sala and si:
					la_sala.poner_diana()
				elif la_sala:
					la_sala.quitar_diana())
			boton("Siguiente skin", func():
				partida.johnny.vestir(Skins.siguiente(partida.johnny.skin))
				partida.decir("Skin: " + Skins.nombre(partida.johnny.skin)))
			pie.text = "Al salir, Johnny vuelve a llevar lo que llevaba (la skin no se guarda)  ·  P, Esc o B: cerrar"
		"Ir a":
			boton("Exposición", cerrar_y.bind(func(): partida.montar(partida.planta.expo, 0)))
			if partida.ed.get("azotea", false):
				boton("Azotea", cerrar_y.bind(partida.ir_a_azotea))
			if not partida.planta.get("superviviente", {}).is_empty():
				boton("Superviviente (H)", cerrar_y.bind(partida.supervivientes.probar_aqui))
			for tipo in partida.orden_jefes:
				if partida.ZOMBIS.has(tipo):
					boton("Sala: " + JEFES.get(tipo, tipo), cerrar_y.bind(partida.ir_al_jefe.bind(tipo)))
			pie.text = "F11 vuelve de la exposición. Lejos de esta planta, F11 lleva a su sala de pruebas  ·  P: cerrar"
		"Varios":
			boton("Mutaciones", cerrar_y.bind(partida.abrir_mutacion))
			boton("Soltar un objeto", cerrar_y.bind(func():
				partida.soltar_objeto(Objetos.al_azar(partida.edificio, ""), partida.johnny.position + Vector2(0, 50))))
			boton("Piezas al baúl", partida.dar_objetos)
			boton("Colecciones completas", func():
				Bestiario.todo_visto()
				partida.decir("Colecciones: todo encontrado y visto"))
			boton("Científico muerto", cerrar_y.bind(partida.probar_cientifico))
			pie.text = "«Piezas al baúl» va al baúl de verdad (el de la sala de mantenimiento)  ·  P: cerrar"


func boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(184, 40)
	b.pressed.connect(func():
		Sonido.tocar("cambiar")
		accion.call())
	hoja.add_child(b)
	return b


# Un botón que se enciende y se apaga: «Nombre: SÍ» en verde o «Nombre: NO» en gris
func interruptor(texto: String, encendido: bool, cambiar: Callable) -> void:
	var b := boton("", func(): pass)
	var pintar := func(si: bool):
		b.text = "%s: %s" % [texto, "SÍ" if si else "NO"]
		for c in ["font_color", "font_hover_color", "font_focus_color"]:
			b.add_theme_color_override(c, Tema.VERDE if si else Tema.GRIS)
	b.set_meta("si", encendido)
	pintar.call(encendido)
	b.pressed.connect(func():
		var si: bool = not b.get_meta("si")
		b.set_meta("si", si)
		cambiar.call(si)
		pintar.call(si))


# La sala de pruebas montada (o null)
func sala() -> SalaArmas:
	for n in partida.mapa.get_children():
		if n is SalaArmas:
			return n
	return null


func cerrar_y(accion: Callable) -> void:
	cerrar()
	accion.call()


func sacar_jefe(tipo: String) -> void:
	cerrar()
	var jefe: Node2D = partida.meter_zombi(tipo, partida.mapa.punto_libre(partida.johnny.position, 300.0))
	if media_vida:
		jefe.vida = floori(jefe.vida_max * jefe.enfado)   # (al siguiente paso se enfada, con su grito)
		if jefe.has_signal("vida_cambiada"):
			jefe.vida_cambiada.emit(jefe.vida, jefe.vida_max)
	jefe.quieto = quieto


func sacar_zombis(tipo: String) -> void:
	cerrar()
	for i in cuantos:
		partida.meter_zombi(tipo, partida.mapa.punto_libre(partida.johnny.position, 300.0))


# Fuera todos los zombis y jefes (menos la diana), sin que cuenten como muertos
func borrar_zombis() -> void:
	var s := sala()
	for z in get_tree().get_nodes_in_group("zombis"):
		if s == null or z != s.diana:
			z.queue_free()
	partida.get_node("Pantalla/Jefa").hide()
	partida.decir("Zombis borrados")


func cerrar() -> void:
	if fondo == null:
		return
	quitar()
	get_tree().paused = false


func quitar() -> void:
	if fondo:
		fondo.queue_free()
		fondo = null
	pestanas.clear()


func _unhandled_input(evento: InputEvent) -> void:
	if fondo == null:
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa") \
			or (evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_P):
		get_viewport().set_input_as_handled()
		cerrar()
