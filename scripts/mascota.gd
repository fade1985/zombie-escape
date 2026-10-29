# La mascota: uno de los cuatro minijefes del centro comercial (su tienda, la Juguetería). Un oso de peluche
# gigante, amarillo y sucio, con la cara del zombi dentro de la cabeza. Lo común de los minijefes, en minijefe.gd.
#
# Es rápida y hace dos cosas:
#   - Embestida: marca una franja roja en el suelo (0,6 s) y sale disparada en línea recta. Si pilla a Johnny le
#     quita 22 y le tira; esquivando, le pasa de largo; si se estrella contra una pared o un mueble, se queda
#     mareada 1,8 s, con estrellitas (¡a por ella!). La carrera es la misma que la carga del antidisturbios.
#   - Salto: se agacha y salta hacia donde está Johnny. Mientras vuela (0,8 s) se ve en el suelo su sombra,
#     creciendo, donde va a caer; al caer quita 18 a lo que esté en ese círculo. En el aire no se le puede dar.
# Enfadada (a media vida): 3 embestidas seguidas con menos aviso; si choca con una pared rebota y, tras un aviso corto
# con su franja (AVISO_REBOTE), sigue; solo se marea si se estrella en la última.
extends Minijefe

const VELOCIDAD := 140.0
const AVISO_EMBESTIDA := [0.6, 0.4]    # normal y enfadada
const AVISO_REBOTE := 0.3              # enfadada, al rebotar en una pared (hasta el 27 oct, sin aviso ni franja)
const VELOCIDAD_EMBESTIDA := 520.0
const TIEMPO_EMBESTIDA := 1.1          # lo que corre como mucho
const DANO_EMBESTIDA := 22
const EMBESTIDAS := [1, 3]             # cuántas seguidas (normal y enfadada)
const MAREADA := 1.8
const AGACHARSE := 0.35                # lo que tarda en coger impulso antes de saltar
const VUELO := 0.8                     # lo que está en el aire (lo que se ve la sombra antes de caer)
const ALTURA_SALTO := 150.0
const RADIO_SALTO := 90.0
const DANO_SALTO := 18
const PIE := 30.0                      # a qué altura dibuja los pies respecto a su centro
# Los fotogramas de su animación de salto: hasta DESPEGUE se agacha, de ahí a ATERRIZA va por el aire y luego cae
# (en la de PixelLab: 0-3 se agacha, 4-8 en el aire con las zarpas arriba, 9-12 cae y se levanta)
const DESPEGUE := 4
const ATERRIZA := 9

var espera_embestida := 1.5
var espera_salto := 3.0


func pensar(delta: float, johnny: Node2D) -> void:
	espera_embestida -= delta
	espera_salto -= delta
	match estado:
		"andar":
			perseguir(delta, johnny, VELOCIDAD)
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if t >= dur:
				elegir(johnny)
		"aviso_embestida":
			# rasca el suelo como un toro; la franja roja marca por dónde irá (ya no cambia de idea)
			frenar(delta, 12.0)
			if t >= datos.aviso:
				cambiar("embestida", {"quedan": datos.quedan - 1})
				Sonido.tocar("rugido")
		"embestida":
			match embestir(delta, johnny, VELOCIDAD_EMBESTIDA, DANO_EMBESTIDA, TIEMPO_EMBESTIDA, PIE):
				"pillado":
					cambiar("recuperar", {"dur": 0.5, "quedan": datos.quedan})
				"pared":
					if datos.quedan > 0:
						rebotar()
					else:
						estrellarse()
				"fin":
					marcha *= 0.3
					cambiar("recuperar", {"dur": 0.4, "quedan": datos.quedan})
		"recuperar":
			frenar(delta, 5.0)
			if t >= datos.dur:
				if datos.quedan > 0:
					apuntar(johnny, datos.quedan, AVISO_EMBESTIDA[1] * 0.75)
				else:
					andar(0.6 if enfadado() else 1.0)
		"atontado":
			frenar(delta, 4.0)
			if t >= MAREADA:
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
			global_position = datos.desde.lerp(datos.hasta, minf(1.0, t / VUELO))
			if t >= VUELO:
				aterrizar(johnny)
		"aterrizar":
			frenar(delta, 10.0)
			if t >= 0.5:
				andar(0.5 if enfadado() else 0.8)


func elegir(johnny: Node2D) -> void:
	var d := global_position.distance_to(johnny.global_position)
	var embiste := espera_embestida <= 0.0 and d > 160.0
	var salta := espera_salto <= 0.0 and d > 90.0 and d < 420.0
	if embiste and (not salta or randf() < 0.55):
		espera_embestida = 2.5 if enfadado() else 3.2
		apuntar(johnny, EMBESTIDAS[fase - 1], AVISO_EMBESTIDA[fase - 1])
		gritar(Idioma.t("¡ABRAZOS GRATIS!"), Color("#ff5d73"), 20)
		return
	if salta:
		espera_salto = 3.0 if enfadado() else 4.0
		cambiar("agacharse")
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# Se pone mirando a Johnny y avisa la embestida (la franja ya no se mueve)
func apuntar(johnny: Node2D, quedan: int, aviso: float) -> void:
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia != Vector2.ZERO:
		mirada = hacia.normalized()
	marcha = Vector2.ZERO
	cambiar("aviso_embestida", {"quedan": quedan, "aviso": aviso})


# Enfadada, al chocar con una pared rebota como una pelota: marca la franja de por dónde sale y sigue corriendo
func rebotar() -> void:
	var pared := pared_chocada()
	mirada = mirada.bounce(pared).normalized()
	if mirada.dot(pared) < 0.2:   # rozando la pared: mejor que salga hacia fuera
		mirada = (mirada + pared).normalized()
	global_position += pared * 4.0
	marcha = Vector2.ZERO
	cambiar("aviso_embestida", {"quedan": datos.quedan, "aviso": AVISO_REBOTE})
	Sonido.tocar("boing")
	Temblor.temblar(5.0)
	gritar(Idioma.t("¡BOING!"), Color("#ffd23f"), 18)


# Salta hacia donde está Johnny (lo más cerca que se pueda andar: no cae dentro de un mueble)
func despegar(johnny: Node2D) -> void:
	var hasta: Vector2 = johnny.global_position
	var cerca := NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), hasta)
	if cerca.distance_to(hasta) < 60.0:
		hasta = cerca
	if hasta != global_position:
		mirada = global_position.direction_to(hasta)
	cambiar("salto", {"desde": global_position, "hasta": hasta})
	invulnerable = true
	$Choque.set_deferred("disabled", true)
	Sonido.tocar("boing")


func aterrizar(johnny: Node2D) -> void:
	global_position = datos.hasta
	$Choque.set_deferred("disabled", false)
	cambiar("aterrizar")
	Sonido.tocar("pisoton")
	Temblor.temblar(12.0)
	for i in 14:
		var a := i * TAU / 14.0
		Particulas.soltar(self, global_position + Vector2(cos(a) * 30.0, PIE + sin(a) * 14.0),
			Vector2(cos(a) * 160.0, sin(a) * 70.0), Color("#8a7a66"), 4, 0.5)
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < RADIO_SALTO + johnny.RADIO and johnny.esquiva_t <= 0.0 \
			and not Aviso.tapado(self, johnny.global_position + Vector2(0, 16), Vector2(0, PIE - 6)):
		johnny.recibir_dano(DANO_SALTO, self)
		johnny.empujar((hacia.normalized() if hacia != Vector2.ZERO else Vector2.DOWN) * 600.0)


# Si cae en mitad de un salto o mareada, que caiga en el suelo y derecha
func morir() -> void:
	sprite.position = Vector2(0, PIE)
	sprite.rotation = 0.0
	$Choque.set_deferred("disabled", false)
	super()


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡HORA DE JUGAR!"))


# En la foto de la prueba (--captura): saltando, con su sombra en el suelo donde va a caer
func foto(johnny: Node2D) -> void:
	cambiar("agacharse")
	t = AGACHARSE
	despegar(johnny)
	t = VUELO * 0.45


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	sprite.rotation = 0.0
	match estado:
		"aviso_embestida":
			# rascando el suelo, a punto de salir
			fijar("embestida", dir, 0)
			sprite.position.x = sin(tiempo * 40.0) * 2.0
		"embestida":
			poner("embestida_" + dir, 1.5)
		"atontado":
			# mareada: se tambalea de un lado a otro
			fijar("golpe", dir, avance("golpe_" + dir, minf(1.0, t / 0.5) * 0.6))
			sprite.position.x = sin(tiempo * 6.0) * 4.0
			sprite.rotation = sin(tiempo * 6.0) * 0.08
		"agacharse":
			fijar("salto", dir, int(t / AGACHARSE * DESPEGUE))
		"salto":
			var k := minf(1.0, t / VUELO)
			fijar("salto", dir, DESPEGUE + int(k * (ATERRIZA - DESPEGUE)))
			sprite.position.y = PIE - sin(k * PI) * ALTURA_SALTO
		"aterrizar":
			var resto := sprite.sprite_frames.get_frame_count("salto_" + dir) - ATERRIZA
			fijar("salto", dir, ATERRIZA + clampi(int(t / 0.5 * resto), 0, maxi(0, resto - 1)))
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


# Los avisos, en el suelo (por debajo de ella): la franja de la embestida y la sombra de donde va a caer
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_embestida":
			franja(VELOCIDAD_EMBESTIDA * TIEMPO_EMBESTIDA, minf(1.0, t / datos.aviso))
		"salto":
			# donde cae: el círculo se llena hacia fuera y su sombra crece en el medio (aviso.gd)
			var k := minf(1.0, t / VUELO)
			Aviso.golpe(self, datos.hasta - global_position + Vector2(0, PIE - 6), 0.0, PI, RADIO_SALTO, k, tiempo,
				0.6, 0.3 + 0.4 * k)
