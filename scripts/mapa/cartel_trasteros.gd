# El cartel de «TRASTEROS» del pasillo de las viviendas (viviendas.gd), en la pared de arriba, nada más entrar desde la
# sala de mantenimiento: una placa de chapa esmaltada azul, vieja, con su filete crema, óxido en las esquinas y un
# tornillo a cada lado, de una imagen de GPT sin letras (tools/cartel_trasteros.py, 64 × 15 píxeles), y encima las letras
# en blanco roto, como el de la sala de mantenimiento (puerta.gd). Lo pone mapa.gd (poner_viviendas). El origen es el pie
# de la cara del muro (para ordenarse con ella).
extends Node2D

# Lo que pone, en español: se pinta ya traducido y la placa se estira por en medio con lo que mida (las puntas, con
# su tornillo, se quedan a su tamaño: PUNTA píxeles del dibujo cada una)
const TEXTO := "TRASTEROS"   # [traducir]
const LETRA := 16          # el tamaño de la letra (la fuente pixel art solo se ve nítida a 16 o 32)
const ALTO := 64.0         # a qué altura va el centro del cartel, por encima del pie del muro
const ALTO_PLACA := 30.0   # lo que mide de alto la placa
const PLACA := preload("res://assets/sprites/cartel-trasteros.png")
const PUNTA := 9
const BLANCO := Color("e9dfc6")   # el blanco roto del filete


func _draw() -> void:
	var texto := Idioma.t(TEXTO)
	var letras := ceilf(Tema.FUENTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA).x / 2.0) * 2.0
	var ancho := letras + 40.0
	var r := Rect2(-roundf(ancho / 4.0) * 2.0, -ALTO - ALTO_PLACA / 2.0, ancho, ALTO_PLACA)
	# su sombra en la chapa de la pared, abajo y a la derecha
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
	# la placa: las dos puntas a su tamaño y lo de en medio estirado
	var tam := PLACA.get_size()
	var punta := PUNTA * 2.0
	draw_texture_rect_region(PLACA, Rect2(r.position, Vector2(punta, r.size.y)), Rect2(0, 0, PUNTA, tam.y))
	draw_texture_rect_region(PLACA, Rect2(r.position.x + punta, r.position.y, r.size.x - punta * 2.0, r.size.y),
		Rect2(PUNTA, 0, tam.x - PUNTA * 2, tam.y))
	draw_texture_rect_region(PLACA, Rect2(r.end.x - punta, r.position.y, punta, r.size.y), Rect2(tam.x - PUNTA, 0, PUNTA, tam.y))
	# las letras, con su sombra
	var donde := Vector2(r.position.x + 20.0, r.position.y + 21.0)
	draw_string(Tema.FUENTE, donde + Vector2(2, 2), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, Color(0, 0, 0, 0.35))
	draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, BLANCO)
