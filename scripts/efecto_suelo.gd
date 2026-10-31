# Los efectos de pixelfx que salen una vez en el suelo y se van, en tres hojas cada uno (exportadas con
# tools/pixelfx/exportar.mjs, 8 columnas a 20 fotogramas por segundo): lo de detrás (en el suelo, por debajo de los
# personajes), lo de delante (a la altura de las balas) y el brillo (que se suma).
#  - "reventon": el gordo al morir (M38), el "acid-splash" pasado a vista desde arriba (tools/pixelfx/reventon-veneno.js).
#    El charco grande que queda es aparte (charco.gd, "reventon").
#  - "gases": la nube del Flatulento (M37), el "poison-cloud" desde arriba (tools/pixelfx/nube-gases.js), del tamaño
#    del radio del gas (140).
#  - "molotov": la botella al romperse (M48; proyectil.gd, llamarada), un efecto nuevo hecho para el juego, visto desde
#    arriba (tools/pixelfx/molotov.js): el chasquido, la gasolina que prende en corro, las llamas, chispas y los cristales
#    que saltan y resbalan. El charco de fuego que queda es aparte (charco.gd, "fuego").
#  - "sangre", "sangre-verde" y "sangre-morada": el zombi que muere de un golpe fuerte revienta (M49; partida.sangre): un
#    efecto hecho para el juego (tools/pixelfx/reventon-sangre.js), con la sangre de cada uno (roja, la del venenoso y la
#    del de tentáculos). La mancha que queda es aparte (mancha.gd).
#  - "chispazo": la electricidad al dar a un zombi (M50; ArmasCreadas.rayo y el lanza rayos, llamarada.gd), el "zap-hit"
#    pasado a vista desde arriba (tools/pixelfx/chispazo.js): un nudo de rayitos a la altura del cuerpo, chispas que hacen
#    eses y caen, y una quemadura en forma de helecho en el suelo. Se suelta en el suelo, debajo del golpe.
#  - "escarcha": la congeladora al explotar (M51; explosion.gd, "helada": en vez de la bola de fuego), un efecto hecho para
#    el juego (tools/pixelfx/escarcha.js): el destello y el copo, un anillo de frío que se abre por el suelo dejando escarcha,
#    cristales de hielo que brotan, brillan y se funden, trozos de hielo y vaho. Hecho para el radio de la congeladora
#    (120): con otro, se agranda o se achica ("escala").
#  - "escarcha-zombi": la misma, pequeña (tools/pixelfx/escarcha-zombi.js), en cada zombi que se congela (la congeladora,
#    granada.gd, y la cámara frigorífica, zombi.congelar).
#  - "deshielo": el hielo que revienta cuando a un zombi se le acaba el congelado o muere congelado (zombi.deshelar), con la
#    idea del "ice-shatter" de pixelfx (tools/pixelfx/deshielo.js): grietas y un destello, y trozos de hielo que saltan,
#    caen, rebotan, resbalan y se funden entre vaho.
class_name EfectoSuelo
extends Node2D

const TIPOS := {
	"reventon": {"hojas": [preload("res://assets/sprites/reventon-veneno-detras.png"),
		preload("res://assets/sprites/reventon-veneno-delante.png"), preload("res://assets/sprites/reventon-veneno-brillo.png")],
		"origen": Vector2(80, 72), "fotogramas": 28},
	"gases": {"hojas": [preload("res://assets/sprites/nube-gases-detras.png"),
		preload("res://assets/sprites/nube-gases-delante.png"), preload("res://assets/sprites/nube-gases-brillo.png")],
		"origen": Vector2(92, 66), "fotogramas": 32},
	"molotov": {"hojas": [preload("res://assets/sprites/molotov-detras.png"),
		preload("res://assets/sprites/molotov-delante.png"), preload("res://assets/sprites/molotov-brillo.png")],
		"origen": Vector2(110, 120), "fotogramas": 26},
	"sangre": {"hojas": [preload("res://assets/sprites/reventon-sangre-detras.png"),
		preload("res://assets/sprites/reventon-sangre-delante.png"), preload("res://assets/sprites/reventon-sangre-brillo.png")],
		"origen": Vector2(100, 100), "fotogramas": 24},
	"sangre-verde": {"hojas": [preload("res://assets/sprites/reventon-sangre-verde-detras.png"),
		preload("res://assets/sprites/reventon-sangre-verde-delante.png"), preload("res://assets/sprites/reventon-sangre-verde-brillo.png")],
		"origen": Vector2(100, 100), "fotogramas": 24},
	"sangre-morada": {"hojas": [preload("res://assets/sprites/reventon-sangre-morada-detras.png"),
		preload("res://assets/sprites/reventon-sangre-morada-delante.png"), preload("res://assets/sprites/reventon-sangre-morada-brillo.png")],
		"origen": Vector2(100, 100), "fotogramas": 24},
	"chispazo": {"hojas": [preload("res://assets/sprites/chispazo-detras.png"),
		preload("res://assets/sprites/chispazo-delante.png"), preload("res://assets/sprites/chispazo-brillo.png")],
		"origen": Vector2(48, 56), "fotogramas": 10},
	"escarcha": {"hojas": [preload("res://assets/sprites/escarcha-detras.png"),
		preload("res://assets/sprites/escarcha-delante.png"), preload("res://assets/sprites/escarcha-brillo.png")],
		"origen": Vector2(88, 80), "fotogramas": 32},
	"escarcha-zombi": {"hojas": [preload("res://assets/sprites/escarcha-zombi-detras.png"),
		preload("res://assets/sprites/escarcha-zombi-delante.png"), preload("res://assets/sprites/escarcha-zombi-brillo.png")],
		"origen": Vector2(36, 48), "fotogramas": 24},
	"deshielo": {"hojas": [preload("res://assets/sprites/deshielo-detras.png"),
		preload("res://assets/sprites/deshielo-delante.png"), preload("res://assets/sprites/deshielo-brillo.png")],
		"origen": Vector2(56, 62), "fotogramas": 18},
}
# El reventón de sangre de cada tipo de zombi (el que no está, el rojo)
const SANGRE := {"venenoso": "sangre-verde", "tentaculos": "sangre-morada"}
const FPS := 20.0

var tipo := "reventon"
var escala := 1.0          # más grande o más pequeño que el dibujo (a 2 unidades por píxel)
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


static func soltar(sala: Node, cual: String, donde: Vector2, escala := 1.0) -> EfectoSuelo:
	var e := EfectoSuelo.new()
	e.tipo = cual
	e.escala = escala
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
		capa.scale = Vector2(2, 2) * escala
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
