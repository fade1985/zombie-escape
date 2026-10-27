# Un billete de dólar en el suelo (los "cash" de src/game-combate.js). Sale despedido del zombi que lo suelta,
# frena, y cuando Johnny pasa cerca (su "iman") vuela hacia él y se lo queda. Los dólares de la partida no se
# guardan hasta completar el edificio: si te matan, se pierden.
# También sirve para los molotovs y granadas que sueltan los zombis (fase 7a): otro "icono" y "puede", que
# dice si cabe en la mochila (si no cabe, se queda en el suelo). Y para los objetos y las armas de la fase 7b:
# lo que Johnny tira desde el inventario ("tirado") no sale despedido ni vuelve solo hasta que él se aparta.
# La munición (y la gasolina y el ácido) lleva "a_oscuras": se ve un poco aunque la sala esté a oscuras. Y la caja de
# munición, "que_icono": su dibujo cambia con el arma que lleva Johnny.
extends Node2D

signal cogido

const ICONO := preload("res://assets/ui/iconos/billete.png")
const A_OSCURAS := preload("res://escenas/luces/suelo_a_oscuras.gdshader")

var johnny: Node2D
var icono: Texture2D = ICONO
var tamano := 0.75
var puede := func() -> bool: return true
var al_no_caber := Callable()   # si lo hay, se llama al pisarlo sin que quepa (una vez cada vez que se pisa: el tope de curas)
var pisado := false
var tirado := false
var salida := Vector2.ZERO    # si no es cero, hacia dónde sale despedido (en vez de a un lado al azar)
var a_oscuras := false
var que_icono := Callable()   # si lo hay, el dibujo que toca ahora (a 32 unidades de ancho, como los objetos)
var velocidad := Vector2.ZERO
var t := 0.0
var dibujo: Sprite2D
var brillo: Sprite2D   # la copia del dibujo que se ve a oscuras (solo con "a_oscuras")


func _ready() -> void:
	dibujo = Sprite2D.new()
	dibujo.texture = icono
	dibujo.scale = Vector2(tamano, tamano)
	dibujo.offset = Vector2(0, -10)
	add_child(dibujo)
	if a_oscuras:
		# encima del dibujo, una copia que no oscurece la penumbra (escenas/luces/suelo_a_oscuras.gdshader)
		brillo = Sprite2D.new()
		brillo.texture = icono
		brillo.offset = dibujo.offset
		brillo.material = ShaderMaterial.new()
		brillo.material.shader = A_OSCURAS
		dibujo.add_child(brillo)
	# Sale despedido hacia un lado al azar
	if not tirado:
		velocidad = salida if salida != Vector2.ZERO else Vector2.from_angle(randf() * TAU) * randf_range(80.0, 200.0)


func _physics_process(delta: float) -> void:
	t += delta
	velocidad *= exp(-delta * 5.0)
	if que_icono.is_valid():
		var nuevo: Texture2D = que_icono.call()
		if nuevo != icono:
			icono = nuevo
			dibujo.texture = nuevo
			dibujo.scale = Vector2.ONE * 32.0 / nuevo.get_width()
			if brillo:
				brillo.texture = nuevo
	# Flota un poco arriba y abajo
	dibujo.position.y = sin(t * 4.0) * 2.0
	if johnny and johnny.vivo and puede.call():
		var hacia: Vector2 = johnny.global_position - global_position
		var d := hacia.length()
		if tirado:
			tirado = d < johnny.stats.iman + 30.0   # hasta que se aparte
			position += velocidad * delta
			return
		if t > 0.4 and d < johnny.stats.iman:
			velocidad += hacia / maxf(d, 1.0) * 2200.0 * delta
			velocidad = velocidad.limit_length(650.0)
		if t > 0.25 and d < johnny.RADIO + 12.0:
			cogido.emit()
			queue_free()
			return
	elif johnny and johnny.vivo and al_no_caber.is_valid():
		var encima: bool = global_position.distance_to(johnny.global_position) < johnny.RADIO + 12.0
		if encima and not pisado:
			al_no_caber.call()
		pisado = encima
	position += velocidad * delta
