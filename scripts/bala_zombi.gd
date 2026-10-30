# Una bala de los malos (el agua sucia que lanza la portera con la fregona o los alfileres de la modista): vuela en línea recta,
# se acaba al chocar con una pared o un mueble y le hace daño a Johnny si le da. Como enemyShoot en el juego
# (src/game-combate.js).
class_name BalaZombi
extends Node2D

var velocidad := Vector2.ZERO
var dano := 10
var radio := 9.0
var vida := 6.0
var forma := "gota"   # "gota": agua sucia de fregar (la portera); "polvo": una nubecita (su giro); "alfiler": una
                      # aguja con la cabeza roja (la modista)
var agua: Dictionary = AGUA   # los colores de la gota (AGUA_ROJA, con la portera enfadada)
var dueno: Node2D = null   # quien la lanza (para la skin del glotón: johnny.gd, devolver())
var t := randf() * TAU     # para que cada gota tiemble a su ritmo
var edad := 0.0            # el polvo se va hinchando al volar

# El agua sucia de la fregona, de pixel art: borde, sombra, cuerpo, luz y brillo
# (verdosa y turbia, algo transparente: que no parezca una piedra)
const AGUA := {"borde": Color("#1f2b27", 0.95), "oscuro": Color("#46604f", 0.88), "medio": Color("#69896f", 0.85),
	"claro": Color("#9cbf9c", 0.9), "brillo": Color("#f4fbef")}
# Con la portera enfadada, el agua sale rojiza (la fregona está llena de sangre)
const AGUA_ROJA := {"borde": Color("#2e1416", 0.95), "oscuro": Color("#6e2a2a", 0.88), "medio": Color("#9a4038", 0.85),
	"claro": Color("#c8786a", 0.9), "brillo": Color("#fbeeea")}
# El polvo del giro: gris claro, algo transparente y con el borde suave, sin brillo
const POLVO := {"borde": Color("#4a4646", 0.6), "oscuro": Color("#857f78", 0.75), "medio": Color("#b0aaa2", 0.72),
	"claro": Color("#dcd7ce", 0.8), "brillo": Color("#dcd7ce", 0.8)}
const PIXEL := 2.0   # un píxel del dibujo
const ALTO := 22.0   # a qué altura del suelo vuela
# Los dibujos de la gota ya hechos, por color, tamaño, dirección (16) y estiramiento (3), y los de la nubecita de
# polvo, por tamaño y vuelta (4): así no se recalculan
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
	edad += delta
	if forma != "alfiler":
		queue_redraw()   # la gota tiembla al volar y el polvo da vueltas
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + radio:
		johnny.recibir_dano(dano, dueno)
		salpicar(global_position, velocidad)   # sobre Johnny: sigue hacia delante
		queue_free()


func salpicar(donde: Vector2, hacia: Vector2) -> void:
	if forma == "gota":
		Salpicadura.lanzar(get_parent(), donde, hacia, agua)
	elif forma == "polvo":
		Salpicadura.lanzar(get_parent(), donde, hacia, POLVO, true)   # se deshace, sin mancha


# La gota de agua sucia (o la nubecita de polvo, o el alfiler), a la altura del cuerpo y con su sombra en el suelo
func _draw() -> void:
	if forma == "alfiler":
		var d := velocidad.normalized()
		var a := Vector2(0, -ALTO)
		draw_line(a - d * 9.0, a + d * 8.0, Color("#1d1b2c"), 4.0)
		draw_line(a - d * 8.0, a + d * 7.0, Color("#d8dde6"), 2.0)
		Formas.disco(self, a - d * 8.0, 3.0, Color("#e0303a"))
		return
	# la sombra: un óvalo de píxeles, aplastado como el suelo
	var r := roundi(radio * 0.8 / PIXEL)
	for y in range(-r / 2, r / 2 + 1):
		for x in range(-r, r + 1):
			if Vector2(x, y * 2.0).length() <= r:
				draw_rect(Rect2(Vector2(x, y) * PIXEL, Vector2(PIXEL, PIXEL)), Color(0, 0, 0, 0.22))
	if forma == "polvo":
		# la nubecita: da vueltas (4 dibujos) y se hincha un poco al volar
		var vuelta := posmod(int(t * 10.0), 4)
		var tam := roundi(radio * (1.2 + 0.6 * minf(edad / 0.8, 1.0)))
		var nube := "polvo_%d_%d" % [tam, vuelta]
		if not dibujos.has(nube):
			dibujos[nube] = dibujar_polvo(tam, vuelta * TAU / 12.0)
		for p in dibujos[nube]:
			draw_rect(Rect2(p[0] + Vector2(0, -ALTO), Vector2(PIXEL, PIXEL)), p[1])
		return
	# la gota: se estira y se encoge un poco (3 dibujos), y apunta hacia donde vuela (16 direcciones)
	var dir := posmod(roundi(velocidad.angle() / TAU * 16.0), 16)
	var estira := posmod(roundi(sin(t * 18.0) * 1.0), 3)
	var clave := "%s_%d_%d_%d" % [agua.medio.to_html(), roundi(radio), dir, estira]
	if not dibujos.has(clave):
		dibujos[clave] = dibujar_gota(radio, dir * TAU / 16.0, [1.0, 1.18, 0.88][estira], agua)
	for p in dibujos[clave]:
		draw_rect(Rect2(p[0] + Vector2(0, -ALTO), Vector2(PIXEL, PIXEL)), p[1])
	# dos gotitas detrás, que se encienden y se apagan
	var atras := -velocidad.normalized()
	for k in 2:
		var p: Vector2 = (atras * radio * (2.6 + k * 1.3) / PIXEL).round() * PIXEL + Vector2(0, -ALTO)
		var luz := 0.5 + 0.5 * sin(t * 25.0 + k * 2.0)
		draw_rect(Rect2(p, Vector2(PIXEL, PIXEL) * (2 - k)), Color(agua.claro, 0.5 + 0.4 * luz))


# Los píxeles de una gota con forma de lágrima: redonda delante, con la cola en punta hacia atrás. Luz desde
# arriba y un brillo arriba a la izquierda (pintar(), abajo)
static func dibujar_gota(radio: float, angulo: float, estira: float, colores: Dictionary) -> Array:
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
	return pintar(dentro, n, colores, Vector2(-0.2, -0.35) * ancho, maxf(ancho * 0.28, PIXEL * 1.1))


# Los píxeles de una nubecita de polvo (o del vapor de la portera, con otros colores): una bola en medio y tres
# alrededor, giradas "vuelta"
static func dibujar_polvo(radio: float, vuelta: float, colores := POLVO) -> Array:
	var bolas := [[Vector2.ZERO, radio * 0.62]]
	for i in 3:
		bolas.append([Vector2.from_angle(vuelta + i * TAU / 3.0) * radio * 0.55, radio * 0.48])
	var dentro := func(c: Vector2, crece: float) -> bool:
		for b in bolas:
			if c.distance_to(b[0]) <= b[1] + crece:
				return true
		return false
	return pintar(dentro, ceili(radio * 1.2 / PIXEL) + 2, colores, Vector2.ZERO, 0.0)


# Pinta píxel a píxel lo que está "dentro" (una función: si el punto está dentro, con el borde "crece" más gordo):
# el borde de arriba, con luz; el de abajo, en sombra; el contorno, oscuro; y un brillo redondo en "brillo_en".
# Devuelve [posición, color] de cada píxel
static func pintar(dentro: Callable, n: int, colores: Dictionary, brillo_en: Vector2, brillo_r: float) -> Array:
	var pixeles := []
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * PIXEL
			var c := p + Vector2(PIXEL, PIXEL) / 2.0
			if dentro.call(c, 0.0):
				var color: Color = colores.medio
				if not dentro.call(c - Vector2(0, PIXEL), 0.0):
					color = colores.claro
				elif not dentro.call(c + Vector2(0, PIXEL), 0.0) or not dentro.call(c + Vector2(0, PIXEL * 2.0), 0.0):
					color = colores.oscuro
				if c.distance_to(brillo_en) < brillo_r:
					color = colores.brillo
				pixeles.append([p, color])
			elif dentro.call(c, PIXEL * 1.1):
				pixeles.append([p, colores.borde])
	return pixeles
