# Una bala de los malos (de momento, el agua sucia que lanza la portera con la fregona): vuela en línea recta,
# se acaba al chocar con una pared o un mueble y le hace daño a Johnny si le da. Como enemyShoot en el juego
# (src/game-combate.js).
extends Node2D

var velocidad := Vector2.ZERO
var dano := 10
var radio := 9.0
var color := Color("#cbb994")
var vida := 6.0


func _ready() -> void:
	add_to_group("balas_zombi")   # así la portera puede borrarlas todas al enfadarse


func _physics_process(delta: float) -> void:
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	if not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
		queue_free()
		return
	global_position = despues
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + radio:
		johnny.recibir_dano(dano)
		queue_free()


# Una gota redonda con su borde oscuro, a la altura del cuerpo
func _draw() -> void:
	draw_circle(Vector2(0, -22), radio + 2.0, Color("#1d1b2c"))
	draw_circle(Vector2(0, -22), radio, color)
