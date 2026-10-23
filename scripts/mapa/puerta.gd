# Una salida de un mapa: las puertas de los apartamentos, el ascensor averiado, las escaleras y por donde se
# ha llegado. Se dibuja a mano, con rectángulos de colores (en múltiplos de 2 unidades, como un píxel del
# dibujo).
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
# El ascensor (elevatorFront de src/render.js): acero, su marco y la cinta de peligro amarilla y negra
const ACERO := {"luz": Color("76807c"), "medio": Color("566060"), "sombra": Color("3d4545"), "filo": Color("1e2324")}
const OSCURO := Color("0c0a0e")
const CINTA := Color("c9a227")
const CINTA_RAYA := Color("1a1712")
const CINTA_SOMBRA := Color(0, 0, 0, 0.35)   # la sombrita que deja la cinta pegada, un píxel por debajo
# Las placas del pasillo, como en un edificio de verdad: la letra de cada piso junto a su puerta (de latón; la de la
# sala de mantenimiento, de acero y con una llave inglesa) y, a la izquierda del ascensor, el número grande de la planta
const LATON := {"luz": Color("e8c868"), "medio": Color("b8923a"), "sombra": Color("7a5a20"), "filo": Color("2e2010"),
	"letra": Color("2b1d10")}
const CHAPA := {"luz": Color("aab2ae"), "medio": Color("86908c"), "sombra": Color("565f5d"), "filo": Color("1e2324"),
	"letra": Color("15191a")}
# Las letras, dibujadas a mano: 5 × 7 píxeles ("X" = píxel)
const LETRAS := {
	"A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
	"B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
	"C": [".XXX.", "X...X", "X....", "X....", "X....", "X...X", ".XXX."],
	"D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
	"0": [".XXX.", "X...X", "X..XX", "X.X.X", "XX..X", "X...X", ".XXX."],
	"1": ["..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
	"2": [".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX"],
	"3": ["XXXXX", "...X.", "..X..", "...X.", "....X", "X...X", ".XXX."],
	"4": ["...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "...X."],
	"5": ["XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX."],
	"6": ["..XX.", ".X...", "X....", "XXXX.", "X...X", "X...X", ".XXX."],
	"7": ["XXXXX", "....X", "...X.", "..X..", ".X...", ".X...", ".X..."],
	"8": [".XXX.", "X...X", "X...X", ".XXX.", "X...X", "X...X", ".XXX."],
	"9": [".XXX.", "X...X", "X...X", ".XXXX", "....X", "...X.", ".XX.."],
	"llave": ["....X.X", "....XXX", "...XXX.", "..XX...", ".XX....", "XX.....", "X......"],   # la llave inglesa (7 × 7)
}
# y las de "PLANTA", más pequeñas: 3 × 5
const LETRITAS := {
	"P": ["XXX", "X.X", "XXX", "X..", "X.."],
	"L": ["X..", "X..", "X..", "X..", "XXX"],
	"A": ["XXX", "X.X", "XXX", "X.X", "X.X"],
	"N": ["X.X", "XXX", "XXX", "XXX", "X.X"],
	"T": ["XXX", ".X.", ".X.", ".X.", ".X."],
}

var salida: Dictionary   # la de planta.gd: dir, tipo, cerrojo...
var indice := 0          # su número en la lista de salidas del sitio
var abierta := true:     # si se puede pasar
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
	# (sin nada escrito encima: adónde lleva lo dicen el mapa de la esquina, las placas de los pisos, el cartel de la
	# planta junto al ascensor y los letreros de neón de las tiendas)


# Dónde aparece Johnny al llegar por esta puerta (un poco hacia dentro)
func llegada() -> Vector2:
	return position + {"arriba": Vector2(0, 60), "abajo": Vector2(0, -60), "izquierda": Vector2(60, 0),
		"derecha": Vector2(-60, 0)}[salida.dir]


func _draw() -> void:
	match salida.dir:
		"arriba":
			# De frente, sobre la cara del muro (que sube 96 desde aquí)
			if salida.tipo == "ascensor":
				ascensor()
				return
			draw_rect(Rect2(-36, -86, 72, 86), MARCO)
			draw_rect(Rect2(-32, -80, 64, 80), HOJA)
			for x in [-28, 4]:
				draw_rect(Rect2(x, -74, 24, 30), PANEL)
				draw_rect(Rect2(x, -38, 24, 32), PANEL)
			draw_rect(Rect2(-2, -80, 4, 80), MARCO)
			draw_rect(Rect2(-8, -44, 4, 4), POMO)
			draw_rect(Rect2(4, -44, 4, 4), POMO)
			if salida.has("placa"):
				placa_de_piso(Vector2(42, -78))   # en la pared, a la derecha del marco y a la altura de los ojos
		"abajo":
			# Vista desde arriba: el hueco en el muro de abajo, con el marco y la hoja
			draw_rect(Rect2(-36, 0, 72, 64), MARCO)
			draw_rect(Rect2(-32, 0, 64, 64), HUECO)
			draw_rect(Rect2(-32, 0, 64, 8), HOJA)
			if salida.has("placa"):
				placa_de_piso(Vector2(42, 6))   # encima del muro, a la derecha del hueco
		_:
			# En los laterales del pasillo: las escaleras (peldaños) o la puerta por donde se ha llegado
			var x0 := -64.0 if salida.dir == "izquierda" else 0.0
			if salida.get("incendios", false):
				incendios(x0)
				return
			draw_rect(Rect2(x0, -36, 64, 72), MARCO)
			if salida.tipo == "escaleras":
				for i in 8:
					draw_rect(Rect2(x0 + i * 8, -32, 8, 64), Color("6d6d72") if i % 2 else Color("57575c"))
			else:
				draw_rect(Rect2(x0, -32, 64, 64), HUECO)
			var borde := -8.0 if salida.dir == "izquierda" else 0.0   # la hoja, en el borde de dentro
			draw_rect(Rect2(borde, -32, 8, 64), HOJA)


# La escalera de incendios de la azotea, en el murete: los peldaños de rejilla de metal, que bajan hacia fuera, y la
# barandilla roja a los dos lados. Mientras esté cerrada (hasta que cae el jefe), con una cinta de peligro cruzada
func incendios(x0: float) -> void:
	draw_rect(Rect2(x0, -36, 64, 72), OSCURO)
	for i in 8:
		var x := x0 + (i * 8.0 if salida.dir == "derecha" else 56.0 - i * 8.0)
		draw_rect(Rect2(x, -30, 6, 60), Color("7a7e84") if i % 2 else Color("62666c"))
		draw_rect(Rect2(x, -30, 6, 2), Color("9a9ea4"))
		for y in range(-26, 30, 8):   # la rejilla
			draw_rect(Rect2(x, y, 6, 2), Color("3a3c40"))
	for y in [-36.0, 32.0]:
		draw_rect(Rect2(x0, y, 64, 4), Color("a8342a"))
		draw_rect(Rect2(x0, y, 64, 2), Color("d0503e"))
	if not abierta:
		draw_set_transform(Vector2(x0 + (20.0 if salida.dir == "derecha" else 44.0), 0), PI / 2.0)
		cinta(-42, -5, 84)
		draw_set_transform(Vector2.ZERO)


# El ascensor averiado, de frente: más ancho que una puerta, con su marco, dos hojas de acero cerradas, la
# lucecita de encima apagada en rojo y tres cintas de peligro que lo bloquean: dos en aspa, de esquina a esquina, y
# una horizontal por encima, algo más baja que el cruce (como pegadas a mano, una tras otra). Ya arreglado (al caer
# el jefe de la planta, ver arreglar_ascensor en partida.gd), sin las cintas y con la lucecita encendida en verde
func ascensor() -> void:
	var w := 80.0
	var alto := 80.0
	var x0 := -w / 2.0
	var arriba := -alto
	# el marco
	draw_rect(Rect2(x0 - 8, arriba - 8, w + 16, alto + 8), ACERO.filo)
	draw_rect(Rect2(x0 - 6, arriba - 6, w + 12, alto + 6), ACERO.medio)
	draw_rect(Rect2(x0 - 6, arriba - 6, w + 12, 2), ACERO.luz)
	draw_rect(Rect2(x0 - 6, arriba - 4, 2, alto + 4), ACERO.luz)
	draw_rect(Rect2(x0 + w + 4, arriba - 4, 2, alto + 4), ACERO.sombra)
	draw_rect(Rect2(x0, arriba, w, alto), OSCURO)
	# las dos hojas cerradas
	draw_rect(Rect2(x0, arriba, w, alto), ACERO.medio)
	draw_rect(Rect2(x0, arriba, w, 2), ACERO.luz)
	draw_rect(Rect2(-1, arriba, 2, alto), ACERO.filo)
	draw_rect(Rect2(x0, -4, w, 4), ACERO.sombra)
	# la lucecita de encima: apagada en rojo o, ya arreglado, encendida en verde
	draw_rect(Rect2(-6, arriba - 6, 12, 4), ACERO.filo)
	draw_rect(Rect2(-4, arriba - 6, 8, 2), Color("5fd35a") if abierta else Color("6a1c1c"))
	if not abierta:
		# las puntas, pegadas al marco (la horizontal, sin llegar al cartel de la planta, que acaba 18 a la izquierda
		# de las hojas)
		cinta_cruzada(Vector2(x0 - 2, arriba - 6), Vector2(-x0, -4))
		cinta_cruzada(Vector2(-x0 + 2, arriba - 6), Vector2(x0, -4))
		draw_rect(Rect2(x0 - 10, -20, w + 20, 2), CINTA_SOMBRA)
		cinta(x0 - 10, -30, w + 20)
	if salida.has("planta"):
		cartel_planta(Vector2(x0 - 76, -84))


# La placa de un piso, con su esquina de arriba a la izquierda en "donde": la letra en una placa de latón (22 × 26)
# o, la de la sala de mantenimiento, una llave inglesa en una de acero (un poco más ancha)
func placa_de_piso(donde: Vector2) -> void:
	var metal: Dictionary = CHAPA if salida.placa == "llave" else LATON
	var filas: Array = LETRAS[salida.placa]
	placa(Rect2(donde, Vector2(filas[0].length() * 2 + 12, filas.size() * 2 + 12)), metal)
	letra(filas, donde + Vector2(6, 6), 2, metal.letra)


# El cartel de la planta, junto al ascensor: una placa de acero (58 × 58) con "PLANTA" en pequeño y debajo el número
# en grande (la planta baja, el 0, como en los botones de los ascensores)
func cartel_planta(donde: Vector2) -> void:
	placa(Rect2(donde, Vector2(58, 58)), CHAPA)
	var x := donde.x + 6
	for c in "PLANTA":
		letra(LETRITAS[c], Vector2(x, donde.y + 8), 2, CHAPA.letra)
		x += 8
	letra(LETRAS[str(salida.planta)], donde + Vector2(19, 24), 4, CHAPA.letra)


# Una placa: el borde oscuro y el metal, con su brillo arriba y a la izquierda y su sombra abajo y a la derecha
func placa(r: Rect2, metal: Dictionary) -> void:
	draw_rect(r, metal.filo)
	var dentro := r.grow(-2)
	draw_rect(dentro, metal.medio)
	draw_rect(Rect2(dentro.position, Vector2(dentro.size.x, 2)), metal.luz)
	draw_rect(Rect2(dentro.position, Vector2(2, dentro.size.y)), metal.luz)
	draw_rect(Rect2(dentro.position.x, dentro.end.y - 2, dentro.size.x, 2), metal.sombra)
	draw_rect(Rect2(dentro.end.x - 2, dentro.position.y + 2, 2, dentro.size.y - 2), metal.sombra)


# Una letra de LETRAS o de LETRITAS, con su esquina de arriba a la izquierda en "donde"; "px", lo que mide cada píxel
func letra(filas: Array, donde: Vector2, px: float, color: Color) -> void:
	for f in filas.size():
		for c in filas[f].length():
			if filas[f][c] == "X":
				draw_rect(Rect2(donde + Vector2(c, f) * px, Vector2(px, px)), color)


# Cinta de peligro: franja amarilla con rayas negras en diagonal, hecha a escalones de píxel
func cinta(x: float, y: float, largo: float) -> void:
	draw_rect(Rect2(x, y, largo, 10), CINTA)
	for sx in range(0, int(largo), 12):
		for j in 5:
			var px := sx + j * 2
			if px + 4 <= largo:
				draw_rect(Rect2(x + px, y + 8 - j * 2, 4, 2), CINTA_RAYA)


# Cinta de peligro en diagonal, con su línea del medio de "desde" a "hasta" y su sombrita debajo. Se pinta píxel a
# píxel (de 2 en 2 unidades) para que tenga el mismo tamaño de píxel que todo lo demás: girada con
# draw_set_transform, como la de incendios, saldría con escalones más finos. Las rayas negras van en horizontal, que
# en una cinta inclinada quedan en diagonal sobre la franja, como las de cinta()
func cinta_cruzada(desde: Vector2, hasta: Vector2) -> void:
	var largo := desde.distance_to(hasta)
	var dir := (hasta - desde) / largo
	var normal := Vector2(-dir.y, dir.x)
	var caja := Rect2(desde, Vector2.ZERO).expand(hasta).grow(8)
	for sombra in [true, false]:   # primero la sombra, y encima la cinta
		for x in range(int(caja.position.x), int(caja.end.x), 2):
			for y in range(int(caja.position.y), int(caja.end.y), 2):
				if y >= 0:
					continue   # por debajo del suelo, nada
				var d := Vector2(x + 1, y + 1 - (2 if sombra else 0)) - desde   # el centro del píxel
				var a_lo_largo := d.dot(dir)
				if a_lo_largo < 0 or a_lo_largo > largo or absf(d.dot(normal)) > 5:
					continue
				var color := CINTA_SOMBRA if sombra else (CINTA_RAYA if posmod(y, 12) < 4 else CINTA)
				draw_rect(Rect2(x, y, 2, 2), color)
