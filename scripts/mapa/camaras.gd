# Las pantallas de las cámaras de seguridad, en la habitación del técnico de las viviendas (viviendas.gd), detrás de
# él: su mejora. Sale cuando ya está rescatado (en el centro comercial) y, desde entonces, el minimapa enseña los zombis
# (minimapa.gd). Dibujadas con código, en píxeles de 2 unidades como los sprites: una mesa metálica con cuatro
# monitores viejos, cada uno con la imagen verdosa de una cámara (rayas, figuras que pasan y algún chispazo de
# nieve) y, en el primero, el piloto rojo de grabar. El origen es el pie de la mesa (para ordenarse con los
# personajes).
extends StaticBody2D

const P := 2.0                    # unidades por píxel del dibujo
const LINEA := Color("#1d1b2c")
const METAL := Color("#5b616a")
const METAL_CLARO := Color("#8a919b")
const CARCASA := Color("#3a3d46")
const CARCASA_CLARA := Color("#5a5f6c")
const PANTALLA := Color("#3b6b52")
const RAYA := Color("#2e5743")
const SILUETA := Color("#15261d")
const NIEVE := Color("#b9e6c9")
const REC := Color("#ff3b3b")

var tiempo := 0.0


func _ready() -> void:
	name = "Camaras"
	add_to_group("obstaculos")   # que los zombis la rodeen
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 14)
	forma.shape = rect
	forma.position = Vector2(0, -7)
	add_child(forma)
	# el resplandor verde de las pantallas
	var brillo := PointLight2D.new()
	brillo.texture = preload("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.9
	brillo.color = Color("#7dffb0")
	brillo.energy = 0.45
	brillo.position = Vector2(0, -44)
	add_child(brillo)


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()   # las imágenes de las cámaras se mueven


func _draw() -> void:
	draw_rect(Rect2(-16 * P, -1 * P, 32 * P, 2 * P), Color(0, 0, 0, 0.25))   # su sombra en el suelo
	# la mesa metálica: patas, la balda de abajo (con un aparato y sus cables) y el tablero
	piezas([[-14, -9, 1, 9, METAL], [13, -9, 1, 9, METAL], [-14, -3, 28, 1, METAL]])
	piezas([[-8, -6, 7, 3, CARCASA]])
	pixel(-7, -5, 1, 1, Color("#4fe3ff"))
	pixel(-5, -5, 1, 1, REC if fmod(tiempo, 1.0) < 0.5 else Color("#5a1a1a"))
	piezas([[-15, -11, 30, 2, METAL_CLARO]])
	pixel(-15, -10, 30, 1, METAL)
	# los cuatro monitores, de dos en dos
	for fila in 2:
		for col in 2:
			monitor(-14 + col * 15, -21 - fila * 11, fila * 2 + col)


# Un monitor: la carcasa, la pantalla con su imagen y, debajo, el pie
func monitor(x: int, y: int, i: int) -> void:
	piezas([[x, y, 13, 10, CARCASA]])
	pixel(x, y, 13, 1, CARCASA_CLARA)
	pixel(x + 1, y + 1, 11, 7, PANTALLA)
	for r in range(2, 8, 2):
		pixel(x + 1, y + r, 11, 1, RAYA)
	# dos figuras que pasan por delante de la cámara, cada una a su paso
	for k in 2:
		var paso := 0.5 + 0.25 * i + 0.35 * k
		var fx := x + 1 + int(fposmod(tiempo * paso * 3.0 + i * 2.7 + k * 5.0, 10.0))
		var fy := y + 3 + k * 2
		pixel(fx, fy, 1, 1, SILUETA)
		pixel(fx, fy + 1, 1, 2, SILUETA)
	# de vez en cuando, un chispazo de nieve
	if fposmod(tiempo * 0.7 + i * 0.31, 1.0) < 0.06:
		for k in 6:
			pixel(x + 1 + (k * 5 + i * 3) % 11, y + 1 + (k * 3 + int(tiempo * 20.0)) % 7, 1, 1, NIEVE)
	# el piloto de grabar, en la primera
	if i == 0 and fmod(tiempo, 1.0) < 0.6:
		pixel(x + 10, y + 1, 1, 1, REC)
	# el pie y la ruedecita de encendido
	pixel(x + 11, y + 8, 1, 1, Color("#7dffb0"))
	pixel(x + 5, y + 10, 3, 1, LINEA)


# Unas cuantas piezas [x, y, ancho, alto, color] (en píxeles del dibujo): primero el contorno de todas y luego
# su color, para que el contorno no se meta entre las de un mismo grupo
func piezas(lista: Array) -> void:
	for p in lista:
		draw_rect(Rect2((p[0] - 1) * P, (p[1] - 1) * P, (p[2] + 2) * P, (p[3] + 2) * P), LINEA)
	for p in lista:
		pixel(p[0], p[1], p[2], p[3], p[4])


func pixel(x: float, y: float, ancho: float, alto: float, color: Color) -> void:
	draw_rect(Rect2(x * P, y * P, ancho * P, alto * P), color)
