# La valla del helipuerto de la azotea (la pone mapa.gd, poner_helipuerto): en lo alto de la rampa, metida en el suelo
# hasta que Johnny sube a la plataforma; entonces sale y cierra el ring hasta que cae el jefe (partida.gd, mirar_ring).
# Es una barrera de franjas rojas y blancas (las del borde son amarillas y negras), vista desde arriba como los muros
# de los lados (lo de arriba y la cara del extremo de abajo), con una luz roja que parpadea mientras está cerrada.
# Cerrada choca como el borde de la plataforma (capa Planta.CAPA_BORDE: para a los que andan, no a las balas) y la
# navegación la recorta.
extends Node2D

const ALTO := 52.0          # lo que sube, en unidades
const SUBE := 0.3           # lo que tarda en salir (y en meterse)
const GROSOR := 16.0        # lo que se ve de ancha (el doble que el borde que cierra: así no se confunde con él)
const ROJO := Color("#c8342c")
const BLANCO := Color("#e6e2d8")
const CANTO := Color("#1c1c20")
const CARA := Color("#5a5c62")
const ROJA := Color("#ff4038")

var hueco: Rect2            # lo que cierra: la boca de la rampa sobre el borde de la plataforma, en unidades
var mapa: Node
var cerrada := false
var subida := 0.0           # 0: metida en el suelo; 1: arriba del todo
var cuerpo: StaticBody2D = null
var t := 0.0


func montar(rect: Rect2, m: Node) -> void:
	name = "Valla"
	hueco = rect
	mapa = m
	position = rect.get_center()   # (en "cosas" se ordena por la y: por la mitad de su largo)


func cerrar() -> void:
	if cerrada:
		return
	cerrada = true
	cuerpo = StaticBody2D.new()
	cuerpo.collision_layer = Planta.CAPA_BORDE
	cuerpo.collision_mask = 0
	cuerpo.add_to_group("obstaculos")
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = hueco.size
	forma.shape = caja
	cuerpo.add_child(forma)
	add_child(cuerpo)
	mapa.rehornear()
	Sonido.tocar("portazo")


func abrir() -> void:
	if not cerrada:
		return
	cerrada = false
	remove_child(cuerpo)   # (antes de rehornear: si no, aún contaría)
	cuerpo.queue_free()
	cuerpo = null
	mapa.rehornear()
	Sonido.tocar("puerta")


func _process(delta: float) -> void:
	t += delta
	var antes := subida
	subida = move_toward(subida, 1.0 if cerrada else 0.0, delta / SUBE)
	if subida != antes or cerrada:
		queue_redraw()


func _draw() -> void:
	if subida <= 0.0:
		return
	var alto := roundf(ALTO * ease(subida, 0.5) / 2.0) * 2.0
	var x := -GROSOR / 2.0
	var y0 := -hueco.size.y / 2.0
	var y1 := hueco.size.y / 2.0
	# la cara del extremo de abajo (la que mira a la pantalla), más oscura hacia el suelo
	for i in int(alto / 2.0):
		draw_rect(Rect2(x, y1 - alto + i * 2.0, GROSOR, 2.0), CARA.darkened(0.4 * i * 2.0 / maxf(alto, 2.0)))
	# lo de arriba: franjas en diagonal, con el canto oscuro
	var arriba := Rect2(x, y0 - alto, GROSOR, y1 - y0)
	for j in int(arriba.size.y / 2.0):
		for i in int(GROSOR / 2.0):
			var franja := int((i + j) / 3.0) % 2 == 0
			draw_rect(Rect2(arriba.position + Vector2(i, j) * 2.0, Vector2(2, 2)), ROJO if franja else BLANCO)
	draw_rect(arriba, CANTO, false, 2.0)
	# la luz roja de lo alto, en el extremo de arriba: parpadea mientras está cerrada
	if cerrada and subida >= 1.0:
		var encendida := fmod(t, 0.8) < 0.45
		draw_rect(Rect2(-2, y0 - alto - 2, 4, 4), ROJA if encendida else ROJA.darkened(0.6))
