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

const OSCURIDAD_SALA := {"pasillo": 0.62, "apartamento": 0.55, "jefe": 0.36}
const PASILLO := 0.62                      # la oscuridad de referencia: a esta, las luces lucen a tope
const SOMBRA := Color(0.06, 0.05, 0.16)    # a qué color tiende lo oscuro (azul noche)
const FOGONAZO := Color(1.0, 0.82, 0.51)
const TEXTURA := preload("res://escenas/luces/luz_suave.tres")
const CAPA_SUELO := 2
const CAPA_COSAS := 1
const MAX_DESTELLOS := 12                  # fogonazos a la vez, como mucho (la escopeta saca muchos)
const CAMBIO := 1.5                        # lo rápido que entra o se va la oscuridad (por segundo)

static var nivel := 0.0     # lo oscuro que está ahora (0 nada, 1 negro)
static var apagada := false # F10: sin penumbra, para comparar
static var destellos := 0

var objetivo := 0.0
var luz_johnny: PointLight2D


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


# Johnny siempre se distingue un poco, aunque esté lejos de las luces
func seguir_a(johnny: Node2D) -> void:
	luz_johnny = PointLight2D.new()
	luz_johnny.name = "Luz"
	luz_johnny.texture = TEXTURA
	luz_johnny.texture_scale = 110.0 / 128.0
	luz_johnny.range_item_cull_mask = CAPA_SUELO | CAPA_COSAS
	johnny.add_child(luz_johnny)


func _process(delta: float) -> void:
	var quiero := 0.0 if apagada else objetivo
	if nivel != quiero:
		nivel = move_toward(nivel, quiero, delta * CAMBIO)
		pintar()


func pintar() -> void:
	color = Color.WHITE.lerp(SOMBRA, nivel)
	if luz_johnny:
		luz_johnny.energy = 0.4 * nivel
		luz_johnny.enabled = nivel > 0.01


# Un destello corto (fogonazo de un disparo, explosión): sale de golpe y se apaga deprisa. Sin sombras, que
# dura un instante y las sombras son lo que más cuesta. `radio` en unidades, `vida` en segundos.
static func destello(desde: Node, pos: Vector2, radio: float, vida: float, fuerza_destello := 1.0) -> void:
	if destellos >= MAX_DESTELLOS or not desde.is_inside_tree():
		return
	var luz := PointLight2D.new()
	luz.texture = TEXTURA
	luz.texture_scale = radio / 128.0
	luz.color = FOGONAZO
	luz.range_item_cull_mask = CAPA_SUELO | CAPA_COSAS
	var e := 1.1 * fuerza_destello * fuerza()
	luz.energy = e
	destellos += 1
	luz.tree_exited.connect(func(): destellos -= 1)
	desde.get_tree().current_scene.add_child(luz)
	luz.global_position = pos
	var t := luz.create_tween()
	t.tween_method(func(k: float): luz.energy = e * (1.0 - k) * (1.0 - k), 0.0, 1.0, vida)
	t.tween_callback(luz.queue_free)
