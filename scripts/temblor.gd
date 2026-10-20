# El temblor de la pantalla y el parón de los golpes, como en el juego JS (shake y hitStop en src/game.js):
#   - Temblor.temblar(fuerza): la cámara se mueve al azar unas unidades (fuerza) y se calma enseguida
#   - Temblor.parar(segundos): el juego casi se congela un instante, para que el golpe "pese"
# Es un autoload: vale desde cualquier sitio y mueve la cámara que esté en uso (la de Johnny).
# Los números son los del JS: golpe 3 + zombis tocados, matar 3, que te peguen 9, escopeta 4, explosión 14...
extends Node

const CALMA := 10.0      # lo rápido que se calma (como shakeAmt *= exp(-dt * 10) del JS)
const LENTO := 0.03      # lo lento que va el juego durante el parón (casi parado)

var cantidad := 0.0      # lo fuerte que tiembla ahora, en unidades del mundo
var hasta := 0           # hasta cuándo dura el parón (en milisegundos desde que arrancó el juego)
var camara: Camera2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue aunque el juego esté en pausa o en el parón


func temblar(fuerza: float) -> void:
	cantidad = maxf(cantidad, fuerza)


func parar(segundos: float) -> void:
	hasta = maxi(hasta, Time.get_ticks_msec() + roundi(segundos * 1000.0))
	Engine.time_scale = LENTO


func _process(_delta: float) -> void:
	# el tiempo de verdad (el delta va a cámara lenta durante el parón)
	var real := 1.0 / maxf(Engine.get_frames_per_second(), 1.0)
	if hasta > 0 and Time.get_ticks_msec() >= hasta:
		hasta = 0
		Engine.time_scale = 1.0
	var c := get_viewport().get_camera_2d()
	if c != camara:
		if is_instance_valid(camara):
			camara.offset = Vector2.ZERO
		camara = c
	if camara == null:
		return
	if cantidad < 0.3 or get_tree().paused:
		camara.offset = Vector2.ZERO
		return
	camara.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * cantidad
	camara.offset = camara.offset.round()   # a unidades enteras, para que el pixel art no se emborrone
	cantidad *= exp(-real * CALMA)
