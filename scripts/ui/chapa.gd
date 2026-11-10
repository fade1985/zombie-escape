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
const ARRIBA := 44                   # lo alto de la franja de lo ahorrado


# La chapa, con su marco y un remache en cada esquina
static func dibujar(lienzo: CanvasItem, tam: Vector2) -> void:
	lienzo.draw_rect(Rect2(Vector2.ZERO, tam), BORDE)
	lienzo.draw_rect(Rect2(Vector2(3, 3), tam - Vector2(6, 6)), CHAPA)
	for p in [Vector2(8, 8), Vector2(tam.x - 12, 8), Vector2(8, tam.y - 12), Vector2(tam.x - 12, tam.y - 12)]:
		lienzo.draw_rect(Rect2(p, Vector2(4, 4)), REMACHE)


# Lo ahorrado, arriba a la izquierda, como el marcador de una caja registradora: el billete y, en una pantallita
# hundida, los dólares en amarillo encima de unos «8» apagados (los segmentos sin encender)
static func dibujar_ahorrado(lienzo: CanvasItem, fuente: Font, dolares: int) -> void:
	lienzo.draw_texture_rect(load("res://assets/ui/iconos/billete.png"), Rect2(14, 6, 32, 32), false)
	dibujar_marcador(lienzo, fuente, caja_ahorrado(fuente, dolares), dolares, AMARILLO)


# La pantallita de un marcador (la de lo ahorrado o la del precio que no llega, en rojo, en la tienda: tienda_armas.gd)
# en "caja": el «$» y la cifra en "color", encima de unos «8» apagados de su color
static func dibujar_marcador(lienzo: CanvasItem, fuente: Font, caja: Rect2, valor: int, color: Color) -> void:
	var numero := str(valor)
	var casillas := maxi(4, numero.length())   # una por cifra, todas del mismo ancho (el de un 8), como en un marcador
	var casilla := fuente.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 2.0   # no-tr
	var ancho_dolar := fuente.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 4.0   # no-tr
	lienzo.draw_rect(caja, REMACHE)                                                    # el marco
	lienzo.draw_rect(caja.grow(-2), Color("#050607"))                                  # la sombra de arriba e izquierda...
	lienzo.draw_rect(Rect2(caja.position + Vector2(3, 3), caja.size - Vector2(5, 5)), Color("#3a3f47"))   # ...la luz de abajo y derecha
	lienzo.draw_rect(Rect2(caja.position + Vector2(3, 3), caja.size - Vector2(6, 6)), Color("#0d1012"))   # y el cristal
	lienzo.draw_rect(Rect2(caja.position + Vector2(4, 4), Vector2(caja.size.x - 8, 2)), Color("#1a1e22"))  # el brillo de arriba
	var base := Vector2(caja.position.x + 9, caja.end.y - 8)
	lienzo.draw_string(fuente, base, "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, color)   # no-tr
	var apagado := color.darkened(0.85)   # (con el amarillo, el #26231a de siempre más o menos)
	var sombra := color.darkened(0.65)
	# cada casilla, su 8 apagado y, en las de la derecha, la cifra encendida (centrada en su casilla) con su sombra
	for i in casillas:
		var x := base.x + ancho_dolar + i * casilla
		lienzo.draw_string(fuente, Vector2(x, base.y), "8", HORIZONTAL_ALIGNMENT_CENTER, casilla, 32, apagado)   # no-tr
		var j := i - (casillas - numero.length())
		if j >= 0:
			lienzo.draw_string(fuente, Vector2(x, base.y + 2), numero[j], HORIZONTAL_ALIGNMENT_CENTER, casilla, 32, sombra)
			lienzo.draw_string(fuente, Vector2(x, base.y), numero[j], HORIZONTAL_ALIGNMENT_CENTER, casilla, 32, color)


# Lo que mide la pantallita de un marcador con ese valor
static func medida_marcador(fuente: Font, valor: int) -> Vector2:
	var casillas := maxi(4, str(valor).length())
	var casilla := fuente.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 2.0   # no-tr
	var ancho_dolar := fuente.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + 4.0   # no-tr
	return Vector2(ancho_dolar + casilla * casillas + 20, 34)


# La pantallita del marcador: dónde va y lo que mide (por si se quiere poner algo a su lado)
static func caja_ahorrado(fuente: Font, dolares: int) -> Rect2:
	return Rect2(Vector2(52, 5), medida_marcador(fuente, dolares))
