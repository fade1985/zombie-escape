# Una salida de un mapa: las puertas de los apartamentos, el ascensor averiado, las escaleras (la salida de incendios,
# roja, con su cartel EXIT: cartel_salida.gd) y por donde se ha llegado. Las puertas vistas de frente (en la pared de
# arriba) son dibujos de PixelLab (tools/guias_puertas.py): la de madera de los pisos, la de cristal de las tiendas y
# la de acero de la sala de mantenimiento. Las de la pared de abajo, de tools/puerta_abajo.py. Lo demás se dibuja a mano, con
# rectángulos de colores (en múltiplos de 2 unidades, como un píxel del dibujo).
#
# Delante tiene una zona invisible: cuando Johnny la pisa, avisa con "empujada" y la partida decide si se
# pasa al otro lado o se le dice por qué no se abre.
extends Node2D

signal empujada(indice: int)

# Las puertas de frente: 36 × 43 píxeles, o sea 72 × 86 unidades
const DIBUJO := {"tienda": preload("res://assets/sprites/puerta-tienda.png"),
	"servicio": preload("res://assets/sprites/puerta-servicio.png")}
# La de los pisos, sucia y con sangre (tools/puertas_sucias.py): tres dibujos, uno al lado de otro, para que no sean todas iguales
const PISO := preload("res://assets/sprites/puerta-piso-sucia.png")
const PISO_DIBUJO := Vector2(36, 43)
# Las de la pared de abajo, que se ve por detrás: el hueco en el muro, con su marco, y la hoja desde arriba, un tablón con su pomo
# (tools/puerta_abajo.py). 36 × 32 píxeles, 72 × 64 unidades. Cuatro, una al lado de otra: madera sucia, madera limpia (ver "limpia"),
# cristal y aluminio (el centro comercial) y chapa gris (la de la sala de mantenimiento, ver "metal")
const ABAJO := preload("res://assets/sprites/puerta-abajo.png")
const ABAJO_DIBUJO := Vector2(36, 32)
# la de chapa gris, con la hoja de la puerta metálica del despacho al taller (tools/puerta_abajo_metal.py): la que se usa de verdad
const ABAJO_METAL := preload("res://assets/sprites/puerta-abajo-metal.png")
# la misma con la hoja en gris marengo metalizado (tools/puerta_abajo_metal.py): la puerta de la calle del portal de los Apartamentos
const ABAJO_MARENGO := preload("res://assets/sprites/puerta-abajo-marengo.png")
# El número de la planta pintado en la pared junto al ascensor (de suelo a moldura): 28 × 42 píxeles, 56 × 84 unidades.
# Planta baja (0) a 3ª (la azotea no tiene ascensor)
const CARTELES := [preload("res://assets/sprites/cartel-planta-0.png"), preload("res://assets/sprites/cartel-planta-1.png"),
	preload("res://assets/sprites/cartel-planta-2.png"), preload("res://assets/sprites/cartel-planta-3.png")]
# Los mismos con la palabra de cada idioma en vez de «PLANTA» (FLOOR, ANDAR, ETAGE: tools/cartel_planta_idiomas.py); en español,
# CARTELES. En inglés, ruso y chino la planta de la calle ya es la 1ª (Planta.CALLE_ES_LA_PRIMERA): sus carteles van del 1 al 4
const CARTELES_POR_IDIOMA := {
	"en": [preload("res://assets/sprites/cartel-planta-0-en.png"), preload("res://assets/sprites/cartel-planta-1-en.png"),
		preload("res://assets/sprites/cartel-planta-2-en.png"), preload("res://assets/sprites/cartel-planta-3-en.png")],
	"pt_BR": [preload("res://assets/sprites/cartel-planta-0-pt_BR.png"), preload("res://assets/sprites/cartel-planta-1-pt_BR.png"),
		preload("res://assets/sprites/cartel-planta-2-pt_BR.png"), preload("res://assets/sprites/cartel-planta-3-pt_BR.png")],
	"de": [preload("res://assets/sprites/cartel-planta-0-de.png"), preload("res://assets/sprites/cartel-planta-1-de.png"),
		preload("res://assets/sprites/cartel-planta-2-de.png"), preload("res://assets/sprites/cartel-planta-3-de.png")],
	"fr": [preload("res://assets/sprites/cartel-planta-0-fr.png"), preload("res://assets/sprites/cartel-planta-1-fr.png"),
		preload("res://assets/sprites/cartel-planta-2-fr.png"), preload("res://assets/sprites/cartel-planta-3-fr.png")],
	"ru": [preload("res://assets/sprites/cartel-planta-0-ru.png"), preload("res://assets/sprites/cartel-planta-1-ru.png"),
		preload("res://assets/sprites/cartel-planta-2-ru.png"), preload("res://assets/sprites/cartel-planta-3-ru.png")],
	"zh_CN": [preload("res://assets/sprites/cartel-planta-0-zh_CN.png"), preload("res://assets/sprites/cartel-planta-1-zh_CN.png"),
		preload("res://assets/sprites/cartel-planta-2-zh_CN.png"), preload("res://assets/sprites/cartel-planta-3-zh_CN.png")],
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
# Las placas del pasillo, como en un edificio de verdad: la letra de cada piso junto a su puerta, de latón y rota, torcida en
# su sitio en la pared de arriba y arrancada y tirada en el suelo en la de abajo (tools/placas_rotas.py: A, B, C y D, una al lado de
# otra; "dibujo", lo que mide cada una); la de la sala de mantenimiento, de acero y entera, con una llave inglesa; y, a la izquierda del
# ascensor, el número grande de la planta
const PLACA_PARED := {"hoja": preload("res://assets/sprites/placa-rota-pared.png"), "dibujo": Vector2(16, 17)}
const PLACA_SUELO := {"hoja": preload("res://assets/sprites/placa-rota-suelo.png"), "dibujo": Vector2(26, 26)}
# El cartel de «MANTENIMIENTO», a la derecha de su puerta: chapa esmaltada azul y vieja, del tamaño del de TRASTEROS
# (cartel_trasteros.gd: 30 de alto y la letra a 16, en una línea). La placa, de una imagen de GPT sin sus letras
# (tools/cartel_mantenimiento.py, 64 × 15 píxeles): se estira por en medio con lo que mida el texto, ya traducido
# ("Mantenimiento", el nombre de la sala, en mayúsculas). MANT_PUNTA, lo que mide cada punta (con su tornillo), que no se estira
const CARTEL_MANT_LISO := preload("res://assets/sprites/cartel-mantenimiento-liso.png")
const MANT_PUNTA := 9
const MANT_ALTO := 30.0
const PLACA_AZUL := 22.0   # lo alto de la placa azul pequeña con la letra de los pisos A y B
const MANT_MARGEN := 14.0   # del borde a las letras, a cada lado (justo pasado el tornillo)
static var mant_fuente: FontVariation
const CARTEL_LETRA := Color("e9dfc6")   # el blanco roto de las letras de GPT
const CHAPA := {"luz": Color("aab2ae"), "medio": Color("86908c"), "sombra": Color("565f5d"), "filo": Color("1e2324"),
	"letra": Color("15191a")}
# Las letras, dibujadas a mano: 5 × 7 píxeles ("X" = píxel)
const LETRAS := {
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
var limpia := false      # si es de una zona segura (lo pone mapa.gd: ZONAS_SEGURAS): sin sangre
var metal := false       # si es de chapa gris como la de fuera (lo pone mapa.gd): las de la sala de mantenimiento y la de las viviendas a ella
var marengo := false     # con la hoja gris marengo (lo pone mapa.gd): la de la calle del portal de los Apartamentos
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
			if dibujo == "piso":
				var modelo: int = {"A": 0, "B": 1}.get(salida.get("placa", ""), 2)
				draw_texture_rect_region(PISO, Rect2(-36, -86, 72, 86), Rect2(Vector2(modelo * PISO_DIBUJO.x, 0), PISO_DIBUJO))
			else:
				draw_texture_rect(DIBUJO[dibujo], Rect2(-36, -86, 72, 86), false)
			if dibujo == "servicio":
				cartel_mantenimiento(Vector2(46, -64))   # a la derecha del marco, a la altura del de TRASTEROS
			elif salida.get("placa", "") == "llave":
				placa_de_piso(Vector2(42, -78), PLACA_PARED, Vector2(38, -80))
			elif salida.has("placa"):
				# la letra del piso en una placa azul pequeña como la de la planta (la del ascensor), a la derecha del marco y
				# a la altura de los ojos (antes, una de latón rota y torcida: PLACA_PARED)
				cartel_azul(salida.placa, Vector2(42, -64), PLACA_AZUL)
		"abajo":
			# Vista desde arriba: el hueco en el muro de abajo, con el marco y la hoja
			if metal:
				draw_texture_rect(ABAJO_METAL, Rect2(-36, 0, 72, 64), false)
			else:
				var modelo := 2 if centro else (1 if limpia else 0)
				draw_texture_rect_region(ABAJO, Rect2(-36, 0, 72, 64), Rect2(Vector2(modelo * ABAJO_DIBUJO.x, 0), ABAJO_DIBUJO))
			if salida.get("placa", "") == "llave":
				# la de acero, encima del muro, a la derecha del hueco (las de latón tiradas en el suelo de los pisos C y D, PLACA_SUELO,
				# ya no salen: esos pisos se quedan sin placa)
				placa_de_piso(Vector2(42, 6), PLACA_SUELO, Vector2(34, -56) if salida.placa == "C" else Vector2(-88, -60))
		_:
			# En los laterales del pasillo: las escaleras (la salida de incendios, en el muro de la derecha) o la puerta
			# por donde se ha llegado
			if salida.tipo == "escaleras":
				draw_texture_rect(SALIDA, Rect2(-8, -36, 72, 72), false)
				return
			if metal:
				# la de chapa gris de la pared de abajo, girada un cuarto de vuelta para que la hoja quede del lado de dentro
				# (en la de la derecha, el de arriba del dibujo va a la izquierda; en la de la izquierda, a la derecha)
				# (y en la de la derecha, dada la vuelta: si no, el pomo quedaría arriba y no abajo, como en la de la izquierda)
				if salida.dir == "derecha":
					draw_set_transform(Vector2.ZERO, -PI / 2, Vector2(-1, 1))
				else:
					draw_set_transform(Vector2.ZERO, PI / 2)
				draw_texture_rect(ABAJO_MARENGO if marengo else ABAJO_METAL, Rect2(-36, 0, 72, 64), false)
				draw_set_transform(Vector2.ZERO)
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
	if not centro and not salida.has("planta_torre"):
		ascensor_portal()
		return
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


# El de los Apartamentos, de GPT (tools/ascensor_gpt.py): acero sucio y arañado, de 41 × 46 píxeles (82 × 92 unidades), con
# el indicador negro de encima, donde se pinta la lucecita, y la cinta amarilla y negra (un trozo de 48 × 6 que se repite)
# de lado a lado a media altura; ya arreglado, sin la cinta y con la lucecita en verde
const ASCENSOR := preload("res://assets/sprites/ascensor.png")
const CINTA_GPT := preload("res://assets/sprites/cinta.png")
func ascensor_portal() -> void:
	draw_texture_rect(ASCENSOR, Rect2(-41, -92, 82, 92), false)
	# la lucecita, en medio del indicador (píxeles 17 a 23 y 1 a 3 del dibujo)
	draw_rect(Rect2(-4, -88, 8, 2), Color("5fd35a") if abierta else Color("8a2020"))
	if not abierta:
		var x := -51.0
		draw_rect(Rect2(x, -34, 102, 2), CINTA_SOMBRA)
		while x < 51.0:
			var largo := minf(96.0, 51.0 - x)
			draw_texture_rect_region(CINTA_GPT, Rect2(x, -46, largo, 12), Rect2(0, 0, largo / 2.0, 6))
			x += largo
	if salida.get("planta", -1) >= 0:
		# a su derecha, la placa azul de la planta, como la de MANTENIMIENTO: «PLANTA 0» (en inglés, ruso y chino la de la
		# calle ya es la 1ª: Planta.CALLE_ES_LA_PRIMERA). Antes, el número grande pintado a la izquierda (cartel_planta)
		var num: int = salida.planta + (1 if Idioma.actual in Planta.CALLE_ES_LA_PRIMERA else 0)
		# (en español, la de la calle es «PLANTA BAJA», como en el nombre de la planta; en los demás idiomas, con su número)
		var texto: String = "PLANTA BAJA" if Idioma.actual == "es" and num == 0 else (Idioma.t("Planta %d") % num).to_upper()   # no-tr (solo en español)
		cartel_azul(texto, Vector2(51, -64))


# El cartel de la sala de mantenimiento: "en", el medio de su lado izquierdo. La placa, con las puntas a su tamaño y lo de
# en medio estirado, y encima el texto, con su sombra
func cartel_mantenimiento(en: Vector2) -> void:
	cartel_azul(Idioma.t("Mantenimiento").to_upper(), en)


# La placa azul esmaltada (la de MANTENIMIENTO) con "texto", del largo que pida: "en", el medio de su lado izquierdo.
# "alto", lo alto de la placa (las puntas, con sus tornillos, y el margen, a su escala; la letra, siempre a 16)
func cartel_azul(texto: String, en: Vector2, alto := MANT_ALTO) -> void:
	var escala := alto / MANT_ALTO
	var margen := roundf(MANT_MARGEN * escala / 2.0) * 2.0
	var letra := 16
	if not mant_fuente:   # la letra de siempre, con las letras algo más juntas (el cartel, más corto)
		mant_fuente = FontVariation.new()
		mant_fuente.base_font = Tema.FUENTE
		mant_fuente.spacing_glyph = -1
	var letras := ceilf(mant_fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, letra).x / 2.0) * 2.0
	var r := Rect2(en.x, en.y - alto / 2.0, letras + margen * 2.0, alto)
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))   # su sombra en la pared, como el de TRASTEROS
	var tam := CARTEL_MANT_LISO.get_size()
	var punta := roundf(MANT_PUNTA * 2.0 * escala / 2.0) * 2.0
	draw_texture_rect_region(CARTEL_MANT_LISO, Rect2(r.position, Vector2(punta, r.size.y)), Rect2(0, 0, MANT_PUNTA, tam.y))
	draw_texture_rect_region(CARTEL_MANT_LISO, Rect2(r.position.x + punta, r.position.y, r.size.x - punta * 2.0, r.size.y),
		Rect2(MANT_PUNTA, 0, tam.x - MANT_PUNTA * 2, tam.y))
	draw_texture_rect_region(CARTEL_MANT_LISO, Rect2(r.end.x - punta, r.position.y, punta, r.size.y),
		Rect2(tam.x - MANT_PUNTA, 0, MANT_PUNTA, tam.y))
	var donde := Vector2(r.position.x + margen, r.position.y + roundf(alto / 2.0 + 6.0))
	draw_string(mant_fuente, donde + Vector2(2, 2), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, letra, Color(0, 0, 0, 0.35))
	draw_string(mant_fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, letra, CARTEL_LETRA)


# La placa de una puerta. La de la sala de mantenimiento, con su esquina de arriba a la izquierda en "acero": una llave inglesa en
# una placa de acero. La de un piso, en "laton", la que le toque de la hoja "rota"
func placa_de_piso(acero: Vector2, rota: Dictionary, laton: Vector2) -> void:
	if salida.placa == "llave":
		var filas: Array = LETRAS.llave
		placa(Rect2(acero, Vector2(filas[0].length() * 2 + 12, filas.size() * 2 + 12)), CHAPA)
		letra(filas, acero + Vector2(6, 6), 2, CHAPA.letra)
		return
	var tam: Vector2 = rota.dibujo
	draw_texture_rect_region(rota.hoja, Rect2(laton, tam * 2), Rect2("ABCD".find(salida.placa) * tam.x, 0, tam.x, tam.y))   # no-tr (las letras de las placas, para buscar su dibujo)


# El cartel de la planta, junto al ascensor, a su izquierda (a 10 unidades del marco): el número pintado con plantilla
# en la pared, con «PLANTA» pequeño encima (en otro idioma, su palabra: CARTELES_POR_IDIOMA), de suelo a moldura (la planta baja, el 0,
# como en los botones de los ascensores). Las pinturas son de PixelLab (tools/guias_cartel.py)
func cartel_planta() -> void:
	if salida.has("planta_torre"):
		cartel_torre(salida.planta_torre)
		return
	var planta: int = salida.planta
	var carteles: Array = CARTELES_POR_IDIOMA.get(Idioma.actual, CARTELES)
	if planta >= 0 and planta < carteles.size():
		draw_texture_rect(carteles[planta], Rect2(-114, -84, 56, 84), false)


# El cartel de Torre Velaria (0, 10, 20, 30 o 40: el ascensor solo para cada diez plantas), en el mismo sitio que los demás: el
# número pintado con plantilla en una placa clara, hecho con código (cada píxel del dibujo, 8 unidades)
const CIFRAS := {"0": ["XXX", "X.X", "X.X", "X.X", "XXX"], "1": [".X.", "XX.", ".X.", ".X.", "XXX"],
	"2": ["XXX", "..X", "XXX", "X..", "XXX"], "3": ["XXX", "..X", "XXX", "..X", "XXX"], "4": ["X.X", "X.X", "XXX", "..X", "..X"]}
const PINTURA := Color("1f2430")        # los números, pintados en oscuro
const PLACA_TORRE := Color("c9cdd3")    # la placa clara de detrás (el cristal esmerilado y la piedra son casi de su color)
func cartel_torre(numero: int) -> void:
	var texto := str(numero)
	var px := 8.0
	var ancho := texto.length() * 3 * px + (texto.length() - 1) * px
	var x := -86.0 - ancho / 2.0   # centrado en el sitio del cartel (de -114 a -58)
	var y := -56.0
	draw_rect(Rect2(-114, -80, 56, 68), PINTURA)
	draw_rect(Rect2(-112, -78, 52, 64), PLACA_TORRE)
	for ch in texto:
		var filas: Array = CIFRAS[ch]
		for f in 5:
			for c in 3:
				if filas[f][c] == "X":
					draw_rect(Rect2(x + c * px, y + f * px, px, px), PINTURA)
		x += 4 * px


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
