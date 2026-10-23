# La placa de cada habitación de las viviendas (viviendas.gd), en la pared, a la derecha de su puerta: de latón, como
# las de los pisos (puerta.gd), con un cuadradito del color del superviviente y su nombre. Va también en las puertas
# cerradas: así se ve a quién falta por salvar. La pone mapa.gd (poner_viviendas). El origen es el pie de la cara del
# muro, en medio de la puerta (para ordenarse con ella).
extends Node2D

const PUERTA := preload("res://scripts/mapa/puerta.gd")
const LETRA := 16          # el tamaño de la letra (la fuente pixel art solo se ve nítida a 16 o 32)

var texto := ""
var color := Color.WHITE


func _draw() -> void:
	var metal: Dictionary = PUERTA.LATON
	var largo := ceilf(Tema.FUENTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA).x / 2.0) * 2.0
	# a la derecha del marco de la puerta y a la altura de los ojos, como la de los pisos
	var r := Rect2(40, -82, largo + 32, 26)
	draw_rect(r, metal.filo)
	var dentro := r.grow(-2)
	draw_rect(dentro, metal.medio)
	draw_rect(Rect2(dentro.position, Vector2(dentro.size.x, 2)), metal.luz)
	draw_rect(Rect2(dentro.position, Vector2(2, dentro.size.y)), metal.luz)
	draw_rect(Rect2(dentro.position.x, dentro.end.y - 2, dentro.size.x, 2), metal.sombra)
	draw_rect(Rect2(dentro.end.x - 2, dentro.position.y + 2, 2, dentro.size.y - 2), metal.sombra)
	# el cuadradito de su color, con su borde
	draw_rect(Rect2(r.position + Vector2(6, 8), Vector2(10, 10)), metal.filo)
	draw_rect(Rect2(r.position + Vector2(8, 10), Vector2(6, 6)), color)
	draw_string(Tema.FUENTE, r.position + Vector2(22, 19), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, metal.letra)
