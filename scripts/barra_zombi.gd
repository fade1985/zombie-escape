# La barrita de vida encima de la cabeza de un zombi, como pixelHpBar del juego JS (src/draw.js): marco
# oscuro de un píxel, el hueco vacío y la sangre, con una fila de brillo arriba y otra de sombra abajo.
# Solo sale cuando ya está herido (y se quita al morir). Va encajada en la cuadrícula del dibujo para que
# se vea nítida. La pone cada zombi al nacer (zombi.gd).
extends Node2D

const P := 2.0                 # un píxel del dibujo, en unidades
const ANCHO := 17              # en píxeles del dibujo, como en el JS
const LINEA := Color("#1d1b2c")
const VACIO := Color("#1a1620")
const SANGRE := [Color("#b02a22"), Color("#e8604a"), Color("#6a1512")]   # relleno, brillo y sombra

var zombi: Node2D
var alto := 86.0               # a qué altura sobre los pies va (un poco por debajo de los números de daño)
var antes := -1.0


func _ready() -> void:
	z_index = 5   # por encima de los zombis de alrededor


func _process(_delta: float) -> void:
	var parte: float = clampf(float(zombi.vida) / zombi.vida_max, 0.0, 1.0)
	visible = parte < 1.0 and zombi.estado != "muerto"
	if not visible:
		return
	# encajada en la cuadrícula del dibujo aunque el zombi esté entre dos píxeles
	global_position = ((zombi.global_position + Vector2(0, -alto)) / P).round() * P
	if parte != antes:
		antes = parte
		queue_redraw()


func _draw() -> void:
	var w := ANCHO * P
	var x := -roundf(ANCHO / 2.0) * P
	draw_rect(Rect2(x - P, -P, w + 2 * P, 5 * P), LINEA)   # el marco
	draw_rect(Rect2(x, 0, w, 3 * P), VACIO)                # el hueco
	var lleno := roundf(ANCHO * antes) * P
	if lleno <= 0.0:
		return
	draw_rect(Rect2(x, 0, lleno, 3 * P), SANGRE[0])
	draw_rect(Rect2(x, 0, lleno, P), SANGRE[1])
	draw_rect(Rect2(x, 2 * P, lleno, P), SANGRE[2])
