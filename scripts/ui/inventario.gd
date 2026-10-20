# Las pantallas de las cosas de Johnny (fase 7b; en el JS, showInventario y showBaul de src/ui.js y el banco
# de src/banco.js). El juego se para mientras están abiertas:
#   - Inventario (Tab, I o Select): las dos armas que lleva, las que guarda (la que deja al comprar otra
#     cuerpo a cuerpo) y la mochila. Al tocar una casilla se elige y salen sus botones: "Ponérmela" (las
#     armas guardadas) y "Tirar al suelo" (los objetos, de uno en uno, y las armas guardadas).
#   - Baúl (al arrimarse a él en la sala de mantenimiento): los objetos guardados de otras partidas y las armas
#     creadas en el banco. Sacarlas y usarlas es la fase 7b2.
#   - Banco de trabajo (al arrimarse a él): arriba, todo lo que se puede combinar (las armas de la receta que
#     lleva y los objetos de la mochila y del baúl). Se tocan dos cosas, suben a la mesa y, si hacen una receta
#     (recetas.gd), se puede crear el arma: sale con una rareza al azar, los ingredientes se gastan (los objetos,
#     primero de la mochila) y el arma va al baúl.
# Van con el ratón, con flechas + Intro o con el mando (A elige, B cierra).
extends CanvasLayer

signal cerrado

const CASILLA := Vector2(108, 100)
const FONDO_CASILLA := Color("#1b1822")

var partida: Node
var fondo: ColorRect
var abierto := ""          # "inventario", "baul", "banco" o "" (nada)
var sel := ""              # la casilla elegida: "m2" la 3.ª de la mochila, "g0" la 1.ª arma guardada, "a1" la 2.ª arma del baúl
var puestos: Array = []    # banco: las claves de lo que hay en la mesa (dos como mucho)
var hecha := {}            # banco: el arma que se acaba de crear (para enseñarla)
var foco := ""             # el botón que tiene que quedar marcado al volver a pintar


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abrir(que: String, p: Node) -> void:
	partida = p
	abierto = que
	sel = ""
	puestos = []
	hecha = {}
	foco = ""
	pintar(true)


func cerrar() -> void:
	if abierto == "":
		return
	abierto = ""
	if fondo:
		fondo.queue_free()
		fondo = null
	cerrado.emit()


func pintar(entrar := false) -> void:
	if fondo:
		fondo.queue_free()
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
	columna.add_theme_constant_override("separation", 8)
	panel.add_child(columna)
	if entrar:
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2(0.9, 0.9)
		panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
		panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var primero: Control
	match abierto:
		"inventario": primero = pintar_inventario(columna)
		"baul": primero = pintar_baul(columna)
		"banco": primero = pintar_banco(columna)
	# se queda marcado el mismo botón que antes (o el primero)
	var marcado: Control = fondo.find_child(foco, true, false) if foco != "" else null
	if marcado == null or not marcado.focus_mode == Control.FOCUS_ALL:
		marcado = primero
	if marcado:
		marcado.grab_focus.call_deferred()


# ── Inventario ──

func pintar_inventario(columna: VBoxContainer) -> Control:
	var johnny: Node2D = partida.johnny
	var mochila: Array = partida.mochila
	var guardadas: Array = partida.armas_guardadas
	titulo(columna, "Inventario")
	subtitulo(columna, "Armas", "")
	var armas := fila(columna)
	for hueco in ["cuerpo", "fuego"]:
		var id: String = johnny.huecos[hueco]
		casilla(armas, "", Objetos.icono(id), Armas.DATOS[id].nombre, "En la mano" if hueco == "cuerpo" else "De fuego",
			Recetas.GRIS)
	for i in guardadas.size():
		casilla(armas, "g%d" % i, Objetos.icono(guardadas[i]), Objetos.nombre(guardadas[i]), "Guardada", Recetas.GRIS)
	var llenas := Objetos.casillas(mochila)
	subtitulo(columna, "Mochila · %d / %d" % [llenas.size(), Objetos.MOCHILA], "mochila")
	var rejilla := GridContainer.new()
	rejilla.columns = 4
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	for i in Objetos.MOCHILA:
		if i < llenas.size():
			var id: String = llenas[i][0]
			var n: int = llenas[i][1]
			casilla(rejilla, "m%d" % i, Objetos.icono(id), Objetos.nombre(id), "× %d" % n if n > 1 else "", Recetas.GRIS)
		else:
			casilla(rejilla, "", "", "", "", Color(0, 0, 0, 0))
	var texto := "Lo que llevas en la mochila pasa al baúl si completas el edificio. Si caes, se pierde."
	if sel != "":
		texto = "Si lo tiras, se queda en el suelo: puedes volver a cogerlo." + (" Se tira de uno en uno." if sel[0] == "m" else "")
	nota(columna, texto)
	var botones := fila(columna, true)
	if sel.begins_with("g"):
		boton(botones, "poner", "Ponérmela", poner_guardada)
	if sel != "":
		boton(botones, "tirar", "Tirar al suelo", tirar, "BotonRojo")
	boton(botones, "cerrar", "Seguir", cerrar)
	return fondo.find_child("m0", true, false) if not llenas.is_empty() else fondo.find_child("cerrar", true, false)


# Se pone en la mano el arma guardada elegida; la que llevaba pasa a las guardadas
func poner_guardada() -> void:
	var i := sel.substr(1).to_int()
	var guardadas: Array = partida.armas_guardadas
	if i >= guardadas.size():
		return
	var johnny: Node2D = partida.johnny
	var id: String = guardadas[i]
	guardadas[i] = johnny.huecos[Armas.DATOS[id].tipo]
	johnny.coger(id)
	sel = ""
	foco = "cerrar"
	pintar()


# Tira al suelo, a los pies de Johnny, lo elegido: un objeto de la mochila (uno) o un arma guardada
func tirar() -> void:
	var i := sel.substr(1).to_int()
	var mochila: Array = partida.mochila
	if sel.begins_with("m"):
		var llenas := Objetos.casillas(mochila)
		if i >= llenas.size():
			return
		var id: String = llenas[i][0]
		mochila.remove_at(mochila.rfind(id))
		partida.soltar_objeto(id, partida.johnny.position + Vector2(0, 34), true)
		if not id in mochila:
			sel = ""
	elif sel.begins_with("g"):
		var id: String = partida.armas_guardadas[i]
		partida.armas_guardadas.remove_at(i)
		partida.soltar_arma(id, partida.johnny.position + Vector2(0, 34))
		sel = ""
	foco = sel if sel != "" else "cerrar"
	pintar()


# ── Baúl ──

func pintar_baul(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	titulo(columna, "Baúl · %d / %d" % [Objetos.casillas_baul(s), Objetos.BAUL])
	var rejilla := GridContainer.new()
	rejilla.columns = 6
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	var n := 0
	for i in s.baul_armas.size():
		var a: Dictionary = s.baul_armas[i]
		casilla(rejilla, "a%d" % i, Objetos.icono(a.icono), a.nombre, Recetas.detalle(a), Recetas.RAREZAS[a.rareza].color)
		n += 1
	for id in Objetos.NOMBRES:
		if s.baul.get(id, 0) > 0:
			casilla(rejilla, "o_" + id, Objetos.icono(id), Objetos.nombre(id), "× %d" % s.baul[id], Recetas.GRIS, false)
			n += 1
	for i in range(n, maxi(Objetos.BAUL, ceili(n / 6.0) * 6)):
		casilla(rejilla, "", "", "", "", Color(0, 0, 0, 0))
	var texto := "Está vacío. Lo que lleves en la mochila se guarda aquí al completar un edificio, y aquí van las armas que crees en el banco de trabajo."
	if sel.begins_with("a"):
		var a: Dictionary = s.baul_armas[sel.substr(1).to_int()]
		texto = "%s (%s, %s): %s. Sacarla y usarla llega en la próxima fase." % [a.nombre,
			Recetas.RAREZAS[a.rareza].nombre.to_lower(), Recetas.HUECOS[a.hueco].to_lower(), a.desc]
	elif n > 0:
		texto = "Aquí se guarda lo que traes en la mochila al completar un edificio, y las armas que creas en el banco de trabajo."
	nota(columna, texto, 640)
	var botones := fila(columna, true)
	boton(botones, "cerrar", "Cerrar", cerrar)
	return fondo.find_child("a0", true, false) if not s.baul_armas.is_empty() else fondo.find_child("cerrar", true, false)


# ── Banco de trabajo ──

# Todo lo que se puede poner en el banco. "clave" dice de dónde sale: "mano" el arma cuerpo a cuerpo que lleva,
# "g1" la 2.ª arma guardada, "o_clavos" ese objeto (sumando los de la mochila y los del baúl)
func ingredientes() -> Array:
	var lista := []
	var mano: String = partida.johnny.huecos.cuerpo
	if mano in Recetas.ARMAS:
		lista.append({"clave": "mano", "id": mano, "nota": "En la mano"})
	var guardadas: Array = partida.armas_guardadas
	for i in guardadas.size():
		if guardadas[i] in Recetas.ARMAS:
			lista.append({"clave": "g%d" % i, "id": guardadas[i], "nota": "Guardada"})
	var baul: Dictionary = Guardado.cargar().baul
	for id in Objetos.NOMBRES:
		var n: int = partida.mochila.count(id) + baul.get(id, 0)
		if n > 0:
			lista.append({"clave": "o_" + id, "id": id, "nota": "× %d" % n})
	return lista


func pintar_banco(columna: VBoxContainer) -> Control:
	var ings := ingredientes()
	# si algo de lo puesto ya no está (se gastó), se quita de la mesa
	puestos = puestos.filter(func(c): return ings.any(func(g): return g.clave == c))
	var mesa := puestos.map(func(c): return ings.filter(func(g): return g.clave == c)[0])
	var receta := Recetas.buscar(mesa[0].id, mesa[1].id) if mesa.size() == 2 else ""
	var lleno := receta != "" and not cabe_en_baul(mesa)
	titulo(columna, "Banco de trabajo")
	subtitulo(columna, "Tus cosas", "")
	var rejilla := GridContainer.new()
	rejilla.columns = 8
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	for g in ings:
		casilla(rejilla, g.clave, Objetos.icono(g.id), Objetos.nombre(g.id), g.nota, Recetas.GRIS, true, g.clave in puestos)
	if ings.is_empty():
		nota(columna, "No tienes nada que combinar. Los objetos los sueltan los zombis.")
	# la mesa: lo puesto + lo puesto = lo que sale
	var linea := fila(columna, true)
	for i in 2:
		if i < mesa.size():
			casilla(linea, "", Objetos.icono(mesa[i].id), Objetos.nombre(mesa[i].id), "", Recetas.GRIS)
		else:
			casilla(linea, "", "", "Elige algo", "", Color(1, 1, 1, 0.15))
		signo(linea, "+" if i == 0 else "=")
	if not hecha.is_empty() and mesa.is_empty():
		casilla(linea, "", Objetos.icono(hecha.icono), hecha.nombre, Recetas.detalle(hecha), Recetas.RAREZAS[hecha.rareza].color)
	elif receta != "":
		var r: Dictionary = Recetas.LISTA[receta]
		casilla(linea, "", Objetos.icono(r.icono), r.nombre, Recetas.HUECOS[r.hueco], Recetas.GRIS)
	else:
		casilla(linea, "", "", "Esto no combina" if mesa.size() == 2 else "?", "", Color(1, 1, 1, 0.15))
	var texto := "Toca dos cosas para ponerlas en la mesa. Si hacen receta, puedes crear un arma."
	if lleno:
		texto = "El baúl está lleno: haz sitio antes de crear otra arma."
	elif receta != "":
		texto = "%s. Al crearla, los dos ingredientes se gastan y el arma va al baúl." % Recetas.LISTA[receta].desc
	elif not hecha.is_empty() and mesa.is_empty():
		texto = "¡%s %s! %s. Está en el baúl." % [hecha.nombre, Recetas.RAREZAS[hecha.rareza].nombre.to_lower(), hecha.desc]
	nota(columna, texto, 640)
	var botones := fila(columna, true)
	var crear := boton(botones, "crear", "Crear", crear_arma, "BotonGrande")
	crear.disabled = receta == "" or lleno
	boton(botones, "cerrar", "Cerrar", cerrar)
	if receta != "" and not lleno:
		return crear
	return fondo.find_child(ings[0].clave, true, false) if not ings.is_empty() else fondo.find_child("cerrar", true, false)


# Toca una cosa: si ya estaba en la mesa se quita; si no, se pone (la tercera sustituye a la segunda)
func poner_en_mesa(clave: String) -> void:
	hecha = {}
	if clave in puestos:
		puestos.erase(clave)
	elif puestos.size() < 2:
		puestos.append(clave)
	else:
		puestos[1] = clave
	foco = clave
	pintar()


func crear_arma() -> void:
	var ings := ingredientes()
	var mesa := []
	for c in puestos:
		for g in ings:
			if g.clave == c:
				mesa.append(g)
	if mesa.size() != 2:
		return
	var receta := Recetas.buscar(mesa[0].id, mesa[1].id)
	if receta == "" or not cabe_en_baul(mesa):
		return
	var johnny: Node2D = partida.johnny
	# se gastan los ingredientes (las armas guardadas, de la última a la primera para no liar los números)
	var guardadas := mesa.filter(func(g): return g.clave.begins_with("g")).map(func(g): return g.clave.substr(1).to_int())
	guardadas.sort()
	guardadas.reverse()
	for i in guardadas:
		partida.armas_guardadas.remove_at(i)
	var sin_mano := false
	for g in mesa:
		if g.clave == "mano":
			sin_mano = true
		elif g.clave.begins_with("o_"):
			gastar_objeto(g.id)
	# si se ha gastado el arma de la mano, coge otra (la fregona, si no guarda ninguna)
	if sin_mano:
		var otra := "fregona"
		for id in partida.armas_guardadas:
			if Armas.DATOS[id].tipo == "cuerpo":
				otra = id
				break
		partida.armas_guardadas.erase(otra)
		johnny.coger(otra)
	hecha = Recetas.crear(receta)
	Guardado.cambiar(func(s): s.baul_armas.append(hecha))
	puestos = []
	foco = "cerrar"
	pintar()


# Gasta un objeto: primero de la mochila y, si no hay ahí, del baúl
func gastar_objeto(id: String) -> void:
	var mochila: Array = partida.mochila
	if id in mochila:
		mochila.remove_at(mochila.rfind(id))
		return
	Guardado.cambiar(func(s):
		s.baul[id] = s.baul.get(id, 0) - 1
		if s.baul[id] <= 0:
			s.baul.erase(id))


# ¿Hay sitio en el baúl para el arma? Cuenta que los objetos que se gastan del baúl pueden dejar libre su casilla
func cabe_en_baul(mesa: Array) -> bool:
	var s := Guardado.cargar()
	var usadas := Objetos.casillas_baul(s)
	for g in mesa:
		if g.clave.begins_with("o_") and not g.id in partida.mochila and s.baul.get(g.id, 0) == 1:
			usadas -= 1
	return usadas < Objetos.BAUL


# ── Piezas ──

func titulo(columna: VBoxContainer, texto: String) -> void:
	var t := Label.new()
	t.theme_type_variation = "Titulo"
	t.text = texto
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(t)


func subtitulo(columna: VBoxContainer, texto: String, icono: String) -> void:
	var t := Tema.icono_y_texto(icono, texto, 20)
	t.get_child(t.get_child_count() - 1).add_theme_color_override("font_color", Tema.AMARILLO)
	columna.add_child(t)


func nota(columna: VBoxContainer, texto: String, ancho := 0) -> void:
	var t := Label.new()
	t.theme_type_variation = "Sub"
	t.text = texto
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size.x = ancho if ancho > 0 else 430
	columna.add_child(t)


func fila(columna: VBoxContainer, centrada := false) -> HBoxContainer:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 6)
	if centrada:
		f.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(f)
	return f


func signo(f: HBoxContainer, texto: String) -> void:
	var t := Label.new()
	t.text = texto
	t.theme_type_variation = "Titulo"
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(t)


func boton(caja: Container, nombre: String, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.theme_type_variation = variacion
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


# Una casilla con su dibujo, su nombre y una línea de debajo, con el borde del color de su rareza.
# Con "clave" se puede tocar (es un botón): en el inventario y el baúl se elige; en el banco, sube a la mesa.
func casilla(padre: Container, clave: String, icono: String, nombre: String, sub: String, borde: Color,
		tocable := true, puesta := false) -> Control:
	var c: Control
	var elegida := puesta or (clave != "" and clave == sel)
	if clave != "" and tocable:
		var b := Button.new()
		b.name = clave
		b.pressed.connect(tocar.bind(clave))
		b.add_theme_stylebox_override("normal", estilo(borde, elegida, false))
		b.add_theme_stylebox_override("hover", estilo(borde, elegida, true))
		b.add_theme_stylebox_override("pressed", estilo(borde, true, true))
		b.add_theme_stylebox_override("focus", estilo(Tema.AMARILLO, false, false, true))
		c = b
	else:
		c = Panel.new()
		if clave != "":
			c.name = clave
		c.add_theme_stylebox_override("panel", estilo(borde, false, false))
	c.custom_minimum_size = CASILLA
	padre.add_child(c)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
	dentro.offset_left = 4
	dentro.offset_right = -4
	dentro.offset_top = 6
	dentro.offset_bottom = -4
	dentro.add_theme_constant_override("separation", 0)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(dentro)
	if icono != "":
		var imagen := TextureRect.new()
		imagen.texture = load("res://assets/ui/iconos/%s.png" % icono)
		imagen.custom_minimum_size = Vector2(0, 36)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(imagen)
	for i in 2:
		var texto := nombre if i == 0 else sub
		if texto == "":
			continue
		var t := Label.new()
		t.text = texto
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_font_size_override("font_size", 16)
		t.add_theme_constant_override("line_spacing", -4)
		if i == 1:
			t.add_theme_color_override("font_color", Tema.GRIS)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(t)
	return c


func estilo(borde: Color, elegida: bool, encima: bool, solo_borde := false) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0) if solo_borde else (Color("#3a3226") if elegida else (Color("#26222e") if encima else FONDO_CASILLA))
	e.border_color = Tema.AMARILLO if elegida else borde
	e.set_border_width_all(3 if (elegida or solo_borde) else 2)
	e.set_corner_radius_all(3)
	if solo_borde:
		e.draw_center = false
		e.expand_margin_left = 2
		e.expand_margin_right = 2
		e.expand_margin_top = 2
		e.expand_margin_bottom = 2
	return e


# Al tocar una casilla: en el banco sube a la mesa; en los demás, se elige (o se deja de elegir)
func tocar(clave: String) -> void:
	if abierto == "banco":
		poner_en_mesa(clave)
		return
	sel = "" if sel == clave else clave
	foco = clave
	pintar()


# Esc, B del mando o (en el inventario) la misma tecla que lo abrió: cerrar. Va en _input porque Godot usa el
# Tabulador para pasar de un botón a otro y no llegaría
func _input(evento: InputEvent) -> void:
	if abierto == "":
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa") \
			or (abierto == "inventario" and evento.is_action_pressed("inventario")):
		get_viewport().set_input_as_handled()
		cerrar()
