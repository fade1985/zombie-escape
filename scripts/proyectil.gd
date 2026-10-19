# Algo que se lanza en parábola (el moco del venenoso, la botella de lejía de la portera): vuela por encima
# de todo hacia donde estaba Johnny y, al caer, deja un charco. Si Johnny está justo donde cae, le hace daño.
# Como lob y updateHazards en src/game-ataques.js.
extends Node2D

const CHARCO := preload("res://escenas/armas/charco.tscn")
const MOCO := preload("res://assets/sprites/objeto-moco.png")

# Cada tipo: cuánto tarda en caer, lo alto que sube, el daño al caer y el charco que deja
const TIPOS := {
	"veneno": {"vuelo": 0.8, "altura": 90.0, "golpe": 8},
	"lejia": {"vuelo": 0.9, "altura": 130.0, "golpe": 10},
}

var tipo := "veneno"
var desde := Vector2.ZERO    # dónde sale (en el suelo, debajo de la boca o de la mano)
var alto_salida := 0.0       # a qué altura sobre el suelo sale
var hasta := Vector2.ZERO    # dónde caerá
var t := 0.0


func _ready() -> void:
	global_position = desde


func _physics_process(delta: float) -> void:
	var datos: Dictionary = TIPOS[tipo]
	t += delta
	var k: float = minf(t / datos.vuelo, 1.0)
	global_position = desde.lerp(hasta, k)
	queue_redraw()
	if k >= 1.0:
		caer(datos)


func caer(datos: Dictionary) -> void:
	var charco := CHARCO.instantiate()
	charco.tipo = tipo
	charco.position = hasta
	get_parent().add_child(charco)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and hasta.distance_to(johnny.global_position) < charco.radio() + johnny.RADIO * 0.5:
		johnny.recibir_dano(datos.golpe)
	queue_free()


func _draw() -> void:
	var datos: Dictionary = TIPOS[tipo]
	var k: float = minf(t / datos.vuelo, 1.0)
	# La sombra, en el suelo, y el proyectil, que sube y baja (la curva de una pelota: sin(k·π))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.25))
	var alto: float = alto_salida * (1.0 - k) + sin(k * PI) * datos.altura
	var donde := Vector2(0, -alto)
	if tipo == "veneno":
		draw_set_transform(donde, 0.0, Vector2(2, 2))
		draw_texture(MOCO, -Vector2(MOCO.get_size()) / 2.0)
	else:
		# La botella de lejía, dando vueltas (dibujada con código, como en el juego)
		draw_set_transform(donde, t * 10.0)
		var contorno := Color("#1d1b2c")
		draw_rect(Rect2(-8, -10, 16, 20), contorno)
		draw_rect(Rect2(-6, -8, 12, 16), Color("#f4f8ff"))
		draw_rect(Rect2(-4.5, -16, 9, 7), contorno)
		draw_rect(Rect2(-3, -15, 6, 5), Color("#4c9fd6"))
		draw_rect(Rect2(-6, -2, 12, 4), Color("#4c9fd6"))
