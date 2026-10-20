# La penumbra de la partida (como src/luz.js del juego JS, pero con las luces de Godot): un CanvasModulate
# que oscurece todo lo que hay en el mundo (la pantalla de vida, arma y minimapa no, que va aparte) con un tono
# azul de noche. Cada clase de sitio tiene su oscuridad (OSCURIDAD_SALA en el JS). Las luces (lampara.gd,
# fuego.gd y los fogonazos de aquí abajo) suman luz cálida encima.
#
# Las luces se reparten en dos "capas" (light_mask), como en la prueba de concepto:
#   - capa 2, el SUELO: la luz de suelo de cada lámpara lo alumbra y hace SOMBRAS (los muebles y los muros
#     llevan su LightOccluder2D)
#   - capa 1, todo lo demás (personajes, muebles, caras de muro): otra luz igual, SIN sombras. Si la luz con
#     sombras alumbrara también a los personajes, a Johnny se le quedaría la cabeza a oscuras al pegarse a un
#     muro (en el dibujo, su cabeza "está dentro" del muro de detrás)
# Así no hace falta tocar nada más: todo lo nuevo que se dibuje está en la capa 1 sin hacer nada.
class_name Luz
extends CanvasModulate

const OSCURIDAD_SALA := {"pasillo": 0.8, "apartamento": 0.84, "jefe": 0.5}
const PASILLO := 0.8                       # la oscuridad de referencia: a esta, las luces lucen a tope
const SOMBRA := Color(0.03, 0.03, 0.1)     # a qué color tiende lo oscuro (azul noche, casi negro)
# La linterna de Johnny: un cono que sale de sus pies hacia donde mira y hace sombras con los muebles
const LINTERNA_ALCANCE := 330.0            # hasta dónde llega, en unidades
const LINTERNA_ANCHO := 0.62               # medio ángulo del cono, en radianes (unos 35°)
const LINTERNA_GIRO := 10.0                # lo rápido que se vuelve hacia donde mira
const LINTERNA_COLOR := Color(1.0, 0.95, 0.82)
const FOGONAZO := Color(1.0, 0.82, 0.51)
const TEXTURA := preload("res://escenas/luces/luz_suave.tres")
const CAPA_SUELO := 2
const CAPA_COSAS := 1
# Lo que está en otra habitación de un apartamento (muros, muebles, zombis) pasa de la capa 1 a esta (mapa.gd):
# las lámparas y el fuego la alumbran, pero la linterna de Johnny no, para que no atraviese las paredes
const CAPA_LEJOS := 4
const MAX_DESTELLOS := 12                  # fogonazos a la vez, como mucho (la escopeta saca muchos)
const CAMBIO := 1.5                        # lo rápido que entra o se va la oscuridad (por segundo)

static var nivel := 0.0     # lo oscuro que está ahora (0 nada, 1 negro)
static var apagada := false # F10: sin penumbra, para comparar
static var destellos := 0

var objetivo := 0.0
var luz_johnny: PointLight2D
var johnny: Node2D
var linterna: Node2D        # gira con Johnny; dentro, el cono del suelo (con sombras) y el de lo demás
var linterna_suelo: PointLight2D
var linterna_cosas: PointLight2D
static var textura_cono: ImageTexture


# Cuánto lucen las luces: a tope con la oscuridad del pasillo y, sin oscuridad, solo un toque cálido
static func fuerza() -> float:
	return maxf(nivel / PASILLO, 0.25)


func _ready() -> void:
	name = "Luz"
	color = Color.WHITE


# El sitio nuevo: su oscuridad entra de golpe (la pantalla está en negro) o poco a poco
func poner_sitio(tipo: String, de_golpe := true) -> void:
	objetivo = OSCURIDAD_SALA.get(tipo, 0.0)
	if de_golpe:
		nivel = 0.0 if apagada else objetivo
		pintar()


func alternar() -> void:
	apagada = not apagada


# Johnny siempre se distingue un poco, aunque esté lejos de las luces (un brillito a su alrededor), y lleva
# la linterna. Como las lámparas, son dos conos iguales: el del suelo hace sombras y el de lo demás no
func seguir_a(quien: Node2D) -> void:
	johnny = quien
	luz_johnny = PointLight2D.new()
	luz_johnny.name = "Luz"
	luz_johnny.texture = TEXTURA
	luz_johnny.texture_scale = 80.0 / 128.0
	luz_johnny.range_item_cull_mask = CAPA_COSAS   # sin el suelo: sin sombras, se colaría por las paredes
	johnny.add_child(luz_johnny)
	linterna = Node2D.new()
	linterna.name = "Linterna"
	linterna.rotation = angulo_de(johnny.direccion)
	johnny.add_child(linterna)
	linterna_suelo = cono(CAPA_SUELO)
	linterna_suelo.shadow_enabled = true
	linterna_suelo.shadow_color = Color.BLACK
	linterna_suelo.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	linterna_suelo.shadow_filter_smooth = 3.0
	linterna_suelo.shadow_item_cull_mask = 1
	linterna_cosas = cono(CAPA_COSAS)
	pintar()


func cono(capa: int) -> PointLight2D:
	var luz := PointLight2D.new()
	luz.texture = hacer_cono()
	luz.texture_scale = LINTERNA_ALCANCE / 128.0
	luz.color = LINTERNA_COLOR
	luz.range_item_cull_mask = capa
	linterna.add_child(luz)
	return luz


# El dibujo del cono (se hace una vez): mirando hacia la derecha desde el centro, se apaga hacia la punta y
# hacia los lados. Sale de los pies (lo que hay debajo de la mano, en el suelo: si saliera de más arriba,
# pegado a un muro quedaría dentro de él y se romperían las sombras), pero ahí apenas alumbra: el haz se
# ve empezar un poco por delante de Johnny, no en sus pies
static func hacer_cono() -> ImageTexture:
	if textura_cono:
		return textura_cono
	var lado := 256
	var img := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(lado, lado) / 2.0
	for y in lado:
		for x in lado:
			var v := Vector2(x + 0.5, y + 0.5) - centro
			var d := v.length() / (lado / 2.0)
			var hacia_punta := pow(clampf(1.0 - d, 0.0, 1.0), 0.8)
			var hacia_lado := 1.0 - smoothstep(LINTERNA_ANCHO * 0.55, LINTERNA_ANCHO, absf(v.angle()))
			var k := hacia_punta * hacia_lado * smoothstep(0.02, 0.22, d)
			img.set_pixel(x, y, Color(k, k, k, 1.0))
	textura_cono = ImageTexture.create_from_image(img)
	return textura_cono


# El ángulo de cada una de las 8 direcciones de Johnny ("e" es 0 y van girando de 45 en 45)
func angulo_de(dir: String) -> float:
	return maxi(["e", "se", "s", "so", "o", "no", "n", "ne"].find(dir), 0) * PI / 4.0


func _process(delta: float) -> void:
	var quiero := 0.0 if apagada else objetivo
	if nivel != quiero:
		nivel = move_toward(nivel, quiero, delta * CAMBIO)
		pintar()
	if linterna and is_instance_valid(johnny):
		var hacia := angulo_de(johnny.direccion)
		linterna.rotation = lerp_angle(linterna.rotation, hacia, minf(delta * LINTERNA_GIRO, 1.0))


func pintar() -> void:
	color = Color.WHITE.lerp(SOMBRA, nivel)
	if luz_johnny:
		luz_johnny.energy = 0.45 * nivel
		luz_johnny.enabled = nivel > 0.01
	if linterna:
		linterna_suelo.energy = 1.1 * nivel
		linterna_cosas.energy = 0.9 * nivel
		linterna.visible = nivel > 0.01


# Un destello corto (fogonazo de un disparo, explosión): sale de golpe y se apaga deprisa. Sin sombras, que
# dura un instante y las sombras son lo que más cuesta. `radio` en unidades, `vida` en segundos.
static func destello(desde: Node, pos: Vector2, radio: float, vida: float, fuerza_destello := 1.0) -> void:
	if destellos >= MAX_DESTELLOS or not desde.is_inside_tree():
		return
	var luz := PointLight2D.new()
	luz.texture = TEXTURA
	luz.texture_scale = radio / 128.0
	luz.color = FOGONAZO
	luz.range_item_cull_mask = CAPA_SUELO | CAPA_COSAS | CAPA_LEJOS
	var e := 1.1 * fuerza_destello * fuerza()
	luz.energy = e
	destellos += 1
	luz.tree_exited.connect(func(): destellos -= 1)
	desde.get_tree().current_scene.add_child(luz)
	luz.global_position = pos
	var t := luz.create_tween()
	t.tween_method(func(k: float): luz.energy = e * (1.0 - k) * (1.0 - k), 0.0, 1.0, vida)
	t.tween_callback(luz.queue_free)
