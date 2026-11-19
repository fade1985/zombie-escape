# El zombi explosivo (el hombretón de la gabardina): no da zarpazos. Cuando llega cerca de Johnny se planta,
# abre la gabardina (enseña la dinamita), parpadea en rojo con un círculo de aviso en el suelo y revienta en cachos de
# carne que salen volando (cachos.gd), sin dejar cuerpo.
# Si lo matas antes, revienta igual. Números de src/zombies.js (EXPLOSION).
extends Zombi

const EXPLOSION := preload("res://escenas/armas/explosion.tscn")
const RADIO_EXPLOSION := 90.0
const DANO_EXPLOSION := 30
const MECHA := 0.8         # segundos desde que abre la gabardina hasta que revienta
const DISPARADOR := 70.0   # a qué distancia de Johnny (además de su radio) enciende la mecha

var mecha := 0.0
var reventado := false


func andar(delta: float, johnny: Node2D) -> void:
	if distancia_a(johnny) < DISPARADOR + johnny.RADIO and se_ve(johnny):
		# ¡Se enciende la mecha! Abre la gabardina y se queda así (la animación no se repite: acaba abierta)
		estado = "mecha"
		mecha = MECHA / ritmo   # (con la mejora del VD-7, más corta)
		mirar_hacia(johnny.global_position - global_position)
		poner_animacion("ataque")
		return
	ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)


func estado_propio(delta: float, _johnny: Node2D) -> void:
	if estado != "mecha":
		return
	pedir_velocidad(Vector2.ZERO)
	# Un pitido cada octavo de segundo, como el JS
	if floorf(mecha * 8.0) != floorf((mecha - delta) * 8.0):
		Sonido.tocar("pitido")
	mecha -= delta
	# Parpadea en rojo cada vez más deprisa (en blanco taparía la dinamita) y tiembla
	var k := 1.0 - mecha / MECHA
	var rojo := int(tiempo * (8.0 + k * 16.0)) % 2 == 0
	sprite.modulate = Color(1.0, 0.55, 0.5) if rojo else Color.WHITE
	sprite.position.x = randf_range(-1.5, 1.5)
	avisar(k)
	if mecha <= 0.0:
		vida = 0
		morir()


# Con la gabardina abierta no se encoge con los golpes: solo pierde vida (y si se muere, revienta)
func encogerse() -> void:
	if estado != "mecha":
		super()


func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	if estado == "mecha":
		fuerza = Vector2.ZERO   # plantado: no le mueven
	super(cantidad, fuerza)


func morir() -> void:
	super()
	sprite.modulate = Color.WHITE
	sprite.position.x = 0.0
	if reventado:
		return
	reventado = true
	# Revienta en cachos de carne que salen volando hacia todos los lados y caen con su sangre (cachos.gd; 19 nov, lo
	# pidió el dueño). Congelado no: revienta en añicos de hielo (zombi.reventar_hielo)
	if not en_anicos:
		Cachos.lanzar(get_parent(), position + Vector2(0, 10))
	# La explosión se añade "en diferido" (al acabar este paso): si revienta a otro explosivo, ese reventará
	# en el paso siguiente, en cadena, sin liarse
	var bum := EXPLOSION.instantiate()
	bum.radio = RADIO_EXPLOSION
	bum.dano = DANO_EXPLOSION
	bum.origen = self
	bum.de = "explosivo"   # (para el cartel de derrota: le ha pillado el dinamitero)
	bum.position = position
	get_parent().add_child.call_deferred(bum)
	# el estruendo despierta a todos los durmientes del apartamento, en todas sus habitaciones, como un disparo de
	# Johnny (M118, 16 nov): revienta igual si se le acaba la mecha o si lo matas. Fuera de los apartamentos, nada
	var johnny = get_tree().get_first_node_in_group("jugador")   # (sin tipo: en_apartamento es de johnny.gd)
	if johnny != null and johnny.has_method("en_apartamento") and johnny.en_apartamento():
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi != self and zombi.has_method("oir_disparo"):
				zombi.oir_disparo(global_position, true)


# Al reventar no queda cuerpo (19 nov): solo sus cachos (Cachos, en morir). Ni su dibujo ni su fuego
func caer_muerto() -> void:
	Sonido.tocar("chof")
	sprite.visible = false
	if has_node("LuzAcido"):
		get_node("LuzAcido").queue_free()
	if llamas:
		llamas.visible = false


# El aviso en el suelo, el mismo de los jefes (aviso.gd): un círculo de pixel art que se va llenando desde él hacia
# fuera mientras corre la mecha, con su destello justo antes de reventar. Como la explosión, lo paran las paredes, las
# puertas y las barricadas, pero no los muebles (explosion.gd, tapado()): cada rayo llega hasta donde da con ellas.
# Se pide en cada fotograma de la mecha; cuando deja de pedirse (al reventar), se esconde solo
func avisar(k: float) -> void:
	var aviso := Aviso.abanico(self, Vector2(0, 4), 0.0, PI, RADIO_EXPLOSION, k, tiempo)
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa == null:
		return
	var puntas := []
	for i in Aviso.MAX_RAYOS:
		var a := PI * (2.0 * i / (Aviso.MAX_RAYOS - 1) - 1.0)
		var fin := global_position + Vector2.from_angle(a) * RADIO_EXPLOSION
		var choque: Dictionary = mapa.muro_entre(global_position, fin)
		puntas.append(global_position.distance_to(choque.position) if not choque.is_empty() else RADIO_EXPLOSION)
	aviso.rayos(puntas)
