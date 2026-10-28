# Una pesa (una mancuerna) que lanza el Gymbro (minijefe de los Apartamentos), dibujada con código como el cuchillo
# del cocinero. Sale de su mano y va por el aire en curva hasta donde apuntó; en el suelo, desde que la lanza, se ve
# su marca roja (se puede esquivar). Al caer, si Johnny está en la marca le quita lo suyo y le empuja. Luego se
# queda un rato tirada en el suelo y se desvanece.
# Se crea con Pesa.new() y se le ponen desde, hasta, vuelo y dano antes de meterla en la escena.
class_name Pesa
extends Node2D

const DIBUJO := preload("res://assets/sprites/mancuerna.png")   # 14 × 9 píxeles
const RADIO := 30.0       # el tamaño de la marca: si Johnny está dentro cuando cae, le da
const ALTURA := 150.0     # lo alto que sube en la curva
const TIRADA := 3.0       # lo que se queda en el suelo

var desde := Vector2.ZERO   # de dónde sale (su mano)
var hasta := Vector2.ZERO   # dónde cae (el centro de la marca)
var vuelo := 0.9            # lo que tarda en caer
var dano := 18
var dueno: Node2D = null    # quien la lanza, el Gymbro (para la skin del glotón: johnny.gd, devolver())
var t := 0.0
var tirada := -1.0          # lo que le queda en el suelo (-1 = aún vuela)
var alto := 0.0             # a qué altura del suelo va
var giro := 0.0


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse el Gymbro, se borran las que van por el aire
	z_index = 5
	global_position = desde


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	if tirada >= 0.0:
		tirada -= delta
		modulate.a = clampf(tirada / 0.6, 0.0, 1.0)
		if tirada <= 0.0:
			queue_free()
		return
	var k := minf(1.0, t / vuelo)
	global_position = desde.lerp(hasta, k)
	alto = sin(k * PI) * ALTURA + (1.0 - k) * 40.0   # sale de la mano (a media altura) y cae al suelo
	giro = t * 12.0
	if k >= 1.0:
		caer()


func caer() -> void:
	alto = 0.0
	giro = 0.0
	tirada = TIRADA
	z_index = 0   # ya en el suelo: se ordena con los demás por su "y"
	remove_from_group("balas_zombi")
	Sonido.tocar("pisoton")
	Temblor.temblar(4.0)
	for i in 8:
		Particulas.soltar(self, global_position, Vector2(randf_range(-90, 90), randf_range(-70, -20)), Color("#8a7a66"), 3, 0.4)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position, johnny.RADIO * 0.6) and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(dano, dueno)
		var hacia: Vector2 = johnny.global_position - global_position
		johnny.empujar((hacia.normalized() if hacia != Vector2.ZERO else Vector2.DOWN) * 500.0)


# La marca es una elipse (el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := RADIO + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


func _draw() -> void:
	if tirada < 0.0:
		# la marca en el suelo (donde va a caer), que se llena según se acerca; y la sombra de la pesa
		var k := minf(1.0, t / vuelo)
		var rojo := Color(1, 0.24, 0.35)
		draw_set_transform(hasta - global_position, 0.0, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, RADIO * k, Color(rojo, 0.15 + 0.2 * k))
		draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 24, Color(rojo, 0.5 + 0.4 * k), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, 8.0 + 6.0 * (1.0 - alto / ALTURA), Color(0, 0, 0, 0.3))
	dibujar(self, Vector2(0, -alto - 6.0), giro)


# La mancuerna: un dibujo de PixelLab (tools/mancuernas.py; hasta el 28 oct, a cuadraditos con código), centrado en
# "donde" y girado "angulo". Lo usan las que lanza el Gymbro y las del suelo de su gimnasio (peligros/tropiezos.gd)
static func dibujar(lienzo: CanvasItem, donde: Vector2, angulo: float) -> void:
	lienzo.draw_set_transform(donde, angulo)
	var tam := DIBUJO.get_size() * 2.0   # (2 unidades por píxel del dibujo)
	lienzo.draw_texture_rect(DIBUJO, Rect2(-tam / 2.0, tam), false)
