# Lo común de los cuatro minijefes del centro comercial (antidisturbios, cocinero, modista y mascota; parte 4
# del plan, docs/CENTRO_COMERCIAL.md). Cada uno es un script que hereda de este y pone sus ataques.
#
# Funcionan como la portera, por ESTADOS: andan un rato hacia Johnny, eligen un ataque, lo AVISAN (siempre se
# puede esquivar) y lo hacen. Lo que es igual en todos está aquí:
#   - la vida y su barra grande (señal vida_cambiada; la partida les sube un 25 % por planta)
#   - a media vida se enfadan: un grito sin que les hagan daño, se ponen rojos y les sale vapor de la cabeza
#   - llamar a otros zombis (señal pide_zombi: la partida los saca)
#   - moverse con el mismo mapa de navegación que los zombis, recibir golpes y morir
# Cada jefe pone en su script: pensar() (qué hace en cada estado), animar(), sus avisos en _draw() y, si quiere,
# danar() (cuánto le hace de verdad un golpe: el escudo del antidisturbios) y al_enfadarse().
# Están en el grupo "zombis" con radio y recibir_golpe(): Johnny, las balas y los lanzables les pegan igual.
class_name Minijefe
extends CharacterBody2D

signal murio
signal vida_cambiada(vida: int, maxima: int)
signal pide_zombi(tipo: String, donde: Vector2)

const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]

@export var vida_max := 500
@export var radio := 32.0
@export var arriba := 120.0        # a qué altura tiene la cabeza (los textos, el vapor y las estrellitas)
@export var dano_contacto := 8     # si Johnny se le pega, también hace daño

var vida := 500
var fase := 1                 # 2 = enfadado
var estado := "andar"
var t := 0.0                  # tiempo que lleva en el estado
var dur := 1.2                # cuánto anda antes de atacar
var datos := {}               # lo que necesita cada ataque
var marcha := Vector2.ZERO    # su velocidad (sin contar los empujones)
var mirada := Vector2.DOWN    # hacia dónde mira
var invulnerable := false
var contacto := 0
var tiempo := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var agente: NavigationAgent2D = $Agente


func _ready() -> void:
	vida = vida_max
	contacto = dano_contacto
	$Vapor.draw.connect(_pintar_encima)
	vida_cambiada.emit.call_deferred(vida, vida_max)


func enfadado() -> bool:
	return fase == 2


func cambiar(nuevo: String, nuevos_datos := {}) -> void:
	estado = nuevo
	t = 0.0
	datos = nuevos_datos


func andar(cuanto: float) -> void:
	cambiar("andar")
	dur = cuanto


func _physics_process(delta: float) -> void:
	if estado == "muerto":
		return
	tiempo += delta
	t += delta
	invulnerable = false
	contacto = dano_contacto
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo:
		frenar(delta)
		mover()
		animar()
		return
	# ¡A mitad de vida se enfada de verdad!
	if fase == 1 and vida <= vida_max * 0.5:
		fase = 2
		cambiar("grito")
		al_enfadarse(johnny)
	if estado == "grito":
		# un momento gritando, sin que le hagan daño
		invulnerable = true
		contacto = 0
		frenar(delta)
		if t >= 1.4:
			andar(0.3)
	else:
		pensar(delta, johnny)
	mover()
	# Si Johnny se le pega, le hace daño (Johnny luego es invulnerable un rato: no le quita en cada paso)
	if contacto > 0 and global_position.distance_to(johnny.global_position) < radio + johnny.RADIO + 4.0:
		johnny.recibir_dano(contacto)
	animar()
	queue_redraw()
	$Vapor.queue_redraw()


# Lo que hace en cada estado: lo pone cada jefe
func pensar(_delta: float, _johnny: Node2D) -> void:
	pass


func animar() -> void:
	pass


# Al enfadarse: borra las balas que hay volando, grita, aparta a Johnny y se pone rojo. Cada jefe pone su grito
func al_enfadarse(johnny: Node2D, grito := "¡GRRR!") -> void:
	for bala in get_tree().get_nodes_in_group("balas_zombi"):
		bala.queue_free()
	gritar(grito, Color("#ffd23f"), 26)
	Sonido.tocar("rugido")
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < 240.0:
		johnny.empujar(hacia.normalized() * 800.0)
	sprite.modulate = Color(1.0, 0.8, 0.78)


func gritar(texto: String, color: Color, tamano := 24) -> void:
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-60, -arriba - 40), texto, color, tamano)


# Llama a otros zombis: aparecen repartidos a su alrededor (la partida los saca)
func llamar(tipo: String, cuantos: int, lejos := 110.0) -> void:
	for i in cuantos:
		var a := float(i) / cuantos * TAU + randf_range(-0.4, 0.4)
		pide_zombi.emit(tipo, global_position + Vector2(cos(a) * lejos, sin(a) * lejos * 0.8))


# Cuántos zombis quedan (sin contarle a él)
func secuaces() -> int:
	return get_tree().get_nodes_in_group("zombis").size() - 1


# ── Moverse ──

# Hacia dónde ir para llegar a Johnny rodeando paredes y muebles (el mismo mapa que los zombis)
func camino_a(johnny: Node2D) -> Vector2:
	agente.target_position = johnny.global_position
	return global_position.direction_to(agente.get_next_path_position())


func perseguir(delta: float, johnny: Node2D, rapidez: float) -> void:
	marcha += (camino_a(johnny) * rapidez - marcha) * (1.0 - exp(-delta * 6.0))


func frenar(delta: float, cuanto := 10.0) -> void:
	marcha *= exp(-delta * cuanto)


func mover() -> void:
	velocity = marcha
	move_and_slide()


# ── Embestir (la carga del antidisturbios y la embestida de la mascota) ──

# Corre en línea recta hacia donde mira, a "rapidez". Si atropella a Johnny le quita "dano", le empuja y le tira
# al suelo (esquivando, le pasa de largo). Dice cómo va: "pillado" (ha atropellado a Johnny), "pared" (se ha
# comido una pared o un mueble), "fin" (ha corrido "cuanto" segundos sin chocar) o "" (sigue corriendo)
func embestir(delta: float, johnny: Node2D, rapidez: float, dano: int, cuanto: float, pie: float) -> String:
	marcha = mirada * rapidez
	contacto = 0   # el golpe ya lo da la embestida
	if randf() < delta * 25.0:
		Particulas.soltar(self, global_position + Vector2(randf_range(-20, 20), pie), Vector2(randf_range(-30, 30), -20),
			Color("#8a7a66"), 3, 0.4)
	var d := global_position.distance_to(johnny.global_position)
	if d < radio + johnny.RADIO + 10.0 and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(dano)
		johnny.empujar(mirada * 900.0)
		johnny.pisar({"tirado": {}})
		Temblor.temblar(10.0)
		marcha *= 0.2
		return "pillado"
	if t > 0.12 and get_real_velocity().length() < rapidez * 0.4:
		return "pared"
	if t >= cuanto:
		return "fin"
	return ""


# Hacia dónde mira la pared con la que acaba de chocar (para rebotar); si no lo sabe, hacia atrás
func pared_chocada() -> Vector2:
	var choque := get_last_slide_collision()
	return choque.get_normal() if choque else -mirada


# Se ha estrellado: se queda atontado (con estrellitas) "atontado_t" segundos
func estrellarse() -> void:
	marcha = Vector2.ZERO
	cambiar("atontado")
	Sonido.tocar("portazo")
	Temblor.temblar(9.0)
	gritar("¡PUMBA!", Color("#ffd23f"))
	for i in 10:
		Particulas.soltar(self, global_position + mirada * radio + Vector2(randf_range(-20, 20), randf_range(-60, 10)),
			Vector2.from_angle(randf() * TAU) * 70.0, Color("#b9b2a6"), 4, 0.6)


# El aviso de la embestida, en el suelo: una franja roja de "largo" por donde va a pasar, que se llena en "k" (0 a 1)
func franja(largo: float, k: float) -> void:
	var rojo := Color(1, 0.24, 0.35)
	draw_set_transform(Vector2(0, 6), mirada.angle())
	draw_rect(Rect2(0, -radio, largo, radio * 2.0), Color(rojo, 0.08 + k * 0.2))
	draw_rect(Rect2(0, -radio, largo * k, radio * 2.0), Color(rojo, 0.9), false, 3.0)
	draw_set_transform(Vector2.ZERO)


# ── Recibir golpes y morir ──

# Cuánto le quita de verdad un golpe de "cantidad" que viene empujando hacia "fuerza". "de_lleno": las
# explosiones, que dan por todos lados. Cada jefe puede cambiarlo (el escudo del antidisturbios)
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	return cantidad


func recibir_golpe(cantidad: int, fuerza: Vector2, de_lleno := false) -> void:
	if estado == "muerto" or invulnerable:
		return
	cantidad = danar(cantidad, fuerza, de_lleno)
	if cantidad <= 0:
		return
	vida = max(vida - cantidad, 0)
	# Los jefes apenas se mueven con los golpes
	marcha += fuerza.normalized() * 8.0
	Zombi.texto_flotante(get_parent(), global_position + Vector2(randf_range(-20, 0), -arriba), str(cantidad))
	Sonido.tocar("golpe")
	if fuerza != Vector2.ZERO:   # un golpe o una bala (no el fuego): salta su sangre
		Particulas.salpicar(self, get_parent(), global_position + Vector2(0, 6), arriba * 0.5, fuerza, Color("#7a1f1a"), 5)
	vida_cambiada.emit(vida, vida_max)
	if vida <= 0:
		morir()


# Daño sin golpe (el fuego del molotov mientras está dentro): no arde ni le hacen nada los demás charcos
func herir(cantidad: float, _color := Color.WHITE) -> void:
	recibir_golpe(maxi(1, roundi(cantidad)), Vector2.ZERO)


func morir() -> void:
	estado = "muerto"
	Sonido.tocar("explosion")
	$Sombra.apagar(1.0)
	remove_from_group("zombis")
	$Choque.set_deferred("disabled", true)
	z_index = -1
	sprite.modulate = Color.WHITE
	sprite.speed_scale = 1.0
	sprite.play("muerte_" + direccion())
	$Vapor.queue_redraw()
	queue_redraw()
	murio.emit()


# ── Dibujo ──

func direccion() -> String:
	return DIRS[wrapi(roundi(mirada.angle() / (PI / 4)), 0, 8)]


# Pone un fotograma concreto de una animación, parada (el estado decide en qué punto va)
func fijar(anim: String, dir: String, fotograma: int) -> void:
	var nombre := anim + "_" + dir
	if sprite.animation != nombre:
		sprite.animation = nombre
	sprite.pause()
	sprite.frame = clampi(fotograma, 0, sprite.sprite_frames.get_frame_count(nombre) - 1)


# El fotograma que toca cuando lleva hecho "k" (de 0 a 1) de una animación
func avance(nombre: String, k: float) -> int:
	var total := sprite.sprite_frames.get_frame_count(nombre)
	return clampi(int(k * total), 0, total - 1)


# Una animación en bucle (andar, reposo...), si no está ya puesta
func poner(nombre: String, velocidad := 1.0) -> void:
	if sprite.animation != nombre or not sprite.is_playing():
		sprite.play(nombre)
	sprite.speed_scale = velocidad


# Lo que va por encima de él (en el nodo "Vapor"): enfadado, el vapor de la cabeza, y atontado, estrellitas
# dando vueltas. Cada jefe puede añadir más en pintar_encima()
func _pintar_encima() -> void:
	if estado == "muerto":
		return
	if enfadado():
		for i in 3:
			var k := fmod(tiempo * 1.2 + i / 3.0, 1.0)
			$Vapor.draw_circle(Vector2((i - 1) * 18.0, -arriba + 6.0 - k * 36.0), 3.0 + k * 7.0, Color(1, 1, 1, 0.75 * (1.0 - k)))
	if estado == "atontado":
		for i in 3:
			var b := tiempo * 5.0 + i * TAU / 3.0
			var p := Vector2(cos(b) * 26.0, -arriba - 8.0 + sin(b) * 8.0)
			var estrella := PackedVector2Array()
			for j in 10:
				estrella.append(p + Vector2.from_angle(j * TAU / 10.0 - PI / 2.0) * (6.0 if j % 2 == 0 else 2.5))
			$Vapor.draw_colored_polygon(estrella, Color("#ffd23f"))
	pintar_encima($Vapor)


func pintar_encima(_lienzo: Node2D) -> void:
	pass
