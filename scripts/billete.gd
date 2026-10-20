# Un billete de dólar en el suelo (los "cash" de src/game-combate.js). Sale despedido del zombi que lo suelta,
# frena, y cuando Johnny pasa cerca (su "iman") vuela hacia él y se lo queda. Los dólares de la partida no se
# guardan hasta completar el edificio: si te matan, se pierden.
# También sirve para los molotovs y granadas que sueltan los zombis (fase 7a): otro "icono" y "puede", que
# dice si cabe en la mochila (si no cabe, se queda en el suelo).
extends Node2D

signal cogido

const ICONO := preload("res://assets/ui/iconos/billete.png")

var johnny: Node2D
var icono: Texture2D = ICONO
var tamano := 0.75
var puede := func() -> bool: return true
var velocidad := Vector2.ZERO
var t := 0.0


func _ready() -> void:
	var dibujo := Sprite2D.new()
	dibujo.texture = icono
	dibujo.scale = Vector2(tamano, tamano)
	dibujo.offset = Vector2(0, -10)
	add_child(dibujo)
	# Sale despedido hacia un lado al azar
	velocidad = Vector2.from_angle(randf() * TAU) * randf_range(80.0, 200.0)


func _physics_process(delta: float) -> void:
	t += delta
	velocidad *= exp(-delta * 5.0)
	# Flota un poco arriba y abajo
	get_child(0).position.y = sin(t * 4.0) * 2.0
	if johnny and johnny.vivo and puede.call():
		var hacia: Vector2 = johnny.global_position - global_position
		var d := hacia.length()
		if t > 0.4 and d < johnny.stats.iman:
			velocidad += hacia / maxf(d, 1.0) * 2200.0 * delta
			velocidad = velocidad.limit_length(650.0)
		if t > 0.25 and d < johnny.RADIO + 12.0:
			cogido.emit()
			queue_free()
			return
	position += velocidad * delta
