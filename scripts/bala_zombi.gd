# Una bala de los malos (el agua sucia que lanza la portera con la fregona o los alfileres de la modista): vuela en línea recta,
# se acaba al chocar con una pared o un mueble y le hace daño a Johnny si le da. Como enemyShoot en el juego
# (src/game-combate.js).
class_name BalaZombi
extends Node2D

var velocidad := Vector2.ZERO
var dano := 10
var radio := 9.0
var vida := 6.0
var forma := "gota"   # "gota": agua sucia de fregar (la portera); "alfiler": una aguja con la cabeza roja (la modista)
var dueno: Node2D = null   # quien la lanza (para la skin del glotón: johnny.gd, devolver())
var t := randf() * TAU     # para que cada gota tiemble a su ritmo

# El agua sucia de la fregona, de pixel art: borde, sombra, cuerpo, luz y brillo
# (verdosa y turbia, algo transparente: que no parezca una piedra)
const AGUA := {"borde": Color("#1f2b27", 0.95), "oscuro": Color("#46604f", 0.88), "medio": Color("#69896f", 0.85),
	"claro": Color("#9cbf9c", 0.9), "brillo": Color("#f4fbef")}
const PIXEL := 2.0   # un píxel del dibujo
const ALTO := 22.0   # a qué altura del suelo vuela
# Los dibujos de la gota ya hechos, por tamaño, dirección (16) y estiramiento (3): así no se recalculan
static var dibujos := {}


func _ready() -> void:
	add_to_group("balas_zombi")   # así la portera puede borrarlas todas al enfadarse


func _physics_process(delta: float) -> void:
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		salpicar(choque.position, -velocidad)   # contra la pared: rebota hacia atrás
		queue_free()
		return
	global_position = despues
	t += delta
	if forma == "gota":
		queue_redraw()   # tiembla al volar
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + radio:
		johnny.recibir_dano(dano, dueno)
		salpicar(global_position, velocidad)   # sobre Johnny: sigue hacia delante
		queue_free()


func salpicar(donde: Vector2, hacia: Vector2) -> void:
	if forma == "gota":
		Salpicadura.lanzar(get_parent(), donde, hacia, AGUA)


# La gota de agua sucia (o el alfiler), a la altura del cuerpo y con su sombra en el suelo
func _draw() -> void:
	if forma == "alfiler":
		var d := velocidad.normalized()
		var a := Vector2(0, -ALTO)
		draw_line(a - d * 9.0, a + d * 8.0, Color("#1d1b2c"), 4.0)
		draw_line(a - d * 8.0, a + d * 7.0, Color("#d8dde6"), 2.0)
		draw_circle(a - d * 8.0, 3.0, Color("#e0303a"))
		return
	# la sombra: un óvalo de píxeles, aplastado como el suelo
	var r := roundi(radio * 0.8 / PIXEL)
	for y in range(-r / 2, r / 2 + 1):
		for x in range(-r, r + 1):
			if Vector2(x, y * 2.0).length() <= r:
				draw_rect(Rect2(Vector2(x, y) * PIXEL, Vector2(PIXEL, PIXEL)), Color(0, 0, 0, 0.22))
	# la gota: se estira y se encoge un poco (3 dibujos), y apunta hacia donde vuela (16 direcciones)
	var dir := posmod(roundi(velocidad.angle() / TAU * 16.0), 16)
	var estira := posmod(roundi(sin(t * 18.0) * 1.0), 3)
	var clave := "%d_%d_%d" % [roundi(radio), dir, estira]
	if not dibujos.has(clave):
		dibujos[clave] = dibujar_gota(radio, dir * TAU / 16.0, [1.0, 1.18, 0.88][estira])
	for p in dibujos[clave]:
		draw_rect(Rect2(p[0] + Vector2(0, -ALTO), Vector2(PIXEL, PIXEL)), p[1])
	# dos gotitas detrás, que se encienden y se apagan
	var atras := -velocidad.normalized()
	for k in 2:
		var p: Vector2 = (atras * radio * (2.6 + k * 1.3) / PIXEL).round() * PIXEL + Vector2(0, -ALTO)
		var luz := 0.5 + 0.5 * sin(t * 25.0 + k * 2.0)
		draw_rect(Rect2(p, Vector2(PIXEL, PIXEL) * (2 - k)), Color(AGUA.claro, 0.5 + 0.4 * luz))


# Los píxeles de una gota con forma de lágrima: redonda delante, con la cola en punta hacia atrás. Luz desde
# arriba y un brillo arriba a la izquierda. Devuelve [posición, color] de cada píxel
static func dibujar_gota(radio: float, angulo: float, estira: float) -> Array:
	var d := Vector2.from_angle(angulo)
	var lado := d.orthogonal()
	var largo := radio * 1.9 * estira   # la cola
	var ancho := radio / sqrt(estira)
	var dentro := func(c: Vector2, crece: float) -> bool:
		var u := c.dot(d)
		var v := absf(c.dot(lado))
		if u >= 0.0:
			return Vector2(u / (radio * estira + crece), v / (ancho + crece)).length() <= 1.0
		var k := -u / (largo + crece)
		return k <= 1.0 and v <= (ancho + crece) * pow(1.0 - k, 0.7)
	var n := ceili((largo + radio) / PIXEL) + 2
	var pixeles := []
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * PIXEL
			var c := p + Vector2(PIXEL, PIXEL) / 2.0
			if dentro.call(c, 0.0):
				# el borde de arriba, con luz; el de abajo, en sombra; y el brillo arriba a la izquierda
				var color: Color = AGUA.medio
				if not dentro.call(c - Vector2(0, PIXEL), 0.0):
					color = AGUA.claro
				elif not dentro.call(c + Vector2(0, PIXEL), 0.0) or not dentro.call(c + Vector2(0, PIXEL * 2.0), 0.0):
					color = AGUA.oscuro
				if c.distance_to(Vector2(-0.2, -0.35) * ancho) < maxf(ancho * 0.28, PIXEL * 1.1):
					color = AGUA.brillo
				pixeles.append([p, color])
			elif dentro.call(c, PIXEL * 1.1):
				pixeles.append([p, AGUA.borde])
	return pixeles
