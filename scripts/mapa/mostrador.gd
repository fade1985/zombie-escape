# El mostrador del puesto del ferretero, en su habitación de las viviendas: su mejora, cuando ya está rescatado
# (supervivientes.gd: poner_puesto). Él atiende detrás. Dibujado con código, en píxeles de 2 unidades como los
# sprites: un mostrador de tablas con la franja naranja de su chaleco y el letrero, y encima lo que vende (una caja
# de munición, un molotov y una granada). Delante tiene una zona invisible: cuando Johnny se arrima, avisa con
# "usar" y sale la ventanita del puesto (ui/puesto.gd). Como el baúl (arrimable.gd), hay que apartarse un poco
# antes de que se vuelva a abrir. El origen es el pie del mostrador (para ordenarse con los personajes).
extends StaticBody2D

signal usar

const P := 2.0                    # unidades por píxel del dibujo
const ANCHO := 104.0              # lo que ocupa en el suelo
const HONDO := 24.0
const LINEA := Color("#1d1b2c")
const MADERA := Color("#9a6a3e")
const VETA := Color("#7a4c2c")
const TABLERO := Color("#c08a55")
const NARANJA := Color("#ff8a1f")

var lista := true     # se pone a false al abrirse, y vuelve a true cuando Johnny se aparta


func _ready() -> void:
	name = "Mostrador"
	add_to_group("obstaculos")   # que los del equipo lo rodeen
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ANCHO, HONDO)
	forma.shape = rect
	forma.position = Vector2(0, -HONDO / 2.0)
	add_child(forma)

	var letrero := Label.new()
	letrero.text = "Ferretería"
	letrero.theme = Tema.crear()
	letrero.add_theme_color_override("font_color", Color("#ffd9a8"))
	letrero.size = Vector2(160, 20)
	letrero.position = Vector2(-80, -23)   # sobre el cartel oscuro del frente
	letrero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(letrero)

	# la zona de delante, donde se para Johnny para comprar
	var zona := Area2D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(ANCHO + 16, 40)
	hueco.shape = r
	hueco.position = Vector2(0, 18)
	zona.add_child(hueco)
	add_child(zona)
	zona.body_entered.connect(func(_cuerpo):
		if lista:
			lista = false
			usar.emit())
	zona.body_exited.connect(func(_cuerpo): lista = true)


func _draw() -> void:
	draw_rect(Rect2(-27 * P, -1 * P, 54 * P, 2 * P), Color(0, 0, 0, 0.25))   # su sombra en el suelo
	# el frente, de tablas, con el cartel oscuro del letrero (bajo, para que a él se le vea de cintura para arriba)
	piezas([[-26, -12, 52, 12, MADERA]])
	for x in [-25, -24, 23, 24]:
		pixel(x, -11, 1, 10, VETA)
	pixel(-26, -2, 52, 2, VETA)
	piezas([[-22, -11, 44, 10, Color("#2b2233")]])
	# el tablero de encima, que sobresale un poco, con la franja naranja de su chaleco y su raya brillante
	piezas([[-27, -15, 54, 3, TABLERO]])
	pixel(-27, -13, 54, 1, NARANJA)
	pixel(-27, -12, 54, 1, Color("#ffd23f"))
	# lo que vende, a los lados (en medio está él): una caja de munición con las balas asomando, un molotov y una
	# granada
	piezas([[-25, -21, 10, 6, Color("#5b6b33")]])
	pixel(-25, -21, 10, 1, Color("#7d8f4a"))
	for x in [-23, -20, -17]:
		pixel(x, -23, 1, 2, Color("#e0b030"))
	pixel(-22, -19, 4, 2, Color("#e0b030"))   # la chapa de la caja
	piezas([[11, -23, 5, 8, Color("#5f8a3a")], [12, -26, 3, 3, Color("#5f8a3a")], [12, -29, 3, 3, Color("#e8dcc0")]])
	pixel(11, -23, 1, 7, Color("#8fbf5a"))   # el brillo del cristal
	pixel(11, -19, 5, 3, Color("#c9772e"))   # la gasolina de dentro
	piezas([[19, -22, 7, 7, Color("#556b2f")], [21, -24, 3, 2, Color("#9aa0a8")]])
	pixel(19, -19, 7, 1, Color("#3e5022"))
	pixel(22, -22, 1, 7, Color("#3e5022"))
	pixel(25, -25, 2, 2, Color("#c0c4d0"))   # la anilla


# Unas cuantas piezas [x, y, ancho, alto, color] (en píxeles del dibujo): primero el contorno de todas y luego
# su color, para que el contorno no se meta entre las de un mismo grupo
func piezas(lista_piezas: Array) -> void:
	for p in lista_piezas:
		draw_rect(Rect2((p[0] - 1) * P, (p[1] - 1) * P, (p[2] + 2) * P, (p[3] + 2) * P), LINEA)
	for p in lista_piezas:
		pixel(p[0], p[1], p[2], p[3], p[4])


func pixel(x: float, y: float, ancho: float, alto: float, color: Color) -> void:
	draw_rect(Rect2(x * P, y * P, ancho * P, alto * P), color)
