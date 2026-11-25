# El globo de un crío de la fiesta (mascota.gd, fase 2, poner_globos; docs/JEFES_CENTRO.md, «La fiesta de
# cumpleaños»): los críos (el zombi rápido) que salen en la fase 2 llevan un globo atado. Cuando el crío muere, el
# globo revienta («¡POP!») y suelta PELOTAS pelotas saltarinas (las de la mascota, soltar_pelotas_en): más pelotas
# para que revienten cuando ella se coma una caja sorpresa... y más pelotas rebotando por la sala.
# Va de hijo del crío. Se dibuja con código, a cuadraditos: el globo, su brillo, el nudo y el hilo que se mece.
class_name Globo
extends Node2D

const COLORES := [Color("#ff5d73"), Color("#5fd3ff"), Color("#7ee081"), Color("#ffd23f"), Color("#c38bff")]
const GOTA := 2.0
const ALTO := 92.0           # a qué altura va el globo (sobre los pies del crío)

var dueno: Node2D = null     # la mascota
var color := Color("#ff5d73")
var t := 0.0


func _ready() -> void:
	color = COLORES.pick_random()
	t = randf() * 5.0
	z_index = 1
	var crio := get_parent()
	if crio.has_signal("murio"):
		crio.murio.connect(reventar)


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()


func reventar() -> void:
	var crio := get_parent()
	var donde: Vector2 = crio.global_position
	var sala := crio.get_parent()
	Sonido.tocar("boing")
	Zombi.texto_flotante(sala, donde + Vector2(-26, -ALTO - 30), Idioma.t("¡POP!"), color, 16)
	for i in 10:
		Particulas.soltar(sala, donde + Vector2(0, -ALTO), Vector2.from_angle(randf() * TAU) * randf_range(60, 150), color, 3, 0.4)
	if is_instance_valid(dueno) and dueno.estado != "muerto":
		dueno.soltar_pelotas_en(donde)
	queue_free()


func _draw() -> void:
	var mece := sin(t * 2.5) * 4.0
	var arriba := Vector2(mece, -ALTO)
	# el hilo, del crío (a la altura de la mano) al nudo
	var desde := Vector2(0, -34)
	for i in 8:
		var k := i / 8.0
		var p := desde.lerp(arriba + Vector2(0, 14), k) + Vector2(sin(t * 4.0 + k * 5.0) * 2.0 * k, 0)
		draw_rect(Rect2((p / GOTA).floor() * GOTA, Vector2(GOTA, GOTA * 2)), Color("#e8e8e8", 0.8))
	# el globo: un óvalo de 7 x 9 píxeles con borde oscuro, brillo y nudo
	var c := (arriba / GOTA).floor() * GOTA
	var oscuro := color.darkened(0.45)
	for y in range(-5, 5):
		var medio := floori(sqrt(maxf(0.0, 1.0 - pow((y + 0.5) / 5.0, 2.0))) * 4.0)
		draw_rect(Rect2(c + Vector2(-medio - 1, y) * GOTA, Vector2((medio * 2 + 3) * GOTA, GOTA)), oscuro)
		draw_rect(Rect2(c + Vector2(-medio, y) * GOTA, Vector2((medio * 2 + 1) * GOTA, GOTA)), color)
	draw_rect(Rect2(c + Vector2(-2, -3) * GOTA, Vector2(GOTA, GOTA * 2)), color.lightened(0.6))
	draw_rect(Rect2(c + Vector2(-1, 5) * GOTA, Vector2(GOTA * 3, GOTA)), oscuro)
