# Johnny, el conserje: se mueve con WASD, las flechas o el stick izquierdo del mando, y pone la animación
# de andar, de reposo o de ataque mirando hacia una de las 8 direcciones.
#
# Armas (los números están en armas.gd). Como en el juego de navegador, lleva dos: una de cuerpo a cuerpo y
# otra de fuego, y se cambia entre ellas con Q, la rueda del ratón o el botón Y del mando. Para probar, las
# teclas 1 a 6 ponen cualquiera de las seis. R (o el botón X del mando) recarga. El lanzallamas no dispara: mientras
# se ataca echa una llamarada continua (llamarada.gd) y gasta su depósito, que se llena con una gasolina de la mochila.
# Tres modos de atacar (se elige en Opciones, o F1, C o la cruceta abajo del mando
# cambian de uno a otro; se guarda):
#   asistido  apunta y ataca solo, como en el juego (src/aim.js): busca el zombi más cercano que vea y, si
#             está a tiro, le pega o le dispara. El jugador solo se preocupa de moverse
#   mira      ataca mientras se pulsa J, el clic izquierdo o el gatillo RT del mando, hacia donde mira Johnny
#   libre     apunta con el ratón (y ataca con el clic o J) o con el stick derecho del mando (y ataca mientras
#             lo empuja). Con una ayuda suave: si apuntas casi encima de un zombi, se tuerce un poco hacia él
#
# Tiene vida: los zarpazos se la quitan y, cuando cambia, lo avisa con la señal "vida_cambiada". La vida va
# en tres tercios: el tercio que pierde ya no se cura, y por cada uno anda un 25 % más lento (como en el JS).
# Con la ayuda "Vida entera" (Opciones > Ayudas) no se pierden tercios; con "Pistola sin fin", la pistola no
# gasta balas.
# Sus atributos (vida máxima, velocidad, daño, ritmo, alcance...) están en "stats" (mejoras.gd): los números
# de las armas se multiplican por ellos.
#
# Esquiva (Espacio, Mayús o el botón A del mando): un acelerón corto en el que no le hacen daño, y se recarga
# en poco menos de un segundo (como el dash del JS). Los talentos (talentos.gd) le dan, además de números:
# Lobezno (recupera vida poco a poco), Durito (cada golpe quita menos), Reflejos (de vez en cuando esquiva solo
# un golpe), Acero (un escudo al empezar cada planta), Mirilla (crítico seguro cada 4 disparos), Ninja (golpe
# en área al acabar la esquiva) y Desfibrilador (resucita una vez por partida).
#
# Las skins (skins.gd): vestir() le cambia las hojas por las de esa skin (las de siempre con otra cabeza); al
# empezar se pone la que dice el guardado. El portero, además, pega con la fregona un 300 % más (arma()), y con el
# glotón quien le hace daño lo paga (devolver()).
extends CharacterBody2D

signal vida_cambiada(vida: int, maxima: int)   # la barra de vida de la pantalla escucha esta señal
signal murio
signal arma_cambiada(texto: String)            # el cartel del arma (y sus balas) de la pantalla escucha esta
signal modo_cambiado(nombre: String)           # y la ayuda de abajo, el modo de atacar
signal resucito                                # Desfibrilador: la partida saca el aviso

const ARRANQUE := 14.0     # lo rápido que llega a su velocidad (y frena): igual que en el juego
# Unidades que avanza en un ciclo de andar (dos pasos), según hacia dónde da el paso. Medido en el dibujo: de lado
# el pie apoyado se va hacia atrás más que de frente o de espaldas. Con 140 (lo del juego viejo) los pies patinaban
# y parecía que flotaba; pegados del todo serían 62 y 52, pero las piernas irían a toda prisa: esto es el término medio
const PASO := {"e": 96.0, "o": 96.0, "se": 84.0, "so": 84.0, "ne": 84.0, "no": 84.0, "s": 84.0, "n": 84.0}
const RADIO := 18.0        # su círculo de choque (los zombis lo usan para saber si está a tiro)

const INVULNERABLE := 0.9  # segundos sin recibir daño después de un zarpazo (parpadea), como en el juego
const ESQUIVA := 0.16      # lo que dura el acelerón de la esquiva
const ESQUIVA_RAPIDEZ := 3.3   # x su velocidad durante la esquiva
const REGENERA_CADA := 3.0 # Lobezno: segundos entre cura y cura
const CAIDA := 0.22        # tropezón (caer): lo que tarda en llegar al suelo y en levantarse
const LEVANTADO := 0.6     # recién levantado, este rato sin volver a tropezar
const AZUL := Color("#9fe8ff")
const MORDISCO := Color("#ff5d5d")   # el «¡ÑAM!» del glotón sobre el que le ha hecho daño

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
var caido_t := 0.0         # lo que le queda tirado en el suelo por un tropezón (caer; 0 = de pie)
var caido_max := 0.0       # lo que dura ese tropezón
var caido_lado := 1.0      # hacia dónde ha caído: 1, con la cabeza a la derecha; -1, a la izquierda
var levantado_t := 0.0     # lo que le queda sin poder volver a tropezar
var sombra_ancho := 0.0    # lo ancha que es su sombra de pie (tumbado, se alarga)
var estrellas: Node2D      # las estrellitas que le dan vueltas a la cabeza cuando está en el suelo

var huecos := {"cuerpo": "fregona", "fuego": "pistola"}   # las dos armas que lleva
var mano := "cuerpo"       # cuál de las dos tiene en la mano
var balas := 0             # balas que quedan en el cargador del arma de fuego
var reserva := 0           # balas de repuesto en la mochila, para recargar
var sin_balas_sola := false   # se ha pasado sola a la de cuerpo a cuerpo al quedarse sin balas
var municion_guardada := {}   # las balas de las armas de fuego que ha guardado: {id: [cargador, reserva]}
var recargando := 0.0      # tiempo que falta para acabar de recargar (0 = no recarga)
var deposito := 0.0        # el lanzallamas: los segundos de fuego que le quedan en el depósito
var gasolina_sin_fin := false   # la sala de pruebas de armas: el lanzallamas se llena sin gastar gasolina
var llamarada: Llamarada   # la llama del lanzallamas (y el chorro del lanza ácido): sale mientras se ataca con él
var goteo: Goteo           # la gota de ácido que cuelga de la boquilla del lanza ácido mientras no echa el chorro
var espera := 0.0          # tiempo que falta para poder atacar otra vez
var ataque_t := -1.0       # tiempo desde que empezó el ataque en curso (-1 = no está atacando)
var ataque_dur := 0.0      # lo que dura ese ataque
var golpe_pendiente := false   # golpe cuerpo a cuerpo que aún no ha llegado (pega a mitad de animación)
var golpe_angulo := 0.0        # y hacia dónde va
var patada_t := -1.0           # tiempo desde el último disparo andando (-1 = nada): el retroceso de todo el cuerpo
var patada := Vector2.ZERO     # hacia dónde y cuánto empuja ese disparo

var skin := ""             # la skin puesta (skins.gd; "" = el conserje de siempre): sus hojas y su ventaja
var modo := "asistido"     # cómo se ataca (ver arriba)
var con_raton := false     # modo libre: si se está apuntando con el ratón (se ha movido hace poco)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var efectos: AnimatedSprite2D = $Efectos   # fogonazo, humo y casquillo al disparar andando
@onready var piernas: AnimatedSprite2D = $Sprite/Piernas   # las piernas andando debajo de un golpe (cintura.gdshader)


func _ready() -> void:
	efectos.animation_finished.connect(efectos.hide)
	llamas = Llamas.new()
	llamas.alto = 70.0
	llamas.fuerza = 0.0
	add_child(llamas)
	llamarada = Llamarada.new()
	add_child(llamarada)
	goteo = Goteo.new()
	add_child(goteo)
	estrellas = Node2D.new()
	estrellas.name = "Estrellas"
	estrellas.draw.connect(pintar_estrellas)
	add_child(estrellas)
	sombra_ancho = $Sombra.ancho
	vida = stats.vida_max
	balas = Armas.datos(huecos.fuego).cargador
	reserva = balas * RESERVA_INICIO
	skin = Skins.puesta()   # la skin que lleva puesta (antes de coger el arma: cada skin tiene sus hojas)
	sostener(mano)
	# Al empezar, que la barra se ponga llena
	vida_cambiada.emit.call_deferred(vida, stats.vida_max)
	# El modo de atacar elegido la última vez (en Opciones o con F1)
	var guardado := Guardado.cargar()
	if guardado.ajustes.modo in MODOS:
		modo = guardado.ajustes.modo
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
	return roundi(tercios_vivos() * stats.vida_max / 3.0)


# Los tercios que cuentan: con la ayuda "Vida entera", siempre los tres
func tercios_vivos() -> int:
	return 3 if Guardado.ajuste("vida_entera") else tercios


# Ayuda "Pistola sin fin": la pistola no gasta balas ni se recarga (en el reto "Solo cuerpo a cuerpo", no vale)
func pistola_sin_fin() -> bool:
	return huecos.fuego == "pistola" and Guardado.ajuste("pistola_sin_fin") and not Reto.sin_municion()


func curar(cantidad: int) -> void:
	if not vivo or vida >= vida_tope():
		return
	vida = mini(vida + cantidad, vida_tope())
	vida_cambiada.emit(vida, stats.vida_max)


# F1, C o cruceta abajo: pasa al siguiente modo de atacar (y se guarda para la próxima vez)
func cambiar_modo() -> void:
	var nombres := MODOS.keys()
	var nuevo: String = nombres[(nombres.find(modo) + 1) % nombres.size()]
	poner_modo(nuevo)
	Guardado.cambiar(func(g): g.ajustes.modo = nuevo)


func poner_modo(nuevo: String) -> void:
	modo = nuevo
	modo_cambiado.emit(MODOS[modo])


# El arma que tiene en la mano: sus datos, con los atributos de Johnny ya aplicados
func arma() -> Dictionary:
	var w: Dictionary = Armas.datos(huecos[mano]).duplicate()
	w.dano = w.dano * stats.dano * (stats.dano_cuerpo if w.tipo == "cuerpo" else stats.dano_fuego)
	if huecos[mano] == "fregona":
		w.dano = w.dano * Skins.fregona(skin)   # el portero: × 4 (solo la fregona de siempre)
	if w.tipo == "cuerpo":
		w.dano = w.dano * Skins.cuerpo(skin)    # el gymbro: × 3 (todas, también las creadas en el banco)
	if w.get("efecto", "") in ArmasCreadas.QUEMAN:
		w.quema = Skins.quema(skin)             # el bombero: × 3 el golpe o la gota, y lo que sigue ardiendo el zombi
		w.dano = w.dano * w.quema
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
	levantado_t -= delta
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
	# Los estados de los charcos: el daño poco a poco (sin parpadear), el tinte, las llamas y las gotitas. Si te
	# acompaña la farmacéutica, el veneno y el ácido hacen la mitad (aliado.gd)
	for nombre in Aliado.CHARCOS:
		if pisando.has(nombre):
			pisando[nombre] = pisando[nombre].merged({"dps": pisando[nombre].get("dps", 0.0) * Aliado.charcos_a_medias(get_tree())}, true)
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
	# Tirado en el suelo por un tropezón: ni anda, ni ataca, ni rueda hasta que se levanta
	if caido_t > 0.0:
		seguir_caido(delta)
		return

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
	# Pistola sin fin: si se pone la ayuda con el cargador a medias, se llena (y deja de recargar)
	if pistola_sin_fin() and balas < Armas.datos("pistola").cargador:
		balas = Armas.datos("pistola").cargador
		recargando = 0.0
		avisar_arma()
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
		var rapidez: float = stats.velocidad * (1.0 - 0.25 * (3 - tercios_vivos()))   # más lento por cada tercio perdido
		rapidez *= Estados.frenado(estados)   # el frío de la cámara, el calambrazo del agua
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
	gotear()
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
	Tactil.vibracion()


# Una copia de Johnny, azulada y medio transparente, que se queda atrás y se apaga
func soltar_estela() -> void:
	var copia := Sprite2D.new()
	copia.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	copia.centered = sprite.centered
	copia.offset = sprite.offset
	copia.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# entera (sin partir por la cintura)
	var material: ShaderMaterial = sprite.material.duplicate()
	material.set_shader_parameter("parte", 0)
	copia.material = material
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


# Ataca hacia ese ángulo si ya puede (ha pasado el hueco entre ataques y, si es de fuego, tiene bala). El lanzallamas,
# en cada paso en que se ataca con él, echa fuego
func intentar_atacar(angulo: float) -> void:
	var w := arma()
	if espera > 0.0 or not (w.tipo == "cuerpo" or lista_para_disparar()):
		return
	direccion = direccion_de(Vector2.from_angle(angulo))
	if w.has("deposito"):
		echar_fuego(angulo, w)
		return
	espera = 1.0 / w.ritmo
	atacar(angulo)


# El lanzallamas: la llamarada sale de la boca del tubo (llamarada.gd; si en este paso no se llama aquí, se apaga) y
# el depósito se va gastando. Va paralela a la línea de tiro (no se tuerce hacia el zombi como la bala: el cono ya lo
# pilla, y torcida subía por encima de las cabezas). Sin sacudida ni retroceso: quieto, Johnny se queda en la postura de
# apuntar (animar). Al vaciarse el depósito, se llena solo si lleva gasolina
func echar_fuego(angulo: float, w: Dictionary) -> void:
	var boca: Vector2 = w.boca[direccion] * 2.0
	llamarada.mantener(global_position + Vector2(boca.x, 16.0 + boca.y + 50.0), angulo, w)
	deposito = maxf(0.0, deposito - get_physics_process_delta_time())
	if deposito <= 0.0:
		empezar_recarga()
		avisar_arma()


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
		# ni a la modista quieta entre los maniquíes: hay que encontrarla (o pegarle a mano)
		if zombi.has_method("escondida") and zombi.escondida():
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
		# Disparando mientras anda: sigue andando y los efectos del disparo se pintan encima. El bumerán no tiene
		# (su hoja solo lleva el gesto de lanzar, que no se pinta andando): sigue andando sin gesto y sin retroceso
		ataque_t = -1.0   # las piernas siguen con la animación de andar
		if efectos.sprite_frames.has_animation("efectos_" + direccion):
			efectos.speed_scale = ritmo_anim
			efectos.play("efectos_" + direccion)
			efectos.set_frame_and_progress(0, 0.0)
			efectos.show()
			# como andando no se ve el retroceso de los brazos, el disparo empuja a Johnny entero hacia atrás
			patada = -Vector2.from_angle(angulo) * PATADA * (1.6 if w.get("perdigones", 1) > 1 else 1.0)
			patada_t = 0.0
	else:
		if sprite.animation.begins_with("andar"):
			# Si golpea andando, las piernas siguen el paso desde donde iba (animar() las enseña)
			piernas.play(sprite.animation)
			piernas.set_frame_and_progress(sprite.frame, sprite.frame_progress)
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
		# el parón y el temblor del golpe (como en el JS): más fuerte cuantos más pilla
		Temblor.parar(0.05)
		Temblor.temblar(3.0 + tocados)


# De dónde sale la bala y hacia dónde va: [salida, ángulo]. Sale de la boca del arma, como se ve en el dibujo (en
# píxeles del dibujo desde los pies, x2 para pasar a unidades; los pies van 16 unidades por debajo del centro de
# Johnny). La bala de verdad va 50 más abajo, a ras de suelo, y se dibuja 50 más arriba (ver bala.gd): así sale de la
# boca y choca con lo que hay a la altura de los pies. Si la línea de tiro (desde el centro de Johnny) pasa por un
# zombi, la bala va derecha de la boca a él: paralela a esa línea, con la boca lejos del centro pasaría por el lado.
# Las armas creadas a distancia (gotas, bumerán, garfio...) van como siempre, paralelas
func tiro(angulo: float, w: Dictionary, hacia: String) -> Array:
	var boca: Vector2 = w.boca[hacia] * 2.0
	var salida := global_position + Vector2(boca.x, 16.0 + boca.y + 50.0)
	var blanco := blanco_en_linea(angulo, w)
	if blanco == null or w.has("efecto"):
		return [salida, angulo]
	if (blanco.global_position - salida).dot(Vector2.from_angle(angulo)) > blanco.radio:
		return [salida, (blanco.global_position - salida).angle()]
	# A quemarropa (el zombi está más cerca que la boca): sale de Johnny, porque de la boca nacería detrás del zombi
	return [global_position, (blanco.global_position - global_position).angle()]


# El zombi al que apunta la línea de tiro: el más cercano, a tiro y a la vista, cuyo círculo de acierto (el de
# bala.gd: su radio, el de la bala y 3 de margen) cruza la línea que sale del centro de Johnny
func blanco_en_linea(angulo: float, w: Dictionary) -> Node2D:
	var u := Vector2.from_angle(angulo)
	var radio_bala := 3.0 if w.get("perdigones", 1) > 1 else 4.0
	var mejor: Node2D = null
	var cerca := INF
	for zombi in get_tree().get_nodes_in_group("zombis"):
		var hacia: Vector2 = zombi.global_position - global_position
		var delante := hacia.dot(u)
		if delante <= 0.0 or delante >= cerca or hacia.length() - zombi.radio > w.alcance:
			continue
		if absf(hacia.cross(u)) > zombi.radio + radio_bala + 3.0 or not se_ve(zombi):
			continue
		mejor = zombi
		cerca = delante
	return mejor


# Saca la bala (o los perdigones) por la boca del arma, como se ve en el dibujo, hacia el zombi al que apunta
func disparar(angulo: float) -> void:
	var w := arma()
	if not w.get("sin_municion", false) and not pistola_sin_fin():
		balas -= 1
	disparos += 1
	var seguro: bool = stats.mirilla and disparos % 4 == 0   # Mirilla: tras 3 disparos, uno crítico seguro
	var t := tiro(angulo, w, direccion)
	var salida: Vector2 = t[0]
	angulo = t[1]
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
		bala.critico = bala.dano > roundi(w.dano)
		bala.vida = w.alcance / w.velocidad
		get_parent().add_child(bala)
		bala.global_position = salida
	Sonido.tocar("escopeta" if w.perdigones > 1 else "pistola")
	soltar_casquillo(angulo, w.perdigones > 1)
	if w.perdigones > 1:
		Temblor.temblar(4.0)   # la escopeta da un buen golpe
	# El fogonazo alumbra un instante alrededor (más con la escopeta)
	Luz.destello(self, salida - Vector2(0, 50), 170.0 if w.perdigones > 1 else 120.0, 0.12 if w.perdigones > 1 else 0.08)
	oir_disparo()
	if balas <= 0:
		empezar_recarga()
	avisar_arma()


# El casquillo sale despedido por la derecha del arma, salta, rebota y se queda en el suelo un buen rato
# (los de la escopeta, rojos y más gordos)
func soltar_casquillo(angulo: float, cartucho: bool) -> void:
	var mapa := get_tree().get_first_node_in_group("mapa")
	var suelo: Node = mapa.cosas if mapa and "cosas" in mapa else get_parent()
	var lado := Vector2.from_angle(angulo + PI / 2.0 + randf_range(-0.4, 0.4))
	var v := lado * randf_range(70.0, 120.0) - Vector2.from_angle(angulo) * randf_range(10.0, 40.0)
	var color := Color("#c0392b") if cartucho else Color("#e8b84a")
	var marca := Color("#8e2a20") if cartucho else Color("#b8892e")
	Particulas.volar(self, global_position + Vector2(0, 14), 40.0, Vector2(v.x, v.y * 0.6), randf_range(110.0, 160.0),
		color, 4.0, suelo, marca, Vector2(6, 4) if cartucho else Vector2(4, 2), false, false, 2, "Casquillos")


# El disparo se oye: despierta a los zombis dormidos que haya cerca
func oir_disparo() -> void:
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.has_method("oir_disparo"):
			zombi.oir_disparo(global_position)


# Antes de disparar: ¿hay bala en el cargador (o fuego en el depósito)? Si no, recarga. La escopeta puede disparar
# a mitad de recarga (con lo que lleve metido); las demás, no
func lista_para_disparar() -> bool:
	if recargando > 0.0:
		if not arma().cartucho or balas <= 0:
			return false
		recargando = 0.0   # dispara y deja de meter cartuchos
	if cargado() > 0.0:
		return true
	if repuesto() > 0:
		empezar_recarga()
		return false
	# sin balas (o sin gasolina): a la fregona (o la que lleve)
	sin_municion_aviso()
	sostener("cuerpo")
	sin_balas_sola = true
	return false


# Lo que le queda en el arma de fuego (las balas del cargador o, en el lanzallamas, los segundos del depósito) y lo
# que tiene para volver a llenarla (las balas de reserva, o las gasolinas de la mochila)
func cargado() -> float:
	return deposito if Armas.datos(huecos.fuego).has("deposito") else float(balas)


func repuesto() -> int:
	return gasolinas() if Armas.datos(huecos.fuego).has("deposito") else reserva


# El aviso de que no le queda con qué disparar
func sin_municion_aviso() -> void:
	var texto := "¡Sin gasolina!" if Armas.datos(huecos.fuego).has("deposito") else "¡Sin balas!"
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-50, -70), texto, Color("#ff9f1c"), 18)
	Sonido.tocar("click")


# Las gasolinas que lleva en la mochila de la partida (en la sala de pruebas de armas, sin fin)
func gasolinas() -> int:
	if gasolina_sin_fin:
		return 99
	var partida := get_tree().current_scene
	return partida.mochila.count("gasolina") if "mochila" in partida else 0


# Coge una gasolina del suelo (partida.gd): si se había pasado sola a la de cuerpo a cuerpo por quedarse sin, vuelve
# a sacar el lanzallamas; y si tiene el depósito vacío, lo llena
func coger_gasolina() -> void:
	if not Armas.datos(huecos.fuego).has("deposito"):
		return
	if sin_balas_sola:
		sostener("fuego")
	if mano == "fuego":
		empezar_recarga()


# Empieza a recargar, si hace falta y le quedan balas de reserva. El lanzallamas, solo con el depósito vacío (con la R
# a medias no se tira media gasolina) y si lleva gasolina
func empezar_recarga() -> void:
	var w := arma()
	if w.tipo != "fuego" or recargando > 0.0 or pistola_sin_fin():
		return
	if w.has("deposito"):
		if deposito > 0.0 or gasolinas() <= 0:
			return
	elif balas >= w.cargador or reserva <= 0:
		return
	recargando = w.recarga
	Sonido.tocar("recargar")
	avisar_arma()


# Mete el cargador entero o, en la escopeta, un cartucho (y sigue con el siguiente). El lanzallamas gasta una
# gasolina de la mochila y llena el depósito entero
func terminar_recarga() -> void:
	var w := arma()
	recargando = 0.0
	if w.has("deposito"):
		if gasolinas() <= 0:   # (la ha tirado desde el inventario mientras tanto)
			avisar_arma()
			return
		if not gasolina_sin_fin:
			var mochila: Array = get_tree().current_scene.mochila
			mochila.remove_at(mochila.rfind("gasolina"))
		deposito = w.deposito
		Sonido.tocar("recargado")
		avisar_arma()
		return
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
	# (al lanzallamas no le valen las balas: solo la gasolina)
	return not w.get("sin_municion", false) and not w.has("deposito") and reserva < w.cargador * RESERVA_MAX


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
# partida (las creadas guardan las suyas en Armas.sacadas; el lanzallamas, lo que le quedaba en el depósito, y si es
# nuevo, lleno)
func coger(id: String) -> void:
	var w: Dictionary = Armas.datos(id)
	if w.tipo == "fuego":
		var vieja: String = huecos.fuego
		if Armas.es_creada(vieja):
			Armas.sacadas[vieja].balas = balas
			Armas.sacadas[vieja].reserva = reserva
			Armas.sacadas[vieja].deposito = deposito
		else:
			municion_guardada[vieja] = [balas, reserva]
		balas = w.cargador
		reserva = w.cargador * RESERVA_INICIO
		deposito = w.get("deposito", 0.0)
		if Armas.es_creada(id):
			balas = Armas.sacadas[id].get("balas", balas)
			reserva = Armas.sacadas[id].get("reserva", reserva)
			deposito = Armas.sacadas[id].get("deposito", deposito)
		elif municion_guardada.has(id):
			balas = municion_guardada[id][0]
			reserva = municion_guardada[id][1]
			municion_guardada.erase(id)
	huecos[w.tipo] = id
	sostener(w.tipo)


# Cambia a la otra arma (Q, rueda del ratón o botón Y)
func cambiar_mano() -> void:
	# a la de fuego sin balas (o sin gasolina) no se cambia
	if mano == "cuerpo" and cargado() <= 0.0 and repuesto() <= 0:
		sin_municion_aviso()
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
	# Cada arma tiene su hoja de Johnny (y cada skin la suya); los pies van en el mismo sitio aunque sea más alta
	partir_cintura(false)
	var hoja := Skins.hoja(w.hoja, skin)
	sprite.sprite_frames = hoja
	efectos.sprite_frames = hoja
	piernas.sprite_frames = hoja
	sprite.offset = -w.pies
	efectos.offset = -w.pies
	piernas.offset = -w.pies
	sprite.speed_scale = 1.0
	sprite.play("reposo_" + direccion)
	avisar_arma()


# Le cuenta a la pantalla qué arma lleva, cuántas balas le quedan y cuál es la otra
func avisar_arma() -> void:
	var w := arma()
	var texto: String = w.nombre
	if w.has("deposito"):
		texto += "   %d s · %d gasolina" % [ceili(deposito), gasolinas()]
	elif w.tipo == "fuego":
		texto += "   %d/%d" % [balas, w.cargador]
		if recargando > 0.0:
			texto += "   recargando…"
	var otra: String = huecos["fuego" if mano == "cuerpo" else "cuerpo"]
	texto += "\n[Q] " + Armas.datos(otra).nombre
	arma_cambiada.emit(texto)


func animar() -> void:
	var rapidez := velocity.length()
	# Mientras dura el ataque se deja su animación (se puso al empezarlo). Si es un golpe y va andando, el
	# cuerpo da el golpe y las piernas siguen andando debajo, para que no parezca que flota
	if ataque_t >= 0.0:
		var partir: bool = rapidez > 20.0 and arma().tipo == "cuerpo"
		partir_cintura(partir)
		if partir:
			var p := paso()
			var andar: String = "andar_" + p[0]
			if piernas.animation != andar:
				var fotograma := piernas.frame
				piernas.play(andar)
				piernas.set_frame_and_progress(fotograma % piernas.sprite_frames.get_frame_count(andar), 0.0)
			piernas.speed_scale = ritmo_andar(piernas, rapidez) * p[1]
		return
	if piernas.visible:
		# Acaba un golpe dado andando: sigue con el paso por donde iban las piernas
		partir_cintura(false)
		if rapidez > 20.0:
			var andar := "andar_" + direccion
			sprite.play(andar)
			sprite.set_frame_and_progress(piernas.frame % sprite.sprite_frames.get_frame_count(andar), piernas.frame_progress)
	if rapidez > 20.0:
		cambiar_animacion("andar_" + direccion)
		# Entero no puede girar las piernas: si va de espaldas a donde mira, el paso va marcha atrás
		sprite.speed_scale = ritmo_andar(sprite, rapidez) * paso()[1]
	else:
		# quieto echando fuego con el lanzallamas: en la postura de apuntar, sin respirar
		cambiar_animacion(("quieto_" if llamarada.pedida else "reposo_") + direccion)
		sprite.speed_scale = 1.0


# El lanza ácido gotea por la boquilla (goteo.gd) mientras lo lleva en la mano de pie, sin echar el chorro y con
# ácido en el depósito: se le dice dónde está el labio de la boquilla en el dibujo de ahora (las "puntas" de su hoja,
# que solo tiene las del reposo). Andando o echando el chorro no se le dice, y la gota se suelta
func gotear() -> void:
	var puntas: Dictionary = sprite.sprite_frames.get_meta("puntas", {})
	var dibujo := String(sprite.animation)
	if deposito <= 0.0 or llamarada.pedida or not puntas.has(dibujo) or Armas.datos(huecos[mano]).get("efecto", "") != "acido":
		return
	var p: Array = puntas[dibujo]
	goteo.gotear(sprite.global_position + p[sprite.frame % p.size()] * 2.0, direccion)


# El paso va según lo que avanza de verdad: más despacio al arrancar y al frenar.
# Cada dirección tiene su número de fotogramas; la hoja los pone a su velocidad (12 por segundo)
func ritmo_andar(dibujo: AnimatedSprite2D, rapidez: float) -> float:
	var fotogramas := dibujo.sprite_frames.get_frame_count(dibujo.animation)
	var fps := dibujo.sprite_frames.get_animation_speed(dibujo.animation)
	var hacia := String(dibujo.animation).trim_prefix("andar_")
	return (rapidez / PASO.get(hacia, 84.0) * fotogramas) / fps


# Hacia dónde dan el paso las piernas y si van hacia delante (1) o marcha atrás (-1). Johnny puede mirar a un
# zombi y andar hacia otro lado: si anda más o menos hacia donde mira, las piernas van hacia donde anda; si
# anda de espaldas, son las de mirar al frente pero hacia atrás (como quien recula); de lado, las de mirar al frente
func paso() -> Array:
	var mira := Vector2.from_angle(DIRS.find(direccion) * PI / 4)
	var giro := rad_to_deg(absf(mira.angle_to(velocity)))
	if giro < 67.5:
		return [direccion_de(velocity), 1.0]
	if giro > 112.5:
		return [direccion_de(-velocity), -1.0]
	return [direccion, 1.0]


# Tropieza y se cae (las mancuernas del gimnasio del Gymbro: peligros/tropiezos.gd): se queda tirado "segundos",
# sin andar, atacar ni rodar, y luego se levanta. No quita vida (lo malo es lo que pase mientras). Rodando no se
# tropieza, ni recién levantado. Devuelve si se ha caído
func caer(segundos: float) -> bool:
	if not vivo or esquiva_t > 0.0 or caido_t > 0.0 or levantado_t > 0.0:
		return false
	# cae hacia donde iba (si iba de arriba abajo, hacia donde mira)
	var hacia := velocity.x if absf(velocity.x) > 20.0 else Vector2.from_angle(DIRS.find(direccion) * PI / 4).x
	caido_lado = -1.0 if hacia < -0.01 else 1.0
	var iba := velocity
	quedarse_quieto()
	velocity = iba * 0.6   # resbala un poco al caer
	efectos.hide()
	cambiar_animacion("reposo_s")   # boca arriba: tumbado, se le ve la cara
	caido_t = segundos
	caido_max = segundos
	Sonido.tocar("golpe")
	Temblor.temblar(6.0)
	Tactil.vibracion()
	return true


# En el suelo: cae de lado (el dibujo se tumba), le dan vueltas unas estrellitas y, al acabar, se levanta
func seguir_caido(delta: float) -> void:
	caido_t -= delta
	velocity *= exp(-delta * 7.0)
	move_and_slide()
	tumbar(clampf(minf(caido_max - caido_t, caido_t) / CAIDA, 0.0, 1.0))
	estrellas.queue_redraw()
	if caido_t <= 0.0:
		caido_t = 0.0
		levantado_t = LEVANTADO
		tumbar(0.0)
		estrellas.queue_redraw()


# Cuánto está tumbado (0, de pie; 1, en el suelo). El dibujo gira por la mitad del cuerpo, no por los pies, y baja
# hasta el suelo; la sombra se alarga
func tumbar(k: float) -> void:
	var giro := caido_lado * PI / 2.0 * k
	sprite.rotation = giro
	var medio := Vector2(0, lerpf(-28.0, 4.0, k))      # dónde queda la mitad del cuerpo
	sprite.position = medio - Vector2(0, -44).rotated(giro)   # (la mitad del cuerpo, 44 unidades por encima de los pies)
	$Sombra.ancho = lerpf(sombra_ancho, sombra_ancho * 1.9, k)
	$Sombra.queue_redraw()


# Tres estrellitas que dan vueltas sobre la cabeza mientras está en el suelo: cruces de 5 píxeles del dibujo (de 2
# unidades), amarillas o blancas, con su borde oscuro
func pintar_estrellas() -> void:
	if caido_t <= 0.0 or caido_max - caido_t < CAIDA:
		return
	var cabeza := Vector2(caido_lado * 40.0, -22.0)
	var t := Time.get_ticks_msec() / 1000.0
	for i in 3:
		var a := t * 5.0 + i * TAU / 3.0
		var p := ((cabeza + Vector2(cos(a) * 22.0, sin(a) * 8.0)) / 2.0).round() * 2.0
		var color := Color("#ffd23f") if i != 1 else Color.WHITE
		for capa in [[Color("#1d1b2c"), 2.0], [color, 0.0]]:
			var b: float = capa[1]
			estrellas.draw_rect(Rect2(p + Vector2(-5 - b, -1 - b), Vector2(10 + b * 2, 2 + b * 2)), capa[0])
			estrellas.draw_rect(Rect2(p + Vector2(-1 - b, -5 - b), Vector2(2 + b * 2, 10 + b * 2)), capa[0])


# Parte a Johnny por la cintura (golpe arriba, piernas de andar abajo) o lo deja entero
# Se queda quieto del todo (la presentación del jefe, ui/presentacion.gd): corta el golpe o el disparo que llevara a
# medias y deja el dibujo en reposo, para que no siga moviendo las piernas mientras está parado
func quedarse_quieto() -> void:
	velocity = Vector2.ZERO
	ataque_t = -1.0
	golpe_pendiente = false
	patada_t = -1.0
	partir_cintura(false)
	sprite.speed_scale = 1.0
	cambiar_animacion("reposo_" + direccion)


func partir_cintura(si: bool) -> void:
	piernas.visible = si
	sprite.material.set_shader_parameter("parte", 1 if si else 0)


# Le pone una skin (skins.gd; "" = el conserje de siempre): las hojas de esa skin para el arma que lleva, sin
# cortar lo que estaba haciendo (sigue con la misma animación, en el mismo punto)
func vestir(id: String) -> void:
	skin = id
	var hoja := Skins.hoja(arma().hoja, skin)
	for dibujo: AnimatedSprite2D in [sprite, efectos, piernas]:
		var animacion := dibujo.animation
		var fotograma := dibujo.frame
		var avance := dibujo.frame_progress
		var andando := dibujo.is_playing()
		dibujo.sprite_frames = hoja
		dibujo.animation = animacion
		if andando:
			dibujo.play(animacion)
		dibujo.set_frame_and_progress(fotograma, avance)


# Lo llaman los zombis al darle un zarpazo. "quien": el que se lo hace (el zombi o el jefe; en lo que se lanza, el que
# lo lanzó), para el glotón (devolver()); nada si no es de nadie (charcos, agua con corriente, explosiones). Sin tipo:
# lo que se lanza puede llegar cuando su dueño ya no está
func recibir_dano(cantidad: int, quien = null) -> void:
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
	Temblor.temblar(9.0)
	Tactil.vibracion()
	quitar_vida(dano)
	devolver(quien)


# El glotón (skins.gd): el que le ha hecho daño lo paga. Un zombi normal (o un maniquí de la modista) muere al momento;
# un jefe pierde una parte de su vida máxima, directa a la vida (morder(): ni su armadura ni su escudo la paran)
func devolver(quien) -> void:
	var parte := Skins.mordisco(skin)
	if parte <= 0.0 or not is_instance_valid(quien) or quien.get("estado") == "muerto":
		return
	if quien.has_method("morder"):
		quien.morder(ceili(quien.vida_max * parte))
	else:
		var dano: int = quien.vida + 1
		quien.recibir_golpe(dano, (quien.global_position - global_position).normalized() * EMPUJE)
	Zombi.texto_flotante(get_parent(), quien.global_position + Vector2(-30, -60), "¡ÑAM!", MORDISCO, 18)
	Sonido.tocar("mordisco")


# Lo llaman los charcos en cada paso mientras los pisa (charco.gd): apunta sus estados. La esquiva cruza
# cualquier charco sin que le pase nada. Con la skin del bombero, el fuego tampoco (lo demás del charco, sí)
func pisar(estados_charco: Dictionary) -> void:
	if vivo and esquiva_t <= 0.0:
		var pisados := estados_charco
		if ignifugo() and pisados.has("fuego"):
			pisados = estados_charco.duplicate()
			pisados.erase("fuego")
		Estados.pisar(pisando, pisados)


# Si el fuego no le hace nada (la skin del bombero): ni el fuego del suelo ni los charcos (pisar()), ni las bolas
# de fuego (bola_fuego.gd), ni el cono del jefe de bomberos (bombero.gd), ni la botella de su molotov (proyectil.gd)
func ignifugo() -> bool:
	return Skins.ignifugo(skin)


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
	# Al bajar de un tercio, ese tercio se pierde (vidaTope en el JS); con la ayuda "Vida entera", no
	if not Guardado.ajuste("vida_entera"):
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
		caido_t = 0.0   # (si estaba tirado por un tropezón, se queda en el suelo, pero sin estrellitas)
		estrellas.queue_redraw()
		efectos.hide()
		partir_cintura(false)
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
