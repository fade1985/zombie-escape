# El Sujeto 1: el jefe final de Torre Velaria, en el laboratorio de la planta 40 (docs/PLAN_TERCER_EDIFICIO.md,
# punto 6). Una copia de Johnny hecha con su sangre: enorme, pálida, con el peto roto y una fregona gigante. Lo común
# con los minijefes (la vida y su barra, moverse, recibir golpes y morir), en minijefe.gd. Mientras pelea, la
# presidenta maneja el laboratorio desde su cabina (peligros/laboratorio.gd).
#
# Pelea como Johnny, y cada ataque tiene su aviso:
#   - Rodar: cuando le disparan, a veces (1 de cada 3, como mucho cada 2,5 s) rueda de lado y la bala le pasa de largo
#     (bala.gd le pregunta: esquivar_bala). Mientras rueda, ninguna le da.
#   - Fregonazo gigante: si Johnny está cerca, marca en el suelo un abanico rojo (140°, unas 5 casillas) y barre con
#     la fregona: 22 y un empujón.
#   - Cubos de agua: levanta un cubo por encima de la cabeza y tira 3 en curva (uno donde está Johnny y los otros
#     alrededor), cada uno con su anillo rojo donde caerá (proyectil.gd, "cubo"): 8 y un charco de agua que resbala
#     6 s (charco.gd, "agua_cubo").
# A media vida no se enfada como los minijefes: el cuerpo no aguanta y SE PARTE EN DOS (la animación «partirse», sin
# que le hagan daño, un fogonazo y la cabina de la presidenta se rompe). Salen dos Sujetos más pequeños (el mismo
# dibujo, a menor escala) con 750 de vida cada uno, más rápidos y con los mismos ataques, más flojos. Al caer uno, el
# otro se enfada (más rápido y ataca más seguido).
# Para que la partida (partida.gd) y el laboratorio no tengan que saber nada de esto, el Sujeto grande no se va:
# se queda de MANDO, invisible y sin cuerpo, siguiendo a las dos mitades. Su vida es la suma de las dos (lo que
# enseña la barra) y, cuando caen las dos, cae él donde cayó la última: la página del dosier y la puerta del
# helipuerto salen de ahí, como con cualquier jefe final.
# Antes de partirse no puede caer (aunque le den mucho de golpe, se queda con 1): la fase partida siempre llega.
extends Minijefe

# Los números (provisionales, aprobados por el dueño el 5 nov). Donde hay dos: el grande y cada mitad
const VELOCIDAD := [95.0, 120.0]
const ENFADADO := 1.3                    # una mitad enfadada (ha caído la otra): así de rápida, y espera menos
const ESPERA_ENFADADO := 0.6
const ESCALA := [1.4, 1.0]               # lo grande que se dibuja
const RADIO := [36.0, 26.0]
const ARRIBA := [150.0, 100.0]
const PIE := 34.0                        # a qué altura dibuja los pies respecto a su centro
# Rodar
const RODAR_CUANTAS := 3                 # rueda 1 de cada tantas balas que le darían
const RODAR_CADA := 2.5                  # como mucho, cada tantos segundos
const RODAR_DURA := 0.6
const RODAR_VELOCIDAD := 300.0
# Fregonazo
const AVISO_FREGONAZO := 0.6
const MEDIO_FREGONAZO := deg_to_rad(70)  # medio abanico (140° en total)
const ALCANCE_FREGONAZO := [160.0, 130.0]   # unas 5 casillas (el grande)
const DANO_FREGONAZO := [22, 16]
const EMPUJE_FREGONAZO := 800.0
const CERCA_FREGONAZO := 190.0           # si Johnny está más cerca que esto, prefiere el fregonazo
const GOLPE := 4                         # el fotograma en el que la fregona barre el suelo
const DESPUES := 0.45                    # lo que tarda en acabar la animación después del golpe
# Cubos
const AVISO_CUBO := 0.5                  # con el cubo levantado, antes de tirar
const CUBOS := [3, 2]
const LEJOS_CUBO := 560.0
const ESPERAS := {"fregonazo": 1.6, "cubo": 6.0}
# Partirse
const PARTIRSE := 1.5                    # los 13 fotogramas de partirse_s (de frente), sin que le hagan daño
const SEPARA := 70.0                     # lo que se separan las dos mitades al salir
const VERDE := Color("#b6ff6a")          # el VD-7
const PALIDO := Color("#d6d2c4")         # su piel (las chispas al partirse)
const ESCENA := "res://escenas/personajes/sujeto_1.tscn"
const PROYECTIL := preload("res://scripts/proyectil.gd")   # (el dibujo del cubo)

var mitad := false                       # es una de las dos mitades de la fase partida
var mando: Node2D = null                 # (las mitades) el grande, que suma su vida
var mitades := []                        # (el grande, ya partido) las dos mitades
var partido := false                     # (el grande) ya se ha partido: ahora es el mando invisible
var espera := {"fregonazo": 0.8, "cubo": 3.0}
var rodo := -10.0                        # cuándo rodó por última vez (en "tiempo")
var balas := 0                           # las balas que le habrían dado desde que rodó


func _ready() -> void:
	super()
	var k := 1 if mitad else 0
	radio = RADIO[k]
	arriba = ARRIBA[k]
	sprite.scale = Vector2.ONE * ESCALA[k]
	vapor = false   # (no echa el vapor de los minijefes)
	if mitad:
		enfado = 0.0   # (las mitades no se enfadan a media vida: se enfadan al caer la otra)
		$Choque.shape = $Choque.shape.duplicate()
		$Choque.shape.radius = radio
		$Sombra.ancho *= ESCALA[1] / ESCALA[0]
		$Sombra.alto *= ESCALA[1] / ESCALA[0]
		agente.radius = radio + 4.0


func velocidad() -> float:
	return VELOCIDAD[1 if mitad else 0] * (ENFADADO if mitad and enfadado() else 1.0)


func pensar(delta: float, johnny: Node2D) -> void:
	if partido:
		seguir_mitades()
		return
	var k := 1 if mitad else 0
	for e in espera:
		espera[e] -= delta * (1.0 / ESPERA_ENFADADO if mitad and enfadado() else 1.0)
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			if d > ALCANCE_FREGONAZO[k] * 0.6:
				perseguir(delta, johnny, velocidad())
			else:
				frenar(delta)
			mirada = marcha.normalized() if marcha.length() > 10.0 else hacia.normalized()
			if t >= dur:
				elegir(johnny, d)
		"rodar":
			# rueda de lado, a toda prisa, y frena al final
			marcha = datos.hacia * RODAR_VELOCIDAD * (1.0 - smoothstep(0.6, 1.0, t / RODAR_DURA))
			contacto = 0
			if t >= RODAR_DURA:
				andar(0.3)
		"aviso_fregonazo":
			frenar(delta)
			if t >= AVISO_FREGONAZO:
				cambiar("fregonazo", {"angulo": datos.angulo})
				fregonazo(johnny)
		"fregonazo":
			frenar(delta)
			if t >= DESPUES:
				andar(0.5 if mitad else 0.7)
		"aviso_cubo":
			frenar(delta)
			if t >= AVISO_CUBO:
				cambiar("cubo", {"angulo": datos.angulo})
				tirar_cubos(johnny)
		"cubo":
			frenar(delta)
			if t >= DESPUES:
				andar(0.5 if mitad else 0.7)
		"partirse":
			sin_tocar(delta)
			mirada = Vector2.DOWN   # (partirse solo está dibujado de frente)
			if t >= PARTIRSE:
				partir(johnny)


func elegir(johnny: Node2D, d: float) -> void:
	var angulo := (johnny.global_position - global_position).angle()
	if d < CERCA_FREGONAZO * (0.85 if mitad else 1.0) and espera.fregonazo <= 0.0:
		espera.fregonazo = ESPERAS.fregonazo
		empezar("aviso_fregonazo", angulo)
		return
	if d < LEJOS_CUBO and espera.cubo <= 0.0:
		espera.cubo = ESPERAS.cubo
		empezar("aviso_cubo", angulo)
		Sonido.tocar("lanzar")
		return
	andar(0.3)


func empezar(nuevo: String, angulo: float) -> void:
	cambiar(nuevo, {"angulo": angulo})
	mirada = Vector2.from_angle(angulo)


func sin_tocar(delta: float) -> void:
	invulnerable = true
	contacto = 0
	frenar(delta)


# ── Rodar ──

# Le pregunta la bala al llegar a él (bala.gd): si dice que sí, la bala le pasa de largo. Rodando, ninguna le da; andando,
# 1 de cada RODAR_CUANTAS (si hace RODAR_CADA que no rueda) le hace rodar de lado, hacia el lado que esté libre
func esquivar_bala(vel: Vector2) -> bool:
	if estado == "rodar":
		return true
	if estado != "andar" or partido or esperando or tiempo - rodo < RODAR_CADA:
		return false
	balas += 1
	if balas < RODAR_CUANTAS and randf() > 1.0 / RODAR_CUANTAS:
		return false
	balas = 0
	rodo = tiempo
	var lado := vel.normalized().orthogonal() * (1.0 if randf() < 0.5 else -1.0)
	if not libre(global_position + lado * 120.0):
		lado = -lado
	cambiar("rodar", {"hacia": lado})
	mirada = lado
	Sonido.tocar("esquiva")
	return true


# Si ahí se puede estar (dentro del mapa de navegación: ni pared, ni mueble)
func libre(p: Vector2) -> bool:
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), p).distance_to(p) < 12.0


# ── Fregonazo ──

# Daña y aparta a Johnny si está dentro del abanico marcado (y no hay una pared o un mueble en medio)
func fregonazo(johnny: Node2D) -> void:
	var k := 1 if mitad else 0
	Sonido.tocar("barrido")
	Temblor.temblar(5.0 if mitad else 7.0)
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_FREGONAZO[k] and desvio <= MEDIO_FREGONAZO + 0.1 \
			and not Aviso.tapado(self, johnny.global_position) and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(DANO_FREGONAZO[k], self)
		johnny.empujar(hacia.normalized() * EMPUJE_FREGONAZO)


# ── Cubos ──

# Dónde caen: el primero donde está Johnny y los demás alrededor (donde se pueda estar)
func destinos(johnny: Node2D, cuantos: int) -> Array:
	var lista := [johnny.global_position]
	var giro := randf() * TAU
	for i in cuantos - 1:
		lista.append(johnny.global_position + Vector2.from_angle(giro + TAU * i / (cuantos - 1)) * randf_range(90.0, 140.0))
	var mapa := agente.get_navigation_map()
	for i in lista.size():
		lista[i] = NavigationServer2D.map_get_closest_point(mapa, lista[i])
	return lista


func tirar_cubos(johnny: Node2D) -> void:
	Sonido.tocar("lanzar")
	for donde in destinos(johnny, CUBOS[1 if mitad else 0]):
		var p: Node2D = load("res://escenas/armas/proyectil.tscn").instantiate()
		p.tipo = "cubo"
		p.desde = global_position + mirada * 20.0 + Vector2(0, PIE * 0.5)
		p.alto_salida = arriba * 0.8
		p.hasta = donde
		p.dueno = self
		get_parent().add_child(p)


# ── Partirse en dos ──

# A media vida (el grande): en vez del grito de los minijefes, empieza a partirse
func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	if mitad:
		return
	for bala in get_tree().get_nodes_in_group("balas_zombi"):
		bala.queue_free()
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < 240.0:
		johnny.empujar(hacia.normalized() * 800.0)
	gritar(Idioma.t("¡NO AGUANTA!"), VERDE, 24)
	Sonido.tocar("rugido")
	cambiar("partirse")


# Antes de partirse no puede caer: como mucho se queda con 1 (y a media vida se parte seguro)
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	return cantidad if mitad else mini(cantidad, vida - 1)


func morder(cantidad: int) -> void:
	if partido:
		return
	super(cantidad if mitad else mini(cantidad, vida - 1))


func recibir_golpe(cantidad: int, fuerza: Vector2, de_lleno := false, de_aliado := false) -> void:
	if partido:
		return
	super(cantidad, fuerza, de_lleno, de_aliado)


# Se parte: un fogonazo, temblor y dos mitades que salen hacia los lados. Él se queda de mando (invisible): suma la
# vida de las dos y cae cuando caen las dos
func partir(johnny: Node2D) -> void:
	partido = true
	cambiar("partido")
	marcha = Vector2.ZERO
	dano_contacto = 0
	remove_from_group("zombis")
	$Choque.set_deferred("disabled", true)
	sprite.hide()
	$Sombra.hide()
	Luz.destello(self, global_position + Vector2(0, -80), 420.0, 0.7, 1.8, VERDE)
	Temblor.temblar(14.0)
	Sonido.tocar("rugido")
	Sonido.tocar("explosion")
	for i in 28:
		Particulas.soltar(self, global_position + Vector2(randf_range(-40, 40), randf_range(-140, 20)),
			Vector2.from_angle(randf() * TAU) * randf_range(60, 180), [VERDE, PALIDO, Color("#7a1f1a")].pick_random(), 4, 0.8)
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.get("laboratorio"):
		mapa.laboratorio.romper_cabina()
	# hacia los lados de Johnny, para que no le caigan encima
	var lado := global_position.direction_to(johnny.global_position).orthogonal()
	if lado == Vector2.ZERO:
		lado = Vector2.RIGHT
	for s in [-1.0, 1.0]:
		var m: Minijefe = load(ESCENA).instantiate()
		m.mitad = true
		m.mando = self
		m.vida_max = maxi(1, roundi(vida_max / 2.0))
		m.quieto = quieto
		m.set_meta("tipo", get_meta("tipo", "sujeto_1"))   # (el cartel de derrota: quién te ha pillado)
		var donde: Vector2 = global_position + lado * s * SEPARA
		m.position = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), donde)
		m.mirada = lado * s
		m.marcha = lado * s * 260.0
		m.vida_cambiada.connect(func(_v, _m): sumar_vida())
		m.murio.connect(_al_caer_mitad.bind(m))
		mitades.append(m)
		get_parent().add_child(m)
		m.cambiar("rodar", {"hacia": lado * s})   # (salen rodando, cada una hacia su lado)
		m.rodo = m.tiempo
		m.sprite.modulate = Color(2.2, 2.6, 1.8)
		m.create_tween().tween_property(m.sprite, "modulate", Color.WHITE, 0.6)
	gritar(Idioma.t("¡GRAAAAH!"), VERDE, 30)
	sumar_vida.call_deferred()


# La vida del mando: la de las dos mitades juntas (la barra de arriba)
func sumar_vida() -> void:
	var total := 0
	for m in mitades:
		if is_instance_valid(m):
			total += maxi(0, m.vida)
	vida = total
	vida_cambiada.emit(vida, vida_max)


# Ha caído una mitad: si queda la otra, se enfada; si no, cae el mando (donde ha caído la última)
func _al_caer_mitad(m: Node2D) -> void:
	sumar_vida()
	for otra in mitades:
		if otra != m and is_instance_valid(otra) and otra.estado != "muerto":
			otra.enfadar()
			return
	global_position = m.global_position
	vida = 0
	estado = "muerto"
	murio.emit()


# (una mitad) Ha caído la otra: se enfada, como los minijefes a media vida
func enfadar() -> void:
	if fase == 2:
		return
	fase = 2
	cambiar("grito")
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny:
		super.al_enfadarse(johnny, Idioma.t("¡GRRR!"))


# El mando va entre las dos mitades (por si alguien mira dónde está el jefe)
func seguir_mitades() -> void:
	invulnerable = true
	contacto = 0
	marcha = Vector2.ZERO
	var vivas := mitades.filter(func(m): return is_instance_valid(m) and m.estado != "muerto")
	if vivas.is_empty():
		return
	var centro := Vector2.ZERO
	for m in vivas:
		centro += m.global_position
	global_position = centro / vivas.size()


func mover() -> void:
	if partido:
		return
	super()


# En la foto de la prueba (--captura): el ataque que se pida, a punto de soltarse
func foto(johnny: Node2D, ataque := "fregonazo") -> void:
	var angulo := (johnny.global_position - global_position).angle()
	match ataque:
		"cubo":
			empezar("aviso_cubo", angulo)
			t = AVISO_CUBO - 0.05
		_:
			empezar("aviso_fregonazo", angulo)
			t = AVISO_FREGONAZO - 0.05


# ── Dibujo ──

func animar() -> void:
	if partido:
		return
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"rodar":
			fijar("rodar", dir, avance("rodar_" + dir, t / RODAR_DURA))
		"aviso_fregonazo":
			fijar("fregonazo", dir, mini(GOLPE - 1, int(t / AVISO_FREGONAZO * GOLPE)))
		"fregonazo":
			soltar("fregonazo", dir, GOLPE)
		"aviso_cubo":
			# con el cubo en alto (lo pinta pintar_encima), temblando de fuerza
			fijar("cubo", dir, 0)
			sprite.position.x = sin(tiempo * 50.0) * 1.5
		"cubo":
			soltar("cubo", dir, 1)
		"partirse":
			var f := avance("partirse_s", t / PARTIRSE)
			fijar("partirse", "s", f)
			if f >= 6:
				sprite.position.x = sin(tiempo * 60.0) * (2.0 + f * 0.3)
		"grito":
			poner("reposo_" + dir)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / velocidad(), 0.5, 1.5))
			else:
				poner("reposo_" + dir)


# Desde el fotograma "golpe" hasta el final, en lo que tarda en volver a andar
func soltar(anim: String, dir: String, golpe: int) -> void:
	var resto := sprite.sprite_frames.get_frame_count(anim + "_" + dir) - golpe
	fijar(anim, dir, golpe + clampi(int(t / DESPUES * resto), 0, maxi(0, resto - 1)))


# El aviso del fregonazo, en el suelo (por debajo de él): el abanico rojo que se va llenando
func _draw() -> void:
	if estado == "aviso_fregonazo":
		Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_FREGONAZO, ALCANCE_FREGONAZO[1 if mitad else 0],
			minf(1.0, t / AVISO_FREGONAZO), tiempo)


# Por encima: el cubo levantado sobre la cabeza antes de tirar
func pintar_encima(lienzo: Node2D) -> void:
	if estado == "aviso_cubo":
		var sube := minf(1.0, t / (AVISO_CUBO * 0.5))
		PROYECTIL.cubo(lienzo, Vector2(sprite.position.x, -arriba + 18.0 - 14.0 * sube), sin(tiempo * 30.0) * 0.08)
		lienzo.draw_set_transform(Vector2.ZERO)
