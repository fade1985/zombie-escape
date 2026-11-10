# Un polígono de color que se dibuja con draw_polygon, en lugar de un Polygon2D, para los que cambian cada fotograma
# (el rayo de la linterna, luz.gd; la pantalla de la tele, tele_salon.gd). Se ve igual que un Polygon2D sin textura.
# Por qué: en la web (Godot 4.7.2, Compatibilidad), un Polygon2D que se vuelve a dibujar con los mismos puntos
# actualiza su malla con mesh_surface_update_index_region, que ata los índices al búfer equivocado
# (GL_ARRAY_BUFFER en vez de GL_ELEMENT_ARRAY_BUFFER), y Chrome llena la consola de avisos de WebGL
# («bindBuffer: element array buffers can not be bound to a different target» y «bufferSubData: no buffer»).
# draw_polygon no usa esa malla y no los provoca.
extends Node2D

var polygon := PackedVector2Array():
	set(v):
		polygon = v
		queue_redraw()
# un color por punto (como el vertex_colors del Polygon2D); si no hay uno por cada punto, todos de color
var vertex_colors := PackedColorArray():
	set(v):
		vertex_colors = v
		queue_redraw()
var color := Color.WHITE:
	set(v):
		color = v
		queue_redraw()


func _draw() -> void:
	if polygon.size() < 3:
		return
	if vertex_colors.size() == polygon.size():   # (como Polygon2D: entonces color no cuenta)
		draw_polygon(polygon, vertex_colors)
	else:
		draw_polygon(polygon, PackedColorArray([color]))
