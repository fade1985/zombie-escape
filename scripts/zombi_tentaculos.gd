# El zombi de tentáculos: muy lento, pero ataca desde lejos. Cuando ve a Johnny a tiro, apunta hacia donde está
# AHORA y, al rato, lanza un latigazo en esa línea: si Johnny se ha movido, falla. Números de src/zombies.js
# (TENTACLE).
# Su hoja (zombi-tentaculos-gpt, hecha con tools/zombi.py) tiene andar, latigazo, golpe y muerte de PixelLab. El
# latigazo va al ritmo del aviso: mientras avisa echa los tentáculos atrás y, al dar el golpe, los lanza hacia
# delante. El tentáculo largo que pega se pinta con código: durante el aviso le sale del hombro, se levanta por
# encima de la cabeza, se enrosca y tiembla, y su sombra crece en el suelo por donde va a caer (es lo que avisa a
# Johnny de por dónde no pasar); con el golpe se estira como un látigo, cae sobre la sombra y se recoge.
extends Zombi

const LARGO := 220.0        # hasta dónde llega el latigazo
const ANCHO := 16.0         # medio ancho de la línea del golpe (y de la sombra que la avisa)
const AVISO := 0.7          # segundos de aviso antes del golpe
const LATIGAZO := 0.25      # lo que dura el golpe
const ESPERA := 2.5         # entre un latigazo y el siguiente
const DANO_LATIGAZO := 15
const PARARSE := 140.0      # a esta distancia ya no se acerca más: ataca desde ahí
const IMPACTO := 3          # el fotograma del ataque en que lanza los tentáculos (antes, los echa atrás)

# El tentáculo pintado con código. Sus colores son los de los tentáculos de su espalda (sacados de su reposo y
# su andar), también el borde, casi negro
const CONTORNO := Color("#0c0906")
const OSCURO := Color("#2d191b")
const GRANATE := Color("#5b3230")
const CLARO := Color("#7d4042")
const BRILLO := Color("#a26161")
const VENTOSA := Color("#915153")
const VENTOSA_HUECO := Color("#3d2526")
const LUZ := Vector2(-0.4, -0.9)   # de dónde le da la luz (arriba a la izquierda): por ahí, el brillo
const PUNTOS := 20          # en cuántos trozos se pinta, de la base a la punta
const GRUESO := 7.5         # medio grueso en la base...
const FINO := 2.0           # ...y en la punta
const ENROSCADO := 110.0    # lo largo que es levantado durante el aviso
const SUELO := 16.0         # la sombra va 16 por debajo de la línea del golpe: a la altura de los pies de Johnny
# De dónde sale: su hombro en cada dirección, medido en su hoja (con los fotogramas 0, 2 y 3 del ataque, que
# se encoge al echar los tentáculos atrás y se agacha al lanzarlos). De espaldas sale de la espalda, por delante
# del cuerpo; si no, por detrás del hombro: los primeros trozos (DETRAS) van detrás del dibujo
const HOMBRO := {
	"s": [Vector2(10, -42), Vector2(12, -38), Vector2(12, -36)],
	"se": [Vector2(-6, -42), Vector2(2, -38), Vector2(6, -36)],
	"e": [Vector2(-6, -42), Vector2(-8, -42), Vector2(6, -42)],
	"ne": [Vector2(-4, -44), Vector2(-2, -44), Vector2(-2, -40)],
	"n": [Vector2(10, -42), Vector2(10, -36), Vector2(10, -34)],
	"no": [Vector2(2, -44), Vector2(0, -42), Vector2(-2, -38)],
	"o": [Vector2(4, -44), Vector2(4, -44), Vector2(-2, -42)],
	"so": [Vector2(8, -42), Vector2(8, -42), Vector2(10, -36)],
}
const DE_ESPALDAS := ["n", "ne", "no"]
const DETRAS := 3

var espera := 0.0
var angulo := 0.0           # hacia dónde va el latigazo (se fija al empezar el aviso)
var t_ataque := 0.0
var delante: Node2D         # pinta la parte del tentáculo que va por delante del cuerpo
var en_suelo: Node2D        # pinta su sombra en el suelo


func _ready() -> void:
	super()
	espera = randf_range(1.0, 2.2)
	# El tentáculo se pinta en tres capas: la sombra, en el suelo (por debajo de todos, como los charcos); la base,
	# en el propio zombi (que pinta siempre por detrás de su dibujo); y el resto en "delante", que va después del
	# dibujo y por eso queda encima
	en_suelo = Node2D.new()
	en_suelo.z_index = -1
	en_suelo.draw.connect(_pintar_sombra)
	add_child(en_suelo)
	delante = Node2D.new()
	delante.draw.connect(_pintar_delante)
	add_child(delante)


func _physics_process(delta: float) -> void:
	espera -= delta
	super(delta)
	queue_redraw()
	delante.queue_redraw()
	en_suelo.queue_redraw()


func andar(delta: float, johnny: Node2D) -> void:
	var ve := se_ve(johnny)
	var distancia := distancia_a(johnny)
	if ve and espera <= 0.0 and distancia < LARGO + johnny.RADIO:
		# Apunta a donde está Johnny ahora mismo
		estado = "aviso"
		t_ataque = 0.0
		angulo = (johnny.global_position - global_position).angle()
		mirar_hacia(Vector2.from_angle(angulo))
		# El ataque no corre solo: cada fotograma lo elige estado_propio, al ritmo del aviso
		poner_animacion("ataque", true)
		sprite.pause()
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
		# Mientras se pinta la franja, echa los tentáculos atrás (los fotogramas de antes del impacto) y tiembla
		sprite.frame = mini(int(t_ataque / AVISO * IMPACTO), IMPACTO - 1)
		sprite.position.x = randf_range(-1.0, 1.0)
		if t_ataque >= AVISO:
			estado = "latigazo"
			t_ataque = 0.0
			sprite.position.x = 0.0
			Sonido.tocar("latigazo")
			golpear(johnny)
	elif estado == "latigazo":
		# Los lanza en el primer instante y los recoge mientras dura el golpe
		var resto := sprite.sprite_frames.get_frame_count(sprite.animation) - IMPACTO
		sprite.frame = IMPACTO + mini(int(t_ataque / LATIGAZO * resto), resto - 1)
		if t_ataque >= LATIGAZO:
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
		johnny.recibir_dano(DANO_LATIGAZO, self)


func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	sprite.position.x = 0.0
	super(cantidad, fuerza)


# La base del tentáculo, por detrás del dibujo: así parece que sale de detrás del hombro (de espaldas no, que le
# sale de la espalda, de cara a nosotros)
func _draw() -> void:
	var puntos := _tentaculo()
	if not puntos.is_empty() and direccion not in DE_ESPALDAS:
		_pintar_tentaculo(self, puntos, 0, DETRAS)


# El resto, por delante del dibujo
func _pintar_delante() -> void:
	var puntos := _tentaculo()
	if not puntos.is_empty():
		_pintar_tentaculo(delante, puntos, 0 if direccion in DE_ESPALDAS else DETRAS, PUNTOS)


# Los puntos del tentáculo en este momento, de la base a la punta (ninguno si no está atacando)
func _tentaculo() -> PackedVector2Array:
	if estado != "aviso" and estado != "latigazo":
		return PackedVector2Array()
	var hombro := _hombro()
	var hacia := Vector2.from_angle(angulo)
	if estado == "aviso":
		return _enroscado(hombro, hacia, t_ataque / AVISO)
	# El latigazo: sale disparado desde lo alto, cae sobre la sombra y se recoge hacia el hombro
	var sale := smoothstep(0.0, 0.05, t_ataque)
	var recoge := smoothstep(0.13, LATIGAZO, t_ataque)
	var antes := _enroscado(hombro, hacia, 1.0, 0.0)
	var estirado := _estirado(hombro, hacia, smoothstep(0.03, 0.1, t_ataque))
	var puntos := PackedVector2Array()
	for i in PUNTOS + 1:
		puntos.append(hombro + (antes[i].lerp(estirado[i], sale) - hombro) * (1.0 - recoge))
	return puntos


# El punto del hombro de donde sale, según hacia dónde mira y el fotograma del ataque (se mueve con el cuerpo, y
# tiembla con él durante el aviso)
func _hombro() -> Vector2:
	var tres: Array = HOMBRO[direccion]
	var p: Vector2
	match sprite.frame:
		0: p = tres[0]
		1: p = (tres[0] + tres[1]) / 2.0
		2: p = tres[1]
		_: p = tres[2]
	return p + Vector2(sprite.position.x, 0)


# Levantado por encima de la cabeza, como un gancho: sube recto del hombro, echado un poco hacia atrás, arriba se
# curva hasta apuntar a Johnny y la punta se enrosca. "k" va de 0 a 1 durante el aviso: primero sale y sube, y luego se enrosca cada vez más
# y tiembla (con "tiembla" a 0, quieto)
func _enroscado(hombro: Vector2, hacia: Vector2, k: float, tiembla := 1.0) -> PackedVector2Array:
	var tramo := ENROSCADO / PUNTOS * ease(minf(1.0, k / 0.35), 0.5)
	var sube := -PI / 2 - 0.3 * hacia.x
	# Lo que gira para apuntarle, por el lado más corto. Si Johnny queda justo al revés (abajo), gira por el lado
	# del hombro, por fuera del cuerpo; y si queda justo encima, también se enrosca hacia ese lado
	var lado := 1.0 if HOMBRO[direccion][0].x >= 0.0 else -1.0
	var giro := wrapf(hacia.angle() - sube, -PI, PI)
	if absf(giro) > PI * 0.9:
		giro = fposmod(hacia.angle() - sube, TAU) if lado > 0.0 else -fposmod(sube - hacia.angle(), TAU)
	var enrosca := (signf(giro) if absf(giro) > 0.2 else lado) * (0.6 + 1.8 * k)
	var puntos := PackedVector2Array([hombro])
	for i in PUNTOS:
		var s := (i + 0.5) / PUNTOS
		var hacia_donde := sube + giro * smoothstep(0.3, 0.85, s) + enrosca * pow(s, 2.5)
		hacia_donde += sin(t_ataque * 47.0 + i * 1.3) * 0.08 * k * tiembla
		puntos.append(puntos[i] + Vector2.from_angle(hacia_donde) * tramo)
	return puntos


# Estirado como un látigo hasta el final de la sombra: sale del hombro hacia arriba (por encima del hombro) y
# baja hasta la punta, primero en arco por lo alto y luego ("cae" de 0 a 1) tendido sobre la sombra. Una onda lo
# recorre de la base a la punta
func _estirado(hombro: Vector2, hacia: Vector2, cae: float) -> PackedVector2Array:
	var punta := Vector2(0, SUELO - 6.0) + hacia * LARGO
	var arriba := hombro + Vector2(0, -36)
	var codo := (hombro + Vector2(0, -70) + hacia * 90.0).lerp(Vector2(0, SUELO - 10.0) + hacia * 70.0, cae)
	var lado := (punta - hombro).orthogonal().normalized()
	var puntos := PackedVector2Array()
	for i in PUNTOS + 1:
		var s := float(i) / PUNTOS
		var u := 1.0 - s
		var p := hombro * u * u * u + arriba * 3.0 * u * u * s + codo * 3.0 * u * s * s + punta * s * s * s
		puntos.append(p + lado * sin(s * 2.0 * TAU - t_ataque * 90.0) * 8.0 * sin(s * PI))
	return puntos


# Pinta los trozos del tentáculo de "desde" a "hasta" (por sus puntos): el contorno, el granate oscuro, el granate
# hacia la luz, un brillo y las ventosas por el lado de la sombra. Grueso en la base y fino en la punta; al salir
# y al recogerse, más fino
func _pintar_tentaculo(lienzo: CanvasItem, puntos: PackedVector2Array, desde: int, hasta: int) -> void:
	var grueso := 1.0
	if estado == "aviso":
		grueso = minf(1.0, 0.3 + 2.0 * t_ataque / AVISO)
	else:
		grueso = 1.0 - 0.7 * smoothstep(0.13, LATIGAZO, t_ataque)
	var r := PackedFloat32Array()
	var luz := PackedVector2Array()   # de lado al tentáculo, hacia donde le da la luz
	for i in PUNTOS + 1:
		r.append((FINO + (GRUESO - FINO) * pow(1.0 - float(i) / PUNTOS, 0.8)) * grueso)
		var n := (puntos[mini(i + 1, PUNTOS)] - puntos[maxi(i - 1, 0)]).orthogonal().normalized()
		luz.append(n if n.dot(LUZ) >= 0.0 else -n)
	# La parte de delante empieza cortada en recto, sin redondel: así no se nota la juntura con la de detrás
	var primero := desde + 1 if desde > 0 else 0
	for capa in [[CONTORNO, 0.0, 1.0, 1.0], [OSCURO, 0.0, 1.0, 0.0], [GRANATE, 0.3, 0.7, 0.0]]:
		for i in range(primero, hasta + 1):
			lienzo.draw_circle(puntos[i] + luz[i] * r[i] * capa[1], r[i] * capa[2] + capa[3], capa[0])
		for i in range(desde, hasta):
			lienzo.draw_line(puntos[i] + luz[i] * r[i] * capa[1], puntos[i + 1] + luz[i + 1] * r[i + 1] * capa[1],
				capa[0], (r[i] + r[i + 1]) * capa[2] + capa[3] * 2.0)
	for i in range(desde, hasta):
		lienzo.draw_line(puntos[i] + luz[i] * r[i] * 0.55, puntos[i + 1] + luz[i + 1] * r[i + 1] * 0.55, CLARO,
			maxf(1.0, r[i] * 0.35))
		if r[i] > 3.5:
			lienzo.draw_line(puntos[i] + luz[i] * r[i] * 0.6, puntos[i + 1] + luz[i + 1] * r[i + 1] * 0.6, BRILLO, 1.0)
	# Las ventosas, una sí y otra no
	for i in range(maxi(desde, 2), hasta - 1, 2):
		var v := puntos[i] - luz[i] * r[i] * 0.45
		lienzo.draw_circle(v, maxf(1.0, r[i] * 0.3), VENTOSA)
		lienzo.draw_circle(v, maxf(0.5, r[i] * 0.12), VENTOSA_HUECO)


# La sombra del tentáculo en el suelo, por donde va a caer: en el aviso crece por la línea del golpe y se oscurece,
# y en el latigazo se recoge con él. Es lo que avisa a Johnny de por dónde no pasar. Como la de los pies
# (sombra.gd): tres capas, más oscura hacia el centro
func _pintar_sombra() -> void:
	var largo := LARGO
	var fuerza := 1.0
	if estado == "aviso":
		var k := t_ataque / AVISO
		largo *= ease(minf(1.0, k / 0.6), 0.4)
		fuerza = 0.6 + 0.4 * k
	elif estado == "latigazo":
		largo *= 1.0 - smoothstep(0.13, LATIGAZO, t_ataque)
	else:
		return
	if largo < 4.0:
		return
	var hacia := Vector2.from_angle(angulo)
	for capa in [[1.0, 0.2], [0.76, 0.22], [0.5, 0.24]]:
		en_suelo.draw_colored_polygon(_mancha(hacia, largo, ANCHO * capa[0]), Color(Sombra.COLOR, capa[1] * fuerza))


# La forma de la sombra: alargada desde los pies hacia "hacia", de "largo" de larga y "ancho" de medio ancho (algo
# más estrecha en la punta), con los dos extremos redondos
func _mancha(hacia: Vector2, largo: float, ancho: float) -> PackedVector2Array:
	var base := Vector2(0, SUELO)
	var fin := base + hacia * largo
	var punta := ancho * 0.8
	var a := hacia.angle()
	var puntos := PackedVector2Array()
	for i in 7:   # media vuelta por la punta...
		puntos.append(fin + Vector2.from_angle(a - PI / 2 + PI * i / 6.0) * punta)
	for i in 7:   # ...y otra por la base
		puntos.append(base + Vector2.from_angle(a + PI / 2 + PI * i / 6.0) * ancho)
	return puntos

