# Un trozo de tabique que sube (mapa.gd: poner_tabiques): con "cajas", lo alto de la pared de arriba de una habitación,
# de una casilla de grueso, liso y claro, a la altura de la pared (SUBE casillas por encima de la suya), con la cara de
# la pared cayendo de él (cara_pared.gd). Donde no cae cara (las esquinas y donde se junta un tabique de los lados)
# baja hasta su casilla, para que el de los lados llegue hasta arriba. Lleva su filo de luz y su contorno oscuro donde
# se acaba, como el tabique plano (mapa.dibujar_tapas). Va con los personajes, ordenado por su "y" (el pie de su
# casilla, el de la cara): quien está detrás queda tapado, y entonces se vuelve medio transparente, como las caras.
extends Node2D

const SUBE := 3                       # lo que sube la pared (la cara, cara_pared.gd: ALTO), en casillas
const COLOR := Color("#c3c0b7")       # el tabique: liso y claro
const FILO := Color(1, 1, 1, 0.3)     # el filo de luz, junto al contorno
const CONTORNO := Color("#1d1b2c")    # la raya oscura donde se acaba (mapa.gd: CONTORNO)

var ancho := 32.0          # en unidades (casillas enteras)
# por cada casilla del tramo: si baja hasta la suya ("baja") y dónde lleva contorno: "arriba", "abajo" (si no baja) y
# a cada lado, "izq" y "der", en sus tres filas (lo alto y, si baja, las dos de debajo)
var casillas: Array = []


func _draw() -> void:
	# En píxeles del dibujo, como las caras: una casilla son 16, y lo alto del tabique, SUBE casillas por encima de la suya
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var y := -16.0 * (SUBE + 1)
	for i in casillas.size():
		var cas: Dictionary = casillas[i]
		var x := i * 16.0
		var filas := SUBE if cas.baja else 1
		draw_rect(Rect2(x, y, 16, 16 * filas), COLOR)
		if cas.arriba:
			draw_rect(Rect2(x, y + 1, 16, 1), FILO)
			draw_rect(Rect2(x, y - 1, 16, 2), CONTORNO)
		if cas.abajo:
			draw_rect(Rect2(x, y + 14, 16, 1), FILO)
			draw_rect(Rect2(x, y + 15, 16, 2), CONTORNO)
		for j in filas:
			if cas.izq[j]:
				draw_rect(Rect2(x + 1, y + 16 * j, 1, 16), FILO)
				draw_rect(Rect2(x - 1, y + 16 * j, 2, 16), CONTORNO)
			if cas.der[j]:
				draw_rect(Rect2(x + 14, y + 16 * j, 1, 16), FILO)
				draw_rect(Rect2(x + 15, y + 16 * j, 2, 16), CONTORNO)


func _process(delta: float) -> void:
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny == null:
		return
	var p := johnny.global_position - global_position
	var detras := p.x > -20.0 and p.x < ancho + 20.0 and p.y < 0.0 and p.y > -(SUBE + 1) * Planta.CASILLA - 8.0
	modulate.a = move_toward(modulate.a, 0.45 if detras else 1.0, delta * 4.0)
