# La zona invisible de delante de un mueble de la sala de mantenimiento (la mesa del ordenador, ordenador.gd; el
# baúl, el banco de trabajo y la taquilla, arrimable.gd; y el armarito de los baños, armarito.gd). Antes el mueble se abría solo al arrimarse; ahora, mientras
# Johnny está en la zona, se abre al pulsar la acción de atacar: el clic izquierdo o J (las que tenga puestas en
# Opciones), el botón B del mando ("usar"; RT ataca siempre) y, en el móvil, el botón «Abrir»
# que sale entonces (tactil.gd). Con el ratón, el clic tiene que caer encima del mueble: si cae en otra parte, no se abre y
# Johnny ataca como siempre (clic_fuera). Con J no hay puntero, así que lo abre esté donde esté y no dispara (johnny.gd,
# "ante_mueble"). Sin letrero encima (lo pidió el dueño).
# Las puertas de dentro (puerta_bano.gd) usan la misma zona para cerrarse y volver a abrirse: la ponen con montar_rect
# (la zona de delante y detrás del hueco), dicen con "puede" cuándo se pueden usar y, con "cierra", que el botón del
# móvil diga «Cerrar». Con ellas Johnny no deja de atacar (lo pidió el dueño; "corta_ataque"): J o el clic encima la
# abren o cierran y a la vez atacan, y en el móvil atacar solo ataca (la puerta, con su botón).
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
var puede := Callable()         # si se da, cuándo se puede usar (si no, siempre): mientras no, ni contorno ni se usa, y J ataca
var cierra := false             # el botón del móvil dice «Cerrar» en vez de «Abrir» (una puerta abierta)
var boton := ""                 # si se da, lo que dice el botón del móvil (ya traducido): los bidones de los jefes, «Empujar»
var corta_ataque := true        # delante de él, J o el clic encima lo usan y no atacan, y el clic que lo usa no dispara hasta
                                # soltarlo. Las puertas lo ponen a false: las usan y Johnny sigue atacando
var al_pie := false            # la distancia, al pie del mueble y no al medio de su dibujo (el armarito, colgado alto en la pared)


# "ancho": lo que ocupa el mueble en el suelo
func montar(ancho: float) -> void:
	montar_rect(Rect2(-(ancho + 20) / 2.0, -2, ancho + 20, 40))


# La zona en un rectángulo cualquiera ("r", en las coordenadas del mueble)
func montar_rect(r: Rect2) -> void:
	name = "Zona"   # no-tr
	collision_layer = 0
	collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = r.size
	hueco.shape = forma
	hueco.position = r.get_center()
	add_child(hueco)
	body_entered.connect(func(cuerpo):
		johnny = cuerpo
		clic_fuera = false
		if mas_cerca_que(cuerpo.get("ante_mueble")):
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
	if dibujo.hframes > 1 or dibujo.vframes > 1:
		# el armarito del baño tiene dos dibujos (cerrado y abierto): el contorno, de una copia aparte del que se ve ahora
		# (con la hoja entera, o un trozo de ella, el borde sacaría una raya del dibujo de al lado)
		var tam := Vector2i(dibujo.texture.get_size()) / Vector2i(dibujo.hframes, dibujo.vframes)
		var esquina := Vector2i(dibujo.frame % dibujo.hframes, dibujo.frame / dibujo.hframes) * tam
		contorno.texture = ImageTexture.create_from_image(dibujo.texture.get_image().get_region(Rect2i(esquina, tam)))
	contorno.scale = dibujo.scale
	contorno.centered = dibujo.centered
	contorno.offset = dibujo.offset
	contorno.flip_h = dibujo.flip_h   # (la puerta del taller, abierta hacia el despacho, lleva su dibujo dado la vuelta)
	contorno.flip_v = dibujo.flip_v
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
	if not activa():
		return false
	var dedo := Tactil.activo and Tactil.con_dedo
	# (el ratón, en la pantalla; pasado al dibujo cada vez, porque la cámara se mueve aunque el ratón esté quieto)
	var en_dibujo := dibujo.get_global_transform_with_canvas().affine_inverse() * raton
	if not dedo and raton.x >= 0.0 and dibujo.get_rect().grow(4).has_point(en_dibujo):
		return true
	return johnny != null and johnny.get("ante_mueble") == self and (dedo or not johnny.get("con_raton"))


# Cada vez que se pulsa "atacar", apunta si ha sido un clic fuera del mueble (llega antes que _physics_process)
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouse:
		raton = evento.position
	if johnny == null or not evento.is_action_pressed("atacar"):
		return
	clic_fuera = evento is InputEventMouseButton and not encima(evento)


func _physics_process(_delta: float) -> void:
	if johnny == null:
		return
	# si está en la zona de dos muebles a la vez (la puerta del taller y el banco), manda el más cercano: solo ese
	# sale con el contorno y solo ese se usa
	var otra: Variant = johnny.get("ante_mueble")
	if otra != self and mas_cerca_que(otra):
		johnny.set("ante_mueble", self)
		clic_fuera = false
	if johnny.get("ante_mueble") != self or not activa():
		return
	# con el mando se usa con B ("usar"): RT ataca siempre, aunque se esté delante de una puerta; con el teclado y el ratón, con
	# J o el clic (las que se hayan puesto para atacar)
	if Input.is_action_just_pressed("usar"):
		abrir()
	elif Input.is_action_just_pressed("atacar") and not clic_fuera and not Controles.con_mando 			and (corta_ataque or not (Tactil.activo and Tactil.con_dedo)):
		# (en el móvil, el botón de atacar no abre ni cierra las puertas: solo ataca; ellas, con su botón «Cerrar»)
		abrir()
		# ese clic ya está gastado: aunque lo siga pulsando (y el mueble ya no se pueda usar, como el armarito vacío o la tele
		# ya vista), Johnny no dispara hasta que lo suelte (las puertas no: con ellas sigue atacando)
		if corta_ataque:
			johnny.set("clic_gastado", true)


# Si este mueble le toca a Johnny antes que "otra" zona (en la que también está): si la otra no se puede usar ahora
# o este está más cerca (del medio de su dibujo)
func mas_cerca_que(otra: Variant) -> bool:
	if otra == null or not is_instance_valid(otra) or otra == self:
		return true
	if not activa():
		return false
	if not otra.activa():
		return true
	return distancia() < otra.distancia() - 1.0


# De Johnny al medio del dibujo del mueble
func distancia() -> float:
	if johnny == null:
		return INF
	var medio := global_position
	if dibujo and not al_pie:
		medio = dibujo.get_global_transform() * dibujo.get_rect().get_center()
	return johnny.global_position.distance_to(medio)


# Si ahora se puede usar (ver "puede")
func activa() -> bool:
	return not puede.is_valid() or puede.call()


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
