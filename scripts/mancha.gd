# Una mancha que se queda en el suelo: lo chamuscado de una granada o la ceniza de un fuego que se ha apagado.
# Es una lista de cuadraditos de pixel art (celdas de 2 píxeles del dibujo). Se quedan hasta salir del sitio;
# si hay demasiadas, se borran las más viejas.
class_name Mancha
extends Node2D

const CELDA := 4.0   # 2 píxeles del dibujo
const MAXIMO := 40

var celdas: Array = []   # [posición, color] de cada cuadradito


func _ready() -> void:
	z_index = -2   # en el suelo, por debajo de los charcos
	add_to_group("manchas")
	var todas := get_tree().get_nodes_in_group("manchas")
	if todas.size() > MAXIMO:
		todas[0].queue_free()


func _draw() -> void:
	for c in celdas:
		draw_rect(Rect2(c[0], Vector2(CELDA, CELDA)), c[1])


# La marca negra de una explosión: un borrón irregular (aplastado, porque el suelo se ve de lado), negro en
# el centro y chamuscado alrededor
static func quemado(sala: Node, donde: Vector2, radio: float) -> void:
	var m := Mancha.new()
	m.position = (donde / CELDA).round() * CELDA
	var ondas := []
	for k in [3, 5, 8]:
		ondas.append([k, randf() * TAU, randf_range(0.06, 0.14)])
	var n := ceili(radio / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var d := Vector2(p.x, p.y / 0.6).length() / radio
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var ruido := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			if d > borde + (ruido - 0.5) * 0.15:
				continue
			var color := Color("#000000", 0.75) if d < 0.55 * borde else Color("#120d0b", 0.55)
			if ruido < 0.12:
				continue   # algún hueco suelto, para que no sea una mancha lisa
			m.celdas.append([p, color])
	sala.add_child(m)


# La mancha de un zombi derrotado (addDecal en src/game-efectos.js): un borrón ondulado, aplastado como el
# suelo, medio transparente y con tres gotas alrededor. Del color de su sangre
static func sangre(sala: Node, donde: Vector2, radio: float, color: Color) -> void:
	var m := Mancha.new()
	m.position = (donde / CELDA).round() * CELDA
	var semilla := randf() * TAU
	var tono := Color(color, 0.35)
	var gotas := []
	for i in 3:
		var a := semilla + i * 2.1
		gotas.append([Vector2(cos(a) * radio * 1.3, sin(a) * radio * 0.8), radio * 0.18])
	var n := ceili(radio * 1.6 / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var centro := p + Vector2(CELDA, CELDA) / 2.0
			var a := atan2(centro.y / 0.65, centro.x)
			var borde := radio * (0.75 + 0.3 * sin(a * 3.0 + semilla))
			var dentro := Vector2(centro.x, centro.y / 0.65).length() <= borde
			for g in gotas:
				dentro = dentro or centro.distance_to(g[0]) <= maxf(g[1], CELDA * 0.7)
			if dentro:
				m.celdas.append([p, tono])
	sala.add_child(m)
