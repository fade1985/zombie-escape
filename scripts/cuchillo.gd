# Un cuchillo del cocinero (minijefe del centro comercial), dibujado con código como la botella de lejía de la
# portera. Llega de dos maneras:
#   - "vuela": lanzado en línea recta, dando vueltas en el aire a la altura del cuerpo (el abanico).
#   - "cae": primero sale su marca roja en el suelo y, al acabarse, cae de punta desde arriba (la lluvia).
# Si le da a Johnny le quita lo suyo. Si no, se queda clavado un rato (en el suelo o en la pared) y se desvanece.
# Se crea con Cuchillo.new(); el cocinero también usa dibujar() para los que lleva en la mano.
class_name Cuchillo
extends Node2D

const CLAVADO := 4.0      # lo que se queda clavado
const CAIDA := 0.22       # lo que tarda en caer desde arriba
const ALTO := 420.0       # desde qué altura cae
const RADIO_CAE := 26.0   # el tamaño de la marca: si Johnny la pisa cuando cae, le da
const ALTURA := 22.0      # a qué altura del suelo vuela (la del cuerpo, como las balas de los zombis)

var modo := "vuela"
var velocidad := Vector2.ZERO   # "vuela"
var dano := 12
var dueno: Node2D = null        # quien lo lanza, el cocinero (para la skin del glotón: johnny.gd, devolver())
var aviso := 0.8                # "cae": lo que dura la marca antes de caer
var espera := 0.0               # "cae": lo que tarda en salir la marca (para que no caigan todos a la vez)
var t := 0.0
var clavado := -1.0             # lo que le queda clavado (-1 = aún no se ha clavado)
var giro := 0.0                 # hacia dónde apunta la hoja
var alto := ALTURA              # a qué altura se dibuja


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse el cocinero, se borran los que van por el aire
	z_index = 4
	if modo == "cae":
		z_index = -1   # la marca, en el suelo, por debajo de todos
		giro = PI / 2.0 + randf_range(-0.3, 0.3)   # de punta, un poco torcido
		visible = false


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	if clavado >= 0.0:
		clavado -= delta
		modulate.a = clampf(clavado / 0.6, 0.0, 1.0)
		if clavado <= 0.0:
			queue_free()
		return
	if modo == "vuela":
		volar(delta)
	else:
		caer()


func volar(delta: float) -> void:
	giro = t * 18.0
	if t > 3.0:
		queue_free()
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		# se clava en la pared o en el mueble, con la punta por delante
		global_position = choque.position - velocidad.normalized() * 6.0
		giro = velocidad.angle()
		clavar()
		return
	global_position = despues
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + 10.0:
		johnny.recibir_dano(dano, dueno)
		queue_free()


func caer() -> void:
	visible = t >= espera
	if t < espera + aviso:
		return
	z_index = 5   # cayendo, por encima de todo
	var k := (t - espera - aviso) / CAIDA
	alto = ALTO * (1.0 - minf(k, 1.0)) + 12.0
	if k < 1.0:
		return
	# ¡clavado! Si Johnny está encima de la marca, le da
	alto = 12.0
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position, johnny.RADIO * 0.6):
		johnny.recibir_dano(dano, dueno)
	for i in 5:
		Particulas.soltar(self, global_position, Vector2(randf_range(-70, 70), randf_range(-60, -20)), Color("#8a7a66"), 3, 0.35)
	clavar()


func clavar() -> void:
	clavado = CLAVADO
	z_index = 0   # ya quieto: se ordena con los demás por su "y"
	remove_from_group("balas_zombi")
	Sonido.tocar("clavado")


# La marca es una elipse (el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := RADIO_CAE + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


func _draw() -> void:
	if modo == "cae" and clavado < 0.0:
		var k := clampf((t - espera) / aviso, 0.0, 1.0)
		# la marca: un anillo rojo que se va llenando; y, cayendo, la sombra del cuchillo
		var rojo := Color(1, 0.24, 0.35)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, RADIO_CAE * k, Color(rojo, 0.15 + 0.2 * k))
		draw_arc(Vector2.ZERO, RADIO_CAE, 0.0, TAU, 24, Color(rojo, 0.5 + 0.4 * k), 3.0)
		draw_line(Vector2(-10, 0), Vector2(10, 0), Color(rojo, 0.8), 3.0)
		draw_line(Vector2(0, -10), Vector2(0, 10), Color(rojo, 0.8), 3.0)
		if t < espera + aviso:
			return
		draw_circle(Vector2.ZERO, 6.0 + 6.0 * (1.0 - alto / ALTO), Color(0, 0, 0, 0.3))
	dibujar(self, Vector2(0, -alto), giro)


# El cuchillo, a cuadraditos (2 unidades por píxel del dibujo): mango de madera con remaches y hoja de acero,
# con la punta hacia "angulo"
static func dibujar(lienzo: CanvasItem, donde: Vector2, angulo: float) -> void:
	lienzo.draw_set_transform(donde, angulo)
	var px := func(x: float, y: float, w: float, h: float, c: String) -> void:
		lienzo.draw_rect(Rect2(x * 2.0, y * 2.0, w * 2.0, h * 2.0), Color(c))
	px.call(-7, -2, 6, 4, "#1d1b2c")   # el contorno del mango
	px.call(-6, -1, 4, 2, "#6b4226")
	px.call(-5, -1, 1, 1, "#d9b36c")   # remaches
	px.call(-3, -1, 1, 1, "#d9b36c")
	px.call(-1, -2, 7, 4, "#1d1b2c")   # el contorno de la hoja
	px.call(6, -1, 1, 2, "#1d1b2c")
	px.call(0, -1, 6, 2, "#aeb6c2")
	px.call(0, -1, 6, 1, "#eef2f7")    # el filo, que brilla
