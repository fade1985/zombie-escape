# Los avisos de los ataques de los jefes, en el suelo y de pixel art (cuadraditos de 2, los píxeles de los dibujos,
# en la cuadrícula del suelo). Dos formas, con el mismo estilo: lo que se enciende poco a poco marca cuánto falta y,
# con lo último, pega; justo antes, un destello suave.
#   - franja(): el camino de una carga o embestida. Flechas grandes que se encienden una tras otra hacia donde va,
#     raíles de puntos que marcan el ancho y, al final, una estrella si se va a estrellar contra la pared o una X si no.
#     Se corta donde se estrellaría el cuerpo del jefe (contra una pared o un mueble).
#   - abanico(): el trozo que barre un golpe cuerpo a cuerpo (porrazo, fregonazo, hachazo...). Se va llenando del jefe
#     hacia fuera, como una barra de carga, sin bordes.
# Lo pinta un shader (aviso.gdshader): así no cuesta nada aunque tenga miles de cuadraditos. Va en un nodo hijo del
# jefe, por detrás de él, que se crea solo la primera vez y se esconde cuando deja de pedirse.
class_name Aviso
extends Node2D

const SHADER := preload("res://escenas/personajes/aviso.gdshader")

var forma := 0          # 0: franja; 1: abanico
var desde := Vector2.ZERO
var angulo := 0.0
var largo := 100.0      # lo largo de la franja o hasta dónde llega el abanico
var medio := 32.0       # la franja: el ancho a cada lado; el abanico: el medio ángulo que barre
var aplasta := 1.0      # el abanico: lo aplastado que se ve en el suelo (de arriba abajo)
var choca := false
var sombra := 0.0       # el abanico de un salto: lo que ocupa la sombra de quien cae (0 a 1)
var pedido := 0         # el último fotograma en que se pidió (si deja de pedirse, se esconde)
static var apagados := false   # el panel de la sala de pruebas los apaga, para ver a los jefes sin ellos


# El camino de una carga: desde "desde" (en el jefe), hacia "angulo", de "largo" y "medio" de ancho a cada lado. "k"
# (0 a 1): lo que lleva de aviso; "tiempo", para que palpiten las flechas. Se llama desde el _draw del jefe
static func franja(jefe: CharacterBody2D, desde_: Vector2, angulo_: float, largo_: float, medio_: float, k: float,
		tiempo: float) -> void:
	# hasta dónde llegaría su cuerpo antes de estrellarse
	var cuerpo := PhysicsShapeQueryParameters2D.new()
	cuerpo.shape = jefe.get_node("Choque").shape
	cuerpo.transform = jefe.get_node("Choque").global_transform
	cuerpo.motion = Vector2.from_angle(angulo_) * largo_
	cuerpo.collision_mask = jefe.collision_mask
	cuerpo.exclude = [jefe.get_rid()]
	var hasta := jefe.get_world_2d().direct_space_state.cast_motion(cuerpo)
	var aviso := pedir(jefe, 0, desde_, angulo_, k, tiempo)
	aviso.choca = hasta[1] < 1.0 and largo_ * hasta[0] + medio_ < largo_
	aviso.largo = largo_ * hasta[0] + medio_ if aviso.choca else largo_
	aviso.medio = medio_


# El trozo que barre un golpe: desde "desde", hacia "angulo", "medio" ángulo a cada lado (PI: el círculo entero) y
# hasta "alcance". "aplasta": lo aplastado que se ve (1, redondo); "sombra_": en un salto, la sombra de quien cae en el
# medio (lo que ocupa, 0 a 1)
static func abanico(jefe: Node2D, desde_: Vector2, angulo_: float, medio_: float, alcance: float, k: float,
		tiempo: float, aplasta_ := 1.0, sombra_ := 0.0) -> void:
	var aviso := pedir(jefe, 1, desde_, angulo_, k, tiempo)
	aviso.largo = alcance
	aviso.medio = medio_
	aviso.aplasta = aplasta_
	aviso.sombra = sombra_


# El aviso del jefe (si no lo tiene, se lo pone), ya pedido para este fotograma
static func pedir(jefe: Node2D, forma_: int, desde_: Vector2, angulo_: float, k: float, tiempo: float) -> Aviso:
	var aviso: Aviso = jefe.get_node_or_null("Aviso")
	if aviso == null:
		aviso = Aviso.new()
		aviso.name = "Aviso"
		aviso.show_behind_parent = true   # en el suelo, por debajo del jefe
		jefe.add_child.call_deferred(aviso)
		jefe.move_child.call_deferred(aviso, 0)
	aviso.forma = forma_
	aviso.desde = desde_
	aviso.angulo = angulo_
	aviso.pedido = Engine.get_process_frames()
	aviso.visible = not apagados
	var m: ShaderMaterial = aviso.material
	m.set_shader_parameter("k", k)
	m.set_shader_parameter("tiempo", tiempo)
	aviso.queue_redraw()
	return aviso


func _init() -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER


func _process(_delta: float) -> void:
	if Engine.get_process_frames() - pedido > 2:
		visible = false


func _draw() -> void:
	var m: ShaderMaterial = material
	m.set_shader_parameter("forma", forma)
	m.set_shader_parameter("origen", to_global(desde))
	m.set_shader_parameter("hacia", Vector2.from_angle(angulo))
	m.set_shader_parameter("largo", largo)
	m.set_shader_parameter("medio", medio)
	m.set_shader_parameter("aplasta", aplasta)
	m.set_shader_parameter("choca", choca)
	m.set_shader_parameter("sombra", sombra)
	# un rectángulo que tapa el aviso: el shader decide qué cuadraditos se ven
	if forma == 0:
		draw_set_transform(desde, angulo)
		draw_rect(Rect2(-6.0, -medio - 6.0, largo + 12.0, medio * 2.0 + 12.0), Color.WHITE)
	else:
		draw_set_transform(desde)
		draw_rect(Rect2(-largo - 6.0, -largo - 6.0, largo * 2.0 + 12.0, largo * 2.0 + 12.0), Color.WHITE)
