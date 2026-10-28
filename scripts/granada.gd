# La granada de Johnny (src/granada.js). Vuela en parábola, bota una vez, rueda un poco frenando, rebota en
# las paredes y los muebles, parpadea en rojo (cada vez más deprisa) y a los 2 s explota: la explosión de
# siempre (explosion.gd), que también hace daño a Johnny, y una mancha chamuscada en el suelo.
# La atraedora y la congeladora (antes, arrojadizas creadas del banco) son esta misma granada con otro "tipo"
# (Lanzables.ARROJADIZAS): su mecha, su dibujo propio (DIBUJOS_PROPIOS) y lo suyo al explotar. A Johnny le hacen
# como mucho 25:
#   atraedora    mientras suena, los zombis cercanos van hacia ella (grupo "cebos", zombi.gd)
#   congeladora  los zombis que pilla se quedan quietos y azules 3 s (la portera, no)
# (La lluvia ácida, la mina despertador, la nube somnífera y la bomba de clavos se quitaron del juego el 25 oct.)
# La Épica, al explotar, suelta granaditas de su tipo que explotan enseguida alrededor (el racimo: Armas.TRUCO)
extends Node2D

const EXPLOSION := preload("res://escenas/armas/explosion.tscn")
const DIBUJO := preload("res://assets/sprites/objeto-granada.png")
# La atraedora (un haz de dinamita con despertador) y la congeladora (un extintor con temporizador): su icono de PixelLab,
# el mismo del inventario, gira en el aire
const DIBUJOS_PROPIOS := {"atraedora": preload("res://assets/ui/iconos/atraedora.png"),
	"congeladora": preload("res://assets/ui/iconos/congeladora.png")}
const G := Lanzables.GRANADA
const HIJA_MECHA := 0.7   # lo que tardan en explotar las granaditas del racimo

var desde := Vector2.ZERO
var hasta := Vector2.ZERO
var radio := 110.0
var dano_zombis := 80
var tipo := "granada"
var fabricante := false
var congela_extra := 0.0   # la congeladora: segundos de más que los deja quietos (talento Criogenia)
var z := 20.0          # altura sobre el suelo
var v := Vector2.ZERO  # velocidad en el suelo
var vz := 0.0          # velocidad hacia arriba
var mecha := 2.0
var parpadeo := 0.0
var boto := false
var giro := 0.0
var racimo := 0        # la Épica: cuántas granaditas suelta al explotar (Armas.TRUCO)
var hija := false      # es una de esas granaditas: mecha corta, y a Johnny le hace menos


func _ready() -> void:
	global_position = desde
	var vuelo: float = G.vuelo
	v = (hasta - desde) / vuelo
	vz = (G.gravedad * vuelo * vuelo / 2.0 - z) / vuelo
	mecha = G.mecha
	if tipo != "granada":
		mecha = Lanzables.ARROJADIZAS[tipo].mecha
		if tipo == "atraedora":
			add_to_group("cebos")
	if hija:
		mecha = HIJA_MECHA


func _physics_process(delta: float) -> void:
	mecha -= delta
	if z > 0.0 or vz > 0.0:
		# en el aire: parábola, dando vueltas
		vz -= G.gravedad * delta
		z += vz * delta
		giro += delta * 14.0
		if z <= 0.0:
			z = 0.0
			if not boto:
				boto = true
				vz = -vz * G.bote
				v *= G.rebote
			else:
				vz = 0.0
	else:
		v *= exp(-delta * G.roce)   # en el suelo rueda y se frena
	# cerca del suelo choca con paredes y muebles (capa 1) y rebota
	var paso := v * delta
	if z < 12.0 and paso.length() > 0.01:
		var rayo := PhysicsRayQueryParameters2D.create(global_position, global_position + paso * 1.5, 1)
		var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
		if not choque.is_empty():
			v = v.bounce(choque.normal) * 0.5
			paso = Vector2.ZERO
	global_position += paso
	# parpadeo rojo: de uno cada 0,4 s a casi continuo al final
	var k := clampf(1.0 - mecha / (G.mecha if tipo == "granada" else Lanzables.ARROJADIZAS[tipo].mecha), 0.0, 1.0)
	if tipo == "atraedora" and randf() < 8.0 * delta:
		# suena: notas que salen hacia arriba
		Particulas.soltar(self, global_position + Vector2(randf_range(-8, 8), -z - 20), Vector2(randf_range(-30, 30), -70),
			Lanzables.ARROJADIZAS.atraedora.color, 3, 0.5)
	var antes := floori(parpadeo)
	parpadeo += delta / (0.4 - 0.33 * k * k)
	if floori(parpadeo) != antes and floori(parpadeo) % 2 == 1:
		Sonido.tocar("pitido")   # pita cada vez que se enciende en rojo
	queue_redraw()
	if mecha <= 0.0:
		explotar()


# ¡Boom! La explosión de siempre (con Puntería, más daño a los zombis). A Johnny, como mucho DANO_JOHNNY (25), como
# la atraedora y la congeladora: hasta el 27 oct su propia granada le quitaba 80, casi toda la vida y dos tercios
func explotar() -> void:
	var boom := EXPLOSION.instantiate()
	boom.radio = radio
	boom.dano = mini(dano_zombis, Lanzables.DANO_JOHNNY)
	boom.dano_zombis = dano_zombis
	boom.position = position
	if tipo != "granada":
		efecto_creada(Lanzables.ARROJADIZAS[tipo])
	if hija:
		boom.dano = roundi(boom.dano * Armas.TRUCO.racimo_tamano)
	get_parent().add_child(boom)
	Mancha.quemado(get_parent(), position, radio * 0.5)
	if racimo > 0:
		soltar_racimo()
	queue_free()


# El racimo de la Épica: "racimo" granaditas de su tipo que saltan repartidas alrededor y explotan enseguida, con
# Armas.TRUCO.racimo_tamano su radio y su daño (ellas, sin racimo)
func soltar_racimo() -> void:
	var giro_racimo := randf() * TAU
	for i in racimo:
		var g: Node2D = get_script().new()
		g.tipo = tipo
		g.desde = global_position
		g.hasta = global_position + Vector2.from_angle(giro_racimo + TAU * i / racimo) * Vector2(1.0, 0.7) * radio * 0.8
		g.radio = radio * Armas.TRUCO.racimo_tamano
		g.dano_zombis = roundi(dano_zombis * Armas.TRUCO.racimo_tamano)
		g.fabricante = fabricante
		g.congela_extra = congela_extra
		g.hija = true
		get_parent().add_child.call_deferred(g)


# Lo suyo de cada arrojadiza creada al explotar, y dos anillos de su color para que se note cuál ha sido
func efecto_creada(c: Dictionary) -> void:
	if c.has("congela"):
		var congela: float = c.congela + congela_extra
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi is Zombi and zombi.global_position.distance_to(global_position) <= radio + zombi.radio:
				zombi.aturdido = maxf(zombi.aturdido, congela)
				zombi.modulate = Color(0.55, 0.8, 1.0)
				zombi.create_tween().tween_property(zombi, "modulate", Color.WHITE, 0.4).set_delay(congela - 0.4)
	for i in 2:
		Particulas.anillo(self, global_position, radio * (0.6 + i * 0.4), c.color, 0.4 + i * 0.15)


func _draw() -> void:
	# la sombra en el suelo (más pequeña cuanto más alta)
	var s := 1.0 - minf(0.5, z / 200.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 7.0 * s, Color(0.08, 0.06, 0.16, 0.3))
	# el dibujo del dueño (19×27) a 0,8: unas 15×22 unidades. En el aire gira; en el suelo, derecha
	var rojo := int(parpadeo) % 2 == 1
	draw_set_transform(Vector2(0, -z - 8.0), giro if z > 0.0 else 0.0, Vector2(0.8, 0.8))
	if DIBUJOS_PROPIOS.has(tipo):
		# su propio dibujo, sin teñir (son rojos: al parpadear se oscurecen un poco, como el pitido)
		var propio: Texture2D = DIBUJOS_PROPIOS[tipo]
		draw_texture(propio, -propio.get_size() / 2.0, Color(1.0, 0.55, 0.5) if rojo else Color.WHITE)
		return
	draw_texture(DIBUJO, -Vector2(9.5, 16.0), Color(1.0, 0.35, 0.3) if rojo else Color.WHITE)
