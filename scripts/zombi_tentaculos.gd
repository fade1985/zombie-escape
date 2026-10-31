# El zombi de tentáculos: muy lento, pero ataca desde lejos. Cuando ve a Johnny a tiro, apunta hacia donde está
# AHORA y, al rato, lanza un latigazo en esa línea: si Johnny se ha movido, falla. El latigazo se para en las paredes
# y los muebles. Números de src/zombies.js (TENTACLE).
# Su hoja (zombi-tentaculos-gpt, hecha con tools/zombi.py) tiene andar, latigazo, golpe y muerte de PixelLab. El
# latigazo va al ritmo del aviso: mientras avisa echa los tentáculos atrás y, al dar el golpe, los lanza hacia
# delante. El tentáculo largo que pega se pinta con código (tentaculo.gd): durante el aviso le sale del hombro, se
# levanta por encima de la cabeza, se enrosca y tiembla, mientras en el suelo sale el mismo aviso que en las cargas
# de los jefes (Aviso.franja: flechas que se encienden hacia donde va y, al final, una X, o una estrella si da con
# una pared); con el golpe se estira como un látigo, cae sobre el aviso y se recoge.
extends Zombi

const LARGO := 220.0        # hasta dónde llega el latigazo (si no da antes con una pared)
const ANCHO := 16.0         # medio ancho de la línea del golpe (y de su aviso)
const AVISO := 0.7          # segundos de aviso antes del golpe
const LATIGAZO := 0.25      # lo que dura el golpe
const ESPERA := 2.5         # entre un latigazo y el siguiente
const DANO_LATIGAZO := 15
const PARARSE := 140.0      # a esta distancia ya no se acerca más: ataca desde ahí
const IMPACTO := 3          # el fotograma del ataque en que lanza los tentáculos (antes, los echa atrás)

# El tentáculo pintado con código, igual que los de su espalda cuando ataca (colores sacados píxel a píxel de su
# latigazo de PixelLab; al pintarlos se oscurecen como su dibujo en el juego): borde casi negro y granate oscuro,
# algo más claro hacia el lado de la luz. Las capas van de la más oscura (todo el ancho) a la más clara: color y lo
# que ocupa (en partes del ancho, contando desde el borde de la luz). Las ventosas, también como las suyas: un aro
# rosa con el centro casi negro, un poco de sombra rosa oscura y un punto de brillo
const PALETA := {
	"contorno": Color("#0e0403"),
	"capas": [
		[Color("#2a1918"), 1.0],
		[Color("#3c2224"), 0.85],
		[Color("#422224"), 0.7],
		[Color("#4a292a"), 0.5],
		[Color("#5b3232"), 0.35],
		[Color("#693a39"), 0.18],
		[Color("#824a48"), 0.08],
	],
	"ventosas": {"aro": Color("#ee8e9c"), "sombra": Color("#d07279"), "brillo": Color("#ffc2d4"),
		"hueco": Color("#0e0403")},
}
const DESDE := Vector2(0, 6)   # de dónde sale el aviso en el suelo, como en los jefes (minijefe.gd, franja)
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
var t_ataque := 0.0
var tentaculo := Tentaculo.new(PALETA, true)   # (su dibujo pasa por el shader de los zombis)
var delante: Node2D         # pinta la parte del tentáculo que va por delante del cuerpo


func _ready() -> void:
	super()
	espera = randf_range(1.0, 2.2)
	tentaculo.largo = LARGO
	tentaculo.ancho = ANCHO
	# El tentáculo se pinta en dos capas: la base, en el propio zombi (que pinta siempre por detrás de su dibujo), y el
	# resto en "delante", que va después del dibujo y por eso queda encima
	delante = Node2D.new()
	delante.draw.connect(_pintar_delante)
	add_child(delante)


func _physics_process(delta: float) -> void:
	espera -= delta
	super(delta)
	queue_redraw()
	delante.queue_redraw()


func andar(delta: float, johnny: Node2D) -> void:
	var ve := se_ve(johnny) and not en_puerta()
	var distancia := distancia_a(johnny)
	if ve and espera <= 0.0 and distancia < LARGO + johnny.RADIO:
		# Apunta a donde está Johnny ahora mismo (y mide hasta dónde llegará, por si hay una pared)
		estado = "aviso"
		t_ataque = 0.0
		tentaculo.apuntar(self, (johnny.global_position - global_position).angle())
		mirar_hacia(Vector2.from_angle(tentaculo.angulo))
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
		# Mientras se enciende el aviso, echa los tentáculos atrás (los fotogramas de antes del impacto) y tiembla
		sprite.frame = mini(int(t_ataque / AVISO * IMPACTO), IMPACTO - 1)
		sprite.position.x = randf_range(-1.0, 1.0)
		if t_ataque >= AVISO:
			estado = "latigazo"
			t_ataque = 0.0
			sprite.position.x = 0.0
			Sonido.tocar("latigazo")
			if johnny != null and johnny.vivo and tentaculo.golpea(self, johnny):
				johnny.recibir_dano(DANO_LATIGAZO, self)
	elif estado == "latigazo":
		# Los lanza en el primer instante y los recoge mientras dura el golpe
		var resto := sprite.sprite_frames.get_frame_count(sprite.animation) - IMPACTO
		sprite.frame = IMPACTO + mini(int(t_ataque / LATIGAZO * resto), resto - 1)
		if t_ataque >= LATIGAZO:
			estado = "andar"
			espera = ESPERA


func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	sprite.position.x = 0.0
	super(cantidad, fuerza)


# El aviso en el suelo, el de las cargas de los jefes (va por detrás de todo el zombi). Y la base del tentáculo, por
# detrás del dibujo: así parece que sale de detrás del hombro (de espaldas no, que le sale de la espalda, de cara a
# nosotros)
func _draw() -> void:
	if estado == "aviso":
		tentaculo.avisar(self, DESDE, t_ataque / AVISO, tiempo)
	var puntos := _tentaculo()
	if not puntos.is_empty() and direccion not in DE_ESPALDAS:
		tentaculo.pintar(self, puntos, 0, DETRAS)


# El resto, por delante del dibujo
func _pintar_delante() -> void:
	var puntos := _tentaculo()
	if not puntos.is_empty():
		tentaculo.pintar(delante, puntos, 0 if direccion in DE_ESPALDAS else DETRAS, Tentaculo.PUNTOS)


# Los puntos del tentáculo en este momento, de la base a la punta (ninguno si no está atacando). Si Johnny queda
# justo abajo o justo arriba, se enrosca hacia el lado del hombro
func _tentaculo() -> PackedVector2Array:
	var lado := 1.0 if HOMBRO[direccion][0].x >= 0.0 else -1.0
	if estado == "aviso":
		return tentaculo.levantado(_hombro(), t_ataque / AVISO, t_ataque, lado)
	if estado == "latigazo":
		return tentaculo.latigo(_hombro(), DESDE, t_ataque, LATIGAZO, lado)
	return PackedVector2Array()


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
