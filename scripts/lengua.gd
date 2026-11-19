# Las lenguas que pegan, pintadas con código: las del latigazo del Glotón y las de la criatura del científico mutado.
# Hacen lo mismo que los tentáculos (tentaculo.gd): apuntan y se paran en las paredes y los muebles, avisan con lo
# mismo que las cargas de los jefes (Aviso.franja) y se pintan como las de su dibujo, por capas, pero sin ventosas.
# Lo que cambia es la forma: durante el aviso no se pintan (las enrosca su dibujo por encima de la cabeza) y con el
# golpe salen disparadas de la boca, caen al suelo sobre el aviso culebreando y se recogen por el mismo camino.
class_name Lengua
extends Tentaculo

const SALE := 0.08         # lo que tardan en llegar al final
const RECOGE := 0.2        # lo que tardan en recogerse (lo último antes de acabar)

var culebrea := 7.0        # lo que culebrea a cada lado


# Lo que le da carne (19 nov): venas que la recorren, bultos y ampollas amarillas como los granos del Glotón. Cada
# lengua los tiene en su sitio (de la base a la punta, "s" de 0 a 1, y de un lado al otro, "lado" de -1 a 1)
const VENA := Color("#5a1838")          # morado oscuro (poco: que se vea carne, no rayas)
const VENA_CLARA := Color("#7a2a4a")
const BULTO := Color("#e07a66")
const BULTO_SOMBRA := Color("#8a2e28")
const AMPOLLA := Color("#c9c63c")
const AMPOLLA_SOMBRA := Color("#6c7a1c")
const AMPOLLA_BRILLO := Color("#f6f39a")

var con_detalles := true
var bultos := []     # [s, lado, tamaño]
var ampollas := []   # [s, lado, tamaño]


func _init(paleta: Dictionary) -> void:
	super(paleta)
	var azar := RandomNumberGenerator.new()
	azar.seed = hash(paleta.get("contorno", Color.BLACK)) + Lengua.cuantas
	Lengua.cuantas += 1
	for i in 6:
		bultos.append([azar.randf_range(0.08, 0.85), azar.randf_range(-0.6, 0.6), azar.randf_range(1.0, 2.0)])
	for i in 4:
		ampollas.append([azar.randf_range(0.12, 0.75), azar.randf_range(-0.35, 0.35), azar.randf_range(1.7, 2.4)])

static var cuantas := 0


# Un círculo de cuadraditos del dibujo, de "radio" píxeles del dibujo, en la cuadrícula
static func bola(lienzo: CanvasItem, centro: Vector2, radio: float, color: Color) -> void:
	var c := (centro / 2.0).floor()
	var n := int(floor(radio - 0.4))
	for y in range(-n, n + 1):
		var ancho := int(round(sqrt(maxf(0.0, radio * radio - y * y)) - 0.25))
		if ancho < 0:
			continue
		lienzo.draw_rect(Rect2((c + Vector2(-ancho, y)) * 2.0, Vector2(ancho * 2 + 1, 1) * 2.0), color)


# Un cuadradito del dibujo (2 × 2), en su sitio de la cuadrícula
static func pixel(lienzo: CanvasItem, p: Vector2, color: Color, tam := 1) -> void:
	lienzo.draw_rect(Rect2((p / 2.0).floor() * 2.0, Vector2(2, 2) * tam), color)


func pintar(lienzo: CanvasItem, puntos: PackedVector2Array, desde: int, hasta: int) -> void:
	super(lienzo, puntos, desde, hasta)
	if not con_detalles:
		return
	# el medio ancho y hacia un lado, en cada punto
	var r := PackedFloat32Array()
	var n := PackedVector2Array()
	for i in PUNTOS + 1:
		r.append((fino + (grueso - fino) * pow(1.0 - float(i) / PUNTOS, 0.8)) * gordo)
		n.append((puntos[mini(i + 1, PUNTOS)] - puntos[maxi(i - 1, 0)]).orthogonal().normalized())
	var donde := func(s: float, lado: float) -> Vector2:
		var f := s * PUNTOS
		var i := mini(int(f), PUNTOS - 1)
		var k := f - i
		var c := puntos[i].lerp(puntos[i + 1], k)
		return c + n[i].lerp(n[i + 1], k) * lado * lerpf(r[i], r[i + 1], k)
	# dos venas que van culebreando a lo largo, de la base hasta cerca de la punta
	for v in 2:
		var linea := PackedVector2Array()
		for j in range(maxi(desde, 1), mini(hasta, PUNTOS - 3) + 1):
			var s := float(j) / PUNTOS
			linea.append(donde.call(s, (0.35 if v == 0 else -0.45) + 0.25 * sin(s * 23.0 + v * 2.0)))
		if linea.size() > 1:
			lienzo.draw_polyline(linea, VENA, 2.0)
			# una rama que sale de cada vena
			var s0 := 0.3 + v * 0.2
			if s0 * PUNTOS >= desde and s0 * PUNTOS + 2 <= hasta:
				var a: Vector2 = donde.call(s0, (0.35 if v == 0 else -0.45))
				var b: Vector2 = donde.call(s0 + 0.06, (0.8 if v == 0 else -0.85))
				lienzo.draw_line(a, b, VENA_CLARA, 2.0)
	# bultos: carne más clara con su sombra debajo
	for b in bultos:
		if b[0] * PUNTOS < desde or b[0] * PUNTOS > hasta:
			continue
		var p: Vector2 = donde.call(b[0], b[1])
		var t := int(b[2] * gordo + 0.5)
		pixel(lienzo, p + Vector2(0, 2), BULTO_SOMBRA, maxi(1, t))
		pixel(lienzo, p, BULTO, maxi(1, t))
		pixel(lienzo, p - Vector2(0, 0), Color(1, 0.8, 0.72), 1)
	# ampollas: amarillas, con contorno oscuro, sombra abajo y un brillo
	for a in ampollas:
		if a[0] * PUNTOS < desde or a[0] * PUNTOS > hasta:
			continue
		var p: Vector2 = donde.call(a[0], a[1])
		var rr: float = a[2] * gordo   # (en píxeles del dibujo)
		if rr < 1.0:
			continue
		bola(lienzo, p, rr + 1.0, contorno)
		bola(lienzo, p, rr, AMPOLLA_SOMBRA)
		bola(lienzo, p - Vector2(0, 2), rr - 0.6, AMPOLLA)
		pixel(lienzo, p - Vector2(2, 4), AMPOLLA_BRILLO)


# Disparada de la boca ("raiz") hasta donde llega (si da con una pared, hasta ella): sale hacia delante, baja hasta
# el suelo y se tiende sobre el aviso (que empieza en "suelo"), con una onda que la recorre. Va saliendo por ese
# camino y se recoge por él hacia la boca. "t", lo que lleva desde el golpe; "dura", cuándo acaba de recogerse
func lanzada(raiz: Vector2, suelo: Vector2, t: float, dura: float) -> PackedVector2Array:
	var hacia := Vector2.from_angle(angulo)
	var punta := suelo + Vector2(0, -4) + hacia * llega
	# donde toca el suelo: siempre más allá de la boca (si va hacia arriba, la boca queda muy alta y, si no, la
	# lengua bajaría y volvería a subir); y al salir de la boca va hacia delante hasta la mitad de ese camino
	var boca := (raiz - suelo).dot(hacia)
	var hasta_codo := minf(maxf(llega * 0.45, boca + 50.0), llega * 0.8)
	var codo := suelo + Vector2(0, -4) + hacia * hasta_codo
	var sale := raiz + hacia * maxf(0.0, hasta_codo - boca) * 0.5
	var lado := (punta - raiz).orthogonal().normalized()
	var fuera := ease(minf(1.0, t / SALE), 0.5) * (1.0 - smoothstep(dura - RECOGE, dura, t))   # lo que tiene fuera
	var puntos := PackedVector2Array()
	for i in PUNTOS + 1:
		var s := fuera * i / PUNTOS
		var u := 1.0 - s
		var p := raiz * u * u * u + sale * 3.0 * u * u * s + codo * 3.0 * u * s * s + punta * s * s * s
		puntos.append(p + lado * sin(s * 9.0 - (t + desfase) * 35.0) * culebrea * sin(s * PI))
	return puntos


# Lo que le da cuerpo al golpe (19 nov: se veía plano). Por debajo del que la lanza: su sombra en el suelo, cada punto
# llevado a la línea del aviso (donde acaba cayendo), oscura y translúcida; así se ve que va por el aire hasta que cae
func sombra(lienzo: CanvasItem, puntos: PackedVector2Array, suelo: Vector2) -> void:
	var hacia := Vector2.from_angle(angulo)
	var lado := hacia.orthogonal()
	var en_suelo := PackedVector2Array()
	for p in puntos:
		var d := p - suelo
		en_suelo.append(suelo + hacia * maxf(0.0, d.dot(hacia)) + lado * d.dot(lado) * 0.5)
	silueta(lienzo, en_suelo, Color(0.05, 0.02, 0.02, 0.3), 1.0)


# Por encima, antes de pintarla: la estela del latigazo mientras sale disparada, dos siluetas claras de por dónde
# acaba de pasar, cada vez más flojas
func estela(lienzo: CanvasItem, raiz: Vector2, suelo: Vector2, t: float, dura: float) -> void:
	if t > SALE + 0.06:
		return
	var apaga := 1.0 - t / (SALE + 0.06)
	for atras in [0.035, 0.018]:
		if t - atras <= 0.0:
			continue
		silueta(lienzo, lanzada(raiz, suelo, t - atras, dura), Color(1.0, 0.86, 0.8, (0.18 if atras > 0.02 else 0.32) * apaga), 1.5)


# El chasquido donde la punta da en el suelo (efecto_suelo.gd, "latigazo"); "cuerpo", el que la lanza
func chasquido(cuerpo: Node2D, suelo: Vector2) -> void:
	EfectoSuelo.soltar(cuerpo.get_parent(), "latigazo", cuerpo.global_position + suelo + Vector2.from_angle(angulo) * llega)
