# Algo que se lanza en parábola: el moco del venenoso, la botella de lejía de la portera, el cóctel molotov de
# Johnny, la bomba de aceite (arrojadiza creada del centro comercial), su vómito (mutación Gastroenteritis) o el
# ácido que salpica la portera. Vuela por encima de todo y, al caer, deja un charco. Los de
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
	"aceite": {"vuelo": 0.55, "altura": 110.0, "golpe": 0, "charco": "aceite"},
	"vomito": {"vuelo": 0.45, "altura": 70.0, "golpe": 0, "charco": "vomito"},
}

var tipo := "veneno"
var desde := Vector2.ZERO    # dónde sale (en el suelo, debajo de la boca o de la mano)
var alto_salida := 0.0       # a qué altura sobre el suelo sale
var hasta := Vector2.ZERO    # dónde caerá
var dano_lanzar := 1.0       # molotov: Puntería
var fabricante := false      # molotov: fuego más grande y más largo
var t := 0.0


func _ready() -> void:
	global_position = desde


func _physics_process(delta: float) -> void:
	var datos: Dictionary = TIPOS[tipo]
	t += delta
	var k: float = minf(t / datos.vuelo, 1.0)
	global_position = desde.lerp(hasta, k)
	queue_redraw()
	if k >= 1.0:
		caer(datos)


func caer(datos: Dictionary) -> void:
	var charco: Node2D = load(CHARCO).instantiate()
	charco.tipo = datos.charco
	# el centro, en píxel entero del dibujo, para que cuadre con el resto del suelo
	charco.position = (hasta / 2.0).round() * 2.0
	if tipo == "molotov" or tipo == "aceite":
		charco.escala = Lanzables.FABRICANTE.radio if fabricante else 1.0
		charco.duracion = Lanzables.FABRICANTE.duracion if fabricante else 1.0
		charco.dano_lanzar = dano_lanzar
	get_parent().add_child(charco)
	match tipo:
		"molotov":
			Sonido.tocar("cristal")
			Sonido.tocar("fuego")
		"lejia": Sonido.tocar("cristal")
		"aceite":
			Sonido.tocar("cristal")
			Sonido.tocar("chof")
		_: Sonido.tocar("chof")
	if tipo == "molotov":
		llamarada(charco.radio())
	elif tipo == "vomito" or tipo == "acido" or tipo == "aceite":
		for i in 8:
			var a := randf() * TAU
			Particulas.soltar(self, hasta, Vector2(cos(a), sin(a)) * randf_range(60, 160),
				Color("#e8c547") if tipo == "aceite" else Color("#c7e04a"), randf_range(3, 5), 0.4)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if datos.golpe > 0 and johnny and johnny.vivo and hasta.distance_to(johnny.global_position) < charco.radio() + johnny.RADIO * 0.5:
		johnny.recibir_dano(datos.golpe)
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
		if Vector2(d.x, d.y / 0.6).length() > r * 0.8 + zombi.radio:
			continue
		if zombi.has_method("prender"):
			zombi.prender(dano_lanzar)
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
			draw_set_transform(donde, 0.0, Vector2(2, 2))
			draw_texture(MOCO, -Vector2(MOCO.get_size()) / 2.0, Color.WHITE if tipo == "veneno" else Color(1, 1, 0.45))
		"molotov":
			botella(donde, t * 12.0)
		"aceite":
			# la botella de aceite: amarilla con el tapón verde, dando vueltas
			draw_set_transform(donde, t * 10.0)
			var contorno := Color("#1d1b2c")
			draw_rect(Rect2(-8, -10, 16, 20), contorno)
			draw_rect(Rect2(-6, -8, 12, 16), Color("#f2c94c"))
			draw_rect(Rect2(-6, -8, 3, 16), Color("#fff0a0"))
			draw_rect(Rect2(-4.5, -16, 9, 7), contorno)
			draw_rect(Rect2(-3, -15, 6, 5), Color("#5aa05a"))
			draw_rect(Rect2(-4, -2, 8, 4), Color("#f1f1e6"))
		_:
			# La botella de lejía, dando vueltas (dibujada con código, como en el juego)
			draw_set_transform(donde, t * 10.0)
			var contorno := Color("#1d1b2c")
			draw_rect(Rect2(-8, -10, 16, 20), contorno)
			draw_rect(Rect2(-6, -8, 12, 16), Color("#f4f8ff"))
			draw_rect(Rect2(-4.5, -16, 9, 7), contorno)
			draw_rect(Rect2(-3, -15, 6, 5), Color("#4c9fd6"))
			draw_rect(Rect2(-6, -2, 12, 4), Color("#4c9fd6"))


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
