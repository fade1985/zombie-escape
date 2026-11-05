# El gas de las rejillas de Recursos Humanos, en Torre Velaria (peligros.gd, GAS): el VD-7 del aire acondicionado. Unas
# rejillas en el suelo de la sala grande que, a ratos (cada una en su momento), echan una nube morada. A Johnny no le
# hace nada (es el Sujeto 0: lo dice el dosier); a los zombis despiertos que la pisan los duerme un rato y luego
# despiertan frenéticos, más rápidos (zombi.gd, gasear). Sirve para escapar, pero vuelven peor. Con la válvula del
# archivo (valvula.gd) se corta el gas y, volviendo a ella, se abre otra vez.
#
# Se dibuja todo con código: la rejilla (en el suelo) y las bocanadas de la nube, que salen, se hinchan, se mecen y se
# deshacen.
extends Node2D

const MORADO := Color(0.5, 0.26, 0.7, 0.3)
const MORADO_CLARO := Color(0.72, 0.5, 0.9, 0.26)

var datos: Dictionary
var mapa: Node
var suelo: Node2D            # las rejillas, en el suelo
var valvula: Node2D
var bocanadas: Array = []    # [x, y, vx, vy, edad, dura, tamaño, semilla]
var nubes: Array = []        # lo grande que es ahora la nube de cada rejilla (0 a 1)
var t := 0.0


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Gas"   # no-tr (nombre de nodo)
	z_index = 4   # la nube, por delante de los personajes
	# la nube luce un poco por sí misma, para que se vea en la penumbra
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	suelo = Node2D.new()
	suelo.name = "Rejillas"
	suelo.z_index = -5   # (debajo de los personajes, encima del suelo)
	suelo.light_mask = Luz.CAPA_SUELO
	suelo.draw.connect(dibujar_rejillas)
	add_child(suelo)
	for r in d.rejillas:
		nubes.append(0.0)
	valvula = preload("res://scripts/peligros/valvula.gd").new()
	valvula.montar(d.valvula, self, m)
	m.cosas.add_child(valvula)


func _exit_tree() -> void:
	if is_instance_valid(valvula):
		valvula.queue_free()


# ¿Está echando gas la rejilla "i"? (cada una tiene su momento del ciclo)
func echando(i: int) -> bool:
	if not datos.abierto:
		return false
	var g: Dictionary = Peligros.GAS
	return fposmod(t + datos.rejillas[i].fase, g.parada + g.echa) >= g.parada


func dentro(p: Vector2) -> bool:
	for i in datos.rejillas.size():
		var r: Dictionary = datos.rejillas[i]
		if nubes[i] > 0.3 and p.distance_to(Vector2(r.x, r.y)) < Peligros.GAS.radio * nubes[i]:
			return true
	return false


# La válvula: cierra el gas (o lo abre otra vez)
func cambiar() -> void:
	datos.abierto = not datos.abierto
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("Gas cortado") if not datos.abierto else Idioma.t("Gas abierto otra vez"))


func _physics_process(delta: float) -> void:
	t += delta
	for i in datos.rejillas.size():
		var r: Dictionary = datos.rejillas[i]
		# la nube crece en un segundo al empezar y se deshace más despacio al parar
		nubes[i] = move_toward(nubes[i], 1.0 if echando(i) else 0.0, delta * (1.0 if echando(i) else 0.6))
		if echando(i) and randf() < 22.0 * delta * nubes[i]:
			var a := randf() * TAU
			var dura := randf_range(1.4, 2.4)
			bocanadas.append([r.x + randf_range(-6, 6), r.y + randf_range(-4, 4), cos(a) * randf_range(10, 30),
				sin(a) * randf_range(8, 20) - 6.0, 0.0, dura, randf_range(12, 22), randf() * TAU])
	var vivas := []
	for b in bocanadas:
		b[4] += delta
		b[0] += b[2] * delta
		b[1] += b[3] * delta
		if b[4] < b[5]:
			vivas.append(b)
	bocanadas = vivas
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position):
		Peligros.avisar(self, datos, Idioma.t("Huele raro... pero a mí no me hace nada"))
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.has_method("gasear") and not zombi.get("dormido") and not zombi is Minijefe and dentro(zombi.global_position):
			zombi.gasear(Peligros.GAS.duerme)
	modulate.a = 1.0 - mapa.niebla.get(datos.sala, 0.0)
	queue_redraw()
	suelo.queue_redraw()


# Cada rejilla: un marco oscuro con sus lamas (en píxeles de 2 unidades) y, si echa gas, un brillo morado entre ellas
func dibujar_rejillas() -> void:
	for i in datos.rejillas.size():
		var r: Dictionary = datos.rejillas[i]
		var o := Vector2(r.x - 12, r.y - 8)
		suelo.draw_rect(Rect2(o, Vector2(24, 16)), Color("#2a2c31"))
		suelo.draw_rect(Rect2(o + Vector2(2, 2), Vector2(20, 12)), Color("#15161a"))
		for k in 3:
			suelo.draw_rect(Rect2(o + Vector2(2, 3 + k * 4), Vector2(20, 2)), Color("#6b707a"))
		if nubes[i] > 0.0:
			suelo.draw_rect(Rect2(o + Vector2(2, 2), Vector2(20, 12)), Color(0.7, 0.4, 0.95, 0.35 * nubes[i]))


# Las bocanadas: bolas de pixel art (un círculo hecho de cuadraditos) que se hinchan y se van borrando
func _draw() -> void:
	for b in bocanadas:
		var k: float = b[4] / b[5]
		var radio: float = b[6] * (0.5 + k)
		var alfa: float = sin(k * PI)
		var centro := Vector2(roundf(b[0] / 2.0) * 2.0, roundf(b[1] / 2.0) * 2.0)
		var color := MORADO.lerp(MORADO_CLARO, 0.5 + 0.5 * sin(t * 2.0 + b[7]))
		color.a *= alfa
		var r := roundf(radio / 2.0)
		for y in range(-r, r + 1):
			var ancho := roundf(sqrt(maxf(r * r - y * y, 0.0)))
			draw_rect(Rect2(centro.x - ancho * 2.0, centro.y + y * 2.0, ancho * 4.0, 2), color)
