# El zombi de tentáculos: muy lento, pero ataca desde lejos. Cuando ve a Johnny a tiro, pinta una franja de
# aviso en el suelo hacia donde está AHORA y, al rato, lanza un latigazo por ella: si Johnny se ha movido,
# falla. Números de src/zombies.js (TENTACLE).
# Aún no tiene pixel art de verdad: usa una prueba quieta (zombi-tentaculos-gpt) y el latigazo se pinta con
# código, como en el juego.
extends Zombi

const LARGO := 220.0        # hasta dónde llega el latigazo
const ANCHO := 16.0         # medio ancho de la franja
const AVISO := 0.7          # segundos de aviso antes del golpe
const LATIGAZO := 0.25      # lo que dura el golpe
const ESPERA := 2.5         # entre un latigazo y el siguiente
const DANO_LATIGAZO := 15
const PARARSE := 140.0      # a esta distancia ya no se acerca más: ataca desde ahí

const MORADO := Color("#a06cc0")
const CONTORNO := Color("#1d1b2c")

var espera := 0.0
var angulo := 0.0           # hacia dónde va el latigazo (se fija al empezar el aviso)
var t_ataque := 0.0


func _ready() -> void:
	super()
	espera = randf_range(1.0, 2.2)


func _physics_process(delta: float) -> void:
	espera -= delta
	super(delta)
	queue_redraw()


func andar(delta: float, johnny: Node2D) -> void:
	var ve := se_ve(johnny)
	var distancia := distancia_a(johnny)
	if ve and espera <= 0.0 and distancia < LARGO + johnny.RADIO:
		# Apunta a donde está Johnny ahora mismo
		estado = "aviso"
		t_ataque = 0.0
		angulo = (johnny.global_position - global_position).angle()
		mirar_hacia(Vector2.from_angle(angulo))
		poner_animacion("reposo")
		return
	if ve and distancia < PARARSE:
		pedir_velocidad(Vector2.ZERO)
		mirar_hacia(johnny.global_position - global_position)
		poner_animacion("reposo")
		return
	ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)


func estado_propio(delta: float, johnny: Node2D) -> void:
	pedir_velocidad(Vector2.ZERO)
	t_ataque += delta
	if estado == "aviso":
		sprite.position.x = randf_range(-1.0, 1.0)   # tiembla mientras se prepara
		if t_ataque >= AVISO:
			estado = "latigazo"
			t_ataque = 0.0
			sprite.position.x = 0.0
			golpear(johnny)
	elif estado == "latigazo" and t_ataque >= LATIGAZO:
		estado = "andar"
		espera = ESPERA


# ¿Está Johnny dentro de la franja? Se mira lo lejos que queda de la línea del latigazo
func golpear(johnny: Node2D) -> void:
	if johnny == null or not johnny.vivo:
		return
	var linea := Vector2.from_angle(angulo)
	var hacia: Vector2 = johnny.global_position - global_position
	var a_lo_largo := clampf(hacia.dot(linea), 0.0, LARGO)
	var separado := hacia.distance_to(linea * a_lo_largo)
	if separado <= ANCHO + johnny.RADIO:
		johnny.recibir_dano(DANO_LATIGAZO)


func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	sprite.position.x = 0.0
	super(cantidad, fuerza)


func _draw() -> void:
	if estado == "aviso":
		# La franja de aviso, cada vez más roja
		var k := t_ataque / AVISO
		draw_set_transform(Vector2.ZERO, angulo)
		draw_rect(Rect2(0, -ANCHO, LARGO, ANCHO * 2), Color(1, 0.24, 0.35, 0.1 + k * 0.3))
		draw_rect(Rect2(0, -ANCHO, LARGO, ANCHO * 2), Color(1, 0.24, 0.35, 0.9), false, 3.0)
	elif estado == "latigazo":
		# El tentáculo sale disparado y culebrea
		var largo := LARGO * minf(1.0, t_ataque / 0.08)
		draw_set_transform(Vector2(0, -4), angulo)
		var puntos := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			puntos.append(Vector2(largo * t, sin(t * 9.0 + t_ataque * 30.0) * 5.0 * (1.0 - t)))
		draw_polyline(puntos, CONTORNO, 18.0)
		draw_polyline(puntos, MORADO, 12.0)
		for i in range(2, 10, 2):
			draw_circle(puntos[i], 2.5, Color("#f2b5d4"))
