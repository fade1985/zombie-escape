# Algo que se lanza en parábola: el moco del venenoso, la botella de lejía de la portera, el cóctel molotov de
# Johnny, su vómito (mutación Gastroenteritis), el ácido que salpica la portera o la sartén de aceite hirviendo del cocinero (con su marca roja en el suelo, donde
# caerá). Vuela por encima de todo y, al caer, deja un charco. Los de
# los zombis, si Johnny está justo donde caen, le hacen daño; el molotov suelta una llamarada que prende a los
# zombis que pilla. Como lob y updateHazards en src/game-ataques.js (y molotovLand en src/molotov.js).
extends Node2D

# El charco se carga al caer, no al principio: charco.gd usa Lanzables, y Lanzables carga este proyectil; si
# cada uno cargase al otro al empezar, según qué se cargue antes uno se queda a medias (pasaba en bano.tscn)
const CHARCO := "res://escenas/armas/charco.tscn"
const MOCO := preload("res://assets/sprites/objeto-moco.png")

# Cada tipo: cuánto tarda en caer, lo alto que sube, el daño al caer y el charco que deja
const TIPOS := {
	"veneno": {"vuelo": 0.8, "altura": 90.0, "golpe": 8, "charco": "veneno"},
	"lejia": {"vuelo": 0.9, "altura": 130.0, "golpe": 10, "charco": "lejia"},
	"acido": {"vuelo": 0.75, "altura": 110.0, "golpe": 8, "charco": "acido"},   # lo que salpica la portera con la fregona
	"molotov": {"vuelo": 0.55, "altura": 110.0, "golpe": 0, "charco": "fuego"},
	"vomito": {"vuelo": 0.45, "altura": 70.0, "golpe": 0, "charco": "vomito"},
	# la sartén del cocinero ("marca": el radio de la marca en el suelo, el del charco "hirviendo" en charco.gd)
	"sarten": {"vuelo": 0.8, "altura": 130.0, "golpe": 0, "charco": "hirviendo", "marca": 60.0},
	# el molotov del jefe de bomberos (bombero.gd): como el de Johnny pero con marca y un fuego algo más pequeño
	"molotov_jefe": {"vuelo": 0.9, "altura": 140.0, "golpe": 6, "charco": "fuego", "marca": 54.0, "escala": 0.85},
	# las probetas del científico jefe (cientifico_jefe.gd): una de ácido, una de veneno y una de aceite (resbala),
	# en curva alta y con su marca en el suelo. Se dibujan con código (probeta()), con el color de su líquido
	"probeta_acido": {"vuelo": 0.85, "altura": 170.0, "golpe": 6, "charco": "acido", "marca": 50.0, "liquido": Color("#d8ff4a")},
	"probeta_veneno": {"vuelo": 0.85, "altura": 170.0, "golpe": 6, "charco": "veneno", "marca": 50.0, "liquido": Color("#b05ad8")},
	"probeta_aceite": {"vuelo": 0.85, "altura": 170.0, "golpe": 0, "charco": "aceite", "marca": 50.0, "liquido": Color("#4fc3ff")},
}

var tipo := "veneno"
var desde := Vector2.ZERO    # dónde sale (en el suelo, debajo de la boca o de la mano)
var alto_salida := 0.0       # a qué altura sobre el suelo sale
var hasta := Vector2.ZERO    # dónde caerá
var dano_lanzar := 1.0       # molotov: Puntería
var fabricante := false      # molotov: fuego más grande y más largo
var dueno: Node2D = null     # quien lo lanza (al cocinero no le quema su aceite; y la skin del glotón le muerde)
var t := 0.0
var marca: Node2D = null     # la sartén: su marca en el suelo, por debajo de todos


func _ready() -> void:
	global_position = desde
	if TIPOS[tipo].has("marca"):
		marca = Node2D.new()
		marca.z_index = -6   # este nodo va a 5: la marca, a -1, como los charcos
		marca.draw.connect(pintar_marca)
		add_child(marca)


func _physics_process(delta: float) -> void:
	var datos: Dictionary = TIPOS[tipo]
	t += delta
	var k: float = minf(t / datos.vuelo, 1.0)
	global_position = desde.lerp(hasta, k)
	queue_redraw()
	if marca:
		marca.queue_redraw()
	if k >= 1.0:
		caer(datos)


func caer(datos: Dictionary) -> void:
	var charco: Node2D = load(CHARCO).instantiate()
	charco.tipo = datos.charco
	# el centro, en píxel entero del dibujo, para que cuadre con el resto del suelo
	charco.position = (hasta / 2.0).round() * 2.0
	charco.dueno = dueno
	if tipo == "molotov":
		charco.escala = Lanzables.FABRICANTE.radio if fabricante else 1.0
		charco.duracion = Lanzables.FABRICANTE.duracion if fabricante else 1.0
		charco.dano_lanzar = dano_lanzar
	elif tipo == "molotov_jefe":
		charco.escala = datos.escala
	get_parent().add_child(charco)
	match tipo:
		"molotov", "molotov_jefe":
			Sonido.tocar("cristal")
			Sonido.tocar("fuego")
		"lejia": Sonido.tocar("cristal")
		"sarten":
			Sonido.tocar("chof")
			Sonido.tocar("chisporroteo")
		"probeta_acido", "probeta_veneno", "probeta_aceite":
			Sonido.tocar("cristal")
			Sonido.tocar("chof")
		_: Sonido.tocar("chof")
	if tipo == "molotov" or tipo == "molotov_jefe":
		llamarada(charco.radio())
	elif tipo == "vomito" or tipo == "acido" or tipo == "sarten" or datos.has("liquido"):
		for i in 8:
			var a := randf() * TAU
			var color: Color = datos.get("liquido", Color("#e8c547") if tipo == "sarten" else Color("#c7e04a"))
			Particulas.soltar(self, hasta, Vector2(cos(a), sin(a)) * randf_range(60, 160), color, randf_range(3, 5), 0.4)
		if datos.has("liquido"):   # la probeta: también sus cristales
			for i in 4:
				var a := randf() * TAU
				Particulas.soltar(self, hasta, Vector2(cos(a) * 110.0, sin(a) * 65.0), Color("#d8f0ff"), 2, 0.3)
	var johnny := get_tree().get_first_node_in_group("jugador")
	# (la botella del molotov del jefe de bomberos son llamas: con la skin del bombero, no le hace nada)
	var ignifugo: bool = tipo == "molotov_jefe" and johnny and johnny.ignifugo()
	if datos.golpe > 0 and johnny and johnny.vivo and not ignifugo and hasta.distance_to(johnny.global_position) < charco.radio() + johnny.RADIO * 0.5:
		johnny.recibir_dano(datos.golpe, dueno)
	queue_free()


# La botella se rompe: llamarada (chispas y cristales) y daño a los zombis que pilla de lleno, que ya se prenden
func llamarada(r: float) -> void:
	Luz.destello(get_parent(), hasta, r * 3.0, 0.3, 0.8)
	for i in 18:
		var a := randf() * TAU
		var v := randf_range(60, 240)
		Particulas.soltar(self, hasta + Vector2(0, -6), Vector2(cos(a) * v, sin(a) * v * 0.6 - 40.0), Llamas.FUEGO[i % 4], randf_range(2, 4), 0.5)
	for i in 4:
		var a := randf() * TAU
		Particulas.soltar(self, hasta, Vector2(cos(a) * 120.0, sin(a) * 70.0), Color("#b9e3d0"), 2, 0.3)   # cristales
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var d: Vector2 = zombi.global_position - hasta
		if Vector2(d.x, d.y / 0.6).length() > r * 0.8 + zombi.radio or zombi == dueno:
			continue   # (al que lo tira, el jefe de bomberos, su propio molotov no le hace nada)
		if zombi.has_method("prender"):
			zombi.prender(dano_lanzar)
		if zombi.get("inmune_fuego"):
			continue   # al que el fuego no le hace nada (el jefe de bomberos), el golpe tampoco
		zombi.recibir_golpe(roundi(Lanzables.MOLOTOV.golpe * dano_lanzar), Vector2.ZERO)


func _draw() -> void:
	var datos: Dictionary = TIPOS[tipo]
	var k: float = minf(t / datos.vuelo, 1.0)
	# La sombra, en el suelo, y el proyectil, que sube y baja (la curva de una pelota: sin(k·π))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.25))
	var alto: float = alto_salida * (1.0 - k) + sin(k * PI) * datos.altura
	var donde := Vector2(0, -alto)
	match tipo:
		"veneno", "vomito", "acido":
			# el moco mira hacia donde va (sus gotas, detrás) y se estira un poco en la dirección del vuelo: hacia
			# arriba al salir, de lado en lo alto y de cabeza al caer. Su velocidad en pantalla: lo que avanza por
			# el suelo más lo que sube o baja (la derivada de la altura)
			var vel: Vector2 = (hasta - desde) / datos.vuelo + Vector2(0, (alto_salida - PI * datos.altura * cos(k * PI)) / datos.vuelo)
			draw_set_transform(donde, vel.angle() + PI / 2.0, Vector2(1.8, 2.3))
			draw_texture(MOCO, -Vector2(MOCO.get_size()) / 2.0, Color.WHITE if tipo == "veneno" else Color(1, 1, 0.45))
		"molotov", "molotov_jefe":
			botella(donde, t * 12.0)
		"sarten":
			sarten(self, donde, t * 9.0)
		"probeta_acido", "probeta_veneno", "probeta_aceite":
			probeta(self, donde, t * 11.0, datos.liquido)
		_:
			# La botella de lejía, dando vueltas (dibujada con código, como en el juego)
			draw_set_transform(donde, t * 10.0)
			var contorno := Color("#1d1b2c")
			draw_rect(Rect2(-8, -10, 16, 20), contorno)
			draw_rect(Rect2(-6, -8, 12, 16), Color("#f4f8ff"))
			draw_rect(Rect2(-4.5, -16, 9, 7), contorno)
			draw_rect(Rect2(-3, -15, 6, 5), Color("#4c9fd6"))
			draw_rect(Rect2(-6, -2, 12, 4), Color("#4c9fd6"))


# La sartén del cocinero, con su aceite dentro
static func sarten(lienzo: CanvasItem, donde: Vector2, giro: float) -> void:
	lienzo.draw_set_transform(donde, giro)
	lienzo.draw_rect(Rect2(10, -4, 20, 8), Color("#1d1b2c"))   # el mango
	lienzo.draw_rect(Rect2(12, -2, 16, 4), Color("#5a3a22"))
	lienzo.draw_circle(Vector2.ZERO, 15.0, Color("#1d1b2c"))
	lienzo.draw_circle(Vector2.ZERO, 12.0, Color("#3a3a46"))   # el hierro
	lienzo.draw_circle(Vector2.ZERO, 9.0, Color("#c98a2a"))    # el aceite
	lienzo.draw_circle(Vector2(-3, -3), 3.0, Color("#f0c060"))


# Una probeta de cristal con su tapón de corcho y el líquido dentro, dando vueltas (las del científico jefe)
static func probeta(lienzo: CanvasItem, donde: Vector2, giro: float, liquido: Color) -> void:
	lienzo.draw_set_transform(donde, giro)
	var contorno := Color("#1d1b2c")
	lienzo.draw_rect(Rect2(-6, -14, 12, 28), contorno)             # el tubo
	lienzo.draw_rect(Rect2(-4, -12, 8, 24), Color("#d8f0ff", 0.85))
	lienzo.draw_rect(Rect2(-4, 0, 8, 12), liquido)                  # el líquido, en la mitad de abajo
	lienzo.draw_rect(Rect2(-4, 0, 8, 2), liquido.lightened(0.5))
	lienzo.draw_rect(Rect2(-3, -10, 2, 8), Color(1, 1, 1, 0.6))     # el brillo del cristal
	lienzo.draw_rect(Rect2(-5, -18, 10, 5), contorno)              # el tapón
	lienzo.draw_rect(Rect2(-4, -17, 8, 3), Color("#b58a5a"))


# Dónde caerá la sartén: un anillo rojo que se va llenando
func pintar_marca() -> void:
	var k: float = minf(t / TIPOS[tipo].vuelo, 1.0)
	var r: float = TIPOS[tipo].marca
	var rojo := Color(1, 0.24, 0.35)
	marca.draw_set_transform(hasta - global_position, 0.0, Vector2(1, 0.6))
	marca.draw_circle(Vector2.ZERO, r * k, Color(rojo, 0.12 + 0.15 * k))
	marca.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(rojo, 0.5 + 0.4 * k), 3.0)


# La botella del molotov (drawMolotov del JS): cristal verde, trapo y la llama del trapo, que baila
func botella(donde: Vector2, giro: float) -> void:
	draw_set_transform(donde, giro)
	var px := func(x: float, y: float, w: float, h: float, c: String) -> void:
		draw_rect(Rect2(x * 2.0, y * 2.0, w * 2.0, h * 2.0), Color(c))
	px.call(-3, -2, 6, 7, "#472937")
	px.call(-2, -5, 4, 3, "#472937")
	px.call(-2, -1, 4, 5, "#4a7a4a")
	px.call(-2, -1, 1, 4, "#78aa60")
	px.call(1, 0, 1, 4, "#2e523a")
	px.call(-1, -4, 2, 3, "#4a7a4a")
	px.call(-1, -6, 2, 2, "#d6c4a0")
	var f := int(t * 12.0) % 2
	px.call(-1, -8 - f, 2, 2 + f, "#ff9f1c")
	px.call(0, -9 - f, 1, 1, "#ffd23f")
