# El científico de Velaria muerto en el suelo (historia.gd): tumbado con su bata blanca manchada de sangre seca
# (de GPT desde la M14, tools/cientifico_muerto_gpt.py, con la piel y el pelo de su página; desde la M86 todos los que llevan página son científicos,
# también en el centro comercial) y, a su lado, la página del dosier, que brilla y sube y baja hasta que Johnny se arrima.
# Entonces avisa con "cogida" (la partida la enseña y la guarda). Ya cogida, el cuerpo se queda sin la página.
extends Node2D

signal cogida

const ALCANCE := 46.0   # lo cerca que hay que pasar para coger la página

var pagina: Dictionary    # la página que lleva (Historia.DOSIERES)
var johnny: Node2D
var mapa: Node = null     # para la niebla de su habitación (su brillo no se ve desde fuera)
var zona := -1
var look := {}            # piel y pelo (los de su página)
var papel: Node2D
var brillo: PointLight2D
var t := 0.0


func montar(p: Dictionary, pos: Vector2) -> void:
	pagina = p
	name = "Cientifico"
	position = pos
	look = p.look
	z_index = -1   # en el suelo: los que pasen por encima se ven delante
	# el dibujo (de GPT), en tres capas: el cuerpo, y la piel y el pelo en grises que se pintan con los
	# colores de su página (tools/cientifico_muerto_gpt.py). La piel, apagada y grisácea: lleva tiempo muerto
	capa(CUERPO, Color.WHITE)
	capa(PIEL, Color(look.skin).lerp(Color("#969696"), 0.35))
	capa(PELO, look.hair)
	# la página: la hoja de GPT con su clip (M14; tools/muebles_gpt.py dosier_pagina), a escala 2 como los demás
	var hoja := Sprite2D.new()
	hoja.texture = PAGINA
	hoja.scale = Vector2(2, 2)
	hoja.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	papel = Node2D.new()
	papel.position = Vector2(28, 30)
	papel.add_child(hoja)
	add_child(papel)
	# su resplandor, el mismo que el de la llave del suelo (mapa.poner_llave; lo pidió el dueño, 10 nov): una luz blanca
	# fija que alumbra todas las capas (luz.gd), para que en un apartamento ilumine también el suelo de la habitación
	brillo = PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.3
	brillo.color = Color.WHITE
	brillo.range_item_cull_mask = Luz.TODAS
	brillo.position = Vector2(papel.position.x, 30 - 3.0)   # (en medio de lo que sube y baja la hoja)
	add_child(brillo)


func _physics_process(delta: float) -> void:
	t += delta
	if papel == null:
		return
	papel.position.y = 30 - absf(sin(t * 2.5)) * 6.0
	var oscuro: float = mapa.niebla.get(zona, 0.0) if mapa and zona >= 0 else 0.0
	brillo.energy = 1.0 - oscuro   # (con la habitación sin descubrir, no se ve desde fuera)
	brillo.enabled = oscuro < 0.98
	if johnny and johnny.vivo and johnny.global_position.distance_to(global_position + papel.position) < ALCANCE:
		papel.queue_free()
		brillo.queue_free()
		papel = null
		cogida.emit()


const CUERPO := preload("res://assets/sprites/cientifico-muerto.png")
const PIEL := preload("res://assets/sprites/cientifico-muerto-piel.png")
const PELO := preload("res://assets/sprites/cientifico-muerto-pelo.png")
const PAGINA := preload("res://assets/sprites/dosier-pagina.png")


# Una capa del dibujo, a escala 2 como los demás sprites, más o menos donde estaba el cuerpo dibujado a mano
func capa(textura: Texture2D, color: Color) -> void:
	var s := Sprite2D.new()
	s.texture = textura
	s.scale = Vector2(2, 2)
	s.position = Vector2(0, -6)
	s.modulate = color
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)   # antes que la página: queda debajo


# Sin la página (ya cogida en esta partida): solo el cuerpo
func vaciar() -> void:
	if papel:
		papel.queue_free()
		brillo.queue_free()
		papel = null
