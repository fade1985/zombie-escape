# Una bola de fuego de las que lanza el jefe de bomberos (minijefe de los Apartamentos), dibujada con código como
# las pesas del Gymbro. Vuela recta a la altura del pecho, con su lucecita y soltando chispas; se acaba al chocar
# con una pared o un mueble (con un chisporroteo) y, si le da a Johnny, le quita lo suyo y le deja ardiendo un
# momento (el estado "fuego" de estados.gd, con los números de "quema").
# Se crea con BolaFuego.new() y se le ponen desde, velocidad, dano y quema antes de meterla en la escena.
class_name BolaFuego
extends Node2D

const LUZ := preload("res://escenas/luces/fuego.tscn")
const RADIO := 10.0        # lo gorda que es (para dar a Johnny)
const ALTO := 44.0         # a qué altura del suelo va (se dibuja ahí; el choque, a ras de suelo)
const VIDA := 2.5

var desde := Vector2.ZERO
var velocidad := Vector2.ZERO
var dano := 14
var quema := {"fuego": {}}   # lo que arde Johnny al darle
var dueno: Node2D = null     # quien la lanza (para la skin del glotón: johnny.gd, devolver())
var vida := VIDA
var t := 0.0


func _ready() -> void:
	add_to_group("balas_zombi")   # así se borran al enfadarse el jefe, como las demás balas de los malos
	z_index = 5
	global_position = desde
	var luz := LUZ.instantiate()
	luz.radio = 80.0
	luz.fuerza = 0.7
	luz.position = Vector2(0, -ALTO)
	add_child(luz)


func _physics_process(delta: float) -> void:
	t += delta
	vida -= delta
	if vida <= 0.0:
		apagarse()
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	if not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
		apagarse()
		return
	global_position = despues
	# chispas que se quedan atrás
	if randf() < delta * 40.0:
		Particulas.soltar(self, global_position + Vector2(randf_range(-4, 4), -ALTO + randf_range(-4, 4)),
			-velocidad * 0.15 + Vector2(randf_range(-20, 20), randf_range(-50, -10)), Llamas.FUEGO[randi() % 4], 2, 0.35)
	queue_redraw()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + RADIO \
			and johnny.esquiva_t <= 0.0:
		if not johnny.ignifugo():   # (con la skin del bombero, se deshace en chispas sin hacerle nada)
			johnny.recibir_dano(dano, dueno)
			johnny.pisar(quema)
		apagarse()


# Se deshace en chispas
func apagarse() -> void:
	Sonido.tocar("chisporroteo")
	for i in 8:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(0, -ALTO), Vector2(cos(a) * 90.0, sin(a) * 60.0 - 30.0),
			Llamas.FUEGO[i % 4], randf_range(2, 3), 0.4)
	queue_free()


# Una bola con el corazón amarillo y el borde rojo, y la cola de fuego que deja (tres bultos cada vez más
# pequeños y más rojos), todo encajado en píxeles de 2 unidades
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	Formas.disco(self, Vector2.ZERO, 7.0, Color(0, 0, 0, 0.25))   # la sombra
	draw_set_transform(Vector2.ZERO)
	var d := -velocidad.normalized()
	var late := 1.0 + 0.12 * sin(t * 25.0)
	for j in 3:
		var i: int = 3 - j   # de atrás adelante, para que los de delante tapen a los de detrás
		var p := (Vector2(0, -ALTO) + d * (i * 9.0) + d.orthogonal() * sin(t * 18.0 + i) * 3.0).snapped(Vector2(2, 2))
		var r := (RADIO - i * 2.5) * late
		Formas.disco(self, p, r + 2.0, Llamas.FUEGO[4])
		Formas.disco(self, p, r, Llamas.FUEGO[3] if i > 1 else Llamas.FUEGO[2])
	var c := Vector2(0, -ALTO).snapped(Vector2(2, 2))
	Formas.disco(self, c, RADIO * late + 2.0, Llamas.FUEGO[4])
	Formas.disco(self, c, RADIO * late, Llamas.FUEGO[2])
	Formas.disco(self, c, RADIO * 0.65 * late, Llamas.FUEGO[1])
	Formas.disco(self, c + Vector2(-2, -2), RADIO * 0.3, Llamas.FUEGO[0])
