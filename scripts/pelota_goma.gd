# Una pelota de goma del antidisturbios (minijefe del centro comercial; docs/JEFES_CENTRO.md), dibujada con código.
# Sale disparada de su escudo y rebota en las paredes y los muebles sin pararse nunca: no se va sola, así que cada
# tanda se suma a las de antes y la sala se va llenando. Si le da a Johnny le quita lo suyo y rebota (si está
# esquivando, le pasa por encima). Se rompe de un disparo de Johnny (bala.gd, romper_en). Cuando el escudo revienta
# (antidisturbios.gd, romper_escudo), revientan todas a la vez (reventar).
# Se crea con PelotaGoma.new() y se le pone "velocidad" (y "dueno") antes de meterla en la escena.
class_name PelotaGoma
extends Node2D

const RADIO := 9.0
const ALTURA := 14.0       # a qué altura del suelo va (rebota, así que sube y baja un poco)
const DANO := 8
const ESPERA_GOLPE := 0.6  # tras darle a Johnny, lo que tarda en poder darle otra vez
const COLORES := [Color("#ff9a3c"), Color("#ffd23f"), Color("#5fd3ff")]   # naranja, amarilla, azul

var velocidad := Vector2.ZERO
var dueno: Node2D = null
var color := Color("#ff9a3c")
var t := 0.0
var espera := 0.0


func _ready() -> void:
	add_to_group("balas_zombi")   # (el bot las esquiva como las demás balas; al enfadarse los jefes se borran)
	add_to_group("pelotas_goma")
	z_index = 4
	color = COLORES[randi() % COLORES.size()]


func _physics_process(delta: float) -> void:
	t += delta
	espera -= delta
	queue_redraw()
	var antes := global_position
	var despues := antes + velocidad * delta
	# rebota en las paredes y los muebles (capa de choque 1), como una bola de billar
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		velocidad = velocidad.bounce(choque.normal)
		global_position = choque.position + choque.normal * 2.0
		if randf() < 0.5:
			Sonido.tocar("boing")
		return
	global_position = despues
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo or espera > 0.0 or johnny.esquiva_t > 0.0:
		return
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < johnny.RADIO + RADIO:
		johnny.recibir_dano(DANO, dueno)
		espera = ESPERA_GOLPE
		velocidad = velocidad.bounce(hacia.normalized())   # rebota en él
		Sonido.tocar("boing")


# Una bala de Johnny en "p": si la toca, la pelota se rompe (bala.gd). Devuelve si la ha roto
func romper_en(p: Vector2) -> bool:
	if p.distance_to(global_position) > RADIO + 8.0:
		return false
	romper()
	return true


func romper() -> void:
	for i in 6:
		Particulas.soltar(get_parent(), global_position, Vector2.from_angle(randf() * TAU) * randf_range(60, 140), color, 3, 0.3)
	Sonido.tocar("chof")
	queue_free()


# El escudo ha reventado: revienta con un fogonazo (más grande que al romperla)
func reventar() -> void:
	for i in 10:
		Particulas.soltar(get_parent(), global_position, Vector2.from_angle(randf() * TAU) * randf_range(90, 220),
			Color("#ffffff") if i % 3 == 0 else color, 3, 0.4)
	queue_free()


func _draw() -> void:
	# su sombra en el suelo y la pelota encima, botando
	var bote := absf(sin(t * 9.0)) * 6.0
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1, 0.45))
	Formas.disco(self, Vector2.ZERO, RADIO, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	# la pelota: un círculo de pixel art de 10×10 píxeles del dibujo (cada uno, 2 unidades), con su borde oscuro, la
	# sombra abajo a la derecha y el brillo arriba a la izquierda
	var c := (Vector2(-10, -ALTURA - bote - 10) / 2.0).floor() * 2.0
	for y in FORMA.size():
		var fila: String = FORMA[y]
		for x in fila.length():
			var col: Color
			match fila[x]:
				"o": col = Color("#1d1b2c")
				"#": col = color
				"s": col = color.darkened(0.35)
				"b": col = color.lightened(0.6)
				_: continue
			draw_rect(Rect2(c + Vector2(x, y) * 2.0, Vector2(2, 2)), col)


# El dibujo de la pelota: o, el borde; #, su color; s, la sombra; b, el brillo
const FORMA := [
	"...oooo...",
	".oo####oo.",
	".o#bb###o.",
	"o##bb####o",
	"o########o",
	"o#######so",
	"o######sso",
	".o####sso.",
	".oossssoo.",
	"...oooo...",
]
