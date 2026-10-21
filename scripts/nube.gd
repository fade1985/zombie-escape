# La nube somnífera (arrojadiza creada del centro comercial: spray + jeringuilla; un guiño al VD-7, que es un
# somnífero). Al reventar, el gas morado se queda unos segundos donde cayó. Los zombis que pilla dentro se duermen:
# se quedan quietos (aturdidos) mientras están dentro y unos segundos más después, con sus "z" encima. A Johnny no
# le hace nada, ni a los jefes (no son Zombi).
extends Node2D

const DESHACE := 0.6   # lo que tarda en deshacerse al final

var radio := 120.0
var vida := 3.0        # lo que dura la nube
var duerme := 3.0      # lo que siguen dormidos al salir de ella
var color := Color("#c9a0ff")
var t := 0.0
var tick := 0.0
var bocanadas: Array = []   # [posición, radio, fase]: las bolas de gas que forman la nube


func _ready() -> void:
	z_index = 10   # por encima de los zombis: el gas los tapa un poco
	for i in 18:
		var a := randf() * TAU
		var d := sqrt(randf()) * radio * 0.7
		bocanadas.append([Vector2(cos(a) * d, sin(a) * d * 0.6), randf_range(0.3, 0.45) * radio, randf() * TAU])
	for i in 14:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(0, -10), Vector2(cos(a), sin(a) * 0.6) * randf_range(60, 160),
			color, 3, 0.4)


func _physics_process(delta: float) -> void:
	t += delta
	if t >= vida + DESHACE:
		queue_free()
		return
	tick += delta
	if tick >= 0.25 and t < vida:
		tick -= 0.25
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if not zombi is Zombi or not dentro(zombi.global_position):
				continue
			zombi.aturdido = maxf(zombi.aturdido, duerme)
			if randf() < 0.35:
				Zombi.texto_flotante(get_parent(), zombi.global_position + Vector2(randf_range(-14, 6), -70), "z", Color("#e6d6ff"), 14)
	queue_redraw()


# La nube, como los charcos, es una elipse en el suelo (de alto, el 60 %)
func dentro(punto: Vector2) -> bool:
	var d := punto - global_position
	return (d.x / radio) ** 2 + (d.y / (radio * 0.6)) ** 2 <= 1.0


func _draw() -> void:
	var fuerza := minf(t / 0.2, 1.0) * clampf((vida + DESHACE - t) / DESHACE, 0.0, 1.0)
	for b in bocanadas:
		# cada bola sube y baja despacio, crece un poco con los segundos y está hecha de cuadraditos de 2
		var p: Vector2 = b[0] + Vector2(sin(t * 0.9 + b[2]) * 6.0, -18.0 + cos(t * 0.7 + b[2]) * 4.0 - t * 3.0)
		var r: float = b[1] * (0.85 + 0.15 * minf(t / vida, 1.0))
		p = (p / 2.0).round() * 2.0
		draw_set_transform(p, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, r, Color(color, 0.16 * fuerza))
		draw_circle(Vector2.ZERO, r * 0.6, Color(color.lightened(0.3), 0.12 * fuerza))
