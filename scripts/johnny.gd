# Johnny, el conserje: se mueve con WASD, las flechas o el stick izquierdo del mando, y pone la animación
# de andar, de reposo o de ataque mirando hacia una de las 8 direcciones.
#
# Armas (los números están en armas.gd). Como en el juego de navegador, lleva dos: una de cuerpo a cuerpo y
# otra de fuego, y se cambia entre ellas con Q, la rueda del ratón o el botón Y del mando. Para probar, las
# teclas 1 a 6 ponen cualquiera de las seis. R (o el botón RB del mando) recarga.
# Tres modos de atacar (F1 cambia de uno a otro):
#   asistido  apunta y ataca solo, como en el juego (src/aim.js): busca el zombi más cercano que vea y, si
#             está a tiro, le pega o le dispara. El jugador solo se preocupa de moverse
#   mira      ataca mientras se pulsa J, el clic izquierdo o el botón X del mando, hacia donde mira Johnny
#   libre     apunta con el ratón (y ataca con el clic o J) o con el stick derecho del mando (y ataca mientras
#             lo empuja). Con una ayuda suave: si apuntas casi encima de un zombi, se tuerce un poco hacia él
#
# Tiene vida: los zarpazos se la quitan y, cuando cambia, lo avisa con la señal "vida_cambiada". La vida va
# en tres tercios: el tercio que pierde ya no se cura, y por cada uno anda un 25 % más lento (como en el JS).
# Sus atributos (vida máxima, velocidad, daño, ritmo, alcance...) están en "stats" (mejoras.gd): los números
# de las armas se multiplican por ellos.
#
# Esquiva (Espacio, Mayús o el botón A del mando): un acelerón corto en el que no le hacen daño, y se recarga
# en poco menos de un segundo (como el dash del JS). Los talentos (talentos.gd) le dan, además de números:
# Lobezno (recupera vida poco a poco), Durito (cada golpe quita menos), Reflejos (de vez en cuando esquiva solo
# un golpe), Acero (un escudo al empezar cada planta), Mirilla (crítico seguro cada 4 disparos), Ninja (golpe
# en área al acabar la esquiva) y Desfibrilador (resucita una vez por partida).
extends CharacterBody2D

signal vida_cambiada(vida: int, maxima: int)   # la barra de vida de la pantalla escucha esta señal
signal murio
signal arma_cambiada(texto: String)            # el cartel del arma (y sus balas) de la pantalla escucha esta
signal modo_cambiado(nombre: String)           # y la ayuda de abajo, el modo de atacar
signal resucito                                # Desfibrilador: la partida saca el aviso

const ARRANQUE := 14.0     # lo rápido que llega a su velocidad (y frena): igual que en el juego
const PASO := 140.0        # unidades que avanza en un ciclo de andar, como en el juego
const RADIO := 18.0        # su círculo de choque (los zombis lo usan para saber si está a tiro)

const INVULNERABLE := 0.9  # segundos sin recibir daño después de un zarpazo (parpadea), como en el juego
const ESQUIVA := 0.16      # lo que dura el acelerón de la esquiva
const ESQUIVA_RAPIDEZ := 3.3   # x su velocidad durante la esquiva
const REGENERA_CADA := 3.0 # Lobezno: segundos entre cura y cura
const AZUL := Color("#9fe8ff")

const MIRAR_CERCA := 360.0 # con un arma de cuerpo a cuerpo, a qué distancia empieza a mirar a un zombi
const EMPUJE := 170.0      # empuje base de un golpe a un zombi normal (el del arma lo multiplica)
const PATADA := 6.0        # disparando andando: lo que el disparo empuja a Johnny hacia atrás (KICK del JS)...
const PATADA_T := 0.12     # ...y lo que tarda en volver (la escopeta empuja 1,6 veces más)
const CAMBIO := 0.15       # lo que tarda en cambiar de arma antes de poder atacar
const BALA := preload("res://escenas/armas/bala.tscn")
# Balas de reserva (AMMO en src/weapons.js), contadas en cargadores del arma: con cuántos empieza, cuántos caben
# y cuántos da una caja de munición
const RESERVA_INICIO := 2
const RESERVA_MAX := 4
const RESERVA_CAJA := 1

const MODOS := {"asistido": "Asistido", "mira": "Hacia donde mira", "libre": "Apuntar libre"}
const AYUDA_ANGULO := 0.2  # modo libre: radianes (unos 11°) de margen para que el apunte se tuerza hacia un zombi

# Nombre corto de cada dirección, empezando por el este y girando hacia abajo (sentido de las agujas
# del reloj, porque en pantalla la Y crece hacia abajo)
const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]

var direccion := "s"   # hacia dónde mira
var stats := Mejoras.base()   # sus atributos (mejoras.gd)
var vida := 100
var tercios := 3          # los tercios de vida que le quedan (el que se pierde ya no se cura)
var vivo := true
var invulnerable := 0.0    # tiempo que le queda sin poder recibir daño
var estados := {}          # lo que le han puesto los charcos (estados.gd): fuego, veneno, lejía...
var pisando := {}          # los estados de los charcos que pisa en este paso
var estado_dano := 0.0     # el daño de los estados que se va sumando hasta llegar a un punto entero
var llamas: Llamas         # las llamas que le salen si arde
var a_la_vista := 0        # Ansiedad: los zombis despiertos que se ven en pantalla
var escudo := 0.0          # Acero: lo que le queda de escudo en esta planta
var esquiva_t := 0.0       # lo que le queda al acelerón de la esquiva (0 = no está esquivando)
var esquiva_espera := 0.0  # lo que falta para poder esquivar otra vez
var esquiva_dir := Vector2.DOWN
var estela_t := 0.0        # para soltar las copias transparentes de la estela
var sola_t := 0.0          # Reflejos: lo que falta para la siguiente esquiva automática
var regenera_t := 0.0      # Lobezno
var disparos := 0          # Mirilla: los disparos que lleva
var resucitado := false    # Desfibrilador: solo una vez por partida

var huecos := {"cuerpo": "fregona", "fuego": "pistola"}   # las dos armas que lleva
var mano := "cuerpo"       # cuál de las dos tiene en la mano
var balas := 0             # balas que quedan en el cargador del arma de fuego
var reserva := 0           # balas de repuesto en la mochila, para recargar
var sin_balas_sola := false   # se ha pasado sola a la de cuerpo a cuerpo al quedarse sin balas
var municion_guardada := {}   # las balas de las armas de fuego que ha guardado: {id: [cargador, reserva]}
var recargando := 0.0      # tiempo que falta para acabar de recargar (0 = no recarga)
var espera := 0.0          # tiempo que falta para poder atacar otra vez
var ataque_t := -1.0       # tiempo desde que empezó el ataque en curso (-1 = no está atacando)
var ataque_dur := 0.0      # lo que dura ese ataque
var golpe_pendiente := false   # golpe cuerpo a cuerpo que aún no ha llegado (pega a mitad de animación)
var golpe_angulo := 0.0        # y hacia dónde va
var patada_t := -1.0           # tiempo desde el último disparo andando (-1 = nada): el retroceso de todo el cuerpo
var patada := Vector2.ZERO     # hacia dónde y cuánto empuja ese disparo

var modo := "asistido"     # cómo se ataca (ver arriba)
var con_raton := false     # modo libre: si se está apuntando con el ratón (se ha movido hace poco)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var efectos: AnimatedSprite2D = $Efectos   # fogonazo, humo y casquillo al disparar andando


func _ready() -> void:
	efectos.animation_finished.connect(efectos.hide)
	llamas = Llamas.new()
	llamas.alto = 70.0
	llamas.fuerza = 0.0
	add_child(llamas)
	vida = stats.vida_max
	balas = Armas.datos(huecos.fuego).cargador
	reserva = balas * RESERVA_INICIO
	sostener(mano)
	# Al empezar, que la barra se ponga llena
	vida_cambiada.emit.call_deferred(vida, stats.vida_max)
	modo_cambiado.emit.call_deferred(MODOS[modo])


# Si se mueve el ratón, se apunta con él; si se empuja el stick derecho, con el mando
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		con_raton = true
	elif evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.4 and evento.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		con_raton = false


# Le pone unos atributos nuevos (al empezar la partida con los talentos, o al comprar uno en el ordenador).
# La vida de más viene llena (sin curar los tercios perdidos) y, si acaba de tener Acero, su escudo
func poner_stats(nuevos: Dictionary) -> void:
	var antes: Dictionary = stats
	stats = nuevos
	if stats.vida_max > antes.vida_max:
		vida = mini(vida + stats.vida_max - antes.vida_max, vida_tope())
	if stats.escudo > 0 and antes.escudo == 0:
		escudo = stats.escudo
	vida_cambiada.emit(vida, stats.vida_max)


# La vida a la que puede llegar curándose: la de los tercios que le quedan
func vida_tope() -> int:
	return roundi(tercios * stats.vida_max / 3.0)


func curar(cantidad: int) -> void:
	if not vivo or vida >= vida_tope():
		return
	vida = mini(vida + cantidad, vida_tope())
	vida_cambiada.emit(vida, stats.vida_max)


# F1: pasa al siguiente modo de atacar
func cambiar_modo() -> void:
	var nombres := MODOS.keys()
	modo = nombres[(nombres.find(modo) + 1) % nombres.size()]
	modo_cambiado.emit(MODOS[modo])


# El arma que tiene en la mano: sus datos, con los atributos de Johnny ya aplicados
func arma() -> Dictionary:
	var w: Dictionary = Armas.datos(huecos[mano]).duplicate()
	w.dano = w.dano * stats.dano * (stats.dano_cuerpo if w.tipo == "cuerpo" else stats.dano_fuego)
	w.ritmo = w.ritmo * stats.ritmo
	w.alcance = w.alcance * stats.alcance * (stats.alcance_cuerpo if w.tipo == "cuerpo" else 1.0)
	if w.tipo == "fuego":
		w.velocidad = w.velocidad * stats.velocidad_bala
	elif stats.ansiedad:
		w.ritmo = w.ritmo * (1.0 + minf(0.5, 0.05 * a_la_vista))   # Ansiedad: +5 % por zombi a la vista
	return w


# El daño de un golpe o una bala: a veces, crítico (el doble). "seguro": crítico sí o sí (Mirilla)
func con_critico(dano: float, seguro := false) -> int:
	return roundi(dano * (2.0 if seguro or randf() < stats.critico else 1.0))


func _physics_process(delta: float) -> void:
	espera -= delta
	invulnerable -= delta
	esquiva_espera -= delta
	sola_t -= delta
	# Parpadea mientras es invulnerable (medio transparente a ratos)
	sprite.modulate.a = 0.45 if invulnerable > 0.0 and int(invulnerable * 18.0) % 2 == 0 else 1.0
	# El retroceso de disparar andando: el dibujo entero va un poquito hacia atrás y vuelve enseguida
	var atras := Vector2.ZERO
	if patada_t >= 0.0:
		patada_t += delta
		atras = patada * maxf(0.0, 1.0 - patada_t / PATADA_T)
		if patada_t >= PATADA_T:
			patada_t = -1.0
	sprite.position = Vector2(0, 16) + atras
	efectos.position = sprite.position
	if not vivo:
		return
	# Los estados de los charcos: el daño poco a poco (sin parpadear), el tinte, las llamas y las gotitas
	estado_dano += Estados.actualizar(estados, pisando, delta)
	pisando = {}
	if estado_dano >= 1.0:
		var entero := int(estado_dano)
		estado_dano -= entero
		Sonido.tocar("chisporroteo")
		quitar_vida(entero)
		if not vivo:
			return
	sprite.modulate = Color(Estados.tinte(estados, Time.get_ticks_msec() / 1000.0), sprite.modulate.a)
	llamas.fuerza = 1.0 if estados.has("fuego") else 0.0
	Estados.efectos(self, estados, velocity, delta, 60.0, RADIO)
	if stats.ansiedad:
		contar_a_la_vista()

	# Teclas de las armas
	for i in Armas.ORDEN.size():
		if Input.is_action_just_pressed("arma_%d" % (i + 1)):
			coger(Armas.ORDEN[i])
	if Input.is_action_just_pressed("cambiar_arma"):
		cambiar_mano()
	if Input.is_action_just_pressed("recargar"):
		empezar_recarga()
	if Input.is_action_just_pressed("cambiar_modo"):
		cambiar_modo()
	if recargando > 0.0:
		recargando -= delta
		if recargando <= 0.0:
			terminar_recarga()

	# Lobezno: recupera vida poco a poco
	if stats.regenera > 0 and vida < vida_tope():
		regenera_t += delta
		if regenera_t >= REGENERA_CADA:
			regenera_t -= REGENERA_CADA
			curar(stats.regenera)

	# Lo que pide el jugador: un vector de largo 0 a 1 (el stick a medias da menos de 1)
	var pedido := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	if Input.is_action_just_pressed("esquivar") and esquiva_espera <= 0.0:
		esquivar(pedido)
	if esquiva_t > 0.0:
		# Durante la esquiva va lanzado, dejando una estela; al acabar frena (y Ninja pega)
		esquiva_t -= delta
		estela_t -= delta
		if estela_t <= 0.0:
			estela_t = 0.03
			soltar_estela()
		if esquiva_t <= 0.0 and stats.ninja:
			golpe_ninja()
	else:
		# Acelera suave hacia la velocidad deseada, como en el juego
		# (en la lejía cuesta frenar y girar: menos agarre)
		var k := 1.0 - exp(-delta * ARRANQUE * maxf(0.08, Estados.agarre(estados)))
		var rapidez: float = stats.velocidad * (1.0 - 0.25 * (3 - tercios))   # más lento por cada tercio perdido
		velocity += (pedido * rapidez - velocity) * k
	# move_and_slide mueve el cuerpo y, si choca con una pared, lo hace resbalar a lo largo de ella
	move_and_slide()
	if pedido.length() > 0.1:
		direccion = direccion_de(pedido)

	match modo:
		"asistido":
			apuntar_y_atacar()
		"mira":
			if Input.is_action_pressed("atacar"):
				intentar_atacar(DIRS.find(direccion) * PI / 4)
		"libre":
			apuntar_libre()

	# El golpe cuerpo a cuerpo hace daño cuando el arma llega a su sitio, no al empezar a moverla
	if ataque_t >= 0.0:
		ataque_t += delta
		if golpe_pendiente and ataque_t >= ataque_dur * arma().momento:
			golpe_pendiente = false
			golpear(golpe_angulo)
		if ataque_t >= ataque_dur:
			ataque_t = -1.0

	animar()
	if Armas.es_creada(huecos[mano]):
		ArmasCreadas.detalle(self, Armas.datos(huecos[mano]), delta)   # chispitas de color en la punta


# La esquiva: sale lanzado hacia donde se mueve (o, quieto, hacia donde mira) y un momento no le hacen daño
func esquivar(pedido: Vector2) -> void:
	esquiva_dir = pedido.normalized() if pedido.length() > 0.1 else Vector2.from_angle(DIRS.find(direccion) * PI / 4)
	velocity = esquiva_dir * stats.velocidad * ESQUIVA_RAPIDEZ
	esquiva_t = ESQUIVA
	esquiva_espera = stats.esquiva_espera
	invulnerable = maxf(invulnerable, 0.3)
	estela_t = 0.0
	Sonido.tocar("esquiva")


# Una copia de Johnny, azulada y medio transparente, que se queda atrás y se apaga
func soltar_estela() -> void:
	var copia := Sprite2D.new()
	copia.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	copia.centered = sprite.centered
	copia.offset = sprite.offset
	copia.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	copia.modulate = Color(AZUL, 0.5)
	get_parent().add_child(copia)
	copia.global_transform = sprite.global_transform
	copia.z_index = -1
	var tween := copia.create_tween()
	tween.tween_property(copia, "modulate:a", 0.0, 0.2)
	tween.tween_callback(copia.queue_free)


# Ninja: al acabar la esquiva, un barrido en círculo con el arma cuerpo a cuerpo. Los zombis que pilla mueren
# al momento; a la jefa le quita un 10 % de su vida
func golpe_ninja() -> void:
	var w: Dictionary = Armas.datos(huecos.cuerpo)
	var alcance: float = w.alcance * stats.alcance * stats.alcance_cuerpo + RADIO
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var hacia: Vector2 = zombi.global_position - global_position
		if hacia.length() > alcance + zombi.radio:
			continue
		var dano: int = zombi.vida + 1 if zombi is Zombi else ceili(zombi.vida_max * 0.1)
		zombi.recibir_golpe(dano, hacia.normalized() * EMPUJE * 1.5)
	# el barrido se ve aunque no pille a nadie: un aro azul que se abre y se apaga
	var aro := Line2D.new()
	aro.width = 3.0
	aro.default_color = AZUL
	for i in 33:
		aro.add_point(Vector2.from_angle(i * TAU / 32) * alcance)
	get_parent().add_child(aro)
	aro.global_position = global_position
	aro.scale = Vector2(0.5, 0.5)
	var tween := aro.create_tween().set_parallel()
	tween.tween_property(aro, "scale", Vector2.ONE, 0.25)
	tween.tween_property(aro, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(aro.queue_free)


# Busca el zombi más cercano que vea y, si está a tiro, le ataca (como autoAim en src/aim.js)
func apuntar_y_atacar() -> void:
	var w := arma()
	var objetivo := buscar_objetivo(w)
	if objetivo == null:
		# Sin nadie a tiro, aprovecha para recargar
		if w.tipo == "fuego":
			empezar_recarga()
		return
	var hacia: Vector2 = objetivo.global_position - global_position
	direccion = direccion_de(hacia)   # mira al zombi aunque ande hacia otro lado
	var a_tiro: bool = w.tipo == "fuego" or hacia.length() - objetivo.radio <= w.alcance
	if a_tiro:
		intentar_atacar(hacia.angle())


# Modo libre: apunta con el stick derecho (y ataca mientras lo empuja) o con el ratón (y ataca con el clic o J)
func apuntar_libre() -> void:
	var stick := Input.get_vector("apuntar_izquierda", "apuntar_derecha", "apuntar_arriba", "apuntar_abajo")
	var apunte := Vector2.ZERO
	var ataca := Input.is_action_pressed("atacar")
	# mientras se apunta un lanzable (con el gatillo o desde el botón del móvil), el stick es para él
	var lanzando := Input.is_action_pressed("lanzar") or Input.is_action_just_released("lanzar")
	if stick.length() > 0.5 and not lanzando:
		apunte = stick
		ataca = true
	elif con_raton:
		apunte = get_global_mouse_position() - global_position
	if apunte.length() < 1.0:
		return
	direccion = direccion_de(apunte)   # mira hacia donde apunta aunque ande hacia otro lado
	if ataca:
		intentar_atacar(ayuda_apunte(apunte.angle()))


# La ayuda del modo libre: si hay un zombi a la vista casi en la línea de tiro, apunta justo a él
func ayuda_apunte(angulo: float) -> float:
	var w := arma()
	var alcance: float = w.alcance + 40.0 if w.tipo == "cuerpo" else w.alcance
	var mejor := angulo
	var margen := AYUDA_ANGULO
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var hacia: Vector2 = zombi.global_position - global_position
		if hacia.length() - zombi.radio > alcance or not se_ve(zombi):
			continue
		var desvio := absf(angle_difference(angulo, hacia.angle()))
		if desvio < margen:
			margen = desvio
			mejor = hacia.angle()
	return mejor


# Ataca hacia ese ángulo si ya puede (ha pasado el hueco entre ataques y, si es de fuego, tiene bala)
func intentar_atacar(angulo: float) -> void:
	var w := arma()
	if espera > 0.0 or not (w.tipo == "cuerpo" or lista_para_disparar()):
		return
	espera = 1.0 / w.ritmo
	direccion = direccion_de(Vector2.from_angle(angulo))
	atacar(angulo)


# Un "rayo" de Johnny al zombi: si choca con algo de la capa 1 (paredes y muebles), no lo ve
func se_ve(zombi: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, zombi.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# El zombi más cercano dentro del alcance que no quede detrás de una pared o de un mueble
func buscar_objetivo(w: Dictionary) -> Node2D:
	var alcance: float = MIRAR_CERCA if w.tipo == "cuerpo" else w.alcance
	var mejor: Node2D = null
	var mapa := get_tree().get_first_node_in_group("mapa")
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var distancia: float = global_position.distance_to(zombi.global_position) - zombi.radio
		# a los de una habitación a oscuras no se les apunta
		if mapa and mapa.oculto(zombi.global_position):
			continue
		if distancia >= alcance or not se_ve(zombi):
			continue
		mejor = zombi
		alcance = distancia
	return mejor


func atacar(angulo: float) -> void:
	var w := arma()
	ataque_t = 0.0
	var nombre := "ataque_" + direccion
	var largo_anim := sprite.sprite_frames.get_frame_count(nombre) / sprite.sprite_frames.get_animation_speed(nombre)
	if w.tipo == "cuerpo":
		# La animación del golpe dura medio segundo como mucho, y nunca más que el hueco entre golpes
		ataque_dur = minf(0.5, 0.95 / w.ritmo)
		Sonido.tocar("barrido")
		golpe_pendiente = true
		golpe_angulo = angulo
	else:
		disparar(angulo)
		# La bala ya ha salido: la animación solo acompaña, y nunca dura más que el hueco entre disparos
		ataque_dur = minf(largo_anim, 0.95 / w.ritmo)
	var ritmo_anim := largo_anim / ataque_dur
	if w.tipo == "fuego" and velocity.length() > 20.0:
		# Disparando mientras anda: sigue andando y los efectos del disparo se pintan encima
		efectos.speed_scale = ritmo_anim
		efectos.play("efectos_" + direccion)
		efectos.set_frame_and_progress(0, 0.0)
		efectos.show()
		ataque_t = -1.0   # las piernas siguen con la animación de andar
		# como andando no se ve el retroceso de los brazos, el disparo empuja a Johnny entero hacia atrás
		patada = -Vector2.from_angle(angulo) * PATADA * (1.6 if w.get("perdigones", 1) > 1 else 1.0)
		patada_t = 0.0
	else:
		sprite.speed_scale = ritmo_anim
		sprite.play(nombre)
		sprite.set_frame_and_progress(0, 0.0)


# Golpe cuerpo a cuerpo: pega a todos los zombis que estén dentro del abanico (meleeHit en el juego)
func golpear(angulo: float) -> void:
	var w := arma()
	var mitad := deg_to_rad(w.arco) / 2.0
	var tocados := 0
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var hacia: Vector2 = zombi.global_position - global_position
		var distancia := hacia.length()
		if distancia - zombi.radio > w.alcance:
			continue
		# angle_difference da lo que hay que girar de un ángulo al otro (de -180° a 180°)
		var desvio := absf(angle_difference(angulo, hacia.angle()))
		if desvio <= mitad + 0.2 or distancia < zombi.radio + 12.0:
			var dano := con_critico(w.dano)
			zombi.recibir_golpe(dano, hacia.normalized() * EMPUJE * w.empuje)
			tocados += 1
			if w.has("efecto"):
				ArmasCreadas.efecto_golpe(zombi, w, dano)   # las armas creadas: aturdir, prender, sangrar...
	if tocados > 0:
		Sonido.tocar("porrazo")


# Saca la bala (o los perdigones) por la boca del arma, como se ve en el dibujo
func disparar(angulo: float) -> void:
	var w := arma()
	if not w.get("sin_municion", false):
		balas -= 1
	disparos += 1
	var seguro: bool = stats.mirilla and disparos % 4 == 0   # Mirilla: tras 3 disparos, uno crítico seguro
	# La boca del arma está en píxeles del dibujo desde los pies (x2 para pasar a unidades); los pies van
	# 16 unidades por debajo del centro de Johnny. La bala de verdad va 50 más abajo, a ras de suelo, y se
	# dibuja 50 más arriba (ver bala.gd): así sale de la boca y choca con lo que hay a la altura de los pies
	var boca: Vector2 = w.boca[direccion] * 2.0
	var salida := global_position + Vector2(boca.x, 16.0 + boca.y + 50.0)
	if w.has("efecto"):
		# las armas creadas a distancia: gotas de fuego o ácido, o el bumerán (armas_creadas.gd)
		ArmasCreadas.disparar(self, angulo, w, salida)
		oir_disparo()
		if balas <= 0:
			empezar_recarga()
		avisar_arma()
		return
	for i in w.perdigones:
		var desvio := 0.0
		if w.perdigones > 1:
			desvio = (float(i) / (w.perdigones - 1) - 0.5) * w.abertura   # abiertos en abanico
		desvio += (randf() - 0.5) * w.temblor
		var rapidez: float = w.velocidad * (randf_range(0.9, 1.1) if w.temblor > 0.0 else 1.0)
		var bala := BALA.instantiate()
		bala.velocidad = Vector2.from_angle(angulo + desvio) * rapidez
		bala.dano = con_critico(w.dano, seguro)
		bala.empuje = w.empuje
		bala.radio = 3.0 if w.perdigones > 1 else 4.0
		bala.vida = w.alcance / w.velocidad
		get_parent().add_child(bala)
		bala.global_position = salida
	Sonido.tocar("escopeta" if w.perdigones > 1 else "pistola")
	# El fogonazo alumbra un instante alrededor (más con la escopeta)
	Luz.destello(self, salida - Vector2(0, 50), 170.0 if w.perdigones > 1 else 120.0, 0.12 if w.perdigones > 1 else 0.08)
	oir_disparo()
	if balas <= 0:
		empezar_recarga()
	avisar_arma()


# El disparo se oye: despierta a los zombis dormidos que haya cerca
func oir_disparo() -> void:
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.has_method("oir_disparo"):
			zombi.oir_disparo(global_position)


# Antes de disparar: ¿hay bala en el cargador? Si no, recarga. La escopeta puede disparar a mitad de recarga
# (con lo que lleve metido); las demás, no
func lista_para_disparar() -> bool:
	if recargando > 0.0:
		if not arma().cartucho or balas <= 0:
			return false
		recargando = 0.0   # dispara y deja de meter cartuchos
	if balas > 0:
		return true
	if reserva > 0:
		empezar_recarga()
		return false
	# sin balas: a la fregona (o la que lleve)
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-50, -70), "¡Sin balas!", Color("#ff9f1c"), 18)
	Sonido.tocar("click")
	sostener("cuerpo")
	sin_balas_sola = true
	return false


# Empieza a recargar, si hace falta y le quedan balas de reserva
func empezar_recarga() -> void:
	var w := arma()
	if w.tipo != "fuego" or recargando > 0.0 or balas >= w.cargador or reserva <= 0:
		return
	recargando = w.recarga
	Sonido.tocar("recargar")
	avisar_arma()


# Mete el cargador entero o, en la escopeta, un cartucho (y sigue con el siguiente)
func terminar_recarga() -> void:
	var w := arma()
	recargando = 0.0
	Sonido.tocar("cartucho" if w.cartucho else "recargado")
	var mete: int = mini(1 if w.cartucho else w.cargador - balas, reserva)
	balas += mete
	reserva -= mete
	if w.cartucho and balas < w.cargador and reserva > 0:
		recargando = w.recarga
	avisar_arma()


# ¿Le cabe más munición? (para que la caja de munición vaya hacia él)
func quiere_municion() -> bool:
	var w: Dictionary = Armas.datos(huecos.fuego)
	return not w.get("sin_municion", false) and reserva < w.cargador * RESERVA_MAX


# Recoge una caja de munición: un cargador más para el arma de fuego que lleve. Si se había pasado sola a la
# de cuerpo a cuerpo por quedarse sin balas, vuelve a sacar la de fuego
func sumar_municion() -> void:
	var w: Dictionary = Armas.datos(huecos.fuego)
	reserva = mini(w.cargador * RESERVA_MAX, reserva + w.cargador * RESERVA_CAJA)
	if sin_balas_sola:
		sostener("fuego")
	if mano == "fuego" and balas <= 0:
		empezar_recarga()
	avisar_arma()


# Coge un arma (teclas 1 a 6, la tienda, el inventario o el baúl): va a su hueco y se la pone en la mano. Si es
# de fuego, con las balas que le quedaban al guardarla o, si es nueva, con el cargador lleno y la reserva de
# partida (las creadas guardan las suyas en Armas.sacadas)
func coger(id: String) -> void:
	var w: Dictionary = Armas.datos(id)
	if w.tipo == "fuego":
		var vieja: String = huecos.fuego
		if Armas.es_creada(vieja):
			Armas.sacadas[vieja].balas = balas
			Armas.sacadas[vieja].reserva = reserva
		else:
			municion_guardada[vieja] = [balas, reserva]
		balas = w.cargador
		reserva = w.cargador * RESERVA_INICIO
		if Armas.es_creada(id):
			balas = Armas.sacadas[id].get("balas", balas)
			reserva = Armas.sacadas[id].get("reserva", reserva)
		elif municion_guardada.has(id):
			balas = municion_guardada[id][0]
			reserva = municion_guardada[id][1]
			municion_guardada.erase(id)
	huecos[w.tipo] = id
	sostener(w.tipo)


# Cambia a la otra arma (Q, rueda del ratón o botón Y)
func cambiar_mano() -> void:
	# a la de fuego sin balas no se cambia
	if mano == "cuerpo" and balas <= 0 and reserva <= 0:
		Zombi.texto_flotante(get_parent(), global_position + Vector2(-50, -70), "¡Sin balas!", Color("#ff9f1c"), 18)
		Sonido.tocar("click")
		return
	sostener("fuego" if mano == "cuerpo" else "cuerpo")
	Sonido.tocar("cambiar")
	espera = maxf(espera, CAMBIO)   # un instante para cambiar de arma


# Se pone en la mano el arma de ese hueco: lo que estaba haciendo con la otra se corta
func sostener(hueco: String) -> void:
	mano = hueco
	sin_balas_sola = false
	recargando = 0.0
	ataque_t = -1.0
	golpe_pendiente = false
	efectos.hide()
	var w := arma()
	# Cada arma tiene su hoja de Johnny; los pies van en el mismo sitio aunque la hoja sea más alta
	sprite.sprite_frames = w.hoja
	efectos.sprite_frames = w.hoja
	sprite.offset = -w.pies
	efectos.offset = -w.pies
	sprite.speed_scale = 1.0
	sprite.play("reposo_" + direccion)
	avisar_arma()


# Le cuenta a la pantalla qué arma lleva, cuántas balas le quedan y cuál es la otra
func avisar_arma() -> void:
	var w := arma()
	var texto: String = w.nombre
	if w.tipo == "fuego":
		texto += "   %d/%d" % [balas, w.cargador]
		if recargando > 0.0:
			texto += "   recargando…"
	var otra: String = huecos["fuego" if mano == "cuerpo" else "cuerpo"]
	texto += "\n[Q] " + Armas.datos(otra).nombre
	arma_cambiada.emit(texto)


func animar() -> void:
	# Mientras dura el ataque se deja su animación (se puso al empezarlo)
	if ataque_t >= 0.0:
		return
	var rapidez := velocity.length()
	if rapidez > 20.0:
		cambiar_animacion("andar_" + direccion)
		# El paso va según lo que avanza de verdad: más despacio al arrancar y al frenar.
		# Cada dirección tiene su número de fotogramas; la hoja los pone a su velocidad (12 por segundo)
		var fotogramas := sprite.sprite_frames.get_frame_count(sprite.animation)
		var fps := sprite.sprite_frames.get_animation_speed(sprite.animation)
		sprite.speed_scale = (rapidez / PASO * fotogramas) / fps
	else:
		cambiar_animacion("reposo_" + direccion)
		sprite.speed_scale = 1.0


# Lo llaman los zombis al darle un zarpazo
func recibir_dano(cantidad: int) -> void:
	if not vivo or invulnerable > 0.0:
		return
	# Reflejos: cada pocos segundos, un golpe se esquiva solo
	if stats.esquiva_sola > 0 and sola_t <= 0.0:
		sola_t = stats.esquiva_sola
		invulnerable = 0.5
		Zombi.texto_flotante(get_parent(), global_position + Vector2(-40, -70), "¡Esquivado!", AZUL, 18)
		Sonido.tocar("esquiva")
		return
	invulnerable = INVULNERABLE
	# Durito quita un poco a cada golpe; el escudo de Acero para la mitad de lo que queda mientras dure
	var dano := maxi(1, roundi(cantidad * stats.dano_recibido) - stats.armadura)
	if escudo > 0.0:
		var parado := minf(escudo, dano / 2.0)
		escudo -= parado
		dano = maxi(1, roundi(dano - parado))
	Sonido.tocar("dano")
	quitar_vida(dano)


# Lo llaman los charcos en cada paso mientras los pisa (charco.gd): apunta sus estados. La esquiva cruza
# cualquier charco sin que le pase nada
func pisar(estados_charco: Dictionary) -> void:
	if vivo and esquiva_t <= 0.0:
		Estados.pisar(pisando, estados_charco)


# Ansiedad: cuántos zombis despiertos hay en la pantalla (sin contar los de habitaciones a oscuras)
func contar_a_la_vista() -> void:
	a_la_vista = 0
	var mapa := get_tree().get_first_node_in_group("mapa")
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var d: Vector2 = zombi.global_position - global_position
		if absf(d.x) < 480.0 and absf(d.y) < 320.0 and not zombi.get("dormido") and not (mapa and mapa.oculto(zombi.global_position)):
			a_la_vista += 1


# Un empujón (el fregonazo de la portera, su grito): se suma a su velocidad y su frenada lo va parando
func empujar(fuerza: Vector2) -> void:
	if vivo:
		velocity += fuerza


func quitar_vida(cantidad: int) -> void:
	vida = max(vida - cantidad, 0)
	# Al bajar de un tercio, ese tercio se pierde (vidaTope en el JS)
	var tercio: float = stats.vida_max / 3.0
	tercios = mini(tercios, maxi(1, ceili(vida / tercio - 0.000001)))
	vida_cambiada.emit(vida, stats.vida_max)
	if vida == 0 and stats.resucitar and not resucitado:
		# Desfibrilador: la primera vez que cae, vuelve con toda la vida
		resucitado = true
		vida = stats.vida_max
		tercios = 3
		invulnerable = 2.0
		vida_cambiada.emit(vida, stats.vida_max)
		resucito.emit()
		return
	if vida == 0:
		vivo = false
		ataque_t = -1.0
		velocity = Vector2.ZERO
		efectos.hide()
		# No tiene animación de morirse: se queda quieto y rojo
		sprite.speed_scale = 1.0
		cambiar_animacion("reposo_" + direccion)
		sprite.modulate = Color(1, 0.35, 0.35)
		murio.emit()


# Una de las 8 direcciones según un vector: angle() da el ángulo en radianes y lo pasamos a uno de los
# 8 trozos de 45°
func direccion_de(v: Vector2) -> String:
	return DIRS[wrapi(roundi(v.angle() / (PI / 4)), 0, 8)]


# Pone una animación. Si solo cambia la dirección (andar_s → andar_se), sigue por el mismo
# fotograma, para que al girar no se le junten los pies de golpe
func cambiar_animacion(nombre: String) -> void:
	if sprite.animation == nombre:
		return
	var mismo_estado := sprite.animation.get_slice("_", 0) == nombre.get_slice("_", 0)
	var fotograma := sprite.frame
	var avance := sprite.frame_progress
	sprite.play(nombre)
	if mismo_estado:
		# Las direcciones no tienen todas los mismos fotogramas: si nos pasamos, volvemos a empezar
		sprite.set_frame_and_progress(fotograma % sprite.sprite_frames.get_frame_count(nombre), avance)
