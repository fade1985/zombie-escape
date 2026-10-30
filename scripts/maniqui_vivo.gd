# Un maniquí del Taller de costura que ha cobrado vida (cuando la modista se enfada: modista.gd). Tiene el dibujo
# del mueble y solo se mueve cuando Johnny no lo mira: si Johnny lo tiene delante (hacia donde mira y sin nada en
# medio), se queda quieto como un mueble más; en cuanto le da la espalda, se le acerca deprisa, bamboleándose
# sobre su peana, y si le toca le hace daño. Se rompe a golpes, y cuando cae la modista se caen todos.
# Está en el grupo "zombis" (con radio, vida y recibir_golpe): las balas, los golpes y las explosiones le dan.
extends CharacterBody2D

signal murio

const DIBUJO := preload("res://assets/sprites/mueble-tallmannequin.png")
const VELOCIDAD := 165.0
const DANO := 10
const VISTA := 0.95        # medio ángulo de lo que ve Johnny por delante: si está dentro, lo está mirando
const LEJOS := 900.0       # más lejos que esto, Johnny ya no lo ve
const DESPERTAR := 0.7     # lo que tarda en cobrar vida (tiembla)
const PIE := 12.0          # sus pies, por debajo de su centro

var radio := 18.0
var vida := 45
var vida_max := 45
var estado := "despertar"  # despertar, quieto, andar o muerto
var t := 0.0
var sprite: Sprite2D
var agente: NavigationAgent2D


func _ready() -> void:
	collision_mask |= Planta.CAPA_BORDE   # el borde del helipuerto de la azotea (planta.gd): andando, no se cruza
	add_to_group("zombis")
	collision_layer = 4    # como los zombis: choca con paredes y muebles, y no tapa la vista
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var choque := CollisionShape2D.new()
	choque.name = "Choque"
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	choque.shape = circulo
	add_child(choque)
	sprite = Sprite2D.new()
	sprite.texture = DIBUJO
	sprite.scale = Vector2(2, 2)
	sprite.centered = false
	sprite.offset = Vector2(-floorf(DIBUJO.get_width() / 2.0), -DIBUJO.get_height())
	sprite.position = Vector2(0, PIE)   # gira sobre sus pies (la peana)
	add_child(sprite)
	agente = NavigationAgent2D.new()
	agente.radius = 18.0
	agente.path_desired_distance = 16.0
	agente.target_desired_distance = 16.0
	add_child(agente)


func _physics_process(delta: float) -> void:
	if estado == "muerto":
		return
	t += delta
	if estado == "despertar":
		sprite.position.x = sin(t * 60.0) * 2.0
		if t >= DESPERTAR:
			estado = "quieto"
			sprite.position.x = 0.0
		return
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo or lo_mira(johnny):
		# quieto como un mueble (y tal como se haya quedado, un poco torcido)
		estado = "quieto"
		return
	estado = "andar"
	agente.target_position = johnny.global_position
	velocity = global_position.direction_to(agente.get_next_path_position()) * VELOCIDAD
	move_and_slide()
	sprite.rotation = sin(t * 16.0) * 0.12
	if global_position.distance_to(johnny.global_position) < radio + johnny.RADIO + 4.0:
		johnny.recibir_dano(DANO, self)


# ¿Lo está mirando Johnny? (lo tiene por delante, no muy lejos y sin nada en medio)
func lo_mira(johnny: Node2D) -> bool:
	var hacia: Vector2 = global_position - johnny.global_position
	if hacia.length() > LEJOS:
		return false
	var vista := Vector2.from_angle(johnny.DIRS.find(johnny.direccion) * PI / 4.0)
	if absf(vista.angle_to(hacia)) > VISTA:
		return false
	return johnny.se_ve(self)


func recibir_golpe(cantidad: int, fuerza: Vector2, _de_lleno := false) -> void:
	if estado == "muerto":
		return
	cantidad = ArmasCreadas.con_acido(self, cantidad)   # (con ácido, le quita más)
	vida = maxi(vida - cantidad, 0)
	Zombi.numero_golpe(get_parent(), global_position + Vector2(randf_range(-20, 0), -130), cantidad)
	Sonido.tocar("golpe")
	# saltan trocitos de plástico
	for i in 3:
		var v := (fuerza.normalized() if fuerza != Vector2.ZERO else Vector2.UP) * 90.0
		Particulas.soltar(self, global_position + Vector2(randf_range(-10, 10), -randf_range(30, 110)),
			v.rotated(randf_range(-0.8, 0.8)), Color("#e8dcc4"), 3, 0.4)
	if vida <= 0:
		morir()


# Daño sin golpe (el fuego del molotov)
func herir(cantidad: float, _color := Color.WHITE) -> void:
	recibir_golpe(maxi(1, roundi(cantidad)), Vector2.ZERO)


# Se cae al suelo, roto, y se queda ahí
func morir() -> void:
	if estado == "muerto":
		return
	estado = "muerto"
	remove_from_group("zombis")
	$Choque.set_deferred("disabled", true)
	z_index = -1
	Sonido.tocar("portazo")
	sprite.position.x = 0.0
	var lado := 1.0 if randf() < 0.5 else -1.0
	create_tween().tween_property(sprite, "rotation", PI / 2.0 * lado, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# tendido, su dibujo queda a ese lado de los pies
	var largo := DIBUJO.get_height() * 2.0
	var ancho := DIBUJO.get_width() * 2.0
	Cuerpo.resbalar(self, Rect2(global_position + sprite.position + Vector2(minf(lado, 0.0) * largo, -ancho / 2.0), Vector2(largo, ancho)), 0.35)
	murio.emit()
