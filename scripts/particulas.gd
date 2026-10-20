# Partículas sencillas (las "particles" del JS): chispas, gotitas, gases y anillos que se abren. Todas en un
# solo nodo que las pinta de golpe, en vez de un nodo por chispa. Se usa desde cualquier sitio con
# Particulas.soltar(...) o Particulas.anillo(...): si aún no existe el nodo, se crea en la escena.
class_name Particulas
extends Node2D

var lista: Array[Dictionary] = []


static func capa(desde: Node) -> Particulas:
	var arbol := desde.get_tree()
	var p := arbol.get_first_node_in_group("particulas") as Particulas
	if p == null:
		p = Particulas.new()
		p.add_to_group("particulas")
		p.z_index = 20   # por encima de los personajes
		arbol.current_scene.add_child(p)
	return p


# Un cuadradito de "tamano" unidades que sale de "donde" con esa velocidad y dura "vida" segundos
static func soltar(desde: Node, donde: Vector2, velocidad: Vector2, color: Color, tamano: float, vida: float) -> void:
	capa(desde).lista.append({"p": donde, "v": velocidad, "c": color, "s": tamano, "t": vida, "max": vida, "r": 0.0})


# El reventón de un zombi al morir (burst en src/game-efectos.js): "n" trozos de su color, con su borde
# oscuro, que salen disparados en todas direcciones; y, si "con_anillo", un anillo blanco que se abre
static func reventon(desde: Node, donde: Vector2, color: Color, n: int, radio: float, con_anillo := true) -> void:
	var c := capa(desde)
	for i in n:
		var a := randf() * TAU
		var v := Vector2.from_angle(a)
		var vida := randf_range(0.35, 0.7)
		c.lista.append({"p": donde + v * radio * 0.5, "v": v * randf_range(80.0, 260.0), "c": color,
			"s": randf_range(8.0, 16.0), "t": vida, "max": 0.7, "r": 0.0, "borde": true})
	if con_anillo:
		anillo(desde, donde, radio, Color.WHITE)


# Un anillo que se abre desde "donde" hasta "radio" (en el suelo: aplastado como las elipses)
static func anillo(desde: Node, donde: Vector2, radio: float, color: Color, vida := 0.3) -> void:
	capa(desde).lista.append({"p": donde, "v": Vector2.ZERO, "c": color, "s": 0.0, "t": vida, "max": vida, "r": radio})


func _process(delta: float) -> void:
	for q in lista:
		q.t -= delta
		q.p += q.v * delta
		q.v *= exp(-delta * 2.0)
	lista = lista.filter(func(q): return q.t > 0.0)
	queue_redraw()


func _draw() -> void:
	for q in lista:
		var k: float = q.t / q.max
		var c: Color = q.c
		if q.r > 0.0:
			# el anillo crece y se apaga
			draw_set_transform(q.p, 0.0, Vector2(1.0, 0.6))
			draw_arc(Vector2.ZERO, q.r * (1.0 - k * 0.6), 0.0, TAU, 48, Color(c, k), 4.0)
			draw_set_transform(Vector2.ZERO)
			continue
		var s: float = maxf(2.0, round(q.s / 2.0) * 2.0)
		var p: Vector2 = (q.p / 2.0).round() * 2.0   # en píxeles enteros del dibujo
		var alfa := minf(1.0, k * 2.0)
		if q.get("borde", false):
			draw_rect(Rect2(p - Vector2(s, s) / 2.0 - Vector2(2, 2), Vector2(s + 4, s + 4)), Color(0.11, 0.1, 0.17, alfa))
		draw_rect(Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), Color(c, alfa))
