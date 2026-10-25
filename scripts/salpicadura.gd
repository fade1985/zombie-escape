# La salpicadura de una gota de agua sucia al chocar (contra una pared o contra Johnny): unas gotitas saltan en
# arco, caen al suelo y dejan una manchita mojada que se seca en un par de segundos. De pixel art, como las
# manchas (mancha.gd). Las gotas, en bala_zombi.gd.
class_name Salpicadura
extends Node2D

const PIXEL := 2.0
const CELDA := 4.0
const GRAVEDAD := 900.0
const SECA := 2.2      # lo que tarda en secarse la mancha
const ALTO := 22.0     # a qué altura del suelo choca la gota (la de bala_zombi.gd)

var colores: Dictionary
var gotitas := []      # [posición en el suelo, velocidad, altura, velocidad hacia arriba, tamaño]
var mojado := []       # [posición, color] de cada cuadradito de la mancha
var t := 0.0
var polvo := false
var suelo: Node2D      # la mancha va en el suelo, por debajo de todo; las gotitas, a la altura de las balas


# "hacia": hacia dónde salen (contra una pared, de vuelta; contra Johnny, hacia delante). "de_polvo": el polvo del
# giro, que se deshace sin dejar mancha
static func lanzar(sala: Node, donde: Vector2, hacia: Vector2, colores_agua: Dictionary, de_polvo := false) -> void:
	var s := Salpicadura.new()
	s.polvo = de_polvo
	s.position = donde
	s.colores = colores_agua
	s.z_index = 4
	var base := hacia.angle()
	for i in 8:
		var a := base + randf_range(-1.3, 1.3)
		s.gotitas.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(60.0, 150.0), ALTO,
			randf_range(100.0, 260.0), PIXEL * (2.0 if i < 4 else 1.0)])
	if de_polvo:
		sala.add_child(s)
		return
	# la mancha donde cae lo gordo: un borrón pequeño y aplastado
	var r := randf_range(10.0, 14.0)
	var n := ceili(r / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			if Vector2(p.x, p.y / 0.6).length() <= r * randf_range(0.8, 1.15):
				var borde := Vector2(p.x, p.y / 0.6).length() > r * 0.6
				s.mojado.append([p, Color(colores_agua.medio if borde else colores_agua.oscuro, 0.7)])
	sala.add_child(s)


func _ready() -> void:
	add_to_group("salpicaduras")
	suelo = Node2D.new()
	suelo.z_as_relative = false
	suelo.z_index = -2   # como las manchas
	suelo.draw.connect(_pintar_suelo)
	add_child(suelo)


func _process(delta: float) -> void:
	t += delta
	for g in gotitas:
		if g[2] <= 0.0:
			continue
		g[0] += g[1] * delta
		g[3] -= GRAVEDAD * delta
		g[2] += g[3] * delta
		if g[2] <= 0.0 and not polvo:   # ha caído: deja su gotita mojada en el suelo
			mojado.append([((g[0] - Vector2(PIXEL, PIXEL)) / PIXEL).round() * PIXEL, Color(colores.oscuro, 0.7), g[4] + PIXEL])
	if t >= SECA:
		queue_free()
		return
	queue_redraw()
	suelo.queue_redraw()


func _draw() -> void:
	# el "plof" al chocar: un anillo de agua que se abre y se apaga enseguida
	if t < 0.2:
		var k := t / 0.2
		draw_set_transform(Vector2(0, -ALTO), 0.0, Vector2(1.0, 0.7))
		draw_arc(Vector2.ZERO, 5.0 + k * 14.0, 0.0, TAU, 16, Color(colores.claro, 1.0 - k), PIXEL * 1.5)
		draw_set_transform(Vector2.ZERO)
	for g in gotitas:
		if g[2] > 0.0:
			var p: Vector2 = (g[0] / PIXEL).round() * PIXEL + Vector2(0, -roundf(g[2] / PIXEL) * PIXEL)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(g[4] + 2, g[4] + 2)), colores.borde)
			draw_rect(Rect2(p, Vector2(g[4], g[4])), colores.claro)
			if g[4] > PIXEL:
				draw_rect(Rect2(p, Vector2(PIXEL, PIXEL)), colores.brillo)


func _pintar_suelo() -> void:
	var seco := clampf((t - SECA * 0.4) / (SECA * 0.6), 0.0, 1.0)   # aguanta un rato y luego se va secando
	for m in mojado:
		var c: Color = m[1]
		var tam: float = m[2] if m.size() > 2 else CELDA
		suelo.draw_rect(Rect2(m[0], Vector2(tam, tam)), Color(c, c.a * (1.0 - seco)))
