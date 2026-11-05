# Una fotocopia del becario (becario.gd, su ataque «¡A COPIAR!»): el mismo dibujo, pero sin sombra y un pelín más clara,
# como recién salida de la máquina. Va a por Johnny como él, muere de un golpe (se deshace en hojas de papel) y no hace
# daño; con el becario enfadado, sí: CONTACTO al tocarle. Lo que le pega no le quita vida al de verdad. Si el becario
# muere, se deshacen todas con él.
# Es un minijefe más (minijefe.gd: moverse, recibir golpes, estar en el grupo "zombis"), pero sin barra, sin premio y
# sin contar como zombi muerto: la saca el becario directamente, no la partida.
extends Minijefe

const VELOCIDAD := 115.0
const CONTACTO := 5
const TINTE := Color(1.15, 1.15, 1.2)

var jefe: Node2D


func _ready() -> void:
	super()
	vapor = false
	sprite.modulate = TINTE if jefe == null or not jefe.enfadado() else TINTE * Color(1.0, 0.8, 0.78)
	# (con un poco de retraso cada una: que no anden todas a la vez como un solo muñeco)
	dur = randf_range(0.0, 0.3)


func pensar(delta: float, johnny: Node2D) -> void:
	if not is_instance_valid(jefe) or jefe.estado == "muerto":
		deshacer()
		return
	contacto = CONTACTO if jefe.enfadado() else 0
	if t < dur:
		frenar(delta)
		return
	mirada = global_position.direction_to(johnny.global_position)
	perseguir(delta, johnny, VELOCIDAD)


# Un golpe, una bala, una explosión o el fuego: se deshace
func recibir_golpe(_cantidad: int, _fuerza: Vector2, _de_lleno := false, _de_aliado := false) -> void:
	deshacer()


func morder(_cantidad: int) -> void:
	deshacer()


func deshacer() -> void:
	if estado == "muerto":
		return
	estado = "muerto"
	remove_from_group("zombis")
	Sonido.tocar("papeles")
	for i in 14:
		var a := randf() * TAU
		Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-14, 14), randf_range(-70, 10)),
			Vector2(cos(a) * randf_range(40, 150), sin(a) * randf_range(30, 110) - 60.0),
			Color("#f4f6f8") if i % 3 else Color("#d9dde3"), randf_range(3, 6), randf_range(0.5, 0.9))
	queue_free()


func animar() -> void:
	sprite.position = Vector2(0, 30)
	var dir := direccion()
	if marcha.length() > 8.0:
		poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.5, 1.8))
	else:
		poner("reposo_" + dir)
