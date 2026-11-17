# Un neón dibujado colgado en la pared de arriba de la galería del centro comercial (17 nov): el casete, el radiocasete o
# el tocadiscos (de GPT: tools/neones_galeria.py). Hace de lámpara: da luz de sus colores al pasillo y, como los apliques de
# los Apartamentos, parpadea y falla de vez en cuando (la misma cuenta, lampara.gd). Cuando falla se ve el tubo apagado.
# Se ve aunque el pasillo esté a oscuras (no le afecta la penumbra). Lo pone mapa.gd (poner_neones_galeria); el nodo va en
# el pie del muro, para ordenarse con la cara de la pared.
extends Node2D

const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const MEDIO := 50.0   # a qué altura va su centro, por encima del pie del muro (la pared mide 96)

var nombre := "casete"
var color := Color("#c070ff")   # el de su luz
var semilla := 0.5
var encendido: Texture2D
var apagado: Texture2D
var luz: Node2D
var tiempo := 0.0


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
	luz.alto = MEDIO
	luz.suelo = Vector2(0, 60)
	luz.fuerza = 0.9
	add_child(luz)
	luz.get_node("Bombilla").visible = false
	for n in ["LuzSuelo", "LuzCosas"]:   # no-tr (nombres de nodo)
		luz.get_node(n).color = color
	luz.get_node("Polvo").visible = false


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


func _draw() -> void:
	var b: float = clampf(luz.brillo(tiempo) if luz else 1.0, 0.0, 1.0)
	var tam := encendido.get_size() * 2.0
	var rect := Rect2(Vector2(-roundf(tam.x / 4.0) * 2.0, -MEDIO - roundf(tam.y / 4.0) * 2.0), tam)
	draw_texture_rect(apagado, rect, false)
	if b <= 0.02:
		return
	# el halo: el mismo dibujo, transparente y corrido un poco a cada lado
	for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_texture_rect(encendido, Rect2(rect.position + d, tam), false, Color(1, 1, 1, 0.22 * b))
	draw_texture_rect(encendido, rect, false, Color(1, 1, 1, b))
