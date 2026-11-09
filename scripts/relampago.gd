# El rayo que salta de un sitio a otro (M50): el de la descarga que pasa de un zombi a otro, el del estallido de las
# armas Épicas de rayo y el de Pararrayos (ArmasCreadas.rayo). Se dibuja a código, porque va de cualquier sitio a
# cualquier otro, pero como los rayos de pixelfx ("chain-lightning", que viene del de Sprite Fusion, licencia MIT, Hugo
# Duprez): un tronco en zigzag partido por la mitad una y otra vez (cada vez menos), con ramas que se separan y
# adelgazan, entintado píxel a píxel en la rejilla de los dibujos: un borde oscuro, un cuerpo celeste y un centro blanco
# de un píxel. Se rehace FORMAS veces por segundo (parpadea), adelgaza y se va en VIDA segundos. Los colores, los del
# lanza rayos. En el sitio donde da, el juego pone además el chispazo (EfectoSuelo, "chispazo").
# El rayo continuo del lanza rayos (llamarada.gd) se dibuja con lo mismo: trazar() y pintar()
class_name Relampago
extends Node2D

const VIDA := 0.22
const FORMAS := 20.0        # cuántas veces por segundo cambia de zigzag
const QUIEBRO := 0.28       # lo que se aparta el primer punto medio, por cada unidad de largo
const RAMAS := 0.5          # las ramas que le salen (más, más ramas)
const PASO := 6.0           # hasta qué largo de tramo se sigue partiendo
# Los colores, de fuera adentro: el borde, el cuerpo y el centro (los del lanza rayos)
const BORDE := Color("#0aa0a2")
const CUERPO := Color("#2cf2f0")
const CENTRO := Color("#ecffff")
# Lo gordo de cada capa, en píxeles del dibujo (el radio del sello redondo): el tronco con fuerza, el tronco
# apagándose y las ramas. -1: esa capa no se pinta
const GORDO := {"fuerte": [1.6, 1.0, 0.0], "flojo": [1.0, 0.0, -1.0], "rama": [1.0, 0.0, -1.0]}

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
		trazar(caminos, rng, Vector2.ZERO, hasta)
	queue_redraw()


func _draw() -> void:
	pintar(self, caminos, t / VIDA < 0.55, global_position)


# El zigzag de "a" a "b", que se añade a "caminos": se parte por la mitad, apartando el medio hacia un lado, y cada mitad
# otra vez (cada vez la mitad de apartado), hasta que los tramos son cortos. De algunos puntos sale una rama, más fina,
# que hace lo mismo. "ramas": cuántas le salen (RAMAS)
static func trazar(caminos: Array, rng: RandomNumberGenerator, a: Vector2, b: Vector2, quiebro := QUIEBRO, ramas := RAMAS,
		grueso := 1.0, nivel := 0) -> void:
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
		if rng.randf() < ramas / (1 + nivel) / maxf(4.0, puntos.size() / 6.0):
			var desde: Vector2 = puntos[i]
			var rumbo: float = (puntos[i + 3] - desde).angle() + (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(0.35, 0.9)
			var l := largo * (1.0 - float(i) / puntos.size()) * rng.randf_range(0.25, 0.5)
			trazar(caminos, rng, desde, desde + Vector2.from_angle(rumbo) * l, quiebro * 1.1, ramas, grueso * 0.55, nivel + 1)


# Entinta los caminos en "lienzo", píxel a píxel en la rejilla de los dibujos (de 2 en 2 en el mundo: "origen" es dónde
# está el lienzo, para cuadrar con ella). Cada píxel se queda con la capa más de dentro que le toque (como pixelfx: así el
# borde de una rama no tapa el tronco) y se pinta una sola vez. "fuerte": al principio, con su borde gordo y sus ramas
static func pintar(lienzo: CanvasItem, lista: Array, fuerte: bool, origen: Vector2) -> void:
	pintar_con(lienzo, lista, GORDO.fuerte if fuerte else GORDO.flojo, GORDO.rama if fuerte else [], [BORDE, CUERPO, CENTRO], origen)


# Lo mismo, eligiendo lo gordo de cada capa en el tronco y en las ramas ([] o sin ramas: no se pintan) y sus tres
# colores (el lanza rayos: sus hebras finas, sus latigazos y el fogonazo blanco del tronco)
static func pintar_con(lienzo: CanvasItem, lista: Array, gordo_tronco: Array, gordo_rama: Array, colores: Array,
		origen: Vector2) -> void:
	var capa := {}   # píxel del dibujo → 0 borde, 1 cuerpo, 2 centro
	for c in lista:
		var tronco: bool = c[1] >= 1.0
		if not tronco and gordo_rama.is_empty():
			continue
		var gordo: Array = gordo_tronco if tronco else gordo_rama
		var puntos: Array = c[0]
		for i in puntos.size() - 1:
			var p: Vector2 = (puntos[i] + origen) / 2.0
			var q: Vector2 = (puntos[i + 1] + origen) / 2.0
			var n := maxi(1, ceili(p.distance_to(q)))
			for j in n:
				var s := Vector2i(p.lerp(q, float(j) / n).round())
				for k in 3:
					var r: float = gordo[k]
					if r < 0.0:
						continue
					var ri := floori(r)
					for dx in range(-ri, ri + 1):
						for dy in range(-ri, ri + 1):
							if dx * dx + dy * dy <= r * r:
								var d := s + Vector2i(dx, dy)
								if capa.get(d, -1) < k:
									capa[d] = k
	for d in capa:
		lienzo.draw_rect(Rect2(Vector2(d) * 2.0 - origen, Vector2(2, 2)), colores[capa[d]])


# Un disco relleno de radio "r" (en píxeles del dibujo) en "centro" (en el lienzo), cuadrado con la rejilla de los dibujos
static func disco(lienzo: CanvasItem, centro: Vector2, r: float, color: Color, origen: Vector2) -> void:
	var c := (centro + origen) / 2.0
	for y in range(floori(c.y - r), ceili(c.y + r) + 1):
		for x in range(floori(c.x - r), ceili(c.x + r) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_squared_to(c) <= r * r:
				lienzo.draw_rect(Rect2(Vector2(x, y) * 2.0 - origen, Vector2(2, 2)), color)
