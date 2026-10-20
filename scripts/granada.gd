# La granada de Johnny (src/granada.js). Vuela en parábola, bota una vez, rueda un poco frenando, rebota en
# las paredes y los muebles, parpadea en rojo (cada vez más deprisa) y a los 2 s explota: la explosión de
# siempre (explosion.gd), que también hace daño a Johnny, y una mancha chamuscada en el suelo.
# Las arrojadizas creadas (fase 7b2) son esta misma granada con otro "tipo" (Lanzables.ARROJADIZAS): su mecha,
# su color (el dibujo de la granada, teñido) y lo suyo al explotar. A Johnny le hacen como mucho 25:
#   atraedora    mientras suena, los zombis cercanos van hacia ella (grupo "cebos", zombi.gd)
#   congeladora  los zombis que pilla se quedan quietos y azules 3 s (la portera, no)
#   lluvia_acida deja un charco de ácido grande que solo daña a los zombis
extends Node2D

const EXPLOSION := preload("res://escenas/armas/explosion.tscn")
const DIBUJO := preload("res://assets/sprites/objeto-granada.png")
const G := Lanzables.GRANADA

var desde := Vector2.ZERO
var hasta := Vector2.ZERO
var radio := 110.0
var dano_zombis := 80
var tipo := "granada"
var fabricante := false
var z := 20.0          # altura sobre el suelo
var v := Vector2.ZERO  # velocidad en el suelo
var vz := 0.0          # velocidad hacia arriba
var mecha := 2.0
var parpadeo := 0.0
var boto := false
var giro := 0.0


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


# ¡Boom! La explosión de siempre (con Puntería, más daño a los zombis; a Johnny le hace lo de siempre)
func explotar() -> void:
	var boom := EXPLOSION.instantiate()
	boom.radio = radio
	boom.dano = G.dano
	boom.dano_zombis = dano_zombis
	boom.position = position
	if tipo != "granada":
		boom.dano = mini(dano_zombis, Lanzables.DANO_JOHNNY)   # a Johnny, como mucho 25
		efecto_creada(Lanzables.ARROJADIZAS[tipo])
	get_parent().add_child(boom)
	Mancha.quemado(get_parent(), position, radio * 0.5)
	queue_free()


# Lo suyo de cada arrojadiza creada al explotar, y dos anillos de su color para que se note cuál ha sido
func efecto_creada(c: Dictionary) -> void:
	if c.has("congela"):
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi is Zombi and zombi.global_position.distance_to(global_position) <= radio + zombi.radio:
				zombi.aturdido = maxf(zombi.aturdido, c.congela)
				zombi.modulate = Color(0.55, 0.8, 1.0)
				zombi.create_tween().tween_property(zombi, "modulate", Color.WHITE, 0.4).set_delay(c.congela - 0.4)
	if c.has("charco"):
		var charco := preload("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = "lluvia"
		charco.escala = Lanzables.FABRICANTE.radio if fabricante else 1.0
		charco.position = (position / 2.0).round() * 2.0
		get_parent().add_child(charco)
		for i in 12:
			var a := randf() * TAU
			Particulas.soltar(self, global_position + Vector2(0, -10), Vector2(cos(a), sin(a) * 0.6) * randf_range(60, 200) - Vector2(0, 50),
				c.color, 3, 0.45)
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
	var tinte: Color = Color.WHITE if tipo == "granada" else Lanzables.ARROJADIZAS[tipo].color
	draw_texture(DIBUJO, -Vector2(9.5, 16.0), Color(1.0, 0.35, 0.3) if rojo else tinte)
