# Un lienzo para pintar con código a la medida de los píxeles de los dibujos (2 × 2 unidades cada uno), para que lo
# pintado no se vea con más detalle que el dibujo de al lado. Se pinta en un visor (SubViewport) a la mitad de
# tamaño y se enseña agrandado al doble, sin suavizar: cada píxel del visor es un píxel del dibujo, y caen justo en
# la cuadrícula de quien lo usa (la de su dibujo, si sus bordes caen en unidades pares, como los de escala 2).
# Lo usan las lenguas del latigazo del Glotón y las de la criatura del científico, y su sombra (21 nov: pintadas a 1 × 1 se veían más finas que él).
# Quien lo usa le pasa con qué pintar ("al_pintar", que recibe el lienzo donde pintar, en unidades, con el centro en
# el del nodo) y lo refresca en cada fotograma mientras haga falta (refrescar).
class_name LienzoPixelado
extends Node2D

var visor: SubViewport
var dibujo: Node2D       # donde se pinta (dentro del visor, a la mitad)
var imagen: Sprite2D     # lo que se ve (el visor, al doble)
var al_pintar: Callable


# "medio": lo que llega desde el centro hacia cada lado, en unidades (par: así los píxeles caen en unidades pares)
func _init(medio: int, al_pintar_: Callable) -> void:
	medio = medio + medio % 2
	al_pintar = al_pintar_
	visor = SubViewport.new()
	visor.size = Vector2i(medio, medio)   # (2 × medio unidades, a medio píxel por unidad)
	visor.transparent_bg = true
	visor.disable_3d = true
	visor.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(visor)
	dibujo = Node2D.new()
	dibujo.position = Vector2(medio, medio) / 2.0
	dibujo.scale = Vector2(0.5, 0.5)
	dibujo.draw.connect(func() -> void: al_pintar.call(dibujo))
	visor.add_child(dibujo)
	imagen = Sprite2D.new()
	imagen.texture = visor.get_texture()
	imagen.centered = false
	imagen.position = -Vector2(medio, medio)
	imagen.scale = Vector2(2, 2)
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Lo translúcido (la sombra, la estela) se guarda en el visor ya multiplicado por su transparencia: se enseña así
	# para que no salga el doble de flojo
	var material_ := CanvasItemMaterial.new()
	material_.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	imagen.material = material_
	imagen.visible = false
	add_child(imagen)


# En cada fotograma: si hay algo que pintar, se vuelve a pintar; si no, se esconde (y el visor no trabaja)
func refrescar(activo: bool) -> void:
	imagen.visible = activo
	if activo:
		dibujo.queue_redraw()
		visor.render_target_update_mode = SubViewport.UPDATE_ONCE
