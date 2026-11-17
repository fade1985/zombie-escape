# Un neón dibujado colgado en la pared de arriba de la galería del centro comercial (17 nov): el casete, el radiocasete o
# el tocadiscos (de GPT: tools/neones_galeria.py). Hace de lámpara: da luz de sus colores al pasillo y, como los apliques de
# los Apartamentos, parpadea y falla de vez en cuando (la misma cuenta, lampara.gd). Cuando falla se ve el tubo apagado.
# Se ve aunque el pasillo esté a oscuras (no le afecta la penumbra). Lo pone mapa.gd (poner_neones_galeria); el nodo va en
# el pie del muro, para ordenarse con la cara de la pared.
# También los dos de la farmacia, que van en vez de sus escaparates (17 nov, el dueño: la cruz de LEDs y la botella; los pone
# mapa.poner_escaparates): esos fallan menos, de vez en cuando, y al fallar (y sueltos, cada pocos segundos) sueltan
# chispas (chispas_neon.gd), como el letrero del súper.
extends Node2D

const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const CHISPAS := preload("res://scripts/mapa/chispas_neon.gd")
const MEDIO := 50.0   # a qué altura va su centro, por encima del pie del muro (la pared mide 96)
const CHISPAS_CADA := Vector2(2.5, 6.0)   # cada cuánto saltan sueltas, en segundos (entre uno y otro)
const CHISPAS_OIDO := 360.0               # hasta qué distancia de Johnny suenan

var nombre := "casete"
var color := Color("#c070ff")   # el de su luz
var semilla := 0.5
var medio := MEDIO              # a qué altura va su centro (los de la farmacia, más bajos: donde iba el escaparate)
var tramo := 0.0                # el de su lámpara (lampara.gd): 0, el de siempre; más largo, falla menos
var chispas_en := Vector2(-1, -1)   # el píxel del dibujo de donde saltan sus chispas (-1: sin chispas)
var encendido: Texture2D
var apagado: Texture2D
var luz: Node2D
var tiempo := 0.0
var chispas: CPUParticles2D
var proxima_chispa := 0.0
var desde_chispa := 99.0     # segundos desde el último chispazo (uno por apagón, aunque la luz dé varios guiños)
var antes_b := 1.0
var destello := 0.0          # el fogonazo de la chispa, lo que le queda
var dado := RandomNumberGenerator.new()


func _ready() -> void:
	encendido = load("res://assets/sprites/neon-%s.png" % nombre)
	apagado = load("res://assets/sprites/neon-%s-apagado.png" % nombre)
	tiempo = semilla * 10.0
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	# su luz de color en el suelo del pasillo, parpadeando (una lámpara sin bombilla ni polvo, como los letreros de neon.gd)
	luz = LAMPARA.instantiate()
	luz.parpadea = true
	luz.semilla = semilla
	luz.radio = 220.0
	luz.alto = medio
	luz.suelo = Vector2(0, 60)
	luz.fuerza = 0.9
	if tramo > 0.0:
		luz.tramo = tramo
	add_child(luz)
	luz.get_node("Bombilla").visible = false
	for n in ["LuzSuelo", "LuzCosas"]:   # no-tr (nombres de nodo)
		luz.get_node(n).color = color
	luz.get_node("Polvo").visible = false
	if chispas_en.x >= 0.0:
		dado.seed = int(semilla * 100000.0)
		proxima_chispa = dado.randf_range(CHISPAS_CADA.x, CHISPAS_CADA.y)
		chispas = CHISPAS.crear()
		chispas.position = rectangulo().position + chispas_en * 2.0 + Vector2(1, 1)
		add_child(chispas)


func _process(delta: float) -> void:
	tiempo += delta
	if chispas:
		# un chispazo al irse la luz y, sueltos, de vez en cuando
		var b: float = luz.brillo(tiempo)
		proxima_chispa -= delta
		desde_chispa += delta
		if (antes_b >= 0.5 and b < 0.5 and desde_chispa > 1.0) or proxima_chispa <= 0.0:
			chispazo()
		antes_b = b
		destello = maxf(destello - delta, 0.0)
	queue_redraw()


func chispazo() -> void:
	chispas.restart()
	destello = 0.1
	desde_chispa = 0.0
	proxima_chispa = dado.randf_range(CHISPAS_CADA.x, CHISPAS_CADA.y)
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and johnny.global_position.distance_to(chispas.global_position) < CHISPAS_OIDO:
		Sonido.tocar("chispa")


# Dónde va el dibujo (a 2 unidades por píxel, centrado y con su medio a "medio" del pie del muro)
func rectangulo() -> Rect2:
	var tam := encendido.get_size() * 2.0
	return Rect2(Vector2(-roundf(tam.x / 4.0) * 2.0, -medio - roundf(tam.y / 4.0) * 2.0), tam)


func _draw() -> void:
	var b: float = clampf(luz.brillo(tiempo) if luz else 1.0, 0.0, 1.0)
	var rect := rectangulo()
	var tam := rect.size
	draw_texture_rect(apagado, rect, false)
	if b > 0.02:
		# el halo: el mismo dibujo, transparente y corrido un poco a cada lado
		for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			draw_texture_rect(encendido, Rect2(rect.position + d, tam), false, Color(1, 1, 1, 0.22 * b))
		draw_texture_rect(encendido, rect, false, Color(1, 1, 1, b))
	if destello > 0.0:
		# el fogonazo donde salta la chispa
		var a := destello / 0.1
		draw_rect(Rect2(chispas.position - Vector2(5, 5), Vector2(10, 10)), Color(1, 0.9, 0.5, 0.35 * a))
		draw_rect(Rect2(chispas.position - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 0.9, a))
