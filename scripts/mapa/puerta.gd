# Una salida de un mapa: las puertas de los apartamentos, el ascensor averiado, las escaleras (la salida de incendios,
# roja, con su cartel EXIT: cartel_salida.gd) y por donde se ha llegado. Las puertas vistas de frente (en la pared de
# arriba) son dibujos de PixelLab (tools/guias_puertas.py): la de madera de los pisos, la de cristal de las tiendas y
# la de acero de la sala de mantenimiento. Lo demás se dibuja a mano, con rectángulos de colores (en múltiplos de 2
# unidades, como un píxel del dibujo).
#
# Delante tiene una zona invisible: cuando Johnny la pisa, avisa con "empujada" y la partida decide si se
# pasa al otro lado o se le dice por qué no se abre.
extends Node2D

signal empujada(indice: int)

# Las puertas de frente: 36 × 43 píxeles, o sea 72 × 86 unidades
const DIBUJO := {"piso": preload("res://assets/sprites/puerta-piso.png"),
	"tienda": preload("res://assets/sprites/puerta-tienda.png"),
	"servicio": preload("res://assets/sprites/puerta-servicio.png")}
# El número de la planta pintado en la pared junto al ascensor (de suelo a moldura): 28 × 42 píxeles, 56 × 84 unidades.
# Planta baja (0) a 3ª (la azotea no tiene ascensor)
const CARTELES := [preload("res://assets/sprites/cartel-planta-0.png"), preload("res://assets/sprites/cartel-planta-1.png"),
	preload("res://assets/sprites/cartel-planta-2.png"), preload("res://assets/sprites/cartel-planta-3.png")]
# Los mismos con la palabra de cada idioma en vez de «PLANTA» (FLOOR, ANDAR, ETAGE: tools/cartel_planta_idiomas.py); en español,
# CARTELES
const CARTELES_POR_IDIOMA := {
	"en": [preload("res://assets/sprites/cartel-planta-0-en.png"), preload("res://assets/sprites/cartel-planta-1-en.png"),
		preload("res://assets/sprites/cartel-planta-2-en.png"), preload("res://assets/sprites/cartel-planta-3-en.png")],
	"pt_BR": [preload("res://assets/sprites/cartel-planta-0-pt_BR.png"), preload("res://assets/sprites/cartel-planta-1-pt_BR.png"),
		preload("res://assets/sprites/cartel-planta-2-pt_BR.png"), preload("res://assets/sprites/cartel-planta-3-pt_BR.png")],
	"de": [preload("res://assets/sprites/cartel-planta-0-de.png"), preload("res://assets/sprites/cartel-planta-1-de.png"),
		preload("res://assets/sprites/cartel-planta-2-de.png"), preload("res://assets/sprites/cartel-planta-3-de.png")],
	"fr": [preload("res://assets/sprites/cartel-planta-0-fr.png"), preload("res://assets/sprites/cartel-planta-1-fr.png"),
		preload("res://assets/sprites/cartel-planta-2-fr.png"), preload("res://assets/sprites/cartel-planta-3-fr.png")],
}
# La salida de incendios del fondo del pasillo (las escaleras, en el muro de la derecha): una hoja de chapa roja metida en el
# hueco, vista de canto desde arriba, con su barra antipánico larga sobresaliendo hacia el pasillo y las escaleras detrás.
# 36 × 36 píxeles (72 × 72 unidades): los 4 primeros píxeles son del suelo del pasillo, por donde sobresale la barra
# (tools/puerta_salida.py, hecha a mano: a 5 píxeles de ancho PixelLab no dibuja)
const SALIDA := preload("res://assets/sprites/puerta-salida.png")
const MARCO := Color("2b1d16")
const HOJA := Color("6b4329")
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

var salida: Dictionary   # la de planta.gd: dir, tipo, cerrojo...
var indice := 0          # su número en la lista de salidas del sitio
var centro := false      # si es del centro comercial (lo pone mapa.gd): puertas de cristal en vez de madera
var cartel: Node2D = null   # las escaleras: su cartel EXIT de la pared de arriba (cartel_salida.gd, lo pone mapa.gd)
var abierta := true:     # si se puede pasar
	set(valor):
		abierta = valor
		if cartel:
			cartel.encender(valor)   # el cartel de las escaleras luce cuando se pueden usar
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
			# la de la sala de mantenimiento (la de la placa con la llave inglesa), de acero en los dos edificios; las
			# demás, la del edificio
			var dibujo: String = "servicio" if salida.get("placa", "") == "llave" else ("tienda" if centro else "piso")
			draw_texture_rect(DIBUJO[dibujo], Rect2(-36, -86, 72, 86), false)
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
			# En los laterales del pasillo: las escaleras (la salida de incendios, en el muro de la derecha) o la puerta
			# por donde se ha llegado
			if salida.tipo == "escaleras":
				draw_texture_rect(SALIDA, Rect2(-8, -36, 72, 72), false)
				return
			var x0 := -64.0 if salida.dir == "izquierda" else 0.0
			draw_rect(Rect2(x0, -36, 64, 72), MARCO)
			draw_rect(Rect2(x0, -32, 64, 64), HUECO)
			var borde := -8.0 if salida.dir == "izquierda" else 0.0   # la hoja, en el borde de dentro
			draw_rect(Rect2(borde, -32, 8, 64), HOJA)


# El ascensor averiado, de frente: más ancho que una puerta, con su marco, dos hojas de acero cerradas, la
# lucecita de encima apagada en rojo y una cinta de peligro horizontal, de lado a lado a media altura, que lo
# bloquea. Ya arreglado (al caer el jefe de la planta, ver arreglar_ascensor en partida.gd), sin la cinta y con la
# lucecita encendida en verde
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
		# la cinta, a media altura de las hojas y sin llegar al cartel de la planta (que acaba 18 a la izquierda de ellas)
		draw_rect(Rect2(x0 - 10, -34, w + 20, 2), CINTA_SOMBRA)
		cinta(x0 - 10, -44, w + 20)
	if salida.has("planta"):
		cartel_planta()


# La placa de un piso, con su esquina de arriba a la izquierda en "donde": la letra en una placa de latón (22 × 26)
# o, la de la sala de mantenimiento, una llave inglesa en una de acero (un poco más ancha)
func placa_de_piso(donde: Vector2) -> void:
	var metal: Dictionary = CHAPA if salida.placa == "llave" else LATON
	var filas: Array = LETRAS[salida.placa]
	placa(Rect2(donde, Vector2(filas[0].length() * 2 + 12, filas.size() * 2 + 12)), metal)
	letra(filas, donde + Vector2(6, 6), 2, metal.letra)


# El cartel de la planta, junto al ascensor, a su izquierda (a 10 unidades del marco): el número pintado con plantilla
# en la pared, con «PLANTA» pequeño encima (en otro idioma, su palabra: CARTELES_POR_IDIOMA), de suelo a moldura (la planta baja, el 0,
# como en los botones de los ascensores). Las pinturas son de PixelLab (tools/guias_cartel.py)
func cartel_planta() -> void:
	var planta: int = salida.planta
	var carteles: Array = CARTELES_POR_IDIOMA.get(Idioma.actual, CARTELES)
	if planta >= 0 and planta < carteles.size():
		draw_texture_rect(carteles[planta], Rect2(-114, -84, 56, 84), false)


# Una placa: el borde oscuro y el metal, con su brillo arriba y a la izquierda y su sombra abajo y a la derecha
func placa(r: Rect2, metal: Dictionary) -> void:
	draw_rect(r, metal.filo)
	var dentro := r.grow(-2)
	draw_rect(dentro, metal.medio)
	draw_rect(Rect2(dentro.position, Vector2(dentro.size.x, 2)), metal.luz)
	draw_rect(Rect2(dentro.position, Vector2(2, dentro.size.y)), metal.luz)
	draw_rect(Rect2(dentro.position.x, dentro.end.y - 2, dentro.size.x, 2), metal.sombra)
	draw_rect(Rect2(dentro.end.x - 2, dentro.position.y + 2, 2, dentro.size.y - 2), metal.sombra)


# Una letra de LETRAS, con su esquina de arriba a la izquierda en "donde"; "px", lo que mide cada píxel
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
