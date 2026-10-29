# Las formas del juego, pintadas con primitivas (triángulos y cuadriláteros sueltos) en vez de con draw_circle, draw_arc,
# draw_colored_polygon y draw_polyline.
#
# Por qué: en la web, cada una de esas cuatro es un polígono con sus propios buffers, y a partir de unos 150-200 por
# fotograma (sumando todo lo que se pinta a la vez) cada fotograma tarda más de un segundo: el juego «se ralentiza y se
# para» (el latigazo del Glotón pintaba 440-880 círculos). Las primitivas aguantan decenas de miles. Medido con
# `-- --captura --dibujos` (docs/WEB.md). En el ordenador no hay diferencia.
#
# Cada función se llama igual que la suya de CanvasItem, con el lienzo delante y los mismos parámetros después:
#   draw_circle(c, r, color)                       →  Formas.disco(self, c, r, color)
#   draw_arc(c, r, desde, hasta, pasos, color, an) →  Formas.arco(self, c, r, desde, hasta, pasos, color, an)
#   draw_colored_polygon(puntos, color)            →  Formas.poligono(self, puntos, color)
#   draw_polyline(puntos, color, ancho)            →  Formas.polilinea(self, puntos, color, ancho)
# Con una cosa nueva que se pinte con muchas formas a la vez, usar estas y no las de CanvasItem.
class_name Formas

const CUADRADO := 0.70710678


# Un círculo relleno. Los pequeños y opacos, con dos cuadrados (uno recto y otro girado 45°: un octógono que a ese tamaño
# no se distingue de un círculo); el resto, con un abanico de triángulos (sin solaparse, para que los translúcidos no
# se oscurezcan donde se cruzarían)
static func disco(lienzo: CanvasItem, centro: Vector2, radio: float, color: Color) -> void:
	if radio <= 0.0:
		return
	if radio <= 10.0 and color.a >= 0.99:
		var a := radio * 0.96
		lienzo.draw_rect(Rect2(centro - Vector2(a, a), Vector2(a, a) * 2.0), color)
		var u := Vector2(CUADRADO, CUADRADO) * a
		lienzo.draw_line(centro - u, centro + u, color, a * 2.0)
		return
	var lados := clampi(roundi(radio * 0.5) + 8, 10, 40)
	var colores := PackedColorArray([color])
	var sin_uv := PackedVector2Array()
	var anterior := centro + Vector2(radio, 0.0)
	for i in range(1, lados + 1):
		var siguiente := centro + Vector2.from_angle(TAU * i / lados) * radio
		lienzo.draw_primitive(PackedVector2Array([centro, anterior, siguiente]), colores, sin_uv)
		anterior = siguiente


# Un arco (o el círculo entero) de un ancho, como draw_arc: una tira de cuadriláteros entre el radio de dentro y el de
# fuera. "pasos": en cuántos trozos
static func arco(lienzo: CanvasItem, centro: Vector2, radio: float, desde: float, hasta: float, pasos: int,
		color: Color, ancho := 1.0) -> void:
	var dentro := maxf(0.0, radio - ancho * 0.5)
	var fuera := radio + ancho * 0.5
	var colores := PackedColorArray([color])
	var sin_uv := PackedVector2Array()
	var n := maxi(1, pasos)
	var d0 := Vector2.from_angle(desde)
	for i in range(1, n + 1):
		var d1 := Vector2.from_angle(lerpf(desde, hasta, float(i) / n))
		lienzo.draw_primitive(PackedVector2Array([centro + d0 * dentro, centro + d0 * fuera, centro + d1 * fuera,
			centro + d1 * dentro]), colores, sin_uv)
		d0 = d1


# Un polígono relleno, como draw_colored_polygon: un triángulo o un cuadrilátero, tal cual; los demás se parten en
# triángulos (Geometry2D)
static func poligono(lienzo: CanvasItem, puntos: PackedVector2Array, color: Color) -> void:
	var colores := PackedColorArray([color])
	var sin_uv := PackedVector2Array()
	if puntos.size() == 3 or puntos.size() == 4:
		lienzo.draw_primitive(puntos, colores, sin_uv)
		return
	var triangulos := Geometry2D.triangulate_polygon(puntos)
	if triangulos.is_empty():
		return
	for i in range(0, triangulos.size(), 3):
		lienzo.draw_primitive(PackedVector2Array([puntos[triangulos[i]], puntos[triangulos[i + 1]], puntos[triangulos[i + 2]]]),
			colores, sin_uv)


# Una línea quebrada de un ancho, como draw_polyline: un cuadrilátero por trozo, con el lado de cada punto promediado entre
# los dos trozos que se juntan en él (sin huecos ni solapes en las curvas). "antialiased" no hace nada (por si lo piden)
static func polilinea(lienzo: CanvasItem, puntos: PackedVector2Array, color: Color, ancho := 1.0, _antialiased := false) -> void:
	var n := puntos.size()
	if n < 2:
		return
	var medio := ancho * 0.5
	var lados := PackedVector2Array()
	for i in n:
		var antes := (puntos[i] - puntos[i - 1]).orthogonal().normalized() if i > 0 else Vector2.ZERO
		var despues := (puntos[i + 1] - puntos[i]).orthogonal().normalized() if i < n - 1 else Vector2.ZERO
		var lado := antes + despues
		if lado.length() < 0.001:
			lado = antes if antes != Vector2.ZERO else despues
		else:
			lado = lado.normalized() * clampf(1.0 / maxf(lado.normalized().dot(despues if i == 0 else antes), 0.5), 1.0, 2.0)
		lados.append(lado * medio)
	var colores := PackedColorArray([color])
	var sin_uv := PackedVector2Array()
	for i in range(n - 1):
		lienzo.draw_primitive(PackedVector2Array([puntos[i] + lados[i], puntos[i + 1] + lados[i + 1],
			puntos[i + 1] - lados[i + 1], puntos[i] - lados[i]]), colores, sin_uv)
