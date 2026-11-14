# El tajo del golpe de un arma cuerpo a cuerpo mejorada (Armas.AURA; la Normal no deja): un haz de cuadraditos del color de
# su calidad (Armas.traza, los mismos tonos que la trazadora de las balas) que sigue el camino del arma en el dibujo del
# golpe y se apaga. Lo suelta Johnny al golpear (johnny.golpear) con el alcance y el abanico de lo que pega; va de hijo
# suyo, así que le sigue si anda. La punta va por delante, casi blanca, y la cola detrás, más oscura y más fina. Los
# cuadraditos son píxeles del dibujo (2 unidades) encajados en la cuadrícula del mundo, como los de la trazadora, y lucen
# por sí mismos (también a oscuras).
# El camino depende del gesto de cada arma (su "gesto" en Armas.DATOS), que es el de su dibujo:
#   "barrido"   de lado, a la altura del pecho, como batea un diestro: siempre de su derecha a su izquierda (el bate)
#   "caida"     de arriba abajo: desde encima de la cabeza hasta el suelo de delante (la fregona y la motosierra)
#   "subida"    de abajo arriba: desde la cadera hasta encima de la cabeza (la katana, que corta al desenvainar)
#   "estocada"  recto hacia delante, desde la mano (el cuchillo)
class_name Tajo
extends Node2D

const DURA := 0.17    # lo que tarda en barrer y apagarse
const PUNTA := 0.9    # lo lejos que llega, de lo que llega el golpe
# De cada gesto: "centro", desde dónde gira o sale (unidades desde el centro de Johnny: el pecho en el barrido, la cadera
# en los golpes de arriba abajo y el pecho en la estocada) y, en los que giran de arriba abajo, de qué altura a cuál va
# la punta (en grados: 0, recto hacia delante; 90, hacia el cielo; negativo, hacia el suelo)
const GESTOS := {
	"barrido": {"centro": Vector2(0, -34)},
	"caida": {"centro": Vector2(0, -24), "de": 100.0, "a": -42.0},
	"subida": {"centro": Vector2(0, -24), "de": -40.0, "a": 110.0},
	"estocada": {"centro": Vector2(0, -30), "de": 0.3, "a": 1.0},   # (aquí, de qué parte del alcance a cuál)
}

var gesto := "barrido"
var angulo := 0.0     # hacia dónde va el golpe (el centro del abanico)
var radio := 0.0      # lo lejos que llega la punta
var grueso := 1       # lo grueso que es, en píxeles del dibujo (Armas.AURA, "tajo")
var ini := 0.0        # por dónde empieza el haz y por dónde acaba: en el barrido, el ángulo sobre el suelo; en la caída y
var fin := 0.0        # la subida, la altura (en radianes); en la estocada, la parte del alcance
var tonos: Array
var t := 0.0


# El tajo de un golpe de "w" (los datos del arma con su calidad, johnny.arma()) hacia "hacia"
static func lanzar(johnny: Node2D, hacia: float, w: Dictionary) -> void:
	var calidad: int = w.get("calidad", 0)
	if calidad <= 0:
		return
	var tajo := Tajo.new()
	tajo.angulo = hacia
	tajo.radio = w.alcance * PUNTA
	tajo.grueso = Armas.AURA[calidad].tajo
	tajo.tonos = Armas.traza(calidad)
	tajo.gesto = w.get("gesto", "barrido")
	var g: Dictionary = GESTOS[tajo.gesto]
	tajo.position = g.centro
	if tajo.gesto == "barrido":
		# de su derecha a su izquierda (en la pantalla, la "y" va hacia abajo: su derecha es el ángulo de más)
		var mitad := deg_to_rad(w.arco) / 2.0
		tajo.ini = hacia + mitad
		tajo.fin = hacia - mitad
	elif tajo.gesto == "estocada":
		tajo.ini = g.de
		tajo.fin = g.a
	else:
		tajo.ini = deg_to_rad(g.de)
		tajo.fin = deg_to_rad(g.a)
	johnny.add_child(tajo)


func _ready() -> void:
	z_index = 4   # por encima de Johnny
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio


func _process(delta: float) -> void:
	t += delta
	if t >= DURA:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := t / DURA
	# la punta va rápido al principio (más despacio al llegar) y la cola la sigue y se la come
	var punta := lerpf(ini, fin, 1.0 - pow(1.0 - minf(k / 0.6, 1.0), 2.0))
	var cola := lerpf(ini, fin, pow(clampf((k - 0.1) / 0.9, 0.0, 1.0), 2.0))
	# (un cuadradito cada 1,4 unidades de camino: de arriba abajo, en la pantalla se estira hasta 1,4 veces)
	var pasos := ceili(absf(punta - cola) * radio / 1.4)
	var alfa := clampf((1.0 - k) * 2.0, 0.0, 1.0)
	for i in pasos + 1:
		var f := float(i) / maxf(pasos, 1)   # 0 en la punta, 1 en la cola
		var a := lerpf(punta, cola, f)
		var capas := maxi(1, roundi(grueso * (1.0 - 0.6 * f)) + (1 if f < 0.08 else 0))
		for j in capas:
			var c: Color = tonos[mini(4, int(f * 3.0) + j)]
			cuadradito(punto(a, j), Color(c, alfa))


# Dónde cae el cuadradito del sitio "a" del camino (lo que miden "ini" y "fin") en la capa "j" (0, la de fuera; cada una,
# un píxel del dibujo más adentro). La altura se pinta hacia arriba de la pantalla, como en todo el juego
func punto(a: float, j: int) -> Vector2:
	var delante := Vector2.from_angle(angulo)
	match gesto:
		"barrido":
			# (un círculo tumbado, visto desde arriba y de lado como el dibujo: la mitad de alto que de ancho)
			return Vector2.from_angle(a) * (radio - j * 2.0) * Vector2(1.0, 0.5)
		"estocada":
			# (las capas, a los dos lados de la línea: 0, +1, -1, +2...)
			var lado := ceili(j / 2.0) * (1.0 if j % 2 == 1 else -1.0) * 2.0
			return delante * radio * a + delante.orthogonal() * lado
	return (delante * cos(a) + Vector2(0, -sin(a))) * (radio - j * 2.0)


# Un cuadradito de un píxel del dibujo (2 unidades), con el centro en "centro", encajado en la cuadrícula del mundo
func cuadradito(centro: Vector2, color: Color) -> void:
	var esquina := ((global_position + centro - Vector2.ONE) / 2.0).round() * 2.0 - global_position
	draw_rect(Rect2(esquina, Vector2(2, 2)), color)
