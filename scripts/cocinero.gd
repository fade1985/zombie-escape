# El cocinero: uno de los cuatro minijefes del centro comercial (su tienda, la Cocina central). Un cocinero zombi
# enorme y gordo, con su gorro y un cuchillo de carnicero. Lo común de los minijefes, en minijefe.gd.
# Rehecho el 23 nov (docs/JEFES_CENTRO.md, «El banquete»): la cocina es su reloj; si no le cortas la comida, se cura.
#
# Es lento y se queda a media distancia. En las dos fases:
#   - La olla: en medio de su cocina hay una olla gigante (el mueble "bigpot", catalogo.gd). Cada tanto va a ella y la
#     remueve (una barrita encima dice cuánto le falta); al terminar se come el guiso y se cura un poco por cada saco
#     de ingredientes que quede. Los sacos (saco_ingredientes.gd): tres que caen por la cocina cada vez que cocina. Si
#     Johnny los rompe todos, el guiso sale malo: se pone enfermo, doblado unos segundos, y le entra el doble (la
#     ventana para pegarle). Si los rompe antes de tiempo, va a cocinar enseguida («¿Y MIS INGREDIENTES?»). Junto a su
#     barra de vida, tres saquitos que se tachan al romper cada uno (ui/barra_jefe.gd, pintar_sacos).
#   - Fogones en damero (fogones_damero.gd): el suelo, en cuadros grandes, se pone al rojo: primero unos y luego los otros.
#   - Cuchillazo: si Johnny se le pega, marca un trozo de suelo (medio segundo) y le da: 20.
# Fase 1:
#   - Sartenes que rebotan (sarten_rebota.gd): rebotan por la sala soltando gotas de aceite y se acumulan (hasta 4);
#     con tres o más, grita «¡A FREGAR!» y vuelven volando a su mano, dando a quien pillen por el camino.
# A media vida, «servicio de urgencia»: grita, se le cae el gorro (otra hoja: jefe-cocinero-sin, calvo y con un
# cuchillo en cada mano) y recoge las sartenes. Fase 2:
#   - Corte en cruz: avisa con cuatro franjas desde él hasta las paredes, en + o en X (a veces una detrás de la otra).
#   - La olla se vuelca: tiembla y sale una ola de aceite (ola_aceite.gd, el barrido del antidisturbios con otro
#     dibujo) que cruza la sala hacia Johnny; dos olas, cada una con su hueco. Detrás de la olla no llega.
#   - Combo: dos cuchillazos seguidos y en el segundo se le clavan los cuchillos en el suelo (le entra un 50 % más).
#   - Lluvia de cuchillos: los tira hacia arriba y caen 6 alrededor de Johnny, cada uno con su marca.
#   - La olla, más a menudo.
# Sin olla (la sala de pruebas), remueve donde está y la ola sale de él.
# Sus animaciones (PixelLab, tools/jefe_hoja.py): andar, lanzar, cuchillazo, golpe, muerte, remover y enfermo; y las
# mismas sin gorro en la fase 2. Lo que lanza sale en el fotograma en el que el brazo llega adelante (SUELTA) y el
# cuchillazo hace daño en el del tajo (TAJO).
extends Minijefe

const HOJA_SIN := preload("res://assets/sprites/jefe-cocinero-sin.tres")
const VELOCIDAD := [60.0, 80.0]
const CERCA := 200.0               # si Johnny está más cerca que esto, se aparta...
const LEJOS := 360.0               # ...y si está más lejos, va a por él (entre medias, pasitos de lado)
# la olla
const CADA_COCINA := [17.0, 12.0]  # cada cuánto va a cocinar (normal y enfadado)
const PRISA := 2.5                 # sin sacos, lo que tarda en ir a cocinar
const REMUEVE := [4.5, 3.5]        # lo que tarda en remover
const CURA_SACO := [0.04, 0.05]    # lo que se cura por cada saco que quede (parte de su vida)
const SACOS := 3
const ENFERMO := 4.5               # lo que se queda doblado con el guiso malo
const DOBLE := 2.0                 # lo que le entra enfermo
const ARCADAS := [0.15, 1.7, 3.2]  # cuándo vomita estando enfermo (además, estrellitas: con_estrellas)
const CHARCO := "res://escenas/armas/charco.tscn"
const CLAVADO := 1.6               # con los cuchillos clavados en el suelo
const MAS_CLAVADO := 1.5           # lo que le entra así
# los ataques
const AVISO_CUCHILLAZO := 0.5
const ALCANCE_CUCHILLAZO := 110.0
const MEDIO_CUCHILLAZO := 0.9      # medio ángulo del trozo que barre
const DANO_CUCHILLAZO := 20
const DISTANCIA_CUCHILLAZO := 140.0   # si Johnny está más cerca que esto, prefiere el cuchillazo (o el combo)
const AVISO_COMBO := [0.5, 0.35]   # el de cada golpe del combo
const AVISO_SARTEN := 0.6
const VELOCIDAD_SARTEN := 260.0
const MAX_SARTENES := 4
const AVISO_FREGAR := 0.8
const AVISO_DAMERO := [1.1, 0.8]   # lo que avisa cada tanda de fogones
const AVISO_CRUZ := 0.8
const AVISO_CRUZ_2 := 0.55         # la segunda cruz, cuando la encadena
const MEDIO_CRUZ := 20.0           # medio ancho de cada franja
const DANO_CRUZ := 18
const AVISO_OLA := 1.0
const AVISO_LLUVIA := 0.5          # lo que tarda en tirarlos hacia arriba
const LLUVIA := 6                  # los que caen alrededor de Johnny
const MARCA_LLUVIA := 0.6          # lo que está cada marca en el suelo antes de caer su cuchillo
const HUECO_LLUVIA := 0.15         # entre una marca y la siguiente
const DANO_LLUVIA := 12
# lo que espera a repetir cada ataque (normal y enfadado; 0: en esa fase no lo hace)
const ESPERAS := {"cuchillazo": [1.4, 1.0], "damero": [9.0, 7.5], "sarten": [5.0, 0.0], "fregar": [12.0, 0.0],
	"cruz": [0.0, 5.0], "ola": [0.0, 13.0], "lluvia": [0.0, 8.0]}
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
# El fotograma de "lanzar" con el brazo del todo adelante y el del tajo del cuchillazo, según hacia dónde mire
const SUELTA := {"e": 4, "se": 4, "n": 4, "no": 4, "s": 5, "ne": 5, "o": 5, "so": 5}
const TAJO := {"s": 4, "se": 4, "e": 4, "n": 4, "ne": 5, "no": 5, "o": 5, "so": 5}
const DESPUES := 0.4               # lo que tarda en acabar la animación después de soltar (y en volver a andar)
const SUBEN := 0.4                 # la lluvia: lo que se ven subir los cuchillos al tirarlos
const OFFSET_SIN := Vector2(-46, -80)   # (el de la hoja sin gorro: lo dice tools/jefe_hoja.py al montarla)

var espera := {"cuchillazo": 0.8, "damero": 4.0, "sarten": 2.0, "fregar": 8.0, "cruz": 1.0, "ola": 5.0, "lluvia": 3.0}
var lado := 1.0                    # hacia qué lado da los pasitos
var cocina := 12.0                 # lo que falta para ir a cocinar
var sacos: Array = []              # los sacos de ingredientes de esta vez (los rotos, ya no válidos)
var olla: Node2D = null            # el mueble de la olla gigante (si lo hay)
var cocinadas := 0                 # las veces que ha terminado de cocinar (para la prueba)


func _ready() -> void:
	super()
	pista.call_deferred()


# La pista para el jugador: Johnny lo dice al entrar (si está la presentación, al acabar)
func pista() -> void:
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("Si se come ese guiso, se cura... A ver qué cocina sin ingredientes"), 4.0)


func pensar(delta: float, johnny: Node2D) -> void:
	for k in espera:
		espera[k] -= delta
	if olla == null:
		olla = buscar_olla()
	if sacos.is_empty() and estado != "muerto":
		reponer(johnny)
	# sin sacos, a cocinar ya (y le saldrá malo)
	if sacos_vivos() == 0 and cocina > PRISA and estado == "andar":
		cocina = PRISA
		gritar(Idioma.t("¿Y MIS INGREDIENTES?"), Color("#ffb347"), 20)
	cocina -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			mirada = hacia.normalized()   # no le quita ojo a Johnny
			guardar_distancia(delta, johnny, hacia, d)
			if t >= dur:
				elegir(johnny, d)
		"ir_olla":
			ir_olla(delta)
		"remover":
			frenar(delta)
			if olla:
				mirada = global_position.direction_to(centro_olla())
			echar_vapor()
			if t >= REMUEVE[fase - 1]:
				comer()
		"enfermo":
			frenar(delta)
			# vomita a arcadas: un chorro y un charco delante de él en cada una, y entre medias, babas
			for arcada in ARCADAS:
				if t - delta < arcada and t >= arcada:
					vomitar()
			if randf() < delta * 4.0:
				Particulas.volar(self, global_position + mirada * 30.0, 40.0, mirada * randf_range(40, 90),
					randf_range(20, 60), Color("#8ab83a"), randf_range(3, 5))
			if t >= ENFERMO:
				andar(0.4)
		"aviso_cuchillazo":
			frenar(delta)
			if t >= AVISO_CUCHILLAZO:
				cambiar("cuchillazo", {"angulo": datos.angulo})
				cuchillazo(johnny, DANO_CUCHILLAZO)
		"aviso_combo":
			frenar(delta)
			if t >= AVISO_COMBO[datos.golpe]:
				cambiar("combo", {"angulo": datos.angulo, "golpe": datos.golpe})
				marcha = Vector2.from_angle(datos.angulo) * 160.0   # (un pasito adelante con cada golpe)
				cuchillazo(johnny, DANO_CUCHILLAZO)
		"combo":
			frenar(delta, 6.0)
			if t >= 0.25:
				if datos.golpe == 0:
					var a := (johnny.global_position - global_position).angle()
					empezar("aviso_combo", a, {"golpe": 1})
				else:
					cambiar("clavado")
					Sonido.tocar("clonc")
					gritar(Idioma.t("¡SE ME HAN CLAVADO!"), Color("#ffd23f"), 18)
		"clavado":
			frenar(delta)
			if t >= CLAVADO:
				andar(0.5)
		"aviso_sarten":
			frenar(delta)
			mirada = hacia.normalized()
			if t >= AVISO_SARTEN:
				cambiar("sarten")
				sarten()
		"aviso_fregar":
			frenar(delta)
			if t >= AVISO_FREGAR:
				andar(0.4)
		"aviso_damero":
			frenar(delta)
			if t >= 0.3:
				damero()
				andar(0.4)
		"aviso_cruz":
			frenar(delta)
			if t >= (AVISO_CRUZ_2 if datos.get("segunda", false) else AVISO_CRUZ):
				cambiar("cruz", {"giro": datos.get("giro", 0.0), "segunda": datos.get("segunda", false)})
				cruz(johnny)
		"cruz":
			frenar(delta)
			if t >= DESPUES:
				# a veces encadena la otra (la + y luego la X, o al revés)
				if not datos.segunda and randf() < 0.5:
					cambiar("aviso_cruz", {"giro": PI / 4.0 - datos.get("giro", 0.0), "segunda": true})
					Sonido.tocar("barrido")
				else:
					andar(0.5)
		"aviso_ola":
			frenar(delta)
			if olla:
				temblar_olla(t / AVISO_OLA)
			if t >= AVISO_OLA:
				ola(johnny)
				andar(0.6)
		"aviso_lluvia":
			frenar(delta)
			mirada = hacia.normalized()
			if t >= AVISO_LLUVIA:
				cambiar("lluvia")
				lluvia(johnny)
		"cuchillazo", "sarten", "lluvia":
			frenar(delta)
			if t >= DESPUES:
				andar(0.5 if enfadado() else 0.9)


# A media distancia: si Johnny se acerca, se aparta; si se aleja (o no le ve), va a por él; entre medias,
# pasitos de lado
func guardar_distancia(delta: float, johnny: Node2D, hacia: Vector2, d: float) -> void:
	var quiere := Vector2.ZERO
	if d > LEJOS or not a_la_vista(johnny):
		quiere = camino_a(johnny)
	elif d < CERCA:
		quiere = -hacia.normalized()
	else:
		quiere = hacia.normalized().orthogonal() * lado * 0.5
	marcha += (quiere * VELOCIDAD[fase - 1] - marcha) * (1.0 - exp(-delta * 6.0))
	# si se ha topado con algo (andando de lado o hacia atrás), cambia de lado
	if t > 0.3 and marcha.length() > 20.0 and get_real_velocity().length() < 8.0:
		lado = -lado


func elegir(johnny: Node2D, d: float) -> void:
	var f := fase - 1
	var angulo := (johnny.global_position - global_position).angle()
	# lo primero, la olla
	if cocina <= 0.0:
		cambiar("ir_olla")
		gritar(Idioma.t("¡A LOS FOGONES!"), Color("#ffb347"), 20)
		return
	if d < DISTANCIA_CUCHILLAZO and espera.cuchillazo <= 0.0:
		espera.cuchillazo = ESPERAS.cuchillazo[f]
		if enfadado():
			empezar("aviso_combo", angulo, {"golpe": 0})
		else:
			empezar("aviso_cuchillazo", angulo)
		return
	for k in ["ola", "cruz", "damero", "lluvia", "fregar", "sarten"]:
		if ESPERAS[k][f] <= 0.0 or espera[k] > 0.0:
			continue
		if k == "fregar" and sartenes().size() < 3:
			continue
		if k == "sarten" and sartenes().size() >= MAX_SARTENES:
			continue
		if k == "cruz" and d > 520.0:
			continue
		espera[k] = ESPERAS[k][f]
		match k:
			"ola":
				empezar("aviso_ola", angulo)
				gritar(Idioma.t("¡QUE SE VUELCA!"), Color("#ffb347"), 20)
				Sonido.tocar("chisporroteo")
			"cruz":
				cambiar("aviso_cruz", {"giro": 0.0 if randf() < 0.5 else PI / 4.0})
				Sonido.tocar("barrido")
			"damero":
				empezar("aviso_damero", angulo)
				gritar(Idioma.t("¡FUEGO EN LOS FOGONES!"), Color("#ff7a2a"), 18)
			"lluvia":
				empezar("aviso_lluvia", angulo)
			"fregar":
				fregar()
			"sarten":
				empezar("aviso_sarten", angulo)
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# Empieza un ataque mirando hacia donde está Johnny
func empezar(nuevo: String, angulo: float, mas := {}) -> void:
	var d := {"angulo": angulo}
	d.merge(mas)
	cambiar(nuevo, d)
	mirada = Vector2.from_angle(angulo)


# ── La olla ──

func buscar_olla() -> Node2D:
	for m in get_tree().get_nodes_in_group("muebles"):
		if m.get("datos") is Dictionary and m.datos.get("tipo", "") == "bigpot":
			return m
	return null


# El centro de lo que ocupa la olla en el suelo (el mueble tiene su sitio en los pies)
func centro_olla() -> Vector2:
	if olla == null:
		return global_position
	return olla.global_position - Vector2(0, olla.datos.h / 2.0)


# Dónde se pone a remover: al lado de la olla que le pille más cerca (por arriba, abajo o a un lado)
func sitio_olla() -> Vector2:
	if olla == null:
		return global_position
	var c := centro_olla()
	var mejor := c
	var lejos := INF
	for d in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		var p: Vector2 = c + d * (Vector2(olla.datos.w, olla.datos.h) / 2.0 * d.abs()).length() + d * (radio + 14.0)
		if libre(p) and p.distance_to(global_position) < lejos:
			lejos = p.distance_to(global_position)
			mejor = p
	return mejor


# Va hacia la olla (rodeando lo que haya); al llegar (o si tarda mucho), a remover
func ir_olla(delta: float) -> void:
	var sitio := sitio_olla()
	agente.target_position = sitio
	var hacia := global_position.direction_to(agente.get_next_path_position())
	marcha += (hacia * VELOCIDAD[fase - 1] * 1.6 - marcha) * (1.0 - exp(-delta * 6.0))
	if marcha.length() > 10.0:
		mirada = marcha.normalized()
	if global_position.distance_to(sitio) < 18.0 or t > 6.0 or olla == null:
		marcha = Vector2.ZERO
		cambiar("remover")
		Sonido.tocar("chof")


# Mientras remueve, la olla echa vapor
func echar_vapor() -> void:
	if randf() < 0.5:
		var c := centro_olla() - Vector2(0, 50 if olla else 20)
		Particulas.soltar(get_parent(), c + Vector2(randf_range(-30, 30), randf_range(-8, 8)),
			Vector2(randf_range(-12, 12), randf_range(-80, -40)), Color(1, 0.97, 0.92, 0.7), randf_range(4, 8), 0.8)


# Ha terminado de remover: con ingredientes, se cura; sin ninguno, el guiso sale malo y se pone enfermo. Luego caen
# sacos nuevos
func comer() -> void:
	var vivos := sacos_vivos()
	cocinadas += 1
	cocina = CADA_COCINA[fase - 1]
	var johnny := get_tree().get_first_node_in_group("jugador")
	if vivos == 0:
		if olla:
			mirada = centro_olla().direction_to(global_position)   # (se da la vuelta: vomita fuera de la olla, a la vista)
		cambiar("enfermo")
		gritar(Idioma.t("¡PUAJ!"), Color("#8ab83a"), 26)
		Sonido.tocar("chof")
	else:
		var cura := roundi(vida_max * CURA_SACO[fase - 1] * vivos)
		vida = mini(vida + cura, vida_max)
		vida_cambiada.emit(vida, vida_max)
		Zombi.texto_flotante(get_parent(), global_position + Vector2(-30, -arriba - 10), "+%d" % cura, Color("#7ee07e"), 22)
		gritar(Idioma.t("¡ÑAM!"), Color("#7ee07e"), 22)
		Sonido.tocar("curar")
		andar(0.4)
	# los que quedaban se los ha echado a la olla: fuera, y caen otros
	for s in sacos:
		if is_instance_valid(s):
			s.queue_free()
	sacos.clear()
	if johnny:
		reponer(johnny)


# Enfermo, con estrellitas de mareo encima de la cabeza (minijefe.actualizar_estrellas)
func con_estrellas() -> bool:
	return estado == "enfermo" or super()


# Una arcada: un chorro de vómito que sale de la boca hacia delante y un charco donde cae (el "vomito" de charco.gd: a
# Johnny no le hace nada)
func vomitar() -> void:
	var boca := global_position + mirada * 26.0
	for i in 18:
		var v := mirada.rotated(randf_range(-0.35, 0.35)) * randf_range(90, 220)
		Particulas.volar(self, boca, 50.0, v, randf_range(30, 90),
			Color("#b89a34") if i % 3 else Color("#8ab83a"), randf_range(4, 7))
	var charco: Node2D = load(CHARCO).instantiate()
	charco.tipo = "vomito"
	charco.dueno = self
	charco.escala = 0.7
	charco.position = ((global_position + mirada * 70.0) / 2.0).round() * 2.0
	get_parent().add_child(charco)
	Sonido.tocar("chof")


# Caen tres sacos nuevos por la cocina: lejos de la olla, de Johnny y entre sí
func reponer(johnny: Node2D) -> void:
	var c := centro_olla() if olla else global_position
	var puestos: Array = []
	for i in SACOS:
		var donde := Vector2.INF
		for intento in 30:
			var p := c + Vector2.from_angle(randf() * TAU) * randf_range(200.0, 420.0) * Vector2(1.0, 0.75)
			if not libre(p) or p.distance_to(johnny.global_position) < 120.0:
				continue
			if puestos.any(func(q): return q.distance_to(p) < 170.0):
				continue
			donde = p
			break
		if donde == Vector2.INF:
			donde = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(),
				c + Vector2.from_angle(i * TAU / SACOS) * 260.0)
		puestos.append(donde)
		var s := SacoIngredientes.new()
		s.tipo = i % 3
		s.position = donde
		get_parent().add_child(s)
		sacos.append(s)


func sacos_vivos() -> int:
	return sacos.filter(func(s): return is_instance_valid(s) and not s.roto).size()


# Para la barra de vida: cuántos sacos hay y cuántos están rotos (ui/barra_jefe.gd)
func sacos_rotos() -> int:
	return SACOS - sacos_vivos() if not sacos.is_empty() else 0


# El aviso de la ola: la olla tiembla y se pone al rojo ("k", de 0 a 1)
func temblar_olla(k: float) -> void:
	var dibujo: Sprite2D = olla.get_node_or_null("Sprite")   # no-tr
	if dibujo == null:
		return
	if k >= 1.0:
		dibujo.position.x = 0.0
		dibujo.modulate = Color.WHITE
		return
	dibujo.position.x = roundf(sin(tiempo * 50.0) * 2.0 * k / 2.0) * 2.0
	dibujo.modulate = Color.WHITE.lerp(Color(1.0, 0.55, 0.35), k * (0.5 + 0.5 * sin(tiempo * 20.0)))


# ── Los ataques ──

# El cuchillazo: daña y empuja a Johnny si está dentro del trozo marcado (y no hay una pared o un mueble en medio)
func cuchillazo(johnny: Node2D, dano: int) -> void:
	Sonido.tocar("barrido")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_CUCHILLAZO and desvio <= MEDIO_CUCHILLAZO + 0.15 \
			and not Aviso.tapado(self, johnny.global_position):
		johnny.recibir_dano(dano, self)
		johnny.empujar(hacia.normalized() * 500.0)


# La sartén: sale de su mano hacia Johnny (un poco desviada) y se queda rebotando
func sarten() -> void:
	var s := SartenRebota.new()
	s.dueno = self
	var a := mirada.angle() + randf_range(-0.35, 0.35)
	s.position = global_position + Vector2.from_angle(a) * (radio + 14.0)
	s.velocidad = Vector2.from_angle(a) * VELOCIDAD_SARTEN
	get_parent().add_child(s)
	Sonido.tocar("lanzar")


func sartenes() -> Array:
	return get_tree().get_nodes_in_group("sartenes")


# «¡A FREGAR!»: las sartenes tiemblan y vuelven volando a su mano
func fregar() -> void:
	cambiar("aviso_fregar")
	gritar(Idioma.t("¡A FREGAR!"), Color("#ffb347"), 22)
	for s in sartenes():
		s.pedir_vuelta()


# Los fogones en damero, en toda su cocina
func damero() -> void:
	var f := FogonesDamero.new()
	f.dueno = self
	f.aviso = AVISO_DAMERO[fase - 1]
	f.position = centro_olla() if olla else global_position
	get_parent().add_child(f)


# Las cuatro direcciones de la cruz (en + con giro 0; en X con giro PI/4)
func brazos(giro: float) -> Array:
	return [giro, giro + PI / 2.0, giro + PI, giro - PI / 2.0]


# El corte en cruz: si Johnny está en alguna de las cuatro franjas (hasta la pared), le da
func cruz(johnny: Node2D) -> void:
	Sonido.tocar("barrido")
	Temblor.temblar(5.0)
	var rel: Vector2 = johnny.global_position - global_position
	for a in brazos(datos.get("giro", 0.0)):
		var d := Vector2.from_angle(a)
		var largo := Aviso.alcance(self, Vector2(0, 6), a, 1400.0, MEDIO_CRUZ)
		var a_lo_largo := rel.dot(d)
		if a_lo_largo > 0.0 and a_lo_largo < largo + johnny.RADIO and absf(rel.cross(d)) < MEDIO_CRUZ + johnny.RADIO:
			johnny.recibir_dano(DANO_CRUZ, self)
			johnny.empujar(d * 400.0)
			return


# La olla se vuelca: dos olas de aceite hacia Johnny, cada una con su hueco
func ola(johnny: Node2D) -> void:
	var o := OlaAceite.new()
	o.dueno = self
	o.position = centro_olla() if olla else global_position
	o.dir = johnny.global_position - o.position
	o.olas = [{"sale": 0.0}, {"sale": 1.6}]
	get_parent().add_child(o)


# La lluvia: caen alrededor de Johnny, cada marca un poco después de la anterior; la primera, donde va a estar
func lluvia(johnny: Node2D) -> void:
	Sonido.tocar("cuchillos")
	for i in LLUVIA:
		var donde: Vector2 = johnny.global_position + johnny.velocity * (MARCA_LLUVIA + i * HUECO_LLUVIA + Cuchillo.CAIDA)
		if i > 0:
			for intento in 4:
				donde = johnny.global_position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 150.0)
				if libre(donde):
					break
		if not libre(donde):
			if i > 0:
				continue
			donde = johnny.global_position
		var c := Cuchillo.new()
		c.dueno = self
		c.modo = "cae"
		c.position = donde
		c.aviso = MARCA_LLUVIA
		c.espera = i * HUECO_LLUVIA
		c.dano = DANO_LLUVIA
		get_parent().add_child(c)


# Si Johnny está a la vista (sin paredes ni muebles en medio)
func a_la_vista(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Si ahí se puede estar (dentro del mapa de navegación: ni pared, ni mueble, ni fuera del local)
func libre(p: Vector2) -> bool:
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), p).distance_to(p) < 12.0


# Los fogones industriales y las freidoras de la cocina (la prueba de la puerta los mira)
func fogones() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary \
		and m.datos.get("tipo", "") in ["industrialstove", "fryer"])


# ── Recibir golpes, enfadarse y morir ──

# Enfermo, le entra el doble; con los cuchillos clavados, un 50 % más
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	match estado:
		"enfermo":
			return roundi(cantidad * DOBLE)
		"clavado":
			return roundi(cantidad * MAS_CLAVADO)
	return cantidad


# «¡SERVICIO DE URGENCIA!»: recoge las sartenes y se le cae el gorro (la hoja cambia a mitad del grito: animar)
func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	var sart := sartenes()
	super(johnny, Idioma.t("¡SERVICIO DE URGENCIA!"))   # (borra lo que vuela, también las sartenes)
	for s in sart:
		if is_instance_valid(s):
			s.queue_free()
	cocina = minf(cocina, CADA_COCINA[1])


func morir() -> void:
	super()
	# lo suyo se va con él (los sacos están en el grupo "zombis": si no, la puerta no se abriría)
	for s in sacos:
		if is_instance_valid(s):
			s.romper()
	for g in ["sartenes"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	for n in get_parent().get_children():
		if n is FogonesDamero or n is OlaAceite:
			n.queue_free()
	if olla:
		temblar_olla(1.0)


# ── Dibujo ──

func animar() -> void:
	# a mitad del grito de enfadarse, la hoja sin gorro
	if fase == 2 and sprite.sprite_frames != HOJA_SIN and not (estado == "grito" and t < 0.6):
		sprite.sprite_frames = HOJA_SIN
		sprite.offset = OFFSET_SIN
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_lluvia":
			preparar("lanzar", dir, SUELTA[dir], AVISO_LLUVIA)
		"aviso_sarten":
			preparar("lanzar", dir, SUELTA[dir], AVISO_SARTEN)
		"aviso_damero", "aviso_fregar":
			preparar("lanzar", dir, SUELTA[dir], 0.3 if estado == "aviso_damero" else AVISO_FREGAR)
		"lluvia", "sarten":
			soltar("lanzar", dir, SUELTA[dir])
		"aviso_cuchillazo":
			preparar("cuchillazo", dir, TAJO[dir], AVISO_CUCHILLAZO)
		"aviso_combo":
			preparar("cuchillazo", dir, TAJO[dir], AVISO_COMBO[datos.golpe])
		"aviso_cruz":
			preparar("cuchillazo", dir, TAJO[dir], AVISO_CRUZ_2 if datos.get("segunda", false) else AVISO_CRUZ)
		"cuchillazo", "combo", "cruz":
			soltar("cuchillazo", dir, TAJO[dir])
		"clavado":
			fijar("cuchillazo", dir, sprite.sprite_frames.get_frame_count("cuchillazo_" + dir) - 1)
			sprite.position.x = sin(tiempo * 40.0) * 2.0 if t < 0.5 else 0.0   # (tira, y no salen)
		"aviso_ola":
			fijar("golpe", dir, avance("golpe_" + dir, minf(1.0, t / AVISO_OLA)))
		"remover":
			poner("remover_" + dir)
		"enfermo":
			poner("enfermo_" + dir, 0.8)
		"grito":
			# al enfadarse: se encoge como si le hubieran dado y luego tiembla de rabia
			fijar("golpe", dir, avance("golpe_" + dir, t / 0.6))
			if t > 0.6:
				sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				# si va hacia atrás (apartándose de Johnny sin dejar de mirarle), las piernas también
				var atras := -1.0 if marcha.dot(mirada) < -0.3 * marcha.length() else 1.0
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD[fase - 1], 0.4, 1.5) * atras)
			else:
				poner("reposo_" + dir)


# Antes de soltar: hasta el fotograma "golpe" (sin llegar) en lo que dura el aviso
func preparar(anim: String, dir: String, golpe: int, aviso: float) -> void:
	fijar(anim, dir, mini(golpe - 1, int(t / aviso * golpe)))


# Y desde el fotograma "golpe" hasta el final, en lo que tarda en volver a andar
func soltar(anim: String, dir: String, golpe: int) -> void:
	var resto := sprite.sprite_frames.get_frame_count(anim + "_" + dir) - golpe
	fijar(anim, dir, golpe + clampi(int(t / DESPUES * resto), 0, maxi(0, resto - 1)))


# Los avisos, en el suelo (por debajo de él): el trozo del cuchillazo y las franjas de la cruz; y el tajo de la cruz
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_cuchillazo":
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_CUCHILLAZO, ALCANCE_CUCHILLAZO,
				minf(1.0, t / AVISO_CUCHILLAZO), tiempo)
		"aviso_combo":
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_CUCHILLAZO, ALCANCE_CUCHILLAZO,
				minf(1.0, t / AVISO_COMBO[datos.golpe]), tiempo)
		"aviso_cruz":
			var k := minf(1.0, t / (AVISO_CRUZ_2 if datos.get("segunda", false) else AVISO_CRUZ))
			var brazos_ := brazos(datos.get("giro", 0.0))
			for i in 4:
				Aviso.disparo(self, Vector2(0, 6), brazos_[i], 1400.0, MEDIO_CRUZ, k, tiempo, i)
		"cruz":
			# el tajo: cuatro rayas blancas que se apagan enseguida
			if t < 0.25:
				var a := 1.0 - t / 0.25
				for b in brazos(datos.get("giro", 0.0)):
					var largo := Aviso.alcance(self, Vector2(0, 6), b, 1400.0, MEDIO_CRUZ)
					var d := Vector2.from_angle(b)
					var paso := 2.0
					var n := int(largo / 8.0)
					for j in n:
						var p := ((Vector2(0, 6) + d * (radio + j * 8.0)) / paso).floor() * paso
						draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color(1, 1, 1, 0.8 * a))
						draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), Color(1, 0.4, 0.4, 0.25 * a))


# Por encima: la lluvia (los cuchillos subiendo), la barrita de lo que le falta a la olla y el gorro que sale volando
func pintar_encima(lienzo: Node2D) -> void:
	if estado == "lluvia" and t <= SUBEN:
		var k := t / SUBEN
		for i in LLUVIA:
			var x := (i - (LLUVIA - 1) / 2.0) * 12.0 * (1.0 + k)
			Cuchillo.dibujar(lienzo, Vector2(x, -arriba * 0.7 - k * k * 420.0 - i * 6.0), -PI / 2.0 + tiempo * 14.0 + i)
	if estado == "remover":
		# encima de la olla (o de él, sin olla)
		var arriba_olla := (olla.global_position - Vector2(0, 160)) if olla else global_position - Vector2(0, arriba + 30)
		var c: Vector2 = ((arriba_olla - global_position) / 2.0).floor() * 2.0
		var k := minf(1.0, t / REMUEVE[fase - 1])
		var ancho := 80.0
		lienzo.draw_rect(Rect2(c - Vector2(ancho / 2.0 + 2, 2), Vector2(ancho + 4, 10)), Tema.LINEA)
		lienzo.draw_rect(Rect2(c - Vector2(ancho / 2.0, 0), Vector2(ancho, 6)), Color("#3a2a20"))
		var color := Color("#7ee07e") if sacos_vivos() > 0 else Color("#8ab83a").darkened(0.3)
		lienzo.draw_rect(Rect2(c - Vector2(ancho / 2.0, 0), Vector2(floorf(ancho * k / 2.0) * 2.0, 6)), color)
	if estado == "grito" and fase == 2 and t > 0.4:
		# el gorro, volando hacia arriba y cayendo detrás
		var u := t - 0.4
		var p := Vector2(30.0 * u, -arriba + 20.0 - 260.0 * u + 420.0 * u * u)
		p = (p / 2.0).floor() * 2.0
		lienzo.draw_rect(Rect2(p + Vector2(-12, -6), Vector2(24, 12)), Color("#f4f0e4"))
		lienzo.draw_rect(Rect2(p + Vector2(-16, -16), Vector2(32, 12)), Color("#f4f0e4"))
		lienzo.draw_rect(Rect2(p + Vector2(-12, 6), Vector2(24, 4)), Color("#d8d0c0"))
		lienzo.draw_rect(Rect2(p + Vector2(-4, -12), Vector2(6, 6)), Color("#a83a2a"))
