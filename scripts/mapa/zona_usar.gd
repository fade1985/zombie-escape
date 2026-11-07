# La zona invisible de delante de un mueble de la sala de mantenimiento (la mesa del ordenador, ordenador.gd; el
# baúl, el banco de trabajo y la taquilla, arrimable.gd). Antes el mueble se abría solo al arrimarse; ahora, mientras
# Johnny está en la zona, se abre al pulsar la acción de atacar: el clic izquierdo o J (las que tenga puestas en
# Opciones), RT en el mando y, en el móvil, el botón «Abrir» que sale entonces (tactil.gd). Con el ratón, el clic tiene
# que caer encima del mueble: si cae en otra parte, no se abre y Johnny ataca como siempre (clic_fuera). Con J o RT no hay
# puntero, así que lo abren estén donde estén y no disparan (johnny.gd, "ante_mueble"). Sin letrero encima (lo pidió el dueño).
extends Area2D

signal usar

# El contorno amarillo que avisa de que el mueble se usa (lo pidió el dueño): con el ratón, sale al pasarlo por encima
# del mueble, esté Johnny donde esté; con el mando, el teclado o el dedo (sin ratón), cuando Johnny está delante.
# Es una copia del dibujo del mueble que solo pinta 1 píxel alrededor de lo que no es transparente, sin penumbra
# (unshaded) para que se vea igual a oscuras
const COLOR_CONTORNO := Color("#ffd84a")
const SHADER_CONTORNO := """
shader_type canvas_item;
render_mode unshaded;
uniform vec4 color : source_color;
// el dibujo crece 1 píxel por cada lado, para que quepa el contorno aunque el mueble llegue al borde de su imagen
void vertex() {
	vec2 lado = UV * 2.0 - 1.0;
	VERTEX += lado;
	UV += lado * TEXTURE_PIXEL_SIZE;
}
float opaco(sampler2D t, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 0.0;
	return step(0.5, texture(t, uv).a);
}
void fragment() {
	vec2 p = TEXTURE_PIXEL_SIZE;
	float vecinos = opaco(TEXTURE, UV + vec2(p.x, 0.0)) + opaco(TEXTURE, UV - vec2(p.x, 0.0))
		+ opaco(TEXTURE, UV + vec2(0.0, p.y)) + opaco(TEXTURE, UV - vec2(0.0, p.y));
	COLOR = (opaco(TEXTURE, UV) < 0.5 && vecinos > 0.0) ? color : vec4(0.0);
}
"""

var johnny: Node2D = null   # Johnny, mientras está en la zona
var clic_fuera := false     # si lo último con lo que se ha atacado es un clic lejos del mueble: ni se abre ni para el ataque
var dibujo: Sprite2D = null     # el dibujo del mueble
var contorno: Sprite2D = null   # su contorno amarillo, escondido mientras no toca
var raton := Vector2(-1, -1)    # dónde está el ratón en la pantalla (el último movimiento); negativo si aún no se ha movido


# "ancho": lo que ocupa el mueble en el suelo
func montar(ancho: float) -> void:
	name = "Zona"   # no-tr
	collision_layer = 0
	collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(ancho + 20, 40)
	hueco.shape = r
	hueco.position = Vector2(0, 18)
	add_child(hueco)
	body_entered.connect(func(cuerpo):
		johnny = cuerpo
		clic_fuera = false
		cuerpo.set("ante_mueble", self))
	body_exited.connect(func(cuerpo):
		if cuerpo.get("ante_mueble") == self:
			cuerpo.set("ante_mueble", null)
		johnny = null)


# Ya dentro del mueble (que ha puesto su dibujo antes que la zona): la copia del dibujo que hace de contorno
func _ready() -> void:
	for hijo in get_parent().get_children():
		if hijo is Sprite2D:
			dibujo = hijo
			break
	if dibujo == null:
		return
	contorno = Sprite2D.new()
	contorno.name = "Contorno"   # no-tr
	contorno.texture = dibujo.texture
	contorno.scale = dibujo.scale
	contorno.centered = dibujo.centered
	contorno.offset = dibujo.offset
	contorno.position = dibujo.position
	var sombreador := Shader.new()
	sombreador.code = SHADER_CONTORNO
	var material := ShaderMaterial.new()
	material.shader = sombreador
	material.set_shader_parameter("color", COLOR_CONTORNO)
	contorno.material = material
	contorno.visible = false
	get_parent().add_child.call_deferred(contorno)


func _process(_delta: float) -> void:
	if contorno:
		contorno.visible = resaltado()


# Si toca enseñar el contorno: con el ratón, si está encima del mueble (lo mismo que cuenta para el clic); sin él (mando,
# teclado o el dedo en el móvil), si Johnny está delante y ya se puede abrir
func resaltado() -> bool:
	var dedo := Tactil.activo and Tactil.con_dedo
	# (el ratón, en la pantalla; pasado al dibujo cada vez, porque la cámara se mueve aunque el ratón esté quieto)
	var en_dibujo := dibujo.get_global_transform_with_canvas().affine_inverse() * raton
	if not dedo and raton.x >= 0.0 and dibujo.get_rect().grow(4).has_point(en_dibujo):
		return true
	return johnny != null and (dedo or not johnny.get("con_raton"))


# Cada vez que se pulsa "atacar", apunta si ha sido un clic fuera del mueble (llega antes que _physics_process)
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouse:
		raton = evento.position
	if johnny == null or not evento.is_action_pressed("atacar"):
		return
	clic_fuera = evento is InputEventMouseButton and not encima(evento)


func _physics_process(_delta: float) -> void:
	if johnny and Input.is_action_just_pressed("atacar") and not clic_fuera:
		abrir()


# Si un clic cae sobre el dibujo del mueble (con un poco de margen, para no tener que afinar)
func encima(evento: InputEventMouseButton) -> bool:
	for hijo in get_parent().get_children():
		if hijo is Sprite2D:
			return hijo.get_rect().grow(4).has_point(hijo.make_input_local(evento).position)
	return false


# Al irse la sala (otra planta, F9, el ascensor) con Johnny dentro: que no se quede creyendo que sigue delante
func _exit_tree() -> void:
	if is_instance_valid(johnny) and johnny.get("ante_mueble") == self:
		johnny.set("ante_mueble", null)
	johnny = null


func abrir() -> void:
	usar.emit()
