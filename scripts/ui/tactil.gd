# Los controles táctiles del móvil, como el #touch-ui del JS (src/input.js, index.html):
#   - Joystick izquierdo: se toca en cualquier sitio de la mitad izquierda y se arrastra (sale donde se toca).
#   - Abajo a la derecha, según el modo de atacar: nada en el asistido (ataca solo), el botón de atacar en el
#     de "hacia donde mira" (mientras se mantiene, ataca) y un joystick derecho en el libre (apunta y dispara).
#   - Alrededor, en arco: esquivar, las dos armas (tocar la otra la saca; tocar la de fuego que ya está en la
#     mano, recarga) y lanzar (se arrastra desde él para apuntar y se suelta para tirar), con el ⇄ al lado
#     para cambiar lo que se lanza.
#   - Bajo el minimapa: cambiar el modo de atacar, el inventario y la pausa.
# Los botones "pulsan" las mismas acciones que el teclado y el mando (eventos de acción), así que Johnny y
# los lanzables no saben si es un dedo o una tecla.
# Solo sale en pantallas táctiles y solo mientras se juega: en la pausa y en las pantallas (inventario, baúl,
# ordenador...) se esconde, y allí el dedo hace de ratón. Mientras se juega, el toque NO hace de ratón (si
# no, cada toque del joystick sería un clic de atacar).
class_name Tactil
extends CanvasLayer

const RADIO_JOY := 70.0        # cuánto se puede arrastrar el joystick (unidades de la pantalla)
const ARRASTRE_LANZAR := 90.0  # cuánto hay que arrastrar desde lanzar para el alcance máximo (el TOSS_DRAG del JS)
const OSCURO := Color(0.06, 0.05, 0.09, 0.55)
const BORDE := Color(0.85, 0.82, 0.74, 0.5)

static var activo := false     # si la pantalla es táctil (se decide una vez y vale para todas las escenas)

var partida: Node
var johnny: Node2D
var lienzo := Control.new()    # donde se dibuja todo
var dedos := {}                # cada dedo en la pantalla (su índice) → qué está haciendo: "joy", "apunte", o un botón
var joy_origen := Vector2.ZERO # dónde se tocó para el joystick izquierdo
var joy := Vector2.ZERO        # cómo de empujado está (de -1 a 1)
var apunte := Vector2.ZERO     # el joystick derecho (modo libre) o el arrastre desde lanzar
var soltar_apunte := 0         # al soltar lanzar, el apunte dura un fotograma más (para que el molotov vaya allí)
var pulsados := {}             # botón → true, para dibujarlo hundido
var iconos := {}               # nombre → su imagen (assets/ui/iconos)


# ¿Es táctil la pantalla? Se mira al arrancar (el menú principal y la partida); si luego llega un toque de
# verdad, también. En el móvil la pantalla se agranda sin redondear: con tantos píxeles por punto, por
# números enteros se quedaría en 1 y se vería medio edificio con los muñecos diminutos
static func preparar(arbol: SceneTree) -> void:
	if DisplayServer.is_touchscreen_available():
		activo = true
	if activo:
		arbol.root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


# En la web, si el navegador deja poner la pantalla completa (en iPhone no se puede)
static func puede_pantalla_completa() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("!!document.fullscreenEnabled", true))
	return true


static func pantalla_completa() -> void:
	var completa := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if completa else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _ready() -> void:
	layer = 5   # por encima del HUD, por debajo de los menús
	process_mode = Node.PROCESS_MODE_ALWAYS   # también en la pausa, para esconderse
	preparar(get_tree())
	lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.set_anchors_preset(Control.PRESET_FULL_RECT)
	lienzo.draw.connect(dibujar)
	add_child(lienzo)


func _exit_tree() -> void:
	soltar_todo()
	Input.emulate_mouse_from_touch = true


# Si se ve ahora: táctil, jugando, sin pausa ni pantallas encima
func jugando() -> bool:
	return activo and johnny != null and johnny.vivo and not get_tree().paused and not partida.terminada


func _process(_delta: float) -> void:
	var ver := jugando()
	if ver != visible:
		visible = ver
		if not ver:
			soltar_todo()
	# Mientras se juega, el dedo no hace de ratón; en los menús, sí
	Input.emulate_mouse_from_touch = not ver
	if ver:
		johnny.con_raton = false   # que no apunte al último sitio tocado en un menú
	lienzo.queue_redraw()


func _physics_process(_delta: float) -> void:
	if soltar_apunte > 0:
		soltar_apunte -= 1
		if soltar_apunte == 0 and not "apunte" in dedos.values():
			apunte = Vector2.ZERO
			ejes("apuntar", apunte)


# ── Dónde está cada cosa (cambia con el tamaño de la pantalla) ──

func tamano() -> Vector2:
	return lienzo.get_viewport_rect().size


# El centro del botón grande de abajo a la derecha (atacar o joystick derecho)
func centro() -> Vector2:
	var s := tamano()
	return Vector2(s.x - 140, s.y - 140)


# Los botones: nombre → [centro, radio]. Las armas, esquivar y lanzar, en arco alrededor del grande
func botones() -> Dictionary:
	var c := centro()
	var s := tamano()
	var en_arco := func(grados: float, r: float) -> Vector2: return c + Vector2.from_angle(deg_to_rad(grados)) * r
	var b := {
		"esquivar": [en_arco.call(180.0, 140.0), 44.0],
		"cuerpo": [en_arco.call(218.0, 145.0), 34.0],
		"fuego": [en_arco.call(252.0, 145.0), 34.0],
		"lanzar": [en_arco.call(288.0, 145.0), 38.0],
		"cambiar_lanzable": [en_arco.call(288.0, 145.0) + Vector2(56, -24), 20.0],
		"modo": [Vector2(s.x - 150, 150), 22.0],
		"inventario": [Vector2(s.x - 97, 150), 22.0],
		"pausa": [Vector2(s.x - 44, 150), 22.0],
	}
	if johnny.modo == "mira":
		b["atacar"] = [c, 62.0]
	return b


# ── Los dedos ──

func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and evento.pressed and not activo:
		activo = true   # un ordenador con pantalla táctil: sale al primer toque
		preparar(get_tree())
	if not visible:
		return
	if evento is InputEventScreenTouch:
		if evento.pressed:
			tocar(evento.index, evento.position)
		else:
			levantar(evento.index)
		get_viewport().set_input_as_handled()
	elif evento is InputEventScreenDrag and dedos.has(evento.index):
		arrastrar(evento.index, evento.position)
		get_viewport().set_input_as_handled()


func tocar(dedo: int, donde: Vector2) -> void:
	# ¿Un botón? (con un poco de margen, que el dedo es gordo)
	var b := botones()
	for nombre in b:
		if donde.distance_to(b[nombre][0]) <= b[nombre][1] + 10.0:
			dedos[dedo] = nombre
			pulsar(nombre, true)
			return
	# El joystick derecho del modo libre: alrededor del botón grande
	if johnny.modo == "libre" and donde.distance_to(centro()) <= RADIO_JOY * 1.5 and not "apunte" in dedos.values():
		dedos[dedo] = "apunte"
		arrastrar(dedo, donde)
		return
	# El joystick izquierdo: en cualquier sitio de la mitad izquierda
	if donde.x < tamano().x * 0.5 and not "joy" in dedos.values():
		dedos[dedo] = "joy"
		joy_origen = donde
		joy = Vector2.ZERO


func arrastrar(dedo: int, donde: Vector2) -> void:
	match dedos[dedo]:
		"joy":
			joy = ((donde - joy_origen) / RADIO_JOY).limit_length(1.0)
			ejes("", joy)
		"apunte":
			apunte = ((donde - centro()) / RADIO_JOY).limit_length(1.0)
			ejes("apuntar", apunte)
		"lanzar":
			apunte = ((donde - botones().lanzar[0]) / ARRASTRE_LANZAR).limit_length(1.0)
			ejes("apuntar", apunte)


func levantar(dedo: int) -> void:
	if not dedos.has(dedo):
		return
	var que: String = dedos[dedo]
	dedos.erase(dedo)
	match que:
		"joy":
			joy = Vector2.ZERO
			ejes("", joy)
		"apunte":
			apunte = Vector2.ZERO
			ejes("apuntar", apunte)
		_:
			pulsar(que, false)


# Un botón apretado (o soltado)
func pulsar(nombre: String, abajo: bool) -> void:
	if abajo:
		pulsados[nombre] = true
	else:
		pulsados.erase(nombre)
	match nombre:
		"esquivar", "atacar", "cambiar_lanzable":
			accion(nombre, abajo)
		"lanzar":
			accion("lanzar", abajo)
			if abajo:
				apunte = Vector2.ZERO
				ejes("apuntar", apunte)
			else:
				soltar_apunte = 2   # que el molotov caiga donde se apuntaba
		"cuerpo", "fuego":
			# la otra arma: cambiar; la de fuego que ya está en la mano: recargar
			accion("recargar" if johnny.mano == nombre else "cambiar_arma", abajo)
		"modo":
			accion("cambiar_modo", abajo)
		"inventario":
			if abajo:
				partida.abrir_cosas("inventario")
		"pausa":
			if abajo:
				partida.pausar()


# Como si se pulsara una tecla: un evento de la acción (así cuenta como "recién pulsada" en el siguiente
# fotograma de física; Input.action_press a veces no)
func accion(nombre: String, abajo: bool, fuerza := 1.0) -> void:
	if Input.is_action_pressed(nombre) == abajo and (not abajo or is_equal_approx(Input.get_action_strength(nombre), fuerza)):
		return
	var e := InputEventAction.new()
	e.action = nombre
	e.pressed = abajo
	e.strength = fuerza if abajo else 0.0
	Input.parse_input_event(e)


# Un joystick en las cuatro acciones de su eje ("" para andar, "apuntar" para apuntar), con su fuerza
func ejes(prefijo: String, v: Vector2) -> void:
	var p := prefijo + "_" if prefijo != "" else ""
	for par in [["izquierda", -v.x], ["derecha", v.x], ["arriba", -v.y], ["abajo", v.y]]:
		accion(p + par[0], par[1] > 0.0, maxf(par[1], 0.0))


# Al esconderse (pausa, menús): nada se queda apretado
func soltar_todo() -> void:
	for dedo in dedos.keys():
		levantar(dedo)
	dedos.clear()
	pulsados.clear()
	joy = Vector2.ZERO
	apunte = Vector2.ZERO
	ejes("", joy)
	ejes("apuntar", apunte)
	soltar_apunte = 0
	# solo las que estén apretadas: soltar una que no lo está cuenta igual como "soltada" (y lanzaba un molotov)
	for nombre in ["esquivar", "atacar", "lanzar", "cambiar_lanzable", "recargar", "cambiar_arma", "cambiar_modo"]:
		if Input.is_action_pressed(nombre):
			Input.action_release(nombre)


# ── El dibujo ──

func dibujar() -> void:
	var s := tamano()
	if s.y > s.x:
		texto(Vector2(s.x / 2, s.y / 2), "Gira el móvil para jugar mejor", 24, Tema.TINTA)
	# El joystick izquierdo, donde se tocó
	if "joy" in dedos.values():
		lienzo.draw_circle(joy_origen, RADIO_JOY, OSCURO)
		lienzo.draw_arc(joy_origen, RADIO_JOY, 0, TAU, 48, BORDE, 2.0)
		lienzo.draw_circle(joy_origen + joy * RADIO_JOY, 28.0, Color(0.85, 0.82, 0.74, 0.6))
	# El joystick derecho (modo libre), siempre a la vista
	if johnny.modo == "libre":
		var c := centro()
		lienzo.draw_circle(c, RADIO_JOY, OSCURO)
		lienzo.draw_arc(c, RADIO_JOY, 0, TAU, 48, Color(Tema.ROJO, 0.6), 2.0)
		var mover := apunte if "apunte" in dedos.values() else Vector2.ZERO
		lienzo.draw_circle(c + mover * RADIO_JOY, 28.0, Color(Tema.ROJO, 0.55))
		icono(c + mover * RADIO_JOY, "diana", 32)
	var b := botones()
	var lz: Lanzables = partida.lanzables
	for nombre in b:
		var donde: Vector2 = b[nombre][0]
		var r: float = b[nombre][1]
		if pulsados.has(nombre):
			donde += Vector2(0, 3)   # hundido
		var borde := BORDE
		if nombre == johnny.mano:
			borde = Color(Tema.AMARILLO, 0.9)
		elif nombre == "atacar":
			borde = Color(Tema.ROJO, 0.7)
		lienzo.draw_circle(donde, r, OSCURO)
		lienzo.draw_arc(donde, r, 0, TAU, 40, borde, 2.5 if nombre == johnny.mano else 2.0)
		match nombre:
			"esquivar":
				icono(donde, "dash", 52)
				if johnny.esquiva_espera > 0.0:
					lienzo.draw_circle(donde, r, Color(0, 0, 0, 0.45))
			"cuerpo", "fuego":
				icono(donde, Objetos.icono(johnny.huecos[nombre]), 40)
				# recargando: un aro blanco que se va llenando (como en el JS)
				if nombre == "fuego" and johnny.recargando > 0.0:
					var w: Dictionary = Armas.datos(johnny.huecos.fuego)
					var hecho: float = 1.0 - johnny.recargando / maxf(0.01, w.get("recarga", 1.0))
					lienzo.draw_arc(donde, r + 4, -PI / 2, -PI / 2 + TAU * clampf(hecho, 0, 1), 32, Color.WHITE, 3.0)
			"lanzar":
				var k: String = lz.tipo
				var ico: String = k if k in ["molotov", "granada"] else Objetos.icono(Recetas.LISTA[k].icono)
				icono(donde, ico, 40)
				texto(donde + Vector2(r * 0.6, r * 0.75), str(lz.cuantas(k)), 16, Tema.TINTA)
			"cambiar_lanzable":
				# el que vendría después (el ⇄ del JS: la fuente pixel art no tiene flechas)
				var ks := lz.tipos()
				var otro: String = ks[(ks.find(lz.tipo) + 1) % ks.size()]
				icono(donde, otro if otro in ["molotov", "granada"] else Objetos.icono(Recetas.LISTA[otro].icono), 22)
			"atacar":
				icono(donde, Objetos.icono(johnny.huecos[johnny.mano]), 56)
			"modo":
				icono(donde, "diana", 26)
			"inventario":
				icono(donde, "mochila", 26)
			"pausa":
				icono(donde, "pausa", 26)
	# Mientras se apunta desde lanzar, hasta dónde se ha arrastrado
	if "lanzar" in dedos.values():
		var desde: Vector2 = b.lanzar[0]
		lienzo.draw_line(desde, desde + apunte * ARRASTRE_LANZAR, Color(lz.color(lz.tipo), 0.8), 3.0)
		lienzo.draw_circle(desde + apunte * ARRASTRE_LANZAR, 8.0, Color(lz.color(lz.tipo), 0.8))


func icono(donde: Vector2, nombre: String, lado: float) -> void:
	# se guardan: si no, la imagen se suelta antes de que se pinte y sale un cuadrado blanco
	if not iconos.has(nombre):
		var ruta := "res://assets/ui/iconos/%s.png" % nombre
		iconos[nombre] = load(ruta) if ResourceLoader.exists(ruta) else null
	var t: Texture2D = iconos[nombre]
	if t == null:
		return
	var escala := lado / maxf(t.get_width(), t.get_height())
	var tam := t.get_size() * escala
	lienzo.draw_texture_rect(t, Rect2(donde - tam / 2, tam), false)


func texto(donde: Vector2, que: String, tam: int, color: Color) -> void:
	var ancho := Tema.FUENTE.get_string_size(que, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var pos := donde + Vector2(-ancho / 2, tam * 0.35)
	lienzo.draw_string_outline(Tema.FUENTE, pos, que, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 4, Tema.LINEA)
	lienzo.draw_string(Tema.FUENTE, pos, que, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
