# El tajo del golpe de un arma cuerpo a cuerpo mejorada (Armas.AURA; la Normal no deja): una media luna de cuadraditos del
# color de su calidad (Armas.traza, los mismos tonos que la trazadora de las balas) que barre el abanico del golpe de un lado
# al otro y se apaga. Lo suelta Johnny al golpear (johnny.golpear) con el alcance y el abanico de lo que pega; va de hija
# suya, así que le sigue si anda. La punta va por delante, casi blanca, y la cola detrás, más oscura y más fina. Cada golpe
# barre hacia un lado (se van alternando, como un vaivén). Los cuadraditos son píxeles del dibujo (2 unidades) encajados en la
# cuadrícula del mundo, como los de la trazadora, y lucen por sí mismos (también a oscuras).
class_name Tajo
extends Node2D

const DURA := 0.17    # lo que tarda en barrer y apagarse
const ALTO := -6.0    # a qué altura del centro de Johnny gira (la del pecho)
const PUNTA := 0.9    # lo lejos que llega, de lo que llega el golpe

static var lado := 1.0   # hacia dónde barre este golpe: 1, a derechas; -1, a izquierdas (se alterna en cada uno)

var angulo := 0.0     # hacia dónde va el golpe (el centro del abanico)
var arco := 0.0       # lo que abre el abanico, en radianes
var radio := 0.0      # lo lejos que llega la punta
var grueso := 1       # lo grueso que es, en píxeles del dibujo (Armas.AURA, "tajo")
var sentido := 1.0
var tonos: Array
var t := 0.0


# El tajo de un golpe de "w" (los datos del arma con su calidad, johnny.arma()) hacia "hacia"
static func lanzar(johnny: Node2D, hacia: float, w: Dictionary) -> void:
	var calidad: int = w.get("calidad", 0)
	if calidad <= 0:
		return
	var tajo := Tajo.new()
	tajo.angulo = hacia
	tajo.arco = deg_to_rad(w.arco)
	tajo.radio = w.alcance * PUNTA
	tajo.grueso = Armas.AURA[calidad].tajo
	tajo.tonos = Armas.traza(calidad)
	tajo.sentido = lado
	lado = -lado
	johnny.add_child(tajo)


func _ready() -> void:
	position = Vector2(0, ALTO)
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
	var ini := angulo - sentido * arco / 2.0   # donde empieza el barrido
	# la punta barre rápido al principio (más despacio al llegar) y la cola la sigue y se la come
	var punta := ini + sentido * arco * (1.0 - pow(1.0 - minf(k / 0.6, 1.0), 2.0))
	var cola := ini + sentido * arco * pow(clampf((k - 0.1) / 0.9, 0.0, 1.0), 2.0)
	var pasos := ceili(absf(punta - cola) * radio / 2.0)
	var alfa := clampf((1.0 - k) * 2.0, 0.0, 1.0)
	for i in pasos + 1:
		var f := float(i) / maxf(pasos, 1)   # 0 en la punta, 1 en la cola
		var a := lerpf(punta, cola, f)
		var capas := maxi(1, roundi(grueso * (1.0 - 0.6 * f)) + (1 if f < 0.08 else 0))
		for j in capas:
			var c: Color = tonos[mini(4, int(f * 3.0) + j)]
			cuadradito(Vector2.from_angle(a) * (radio - j * 2.0), Color(c, alfa))


# Un cuadradito de un píxel del dibujo (2 unidades), con el centro en "centro", encajado en la cuadrícula del mundo
func cuadradito(centro: Vector2, color: Color) -> void:
	var esquina := ((global_position + centro - Vector2.ONE) / 2.0).round() * 2.0 - global_position
	draw_rect(Rect2(esquina, Vector2(2, 2)), color)
