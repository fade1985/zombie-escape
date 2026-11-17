# El letrero de neón de una tienda del centro comercial, encima de su puerta en la pared de arriba del pasillo
# (lo pone mapa.gd; el texto, ya traducido, de Tienda.neon, y el color, de Tienda.TIPOS). Está roto, como todo: alguna
# letra está fundida (se ve el tubo apagado) y el resto parpadea y falla a trompicones, con la misma cuenta que los apliques (lampara.gd).
# Lleva su luz de color, que tiembla con él, y se ve aunque el pasillo esté a oscuras (no le afecta la penumbra).
extends Node2D

const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const TAMANO := 32           # la fuente pixel art a 32: cada píxel de la letra, 2 unidades (como los dibujos)
const ALTO := 104.0          # a qué altura va, por encima del pie del muro (justo encima de la puerta)
const TUBO := Color(0.3, 0.28, 0.33)   # una letra fundida: el tubo de cristal apagado

# Las tiendas que, en vez del neón de letras, tienen un letrero dibujado de letras corpóreas iluminadas por detrás (de GPT:
# assets/sprites/letrero-<tipo>.png, con su resplandor, letrero-<tipo>-halo.png de tools/letrero_halo.py), con el color de
# su luz. Van en inglés, iguales en todos los idiomas, como una marca (17 nov, el dueño)
const LETREROS := {"supermercado": Color("#3d9bff")}
const LETRERO_PIE := 98.0    # el letrero dibujado: a qué altura va su pie, por encima del pie del muro
const HALO_MARGEN := 8       # los píxeles de más del resplandor por cada lado (tools/letrero_halo.py)
# De dónde saltan las chispas (17 nov, el dueño): el píxel del letrero donde está suelta la letra caída (en el del súper,
# la esquina de abajo de la primera E, que cuelga de sus tornillos). Saltan cada vez que se va la luz del letrero (un
# cortocircuito) y, sueltas, cada CHISPAS_CADA segundos más o menos
const CHISPAS_EN := {"supermercado": Vector2(33, 15)}
const CHISPAS_CADA := Vector2(1.5, 4.5)
const CHISPAS_OIDO := 360.0  # hasta qué distancia de Johnny suenan
var chispas: CPUParticles2D
var proxima_chispa := 0.0
var destello := 0.0          # el fogonazo de la chispa en la letra, lo que le queda
var antes_b := 1.0
var desde_chispa := 99.0     # segundos desde el último chispazo (uno por apagón, aunque la luz dé varios guiños)
var dado := RandomNumberGenerator.new()

var texto := "TIENDA"   # no-tr (lo cambia siempre mapa.gd, ya traducido: Tienda.neon)
var tipo := ""          # el tipo de tienda (lo pone mapa.gd): si está en LETREROS, su letrero dibujado
var letrero: Texture2D
var halo: Texture2D
var color := Color("#ff4fa0")
var semilla := 0.5
var iluminado := false       # en Torre Velaria: un rótulo de departamento iluminado por detrás (placa blanca y fría), no un neón
var fundidas := {}           # las letras que no se encienden (su posición en el texto)
var luz: Node2D
var tiempo := 0.0
var fuente: Font


func _ready() -> void:
	fuente = Tema.crear().default_font
	tiempo = semilla * 10.0
	if LETREROS.has(tipo):
		letrero = load("res://assets/sprites/letrero-%s.png" % tipo)
		halo = load("res://assets/sprites/letrero-%s-halo.png" % tipo)
		color = LETREROS[tipo]
		if CHISPAS_EN.has(tipo):
			poner_chispas()
	# una o dos letras fundidas (nunca un espacio), elegidas con la semilla para que no cambien al volver
	var letras := []
	for i in texto.length():
		if texto[i] != " ":
			letras.append(i)
	var cuantas := 1 + int(semilla * 10.0) % 2
	for k in cuantas:
		fundidas[letras[int(fposmod(semilla * 7.31 + k * 0.37, 1.0) * letras.size())]] = true
	# lo que no se ilumina con la penumbra: el neón luce por sí mismo
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	# su luz de color en el suelo del pasillo, parpadeando (una lámpara sin bombilla ni polvo)
	luz = LAMPARA.instantiate()
	luz.parpadea = true
	luz.semilla = semilla
	luz.radio = 170.0
	luz.alto = ALTO
	luz.suelo = Vector2(0, 50)
	luz.fuerza = 0.8
	if letrero:
		luz.tramo = 7.0   # (el letrero dibujado falla menos que los neones: de vez en cuando)
	add_child(luz)
	luz.get_node("Bombilla").visible = false
	for nombre in ["LuzSuelo", "LuzCosas"]:   # no-tr (nombres de nodo)
		luz.get_node(nombre).color = color
	luz.get_node("Polvo").visible = false


func _process(delta: float) -> void:
	tiempo += delta
	if chispas:
		# un chispazo al irse la luz del letrero y, sueltos, de vez en cuando
		var b: float = luz.brillo(tiempo)
		proxima_chispa -= delta
		desde_chispa += delta
		if (antes_b >= 0.5 and b < 0.5 and desde_chispa > 1.0) or proxima_chispa <= 0.0:
			chispazo()
		antes_b = b
		destello = maxf(destello - delta, 0.0)
	queue_redraw()


# Las chispas de la letra caída: puntitos de un píxel, amarillos y blancos, que saltan hacia los lados y caen, sumando su
# luz (se ven aunque el pasillo esté a oscuras)
func poner_chispas() -> void:
	dado.seed = int(semilla * 100000.0)
	proxima_chispa = dado.randf_range(CHISPAS_CADA.x, CHISPAS_CADA.y)
	chispas = CPUParticles2D.new()
	chispas.emitting = false
	chispas.one_shot = true
	chispas.amount = 14
	chispas.lifetime = 0.7
	chispas.explosiveness = 0.9
	chispas.local_coords = false
	var t := letrero.get_size()
	chispas.position = Vector2(-t.x + CHISPAS_EN[tipo].x * 2 + 1, -LETRERO_PIE - t.y * 2 + CHISPAS_EN[tipo].y * 2 + 1)
	chispas.direction = Vector2(0, -1)
	chispas.spread = 75.0
	chispas.initial_velocity_min = 40.0
	chispas.initial_velocity_max = 120.0
	chispas.gravity = Vector2(0, 420)
	chispas.scale_amount_min = 2.0   # un píxel del dibujo
	chispas.scale_amount_max = 2.0
	var apagarse := Gradient.new()
	apagarse.set_color(0, Color(1, 1, 0.85, 1))
	apagarse.set_color(1, Color(1, 0.45, 0.1, 0))
	apagarse.add_point(0.35, Color(1, 0.85, 0.3, 1))
	chispas.color_ramp = apagarse
	var suma := CanvasItemMaterial.new()
	suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	suma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	chispas.material = suma
	chispas.z_index = 5
	add_child(chispas)


func chispazo() -> void:
	chispas.restart()
	destello = 0.1
	desde_chispa = 0.0
	proxima_chispa = dado.randf_range(CHISPAS_CADA.x, CHISPAS_CADA.y)
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and johnny.global_position.distance_to(chispas.global_position) < CHISPAS_OIDO:
		Sonido.tocar("chispa")


func _draw() -> void:
	var b: float = luz.brillo(tiempo) if luz else 1.0
	if letrero:
		dibujar_letrero(b)
		return
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO).x
	var x := -roundf(ancho / 2.0 / 2.0) * 2.0
	var y := -ALTO
	if iluminado:
		dibujar_rotulo(x, y, ancho, b)
		return
	# el soporte: una chapa oscura detrás de las letras, atornillada a la pared
	draw_rect(Rect2(x - 8, y - TAMANO + 2, ancho + 16, TAMANO + 6), Color(0.08, 0.07, 0.1, 0.85))
	for i in texto.length():
		var letra := texto[i]
		var w := fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO).x
		if letra != " ":
			if fundidas.has(i):
				draw_string(fuente, Vector2(x, y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, TUBO)
			else:
				# cada letra falla un poco por su cuenta además del parpadeo de todo el letrero
				var propio := b * (0.75 + 0.25 * sin(tiempo * (9.0 + i * 1.7) + i * 2.3))
				var c := TUBO.lerp(color, clampf(propio, 0.0, 1.0))
				# el halo: la letra un poco más gorda y transparente por detrás
				var halo := Color(color.r, color.g, color.b, 0.28 * propio)
				draw_string_outline(fuente, Vector2(x, y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, 6, halo)
				draw_string(fuente, Vector2(x, y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, c)
		x += w


# El letrero dibujado (LETREROS): primero su resplandor de color en la pared, y encima las letras, que se ven siempre (son
# de chapa: lo que se apaga es la luz de detrás). La luz luce fija y, de vez en cuando, cuando falla la de su lámpara
# (lampara.brillo: unos guiños o un apagón corto), se va casi del todo (17 nov, el dueño: antes temblaba sin parar)
func dibujar_letrero(b: float) -> void:
	var t := letrero.get_size()
	var x := -t.x   # (centrado: el dibujo, a 2 unidades por píxel)
	var y := -LETRERO_PIE - t.y * 2
	var luz_halo := 1.0 if b > 0.6 else 0.3 * clampf(b, 0.0, 1.0)
	draw_texture_rect(halo, Rect2(x - HALO_MARGEN * 2, y - HALO_MARGEN * 2, (t.x + HALO_MARGEN * 2) * 2,
		(t.y + HALO_MARGEN * 2) * 2), false, Color(color.r, color.g, color.b, 0.75 * luz_halo))
	# (las letras, algo más oscuras con la luz ida: su canto azul claro brilla con la luz de detrás)
	var sombra := lerpf(0.55, 1.0, luz_halo)
	draw_texture_rect(letrero, Rect2(x, y, t.x * 2, t.y * 2), false, Color(sombra, sombra, sombra))
	if destello > 0.0:
		# el fogonazo en la letra suelta
		var a := destello / 0.1
		draw_rect(Rect2(chispas.position - Vector2(5, 5), Vector2(10, 10)), Color(1, 0.9, 0.5, 0.35 * a))
		draw_rect(Rect2(chispas.position - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 0.9, a))


# El rótulo de un departamento de la torre: una placa blanca y fría iluminada por detrás, con el nombre en gris azulado oscuro
# en un marco de aluminio. Casi no parpadea (la luz de la torre falla poco), pero a veces se apaga un instante
func dibujar_rotulo(x: float, y: float, ancho: float, b: float) -> void:
	var luz_placa := clampf(0.55 + 0.45 * b, 0.0, 1.0)
	var placa := Color(0.84, 0.92, 1.0).lerp(color, 0.25) * Color(luz_placa, luz_placa, luz_placa, 1.0)
	var marco := Color(0.22, 0.25, 0.3)
	var rect := Rect2(x - 12, y - TAMANO + 0, ancho + 24, TAMANO + 10)
	# el halo frío alrededor
	draw_rect(rect.grow(6), Color(0.7, 0.85, 1.0, 0.12 * luz_placa))
	draw_rect(rect.grow(2), marco)
	draw_rect(rect, placa)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color(1, 1, 1, 0.5 * luz_placa))   # el brillo de arriba
	draw_string(fuente, Vector2(x, y + 2), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, Color(0.13, 0.17, 0.25))
