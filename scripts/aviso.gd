# Los avisos de los ataques de los jefes, en el suelo y de pixel art (cuadraditos de 2, los píxeles de los dibujos,
# en la cuadrícula del suelo): se van llenando hacia donde va el golpe y, cuando están llenos, pega. Al final el borde
# se aclara poco a poco y, justo antes, un destello suave (el «¡ahora!»), sin parpadeos. De momento, la franja de las
# cargas y embestidas (minijefe.franja).
# Lo pinta un shader (aviso.gdshader): así no cuesta nada aunque tenga miles de cuadraditos. Va en un nodo hijo del
# jefe, por detrás de él, que se crea solo la primera vez y se esconde cuando deja de pedirse.
class_name Aviso
extends Node2D

const SHADER := preload("res://escenas/personajes/aviso.gdshader")

var desde := Vector2.ZERO
var angulo := 0.0
var largo := 100.0
var medio := 32.0
var pedido := 0   # el último fotograma en que se pidió (si deja de pedirse, se esconde)


# La franja de una carga: desde "desde" (en el jefe), hacia "angulo", de "largo" y "medio" de ancho a cada lado. Se
# llena en "k" (0 a 1); "tiempo", para que corran las flechas. Se llama desde el _draw del jefe
static func franja(jefe: Node2D, desde_: Vector2, angulo_: float, largo_: float, medio_: float, k: float,
		tiempo: float) -> void:
	var aviso: Aviso = jefe.get_node_or_null("Aviso")
	if aviso == null:
		aviso = Aviso.new()
		aviso.name = "Aviso"
		aviso.show_behind_parent = true   # en el suelo, por debajo del jefe
		jefe.add_child.call_deferred(aviso)
		jefe.move_child.call_deferred(aviso, 0)
	aviso.desde = desde_
	aviso.angulo = angulo_
	aviso.largo = largo_
	aviso.medio = medio_
	aviso.pedido = Engine.get_process_frames()
	aviso.visible = true
	var m: ShaderMaterial = aviso.material
	m.set_shader_parameter("k", k)
	m.set_shader_parameter("tiempo", tiempo)
	aviso.queue_redraw()


func _init() -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER


func _process(_delta: float) -> void:
	if Engine.get_process_frames() - pedido > 2:
		visible = false


func _draw() -> void:
	var m: ShaderMaterial = material
	m.set_shader_parameter("origen", to_global(desde))
	m.set_shader_parameter("hacia", Vector2.from_angle(angulo))
	m.set_shader_parameter("largo", largo)
	m.set_shader_parameter("medio", medio)
	# un rectángulo que tapa la franja: el shader decide qué cuadraditos se ven
	draw_set_transform(desde, angulo)
	draw_rect(Rect2(-6.0, -medio - 6.0, largo + 12.0, medio * 2.0 + 12.0), Color.WHITE)
