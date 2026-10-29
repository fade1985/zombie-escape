# El temblor de la pantalla y el parón de los golpes, como en el juego JS (shake y hitStop en src/game.js):
#   - Temblor.temblar(fuerza): la cámara se mueve al azar unas unidades (fuerza) y se calma enseguida
#   - Temblor.parar(segundos): el juego casi se congela un instante, para que el golpe "pese". No se acumulan: si
#     llega otro mientras dura, cuenta solo el más largo (desde que empezó el primero), y tras uno corto hay un respiro
#     en el que no empieza otro corto (si no, el cuchillo rápido o una cadena de explosiones irían a saltos). Con la
#     pausa (menús, inventario, tarjetas...) se corta en el acto. Lo que no debe frenarse (la música al cambiar de
#     canción, el fundido a negro de las puertas) va con set_ignore_time_scale
#   - Temblor.desplazamiento: lo que la cámara se aparta de Johnny aparte del temblor (la presentación del jefe la
#     lleva hasta él, ui/presentacion.gd); se suma siempre, en unidades pares para que el pixel art no se emborrone
#   - El ajuste «Temblor de pantalla» de Opciones (Guardado, ajustes.temblor: 1, 0,5 o 0) multiplica la fuerza de
#     temblar y lo que dura cada parón; con 0 no hay ni temblor ni parón. Se nota al momento, también desde la pausa
# Es un autoload: vale desde cualquier sitio y mueve la cámara que esté en uso (la de Johnny).
# Los números son los del JS: golpe 3 + zombis tocados, matar 3, que te peguen 9, escopeta 4, explosión 14...
extends Node

const CALMA := 10.0      # lo rápido que se calma (como shakeAmt *= exp(-dt * 10) del JS)
const LENTO := 0.03      # lo lento que va el juego durante el parón (casi parado)
const CORTO := 0.15      # hasta cuántos segundos es un parón "corto" (los largos, como matar a un jefe, entran siempre)
const RESPIRO := 150     # milisegundos tras un parón en los que no empieza otro corto

var cantidad := 0.0      # lo fuerte que tiembla ahora, en unidades del mundo
var desplazamiento := Vector2.ZERO   # lo que la cámara se aparta aparte del temblor (ver arriba)
var hasta := 0           # hasta cuándo dura el parón (en milisegundos desde que arrancó el juego); 0: no hay
var empezo := 0          # cuándo empezó el parón que dura
var acabo := -RESPIRO    # cuándo acabó el último
var camara: Camera2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue aunque el juego esté en pausa o en el parón


func temblar(fuerza: float) -> void:
	cantidad = maxf(cantidad, fuerza * intensidad())


func parar(segundos: float) -> void:
	var ahora := Time.get_ticks_msec()
	var escala := intensidad()
	if get_tree().paused or escala <= 0.0:
		return
	if hasta == 0:
		if segundos <= CORTO and ahora - acabo < RESPIRO:   # (lo corto o largo que es, sin contar el ajuste)
			return
		empezo = ahora
	hasta = maxi(hasta, empezo + roundi(segundos * escala * 1000.0))
	Engine.time_scale = LENTO


# Lo que se deja temblar y frenar, el ajuste de Opciones: de 1 (normal) a 0 (nada)
func intensidad() -> float:
	return clampf(float(Guardado.ajuste("temblor")), 0.0, 1.0)


func terminar_paron() -> void:
	hasta = 0
	acabo = Time.get_ticks_msec()
	Engine.time_scale = 1.0


func _process(_delta: float) -> void:
	# el tiempo de verdad (el delta va a cámara lenta durante el parón)
	var real := 1.0 / maxf(Engine.get_frames_per_second(), 1.0)
	if hasta > 0 and (Time.get_ticks_msec() >= hasta or get_tree().paused):
		terminar_paron()
	var c := get_viewport().get_camera_2d()
	if c != camara:
		if is_instance_valid(camara):
			camara.offset = Vector2.ZERO
		camara = c
		desplazamiento = Vector2.ZERO   # (otra partida: si la presentación de un jefe se quedó a medias, que no lo herede)
	if camara == null:
		return
	var aparte := (desplazamiento / 2.0).round() * 2.0
	if cantidad < 0.3 or get_tree().paused:
		camara.offset = aparte
		return
	var sacudida := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * cantidad
	camara.offset = aparte + sacudida.round()   # a unidades enteras, para que el pixel art no se emborrone
	cantidad *= exp(-real * CALMA)
