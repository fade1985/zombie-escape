# Una bala (o un perdigón de la escopeta): vuela en línea recta y se acaba al chocar con una pared o un
# mueble, al dar a un zombi o al llegar a su alcance. Como en el juego (src/game-combate.js), la bala "de
# verdad" va a la altura de los pies, y el dibujo sale a la altura del cañón y baja enseguida a la del cuerpo.
extends Node2D

const ALTURA_CUERPO := 22.0   # a qué altura sobre los pies se dibuja la bala cuando ya va lanzada
const BAJADA := 14.0          # lo rápido que baja el dibujo desde el cañón
const EMPUJE := 170.0         # empuje base de un zombi normal (el del arma lo multiplica)

var velocidad := Vector2.ZERO
var dano := 0
var empuje := 1.0
var radio := 4.0
var vida := 1.0             # segundos que le quedan (alcance ÷ velocidad)
var altura := 50.0          # a qué altura sobre la bala de verdad se dibuja
var choque := -1.0          # al chocar, el tiempo que queda de la nubecilla (antes de chocar, -1)


func _physics_process(delta: float) -> void:
	if choque >= 0.0:
		# Ya ha chocado: solo queda la nubecilla, que se apaga y se va
		choque -= delta
		queue_redraw()
		if choque < 0.0:
			queue_free()
		return

	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	altura += (ALTURA_CUERPO - altura) * (1.0 - exp(-delta * BAJADA))

	var antes := global_position
	var despues := antes + velocidad * delta
	# ¿Hay una pared o un mueble entre donde estaba y donde va a estar? (capa de choque 1)
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var pared := get_world_2d().direct_space_state.intersect_ray(rayo)
	if pared:
		global_position = pared.position
		chocar()
		return
	global_position = despues

	# ¿Ha dado a algún zombi?
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if global_position.distance_to(zombi.global_position) < zombi.radio + radio + 3.0:
			zombi.recibir_golpe(dano, velocidad.normalized() * EMPUJE * empuje)
			chocar()
			return
	queue_redraw()


func chocar() -> void:
	choque = 0.12
	queue_redraw()


func _draw() -> void:
	var donde := Vector2(0, -altura)
	if choque >= 0.0:
		# Nubecilla blanca que crece y se desvanece
		var k := 1.0 - choque / 0.12
		draw_circle(donde, radio + 6.0 * k, Color(1, 1, 1, 0.8 * (1.0 - k)))
		return
	# Una estela corta hacia atrás y la bala encima, con su borde oscuro (como todo el pixel art del juego)
	draw_line(donde, donde - velocidad.normalized() * 14.0, Color(1, 0.96, 0.84, 0.45), radio)
	draw_circle(donde, radio + 1.5, Color(0.11, 0.1, 0.17))
	draw_circle(donde, radio, Color(1, 0.96, 0.84))
