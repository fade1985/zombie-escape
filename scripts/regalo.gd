# Un regalo de la mascota (minijefe del centro comercial; docs/JEFES_CENTRO.md, «La fiesta de cumpleaños»): con
# «¡REGALOS!» tira varios por el aire alrededor de Johnny (mascota.gd, tirar_regalos). Cada uno vuela en arco de donde
# está ella a su sitio; mientras, en el suelo se ve dónde va a caer (el aviso de los jefes, aviso.gd, que se llena). Al
# caer revienta: le quita DANO a Johnny si está dentro (esquivando, no) y suelta pelotas saltarinas (mascota.gd,
# soltar_pelotas_en). Dibujo de PixelLab (regalo.png).
# Se crea con Regalo.new(), se le ponen "desde" (de dónde sale), "vuelo" y "dueno", y se mete en la escena en su sitio.
class_name Regalo
extends Node2D

const DIBUJO := preload("res://assets/sprites/regalo.png")
const RADIO := 48.0
const ALTO := 170.0        # lo alto que sube en el arco
const DANO := 12
const COLORES := [Color("#ff5d73"), Color("#ffd23f"), Color("#5fd3ff"), Color("#7ee081"), Color("#f4f0e4")]

var desde := Vector2.ZERO  # de dónde sale (en el mundo)
var vuelo := 0.9           # lo que tarda en caer
var dueno: Node2D = null
var t := 0.0
var sprite: Sprite2D


func _ready() -> void:
	z_index = 2
	sprite = Sprite2D.new()
	sprite.texture = DIBUJO
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	colocar()


func _physics_process(delta: float) -> void:
	t += delta
	colocar()
	queue_redraw()
	if t >= vuelo:
		caer()


# En el aire: de "desde" a su sitio, subiendo y bajando, dando vueltas
func colocar() -> void:
	var k := minf(1.0, t / vuelo)
	sprite.position = (desde - global_position) * (1.0 - k) + Vector2(0, -sin(k * PI) * ALTO - 12.0)
	sprite.rotation = k * TAU * 1.5


func caer() -> void:
	Sonido.tocar("chof")
	Temblor.temblar(4.0)
	for i in 16:
		Particulas.soltar(get_parent(), global_position + Vector2(0, -6),
			Vector2.from_angle(randf() * TAU) * randf_range(70, 190), COLORES[i % COLORES.size()], 3, 0.5)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and johnny.esquiva_t <= 0.0:
		var hacia: Vector2 = (johnny.global_position - global_position) * Vector2(1.0, 1.0 / 0.6)
		if hacia.length() < RADIO + johnny.RADIO:
			johnny.recibir_dano(DANO, dueno)
	if is_instance_valid(dueno) and dueno.has_method("soltar_pelotas_en"):
		dueno.soltar_pelotas_en(global_position)
	queue_free()


# Dónde va a caer: el círculo de aviso que se llena, con la sombra del regalo creciendo en medio
func _draw() -> void:
	var k := minf(1.0, t / vuelo)
	Aviso.abanico(self, Vector2.ZERO, 0.0, PI, RADIO, k, t, 0.6, 0.2 + 0.3 * k)
