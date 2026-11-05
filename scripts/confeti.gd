# Un cañón de confeti del presentador (minijefe de Torre Velaria): marca en el suelo donde estaba Johnny y, al cabo de
# AVISO segundos, revienta. Si Johnny sigue dentro del círculo, le quita lo suyo; y salen por el aire papelitos de
# colores, que caen al suelo y se desvanecen. Dibujado con código.
# La marca va sin luz (para que se vea en la penumbra) y por debajo de todo; el confeti, por encima.
# Se crea con Confeti.new() (presentador.gd, confeti()).
class_name Confeti
extends Node2D

const RADIO := 52.0       # el círculo que daña
const PAPELES := 34       # los papelitos que salen
const VUELO := 1.3        # lo que duran por el aire y en el suelo
const COLORES := [Color("#ff4d8d"), Color("#ffd23f"), Color("#4dd2ff"), Color("#7dff6b"), Color("#c77dff"), Color("#ffffff")]

var aviso := 0.9
var dano := 10
var dueno: Node2D = null  # el presentador (para el cartel de derrota)
var t := 0.0
var reventado := false
var papeles := []         # cada uno: [posición, velocidad, color, giro, alto, velocidad hacia arriba]
var marca: Node2D


func _ready() -> void:
	add_to_group("balas_zombi")   # al enfadarse el presentador, se borran los que esperan
	z_index = 4
	marca = Node2D.new()
	marca.z_as_relative = false
	marca.z_index = -1
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	marca.material = sin_luz
	marca.draw.connect(pintar_marca)
	add_child(marca)


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	marca.queue_redraw()
	if not reventado and t >= aviso:
		reventar()
	if reventado:
		for p in papeles:
			p[5] -= 520.0 * delta          # cae
			p[4] = maxf(0.0, p[4] + p[5] * delta)
			if p[4] > 0.0:
				p[0] += p[1] * delta
				p[1] *= 0.96
			p[3] += delta * 9.0
		if t >= aviso + VUELO:
			queue_free()


func reventar() -> void:
	reventado = true
	Sonido.tocar("confeti")
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < RADIO + johnny.RADIO * 0.5:
		johnny.recibir_dano(dano, dueno if is_instance_valid(dueno) else null)
	for i in PAPELES:
		var a := randf() * TAU
		papeles.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(60.0, 240.0), COLORES[i % COLORES.size()],
			randf() * TAU, 8.0, randf_range(140.0, 300.0)])


# El aviso en el suelo: un círculo rosa que se va llenando y, en medio, la boca del cañón
func pintar_marca() -> void:
	if reventado:
		var k := clampf((t - aviso) / 0.25, 0.0, 1.0)
		marca.draw_circle(Vector2.ZERO, RADIO * (0.6 + 0.6 * k), Color(1.0, 0.95, 0.7, 0.5 * (1.0 - k)))
		return
	var lleno := clampf(t / aviso, 0.0, 1.0)
	var parpadeo := 0.5 + 0.5 * sin(t * 24.0) if lleno > 0.7 else 1.0
	marca.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))   # (aplastado: está en el suelo)
	marca.draw_circle(Vector2.ZERO, RADIO * lleno, Color("#ff4d8d", 0.22))
	marca.draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 32, Color("#ff4d8d", 0.85 * parpadeo), 3.0)
	marca.draw_circle(Vector2.ZERO, 9.0, Color("#2b2633", 0.9))
	marca.draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 12, Color("#ffd23f"), 2.0)
	marca.draw_set_transform(Vector2.ZERO)


# Los papelitos por el aire (cada uno a su altura) y, ya en el suelo, desvaneciéndose
func _draw() -> void:
	if not reventado:
		return
	var a := clampf((aviso + VUELO - t) / 0.4, 0.0, 1.0)
	for p in papeles:
		var c: Color = p[2]
		var lado := Vector2(cos(p[3]), 0.0) * 4.0
		var donde: Vector2 = p[0] + Vector2(0, -p[4])
		draw_line(donde - lado, donde + lado, Color(c, a), 3.0)
