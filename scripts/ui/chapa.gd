# La chapa oscura de los programas del ordenador que se dibujan a mano (el árbol de talentos, arbol_talentos.gd, y la
# tienda de armas, tienda_armas.gd): sus colores, el marco con sus remaches y el marcador de lo ahorrado, como el de
# una caja registradora. Son funciones sueltas: cada programa las llama desde su _draw, pasándose a sí mismo
extends RefCounted

const BORDE := Color("#14161a")      # el marco de la chapa
const CHAPA := Color("#22252b")
const REMACHE := Color("#4a4f58")
const APAGADO := Color("#3c4048")    # las rayas y los bordes de lo bloqueado
const NEGRO := Color("#1a1c20")      # el relleno de lo bloqueado
const TEXTO := Color("#d8d0b8")
const TEXTO_SUAVE := Color("#8a8f98")
const AMARILLO := Color("#ffe066")   # lo ahorrado y los cuadraditos llenos
const VERDE := Color("#b0d98c")      # el mutágeno: el verde de la piel de los durmientes, un poco más vivo para que se lea
# El símbolo del mutágeno en su marcador, en lugar del «$»: una doble hélice de ADN, a cuadraditos de PIXEL_ADN (cada
# fila, de arriba abajo; «#», lleno). Las dos tiras se cruzan en medio y entre ellas van los peldaños
const ADN := ["#.....#", "#.###.#", "#.....#", "#.###.#", ".#...#.", "..#.#..", "...#...", "..#.#..", ".#...#.", "#.###.#",
	"#.....#", "#.###.#", "#.....#"]
const PIXEL_ADN := 2.0
const CIFRAS := 4        # las casillas de los marcadores fijos (los del inventario): hasta 9999...
const MAXIMO := 10000    # ...y de aquí en adelante, «MAX»
const ARRIBA := 44                   # lo alto de la franja de lo ahorrado
# Las cifras de los marcadores, como las de un reloj digital (lo pidió el dueño, con un dibujo, el 15 nov; antes, las de
# la letra): siete rayas de 3 de grueso con las puntas en pico y un hueco entre ellas. Cada cifra enciende las suyas
# (ENCENDIDAS) y las demás se quedan apagadas, que se ven un poco; en las casillas vacías de los marcadores fijos, todas
# apagadas (un «8» apagado). Del tamaño de las cifras de la letra a 32 (CIFRA_TAM: 16 × 19), a cuadraditos: cada raya,
# por su letra (las de siempre de los relojes: a arriba, b y c a la derecha, d abajo, e y f a la izquierda, g en medio),
# sus trozos [x, y, ancho, alto]
const CIFRA_TAM := Vector2(16, 19)
const RAYAS := {
	"a": [[4, 0, 8, 1], [3, 1, 10, 1], [4, 2, 8, 1]],
	"g": [[4, 8, 8, 1], [3, 9, 10, 1], [4, 10, 8, 1]],
	"d": [[4, 16, 8, 1], [3, 17, 10, 1], [4, 18, 8, 1]],
	"f": [[1, 2, 1, 7], [0, 3, 1, 5], [2, 3, 1, 5]],
	"b": [[14, 2, 1, 7], [13, 3, 1, 5], [15, 3, 1, 5]],
	"e": [[1, 10, 1, 7], [0, 11, 1, 5], [2, 11, 1, 5]],
	"c": [[14, 10, 1, 7], [13, 11, 1, 5], [15, 11, 1, 5]],
}
const ENCENDIDAS := ["abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc", "abcdefg", "abcdfg"]   # del 0 al 9


# La chapa, con su marco y un remache en cada esquina
static func dibujar(lienzo: CanvasItem, tam: Vector2) -> void:
	lienzo.draw_rect(Rect2(Vector2.ZERO, tam), BORDE)
	lienzo.draw_rect(Rect2(Vector2(3, 3), tam - Vector2(6, 6)), CHAPA)
	for p in [Vector2(8, 8), Vector2(tam.x - 12, 8), Vector2(8, tam.y - 12), Vector2(tam.x - 12, tam.y - 12)]:
		lienzo.draw_rect(Rect2(p, Vector2(4, 4)), REMACHE)


# Lo ahorrado, arriba a la izquierda, como el marcador de una caja registradora: el billete y, en una pantallita
# hundida, los dólares en amarillo
# Con "fijo", el marcador de 4 casillas del inventario (en la tienda de armas: lo pidió el dueño el 15 nov)
static func dibujar_ahorrado(lienzo: CanvasItem, fuente: Font, dolares: int, fijo := false) -> void:
	lienzo.draw_texture_rect(load("res://assets/ui/iconos/billete.png"), Rect2(14, 6, 32, 32), false)
	dibujar_marcador(lienzo, fuente, caja_ahorrado(fuente, dolares, fijo), dolares, AMARILLO, false, fijo)


# El mutágeno (el guardado y el de la partida, lo mismo que en el inventario), arriba a la izquierda del árbol de
# talentos, que se paga con él (15 nov): sin dibujo al lado, el marcador fijo del inventario, con la hélice y la
# cifra en verde
static func dibujar_mutageno(lienzo: CanvasItem, fuente: Font, mutageno: int) -> void:
	dibujar_marcador(lienzo, fuente, Rect2(Vector2(14, 5), medida_fija(fuente)), mutageno, VERDE, true, true)


# La pantallita de un marcador (la de lo ahorrado o la del precio que no llega en la tienda: tienda_armas.gd) en "caja":
# el «$» pegado a la cifra, en "color" y con su sombra; las cifras, de reloj digital (dibujar_cifra). Sin casillas vacías.
# Con "adn", la del mutágeno (inventario.gd): en vez del «$», la doble hélice (ADN).
# Con "fijo" (los dos del inventario, 15 nov): siempre CIFRAS casillas, del mismo ancho con «$» o con hélice, y en cada
# casilla vacía un «8» apagado (dibujar_cifra con -1); de MAXIMO en adelante, «8MAX» (las letras, de la letra de siempre)
static func dibujar_marcador(lienzo: CanvasItem, fuente: Font, caja: Rect2, valor: int, color: Color, adn := false,
		fijo := false) -> void:
	var numero := str(valor)
	var casilla := fuente.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 2.0   # no-tr (cada cifra, del ancho de un 8)
	var ancho_dolar := ancho_simbolo(fuente, adn) if not fijo else maxf(ancho_simbolo(fuente, false), ancho_simbolo(fuente, true))
	var apagadas := 0   # las casillas de la izquierda que solo llevan su «8» apagado
	if fijo:
		numero = "MAX" if valor >= MAXIMO else numero   # no-tr (como en las máquinas: no se traduce)
		apagadas = CIFRAS - numero.length()
	lienzo.draw_rect(caja, REMACHE)                                                    # el marco
	lienzo.draw_rect(caja.grow(-2), Color("#050607"))                                  # la sombra de arriba e izquierda...
	lienzo.draw_rect(Rect2(caja.position + Vector2(3, 3), caja.size - Vector2(5, 5)), Color("#3a3f47"))   # ...la luz de abajo y derecha
	lienzo.draw_rect(Rect2(caja.position + Vector2(3, 3), caja.size - Vector2(6, 6)), Color("#0d1012"))   # y el cristal
	lienzo.draw_rect(Rect2(caja.position + Vector2(4, 4), Vector2(caja.size.x - 8, 2)), Color("#1a1e22"))  # el brillo de arriba
	var base := Vector2(caja.position.x + 9, caja.end.y - 8)
	var sombra := color.darkened(0.65)
	if adn:
		dibujar_adn(lienzo, Vector2(base.x, base.y - ADN.size() * PIXEL_ADN + 2), color, sombra)
	else:
		lienzo.draw_string(fuente, base, "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, color)   # no-tr
	var apagado := color.darkened(0.82)   # las rayas sin encender
	for i in apagadas + numero.length():
		var x := base.x + ancho_dolar + i * casilla
		var arriba := Vector2(x + roundf((casilla - CIFRA_TAM.x) / 2.0), base.y - CIFRA_TAM.y + 1)
		if i < apagadas:
			dibujar_cifra(lienzo, arriba, -1, color, apagado)
			continue
		var letra := numero[i - apagadas]
		if letra.is_valid_int():
			dibujar_cifra(lienzo, arriba, int(letra), color, apagado)
			continue
		# las letras de MAX, con la letra de siempre, centradas a mano en su casilla (la «A» es más ancha que un 8 y, con
		# el ancho de la casilla, Godot no la pinta)
		x += roundf((casilla - fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x) / 2.0)
		lienzo.draw_string(fuente, Vector2(x, base.y + 2), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, sombra)
		lienzo.draw_string(fuente, Vector2(x, base.y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, color)


# Una cifra de reloj digital (RAYAS) con su esquina de arriba a la izquierda en "pos": las rayas que no enciende, en
# "apagado", y las suyas (ENCENDIDAS), en "color". Sin sombra, como en un reloj de verdad (con ella parecía que había
# rayas de más). Con -1, todas apagadas
static func dibujar_cifra(lienzo: CanvasItem, pos: Vector2, cifra: int, color: Color, apagado: Color) -> void:
	var luz: String = ENCENDIDAS[cifra] if cifra >= 0 else ""
	for k in RAYAS:
		for r in RAYAS[k]:
			lienzo.draw_rect(Rect2(pos + Vector2(r[0], r[1]), Vector2(r[2], r[3])), color if k in luz else apagado)


# La doble hélice del mutágeno, con su esquina de arriba a la izquierda en "pos": primero la sombra, como las cifras.
# "pixel": lo que mide cada cuadradito (la pequeña del pie de la ficha de un talento, arbol_talentos.gd, va a 1)
static func dibujar_adn(lienzo: CanvasItem, pos: Vector2, color: Color, sombra: Color, pixel := PIXEL_ADN) -> void:
	for capa in [[Vector2(0, pixel), sombra], [Vector2.ZERO, color]]:
		for f in ADN.size():
			for c in ADN[f].length():
				if ADN[f][c] == "#":
					lienzo.draw_rect(Rect2(pos + capa[0] + Vector2(c, f) * pixel, Vector2.ONE * pixel), capa[1])


# Lo que ocupa el símbolo de delante de la cifra (el «$» o la hélice), con su aire hasta ella
static func ancho_simbolo(fuente: Font, adn := false) -> float:
	if adn:
		return ADN[0].length() * PIXEL_ADN + 6.0
	return fuente.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 4.0   # no-tr


# Lo que mide la pantallita de un marcador con ese valor
static func medida_marcador(fuente: Font, valor: int, adn := false) -> Vector2:
	var casilla := fuente.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 2.0   # no-tr
	return Vector2(ancho_simbolo(fuente, adn) + casilla * str(valor).length() + 20, 34)


# Lo que mide un marcador "fijo" (dibujar_marcador): el mismo con «$» que con hélice, para cualquier valor
static func medida_fija(fuente: Font) -> Vector2:
	var casilla := fuente.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 2.0   # no-tr
	return Vector2(maxf(ancho_simbolo(fuente, false), ancho_simbolo(fuente, true)) + casilla * CIFRAS + 20, 34)


# La pantallita del marcador: dónde va y lo que mide (por si se quiere poner algo a su lado)
static func caja_ahorrado(fuente: Font, dolares: int, fijo := false) -> Rect2:
	return Rect2(Vector2(52, 5), medida_fija(fuente) if fijo else medida_marcador(fuente, dolares))
