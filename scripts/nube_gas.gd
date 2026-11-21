# La nube de gas lacrimógeno del antidisturbios (antidisturbios.gd: sale de sus botes, proyectil.gd "gas"). Hasta el 21
# nov era un charco (charco.gd) y parecía líquido: ahora es una nube baja de bolas de humo blanco amarillento,
# translúcidas, que se mueven despacio y se van hinchando, con hilillos que suben. Crece al caer, dura VIDA s y se va
# deshaciendo. A quien esté dentro (Johnny y los zombis, menos a quien la tiró: "dueno") le pone el estado "toxico",
# como la lejía (estados.gd). Las paredes la cortan como a los charcos (ArmasCreadas.tapado). Se dibuja con código.
class_name NubeGas
extends Node2D

const RADIO := 72.0        # el de su huella en el suelo (una elipse, como los charcos)
const VIDA := 7.0
const CRECE := 0.5         # lo que tarda en hincharse al caer
const SE_VA := 1.2         # lo que tarda en deshacerse al final
const ESTADOS := {"toxico": {"dps": 7.0}}
const BOLAS := 11
const COLORES := [Color("#d9d8b0"), Color("#ecebc8"), Color("#c4c39a")]

var dueno: Node2D = null
var t := 0.0
var bolas: Array = []      # cada bola de humo: [sitio, radio, desfase, color]
var hilos: Array = []      # los hilillos que suben: [sitio, cuándo salió]


func _ready() -> void:
	add_to_group("nubes_gas")
	z_index = 3   # por encima de los pies de quien está dentro (translúcida: se le ve)
	for i in BOLAS:
		var a := randf() * TAU
		var d := sqrt(randf()) * RADIO * 0.75
		bolas.append([Vector2(cos(a) * d, sin(a) * d * 0.6), randf_range(18.0, 32.0), randf() * TAU,
			COLORES[i % COLORES.size()]])
	Sonido.tocar("siseo")


func _physics_process(delta: float) -> void:
	t += delta
	if t >= VIDA:
		queue_free()
		return
	queue_redraw()
	# los hilillos de humo que suben
	if randf() < delta * 10.0 and t < VIDA - SE_VA:
		var a := randf() * TAU
		hilos.append([Vector2(cos(a), sin(a) * 0.6) * randf() * RADIO * 0.8, t])
	hilos = hilos.filter(func(h): return t - h[1] < 1.4)
	# a quien esté dentro, el picor (cada paso: los estados ya cuentan su tiempo)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position) \
			and not ArmasCreadas.tapado(self, global_position, johnny.global_position):
		johnny.pisar(ESTADOS)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi != dueno and zombi.has_method("pisar") and dentro(zombi.global_position) \
				and not ArmasCreadas.tapado(self, global_position, zombi.global_position):
			zombi.pisar(ESTADOS)


# Lo grande que está (0 a 1): crece al caer y se deshace al final
func tamano() -> float:
	return minf(1.0, t / CRECE) * clampf((VIDA - t) / SE_VA, 0.0, 1.0)


func dentro(p: Vector2) -> bool:
	var d := p - global_position
	var r := RADIO * maxf(tamano(), 0.3)
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


func _draw() -> void:
	var k := tamano()
	if k <= 0.0:
		return
	# la sombra flojita en el suelo
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	Formas.disco(self, Vector2.ZERO, RADIO * k, Color("#8f8e6a", 0.18 * k))
	draw_set_transform(Vector2.ZERO)
	# las bolas de humo: primero la parte de abajo, más oscura, y encima la de arriba, más clara (como una nube con
	# volumen); se balancean despacio y respiran
	for capa in 2:
		for b in bolas:
			var vaiven := Vector2(sin(t * 0.9 + b[2]) * 6.0, cos(t * 0.7 + b[2]) * 3.0)
			var r: float = b[1] * k * (1.0 + sin(t * 1.3 + b[2]) * 0.08)
			var p: Vector2 = b[0] * (0.6 + 0.4 * k) + vaiven + Vector2(0, -r * 0.55)
			var col: Color = b[3]
			if capa == 0:
				Formas.disco(self, ((p + Vector2(0, 4)) / 2.0).floor() * 2.0, r, Color(col.darkened(0.25), 0.32 * k))
			else:
				Formas.disco(self, ((p - Vector2(r * 0.2, r * 0.25)) / 2.0).floor() * 2.0, r * 0.62, Color(col.lightened(0.2), 0.3 * k))
	# los hilillos que suben (cuadraditos que se van apagando)
	for h in hilos:
		var e: float = t - h[1]
		var p: Vector2 = h[0] + Vector2(sin(e * 4.0 + h[0].x) * 4.0, -24.0 - e * 40.0)
		draw_rect(Rect2((p / 2.0).floor() * 2.0, Vector2(4, 4)), Color("#f4f2d6", (1.0 - e / 1.4) * 0.5 * k))
