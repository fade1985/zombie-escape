# El cartel de «TRASTEROS» del pasillo de las viviendas (viviendas.gd), en la pared de arriba, nada más entrar desde la
# sala de mantenimiento: una placa de chapa esmaltada del mismo azul que las puertas de los trasteros, con un filete
# blanco por dentro del borde, las letras blancas y un tornillo a cada lado, como los carteles de los trasteros de
# verdad. Lo pone mapa.gd (poner_viviendas). El origen es el pie de la cara del muro (para ordenarse con ella).
extends Node2D

const TEXTO := "TRASTEROS"
const LETRA := 16          # el tamaño de la letra (la fuente pixel art solo se ve nítida a 16 o 32)
const ALTO := 64.0         # a qué altura va el centro del cartel, por encima del pie del muro
const ALTO_PLACA := 30.0   # lo que mide de alto la placa
const FILO := Color("1d1b2c")          # el contorno de siempre
const AZUL := Color("3468a0")          # el de las puertas de los trasteros (tools/trastero.py)
const AZUL_SOMBRA := Color("26507f")
const BLANCO := Color("e6eaee")
const TORNILLO := [Color("dee2e8"), Color("70768a")]   # su brillo y su sombra


func _draw() -> void:
	var letras := ceilf(Tema.FUENTE.get_string_size(TEXTO, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA).x / 2.0) * 2.0
	var ancho := letras + 36.0
	var r := Rect2(-roundf(ancho / 4.0) * 2.0, -ALTO - ALTO_PLACA / 2.0, ancho, ALTO_PLACA)
	# su sombra en la chapa de la pared, abajo y a la derecha
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, FILO)
	var dentro := r.grow(-2)
	draw_rect(dentro, AZUL)
	draw_rect(Rect2(dentro.position.x, dentro.end.y - 2, dentro.size.x, 2), AZUL_SOMBRA)
	# el filete blanco, a un píxel del borde
	var filete := dentro.grow(-2)
	draw_rect(Rect2(filete.position, Vector2(filete.size.x, 2)), BLANCO)
	draw_rect(Rect2(filete.position.x, filete.end.y - 2, filete.size.x, 2), BLANCO)
	draw_rect(Rect2(filete.position, Vector2(2, filete.size.y)), BLANCO)
	draw_rect(Rect2(filete.end.x - 2, filete.position.y, 2, filete.size.y), BLANCO)
	# un tornillo a cada lado, en medio
	for x in [r.position.x + 8.0, r.end.x - 12.0]:
		draw_rect(Rect2(x, r.position.y + 12, 4, 4), TORNILLO[1])
		draw_rect(Rect2(x, r.position.y + 12, 2, 2), TORNILLO[0])
	draw_string(Tema.FUENTE, Vector2(r.position.x + 18, r.position.y + 21), TEXTO, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, BLANCO)
