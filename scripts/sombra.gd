# La sombra bajo los pies de un personaje: una elipse pixel art (con píxeles de 2 unidades, como los dibujos),
# en tres capas que se suman: casi negra en el centro y cada vez más suave hacia fuera. Va como primer hijo del
# personaje, así se dibuja por debajo de él. Al morir se apaga poco a poco (apagar()).
class_name Sombra
extends Node2D

const COLOR := Color(0.024, 0.016, 0.055)   # el mismo morado casi negro que la sombra de los aliados (persona.gd)
const PIXEL := 2.0

@export var ancho := 36.0   # en unidades del juego (2 por píxel del dibujo)
@export var alto := 12.0


func _draw() -> void:
	# de fuera hacia dentro: [tamaño, opacidad]
	for capa in [[1.0, 0.2], [0.76, 0.22], [0.5, 0.24]]:
		_elipse(ancho * capa[0], alto * capa[0], Color(COLOR, capa[1]))


# Una elipse hecha de filas de píxeles: cada fila tan ancha como la elipse a esa altura, redondeada al píxel
func _elipse(w: float, h: float, color: Color) -> void:
	var filas := maxi(2, roundi(h / PIXEL))
	var mitad := filas / 2.0
	for i in filas:
		var y := (i + 0.5 - mitad) / mitad   # de -1 a 1
		var medio := roundi(w / PIXEL / 2.0 * sqrt(1.0 - y * y)) * PIXEL
		if medio > 0:
			draw_rect(Rect2(-medio, (i - mitad) * PIXEL, medio * 2.0, PIXEL), color)


# Al morir: el cuerpo queda tirado en el suelo y la sombra de "estar de pie" se desvanece
func apagar(tiempo := 0.4) -> void:
	create_tween().tween_property(self, "modulate:a", 0.0, tiempo)
