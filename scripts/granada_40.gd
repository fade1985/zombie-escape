# La granada de 40 mm del lanzagranadas (6 nov). Vuela recta, despacio para que se vea ir, dejando un hilo de humo,
# y revienta al tocar a un zombi, al dar en una pared o un mueble, o al llegar a su alcance: la misma explosión que la
# granada de mano (explosion.gd, sin mecha), que hace daño en área y también a Johnny si le pilla, con el mismo tope
# (Lanzables.DANO_JOHNNY). Como la bala (bala.gd), la de verdad va a la altura de los pies y el dibujo sale a la altura
# del cañón y baja enseguida a la del cuerpo.
class_name Granada40
extends Node2D

const EXPLOSION := preload("res://escenas/armas/explosion.tscn")
const ALTURA_CUERPO := 22.0   # a qué altura sobre los pies se dibuja cuando ya va lanzada
const BAJADA := 14.0          # lo rápido que baja el dibujo desde el cañón
const TOCA := 10.0            # lo que se le suma al radio del zombi para que la toque (es gorda: más que una bala)
const NEGRO := Color("#2a2a33")
const NEGRO_LUZ := Color("#4a4a58")
const LATON := Color("#e0b040")
const LATON_LUZ := Color("#ffe08a")
const LINEA := Color("#14121c")

var velocidad := Vector2.ZERO
var dano_zombis := 80
var radio := 110.0            # el de la explosión
var vida := 1.0               # segundos que le quedan (alcance ÷ velocidad): al acabarse, revienta
var altura := 50.0            # a qué altura sobre la de verdad se dibuja
var humo := 0.0               # cuánto falta para la siguiente bocanada de humo
var hecha := false            # ya ha reventado (que no lo haga dos veces)


func _physics_process(delta: float) -> void:
	if hecha:
		return
	vida -= delta
	altura += (ALTURA_CUERPO - altura) * (1.0 - exp(-delta * BAJADA))
	var antes := global_position
	var despues := antes + velocidad * delta
	# ¿Hay una pared o un mueble entre donde estaba y donde va a estar? (capa de choque 1) Revienta un poco antes, de
	# este lado, para que la pared no tape la onda
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var pared := get_world_2d().direct_space_state.intersect_ray(rayo)
	if pared:
		global_position = pared.position - velocidad.normalized() * 4.0
		reventar()
		return
	global_position = despues
	# ¿Ha tocado a algún zombi? (o la burbuja del jefe de bomberos o la cúpula del científico)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var escudo: bool = zombi.has_method("escudo_toca") and zombi.escudo_toca(global_position + Vector2(0, -altura))
		if escudo or global_position.distance_to(zombi.global_position) < zombi.radio + TOCA:
			reventar()
			return
	if vida <= 0.0:
		reventar()
		return
	# un hilo de humo gris detrás
	humo -= delta
	if humo <= 0.0:
		humo = 0.03
		var atras := -velocidad.normalized()
		Particulas.soltar(get_parent(), global_position + Vector2(0, -altura) + atras * 8.0,
			atras * 20.0 + Vector2(randf_range(-10, 10), -15), Color(0.75, 0.75, 0.78, 0.7), randf_range(5.0, 8.0), 0.35)
	queue_redraw()


# ¡Boom! La explosión de la granada de mano: a los zombis, todo su daño; a Johnny, como mucho DANO_JOHNNY
func reventar() -> void:
	hecha = true
	var boom := EXPLOSION.instantiate()
	boom.radio = radio
	boom.dano = mini(dano_zombis, Lanzables.DANO_JOHNNY)
	boom.dano_zombis = dano_zombis
	boom.paredes = true
	boom.position = position
	get_parent().add_child(boom)
	Mancha.quemado(get_parent(), position, radio * 0.5)
	queue_free()


# La granada: el casquillo negro y la punta redonda de latón, girada hacia donde vuela (2 unidades por píxel del
# dibujo, como los sprites). Y su sombra en el suelo
func _draw() -> void:
	draw_circle(Vector2(0, 2), 4.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -altura), velocidad.angle())
	draw_rect(Rect2(-8, -4, 14, 8), LINEA)                 # el contorno
	draw_circle(Vector2(6, 0), 4.0, LINEA)
	draw_rect(Rect2(-6, -2, 8, 4), NEGRO)                  # el casquillo
	draw_rect(Rect2(-6, -2, 8, 2), NEGRO_LUZ)
	draw_rect(Rect2(-8, -4, 2, 8), NEGRO)                  # el culo, con su reborde
	draw_rect(Rect2(2, -2, 4, 4), LATON)                   # la punta de latón
	draw_circle(Vector2(6, 0), 2.0, LATON)
	draw_rect(Rect2(4, -2, 2, 2), LATON_LUZ)
	draw_set_transform(Vector2.ZERO)
