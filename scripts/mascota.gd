# La mascota: uno de los cuatro minijefes del centro comercial (su tienda, la Juguetería). Un oso de peluche
# gigante, amarillo y sucio, con la cara del zombi dentro de la cabeza. Lo común de los minijefes, en minijefe.gd.
#
# Es rápida y hace dos cosas:
#   - Embestida: marca una franja roja en el suelo (0,6 s) y sale disparada en línea recta. Si pilla a Johnny le
#     quita 22 y le tira; esquivando, le pasa de largo; si se estrella contra una pared o un mueble, se queda
#     mareada 5 s, con estrellitas (¡a por ella!). La carrera es la misma que la carga del antidisturbios.
#   - Salto: se agacha y salta hacia donde está Johnny. Mientras vuela (0,8 s) se ve en el suelo su sombra,
#     creciendo, donde va a caer; al caer quita 18 a lo que esté en ese círculo. En el aire no se le puede dar.
# Enfadada (a media vida): 3 embestidas seguidas con menos aviso; si choca con una pared rebota y, tras un aviso corto
# con su franja (AVISO_REBOTE), sigue; solo se marea si se estrella en la última.
# M85: en la fase 2 van saliendo críos (el zombi rápido) por la tienda, lejos de Johnny (salir_crios()).
#
# Rehecha el 24 nov (docs/JEFES_CENTRO.md, «La fiesta de cumpleaños»), fase 1:
#   - Pelotas saltarinas: cada vez que se estrella (o rebota) contra una pared suelta PELOTAS_PARED pelotas de juguete
#     (pelota_goma.gd, con "juguete") que rebotan sin parar y se suman (como mucho MAX_PELOTAS).
#   - Al caer de un salto, las pelotas cercanas salen disparadas hacia fuera, más deprisa (aplastar_pelotas).
#   - El truco, las cajas sorpresa (caja_sorpresa.gd): hay CAJAS por la sala; si se come una embistiendo, el muñeco
#     salta, ella cae de culo mareada SORPRESA s (le entra un MAS_SORPRESA más) y todas las pelotas revientan (las que
#     tiene cerca le hacen daño). La caja se va y al rato cae otra. Pistas: lo dice Johnny al entrar y junto a la barra
#     de vida hay una cajita por cada caja (ui/barra_jefe.gd, pintar_cajas).
# 25 nov (el dueño: no paraba de perseguir a Johnny y casi no embestía), también en la fase 1:
#   - No persigue: baila a saltitos alrededor de Johnny, a media distancia (bailar), y desde ahí ataca.
#   - Embiste más a menudo y corre hasta estrellarse con algo (no se para al rato): cada choque suelta pelotas. Contra
#     una pared solo se sacude la cabeza SACUDE s; la caja sorpresa es la que la deja sentada.
#   - «¡REGALOS!»: tira REGALOS regalos por el aire alrededor de Johnny (regalo.gd); al caer revientan y sueltan pelotas.
#   - El matasuegras: con Johnny cerca, sopla un matasuegras gigante: un cono que le quita un poco y le manda lejos (y
#     las pelotas que pille salen disparadas).
extends Minijefe

const PELOTA := preload("res://scripts/pelota_goma.gd")
const CAJA := preload("res://scripts/caja_sorpresa.gd")
const PELOTAS_PARED := 2
const MAX_PELOTAS := 12
const VELOCIDAD_PELOTA := 240.0
const APLASTA := 170.0                 # al caer de un salto, las pelotas a menos de esto salen disparadas...
const DISPARO_APLASTA := 520.0         # ...así de deprisa (luego frenan hasta VELOCIDAD_PELOTA)
const CAJAS := 3
const SORPRESA := 5.0                  # lo que se queda sentada y mareada tras comerse una caja
const MAS_SORPRESA := 1.5              # lo que le entra así
const REVIENTA_CERCA := 140.0          # las pelotas que revientan a menos de esto le hacen daño...
const DANO_REVIENTA := 12              # ...esto cada una
const REPONE_CAJA := 6.0               # lo que tarda en caer otra caja cuando una se va
const REGALO := preload("res://scripts/regalo.gd")
const VELOCIDAD_BAILE := 190.0         # fase 1: lo deprisa que va de un sitio a otro a saltitos
const BAILE := [210.0, 330.0]          # a qué distancia de Johnny se pone (de, a)
const SACUDE := 1.0                    # fase 1: lo que se queda sacudiendo la cabeza tras estrellarse contra una pared
const ESPERA_EMBESTIDA := [2.2, 2.5]   # entre una embestida y la siguiente (normal y enfadada)
const TIEMPO_EMBESTIDA_1 := 3.2        # fase 1: corre hasta chocar (esto es lo más que corre si no choca con nada)
const REGALOS := 4
const AVISO_REGALOS := 0.55            # lo que tarda en tirarlos (con los brazos arriba)
const VUELO_REGALO := 0.95             # lo que tardan en caer (lo que se ve su marca en el suelo)
const ESPERA_REGALOS := 6.0
const PELOTAS_REGALO := 2
const AVISO_SOPLO := 0.6               # el matasuegras: lo que tarda en soplar (lo que se ve el cono)
const SOPLO := 0.55                    # lo que sopla
const ALCANCE_SOPLO := 210.0
const MEDIO_SOPLO := 0.55              # medio ángulo del cono
const DANO_SOPLO := 10
const EMPUJE_SOPLO := 2600.0
const DISTANCIA_SOPLO := 180.0         # con Johnny más cerca que esto, sopla
const ESPERA_SOPLO := 3.0
const SOPLA := 6                       # el fotograma de su animación en el que el matasuegras se desenrolla
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

# M85: los críos que salen sin parar (normal y enfadada): cada cuánto sale uno, cuántos puede haber vivos a la vez
# (con el máximo, no saca más hasta que Johnny mate alguno) y a qué distancia de Johnny aparecen (para verlos venir)
const CRIOS_CADA := [4.0, 2.5]
const CRIOS_MAX := [4, 6]
const CRIOS_LEJOS := 300.0

var espera_embestida := 1.5
var espera_salto := 3.0
var espera_crio := 3.0
var espera_regalos := 3.0
var espera_soplo := 0.0
var punto := Vector2.INF       # fase 1: el sitio al que va bailando
var punto_t := 0.0             # lo que lleva yendo a ese sitio
var cajas: Array = []          # las cajas sorpresa que hay ahora en la sala
var reponer: Array = []        # lo que falta para que caiga cada caja nueva (una por cada caja que se ha ido)
var cajas_puestas := false
var inicio := Vector2.ZERO     # donde sale (el medio de la sala): las cajas caen a su alrededor


func _ready() -> void:
	super()
	pista.call_deferred()


# La pista para el jugador: Johnny lo dice al entrar (si está la presentación, al acabar)
func pista() -> void:
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("Esas cajas sorpresa... ¿Y si consigo que se estrelle contra una?"), 4.0)


func pensar(delta: float, johnny: Node2D) -> void:
	espera_embestida -= delta
	espera_salto -= delta
	espera_regalos -= delta
	espera_soplo -= delta
	salir_crios(delta, johnny)
	reponer_cajas(delta, johnny)
	match estado:
		"andar":
			if fase == 1:
				bailar(delta, johnny)
			else:
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
			var como := embestir(delta, johnny, VELOCIDAD_EMBESTIDA, DANO_EMBESTIDA, tiempo_embestida(), PIE)
			var caja := caja_tocada() if como in ["", "pared"] and t > 0.05 else null
			if caja:
				sorpresa(caja)
				return
			match como:
				"pillado":
					cambiar("recuperar", {"dur": 0.5, "quedan": datos.quedan})
				"pared":
					soltar_pelotas()
					if datos.quedan > 0:
						rebotar()
					else:
						estrellarse()
						if fase == 1:
							datos.dura = SACUDE   # (solo se sacude: la que la deja sentada es la caja sorpresa)
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
			if t >= datos.get("dura", tiempo_atontado(MAREADA)):   # (3 s, salvo en la azotea; en la fase 1, SACUDE)
				andar(0.4)
		"sorpresa":
			# sentada de culo, mareada: ¡a por ella!
			frenar(delta, 5.0)
			if t >= SORPRESA:
				andar(0.4)
		"regalos":
			# con los brazos arriba, mirando a Johnny; al acabar el aviso, los tira
			frenar(delta, 10.0)
			mirada = global_position.direction_to(johnny.global_position)
			if t >= AVISO_REGALOS:
				tirar_regalos(johnny)
				cambiar("recuperar", {"dur": 0.45, "quedan": 0})
		"aviso_soplo":
			# se lleva el matasuegras a la boca: el cono marca por dónde va a soplar (ya no se gira)
			frenar(delta, 12.0)
			if t >= AVISO_SOPLO:
				cambiar("soplo", {"angulo": datos.angulo})
				soplar(johnny)
		"soplo":
			frenar(delta, 12.0)
			echar_soplo()
			if t >= SOPLO:
				andar(0.5)
		"agacharse":
			frenar(delta, 12.0)
			if t >= AGACHARSE:
				despegar(johnny)
		"salto":
			# por el aire, de donde estaba a donde cae (sin chocar con nada)
			invulnerable = true
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
	if fase == 1:
		elegir_fiesta(johnny, d)
		return
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


# Fase 1: si Johnny está cerca, el matasuegras; si no, embestir, los regalos o saltar (lo que esté listo); con nada
# listo, sigue bailando
func elegir_fiesta(johnny: Node2D, d: float) -> void:
	if espera_soplo <= 0.0 and d < DISTANCIA_SOPLO:
		espera_soplo = ESPERA_SOPLO
		var angulo := global_position.direction_to(johnny.global_position).angle()
		mirada = Vector2.from_angle(angulo)
		marcha = Vector2.ZERO
		cambiar("aviso_soplo", {"angulo": angulo})
		return
	if espera_embestida <= 0.0 and d > 160.0:
		espera_embestida = ESPERA_EMBESTIDA[0]
		apuntar(johnny, 1, AVISO_EMBESTIDA[0])
		gritar(Idioma.t("¡ABRAZOS GRATIS!"), Color("#ff5d73"), 20)
		return
	if espera_regalos <= 0.0:
		espera_regalos = ESPERA_REGALOS
		marcha = Vector2.ZERO
		cambiar("regalos")
		gritar(Idioma.t("¡REGALOS!"), Color("#7ee081"), 20)
		return
	if espera_salto <= 0.0 and d > 90.0 and d < 420.0:
		espera_salto = 4.5
		cambiar("agacharse")
		return
	andar(0.4)


# Lo que corre como mucho en una embestida: en la fase 1, hasta chocar con algo
func tiempo_embestida() -> float:
	return TIEMPO_EMBESTIDA_1 if fase == 1 else TIEMPO_EMBESTIDA


# Fase 1: va a saltitos de un sitio a otro alrededor de Johnny, a media distancia (BAILE), mirándole. Cuando llega (o
# tarda mucho), busca otro un poco más allá, dándole la vuelta
func bailar(delta: float, johnny: Node2D) -> void:
	punto_t += delta
	if punto == Vector2.INF or global_position.distance_to(punto) < 20.0 or punto_t > 2.2:
		punto = punto_baile(johnny)
		punto_t = 0.0
	var hacia := punto - global_position
	if hacia.length() > 20.0:
		marcha += (hacia.normalized() * VELOCIDAD_BAILE - marcha) * (1.0 - exp(-delta * 6.0))
	else:
		frenar(delta, 8.0)
	mirada = global_position.direction_to(johnny.global_position)


# Un sitio libre a media distancia de Johnny, girando un poco alrededor de él desde donde está ella
func punto_baile(johnny: Node2D) -> Vector2:
	var mapa_nav := agente.get_navigation_map()
	var desde: float = johnny.global_position.direction_to(global_position).angle()
	var mejor := global_position
	for i in 10:
		var a := desde + randf_range(0.5, 1.3) * (1.0 if randf() < 0.5 else -1.0)
		var p: Vector2 = johnny.global_position + Vector2.from_angle(a) * randf_range(BAILE[0], BAILE[1])
		var cerca := NavigationServer2D.map_get_closest_point(mapa_nav, p)
		if cerca.distance_to(p) < 24.0:
			return cerca
		mejor = cerca
	return mejor


# «¡REGALOS!»: el primero hacia donde va Johnny y los demás repartidos a su alrededor
func tirar_regalos(johnny: Node2D) -> void:
	Sonido.tocar("lanzar")
	var mapa_nav := agente.get_navigation_map()
	var giro := randf() * TAU
	for i in REGALOS:
		var lado := Vector2.ZERO if i == 0 else Vector2.from_angle(giro + i * TAU / (REGALOS - 1)) * randf_range(120.0, 170.0)
		var r := REGALO.new()
		r.desde = global_position + Vector2(0, -arriba * 0.6)
		r.vuelo = VUELO_REGALO + i * 0.12
		r.dueno = self
		r.position = NavigationServer2D.map_get_closest_point(mapa_nav, johnny.global_position + johnny.velocity * 0.5 + lado)
		get_parent().add_child(r)


# El matasuegras: si Johnny está en el cono (y no esquiva ni hay nada en medio), le quita un poco y le manda lejos; las
# pelotas que pille salen disparadas
func soplar(johnny: Node2D) -> void:
	Sonido.tocar("rugido")
	Temblor.temblar(5.0)
	gritar(Idioma.t("¡PIIIII!"), Color("#ffd23f"), 18)
	var hacia: Vector2 = johnny.global_position - global_position
	if en_cono(hacia) and johnny.esquiva_t <= 0.0 and not Aviso.tapado(self, johnny.global_position, Vector2(0, 6)):
		johnny.recibir_dano(DANO_SOPLO, self)
		johnny.empujar(Vector2.from_angle(datos.angulo) * EMPUJE_SOPLO)
	for p in pelotas():
		var a: Vector2 = p.global_position - global_position
		if en_cono(a):
			p.velocidad = a.normalized() * DISPARO_APLASTA


func en_cono(hacia: Vector2) -> bool:
	return hacia.length() < ALCANCE_SOPLO + 20.0 and absf(angle_difference(datos.angulo, hacia.angle())) < MEDIO_SOPLO + 0.1


# Mientras sopla: confeti y rachas de aire que salen por el cono
func echar_soplo() -> void:
	for i in 5:
		var a: float = datos.angulo + randf_range(-MEDIO_SOPLO, MEDIO_SOPLO) * 0.8
		var color: Color = [Color("#ff5d73"), Color("#ffd23f"), Color("#5fd3ff"), Color("#7ee081"), Color("#f4f0e4", 0.7)][randi() % 5]
		Particulas.soltar(get_parent(), global_position + Vector2.from_angle(datos.angulo) * (radio + 10.0) + Vector2(0, -arriba * 0.45),
			Vector2.from_angle(a) * randf_range(380, 620), color, randf_range(3, 5), 0.4)


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
	# el pisotón de pixelfx (M58), del tamaño de la zona donde cae
	EfectoSuelo.soltar(get_parent(), "pisoton", global_position + Vector2(0, PIE - 6), RADIO_SALTO / EfectoSuelo.ONDA_PISOTON)
	aplastar_pelotas()
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < RADIO_SALTO + johnny.RADIO and johnny.esquiva_t <= 0.0 \
			and not Aviso.tapado(self, johnny.global_position + Vector2(0, 16), Vector2(0, PIE - 6)):
		johnny.recibir_dano(DANO_SALTO, self)
		johnny.empujar((hacia.normalized() if hacia != Vector2.ZERO else Vector2.DOWN) * 600.0)


# M85: cada CRIOS_CADA segundos sale un crío, si no hay ya CRIOS_MAX vivos. Aparece en un sitio libre de la tienda a
# unas CRIOS_LEJOS unidades de Johnny (como si saliera de entre los juguetes). En la sala de pruebas (quieta), no.
func salir_crios(delta: float, johnny: Node2D) -> void:
	espera_crio -= delta
	if espera_crio > 0.0 or quieto or fase == 1:   # (desde el 24 nov, solo en la fase 2)
		return
	espera_crio = CRIOS_CADA[fase - 1]
	if crios() >= CRIOS_MAX[fase - 1]:
		return
	# prueba unos cuantos sitios alrededor de Johnny y se queda con el que, ya dentro de la tienda, quede más lejos
	var mapa_nav := agente.get_navigation_map()
	var mejor := global_position
	for i in 8:
		var a := randf() * TAU
		var p := NavigationServer2D.map_get_closest_point(mapa_nav, johnny.global_position + Vector2(cos(a), sin(a)) * CRIOS_LEJOS)
		if p.distance_to(johnny.global_position) > mejor.distance_to(johnny.global_position):
			mejor = p
		if mejor.distance_to(johnny.global_position) > CRIOS_LEJOS * 0.75:
			break
	pide_zombi.emit("rapido", mejor)


# Cuántos críos quedan vivos
func crios() -> int:
	return get_tree().get_nodes_in_group("zombis").filter(func(z): return z.get_meta("tipo", "") == "rapido").size()


# ── Las pelotas saltarinas ──

func pelotas() -> Array:
	return get_tree().get_nodes_in_group("pelotas_goma")


# Al caer un regalo: PELOTAS_REGALO pelotas que salen de donde ha caído, cada una hacia un lado
func soltar_pelotas_en(donde: Vector2) -> void:
	var giro := randf() * TAU
	for i in mini(PELOTAS_REGALO, MAX_PELOTAS - pelotas().size()):
		var p := PELOTA.new()
		p.juguete = true
		p.rapidez_normal = VELOCIDAD_PELOTA
		p.velocidad = Vector2.from_angle(giro + i * TAU / PELOTAS_REGALO) * VELOCIDAD_PELOTA
		p.dueno = self
		p.position = donde
		get_parent().add_child(p)


# Al estrellarse contra una pared: PELOTAS_PARED pelotas que salen rebotando hacia atrás, hacia la sala
func soltar_pelotas() -> void:
	var hay := pelotas().size()
	for i in mini(PELOTAS_PARED, MAX_PELOTAS - hay):
		var p := PELOTA.new()
		p.juguete = true
		p.rapidez_normal = VELOCIDAD_PELOTA
		p.velocidad = (-mirada).rotated(randf_range(0.35, 0.8) * (1 if i % 2 == 0 else -1)) * VELOCIDAD_PELOTA
		p.dueno = self
		p.position = position - mirada * (radio * 0.5) + Vector2(0, PIE * 0.3)
		get_parent().add_child(p)


# Al caer de un salto: las pelotas cercanas salen disparadas hacia fuera, más deprisa (luego van frenando)
func aplastar_pelotas() -> void:
	for p in pelotas():
		var hacia: Vector2 = p.global_position - global_position
		if hacia.length() < APLASTA:
			p.velocidad = (hacia.normalized() if hacia != Vector2.ZERO else Vector2.from_angle(randf() * TAU)) * DISPARO_APLASTA


# ── Las cajas sorpresa ──

# Cuántas cajas hay listas ahora (para la barra de vida, ui/barra_jefe.gd)
func cajas_listas() -> int:
	return cajas.filter(func(c): return is_instance_valid(c) and not c.abierta).size()


# La primera vez, las CAJAS de la sala; luego, cada caja que se va deja una cuenta atrás para que caiga otra
func reponer_cajas(delta: float, johnny: Node2D) -> void:
	cajas = cajas.filter(func(c): return is_instance_valid(c))
	if not cajas_puestas:
		cajas_puestas = true
		inicio = global_position
		for i in CAJAS:
			poner_caja(johnny)
		return
	for i in reponer.size():
		reponer[i] -= delta
	while not reponer.is_empty() and reponer[0] <= 0.0:
		reponer.pop_front()
		poner_caja(johnny)


# Una caja nueva en un sitio libre de la sala: ni pegada a una pared, ni a las otras cajas, ni encima de nadie
func poner_caja(johnny: Node2D) -> void:
	var mapa_nav := agente.get_navigation_map()
	var donde := Vector2.INF
	for intento in 40:
		var p: Vector2 = inicio + Vector2(randf_range(-1.0, 1.0) * 560.0, randf_range(-1.0, 1.0) * 260.0)
		var libre := true
		for lado in [Vector2.ZERO, Vector2(56, 0), Vector2(-56, 0), Vector2(0, 50), Vector2(0, -50)]:
			if NavigationServer2D.map_get_closest_point(mapa_nav, p + lado).distance_to(p + lado) > 6.0:
				libre = false
		if not libre or p.distance_to(johnny.global_position) < 110.0 or p.distance_to(global_position) < 140.0:
			continue
		if cajas.any(func(c): return c.global_position.distance_to(p) < 220.0):
			continue
		donde = p
		break
	if donde == Vector2.INF:
		return   # (no cabe: lo vuelve a intentar dentro de un rato)
	var c := CAJA.new()
	c.position = donde
	get_parent().add_child(c)
	cajas.append(c)


# La caja contra la que va embistiendo, si la toca (de frente o rozándola)
func caja_tocada() -> Node2D:
	for c in cajas:
		if is_instance_valid(c) and c.lista() and c.global_position.distance_to(global_position) < radio + CAJA.RADIO + 10.0:
			return c
	return null


# ¡Sorpresa! Se ha comido una caja: el muñeco salta, ella cae de culo mareada y todas las pelotas revientan
func sorpresa(caja: Node2D) -> void:
	caja.abrir()
	reponer.append(REPONE_CAJA + CAJA.ABIERTA)
	marcha = -mirada * 420.0   # (el muñeco la tira hacia atrás: cae de culo al lado de la caja, no detrás)
	global_position -= mirada * 6.0
	cambiar("sorpresa")
	Temblor.temblar(12.0)
	Sonido.tocar("portazo")
	var dano := 0
	var hay := pelotas().size()
	for p in pelotas():
		if p.global_position.distance_to(global_position) < REVIENTA_CERCA:
			dano += DANO_REVIENTA
		p.reventar()
	if hay > 0:
		Sonido.tocar("explosion")
	if dano > 0:
		recibir_golpe(dano, Vector2.ZERO, true)


# Sentada tras la caja, le entra más; y lleva estrellitas
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	return roundi(cantidad * MAS_SORPRESA) if estado == "sorpresa" else cantidad


func con_estrellas() -> bool:
	return estado in ["atontado", "sorpresa"]


# Si cae en mitad de un salto o mareada, que caiga en el suelo y derecha; y se van las cajas
func morir() -> void:
	sprite.position = Vector2(0, PIE)
	sprite.rotation = 0.0
	$Choque.set_deferred("disabled", false)
	for c in cajas:
		if is_instance_valid(c):
			c.irse()
	cajas.clear()
	reponer.clear()
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
		"sorpresa":
			# cae de culo (de frente: animación de PixelLab) y se queda sentada con la cabeza dando vueltas (los
			# últimos fotogramas, de ida y vuelta)
			var n := sprite.sprite_frames.get_frame_count("sorpresa_s")
			var f := int(t * 12.0)
			if f >= n:
				var vuelta := int((t - n / 12.0) * 6.0) % 6
				f = n - 1 - (vuelta if vuelta < 3 else 6 - vuelta)
			fijar("sorpresa", "s", f)
		"agacharse":
			fijar("salto", dir, int(t / AGACHARSE * DESPEGUE))
		"regalos":
			# se agacha y levanta las zarpas (el principio del salto, sin despegar) y los tira
			fijar("salto", dir, mini(int(t / AVISO_REGALOS * (DESPEGUE + 2)), DESPEGUE + 1))
		"aviso_soplo":
			# se lleva el matasuegras a la boca (la animación de PixelLab, hasta que sopla)
			fijar("matasuegras", dir, int(minf(1.0, t / AVISO_SOPLO) * SOPLA))
		"soplo":
			var n := sprite.sprite_frames.get_frame_count("matasuegras_" + dir)
			fijar("matasuegras", dir, SOPLA + int(minf(1.0, t / SOPLO) * (n - SOPLA)))
			sprite.position.x = sin(tiempo * 60.0) * 1.5
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
				if fase == 1 and estado == "andar":
					sprite.position.y = PIE - absf(sin(tiempo * 11.0)) * 9.0   # (bailando: a saltitos)
			else:
				poner("reposo_" + dir)


# Los avisos, en el suelo (por debajo de ella): la franja de la embestida y la sombra de donde va a caer
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_embestida":
			franja(VELOCIDAD_EMBESTIDA * tiempo_embestida(), minf(1.0, t / datos.aviso))
		"aviso_soplo":
			# el cono del matasuegras (se corta donde hay paredes o muebles)
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_SOPLO, ALCANCE_SOPLO, minf(1.0, t / AVISO_SOPLO), tiempo)
		"salto":
			# donde cae: el círculo se llena hacia fuera y su sombra crece en el medio (aviso.gd)
			var k := minf(1.0, t / VUELO)
			Aviso.golpe(self, datos.hasta - global_position + Vector2(0, PIE - 6), 0.0, PI, RADIO_SALTO, k, tiempo,
				0.6, 0.3 + 0.4 * k)
