# Lo que luce de quien arde o tiene ácido, para que se vea en las salas oscuras. La penumbra (luz.gd) oscurece todo
# el dibujo, también las llamas; así que encima del dibujo va una copia suya que solo pinta lo que luce (las llamas,
# las chispas y, más flojo, el ácido) y a la que no le afecta la oscuridad (escenas/personajes/brillo.gdshader). Va
# de hija del dibujo y cada paso copia su fotograma y lo que tiene puesto en el shader; sin fuego ni ácido, se
# esconde. Lo pone Zombi.quemaduras (zombis, quemado.gd y jefes con ácido).
# Y la luz verde del ácido, como la naranja del fuego (luz_acido).
class_name Brillo
extends AnimatedSprite2D

const SHADER := preload("res://escenas/personajes/brillo.gdshader")
const PARAMETROS := ["destello", "hielo", "fuego", "acido", "t", "semilla", "alto"]
const COLOR_ACIDO := Color("#7ddc3a")

var dibujo: AnimatedSprite2D


# La copia que brilla de un dibujo (la crea la primera vez)
static func de(s: AnimatedSprite2D) -> Brillo:
	var b: Brillo = s.get_node_or_null("Brillo")
	if b == null:
		b = Brillo.new()
		b.name = "Brillo"
		b.dibujo = s
		b.material = ShaderMaterial.new()
		b.material.shader = SHADER
		s.add_child(b)
	return b


# La luz verde del ácido de alguien (la crea la primera vez): más pequeña y floja que la del fuego, y late despacio.
# "alto", lo que mide (va a media altura, como la del fuego)
static func luz_acido(quien: Node2D, alto: float) -> PointLight2D:
	var luz: PointLight2D = quien.get_node_or_null("LuzAcido")
	if luz == null:
		luz = Llamas.LUZ.instantiate()
		luz.name = "LuzAcido"
		luz.color = COLOR_ACIDO
		luz.radio = 70.0
		luz.latido = true
		luz.position = Vector2(0, -alto * 0.4)
		quien.add_child(luz)
	return luz


# Lo que tiene puesto un shader (0 si aún no se le ha puesto nada)
static func valor(m: ShaderMaterial, k: String) -> float:
	var v = m.get_shader_parameter(k)
	return v if v != null else 0.0


func _process(_delta: float) -> void:
	var m := dibujo.material as ShaderMaterial
	visible = m != null and (Brillo.valor(m, "fuego") > 0.0 or Brillo.valor(m, "acido") > 0.0)
	if not visible:
		return
	if sprite_frames != dibujo.sprite_frames:
		sprite_frames = dibujo.sprite_frames
	animation = dibujo.animation
	frame = dibujo.frame
	centered = dibujo.centered
	offset = dibujo.offset
	flip_h = dibujo.flip_h
	flip_v = dibujo.flip_v
	for k in PARAMETROS:
		material.set_shader_parameter(k, m.get_shader_parameter(k))
