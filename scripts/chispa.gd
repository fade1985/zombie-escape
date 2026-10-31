# La chispa de una bala al dar a un zombi (bala.gd, chocar), hecha con pixelfx: el "hit-spark" (tools/pixelfx/chispa.js,
# exportado con tools/pixelfx/exportar_chispa.mjs). Una cruz con un rayo largo hacia donde iba la bala, un rombo blanco
# y chispas que caen al suelo y rebotan. Dos hojas por talla (la de una bala y la de un perdigón, más pequeña): el color y
# el brillo (que se suma, con mezcla "añadir"). En cada hoja, los 5 colores (los de la estela de la bala: normal,
# crítica y los de cada calidad mejorada) y en cada color 5 direcciones (de hacia arriba a hacia abajo, de 45° en 45°);
# hacia la izquierda, dada la vuelta. Va por encima de los personajes, como las balas de los zombis. Contra las paredes
# sigue el impacto de siempre (impacto.gd)
class_name Chispa
extends Node2D

# (las medidas, copiadas de lo que escribe el exportador)
const TIPOS := {
	"bala": {"hojas": [preload("res://assets/sprites/chispa-bala.png"), preload("res://assets/sprites/chispa-bala-brillo.png")],
		"origen": Vector2(24, 42), "fotogramas": 12, "columnas": 12, "filas": 1},
	"perdigon": {"hojas": [preload("res://assets/sprites/chispa-perdigon.png"),
		preload("res://assets/sprites/chispa-perdigon-brillo.png")],
		"origen": Vector2(15, 31), "fotogramas": 12, "columnas": 12, "filas": 1},
}
const COLORES := ["normal", "critica", "poco_comun", "rara", "epica"]   # en el orden de las hojas
const FPS := 30.0
const ALTURA := 22.0   # a qué altura sobre su origen (el suelo) está el golpe en la hoja (11 píxeles del dibujo)

var talla := "bala"
var variante := 0           # la fila de la hoja: color × 5 + dirección
var alto := 0.0             # lo que sube el dibujo, si la bala iba más alta de lo normal
var capas: Array[Sprite2D] = []
var t := 0.0
var de_calentar := false    # el de precalentar(): casi transparente, unos fotogramas y fuera

static var calentados := {}


# La chispa en "pie" (el suelo, debajo de la bala), con el golpe "altura" más arriba, hacia "angulo" (por donde iba la
# bala). "color": uno de COLORES. "perdigon": la pequeña
static func soltar(sala: Node, pie: Vector2, altura: float, angulo: float, color: String, perdigon := false) -> void:
	var vuelta := cos(angulo) < 0.0
	var a := clampf(wrapf(PI - angulo if vuelta else angulo, -PI, PI), -PI / 2.0, PI / 2.0)
	var c := Chispa.new()
	c.talla = "perdigon" if perdigon else "bala"
	c.variante = maxi(0, COLORES.find(color)) * 5 + roundi((a + PI / 2.0) / (PI / 4.0))
	c.position = (pie / 2.0).round() * 2.0
	c.alto = roundf((ALTURA - altura) / 2.0) * 2.0
	c.scale.x = -1.0 if vuelta else 1.0
	sala.add_child.call_deferred(c)   # (sale en mitad de una consulta de física)


# El color de la chispa de una bala: el de su estela (bala.gd, estela)
static func color_de(critico: bool, calidad: int, epica: bool) -> String:
	if epica:
		return "epica"
	if critico:
		return "critica"
	return COLORES[1 + clampi(calidad, 0, 3)] if calidad > 0 else "normal"


# Como el fogonazo (fogonazo.gd): para que la primera no pare el juego, una casi transparente en el centro de la pantalla
static func precalentar(sala: Node) -> void:
	if calentados.has("chispa") or not sala.is_inside_tree():
		return
	var camara := sala.get_viewport().get_camera_2d()
	if camara == null:
		return
	calentados["chispa"] = true
	for cual in TIPOS:
		var c := Chispa.new()
		c.talla = cual
		c.de_calentar = true
		c.position = camara.get_screen_center_position()
		sala.add_child.call_deferred(c)


func _ready() -> void:
	var datos: Dictionary = TIPOS[talla]
	z_as_relative = false
	z_index = 4   # (por encima de los personajes: si da a un zombi desde arriba, que no lo tape)
	for i in 2:
		var capa := Sprite2D.new()
		capa.texture = datos.hojas[i]
		capa.hframes = datos.columnas
		capa.vframes = datos.filas * COLORES.size() * 5
		capa.centered = false
		capa.offset = -datos.origen
		capa.position = Vector2(0, alto)
		capa.scale = Vector2(2, 2)
		if i == 1:
			var suma := CanvasItemMaterial.new()
			suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			capa.material = suma
		add_child(capa)
		capas.append(capa)
	if de_calentar:
		modulate = Color(1, 1, 1, 0.02)   # (del todo transparente, el motor se lo salta y no prepara nada)
	poner(0)


func _process(delta: float) -> void:
	t += delta
	if de_calentar:
		if t > 0.1:
			queue_free()
		return
	var cuadro := int(t * FPS)
	if cuadro >= TIPOS[talla].fotogramas:
		queue_free()
		return
	poner(cuadro)


func poner(cuadro: int) -> void:
	var datos: Dictionary = TIPOS[talla]
	var cols: int = datos.columnas
	var fila: int = variante * datos.filas + floori(cuadro / float(cols))
	for capa in capas:
		capa.frame = fila * cols + cuadro % cols
