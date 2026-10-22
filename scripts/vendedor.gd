# El vendedor ambulante (un evento sorpresa, eventos.gd): un superviviente con una mochila enorme que se ha plantado
# en el pasillo, con una manta en el suelo, y vende cosas por dólares. Los zombis no le hacen caso (no está en el
# grupo "presa"). Al arrimarse, el juego se para y sale su puesto (con el panel de los menús de la partida, menus.gd):
# tres cosas sorteadas de VENTA, cada una una sola vez. Se paga primero con los dólares de esta partida y, si no
# llegan, con los ahorrados (que se gastan ya, en el guardado).
#
# Lo que vende y lo que ya se ha llevado Johnny va en "datos" (eventos.gd lo guarda): al volver al pasillo, sigue igual.
extends Node2D

# Números provisionales
const VENTA := {
	"botiquin": {"nombre": "Botiquín", "icono": "botiquin", "precio": 8, "desc": "Cura como el de los baños"},
	"municion": {"nombre": "Caja de munición", "icono": "municion", "precio": 3, "desc": "Un cargador más"},
	"molotov": {"nombre": "Molotov", "icono": "molotov", "precio": 5, "desc": "Uno más para lanzar"},
	"granada": {"nombre": "Granada", "icono": "granada", "precio": 6, "desc": "Una más para lanzar"},
	"chaleco": {"nombre": "Chaleco", "icono": "casco", "precio": 10, "desc": "+30 de escudo hasta la planta siguiente"},
	"objeto": {"nombre": "Objeto sorpresa", "icono": "mochila", "precio": 6, "desc": "Uno al azar para el banco de trabajo"},
}
const OFERTAS := 3
const ESCUDO := 30.0
const FRASES := ["«Pago al contado: aquí no se fía»", "«Todo a buen precio, conserje»",
	"«Lo he sacado de las tiendas de abajo... no preguntes»"]
const LOOK := {"skin": Color("#c68642"), "hair": Color("#2b2b2b"), "shirt": Color("#8a5a2b"), "pants": Color("#4a4a3a"),
	"shoes": Color("#2e2a1f"), "hat": {"kind": "cap", "color": Color("#c0392b"), "chapa": false}, "bigote": true}

var partida: Node
var datos: Dictionary      # {pos, ofertas, vendidas, objeto}
var lista := true          # como los muebles de la sala de mantenimiento: hay que apartarse para volver a abrirlo
var persona: Persona
var manta: Node2D
var botones := {}          # id -> su botón en el puesto
var info: Label


func montar(p: Node, d: Dictionary) -> void:
	partida = p
	datos = d
	name = "Vendedor"
	position = d.pos
	process_mode = Node.PROCESS_MODE_ALWAYS   # para cerrar el puesto con Esc (con el juego parado)
	# la manta del suelo, delante, con lo que vende encima
	manta = Node2D.new()
	manta.name = "Manta"
	manta.position = Vector2(0, 34)
	manta.z_index = -1
	manta.draw.connect(dibujar_manta)
	add_child(manta)
	persona = Persona.new()
	persona.look = LOOK
	persona.mira = Vector2(0.3, 1).normalized()
	persona.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(persona)
	var letrero := Label.new()
	letrero.text = "Vendedor"
	letrero.theme = Tema.crear()
	letrero.add_theme_color_override("font_color", Tema.VERDE)
	letrero.add_theme_font_size_override("font_size", 16)
	letrero.size = Vector2(120, 20)
	letrero.position = Vector2(-60, -84)
	letrero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letrero.z_index = 5
	add_child(letrero)
	# no se le atraviesa
	var cuerpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 16.0
	forma.shape = circulo
	cuerpo.add_child(forma)
	add_child(cuerpo)
	# al arrimarse, el puesto
	var zona := Area2D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 58.0
	hueco.shape = r
	hueco.position = Vector2(0, 22)
	zona.add_child(hueco)
	add_child(zona)
	zona.body_entered.connect(func(_cuerpo):
		if lista:
			lista = false
			abrir())
	zona.body_exited.connect(func(_cuerpo): lista = true)


# ── El puesto ──

func abrir() -> void:
	if partida.terminada or partida.cambiando or not partida.johnny.vivo or get_tree().paused:
		return
	get_tree().paused = true
	var columna: VBoxContainer = partida.menus.abrir("vendedor")
	partida.menus.titulo(columna, "Vendedor ambulante", FRASES.pick_random())
	botones = {}
	var primero: Button = null
	for id in datos.ofertas:
		var b := Button.new()
		b.custom_minimum_size = Vector2(520, 52)
		b.icon = load("res://assets/ui/iconos/%s.png" % VENTA[id].icono)
		b.add_theme_constant_override("icon_max_width", 32)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(comprar.bind(id))
		columna.add_child(b)
		botones[id] = b
		if primero == null and not id in datos.vendidas:
			primero = b
	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(520, 0)
	info.add_theme_font_size_override("font_size", 16)
	columna.add_child(info)
	var salir := Button.new()
	salir.text = "Seguir"
	salir.pressed.connect(cerrar)
	columna.add_child(salir)
	poner_textos()
	info.text = cuanto_tienes()
	(primero if primero else salir).grab_focus()


func cerrar() -> void:
	if partida.menus.abierto != "vendedor":
		return
	partida.menus.cerrar()
	get_tree().paused = false


func _unhandled_input(evento: InputEvent) -> void:
	if partida and partida.menus.abierto == "vendedor" and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		cerrar()


func poner_textos() -> void:
	for id in botones:
		var v: Dictionary = VENTA[id]
		var vendida: bool = id in datos.vendidas
		botones[id].text = "  %s · %s" % [v.nombre, "VENDIDO" if vendida else "$%d  —  %s" % [v.precio, v.desc]]
		botones[id].disabled = vendida


func cuanto_tienes() -> String:
	return "Tienes $%d: %d de esta partida y %d ahorrados" % [partida.cartera(), partida.dolares, partida.ahorrados]


func comprar(id: String) -> void:
	var v: Dictionary = VENTA[id]
	var no := por_que_no(id)
	if no == "" and partida.cartera() < v.precio:
		no = "No te llega: te faltan $%d" % (v.precio - partida.cartera())
	if no != "":
		info.text = no
		Sonido.tocar("no")
		return
	pagar(v.precio)
	var que := dar(id)
	datos.vendidas.append(id)
	Sonido.tocar("compra")
	poner_textos()
	info.text = "%s. %s" % [que, cuanto_tienes()]
	manta.queue_redraw()
	# el foco, a otra cosa que se pueda comprar (o a Seguir)
	for otro in botones:
		if not botones[otro].disabled:
			botones[otro].grab_focus()
			return
	info.get_parent().get_child(-1).grab_focus()


# Por qué no se puede comprar ahora ("" si se puede)
func por_que_no(id: String) -> String:
	var johnny: Node2D = partida.johnny
	if id in datos.vendidas:
		return "Eso ya te lo has llevado"
	match id:
		"botiquin":
			if johnny.vida >= johnny.vida_tope():
				return "Tienes la vida al máximo"
		"municion":
			if not johnny.quiere_municion():
				return "No te cabe más munición"
		"molotov", "granada":
			if not partida.lanzables.cabe(id):
				return "No te caben más"
		"objeto":
			if not Objetos.cabe(partida.mochila, datos.objeto):
				return "No te cabe en la mochila"
	return ""


# Primero con los dólares de la partida; lo que falte, de los ahorrados
func pagar(precio: int) -> void:
	var de_partida: int = mini(partida.dolares, precio)
	partida.dolares -= de_partida
	var resto := precio - de_partida
	if resto > 0:
		partida.ahorrados = Guardado.cambiar(func(g): g.dolares -= resto).dolares


# Lo comprado, a Johnny; devuelve lo que se dice
func dar(id: String) -> String:
	var johnny: Node2D = partida.johnny
	match id:
		"botiquin":
			var cura: int = partida.cura_botiquin()
			johnny.curar(cura)
			return "Te curas %d" % cura
		"municion":
			johnny.sumar_municion()
			return "Un cargador más"
		"molotov", "granada":
			partida.lanzables.sumar(id)
			return "+1 " + id
		"chaleco":
			johnny.escudo += ESCUDO
			return "+%d de escudo" % ESCUDO
		"objeto":
			partida.mochila.append(datos.objeto)
			Objetos.apuntar_encontrado(datos.objeto)   # para las Colecciones del ordenador
			return "Te llevas: " + Objetos.nombre(datos.objeto)
	return ""


# ── Dibujos ──

# La mochila enorme, a la espalda (asoma por encima de los hombros), con el saco de dormir enrollado encima
func _draw() -> void:
	draw_rect(Rect2(-17, -52, 34, 36), Color("#1d1b2c"))
	draw_rect(Rect2(-15, -50, 30, 32), Color("#5b6b3a"))
	draw_rect(Rect2(-15, -50, 30, 4), Color("#7a8c4f"))
	draw_rect(Rect2(-20, -60, 40, 11), Color("#1d1b2c"))
	draw_rect(Rect2(-18, -58, 36, 7), Color("#3d63c9"))
	draw_rect(Rect2(-18, -58, 36, 2), Color("#6f8fe0"))


# La manta, a cuadros, con lo que aún vende encima
func dibujar_manta() -> void:
	var ancho := 132.0
	manta.draw_rect(Rect2(-ancho / 2.0 - 2, -2, ancho + 4, 44), Color("#1d1b2c"))
	for i in 11:
		for j in 4:
			manta.draw_rect(Rect2(-ancho / 2.0 + i * 12, j * 10, 12, 10), Color("#a33a3a") if (i + j) % 2 == 0 else Color("#c8b48a"))
	var x := -ancho / 2.0 + 10
	for id in datos.ofertas:
		if not id in datos.vendidas:
			var icono: Texture2D = load("res://assets/ui/iconos/%s.png" % VENTA[id].icono)
			var tam := icono.get_size()   # (los iconos son de la pantalla: a su tamaño, como los lanzables del suelo)
			manta.draw_texture_rect(icono, Rect2(Vector2(x + 16 - tam.x / 2.0, 20 - tam.y / 2.0), tam), false)
		x += 40
