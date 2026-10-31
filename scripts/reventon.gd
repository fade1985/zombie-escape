# El reventón del gordo al morir (M38): una corona de veneno que se abre en el suelo y gotas que salen a todos lados,
# caen y chisporrotean. Es el "acid-splash" de pixelfx pasado a vista desde arriba (tools/pixelfx/reventon-veneno.js),
# en tres hojas: lo de detrás (las manchitas, la mitad de atrás de la corona), lo de delante y el brillo (que se suma).
# Se ve una vez y se va; el charco grande que queda es aparte (charco.gd, "reventon").
class_name Reventon
extends Node2D

const HOJAS := [preload("res://assets/sprites/reventon-veneno-detras.png"),
	preload("res://assets/sprites/reventon-veneno-delante.png"), preload("res://assets/sprites/reventon-veneno-brillo.png")]
const ORIGEN := Vector2(80, 72)   # dónde está el suelo del centro en cada fotograma (en píxeles del dibujo)
const FOTOGRAMAS := 28
const FPS := 20.0

var capas: Array[Sprite2D] = []
var t := 0.0


static func soltar(sala: Node, donde: Vector2) -> void:
	var r := Reventon.new()
	r.position = (donde / 2.0).round() * 2.0   # (en píxel entero del dibujo, como los charcos)
	sala.add_child.call_deferred(r)   # (puede morir en mitad de una consulta de física)


func _ready() -> void:
	# lo de detrás, en el suelo como los charcos (a -1, y por encima: sale después); lo de delante, a la altura de las balas
	for i in 3:
		var capa := Sprite2D.new()
		capa.texture = HOJAS[i]
		capa.hframes = 8
		capa.vframes = 4
		capa.centered = false
		capa.offset = -ORIGEN
		capa.scale = Vector2(2, 2)
		capa.z_as_relative = false
		capa.z_index = -1 if i == 0 else 4
		if i == 2:
			var suma := CanvasItemMaterial.new()
			suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			capa.material = suma
		add_child(capa)
		capas.append(capa)


func _process(delta: float) -> void:
	t += delta
	var cuadro := int(t * FPS)
	if cuadro >= FOTOGRAMAS:
		queue_free()
		return
	for capa in capas:
		capa.frame = cuadro
