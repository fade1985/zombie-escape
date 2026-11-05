# El cortocircuito del informático (minijefe de Torre Velaria, informatico.gd): el suelo de su sala, partido en franjas
# a lo ancho, se electrifica por turnos. En cada turno, primero las franjas que van a dar corriente echan chispitas
# (AVISO: se ve venir) y luego dan corriente un rato (ACTIVA): si Johnny tiene los pies en una, DANO y un calambre. Las
# que no tocan en ese turno son seguras: hay que ir saltando de una segura a otra. "turnos" dice qué franjas dan en cada
# turno: [0, 1] son las pares y luego las impares; enfadado, [0, 1, 0].
# Va en el suelo y luce por sí mismo (como los avisos: también a oscuras, con el apagón). Se crea con Cortocircuito.new().
class_name Cortocircuito
extends Node2D

const FRANJA := 96.0          # lo ancha que es cada franja (de arriba abajo)
const DANO := 12

var sala := Rect2()           # el suelo de la sala (en unidades)
var turnos: Array = [0, 1]
var aviso := 1.1              # lo que echan chispitas antes de dar corriente
var activa := 0.8             # lo que dan corriente
var dueno: Node2D = null      # el informático (para el cartel de derrota y la skin del glotón)
var t := 0.0
var turno := -1               # el turno en marcha
var pillado := false          # si ya le ha dado en este turno (uno por turno)
var chispas := []             # las chispitas: {pos, vida}


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse el informático, se corta el que hubiera
	z_as_relative = false
	z_index = -1
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = sin_luz


func franjas() -> int:
	return maxi(2, ceili(sala.size.y / FRANJA))


func dura_turno() -> float:
	return aviso + activa


# Si la franja "i" da corriente en el turno que va
func toca(i: int) -> bool:
	return turno >= 0 and i % 2 == turnos[turno]


func _physics_process(delta: float) -> void:
	t += delta
	var nuevo := floori(t / dura_turno())
	if nuevo >= turnos.size():
		queue_free()
		return
	if nuevo != turno:
		turno = nuevo
		pillado = false
		Sonido.tocar("chisporroteo")
	var en := t - turno * dura_turno()   # lo que lleva el turno
	var dando := en >= aviso
	if dando and en - delta < aviso:
		Sonido.tocar("calambre")
		Temblor.temblar(4.0)
	# las chispitas: cada vez más antes de dar corriente, y muchas mientras da
	var ritmo := 30.0 * (en / aviso) if not dando else 70.0
	for i in franjas():
		if not toca(i):
			continue
		var r := rect_franja(i)
		var n := ritmo * delta * (r.size.x / 600.0)
		while n > 0.0:
			if randf() < n:
				chispas.append({"pos": Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y)),
					"vida": randf_range(0.08, 0.2)})
			n -= 1.0
	for c in chispas:
		c.vida -= delta
	chispas = chispas.filter(func(c): return c.vida > 0.0)
	# si Johnny tiene los pies en una franja que da corriente (rodando por el suelo, no se libra)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if dando and not pillado and johnny and johnny.vivo:
		var pies: Vector2 = johnny.global_position + Vector2(0, 12)
		var i := floori((pies.y - sala.position.y) / FRANJA)
		if sala.has_point(pies) and toca(i):
			pillado = true
			johnny.recibir_dano(DANO, dueno)
			for k in 6:
				Particulas.soltar(get_parent(), pies + Vector2(randf_range(-12, 12), -10),
					Vector2.from_angle(randf() * TAU) * 120.0, Color("#bff4ff"), 3, 0.25)
	queue_redraw()


func rect_franja(i: int) -> Rect2:
	var y0 := sala.position.y + i * FRANJA
	return Rect2(sala.position.x, y0, sala.size.x, minf(FRANJA, sala.end.y - y0))


func _draw() -> void:
	if turno < 0:
		return
	var en := t - turno * dura_turno()
	var dando := en >= aviso
	var k := clampf(en / aviso, 0.0, 1.0)
	for i in franjas():
		var r := rect_franja(i)
		if r.size.y <= 0.0:
			continue
		if not toca(i):
			continue
		if not dando:
			# el aviso: la franja se va tiñendo de azul, con el borde punteado que parpadea cada vez más deprisa
			draw_rect(r, Color(0.35, 0.8, 1.0, 0.06 + 0.12 * k))
			var luce := 0.35 + 0.35 * absf(sin(t * (6.0 + 14.0 * k)))
			borde(r, Color(0.6, 0.95, 1.0, luce))
		else:
			# da corriente: azul eléctrico y rayitos en zigzag de lado a lado
			var parpadeo := 0.75 + 0.25 * sin(t * 60.0)
			draw_rect(r, Color(0.4, 0.85, 1.0, 0.32 * parpadeo))
			borde(r, Color(0.85, 1.0, 1.0, 0.9))
			for linea in 3:
				var y := r.position.y + r.size.y * (linea + 0.5) / 3.0
				var puntos := PackedVector2Array()
				var x := r.position.x
				var semilla := floorf(t * 18.0) + linea * 7.0 + i * 13.0
				while x <= r.end.x:
					var s := sin(semilla * 12.9898 + x * 0.0789) * 43758.5453
					puntos.append(Vector2(x, y + (s - floorf(s) - 0.5) * r.size.y * 0.4))
					x += 22.0
				draw_polyline(puntos, Color(0.9, 1.0, 1.0, 0.85 * parpadeo), 2.0)
	for c in chispas:
		var p: Vector2 = c.pos
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("#fff6a8"))
		draw_rect(Rect2(p - Vector2(5, 1), Vector2(10, 2)), Color("#bff4ff", 0.8))
		draw_rect(Rect2(p - Vector2(1, 5), Vector2(2, 10)), Color("#bff4ff", 0.8))


# El borde de una franja, a trazos
func borde(r: Rect2, color: Color) -> void:
	for y in [r.position.y + 1.0, r.end.y - 1.0]:
		var x := r.position.x
		while x < r.end.x:
			draw_line(Vector2(x, y), Vector2(minf(x + 12.0, r.end.x), y), color, 2.0)
			x += 20.0
