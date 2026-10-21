# El antidisturbios: uno de los cuatro minijefes del centro comercial (su tienda, la Oficina de seguridad). Un
# policía zombi enorme con casco, porra y un escudo transparente. Lo común de los minijefes, en minijefe.gd.
#
# Es lento y gira despacio, y el escudo le tapa por delante:
#   - De frente, las balas y los golpes rebotan en el escudo («¡CLONC!» y chispas). De lado le haces el daño
#     normal, y por la espalda, el doble. Las explosiones (granadas) y el fuego (molotov) le dan por todos lados.
#   - Porrazo: si Johnny está cerca y delante, marca en rojo un trozo de suelo (medio segundo) y golpea: 18 y empuja.
#   - Carga: marca una franja roja y corre en línea recta con el escudo por delante. Si pilla a Johnny le quita
#     20 y le tira; si se estrella contra una pared o un mueble, se queda atontado 2 s (¡a por su espalda!).
#   - Silbato: llegan 2 refuerzos.
# Enfadado (a media vida): gira más deprisa, carga dos veces seguidas y llama a 3.
extends Minijefe

const REFUERZO := "vigilante"
const REFUERZOS := [2, 3]          # cuántos llegan al silbato (normal y enfadado)
const VELOCIDAD := 70.0
const GIRO := [1.4, 2.4]           # lo deprisa que se gira, en radianes por segundo (normal y enfadado)
# El escudo: medio ángulo de lo que tapa por delante; por detrás, lo mismo es la espalda (el doble de daño)
const FRENTE := PI / 3.0
const ESPALDA := PI / 3.0
const AVISO_PORRAZO := 0.5
const ALCANCE_PORRAZO := 115.0
const MEDIO_PORRAZO := 0.85        # medio ángulo del trozo que barre
const DANO_PORRAZO := 18
const DISTANCIA_PORRAZO := 150.0   # si Johnny está más cerca que esto (y delante), prefiere el porrazo
const AVISO_CARGA := [0.8, 0.5]    # la primera carga y la segunda seguida (enfadado)
const VELOCIDAD_CARGA := 400.0
const TIEMPO_CARGA := 1.3          # lo que corre como mucho
const DANO_CARGA := 20
const ATONTADO := 2.0              # lo que se queda atontado al estrellarse
const CARGAS := [1, 2]             # cuántas seguidas
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
const GOLPE_PORRAZO := 4           # fotograma del porrazo en el que la porra baja (ajustar con su animación)

var espera_porrazo := 1.0
var espera_carga := 2.5
var espera_silbato := 5.0
var clonc_t := 0.0                 # para no llenar la pantalla de «¡CLONC!» con los perdigones de la escopeta


func pensar(delta: float, johnny: Node2D) -> void:
	espera_porrazo -= delta
	espera_carga -= delta
	espera_silbato -= delta
	clonc_t -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			# solo anda hacia delante: para ir hacia Johnny tiene que girarse (y se gira despacio)
			var quiere := camino_a(johnny)
			girar_hacia(delta, quiere)
			var alineado := maxf(0.0, mirada.dot(quiere))
			marcha += (mirada * VELOCIDAD * (0.25 + 0.75 * alineado) - marcha) * (1.0 - exp(-delta * 6.0))
			if t >= dur:
				elegir(johnny, d, absf(angle_difference(mirada.angle(), hacia.angle())))
		"aviso_porrazo":
			frenar(delta)
			if t >= AVISO_PORRAZO:
				cambiar("porrazo", {"angulo": datos.angulo})
				porrazo(johnny)
		"porrazo":
			frenar(delta)
			if t >= 0.4:
				andar(0.5 if enfadado() else 0.9)
		"aviso_carga":
			# se agacha detrás del escudo y se va girando hacia Johnny (la franja roja marca por dónde irá)
			frenar(delta, 6.0)
			girar_hacia(delta, hacia.normalized())
			if t >= datos.aviso:
				cambiar("carga", {"quedan": datos.quedan - 1})
				Sonido.tocar("rugido")
		"carga":
			cargar(delta, johnny, d)
		"atontado":
			frenar(delta, 4.0)
			if t >= ATONTADO:
				andar(0.4)
		"recuperar":
			frenar(delta, 5.0)
			if t >= datos.dur:
				if datos.get("quedan", 0) > 0:
					cambiar("aviso_carga", {"quedan": datos.quedan, "aviso": AVISO_CARGA[1]})
				else:
					andar(0.5 if enfadado() else 0.9)
		"silbato":
			frenar(delta)
			if t >= 0.5 and not datos.get("hecho", false):
				datos.hecho = true
				llamar(REFUERZO, REFUERZOS[fase - 1], 120.0)
			if t >= 1.0:
				andar(0.5)


func girar_hacia(delta: float, hacia: Vector2) -> void:
	if hacia == Vector2.ZERO:
		return
	var paso: float = GIRO[fase - 1] * delta
	mirada = mirada.rotated(clampf(angle_difference(mirada.angle(), hacia.angle()), -paso, paso))


func elegir(johnny: Node2D, d: float, desvio: float) -> void:
	if d < DISTANCIA_PORRAZO and desvio < 0.9 and espera_porrazo <= 0.0:
		espera_porrazo = 1.0 if enfadado() else 1.5
		cambiar("aviso_porrazo", {"angulo": mirada.angle()})
		return
	# el silbato (si no quedan ya muchos zombis por ahí)
	if espera_silbato <= 0.0 and secuaces() <= REFUERZOS[fase - 1]:
		espera_silbato = 13.0
		cambiar("silbato")
		Sonido.tocar("silbato")
		gritar("¡PRIIIII!", Color("#bfe9ff"))
		return
	if d > 170.0 and desvio < 0.7 and espera_carga <= 0.0:
		espera_carga = 2.5 if enfadado() else 3.5
		cambiar("aviso_carga", {"quedan": CARGAS[fase - 1], "aviso": AVISO_CARGA[0]})
		gritar("¡ATRÁS!", Color("#ff5d73"))
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# El porrazo: daña y empuja a Johnny si está dentro del trozo marcado
func porrazo(johnny: Node2D) -> void:
	Sonido.tocar("porrazo")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_PORRAZO and desvio <= MEDIO_PORRAZO + 0.15:
		johnny.recibir_dano(DANO_PORRAZO)
		johnny.empujar(hacia.normalized() * 650.0)


# La carga: corre en línea recta con el escudo por delante. Si pilla a Johnny, le tira; si se estrella, se atonta
func cargar(delta: float, johnny: Node2D, d: float) -> void:
	marcha = mirada * VELOCIDAD_CARGA
	contacto = 0   # el golpe de la carga ya lo da él
	if randf() < delta * 25.0:
		Particulas.soltar(self, global_position + Vector2(randf_range(-20, 20), PIE), Vector2(randf_range(-30, 30), -20),
			Color("#8a7a66"), 3, 0.4)
	if d < radio + johnny.RADIO + 10.0 and johnny.esquiva_t <= 0.0:   # esquivando, la carga le pasa de largo
		johnny.recibir_dano(DANO_CARGA)
		johnny.empujar(mirada * 900.0)
		johnny.pisar({"tirado": {}})
		Temblor.temblar(10.0)
		marcha *= 0.2
		cambiar("recuperar", {"dur": 0.6, "quedan": datos.quedan})
	elif t > 0.12 and get_real_velocity().length() < VELOCIDAD_CARGA * 0.4:
		# se ha comido una pared o un mueble
		estrellarse()
	elif t >= TIEMPO_CARGA:
		marcha *= 0.3
		cambiar("recuperar", {"dur": 0.5, "quedan": datos.quedan})


func estrellarse() -> void:
	marcha = Vector2.ZERO
	cambiar("atontado")
	Sonido.tocar("portazo")
	Temblor.temblar(9.0)
	gritar("¡PUMBA!", Color("#ffd23f"))
	for i in 10:
		Particulas.soltar(self, global_position + mirada * radio + Vector2(randf_range(-20, 20), randf_range(-60, 10)),
			Vector2.from_angle(randf() * TAU) * 70.0, Color("#b9b2a6"), 4, 0.6)


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡QUEDAS DETENIDO!")


# ── El escudo ──

# Por delante no le pasa nada (salvo las explosiones y el fuego, que llegan sin dirección o "de lleno"); por la
# espalda, el doble
func danar(cantidad: int, fuerza: Vector2, de_lleno: bool) -> int:
	if de_lleno or fuerza == Vector2.ZERO:
		return cantidad
	var dif := absf(angle_difference(mirada.angle(), (-fuerza).angle()))
	if dif < FRENTE:
		clonc(fuerza)
		return 0
	if dif > PI - ESPALDA:
		return cantidad * 2
	return cantidad


func clonc(fuerza: Vector2) -> void:
	var donde := global_position + mirada * (radio + 6.0) + Vector2(0, -arriba * 0.45)
	for i in 6:
		var v := (-fuerza.normalized()).rotated(randf_range(-1.0, 1.0)) * randf_range(90.0, 200.0)
		Particulas.soltar(self, donde, v, Color("#fff3a8") if i % 2 else Color("#ffffff"), 3, 0.25)
	if clonc_t <= 0.0:
		clonc_t = 0.25
		Zombi.texto_flotante(get_parent(), donde + Vector2(-34, -30), "¡CLONC!", Color("#bfe9ff"), 18)
		Sonido.tocar("clonc")


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_porrazo":
			fijar("porrazo", dir, mini(GOLPE_PORRAZO - 1, int(t / AVISO_PORRAZO * GOLPE_PORRAZO)))
		"porrazo":
			var resto := sprite.sprite_frames.get_frame_count("porrazo_" + dir) - GOLPE_PORRAZO
			fijar("porrazo", dir, GOLPE_PORRAZO + clampi(int(t / 0.4 * resto), 0, maxi(0, resto - 1)))
		"aviso_carga":
			fijar("carga", dir, avance("carga_" + dir, t / datos.aviso))
		"carga":
			# agachado tras el escudo, dando zancadas (un pequeño bote)
			fijar("carga", dir, sprite.sprite_frames.get_frame_count("carga_" + dir) - 1)
			sprite.position.y = PIE - absf(sin(tiempo * 18.0)) * 3.0
		"atontado":
			fijar("golpe", dir, avance("golpe_" + dir, t / 0.5))
			sprite.position.x = sin(tiempo * 9.0) * 2.0
		"silbato":
			fijar("silbato", "s", avance("silbato_s", t / 1.0))
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func morir() -> void:
	super()
	# mientras no tenga su animación de muerte (solo la vista quieta), cae de lado
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# Los avisos, en el suelo (por debajo de él), y por dónde le tapa el escudo
func _draw() -> void:
	if estado == "muerto":
		return
	var rojo := Color(1, 0.24, 0.35)
	# el escudo: un arco azulado a sus pies, por delante
	var a := mirada.angle()
	draw_set_transform(Vector2(0, PIE - 6), 0.0, Vector2(1, 0.7))
	draw_arc(Vector2.ZERO, radio + 14.0, a - FRENTE, a + FRENTE, 16, Color("#bfe9ff", 0.35), 3.0)
	match estado:
		"aviso_porrazo":
			var k := minf(1.0, t / AVISO_PORRAZO)
			var puntos := PackedVector2Array([Vector2.ZERO])
			for i in 17:
				var b: float = datos.angulo - MEDIO_PORRAZO + i / 16.0 * MEDIO_PORRAZO * 2.0
				puntos.append(Vector2.from_angle(b) * ALCANCE_PORRAZO)
			draw_set_transform(Vector2(0, 6))
			draw_colored_polygon(puntos, Color(rojo, 0.1 + k * 0.25))
			puntos.append(Vector2.ZERO)
			draw_polyline(puntos, Color(rojo, 0.9), 3.0)
		"aviso_carga":
			var k := minf(1.0, t / datos.aviso)
			var largo := VELOCIDAD_CARGA * TIEMPO_CARGA
			draw_set_transform(Vector2(0, 6), a)
			draw_rect(Rect2(0, -radio, largo, radio * 2.0), Color(rojo, 0.08 + k * 0.2))
			draw_rect(Rect2(0, -radio, largo * k, radio * 2.0), Color(rojo, 0.9), false, 3.0)


# Atontado: estrellitas dando vueltas sobre el casco
func pintar_encima(lienzo: Node2D) -> void:
	if estado != "atontado":
		return
	for i in 3:
		var b := tiempo * 5.0 + i * TAU / 3.0
		var p := Vector2(cos(b) * 26.0, -arriba - 8.0 + sin(b) * 8.0)
		var estrella := PackedVector2Array()
		for j in 10:
			estrella.append(p + Vector2.from_angle(j * TAU / 10.0 - PI / 2.0) * (6.0 if j % 2 == 0 else 2.5))
		lienzo.draw_colored_polygon(estrella, Color("#ffd23f"))
