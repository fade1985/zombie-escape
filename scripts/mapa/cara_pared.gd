# La cara de un muro: el papel pintado (o el azulejo) que se ve de frente cuando hay suelo justo debajo del
# muro, como en Zelda o en Isaac. Mide 3 casillas de alto (96 unidades) y sube desde el pie del muro, así que
# en los tabiques tapa las dos últimas filas de la habitación de detrás. Va con los personajes, ordenada por
# su "y": quien está delante del muro se dibuja encima y quien está detrás queda tapado (y entonces la cara
# se vuelve medio transparente para que no se pierda de vista a Johnny).
extends Node2D

const ALTO := 96.0     # alto de la cara, en unidades (48 píxeles del dibujo)
const TECHO := 12.0    # la moldura de arriba (6 píxeles)

var ancho := 32.0          # en unidades
var pared: Texture2D
var techo: Texture2D
var puede_tapar := false   # solo los tabiques de dentro tienen a alguien detrás
var niebla := 0.0          # la oscuridad de su habitación, si aún no se ha pisado (la pone mapa.gd)
var adornos := []          # restos pintados encima del papel (salpicones, huellas...; mapa.gd): {dibujo, x, y}


func _ready() -> void:
	# Repetir la textura a lo largo; scale 2 porque se dibuja en píxeles del dibujo
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	set_process(puede_tapar)


func _draw() -> void:
	# En píxeles del dibujo. La textura empieza a contar desde el borde izquierdo del mapa, así que dos trozos
	# de cara seguidos casan sin costura.
	var x0 := position.x / 2.0
	var w := ancho / 2.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	draw_texture_rect_region(pared, Rect2(0, -ALTO / 2.0, w, ALTO / 2.0), Rect2(x0, 0, w, pared.get_height()))
	draw_texture_rect_region(techo, Rect2(0, -(ALTO + TECHO) / 2.0, w, TECHO / 2.0), Rect2(x0, 0, w, techo.get_height()))
	for a in adornos:
		draw_texture(a.dibujo, Vector2(a.x, a.y))
	if niebla > 0.0:
		draw_rect(Rect2(0, -(ALTO + TECHO) / 2.0, w, (ALTO + TECHO) / 2.0), Color(0.07, 0.063, 0.11, 0.8 * niebla))


func _process(delta: float) -> void:
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny == null:
		return
	var p := johnny.global_position - global_position
	var detras := p.x > -20.0 and p.x < ancho + 20.0 and p.y < 0.0 and p.y > -ALTO - 40.0
	modulate.a = move_toward(modulate.a, 0.45 if detras else 1.0, delta * 4.0)
