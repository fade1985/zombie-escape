# Los efectos de pixelfx que salen una vez en el suelo y se van, en tres hojas cada uno (exportadas con
# tools/pixelfx/exportar.mjs, 8 columnas a 20 fotogramas por segundo): lo de detrás (en el suelo, por debajo de los
# personajes), lo de delante (a la altura de las balas) y el brillo (que se suma).
#  - "reventon": el gordo al morir (M38), el "acid-splash" pasado a vista desde arriba (tools/pixelfx/reventon-veneno.js).
#    El charco grande que queda es aparte (charco.gd, "reventon").
#  - "gases": la nube del Flatulento (M37), el "poison-cloud" desde arriba (tools/pixelfx/nube-gases.js), del tamaño
#    del radio del gas (140).
class_name EfectoSuelo
extends Node2D

const TIPOS := {
	"reventon": {"hojas": [preload("res://assets/sprites/reventon-veneno-detras.png"),
		preload("res://assets/sprites/reventon-veneno-delante.png"), preload("res://assets/sprites/reventon-veneno-brillo.png")],
		"origen": Vector2(80, 72), "fotogramas": 28},
	"gases": {"hojas": [preload("res://assets/sprites/nube-gases-detras.png"),
		preload("res://assets/sprites/nube-gases-delante.png"), preload("res://assets/sprites/nube-gases-brillo.png")],
		"origen": Vector2(92, 66), "fotogramas": 32},
}
const FPS := 20.0

var tipo := "reventon"
var capas: Array[Sprite2D] = []
var t := 0.0
var de_calentar := false   # el de precalentar(): casi transparente, unos fotogramas y fuera

static var calentados := {}


# La primera vez que se dibuja algo con la mezcla "añadir" del brillo, el motor tiene que preparar cómo pintarlo y el
# juego se para un momento (sobre todo en la web). Para que no pase la primera vez que sale de verdad, antes se pinta
# uno casi transparente en el centro de la pantalla (fuera de ella no se dibujaría y no serviría)
static func precalentar(sala: Node, cual: String) -> void:
	if calentados.has(cual):
		return
	var camara := sala.get_viewport().get_camera_2d()
	if camara == null:
		return
	calentados[cual] = true
	var e := EfectoSuelo.new()
	e.tipo = cual
	e.de_calentar = true
	e.position = camara.get_screen_center_position()
	sala.add_child.call_deferred(e)


static func soltar(sala: Node, cual: String, donde: Vector2) -> EfectoSuelo:
	var e := EfectoSuelo.new()
	e.tipo = cual
	e.position = (donde / 2.0).round() * 2.0   # (en píxel entero del dibujo, como los charcos)
	sala.add_child.call_deferred(e)   # (puede salir en mitad de una consulta de física)
	return e


func _ready() -> void:
	var datos: Dictionary = TIPOS[tipo]
	var filas := ceili(datos.fotogramas / 8.0)
	# lo de detrás, en el suelo como los charcos (a -1, y por encima: sale después); lo de delante, a la altura de las balas
	for i in 3:
		var capa := Sprite2D.new()
		capa.texture = datos.hojas[i]
		capa.hframes = 8
		capa.vframes = filas
		capa.centered = false
		capa.offset = -datos.origen
		capa.scale = Vector2(2, 2)
		capa.z_as_relative = false
		capa.z_index = -1 if i == 0 else 4
		if i == 2:
			var suma := CanvasItemMaterial.new()
			suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			capa.material = suma
		add_child(capa)
		capas.append(capa)
	if de_calentar:
		modulate = Color(1, 1, 1, 0.02)   # (del todo transparente, el motor se lo salta y no prepara nada)
		for capa in capas:
			capa.frame = 3


func _process(delta: float) -> void:
	t += delta
	if de_calentar:
		if t > 0.1:
			queue_free()
		return
	var cuadro := int(t * FPS)
	if cuadro >= TIPOS[tipo].fotogramas:
		queue_free()
		return
	for capa in capas:
		capa.frame = cuadro
