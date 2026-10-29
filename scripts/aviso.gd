# Los avisos de los ataques de los jefes, en el suelo y de pixel art (cuadraditos de 2, los píxeles de los dibujos,
# en la cuadrícula del suelo). Varias formas, con el mismo estilo: lo que se enciende o se llena poco a poco marca
# cuánto falta y, con lo último, pega; justo antes, un destello suave.
#   - franja(): el camino de una carga o embestida. Flechas grandes que se encienden una tras otra hacia donde va,
#     raíles de puntos que marcan el ancho y, al final, una estrella si se va a estrellar contra la pared o una X si no.
#     Se corta donde se estrellaría el cuerpo del jefe (contra una pared o un mueble). También la de los latigazos de
#     tentáculos y lenguas (tentaculo.gd), cortada donde se paran.
#   - abanico(): el trozo que barre un golpe cuerpo a cuerpo (porrazo, fregonazo, hachazo...), o un círculo entero
#     (medio ángulo PI). Se va llenando del jefe hacia fuera, como una barra de carga, sin bordes. Puede llegar hasta
#     las paredes (rayos()), ser de otro color (tinte) y llevar ondas que van hacia el jefe (ondas).
#   - barra(): una franja recta que se llena hacia fuera (alfileres, por donde irán los disparos: contratos, cuchillos,
#     bolas de fuego). Se corta donde el disparo se pararía contra una pared o un mueble (alcance()) y ahí acaba en la
#     estrella de las cargas.
#   - flechas_giro(): los dos anillos de flechas del giro del bombero.
# Lo pinta un shader (aviso.gdshader): así no cuesta nada aunque tenga miles de cuadraditos. Cada aviso va en un nodo
# hijo del jefe, por detrás de él, que se crea solo la primera vez y se esconde cuando deja de pedirse. Un jefe puede
# tener varios a la vez ("cual": 0, 1, 2...), como las lenguas del glotón (tres, o seis enfadado).
class_name Aviso
extends Node2D

const SHADER := preload("res://escenas/personajes/aviso.gdshader")
const ROJO := Color(1, 0.24, 0.35)
const MAX_RAYOS := 21

var forma := 0          # 0: franja; 1: abanico; 2: barra; 3: flechas del giro
var desde := Vector2.ZERO
var angulo := 0.0
var largo := 100.0      # lo largo de la franja o de la barra, o hasta dónde llega el abanico
var inicio := 0.0       # la barra: dónde empieza
var medio := 32.0       # la franja y la barra: el ancho a cada lado; el abanico: el medio ángulo que barre
var aplasta := 1.0      # el abanico: lo aplastado que se ve en el suelo (de arriba abajo)
var choca := false
var sombra := 0.0       # el abanico de un salto: lo que ocupa la sombra de quien cae (0 a 1)
var tinte := ROJO       # el abanico y la barra: su color
var ondas := 0.0        # el abanico: lo deprisa que van las ondas hacia el jefe (0, sin ondas)
var hasta_rayos := PackedFloat32Array()   # el abanico: hasta dónde llega cada rayo, de un borde al otro (vacío: todos igual)
var sentido := 1.0      # las flechas del giro: hacia qué lado gira
var destella := true    # el destello del final (no, en lo que ya está pasando: aspirando, girando)
var pedido := 0         # el último fotograma en que se pidió (si deja de pedirse, se esconde)
static var apagados := false   # el panel de la sala de pruebas los apaga, para ver a los jefes sin ellos


# El camino de una carga: desde "desde" (en el jefe), hacia "angulo", de "largo" y "medio" de ancho a cada lado. "k"
# (0 a 1): lo que lleva de aviso; "tiempo", para que palpiten las flechas. Se llama desde el _draw del jefe
static func franja(jefe: CharacterBody2D, desde_: Vector2, angulo_: float, largo_: float, medio_: float, k: float,
		tiempo: float) -> Aviso:
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
	return aviso


# El trozo que barre un golpe: desde "desde", hacia "angulo", "medio" ángulo a cada lado (PI: el círculo entero) y
# hasta "alcance". "aplasta": lo aplastado que se ve (1, redondo); "sombra_": en un salto, la sombra de quien cae en el
# medio (lo que ocupa, 0 a 1); "cual": si el jefe tiene varios a la vez, cuál
static func abanico(jefe: Node2D, desde_: Vector2, angulo_: float, medio_: float, alcance: float, k: float,
		tiempo: float, aplasta_ := 1.0, sombra_ := 0.0, cual := 0) -> Aviso:
	var aviso := pedir(jefe, 1, desde_, angulo_, k, tiempo, cual)
	aviso.largo = alcance
	aviso.medio = medio_
	aviso.aplasta = aplasta_
	aviso.sombra = sombra_
	return aviso


# Una barra recta: desde "desde", hacia "angulo", de "inicio_" a "largo_" y "medio_" de ancho a cada lado. Se corta
# donde se pararía el disparo que marca (alcance()) y ahí acaba en la estrella de las cargas. "cual": si el jefe tiene
# varias a la vez, cuál
static func barra(jefe: Node2D, desde_: Vector2, angulo_: float, inicio_: float, largo_: float, medio_: float, k: float,
		tiempo: float, cual := 0) -> Aviso:
	var aviso := pedir(jefe, 2, desde_, angulo_, k, tiempo, cual)
	aviso.inicio = inicio_
	aviso.largo = alcance(jefe, desde_, angulo_, largo_, medio_)
	aviso.choca = aviso.largo < largo_ and aviso.largo > inicio_   # (si ya empieza en la pared, no hay nada que marcar)
	aviso.medio = medio_
	return aviso


# Hasta dónde llega un disparo que sale de "desde_" (en el jefe) hacia "angulo_", de "largo_" como mucho: por dónde
# pasaría un círculo de "ancho" (el de su barra) antes de dar con una pared o un mueble, donde se paran los disparos
# (contratos, cuchillos, alfileres y bolas de fuego, con un rayo de la capa 1). Si choca, llega hasta tocar la pared
static func alcance(jefe: Node2D, desde_: Vector2, angulo_: float, largo_: float, ancho: float) -> float:
	var circulo := CircleShape2D.new()
	circulo.radius = ancho
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = circulo
	consulta.transform = Transform2D(0.0, jefe.to_global(desde_))
	consulta.motion = Vector2.from_angle(angulo_) * largo_
	consulta.collision_mask = 1   # paredes y muebles
	var hasta := jefe.get_world_2d().direct_space_state.cast_motion(consulta)
	return minf(largo_, largo_ * hasta[0] + ancho) if hasta[1] < 1.0 else largo_


# Las flechas del giro del bombero alrededor de "desde": corren hacia "sentido_" (1, como las agujas del reloj). "k",
# lo que se ven (0 a 1)
static func flechas_giro(jefe: Node2D, desde_: Vector2, sentido_: float, k: float, tiempo: float, cual := 0) -> Aviso:
	var aviso := pedir(jefe, 3, desde_, 0.0, k, tiempo, cual)
	aviso.sentido = sentido_
	aviso.largo = 216.0
	aviso.destella = false
	return aviso


# Que el abanico llegue hasta donde dice cada rayo ("puntas": de un borde al otro, todos a la misma distancia del
# anterior), en vez de todo igual: hasta las paredes
func rayos(puntas: Array) -> void:
	hasta_rayos.resize(MAX_RAYOS)
	hasta_rayos.fill(0.0)
	var mas := 0.0
	for i in mini(puntas.size(), MAX_RAYOS):
		hasta_rayos[i] = puntas[i]
		mas = maxf(mas, puntas[i])
	largo = mas
	hasta_rayos.resize(mini(puntas.size(), MAX_RAYOS))


# El aviso del jefe (si no lo tiene, se lo pone), ya pedido para este fotograma y con lo que no es de su forma como
# viene de serie
static func pedir(jefe: Node2D, forma_: int, desde_: Vector2, angulo_: float, k: float, tiempo: float,
		cual := 0) -> Aviso:
	var nombre := "Aviso" if cual == 0 else "Aviso%d" % cual
	var aviso: Aviso = jefe.get_node_or_null(nombre)
	if aviso == null:
		aviso = Aviso.new()
		aviso.name = nombre
		aviso.show_behind_parent = true   # en el suelo, por debajo del jefe
		jefe.add_child.call_deferred(aviso)
		jefe.move_child.call_deferred(aviso, 0)
	aviso.forma = forma_
	aviso.desde = desde_
	aviso.angulo = angulo_
	aviso.inicio = 0.0
	aviso.aplasta = 1.0
	aviso.choca = false
	aviso.sombra = 0.0
	aviso.tinte = ROJO
	aviso.ondas = 0.0
	aviso.hasta_rayos.clear()
	aviso.destella = true
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
	m.set_shader_parameter("inicio", inicio)
	m.set_shader_parameter("medio", medio)
	m.set_shader_parameter("aplasta", aplasta)
	m.set_shader_parameter("choca", choca)
	m.set_shader_parameter("sombra", sombra)
	m.set_shader_parameter("tinte", Vector3(tinte.r, tinte.g, tinte.b))
	m.set_shader_parameter("ondas", ondas)
	m.set_shader_parameter("sentido", sentido)
	m.set_shader_parameter("destella", destella)
	m.set_shader_parameter("n_rayos", hasta_rayos.size())
	if hasta_rayos.size() > 1:
		var todos := hasta_rayos.duplicate()
		todos.resize(MAX_RAYOS)
		m.set_shader_parameter("rayos", todos)
	# un rectángulo que tapa el aviso: el shader decide qué cuadraditos se ven
	if forma == 0 or forma == 2:
		draw_set_transform(desde, angulo)
		draw_rect(Rect2(-6.0, -medio - 6.0, largo + 12.0, medio * 2.0 + 12.0), Color.WHITE)
	else:
		draw_set_transform(desde)
		draw_rect(Rect2(-largo - 6.0, -largo - 6.0, largo * 2.0 + 12.0, largo * 2.0 + 12.0), Color.WHITE)
