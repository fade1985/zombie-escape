# La portera: la mini jefa de cada planta (una abuela zombi con una fregona llena de sangre). Copiada de
# src/jefe-portera.js y src/jefe-base.js del juego de navegador.
#
# Funciona por ESTADOS: anda un rato hacia Johnny, elige un ataque, lo AVISA (siempre se puede esquivar) y lo
# hace. Sus ataques:
#   - abanico: levanta la fregona (aviso: líneas en el suelo) y lanza agua sucia en abanico, 2 tandas
#   - fregonazo: si Johnny está cerca, marca un trozo de suelo en rojo y da un golpe que quita 20 y empuja
#   - lejía: tira botellas alrededor de Johnny (la primera, justo donde va a estar) que dejan charco
#   - ácido (20 oct): levanta la fregona y salpica charcos de ácido (el primero, justo donde va a estar Johnny)
#   - embestida (20 oct): marca una franja roja, corre en línea recta y remata con un fregonazo en círculo
#   - llamar: grita "¡VECINOS!" y aparecen vecinos (normales y rápidos): 2, o 4 enfadada
# A mitad de vida grita, se pone roja, echa vapor y se vuelve más rápida, y además (todo el doble):
#   - giro: da vueltas con la fregona persiguiendo a Johnny y escupe polvo en espiral
#
# Johnny y las balas le pegan igual que a un zombi (está en el grupo "zombis" y tiene radio y recibir_golpe).
extends CharacterBody2D

signal murio
signal vida_cambiada(vida: int, maxima: int)
signal pide_zombi(tipo: String, donde: Vector2)   # al llamar a los vecinos: la sala los saca

const BALA := preload("res://escenas/armas/bala_zombi.tscn")
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")

# Los números de cada ataque (PORTERA en el juego)
const AVISO_ABANICO := 0.55
const CHORROS := 7               # gotas de cada abanico (enfadada, 3 más)
const ABERTURA := 1.0            # lo abierto que es el abanico, en radianes (enfadada, ×1,3)
const VELOCIDAD_GOTA := 240.0
const DANO_GOTA := 10
const AVISO_FREGONAZO := 0.6
const ALCANCE_FREGONAZO := 135.0
const MEDIO_FREGONAZO := 1.05    # medio ángulo del trozo que barre
const DANO_FREGONAZO := 20
const DISTANCIA_FREGONAZO := 150.0   # si Johnny está más cerca que esto, prefiere el fregonazo
const BOTELLAS := 3
# Charcos de ácido (números provisionales, los de PORTERA en el juego; el charco, en charco.gd)
const AVISO_ACIDO := 0.5
const ACIDOS := [3, 6]           # cuántos en cada fase
# Embestida: aviso, velocidad y tiempo máximo corriendo; luego el fregonazo en círculo
const AVISO_EMBESTIDA := 0.55
const VELOCIDAD_EMBESTIDA := 470.0
const TIEMPO_EMBESTIDA := 0.9
const AVISO_CIRCULO := 0.35
const RADIO_CIRCULO := 125.0
const DANO_CIRCULO := 20
const EMBESTIDAS := [1, 2]       # cuántas seguidas en cada fase
const VECINOS := [2, 4]          # cuántos vecinos llama al gritar en cada fase
const TIEMPO_GIRO := 2.6
const DANO_CONTACTO := 10        # si Johnny se le pega, también hace daño
const ARRIBA := 190.0            # a qué altura tiene la cabeza (para los textos y el vapor)
const PASO := 96.0               # lo que avanza en un ciclo de andar (así los pies no patinan)
const PIE := 34.0                # a qué altura dibuja los pies respecto a su centro
# En su dibujo lo que toca el suelo es la fregona: las zapatillas quedan algo más arriba según la dirección.
# Cuántos píxeles se baja en cada una (FEET_DY en el juego)
const BAJAR := {"s": 5, "se": 9, "e": 3, "ne": 5, "n": 5, "no": 5, "o": 3, "so": 4}
const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]
const GOLPE_FREGONA := 2         # fotograma del fregonazo en el que la fregona toca el suelo

@export var vida_max := 600
@export var radio := 38.0

var vida := 600
var fase := 1                 # 2 = enfadada
var estado := "andar"
var t := 0.0                  # tiempo que lleva en el estado
var dur := 1.2                # cuánto anda antes de atacar
var datos := {}               # lo que necesita cada ataque (cuántas tandas, hacia dónde...)
var ultimo := ""              # el último ataque (para no repetirlo)
var espera_fregonazo := 1.5
var espera_llamar := 8.0
var giro := 0.0               # ángulo al que mira mientras da vueltas
var marcha := Vector2.ZERO    # su velocidad (sin contar los empujones)
var mirada := Vector2.DOWN    # hacia dónde mira (gira suave)
var invulnerable := false
var contacto := DANO_CONTACTO
var tiempo := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var agente: NavigationAgent2D = $Agente


func _ready() -> void:
	vida = vida_max
	$Vapor.draw.connect(_pintar_vapor)
	vida_cambiada.emit.call_deferred(vida, vida_max)


func enfadada() -> bool:
	return fase == 2


func cambiar(nuevo: String, nuevos_datos := {}) -> void:
	estado = nuevo
	t = 0.0
	datos = nuevos_datos


func _physics_process(delta: float) -> void:
	if estado == "muerto":
		return
	tiempo += delta
	t += delta
	espera_fregonazo -= delta
	espera_llamar -= delta
	invulnerable = false
	contacto = DANO_CONTACTO
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo:
		frenar(delta)
		mover()
		animar()
		return
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	var apunta := hacia.angle()

	# ¡A mitad de vida se enfada de verdad!
	if fase == 1 and vida <= vida_max * 0.5:
		fase = 2
		cambiar("grito")
		enfadarse(johnny)

	match estado:
		"andar":
			perseguir(delta, johnny, 105.0 if enfadada() else 75.0)
			mirar(delta, hacia)
			if t >= dur:
				elegir(d)
		"aviso_abanico":
			frenar(delta)
			mirar(delta, hacia)
			if t >= AVISO_ABANICO:
				cambiar("abanico", {"tandas": 3 if enfadada() else 2, "siguiente": 0.0, "i": 0})
		"abanico":
			abanico(delta, hacia, apunta)
		"aviso_fregonazo":
			frenar(delta)
			mirada = Vector2.from_angle(datos.angulo)
			if t >= AVISO_FREGONAZO:
				cambiar("fregonazo", {"angulo": datos.angulo})
				fregonazo(johnny)
		"fregonazo":
			frenar(delta)
			if t >= 0.35:
				andar(0.4 if enfadada() else 0.8)
		"lejia":
			lejia(delta, johnny, hacia)
		"aviso_giro":
			frenar(delta)
			giro += delta * 6.0 * (t / 0.6)
			if t >= 0.6:
				cambiar("giro", {"siguiente": 0.0})
		"giro":
			girar(delta, johnny)
		"aviso_acido":
			# levanta la fregona chorreando ácido
			frenar(delta)
			mirar(delta, hacia)
			if randf() < delta * 12.0:
				Particulas.soltar(self, global_position + Vector2(randf_range(-30, 30), -randf_range(60, 140)),
					Vector2(0, 60), Color("#9be33b"), 3, 0.5)
			if t >= AVISO_ACIDO:
				cambiar("acido", {"lanzadas": 0})
		"acido":
			acido(delta, johnny, hacia, apunta)
		"aviso_embestida":
			# se agacha mirando a Johnny (la franja roja marca por dónde va a venir)
			frenar(delta)
			mirar(delta, hacia)
			datos.angulo = apunta
			if t >= datos.aviso:
				cambiar("embestida", {"angulo": apunta, "quedan": datos.quedan - 1})
				Sonido.tocar("rugido")
		"embestida":
			embestir(delta, d)
		"aviso_circulo":
			frenar(delta, 6.0)
			if t >= AVISO_CIRCULO:
				cambiar("circulo", {"quedan": datos.quedan})
				fregonazo_circulo(johnny)
		"circulo":
			frenar(delta)
			if t >= 0.4:
				if datos.quedan > 0:
					cambiar("aviso_embestida", {"quedan": datos.quedan, "aviso": AVISO_EMBESTIDA * 0.6, "angulo": apunta})
				else:
					andar(0.5 if enfadada() else 0.9)
		"llamar":
			frenar(delta)
			if t >= 0.8 and not datos.get("hecho", false):
				datos.hecho = true
				# repartidos a su alrededor, uno normal y otro rápido
				var n: int = VECINOS[fase - 1]
				for i in n:
					var a := float(i) / n * TAU + randf_range(-0.5, 0.5)
					pide_zombi.emit("rapido" if i % 2 else "normal", global_position + Vector2(cos(a) * 120.0, sin(a) * 90.0))
			if t >= 1.1:
				andar(0.6)
		"grito":
			# Al enfadarse: un momento sin que le hagan daño, gritando
			invulnerable = true
			contacto = 0
			frenar(delta)
			if t >= 1.6:
				andar(0.3)
		"recuperar":
			frenar(delta, 4.0)
			if t >= datos.dur:
				andar(0.4)

	mover()
	# Si Johnny se le pega, le hace daño (Johnny luego es invulnerable un rato: no le quita en cada paso)
	if contacto > 0 and d < radio + johnny.RADIO + 4.0:
		johnny.recibir_dano(contacto)
	animar()


func andar(cuanto: float) -> void:
	cambiar("andar")
	dur = cuanto


# ── Cada ataque, paso a paso ──

func elegir(d: float) -> void:
	if d < DISTANCIA_FREGONAZO and espera_fregonazo <= 0.0:
		espera_fregonazo = 2.0 if enfadada() else 3.0
		var johnny := get_tree().get_first_node_in_group("jugador")
		cambiar("aviso_fregonazo", {"angulo": (johnny.global_position - global_position).angle()})
		return
	# grita y llama a los vecinos (si no quedan ya muchos zombis por ahí)
	if espera_llamar <= 0.0 and secuaces() <= VECINOS[fase - 1]:
		espera_llamar = 12.0
		cambiar("llamar")
		gritar("¡VECINOS!", Color("#ffd23f"), 26)
		Sonido.tocar("rugido")
		return
	var opciones := ["abanico", "lejia", "giro", "acido", "embestida"] if enfadada() else ["abanico", "lejia", "acido", "embestida"]
	opciones.erase(ultimo)
	ultimo = opciones.pick_random()
	match ultimo:
		"abanico":
			cambiar("aviso_abanico")
		"lejia":
			cambiar("lejia", {"lanzadas": 0})
			gritar("¡LEJÍA!", Color("#bfe9ff"))
		"acido":
			cambiar("aviso_acido")
			gritar("¡ÁCIDO!", Color("#9be33b"))
		"embestida":
			var johnny := get_tree().get_first_node_in_group("jugador")
			cambiar("aviso_embestida", {"quedan": EMBESTIDAS[fase - 1], "aviso": AVISO_EMBESTIDA,
				"angulo": (johnny.global_position - global_position).angle()})
		"giro":
			cambiar("aviso_giro")
			gritar("¡A BARRER!", Color("#ffd23f"))


# Abanico de agua sucia: dos tandas (tres enfadada), una sí y otra no desplazada medio hueco
func abanico(delta: float, hacia: Vector2, apunta: float) -> void:
	frenar(delta)
	mirar(delta, hacia)
	datos.siguiente -= delta
	if datos.siguiente <= 0.0 and datos.i < datos.tandas:
		var n := CHORROS + 3 if enfadada() else CHORROS
		var abierto := ABERTURA * (1.3 if enfadada() else 1.0)
		var desplazado := abierto / (n - 1) / 2.0 if datos.i % 2 == 1 else 0.0
		for i in n:
			var a: float = apunta - abierto / 2.0 + float(i) / (n - 1) * abierto + desplazado
			disparar(global_position + Vector2.from_angle(apunta) * 30.0, a, VELOCIDAD_GOTA, DANO_GOTA, 9.0)
		datos.i += 1
		datos.siguiente = 0.4
		Sonido.tocar("escobazo")
		Sonido.tocar("disparo_zombi")
	if datos.i >= datos.tandas and datos.siguiente <= 0.0:
		andar(0.5 if enfadada() else 0.9)


# El golpe de fregona: daña y empuja a Johnny si está dentro del trozo marcado
func fregonazo(johnny: Node2D) -> void:
	Sonido.tocar("escobazo")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_FREGONAZO and desvio <= MEDIO_FREGONAZO + 0.15:
		johnny.recibir_dano(DANO_FREGONAZO)
		johnny.empujar(hacia.normalized() * 650.0)


# Lanza botellas de lejía alrededor de donde va a estar Johnny (la primera, justo ahí)
func lejia(delta: float, johnny: Node2D, hacia: Vector2) -> void:
	frenar(delta)
	mirar(delta, hacia)
	var n := BOTELLAS + 2 if enfadada() else BOTELLAS
	while datos.lanzadas < n and t >= 0.3 + datos.lanzadas * 0.18:
		var lejos := 0.0 if datos.lanzadas == 0 else randf_range(60.0, 130.0)
		var botella := PROYECTIL.instantiate()
		botella.tipo = "lejia"
		botella.desde = global_position
		botella.alto_salida = ARRIBA * 0.6
		botella.hasta = johnny.global_position + johnny.velocity * 0.3 + Vector2.from_angle(randf() * TAU) * lejos
		get_parent().add_child(botella)
		datos.lanzadas += 1
		Sonido.tocar("escupitajo")
	if t >= 0.3 + n * 0.18 + 0.4:
		andar(0.5 if enfadada() else 1.0)


# Charcos de ácido: sacude la fregona y los salpica en parábola (el primero, justo donde va a estar Johnny)
func acido(delta: float, johnny: Node2D, hacia: Vector2, apunta: float) -> void:
	frenar(delta)
	mirar(delta, hacia)
	var n: int = ACIDOS[fase - 1]
	var hueco := 0.1 if enfadada() else 0.16
	while datos.lanzadas < n and t >= datos.lanzadas * hueco:
		var lejos := 0.0 if datos.lanzadas == 0 else randf_range(70.0, 190.0 if enfadada() else 140.0)
		var gota := PROYECTIL.instantiate()
		gota.tipo = "acido"
		gota.desde = global_position + Vector2.from_angle(apunta) * 40.0   # sale de la punta de la fregona
		gota.alto_salida = 40.0
		gota.hasta = johnny.global_position + johnny.velocity * 0.3 + Vector2.from_angle(randf() * TAU) * lejos
		get_parent().add_child(gota)
		if datos.lanzadas % 2 == 0:
			Sonido.tocar("escobazo")
		datos.lanzadas += 1
	if t >= n * hueco + 0.45:
		andar(0.5 if enfadada() else 0.9)


# Embestida: corre en línea recta muy deprisa; al llegar a Johnny (o al cansarse) frena y prepara el fregonazo
func embestir(delta: float, d: float) -> void:
	marcha = Vector2.from_angle(datos.angulo) * VELOCIDAD_EMBESTIDA
	mirada = Vector2.from_angle(datos.angulo)
	if randf() < delta * 25.0:
		Particulas.soltar(self, global_position + Vector2(randf_range(-20, 20), PIE), Vector2(randf_range(-30, 30), -20),
			Color("#8a7a66"), 3, 0.4)
	if d < 75.0 or t >= TIEMPO_EMBESTIDA:
		marcha *= 0.3
		cambiar("aviso_circulo", {"quedan": datos.quedan})


# Fregonazo en círculo: golpea todo lo que tiene alrededor y lo echa hacia atrás
func fregonazo_circulo(johnny: Node2D) -> void:
	Sonido.tocar("escobazo")
	for i in 14:
		var a := i / 14.0 * TAU
		var r := randf_range(50.0, RADIO_CIRCULO)
		Particulas.soltar(self, global_position + Vector2(cos(a) * r, sin(a) * r * 0.8), Vector2(cos(a), sin(a)) * 60.0,
			Color("#cbb994"), 4, 0.5)
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() - johnny.RADIO <= RADIO_CIRCULO:
		johnny.recibir_dano(DANO_CIRCULO)
		johnny.empujar(hacia.normalized() * 700.0)


# Torbellino (solo enfadada): da vueltas con la fregona, persigue a Johnny y escupe polvo en espiral
func girar(delta: float, johnny: Node2D) -> void:
	perseguir(delta, johnny, 120.0)
	giro += delta * 16.0
	datos.siguiente -= delta
	if datos.siguiente <= 0.0:
		datos.siguiente = 0.11
		for k in [0.0, PI]:
			disparar(global_position, giro * 0.45 + k, 170.0, 10, 8.0)
		Sonido.tocar("escobazo")
	if t >= TIEMPO_GIRO:
		cambiar("recuperar", {"dur": 0.9})


# Paso a la fase 2: borra las balas que hay volando y aparta a Johnny de un grito
func enfadarse(johnny: Node2D) -> void:
	for bala in get_tree().get_nodes_in_group("balas_zombi"):
		bala.queue_free()
	gritar("¡QUE ACABO DE FREGAR!", Color("#ffd23f"), 26)
	Sonido.tocar("rugido")
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < 260.0:
		johnny.empujar(hacia.normalized() * 900.0)
	sprite.modulate = Color(1.0, 0.8, 0.78)   # un poco más roja de rabia


func gritar(texto: String, color: Color, tamano := 24) -> void:
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-60, -ARRIBA - 50), texto, color, tamano)


func disparar(desde: Vector2, angulo: float, rapidez: float, dano: int, tamano: float) -> void:
	var bala := BALA.instantiate()
	bala.position = desde
	bala.velocidad = Vector2.from_angle(angulo) * rapidez
	bala.dano = dano
	bala.radio = tamano
	get_parent().add_child(bala)


# Cuántos zombis quedan (sin contarla a ella)
func secuaces() -> int:
	return get_tree().get_nodes_in_group("zombis").size() - 1


# ── Moverse ──

# Anda hacia Johnny rodeando paredes y muebles (con el mismo mapa de navegación que los zombis), acelerando suave
func perseguir(delta: float, johnny: Node2D, rapidez: float) -> void:
	agente.target_position = johnny.global_position
	var hacia := global_position.direction_to(agente.get_next_path_position())
	marcha += (hacia * rapidez - marcha) * (1.0 - exp(-delta * 6.0))


func frenar(delta: float, cuanto := 10.0) -> void:
	marcha *= exp(-delta * cuanto)


func mirar(delta: float, hacia: Vector2) -> void:
	mirada = mirada.lerp(hacia.normalized(), minf(1.0, delta * 8.0))


func mover() -> void:
	velocity = marcha
	move_and_slide()


# ── Recibir golpes y morir ──

func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	if estado == "muerto" or invulnerable:
		return
	vida = max(vida - cantidad, 0)
	# Los jefes apenas se mueven con los golpes
	marcha += fuerza.normalized() * 8.0
	Zombi.texto_flotante(get_parent(), global_position + Vector2(randf_range(-20, 0), -ARRIBA), str(cantidad))
	Sonido.tocar("golpe")
	if fuerza != Vector2.ZERO:   # un golpe o una bala (no el fuego): salta su sangre
		Particulas.salpicar(self, get_parent(), global_position + Vector2(0, 6), ARRIBA * 0.5, fuerza, Color("#7a1f1a"), 5)
	vida_cambiada.emit(vida, vida_max)
	if vida <= 0:
		morir()


# Daño sin golpe (el fuego del molotov, mientras está dentro): la portera no sabe arder ni le hacen nada los
# demás charcos ni las mutaciones
func herir(cantidad: float, _color := Color.WHITE) -> void:
	recibir_golpe(maxi(1, roundi(cantidad)), Vector2.ZERO)


func morir() -> void:
	estado = "muerto"
	Sonido.tocar("explosion")
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


# Cada estado usa su animación de la hoja: levantar la fregona es el aviso del abanico y del fregonazo, y
# bajarla, el golpe; la lejía, lanzar; el grito, al enfadarse y al llamar; quieta y dando vueltas, el giro
func animar() -> void:
	var dir := direccion()
	match estado:
		"aviso_abanico":
			fijar("ataque", dir, alzar(t / AVISO_ABANICO))
		"abanico":
			fijar("ataque", dir, GOLPE_FREGONA if datos.i == 0 else bajar(1.0 - maxf(0.0, datos.siguiente) / 0.4))
		"aviso_fregonazo":
			fijar("ataque", dir, alzar(t / AVISO_FREGONAZO))
		"fregonazo":
			fijar("ataque", dir, bajar(t / 0.35))
		"aviso_acido":
			fijar("ataque", dir, alzar(t / AVISO_ACIDO))
		"acido":
			fijar("ataque", dir, bajar(t / (ACIDOS[fase - 1] * (0.1 if enfadada() else 0.16) + 0.45)))
		"aviso_embestida":
			fijar("ataque", dir, alzar(t / datos.aviso))
		"aviso_circulo":
			fijar("ataque", dir, alzar(t / AVISO_CIRCULO))
		"circulo":
			fijar("ataque", dir, bajar(t / 0.4))
		"lejia":
			var n := BOTELLAS + 2 if enfadada() else BOTELLAS
			fijar("lanzar", dir, avance("lanzar_" + dir, t / (0.3 + n * 0.18 + 0.4)))
		"aviso_giro", "giro":
			dir = DIRS[wrapi(roundi(giro / (PI / 4)), 0, 8)]
			fijar("quieto", dir, 0)
		"llamar":
			dir = "s"   # el grito solo está dibujado mirando al sur
			fijar("grito", dir, avance("grito_s", t / 1.1))
		"grito":
			dir = "s"
			fijar("grito", dir, avance("grito_s", t / 1.6))
		_:
			if marcha.length() > 10.0:
				# El paso va al ritmo de lo que avanza: así los pies no patinan ni parece que flote
				var nombre := "andar_" + dir
				if sprite.animation != nombre or not sprite.is_playing():
					var fotograma := sprite.frame if sprite.animation.begins_with("andar") else 0
					sprite.play(nombre)
					sprite.frame = fotograma % sprite.sprite_frames.get_frame_count(nombre)
				var ciclo := sprite.sprite_frames.get_frame_count(nombre) / sprite.sprite_frames.get_animation_speed(nombre)
				sprite.speed_scale = marcha.length() * ciclo / PASO
			else:
				sprite.speed_scale = 1.0
				if sprite.animation != "reposo_" + dir:
					sprite.play("reposo_" + dir)
	sprite.position.y = PIE + BAJAR[dir] * 2.0
	queue_redraw()
	$Vapor.queue_redraw()


# Pone un fotograma concreto de una animación, parada (el estado decide en qué punto va)
func fijar(anim: String, dir: String, fotograma: int) -> void:
	var nombre := anim + "_" + dir
	if sprite.animation != nombre:
		sprite.animation = nombre
	sprite.pause()
	sprite.frame = fotograma


func avance(nombre: String, k: float) -> int:
	var total := sprite.sprite_frames.get_frame_count(nombre)
	return clampi(int(k * total), 0, total - 1)


# Levantar la fregona: los fotogramas de antes del golpe
func alzar(k: float) -> int:
	return mini(GOLPE_FREGONA - 1, int(k * GOLPE_FREGONA))


# Bajarla: del golpe hasta el final
func bajar(k: float) -> int:
	var resto := sprite.sprite_frames.get_frame_count(sprite.animation) - GOLPE_FREGONA
	return GOLPE_FREGONA + clampi(int(k * resto), 0, resto - 1)


# Los avisos, en el suelo (por debajo de ella)
func _draw() -> void:
	var rojo := Color(1, 0.24, 0.35)
	match estado:
		"aviso_fregonazo":
			var k := minf(1.0, t / AVISO_FREGONAZO)
			var puntos := PackedVector2Array([Vector2(0, 6)])
			for i in 17:
				var a: float = datos.angulo - MEDIO_FREGONAZO + i / 16.0 * MEDIO_FREGONAZO * 2.0
				puntos.append(Vector2(0, 6) + Vector2.from_angle(a) * ALCANCE_FREGONAZO)
			draw_colored_polygon(puntos, Color(rojo, 0.1 + k * 0.25))
			puntos.append(Vector2(0, 6))
			draw_polyline(puntos, Color(rojo, 0.9), 3.0)
		"aviso_abanico":
			var johnny := get_tree().get_first_node_in_group("jugador")
			if johnny == null:
				return
			var apunta: float = (johnny.global_position - global_position).angle()
			var n := CHORROS + 3 if enfadada() else CHORROS
			var abierto := ABERTURA * (1.3 if enfadada() else 1.0)
			var color := Color("#ff5d73", minf(1.0, t / AVISO_ABANICO) * 0.7)
			for i in n:
				var a: float = apunta - abierto / 2.0 + float(i) / (n - 1) * abierto
				draw_dashed_line(Vector2.from_angle(a) * 40.0, Vector2.from_angle(a) * 170.0, color, 2.5, 8.0)
		"aviso_embestida":
			# franja roja por donde va a embestir
			var k := minf(1.0, t / datos.aviso)
			var largo := VELOCIDAD_EMBESTIDA * TIEMPO_EMBESTIDA
			draw_set_transform(Vector2(0, 6), datos.angulo)
			draw_rect(Rect2(0, -radio, largo, radio * 2.0), Color(rojo, 0.08 + k * 0.2))
			draw_rect(Rect2(0, -radio, largo * k, radio * 2.0), Color(rojo, 0.9), false, 3.0)
		"aviso_circulo":
			var k := minf(1.0, t / AVISO_CIRCULO)
			draw_set_transform(Vector2(0, 6), 0.0, Vector2(1, 0.8))
			draw_circle(Vector2.ZERO, RADIO_CIRCULO, Color(rojo, 0.08 + k * 0.22))
			draw_arc(Vector2.ZERO, RADIO_CIRCULO, 0, TAU, 48, Color(rojo, 0.9), 3.0)
			draw_circle(Vector2.ZERO, RADIO_CIRCULO * k, Color(rojo, 0.25))
		"circulo":
			# el anillo de polvo del golpe, que se abre y se desvanece
			var k := minf(1.0, t / 0.35)
			draw_set_transform(Vector2(0, 6), 0.0, Vector2(1, 0.8))
			draw_arc(Vector2.ZERO, RADIO_CIRCULO * (0.6 + k * 0.4), 0, TAU, 48, Color("#cbb994", 1.0 - k), 6.0)
		"aviso_giro":
			var k := minf(1.0, t / 0.6)
			draw_set_transform(Vector2(0, 10), 0.0, Vector2(1, 0.75))
			draw_circle(Vector2.ZERO, 70.0, Color(rojo, 0.08 + k * 0.22))
			draw_arc(Vector2.ZERO, 70.0, 0, TAU, 40, Color(rojo, 0.9), 3.0)
			draw_circle(Vector2.ZERO, 70.0 * k, Color(rojo, 0.25))


# Enfadada, le sale vapor de la cabeza (va en un nodo aparte, "Vapor", para que se pinte por encima de ella)
func _pintar_vapor() -> void:
	if not enfadada() or estado == "muerto":
		return
	for i in 3:
		var k := fmod(tiempo * 1.2 + i / 3.0, 1.0)
		$Vapor.draw_circle(Vector2((i - 1) * 24.0, -ARRIBA + 10.0 - k * 40.0), 4.0 + k * 8.0, Color(1, 1, 1, 0.75 * (1.0 - k)))
