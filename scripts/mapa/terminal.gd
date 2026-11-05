# Un ordenador encendido de Torre Velaria (el cerrojo "codigo": edificios.gd y Planta.codigo): una mesita con su
# pantalla, que brilla verde en la oscuridad para que se encuentre. Plantándose delante, Johnny lee en ella una de las
# tres cifras del código de la sala del jefe; al leerla salta el «control de productividad» (lo hace la partida: se
# despiertan los zombis del departamento). Leído, enseña su cifra en grande y ya no hace nada más.
# Se dibuja con código, a píxeles de 2 unidades; el nodo va en el suelo, en "cosas", como el científico muerto.
extends Node2D

signal leido

const CERCA := 56.0               # a cuánto hay que plantarse para leerlo
const VERDE := Color("#58ff8a")

var datos: Dictionary             # {sitio, sala, pos, leido, cifra} (Planta.codigo)
var mapa: Node
var johnny: Node
var brillo: PointLight2D
var t := 0.0


func montar(d: Dictionary, m: Node, j: Node) -> void:
	datos = d
	mapa = m
	johnny = j
	name = "Terminal"   # no-tr (nombre de nodo)
	position = d.pos
	brillo = PointLight2D.new()
	brillo.texture = preload("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.8
	brillo.color = VERDE
	brillo.position = Vector2(0, -50)
	add_child(brillo)


func _physics_process(delta: float) -> void:
	t += delta
	# como el cuadro eléctrico: en una habitación aún sin descubrir se oscurece y su brillo se apaga
	var oscuro: float = mapa.niebla.get(datos.sala, 0.0)
	modulate = Color.WHITE.lerp(Color(0.07, 0.063, 0.11), 0.9 * oscuro)
	brillo.enabled = oscuro < 0.98
	brillo.energy = (0.7 + sin(t * 3.0) * 0.15) * (1.0 - oscuro)
	queue_redraw()
	if datos.leido or johnny == null or not johnny.vivo:
		return
	if johnny.global_position.distance_to(global_position + Vector2(0, 20)) < CERCA:
		datos.leido = true
		Sonido.tocar("pitido")
		for i in 10:
			Particulas.soltar(self, global_position + Vector2(0, -34), Vector2(randf_range(-60, 60), randf_range(-90, -10)),
				VERDE if i % 2 else Color.WHITE, 2, 0.35)
		leido.emit()


# Un rectángulo en píxeles del dibujo (cada uno, 2 unidades), contando desde la esquina de arriba a la izquierda del
# dibujo (36 × 38 píxeles, con el pie en el suelo: una mesa de oficina con su ordenador, del tamaño de un zombi)
func px(x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x * 2 - 36, y * 2 - 70), Vector2(w * 2, h * 2)), color)


func _draw() -> void:
	# la sombra
	draw_rect(Rect2(-34, 0, 68, 8), Color(0, 0, 0, 0.3))
	# la mesa: tablero gris claro con su canto y dos patas
	px(0, 18, 36, 6, Color("#2a2b30"))
	px(1, 18, 34, 3, Color("#c9cdd4"))
	px(1, 21, 34, 2, Color("#8a8f98"))
	px(2, 24, 3, 14, Color("#3b3e45"))
	px(31, 24, 3, 14, Color("#3b3e45"))
	# la pantalla, encima de la mesa: marco negro, cristal y su pie
	px(7, 0, 22, 16, Color("#1b1c20"))
	px(8, 1, 20, 13, Color("#0c2a16") if not datos.leido else Color("#0e3a1d"))
	px(16, 16, 4, 2, Color("#1b1c20"))
	# el teclado
	px(9, 19, 18, 2, Color("#4a4e57"))
	if datos.leido:
		# la cifra, en grande
		var fuente := ThemeDB.fallback_font
		draw_string(fuente, Vector2(-8, -38), str(datos.cifra), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, VERDE)
	else:
		# rayas de texto que parpadean, y el cursor
		for i in 4:
			px(10, 3 + i * 2, 4 + (i * 3 + int(t * 2.0)) % 12, 1, Color(VERDE, 0.8))
		if sin(t * 6.0) > 0.0:
			px(23, 11, 3, 1, VERDE)
