# La luz fija del gimnasio del Gymbro (peligros.gd, GIMNASIO). No es un peligro: se monta como ellos porque es lo
# que tiene la habitación en vez de lámparas (su sala no tiene ninguna). Unas luces blancas, un poco cálidas, repartidas
# por la sala, sin sombras (la habitación es una sola: no hay a quién colarse) y sin latido, siempre iguales, como el
# resplandor del ácido del Glotón (porqueria.gd) y el fuego del jefe de bomberos (cerco.gd), pero quietas. Alumbran
# el suelo y todo lo que hay en la sala (los muebles, Johnny, el jefe...) y siguen la oscuridad de la planta
# (Luz.fuerza), como las demás luces.
extends Node2D

const TEXTURA := preload("res://escenas/luces/luz_suave.tres")

var datos: Dictionary
var mapa: Node
var luces: Array = []


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "LuzGimnasio"
	for donde in datos.luces:
		var l := PointLight2D.new()
		l.texture = TEXTURA
		l.texture_scale = Peligros.GIMNASIO.radio / 128.0
		l.color = Peligros.GIMNASIO.color
		l.range_item_cull_mask = Luz.CAPA_SUELO | Luz.CAPA_COSAS | Luz.capa_sala(datos.sala)
		l.position = donde
		add_child(l)
		luces.append(l)


func _physics_process(_delta: float) -> void:
	for l in luces:
		l.energy = Peligros.GIMNASIO.fuerza * Luz.fuerza()
