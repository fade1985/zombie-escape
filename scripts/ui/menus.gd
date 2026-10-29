# Los menús de dentro de la partida (como showPause y showEnd de src/ui.js):
#   - Pausa (Esc o Start): el sitio en el que estás, los atributos de Johnny y sus armas, y los botones
#     Continuar, Opciones (opciones.gd), Tutorial (tutorial.gd) y Abandonar partida. El juego se para mientras está
#     abierta.
#   - El cartel del final: "¡Edificio completado!" o "¡Derrota!", con lo que has hecho en la partida, lo conseguido
#     en ella (logros, skins, páginas... lo nuevo) y los botones de volver a jugar («Otra vez», también con la R) o ir
#     al menú principal. Al caer, a la izquierda, quién te ha pillado (quien_te_pilla).
#   - Las mutaciones (showMutacion del JS): tras caer la portera, dos cartas para elegir una (también con 1 y 2).
#   - La página del dosier recién encontrada junto a un científico muerto (historia.gd).
# Se manejan con el ratón, con el teclado (flechas e Intro) o con el mando (cruceta o stick, A para pulsar y
# B para volver): Godot pasa de un botón a otro solo, y aquí se elige cuál empieza marcado.
extends CanvasLayer

signal continuar
signal abandonar
signal reintentar
signal menu_principal

const ESPERA_FIN := 500   # milisegundos que el cartel del final no hace caso a sus botones: por si venías pegando
const DIBUJO_FICHA := 150.0   # lo más grande que sale el dibujo de quién te ha pillado (a escala entera)

# Lo que te puede pillar sin ser un enemigo (johnny.gd, golpe_de): cómo se llama, un consejo para la próxima vez y su
# icono, para el cartel de derrota. Los enemigos salen del bestiario (su dibujo, su nombre y su frase)
# [traducir]
const PELIGROS := {
	"fuego": {"nombre": "El fuego", "consejo": "Esquiva para cruzar el fuego del suelo: así no te quemas.", "icono": "molotov"},
	"veneno": {"nombre": "El veneno", "consejo": "Esquiva para cruzar los charcos: así no te hacen nada.", "icono": "obj-bidon_acido"},
	"toxico": {"nombre": "La lejía", "consejo": "Esquiva para cruzar los charcos: así no te hacen nada.", "icono": "obj-bidon_acido"},
	"acido": {"nombre": "El ácido", "consejo": "Esquiva para cruzar los charcos: así no te hacen nada.", "icono": "obj-bidon_acido"},
	"frio": {"nombre": "El frío", "consejo": "No te quedes mucho rato en la cámara frigorífica: el frío te quita vida y te frena.", "icono": "congeladora"},
	"agua": {"nombre": "El agua con corriente", "consejo": "Baja la palanca del cuadro eléctrico y el agua dejará de dar calambres.", "icono": "obj-bateria"},
	"cable": {"nombre": "El cable pelado", "consejo": "No pises el charco donde ha caído el cable: da calambres a todo el charco.", "icono": "obj-bateria"},
	"granada": {"nombre": "Tu propia granada", "consejo": "Lánzala lejos: su explosión también te hace daño a ti.", "icono": "granada"},
}
# [/traducir]

var fondo: ColorRect
var abierto := ""         # "pausa", "fin", "mutacion", "pagina", "opciones", "tutorial" o "" (nada)
var elegir_mutacion := Callable()   # a quién avisar con la mutación elegida
var cartas: Array = []    # las dos mutaciones que se ofrecen
var al_leer := Callable()  # a quién avisar al cerrar la página del dosier
var fin_desde := 0         # cuándo se abrió el cartel del final (Time.get_ticks_msec), para ESPERA_FIN


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


# "foco": qué botón empieza marcado ("" = Continuar; "opciones" = al volver de Opciones habiendo cambiado de idioma)
func pausa(partida: Node, foco := "") -> void:
	var columna := abrir("pausa")
	var johnny: Node2D = partida.johnny
	var s: Dictionary = johnny.stats
	titulo(columna, Idioma.t("Pausa"), partida.lugar.text.replace("\n", " · "))
	var lado := HBoxContainer.new()
	lado.add_theme_constant_override("separation", 28)
	columna.add_child(lado)
	var izquierda := VBoxContainer.new()
	izquierda.custom_minimum_size.x = 300
	lado.add_child(izquierda)
	var w: Dictionary = johnny.arma()
	dato(izquierda, "corazon", Idioma.t("Vida"), "%d / %d" % [johnny.vida, s.vida_max])
	dato(izquierda, "fuerza", Idioma.t("Daño"), "x" + Idioma.puntuar("%.2f" % s.dano))
	dato(izquierda, "cafe", Idioma.t("Velocidad de ataque"), "x" + Idioma.puntuar("%.2f" % s.ritmo))
	dato(izquierda, "guantes", Idioma.t("Alcance"), "x" + Idioma.puntuar("%.2f" % (s.alcance * (s.alcance_cuerpo if w.tipo == "cuerpo" else 1.0))))
	dato(izquierda, "dash", Idioma.t("Velocidad"), str(roundi(s.velocidad)))
	dato(izquierda, "casco", Idioma.t("Daño recibido"), "x" + Idioma.puntuar("%.2f" % s.dano_recibido))
	dato(izquierda, "diana", Idioma.t("Crítico"), "%d%%" % roundi(s.critico * 100))
	var derecha := VBoxContainer.new()
	lado.add_child(derecha)
	var armas := Label.new()
	armas.text = Idioma.t("Armas")
	armas.theme_type_variation = "Sub"
	derecha.add_child(armas)
	for hueco in ["cuerpo", "fuego"]:
		var id: String = johnny.huecos[hueco]
		var a: Dictionary = Armas.datos(id)
		var resumen := Idioma.t("%s · daño %d · %s/s") % [Objetos.nombre(id), a.dano * (a.get("perdigones", 1)), Idioma.puntuar("%.1f" % a.ritmo)]
		derecha.add_child(Tema.icono_y_texto(Objetos.icono(id), resumen, 20))
	var lz: Lanzables = partida.lanzables
	derecha.add_child(Tema.icono_y_texto("molotov", Idioma.t("Molotovs: %d") % lz.total("molotov"), 20))
	derecha.add_child(Tema.icono_y_texto("granada", Idioma.t("Granadas: %d") % lz.total("granada"), 20))
	if not partida.mutaciones.tengo.is_empty():
		var muts := Label.new()
		muts.text = Idioma.t("Mutaciones")
		muts.theme_type_variation = "Sub"
		derecha.add_child(muts)
		for id in partida.mutaciones.tengo:
			var m := Mutaciones.mutacion(id)
			derecha.add_child(Tema.icono_y_texto(m.icono, m.nombre, 20))
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 10)
	columna.add_child(botones)
	var seguir := boton(botones, Idioma.t("Continuar"), func(): continuar.emit())
	# Opciones (scripts/ui/opciones.gd): modo de atacar, música, sonido y controles
	var opciones := boton(botones, Idioma.t("Opciones"), func(): pass)
	opciones.pressed.connect(func():
		abierto = "opciones"
		var idioma_antes := Idioma.actual
		Opciones.abrir(self, fondo, johnny).cerrado.connect(func():
			abierto = "pausa"
			if Idioma.actual != idioma_antes:   # se ha cambiado de idioma: la pausa se monta otra vez con sus textos
				partida.poner_lugar()   # (el sitio de arriba, que se reescribe con el juego en marcha)
				pausa(partida, "opciones")
			else:
				opciones.grab_focus()))
	# El apartado Tutorial (ui/tutorial.gd): las fichas de los tutoriales vistos, para volver a leerlas
	var tutorial := boton(botones, Idioma.t("Tutorial"), func(): pass)
	tutorial.pressed.connect(func():
		abierto = "tutorial"
		Tutorial.lista(self, fondo).cerrado.connect(func():
			abierto = "pausa"
			tutorial.grab_focus()))
	# En el móvil, también aquí la pantalla completa (si el navegador la deja)
	if Tactil.activo and Tactil.puede_pantalla_completa():
		boton(botones, Idioma.t("Pantalla completa"), Tactil.pantalla_completa)
	boton(botones, Idioma.t("Abandonar partida"), func(): abandonar.emit(), "BotonRojo")   # no-tr (variación del tema)
	(opciones if foco == "opciones" else seguir).grab_focus.call_deferred()


# r: gano, titulo, sub, plantas, muertos, visitados, tiempo, dolares, salvados, cartera y, con los niveles de alerta
# (alerta.gd), alerta (la de la partida), extra (los dólares de más por ella) y abierta (la que se abre, o 0);
# con el reto del día (reto.gd), reto (el nombre de su regla), marca (la mejor de hoy), mejor (si se acaba de mejorar)
# y premio_reto (sus dólares de más, la primera vez que se completa hoy; si no, 0); asesino (al caer, quién te ha
# pillado: johnny.gd, golpe_de) y conseguido (lo nuevo de esta partida: partida.gd, conseguido)
func fin(r: Dictionary) -> void:
	var columna := abrir("fin")
	fin_desde = Time.get_ticks_msec()
	titulo(columna, r.titulo, r.sub)
	var lista := VBoxContainer.new()
	lista.custom_minimum_size.x = 440
	var ficha := quien_te_pilla(r.get("asesino", ""))
	if ficha:
		# al caer: a la izquierda quién te ha pillado y a la derecha lo de la partida
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 16)
		fila.add_child(ficha)
		fila.add_child(lista)
		columna.add_child(fila)
	else:
		columna.add_child(lista)
	dato(lista, "apartamentos", Idioma.t("Plantas superadas"), r.plantas)
	dato(lista, "zombi", Idioma.t("Enemigos derrotados"), str(r.muertos))
	dato(lista, "puerta", Idioma.t("Apartamentos visitados (última planta)"), r.visitados)
	if r.tiempo != "":
		dato(lista, "trofeo", Idioma.t("Tiempo"), r.tiempo)
	if r.get("reto", "") != "":
		dato(lista, "trofeo", Idioma.t("Reto del día · %s") % r.reto, Idioma.t("%s · ¡mejor marca de hoy!") % r.marca if r.mejor
			else Idioma.t("Tu mejor marca de hoy: %s") % r.marca, Color("#f7c440") if r.mejor else Tema.TINTA)
	if r.gano:
		var premio: int = r.get("premio_reto", 0)
		dato(lista, "billete", Idioma.t("Dólares conseguidos"), Idioma.t("+$%d  (tienes $%d)") % [r.dolares + r.extra + premio, r.cartera], Tema.VERDE)
		if r.get("alerta", 0) > 0:
			dato(lista, "alerta", Idioma.t("De ellos, por la %s") % Alerta.nombre(r.alerta), "+$%d" % r.extra, Tema.VERDE)
		if premio > 0:
			dato(lista, "trofeo", Idioma.t("De ellos, por completar el reto de hoy"), "+$%d" % premio, Tema.VERDE)
		if r.get("abierta", 0) > 0:
			dato(lista, "alerta", Idioma.t("¡Nivel nuevo!"), Idioma.t("%s abierta") % Alerta.nombre(r.abierta), Color("#f7c440"))
	else:
		# si caes, te quedas la mitad de lo recogido (partida.gd, DOLARES_AL_CAER) y la otra mitad se pierde
		dato(lista, "billete", Idioma.t("Dólares salvados (la mitad)"), Idioma.t("+$%d  (tienes $%d)") % [r.salvados, r.cartera], Tema.VERDE)
		dato(lista, "billete", Idioma.t("Dólares perdidos"), "$%d" % (r.dolares - r.salvados), Tema.ROJO)
	# lo conseguido en esta partida, solo si hay algo nuevo
	var conseguido: Array = r.get("conseguido", [])
	if not conseguido.is_empty():
		var cabeza := Label.new()
		cabeza.theme_type_variation = "Sub"
		cabeza.text = Idioma.t("Conseguido en esta partida")
		cabeza.custom_minimum_size.y = 30   # (un poco de aire con lo de arriba)
		cabeza.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lista.add_child(cabeza)
		for fila in conseguido:
			dato(lista, fila[0], fila[1], fila[2], Color("#f7c440"))
	var botones := VBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(botones)
	# «Otra vez» vuelve a empezar el edificio; con teclado, también la R (en el móvil y con mando no se dice)
	var con_r := not Tactil.activo and Input.get_connected_joypads().is_empty()
	var otra_vez := Idioma.t("Jugar otra vez") if r.gano else Idioma.t("Otra vez")
	var otra := boton(botones, "%s (R)" % otra_vez if con_r else otra_vez, al_final.bind(reintentar), "BotonGrande")   # no-tr
	boton(botones, Idioma.t("Menú principal"), al_final.bind(menu_principal))
	for b in botones.get_children():
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	otra.grab_focus.call_deferred()


# Los botones del cartel del final (y la R): no hacen caso hasta pasado ESPERA_FIN desde que se abrió
func al_final(senal: Signal) -> void:
	if abierto == "fin" and Time.get_ticks_msec() - fin_desde >= ESPERA_FIN:
		senal.emit()


# La ficha de quién te ha pillado, en el cartel de derrota: su dibujo, su nombre y su frase del bestiario (que suele
# ser una pista de cómo ganarle) o, si es un peligro (PELIGROS), su icono, su nombre y un consejo. null si no se sabe
func quien_te_pilla(id: String) -> Control:
	var dibujo: Texture2D
	var escala_max := 99
	var nombre := ""
	var frase := ""
	if id in Bestiario.LISTA:
		dibujo = Bestiario.retrato(id)
		escala_max = Bestiario.LISTA[id].escala + 1   # (uno más que en el juego; los tentáculos ya van a 1)
		nombre = Bestiario.nombre(id)
		frase = Bestiario.frase(id)
	elif id in PELIGROS:
		dibujo = load("res://assets/ui/iconos/%s.png" % PELIGROS[id].icono)
		nombre = Idioma.t(PELIGROS[id].nombre)
		frase = Idioma.t(PELIGROS[id].consejo)
	else:
		return null
	var ficha := PanelContainer.new()
	var marco := StyleBoxFlat.new()   # metal oscuro con el borde rojo
	marco.bg_color = Color(0.13, 0.06, 0.08, 0.9)
	marco.set_border_width_all(2)
	marco.border_color = Tema.ROJO
	marco.shadow_color = Tema.LINEA
	marco.shadow_size = 2
	marco.set_content_margin_all(10)
	ficha.add_theme_stylebox_override("panel", marco)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 8)
	ficha.add_child(dentro)
	var arriba := Label.new()
	arriba.theme_type_variation = "Sub"
	arriba.text = Idioma.t("Te ha pillado")
	arriba.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dentro.add_child(arriba)
	# el dibujo, a escala entera (nítido) y lo más grande que quepa en DIBUJO_FICHA
	var imagen := TextureRect.new()
	imagen.texture = dibujo
	var tam := dibujo.get_size()
	var escala := clampi(floori(minf(DIBUJO_FICHA / tam.x, DIBUJO_FICHA / tam.y)), 1, escala_max)
	imagen.custom_minimum_size = tam * escala
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dentro.add_child(imagen)
	var quien := Label.new()
	quien.text = nombre
	quien.add_theme_color_override("font_color", Tema.ROJO)
	quien.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quien.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quien.custom_minimum_size.x = 190
	dentro.add_child(quien)
	var pista := Label.new()
	pista.theme_type_variation = "Sub"
	pista.text = frase
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pista.custom_minimum_size.x = 190
	dentro.add_child(pista)
	return ficha


# El recuadro de las mutaciones: dos cartas (icono, nombre y lo que hace). "llevas": las que ya tiene
func mutacion(opciones: Array, llevas: int, al_elegir: Callable) -> void:
	var columna := abrir("mutacion", 0.8)
	elegir_mutacion = al_elegir
	cartas = opciones
	var virus := Label.new()
	virus.text = Idioma.t("La exposición prolongada al virus hace que te sientas...")
	virus.theme_type_variation = "Sub"
	virus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(virus)
	var t := Label.new()
	t.theme_type_variation = "Titulo"
	t.text = Idioma.t("¡¡¡DIFERENTE!!!")
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
	pie.text = Idioma.t("Mutación %d de %d · dura hasta que acabe la partida") % [llevas + 1, Mutaciones.MAXIMO]
	pie.theme_type_variation = "Sub"
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(pie)
	primera.grab_focus.call_deferred()


# La página del dosier que lleva el científico: quién era, la hoja y el botón de seguir
func pagina(p: Dictionary, n: int, total: int, al_cerrar: Callable) -> void:
	var columna := abrir("pagina", 0.85)
	al_leer = al_cerrar
	titulo(columna, Idioma.t("Página %d de %d") % [n, total], Idioma.t("Junto al cuerpo de %s") % Historia.cuerpo_de(p))
	var centro := CenterContainer.new()
	columna.add_child(centro)
	centro.add_child(Historia.hoja(p, 600.0))
	var pie := Label.new()
	pie.text = Idioma.t("Se guarda en el Dosier del ordenador de mantenimiento")
	pie.theme_type_variation = "Sub"
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(pie)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(fila)
	boton(fila, Idioma.t("Seguir"), leida).grab_focus.call_deferred()


func leida() -> void:
	if abierto != "pagina":
		return
	cerrar()
	al_leer.call()


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
	if abierto == "fin" and evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
		al_final(reintentar)
		return
	if abierto == "pagina" and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		leida()
		return
	if abierto == "pausa" and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		continuar.emit()
