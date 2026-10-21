# Un contrato del gerente (el jefe final del centro comercial), dibujado con código como el cuchillo del cocinero.
# Es una hoja de papel que vuela en línea recta dando vueltas, a la altura del cuerpo, y corta: si le da a Johnny
# le quita lo suyo. Si se topa con una pared, un mueble o un aparato de la azotea, se para y cae al suelo, donde
# se queda un momento y se desvanece.
# Se crea con Contrato.new(); el gerente también usa dibujar() para el taco que lleva en la mano en el aviso.
class_name Contrato
extends Node2D

const ALTURA := 22.0      # a qué altura del suelo vuela (la del cuerpo, como las balas de los zombis)
const VIDA := 3.0         # lo que vuela como mucho
const EN_EL_SUELO := 1.2  # lo que se queda en el suelo antes de desvanecerse
const CAIDA := 0.35       # lo que tarda en caer al suelo

var velocidad := Vector2.ZERO
var dano := 10
var t := 0.0
var caido := -1.0         # el tiempo que lleva parado (-1 = aún vuela)
var giro := 0.0           # hacia dónde apunta la hoja
var alto := ALTURA        # a qué altura se dibuja


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse el gerente, se borran los que van por el aire
	z_index = 4
	giro = randf() * TAU


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	if caido >= 0.0:
		# cae dando un último giro y se queda en el suelo un momento
		caido += delta
		alto = ALTURA * maxf(0.0, 1.0 - caido / CAIDA)
		modulate.a = clampf((CAIDA + EN_EL_SUELO - caido) / 0.4, 0.0, 1.0)
		if caido >= CAIDA + EN_EL_SUELO:
			queue_free()
		return
	giro += delta * 16.0
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
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + 10.0:
		johnny.recibir_dano(dano)
		# un corte: unos trocitos de papel saltan
		for i in 4:
			Particulas.soltar(self, global_position + Vector2(0, -ALTURA), Vector2.from_angle(randf() * TAU) * 80.0,
				Color("#f1ede0"), 3, 0.3)
		queue_free()


# Deja de volar: cae al suelo y ya no corta
func parar() -> void:
	caido = 0.0
	z_index = 0   # ya en el suelo: se ordena con los demás por su "y"
	remove_from_group("balas_zombi")


func _draw() -> void:
	# su sombra en el suelo y la hoja, encima (aplastada según gira, como si diera vueltas de canto)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.25))
	dibujar(self, Vector2(0, -alto), giro, 1.0 if caido >= 0.0 else 0.55 + 0.45 * absf(cos(t * 9.0)))


# El contrato, a cuadraditos (2 unidades por píxel del dibujo): una hoja blanca con renglones grises, una firma
# roja y una hoja verde (el logo de Velaria) en la esquina. "ancho" la estrecha para que parezca que gira
static func dibujar(lienzo: CanvasItem, donde: Vector2, angulo: float, ancho := 1.0) -> void:
	lienzo.draw_set_transform(donde, angulo, Vector2(ancho, 1.0))
	var px := func(x: float, y: float, w: float, h: float, c: String) -> void:
		lienzo.draw_rect(Rect2(x * 2.0, y * 2.0, w * 2.0, h * 2.0), Color(c))
	px.call(-5, -6, 10, 12, "#1d1b2c")   # el contorno
	px.call(-4, -5, 8, 10, "#f1ede0")    # el papel
	px.call(-4, 4, 8, 1, "#cfc8b4")      # la sombra de abajo
	for y in [-3, -1, 1]:
		px.call(-3, y, 6, 1, "#9a9486")  # los renglones
	px.call(-3, 3, 3, 1, "#a3262f")      # la firma
	px.call(2, -4, 1, 1, "#4f9a4a")      # la hojita de Velaria
	lienzo.draw_set_transform(Vector2.ZERO)
