# El helicóptero de Velaria (trozo 6 de la parte 4, docs/historial/CENTRO_COMERCIAL.md). Cuando cae el gerente mutado,
# llega volando a la azotea a por el Sujeto 0 (Johnny), como decía la orden de recogida del dosier (historia.gd).
# Viene de fuera, por la derecha, bajando poco a poco, y se queda encima del helipuerto con el rotor girando y un
# foco que busca a Johnny por el suelo. No ataca: al rato suelta una escalera de cuerda hasta el suelo, en el centro
# del helipuerto, y en cuanto Johnny llega a ella se acaba el edificio (la señal "agarrada", que recoge partida.gd).
# El cuerpo es un dibujo de PixelLab (helicoptero.png, de tools/helicoptero.py): negro, con la raya verde y la hoja
# de Velaria. Lo que se mueve lo pinta el código encima: el rotor grande y el de la cola girando, y la luz roja de la
# aleta, que parpadea. El nodo está en el suelo (ahí va su sombra) y el aparato se pinta "altura" unidades más arriba.
# Se crea con Helicoptero.new(), poniéndole "destino" (el centro del helipuerto) y "johnny".
class_name Helicoptero
extends Node2D

signal escalera_lista   # la escalera ya llega al suelo
signal agarrada         # Johnny ha llegado a la punta de la escalera

const ALTURA := 170.0              # a qué altura se queda encima del helipuerto
const LLEGADA := 4.0               # lo que tarda en llegar desde fuera
const DESDE := Vector2(900, -420)  # de dónde viene, respecto al helipuerto
const DIBUJO := preload("res://assets/sprites/helicoptero.png")   # el cuerpo, sin las aspas (2 unidades por píxel)
# Sitios del dibujo, en sus píxeles (los da py tools/helicoptero.py al montarlo)
const ORIGEN := Vector2(48.0, 34.5)    # el centro de la cabina: lo que va a "altura" encima del nodo
const BUJE := Vector2(55.0, 1.0)       # la punta del mástil, donde gira el rotor grande
const COLA := Vector2(146.0, 20.0)     # el rotor pequeño, en el costado de la aleta
const LUZ_ROJA := Vector2(150.0, 3.0)  # en lo alto de la aleta
const ROTOR := 216.0               # lo largo de cada pala, en unidades
const FOCO_ALCANCE := 300.0        # lo lejos del helipuerto que llega a mirar el foco
const ESCALERA_ESPERA := 1.0       # lo que espera, ya quieto, a soltar la escalera
const ESCALERA_TIEMPO := 2.0       # lo que tarda en desenrollarse hasta el suelo
const ESCALERA_X := -12.0          # dónde cuelga, respecto al centro del helipuerto (de los patines)
const ESCALERA_ANCHO := 20.0       # lo ancha que es, entre cuerdas
const ALCANCE := 52.0              # lo cerca de la punta que hay que estar para agarrarse
const CUERDA := "#cfae72"
const CUERDA_SOMBRA := "#6e5632"
const PELDANO := "#8e6a38"
const PELDANO_LUZ := "#b88d4e"
const CONTORNO := "#0d0e12"

var destino := Vector2.ZERO
var johnny: Node2D
var t := 0.0
var altura := ALTURA
var llegado := false
var giro := 0.0                    # cómo va el rotor
var inclinado := 0.0               # al volar hacia delante, baja el morro
var foco_en := Vector2(-160, 40)   # adonde da el foco en el suelo (respecto a él)
var foco: PointLight2D
var rotor_t := 0.0                 # para el ruido del rotor
var quieto := 0.0                  # lo que lleva ya en su sitio, para soltar la escalera
var escalera := 0.0                # cuánto ha bajado la escalera: 0, recogida; 1, hasta el suelo
var cogida := false                # si ya se ha agarrado Johnny (solo una vez)


func _ready() -> void:
	z_index = 60   # vuela por encima de todo
	position = destino + DESDE
	# la luz del foco, en el suelo (alumbra el suelo y lo que haya encima: a Johnny, si le pilla)
	foco = PointLight2D.new()
	foco.texture = Luz.TEXTURA
	foco.texture_scale = 190.0 / 128.0
	foco.color = Color(1.0, 0.96, 0.82)
	foco.energy = 1.4
	foco.range_item_cull_mask = Luz.TODAS
	add_child(foco)


func _process(delta: float) -> void:
	t += delta
	giro += delta * 26.0
	if not llegado:
		# llega frenando, bajando y con el morro hacia abajo; al final se endereza
		var k := minf(1.0, t / LLEGADA)
		var e := 1.0 - pow(1.0 - k, 3.0)
		position = (destino + DESDE).lerp(destino, e)
		altura = lerpf(ALTURA + 140.0, ALTURA, e)
		inclinado = -0.16 * (1.0 - e)
		if k >= 1.0:
			llegado = true
	else:
		altura = ALTURA + sin(t * 2.0) * 4.0   # se mece un poco en el aire
		inclinado = 0.0   # (quieto, recto: un dibujo de píxeles girado tan poco sale con dientes)
		quieto += delta
		if quieto >= ESCALERA_ESPERA and escalera < 1.0:
			if escalera == 0.0:
				Sonido.tocar("cuerda")
			escalera = minf(1.0, escalera + delta / ESCALERA_TIEMPO)
			if escalera >= 1.0:
				Sonido.tocar("clonc")
				escalera_lista.emit()
		elif escalera >= 1.0 and not cogida and johnny and is_instance_valid(johnny) \
				and johnny.global_position.distance_to(punta()) < ALCANCE:
			cogida = true
			agarrada.emit()
	# el foco busca a Johnny (con retraso, y sin pasar de su alcance)
	var objetivo := foco_en
	if johnny and is_instance_valid(johnny):
		objetivo = (johnny.global_position - global_position).limit_length(FOCO_ALCANCE if llegado else FOCO_ALCANCE * 2.0)
	foco_en = foco_en.lerp(objetivo, 1.0 - exp(-delta * 1.6))
	foco.position = foco_en
	rotor_t -= delta
	if rotor_t <= 0.0:
		rotor_t = 0.42
		Sonido.tocar("rotor")
	queue_redraw()


# Dónde toca el suelo la escalera (en el mundo): lo que hay que pisar para agarrarse
func punta() -> Vector2:
	return global_position + Vector2(ESCALERA_X, 0.0)


# Cuánto se va de lado un punto de la escalera al mecerse (k: 0 arriba, 1 abajo)
func balanceo(k: float) -> float:
	return sin(t * 1.9 - k * 1.2) * 7.0 * k * escalera


func _draw() -> void:
	# la sombra en el suelo, más pequeña y clara cuanto más alto
	var s := clampf(1.0 - (altura - ALTURA) / 400.0, 0.55, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.26))
	draw_circle(Vector2.ZERO, 160.0 * s, Color(0, 0, 0, 0.3 * s))
	draw_set_transform(Vector2.ZERO)
	# el haz del foco: de la lámpara de debajo del morro al círculo del suelo
	var lampara := Vector2(-54, -altura + 33).rotated(inclinado)
	var lado := Vector2(70, 0)
	draw_colored_polygon(PackedVector2Array([lampara + Vector2(-6, 0), lampara + Vector2(6, 0), foco_en + lado,
		foco_en - lado]), Color(1, 0.96, 0.8, 0.16))
	draw_set_transform(foco_en, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 70.0, Color(1, 0.96, 0.8, 0.22))
	draw_set_transform(Vector2.ZERO)
	dibujar_escalera()
	cuerpo(Vector2(0, -roundf(altura / 2.0) * 2.0))   # (de 2 en 2, como sus píxeles)


# La escalera de cuerda, a cuadraditos de 2 unidades: cuelga de los patines y baja frenando hasta el suelo. Una vez
# abajo, un aro amarillo en el suelo marca hasta dónde hay que llegar
func dibujar_escalera() -> void:
	if escalera <= 0.0:
		return
	var arriba := -altura + 53.0
	var largo := (-2.0 - arriba) * (1.0 - pow(1.0 - escalera, 2.0))
	var filas := int(largo / 2.0)
	var mitad := ESCALERA_ANCHO / 2.0
	for i in filas:
		var y := arriba + i * 2.0
		var x := ESCALERA_X + roundf(balanceo(i * 2.0 / (-2.0 - arriba)) / 2.0) * 2.0
		draw_rect(Rect2(x - mitad, y, 2, 2), Color(CUERDA))
		draw_rect(Rect2(x - mitad + 2, y, 2, 2), Color(CUERDA_SOMBRA))
		draw_rect(Rect2(x + mitad - 4, y, 2, 2), Color(CUERDA))
		draw_rect(Rect2(x + mitad - 2, y, 2, 2), Color(CUERDA_SOMBRA))
		if i % 7 == 0:   # un peldaño cada 14
			draw_rect(Rect2(x - mitad, y, ESCALERA_ANCHO, 4), Color(PELDANO))
			draw_rect(Rect2(x - mitad, y, ESCALERA_ANCHO, 2), Color(PELDANO_LUZ))
	if escalera >= 1.0:
		# el aro del suelo, que late un poco: ahí hay que ponerse
		draw_set_transform(Vector2(ESCALERA_X, 0.0), 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, ALCANCE, 0.0, TAU, 40, Color(1.0, 0.85, 0.3, 0.5 + 0.25 * sin(t * 5.0)), 4.0)
		draw_set_transform(Vector2.ZERO)


# El aparato, mirando a la izquierda (por donde viene): el dibujo con el centro de la cabina en "donde" y, encima,
# los rotores girando y la luz de la aleta
func cuerpo(donde: Vector2) -> void:
	var en := func(p: Vector2) -> Vector2:   # un sitio del dibujo, en unidades (con el morro bajado, si va inclinado)
		return donde + ((p - ORIGEN) * 2.0).rotated(inclinado)
	draw_set_transform(donde, inclinado, Vector2(2, 2))
	draw_texture(DIBUJO, -ORIGEN)
	draw_set_transform(Vector2.ZERO)
	# el rotor de la cola: un disco borroso y una pala que gira
	var cola: Vector2 = en.call(COLA)
	var palita := Vector2.from_angle(giro * 1.6) * 21.0
	draw_circle(cola, 22.0, Color(0.7, 0.72, 0.76, 0.12))
	draw_line(cola - palita, cola + palita, Color(CONTORNO), 4.0)
	# el rotor grande: un disco borroso y dos palas que giran (visto un poco desde arriba)
	var buje: Vector2 = en.call(BUJE)
	draw_set_transform(buje, inclinado, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, ROTOR, Color(0.72, 0.75, 0.8, 0.16))
	draw_set_transform(Vector2.ZERO)
	for i in 2:
		var a := giro + i * PI
		var hasta := Vector2(cos(a) * ROTOR, sin(a) * ROTOR * 0.22).rotated(inclinado)
		draw_line(buje, buje + hasta, Color(CONTORNO, 0.9), 6.0)
	draw_rect(Rect2(buje - Vector2(6, 3), Vector2(12, 6)), Color(CONTORNO))
	# la luz roja de la aleta, que parpadea
	if fmod(t, 1.0) < 0.18:
		var luz: Vector2 = en.call(LUZ_ROJA)
		draw_rect(Rect2(luz - Vector2(2, 2), Vector2(4, 4)), Color("#ff3b3b"))
		draw_circle(luz, 9.0, Color(1, 0.2, 0.2, 0.3))
