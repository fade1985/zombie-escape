# La modista: una de los minijefes del centro comercial (su tienda, el Taller de costura), rehecha el 24 nov como
# «El desfile» (docs/JEFES_CENTRO.md): una pelea de mirar y pensar. La encargada de la tienda de ropa, alta y tiesa
# como un maniquí, con unas tijeras de sastre enormes. Lo común de los minijefes, en minijefe.gd.
#
# Fase 1, «la tienda» (su tienda está llena de maniquíes de cuerpo entero con su mismo vestido, "tallmannequin"):
#   - Carretes: tira un carrete que rueda hasta la pared dejando un hilo tendido (hilo_modista.gd). Flojo, enreda
#     (frena a Johnny); los hilos se acumulan (hasta MAX_HILOS) y se cortan de un golpe o de un tiro.
#   - «¡A TENSAR!»: con 3 hilos o más, tira de todos: se ponen rojos y, tras el aviso, hacen daño un momento.
#   - El truco, esconderse: le brillan los ojos y, en una nube de retales que sale de TODOS los maniquíes a la vez,
#     se cambia de sitio con uno. Quieta entre ellos, solo se la distingue porque **respira** (sube y baja un
#     píxel) y algún parpadeo de los ojos. Si Johnny le pega a ella, queda descubierta (DESCUBIERTA s aturdida,
#     le entra el doble); si le pega a un maniquí que no es, ese maniquí revienta en un anillo de alfileres (con
#     aviso). Cada maniquí lleva un "señuelo" (Senuelo, abajo) para recibir esos golpes.
#   - De relleno: la ráfaga de alfileres (una raya en el suelo que sigue a Johnny y luego varios seguidos) y el
#     tijeretazo de cerca (marca roja de medio segundo).
#   - Pista: al entrar, Johnny dice «Uno de esos maniquíes respira...». Junto a la barra de vida, un carretito por
#     cada hilo tendido (ui/barra_jefe.gd, pintar_hilos).
# A media vida, «¡QUE EMPIECE EL DESFILE!» (su pose de pasarela): los hilos se caen, se apagan las luces de la tienda,
# se enciende un foco que recorre la sala (foco_modista.gd) y 3 maniquíes cobran vida (maniqui_vivo.gd).
# Fase 2, «la pasarela»:
#   - Bajo el foco, los maniquíes se quedan quietos; a oscuras (y si Johnny no los mira), se mueven.
#   - Ella ronda por la oscuridad apartándose del foco (se le ven los ojos) y lanza tijeretazos de pared a pared: una
#     franja de aviso y cruza la sala corriendo con las tijeras por delante, CORTES veces seguidas.
#   - El truco: si el foco la pilla (también a mitad de un corte), se queda congelada como un maniquí (CONGELADA s,
#     le entra el doble). Luego un rato (INMUNE_FOCO) el foco no la para.
#   - Pista: al apagarse las luces, Johnny dice «Si el foco la pilla, se queda tiesa...».
# Sus animaciones (PixelLab, tools/jefe_hoja.py): andar, alfileres, tijeretazo, golpe, muerte, corte (el tijeretazo
# largo) y, solo de frente, aturdida y desfile.
extends Minijefe

const VIVO := preload("res://scripts/maniqui_vivo.gd")
const BALA := preload("res://escenas/armas/bala_zombi.tscn")
const MANIQUI := "tallmannequin"   # los maniquíes de su tienda (catalogo.gd)
const VELOCIDAD := [90.0, 120.0]
const LEJOS := 260.0               # se queda más o menos a esta distancia de Johnny
# Los alfileres: cuántos en cada ráfaga (normal y enfadada), cada cuánto sale uno, lo deprisa que vuelan y el daño
const ALFILERES := [5, 6]
const CADA_ALFILER := 0.09
const VELOCIDAD_ALFILER := 480.0
const DANO_ALFILER := 8
const AVISO_ALFILERES := [0.7, 0.6]
const FIJA := 0.2                  # la raya deja de seguir a Johnny este rato antes de tirar
const GIRO_RAYA := 2.5             # lo deprisa que la raya sigue a Johnny (radianes por segundo)
const ALCANCE_ALFILERES := 700.0   # más lejos que esto no tira
const ANCHO_AVISO := 10.0          # medio ancho de la franja que avisa de los alfileres (aviso.gd, disparo())
const AVISO_TIJERETAZO := 0.5
const ALCANCE_TIJERETAZO := 110.0
const MEDIO_TIJERETAZO := 0.8      # medio ángulo del trozo que corta
const DANO_TIJERETAZO := 22
const DISTANCIA_TIJERETAZO := 140.0   # si Johnny está más cerca que esto, prefiere el tijeretazo
# Los carretes y los hilos
const MAX_HILOS := 16
const AVISO_CARRETE := 0.45
const CARRETES := 5                # los que tira de una vez, en abanico
const ABANICO_CARRETES := 0.35     # lo que se separan entre sí (radianes)
const ABRE_CARRETE := 0.5          # lo que se desvía (al azar) de Johnny al tirarlo: así los hilos se cruzan
const CARRERA_ATADO := 560.0       # lo deprisa que va a por Johnny atado
const CRECIDA := 8.0               # si no la encuentran escondida, lo que dura crecida: más rápida
const RAPIDA := 2.0                # crecida, lo deprisa que se le pasan las esperas entre ataques
const ANDA_CRECIDA := 1.4          # crecida, lo deprisa que anda
const SEGUIDOS := 2                # tijeretazos seguidos como mucho antes de hacer otra cosa
const TENSAR := 1.6                # lo que dura tirando de los hilos (el aviso de los hilos es menos: hilo_modista.gd)
const MIN_TENSAR := 4              # con menos hilos no tensa
# Esconderse entre los maniquíes
const OJOS := 0.6                  # lo que le brillan los ojos antes de cambiarse de sitio
const OJOS_MANIQUI := [Vector2(-5, -103), Vector2(1, -103)]   # escondida, sus ojos van en la cabeza del maniquí
const PRIMER_TIRO := 3.0           # al entrar en la sala, lo que tarda en tirar la primera vez (después de su presentación)
const AVISO_ESCONDIDA := 0.6       # lo que dura su aviso en el suelo antes de tirar
const DISPARO_ESCONDIDA := 1.5     # escondida, cada cuánto le tira un alfiler (y dos señuelos a la vez: disparo_escondida)
const ESCONDIDA := 6.0             # lo que se queda quieta como un maniquí más
const RESPIRA := 1.7               # lo que tarda cada respiración (sube y baja un píxel)
const PARPADEO := [2.0, 3.5]       # cada cuánto le brillan un instante los ojos escondida
const LEJOS_DE_JOHNNY := 220.0     # el maniquí con el que se cambia está por lo menos así de lejos de Johnny
const DESCUBIERTA := 1.5           # lo que se queda aturdida si la encuentran
const MAS_DESCUBIERTA := 2.0       # lo que le entra entonces
const REVIENTA := 0.5              # el aviso del maniquí equivocado antes de reventar en alfileres
const ALFILERES_REVIENTA := 12
const RADIO_REVIENTA := 90.0       # el aro del aviso (los alfileres llegan más lejos)
const VIVOS := 3                   # los maniquíes que cobran vida al enfadarse
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
const PIE_MANIQUI := Vector2(0, 26)   # su centro, respecto a los pies de un maniquí (para ponerse en su sitio)
# La pasarela (fase 2)
const OSCURO := 0.45               # la oscuridad de más con las luces apagadas (luz.gd, evento; con la de la tienda, casi negro)
const AVISO_CORTE := [0.9, 0.45]   # el aviso del primer corte y el de los siguientes
const CORTES := 4
const VELOCIDAD_CORTE := 900.0
const DURA_CORTE := 1.4            # lo más que corre en un corte
const ANCHO_CORTE := 26.0          # lo cerca de su camino que tiene que estar Johnny para que le corte
const DANO_CORTE := 18
const CONGELADA := 1.3             # lo que se queda tiesa si la pilla el foco
const MAS_CONGELADA := 2.0
const INMUNE_FOCO := 5.0           # después, el foco no la para este rato
# Lo que espera entre ataque y ataque (normal y enfadada; 0: no lo hace)
const ESPERAS := {"tijeretazo": [1.4, 1.1], "alfileres": [3.5, 5.0], "carrete": [1.6, 0.0], "tensar": [9.0, 0.0],
	"esconderse": [7.0, 0.0], "corte": [0.0, 5.5]}
# Los fotogramas de sus animaciones en los que corta las tijeras y lanza los alfileres (el brazo ya estirado)
const CORTA := 4
const LANZA := 4
# Dónde tiene los ojos en cada dirección (respecto a su centro), para el brillo; de espaldas, solo el resplandor
const OJOS_EN := {"s": [Vector2(-5, -91), Vector2(1, -91)], "se": [Vector2(0, -91), Vector2(5, -91)],
	"so": [Vector2(-9, -91), Vector2(-4, -91)], "e": [Vector2(4, -86)], "o": [Vector2(-8, -86)],
	"n": [], "ne": [], "no": []}
const CABEZA := Vector2(-2, -89)

var pillada_antes := false         # la última vez que iba a esconderse, la pillaron (danar, "ojos")
var reloj_tiros := 0.0             # escondida, lo que falta para tirar (ver "escondida" en pensar)
var crecida := 0.0                 # lo que le queda de crecida (salir)
var seguidos := 0                  # tijeretazos seguidos (elegir)
var tirados := 0                  # los carretes que lleva tirados (para los gordos)
var disfraz: Sprite2D = null       # escondida, el dibujo del maniquí que hace de ella (vestir)
var espera := {"tijeretazo": 1.0, "alfileres": 2.0, "carrete": 1.0, "tensar": 6.0, "esconderse": 4.0, "corte": 2.0}
var vivos: Array = []
var hilos: Array = []
var ojos: Node2D                   # el brillo de los ojos, que se ve también a oscuras
var foco: FocoModista = null
var sin_foco := 0.0                # mientras sea > 0, el foco no la congela
var parpadeo := 2.0
var lamparas: Array = []           # las que se apagaron al empezar el desfile, con lo que lucían: [nodo, fuerza]


func _ready() -> void:
	super()
	ojos = Node2D.new()
	ojos.name = "Ojos"
	ojos.z_index = 2
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ojos.material = sin_luz
	ojos.draw.connect(_pintar_ojos)
	add_child(ojos)
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_inside_tree():
			EfectoSuelo.precalentar(get_parent(), "retales"))
	# al aparecer ya está escondida: ocupa el sitio de un maniquí (sin dejar otro donde estaba)
	empezar_escondida.call_deferred()
	pista.call_deferred()


# La pista para el jugador: Johnny lo dice al entrar (si está la presentación, al acabar)
func pista() -> void:
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("Uno de esos maniquíes respira..."), 4.0)


func empezar_escondida() -> void:
	poner_senuelos()
	var johnny := get_tree().get_first_node_in_group("jugador")
	var m: Node2D = maniqui_lejos(johnny) if johnny else null
	if m == null:
		return
	global_position = m.global_position - PIE_MANIQUI
	vestir(m)
	m.get_parent().remove_child(m)
	m.queue_free()
	rehornear()
	mirada = Vector2.DOWN
	cambiar("escondida", {"dur": ESCONDIDA})
	reloj_tiros = PRIMER_TIRO   # (al empezar, más margen: que dé tiempo a situarse)


func pensar(delta: float, johnny: Node2D) -> void:
	# crecida (no la han encontrado a tiempo: salir), las esperas entre ataques corren más deprisa
	for k in espera:
		espera[k] -= delta * (RAPIDA if crecida > 0.0 else 1.0)
	if crecida > 0.0:
		crecida -= delta
		if estado not in ["escondida", "congelada"]:
			# roja, latiendo
			var late := 0.5 + 0.5 * sin(tiempo * 12.0)
			sprite.modulate = Color(1.0, 0.55 + 0.25 * late, 0.55 + 0.25 * late)
		if crecida <= 0.0 and fase == 1 and estado != "escondida":
			sprite.modulate = Color.WHITE
	sin_foco -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	# la pasarela: si el foco la pilla, se queda tiesa (salvo justo después de otra vez)
	if fase == 2 and sin_foco <= 0.0 and estado not in ["congelada", "grito"] and bajo_foco():
		congelarse()
		return
	match estado:
		"andar":
			rondar(delta, johnny, hacia, d)
			if t >= dur:
				elegir(johnny, hacia, d)
		"aviso_tijeretazo":
			frenar(delta)
			if t >= AVISO_TIJERETAZO:
				cambiar("tijeretazo", {"angulo": datos.angulo})
				tijeretazo(johnny)
		"tijeretazo":
			frenar(delta)
			if t >= 0.4:
				andar(0.6)
		"aviso_alfileres":
			# la raya sigue a Johnny (despacio) hasta un poco antes de tirar
			frenar(delta)
			if t < datos.aviso - FIJA:
				var paso := GIRO_RAYA * delta
				datos.angulo += clampf(angle_difference(datos.angulo, hacia.angle()), -paso, paso)
				mirada = Vector2.from_angle(datos.angulo)
			if t >= datos.aviso:
				cambiar("alfileres", {"angulo": datos.angulo, "quedan": ALFILERES[fase - 1], "siguiente": 0.0})
		"alfileres":
			frenar(delta)
			datos.siguiente -= delta
			if datos.quedan > 0 and datos.siguiente <= 0.0:
				lanzar_alfiler(position, datos.angulo + randf_range(-0.03, 0.03))
				datos.quedan -= 1
				datos.siguiente = CADA_ALFILER
			elif datos.quedan <= 0 and datos.siguiente <= -0.25:
				andar(0.6)
		"aviso_carrete":
			frenar(delta)
			if t >= AVISO_CARRETE:
				# un abanico de carretes de golpe: la sala se llena de hilos enseguida (por eso conviene cortarlos)
				for i in CARRETES:
					var abre := (i - (CARRETES - 1) / 2.0) * ABANICO_CARRETES
					if hilos_vivos() < MAX_HILOS:
						tirar_carrete(datos.angulo + abre)
				cambiar("carrete", {"angulo": datos.angulo})
		"carrete":
			frenar(delta)
			if t >= 0.35:
				andar(0.5)
		"tensar":
			frenar(delta)
			if t >= TENSAR:
				andar(0.4)
		"a_por":
			# corre a por Johnny atado y, al llegar, el tijeretazo
			marcha = camino_a(johnny) * CARRERA_ATADO
			mirada = hacia.normalized()
			if d < DISTANCIA_TIJERETAZO * 0.8:
				apuntar_tijeretazo(hacia)
			elif t >= 1.0:
				andar(0.3)
		"ojos":
			# le brillan los ojos... y se cambia de sitio (si le pegan antes, se queda: la han pillado)
			frenar(delta)
			if datos.get("pillada", false):
				pillada()
			elif t >= OJOS:
				cambiarse(johnny)
		"escondida":
			marcha = Vector2.ZERO
			mirada = Vector2.DOWN
			parpadeo -= delta
			if parpadeo <= -0.18:
				parpadeo = randf_range(PARPADEO[0], PARPADEO[1])
			# cada DISPARO_ESCONDIDA, tres alfileres (el suyo y dos señuelos), con su aviso antes. Con su propio reloj, que
			# solo corre aquí (mientras sale su presentación no piensa: si no, nada más acabar ya tiraba)
			reloj_tiros -= delta
			if not datos.has("tiros") and reloj_tiros <= AVISO_ESCONDIDA:
				datos.tiros = apuntar_escondida(johnny)
			if datos.has("tiros") and reloj_tiros <= 0.0:
				disparar_escondida(datos.tiros)
				datos.erase("tiros")
				reloj_tiros = DISPARO_ESCONDIDA
			if t >= datos.dur:
				salir(johnny, hacia, d)
		"descubierta":
			# aturdida: el doble de daño (danar) y estrellitas
			marcha = Vector2.ZERO
			if t >= DESCUBIERTA:
				espera.esconderse = ESPERAS.esconderse[0]
				andar(0.3)
		"pillada":
			# un respingo (su animación de golpe) y salta a por Johnny
			frenar(delta)
			if t >= 0.35:
				if d < DISTANCIA_TIJERETAZO + 40.0:
					apuntar_tijeretazo(hacia)
				elif d < ALCANCE_ALFILERES and ve_a(johnny):
					apuntar_alfileres(hacia)
				else:
					andar(0.4)
		"aviso_corte":
			# la franja hasta la pared, que sigue a Johnny hasta un poco antes
			frenar(delta)
			if t < datos.aviso - FIJA:
				mirada = hacia.normalized()
			if t >= datos.aviso:
				cambiar("corte", {"quedan": datos.quedan, "dio": false})
				Sonido.tocar("tijeras")
		"corte":
			if correr_corte(delta, johnny):
				soltar_tajo(datos.get("desde", global_position))
				if datos.quedan > 1:
					cambiar("aviso_corte", {"aviso": AVISO_CORTE[1], "quedan": datos.quedan - 1})
					mirada = global_position.direction_to(johnny.global_position)
				else:
					andar(0.7)
		"congelada":
			marcha = Vector2.ZERO
			if t >= CONGELADA:
				sprite.modulate = Color(1.0, 0.8, 0.78)
				sin_foco = INMUNE_FOCO
				andar(0.3)
		"atontado":
			marcha = Vector2.ZERO
			if t >= datos.get("dura", 2.0):
				andar(0.3)


# Andando: en la tienda se queda a media distancia; en la pasarela, además, se aparta del foco
func rondar(delta: float, johnny: Node2D, hacia: Vector2, d: float) -> void:
	var rapidez: float = VELOCIDAD[fase - 1] * (ANDA_CRECIDA if crecida > 0.0 else 1.0)
	var quiero := Vector2.ZERO
	if d > LEJOS + 60.0:
		quiero = camino_a(johnny) * rapidez
	elif d < LEJOS - 80.0:
		quiero = -hacia.normalized() * rapidez * 0.8
	else:
		quiero = hacia.normalized().orthogonal() * rapidez * 0.5 * (1.0 if int(tiempo / 3.0) % 2 else -1.0)
	if is_instance_valid(foco):
		var lejos_foco := global_position - foco.global_position
		if lejos_foco.length() < FocoModista.RADIO * 2.0:
			quiero += lejos_foco.normalized() * rapidez * 1.2
	marcha += (quiero.limit_length(rapidez * 1.2) - marcha) * (1.0 - exp(-delta * 6.0))
	if marcha.length() > 10.0:
		mirada = marcha.normalized() if d > LEJOS else hacia.normalized()


func elegir(johnny: Node2D, hacia: Vector2, d: float) -> void:
	var f := fase - 1
	# de cerca, el tijeretazo... pero no más de SEGUIDOS veces seguidas: luego, otra cosa (24 nov, el dueño: a
	# cuerpo a cuerpo solo daba tijeretazos). Entonces los alfileres y el esconderse valen también de cerca
	if d < DISTANCIA_TIJERETAZO and espera.tijeretazo <= 0.0 and seguidos < SEGUIDOS:
		seguidos += 1
		apuntar_tijeretazo(hacia)
		return
	var antes := seguidos
	var de_cerca_vale := seguidos >= SEGUIDOS
	seguidos = 0
	if fase == 1:
		if espera.tensar <= 0.0 and hilos_tendidos() >= MIN_TENSAR:
			espera.tensar = ESPERAS.tensar[f]
			tensar()
			return
		if espera.esconderse <= 0.0 and (d > 160.0 or de_cerca_vale) and maniqui_lejos(johnny) != null:
			espera.esconderse = ESPERAS.esconderse[f]
			cambiar("ojos")
			# (lo grita donde está ahora: luego, escondida, ya no dice nada que la delate)
			gritar(Idioma.t("¿A QUE NO ME ENCUENTRAS?"), Color("#ffd23f"), 18)
			return
		if espera.carrete <= 0.0 and hilos_vivos() < MAX_HILOS:
			espera.carrete = ESPERAS.carrete[f]
			var angulo := hacia.angle() + randf_range(-ABRE_CARRETE, ABRE_CARRETE)
			mirada = Vector2.from_angle(angulo)
			cambiar("aviso_carrete", {"angulo": angulo})
			return
	else:
		if espera.corte <= 0.0:
			espera.corte = ESPERAS.corte[f]
			mirada = hacia.normalized()
			cambiar("aviso_corte", {"aviso": AVISO_CORTE[0], "quedan": CORTES})
			gritar(Idioma.t("¡A LA PASARELA!"), Color("#ff5d73"), 18)
			return
	if (d > 160.0 or de_cerca_vale) and d < ALCANCE_ALFILERES and espera.alfileres <= 0.0 and ve_a(johnny):
		apuntar_alfileres(hacia)
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	seguidos = antes
	andar(0.3)


func apuntar_tijeretazo(hacia: Vector2) -> void:
	espera.tijeretazo = ESPERAS.tijeretazo[fase - 1]
	mirada = hacia.normalized()
	cambiar("aviso_tijeretazo", {"angulo": hacia.angle()})


func apuntar_alfileres(hacia: Vector2) -> void:
	espera.alfileres = ESPERAS.alfileres[fase - 1]
	mirada = hacia.normalized()
	cambiar("aviso_alfileres", {"angulo": hacia.angle(), "aviso": AVISO_ALFILERES[fase - 1]})


# El tijeretazo: daña y empuja a Johnny si está dentro del trozo marcado (y no hay una pared o un mueble en medio)
func tijeretazo(johnny: Node2D) -> void:
	Sonido.tocar("tijeras")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_TIJERETAZO and desvio <= MEDIO_TIJERETAZO + 0.15 \
			and not Aviso.tapado(self, johnny.global_position):
		johnny.recibir_dano(DANO_TIJERETAZO, self)
		johnny.empujar(hacia.normalized() * 650.0)


# Un alfiler: una bala de los malos (bala_zombi.gd) con forma de aguja, desde "desde" (en las coordenadas de la sala)
func lanzar_alfiler(desde: Vector2, angulo: float, separacion := -1.0) -> void:
	var dir := Vector2.from_angle(angulo)
	var bala := BALA.instantiate()
	bala.dueno = self
	bala.position = desde + dir * (radio + 6.0 if separacion < 0.0 else separacion)
	bala.velocidad = dir * VELOCIDAD_ALFILER
	bala.dano = DANO_ALFILER
	bala.radio = 5.0
	bala.forma = "alfiler"
	get_parent().add_child(bala)


# ¿Ve a Johnny desde donde está? (los muebles y los maniquíes tapan)
func ve_a(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# ── Los hilos ──

func tirar_carrete(angulo: float) -> void:
	var hilo := HiloModista.new()
	tirados += 1
	hilo.doble = tirados % 3 == 0   # uno de cada tres, el gordo (dos golpes)
	hilo.dir = Vector2.from_angle(angulo)
	hilo.dueno = self
	hilo.position = position + Vector2(0, PIE - 4.0) + hilo.dir.normalized() * (radio + 4.0)   # (antes de entrar: mide la pared desde ahí)
	get_parent().add_child(hilo)
	hilos.append(hilo)
	Sonido.tocar("alfiler")


func hilos_vivos() -> int:
	hilos = hilos.filter(func(h): return is_instance_valid(h) and h.estado != "cortado")
	return hilos.size()


# Los que ya están tendidos de pared a pared (los que pinta la barra de vida y los que cuentan para tensar)
func hilos_tendidos() -> int:
	return hilos.filter(func(h): return is_instance_valid(h) and h.tendido()).size()


# Un hilo tensado ha pillado a Johnny y lo ha dejado atado (hilo_modista.gd): va corriendo a por él con las tijeras
func atado(_johnny: Node2D) -> void:
	if fase == 1 and estado in ["tensar", "andar"]:
		cambiar("a_por")
		gritar(Idioma.t("¡TE TENGO!"), Color("#ff5d73"), 20)


func tensar() -> void:
	cambiar("tensar")
	gritar(Idioma.t("¡A TENSAR!"), Color("#ff5d73"), 20)
	for h in hilos:
		if is_instance_valid(h):
			h.tensar()


# ── Los maniquíes ──

# Los maniquíes de cuerpo entero que hay en el sitio (los muebles de su tienda)
func maniquies() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary \
		and m.datos.get("tipo", "") == MANIQUI)


# Uno al azar lejos de Johnny (y no pegado a ella), o null si no hay
func maniqui_lejos(johnny: Node2D) -> Node2D:
	var buenos := maniquies().filter(func(m): return m.global_position.distance_to(johnny.global_position) > LEJOS_DE_JOHNNY \
		and m.global_position.distance_to(global_position + PIE_MANIQUI) > 120.0)
	return buenos.pick_random() if not buenos.is_empty() else null


# A cada maniquí, su señuelo (el que recibe los golpes de Johnny para saber si se ha equivocado)
func poner_senuelos() -> void:
	for m in maniquies():
		if m.get_node_or_null("Senuelo") == null:
			var s := Senuelo.new()
			s.name = "Senuelo"   # no-tr (nombre de nodo)
			s.modista = self
			s.position = -PIE_MANIQUI
			m.add_child(s)


# Escondida no se queda tranquila (25 nov, el dueño: era fácil esperar): le tira un alfiler a Johnny y, a la vez, otros
# dos maniquíes cualquiera también, para que no se sepa cuál es ella (fijarse en cuál tira siempre es otra pista).
# Para que sea justo, antes sale el aviso de los tres en el suelo (AVISO_ESCONDIDA: la raya de flechas, _draw) y, al
# tirar, un destello rojo y unos retales en el maniquí que tira. apuntar_escondida elige quién y hacia dónde
# ([posición, ángulo] de cada uno); disparar_escondida los suelta
func apuntar_escondida(johnny: Node2D) -> Array:
	var desde: Array[Vector2] = [global_position]
	var otros := get_tree().get_nodes_in_group("senuelos").filter(func(s): return s.revienta <= 0.0 		and s.global_position.distance_to(johnny.global_position) < ALCANCE_ALFILERES and libre(s.global_position, johnny))
	otros.shuffle()
	for s in otros.slice(0, 2):
		desde.append(s.global_position)
	var tiros := []
	for g in desde:
		tiros.append([g, (johnny.global_position - g).angle()])
	return tiros


# ¿Un alfiler tirado desde ahí llega a Johnny? (sale un poco por delante, como en lanzar_alfiler: así no choca con el
# propio maniquí; los muebles y los otros maniquíes lo paran)
func libre(desde: Vector2, johnny: Node2D) -> bool:
	var dir := desde.direction_to(johnny.global_position)
	var rayo := PhysicsRayQueryParameters2D.create(desde + dir * (radio + 6.0), johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


func disparar_escondida(tiros: Array) -> void:
	for tiro in tiros:
		var g: Vector2 = tiro[0]
		var dir := Vector2.from_angle(tiro[1])
		lanzar_alfiler(get_parent().to_local(g), tiro[1])
		# el destello en la mano (a la altura a la que vuelan los alfileres) y unos retales
		var mano := g + Vector2(0, -BalaZombi.ALTO) + dir * 20.0
		for i in 6:
			var v := dir.rotated(randf_range(-0.9, 0.9)) * randf_range(40.0, 110.0)
			Particulas.soltar(get_parent(), get_parent().to_local(mano), v, Color("#ff5d73") if i % 2 == 0 else Color("#fff4c0"), 2, 0.3)
		EfectoSuelo.soltar(get_parent(), "retales", get_parent().to_local(g) + Vector2(0, -30), 0.35)
	Sonido.tocar("alfiler")


# Lo de antes, de golpe (sin aviso): solo para la prueba
func disparo_escondida(johnny: Node2D) -> void:
	disparar_escondida(apuntar_escondida(johnny))


func quitar_senuelos() -> void:
	for s in get_tree().get_nodes_in_group("senuelos"):
		s.remove_from_group("zombis")
		s.queue_free()


# Se cambia de sitio con un maniquí: ella va a donde estaba él y él aparece donde estaba ella. A la vez, sale una
# nube de retales de todos los maniquíes (y de ella): así no se ve con cuál se ha cambiado
func cambiarse(johnny: Node2D) -> void:
	pillada_antes = false
	var m := maniqui_lejos(johnny)
	if m == null:
		andar(0.3)
		return
	vestir(m)
	var antes := global_position
	var paso: Vector2 = antes + PIE_MANIQUI - m.global_position
	global_position = m.global_position - PIE_MANIQUI
	m.global_position += paso
	m.datos.x += paso.x
	m.datos.y += paso.y
	rehornear()
	for otro in maniquies():
		soplo(otro.global_position - PIE_MANIQUI)
	soplo(global_position)
	Sonido.tocar("esquiva")
	marcha = Vector2.ZERO
	mirada = Vector2.DOWN
	parpadeo = randf_range(PARPADEO[0], PARPADEO[1])
	cambiar("escondida", {"dur": ESCONDIDA})


# Deja de estar escondida sin que la pillen: alfileres desde allí o a andar
func salir(johnny: Node2D, hacia: Vector2, d: float) -> void:
	espera.esconderse = ESPERAS.esconderse[0]
	# no la han encontrado a tiempo: sale crecida, un rato más rápida (24 nov, el dueño)
	crecida = CRECIDA
	gritar(Idioma.t("¡DEMASIADO LENTO!"), Color("#ff5d73"), 20)
	Sonido.tocar("rugido")
	soplo(global_position)
	if d > 170.0 and d < ALCANCE_ALFILERES and ve_a(johnny):
		apuntar_alfileres(hacia)
	else:
		andar(0.4)


# Escondida se disfraza de maniquí: en vez de su dibujo, el mismo que los maniquíes de la tienda (vestir copia el del
# maniquí con el que se cambia). Al salir de "escondida", por lo que sea, vuelve a ser ella
func cambiar(nuevo: String, nuevos_datos := {}) -> void:
	super(nuevo, nuevos_datos)
	if nuevo == "escondida":
		reloj_tiros = DISPARO_ESCONDIDA
	var escondida_ya := nuevo == "escondida"
	if is_instance_valid(disfraz):
		disfraz.visible = escondida_ya
	sprite.visible = not (escondida_ya and is_instance_valid(disfraz))


func vestir(m: Node2D) -> void:
	var suyo := m.get_node_or_null("Sprite") as Sprite2D
	if suyo == null:
		return
	if not is_instance_valid(disfraz):
		disfraz = Sprite2D.new()
		add_child(disfraz)
	disfraz.texture = suyo.texture
	disfraz.scale = suyo.scale
	disfraz.centered = false
	disfraz.flip_h = suyo.flip_h
	disfraz.offset = suyo.offset
	disfraz.position = PIE_MANIQUI   # (los pies del maniquí: donde estaban los del de verdad)
	disfraz.visible = false


# ¿Está quieta entre los maniquíes? (el apuntado automático de Johnny no la busca: johnny.gd)
func escondida() -> bool:
	return estado == "escondida"


# Si le pegan escondida, la han encontrado: aturdida y el doble de daño. Con los ojos brillando, solo la pillan (no se
# cambia de sitio). Descubierta o congelada en el foco, le entra el doble
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	match estado:
		"escondida":
			descubrirse()
		"ojos":
			# (solo una vez seguida: si la última vez ya la pillaron, esta se esconde aunque le peguen; 25 nov, el
			# dueño: pegándole sin parar no se escondía nunca)
			if not pillada_antes:
				datos.pillada = true
				pillada_antes = true
		"descubierta":
			return roundi(cantidad * MAS_DESCUBIERTA)
		"congelada":
			return roundi(cantidad * MAS_CONGELADA)
	return cantidad


func descubrirse() -> void:
	cambiar("descubierta")
	marcha = Vector2.ZERO
	gritar(Idioma.t("¡ME HAS VISTO!"), Color("#ffd23f"), 20)
	Sonido.tocar("golpe")
	soplo(global_position)


func pillada() -> void:
	espera.esconderse = ESPERAS.esconderse[0]
	cambiar("pillada")
	gritar(Idioma.t("¡SSSS!"), Color("#ff5d73"), 20)


# Le han pegado a un maniquí (su señuelo): si ella está escondida y no es ella, revienta en alfileres
func maniqui_golpeado(s: Senuelo) -> void:
	if estado != "escondida" or s.revienta > 0.0 or s.espera > 0.0:
		return
	s.revienta = REVIENTA
	Sonido.tocar("alfiler")


# El maniquí equivocado revienta: un anillo de alfileres alrededor y una nube de retales
func reventar(s: Senuelo) -> void:
	var desde: Vector2 = get_parent().to_local(s.global_position)
	var giro := randf() * TAU
	for i in ALFILERES_REVIENTA:
		lanzar_alfiler(desde, giro + i * TAU / ALFILERES_REVIENTA, 30.0)
	soplo(s.global_position)
	Sonido.tocar("tijeras")
	Temblor.temblar(4.0)


# El mapa vuelve a mirar por dónde se puede andar (los maniquíes han cambiado de sitio)
func rehornear() -> void:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.has_method("rehornear"):
		mapa.rehornear()


# Una nube de retales (pixelfx: tools/pixelfx/retales.js) donde aparece o desaparece
func soplo(donde: Vector2) -> void:
	EfectoSuelo.soltar(get_parent(), "retales", get_parent().to_local(donde) + Vector2(0, -30), 0.8)


# ── La pasarela (fase 2) ──

func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	crecida = 0.0
	super(johnny, Idioma.t("¡QUE EMPIECE EL DESFILE!"))
	for h in hilos:
		if is_instance_valid(h):
			h.caer()
	hilos.clear()
	quitar_senuelos()
	# las luces se apagan a mitad del grito (con su chasquido) y se enciende el foco
	get_tree().create_timer(0.7, false).timeout.connect(func():
		if is_inside_tree() and estado != "muerto":
			apagar_luces()
			despertar_maniquies(johnny))


func apagar_luces() -> void:
	Sonido.tocar("apagon")
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa:
		for n in mapa.find_children("*", "", true, false):
			if n.scene_file_path == Eventos.LAMPARA and n.get("fuerza") != null:
				lamparas.append([n, n.fuerza])
				n.fuerza = 0.0
				for hijo in ["Bombilla", "Polvo"]:   # no-tr (nombres de nodo)
					if n.has_node(hijo):
						n.get_node(hijo).hide()
	Luz.evento += OSCURO
	foco = FocoModista.new()
	get_parent().add_child(foco)
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("Si el foco la pilla, se queda tiesa..."), 3.5)


# Al caer ella vuelve la luz
func encender_luces() -> void:
	if not is_instance_valid(foco):
		return
	foco.queue_free()
	foco = null
	Luz.evento = maxf(0.0, Luz.evento - OSCURO)
	for l in lamparas:
		if is_instance_valid(l[0]):
			l[0].fuerza = l[1]
			for hijo in ["Bombilla", "Polvo"]:   # no-tr (nombres de nodo)
				if l[0].has_node(hijo):
					l[0].get_node(hijo).show()
	lamparas.clear()


func bajo_foco() -> bool:
	return FocoModista.alumbrado(get_tree(), global_position + Vector2(0, PIE - 10.0))


func congelarse() -> void:
	cambiar("congelada", {"anim": sprite.animation, "frame": sprite.frame})
	marcha = Vector2.ZERO
	sprite.modulate = Color(0.78, 0.8, 0.86)
	gritar(Idioma.t("¡TIESA!"), Color("#fff4c0"), 20)
	Sonido.tocar("golpe")


# Un paso del corte: corre recta con las tijeras por delante y corta a Johnny si le pilla (una vez). Devuelve si ha
# terminado (contra la pared, un mueble o al acabarse el tiempo)
func correr_corte(_delta: float, johnny: Node2D) -> bool:
	if not datos.has("desde"):
		datos.desde = global_position
	marcha = mirada * VELOCIDAD_CORTE
	if randf() < 0.5:
		Particulas.soltar(self, global_position + Vector2(randf_range(-10, 10), PIE),
			-mirada.rotated(randf_range(-0.6, 0.6)) * 60.0, Color("#c8ccd4"), 2, 0.3)
	var d := global_position.distance_to(johnny.global_position)
	if not datos.dio and d < radio + johnny.RADIO + ANCHO_CORTE * 0.5:
		datos.dio = true
		johnny.recibir_dano(DANO_CORTE, self)
		johnny.empujar(mirada.orthogonal() * signf(mirada.orthogonal().dot(johnny.global_position - global_position) + 0.01) * 700.0)
	if t > 0.1 and get_real_velocity().length() < VELOCIDAD_CORTE * 0.35 or t > 0.05 and toca_muro(self):
		marcha = Vector2.ZERO
		return true
	return t >= DURA_CORTE


# El tajo que deja en el suelo por donde ha pasado (blanco, se apaga en un momento)
func soltar_tajo(desde: Vector2) -> void:
	var tajo := TajoCorte.new()
	tajo.a = desde + Vector2(0, PIE - 6.0)
	tajo.b = global_position + Vector2(0, PIE - 6.0)
	get_parent().add_child(tajo)


# Enfadada: tres maniquíes cobran vida (los de la tienda; si no hay bastantes, aparecen a su alrededor)
func despertar_maniquies(johnny: Node2D) -> void:
	var lista := maniquies().filter(func(m): return m.global_position.distance_to(johnny.global_position) > 200.0)
	lista.shuffle()
	var donde := []
	for m in lista.slice(0, VIVOS):
		donde.append(m.global_position)
		m.get_parent().remove_child(m)
		m.queue_free()
	if not donde.is_empty():
		rehornear()
	while donde.size() < VIVOS:
		var a := donde.size() * TAU / VIVOS + randf() * 0.5
		donde.append(global_position + PIE_MANIQUI + Vector2(cos(a), sin(a) * 0.8) * 130.0)
	Bestiario.apuntar("maniqui")   # visto: al bestiario de las Colecciones del ordenador
	for p in donde:
		var vivo := VIVO.new()
		vivo.set_meta("tipo", "maniqui")   # (quién es: Bestiario.de)
		# romperlo cuenta como matarlo (para Colecciones); si se rompen porque ella ha caído, no
		vivo.murio.connect(maniqui_roto)
		get_parent().add_child(vivo)
		vivo.global_position = p - Vector2(0, VIVO.PIE)
		vivos.append(vivo)


# Un maniquí vivo roto por Johnny: uno más matado (Colecciones)
func maniqui_roto() -> void:
	var p := get_tree().current_scene
	if estado != "muerto" and p and p.has_method("contar_matado") and not p.en_pruebas():
		p.contar_matado("maniqui")


func con_estrellas() -> bool:
	return estado in ["atontado", "descubierta"]


func morir() -> void:
	super()
	ojos.queue_redraw()
	for h in hilos:
		if is_instance_valid(h):
			h.cortar()
	quitar_senuelos()
	encender_luces()
	# sin ella, los maniquíes vuelven a ser maniquíes (y se caen)
	for vivo in vivos:
		if is_instance_valid(vivo):
			vivo.morir()


func _exit_tree() -> void:
	# (si se va de la sala con el desfile a medias, que no se quede la oscuridad de más)
	if is_instance_valid(foco):
		Luz.evento = maxf(0.0, Luz.evento - OSCURO)


# ── Dibujo ──

func tiene(nombre: String) -> bool:
	return sprite.sprite_frames.has_animation(nombre)


func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_tijeretazo":
			fijar("tijeretazo", dir, mini(CORTA - 1, int(t / AVISO_TIJERETAZO * CORTA)))
		"tijeretazo":
			var resto := sprite.sprite_frames.get_frame_count("tijeretazo_" + dir) - CORTA
			fijar("tijeretazo", dir, CORTA + clampi(int(t / 0.4 * resto), 0, maxi(0, resto - 1)))
		"aviso_alfileres", "aviso_carrete":
			var aviso: float = datos.aviso if estado == "aviso_alfileres" else AVISO_CARRETE
			fijar("alfileres", dir, mini(LANZA - 1, int(t / aviso * LANZA)))
		"alfileres":
			# con el brazo fuera mientras salen; luego vuelve a la postura
			var total := sprite.sprite_frames.get_frame_count("alfileres_" + dir)
			var k: float = t / (ALFILERES[fase - 1] * CADA_ALFILER + 0.25)
			fijar("alfileres", dir, LANZA + clampi(int(k * (total - LANZA)), 0, maxi(0, total - LANZA - 1)))
		"carrete":
			var total := sprite.sprite_frames.get_frame_count("alfileres_" + dir)
			fijar("alfileres", dir, LANZA + clampi(int(t / 0.35 * (total - LANZA)), 0, maxi(0, total - LANZA - 1)))
		"tensar":
			# tira de los hilos: el brazo atrás (el principio del tijeretazo) y tiembla
			fijar("tijeretazo", dir, 2)
			sprite.position.x = sin(tiempo * 40.0) * 1.0
		"pillada":
			# el respingo, desde el fotograma 2 (en el 1 PixelLab pintó una raya blanca en varias direcciones)
			var total := sprite.sprite_frames.get_frame_count("golpe_" + dir)
			fijar("golpe", dir, mini(total - 1, 2 + int(t / 0.35 * (total - 2))))
		"ojos":
			fijar("quieto", dir, 0)
		"escondida":
			fijar("quieto", "s", 0)
			# respira: sube un píxel la mitad de cada respiración (lo único que la delata)
			if fmod(t, RESPIRA) < RESPIRA * 0.5:
				sprite.position.y = PIE - 2.0
			if is_instance_valid(disfraz):
				disfraz.position.y = PIE_MANIQUI.y - (2.0 if fmod(t, RESPIRA) < RESPIRA * 0.5 else 0.0)
		"descubierta":
			if tiene("aturdida_s"):
				poner("aturdida_s")
			else:
				fijar("golpe", "s", 4 + int(t * 6.0) % 3)
		"aviso_corte":
			var nombre := "corte" if tiene("corte_" + dir) else "tijeretazo"
			fijar(nombre, dir, mini(2, int(t / datos.aviso * 3.0)))
			sprite.position.x = sin(tiempo * 50.0) * 1.0
		"corte":
			var nombre := "corte" if tiene("corte_" + dir) else "tijeretazo"
			fijar(nombre, dir, 3 + int(t * 14.0) % maxi(1, sprite.sprite_frames.get_frame_count(nombre + "_" + dir) - 3))
		"congelada":
			# tiesa en la postura en que la ha pillado (y gris)
			if tiene(datos.anim):
				fijar(datos.anim.get_slice("_", 0), datos.anim.get_slice("_", 1), datos.frame)
		"grito":
			if tiene("desfile_s"):
				fijar("desfile", "s", avance("desfile_s", t / 1.2))
			else:
				fijar("quieto", "s", 0)
				sprite.position.x = sin(tiempo * 50.0) * 2.0
		"atontado":
			fijar("golpe", "s", 4 + int(t * 6.0) % 3)
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD[fase - 1], 0.4, 1.5))
			else:
				poner("reposo_" + dir)
	ojos.queue_redraw()


# Los avisos, en el suelo (por debajo de ella)
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"escondida":
			# el aviso de los alfileres que va a tirar escondida (el suyo y los de dos señuelos)
			if datos.has("tiros"):
				var k := clampf(1.0 - reloj_tiros / AVISO_ESCONDIDA, 0.0, 1.0)
				for i in datos.tiros.size():
					var g: Vector2 = datos.tiros[i][0]
					var a: float = datos.tiros[i][1]
					Aviso.disparo(self, to_local(g) + Vector2(0, 6) + Vector2.from_angle(a) * 30.0, a, ALCANCE_ALFILERES,
						ANCHO_AVISO, k, tiempo, i, 5.0)
		"aviso_tijeretazo":
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_TIJERETAZO, ALCANCE_TIJERETAZO,
				minf(1.0, t / AVISO_TIJERETAZO), tiempo)
		"aviso_alfileres":
			# por donde irán los alfileres, como las cargas: flechas que se encienden hacia fuera (aviso.gd)
			Aviso.disparo(self, Vector2(0, 6), datos.angulo, radio + ALCANCE_ALFILERES, ANCHO_AVISO,
				minf(1.0, t / datos.aviso), tiempo, 0, 5.0)
		"aviso_carrete":
			Aviso.disparo(self, Vector2(0, PIE - 4.0), datos.angulo, radio + 260.0, 8.0,
				minf(1.0, t / AVISO_CARRETE), tiempo, 0, 4.0)
		"aviso_corte":
			franja(1600.0, minf(1.0, t / datos.aviso))


# El brillo de los ojos: antes de cambiarse de sitio (cada vez más fuerte), en algún parpadeo escondida y, en la
# pasarela, siempre (a oscuras es lo que se le ve)
func _pintar_ojos() -> void:
	if estado == "muerto":
		return
	var k := 0.0
	if estado == "ojos":
		k = minf(1.0, t / (OJOS * 0.5))
	elif estado == "escondida" and parpadeo < 0.0:
		k = 0.7
	elif fase == 2 and estado not in ["grito", "congelada"]:
		k = 0.75
	if k <= 0.0:
		return
	var dir := direccion()
	var puntos: Array = OJOS_EN[dir]
	if estado == "escondida" and is_instance_valid(disfraz):
		puntos = OJOS_MANIQUI.map(func(p): return p + Vector2(0, disfraz.position.y - PIE_MANIQUI.y))
	var cabeza: Vector2 = CABEZA if puntos.is_empty() else (puntos[0] + puntos[-1]) / 2.0
	Formas.disco(ojos, cabeza, 16.0, Color(1.0, 0.36, 0.45, 0.18 * k))
	for p in puntos:
		Formas.disco(ojos, p, 4.5, Color(1.0, 0.42, 0.5, 0.45 * k))
		ojos.draw_rect(Rect2(p - Vector2(2, 1), Vector2(4, 2)), Color(1.0, 0.95, 0.7, k))


# El señuelo de un maniquí: va dentro del maniquí (sigue sus cambios de sitio) y es del grupo "zombis" para que le
# lleguen los golpes, los tiros y las explosiones de Johnny. No tiene vida que perder: avisa a la modista
# (maniqui_golpeado) y, si toca, revienta en alfileres tras un aviso (un aro rojo). El apuntado automático no lo busca
# (escondida()). Al pasar a la fase 2 o al caer ella, se quitan (que no se quede la puerta cerrada)
class Senuelo extends CharacterBody2D:
	var modista: Node2D
	var radio := 22.0
	var vida := 1
	var vida_max := 1
	var revienta := 0.0      # > 0: el aviso de reventar, en marcha
	var espera := 0.0        # después de reventar, un rato sin volver a hacerlo
	var tiempo := 0.0

	func _ready() -> void:
		add_to_group("zombis")
		add_to_group("senuelos")
		collision_layer = 0
		collision_mask = 0

	func escondida() -> bool:
		return true

	func recibir_golpe(_cantidad: int, _fuerza: Vector2, _de_lleno := false, _de_aliado := false) -> void:
		if is_instance_valid(modista):
			modista.maniqui_golpeado(self)

	func herir(_cantidad: float, _color := Color.WHITE) -> void:
		pass

	func _physics_process(delta: float) -> void:
		tiempo += delta
		espera -= delta
		if revienta > 0.0:
			revienta -= delta
			if revienta <= 0.0:
				espera = 1.5
				if is_instance_valid(modista):
					modista.reventar(self)
		queue_redraw()

	func _draw() -> void:
		if revienta > 0.0:
			var k: float = 1.0 - revienta / 0.5
			Aviso.golpe(self, Vector2(0, 26), 0.0, PI, 90.0, k, tiempo)


# El tajo blanco que deja un corte por el suelo: una raya que se estrecha y se apaga
class TajoCorte extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var t := 0.0

	func _ready() -> void:
		z_index = -1
		var sin_luz := CanvasItemMaterial.new()
		sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = sin_luz

	func _process(delta: float) -> void:
		t += delta
		if t >= 0.45:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - t / 0.45
		var largo := a.distance_to(b)
		var n := int(largo / 2.0)
		var lado := (b - a).normalized().orthogonal()
		for i in n + 1:
			var u := float(i) / maxf(1.0, n)
			var ancho := sin(u * PI) * 3.0 * k
			var p := a.lerp(b, u) - global_position
			for w in range(-int(ancho), int(ancho) + 1, 2):
				draw_rect(Rect2(((p + lado * w) / 2.0).floor() * 2.0, Vector2(2, 2)),
					Color(1.0, 0.98, 0.92, k * (1.0 if w == 0 else 0.6)))
