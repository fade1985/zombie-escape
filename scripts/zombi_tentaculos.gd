# El zombi de tentáculos: muy lento, pero ataca desde lejos. Cuando ve a Johnny a tiro, pinta una franja de
# aviso en el suelo hacia donde está AHORA y, al rato, lanza un latigazo por ella: si Johnny se ha movido,
# falla. Números de src/zombies.js (TENTACLE).
# Su dibujo (zombi-tentaculos-gpt) es una imagen quieta por dirección: para que no se vea rígido, se le mueve
# con código (se bambolea al andar, respira) y le salen por la espalda tentáculos que se menean sin parar,
# como los de drawBackTentacles en el JS. El latigazo también se pinta con código, como en el juego.
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
const CARNE := Color("#7a2f3f")      # el granate de los tentáculos de su dibujo
const CARNE_LUZ := Color("#a4495a")
const PIES := 28.0                   # dónde van los pies en la escena (el dibujo gira y bota desde ahí)

var espera := 0.0
var angulo := 0.0           # hacia dónde va el latigazo (se fija al empezar el aviso)
var t_ataque := 0.0
var andar_t := 0.0          # la fase del bamboleo al andar


func _ready() -> void:
	super()
	espera = randf_range(1.0, 2.2)


func _physics_process(delta: float) -> void:
	espera -= delta
	super(delta)
	if estado != "muerto":
		mover_dibujo(delta)
	queue_redraw()


# Que no parezca de cartón: se balancea de un pie a otro y bota al andar, y respira (se estira y encoge un
# poco). Todo gira desde los pies
func mover_dibujo(delta: float) -> void:
	var rapidez := minf(1.0, velocity.length() / 25.0)
	andar_t += delta * (1.5 + 3.0 * rapidez)
	var respira := sin(tiempo * 2.2)
	sprite.rotation = sin(andar_t) * 0.07 * rapidez + sin(tiempo * 1.3) * 0.015
	sprite.position.y = PIES - absf(sin(andar_t)) * 3.0 * rapidez
	sprite.scale = Vector2(1.0 + respira * 0.012, 1.0 - respira * 0.02)


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
			Sonido.tocar("latigazo")
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
	if estado != "muerto":
		tentaculos_espalda()
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


# Tentáculos que le salen de los hombros por detrás (se pintan antes que su dibujo, así quedan detrás) y se
# menean cada uno a su ritmo. Mientras avisa del latigazo se encrespan
func tentaculos_espalda() -> void:
	var tenso := 1.8 if estado == "aviso" else 1.0
	var hombros := Vector2(sprite.position.x, sprite.position.y - 72.0)
	for i in 4:
		var lado := -1.0 if i % 2 == 0 else 1.0
		var abre := 0.25 + 0.35 * float(i / 2)
		var base := -PI / 2.0 + lado * abre + sin(tiempo * 1.7 + i) * 0.15
		var desde := hombros + Vector2(lado * (6.0 + 4.0 * float(i / 2)), 6.0)
		var largo := (36.0 - 6.0 * float(i / 2)) * (1.0 + 0.12 * sin(tiempo * 2.0 + i * 1.3))
		var puntos := PackedVector2Array()
		for j in 7:
			var t := j / 6.0
			var meneo := (sin(tiempo * 5.0 * tenso + j + i * 2.0) * 5.0 + lado * 4.0) * t * tenso   # y se curvan hacia fuera
			puntos.append(desde + Vector2.from_angle(base) * largo * t + Vector2.from_angle(base + PI / 2.0) * meneo)
		draw_polyline(puntos, CONTORNO, 7.0, true)
		draw_polyline(puntos, CARNE, 4.0, true)
		draw_polyline(puntos.slice(0, 4), CARNE_LUZ, 2.0, true)
