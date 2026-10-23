# La cafetera de Johnny, sobre una mesita. Según el dosier de los Apartamentos (página «Sujeto 0»), se la regaló
# Velaria y con ella le daban el VD-7. Está en la habitación de la farmacéutica de las viviendas, junto a ella (la
# pone mapa.gd: poner_viviendas, cuando ya está rescatada); la primera vez que Johnny entra allí, ella le encuentra
# el doble fondo (supervivientes.gd: guino_cafetera).
# Dibujada con código, en píxeles de 2 unidades como los sprites: la mesita, la cafetera con su jarra, una taza y
# el vapor que sube. El origen es el pie de la mesita (para ordenarse con los personajes).
extends StaticBody2D

const P := 2.0                    # unidades por píxel del dibujo
const LINEA := Color("#1d1b2c")
const MADERA := Color("#b07a4c")
const CANTO := Color("#7a4c2c")
const PATA := Color("#6e4529")
const CUERPO := Color("#34313f")
const BRILLO := Color("#4f4a60")
const CRISTAL := Color("#8fb8c9")
const CAFE := Color("#5a3220")
const TAZA := Color("#f2ece0")

var tiempo := 0.0


func _ready() -> void:
	name = "Cafetera"
	add_to_group("obstaculos")   # que los zombis la rodeen
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 12)
	forma.shape = rect
	forma.position = Vector2(0, -6)
	add_child(forma)


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()   # el vapor se mueve


func _draw() -> void:
	draw_rect(Rect2(-8 * P, -1 * P, 16 * P, 2 * P), Color(0, 0, 0, 0.25))   # su sombra en el suelo
	# la mesita: patas y travesaño, y encima la tabla
	piezas([[-6, -7, 1, 7, PATA], [5, -7, 1, 7, PATA], [-6, -3, 12, 1, Color("#5a3820")]])
	piezas([[-7, -9, 14, 1, MADERA], [-7, -8, 14, 1, CANTO]])
	# la cafetera: el cuerpo, con un canto más claro, la tapa del filtro y su lucecita encendida
	piezas([[-5, -16, 6, 7, CUERPO], [-6, -18, 8, 2, BRILLO]])
	pixel(-5, -16, 1, 7, BRILLO)
	pixel(-6, -18, 8, 1, Color("#6a6480"))
	pixel(0, -15, 1, 1, Color("#ff5a4d"))
	# la jarra de cristal, con café hasta la mitad, un brillo y el asa
	piezas([[-4, -13, 4, 4, CRISTAL], [0, -12, 1, 2, Color("#22202a")]])
	pixel(-4, -11, 4, 2, CAFE)
	pixel(-4, -13, 1, 2, Color("#e6f6ff"))
	# la taza de Johnny
	piezas([[3, -11, 2, 2, TAZA], [5, -11, 1, 1, TAZA]])
	pixel(3, -11, 2, 1, CAFE)
	# el vapor: bolitas que suben de la cafetera (y una de la taza) y se van borrando
	for k in 4:
		var t := fmod(tiempo * 0.5 + k / 4.0, 1.0)
		var donde := Vector2(-2 * P + sin(t * 7.0 + k) * 3.0, -19 * P - t * 26.0)
		draw_circle(donde, 2.0 + t * 3.0, Color(1, 1, 1, 0.35 * (1.0 - t)))
	var t2 := fmod(tiempo * 0.4, 1.0)
	draw_circle(Vector2(4 * P + sin(t2 * 6.0) * 2.0, -12 * P - t2 * 14.0), 1.5 + t2 * 2.0, Color(1, 1, 1, 0.25 * (1.0 - t2)))


# Unas cuantas piezas [x, y, ancho, alto, color] (en píxeles del dibujo): primero el contorno de todas y luego
# su color, para que el contorno no se meta entre las de un mismo grupo
func piezas(lista: Array) -> void:
	for p in lista:
		draw_rect(Rect2((p[0] - 1) * P, (p[1] - 1) * P, (p[2] + 2) * P, (p[3] + 2) * P), LINEA)
	for p in lista:
		pixel(p[0], p[1], p[2], p[3], p[4])


func pixel(x: float, y: float, ancho: float, alto: float, color: Color) -> void:
	draw_rect(Rect2(x * P, y * P, ancho * P, alto * P), color)
