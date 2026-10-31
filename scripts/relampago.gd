# El rayo que salta de un sitio a otro (M50): el de la descarga que pasa de un zombi a otro, el del estallido de las
# armas Épicas de rayo y el de Pararrayos (ArmasCreadas.rayo). Se dibuja a código, porque va de cualquier sitio a
# cualquier otro, pero como los rayos de pixelfx ("chain-lightning", que viene del de Sprite Fusion, licencia MIT, Hugo
# Duprez): un tronco en zigzag partido por la mitad una y otra vez (cada vez menos), con ramas que se separan y
# adelgazan, entintado con un borde oscuro, un cuerpo celeste y un centro blanco, en la rejilla de los dibujos (de 2 en
# 2). Se rehace FORMAS veces por segundo (parpadea), adelgaza y se va en VIDA segundos. Los colores, los del lanza
# rayos (llamarada.gd). En el sitio donde da, el juego pone además el chispazo (EfectoSuelo, "chispazo")
class_name Relampago
extends Node2D

const VIDA := 0.22
const FORMAS := 20.0        # cuántas veces por segundo cambia de zigzag
const QUIEBRO := 0.28       # lo que se aparta el primer punto medio, por cada unidad de largo
const RAMAS := 0.5          # las ramas que le salen (más, más ramas)
const PASO := 6.0           # hasta qué largo de tramo se sigue partiendo

var hasta := Vector2.ZERO   # adonde llega, desde su sitio
var t := 0.0
var forma := -1
var caminos: Array = []     # [puntos, grueso]: el tronco (grueso 1) y las ramas (menos)


static func soltar(sala: Node, desde: Vector2, a: Vector2) -> void:
	var r := Relampago.new()
	r.position = (desde / 2.0).round() * 2.0
	r.hasta = ((a - desde) / 2.0).round() * 2.0
	sala.add_child.call_deferred(r)   # (puede salir en mitad de una consulta de física)


func _ready() -> void:
	z_as_relative = false
	z_index = 4   # a la altura de las balas


func _process(delta: float) -> void:
	t += delta
	if t >= VIDA:
		queue_free()
		return
	var f := int(t * FORMAS)
	if f != forma:
		forma = f
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		caminos.clear()
		zigzag(rng, Vector2.ZERO, hasta, QUIEBRO, 1.0, 0)
	queue_redraw()


# El zigzag de "a" a "b": se parte por la mitad, apartando el medio hacia un lado, y cada mitad otra vez (cada vez la
# mitad de apartado), hasta que los tramos son cortos. De algunos puntos sale una rama, más fina, que hace lo mismo
func zigzag(rng: RandomNumberGenerator, a: Vector2, b: Vector2, quiebro: float, grueso: float, nivel: int) -> void:
	var largo := a.distance_to(b)
	var puntos := [a, b]
	var aparta := largo * quiebro
	while puntos.size() < 2 + largo / PASO:
		var nuevos := [puntos[0]]
		for i in puntos.size() - 1:
			var p: Vector2 = puntos[i]
			var q: Vector2 = puntos[i + 1]
			nuevos.append((p + q) / 2.0 + (q - p).normalized().orthogonal() * rng.randf_range(-aparta, aparta))
			nuevos.append(q)
		puntos = nuevos
		aparta *= 0.52
	caminos.append([puntos, grueso])
	if nivel >= 2:
		return
	for i in range(2, puntos.size() - 3):
		if rng.randf() < RAMAS / (1 + nivel) / maxf(4.0, puntos.size() / 6.0):
			var desde: Vector2 = puntos[i]
			var rumbo: float = (puntos[i + 3] - desde).angle() + (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(0.35, 0.9)
			var l := largo * (1.0 - float(i) / puntos.size()) * rng.randf_range(0.25, 0.5)
			zigzag(rng, desde, desde + Vector2.from_angle(rumbo) * l, quiebro * 1.1, grueso * 0.55, nivel + 1)


func _draw() -> void:
	var k := 1.0 - t / VIDA            # se va apagando
	var fuerte := k > 0.45             # al principio, con su borde gordo y sus ramas
	# primero todos los bordes, luego todos los cuerpos y luego los centros: así el borde de una rama no tapa el tronco
	for capa in 3:
		for c in caminos:
			var tronco: bool = c[1] >= 1.0
			if not tronco and not fuerte:
				continue
			var color: Color = [Llamarada.RAYO_BORDE, Llamarada.RAYO_MEDIO, Llamarada.RAYO_CENTRO][capa]
			var r: float = [2.0 if fuerte else 1.0, 1.0, 0.0][capa] if tronco else [1.0, 0.0, -1.0][capa]
			if r < 0.0 or (capa == 2 and not tronco):
				continue
			pintar(c[0], r, color)


# Un sello cuadrado de "r" píxeles del dibujo a cada lado (0: uno solo) en cada píxel del camino
func pintar(puntos: Array, r: float, color: Color) -> void:
	var lado := (r * 2.0 + 1.0) * 2.0
	for i in puntos.size() - 1:
		var p: Vector2 = puntos[i]
		var q: Vector2 = puntos[i + 1]
		var n := maxi(1, ceili(p.distance_to(q) / 2.0))
		for j in n:
			var s := (p.lerp(q, float(j) / n) / 2.0).round() * 2.0
			draw_rect(Rect2(s - Vector2(r * 2.0, r * 2.0), Vector2(lado, lado)), color)
