# Un charco en el suelo (el moco verde del venenoso o la lejía de la portera): mientras Johnny lo pisa, le va
# quitando vida poco a poco, y al rato se seca. De momento es la versión sencilla: lo de seguir envenenado
# al salir y resbalar con la lejía llegará en la fase 7, con el molotov (src/estados.js en el juego).
extends Node2D

# Cada tipo: su dibujo, su tamaño (radio), cuánto dura, el daño por segundo al pisarlo y de qué color se pone
# Johnny mientras lo pisa
const TIPOS := {
	"veneno": {"dibujo": preload("res://assets/sprites/objeto-charco-veneno.png"), "radio": 64.0,
		"vida": 4.0, "dps": 4.0, "color": Color(0.6, 1.0, 0.45)},
	"lejia": {"dibujo": preload("res://assets/sprites/objeto-charco-lejia.png"), "radio": 54.0,
		"vida": 5.0, "dps": 3.0, "color": Color(0.7, 0.9, 1.0)},
}

var tipo := "veneno"
var vida := 0.0


func _ready() -> void:
	vida = TIPOS[tipo].vida
	z_index = -1   # en el suelo: por debajo de todos


func radio() -> float:
	return TIPOS[tipo].radio


func _physics_process(delta: float) -> void:
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	# Al final se va secando (más transparente)
	modulate.a = clampf(vida / 0.6, 0.0, 1.0)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position, johnny.RADIO * 0.3):
		johnny.pisar_charco(TIPOS[tipo].dps * delta, TIPOS[tipo].color)


# El charco es una elipse (más ancha que alta, porque el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := radio() + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.55)) ** 2 <= 1.0


func _draw() -> void:
	var dibujo: Texture2D = TIPOS[tipo].dibujo
	# A escala 2, como todo el pixel art (estirarlo a su radio exacto deformaría los píxeles)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	draw_texture(dibujo, -Vector2(dibujo.get_size()) / 2.0)
