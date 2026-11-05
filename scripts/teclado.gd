# Un teclado del informático (minijefe de Torre Velaria), dibujado con código como el contrato del gerente. Vuela en
# línea recta dando vueltas, a la altura del cuerpo: si le da a Johnny le quita lo suyo y saltan teclas. Si se topa
# con una pared o un mueble, se para y cae al suelo, donde se queda un momento y se desvanece.
# Se crea con Teclado.new() (informatico.gd, lanzar_teclados).
class_name Teclado
extends Node2D

const ALTURA := 22.0      # a qué altura del suelo vuela (la del cuerpo, como las balas de los zombis)
const VIDA := 3.0         # lo que vuela como mucho
const EN_EL_SUELO := 1.2  # lo que se queda en el suelo antes de desvanecerse
const CAIDA := 0.35       # lo que tarda en caer al suelo

var velocidad := Vector2.ZERO
var dano := 10
var dueno: Node2D = null  # quien lo lanza, el informático (para la skin del glotón: johnny.gd, devolver())
var t := 0.0
var caido := -1.0         # el tiempo que lleva parado (-1 = aún vuela)
var giro := 0.0           # hacia dónde apunta
var alto := ALTURA        # a qué altura se dibuja


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse el informático, se borran los que van por el aire
	z_index = 4
	giro = randf() * TAU


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	if caido >= 0.0:
		caido += delta
		alto = ALTURA * maxf(0.0, 1.0 - caido / CAIDA)
		modulate.a = clampf((CAIDA + EN_EL_SUELO - caido) / 0.4, 0.0, 1.0)
		if caido >= CAIDA + EN_EL_SUELO:
			queue_free()
		return
	giro += delta * 12.0
	if t > VIDA:
		parar()
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		global_position = choque.position - velocidad.normalized() * 6.0
		parar()
		return
	global_position = despues
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + 12.0:
		johnny.recibir_dano(dano, dueno)
		# saltan unas teclas
		for i in 5:
			Particulas.soltar(self, global_position + Vector2(0, -ALTURA), Vector2.from_angle(randf() * TAU) * 90.0,
				Color("#d8d4c8") if i % 2 == 0 else Color("#3a3a46"), 3, 0.35)
		queue_free()


# Deja de volar: cae al suelo y ya no hace daño
func parar() -> void:
	caido = 0.0
	z_index = 0   # ya en el suelo: se ordena con los demás por su "y"
	remove_from_group("balas_zombi")


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	Formas.disco(self, Vector2.ZERO, 11.0, Color(0, 0, 0, 0.25))
	dibujar(self, Vector2(0, -alto), giro, 1.0 if caido >= 0.0 else 0.5 + 0.5 * absf(cos(t * 8.0)))


# El teclado, a cuadraditos (2 unidades por píxel del dibujo): una tabla gris oscura con tres filas de teclas claras y
# la barra espaciadora, y el cable colgando. "ancho" lo estrecha para que parezca que gira
static func dibujar(lienzo: CanvasItem, donde: Vector2, angulo: float, ancho := 1.0) -> void:
	lienzo.draw_set_transform(donde, angulo, Vector2(ancho, 1.0))
	var px := func(x: float, y: float, w: float, h: float, c: String) -> void:
		lienzo.draw_rect(Rect2(x * 2.0, y * 2.0, w * 2.0, h * 2.0), Color(c))
	px.call(-9, -4, 18, 8, "#14131c")    # el contorno
	px.call(-8, -3, 16, 6, "#3a3a46")    # la tabla
	for y in [-2, 0]:
		for x in range(-7, 7, 2):
			px.call(x, y, 1, 1, "#d8d4c8")   # las teclas
	px.call(-4, 2, 8, 1, "#d8d4c8")      # la barra espaciadora
	px.call(6, 2, 1, 1, "#7fe08a")       # la lucecita verde
	px.call(-1, -6, 1, 2, "#14131c")     # el cable
	lienzo.draw_set_transform(Vector2.ZERO)
