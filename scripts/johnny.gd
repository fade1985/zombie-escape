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
# Tiene vida: los zarpazos se la quitan y, cuando cambia, lo avisa con la señal "vida_cambiada".
extends CharacterBody2D

signal vida_cambiada(vida: int, maxima: int)   # la barra de vida de la pantalla escucha esta señal
signal murio
signal arma_cambiada(texto: String)            # el cartel del arma (y sus balas) de la pantalla escucha esta
signal modo_cambiado(nombre: String)           # y la ayuda de abajo, el modo de atacar

const VELOCIDAD := 210.0   # unidades por segundo, la misma que en el juego de navegador
const ARRANQUE := 14.0     # lo rápido que llega a su velocidad (y frena): igual que en el juego
const PASO := 140.0        # unidades que avanza en un ciclo de andar, como en el juego
const RADIO := 18.0        # su círculo de choque (los zombis lo usan para saber si está a tiro)

const VIDA_MAX := 100
const INVULNERABLE := 0.9  # segundos sin recibir daño después de un zarpazo (parpadea), como en el juego

const MIRAR_CERCA := 360.0 # con un arma de cuerpo a cuerpo, a qué distancia empieza a mirar a un zombi
const EMPUJE := 170.0      # empuje base de un golpe a un zombi normal (el del arma lo multiplica)
const CAMBIO := 0.15       # lo que tarda en cambiar de arma antes de poder atacar
const BALA := preload("res://escenas/armas/bala.tscn")

const MODOS := {"asistido": "Asistido", "mira": "Hacia donde mira", "libre": "Apuntar libre"}
const AYUDA_ANGULO := 0.2  # modo libre: radianes (unos 11°) de margen para que el apunte se tuerza hacia un zombi

# Nombre corto de cada dirección, empezando por el este y girando hacia abajo (sentido de las agujas
# del reloj, porque en pantalla la Y crece hacia abajo)
const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]

var direccion := "s"   # hacia dónde mira
var vida := VIDA_MAX
var vivo := true
var invulnerable := 0.0    # tiempo que le queda sin poder recibir daño
var charco_dano := 0.0     # el daño de los charcos que se va sumando hasta llegar a un punto entero
var charco_tinte := Color.WHITE
var charco_tiempo := 0.0   # cuánto le queda teñido del color del charco

var huecos := {"cuerpo": "fregona", "fuego": "pistola"}   # las dos armas que lleva
var mano := "cuerpo"       # cuál de las dos tiene en la mano
var balas := 0             # balas que quedan en el cargador del arma de fuego
var recargando := 0.0      # tiempo que falta para acabar de recargar (0 = no recarga)
var espera := 0.0          # tiempo que falta para poder atacar otra vez
var ataque_t := -1.0       # tiempo desde que empezó el ataque en curso (-1 = no está atacando)
var ataque_dur := 0.0      # lo que dura ese ataque
var golpe_pendiente := false   # golpe cuerpo a cuerpo que aún no ha llegado (pega a mitad de animación)
var golpe_angulo := 0.0        # y hacia dónde va

var modo := "asistido"     # cómo se ataca (ver arriba)
var con_raton := false     # modo libre: si se está apuntando con el ratón (se ha movido hace poco)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var efectos: AnimatedSprite2D = $Efectos   # fogonazo, humo y casquillo al disparar andando


func _ready() -> void:
	efectos.animation_finished.connect(efectos.hide)
	balas = Armas.DATOS[huecos.fuego].cargador
	sostener(mano)
	# Al empezar, que la barra se ponga llena
	vida_cambiada.emit.call_deferred(vida, VIDA_MAX)
	modo_cambiado.emit.call_deferred(MODOS[modo])


# Si se mueve el ratón, se apunta con él; si se empuja el stick derecho, con el mando
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		con_raton = true
	elif evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.4 and evento.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		con_raton = false


# F1: pasa al siguiente modo de atacar
func cambiar_modo() -> void:
	var nombres := MODOS.keys()
	modo = nombres[(nombres.find(modo) + 1) % nombres.size()]
	modo_cambiado.emit(MODOS[modo])


# El arma que tiene en la mano (sus datos)
func arma() -> Dictionary:
	return Armas.DATOS[huecos[mano]]


func _physics_process(delta: float) -> void:
	espera -= delta
	invulnerable -= delta
	# Parpadea mientras es invulnerable (medio transparente a ratos)
	sprite.modulate.a = 0.45 if invulnerable > 0.0 and int(invulnerable * 18.0) % 2 == 0 else 1.0
	if not vivo:
		return
	# Pisando un charco se tiñe de su color (verde el moco, azulado la lejía)
	charco_tiempo -= delta
	var tinte := charco_tinte if charco_tiempo > 0.0 else Color.WHITE
	sprite.modulate = Color(tinte, sprite.modulate.a)

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

	# Lo que pide el jugador: un vector de largo 0 a 1 (el stick a medias da menos de 1)
	var pedido := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	# Acelera suave hacia la velocidad deseada, como en el juego
	var k := 1.0 - exp(-delta * ARRANQUE)
	velocity += (pedido * VELOCIDAD - velocity) * k
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
	if stick.length() > 0.5:
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
	else:
		sprite.speed_scale = ritmo_anim
		sprite.play(nombre)
		sprite.set_frame_and_progress(0, 0.0)


# Golpe cuerpo a cuerpo: pega a todos los zombis que estén dentro del abanico (meleeHit en el juego)
func golpear(angulo: float) -> void:
	var w := arma()
	var mitad := deg_to_rad(w.arco) / 2.0
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var hacia: Vector2 = zombi.global_position - global_position
		var distancia := hacia.length()
		if distancia - zombi.radio > w.alcance:
			continue
		# angle_difference da lo que hay que girar de un ángulo al otro (de -180° a 180°)
		var desvio := absf(angle_difference(angulo, hacia.angle()))
		if desvio <= mitad + 0.2 or distancia < zombi.radio + 12.0:
			zombi.recibir_golpe(w.dano, hacia.normalized() * EMPUJE * w.empuje)


# Saca la bala (o los perdigones) por la boca del arma, como se ve en el dibujo
func disparar(angulo: float) -> void:
	var w := arma()
	balas -= 1
	# La boca del arma está en píxeles del dibujo desde los pies (x2 para pasar a unidades); los pies van
	# 16 unidades por debajo del centro de Johnny. La bala de verdad va 50 más abajo, a ras de suelo, y se
	# dibuja 50 más arriba (ver bala.gd): así sale de la boca y choca con lo que hay a la altura de los pies
	var boca: Vector2 = w.boca[direccion] * 2.0
	var salida := global_position + Vector2(boca.x, 16.0 + boca.y + 50.0)
	for i in w.perdigones:
		var desvio := 0.0
		if w.perdigones > 1:
			desvio = (float(i) / (w.perdigones - 1) - 0.5) * w.abertura   # abiertos en abanico
		desvio += (randf() - 0.5) * w.temblor
		var rapidez: float = w.velocidad * (randf_range(0.9, 1.1) if w.temblor > 0.0 else 1.0)
		var bala := BALA.instantiate()
		bala.velocidad = Vector2.from_angle(angulo + desvio) * rapidez
		bala.dano = w.dano
		bala.empuje = w.empuje
		bala.radio = 3.0 if w.perdigones > 1 else 4.0
		bala.vida = w.alcance / w.velocidad
		get_parent().add_child(bala)
		bala.global_position = salida
	# El disparo se oye: despierta a los zombis dormidos que haya cerca
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.has_method("oir_disparo"):
			zombi.oir_disparo(global_position)
	if balas <= 0:
		empezar_recarga()
	avisar_arma()


# Antes de disparar: ¿hay bala en el cargador? Si no, recarga. La escopeta puede disparar a mitad de recarga
# (con lo que lleve metido); las demás, no
func lista_para_disparar() -> bool:
	if recargando > 0.0:
		if not arma().cartucho or balas <= 0:
			return false
		recargando = 0.0   # dispara y deja de meter cartuchos
	if balas > 0:
		return true
	empezar_recarga()
	return false


# De momento las balas de reserva no se acaban (las cajas de munición y la tienda vendrán más adelante)
func empezar_recarga() -> void:
	var w := arma()
	if w.tipo != "fuego" or recargando > 0.0 or balas >= w.cargador:
		return
	recargando = w.recarga
	avisar_arma()


# Mete el cargador entero o, en la escopeta, un cartucho (y sigue con el siguiente)
func terminar_recarga() -> void:
	var w := arma()
	recargando = 0.0
	if w.cartucho:
		balas += 1
		if balas < w.cargador:
			recargando = w.recarga
	else:
		balas = w.cargador
	avisar_arma()


# Coge un arma (teclas 1 a 6): va a su hueco y se la pone en la mano. Si es de fuego, con el cargador lleno
func coger(id: String) -> void:
	var w: Dictionary = Armas.DATOS[id]
	huecos[w.tipo] = id
	if w.tipo == "fuego":
		balas = w.cargador
	sostener(w.tipo)


# Cambia a la otra arma (Q, rueda del ratón o botón Y)
func cambiar_mano() -> void:
	sostener("fuego" if mano == "cuerpo" else "cuerpo")
	espera = maxf(espera, CAMBIO)   # un instante para cambiar de arma


# Se pone en la mano el arma de ese hueco: lo que estaba haciendo con la otra se corta
func sostener(hueco: String) -> void:
	mano = hueco
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
	texto += "\n[Q] " + Armas.DATOS[otra].nombre
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
	invulnerable = INVULNERABLE
	quitar_vida(cantidad)


# Lo llaman los charcos (moco, lejía) en cada paso mientras los pisa: quita vida poco a poco, sin parpadear
# ni dejarle invulnerable, y le tiñe del color del charco. "cantidad" suele ser un trocito (4 por segundo ×
# lo que dura un paso), así que se va sumando y se quita cuando llega a un punto entero
func pisar_charco(cantidad: float, color: Color) -> void:
	if not vivo:
		return
	charco_tinte = color
	charco_tiempo = 0.15
	charco_dano += cantidad
	if charco_dano >= 1.0:
		var entero := int(charco_dano)
		charco_dano -= entero
		quitar_vida(entero)


# Un empujón (el fregonazo de la portera, su grito): se suma a su velocidad y su frenada lo va parando
func empujar(fuerza: Vector2) -> void:
	if vivo:
		velocity += fuerza


func quitar_vida(cantidad: int) -> void:
	vida = max(vida - cantidad, 0)
	vida_cambiada.emit(vida, VIDA_MAX)
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
