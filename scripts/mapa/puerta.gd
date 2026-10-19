# Una salida de un mapa: las puertas de los apartamentos, el ascensor averiado, las escaleras y por donde se
# ha llegado. Se dibuja a mano, con rectángulos de colores (en múltiplos de 2 unidades, como un píxel del
# dibujo). Lleva una lucecita encima: verde si se puede pasar y roja si no.
#
# Delante tiene una zona invisible: cuando Johnny la pisa, avisa con "empujada" y la partida decide si se
# pasa al otro lado o se le dice por qué no se abre.
extends Node2D

signal empujada(indice: int)

const MARCO := Color("2b1d16")
const HOJA := Color("6b4329")
const PANEL := Color("573420")
const POMO := Color("d8b04a")
const HUECO := Color("1a1410")
const METAL := Color("8d949e")
const METAL_OSCURO := Color("4a4f57")
const VERDE := Color("6ee36e")
const ROJO := Color("e5484d")

var salida: Dictionary   # la de planta.gd: dir, tipo, letrero...
var indice := 0          # su número en la lista de salidas del sitio
var abierta := true:     # si se puede pasar (enciende la luz verde o la roja)
	set(valor):
		abierta = valor
		queue_redraw()


func _ready() -> void:
	# La zona que hay que pisar, pegada al muro por dentro
	var zona := Area2D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2   # solo Johnny
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	var vertical: bool = salida.dir == "izquierda" or salida.dir == "derecha"
	caja.size = Vector2(28, 56) if vertical else Vector2(56, 28)
	forma.shape = caja
	forma.position = {"arriba": Vector2(0, 14), "abajo": Vector2(0, -14), "izquierda": Vector2(14, 0),
		"derecha": Vector2(-14, 0)}[salida.dir]
	zona.add_child(forma)
	add_child(zona)
	zona.body_entered.connect(func(cuerpo):
		if cuerpo.is_in_group("jugador"):
			empujada.emit(indice))

	# El letrero
	var cartel := Label.new()
	cartel.text = salida.letrero
	cartel.add_theme_font_size_override("font_size", 12)
	cartel.add_theme_constant_override("outline_size", 4)
	cartel.add_theme_color_override("font_outline_color", Color(0.11, 0.1, 0.17))
	cartel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cartel.size = Vector2(120, 16)
	cartel.position = {"arriba": Vector2(-60, -102), "abajo": Vector2(-60, -24), "izquierda": Vector2(-20, -56),
		"derecha": Vector2(-100, -56)}[salida.dir]
	add_child(cartel)


# Dónde aparece Johnny al llegar por esta puerta (un poco hacia dentro)
func llegada() -> Vector2:
	return position + {"arriba": Vector2(0, 60), "abajo": Vector2(0, -60), "izquierda": Vector2(60, 0),
		"derecha": Vector2(-60, 0)}[salida.dir]


func _draw() -> void:
	var luz := VERDE if abierta else ROJO
	match salida.dir:
		"arriba":
			# De frente, sobre la cara del muro (que sube 96 desde aquí)
			if salida.tipo == "ascensor":
				draw_rect(Rect2(-36, -86, 72, 86), METAL_OSCURO)
				draw_rect(Rect2(-32, -80, 64, 80), METAL)
				draw_rect(Rect2(-2, -80, 4, 80), METAL_OSCURO)
				draw_rect(Rect2(-14, -94, 28, 8), Color("201010"))
				draw_rect(Rect2(-10, -92, 20, 4), ROJO.darkened(0.3))
				return
			draw_rect(Rect2(-36, -86, 72, 86), MARCO)
			draw_rect(Rect2(-32, -80, 64, 80), HOJA)
			for x in [-28, 4]:
				draw_rect(Rect2(x, -74, 24, 30), PANEL)
				draw_rect(Rect2(x, -38, 24, 32), PANEL)
			draw_rect(Rect2(-2, -80, 4, 80), MARCO)
			draw_rect(Rect2(-8, -44, 4, 4), POMO)
			draw_rect(Rect2(4, -44, 4, 4), POMO)
			draw_rect(Rect2(-4, -94, 8, 6), luz)
		"abajo":
			# Vista desde arriba: el hueco en el muro de abajo, con el marco y la hoja
			draw_rect(Rect2(-36, 0, 72, 64), MARCO)
			draw_rect(Rect2(-32, 0, 64, 64), HUECO)
			draw_rect(Rect2(-32, 0, 64, 8), HOJA)
			draw_rect(Rect2(-4, 14, 8, 6), luz)
		_:
			# En los laterales del pasillo: las escaleras (peldaños) o la puerta por donde se ha llegado
			var x0 := -64.0 if salida.dir == "izquierda" else 0.0
			draw_rect(Rect2(x0, -36, 64, 72), MARCO)
			if salida.tipo == "escaleras":
				for i in 8:
					draw_rect(Rect2(x0 + i * 8, -32, 8, 64), Color("6d6d72") if i % 2 else Color("57575c"))
			else:
				draw_rect(Rect2(x0, -32, 64, 64), HUECO)
			var borde := -8.0 if salida.dir == "izquierda" else 0.0   # la hoja, en el borde de dentro
			draw_rect(Rect2(borde, -32, 8, 64), HOJA)
			draw_rect(Rect2(borde + 2, -4, 4, 8), luz)
