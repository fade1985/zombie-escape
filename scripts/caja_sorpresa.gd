# Una caja sorpresa de la Juguetería: el truco para pegarle a la mascota (minijefe del centro comercial;
# docs/JEFES_CENTRO.md, «La fiesta de cumpleaños»). Hay CAJAS repartidas por la sala (mascota.gd, poner_cajas). Si la
# mascota se la come embistiendo, el muñeco del muelle salta («¡SORPRESA!»), ella cae de culo mareada mucho más rato
# y todas las pelotas revientan (mascota.gd, sorpresa). La caja abierta se queda un rato, se va con una nubecita y, al
# poco, cae otra en otro sitio (mascota.gd, reponer_cajas).
# Es un mueble más: choca con todo (capa 1, como los muebles: la mascota se estrella en ella, Johnny no la atraviesa
# y las pelotas rebotan), pero no se rompe. Dibujos de PixelLab: la caja cerrada y el muñeco saliendo (una hoja).
# Se crea con CajaSorpresa.new() y se mete en la escena; ella sola cae del techo.
class_name CajaSorpresa
extends StaticBody2D

const CERRADA := preload("res://assets/sprites/caja-sorpresa.png")
const SALTA := preload("res://assets/sprites/caja-sorpresa-salta.png")
const CUADROS := 9          # los fotogramas de la hoja del muñeco saliendo
const CUADRO := 0.07        # lo que dura cada uno
const RADIO := 22.0
const CAE := 0.45           # lo que tarda en caer del techo al aparecer
const ABIERTA := 4.0        # lo que se queda abierta antes de irse
const PIES := 4.0           # dónde están sus pies en el dibujo, desde abajo

var t := 0.0
var abierta := false
var abierta_t := 0.0
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("cajas_sorpresa")
	collision_layer = 1
	collision_mask = 0
	var choque := CollisionShape2D.new()
	choque.name = "Choque"
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO
	choque.shape = circulo
	add_child(choque)
	sprite = Sprite2D.new()
	sprite.texture = CERRADA
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -CERRADA.get_height() / 2.0 + PIES)
	add_child(sprite)
	sprite.position.y = -500.0


func _physics_process(delta: float) -> void:
	t += delta
	if t < CAE:
		var k := t / CAE
		sprite.position.y = -500.0 * (1.0 - k * k)
		return
	if sprite.position.y != 0.0:
		# acaba de caer: un golpe seco y una nubecita
		sprite.position.y = 0.0
		Sonido.tocar("chof")
		for i in 6:
			Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-16, 16), 4),
				Vector2(randf_range(-80, 80), randf_range(-30, 10)), Color("#d8d0c0", 0.7), randf_range(3, 5), 0.4)
	if not abierta:
		# de vez en cuando, la manivela da un tironcito (para que se vea que está viva)
		sprite.position.x = 1.0 if fmod(t, 2.6) < 0.08 else 0.0
		return
	abierta_t += delta
	var cuadro := mini(int(abierta_t / CUADRO), CUADROS - 1)
	if cuadro == CUADROS - 1:
		# el muñeco se queda botando en su muelle
		cuadro = CUADROS - 2 + int(abierta_t / 0.18) % 2
	sprite.frame = cuadro
	if abierta_t >= ABIERTA:
		irse()


# Si la mascota está aún a tiempo de estrellarse en ella (la que acaba de caer, todavía en el aire, no cuenta)
func lista() -> bool:
	return not abierta and t >= CAE


# ¡Sorpresa! El muñeco sale disparado de la caja
func abrir() -> void:
	abierta = true
	abierta_t = 0.0
	sprite.texture = SALTA
	sprite.hframes = CUADROS
	sprite.frame = 0
	sprite.offset = Vector2(0, -SALTA.get_height() / 2.0 + PIES)
	Sonido.tocar("boing")
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-56, -190), Idioma.t("¡SORPRESA!"), Color("#ffd23f"), 22)
	for i in 14:
		Particulas.soltar(get_parent(), global_position + Vector2(0, -40),
			Vector2.from_angle(randf() * TAU) * randf_range(80, 200),
			[Color("#ff5d73"), Color("#ffd23f"), Color("#5fd3ff"), Color("#7ee081")][i % 4], 3, 0.6)


# Se va con una nubecita (la mascota pone otra al rato)
func irse() -> void:
	for i in 10:
		Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-18, 18), -randf_range(0, 40)),
			Vector2(randf_range(-60, 60), randf_range(-80, -20)), Color("#e8e0d0", 0.8), randf_range(3, 6), 0.5)
	queue_free()
