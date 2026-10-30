# El chorro de fuego del lanzallamas del jefe de bomberos (L25 y L34): el efecto "fire-breath" de pixelfx hecho
# bocanadas. Cada bocanada sale de la manguera, vuela por el cono hasta la pared y se va enfriando por el camino
# (blanca y amarilla en la boca, naranja, roja al llegar); en la pared se aplasta, se abre a los lados, sube y acaba en
# humo. Los dibujos de las bocanadas, de fuego y de humo en 10 tamaños y 10 edades, están en bocanadas-fuego.png
# (tools/pixelfx/bocanadas.mjs). El cono es rígido: las bocanadas siguen el giro del jefe, así que el fuego que se ve
# es el que quema (bombero.gd, en_cono). Lo usa bombero.gd: avanzar() en cada paso y pintar() en su lienzo de encima.
class_name ChorroFuego

const HOJA := preload("res://assets/sprites/bocanadas-fuego.png")
const TAMANOS := [3.0, 4.0, 5.0, 6.5, 8.0, 10.0, 12.5, 15.0, 18.0, 22.0]   # (los de la hoja, en píxeles del dibujo)
const CASILLA := 56
const EDADES := 10
const POR_SEGUNDO := 320.0   # bocanadas que salen cada segundo
const VELOCIDAD := [650.0, 950.0]
const APLASTADA := 0.35      # lo que dura una bocanada aplastada contra la pared
const HUMO := 0.9            # lo que dura su humo

var bocanadas: Array[Dictionary] = []
var debe := 0.0              # lo que falta por echar (POR_SEGUNDO no cae justo en cada paso)
var angulo := 0.0            # hacia dónde apunta el cono
var puntas: Array = []       # lo largo de cada rayo del cono, desde los pies (bombero.gd, medir_conos)
var abertura := 0.35         # medio cono, en radianes
var boca := Vector2.ZERO     # la boca de la manguera y los pies del jefe (por donde baja el fuego hasta el suelo)
var pies := Vector2.ZERO


# Lo largo del cono por "e" (de -1, un borde, a 1, el otro)
func largo_en(e: float) -> float:
	if puntas.is_empty():
		return 0.0
	var x := (e + 1.0) * 0.5 * (puntas.size() - 1)
	var j := clampi(int(x), 0, puntas.size() - 2)
	return lerpf(float(puntas[j]), float(puntas[j + 1]), x - j)


# Un paso: si "echa", salen bocanadas nuevas; las que hay avanzan, se aplastan en la pared y se vuelven humo
func avanzar(delta: float, echa: bool) -> void:
	if echa and not puntas.is_empty():
		debe += POR_SEGUNDO * delta
		while debe >= 1.0:
			debe -= 1.0
			var e := randf_range(-1.0, 1.0)
			bocanadas.append({"e": e, "va": randf_range(0.0, 20.0), "v": randf_range(VELOCIDAD[0], VELOCIDAD[1]),
				"tam": randf_range(0.8, 1.25) * (1.0 - 0.25 * absf(e)), "t": 0.0, "pared": -1.0, "humo": -1.0,
				"donde": Vector2.ZERO, "lado": Vector2.ZERO})
	for b in bocanadas:
		b.t += delta
		if b.humo >= 0.0:
			b.humo += delta
			b.donde += b.lado * delta * 0.3 + Vector2(0, -50.0 * delta)
		elif b.pared >= 0.0:
			b.pared += delta
			b.donde += b.lado * delta * (1.0 - b.pared / APLASTADA) + Vector2(0, -60.0 * delta)
			if b.pared >= APLASTADA:
				b.humo = 0.0 if randf() < 0.3 else HUMO   # (no todas echan humo)
		else:
			var largo := largo_en(b.e)
			b.va += b.v * delta * (1.0 - 0.3 * minf(1.0, b.va / maxf(1.0, largo)))
			if b.va >= largo:
				# llega a la pared: ahí se queda, se aplasta y se abre a los lados
				b.va = largo
				b.donde = sitio(b)
				var dir := Vector2.from_angle(angulo + b.e * abertura)
				b.lado = dir.orthogonal() * randf_range(-1.0, 1.0) * b.v * 0.35 - dir * 40.0
				b.pared = 0.0
	bocanadas = bocanadas.filter(func(b): return b.humo < HUMO)


# Dónde está una bocanada que vuela: por su rayo del cono, bajando de la boca de la manguera al suelo de la pared
func sitio(b: Dictionary) -> Vector2:
	var f: float = b.va / maxf(1.0, largo_en(b.e))
	return boca.lerp(pies, f) + Vector2.from_angle(angulo + b.e * abertura) * b.va + Vector2(0, -b.t * 30.0)


# Lo grande que se ve (en píxeles del dibujo): crece con lo que ha volado
func tamano(b: Dictionary) -> float:
	return minf(22.0, (3.0 + b.va * 0.04) * b.tam)


# El dibujo: primero el humo; luego el fuego, de la pared a la boca (lo recién salido, encima)
func pintar(lienzo: Node2D) -> void:
	for b in bocanadas:
		if b.humo >= 0.0:
			bocanada(lienzo, b.donde, tamano(b) * 1.3, b.humo / HUMO, true, 0.6)
	for b in bocanadas:
		if b.humo >= 0.0:
			continue
		if b.pared >= 0.0:
			bocanada(lienzo, b.donde, tamano(b) * (1.0 + 0.5 * b.pared / APLASTADA), 0.6 + 0.4 * b.pared / APLASTADA, false)
		else:
			var f: float = b.va / maxf(1.0, largo_en(b.e))
			bocanada(lienzo, sitio(b), tamano(b), f * 0.5 + 0.1 * absf(b.e), false)


# Una bocanada de la hoja: "edad" de 0 (recién salida, la más caliente) a 1 (casi apagada)
func bocanada(lienzo: Node2D, donde: Vector2, tam: float, edad: float, humo: bool, alfa := 1.0) -> void:
	var fila := 0
	while fila < TAMANOS.size() - 1 and TAMANOS[fila + 1] <= tam:
		fila += 1
	if humo:
		fila += TAMANOS.size()
	var col := clampi(int(edad * EDADES), 0, EDADES - 1)
	var lado := CASILLA * 2.0
	lienzo.draw_texture_rect_region(HOJA, Rect2((donde / 2.0).round() * 2.0 - Vector2(lado, lado) / 2.0, Vector2(lado, lado)),
		Rect2(col * CASILLA, fila * CASILLA, CASILLA, CASILLA), Color(1, 1, 1, alfa))
