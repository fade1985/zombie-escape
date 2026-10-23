# El Gymbro: uno de los cuatro minijefes de los Apartamentos (docs/JEFES_APARTAMENTOS.md, apartado 2). Un zombi
# de gimnasio musculoso a reventar, con los cuádriceps y las manos tan grandes que las arrastra por el suelo, calvo
# y con barba, la piel cayéndosele a cachos. Lo común de los minijefes, en minijefe.gd.
#
#   - Torbellino: marca en rojo por dónde irá (lo ancho de sus brazos) y sale girando con los brazos abiertos en
#     línea recta. Si pilla a Johnny le quita 20 y le tira (esquivando, le pasa de largo). Si se come una pared,
#     se queda mareado (¡a por él!).
#   - Salto: se agacha y salta hacia Johnny. Mientras está en el aire (1,1 s) se ve en el suelo la zona donde va a
#     caer (una sombra con el borde rojo, de 400 de ancho); al caer, si Johnny está dentro, le quita 24 y le tira.
#     En el aire no se le puede dar.
#   - Pesas: lanza mancuernas en curva (pesa.gd) a donde está Johnny y a donde va a estar, cada una con su marca
#     roja en el suelo.
# Enfadado (a media vida, «¡HORA DE LOS SUPLEMENTOS!»): se toma sus suplementos y le sale una barra de armadura
# encima de la de vida; mientras le quede armadura, solo le entra a la vida la mitad del daño (la otra mitad se la
# come la armadura). Además: hasta 2 torbellinos seguidos, el salto dura la mitad y el doble de pesas.
extends Minijefe

signal armadura_cambiada(armadura: int, maxima: int)   # la barra de armadura de la pantalla (partida.gd)

const VELOCIDAD := 75.0
const AVISO_TORBELLINO := [0.7, 0.45]   # normal y enfadado (el segundo torbellino seguido, aún menos)
const VELOCIDAD_TORBELLINO := 400.0
const TIEMPO_TORBELLINO := 1.1          # lo que gira como mucho
const DANO_TORBELLINO := 20
const BRAZOS := 56.0                    # hasta dónde llegan sus brazos abiertos (desde el centro)
const TORBELLINOS := [1, 2]             # cuántos seguidos
const MAREADO := 1.6
const AGACHARSE := 0.45
const VUELO := [1.1, 0.55]              # lo que está en el aire (enfadado, la mitad)
const ALTURA_SALTO := 170.0
const RADIO_SALTO := 200.0              # la zona donde cae: de lado a lado, el doble (de arriba abajo, el 60 %)
const DANO_SALTO := 24
const PESAS := [2, 4]                   # cuántas lanza de una vez
const VUELO_PESA := 0.9
const DANO_PESA := 18
const ARMADURA := 0.3                   # la armadura de los suplementos (parte de su vida máxima)
const PIE := 30.0                       # a qué altura dibuja los pies respecto a su centro
const ACERO := Color("#9fc3e8")
# Los fotogramas de sus animaciones de PixelLab (assets/pixellab.json → apartamentos-jefes → gymbro-72):
# el torbellino gira de GIRO_DESDE al final (antes levanta los brazos); el salto se agacha hasta DESPEGUE, va por
# el aire hasta ATERRIZA y luego cae; las pesas salen de la mano en SUELTA
const GIRO_DESDE := 1
const DESPEGUE := 4
const ATERRIZA := 8
const SUELTA := 4

var espera_torbellino := 1.5
var espera_salto := 3.5
var espera_pesas := 2.5
var armadura := 0
var armadura_max := 0


func pensar(delta: float, johnny: Node2D) -> void:
	espera_torbellino -= delta
	espera_salto -= delta
	espera_pesas -= delta
	match estado:
		"andar":
			perseguir(delta, johnny, VELOCIDAD)
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if t >= dur:
				elegir(johnny)
		"aviso_torbellino":
			# abre los brazos; la franja roja marca por dónde irá (ya no cambia de idea)
			frenar(delta, 12.0)
			if t >= datos.aviso:
				cambiar("torbellino", {"quedan": datos.quedan - 1})
				Sonido.tocar("rugido")
		"torbellino":
			match girar(delta, johnny):
				"pillado":
					cambiar("recuperar", {"dur": 0.5, "quedan": datos.quedan})
				"pared":
					estrellarse()
				"fin":
					marcha *= 0.3
					cambiar("recuperar", {"dur": 0.4, "quedan": datos.quedan})
		"recuperar":
			frenar(delta, 5.0)
			if t >= datos.dur:
				if datos.quedan > 0:
					apuntar(johnny, datos.quedan, AVISO_TORBELLINO[1] * 0.75)
				else:
					andar(0.6 if enfadado() else 1.0)
		"atontado":
			frenar(delta, 4.0)
			if t >= MAREADO:
				andar(0.4)
		"agacharse":
			frenar(delta, 12.0)
			if t >= AGACHARSE:
				despegar(johnny)
		"salto":
			# por el aire, de donde estaba a donde cae (sin chocar con nada)
			invulnerable = true
			contacto = 0
			marcha = Vector2.ZERO
			global_position = datos.desde.lerp(datos.hasta, minf(1.0, t / datos.vuelo))
			if t >= datos.vuelo:
				aterrizar(johnny)
		"aterrizar":
			frenar(delta, 10.0)
			if t >= 0.5:
				andar(0.5 if enfadado() else 0.8)
		"pesas":
			frenar(delta, 12.0)
			if not datos.lanzado and sprite.frame >= SUELTA:
				datos.lanzado = true
				lanzar_pesas(johnny)
			if t >= 0.9:
				andar(0.5 if enfadado() else 0.8)


func elegir(johnny: Node2D) -> void:
	var d := global_position.distance_to(johnny.global_position)
	var gira := espera_torbellino <= 0.0 and d > 90.0 and d < 460.0
	var salta := espera_salto <= 0.0 and d > 120.0 and d < 450.0
	var lanza := espera_pesas <= 0.0 and d > 160.0
	if gira and (not (salta or lanza) or randf() < 0.45):
		espera_torbellino = 2.8 if enfadado() else 3.6
		apuntar(johnny, TORBELLINOS[fase - 1], AVISO_TORBELLINO[fase - 1])
		gritar("¡NO PAIN, NO GAIN!", Color("#ff5d73"), 20)
		return
	if salta and (not lanza or randf() < 0.5):
		espera_salto = 3.5 if enfadado() else 5.0
		cambiar("agacharse")
		return
	if lanza:
		espera_pesas = 3.0 if enfadado() else 4.2
		mirada = global_position.direction_to(johnny.global_position)
		cambiar("pesas", {"lanzado": false})
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# ── El torbellino ──

# Se pone mirando a Johnny y avisa el torbellino (la franja ya no se mueve)
func apuntar(johnny: Node2D, quedan: int, aviso: float) -> void:
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia != Vector2.ZERO:
		mirada = hacia.normalized()
	marcha = Vector2.ZERO
	cambiar("aviso_torbellino", {"quedan": quedan, "aviso": aviso})


# Como embestir() de minijefe.gd, pero le pilla con los brazos abiertos (llega más lejos a los lados)
func girar(delta: float, johnny: Node2D) -> String:
	marcha = mirada * VELOCIDAD_TORBELLINO
	contacto = 0   # el golpe ya lo da el torbellino
	if randf() < delta * 30.0:
		Particulas.soltar(self, global_position + Vector2(randf_range(-40, 40), PIE), Vector2(randf_range(-60, 60), -20),
			Color("#8a7a66"), 3, 0.4)
	var d := global_position.distance_to(johnny.global_position)
	if d < BRAZOS + johnny.RADIO and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(DANO_TORBELLINO, self)
		# le lanza hacia un lado, como un manotazo
		var lado: Vector2 = mirada.orthogonal() * signf(mirada.orthogonal().dot(johnny.global_position - global_position) + 0.01)
		johnny.empujar((mirada + lado).normalized() * 900.0)
		johnny.pisar({"tirado": {}})
		Temblor.temblar(10.0)
		Sonido.tocar("golpe")
		marcha *= 0.2
		return "pillado"
	if t > 0.12 and get_real_velocity().length() < VELOCIDAD_TORBELLINO * 0.4:
		return "pared"
	if t >= TIEMPO_TORBELLINO:
		return "fin"
	return ""


# ── El salto ──

# Salta hacia donde está Johnny (lo más cerca que se pueda andar: no cae dentro de un mueble)
func despegar(johnny: Node2D) -> void:
	var hasta: Vector2 = johnny.global_position
	var cerca := NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), hasta)
	if cerca.distance_to(hasta) < 60.0:
		hasta = cerca
	if hasta != global_position:
		mirada = global_position.direction_to(hasta)
	cambiar("salto", {"desde": global_position, "hasta": hasta, "vuelo": VUELO[fase - 1]})
	invulnerable = true
	$Choque.set_deferred("disabled", true)
	Sonido.tocar("rugido")


func aterrizar(johnny: Node2D) -> void:
	global_position = datos.hasta
	$Choque.set_deferred("disabled", false)
	cambiar("aterrizar")
	Sonido.tocar("pisoton")
	Temblor.temblar(14.0)
	# el polvo sale hacia los lados y la onda se abre hasta el borde de la zona
	for i in 16:
		var a := i * TAU / 16.0
		Particulas.soltar(self, global_position + Vector2(cos(a) * 34.0, PIE + sin(a) * 16.0),
			Vector2(cos(a), sin(a) * 0.6) * RADIO_SALTO * 2.0, Color("#8a7a66"), 4, 0.5)
	Particulas.anillo(self, global_position + Vector2(0, PIE - 6), RADIO_SALTO, Color("#b3a58c"), 0.35)
	var hacia: Vector2 = johnny.global_position - global_position
	if en_la_zona(johnny.global_position + Vector2(0, 16), johnny.RADIO * 0.6) and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(DANO_SALTO, self)
		johnny.empujar((hacia.normalized() if hacia != Vector2.ZERO else Vector2.DOWN) * 700.0)
		johnny.pisar({"tirado": {}})


# La zona del salto es la que se ve en el suelo, a sus pies donde cae: una elipse (el suelo se ve un poco desde
# arriba, como la marca de las pesas). Le da a Johnny si tiene los pies (su sombra) dentro, con "margen" de más
# por lo que ocupa él
func en_la_zona(pies: Vector2, margen: float) -> bool:
	var d := pies - (global_position + Vector2(0, PIE - 6))
	var r := RADIO_SALTO + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


# ── Las pesas ──

# La primera, a donde está Johnny; la segunda, a donde va a estar si sigue andando igual; enfadado, dos más
# alrededor de él
func lanzar_pesas(johnny: Node2D) -> void:
	Sonido.tocar("latigazo")
	var mano := global_position + Vector2(mirada.x * 30.0, -arriba * 0.5)
	var donde: Array = [johnny.global_position, johnny.global_position + johnny.velocity * VUELO_PESA]
	for i in PESAS[fase - 1] - 2:
		donde.append(johnny.global_position + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 120.0))
	for i in donde.size():
		var pesa := Pesa.new()
		pesa.dueno = self
		pesa.desde = mano
		# donde se pueda estar (no dentro de una pared o un mueble)
		pesa.hasta = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), donde[i])
		pesa.vuelo = VUELO_PESA + i * 0.12   # una detrás de otra
		pesa.dano = DANO_PESA
		get_parent().add_child(pesa)


# ── Los suplementos (la armadura) ──

func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡HORA DE LOS SUPLEMENTOS!")
	armadura_max = int(vida_max * ARMADURA)
	armadura = armadura_max
	armadura_cambiada.emit(armadura, armadura_max)
	for i in 12:
		Particulas.soltar(self, global_position + Vector2(randf_range(-30, 30), -arriba * 0.7),
			Vector2(randf_range(-80, 80), randf_range(-120, -40)), ACERO, 3, 0.6)


# Con armadura, a la vida solo le llega la mitad; la otra mitad se la come la armadura
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	if armadura <= 0:
		return cantidad
	var a_la_armadura := mini(armadura, cantidad / 2)
	armadura -= a_la_armadura
	armadura_cambiada.emit(armadura, armadura_max)
	if armadura <= 0:
		gritar("¡SIN SUPLEMENTOS!", ACERO, 18)
		Sonido.tocar("cristal")
	return cantidad - a_la_armadura


# En la foto de la prueba (--captura): girando en el torbellino, hacia Johnny
func foto(johnny: Node2D) -> void:
	apuntar(johnny, 1, AVISO_TORBELLINO[0])
	t = AVISO_TORBELLINO[0] * 0.8


# Si cae en mitad de un salto o mareado, que caiga en el suelo y derecho
func morir() -> void:
	sprite.position = Vector2(0, PIE)
	sprite.rotation = 0.0
	$Choque.set_deferred("disabled", false)
	super()
	armadura_cambiada.emit(0, maxi(1, armadura_max))


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	sprite.rotation = 0.0
	match estado:
		"aviso_torbellino":
			# levanta los brazos, a punto de girar
			fijar("torbellino", "s", int(minf(1.0, t / datos.aviso) * GIRO_DESDE))
			sprite.position.x = sin(tiempo * 40.0) * 2.0
		"torbellino":
			var total := sprite.sprite_frames.get_frame_count("torbellino_s")
			fijar("torbellino", "s", GIRO_DESDE + int(t * 22.0) % maxi(1, total - GIRO_DESDE))
		"atontado":
			# mareado: se tambalea de un lado a otro
			fijar("golpe", dir, avance("golpe_" + dir, minf(1.0, t / 0.5) * 0.6))
			sprite.position.x = sin(tiempo * 6.0) * 4.0
			sprite.rotation = sin(tiempo * 6.0) * 0.08
		"agacharse":
			fijar("salto", dir, int(t / AGACHARSE * DESPEGUE))
		"salto":
			var k := minf(1.0, t / datos.vuelo)
			fijar("salto", dir, DESPEGUE + int(k * (ATERRIZA - DESPEGUE)))
			sprite.position.y = PIE - sin(k * PI) * ALTURA_SALTO
		"aterrizar":
			var resto := sprite.sprite_frames.get_frame_count("salto_" + dir) - ATERRIZA
			fijar("salto", dir, ATERRIZA + clampi(int(t / 0.5 * resto), 0, maxi(0, resto - 1)))
		"pesas":
			fijar("lanzar", dir, avance("lanzar_" + dir, t / 0.9))
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


# Los avisos, en el suelo (por debajo de él): la franja del torbellino (tan ancha como sus brazos), el círculo
# que barre girando y la zona del salto (la sombra de donde va a caer, que se agranda, y su borde rojo: lo que
# golpea, en_la_zona())
func _draw() -> void:
	if estado == "muerto":
		return
	var rojo := Color(1, 0.24, 0.35)
	match estado:
		"aviso_torbellino":
			var k := minf(1.0, t / datos.aviso)
			var largo := VELOCIDAD_TORBELLINO * TIEMPO_TORBELLINO
			draw_set_transform(Vector2(0, 6), mirada.angle())
			draw_rect(Rect2(0, -BRAZOS, largo, BRAZOS * 2.0), Color(rojo, 0.08 + k * 0.2))
			draw_rect(Rect2(0, -BRAZOS, largo * k, BRAZOS * 2.0), Color(rojo, 0.9), false, 3.0)
		"torbellino":
			# el remolino: arcos que dan vueltas a la altura de los brazos
			draw_set_transform(Vector2(0, PIE - 6), 0.0, Vector2(1, 0.6))
			for i in 3:
				var a := tiempo * 14.0 + i * TAU / 3.0
				draw_arc(Vector2.ZERO, BRAZOS, a, a + 1.4, 12, Color(1, 1, 1, 0.5), 4.0)
		"salto":
			var k := minf(1.0, t / datos.vuelo)
			draw_set_transform(datos.hasta - global_position + Vector2(0, PIE - 6), 0.0, Vector2(1, 0.6))
			draw_circle(Vector2.ZERO, RADIO_SALTO * (0.35 + 0.65 * k), Color(0, 0, 0, 0.2 + 0.3 * k))
			draw_arc(Vector2.ZERO, RADIO_SALTO, 0.0, TAU, 64, Color(rojo, 0.4 + 0.5 * k), 3.0)
	draw_set_transform(Vector2.ZERO)


# Con armadura, un brillo azul de acero que le rodea (por encima de él)
func pintar_encima(lienzo: Node2D) -> void:
	if armadura <= 0 or estado == "salto":
		return
	var brillo := 0.5 + 0.2 * sin(tiempo * 6.0)
	lienzo.draw_set_transform(Vector2(0, -arriba * 0.45), 0.0, Vector2(1, 1.3))
	lienzo.draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 32, Color(ACERO, brillo), 4.0)
	lienzo.draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 32, Color(ACERO, brillo * 0.4), 2.0)
	lienzo.draw_set_transform(Vector2.ZERO)
