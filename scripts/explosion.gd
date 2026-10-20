# Una explosión (la del zombi explosivo y la granada). Al aparecer hace daño a Johnny y a los
# zombis que pillen dentro del círculo (¡reacciones en cadena!), enseña la bola de fuego y se va.
# Como en el juego (explode en src/game-ataques.js).
extends Node2D

const EMPUJE := 170.0 * 2.2   # las explosiones lanzan a los zombis más lejos que un golpe

var radio := 90.0
var dano := 30
var dano_zombis := -1     # si es distinto (la granada con Puntería les hace más a ellos): -1 = el mismo
var origen: Node = null       # quien ha reventado (no se hace daño a sí mismo)
var tiempo := 0.0


func _ready() -> void:
	Sonido.tocar("explosion")
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) <= radio + johnny.RADIO:
		johnny.recibir_dano(dano)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi == origen:
			continue
		var hacia: Vector2 = zombi.global_position - global_position
		if hacia.length() <= radio + zombi.radio:
			zombi.recibir_golpe(dano if dano_zombis < 0 else dano_zombis, hacia.normalized() * EMPUJE)
	# La explosión ilumina toda la zona, y el resplandor del fuego tarda en apagarse
	Luz.destello(self, global_position, maxf(200.0, radio * 2.5), 0.4)
	Luz.destello(self, global_position, maxf(160.0, radio * 1.8), 1.2, 0.5)
	# La bola de fuego de PixelLab, un poco más grande que su dibujo (como en el juego)
	$Fuego.play("reposo_s")


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()
	# 12 fotogramas a 14 por segundo: algo menos de un segundo
	if tiempo > 0.85:
		queue_free()


# Un destello redondo que se abre y se apaga enseguida, por debajo de la bola de fuego
func _draw() -> void:
	var k := minf(tiempo / 0.3, 1.0)
	if k < 1.0:
		draw_circle(Vector2.ZERO, radio * (0.4 + 0.6 * k), Color(1, 0.82, 0.25, 0.45 * (1.0 - k)))
