# La granada de Johnny (src/granada.js). Vuela en parábola, bota una vez, rueda un poco frenando, rebota en
# las paredes y los muebles, parpadea en rojo (cada vez más deprisa) y a los 2 s explota: la explosión de
# siempre (explosion.gd), que también hace daño a Johnny, y una mancha chamuscada en el suelo.
extends Node2D

const EXPLOSION := preload("res://escenas/armas/explosion.tscn")
const DIBUJO := preload("res://assets/sprites/objeto-granada.png")
const G := Lanzables.GRANADA

var desde := Vector2.ZERO
var hasta := Vector2.ZERO
var radio := 110.0
var dano_zombis := 80
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
	var k := clampf(1.0 - mecha / G.mecha, 0.0, 1.0)
	parpadeo += delta / (0.4 - 0.33 * k * k)
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
	get_parent().add_child(boom)
	Mancha.quemado(get_parent(), position, radio * 0.5)
	queue_free()


func _draw() -> void:
	# la sombra en el suelo (más pequeña cuanto más alta)
	var s := 1.0 - minf(0.5, z / 200.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 7.0 * s, Color(0.08, 0.06, 0.16, 0.3))
	# el dibujo del dueño (19×27) a 0,8: unas 15×22 unidades. En el aire gira; en el suelo, derecha
	var rojo := int(parpadeo) % 2 == 1
	draw_set_transform(Vector2(0, -z - 8.0), giro if z > 0.0 else 0.0, Vector2(0.8, 0.8))
	draw_texture(DIBUJO, -Vector2(9.5, 16.0), Color(1.0, 0.35, 0.3) if rojo else Color.WHITE)
